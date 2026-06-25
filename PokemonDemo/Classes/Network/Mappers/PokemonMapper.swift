import Foundation

nonisolated enum PokemonMappingError: Error, Equatable, Sendable {
    case invalidIdentifier
    case invalidName
}

nonisolated enum PokemonMapper {
    static func mapSpecies(_ dto: PokemonSpeciesDTO) throws -> PokemonSpecies {
        PokemonSpecies(
            id: try validIdentifier(dto.id),
            name: try validName(dto.name),
            captureRate: dto.captureRate,
            color: try dto.color.map(mapColor),
            pokemons: try dto.pokemons.map(mapPokemon)
        )
    }

    static func mapDetail(_ dto: PokemonDetailDTO) throws -> PokemonDetail {
        PokemonDetail(
            id: try validIdentifier(dto.id),
            name: try validName(dto.name),
            abilityNames: normalizedNames(dto.abilityNames),
            typeNames: normalizedNames(dto.typeNames),
            height: dto.height,
            weight: dto.weight,
            captureRate: dto.captureRate,
            colorName: normalizedOptionalName(dto.colorName)
        )
    }

    private static func mapColor(_ dto: PokemonColorDTO) throws -> PokemonColor {
        PokemonColor(
            id: try validIdentifier(dto.id),
            name: try validName(dto.name)
        )
    }

    private static func mapPokemon(_ dto: PokemonDTO) throws -> Pokemon {
        Pokemon(
            id: try validIdentifier(dto.id),
            name: try validName(dto.name),
            abilityNames: normalizedNames(dto.abilityNames)
        )
    }

    private static func validIdentifier(_ identifier: Int) throws -> Int {
        guard identifier > 0 else {
            throw PokemonMappingError.invalidIdentifier
        }
        return identifier
    }

    private static func validName(_ name: String) throws -> String {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw PokemonMappingError.invalidName
        }
        return normalized
    }

    private static func normalizedOptionalName(_ name: String?) -> String? {
        guard let name else { return nil }
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private static func normalizedNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names.compactMap { name in
            let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty, seen.insert(normalized).inserted else {
                return nil
            }
            return normalized
        }
    }
}
