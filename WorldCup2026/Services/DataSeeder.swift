
import Foundation
import SwiftData

@MainActor
class DataSeeder {
    static let shared = DataSeeder()
    
    // Simple types for CSV parsing
    struct ParsedVenue { let id: String; let venue: Venue }
    struct ParsedTeam { let id: String; let team: Team }

    // Structure for lightweight updates
    struct MatchUpdate {
        let status: MatchStatus
        let homeScore: Int
        let awayScore: Int
    } 

    /// Initial seeding: Wipes DB and loads base schedule + local updates
    func seed(context: ModelContext) {
        // Clear existing data only if needed or force re-seed. 
        // For simplicity, we clear to ensure clean state on app launch as per previous logic.
        // In a production app, we might check if 'Match' count is 0.
        
        // Fetch count
        let descriptor = FetchDescriptor<Match>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        if existingCount > 0 {
            // Already seeded, maybe just apply updates?
            // But previous logic was to clear. Let's stick to update logic if data exists to avoid flicker.
            print("Data already exists. Skipping full re-seed.")
            return 
        }

        // Clear existing data (if any partial state)
        do {
            try context.delete(model: Match.self)
            try context.delete(model: Team.self)
            try context.delete(model: Venue.self)
        } catch {
            print("Failed to clear data: \(error)")
        }
        
        var venuesDict: [String: Venue] = [:]
        var teamsDict: [String: Team] = [:]
        
        // --- 1. Load HOST CITIES ---
        if let url = Bundle.main.url(forResource: "host_cities", withExtension: "csv"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            
            let lines = content.components(separatedBy: .newlines)
            // Skip header line
            for i in 1..<lines.count {
                let line = lines[i]
                if line.isEmpty { continue }
                
                let columns = line.components(separatedBy: ",")
                if columns.count >= 4 {
                    let id = columns[0]
                    let venue = Venue(
                        name: columns[3].trimmingCharacters(in: .whitespacesAndNewlines),
                        city: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                        country: columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    context.insert(venue)
                    venuesDict[id] = venue
                }
            }
        }
        
        // --- 2. Load TEAMS ---
        if let url = Bundle.main.url(forResource: "teams", withExtension: "csv"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            
            let lines = content.components(separatedBy: .newlines)
            for i in 1..<lines.count {
                let line = lines[i]
                if line.isEmpty { continue }

                let columns = line.components(separatedBy: ",")
                if columns.count >= 3 {
                    let id = columns[0]
                    let code = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let team = Team(
                        id: code,
                        name: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                        flagAsset: code.lowercased(),
                        emoji: flagEmoji(for: code)
                    )
                    context.insert(team)
                    teamsDict[id] = team
                } 
            }
        }
        
        // --- 3. Load MATCHES (Base Schedule) ---
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ" 
        
        if let url = Bundle.main.url(forResource: "matches", withExtension: "csv"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            
            let lines = content.components(separatedBy: .newlines)
            for i in 1..<lines.count {
                let line = lines[i]
                if line.isEmpty { continue }

                let columns = line.components(separatedBy: ",")
                if columns.count >= 8 {
                    // Base Data
                    let id = columns[0].trimmingCharacters(in: .whitespaces)
                    let homeId = columns[2]
                    let awayId = columns[3]
                    let cityId = columns[4]
                    let dateStr = columns[6]
                    let label = columns[7].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Parse Date
                    var isoDate = dateStr
                    if isoDate.count == 22 { isoDate += "00" } // Fix timezone
                    let date = formatter.date(from: isoDate) ?? Date()
                    
                    if let homeTeam = teamsDict[homeId],
                       let awayTeam = teamsDict[awayId],
                       let venue = venuesDict[cityId] {
                        
                        let match = Match(
                            id: id,
                            date: date,
                            group: label,
                            stage: determineStage(from: label),
                            homeTeam: homeTeam,
                            awayTeam: awayTeam,
                            venue: venue,
                            homeScore: 0,
                            awayScore: 0,
                            status: .scheduled
                        )
                        context.insert(match)
                    }
                }
            }
        }
    }
    
    // MARK: - Live Updates Logic
    
    func startPollingUpdates(context: ModelContext) {
        Task {
            // Initial check
            await poll(context: context)
        }
    }
    
    private func poll(context: ModelContext) async {
        while true {
            let hasLiveMatches = await fetchAndApplyUpdates(context: context)
            
            // If live match exists, check every 1 minute (60s), else every 5 minutes (300s)
            let sleepSeconds: UInt64 = hasLiveMatches ? 60 : 300
            print("Next update check in \(sleepSeconds) seconds...")
            
            try? await Task.sleep(nanoseconds: sleepSeconds * 1_000_000_000)
        }
    }

    /// Fetches updates CSV from GitHub and applies changes to existing matches. Returns true if any match is Live.
    private func fetchAndApplyUpdates(context: ModelContext) async -> Bool {
        let urlString = "https://mickurt.github.io/Soccer2026/matches_update.csv"
        // Add cache busting
        let cacheBuster = "?t=\(Date().timeIntervalSince1970)"
        guard let url = URL(string: urlString + cacheBuster) else { return false }
        
        var hasLive = false
        
        do {
            print("Fetching updates from \(urlString)...")
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    return false
                }
            }
            
            if let content = String(data: data, encoding: .utf8) {
                // Parse updates
                var updatesDict: [String: MatchUpdate] = [:]
                let lines = content.components(separatedBy: .newlines)
                
                print("Downloaded \(lines.count) lines from updates CSV.")
                
                // Expected format: id,status,home_score,away_score
                for line in lines.dropFirst() { 
                    let columns = line.components(separatedBy: ",")
                    if columns.count >= 4 {
                        let id = columns[0].trimmingCharacters(in: .whitespaces)
                        let statusStr = columns[1].trimmingCharacters(in: .whitespaces)
                        let homeScore = Int(columns[2].trimmingCharacters(in: .whitespaces)) ?? 0
                        let awayScore = Int(columns[3].trimmingCharacters(in: .whitespaces)) ?? 0
                        
                        var status: MatchStatus = .scheduled
                        if let s = MatchStatus(rawValue: statusStr) { status = s }
                        else if statusStr.lowercased() == "live" { status = .live }
                        else if statusStr.lowercased() == "finished" { status = .finished }
                        else if statusStr.lowercased() == "scheduled" { status = .scheduled }

                        
                        if status == .live { hasLive = true }
                        
                        updatesDict[id] = MatchUpdate(status: status, homeScore: homeScore, awayScore: awayScore)
                    }
                }
                
                print("Parsed \(updatesDict.count) updates.")
                
                // Apply to DB on MainActor
                await MainActor.run {
                    do {
                        let allMatches = try context.fetch(FetchDescriptor<Match>())
                        var changedCount = 0
                        
                        // Valid list of IDs present in the update
                        let updatedIDs = Set(updatesDict.keys)
                        
                        for match in allMatches {
                            if let update = updatesDict[match.id] {
                                // CASE 1: Match is in the CSV -> Apply CSV values
                                if match.status != update.status || 
                                   match.homeScore != update.homeScore || 
                                   match.awayScore != update.awayScore {
                                    
                                    print("Updating Match \(match.id): \(match.status.rawValue) -> \(update.status.rawValue)")
                                    match.status = update.status
                                    match.homeScore = update.homeScore
                                    match.awayScore = update.awayScore
                                    changedCount += 1
                                }
                            } else {
                                // CASE 2: Match is NOT in the CSV -> Reset to Scheduled/Default
                                // The user requested: "if no line... leave scheduled".
                                // This implies the CSV is the source of truth for "Active" matches.
                                // If a match was Live/Finished but is removed from CSV, it reverts to Scheduled.
                                if match.status != .scheduled || match.homeScore != nil {
                                     print("Reverting Match \(match.id) to Scheduled (not in update file)")
                                     match.status = .scheduled
                                     match.homeScore = nil
                                     match.awayScore = nil
                                     changedCount += 1
                                }
                            }
                        }
                        
                        if changedCount > 0 {
                             try? context.save() 
                             print("Successfully updated/reset \(changedCount) matches.")
                        } else {
                            print("Database is in sync with updates.")
                        }
                    } catch {
                        print("Failed to fetch matches for update: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to download updates: \(error)")
        }
        
        return hasLive
    }
    
    func determineStage(from label: String) -> String {
        if label.contains("Group") { return "Group Stage" }
        if label.contains("32") { return "Round of 32" }
        if label.contains("16") { return "Round of 16" }
        if label.contains("Quarter") { return "Quarterfinals" }
        if label.contains("Semi") { return "Semifinals" }
        if label.contains("Final") { return "Final" }
        return "Knockout"
    }

    func flagEmoji(for code: String) -> String {
        let mappings: [String: String] = [
            "MEX": "🇲🇽", "RSA": "🇿🇦", "KOR": "🇰🇷", "CAN": "🇨🇦",
            "QAT": "🇶🇦", "SUI": "🇨🇭", "BRA": "🇧🇷", "MAR": "🇲🇦",
            "HAI": "🇭🇹", "SCO": "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "USA": "🇺🇸", "PAR": "🇵🇾",
            "AUS": "🇦🇺", "GER": "🇩🇪", "CUR": "🇨🇼", "CIV": "🇨🇮",
            "ECU": "🇪🇨", "NED": "🇳🇱", "JPN": "🇯🇵", "TUN": "🇹🇳",
            "BEL": "🇧🇪", "EGY": "🇪🇬", "IRN": "🇮🇷", "NZL": "🇳🇿",
            "ESP": "🇪🇸", "CPV": "🇨🇻", "KSA": "🇸🇦", "URU": "🇺🇾",
            "FRA": "🇫🇷", "SEN": "🇸🇳", "NOR": "🇳🇴", "ARG": "🇦🇷",
            "ALG": "🇩🇿", "AUT": "🇦🇹", "JOR": "🇯🇴", "POR": "🇵🇹",
            "UZB": "🇺🇿", "COL": "🇨🇴", "ENG": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "CRO": "🇭🇷",
            "GHA": "🇬🇭", "PAN": "🇵🇦"
        ]
        return mappings[code] ?? "🏳️"
    }
}
