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
    func parse(data: Data) throws -> [Chart]
}

final class StatParser: IStatParser {
    func parse(data: Data) throws -> [Chart] {
        let json = JsonReader(data: data)
        let charts = json.array?.map(JsonReader.init).compactMap(parseChart) ?? []
        return charts
    }
    
    private func parseChart(object: JsonReader) -> Chart? {
        guard let columns = object["columns"].array else { return nil }
        
        let columnNames: [String] = columns.map(JsonReader.init).compactMap { $0[0].string }
        guard columnNames.count == columns.count else { return nil }
        
        guard let dates = parseChartDates(object: object, key: "x") else { return nil }
        let numberOfDates = dates.count

        let lines = columnNames.compactMap({ parseChartLine(object: object, key: $0) })
        guard lines.allSatisfy({ $0.values.count == numberOfDates }) else { return nil }
        
        return Chart(
            length: numberOfDates,
            lines: lines,
            axis: dates.enumerated().map { index, date in
                ChartAxisItem(
                    date: date,
                    values: calculateValues(lines: lines, index: index)
                )
            }
        )
    }
    
    private func parseChartDates(object: JsonReader, key: String) -> [Date]? {
        guard object["types"][key].string == "x" else { return nil }
        let timestamps: [TimeInterval] = obtainColumnValues(object: object, key: key)
        return timestamps.map { Date(timeIntervalSince1970: $0 / 1000) }
    }
    
    private func parseChartLine(object: JsonReader, key: String) -> ChartLine? {
        guard object["types"][key].string == "line" else { return nil }
        guard let name = object["names"][key].string else { return nil }
        guard let color = object["colors"][key].string else { return nil }
        let values: [Int] = obtainColumnValues(object: object, key: key)
        return ChartLine(key: key, name: name, color: UIColor(hex: color), values: values)
    }
    
    private func obtainColumnValues<T>(object: JsonReader, key: String) -> [T] {
        guard let columns = object["columns"].array?.map(JsonReader.init) else { return [] }
        guard let keyColumn = columns.first(where: { $0[0].string == key }) else { return [] }
        guard let values = keyColumn.array?.dropFirst() else { return [] }
        
        if let result = Array(values) as? [T] {
            return result
        }
        else {
            return []
        }
    }
    
    private func calculateValues(lines: [ChartLine], index: Int) -> [String: Int] {
        var edges = [String: Int]()
        lines.forEach { line in edges[line.key] = line.values[index] }
        return edges
    }
}
