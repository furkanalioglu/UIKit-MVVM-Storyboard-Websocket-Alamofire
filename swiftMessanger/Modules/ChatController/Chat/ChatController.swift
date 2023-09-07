import UIKit
import AVFoundation
import AVKit


class ChatController: UIViewController {
    
    let viewModel = ChatViewModel()
    
    let photoPicker = PhotoPickerManager()
    
    var cellHeights = [IndexPath: CGFloat]()
    
    var shouldEndRefreshingAfterDragging = false
    
    @IBOutlet weak var inputViewBottonAnchor: NSLayoutConstraint!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var videoCell: UIView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var scrollToBottomButtonLabel: UIButton!
    
    
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
        CoreDataManager.shared.loadImageDelegate = self
        SocketIOManager.shared().chatDelegate = self
        setupTapGesture()
        setupRefreshControl()
        setupNotificationObservers()
        configureSendImageButton()
        photoPicker.delegate = self
        videoCell.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.handleDismissView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        AppConfig.instance.dynamicLinkId = nil
        switch viewModel.chatType {
        case .user(let user):
            AppConfig.instance.currentChat = user.userId
            setupNavigationController()
        case .group(let group):
            AppConfig.instance.currentChat = group.id
            setupNavigationController()
            
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
        viewModel.fetchNewMessages()
    }
    
    @IBAction func handleScrollToBottom(_ sender: Any) {
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        if lastRow > 0 {
            let indexPath = IndexPath(row: lastRow, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    
    @objc func handleUserDidEnterForeground() {
        viewModel.messages?.removeAll()
        switch viewModel.chatType{
        case .group(let group):
            viewModel.fetchGroupMessagesForSelectedGroup(gid: group.id, page: 1)
        case .user(_):
            viewModel.fetchLocalMessages(beforeTime: Date().toTimestampString())
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
        switch viewModel.chatType {
        case .user(_):
            photoPicker.presentPhotoPicker(from: self)
        default:
            break
        }
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
            
            print("heree",viewModel.isGroupOwner)
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
    
    func configureSendImageButton(){
        switch viewModel.chatType{
        case .group(_):
            takePhotoButton.isHidden = true
        case .user(_):
            takePhotoButton.isHidden = false
        default:
                break
        }
    }
    
}

extension ChatController : UITableViewDelegate {
}

extension ChatController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages?.count ?? 0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(viewModel.messages![indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messageItemType = viewModel.messages?[indexPath.row].type
        if messageItemType == MessageTypes.text.rawValue{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellNib) as? ChatCell2 else { fatalError("Could not load table view cell !!")}
            cell.message = viewModel.messages?[indexPath.row]
            return cell
        }else{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellWithImageNib) as? ChatCellWithImage else { fatalError("Could not load table view cell !!")}
            cell.message = viewModel.messages?[indexPath.row]
            return cell

        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let indexPaths = tableView.indexPathsForVisibleRows ?? []
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        if viewModel.areLastMessagesVisible(numberOfMessages: 10, indexPaths: indexPaths, lastRow: lastRow) {
            scrollToBottomButtonLabel.isHidden = true
        } else {
            scrollToBottomButtonLabel.isHidden = false
        }
    }
}

