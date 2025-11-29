//
//  ModernButton.swift
//  Buatsaver
//
//  A modern, customizable button component.
//

import SwiftUI

enum ButtonStyle {
    case primary
    case secondary
}

struct ModernButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    var disabled: Bool = false
    var fullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(style == .primary ? .white : .white.opacity(0.9))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                Group {
                    if style == .primary {
                        LinearGradient(
                            colors: disabled ? [Color.gray.opacity(0.3)] : [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.white.opacity(disabled ? 0.05 : 0.1)
                    }
                }
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        style == .primary
                            ? Color.clear
                            : Color.white.opacity(disabled ? 0.1 : 0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: style == .primary && !disabled
                    ? Color.purple.opacity(0.3)
                    : Color.clear,
                radius: 10,
                y: 5
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: disabled)
    }
}
