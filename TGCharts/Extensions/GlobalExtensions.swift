//
//  GlobalExtensions.swift
//  TGCharts
//
//  Created by Stan Potemkin on 12/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

func between<Type: Comparable>(value: Type, minimum: Type, maximum: Type) -> Type {
    return Swift.min(Swift.max(minimum, value), maximum)
}

func convertMap<Source, Target>(_ value: Source, block: (Source) -> Target) -> Target {
    return block(value)
}

func clone<Source>(_ value: Source, number: Int) -> [Source] {
    return [Source](repeating: value, count: number)
}

func calculateLimits(_ values: [Int]) -> (lower: Int, upper: Int)? {
    var lowerValue = Int.max
    var upperValue = Int.min
    
    if let firstValue = values.first {
        lowerValue = firstValue
        upperValue = firstValue
    }
    else {
        return nil
    }
    
    for value in values {
        if value > upperValue {
            upperValue = value
        }
        else if value < lowerValue {
            lowerValue = value
        }
    }
    
    return (
        lower: lowerValue,
        upper: upperValue
    )
}
