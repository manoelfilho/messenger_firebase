import UIKit
import MessageKit
import InputBarAccessoryView

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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = conversationId {
            self.listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }

}

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
}
