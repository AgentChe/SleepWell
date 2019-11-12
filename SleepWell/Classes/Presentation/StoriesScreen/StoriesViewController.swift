//
//  StoriesViewController.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class StoriesViewController: UIViewController {
    
    @IBOutlet private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        tableView.register(UINib(nibName: "StoryCell", bundle: nil), forCellReuseIdentifier: "StoryCell")
        tableView.register(UINib(nibName: "PremiumUnlockCell", bundle: nil), forCellReuseIdentifier: "PremiumUnlockCell")

        let size = tableHeaderView.systemLayoutSizeFitting(
            CGSize(width: tableView.frame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        tableHeaderView.frame = CGRect(origin: .zero, size: size)
        tableHeaderView.setup(title: "Stories", subtitle: "Описание, что дают пользователю материалы представленные в этом разделе.")
        tableView.tableHeaderView = tableHeaderView
    }

    private let tableHeaderView = StoriesHeaderView()
    private let disposeBag = DisposeBag()
}

extension StoriesViewController: BindsToViewModel {
    typealias ViewModel = StoriesViewModel
    typealias Input = Observable<Bool>
    typealias Output = Signal<MainRoute>

    static func make() -> StoriesViewController {
        let storyboard = UIStoryboard(name: "StoriesScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "StoriesViewController") as! StoriesViewController
    }
    
    func bind(to viewModel: StoriesViewModelInterface, with input: Input) -> Output {
        let elements = viewModel.elements(subscription: input)

        elements
            .drive(tableView.rx.items) { table, index, item in
                switch item {
                case let .story(element):
                    let cell = table.dequeueReusableCell(withIdentifier: "StoryCell") as! StoryCell
                    cell.setup(model: element)
                    return cell
                case .premiumUnlock:
                    let cell = table.dequeueReusableCell(withIdentifier: "PremiumUnlockCell") as! PremiumUnlockCell
                    return cell
                }
            }
            .disposed(by: disposeBag)

        let randomElement = tableHeaderView.didTapRandom
            .withLatestFrom(elements)
            .flatMapFirst { viewModel.randomElement(items: $0) }
        
       return Signal
        .merge(
           randomElement,
           tableView.rx.modelSelected(StoriesCellType.self).asSignal()
        )
        .flatMapFirst { cellType -> Signal<MainRoute> in
            guard case let .story(story) = cellType else {
                return Signal.just(.paygate)
            }
            
            return viewModel
                .getStoryDetails(id: story.id)
                .map { detail -> MainRoute in
                    guard let details = detail else {
                        return .paygate
                    }
                    return .play(details)
                }
        }
    }
}
