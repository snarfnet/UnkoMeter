import SwiftUI

enum PoopType: String, CaseIterable, Identifiable, Codable {
    case good
    case slightlyHard
    case veryHard
    case diarrhea
    case strangeColor

    var id: String { rawValue }

    init(legacyValue: String) {
        switch legacyValue {
        case "快便":
            self = .good
        case "やや硬い":
            self = .slightlyHard
        case "かなり硬い":
            self = .veryHard
        case "下痢":
            self = .diarrhea
        case "変な色":
            self = .strangeColor
        default:
            self = .good
        }
    }

    var title: String {
        switch self {
        case .good: return "快便"
        case .slightlyHard: return "やや硬い"
        case .veryHard: return "かなり硬い"
        case .diarrhea: return "ゆるい"
        case .strangeColor: return "色が気になる"
        }
    }

    var shortTitle: String {
        switch self {
        case .good: return "快"
        case .slightlyHard: return "硬め"
        case .veryHard: return "硬い"
        case .diarrhea: return "ゆる"
        case .strangeColor: return "色"
        }
    }

    var note: String {
        switch self {
        case .good: return "いい調子"
        case .slightlyHard: return "水分を意識"
        case .veryHard: return "無理しない"
        case .diarrhea: return "食事を確認"
        case .strangeColor: return "続くなら相談"
        }
    }

    var symbol: String {
        switch self {
        case .good: return "leaf.fill"
        case .slightlyHard: return "circle.lefthalf.filled"
        case .veryHard: return "diamond.fill"
        case .diarrhea: return "drop.fill"
        case .strangeColor: return "eyedropper.halffull"
        }
    }

    var tint: Color {
        switch self {
        case .good: return AppPalette.mint
        case .slightlyHard: return AppPalette.sun
        case .veryHard: return AppPalette.orange
        case .diarrhea: return AppPalette.coral
        case .strangeColor: return AppPalette.grape
        }
    }
}

enum AppPalette {
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let paperDeep = Color(red: 0.90, green: 0.85, blue: 0.75)
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.13)
    static let muted = Color(red: 0.42, green: 0.43, blue: 0.39)
    static let mint = Color(red: 0.10, green: 0.62, blue: 0.49)
    static let forest = Color(red: 0.05, green: 0.30, blue: 0.25)
    static let sun = Color(red: 0.93, green: 0.70, blue: 0.20)
    static let orange = Color(red: 0.84, green: 0.43, blue: 0.18)
    static let coral = Color(red: 0.86, green: 0.24, blue: 0.23)
    static let grape = Color(red: 0.45, green: 0.30, blue: 0.62)
    static let clay = Color(red: 0.42, green: 0.27, blue: 0.18)
}

struct ContentView: View {
    @StateObject private var manager = PoopManager()
    @State private var selectedTab = 0
    @State private var showSplash = true

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TimerView(manager: manager)
                    .tabItem { Label("記録", systemImage: "timer") }
                    .tag(0)

                StatsView(manager: manager)
                    .tabItem { Label("ふり返り", systemImage: "chart.bar.xaxis") }
                    .tag(1)
            }
            .tint(AppPalette.mint)
            .safeAreaInset(edge: .bottom) {
                if DeviceCheck.isNativePhone {
                    AdMobBannerView()
                        .frame(width: 320, height: 50)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                        .background(.white.opacity(0.72))
                }
            }

            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
                    .zIndex(10)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}

struct TimerView: View {
    @ObservedObject var manager: PoopManager
    @State private var selectedType: PoopType = .good
    @State private var memo = ""

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HeaderBlock(
                        eyebrow: manager.isRunning ? "MEASURING" : "READY",
                        title: "今日のトイレを記録",
                        subtitle: manager.isRunning ? "終わったら状態を選んで保存しよう。" : "時間、状態、メモ。あとで体調のクセが見えてきます。"
                    )
                    .padding(.top, 18)

                    TimerDial(
                        minutes: manager.minutes,
                        seconds: manager.seconds,
                        totalSeconds: manager.totalSeconds,
                        isRunning: manager.isRunning
                    )

                    ConditionPicker(selectedType: $selectedType)

                    MemoPanel(memo: $memo)

                    ActionButtons(
                        isRunning: manager.isRunning,
                        startAction: { manager.start() },
                        finishAction: {
                            manager.saveRecord(type: selectedType, memo: memo)
                            memo = ""
                            selectedType = .good
                        }
                    )

                    if let latest = manager.lastRecord {
                        LatestRecordCard(record: latest)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }
}

struct StatsView: View {
    @ObservedObject var manager: PoopManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        HeaderBlock(
                            eyebrow: "BODY LOG",
                            title: "今月の調子",
                            subtitle: "記録が増えるほど、食事と体調のつながりが見えます。"
                        )
                        .padding(.top, 18)

                        LazyVGrid(columns: columns, spacing: 12) {
                            MetricCard(title: "総記録", value: "\(manager.totalCount)", unit: "回", symbol: "target", tint: AppPalette.mint)
                            MetricCard(title: "平均時間", value: manager.averageDurationText, unit: "", symbol: "clock.fill", tint: AppPalette.clay)
                            MetricCard(title: "快便率", value: "\(manager.regularityScore)", unit: "%", symbol: "leaf.fill", tint: AppPalette.mint)
                            MetricCard(title: "今月ゆるめ", value: "\(manager.monthlyDiarrheaCount)", unit: "回", symbol: "drop.fill", tint: AppPalette.coral)
                        }

                        ConditionBreakdown(manager: manager)
                        FoodInsightCard(topFood: manager.mostCommonFood)
                        AdviceCard(text: manager.healthAdvice)
                        RecentRecordsSection(manager: manager)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.paper, Color(red: 0.91, green: 0.97, blue: 0.91), AppPalette.paperDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AppPalette.mint.opacity(0.16))
                .frame(width: 260, height: 260)
                .offset(x: 140, y: -260)

            Circle()
                .fill(AppPalette.sun.opacity(0.18))
                .frame(width: 220, height: 220)
                .offset(x: -150, y: 260)
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            AppPalette.forest.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 84, weight: .bold))
                    .foregroundStyle(AppPalette.sun, AppPalette.mint)

                VStack(spacing: 6) {
                    Text("UnkoMeter")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("腸の調子を、軽く残す。")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.76))
                }
            }
        }
    }
}

struct HeaderBlock: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(.caption.weight(.black))
                .foregroundStyle(AppPalette.mint)

            Text(title)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(AppPalette.ink)
                .minimumScaleFactor(0.82)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TimerDial: View {
    let minutes: Int
    let seconds: Int
    let totalSeconds: Int
    let isRunning: Bool

    private var progress: Double {
        min(Double(totalSeconds) / 600.0, 1.0)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.64), lineWidth: 1)
                )
                .shadow(color: AppPalette.ink.opacity(0.10), radius: 24, x: 0, y: 14)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(AppPalette.paperDeep, lineWidth: 16)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AppPalette.mint, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.25), value: progress)

                    VStack(spacing: 4) {
                        Text(String(format: "%02d:%02d", minutes, seconds))
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppPalette.ink)

                        Text(isRunning ? "計測中" : "10分以内を目安に")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isRunning ? AppPalette.mint : AppPalette.muted)
                    }
                }
                .frame(width: 220, height: 220)

                Text("長く続く不調や血便がある場合は、医療機関に相談してください。")
                    .font(.footnote)
                    .foregroundStyle(AppPalette.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }
}

struct ConditionPicker: View {
    @Binding var selectedType: PoopType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "状態", symbol: "slider.horizontal.3")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                ForEach(PoopType.allCases) { type in
                    Button {
                        selectedType = type
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.symbol)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(selectedType == type ? .white : type.tint)

                            Text(type.title)
                                .font(.subheadline.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)

                            Text(type.note)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(selectedType == type ? .white.opacity(0.82) : AppPalette.muted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 104)
                        .padding(.horizontal, 8)
                        .background(selectedType == type ? type.tint : .white.opacity(0.70))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedType == type ? .clear : type.tint.opacity(0.20), lineWidth: 1)
                        )
                        .foregroundStyle(selectedType == type ? .white : AppPalette.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct MemoPanel: View {
    @Binding var memo: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "メモ", symbol: "square.and.pencil")

            ZStack(alignment: .topLeading) {
                if memo.isEmpty {
                    Text("例: ラーメン、寝不足、少しお腹が冷えた")
                        .foregroundStyle(AppPalette.muted.opacity(0.72))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                }

                TextEditor(text: $memo)
                    .frame(minHeight: 104)
                    .font(.body)
                    .padding(12)
                    .background(Color.clear)
            }
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppPalette.mint.opacity(0.18), lineWidth: 1)
            )
        }
    }
}

struct ActionButtons: View {
    let isRunning: Bool
    let startAction: () -> Void
    let finishAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: startAction) {
                Label(isRunning ? "計測し直す" : "開始", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle(color: AppPalette.mint))

            Button(action: finishAction) {
                Label("保存", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle(color: AppPalette.ink))
            .disabled(!isRunning)
            .opacity(isRunning ? 1 : 0.42)
        }
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .background(color.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct LatestRecordCard: View {
    let record: PoopRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "直近の記録", symbol: "clock.arrow.circlepath")
            RecordRow(record: record)
        }
        .panelStyle()
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppPalette.muted)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                        .minimumScaleFactor(0.7)

                    Text(unit)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppPalette.muted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ConditionBreakdown: View {
    @ObservedObject var manager: PoopManager

    private var maxCount: Int {
        max(PoopType.allCases.map { manager.count(for: $0) }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "状態別", symbol: "chart.bar.fill")

            ForEach(PoopType.allCases) { type in
                let count = manager.count(for: type)

                HStack(spacing: 12) {
                    Image(systemName: type.symbol)
                        .foregroundStyle(type.tint)
                        .frame(width: 24)

                    Text(type.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppPalette.ink)
                        .frame(width: 86, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppPalette.paperDeep.opacity(0.8))

                            Capsule()
                                .fill(type.tint)
                                .frame(width: geometry.size.width * CGFloat(count) / CGFloat(maxCount))
                        }
                    }
                    .frame(height: 10)

                    Text("\(count)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppPalette.ink)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .panelStyle()
    }
}

struct FoodInsightCard: View {
    let topFood: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "食べ物メモ", symbol: "fork.knife")

            if let topFood {
                Text("気になる記録によく出る言葉")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppPalette.muted)

                Text(topFood)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(AppPalette.clay)
            } else {
                Text("食べたものをメモすると、あとで体調とのつながりを見やすくなります。")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .panelStyle()
    }
}

struct AdviceCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "ひとこと", symbol: "heart.text.square.fill")

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .panelStyle()
    }
}

struct RecentRecordsSection: View {
    @ObservedObject var manager: PoopManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "最近の記録", symbol: "list.bullet.rectangle")

            if manager.recentRecords.isEmpty {
                Text("まだ記録はありません。")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(manager.recentRecords) { record in
                    RecordRow(record: record)
                }
            }
        }
        .panelStyle()
    }
}

struct RecordRow: View {
    let record: PoopRecord

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.type.symbol)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(record.type.tint)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(record.type.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppPalette.ink)

                    Text(Self.dateFormatter.string(from: record.date))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.muted)
                }

                Text(record.memo.isEmpty ? "メモなし" : record.memo)
                    .font(.caption)
                    .foregroundStyle(AppPalette.muted)
                    .lineLimit(1)
            }

            Spacer()

            Text(PoopManager.formatDuration(record.duration))
                .font(.caption.weight(.black))
                .foregroundStyle(AppPalette.ink)
        }
        .padding(12)
        .background(AppPalette.paper.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SectionTitle: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(AppPalette.mint)

            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(AppPalette.ink)
        }
    }
}

private extension View {
    func panelStyle() -> some View {
        padding(16)
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            )
            .shadow(color: AppPalette.ink.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
