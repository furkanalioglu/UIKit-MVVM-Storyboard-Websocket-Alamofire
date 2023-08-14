//
//  MessageController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 31.07.2023.
//

import UIKit

class MessagesController: UIViewController{
    
    let viewModel = MessagesViewModel()
    
    @IBOutlet weak var showSheetButtonOutlet: UINavigationItem!
    
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.registerNibs()
        }
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private func registerNibs() {
        tableView.register(UINib(nibName: viewModel.cellId, bundle: nil), forCellReuseIdentifier: viewModel.cellId)
        tableView.register(UINib(nibName: viewModel.headerId, bundle: nil),forHeaderFooterViewReuseIdentifier: viewModel.headerId)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        SocketIOManager.shared().delegate = self
        tableView.reloadData()
        
        NotificationCenter.default.addObserver(self,selector: #selector(handleNotificationArrived),name: .notificationArrived,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserDidEnterForeground), name: .userDidEnterForeground, object: nil)
    }
    
    @IBAction func showSheetButton(_ sender: Any) {
        performSegue(withIdentifier: viewModel.usersSegueId, sender: nil)
    }
    
    @objc func handleNotificationArrived() {
        guard let index = (viewModel.messages?.firstIndex(where: {$0.id == AppConfig.instance.dynamicLinkId})) else {
            self.viewModel.getAllMessages()
            return
        }
        let user = viewModel.messages?[index]
        if AppConfig.instance.dynamicLinkId != nil  && AppConfig.instance.currentChat == nil{
            performSegue(withIdentifier: viewModel.chatSegueId, sender: user)
        }
    }
    
    @objc func handleUserDidEnterForeground() {
        viewModel.getAllMessages()
    }
    
    @IBAction func segmentedControlHandler(_ sender: Any) {
        let segment = segmentedControl.selectedSegmentIndex == 0 ? SegmentedIndex.messages : SegmentedIndex.groups
        viewModel.switchSegment(to: segment)
        tableView.reloadData()
    }
}

extension MessagesController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.arrayCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellId) as? MessagesCell else {
            fatalError("COULD NOT LOAD MESSAGES CELL")
        }
        switch viewModel.currentSegment {
         case .messages:
             cell.message = viewModel.messages?[indexPath.row]
         case .groups:
             cell.group = viewModel.groups?[indexPath.row]
         }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}


extension MessagesController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch viewModel.currentSegment {
        case .messages:
            guard let userId = viewModel.messages?[indexPath.row] else { fatalError("COULD NOT FIND USER")}
            performSegue(withIdentifier: viewModel.chatSegueId, sender: userId)
            viewModel.messages?[indexPath.row].isSeen = true
            tableView.deselectRow(at: indexPath, animated: true)
            
        case .groups:
            guard let groupId = viewModel.groups?[indexPath.row] else { fatalError("could not find group")}
            performSegue(withIdentifier: viewModel.chatSegueId, sender: groupId)
            //isSeen here
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    //TODO: - HEIGHT FOR ROW
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: viewModel.headerId) as? MessagesHeader else { fatalError("Could not load header!!!")}
        header.viewModel.delegate = self
        return header
    }
}


//MARK: - SEGUE
extension MessagesController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewModel.usersSegueId,
           let navigationController = segue.destination as? UINavigationController,
           let usersSheet = navigationController.topViewController as? UsersController {
            usersSheet.viewModel.selectUserDelegate = self
        }
        
        if segue.identifier == viewModel.chatSegueId, let chatVC = segue.destination as? ChatController {
            if let selectedMessage = sender as? MessagesCellItem {
                chatVC.viewModel.chatType = .user(selectedMessage)
                chatVC.viewModel.seenDelegate = self
            }else if let selectedGroup = sender as? GroupCell{
                chatVC.viewModel.chatType = .group(selectedGroup)
                chatVC.viewModel.seenDelegate = self
            }else{
                print("SEGUEDEBUG: could not send segue")
            }
        }
    }
} 

