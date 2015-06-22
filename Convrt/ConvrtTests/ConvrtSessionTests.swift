//
//  ConvrtSessionTests.swift
//  Convrt
//
//  Created by Hamon Riazy on 20/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit
import XCTest
@testable import Convrt

class ConvrtSessionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testFullCurrencyList() {
        let currencyList = ConvrtSession.sharedInstance.savedCurrencyConfiguration
        
        XCTAssert(!currencyList.isEmpty)
    }
    
    func testYQLConstructor() {
        let usd = Currency(name: "", identifier: "USD")
        let eur = Currency(name: "", identifier: "EUR")
        let gbp = Currency(name: "", identifier: "GBP")
        let currencies = [CurrencyPair(fromCurrency: usd, toCurrency: eur), CurrencyPair(fromCurrency: usd, toCurrency: gbp)]
        
        let yqlString = ConvrtSession.sharedInstance.constructYQL(currencies)
        
        XCTAssertNotNil(yqlString)
        XCTAssertGreaterThan(yqlString.characters.count, 0)
    }
    
    func testConversion() {
        let usd = Currency(name: "US Dollar", identifier: "USD")
        let eur = Currency(name: "Euro", identifier: "EUR")
        let gbp = Currency(name: "Pound Sterling", identifier: "GBP")
        let hkd = Currency(name: "Hong Kong Dollar", identifier: "HKD")
        let currencyArray = [CurrencyPair(fromCurrency: usd, toCurrency: hkd),
            CurrencyPair(fromCurrency: eur, toCurrency: gbp),
            CurrencyPair(fromCurrency: usd, toCurrency: eur)]
        
        let expectation = self.expectationWithDescription("fetchRates Expectation")
        
        var optionalItems: [CurrencyPair]?
        var optionalError: ConvrtError?
        
        ConvrtSession.sharedInstance.fetchRatesForCurrencies(currencyArray, completion: { (items, error) -> () in
            
            optionalItems = items
            optionalError = error
            
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(30, handler: nil)
        
        if let actualItems = optionalItems {
            if actualItems.count != 3 {
                XCTFail()
            }
        } else {
            XCTFail()
        }
        
        if let actualError = optionalError {
            if actualError != .NoError {
                XCTFail()
            }
        } else {
            XCTFail()
        }
        
    }
    
}
