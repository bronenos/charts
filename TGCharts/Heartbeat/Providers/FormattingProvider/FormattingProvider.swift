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
    func format(guide value: Int) -> String
}

final class FormattingProvider: IFormattingProvider {
    private let dateFormatter = DateFormatter()
    private(set) var calendar = Calendar.autoupdatingCurrent
    
    private let quantityFormatter = NumberFormatter()
    
    private var cached = [String: String]()
    
    init(localeProvider: ILocaleProvider) {
        dateFormatter.locale = localeProvider.activeLocale
        
        quantityFormatter.minimumFractionDigits = 0
        quantityFormatter.maximumFractionDigits = 0
    }
    
    func format(date: Date, style: FormattingDateStyle) -> String {
        let cachingKey = "\(date.timeIntervalSince1970):\(style)"
        if let cached = cached[cachingKey] { return cached }
        
        switch style {
        case .shortDate:
            dateFormatter.dateFormat = "d MMM"
            dateFormatter.doesRelativeDateFormatting = false

        case .justYear:
            dateFormatter.dateFormat = "yyyy"
            dateFormatter.doesRelativeDateFormatting = false
            
        case .mediumDate:
            dateFormatter.dateFormat = "d MMMM yyyy"
            dateFormatter.doesRelativeDateFormatting = false
            
        case .dayAndDate:
            dateFormatter.dateFormat = "EEE, d MMM yyyy"
            dateFormatter.doesRelativeDateFormatting = false

        case .fullDate:
            dateFormatter.dateFormat = "EEEE, d MMM yyyy"
            dateFormatter.doesRelativeDateFormatting = false
        }
        
        let result = dateFormatter.string(from: date)
        cached[cachingKey] = result
        
        return result
    }
    
    func format(guide value: Int) -> String {
        if value > 1_000_000 {
            quantityFormatter.minimumFractionDigits = 1
            quantityFormatter.maximumFractionDigits = 1
            
            let rest = Double(value) / 1_000_000
            if let value = quantityFormatter.string(from: NSNumber(value: rest)) {
                return value + "M"
            }
        }
        
        if value > 1_000 {
            quantityFormatter.minimumFractionDigits = 1
            quantityFormatter.maximumFractionDigits = 1
            
            let rest = Double(value) / 1_000
            if let value = quantityFormatter.string(from: NSNumber(value: rest)) {
                return value + "K"
            }
        }
        
        quantityFormatter.minimumFractionDigits = 0
        quantityFormatter.maximumFractionDigits = 0
        
        return String(describing: value)
    }
}
