//
//  UITableViewExtension.swift
//  SleepWell
//
//  Created by Alexander Mironov on 29/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


extension Reactive where Base: UITableView {
    
    var scrollToTop: Binder<Void> {
        Binder(base) { base, _ in
            base.scrollToTop()
        }
    }
}

private extension UITableView {
    
    func scrollToTop() {
        let offset = CGPoint(x: 0, y: -adjustedContentInset.top)
        if !isDragging && contentOffset != offset {
            setContentOffset(offset, animated: true)
        }
    }
}
