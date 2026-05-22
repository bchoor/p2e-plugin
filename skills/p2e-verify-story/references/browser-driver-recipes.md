# Browser-Driver MCP Recipes

Patterns for driving a browser via the available MCP — `mcp__chrome-devtools__*` (preferred; richer ops, CDP-backed) or `mcp__claude-in-chrome__*` (fallback; extension-backed). Each entry is a failure mode encountered in practice plus the working recipe.

## Picking the MCP

- **`mcp__chrome-devtools__*`** is preferred when both are available. It speaks CDP directly, so it gives stable UIDs from `take_snapshot`, real pointer events for `:hover`, and richer screenshot / network introspection.
- **`mcp__claude-in-chrome__*`** is the fallback. It works via a Chrome extension and exposes most of the same ops under different tool names. Use when chrome-devtools is not connected.

This file uses chrome-devtools names. For claude-in-chrome equivalents:
- `take_snapshot` → `read_page` (a11y tree text) or `find` (returns matches)
- `click` / `fill` / `hover` → `computer` (with action) or `form_input`
- `take_screenshot` → `get_screenshot`
- `evaluate_script` → `javascript_tool`
- `navigate_page` → `navigate`
- `new_page` → `tabs_create_mcp`

If neither MCP is connected, stop with a concrete blocker message. Do not attempt to verify UI ACs without a browser-driver MCP.

## Loading the toolkit

Both MCPs ship their tools as deferred. Load all of them in one bulk ToolSearch call rather than one-by-one:

```
ToolSearch(query: "chrome-devtools", max_results: 30)
```

or

```
ToolSearch(query: "claude-in-chrome", max_results: 30)
```

A keyword search matches every tool in one round-trip. Avoid `select:` for individual tools — that's one round-trip per tool.

## Finding elements

### Prefer take_snapshot for stable UIDs (chrome-devtools)

```js
mcp__chrome-devtools__take_snapshot({ filePath: ".claude/snap.txt" })  // save to file if large
```

The snapshot returns the a11y tree with `uid=<n>_<m>` markers. Pass the UID to `click`, `hover`, `fill`, `drag`. UIDs are stable within a snapshot but change on every fresh snapshot — always take a new snapshot before a new sequence of UID-keyed actions.

When the snapshot is too large to inline-return (> ~50KB), pass `filePath` and `grep` the file for the labels you need:

```bash
grep -nE "menu|menuitemcheckbox|Apply" .claude/snap.txt | head -10
```

### Prefer evaluate_script for finding by text content

When you need to find an element by visible text and don't care about UID stability:

```js
() => {
  const items = [...document.querySelectorAll('[role="menuitemradio"]')];
  return items.find(el => (el.textContent || '').trim().endsWith("Git: HEAD"))?.outerHTML;
}
```

This is faster than take_snapshot for known structural queries. But you cannot click the returned element from another evaluate_script call — JS clicks don't reliably trigger React state updates and don't trigger CSS `:hover`. Use take_snapshot + UID-based click instead.

## Hovering for CSS-driven submenus

Many UI libraries reveal nested menus on CSS `:hover` without a JS event listener. JS `.dispatchEvent(new MouseEvent("mouseenter"))` does NOT trigger `:hover` — it dispatches the event but the pseudo-class is browser-managed.

Wrong:
```js
el.dispatchEvent(new MouseEvent("mouseenter", { bubbles: true }));
```

Right:
```js
mcp__chrome-devtools__hover({ uid: "<uid-of-parent-menu-item>" })
```

The chrome-devtools `hover` tool drives a real pointer event through the CDP, so `:hover` engages and the CSS reveal fires. Confirm by taking a new snapshot — the submenu's items should appear with new UIDs.

## React-controlled input fields

React's controlled inputs read from props, not from the DOM `value`. Setting `input.value = "x"` directly doesn't fire React's onChange:

Wrong:
```js
input.value = "nonexistent-ref-xyz";
input.dispatchEvent(new Event("input", { bubbles: true }));  // doesn't reach React
```

Right:
```js
const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
setter.call(input, "nonexistent-ref-xyz");
input.dispatchEvent(new Event("input", { bubbles: true }));
```

The descriptor-setter trick bypasses React's value tracking, then the dispatched `input` event triggers the synthetic event React listens for.

Alternative for simple cases: use `mcp__chrome-devtools__fill` with the input's UID — it does the React-compatible value setting under the hood.

## Capturing transient UI (toasts, tooltips)

Toasts auto-dismiss in 1–5 seconds depending on the library. The MCP click → screenshot round-trip is often slower than that, so the toast has vanished by the time `take_screenshot` fires.

Fix: inject a CSS pin BEFORE triggering the toast, so it stays painted regardless of the dismiss timer:

```js
() => {
  const style = document.createElement("style");
  style.id = "verify-toast-pin";
  style.textContent = `
    .toast, [role="status"], [role="alert"], [class*="toast"] {
      opacity: 1 !important;
      transform: none !important;
      transition: none !important;
      animation: none !important;
    }
  `;
  document.head.appendChild(style);
  return { pinned: true };
}
```

The pin works because most toast libraries unmount the element only when the *parent state* clears the toast — but with a long enough display window (or by overriding the CSS that the dismiss timer toggles), the element stays visible long enough to screenshot. Clean up the style element after capture if needed.

For Sonner / react-hot-toast: the toast usually has classes like `.toast`, `.go2072408551`, etc. Target by role attribute (`[role="status"]`, `[role="alert"]`) and class pattern (`[class*="toast"]`) for broad coverage.

## Reading network requests

After a UI action, list the network requests to confirm the right backend call was made:

```js
mcp__chrome-devtools__list_network_requests({
  resourceTypes: ["fetch", "xhr"],
  pageSize: 10
})
```

For details on a single request:

```js
mcp__chrome-devtools__get_network_request({ reqid: <id> })
```

This shows headers + response body. Useful for confirming AC-specified status codes (200 / 404 / etc.) and JSON shape.

## Reading console logs

```js
mcp__chrome-devtools__list_console_messages({
  types: ["error", "warn"],
  pageSize: 20
})
```

Filter by type. Errors during the AC flow that aren't directly related to the AC should be noted in the report as a separate observation, since they indicate adjacent regression risk.

## Taking screenshots

### Viewport screenshot

```js
mcp__chrome-devtools__take_screenshot({
  filePath: "/abs/path/to/01-ac-name.png"
})
```

### Full-page (for the report preview)

```js
mcp__chrome-devtools__take_screenshot({
  filePath: "/abs/path/to/00-report-preview.png",
  fullPage: true
})
```

Use full-page for the report itself (so reviewers can see the whole document in one image when the HTML isn't rendered, e.g. when pasted into a GH issue body).

### Element screenshot via UID

```js
mcp__chrome-devtools__take_screenshot({ uid: "<uid>", filePath: ... })
```

Crops to a single element. Useful for focused before / after comparisons of one component.

## Scrolling an element into view before screenshot

The browser viewport is fixed at 1280×720 by default (or whatever was set by `resize_page`). If the element you need to screenshot is below the fold, scroll it in first:

```js
() => {
  const row = document.querySelector('.doc-row[data-line="13"]');
  row?.scrollIntoView({ block: "center", behavior: "instant" });
  return { scrolled: !!row };
}
```

Then take the screenshot.

## Reload after server-side change

If you edit a file on disk while the app is open (e.g. to create a diff for AC1), the in-memory document doesn't change. Options:

1. **Reload from disk via the app's UI** — if there's a "Reload" button, click it.
2. **Hard reload the page** — `mcp__chrome-devtools__navigate_page({ type: "reload", ignoreCache: true })`.
3. **File-watch trigger** — if the app has a file watcher, edit the file and wait. Less reliable.

Option 2 is the most robust; it works without depending on the app's internal reload mechanism.

## Window size for consistent screenshots

Set a known viewport before any screenshot:

```js
mcp__chrome-devtools__resize_page({ width: 1280, height: 720 })
```

This makes screenshots consistent across runs (independent of the user's actual window size). 1280×720 is a common report-quality size.

## Closing the menu after capture

After clicking a menu open, the menu may still be open and obscure subsequent screenshots. Close it via Escape:

```js
mcp__chrome-devtools__press_key({ key: "Escape" })
```

Or by clicking a non-menu region. Verify it closed with a follow-up snapshot before the next action.

## Avoiding browser-side alerts and modal dialogs

Do NOT trigger native `alert()` / `confirm()` / `prompt()` dialogs through clicks. These block ALL further MCP events until manually dismissed in the browser, which means the verification flow stops cold. If the AC requires confirming a destructive action that triggers a native confirm:

1. Stub the dialog before clicking: `window.confirm = () => true;`
2. Then perform the click that would have triggered it
3. Capture the post-confirm UI state

For `<dialog>` elements (HTML5 modal), they're MCP-friendly — they're DOM, not a browser-managed prompt — and can be driven normally.

## Opening the report for review (Phase 5)

```js
mcp__chrome-devtools__new_page({ url: "file:///abs/path/to/<artifacts-dir>/results.html" })
```

The `file://` URL works for self-contained HTML. If the report references any non-relative path or external resource, the `new_page` will succeed but the resource will fail to load — keep the artifacts dir flat and relative-pathed.
