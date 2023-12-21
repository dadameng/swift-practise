import UIKit

protocol CurrencyConvertTableCellInput {
    func updateCell(with viewModel: CurrencyConvertItemViewModel)
    func triggerShakeAnimation()
}

final class CurrencyConvertTableCell: UITableViewCell {
    static let reuseIdentifier = String(describing: CurrencyConvertTableCell.self)

    private var flagImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private var currencyTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(named: "PrimaryCellTitleColor")
        return label
    }()

    private var currencyValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = UIColor(named: "SecondCellTextColor")
        label.textAlignment = .right
        label.contentMode = .right
        return label
    }()

    private var currencyNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(named: "SecondCellTextColor")
        return label
    }()

    private var cursor: BlinkingCursor = {
        let cursor = BlinkingCursor(cursorColor: .red)
        cursor.isHidden = true
        return cursor
    }()

    private var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor(named: "PrimaryCellBgColor")!.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.isHidden = true
        return gradientLayer
    }()

    private let contentPaddingEdge = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
    private let viewsSpace = 20.0
    private let imageViewSize = CGSize(width: 48, height: 32)
    private let titleLabelWidth = 40.0
    private let valuePlaceholderColor = UIColor(named: "SecondCellTextColor")

    // MARK: override

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = currencyTitleLabel.frame
    }

    // MARK: - UI setup

    private func setupViews() {
        contentView.backgroundColor = .white
        [flagImageView, currencyTitleLabel, currencyValueLabel, currencyNameLabel, cursor].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        contentView.layer.addSublayer(gradientLayer)
    }

    private func setupConstraints() {
        // 基本约束
        currencyTitleLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        currencyValueLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            flagImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPaddingEdge.left),
            flagImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagImageView.widthAnchor.constraint(equalToConstant: imageViewSize.width),
            flagImageView.heightAnchor.constraint(equalToConstant: imageViewSize.height),

            currencyTitleLabel.leadingAnchor.constraint(equalTo: flagImageView.trailingAnchor, constant: viewsSpace),
            currencyTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            currencyTitleLabel.widthAnchor.constraint(equalToConstant: titleLabelWidth),

            currencyValueLabel.leadingAnchor.constraint(equalTo: currencyTitleLabel.trailingAnchor, constant: viewsSpace),
            currencyValueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            currencyValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPaddingEdge.right),

            currencyNameLabel.topAnchor.constraint(equalTo: currencyValueLabel.bottomAnchor, constant: 4),
            currencyNameLabel.trailingAnchor.constraint(equalTo: currencyValueLabel.trailingAnchor),

            cursor.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPaddingEdge.right + 2.0),
            cursor.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            cursor.widthAnchor.constraint(equalToConstant: 2.0),
            cursor.heightAnchor.constraint(equalTo: currencyValueLabel.heightAnchor),
        ])
    }

    private func updateLayoutForSelectedState(isSelected: Bool) {
        // 先重置到默认状态
        currencyTitleLabel.isHidden = false
        currencyValueLabel.leadingAnchor.constraint(equalTo: currencyTitleLabel.trailingAnchor, constant: viewsSpace).isActive = false
        currencyValueLabel.leadingAnchor.constraint(equalTo: flagImageView.trailingAnchor, constant: viewsSpace).isActive = false
        gradientLayer.isHidden = true

        if isSelected {
            currencyValueLabel.leadingAnchor.constraint(equalTo: currencyTitleLabel.trailingAnchor, constant: viewsSpace).isActive = true

        } else {
            currencyValueLabel.sizeToFit()
            var remainWidth = contentView.bounds.width - titleLabelWidth - imageViewSize.width
            remainWidth -= contentPaddingEdge.left * 2 - viewsSpace * 2
            let isValueLabelTooLong = currencyValueLabel.frame.width > remainWidth
            currencyTitleLabel.isHidden = isValueLabelTooLong

            if isValueLabelTooLong {
                currencyValueLabel.leadingAnchor.constraint(equalTo: flagImageView.trailingAnchor, constant: viewsSpace).isActive = true
                gradientLayer.isHidden = false
            }
        }
        contentView.layoutIfNeeded()
    }
}

extension CurrencyConvertTableCell: CurrencyConvertTableCellInput {
    func updateCell(with viewModel: CurrencyConvertItemViewModel) {
        flagImageView.image = UIImage(named: viewModel.imageName)
        currencyTitleLabel.text = viewModel.title
        currencyNameLabel.text = viewModel.currencyName
        currencyValueLabel.text = viewModel.valueString
        contentView.backgroundColor = viewModel.selected ? UIColor(named: "PrimaryCellSelectedBgColor")! : UIColor(named: "PrimaryCellBgColor")
        currencyValueLabel.textColor = viewModel.hasValidInput ? .black : valuePlaceholderColor
        cursor.isHidden = !viewModel.selected
        if viewModel.selected {
            cursor.restartBlinking()
        }
        contentView.layoutIfNeeded()
    }

    func triggerShakeAnimation() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-10, 10, -10, 10, -5, 5, -2.5, 2.5, 0]
        layer.add(animation, forKey: "shake")
    }
}
