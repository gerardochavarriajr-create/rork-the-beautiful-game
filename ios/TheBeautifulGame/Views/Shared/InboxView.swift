import SwiftUI

struct InboxView: View {
    @Bindable var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: NewsItemType?
    @State private var selectedArticle: NewsArticle?

    private var filteredNews: [NewsArticle] {
        if let filter = selectedFilter {
            return gameManager.news.filter { $0.type == filter }
        }
        return gameManager.news
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChips
                newsList
            }
            .background(AppTheme.background)
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedArticle) { article in
                NewspaperArticleView(article: article)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Button {
                    selectedFilter = nil
                } label: {
                    Text("All")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedFilter == nil ? AppTheme.pitchGreen : AppTheme.surfaceElevated, in: Capsule())
                        .foregroundStyle(selectedFilter == nil ? .white : AppTheme.textSecondary)
                }

                ForEach([NewsItemType.newspaper, .matchResult, .transfer, .injury, .board], id: \.self) { type in
                    Button {
                        selectedFilter = selectedFilter == type ? nil : type
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption2)
                            Text(type.rawValue.capitalized)
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedFilter == type ? AppTheme.pitchGreen : AppTheme.surfaceElevated, in: Capsule())
                        .foregroundStyle(selectedFilter == type ? .white : AppTheme.textSecondary)
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
        .padding(.vertical, 10)
    }

    private var newsList: some View {
        Group {
            if filteredNews.isEmpty {
                ContentUnavailableView("No News", systemImage: "newspaper", description: Text("News will appear as you progress through the season."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredNews) { article in
                            Button {
                                markAsRead(article)
                                selectedArticle = article
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: article.type.icon)
                                        .font(.title3)
                                        .foregroundStyle(article.isRead ? AppTheme.textSecondary : AppTheme.golden)
                                        .frame(width: 36)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(article.headline)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.textPrimary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        HStack(spacing: 8) {
                                            Text(article.source)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.pitchGreen)
                                            Text(article.date)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    if !article.isRead {
                                        Circle()
                                            .fill(AppTheme.pitchGreen)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(14)
                                .background(AppTheme.surface, in: .rect(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func markAsRead(_ article: NewsArticle) {
        if let idx = gameManager.news.firstIndex(where: { $0.id == article.id }) {
            gameManager.news[idx].isRead = true
        }
    }
}

struct NewspaperArticleView: View {
    let article: NewsArticle
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(article.headline)
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    if let sub = article.subheadline {
                        Text(sub)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(AppTheme.textSecondary)
                            .italic()
                    }

                    Divider().background(AppTheme.surfaceElevated)

                    Text(article.body)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineSpacing(6)

                    Divider().background(AppTheme.surfaceElevated)

                    HStack {
                        Text("Source: \(article.source)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .italic()
                        Spacer()
                        Text(article.date)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
