//
//  PagingCarousel.swift
//  Andare
//
//  Created by neg2sode on 2025/7/20.
//

import SwiftUI

struct PagingCarousel<SelectionValue: Hashable, Page: View>: View {
    @Binding var selection: SelectionValue
    let pages: [SelectionValue]
    let content: (SelectionValue) -> Page

    init(selection: Binding<SelectionValue>, pages: [SelectionValue], @ViewBuilder content: @escaping (SelectionValue) -> Page) {
        self._selection = selection
        self.pages = pages
        self.content = content
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(pages, id: \.self) { pageValue in
                content(pageValue)
                    .tag(pageValue)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}
