//
//  BeachList.swift
//  SD Beach Report
//
//  Created by Bryson Reese on 5/27/26.
//
import SwiftUI

struct BeachList: View {
    let beaches: [BeachReport]
    @EnvironmentObject var repository: BeachReportRepository
    
    var body: some View {
        ForEach(beaches) { report in
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
    }
}
