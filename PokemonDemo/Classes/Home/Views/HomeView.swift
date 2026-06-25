//
//  HomeView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var hasSeenWelcome = false

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
        .onAppear {
            hasSeenWelcome = viewModel.hasSeenWelcome
        }
    }
}
