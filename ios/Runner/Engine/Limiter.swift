import Foundation

/// A look-ahead peak limiter for interleaved float samples: no sample goes
/// past [ceiling], and the gain comes down smoothly just before a peak
/// instead of clipping it. Mirrors Limiter.kt.
///
/// For each frame, the gain it needs is `ceiling / peak` (or 1). The gain
/// applied is the smallest need over the next look-ahead, averaged over the
/// look-ahead before it, so it ramps down over the look-ahead and is never
/// above what the peak needs. It recovers over about [releaseSeconds]. The
/// sound comes out [lookaheadSeconds] late.
final class Limiter {
  /// -1 dBFS: headroom for the encoder.
  static let defaultCeiling = Float(pow(10.0, -1.0 / 20))
  static let lookaheadSeconds = 0.005
  static let releaseSeconds = 0.1

  private let channels: Int
  private let ceiling: Float
  /// Frames the sound comes out late.
  let lookahead: Int
  private let window: Int
  private let release: Float

  private var delayed: [Float]
  private var delayPos = 0
  private var needed: [Float]
  private var queue: [Int]
  private var queueHead = 0
  private var queueSize = 0
  private var held: [Float]
  private var heldSum: Double
  private var gain: Float = 1
  private var frame = 0

  init(channels: Int, sampleRate: Int, ceiling: Float = Limiter.defaultCeiling) {
    self.channels = channels
    self.ceiling = ceiling
    lookahead = max(1, Int(Double(sampleRate) * Self.lookaheadSeconds))
    window = lookahead + 1
    release = Float(1 - exp(-1 / (Self.releaseSeconds * Double(sampleRate))))
    delayed = [Float](repeating: 0, count: lookahead * channels)
    needed = [Float](repeating: 1, count: window)
    queue = [Int](repeating: 0, count: window)
    held = [Float](repeating: 1, count: window)
    heldSum = Double(window)
  }

  /// Limits [frames] frames of [samples], in place.
  func process(_ samples: UnsafeMutablePointer<Float>, frames: Int) {
    var i = 0
    for _ in 0..<frames {
      var peak: Float = 0
      for c in 0..<channels { peak = max(peak, abs(samples[i + c])) }
      let need = peak > ceiling ? ceiling / peak : 1
      let slot = frame % window
      needed[slot] = need

      while queueSize > 0, needed[queue[(queueHead + queueSize - 1) % window] % window] >= need {
        queueSize -= 1
      }
      queue[(queueHead + queueSize) % window] = frame
      queueSize += 1
      while queue[queueHead] < frame - lookahead {
        queueHead = (queueHead + 1) % window
        queueSize -= 1
      }
      let hold = needed[queue[queueHead] % window]
      heldSum += Double(hold - held[slot])
      held[slot] = hold
      gain = min(Float(heldSum / Double(window)), gain + (1 - gain) * release)

      let d = delayPos * channels
      for c in 0..<channels {
        let out = delayed[d + c] * gain
        delayed[d + c] = samples[i + c]
        samples[i + c] = out
      }
      delayPos = (delayPos + 1) % lookahead
      frame += 1
      i += channels
    }
  }
}
