//
//  ContentView.swift
//  BatteryLevelWidget
//
//  Created by Jason Cantor on 2/19/24.
//
import SwiftUI
import RealityKit
import RealityKitContent
import UIKit

class BatteryLevelViewModel: ObservableObject {
    @Published var batteryLevel: Float = UIDevice.current.batteryLevel
    @Published var batteryState: UIDevice.BatteryState = UIDevice.current.batteryState
    @Published var showBatteryPercentage: Bool = true

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        self.updateBatteryLevel() // Call to update the battery level initially
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func batteryLevelDidChange(_ notification: Notification) {
        self.updateBatteryLevel() // This is where you were seeing the error
    }
    
    @objc func batteryStateDidChange(_ notification: Notification) {
        self.batteryState = UIDevice.current.batteryState
    }
    
    func updateBatteryLevel() {
        // Ensure the battery monitoring is enabled
        UIDevice.current.isBatteryMonitoringEnabled = true
        // Update the battery level
        self.batteryLevel = UIDevice.current.batteryLevel
    }
}


struct BatteryIcon: View {
    var batteryLevel: Float // Value between 0.0 and 1.0
    var batteryState: UIDevice.BatteryState
    var showPercentage: Bool

    var body: some View {
        ZStack {
            // Main battery body
            RoundedRectangle(cornerRadius: 22.5, style: .continuous)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 280, height: 100)
            
            // Battery tip
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 20, height: 40)
                .offset(x: 140, y: 0)
            
            // Battery level representation
            RoundedRectangle(cornerRadius: 22.5, style: .continuous)
                .fill(determineFillColor())
                .frame(width: (280 - 4) * CGFloat(batteryLevel), height: 96)
                .offset(x: (280 - 4) * CGFloat(batteryLevel) / 2 - 140, y: 0)
            // Adjusted battery level text to include charging symbol if needed
            if showPercentage {
                if batteryState == .charging || batteryState == .full {
                    HStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("\(Int(batteryLevel * 100))%")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                } else {
                    Text("\(Int(batteryLevel * 100))%")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
                
        }
    }
    
    private func determineFillColor() -> Color {
        switch batteryState {
        case .charging, .full:
            return .green
        default:
            return batteryLevel > 0.2 ? Color.green : Color.red
        }
    }
}


struct ContentView: View {
    @StateObject private var viewModel = BatteryLevelViewModel()
    @State private var showSettings = false // State to toggle settings view

    var body: some View {
        VStack {
            Spacer()

            if showSettings {
                // Settings menu with close functionality
                SettingsMenuView(showSettings: $showSettings, viewModel: viewModel)
                    .transition(.asymmetric(insertion: .push(from: .top), removal: .push(from: .bottom)))
            } else {
                // BatteryIcon with TapGesture to toggle settings view
                BatteryIcon(batteryLevel: viewModel.batteryLevel, batteryState: viewModel.batteryState, showPercentage: viewModel.showBatteryPercentage)
                    .frame(width: 300, height: 100)
                    .padding()
                    .onTapGesture {
                        withAnimation {
                            self.showSettings.toggle()
                        }
                    }
                    .rotation3DEffect(.degrees(showSettings ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .animation(.easeInOut, value: showSettings)
            }

            Spacer()
        }
        .padding()
    }
}

struct SettingsMenuView: View {
    @Binding var showSettings: Bool
    @ObservedObject var viewModel: BatteryLevelViewModel // Use ObservedObject here

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        self.showSettings = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundColor(.black)
                }
                .padding()
                .accessibilityLabel("Close Settings")
            }

            Spacer()

            Toggle(isOn: $viewModel.showBatteryPercentage) { // Bind to the viewModel's property
                Text("Show Battery Percentage")
            }
            .padding()

            Text("App Version: 1.1")
                .padding()

            Spacer()
        }
        .frame(width: 300, height: 200)
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(20)
        .padding(.top, 50)
    }
}


// Keep the preview as is
#Preview(windowStyle: .automatic) {
    ContentView()
}
