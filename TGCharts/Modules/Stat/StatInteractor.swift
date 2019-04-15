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
    var localeProvider: ILocaleProvider { get }
    var formattingProvider: IFormattingProvider { get }
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
            guard case .ready(let metas) = value else { return }
            self?.view.setChartMetas(metas)
        }
    }
    
    var localeProvider: ILocaleProvider {
        return heartbeat.providers.localeProvider
    }
    
    var formattingProvider: IFormattingProvider {
        return heartbeat.providers.formattingProvider
    }
    
    func interfaceStartup() {
        view.setTitle(heartbeat.localized(key: "Stat.Title"))
        updateDesignSwitcher()
        heartbeat.workers.statWorker.requestIfNeeded()
    }
    
    func toggleDesign() {
        switch DesignBook.shared.style {
        case .light: view.setDesignSwitcher(title: heartbeat.localized(key: "Stat.Mode.Light"))
        case .dark: view.setDesignSwitcher(title: heartbeat.localized(key: "Stat.Mode.Dark"))
        }
        
        router.toggleDesign()
    }
    
    private func updateDesignSwitcher() {
        switch DesignBook.shared.style {
        case .light: view.setDesignSwitcher(title: heartbeat.localized(key: "Stat.Mode.Dark"))
        case .dark: view.setDesignSwitcher(title: heartbeat.localized(key: "Stat.Mode.Light"))
        }
    }
}
