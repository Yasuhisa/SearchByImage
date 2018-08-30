//
//  WalkthroughViewController.swift
//  SearchByImage
//
//  Created by arakawa.yasuhisa on 2018/08/30.
//  Copyright © 2018年 yasuhisa.arakawa. All rights reserved.
//

import UIKit
import BWWalkthrough

class WalkthroughViewController: BWWalkthroughViewController, BWWalkthroughViewControllerDelegate {
    
    private lazy var endPageIndex = self.pageControl?.numberOfPages
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let page1 = self.storyboard?.instantiateViewController(withIdentifier: Constants.VIEWCONTROLLER_WALKTHROUGH_FIRST)
        let page2 = self.storyboard?.instantiateViewController(withIdentifier: Constants.VIEWCONTROLLER_WALKTHROUGH_SECOND)
        let pageEnd = self.storyboard?.instantiateViewController(withIdentifier: Constants.VIEWCONTROLLER_WALKTHROUGH_END)
        
        self.add(viewController: page1 ?? UIViewController())
        self.add(viewController: page2 ?? UIViewController())
        self.add(viewController: pageEnd ?? UIViewController())
        
        // set BWWalkthroughViewControllerDelegate
        super.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func walkthroughCloseButtonPressed() {
        let storybord = UIStoryboard(name: Constants.STORYBOARD_CAMERA, bundle: nil)
        let cameraViewController = storybord.instantiateInitialViewController()
        
        let window = UIApplication.shared.keyWindow
        window?.rootViewController = cameraViewController
        window?.makeKeyAndVisible()
    }
    
    func walkthroughPageDidChange(_ pageNumber: Int) {
        if pageNumber + 1 == endPageIndex {
            // TODO: Use localize string
            self.closeButton?.setTitle("わかった", for: .normal)
        } else {
            // TODO: Use localize string
            super.closeButton?.setTitle("スキップ", for: .normal)
        }
    }
    
}
