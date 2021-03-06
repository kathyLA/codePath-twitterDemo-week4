//
//  TweetsViewController.swift
//  TwitterDemo
//
//  Created by kathy yin on 4/16/17.
//  Copyright © 2017 kathy. All rights reserved.
//

import UIKit

class TweetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ComposeTweetViewConrollerDelegate, TweetCellButtonDelegate {
    var mode: tweetsMode = .home
    var tweets: [Tweet]!
    var showProfileHearder: Bool = true
    var profileView: ProfileView = UINib(nibName: "ProfileView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ProfileView
    var showBackButton: Bool = false
    var user: User! {
        didSet {
            if showProfileHearder {
                profileView.user = user
            }
        }
    }
    
    @IBOutlet weak var tableview: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableview.dataSource = self
        self.tableview.delegate = self
        self.tableview.estimatedRowHeight = 120
        self.tableview.rowHeight = UITableViewAutomaticDimension
        self.tableview.refreshControl = UIRefreshControl()
        self.tableview.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableview.delaysContentTouches = false
        
        if showBackButton == true {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(onBack))
        } else {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(onlogOut(_:)))
        }

        switch (self.mode) {
            case .home:
                showProfileHearder = false
                break
            case .mentions:
                showProfileHearder = false
                break
            case .profile:
                showProfileHearder = true
                break
        }
        
        if showProfileHearder {
            self.tableview.tableHeaderView = profileView
        }
        
        if (self.mode == .profile || self.mode == .mentions) {
            if (self.user == nil) {
                user = User.currentUser
            }
        }
        refresh()
    }
    
    func onBack () {
        self.navigationController?.popViewController(animated: true)
    }
    
    func onlogOut(_ sender: Any) {
        User.currentUser = nil
        TwitterClient.shareInstance?.logout()
    }
    
    func refresh() {
        switch mode {
            case .profile:
                TwitterClient.shareInstance?.userTimeline(screenName: user.screenName!, success: { (tweets: [Tweet]) in
                    self.tweets = tweets
                    self.tableview.refreshControl?.endRefreshing()
                    self.tableview.reloadData()
                }, failure: { (error) in
                    self.tableview.refreshControl?.endRefreshing()
                })
            case .home:
                TwitterClient.shareInstance?.homeTimeline(success: { (tweets: [Tweet]) in
                    self.tweets = tweets
                    self.tableview.refreshControl?.endRefreshing()
                    self.tableview.reloadData()
                }, failure: { (error) in
                    self.tableview.refreshControl?.endRefreshing()
                })
            
            case .mentions:
                TwitterClient.shareInstance?.userTimeline(screenName: user.screenName!, success: { (tweets: [Tweet]) in
                    self.tweets = tweets
                    self.tableview.refreshControl?.endRefreshing()
                    self.tableview.reloadData()
                }, failure: { (error) in
                    self.tableview.refreshControl?.endRefreshing()
                })
            
        }
    }

    func didTapUserProfile(tweetCell: TweetCell) {
        let indexPath = tableview.indexPath(for: tweetCell)
        let tweet = self.tweets[(indexPath?.row)!]
        let user = tweet.user
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tweetsNaviVC = storyboard.instantiateViewController(withIdentifier: "TweetsNavigationComtroller") as! UINavigationController
        let tweetsVC = tweetsNaviVC.topViewController as! TweetsViewController
        tweetsVC.user = user
        tweetsVC.mode = .profile
        tweetsVC.showBackButton = true
        self.navigationController?.pushViewController(tweetsVC, animated: true)
    }
    
    func didTapReplyTweet(tweetCell: TweetCell) {
        self.performSegue(withIdentifier: "ReplyTweet", sender: tweetCell)
    }
    
    func didTapRetweet(tweetCell: TweetCell) {
        let indexPath = tableview.indexPath(for: tweetCell)
        let tweet = self.tweets[(indexPath?.row)!]
        let value = !(tweet.retweeted ?? false)
        var retweetsCount = tweet.retweetCount
        self.tweets[(indexPath?.row)!].retweeted = value
        if (value) {
            retweetsCount = retweetsCount + 1;
            TwitterClient.shareInstance?.retweet(id: tweet.id!, success: {
            }, failure: { (error) in
            })
        } else {
            retweetsCount = retweetsCount - 1
            TwitterClient.shareInstance?.unRetweet(id: tweet.id!, success: {
            }, failure: { (error) in
            })
        }

        self.tweets[(indexPath?.row)!].retweetCount = retweetsCount
        self.tableview.reloadRows(at: [indexPath!], with: .automatic)
    }
    
    func didTapFavorite(tweetCell: TweetCell) {
        let indexPath = tableview.indexPath(for: tweetCell)
        let tweet = self.tweets[(indexPath?.row)!]
        let value = !(tweet.favorited ?? false)
        var favoriteCount = tweet.user?.favouritesCount
        self.tweets[(indexPath?.row)!].favorited = value
        if (value) {
            favoriteCount = favoriteCount! + 1;
            TwitterClient.shareInstance?.favorite(id: tweet.id!, success: {
            }, failure: { (error) in
            })
        } else {
            favoriteCount = favoriteCount! - 1
            TwitterClient.shareInstance?.unFavorite(id: tweet.id!, success: {
            }, failure: { (error) in
            })
        }
        
        self.tweets[(indexPath?.row)!].user?.favouritesCount = favoriteCount!
        self.tableview.reloadRows(at: [indexPath!], with: .automatic)
    }
    
    func didTweet(composeTweetViewController: ComposeTweetViewController) {
        self.navigationController?.popViewController(animated: true)
        refresh()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  (tweets != nil) ? tweets.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tweet = self.tweets[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TweetCell") as! TweetCell
        cell.tweet = tweet
        cell.delegate = self
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        
        if(segue.identifier == "NewTweet") {
            let vc = segue.destination as! ComposeTweetViewController
            vc.delegate = self
            vc.user = User.currentUser
            vc.isReply = false
        } else if (segue.identifier == "ReplyTweet") {
            let vc = segue.destination as! ComposeTweetViewController
            vc.delegate = self
            let indexPath = tableview.indexPath(for: (sender as? TweetCell)!)
            let tweet = self.tweets[(indexPath?.row)!]
            vc.user = User.currentUser
            vc.replyId = tweet.id
            vc.replyScreenName = tweet.user?.screenName
            vc.isReply = true
            
        } else {
            let vc = segue.destination as! DetailTweetViewController
            let indexPath = tableview.indexPath(for: (sender as? TweetCell)!)
            vc.tweet = self.tweets[(indexPath?.row)!]
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
