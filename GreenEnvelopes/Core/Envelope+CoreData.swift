//
//  Envelope+CoreData.swift
//  GreenEnvelopes
//

import Foundation
import CoreData

@objc(Envelope)
public class Envelope: NSManagedObject {

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var iconName: String?
    @NSManaged public var order: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var targetAmount: NSDecimalNumber?  // optional, for progress %

    @NSManaged public var expenseTransactions: NSSet?     // Transaction where envelope == self
    @NSManaged public var sourceTransfers: NSSet?         // Transaction where sourceEnvelope == self
    @NSManaged public var targetTransfers: NSSet?        // Transaction where targetEnvelope == self
    @NSManaged public var incomeAllocations: NSSet?      // IncomeAllocation where envelope == self
}

extension Envelope {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Envelope> {
        NSFetchRequest<Envelope>(entityName: "Envelope")
    }
}
