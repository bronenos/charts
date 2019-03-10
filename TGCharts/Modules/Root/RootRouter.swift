//  
//  RootRouter.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

func RootModuleAssembly(heartbeat: IHeartbeat) -> Module<IRootRouter> {
    let router = RootRouter(heartbeat: heartbeat)
    return .init(router: router, viewController: router.viewController)
}

protocol IRootRouter: IBaseRouter {
    func displayStat()
}

final class RootRouter: IRootRouter {
    private let heartbeat: IHeartbeat
    private let interactor: IRootInteractor
    private weak var internalViewController: RootViewController?
    
    private weak var statRouter: IStatRouter?
    
    init(heartbeat: IHeartbeat) {
        self.heartbeat = heartbeat
        
        interactor = RootInteractor(heartbeat: heartbeat)
    }
    
    var viewController: UIViewController {
        if let vc = internalViewController {
            return vc
        }
        else {
            let vc = RootViewController()
            vc.router = self
            vc.interactor = interactor
            internalViewController = vc

            interactor.router = self
            interactor.view = vc
            
            return vc
        }
    }
    
    func displayStat() {
        let module = StatModuleAssembly(heartbeat: heartbeat)
        statRouter = module.router
        
        module.router.configureHandlers(
            designToggleHandler: { [weak self] in
                self?.presentSnapshot(
                    whileExecuting: { self?.interactor.toggleDesign() }
                )
            }
        )
        
        internalViewController?.viewControllers = [module.viewController]
    }
    
    func recursiveReload() {
        internalViewController?.view = nil
        statRouter?.recursiveReload()
    }
    
    private func presentSnapshot(whileExecuting block: () -> Void) {
        guard let snapshot = internalViewController?.view.snapshotView(afterScreenUpdates: false) else {
            return
        }
        
        let vc = UIViewController()
        vc.view.addSubview(snapshot)
        
        internalViewController?.present(vc, animated: false, completion: nil)
        block()
        internalViewController?.dismiss(animated: false, completion: nil)
    }
}
