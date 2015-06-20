//
//  ViewController.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.registerClass(ConvrtCollectionViewCell.self, forCellWithReuseIdentifier: ConvrtCollectionViewCell.kCellIdentifier)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func submitMessage() {
        let usd = Currency(name: "US Dollar", identifier: "USD")
        let eur = Currency(name: "Euro", identifier: "EUR")
        let gbp = Currency(name: "Pound Sterling", identifier: "GBP")
        let hkd = Currency(name: "Hong Kong Dollar", identifier: "HKD")
        let currencyArray = [CurrencyPair(fromCurrency: usd, toCurrency: hkd, rate: nil),
            CurrencyPair(fromCurrency: eur, toCurrency: gbp, rate: nil),
            CurrencyPair(fromCurrency: usd, toCurrency: eur, rate: nil)]
        ConvrtSession.sharedInstance.fetchRatesForCurrencies(currencyArray, completion: { (items, error) -> () in
            
        })
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ConvrtCollectionViewCell.kCellIdentifier, forIndexPath: indexPath)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // TODO:
    }
    
}

