//
//  SquallywoodMapView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import SwiftUI

struct SquallywoodMapView: View {
    @State private var squallywoodRegions: [SquallywoodRegion] = []
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // Single coordinate scale factor to adjust
    private let coordinateScale: CGFloat = 4.4  // Adjust this number to find the perfect fit
    
    // Define colors for the regions
    let regionColors: [Color] = [
        .red.opacity(0.3),
        .blue.opacity(0.3),
        .green.opacity(0.3),
        .orange.opacity(0.3),
        .purple.opacity(0.3),
        .cyan.opacity(0.3),
        .yellow.opacity(0.3),
        .red.opacity(0.3),
        .gray.opacity(0.3)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let mapImage = UIImage(named: "OfficialBlank") {
                    let imageSize = mapImage.size
                    let aspectRatio = imageSize.width / imageSize.height
                    let containerWidth = geometry.size.width
                    let containerHeight = containerWidth / aspectRatio
                    
                    ZStack {
                        // Base map
                        Image(uiImage: mapImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: containerWidth, height: containerHeight)
                            .scaleEffect(scale)
                            .offset(offset)
                            
                        
                        // Container for all regions
                        ZStack {
                            // Regions
                            ForEach(Array(squallywoodRegions.enumerated()), id: \.element.id) { index, region in
                                let color = regionColors[index % regionColors.count]
                                
                                Path { path in
                                    guard let firstPoint = region.points.first else { return }
                                    
                                    let scaleX = containerWidth / imageSize.width
                                    
                                    let scaledFirst = CGPoint(
                                        x: firstPoint.x * coordinateScale * scaleX,
                                        y: firstPoint.y * coordinateScale * scaleX
                                    )
                                    
                                    path.move(to: scaledFirst)
                                    
                                    for point in region.points.dropFirst() {
                                        let scaledPoint = CGPoint(
                                            x: point.x * coordinateScale * scaleX,
                                            y: point.y * coordinateScale * scaleX
                                        )
                                        path.addLine(to: scaledPoint)
                                    }
                                    
                                    path.closeSubpath()
                                }
                                .fill(color)
                                .overlay(
                                    Path { path in
                                        guard let firstPoint = region.points.first else { return }
                                        let scaleX = containerWidth / imageSize.width
                                        
                                        let scaledFirst = CGPoint(
                                            x: firstPoint.x * coordinateScale * scaleX,
                                            y: firstPoint.y * coordinateScale * scaleX
                                        )
                                        path.move(to: scaledFirst)
                                        
                                        for point in region.points.dropFirst() {
                                            let scaledPoint = CGPoint(
                                                x: point.x * coordinateScale * scaleX,
                                                y: point.y * coordinateScale * scaleX
                                            )
                                            path.addLine(to: scaledPoint)
                                        }
                                        path.closeSubpath()
                                    }
                                    .stroke(color.opacity(0.8), lineWidth: 2)
                                )
                                .contentShape(Path { path in
                                    guard let firstPoint = region.points.first else { return }
                                    let scaleX = containerWidth / imageSize.width
                                    
                                    let scaledFirst = CGPoint(
                                        x: firstPoint.x * coordinateScale * scaleX,
                                        y: firstPoint.y * coordinateScale * scaleX
                                    )
                                    path.move(to: scaledFirst)
                                    
                                    for point in region.points.dropFirst() {
                                        let scaledPoint = CGPoint(
                                            x: point.x * coordinateScale * scaleX,
                                            y: point.y * coordinateScale * scaleX
                                        )
                                        path.addLine(to: scaledPoint)
                                    }
                                    path.closeSubpath()
                                })
                                .onTapGesture {
                                    print("Tapped region: \(region.id)")
                                }
                                
                                // Region label
                                if let centerPoint = calculateRegionCenter(points: region.points) {
                                    let scaleX = containerWidth / imageSize.width
                                    let scaledCenter = CGPoint(
                                        x: centerPoint.x * coordinateScale * scaleX,
                                        y: centerPoint.y * coordinateScale * scaleX
                                    )
                                    
                                    Text(region.id)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(color.opacity(0.8))
                                        .cornerRadius(4)
                                        .position(scaledCenter)
                                }
                            }
                        }
                        .scaleEffect(scale)
                        .offset(offset)
                    }
                    .frame(width: containerWidth, height: containerHeight)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
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
                } else {
                    Text("Blank map image not found")
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            squallywoodRegions = loadSquallywoodRegionsFromJSON()
        }
    }
    
    func calculateRegionCenter(points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let xSum = points.reduce(0) { $0 + $1.x }
        let ySum = points.reduce(0) { $0 + $1.y }
        return CGPoint(
            x: xSum / CGFloat(points.count),
            y: ySum / CGFloat(points.count)
        )
    }
}

#Preview {
    SquallywoodMapView()
} 
