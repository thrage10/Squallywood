//
//  model.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import Foundation
import Supabase
import CoreGraphics
import SwiftUI

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

struct SquallywoodRegion: Identifiable, Codable {
    let id: String
    var points: [CGPoint]
}

// Owns all completed-trail data for the session. Lives at the app level so data
// survives tab switches without re-fetching.
@MainActor
final class TrailChecklistStore: ObservableObject {
    @Published var completedTrailsList: [CompletedTrailEntry] = []
    @Published var availableSkiTrails: [String] = []
    @Published var errorMessage: String? = nil

    private var currentUserId: UUID? = nil
    private var isLoaded = false

    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://qklbeoadcidyasmuerjv.supabase.co")!,
        supabaseKey: "sb_publishable_3Q8l1ko8VIC5bXOfEoPgew_wHx-wKnj"
    )

    // Called once when the user logs in. Guard prevents re-fetching on tab switches.
    func loadForSession() {
        guard !isLoaded else { return }
        isLoaded = true
        Task {
            do {
                let user = try await supabase.auth.user()
                currentUserId = user.id
                await fetchTrails()
                await fetchAvailableTrails()
            } catch {
                isLoaded = false
                print("TrailChecklistStore: session load error: \(error)")
            }
        }
    }

    func logout() async {
        do { try await supabase.auth.signOut() } catch { print("Logout error: \(error)") }
        completedTrailsList = []
        availableSkiTrails = []
        errorMessage = nil
        currentUserId = nil
        isLoaded = false
    }

    // Returns true on success so the caller can reset the picker selection.
    func addTrail(named trailName: String) async -> Bool {
        guard let userId = currentUserId else { return false }
        let trailData: [String: String] = ["trail_name": trailName, "user_id": userId.uuidString]
        do {
            let response = try await supabase.from("Completed_Trails")
                .insert(trailData).select().single().execute()
            let newTrail = try JSONDecoder().decode(CompletedTrailDatabaseResponse.self, from: response.data)
            completedTrailsList.append(newTrail.toCompletedTrailEntry())
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Error adding trail: \(error.localizedDescription)"
            return false
        }
    }

    func deleteTrail(_ trail: CompletedTrailEntry) {
        Task {
            do {
                _ = try await supabase.from("Completed_Trails")
                    .delete().eq("id", value: trail.completedTrailId).execute()
                completedTrailsList.removeAll { $0.completedTrailId == trail.completedTrailId }
            } catch {
                errorMessage = "Error deleting trail: \(error.localizedDescription)"
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    errorMessage = nil
                }
            }
        }
    }

    private func fetchTrails() async {
        guard let userId = currentUserId else { return }
        do {
            let response = try await supabase.from("Completed_Trails")
                .select().eq("user_id", value: userId).execute()
            completedTrailsList = try JSONDecoder()
                .decode([CompletedTrailDatabaseResponse].self, from: response.data)
                .map { $0.toCompletedTrailEntry() }
        } catch {
            print("Error fetching trails: \(error)")
        }
    }

    private func fetchAvailableTrails() async {
        do {
            struct Row: Codable { let trail_name: String }
            let response = try await supabase.from("All_Trails").select("trail_name").execute()
            availableSkiTrails = try JSONDecoder()
                .decode([Row].self, from: response.data)
                .map { $0.trail_name }.sorted()
        } catch {
            print("Error fetching available trails: \(error)")
        }
    }
}
