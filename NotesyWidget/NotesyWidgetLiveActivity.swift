//
//  NotesyWidgetLiveActivity.swift
//  NotesyWidget
//
//  Created by Rahul Dagar on 2026-09-22.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NotesyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct NotesyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NotesyWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension NotesyWidgetAttributes {
    fileprivate static var preview: NotesyWidgetAttributes {
        NotesyWidgetAttributes(name: "World")
    }
}

extension NotesyWidgetAttributes.ContentState {
    fileprivate static var smiley: NotesyWidgetAttributes.ContentState {
        NotesyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: NotesyWidgetAttributes.ContentState {
         NotesyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: NotesyWidgetAttributes.preview) {
   NotesyWidgetLiveActivity()
} contentStates: {
    NotesyWidgetAttributes.ContentState.smiley
    NotesyWidgetAttributes.ContentState.starEyes
}
