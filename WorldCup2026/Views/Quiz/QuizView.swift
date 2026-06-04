
import SwiftUI

struct QuizView: View {
    @State private var currentScore: Int = 0
    @AppStorage("quizHighScore") private var highScore: Int = 0
    
    // Game State
    @State private var questions: [QuizQuestion] = []
    @State private var currentQuestionIndex: Int = 0
    @State private var isGameOver: Bool = false
    @State private var selectedOptionIndex: Int?
    @State private var showResult: Bool = false // To show green/red before moving on
    @State private var gameStarted: Bool = false
    
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geometry in
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
                
                if !gameStarted {
                    VStack(spacing: 30) {
                        Image(systemName: "trophy")
                            .font(.system(size: 80))
                            .foregroundStyle(.yellow)
                            .shadow(radius: 5)
                        
                        Text("Road to the Final Trivia")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: .green.opacity(0.5), radius: 10)
                        
                        VStack(spacing: 10) {
                            Text(LocalizedStringKey("Test your knowledge!"))
                                .foregroundStyle(.white.opacity(0.9))
                            Text(LocalizedStringKey("High Score: \(highScore)"))
                                .font(.headline)
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                        }
                        
                        Button {
                            startGame()
                        } label: {
                            Text(LocalizedStringKey("Start Quiz"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.3))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.green.opacity(0.8), lineWidth: 1.5))
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.black.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                } else if isGameOver {
                    VStack(spacing: 30) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.red)
                        
                        Text(LocalizedStringKey("Game Over!"))
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(.white)
                        
                        VStack(spacing: 12) {
                            Text(LocalizedStringKey("Final Score"))
                                .font(.headline)
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                            Text("\(currentScore)")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        
                        Button {
                            startGame()
                        } label: {
                            Text(LocalizedStringKey("Try Again"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.3))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.green.opacity(0.8), lineWidth: 1.5))
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.black.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                } else if let question = currentQuestion {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Text(LocalizedStringKey("Score: \(currentScore)"))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.4))
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            Text("Q: \(currentQuestionIndex + 1)")
                                .font(.subheadline)
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                        }
                        .padding(.horizontal)
                        
                        // Question Card
                        Text(LocalizedStringKey(question.text))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5))
                            .shadow(color: .black.opacity(0.5), radius: 10)
                            .padding(.horizontal)
                        
                        // Options
                        VStack(spacing: 16) {
                            ForEach(0..<question.options.count, id: \.self) { index in
                                Button {
                                    handleAnswer(index)
                                } label: {
                                    HStack {
                                        Text(LocalizedStringKey(question.options[index]))
                                            .fontWeight(.medium)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        
                                        if showResult {
                                            if index == question.correctOptionIndex {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                            } else if index == selectedOptionIndex {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.red)
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        getResultColor(for: index, correctIndex: question.correctOptionIndex)
                                    )
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                .disabled(showResult) // Prevent double tapping
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(gameStarted && !isGameOver ? LocalizedStringKey("Quiz") : "")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func handleAnswer(_ selectedIndex: Int) {
        // Prevent re-selection
        guard selectedOptionIndex == nil else { return }
        
        let question = questions[currentQuestionIndex]
        selectedOptionIndex = selectedIndex
        showResult = true
        
        if selectedIndex == question.correctOptionIndex {
            // Correct
            currentScore += 1
            if currentScore > highScore {
                highScore = currentScore
            }
            
            // Wait then move to next
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    // Check if game over (win) or continue
                    if currentQuestionIndex < questions.count - 1 {
                        currentQuestionIndex += 1
                        selectedOptionIndex = nil
                        showResult = false
                    } else {
                        isGameOver = true
                    }
                }
            }
        } else {
            // Wrong
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    isGameOver = true
                }
            }
        }
    }
    
    func startGame() {
        questions = QuizData.questions.shuffled() // Shuffle full deck
        currentQuestionIndex = 0
        currentScore = 0
        isGameOver = false
        showResult = false
        selectedOptionIndex = nil
        withAnimation {
            gameStarted = true
        }
    }
    
    func getResultColor(for index: Int, correctIndex: Int) -> Color {
        guard showResult else { return Color.black.opacity(0.6) }
        
        if index == correctIndex {
            return Color.green.opacity(0.4)
        } else if index == selectedOptionIndex {
            return Color.red.opacity(0.4)
        }
        
        return Color.black.opacity(0.6)
    }
}
