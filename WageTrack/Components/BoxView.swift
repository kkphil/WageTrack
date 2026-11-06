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
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
    }
}
