//
//  CurrencyPair.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation
import CoreData
import SugarRecord

class CurrencyPair: NSManagedObject {
    
    @NSManaged var fromCurrency: Currency
    @NSManaged var toCurrency: Currency
    
    @NSManaged var rate: Double
    
    static func create(withDatabase db: CoreDataDefaultStorage, callBack: (result: CurrencyPair?) -> ()) {
        do {
            try db.operation({ (context, save) -> Void in
                let newTask: CurrencyPair = try! context.new()
                save()
                callBack(result: newTask)
            })
        }
        catch {
            callBack(result: nil)
            // There was an error in the operation
        }
    }
    
    func merge(otherCurrencyPair: CurrencyPair) {
        self.rate = otherCurrencyPair.rate
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let currencyPair = object as? CurrencyPair else { return false }
        return self.fromCurrency == currencyPair.fromCurrency && self.toCurrency == currencyPair.toCurrency
    }
    
}

func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
    return lhs.fromCurrency == rhs.fromCurrency && lhs.toCurrency == rhs.toCurrency
}
