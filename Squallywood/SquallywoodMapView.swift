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
    
    // Define colors for the regions
    let regionColors: [Color] = [
        .red.opacity(0.3),
        .blue.opacity(0.3),
        .green.opacity(0.3),
        .orange.opacity(0.3),
        .purple.opacity(0.3),
        .pink.opacity(0.3),
        .yellow.opacity(0.3),
        .cyan.opacity(0.3)
    ]
    
    var body: some View {
        GeometryReader { geometry in
                   ZStack {
                       // Base map
                       if let mapImage = UIImage(named: "OfficialBlank") {
                           Image(uiImage: mapImage)
                               .resizable()
                               .scaledToFit()
                               .scaleEffect(scale)
                               .offset(offset)
                           
                           // Draw regions
                           ForEach(Array(squallywoodRegions.enumerated()), id: \.element.id) { index, region in
                               let color = regionColors[index % regionColors.count]
                               
                               // Region shape
                               Path { path in
                                   let imageScale = calculateScale(viewSize: geometry.size, imageSize: mapImage.size)
                                   guard let firstPoint = region.points.first else { return }
                                   let scaledFirstPoint = CGPoint(
                                       x: firstPoint.x * scale * imageScale + offset.width,
                                       y: firstPoint.y * scale * imageScale + offset.height
                                   )
                                   path.move(to: scaledFirstPoint)
                                   
                                   for point in region.points.dropFirst() {
                                       let scaledPoint = CGPoint(
                                           x: point.x * scale * imageScale + offset.width,
                                           y: point.y * scale * imageScale + offset.height
                                       )
                                       path.addLine(to: scaledPoint)
                                   }
                                   path.closeSubpath()
                               }
                               .fill(color)
                               .overlay(
                                   Path { path in
                                       let imageScale = calculateScale(viewSize: geometry.size, imageSize: mapImage.size)
                                       guard let firstPoint = region.points.first else { return }
                                       let scaledFirstPoint = CGPoint(
                                           x: firstPoint.x * scale * imageScale + offset.width,
                                           y: firstPoint.y * scale * imageScale + offset.height
                                       )
                                       path.move(to: scaledFirstPoint)
                                       
                                       for point in region.points.dropFirst() {
                                           let scaledPoint = CGPoint(
                                               x: point.x * scale * imageScale + offset.width,
                                               y: point.y * scale * imageScale + offset.height
                                           )
                                           path.addLine(to: scaledPoint)
                                       }
                                       path.closeSubpath()
                                   }
                                   .stroke(color.opacity(0.8), lineWidth: 2)
                               )
                               .contentShape(Path { path in
                                   let imageScale = calculateScale(viewSize: geometry.size, imageSize: mapImage.size)
                                   guard let firstPoint = region.points.first else { return }
                                   let scaledFirstPoint = CGPoint(
                                       x: firstPoint.x * scale * imageScale + offset.width,
                                       y: firstPoint.y * scale * imageScale + offset.height
                                   )
                                   path.move(to: scaledFirstPoint)
                                   
                                   for point in region.points.dropFirst() {
                                       let scaledPoint = CGPoint(
                                           x: point.x * scale * imageScale + offset.width,
                                           y: point.y * scale * imageScale + offset.height
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
                                   let imageScale = calculateScale(viewSize: geometry.size, imageSize: mapImage.size)
                                   Text(region.id)
                                       .font(.caption)
                                       .foregroundColor(.white)
                                       .padding(4)
                                       .background(color.opacity(0.8))
                                       .cornerRadius(4)
                                       .position(
                                           x: centerPoint.x * scale * imageScale + offset.width,
                                           y: centerPoint.y * scale * imageScale + offset.height
                                       )
                               }
                           }
                       } else {
                           Text("Blank map image not found")
                               .foregroundColor(.red)
                       }
                   }
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
               }
               .onAppear {
                   squallywoodRegions = loadSquallywoodRegionsFromJSON()
               }
           }
           
           func calculateScale(viewSize: CGSize, imageSize: CGSize) -> CGFloat {
               min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
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
