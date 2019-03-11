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
        tableView?.reloadData()
    }
    
    func register(in tableView: UITableView) {
        tableView.dataSource = nil
        tableView.delegate = nil
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
        self.tableView = tableView
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
            label.textColor = DesignBook.shared.resolve(colorAlias: .sectionTitleForeground)
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
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.row == 0:
            return chartCellHeight
            
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.row > 0:
            return standardCellHeight
            
        case !sectionBelongsToAnyChart(indexPath.section) && indexPath.row == 0:
            return standardCellHeight
            
        default:
            assertionFailure()
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch true {
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.row == 0:
            let chartControl = chartControls[indexPath.section]
            return constructChartControlCell(chartControl)
            
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.row > 0:
            let lineConfig = chartControls[indexPath.section].config.lines[indexPath.row - 1]
            return constructChartLineControlCell(lineConfig)
            
        case !sectionBelongsToAnyChart(indexPath.section) && indexPath.row == 0:
            return constructSwitchDesignCell()
            
        default:
            assertionFailure()
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        switch true {
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.row == 0:
            break
            
        case sectionBelongsToAnyChart(indexPath.section) && indexPath.row > 0:
            let chartControl = chartControls[indexPath.section]
            let key = chartControl.config.lines[indexPath.row - 1].key
            chartControl.toggleLine(key: key)
            tableView.reloadData()

        case !sectionBelongsToAnyChart(indexPath.section) && indexPath.row == 0:
            switchDesignHandler?()
            
        default:
            assertionFailure()
        }
    }
    
    func updateDesign() {
        guard let tableView = tableView else { return }
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return }
        
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.reloadRows(at: visibleIndexPaths, with: .none)
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
    
    private func sectionBelongsToAnyChart(_ section: Int) -> Bool {
        return (section < chartControls.count)
    }
    
    private func constructChartControlCell(_ chart: IChartControl) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.contentView.addSubview(chart.view)
        chart.view.frame = cell.contentView.bounds
        chart.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return cell
    }
    
    private func constructChartLineControlCell(_ config: ChartConfigLine) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = DesignBook.shared.resolve(colorAlias: .elementBackground)
        cell.contentView.backgroundColor = DesignBook.shared.resolve(colorAlias: .elementBackground)
        cell.textLabel?.text = config.name
        cell.textLabel?.textColor = DesignBook.shared.resolve(colorAlias: .optionForeground)
        cell.textLabel?.textAlignment = .left
        cell.imageView?.image = generateLineIcon(color: config.color)
        cell.accessoryType = config.visible ? .checkmark : .none
        return cell
    }
    
    private func constructSwitchDesignCell() -> UITableViewCell {
        let cell = UITableViewCell()
        cell.contentView.backgroundColor = DesignBook.shared.resolve(colorAlias: .elementBackground)
        cell.textLabel?.text = designSwitcherTitle
        cell.textLabel?.textColor = DesignBook.shared.resolve(colorAlias: .actionForeground)
        cell.textLabel?.textAlignment = .center
        return cell
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
}
