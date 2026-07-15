//  BookDiscoveryView.swift
//  Reading Tracker
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
