//
//  SettingsController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import UIKit

class SettingsController: UIViewController {

    let viewModel = SettingsViewModel()
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            self.registerNibs()
        }
    }
    
    private func registerNibs() {
        //Cell nib
        self.tableView.register(UINib(nibName:viewModel.cellNib , bundle: nil), forCellReuseIdentifier: viewModel.cellNib)
        //LogoutCell nib
        self.tableView.register(UINib(nibName:viewModel.logoutCellNib , bundle: nil), forCellReuseIdentifier: viewModel.logoutCellNib)
        
        
    }

    
}

extension SettingsController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            performSegue(withIdentifier: viewModel.segueId, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}



extension SettingsController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellNib) as? SettingsCell else {
                fatalError("Could not load Settings cell !")}
            return cell
        }else{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.logoutCellNib) as? LogoutCell else {
                fatalError("Could not load Logout Cell")
            }
            cell.delegate = self
            return cell
        }
    }
}

extension SettingsController : LogoutCellProtocol{
    func didTapLogoutButton() {
        AuthService.instance.logout { err in
            if let err = err {
                print(err.localizedDescription)
                return
            }
        }
        SocketIOManager.shared().closeConnection()

        AppConfig.instance.currentUser = nil
        AppConfig.instance.pushToken = nil
        UserDefaults.standard.removeObject(forKey: userToken)
        UserDefaults.standard.removeObject(forKey: currentUserIdK)
        UserDefaults.standard.removeObject(forKey: refreshToken)
        
        RootManager.switchRoot(.auth)
        
    }
}

