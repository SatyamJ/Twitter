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

class TweetsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CellDelegate, UIScrollViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    @IBOutlet weak var composeBarButton: UIBarButtonItem!
    @IBOutlet weak var logoView: UIView!
    
    var tweets: [Tweet]?
    var user: User?
    var moreDataRequested: Bool = false
    var loadingMoreView:InfiniteScrollActivityView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupNavigationBar()
        
        self.setupTableView()
        
        requestNetworkData()
        
        self.setupRefreshControl()
        
        setupInfiniteScrollView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
    }
    
    func setupRefreshControl(){
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(TweetsViewController.refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    func setupNavigationBar(){
        self.menuBarButton.target = self.revealViewController()
        self.menuBarButton.action = #selector(SWRevealViewController.revealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        self.composeBarButton.image = UIImage(named: "twitter_quill_30")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        //navigationController?.navigationBar.barTintColor = UIColor(red: 0.2118, green: 0.549, blue: 0.7098, alpha: 1.0)
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 1.0)
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let tweets = tweets {
            return tweets.count
        }else{
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TweetCell", for: indexPath) as! TweetCell
        cell.tweet = self.tweets![indexPath.row]
        cell.delegate = self
        return cell
    }
    
    func setupInfiniteScrollView(){
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
    
    func requestNetworkData(){
        MBProgressHUD.showAdded(to: self.view, animated: true)
        TwitterClient.sharedInstance?.homeTimeline({ (tweets:[Tweet]) -> () in
            self.tweets = tweets
            self.tableView.reloadData()
            MBProgressHUD.hide(for: self.view, animated: true)
        }) { (error: NSError) -> () in
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!moreDataRequested){
            
            let scrollViewContentHeight = self.tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - self.tableView.bounds.size.height
            
            if scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging {
                moreDataRequested = true
                
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                loadMoreData()
            }
            
        }
    }
    
    func loadMoreData(){
        if let lastTweetId = Int((self.tweets?.last?.tweetId)! as String){
            TwitterClient.sharedInstance?.homeTimelineOnScroll(lastTweetId-1, success: { (moreTweets: [Tweet]) in
                self.tweets?.append(contentsOf: moreTweets)
                self.loadingMoreView!.stopAnimating()
                self.tableView.reloadData()
                self.moreDataRequested = false
            }) { (error: NSError) in
                print("Error in loading more feeds: \(error.localizedDescription)")
            }
        }
    }
    
    func onTapCellProfileImage(_ sender: AnyObject?){
        //print("onTapCellProfileImage")
        let recog = sender as! UITapGestureRecognizer
        let view = recog.view
        let cell = view!.superview?.superview as! TweetCell
        let indexPath = tableView.indexPath(for: cell)
        self.user = tweets![indexPath!.row].user
        performSegue(withIdentifier: "showUserProfileSegue", sender: nil)
    }
    
    func onTapCellLike(_ sender: AnyObject?) {
        //print("onTapCellLike called")
        if let recognizer = sender as? UITapGestureRecognizer{
            let imageView = recognizer.view
            if let cellView = imageView?.superview?.superview as? TweetCell {
                let indexPath = self.tableView.indexPath(for: cellView)
                if let row = indexPath?.row{
                    if let tweet = self.tweets?[row]{
                        //print("processing tweet id: \(tweet.tweetId)")
                        if tweet.liked == true{
                            //self.tweets![(indexPath?.row)!].liked = false
                            TwitterClient.sharedInstance?.unlike(String(tweet.tweetId!),
                                success: { () -> () in
                                    self.tweets![(indexPath?.row)!].liked = false
                                    self.tweets![(indexPath?.row)!].likes_count -= 1
                                    self.tableView.reloadData()
                                }, failure: { (error: NSError) -> () in
                                    print("Tweet Unlike error: \(error.localizedDescription)")
                            })
                        }else{
                            //self.tweets![(indexPath?.row)!].liked = true
                            TwitterClient.sharedInstance?.like(String(tweet.tweetId!),
                                success: { () -> () in
                                    self.tweets![(indexPath?.row)!].liked = true
                                    self.tweets![(indexPath?.row)!].likes_count += 1
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
            if let cellView = imageView?.superview?.superview as? TweetCell {
                let indexPath = self.tableView.indexPath(for: cellView)
                if let row = indexPath?.row{
                    if let tweet = self.tweets?[row]{
                        //print("processing tweet id: \(tweet.tweetId!)")
                        if tweet.retweeted == true{
                            TwitterClient.sharedInstance?.unretweet(String(tweet.tweetId!),
                                success: { () -> () in
                                    self.tweets![(indexPath?.row)!].retweeted = false
                                    self.tweets![(indexPath?.row)!].retweet_count -= 1
                                    self.tableView.reloadData()
                                }, failure: { (error: NSError) -> () in
                                    print("Un-retweet error: \(error.localizedDescription)")
                            })
                        }else{
                            TwitterClient.sharedInstance?.retweet(String(tweet.tweetId!),
                              success: { () -> () in
                                self.tweets![(indexPath?.row)!].retweeted = true
                                self.tweets![(indexPath?.row)!].retweet_count += 1
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
    

        // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TweetDetailsSegue"{
            if let cell = sender as? TweetCell{
                let indexPath = tableView.indexPath(for: cell)
                if let destinationViewController = segue.destination as? TweetDetailsViewController{
                    destinationViewController.tweet = self.tweets![indexPath!.row] as Tweet
                    destinationViewController.row = indexPath!.row
                    let bgView = UIView()
                    bgView.backgroundColor = UIColor.gray
                    cell.selectedBackgroundView = bgView
                    
                    tableView.deselectRow(at: indexPath!, animated: true)
                }
            }
        } else if segue.identifier == "showUserProfileSegue" {
            if let destinationViewController = segue.destination as? MeViewController {
                destinationViewController.user = self.user
            }
        } else if segue.identifier == "tweetSegue" {
            if let recognizer = sender as? UIGestureRecognizer{
                let view = recognizer.view
                if let cell = view?.superview?.superview as? TweetCell{
                    let indexPath = tableView.indexPath(for: cell)
                    if let destinationViewController = segue.destination as? ComposeTweetViewController{
                        destinationViewController.tweetId = tweets?[(indexPath?.row)!].tweetId!
                        destinationViewController.replyTo = tweets?[(indexPath?.row)!].user?.screen_name
                        destinationViewController.tweets = self.tweets
                    }
                }
            }else{
                if let destinationViewController = segue.destination as? ComposeTweetViewController{
                    //print("segue for new tweet")
                    destinationViewController.tweetId = ""
                    destinationViewController.replyTo = ""
                    destinationViewController.temp = self.tweets![0]
                }
            }
        }
    }
}
