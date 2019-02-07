//
//  MapVC.swift
//  virtualtourist
//
//  Created by carloshenrique.carmo on 06/02/19.
//  Copyright © 2019 carloshpdoc. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapVC: UIViewController {
        
@IBOutlet weak var mapView: MKMapView!
@IBOutlet weak var editButton: UIBarButtonItem!
@IBOutlet weak var removePinBannerConstraint: NSLayoutConstraint!

var dataController: DataController!
var fetchedResultsController:NSFetchedResultsController<Pin>!
var removePin = false

    override func viewDidLoad() {
        mapView.delegate = self
        setupFetchedResultsController()
    }

    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            for pin in result {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
                mapView.addAnnotation(annotation)
            }
        }
    }

    // MARK: Add Pin to Map
    @IBAction func pressMapAddPin(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let pressedMap = sender.location(in: mapView)
            let location = mapView.convert(pressedMap, toCoordinateFrom: mapView)
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = Double(location.latitude)
            pin.longitude = Double(location.longitude)

            try? dataController.viewContext.save()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            mapView.addAnnotation(annotation)
        }
    }

    @IBAction func pressEdit(_ sender: Any) {

        removePinBannerConstraint.constant = removePinBannerConstraint.constant == 0 ? -70.0 : 0
        editButton.title = removePinBannerConstraint.constant == 0 ? "Edit" : "Done"
        removePin = removePinBannerConstraint.constant == 0 ? false : true
        
        // Pin Banner Animation
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    }

extension MapVC: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var pinView: MKPinAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            pinView = dequeuedView
        } else {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView.animatesDrop = true
        }
        
        return pinView
    }

    // MARK: Pin Pressed
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        if let annotation = view.annotation {
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [annotation.coordinate.latitude, annotation.coordinate.longitude])
            fetchRequest.predicate = predicate
            
            if let result = try? dataController.viewContext.fetch(fetchRequest),
                let pin = result.first {
                

                if removePin {
                    dataController.viewContext.delete(pin)
                    try? dataController.viewContext.save()
                    mapView.removeAnnotation(annotation)

                } else {
                    performSegue(withIdentifier: "SeguePhotoVC", sender: pin )
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SeguePhotoVC" {
            let viewController = segue.destination as! PhotoVC
            viewController.pin = sender as? Pin
        }
    }
}
