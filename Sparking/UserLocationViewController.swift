//
//  UserLocationViewController.swift
//  Sparking
//
//  Created by 최하진 on 4/5/25.
// 이게 진짜 합치는 몸체이다

import UIKit
import MapKit
import CoreLocation
import Contacts // 터치한 곳 string 변환시 필요

class UserLocationViewController: UIViewController, UISearchBarDelegate {
    // coreloaction으로 현재
    var userLati: Double = 37.5665
    var userLon: Double = 126.9780
    let manager = CLLocationManager()
    let API_KEY = "4965454f67736b6435354d516f646a"
    var tempAdds: [String] = []
    var checkArr:[String] = []
    var searchKey:String = "중구" // 터치한 곳 주소 추출용, 첫 위치는 시청이니까 상수로 넣어둠
    var tempSearch:String = ""
    let activityIndicator = UIActivityIndicatorView(style: .large)
   
    // annotaion arr
    var parkingAnnotations: [ParkingAnnotation] = []
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        manager.delegate = self
        searchBar.delegate = self
        manager.requestWhenInUseAuthorization() // 권한 요청
        
        searchWithQuery(searchKey)
        mapView.preferredConfiguration = MKStandardMapConfiguration()
        updateMapToUserLocation()
        //        manager.startUpdatingLocation()
        // 난 지도 축소 확대가 안돼서 추가
        mapView.isZoomEnabled = true
        
        // 맵뷰 터치 이벤트 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // 첫 실행인지 조건 걸어주기
        // 이건 설치 후 첫 실행
        //   let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchBefore")
        
        // 로딩 인디케이터 설정
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
    }
    
    // 로딩되는 동안 보여줄 대기 화면
    func showLoading(){
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false // 로딩되는 동안 유저가 화면 조작 못하도록 막음
    }
    
    // api 끝난 후에 호출해줘야함
    func hideLoading(){
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    // 터치 이벤트 처리
    // 터치한곳 좌표로 업데이트 해줌
    @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let geocoder = CLGeocoder()
        let point = gestureRecognizer.location(in: mapView) // 화면 상의 CGPoint
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView) // 지도 위의 좌표로 변환
        
        // 내 위치 업데이트
        userLati = coordinate.latitude
        userLon = coordinate.longitude
        
        // 여기서 변경될 주차장api 요청 주소 추출하기
        // 리버스 지오코딩 (좌표 -> 주소)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // reverseGeocodeLocation 얘가 비동기라 클로저에서 처리
        geocoder.reverseGeocodeLocation(location) { placeMarkers, error in
            if let error {
                print("터치한 곳 한글 주소 변환 실패 : \(error.localizedDescription)")
                return
            }
            
            guard let placeMarker = placeMarkers?.first else {
                print("터치한 곳 주소 정보 없음")
                return
            }
            // placeMarker 에서 주소만 문자열로 추출
            let full = placeMarker.description
            //            print("full : \(full)")
            if let range =  full.range(of: "[가-힣]+구", options: .regularExpression) {
                let district = String(full[range])
                //                print("정규식으로 추출한 자치구명: \(district)")
                
                if self.searchKey != district{
                    self.searchKey = district
                    print("변경된 구  : \(self.searchKey)")
                    self.searchWithQuery(self.searchKey)
                }else{
                    print("구 동일 - 검색 스킵")
                }
            }
        }
        
        // #TODO - 얘 실행 위치 변경해야할듯f무ㅐ
        // 터치한 곳에 내 위치 핀 추가
        updateMapToUserLocation()
        
        // 비교 후  api 요청하기
        // 첫 실행인지 조건 걸어야할듯
    }
    
    // 🔍 SearchBar로 자치구 검색 기능
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let geocoder = CLGeocoder()
        guard let district = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !district.isEmpty else { return }
        
        let fullAddress = "서울특별시 \(district)"
        
        geocoder.geocodeAddressString(fullAddress) { placemarks, error in
            if let location = placemarks?.first?.location {
                let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
                self.mapView.setRegion(region, animated: true)
                self.searchWithQuery(district)
            } else {
                print("검색 주소 변환 실패: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        searchBar.resignFirstResponder()
    }
    
    
    
    // 사용자 위치가 변해야 얘도 작동하는데 일단 보류중
//    func searchParking(near coordinate: CLLocationCoordinate2D) {
//        print("서치 파킹 입장")
//        let request = MKLocalSearch.Request()
//        request.naturalLanguageQuery = "주차장"
//        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
//        
//        let search = MKLocalSearch(request: request)
//        search.start { response, error in
//            if let error = error {
//                print("주차장 검색 실패: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let response = response else {
//                print("주차장 검색 결과 없음")
//                return
//            }
//            
//            print("검색 결과: \(response.mapItems.count)개")
//            
//            DispatchQueue.main.async {
//                for item in response.mapItems {
//                    let annotation = CustomAnnotation(
//                        coordinate: item.placemark.coordinate,
//                        title: item.name ?? "주차장"
//                    )
//                    
//                    self.mapView.addAnnotation(annotation)
//                    print("마커 추가: \(item.name ?? "알 수 없음")")
//                }
//            }
//        }
//    }
//    
    // # MARK -  공공 API 데이터 받아오기. + 가공 관련
    func searchWithQuery(_ query: String?) {
        guard let query, !query.isEmpty else {
            print("검색어가 없습니다.")
            return
        }
        
        // 여기서 로딩화면 출력
//        showLoading()
        –––
        guard let endPt = "http://openapi.seoul.go.kr:8088/\(API_KEY)/json/GetParkingInfo/1/200/\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: endPt) else {
            print("URL 생성 실패")
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data else {
                print("데이터 없음")
                return
            }
            
            do {
                let root = try JSONDecoder().decode(ParkingLotRoot.self, from: data)
                let getParkingInfo = root.GetParkingInfo
                let parkingLots = root.GetParkingInfo.row
                
                guard !getParkingInfo.row.isEmpty else {
                    print("주차장 정보가 없습니다.")
                    return
                }
                
                //  주소만 추출하기
                self.tempAdds = getParkingInfo.row.compactMap { $0.ADDR }
                
//                // 여기서 주소 한번 확인해서 다시 담아야함
                self.checkArr = self.tempAdds.map{
                    item in return item.components(separatedBy: "(").first ?? item
                }
                s
                // 한꺼번에 올리는 부분 컨펌 받은 곳
                var totalCount = parkingLots.count
//                self.pinningParkingCoordinates(from: parkingLots, address : self.checkArr)
                for item in parkingLots {
                    let geocoder = CLGeocoder()
                    geocoder.geocodeAddressString(item.ADDR) { places , _ in
                        
                        if let place = places?.first, let location = place.location {
                            let parkingPin = ParkingAnnotation()
                            parkingPin.title = item.PKLT_NM
                            parkingPin.subtitle = item.PAY_YN_NM
                            parkingPin.coordinate = location.coordinate
                            self.parkingAnnotations.append(parkingPin)
                        }else {
                            totalCount -= 1
                        }
                        
                        if totalCount == self.parkingAnnotations.count {
                            DispatchQueue.main.async {
                                self.mapView.addAnnotations(self.parkingAnnotations)
                            }
                        }
                    }
                }
                
            } catch {
                print("JSON 디코딩 실패: \(error.localizedDescription)")
            }
        }.resume()
    }
    
//    func cleanAddress(from raw: String) -> String {
//        let pattern = "\\(.*?\\)|~"
//        let regex = try? NSRegularExpression(pattern: pattern, options: [])
//        let range = NSRange(raw.startIndex..., in: raw)
//        let result = regex?.stringByReplacingMatches(in: raw, options: [], range: range, withTemplate: "") ?? raw
//        return "서울특별시 \(result.trimmingCharacters(in: .whitespacesAndNewlines))"
//    }
    
    // API 주소 -> 좌표로 변환해서 주차장 핀꼽기222
    func pinningParkingCoordinates(from parkingLots: [Row], address: [String]) {
        let geocoder = CLGeocoder()
        let dispatchGroup = DispatchGroup() // 한번에 UI 업데이트 하기 위해사용
  
        
        // 백그라운드 에서 작업하도록 함
        DispatchQueue.global(qos: .userInitiated).async {
        
            for (index, lot) in address.enumerated() { //요청 시간차
                dispatchGroup.enter()
                
//                print("주소 확인:", lot.ADDR)
//                let fullAddress = self.cleanAddress(from: lot.ADDR)
                print("@@@ ")
                print(address[0])
        
                // 지오코더 주소 변환이 왜 안되는건지...
                let fulladdress = "서울특별시 " + address[index]
                geocoder.geocodeAddressString(fulladdress) { placemarks, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("주소 변환 실패: \(error.localizedDescription)") // nil
                    }
                    
                    if placemarks?.last?.location == nil {
                        print("❗️지오코딩 실패 주소: \(fulladdress)")
                    }
    
                    guard let location = placemarks?.last?.location else {
                        print("위치 정보 없음: \(fulladdress)") // 경도 위도 못찾음
                        return
                    }
                    

//                    let annotation = ParkingAnnotation()
//                    annotation.coordinate = location.coordinate
//                    
//                    print("@@@ 여기 : ")
//                    print(annotation.coordinate)
//                    annotation.title = lot.PKLT_NM
//
//                    let charge = "기본요금: \(lround(lot.BSC_PRK_CRG))원"
//                    let availableCars = "가능 차량: \(Int(lot.TPKCT - lot.NOW_PRK_VHCL_CNT))대"
//                    annotation.subtitle = "\(charge) • \(availableCars)"
//                    annotation.parkingData = lot
//                    
//                    newParkingAnnotations.append(annotation)
                }
            }
            dispatchGroup.notify(queue: .main) {
                print("모든 주소 변환 완료")
                self.mapView.removeAnnotations(self.parkingAnnotations)
                self.parkingAnnotations = newParkingAnnotations
                self.mapView.addAnnotations(newParkingAnnotations)
                self.hideLoading()
            }
        }
        }
    }
    
    
    
    // 자치구 추출 함수
    func extractDistrict3(from address: String) -> String? {
        let pattern = #"([가-힣]+구)"#
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            if let match = regex.firstMatch(in: address, range: NSRange(address.startIndex..., in: address)),
               let range = Range(match.range, in: address) {
                return String(address[range])
            }
        } catch {
            print("정규식 에러: \(error.localizedDescription)")
        }
        return nil
    }
    
    
    
    extension UserLocationViewController: CLLocationManagerDelegate {
        // # MARK - 사용자의 접근권한 설정에 따른 좌표 설정
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            print("위치 업데이트 감지")
            manager.stopUpdatingLocation()
            
            if let location = locations.last {
                
                // # MARK - 사용자 좌표 업데이트
                userLati = location.coordinate.latitude
                userLon = location.coordinate.longitude
                print("사용자 위치: \(location.coordinate)")
                print("사용자 좌표 : ")
                print(" LATI : \(userLati)")
                print("LON : \(userLon)")
                updateMapToUserLocation()
//                searchParking(near: location.coordinate)
            }
        }
        
        // 위치정보 접근 권한 변경시
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            switch status{
            case .authorizedWhenInUse, .authorizedAlways:
                print("위치 권한 접근 ㅇㅋ")
                manager.startUpdatingLocation() // 위치 업데이트
                
            case .denied, .restricted:
                print("위치 권한 접근 거부됨")
                userLati = 37.5665
                userLon = 126.9780
                
            case .notDetermined:
                print("아직 권한 선택 안함 ")
                manager.requestWhenInUseAuthorization() // 권한 요청하기
            @unknown default:
                break
            }
        }
        
        // 원래 권한이 없는 경우: 기본 좌표로 지도를 초기화할 때
        //권한이 있는 경우: GPS로 받은 위치로 지도를 재설정할 때 출력해주는 함수인데....
        // 터치 좌표 찍어주기
        func updateMapToUserLocation() {
            let location = CLLocationCoordinate2D(latitude: userLati, longitude: userLon)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: true)
            
            DispatchQueue.main.async {
                // 기존 '현재 내위치' 핀 제거 : CustomAnnotaion 타입의 핀들 중에 title이 "현재 내 위치"인 것들만 제거
                self.mapView.annotations.forEach {
                    if let annotation = $0 as? CustomAnnotation, annotation.title == "현재 내 위치" {
                        self.mapView.removeAnnotation(annotation)
                    }
                }
                
                // 새로운 핀 추가
                let userLocationPin = CustomAnnotation(coordinate: location, title: "현재 내 위치")
                self.mapView.addAnnotation(userLocationPin)
            }
        }
        
        // 권한 거부하면 알람띄워주기
        func showLocationPermissionAlert() {
            let alert = UIAlertController(title: "위치 권한 필요",
                                          message: "나의 위치를 기반으로 주차장을 찾으려면 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default, handler: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            
            present(alert, animated: true)
        }
    
}

extension UserLocationViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // 유저 위치 그리는 부분
        if annotation is  MKUserLocation {
            return nil
        }
    
        if let customAnnotation = annotation as? CustomAnnotation{
            let identifier = "user"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
  
                // 크기 조절
                if let image = UIImage(named: "marker.png"){
                    let size = CGSize(width: 50, height: 50)
                    let render = UIGraphicsImageRenderer(size: size)
                    let resizedImage = render.image { _ in
                        image.draw(in: CGRect(origin: .zero, size: size))
                    }
                    annotationView?.image = resizedImage
                }
            }else{
                annotationView?.annotation = customAnnotation
            }
            
            return annotationView
        }
           
        // 주차장 핀 그리는 부분
        let identifier = "ParkingPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            // 주차장 마커 상세
            let infoButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = infoButton
            
            let emojiLabel = UILabel()
            emojiLabel.text = "🚘"
            emojiLabel.font = UIFont.systemFont(ofSize: 24)
            emojiLabel.textAlignment = .center
            
            let emojiContainer = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            emojiLabel.frame = emojiContainer.bounds
            emojiContainer.addSubview(emojiLabel)
            annotationView?.leftCalloutAccessoryView = emojiContainer
            
        }else {
            annotationView?.annotation = annotation
        }
        
        // 카드에 데이터 뿌리는 부분
        if let markerView = annotationView as? MKMarkerAnnotationView,
           let parkingAnnotation = annotation as? ParkingAnnotation,
           let data = parkingAnnotation.parkingData {

            let availableSpots = max(0, Int(data.TPKCT - data.NOW_PRK_VHCL_CNT))
            markerView.glyphText = "\(availableSpots)"

            if availableSpots <= 0 {
                markerView.markerTintColor = .gray
            } else if data.PAY_YN_NM == "무료" {
                markerView.markerTintColor = .systemMint
            } else {
                markerView.markerTintColor = .systemYellow
            }
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? ParkingAnnotation else {return}
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = sb.instantiateViewController(withIdentifier: "parkinginfo") as? ModalViewController {
            detailVC.parkingLot = annotation.parkingData
            detailVC.modalPresentationStyle = .pageSheet
            present(detailVC, animated: true, completion: nil)
        }
    }
}

// 유저의 위치 표시용 커스텀 마커
class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

// 마커 카드에 커스텀 데이터를 뿌리기 위한 타입캐스팅
class ParkingAnnotation: MKPointAnnotation {
    var parkingData: Row?
}


