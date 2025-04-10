import Foundation

func getSquallywoodRegionsFileURL() -> URL {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    return documentsDirectory.appendingPathComponent("SquallywoodRegions.json")
}

func saveSquallywoodRegionsToJSON(_ regions: [SquallywoodRegion]) {
    let fileURL = getSquallywoodRegionsFileURL()
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(regions)
        try data.write(to: fileURL)
        print("✅ Saved regions to \(fileURL)")
    } catch {
        print("❌ Error saving regions: \(error)")
    }
}

func loadSquallywoodRegionsFromJSON() -> [SquallywoodRegion] {
    guard let bundledRegionsURL = Bundle.main.url(forResource: "SquallywoodRegions", withExtension: "json", subdirectory: "SquallywoodRegions.dataset"),
          let data = try? Data(contentsOf: bundledRegionsURL),
          let regions = try? JSONDecoder().decode([SquallywoodRegion].self, from: data) else {
        print("⚠️ Could not load regions from assets")
        return []
    }
    return regions
}
