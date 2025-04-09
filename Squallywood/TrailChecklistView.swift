//
//  ContentView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/5/25.
//

import SwiftUI
import Supabase
import Foundation

struct TrailChecklistView: View {
    @Binding var userIsLoggedIn: Bool
    @State private var completedTrailsList: [CompletedTrailEntry] = []
    @State private var currentLoggedInUser: User? = nil
    @State private var availableSkiTrails: [String] = []
    @State private var selectedTrailToAdd: String = ""
    @State private var checklistErrorMessage: String? = nil
    
    let supabaseConnection = SupabaseClient(
        supabaseURL: URL(string: "https://yayivyfaenfjkxeibddl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlheWl2eWZhZW5mamt4ZWliZGRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4NzIzNzIsImV4cCI6MjA1OTQ0ODM3Mn0.41_ftRNoFJvLKKcYc-BRIhAngryVmxxy3WWJT6PY-_Q"
    )
            
   
    var body: some View {
        NavigationView {
            VStack {
                if userIsLoggedIn {
                    List {
                        if completedTrailsList.isEmpty {
                            Text("No completed trails yet. Add some!")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(completedTrailsList) { trail in
                                Text(trail.completedTrailName)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTrail(trail: trail)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }

                    HStack {
                        Picker("Select Trail", selection: $selectedTrailToAdd) {
                            Text("Select a trail").tag("")
                            ForEach(availableSkiTrails, id: \.self) { trail in
                                Text(trail).tag(trail)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        Button(action: addTrail) {
                            Image(systemName: "plus")
                                .padding()
                        }
                        .disabled(selectedTrailToAdd.isEmpty)
                    }
                    .padding()
                    
                    // Add error message display
                    if let checklistErrorMessage = checklistErrorMessage {
                        Text(checklistErrorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Button("Log Out") {
                        logout()
                    }
                    .padding()
                }
            }
            .navigationTitle("Completed Trails")
            .onAppear {
                print("TrailChecklistView appeared. Checking user...")
                checkLoggedInUser()
                fetchAvailableTrails()
            }
        }
    }

    func fetchAvailableTrails() {
        Task {
            do {
                let response = try await supabaseConnection.from("All_Trails")
                    .select("trail_name")
                    .execute()
                
                struct AvailableTrailResponse: Codable {
                    let trail_name: String
                }
                
                let trails = try JSONDecoder().decode([AvailableTrailResponse].self, from: response.data)
                await MainActor.run {
                    self.availableSkiTrails = trails.map { $0.trail_name }.sorted()
                    print("fetchAvailableTrails: Loaded \(self.availableSkiTrails.count) available trails.")
                }
            } catch {
                print("Error fetching available trails: \(error)")
            }
        }
    }

    func checkLoggedInUser() {
        Task {
            do {
                let user = try await supabaseConnection.auth.user()
                print("User session found: \(user.id)")
                await MainActor.run {
                    self.currentLoggedInUser = user
                    if !self.userIsLoggedIn { self.userIsLoggedIn = true }
                }
                print("User confirmed, calling fetchTrails...")
                await fetchTrails()
            } catch {
                print("No user session found or error: \(error)")
                await MainActor.run {
                    self.currentLoggedInUser = nil
                    self.userIsLoggedIn = false
                    self.completedTrailsList = []
                }
            }
        }
    }

    func logout() {
        Task {
            do {
                try await supabaseConnection.auth.signOut()
                await MainActor.run {
                    self.userIsLoggedIn = false
                    self.currentLoggedInUser = nil
                    self.completedTrailsList = []
                    self.selectedTrailToAdd = ""
                    self.availableSkiTrails = []
                    self.checklistErrorMessage = nil // Clear error message
                    print("User logged out.")
                }
            } catch {
                print("Error logging out: \(error)")
            }
        }
    }

    func addTrail() {
        Task {
            await addTrailAsync()
        }
    }

    func addTrailAsync() async {
        guard let userId = currentLoggedInUser?.id else { return }
        
        // Check if trail is already in the completed trails
        if completedTrailsList.contains(where: { $0.completedTrailId == userId }) {
            await MainActor.run {
                checklistErrorMessage = "This trail is already logged as completed"
                // Optionally, clear the error after a few seconds
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await MainActor.run {
                        checklistErrorMessage = nil
                    }
                }
            }
            return
        }

        let trailData: [String: String] = [
            "trail_name": selectedTrailToAdd,
            "user_id": userId.uuidString
        ]

        do {
            let response = try await supabaseConnection.from("Completed_Trails")
                .insert(trailData)
                .select()
                .single()
                .execute()
            
            let newTrailResponse = try JSONDecoder().decode(CompletedTrailDatabaseResponse.self, from: response.data)
            
            await MainActor.run {
                self.completedTrailsList.append(newTrailResponse.toCompletedTrailEntry())
                selectedTrailToAdd = ""
                checklistErrorMessage = nil // Clear any existing error message
            }
        } catch {
            print("Error adding trail: \(error)")
            await MainActor.run {
                checklistErrorMessage = "Error adding trail: \(error.localizedDescription)"
            }
        }
    }

    func deleteTrail(trail: CompletedTrailEntry) {
        Task {
            do {
                print("deleteTrail: Attempting to delete trail with ID: \(trail.completedTrailId)")
                _ = try await supabaseConnection.from("Completed_Trails")
                    .delete()
                    .eq("id", value: trail.completedTrailId)
                    .execute()
                
                await MainActor.run {
                    completedTrailsList.removeAll { $0.completedTrailId == trail.completedTrailId }
                    print("deleteTrail: Successfully deleted trail ID \(trail.completedTrailId) locally.")
                }
            } catch {
                print("deleteTrail: Error deleting trail ID \(trail.completedTrailId) from Supabase: \(error)")
                await MainActor.run {
                    checklistErrorMessage = "Error deleting trail: \(error.localizedDescription)"
                    // Clear error after a delay
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        await MainActor.run {
                            checklistErrorMessage = nil
                        }
                    }
                }
            }
        }
    }

    // Keep this function for compatibility with ForEach's onDelete
    func deleteTrail(at offsets: IndexSet) {
        for index in offsets {
            let trail = completedTrailsList[index]
            deleteTrail(trail: trail)
        }
    }

    func fetchTrails() async {
        guard let userId = currentLoggedInUser?.id else {
            print("fetchTrails: No user ID available")
            return
        }
        
        do {
            print("fetchTrails: Fetching trails for user ID: \(userId)")
            let response = try await supabaseConnection.from("Completed_Trails")
                .select()
                .eq("user_id", value: userId)
                .execute()
            
            let trailResponses = try JSONDecoder().decode([CompletedTrailDatabaseResponse].self, from: response.data)
            
            await MainActor.run {
                self.completedTrailsList = trailResponses.map { $0.toCompletedTrailEntry() }
                print("fetchTrails: Loaded \(self.completedTrailsList.count) trails")
            }
        } catch {
            print("Error fetching trails: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding error: \(decodingError)")
            }
            await MainActor.run {
                self.completedTrailsList = []
            }
        }
    }
}
