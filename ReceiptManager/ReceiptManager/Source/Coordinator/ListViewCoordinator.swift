//
//  ListViewCoordinator.swift
//  ReceiptManager
//
//  Created by parkhyo on 2023/11/16.
//

import UIKit

final class ListViewCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    var navigationController: UINavigationController?
    var storageService: StorageService
    var userDefaultService: UserDefaultService
    var dateManageService: DateManageService
    
    var viewController: UIViewController?
    
    init(
        storageService: StorageService,
        userDefaultService: UserDefaultService,
        dateManageService: DateManageService
    ) {
        self.storageService = storageService
        self.userDefaultService = userDefaultService
        self.dateManageService = dateManageService
    }
    
    func start() {
        let listViewReactor = ListViewReactor(
            storageService: storageService,
            userDefaultService: userDefaultService,
            dateManageService: dateManageService
        )
        let listViewController = ListViewController(reactor: listViewReactor)
        listViewController.coordinator = self
        viewController = listViewController
        
        guard let parentViewController = parentCoordinator?.navigationController?.viewControllers.last else {
            return
        }
        parentViewController.addChild(listViewController)
    }
    
    func presentDetailView(expense: Receipt) {
        let expenseViewCoordinator = parentCoordinator as? ExpenseViewCoordinator
        
        expenseViewCoordinator?.moveDetailView(expense: expense)
    }
}
