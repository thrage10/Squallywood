//
//  SquallywoodMapView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import SwiftUI

struct SquallywoodMapView: View {
    var body: some View {
        ScrollView {
            Image("OfficialTrailMap")
                .resizable()
                .scaledToFit()
        }
    }
}

#Preview {
    SquallywoodMapView()
} 