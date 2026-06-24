//
//  MainView.swift
//  SD Beach Report
//
//  Created by Bryson Reese on 5/27/26.
//

import SwiftUI
import ConfettiSwiftUI

struct MainView: View {
    @EnvironmentObject var repository: BeachReportRepository
    @State private var confettiTrigger: Int = 0
    
    var statusSummary: some View {
        let closed = repository.reports.filter { $0.advisory?.type == "Closure" }.count
        let open = repository.reports.filter { $0.advisory == nil }.count
        let advisory = repository.reports.filter { $0.advisory?.type == "Posting" }.count
        
        return HStack(spacing: 0) {
            StatusSummaryItem(count: closed, label: "Closed", color: .red, icon: "xmark.circle.fill")
            Divider()
            StatusSummaryItem(count: advisory, label: "Advisory", color: .yellow, icon: "exclamationmark.triangle.fill")
            Divider()
            StatusSummaryItem(count: open, label: "Open", color: .green, icon: "checkmark.square.fill")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    var body: some View {
        NavigationStack {
            VStack{
                statusSummary
                HStack {
                    NavigationLink(destination: FullListView()) {
                        VStack {
                            Image(systemName: "list.clipboard")
                            Text("Reports")
                        }.frame(maxHeight: 44)
                    }.buttonStyle(.glass)
                    .buttonSizing(.flexible)
                    NavigationLink(destination: BeachMapView()) {
                        VStack {
                            Image(systemName: "map")
                            Text("Map")
                        }.frame(maxHeight: 44)
                    }.buttonStyle(.glass)
                    .buttonSizing(.flexible)
                }.padding(.top, 8)
                .padding(.horizontal, 8)
                List {
                    if let error = repository.error {
                        ContentUnavailableView {
                            Label("Error", systemImage: "exclamationmark.triangle.fill")
                            Text(error.localizedDescription)
                        }
                    } else if repository.isLoading {
                        ProgressView("Loading...")
                    } else if repository.favorites.isEmpty {
                        ContentUnavailableView {
                            Label("No Favorites", systemImage: "star.slash")
                            Text("Browse beaches to add favorites")
                        }
                    } else {
                        Section(header: Text("Favorites")) {
                            ForEach(repository.favorites) { report in
                                NavigationLink(destination: DetailsView(stationName: report.stationName)) {
                                    BeachReportRow(report: report)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        repository.toggleFavorite(for: report)
                                    } label: {
                                        report.favorite ?
                                        Label("Unfavorite", systemImage: "star.slash") :
                                        Label("Favorite", systemImage: "star")
                                    }
                                }
                            }
                            .onMove { from, to in
                                repository.swapFavorites(from, to)
                            }
                        }
                    }
                }.listStyle(.plain)
                    .contentMargins(0)
            }.navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack{
                        Image(systemName: "water.waves").foregroundColor(.blue)
                        Text("SD Beach Report")
                    }.onTapGesture(count: 10) {
                        confettiTrigger += 1
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: AboutInfoView()) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .refreshable{
                do {
                    try await repository.fetchReports(isRefreshing: true)
                } catch {
                    repository.error = error
                }
            }
        }.overlay(alignment: .bottom) {
            Color.clear
                .frame(height: 1)
                .confettiCannon(trigger: $confettiTrigger, num: 40, confettis: [.text("☀️"), .text("🌊"), .text("🏖️"), .text("🐚")], confettiSize: 20, radius: 800)
        }
    }
}
