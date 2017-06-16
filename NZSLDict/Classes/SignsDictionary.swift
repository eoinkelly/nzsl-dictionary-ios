import Foundation
import SQLite

class SignsDictionary {
    // "fuck" is conspiciously absent here because it is treated as a special case
    private static let UNSUITABLE_FOR_WOTD_WORDSET = Set<String>(["(vaginal) discharge",
                                                                  "abortion", "abuse", "anus", "asshole", "attracted", "balls", "been to",
                                                                  "bisexual", "bitch", "blow job", "breech (birth)", "bugger",
                                                                  "bullshit", "cervical smear", "cervix", "circumcise", "cold (behaviour)",
                                                                  "come", "condom", "contraction (labour)", "cunnilingus",
                                                                  "cunt", "damn", "defecate", "faeces", "dickhead", "dilate (cervix)",
                                                                  "ejaculate", "sperm", "episiotomy", "erection", "fart", "foreplay",
                                                                  "gay", "gender", "get intimate", "get stuffed", "hard-on", "have sex",
                                                                  "heterosexual", "homo", "horny", "hysterectomy", "intercourse", "labour pains",
                                                                  "lesbian", "lose one's virginity", "love bite", "lust",
                                                                  "masturbate (female)", "masturbate", "wanker", "miscarriage", "orgasm",
                                                                  "ovaries", "penis", "period", "period pains", "promiscuous",
                                                                  "prostitute", "rape", "sanitary pad", "sex", "sexual abuse", "shit",
                                                                  "smooch", "sperm", "strip", "suicide", "tampon", "testicles", "vagina", "virgin"])

    private var numWordsInDB: Int = 0
    private let wordsTable: Table = Table("words")
    private let glossColumn = Expression<String>("gloss")
    private let maoriColumn = Expression<String>("maori")
    private let minorColumn = Expression<String>("minor")
    private let pictureColumn = Expression<String>("picture")
    private let videoColumn = Expression<String>("video")
    private let handshapeColumn = Expression<String>("handshape")
    private let locationColumn = Expression<String>("location")
    private var db: Connection!

    // MARK: Initializers

    init() {
        guard let sqliteDbFilePath = Bundle.main.path(forResource: "nzsl", ofType: "db") else {
            // TODO: what to do with this error?
            print("Failed to create db file path")
            return
        }

        do {
            // Swift takes care of any cleanup of the DB connection when this
            // class gets deallocated
            self.db = try Connection(sqliteDbFilePath, readonly: true)

            // Log all SQL statements if we are built with -D DEBUG
            // preprocessor flag set (see the "Other Swift flags" section of the
            // Build Settings)
            #if DEBUG
                self.db.trace { print("SQL TRACE: \($0)") }
            #endif

            // Gather the count of words in the DB for later display in the UI.
            self.numWordsInDB = try db.scalar(self.wordsTable.count)

            #if DEBUG
                print("Found \(numWordsInDB) words in Signs Database")
            #endif
        } catch {
            // TODO: what to do with this error?
            print("Failed to setup \(sqliteDbFilePath) SQLite DB")
            return
        }
    }

    // MARK: public functions

    func search(for target: String) -> [DictEntry] {
        let resultSet: NSMutableOrderedSet = NSMutableOrderedSet()
        let lowerCaseTarget = target.lowercased()
        let containsTarget = "%\(lowerCaseTarget)%"

        let exactPrimaryQuery = self.wordsTable.filter(self.glossColumn == lowerCaseTarget || self.maoriColumn == lowerCaseTarget)
        let containsPrimaryQuery = self.wordsTable.filter(self.glossColumn.like(containsTarget) || self.maoriColumn.like(containsTarget))
        let exactSecondaryQuery = self.wordsTable.filter(self.minorColumn == lowerCaseTarget)
        let containsSecondaryQuery = self.wordsTable.filter(self.minorColumn.like(containsTarget))

        do {
            for row in try db.prepare(exactPrimaryQuery) {
                resultSet.add(buildDictEntryFromRow(row))
            }
            for row in try db.prepare(containsPrimaryQuery) {
                resultSet.add(buildDictEntryFromRow(row))
            }
            for row in try db.prepare(exactSecondaryQuery) {
                resultSet.add(buildDictEntryFromRow(row))
            }
            for row in try db.prepare(containsSecondaryQuery) {
                resultSet.add(buildDictEntryFromRow(row))
            }
        } catch {
            print("Encountered an error while performing search")
            return []
        }

        #if DEBUG
            print("Found \(resultSet.count) results")
        #endif

        return resultSet.array as! [DictEntry]
    }

    func searchHandshape(_ targetHandshape: String?, location targetLocation: String?) -> [DictEntry] {
        var results: [DictEntry] = []
        var query: Table

        if targetHandshape != nil && targetLocation != nil {
            query = self.wordsTable.filter(self.handshapeColumn == targetHandshape! && self.locationColumn == targetLocation!)
        }
        else if targetHandshape != nil {
            query = self.wordsTable.filter(self.handshapeColumn == targetHandshape!)
        }
        else if targetLocation != nil {
            query = self.wordsTable.filter(self.locationColumn == targetLocation!)
        }
        else {
            query = self.wordsTable
        }

        do {
            for row in try db.prepare(query) {
                results.append(buildDictEntryFromRow(row))
            }
        } catch {
            print("failed to do query")
            return []
        }

        return results;
    }


    // How this works:
    //
    //     1. Find 100 candidate words from the database
    //     2. iterate through them until we find one which is suitable and return it
    //
    func wordOfTheDay() -> DictEntry {
        let offset = numSecondsBetweenJan1970AndStartOfToday() % self.numWordsInDB
        let query = self.wordsTable.limit(100, offset: offset)

        do {
            for row in try db.prepare(query) {
                let candidateDictEntry = buildDictEntryFromRow(row)
                if entryIsSuitableAsWotd(candidateDictEntry) {
                    return candidateDictEntry
                }
            }
        } catch {
            print("Failed to find a word of the day")
        }

        return DictEntry()
    }


    // MARK: Private helper functions

    private func buildDictEntryFromRow(_ row: Row) -> DictEntry {
        // TODO: how do i ensure that the value gets set to emtpy string if it comes back as null from DB?
        return DictEntry(gloss: row[glossColumn],
                            minor: row[minorColumn],
                            maori: row[maoriColumn],
                            image: row[pictureColumn],
                            video: row[videoColumn],
                            handshape: row[handshapeColumn],
                            location: row[locationColumn])
    }

    private func entryIsSuitableAsWotd(_ dictEntry: DictEntry) -> Bool {
        if SignsDictionary.UNSUITABLE_FOR_WOTD_WORDSET.contains(dictEntry.gloss.lowercased()) { return false }
        if dictEntry.gloss.lowercased().range(of:"fuck") != nil { return false }
        return true
    }

    private func numSecondsBetweenJan1970AndStartOfToday() -> Int {
        let now = Date()
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        var components = calendar.components([.year, .month, .day, .hour, .minute, .second], from: now)
        components.setValue(0, for: .hour)
        components.setValue(0, for: .minute)
        components.setValue(0, for: .second)
        let startOfToday = calendar.date(from: components)!

        return Int(startOfToday.timeIntervalSince1970)
    }
}
