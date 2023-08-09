//
//  UsersController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.

import UIKit

protocol UsersControllerProtocol : AnyObject{
    func didReceivedDatas(error: String?)
}

protocol DidSelectUserProtocol : AnyObject {
    func didSelectUser(user: MessagesCellItem)
}

class UsersController: UIViewController {
    
    let viewModel = UsersViewModel()
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            self.tableView.delegate = self
            self.tableView.dataSource = self
            registerNibs()
        }
    }
    
    private func registerNibs() {
        //Cell nib
        self.tableView.register(UINib(nibName:viewModel.cellNib , bundle: nil), forCellReuseIdentifier: viewModel.cellNib)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.delegate = self
    }
}


//MARK: - Datasource
extension UsersController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.users?.count ?? 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellNib) as? UsersCell else { fatalError("DEBUG2: Could not load users cell")}
        cell.user = viewModel.users?[indexPath.row]
        return cell
    }
    
}

//MARK: - Delegate
extension UsersController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = viewModel.users?[indexPath.row] else { fatalError("COULD NOT FIND USER")}
        print("Preparing to call delegate with user: \(user.id)")  // Debug print statement
        viewModel.selectUserDelegate?.didSelectUser(user: user)
        self.dismiss(animated: true)
    }
}


extension UsersController : UsersControllerProtocol {
    func didReceivedDatas(error: String?) {
        if error != nil {
            print("DEBUG5",error ?? "")
        }else{
            tableView.reloadData()
        }
    }
}
