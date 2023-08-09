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
    
    private func registerNibs() {
        tableView.register(UINib(nibName: viewModel.cellId, bundle: nil), forCellReuseIdentifier: viewModel.cellId)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        SocketIOManager.shared().delegate = self
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
        print("SORTEDDEBUG",viewModel.messages?.first)
    }
    
    @IBAction func showSheetButton(_ sender: Any) {
        performSegue(withIdentifier: viewModel.usersSegueId, sender: nil)
    }
    
}

extension MessagesController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellId) as? MessagesCell else {
            fatalError("COULD NOT LOAD MESSAGES CELL")
        }
        cell.message = viewModel.messages?[indexPath.row]
        return cell
    }
}


extension MessagesController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let userId = viewModel.messages?[indexPath.row] else { fatalError("COULD NOT FIND USER")}
        performSegue(withIdentifier: viewModel.chatSegueId, sender: userId)
        viewModel.messages?[indexPath.row].isSeen = true
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


//MARK: - SEGUE
extension MessagesController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        debugPrint("segue_id", segue.identifier)
        debugPrint("segue_id", segue.destination)
        if segue.identifier == viewModel.usersSegueId,
           let navigationController = segue.destination as? UINavigationController,
           let usersSheet = navigationController.topViewController as? UsersController {
            usersSheet.viewModel.selectUserDelegate = self
        }
        
        if segue.destination is ChatController {
            guard let data = sender as? MessagesCellItem else { return }
            let vc = segue.destination as? ChatController
            vc?.viewModel.user = data
            vc?.viewModel.seenDelegate = self
        }
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
