//
//  ViewController.swift
//  LFLocationDemo
//
//  Created by LeonDeng on 2019/8/26.
//  Copyright © 2019 LeonDeng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LFLocation.currentLocationDescription(timeOut: 10) { (state, country, province, city, area) in
            switch state {
            case .success:
                print("国家:\(String(describing: country)) 省份:\(String(describing: province)) 城市:\(String(describing: city)), 区域:\(String(describing: area))")
                break
            case .timeOut:
                break
            case .unauth:
                break
            case .noService:
                break
            case .error(let error):
                print("Error: \(error?.localizedDescription ?? "no error")")
                break
            }
        }
    }
}

