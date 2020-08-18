//
//  Logging.swift
//  FinaleControl
//
//  Created by David Keeffe on 17/08/2020.
//  Copyright © 2020 Music3149. All rights reserved.
//

import Foundation
import OSLog

class Logger {
    
    var logger: OSLog
    var appname: String
    
    init(appname: String, location: String) {
        self.appname = appname
        logger = OSLog(subsystem: appname, category: location)
    }
    
    /**
            get a logger instance using the same appname
     */
    
    func getsub(location: String) -> Logger {
        return Logger(appname: self.appname, location: location)
    }
    
    func debug(_ message: String) {
        os_log("DEBUG - %{public}@", log: logger, type: .debug, message)
    }
    
    func error(_ message: String) {
        os_log("ERROR - %{public}@", log: logger, type: .error, message)
    }
    
    func info(_ message: String) {
        os_log("INFO - %{public}@", log: logger, type: .info, message)
    }
}
