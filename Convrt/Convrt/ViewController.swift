//
//  ViewController.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit

// TODO: switch back to UIViewController + iboutlet UICollectionViewDelegate & DataSource
class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var detailView: CurrencyEditView?
    
    var selectedCurrency: Currency?
    var selectedCurrencyAmount: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView!.backgroundColor = UIColor.whiteColor()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        
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
        return ConvrtSession.sharedInstance.fullCurrenyList.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ConvrtCollectionViewCell.kCellIdentifier, forIndexPath: indexPath) as! ConvrtCollectionViewCell
        cell.codeLabel?.text = ConvrtSession.sharedInstance.fullCurrenyList[indexPath.row].code
        cell.countryLabel?.text = ConvrtSession.sharedInstance.fullCurrenyList[indexPath.row].title
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedCurrency = ConvrtSession.sharedInstance.fullCurrenyList[indexPath.row]
        self.detailView?.codeLabel?.text = self.selectedCurrency?.code
        self.detailView?.titleLabel?.text = self.selectedCurrency?.title
        self.detailView?.amountTextField?.becomeFirstResponder()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(145 * self.view.bounds.size.width/320, 145 * self.view.bounds.size.width/320);
    }
    
}
