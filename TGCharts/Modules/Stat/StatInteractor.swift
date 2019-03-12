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
    func toggleDesign()
}

final class StatInteractor: IStatInteractor {
    private let heartbeat: IHeartbeat

    weak var router: IStatRouter!
    weak var view: IStatView!
    
    private var statObserver: BroadcastObserver<StatLoadingState>?
    
    init(heartbeat: IHeartbeat) {
        self.heartbeat = heartbeat
        
        statObserver = heartbeat.workers.statWorker.stateObservable.addObserver { [weak self] value in
            guard case .ready(let charts) = value else { return }
            let prefix = heartbeat.localized(key: "Stat.Section.TitlePrefix")
            self?.view.setCharts(titlePrefix: prefix, charts: charts)
        }
    }
    
    func interfaceStartup() {
        view.setTitle(heartbeat.localized(key: "Stat.Title"))
        updateDesignSwitcher()
        heartbeat.workers.statWorker.requestIfNeeded()
    }
    
    func toggleDesign() {
        router.toggleDesign()
        updateDesignSwitcher()
    }
    
    private func updateDesignSwitcher() {
        switch DesignBook.shared.style {
        case .light: view.setDesignSwitcher(title: heartbeat.localized(key: "Stat.Mode.Dark"))
        case .dark: view.setDesignSwitcher(title: heartbeat.localized(key: "Stat.Mode.Light"))
        }
    }
}
