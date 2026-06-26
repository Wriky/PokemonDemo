//
//  WelcomeView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            WelcomeTheme.background
                .ignoresSafeArea()

            WelcomeBackgroundMark()

            VStack(spacing: 0) {
                topBar

                Spacer(minLength: 26)

                VStack(spacing: 28) {
                    heroMark

                    VStack(spacing: 12) {
                        Text("Pokemon Search")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(WelcomeTheme.ink)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.82)

                        Text("Discover species, forms, and tiny details.")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(WelcomeTheme.inkMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }

                    featurePills
                }

                Spacer(minLength: 34)

                Button {
                    onContinue()
                } label: {
                    HStack(spacing: 10) {
                        Text("Start Exploring")
                            .font(.system(.headline, design: .rounded, weight: .bold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        WelcomeTheme.coral,
                                        WelcomeTheme.coralDeep
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(0.36), lineWidth: 1)
                    }
                    .shadow(color: WelcomeTheme.coral.opacity(0.24), radius: 18, y: 10)
                }
                .buttonStyle(WelcomePressButtonStyle())
                .accessibilityLabel("Start exploring")
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 9) {
                Circle()
                    .fill(WelcomeTheme.sky)
                    .frame(width: 12, height: 12)

                Circle()
                    .fill(WelcomeTheme.butter)
                    .frame(width: 9, height: 9)

                Circle()
                    .fill(WelcomeTheme.mint)
                    .frame(width: 9, height: 9)
            }
            .padding(10)
            .background(
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.76))
            )

            Spacer()

            Text("POKEMON")
                .font(.system(.caption2, design: .rounded, weight: .black))
                .tracking(1.8)
                .foregroundStyle(WelcomeTheme.inkMuted)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.76))
                )
        }
    }

    private var heroMark: some View {
        ZStack {
            Circle()
                .fill(WelcomeTheme.sky.opacity(0.13))
                .frame(width: 226, height: 226)
                .offset(y: 10)

            Circle()
                .fill(WelcomeTheme.butter.opacity(0.24))
                .frame(width: 148, height: 148)
                .offset(x: -74, y: -54)

            Circle()
                .fill(WelcomeTheme.mint.opacity(0.24))
                .frame(width: 116, height: 116)
                .offset(x: 78, y: 55)

            Sparkle()
                .fill(WelcomeTheme.butter)
                .frame(width: 22, height: 22)
                .offset(x: 92, y: -92)

            Sparkle()
                .fill(WelcomeTheme.sky)
                .frame(width: 15, height: 15)
                .offset(x: -101, y: 76)

            WelcomePokeball()
                .frame(width: 178, height: 178)
                .shadow(color: WelcomeTheme.coral.opacity(0.22), radius: 28, y: 16)
        }
        .frame(height: 242)
        .accessibilityHidden(true)
    }

    private var featurePills: some View {
        HStack(spacing: 10) {
            WelcomeInfoPill(icon: "sparkle.magnifyingglass", text: "Species")
            WelcomeInfoPill(icon: "circle.grid.2x2.fill", text: "Forms")
            WelcomeInfoPill(icon: "heart.fill", text: "Details")
        }
    }
}

private enum WelcomeTheme {
    static let background = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.075, blue: 0.085, alpha: 1)
                : UIColor(red: 0.98, green: 0.94, blue: 0.88, alpha: 1)
        }
    )
    static let ink = Color(uiColor: .label)
    static let inkMuted = Color(uiColor: .secondaryLabel)
    static let coral = Color(red: 1.0, green: 0.29, blue: 0.33)
    static let coralDeep = Color(red: 0.86, green: 0.13, blue: 0.22)
    static let sky = Color(red: 0.12, green: 0.58, blue: 0.80)
    static let butter = Color(red: 1.0, green: 0.79, blue: 0.28)
    static let mint = Color(red: 0.43, green: 0.78, blue: 0.58)
}

private struct WelcomeInfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(WelcomeTheme.coral)

            Text(text)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(WelcomeTheme.inkMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(
            Capsule(style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.86))
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(.white.opacity(0.66), lineWidth: 1)
        }
    }
}

private struct WelcomeBackgroundMark: View {
    var body: some View {
        VStack {
            Spacer()

            PokeballOutline()
                .stroke(WelcomeTheme.coral.opacity(0.055), lineWidth: 24)
                .frame(width: 360, height: 360)
                .offset(x: 112, y: 48)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct WelcomePokeball: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .secondarySystemGroupedBackground))

            VStack(spacing: 0) {
                WelcomeTheme.coral
                Color(uiColor: .systemBackground)
            }
            .clipShape(Circle())

            Circle()
                .stroke(.white.opacity(0.82), lineWidth: 5)

            Rectangle()
                .fill(WelcomeTheme.ink.opacity(0.13))
                .frame(height: 12)

            Circle()
                .fill(Color(uiColor: .systemBackground))
                .frame(width: 56, height: 56)
                .overlay {
                    Circle()
                        .stroke(WelcomeTheme.ink.opacity(0.13), lineWidth: 10)
                }
                .overlay {
                    Circle()
                        .fill(WelcomeTheme.sky.opacity(0.18))
                        .frame(width: 22, height: 22)
                }
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }
}

private struct PokeballOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addEllipse(in: CGRect(x: center.x - radius * 0.18, y: center.y - radius * 0.18, width: radius * 0.36, height: radius * 0.36))
        return path
    }
}

private struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.midY))
        return path
    }
}

private struct WelcomePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: configuration.isPressed)
    }
}
