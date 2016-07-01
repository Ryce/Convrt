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
    
    var tableViewItems = ConvrtSession.sharedInstance.fullCurrenyList
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: currencySelectionCellIdentifier)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: Selector("dismiss"))
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: UITableViewDelegate & DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: currencySelectionCellIdentifier, for: indexPath)
        let currentCurrency = tableViewItems[(indexPath as NSIndexPath).row]
        tableViewCell.textLabel?.text = currentCurrency.title
        if ConvrtSession.sharedInstance.savedCurrencyConfiguration.contains(currentCurrency) {
            tableViewCell.accessoryType = .checkmark
        } else {
            tableViewCell.accessoryType = .none
        }
        return tableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let currentCurrency = tableViewItems[(indexPath as NSIndexPath).row]
        if ConvrtSession.sharedInstance.savedCurrencyConfiguration.contains(currentCurrency) {
            guard let index = ConvrtSession.sharedInstance.savedCurrencyConfiguration.index(of: currentCurrency) else { return }
            ConvrtSession.sharedInstance.savedCurrencyConfiguration.remove(at: index)
        } else {
            ConvrtSession.sharedInstance.savedCurrencyConfiguration.append(currentCurrency)
        }
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
}
