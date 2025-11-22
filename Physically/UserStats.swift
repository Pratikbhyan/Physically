import Foundation
import SwiftData

@Model
final class UserStats {
    var squatsBanked: Int
    var totalSquats: Int
    var streakDays: Int
    var lastSquatDate: Date?
    
    var bankedMinutes: Double
    var exchangeRateSquats: Int // Squats per 1 minute
    var exchangeRatePushups: Int // Pushups per 1 minute
    var debtMinutes: Double
    var lastDebtDate: Date?
    
    init(squatsBanked: Int = 0, totalSquats: Int = 0, streakDays: Int = 0, lastSquatDate: Date? = nil, bankedMinutes: Double = 0.0, exchangeRateSquats: Int = 10, exchangeRatePushups: Int = 10, debtMinutes: Double = 0.0, lastDebtDate: Date? = nil) {
        self.squatsBanked = squatsBanked
        self.totalSquats = totalSquats
        self.streakDays = streakDays
        self.lastSquatDate = lastSquatDate
        self.bankedMinutes = bankedMinutes
        self.exchangeRateSquats = exchangeRateSquats
        self.exchangeRatePushups = exchangeRatePushups
        self.debtMinutes = debtMinutes
        self.lastDebtDate = lastDebtDate
    }
}
