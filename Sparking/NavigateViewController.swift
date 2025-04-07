//
//  NavigateViewController.swift
//  Sparking
//
//  Created by 김나연 on 4/4/25.
//

import UIKit
import MapKit
import CoreLocation

class NavigateViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var expTimeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var parkingLot: Row?
    var latitude: Double = 0.0
    var longtitude: Double = 0.0
    
    var currentLatitude: Double = 0.0
    var currentLongtitude: Double = 0.0
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let status = locationManager.authorizationStatus
        print("현재 권한 상태: \(status.rawValue)")
        
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first   {
            currentLongtitude = location.coordinate.longitude
            currentLatitude  = location.coordinate.latitude
            print("위치 업데이트")
            print("위도: \(location.coordinate.latitude), 경도: \(location.coordinate.longitude)")
            
            guard let address = parkingLot?.ADDR else { return }
            
            pinningParkingCoordinates(address) { coordinate in
                guard let coordinate else {
                    print("좌표 변환 실패")
                    return
                }
                
                self.latitude = coordinate.latitude
                self.longtitude = coordinate.longitude
                
                print(self.longtitude)
                print(self.latitude)
                print(self.currentLatitude)
                print(self.currentLongtitude)
                
                self.directionCallRequest(origin: "\(self.currentLongtitude),\(self.currentLatitude)", destination: "\(self.longtitude),\(self.latitude)")
            }
        }
    }
    
    // API 주소 좌표로 변환
    func pinningParkingCoordinates(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { placemarks, error in
            print("주소 확인: \(address)")
            
            if let error = error {
                print("주소 변환 실패: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let location = placemarks?.first?.location else {
                print("위치 정보 없음: \(address)")
                completion(nil)
                return
            }
            
            completion(location.coordinate)
        }
    }
    
    // 길찾기 API(kakao mobility) 이용하기 - 길 찾아서 예상 소요시간 추출, 현재 위치/도착지 핀
    func directionCallRequest(origin: String, destination: String) {
        guard var urlComponents = URLComponents(string: "https://apis-navi.kakaomobility.com/v1/directions") else {
            print("URL Components Error")
            return
        }
        
        let queryItemArray = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "priority", value: "RECOMMEND")
        ]
        
        urlComponents.queryItems = queryItemArray
        
        guard let url = urlComponents.url else {
            print("URL Error")
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("KakaoAK a1ca20c12106778d413b69fdaace0b23", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            let coordinate = CLLocationCoordinate2D(latitude: self.currentLatitude, longitude: self.currentLongtitude)
            
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = CLLocationCoordinate2D(latitude: self.currentLatitude, longitude: self.currentLongtitude)
            startAnnotation.title = "현재 위치"
            
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longtitude)
            endAnnotation.title = "도착지"
            
            guard let data else { return }
            do {
                let root = try JSONDecoder().decode(MapRoot.self, from: data)
                let routes = root.routes.first
                let summary = routes?.summary
                
                DispatchQueue.main.async {
                    guard self.mapView != nil else {
                        print("mapView is nil")
                        return
                    }
                    
                    self.mapView.setRegion(region, animated: true)
                    self.mapView.addAnnotation(startAnnotation)
                    self.mapView.addAnnotation(endAnnotation)
                    self.expTimeLabel.text = "🚘 예상 소요 시간: 약 \((summary?.duration ?? 0)/60)분"
                    
                    let sections = routes?.sections ?? []
                    for section in sections {
                        for road in section.roads {
                            let coordinates = self.convertVertexesToCoordinates(vertexes: road.vertexes)
                            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                            self.mapView.addOverlay(polyline)
                        }
                    }
                }
                
            } catch {
                print("JSON 디코딩 실패: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // vertexes 좌표 배열을 지도에 찍을 수 있게 변환함
    func convertVertexesToCoordinates(vertexes: [Double]) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        for i in stride(from: 0, to: vertexes.count, by: 2) {
            let longitude = vertexes[i]
            let latitude = vertexes[i + 1]
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            coordinates.append(coordinate)
        }
        return coordinates
    }
    
    // polyline custom
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer()
    }
}
