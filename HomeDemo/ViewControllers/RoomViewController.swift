//
//  RoomViewController.swift
//  HomeDemo
//
//  Created by HeMengjie on 2017/10/26.
//  Copyright © 2017年 hmj. All rights reserved.
//

import UIKit
import HomeKit

class RoomViewController: UIViewController {
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var currentLab: UILabel!
    @IBOutlet weak var myCurrentTableView: UITableView!
    
    var myRoom: HMRoom!
    var myHome: HMHome!
    var arressBrowser: HMAccessoryBrowser!
    var arressoryCurren: HMAccessory!
    var readCharacter: HMCharacteristic!
    var writeCharacter: HMCharacteristic!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.arressBrowser.stopSearchingForNewAccessories()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
         Accessories封装了物理配件的状态，因此它不能被用户创建，也就是说我们不能去创建智能硬件对象，只能通过去搜寻它，然后添加。想要允许用户给家添加新的配件，我们可以使HMAccessoryBrowser对象在后台搜寻一个与home没有关联的配件，当它找到配件的时候，系统会调用委托方法来通知你的应用程序。
         */
        self.title = myRoom.name
        self.myTableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
        self.myCurrentTableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "myCell")
        
        self.arressBrowser = HMAccessoryBrowser.init()
        self.arressBrowser.delegate = self
    }
    @IBAction func getAllDevice(_ sender: Any) {
        print("开始搜索配件")
        self.arressBrowser.startSearchingForNewAccessories()
    }
    @IBAction func changeNameBtnClick(_ sender: UIButton) {
        if self.arressoryCurren != nil {
            self.arressoryCurren.updateName(("新\(self.arressoryCurren.name)"), completionHandler: { (error) in
                if error != nil {
                    print("更改名字失败")
                }else {
                    print("更改名字成功")
                    self.currentLab.text = self.arressoryCurren.name
                    for accessory in self.myRoom.accessories {
                        self.myAccessoryArr.append(accessory)
                    }
                    self.myCurrentTableView.reloadData()
                }
            })
        }
    }
    @IBAction func removeBtnClick(_ sender: UIButton) {
        if self.arressoryCurren != nil {
            self.myHome.removeAccessory(self.arressoryCurren, completionHandler: { (error) in
                if error != nil{
                    print("移除失败")
                }else{
                    self.currentLab.text = "为选中设备"
                    print("移除成功")
                    for accessory in self.myRoom.accessories {
                        self.myAccessoryArr.append(accessory)
                    }
                    self.myCurrentTableView.reloadData()
                }
            })
        }
    }
    @IBAction func openAccessoryBtnClick(_ sender: UIButton) {
        for i in 0..<self.arressoryCurren.services.count {
            let myService = self.arressoryCurren.services[i]
            print("服务的名字为\(myService.name)")
            for j in 0..<myService.characteristics.count {
                print("服务的特征为\(myService.characteristics[j].properties)")
                let myCharactWristics = myService.characteristics[j]
                if myCharactWristics.properties[0] == HMCharacteristicPropertyReadable {
                    self.readCharacter = myCharactWristics
                    self.readCharacter.enableNotification(true, completionHandler: { (error) in
                        //接受外设的通知
                    })
                }else {
                    self.writeCharacter = myCharactWristics
                    self.writeCharacter.enableNotification(true, completionHandler: { (error) in
                        if error != nil {
                            let myValue = self.writeCharacter.value as! Int
                            print("特征的状态\(myValue)")
                            if myValue == 0 {
                                self.writeCharacter.writeValue(1, completionHandler: { (error) in
                                    if error == nil {
                                        print("写入成功")
                                    }else{
                                        print("写入失败")
                                    }
                                })
                            }else {
                                self.writeCharacter.writeValue(0, completionHandler: { (error) in
                                    if error == nil {
                                        print("写入成功")
                                    }else{
                                        print("写入失败")
                                    }
                                })
                            }
                        }else {
                            print("读取特征失败")
                        }
                    })
                }
            }
        }
    }
    @IBAction func getAllMyAccessory(_ sender: UIButton) {
        for accessory in self.myRoom.accessories {
            self.myAccessoryArr.append(accessory)
        }
        self.myCurrentTableView.reloadData()
    }
    //lazy
    lazy var accessoryArr : [HMAccessory] = {
        return [HMAccessory]()
    }()
    lazy var myAccessoryArr : [HMAccessory] = {
       return [HMAccessory]()
    }()
    
}

extension RoomViewController: UITableViewDataSource, UITableViewDelegate, HMAccessoryBrowserDelegate, HMAccessoryDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 100 {
            return self.accessoryArr.count
        }
        return self.myAccessoryArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 100 {
            let myTableCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            myTableCell.textLabel?.text = self.accessoryArr[indexPath.row].name
            return myTableCell
        }else {
            let myTableCell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
            myTableCell.textLabel?.text = self.myAccessoryArr[indexPath.row].name
            return myTableCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 100 {
            let accessoryName = self.accessoryArr[indexPath.row]
            self.myHome.addAccessory(accessoryName, completionHandler: { (error) in
                if error == nil {
                    if accessoryName.room != self.myRoom {
                        self.myHome.assignAccessory(accessoryName, to: self.myRoom, completionHandler: { (error1) in
                            if error1 == nil {
                                print("已经将设备添加到了房间")
                            }else {
                                print("指定的设备添加失败")
                            }
                        })
                    }else {
                        print("该设备已经存在于房间")
                    }
                }else{
                    print("添加设备到家失败")
                }
            })
        }else {
            self.currentLab.text = self.myAccessoryArr[indexPath.row].name
            self.arressoryCurren = self.myAccessoryArr[indexPath.row]
            self.arressoryCurren.delegate = self
        }
    }
    
    
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        self.accessoryArr.append(accessory)
        self.myTableView.reloadData()
    }
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        print("硬件已经移除了")
    }
    
    func accessory(_ accessory: HMAccessory, didUpdateAssociatedServiceTypeFor service: HMService) {
        print("特征发生了改变")
    }
}
