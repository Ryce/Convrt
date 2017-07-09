//
//  CurrencySelectionViewController.swift
//  Convrt
//
//  Created by Hamon Riazy on 02/08/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit
import RealmSwift

let currencySelectionCellIdentifier = "com.ryce.convrt.currencySelectionCell"

class CurrencySelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var convrtSession: ConvrtSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: currencySelectionCellIdentifier)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(CurrencySelectionViewController.dismiss as (CurrencySelectionViewController) -> () -> ()))
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
        return convrtSession.fullCurrenyList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: currencySelectionCellIdentifier, for: indexPath)
        let currentCurrency = convrtSession.fullCurrenyList[(indexPath as NSIndexPath).row]
        tableViewCell.textLabel?.text = currentCurrency.title
        let savedCurrencies = convrtSession.savedCurrencies()
        if savedCurrencies?.contains(currentCurrency) ?? false {
            tableViewCell.accessoryType = .checkmark
        } else {
            tableViewCell.accessoryType = .none
        }
        return tableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let currentCurrency = convrtSession.fullCurrenyList[(indexPath as NSIndexPath).row]
        let realm = try! Realm()
        if let currencyInRealm = realm.object(ofType: Currency.self, forPrimaryKey: currentCurrency.code) {
            try? realm.write {
                realm.delete(currencyInRealm)
            }
        } else {
            try? realm.write {
                realm.add(currentCurrency, update: true)
            }
        }
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
}
