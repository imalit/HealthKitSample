//
//  ContentView.swift
//  HKSample
//
//  Created by Isiah Marie Ramos Malit on 2022-10-04.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    
    let viewModel = ViewModel()
    let timer = Timer.publish(
        every: 60, //currently 60 sec. change to 15 min.
        tolerance: nil,
        on: .main,
        in: .common,
        options: nil
    ).autoconnect()
    
    var body: some View {
        if HKHealthStore.isHealthDataAvailable() {
            Text("Hello, Health Kit!")
                .padding()
                .onReceive(timer, perform: { _ in
                    viewModel.syncDisplay()
                })
                .onAppear {
                    viewModel.requestPermissions()
                }
        } else {
            Text("Hello, World!")
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
