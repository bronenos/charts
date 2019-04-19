//
//  BroadcastObservable.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

class BroadcastObservable<VT> {
    typealias Observer = (VT) -> Void
    
    private var observers = [(UUID, Observer)]()
    private(set) var lastValue: VT?
    private(set) var previousValue: VT?
    
    func addObserver(_ observer: @escaping Observer) -> BroadcastObserver<VT> {
        let id = UUID()
        observers.append((id, observer))
        return BroadcastObserver(ID: id, broadcastObservable: self)
    }
    
    func removeObserver(_ observer: BroadcastObserver<VT>) {
        let id = observer.ID
        let ids = observers.map { $0.0 }
        
        if let index = ids.firstIndex(of: id) {
            observers.remove(at: index)
        }
    }
    
    func broadcast(_ value: VT) {
        previousValue = lastValue
        lastValue = value
        
        observers.forEach { observer in
            observer.1(value)
        }
    }
}
