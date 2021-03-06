//
//  TweetsViewController.swift
//  Twitter
//
//  Created by Satyam Jaiswal on 2/20/16.
//  Copyright © 2016 Satyam Jaiswal. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class TweetsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CellDelegate, UIScrollViewDelegate, ComposeTweetDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var networkErrorImageView: UIImageView!
    @IBOutlet weak var ntwkErrStackView: UIStackView!
    
    var tweets: [Tweet]?
    var moreDataRequested: Bool = false
    var loadingMoreView:InfiniteScrollActivityView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func setupUI(){
        self.setupNavigationBar()
        self.setupTableView()
        self.requestNetworkData()
        self.setupRefreshControl()
        self.setupInfiniteScrollView()
        
        self.networkErrorImageView.alpha = 0
        self.setupGestureRecognizers()
    }
    
    fileprivate func setupGestureRecognizers(){
        let networkGesture = UITapGestureRecognizer()
        networkGesture.addTarget(self, action: #selector(onTapNetworkError))
        self.ntwkErrStackView.addGestureRecognizer(networkGesture)
        self.ntwkErrStackView.isUserInteractionEnabled = true
    }
    
    func onTapNetworkError(_ sender: AnyObject){
//        print("onTapNetworkError called")
        hideNetworkError()
        self.requestNetworkData()
    }
    
    fileprivate func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        self.tableView.tableFooterView = UIView()
    }
    
    fileprivate func setupRefreshControl(){
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    fileprivate func setupNavigationBar(){
        self.menuBarButton.target = self.revealViewController()
        self.menuBarButton.action = #selector(SWRevealViewController.revealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
//        self.menuBarButton.image = User.currentUser.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.tweets == nil {
            return 0
        }else{
            return self.tweets!.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TweetCell", for: indexPath) as! TweetCell
        cell.tweet = self.tweets![indexPath.row]
        cell.delegate = self
        cell.accessoryType = .none
        return cell
    }
    
    fileprivate func setupInfiniteScrollView(){
        // Set up Infinite Scroll loading indicator
        let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        tableView.contentInset = insets
    }
    
    func refreshControlAction(_ refreshControl: UIRefreshControl){
        requestNetworkData()
        refreshControl.endRefreshing()
    }
    
    fileprivate func requestNetworkData(){
        MBProgressHUD.showAdded(to: self.view, animated: true)
        TwitterClient.sharedInstance?.homeTimeline({ (tweets:[Tweet]) -> () in
            if tweets.count > 0 {
                self.tweets = tweets
                self.tableView.reloadData()
                MBProgressHUD.hide(for: self.view, animated: true)
                self.hideNetworkError()
            }
            MBProgressHUD.hide(for: self.view, animated: true)
            
        }) { (error: NSError) -> () in
            print("Error: \(error.localizedDescription)")
            MBProgressHUD.hide(for: self.view, animated: true)
            if error.localizedDescription.contains("429"){
                self.requestCountExceeded()
            }else{
                self.showNetworkError()
            }
            
        }
    }
    
    fileprivate func requestCountExceeded(){
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.show(animated: true, whileExecuting: {
            hud?.labelText = "Request limit exceeded. Try again later."
        })
        hud?.hide(true, afterDelay: 1)
    }
    
    fileprivate func showNetworkError(){
        UIView.animate(withDuration: 2, animations: {
            self.networkErrorImageView.alpha = 1.0
        })
    }
    
    fileprivate func hideNetworkError(){
        UIView.animate(withDuration: 1, animations: {
            self.networkErrorImageView.alpha = 0.0
        })
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!moreDataRequested){
            
            let scrollViewContentHeight = self.tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - self.tableView.bounds.size.height
            
            if scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging {
                moreDataRequested = true
                
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                if let progressView = self.loadingMoreView{
                    progressView.frame = frame
                    progressView.startAnimating()
                }
                loadMoreData()
            }
            
        }
    }
    
    fileprivate func loadMoreData(){
        TwitterClient.sharedInstance?.homeTimelineOnScroll(self.getEarliestTweetId(), success: { (moreTweets: [Tweet]) in
            if moreTweets.count > 0 {
                self.tweets?.append(contentsOf: moreTweets)
                self.tableView.reloadData()
            }
            self.loadingMoreView?.stopAnimating()
            self.moreDataRequested = false
        }) { (error: NSError) in
            self.loadingMoreView?.stopAnimating()
            print("Error in loading more feeds: \(error.localizedDescription)")
        }

    }
    
    fileprivate func getEarliestTweetId() -> Int? {
        var id:Int?
        
        if let tweets = self.tweets{
            if tweets.count > 0{
                if let strId = tweets[tweets.count-1].tweetId{
                    id = Int(strId)
                }
            }
        }
        return id
    }
    
    func onTapCellProfileImage(_ sender: AnyObject?){
        //print("onTapCellProfileImage")
        performSegue(withIdentifier: "showUserProfileSegue", sender: sender)
    }
    
    func onTapCellLike(_ sender: AnyObject?) {
        //print("onTapCellLike called")
        if let recognizer = sender as? UITapGestureRecognizer{
            let imageView = recognizer.view
            if let cellView = imageView?.superview?.superview?.superview as? TweetCell {
                if let indexPath = self.tableView.indexPath(for: cellView) {
                    if let tweet = self.tweets?[indexPath.row]{
                        //print("processing tweet id: \(tweet.tweetId)")
                        if tweet.liked == true{
                            //self.tweets![(indexPath?.row)!].liked = false
                            TwitterClient.sharedInstance?.unlike(String(tweet.tweetId!),
                                 success: { () -> () in
                                    self.tweets![indexPath.row].liked = false
                                    self.tweets![indexPath.row].likes_count -= 1
                                    self.tableView.reloadData()
                            }, failure: { (error: NSError) -> () in
                                print("Tweet Unlike error: \(error.localizedDescription)")
                            })
                        }else{
                            //self.tweets![(indexPath?.row)!].liked = true
                            TwitterClient.sharedInstance?.like(String(tweet.tweetId!),
                               success: { () -> () in
                                self.tweets![indexPath.row].liked = true
                                self.tweets![indexPath.row].likes_count += 1
                                self.tableView.reloadData()
                            }, failure: { (error: NSError) -> () in
                                print("Tweet Like error: \(error.localizedDescription)")
                            })
                        }
                    }
                }
            }
        }
    }
    
    func onTapCellReply(_ sender: AnyObject?) {
        performSegue(withIdentifier: "tweetSegue", sender: sender)
    }
    
    func onTapCellRetweet(_ sender: AnyObject?) {
        //print("onTapCellRetweet called")
        if let recognizer = sender as? UITapGestureRecognizer{
            let imageView = recognizer.view
            if let cellView = imageView?.superview?.superview?.superview as? TweetCell {
                if let indexPath = self.tableView.indexPath(for: cellView) {
                    if let tweet = self.tweets?[indexPath.row]{
                        //print("processing tweet id: \(tweet.tweetId!)")
                        if tweet.retweeted == true{
                            TwitterClient.sharedInstance?.unretweet(String(tweet.tweetId!),
                                success: { () -> () in
                                    self.tweets![indexPath.row].retweeted = false
                                    self.tweets![indexPath.row].retweet_count -= 1
                                    self.tableView.reloadData()
                            }, failure: { (error: NSError) -> () in
                                print("Un-retweet error: \(error.localizedDescription)")
                            })
                        }else{
                            TwitterClient.sharedInstance?.retweet(String(tweet.tweetId!),
                                  success: { () -> () in
                                    self.tweets![indexPath.row].retweeted = true
                                    self.tweets![indexPath.row].retweet_count += 1
                                    self.tableView.reloadData()
                            }, failure: { (error: NSError) -> () in
                                print("Retweet error: \(error.localizedDescription)")
                            })
                        }
                    }
                }
                
            }
        }
    }
    
    
    @IBAction func onComposeTapped(_ sender: Any) {
        performSegue(withIdentifier: "tweetSegue", sender: sender)
    }

    func onNewTweet(status: Tweet) {
        self.tweets?.insert(status, at: 0)
        self.tableView.reloadData()
    }
    
    func reload(_ sender: TweetCell) {
        if let indexPath = self.tableView.indexPath(for: sender){
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
        }
    }
    
        // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "TweetDetailsSegue"{
            if let detailsViewController = segue.destination as? TweetDetailsViewController {
                if let cell = sender as? TweetCell{
                    if let indexPath = tableView.indexPath(for: cell) {
                        detailsViewController.tweet = self.tweets![indexPath.row] as Tweet
                        detailsViewController.row = indexPath.row
                        let bgView = UIView()
                        bgView.backgroundColor = UIColor.gray
                        cell.selectedBackgroundView = bgView
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
            }
        } else if segue.identifier == "showUserProfileSegue" {
            if let profileViewController = segue.destination as? MeViewController {
                if let recog = sender as? UITapGestureRecognizer {
                    let view = recog.view
                    if let cell = view?.superview?.superview as? TweetCell {
                        if let indexPath = tableView.indexPath(for: cell) {
                            if let tweet = tweets?[indexPath.row] {
                                profileViewController.user = tweet.user
                            }
                        }
                    }
                }
            }
        } else if segue.identifier == "tweetSegue" {
            if let nc = segue.destination as? UINavigationController {
                if let composeViewController = nc.topViewController as? ComposeTweetViewController {
                    composeViewController.delegate = self
                    if let recognizer = sender as? UIGestureRecognizer{
                        let view = recognizer.view
                        if let cell = view?.superview?.superview?.superview as? TweetCell{
                            if let indexPath = tableView.indexPath(for: cell) {
                                if let tweet = self.tweets?[indexPath.row]{
                                    composeViewController.recepientTweetId = tweet.tweetId
                                    composeViewController.recepientUser = tweet.user
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
