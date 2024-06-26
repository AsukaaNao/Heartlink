//
//  ListView.swift
//  WatchHeartlink Watch App
//
//  Created by Shelfinna on 01/06/24.
//

import SwiftUI

struct ListView: View {
    let event: Event
    
    var body: some View {
        HStack(alignment: .top) { // Align the content to the top
            VStack(alignment: .leading) {
                HStack(alignment: .top) { // Align the content to the top
                    Text(event.eventType.icon)
                        .font(.system(size: 40))
                    VStack(alignment: .leading){
                        Text(event.note)
//                            .font(.caption)
                            .font(.system(size: 14))
                        Text(event.date.formatted(.dateTime.hour().minute()))
//                            .font(.footnote)
                            .font(.system(size: 12))
                    }
                }
            }
            Spacer()
        }
        .padding(7)
        .background(Color.purple)
        .listRowInsets(EdgeInsets())
        .cornerRadius(10)

    }
}



struct ListView_Previews: PreviewProvider {
    static let event = Event(eventType: .date, date: Date(), note: "Let's party")
    static var previews: some View {
        ListView(event: event)
    }
}
