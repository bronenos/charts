//
//  DesignBook.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

fileprivate var sharedInstance: IDesignBook!

protocol IDesignBook: class {
    var style: DesignBookStyle { get }
    func color(_ color: DesignBookColor) -> UIColor
    func font(size: CGFloat, weight: DesignBookFontWeight) -> UIFont
    func resolve(colorAlias: DesignBookColorAlias) -> UIColor
    func resolveStatusBarStyle() -> UIStatusBarStyle
}

class DesignBook: IDesignBook {
    class func setShared(_ instance: IDesignBook) {
        sharedInstance = instance
    }
    
    class var shared: IDesignBook {
        return sharedInstance
    }
    
    var style: DesignBookStyle {
        preconditionFailure("Override in specific subclass")
    }
    
    func color(_ color: DesignBookColor) -> UIColor {
        switch color {
        case .black: return UIColor.black
        case .white: return UIColor.white
        case .background: return UIColor.groupTableViewBackground
        case .lightAsphalt: return UIColor(red: 0.10, green: 0.14, blue: 0.19, alpha: 1.0)
        case .darkAsphalt: return UIColor(red: 0.07, green: 0.10, blue: 0.13, alpha: 1.0)
        case .lightGray: return UIColor.lightGray
        case .darkGray: return UIColor.darkGray
        case .lightSilver: return UIColor(red: 0.82, green: 0.82, blue: 0.84, alpha: 1.0)
        case .darkSilver: return UIColor(red: 0.77, green: 0.77, blue: 0.80, alpha: 1.0)
        case .blue: return UIColor.blue
        }
    }
    
    func font(size: CGFloat, weight: DesignBookFontWeight) -> UIFont {
        switch weight {
        case .light: return UIFont.systemFont(ofSize: size, weight: .light)
        case .regular: return UIFont.systemFont(ofSize: size, weight: .regular)
        case .medium: return UIFont.systemFont(ofSize: size, weight: .medium)
        }
    }
    
    func resolve(colorAlias: DesignBookColorAlias) -> UIColor {
        preconditionFailure("Must use the specific subclass")
    }
    
    func resolveStatusBarStyle() -> UIStatusBarStyle {
        preconditionFailure("Must use the specific subclass")
    }
}

final class LightDesignBook: DesignBook {
    override var style: DesignBookStyle {
        return .light
    }
    
    override func resolve(colorAlias: DesignBookColorAlias) -> UIColor {
        switch colorAlias {
        case .generalBackground: return color(.background)
        case .elementBackground: return color(.white)
        case .navigationForeground: return color(.black)
        case .sectionTitleForeground: return color(.darkGray)
        case .chartIndexForeground: return color(.lightGray)
        case .chartGridBackground: return color(.lightGray)
        case .sliderActiveBackground: return color(.white)
        case .sliderInactiveBackground: return color(.lightSilver)
        case .sliderControlBackground: return color(.darkSilver)
        case .sliderControlForeground: return color(.lightSilver)
        case .optionForeground: return color(.black)
        case .actionForeground: return color(.blue)
        }
    }
    
    override func resolveStatusBarStyle() -> UIStatusBarStyle {
        return .default
    }
}

final class DarkDesignBook: DesignBook {
    override var style: DesignBookStyle {
        return .dark
    }
    
    override func resolve(colorAlias: DesignBookColorAlias) -> UIColor {
        switch colorAlias {
        case .generalBackground: return color(.darkAsphalt)
        case .elementBackground: return color(.lightAsphalt)
        case .navigationForeground: return color(.white)
        case .sectionTitleForeground: return color(.lightSilver)
        case .chartIndexForeground: return color(.lightSilver)
        case .chartGridBackground: return color(.darkGray)
        case .sliderActiveBackground: return color(.darkSilver)
        case .sliderInactiveBackground: return color(.darkSilver)
        case .sliderControlBackground: return color(.lightSilver)
        case .sliderControlForeground: return color(.white)
        case .optionForeground: return color(.white)
        case .actionForeground: return color(.blue)
        }
    }
    
    override func resolveStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
}
