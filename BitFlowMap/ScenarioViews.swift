import SwiftUI

// MARK: - Scenario List
struct ScenarioListView: View {
    @EnvironmentObject var scenarioStore: ScenarioStore
    @State private var showCreate = false
    @State private var searchText = ""
    @State private var selectedFilter: ScenarioStatus? = nil
    @State private var appeared = false

    var filtered: [Scenario] {
        var list = scenarioStore.scenarios
        if let f = selectedFilter { list = list.filter { $0.status == f } }
        if !searchText.isEmpty { list = list.filter { $0.title.localizedCaseInsensitiveContains(searchText) } }
        return list
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bfmBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Scenarios")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.bfmTextPrimary)
                        Spacer()
                        Button(action: { showCreate = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(LinearGradient.bfmCyanGlow)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Search
                    BFMTextField(placeholder: "Search scenarios...", text: $searchText, icon: "magnifyingglass")
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(label: "All", isSelected: selectedFilter == nil) { selectedFilter = nil }
                            FilterChip(label: "Active", isSelected: selectedFilter == .active) { selectedFilter = .active }
                            FilterChip(label: "Decided", isSelected: selectedFilter == .decided) { selectedFilter = .decided }
                            FilterChip(label: "Archived", isSelected: selectedFilter == .archived) { selectedFilter = .archived }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }

                    if filtered.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.bfmTextTertiary)
                            Text("No scenarios found")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.bfmTextSecondary)
                            Button("Create First Scenario") { showCreate = true }
                                .buttonStyle(BFMPrimaryButton())
                                .frame(maxWidth: 240)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(filtered) { scenario in
                                    NavigationLink(destination: ScenarioDetailView(scenario: scenario)) {
                                        ScenarioRowCard(scenario: scenario)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 20)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            scenarioStore.deleteScenario(id: scenario.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            scenarioStore.archiveScenario(id: scenario.id)
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        .tint(.bfmGold)
                                    }
                                }
                                Spacer().frame(height: 80)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCreate) {
            CreateScenarioView()
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .bfmDeepNavy : .bfmTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AnyView(LinearGradient.bfmCyanGlow) : AnyView(Color.bfmSurface))
                .cornerRadius(10)
        }
    }
}

// MARK: - Create Scenario
struct CreateScenarioView: View {
    @EnvironmentObject var scenarioStore: ScenarioStore
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var description = ""
    @State private var category: ScenarioCategory = .personal
    @State private var tags = ""
    @State private var step = 0
    @State private var variants: [ScenarioVariant] = [
        ScenarioVariant(label: "A", title: "", description: ""),
        ScenarioVariant(label: "B", title: "", description: "")
    ]
    @State private var showError = false
    @State private var errorMsg = ""

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        if step > 0 { step -= 1 } else { presentationMode.wrappedValue.dismiss() }
                    }) {
                        Image(systemName: step == 0 ? "xmark" : "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.bfmTextSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.bfmSurface)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(step == 0 ? "New Scenario" : "Add Variants")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)

                    Spacer()

                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<2, id: \.self) { i in
                            Circle()
                                .fill(i <= step ? Color.bfmCyan : Color.bfmTextTertiary)
                                .frame(width: 7, height: 7)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if showError {
                    Text(errorMsg)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.bfmRed)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                ScrollView(showsIndicators: false) {
                    if step == 0 {
                        // Step 1: Basic Info
                        VStack(spacing: 20) {
                            BFMTextField(placeholder: "Scenario title", text: $title, icon: "text.alignleft")
                            BFMTextField(placeholder: "Description (optional)", text: $description, icon: "doc.text")

                            // Category picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Category")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.bfmTextSecondary)
                                    .padding(.leading, 4)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(ScenarioCategory.allCases, id: \.self) { cat in
                                        Button(action: { withAnimation { category = cat } }) {
                                            VStack(spacing: 6) {
                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(category == cat ? .bfmDeepNavy : cat.color)
                                                Text(cat.displayName)
                                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                    .foregroundColor(category == cat ? .bfmDeepNavy : .bfmTextSecondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                category == cat ?
                                                AnyView(RoundedRectangle(cornerRadius: 12).fill(cat.color)) :
                                                AnyView(RoundedRectangle(cornerRadius: 12).fill(Color.bfmSurface))
                                            )
                                        }
                                    }
                                }
                            }

                            BFMTextField(placeholder: "Tags (comma separated)", text: $tags, icon: "tag")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    } else {
                        // Step 2: Variants
                        VStack(spacing: 16) {
                            ForEach(variants.indices, id: \.self) { i in
                                VariantEditor(variant: $variants[i])
                            }

                            if variants.count < 4 {
                                Button(action: addVariant) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Variant \(["C","D"][variants.count - 2])")
                                    }
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.bfmCyan)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.bfmSurface)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bfmCyan.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }

                    Spacer().frame(height: 100)
                }

                // Bottom button
                Button(step == 0 ? "Continue" : "Create Scenario") {
                    handleNext()
                }
                .buttonStyle(BFMPrimaryButton())
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
        }
    }

    func addVariant() {
        let labels = ["A", "B", "C", "D"]
        variants.append(ScenarioVariant(label: labels[variants.count], title: "", description: ""))
    }

    func handleNext() {
        showError = false
        if step == 0 {
            if title.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMsg = "Please enter a title."
                showError = true
                return
            }
            withAnimation { step = 1 }
        } else {
            let validVariants = variants.filter { !$0.title.isEmpty }
            if validVariants.count < 2 {
                errorMsg = "Please add at least 2 variants."
                showError = true
                return
            }
            var scenario = Scenario(title: title, description: description, category: category)
            scenario.variants = variants.filter { !$0.title.isEmpty }
            scenario.tags = tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            scenarioStore.addScenario(scenario)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct VariantEditor: View {
    @Binding var variant: ScenarioVariant

    var body: some View {
        BFMCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Variant \(variant.label)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.bfmCyan)
                    Spacer()
                }

                BFMTextField(placeholder: "Variant title", text: $variant.title, icon: "square.and.pencil")
                BFMTextField(placeholder: "Description", text: $variant.description, icon: "doc.text")

                // Quick params
                VStack(spacing: 10) {
                    SliderRow(label: "💰 Cost ($)", value: $variant.money, range: 0...100000, format: "$%.0f")
                    SliderRow(label: "⏱ Time (hrs)", value: $variant.time, range: 0...500, format: "%.0fh")
                    SliderRow(label: "🧠 Stress (1-10)", value: $variant.stress, range: 1...10, format: "%.1f")
                    SliderRow(label: "⚠️ Risk (1-10)", value: $variant.risk, range: 1...10, format: "%.1f")
                }
            }
        }
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
                Spacer()
                Text(String(format: format, value))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.bfmCyan)
            }
            Slider(value: $value, in: range)
                .accentColor(.bfmCyan)
        }
    }
}

// MARK: - Scenario Detail
struct ScenarioDetailView: View {
    @EnvironmentObject var scenarioStore: ScenarioStore
    let scenario: Scenario
    @State private var localScenario: Scenario
    @State private var showEdit = false
    @State private var showBranchMap = false
    @State private var showAddNote = false
    @State private var showImpact = false
    @State private var noteText = ""
    @State private var selectedTab = 0

    init(scenario: Scenario) {
        self.scenario = scenario
        _localScenario = State(initialValue: scenario)
    }

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Info
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Category badge + title
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TagChip(text: localScenario.category.displayName, color: localScenario.category.color)
                                TagChip(text: localScenario.status.displayName, color: localScenario.status.color)
                                Spacer()
                            }
                            Text(localScenario.title)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.bfmTextPrimary)
                            if !localScenario.description.isEmpty {
                                Text(localScenario.description)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.bfmTextSecondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Action buttons
                        HStack(spacing: 12) {
                            ActionButton(icon: "map.fill", label: "Branch Map", color: .bfmCyan) { showBranchMap = true }
                            ActionButton(icon: "chart.bar.fill", label: "Impact", color: .bfmPurpleLight) { showImpact = true }
                            ActionButton(icon: "square.and.pencil", label: "Edit", color: .bfmGold) { showEdit = true }
                        }
                        .padding(.horizontal, 20)

                        // Variants
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Variants", count: localScenario.variants.count)
                                .padding(.horizontal, 20)

                            ForEach(localScenario.variants) { variant in
                                VariantCard(
                                    variant: variant,
                                    isBest: variant.id == localScenario.bestVariantId,
                                    weights: localScenario.parameterWeights,
                                    onSelect: {
                                        scenarioStore.markDecided(scenarioId: localScenario.id, variantId: variant.id)
                                        if let updated = scenarioStore.scenarios.first(where: { $0.id == localScenario.id }) {
                                            localScenario = updated
                                        }
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }

                        // Notes section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SectionHeader(title: "Notes", count: localScenario.notes.count)
                                Spacer()
                                Button(action: { showAddNote = true }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.bfmCyan)
                                }
                            }
                            .padding(.horizontal, 20)

                            if localScenario.notes.isEmpty {
                                Text("No notes yet. Tap + to add one.")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.bfmTextTertiary)
                                    .padding(.horizontal, 20)
                            } else {
                                ForEach(localScenario.notes) { note in
                                    NoteCard(note: note)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle(localScenario.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBranchMap) {
            BranchMapView(scenario: localScenario)
        }
        .sheet(isPresented: $showImpact) {
            ImpactCalculatorView(scenario: $localScenario)
        }
        .sheet(isPresented: $showEdit) {
            EditScenarioView(scenario: $localScenario)
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(noteText: $noteText, onSave: saveNote)
        }
        .onAppear {
            if let updated = scenarioStore.scenarios.first(where: { $0.id == scenario.id }) {
                localScenario = updated
            }
        }
    }

    func saveNote() {
        guard !noteText.isEmpty else { return }
        let note = ScenarioNote(text: noteText)
        localScenario.notes.insert(note, at: 0)
        scenarioStore.updateScenario(localScenario)
        noteText = ""
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.1))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}

struct VariantCard: View {
    let variant: ScenarioVariant
    let isBest: Bool
    let weights: ParameterWeights
    let onSelect: () -> Void
    @State private var expanded = false

    var score: Int { Int(variant.totalScore(weights: weights)) }

    var body: some View {
        BFMCard(padding: 16, cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(variant.label)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.bfmCyan)
                        .frame(width: 32, height: 32)
                        .background(Color.bfmCyan.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(variant.title.isEmpty ? "Variant \(variant.label)" : variant.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.bfmTextPrimary)
                        if !variant.description.isEmpty {
                            Text(variant.description)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.bfmTextSecondary)
                                .lineLimit(expanded ? nil : 1)
                        }
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        ScoreBadge(score: score)
                        if isBest {
                            Text("BEST")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundColor(.bfmGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.bfmGreen.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }

                // Metrics
                HStack(spacing: 8) {
                    MetricPill(icon: "dollarsign", value: "$\(Int(variant.money))", color: .bfmGold)
                    MetricPill(icon: "clock", value: "\(Int(variant.time))h", color: .bfmCyan)
                    MetricPill(icon: "brain", value: "\(Int(variant.stress))/10", color: .bfmPurpleLight)
                    MetricPill(icon: "exclamationmark.triangle", value: "\(Int(variant.risk))/10", color: .bfmRed)
                }

                if variant.isSelected {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.bfmGreen)
                        Text("Selected Decision")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.bfmGreen)
                    }
                } else {
                    Button("Select This Variant") {
                        onSelect()
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.bfmCyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.bfmCyan.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bfmCyan.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }
}

struct MetricPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.bfmTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

struct NoteCard: View {
    let note: ScenarioNote

    var body: some View {
        BFMCard(padding: 14, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(note.text)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                Text(note.createdAt, style: .date)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.bfmTextTertiary)
            }
        }
    }
}

struct AddNoteSheet: View {
    @Binding var noteText: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Add Note")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                    .padding(.top, 24)

                TextEditor(text: $noteText)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color.bfmSurface)
                    .cornerRadius(14)
                    .padding(.horizontal, 20)

                Button("Save Note") {
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

// MARK: - Branch Map (WOW Screen)
struct BranchMapView: View {
    let scenario: Scenario
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var appeared = false
    @State private var highlightedVariant: UUID? = nil
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.bfmDeepNavy.ignoresSafeArea()
            GlowCircle(color: .bfmCyan, size: 400, opacity: 0.05)
            GlowCircle(color: .bfmPurple, size: 300, opacity: 0.04).offset(x: 100, y: 100)

            VStack(spacing: 0) {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.bfmTextTertiary)
                    }
                    Spacer()
                    Text("Branch Map")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 18))
                        .foregroundColor(.bfmTextTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                // Map canvas
                GeometryReader { geo in
                    ZStack {
                        // Draw connections
                        ForEach(scenario.variants.indices, id: \.self) { i in
                            BranchConnector(
                                startPoint: CGPoint(x: geo.size.width / 2, y: 100),
                                endPoint: variantPosition(index: i, total: scenario.variants.count, size: geo.size),
                                color: variantColor(index: i),
                                isHighlighted: highlightedVariant == scenario.variants[i].id
                            )
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(Double(i) * 0.15), value: appeared)
                        }

                        // Root node
                        RootNode(title: scenario.title)
                            .position(x: geo.size.width / 2, y: 100)
                            .scaleEffect(appeared ? 1 : 0.3)
                            .opacity(appeared ? 1 : 0)

                        // Variant nodes
                        ForEach(scenario.variants.indices, id: \.self) { i in
                            let variant = scenario.variants[i]
                            let pos = variantPosition(index: i, total: scenario.variants.count, size: geo.size)

                            VariantNode(
                                variant: variant,
                                isBest: variant.id == scenario.bestVariantId,
                                isHighlighted: highlightedVariant == variant.id,
                                color: variantColor(index: i)
                            )
                            .position(pos)
                            .scaleEffect(appeared ? 1 : 0.3)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.12), value: appeared)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    highlightedVariant = highlightedVariant == variant.id ? nil : variant.id
                                }
                            }
                        }

                        // Outcome nodes (if variant highlighted)
                        if let hid = highlightedVariant,
                           let variant = scenario.variants.first(where: { $0.id == hid }),
                           !variant.outcomes.isEmpty {
                            let vIdx = scenario.variants.firstIndex(where: { $0.id == hid }) ?? 0
                            let vPos = variantPosition(index: vIdx, total: scenario.variants.count, size: geo.size)

                            ForEach(variant.outcomes.indices, id: \.self) { oi in
                                let outcome = variant.outcomes[oi]
                                let oPos = outcomePosition(variantPos: vPos, index: oi, total: variant.outcomes.count, size: geo.size)

                                Path { p in
                                    p.move(to: vPos)
                                    p.addLine(to: oPos)
                                }
                                .stroke(outcome.impact.color.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                                OutcomeNode(outcome: outcome)
                                    .position(oPos)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { val in scale = max(0.5, min(2.5, val)) }
                )
                .gesture(
                    DragGesture()
                        .onChanged { val in offset = val.translation }
                )

                // Legend
                HStack(spacing: 16) {
                    ForEach(scenario.variants.indices, id: \.self) { i in
                        let variant = scenario.variants[i]
                        HStack(spacing: 6) {
                            Circle().fill(variantColor(index: i)).frame(width: 8, height: 8)
                            Text("Var \(variant.label)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.bfmTextSecondary)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }

    func variantColor(index: Int) -> Color {
        let colors: [Color] = [.bfmCyan, .bfmPurpleLight, .bfmGold, .bfmGreen]
        return colors[index % colors.count]
    }

    func variantPosition(index: Int, total: Int, size: CGSize) -> CGPoint {
        guard total > 0 else { return .zero }
        let spread = min(size.width * 0.85, CGFloat(total) * 120)
        let step = spread / CGFloat(max(total - 1, 1))
        let x = (size.width - spread) / 2 + CGFloat(index) * step
        return CGPoint(x: x, y: size.height * 0.5)
    }

    func outcomePosition(variantPos: CGPoint, index: Int, total: Int, size: CGSize) -> CGPoint {
        let angle = (Double(index) - Double(total - 1) / 2) * 50.0 * .pi / 180
        let radius: CGFloat = 90
        return CGPoint(
            x: variantPos.x + radius * CGFloat(sin(angle)),
            y: variantPos.y + radius * 1.2
        )
    }
}

struct BranchConnector: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let color: Color
    let isHighlighted: Bool

    var body: some View {
        Path { p in
            p.move(to: startPoint)
            let cp1 = CGPoint(x: startPoint.x, y: startPoint.y + (endPoint.y - startPoint.y) * 0.4)
            let cp2 = CGPoint(x: endPoint.x, y: endPoint.y - (endPoint.y - startPoint.y) * 0.4)
            p.addCurve(to: endPoint, control1: cp1, control2: cp2)
        }
        .stroke(
            color.opacity(isHighlighted ? 0.9 : 0.5),
            style: StrokeStyle(lineWidth: isHighlighted ? 2.5 : 1.5)
        )
        .shadow(color: color.opacity(isHighlighted ? 0.5 : 0), radius: 6)
    }
}

struct RootNode: View {
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient.bfmCyanGlow)
                    .frame(width: 56, height: 56)
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.bfmDeepNavy)
            }
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.bfmTextPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 100)
                .lineLimit(2)
        }
    }
}

struct VariantNode: View {
    let variant: ScenarioVariant
    let isBest: Bool
    let isHighlighted: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(isHighlighted ? 0.3 : 0.15))
                    .frame(width: isHighlighted ? 64 : 52, height: isHighlighted ? 64 : 52)
                    .overlay(Circle().stroke(color, lineWidth: isHighlighted ? 2.5 : 1.5))
                    .shadow(color: color.opacity(isHighlighted ? 0.5 : 0), radius: 8)

                Text(variant.label)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(color)
            }

            Text(variant.title.isEmpty ? "Variant \(variant.label)" : variant.title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.bfmTextPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 90)
                .lineLimit(2)

            if isBest {
                Text("⭐ BEST")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.bfmGold)
            }
        }
    }
}

struct OutcomeNode: View {
    let outcome: VariantOutcome

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: outcome.impact.icon)
                .font(.system(size: 16))
                .foregroundColor(outcome.impact.color)
                .frame(width: 34, height: 34)
                .background(outcome.impact.color.opacity(0.15))
                .clipShape(Circle())

            Text(outcome.title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.bfmTextSecondary)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .lineLimit(2)
        }
    }
}

// MARK: - Edit Scenario
struct EditScenarioView: View {
    @EnvironmentObject var scenarioStore: ScenarioStore
    @Binding var scenario: Scenario
    @Environment(\.presentationMode) var presentationMode
    @State private var localTitle: String = ""
    @State private var localDesc: String = ""
    @State private var localCategory: ScenarioCategory = .personal

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.bfmTextSecondary)
                    Spacer()
                    Text("Edit Scenario")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Spacer()
                    Button("Save") { saveChanges() }
                        .foregroundColor(.bfmCyan)
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 16) {
                        BFMTextField(placeholder: "Title", text: $localTitle, icon: "text.alignleft")
                        BFMTextField(placeholder: "Description", text: $localDesc, icon: "doc.text")

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Category")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.bfmTextSecondary)
                            Picker("Category", selection: $localCategory) {
                                ForEach(ScenarioCategory.allCases, id: \.self) { cat in
                                    Text(cat.displayName).tag(cat)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            localTitle = scenario.title
            localDesc = scenario.description
            localCategory = scenario.category
        }
    }

    func saveChanges() {
        guard !localTitle.isEmpty else { return }
        scenario.title = localTitle
        scenario.description = localDesc
        scenario.category = localCategory
        scenarioStore.updateScenario(scenario)
        presentationMode.wrappedValue.dismiss()
    }
}
