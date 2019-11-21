//
//  ViewController.swift
//  UrlSessionLesson
//
//  Created by Константин Богданов on 06/11/2019.
//  Copyright © 2019 Константин Богданов. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	let tableView = UITableView()
	var images: [ImageViewModel] = []
	let reuseId = "UITableViewCellreuseId"
	let interactor: InteractorInput
    var pageCounter: UInt = 1
    
    let searchDelayQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    let searchField: UITextField = {
        let textField = UITextField()
        
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.textAlignment = .center
        textField.placeholder = "Start typing here"
        textField.layer.cornerRadius = 20
        
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        return textField
    }()

	init(interactor: InteractorInput) {
		self.interactor = interactor
		super.init(nibName: nil, bundle: nil)
	}
	required init?(coder: NSCoder) {
		fatalError("Метод не реализован")
	}
	override func viewDidLoad() {
		super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        
        view.addSubview(searchField)
		view.addSubview(tableView)
        searchField.translatesAutoresizingMaskIntoConstraints = false
		tableView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
            // Search field
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            searchField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
            searchField.heightAnchor.constraint(equalToConstant: 40),
            // Table view
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
			tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
			tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
			tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseId)
		tableView.dataSource = self
        tableView.delegate = self
	}
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        // Introduce delayed search
        searchDelayQueue.isSuspended = true
        searchDelayQueue.cancelAllOperations()
        
        if let text = textField.text {
            searchDelayQueue.addOperation {
                self.search(by: text)
            }
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            self.searchDelayQueue.isSuspended = false
        }
    }
    
    

	private func loadImage() {
		let imagePath = "http://s16.stc.all.kpcdn.net/share/i/12/11048313/inx960x640.jpg"
		interactor.loadImage(at: imagePath) { [weak self] image in
			if let image = image {
				let model = ImageViewModel(description: "Тестовая картинка", image: image)
				self?.images = [model]
				DispatchQueue.main.async {
					self?.tableView.reloadData()
				}
			}
		}
	}

	private func search(by searchString: String) {
        images.removeAll()
        pageCounter = 1
		interactor.loadImageList(by: searchString) { [weak self] models in
			self?.loadImages(with: models)
		}
	}

	private func loadImages(with models: [ImageModel]) {
		let models = models.suffix(10)

		let group = DispatchGroup()
		for model in models {
			group.enter()
			interactor.loadImage(at: model.path) { [weak self] image in
				guard let image = image else {
					group.leave()
					return
				}
				let viewModel = ImageViewModel(description: model.description,
											   image: image)
				self?.images.append(viewModel)
				group.leave()
			}

		}

		group.notify(queue: DispatchQueue.main) {
			self.tableView.reloadData()
		}
	}
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return images.count
	}
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == images.count - 1, let text = searchField.text {
            pageCounter += 1
            interactor.loadImageList(by: text, pageNumber: pageCounter) { [weak self] models in
                self?.loadImages(with: models)
            }
        }
    }
    
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
		let model = images[indexPath.row]
		cell.imageView?.image = model.image
		cell.textLabel?.text = model.description
		return cell
	}
}
