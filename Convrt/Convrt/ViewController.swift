//
//  ViewController.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit

// TODO: switch back to UIViewController + iboutlet UICollectionViewDelegate & DataSource
class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CurrencyEditDelegate {
    
    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var detailView: CurrencyEditView?
    
    var selectedCurrency: Currency?
    var selectedCurrencyAmount: CurrencyAmount = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView!.backgroundColor = UIColor.whiteColor()
        self.detailView?.delegate = self
        self.detailView?.amountTextField?.keyboardType = UIKeyboardType.DecimalPad
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ConvrtSession.sharedInstance.savedCurrencyConfiguration.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ConvrtCollectionViewCell.kCellIdentifier, forIndexPath: indexPath) as! ConvrtCollectionViewCell
        let currency = ConvrtSession.sharedInstance.savedCurrencyConfiguration[indexPath.row]
        cell.codeLabel?.text = currency.code
        cell.countryLabel?.text = currency.title
        cell.amountLabel?.text = NSString(format: "%.2lf", currency.currentAmount) as String
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedCurrency = ConvrtSession.sharedInstance.savedCurrencyConfiguration[indexPath.row]
        
        self.detailView?.currency = self.selectedCurrency
        self.detailView?.codeLabel?.text = self.selectedCurrency?.code
        self.detailView?.titleLabel?.text = self.selectedCurrency?.title
        self.detailView?.amountTextField?.text = ""
        self.detailView?.amountTextField?.becomeFirstResponder()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(145 * self.view.bounds.size.width/320, 145 * self.view.bounds.size.width/320);
    }
    
    // MARK: CurrencyEditDelegate
    
    func didDismiss(view: CurrencyEditView, _ currency: Currency, _ inputAmount: CurrencyAmount) {
        currency.currentAmount = inputAmount
        self.selectedCurrencyAmount = inputAmount
        self.selectedCurrency = currency
        // TODO: asynchronously load selected currency rates and set
        self.collectionView?.reloadData()
    }
    
}
