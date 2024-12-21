//
//  PortfolioView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import SwiftUI

struct PortfolioView: View {
    // MARK: - Properties
    @StateObject private var viewModel = PortfolioViewModel()
    @State private var showAddTransactionView = false
    @State private var expandedRows: Set<String> = []
    @State private var swipedTransaction: Transaction?
    
    // MARK: - Body
    var body: some View {
        BaseView(errorMessage: $viewModel.errorMessage) {
            NavigationView {
                VStack {
                    makePortfolioHeaderView()
                    makePortfolioContentView()
                }
                .navigationTitle("Portfolio")
            }
        }
        .sheet(isPresented: $showAddTransactionView) {
            AddTransactionView(didAddTransaction: { newTransaction in
                viewModel.addTransaction(newTransaction)
            })
            .presentationDetents([.medium])
            .presentationCornerRadius(36)
        }
        .sheet(item: $swipedTransaction, onDismiss: {
            swipedTransaction = nil
        }) { transaction in
            AddTransactionView(transaction: transaction, didEditTransaction: { updatedTransaction in
                viewModel.editTransaction(updatedTransaction)
            })
            .presentationDetents([.medium])
            .presentationCornerRadius(36)
        }
        .onAppear {
            viewModel.fetchPortfolios()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func makePortfolioHeaderView() -> some View {
        VStack(spacing: 8) {
            Text(viewModel.totalValue.formattedAsCurrency())
                .font(.title).bold()
                .foregroundColor(.wmPink)
            
            HStack {
                Text(viewModel.portfolioChangePercentage.formattedAsPercentage())
                    .font(.footnote).bold()
                    .foregroundColor(.gray)
                
                Text(viewModel.portfolioChangeValue.formattedAsCurrency(includePlusSign: true))
                    .font(.footnote).bold()
                    .foregroundColor(.gray)
                
                Text(viewModel.selectedTimeline.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .onTapGesture {
                viewModel.toggleSelectedTimeline()
            }
        }
        .padding(.vertical, 32)
    }
    
    @ViewBuilder
    private func makePortfolioContentView() -> some View {
        List {
            ForEach(viewModel.groupedTransactions, id: \.coin.id) { group in
                makeTransactionsSummaryView(for: group, isExpanded: expandedRows.contains(group.coin.id))
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            toggleRowExpansion(for: group.coin.id)
                        }
                    }
                
                if expandedRows.contains(group.coin.id) {
                    makeExpandedTransactionsView(for: group)
                }
            }
            
            Button {
                showAddTransactionView.toggle()
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Add Transaction")
                }
                .frame(maxWidth: .infinity)
            }
            .listRowSeparator(.hidden)
            .buttonStyle(.borderless)
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.fetchPortfolios()
        }
    }
    
    @ViewBuilder
    private func makeTransactionsSummaryView(for group: CoinTransactions, isExpanded: Bool) -> some View {
        HStack(spacing: 16) {
            CoinImageView(
                imageData: group.coin.imageData,
                placeholder: group.coin.symbol,
                size: 36
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.coin.symbol.uppercased())
                    .font(.footnote).bold()
                
                Text(group.totalQuantity.formattedAsQuantity())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(group.totalValue.formattedAsCurrency())
                .font(.caption).bold()
            
            Image(systemName: "chevron.up")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(.gray)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .listRowSeparator(.hidden)
        .swipeActions {
            Button(role: .destructive) {
                viewModel.deleteTransactions(for: group.coin.id)
            } label: {
                Image("TrashIcon")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func makeExpandedTransactionsView(for group: CoinTransactions) -> some View {
        ForEach(group.transactions.keys.sorted(by: { $0 > $1 }), id: \.self) { date in
            Section(date.formatted(as: .dateOnly)) {
                ForEach(group.transactions[date] ?? [], id: \.id) { transaction in
                    makeTransactionView(transaction)
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.deleteTransaction(transaction.id)
                            } label: {
                                Image("TrashIcon")
                            }
                            
                            Button {
                                swipedTransaction = transaction
                            } label: {
                                Image("EditIcon")
                            }
                            .tint(.blue)
                        }
                }
            }
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    private func makeTransactionView(_ transaction: Transaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.rawValue)
                    .font(.subheadline).bold()
                
                Text(transaction.pricePerCoin.formattedAsCurrency())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    let isDeductiveTransaction = viewModel.isDeductiveTransaction(transaction.type)
                    Text(transaction.quantity.formattedAsQuantity(includeMinusSign: isDeductiveTransaction))
                        .font(.footnote).bold()
                    
                    if let coin = transaction.coin {
                        Text(coin.symbol.uppercased())
                            .font(.footnote).bold()
                    }
                }
                
                Text(transaction.totalCost.formattedAsCurrency())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func toggleRowExpansion(for key: String) {
        if expandedRows.contains(key) {
            expandedRows.remove(key)
        } else {
            expandedRows.insert(key)
        }
    }
}

// MARK: - Previews
struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
    }
}
