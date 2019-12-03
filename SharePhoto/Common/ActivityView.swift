//
//  ActivityView.swift
//  SharePhoto
//
//  Created by Admin on 11/7/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import Foundation
import UIKit

class ActivityView {

    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    func relayoutPosition(_ view: UIView) {
        effectView.frame = CGRect(x: view.frame.midX - 60, y: view.frame.midY - 60 , width: 120, height: 120)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
    }
    
    func showActivityIndicator(_ view: UIView, withTitle title: String) {

        hideActivitiIndicator()

        strLabel = UILabel(frame: CGRect(x: 0, y: 70, width: 120, height: 46))
        strLabel.text = title
        strLabel.textAlignment = .center
        strLabel.font = .systemFont(ofSize: 18, weight: UIFont.Weight.medium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)

        effectView.frame = CGRect(x: view.frame.midX - 60, y: view.frame.midY - 60 , width: 120, height: 120)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true

        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
        } else {
            // Fallback on earlier versions
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        
        activityIndicator.color = UIColor.white
        activityIndicator.frame = CGRect(x: 30, y: 20, width: 60, height: 60)
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
