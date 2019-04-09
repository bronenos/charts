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
fileprivate let sharedStyleObservable = BroadcastObservable<DesignBookStyle>()

extension Notification.Name {
    static let designBookChanged = Notification.Name(rawValue: "DesignBookChanged")
}

protocol IDesignBook: class {
    var style: DesignBookStyle { get }
    var styleObservable: BroadcastObservable<DesignBookStyle> { get }
    func color(_ color: DesignBookColor) -> UIColor
    func font(size: CGFloat, weight: DesignBookFontWeight) -> UIFont
    func resolveStatusBarStyle() -> UIStatusBarStyle
    func resolveNavigationTitleAttributes() -> [NSAttributedString.Key: Any]
}

class DesignBook: IDesignBook {
    class func setShared(_ instance: IDesignBook) {
        sharedInstance = instance
        sharedStyleObservable.broadcast(instance.style)
        NotificationCenter.default.post(name: .designBookChanged, object: nil)
    }
    
    class var shared: IDesignBook {
        return sharedInstance
    }
    
    var style: DesignBookStyle {
        preconditionFailure("Override in specific subclass")
    }
    
    var styleObservable: BroadcastObservable<DesignBookStyle> {
        return sharedStyleObservable
    }
    
    func color(_ color: DesignBookColor) -> UIColor {
        abort()
    }
    
    func font(size: CGFloat, weight: DesignBookFontWeight) -> UIFont {
        switch weight {
        case .light: return UIFont.systemFont(ofSize: size, weight: .light)
        case .regular: return UIFont.systemFont(ofSize: size, weight: .regular)
        case .medium: return UIFont.systemFont(ofSize: size, weight: .medium)
        }
    }
    
    func resolveStatusBarStyle() -> UIStatusBarStyle {
        preconditionFailure("Must use the specific subclass")
    }
    
    func resolveNavigationTitleAttributes() -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: color(.primaryForeground)]
    }
}

final class LightDesignBook: DesignBook {
    override var style: DesignBookStyle {
        return .light
    }
    
    override func color(_ color: DesignBookColor) -> UIColor {
        switch color {
        case .spaceBackground: return UIColor(red: 0.92, green: 0.92, blue: 0.95, alpha: 1.0)
        case .primaryBackground: return UIColor.white
        case .focusedBackground: return UIColor(white: 0.9, alpha: 1.0)
        case .primaryForeground: return UIColor.black
        case .secondaryForeground: return UIColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)
        case .chartIndexForeground: return UIColor(red: 0.52, green: 0.55, blue: 0.57, alpha: 1.0)
        case .chartPointerStepperLineStroke: return UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 0.35)
        case .chartPointerFocusedLineStroke: return UIColor(red: 0.77, green: 0.78, blue: 0.78, alpha: 0.35)
        case .chartPointerCloudBackground: return UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1.0)
        case .chartPointerCloudForeground: return UIColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)
        case .navigatorBackground: return UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0)
        case .navigatorCoverBackground: return UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 0.7)
        case .sliderBackground: return UIColor(red: 0.75, green: 0.79, blue: 0.84, alpha: 0.85)
        case .sliderForeground: return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .actionForeground: return UIColor(red: 0.05, green: 0.40, blue: 0.87, alpha: 1.0)
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
    
    override func color(_ color: DesignBookColor) -> UIColor {
        switch color {
        case .spaceBackground: return UIColor(red: 0.07, green: 0.10, blue: 0.13, alpha: 1.0)
        case .primaryBackground: return UIColor(red: 0.10, green: 0.14, blue: 0.19, alpha: 1.0)
        case .focusedBackground: return UIColor(red: 0.20, green: 0.24, blue: 0.29, alpha: 1.0)
        case .primaryForeground: return UIColor.white
        case .secondaryForeground: return UIColor(red: 0.29, green: 0.35, blue: 0.42, alpha: 1.0)
        case .chartIndexForeground: return UIColor(red: 0.29, green: 0.35, blue: 0.42, alpha: 1.0)
        case .chartPointerStepperLineStroke: return UIColor(red: 0.08, green: 0.11, blue: 0.15, alpha: 0.35)
        case .chartPointerFocusedLineStroke: return UIColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 0.35)
        case .chartPointerCloudBackground: return UIColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1.0)
        case .chartPointerCloudForeground: return UIColor.white
        case .navigatorBackground: return UIColor(red: 0.09, green: 0.12, blue: 0.17, alpha: 1.0)
        case .navigatorCoverBackground: return UIColor(red: 0.09, green: 0.12, blue: 0.17, alpha: 0.7)
        case .sliderBackground: return UIColor(red: 0.16, green: 0.21, blue: 0.28, alpha: 0.85)
        case .sliderForeground: return UIColor.white
        case .actionForeground: return UIColor(red: 0.09, green: 0.48, blue: 1.0, alpha: 1.0)
        }
    }
    
    override func resolveStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
}
