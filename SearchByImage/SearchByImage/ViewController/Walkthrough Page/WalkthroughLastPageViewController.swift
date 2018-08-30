//
//  WalkthroughLastPageViewController.swift
//  SearchByImage
//
//  Created by arakawa.yasuhisa on 2018/08/30.
//  Copyright © 2018年 yasuhisa.arakawa. All rights reserved.
//

import UIKit

class WalkthroughEndPageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Constants.FIRST_START) {
            // when first start, display walkthrough
            defaults.set(true, forKey: Constants.FIRST_START)
            defaults.synchronize()
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
