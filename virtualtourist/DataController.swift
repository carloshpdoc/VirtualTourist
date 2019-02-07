//
//  DataController.swift
//  virtualtourist
//
//  Created by carloshenrique.carmo on 06/02/19.
//  Copyright © 2019 carloshpdoc. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentConainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return persistentConainer.viewContext
    }
    
    init(modelName: String) {
        persistentConainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentConainer.loadPersistentStores { storeDescription, error in
            
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            completion?()
        }
    }
}

extension DataController {
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("AutoSaving")
        
        guard interval > 0 else {
            print("Cannot set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
