
import SwiftUI
import SwiftData

struct MyTeamView: View {
    @Query(sort: [SortDescriptor(\Team.name)]) private var teams: [Team]
    @AppStorage("myTeamId") private var myTeamId: String = ""
    
    // Find the team efficiently
    private var selectedTeam: Team? {
        teams.first { $0.id == myTeamId }
    }
    
    var body: some View {
        NavigationStack {
            if let team = selectedTeam {
                ZStack(alignment: .topTrailing) {
                    CountryDetailView(team: team)
                    
                    Button {
                        withAnimation {
                            myTeamId = ""
                        }
                    } label: {
                        Text(LocalizedStringKey("Change Team"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.black.opacity(0.6)))
                            .overlay(Capsule().stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                .id(team.id)
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text(LocalizedStringKey("My Team"))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .green.opacity(0.5), radius: 10)
                        
                        Text(LocalizedStringKey("Select your favorite team to follow their journey."))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                            .shadow(color: .black.opacity(0.5), radius: 2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(teams) { team in
                                Button {
                                    withAnimation {
                                        myTeamId = team.id
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        Text(team.emoji)
                                            .font(.system(size: 44))
                                            .shadow(color: .white.opacity(0.3), radius: 5)
                                        Text(LocalizedStringKey(team.name))
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                                            .font(.caption)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.black.opacity(0.6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5)
                                    )
                                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
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
}
