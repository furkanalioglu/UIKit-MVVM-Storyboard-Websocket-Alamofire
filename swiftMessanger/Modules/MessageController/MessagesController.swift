//
//  MessageController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 31.07.2023.
//

import UIKit

protocol MessagesControllerDelegate : AnyObject {
    func messageDatasReceived(error: Error?)
    func newMessageCellDataReceived(error : Error?)
    func groupDatasReceived(error: Error?)
}


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
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
        print("SORTEDDEBUG",viewModel.messages?.first)
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
        return viewModel.currentSegment == .messages ? viewModel.messages?.count ?? 0  : viewModel.groups?.count ?? 0
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
        
        if segue.identifier == viewModel.chatSegueId {
            switch viewModel.currentSegment{
            case .groups:
                guard let data = sender as? GroupCell else { return }
                let vc = segue.destination as? ChatController
                vc?.viewModel.groupUsers = data
            case .messages:
                guard let data = sender as? MessagesCellItem else { return }
                let vc = segue.destination as? ChatController
                vc?.viewModel.user = data
                vc?.viewModel.seenDelegate = self
            }
        }
        
        
        //add segue events for group here
    }
} 


extension MessagesController : DidSelectUserProtocol {
    func didSelectUser(user: MessagesCellItem) {
        print("SELECTED USER ::\(user)")
        self.performSegue(withIdentifier: viewModel.chatSegueId, sender: user)
    }
}

extension MessagesController : MessagesControllerDelegate {
    func messageDatasReceived(error: Error?) {
        if let error = error {
            print("LIFEDEBUG: COULD NOT LOAD USERS",error.localizedDescription)
            return
        }else{
            tableView.reloadData()
            if AppConfig.instance.dynamicLinkId != nil {
                print("DYNAMICDEBUG: PERFORMING SEGU)")
                guard let index = (viewModel.messages?.firstIndex(where: {$0.id == AppConfig.instance.dynamicLinkId})) else { fatalError("NO USER")}
                let user = viewModel.messages?[index]
                print("DYNAMICDEBUG index:  \(index) user: \(user)" )
                performSegue(withIdentifier: viewModel.chatSegueId, sender: viewModel.messages?[index])
            }else{
                print("DYNAMICDEBUG: COULD NOT SEND SEGUE")
            }
        }
    }
    
    func newMessageCellDataReceived(error: Error?) {
        if let error = error{
            print(error.localizedDescription)
            return
        }else{
            viewModel.messages = viewModel.messages?.sorted(by: { $0.sendTime?.toDate() ?? Date() > $1.sendTime?.toDate() ?? Date()})
            tableView.reloadData()
        }
    }
    
    func groupDatasReceived(error: Error?) {
        if let error = error {
            print("COULD NOT LOAD",error.localizedDescription)
            return
        }else{
            viewModel.groups = viewModel.groups?.sorted(by: {$0.sendTime.toDate() ?? Date() > $1.sendTime.toDate() ?? Date()})
            tableView.reloadData()
        }
    }
}

extension MessagesController : SocketIOManagerDelegate {
    func didReceiveMessage(message: MessageItem) {
        //MARK: - UNTESTEDCHANGES
        viewModel.handleIncomingMessage(message: message)
        viewModel.messages = viewModel.messages?.sorted(by: { $0.sendTime?.toDate() ?? Date() > $1.sendTime?.toDate() ?? Date()})
        tableView.reloadData()
    }
}

extension MessagesController: ChatMessageSeenDelegate {
    func chatMessageReceivedFromUser(error: String?, message: MessageItem) {
        viewModel.handleIncomingMessage(message: message)
        viewModel.messages = viewModel.messages?.sorted(by: { $0.sendTime?.toDate() ?? Date() > $1.sendTime?.toDate() ?? Date()})
        tableView.reloadData()
    }
    
    
    func chatMessageSeen(error: String?, forId senderId: Int?) {
        if let messageIndex = viewModel.messages?.firstIndex(where: {$0.id == senderId}) {
            viewModel.messages?[messageIndex].isSeen = true
            tableView.reloadData()
        }else{
            print("Seendebug: Could not find message with index \(String(describing: senderId))")
        }
    }
}

extension MessagesController: MessagesHeaderProtocol {
    func userDidTapNewGroupButton() {
        performSegue(withIdentifier: viewModel.newGroupSegueId, sender: nil)
    }
}
