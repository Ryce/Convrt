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
        let usd = Currency("", "USD", "")
        let eur = Currency("", "EUR", "")
        let gbp = Currency("", "GBP", "")
        let currencies = [CurrencyPair(usd, eur), CurrencyPair(usd, gbp)]
        
        let yqlString = ConvrtSession.sharedInstance.constructYQL(currencies)
        
        XCTAssertNotNil(yqlString)
        XCTAssertGreaterThan(yqlString.characters.count, 0)
    }
    
    func testConversion() {
        let usd = Currency("US Dollar", "USD", "")
        let eur = Currency("Euro", "EUR", "")
        let gbp = Currency("Pound Sterling", "GBP", "")
        let hkd = Currency("Hong Kong Dollar", "HKD", "")
        let currencyArray = [CurrencyPair(usd, hkd),
            CurrencyPair(eur, gbp),
            CurrencyPair(usd, eur)]
        
        let expectation = self.expectationWithDescription("fetchRates Expectation")
        
        var succeed = false
        var optionalError: ConvrtError?
        
        ConvrtSession.sharedInstance.fetchRatesForCurrencies(currencyArray, completion: { (didSucceed, error) -> () in
            
            succeed = didSucceed
            optionalError = error
            
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(30, handler: nil)
        
        if !succeed {
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
