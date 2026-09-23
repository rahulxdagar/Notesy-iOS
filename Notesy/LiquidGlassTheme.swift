import SwiftUI

extension View {
    func liquidGlass() -> some View {
        self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    func liquidGlass(id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View {
        self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .glassEffectID(id, in: namespace)
    }
}
