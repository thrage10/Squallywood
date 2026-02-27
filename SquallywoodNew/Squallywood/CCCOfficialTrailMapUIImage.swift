import SwiftUI
import UIKit

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
                    OfficialTrailMapUIImage()
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

struct OfficialTrailMapUIImage: View {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            if let mapImage = UIImage(named: "OfficialTrailMap") {
                Image(uiImage: mapImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 10)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                },
                            DragGesture()
                                .onChanged { value in
                                    let delta = CGSize(
                                        width: value.translation.width - lastOffset.width,
                                        height: value.translation.height - lastOffset.height
                                    )
                                    lastOffset = value.translation
                                    offset = CGSize(
                                        width: offset.width + delta.width,
                                        height: offset.height + delta.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = .zero
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            scale = 1.0
                            offset = .zero
                        }
                    }
            } else {
                Text("Map image not found")
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    MapView()
} 
