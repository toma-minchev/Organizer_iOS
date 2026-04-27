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
    var recurrenceValue: Int
    var recurrenceUnit: RecurrenceUnit
}

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var event: Event

    @State private var draft: DraftEvent
    private let snapshot: DraftEvent

    init(event: Event) {
        self.event = event
        let snap = DraftEvent(
            name: event.name,
            details: event.details,
            dueDate: event.dueDate,
            recurrenceValue: event.recurrenceValue,
            recurrenceUnit: event.recurrenceUnit
        )
        _draft = State(initialValue: snap)
        self.snapshot = snap
    }

    @State private var isDirty: Bool = false

    private var isNameValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func applyChanges() {
        event.name = draft.name
        event.details = draft.details
        event.dueDate = draft.dueDate
        event.recurrenceValue = draft.recurrenceValue
        event.recurrenceUnit = draft.recurrenceUnit
        
        event.scheduleNotification()
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

            Toggle("Completed", isOn: $event.isCompleted)
            .sensoryFeedback(.impact(weight: .medium), trigger: event.isCompleted)

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
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if isDirty {
                    Button {
                        if isNameValid {
                            applyChanges()
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(isNameValid ? .accentColor : .gray)
                } else {
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        event.deleteNotification()
                        modelContext.delete(event)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .onChange(of: draft) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isDirty = draft != snapshot
            }
        }
    }
}
