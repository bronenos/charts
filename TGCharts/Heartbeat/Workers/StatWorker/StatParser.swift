//
//  StatParser.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IStatParser: class {
    func parse(data: Data) throws -> [StatChart]
}

final class StatParser: IStatParser {
    func parse(data: Data) throws -> [StatChart] {
        let json = JsonReader(data: data)
        let charts = json.array?.map(JsonReader.init).compactMap(parseChart) ?? []
        return charts
    }
    
    private func parseChart(object: JsonReader) -> StatChart? {
        guard let columns = object["columns"].array else { return nil }
        
        let columnNames: [String] = columns.map(JsonReader.init).compactMap { $0[0].string }
        guard columnNames.count == columns.count else { return nil }
        
        guard let axis = parseChartAxis(object: object, key: "x") else { return nil }
        let lines = columnNames.compactMap({ parseChartLine(object: object, key: $0) })
        
        return StatChart(
            axis: axis,
            lines: lines
        )
    }
    
    private func parseChartAxis(object: JsonReader, key: String) -> StatChartAxis? {
        guard object["types"][key].string == "x" else { return nil }
        guard let timestamps = obtainColumnValues(object: object, key: key) as? [TimeInterval] else { return nil }
        
        return StatChartAxis(
            dates: timestamps.map { Date(timeIntervalSince1970: $0 / 1000) }
        )
    }
    
    private func parseChartLine(object: JsonReader, key: String) -> StatChartLine? {
        guard object["types"][key].string == "line" else { return nil }
        guard let name = object["names"][key].string else { return nil }
        guard let color = object["colors"][key].string else { return nil }
        guard let values = obtainColumnValues(object: object, key: key) as? [Int] else { return nil }
        
        return StatChartLine(
            name: name,
            color: UIColor(hex: color),
            values: values
        )
    }
    
    private func obtainColumnValues(object: JsonReader, key: String) -> [Any] {
        guard let columns = object["columns"].array?.map(JsonReader.init) else { return [] }
        guard let keyColumn = columns.first(where: { $0[0].string == key }) else { return [] }
        guard let values = keyColumn.array else { return [] }
        return Array(values.dropFirst())
    }
}
