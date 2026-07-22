import SwiftUI

struct AICOAlertAction: Identifiable {
    enum Style {
        case primary
        case secondary
        case destructive
    }

    let id = UUID()
    let title: String
    var style: Style = .primary
    let action: () -> Void
}

struct AICOAlertView: View {
    let title: String
    let message: String
    let actions: [AICOAlertAction]

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                actionArea
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 18)
            .frame(maxWidth: 304, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.white.opacity(0.82), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.16), radius: 30, x: 0, y: 18)
            .padding(.horizontal, 48)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    @ViewBuilder
    private var actionArea: some View {
        if actions.count <= 1 {
            ForEach(actions) { action in
                actionButton(action)
            }
        } else {
            VStack(spacing: 10) {
                if let primaryAction = actions.first(where: { $0.style == .primary }) {
                    actionButton(primaryAction)
                }

                HStack(spacing: 10) {
                    ForEach(actions.filter { $0.style != .primary }) { action in
                        actionButton(action)
                    }
                }
            }
        }
    }

    private func actionButton(_ action: AICOAlertAction) -> some View {
        Button {
            action.action()
        } label: {
            Text(action.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(foregroundColor(for: action.style))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(background(for: action.style))
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func foregroundColor(for style: AICOAlertAction.Style) -> Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return AICOTheme.darkGray
        case .destructive:
            return AICOTheme.primaryOrange
        }
    }

    @ViewBuilder
    private func background(for style: AICOAlertAction.Style) -> some View {
        switch style {
        case .primary:
            AICOTheme.primaryOrange
        case .secondary:
            AICOTheme.cardGray
        case .destructive:
            AICOTheme.primaryOrange.opacity(0.1)
        }
    }
}

#Preview {
    AICOAlertView(
        title: "기록이 저장되었어요",
        message: "저장된 기록은 기록 보관함에서 확인할 수 있어요.",
        actions: [
            AICOAlertAction(title: "확인") {}
        ]
    )
}
