//
//  PTermsAndConditionViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 23/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

class PTermsAndConditionViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadHtmlFile()
        // Do any additional setup after loading the view.
    }
    

    func loadHtmlFile() {
        let url = Bundle.main.url(forResource: "T&C", withExtension:"html")
        let request = NSURLRequest(url: url!)
        webView.loadRequest(request as URLRequest)
    }
}
