//
//  ParkingModel.swift
//  Sparking
//
//  Created by 김나연 on 4/3/25.
//
import Foundation

struct ParkingLotRoot: Codable{
    let GetParkingInfo: GetParkingInfo
}

struct GetParkingInfo: Codable {
    let row: [Row]
}

struct Row: Codable {
    var BSC_PRK_CRG: Double
    var BSC_PRK_HR: Double
    let ADD_PRK_CRG: Double        //추가 단위 요금
    let ADD_PRK_HR: Double         //추가 단위 시간(분)
    let TPKCT: Double            //총 주차면
    let OPER_SE_NM: String      //운영구분명(시간제)
    let ADDR: String          //주소
    let NOW_PRK_VHCL_CNT: Double    //현재 주차 차량 수
    let PAY_YN_NM: String       //유무료구분명(유료/무료)
    let PAY_YN: String
    let PKLT_NM: String        //주차장 이름
    let PRK_STTS_NM: String     //주차현황 정보 제공 여부
    let TELNO: String?        //전화번호 (옵셔널)
    
//    enum CodingKeys: String, CodingKey {
//        case addCharge = "ADD_PRK_CRG"
//        case addHour = "ADD_PRK_HR"
//        case okPark = "TPKCT"
//        case operSeNm = "OPER_SE_NM"
//        case address = "ADDR"
//        case nowPark = "NOW_PRK_VHCL_CNT"
//        case charge = "PAY_YN"
//        case name = "PKLT_NM"
//        case prkSttsNm = "PRK_STTS_NM"
//        case phoneNum = "TELNO"
//    }
}
