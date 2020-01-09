//
//  SplashVC.swift
//  SharePhoto
//
//  Created by Admin on 1/9/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class SplashVC: UIViewController {

    @IBOutlet weak var lblMark: UILabel!
    @IBOutlet weak var imgViewMark: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.lblMark.alpha = 0
        self.imgViewMark.alpha = 1.0
        self.view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animate(withDuration: 1.0, animations: {
            self.lblMark.alpha = 1.0
            self.imgViewMark.alpha = 0
            self.view.backgroundColor = .black
        }) { (success) in
            self.perform(#selector(self.gotoSiginPage), with: nil, afterDelay: 0.5)
        }
    }
    
    @objc func gotoSiginPage() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInVC") as? SignInViewController {
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
