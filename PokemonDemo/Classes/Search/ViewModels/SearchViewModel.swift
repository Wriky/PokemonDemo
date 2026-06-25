//
//  SearchViewModel.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var keyword = ""
    @Published private(set) var speciesList: [PokemonSpecies] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasSearched = false

    private let service: any PokemonServicing
    private let pageSize = 20
    private var currentOffset = 0
    private var canLoadMore = false
    private var latestSearchRequestID = 0

    init(service: any PokemonServicing = PokemonService()) {
        self.service = service
    }

    var isSearchDisabled: Bool {
        trimmedKeyword.isEmpty
    }

    var shouldShowLoadMore: Bool {
        canLoadMore && !speciesList.isEmpty
    }

    var shouldShowNoMoreData: Bool {
        hasSearched && !speciesList.isEmpty && !canLoadMore && !isLoading && !isLoadingMore
    }

    func search() async {
        let keyword = trimmedKeyword
        guard !keyword.isEmpty else { return }

        latestSearchRequestID += 1
        let requestID = latestSearchRequestID

        isLoading = true
        hasSearched = true
        errorMessage = nil
        currentOffset = 0

        do {
            let results = try await service.searchSpecies(
                keyword: keyword,
                limit: pageSize,
                offset: currentOffset
            )
            guard requestID == latestSearchRequestID else { return }
            speciesList = results
            currentOffset = results.count
            canLoadMore = results.count == pageSize
        } catch {
            guard requestID == latestSearchRequestID else { return }
            speciesList = []
            canLoadMore = false
            errorMessage = error.localizedDescription
        }

        if requestID == latestSearchRequestID {
            isLoading = false
        }
    }

    func loadMore() async {
        guard shouldShowLoadMore, !isLoadingMore else { return }

        isLoadingMore = true
        errorMessage = nil

        do {
            let moreResults = try await service.searchSpecies(
                keyword: trimmedKeyword,
                limit: pageSize,
                offset: currentOffset
            )
            speciesList.append(contentsOf: moreResults)
            currentOffset += moreResults.count
            canLoadMore = moreResults.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    private var trimmedKeyword: String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
