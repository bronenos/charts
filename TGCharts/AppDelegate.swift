//
//  AppDelegate.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private weak var rootRouter: IRootRouter?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let module = RootModuleAssembly(heartbeat: Heartbeat())
        rootRouter = module.router
        
        window.rootViewController = module.viewController
        window.makeKeyAndVisible()
        
        return true
    }
}
