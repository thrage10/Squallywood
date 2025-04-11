import Foundation
import UIKit

private func getSquallywoodRegionsFileURL() -> URL {
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
    // Load from asset catalog dataset
    if let asset = NSDataAsset(name: "SquallywoodRegions") {
        do {
            let regions = try JSONDecoder().decode([SquallywoodRegion].self, from: asset.data)
            print("✅ Successfully loaded \(regions.count) regions from assets")
            return regions
        } catch let decodingError {
            print("⚠️ Error decoding regions: \(decodingError)")
        }
    } else {
        print("⚠️ Could not find SquallywoodRegions dataset in assets")
    }
    return []
}
