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
    private let localeProvider: ILocaleProvider
    
    private let dateFormatter = DateFormatter()
    private(set) var calendar = Calendar.autoupdatingCurrent
    
    init(localeProvider: ILocaleProvider) {
        self.localeProvider = localeProvider
    }
    
    func format(date: Date, style: FormattingDateStyle) -> String {
        dateFormatter.locale = localeProvider.activeLocale
        
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
        
        return dateFormatter.string(from: date)
    }
}
