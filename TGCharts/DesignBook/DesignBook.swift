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

enum ChartColorKey {
    case x
    case y
    case line(String)
    case button(String)
    case tooltip(String)
    case dimming
}

protocol IDesignBook: class {
    var style: DesignBookStyle { get }
    var styleObservable: BroadcastObservable<DesignBookStyle> { get }
    var standardRadius: CGFloat { get }
    func color(_ color: DesignBookColor) -> UIColor
    func color(chart: Chart, key: ChartColorKey) -> UIColor
    func font(size: CGFloat, weight: DesignBookFontWeight) -> UIFont
    func duration(_ animation: DesignBookAnimation) -> TimeInterval
    func mainGraphHeight(bounds: CGRect, traitCollection: UITraitCollection) -> CGFloat
    func caretStandardWidth(navigationWidth: CGFloat) -> CGFloat
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
    
    var standardRadius: CGFloat {
        return 6
    }
    
    func color(_ color: DesignBookColor) -> UIColor {
        abort()
    }
    
    func color(chart: Chart, key: ChartColorKey) -> UIColor {
        abort()
    }
    
    func font(size: CGFloat, weight: DesignBookFontWeight) -> UIFont {
        switch weight {
        case .light: return UIFont.systemFont(ofSize: size, weight: .light)
        case .regular: return UIFont.systemFont(ofSize: size, weight: .regular)
        case .medium: return UIFont.systemFont(ofSize: size, weight: .medium)
        }
    }
    
    func duration(_ animation: DesignBookAnimation) -> TimeInterval {
        switch animation {
        case .designChange: return 0.15
        case .toggleLine: return 0.25
        case .toggleOption: return 0.25
        case .updateEye: return isPhone ? 0.075 : 0
        case .pointerDimming: return 0.25
        }
    }
    
    func mainGraphHeight(bounds: CGRect, traitCollection: UITraitCollection) -> CGFloat {
        if isPhone {
            switch traitCollection.verticalSizeClass {
            case .regular: return min(bounds.height * 0.5, 300)
            case .compact: return 150
            default: return 50
            }
        }
        else {
            return 300
        }
    }
    
    func caretStandardWidth(navigationWidth: CGFloat) -> CGFloat {
        return isPhone ? 95 : (navigationWidth / 12)
    }
    
    func resolveStatusBarStyle() -> UIStatusBarStyle {
        preconditionFailure("Must use the specific subclass")
    }
    
    func resolveNavigationTitleAttributes() -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: color(.primaryForeground)]
    }
    
    fileprivate var isPhone: Bool {
        return (UI_USER_INTERFACE_IDIOM() == .phone)
    }
    
    fileprivate func color(style: ChartStyle, key: ChartColorKey) -> UIColor {
        switch key {
        case .x: return style.axis.horizontal
        case .y: return style.axis.vertical
        case .line(let colorKey): return style.lines[colorKey]?.line ?? UIColor(hex: colorKey)
        case .button(let colorKey): return style.lines[colorKey]?.button ?? UIColor(hex: colorKey)
        case .tooltip(let colorKey): return style.lines[colorKey]?.tooltip ?? UIColor(hex: colorKey)
        case .dimming: return style.mask ?? UIColor.clear
        }
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
        case .chartGridStroke: return UIColor(hex: "182D3B").withAlphaComponent(0.1)
        case .chartPointerCloudBackground: return UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1.0)
        case .chartPointerCloudForeground: return UIColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)
        case .chartPointerCloudControls: return UIColor(hex: "59606D").withAlphaComponent(0.3)
        case .navigatorBackground: return UIColor(hex: "E9F3FA")
        case .navigatorCoverBackground: return self.color(.navigatorBackground).withAlphaComponent(0.2)
        case .sliderBackground: return UIColor(hex: "B4C7D9")
        case .sliderForeground: return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .optionForeground: return UIColor.white
        case .actionForeground: return UIColor(hex: "108BE3")
        }
    }
    
    override func color(chart: Chart, key: ChartColorKey) -> UIColor {
        return color(style: chart.stylePair.light, key: key)
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
        case .chartGridStroke: return UIColor(hex: "8596AB").withAlphaComponent(0.2)
        case .chartPointerCloudBackground: return UIColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1.0)
        case .chartPointerCloudForeground: return UIColor.white
        case .chartPointerCloudControls: return UIColor(hex: "D2D5D7")
        case .navigatorBackground: return UIColor(hex: "151C27")
        case .navigatorCoverBackground: return self.color(.navigatorBackground).withAlphaComponent(0.2)
        case .sliderBackground: return UIColor(hex: "444F5A")
        case .sliderForeground: return UIColor.white
        case .optionForeground: return UIColor.white
        case .actionForeground: return UIColor(hex: "2EA6FE")
        }
    }
    
    override func color(chart: Chart, key: ChartColorKey) -> UIColor {
        return color(style: chart.stylePair.dark, key: key)
    }
    
    override func resolveStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
}
