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
    var activeLocale: Locale {
        return Locale.current
    }
    
    func localize(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}
