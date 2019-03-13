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
    func setCharts(titlePrefix: String, charts: [StatChart])
    func setDesignSwitcher(title: String)
}

final class StatViewController: BaseViewController, IStatView {
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
    
    func setCharts(titlePrefix: String, charts: [StatChart]) {
        chartControls = charts.map(ChartControl.init)
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
        
        tableView.backgroundColor = DesignBook.shared.resolve(colorAlias: .generalBackground)
        dataSource.updateDesign()
        
        let chartBackground = DesignBook.shared.resolve(colorAlias: .elementRegularBackground)
        chartControls.forEach { control in control.setBackgroundColor(chartBackground) }
    }

    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            topLayoutGuide: topLayoutGuide,
            bottomLayoutGuide: bottomLayoutGuide
        )
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
