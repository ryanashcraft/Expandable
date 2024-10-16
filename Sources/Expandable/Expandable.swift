import SwiftUI

public struct Expandable<Contents: View, ButtonLabel: View>: View {
    @Environment(\.lineLimit) var lineLimit

    /// Wrapped contents.
    private let contents: () -> Contents

    /// Label for the expand button.
    private let buttonLabel: () -> ButtonLabel

    /// Width of the gradient placed on the leading edge of the expand button.
    private let gradientWidth: Double = 60

    @State private var isExpanded: Bool = false

    /// Measured height of the contents when truncated.
    @State private var truncatedHeight: CGFloat = 0

    /// Measured height of the contents when untruncated.
    @State private var fullHeight: CGFloat = 0

    var isTruncated: Bool {
        truncatedHeight < fullHeight
    }

    public init(@ViewBuilder _ contents: @escaping () -> Contents, @ViewBuilder buttonLabel: @escaping () -> ButtonLabel) {
        self.contents = contents
        self.buttonLabel = buttonLabel
    }

    var expandButtonContents: some View {
        ZStack {
            // Use space for vertical alignment when the `expandButtonLabel` is shorter than the line height
            Text(" ")
                .hidden()

            buttonLabel()
        }
    }

    var expandButton: some View {
        Button {
            withAnimation {
                self.isExpanded = true
            }
        } label: {
            expandButtonContents
        }
        .buttonStyle(.borderless)
        .tint(.accentColor)
        .accessibilityHidden(true)
    }

    var expandButtonCutout: some View {
        Color.clear
            .overlay(alignment: .bottomTrailing) {
                expandButtonContents
                    .opacity(0)
                    .overlay(Color.black)
                    .overlay(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(
                                stops: [
                                    .init(color: Color.clear, location: 0),
                                    .init(color: Color.black, location: 1),
                                ]
                            ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: gradientWidth)
                        .offset(x: -gradientWidth)
                        .flipsForRightToLeftLayoutDirection(true)
                    }
            }
    }

    var measuredContents: some View {
        ZStack(alignment: .top) {
            // Measure the truncated height
            contents()
                .lineLimit(lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .local).size.height
                } action: { newValue in
                    self.truncatedHeight = newValue
                }
                .hidden()

            // Measure the untruncated height
            contents()
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .local).size.height
                } action: { newValue in
                    self.fullHeight = newValue
                }
                .hidden()
        }
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            contents()
                .lineLimit(isExpanded ? nil : lineLimit)
                .transaction { $0.animation = nil }
                .frame(maxWidth: .infinity, alignment: .leading)
                .invertedMask {
                    if !isExpanded && isTruncated {
                        expandButtonCutout
                    }
                }

            if isTruncated, !isExpanded {
                expandButton
            }
        }
        .accessibilityAction {
            if isTruncated, !isExpanded {
                withAnimation {
                    self.isExpanded.toggle()
                }
            }
        }
        .background {
            measuredContents
        }
    }
}

extension View {
    @inlinable
    func invertedMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}

#Preview {
    ScrollView {
        Expandable {
            Text("Here’s to the crazy ones. The misfits. The rebels. The troublemakers. The round pegs in the square holes. The ones who see things differently. They’re not fond of rules. And they have no respect for the status quo. You can quote them, disagree with them, glorify or vilify them. About the only thing you can’t do is ignore them. Because they change things. They push the human race forward. And while some may see them as the crazy ones, we see genius. Because the people who are crazy enough to think they can change the world, are the ones who do.")
        } buttonLabel: {
            Text("more")
        }
            .lineLimit(3)
            .padding()

        Expandable {
            Text("هذه فقرة نصية طويلة تستخدم لاختبار عرض النصوص في التطبيقات التي تدعم اللغات من اليمين إلى اليسار. من المهم أن يتم التعامل مع الأحرف والمسافات والتنسيقات بشكل صحيح. يجب أن تكون الواجهة قادرة على التعامل مع نصوص متعددة الأسطر بشكل جيد، بما في ذلك الحالات التي يكون فيها النص طويلاً جدًا ويحتاج إلى قطع أو تقليم.")
        } buttonLabel: {
            Image(systemName: "ellipsis")
        }
            .lineLimit(3)
            .padding()
            .environment(\.layoutDirection, .rightToLeft)
    }
}
