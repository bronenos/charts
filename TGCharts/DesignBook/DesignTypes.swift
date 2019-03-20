//
//  DesignTypes.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum DesignBookStyle {
    case light
    case dark
}

enum DesignBookColor {
    case black
    case white
    case background
    case lightAsphalt
    case darkAsphalt
    case lightGray
    case darkGray
    case lightSilver
    case darkSilver
    case lightBlue
    case darkBlue
}

enum DesignBookFontWeight {
    case light
    case regular
    case medium
}

enum DesignBookColorAlias {
    case generalBackground
    case elementRegularBackground
    case elementFocusedBackground
    case navigationBackground
    case navigationForeground
    case sectionTitleForeground
    case chartIndexForeground
    case chartGridBackground
    case chartPointerForeground
    case sliderActiveBackground
    case sliderInactiveBackground
    case sliderControlBackground
    case sliderControlForeground
    case optionForeground
    case actionForeground
}

protocol DesignBookUpdatable: class {
    func updateDesign()
}
