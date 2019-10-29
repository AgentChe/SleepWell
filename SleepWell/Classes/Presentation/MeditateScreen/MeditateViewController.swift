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

    static func make() -> MeditateViewController {
        let storyboard = UIStoryboard(name: "MeditateScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "MeditateViewController") as! MeditateViewController
    }
    
    func bind(to viewModel: MeditateViewModelInterface, with input: ()) -> () {
        
        viewModel.elements(selectedTag: tableHeaderView.selectTag)
            .drive(tableView.rx.items) { table, index, item in
                switch item {
                case let .meditate(element):
                    let cell = table.dequeueReusableCell(withIdentifier: "MeditateCell") as! MeditateCell
                    let model = MeditateCell.Model(image: "Image1", title: element.name, subtitle: element.reader, avatar: "avatar", isAvailable: element.paid)
                    cell.setup(model: model)
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

        tableView.rx.modelSelected(MeditateCellType.self)
            .bind { viewModel.didTapCell(model: $0) }
            .disposed(by: disposeBag)
    }
}
