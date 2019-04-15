//
//  StatDataSource.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartControlMeta {
    let chartMeta: ChartMeta
    let control: ChartControl
}

fileprivate let standardHeaderHeight = CGFloat(25)

final class StatDataSource: NSObject, UITableViewDataSource, UITableViewDelegate, DesignBookUpdatable {
    private weak var tableView: UITableView?
    
    private var metas = [ChartControlMeta]()
    private var designSwitcherTitle: String?
    
    func setMetas(metas: [ChartControlMeta]) {
        self.metas = metas
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
        
        tableView.separatorColor = DesignBook.shared.color(.primaryBackground)
        tableView.reloadData()
        
        self.tableView = tableView
    }
    
    func reload(mainGraphHeight: CGFloat) {
        metas.forEach { meta in meta.control.updateHeight(mainGraphHeight: mainGraphHeight) }
        tableView?.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return metas.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return standardHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = StatSectionHeader()
        label.text = metas[section].chartMeta.title.uppercased()
        label.textColor = DesignBook.shared.color(.secondaryForeground)
        label.font = DesignBook.shared.font(size: 13, weight: .light)
        return label
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let control = metas[indexPath.section].control
        let height = control.sizeThatFits(tableView.bounds.size).height
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let control = metas[indexPath.section].control
        control.link(to: cell.contentView)
        
        cell.selectionStyle = .none
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let control = metas[indexPath.section].control
        control.unlink()
    }
    
    func updateDesign() {
        tableView?.separatorColor = DesignBook.shared.color(.primaryBackground)
        metas.forEach { meta in meta.control.update() }
    }
}

fileprivate extension IndexPath {
    var isFirstRow: Bool {
        return (row == 0)
    }
}
