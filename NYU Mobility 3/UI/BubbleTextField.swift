//
//  BubbleTextField.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import UIKit

class BubbleTextField: UITextField {
    
    // Called
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupField()
    }
    
    func setupField() {
        backgroundColor = UIColor.white
        textColor = UIColor.black
        if let placeholder = self.placeholder {
            self.attributedPlaceholder =
                NSAttributedString(string:placeholder,
                                   attributes:
                                    [NSAttributedString.Key.foregroundColor:
                                    UIColor.gray])
        }
        self.layer.cornerRadius = self.frame.size.height / 2
        self.clipsToBounds = true
    }
}
