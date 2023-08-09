//
//  ViewController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 31.07.2023.
//

import UIKit

protocol LoginControllerDelegate : AnyObject {
    func userLoggedIn(error: Error?)
}

class LoginController: UIViewController, StoryboardSwitch{
    //MARK: - Properties
    
    //Textfields
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //Buttons
    @IBOutlet weak var loginButtonOutlet: UIButton!
    @IBOutlet weak var signUpButtonOutlet: UIButton!
    
    let viewModel = LoginViewModel()
    
    
    //MARK: - Lifectcycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        setupTapGesture()
    }
    
    
    //MARK: - Actions
    @IBAction func loginButtonHandler(_ sender: Any) {
        guard let email = emailTextField.text else { return }
        guard let pass = passwordTextField.text  else { return }
        viewModel.loginUser(withEmail: email, password: pass, pushToken: String(UUID().uuidString))
    }
    
    @IBAction func signUpButtonHandler(_ sender: Any) {
        performSegue(withIdentifier: viewModel.segueRegisterId, sender: nil)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap() {
        view.endEditing(true)
    }
}

//CHECKLOG: REFACTOR MVC TO MVVM

extension LoginController : LoginControllerDelegate {
    func userLoggedIn(error: Error?) {
        if let error = error {
            print("LIFEDEBUG: \(error.localizedDescription)")
            return
        }else{
            RootManager.switchRoot(.tabBar)
        }
    }
}



