//
//  ViewController.swift
//  Tries
//
//  Created by Chris Eidhof on 01/04/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView?
    @IBOutlet var progressView: UIProgressView!
    
    let backgroundQueue = NSOperationQueue()

    var trie: Trie<Character>?
    var dataSource: ArrayDataSource?


    func backgroundJob<A>(block: () -> A, completion: A -> ()) {
        backgroundQueue.addOperation(asyncBlock(block, completion))
    }
    
    @IBAction func editingChanged(sender: UITextField) {
        if let words = trie where count(sender.text) > 0 {
            backgroundQueue.cancelAllOperations()
            backgroundJob({
               autocompleteString(sender.text, words)
            }) {
                self.dataSource?.items = $0
            }
            
        } else {
            dataSource?.items = []
        }
    }
    
    
    func buildTrie() {
        backgroundJob({
            // To execute this example, make sure to either run it in the simulator, or change the path below
            if let dictContents = String(contentsOfFile: "/usr/share/dict/words", encoding: NSUTF8StringEncoding, error: nil) {
                let words = dictContents.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                self.trie = buildStringTrie(words) { progress in
                    mainThread {
                        self.progressView?.progress = Float(progress)
                    }
                }
            }
        }) {
            self.progressView?.hidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildTrie()
        if let tv = tableView {
            dataSource = ArrayDataSource(tableView: tv)
            tv.dataSource = dataSource!
        }
    }
}

class ArrayDataSource: NSObject, UITableViewDataSource {
    var items: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var tableView: UITableView
    
    init(tableView: UITableView) {
        self.tableView = tableView
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
}