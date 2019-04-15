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
    func parse(data: Data, colorStyles: [ChartType: ChartStylePair]) throws -> Chart?
}

final class StatParser: IStatParser {
    func parse(data: Data, colorStyles: [ChartType: ChartStylePair]) throws -> Chart? {
        let json = JsonReader(data: data)
        let chart = parseChart(object: json, colorStyles: colorStyles)
        return chart
    }
    
    private func parseChart(object: JsonReader, colorStyles: [ChartType: ChartStylePair]) -> Chart? {
        guard let columns = object["columns"].array else { return nil }
        
        let columnNames: [String] = columns.map(JsonReader.init).compactMap { $0[0].string }
        guard columnNames.count == columns.count else { return nil }
        
        guard let dates = parseChartDates(object: object, key: "x") else { return nil }
        let numberOfDates = dates.count
        
        let lines = columnNames.compactMap({ parseChartLine(object: object, key: $0) })
        guard lines.allSatisfy({ $0.values.count == numberOfDates }) else { return nil }
        guard let firstLine = lines.first else { return nil }
        
        let type = parseChartType(
            object: object,
            firstLineType: firstLine.type
        )
        
        guard let stylePair = colorStyles[type] else {
            return nil
        }
        
        return Chart(
            type: type,
            length: numberOfDates,
            lines: lines,
            axis: dates.enumerated().map { index, date in
                ChartAxisItem(
                    date: date,
                    values: calculateValues(lines: lines, index: index)
                )
            },
            stylePair: stylePair
        )
    }
    
    private func parseChartType(object: JsonReader, firstLineType: String) -> ChartType {
        switch firstLineType {
        case "line" where object["y_scaled"].boolValue: return .duo
        case "bar": return .bar
        case "area": return .area
        default: return .line
        }
    }
    
    private func parseChartDates(object: JsonReader, key: String) -> [Date]? {
        guard object["types"][key].string == "x" else { return nil }
        let timestamps: [TimeInterval] = obtainColumnValues(object: object, key: key)
        return timestamps.map { Date(timeIntervalSince1970: $0 / 1000) }
    }
    
    private func parseChartLine(object: JsonReader, key: String) -> ChartLine? {
        guard let name = object["names"][key].string else { return nil }
        guard let type = object["types"][key].string else { return nil }
        guard let colorKey = object["colors"][key].string else { return nil }
        let values: [Int] = obtainColumnValues(object: object, key: key)
        return ChartLine(key: key, name: name, type: type, colorKey: colorKey, values: values)
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

// bar / area
// root.y_scaled
// root.stacked
// root.percentage
