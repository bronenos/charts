//
//  LocaleProvider.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol ILocaleProvider: class {
    var activeLocale: Locale { get }
    func localize(key: String) -> String
}

final class LocaleProvider: ILocaleProvider {
    static var activeLocale: Locale!
    
    init() {
        LocaleProvider.activeLocale = Locale.current
    }
    
    var activeLocale: Locale {
        return LocaleProvider.activeLocale
    }
    
    func localize(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}
