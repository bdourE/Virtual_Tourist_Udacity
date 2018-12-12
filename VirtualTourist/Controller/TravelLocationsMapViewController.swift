//
//  TravelLocationsMapViewController.swift
//  VirualTourist
//
//  Created by بدور on 06/12/2018.
//  Copyright © 2018 Bdour. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData
class TravelLocationsMapViewController: UIViewController ,MKMapViewDelegate {

    //MARK: Outlets & Properties
    @IBOutlet weak var mapView: MKMapView!
    var pinCoordinate : CLLocationCoordinate2D!
    var deleteLabel: UILabel!
    var EditBtn: UIBarButtonItem!
    var DoneBtn: UIBarButtonItem!
    var pin : Pin?
    var pins : [Pin] = []
    var dataController:DataController!
    var deleteMode = false
    //MARK: UI Configuration Enum
    enum UIState { case  delete, Normal }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // add tap Gesture so user can add pin
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        longPressGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGesture)
        
        //UI setting
        setUI()
        setUIForState(.Normal)
        
        // get saved pin
         loadPins()
        
       
        
    }
    
    fileprivate func loadPins() {
        let fethRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fethRequest){
            pins = result
        }
        updateMap()
    }
    
    func updateMap (){
        if pins.isEmpty {
            EditBtn.isEnabled = false
        }
        else {
               EditBtn.isEnabled = true
            for index in 0...pins.count-1 {
                let coordinate = CLLocationCoordinate2DMake(pins[index].latitude, pins[index].longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                self.mapView.addAnnotation(annotation)
            }}
    }
    
    
    // Adds a new notebook to the end of the `notebooks` array
    func addPin(long: Double , lat : Double) {
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = long
        pin.latitude = lat
        try? dataController.viewContext.save()
        pins.append(pin)
        updateMap()
    }
    
    @objc func deletePin(_ sender: Any) {
        if (deleteMode)
        {
            setUIForState(.Normal)
            deleteMode = false
            if pins.isEmpty {
                EditBtn.isEnabled = false
            }}
        else {
            setUIForState(.delete)
            deleteMode = true
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let mapCoordinate = view.annotation?.coordinate
        {
            if deleteMode  {
                for index in 0...pins.count-1{
                    if (mapCoordinate.latitude == pins[index].latitude && mapCoordinate.longitude == pins[index].longitude)
                    {
                        dataController.viewContext.delete(pins[index])
                        try? dataController.viewContext.save()
                        pins.remove(at: index)
                        mapView.removeAnnotation(view.annotation!)
                      
                        break
                    }}
                
                
            }
            else {
                for index in 0...pins.count-1{
                    if (mapCoordinate.latitude == pins[index].latitude && mapCoordinate.longitude == pins[index].longitude)
                    {
                        pin = pins[index]
                        performSegue(withIdentifier: "FindImages", sender: self)
                        break
                    }  }  } } }
    
    @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .ended {
            let point = gesture.location(in: self.mapView)
            let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
             addPin(long: coordinate.longitude, lat: coordinate.latitude)
        }
    }
    
    
    func setUI(){
        EditBtn = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(deletePin))
        DoneBtn = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(deletePin))
        self.navigationItem.rightBarButtonItem  = EditBtn
        deleteLabel = UILabel(frame: CGRect(x: 0, y: self.view.frame.size.height , width: self.view.frame.size.width, height: 50))
        deleteLabel.text = "Tap pins to delete"
        deleteLabel.textColor = UIColor.white
        deleteLabel.backgroundColor = UIColor.red
        deleteLabel.textAlignment = NSTextAlignment.center
    }
    
    func setUIForState(_ state: UIState) {
        switch state {
        case .delete:
            view.frame.origin.y -= deleteLabel.frame.height
            self.view.addSubview(deleteLabel)
            deleteLabel.isHidden = false
            self.navigationItem.rightBarButtonItem  = DoneBtn
        case .Normal:
           deleteLabel.removeFromSuperview()
            deleteLabel.isHidden = true
             view.frame.origin.y = 0
           self.navigationItem.rightBarButtonItem  = EditBtn
        }}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "FindImages")
        {
            let PhotoAlbum  = segue.destination as! AlbumViewController
            PhotoAlbum.dataController = dataController
            PhotoAlbum.pin = self.pin!
        }
    }
}
