import Combine
import Foundation
import UIKit

final class CurrencyConvertController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static private let keyboardHeightRate = 0.35

    // MARK: - property

    let coordinator: CurrencyConvertCoordinator
    let viewModel: CurrencyConvertViewModel
    let tableView = UITableView()
    var numericKeyboard: NumericKeyboard?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - override

    init(coordinator: CurrencyConvertCoordinator, viewModel: CurrencyConvertViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        numericKeyboard = NumericKeyboard(
            maxInput: Int.max,
            maximumFractionDigits: viewModel.formatteMaximumFractionDigits,
            inputCallback: handleKeyboardInputChange,
            onLimitedRuleInvoked: handleInvalidInput
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNumericKeyboard()
        setupTableView()
        setupBehaviours()
        bindViewModel()
    }

    // MARK: - Private

    private func setupBehaviours() {
        addBehaviors([WhiteStyleNavigationBarBehavior(title: "Currency Exchange"), BackButtonEmptyTitleNavigationBarBehavior()])
    }

    private func bindViewModel() {
        viewModel.viewDidLoad(viewController: self)
        viewModel.isRequestingPublisher.receive(on: RunLoop.main).sink { [unowned self] isLoading in
            self.numericKeyboard?.disableInput = isLoading
            isLoading ? self.triggerShimmerAnimation() : self.removeShimmerAnimation()
        }.store(in: &cancellables)
        viewModel.itemViewModelsPublisher.receive(on: RunLoop.main).sink { [unowned self] result in
            switch result {
            case .success:
                self.tableView.reloadData()
            case let .failure(error):
                print("error is : \(error)")
            }
            self.tableView.refreshControl?.endRefreshing()
        }.store(in: &cancellables)
    }

    // MARK: - UITableViewDataSource and UITableViewDelegate methods

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.itemViewModels.count
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        let totalHeight = view.frame.height * (1 - CurrencyConvertController.keyboardHeightRate)
        let availableHeight = totalHeight - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        let rowCount = CGFloat(viewModel.itemViewModels.count)
        let rowHeight = availableHeight / rowCount
        return rowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CurrencyConvertTableCell.reuseIdentifier,
            for: indexPath
        ) as? CurrencyConvertTableCell else {
            assertionFailure(
                "Cannot dequeue reusable cell \(CurrencyConvertTableCell.self) with reuseIdentifier: \(CurrencyConvertTableCell.reuseIdentifier)"
            )
            return UITableViewCell()
        }
        cell.updateCell(with: viewModel.itemViewModels[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row != viewModel.selectedIndex else {
            return
        }
        numericKeyboard?.reset(.initialized)
        viewModel.didResetInput()
        viewModel.didSelectItem(at: indexPath.row)
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Change Currency") { [unowned self] _, _, completionHandler in
            coordinator.showCurrencyListViewController(
                from: navigationController!,
                in: viewModel.selectedSymbols,
                at: indexPath.row,
                symbolsChangeBlock: { [unowned self] newSymblos in
                    viewModel.didUpdateSelectedSymbols(newSymblos)
                }
            )
            completionHandler(true)
        }
        action.backgroundColor = AppColor.alterCurrencyActionBg.color

        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }

    // MARK: - handle change

    private func handleKeyboardInputChange(_ input: String?) {
        viewModel.didInputValidValue()
        viewModel.didUpdateAmount(input)
    }

    private func handleInvalidInput(_: KeyboardInputError) {
        triggerShakeCurrentCell()
    }

    private func triggerShakeCurrentCell() {
        let indexPath = IndexPath(row: viewModel.selectedIndex, section: 0)

        guard let cell = tableView.cellForRow(at: indexPath) as? CurrencyConvertTableCell else {
            return
        }
        cell.triggerShakeAnimation()
    }

    @objc private func refreshData(_ sender: UIRefreshControl) {
        sender.attributedTitle = NSAttributedString(string: "last time update at \(viewModel.lastTimeString)")
        sender.beginRefreshing()
        viewModel.didTriggerRefresh()
    }

    private func triggerShimmerAnimation() {
        for cell in tableView.visibleCells {
            if let cell = cell as? CurrencyConvertTableCell {
                cell.triggerShimmerAnimation()
            }
        }
    }

    private func removeShimmerAnimation() {
        for cell in tableView.visibleCells {
            if let cell = cell as? CurrencyConvertTableCell {
                cell.removeShimmerAnimation()
            }
        }
    }

    // MARK: - UI Setup

    private func setupNumericKeyboard() {
        view.addSubview(numericKeyboard!)
        numericKeyboard!.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            numericKeyboard!.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: CurrencyConvertController.keyboardHeightRate),
            numericKeyboard!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            numericKeyboard!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            numericKeyboard!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(CurrencyConvertTableCell.self, forCellReuseIdentifier: CurrencyConvertTableCell.reuseIdentifier)
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: numericKeyboard!.topAnchor),
        ])
    }
}
