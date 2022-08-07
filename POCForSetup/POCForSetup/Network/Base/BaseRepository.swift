//
//  BaseRepository.swift
//  POCForSetup
//
//  Created by Yash on 07/08/22.
//

import Foundation

enum APIError: Error {
	case custom(String)
	case currentError(Error)
	case unknownError
	case connectionError
	case invalidCredentials
	case invalidRequest
	case notFound
	case invalidResponse
	case serverError
	case serverUnavailable
	case timeOut
	case unsuppotedURL
}

enum APIMethod {
	case get
	case post
	
	var method: String {
		switch self {
			case .get:
				return "GET"
			case .post:
				return "POST"
		}
	}
}


class BaseRepository {
	
	private func apiRequest(request: URLRequest,
							completion: @escaping (_ data: Data?,_ response: URLResponse?,_ error: Error?) -> Void ) {
		URLSession.shared.dataTask(with: request) {  data,response,error in
			completion(data, response, error)
		}.resume()
	}
	
	
	private func requestDecodable<D:  Decodable>(urlPath: String,
												 httpMethod: APIMethod,
												 completion: @escaping (_ data: D?,_ response: URLResponse?,_ error: APIError?) -> Void ) {
		guard urlPath.isEmpty == false else {
			return completion(nil, nil, .custom("Write according to your requirement"))
		}
		guard let url = URL(string: urlPath) else {
			return completion(nil, nil, .custom("Write according to your requirement"))
		}
		var request = URLRequest(url: url)
		request.httpMethod = httpMethod.method
		apiRequest(request: request) {  [weak self] data,response,error in
			self?.reponsePrintAndSend(request: request, data: data, response: response, error: error, completion: completion)
		}
	}
	
	private func requestEncodableDecodable<E: Encodable,D:  Decodable>(urlPath: String,
																	   parameter: E,
																	   httpMethod: APIMethod,
																	   completion: @escaping (_ data: D?,_ response: URLResponse?,_ error: APIError?) -> Void ) {
		guard urlPath.isEmpty == false else {
			return completion(nil, nil, .custom("Write according to your requirement"))
		}
		guard let url = URL(string: urlPath) else {
			return completion(nil, nil, .custom("Write according to your requirement"))
		}
		var request = URLRequest(url: url)
		request.httpMethod = httpMethod.method
		do {
			request.httpBody = try JSONEncoder().encode(parameter)
			print("API Parameter : \(parameter)")
		} catch (let decoderError) {
			print("Encoder Error: \(decoderError)")
			completion(nil, nil, (decoderError as? APIError) ?? .currentError(decoderError))
			return
		}
		apiRequest(request: request) {  [weak self] data,response,error in
			self?.reponsePrintAndSend(request: request, data: data, response: response, error: error, completion: completion)
		}
	}
	
	private func reponsePrintAndSend<D: Decodable>(request: URLRequest,
												   data: Data?,
												   response: URLResponse?,
												   error: Error?,
												   completion: @escaping (_ data: D?,_ response: URLResponse?,_ error: APIError?) -> Void ) {
		if let url  = request.url {
			print("API Info: -  \(url)")
		}
		if let data = data {
			print("Resposne: \(String(describing: String(data: data, encoding: .utf8)))")
			do {
				let dataResposne = try JSONDecoder().decode(D.self, from: data)
				if let error = error {
					completion(dataResposne, response, (error as? APIError) ?? .currentError(error))
				} else {
					completion(dataResposne, response, nil)
				}
			} catch (let decoderError) {
				if let error = error {
					print("API Error: \(error) \n Decoder Error: \(decoderError)")
					completion(nil, response, (error as? APIError) ?? .currentError(error))
				} else {
					print("Decoder Error: \(decoderError)")
					completion(nil, response, (decoderError as? APIError) ?? .currentError(decoderError))
				}
			}
		} else {
			print("API Error: \(String(describing: error))")
			if let error = error {
				completion(nil, response, (error as? APIError) ?? .currentError(error))
			} else {
				completion(nil, response, .custom("Write according to your requirement"))
			}
		}
	}
	
	func get<D: Decodable>(urlPath: String, completion: @escaping (D?, URLResponse?, APIError?) -> Void) {
		requestDecodable(urlPath: urlPath, httpMethod: .get, completion: completion)
	}
	
	func get<E: Encodable,D: Decodable>(urlPath: String,
										parameter: E,
										completion: @escaping (D?, URLResponse?, APIError?) -> Void) {
		requestEncodableDecodable(urlPath: urlPath, parameter: parameter, httpMethod: .get, completion: completion)
	}
	
	func post<E: Encodable,D: Decodable>(urlPath: String,
										 parameter: E,
										 completion: @escaping (D?, URLResponse?, APIError?) -> Void) {
		requestEncodableDecodable(urlPath: urlPath, parameter: parameter, httpMethod: .get, completion: completion)
	}
}
