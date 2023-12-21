import UIKit

struct WhiteStyleNavigationBarBehavior: ViewControllerLifecycleBehavior {
    let title: String
    init(title: String) {
        self.title = title
    }

    func viewDidLoad(viewController: UIViewController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .white
        viewController.navigationController?.navigationBar.tintColor = .black
        viewController.navigationController?.navigationBar.standardAppearance = appearance
        viewController.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        viewController.title = title
    }
}
