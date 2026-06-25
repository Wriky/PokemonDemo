//
//  PokemonDetailView.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: PokemonDetailViewModel

    init(
        pokemonID: Int,
        placeholderName: String,
        repository: (any PokemonRepositoryProtocol)? = nil
    ) {
        if let repository {
            _viewModel = StateObject(
                wrappedValue: PokemonDetailViewModel(
                    pokemonID: pokemonID,
                    placeholderName: placeholderName,
                    repository: repository
                )
            )
        } else {
            _viewModel = StateObject(
                wrappedValue: PokemonDetailViewModel(
                    pokemonID: pokemonID,
                    placeholderName: placeholderName
                )
            )
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                loadingView
            } else if let errorMessage = viewModel.errorMessage, viewModel.detail == nil {
                errorView(message: errorMessage)
            } else if let detail = viewModel.detail {
                detailContent(detail)
            } else {
                errorView(message: "No Pokemon detail available.")
            }
        }
        // .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
    }

    private var loadingView: some View {
        ZStack {
            PokemonDetailTheme.pageBackground(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ProgressView()
                    .controlSize(.large)
                    .tint(PokemonDetailTheme.skyBlue)

                Text("SCANNING SPECIES DATA…")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(PokemonDetailTheme.inkMuted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading Pokemon details")
    }

    private func errorView(message: String) -> some View {
        ZStack {
            PokemonDetailTheme.pageBackground(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(PokemonDetailTheme.warning)

                Text("SCAN FAILED")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(PokemonDetailTheme.inkMuted)

                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(PokemonDetailTheme.inkMuted)

                Button {
                    Task { await viewModel.load() }
                } label: {
                    Text("Retry Scan")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(PokemonDetailTheme.pokeballRed)
                        )
                }
                .buttonStyle(PokedexPressButtonStyle())
            }
            .padding(32)
        }
    }

    private func detailContent(_ detail: PokemonDetail) -> some View {
        let accent = PokemonColorPalette.color(for: detail.colorName)

        return GeometryReader { proxy in
            ZStack {
                PokemonDetailTheme.pageBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroHeader(
                            detail,
                            accent: accent,
                            topInset: proxy.safeAreaInsets.top
                        )

                        VStack(spacing: 18) {
                            if !detail.typeNames.isEmpty {
                                infoCard(title: "TYPE SIGNATURE", icon: "bolt.fill", accent: accent) {
                                    FlowLayout(spacing: 10) {
                                        ForEach(detail.typeNames, id: \.self) { typeName in
                                            PokemonTypeChip(typeName: typeName)
                                        }
                                    }
                                }
                            }

                            if !detail.abilityNames.isEmpty {
                                infoCard(title: "ABILITIES", icon: "sparkles", accent: accent) {
                                    FlowLayout(spacing: 10) {
                                        ForEach(detail.abilityNames, id: \.self) { ability in
                                            abilityChip(ability, accent: accent)
                                        }
                                    }
                                }
                            }

                            infoCard(title: "PHYSICAL DATA", icon: "chart.bar.fill", accent: accent) {
                                HStack(spacing: 12) {
                                    statCard(
                                        title: "Height",
                                        value: formattedStat(detail.height, unit: "dm"),
                                        icon: "ruler.fill",
                                        accent: PokemonDetailTheme.skyBlue
                                    )

                                    statCard(
                                        title: "Weight",
                                        value: formattedStat(detail.weight, unit: "hg"),
                                        icon: "scalemass.fill",
                                        accent: PokemonDetailTheme.goldenYellow
                                    )

                                    statCard(
                                        title: "Capture",
                                        value: detail.captureRate.map(String.init) ?? "—",
                                        icon: "target",
                                        accent: PokemonDetailTheme.pokeballRed
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 36)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
    }

    private func heroHeader(_ detail: PokemonDetail, 
                            accent: Color,
                            topInset: CGFloat
            ) -> some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [
                        PokemonDetailTheme.skyBlue,
                        PokemonDetailTheme.skyBlueLight
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                DetailSparkleField()
                    .allowsHitTesting(false)

                PokeballWatermark()
                    .frame(width: 180, height: 180)
                    .foregroundStyle(.white.opacity(0.07))
                    .offset(x: 90, y: -20)
            }
            .frame(height: 280)
            .overlay(alignment: .bottom) {
                heroCard(detail, accent: accent)
                    .padding(.horizontal, 16)
                    .offset(y: topInset + 50)
            }
        }
        .padding(.bottom, topInset + 50)
    }

    private func heroCard(_ detail: PokemonDetail, accent: Color) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.22), accent.opacity(0.06)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 110
                        )
                    )
                    .frame(width: 200, height: 200)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.5), accent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 188, height: 188)

                PokemonArtworkView(pokemonID: detail.id, colorName: detail.colorName)
                    .frame(maxWidth: 170, maxHeight: 170)
                    .shadow(color: accent.opacity(0.35), radius: 16, y: 8)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text(detail.name.capitalized)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(PokemonDetailTheme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    idBadge(detail.id)

                    if let colorName = detail.colorName {
                        colorBadge(colorName, accent: accent)
                    }
                }
            }
            .padding(.bottom, 6)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(PokemonDetailTheme.cardBackground(for: colorScheme))
                .shadow(color: PokemonDetailTheme.shadow, radius: 20, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accent.opacity(0.14), lineWidth: 1.5)
        }
    }

    private func idBadge(_ id: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "number")
                .font(.system(size: 10, weight: .black))
            Text(String(format: "%04d", id))
                .font(.system(.caption, design: .monospaced, weight: .black))
        }
        .foregroundStyle(PokemonDetailTheme.pokeballRed)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(PokemonDetailTheme.pokeballRed.opacity(0.12))
        )
    }

    private func colorBadge(_ colorName: String, accent: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
            Text(colorName.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .tracking(0.6)
        }
        .foregroundStyle(PokemonDetailTheme.inkMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(accent.opacity(0.12))
        )
    }

    private func infoCard<Content: View>(
        title: String,
        icon: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accent)

                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(0.9)
                    .foregroundStyle(PokemonDetailTheme.inkMuted)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PokemonDetailTheme.cardBackground(for: colorScheme))
                .shadow(color: PokemonDetailTheme.shadow, radius: 14, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.1), lineWidth: 1)
        }
    }

    private func abilityChip(_ ability: String, accent: Color) -> some View {
        Text(ability.replacingOccurrences(of: "-", with: " ").capitalized)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(PokemonDetailTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(accent.opacity(0.1))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(accent.opacity(0.22), lineWidth: 1)
            }
    }

    private func statCard(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accent)
            }

            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .black))
                .foregroundStyle(PokemonDetailTheme.ink)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text(title.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(PokemonDetailTheme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent.opacity(0.06))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    private func formattedStat(_ value: Int?, unit: String) -> String {
        guard let value else { return "—" }
        return "\(value) \(unit)"
    }
}

// MARK: - Theme

private enum PokemonDetailTheme {
    static let pokeballRed = Color(red: 1.0, green: 0.28, blue: 0.30)
    static let skyBlue = Color(red: 0.22, green: 0.68, blue: 0.94)
    static let skyBlueLight = Color(red: 0.45, green: 0.82, blue: 0.98)
    static let goldenYellow = Color(red: 1.0, green: 0.78, blue: 0.18)
    static let warning = Color(red: 0.92, green: 0.53, blue: 0.08)
    static let shadow = Color.black.opacity(0.08)

    static let ink = Color(uiColor: .label)
    static let inkMuted = Color(uiColor: .secondaryLabel)

    static func pageBackground(for colorScheme: ColorScheme) -> some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.10, blue: 0.16),
                        Color(red: 0.04, green: 0.07, blue: 0.11)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.88, green: 0.96, blue: 1.0),
                        Color(red: 0.94, green: 0.97, blue: 0.99)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.15, blue: 0.20)
            : Color(uiColor: .systemBackground)
    }
}

// MARK: - Decorative Views

private struct DetailSparkleField: View {
    private struct Sparkle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    private let sparkles: [Sparkle] = [
        Sparkle(x: 0.12, y: 0.18, size: 10, opacity: 0.7),
        Sparkle(x: 0.78, y: 0.12, size: 8, opacity: 0.55),
        Sparkle(x: 0.55, y: 0.28, size: 6, opacity: 0.45),
        Sparkle(x: 0.30, y: 0.08, size: 7, opacity: 0.5),
        Sparkle(x: 0.88, y: 0.35, size: 9, opacity: 0.6),
        Sparkle(x: 0.08, y: 0.42, size: 6, opacity: 0.4)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size, weight: .bold))
                    .foregroundStyle(.white.opacity(sparkle.opacity))
                    .position(
                        x: geo.size.width * sparkle.x,
                        y: geo.size.height * sparkle.y
                    )
            }
        }
    }
}

private struct PokeballWatermark: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 18)

            Rectangle()
                .frame(height: 18)

            Circle()
                .fill(PokemonDetailTheme.pokeballRed.opacity(0.3))
                .frame(width: 60, height: 60)

            Circle()
                .stroke(lineWidth: 14)
                .frame(width: 60, height: 60)
        }
        .accessibilityHidden(true)
    }
}

private struct PokedexPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}


