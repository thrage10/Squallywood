//
//  model.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import Foundation
import Supabase

// Main Trail model used throughout the app
struct Trail: Identifiable, Codable {
    let id: UUID
    let name: String
}

// Response structure matching Supabase table columns exactly
struct TrailResponse: Codable {
    let id: UUID
    let trail_name: String
    let user_id: UUID
    
    // Add a conversion method to Trail
    func toTrail() -> Trail {
        return Trail(id: id, name: trail_name)
    }
}

struct CompletedTrailEntry: Identifiable, Codable {
    let id: UUID
    let completedTrailName: String
    
    var completedTrailId: UUID { id }
}

struct CompletedTrailDatabaseResponse: Codable {
    let id: UUID
    let trail_name: String
    let user_id: UUID
    
    func toCompletedTrailEntry() -> CompletedTrailEntry {
        return CompletedTrailEntry(
            id: id,
            completedTrailName: trail_name
        )
    }
}
