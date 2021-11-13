import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.contentMode = .scaleToFill
        imageView.layer.masksToBounds = true
        imageView.tintColor = .lightGray
        return imageView
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = UIColor(named: "bg_color")
        field.textColor = .systemGray
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = UIColor(named: "bg_color")
        field.textColor = .systemGray
        return field
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = UIColor(named: "bg_color")
        field.textColor = .systemGray
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = UIColor(named: "bg_color")
        field.textColor = .systemGray
        field.isSecureTextEntry = true
        return field
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cadastrar", for: .normal)
        button.backgroundColor = UIColor(named: "success_color")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        title = "Cadastro"
        view.backgroundColor = UIColor(named: "bg_color")
        
        firstNameField.attributedPlaceholder = NSAttributedString(
            string: "Nome",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        )
        lastNameField.attributedPlaceholder = NSAttributedString(
            string: "Último nome",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        )
        emailField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        )
        passwordField.attributedPlaceholder = NSAttributedString(
            string: "Senha",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        )
        
        navigationController?.navigationBar.barTintColor = UIColor(named: "bg_color")
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        registerButton.addTarget(self,
                                 action: #selector(registerButtonTapped),
                                 for: .touchUpInside
        )
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        
        imageView.addGestureRecognizer(gesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds

        imageView.frame = CGRect(x: (scrollView.width-150)/2,
                                 y: 20,
                                 width: 150,
                                 height: 150
        )
        
        imageView.layer.cornerRadius = imageView.width / 2.0
        
        firstNameField.frame = CGRect(x: 30,
                                      y: imageView.bottom + 10,
                                      width: scrollView.width - 60,
                                      height: 55
        )
        
        lastNameField.frame = CGRect(x: 30,
                                     y: firstNameField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 55
        )
        
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 55
        )
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 55
        )
        
        registerButton.frame = CGRect(x: 30,
                                      y: passwordField.bottom + 30,
                                      width: scrollView.width - 60,
                                      height: 55
        )
        
    }
    
    @objc private func registerButtonTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard
            let name = firstNameField.text,
            let lasteName = lastNameField.text,
            let email = emailField.text,
            let password = passwordField.text,
            !name.isEmpty,
            !lasteName.isEmpty,
            !email.isEmpty,
            !password.isEmpty,
            password.count >= 6 else {
                
                self.alertUserLoginError()
                return
                
            }
        
        
        self.spinner.show(in: view)
        
        //Firebase register
        
        DatabaseManager.shared.userExists(with: email) { [weak self] exists in
            
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            
            guard !exists else {
                self?.alertUserLoginError(message: "Este email já está cadastrado")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                
                guard authResult != nil, error == nil else {
                    self?.alertUserLoginError(message: "Erro no cadastrado do usuário")
                    return
                }
                
                let chatUser = ChatAppUser(
                    firstName: name,
                    lastName: lasteName,
                    emailAddress: email)
                
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    //upload the image
                    guard
                        let image = strongSelf.imageView.image,
                        let data = image.pngData() else {
                            return
                        }
                    
                    //upload the file to firebase storage
                    let filename = chatUser.profilePictureFileName
                    
                    StorageManager.shared.uploadProfilePicture(
                        with: data,
                        fileName: filename,
                        completion: { result in
                            switch result {
                                case .success(let downloadUrl):
                                    UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                case .failure(let error):
                                    print("Erro no upload: \(error)")
                                }
                        }
                    )
                    
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
            
        }
        
    }
    
    @objc func didTapChangeProfilePic(){
        self.presentPhotoActionSheet()
    }
    
    func alertUserLoginError(message: String = "Por favor, forneça todos os dados para efetuar o cadastro"){
        
        let alert = UIAlertController(title: "Erro",
                                      message: message,
                                      preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Ok",
                                      style: .cancel,
                                      handler: nil)
        )
        
        present(alert, animated: true)
        
    }
    
    // MARK: Keyboard
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= (keyboardSize.height - 50)
            }
        }

    }

    @objc func keyboardWillHide(notification: Notification) {
        if (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue != nil {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
    }
}

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        if textField == passwordField {
            self.registerButtonTapped()
        }
        return true
    }
    
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet(){
        
        let actionSheet = UIAlertController(
            title: "Imagem do perfil",
            message: "Como deseja selecionar uma imagem?",
            preferredStyle: .actionSheet
        )
        
        actionSheet.addAction(UIAlertAction(
            title: "Cancelar",
            style: .cancel,
            handler: nil
        ))
        
        actionSheet.addAction(UIAlertAction(
            title: "Usar a câmera",
            style: .default,
            handler: { [weak self] _ in
                self?.presentCamera()
            }
        ))
        
        actionSheet.addAction(UIAlertAction(
            title: "Escolher uma foto",
            style: .default,
            handler: { [weak self] _ in
                self?.presentPhotoPicture() }
        ))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicture(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.imageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
