struct ModelList: Encodable {
    struct Entry: Encodable {
        let id: String
        let object = "model"
        let created = 0
        let ownedBy = "apple"
    }

    let object = "list"
    let data: [Entry]
}
