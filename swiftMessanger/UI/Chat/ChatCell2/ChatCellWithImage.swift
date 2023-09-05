import SDWebImage

protocol ChatCellWithImageDelegate: AnyObject {
    func didReceivedCellImage()
}

class ChatCellWithImage: UITableViewCell {
    var message: MessageItem? {
        didSet {
            configureUI()
        }
    }
    
    @IBOutlet weak var leftStack: UIStackView!
    @IBOutlet weak var rightStack: UIStackView!
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var sentImageView: UIImageView!
    @IBOutlet weak var messageBuble: UIView!
    
    weak var delegate : ChatCellWithImageDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public func resizeImage(image: UIImage) -> UIImage? { // MARK:  Resize Height to 1600px
        
        let ratio = 2048 / image.size.height
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if (image.size.height > 2048) {
            newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        } else {
            newSize = image.size
        }
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func updateImage(_ image: Data) {
        let image = UIImage(data: image)
        sentImageView.image = resizeImage(image: image!)
    }
    
    private func configureUI() {
        guard let message = message else { return }
        guard let currentUserId = AppConfig.instance.currentUserId else { return }
        
        let isCurrentUserSender = message.senderId == Int(currentUserId)
        
        
        senderLabel.text = String(message.senderId)
        senderLabel.font = UIFont.systemFont(ofSize: 10)
        rightStack.isHidden = isCurrentUserSender
        messageBuble.backgroundColor = isCurrentUserSender ? .systemPurple : .systemPink
        leftStack.isHidden = !isCurrentUserSender
        
        if let data = message.imageData {
            sentImageView.image = UIImage(data: data)
        }else{
            sentImageView.image = UIImage(systemName: "tray.and.arrow.down")
        }
        
    }
}

