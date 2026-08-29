//
//  SessionHandler.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import Get
import RestAPI

public enum SessionCheckResult {
    case error(Error)
    case ok(TokenRefresh?)
    case invalidRefreshToken
}

public struct SessionHandler {
    
    public static func checkAndRenewSession(_ apiClient: APIClient, _ err: OCWAPIError, _ refresh_token: String, _ access_token: String) async -> SessionCheckResult {
        if (err.statusCode == 401) {
            do {
                let refreshResult = try await apiClient.send(Paths.api.token.refresh.post(TokenRefresh(refresh: refresh_token, access: access_token)))
                return .ok(refreshResult.value)
            } catch let e as APIError {
                switch (e) {
                case .unacceptableStatusCode(401):
                    return .invalidRefreshToken
                default:
                    return .error(e)
                }
            } catch let e {
                return .error(e)
            }
        } else {
            return .error(err)
        }
    }
}
