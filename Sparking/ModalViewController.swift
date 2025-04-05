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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        pkLotNmLabel.text = parkingLot?.PKLT_NM
        pkLotAddrLabel.text = parkingLot?.ADDR
        phoNumLabel.text = parkingLot?.TELNO
        bscPrkFeeLabel.text = "기본 요금: \(lroundl(parkingLot?.BSC_PRK_HR ?? 0))분당 \(lroundl(parkingLot?.BSC_PRK_CRG ?? 0))원"
        addPrkFeeLabel.text = "추가 요금: \(lroundl(parkingLot?.ADD_PRK_HR ?? 0))분당 \(lroundl(parkingLot?.ADD_PRK_CRG ?? 0))원"
    }
    
    @IBAction func actNavigate(_ sender: Any) {
        
        
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        let targetVC = segue.destination as? NavigateViewController
        // Pass the selected object to the new view controller.
        targetVC?.parkingLot = parkingLot
    }


}
