//
//  VPTimestampView.swift
//  WageTrack
//
//  Created by Philip Kurth on 05.03.26.
//

import Foundation
import SwiftUI

struct VPTimestampView: View {
    @State private var date: Date = Date()
    @State private var color: Color = .accentColor
    
    init(date: Date, color: Color? = nil) {
        _date = State(initialValue: date)
        _color = State(initialValue: color ?? .accentColor)
    }
    
    var body: some View {
        VStack {
            Text(date.format("dd"))
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
            Text(date.format("MMM"))
                .font(.caption2)
                .textCase(.uppercase)
        }
        .frame(width: 45)
        .padding(5)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
