
import Foundation
import SwiftData

@Model
final class Team: Identifiable {
    var id: String // e.g. "USA"
    var name: String
    var flagAsset: String 
    var emoji: String // e.g. "🇺🇸"
    
    init(id: String, name: String, flagAsset: String = "", emoji: String = "🏳️") {
        self.id = id
        self.name = name
        self.flagAsset = flagAsset
        self.emoji = emoji
    }
}
