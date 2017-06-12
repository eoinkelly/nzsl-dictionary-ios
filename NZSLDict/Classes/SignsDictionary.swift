//
//  SignsDictionary.swift
//  NZSLDict
//
//  Created by Eoin Kelly on 12/06/17.
//
//

import Foundation
//import CommonCrypto
import SQLite

//        Row(columnNames: ["\"handshape\"": 5,
//                          "\"picture\"": 3,
//                          "\"maori\"": 2,
//                          "\"target\"": 7,
//                          "\"video\"": 4,
//                          "\"location\"": 6,
//                          "\"gloss\"": 0,
//                          "\"minor\"": 1],
//            values: [Optional("bone"),
//                     Optional(""),
//                     Optional("kōiwi"),
//                     Optional("picture_w3_20.png"),
//                     Optional("http://freelex.nzsl.vuw.ac.nz/dnzsl/freelex/assets/3131/bone.3131.main_glosses.sp.r480x360.mp4"),
//                     Optional("4.3.1"),
//                     Optional("lower arm"),
//                     Optional("bone||koiwi")])


class SignsDictionaryNew: NSObject {
    private var numWordsInDB: Int = 0
    private var db: Connection!
    private var wordsTable: Table!

    // MARK: Initializers

    override init() {
        guard let sqliteDbFilePath = Bundle.main.path(forResource: "nzsl", ofType: "db") else {
            print("Failed to create db file path")
            return
        }

        do {
            self.db = try Connection(sqliteDbFilePath, readonly: true)
            self.wordsTable = Table("words")
            self.numWordsInDB = try db.scalar(self.wordsTable.count)

            print("There are \(numWordsInDB) words in SQLite DB")
        } catch {
            print("Failed to setup \(sqliteDbFilePath) SQLite DB")
        }
    }

    deinit {
        // TODO: do i need to close the DB connection somehow?
    }

    // MARK: public functions
    


    // used by tests and SearchViewController
    func search(for target: String) -> [DictEntry] {
        var sr = [Any]()
        let exactTerm: String = normalise(target)
        let containsTerm: String = "%%\(exactTerm)%%"
        var exactPrimaryMatchStmt: sqlite3_stmt?
        var containsPrimaryMatchStmt: sqlite3_stmt?
        var exactSecondaryMatchStmt: sqlite3_stmt?
        var containsSecondaryMatchStmt: sqlite3_stmt?
        var statementPreparedOk: Bool = true

        statementPreparedOk = sqlite3_prepare_v2(db, "SELECT * FROM words WHERE gloss = ? OR maori = ?", -1, exactPrimaryMatchStmt, nil) == SQLITE_OK && sqlite3_prepare_v2(db, "SELECT * FROM words WHERE gloss LIKE ? OR maori LIKE ?", -1, containsPrimaryMatchStmt, nil) == SQLITE_OK && sqlite3_prepare_v2(db, "SELECT * FROM words WHERE minor = ?", -1, exactSecondaryMatchStmt, nil) == SQLITE_OK && sqlite3_prepare_v2(db, "SELECT * FROM words WHERE minor LIKE ?", -1, containsSecondaryMatchStmt, nil) == SQLITE_OK

        if !statementPreparedOk {
            return nil
        }
        
        sqlite3_bind_text(exactPrimaryMatchStmt, 1, exactTerm.utf8, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(exactPrimaryMatchStmt, 2, exactTerm.utf8, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(containsPrimaryMatchStmt, 1, containsTerm.utf8, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(containsPrimaryMatchStmt, 2, containsTerm.utf8, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(exactSecondaryMatchStmt, 1, exactTerm.utf8, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(containsSecondaryMatchStmt, 1, containsTerm.utf8, -1, SQLITE_TRANSIENT)
        while sqlite3_step(exactPrimaryMatchStmt) == SQLITE_ROW {
            sr.append(entry_from_row(exactPrimaryMatchStmt))
        }
        sqlite3_finalize(exactPrimaryMatchStmt)
        while sqlite3_step(containsPrimaryMatchStmt) == SQLITE_ROW {
            sr.append(entry_from_row(containsPrimaryMatchStmt))
        }
        sqlite3_finalize(containsPrimaryMatchStmt)
        while sqlite3_step(exactSecondaryMatchStmt) == SQLITE_ROW {
            sr.append(entry_from_row(exactSecondaryMatchStmt))
        }
        sqlite3_finalize(exactSecondaryMatchStmt)
        while sqlite3_step(containsSecondaryMatchStmt) == SQLITE_ROW {
            sr.append(entry_from_row(containsSecondaryMatchStmt))
        }
        sqlite3_finalize(containsSecondaryMatchStmt)
        var uniqueResults = [Any]()
        for e: Any in sr {
            if !uniqueResults.contains(e) {
                uniqueResults.append(e)
            }
        }
        return uniqueResults
    }
//
//    func searchHandshape(_ targetHandshape: String, location targetLocation: String) -> [Any] { // used by SearchViewController
//        var sr = [Any]()
//        var st: sqlite3_stmt?
//        if targetHandshape != nil && targetLocation != nil {
//            if sqlite3_prepare_v2(db, "select * from words where handshape = ? and location = ?", -1, st, nil) != SQLITE_OK {
//                return nil
//            }
//            sqlite3_bind_text(st, 1, targetHandshape.utf8, -1, SQLITE_TRANSIENT)
//            sqlite3_bind_text(st, 2, targetLocation.utf8, -1, SQLITE_TRANSIENT)
//        }
//        else if targetHandshape != nil {
//            if sqlite3_prepare_v2(db, "select * from words where handshape = ?", -1, st, nil) != SQLITE_OK {
//                return nil
//            }
//            sqlite3_bind_text(st, 1, targetHandshape.utf8, -1, SQLITE_TRANSIENT)
//        }
//        else if targetLocation != nil {
//            if sqlite3_prepare_v2(db, "select * from words where location = ?", -1, st, nil) != SQLITE_OK {
//                return nil
//            }
//            sqlite3_bind_text(st, 1, targetLocation.utf8, -1, SQLITE_TRANSIENT)
//        }
//        else {
//            if sqlite3_prepare_v2(db, "select * from words", -1, st, nil) != SQLITE_OK {
//                return nil
//            }
//        }
//        
//        while sqlite3_step(st) == SQLITE_ROW {
//            sr.append(entry_from_row(st))
//        }
//        sqlite3_finalize(st)
//        sort_results(sr)
//        return sr
//    }
//
//    //  Converted with Swiftify v1.0.6355 - https://objectivec2swift.com/
//    func wordOfTheDay() -> DictEntry { // Used by searchViewController
//        let taboo = Set<AnyHashable>(["(vaginal) discharge", "abortion", "abuse", "anus", "asshole", "attracted", "balls", "been to", "bisexual", "bitch", "blow job", "breech (birth)", "bugger", "bullshit", "cervical smear", "cervix", "circumcise", "cold (behaviour)", "come", "condom", "contraction (labour)", "cunnilingus", "cunt", "damn", "defecate, faeces", "dickhead", "dilate (cervix)", "ejaculate, sperm", "episiotomy", "erection", "fart", "foreplay", "gay", "gender", "get intimate", "get stuffed", "hard-on", "have sex", "heterosexual", "homo", "horny", "hysterectomy", "intercourse", "labour pains", "lesbian", "lose one's virginity", "love bite", "lust", "masturbate (female)", "masturbate, wanker", "miscarriage", "orgasm", "ovaries", "penis", "period", "period pains", "promiscuous", "prostitute", "rape", "sanitary pad", "sex", "sexual abuse", "shit", "smooch", "sperm", "strip", "suicide", "tampon", "testicles", "vagina", "virgin"])
//        var now: time_t = time(nil)
//
//        let tm: tm? = localtime(now)
//        let buf = [CChar](repeating: CChar(), count: 20)
//        snprintf(buf, MemoryLayout<buf>.size, "%04d-%02d-%02d", 1900 + tm?.tm_year, 1 + tm?.tm_mon, tm?.tm_mday)
//        let digest = [UInt8](repeating: 0, count: CC_SHA1_DIGEST_LENGTH)
//        CC_SHA1(buf, (strlen(buf) as? CC_LONG), digest)
//        let i: Int = (digest[0] << 8) | (digest[1]) % count
//        let reject: ((_ e: DictEntry) -> Bool)? = {(_ e: DictEntry) -> Void in
//            if taboo.contains(e.gloss) {
//                return true
//            }
//            if (e.gloss as NSString).range(of: "fuck").location != NSNotFound || (e.minor as NSString).range(of: "fuck").location != NSNotFound {
//                return true
//            }
//            return false
//        }
//        var r: DictEntry? = nil
//        var st: sqlite3_stmt?
//        if sqlite3_prepare_v2(db, "select * from words limit 100 offset ?", -1, st, nil) != SQLITE_OK {
//            return nil
//        }
//        sqlite3_bind_int(st, 1, i)
//        while sqlite3_step(st) == SQLITE_ROW {
//            r = entry_from_row(st)
//            if reject(r) {
//                continue
//            }
//            break
//        }
//        sqlite3_finalize(st)
//        return r!
//    }
//
    // MARK: Private helper functions

//    private func normalise(s: String) -> String {
//        let d: Data? = s.data(using: String.Encoding.ascii, allowLossyConversion: true)
//        return String(d, encoding: String.Encoding.ascii).lowercased()
//    }
//
//    private func sort_results(sr: [Any]) {
//        sr.sort(by: {(_ obj1: Any, _ obj2: Any) -> Void in
//            var s1: String = obj1.gloss()
//            var s2: String = obj2.gloss()
//            let skip_parens: ((_ s: String) -> String)?? = {(_ s: String) -> Void in
//                if s[0] == "(" {
//                    let p: NSRange = (s as NSString).range(of: ") ")
//                    if p.location != NSNotFound {
//                        s = (s as? NSString)?.substring(from: p.location + 2)
//                    }
//                    else {
//                        print("expected to find closing parenthesis: \(s)")
//                    }
//                }
//                return s
//            }
//            s1 = skip_parens(s1)
//            s2 = skip_parens(s2)
//            return s1.caseInsensitiveCompare(s2)
//        })
//    }
//    private func entry_from_row(st: sqlite3_stmt) -> DictEntry {
//        let r = DictEntry()
//        r.gloss = String(utf8String: CChar(sqlite3_column_text(st, 0)))
//        r.minor = String(utf8String: CChar(sqlite3_column_text(st, 1)))
//        r.maori = String(utf8String: CChar(sqlite3_column_text(st, 2)))
//        r.image = String(utf8String: CChar(sqlite3_column_text(st, 3)))
//        r.video = String(utf8String: CChar(sqlite3_column_text(st, 4)))
//        r.handshape = String(utf8String: CChar(sqlite3_column_text(st, 5)))
//        r.location = String(utf8String: CChar(sqlite3_column_text(st, 6)))
//        return r
//    }
//
//

}
