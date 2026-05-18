import Foundation
import Combine

struct PoopRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let type: PoopType
    let memo: String
    let duration: Int

    init(id: UUID = UUID(), date: Date = Date(), type: PoopType, memo: String, duration: Int) {
        self.id = id
        self.date = date
        self.type = type
        self.memo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        self.duration = max(0, duration)
    }
}

final class PoopManager: ObservableObject {
    @Published var totalSeconds = 0
    @Published var isRunning = false
    @Published private(set) var records: [PoopRecord] = []

    private var timer: Timer?
    private let recordsKey = "unkoMeter.records.v2"
    private let legacyRecordsKey = "poopRecords"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadRecords()
    }

    deinit {
        timer?.invalidate()
    }

    var minutes: Int {
        totalSeconds / 60
    }

    var seconds: Int {
        totalSeconds % 60
    }

    var lastRecord: PoopRecord? {
        records.first
    }

    var recentRecords: [PoopRecord] {
        Array(records.prefix(8))
    }

    var totalCount: Int {
        records.count
    }

    var monthlyRecords: [PoopRecord] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return []
        }
        return records.filter { $0.date >= monthStart }
    }

    var monthlyGoodCount: Int {
        monthlyRecords.filter { $0.type == .good }.count
    }

    var monthlyDiarrheaCount: Int {
        monthlyRecords.filter { $0.type == .diarrhea }.count
    }

    var averageDuration: Int {
        guard !records.isEmpty else { return 0 }
        return records.reduce(0) { $0 + $1.duration } / records.count
    }

    var averageDurationText: String {
        Self.formatDuration(averageDuration)
    }

    var regularityScore: Int {
        guard !monthlyRecords.isEmpty else { return 0 }
        let goodishCount = monthlyRecords.filter { [.good, .slightlyHard].contains($0.type) }.count
        return Int((Double(goodishCount) / Double(monthlyRecords.count) * 100).rounded())
    }

    var mostCommonFood: String? {
        let foodCounts = records
            .filter { $0.type == .diarrhea || $0.type == .strangeColor }
            .flatMap { Self.extractFoods(from: $0.memo) }
            .reduce(into: [String: Int]()) { counts, food in
                counts[food, default: 0] += 1
            }

        return foodCounts.max { $0.value < $1.value }?.key
    }

    var healthAdvice: String {
        if records.isEmpty {
            return "まずは1回だけ残してみよう。時間、状態、食べたものを少し書くと、あとで原因を見つけやすくなります。"
        }

        if monthlyDiarrheaCount > monthlyGoodCount {
            return "今月はゆるめの記録が多いです。辛いもの、油もの、乳製品、寝不足のどれかが続いていないか見てみよう。"
        }

        if averageDuration >= 600 {
            return "平均時間が少し長めです。無理に粘らず、水分と食物繊維を意識して様子を見よう。"
        }

        if monthlyGoodCount >= 20 {
            return "いい流れです。今の食事、水分、睡眠のリズムを崩さず続けよう。"
        }

        return "大きな乱れはなさそうです。メモを少し足すと、自分の体調パターンがもっと見えます。"
    }

    func start() {
        timer?.invalidate()
        totalSeconds = 0
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.totalSeconds += 1
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func saveRecord(type: PoopType, memo: String) {
        let duration = max(totalSeconds, 1)
        let record = PoopRecord(type: type, memo: memo, duration: duration)
        records.insert(record, at: 0)
        saveRecords()
        stop()
    }

    func deleteRecords(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where records.indices.contains(index) {
            records.remove(at: index)
        }
        saveRecords()
    }

    func count(for type: PoopType) -> Int {
        records.filter { $0.type == type }.count
    }

    static func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60

        if minutes == 0 {
            return "\(seconds)秒"
        }

        return "\(minutes)分\(String(format: "%02d", seconds))秒"
    }

    private func loadRecords() {
        if let data = userDefaults.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([PoopRecord].self, from: data) {
            records = decoded.sorted { $0.date > $1.date }
            return
        }

        if let data = userDefaults.data(forKey: legacyRecordsKey),
           let decoded = try? JSONDecoder().decode([LegacyPoopRecord].self, from: data) {
            records = decoded.map { $0.modernized }.sorted { $0.date > $1.date }
            saveRecords()
        }
    }

    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            userDefaults.set(encoded, forKey: recordsKey)
        }
    }

    private static func extractFoods(from text: String) -> [String] {
        let commonFoods = [
            "ラーメン", "うどん", "そば", "カレー", "ピザ", "ハンバーガー",
            "揚げ物", "唐揚げ", "ポテト", "コーラ", "ビール", "酒",
            "辛い", "スパイス", "油", "バター", "チーズ", "乳製品",
            "肉", "牛乳", "刺身", "魚", "生もの", "コーヒー", "アイス"
        ]

        return commonFoods.filter { text.localizedStandardContains($0) }
    }
}

private struct LegacyPoopRecord: Codable {
    let id: UUID
    let date: Date
    let type: String
    let memo: String
    let duration: Int

    var modernized: PoopRecord {
        PoopRecord(
            id: id,
            date: date,
            type: PoopType(legacyValue: type),
            memo: memo,
            duration: duration
        )
    }
}
