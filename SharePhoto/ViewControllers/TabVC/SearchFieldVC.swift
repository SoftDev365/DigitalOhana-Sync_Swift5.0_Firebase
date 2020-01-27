//
//  SearchFieldVC.swift
//  SharePhoto
//
//  Created by Admin on 1/28/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class SearchFieldVC: UIViewController {

    @IBOutlet weak var swcTaken: UISwitch!
    @IBOutlet weak var swcUpload: UISwitch!
    @IBOutlet weak var swcUser: UISwitch!
    
    @IBOutlet weak var btnTakenFrom: UIButton!
    @IBOutlet weak var btnTakenTo: UIButton!
    
    @IBOutlet weak var btnUploadFrom: UIButton!
    @IBOutlet weak var btnUploadTo: UIButton!
    
    @IBOutlet weak var btnUserName: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }    

    @IBAction func onSwitchTaken(_ sender: Any) {
    }
    
    @IBAction func onBtnTakenFrom(_ sender: Any) {
    }
    
    @IBAction func onBtnTakenTo(_ sender: Any) {
    }
    
    @IBAction func onSwitchUpload(_ sender: Any) {
    }
    
    @IBAction func onBtnUploadFrom(_ sender: Any) {
    }
    
    @IBAction func onBtnUploadTo(_ sender: Any) {
    }
    
    @IBAction func switchUser(_ sender: Any) {
    }
    
    @IBAction func onBtnUserName(_ sender: Any) {
    }
    
    @IBAction func onBtnSearch(_ sender: Any) {
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
