//
//  CircularProgressView.swift
//  Jentacular
//
//  Animated circular progress indicator for security score display
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let trackColor: Color
    let progressColor: Color
    let animated: Bool

    @State private var animatedProgress: Double = 0

    init(progress: Double,
         lineWidth: CGFloat = 15,
         trackColor: Color = Color.dividerColor,
         progressColor: Color = .accentGold,
         animated: Bool = true) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.progressColor = progressColor
        self.animated = animated
    }

    var body: some View {
        ZStack {
            // Track circle
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: animated ? animatedProgress : progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [progressColor, progressColor.opacity(0.7)]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { newValue in
            if animated {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Score Display
struct ScoreDisplayView: View {
    let score: Int
    let level: String
    let progressColor: Color

    var body: some View {
        ZStack {
            CircularProgressView(
                progress: Double(score) / 100.0,
                lineWidth: 18,
                progressColor: progressColor
            )

            VStack(spacing: 8) {
                Text("\(score)")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.primaryText)

                Text("/ 100")
                    .font(.system(size: 20))
                    .foregroundColor(.secondaryText)

                Text(level)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(progressColor)
            }
        }
        .frame(width: 220, height: 220)
    }
}
