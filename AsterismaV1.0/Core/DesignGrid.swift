//  DesignGrid.swift
//  AsterismaV1.0
//
//  P7 UI REVIEW EXECUTION (High #2/#4, Medium #4):
//  One shared source of layout truth so every surface — sidebar, cards,
//  HUD, banners, decorative glow — derives from the SAME geometry instead
//  of independent magic numbers. Per the review: "Even subtle
//  inconsistencies become highly visible in a minimalist interface."

import CoreGraphics

enum DesignGrid {
    // Sidebar column (NavigationSplitView)
    static let sidebarMinWidth: CGFloat = 200
    static let sidebarIdealWidth: CGFloat = 224

    // Cards / floating surfaces (HUD, banners, toasts, report card)
    static let cardCornerRadius: CGFloat = 12
    static let cardPaddingH: CGFloat = 14
    static let cardPaddingV: CGFloat = 10
    static let hudLeadingInset: CGFloat = 20
    static let hudTopInset: CGFloat = 12
    static let toastHorizontalInset: CGFloat = 20
    static let bannerBottomInset: CGFloat = 12
    static let bannerHorizontalInset: CGFloat = 20

    // Ambient glow derivation (UI REVIEW §3/§4, option B — "diffuse enough
    // that its boundaries aren't perceptible"): the glow is anchored to the
    // WINDOW's own geometry — centered, spanning past the diagonal — rather
    // than positioned independently. These fractions are shares of the
    // window's min/max dimension measured in EnvironmentBackgroundView.
    static let glowStartFraction: CGFloat = 0.55   // begins far from center
    static let glowEndFraction: CGFloat = 1.00     // fades past the corners
    static let glowPeakOpacity: Double = 0.16      // whisper, not a surface
}
