//
//  HomeViewModel.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import Foundation
import Combine

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
