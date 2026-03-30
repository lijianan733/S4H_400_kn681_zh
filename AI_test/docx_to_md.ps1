$ErrorActionPreference = 'Stop'

$src = (Get-ChildItem -LiteralPath 'F:\vsCode\S4H_400_kn681_zh\AI_test' -Filter '*CW_FS_SDA10*.docx' | Select-Object -First 1).FullName
if ([string]::IsNullOrWhiteSpace($src)) {
    throw 'DOCX file not found.'
}

$outMd = 'F:\vsCode\S4H_400_kn681_zh\AI_test\CW_FS_SDA10_requirements.md'

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Web

$zip = [System.IO.Compression.ZipFile]::OpenRead($src)
$entry = $zip.GetEntry('word/document.xml')
if ($null -eq $entry) {
    $zip.Dispose()
    throw 'word/document.xml not found in DOCX.'
}

$sr = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
$xml = $sr.ReadToEnd()
$sr.Close()
$zip.Dispose()

$paragraphs = [regex]::Matches($xml, '<w:p\b[\s\S]*?</w:p>')
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# CW_FS_SDA10 需求文档（DOCX转写）')
$lines.Add('')

foreach ($p in $paragraphs) {
    $texts = [regex]::Matches($p.Value, '<w:t[^>]*>(.*?)</w:t>')
    if ($texts.Count -gt 0) {
        $sb = New-Object System.Text.StringBuilder
        foreach ($t in $texts) {
            [void]$sb.Append([System.Web.HttpUtility]::HtmlDecode($t.Groups[1].Value))
        }

        $line = $sb.ToString().Trim()
        if ($line.Length -gt 0) {
            $lines.Add($line)
            $lines.Add('')
        }
    }
}

[System.IO.File]::WriteAllLines($outMd, $lines, [System.Text.Encoding]::UTF8)
Write-Output ('WROTE_MD=' + $outMd)
