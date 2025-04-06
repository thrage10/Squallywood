//
//  SquallywoodApp.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/5/25.
//

import SwiftUI

@main
struct SquallywoodApp: App {
    @State private var isLoggedIn: Bool = false // Track login state

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                // Show TrailChecklistView if user is logged in
                TrailChecklistView(isLoggedIn: $isLoggedIn)
            } else {
                // Show LoginSignupView if user is not logged in
                LoginSignupView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
