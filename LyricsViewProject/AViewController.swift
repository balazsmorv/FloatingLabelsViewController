//
//  AViewController.swift
//  LyricsViewProject
//
//  Created by Balázs Morvay on 2021. 03. 03..
//

import UIKit
import Combine

class AViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let floatingVM = FloatingLabelsViewModel(lineAlphaFactor: 1.0,
                                                 bottomAlphaFactor: 2.0,
                                                 numberOfLines: 10,
                                                 initialLabelNumber: 0,
                                                 leadingPadding: 8.0,
                                                 trailingPadding: 8.0,
                                                 lineSpace: 50,
                                                 font: .systemFont(ofSize: 20),
                                                 extraSpaceInBottom: 0,
                                                 animationLength: 0.5,
                                                 scaleX: 1.0,
                                                 scaleY: 1.0,
                                                 textColor: .blue,
                                                 timer: Timer.publish(every: 1.0, on: .main, in: .default).autoconnect().eraseToAnyPublisher(),
                                                 texts: ["The only string"])
        
        let floatingView = FloatingLabelsView()
        floatingView.viewModel = floatingVM
        floatingView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(floatingView)
        
        floatingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        floatingView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        floatingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        floatingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    }

}
