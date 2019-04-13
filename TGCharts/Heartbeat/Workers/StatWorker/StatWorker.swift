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
    private let folderName: String
    private let entryFileName: String
    
    private(set) var state = StatLoadingState.unknown
    let stateObservable = BroadcastObservable<StatLoadingState>()
    
    init(folderName: String, entryFileName: String) {
        self.folderName = folderName
        self.entryFileName = entryFileName
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
        let fm = FileManager.default
        let name = folderName
        let entry = entryFileName
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let folderURL = Bundle.main.url(forResource: name, withExtension: nil) else {
                DispatchQueue.main.async { self?.storeAndBroadcast(charts: []) }
                return
            }
            
            guard let chartsURL = fm.scan(atPath: folderURL.path) else {
                DispatchQueue.main.async { self?.storeAndBroadcast(charts: []) }
                return
            }
            
            let charts: [Chart] = chartsURL.compactMap { chartURL in
                let contentURL = folderURL.appendingPathComponent(chartURL, isDirectory: true)
                let entryURL = contentURL.appendingPathComponent(entry, isDirectory: false)
                
                guard let entryData = fm.contents(atPath: entryURL.path) else { return nil }
                guard let contents = fm.scan(atPath: contentURL.path) else { return nil }

                let specificMonths: [[URL]] = Set(contents).subtracting([entry]).map { monthName in
                    let monthURL = contentURL.appendingPathComponent(monthName, isDirectory: true)
                    let monthContents = fm.scan(atPath: monthURL.path) ?? []
                    return monthContents.map { monthURL.appendingPathComponent($0, isDirectory: false) }
                }
                
                var children = [String: URL]()
                for dateURL in specificMonths.reduce([], +) {
                    let day = dateURL.deletingPathExtension().lastPathComponent
                    let yearMonth = dateURL.deletingLastPathComponent().lastPathComponent
                    children["\(yearMonth)-\(day)"] = dateURL
                }
                
                if let chart = try? StatParser().parse(data: entryData, including: children) {
                    return chart
                }
                else {
                    return nil
                }
            }
            
            DispatchQueue.main.async { self?.storeAndBroadcast(charts: charts) }
        }
    }
    
    private func storeAndBroadcast(charts: [Chart]) {
        state = .ready(charts)
        stateObservable.broadcast(state)
    }
}

fileprivate extension FileManager {
    func scan(atPath path: String) -> [String]? {
        if let contents = try? contentsOfDirectory(atPath: path) {
            return contents
        }
        else {
            return []
        }
    }
}
