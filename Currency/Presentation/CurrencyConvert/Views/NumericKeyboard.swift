import UIKit

enum ResetType {
    case initialized
    case withDecimal(Decimal)
    case withInteger(Int)
}

protocol NumericKeyboardInterface {
    var currentValue: String? { get set }
    func reset(_: ResetType)
}

enum KeyboardInputError: Error {
    case maxLimit
    case emptyDelete
    case maximumFractionDigits
}

@MainActor
final class KeyboardInputHandler {
    enum State {
        case initial
        case numberInput
        case decimalInput
    }

    var state: State = .initial
    var displayedText: String = ""
    let maxInput: Int
    let maximumFractionDigits: Int

    init(state: State, displayedText: String, maxInput: Int, maximumFractionDigits: Int) {
        self.state = state
        self.displayedText = displayedText
        self.maxInput = maxInput
        self.maximumFractionDigits = maximumFractionDigits
    }

    func handleInput(_ input: String) throws {
        switch input {
        case "0" ... "9":
            try handleNumberInput(input)
        case ".":
            handleDecimalInput()
        case "-":
            try handleDeleteInput()
        default:
            break
        }
    }

    private func handleNumberInput(_ input: String) throws {
        switch state {
        case .initial:
            displayedText = input != "0" ? input : "0"
            state = .numberInput
        case .numberInput:
            guard displayedText != "0" else {
                displayedText = input
                return
            }
            guard !isGreaterThanMax(string: displayedText + input) else {
                throw KeyboardInputError.maxLimit
            }
            displayedText += input
        case .decimalInput:
            guard !isGreaterThanMaximumFractionDigits() else {
                throw KeyboardInputError.maximumFractionDigits
            }
            displayedText += input
        }
    }

    private func handleDecimalInput() {
        if state != .decimalInput {
            if state == .initial {
                displayedText = "0."
            } else if !displayedText.contains(".") {
                displayedText += "."
            }
            state = .decimalInput
        }
    }

    private func handleDeleteInput() throws {
        guard !displayedText.isEmpty, displayedText != "0" else {
            throw KeyboardInputError.emptyDelete
        }

        displayedText.removeLast()
        if displayedText.isEmpty {
            state = .initial
            displayedText = ""
        } else if displayedText.contains(".") {
            state = .decimalInput
        } else {
            state = .numberInput
        }
    }

    private func isGreaterThanMax(string: String) -> Bool {
        guard let number = Decimal(string: string) else {
            fatalError("please check input")
        }

        let intMaxDecimal = Decimal(maxInput)
        return number > intMaxDecimal
    }

    private func isGreaterThanMaximumFractionDigits() -> Bool {
        guard let decimal = Decimal(string: displayedText) else {
            fatalError("please check input")
        }
        let decimalFractionDigits = max(0, -decimal.exponent)
        return decimalFractionDigits >= maximumFractionDigits
    }
}

@MainActor
final class NumericKeyboard: UIView {
    var currentValue: String?
    var disableInput = false {
        didSet {
            for (_, rowButtons) in buttonsLayout.enumerated() {
                for (_, title) in rowButtons.enumerated() {
                    if let button = buttons[title] {
                        button.isEnabled = !disableInput
                    }
                }
            }
        }
    }

    private var inputHandler: KeyboardInputHandler
    private let buttonsLayout = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "-"],
    ]
    private var buttons: [String: UIButton] = [:]
    private let inputCallback: (String?) -> Void
    private let onLimitedRuleInvoked: (KeyboardInputError) -> Void

    private let gap: CGFloat = 0.5
    private let maxInput: Int
    private let maximumFractionDigits: Int

    init(
        maxInput: Int,
        maximumFractionDigits: Int,
        inputCallback: @escaping (String?) -> Void,
        onLimitedRuleInvoked: @escaping (KeyboardInputError) -> Void
    ) {
        self.maxInput = maxInput
        self.maximumFractionDigits = maximumFractionDigits
        self.inputCallback = inputCallback
        self.onLimitedRuleInvoked = onLimitedRuleInvoked
        inputHandler = KeyboardInputHandler(
            state: .initial,
            displayedText: "",
            maxInput: maxInput,
            maximumFractionDigits: maximumFractionDigits
        )
        super.init(frame: .zero)
        backgroundColor = UIColor(named: "PrimaryKeyboardMarginColor")
        setupButtons()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupButtons() {
        for keys in buttonsLayout {
            for key in keys {
                let button = createButton(title: key)
                addSubview(button)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let buttonWidth = (bounds.width - 2 * gap) / 3
        let buttonHeight = (bounds.height - 3 * gap) / 4

        for (row, rowButtons) in buttonsLayout.enumerated() {
            for (column, title) in rowButtons.enumerated() {
                if let button = buttons[title] {
                    button.frame = CGRect(
                        x: CGFloat(column) * (buttonWidth + gap),
                        y: CGFloat(row) * (buttonHeight + gap),
                        width: buttonWidth,
                        height: buttonHeight
                    )
                }
            }
        }
    }

    private func createButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        let backgroundColor = UIColor(named: "PrimaryKeyboardBgColor")!
        let titleColor = UIColor(named: "PrimaryKeyboardTitleColor")!

        button.setBackgroundColor(backgroundColor, forState: .normal)
        button.setBackgroundColor(backgroundColor.withAlphaComponent(0.8), forState: .highlighted)
        button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        button.setTitleColor(titleColor, for: .normal)

        if title == "-" {
            button.setImage(UIImage(systemName: "delete.left"), for: .normal)
            button.tintColor = titleColor
        } else {
            button.setTitle(title, for: .normal)
        }
        buttons[title] = button

        return button
    }

    @objc private func keyPressed(_ sender: UIButton) {
        guard let key = buttons.first(where: { $0.value == sender })?.key else { return }
        let oldDisplayedText = currentValue
        do {
            try inputHandler.handleInput(key)
            let newDisplayedText = inputHandler.displayedText.isEmpty ? nil : inputHandler.displayedText
            guard oldDisplayedText != newDisplayedText else {
                return
            }
            currentValue = newDisplayedText
            inputCallback(newDisplayedText)
        } catch let error as KeyboardInputError {
            onLimitedRuleInvoked(error)
        } catch {
            fatalError("shouldn't happen in NumericKeyboard")
        }
    }
}

extension NumericKeyboard: NumericKeyboardInterface {
    func reset(_ type: ResetType) {
        switch type {
        case .initialized:
            currentValue = nil
            inputHandler = KeyboardInputHandler(
                state: .initial,
                displayedText: "",
                maxInput: maxInput,
                maximumFractionDigits: maximumFractionDigits
            )
        case let .withDecimal(value):
            guard value.exponent < 0 else {
                fatalError("please input  a decimal number")
            }
            let resetValue = "\(value)"
            currentValue = resetValue
            inputHandler = KeyboardInputHandler(
                state: .decimalInput,
                displayedText: resetValue,
                maxInput: maxInput,
                maximumFractionDigits: maximumFractionDigits
            )
        case let .withInteger(value):
            let resetValue = "\(value)"
            currentValue = resetValue
            inputHandler = KeyboardInputHandler(
                state: .numberInput,
                displayedText: resetValue,
                maxInput: maxInput,
                maximumFractionDigits: maximumFractionDigits
            )
        }
    }
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor, forState controlState: UIControl.State) {
        let colorImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
            color.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: 1)).fill()
        }
        setBackgroundImage(colorImage, for: controlState)
    }
}
