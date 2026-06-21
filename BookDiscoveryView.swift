//
//  BookDiscoveryView.swift
//  Reading Tracker
//
//  Created by Johan Rembeci on 6/20/26.
//

import SwiftUI

struct BookDiscoveryView: View {

    var body: some View {
        NavigationStack {
            BookSearchDrawer(
                viewModel: BookDiscoveryViewModel()
            )
            .navigationTitle("Discover Books")
        }
    }
}

#Preview {
    BookDiscoveryView()
}
