//
//  OnboardingAimsView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct OnboardingAimItem {
    let aim: Aim
    let title: String
    private(set) var isSelected: Bool
    
    mutating func changeSelection() {
        isSelected = !isSelected
    }
}

final class OnboardingAimsView: UIView, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!
    
    let nextUpWithAims = PublishRelay<[Aim]>()
    
    private let disposeBag = DisposeBag()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    private func configure() {
        Bundle.main.loadNibNamed("OnboardingAimsView", owner: self)
        frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(containerView)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib(nibName: "OnboardingAimTableCell", bundle: nil), forCellReuseIdentifier: "OnboardingAimTableCell")
        
        updateNextButton()
        
        nextButton.rx.tap
            .map { [weak self] _ -> [Aim] in
                return self?.items.filter { $0.isSelected }.map { $0.aim } ?? []
            }
            .bind(to: nextUpWithAims)
            .disposed(by: disposeBag)
    }
    
    func show() {
        SDKStorage.shared
            .amplitudeManager
            .logEvent(name: "Help you with scr", parameters: [:])
        
        isHidden = false
        alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.alpha = 1
        })
    }
    
    func hide(completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.alpha = 0
        }, completion: { [weak self] _ in
            self?.isHidden = true
            
            completion()
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 0 : items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OnboardingAimTableCell") as! OnboardingAimTableCell
        cell.bind(item: items[indexPath.row])
        
        cell.selectItem = { [weak self] item in
            self?.updateItems(changed: item)
            self?.updateNextButton()
            self?.tableView.reloadData()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return section == 0 ? OnboardingAimTableHeader() : UIView()
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? UITableView.automaticDimension : 0
    }
    
    private func updateItems(changed item: OnboardingAimItem) {
        guard let index = items.firstIndex(where: { $0.aim == item.aim }) else {
            return
        }
        
        items[index].changeSelection()
    }
    
    private func updateNextButton() {
        let isEmpty = items.filter { $0.isSelected }.count == 0
        nextButton.isUserInteractionEnabled = !isEmpty
        nextButton.alpha = isEmpty ? 0.1 : 1
    }
    
    private var items: [OnboardingAimItem] = [
        OnboardingAimItem(aim: .betterSleep, title: "better_sleep".localized, isSelected: false),
        OnboardingAimItem(aim: .increaseHappiness, title: "increase_happiness".localized, isSelected: false),
        OnboardingAimItem(aim: .morningEasier, title: "mornings_easier".localized, isSelected: false),
        OnboardingAimItem(aim: .reduceStress, title: "reduce_stress".localized, isSelected: false),
        OnboardingAimItem(aim: .manageTinnitus, title: "manage_tinnitus".localized, isSelected: false),
        OnboardingAimItem(aim: .buildSelfEstreem, title: "build_self_esteem".localized, isSelected: false)
    ]
}
