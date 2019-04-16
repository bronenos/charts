//
//  StatWorker.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IStatWorker: class {
    var state: StatLoadingState { get }
    var stateObservable: BroadcastObservable<StatLoadingState> { get }
    func requestIfNeeded()
}

final class StatWorker: IStatWorker {
    private let localeProvider: ILocaleProvider
    private let folderName: String
    private let entryFileName: String
    
    private(set) var state = StatLoadingState.unknown
    let stateObservable = BroadcastObservable<StatLoadingState>()
    
    init(localeProvider: ILocaleProvider, folderName: String, entryFileName: String) {
        self.localeProvider = localeProvider
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
            
            guard let chartsURL = fm.scan(atPath: folderURL.path)?.sorted() else {
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
                
                guard let colorStyles = self?.generateColorStyles() else {
                    return nil
                }
                
                if let chart = try? StatParser().parse(data: entryData, colorStyles: colorStyles) {
                    return chart
                }
                else {
                    return nil
                }
            }
            
            DispatchQueue.main.async { self?.storeAndBroadcast(charts: charts) }
        }
    }
    
    private func generateColorStyles() -> [ChartType: ChartStylePair] {
        return [
            .line: obtainStrokeColors(),
            .duo: obtainStrokeColors(),
            .bar: obtainFillColors(),
            .area: obtainFillColors()
        ]
    }
    
    private func obtainStrokeColors() -> ChartStylePair {
        let greenKey = "#4BD964"
        let redKey = "#FE3C30"
        let blueKey = "#108BE3"
        let yellowKey = "#E8AF14"

        return ChartStylePair(
            light: ChartStyle(
                axis: ChartAxisStyle(
                    vertical: UIColor(hex: "8E8E93"),
                    horizontal: UIColor(hex: "8E8E93")
                ),
                lines: [
                    greenKey: ChartLineStyle(
                        line: UIColor(hex: "4BD964"),
                        button: UIColor(hex: "4BD964"),
                        tooltip: UIColor(hex: "2FB146")
                    ),
                    redKey: ChartLineStyle(
                        line: UIColor(hex: "FE3C30"),
                        button: UIColor(hex: "FF3B30"),
                        tooltip: UIColor(hex: "FE3C30")
                    ),
                    blueKey: ChartLineStyle(
                        line: UIColor(hex: "007AFF"),
                        button: UIColor(hex: "007AFF"),
                        tooltip: UIColor(hex: "007AFF")
                    ),
                    yellowKey: ChartLineStyle(
                        line: UIColor(hex: "F3BA00"),
                        button: UIColor(hex: "F3BA00"),
                        tooltip: UIColor(hex: "DDA900")
                    )
                ],
                mask: nil
            ),
            dark: ChartStyle(
                axis: ChartAxisStyle(
                    vertical: UIColor(hex: "8596AB"),
                    horizontal: UIColor(hex: "8596AB")
                ),
                lines: [
                    greenKey: ChartLineStyle(
                        line: UIColor(hex: "4BD964"),
                        button: UIColor(hex: "4BD964"),
                        tooltip: UIColor(hex: "4BD964")
                    ),
                    redKey: ChartLineStyle(
                        line: UIColor(hex: "FE3C30"),
                        button: UIColor(hex: "FF3B30"),
                        tooltip: UIColor(hex: "FE3C30")
                    ),
                    blueKey: ChartLineStyle(
                        line: UIColor(hex: "007AFF"),
                        button: UIColor(hex: "3193FF"),
                        tooltip: UIColor(hex: "3193FF")
                    ),
                    yellowKey: ChartLineStyle(
                        line: UIColor(hex: "F3BA00"),
                        button: UIColor(hex: "E0AC00"),
                        tooltip: UIColor(hex: "DDA900")
                    )
                ],
                mask: nil
            )
        )
    }
    
    private func obtainFillColors() -> ChartStylePair {
        let lightBlueKey = "#64ADED"
        let mediumBlueKey = "#3497ED"
        let darkBlueKey = "#2373DB"
        let lightGreenKey = "#9ED448"
        let darkGreenKey = "#5FB641"
        let yellowKey = "#F5BD25"
        let orangeKey = "#F79E39"
        let redKey = "#E65850"
        
        return ChartStylePair(
            light: ChartStyle(
                axis: ChartAxisStyle(
                    vertical: UIColor(hex: "252529").withAlphaComponent(0.5),
                    horizontal: UIColor(hex: "252529").withAlphaComponent(0.5)
                ),
                lines: [
                    lightBlueKey: ChartLineStyle(
                        line: UIColor(hex: "55BFE6"),
                        button: UIColor(hex: "55BFE6"),
                        tooltip: UIColor(hex: "269ED4")
                    ),
                    mediumBlueKey: ChartLineStyle(
                        line: UIColor(hex: "539AF7"),
                        button: UIColor(hex: "539AF7"),
                        tooltip: UIColor(hex: "539AF7")
                    ),
                    darkBlueKey: ChartLineStyle(
                        line: UIColor(hex: "407DCD"),
                        button: UIColor(hex: "407DCD"),
                        tooltip: UIColor(hex: "407DCD")
                    ),
                    lightGreenKey: ChartLineStyle(
                        line: UIColor(hex: "88D43F"),
                        button: UIColor(hex: "88D43F"),
                        tooltip: UIColor(hex: "73C129")
                    ),
                    darkGreenKey: ChartLineStyle(
                        line: UIColor(hex: "73B435"),
                        button: UIColor(hex: "73B435"),
                        tooltip: UIColor(hex: "4BAB29")
                    ),
                    yellowKey: ChartLineStyle(
                        line: UIColor(hex: "F5BD25"),
                        button: UIColor(hex: "F5BD25"),
                        tooltip: UIColor(hex: "EAAF10")
                    ),
                    orangeKey: ChartLineStyle(
                        line: UIColor(hex: "FF9B39"),
                        button: UIColor(hex: "FF9B39"),
                        tooltip: UIColor(hex: "E87B11")
                    ),
                    redKey: ChartLineStyle(
                        line: UIColor(hex: "F8564B"),
                        button: UIColor(hex: "F8564B"),
                        tooltip: UIColor(hex: "F34C44")
                    )
                ],
                mask: UIColor(hex: "FFFFFF").withAlphaComponent(0.5)
            ),
            dark: ChartStyle(
                axis: ChartAxisStyle(
                    vertical: UIColor(hex: "BACCE1").withAlphaComponent(0.6),
                    horizontal: UIColor(hex: "8596AB")
                ),
                lines: [
                    lightBlueKey: ChartLineStyle(
                        line: UIColor(hex: "479FC4"),
                        button: UIColor(hex: "399FC5"),
                        tooltip: UIColor(hex: "269ED4")
                    ),
                    mediumBlueKey: ChartLineStyle(
                        line: UIColor(hex: "407ECF"),
                        button: UIColor(hex: "407ECF"),
                        tooltip: UIColor(hex: "63A6FF")
                    ),
                    darkBlueKey: ChartLineStyle(
                        line: UIColor(hex: "2A61A9"),
                        button: UIColor(hex: "2A61A9"),
                        tooltip: UIColor(hex: "3578CF")
                    ),
                    lightGreenKey: ChartLineStyle(
                        line: UIColor(hex: "88BA52"),
                        button: UIColor(hex: "88BA52"),
                        tooltip: UIColor(hex: "86C740")
                    ),
                    darkGreenKey: ChartLineStyle(
                        line: UIColor(hex: "3DA05A"),
                        button: UIColor(hex: "3DA05A"),
                        tooltip: UIColor(hex: "3DA05A")
                    ),
                    yellowKey: ChartLineStyle(
                        line: UIColor(hex: "DBB630"),
                        button: UIColor(hex: "DBB630"),
                        tooltip: UIColor(hex: "DBB630")
                    ),
                    orangeKey: ChartLineStyle(
                        line: UIColor(hex: "E48C35"),
                        button: UIColor(hex: "E48C35"),
                        tooltip: UIColor(hex: "FF9B39")
                    ),
                    redKey: ChartLineStyle(
                        line: UIColor(hex: "DE4D43"),
                        button: UIColor(hex: "DE4D43"),
                        tooltip: UIColor(hex: "DE4D43")
                    )
                ],
                mask: UIColor(hex: "212F3F").withAlphaComponent(0.5)
            )
        )
    }
    
    private func storeAndBroadcast(charts: [Chart]) {
        let standardTitles: [String] = [
            "Followers",
            "Interactions",
            "Messages",
            "Views",
            "Apps"
        ]
        
        if charts.count == standardTitles.count {
            let chartMetas = zip(charts, standardTitles).map { chart, title in
                ChartMeta(title: title, chart: chart)
            }
            
            state = .ready(chartMetas)
            stateObservable.broadcast(state)
        }
        else {
            let prefix = localeProvider.localize(key: "Stat.Section.TitlePrefix")
            let chartMetas = charts.enumerated().map { index, chart in
                ChartMeta(title: "\(prefix) #\(index + 1)", chart: chart)
            }

            state = .ready(chartMetas)
            stateObservable.broadcast(state)
        }
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
