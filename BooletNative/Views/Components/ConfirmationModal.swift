//
//  ConfirmationModal.swift
//  Booklet
//
//  Reusable confirmation modal component
//

import SwiftUI

struct ConfirmationModal: View {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmColor: Color
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    init(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        confirmColor: Color = .blue,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmColor = confirmColor
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 15) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)
                .frame(width: 100)
                
                Button(confirmTitle) {
                    onConfirm()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(confirmColor)
                .frame(width: 100)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

// Destructive confirmation variant
struct DestructiveConfirmationModal: View {
    let title: String
    let message: String
    let itemName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("\"\(itemName)\"")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                
                Text("This action cannot be undone.")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            HStack(spacing: 15) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)
                .frame(width: 100)
                
                Button("Delete") {
                    onConfirm()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(width: 100)
            }
        }
        .padding(30)
        .frame(width: 450)
    }
}

// Generic action confirmation modal
struct ActionConfirmationModal: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let actionTitle: String
    let actionColor: Color
    let onAction: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 15) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)
                .frame(width: 100)
                
                Button(actionTitle) {
                    onAction()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(actionColor)
                .frame(width: 120)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

#Preview("Standard Confirmation") {
    ConfirmationModal(
        title: "Confirm Action",
        message: "Are you sure you want to proceed with this action?",
        onConfirm: {},
        onCancel: {}
    )
}

#Preview("Destructive Confirmation") {
    DestructiveConfirmationModal(
        title: "Delete Book?",
        message: "Are you sure you want to delete",
        itemName: "The Great Gatsby",
        onConfirm: {},
        onCancel: {}
    )
}

#Preview("Action Confirmation") {
    ActionConfirmationModal(
        icon: "book.fill",
        iconColor: .green,
        title: "Send to Reading Tracker?",
        message: "This book will be added to your currently reading list.",
        actionTitle: "Start Reading",
        actionColor: .green,
        onAction: {},
        onCancel: {}
    )
}
