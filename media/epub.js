(function () {
  const vscode = acquireVsCodeApi();

  const tocEl = document.getElementById('toc');
  const titleEl = document.getElementById('book-title');
  const contentEl = document.getElementById('content');
  const progressEl = document.getElementById('progress');
  const prevBtn = document.getElementById('prev');
  const nextBtn = document.getElementById('next');

  let toc = [];
  let current = 0;
  let total = 0;

  function goto(index, anchor) {
    vscode.postMessage({ command: 'goto', index: index, anchor: anchor || '' });
  }

  prevBtn.addEventListener('click', () => goto(current - 1));
  nextBtn.addEventListener('click', () => goto(current + 1));

  document.addEventListener('keydown', (e) => {
    if (e.target && /^(INPUT|TEXTAREA)$/.test(e.target.tagName)) {
      return;
    }
    if (e.key === 'ArrowLeft') {
      goto(current - 1);
    } else if (e.key === 'ArrowRight') {
      goto(current + 1);
    }
  });

  function renderToc() {
    tocEl.innerHTML = '';
    toc.forEach((entry) => {
      const item = document.createElement('div');
      item.className = 'toc-entry depth-' + Math.min(entry.depth, 3);
      item.textContent = entry.label;
      item.title = entry.label;
      item.addEventListener('click', () => goto(entry.spineIndex, entry.anchor));
      tocEl.appendChild(item);
    });
  }

  function highlightToc() {
    const entries = tocEl.querySelectorAll('.toc-entry');
    entries.forEach((el, i) => {
      el.classList.toggle('active', toc[i] && toc[i].spineIndex === current);
    });
  }

  function updateToolbar() {
    progressEl.textContent = (current + 1) + ' / ' + total;
    prevBtn.disabled = current <= 0;
    nextBtn.disabled = current >= total - 1;
  }

  window.addEventListener('message', (event) => {
    const msg = event.data;
    if (msg.type === 'init') {
      toc = msg.toc || [];
      titleEl.textContent = msg.title || '';
      titleEl.title = msg.title || '';
      renderToc();
    } else if (msg.type === 'chapter') {
      current = msg.index;
      total = msg.total;
      contentEl.innerHTML = msg.html;
      updateToolbar();
      highlightToc();
      if (msg.anchor) {
        const target = document.getElementById(msg.anchor);
        if (target) {
          target.scrollIntoView();
        } else {
          contentEl.scrollTop = 0;
        }
      } else {
        contentEl.scrollTop = 0;
      }
    }
  });

  vscode.postMessage({ command: 'ready' });
})();
