import ComposableArchitecture
import SwiftUI

struct AccountPickerState: Equatable {
    var rows: IdentifiedArrayOf<AccountPickerRow>
}