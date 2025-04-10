//
//  MapView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import SwiftUI

struct MapView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("View Selection", selection: $selectedTab) {
                    Text("Official").tag(0)
                    Text("Navigation").tag(1)
                    Text("Squallywood").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TabView(selection: $selectedTab) {
                    OfficialMapView()
                        .tag(0)
                    
                    NavigationMapView()
                        .tag(1)
                    
                    SquallywoodMapView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Trail Map")
        }
    }
}

#Preview {
    MapView()
} 
