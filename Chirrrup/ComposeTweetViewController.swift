//
//  ComposeTweetViewController.swift
//  Twitter
//
//  Created by Satyam Jaiswal on 2/29/16.
//  Copyright © 2016 Satyam Jaiswal. All rights reserved.
//

import UIKit
import MBProgressHUD

class ComposeTweetViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tweetTextView: UITextView!
    
    @IBOutlet weak var userProfileImageView: UIImageView!
    
    @IBOutlet weak var characterCountLabel: UILabel!
    
    @IBOutlet weak var replyInfoLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var handleLabel: UILabel!
    
    var placeholderLabel : UILabel!
    
    //var newStatus: String?
    
    var tweetId: String?
    var replyTo: String?
    var delegate: CellDelegate?
    var tweets: [Tweet]? = []
    var temp: Tweet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tweets = []
        
        self.setupUserFields()

        self.setupNavigationBar()
        
        configureTextView()
        
        let tweetCharacterCount = NSString(string: self.tweetTextView.text).length
        self.characterCountLabel.text = "\(140 - tweetCharacterCount)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tweets = []
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUserFields(){
        self.userProfileImageView.setImageWith((User.currentUser?.user_profile_image_url)! as URL)
        self.nameLabel.text = User.currentUser?.name as String?
        self.handleLabel.text = User.currentUser?.screen_name as String?
    }
    
    func setupNavigationBar(){
        navigationController?.delegate = self
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 1.0)
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
    
    func configureTextView(){
        if let listener = replyTo{
            if listener.isEmpty{
                tweetTextView.text = ""
                self.replyInfoLabel.isHidden = true
            }else{
                tweetTextView.text = "@\(listener)"
                self.replyInfoLabel.isHidden = false
                self.replyInfoLabel.text = "in reply to @\(listener)"
            }
        }
        
        tweetTextView.delegate = self
        placeholderLabel = UILabel()
        placeholderLabel.text = "What's happening today?"
        placeholderLabel.font = UIFont.italicSystemFont(ofSize: tweetTextView.font!.pointSize)
        placeholderLabel.sizeToFit()
        tweetTextView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: tweetTextView.font!.pointSize / 2)
        placeholderLabel.textColor = UIColor(white: 0, alpha: 0.3)
        
        placeholderLabel.isHidden = !tweetTextView.text.isEmpty
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        let characterleft = 140 - NSString(string: textView.text).length
        self.characterCountLabel.text = "\(characterleft)"
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return NSString(string: textView.text).length + (NSString(string: text).length - range.length) <= 140
    }
    
    @IBAction func onTapTweetButton(_ sender: AnyObject) {
        
        self.tweetTextView.resignFirstResponder()
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        hud?.labelText = "Posting..."
        let status = self.tweetTextView.text
        //print(status)
        TwitterClient.sharedInstance?.tweet(self.tweetId!, status: status! ,success: { (response: Tweet) -> () in
            //print("response received")
            self.tweets?.append(response)
            
            hud?.labelText = "Post successful!"
            self.tweetTextView.text = ""
            self.replyInfoLabel.isHidden = true
            self.placeholderLabel.isHidden = false		
            MBProgressHUD.hide(for: self.view, animated: true)
        }) { (error: NSError) -> () in
            print("Error in tweet reply: \(error.localizedDescription)")
        }
        
    }
    
    @IBAction func onTweetButtonTapped(_ sender: Any) {
        self.tweetTextView.resignFirstResponder()
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        hud?.labelText = "Posting..."
        let status = self.tweetTextView.text
        //print(status)
        TwitterClient.sharedInstance?.tweet(self.tweetId!, status: status! ,success: { (response: Tweet) -> () in
            //print("response received")
            self.tweets?.append(response)
            
            hud?.labelText = "Post successful!"
            self.tweetTextView.text = ""
            self.replyInfoLabel.isHidden = true
            self.placeholderLabel.isHidden = false
            MBProgressHUD.hide(for: self.view, animated: true)
        }) { (error: NSError) -> () in
            print("Error in tweet reply: \(error.localizedDescription)")
        }
    }
    
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let destinationViewController = viewController as? TweetsViewController{
            if let feeds = self.tweets{
                for tweet in feeds{
                    //print("inserting")
                    destinationViewController.tweets?.insert(tweet, at: 0)
                }
            }
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare for segue of Compose tweet vc called")
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
 

}
