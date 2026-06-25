//
//  PokemonArtworkLoader.swift
//  PokemonDemo
//

import Foundation
import UIKit

enum PokemonArtworkLoader {
    static let session: URLSession = {
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }()

    static func loadImage(for pokemonID: Int) async -> UIImage? {
        await loadFirstAvailableImage(
            from: PokemonArtworkURLBuilder.urls(for: pokemonID)
        ) { url in
            await loadImage(from: url, retries: 2)
        }
    }

    static func loadFirstAvailableImage(
        from urls: [URL],
        using loader: (URL) async -> UIImage?
    ) async -> UIImage? {
        for url in urls {
            if let image = await loader(url) {
                return image
            }
        }
        return nil
    }

    private static func loadImage(from url: URL, retries: Int) async -> UIImage? {
        for attempt in 0...retries {
            if Task.isCancelled { return nil }

            if let cached = cachedImage(for: url) {
                return cached
            }

            do {
                let (data, response) = try await session.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let image = UIImage(data: data) else {
                    continue
                }
                return image
            } catch {
                guard attempt < retries else { break }
                let delay = UInt64(400_000_000 * (attempt + 1))
                try? await Task.sleep(nanoseconds: delay)
            }
        }
        return nil
    }

    private static func cachedImage(for url: URL) -> UIImage? {
        guard let cached = session.configuration.urlCache?.cachedResponse(for: URLRequest(url: url)) else {
            return nil
        }
        return UIImage(data: cached.data)
    }
}
