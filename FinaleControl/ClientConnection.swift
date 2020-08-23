//
//  ClientConnection.swift
//  netclass
//
//  Created by David Keeffe on 21/08/2020.
//  Copyright © 2020 Music3149. All rights reserved.
//

import Foundation
import Network

@available(macOS 10.14, *)
class ClientConnection {
    let nwConnection: NWConnection
    let queue = DispatchQueue(label: "Client connection Q")
    typealias ClientReceiver = (_ data: Data) -> Void

    var receiver: ClientReceiver = {
        data in
        let message = String(data: data, encoding: .utf8)
        print("connection did receive, data: \(data as NSData) string: \(message ?? "-")")
        return
    }

    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
    }

    var didStopCallback: ((Error?) -> Void)?
    var readyCallback: (() -> Void)?

    func start() {
        print("connection will start")
        nwConnection.stateUpdateHandler = stateDidChange(to:)
        setupReceive()
        nwConnection.start(queue: queue)
    }

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("Client connection ready")
            if let rcb = readyCallback {
                rcb()
            }
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }

    private func setupReceive() {
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self.receiver(data)
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }

    func send(data: Data) {
        nwConnection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            print("connection did send, data: \(data as NSData)")
        })
    }

    func stop() {
        print("connection will stop")
        stop(error: nil)
    }

    private func connectionDidFail(error: Error) {
        print("connection did fail, error: \(error)")
        stop(error: error)
    }

    private func connectionDidEnd() {
        print("connection did end")
        stop(error: nil)
    }

    private func stop(error: Error?) {
        nwConnection.stateUpdateHandler = nil
        nwConnection.cancel()
        if let didStopCallback = self.didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
}
