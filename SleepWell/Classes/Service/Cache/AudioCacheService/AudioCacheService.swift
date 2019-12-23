//
//  AudioCacheService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 23/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

// В Resources/Cache лежат аудиофайлы. Когда пользователь запускает проигрывание аудиофайла, мы должны проверять есть ли такой аудиофайл в кеше приложения и если есть - воспроизводить его, иначе - по удаленному url.
protocol ___AudioCacheService {
    // name - название файлы в Resource/Cache
    // cacheName - название файла, сохраненого в кеш (будет передавать как remoteUrl.absoluteString)
    func copy(audio: [CopyResource]) -> Single<Void>
}
