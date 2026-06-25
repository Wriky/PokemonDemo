//
//  PokemonTypeChip.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonTypeChip: View {
    let typeName: String

    var body: some View {
        Text(typeName.capitalized)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(chipColor.opacity(0.35))
            )
            .accessibilityLabel("\(typeName.capitalized) type")
    }

    private var chipColor: Color {
        switch typeName.lowercased() {
        case "fire": return .orange
        case "water": return .blue
        case "grass", "bug": return .green
        case "electric": return .yellow
        case "psychic", "poison", "ghost": return .purple
        case "fighting": return .brown
        case "ground", "rock": return .gray
        case "flying": return .cyan
        case "ice": return .mint
        case "dragon": return .indigo
        case "dark": return .black
        case "steel", "normal": return .secondary
        case "fairy": return .pink
        default: return .secondary
        }
    }
}

enum PokemonColorPalette {
    static func color(for colorName: String?) -> Color {
        guard let colorName else { return Color(uiColor: .secondarySystemBackground) }

        switch colorName.lowercased() {
        case "black": return .black
        case "blue": return .blue
        case "brown": return .brown
        case "gray": return .gray
        case "green": return .green
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "white": return Color(uiColor: .systemBackground)
        case "yellow": return .yellow
        default: return Color(uiColor: .secondarySystemBackground)
        }
    }

    static func background(for colorName: String?, opacity: Double = 0.4) -> Color {
        color(for: colorName).opacity(opacity)
    }
}
