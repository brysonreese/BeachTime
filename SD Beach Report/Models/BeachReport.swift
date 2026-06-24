//
//  BeachReport.swift
//  SD Beach Report
//
//  Created by Bryson Reese on 5/27/26.
//

import Foundation
import SwiftUI

struct BeachReport: Codable, Identifiable {
    var id: Int { stationID }
    var stationID: Int
    var stationName: String
    var beachName: String
    var stationDescription: String
    var latitude: Double
    var longitude: Double
    var advisory: Advisory?
    var favorite: Bool = false

    var cleanName: String {
        ( beachName + " " + stationDescription).replacingOccurrences(of: #"\s*\(.*?\)$"#, with: "", options: .regularExpression)
    }

    var statusIcon: (iconName: String, color: Color, description: String) {
        guard let advisory = advisory else {
            return ("checkmark.square.fill", .green, "Open")
        }

        switch advisory.type {
        case "Closure":
            return ("xmark.circle.fill", .red, "Closed")
        case "Posting":
            return ("exclamationmark.triangle.fill", .yellow, "Advisory")
        case "Rain":
            return ("cloud.rain.fill", .blue, "Rain Advisory")
        default:
            return ("questionmark.circle.fill", .gray, "Unknown")
        }
    }

    enum CodingKeys: String, CodingKey {
        case stationID = "station_id"
        case stationName = "station_name"
        case beachName = "beach_name"
        case stationDescription = "station_description"
        case latitude
        case longitude
        case advisory
    }
}

struct Advisory: Codable {
    var type: String?
    var cause: String?
    var startDate: String?

    enum CodingKeys: String, CodingKey {
        case type
        case cause
        case startDate = "start_date"
    }
}
