//
//  CurrencySelectionViewController.swift
//  Convrt
//
//  Created by Hamon Riazy on 02/08/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

let currencySelectionCellIdentifier = "com.ryce.convrt.currencySelectionCell"

class CurrencySelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var convrtSession: ConvrtSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: currencySelectionCellIdentifier)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(CurrencySelectionViewController.dismiss))
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UITableViewDelegate & DataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convrtSession.fullCurrenyList().count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCellWithIdentifier(currencySelectionCellIdentifier, forIndexPath: indexPath)
        let currentCurrency = convrtSession.fullCurrenyList()[(indexPath as NSIndexPath).row]
        tableViewCell.textLabel?.text = currentCurrency.title
        if convrtSession.selectedCurrencies.contains(currentCurrency) {
            tableViewCell.accessoryType = .Checkmark
        } else {
            tableViewCell.accessoryType = .None
        }
        return tableViewCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let currentCurrency = convrtSession.fullCurrenyList()[(indexPath as NSIndexPath).row]
        if convrtSession.selectedCurrencies.contains(currentCurrency) {
            guard let index = convrtSession.selectedCurrencies.indexOf(currentCurrency) else { return }
            convrtSession.selectedCurrencies.removeAtIndex(index)
        } else {
            convrtSession.selectedCurrencies.append(currentCurrency)
        }
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }
    
}
