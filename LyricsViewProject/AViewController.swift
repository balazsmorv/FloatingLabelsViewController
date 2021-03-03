//
//  AViewController.swift
//  LyricsViewProject
//
//  Created by Balázs Morvay on 2021. 03. 03..
//

import UIKit

class AViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let vc = ViewController()
        
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: false, completion: nil)

    }

}
