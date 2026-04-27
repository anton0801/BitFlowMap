import SwiftUI
import WebKit

struct ImpactCalculatorView: View {
    @EnvironmentObject var scenarioStore: ScenarioStore
    @Binding var scenario: Scenario
    @Environment(\.presentationMode) var presentationMode
    @State private var weights: ParameterWeights
    @State private var appeared = false
    @State private var selectedTab = 0

    init(scenario: Binding<Scenario>) {
        _scenario = scenario
        _weights = State(initialValue: scenario.wrappedValue.parameterWeights)
    }

    var bestVariant: ScenarioVariant? {
        scenario.variants.max(by: { $0.totalScore(weights: weights) < $1.totalScore(weights: weights) })
    }

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.bfmTextTertiary)
                    }
                    Spacer()
                    Text("Impact Calculator")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Spacer()
                    Button("Save") {
                        scenario.parameterWeights = weights
                        scenarioStore.updateScenario(scenario)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.bfmCyan)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Tab selector
                HStack(spacing: 0) {
                    ForEach(["Scores", "Weights"], id: \.self) { tab in
                        Button(tab) {
                            withAnimation { selectedTab = tab == "Scores" ? 0 : 1 }
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedTab == (tab == "Scores" ? 0 : 1) ? .bfmDeepNavy : .bfmTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            selectedTab == (tab == "Scores" ? 0 : 1) ?
                            AnyView(RoundedRectangle(cornerRadius: 10).fill(LinearGradient.bfmCyanGlow)) :
                            AnyView(Color.clear)
                        )
                    }
                }
                .padding(4)
                .background(Color.bfmSurface)
                .cornerRadius(14)
                .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if selectedTab == 0 {
                            // Scores view
                            VStack(spacing: 12) {
                                // Best variant highlight
                                if let best = bestVariant {
                                    BFMCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("🏆 Best Option")
                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                    .foregroundColor(.bfmGold)
                                                Text("Variant \(best.label): \(best.title.isEmpty ? "Unnamed" : best.title)")
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(.bfmTextPrimary)
                                            }
                                            Spacer()
                                            ScoreBadge(score: Int(best.totalScore(weights: weights)))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }

                                // All variant scores
                                ForEach(scenario.variants) { variant in
                                    VariantScoreBar(
                                        variant: variant,
                                        score: Int(variant.totalScore(weights: weights)),
                                        isBest: variant.id == bestVariant?.id,
                                        weights: weights
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        } else {
                            // Weights view
                            BFMCard {
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Parameter Weights")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.bfmTextPrimary)

                                    Text("Set how important each factor is")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(.bfmTextSecondary)

                                    WeightSlider(label: "💰 Money Impact", value: $weights.money, color: .bfmGold)
                                    WeightSlider(label: "⏱ Time Impact", value: $weights.time, color: .bfmCyan)
                                    WeightSlider(label: "🧠 Stress Impact", value: $weights.stress, color: .bfmPurpleLight)
                                    WeightSlider(label: "⚠️ Risk Impact", value: $weights.risk, color: .bfmRed)

                                    // Normalize button
                                    Button("Auto-Balance Weights") {
                                        withAnimation {
                                            weights.normalize()
                                        }
                                    }
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.bfmCyan)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.bfmCyan.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 60)
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = BitFlowParams.cookieBin
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("\(BitFlowParams.trace) Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

struct VariantScoreBar: View {
    let variant: ScenarioVariant
    let score: Int
    let isBest: Bool
    let weights: ParameterWeights
    @State private var animatedScore: CGFloat = 0

    var body: some View {
        BFMCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Variant \(variant.label)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(isBest ? .bfmGold : .bfmTextPrimary)
                    if !variant.title.isEmpty {
                        Text("· \(variant.title)")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                    }
                    Spacer()
                    Text("\(score)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(isBest ? .bfmGold : .bfmCyan)
                }

                // Score bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.bfmSurface)
                            .frame(height: 8)
                        Capsule()
                            .fill(isBest ? LinearGradient.bfmGoldGrad : LinearGradient.bfmCyanGlow)
                            .frame(width: geo.size.width * animatedScore / 100, height: 8)
                    }
                }
                .frame(height: 8)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animatedScore = CGFloat(score)
                    }
                }

                // Individual metrics
                HStack(spacing: 12) {
                    MiniMetric(label: "Money", value: "$\(Int(variant.money))", weight: weights.money)
                    MiniMetric(label: "Time", value: "\(Int(variant.time))h", weight: weights.time)
                    MiniMetric(label: "Stress", value: "\(Int(variant.stress))/10", weight: weights.stress)
                    MiniMetric(label: "Risk", value: "\(Int(variant.risk))/10", weight: weights.risk)
                }
            }
        }
    }
}

struct MiniMetric: View {
    let label: String
    let value: String
    let weight: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.bfmTextPrimary)
            Text("\(label) \(Int(weight * 100))%")
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundColor(.bfmTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeightSlider: View {
    let label: String
    @Binding var value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            Slider(value: $value, in: 0...1, step: 0.05)
                .accentColor(color)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ \(BitFlowParams.trace) Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct CalculatorsView: View {
    @State private var selectedCalc = 0
    let calcTitles = ["Financial", "Time", "Risk", "Custom"]
    let calcIcons = ["dollarsign.circle.fill", "clock.fill", "exclamationmark.triangle.fill", "slider.horizontal.3"]
    let calcColors: [Color] = [.bfmGold, .bfmCyan, .bfmRed, .bfmPurpleLight]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bfmBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Calculators")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 16)

                    // Tab bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { i in
                                Button(action: { withAnimation { selectedCalc = i } }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: calcIcons[i])
                                            .font(.system(size: 14))
                                            .foregroundColor(selectedCalc == i ? .bfmDeepNavy : calcColors[i])
                                        Text(calcTitles[i])
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(selectedCalc == i ? .bfmDeepNavy : .bfmTextSecondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(
                                        selectedCalc == i ?
                                        AnyView(Capsule().fill(calcColors[i])) :
                                        AnyView(Capsule().fill(Color.bfmSurface))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)

                    Group {
                        switch selectedCalc {
                        case 0: FinancialCalculatorView()
                        case 1: TimeCalculatorView()
                        case 2: RiskCalculatorView()
                        default: CustomFormulaView()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}


struct FinancialCalculatorView: View {
    @State private var entries: [FinancialEntry] = []
    @State private var showAdd = false
    @State private var newTitle = ""
    @State private var newAmount = ""
    @State private var newType: EntryType = .expense
    @State private var newCategory = ""
    private let storageKey = "bfm_fin_entries"

    var totalIncome: Double { entries.filter { $0.type == .income }.map { $0.amount }.reduce(0, +) }
    var totalExpense: Double { entries.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +) }
    var balance: Double { totalIncome - totalExpense }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Summary
                HStack(spacing: 12) {
                    SummaryCard(label: "Income", value: totalIncome, color: .bfmGreen)
                    SummaryCard(label: "Expenses", value: totalExpense, color: .bfmRed)
                    SummaryCard(label: "Balance", value: balance, color: balance >= 0 ? .bfmGreen : .bfmRed)
                }
                .padding(.horizontal, 20)

                // Add entry button
                Button(action: { showAdd = true }) {
                    Label("Add Entry", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.bfmCyan)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.bfmSurface)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bfmCyan.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 20)

                if entries.isEmpty {
                    Text("No entries yet. Add income or expenses.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.bfmTextTertiary)
                        .padding()
                } else {
                    ForEach(entries) { entry in
                        FinancialEntryRow(entry: entry, onDelete: { deleteEntry(entry) })
                            .padding(.horizontal, 20)
                    }
                }

                Spacer().frame(height: 80)
            }
            .padding(.top, 16)
        }
        .sheet(isPresented: $showAdd) {
            AddFinancialEntrySheet(
                title: $newTitle, amount: $newAmount,
                type: $newType, category: $newCategory,
                onSave: { addEntry() }
            )
        }
        .onAppear { loadEntries() }
    }

    func addEntry() {
        guard let amt = Double(newAmount), !newTitle.isEmpty else { return }
        let entry = FinancialEntry(title: newTitle, amount: amt, type: newType, category: newCategory)
        entries.insert(entry, at: 0)
        saveEntries()
        newTitle = ""; newAmount = ""; newCategory = ""
    }

    func deleteEntry(_ entry: FinancialEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([FinancialEntry].self, from: data) {
            entries = decoded
        }
    }
}

struct SummaryCard: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        BFMCard(padding: 12, cornerRadius: 14) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
                Text("$\(Int(abs(value)))")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct FinancialEntryRow: View {
    let entry: FinancialEntry
    let onDelete: () -> Void

    var body: some View {
        BFMCard(padding: 14, cornerRadius: 14) {
            HStack {
                Circle()
                    .fill(entry.type == .income ? Color.bfmGreen.opacity(0.2) : Color.bfmRed.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: entry.type == .income ? "arrow.down.left" : "arrow.up.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(entry.type == .income ? .bfmGreen : .bfmRed)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    if !entry.category.isEmpty {
                        Text(entry.category)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.bfmTextTertiary)
                    }
                }

                Spacer()

                Text("\(entry.type == .income ? "+" : "-")$\(Int(entry.amount))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(entry.type == .income ? .bfmGreen : .bfmRed)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.bfmRed.opacity(0.6))
                }
                .padding(.leading, 8)
            }
        }
    }
}

struct AddFinancialEntrySheet: View {
    @Binding var title: String
    @Binding var amount: String
    @Binding var type: EntryType
    @Binding var category: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Add Entry")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                    .padding(.top, 24)

                Picker("Type", selection: $type) {
                    Text("Expense").tag(EntryType.expense)
                    Text("Income").tag(EntryType.income)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                BFMTextField(placeholder: "Title", text: $title, icon: "text.alignleft")
                    .padding(.horizontal, 20)
                BFMTextField(placeholder: "Amount", text: $amount, icon: "dollarsign")
                    .padding(.horizontal, 20)
                    .keyboardType(.decimalPad)
                BFMTextField(placeholder: "Category (optional)", text: $category, icon: "tag")
                    .padding(.horizontal, 20)

                Button("Add Entry") {
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(BFMPrimaryButton())
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

// MARK: - Time Calculator
struct TimeCalculatorView: View {
    @State private var tasks: [TimeEntry] = []
    @State private var newTask = ""
    @State private var newHours = ""
    private let storageKey = "bfm_time_tasks"

    var totalHours: Double { tasks.map { $0.hours }.reduce(0, +) }
    var completedHours: Double { tasks.filter { $0.isCompleted }.map { $0.hours }.reduce(0, +) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Summary
                BFMCard {
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("\(Int(totalHours))h")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.bfmCyan)
                            Text("Total")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.bfmTextSecondary)
                        }
                        Divider().background(Color.bfmTextTertiary)
                        VStack(spacing: 4) {
                            Text("\(Int(completedHours))h")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.bfmGreen)
                            Text("Done")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.bfmTextSecondary)
                        }
                        Divider().background(Color.bfmTextTertiary)
                        VStack(spacing: 4) {
                            Text("\(Int(totalHours - completedHours))h")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.bfmGold)
                            Text("Left")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.bfmTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)

                // Add task
                HStack(spacing: 10) {
                    BFMTextField(placeholder: "Task name", text: $newTask, icon: "checkmark.circle")
                    BFMTextField(placeholder: "Hrs", text: $newHours, icon: "clock")
                        .frame(width: 90)
                        .keyboardType(.decimalPad)
                    Button(action: addTask) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(LinearGradient.bfmCyanGlow)
                    }
                }
                .padding(.horizontal, 20)

                ForEach(tasks) { task in
                    TimeTaskRow(task: task, onToggle: { toggleTask(task) }, onDelete: { deleteTask(task) })
                        .padding(.horizontal, 20)
                }

                Spacer().frame(height: 80)
            }
            .padding(.top, 16)
        }
        .onAppear { loadTasks() }
    }

    func addTask() {
        guard !newTask.isEmpty, let hrs = Double(newHours), hrs > 0 else { return }
        let task = TimeEntry(task: newTask, hours: hrs)
        tasks.insert(task, at: 0)
        saveTasks(); newTask = ""; newHours = ""
    }

    func toggleTask(_ task: TimeEntry) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            saveTasks()
        }
    }

    func deleteTask(_ task: TimeEntry) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TimeEntry].self, from: data) { tasks = decoded }
    }
}

struct TimeTaskRow: View {
    let task: TimeEntry
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        BFMCard(padding: 14, cornerRadius: 14) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(task.isCompleted ? .bfmGreen : .bfmTextTertiary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.task)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(task.isCompleted ? .bfmTextTertiary : .bfmTextPrimary)
                        .strikethrough(task.isCompleted)
                }
                Spacer()
                Text("\(String(format: "%.1f", task.hours))h")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.bfmCyan)
                Button(action: onDelete) {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundColor(.bfmRed.opacity(0.6))
                }
                .padding(.leading, 8)
            }
        }
    }
}

// MARK: - Risk Calculator
struct RiskCalculatorView: View {
    @State private var risks: [RiskEntry] = []
    @State private var showAdd = false
    @State private var newRiskTitle = ""
    @State private var newProbability: Double = 0.5
    @State private var newImpact: Double = 5
    @State private var newMitigation = ""
    private let storageKey = "bfm_risks"

    var overallRisk: Double {
        guard !risks.isEmpty else { return 0 }
        let total = risks.map { $0.probability * $0.impact }.reduce(0, +)
        return total / Double(risks.count)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Overall risk gauge
                BFMCard {
                    VStack(spacing: 10) {
                        Text("Overall Risk Score")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                        Text(String(format: "%.1f", overallRisk))
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(overallRisk > 6 ? .bfmRed : overallRisk > 3 ? .bfmGold : .bfmGreen)
                        Text(overallRisk > 6 ? "High Risk ⚠️" : overallRisk > 3 ? "Medium Risk" : "Low Risk ✅")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(overallRisk > 6 ? .bfmRed : overallRisk > 3 ? .bfmGold : .bfmGreen)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)

                Button(action: { showAdd = true }) {
                    Label("Add Risk Factor", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.bfmRed)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.bfmRed.opacity(0.1))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bfmRed.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 20)

                ForEach(risks) { risk in
                    RiskRow(risk: risk, onDelete: { risks.removeAll { $0.id == risk.id }; saveRisks() })
                        .padding(.horizontal, 20)
                }

                Spacer().frame(height: 80)
            }
            .padding(.top, 16)
        }
        .sheet(isPresented: $showAdd) {
            AddRiskSheet(title: $newRiskTitle, probability: $newProbability, impact: $newImpact, mitigation: $newMitigation, onSave: addRisk)
        }
        .onAppear { loadRisks() }
    }

    func addRisk() {
        guard !newRiskTitle.isEmpty else { return }
        let risk = RiskEntry(title: newRiskTitle, probability: newProbability, impact: newImpact, mitigation: newMitigation)
        risks.insert(risk, at: 0); saveRisks()
        newRiskTitle = ""; newProbability = 0.5; newImpact = 5; newMitigation = ""
    }

    func saveRisks() {
        if let data = try? JSONEncoder().encode(risks) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
    func loadRisks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([RiskEntry].self, from: data) { risks = decoded }
    }
}

struct RiskRow: View {
    let risk: RiskEntry
    let onDelete: () -> Void
    let score: Double
    init(risk: RiskEntry, onDelete: @escaping () -> Void) {
        self.risk = risk; self.onDelete = onDelete
        self.score = risk.probability * risk.impact
    }

    var body: some View {
        BFMCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(risk.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Spacer()
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(score > 6 ? .bfmRed : score > 3 ? .bfmGold : .bfmGreen)
                    Button(action: onDelete) {
                        Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.bfmRed.opacity(0.5))
                    }
                    .padding(.leading, 8)
                }
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Probability")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextTertiary)
                        Text("\(Int(risk.probability * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.bfmCyan)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Impact")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextTertiary)
                        Text("\(Int(risk.impact))/10")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.bfmRed)
                    }
                    if !risk.mitigation.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mitigation")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.bfmTextTertiary)
                            Text(risk.mitigation)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.bfmTextSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

struct AddRiskSheet: View {
    @Binding var title: String
    @Binding var probability: Double
    @Binding var impact: Double
    @Binding var mitigation: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Add Risk Factor")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                    .padding(.top, 24)

                BFMTextField(placeholder: "Risk description", text: $title, icon: "exclamationmark.triangle")
                    .padding(.horizontal, 20)
                BFMTextField(placeholder: "Mitigation strategy", text: $mitigation, icon: "shield.fill")
                    .padding(.horizontal, 20)

                VStack(spacing: 16) {
                    SliderRow(label: "Probability", value: $probability, range: 0...1, format: "%.0f%%")
                    SliderRow(label: "Impact (1-10)", value: $impact, range: 1...10, format: "%.1f")
                }
                .padding(.horizontal, 20)

                Button("Add Risk") { onSave(); presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(BFMPrimaryButton())
                    .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

// MARK: - Custom Formula
struct CustomFormulaView: View {
    @State private var formulas: [CustomFormula] = []
    @State private var showAdd = false
    @State private var newFormulaName = ""
    @State private var varName1 = ""; @State private var varVal1 = ""
    @State private var varName2 = ""; @State private var varVal2 = ""
    @State private var varName3 = ""; @State private var varVal3 = ""
    @State private var operation: String = "+"
    private let storageKey = "bfm_formulas"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                BFMCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom Formula Builder")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.bfmTextPrimary)
                        Text("Create your own calculation formulas to evaluate any scenario dimension.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                    }
                }
                .padding(.horizontal, 20)

                Button(action: { showAdd = true }) {
                    Label("New Formula", systemImage: "function")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.bfmPurpleLight)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.bfmPurpleLight.opacity(0.1))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bfmPurpleLight.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 20)

                ForEach(formulas) { formula in
                    FormulaResultCard(formula: formula, onDelete: {
                        formulas.removeAll { $0.id == formula.id }; saveFormulas()
                    })
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 80)
            }
            .padding(.top, 16)
        }
        .sheet(isPresented: $showAdd) {
            AddFormulaSheet(
                name: $newFormulaName,
                varName1: $varName1, varVal1: $varVal1,
                varName2: $varName2, varVal2: $varVal2,
                varName3: $varName3, varVal3: $varVal3,
                operation: $operation,
                onSave: buildFormula
            )
        }
        .onAppear { loadFormulas() }
    }

    func buildFormula() {
        guard !newFormulaName.isEmpty else { return }
        var vars: [FormulaVariable] = []
        if !varName1.isEmpty, let v = Double(varVal1) { vars.append(FormulaVariable(name: varName1, value: v)) }
        if !varName2.isEmpty, let v = Double(varVal2) { vars.append(FormulaVariable(name: varName2, value: v)) }
        if !varName3.isEmpty, let v = Double(varVal3) { vars.append(FormulaVariable(name: varName3, value: v)) }
        let values = vars.map { $0.value }
        var result: Double = values.first ?? 0
        for i in 1..<values.count {
            switch operation {
            case "+": result += values[i]
            case "-": result -= values[i]
            case "*": result *= values[i]
            case "/": result = values[i] != 0 ? result / values[i] : 0
            default: result += values[i]
            }
        }
        let formula = CustomFormula(name: newFormulaName, variables: vars, formula: vars.map { $0.name }.joined(separator: " \(operation) "), result: result)
        formulas.insert(formula, at: 0); saveFormulas()
        newFormulaName = ""; varName1 = ""; varVal1 = ""; varName2 = ""; varVal2 = ""; varName3 = ""; varVal3 = ""
    }

    func saveFormulas() {
        if let data = try? JSONEncoder().encode(formulas) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
    func loadFormulas() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CustomFormula].self, from: data) { formulas = decoded }
    }
}

struct FormulaResultCard: View {
    let formula: CustomFormula
    let onDelete: () -> Void

    var body: some View {
        BFMCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(formula.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Spacer()
                    Text(String(format: "= %.2f", formula.result))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.bfmPurpleLight)
                    Button(action: onDelete) {
                        Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.bfmRed.opacity(0.5))
                    }
                    .padding(.leading, 6)
                }
                Text(formula.formula)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.bfmTextSecondary)
                HStack(spacing: 12) {
                    ForEach(formula.variables) { v in
                        Text("\(v.name)=\(String(format: "%.1f", v.value))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextTertiary)
                    }
                }
            }
        }
    }
}

struct AddFormulaSheet: View {
    @Binding var name: String
    @Binding var varName1: String; @Binding var varVal1: String
    @Binding var varName2: String; @Binding var varVal2: String
    @Binding var varName3: String; @Binding var varVal3: String
    @Binding var operation: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode

    let ops = ["+", "-", "*", "/"]

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Build Formula")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                        .padding(.top, 24)

                    BFMTextField(placeholder: "Formula name", text: $name, icon: "function")
                        .padding(.horizontal, 20)

                    // Operation
                    HStack(spacing: 12) {
                        ForEach(ops, id: \.self) { op in
                            Button(op) { operation = op }
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(operation == op ? .bfmDeepNavy : .bfmTextSecondary)
                                .frame(width: 44, height: 44)
                                .background(operation == op ? Color.bfmCyan : Color.bfmSurface)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Variable inputs
                    ForEach([
                        ($varName1, $varVal1, "A"),
                        ($varName2, $varVal2, "B"),
                        ($varName3, $varVal3, "C")
                    ], id: \.2) { nameB, valB, label in
                        HStack(spacing: 10) {
                            Text(label)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.bfmCyan)
                                .frame(width: 24)
                            BFMTextField(placeholder: "Variable name", text: nameB, icon: "x.square")
                            BFMTextField(placeholder: "Value", text: valB, icon: "number")
                                .frame(width: 90)
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal, 20)
                    }

                    Button("Calculate") { onSave(); presentationMode.wrappedValue.dismiss() }
                        .buttonStyle(BFMPrimaryButton())
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
        }
    }
}
