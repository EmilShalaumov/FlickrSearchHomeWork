//
//  Interactor.swift
//  UrlSessionLesson
//
//  Created by Константин Богданов on 06/11/2019.
//  Copyright © 2019 Константин Богданов. All rights reserved.
//

import UIKit

protocol InteractorInput {
	func loadImage(at path: String, completion: @escaping (UIImage?) -> Void)
    func loadImageList(by searchString: String, pageNumber: UInt, completion: @escaping ([ImageModel]) -> Void)
}

extension InteractorInput {
    func loadImageList(by searchString: String, completion: @escaping ([ImageModel]) -> Void) {
        loadImageList(by: searchString, pageNumber: 1, completion: completion)
    }
}

class Interactor: InteractorInput {
	let networkService: NetworkServiceInput

	init(networkService: NetworkServiceInput) {
		self.networkService = networkService
	}


	func loadImage(at path: String, completion: @escaping (UIImage?) -> Void) {
		networkService.getData(at: path, parameters: nil) { data in
			guard let data = data else {
				completion(nil)
				return
			}
			completion(UIImage(data: data))
		}
	}

    func loadImageList(by searchString: String, pageNumber: UInt, completion: @escaping ([ImageModel]) -> Void) {
        let url = API.searchPath(text: searchString, extras: "url_m", page: String(pageNumber))
		networkService.getData(at: url) { data in
			guard let data = data else {
				completion([])
				return
			}
			let responseDictionary = try? JSONSerialization.jsonObject(with: data, options: .init()) as? Dictionary<String, Any>

			guard let response = responseDictionary,
				let photosDictionary = response["photos"] as? Dictionary<String, Any>,
				let photosArray = photosDictionary["photo"] as? [[String: Any]] else {
					completion([])
					return
			}

			let models = photosArray.map { (object) -> ImageModel in
				let urlString = object["url_m"] as? String ?? ""
				let	title = object["title"] as? String ?? ""
				return ImageModel(path: urlString, description: title)
			}
			completion(models)
		}
	}
}
