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
    func configureModeSwitcher(title: String)
}

final class StatViewController: BaseViewController, IStatView {
    var router: IStatRouter!
    weak var interactor: IStatInteractor!
    
    private let tableView = UITableView()
    
    private var dataSource = StatDataSource()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = DesignBook.shared.resolve(colorAlias: .generalBackground)
        view.addSubview(tableView)
        
        dataSource = StatDataSource()
        dataSource.register(in: tableView)
        
        interactor.interfaceStartup()
        
        dataSource.switchModeHandler = { [weak self] in
            self?.router.toggleDesign()
        }
    }

    func configureModeSwitcher(title: String) {
        dataSource.setModeSwitcherTitle(title)
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
}

fileprivate struct Layout {
    let bounds: CGRect
    let topLayoutGuide: UILayoutSupport
    let bottomLayoutGuide: UILayoutSupport
    
    var tableViewFrame: CGRect {
        return bounds
    }
}
