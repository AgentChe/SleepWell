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
        
        let size = tableHeaderView.systemLayoutSizeFitting(
            CGSize(width: tableView.frame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        tableHeaderView.frame = CGRect(origin: .zero, size: size)
        tableHeaderView.setup(title: "Meditate", subtitle: "Описание, что дают пользователю материалы представленные в этом разделе.")
        tableView.tableHeaderView = tableHeaderView
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

        return tableView.rx.modelSelected(MeditateCellType.self)
            .asSignal()
            .flatMapFirst { cellType -> Signal<MainRoute> in
                guard case let .meditate(meditate) = cellType else {
                    return Signal.just(.paygate)
                }
                
                return viewModel
                    .getMeditationDetails(meditationId: meditate.id)
                    .map { detail -> MainRoute in
                        guard let details = detail else {
                            return .paygate
                        }
                        return .play(details)
                    }
            }
        
    }
}
