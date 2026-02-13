//
//  IncomeAllocation+CoreData.swift
//  GreenEnvelopes
//

import Foundation
import CoreData

@objc(IncomeAllocation)
public class IncomeAllocation: NSManagedObject {

    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var transaction: Transaction?
    @NSManaged public var envelope: Envelope?
}

extension IncomeAllocation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<IncomeAllocation> {
        NSFetchRequest<IncomeAllocation>(entityName: "IncomeAllocation")
    }
}
