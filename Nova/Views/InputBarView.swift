//
//  InputBarView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct InputBarView: View {
    @Binding var currentInput: String
    @State private var textHeight: CGFloat = 22
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                if currentInput.isEmpty {
                    Text("Ask Nova anything...")
                        .foregroundColor(AppColors.secondaryText)
                        .font(.system(size: 15))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                GrowingTextView(
                    text: $currentInput,
                    height: $textHeight,
                    onSend: onSend
                )
                .focusable()
                .frame(height: textHeight)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
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
    }
}



