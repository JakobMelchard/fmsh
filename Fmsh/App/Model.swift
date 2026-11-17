import Foundation
import Observation

/// Root state, main-actor bound. Settings that outlive a launch go through `@AppStorage`.
@MainActor
@Observable
final class Model {
  private(set) var count = 0

  func increment() { count += 1 }
}
