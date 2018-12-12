//
//  AlbumViewController.swift
//  VirualTourist
//
//  Created by بدور on 11/12/2018.
//  Copyright © 2018 Bdour. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import   CoreData
// MARK: - ViewController: UIViewController

class AlbumViewController:UIViewController , UICollectionViewDelegate , UICollectionViewDataSource  {
    
    
     // MARK: Properties
    var pin : Pin?
    var selectedPhototIndex : [IndexPath] = []
    var downloadingState = false
    var selectingState = false
    var  StopDownloading = false
    var flickr = Flickr()
    
    // MARK: - Variables - For FetchController
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    //MARK: UI Configuration Enum
    enum UIState { case  Downloading , Normal , Selecting }
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var NewCollectionBtn: UIButton!
    
   // MARK: Life Cycle
   override func viewDidLoad() {
      
        super.viewDidLoad()
        setupFetchedResultsController()
        setTheMap()
        setCollectionView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchedResultsController = nil
        StopDownloading = true
        flickr.cancel()
    }
   
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "location == %@", pin!)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        if (fetchedResultsController.fetchedObjects?.isEmpty)!{
            
            downloading (long: (pin?.longitude)! , lati: (pin?.latitude)!)
        }
    }
    
    fileprivate func setTheMap() {
        // place pin on Map
        let initialLocation = CLLocation(latitude:(pin?.latitude)!, longitude: (pin?.longitude)!)
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: (pin?.latitude)!, longitude: (pin?.longitude)!)
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func setCollectionView() {
        // ADD Tap Gesture To collection view
        let longPressGesture = UITapGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        collectionView!.addGestureRecognizer(longPressGesture)
        // set up collection view
        collectionView!.delegate = self
        collectionView!.dataSource = self
        // set flow layout properties.
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        // the space between items within a row or column
        flowLayout.minimumInteritemSpacing = space
        //the space between rows or columns
        flowLayout.minimumLineSpacing = space
        //cell size
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    // MARK: Search Actions
    func downloading (long : Double , lati : Double) {
        
        setUIForState(.Downloading)
        flickr.getImages(latitude: lati , longitude: long) { (totalPages, error) in
            
            if let error = error
            {
                performUIUpdatesOnMain {
                    self.setUIForState(.Normal)
                    self.alertWithError(error: "No photo returned. Try again.")
                }
            }
                
            else {
                // pick a random page!
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
              self.flickr.displayImageFromFlickrBySearch(withPageNumber: randomPage){ (imageUrlString, error) in
                    if let error = error
                    {
                        performUIUpdatesOnMain {
                            self.setUIForState(.Normal)
                            self.alertWithError(error: "No photo returned. Try again.")
                        }
                    }
                    else{
                        for index in 0...imageUrlString.count-1 {
                            if !(self.StopDownloading){
                             // if an image exists at the url, set the image and title
                            let imageURL = URL(string: imageUrlString[index])
                            if let imageData = try? Data(contentsOf: imageURL!) {
                                performUIUpdatesOnMain {
                                    
                                    let photo = Photo(context: self.dataController.viewContext)
                                    photo.image = imageData
                                    photo.location = self.pin
                                    try? self.dataController.viewContext.save()
                                }} }}
                        // Dawnload Completed
                        performUIUpdatesOnMain {
                                    self.setUIForState(.Normal)
                        } }}}}}
    
    // MARK: Collection View Data Source
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
            return fetchedResultsController.sections?.count ?? 1 }
    
    
   
    
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell",
                                                      for: indexPath) as! CustomCell
        cell.ActivityIndicator.startAnimating()
       let photo = fetchedResultsController.object(at: indexPath)
        let img = UIImage(data: photo.image!)
        cell.imageView?.image = img
        if (selectedPhototIndex.contains(indexPath)){
            cell.imageView.alpha = 0.3
        }
        else {
            cell.imageView.alpha = 1
        }
        cell.ActivityIndicator.stopAnimating()
        cell.ActivityIndicator.isHidden = true
       return cell
    }

  @objc func handleLongPress(gesture: UITapGestureRecognizer) {
    
            let p = gesture.location(in: self.collectionView)
            let indexPath = self.collectionView!.indexPathForItem(at: p)
            if let index = indexPath {
                let cell = self.collectionView!.cellForItem(at: index) as? CustomCell
                if (selectedPhototIndex.contains(index))
                {
                    let i = selectedPhototIndex.index(of: index)
                    selectedPhototIndex.remove(at: i!)
                    cell?.imageView.alpha = 1
                }
                else {
                    selectedPhototIndex.append(index)
                    cell?.imageView.alpha = 0.3
                }
                if (selectedPhototIndex.isEmpty){
                   setUIForState(.Normal)
                }
                else {
                    setUIForState(.Selecting)
                }  }  }
    
   func deleteSelectedPhoto(){
        selectedPhototIndex.sort(){$0>$1}
        for index in selectedPhototIndex
        {
            let photo = fetchedResultsController.object(at: index)
            dataController.viewContext.delete(photo)
          
        }
        selectedPhototIndex.removeAll()
        try?  dataController.viewContext.save()
        setUIForState(.Normal)
    }
    
func UpdateColletion(){
        for oldPhoto in fetchedResultsController.fetchedObjects!
        {dataController.viewContext.delete(oldPhoto)}
        try?  dataController.viewContext.save()
        downloading(long: (pin?.longitude)!, lati: (pin?.latitude)!)

    }
    
    @IBAction func newCollection(_ sender: Any) {
        if selectingState {
            deleteSelectedPhoto()
                }
        else {
    UpdateColletion()
        }}
    
    func setUIForState(_ state: UIState) {
        switch state {
        case .Downloading:
            selectingState = false
            downloadingState = true
            NewCollectionBtn.isHidden = true
        case .Normal :
            selectingState = false
            downloadingState = false
            NewCollectionBtn.isUserInteractionEnabled = true
             NewCollectionBtn.isHidden = false
             NewCollectionBtn.setTitle("New Collection", for: .normal)
        case .Selecting :
            selectingState = true
            NewCollectionBtn.setTitle("Remove Selected Photo", for: .normal)
        }
    }

    private func alertWithError(error: String) {
        let alertView = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "dismiss", style: .cancel) {
            UIAlertAction in
            self.setUIForState(.Normal)
        }
        alertView.addAction(cancelAction)
        self.present(alertView, animated: true){
            self.view.alpha = 1.0
        }
    }
  

}
extension AlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
   
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            print("Move an item. We don't expect to see this in this app.")
            break
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
    
}


