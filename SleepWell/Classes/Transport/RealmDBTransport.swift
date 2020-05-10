//
//  RealmDBTransport.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RealmSwift

class RealmDBTransport {
    func loadData<E, R: Object>(realmType: R.Type, filter: NSPredicate? = nil, map: @escaping (R) -> (E)) -> Single<[E]> {
        return Single.create { single in
            
            guard let realm = try? Realm(configuration: RealmDBTransport.realmConfiguration) else {
                single(.error(DataBaseError.failedToInitialize))
                return Disposables.create()
            }
            
            var results = realm.objects(R.self)
            if filter != nil {
                results = results.filter(filter!)
            }
            
            let objects: [E] = results.map { obj -> E in
                return map(obj)
            }
            
            single(.success(objects))
            
            return Disposables.create()
        }
    }
    
    func saveData<E, R: Object>(entities: [E], map: @escaping (E) -> (R)) -> Single<Void> {
        return Single.create { single in
            
            guard let realm = try? Realm(configuration: RealmDBTransport.realmConfiguration) else {
                single(.error(DataBaseError.failedToInitialize))
                return Disposables.create()
            }
            
            let objects = entities.map { entity -> R in
                return map(entity)
            }
            
            do {
                try realm.write{
                    realm.add(objects, update: .all)
                }
                
                single(.success(Void()))
            }
            catch _ {
                single(.error(DataBaseError.failedToWrite))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteData<R: Object>(realmType: R.Type, filter: NSPredicate? = nil) -> Single<Void> {
        return Single.create { single in
            
            guard let realm = try? Realm(configuration: RealmDBTransport.realmConfiguration) else {
                single(.error(DataBaseError.failedToInitialize))
                return Disposables.create()
            }
            
            do {
                try realm.write {
                    var results = realm.objects(R.self)
                    if filter != nil {
                        results = results.filter(filter!)
                    }
                    
                    realm.delete(results)
                }
                
                single(.success(Void()))
            }
            catch _ {
                single(.error(DataBaseError.failedToWrite))
            }
            
            return Disposables.create()
        }
    }
    
    private static let realmConfiguration = Realm.Configuration(
        schemaVersion: 2,
        deleteRealmIfMigrationNeeded: true
    )
}
