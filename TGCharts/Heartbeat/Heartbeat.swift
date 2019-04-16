//
//  Heartbeat.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol IHeartbeat: class {
    var providers: HeartbeatProviders { get }
    var drivers: HeartbeatDrivers { get }
    var workers: HeartbeatWorkers { get }
}

final class Heartbeat: IHeartbeat {
    let providers: HeartbeatProviders
    let drivers: HeartbeatDrivers
    let workers: HeartbeatWorkers
    
    init() {
        let localeProvider = LocaleProvider()
        
        let formattingProvider = FormattingProvider(
            localeProvider: localeProvider
        )
        
        providers = HeartbeatProviders(
            localeProvider: localeProvider,
            formattingProvider: formattingProvider
        )
        
        let feedbackDriver = FeedbackDriver()
        
        drivers = HeartbeatDrivers(
            feedbackDriver: feedbackDriver
        )
        
        let statWorker = StatWorker(
            localeProvider: localeProvider,
            folderName: "graph_data",
            entryFileName: "overview.json"
        )
        
        workers = HeartbeatWorkers(
            statWorker: statWorker
        )
        
        DesignBook.setShared(LightDesignBook())
    }
}

extension IHeartbeat {
    func localized(key: String) -> String {
        return providers.localeProvider.localize(key: key)
    }
}
