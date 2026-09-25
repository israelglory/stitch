import Foundation

/// An overlay's look at one moment of its entrance or exit. Mirrors
/// lib/features/text/domain/text_motion.dart; docs/engine.md defines the
/// looks.
struct TextMotion {
  /// Opacity, 0 to 1.
  var alpha = 1.0
  /// Vertical offset as a fraction of the canvas height, down.
  var dy = 0.0
  /// Multiplies the overlay's own scale.
  var scale = 1.0
  /// Fraction of the text shown by a typewriter, 0 to 1.
  var reveal = 1.0

  static let slideDistance = 0.05
  static let scaleFrom = 0.6

  /// The motion [tUs] into [overlay].
  static func at(_ overlay: EngineDocument.Overlay, tUs: Int64) -> TextMotion {
    let duration = overlay.endUs - overlay.startUs
    func phase(_ span: Int64, _ into: Int64) -> Double {
      span <= 0 ? 1 : min(max(Double(into) / Double(span), 0), 1)
    }
    let a = apply(
      overlay.animationIn.type, phase(overlay.animationIn.durationUs, tUs), entering: true)
    let b = apply(
      overlay.animationOut.type, phase(overlay.animationOut.durationUs, duration - tUs),
      entering: false)
    return TextMotion(
      alpha: a.alpha * b.alpha, dy: a.dy + b.dy, scale: a.scale * b.scale,
      reveal: min(a.reveal, b.reveal))
  }

  private static func apply(_ type: String, _ phase: Double, entering: Bool) -> TextMotion {
    let e = 1 - pow(1 - phase, 3)
    switch type {
    case "fade":
      return TextMotion(alpha: e)
    case "slideUp":
      return TextMotion(alpha: e, dy: (1 - e) * slideDistance * (entering ? 1 : -1))
    case "slideDown":
      return TextMotion(alpha: e, dy: (1 - e) * slideDistance * (entering ? -1 : 1))
    case "scale":
      return TextMotion(alpha: e, scale: scaleFrom + (1 - scaleFrom) * e)
    case "typewriter":
      return TextMotion(reveal: phase)
    default:
      return TextMotion()
    }
  }

  /// Which of [count] typewriter frames shows [reveal], or nil for none.
  static func frame(reveal: Double, count: Int) -> Int? {
    if count <= 1 { return reveal > 0 ? 0 : nil }
    let shown = Int((reveal * Double(count)).rounded(.up))
    return shown <= 0 ? nil : min(shown, count) - 1
  }
}
