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
      pubnubStore.publish(update: self.entry)
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
  let clientUUID: String = UUID().uuidString

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
      self?.displayMessage(
        "[MESSAGE: received]",
        messageText: "entry: \(event.payload["entry"] ?? "null"), update: \(event.payload["update"] ?? "null")"
      )
    }

    listener.didReceivePresence = { [weak self] event in
      let theText = "event uuid: \(event.metadata?["pn_uuid"] ?? "null"), channel: \(event.channel)"
        
      self?.displayMessage(
        "[PRESENCE: \(event.metadata?["pn_action"] ?? "null")]", messageText: theText
      )
    }

    listener.didReceiveSubscriptionChange = { [weak self] event in
      switch event {
        case .subscribed(let channels, _):
          self?.displayMessage("[SUBSCRIPTION CHANGED: new channels]", messageText: "channels added: \(channels[0].id)")
          self?.publish(update: "Harmless.")
        default: break
      }
    }

    listener.didReceiveStatus = { [weak self] event in
      switch event {
        case .success(let connection):
          self?.displayMessage("[STATUS: connection]", messageText: "state: \(connection)");
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

  func displayMessage(_ messageType: String, messageText: String) {
    self.messages.append(
      Message(
        messageType: messageType,
        messageText: messageText
      )
    )
  }

  func publish(update: String, _ anEntry: String = "Earth") {
    let entryUpdate = ["entry": anEntry, "update": update]

    pubnub.publish(channel: self.channel, message: entryUpdate) { [weak self] result in
      switch result {
        case let .success(response):
          self?.displayMessage(
            "[PUBLISH: sent]",
            messageText: "timetoken: \(response.timetoken.formattedDescription) (\(response.timetoken.description))");

        case let .failure(error):
          print("failed: \(error.localizedDescription)")
      }
    }
  }
}

// MARK:- Models
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
