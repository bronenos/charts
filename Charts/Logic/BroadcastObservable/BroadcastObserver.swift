//
//  BroadcastObserver.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

typealias BroadcastObserverID = UUID

final class BroadcastObserver<VT> {
    let ID: BroadcastObserverID
    private weak var broadcastObservable: BroadcastObservable<VT>?
    
    init(ID: BroadcastObserverID, broadcastObservable: BroadcastObservable<VT>) {
        self.ID = ID
        self.broadcastObservable = broadcastObservable
    }
    
    deinit {
        broadcastObservable?.removeObserver(self)
    }
}
