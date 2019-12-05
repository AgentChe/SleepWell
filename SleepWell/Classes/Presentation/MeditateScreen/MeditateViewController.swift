//
//  MeditateViewController.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 26/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class MeditateViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        tableView.register(UINib(nibName: "MeditateCell", bundle: nil), forCellReuseIdentifier: "MeditateCell")
        tableView.register(UINib(nibName: "PremiumUnlockCell", bundle: nil), forCellReuseIdentifier: "PremiumUnlockCell")
        
        var tableHeaderFrame = tableHeaderView.frame
        tableHeaderFrame.size.width = tableView.frame.size.width
        tableHeaderView.frame = tableHeaderFrame
        
        tableHeaderView.setNeedsLayout()
        tableHeaderView.layoutIfNeeded()
        
        let height = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        var tableHeaderUpdatedFrame = tableHeaderView.frame
        tableHeaderUpdatedFrame.size.height = height
        
        tableHeaderView.frame = tableHeaderUpdatedFrame
        
        tableHeaderView.setup(title: "Meditate", subtitle: "meditations_subtitle".localized)
        tableView.tableHeaderView = tableHeaderView
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: GlobalDefinitions.tableBottomInsert, right: 0)
    }

    private let tableHeaderView = MeditateHeaderView()
    private let disposeBag = DisposeBag()
}

extension MeditateViewController: BindsToViewModel {
    typealias ViewModel = MeditateViewModel
    typealias Input = Observable<Bool>
    typealias Output = Signal<MainRoute>

    static func make() -> MeditateViewController {
        let storyboard = UIStoryboard(name: "MeditateScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "MeditateViewController") as! MeditateViewController
    }
    
    func bind(to viewModel: MeditateViewModelInterface, with input: Input) -> Output {
        
        viewModel.elements(subscription: input, selectedTag: tableHeaderView.selectTag)
            .drive(tableView.rx.items) { table, index, item in
                switch item {
                case let .meditate(element):
                    let cell = table.dequeueReusableCell(withIdentifier: "MeditateCell") as! MeditateCell
                    cell.setup(model: element)
                    return cell
                case .premiumUnlock:
                    let cell = table.dequeueReusableCell(withIdentifier: "PremiumUnlockCell") as! PremiumUnlockCell
                    return cell
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.tags(selectedTag: tableHeaderView.selectTag)
            .drive(tableHeaderView.rx.tags)
            .disposed(by: disposeBag)
        
        tableHeaderView.didTapMenu
            .emit(onNext: { [weak self] in
                let vc = SettingsViewController()
                vc.modalPresentationStyle = .overFullScreen
                self?.present(vc, animated: false)
            })
            .disposed(by: disposeBag)

        return tableView.rx.modelSelected(MeditateCellType.self)
            .asSignal()
            .flatMapFirst { cellType -> Signal<MainRoute> in
                guard case let .meditate(meditate) = cellType else {
                    return Signal.just(.paygate)
                }
                
                return viewModel
                    .getMeditationDetails(meditationId: meditate.id, subscription: input)
                    .map { action -> MainRoute in
                        switch action {
                        case .paygate:
                            return .paygate
                        case let .detail(detail):
                            guard let recording = detail else {
                                assertionFailure(" ⚠️ Пустая запись ⚠️")
                                return .paygate
                            }
                            return .play(recording)
                        }
                    }
            }
    }
}
