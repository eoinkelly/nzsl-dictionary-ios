struct DictEntry: Equatable {
    fileprivate static let LOCATION_IMAGES = [
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

    // These properties can be set during initialization only
    let gloss: String?
    let minor: String?
    let maori: String?
    let image: String?
    let video: String?
    let handshape: String?
    let location: String?

    // MARK: Initializers

    init() {
        self.gloss = nil
        self.minor = nil
        self.maori = nil
        self.image = nil
        self.video = nil
        self.handshape = nil
        self.location = nil
    }

    init(gloss: String?, minor: String?, maori: String?, image: String?,
         video: String?, handshape: String?, location: String?) {
        self.gloss = gloss
        self.minor = minor
        self.maori = maori
        self.image = image
        self.video = video
        self.handshape = handshape
        self.location = location
    }

    // MARK: Public functions

    func handshapeImageFileName() -> String? {
        guard let handshape = self.handshape else { return nil }
        return "handshape.\(handshape).png"
    }

    func locationImageFileName() -> String? {
        guard let loc = self.location else { return nil }
        return DictEntry.LOCATION_IMAGES[loc]
    }

    // MARK: Equatable protocol

    static func ==(lhs: DictEntry, rhs: DictEntry) -> Bool {
        return lhs.gloss == rhs.gloss &&
            lhs.minor == rhs.minor &&
            lhs.maori == rhs.maori &&
            lhs.image == rhs.image &&
            lhs.video == rhs.video &&
            lhs.handshape == rhs.handshape &&
            lhs.location == rhs.location
    }
}

