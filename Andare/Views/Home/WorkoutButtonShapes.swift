//
//  WorkoutButtonShapes.swift
//  Andare
//
//  Custom shapes for each workout type's start button:
//  - Cycling: bun / half-dome — flat bottom edge, wide rounded top
//  - Running: concave sides, straight top/bottom
//  - Walking: convex corner bulges with gently pinched edges
//

import SwiftUI

// MARK: - Cycling Shape
// Bun / half-dome shape: flat bottom edge, wide rounded top, soft corners.

struct CyclingButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }
        var path = Path()

        let w = rect.width
        let h = rect.height

        // Shrink and center the shape within the rect
        let shapeW = w * 1.05
        let shapeH = h * 0.88
        let left = (w - shapeW) / 2
        let right = left + shapeW
        let top = (h - shapeH) / 2
        let bottom = top + shapeH

        let cornerR = min(shapeW, shapeH) * 0.10

        path.move(to: CGPoint(x: left + cornerR, y: bottom))

        // Bottom edge — flat
        path.addLine(to: CGPoint(x: right - cornerR, y: bottom))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: right, y: bottom - cornerR),
            control: CGPoint(x: right, y: bottom)
        )

        // Right side + top dome
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: top),
            control1: CGPoint(x: right, y: top + shapeH * 0.25),
            control2: CGPoint(x: left + shapeW * 0.85, y: top)
        )

        path.addCurve(
            to: CGPoint(x: left, y: bottom - cornerR),
            control1: CGPoint(x: left + shapeW * 0.15, y: top),
            control2: CGPoint(x: left, y: top + shapeH * 0.25)
        )

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: left + cornerR, y: bottom),
            control: CGPoint(x: left, y: bottom)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Running Shape (Concave sides, straight top/bottom)

struct RunningButtonShape: Shape {
    var concaveDepth: CGFloat = 0.18

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }
        var path = Path()

        let w = rect.width
        let h = rect.height
        let r: CGFloat = min(w, h) * 0.08
        let indent = w * concaveDepth

        path.move(to: CGPoint(x: r, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: w - r, y: 0))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: w, y: r),
            control: CGPoint(x: w, y: 0)
        )

        // Right edge — concave inward
        path.addQuadCurve(
            to: CGPoint(x: w, y: h - r),
            control: CGPoint(x: w - indent, y: h * 0.5)
        )

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: w - r, y: h),
            control: CGPoint(x: w, y: h)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: r, y: h))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h - r),
            control: CGPoint(x: 0, y: h)
        )

        // Left edge — concave inward
        path.addQuadCurve(
            to: CGPoint(x: 0, y: r),
            control: CGPoint(x: indent, y: h * 0.5)
        )

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: r, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Walking Shape (Convex corner bulges)
// Four quarter-circle arcs at corners with gently pinched edges between them.

struct WalkingButtonShape: Shape {
    var bulgeFactor: CGFloat = 0.15

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }
        var path = Path()

        let w = rect.width
        let h = rect.height
        let r = min(w, h) * 0.30
        let pinch = min(w, h) * bulgeFactor

        // Start where top-left arc meets the top edge
        path.move(to: CGPoint(x: r, y: 0))

        // Top edge — curves inward
        path.addQuadCurve(
            to: CGPoint(x: w - r, y: 0),
            control: CGPoint(x: w * 0.5, y: pinch)
        )

        // Top-right corner arc
        path.addArc(
            center: CGPoint(x: w - r, y: r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge — curves inward
        path.addQuadCurve(
            to: CGPoint(x: w, y: h - r),
            control: CGPoint(x: w - pinch, y: h * 0.5)
        )

        // Bottom-right corner arc
        path.addArc(
            center: CGPoint(x: w - r, y: h - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge — curves inward
        path.addQuadCurve(
            to: CGPoint(x: r, y: h),
            control: CGPoint(x: w * 0.5, y: h - pinch)
        )

        // Bottom-left corner arc
        path.addArc(
            center: CGPoint(x: r, y: h - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge — curves inward
        path.addQuadCurve(
            to: CGPoint(x: 0, y: r),
            control: CGPoint(x: pinch, y: h * 0.5)
        )

        // Top-left corner arc
        path.addArc(
            center: CGPoint(x: r, y: r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}
