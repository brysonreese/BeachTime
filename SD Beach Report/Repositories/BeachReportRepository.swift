//
//  BeachReport.swift
//  SD Beach Report
//
//  Created by Bryson Reese on 5/27/26.
//

import Foundation
internal import Combine
import SwiftUI

@MainActor
class BeachReportRepository: ObservableObject {
    @Published var reports: [BeachReport] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    var favorites: [BeachReport] {
        let savedNames = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        var result: [BeachReport] = []
        for stationName in savedNames {
            if let beach = self.getBeachByStationName(stationName) {
                result.append(beach)
            }
        }
        return result
    }

    enum SortOptions: String, Identifiable, CaseIterable {
        case nameAtoZ
        case nameZtoA
        case severityLowtoHigh
        case severityHightoLow

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .nameAtoZ: return "Name: A - Z"
            case .nameZtoA: return "Name: Z - A"
            case .severityLowtoHigh: return "Severity: Low - High"
            case .severityHightoLow: return "Severity: High - Low"
            }
        }
    }

    // Lower index = more severe
    private let severityOrder: [String] = ["Closure", "Posting", "Rain"]

    private func severityRank(for beach: BeachReport) -> Int {
        guard let type = beach.advisory?.type else { return 999 } // open reports rank lowest severity
        return severityOrder.firstIndex(of: type) ?? 998
    }

    func sortedReports(by: SortOptions) -> [BeachReport] {
        switch by {
        case .nameAtoZ:
            return reports.sorted { $0.cleanName < $1.cleanName }
        case .nameZtoA:
            return reports.sorted { $0.cleanName > $1.cleanName }
        case .severityLowtoHigh:
            return reports.sorted { severityRank(for: $0) > severityRank(for: $1) }
        case .severityHightoLow:
            return reports.sorted { severityRank(for: $0) < severityRank(for: $1) }
        }
    }

    private let url = URL(string: "http://127.0.0.1:8000/beach_status")!
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 8
        return URLSession(configuration: config)
    }()

    init() {
        Task {
            try await fetchReports()
        }
    }

    func getBeachByStationName(_ stationName: String) -> BeachReport? {
        return reports.first(where: { $0.stationName == stationName })
    }

    func fetchReports(isRefreshing: Bool = false) async throws {
        if !isRefreshing {
            isLoading = true
        }
        reports = []
        error = nil

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            reports = try JSONDecoder().decode([BeachReport].self, from: data)
            await loadFavorites()
        } catch {
            if (error as? URLError)?.code == .cancelled {
            } else {
                self.error = error
            }
        }

        isLoading = false
    }

    func toggleFavorite(for beach: BeachReport) {
        if let index = reports.firstIndex(where: { $0.stationName == beach.stationName }) {
            let savedNames = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
            if reports[index].favorite {
                saveFavorites(favorites: savedNames.filter { $0 != beach.stationName })
            } else {
                saveFavorites(favorites: savedNames + [beach.stationName])
            }
            reports[index].favorite.toggle()
        }
    }

    private let favoritesKey = "favoriteStationNames"

    func saveFavorites(favorites: [String]) {
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
        objectWillChange.send()
    }

    func loadFavorites() async {
        let savedNames = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        for index in reports.indices {
            reports[index].favorite = savedNames.contains(reports[index].stationName)
        }
    }

    func swapFavorites(_ from: IndexSet, _ to: Int) {
        if var savedNames = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            savedNames.move(fromOffsets: from, toOffset: to)
            saveFavorites(favorites: savedNames)
        }
    }
}
