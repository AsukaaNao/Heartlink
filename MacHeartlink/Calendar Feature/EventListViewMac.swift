//
//  EventListViewMac.swift
//  MacHeartlink
//
//  Created by Shelfinna on 30/05/24.
//

import SwiftUI

struct EventListViewMac: View {
    @EnvironmentObject var myEvents: EventStore
    @State private var formType: EventFormType?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("All Events")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    ForEach(myEvents.events.sorted {$0.date < $1.date }) { event in
                        ListViewRowMac(event: event, formType: $formType)
                            .swipeActions {
                                Button(role: .destructive) {
                                    myEvents.delete(event)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        Divider()
                            .padding(.horizontal)
                    }
                }
                .padding()
                .navigationTitle("Calendar Events")
                .sheet(item: $formType) { $0 }
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            formType = .new
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.medium)
                        }
                    }
                }
                .background(Color.white) // Set the background color of the ScrollView
            }
            .background(Color.white) // Set the background color of the VStack inside the ScrollView
        }
    }
}

struct EventListViewMac_Previews: PreviewProvider {
    static var previews: some View {
        EventListViewMac()
            .environmentObject(EventStore(preview: true))
    }
}



