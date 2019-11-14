//
//  ImageSlideViewController.swift
//  SharePhoto
//
//  Created by Admin on 11/14/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit

class ImageSlideViewController: UIViewController {

    @IBOutlet weak var scrView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    var fileList: [StorageItem]?
    
    func setFileList(_ list: [StorageItem]) {
        self.fileList = list
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initContentImageViews()
    }
    
    func initContentImageViews() {
        let w = self.scrView.bounds.size.width
        let h = self.scrView.bounds.size.height
        var k = 0

        for i in 0...(fileList!.count-1) {
            if fileList![i].isFolder == true {
                continue
            }
            
            let rect = CGRect(x: w*CGFloat(k), y: 0, width: w, height: h)
            let item = ImageZoomView(frame: rect, file: fileList![i].file)
            
            self.contentView.addSubview(item)
            k += 1
        }
        
        self.contentView.frame = CGRect(x: 0, y: 0, width: w*CGFloat(k), height: h)
        self.scrView.contentSize = self.contentView.bounds.size
        self.scrView.isPagingEnabled = true
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
