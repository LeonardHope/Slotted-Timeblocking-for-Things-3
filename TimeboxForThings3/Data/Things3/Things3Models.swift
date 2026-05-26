import Foundation
import GRDB

/// Raw database record for TMTask table.
struct Things3TaskRecord: FetchableRecord, Decodable {
    let uuid: String
    let title: String?
    let notes: String?
    let type: Int
    let status: Int
    let start: Int
    let startDate: Int?
    let deadline: Int?
    let trashed: Int
    let todayIndex: Int
    let project: String?
    let area: String?
    let heading: String?
    let checklistItemsCount: Int
    let openChecklistItemsCount: Int
    let creationDate: Double?
    let userModificationDate: Double?
    let stopDate: Double?
    let index: Int

    // Joined fields
    let projectTitle: String?
    let areaTitle: String?
    let headingTitle: String?
}

/// Raw database record for TMTag table.
struct Things3TagRecord: FetchableRecord, Decodable {
    let uuid: String
    let title: String?
    let shortcut: String?
    let parent: String?
    let index: Int
}

/// Raw database record for TMArea table.
struct Things3AreaRecord: FetchableRecord, Decodable {
    let uuid: String
    let title: String?
    let visible: Int
    let index: Int
}

/// Raw database record for TMTaskTag junction.
struct Things3TaskTagRecord: FetchableRecord, Decodable {
    let tasks: String
    let tags: String
}

/// Constants for Things 3 database values.
enum Things3Constants {
    enum TaskType: Int {
        case toDo = 0
        case project = 1
        case heading = 2
    }

    enum TaskStatus: Int {
        case incomplete = 0
        case canceled = 2
        case completed = 3
    }

    enum StartValue: Int {
        case inbox = 0
        case anytime = 1
        case someday = 2
    }
}
