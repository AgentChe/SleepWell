//
//  PickerView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 30/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

protocol PickerViewItem {}

class PickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    var didSelectItem: ((PickerViewItem) -> ())?
    
    private var items: [PickerViewItem] = []
    private var mapItemToPresentation: ((PickerViewItem) -> (String))!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    private func configure() {
        dataSource = self
        delegate = self
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        
        if let v = view as? UILabel {
            label = v
        } else {
            label = UILabel()
            label.textColor = .white
            label.font = UIFont(name: "Poppins-SemiBold", size: 17)
            label.textAlignment = .center
        }
        
        label.text = mapItemToPresentation(items[row])
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        didSelectItem?(items[row])
    }
    
    func bind(items: [PickerViewItem], map: @escaping (PickerViewItem) -> String) {
        self.items = items
        self.mapItemToPresentation = map
        
        reloadAllComponents()
        
        if !items.isEmpty {
            delegate?.pickerView?(self, didSelectRow: 0, inComponent: 0)
        }
    }
}
