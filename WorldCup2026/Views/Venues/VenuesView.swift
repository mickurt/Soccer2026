
import SwiftUI
import SwiftData

struct VenuesView: View {
    @Query(sort: \Venue.name) private var venues: [Venue]
    
    var body: some View {
        NavigationStack {
            List(venues) { venue in
                HStack {
                    ZStack {
                        Circle()
                            .fill(.tint.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "sportscourt.fill")
                            .foregroundStyle(.tint)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(venue.name)
                            .font(.headline)
                        Text("\(venue.city), \(venue.country)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Venues")
        }
    }
}
