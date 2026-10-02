//
//  AnimatedGradientBackground.swift
//  Jentacular
//
//  Animated gradient background component with multiple color phases
//  Original implementation using phase-based animation with smooth transitions
//

import SwiftUI

struct AnimatedGradientBackground: View {
    // MARK: - Configuration
    var colors: [Color]
    var duration: Double = 8.0
    var opacity: Double = 0.6

    // MARK: - State
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(opacity)
            .ignoresSafeArea()

            // Animated overlay blobs
            animatedBlob(
                color: colors.first ?? .accentBlue,
                size: 300,
                position: animate ? CGPoint(x: 0.2, y: 0.2) : CGPoint(x: 0.8, y: 0.3),
                delay: 0
            )

            animatedBlob(
                color: colors.count > 1 ? colors[1] : .accentCyan,
                size: 250,
                position: animate ? CGPoint(x: 0.8, y: 0.7) : CGPoint(x: 0.2, y: 0.6),
                delay: duration / 3
            )

            animatedBlob(
                color: colors.count > 2 ? colors[2] : .accentPurple,
                size: 200,
                position: animate ? CGPoint(x: 0.5, y: 0.9) : CGPoint(x: 0.5, y: 0.1),
                delay: duration * 2 / 3
            )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }

    // MARK: - Animated Blob
    private func animatedBlob(color: Color, size: CGFloat, position: CGPoint, delay: Double) -> some View {
        Circle()
            .fill(color.opacity(0.3))
            .frame(width: size, height: size)
            .blur(radius: 60)
            .position(x: position.x * UIScreen.main.bounds.width,
                      y: position.y * UIScreen.main.bounds.height)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: animate
            )
    }
}

// MARK: - Preset Gradients
extension AnimatedGradientBackground {
    static let jentacularDefault = AnimatedGradientBackground(
        colors: [
            Color(red: 0.05, green: 0.07, blue: 0.15),
            Color(red: 0.08, green: 0.12, blue: 0.25),
            Color(red: 0.05, green: 0.15, blue: 0.2)
        ],
        duration: 10.0,
        opacity: 1.0
    )

    static let connected = AnimatedGradientBackground(
        colors: [
            Color(red: 0.02, green: 0.15, blue: 0.08),
            Color(red: 0.05, green: 0.2, blue: 0.12),
            Color(red: 0.02, green: 0.12, blue: 0.15)
        ],
        duration: 12.0,
        opacity: 1.0
    )

    static let connecting = AnimatedGradientBackground(
        colors: [
            Color(red: 0.15, green: 0.1, blue: 0.02),
            Color(red: 0.2, green: 0.15, blue: 0.05),
            Color(red: 0.12, green: 0.1, blue: 0.02)
        ],
        duration: 6.0,
        opacity: 1.0
    )
}

// MARK: - Pulse Animation View
struct PulseView: View {
    var color: Color = .accentBlue
    var size: CGFloat = 100
    var pulseCount: Int = 3
    var duration: Double = 2.0

    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<pulseCount, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: size, height: size)
                    .scaleEffect(animate ? 1.5 : 1.0)
                    .opacity(animate ? 0 : 0.6)
                    .animation(
                        Animation.easeOut(duration: duration)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * (duration / Double(pulseCount))),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Glow Effect Modifier
struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 20
    var intensity: Double = 0.6

    func body(content: Content) -> some View {
        content
            .background(
                content
                    .blur(radius: radius)
                    .opacity(intensity)
                    .foregroundColor(color)
            )
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 20, intensity: Double = 0.6) -> some View {
        modifier(GlowModifier(color: color, radius: radius, intensity: intensity))
    }
}

// MARK: - Shimmer Effect
struct ShimmerView: View {
    var width: CGFloat = 200
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8

    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.cardBackgroundHighlighted)
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.1), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 0.3)
                    .offset(x: animate ? width : -width)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
            )
            .onAppear { animate = true }
            .clipped()
    }
}

// MARK: - Floating Animation
struct FloatingModifier: ViewModifier {
    var amplitude: CGFloat = 10
    var duration: Double = 3.0

    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = -amplitude
                }
            }
    }
}

extension View {
    func floating(amplitude: CGFloat = 10, duration: Double = 3.0) -> some View {
        modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }
}

// MARK: - Rotating Loader
struct RotatingLoader: View {
    var color: Color = .accentCyan
    var size: CGFloat = 40
    var lineWidth: CGFloat = 4

    @State private var rotate = false

    var body: some View {
        Circle()
            .trim(from: 0.2, to: 1)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.3)]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotate ? 360 : 0))
            .animation(
                Animation.linear(duration: 1.0)
                    .repeatForever(autoreverses: false),
                value: rotate
            )
            .onAppear { rotate = true }
    }
}
