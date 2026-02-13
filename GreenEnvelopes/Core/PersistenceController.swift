//
//  PersistenceController.swift
//  GreenEnvelopes
//

import CoreData

final class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        let model = PersistenceController.buildManagedObjectModel()
        container = NSPersistentContainer(name: "GreenEnvelopes", managedObjectModel: model)

        if container.persistentStoreDescriptions.isEmpty {
            let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("GreenEnvelopes.sqlite")
            let desc = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [desc]
        }

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func buildManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: - Envelope entity
        let envelopeEntity = NSEntityDescription()
        envelopeEntity.name = "Envelope"
        envelopeEntity.managedObjectClassName = "GreenEnvelopes.Envelope"

        let envelopeId = NSAttributeDescription()
        envelopeId.name = "id"
        envelopeId.attributeType = .UUIDAttributeType
        envelopeId.isOptional = true

        let envelopeName = NSAttributeDescription()
        envelopeName.name = "name"
        envelopeName.attributeType = .stringAttributeType
        envelopeName.isOptional = true

        let envelopeIconName = NSAttributeDescription()
        envelopeIconName.name = "iconName"
        envelopeIconName.attributeType = .stringAttributeType
        envelopeIconName.isOptional = true

        let envelopeOrder = NSAttributeDescription()
        envelopeOrder.name = "order"
        envelopeOrder.attributeType = .integer32AttributeType
        envelopeOrder.defaultValue = 0

        let envelopeCreatedAt = NSAttributeDescription()
        envelopeCreatedAt.name = "createdAt"
        envelopeCreatedAt.attributeType = .dateAttributeType
        envelopeCreatedAt.isOptional = true

        let envelopeTargetAmount = NSAttributeDescription()
        envelopeTargetAmount.name = "targetAmount"
        envelopeTargetAmount.attributeType = .decimalAttributeType
        envelopeTargetAmount.isOptional = true

        envelopeEntity.properties = [envelopeId, envelopeName, envelopeIconName, envelopeOrder, envelopeCreatedAt, envelopeTargetAmount]

        // MARK: - Transaction entity
        let transactionEntity = NSEntityDescription()
        transactionEntity.name = "Transaction"
        transactionEntity.managedObjectClassName = "GreenEnvelopes.Transaction"

        let transactionId = NSAttributeDescription()
        transactionId.name = "id"
        transactionId.attributeType = .UUIDAttributeType
        transactionId.isOptional = true

        let transactionAmount = NSAttributeDescription()
        transactionAmount.name = "amount"
        transactionAmount.attributeType = .decimalAttributeType
        transactionAmount.isOptional = true

        let transactionType = NSAttributeDescription()
        transactionType.name = "type"
        transactionType.attributeType = .stringAttributeType
        transactionType.isOptional = true

        let transactionDate = NSAttributeDescription()
        transactionDate.name = "date"
        transactionDate.attributeType = .dateAttributeType
        transactionDate.isOptional = true

        let transactionNote = NSAttributeDescription()
        transactionNote.name = "note"
        transactionNote.attributeType = .stringAttributeType
        transactionNote.isOptional = true

        let envelopeRel = NSRelationshipDescription()
        envelopeRel.name = "envelope"
        envelopeRel.maxCount = 1
        envelopeRel.isOptional = true

        let sourceEnvelopeRel = NSRelationshipDescription()
        sourceEnvelopeRel.name = "sourceEnvelope"
        sourceEnvelopeRel.maxCount = 1
        sourceEnvelopeRel.isOptional = true

        let targetEnvelopeRel = NSRelationshipDescription()
        targetEnvelopeRel.name = "targetEnvelope"
        targetEnvelopeRel.maxCount = 1
        targetEnvelopeRel.isOptional = true

        let allocationsRel = NSRelationshipDescription()
        allocationsRel.name = "allocations"
        allocationsRel.minCount = 0
        allocationsRel.maxCount = 0
        allocationsRel.deleteRule = .cascadeDeleteRule

        transactionEntity.properties = [transactionId, transactionAmount, transactionType, transactionDate, transactionNote, envelopeRel, sourceEnvelopeRel, targetEnvelopeRel, allocationsRel]

        // MARK: - IncomeAllocation entity
        let allocationEntity = NSEntityDescription()
        allocationEntity.name = "IncomeAllocation"
        allocationEntity.managedObjectClassName = "GreenEnvelopes.IncomeAllocation"

        let allocationAmount = NSAttributeDescription()
        allocationAmount.name = "amount"
        allocationAmount.attributeType = .decimalAttributeType
        allocationAmount.isOptional = true

        let allocationTransactionRel = NSRelationshipDescription()
        allocationTransactionRel.name = "transaction"
        allocationTransactionRel.maxCount = 1
        allocationTransactionRel.isOptional = true

        let allocationEnvelopeRel = NSRelationshipDescription()
        allocationEnvelopeRel.name = "envelope"
        allocationEnvelopeRel.maxCount = 1
        allocationEnvelopeRel.isOptional = true

        allocationEntity.properties = [allocationAmount, allocationTransactionRel, allocationEnvelopeRel]

        // Set relationship destinations and inverses
        envelopeRel.destinationEntity = envelopeEntity
        sourceEnvelopeRel.destinationEntity = envelopeEntity
        targetEnvelopeRel.destinationEntity = envelopeEntity
        allocationsRel.destinationEntity = allocationEntity

        allocationTransactionRel.destinationEntity = transactionEntity
        allocationEnvelopeRel.destinationEntity = envelopeEntity

        let envelopeExpenses = NSRelationshipDescription()
        envelopeExpenses.name = "expenseTransactions"
        envelopeExpenses.minCount = 0
        envelopeExpenses.maxCount = 0
        envelopeExpenses.destinationEntity = transactionEntity
        envelopeExpenses.inverseRelationship = envelopeRel

        let envelopeSourceTransfers = NSRelationshipDescription()
        envelopeSourceTransfers.name = "sourceTransfers"
        envelopeSourceTransfers.minCount = 0
        envelopeSourceTransfers.maxCount = 0
        envelopeSourceTransfers.destinationEntity = transactionEntity
        envelopeSourceTransfers.inverseRelationship = sourceEnvelopeRel

        let envelopeTargetTransfers = NSRelationshipDescription()
        envelopeTargetTransfers.name = "targetTransfers"
        envelopeTargetTransfers.minCount = 0
        envelopeTargetTransfers.maxCount = 0
        envelopeTargetTransfers.destinationEntity = transactionEntity
        envelopeTargetTransfers.inverseRelationship = targetEnvelopeRel

        let envelopeAllocations = NSRelationshipDescription()
        envelopeAllocations.name = "incomeAllocations"
        envelopeAllocations.minCount = 0
        envelopeAllocations.maxCount = 0
        envelopeAllocations.destinationEntity = allocationEntity
        envelopeAllocations.inverseRelationship = allocationEnvelopeRel

        envelopeRel.inverseRelationship = envelopeExpenses
        sourceEnvelopeRel.inverseRelationship = envelopeSourceTransfers
        targetEnvelopeRel.inverseRelationship = envelopeTargetTransfers
        allocationsRel.inverseRelationship = allocationTransactionRel
        allocationTransactionRel.inverseRelationship = allocationsRel
        allocationEnvelopeRel.inverseRelationship = envelopeAllocations

        envelopeEntity.properties.append(contentsOf: [envelopeExpenses, envelopeSourceTransfers, envelopeTargetTransfers, envelopeAllocations])

        let allocationTransactionInverse = NSRelationshipDescription()
        allocationTransactionInverse.name = "transaction"
        allocationTransactionInverse.maxCount = 1
        allocationTransactionInverse.destinationEntity = transactionEntity
        allocationTransactionInverse.inverseRelationship = allocationsRel

        model.entities = [envelopeEntity, transactionEntity, allocationEntity]
        return model
    }

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
