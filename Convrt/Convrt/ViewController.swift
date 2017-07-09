//
//  ViewController.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CurrencyEditDelegate {
    
    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var detailView: CurrencyEditView?
    
    let convrtSession = ConvrtSession()
    
    var selectedCurrency: Currency?
    var selectedCurrencyAmount: CurrencyAmount = 0.0
    
    let loadingIndicatorContainer: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        
        return view
    }()
    
    let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView!.backgroundColor = UIColor.clear
        self.detailView?.delegate = self
        self.detailView?.amountTextField?.keyboardType = UIKeyboardType.decimalPad
        
        self.collectionView!.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ViewController.showCurrencySelection)))
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        convrtSession.updateSavedCurrencyPairs()
        guard let savedCurrencyPairs = convrtSession.savedCurrencyPairs() else { return }
        self.showLoadingIndicator()
        convrtSession.fetchRatesForCurrencies(Array(savedCurrencyPairs)) { (items, error) -> () in
            self.hideLoadingIndicator()
            if error != .noError {
                let alert = UIAlertController(title: "Whoops", message: "There was a problem fetching the rates", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            self.collectionView?.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    
    func showCurrencySelection() {
        let vc = UINavigationController(rootViewController: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CurrencySelectionViewController") as! CurrencySelectionViewController)
        self.present(vc, animated: true, completion: nil)
    }
    
    func updateView(_ amount: CurrencyAmount, currency: Currency) {
        currency.currentAmount.value = amount
        self.selectedCurrencyAmount = amount
        self.selectedCurrency = currency
        // TODO: asynchronously load selected currency rates and set
        self.collectionView?.reloadData()
    }

    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return convrtSession.selectedCurrencies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ConvrtCollectionViewCell.kCellIdentifier, for: indexPath) as! ConvrtCollectionViewCell
        let currency = convrtSession.selectedCurrencies[(indexPath as NSIndexPath).row]
        cell.codeLabel?.text = currency.code
        cell.countryLabel?.text = currency.title
        if let selCurr = self.selectedCurrency, selCurr != currency {
            cell.amountLabel?.text = "" // TODO: convrt.calculateAmount(selCurr)
        } else {
            cell.amountLabel?.text = currency.displayAmount
        }
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedCurrency = convrtSession.selectedCurrencies[(indexPath as NSIndexPath).row]
        
        self.detailView?.currency = self.selectedCurrency
        self.detailView?.codeLabel?.text = self.selectedCurrency?.code
        self.detailView?.titleLabel?.text = self.selectedCurrency?.title
        if let amount = self.selectedCurrency?.displayAmount,
            selectedCurrencyAmount > 0.0 {
            self.detailView?.amountTextField?.text = amount
        } else {
            self.detailView?.amountTextField?.text = ""
        }
        self.detailView?.amountTextField?.becomeFirstResponder()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 145 * self.view.bounds.size.width/320, height: 120 * self.view.bounds.size.width/320);
    }
    
    // MARK: CurrencyEditDelegate
    
    func didDismiss(_ view: CurrencyEditView, _ currency: Currency, _ inputAmount: CurrencyAmount) {
        currency.currentAmount.value = inputAmount
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
        UIView.animate(withDuration: 0.5) { () -> Void in
            self.loadingIndicatorContainer.alpha = 1.0
        }
    }
    
    func hideLoadingIndicator() {
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.loadingIndicatorContainer.alpha = 0.0
            }) { (didFinish) -> Void in
                self.loadingIndicatorContainer.removeFromSuperview()
                self.loadingIndicator.stopAnimating()
        }
    }
    
}
