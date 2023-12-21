import UIKit

@MainActor
class BlinkingCursor: UIView {
    private let blinkingRate: CFTimeInterval = 0.7
    let cursorColor: UIColor

    init(cursorColor: UIColor) {
        self.cursorColor = cursorColor
        super.init(frame: .zero)
        backgroundColor = self.cursorColor
        startBlinking()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func restartBlinking() {
        layer.removeAnimation(forKey: "blinking")
        startBlinking()
    }

    private func startBlinking() {
        let blinkingAnimation = CABasicAnimation(keyPath: "opacity")
        blinkingAnimation.fromValue = 1.0
        blinkingAnimation.toValue = 0.0
        blinkingAnimation.duration = blinkingRate
        blinkingAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        blinkingAnimation.autoreverses = true
        blinkingAnimation.repeatCount = Float.infinity
        layer.add(blinkingAnimation, forKey: "blinking")
    }
}
