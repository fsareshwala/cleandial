# Clean Dial

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Format every phone number in your iOS Contacts into a clean, consistent standard—in seconds.**

Clean Dial is an iOS and iPadOS utility app that simplifies keeping your contact phone numbers in a
user friendly and consistent format. Preview every change before it happens, switch between standard
formats with a single tap, and update your entire address book locally on your device. Available on
the App Store as [Clean Dial](https://apps.apple.com/us/app/clean-dial/id6745625133).

## The Problem

Over years of importing contacts, saving numbers from messages, and traveling across regions, an
address book quickly becomes a mix of inconsistent styles (`5555648583`, `(555) 564-8583`,
`555.564.8583`, `+1 555-564-8583`):

1. **Inconsistent formatting:** Phone numbers saved from different apps and devices rarely follow
   the same convention, making your Contacts list messy and harder to scan.
2. **Dialing and caller ID friction:** Missing country codes or non-standard formatting can break
   international dialing, messaging apps, and caller ID matching when traveling or switching
   carriers.
3. **Tedious manual editing:** Opening hundreds of contacts one by one in the built-in Contacts app
   to retype phone numbers is slow, repetitive, and makes malformed entries easy to miss.

## The Solution

Clean Dial scans your Contacts on-device and formats your phone numbers in three quick steps:

1. Choose a standard format (**International**, **National**, or **E.164**).
2. Review the live before-and-after preview for every number—and uncheck any you want to skip.
3. Tap **Format** to update all selected contacts at once.

Any unparseable entries (such as short codes or extensions) are safely separated into **Invalid
Contacts** so they are never corrupted and can be repaired directly in-app.

## Screenshots

|                                                                                                                                                                   1. Preview Changes                                                                                                                                                                   |                                                                                                                                                                   2. Switch Formats                                                                                                                                                                    |                                                                                                                                                                   3. Tap to Format                                                                                                                                                                    |                                                                                                                                                                           4. Clean & Private                                                                                                                                                                           |
| :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
| <picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/2a578b91-3350-4e35-9d51-35842d5a8fc3"><img alt="Preview contact phone number formatting changes in Clean Dial" src="https://github.com/user-attachments/assets/56c95d29-de69-428e-b7a4-d2daa65a9e1e"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/ee144fd0-04a1-4140-86c1-f32b47cd5c21"><img alt="Switch between International, National, and E.164 formats with one tap" src="https://github.com/user-attachments/assets/688edb19-af2d-4d34-9cb2-d24c08333498"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/06ab845d-4fdd-4278-b696-7b512fe014c6"><img alt="Uncheck contacts to skip and tap Format to update the rest in one tap" src="https://github.com/user-attachments/assets/b40fc201-23b2-4758-821f-42e9634c662d"></picture> | <picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/55f0f30a-ae2d-439b-b792-ad83c239df5c"><img alt="All valid contacts formatted cleanly with invalid numbers surfaced for review" src="https://github.com/user-attachments/assets/9aedc157-5cb7-4764-822d-082b09890bf0"></picture> |

## Supported Formats

The app currently supports the following standard phone number formats:

| Format            | Example           | Description                                                            |
| ----------------- | ----------------- | ---------------------------------------------------------------------- |
| **International** | `+1 555-564-8583` | International format with spaces and hyphens for readability (default) |
| **National**      | `(555) 564-8583`  | National format with parentheses and a hyphen                          |
| **E.164**         | `+15555648583`    | International standard format                                          |

## Features

| Feature                        | Details                                                                                                                                                                                    |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Instant Format Switching**   | Toggle between **International**, **National**, and **E.164** at any time—the contact list immediately updates to show only numbers that differ from your chosen format.                   |
| **Live Before/After Previews** | Every row displays the contact name, localized phone label (`mobile`, `home`, `work`), proposed formatted number, and strikethrough original number so you know exactly what will change.  |
| **Selective Checkboxes**       | Each phone number has its own checkbox (checked by default), letting you skip specific contacts or numbers without blocking a batch update.                                                |
| **Fast Batch Formatting**      | Streams large address books incrementally, updates selected contacts in one tap via Apple's `Contacts` framework, preserves phone labels, and leaves other numbers on a contact untouched. |
| **Invalid Contact Repair**     | Automatically isolates unparseable numbers (such as extensions or short codes) under **Invalid Contacts** so they are never mangled, and lets you tap any row to edit the contact in-app.  |
| **Native Apple Design**        | Built with SwiftUI for iPhone and iPad with Light and Dark Mode support, pull-to-refresh, and automatic syncing whenever you return to the app.                                            |

## How to Use

1. Open **Clean Dial** and tap **Continue** to grant access to your Contacts.
2. Under **Format Type**, select **International**, **National**, or **e.164**.
3. Review the live before-and-after previews under **Contacts**, and uncheck any phone numbers you
   want to leave unchanged.
4. Tap the **Format** button in the bottom-right toolbar to update all checked contacts at once.
5. _(Optional)_ If any entries appear under **Invalid Contacts**, tap a contact to open and fix its
   phone number directly in-app.

## App Store

The app is available on the App Store as
[Clean Dial](https://apps.apple.com/us/app/clean-dial/id6745625133).

## Privacy

Your contacts never leave your device.

- **100% Local Contact Processing:** All phone number parsing, formatting, and contact updates
  happen entirely on-device using Apple's `Contacts` framework and `PhoneNumberKit`. None of your
  contacts, phone numbers, or address book details are ever uploaded, stored, or shared.
- **Anonymous Diagnostics:** Clean Dial uses Firebase Analytics and Firebase Crashlytics only for
  anonymous usage metrics (such as which format type was selected) and crash reports to improve
  stability. Personal information or contact data never leaves your device.
- **Open Source:** Every line of code is publicly auditable in this repository.

## See Also

This app is written for iOS. If you're looking for a similar app on the Android platform, see
[Twitch 2](https://play.google.com/store/apps/details?id=twitch.angelandroidapps.cnf2&hl=en_US).

## Contributing

Contributions are welcome! If you'd like to contribute to this project, please ensure your code
follows the existing style and includes appropriate tests. For major changes, please open an issue
first to discuss what you would like to change.

Found a bug or have a feature suggestion?
[Open an issue on GitHub](https://github.com/fsareshwala/cleandial/issues).
