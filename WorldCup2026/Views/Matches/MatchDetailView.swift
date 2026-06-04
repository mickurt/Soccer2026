
import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Bindable var match: Match
    
    var isEnglish: Bool {
        Locale.current.identifier.starts(with: "en")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    Text(LocalizedStringKey(match.stage))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                        .textCase(.uppercase)
                    
                    HStack(alignment: .center, spacing: 0) {
                        // Home
                        VStack {
                            Text(match.homeTeam?.emoji ?? "🏳️")
                                .font(.system(size: 70))
                                .shadow(color: .white.opacity(0.3), radius: 5)
                            Text(LocalizedStringKey(match.homeTeam?.name ?? "Home"))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Score/VS
                        VStack(spacing: 8) {
                            if match.status == .scheduled {
                                Text("VS")
                                    .font(.title)
                                    .fontWeight(.black)
                                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.4))
                                    .shadow(color: Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), radius: 5)
                            } else {
                                HStack(spacing: 12) {
                                    Text("\(match.homeScore ?? 0)")
                                    Text("-")
                                        .foregroundStyle(Color.white.opacity(0.7))
                                    Text("\(match.awayScore ?? 0)")
                                }
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .white.opacity(0.5), radius: 4)
                            }
                            
                            StatusBadge(match: match)
                        }
                        .frame(width: 120)
                        
                        // Away
                        VStack {
                            Text(match.awayTeam?.emoji ?? "🏳️")
                                .font(.system(size: 70))
                                .shadow(color: .white.opacity(0.3), radius: 5)
                            Text(LocalizedStringKey(match.awayTeam?.name ?? "Away"))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(24)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.6))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // Info Section
                VStack(alignment: .leading, spacing: 20) {
                    Label {
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey("Date & Time"))
                                .font(.caption)
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                            Text(match.date.formatted(date: .long, time: .shortened))
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.title2)
                    }
                    
                    Divider().background(Color.white.opacity(0.2))
                    
                    Label {
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey("Venue"))
                                .font(.caption)
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                            // Keeping localized string key wrapper for interpolation
                            Text(LocalizedStringKey("\(match.venue?.name ?? "TBD"), \(match.venue?.city ?? "")"))
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                    } icon: {
                        Image(systemName: "sportscourt")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.title2)
                    }
                    
                    Divider().background(Color.white.opacity(0.2))
                    
                    Label {
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey("Group"))
                                .font(.caption)
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                            Text(LocalizedStringKey(match.group ?? match.stage))
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                    } icon: {
                        Image(systemName: "flag.2.crossed")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.title2)
                    }
                }
                .padding(20)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5))
                .padding(.horizontal)
                
                // Score Update Section (Admin/Simulated) - Commented out for production
                /*
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(LocalizedStringKey("Update Score"))
                            .font(.headline)
                        Spacer()
                        if match.status == .live {
                            Label(LocalizedStringKey("Live"), systemImage: "circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    if match.status == .live || match.status == .finished {
                        HStack {
                            VStack {
                                Text(LocalizedStringKey("Home"))
                                    .font(.caption)
                                Stepper("\(match.homeScore ?? 0)", value: Binding(get: { match.homeScore ?? 0 }, set: { match.homeScore = $0 }))
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text(LocalizedStringKey("Away"))
                                    .font(.caption)
                                Stepper("\(match.awayScore ?? 0)", value: Binding(get: { match.awayScore ?? 0 }, set: { match.awayScore = $0 }))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    // External Link Button as requested
                    Button(action: {
                        if let url = URL(string: "https://your-admin-panel.com/match/\(match.id)") {
                           UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "safari")
                            Text(LocalizedStringKey("Open Admin Panel to Update"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Picker(LocalizedStringKey("Match Status"), selection: $match.statusRaw) {
                        ForEach(MatchStatus.allCases, id: \.self) { status in
                            Text(LocalizedStringKey(status.rawValue)).tag(status.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top)
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding(.horizontal)
                */
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Match Details"))
        .navigationBarTitleDisplayMode(.inline)
        .background {
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
        }
    }
}
