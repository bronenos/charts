//
//  StatDataSource.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

fileprivate let standardHeaderHeight = CGFloat(25)

final class StatDataSource: NSObject, UITableViewDataSource, UITableViewDelegate, DesignBookUpdatable {
    var switchDesignHandler: (() -> Void)?
    
    private var designSwitcherCell = UITableViewCell()
    private weak var tableView: UITableView?
    
    private var sectionTitle: String?
    private var chartControls = [ChartControl]()
    private var designSwitcherTitle: String?
    
    func setChartControls(titlePrefix: String, controls: [ChartControl]) {
        sectionTitle = titlePrefix
        chartControls = controls
        tableView?.reloadData()
    }
    
    func setDesignSwitcherTitle(_ title: String) {
        designSwitcherTitle = title
    }
    
    func register(in tableView: UITableView) {
        tableView.dataSource = nil
        tableView.delegate = nil
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
        self.tableView = tableView
    }
    
    func reload() {
        tableView?.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return chartControls.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return standardHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sectionTitle else { return nil }
        
        let label = StatSectionHeader()
        label.text = "\(title) #\(section + 1)".uppercased()
        label.textColor = DesignBook.shared.color(.secondaryForeground)
        label.font = DesignBook.shared.font(size: 13, weight: .light)
        return label
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let control = chartControls[indexPath.section]
        let height = control.sizeThatFits(tableView.bounds.size).height
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let control = chartControls[indexPath.section]
        control.link(to: cell.contentView)
        
        cell.separatorInset.left = cell.bounds.width
        cell.selectionStyle = .none
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let control = chartControls[indexPath.section]
        control.unlink()
    }
    
    func updateDesign() {
        chartControls.forEach { control in control.update() }
    }
}

fileprivate extension IndexPath {
    var isFirstRow: Bool {
        return (row == 0)
    }
}
