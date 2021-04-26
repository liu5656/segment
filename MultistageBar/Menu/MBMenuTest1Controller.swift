//
//  MBMenuTest1Controller.swift
//  MultistageBar
//
//  Created by x on 2021/4/25.
//  Copyright © 2021 x. All rights reserved.
//

import UIKit

class MBMenuTest1Controller: MBViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = menu
    }
    lazy var menu: MBOrderMenu = {
        let temp = MBOrderMenu.init(frame: CGRect.init(x: 0, y: 0, width: Screen.width, height: Screen.height - Screen.fakeNavBarHeight))
        view.addSubview(temp)
        return temp
    }()

}