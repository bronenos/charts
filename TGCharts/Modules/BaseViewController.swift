//
//  BaseViewController.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

class BaseViewController: UIViewController {
    private var numberOfLoads = 0
    
    var isFirstLoad: Bool {
        return (numberOfLoads == 1)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignBook.shared.resolve(colorAlias: .generalBackground)
        numberOfLoads += 1
    }
    
    func setTitle(_ title: String) {
        navigationItem.title = title
    }
}
