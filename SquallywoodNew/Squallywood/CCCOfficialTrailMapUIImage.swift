import SwiftUI
import UIKit
import Supabase

struct MapView: View {
    @Binding var userIsLoggedIn: Bool
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Group {
                    if selectedTab == 0 {
                        OfficialTabView(userIsLoggedIn: $userIsLoggedIn)
                    } else if selectedTab == 1 {
                        NavigationMapView()
                    } else {
                        SquallywoodMapView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                HStack(spacing: 0) {
                    tabBarButton(index: 0, icon: "map",                    label: "Official")
                    tabBarButton(index: 1, icon: "location.north.line",    label: "Navigation")
                    tabBarButton(index: 2, icon: "mountain.2",             label: "Squallywood")
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Profile")
        }
    }

    @ViewBuilder
    private func tabBarButton(index: Int, icon: String, label: String) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == index ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}

struct OfficialTabView: View {
    @Binding var userIsLoggedIn: Bool
    @State private var completedTrailsList: [CompletedTrailEntry] = []
    @State private var currentLoggedInUser: User? = nil
    @State private var availableSkiTrails: [String] = []
    @State private var selectedTrailToAdd: String = ""
    @State private var checklistErrorMessage: String? = nil

    let supabaseConnection = SupabaseClient(
        supabaseURL: URL(string: "https://qklbeoadcidyasmuerjv.supabase.co")!,
        supabaseKey: "sb_publishable_3Q8l1ko8VIC5bXOfEoPgew_wHx-wKnj"
    )

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                OfficialTrailMapUIImage(
                    containerSize: CGSize(width: geo.size.width, height: geo.size.height * 0.5)
                )
                .frame(width: geo.size.width, height: geo.size.height * 0.5)
                .clipped()

                Divider()

                if userIsLoggedIn {
                    VStack(spacing: 0) {
                        List {
                            if completedTrailsList.isEmpty {
                                Text("No completed trails yet. Add some!")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(completedTrailsList) { trail in
                                    Text(trail.completedTrailName)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteTrail(trail: trail)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .listStyle(.plain)

                        VStack(spacing: 0) {
                            HStack {
                                Picker("Select Trail", selection: $selectedTrailToAdd) {
                                    Text("Select a trail").tag("")
                                    ForEach(availableSkiTrails, id: \.self) { trail in
                                        Text(trail).tag(trail)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())

                                Button(action: addTrail) {
                                    Image(systemName: "plus")
                                        .padding()
                                }
                                .disabled(selectedTrailToAdd.isEmpty)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                            if let errorMessage = checklistErrorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.bottom, 4)
                            }

                            Button("Log Out") {
                                logout()
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .frame(height: geo.size.height * 0.5 - 1)
                }
            }
        }
        .onAppear {
            checkLoggedInUser()
            fetchAvailableTrails()
        }
    }

    func fetchAvailableTrails() {
        Task {
            do {
                let response = try await supabaseConnection.from("All_Trails")
                    .select("trail_name")
                    .execute()

                struct AvailableTrailResponse: Codable {
                    let trail_name: String
                }

                let trails = try JSONDecoder().decode([AvailableTrailResponse].self, from: response.data)
                await MainActor.run {
                    self.availableSkiTrails = trails.map { $0.trail_name }.sorted()
                }
            } catch {
                print("Error fetching available trails: \(error)")
            }
        }
    }

    func checkLoggedInUser() {
        Task {
            do {
                let user = try await supabaseConnection.auth.user()
                await MainActor.run {
                    self.currentLoggedInUser = user
                    if !self.userIsLoggedIn { self.userIsLoggedIn = true }
                }
                await fetchTrails()
            } catch {
                await MainActor.run {
                    self.currentLoggedInUser = nil
                    self.userIsLoggedIn = false
                    self.completedTrailsList = []
                }
            }
        }
    }

    func logout() {
        Task {
            do {
                try await supabaseConnection.auth.signOut()
                await MainActor.run {
                    self.userIsLoggedIn = false
                    self.currentLoggedInUser = nil
                    self.completedTrailsList = []
                    self.selectedTrailToAdd = ""
                    self.availableSkiTrails = []
                    self.checklistErrorMessage = nil
                }
            } catch {
                print("Error logging out: \(error)")
            }
        }
    }

    func addTrail() {
        Task { await addTrailAsync() }
    }

    func addTrailAsync() async {
        guard let userId = currentLoggedInUser?.id else { return }

        if completedTrailsList.contains(where: { $0.completedTrailId == userId }) {
            await MainActor.run {
                checklistErrorMessage = "This trail is already logged as completed"
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await MainActor.run { checklistErrorMessage = nil }
                }
            }
            return
        }

        let trailData: [String: String] = [
            "trail_name": selectedTrailToAdd,
            "user_id": userId.uuidString
        ]

        do {
            let response = try await supabaseConnection.from("Completed_Trails")
                .insert(trailData)
                .select()
                .single()
                .execute()

            let newTrailResponse = try JSONDecoder().decode(CompletedTrailDatabaseResponse.self, from: response.data)
            await MainActor.run {
                self.completedTrailsList.append(newTrailResponse.toCompletedTrailEntry())
                selectedTrailToAdd = ""
                checklistErrorMessage = nil
            }
        } catch {
            await MainActor.run {
                checklistErrorMessage = "Error adding trail: \(error.localizedDescription)"
            }
        }
    }

    func deleteTrail(trail: CompletedTrailEntry) {
        Task {
            do {
                _ = try await supabaseConnection.from("Completed_Trails")
                    .delete()
                    .eq("id", value: trail.completedTrailId)
                    .execute()
                await MainActor.run {
                    completedTrailsList.removeAll { $0.completedTrailId == trail.completedTrailId }
                }
            } catch {
                await MainActor.run {
                    checklistErrorMessage = "Error deleting trail: \(error.localizedDescription)"
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        await MainActor.run { checklistErrorMessage = nil }
                    }
                }
            }
        }
    }

    func fetchTrails() async {
        guard let userId = currentLoggedInUser?.id else { return }
        do {
            let response = try await supabaseConnection.from("Completed_Trails")
                .select()
                .eq("user_id", value: userId)
                .execute()
            let trailResponses = try JSONDecoder().decode([CompletedTrailDatabaseResponse].self, from: response.data)
            await MainActor.run {
                self.completedTrailsList = trailResponses.map { $0.toCompletedTrailEntry() }
            }
        } catch {
            await MainActor.run { self.completedTrailsList = [] }
        }
    }
}

struct OfficialTrailMapUIImage: View {
    let containerSize: CGSize

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let mapImage = UIImage(named: "OfficialTrailMap")

    private var fittedSize: CGSize {
        guard let img = mapImage, containerSize.width > 0, containerSize.height > 0 else { return .zero }
        let imgAspect = img.size.width / img.size.height
        let csAspect = containerSize.width / containerSize.height
        if imgAspect > csAspect {
            return CGSize(width: containerSize.width, height: containerSize.width / imgAspect)
        } else {
            return CGSize(width: containerSize.height * imgAspect, height: containerSize.height)
        }
    }

    private var displayedSize: CGSize {
        CGSize(width: fittedSize.width * scale, height: fittedSize.height * scale)
    }

    private var maxOffsetX: CGFloat { max(0, (displayedSize.width  - containerSize.width)  / 2) }
    private var maxOffsetY: CGFloat { max(0, (displayedSize.height - containerSize.height) / 2) }

    private func clampOffset(_ o: CGSize) -> CGSize {
        CGSize(
            width:  min(max(o.width,  -maxOffsetX), maxOffsetX),
            height: min(max(o.height, -maxOffsetY), maxOffsetY)
        )
    }

    var body: some View {
        ZStack {
            if let img = mapImage {
                Image(uiImage: img)
                    .resizable()
                    .frame(width: displayedSize.width, height: displayedSize.height)
                    .offset(offset)
                    .allowsHitTesting(false)
            } else {
                Text("Map image not found")
                    .foregroundColor(.red)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .contentShape(Rectangle())
        .gesture(
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = min(max(scale * delta, 1.0), 10.0)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        offset = clampOffset(offset)
                    },
                DragGesture()
                    .onChanged { value in
                        let delta = CGSize(
                            width:  value.translation.width  - lastOffset.width,
                            height: value.translation.height - lastOffset.height
                        )
                        lastOffset = value.translation
                        offset = clampOffset(CGSize(
                            width:  offset.width  + delta.width,
                            height: offset.height + delta.height
                        ))
                    }
                    .onEnded { _ in
                        lastOffset = .zero
                    }
            )
        )
        .onTapGesture(count: 2) {
            withAnimation(.spring()) {
                if scale > 1.5 {
                    scale = 1.0
                    offset = .zero
                } else {
                    scale = 2.5
                }
            }
        }
        .clipped()
    }
}

struct NavigationTrailMapImage: View {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    // Stored so gesture handlers can compute pan constraints outside the GeometryReader closure
    @State private var containerSize: CGSize = .zero

    private let mapImage = UIImage(named: "OfficialTrailMap")

    private var aspectRatio: CGFloat {
        guard let img = mapImage, img.size.height > 0 else { return 1 }
        return img.size.width / img.size.height
    }

    private var displayedWidth:  CGFloat { aspectRatio * containerSize.height * scale }
    private var displayedHeight: CGFloat { containerSize.height * scale }
    private var maxOffsetX: CGFloat { max(0, (displayedWidth  - containerSize.width)  / 2) }
    private var maxOffsetY: CGFloat { max(0, (displayedHeight - containerSize.height) / 2) }

    private func clampOffset(_ o: CGSize) -> CGSize {
        CGSize(
            width:  min(max(o.width,  -maxOffsetX), maxOffsetX),
            height: min(max(o.height, -maxOffsetY), maxOffsetY)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let cs = geometry.size
            let dw = aspectRatio * cs.height * scale
            let dh = cs.height * scale

            if let img = mapImage {
                Image(uiImage: img)
                    .resizable()
                    .frame(width: dw, height: dh)
                    .offset(
                        x: (cs.width - dw) / 2 + offset.width,
                        y: (cs.height - dh) / 2 + offset.height
                    )
                    .allowsHitTesting(false)
            } else {
                Text("Map image not found")
                    .foregroundColor(.red)
                    .allowsHitTesting(false)
            }
        }
        // Reads the container size so gesture handlers can compute maxOffsetX/Y
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { containerSize = proxy.size }
                    .onChange(of: proxy.size) { containerSize = $0 }
            }
            .allowsHitTesting(false)
        )
        // Hard-limits the gesture hit area to the container rectangle so touches above
        // (the From/To picker in NavigationMapView) are never captured by the map gesture.
        .contentShape(Rectangle())
        .gesture(
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = min(max(scale * delta, 1.0), 10.0)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        offset = clampOffset(offset)
                    },
                DragGesture()
                    .onChanged { value in
                        let delta = CGSize(
                            width:  value.translation.width  - lastOffset.width,
                            height: value.translation.height - lastOffset.height
                        )
                        lastOffset = value.translation
                        offset = clampOffset(CGSize(
                            width:  offset.width  + delta.width,
                            height: offset.height + delta.height
                        ))
                    }
                    .onEnded { _ in
                        lastOffset = .zero
                    }
            )
        )
        .onTapGesture(count: 2) {
            withAnimation(.spring()) {
                if scale > 1.5 {
                    scale = 1.0
                    offset = .zero
                } else {
                    scale = 2.5
                }
            }
        }
        .clipped()
    }
}

#Preview {
    MapView(userIsLoggedIn: .constant(true))
}
