import SwiftUI

struct SquallywoodRegionEditorView: View {
    @State private var squallywoodRegions: [SquallywoodRegion] = []
    @State private var regionCounter = 1
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // States for drawing
    @State private var currentPoints: [CGPoint] = []
    @State private var isDrawing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let mapImage = UIImage(named: "OfficialBlank") {
                    // Background Map
                    Image(uiImage: mapImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        if !isDrawing {  // Only allow zooming when not drawing
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale = min(max(scale * delta, 1), 4)
                                        }
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if !isDrawing {  // Only allow panning when not drawing
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
                                    }
                                    .onEnded { _ in
                                        lastOffset = .zero
                                    }
                            )
                        )
                        .overlay(
                            GeometryReader { overlayGeometry in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture { location in
                                        if isDrawing {
                                            let imageScale = calculateScale(viewSize: geometry.size, imageSize: mapImage.size)
                                            let tapPoint = CGPoint(
                                                x: (location.x - offset.width) / (scale * imageScale),
                                                y: (location.y - offset.height) / (scale * imageScale)
                                            )
                                            currentPoints.append(tapPoint)
                                        }
                                    }
                            }
                        )
                    
                    // Draw existing regions
                    ForEach(squallywoodRegions) { region in
                        let imageScale = calculateScale(viewSize: geometry.size, imageSize: mapImage.size)
                        Path { path in
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
                        .stroke(Color.red, lineWidth: 2)
                        
                        // Region label
                        if let centerPoint = calculateRegionCenter(points: region.points) {
                            Text(region.id)
                                .font(.caption)
                                .foregroundColor(.red)
                                .position(
                                    x: centerPoint.x * scale * imageScale + offset.width,
                                    y: centerPoint.y * scale * imageScale + offset.height - 20
                                )
                        }
                    }
                    
                    // Draw current region being created
                    if !currentPoints.isEmpty {
                        let imageScale = calculateScale(viewSize: geometry.size, imageSize: mapImage.size)
                        Path { path in
                            let scaledFirstPoint = CGPoint(
                                x: currentPoints[0].x * scale * imageScale + offset.width,
                                y: currentPoints[0].y * scale * imageScale + offset.height
                            )
                            path.move(to: scaledFirstPoint)
                            
                            for point in currentPoints.dropFirst() {
                                let scaledPoint = CGPoint(
                                    x: point.x * scale * imageScale + offset.width,
                                    y: point.y * scale * imageScale + offset.height
                                )
                                path.addLine(to: scaledPoint)
                            }
                            if currentPoints.count > 2 {
                                path.addLine(to: scaledFirstPoint)
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }
                    
                } else {
                    Text("Blank map image not found")
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            squallywoodRegions = loadSquallywoodRegionsFromJSON()
            regionCounter = squallywoodRegions.count + 1
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(isDrawing ? "Finish Region" : "Start Drawing") {
                    if isDrawing {
                        if currentPoints.count >= 3 {
                            let newRegion = SquallywoodRegion(
                                id: "region_\(regionCounter)",
                                points: currentPoints
                            )
                            squallywoodRegions.append(newRegion)
                            regionCounter += 1
                        }
                        currentPoints = []
                        isDrawing = false
                    } else {
                        isDrawing = true
                        currentPoints = []
                    }
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button("Undo Point") {
                    if !currentPoints.isEmpty {
                        currentPoints.removeLast()
                    }
                }
                .disabled(!isDrawing || currentPoints.isEmpty)
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button("💾 Save") {
                    saveSquallywoodRegionsToJSON(squallywoodRegions)
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button("🗑 Clear All") {
                    squallywoodRegions = []
                    currentPoints = []
                    isDrawing = false
                    regionCounter = 1
                }
            }
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
    SquallywoodRegionEditorView()
} 