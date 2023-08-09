//
//  EditProfileController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import UIKit

protocol EditProfileDelegate : AnyObject {
    func didTapSaveUser(updates: UpdateUserModel)
}

class EditProfileController: UIViewController {
    
    let viewModel = EditProfileViewModel()
    
    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            self.registerNibs()
        }
    }
    
    private func registerNibs() {
        //cell
        self.tableView.register(UINib(nibName:viewModel.cellNib , bundle: nil), forCellReuseIdentifier: viewModel.cellNib)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension EditProfileController : UITableViewDelegate {
    
}

extension EditProfileController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellNib) as? EditProfileCell else { fatalError("COULD NOT LOAD EDIT PROFILE CELL ")}
        cell.delegate = self
        return cell
    }
}

extension EditProfileController : EditProfileDelegate {
    func didTapSaveUser(updates: UpdateUserModel) {
        //CHECKLOG: CONFIGURED TO MVVM
        viewModel.setUpdates(updates: updates)
    }
}

