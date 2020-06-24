////
////  ContentView.swift
////  pnquickstart
////
////  Created by pubnubcvconover on 4/16/20.
////  Copyright © 2020 PubNub. All rights reserved.
////
//
//import SwiftUI
//import PubNub
//
//struct Message: Identifiable {
//    var id = UUID()
//    var messageType: String
//    var messageText: String
//}
//
//let clientUUID: String = UUID().uuidString
//var pnconfig = PubNubConfiguration(publishKey: "demo-36", subscribeKey: "demo-36")
//var listener = SubscriptionListener(queue: .main)
//
//struct ContentView: View {
//    // i can't set the uuid - it give an error
//    // self.pnconfig.uuid = clientUUID
//    
//    var pubnub: PubNub! = PubNub(configuration: pnconfig)
//    let theChannel: String = "the_guide";
//    let theEntry: String = "Earth";
//    
//    @State var messages: [Message] = []
//    @State var entry = "Mostly Harmless."
//    
//    var body: some View {
//        VStack {
//            Spacer()
//            VStack {
//                TextField("", text: $entry)
//                    .frame(width: 300.0, height: 40)
//                    .border(Color.black)
//                Spacer()
//                Button(action: {
//                    self.submitUpdate(self.theEntry, anUpdate: self.entry)
//                    self.entry = ""
//                }) {
//                    Text("SUBMIT UPDATE TO THE GUIDE")
//                        .padding()
//                        .foregroundColor(Color.white)
//                        .background(Color.red)
//                        .cornerRadius(40)
//                        .frame(width: 300.0)
//                }
//                Spacer()
//                List(messages) { message in
//                    VStack(alignment: .leading) {
//                        Text(message.messageType)
//                        Text(message.messageText)
//                    }
//                }
//            }
//            Spacer()
//        }.onAppear {
//            listener.didReceiveMessage = { event in
//                let payload = event.payload
//                self.displayMessage("[MESSAGE: received]", messageText: "entry: \(payload["entry"] ?? "null"), update: \(payload["update"] ?? "null")")
//            }
//            
//            listener.didReceiveSubscriptionChange = { event in
//                switch event {
//                    case .subscribed(let channels, _):
//                        self.displayMessage("[SUBSCRIPTION CHANGED: new channels]", messageText: "channels added: \(channels[0].id)")
//                        self.submitUpdate(self.theEntry, anUpdate: "Harmless.");
//                        break
//                    
//                    default: break
//                }
//            }
//            
//            listener.didReceiveStatus = { event in
//                switch event {
//                    case .success(let connection):
//                        self.displayMessage("[STATUS: connection]",
//                                            messageText: "state: \(connection)");
//                    
//                    case .failure(let error):
//                        print("Status Error: \(error.localizedDescription)")
//                }
//            }
//            
//            listener.didReceivePresence = { event in
//                self.displayMessage("[PRESENCE: \(event.metadata!["action"] ?? "no action?")]",
//                    messageText: "uuid: \(event.metadata!["uuid"] ?? "no uuid?"), channel:  \(event.channel)")
//            }
//            
//            self.pubnub.add(listener)
//            self.pubnub.subscribe(to: [self.theChannel], withPresence: true)
//        }
//    }
//
//    func submitUpdate(_ anEntry: String, anUpdate: String) {
//        let entryUpdate = ["entry": anEntry, "update": anUpdate]
//        
//        pubnub.publish(channel: self.theChannel, message: entryUpdate)
//        { result in
//          switch result {
//            case let .success(response):
//                self.displayMessage(
//                    "[PUBLISH: sent]", messageText: "timetoken: " + String(response.timetoken));
//
//            case let .failure(error):
//              print("failed: \(error.localizedDescription)")
//          }
//        }
//    }
//
//    func displayMessage(_ messageType: String, messageText: String) {
//        self.messages.insert(
//        Message(
//            messageType: messageType,
//            messageText: messageText
//        ), at: 0)
//    }
//}
//
//
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
