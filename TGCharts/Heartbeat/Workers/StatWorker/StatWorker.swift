//
//  StatWorker.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol IStatWorker: class {
    var state: StatLoadingState { get }
    var stateObservable: BroadcastObservable<StatLoadingState> { get }
    func requestIfNeeded()
}

final class StatWorker: IStatWorker {
    private let jsonFilename: String
    
    private(set) var state = StatLoadingState.unknown
    let stateObservable = BroadcastObservable<StatLoadingState>()
    
    init(jsonFilename: String) {
        self.jsonFilename = jsonFilename
    }

    func requestIfNeeded() {
        switch state {
        case .unknown:
            state = .waiting
            readAndParse()
            
        case .waiting:
            return
            
        case .ready:
            stateObservable.broadcast(state)
        }
    }
    
    private func readAndParse() {
        let filename = jsonFilename
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let chartsURL = Bundle.main.url(forResource: filename, withExtension: "json") else {
                DispatchQueue.main.async { self?.storeAndBroadcast(charts: []) }
                return
            }
            
            guard let chartsData = try? Data(contentsOf: chartsURL) else {
                DispatchQueue.main.async { self?.storeAndBroadcast(charts: []) }
                return
            }
            
            if let charts = try? StatParser().parse(data: chartsData) {
                DispatchQueue.main.async { self?.storeAndBroadcast(charts: charts) }
            }
            else {
                DispatchQueue.main.async { self?.storeAndBroadcast(charts: []) }
            }
        }
    }
    
    private func storeAndBroadcast(charts: [StatChart]) {
        state = .ready(charts)
        stateObservable.broadcast(state)
    }
}
