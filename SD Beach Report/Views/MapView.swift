//
//  MapView.swift
//  SD Beach Report
//
//  Created by Bryson Reese on 5/27/26.
//

import MapKit
import SwiftUI

struct BeachMapView: View {
    @EnvironmentObject var repository: BeachReportRepository
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReport: BeachReport?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedDetent: PresentationDetent = .fraction(0.15)
    @State private var searchText: String = ""
    @State private var showSheet: Bool = true
    
    var filteredReports: [BeachReport] {
        if searchText.isEmpty {
            return repository.sortedReports(by: BeachReportRepository.SortOptions.nameAtoZ)
        } else {
            return repository.sortedReports(by: BeachReportRepository.SortOptions.nameAtoZ).filter {
                $0.beachName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        Group {
            if let error = repository.error {
                ScrollView{
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle.fill")
                        Text(error.localizedDescription)
                    }
                }
            } else if repository.isLoading {
                ProgressView("Loading...")
            } else {
                Map(position: $cameraPosition) {
                    ForEach(repository.reports, id: \.stationName) { report in
                        Annotation("", coordinate: CLLocationCoordinate2D(
                            latitude: report.latitude,
                            longitude: report.longitude
                        )) {
                            BeachMapPin(report: report)
                                .onTapGesture {
                                    withAnimation {
                                        selectedReport = report
                                        selectedDetent = .medium
                                        cameraPosition = .camera(MapCamera(
                                            centerCoordinate: CLLocationCoordinate2D(
                                                latitude: report.latitude - 0.01,
                                                longitude: report.longitude
                                            ),
                                            distance: 10000
                                        ))
                                    }
                                }
                        }
                    }
                }
                .onMapCameraChange {
                    if selectedReport == nil {
                        withAnimation {
                            selectedDetent = .fraction(0.15)
                        }
                    }
                }
                .sheet(isPresented: $showSheet) {
                    NavigationStack {
                        if let selected = selectedReport {
                            // detail state
                            DetailsView(stationName: selected.stationName)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button {
                                            withAnimation {
                                                selectedReport = nil
                                                selectedDetent = .medium
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "chevron.left")
                                                Text("Beaches")
                                            }
                                        }
                                    }
                                }
                        } else {
                            List {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.secondary)
                                    TextField("Search beaches...", text: $searchText)
                                        .autocorrectionDisabled()
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 4)
                                
                                ForEach(filteredReports, id: \.stationName) { report in
                                    Button {
                                        withAnimation {
                                            selectedReport = report
                                            selectedDetent = .medium
                                            cameraPosition = .camera(MapCamera(
                                                centerCoordinate: CLLocationCoordinate2D(
                                                    latitude: report.latitude - 0.01,
                                                    longitude: report.longitude
                                                ),
                                                distance: 10000
                                            ))
                                        }
                                    } label: {
                                        BeachReportRow(report: report)
                                    }
                                    .tint(.primary)
                                }
                            }
                            .listStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .presentationDetents([.fraction(0.15), .medium, .large], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationBackground(.regularMaterial)
                    .interactiveDismissDisabled()
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            showSheet = false
                            dismiss()
                        }) {
                            Image(systemName: "chevron.backward")
                        }
                    }
                }
            }
        }
    }
}
