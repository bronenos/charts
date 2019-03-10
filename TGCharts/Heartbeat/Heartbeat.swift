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
}

final class Heartbeat: IHeartbeat {
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
        
        DesignBook.setShared(LightDesignBook())
    }
}

extension IHeartbeat {
    func localized(key: String) -> String {
        return providers.localeProvider.localize(key: key)
    }
}
