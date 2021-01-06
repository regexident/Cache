import Foundation

class DateProvider {
    var date: Date

    init(date: Date = .init()) {
        self.date = date
    }

    func travel(by timeInterval: TimeInterval) {
        self.date = date.addingTimeInterval(timeInterval)
    }

    func generateDate() -> Date {
        return self.date
    }
}
