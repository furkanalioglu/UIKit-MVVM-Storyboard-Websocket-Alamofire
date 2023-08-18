//
//  StartRaceController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 18.08.2023.
//

protocol StartControllerProtocol : AnyObject{
    func userDidTapStartButton(value: Int)
}

import UIKit

class StartRaceController: UIViewController {
    
    weak var delegate : StartControllerProtocol?
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var sliderValue: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sender.value = round(sender.value)

        updateUI()
    }
    
    private func updateUI() {
        sliderValue.text = String(format: "%.2f", slider.value)
    }
    
    @IBAction func startButtonHandler(_ sender: Any) {
        delegate.self?.userDidTapStartButton(value: Int(slider.value))
    }
    
}
