//
//  ListViewController.swift
//  ReceiptManager
//
//  Created by parkhyo on 2023/05/02.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx

final class ListViewController: UIViewController, ViewModelBindable {
    var viewModel: ListViewModel?
    
    // MARK: - UIComponent
    private var headerView = UIView()
    
    private var monthLabel: UILabel = {
        let label = UILabel()
        label.text = "2023년 04월"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .body)
        
        return label
    }()
    
    private var previousButton: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        
        return button
    }()
    
    private var nextButton: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        
        return button
    }()
    
    private var nowButton: UIButton = {
        let button = UIButton()
        button.setTitle("현재 달", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.setTitleColor(ConstantColor.backGrouncColor, for: .normal)
        button.backgroundColor = ConstantColor.listColor
        button.layer.cornerRadius = 5
        
        return button
    }()
    
    private var tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupView()
        setupTableView()
        setupConstraints()
    }
    
    func bindViewModel() {
        guard let viewModel = viewModel else { return }
        
        // ViewModel Properties Binding
        viewModel.title
            .drive(navigationItem.rx.title)
            .disposed(by: rx.disposeBag)
        
        viewModel.receiptList
            .bind(to: tableView.rx.items(dataSource: viewModel.dataSource))
            .disposed(by: rx.disposeBag)
        
        viewModel.currentDate
            .map({ date in
                return DateFormatter.string(from: date, format: "yyyy년 MM월")
            })
            .drive(monthLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        // Button Binding
        previousButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel?.movePriviousAction()
            })
            .disposed(by: rx.disposeBag)
        
        nextButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel?.moveNextAction()
            })
            .disposed(by: rx.disposeBag)
        
        nowButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel?.moveNowAction()
            })
            .disposed(by: rx.disposeBag)
        
        tableView.rx.setDelegate(self)
            .disposed(by: rx.disposeBag)
    }
}

// MARK: - UITableViewDelegate
extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let data = viewModel?.dataSource[section]
        
        let string = data?.identity
        
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .white
        label.text = string
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // 해당 방법은 HeaderView라는 식별자를 가진 View를 새로 만든다.
        let headerView = UITableViewHeaderFooterView(reuseIdentifier: "HeaderView")

        headerView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.contentView.leadingAnchor, constant: 15),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

// MARK: - UIConstraint
extension ListViewController {
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ConstantColor.backGrouncColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.backItem?.title = "뒤로가기"
    }
    
    private func setupView() {
        [headerView, tableView].forEach(view.addSubview(_:))
        [monthLabel, previousButton, nextButton, nowButton].forEach(headerView.addSubview(_:))
        [headerView, monthLabel, previousButton, nextButton, nowButton, tableView]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        view.backgroundColor = ConstantColor.backGrouncColor
    }
    
    private func setupTableView() {
        tableView.backgroundColor = ConstantColor.backGrouncColor
        tableView.register(ListTableViewCell.self, forCellReuseIdentifier: ListTableViewCell.identifier)
    }
    
    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            headerView.heightAnchor.constraint(equalTo: safeArea.heightAnchor, multiplier: 0.1),
            
            monthLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            monthLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            previousButton.widthAnchor.constraint(equalToConstant: 45),
            previousButton.heightAnchor.constraint(equalToConstant: 45),
            previousButton.trailingAnchor.constraint(equalTo: monthLabel.leadingAnchor, constant: -5),
            previousButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            nextButton.leadingAnchor.constraint(equalTo: monthLabel.trailingAnchor, constant: 5),
            nextButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            
            nowButton.widthAnchor.constraint(equalToConstant: 60),
            nowButton.heightAnchor.constraint(equalToConstant: 30),
            nowButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -30),
            nowButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }
}
