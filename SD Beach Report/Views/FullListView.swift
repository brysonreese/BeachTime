//
//  FullListView.swift
//  SD Beach Report
//
//  Created by Bryson Reese on 5/27/26.
//

import SwiftUI

struct FullListView: View {
    @EnvironmentObject var repository: BeachReportRepository
    @State private var searchText = ""
    @State private var selectedSort: BeachReportRepository.SortOptions = .nameAtoZ
    
    var filteredReports: [BeachReport] {
        if searchText.isEmpty {
            return repository.sortedReports(by: selectedSort)
        } else {
            return repository.sortedReports(by: selectedSort).filter {
                $0.stationName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            if let error = repository.error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                    Text(error.localizedDescription)
                }
            } else if repository.isLoading {
                ProgressView("Loading...")
            } else {
                Section(header: Text("All Beaches")) {
                    BeachList(beaches: filteredReports)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search beaches")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu("Sort: \(selectedSort.title)") {
                    Picker("Sort", selection: $selectedSort) {
                        ForEach(BeachReportRepository.SortOptions.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }
            }
        }
        .navigationTitle("Beach Reports")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            do {
                try await repository.fetchReports(isRefreshing: true)
            } catch {
                repository.error = error
            }
        }
    }
}
