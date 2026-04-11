import SwiftUI
import WebKit
import AVFoundation

// MARK: - Notifications
struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash").font(.system(size: 40)).foregroundColor(.secondary)
                        Text("Nothing yet").foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(notifications) { n in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(Color.brand.opacity(0.1)).frame(width: 36, height: 36)
                                Image(systemName: "sparkles").font(.system(size: 14)).foregroundColor(Color.brand)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(n.title).font(.system(size: 14, weight: .semibold))
                                Text(n.body).font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            Spacer()
                            if n.isUnread { Circle().fill(Color.brand).frame(width: 7, height: 7) }
                        }
                        .padding(.vertical, 4)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
            }
        }
        .task {
            if let r = try? await APIService.shared.request(path: "/api/notifications") as NotificationsResponse {
                notifications = r.notifications
            }
            isLoading = false
        }
    }
}

// MARK: - Shared UI Components
struct SGField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var caps: Bool = true

    init(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, caps: Bool = true) {
        self.placeholder = placeholder
        self._text = text
        self.keyboard = keyboard
        self.caps = caps
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboard)
            .autocapitalization(caps ? .words : .none)
            .autocorrectionDisabled()
            .padding(.horizontal, 14).frame(height: 52)
            .background(Color(.secondarySystemBackground)).cornerRadius(14)
    }
}

struct SGSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var show = false

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        HStack {
            if show { TextField(placeholder, text: $text).autocapitalization(.none) }
            else { SecureField(placeholder, text: $text) }
            Button(action: { show.toggle() }) {
                Image(systemName: show ? "eye.slash" : "eye").foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14).frame(height: 52)
        .background(Color(.secondarySystemBackground)).cornerRadius(14)
    }
}

struct SGButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading { ProgressView().tint(.white) }
            else {
                Text(title).font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white).frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 54)
        .background(disabled || isLoading ? Color.accent.opacity(0.4) : Color.accent)
        .cornerRadius(14)
        .disabled(disabled || isLoading)
    }
}

