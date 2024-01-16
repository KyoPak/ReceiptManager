//
//  MainTabBarCoordinator.swift
//  ReceiptManager
//
//  Created by parkhyo on 2023/11/15.
//

import UIKit

final class MainTabBarCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    var window: UIWindow?
    var mainNavigationController: UINavigationController?
    var subNavigationController: UINavigationController?
    
    private let expenseRepository: ExpenseRepository
    private let currencyRepository: CurrencyRepository
    private let dateRepository: DateRepository
    
    init(
        window: UIWindow?,
        mainNavigationController: UINavigationController,
        expenseRepository: ExpenseRepository,
        currencyRepository: CurrencyRepository,
        dateRepository: DateRepository
    ) {
        self.window = window
        self.expenseRepository = expenseRepository
        self.currencyRepository = currencyRepository
        self.dateRepository = dateRepository
        self.mainNavigationController = mainNavigationController
    }
    
    func start() {
        mainNavigationController?.setNavigationBarHidden(true, animated: false)
        
        let tabBarController = CustomTabBarController()
        tabBarController.coordinator = self
        
        let coordinators = CustomTabItem.allCases.map {
            $0.initialCoordinator(
                mainNavigationController: mainNavigationController,
                subNavigationController: UINavigationController(),
                expenseRepository: expenseRepository,
                currencyRepository: currencyRepository,
                dateRepository: dateRepository
            )
        }
        
        coordinators.forEach {
            $0.start()
            $0.parentCoordinator = self
            childCoordinators.append($0)
        }
        
        let controllers = coordinators.map { $0.subNavigationController ?? UINavigationController() }
        tabBarController.setViewControllers(controllers, animated: false)
        
        mainNavigationController?.setViewControllers([tabBarController], animated: true)
        window?.rootViewController = mainNavigationController
    }
}

extension MainTabBarCoordinator {
    func showRegister() {
        let coordinator = ComposeViewCoordinator(
            transitionType: .modal,
            mainNavigationController: mainNavigationController,
            expenseRepository: expenseRepository,
            currencyRepository: currencyRepository,
            expense: nil
        )
        
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        
        coordinator.start()
    }
}
