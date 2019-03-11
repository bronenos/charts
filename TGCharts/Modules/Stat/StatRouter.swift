//  
//  StatRouter.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

func StatModuleAssembly(heartbeat: IHeartbeat) -> Module<IStatRouter> {
    let router = StatRouter(heartbeat: heartbeat)
    return .init(router: router, viewController: router.viewController)
}

protocol IStatRouter: IBaseRouter {
    func configureHandlers(designToggleHandler: @escaping () -> Void)
    func toggleDesign()
}

final class StatRouter: IStatRouter {
    private let heartbeat: IHeartbeat
    private let interactor: IStatInteractor
    private weak var internalViewController: StatViewController?
    
    private var designToggleHandler: (() -> Void)?
    
    init(heartbeat: IHeartbeat) {
        self.heartbeat = heartbeat
        
        interactor = StatInteractor(heartbeat: heartbeat)
    }
    
    var viewController: UIViewController {
        if let vc = internalViewController {
            return vc
        }
        else {
            let vc = StatViewController(designObservable: DesignBook.shared.styleObservable)
            vc.router = self
            vc.interactor = interactor
            internalViewController = vc

            interactor.router = self
            interactor.view = vc
            
            return vc
        }
    }
    
    func recursiveReload() {
        internalViewController?.view = nil
    }
    
    func configureHandlers(designToggleHandler: @escaping () -> Void) {
        self.designToggleHandler = designToggleHandler
    }
    
    func toggleDesign() {
        designToggleHandler?()
    }
}
