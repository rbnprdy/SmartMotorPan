//
//  ContentView.swift
//  SmartMotorPan
//
//  Created by Ruben Purdy on 1/1/20.
//  Copyright © 2020 rbnprdy. All rights reserved.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @State private var distance: String = ""
    @State private var waitTime: String = ""
    @State private var acceleration: String = "100"
    @State private var velocity: String = "100000"
    @State private var KP: String = "220"
    @State private var KD: String = "200"
    @State private var KI: String = "110"
    @State private var KL: String = "1100"
    @State private var sleepSwitch: String = "1000000"
    @State private var sleepMove: String = "1000000"
    
    @State private var intAlertPresented = false
    @State private var beginAlertPresented = false
    @State private var continueRunning = true
    @State private var showAlert = false
    
    let fontSize = Font.body
    
    var body: some View {
        VStack(alignment: .center) {
            Group {
                Text("SmartMotor Controller")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.vertical)
                    .foregroundColor(.blue)
                Text("Enter Distance:")
                    .font(fontSize)
                TextField("Distance", text: self.$distance)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
                Text("Enter Wait Time:")
                    .font(fontSize)
                TextField("Wait Time", text: self.$waitTime)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
                Text("Enter Acceleration:")
                    .font(fontSize)
                TextField("Acceleration", text: self.$acceleration)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
            }
            Group {
                Text("Enter Velocity:")
                    .font(fontSize)
                TextField("Velocity", text: self.$velocity)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
                Text("Enter KP:")
                    .font(fontSize)
                TextField("KP", text: self.$KP)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
                Text("Enter KD:")
                    .font(fontSize)
                TextField("KD", text: self.$KD)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
                Text("Enter KI:")
                    .font(fontSize)
                TextField("KI", text: self.$KI)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
                Text("Enter KL:")
                    .font(fontSize)
                TextField("KL", text: self.$KL)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
            }
            Group {
                Text("Enter Sleep time for switching UA/UB (us)")
                    .font(fontSize)
                TextField("Sleep switch", text: self.$sleepSwitch)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
                Text("Enter Sleep time waiting after switching to move (us)")
                    .font(fontSize)
                TextField("Sleep move", text: self.$sleepMove)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numbersAndPunctuation)
                    .font(fontSize)
                
            }
            Spacer()
            Button(action: {
                guard let distanceInt = Int(self.distance), let waitTimeInt = Int(self.waitTime), let accelerationInt = Int(self.acceleration), let velocityInt = Int(self.velocity), let KPInt = Int(self.KP), let KDInt = Int(self.KD), let KIInt = Int(self.KI), let KLInt = Int(self.KL), let sleepSwitchInt = Int(self.sleepSwitch), let sleepMoveInt = Int(self.sleepMove) else {
                    self.intAlertPresented = true
                    self.showAlert = true
                    return
                }
                self.continueRunning = true
                self.beginAlertPresented = true
                self.showAlert = true
                self.sendCommands(distance: distanceInt, waitTime: waitTimeInt, acceleration: accelerationInt, velocity: velocityInt, KP: KPInt, KD: KDInt, KI: KIInt, KL: KLInt, sleepSwitch: sleepSwitchInt, sleepMove: sleepMoveInt)
            }) {
            Text("GO")
                .font(.largeTitle)
            }
        }
        .alert(isPresented: self.$showAlert) {
            if self.intAlertPresented {
                return Alert(title: Text("Error"), message: Text("All values must be integers value"), dismissButton: .default(Text("Okay"), action: {
                    self.intAlertPresented = false
                    self.showAlert = false
                }))
            } else if self.beginAlertPresented {
                return Alert(title: Text("Running"), message: Text("Running the motor with a distance of \(self.distance) and wait time of \(self.waitTime)"), dismissButton: .cancel({
                    self.continueRunning = false
                    self.beginAlertPresented = false
                    self.showAlert = false
                }))
            } else {
                return Alert(title: Text("Unknown Error"))
            }
        }
        .onAppear(perform: startBluetooth)
    }
    
    func sendCommands(distance: Int, waitTime: Int, acceleration: Int, velocity: Int, KP: Int, KD: Int, KI: Int, KL: Int, sleepSwitch: Int, sleepMove: Int) {
        
        BluetoothController.Singleton.startup(KP: KP, KD: KD, KI: KI, KL: KL, Acceleration: acceleration, Velocity: velocity)
        
        DispatchQueue.global(qos: .background).async {
            while self.continueRunning {
                BluetoothController.Singleton.move(distance: distance, sleepSwitch: sleepSwitch, sleepMove: sleepMove)
                sleep(UInt32(waitTime))
            }
        }
    }
    
    func startBluetooth() {
        BluetoothController.Singleton.startCentralManager()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
