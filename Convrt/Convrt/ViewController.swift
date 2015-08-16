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
    
    let loadingIndicatorContainer: UIView = {
        let view = UIView(frame: CGRectZero)
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        
        return view
    }()
    
    let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView!.backgroundColor = UIColor.clearColor()
        self.detailView?.delegate = self
        self.detailView?.amountTextField?.keyboardType = UIKeyboardType.DecimalPad
        
        self.collectionView!.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: Selector()))
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.showLoadingIndicator()
        ConvrtSession.sharedInstance.fetchRatesForCurrencies(genericCurrencyPairs()) { (items, error) -> () in
            self.hideLoadingIndicator()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    
    func showCurrencySelection() {
        let vc = UINavigationController(rootViewController: CurrencySelectionViewController())
        self.presentViewController(vc, animated: true, completion: nil)
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
        if let selCurr = self.selectedCurrency where selCurr != currency {
            cell.amountLabel?.text = currency.calculateAmount(selCurr)
        } else {
            cell.amountLabel?.text = currency.displayAmount()
        }
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedCurrency = ConvrtSession.sharedInstance.savedCurrencyConfiguration[indexPath.row]
        
        self.detailView?.currency = self.selectedCurrency
        self.detailView?.codeLabel?.text = self.selectedCurrency?.code
        self.detailView?.titleLabel?.text = self.selectedCurrency?.title
        if let amount = self.selectedCurrency?.displayAmount() where self.selectedCurrency?.currentAmount > 0.0 {
            self.detailView?.amountTextField?.text = amount
        } else {
            self.detailView?.amountTextField?.text = ""
        }
        self.detailView?.amountTextField?.becomeFirstResponder()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(145 * self.view.bounds.size.width/320, 120 * self.view.bounds.size.width/320);
    }
    
    
    
    
    // MARK: CurrencyEditDelegate
    
    func didDismiss(view: CurrencyEditView, _ currency: Currency, _ inputAmount: CurrencyAmount) {
        currency.currentAmount = inputAmount
        self.selectedCurrencyAmount = inputAmount
        self.selectedCurrency = currency
        // TODO: asynchronously load selected currency rates and set
        self.collectionView?.reloadData()
    }
    
    // MARK: Loading Indicator
    
    func showLoadingIndicator() {
        self.loadingIndicatorContainer.frame = self.view.bounds
        self.loadingIndicator.center = self.loadingIndicatorContainer.center
        self.view.addSubview(self.loadingIndicatorContainer)
        self.loadingIndicatorContainer.addSubview(self.loadingIndicator)
        self.loadingIndicator.startAnimating()
        self.loadingIndicatorContainer.alpha = 0.0
        UIView.animateWithDuration(0.5) { () -> Void in
            self.loadingIndicatorContainer.alpha = 1.0
        }
    }
    
    func hideLoadingIndicator() {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.loadingIndicatorContainer.alpha = 0.0
        }) { (didFinish) -> Void in
            self.loadingIndicatorContainer.removeFromSuperview()
            self.loadingIndicator.stopAnimating()
        }
    }
    
}
