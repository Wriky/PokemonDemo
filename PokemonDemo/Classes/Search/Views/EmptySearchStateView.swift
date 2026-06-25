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
                                Color(red: 0.90, green: 0.12, blue: 0.17).opacity(0.15),
                                Color(red: 0.08, green: 0.57, blue: 0.78).opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "scope")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(red: 0.90, green: 0.12, blue: 0.17))
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
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [7, 7]))
                .foregroundStyle(Color.secondary.opacity(0.22))
        }
        .accessibilityElement(children: .combine)
    }
}
