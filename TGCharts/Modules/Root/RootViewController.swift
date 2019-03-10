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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isFirstLoad {
            interactor.interfaceStartup()
        }
        else {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return DesignBook.shared.resolveStatusBarStyle()
    }
}
