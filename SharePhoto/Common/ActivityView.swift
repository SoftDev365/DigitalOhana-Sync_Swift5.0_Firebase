//
//  ActivityView.swift
//  SharePhoto
//
//  Created by Admin on 11/7/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

class ActivityView {

    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    func relayoutPosition(_ view: UIView) {
        let width = effectView.frame.size.width
        effectView.frame = CGRect(x: view.frame.midX - width/2, y: view.frame.midY - 60 , width: width, height: 120)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
    }
    
    func showActivityIndicator(_ view: UIView, withTitle title: String) {

        hideActivitiIndicator()
        
        let widthOfTitle = title.width(withConstrainedHeight: 46, font: .systemFont(ofSize: 18, weight: UIFont.Weight.medium))
        var widthOfView: CGFloat = 120
        if widthOfView < widthOfTitle + 30 {
            widthOfView = widthOfTitle + 30
        }

        strLabel = UILabel(frame: CGRect(x: 0, y: 70, width: widthOfView, height: 46))
        strLabel.text = title
        strLabel.textAlignment = .center
        strLabel.font = .systemFont(ofSize: 18, weight: UIFont.Weight.medium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)

        effectView.frame = CGRect(x: view.frame.midX - widthOfView/2, y: view.frame.midY - 60 , width: widthOfView, height: 120)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true

        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
        } else {
            // Fallback on earlier versions
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        
        activityIndicator.color = UIColor.white
        activityIndicator.frame = CGRect(x: (widthOfView - 60)/2, y: 20, width: 60, height: 60)
        activityIndicator.startAnimating()

        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(strLabel)
        view.addSubview(effectView)
    }
    
    func hideActivitiIndicator() {
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
    }
}
