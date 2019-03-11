//  
//  RootInteractor.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol IRootInteractor: IBaseInteractor {
    var router: IRootRouter! { get set }
    var view: IRootView! { get set }
    func toggleDesign()
}

final class RootInteractor: IRootInteractor {
    private let heartbeat: IHeartbeat

    weak var router: IRootRouter!
    weak var view: IRootView!
    
    init(heartbeat: IHeartbeat) {
        self.heartbeat = heartbeat
    }
    
    func interfaceStartup() {
        router.displayStat()
    }
    
    func toggleDesign() {
        switch DesignBook.shared.style {
        case .light: DesignBook.setShared(DarkDesignBook())
        case .dark: DesignBook.setShared(LightDesignBook())
        }
    }
}
