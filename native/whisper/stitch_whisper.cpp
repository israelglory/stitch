// A small C interface over whisper.cpp for the Dart side (see
// lib/features/captions/data/whisper_bindings.dart).
//
// Progress and cancellation go through plain memory the caller owns, so
// nothing calls back into Dart from whisper's threads.

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

#include "whisper.h"

#if defined(_WIN32)
#define STITCH_EXPORT extern "C" __declspec(dllexport)
#else
#define STITCH_EXPORT extern "C" __attribute__((visibility("default")))
#endif

namespace {

void on_log(enum ggml_log_level, const char *, void *) {}

void on_progress(whisper_context *, whisper_state *, int progress, void *data) {
  __atomic_store_n(static_cast<int32_t *>(data), progress, __ATOMIC_RELAXED);
}

bool on_abort(void *data) {
  return __atomic_load_n(static_cast<const int32_t *>(data), __ATOMIC_RELAXED) != 0;
}

bool on_encoder_begin(whisper_context *, whisper_state *, void *data) {
  return !on_abort(data);
}

// Appends [text] as a JSON string. Bytes outside printable ASCII are
// written as \u00XX, one per byte: tokens can end in the middle of a
// UTF-8 character, so the caller joins the bytes of a word first and
// decodes them together.
void append_bytes(std::string &out, const char *text) {
  out += '"';
  for (const unsigned char *c = reinterpret_cast<const unsigned char *>(text); *c; ++c) {
    if (*c == '"' || *c == '\\') {
      out += '\\';
      out += static_cast<char>(*c);
    } else if (*c < 0x20 || *c >= 0x7f) {
      char escaped[7];
      std::snprintf(escaped, sizeof escaped, "\\u%04x", *c);
      out += escaped;
    } else {
      out += static_cast<char>(*c);
    }
  }
  out += '"';
}

char *copy(const std::string &s) {
  char *result = static_cast<char *>(std::malloc(s.size() + 1));
  if (result != nullptr) std::memcpy(result, s.c_str(), s.size() + 1);
  return result;
}

}  // namespace

// Transcribes [n_samples] of 16 kHz mono audio with the model at
// [model_path]. [language] is a whisper language code, or "auto".
//
// Returns JSON, freed with stitch_whisper_free:
//   {"language": "en", "segments": [{"start": ms, "end": ms, "tokens":
//     [{"text": " Hel", "start": ms, "end": ms, "p": 0.9}, ...]}, ...]}
// or {"error": "model" | "cancelled" | "failed"}.
//
// [progress] receives 0 to 100 as it runs. Setting [cancel] to nonzero
// stops it.
STITCH_EXPORT char *stitch_whisper_transcribe(
    const char *model_path, const float *samples, int32_t n_samples,
    const char *language, int32_t n_threads, int32_t *progress,
    const int32_t *cancel) {
  whisper_log_set(on_log, nullptr);

  whisper_context_params cparams = whisper_context_default_params();
  cparams.use_gpu = false;
  whisper_context *ctx = whisper_init_from_file_with_params(model_path, cparams);
  if (ctx == nullptr) return copy("{\"error\":\"model\"}");

  whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
  params.n_threads = n_threads;
  params.language = language;
  params.translate = false;
  params.no_context = true;
  params.token_timestamps = true;
  params.suppress_nst = true;
  params.print_progress = false;
  params.print_realtime = false;
  params.print_special = false;
  params.print_timestamps = false;
  params.progress_callback = on_progress;
  params.progress_callback_user_data = progress;
  params.encoder_begin_callback = on_encoder_begin;
  params.encoder_begin_callback_user_data = const_cast<int32_t *>(cancel);
  params.abort_callback = on_abort;
  params.abort_callback_user_data = const_cast<int32_t *>(cancel);

  const int status = whisper_full(ctx, params, samples, n_samples);
  if (on_abort(const_cast<int32_t *>(cancel))) {
    whisper_free(ctx);
    return copy("{\"error\":\"cancelled\"}");
  }
  if (status != 0) {
    whisper_free(ctx);
    return copy("{\"error\":\"failed\"}");
  }

  const whisper_token eot = whisper_token_eot(ctx);
  std::string out = "{\"language\":";
  append_bytes(out, whisper_lang_str(whisper_full_lang_id(ctx)));
  out += ",\"segments\":[";
  const int n_segments = whisper_full_n_segments(ctx);
  for (int s = 0; s < n_segments; ++s) {
    if (s > 0) out += ',';
    // Whisper counts time in 10 ms steps.
    out += "{\"start\":" + std::to_string(whisper_full_get_segment_t0(ctx, s) * 10);
    out += ",\"end\":" + std::to_string(whisper_full_get_segment_t1(ctx, s) * 10);
    out += ",\"tokens\":[";
    bool first = true;
    const int n_tokens = whisper_full_n_tokens(ctx, s);
    for (int t = 0; t < n_tokens; ++t) {
      const whisper_token_data data = whisper_full_get_token_data(ctx, s, t);
      if (data.id >= eot) continue;  // timestamps and other special tokens
      if (!first) out += ',';
      first = false;
      out += "{\"text\":";
      append_bytes(out, whisper_full_get_token_text(ctx, s, t));
      out += ",\"start\":" + std::to_string(data.t0 * 10);
      out += ",\"end\":" + std::to_string(data.t1 * 10);
      char p[32];
      std::snprintf(p, sizeof p, "%.3f", data.p);
      out += ",\"p\":";
      out += p;
      out += '}';
    }
    out += "]}";
  }
  out += "]}";
  whisper_free(ctx);
  return copy(out);
}

STITCH_EXPORT void stitch_whisper_free(char *result) { std::free(result); }
