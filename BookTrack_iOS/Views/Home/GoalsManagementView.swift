//
//  GoalsManagementView.swift
//  BookTrack_iOS
//
//  Created by Codex on 2026-04-15.
//

import SwiftUI

struct GoalsManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dashboardVM: DashboardViewModel

    @State private var draft = GoalDraft()
    @State private var editingGoal: GoalDTO?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("New Goal") {
                    GoalEditorForm(draft: $draft)

                    Button {
                        Task {
                            let didSave = await dashboardVM.createGoal(
                                period: draft.period,
                                metric: draft.metric,
                                target: draft.targetValue,
                                isActive: draft.isActive,
                                isPrimary: draft.isPrimary
                            )

                            if didSave {
                                draft = GoalDraft()
                            }
                        }
                    } label: {
                        if dashboardVM.isSavingGoal {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Goal")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!draft.isValid || dashboardVM.isSavingGoal)
                }

                Section("Your Goals") {
                    if dashboardVM.goals.isEmpty {
                        ContentUnavailableView(
                            "No Goals Yet",
                            systemImage: "target",
                            description: Text("Create a goal for pages or books and it will start tracking on your dashboard.")
                        )
                    } else {
                        ForEach(dashboardVM.goals) { goal in
                            Button {
                                editingGoal = goal
                            } label: {
                                GoalRow(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Manage Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Goal Error", isPresented: goalErrorIsPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(dashboardVM.goalErrorMessage ?? "Something went wrong.")
            }
            .sheet(item: $editingGoal) { goal in
                GoalEditSheet(goal: goal)
                    .environmentObject(dashboardVM)
            }
        }
    }

    private var goalErrorIsPresented: Binding<Bool> {
        Binding(
            get: { dashboardVM.goalErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    dashboardVM.goalErrorMessage = nil
                }
            }
        )
    }
}

private struct GoalEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dashboardVM: DashboardViewModel

    let goal: GoalDTO

    @State private var draft: GoalDraft
    @State private var showingDeleteConfirmation = false

    init(goal: GoalDTO) {
        self.goal = goal
        _draft = State(initialValue: GoalDraft(goal: goal))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    LabeledContent("Period", value: goal.period.title)
                    LabeledContent("Metric", value: goal.metric.title)
                    GoalEditorForm(draft: $draft, allowsIdentityEditing: false)
                }

                Section {
                    Button {
                        Task {
                            let didSave = await dashboardVM.updateGoal(
                                id: goal.id,
                                target: draft.targetValue,
                                isActive: draft.isActive,
                                isPrimary: draft.isPrimary
                            )

                            if didSave {
                                dismiss()
                            }
                        }
                    } label: {
                        if dashboardVM.isSavingGoal {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!draft.isValid || dashboardVM.isSavingGoal)

                    Button("Delete Goal", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(dashboardVM.isSavingGoal)
                    .popover(isPresented: $showingDeleteConfirmation, attachmentAnchor: .point(.center), arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Delete this goal?")
                                .font(.headline)

                            Text("This will remove the goal and stop tracking its progress.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                Button("Cancel") {
                                    showingDeleteConfirmation = false
                                }
                                
                                Spacer()
                                
                                Button("Delete", role: .destructive) {
                                    Task {
                                        let didDelete = await dashboardVM.deleteGoal(id: goal.id)
                                        if didDelete {
                                            showingDeleteConfirmation = false
                                            dismiss()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .frame(width: 300)
                        .presentationCompactAdaptation(.popover)
                    }
                }
                .listRowSeparator(.hidden, edges: .all)
            }
            
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Goal Error", isPresented: goalErrorIsPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(dashboardVM.goalErrorMessage ?? "Something went wrong.")
            }
        }
    }

    private var goalErrorIsPresented: Binding<Bool> {
        Binding(
            get: { dashboardVM.goalErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    dashboardVM.goalErrorMessage = nil
                }
            }
        )
    }
}

private struct GoalEditorForm: View {
    @Binding var draft: GoalDraft
    var allowsIdentityEditing = true

    var body: some View {
        if allowsIdentityEditing {
            Picker("Period", selection: $draft.period) {
                ForEach(GoalPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }

            Picker("Metric", selection: $draft.metric) {
                ForEach(GoalMetric.allCases) { metric in
                    Text(metric.title).tag(metric)
                }
            }
        }

        TextField("Target", text: $draft.target)
            .keyboardType(.numberPad)

        Toggle("Active", isOn: $draft.isActive)
        Toggle("Pin on Dashboard", isOn: $draft.isPrimary)
    }
}

private struct GoalRow: View {
    let goal: GoalDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: goal.metric.icon)
                .font(.title3)
                .foregroundStyle(goal.metric == .pages ? .indigo : .teal)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(goal.period.title) \(goal.metric.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("\(goal.target) \(goal.target == 1 ? goal.metric.singularTitle : goal.metric.title.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(goal.isActive ? "Active" : "Paused")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(goal.isActive ? .green : .secondary)

                if goal.isPrimary == true {
                    Text("Pinned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct GoalDraft {
    var period: GoalPeriod = .daily
    var metric: GoalMetric = .pages
    var target = ""
    var isActive = true
    var isPrimary = false

    init() {}

    init(goal: GoalDTO) {
        period = goal.period
        metric = goal.metric
        target = String(goal.target)
        isActive = goal.isActive
        isPrimary = goal.isPrimary ?? false
    }

    var targetValue: Int {
        Int(target) ?? 0
    }

    var isValid: Bool {
        targetValue > 0
    }
}

#Preview {
    GoalsManagementView()
        .environmentObject(DashboardViewModel())
}
