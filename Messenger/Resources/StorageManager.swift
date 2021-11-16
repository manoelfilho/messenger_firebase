import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads a file to firebase and returns a link
    public func uploadProfilePicture(with data: Data,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion){
     
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            
            guard error == nil else {
                print("Erro ao fazer upload do arquivo para o Firebase")
                completion(.failure(StorageErros.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL (completion: { url, error in
                guard let url = url else {
                    print("Erro ao pegar URL do arquivo")
                    completion(.failure(StorageErros.FailedToGetDownloadURl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
            
        }
        
    }
    
    /// Uploads a photo to Firebase
    public func uploadMessagePhoto(with data: Data,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion){
     
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            
            guard error == nil else {
                print("Erro ao fazer upload do arquivo para o Firebase")
                completion(.failure(StorageErros.failedToUpload))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL (completion: { url, error in
                guard let url = url else {
                    print("Erro ao pegar URL do arquivo")
                    completion(.failure(StorageErros.FailedToGetDownloadURl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
            
        }
        
    }
    
    public func donwloadUrl(for path: String, completion: @escaping (Result<URL, Error>) -> Void){
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                print(error ?? "")
                completion(.failure(StorageErros.FailedToGetDownloadURl))
                return
            }
            
            completion(.success(url))
        })
    }
    
    public enum StorageErros: Error {
        case failedToUpload
        case FailedToGetDownloadURl
    }
    
}
