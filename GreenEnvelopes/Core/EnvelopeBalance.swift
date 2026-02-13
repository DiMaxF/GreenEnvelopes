//
//  EnvelopeBalance.swift
//  GreenEnvelopes
//

import CoreData

extension Envelope {

    /// Balance = sum(income allocations) + sum(transfers in) - sum(expenses) - sum(transfers out)
    func balance(in context: NSManagedObjectContext) -> Decimal {
        var total = Decimal.zero

        // Income allocations to this envelope
        let allocReq: NSFetchRequest<IncomeAllocation> = IncomeAllocation.fetchRequest()
        allocReq.predicate = NSPredicate(format: "envelope == %@", self)
        if let allocs = try? context.fetch(allocReq) {
            for a in allocs { if let amt = a.amount { total += amt as Decimal } }
        }

        // Transfers into this envelope
        let targetReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        targetReq.predicate = NSPredicate(format: "type == %@ AND targetEnvelope == %@", "transfer", self)
        if let transfers = try? context.fetch(targetReq) {
            for t in transfers { if let amt = t.amount { total += amt as Decimal } }
        }

        // Expenses from this envelope
        let expReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        expReq.predicate = NSPredicate(format: "type == %@ AND envelope == %@", "expense", self)
        if let expenses = try? context.fetch(expReq) {
            for t in expenses { if let amt = t.amount { total -= amt as Decimal } }
        }

        // Transfers out of this envelope
        let sourceReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        sourceReq.predicate = NSPredicate(format: "type == %@ AND sourceEnvelope == %@", "transfer", self)
        if let out = try? context.fetch(sourceReq) {
            for t in out { if let amt = t.amount { total -= amt as Decimal } }
        }

        return total
    }

    /// Optional target amount for progress (e.g. 100% = full)
    var targetAmountValue: Decimal? {
        guard let t = targetAmount else { return nil }
        return t as Decimal
    }
}
