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
}

struct Summary: Codable {
    let distance: Int
    let duration: Int
}
