//
//  BoxView.swift
//  WageTrack
//
//  Created by Philip Kurth on 05.03.26.
//

import Foundation
import SwiftUI

struct BoxView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 90, height: 60)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
    }
}
