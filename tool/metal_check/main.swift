// Compiles every generated Metal transition with this Mac's Metal runtime
// compiler (no Xcode Metal toolchain needed); run by
// tool/check_transitions_metal.sh.
import Foundation
import Metal

enum EngineError: Error { case badDocument(String) }

guard let device = MTLCreateSystemDefaultDevice() else {
  print("No Metal device")
  exit(1)
}
var failures = 0
for (id, body) in TransitionSources.metal.sorted(by: { $0.key < $1.key }) {
  do {
    _ = try Transitions.makePipeline(device: device, body: body)
  } catch {
    failures += 1
    print("\(id): \(error)")
  }
}
print("\(TransitionSources.metal.count - failures) of \(TransitionSources.metal.count) compile")
exit(failures == 0 ? 0 : 1)
