//
//  HomebrewDashboardView.swift
//  Homebrew Assistant
//
//  Purpose: Presents the Homebrew dashboard.
//  Owns: Dashboard layout, filter/sort controls, option cards, status display,
//  and progress display.
//  Does not own: Homebrew option metadata, public recipe catalog loading,
//  signed index verification, source policy, internal workflow behavior,
//  recipe preparation state, downloads, saves, verification, or workflow navigation.
//  Uses: HomebrewDashboardController for visible options, filter/sort state,
//  selection bindings, and preparation status mapping.
//

internal import SwiftUI

struct HomebrewDashboardView: View {
    @ObservedObject var controller: HomebrewDashboardController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            controlSection
            optionCards
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "chooseHomebrew.availableHomebrew.sectionTitle"))
                .font(.title2)
                .fontWeight(.semibold)

            Text(String(localized: "chooseHomebrew.availableHomebrew.description"))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
        }
    }

    private var controlSection: some View {
        HStack(alignment: .center) {
            Spacer()

            filterMenu
            sortMenu
        }
    }

    private var optionCards: some View {
        VStack(spacing: 12) {
            ForEach(controller.visibleOptions) { option in
                HomebrewOptionCard(
                    option: option,
                    isSelected: controller.binding(for: option),
                    status: controller.status(for: option)
                )
            }
        }
    }

    private var filterMenu: some View {
        Picker(String(localized: "chooseHomebrew.filter.label"), selection: $controller.selectedCategoryFilter) {
            ForEach(HomebrewCategoryFilter.allCases) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .pickerStyle(.menu)
    }

    private var sortMenu: some View {
        Picker(String(localized: "chooseHomebrew.sort.label"), selection: $controller.selectedSortMode) {
            ForEach(HomebrewSortMode.allCases) { sortMode in
                Text(sortMode.title)
                    .tag(sortMode)
            }
        }
        .pickerStyle(.menu)
    }
}

private struct HomebrewOptionCard: View {
    let option: HomebrewOption
    @Binding var isSelected: Bool
    let status: HomebrewPreparationStatus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $isSelected)
                .labelsHidden()
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                optionSummary
                statusSummary
                progressView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var optionSummary: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: option.systemImageName)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(option.name)
                    .font(.headline)

                Text(option.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }
        }
    }

    private var statusSummary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Circle()
                .fill(status.style)
                .frame(width: 8, height: 8)

            Text(status.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(status.style)
        }
    }

    @ViewBuilder
    private var progressView: some View {
        if let progressValue = status.progressValue {
            ProgressView(value: progressValue)
        }
    }
}
