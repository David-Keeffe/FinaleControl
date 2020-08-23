//
//  Client.swift
//  netclass
//
//  Created by David Keeffe on 21/08/2020.
//  Copyright © 2020 Music3149. All rights reserved.
//

import Foundation
import Network

@available(macOS 10.14, *)
class TCPClient {
    let connection: ClientConnection
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    var onReady: (() -> Void)?
    var ender: ((Error?) -> Void)?
    var receiver: ((Data) -> Void)? = {
        data in
        let message = String(data: data, encoding: .utf8)
        print("CLIENT did receive, data: \(data as NSData) string: \(message ?? "-")")
    }

    init(host: String, port: UInt16) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        let nwConnection = NWConnection(host: self.host, port: self.port, using: .tcp)
        connection = ClientConnection(nwConnection: nwConnection)
    }

    func start() {
        print("Client started \(host) \(port)")
        if let onr = onReady {
            connection.readyCallback = onr
        }
        if let rcv = receiver {
            connection.receiver = rcv
        }
        connection.didStopCallback = didStopCallback(error:)
        connection.start()
    }

    func stop() {
        connection.stop()
    }

    func send(data: Data) {
        connection.send(data: data)
    }

    func didReceive(data: Data) {
        let message = String(data: data, encoding: .utf8)
        print("CLIENT did receive, data: \(data as NSData) string: \(message ?? "-")")
    }

    func didStopCallback(error: Error?) {
        if let stopper = self.ender {
            stopper(error)
        }
    }
}
