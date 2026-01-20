//
//  QuickAccessCustomizationView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/14/26.
//

import SwiftUI

struct QuickAccessCustomizationView: View {
    @Bindable var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var pinnedItems: [QuickAccessItem]
    @State private var availableItems: [QuickAccessItem]
    
    init(appModel: AppModel) {
        self.appModel = appModel
        _pinnedItems = State(initialValue: appModel.quickAccessItems.filter { $0.isPinned }.sorted { $0.order < $1.order })
        _availableItems = State(initialValue: appModel.quickAccessItems.filter { !$0.isPinned })
    }
    
    var canAddMore: Bool {
        pinnedItems.count < 10
    }
    
    var canRemoveMore: Bool {
        pinnedItems.count > 3
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Customize Quick Access")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Done") {
                    saveChanges()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)
            
            Divider()
            
            HStack(alignment: .top, spacing: 20) {
                // Pinned Items
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Pinned Items")
                            .font(.headline)
                        Spacer()
                        Text("\(pinnedItems.count) / 10")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("These items appear in your Quick Access section. Drag to reorder.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    List {
                        ForEach(pinnedItems) { item in
                            QuickAccessItemRow(item: item, isPinned: true, canRemove: canRemoveMore) {
                                removeItem(item)
                            }
                        }
                        .onMove { source, destination in
                            pinnedItems.move(fromOffsets: source, toOffset: destination)
                            updateOrders()
                        }
                    }
                    .frame(minHeight: 300)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Available Items
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Available Tools")
                            .font(.headline)
                        Spacer()
                        Text("\(availableItems.count)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Click the + button to add items to Quick Access.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    List {
                        ForEach(availableItems) { item in
                            QuickAccessItemRow(item: item, isPinned: false, canAdd: canAddMore) {
                                addItem(item)
                            }
                        }
                    }
                    .frame(minHeight: 300)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            
            Divider()
            
            // Footer
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 12))
                    Text("Minimum 3 items, maximum 10 items")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Reset to Default") {
                    resetToDefault()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }
            .padding(20)
        }
        .frame(width: 800, height: 600)
    }
    
    private func addItem(_ item: QuickAccessItem) {
        guard canAddMore else { return }
        
        if let index = availableItems.firstIndex(where: { $0.id == item.id }) {
            availableItems.remove(at: index)
            var mutableItem = item
            mutableItem.isPinned = true
            mutableItem.order = pinnedItems.count
            pinnedItems.append(mutableItem)
        }
    }
    
    private func removeItem(_ item: QuickAccessItem) {
        guard canRemoveMore else { return }
        
        if let index = pinnedItems.firstIndex(where: { $0.id == item.id }) {
            pinnedItems.remove(at: index)
            var mutableItem = item
            mutableItem.isPinned = false
            availableItems.append(mutableItem)
            updateOrders()
        }
    }
    
    private func updateOrders() {
        for (index, _) in pinnedItems.enumerated() {
            pinnedItems[index].order = index
        }
    }
    
    private func saveChanges() {
        appModel.quickAccessItems = pinnedItems + availableItems
        appModel.saveQuickAccessItems()
    }
    
    private func resetToDefault() {
        let defaultItems = QuickAccessItem.defaultItems
        pinnedItems = defaultItems.filter { $0.isPinned }
        availableItems = defaultItems.filter { !$0.isPinned }
    }
}

struct QuickAccessItemRow: View {
    let item: QuickAccessItem
    let isPinned: Bool
    var canAdd: Bool = true
    var canRemove: Bool = true
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(.blue)
                .font(.system(size: 16))
                .frame(width: 24)
            
            Text(item.title)
                .font(.system(size: 13))
            
            Spacer()
            
            if isPinned {
                Button(action: action) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(canRemove ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canRemove)
                .help(canRemove ? "Remove from Quick Access" : "Minimum 3 items required")
            } else {
                Button(action: action) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(canAdd ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
                .help(canAdd ? "Add to Quick Access" : "Maximum 10 items reached")
            }
        }
        .padding(.vertical, 4)
    }
}
