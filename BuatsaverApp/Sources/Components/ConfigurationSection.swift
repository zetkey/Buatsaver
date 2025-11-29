//
//  ConfigurationSection.swift
//  Buatsaver
//
//  Configuration section for screensaver settings.
//

import SwiftUI

struct ConfigurationSection: View {
    @Binding var saverName: String
    @Binding var saverIdentifier: String
    var isBundleIdentifierValid: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Screensaver Name")
                    .accessibilityHint("Enter the name for your screensaver")

                TextField("Screensaver name", text: $saverName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .accessibilityLabel("Screensaver Name")
                    .accessibilityHint("Enter the name for your screensaver")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Bundle ID")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("Bundle identifier", text: $saverIdentifier)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(isBundleIdentifierValid ? .secondary : .red)
                    .padding(10)
                    .background(
                        isBundleIdentifierValid
                            ? Color(nsColor: .controlBackgroundColor)
                            : Color(nsColor: .controlBackgroundColor).opacity(0.7)
                    )
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isBundleIdentifierValid ? Color.secondary : Color.red,
                                lineWidth: isBundleIdentifierValid ? 1 : 1.5
                            )
                    )
                    .accessibilityLabel("Bundle Identifier")
                    .accessibilityHint("Unique identifier for the screensaver (auto-generated from name)")
            }
        }
    }
}

struct ConfigurationSection_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationSection(
            saverName: .constant("Test Screensaver"),
            saverIdentifier: .constant("local.test.screensaver"),
            isBundleIdentifierValid: true
        )
        .padding()
        .frame(width: 400)
    }
}
