//
//  FeedbackDriver.swift
//  TGCharts
//
//  Created by Stan Potemkin on 15/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IFeedbackDriver: class {
    func vibrateOnSlide()
    func vibrateOnAction(strength: FeedbackVibroStrength)
}

final class FeedbackDriver: IFeedbackDriver {
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    func vibrateOnSlide() {
        selectionGenerator.selectionChanged()
    }
    
    func vibrateOnAction(strength: FeedbackVibroStrength) {
        switch strength {
        case .medium: mediumImpactGenerator.impactOccurred()
        case .strong: heavyImpactGenerator.impactOccurred()
        }
    }
}
