//
//  VPTimestampView.swift
//  WageTrack
//
//  Created by Philip Kurth on 05.03.26.
//

import Foundation
import SwiftUI

struct VPTimestampView: View {
    // Bewusst kein @State: Sonst bliebe das Datum stehen, wenn die Schicht bearbeitet wird
    let date: Date
    var color: Color = .accentColor

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
