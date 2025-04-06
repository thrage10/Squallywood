//
//  ContentView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/5/25.
//

import SwiftUI
import Supabase


struct TrailChecklistView: View {
    @Binding var isLoggedIn: Bool  // Bind to isLoggedIn state from the main app
    @State private var trails: [Trail] = []
    @State private var newTrailName: String = ""
    @State private var currentUser: User? = nil
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://yayivyfaenfjkxeibddl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlheWl2eWZhZW5mamt4ZWliZGRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4NzIzNzIsImV4cCI6MjA1OTQ0ODM3Mn0.41_ftRNoFJvLKKcYc-BRIhAngryVmxxy3WWJT6PY-_Q"
    )
            
   
    var body: some View {
            NavigationView {
                VStack {
                    if isLoggedIn {
                        List {
                            ForEach(trails) { trail in
                                Text(trail.name)
                            }
                            .onDelete(perform: deleteTrail)
                        }

                        HStack {
                            TextField("New trail", text: $newTrailName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button(action: addTrail) {
                                Image(systemName: "plus")
                                    .padding()
                            }
                            .disabled(newTrailName.isEmpty)
                        }
                        .padding()

                        Button("Log Out") {
                            logout()
                        }
                        .padding()
                    }
                }
                .navigationTitle(isLoggedIn ? "Completed Trails" : "Log In / Sign Up")
                .onAppear {
                    checkLoggedInUser()
                }
            }
        }

        func checkLoggedInUser() {
            Task {
                if let user = try? await supabase.auth.user() {
                    self.currentUser = user
                    self.isLoggedIn = true
                    await fetchTrails()
                } else {
                    self.currentUser = nil
                    self.isLoggedIn = false
                }
            }
        }

        func logout() {
            Task {
                do {
                    try await supabase.auth.signOut()
                    self.isLoggedIn = false
                    self.trails = []
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
            guard let userIdString = currentUser?.id else { return }
            let userId = userIdString.uuidString

            let trail = Trail(id: UUID(), name: newTrailName)

            do {
                _ = try await supabase.from("Completed_Trails").insert([
                    ["trail_name": trail.name, "user_id": userId]
                ]).execute()

                trails.append(trail)
                newTrailName = ""
            } catch {
                print("Error adding trail: \(error)")
            }
        }

        func deleteTrail(at offsets: IndexSet) {
            Task {
                for index in offsets {
                    let trail = trails[index]

                    do {
                        _ = try await supabase.from("Completed_Trails")
                            .delete()
                            .eq("id", value: trail.id.uuidString)
                            .execute()
                    }
                }
                trails.remove(atOffsets: offsets)
            }
        }

        func fetchTrails() async {
            guard let userId = currentUser?.id else { return }

            do {
                let response = try await supabase.from("Completed_Trails")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()

                let trailResponses = try JSONDecoder().decode([TrailResponse].self, from: response.data)
                self.trails = trailResponses.map { trail in
                    Trail(id: UUID(uuidString: trail.id) ?? UUID(), name: trail.name)
                }
            } catch {
                print("Error fetching trails: \(error)")
            }
        }
    }
