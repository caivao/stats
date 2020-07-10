//
//  Settings.swift
//  CPU
//
//  Created by Serhiy Mytrovtsiy on 18/04/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import StatsKit
import ModuleKit

internal class Settings: NSView, Settings_v {
    private var hyperthreadState: Bool = false
    private var updateIntervalValue: String = "1"
    private let listOfUpdateIntervals: [String] = ["1", "2", "3", "5", "10", "15", "30"]
    
    private let title: String
    private let store: UnsafePointer<Store>
    
    public var callback: (() -> Void) = {}
    public var setInterval: ((_ value: Double) -> Void) = {_ in }
    
    public init(_ title: String, store: UnsafePointer<Store>) {
        self.title = title
        self.store = store
        self.hyperthreadState = store.pointee.bool(key: "\(self.title)_hyperhreading", defaultValue: self.hyperthreadState)
        self.updateIntervalValue = store.pointee.string(key: "\(self.title)_updateInterval", defaultValue: self.updateIntervalValue)
        
        super.init(frame: CGRect(
            x: Constants.Settings.margin,
            y: Constants.Settings.margin,
            width: Constants.Settings.width - (Constants.Settings.margin*2),
            height: 0
        ))
        
        self.wantsLayer = true
        self.canDrawConcurrently = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func load(widget: widget_t) {
        self.subviews.forEach{ $0.removeFromSuperview() }
        
        let rowHeight: CGFloat = 30
        let num: CGFloat = widget == .barChart ? 1 : 0
        
        self.addSubview(SelectTitleRow(
            frame: NSRect(x: Constants.Settings.margin, y: Constants.Settings.margin + (rowHeight + Constants.Settings.margin) * num, width: self.frame.width - (Constants.Settings.margin*2), height: rowHeight),
            title: "Update interval",
            action: #selector(changeUpdateInterval),
            items: self.listOfUpdateIntervals.map{ "\($0) sec" },
            selected: "\(self.updateIntervalValue) sec"
        ))
        
        if widget == .barChart {
            self.addSubview(ToggleTitleRow(
                frame: NSRect(x: Constants.Settings.margin, y: Constants.Settings.margin + (rowHeight + Constants.Settings.margin) * 0, width: self.frame.width - (Constants.Settings.margin*2), height: rowHeight),
                title: "Show hyper-threading cores",
                action: #selector(toggleMultithreading),
                state: self.hyperthreadState
            ))
        }
        
        self.setFrameSize(NSSize(width: self.frame.width, height: (rowHeight*(num+1)) + (Constants.Settings.margin*(2+num))))
    }
    
    @objc private func changeUpdateInterval(_ sender: NSMenuItem) {
        let newUpdateInterval = sender.title.replacingOccurrences(of: " sec", with: "")
        self.updateIntervalValue = newUpdateInterval
        store.pointee.set(key: "\(self.title)_updateInterval", value: self.updateIntervalValue)
        
        if let value = Double(self.updateIntervalValue) {
            self.setInterval(value)
        }
    }
    
    @objc func toggleMultithreading(_ sender: NSControl) {
        var state: NSControl.StateValue? = nil
        if #available(OSX 10.15, *) {
            state = sender is NSSwitch ? (sender as! NSSwitch).state: nil
        } else {
            state = sender is NSButton ? (sender as! NSButton).state: nil
        }
        
        self.hyperthreadState = state! == .on ? true : false
        self.store.pointee.set(key: "\(self.title)_hyperhreading", value: self.hyperthreadState)
        self.callback()
    }
}
