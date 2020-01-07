//
//  SoundsViewModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright (c) 2020 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol SoundsViewModelInterface {
    func sounds() -> Driver<[GroupModel]>
}

final class SoundsViewModel: BindableViewModel {
    typealias Interface = SoundsViewModelInterface
    
    lazy var router: SoundsRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {}
}

extension SoundsViewModel: SoundsViewModelInterface {
    
    func sounds() -> Driver<[GroupModel]> {
        let sounds1 = [SoundModel(id: 0, name: "i_s_004", image: "i_s_004"),
                      SoundModel(id: 1, name: "i_s_005", image: "i_s_005"),
                      SoundModel(id: 2, name: "i_s_006", image: "i_s_006"),
                      SoundModel(id: 3, name: "i_s_007", image: "i_s_007"),
                      SoundModel(id: 4, name: "i_s_008", image: "i_s_008"),
                      SoundModel(id: 5, name: "i_s_009", image: "i_s_009"),
                      SoundModel(id: 6, name: "i_s_010", image: "i_s_010"),
                      SoundModel(id: 7, name: "i_s_011", image: "i_s_011"),
                      SoundModel(id: 8, name: "i_s_012", image: "i_s_012"),
                      SoundModel(id: 9, name: "i_s_013", image: "i_s_013")]
        
        let sounds2 = [SoundModel(id: 10, name: "i_s_011", image: "i_s_011"),
        SoundModel(id: 11, name: "i_s_012", image: "i_s_012"),
        SoundModel(id: 12, name: "i_s_013", image: "i_s_013")]
        
        let sounds3 = [SoundModel(id: 13, name: "i_s_001", image: "i_s_001"),
        SoundModel(id: 14, name: "i_s_012", image: "i_s_012"),
        SoundModel(id: 15, name: "i_s_013", image: "i_s_013")]
        
        
        let sounds4 = [SoundModel(id: 16, name: "i_s_001", image: "i_s_001"),
        SoundModel(id: 17, name: "i_s_002", image: "i_s_002"),
        SoundModel(id: 18, name: "i_s_003", image: "i_s_003"),
        SoundModel(id: 19, name: "i_s_004", image: "i_s_004"),
        SoundModel(id: 20, name: "i_s_012", image: "i_s_012"),
        SoundModel(id: 21, name: "i_s_013", image: "i_s_013")]
        
        let sounds5 = [SoundModel(id: 22, name: "i_s_001", image: "i_s_001"),
        SoundModel(id: 23, name: "i_s_013", image: "i_s_013")]
        
        let sounds6 = [SoundModel(id: 24, name: "i_s_001", image: "i_s_001"),
        SoundModel(id: 25, name: "i_s_002", image: "i_s_002"),
        SoundModel(id: 26, name: "i_s_003", image: "i_s_003"),
        SoundModel(id: 27, name: "i_s_004", image: "i_s_004"),
        SoundModel(id: 28, name: "i_s_005", image: "i_s_005"),
        SoundModel(id: 29, name: "i_s_006", image: "i_s_006"),
        SoundModel(id: 30, name: "i_s_007", image: "i_s_007")]
        
        let sounds7 = [SoundModel(id: 31, name: "i_s_001", image: "i_s_001"),
        SoundModel(id: 32, name: "i_s_002", image: "i_s_002"),
        SoundModel(id: 33, name: "i_s_003", image: "i_s_003"),
        SoundModel(id: 34, name: "i_s_004", image: "i_s_004"),
        SoundModel(id: 35, name: "i_s_009", image: "i_s_009"),
        SoundModel(id: 36, name: "i_s_010", image: "i_s_010"),
        SoundModel(id: 37, name: "i_s_011", image: "i_s_011"),
        SoundModel(id: 38, name: "i_s_012", image: "i_s_012"),
        SoundModel(id: 39, name: "i_s_013", image: "i_s_013")]
        
        let elements = [GroupModel(name: "Air", sounds: sounds1),
                        GroupModel(name: "Water", sounds: sounds2),
                        GroupModel(name: "Earth", sounds: sounds3),
                        GroupModel(name: "Creatures", sounds: sounds4),
                        GroupModel(name: "Noize", sounds: sounds5),
                        GroupModel(name: "Abstract", sounds: sounds6),
                        GroupModel(name: "Other", sounds: sounds7)]
        
        return Driver.just(elements)
    }
}
