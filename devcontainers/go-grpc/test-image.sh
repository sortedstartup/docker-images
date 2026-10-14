#!/usr/bin/env bash
set -euo pipefail

mode=${1:-core}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing executable: $1"
}

expect_contains() {
  local actual=$1 expected=$2 label=$3
  [[ "$actual" == *"$expected"* ]] || fail "$label expected '$expected', got '$actual'"
  printf 'PASS: %s (%s)\n' "$label" "$actual"
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cat > "$tmpdir/GoSmokeTest.go" <<'GO'
package main

import "fmt"

func main() { fmt.Println("go-ok") }
GO

for tool in go node npm protoc buf stripe; do
  require_command "$tool"
done

expect_contains "$(go version)" 'go1.27.2' 'Go version'
expect_contains "$(go run "$tmpdir/GoSmokeTest.go")" 'go-ok' 'Go compile and run'
expect_contains "$(node --version)" 'v' 'Node.js launches'
expect_contains "$(npm --version)" '.' 'npm launches'
expect_contains "$(node -e 'console.log("node-ok")')" 'node-ok' 'Node.js execution'
expect_contains "$(protoc --version)" '36.2' 'protoc version'
expect_contains "$(buf --version)" '1.72.0' 'Buf version'
expect_contains "$(stripe version 2>&1)" '1.53.1' 'Stripe CLI version'

for tool in protoc-gen-go protoc-gen-go-grpc sqlc dlv gopls golint staticcheck; do
  require_command "$tool"
done

cat > "$tmpdir/smoke.proto" <<'PROTO'
syntax = "proto3";
package smoke;
option go_package = "example.com/smoke;smoke";

service Greeter {
  rpc SayHello (HelloRequest) returns (HelloReply);
}
message HelloRequest { string name = 1; }
message HelloReply { string message = 1; }
PROTO
protoc --proto_path="$tmpdir" \
  --go_out="$tmpdir" --go_opt=paths=source_relative \
  --go-grpc_out="$tmpdir" --go-grpc_opt=paths=source_relative \
  "$tmpdir/smoke.proto"
[[ -s "$tmpdir/smoke.pb.go" ]] || fail 'protoc-gen-go did not generate Go code'
[[ -s "$tmpdir/smoke_grpc.pb.go" ]] || fail 'protoc-gen-go-grpc did not generate gRPC code'
echo 'PASS: protoc Go and gRPC plugins generate code'
sqlc version >/dev/null
echo 'PASS: sqlc launches'
expect_contains "$(dlv version)" 'Delve' 'Delve launches'
expect_contains "$(gopls version)" 'golang.org/x/tools/gopls' 'gopls launches'
expect_contains "$(staticcheck -version)" 'staticcheck' 'staticcheck launches'

if [[ "$mode" == core ]]; then
  exit 0
fi
[[ "$mode" == android ]] || fail "unknown test mode: $mode"

for tool in java javac sdkmanager adb; do
  require_command "$tool"
done

[[ -n "${JAVA_HOME:-}" ]] || fail 'JAVA_HOME is unset'
[[ -x "$JAVA_HOME/bin/java" ]] || fail "JAVA_HOME does not contain java: $JAVA_HOME"
[[ "$(readlink -f "$(command -v java)")" == "$(readlink -f "$JAVA_HOME/bin/java")" ]] || fail 'java on PATH does not match JAVA_HOME'
expect_contains "$(java -version 2>&1)" '26.0.2' 'Java runtime version'
expect_contains "$(javac -version 2>&1)" '26.0.2' 'Java compiler version'

[[ -d "$ANDROID_HOME/platforms/android-37.0" ]] || fail 'Android platform 37.0 is missing'
[[ -x "$ANDROID_HOME/build-tools/37.0.0/aapt2" ]] || fail 'Android Build Tools 37.0.0 are missing'
[[ -x "$ANDROID_HOME/build-tools/37.0.0/d8" ]] || fail 'D8 is missing from Android Build Tools 37.0.0'
expect_contains "$(sdkmanager --version)" '.' 'Android sdkmanager launches'
expect_contains "$(adb version)" 'Android Debug Bridge' 'Android platform-tools launch'
expect_contains "$("$ANDROID_HOME/build-tools/37.0.0/aapt2" version)" 'Android Asset Packaging Tool' 'aapt2 launches'
expect_contains "$("$ANDROID_HOME/build-tools/37.0.0/d8" --version 2>&1)" 'D8' 'D8 launches'

cat > "$tmpdir/JavaSmokeTest.java" <<'JAVA'
class JavaSmokeTest {
  public static void main(String[] args) {
    System.out.println("java-ok");
  }
}
JAVA
javac "$tmpdir/JavaSmokeTest.java"
expect_contains "$(java -cp "$tmpdir" JavaSmokeTest)" 'java-ok' 'Java compile and run'
