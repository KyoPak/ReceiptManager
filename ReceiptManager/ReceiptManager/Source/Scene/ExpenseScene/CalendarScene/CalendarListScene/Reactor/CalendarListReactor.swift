//
//  CalendarListReactor.swift
//  ReceiptManager
//
//  Created by parkhyo on 12/5/23.
//

import ReactorKit

final class CalendarListReactor: Reactor {
    
    // Reactor Properties
    
    enum Action { 
        case loadData
        case cellBookMark(IndexPath)
        case cellDelete(IndexPath)
    }
    
    enum Mutation {
        case updateDateTitle(String)
        case updateExpenseList([Receipt])
        case updateAmount(String)
        case onError(StorageServiceError?)
    }
    
    struct State {
        var dateTitle: String
        var day: String
        var weekIndex: Int
        var expenseByDay: [Receipt]
        var amountByDay: String
        var dataError: StorageServiceError?
    }
    
    let initialState: State
    
    // Properties
    
    private let storageService: StorageService
    private let dateManageService: DateManageService
    let userDefaultEvent: BehaviorSubject<Int>
    
    // Initializer
    
    init(
        storageService: StorageService,
        userDefaultService: UserDefaultService,
        dateManageService: DateManageService,
        day: String,
        weekIndex: Int
    ) {
        self.storageService = storageService
        self.userDefaultEvent = userDefaultService.event
        self.dateManageService = dateManageService
        
        initialState = State(
            dateTitle: "",
            day: day,
            weekIndex: weekIndex % 7,
            expenseByDay: [], 
            amountByDay: ""
        )
    }
    
    // Reactor Method
    
    func mutate(action: Action) -> Observable<Mutation> { 
        switch action {
        case .loadData:
            return Observable.concat([
                Observable.just(Mutation.updateDateTitle(updateDate())),
                loadData().flatMap({ [weak self] models in
                    return Observable.concat([
                        Observable.just(Mutation.updateExpenseList(models)),
                        Observable.just(Mutation.updateAmount(self?.updateAmount(models) ?? "" ))
                    ])
                })
            ])
            
        case .cellBookMark(let indexPath):
            var expense = currentState.expenseByDay[indexPath.row]
            expense.isFavorite.toggle()
            return storageService.upsert(receipt: expense)
                .withUnretained(self)
                .flatMap { (owner, _) in
                    owner.loadData().map { models in
                        Mutation.updateExpenseList(models)}
                }
                .catchAndReturn(Mutation.onError(StorageServiceError.entityUpdateError))
                .flatMap { mutation in
                    return Observable.concat([
                        Observable.just(mutation),
                        Observable.just(Mutation.onError(nil))
                    ])
                }
            
        case .cellDelete(let indexPath):
            let expense = currentState.expenseByDay[indexPath.row]
            return storageService.delete(receipt: expense)
                .withUnretained(self)
                .flatMap { (owner, _) in
                    owner.loadData().map { models in
                        Mutation.updateExpenseList(models)}
                }
                .catchAndReturn(Mutation.onError(StorageServiceError.entityDeleteError))
                .flatMap { mutation in
                    return Observable.concat([
                        Observable.just(mutation),
                        Observable.just(Mutation.onError(nil))
                    ])
                }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .updateDateTitle(let title):
            newState.dateTitle = title
        
        case .updateExpenseList(let models):
            newState.expenseByDay = models
            
        case .updateAmount(let amount):
            newState.amountByDay = amount
            
        case .onError(let error):
            newState.dataError = error
        }
        
        return newState
    }
}

extension CalendarListReactor {
    private func loadData() -> Observable<[Receipt]> {
        return storageService.fetch()
            .distinctUntilChanged()
            .withUnretained(self)
            .map { (owner, item) in
                owner.filterData(for: item)
            }
    }
    
    private func filterData(for data: [Receipt]) -> [Receipt] {
        let dayFormat = ConstantText.dateFormatFull.localize()
        let currentDate = updateDate()
        
        return data.filter { expense in
            let expenseDate = DateFormatter.string(from: expense.receiptDate, dayFormat)
            return expenseDate == currentDate
        }
    }
}

extension CalendarListReactor {
    private func updateDate() -> String {
        let date = (try? dateManageService.currentDateEvent.value()) ?? Date()
        
        let day = currentState.day
        let month = DateFormatter.month(from: date)
        let year = DateFormatter.year(from: date)
        
        let newDate = createDateFromComponents(year: year, month: month, day: Int(day))
        return DateFormatter.string(from: newDate ?? Date(), ConstantText.dateFormatFull.localize())
    }
    
    private func createDateFromComponents(year: Int?, month: Int?, day: Int?) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        let calendar = Calendar.current
        return calendar.date(from: dateComponents)
    }
    
    private func updateAmount(_ expenses: [Receipt]) -> String {
        var totalAmount: Double = .zero
        
        for expense in expenses {
            totalAmount += Double(expense.priceText) ?? .zero
        }
        
        return NumberFormatter.numberDecimal(from: totalAmount.convertString())
    }
}
