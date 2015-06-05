//
//  PageViewController.swift
//  Dam It!
//
//  Created by Noah Conley on 6/5/15.
//  Copyright (c) 2015 EECS370. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

	let pageTitles = ["The Problem", "Your Job", "Your Goal", "Game Over"]
	var images = ["htp1.png","htp2.png","htp3.png","htp4.png"]
	var count = 0

	var pageViewController : UIPageViewController?

	@IBAction func swipeLeft(sender: AnyObject) {
		println("Swipe left")
	}
	@IBAction func swiped(sender: AnyObject) {
		pageViewController!.view.removeFromSuperview()
		pageViewController!.removeFromParentViewController()
		reset()
	}

	func reset() {
		/* Getting the page View controller */
		pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? UIPageViewController
		pageViewController!.dataSource = self as UIPageViewControllerDataSource

		let pageContentViewController = self.viewControllerAtIndex(0)
		pageViewController!.setViewControllers([pageContentViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)

		/* We are substracting 30 because we have a start again button whose height is 30*/
		pageViewController!.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height - 30)
		self.addChildViewController(pageViewController!)
		self.view.addSubview(pageViewController!.view)
		pageViewController!.didMoveToParentViewController(self)
	}

	@IBAction func start(sender: AnyObject) {
		let pageContentViewController = self.viewControllerAtIndex(0)
		pageViewController!.setViewControllers([pageContentViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		reset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {

		var index = (viewController as! UIPageContentViewController).pageIndex!
		index++
		if(index >= self.images.count){
			return nil
		}
		return self.viewControllerAtIndex(index)
	}

	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

		var index = (viewController as! UIPageContentViewController).pageIndex!
		if(index <= 0){
			return nil
		}
		index--
		return self.viewControllerAtIndex(index)
	}

	func viewControllerAtIndex(index : Int) -> UIViewController? {
		if((self.pageTitles.count == 0) || (index >= self.pageTitles.count)) {
			return nil
		}
		let pageContentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageContentViewController") as! UIPageContentViewController

		pageContentViewController.imageName = self.images[index]
		pageContentViewController.titleText = self.pageTitles[index]
		pageContentViewController.pageIndex = index
		return pageContentViewController
	}

	func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
		return pageTitles.count
	}

	func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
		return 0
	}
}
