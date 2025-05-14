//
//  Article.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

struct Article: Identifiable, Codable {
    var id: String { title + source }
    let title: String
    let source: String
    let url: URL
    let publishedAt: Date
    
    // For backward compatibility
    var description: String { title }
}

// Extension pour les données mock
extension Article {
    static let mock: [Article] = [
        .init(
            title: "Apple annonce de nouveaux résultats records",
            source: "Financial Times",
            url: URL(string: "https://example.com/news/1")!,
            publishedAt: Date()
        ),
        .init(
            title: "Microsoft dépasse les attentes pour le quatrième trimestre",
            source: "Wall Street Journal",
            url: URL(string: "https://example.com/news/2")!,
            publishedAt: Date().addingTimeInterval(-86400) // -1 jour
        ),
        .init(
            title: "Les valeurs technologiques en hausse suite aux bons résultats",
            source: "Bloomberg",
            url: URL(string: "https://example.com/news/3")!,
            publishedAt: Date().addingTimeInterval(-172800) // -2 jours
        )
    ]
    
    static func getMockNews(for symbol: String) -> [Article] {
        let currentDate = Date()
        let daySeconds: TimeInterval = 86400
        
        // Common financial news sources
        let sources = ["Financial Times", "Bloomberg", "CNBC", "Wall Street Journal", "MarketWatch", "Reuters", "The Economist", "Yahoo Finance", "Barron's", "Morningstar", "Les Échos", "Le Figaro", "Handelsblatt", "Il Sole 24 Ore", "Expansion", "Het Financieele Dagblad"]
        
        // Recent general news topics with company-specific mentions
        let topics: [(title: String, source: String, days: Int)] = [
            ("\(symbol) Announces Strong Q2 Earnings, Beating Market Expectations", sources[0], 0),
            ("\(symbol) Invests €2 Billion in AI and Cloud Infrastructure", sources[1], 1),
            ("Analysts Raise Price Target for \(symbol) Following Product Launch", sources[2], 1),
            ("\(symbol) Stock Rebounds After Fed Rate Decision", sources[3], 2),
            ("Tech Stocks Rally: \(symbol) Leads Gains on Positive Industry Outlook", sources[4], 2),
            ("Supply Chain Challenges: How \(symbol) is Navigating Global Disruptions", sources[5], 3),
            ("ESG Spotlight: \(symbol)'s New Sustainability Initiatives Draw Investor Interest", sources[6], 4),
            ("\(symbol) Expands Operations in Asian Markets with New Strategic Partnership", sources[7], 5),
            ("Market Volatility: Is \(symbol) a Safe Haven Investment?", sources[8], 6),
            ("CEO of \(symbol) Featured in Exclusive Interview on Future Strategy", sources[9], 7),
            ("Industry Analysis: How \(symbol) Compares to Competitors in Current Market", sources[10], 8),
            ("Breaking: \(symbol) Announces Major Acquisition in Tech Space", sources[11], 9)
        ]
        
        // Company-specific news items
        var companyNews: [(title: String, source: String, days: Int)] = []
        switch symbol {
        case "AAPL":
            companyNews = [
                ("Apple's iPhone 16 Expected to Feature Advanced AI Capabilities", "Bloomberg", 0),
                ("Apple Services Revenue Hits New Highs as Hardware Sales Stabilize", "CNBC", 1),
                ("How Apple's Vision Pro is Reshaping the AR/VR Landscape", "TechCrunch", 2),
                ("Apple and OpenAI Partnership Rumors Send Stock Soaring", "Financial Times", 3)
            ]
        case "MSFT":
            companyNews = [
                ("Microsoft Cloud Revenue Surges as AI Integration Deepens", "Wall Street Journal", 0),
                ("Microsoft 365 Copilot Adoption Exceeds Expectations", "The Information", 1),
                ("Microsoft's Gaming Division Shows Strong Growth Post-Activision Acquisition", "GameSpot", 2),
                ("Microsoft Overtakes Apple as World's Most Valuable Company", "Reuters", 3)
            ]
        case "GOOGL":
            companyNews = [
                ("Google's Gemini AI Model Shows Promising Results Against Competitors", "The Verge", 0),
                ("Alphabet's Ad Revenue Rebounds as Digital Marketing Spend Increases", "AdWeek", 1),
                ("Google Cloud Platform Gains Market Share Against AWS and Azure", "TechTarget", 2),
                ("Antitrust Concerns Ease as Google Makes Platform Changes", "Politico", 3)
            ]
        case "AMZN":
            companyNews = [
                ("Amazon Prime Day Sets New Sales Record Amid Economic Uncertainty", "CNBC", 0),
                ("AWS Maintains Cloud Dominance Despite Increasing Competition", "InfoWorld", 1),
                ("Amazon's Healthcare Ambitions Expand with New Pharmacy Initiatives", "Healthcare IT News", 2),
                ("Amazon Logistics Network Optimization Leads to Margin Improvements", "Supply Chain Dive", 3)
            ]
        case "TSLA":
            companyNews = [
                ("Tesla Cybertruck Production Ramps Up as Demand Remains Strong", "Electrek", 0),
                ("Tesla's Full Self-Driving Software Reaches New Milestone", "CleanTechnica", 1),
                ("Tesla Energy Storage Deployments Double Year-Over-Year", "Bloomberg", 2),
                ("Tesla Opens New Gigafactory in Mexico, Expanding Production Capacity", "Automotive News", 3)
            ]
        // European companies
        case "ASML":
            companyNews = [
                ("ASML Boosts Production Capacity as Chip Demand Surges", "Bloomberg", 0),
                ("ASML Reports Record Order Backlog as Semiconductor Industry Expands", "Reuters", 1),
                ("ASML's EUV Technology Powers Next-Generation Chip Manufacturing", "Financial Times", 2),
                ("ASML to Open New R&D Center in Silicon Valley", "Het Financieele Dagblad", 3)
            ]
        case "LVMH.PA":
            companyNews = [
                ("LVMH Reports Strong Luxury Goods Sales Despite Economic Headwinds", "Les Échos", 0),
                ("LVMH's Chinese Market Share Growing as Post-Pandemic Tourism Resumes", "Bloomberg", 1),
                ("Bernard Arnault: 'Luxury Remains Resilient in Uncertain Times'", "Financial Times", 2),
                ("LVMH Expands Manufacturing Footprint with New Italian Facility", "Le Figaro", 3)
            ]
        case "SAP":
            companyNews = [
                ("SAP Cloud Revenue Grows 25% as Businesses Accelerate Digital Transformation", "Handelsblatt", 0),
                ("SAP's Business AI Suite Gains Traction Among Enterprise Clients", "Reuters", 1),
                ("SAP Completes Successful Migration of Legacy Customers to S/4HANA", "Bloomberg", 2),
                ("SAP Forms Strategic Partnership with Microsoft on Cloud Infrastructure", "Financial Times", 3)
            ]
        case "SIE.DE":
            companyNews = [
                ("Siemens Energy Division Reports Better Than Expected Results", "Handelsblatt", 0),
                ("Siemens Digital Industries Leads Automation Revolution", "Bloomberg", 1),
                ("Siemens Invests €2 Billion in Smart Infrastructure Projects", "Financial Times", 2),
                ("Siemens Mobility Wins Major Rail Contract in Egypt", "Reuters", 3)
            ]
        case "NOVN.SW":
            companyNews = [
                ("Novartis' New Cancer Treatment Receives FDA Approval", "Reuters", 0),
                ("Novartis Reports Positive Phase III Results for Heart Failure Drug", "Financial Times", 1),
                ("Novartis to Spin Off Generic Drug Division Sandoz", "Bloomberg", 2),
                ("Novartis CEO Outlines Strategy for Focused Pharmaceutical Company", "Neue Zürcher Zeitung", 3)
            ]
        case "NOVO-B.CO":
            companyNews = [
                ("Novo Nordisk Weight Loss Drug Wegovy Faces Supply Constraints Amid Surging Demand", "Reuters", 0),
                ("Novo Nordisk Market Value Surpasses $500 Billion on Obesity Drug Success", "Financial Times", 1),
                ("Novo Nordisk Expands Manufacturing Capacity for GLP-1 Medications", "Bloomberg", 2),
                ("Novo Nordisk Foundation Makes Record Research Grant for Diabetes Research", "Børsen", 3)
            ]
        case "AZN.L":
            companyNews = [
                ("AstraZeneca's Cancer Immunotherapy Portfolio Shows Strong Growth", "Financial Times", 0),
                ("AstraZeneca Completes Acquisition of Biotech Firm for Rare Disease Treatments", "Reuters", 1),
                ("AstraZeneca and Oxford Partner on New mRNA Platform", "The Guardian", 2),
                ("AstraZeneca CEO: 'Our Pipeline Has Never Been Stronger'", "Bloomberg", 3)
            ]
        // Actions asiatiques
        case "9988.HK", "BABA":
            companyNews = [
                ("Alibaba's Cloud Business Faces Intense Competition From Domestic Rivals", "South China Morning Post", 0),
                ("Alibaba Restructures E-commerce Division Amid Slowing Growth", "Bloomberg", 1),
                ("Regulatory Headwinds Continue for Alibaba in China", "Financial Times", 2),
                ("Alibaba Struggles to Regain Investor Confidence After Years of Scrutiny", "Wall Street Journal", 3)
            ]
        case "0700.HK", "TCEHY":
            companyNews = [
                ("Tencent's Gaming Revenue Stabilizes After Regulatory Challenges", "Reuters", 0),
                ("Tencent's WeChat Faces New Data Privacy Regulations", "South China Morning Post", 1),
                ("Tencent Expands International Investments as Domestic Growth Slows", "Bloomberg", 2),
                ("Tencent Commits $15 Billion to Chinese Government's 'Common Prosperity' Initiative", "Financial Times", 3)
            ]
        case "005930.KS":
            companyNews = [
                ("Samsung Electronics Reports Surge in Memory Chip Demand", "Korea Herald", 0),
                ("Samsung to Invest $10 Billion in New Semiconductor Plant", "Reuters", 1), 
                ("Samsung Expands AI Features Across Consumer Electronics Line", "Bloomberg", 2),
                ("Samsung's Foldable Phones Gain Market Share Against Competitors", "CNBC", 3)
            ]
        // Mauvaises actions
        case "PLTR":
            companyNews = [
                ("Palantir Faces Criticism Over Government Contracts and Privacy Concerns", "The Guardian", 0),
                ("Palantir's Commercial Business Growth Disappoints Investors", "Wall Street Journal", 1),
                ("Analysts Question Palantir's Path to Profitability", "Bloomberg", 2),
                ("Palantir Stock Downgraded as Competition Intensifies", "CNBC", 3)
            ]
        case "RIVN":
            companyNews = [
                ("Rivian Slashes Production Targets Amid Supply Chain Challenges", "Reuters", 0),
                ("Rivian Faces Cash Burn Concerns as EV Market Competition Heats Up", "Bloomberg", 1),
                ("Amazon Reduces Rivian Delivery Van Orders Amid Economic Uncertainty", "Wall Street Journal", 2),
                ("Rivian Struggles with Manufacturing Efficiency, Delays New Models", "TechCrunch", 3)
            ]
        case "GME":
            companyNews = [
                ("GameStop Reports Another Quarterly Loss as Digital Shift Struggles", "Reuters", 0),
                ("GameStop's Strategy Pivot Fails to Impress Wall Street Analysts", "Bloomberg", 1),
                ("Meme Stock Era Fades as GameStop Trading Volume Plummets", "Wall Street Journal", 2),
                ("GameStop's NFT Marketplace Shows Minimal Revenue Impact", "The Verge", 3)
            ]
        case "WISH":
            companyNews = [
                ("ContextLogic (Wish) User Base Continues to Shrink, Revenue Concerns Mount", "Reuters", 0),
                ("Wish Platform Struggles with Product Quality Issues and Consumer Trust", "Bloomberg", 1),
                ("Wish Delisted from App Stores in Several Countries Over Counterfeit Concerns", "TechCrunch", 2),
                ("Wish Considers Strategic Alternatives as Business Model Falters", "Wall Street Journal", 3)
            ]
        case "3333.HK":
            companyNews = [
                ("China Evergrande Defaults on International Bonds", "Financial Times", 0),
                ("Evergrande Crisis Continues to Shake Chinese Real Estate Sector", "Reuters", 1),
                ("China Evergrande's Restructuring Plan Faces Creditor Pushback", "Bloomberg", 2),
                ("Evergrande Asset Sales Insufficient to Address Massive Debt Load", "South China Morning Post", 3)
            ]
        case "HOOD":
            companyNews = [
                ("Robinhood Reports Declining User Growth and Transaction Revenue", "CNBC", 0),
                ("Robinhood Faces Class Action Lawsuit from Meme Stock Traders", "Reuters", 1),
                ("Cryptocurrency Revenue Plummets at Robinhood Amid Market Downturn", "Bloomberg", 2),
                ("Robinhood Lays Off 23% of Staff as Trading Volume Crashes", "Wall Street Journal", 3)
            ]
        default:
            // No company-specific news, will use generic topics
            break
        }
        
        // Combine and sort by recency
        var allNews = topics
        allNews.append(contentsOf: companyNews)
        allNews.sort { $0.days < $1.days }
        
        // Create Article objects
        return allNews.prefix(12).map { news in
            Article(
                title: news.title,
                source: news.source,
                url: URL(string: "https://example.com/news/\(symbol)/\(news.days)")!,
                publishedAt: currentDate.addingTimeInterval(-Double(news.days) * daySeconds)
            )
        }
    }
}
