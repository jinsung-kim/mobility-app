//
//  BubbleButton.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import UIKit

class BubbleButton: UIButton {
    
    // Called
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    func setupButton() {
        setTitleColor(.black, for: .normal)
        backgroundColor = UIColor.white
        titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        layer.cornerRadius = 25
        layer.borderWidth = 3.0
        layer.borderColor = UIColor.darkGray.cgColor
    }
    
    func setShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 6.0)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.5
        clipsToBounds = true
        layer.masksToBounds = false
    }
}
