import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let headerProfile: Profile = {
        let profile = Profile()
        return profile
    }()
    
    let data = ["Log out"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "bg_color")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(named: "bg_color")
        tableView.separatorColor = .systemGray
        
        self.updateHeaderProfile()

    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        self.headerProfile.frame = CGRect(
            x: 20,
            y: 0,
            width: 80,
            height: 100
        )
        
        self.headerProfile.backgroundColor = UIColor(named: "bg_color")
        self.headerProfile.image.contentMode = .scaleAspectFill
        self.headerProfile.image.layer.borderWidth = 5
        self.headerProfile.image.layer.borderColor = UIColor(named: "yellow")?.cgColor
        self.headerProfile.image.layer.masksToBounds = true
        self.headerProfile.image.layer.cornerRadius = 40
    }
    
    func updateHeaderProfile() -> Void {
        
        guard
            let email = UserDefaults.standard.value(forKey: "email") as? String,
            let name = UserDefaults.standard.value(forKey: "name") as? String else {
                print("Email e nome nao localizados em UserDefaults")
                return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let filename = "\(safeEmail)_profile_picture.png"
        let path = "images/\(filename)"
        
        StorageManager.shared.donwloadUrl(for: path, completion: { [weak self] result in
            
            guard let strongSelf = self else {
                print("Erro no retorna da URL da imagem")
                return
            }
            
            switch result {
                case .success(let url):
                    
                    URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
                        
                        guard let data = data, error == nil else {
                            print("Erro no retorno dos dados da imagem do usuário")
                            return
                        }
                        
                        DispatchQueue.main.async {
                            let image = UIImage(data: data)
                            strongSelf.headerProfile.image.image = image
                            strongSelf.headerProfile.name.text = name
                            strongSelf.headerProfile.email.text = email
                            strongSelf.headerProfile.createdAt.text = ""
                            strongSelf.tableView.tableHeaderView = strongSelf.headerProfile
                        }
                        
                    }).resume()
                    
                case .failure(let error):
                    print("Error ao baixar imagem de perfil do usuário. \(error)")
            }
        })
            
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.data[indexPath.row]
        cell.textLabel?.textColor = UIColor(named: "pink")
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        cell.backgroundColor = UIColor(named: "bg_color")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { [weak self] _ in
            
            guard let strongSelf = self else  {
                return
            }
            
            //Log out Facebook
            //FBSDKLoginKit.LoginManager().logOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: false)
                
                ///Remove the email user of UserDefaults
                UserDefaults.standard.removeObject(forKey: "email")
                
            } catch {
                print("Erro ao tentar deslogar")
            }
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
        
    }
}
