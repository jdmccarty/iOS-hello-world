# Flag Status iOS App

This is an experimental project to use cursor to produce a "hello world" app that denotes whether a flag should be flown at half mast. The project is an iOS application built with SwiftUI that acts as a wrapper around a web-based JavaScript widget (`us-half-staff-flags.js`) designed to display the current US flag status (full or half staff).

## Development Summary

The development process involved several key steps and iterations:

1.  **Initial Setup:**
    *   Created a basic SwiftUI iOS project structure.
    *   Established a foundation using `ContentView.swift`.

2.  **WebView Integration:**
    *   Integrated a `WKWebView` component using `UIViewRepresentable` (`WebView.swift`) to host web content within the native app.

3.  **Widget Loading & Challenges:**
    *   Initially attempted to load the widget directly using `loadHTMLString` and later `loadFileURL` pointing to a local `widget.html`.
    *   Encountered issues likely related to the widget's internal use of `document.write` after the initial page load, which interfered with `WKWebView`'s rendering.
    *   Troubleshooting involved checking JavaScript console logs (`WKScriptMessageHandler`) and inspecting element classes via JavaScript injection.

4.  **Revised Widget Integration Strategy:**
    *   Adopted a new approach where `widget.html` acts only as a minimal shell, loading necessary resources (`moment.js`, original CSS).
    *   Injected custom JavaScript via `webView(_:didFinish:)` in the `WKNavigationDelegate`.
    *   This injected JavaScript now dynamically:
        *   Checks for `moment.js`.
        *   Determines the flag state (`full` or `half`, currently based on a hardcoded empty `dataevent`).
        *   Creates the primary widget container `div` using `document.createElement`.
        *   Assigns the correct classes (`halfstaffwidget_container`, `full` or `half`).
        *   Populates the `innerHTML` with the current time, date, and a dynamic status message ("Flag is flown full staff" / "Flag is flown half staff").
        *   Appends the created element to the `document.body`.

5.  **Custom Styling:**
    *   After the widget element is created by the injected JavaScript, a second step injects custom CSS rules.
    *   This CSS overrides the original widget styles to:
        *   Use custom local background images (`full-flag.png`, `half-flag.png`) for the `full`/`half` states, requiring the use of absolute `file://` URLs passed from Swift to JavaScript.
        *   Control background display (`background-size: contain`, `background-color`).
        *   Adjust layout, padding, and container sizing for better display within the app view.
        *   Restyle text elements (time, date, status message) for readability, using system fonts and absolute positioning.

6.  **Link Handling:**
    *   Implemented `WKNavigationDelegate` (`decidePolicyFor navigationAction`) to intercept standard link clicks.
    *   (Future/Implied: Need `WKUIDelegate` (`createWebViewWith configuration`) to handle `window.open` calls triggered by the widget's click handler).

7.  **Iteration & Debugging:**
    *   Refined layout iteratively using SwiftUI padding and CSS adjustments (`height`, `width`, `padding`, `top`, etc.).
    *   Used extensive `console.log` statements within the injected JavaScript, forwarded to the Xcode console, to debug execution flow and variable states.

## Current Status

The app currently displays the flag widget with custom background images, text styling, and a dynamic status message based on a hardcoded state. It fills the main view area below the safe area insets.

## Future Considerations

*   Implement `WKUIDelegate` to fully restore the external link functionality on tap.
*   Fetch the *actual* `dataevent` value (e.g., from a network request or configuration) instead of hardcoding it, to display the real-time flag status and correct message/image.
*   Refine UI/layout for different device sizes and orientations.
*   Add error handling for network requests or script failures.
*   Prepare for TestFlight distribution.
*   Add state selector to be accurate with state specific directives from the respective Governors
