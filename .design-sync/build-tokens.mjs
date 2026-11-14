#!/usr/bin/env node
// Tokens-only Claude Design bundle for MemoDiary.
//
// MemoDiary is a Flutter app, so there is no React package for design-sync's
// converter to bundle. This script produces the upload layout by hand from
// the Dart theme: colours, the text theme and the shape/material constants of
// the core theme widgets. It ships no components.
//
//   node .design-sync/build-tokens.mjs [--out ./ds-bundle] [--sync-lib <design-sync skill dir>/lib]
//
// Colours and the type scale are parsed from ink_diary_theme.dart. Material
// values that live inside widget build methods are recorded in MATERIALS
// below; every hex there is checked against its Dart source, so a widget that
// changes colour fails this build instead of shipping a stale token.

import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(HERE, '..');
const arg = (flag) => {
  const i = process.argv.indexOf(flag);
  return i > 0 ? process.argv[i + 1] : undefined;
};
const OUT = resolve(arg('--out') ?? join(REPO, 'ds-bundle'));
const SYNC_LIB = arg('--sync-lib');
const NAMESPACE = 'MemoDiaryDS';
const THEME_DIR = 'lib/core/theme';

const die = (msg) => {
  console.error(`✗ ${msg}`);
  process.exit(1);
};
const dart = (rel) => readFileSync(join(REPO, THEME_DIR, rel), 'utf8');
const kebab = (s) => s.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
const rgba = (hex, alpha) => {
  const n = parseInt(hex, 16);
  return `rgba(${n >> 16}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
};

// ---------------------------------------------------------------------------
// 1. Semantic colour tokens: InkDiaryTokens.light / .dark
// ---------------------------------------------------------------------------
const themeSrc = dart('ink_diary_theme.dart');

function parseInkTokens(mode) {
  const block = new RegExp(`static const ${mode} = InkDiaryTokens\\(([\\s\\S]*?)\\);`).exec(themeSrc);
  if (!block) die(`InkDiaryTokens.${mode} not found in ink_diary_theme.dart`);
  const out = {};
  for (const m of block[1].matchAll(/(\w+): Color\(0xFF([0-9A-Fa-f]{6})\)/g)) out[m[1]] = m[2].toUpperCase();
  return out;
}
const ink = { light: parseInkTokens('light'), dark: parseInkTokens('dark') };
const inkNames = Object.keys(ink.light);
const declared = [...themeSrc.matchAll(/^\s+final Color (\w+);/gm)].map((m) => m[1]);
for (const name of declared) {
  if (!ink.light[name] || !ink.dark[name]) die(`InkDiaryTokens.${name} has no light/dark literal — parser out of date`);
}
if (!declared.length) die('no `final Color` fields found on InkDiaryTokens');

// ---------------------------------------------------------------------------
// 2. Material ColorScheme roles: InkDiaryTheme.light / .dark
// ---------------------------------------------------------------------------
function parseScheme(mode) {
  const block = new RegExp(`static ThemeData get ${mode} \\{([\\s\\S]*?)return _buildTheme`).exec(themeSrc);
  if (!block) die(`InkDiaryTheme.${mode} not found`);
  const out = {};
  const line = /^\s*(\w+): (?:const )?(?:Color\(0xFF([0-9A-Fa-f]{6})\)|tokens\.(\w+)|Colors\.(white|black)),$/gm;
  for (const m of block[1].matchAll(line)) {
    out[m[1]] = m[2] ? `#${m[2].toUpperCase()}` : m[3] ? `var(--ink-${kebab(m[3])})` : m[4] === 'white' ? '#FFFFFF' : '#000000';
  }
  const expected = [...block[1].matchAll(/^\s*(\w+): /gm)].map((m) => m[1]).filter((k) => k !== 'brightness');
  const missed = expected.filter((k) => !(k in out));
  if (missed.length) die(`ColorScheme.${mode}: could not parse ${missed.join(', ')}`);
  return out;
}
const scheme = { light: parseScheme('light'), dark: parseScheme('dark') };

// ---------------------------------------------------------------------------
// 3. Type scale: ThemeData.textTheme
// ---------------------------------------------------------------------------
const textSection = themeSrc.slice(themeSrc.indexOf('textTheme: TextTheme('));
if (textSection.length === themeSrc.length) die('textTheme not found');
const fontConst = { fontNotoSerif: 'ui', fontLiterata: 'body' };
const colorRef = (expr) => {
  const [owner, name] = expr.split('.');
  if (owner === 'tokens') return `var(--ink-${kebab(name)})`;
  if (owner === 'colorScheme') return `var(--ink-scheme-${kebab(name)})`;
  die(`textTheme: unknown colour expression ${expr}`);
};
const typeScale = [...textSection.matchAll(
  /(\w+): TextStyle\(\s*fontFamily: (\w+),\s*fontSize: ([\d.]+),\s*fontWeight: FontWeight\.w(\d+),\s*height: ([\d.]+),\s*letterSpacing: ([\d.]+),\s*color: ([\w.]+),/g,
)].map((m) => {
  if (!fontConst[m[2]]) die(`textTheme.${m[1]}: unknown font constant ${m[2]}`);
  return { name: kebab(m[1]), font: fontConst[m[2]], size: m[3], weight: m[4], lineHeight: m[5], tracking: m[6], color: colorRef(m[7]) };
});
const styleCount = (textSection.match(/: TextStyle\(/g) ?? []).length;
if (!typeScale.length || typeScale.length !== styleCount) {
  die(`textTheme: parsed ${typeScale.length} of ${styleCount} styles — a style no longer matches the expected field order`);
}

// The theme names 'Noto Serif SC' and 'Literata', but pubspec.yaml bundles no
// font files, so both resolve to the platform sans-serif on device. The stack
// below is the one .stitch/DESIGN.md specifies and matches what ships.
const SANS_STACK = `"Noto Sans SC", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif`;

// ---------------------------------------------------------------------------
// 4. Materials recorded from widget build methods (drift-checked, see below)
// ---------------------------------------------------------------------------
const MATERIALS = [
  // BegoniaPlaqueButton — chamfered plaque (e.g. the "My Diary" notebook switcher)
  { name: 'plaque-fill', src: 'widgets/begonia_plaque_button.dart', light: ['180deg', 'FAF6EC', 'EAE0CC'], dark: ['180deg', '2B2824', '1E1C19'] },
  { name: 'plaque-accent-fill', src: 'widgets/begonia_plaque_button.dart', light: ['180deg', 'BA372A', '98261B'], dark: ['180deg', '98261B', '6E180F'] },
  { name: 'plaque-border', src: 'widgets/begonia_plaque_button.dart', light: 'B89B72', dark: 'token:deckleBorder' },
  { name: 'plaque-text', src: 'widgets/begonia_plaque_button.dart', light: '8F2419', dark: 'token:jiaomo' },
  // OctagonalMedallionButton — app-bar icon buttons
  { name: 'medallion-fill', src: 'widgets/octagonal_medallion_button.dart', light: ['135deg', 'F9F5EB', 'E6DCC8'], dark: ['135deg', '2C2A26', '1F1D1A'] },
  { name: 'medallion-border', src: 'widgets/octagonal_medallion_button.dart', light: 'B5A486', dark: 'token:deckleBorder' },
  // ScrollRollerFab — the "挥毫落墨 Write Diary" action
  { name: 'fab-fill', src: 'widgets/scroll_roller_fab.dart', light: ['180deg', 'C43E30', 'A82F22', '8C2014'], dark: ['180deg', '9E2E22', '7A1F16', '5E150E'] },
  { name: 'fab-border', src: 'widgets/scroll_roller_fab.dart', light: 'D9A962', dark: '8B6B3E' },
  { name: 'fab-text', src: 'widgets/scroll_roller_fab.dart', light: 'FFF9F2', dark: 'FFF9F2' },
  { name: 'fab-rail-top', src: 'widgets/scroll_roller_fab.dart', light: ['alpha', 'FFDF9E', 0.7], dark: ['alpha', 'FFDF9E', 0.7] },
  { name: 'fab-rail-bottom', src: 'widgets/scroll_roller_fab.dart', light: ['alpha', 'B5833E', 0.7], dark: ['alpha', 'B5833E', 0.7] },
  // WusilanScrollCard — parchment card with a double-line inner frame
  { name: 'scroll-card-fill', src: 'widgets/wusilan_scroll_card.dart', light: ['180deg', 'FBF8F0', 'F0E9DA'], dark: ['180deg', '282521', '1D1B18'] },
  { name: 'scroll-card-border', src: 'widgets/wusilan_scroll_card.dart', light: 'C4B59B', dark: 'token:deckleBorder' },
  { name: 'wusilan-line', src: 'widgets/wusilan_scroll_card.dart', light: ['alpha', '8A7B62', 0.28], dark: ['alpha', 'token:qingmo', 0.25] },
];

const SHADOWS = [
  // XuanPaperCard: two stacked jiaomo shadows
  { name: 'card', light: ['0 4px 16px -2px', 'token:jiaomo', 0.04, '0 1px 4px', 'token:jiaomo', 0.02], dark: ['0 4px 16px -2px', 'token:jiaomo', 0.25, '0 1px 4px', 'token:jiaomo', 0.15] },
  { name: 'scroll-card', src: 'widgets/wusilan_scroll_card.dart', light: ['0 3px 10px', '1C1914', 0.08], dark: ['0 3px 10px', '000000', 0.4] },
  { name: 'plaque', src: 'widgets/begonia_plaque_button.dart', light: ['0 1.5px 4px', '2A2216', 0.08], dark: ['0 1.5px 4px', '000000', 0.35] },
  { name: 'medallion', src: 'widgets/octagonal_medallion_button.dart', light: ['0 1.5px 4px', '2A2216', 0.12], dark: ['0 1.5px 4px', '000000', 0.4] },
  { name: 'fab', src: 'widgets/scroll_roller_fab.dart', light: ['0 5px 12px -2px', '8C2014', 0.45], dark: ['0 5px 12px -2px', '000000', 0.55] },
  { name: 'seal', light: ['0 2px 6px', 'token:cinnabar', 0.3], dark: ['0 2px 6px', 'token:cinnabar', 0.3] },
];

// Fixed geometry: [css name, value, Dart source, literal that must still be in that source]
const GEOMETRY = [
  ['radius-seal-square', '2px', 'widgets/cinnabar_seal_badge.dart', 'BorderRadius.circular(2.0)'],
  ['radius-seal', '6px', 'widgets/cinnabar_seal_badge.dart', 'BorderRadius.circular(6.0)'],
  ['radius-control', '8px', 'ink_diary_theme.dart', 'BorderRadius.circular(8)'],
  ['radius-pill', '10px', 'widgets/ink_metadata_pill.dart', 'BorderRadius.circular(10)'],
  ['radius-scroll-card', '10px', 'widgets/wusilan_scroll_card.dart', 'this.borderRadius = 10.0'],
  ['radius-card', '12px', 'widgets/xuan_paper_card.dart', 'this.borderRadius = 12.0'],
  ['radius-dialog', '16px', 'ink_diary_theme.dart', 'BorderRadius.circular(16)'],
  ['radius-sheet', '24px', 'ink_diary_theme.dart', 'Radius.circular(24)'],
  ['border-hairline', '1px', 'widgets/xuan_paper_card.dart', 'Border.all(color: border, width: 1.0)'],
  ['border-seal', '1.2px', 'widgets/cinnabar_seal_badge.dart', 'width: 1.2'],
  ['border-focus', '1.5px', 'ink_diary_theme.dart', 'BorderSide(color: tokens.jiaomo, width: 1.5)'],
  ['border-fab', '1.5px', 'widgets/scroll_roller_fab.dart', 'borderWidth: 1.5'],
  ['wusilan-inset', '3.5px', 'widgets/wusilan_scroll_card.dart', 'inset: 3.5'],
  ['begonia-cut', '6px', 'widgets/begonia_plaque_button.dart', 'this.cutSize = 6.0'],
  ['octagon-chamfer', '28%', 'shapes/classical_chinese_borders.dart', 'this.chamferRatio = 0.28'],
  ['tally-cut', '8px', 'shapes/classical_chinese_borders.dart', 'this.cutSize = 8.0'],
  ['card-padding', '16px', 'widgets/xuan_paper_card.dart', 'this.padding = const EdgeInsets.all(16)'],
  ['card-margin', '8px 16px', 'widgets/xuan_paper_card.dart', 'EdgeInsets.symmetric(horizontal: 16, vertical: 8)'],
  ['control-padding', '12px 16px', 'ink_diary_theme.dart', 'EdgeInsets.symmetric(horizontal: 16, vertical: 12)'],
  ['input-padding', '12px 14px', 'ink_diary_theme.dart', 'EdgeInsets.symmetric(horizontal: 14, vertical: 12)'],
  ['pill-padding', '6px 10px', 'widgets/ink_metadata_pill.dart', 'EdgeInsets.symmetric(horizontal: 10, vertical: 6)'],
  ['plaque-padding', '5px 10px', 'widgets/begonia_plaque_button.dart', 'EdgeInsets.symmetric(horizontal: 10, vertical: 5)'],
  ['medallion-size', '38px', 'widgets/octagonal_medallion_button.dart', 'this.size = 38.0'],
  ['fab-height', '44px', 'widgets/scroll_roller_fab.dart', 'const height = 44.0'],
  ['fab-width', '178px', 'widgets/scroll_roller_fab.dart', '178.0'],
  ['fab-width-rolled', '52px', 'widgets/scroll_roller_fab.dart', '52.0'],
  ['seal-size', '44px', 'widgets/cinnabar_seal_badge.dart', 'this.size = 44.0'],
  ['seal-size-wash', '32px', 'widgets/cinnabar_seal_badge.dart', 'this.size = 32.0'],
  ['seal-size-compact', '28px', 'widgets/cinnabar_seal_badge.dart', 'this.size = 28.0'],
  ['duration-fab', '260ms', 'widgets/scroll_roller_fab.dart', 'Duration(milliseconds: 260)'],
  ['duration-switch', '200ms', 'widgets/ink_switch.dart', 'Duration(milliseconds: 200)'],
];

// Drift guard: every literal recorded above must still be in its Dart source.
const srcCache = new Map();
const srcOf = (rel) => srcCache.get(rel) ?? srcCache.set(rel, dart(rel)).get(rel);
const drift = [];
const hexesOf = (v) => (Array.isArray(v) ? v : [v]).filter((x) => typeof x === 'string' && /^[0-9A-F]{6}$/.test(x) && x !== '000000');
for (const m of [...MATERIALS, ...SHADOWS]) {
  if (!m.src) continue;
  for (const hex of [...hexesOf(m.light), ...hexesOf(m.dark)]) {
    if (!srcOf(m.src).includes(`Color(0xFF${hex})`)) drift.push(`${m.name}: #${hex} no longer in ${THEME_DIR}/${m.src}`);
  }
}
for (const [name, , src, literal] of GEOMETRY) {
  if (!srcOf(src).includes(literal)) drift.push(`${name}: \`${literal}\` no longer in ${THEME_DIR}/${src}`);
}
if (drift.length) die(`recorded values drifted from the Dart source — update build-tokens.mjs:\n  ${drift.join('\n  ')}`);

// ---------------------------------------------------------------------------
// Emit
// ---------------------------------------------------------------------------
const colorOf = (v, mode) => (v.startsWith('token:') ? ink[mode][v.slice(6)] : v);
const materialValue = (v, mode) => {
  if (typeof v === 'string') return v.startsWith('token:') ? `var(--ink-${kebab(v.slice(6))})` : `#${v}`;
  if (v[0] === 'alpha') return rgba(colorOf(v[1], mode), v[2]);
  return `linear-gradient(${v[0]}, ${v.slice(1).map((h) => `#${h}`).join(', ')})`;
};
const shadowValue = (v, mode) => {
  const parts = [];
  for (let i = 0; i < v.length; i += 3) parts.push(`${v[i]} ${rgba(colorOf(v[i + 1], mode), v[i + 2])}`);
  return parts.join(', ');
};
const modeVars = (mode) => [
  ...inkNames.map((n) => [`--ink-${kebab(n)}`, `#${ink[mode][n]}`]),
  ...Object.entries(scheme[mode]).map(([k, v]) => [`--ink-scheme-${kebab(k)}`, v]),
  ...MATERIALS.map((m) => [`--ink-${m.name}`, materialValue(m[mode], mode)]),
  ...SHADOWS.map((s) => [`--ink-shadow-${s.name}`, shadowValue(s[mode], mode)]),
];
const decls = (vars, indent) => vars.map(([k, v]) => `${indent}${k}: ${v};`).join('\n');
const BANNER = '/* Generated by .design-sync/build-tokens.mjs from lib/core/theme — do not edit. */\n';

const colorsCss = `${BANNER}
:root {
  color-scheme: light dark;
${decls(modeVars('light'), '  ')}
}

/* Dark follows the system unless the root pins a theme with data-theme. */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
${decls(modeVars('dark'), '    ')}
  }
}
:root[data-theme="dark"] {
${decls(modeVars('dark'), '  ')}
}
`;

const typographyCss = `${BANNER}
:root {
  --ink-font-ui: ${SANS_STACK};
  --ink-font-body: ${SANS_STACK};
${typeScale.map((t) => `  --ink-text-${t.name}-size: ${t.size}px;`).join('\n')}
}

${typeScale.map((t) => `.ink-text-${t.name} {
  font-family: var(--ink-font-${t.font});
  font-size: var(--ink-text-${t.name}-size);
  font-weight: ${t.weight};
  line-height: ${t.lineHeight};
  letter-spacing: ${t.tracking}px;
  color: ${t.color};
}`).join('\n')}
`;

const shapeCss = `${BANNER}
:root {
${decls(GEOMETRY.map(([k, v]) => [`--ink-${k}`, v]), '  ')}
  --ink-touch-target: 44px;
  --ink-ease-fab: cubic-bezier(0.215, 0.61, 0.355, 1);
  --ink-ease-switch: ease-in-out;

  /* clip-path shapes (shapes/classical_chinese_borders.dart) */
  --ink-shape-begonia: polygon(
    var(--ink-begonia-cut) 0, calc(100% - var(--ink-begonia-cut)) 0,
    100% var(--ink-begonia-cut), 100% calc(100% - var(--ink-begonia-cut)),
    calc(100% - var(--ink-begonia-cut)) 100%, var(--ink-begonia-cut) 100%,
    0 calc(100% - var(--ink-begonia-cut)), 0 var(--ink-begonia-cut));
  --ink-shape-octagon: polygon(
    var(--ink-octagon-chamfer) 0, calc(100% - var(--ink-octagon-chamfer)) 0,
    100% var(--ink-octagon-chamfer), 100% calc(100% - var(--ink-octagon-chamfer)),
    calc(100% - var(--ink-octagon-chamfer)) 100%, var(--ink-octagon-chamfer) 100%,
    0 calc(100% - var(--ink-octagon-chamfer)), 0 var(--ink-octagon-chamfer));
  --ink-shape-waist-tally: polygon(
    var(--ink-tally-cut) 0, calc(100% - var(--ink-tally-cut)) 0,
    100% var(--ink-tally-cut), 100% calc(100% - var(--ink-tally-cut) * 0.75),
    calc(100% - var(--ink-tally-cut) * 0.75) 100%, calc(var(--ink-tally-cut) * 0.75) 100%,
    0 calc(100% - var(--ink-tally-cut) * 0.75), 0 var(--ink-tally-cut));
}
`;

const stylesCss = `${BANNER}
@import "./tokens/colors.css";
@import "./tokens/typography.css";
@import "./tokens/shape.css";

body {
  margin: 0;
  background: var(--ink-xuan-ground);
  color: var(--ink-jiaomo);
  font-family: var(--ink-font-body);
}
`;

// README: the conventions header (hand-authored) + a generated token index.
let config = {};
try { config = JSON.parse(readFileSync(join(HERE, 'config.json'), 'utf8')); } catch { /* optional */ }
const headerPath = config.readmeHeader ? resolve(REPO, config.readmeHeader) : null;
const header = headerPath && existsSync(headerPath) ? `${readFileSync(headerPath, 'utf8').trimEnd()}\n\n---\n\n` : '';
const row = (cells) => `| ${cells.join(' | ')} |`;
const lightVars = new Map(modeVars('light'));
const darkVars = new Map(modeVars('dark'));
const table = (names) => [row(['Token', 'Light', 'Dark']), row(['---', '---', '---']),
  ...names.map((n) => row([`\`${n}\``, `\`${lightVars.get(n)}\``, `\`${darkVars.get(n)}\``]))].join('\n');
const readme = `${header}# MemoDiary (拾光日记) — Ink Diary tokens

Tokens-only design system generated from the Flutter theme in \`${THEME_DIR}\`. It ships no components:
\`window.${NAMESPACE}\` is empty. Everything is CSS custom properties reachable from \`styles.css\`.

## Colour

${table(inkNames.map((n) => `--ink-${kebab(n)}`))}

## Material colour roles

${table(Object.keys(scheme.light).map((k) => `--ink-scheme-${kebab(k)}`))}

## Materials and shadows

${table([...MATERIALS.map((m) => `--ink-${m.name}`), ...SHADOWS.map((s) => `--ink-shadow-${s.name}`)])}

## Type scale

${[row(['Class', 'Font', 'Size', 'Weight', 'Line height', 'Tracking']), row(['---', '---', '---', '---', '---', '---']),
    ...typeScale.map((t) => row([`\`.ink-text-${t.name}\``, `\`--ink-font-${t.font}\``, `${t.size}px`, t.weight, t.lineHeight, `${t.tracking}px`]))].join('\n')}

## Geometry and motion

${[row(['Token', 'Value']), row(['---', '---']), ...GEOMETRY.map(([k, v]) => row([`\`--ink-${k}\``, `\`${v}\``])),
    row(['`--ink-touch-target`', '`44px`']), row(['`--ink-shape-begonia`', 'clip-path polygon, cut = `--ink-begonia-cut`']),
    row(['`--ink-shape-octagon`', 'clip-path polygon, chamfer = `--ink-octagon-chamfer`']),
    row(['`--ink-shape-waist-tally`', 'clip-path polygon, cut = `--ink-tally-cut`'])].join('\n')}
`;

const bundleHeader = { namespace: NAMESPACE, components: [], sourceHashes: {}, inlinedExternals: [] };
const bundleJs = `/* @ds-bundle: ${JSON.stringify(bundleHeader)} */
(function () { window.${NAMESPACE} = window.${NAMESPACE} || {}; })();
`;

rmSync(OUT, { recursive: true, force: true });
mkdirSync(join(OUT, 'tokens'), { recursive: true });
const write = (rel, text) => writeFileSync(join(OUT, rel), text);
write('tokens/colors.css', colorsCss);
write('tokens/typography.css', typographyCss);
write('tokens/shape.css', shapeCss);
write('styles.css', stylesCss);
write('README.md', readme);
write('_ds_bundle.js', bundleJs);
write('_ds_needs_recompile', '{"by":"design-sync-cli"}\n');
write('.ds-build-meta.json', `${JSON.stringify({ shape: 'package', componentCount: 0, tokensOnly: true, generator: '.design-sync/build-tokens.mjs' }, null, 2)}\n`);

// Verification anchor. Needs the design-sync skill's hash recipe, so it is
// written only when --sync-lib points at that skill's lib/ directory.
if (SYNC_LIB) {
  const { styleShaFor, auxShaFor, scriptsShaFor, KEY_RECIPE } = await import(pathToFileURL(resolve(SYNC_LIB, 'sync-hashes.mjs')).href);
  const bundleSha12 = createHash('sha256').update(readFileSync(join(OUT, '_ds_bundle.js'))).digest('hex').slice(0, 12);
  write('_ds_sync.json', `${JSON.stringify({
    shape: 'package', styleSha: styleShaFor(OUT, { includeBundleBody: true }), renderHashes: {}, sourceKeys: {},
    keyRecipe: KEY_RECIPE, scriptsSha: scriptsShaFor(), sourceHashes: {}, auxSha: auxShaFor(OUT), bundleSha12,
  }, null, 2)}\n`);
}

console.error(`✓ wrote ${OUT}: ${inkNames.length} ink colours, ${Object.keys(scheme.light).length} scheme roles, `
  + `${MATERIALS.length} materials, ${SHADOWS.length} shadows, ${typeScale.length} text styles, ${GEOMETRY.length} geometry tokens`
  + `${header ? ', conventions header prepended' : ''}${SYNC_LIB ? ', anchor written' : ''}`);
