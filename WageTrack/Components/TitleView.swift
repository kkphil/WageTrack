//
//  TitleView.swift
//  WageTrack
//
//  Created by Philip Kurth on 22.02.26.
//

import Foundation
import SwiftUI

struct TitleView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.largeTitle)
            .bold()
            .frame(alignment: .leading)
            .lineLimit(1)
    }
}
