//
//  MBSegmentCollectionView.swift
//  MultistageBar
//
//  Created by x on 2020/4/26.
//  Copyright © 2020 x. All rights reserved.
//

import UIKit

class MBSegmentCollectionView: UICollectionView {

    var paddingWidth: CGFloat = 0
    var threshold: CGFloat = 0
    var lastIndex: Int = 0                              // 当前选中的
    var lastFrame: CGRect = .zero
    var needUpdateIndicator: Bool = false               // 是否需要刷新indicator
    var indicator: MBSegmentIndicatorProtocol? {
        willSet{
            if let temp = indicator as? UIView {
                temp.removeFromSuperview()
            }
        }
    }
    override var frame: CGRect {
        didSet{
            threshold = frame.width * 0.8
        }
    }
    var from: Int = 0
    var to: Int = 0
    func mb_slider(from: Int, to: Int, scale: CGFloat) {
        if self.from != from || self.to != to, scale > 0.9 {
            self.from = from
            self.to = to
            scrollToItem(at: IndexPath.init(row: to, section: 0), at: .centeredHorizontally, animated: true)
            lastIndex = to
        }
        guard let toCell = cellForItem(at: IndexPath.init(row: to, section: 0)) as? MBSegmentCellProtocol else {return}
        guard let fromCell = cellForItem(at: IndexPath.init(row: from, section: 0)) as? MBSegmentCellProtocol else {return}
        fromCell.mb_willFocus(false, scale: scale)
        toCell.mb_willFocus(true, scale: scale)
        guard let _ = indicator, let tempFrom = fromCell as? UICollectionViewCell, let tempTo = toCell as? UICollectionViewCell else {
            return
        }
        mb_indicator(from: tempFrom.frame, fCenter: tempFrom.center, to: tempTo.frame, tCenter: tempTo.center, scale: scale)
    }
    private func mb_indicator(from: CGRect, fCenter: CGPoint, to: CGRect, tCenter: CGPoint, scale: CGFloat) {
        guard let _ = indicator else {return}
        lastFrame = from
        indicator?.mb_slider(fromWidth: from.width, fromCenter: fCenter, toWidth: to.width, toCenter: tCenter, scale: scale)
    }
    func mb_sliderClick(index: IndexPath) {
        guard let _ = indicator, let toCell = cellForItem(at: index) else {return}
        if let from = cellForItem(at: IndexPath.init(row: lastIndex, section: 0)) as? MBSegmentCellProtocol {
            from.mb_willFocus(false, scale: 1)
        }
        (toCell as? MBSegmentCellProtocol)?.mb_willFocus(true, scale: 1)
        lastIndex = index.row
        UIView.animate(withDuration: 0.3) {
            let fCenter = CGPoint.init(x: self.lastFrame.midX, y: self.lastFrame.midY)
            self.mb_indicator(from: self.lastFrame, fCenter: fCenter, to: toCell.frame, tCenter: toCell.center, scale: 1)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let temp = indicator as? UIView, needUpdateIndicator else {return}
        needUpdateIndicator = false
        mb_slider(from: lastIndex, to: lastIndex, scale: 1)
        
        guard temp.superview == nil else {
            sendSubviewToBack(temp)
            return
        }
        addSubview(temp)
        sendSubviewToBack(temp)
    }
    
    override func reloadData() {
        super.reloadData()
        needUpdateIndicator = true
    }
}
