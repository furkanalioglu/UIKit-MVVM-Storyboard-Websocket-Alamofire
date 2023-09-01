//
//  NewGroupController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 11.08.2023.
//

import UIKit

protocol NewGroupControllerProtocol : AnyObject {
    func datasReceived(error: String?)
}

class NewGroupController: UIViewController {
    var viewModel = NewGroupViewModel()
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            self.registerNibs()
        }
    }
    
    @IBOutlet weak var nextButtonLabel: UIBarButtonItem!
    
    
    private func registerNibs() {
        tableView.register(UINib(nibName: viewModel.cellId, bundle: nil), forCellReuseIdentifier: viewModel.cellId)
        tableView.register(UINib(nibName: viewModel.headerId, bundle: nil), forHeaderFooterViewReuseIdentifier: viewModel.headerId)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        nextButtonLabel.isEnabled = false
    }
    
    @IBAction func nextButtonHandler(_ sender: Any) {
        performSegue(withIdentifier: viewModel.segueId, sender: viewModel.selectedUsers)
    }
}

extension NewGroupController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = viewModel.users?[indexPath.row] else { return }
        if viewModel.users?[indexPath.row].selectedForCell == nil {
            viewModel.users?[indexPath.row].selectedForCell = false
        }
        
        if viewModel.users?[indexPath.row].selectedForCell == true {
            viewModel.users?[indexPath.row].selectedForCell = false
            
            viewModel.selectedUsers.removeAll { $0 == user.userId }
        } else {
            viewModel.users?[indexPath.row].selectedForCell = true
            viewModel.selectedUsers.append(user.userId)
        }
        tableView.reloadData()
        nextButtonLabel.isEnabled = !viewModel.selectedUsers.isEmpty
    }
}

extension NewGroupController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.users?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellId) as? NewGroupCell else { fatalError("could not load NewGroupCell")}
        cell.user = viewModel.users?[indexPath.row]
        return cell
    }
}

extension NewGroupController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewModel.segueId {
            print("SAVED USERS LOG  segued")
            let vc = segue.destination as? NewGroupEditController
            vc?.viewModel.savedUsers = viewModel.selectedUsers
        }
    }
}

extension NewGroupController : NewGroupControllerProtocol {
    func datasReceived(error: String?) {
        if error != nil {
            print("COULD NOT GET DATAS")
            return
        }else{
            tableView.reloadData()
        }
    }
}


