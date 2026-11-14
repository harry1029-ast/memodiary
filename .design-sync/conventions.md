# Building with the MemoDiary Ink Diary tokens

MemoDiary (拾光日记) is an offline Chinese/English diary app for phones, styled as ink on Xuan paper. This design system is **tokens only**: there is no component library, `window.MemoDiaryDS` is empty, and nothing needs a provider or wrapper. Build with plain elements and style them with the CSS custom properties below.

## Setup

- Load `styles.css`. It imports `tokens/colors.css`, `tokens/typography.css` and `tokens/shape.css`, and sets the page background (`--ink-xuan-ground`), text colour and font.
- Light and dark follow the system. To pin one, set `data-theme="light"` or `data-theme="dark"` on the `<html>` element. Never hard-code a hex: every colour token has a light and a dark value.
- Design for a 360px-wide phone first. Interactive targets are at least `var(--ink-touch-target)` (44px).

## Styling idiom: `var(--ink-*)`

| Purpose | Tokens |
|---|---|
| Page and paper | `--ink-xuan-ground` (page), `--ink-xuan-pure-leaf` (card), `--ink-aged-fiber` (muted card, switch track), `--ink-deckle-border` (1px card and input borders) |
| Ink (text and icons), strongest to faintest | `--ink-jiaomo` (titles), `--ink-nongmo` (body), `--ink-danmo` (secondary text), `--ink-qingmo` (hints, disabled) |
| Cinnabar, the only accent | `--ink-cinnabar` (seals, active state, date stamps), `--ink-cinnabar-wash` (tinted badge background), `--ink-cinnabar-dark` (border on cinnabar) |
| Status | `--ink-emerald-saved` (saved confirmation), `--ink-scheme-error` |
| Radii | `--ink-radius-control` (buttons, inputs), `--ink-radius-pill`, `--ink-radius-card`, `--ink-radius-dialog`, `--ink-radius-sheet` |
| Shadows | `--ink-shadow-card`, `--ink-shadow-plaque`, `--ink-shadow-medallion`, `--ink-shadow-fab`, `--ink-shadow-seal` |
| Padding | `--ink-card-padding`, `--ink-control-padding`, `--ink-input-padding`, `--ink-pill-padding`, `--ink-plaque-padding` |

Text uses the type classes, which set family, size, weight, line height, tracking and colour: `.ink-text-display-large`, `.ink-text-headline-large`, `.ink-text-headline-medium`, `.ink-text-headline-small`, `.ink-text-body-large`, `.ink-text-body-medium`, `.ink-text-body-small`, `.ink-text-label-large`, `.ink-text-label-medium`, `.ink-text-label-small`. Typography is a clean sans-serif (`--ink-font-ui`, `--ink-font-body`); do not introduce serif or calligraphic fonts. Labels are Chinese first, with a small English gloss where the app has one (for example "挥毫落墨 Write Diary").

## Signature shapes

The classical character lives in three non-rectangular shapes, each a `clip-path` value:

- `--ink-shape-begonia`: rectangle with four cut corners. Secondary plaque buttons (`--ink-plaque-fill`, `--ink-plaque-border`, `--ink-plaque-text`) and the primary write action (`--ink-fab-fill`, `--ink-fab-border`, `--ink-fab-text`, height `--ink-fab-height`).
- `--ink-shape-octagon`: octagon for square icon buttons (`--ink-medallion-fill`, `--ink-medallion-border`, size `--ink-medallion-size`).
- `--ink-shape-waist-tally`: date stamp beside each timeline entry; today's stamp is filled `--ink-cinnabar`.

`clip-path` cuts off CSS borders, so draw the border as an outer layer: the outer element takes the border colour as its background, the inner element sits 1px inside with the fill, and both use the same shape.

Parchment cards use `--ink-scroll-card-fill` with `--ink-scroll-card-border`, plus an inner hairline in `--ink-wusilan-line` inset by `--ink-wusilan-inset`.

## Where the truth lives

Read `styles.css` and the three files under `tokens/` before styling; the tables later in this README list every token with its light and dark value.

## Example: an entry card with a plaque button

```html
<article style="background: var(--ink-xuan-pure-leaf); border: var(--ink-border-hairline) solid var(--ink-deckle-border);
                border-radius: var(--ink-radius-card); box-shadow: var(--ink-shadow-card);
                padding: var(--ink-card-padding); margin: var(--ink-card-margin);">
  <div class="ink-text-label-medium">2026-11-06 09:34</div>
  <h2 class="ink-text-headline-small" style="margin: 4px 0;">无题 · 偶感</h2>
  <p class="ink-text-body-small" style="margin: 0 0 12px;">记录下一件让你觉得微小却真切的幸福。</p>
  <span style="display: inline-block; padding: 1px; background: var(--ink-plaque-border);
               clip-path: var(--ink-shape-begonia); filter: drop-shadow(var(--ink-shadow-plaque));">
    <button class="ink-text-label-medium" style="display: block; border: 0; min-height: var(--ink-touch-target);
                   padding: var(--ink-plaque-padding); background: var(--ink-plaque-fill);
                   color: var(--ink-plaque-text); clip-path: var(--ink-shape-begonia);">漫步偶遇</button>
  </span>
</article>
```
