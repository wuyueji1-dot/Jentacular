//
//  AppBackgroundView.swift
//  Jentacular
//
//  Reusable background view with themed image and overlay for readability
//

import SwiftUI

struct AppBackgroundView: View {
    let imageName: String

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // Semi-transparent overlay for text readability
            Color.appBackground.opacity(0.75)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Background Theme Names
enum AppBackgroundTheme {
    static let home = "bg_gradient_blue"
    static let shield = "bg_gradient_purple"
    static let servers = "texture_dark_1"
    static let analysis = "texture_dark_2"
    static let settings = "bg_gradient_dark"
}
