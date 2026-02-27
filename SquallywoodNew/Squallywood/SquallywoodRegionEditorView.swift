import SwiftUI

struct SquallywoodRegionEditorView: View {
    @State private var squallywoodRegions: [SquallywoodRegion] = []  // Will start empty
    @State private var regionCounter = 1
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var currentPoints: [CGPoint] = []
    @State private var isDrawing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let mapImage = UIImage(named: "OfficialBlank") {
                    let imageSize = mapImage.size
                    let aspectRatio = imageSize.width / imageSize.height
                    let containerWidth = geometry.size.width
                    let containerHeight = containerWidth / aspectRatio
                    
                    ZStack {
                        // Background Map
                        Image(uiImage: mapImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: containerWidth, height: containerHeight)
                            .scaleEffect(scale)
                            .offset(offset)
                            .coordinateSpace(name: "MapImageSpace")
                        
                        // Drawing overlay
                        GeometryReader { drawingGeometry in
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onEnded { value in
                                            if isDrawing {
                                                // Get the tap location relative to the image view
                                                let tapLocation = value.location
                                                
                                                // Convert to image coordinates
                                                let imageX = (tapLocation.x - offset.width) / scale
                                                let imageY = (tapLocation.y - offset.height) / scale
                                                
                                                currentPoints.append(CGPoint(x: imageX, y: imageY))
                                            }
                                        }
                                )
                                .coordinateSpace(name: "MapImageSpace")
                        }
                        .frame(width: containerWidth, height: containerHeight)
                        
                        // Container for regions and current drawing
                        ZStack {
                            // Existing regions
                            ForEach(squallywoodRegions) { region in
                                Path { path in
                                    guard let firstPoint = region.points.first else { return }
                                    path.move(to: firstPoint)
                                    
                                    for point in region.points.dropFirst() {
                                        path.addLine(to: point)
                                    }
                                    
                                    if region.points.count > 2 {
                                        path.closeSubpath()
                                    }
                                }
                                .stroke(Color.red, lineWidth: 2)
                            }
                            
                            // Current region being drawn
                            if !currentPoints.isEmpty {
                                Path { path in
                                    path.move(to: currentPoints[0])
                                    
                                    for point in currentPoints.dropFirst() {
                                        path.addLine(to: point)
                                    }
                                    
                                    if currentPoints.count > 2 {
                                        path.closeSubpath()
                                    }
                                }
                                .stroke(Color.blue, lineWidth: 2)
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
                                    if !isDrawing {
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
                                    if !isDrawing {
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
                } else {
                    Text("Blank map image not found")
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            // Reset everything when view appears
            squallywoodRegions = []
            currentPoints = []
            regionCounter = 1
            isDrawing = false
            scale = 1.0
            offset = .zero
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

// Helper shape for drawing regions
struct RegionShape: Shape {
    let points: [CGPoint]
    let imageSize: CGSize
    let containerSize: CGSize
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !points.isEmpty else { return path }
        
        let imageScale = containerSize.width / imageSize.width
        
        let firstPoint = CGPoint(
            x: points[0].x * imageScale,
            y: points[0].y * imageScale
        )
        path.move(to: firstPoint)
        
        for point in points.dropFirst() {
            let scaledPoint = CGPoint(
                x: point.x * imageScale,
                y: point.y * imageScale
            )
            path.addLine(to: scaledPoint)
        }
        
        if points.count > 2 {
            path.closeSubpath()
        }
        
        return path
    }
}

#Preview {
    SquallywoodRegionEditorView()
} 