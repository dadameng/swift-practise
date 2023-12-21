import UIKit

protocol CurrencyListCellInput {
    func updateCell(with viewModel: CurrencyListItemViewModel)
}

final class CurrencyListCell: UITableViewCell {
    static let reuseIdentifier = String(describing: CurrencyListCell.self)

    private var flagImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private var currencyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .black
        return label
    }()

    private var statusImageView: UIImageView = {
        let imageView = UIImageView()
        let checkmarkImage = UIImage(systemName: "checkmark")
        imageView.image = checkmarkImage
        imageView.tintColor = .gray
        return imageView
    }()

    private let contentPaddingEdge = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
    private let viewsSpace = 20.0
    private let imageViewSize = CGSize(width: 48, height: 32)
    private let titleLabelWidth = 40.0

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

    // MARK: - UI setup

    private func setupViews() {
        contentView.backgroundColor = .white
        [flagImageView, currencyLabel, statusImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            flagImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPaddingEdge.left),
            flagImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagImageView.widthAnchor.constraint(equalToConstant: imageViewSize.width),
            flagImageView.heightAnchor.constraint(equalToConstant: imageViewSize.height),

            currencyLabel.leadingAnchor.constraint(equalTo: flagImageView.trailingAnchor, constant: viewsSpace),
            currencyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            statusImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPaddingEdge.right),
            statusImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
}

extension CurrencyListCell: CurrencyListCellInput {
    func updateCell(with viewModel: CurrencyListItemViewModel) {
        statusImageView.isHidden = !viewModel.selected
        flagImageView.image = UIImage(named: viewModel.imageName)
        currencyLabel.text = viewModel.currency
    }
}
