import UIKit

protocol NumericKeyboardInterface {
    var currentValue: String { get set }
    func reset()
}

enum KeyboardInputError: Error {
    case maxLimit
    case emptyDelete
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

    init(state: State, displayedText: String) {
        self.state = state
        self.displayedText = displayedText
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
            if !(displayedText == "0" && input == "0") {
                guard !isGreaterThanIntMax(string: displayedText + input) else {
                    throw KeyboardInputError.maxLimit
                }
                displayedText += input
            }
        case .decimalInput:
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
        guard !displayedText.isEmpty else {
            throw KeyboardInputError.emptyDelete
        }
        displayedText.removeLast()
        if displayedText.last == "." {
            displayedText.removeLast()
        }
        if displayedText.isEmpty {
            state = .initial
            displayedText = ""
        } else if displayedText.contains(".") {
            state = .decimalInput
        } else {
            state = .numberInput
        }
    }

    private func isGreaterThanIntMax(string: String) -> Bool {
        guard let number = Decimal(string: string) else {
            return false
        }

        let intMaxDecimal = Decimal(Int.max)
        return number > intMaxDecimal
    }
}

@MainActor
final class NumericKeyboard: UIView {
    var currentValue: String = "" {
        didSet {
            if let _ = Int(currentValue) {
                inputHandler = KeyboardInputHandler(
                    state: .numberInput,
                    displayedText: currentValue
                )
            } else if let _ = Double(currentValue), currentValue.contains(".") {
                inputHandler = KeyboardInputHandler(
                    state: .decimalInput,
                    displayedText: currentValue
                )
            } else {
                inputHandler = KeyboardInputHandler(state: .initial, displayedText: "")
            }
        }
    }

    var inputHandler = KeyboardInputHandler(state: .initial, displayedText: "")
    let buttonsLayout = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "-"],
    ]
    var buttons: [String: UIButton] = [:]
    let inputCallback: (String) -> Void
    let triggerMaxLimit: () -> Void
    let triggerDeleteAlert: () -> Void

    let gap: CGFloat = 0.5

    init(
        inputCallback: @escaping (String) -> Void,
        triggerMaxLimit: @escaping () -> Void,
        triggerDeleteAlert: @escaping () -> Void
    ) {
        self.inputCallback = inputCallback
        self.triggerMaxLimit = triggerMaxLimit
        self.triggerDeleteAlert = triggerDeleteAlert
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
        let oldDisplayedText = inputHandler.displayedText
        do {
            try inputHandler.handleInput(key)
            let newDisplayedText = inputHandler.displayedText
            guard oldDisplayedText != newDisplayedText else {
                return
            }
            currentValue = newDisplayedText
            inputCallback(inputHandler.displayedText)
        } catch let error as KeyboardInputError {
            switch error {
            case .maxLimit:
                triggerMaxLimit()
            case .emptyDelete:
                triggerDeleteAlert()
            }
        } catch {
            fatalError("shouldn't happen in NumericKeyboard")
        }
    }
}

extension NumericKeyboard: NumericKeyboardInterface {
    func reset() {
        currentValue = ""
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
