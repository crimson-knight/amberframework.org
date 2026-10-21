// Capture the actual deployment image with a checksum-verified browser library.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');
const { performance } = require('node:perf_hooks');

const pins = JSON.parse(fs.readFileSync(path.join(__dirname, 'memory_contract_render_pins.json')));
const output = '/proof';
const source = '/app/docs/v2/guides/memory-contracts.md';
const url = 'http://127.0.0.1:3212/docs/v2/guides/memory-contracts';
const origin = new URL(url).origin;
const hash = (data, algorithm = 'sha256') => crypto.createHash(algorithm).update(data).digest('hex');
const need = (condition, message) => { if (!condition) throw new Error(message); };
const write = (filename, value) => fs.writeFileSync(path.join(output, filename), JSON.stringify(value, null, 2) + '\n');

function validate(metrics) {
  need(metrics.url === url, 'The exact guide route must be rendered');
  need(metrics.headings.includes('Memory budget contracts'), 'The actual guide heading must be present');
  need(metrics.pageWidth <= metrics.viewportWidth + 1, 'The page must fit its viewport');
  need(metrics.tables >= 2, 'Both owner/window and installation tables must be rendered');
  need(metrics.imagesComplete && metrics.fontsLoaded, 'Guide assets must finish loading');
}

async function measure(page) {
  const viewport = page.viewportSize();
  const measured = await page.evaluate(() => ({
    url: location.href,
    headings: Array.from(document.querySelectorAll('h1')).map(node => node.textContent.trim()),
    observedInnerWidth: innerWidth,
    pageWidth: document.documentElement.scrollWidth,
    pageHeight: document.documentElement.scrollHeight,
    tables: document.querySelectorAll('main table').length,
    imagesComplete: Array.from(document.images).every(image => image.complete && image.naturalWidth > 0),
    fontsLoaded: document.fonts.status === 'loaded',
  }));
  return { ...measured, viewportWidth: viewport.width };
}

async function installPackage(directory) {
  const response = await fetch(pins.package_url, { signal: AbortSignal.timeout(30000) });
  need(response.ok, 'The exact browser package must be downloadable');
  const chunks = [];
  let size = 0;
  for await (const chunk of response.body) {
    size += chunk.length;
    need(size <= pins.package_bytes, 'The browser package must retain its pinned size');
    chunks.push(Buffer.from(chunk));
  }
  const raw = Buffer.concat(chunks);
  need(size === pins.package_bytes && hash(raw) === pins.package_sha256, 'Browser archive SHA-256 must match');
  need('sha512-' + crypto.createHash('sha512').update(raw).digest('base64') === pins.package_integrity,
    'Browser archive SHA-512 integrity must match');
  const archive = path.join(directory, 'package.tgz');
  const installed = path.join(directory, 'package');
  fs.writeFileSync(archive, raw);
  fs.mkdirSync(installed);
  execFileSync('/usr/bin/tar', ['-xzf', archive, '--strip-components=1', '-C', installed], { timeout: 30000 });
  const metadata = JSON.parse(fs.readFileSync(path.join(installed, 'package.json')));
  need(metadata.version === pins.package_version, 'The extracted package must retain its pinned version');
  return { library: require(installed), directory, archiveSha256: hash(raw) };
}

async function boundedTableAction(action, deadline, message) {
  const milliseconds = Math.min(2500, deadline - performance.now());
  need(Number.isFinite(milliseconds) && milliseconds > 0, 'Mobile table interaction deadline exceeded');
  let timer;
  try {
    return await Promise.race([
      action(),
      new Promise((resolve, reject) => { timer = setTimeout(() => reject(new Error(message)), milliseconds); }),
    ]);
  } finally { clearTimeout(timer); }
}

async function tableAction(page, operation, index, deadline) {
  return boundedTableAction(() => page.evaluate(({ memoryContractTableOperation, index }) => {
    const key = '__memoryContractTableProof';
    const check = (value, message) => { if (!value) throw new Error(message); };
    const regions = Array.from(document.querySelectorAll('main .table-scroll'));
    if (memoryContractTableOperation === 'prepare') {
      check(regions.length === 2 && !Object.hasOwn(window, key), 'Exactly two fresh table regions are required');
      const state = { windowX: scrollX, windowY: scrollY, focused: document.activeElement, tables: [] };
      window[key] = state;
      for (const region of regions) {
        const events = { trustedKeys: 0, touchStart: 0, touchMove: 0, touchEnd: 0, touchCancel: 0 };
        const listeners = [];
        state.tables.push({ region, left: region.scrollLeft, top: region.scrollTop, events, listeners });
        for (const [type, field] of [['touchstart', 'touchStart'], ['touchmove', 'touchMove'], ['touchend', 'touchEnd'], ['touchcancel', 'touchCancel'], ['keydown', 'trustedKeys']]) {
          const listener = event => { if (event.isTrusted && (type !== 'keydown' || event.key === 'ArrowRight')) events[field] += 1; };
          region.addEventListener(type, listener, { passive: true });
          listeners.push([type, listener]);
        }
      }
      return { regions: regions.length, positions: state.tables.map(table => ({ left: table.left, top: table.top })) };
    }
    const state = window[key];
    check(state && state.tables.length === 2, 'Owned mobile table state is required');
    if (memoryContractTableOperation === 'restore') {
      const positions = [];
      for (const table of state.tables) {
        for (const [type, listener] of table.listeners) table.region.removeEventListener(type, listener);
        table.region.scrollLeft = table.left;
        table.region.scrollTop = table.top;
        positions.push({ left: table.region.scrollLeft, top: table.region.scrollTop,
          originalLeft: table.left, originalTop: table.top });
      }
      if (state.focused && state.focused.isConnected) state.focused.focus({ preventScroll: true });
      window.scrollTo(state.windowX, state.windowY);
      const returned = { positions, windowX: scrollX, windowY: scrollY,
        originalWindowX: state.windowX, originalWindowY: state.windowY, listenersRemoved: true };
      delete window[key];
      returned.ownedStateRemoved = !Object.hasOwn(window, key);
      return returned;
    }
    const table = state.tables[index];
    check(table && table.region === regions[index], 'The exact original table region must remain present');
    const region = table.region;
    if (memoryContractTableOperation === 'focus') {
      region.scrollIntoView({ block: 'start', inline: 'nearest' });
      window.scrollBy(0, -96);
      region.focus({ preventScroll: true });
    }
    if (memoryContractTableOperation === 'reset') region.scrollLeft = table.left;
    const element = region.querySelector('table');
    const heading = element && element.querySelector('thead tr') && element.querySelector('thead tr').lastElementChild;
    const firstRow = element && element.querySelector('tbody tr');
    const cell = firstRow && firstRow.lastElementChild;
    check(heading && cell, 'The rightmost table heading and first data cell must exist');
    const bounds = region.getBoundingClientRect();
    const clipLeft = Math.max(0, bounds.left + region.clientLeft);
    const clipRight = Math.min(innerWidth, bounds.left + region.clientLeft + region.clientWidth);
    const range = document.createRange();
    range.selectNodeContents(cell);
    const rectangles = Array.from(range.getClientRects());
    check(rectangles.length > 0 && rectangles.length <= 64, 'Finite rendered rightmost cell text is required');
    const visibleRows = rectangles.filter(rect => rect.width > 0 && rect.height > 0 && rect.top >= 76 && rect.bottom <= innerHeight);
    const edge = visibleRows.sort((a, b) => b.right - a.right)[0];
    const point = edge && edge.right > clipLeft + 8 && edge.right <= clipRight + 1
      ? { x: edge.right - 2, y: (edge.top + edge.bottom) / 2 } : null;
    const hit = point && document.elementFromPoint(point.x, point.y);
    return { index, heading: heading.textContent.trim(), probeText: cell.textContent.trim().replace(/\s+/g, ' '),
      role: region.getAttribute('role'), label: region.getAttribute('aria-label'), tabIndex: region.tabIndex,
      overflowX: getComputedStyle(region).overflowX, focused: document.activeElement === region,
      left: region.scrollLeft, top: region.scrollTop, maximumLeft: region.scrollWidth - region.clientWidth,
      clipLeft, clipRight, gestureY: Math.min(innerHeight - 32, bounds.top + 70),
      atRightEnd: Math.abs(region.scrollWidth - region.clientWidth - region.scrollLeft) <= 2,
      rightEdgeTextVisible: Boolean(hit && (hit === cell || cell.contains(hit))),
      rightEdgePoint: point, events: { ...table.events } };
  }, { memoryContractTableOperation: operation, index }), deadline, 'Mobile table DOM operation exceeded its bound');
}

async function verifyMobileTables(page, context, proof, browserErrors) {
  const started = performance.now();
  const deadline = started + 30000;
  let session;
  let prepared = false;
  let primaryError;
  proof.maximumMilliseconds = 30000;
  proof.cleanupMaximumMilliseconds = 5000;
  proof.tables = [];
  proof.cleanupErrors = [];
  proof.passed = false;
  try {
    prepared = true;
    proof.initial = await tableAction(page, 'prepare', 0, deadline);
    need(proof.initial.regions === 2 && proof.initial.positions.every(position => position.left === 0), 'Both mobile tables must start at their original left edge');
    session = await boundedTableAction(() => context.newCDPSession(page), deadline, 'Mobile table CDP session exceeded its bound');
    for (const [index, heading, probeText] of [
      [0, 'What the check establishes', 'Allocation calls and requested bytes attributable to that fiber'],
      [1, 'Evidence to retain', 'Generated checksum-bearing lock, successful frozen installation, exact installed membership, and package/script ordering'],
    ]) {
      const row = { index, heading, keyboard: { samples: [] }, touch: { gestures: [], samples: [] } };
      proof.tables.push(row);
      const initial = await tableAction(page, 'focus', index, deadline);
      row.initial = initial;
      need(initial.heading === heading && initial.probeText === probeText, 'The exact rightmost source table content must be present');
      need(initial.role === 'region' && initial.label === 'Scrollable documentation table' && initial.tabIndex === 0 && initial.focused,
        'Each mobile table must expose and focus its labeled keyboard region');
      need(['auto', 'scroll'].includes(initial.overflowX) && initial.maximumLeft > 0 && initial.maximumLeft <= 640 &&
        !initial.atRightEnd && !initial.rightEdgeTextVisible && initial.clipRight - initial.clipLeft >= 240,
      'Each mobile table must provide a finite horizontal path to initially hidden rightmost text');
      let keyboard = initial;
      for (let count = 0; count < 24 && !keyboard.atRightEnd; count += 1) {
        await boundedTableAction(() => page.keyboard.press('ArrowRight', { delay: 20 }), deadline, 'Table keyboard input exceeded its bound');
        await boundedTableAction(() => new Promise(resolve => setTimeout(resolve, 35)), deadline, 'Table keyboard settle exceeded its bound');
        keyboard = await tableAction(page, 'snapshot', index, deadline);
        row.keyboard.samples.push(keyboard);
      }
      row.keyboard.final = keyboard;
      need(keyboard.focused && keyboard.atRightEnd && keyboard.left > initial.left + 1 && keyboard.rightEdgeTextVisible && keyboard.events.trustedKeys > 0,
        'Keyboard input must reach and reveal the rightmost table content');
      const reset = await tableAction(page, 'reset', index, deadline);
      need(Math.abs(reset.left - initial.left) <= 1 && !reset.atRightEnd, 'The keyboard table position must restore before touch input');
      row.touch.initial = reset;
      let touch = reset;
      for (let count = 0; count < 3 && !touch.atRightEnd; count += 1) {
        const gesture = { x: touch.clipRight - 24, y: touch.gestureY,
          xDistance: -Math.min(touch.maximumLeft + 32, touch.clipRight - touch.clipLeft - 48),
          yDistance: 0, speed: 600, preventFling: true, gestureSourceType: 'touch' };
        need(gesture.x > touch.clipLeft + 24 && gesture.y >= 76 && gesture.y <= page.viewportSize().height - 24,
          'The touch gesture must begin inside the visible table');
        row.touch.gestures.push(gesture);
        await boundedTableAction(() => session.send('Input.synthesizeScrollGesture', gesture), deadline, 'Table touch gesture exceeded its bound');
        await boundedTableAction(() => new Promise(resolve => setTimeout(resolve, 35)), deadline, 'Table touch settle exceeded its bound');
        touch = await tableAction(page, 'snapshot', index, deadline);
        row.touch.samples.push(touch);
      }
      row.touch.final = touch;
      need(touch.atRightEnd && touch.left > reset.left + 1 && touch.rightEdgeTextVisible && touch.events.touchStart > 0 &&
        touch.events.touchMove > 0 && touch.events.touchEnd > 0 && touch.events.touchCancel === 0,
      'Trusted mobile touch input must reach and reveal the rightmost table content');
      row.passed = true;
    }
  } catch (error) {
    primaryError = error;
    proof.error = String(error).slice(0, 2048);
    throw error;
  } finally {
    const cleanupDeadline = performance.now() + 5000;
    if (prepared) {
      try {
        proof.restoration = await tableAction(page, 'restore', 0, cleanupDeadline);
        const returned = proof.restoration;
        need(returned.listenersRemoved && returned.ownedStateRemoved && returned.positions.length === 2 && returned.positions.every(position =>
          Math.abs(position.left - position.originalLeft) <= 1 && Math.abs(position.top - position.originalTop) <= 1) &&
          Math.abs(returned.windowX - returned.originalWindowX) <= 1 && Math.abs(returned.windowY - returned.originalWindowY) <= 1,
        'All original table and page positions and temporary listeners must restore');
      } catch (error) { proof.cleanupErrors.push(String(error).slice(0, 2048)); }
    }
    if (session) {
      try { await boundedTableAction(() => session.detach(), cleanupDeadline, 'Mobile table CDP detach exceeded its bound'); }
      catch (error) { proof.cleanupErrors.push(String(error).slice(0, 2048)); }
    }
    proof.elapsedMilliseconds = performance.now() - started;
    if (!Number.isFinite(proof.elapsedMilliseconds) || proof.elapsedMilliseconds > 35000) proof.cleanupErrors.push('Mobile table proof exceeded its complete bound');
    if (proof.cleanupErrors.length > 0) {
      browserErrors.push(...proof.cleanupErrors.map(error => 'Mobile table cleanup: ' + error));
      throw primaryError || new Error(proof.cleanupErrors.join('; '));
    }
  }
  proof.passed = true;
}


async function main() {
  const result = {
    format: 'memory-contract-guide-render-proof-v1',
    passed: false,
    sourceCommit: process.env.SOURCE_COMMIT,
    image: pins.image,
    sourceSha256: null,
    scriptSha256: hash(fs.readFileSync(__filename)),
    nodeVersion: process.version,
    nodeSha256: hash(fs.readFileSync(process.execPath)),
    viewports: [],
    scope: 'Hosted deployment-image rendering and layout controls; production approval and live-origin proof remain separate.',
  };
  let browser;
  let packageDirectory;
  let primaryError;
  try {
    result.sourceSha256 = hash(fs.readFileSync(source));
    need(result.sourceSha256 === pins.guide_sha256, 'Exact reviewed guide source is required');
    packageDirectory = fs.mkdtempSync('/tmp/guide-browser-');
    const installed = await installPackage(packageDirectory);
    const executable = installed.library.chromium.executablePath();
    const browserSha256 = hash(fs.readFileSync(executable));
    browser = await installed.library.chromium.launch({ headless: true, args: ['--disable-dev-shm-usage'] });
    write('PACKAGE_IDENTITY.json', {
      image: pins.image, packageVersion: pins.package_version,
      packageSha256: installed.archiveSha256, packageIntegrity: pins.package_integrity,
      browserVersion: browser.version(), browserSha256, nodeVersion: process.version,
      nodeSha256: result.nodeSha256,
    });
    for (const viewport of [
      { label: 'desktop', width: 1440, height: 1000, isMobile: false },
      { label: 'mobile', width: 390, height: 844, isMobile: true },
    ]) {
      const context = await browser.newContext({
        viewport: { width: viewport.width, height: viewport.height },
        deviceScaleFactor: 1, isMobile: viewport.isMobile, hasTouch: viewport.isMobile,
        reducedMotion: 'reduce',
      });
      const page = await context.newPage();
      const errors = [], externalRequests = [];
      const captures = [];
      const observation = { ...viewport, errors, externalRequests, captures, completed: false };
      result.viewports.push(observation);
      const validateBehavior = () => need(errors.length === 0 && externalRequests.length === 0,
        'The guide must render with clean first-party behavior');
      page.on('pageerror', error => errors.push(String(error)));
      page.on('console', message => { if (['warning', 'error'].includes(message.type())) errors.push(message.text()); });
      await page.route('**/*', async route => {
        const requested = new URL(route.request().url());
        if (['http:', 'https:'].includes(requested.protocol) && requested.origin !== origin) {
          externalRequests.push(requested.href);
          await route.abort();
        } else await route.continue();
      });
      const response = await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
      need(response && response.status() === 200, 'The real deployment image must serve the guide');
      await page.evaluate(async () => { await document.fonts.ready; });
      await page.waitForFunction(() => Array.from(document.images).every(image => image.complete && image.naturalWidth > 0));
      const metrics = await measure(page);
      observation.metrics = metrics;
      validate(metrics);
      need(metrics.pageHeight > viewport.height && metrics.pageHeight <= 30000, 'The full guide must fit the declared capture bound');
      const originalWidth = await page.evaluate(() => {
        const previous = document.documentElement.style.minWidth;
        document.documentElement.style.minWidth = '3000px';
        return previous;
      });
      let overflowRejected = false;
      try { validate(await measure(page)); } catch (error) { overflowRejected = error.message === 'The page must fit its viewport'; }
      need(overflowRejected, 'A real injected overflow must fail the layout gate');
      observation.overflowRejected = overflowRejected;
      await page.evaluate(previous => { document.documentElement.style.minWidth = previous; }, originalWidth);
      const restored = await measure(page);
      validate(restored);
      need(restored.pageWidth === metrics.pageWidth, 'Restored page geometry must match');
      observation.restored = true;
      if (viewport.isMobile) {
        observation.mobileTableInteractions = {};
        await verifyMobileTables(page, context, observation.mobileTableInteractions, errors);
        const afterInteraction = await measure(page);
        validate(afterInteraction);
        need(afterInteraction.pageWidth === metrics.pageWidth && afterInteraction.pageHeight === metrics.pageHeight,
          'Mobile table interaction must preserve the original page geometry');
      }
      validateBehavior();
      for (const [suffix, fullPage] of [['full', true], ['viewport', false]]) {
        const filename = viewport.label + '-' + suffix + '.png';
        const image = await page.screenshot({ path: path.join(output, filename), fullPage, animations: 'disabled' });
        need(image.length > 0 && image.length <= 16 * 1024 * 1024, 'Screenshot bytes must fit their finite bound');
        captures.push({ filename, bytes: image.length, sha256: hash(image) });
        validateBehavior();
      }
      await context.close();
      validateBehavior();
      observation.completed = true;
    }
    need(hash(fs.readFileSync(source)) === result.sourceSha256, 'Guide source must remain exact through rendering');
    need(hash(fs.readFileSync(executable)) === browserSha256, 'Browser provider must remain exact through rendering');
    result.passed = true;
  } catch (error) {
    primaryError = error;
    result.error = String(error).slice(0, 2048);
    throw error;
  } finally {
    result.finalizationErrors = [];
    if (browser) {
      let timer;
      try {
        await Promise.race([
          browser.close(),
          new Promise((resolve, reject) => { timer = setTimeout(() => reject(new Error('Browser close exceeded five seconds')), 5000); }),
        ]);
      } catch (error) { result.finalizationErrors.push(String(error).slice(0, 2048)); }
      finally { clearTimeout(timer); }
    }
    if (packageDirectory) {
      try { fs.rmSync(packageDirectory, { recursive: true, force: true }); }
      catch (error) { result.finalizationErrors.push(String(error).slice(0, 2048)); }
    }
    for (const viewport of result.viewports) {
      if (viewport.errors.length > 0 || viewport.externalRequests.length > 0) {
        result.finalizationErrors.push('The ' + viewport.label + ' capture recorded browser behavior failures');
      }
    }
    if (result.finalizationErrors.length > 0) {
      result.passed = false;
      process.exitCode = 1;
    }
    try { write('RENDER_RESULT.json', result); }
    catch (error) {
      process.exitCode = 1;
      console.error('Render proof result output failure: ' + String(error));
      throw primaryError || error;
    }
  }
}

main().catch(error => { console.error(String(error)); process.exitCode = 1; });
