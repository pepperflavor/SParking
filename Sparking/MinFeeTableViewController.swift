//
//  MinFeeTableViewController.swift
//  Sparking
//
//  Created by 김나연 on 4/3/25.
//

import UIKit

class MinFeeTableViewController: UITableViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    
    let apiKey = "4965454f67736b6435354d516f646a"
    var sortedParkingLots: [Row]?
    var bscPrkCrg: Double = 0.0
    var bscPrkHr: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        searchBar.delegate = self
        searchBar.placeholder = "주차장을 검색할 ~구를 입력하세요"
    }
    
    // query 이용해서 서치
    func searchWithQuery(_ query: String?) {
        guard let query, !query.isEmpty else {
            print("검색어가 없습니다.")
            return
        }
        guard let endPt = "http://openapi.seoul.go.kr:8088/\(apiKey)/json/GetParkingInfo/1/100/\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        guard let url = URL(string: endPt) else { return }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data else {
                print("데이터 없음")
                return
            }
            
            do {
                // JSON 디코딩
                let root = try JSONDecoder().decode(ParkingLotRoot.self, from: data)
                let getParkingInfo = root.GetParkingInfo
                let row = getParkingInfo.row
                print(getParkingInfo)
                
                // 데이터가 있을 경우
                guard !getParkingInfo.row.isEmpty else {
                    print("주차장 정보가 없습니다.")
                    return
                }
                
                // 주차장 정보 가져오기
                for parking in getParkingInfo.row {
                    print("주차장 이름: \(parking.PKLT_NM)")
                    print("주소: \(parking.ADDR)")
                    print("유료/무료: \(parking.PAY_YN_NM)")
                    print("추가 단위 요금: \(parking.ADD_PRK_CRG)원")
                    print("총 주차 면수: \(parking.TPKCT)")
                    print("현재 주차 차량 수: \(parking.NOW_PRK_VHCL_CNT)")
                    print("전화번호: \(parking.TELNO ?? "")")
                    print("-------------------")
                }
                
                self.sortedParkingLots = row.sorted { $0.computedFee < $1.computedFee }
                
            } catch {
                print("JSON 디코딩 실패: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }.resume()
    }
    
    // 입력한 주소에서 자치구만 따옴
    func extractDistrict(from address: String) -> String? {
        let pattern = #"([가-힣]+구)"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            if let match = regex.firstMatch(in: address, range: NSRange(address.startIndex..., in: address)) {
                if let range = Range(match.range, in: address) {
                    return String(address[range])
                }
            }
        } catch {
            print("정규식 에러: \(error.localizedDescription)")
        }
        return nil
    }
    
    func showModalVC() {
        let vc = ModalViewController()
        
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        
        self.present(vc, animated: true)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sortedParkingLots?.count ?? 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MinFee", for: indexPath)
        
        // Configure the cell...
        
        guard let sortedParkingLots else { return cell }
        let parkingLot:Row = sortedParkingLots[indexPath.row]
        
        let feeImageView = cell.viewWithTag(1) as? UIImageView
        let parkingLotNm = cell.viewWithTag(2) as? UILabel
        let parkingLotFee = cell.viewWithTag(3) as? UILabel
        let canParkingCnt = cell.viewWithTag(4) as? UILabel
        
        var canPkCnt = lroundl(parkingLot.TPKCT - parkingLot.NOW_PRK_VHCL_CNT)
        
        if canPkCnt < 0 {
            canPkCnt = 0
        }
        
        if parkingLot.PRK_STTS_NM == "현재~20분이내 연계데이터 존재(현재 주차대수 표현)" {
            if parkingLot.PAY_YN_NM == "무료" {
                feeImageView?.image = UIImage(named: "free")
                parkingLotNm?.text = parkingLot.PKLT_NM
                parkingLotFee?.text = "무료 이용 가능"
                canParkingCnt?.text = String(canPkCnt)
            } else if parkingLot.PAY_YN_NM == "유료" {
                feeImageView?.image = UIImage(named: "paid")
                parkingLotNm?.text = parkingLot.PKLT_NM
                parkingLotFee?.text = "기본 요금(1시간 기준): \(lroundl(parkingLot.computedFee))원"
                canParkingCnt?.text = String(canPkCnt)
            }
        } else if parkingLot.PRK_STTS_NM == "미연계중" {
            feeImageView?.image = UIImage(named: "unlinked")
            parkingLotNm?.text = parkingLot.PKLT_NM
            parkingLotFee?.text = "주차 현황 미제공"
            canParkingCnt?.text = ""
        }
        
        print(parkingLot.BSC_PRK_HR)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sortedParkingLots else { return }
        let parkingLot = sortedParkingLots[indexPath.row]
        guard  let targetVC = storyboard?.instantiateViewController(withIdentifier: "parkinginfo") as? ModalViewController else { return }
        
        
        targetVC.parkingLot = parkingLot
        if let sheetPresentationController = targetVC.sheetPresentationController {
             sheetPresentationController.detents = [.medium(), .large()]
             sheetPresentationController.prefersGrabberVisible = true
         }
        present(targetVC, animated: true)
    }
    
}

extension MinFeeTableViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // 테스트 코드
        let address1 = "구로구 구로동"
        let address2 = "영등포구 소래동"
        
        print(extractDistrict(from: address1) ?? "구 없음") // 구로구
        print(extractDistrict(from: address2) ?? "구 없음") // 영등포구
        
        searchWithQuery(extractDistrict(from: searchBar.text ?? ""))
        searchBar.resignFirstResponder()
    }
}

extension Row {
    var computedFee: Double {
        var fee = BSC_PRK_CRG
        switch BSC_PRK_HR {
        case 1:   fee *= 60
        case 5:   fee *= 12
        case 30:  fee *= 2
        case 120: fee /= 2
        case 540: fee /= 9
        default:  break
        }
        return fee
    }
}

