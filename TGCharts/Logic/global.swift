//
//  global.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

// Sometimes expressions like "a && not(b) && c"
// are more readable than "a && !b && c";
// don't you think so?
func not(_ value: Bool) -> Bool {
    return !value
}
