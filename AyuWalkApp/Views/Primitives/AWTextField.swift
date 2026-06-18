import SwiftUI
import UIKit

struct AWTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var font: Font = AyuWalkTypography.bodyStrong

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textFieldStyle(.plain)
            .font(font)
            .foregroundStyle(AyuWalkTheme.ink)
            .padding(.horizontal, AyuWalkSpacing.md)
            .frame(height: AyuWalkSize.formControlHeight)
            .awPaperInsetBackground(
                cornerRadius: AyuWalkSize.formControlHeight / 2,
                fill: AyuWalkTheme.surface,
                borderTint: AyuWalkTheme.secondaryAccent
            )
    }
}
