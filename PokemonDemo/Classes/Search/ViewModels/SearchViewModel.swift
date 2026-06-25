//
//  SearchViewModel.swift
//  PokemonDemo
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

    private let repository: any PokemonRepositoryProtocol
    private let pageSize = 20
    private var currentOffset = 0
    private var canLoadMore = false
    private var latestSearchRequestID = 0
    private var currentSearchKeyword = ""

    init(repository: any PokemonRepositoryProtocol = PokemonRepository.production) {
        self.repository = repository
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
        currentSearchKeyword = keyword

        isLoading = true
        isLoadingMore = false
        hasSearched = true
        errorMessage = nil
        currentOffset = 0

        do {
            let results = try await repository.searchSpecies(
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

        let requestID = latestSearchRequestID
        let keyword = currentSearchKeyword
        let offset = currentOffset

        isLoadingMore = true
        errorMessage = nil

        do {
            let moreResults = try await repository.searchSpecies(
                keyword: keyword,
                limit: pageSize,
                offset: offset
            )
            guard requestID == latestSearchRequestID,
                  keyword == currentSearchKeyword else { return }
            speciesList.append(contentsOf: moreResults)
            currentOffset = offset + moreResults.count
            canLoadMore = moreResults.count == pageSize
        } catch {
            guard requestID == latestSearchRequestID,
                  keyword == currentSearchKeyword else { return }
            errorMessage = error.localizedDescription
        }

        if requestID == latestSearchRequestID,
           keyword == currentSearchKeyword {
            isLoadingMore = false
        }
    }

    private var trimmedKeyword: String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
