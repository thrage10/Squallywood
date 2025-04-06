//
//  model.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import Foundation
import Supabase


struct Trail: Identifiable, Codable {
    let id: UUID
    let name: String
}

struct TrailResponse: Codable {
    let id: String
    let name: String
}
