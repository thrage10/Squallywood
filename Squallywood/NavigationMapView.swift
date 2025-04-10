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
        supabaseURL: URL(string: "https://yayivyfaenfjkxeibddl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlheWl2eWZhZW5mamt4ZWliZGRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4NzIzNzIsImV4cCI6MjA1OTQ0ODM3Mn0.41_ftRNoFJvLKKcYc-BRIhAngryVmxxy3WWJT6PY-_Q"
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("From:")
                        .font(.headline)
                    Picker("From Trail", selection: $selectedStartingTrail) {
                        Text("Select starting trail").tag("")
                        ForEach(availableSkiTrails, id: \.self) { trail in
                            Text(trail).tag(trail)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("To:")
                        .font(.headline)
                    Picker("To Trail", selection: $selectedDestinationTrail) {
                        Text("Select destination trail").tag("")
                        ForEach(availableSkiTrails, id: \.self) { trail in
                            Text(trail).tag(trail)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                }
                .padding(.horizontal)
                
                Button(action: findPath) {
                    Text("Go")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                }
                .padding(.horizontal)
                .disabled(selectedStartingTrail.isEmpty || selectedDestinationTrail.isEmpty)
                
                if let calculatedRoute = calculatedRoute {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Route:")
                            .font(.headline)
                        ForEach(Array(calculatedRoute.enumerated()), id: \.offset) { index, trail in
                            HStack {
                                Text("\(index + 1).")
                                Text(trail)
                                if index < calculatedRoute.count - 1 {
                                    Image(systemName: "arrow.down")
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                    .padding(.horizontal)
                }
                
                if let errorMessage = navigationErrorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                OfficialTrailMapUIImage()
                    .frame(height: UIScreen.main.bounds.height * 0.6)
            }
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