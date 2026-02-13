//
//  ExportView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme

    @State private var scope: ExportScope = .all
    @State private var format: ExportFormat = .csv
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    enum ExportScope: String, CaseIterable {
        case all = "All Data"
        case currentMonth = "Current Month"
    }

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Scope") {
                    Picker("Scope", selection: $scope) {
                        ForEach([ExportScope.all, ExportScope.currentMonth], id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach([ExportFormat.csv, ExportFormat.pdf], id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button {
                        generateAndShare()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Generate & Share")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(isExporting)
                    .foregroundStyle(AppColors.primaryAccent)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.primaryAccent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func generateAndShare() {
        isExporting = true
        let url: URL?
        switch format {
        case .csv:
            url = generateCSV()
        case .pdf:
            url = generatePDF()
        }
        isExporting = false
        if let u = url {
            exportURL = u
            showShareSheet = true
        }
    }

    private func generateCSV() -> URL? {
        let (rows, _) = fetchExportData()
        var csv = "date,envelope,type,amount,note\n"
        for row in rows {
            let noteEscaped = (row.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(row.date),\"\(row.envelope)\",\(row.type),\(row.amount),\"\(noteEscaped)\"\n"
        }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("GreenEnvelopes_\(dateString()).csv")
        try? csv.write(to: temp, atomically: true, encoding: .utf8)
        return temp
    }

    private func generatePDF() -> URL? {
        let (rows, _) = fetchExportData()
        let pdfMeta: [String: Any] = [kCGPDFContextCreator as String: "Green Envelopes"]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMeta
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let font = UIFont.systemFont(ofSize: 10)
            var y: CGFloat = 40
            let margin: CGFloat = 40
            for row in rows.prefix(80) {
                let text = "\(row.date)  \(row.envelope)  \(row.type)  \(row.amount)  \(row.note ?? "")"
                (text as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: font])
                y += 18
                if y > 750 {
                    ctx.beginPage()
                    y = 40
                }
            }
        }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("GreenEnvelopes_\(dateString()).pdf")
        try? data.write(to: temp)
        return temp
    }

    private struct ExportRow {
        let date: String
        let envelope: String
        let type: String
        let amount: String
        let note: String?
    }

    private func fetchExportData() -> ([ExportRow], DateInterval?) {
        let cal = Calendar.current
        let now = Date()
        let interval: DateInterval?
        if scope == .currentMonth {
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            interval = DateInterval(start: start, end: now)
        } else {
            interval = nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var rows: [ExportRow] = []

        let allocReq: NSFetchRequest<IncomeAllocation> = IncomeAllocation.fetchRequest()
        if let interval = interval {
            allocReq.predicate = NSPredicate(format: "transaction.date >= %@ AND transaction.date <= %@", interval.start as NSDate, interval.end as NSDate)
        }
        allocReq.sortDescriptors = [NSSortDescriptor(keyPath: \IncomeAllocation.transaction?.date, ascending: true)]
        if let allocs = try? viewContext.fetch(allocReq) {
            for a in allocs {
                let d = a.transaction?.date ?? Date()
                if interval != nil && (d < interval!.start || d > interval!.end) { continue }
                rows.append(ExportRow(
                    date: dateFormatter.string(from: d),
                    envelope: a.envelope?.name ?? "",
                    type: "income",
                    amount: "\(a.amount?.doubleValue ?? 0)",
                    note: a.transaction?.note
                ))
            }
        }

        let trReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        var trPreds = [NSPredicate(format: "type == %@ OR type == %@", "expense", "transfer")]
        if let interval = interval {
            trPreds.append(NSPredicate(format: "date >= %@ AND date <= %@", interval.start as NSDate, interval.end as NSDate))
        }
        trReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: trPreds)
        trReq.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)]
        if let list = try? viewContext.fetch(trReq) {
            for t in list {
                let envName = t.envelope?.name ?? t.sourceEnvelope?.name ?? ""
                rows.append(ExportRow(
                    date: dateFormatter.string(from: t.date ?? Date()),
                    envelope: envName,
                    type: t.type ?? "expense",
                    amount: "\(-(t.amount?.doubleValue ?? 0))",
                    note: t.note
                ))
            }
        }

        rows.sort { (r1, r2) in r1.date < r2.date }
        return (rows, interval)
    }

    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
