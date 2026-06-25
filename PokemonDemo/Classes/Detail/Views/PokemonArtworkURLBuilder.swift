import Foundation

nonisolated enum PokemonArtworkURLBuilder {
    static func urls(for pokemonID: Int) -> [URL] {
        [
            "https://cdn.jsdelivr.net/gh/PokeAPI/sprites@master/sprites/pokemon/other/official-artwork/\(pokemonID).png",
            "https://cdn.jsdelivr.net/gh/PokeAPI/sprites@master/sprites/pokemon/\(pokemonID).png",
            "https://cdn.jsdelivr.net/gh/PokeAPI/sprites@master/sprites/pokemon/other/home/\(pokemonID).png"
        ].compactMap(URL.init(string:))
    }
}
