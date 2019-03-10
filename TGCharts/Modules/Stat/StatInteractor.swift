//  
//  StatInteractor.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol IStatInteractor: IBaseInteractor {
    var router: IStatRouter! { get set }
    var view: IStatView! { get set }
}

final class StatInteractor: IStatInteractor {
    private let heartbeat: IHeartbeat

    weak var router: IStatRouter!
    weak var view: IStatView!
    
    init(heartbeat: IHeartbeat) {
        self.heartbeat = heartbeat
    }
    
    func interfaceStartup() {
        view.setTitle(heartbeat.localized(key: "Stat.Title"))
        
        switch DesignBook.shared.style {
        case .light: view.configureModeSwitcher(title: heartbeat.localized(key: "Stat.Mode.Dark"))
        case .dark: view.configureModeSwitcher(title: heartbeat.localized(key: "Stat.Mode.Light"))
        }
        
        heartbeat.workers.statWorker.requestIfNeeded()
    }
}
