//
//  HistoryFetch.swift
//  GreenEnvelopes
//

import CoreData

enum HistoryFetch {
    static func items(
        in context: NSManagedObjectContext,
        filter: HistoryFilter,
        envelopeID: NSManagedObjectID?,
        searchText: String
    ) -> [HistoryItem] {
        var items: [HistoryItem] = []

        let envelopeObj: Envelope? = envelopeID.flatMap { try? context.existingObject(with: $0) as? Envelope }

        if filter != .expenses {
            let allocReq: NSFetchRequest<IncomeAllocation> = IncomeAllocation.fetchRequest()
            if let env = envelopeObj {
                allocReq.predicate = NSPredicate(format: "envelope == %@", env)
            }
            if let allocs = try? context.fetch(allocReq) {
                for a in allocs {
                    if searchText.isEmpty ||
                        (a.envelope?.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                        (a.transaction?.note?.localizedCaseInsensitiveContains(searchText) ?? false) {
                        items.append(.incomeAllocation(a))
                    }
                }
            }
        }

        if filter != .income {
            let trReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            trReq.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
            var preds: [NSPredicate] = [NSPredicate(format: "type == %@ OR type == %@", "expense", "transfer")]
            if let env = envelopeObj {
                preds.append(NSPredicate(format: "envelope == %@ OR sourceEnvelope == %@ OR targetEnvelope == %@", env, env, env))
            }
            trReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
            if let list = try? context.fetch(trReq) {
                for t in list {
                    if searchText.isEmpty ||
                        (t.envelope?.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                        (t.sourceEnvelope?.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                        (t.targetEnvelope?.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                        (t.note?.localizedCaseInsensitiveContains(searchText) ?? false) {
                        if t.type == "expense" {
                            items.append(.expense(t))
                        } else {
                            items.append(.transfer(t))
                        }
                    }
                }
            }
        }

        items.sort { $0.date > $1.date }
        return items
    }
}

enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case income = "Income"
    case expenses = "Expenses"
}
