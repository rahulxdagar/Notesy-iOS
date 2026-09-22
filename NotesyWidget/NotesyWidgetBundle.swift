//
//  NotesyWidgetBundle.swift
//  NotesyWidget
//
//  Created by Rahul Dagar on 2026-09-22.
//

import WidgetKit
import SwiftUI

@main
struct NotesyWidgetBundle: WidgetBundle {
    var body: some Widget {
        NotesyWidget()
        NotesyWidgetControl()
        NotesyWidgetLiveActivity()
    }
}
