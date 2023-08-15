//
//  ChatInformationController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//

import UIKit

class ChatInformationController: UIViewController {
    
    let viewModel = ChatInformationViewModel()
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            self.registerNibs()
        }
    }
    
    private func registerNibs() {
        tableView.register(UINib(nibName: viewModel.cellNib, bundle: nil), forCellReuseIdentifier: viewModel.cellNib)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("INFODEBUG: \(viewModel.users)")
    }
}

extension ChatInformationController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.users?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellNib) as? ChatInformationCell else {fatalError("Could not load cell")}
        cell.user = viewModel.users?[indexPath.row]
        return cell
    }
    
}

extension ChatInformationController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
