// After-fix check: same pages as the QA crawl, in a chosen theme. Usage: node verify.mjs <light|dark> '<pages json>'
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { chromium } from 'playwright-core';
const DIR = './qa-ws';
const THEME = process.argv[2] ?? 'light'; const OUT = `${DIR}/after/${THEME}`; mkdirSync(OUT, { recursive: true });
const axe = readFileSync('./node_modules/axe-core/axe.min.js', 'utf8');
const PAGES = JSON.parse(process.argv[3] ?? '[]');
const ctx = await chromium.launchPersistentContext(`${DIR}/profile`, { executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true, viewport: { width: 1440, height: 900 } });
await ctx.addInitScript((t) => { try { localStorage.setItem('app-theme', t); } catch {} }, THEME);
const p = ctx.pages()[0] ?? await ctx.newPage();
let errs = [];
p.on('console', (m) => { if (m.type() === 'error') errs.push(m.text().replace(/\s+/g, ' ').slice(0, 200)); });
p.on('pageerror', (e) => errs.push(`pageerror: ${String(e).slice(0, 200)}`));
for (const pg of PAGES) for (const [vp, size] of [['desk', { width: 1440, height: 900 }], ['phone', { width: 390, height: 844 }]]) {
  if (pg.deskOnly && vp === 'phone') continue;
  errs = [];
  await p.setViewportSize(size);
  await p.goto(pg.url, { waitUntil: 'networkidle', timeout: 180000 }).catch((e) => errs.push(`goto: ${e}`));
  await p.waitForTimeout(pg.wait ?? 2000);
  const info = await p.evaluate(() => ({ url: location.pathname + location.hash, h1: [...document.querySelectorAll('h1')].map((h) => h.innerText.trim()), ovf: document.documentElement.scrollWidth - innerWidth, theme: document.documentElement.dataset.dashboardTheme, crumbs: [...document.querySelectorAll('nav[aria-label=Breadcrumb] li')].map((l) => l.innerText.trim()).filter(Boolean).join(' > ') }));
  await p.addScriptTag({ content: axe }).catch(() => {});
  const a11y = await p.evaluate(async () => window.axe ? (await window.axe.run(document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] } })).violations.map((v) => ({ id: v.id, n: v.nodes.length, t: v.nodes.slice(0, 3).map((n) => n.target.join(' ') + ' :: ' + (n.failureSummary || '').replace(/\s+/g, ' ').slice(0, 160)) })) : []).catch(() => []);
  await p.screenshot({ path: `${OUT}/${pg.id}-${vp}.png`, fullPage: !!pg.full });
  writeFileSync(`${OUT}/${pg.id}-${vp}.json`, JSON.stringify({ ...info, errs, a11y }, null, 1));
  console.log(`${pg.id}-${vp}: ${info.url} theme=${info.theme} h1=${JSON.stringify(info.h1)} crumbs="${info.crumbs}" ovf=${info.ovf} err=${errs.length} axe=${a11y.map((v) => v.id + 'x' + v.n).join(',') || 'clean'}`);
}
await ctx.close();
