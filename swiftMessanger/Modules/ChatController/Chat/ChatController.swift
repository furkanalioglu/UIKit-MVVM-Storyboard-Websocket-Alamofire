import UIKit
import AVFoundation
import AVKit


class ChatController: UIViewController {
    
    let viewModel = ChatViewModel()
    
    @IBOutlet weak var inputViewBottonAnchor: NSLayoutConstraint!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var videoCell: UIView!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            self.registerNibs()
        }
    }
    
    private func registerNibs() {
        tableView.register(UINib(nibName: viewModel.cellNib, bundle: nil), forCellReuseIdentifier: viewModel.cellNib)
        tableView.register(UINib(nibName: viewModel.cellWithImageNib, bundle: nil), forCellReuseIdentifier: viewModel.cellWithImageNib)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.photoSentDelegate = self
        PhotoPickerManager.shared.delegate = self
        SocketIOManager.shared().chatDelegate = self
        setupTapGesture()
        setupRefreshControl()
        setupNotificationObservers()
        videoCell.isHidden = true
        switch viewModel.chatType{
        case .user(let user):
            print("USERUSERUSER",user)
        default:break
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        switch viewModel.chatType {
        case .user(let user):
            AppConfig.instance.currentChat = nil
            viewModel.handleMessageSeen(forUserId: user.userId)
        case .group(let group):
            viewModel.rView?.handler?.stopTimer()
            viewModel.player?.pause()
            AppConfig.instance.currentChat = nil
            viewModel.rView?.removeAllCircles()
            viewModel.rView?.removeLottieAnimation()
            viewModel.rView?.removeFromSuperview()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                viewModel.handleMessageSeen(forUserId: group.id)
                viewModel.rView?.lottieAnimationView.isHidden = true
                viewModel.rView?.lottieAnimationView.stop()
                viewModel.rView?.flagView.isHidden = true
                viewModel.rView = nil
                SocketIOManager.shared().sendRaceEventRequest(groupId: String(group.id), seconds: "100",status: 1)
            }
            
        default:
            print("Error")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        AppConfig.instance.dynamicLinkId = nil
        switch viewModel.chatType {
        case .user(let user):
            AppConfig.instance.currentChat = user.userId
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
        viewModel.messages?.removeAll()
        switch viewModel.chatType{
        case .group(let group):
            viewModel.fetchGroupMessagesForSelectedGroup(gid: group.id, page: 1)
        case .user(let user):
            viewModel.fetchMessagesForSelectedUser(userId: String(user.userId), page: 1)
        default:
            break
        }
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
    
    @IBAction func takePhotoAction(_ sender: Any) {
        PhotoPickerManager.shared.presentPhotoPicker(from: self)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        let holdGesture = UILongPressGestureRecognizer(target: self ,action: #selector(onHoldSendMessage))
        holdGesture.minimumPressDuration = 0.5
        sendMessageButton.addGestureRecognizer(holdGesture)
    }
    
    @objc func handleTap() {
        view.endEditing(true)
    }
    @objc func onHoldSendMessage() {
        viewModel.sendMessage(myText: "test")
        tableView.reloadData()
        scrollToBottom(animated: true)
    }
    
    @objc func startEventTapped() {
        switch viewModel.chatType{
        case .group(let group):
            if videoCell.isHidden{
                performSegue(withIdentifier: viewModel.startSegueId, sender: nil)
                //handle gere
            }else{
                SocketIOManager.shared().sendRaceEventRequest(groupId: String(group.id), seconds: "66",status: 1)
            }
        default:
            print(" EventDebug: since group not found Could not emit race event")
        }
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserDidEnterForeground), name: .userDidEnterForeground, object: nil)
    }
    
    func setupRaceView(seconds:Int) {
        switch viewModel.chatType{
        case .group(let group):
            if videoCell.isHidden  {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let raceView = RaceView(frame: view.frame,handler: RaceHandler(userModels: [GroupEventModel](), isAnyRaceAvailable: true, countdownValue: seconds, raceOwnerId: viewModel.groupOwnerId),groupId: group.id)
                    viewModel.rView = raceView
                    viewModel.rView?.handler?.startTimer()
                    videoCell.addSubview((viewModel.rView)!)
                    
                    raceView.fillSuperview()
                    videoCell.isHidden = false
                }
            }else{
                DispatchQueue.main.async { [weak self] in
                    self?.videoCell.isHidden = true
                }
            }
        default:
            break
        }

    }
    
    func setupNavigationController() {
        switch viewModel.chatType {
        case .group:
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
        case .user:
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
        let messageItemType = viewModel.messages?[indexPath.row].type
        if messageItemType == "text"{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellNib) as? ChatCell2 else { fatalError("Could not load table view cell !!")}
            cell.message = viewModel.messages?[indexPath.row]
            return cell
        }else{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellWithImageNib) as? ChatCellWithImage else { fatalError("Could not load table view cell !!")}
            cell.message = viewModel.messages?[indexPath.row]
            return cell

        }
    }
}

extension ChatController : ChatControllerSentPhotoDelegate {
    func userDidSentPhoto(image: UIImage?, error: String?) {
        if error == nil {
            print("IMAGE SENT \(image)")
            self.tableView.reloadData()
            scrollToBottom(animated: true)

        }
    }
}


