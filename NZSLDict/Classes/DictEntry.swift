import Foundation

struct DictEntry {
    private static let locationImages = [
        "in front of body":  "location.1.1.in_front_of_body.png",
        "chest":             "location.4.12.chest.png",
        "lower head":        "location.3.9.lower_head.png",
        "fingers/thumb":     "location.6.20.fingers_thumb.png",
        "in front of face":  "location.2.2.in_front_of_face.png",
        "top of head":       "location.3.4.top_of_head.png",
        "head":              "location.3.3.head.png",
        "cheek":             "location.3.8.cheek.png",
        "nose":              "location.3.6.nose.png",
        "back of hand":      "location.6.22.back_of_hand.png",
        "neck/throat":       "location.4.10.neck_throat.png",
        "shoulders":         "location.4.11.shoulders.png",
        "abdomen":           "location.4.13.abdomen.png",
        "eyes":              "location.3.5.eyes.png",
        "ear":               "location.3.7.ear.png",
        "hips/pelvis/groin": "location.4.14.hips_pelvis_groin.png",
        "wrist":             "location.6.19.wrist.png",
        "lower arm":         "location.5.18.lower_arm.png",
        "upper arm":         "location.5.16.upper_arm.png",
        "elbow":             "location.5.17.elbow.png",
        "upper leg":         "location.4.15.upper_leg.png",
        ]

    // TODO: can these be made let if I implement an initializer?
    var gloss: String = ""
    var minor: String = ""
    var maori: String = ""
    var image: String = ""
    var video: String = ""
    var handshape: String = ""
    var location: String = ""

    func handshapeImage() -> String {
        return "handshape.\(handshape).png"
    }

    func locationImage() -> String {
        // TODO: need to handle possibly missing locations better
        return DictEntry.locationImages[self.location]!
    }
}

// TODO: should this be in diff file?
extension DictEntry: Equatable {}

func ==(lhs: DictEntry, rhs: DictEntry) -> Bool {
    let areEqual = lhs.gloss == rhs.gloss &&
                   lhs.minor == rhs.minor &&
                   lhs.maori == rhs.maori &&
                   lhs.image == rhs.image &&
                   lhs.video == rhs.video &&
                   lhs.handshape == rhs.handshape &&
                   lhs.location == rhs.location
    return areEqual
}
