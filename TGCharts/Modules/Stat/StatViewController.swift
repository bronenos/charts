//  
//  StatViewController.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IStatView: class {
    func setTitle(_ title: String)
    func setCharts(titlePrefix: String, charts: [Chart])
    func setDesignSwitcher(title: String)
}

final class StatViewController: BaseViewController, IStatView, IChartControlDelegate {
    var router: IStatRouter!
    weak var interactor: IStatInteractor!
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    private let dataSource = StatDataSource()
    private var chartControls = [IChartControl]()

    override init(designObservable: BroadcastObservable<DesignBookStyle>) {
        super.init(designObservable: designObservable)
        
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        
        dataSource.switchDesignHandler = { [weak self] in
            self?.interactor.toggleDesign()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func setCharts(titlePrefix: String, charts: [Chart]) {
        let formattingProvider = interactor.formattingProvider
        chartControls.forEach { control in control.setDelegate(nil) }
        chartControls = charts.map { ChartControl(chart: $0, formattingProvider: formattingProvider) }
        chartControls.forEach { control in control.setDelegate(self) }
        
        dataSource.setChartControls(titlePrefix: titlePrefix, controls: chartControls)
    }
    
    func setDesignSwitcher(title: String) {
        dataSource.setDesignSwitcherTitle(title)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        
        dataSource.register(in: tableView)
        interactor.interfaceStartup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let layout = getLayout(size: view.bounds.size)
        tableView.frame = layout.tableViewFrame
    }
    
    override func updateDesign() {
        super.updateDesign()
        
        tableView.backgroundColor = DesignBook.shared.color(.spaceBackground)
        dataSource.updateDesign()
    }

    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            topLayoutGuide: topLayoutGuide,
            bottomLayoutGuide: bottomLayoutGuide
        )
    }
    
    func chartControlDidBeginInteraction() {
        tableView.isScrollEnabled = false
    }
    
    func chartControlDidEndInteraction() {
        tableView.isScrollEnabled = true
    }
    
}

fileprivate struct Layout {
    let bounds: CGRect
    let topLayoutGuide: UILayoutSupport
    let bottomLayoutGuide: UILayoutSupport
    
    var tableViewFrame: CGRect {
        return bounds
    }
}
