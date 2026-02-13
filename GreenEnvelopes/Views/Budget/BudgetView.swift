//
//  BudgetView.swift
//  GreenEnvelopes
//
//  Interactive budget health dashboard with animated gauge,
//  daily allowance, spending donut chart, and saving streak.
//

import SwiftUI
import CoreData

struct BudgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.currencyCode) var currencyCode

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Envelope.order, ascending: true)])
    private var envelopes: FetchedResults<Envelope>

    @State private var appeared = false
    @State private var selectedSegment: String? = nil
    @State private var animatedHealth: CGFloat = 0

    // MARK: - Computed data

    private var totalIncome: Double {
        let req: NSFetchRequest<IncomeAllocation> = IncomeAllocation.fetchRequest()
        guard let allocs = try? viewContext.fetch(req) else { return 0 }
        return allocs.compactMap { $0.amount?.doubleValue }.reduce(0, +)
    }

    private var totalSpentThisMonth: Double {
        let cal = Calendar.current
        let now = Date()
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return 0 }
        let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        req.predicate = NSPredicate(format: "type == %@ AND date >= %@", "expense", start as NSDate)
        guard let list = try? viewContext.fetch(req) else { return 0 }
        return list.compactMap { $0.amount?.doubleValue }.reduce(0, +)
    }

    private var totalSpentAllTime: Double {
        let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        req.predicate = NSPredicate(format: "type == %@", "expense")
        guard let list = try? viewContext.fetch(req) else { return 0 }
        return list.compactMap { $0.amount?.doubleValue }.reduce(0, +)
    }

    private var budgetHealth: Double {
        guard totalIncome > 0 else { return 0 }
        let remaining = max(0, totalIncome - totalSpentAllTime)
        return min(1, remaining / totalIncome)
    }

    private var daysLeftInMonth: Int {
        let cal = Calendar.current
        let now = Date()
        guard let range = cal.range(of: .day, in: .month, for: now) else { return 1 }
        let today = cal.component(.day, from: now)
        return max(1, range.count - today)
    }

    private var dailyAllowance: Double {
        let totalBalance = envelopes.reduce(0.0) { sum, env in
            sum + NSDecimalNumber(decimal: env.balance(in: viewContext)).doubleValue
        }
        return max(0, totalBalance / Double(daysLeftInMonth))
    }

    private var envelopeSpending: [(name: String, icon: String, amount: Double, color: Color)] {
        let cal = Calendar.current
        let now = Date()
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return [] }

        let colors: [Color] = [
            Color(hex: "2AAA6A"), Color(hex: "E8A838"), Color(hex: "6C8EBF"),
            Color(hex: "E8706A"), Color(hex: "9B72CF"), Color(hex: "5CD6A0"),
            Color(hex: "F5CE6E"), Color(hex: "4ECDC4"), Color(hex: "FF6B6B"),
        ]

        var result: [(name: String, icon: String, amount: Double, color: Color)] = []
        for (i, env) in envelopes.enumerated() {
            let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            req.predicate = NSPredicate(format: "type == %@ AND envelope == %@ AND date >= %@", "expense", env, start as NSDate)
            let spent = (try? viewContext.fetch(req))?.compactMap { $0.amount?.doubleValue }.reduce(0, +) ?? 0
            if spent > 0 {
                result.append((
                    name: env.name ?? "Envelope",
                    icon: env.iconName ?? "envelope.fill",
                    amount: spent,
                    color: colors[i % colors.count]
                ))
            }
        }
        return result.sorted { $0.amount > $1.amount }
    }

    private var savingStreak: Int {
        let cal = Calendar.current
        let now = Date()
        var streak = 0
        for daysBack in 0..<60 {
            guard let day = cal.date(byAdding: .day, value: -daysBack, to: now) else { break }
            let dayStart = cal.startOfDay(for: day)
            guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { break }

            let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            req.predicate = NSPredicate(format: "type == %@ AND date >= %@ AND date < %@", "expense", dayStart as NSDate, dayEnd as NSDate)
            let daySpent = (try? viewContext.fetch(req))?.compactMap { $0.amount?.doubleValue }.reduce(0, +) ?? 0

            if daySpent <= dailyAllowance {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var formatter: NumberFormatter {
        CurrencySettings.formatter(code: currencyCode)
    }

    private func fmtCurrency(_ value: Double) -> String {
        formatter.string(from: NSDecimalNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Budget Health Gauge
                    budgetHealthGauge
                        .padding(.horizontal, 20)
                        .offset(y: appeared ? 0 : 40)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: appeared)

                    // MARK: - Daily Allowance + Streak
                    HStack(spacing: 12) {
                        dailyAllowanceCard
                        streakCard
                    }
                    .padding(.horizontal, 20)
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.12), value: appeared)

                    // MARK: - Spending Donut
                    if !envelopeSpending.isEmpty {
                        spendingDonutSection
                            .padding(.horizontal, 20)
                            .offset(y: appeared ? 0 : 40)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.24), value: appeared)
                    }

                    // MARK: - Monthly Summary
                    monthlySummaryCard
                        .padding(.horizontal, 20)
                        .offset(y: appeared ? 0 : 40)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.36), value: appeared)

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .background(AppColors.background(colorScheme: colorScheme))
            .navigationTitle("Budget")
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                    animatedHealth = CGFloat(budgetHealth)
                }
            }
        }
    }

    // MARK: - Budget Health Gauge

    private var budgetHealthGauge: some View {
        VStack(spacing: 16) {
            Text("Budget Health")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.secondaryText)

            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        Color(UIColor.tertiarySystemFill),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(135))

                // Animated progress arc
                Circle()
                    .trim(from: 0, to: animatedHealth * 0.75)
                    .stroke(
                        AngularGradient(
                            colors: [healthColor.opacity(0.6), healthColor],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(135))
                    .shadow(color: healthColor.opacity(0.4), radius: 8, x: 0, y: 0)

                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(animatedHealth * 100))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    Text("of 100")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                    Text(healthLabel)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(healthColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(healthColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(height: 220)
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Budget health \(Int(budgetHealth * 100)) percent, \(healthLabel)")
    }

    private var healthColor: Color {
        if budgetHealth >= 0.6 { return AppColors.primaryAccent }
        if budgetHealth >= 0.3 { return AppColors.warning }
        return AppColors.critical
    }

    private var healthLabel: String {
        if budgetHealth >= 0.75 { return "Excellent" }
        if budgetHealth >= 0.5 { return "Good" }
        if budgetHealth >= 0.25 { return "Careful" }
        return "Critical"
    }

    // MARK: - Daily Allowance

    private var dailyAllowanceCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundStyle(AppColors.primaryAccent)

            Text(fmtCurrency(dailyAllowance))
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("Daily\nallowance")
                .font(.caption2)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily allowance: \(fmtCurrency(dailyAllowance))")
    }

    // MARK: - Saving Streak

    private var streakCard: some View {
        VStack(spacing: 8) {
            ZStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(
                        savingStreak >= 7
                            ? LinearGradient(colors: [.orange, .red], startPoint: .bottom, endPoint: .top)
                            : LinearGradient(colors: [AppColors.warning, AppColors.warning], startPoint: .bottom, endPoint: .top)
                    )
            }

            Text("\(savingStreak)")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(savingStreak == 1 ? "Day\nstreak" : "Days\nstreak")
                .font(.caption2)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Saving streak: \(savingStreak) days")
    }

    // MARK: - Spending Donut

    private var spendingDonutSection: some View {
        let total = envelopeSpending.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 16) {
            Label("Spending this month", systemImage: "chart.pie.fill")
                .font(.subheadline)
                .fontWeight(.semibold)

            ZStack {
                // Donut segments
                ForEach(Array(envelopeSpending.enumerated()), id: \.element.name) { index, item in
                    let (start, end) = segmentAngles(index: index, total: total)
                    let isSelected = selectedSegment == item.name

                    Circle()
                        .trim(from: appeared ? start : 0, to: appeared ? end : 0)
                        .stroke(
                            item.color,
                            style: StrokeStyle(lineWidth: isSelected ? 32 : 24, lineCap: .butt)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(isSelected ? 1.06 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
                        .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1 + 0.3), value: appeared)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSegment = selectedSegment == item.name ? nil : item.name
                            }
                        }
                }

                // Center label
                VStack(spacing: 2) {
                    if let sel = selectedSegment, let item = envelopeSpending.first(where: { $0.name == sel }) {
                        Image(systemName: item.icon)
                            .font(.title3)
                            .foregroundStyle(item.color)
                        Text(item.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(fmtCurrency(item.amount))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(item.color)
                    } else {
                        Text(fmtCurrency(total))
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Total")
                            .font(.caption2)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedSegment)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Spending donut chart. Total: \(fmtCurrency(total)). \(envelopeSpending.map { "\($0.name): \(fmtCurrency($0.amount))" }.joined(separator: ", "))")

            // Legend
            VStack(spacing: 8) {
                ForEach(envelopeSpending, id: \.name) { item in
                    let pct = total > 0 ? item.amount / total * 100 : 0
                    let isSelected = selectedSegment == item.name

                    HStack(spacing: 10) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Image(systemName: item.icon)
                            .font(.caption)
                            .foregroundStyle(item.color)
                            .frame(width: 18)
                        Text(item.name)
                            .font(.caption)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .lineLimit(1)
                        Spacer()
                        Text(fmtCurrency(item.amount))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text("(\(Int(pct))%)")
                            .font(.caption2)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(isSelected ? item.color.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSegment = selectedSegment == item.name ? nil : item.name
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func segmentAngles(index: Int, total: Double) -> (CGFloat, CGFloat) {
        guard total > 0 else { return (0, 0) }
        var start: Double = 0
        for i in 0..<index {
            start += envelopeSpending[i].amount / total
        }
        let end = start + envelopeSpending[index].amount / total
        let gap: Double = 0.005
        return (CGFloat(start + gap), CGFloat(end - gap))
    }

    // MARK: - Monthly Summary

    private var monthlySummaryCard: some View {
        let cal = Calendar.current
        let now = Date()
        let day = cal.component(.day, from: now)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let monthProgress = Double(day) / Double(daysInMonth)

        return VStack(spacing: 14) {
            HStack {
                Label("Month progress", systemImage: "calendar")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(day) of \(daysInMonth) days")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            // Month progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 10)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primaryAccent.opacity(0.7), AppColors.primaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: appeared ? geo.size.width * monthProgress : 0, height: 10)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: appeared)
                }
            }
            .frame(height: 10)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spent this month")
                        .font(.caption2)
                        .foregroundStyle(AppColors.secondaryText)
                    Text(fmtCurrency(totalSpentThisMonth))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.critical)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total remaining")
                        .font(.caption2)
                        .foregroundStyle(AppColors.secondaryText)
                    Text(fmtCurrency(max(0, totalIncome - totalSpentAllTime)))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primaryAccent)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
