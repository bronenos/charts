//
//  StatDataSource.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum StatSection: Int, CaseIterable {
    case chart
    case modeSwitcher
}

final class StatDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    var switchModeHandler: (() -> Void)?
    
    private let modeSwitcherCell = UITableViewCell()
    
    func setModeSwitcherTitle(_ title: String) {
        modeSwitcherCell.backgroundColor = DesignBook.shared.resolve(colorAlias: .elementBackground)
        modeSwitcherCell.contentView.backgroundColor = DesignBook.shared.resolve(colorAlias: .elementBackground)
        modeSwitcherCell.textLabel?.backgroundColor = DesignBook.shared.resolve(colorAlias: .elementBackground)
        modeSwitcherCell.textLabel?.text = title
        modeSwitcherCell.textLabel?.textColor = DesignBook.shared.resolve(colorAlias: .actionForeground)
        modeSwitcherCell.textLabel?.textAlignment = .center
    }
    
    func register(in tableView: UITableView) {
        tableView.dataSource = nil
        tableView.delegate = nil
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return StatSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection index: Int) -> Int {
        guard let section = StatSection(rawValue: index) else {
            abort()
        }
        
        switch section {
        case .chart: return 0
        case .modeSwitcher: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = StatSection(rawValue: indexPath.section) else {
            abort()
        }
        
        switch section {
        case .chart: abort()
        case .modeSwitcher: return modeSwitcherCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = StatSection(rawValue: indexPath.section) else {
            abort()
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        switch section {
        case .chart: abort()
        case .modeSwitcher: switchModeHandler?()
        }
    }
}
