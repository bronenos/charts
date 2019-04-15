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
    func setChartMetas(_ metas: [ChartMeta])
    func setDesignSwitcher(title: String)
}

final class StatViewController: BaseViewController, IStatView, IChartControlDelegate {
    var router: IStatRouter!
    weak var interactor: IStatInteractor!
    
    private let rightBarButton = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    private let dataSource = StatDataSource()
    private var chartControls = [ChartControl]()

    override init(designObservable: BroadcastObservable<DesignBookStyle>) {
        super.init(designObservable: designObservable)
        
        rightBarButton.target = self
        rightBarButton.action = #selector(handleDesignToggle)
        navigationItem.rightBarButtonItem = rightBarButton
        
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func setChartMetas(_ metas: [ChartMeta]) {
        let localeProvider = interactor.localeProvider
        let formattingProvider = interactor.formattingProvider
        let feedbackDriver = interactor.feedbackDriver
        
        chartControls.forEach { control in control.setDelegate(nil) }
        chartControls = metas.map { meta in
            ChartControl(
                chart: meta.chart,
                mainGraphHeight: DesignBook.shared.mainGraphHeight(
                    bounds: view.bounds,
                    traitCollection: traitCollection
                ),
                localeProvider: localeProvider,
                formattingProvider: formattingProvider,
                feedbackDriver: feedbackDriver
            )
        }
        chartControls.forEach { control in control.setDelegate(self) }
        
        dataSource.setMetas(
            metas: zip(metas, chartControls).map { meta, control in
                return ChartControlMeta(chartMeta: meta, control: control)
            }
        )
    }
    
    func setDesignSwitcher(title: String) {
        rightBarButton.title = title
    }
    
    override func updateDesign() {
        super.updateDesign()
        
        tableView.backgroundColor = DesignBook.shared.color(.spaceBackground)
        rightBarButton.tintColor = DesignBook.shared.color(.actionForeground)
        dataSource.updateDesign()
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
    
    @objc private func handleDesignToggle() {
        interactor.toggleDesign()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        dataSource.reload(
            mainGraphHeight: DesignBook.shared.mainGraphHeight(
                bounds: view.bounds,
                traitCollection: traitCollection
            )
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
