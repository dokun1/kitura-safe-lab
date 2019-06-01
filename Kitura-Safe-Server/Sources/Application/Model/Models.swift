//
//  Person.swift
//  Application
//
//  Created by David Okun on 5/30/19.
//

import Foundation

enum Safety: String, Codable {
    enum CodingKeys: String, CodingKey {
        case unreported = "unreported"
        case safe = "safe"
        case unsafe = "unsafe"
    }
    
    case unreported = "Unreported"
    case safe = "Safe"
    case unsafe = "Unsafe"
}

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}

struct Person: Codable, Hashable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }
    
    var coordinate: Coordinate
    var name: String
    var id: String
    var status: Safety
}

struct Disaster: Codable {
    var coordinate: Coordinate
    var name: String
}

struct Dashboard: Codable {
    var coordinate: Coordinate
    var dashboardID: String
}
