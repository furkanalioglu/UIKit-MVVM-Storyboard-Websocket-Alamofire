//
//  ChatController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import UIKit

//MARK: - DELEGATES
protocol ChatControllerDelegate : AnyObject {
    func datasReceived(error : String?)
}

protocol ChatMessageSeenDelegate : AnyObject {
    func chatMessageSeen(error: String?, forId senderId: Int?)
    func chatMessageReceivedFromUser(error: String?, message: MessageItem)
}

class ChatController: UIViewController {
    
    let viewModel = ChatViewModel()

    @IBOutlet weak var inputViewBottonAnchor: NSLayoutConstraint!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView! {
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
        
        navigationItem.title = viewModel.user?.username
        navigationItem.largeTitleDisplayMode = .never
            
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        viewModel.delegate = self
        SocketIOManager.shared().chatDelegate = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        setupTapGesture()
        
        print("MESSAGEDEBUG:",viewModel.messages)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let uid = viewModel.user?.id else { fatalError( "Coudl not get user id")}
        viewModel.handleMessageSeen(forUserId: uid)
    }
    
    
    //MARK: - Actions
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.3) {
                self.inputViewBottonAnchor.constant = -keyboardSize.height
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.inputViewBottonAnchor.constant = -8
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func handleRefresh() {
        if viewModel.newMessages?.count ?? 0 > 0 {
            viewModel.fetchNewMessages()
        }else{
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    @IBAction func sendMessageAction(_ sender: Any) {
        viewModel.sendMessage(myText: messageTextField.text)
        messageTextField.text = ""

        tableView.reloadData()
        scrollToBottom(animated: true)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap() {
        view.endEditing(true)
    }
}

extension ChatController : UITableViewDelegate {
}


extension ChatController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellNib) as? ChatCell2 else { fatalError("Could not load table view cell !!")}
        cell.message = viewModel.messages?[indexPath.row]
        return cell
    }
    
}
    

extension ChatController : ChatControllerDelegate {
    func datasReceived(error: String?) {
        tableView.refreshControl?.endRefreshing()
        tableView.reloadData()
        if let count = viewModel.messages?.count, count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
}

extension ChatController : SocketIOManagerChatDelegate {
    func scrollToBottom(animated: Bool = true) {
        guard let msgCount = viewModel.messages?.count, msgCount > 0 else {
            return
        }

        let indexPath = IndexPath(row: msgCount - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    func didReceiveChatMessage(message: MessageItem) {
        if message.senderId == viewModel.user?.id || message.senderId == Int(AppConfig.instance.currentUserId ?? "") {
            viewModel.messages?.append(message)
            tableView.reloadData()
            scrollToBottom(animated: true)
        }
    }
}

