//
//  Transaction+CoreData.swift
//  GreenEnvelopes
//

import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {

    @NSManaged public var id: UUID?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var type: String?   // "income", "expense", "transfer"
    @NSManaged public var date: Date?
    @NSManaged public var note: String?

    @NSManaged public var envelope: Envelope?             // for expense: envelope we spend from
    @NSManaged public var sourceEnvelope: Envelope?      // for transfer
    @NSManaged public var targetEnvelope: Envelope?       // for transfer
    @NSManaged public var allocations: NSSet?            // IncomeAllocation (for income)
}

extension Transaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        NSFetchRequest<Transaction>(entityName: "Transaction")
    }
}
