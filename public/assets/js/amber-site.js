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

  const terminalDemo = document.querySelector('[data-terminal-demo]');
  if (terminalDemo) {
    const terminal = terminalDemo.querySelector('.terminal-demo');
    const lines = [...terminalDemo.querySelectorAll('[data-terminal-line]')];
    const appPreview = terminalDemo.querySelector('[data-app-preview]');
    const replay = terminalDemo.querySelector('[data-terminal-replay]');
    let timers = [];

    const clearTimers = () => {
      timers.forEach((timer) => window.clearTimeout(timer));
      timers = [];
    };

    const showCompleteSession = () => {
      clearTimers();
      terminal.classList.remove('is-animating');
      lines.forEach((line) => line.classList.add('is-visible'));
      appPreview.classList.remove('is-waiting');
    };

    const replaySession = () => {
      if (reducedMotion) {
        showCompleteSession();
        return;
      }

      clearTimers();
      terminal.classList.add('is-animating');
      lines.forEach((line) => line.classList.remove('is-visible'));
      appPreview.classList.add('is-waiting');

      lines.forEach((line, index) => {
        const delay = 260 + (index * 430);
        timers.push(window.setTimeout(() => {
          line.classList.add('is-visible');
          if (line.hasAttribute('data-terminal-ready')) {
            timers.push(window.setTimeout(() => appPreview.classList.remove('is-waiting'), 340));
          }
        }, delay));
      });
    };

    replay?.addEventListener('click', replaySession);
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
