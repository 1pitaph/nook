import SwiftUI

struct NookCollectionSettingsView: View {
  @AppStorage("nook.settings.hapticsEnabled") private var hapticsEnabled = true
  @AppStorage("nook.settings.reminderHintsEnabled") private var reminderHintsEnabled = true
  @AppStorage("nook.settings.saveLinksAutomatically") private var saveLinksAutomatically = false

  var body: some View {
    Form {
      Section {
        Toggle(isOn: $hapticsEnabled) {
          NookSettingsLabel(
            title: "Haptics",
            subtitle: "Play light feedback when saving an item.",
            systemName: "hand.tap"
          )
        }

        Toggle(isOn: $reminderHintsEnabled) {
          NookSettingsLabel(
            title: "Reminder hints",
            subtitle: "Suggest reminders when a capture sounds time-sensitive.",
            systemName: "bell"
          )
        }

        Toggle(isOn: $saveLinksAutomatically) {
          NookSettingsLabel(
            title: "Auto-save links",
            subtitle: "Keep shared links without asking for extra detail.",
            systemName: "link"
          )
        }
      } header: {
        Text("Capture")
          .font(NookFont.app(13, weight: .semibold))
      }

      Section {
        LabeledContent {
          Text("Inbox")
            .font(NookFont.app(15))
            .foregroundStyle(NookTheme.secondaryText)
        } label: {
          Label {
            Text("Default collection")
              .font(NookFont.app(17))
          } icon: {
            Image(systemName: "tray")
          }
        }

        LabeledContent {
          Text("On-device library")
            .font(NookFont.app(15))
            .foregroundStyle(NookTheme.secondaryText)
        } label: {
          Label {
            Text("Storage")
              .font(NookFont.app(17))
          } icon: {
            Image(systemName: "externaldrive")
          }
        }
      } header: {
        Text("Workspace")
          .font(NookFont.app(13, weight: .semibold))
      }
    }
    .scrollContentBackground(.hidden)
    .background(NookTheme.background)
    .tint(NookTheme.active)
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct NookSettingsLabel: View {
  let title: String
  let subtitle: String
  let systemName: String

  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(NookFont.app(17))

        Text(subtitle)
          .font(NookFont.app(12))
          .foregroundStyle(NookTheme.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    } icon: {
      Image(systemName: systemName)
    }
    .labelStyle(.titleAndIcon)
  }
}
