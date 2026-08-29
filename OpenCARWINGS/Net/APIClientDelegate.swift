//
//  APIClientDelegate.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 23.8.2026.
//

import Get
import RestAPI
import Foundation

public struct OCWAPIError : Error {
    let apiError: RestAPIError?
    let statusCode: Int
}

struct OCWAPIClientDelegate: APIClientDelegate {
    
    func client(_ client: APIClient, validateResponse response: HTTPURLResponse, data: Data, task: URLSessionTask) throws {
        guard (200..<300).contains(response.statusCode) else {
            // Try to decode the backend's JSON error
            if let decoded = try? JSONDecoder().decode(RestAPIError.self, from: data) {
                throw OCWAPIError(apiError: decoded, statusCode: response.statusCode)
            }

            throw OCWAPIError(apiError: nil, statusCode: response.statusCode)
        }
    }
}


struct OCWAPIClientFactory {
    public static func createAPIClient(_ url: String, _ token: String? = nil) -> APIClient {
        let language = Locale.preferredLanguages[0]
        let clientConfig = APIClient.Configuration(baseURL: URL(string: url), sessionConfiguration: URLSessionConfiguration.default, delegate: OCWAPIClientDelegate())
        clientConfig.decoder.dateDecodingStrategy = DateUtils.multipleFormats
        clientConfig.sessionConfiguration.httpAdditionalHeaders = ["Authorization": "Bearer \(token ?? "")", "Accept-Language": language]
        clientConfig.sessionConfiguration.timeoutIntervalForRequest = 10
        return APIClient(configuration: clientConfig)
    }
}
