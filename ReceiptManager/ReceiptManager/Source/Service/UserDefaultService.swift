//
//  UserDefaultService.swift
//  ReceiptManager
//
//  Created by parkhyo on 11/26/23.
//

import RxSwift

protocol UserDefaultService {
    var event: BehaviorSubject<Int> { get }
    
    func fetchCurrencyIndex() -> Int
    func updateCurrency(index: Int) -> Observable<Int>
}

final class DefaultUserDefaultService: UserDefaultService {
    
    private let storage = UserDefaults.standard
    
    let event: BehaviorSubject<Int>
    
    init() {
        event = BehaviorSubject(value: storage.integer(forKey: ConstantText.currencyKey))
    }
    
    func fetchCurrencyIndex() -> Int {
        return storage.integer(forKey: ConstantText.currencyKey)
    }
    
    func updateCurrency(index: Int) -> Observable<Int> {
        storage.set(index, forKey: ConstantText.currencyKey)
        event.onNext(index)
        return Observable.just(index)
    }
}