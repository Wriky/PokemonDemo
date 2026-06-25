//
//  HomeViewModel.swift
//  PokemonDemo
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    private let welcomeStorageKey = "alreadyEntered"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasSeenWelcome: Bool {
        defaults.bool(forKey: welcomeStorageKey)
    }

    func completeWelcome() {
        defaults.set(true, forKey: welcomeStorageKey)
    }
}
