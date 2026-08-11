(() => {
  const menuButton = document.querySelector('[data-menu-button]');
  const menu = document.querySelector('[data-site-menu]');

  if (menuButton && menu) {
    menuButton.addEventListener('click', () => {
      const open = menuButton.getAttribute('aria-expanded') === 'true';
      menuButton.setAttribute('aria-expanded', String(!open));
      menuButton.setAttribute('aria-label', open ? 'Open navigation' : 'Close navigation');
      menu.toggleAttribute('data-open', !open);
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
        const response = await fetch(url);
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
})();
