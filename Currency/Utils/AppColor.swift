import UIKit

enum AppColor: String {
    case primaryCellBg = "PrimaryCellBgColor"
    case primaryCellPlaceholder = "PrimaryCellPlaceholderColor"
    case primaryCellSelectedBg = "PrimaryCellSelectedBgColor"
    case primaryCellTitle = "PrimaryCellTitleColor"
    case primaryKeyboardBg = "PrimaryKeyboardBgColor"
    case primaryKeyboardMargin = "PrimaryKeyboardMarginColor"
    case primaryKeyboardTitle = "PrimaryKeyboardTitleColor"
    case secondCellText = "SecondCellTextColor"
    case alterCurrencyActionBg = "AlterCurrencyActionBgColor"
    case cursor = "CursorColor"

    var color: UIColor {
        return UIColor(named: self.rawValue) ?? UIColor.clear
    }
}
