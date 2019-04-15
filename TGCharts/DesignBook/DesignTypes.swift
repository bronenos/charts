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
    case spaceBackground
    case primaryBackground
    case focusedBackground
    case primaryForeground
    case secondaryForeground
    case chartIndexForeground
    case chartGuidesLineStroke
    case chartPointerFocusedLineStroke
    case chartPointerCloudBackground
    case chartPointerCloudForeground
    case chartPointerDimming
    case navigatorBackground
    case navigatorCoverBackground
    case sliderBackground
    case sliderForeground
    case optionForeground
    case actionForeground
}

enum DesignBookFontWeight {
    case light
    case regular
    case medium
}

enum DesignBookAnimation {
    case designChange
    case toggleLine
    case toggleOption
    case updateEye
    case pointerDimming
}

protocol DesignBookUpdatable: class {
    func updateDesign()
}
