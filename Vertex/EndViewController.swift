//
//  EndViewController.swift
//  Dam It!
//
//  Created by Alex Sanz on 6/5/15.
//  Copyright (c) 2015 EECS370. All rights reserved.
//

import UIKit
import Foundation


class EndViewController: UIViewController {

	var score = 0
	var level = 0

	@IBOutlet weak var scoreLabel: UILabel!

	@IBOutlet weak var levelLabel: UILabel!

	@IBOutlet weak var restartButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
		scoreLabel.text = "Score: \(score)"
		levelLabel.text = "Level: \(level)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    
}