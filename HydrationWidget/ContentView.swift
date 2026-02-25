import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HydrationViewModel()
    @State private var showingPaywall = false
    
    let waterAmounts = [8, 16, 24, 32] // oz
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: min(CGFloat(viewModel.todayOz) / CGFloat(viewModel.goalOz), 1.0))
                        .stroke(Color.blue.gradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: viewModel.todayOz)
                    
                    VStack(spacing: 4) {
                        Text("\(viewModel.todayOz)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("/ \(viewModel.goalOz) oz")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Quick Add Buttons
                VStack(spacing: 12) {
                    Text("Quick Add")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(waterAmounts, id: \.self) { amount in
                            Button(action: { viewModel.addWater(amount) }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "drop.fill")
                                        .font(.title2)
                                    Text("\(amount) oz")
                                        .font(.caption)
                                }
                                .frame(width: 70, height: 70)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // History
                List {
                    Section("Today's Log") {
                        if viewModel.logs.isEmpty {
                            Text("No water logged yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.logs) { log in
                                HStack {
                                    Image(systemName: "drop.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("\(log.amount) oz")
                                    Spacer()
                                    Text(log.time, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onDelete(perform: viewModel.deleteLog)
                        }
                    }
                    
                    Section {
                        Button(action: { showingPaywall = true }) {
                            HStack {
                                Image(systemName: viewModel.isPro ? "checkmark.circle.fill" : "crown.fill")
                                Text(viewModel.isPro ? "Pro Active" : "Unlock Advanced Stats - $0.99")
                            }
                            .foregroundColor(viewModel.isPro ? .green : .orange)
                        }
                        .disabled(viewModel.isPro)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Hydration")
            .sheet(isPresented: $showingPaywall) {
                PaywallView(viewModel: viewModel)
            }
        }
    }
}

struct PaywallView: View {
    @ObservedObject var viewModel: HydrationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "drop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Hydration Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.blue); Text("Weekly & monthly stats") }
                    HStack { Image(systemName: "bell.badge").foregroundColor(.blue); Text("Smart reminders") }
                    HStack { Image(systemName: "target").foregroundColor(.blue); Text("Custom daily goals") }
                    HStack { Image(systemName: "cup.and.saucer").foregroundColor(.blue); Text("Track coffee, tea, etc.") }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("$0.99")
                        .font(.system(size: 48, weight: .bold))
                    
                    Text("One-time purchase")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    viewModel.purchasePro()
                    dismiss()
                }) {
                    Text("Purchase Pro")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Close") { dismiss() })
        }
    }
}
