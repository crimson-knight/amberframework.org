// Capture the actual deployment image with a checksum-verified browser library.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');

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
    write('RENDER_RESULT.json', result);
  }
}

main().catch(error => { console.error(String(error)); process.exitCode = 1; });
