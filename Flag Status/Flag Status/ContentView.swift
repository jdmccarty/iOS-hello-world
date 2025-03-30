//
//  ContentView.swift
//  Flag Status
//
//  Created by Justin McCarty on 3/28/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Remove the Text view for "Flag Status"
            // Text("Flag Status")
            //     .font(.largeTitle)
            //     .padding(.top)

            WebView()
                .padding(.horizontal)
                .padding(.bottom)
        }
        // NO .ignoresSafeArea
    }
}

#Preview {
    ContentView()
}
