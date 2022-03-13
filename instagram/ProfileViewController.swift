//
//  ProfileViewController.swift
//  instagram
//
//  Created by Luis Mora on 3/12/22.
//

import UIKit
import Parse
import AlamofireImage

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //make profile picture circle
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.borderColor = UIColor.black.cgColor
        profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        profileImageView.clipsToBounds = true
        
        usernameLabel.text = PFUser.current()?.username as String?
        if let imageFile = PFUser.current()?["profilepic"] as? PFFileObject {
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            profileImageView.af.setImage(withURL: url)
        }
        //let imageFile = PFUser.current()?["profilepic"] as! PFFileObject
        
    }
    
    //profile image opens camera/photolibrary
    @IBAction func editProfileTap(_ sender: Any) {
        //camera view controller
        let picker = UIImagePickerController()
        //call back once there is a photo
        picker.delegate = self
        //able to edit photo
        picker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    //pick image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as! UIImage
        
        let size = CGSize(width: 128, height: 128)
        let scaledImage = image.af.imageAspectScaled(toFill: size)
        
        profileImageView.image = scaledImage
        

        //images need to be saved as "files" in Parse
        let imageData = profileImageView.image!.pngData()
        let file = PFFileObject(name: "image.png", data: imageData!)
        PFUser.current()?["profilepic"] = file
        
        PFUser.current()?
            .saveInBackground { success, error in
            if success {
                self.dismiss(animated: true, completion: nil)
            } else {
                print("Error: \(String(describing: error))")
            }
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
