//
//  NavigateViewController.swift
//  Sparking
//
//  Created by 김나연 on 4/4/25.
//

import UIKit
import MapKit

class NavigateViewController: UIViewController {
    @IBOutlet weak var expTimeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var parkingLot: Row?
    var latitude: Double = 0.0
    var longtitude: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        guard let address = parkingLot?.ADDR else { return }
        print(address)
        pinningParkingCoordinates(address) { coordinate in
            guard let coordinate else {
                print("좌표 변환 실패")
                return
            }
            self.latitude = coordinate.latitude
            self.longtitude = coordinate.longitude
            
            self.directionCallRequest(origin: "127.10764191124568,37.402464820205246", destination: "\(self.longtitude),\(self.latitude)")
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
            
            let coordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
            
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
            startAnnotation.title = "현재 위치"
            
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longtitude)
            print(self.latitude, self.longtitude)
            endAnnotation.title = "도착지"
            
            guard let data else { return }
            do {
                let root = try JSONDecoder().decode(MapRoot.self, from: data)
                let routes = root.routes.first
                let summary = routes?.summary
                
                print(summary?.duration)
                
                DispatchQueue.main.async {
                    self.mapView.setRegion(region, animated: true)
                    self.mapView.addAnnotation(startAnnotation)
                    self.mapView.addAnnotation(endAnnotation)
                    self.expTimeLabel.text = "예상 소요 시간: 약 \((summary?.duration ?? 0)/60)분"
                }
                
            } catch {
                print("JSON 디코딩 실패: \(error.localizedDescription)")
            }
        }.resume()
    }
}
