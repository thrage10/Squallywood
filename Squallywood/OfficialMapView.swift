//
//  OfficialMapView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import SwiftUI

struct OfficialMapView: View {
    var body: some View {
        ScrollView {
            Image("OfficialTrailMap")
                .resizable()
                .scaledToFit()
        }
    }
}

#Preview {
    OfficialMapView()
} 