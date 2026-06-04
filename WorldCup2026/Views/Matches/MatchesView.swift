
import SwiftUI
import SwiftData

struct MatchesView: View {
    @Query(sort: \Match.date) private var matches: [Match]
    @State private var showFinishedMatches: Bool = false
    
    // Filtered matches based on segment selection
    var filteredMatches: [Match] {
        matches.filter { match in
            if showFinishedMatches {
                return match.status == .finished
            } else {
                // Show Scheduled and Live matches
                return match.status != .finished
            }
        }
    }

    // Group filtered matches by date
    var groupedMatches: [Date: [Match]] {
        Dictionary(grouping: filteredMatches) { match in
            Calendar.current.startOfDay(for: match.date)
        }
    }
    
    var sortedDates: [Date] {
        groupedMatches.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                VStack(spacing: 4) {
                    Text(LocalizedStringKey("Matches"))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .green.opacity(0.5), radius: 10)
                    Text("Road to the Final")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5)) // Gold-like color
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Custom Segmented Control
                HStack(spacing: 0) {
                    CustomSegmentButton(
                        title: LocalizedStringKey("Upcoming & Live"),
                        showLiveBadge: !showFinishedMatches,
                        isSelected: !showFinishedMatches
                    ) {
                        withAnimation { showFinishedMatches = false }
                    }
                    
                    CustomSegmentButton(
                        title: LocalizedStringKey("Finished"),
                        showLiveBadge: false,
                        isSelected: showFinishedMatches
                    ) {
                        withAnimation { showFinishedMatches = true }
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(red: 0.8, green: 1.0, blue: 0.6).opacity(0.5), lineWidth: 1) // faint green glow outline
                )
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                if matches.isEmpty {
                     ContentUnavailableView(LocalizedStringKey("No Matches"), systemImage: "sportscourt.slash")
                        .environment(\.colorScheme, .dark)
                } else if sortedDates.isEmpty {
                     ContentUnavailableView(
                        showFinishedMatches ? LocalizedStringKey("No Finished Matches") : LocalizedStringKey("No Upcoming Matches"),
                        systemImage: showFinishedMatches ? "clock.arrow.circlepath" : "calendar.badge.clock"
                     )
                     .environment(\.colorScheme, .dark)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(sortedDates, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(date.formatted(.dateTime.weekday(.wide).day().month().year()))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color(red: 0.9, green: 0.9, blue: 0.7)) // Pale golden/yellow
                                        .padding(.horizontal)
                                        .shadow(color: .black, radius: 2)
                                    
                                    ForEach(groupedMatches[date] ?? []) { match in
                                        NavigationLink(destination: MatchDetailView(match: match)) {
                                            MatchCardView(match: match)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
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
}

struct CustomSegmentButton: View {
    let title: LocalizedStringKey
    let showLiveBadge: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                if showLiveBadge {
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.green.opacity(0.3) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.green.opacity(0.8) : Color.clear, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.7))
        }
    }
}
