//
//  MapModel.swift
//  Sparking
//
//  Created by 김나연 on 4/4/25.
//

import Foundation

struct MapRoot: Codable {
    let routes: [Route]
}

struct Route: Codable {
    let summary: Summary
    let sections: [Section]
}

struct Summary: Codable {
    let distance: Int
    let duration: Int
}

struct Section: Codable {
    let roads: [Road]
}

struct Road: Codable {
    let vertexes: [Double]
}
