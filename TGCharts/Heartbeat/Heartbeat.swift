//
//  Heartbeat.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

struct Heartbeat {
    let providers: HeartbeatProviders
    
    init() {
        let localeProvider = LocaleProvider()
        
        let formattingProvider = FormattingProvider(
            localeProvider: localeProvider
        )
        
        providers = HeartbeatProviders(
            localeProvider: localeProvider,
            formattingProvider: formattingProvider
        )
    }
}
