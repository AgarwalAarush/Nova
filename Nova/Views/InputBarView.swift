//
//  InputBarView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct InputBarView: View {
    @Binding var currentInput: String
    @FocusState private var isTextFieldFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask Nova anything...", text: $currentInput, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .lineLimit(1...4)
                .focused($isTextFieldFocused)
                .onSubmit {
                    onSend()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppColors.textFieldBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppColors.textFieldBorder, lineWidth: 1)
                        )
                )
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.secondaryText : AppColors.accentBlue)
            }
            .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.background)
        .onAppear {
            isTextFieldFocused = true
        }
    }
}