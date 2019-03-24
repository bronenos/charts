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
fileprivate let standardCellHeight = CGFloat(40)
fileprivate let chartCellHeight = CGFloat(350)
fileprivate let chartCellReuseID = "chart_cell"
fileprivate let optionCellReuseID = "option_cell"
fileprivate let actionCellReuseID = "action_cell"

final class StatDataSource: NSObject, UITableViewDataSource, UITableViewDelegate, DesignBookUpdatable {
    var switchDesignHandler: (() -> Void)?
    
    private var designSwitcherCell = UITableViewCell()
    private weak var tableView: UITableView?
    
    private var sectionTitle: String?
    private var chartControls = [IChartControl]()
    private var designSwitcherTitle: String?
    
    func setChartControls(titlePrefix: String, controls: [IChartControl]) {
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
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: chartCellReuseID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: optionCellReuseID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: actionCellReuseID)

        tableView.reloadData()
        self.tableView = tableView
    }
    
    func reload() {
        tableView?.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return chartControls.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return standardHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch true {
        case sectionBelongsToAnyChart(section):
            guard let title = sectionTitle else { return nil }
            
            let label = StatSectionHeader()
            label.text = "\(title) \(section + 1)/\(chartControls.count)".uppercased()
            label.textColor = DesignBook.shared.color(.secondaryForeground)
            label.font = DesignBook.shared.font(size: 13, weight: .light)
            return label
            
        case !sectionBelongsToAnyChart(section):
            return nil
            
        default:
            assertionFailure()
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch true {
        case sectionBelongsToAnyChart(section):
            let numberOfLines = chartControls[section].config.lines.count
            return 1 + numberOfLines
            
        case !sectionBelongsToAnyChart(section):
            return 1
            
        default:
            assertionFailure()
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch true {
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            return chartCellHeight
            
        case sectionBelongsToAnyChart(indexPath.section) && not(indexPath.isFirstRow):
            return standardCellHeight
            
        case !sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            return standardCellHeight
            
        default:
            assertionFailure()
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch true {
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            return reusableChartControlCell()
            
        case sectionBelongsToAnyChart(indexPath.section) && not(indexPath.isFirstRow):
            return reusableChartLineControlCell()
            
        case !sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            return reusableSwitchDesignCell()
            
        default:
            assertionFailure()
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch true {
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            let chartControl = chartControls[indexPath.section]
            populateChartControl(control: chartControl, intoCell: cell)
            
        case sectionBelongsToAnyChart(indexPath.section) && !indexPath.isFirstRow:
            let line = chartControls[indexPath.section].chart.lines[indexPath.row - 1]
            let lineConfig = chartControls[indexPath.section].config.lines[indexPath.row - 1]
            populateChartLineControl(line: line, config: lineConfig, intoCell: cell)
            
        case !sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            populateSwitchDesignCell(intoCell: cell)
            
        default:
            assertionFailure()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch true {
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            let chartControl = chartControls[indexPath.section]
            utilizeChartControl(control: chartControl, intoCell: cell)
            
        case sectionBelongsToAnyChart(indexPath.section) && not(indexPath.isFirstRow):
            break
            
        case !sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            break
            
        default:
            assertionFailure()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch true {
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            break
            
        case sectionBelongsToAnyChart(indexPath.section) && not(indexPath.isFirstRow):
            let chartControl = chartControls[indexPath.section]
            let key = chartControl.config.lines[indexPath.row - 1].key
            chartControl.toggleLine(key: key)
            updateRowsWithoutAnimations(indexPaths: [indexPath])

        case !sectionBelongsToAnyChart(indexPath.section) && indexPath.isFirstRow:
            // let the system to animate the cell back with the current design
            // and then we can perform the design switch
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
                self?.switchDesignHandler?()
            }
            
        default:
            assertionFailure()
        }
    }
    
    func updateDesign() {
        guard let tableView = tableView else { return }
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return }
        updateRowsWithoutAnimations(indexPaths: visibleIndexPaths)
    }
    
    private func sectionBelongsToAnyChart(_ section: Int) -> Bool {
        return (section < chartControls.count)
    }
    
    private func reusableChartControlCell() -> UITableViewCell {
        if let cell = tableView?.dequeueReusableCell(withIdentifier: chartCellReuseID) {
            return cell
        }

        return UITableViewCell(style: .default, reuseIdentifier: chartCellReuseID)
    }
    
    private func populateChartControl(control: IChartControl, intoCell cell: UITableViewCell) {
        control.link(to: cell.contentView)
        control.render()
        
        cell.separatorInset.left = cell.bounds.width
        cell.selectionStyle = .none
    }
    
    private func utilizeChartControl(control: IChartControl, intoCell cell: UITableViewCell) {
//        control.unlink()
    }
    
    private func reusableChartLineControlCell() -> UITableViewCell {
        if let cell = tableView?.dequeueReusableCell(withIdentifier: optionCellReuseID) {
            return cell
        }
        
        return UITableViewCell(style: .default, reuseIdentifier: optionCellReuseID)
    }
    
    private func populateChartLineControl(line: ChartLine, config: ChartLineConfig, intoCell cell: UITableViewCell) {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = DesignBook.shared.color(.focusedBackground)
        
        cell.backgroundColor = DesignBook.shared.color(.primaryBackground)
        cell.selectedBackgroundView = selectedBackgroundView
        cell.contentView.backgroundColor = DesignBook.shared.color(.primaryBackground)
        cell.textLabel?.text = line.name
        cell.textLabel?.textColor = DesignBook.shared.color(.primaryForeground)
        cell.textLabel?.textAlignment = .left
        cell.imageView?.image = generateLineIcon(color: line.color)
        cell.accessoryType = config.visible ? .checkmark : .none
    }
    
    private func reusableSwitchDesignCell() -> UITableViewCell {
        if let cell = tableView?.dequeueReusableCell(withIdentifier: actionCellReuseID) {
            return cell
        }
        
        return UITableViewCell(style: .default, reuseIdentifier: actionCellReuseID)
    }
    
    private func populateSwitchDesignCell(intoCell cell: UITableViewCell) {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = DesignBook.shared.color(.focusedBackground)
        
        cell.backgroundColor = DesignBook.shared.color(.primaryBackground)
        cell.selectedBackgroundView = selectedBackgroundView
        cell.contentView.backgroundColor = DesignBook.shared.color(.primaryBackground)
        cell.textLabel?.backgroundColor = DesignBook.shared.color(.primaryBackground)
        cell.textLabel?.text = designSwitcherTitle
        cell.textLabel?.textColor = DesignBook.shared.color(.actionForeground)
        cell.textLabel?.textAlignment = .center
    }
    
    private func generateLineIcon(color: UIColor) -> UIImage? {
        let size = CGSize(width: 12, height: 12)
        
        func _draw(in context: CGContext) {
            let bounds = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: bounds, cornerRadius: 3)
            
            context.setFillColor(color.cgColor)
            context.addPath(path.cgPath)
            context.fillPath()
        }
        
        if #available(iOS 10.0, *) {
            return UIGraphicsImageRenderer(size: size).image { context in
                _draw(in: context.cgContext)
            }
        }
        else {
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            
            _draw(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
    }
    
    fileprivate func updateRowsWithoutAnimations(indexPaths: [IndexPath]) {
        guard let tableView = tableView else { return }
        guard !tableView.visibleCells.isEmpty else { return }
        
        tableView.visibleCells.forEach { cell in
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            tableView.delegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
        }
    }
}

fileprivate extension IndexPath {
    var isFirstRow: Bool {
        return (row == 0)
    }
}
