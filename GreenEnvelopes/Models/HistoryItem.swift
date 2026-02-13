//
//  HistoryItem.swift
//  GreenEnvelopes
//

import Foundation
import CoreData

enum HistoryItem: Identifiable {
    case expense(Transaction)
    case transfer(Transaction)
    case incomeAllocation(IncomeAllocation)

    var id: String {
        switch self {
        case .expense(let t): return "exp-\(t.id?.uuidString ?? UUID().uuidString)"
        case .transfer(let t): return "tr-\(t.id?.uuidString ?? UUID().uuidString)"
        case .incomeAllocation(let a): return "inc-\(a.objectID.uriRepresentation().absoluteString)"
        }
    }

    var date: Date {
        switch self {
        case .expense(let t): return t.date ?? Date()
        case .transfer(let t): return t.date ?? Date()
        case .incomeAllocation(let a): return a.transaction?.date ?? Date()
        }
    }

    var amount: Decimal {
        switch self {
        case .expense(let t): return -(t.amount as Decimal? ?? 0)
        case .transfer(let t): return -(t.amount as Decimal? ?? 0)
        case .incomeAllocation(let a): return a.amount as Decimal? ?? 0
        }
    }

    var isIncome: Bool {
        if case .incomeAllocation = self { return true }
        return false
    }

    var envelopeName: String? {
        switch self {
        case .expense(let t): return t.envelope?.name
        case .transfer(let t): return t.sourceEnvelope?.name
        case .incomeAllocation(let a): return a.envelope?.name
        }
    }

    var note: String? {
        switch self {
        case .expense(let t): return t.note
        case .transfer(let t): return t.note
        case .incomeAllocation(let a): return a.transaction?.note
        }
    }

    var detailDescription: String {
        switch self {
        case .expense: return "Expense"
        case .transfer(let t):
            return "Transfer to \(t.targetEnvelope?.name ?? "envelope")"
        case .incomeAllocation: return "Income"
        }
    }
}
