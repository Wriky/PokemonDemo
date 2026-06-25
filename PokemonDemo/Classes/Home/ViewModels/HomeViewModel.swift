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

    var hasSeenWelcome: Bool {
        UserDefaults.standard.bool(forKey: welcomeStorageKey)
    }

    func completeWelcome() {
        UserDefaults.standard.set(true, forKey: welcomeStorageKey)
    }
}
