//  
//  RootViewController.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IRootView: class {
}

final class RootViewController: BaseNavigationController, IRootView {
    var router: IRootRouter!
    weak var interactor: IRootInteractor!
    
    override func updateDesign() {
        super.updateDesign()
        navigationBar.barTintColor = DesignBook.shared.color(.primaryBackground)
        navigationBar.titleTextAttributes = DesignBook.shared.resolveNavigationTitleAttributes()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interactor.interfaceStartup()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return DesignBook.shared.resolveStatusBarStyle()
    }
}
