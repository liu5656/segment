//
//  MBSegmentMenuView.swift
//  MultistageBar
//
//  Created by x on 2020/4/24.
//  Copyright © 2020 x. All rights reserved.
//

import UIKit

protocol MBSegmentMenuViewDelegate: class {
    func mb_didSelected(index: Int)
}

class MBSegmentMenuView: UIView {
    //MARK: - public
    func mb_show(in content: UIView, contentFrame: CGRect) {
        if header != nil {
            horizontalScroll.frame = CGRect.init(x: self.frame.origin.x, y: 0, width: self.frame.width, height: content.frame.height)
            content.addSubview(horizontalScroll)
            
            content.addSubview(header!)
            
            originalHeaderFrame = header!.frame
            topOffset = header!.frame.maxY
            originalBarFrame = self.frame
        }
        content.addSubview(self)
        if header == nil {
            horizontalScroll.frame = contentFrame
            content.addSubview(horizontalScroll)
        }
    }
    func mb_slider(from: Int, to: Int, scale: CGFloat) {
        menuCV.mb_slider(from: from, to: to, scale: scale)
    }
    func mb_reloadDataTitle() {
        menuCV.reloadData()
    }
    
    //MARK: - utils
    private func mb_handleUpDown(offset: CGPoint, scrollView: UIScrollView) {
        guard header != nil else {return}
        let delta = originalTopOffset + offset.y
        if delta > 0 {
            header?.frame = CGRect.init(origin: CGPoint.init(x: 0, y: originalHeaderFrame.origin.y - min(delta, topOffset)), size: originalHeaderFrame.size)
            self.frame = CGRect.init(origin: CGPoint.init(x: originalBarFrame.origin.x, y: originalBarFrame.origin.y - min(delta, topOffset)), size: originalBarFrame.size)
        }else{
            header?.frame = CGRect.init(origin: CGPoint.init(x: 0, y: originalHeaderFrame.origin.y - max(delta, 0)), size: originalHeaderFrame.size)
            self.frame = CGRect.init(origin: CGPoint.init(x: originalBarFrame.origin.x, y: originalBarFrame.origin.y - max(delta, 0)), size: originalBarFrame.size)
        }
    }
    private func mb_maxWidth() -> CGFloat {
        var width: CGFloat = 0
        datasource.enumerated().forEach { (model) in
            width += model.element.mb_size().width
            if model.offset != datasource.count - 1 {
                width += lineSpacing
            }
        }
        return min(maxWidth, width)
    }
    private func mb_page(at index: Int) -> MBSegmentContentItemProtocol {
        if let temp = contentItems[index] {
            return temp
        }else{
            return contentDatasource!.mb_segmentContent(cellForItemAt: index)
        }
    }
    //判重后再决定是否添加
    private func mb_willShow(at index: Int, item: MBSegmentContentItemProtocol) {
        guard contentItems[index] == nil else {return}
        contentItems[index] = item
        let content = item.mb_view()
        if header == nil {
            content.frame = CGRect.init(origin: CGPoint.init(x: CGFloat(index) * horizontalScroll.frame.width, y: 0), size: CGSize.init(width: horizontalScroll.frame.width, height: horizontalScroll.frame.height))
            horizontalScroll.addSubview(content)
        }else{
            let page: UIScrollView
            if (content as? UIScrollView) != nil {
                content.frame = CGRect.init(origin: CGPoint.init(x: CGFloat(index) * horizontalScroll.frame.width, y: 0), size: horizontalScroll.frame.size)
                page = content as! UIScrollView
            }else{
                page = UIScrollView.init()
                page.frame = CGRect.init(origin: CGPoint.init(x: CGFloat(index) * horizontalScroll.frame.width, y: 0), size: horizontalScroll.frame.size)
                page.showsVerticalScrollIndicator = false
                page.showsHorizontalScrollIndicator = false
                
                page.contentSize = CGSize.init(width: content.frame.width, height: content.frame.height)
                page.addSubview(content)
            }
            page.contentInsetAdjustmentBehavior = .never
            horizontalScroll.addSubview(page)
            page.contentInset = UIEdgeInsets.init(top: originalTopOffset, left: 0, bottom: 0, right: 0)
            page.setContentOffset(CGPoint.init(x: 0, y: -frame.maxY), animated: false)
            page.addObserver(self, forKeyPath: contentOffsetKeyPath, options: .new, context: nil)
        }
    }
    private func mb_willShowAgain(at index: Int, item: MBSegmentContentItemProtocol) {
        guard header != nil else {return}
        let content = item.mb_view()
        guard let temp = (content as? UIScrollView) ?? (content.superview as? UIScrollView),
            temp.contentOffset.y < 0 else {return}
        MBLog("\(temp.contentOffset.y)---- \(-frame.maxY)")
        temp.setContentOffset(CGPoint.init(x: 0, y: -frame.maxY), animated: false)
    }
        
    //MARK: - lazy
    // step 2: 如果设置底部容器代理,就监听contentOffset为滑动做准备
    weak var contentDatasource : MBSegmentContentDatasource? {
        didSet{
            horizontalScroll.addObserver(self, forKeyPath: contentOffsetKeyPath, options: .new, context: nil)
        }
    }
    // menu
    weak var delegate: MBSegmentMenuViewDelegate?
    var sectionInset: UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: 5)
    var maxWidth: CGFloat = UIScreen.main.bounds.width
    var lineSpacing: CGFloat = 0
    var itemHeight: CGFloat = 40
    var contentRadius: CGFloat = 0
    var corners: CACornerMask = [.layerMinXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    var contentColor: UIColor = UIColor.clear
    var selectedIndex: Int = 0
    var indicator: MBSegmentIndicatorProtocol? {
        didSet{
            menuCV.indicator = indicator
        }
    }
    
    
    deinit {
        if header != nil {
            horizontalScroll.subviews.forEach { (view) in
                if view is UIScrollView {
                    view.removeObserver(self, forKeyPath: contentOffsetKeyPath)
                }
            }
        }
        if contentDatasource != nil {
            horizontalScroll.removeObserver(self, forKeyPath: contentOffsetKeyPath)            
        }
    }
    
    // header 只有一级菜单才有header,多级菜单要出问题
    var header: UIView?
    private var originalHeaderFrame: CGRect = .zero
    private var originalBarFrame: CGRect = .zero
    private var originalTopOffset: CGFloat {
        get{
            return originalBarFrame.maxY
        }
    }
    var topOffset: CGFloat = 100
    var datasource: [MBSegmentModelProtocol] = [] {
        didSet{
            let width = min(bounds.width, sectionInset.left + mb_maxWidth() + sectionInset.right)
            menuCV.frame = CGRect.init(x: (bounds.size.width - width) * 0.5, y: (bounds.size.height - itemHeight) * 0.5, width: width, height: itemHeight)
            #warning("1.0 todo 忘记逻辑了")
//            menuCV.paddingWidth = datasource.first?.style?.paddingWidth ?? 0
            datasource.forEach { (model) in
                menuCV.register(model.style.cellClass, forCellWithReuseIdentifier: model.style.identify)
            }
            menuCV.reloadData()
            // 更新contentsize
            guard let number = contentDatasource?.mb_segmentContentNumber() else {return}
            horizontalScroll.contentSize = CGSize.init(width: horizontalScroll.frame.width * CGFloat(number), height: horizontalScroll.frame.height)
            guard contentItems.count == 0, datasource.count > 0 else {return}
            mb_willShow(at: 0, item: mb_page(at: 0))
        }
    }
    
    // content
    private let contentOffsetKeyPath = "contentOffset"
    private var lastContentOffset: CGPoint = .zero
    private var contentItems: [Int: MBSegmentContentItemProtocol] = [:]
    private lazy var horizontalScroll: UIScrollView = {
        let scr = UIScrollView.init()
        scr.contentInsetAdjustmentBehavior = .never
        scr.isPagingEnabled = true
        scr.bounces = false
        scr.showsVerticalScrollIndicator = false
        scr.showsHorizontalScrollIndicator = false
        scr.scrollsToTop = false
        return scr
    }()
    private lazy var menuCV: MBSegmentCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let col = MBSegmentCollectionView.init(frame: .zero, collectionViewLayout: layout)
        col.showsVerticalScrollIndicator = false
        col.showsHorizontalScrollIndicator = false
        col.backgroundColor = contentColor
        if contentRadius > 0 {
            col.layer.cornerRadius = contentRadius
            col.layer.maskedCorners = corners
        }
        col.scrollsToTop = false
        col.dataSource = self
        col.delegate = self
        addSubview(col)
        return col
    }()
    
    //MARK: - kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == contentOffsetKeyPath, let currentOffset = change?[NSKeyValueChangeKey.newKey] as? CGPoint, let scroll = object as? UIScrollView else {return}
        guard scroll == horizontalScroll else {
            mb_handleUpDown(offset: currentOffset, scrollView: scroll)
            return
        }
        defer {
            lastContentOffset = currentOffset
        }

        let multiple = currentOffset.x / horizontalScroll.frame.width
        let leftToRight = currentOffset.x > lastContentOffset.x
        let from = leftToRight ? floor(multiple) : ceil(multiple)
        let to = leftToRight ? from + 1 : from - 1
        let scale = (currentOffset.x - from * horizontalScroll.frame.width) / ((to - from) * horizontalScroll.frame.width)
        if scale > 0.1, contentItems[Int(to)] == nil { // 超过scroll宽度0.1就要准备数据
            mb_willShow(at: Int(to), item: mb_page(at: Int(to)))
        }else if scale > 0.1, header != nil {
            mb_willShowAgain(at: Int(to), item: mb_page(at: Int(to)))
        }
        // 滚动条变化
        guard from != to, scale != 0 else {return}
        menuCV.mb_slider(from: Int(from), to: Int(to), scale: scale)
    }
}

//MARK: - UICollectionViewDataSource
extension MBSegmentMenuView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasource.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = datasource[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.style.identify, for: indexPath) as? MBSegmentCellProtocol else {
            return UICollectionViewCell()
        }
        cell.mb_update(model: data)
        cell.mb_update(style: data.style)
        return cell as! UICollectionViewCell
    }
}

//MARK: - UICollectionViewDelegate
extension MBSegmentMenuView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if contentDatasource != nil {
            
            horizontalScroll.setContentOffset(CGPoint.init(x: CGFloat(indexPath.row) * horizontalScroll.frame.width, y: 0), animated: false)
            menuCV.mb_sliderClick(index: indexPath)
            
            if contentItems[indexPath.row] == nil {
                mb_willShow(at: indexPath.row, item: mb_page(at: indexPath.row))
            }else{
                mb_willShowAgain(at: indexPath.row, item: mb_page(at: indexPath.row))
            }
        }else{
            menuCV.mb_slider(from: menuCV.lastIndex, to: indexPath.row, scale: 1)
        }
        delegate?.mb_didSelected(index: indexPath.row)
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension MBSegmentMenuView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = datasource[indexPath.row].mb_size()
        return CGSize.init(width: size.width, height: itemHeight)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInset
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
}
