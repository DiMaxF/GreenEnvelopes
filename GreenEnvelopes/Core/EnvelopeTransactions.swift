//
//  EnvelopeTransactions.swift
//  GreenEnvelopes
//

import CoreData

struct EnvelopeTransactionItem: Identifiable {
    let id: UUID
    let date: Date
    let amount: Decimal
    let type: String  // "income", "expense", "transfer_in", "transfer_out"
    let note: String?
    let envelopeName: String?
}

extension Envelope {
    /// Last N transactions affecting this envelope (expenses, transfers, income allocations).
    func recentTransactionItems(in context: NSManagedObjectContext, limit: Int = 10) -> [EnvelopeTransactionItem] {
        var items: [EnvelopeTransactionItem] = []

        // Expenses from this envelope
        let expReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        expReq.predicate = NSPredicate(format: "type == %@ AND envelope == %@", "expense", self)
        expReq.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        expReq.fetchLimit = limit
        if let list = try? context.fetch(expReq) {
            for t in list {
                items.append(EnvelopeTransactionItem(
                    id: t.id ?? UUID(),
                    date: t.date ?? Date(),
                    amount: -(t.amount as Decimal? ?? 0),
                    type: "expense",
                    note: t.note,
                    envelopeName: name
                ))
            }
        }

        // Transfers out
        let outReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        outReq.predicate = NSPredicate(format: "type == %@ AND sourceEnvelope == %@", "transfer", self)
        outReq.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        outReq.fetchLimit = limit
        if let list = try? context.fetch(outReq) {
            for t in list {
                items.append(EnvelopeTransactionItem(
                    id: t.id ?? UUID(),
                    date: t.date ?? Date(),
                    amount: -(t.amount as Decimal? ?? 0),
                    type: "transfer_out",
                    note: t.note,
                    envelopeName: t.targetEnvelope?.name
                ))
            }
        }

        // Transfers in
        let inReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        inReq.predicate = NSPredicate(format: "type == %@ AND targetEnvelope == %@", "transfer", self)
        inReq.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        inReq.fetchLimit = limit
        if let list = try? context.fetch(inReq) {
            for t in list {
                items.append(EnvelopeTransactionItem(
                    id: t.id ?? UUID(),
                    date: t.date ?? Date(),
                    amount: t.amount as Decimal? ?? 0,
                    type: "transfer_in",
                    note: t.note,
                    envelopeName: t.sourceEnvelope?.name
                ))
            }
        }

        // Income allocations to this envelope
        let allocReq: NSFetchRequest<IncomeAllocation> = IncomeAllocation.fetchRequest()
        allocReq.predicate = NSPredicate(format: "envelope == %@", self)
        allocReq.fetchLimit = limit * 2
        if let allocs = try? context.fetch(allocReq) {
            for a in allocs {
                let t = a.transaction
                items.append(EnvelopeTransactionItem(
                    id: UUID(),
                    date: t?.date ?? Date(),
                    amount: a.amount as Decimal? ?? 0,
                    type: "income",
                    note: t?.note,
                    envelopeName: name
                ))
            }
        }

        items.sort { $0.date > $1.date }
        return Array(items.prefix(limit))
    }
}
