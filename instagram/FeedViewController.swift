//
//  FeedViewController.swift
//  instagram
//
//  Created by Luis Mora on 3/4/22.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    //comment bar variables
    let commentBar = MessageInputBar()
    var showsCommentBar = false
    
    //post variables
    var selectedPost: PFObject!
    var posts = [PFObject]()
    
    //query variables
    let query = PFQuery(className:"Posts")
    var queryLimit = 3
    let refreshControl = UIRefreshControl()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment.."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.keyboardDismissMode = .interactive
        
        //when that event happens(hide keyboard), call function
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func keyboardWillBeHidden(note: Notification) {
        commentBar.inputTextView.text = nil
        
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    //using message input bar method
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadPosts()
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        //create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!

        //adding comment to comments array to post
        selectedPost.add(comment, forKey: "comments")

        selectedPost.saveInBackground{(success, error) in
            if success {
                print("comment saved")
            } else {
                print("error saving comment")
            }
        }
        tableView.reloadData()
        
        //clear and dismiss the input bar
        commentBar.inputTextView.text = nil
        
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    //setting up table view cells for the post
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        return comments.count + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    //creating the proper tableview cell: post/comment/add-comment
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 {
            
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            
            cell.captionLabel.text = post["caption"] as? String
            
            //setting image for post
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            cell.photoView.af.setImage(withURL: url)
            
            //setting image from profile
            if let profilePicFile = user["profilepic"] as? PFFileObject {
                let profilePicurlString = profilePicFile.url!
                let profilePicurl = URL(string: profilePicurlString)!
                cell.profilePicView.af.setImage(withURL: profilePicurl)
            }
            
            return cell
        } else if indexPath.row <= comments.count {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            
            //setting comment profile pic image
            if let profilePicFile = user["profilepic"] as? PFFileObject {
                let profilePicurlString = profilePicFile.url!
                let profilePicurl = URL(string: profilePicurlString)!
                cell.profilePicView.af.setImage(withURL: profilePicurl)
            }
            
            return cell
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            
            return cell
        }
    }
    
    //laoding the intial posts
    func loadPosts() {

        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = queryLimit
        query.order(byDescending: "updatedAt")
        
        query.findObjectsInBackground{ (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
        
    }
    
    //adding more posts
    func loadMorePosts() {
        queryLimit += 3
        
        query.includeKeys(["author", "comments", "comments.author", "comments.author.profilepic"])
        query.limit = queryLimit
        query.order(byDescending: "updatedAt")
        
        query.findObjectsInBackground{ (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    
    //calling loadMorePosts when the bottom of the screen was reached
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section + 1 == posts.count {
            loadMorePosts()
        }
    }
    
    //refreshing screen
    @objc func onRefresh() {
        loadPosts()
        refreshControl.endRefreshing()
    }
    
    //logout logic
    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else {return}
        
        delegate.window?.rootViewController = loginViewController
    }
    
    //returning the selected post
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count+1 {
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
        
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
