import SwiftUI

struct PhotoReelView: View {
    let regionId: String
    @State private var currentPhotoIndex: Int = 0
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @Environment(\.dismiss) private var dismiss
    
    // Function to get photos for a specific region
    private func getPhotos(for regionId: String) -> [String] {
        var photos: [String] = []
        var index = 1
        
        // Keep checking for images until we don't find one
        while let _ = UIImage(named: "\(regionId)_\(index)") {
            photos.append("\(regionId)_\(index)")
            index += 1
        }
        
        return photos
    }
    
    private func resetZoom() {
        withAnimation {
            currentScale = 1.0
            lastScale = 1.0
            currentOffset = .zero
            lastOffset = .zero
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main photo
                let photos = getPhotos(for: regionId)
                if !photos.isEmpty {
                    Image(photos[currentPhotoIndex])
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(currentScale)
                        .offset(currentOffset)
                        .gesture(
                            // Pinch to zoom
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    currentScale = currentScale * delta
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    // Limit minimum zoom to 1x and maximum to 4x
                                    currentScale = min(max(currentScale, 1), 4)
                                }
                        )
                        .gesture(
                            // Drag when zoomed
                            DragGesture()
                                .onChanged { value in
                                    if currentScale > 1 {
                                        let delta = CGSize(
                                            width: value.translation.width - lastOffset.width,
                                            height: value.translation.height - lastOffset.height
                                        )
                                        lastOffset = value.translation
                                        currentOffset = CGSize(
                                            width: currentOffset.width + delta.width,
                                            height: currentOffset.height + delta.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = .zero
                                }
                        )
                        .onTapGesture(count: 2) {
                            // Double tap to toggle zoom
                            withAnimation {
                                if currentScale > 1 {
                                    resetZoom()
                                } else {
                                    currentScale = 2.0
                                }
                            }
                        }
                        // Updated onChange modifier
                        .onChange(of: currentPhotoIndex) { _, _ in
                            resetZoom()
                        }
                } else {
                    Text("No photos available")
                        .foregroundColor(.gray)
                }
                
                // Navigation buttons in header
                VStack {
                    HStack {
                        // Back button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back to Map")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // Next/Prev buttons
                        if !photos.isEmpty && photos.count > 1 {
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation {
                                        currentPhotoIndex = (currentPhotoIndex - 1 + photos.count) % photos.count
                                    }
                                }) {
                                    Text("Prev")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        currentPhotoIndex = (currentPhotoIndex + 1) % photos.count
                                    }
                                }) {
                                    Text("Next")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
} 
