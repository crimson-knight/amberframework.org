(() => {
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const menuButton = document.querySelector('[data-menu-button]');
  const menu = document.querySelector('[data-site-menu]');

  const setMenuOpen = (open) => {
    if (!menuButton || !menu) return;
    menuButton.setAttribute('aria-expanded', String(open));
    menuButton.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
    menu.toggleAttribute('data-open', open);
  };

  if (menuButton && menu) {
    menuButton.addEventListener('click', () => {
      setMenuOpen(menuButton.getAttribute('aria-expanded') !== 'true');
    });

    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && menuButton.getAttribute('aria-expanded') === 'true') {
        setMenuOpen(false);
        menuButton.focus();
      }
    });

    document.addEventListener('click', (event) => {
      if (menuButton.getAttribute('aria-expanded') !== 'true') return;
      if (!menu.contains(event.target) && !menuButton.contains(event.target)) setMenuOpen(false);
    });
  }

  document.querySelectorAll('[data-version-select]').forEach((select) => {
    select.addEventListener('change', (event) => {
      window.location.assign(event.currentTarget.value);
    });
  });

  document.querySelectorAll('[data-copy-page]').forEach((button) => {
    button.addEventListener('click', async () => {
      const url = button.getAttribute('data-raw-url');
      if (!url) return;

      const original = button.textContent;
      try {
        const response = await fetch(url, {credentials: 'same-origin'});
        if (!response.ok) throw new Error(`Request failed: ${response.status}`);
        await navigator.clipboard.writeText(await response.text());
        button.textContent = 'Copied';
      } catch (error) {
        console.error('Unable to copy documentation page', error);
        button.textContent = 'Copy failed';
      }

      window.setTimeout(() => {
        button.textContent = original;
      }, 1800);
    });
  });

  document.querySelectorAll('[data-open-docs-ai]').forEach((link) => {
    const provider = link.getAttribute('data-open-docs-ai');
    const title = link.getAttribute('data-docs-title') || 'Amber Framework documentation';
    const rawPath = link.getAttribute('data-raw-url');
    if (!provider || !rawPath) return;

    const rawUrl = new URL(rawPath, window.location.origin).toString();
    const prompt = `Read the Amber Framework documentation page “${title}” at ${rawUrl}. Help me understand or apply it, and cite the relevant section when answering.`;
    const baseUrl = provider === 'claude' ? 'https://claude.ai/new' : 'https://chatgpt.com/';
    const destination = new URL(baseUrl);
    destination.searchParams.set('q', prompt);
    link.setAttribute('href', destination.toString());
  });

  const crystalKeywords = new Set([
    'abstract', 'alias', 'annotation', 'as', 'as?', 'begin', 'break', 'case',
    'class', 'def', 'do', 'else', 'elsif', 'end', 'ensure', 'enum', 'extend',
    'false', 'for', 'fun', 'if', 'in', 'include', 'instance_sizeof', 'is_a?',
    'lib', 'macro', 'module', 'next', 'nil', 'of', 'out', 'pointerof',
    'private', 'protected', 'require', 'rescue', 'return', 'select', 'self',
    'sizeof', 'struct', 'super', 'then', 'true', 'type', 'typeof', 'union',
    'unless', 'until', 'verbatim', 'when', 'while', 'with', 'yield'
  ]);

  const escapeCode = (value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

  const highlightCrystal = (source) => {
    const tokenPattern = /#[^\n]*|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|:[a-zA-Z_]\w*[!?=]?|@[a-zA-Z_]\w*|\b\d+(?:\.\d+)?(?:_[a-z0-9]+)?\b|\b[A-Z][A-Za-z0-9_]*(?:::[A-Z][A-Za-z0-9_]*)*\b|\b[a-z_]\w*[!?=]?(?=\s*\()|=>|->|\.\.|&&|\|\||==|!=|<=|>=|\b[a-zA-Z_][a-zA-Z0-9_?]*\b/g;
    let highlighted = '';
    let cursor = 0;

    for (const match of source.matchAll(tokenPattern)) {
      const token = match[0];
      const index = match.index;
      highlighted += escapeCode(source.slice(cursor, index));

      let kind = '';
      if (token.startsWith('#')) kind = 'comment';
      else if (token.startsWith('"') || token.startsWith("'")) kind = 'string';
      else if (token.startsWith(':')) kind = 'symbol';
      else if (token.startsWith('@')) kind = 'variable';
      else if (/^\d/.test(token)) kind = 'number';
      else if (/^[A-Z]/.test(token)) kind = 'constant';
      else if (crystalKeywords.has(token)) kind = 'keyword';
      else if (/^\s*\(/.test(source.slice(index + token.length))) kind = 'function';
      else if (/^(=>|->|\.\.|&&|\|\||==|!=|<=|>=)$/.test(token)) kind = 'operator';

      highlighted += kind
        ? `<span class="token token-${kind}">${escapeCode(token)}</span>`
        : escapeCode(token);
      cursor = index + token.length;
    }

    return highlighted + escapeCode(source.slice(cursor));
  };

  document.querySelectorAll('code.language-crystal, code.language-cr, code.language-ruby').forEach((code) => {
    if (code.hasAttribute('data-highlighted')) return;
    code.innerHTML = highlightCrystal(code.textContent || '');
    code.setAttribute('data-highlighted', 'crystal');
  });

  const terminalDemo = document.querySelector('[data-terminal-demo]');
  if (terminalDemo) {
    const terminal = terminalDemo.querySelector('.terminal-demo');
    const lines = [...terminalDemo.querySelectorAll('[data-terminal-line]')];
    const replay = terminalDemo.querySelector('[data-terminal-replay]');
    const terminalUrl = terminalDemo.querySelector('[data-terminal-url]');
    const spinnerFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    let timers = [];
    let runId = 0;

    const clearTimers = () => {
      timers.forEach((timer) => window.clearTimeout(timer));
      timers = [];
    };

    const wait = (milliseconds) => new Promise((resolve) => {
      timers.push(window.setTimeout(resolve, milliseconds));
    });

    const resetSession = () => {
      terminalDemo.classList.remove('is-browser-open');
      terminal.classList.add('is-animating');
      terminalUrl?.classList.remove('is-activated');
      lines.forEach((line) => {
        line.classList.remove('is-active', 'is-complete');
        const output = line.querySelector('[data-terminal-output]');
        const state = line.querySelector('[data-terminal-state]');
        if (output) output.textContent = '';
        if (state) state.textContent = line.classList.contains('terminal-line-ready') ? '◆' : '⠋';
      });
    };

    const showCompleteSession = () => {
      clearTimers();
      runId += 1;
      terminal.classList.remove('is-animating');
      lines.forEach((line) => {
        const output = line.querySelector('[data-terminal-output]');
        if (output) output.textContent = line.dataset.terminalText || '';
        line.classList.add('is-complete');
      });
      terminalDemo.classList.add('is-browser-open');
    };

    const typeLine = async (line, activeRun) => {
      const output = line.querySelector('[data-terminal-output]');
      const state = line.querySelector('[data-terminal-state]');
      const text = line.dataset.terminalText || '';
      const handTyped = line.dataset.terminalMode === 'typed';
      let frameIndex = 0;
      let characterIndex = 0;

      line.classList.add('is-active');

      while (characterIndex < text.length && activeRun === runId) {
        const burst = handTyped ? (characterIndex % 9 === 0 ? 2 : 1) : 3;
        characterIndex = Math.min(text.length, characterIndex + burst);
        if (output) output.textContent = text.slice(0, characterIndex);
        if (state && !line.classList.contains('terminal-line-ready')) {
          state.textContent = spinnerFrames[frameIndex % spinnerFrames.length];
          frameIndex += 1;
        }
        const rhythm = handTyped
          ? [34, 46, 28, 76, 38, 30, 112][characterIndex % 7]
          : 24;
        await wait(rhythm);
      }

      if (activeRun !== runId) return false;
      line.classList.remove('is-active');
      line.classList.add('is-complete');
      if (state && !line.classList.contains('terminal-line-ready')) state.textContent = '✓';
      await wait(handTyped ? 210 : 110);
      return activeRun === runId;
    };

    const openGeneratedApp = async (activeRun) => {
      terminalUrl?.classList.add('is-activated');
      await wait(420);
      if (activeRun !== runId) return;
      terminalDemo.classList.add('is-browser-open');
      await wait(480);
      terminalUrl?.classList.remove('is-activated');
    };

    const replaySession = async () => {
      if (reducedMotion) {
        showCompleteSession();
        return;
      }

      clearTimers();
      runId += 1;
      const activeRun = runId;
      resetSession();
      await wait(260);

      for (const line of lines) {
        if (!await typeLine(line, activeRun)) return;
      }

      await openGeneratedApp(activeRun);
    };

    replay?.addEventListener('click', replaySession);
    terminalUrl?.addEventListener('click', () => openGeneratedApp(runId));
    replaySession();
  }

  if (!reducedMotion && 'IntersectionObserver' in window) {
    document.body.classList.add('motion-ready');
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      });
    }, {rootMargin: '0px 0px -8% 0px', threshold: 0.08});

    document.querySelectorAll('.reveal').forEach((element) => observer.observe(element));
  } else {
    document.querySelectorAll('.reveal').forEach((element) => element.classList.add('is-visible'));
  }

  if (!reducedMotion) {
    document.querySelectorAll('[data-tilt]').forEach((card) => {
      card.addEventListener('pointermove', (event) => {
        if (event.pointerType === 'touch') return;
        const rect = card.getBoundingClientRect();
        const x = (event.clientX - rect.left) / rect.width;
        const y = (event.clientY - rect.top) / rect.height;
        card.style.setProperty('--tilt-y', `${(x - 0.5) * 4.5}deg`);
        card.style.setProperty('--tilt-x', `${(0.5 - y) * 4.5}deg`);
      });

      card.addEventListener('pointerleave', () => {
        card.style.setProperty('--tilt-x', '0deg');
        card.style.setProperty('--tilt-y', '0deg');
      });
    });

    document.querySelectorAll('[data-crystal-field]').forEach((field) => {
      let frame = 0;
      const update = (x, y) => {
        window.cancelAnimationFrame(frame);
        frame = window.requestAnimationFrame(() => {
          field.style.setProperty('--field-x', `${x}px`);
          field.style.setProperty('--field-y', `${y}px`);
        });
      };

      field.addEventListener('pointermove', (event) => {
        const rect = field.getBoundingClientRect();
        const x = ((event.clientX - rect.left) / rect.width - 0.5) * 24;
        const y = ((event.clientY - rect.top) / rect.height - 0.5) * 18;
        update(x, y);
      });

      field.addEventListener('pointerleave', () => update(0, 0));
      window.addEventListener('scroll', () => {
        const rect = field.getBoundingClientRect();
        const progress = Math.max(-1, Math.min(1, -rect.top / Math.max(rect.height, 1)));
        update(0, progress * 16);
      }, {passive: true});
    });
  }
})();
