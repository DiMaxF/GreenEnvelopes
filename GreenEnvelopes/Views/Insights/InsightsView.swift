//
//  InsightsView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData
import Charts

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.currencyCode) var currencyCode

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Envelope.order, ascending: true)])
    private var envelopes: FetchedResults<Envelope>

    @State private var appeared = false

    // MARK: - Computed data

    private var envelopeBalances: [(name: String, balance: Double)] {
        envelopes.map { env in
            (name: env.name ?? "Envelope", balance: NSDecimalNumber(decimal: env.balance(in: viewContext)).doubleValue)
        }.filter { $0.balance > 0 }
    }

    private var monthlyData: [(month: String, amount: Double)] {
        let cal = Calendar.current
        let now = Date()
        let startOfCurrentMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        var result: [(month: String, amount: Double)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        for i in (0..<6).reversed() {
            guard let monthStart = cal.date(byAdding: .month, value: -i, to: startOfCurrentMonth),
                  let monthEnd = cal.date(byAdding: .day, value: -1, to: cal.date(byAdding: .month, value: 1, to: monthStart)!)
            else { continue }
            let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            req.predicate = NSPredicate(format: "type == %@ AND date >= %@ AND date <= %@", "expense", monthStart as NSDate, monthEnd as NSDate)
            if let list = try? viewContext.fetch(req) {
                let sum = list.compactMap { $0.amount?.doubleValue }.reduce(0, +)
                result.append((month: formatter.string(from: monthStart), amount: sum))
            } else {
                result.append((month: formatter.string(from: monthStart), amount: 0))
            }
        }
        return result
    }

    private var totalIncome: Decimal {
        var sum: Decimal = 0
        let req: NSFetchRequest<IncomeAllocation> = IncomeAllocation.fetchRequest()
        if let allocs = try? viewContext.fetch(req) {
            for a in allocs { if let amt = a.amount { sum += amt as Decimal } }
        }
        return sum
    }

    private var totalSpent: Decimal {
        var sum: Decimal = 0
        let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        req.predicate = NSPredicate(format: "type == %@", "expense")
        if let list = try? viewContext.fetch(req) {
            for t in list { if let amt = t.amount { sum += amt as Decimal } }
        }
        return sum
    }

    private var envelopesAtRisk: Int {
        envelopes.filter { env in env.balance(in: viewContext) <= 0 }.count
    }

    private var currencyFormatter: NumberFormatter {
        CurrencySettings.formatter(code: currencyCode)
    }

    private var hasData: Bool {
        !envelopeBalances.isEmpty || !monthlyData.allSatisfy({ $0.amount == 0 })
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if hasData {
                        // Summary row
                        summarySection
                            .padding(.horizontal, 20)
                            .offset(y: appeared ? 0 : 30)
                            .opacity(appeared ? 1 : 0)

                        // Balance chart
                        if !envelopeBalances.isEmpty {
                            balanceChartSection
                                .padding(.horizontal, 20)
                                .offset(y: appeared ? 0 : 30)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: appeared)
                        }

                        // Monthly spending chart
                        if !monthlyData.isEmpty {
                            spendingChartSection
                                .padding(.horizontal, 20)
                                .offset(y: appeared ? 0 : 30)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appeared)
                        }
                    } else {
                        InsightsEmptyState()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .opacity(appeared ? 1 : 0)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background(colorScheme: colorScheme))
            .navigationTitle("Insights")
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        HStack(spacing: 12) {
            InsightMetricCard(
                icon: "arrow.down.circle.fill",
                title: "Income",
                value: currencyFormatter.string(from: NSDecimalNumber(decimal: totalIncome)) ?? "0",
                accentColor: AppColors.primaryAccent,
                colorScheme: colorScheme
            )

            InsightMetricCard(
                icon: "arrow.up.circle.fill",
                title: "Spent",
                value: currencyFormatter.string(from: NSDecimalNumber(decimal: totalSpent)) ?? "0",
                accentColor: Color(hex: "E8706A"),
                colorScheme: colorScheme
            )

            InsightMetricCard(
                icon: "exclamationmark.triangle.fill",
                title: "At risk",
                value: "\(envelopesAtRisk)",
                accentColor: envelopesAtRisk > 0 ? AppColors.warning : AppColors.secondaryText.opacity(0.5),
                colorScheme: colorScheme
            )
        }
    }

    // MARK: - Balance chart

    private var balanceChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Balance by envelope", systemImage: "chart.bar.xaxis")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Chart(envelopeBalances, id: \.name) { item in
                BarMark(
                    x: .value("Balance", item.balance),
                    y: .value("Envelope", item.name)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "2AAA6A"), Color(hex: "5CD6A0")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(AppColors.secondaryText.opacity(0.3))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption)
                }
            }
            .frame(height: CGFloat(max(100, envelopeBalances.count * 52)))
            .accessibilityLabel("Bar chart showing balance by envelope. \(envelopeBalances.map { "\($0.name): \(currencyFormatter.string(from: NSDecimalNumber(value: $0.balance)) ?? "")" }.joined(separator: ", "))")
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Monthly spending chart

    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Monthly spending", systemImage: "calendar.badge.clock")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text("Last 6 months")
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)

            Chart(monthlyData, id: \.month) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "E8A838"), Color(hex: "F5CE6E")],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(AppColors.secondaryText.opacity(0.3))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption)
                }
            }
            .frame(height: 160)
            .accessibilityLabel("Bar chart of monthly spending. \(monthlyData.map { "\($0.month): \(currencyFormatter.string(from: NSDecimalNumber(value: $0.amount)) ?? "")" }.joined(separator: ", "))")
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Metric card

private struct InsightMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let accentColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentColor)

            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption2)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Empty state

private struct InsightsEmptyState: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.secondaryText.opacity(0.4))
            Text("No insights yet")
                .font(.title3)
                .fontWeight(.medium)
            Text("Add income and expenses to see\nyour balance and spending trends.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.secondaryText)
            Button("Go to Envelopes") {
                appState.selectedTab = 0
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primaryAccent)
            .padding(.top, 8)
        }
        .padding()
    }
}
