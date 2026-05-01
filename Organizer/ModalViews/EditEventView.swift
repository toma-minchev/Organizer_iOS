//
//  EditEventView.swift
//  Organizer
//

import SwiftUI
import SwiftData

struct DraftEvent: Equatable {
    var name: String
    var details: String
    var dueDate: Date
    var priority: Priority
    var notify: Bool
    var notifyOffsetValue: Int
    var notifyOffsetUnit: RecurrenceUnit
    var recurrenceValue: Int
    var recurrenceUnit: RecurrenceUnit
}

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var event: Event
    
    @State private var showDeleteConfirmation = false
    @State private var draft: DraftEvent
    @State private var snapshot: DraftEvent
    
    private var isDirty: Bool { draft != snapshot }
    private var isNameValid: Bool { !draft.name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(event: Event) {
        self.event = event
        let snap = DraftEvent(
            name: event.name,
            details: event.details,
            dueDate: event.dueDate,
            priority: event.priority,
            notify: event.notify,
            notifyOffsetValue: event.notifyOffsetValue,
            notifyOffsetUnit: event.notifyOffsetUnit,
            recurrenceValue: event.recurrenceValue,
            recurrenceUnit: event.recurrenceUnit
        )
        _draft = State(initialValue: snap)
        _snapshot = State(initialValue: snap)
    }

    
    var body: some View {
        Form {
            TextField("Name", text: $draft.name)
                .bold()
                .padding(.top, 6)
                .padding(.horizontal, 6)

            ZStack(alignment: .topLeading) {
                if draft.details.isEmpty {
                    Text("Details")
                        .foregroundColor(.secondary)
                        .padding(.top, 6)
                        .padding(.horizontal, 6)
                        .bold()
                }

                TextEditor(text: $draft.details)
                    .frame(minHeight: 120)
                    .frame(maxHeight: 300)
            }

            DatePicker("Due Date", selection: $draft.dueDate)
            
            HStack {
                Text("Priority")
                Spacer()
                
                Menu {
                    ForEach(Priority.allCases) { option in
                        Button(option.title) { draft.priority = option }

                    }
                } label: {
                    Text(draft.priority.title)
                    .frame(minWidth: 40)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(.secondarySystemFill)))
                }
            }

            Toggle("Completed", isOn: Binding(
                get: { event.isCompleted },
                set: { _ in handleCompletion() }
            ))
            .sensoryFeedback(.impact(weight: .medium), trigger: event.isCompleted)
            
            Section("Notify") {
                Toggle("Send notification", isOn: Binding(
                    get: { draft.notify },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            draft.notify = newValue
                        }
                    }
                ))
                .sensoryFeedback(.impact(weight: .medium), trigger: draft.notify)
                
                if draft.notify {
                    HStack {
                        Text("Early reminder")
                        Spacer()
                        Menu {
                            Button("0") { draft.notifyOffsetValue = 0 }
                            ForEach(RecurrenceUnit.recurrenceRange(recurrenceUnit: draft.notifyOffsetUnit), id: \.self) { value in
                                Button("\(value)") { draft.notifyOffsetValue = value }
                            }
                        } label: {
                            Text("\(draft.notifyOffsetValue)")
                                .frame(minWidth: 20)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.secondarySystemFill)))
                        }

                        Menu {
                            ForEach(RecurrenceUnit.allCases, id: \.self) { unit in
                                Button(unit.localizedLabel(value: draft.notifyOffsetValue)) {
                                    draft.notifyOffsetUnit = unit
                                }
                            }
                        } label: {
                            Text(draft.notifyOffsetUnit.localizedLabel(value: draft.notifyOffsetValue))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.secondarySystemFill)))
                        }
                    }
                }
            }

            Section("Repeat") {
                Toggle("Repeat", isOn: Binding(
                    get: { draft.recurrenceValue > 0 },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            draft.recurrenceValue = newValue ? 1 : 0
                        }
                    }
                ))
                .sensoryFeedback(.impact(weight: .medium), trigger: draft.recurrenceValue > 0)

                if draft.recurrenceValue > 0 {
                    HStack {
                        Text("Every")
                        Spacer()

                        Menu {
                            ForEach(RecurrenceUnit.recurrenceRange(recurrenceUnit: draft.recurrenceUnit), id: \.self ) { value in
                                Button("\(value)") { draft.recurrenceValue = value }
                            }
                        } label: {
                            Text("\(draft.recurrenceValue)")
                            .frame(minWidth: 20)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color(.secondarySystemFill)))
                        }
                        
                        Menu {
                            ForEach(RecurrenceUnit.allCases, id: \.self) { unit in
                                Button(unit.localizedLabel(value: draft.recurrenceValue)) {
                                    draft.recurrenceUnit = unit
                                }
                            }
                        } label: {
                            Text(draft.recurrenceUnit.localizedLabel(value: draft.recurrenceValue))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color(.secondarySystemFill)))
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Event")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isDirty)
        .navigationBarBackButtonHidden(isDirty)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isDirty {
                    Button("Cancel") {
                        draft = snapshot
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if isDirty {
                    Button {
                        if isNameValid {
                            applyChanges()
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(isNameValid ? .accentColor : .gray)
                } else {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .popover(isPresented: $showDeleteConfirmation) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Delete Event?")
                                .font(.headline)
                                
                                Text("This action cannot be undone.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                            
                            Button {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                showDeleteConfirmation = false
                                event.deleteNotification()
                                modelContext.delete(event)
                                dismiss()
                            } label: {
                                Text("Delete Event")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                            }
                            .padding(14)
                            .background(Capsule().fill(.ultraThinMaterial))
                        }
                        .padding(14)
                        .frame(width: 200)
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDirty)
    }
    
    private func applyChanges() {
        event.name = draft.name
        event.details = draft.details
        event.dueDate = draft.dueDate
        event.priority = draft.priority
        event.notify = draft.notify
        event.notifyOffsetUnit = draft.notifyOffsetUnit
        event.notifyOffsetValue = draft.notifyOffsetValue
        event.recurrenceValue = draft.recurrenceValue
        event.recurrenceUnit = draft.recurrenceUnit
        
        snapshot = draft
        
        if draft.notify { event.scheduleNotification() }
        else { event.deleteNotification() }
    }
    
    private func handleCompletion() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation {
            event.isCompleted.toggle()
        }
        
        if event.isCompleted {
            if event.recurrenceValue > 0 {
                event.addToDueDate()
                event.scheduleNotification()
            } else {
                event.deleteNotification()
            }
            dismiss()
        } else {
            event.scheduleNotification()
        }
    }
}
