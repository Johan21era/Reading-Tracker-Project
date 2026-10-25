//  WindowChromeConfigurator.swift
//  AsterismaV1.0
//
//  Owner-test F4 / fullscreen design directive:
//  The starfield should read as one continuous surface from the window's top
//  edge, while the native toolbar, traffic lights, and green zoom button must
//  remain fully functional. SwiftUI's `.hiddenTitleBar` removed the toolbar in
//  windowed mode, so we keep the standard toolbar and make the titlebar itself
//  transparent/full-size instead.

import AppKit
import SwiftUI

struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }

            // Content paints all the way to the top; the starfield background
            // already ignores the safe area.
            window.styleMask.insert(.fullSizeContentView)
            window.styleMask.insert(.resizable)

            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.titlebarSeparatorStyle = .none
            window.backgroundColor = .clear
            window.isOpaque = false

            // Keep the native toolbar and its controls, but remove the
            // baseline separator that otherwise draws a horizontal rule.
            window.toolbarStyle = .unifiedCompact
            window.toolbar?.showsBaselineSeparator = false
            window.toolbar?.isVisible = true

            window.minSize = NSSize(width: 1000, height: 680)

            // No control should look pre-focused at launch. Clear the
            // automatic first-responder assignment after the window settles;
            // keyboard focus still works normally once the user starts.
            window.initialFirstResponder = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                window.makeFirstResponder(nil)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
