//
//  PokemonDetailView.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonDetailView: View {
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
        .navigationTitle(viewModel.detail?.name.capitalized ?? viewModel.placeholderName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading Pokemon details...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading Pokemon details")
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Retry") {
                Task {
                    await viewModel.load()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func detailContent(_ detail: PokemonDetail) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection(detail)

                if !detail.typeNames.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(detail.typeNames, id: \.self) { typeName in
                            PokemonTypeChip(typeName: typeName)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !detail.abilityNames.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Abilities")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(detail.abilityNames, id: \.self) { ability in
                                Text(ability.capitalized)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(uiColor: .secondarySystemBackground))
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                statsRow(detail)
            }
            .padding()
        }
    }

    private func heroSection(_ detail: PokemonDetail) -> some View {
        VStack(spacing: 12) {
            PokemonArtworkView(pokemonID: detail.id, colorName: detail.colorName)

            Text(detail.name.capitalized)
                .font(.largeTitle.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text("#\(detail.id)")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PokemonColorPalette.background(for: detail.colorName, opacity: 0.42))
        )
    }

    private func statsRow(_ detail: PokemonDetail) -> some View {
        HStack(spacing: 12) {
            statCard(title: "Height", value: formattedStat(detail.height, unit: "dm"))
            statCard(title: "Weight", value: formattedStat(detail.weight, unit: "hg"))
            statCard(title: "Capture", value: detail.captureRate.map(String.init) ?? "—")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    private func formattedStat(_ value: Int?, unit: String) -> String {
        guard let value else { return "—" }
        return "\(value) \(unit)"
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
