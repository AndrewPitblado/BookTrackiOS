//
//  SVGImageView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-16.
//

import SwiftUI

/// Loads an image from a remote URL and renders it natively.
/// Falls back to a system image on failure.
struct RemoteImageView: View {
    let url: URL?
    var fallbackSystemName: String = "trophy.fill"

    @State private var uiImage: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if failed {
                Image(systemName: fallbackSystemName)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url else {
            failed = true
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                uiImage = image
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
    }
}
