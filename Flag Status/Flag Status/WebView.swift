//
//  WebView.swift
//  Flag Status
//
//  Created by Justin McCarty on 3/28/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    // --- Corrected Coordinator Definition ---
    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate { // <-- Ensure BOTH protocols are listed

        // Message Handler function (for console logs)
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "logHandler", let messageBody = message.body as? String {
                print("JavaScript console: \(messageBody)")
            }
        }

        // Navigation Delegate function (for link handling)
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    print("User tapped link to: \(url)")
                    // Ensure we are on the main thread for UI updates like opening URLs
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url)
                    }
                    decisionHandler(.cancel) // Cancel navigation in WebView
                    return
                }
            }
            decisionHandler(.allow) // Allow other navigation types
        }

        // Navigation Delegate function (for CSS injection after load)
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print(">>> WebView did finish loading widget.html shell.")

            // --- Get Absolute File URLs for Images ---
            guard let fullFlagURL = Bundle.main.url(forResource: "full-flag", withExtension: "png"), // Correct for full-flag.png
                  let halfFlagURL = Bundle.main.url(forResource: "half-flag", withExtension: "png") else { // Correct for half-flag.png
                print(">>> Error: Could not find flag image URLs in bundle.")
                return // Don't proceed if images aren't found
            }
            let fullFlagPath = fullFlagURL.absoluteString
            let halfFlagPath = halfFlagURL.absoluteString
            print(">>> Full flag path: \(fullFlagPath)")
            print(">>> Half flag path: \(halfFlagPath)")
            // --- End of Get Absolute File URLs ---


            // --- JavaScript to Create/Populate Widget AND Inject CSS (with more logging/error handling) ---
            let jsCreatePopulateInject = """
            // Define image paths from Swift
            const fullFlagImagePath = "\(fullFlagPath)";
            const halfFlagImagePath = "\(halfFlagPath)";
            var dataevent = ''; // Define and initialize dataevent

            if (typeof window.goToHalfstaff === 'undefined') {
                 window.goToHalfstaff = function () {
                     window.open("https://halfstaff.org/widget/", "_blank");
                 };
            }

            // --- Function to Inject Override CSS (Defined first) ---
            function injectOverrideCss() {
                console.log('Attempting to inject override CSS with absolute image paths...');
                // Use the image path variables defined above
                const css = `
                    /* REMOVE @import for Lato */
                    /* @import url('...'); */

                    html, body {
                        width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden;
                    }
                    body {
                         display: block; background-color: transparent !important;
                    }
                    /* Base style for the widget container */
                    .halfstaffwidget_container {
                        border: 1px solid #DDD !important; /* Lighter border or remove */
                        border-radius: 8px !important; /* Keep rounded corners */
                        box-shadow: 0 1px 3px rgba(0,0,0,0.1) !important; /* Lighter shadow or remove */
                        width: 100% !important; /* Fill padded width */
                        height: 100% !important; /* Fill padded height */
                        margin: 0 !important;
                        box-sizing: border-box; cursor: pointer;
                        /* --- Use contain, center, and add background --- */
                        background-size: contain !important; /* Fit whole image */
                        background-position: center center !important; /* Center the image */
                        background-repeat: no-repeat !important;
                        background-color: #FFFFFF !important; /* WHITE background for empty space */
                        /* --- End background --- */
                        position: relative; /* Keep for text positioning */
                        overflow: hidden; /* Keep */
                        padding: 0 !important;
                    }
                    /* State-specific backgrounds (image only) */
                    .halfstaffwidget_container.full { background-image: url('${fullFlagImagePath}') !important; }
                    .halfstaffwidget_container.half { background-image: url('${halfFlagImagePath}') !important; }

                    /* Base Text Styles (Use system fonts) */
                    .halfstaffwidget_container * {
                         /* Rely on system fonts */
                         font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif !important;
                         color: #000000 !important;
                         background-color: transparent !important; /* Overridden below */
                         border: none !important; text-shadow: none !important;
                         z-index: 10;
                    }

                    /* Position Text Elements */
                    .halfstaffwidget_time, .halfstaffwidget_date, .halfstaffwidget_status_message, .halfstaffwidget_message {
                         position: absolute; left: 10px; right: 10px;
                         background-color: rgba(240, 240, 240, 0.8) !important;
                         padding: 3px 6px; border-radius: 4px;
                         text-align: left;
                    }
                    .halfstaffwidget_time {
                        top: 10px;
                        font-size: 1.5em !important;
                        font-weight: normal !important;
                    }
                    .halfstaffwidget_date {
                         top: 40px;
                         font-size: 1.0em !important;
                         font-weight: bold !important; /* Date is 1.0em, bold */
                    }
                    /* --- Style the status message LIKE the date --- */
                    .halfstaffwidget_status_message {
                         top: 65px; /* Keep position below date for now */
                         font-size: 1.0em !important; /* Match date size */
                         font-weight: bold !important; /* Match date weight */
                    }
                    /* Adjust original message position */
                    .halfstaffwidget_message {
                         top: 90px; /* Keep position below status message */
                         font-size: 0.8em !important;
                         font-weight: normal !important;
                         display: ${dataevent ? 'block' : 'none'} !important;
                    }

                    /* Hide original link div */
                    .halfstaffwidget_linkdiv { display: none !important; }
                `;
                var style = document.createElement('style');
                style.innerHTML = css;
                style.id = 'injectedAppStyle';
                var oldStyle = document.getElementById('injectedAppStyle');
                if (oldStyle) { oldStyle.remove(); }
                document.head.appendChild(style);
                console.log('Injected override CSS with absolute paths.');
            } // End of injectOverrideCss function

            // --- Function to Create and Populate Widget (Add Status Message) ---
            function createAndPopulateWidget() {
                console.log('[JS DEBUG] Inside createAndPopulateWidget');
                try {
                    if (typeof moment === 'undefined') {
                        console.log('[JS DEBUG] Moment.js not loaded yet, retrying...');
                        setTimeout(createAndPopulateWidget, 200);
                        return;
                    }
                    console.log('[JS DEBUG] Moment.js is loaded.');

                    var existingContainer = document.querySelector('.halfstaffwidget_container');
                    if (existingContainer) {
                        console.log('[JS DEBUG] Widget container already exists. Skipping creation.');
                        injectOverrideCss(); // Still inject CSS
                        return;
                    }
                    console.log('[JS DEBUG] No existing container found. Proceeding with creation.');

                    // Determine state and status message
                    var stateClass = dataevent ? 'half' : 'full';
                    console.log('[JS DEBUG] Determined stateClass: ' + stateClass);
                    var statusMessage = ""; // Initialize message variable
                    if (stateClass === 'full') {
                        statusMessage = "Flag is flown full staff";
                    } else { // stateClass === 'half'
                        statusMessage = "Flag is flown half staff";
                    }
                    console.log('[JS DEBUG] Determined statusMessage: ' + statusMessage);

                    console.log('[JS DEBUG] Creating container div...');
                    var container = document.createElement('div');
                    console.log('[JS DEBUG] Setting className...');
                    container.className = 'halfstaffwidget_container ' + stateClass;
                    console.log('[JS DEBUG] Setting onclick...');
                    container.onclick = window.goToHalfstaff;

                    console.log('[JS DEBUG] Preparing innerHTML...');
                    var dt = moment().format("MMM. D, YYYY");
                    var tm = moment().format("hh:mm a");
                    container.innerHTML = "<div class='halfstaffwidget_time'>" + tm + "</div>"
                                          + "<div class='halfstaffwidget_date'>" + dt + "</div>"
                                          + "<div class='halfstaffwidget_status_message'>" + statusMessage + "</div>"
                                          + "<div class='halfstaffwidget_message'>" + dataevent + "</div>"
                                          + "<div class='halfstaffwidget_linkdiv'></div>";
                    console.log('[JS DEBUG] InnerHTML set.');

                    console.log('[JS DEBUG] Appending container to body...');
                    document.body.appendChild(container);
                    console.log('[JS DEBUG] Container appended. Final class: ' + container.className);

                    // Inject CSS AFTER success
                    injectOverrideCss();

                } catch (e) {
                     console.error('[JS ERROR] Error in createAndPopulateWidget: ' + e.message + ' Stack: ' + e.stack);
                }
            } // End of createAndPopulateWidget function

            // --- Start the process (remains the same) ---
            setTimeout(createAndPopulateWidget, 200);
            """

            print(">>> Evaluating script (v4) to create/populate widget and inject CSS...")
            webView.evaluateJavaScript(jsCreatePopulateInject) { result, error in
                if let error = error {
                    print(">>> Error evaluating create/populate/inject script: \(error)")
                } else {
                    print(">>> Successfully evaluated create/populate/inject script.")
                }
            }
        }

         // Optional: Add error handling for navigation failures
         func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
             print(">>> WebView navigation failed: \(error.localizedDescription)")
         }

         func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
              print(">>> WebView provisional navigation failed: \(error.localizedDescription)")
         }
    }
    // --- End of Corrected Coordinator Definition ---


    // --- makeCoordinator function (remains the same) ---
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    // --- End of makeCoordinator function ---


    // --- Corrected makeUIView function ---
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences

        // Setup script message handler (as before)
        let scriptSource = """
            window.originalConsoleLog = console.log;
            console.log = function(message) {
                // Try converting non-string messages to string
                let msgStr = typeof message === 'string' ? message : JSON.stringify(message);
                window.webkit.messageHandlers.logHandler.postMessage(msgStr);
                window.originalConsoleLog.apply(console, arguments);
            };
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        userContentController.add(context.coordinator, name: "logHandler")
        configuration.userContentController = userContentController

        // Create the WKWebView with the configuration
        let webView = WKWebView(frame: .zero, configuration: configuration)

        // --- CRITICAL: Set the navigationDelegate ---
        webView.navigationDelegate = context.coordinator
        // --- End of critical line ---

        // Load the local HTML file (as before)
        guard let url = Bundle.main.url(forResource: "widget", withExtension: "html") else {
            print("Error: widget.html not found in bundle.")
            webView.loadHTMLString("<h1>Error: HTML file not found</h1>", baseURL: nil)
            return webView
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())

        return webView
    }
    // --- End of Corrected makeUIView function ---


    // --- updateUIView function (remains the same) ---
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    // --- End of updateUIView function ---
}

