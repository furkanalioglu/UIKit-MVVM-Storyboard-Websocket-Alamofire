import UIKit
import AVFoundation
import AVKit


class ChatController: UIViewController {
    
    let viewModel = ChatViewModel()
    
    @IBOutlet weak var inputViewBottonAnchor: NSLayoutConstraint!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var videoCell: UIView!
    
    
    
    
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
        
        viewModel.delegate = self
        SocketIOManager.shared().chatDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserDidEnterForeground), name: .userDidEnterForeground, object: nil)
        
        setupTapGesture()
        setupRefreshControl()
        setupNotificationObservers()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        switch viewModel.chatType {
        case .user(let user):
            AppConfig.instance.currentChat = nil
            viewModel.handleMessageSeen(forUserId: user.id)
        case .group(let group):
            AppConfig.instance.currentChat = nil
            viewModel.handleMessageSeen(forUserId: group.id)
        default:
            print("Error")
        }
        viewModel.player?.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        AppConfig.instance.dynamicLinkId = nil
        switch viewModel.chatType {
        case .user(let user):
            AppConfig.instance.currentChat = user.id
        case .group(let group):
            AppConfig.instance.currentChat = group.id
        default:
            print("Error")
        }
    }
    
    
    //MARK: - Actions
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.3) {
                self.inputViewBottonAnchor.constant = -keyboardSize.height
                self.view.layoutIfNeeded()
            }
            self.scrollToBottom(animated: true)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.inputViewBottonAnchor.constant = 0
            self.view.layoutIfNeeded()
            
            self.tableView.contentInset = .zero
            self.tableView.scrollIndicatorInsets = .zero
        }
        self.scrollToBottom(animated: true)
    }
    
    @objc func handleRefresh() {
        if viewModel.newMessages?.count ?? 0 > 0 {
            viewModel.fetchNewMessages()
        }else{
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc func handleUserDidEnterForeground() {
        scrollToBottom(animated: true)
        print("HANDLE RELOAD NEW MESSAGES HERE!!")
    }
    
    @objc func rightBarButtonTapped() {
        performSegue(withIdentifier: viewModel.segueId, sender: viewModel.userInformations)
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
    
    @objc func startEventTapped() {
        print("Staretedd")
    }
    
    private func setupVideoLayer() {
        videoCell.backgroundColor = .green
        videoCell.isHidden = !viewModel.isGroupOwner
    }
    
    //MARK: - Functions
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setupNavigationController() {
        switch viewModel.chatType {
        case .group(_):
            navigationItem.title = viewModel.navigationTitle
            navigationItem.largeTitleDisplayMode = .never
            var rightBarButtonItems: [UIBarButtonItem] = []
            
            let rightButtonImage = UIImage(systemName: "info.circle")
            let infoButton = UIBarButtonItem(image: rightButtonImage, style: .plain, target: self, action: #selector(rightBarButtonTapped))
            rightBarButtonItems.append(infoButton)
            
            if viewModel.isGroupOwner {
                let startEventButtonImage = UIImage(systemName: "flag.checkered")
                let startEventButton = UIBarButtonItem(image:startEventButtonImage, style: .plain, target: self, action: #selector(startEventTapped))
                rightBarButtonItems.append(startEventButton)
            }
            navigationItem.rightBarButtonItems = rightBarButtonItems
        case .user(_):
            navigationItem.title = viewModel.navigationTitle
            navigationItem.largeTitleDisplayMode = .never
        default:
            break
        }
    }
    
}

extension ChatController : UITableViewDelegate {}

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