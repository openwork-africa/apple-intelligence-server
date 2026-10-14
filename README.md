# apple-intelligence-server

Apple's on-device language model behind an OpenAI-compatible HTTP API.

It wraps the [FoundationModels](https://developer.apple.com/documentation/foundationmodels) framework, the model Apple Intelligence runs on your Mac, so that anything that can talk to the OpenAI API can use it: `curl`, the OpenAI SDKs, or your own service. Nothing leaves the machine, and there are no keys and no cost per request.

It is one small binary with no dependencies.

## Requirements

- A Mac with Apple silicon
- macOS 26 or later
- Apple Intelligence turned on (System Settings → Apple Intelligence & Siri)

## Install

### Download the release

```sh
curl -L https://github.com/openwork-africa/apple-intelligence-server/releases/latest/download/apple-intelligence-server-macos-arm64.tar.gz | tar -xz
sudo mv apple-intelligence-server/apple-intelligence-server /usr/local/bin/
```

Each release also carries a `.sha256` file to check the download against.

If you download the archive with a browser instead, macOS marks it as quarantined and refuses to run it. Clear the mark once:

```sh
xattr -d com.apple.quarantine apple-intelligence-server/apple-intelligence-server
```

### Build from source

You need Xcode 26 or later.

```sh
git clone https://github.com/openwork-africa/apple-intelligence-server.git
cd apple-intelligence-server
swift build --configuration release
sudo cp .build/release/apple-intelligence-server /usr/local/bin/
```

## Run

```sh
apple-intelligence-server                 # serve on http://127.0.0.1:8793
apple-intelligence-server --port 9000     # choose the port
```

Check that the model is ready:

```sh
curl http://127.0.0.1:8793/health
# {"available":true,"ok":true}
```

`/health` answers 200 only when the model can generate. When it cannot, it answers 503 with the reason, for example that Apple Intelligence is turned off or the model is still downloading.

### Ask once, without a server

```sh
apple-intelligence-server ask "Explain a mutex in one sentence."
cat notes.txt | apple-intelligence-server ask --instructions "Summarise this in three bullet points."
```

The answer is printed to standard output, and the exit code is non-zero when the model could not answer.

## API

| Route | What it does |
|---|---|
| `GET /health` | Whether the model is ready |
| `GET /v1/models` | The model list, with one entry: `apple-intelligence` |
| `POST /v1/chat/completions` | OpenAI Chat Completions, with streaming and tool calls |
| `POST /v1/images/generations` | Images from Image Playground |
| `POST /generate` | One prompt in, one answer out |

### Chat

```sh
curl http://127.0.0.1:8793/v1/chat/completions -d '{
  "messages": [
    {"role": "system", "content": "Answer in one sentence."},
    {"role": "user", "content": "Why is the sky blue?"}
  ]
}'
```

`temperature` and `max_tokens` are honoured. Set `"stream": true` to receive server-sent events that end with `data: [DONE]`. Earlier turns in `messages` are replayed to the model as real history.

With the OpenAI SDK, point the client at the server; the key can be anything:

```python
from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:8793/v1", api_key="unused")
answer = client.chat.completions.create(
    model="apple-intelligence",
    messages=[{"role": "user", "content": "Say hello."}],
)
print(answer.choices[0].message.content)
```

### Tool calls

Name the tools you want in `tools`. When the model decides to use one, the answer has `finish_reason: "tool_calls"` and the call's arguments; run the tool yourself and send the result back as a `tool` message.

```sh
curl http://127.0.0.1:8793/v1/chat/completions -d '{
  "messages": [{"role": "user", "content": "Read /tmp/notes.txt and tell me what it says."}],
  "tools": [{"type": "function", "function": {"name": "Read"}}]
}'
```

The tools are a fixed set, matched by name: `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `TodoWrite` and `NotebookEdit`. Their argument names follow Claude Code's tools and are defined in [`ToolArguments.swift`](Sources/AppleIntelligenceServer/Tools/ToolArguments.swift). The server never runs a tool.

### Images

```sh
curl http://127.0.0.1:8793/v1/images/generations -d '{"prompt": "a heron at dawn", "style": "sketch", "n": 1}'
```

`style` is `animation` (the default), `illustration` or `sketch`, and `n` is at most 4. Each image comes back as base64 PNG in `data[].b64_json`.

### Generate

```sh
curl http://127.0.0.1:8793/generate -d '{"prompt": "Name three primary colours.", "instructions": "Answer in a list."}'
# {"ok":true,"output":"..."}
```

## Limits

- **Tools cannot be defined by the client.** The model only accepts argument shapes that are compiled in, so a tool whose name is not in the list above is ignored, and the `parameters` you send are not read.
- **One tool call per answer.** Generation stops at the first tool the model calls.
- **A tool call is not streamed.** A streaming request that names tools is answered in a single event.
- **Small context.** The on-device model takes about 4,000 tokens in all; a longer conversation fails with an error that says so.
- **No token counts.** `usage` is always zero.
- **Text content only.** Image parts in a message are dropped.
- **Images follow a style.** Image Playground draws in its own styles; it does not produce photographs.

## Security

The server listens on `127.0.0.1` only and has no authentication. Anything running on the same machine can use it, and nothing outside the machine can. Do not put it behind a proxy that exposes it to a network without adding authentication there.

## Development

```sh
swift build          # debug build
swift test           # unit tests; they do not need the model
Scripts/bundle.sh    # release build, packed into dist/
```

The code is organised by what each part is responsible for:

| Folder | Holds |
|---|---|
| `Launch/` | The command line and what each command starts |
| `HTTP/` | Reading a request, writing a response, listening |
| `Routing/` | Which handler answers which route |
| `Routes/` | One handler per endpoint |
| `OpenAI/` | The request and response shapes on the wire |
| `Model/` | Everything that talks to the model and Image Playground |
| `Tools/` | The tools the model may call |

To publish a release, set the version in [`ServerInfo.swift`](Sources/AppleIntelligenceServer/Support/ServerInfo.swift), commit, then push a matching tag:

```sh
git tag v1.0.0 && git push origin v1.0.0
```

The release workflow tests, bundles and attaches the archive to a GitHub release.

## Licence

[MIT](LICENSE)

Apple, Apple Intelligence and Image Playground are trademarks of Apple Inc. This project is not affiliated with or endorsed by Apple.
