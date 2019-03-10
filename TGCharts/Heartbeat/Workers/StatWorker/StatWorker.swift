//
//  StatWorker.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol IStatWorker: class {
    var state: StatState { get }
    var stateObservable: BroadcastObservable<StatState> { get }
    func requestIfNeeded()
}

final class StatWorker: IStatWorker {
    private let jsonFilename: String
    
    private(set) var state = StatState.unknown
    let stateObservable = BroadcastObservable<StatState>()
    
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
                DispatchQueue.main.async { self?.state = .ready([]) }
                return
            }
            
            guard let chartsData = try? Data(contentsOf: chartsURL) else {
                DispatchQueue.main.async { self?.state = .ready([]) }
                return
            }
            
            if let _ = try? StatParser().parse(data: chartsData) {
                
            }
            else {
                
            }
        }
    }
}
