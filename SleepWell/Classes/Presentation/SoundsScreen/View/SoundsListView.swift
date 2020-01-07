//
//  SoundsListView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SoundsListView: UIView {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var conteinerView: UIView!
    @IBOutlet weak var closeButton: UIButton!

    override init(frame: CGRect) {
           super.init(frame: frame)
           initialize()
       }
       
       required init?(coder: NSCoder) {
           super.init(coder: coder)
           initialize()
       }
    
    private func initialize() {
        UINib(nibName: "SoundsListView", bundle: nil).instantiate(withOwner: self, options: nil)
        conteinerView.frame = bounds
        addSubview(conteinerView)

        tableView.register(UINib(nibName: "SoundGroupCell", bundle: nil), forCellReuseIdentifier: "SoundGroupCell")
        tableView.dataSource = self
    }
    
     private let selectedSoundRelay = PublishRelay<SoundModel>()
    private var _elements: [GroupModel] = []
}

extension SoundsListView {

    var elements: Binder<[GroupModel]> {
        return Binder(self) { base, elements in
            base._elements = elements
            base.tableView.reloadData()
        }
    }

    var items: [GroupModel] {
        set {
            _elements = newValue
            tableView.reloadData()
        }
        get {
            return _elements
        }
    }
    
    var selectedItem: Observable<SoundModel> {
        return selectedSoundRelay.asObservable()
    }
}

extension SoundsListView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _elements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundGroupCell", for: indexPath) as! SoundGroupCell
        
        cell.setup(model: _elements[indexPath.row]) { [weak self] element in
            self?.selectedSoundRelay.accept(element)
        }
        
        return cell
    }
}
