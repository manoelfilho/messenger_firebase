import Foundation
import FirebaseDatabase
import MessageKit

struct ChatAppUser {
    
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
    
}

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    ///Return a safe email from a email. Safe email has hifens instead " @ " and " . "
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

// MARK: - Account Management with Firebase
extension DatabaseManager{
    
    ///Check if there is a User with same email
    public func userExists(with email: String, completion: @escaping ((Bool)) -> Void)  {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
                
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
        
    }
    
    ///Insert a new user
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        
        let userArray = ["first_name": user.firstName, "last_name": user.lastName]
        
        //In the first moment insert a node with safe email and body with name and last name
        database.child(user.safeEmail).setValue(userArray, withCompletionBlock: { error, _ in
            
            guard error == nil else {
                print("Error insert data user in firebase")
                completion(false)
                return
            }
            
            //In the second moment insert in node users
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                
                if var userCollection = snapshot.value as? [[String: String]] {
                    
                    //If find the node users:
                    let newElement = ["name": user.firstName + " " + user.lastName, "email": user.safeEmail];
                    
                    userCollection.append(newElement)
                    
                    //Add a new user in collection
                    self.database.child("users").setValue(userCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
        
                } else {
                 
                    //If doesnt find the node users:
                    let newCollection: [[String: String]] = [
                        [ "name": user.firstName + " " + user.lastName, "email": user.safeEmail]
                    ]
                    
                    //Create a new collection with the first data user
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            return
                        }
                        completion(true)
                    })
                    
                }
            })
            
        })
        
    }
    
    ///Return all users in firebase
    public func getAllUsers(completion: @escaping(Result<[[String: String]], DatabaseErros>) -> Void ){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DatabaseErros: Error {
        case failedToFetch
    }
    
}

// MARK: - Conversation Management
extension DatabaseManager{
    
    ///Create a new conversation with target user email and first message
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void ){
        
        guard
            let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("There isn't user node")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
                
                case .text(let messageText):
                    message = messageText
                case .attributedText(_):
                    break
                case .photo(_):
                    break
                case .video(_):
                    break
                case .location(_):
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .linkPreview(_):
                    break
                case .custom(_):
                    break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String : Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_ready": false
                ]
            ]
            
            let recipent_newConversationData: [String : Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_ready": false
                ]
            ]
            
            //update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //apend
                    conversations.append(recipent_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipent_newConversationData])
                }
            })
            
            
            //update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversations array exists for current user
                
                conversations.append(newConversationData)
                
                userNode["conversations"] = conversations
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(
                        name: name,
                        conversationID: conversationId,
                        firstMessage: firstMessage,
                        completion: completion
                    )
                })
                
            } else {
                //conversations array doestn exist for current user
                
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(
                        name: name,
                        conversationID: conversationId,
                        firstMessage: firstMessage,
                        completion: completion
                    )
                    
                })
                
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
        }
        
        guard let  myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmailUser = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.description,
            "content": message,
            "date": dateString,
            "sender_email": currentEmailUser,
            "is_ready": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    ///Fetches and returns all coversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void ){
                
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
                        
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErros.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                               
                guard
                    let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isReady = latestMessage["is_ready"] as? Bool else {
                        return nil
                }
                
                let lastestMessageObject = LastestMessage(
                    date: date,
                    text: message,
                    isRead: isReady
                )
                
                return Conversation(
                    id: conversationId,
                    name: name,
                    otherUserEmail: otherUserEmail,
                    latestMessage: lastestMessageObject
                )

            })
                        
            completion(.success(conversations))
        })
        
    }
    
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void ){
        
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErros.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                
                guard
                    let content = dictionary["content"] as? String,
                    let id = dictionary["id"] as? String,
                    //let isReady = dictionary["is_ready"] as? Bool,
                    let name = dictionary["name"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let type = dictionary["type"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateString)
                    else {
                        return nil
                }
                
                var kind: MessageKind?
                
                if type == "photo" {
                    
                    guard
                        let imageUrl = URL(string: content),
                        let placeholder = UIImage(systemName: "plus") else {
                            return nil
                        }
                
                    let media = Media(
                            url: imageUrl,
                            image: nil,
                            placeholderImage: placeholder,
                            size: CGSize(width: 300, height: 300)
                    )
                    
                    kind = .photo(media)
                    
                }else{
                    
                    kind = .text(content)
                    
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(
                    photoURL: "",
                    senderId: senderEmail,
                    displayName: name
                )
                
                return Message(
                    sender: sender,
                    messageId: id,
                    sentDate: date,
                    kind: finalKind
                )

            })
                        
            completion(.success(messages))
        })
        
    }
    
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        //adiciona nova msg para mensagens
        //atualiza o sender
        //atualiza o a ultima msg do recebedor
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Email user not found")
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
                
                case .text(let messageText):
                    message = messageText
                case .attributedText(_):
                    break
                case .photo(let mediaItem):
                    if let targetUrlString = mediaItem.url?.absoluteString {
                       message = targetUrlString
                    }
                    break
                case .video(_):
                    break
                case .location(_):
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .linkPreview(_):
                    break
                case .custom(_):
                    break
            }
            
            guard let  myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentEmailUser = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.description,
                "content": message,
                "date": dateString,
                "sender_email": currentEmailUser,
                "is_ready": false,
                "name": name
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_ready": false,
                        "message": message
                    ]
                    
                    var targetConversation: [String: Any]?
                    
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    
                    currentUserConversations[position] = finalConversation
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        //update latest messsage for recipient user

                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_ready": false,
                                "message": message
                            ]
                            
                            var targetConversation: [String: Any]?
                            
                            var position = 0
                            
                            for conversationDictionary in otherUserConversations {
                                
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                
                                position += 1
                            }
                            
                            targetConversation?["latest_message"] = updatedValue
                            
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            
                            otherUserConversations[position] = finalConversation
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        })
    }
    
}

// MARK: - Another functions
extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping(Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseErros.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
}
