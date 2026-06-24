//
//  DetailsView.swift
//  SD Beach Report
//
//  Created by Bryson Reese on 5/27/26.
//

import SwiftUI

struct DetailsView: View {
    @EnvironmentObject var repository: BeachReportRepository
    let stationName: String
    
    var report: BeachReport? {
        repository.reports.first(where: { $0.stationName == stationName })
    }

    var body: some View {
        if let report = report {
            List {
                Section("Beach Info") {
                    LabeledContent("Name", value: report.cleanName)
                    LabeledContent("Status") {
                        HStack {
                            Text(report.statusIcon.description)
                            Image(systemName: report.statusIcon.iconName)
                                .foregroundColor(report.statusIcon.color)
                        }
                    }
                }
                
                Button {
                    repository.toggleFavorite(for: report)
                } label: {
                    report.favorite ?
                    Label("Remove Favorite", systemImage: "star.fill") :
                    Label("Add Favorite", systemImage: "star")
                }
                
                
                Section("Description") {
                    if report.advisory != nil && report.advisory!.cause != nil {
                        Text(report.advisory!.cause!)
                            .font(.body)
                    }
                }
            }
            .navigationTitle(report.cleanName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
