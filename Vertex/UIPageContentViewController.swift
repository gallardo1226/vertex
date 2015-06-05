//
//  UIPageContentViewController.swift
//  Dam It!
//
//  Created by Noah Conley on 6/5/15.
//  Copyright (c) 2015 EECS370. All rights reserved.
//

import UIKit

class UIPageContentViewController: UIViewController {
	@IBOutlet weak var heading: UILabel!
	@IBOutlet weak var bkImageView: UIImageView!

	var pageIndex: Int?
	var titleText : String!
	var imageName : String!

	@IBAction func done(sender: AnyObject) {
		self.parentViewController!.dismissViewControllerAnimated(true, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.bkImageView.image = UIImage(named: imageName)
		self.heading.text = self.titleText
		self.heading.alpha = 0.1
		UIView.animateWithDuration(1.0, animations: { () -> Void in
			self.heading.alpha = 1.0
		})

	}

}
