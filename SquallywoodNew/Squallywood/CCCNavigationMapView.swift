//
//  NavigationMapView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import SwiftUI
import Supabase

struct SkiTrailWithConnections: Codable {
    let trail_name: String
    let downhill_node_1: String?
    let downhill_node_2: String?
    let downhill_node_3: String?
    let downhill_node_4: String?
    let downhill_node_5: String?
    let downhill_node_6: String?
    let downhill_node_7: String?
    let downhill_node_8: String?
    
    var connectedTrails: [String] {
        [downhill_node_1, downhill_node_2, downhill_node_3, 
         downhill_node_4, downhill_node_5, downhill_node_6, 
         downhill_node_7, downhill_node_8]
            .compactMap { $0 }
    }
}

class SkiTrailNavigationGraph {
    var trailConnectionMap: [String: [String]] = [:]
    
    init(skiTrails: [SkiTrailWithConnections]) {
        for skiTrail in skiTrails {
            trailConnectionMap[skiTrail.trail_name] = skiTrail.connectedTrails
        }
    }
    
    func findShortestRouteFromTrailToTrail(startingTrail: String, destinationTrail: String) -> [String]? {
        guard trailConnectionMap[startingTrail] != nil, trailConnectionMap[destinationTrail] != nil else { return nil }
        
        var visited: Set<String> = []
        var queue: [(node: String, path: [String])] = [(startingTrail, [startingTrail])]
        
        while !queue.isEmpty {
            let (currentNode, currentPath) = queue.removeFirst()
            
            if currentNode == destinationTrail {
                return currentPath
            }
            
            if visited.contains(currentNode) { continue }
            visited.insert(currentNode)
            
            for neighbor in trailConnectionMap[currentNode] ?? [] {
                if !visited.contains(neighbor) {
                    queue.append((neighbor, currentPath + [neighbor]))
                }
            }
        }
        
        return nil
    }
}

struct NavigationMapView: View {
    @State private var selectedStartingTrail: String = ""
    @State private var selectedDestinationTrail: String = ""
    @State private var availableSkiTrails: [String] = []
    @State private var skiTrailNavigationSystem: SkiTrailNavigationGraph?
    @State private var calculatedRoute: [String]? = nil
    @State private var navigationErrorMessage: String? = nil
    
    let supabaseConnection = SupabaseClient(
        supabaseURL: URL(string: "https://qklbeoadcidyasmuerjv.supabase.co")!,
        supabaseKey: "sb_publishable_3Q8l1ko8VIC5bXOfEoPgew_wHx-wKnj"
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed compact header
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("From").font(.caption).foregroundColor(.secondary)
                        Picker("", selection: $selectedStartingTrail) {
                            Text("Select").tag("")
                            ForEach(availableSkiTrails, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray6)))
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("To").font(.caption).foregroundColor(.secondary)
                        Picker("", selection: $selectedDestinationTrail) {
                            Text("Select").tag("")
                            ForEach(availableSkiTrails, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray6)))
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: findPath) {
                        Text("Go")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                    }
                    .disabled(selectedStartingTrail.isEmpty || selectedDestinationTrail.isEmpty)
                }

                if let calculatedRoute = calculatedRoute {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(calculatedRoute.enumerated()), id: \.offset) { index, trail in
                                Text(trail).font(.caption2)
                                if index < calculatedRoute.count - 1 {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                if let errorMessage = navigationErrorMessage {
                    Text(errorMessage).font(.caption).foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            Divider()

            NavigationTrailMapImage()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            fetchTrailData()
        }
    }
    
    func fetchTrailData() {
        Task {
            do {
                let response = try await supabaseConnection.from("All_Trails")
                    .select()
                    .execute()
                
                let trails = try JSONDecoder().decode([SkiTrailWithConnections].self, from: response.data)
                
                await MainActor.run {
                    self.availableSkiTrails = trails.map { $0.trail_name }.sorted()
                    self.skiTrailNavigationSystem = SkiTrailNavigationGraph(skiTrails: trails)
                }
            } catch {
                await MainActor.run {
                    self.navigationErrorMessage = "Error loading trail data"
                }
            }
        }
    }
    
    func findPath() {
        guard let graph = skiTrailNavigationSystem else {
            navigationErrorMessage = "Trail data not loaded"
            return
        }
        
        if let foundPath = graph.findShortestRouteFromTrailToTrail(
            startingTrail: selectedStartingTrail,
            destinationTrail: selectedDestinationTrail
        ) {
            calculatedRoute = foundPath
            navigationErrorMessage = nil
        } else {
            calculatedRoute = nil
            navigationErrorMessage = "No route found between these trails"
        }
    }
}

#Preview {
    NavigationMapView()
} 
