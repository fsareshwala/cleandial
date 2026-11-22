# Clean Dial — Swift Coding Style Guide

This document defines the coding style conventions for the **Clean Dial** (`cleandial`) codebase.
All new code and edits—both human and AI-authored—must follow these conventions.

---

## 1. Formatting & File Structure

- **Indentation:** Use **2 spaces** per indentation level (no tabs).
- **Imports:** List module imports alphabetically at the top of each file. In test files, separate
  `@testable import cleandial` from framework imports with a blank line.
- **Line Wrapping:** Wrap long parameter lists, multi-argument calls, and multi-line collections
  across lines with 2-space indentation and closing delimiters aligned with the opening statement.
- **Section Markers:** Use `// MARK: -` comments to group logical sections in longer files (e.g.,
  test suites and test helpers).
- **Previews:** Place `#Preview` blocks at the bottom of SwiftUI view files.

---

## 2. Control Flow & Whitespace

### Never Write Single-Line `if` or `guard` Statements

Keep the header, body, and closing brace of every `if` and `guard` statement on separate lines.

```swift
// Avoid
if isReady { proceed() }
guard let label = devicePhoneNumber.label else { return "" }

// Prefer
if isReady {
  proceed()
}

guard let label = devicePhoneNumber.label else {
  return ""
}
```

### Add a Blank Line After Control Structure Closing Braces

Place a blank line after the closing `}` of `if`, `if`/`else`, `guard`, `for`, `while`, `repeat`,
`switch`, `do`/`catch`, `defer`, and `#if`/`#endif` blocks to visually separate them from
subsequent statements in the same scope.

**Exception:** Do **not** add a blank line when the next line is itself a closing brace `}`
(closing nested scopes) or a continuation of the same control structure (`else`, `catch`, `case`).

```swift
// Avoid
guard !isFetchingContacts else {
  return
}
isFetchingContacts = true

// Prefer
guard !isFetchingContacts else {
  return
}

isFetchingContacts = true
```

```swift
// Avoid
if delay > 0 {
  try? await Task.sleep(nanoseconds: delay)
}
for contact in contacts {
  continuation.yield(contact)
}
continuation.finish()

// Prefer
if delay > 0 {
  try? await Task.sleep(nanoseconds: delay)
}

for contact in contacts {
  continuation.yield(contact)
}

continuation.finish()
```

```swift
// No blank line needed before closing braces of enclosing scopes
for contact in batch {
  if contact.hasValidPhoneNumber {
    validContacts.append(contact)
  } else {
    invalidContacts.append(contact)
  }
}
```

### Avoid the Ternary Operator (`? :`)

Do not use the ternary operator (`condition ? a : b`). Use an explicit multi-line `if`/`else`
statement (or SwiftUI `if`/`else` view branch) instead.

```swift
// Avoid
return phoneNumber == formatted ? nil : formatted

// Prefer
if phoneNumber == formatted {
  return nil
} else {
  return formatted
}
```

```swift
// Avoid
Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
  .foregroundStyle(isSelected ? .blue : .gray)

// Prefer
if isSelected {
  Image(systemName: "checkmark.circle.fill")
    .foregroundStyle(.blue)
} else {
  Image(systemName: "circle")
    .foregroundStyle(.gray)
}
```

---

## 3. Boolean Returns

### Always Use Explicit `return` for Boolean Functions & Computed Properties

Never rely on Swift's implicit single-expression return (placing just a boolean identifier or
expression as the last line) when a function or computed property returns `Bool`. Always write the
explicit `return` keyword.

```swift
// Avoid
func anyContactNeedsFormatting() -> Bool {
  validContacts.contains { $0.needsFormatting(toFormat: selectedFormatType) }
}

// Prefer
func anyContactNeedsFormatting() -> Bool {
  return validContacts.contains { $0.needsFormatting(toFormat: selectedFormatType) }
}
```

### Avoid `!` Negation When Returning a Boolean

When returning a boolean, avoid using the `!` negation operator (or returning an inverted expression
inline). Write an explicit multi-line `if`/`else` returning `true` or `false`.

```swift
// Avoid
func isActive() -> Bool {
  return !isDisabled
}

// Prefer
func isActive() -> Bool {
  if isDisabled {
    return false
  } else {
    return true
  }
}
```

```swift
// Avoid
var hasValidPhoneNumber: Bool {
  parsedPhoneNumber != PhoneNumber.notPhoneNumber()
}

// Prefer
var hasValidPhoneNumber: Bool {
  if parsedPhoneNumber == PhoneNumber.notPhoneNumber() {
    return false
  } else {
    return true
  }
}
```

---

## 4. Naming, Types & Safety

- **Casing:** `PascalCase` for types (`struct`, `enum`, `class`, `protocol`) and `camelCase` for
  properties, methods, local variables, and enum cases.
- **Value Semantics:** Prefer `struct` and `enum` over `class`. Use `final class` only where
  reference semantics are required (`@Observable` view models, `UIApplicationDelegate`, UIKit
  coordinators, thread-safe test mocks).
- **Immutability & Access Control:** Default to `let` for constants and `private` for
  implementation details.
- **Optionals:** Avoid force unwrapping (`!`) in production code. Use `guard let`, `if let`, or
  nil-coalescing (`??`) with explicit fallbacks.

---

## 5. SwiftUI, Architecture & Concurrency

- **State Management:** Use `@State private var` for view-owned state, `@Binding var` for parent
  bindings, `@Environment(\...) private var` for environment values (`dismiss`, `openURL`,
  `scenePhase`), and `@Observable` (`Observation` framework) for view models. Avoid Combine
  (`ObservableObject`, `@Published`).
- **Concurrency:** Prefer Swift `async`/`await`, `Task`, and `AsyncStream` over completion
  handlers. Annotate UI-bound view models with `@MainActor`.
- **Modern Modifiers:** Prefer `.foregroundStyle(...)` over `.foregroundColor(...)` and
  `.clipShape(.rect(cornerRadius: ...))` over `.cornerRadius(...)`.
- **Separation of Concerns:** Keep Contacts access behind `ContactStoreProviding`, analytics events
  strongly typed in `AnalyticsEvent` / `AnalyticsLogging`, external URLs in `AppLinks`, and shared
  UI primitives (`IconHeaderView`, `SelectionIndicatorView`, `MessageView`, `ActionView`, `Sheet`)
  reusable.

---

## 6. Testing Conventions

- **Frameworks:** Use **Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`) for unit
  tests in `cleandialTests/` and **XCTest / XCUIAutomation** for UI tests in `cleandialUITests/`.
- **Determinism:** Use explicit international country codes in test phone numbers (e.g.,
  `+14155550100`, `+442079460958`) so formatting assertions are locale-independent.
- **Style Parity:** Apply the same control-flow, whitespace, explicit boolean return, and
  no-ternary rules in test files as in production code.
