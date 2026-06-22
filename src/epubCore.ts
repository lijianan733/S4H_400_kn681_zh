// Pure EPUB parsing and rendering logic, with no dependency on the VS Code API
// so it can be unit-tested in isolation.
//
// Loads an .epub file (a zip archive), parses its OPF package and NCX table of
// contents, and renders chapters one at a time. Images and stylesheets
// referenced by a chapter are inlined as data URIs / <style> blocks so the
// content renders under a strict Content Security Policy without exposing the
// file system to the webview.

import JSZip from 'jszip'
import { XMLParser } from 'fast-xml-parser'

interface ManifestItem {
    href: string
    mediaType: string
}

export interface TocEntry {
    label: string
    spineIndex: number
    anchor: string
    depth: number
}

export interface EpubBook {
    zip: JSZip
    opfDir: string
    title: string
    spine: string[]
    toc: TocEntry[]
}

const xmlParser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: '@_',
    trimValues: true,
})

function toArray<T>(value: T | T[] | undefined): T[] {
    if (value === undefined || value === null) {
        return []
    }
    return Array.isArray(value) ? value : [value]
}

function posixDirname(p: string): string {
    const idx = p.lastIndexOf('/')
    return idx === -1 ? '' : p.slice(0, idx)
}

// Resolve a (possibly relative) href against a base directory inside the zip,
// dropping any URL fragment/query and normalising "." / ".." segments.
function resolveZipPath(baseDir: string, href: string): string {
    const clean = decodeURIComponent(href.split('#')[0].split('?')[0])
    const joined = baseDir ? `${baseDir}/${clean}` : clean
    const stack: string[] = []
    for (const part of joined.split('/')) {
        if (part === '' || part === '.') {
            continue
        }
        if (part === '..') {
            stack.pop()
        } else {
            stack.push(part)
        }
    }
    return stack.join('/')
}

function mediaTypeForPath(p: string): string {
    const ext = p.slice(p.lastIndexOf('.') + 1).toLowerCase()
    switch (ext) {
        case 'jpg':
        case 'jpeg':
            return 'image/jpeg'
        case 'png':
            return 'image/png'
        case 'gif':
            return 'image/gif'
        case 'svg':
            return 'image/svg+xml'
        case 'webp':
            return 'image/webp'
        default:
            return 'application/octet-stream'
    }
}

async function replaceAsync(
    input: string,
    regex: RegExp,
    replacer: (match: RegExpExecArray) => Promise<string>
): Promise<string> {
    const matches: RegExpExecArray[] = []
    let m: RegExpExecArray | null
    regex.lastIndex = 0
    while ((m = regex.exec(input)) !== null) {
        matches.push(m)
        if (m.index === regex.lastIndex) {
            regex.lastIndex++
        }
    }
    let result = ''
    let lastIndex = 0
    for (const match of matches) {
        result += input.slice(lastIndex, match.index)
        result += await replacer(match)
        lastIndex = match.index + match[0].length
    }
    result += input.slice(lastIndex)
    return result
}

export async function loadBook(bytes: Uint8Array): Promise<EpubBook> {
    const zip = await JSZip.loadAsync(bytes)

    const containerFile = zip.file('META-INF/container.xml')
    if (!containerFile) {
        throw new Error('无效的 EPUB：缺少 META-INF/container.xml')
    }
    const container = xmlParser.parse(await containerFile.async('string'))
    const rootfiles = toArray(container?.container?.rootfiles?.rootfile)
    const opfPath: string | undefined = rootfiles[0]?.['@_full-path']
    if (!opfPath) {
        throw new Error('无效的 EPUB：未找到 OPF 根文件')
    }

    const opfFile = zip.file(opfPath)
    if (!opfFile) {
        throw new Error(`无效的 EPUB：找不到 OPF 文件 ${opfPath}`)
    }
    const opfDir = posixDirname(opfPath)
    const opf = xmlParser.parse(await opfFile.async('string'))
    const pkg = opf?.package

    const title =
        toArray(pkg?.metadata?.['dc:title'])
            .map((t: unknown) => (typeof t === 'string' ? t : (t as Record<string, unknown>)?.['#text']))
            .find((t: unknown): t is string => typeof t === 'string' && t.length > 0) ?? 'EPUB'

    const manifestById = new Map<string, ManifestItem>()
    for (const item of toArray(pkg?.manifest?.item)) {
        const id = item['@_id']
        const href = item['@_href']
        if (id && href) {
            manifestById.set(id, { href, mediaType: item['@_media-type'] ?? '' })
        }
    }

    const spine: string[] = []
    const spineIndexByPath = new Map<string, number>()
    for (const ref of toArray(pkg?.spine?.itemref)) {
        const item = manifestById.get(ref['@_idref'])
        if (!item) {
            continue
        }
        const path = resolveZipPath(opfDir, item.href)
        spineIndexByPath.set(path, spine.length)
        spine.push(path)
    }

    const toc = await loadToc(zip, pkg, manifestById, opfDir, spineIndexByPath, spine)

    return { zip, opfDir, title, spine, toc }
}

async function loadToc(
    zip: JSZip,
    pkg: Record<string, unknown> | undefined,
    manifestById: Map<string, ManifestItem>,
    opfDir: string,
    spineIndexByPath: Map<string, number>,
    spine: string[]
): Promise<TocEntry[]> {
    const entries: TocEntry[] = []

    const tocId = (pkg?.spine as Record<string, string> | undefined)?.['@_toc']
    let ncxItem = tocId ? manifestById.get(tocId) : undefined
    if (!ncxItem) {
        for (const item of manifestById.values()) {
            if (item.mediaType === 'application/x-dtbncx+xml') {
                ncxItem = item
                break
            }
        }
    }

    if (ncxItem) {
        const ncxPath = resolveZipPath(opfDir, ncxItem.href)
        const ncxFile = zip.file(ncxPath)
        if (ncxFile) {
            const ncx = xmlParser.parse(await ncxFile.async('string'))
            const ncxDir = posixDirname(ncxPath)
            const walk = (points: unknown, depth: number) => {
                for (const point of toArray(points)) {
                    const np = point as Record<string, unknown>
                    const label = extractNavLabel(np)
                    const src = (np.content as Record<string, string> | undefined)?.['@_src']
                    if (src) {
                        const target = resolveZipPath(ncxDir, src)
                        const spineIndex = spineIndexByPath.get(target)
                        if (spineIndex !== undefined) {
                            const hashIdx = src.indexOf('#')
                            entries.push({
                                label,
                                spineIndex,
                                anchor: hashIdx === -1 ? '' : src.slice(hashIdx + 1),
                                depth,
                            })
                        }
                    }
                    if (np.navPoint) {
                        walk(np.navPoint, depth + 1)
                    }
                }
            }
            walk((ncx?.ncx?.navMap as Record<string, unknown> | undefined)?.navPoint, 0)
        }
    }

    if (entries.length === 0) {
        // Fall back to one entry per spine document.
        spine.forEach((path, index) => {
            const name = path.slice(path.lastIndexOf('/') + 1)
            entries.push({ label: name, spineIndex: index, anchor: '', depth: 0 })
        })
    }

    return entries
}

function extractNavLabel(navPoint: Record<string, unknown>): string {
    const navLabel = navPoint.navLabel as Record<string, unknown> | undefined
    const text = navLabel?.text
    if (typeof text === 'string') {
        return text
    }
    if (text && typeof text === 'object') {
        const inner = (text as Record<string, unknown>)['#text']
        if (typeof inner === 'string') {
            return inner
        }
    }
    return '(未命名)'
}

// Build the renderable HTML for a single spine document, inlining stylesheets
// and images and removing scripts.
export async function renderChapter(book: EpubBook, spineIndex: number): Promise<string> {
    const chapterPath = book.spine[spineIndex]
    const file = book.zip.file(chapterPath)
    if (!file) {
        return `<p>无法加载章节：${chapterPath}</p>`
    }
    const chapterDir = posixDirname(chapterPath)
    const raw = await file.async('string')

    const headMatch = raw.match(/<head\b[^>]*>([\s\S]*?)<\/head>/i)
    const bodyMatch = raw.match(/<body\b([^>]*)>([\s\S]*?)<\/body>/i)
    const bodyAttrs = bodyMatch ? bodyMatch[1] : ''
    let body = bodyMatch ? bodyMatch[2] : raw

    const styles: string[] = []
    if (headMatch) {
        const head = headMatch[1]
        // Inline <link rel="stylesheet">.
        const linkRegex = /<link\b[^>]*>/gi
        let lm: RegExpExecArray | null
        while ((lm = linkRegex.exec(head)) !== null) {
            const tag = lm[0]
            if (!/rel\s*=\s*["']?stylesheet/i.test(tag)) {
                continue
            }
            const hrefMatch = tag.match(/href\s*=\s*["']([^"']+)["']/i)
            if (!hrefMatch) {
                continue
            }
            const cssFile = book.zip.file(resolveZipPath(chapterDir, hrefMatch[1]))
            if (cssFile) {
                styles.push(await cssFile.async('string'))
            }
        }
        // Preserve inline <style> blocks from the head.
        const styleRegex = /<style\b[^>]*>([\s\S]*?)<\/style>/gi
        let sm: RegExpExecArray | null
        while ((sm = styleRegex.exec(head)) !== null) {
            styles.push(sm[1])
        }
    }

    body = await inlineImages(book, chapterDir, body)
    body = body.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')

    const styleBlock = styles.length ? `<style>\n${styles.join('\n')}\n</style>` : ''
    return `${styleBlock}<div class="epub-body" ${bodyAttrs}>${body}</div>`
}

async function inlineImages(book: EpubBook, chapterDir: string, html: string): Promise<string> {
    const toDataUri = async (src: string): Promise<string | undefined> => {
        const imgPath = resolveZipPath(chapterDir, src)
        const imgFile = book.zip.file(imgPath)
        if (!imgFile) {
            return undefined
        }
        const base64 = await imgFile.async('base64')
        return `data:${mediaTypeForPath(imgPath)};base64,${base64}`
    }

    html = await replaceAsync(
        html,
        /(<img\b[^>]*?\bsrc\s*=\s*)["']([^"']+)["']/gi,
        async (m) => {
            const dataUri = await toDataUri(m[2])
            return dataUri ? `${m[1]}"${dataUri}"` : m[0]
        }
    )
    // SVG <image xlink:href="..."> / <image href="...">.
    html = await replaceAsync(
        html,
        /(<image\b[^>]*?\b(?:xlink:href|href)\s*=\s*)["']([^"']+)["']/gi,
        async (m) => {
            const dataUri = await toDataUri(m[2])
            return dataUri ? `${m[1]}"${dataUri}"` : m[0]
        }
    )
    return html
}
