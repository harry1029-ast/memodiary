# design-sync notes

## This is an off-script, tokens-only sync

- MemoDiary is a Flutter app. There is no React package, `dist/` or Storybook, so design-sync's converter (`package-build.mjs`, `resync.mjs`) cannot run here. Do not try to make it.
- The owner chose a tokens-only sync (2026-11-15): colours, type scale, shapes and materials, no components. React re-creations of the Flutter widgets were offered and declined.
- Build: `node .design-sync/build-tokens.mjs --sync-lib <design-sync skill dir>/lib` writes `ds-bundle/` (gitignored). `--sync-lib` adds the `_ds_sync.json` anchor; without it the bundle has no anchor.
- Validate: `node <design-sync skill dir>/package-validate.mjs ds-bundle --no-render-check`. With zero components there is nothing to render, so the `[RENDER_SKIPPED]` warning is expected.
- First upload completed 2026-11-15 to the project "MemoDiary Ink Diary" (`projectId` in `config.json`). `pkg` is a label only: there is no npm package.
- Re-sync procedure: rebuild with `--sync-lib`, validate, then upload in one fenced pass (the `_ds_needs_recompile` marker, then tokens, `styles.css`, `README.md` and `_ds_bundle.js`, then the marker again, then `_ds_sync.json` last). Uploading every file each time is fine; there are only 8.

## Re-sync risks

- `build-tokens.mjs` parses `lib/core/theme/ink_diary_theme.dart` by regex (token literals, ColorScheme, textTheme field order). A reformat of that file fails the build with a message naming what it could not parse; fix the parser, not the output.
- Material values from widget build methods (gradients, borders, shadows, sizes) are recorded by hand in the script and drift-checked against the Dart source. A failed drift check means a widget changed: update the recorded value.
- Dark-mode values that a widget takes from `Colors.black` are not drift-checked.

## Findings

- Fonts: the theme names `Noto Serif SC`, `Literata`, `Kaiti SC` and `Ma Shan Zheng`, but `pubspec.yaml` bundles no font files, so on device everything renders in the platform sans-serif. The tokens use the sans stack from `.stitch/DESIGN.md`, which matches the shipped look. If fonts are bundled later, update `SANS_STACK` and the `fontConst` mapping.
- `.stitch/DESIGN.md` colours and type sizes differ from the Dart theme (for example surface `#F4EFE2` against `xuanGround` `#FCF9F2`). The Dart theme is the source used here.
- No headless browser is installed on this machine, so the example in `conventions.md` and the clip-path shape tokens have not been rendered and checked visually.
- `DesignSync` needs `/design-login` run once from an interactive Claude Code session before any upload.
- The skill's base directory under `/tmp/claude-1000/bundled-skills/` changes between Claude Code releases. Find the current one from the `/design-sync` invocation before passing `--sync-lib`.
