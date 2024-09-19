// ContentView.swift
import SwiftUI

struct ContentView: View {
    let webFramework: TinyWebFrameworkProtocol = TinyWebFramework()
    
    var body: some View {
        VStack {
            Text("Tiny Swift Web Server")
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                startWebApp(with: webFramework)
            }) {
                Text("Start Server")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                webFramework.stopServer()
            }) {
                Text("Stop Server")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
