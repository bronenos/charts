//
//  BaseViewController.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

class BaseViewController: UIViewController, DesignBookUpdatable {
    private var designObserver: BroadcastObserver<DesignBookStyle>?
    
    init(designObservable: BroadcastObservable<DesignBookStyle>) {
        super.init(nibName: nil, bundle: nil)
        
        designObserver = designObservable.addObserver { [weak self] _ in
            self?.updateDesign()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDesign()
    }
    
    func setTitle(_ title: String) {
        navigationItem.title = title
    }
    
    func updateDesign() {
        view.backgroundColor = DesignBook.shared.resolve(colorAlias: .generalBackground)
    }
}
