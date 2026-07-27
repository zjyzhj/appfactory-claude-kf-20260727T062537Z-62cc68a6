import SwiftUI

// MARK: - tab_criteria

/// tab_criteria route: criteria list (built-in + custom) with enable/disable,
/// plus WeightProfile rows → weight_editor. Editing WeightProfile draft is held
/// in LocalStore so it survives tab switches (ACC-NAV).
struct CriteriaHomeView: View {
    @EnvironmentObject private var store: LocalStore
    @State private var showingNewCriterion = false
    @State private var editingNewProfile = false
    @State private var toast: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    criteriaSection
                    profilesSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .paperBackground()
            .navigationTitle("Criteria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewCriterion = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.accentBrass)
                    }
                    .accessibilityLabel("Add criterion")
                }
            }
            .sheet(isPresented: $showingNewCriterion) {
                CriterionEditSheet { created in
                    if created != nil {
                        toast = "Criterion added — it now appears in walkthroughs and compare."
                    } else {
                        toast = "A criterion with that name already exists."
                    }
                }
            }
            .navigationDestination(for: UUID.self) { profileId in
                WeightEditorView(profileId: profileId)
            }
            .navigationDestination(isPresented: $editingNewProfile) {
                WeightEditorView(profileId: nil)
            }
            .overlay(alignment: .bottom) { ToastView(text: $toast) }
        }
    }

    private var criteriaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scoring criteria")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            Text("Disabled criteria leave walkthroughs and compare. Built-in criteria can't be deleted.")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkTertiary)
            ForEach(store.criteria.sorted(by: { $0.sortOrder < $1.sortOrder })) { criterion in
                HStack(spacing: 12) {
                    Image(systemName: criterion.sfSymbol)
                        .font(.system(size: 17))
                        .foregroundStyle(criterion.isEnabled ? Theme.accentBrass : Theme.inkTertiary)
                        .frame(width: 26)
                        .accessibilityLabel("\(criterion.name) icon")
                    Text(criterion.name)
                        .font(Theme.body().weight(.medium))
                        .foregroundStyle(criterion.isEnabled ? Theme.inkPrimary : Theme.inkTertiary)
                    if criterion.isBuiltIn {
                        Text("Built-in")
                            .font(Theme.caption().weight(.semibold))
                            .foregroundStyle(Theme.inkTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.scoreTrack.opacity(0.5))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Toggle("Enabled", isOn: Binding(
                        get: { criterion.isEnabled },
                        set: { store.setCriterionEnabled(criterion.id, enabled: $0) }))
                        .labelsHidden()
                        .tint(Theme.accentSage)
                        .accessibilityLabel("\(criterion.name) enabled")
                    if !criterion.isBuiltIn {
                        Button(role: .destructive) {
                            _ = store.deleteCriterion(id: criterion.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Theme.warnTerracotta)
                        }
                        .accessibilityLabel("Delete \(criterion.name)")
                    }
                }
                .padding(12)
                .panelCard()
            }
        }
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weight profiles")
                    .font(Theme.sectionTitle())
                    .foregroundStyle(Theme.inkPrimary)
                Spacer()
                Button {
                    let draft = WeightEditorDraft(profileId: nil, name: "",
                                                  weights: defaultDraftWeights())
                    store.weightEditorDraft = draft
                    editingNewProfile = true
                } label: {
                    Label("New", systemImage: "plus")
                        .font(Theme.caption().weight(.semibold))
                        .foregroundStyle(Theme.accentBrass)
                }
                .accessibilityLabel("New weight profile")
            }
            ForEach(store.weightProfiles) { profile in
                NavigationLink(value: profile.id) {
                    HStack(spacing: 12) {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(Theme.accentBrass)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name)
                                .font(Theme.body().weight(.medium))
                                .foregroundStyle(Theme.inkPrimary)
                            Text("Σ \(profile.total)% · \(profile.weights.count) criteria")
                                .font(Theme.caption())
                                .foregroundStyle(Theme.inkTertiary)
                        }
                        Spacer()
                        if profile.isActive {
                            Text("Active")
                                .font(Theme.caption().weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Theme.accentSage)
                                .clipShape(Capsule())
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                    .padding(12)
                    .panelCard()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(profile.name) weight profile\(profile.isActive ? ", active" : "")")
            }
        }
    }

    private func defaultDraftWeights() -> [UUID: Int] {
        let enabled = store.enabledCriteria
        let base = 100 / max(enabled.count, 1)
        var weights: [UUID: Int] = [:]
        var remainder = 100 - base * enabled.count
        for criterion in enabled {
            weights[criterion.id] = base + (remainder > 0 ? 1 : 0)
            if remainder > 0 { remainder -= 1 }
        }
        return weights
    }
}

// MARK: - criterion_edit sheet

struct CriterionEditSheet: View {
    @EnvironmentObject private var store: LocalStore
    @Environment(\.dismiss) private var dismiss
    var onSaved: (Criterion?) -> Void

    @State private var name: String = ""
    @State private var selectedSymbol: String = "star.fill"
    @FocusState private var nameFocused: Bool

    /// Domain icon palette for custom criteria (criterion_icons slot mapping).
    private let symbolChoices = [
        "star.fill", "bolt.fill", "drop.fill", "wind", "leaf.fill",
        "car.fill", "bus.fill", "bicycle", "figure.walk", "wifi",
        "tv.fill", "washer.fill", "oven.fill", "refrigerator.fill", "bed.double.fill",
        "door.left.hand.open", "lightbulb.fill", "speaker.wave.2.fill", "lock.fill", "eye.fill",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Criterion name")
                            .font(Theme.caption().weight(.semibold))
                            .foregroundStyle(Theme.inkSecondary)
                        TextField("e.g. Water Pressure", text: $name)
                            .font(Theme.body())
                            .foregroundStyle(Theme.inkPrimary)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .onSubmit { nameFocused = false }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(Theme.bgPanel)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Icon")
                            .font(Theme.caption().weight(.semibold))
                            .foregroundStyle(Theme.inkSecondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(symbolChoices, id: \.self) { symbol in
                                Button { selectedSymbol = symbol } label: {
                                    Image(systemName: symbol)
                                        .font(.system(size: 18))
                                        .foregroundStyle(selectedSymbol == symbol ? .white : Theme.accentBrass)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedSymbol == symbol ? Theme.accentBrass : Theme.bgPanel)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .accessibilityLabel("Icon \(symbol)")
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .paperBackground()
            .navigationTitle("New Criterion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.inkSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        nameFocused = false
                        let created = store.createCriterion(name: name, sfSymbol: selectedSymbol)
                        dismiss()
                        onSaved(created)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accentBrass)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - weight_editor (push)

/// weight_editor route (F5 / ACC-F5): sliders 0–100 per enabled criterion,
/// live Σ=100 validation — Σ≠100 blocks save and states the delta. Switching
/// the active profile re-ranks compare immediately (mot_rank_regrow).
struct WeightEditorView: View {
    @EnvironmentObject private var store: LocalStore
    @Environment(\.dismiss) private var dismiss

    /// nil = editing a new (unsaved) profile from the draft.
    let profileId: UUID?

    @State private var name: String = ""
    @State private var weights: [UUID: Int] = [:]
    @State private var toast: String? = nil

    private var existing: WeightProfile? { store.weightProfiles.first(where: { $0.id == profileId }) }
    private var total: Int { weights.values.reduce(0, +) }
    private var delta: Int { ScoringEngine.weightDelta(weights: weights) }
    private var saveable: Bool { ScoringEngine.weightsAreSaveable(weights: weights) && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                nameField
                totalBanner
                ForEach(store.enabledCriteria) { criterion in
                    sliderRow(criterion: criterion)
                }
                saveSection
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle(existing?.name ?? "New Profile")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) { ToastView(text: $toast) }
        .onAppear {
            if let existing {
                name = existing.name
                weights = existing.weights
            } else if let draft = store.weightEditorDraft {
                name = draft.name
                weights = draft.weights
            }
        }
        .onChange(of: weights) { _, newValue in
            store.weightEditorDraft = WeightEditorDraft(profileId: existing?.id, name: name, weights: newValue)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Profile name")
                .font(Theme.caption().weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
            TextField("e.g. Commute-first", text: $name)
                .font(Theme.body())
                .foregroundStyle(Theme.inkPrimary)
                .submitLabel(.done)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Theme.bgPanel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: name) { _, newValue in
                    store.weightEditorDraft = WeightEditorDraft(profileId: existing?.id, name: newValue, weights: weights)
                }
        }
    }

    private var totalBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: delta == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(delta == 0 ? Theme.accentSage : Theme.warnTerracotta)
            Text(delta == 0
                 ? "Total is 100% — ready to save."
                 : delta > 0
                    ? "Total is \(total)% — add \(delta) to save."
                    : "Total is \(total)% — remove \(-delta) to save.")
                .font(Theme.body())
                .foregroundStyle(Theme.inkPrimary)
            Spacer()
            Text("Σ \(total)%")
                .font(Theme.scoreNumber())
                .foregroundStyle(delta == 0 ? Theme.accentSage : Theme.warnTerracotta)
        }
        .padding(12)
        .background((delta == 0 ? Theme.accentSage : Theme.warnTerracotta).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel(delta == 0 ? "Weights total 100 percent" : "Weights total \(total) percent, adjust by \(abs(delta))")
    }

    private func sliderRow(criterion: Criterion) -> some View {
        let value = weights[criterion.id] ?? 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: criterion.sfSymbol)
                    .foregroundStyle(Theme.accentBrass)
                    .frame(width: 22)
                Text(criterion.name)
                    .font(Theme.body().weight(.medium))
                    .foregroundStyle(Theme.inkPrimary)
                Spacer()
                Text("\(value)%")
                    .font(Theme.scoreNumber())
                    .foregroundStyle(Theme.inkPrimary)
                    .accessibilityHidden(true)
            }
            Slider(value: Binding(
                get: { Double(weights[criterion.id] ?? 0) },
                set: { weights[criterion.id] = Int($0.rounded()) }),
                in: 0...100, step: 1)
                .tint(Theme.accentBrass)
                .accessibilityLabel("Weight for \(criterion.name)")
                .accessibilityValue("\(value) percent")
        }
        .padding(12)
        .panelCard()
    }

    private var saveSection: some View {
        VStack(spacing: 10) {
            Button {
                if let saved = store.saveWeightProfile(id: existing?.id, name: name, weights: weights) {
                    store.weightEditorDraft = nil
                    if !saved.isActive {
                        store.activateWeightProfile(id: saved.id)
                    }
                    toast = "Profile saved and activated."
                } else {
                    toast = "Total must equal 100% to save."
                }
            } label: {
                Text(existing?.isActive == true ? "Save" : "Save & Set Active")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(saveable ? Theme.accentBrass : Theme.inkTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!saveable)
            .accessibilityLabel("Save weight profile")

            if let existing, !existing.isActive, store.weightProfiles.count > 1 {
                Button(role: .destructive) {
                    if store.deleteWeightProfile(id: existing.id) {
                        dismiss()
                    }
                } label: {
                    Text("Delete Profile")
                        .font(Theme.body().weight(.medium))
                        .foregroundStyle(Theme.warnTerracotta)
                }
            }
        }
        .padding(.top, 6)
    }
}
