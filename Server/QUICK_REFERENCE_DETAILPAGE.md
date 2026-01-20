# Quick Reference: DetailPageContainer Usage

## Import
The `DetailPageContainer` and `SummaryCardView` are defined in `StorageView.swift` and can be used across all view files.

## Basic Usage

```swift
struct MyOverviewView: View {
    var body: some View {
        DetailPageContainer {
            // Your content here - no VStack wrapper needed
            // DetailPageContainer provides the VStack
            
            HeaderSection()
            KPICardsSection()
            ChartsSection()
            DetailSection()
        }
    }
}
```

## Page Header Pattern

```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Page Title")
        .font(.system(size: 28, weight: .bold))
    Text("Page description")
        .font(.subheadline)
        .foregroundStyle(.secondary)
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 20)
.padding(.top, 16)
```

## KPI Cards Pattern

```swift
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)
], spacing: 12) {
    SummaryCardView(
        title: "Card Title",
        value: "123",
        icon: "chart.bar.fill",
        color: .blue
    )
    // More cards...
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 20)
```

## Content Section Pattern

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Section Title")
        .font(.headline)
    
    // Section content (chart, cards, etc.)
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 20)
```

## Chart Pattern

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Chart Title")
        .font(.headline)
    
    MyChartView()
        .frame(maxWidth: .infinity)
        .frame(height: 280)
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 20)
```

## Adaptive Grid for Cards

```swift
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 12)
], spacing: 12) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 20)
```

## Navigation Split View Integration

```swift
struct MyView: View {
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                // items
            }
            .navigationTitle("Title")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            Group {
                if let selected = selectedItem {
                    ItemDetailView(item: selected)
                } else {
                    OverviewView() // Uses DetailPageContainer
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
```

## Detail View Pattern

```swift
struct ItemDetailView: View {
    let item: Item
    
    var body: some View {
        DetailPageContainer {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "icon")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 22, weight: .bold))
                    Text(item.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Properties section
            VStack(alignment: .leading, spacing: 12) {
                Text("Properties")
                    .font(.headline)
                
                // Property rows
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            // Actions section
            VStack(spacing: 8) {
                Button("Action 1") { }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
    }
}
```

## Summary Card Customization

```swift
SummaryCardView(
    title: "Metric Name",      // Keep short, uses lineLimit(1)
    value: "1.2K",              // Main value, uses lineLimit(1) with minimumScaleFactor
    icon: "chart.bar.fill",     // SF Symbol name
    color: .blue                // Icon and theme color
)
```

## Do's and Don'ts

### ✅ DO
- Use `DetailPageContainer` for all overview and detail pages
- Apply `.frame(maxWidth: .infinity, alignment: .leading)` to all major sections
- Use adaptive grids: `GridItem(.adaptive(minimum: X, maximum: Y))`
- Use consistent horizontal padding (20px)
- Use `.topLeading` for page-level alignment, `.leading` for sections

### ❌ DON'T
- Don't wrap DetailPageContainer content in another ScrollView
- Don't forget `.frame(maxWidth: .infinity)` on content sections
- Don't use fixed-width grids for KPI cards
- Don't nest padding redundantly
- Don't use `.fixedSize()` on content that should expand
- Don't set explicit width values on expandable content

## Spacing Guidelines

| Element | Value | Purpose |
|---------|-------|---------|
| Section vertical spacing | 20pt | Between major page sections |
| Card grid spacing | 12pt | Between KPI cards |
| Section item spacing | 8-12pt | Within a section |
| Horizontal padding | 20pt | Page margins |
| Top padding (first section) | 16pt | Header top margin |
| Bottom padding | 20pt | Page bottom margin (in DetailPageContainer) |

## Color Palette for Cards

```swift
.blue     // Primary, capacity, network
.green    // Success, healthy, available
.orange   // Warning, used space
.red      // Critical, error, danger
.purple   // Performance, metrics
.cyan     // Throughput, bandwidth
```

## Chart Height Guidelines

- **Small charts** (distribution, simple bars): 200pt
- **Standard charts** (primary data visualization): 280pt
- **Large charts** (detailed multi-series): 360pt

Always use `.frame(maxWidth: .infinity)` with explicit height.
