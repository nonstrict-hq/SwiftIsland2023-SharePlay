/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The activity that users use to draw together.
*/

import Foundation
import GroupActivities

struct DrawTogether: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = NSLocalizedString("Draw Together", comment: "Title of group activity")
        metadata.subtitle = Date().formatted()
        if #available(iOS 17, *) {
            metadata.type = .createTogether
        } else {
            metadata.type = .generic
        }
        return metadata
    }
}
