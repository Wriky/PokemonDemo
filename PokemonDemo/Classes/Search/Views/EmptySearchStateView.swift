//
//  EmptySearchStateView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct EmptySearchStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.36, blue: 0.38).opacity(0.14),
                                Color(red: 0.28, green: 0.67, blue: 0.88).opacity(0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "scope")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.36, blue: 0.38))
            }
            .frame(width: 78, height: 78)

            VStack(spacing: 7) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .black))

                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 38)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.92))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [7, 7]))
                .foregroundStyle(Color(red: 1.0, green: 0.36, blue: 0.38).opacity(0.16))
        }
        .shadow(color: .black.opacity(0.05), radius: 14, y: 8)
        .accessibilityElement(children: .combine)
    }
}
