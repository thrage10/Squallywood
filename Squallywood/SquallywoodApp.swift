//
//  SquallywoodApp.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/5/25.
//

import SwiftUI

@main
struct SquallywoodApp: App {
    @State private var userIsLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if !userIsLoggedIn {
                LoginSignupView(userIsLoggedIn: $userIsLoggedIn)
            } else {
                TabView {
                    TrailChecklistView(userIsLoggedIn: $userIsLoggedIn)
                        .tabItem {
                            Label("Completed Trails Checklist", systemImage: "checklist")
                        }
                    
                    MapView()
                        .tabItem {
                            Label("Trail Navigation Map", systemImage: "map")
                        }
                }
            }
        }
    }
}
