//
//  RegisterController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 31.07.2023.
//

import UIKit

protocol RegisterControllerDelegate : AnyObject{
    func didRegisterUser(_ user: RegisterModel?, error : String?)
    func didLoginRegisteredUser(error: String?)
}

class RegisterController: UIViewController {
    
    //Labels
    @IBOutlet weak var registerLabel: UILabel!
    //TextFields
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repasswordTextField:UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var age: UITextField!
    //SegmentedControl
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    //Buttons
    @IBOutlet weak var registerButtonOutlet: UIButton!
    
    let viewModel = RegisterViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerButtonOutlet.isEnabled = false
        viewModel.delegate = self
        setupTextFields()
        setupTapGesture()
    }
    
    
    //Actions
    
    @IBAction func registerButtonHandler(_ sender: Any) {
        viewModel.registerUser(firstName: firstName.text, lastName: lastName.text, age: age.text, gender: segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex))
    }
    
    @IBAction func segmentedControlAction(_ sender: Any) {
    }
    
}


//MARK: - TextField Delegates
extension RegisterController {
    private func configureRegisterButton() {
        registerButtonOutlet.isEnabled = viewModel.isRegisterButtonEnabled
    }
    
    private func setupTextFields() {
        emailTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        repasswordTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        switch textField {
        case emailTextField:
            viewModel.email = textField.text
        case passwordTextField:
            viewModel.password = textField.text
        case repasswordTextField:
            viewModel.rePassword = textField.text
        default:
            break
        }
        registerButtonOutlet.isEnabled = viewModel.isRegisterButtonEnabled
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap() {
        view.endEditing(true)
    }
}

extension RegisterController : RegisterControllerDelegate {
    func didRegisterUser(_ user: RegisterModel?, error: String?) {
        if let error = error {
            print("log could not Registered User \(error)")
            return
        }
        self.viewModel.loginUser(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!,pushToken: UUID().uuidString)
        print("log: REIGSTERED USER")
    }
    
    func didLoginRegisteredUser(error: String?) {
        if let error = error {
            print(error)
        }else{
            RootManager.switchRoot(.tabBar)
        }
        
    }
}



