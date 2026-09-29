import Foundation

/// An item's animatable values at one moment. Mirrors `KeyframeValues` in
/// lib/features/timeline/domain/models.dart. Clips read x and y as their
/// offset, overlays as their center; volume is the final gain.
struct KeyframeValues: Decodable, Equatable {
  var x = 0.0
  var y = 0.0
  var scale = 1.0
  var rotationDeg = 0.0
  var opacity = 1.0
  var volume = 1.0

  enum CodingKeys: String, CodingKey { case x, y, scale, rotationDeg, opacity, volume }

  init() {}

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 0
    y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 0
    scale = try c.decodeIfPresent(Double.self, forKey: .scale) ?? 1
    rotationDeg = try c.decodeIfPresent(Double.self, forKey: .rotationDeg) ?? 0
    opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 1
    volume = try c.decodeIfPresent(Double.self, forKey: .volume) ?? 1
  }

  /// Each value [t] (0 to 1) of the way to [to].
  func lerp(to: KeyframeValues, _ t: Double) -> KeyframeValues {
    func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * t }
    var v = KeyframeValues()
    v.x = mix(x, to.x)
    v.y = mix(y, to.y)
    v.scale = mix(scale, to.scale)
    v.rotationDeg = mix(rotationDeg, to.rotationDeg)
    v.opacity = mix(opacity, to.opacity)
    v.volume = mix(volume, to.volume)
    return v
  }
}

/// One keyframe, its time on the timeline.
struct Keyframe: Decodable {
  let timeUs: Int64
  let values: KeyframeValues
  /// "linear", "easeIn", "easeOut", "easeInOut", or "hold".
  let easing: String
}

/// An item's keyframes, evaluated as `engineValuesAt` in
/// lib/features/timeline/domain/keyframes.dart does (docs/timeline.md,
/// Evaluator contract). A looping item's repeat every [loopUs] from
/// [loopStartUs].
struct Keyframes {
  let list: [Keyframe]
  var loopStartUs: Int64 = 0
  var loopUs: Int64 = 0

  static let none = Keyframes(list: [])

  var isEmpty: Bool { list.isEmpty }

  /// Values at timeline time [timeUs], or nil without keyframes (the item's
  /// own values apply).
  func values(at timeUs: Int64) -> KeyframeValues? {
    guard let first = list.first, let last = list.last else { return nil }
    var t = timeUs
    if loopUs > 0, t >= loopStartUs {
      t = loopStartUs + (t - loopStartUs) % loopUs
    }
    if t <= first.timeUs { return first.values }
    if t >= last.timeUs { return last.values }
    // The last keyframe at or before t.
    var lo = 0
    var hi = list.count - 1
    while hi - lo > 1 {
      let mid = (lo + hi) >> 1
      if list[mid].timeUs <= t { lo = mid } else { hi = mid }
    }
    let a = list[lo]
    let b = list[lo + 1]
    let p = Double(t - a.timeUs) / Double(b.timeUs - a.timeUs)
    return a.values.lerp(to: b.values, Self.ease(a.easing, p))
  }

  /// Timeline times in [fromUs, toUs] where the values start a new stretch:
  /// every keyframe, on every pass of a loop, and each pass's start.
  func breakpoints(fromUs: Int64, toUs: Int64) -> [Int64] {
    guard !list.isEmpty else { return [] }
    var times: [Int64] = []
    if loopUs > 0 {
      // The pass that holds fromUs.
      var pass = loopStartUs
      if fromUs > loopStartUs { pass += (fromUs - loopStartUs) / loopUs * loopUs }
      while pass <= toUs {
        times.append(pass)
        for k in list { times.append(pass + k.timeUs - loopStartUs) }
        pass += loopUs
      }
    } else {
      times = list.map(\.timeUs)
    }
    return times.filter { $0 > fromUs && $0 < toUs }
  }

  /// Largest volume any keyframe reaches, or nil without keyframes.
  var maxVolume: Double? { list.map(\.values.volume).max() }

  /// [p] (0 to 1) shaped by [easing]. Mirrors `easeProgress`.
  static func ease(_ easing: String, _ p: Double) -> Double {
    switch easing {
    case "easeIn": return p * p * p
    case "easeOut": return 1 - pow(1 - p, 3)
    case "easeInOut": return p < 0.5 ? 4 * p * p * p : 1 - pow(-2 * p + 2, 3) / 2
    case "hold": return 0
    default: return p
    }
  }
}
