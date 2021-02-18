//
//  ContentView.swift
//  pnquickstart
//
//  Created by pubnubcvconover on 4/16/20.
//  Copyright © 2020 PubNub. All rights reserved.
//
import SwiftUI
import PubNub

struct ContentView: View {
  
  @ObservedObject var pubnubStore: PubNubStore
  @State var entry = "Mostly Harmless."
  
  var body: some View {
    VStack {
      Spacer()
      
      TextField("", text: $entry, onCommit: submitUpdate)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .frame(width: 300.0, height: 40)
      
      Spacer()
      
      Button(action: submitUpdate) {
        Text("SUBMIT UPDATE TO THE GUIDE")
          .padding()
          .foregroundColor(Color.white)
          .background(entry.isEmpty ? Color.secondary : Color.red)
          .cornerRadius(40)
      }
      .disabled(entry.isEmpty)
      .frame(width: 300.0)
      
      Spacer()
      
      List {
        ForEach(pubnubStore.messages.reversed()) { message in
          VStack(alignment: .leading) {
            Text(message.messageType)
            Text(message.messageText)
          }
        }
      }
      
      Spacer()
    }
  }
  
  func submitUpdate() {
    if !self.entry.isEmpty {
      pubnubStore.publish(update: EntryUpdate(update: self.entry))
      self.entry = ""
    }
    
    // Hides keyboard
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

// MARK:- View Stores
class PubNubStore: ObservableObject {
  @Published var messages: [Message] = []
  
  var pubnub: PubNub
  let channel: String = "the_guide"
  let clientUUID: String = "ReplaceWithYourClientIdentifier"
  
  init() {
    var pnconfig = PubNubConfiguration(publishKey: "myPublishKey", subscribeKey: "mySubscribeKey")
    pnconfig.uuid = clientUUID
    
    self.pubnub = PubNub(configuration: pnconfig)
    
    startListening()
    subscribe(to: self.channel)
  }
  
  lazy var listener: SubscriptionListener? = {
    let listener = SubscriptionListener()
    
    listener.didReceiveMessage = { [weak self] event in
      if let entry = try? event.payload.codableValue.decode(EntryUpdate.self) {
        
        self?.display(
          Message(messageType: "[MESSAGE: received]", messageText: "entry: \(entry.entry), update: \(entry.update)")
        )
      }
    }
    
    listener.didReceivePresence = { [weak self] event in
      let userChannelDescription = "event uuid: \(event.metadata?.codableValue["pn_uuid"] ?? "null"), channel: \(event.channel)"
      
      self?.display(
        Message(messageType: "[PRESENCE: \(event.metadata?.codableValue["pn_action"] ?? "null")]", messageText: userChannelDescription)
      )
    }
    
    listener.didReceiveSubscriptionChange = { [weak self] event in
      switch event {
      case .subscribed(let channels, _):
        self?.display(Message(messageType: "[SUBSCRIPTION CHANGED: new channels]", messageText: "channels added: \(channels[0].id)"))
        self?.publish(update: EntryUpdate(update: "Harmless."))
      default: break
      }
    }
    
    listener.didReceiveStatus = { [weak self] event in
      switch event {
      case .success(let connection):
        self?.display(Message(messageType: "[STATUS: connection]", messageText: "state: \(connection)"))
      case .failure(let error):
        print("Status Error: \(error.localizedDescription)")
      }
    }
    
    return listener
  }()
  
  func startListening() {
    if let listener = listener {
      pubnub.add(listener)
    }
  }
  
  func subscribe(to channel: String) {
    pubnub.subscribe(to: [channel], withPresence: true)
  }
  
  func display(_ message: Message) {
    self.messages.append(message)
  }
  
  func publish(update entryUpdate: EntryUpdate) {
    pubnub.publish(channel: self.channel, message: entryUpdate) { [weak self] result in
      switch result {
      case let .success(timetoken):
        self?.display(
          Message(messageType: "[PUBLISH: sent]", messageText: "timetoken: \(timetoken.formattedDescription) (\(timetoken.description))")
        )
        
      case let .failure(error):
        print("failed: \(error.localizedDescription)")
      }
    }
  }
}

// MARK:- Models

struct EntryUpdate: JSONCodable {
  var update: String
  var entry: String
  
  init(update: String, entry: String = "Earth") {
    self.update = update
    self.entry = entry
  }
}

struct Message: Identifiable {
  var id = UUID()
  var messageType: String
  var messageText: String
}

// MARK:- Extension Helpers
extension DateFormatter {
  static let defaultTimetoken: DateFormatter = {
    var formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .short
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

extension Timetoken {
  var formattedDescription: String {
    return DateFormatter.defaultTimetoken.string(from: timetokenDate)
  }
}

// MARK:- View Preview
struct ContentView_Previews: PreviewProvider {
  static let store = PubNubStore()
  
  static var previews: some View {
    ContentView(pubnubStore: store)
  }
}
