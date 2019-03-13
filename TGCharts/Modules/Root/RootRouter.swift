//  
//  RootRouter.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

func RootModuleAssembly(window: UIWindow, heartbeat: IHeartbeat) -> Module<IRootRouter> {
    let router = RootRouter(window: window, heartbeat: heartbeat)
    return .init(router: router, viewController: router.viewController)
}

protocol IRootRouter: IBaseRouter {
    func displayStat()
}

final class RootRouter: IRootRouter {
    private let window: UIWindow
    private let heartbeat: IHeartbeat
    private let interactor: IRootInteractor
    private weak var internalViewController: RootViewController?
    
    private weak var statRouter: IStatRouter?
    private var snapshotWindow: UIWindow?
    
    init(window: UIWindow, heartbeat: IHeartbeat) {
        self.window = window
        self.heartbeat = heartbeat
        
        interactor = RootInteractor(heartbeat: heartbeat)
    }
    
    var viewController: UIViewController {
        if let vc = internalViewController {
            return vc
        }
        else {
            let vc = RootViewController(designObservable: DesignBook.shared.styleObservable)
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
    
    private func presentSnapshot(whileExecuting block: @escaping () -> Void) {
        guard let snapshot = viewController.view.snapshotView(afterScreenUpdates: false) else {
            return
        }
        
        window.addSubview(snapshot)
        
        // let the system to finish its current drawings
        DispatchQueue.main.async {
            block()
            
            UIView.animate(
                withDuration: 0.15,
                animations: { snapshot.alpha = 0 },
                completion: { _ in snapshot.removeFromSuperview() }
            )
        }
    }
}
