import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    var activeField: UITextField?
    
    private let squareView: UIView = {
        let square = UIView()
        square.backgroundColor = UIColor(named: "success_color")
        square.layer.cornerRadius = 12
        return square
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Bem vindo"
        label.textColor = .white
        label.font = .systemFont(ofSize: 40, weight: .bold)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Faça login para continuar"
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .thin)
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.leftViewMode = .always
        field.backgroundColor = UIColor(named: "bg_color")
        field.textColor = .systemGray
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let image = UIImage(named: "icon_user")?.with(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
        imageView.image = image
        field.leftView = imageView
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.leftViewMode = .always
        field.backgroundColor = UIColor(named: "bg_color")
        field.isSecureTextEntry = true
        field.textColor = .systemGray
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let image = UIImage(named: "icon_password")?.with(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
        imageView.image = image
        field.leftView = imageView
        
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log in ➞", for: .normal)
        button.backgroundColor = UIColor(named: "success_color")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cadastrar", for: .normal)
        button.backgroundColor = UIColor(named: "success_color_light")
        button.setTitleColor(UIColor(named: "success_color"), for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    /*
    private let loginButtonFB: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email", "public_profile"]
        return button
    }()
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Log in"
        
        view.backgroundColor = UIColor(named: "bg_color")
        
        loginButton.addTarget(self,
                              action: #selector(logginButtonTapped),
                              for: .touchUpInside
        )
        
        registerButton.addTarget(self,
                                 action: #selector(didTapRegister),
                                 for: .touchUpInside
        )
        
        emailField.delegate = self
        passwordField.delegate = self
        //loginButtonFB.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(squareView)
        scrollView.addSubview(welcomeLabel)
        scrollView.addSubview(subtitleLabel)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(registerButton)
        // view.addSubview(loginButtonFB)
        
        
        // MARK: Custom Placeholders
        emailField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        )
        
        passwordField.attributedPlaceholder = NSAttributedString(
            string: "Senha",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        )
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //  Hidden bar
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        squareView.frame = CGRect(x: 30,
                                  y: scrollView.top + 50,
                                  width: 50,
                                  height: 50
        )
        
        welcomeLabel.frame = CGRect(x: 30,
                                    y: squareView.bottom + 30,
                                    width: scrollView.frame.width,
                                    height: 30
        )
        
        subtitleLabel.frame = CGRect(x: 30,
                                     y: welcomeLabel.bottom,
                                     width: scrollView.frame.width,
                                     height: 50
        )
        
        emailField.frame = CGRect(x: 30,
                                  y: subtitleLabel.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 55
        )
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 55
        )
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 30,
                                   width: scrollView.width - 60,
                                   height: 55
        )
        
        registerButton.frame = CGRect(x: 30,
                                      y: loginButton.bottom + 10,
                                      width: scrollView.width - 60,
                                      height: 55
        )
        
        /*
        loginButtonFB.frame = CGRect(x: 30,
                                      y: scrollView.bottom - 80,
                                      width: scrollView.width - 60,
                                      height: 55
        )
         */
        
    }
    
    func alertUserLoginError(){
        
        let alert = UIAlertController(title: "Erro",
                                      message: "Por favor, forneça todos os dados",
                                      preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok",
                                      style: .cancel,
                                      handler: nil)
        )
        present(alert, animated: true)
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
    
    @objc private func didTapRegister(){
        
        let vc = RegisterViewController()
        vc.title = "Registre uma conta"
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @objc private func logginButtonTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            self.alertUserLoginError()
            return
        }
        
        self.spinner.show(in: view)
        
        //Firebase log in
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            
            guard authResult != nil, error == nil else {
                self?.alertUserLoginError(message: "Credenciais inválidas")
                return
            }
                        
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard
                        let userData = data as? [String: Any],
                        let firstName = userData["first_name"] as? String,
                        let lastName = userData["last_name"] as? String else {
                        return
                    }

                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    
                case .failure(let error):
                    print("Erro ao retornar os dados do usuário: \(error)")
                }
            })
                    
            UserDefaults.standard.set(email, forKey: "email")
            
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
}

// MARK: Delegates TextField
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        if textField == passwordField {
            self.logginButtonTapped()
        }
        return true
    }
    
}

// MARK: Delegates Facebook Button
extension LoginViewController: LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard let token = result?.token?.tokenString else {
            print("User is not able to login with Facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(
            graphPath: "me",
            parameters: ["fields" : "email, first_name, last_name, picture.type(large)"],
            tokenString: token,
            version: nil,
            httpMethod: .get
        )
        
        facebookRequest.start(completion: { _, result, error in
            
            guard let result = result as? [String: Any], error == nil else {
                print("Erro ao fazer requisicao para o Facebook Graph")
                return
            }
            
            guard
                let firstName = result["first_name"] as? String,
                let lastName = result["last_name"] as? String,
                let email = result["email"] as? String,
                let picture = result["picture"] as? [String: Any],
                let data = picture["data"] as? [String: Any],
                let pictureUrl = data["url"] as? String else {
                    print("Erro ao pegar dados do usuário no Facebook")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(with: email) { exists in
                
                if !exists {
                    
                    let chatUser = ChatAppUser(
                        firstName: firstName,
                        lastName: lastName,
                        emailAddress: email
                    )
                    
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        
                        if success {
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                
                                guard let data = data else {
                                    return
                                }
                                
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
                            }).resume()
                            
                            
                        }
                        
                    })
                }
            }
            
            let credential  = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    print("error")
                    return
                }
                print("Logged")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            })
            
        })
    }
}
