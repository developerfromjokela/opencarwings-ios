//
//  WSClient.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import Foundation
import Starscream
import SwiftUI
import RestAPI

public enum WSClientEvent {
    case connected(Bool)
    case disconnected
    case reconnecting
    case clientError(Error?)
    case alert(AlertHistoryFull)
    case serverAck
    case updatedCarInfo(Car)
}

class WSClient {
    // Singleton instance
    static let shared = WSClient()
    
    private var socket: WebSocket
    private var isConnected: Bool = false
    private var isReconnecting: Bool = false
    private var reconnectAttempts: Int = 0
    private let baseReconnectDelay: TimeInterval = 1.5
    public var sendingTrigger: Bool = false
    public var onWSEvent: ((WSClientEvent) -> Void)
    private var request: URLRequest? = nil
    
    private init() {
        var request = URLRequest(url: URL(string: "wss://opencarwings.viaaq.eu")!)
        request.setValue("Bearer default-token", forHTTPHeaderField: "Authorization")
        let language = Locale.preferredLanguages[0]
        request.setValue(language, forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 5
        self.socket = WebSocket(request: request)
        self.onWSEvent = { _ in }
        self.socket.onEvent = { event in
            self.didReceive(event: event)
        }
    }
    
    // Configure the singleton instance with URL, token, and event handler
    func configure(url: String, token: String, onWSEvent: @escaping (WSClientEvent) -> Void, timeoutInterval: TimeInterval = 1.5) {
        isConnected = false
        self.request = URLRequest(url: URL(string: url)!)
        self.request!.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let language = Locale.preferredLanguages[0]
        self.request!.setValue(language, forHTTPHeaderField: "Accept-Language")
        self.request!.timeoutInterval = timeoutInterval
        self.socket = WebSocket(request: self.request!)
        self.onWSEvent = onWSEvent
        self.socket.onEvent = { event in
            self.didReceive(event: event)
        }
    }
    
    
    
    func connect() {
        self.reconnectAttempts = 0
        isReconnecting = false
        socket.connect()
    }
    
    func disconnect() {
        self.reconnectAttempts = 0
        isConnected = false
        isReconnecting = false
        self.onWSEvent = { _ in }
        self.socket.onEvent = { _ in }
        self.socket.disconnect()
    }
    
    func connectionState() -> Bool {
        return self.isConnected
    }
    
    func reconnectState() -> Bool {
        return self.isReconnecting
    }
    
    private func scheduleReconnect() {
        guard !isConnected else {
            return
        }
        
        if !isReconnecting {
            isReconnecting = true
        }
        

        if self.reconnectAttempts == 4 {
            onWSEvent(.reconnecting)
        }
        
        var delay = baseReconnectDelay * pow(1.0, Double(self.reconnectAttempts))
        
        if self.reconnectAttempts == 1 {
            delay = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            guard !isConnected else {
                return
            }
            var count = self.reconnectAttempts
            count += 1
            print(self.reconnectAttempts, count)
            self.reconnectAttempts = count
            
            print(self.reconnectAttempts, count)
            self.socket = WebSocket(request: self.request!)
            print("Attempting to reconnect... Attempt \(self.reconnectAttempts)")
            self.socket.connect()
            self.socket.onEvent = { event in
                self.didReceive(event: event)
            }
        }
    }
    
    func didReceive(event: WebSocketEvent) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            self.isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
            self.onWSEvent(.disconnected)
            self.scheduleReconnect()
        case .text(let string):
            parsePayload(string: string)
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            self.scheduleReconnect()
        case .cancelled:
            self.isConnected = false
            self.scheduleReconnect()
        case .error(let err):
            self.isConnected = false
            self.onWSEvent(.disconnected)
            self.onWSEvent(.clientError(err))
            self.scheduleReconnect()
        case .peerClosed:
            self.isConnected = false
            self.scheduleReconnect()
        }
    }
    
    func parsePayload(string: String) {
        let jsonData = string.data(using: .utf8)!
        print(jsonData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = DateUtils.multipleFormats

        let basePayload: BasePayload = try! decoder.decode(BasePayload.self, from: jsonData)
        
        if basePayload.type == "alert" {
            self.onWSEvent(.alert((try! decoder.decode(AlertPayload.self, from: jsonData) as AlertPayload).data))
        } else if (basePayload.type != "listen") {
            self.onWSEvent(.updatedCarInfo((try! decoder.decode(CarPayload.self, from: jsonData) as CarPayload).data))
        } else {
            self.isReconnecting = false
            self.isConnected = true
            let silent = self.reconnectAttempts < 4
            self.reconnectAttempts = 0
            self.onWSEvent(.serverAck)
            self.onWSEvent(.connected(silent))
        }
    }
}
