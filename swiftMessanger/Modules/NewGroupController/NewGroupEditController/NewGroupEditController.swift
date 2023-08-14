//
//  NewGroupEditController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 11.08.2023.
//

import UIKit

class NewGroupEditController: UIViewController {
    
    let viewModel = NewGroupEditViewModel()
        
    @IBOutlet weak var createButtonLabel: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!{
        didSet{
            collectionView.delegate = self
            collectionView.dataSource = self
            self.registerNibs()
        }
    }
    
    
    private func registerNibs() {
        collectionView.register(UINib(nibName:viewModel.cellNib, bundle: nil),forCellWithReuseIdentifier: viewModel.cellNib)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createButtonLabel.isEnabled = false
    }
    
    
    @IBAction func createButtonAction(_ sender: Any) {
        let groupModel = CreateGroupModel(groupName: viewModel.groupName, ids: viewModel.savedUsers)
        MessagesService.instance.createGroup(withGroupModel:groupModel) { err in
            if err != nil {
                return
            }else{
                print("GROUPDEBUG: createddddd \(err)")
            }
        }
        dismiss(animated: true)
    }
    
}

extension NewGroupEditController : UICollectionViewDelegate{
    
}

extension NewGroupEditController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: viewModel.cellNib, for: indexPath) as? NewGroupEditCell else { fatalError( "Could not load cel!!!")}
        cell.delegate = self
        cell.selectedUsers = viewModel.savedUsers
        return cell
    }
}

extension NewGroupEditController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 100)
    }
}

extension NewGroupEditController : NewGroupEditCellTextFieldProtocol {
    func textDidChange(text: String) {
        viewModel.groupName = text
        createButtonLabel.isEnabled = !viewModel.groupName.isEmpty && !viewModel.groupName.trimmingCharacters(in: .whitespaces).isEmpty && viewModel.groupName.count < 25
    }
}
