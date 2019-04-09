//
//  FormattingProvider.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol IFormattingProvider: class {
    func format(date: Date, style: FormattingDateStyle) -> String
}

final class FormattingProvider: IFormattingProvider {
    private let dateFormatter = DateFormatter()
    private(set) var calendar = Calendar.autoupdatingCurrent
    
    private var cached = [String: String]()
    
    init(localeProvider: ILocaleProvider) {
        dateFormatter.locale = localeProvider.activeLocale
    }
    
    func format(date: Date, style: FormattingDateStyle) -> String {
        let cachingKey = "\(date.timeIntervalSince1970):\(style)"
        if let cached = cached[cachingKey] {
            return cached
        }
        
        switch style {
        case .shortDate:
            dateFormatter.dateFormat = "MMM d"
            dateFormatter.doesRelativeDateFormatting = false

        case .justYear:
            dateFormatter.dateFormat = "yyyy"
            dateFormatter.doesRelativeDateFormatting = false
            
        case .mediumDate:
            dateFormatter.dateFormat = "d MMM yyyy"
            dateFormatter.doesRelativeDateFormatting = false
            
        case .fullDate:
            dateFormatter.dateFormat = "EEEE, d MMM yyyy"
            dateFormatter.doesRelativeDateFormatting = false
        }
        
        let result = dateFormatter.string(from: date)
        cached[cachingKey] = result
        
        return result
    }
}
