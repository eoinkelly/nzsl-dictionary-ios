import Foundation
import SQLite

class SignsDictionary {
    // These words are still in the dictionary and can be found via search but
    // will not appear as "word of the day". "fuck" is conspiciously absent
    // here because it is treated as a special case.
    fileprivate static let UNSUITABLE_FOR_WOTD_WORDSET = Set<String>([
        "(vaginal) discharge", "abortion", "abuse", "anus", "asshole", "attracted", "balls", "been to", "bisexual", "bitch",
        "blow job", "breech (birth)", "bugger", "bullshit", "cervical smear", "cervix", "circumcise", "cold (behaviour)", "come",
        "condom", "contraction (labour)", "cunnilingus", "cunt", "damn", "defecate", "faeces", "dickhead", "dilate (cervix)",
        "ejaculate", "sperm", "episiotomy", "erection", "fart", "foreplay", "gay", "gender", "get intimate", "get stuffed",
        "hard-on", "have sex", "heterosexual", "homo", "horny", "hysterectomy", "intercourse", "labour pains", "lesbian",
        "lose one's virginity", "love bite", "lust", "masturbate (female)", "masturbate", "wanker", "miscarriage", "orgasm",
        "ovaries", "penis", "period", "period pains", "promiscuous", "prostitute", "rape", "sanitary pad", "sex", "sexual abuse",
        "shit", "smooch", "sperm", "strip", "suicide", "tampon", "testicles", "vagina", "virgin"])

    // Knowing the number of rows in the DB lets us calculate WOTD
    fileprivate var numRowsInDB: Int = 0

    // SQLite.swift table types
    fileprivate let wordsTable: Table = Table("words")

    // SQLite.swift column types
    fileprivate let glossColumn = Expression<String?>("gloss")
    fileprivate let maoriColumn = Expression<String?>("maori")
    fileprivate let minorColumn = Expression<String?>("minor")
    fileprivate let pictureColumn = Expression<String?>("picture")
    fileprivate let videoColumn = Expression<String?>("video")
    fileprivate let handshapeColumn = Expression<String?>("handshape")
    fileprivate let locationColumn = Expression<String?>("location")

    // SQLite.swift DB connection
    fileprivate var db: Connection!

    // MARK: Initializers

    init?() {
        guard let sqliteDbFilePath = Bundle.main.path(forResource: "nzsl", ofType: "db") else {
            print("Failed to find the signs dictionary at the expected path")
            return nil
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
            self.numRowsInDB = try db.scalar(self.wordsTable.count)

            #if DEBUG
                print("There are \(self.numRowsInDB) words in the Signs Database")
            #endif
        } catch {
            print("Failed to connect to '\(sqliteDbFilePath)' SQLite DB")
            return nil
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
                resultSet.add(row)
            }
            for row in try db.prepare(containsPrimaryQuery) {
                resultSet.add(row)
            }
            for row in try db.prepare(exactSecondaryQuery) {
                resultSet.add(row)
            }
            for row in try db.prepare(containsSecondaryQuery) {
                resultSet.add(row)
            }
        } catch {
            #if DEBUG
                print("Encountered an error while performing search")
            #endif
            return []
        }

        #if DEBUG
            print("Found \(resultSet.count) results for search term '\(target)'")
        #endif

        return resultSet.array.map({ buildDictEntryFromRow($0 as! Row) })
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
    //     1. Find 100 candidate DictEntrys from the database with an offset calculated
    //        based on today's date (offset will change only when date does)
    //     2. Iterate through the candidates until we find one which is suitable and
    //        return it.
    //
    func wordOfTheDay() -> DictEntry {
        // Avoid division by 0 error
        guard self.numRowsInDB > 0 else { return DictEntry() }

        let offset = numSecondsBetweenJan1970AndStartOfToday() % self.numRowsInDB
        let query = self.wordsTable.limit(100, offset: offset)

        do {
            for row in try db.prepare(query) {
                let candidateDictEntry = buildDictEntryFromRow(row)
                if entryIsSuitableAsWotd(candidateDictEntry) {
                    return candidateDictEntry
                }
            }
        } catch {
            #if DEBUG
                print("Failed to find a word of the day")
            #endif
        }

        return DictEntry()
    }


    // MARK: Private helper functions

    fileprivate func buildDictEntryFromRow(_ row: Row) -> DictEntry {
        return DictEntry(gloss: row[glossColumn],
                            minor: row[minorColumn],
                            maori: row[maoriColumn],
                            image: row[pictureColumn],
                            video: row[videoColumn],
                            handshape: row[handshapeColumn],
                            location: row[locationColumn])
    }

    fileprivate func entryIsSuitableAsWotd(_ dictEntry: DictEntry) -> Bool {
        guard let gloss = dictEntry.gloss else { return false }
        let lcGloss = gloss.lowercased()

        if SignsDictionary.UNSUITABLE_FOR_WOTD_WORDSET.contains(lcGloss) { return false }
        if lcGloss.range(of:"fuck") != nil { return false }

        return true
    }

    fileprivate func numSecondsBetweenJan1970AndStartOfToday() -> Int {
        let now = Date()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        components.setValue(0, for: .hour)
        components.setValue(0, for: .minute)
        components.setValue(0, for: .second)
        let startOfToday = calendar.date(from: components)!

        return Int(startOfToday.timeIntervalSince1970)
    }
}
