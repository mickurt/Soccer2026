
import Foundation

struct QuizQuestion: Identifiable, Codable {
    var id: UUID = UUID()
    let text: String
    let options: [String]
    let correctOptionIndex: Int
    
    var correctAnswer: String {
        return options[correctOptionIndex]
    }
}
