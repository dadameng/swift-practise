import Foundation
import UIKit

final class CurrencyListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()

    let coordinator: CurrencyListCoordinator
    let viewModel: CurrencyListViewModel

    init(coordinator: CurrencyListCoordinator, viewModel: CurrencyListViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupBehaviours()
    }

    // MARK: - Private

    private func setupBehaviours() {
        addBehaviors([WhiteStyleNavigationBarBehavior(title: "Select Currency")])
    }

    // MARK: - UITableViewDataSource and UITableViewDelegate methods

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.listViewModels.count
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        55
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CurrencyListCell.reuseIdentifier,
            for: indexPath
        ) as? CurrencyListCell else {
            assertionFailure("Cannot dequeue reusable cell \(CurrencyListCell.self) with reuseIdentifier: \(CurrencyListCell.reuseIdentifier)")
            return UITableViewCell()
        }
        cell.updateCell(with: viewModel.listViewModels[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectedIndex(at: indexPath.row)
        coordinator.popToSource(viewModel.selectedSymbols, from: navigationController!)
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(CurrencyListCell.self, forCellReuseIdentifier: CurrencyListCell.reuseIdentifier)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
}
