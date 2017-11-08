//
//  ViewController.swift
//  HomeDemo
//
//  Created by HeMengjie on 2017/10/26.
//  Copyright © 2017年 hmj. All rights reserved.
//

import UIKit
import HomeKit

class ViewController: UIViewController {

    @IBOutlet weak var MyHomeNameLab: UILabel!
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    var homeManagerTool: HomeKitTool!
    var currentHome: HMHome!
    //Getter
    lazy var homeArr : [HMHome] = {
        return [HMHome]()
    }()
    lazy var roomArr : [HMRoom] = {
        return [HMRoom]()
    }()
    //
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initHome()
    }
    func initHome() {
        self.title = "我家"
        NotificationCenter.default.addObserver(self, selector: #selector(getHomesNotify), name: NSNotification.Name(rawValue: "getName"), object: nil)
        myCollectionView.register(UINib.init(nibName: "RomeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        self.homeManagerTool = HomeKitTool()
        self.homeManagerTool.initHomeManager()
        self.myCollectionView.delegate = self
        self.myCollectionView.dataSource = self
    }
    //收到添加房间更新的通知方法
    @objc func getHomesNotify() {
        self.currentHome = self.homeManagerTool.homeManager.primaryHome
        self.MyHomeNameLab.text = "\(self.currentHome.name)primary"
        //获取房间
        self.getRoomArr(home: self.currentHome)
    }
    //获取房间
    func getRoomArr(home: HMHome) {
        if home.rooms.count != 0 {
            self.roomArr = home.rooms
            for i in 0..<self.roomArr.count {
                let room = self.roomArr[i]
                print(room.name)
            }
        }else {
            self.roomArr = home.rooms
        }
        self.myCollectionView.reloadData()
    }

    @IBAction func addHomeBtnClick(_ sender: Any) {
        let alertCon = UIAlertController.init(title: "请输入新的home的名字", message: "请确保这个名字的唯一性", preferredStyle: UIAlertControllerStyle(rawValue: 1)!)
        alertCon.addTextField { (text) in
            text.placeholder = "请输入新家的名字"
        }
        let action = UIAlertAction.init(title: "取消", style: .cancel) { (alter) in
            
        }
        let actionOk = UIAlertAction.init(title: "确定", style: .default) { (alter) in
            let nameString = alertCon.textFields?.first?.text
            self.homeManagerTool.addHome(homeName: nameString!)
        }
        alertCon.addAction(action)
        alertCon.addAction(actionOk)
        self.present(alertCon, animated: true, completion: nil)
    }
    @IBAction func featchHomeBtnClick(_ sender: UIButton) {
        if homeManagerTool.homeManager.homes.count != 0 {
            self.homeArr = self.homeManagerTool.homeManager.homes
            let homeList = UIAlertController.init(title: "", message: "我的所有home", preferredStyle: .actionSheet)
            for i in 0..<self.homeArr.count {
                let home = self.homeArr[i]
                var myName = home.name
                if home.isPrimary {
                    myName = "\(myName)primary"
                }
                let action = UIAlertAction.init(title: myName, style: .default, handler: { (action) in
                    self.currentHome = home
                    self.MyHomeNameLab.text = myName
                    //更新room数据
                    self.getRoomArr(home: self.currentHome)
                    
                })
                homeList.addAction(action)
            }
            let disMiss =   UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                
            })
            homeList.addAction(disMiss)
            self.present(homeList, animated: true, completion: nil)
        }
    }
    @IBAction func removeHomeBtnClick(_ sender: UIButton) {
        if self.currentHome != nil {
            self.homeManagerTool.removeHome(homeName: self.currentHome)
            self.getHomesNotify()
        }
    }
}

extension ViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.roomArr.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let roomCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RomeCollectionViewCell
        if indexPath.row < self.roomArr.count {
            roomCell.myRoomName.text = self.roomArr[indexPath.row].name
        }else {
            roomCell.myRoomName.text = "+"
        }
        return roomCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < self.roomArr.count {
            //跳转到对应的room中
            let viewRoomVC = RoomViewController()
            let room = self.roomArr[indexPath.row]
            viewRoomVC.myHome = self.currentHome
            viewRoomVC.myRoom = room
            self.navigationController?.pushViewController(viewRoomVC, animated: true)
        }else {
            let alertVC = UIAlertController.init(title: "添加房间", message: "名字具有唯一性", preferredStyle: .alert)
            alertVC.addTextField(configurationHandler: { (text) in
                text.placeholder = "请输入房间名字"
            })
            let action1 = UIAlertAction.init(title: "确定", style: .default, handler: { (alter) in
                let roomNewName = alertVC.textFields?.first?.text
                self.currentHome.addRoom(withName: roomNewName!, completionHandler: { (home, error) in
                    if error == nil{
                        self.getRoomArr(home: self.currentHome)
                    }
                })
            })
            let action2 = UIAlertAction.init(title: "取消", style: .cancel, handler: { (alter) in
                
            })
            alertVC.addAction(action1)
            alertVC.addAction(action2)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
}
