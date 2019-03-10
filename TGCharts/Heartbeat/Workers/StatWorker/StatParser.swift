//
//  StatParser.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol IStatParser: class {
    func parse(data: Data) throws -> [StatChart]
}

final class StatParser: IStatParser {
    func parse(data: Data) throws -> [StatChart] {
        let json = JsonReader(data: data)
        let chart = json[0]["columns"][0][0].stringValue
        return []
    }
}
