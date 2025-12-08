import SwiftUI

struct ThemeSelectorHorizontal: View {
    @Binding var themeSelection: AppThemeID

    init(selection: Binding<AppThemeID>) {
        self._themeSelection = selection
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppThemeID.allCases) { themeID in
                Button {
                    themeSelection = themeID
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(themeID.theme.accent)
                                .frame(width: 24, height: 24)

                            if themeSelection == themeID {
                                Circle()
                                    .strokeBorder(.white.opacity(0.9), lineWidth: 2)
                                    .frame(width: 30, height: 30)
                            }
                        }

                        Text(themeID.displayName)
                            .font(.system(size: 10,
                                          weight: themeSelection == themeID ? .semibold : .regular))
                            .foregroundColor(
                                themeSelection == themeID
                                ? .white.opacity(0.9)
                                : .white.opacity(0.6)
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}




