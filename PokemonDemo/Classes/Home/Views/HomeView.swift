//
//  HomeView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var hasSeenWelcome: Bool

    init(viewModel: HomeViewModel = HomeViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _hasSeenWelcome = State(initialValue: viewModel.hasSeenWelcome)
    }

    var body: some View {
        Group {
            if hasSeenWelcome {
                SearchView()
            } else {
                WelcomeView {
                    viewModel.completeWelcome()
                    hasSeenWelcome = true
                }
            }
        }
    }
}
