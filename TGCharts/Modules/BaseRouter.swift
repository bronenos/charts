//
//  BaseRouter.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IBaseRouter: class {
    var viewController: UIViewController { get }
}

struct Module<RT> {
    let router: RT
    let viewController: UIViewController
}
