import CoreMedia
import Foundation

/// The document the Dart side sends: canvas, media files, and the timeline
/// flattened to absolute times (Dart `ResolvedComposition`). Preview and
/// export are both built from this one value.
struct EngineDocument: Decodable {
  struct Canvas: Decodable {
    let width: Int
    let height: Int
    let frameRate: Int
  }

  struct Background: Decodable {
    /// "solid" or "blur".
    let type: String
    /// ARGB, for "solid".
    let color: Int?
  }

  struct Media: Decodable {
    let path: String
    /// "video", "photo", or "audio".
    let kind: String
    /// Smaller copy for preview, when the source is above 1080p.
    let proxyPath: String?
  }

  struct Framing: Decodable {
    let mode: String
    let scale: Double
    let offsetX: Double
    let offsetY: Double
    let rotationDeg: Double
  }

  struct Clip: Decodable {
    let clipId: String
    let mediaId: String
    let kind: String
    let startUs: Int64
    let endUs: Int64
    let sourceInUs: Int64
    let sourceOutUs: Int64
    let speed: Double
    let volume: Double
    let audioFadeInUs: Int64
    let audioFadeOutUs: Int64
    let framing: Framing
  }

  struct Transition: Decodable {
    let type: String
    let fromClipId: String
    let toClipId: String
    let startUs: Int64
    let durationUs: Int64
  }

  struct Audio: Decodable {
    let id: String
    let mediaId: String
    let startUs: Int64
    let endUs: Int64
    let sourceInUs: Int64
    let sourceOutUs: Int64
    let speed: Double
    let loop: Bool
    let volume: Double
    let fadeInUs: Int64
    let fadeOutUs: Int64
  }

  struct Composition: Decodable {
    let durationUs: Int64
    let clips: [Clip]
    let transitions: [Transition]
    let audio: [Audio]

    enum CodingKeys: String, CodingKey { case durationUs, clips, transitions, audio }

    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      durationUs = try c.decode(Int64.self, forKey: .durationUs)
      clips = try c.decodeIfPresent([Clip].self, forKey: .clips) ?? []
      transitions = try c.decodeIfPresent([Transition].self, forKey: .transitions) ?? []
      audio = try c.decodeIfPresent([Audio].self, forKey: .audio) ?? []
    }
  }

  let canvas: Canvas
  let background: Background
  let media: [String: Media]
  let composition: Composition

  static func decode(_ json: String) throws -> EngineDocument {
    try JSONDecoder().decode(EngineDocument.self, from: Data(json.utf8))
  }
}

/// Microseconds to CMTime, exactly.
@inline(__always)
func cmTime(us: Int64) -> CMTime { CMTime(value: us, timescale: 1_000_000) }

@inline(__always)
func cmRange(startUs: Int64, endUs: Int64) -> CMTimeRange {
  CMTimeRange(start: cmTime(us: startUs), end: cmTime(us: endUs))
}

extension CMTime {
  var microseconds: Int64 {
    guard isNumeric else { return 0 }
    return Int64((seconds * 1_000_000).rounded())
  }
}

/// Errors reported to Dart with a stable code.
enum EngineError: Error {
  case badDocument(String)
  case missingFile(String)
  case unsupportedMedia(String)
  case exportFailed(String)
  case cancelled

  var code: String {
    switch self {
    case .badDocument: return "bad_document"
    case .missingFile: return "missing_file"
    case .unsupportedMedia: return "unsupported_media"
    case .exportFailed: return "export_failed"
    case .cancelled: return "cancelled"
    }
  }

  var message: String {
    switch self {
    case .badDocument(let m), .missingFile(let m), .unsupportedMedia(let m),
      .exportFailed(let m):
      return m
    case .cancelled: return "Cancelled"
    }
  }
}
