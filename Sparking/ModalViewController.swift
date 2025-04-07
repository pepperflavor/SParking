//
//  ModalViewController.swift
//  Sparking
//
//  Created by 김나연 on 4/4/25.
//

import UIKit

class ModalViewController: UIViewController {
    @IBOutlet weak var pkLotNmLabel: UILabel!
    @IBOutlet weak var pkLotAddrLabel: UILabel!
    @IBOutlet weak var bscPrkFeeLabel: UILabel!
    @IBOutlet weak var addPrkFeeLabel: UILabel!
    @IBOutlet weak var phoNumLabel: UILabel!
    
    var parkingLot: Row?
    var listVC: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        guard let parkingLot else { return }
        
        pkLotNmLabel.text = "🅿️ \(parkingLot.PKLT_NM)"
        pkLotAddrLabel.text = "📇 서울특별시 \(parkingLot.ADDR)"
        phoNumLabel.text = "☎️ \(parkingLot.TELNO ?? "")"
        bscPrkFeeLabel.text = "💲 기본 요금: \(lroundl(parkingLot.BSC_PRK_HR))분당 \(lroundl(parkingLot.BSC_PRK_CRG ))원"
        addPrkFeeLabel.text = "💲 추가 요금: \(lroundl(parkingLot.ADD_PRK_HR))분당 \(lroundl(parkingLot.ADD_PRK_CRG))원"
    }
    
    @IBAction func actNavigate(_ sender: Any) {
        self.dismiss(animated: true) {
            guard let navigateVC = self.storyboard?.instantiateViewController(withIdentifier: "navigation") as? NavigateViewController else { return }
            navigateVC.parkingLot = self.parkingLot
            
            self.listVC?.navigationController?.pushViewController(navigateVC, animated: true)
        }
    }
}
