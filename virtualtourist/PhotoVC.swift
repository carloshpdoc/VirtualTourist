//
//  File.swift
//  virtualtourist
//
//  Created by carloshenrique.carmo on 06/02/19.
//  Copyright © 2019 carloshpdoc. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var photoAction: UIBarButtonItem!
    
    // MARK: Properties
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var selectedPhotos: [IndexPath]! = []
    
    // MARK: Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        setupMapView()
        setCollectionViewLayout()
        setupFetchedResultsController()
        
        if fetchedResultsController.fetchedObjects!.count == 0 {
            loadPhotos()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView?.reloadData()
    }
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("FetchedResults failure: \(error.localizedDescription)")
        }
    }
    
    func loadPhotos() {
        
        let flickrClient = Flickr.sharedInstance()
        flickrClient.getPhotos(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)) { (success, photos, error) in
            
            if success == false {
                print("Unable download images from Flickr.")
                return
            }
            
            print("Flickr images fetched : \(photos.count)")
            
            photos.forEach() { photo_url in
                let photo = Photo(context: self.dataController.viewContext)
                photo.url = URL(string: photo_url as! String)?.absoluteString
                photo.pin = self.pin
                
                do {
                    // Saves to CoreData
                    try self.dataController.viewContext.save()
                } catch  {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: Download Images
    func downloadImage( imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ error: NSError?) -> Void){
        
        // Create session and request
        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        // Create network request
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            
            if downloadError != nil {
                completionHandler(nil, NSError(domain: "downloadImage", code: 0, userInfo: [NSLocalizedDescriptionKey: imagePath]))
            } else {
                
                completionHandler(data, nil)
            }
        }
        task.resume()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.object(at: indexPath)

        if let data = photo.data {
            cell.photoVCImageView.image = UIImage(data: data)
            cell.activityIndicator.isHidden = true
            cell.activityIndicator.stopAnimating()
        } else {
            cell.photoVCImageView.image = UIImage(named: "image")
            
            // Call Download Image Method
            DispatchQueue.global().async {
                self.downloadImage(imagePath: photo.url!) { imageData, errorString in
                    if let imageData = imageData {
                        DispatchQueue.main.async {
                            cell.activityIndicator.isHidden = true
                            cell.activityIndicator.stopAnimating()
                            cell.photoVCImageView.image = UIImage(data: imageData)
                        }
                        photo.data = imageData
                        try? self.dataController.viewContext.save()
                    }
                }
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Changes photo opacity
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 0.4
        
        if selectedPhotos.contains(indexPath) == false {
            selectedPhotos.append(indexPath)
        }
        selectphotoAction()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        // Changes photo opacity
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 1.0
        
        if let index = selectedPhotos.firstIndex(of: indexPath) {
            selectedPhotos.remove(at: index)
        }
        selectphotoAction()
    }

    func setCollectionViewLayout() {
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        let layout = UICollectionViewFlowLayout()
        
        layout.minimumInteritemSpacing = space
        layout.minimumLineSpacing = space
        layout.itemSize = CGSize(width: dimension, height: dimension)

        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.allowsMultipleSelection = true
    }

    func setupMapView() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude), CLLocationDegrees(pin.longitude))
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    @IBAction func newCollection(_ sender: Any) {
        if hasSelectedPhotos() {
            deletePhotos()
        } else {
            fetchedResultsController.fetchedObjects?.forEach() { photo in
                dataController.viewContext.delete(photo)
                do {
                    // Saves to CoreData
                    try dataController.viewContext.save()
                } catch {
                    print("Unable to delete photo. \(error.localizedDescription)")
                }
            }
            self.collectionView.reloadData()
            loadPhotos()
        }
        // Saves to CoreData
        try? dataController.viewContext.save()
    }

    func selectphotoAction() {
        if hasSelectedPhotos() {
            photoAction.title = "Delete Photos"
            photoAction.tintColor = .red
        }
        else {
            photoAction.title = "News Collection"
            photoAction.tintColor = .blue
        }
    }
    
    // Checks selected photos
    func hasSelectedPhotos() -> Bool {
        return selectedPhotos.count != 0
    }
    
    // Deletes selected photos
    func deletePhotos() {
        let photos = selectedPhotos.map() { fetchedResultsController.object(at: $0) }
        photos.forEach() { photo in
            dataController.viewContext.delete(photo)
            try? dataController.viewContext.save()
        }
    }
}

// MARK: Extensions
extension PhotoVC: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.collectionView?.insertItems(at: [newIndexPath!])
            break
        case .delete:
            self.collectionView?.deleteItems(at: [indexPath!])
            break
        case .update:
            self.collectionView?.reloadItems(at: [indexPath!])
            break
        case .move:
            break
        }
    }
}
