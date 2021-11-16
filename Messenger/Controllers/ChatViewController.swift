import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    
    var description: String {
        
        switch self {
            
            case .text(_):
                return "text"
            case .attributedText(_):
                return "attributed_text"
            case .photo(_):
                return "photo"
            case .video(_):
                return "video"
            case .location(_):
                return "location"
            case .emoji(_):
                return "emoji"
            case .audio(_):
                return "audio"
            case .contact(_):
                return "contact"
            case .linkPreview(_):
                return "link_preview"
            case .custom(_):
                return "custom"
            
        }
    }
    
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

struct Media: MediaItem{
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

class ChatViewController: MessagesViewController {
    
    public let otherUserEmail: String
    private let conversationId: String?
    public var isNewConversation = false
    
    public static let dateFormatter: DateFormatter = {
        let formatte = DateFormatter()
        formatte.dateStyle = .medium
        formatte.timeStyle = .long
        formatte.locale = .current
        return formatte
    }()
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(
            photoURL: "",
            senderId: safeEmail,
            displayName: "Me"
        )
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool){
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
                case .success(let messages):
                    guard !messages.isEmpty else {
                        return
                    }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
                
                case .failure(let error):
                    print("Erro no retorno das mensagens \(error)")
            }
        })
    }
    
    init(with email: String, id: String?){
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //msg teste
        //self.messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello world message")))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        setupInputButton()
        
    }
    
    private func setupInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        let imageIconButton = UIImage(systemName: "photo")
        button.setImage(imageIconButton, for: .normal)
        button.onTouchUpInside { _ in
            self.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet(){
        
        let actionSheet = UIAlertController(
            title: "Adicionar arquivo",
            message: "O que deseja encaminhar",
            preferredStyle: .actionSheet
        )
        
        actionSheet.addAction(UIAlertAction(title: "Imagem", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Vídeo", style: .default, handler: { _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Áudio", style: .default, handler: { _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet(){
        
        
        let actionSheet = UIAlertController(
            title: "Imagem",
            message: "Selecione sua imagem",
            preferredStyle: .actionSheet
        )
        
        actionSheet.addAction(UIAlertAction(title: "Câmera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Galeria", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = conversationId {
            self.listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }

}

//MARK: ImagePicker
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        guard
            let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
            let imageDate = image.pngData(),
            let messageId =  createMessageId(),
            let conversationId = conversationId,
            let name = self.title,
            let selfSender = selfSender else {
            return
        }
        
        let fileName = "photo_message_\(messageId)".replacingOccurrences(of: " ", with: "-")+".png"
        
        //Upload the image
        StorageManager.shared.uploadMessagePhoto(with: imageDate, fileName: fileName) { [weak self] result in
            
            guard let strongSelf = self else {
                return
            }
            
            switch result {
                case .success(let urlString):
                    //Send the message
                    print(urlString)
                
                    guard
                        let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else {
                            return
                        }
                
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media)
                    )
                
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        
                        if success {
                            print("sent message photo")
                        }else{
                            print("Error sendinf photo")
                        }
                        
                    }
                case .failure(let error):
                    print("Error: \(error)")
            }
        }
        
        
    }
    
}

//MARK: Input bar
extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        guard
            !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let messageID = createMessageId() else {
            return
        }
        
        let message = Message(sender: selfSender,
                              messageId: messageID,
                              sentDate: Date(),
                              kind: .text(text)
        )
        
        //send message
        if isNewConversation {

            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    self?.isNewConversation = false
                }else{
                    print("Failed to send")
                }
            })
            
        } else {
            
            guard
                let conversationId = conversationId,
                let name = self.title else {
                return
            }
            
            //adiciona para uma conversa existente
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    
                }else {
                    print("erro ...")
                }
            }
            
        }
    }
    
    private func createMessageId()->String? {
        //date, otheremail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        return newIdentifier
    }
    
}

//MARK: Message Kit
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email needed be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return self.messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return self.messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
            case .photo(let media):
                guard let imageUrl = media.url else {
                    return
                }
            imageView.sd_setImage(with: imageUrl, completed: nil)
            default:
                break
        }
    }
    
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {}
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
            case .photo(let media):
                guard let imageUrl = media.url else {
                    return
                }
                let vc = PhotoViewViewController(with: imageUrl)
                self.navigationController?.pushViewController(vc, animated: true)
            default:
                break
        }
    }
    
}
