#!/usr/bin/env bash
set -uo pipefail

mode=${1:-core}
failures=0
passes=0

fail() {
  echo "FAIL: $*" >&2
  return 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing executable: $1"
}

expect_contains() {
  local actual=$1 expected=$2 label=$3
  [[ "$actual" == *"$expected"* ]] || fail "$label expected '$expected', got '$actual'"
}

run_test() {
  local label=$1
  shift
  if "$@"; then
    ((passes += 1))
    echo "PASS: $label"
  else
    ((failures += 1))
    echo "FAILED: $label" >&2
  fi
}

test_go_version() {
  require_command go || return 1
  expect_contains "$(go version 2>&1)" 'go1.27.2' 'Go version'
}

test_go_runtime() {
  require_command go || return 1
  local tmpdir
  tmpdir=$(mktemp -d) || return 1
  trap 'rm -rf "$tmpdir"' EXIT
  cat > "$tmpdir/main.go" <<'GO'
package main

import "fmt"

func main() { fmt.Println("go-ok") }
GO
  expect_contains "$(go run "$tmpdir/main.go" 2>&1)" 'go-ok' 'Go compile and run'
}

test_node_version() {
  require_command node || return 1
  expect_contains "$(node --version 2>&1)" 'v' 'Node.js version'
}

test_node_runtime() {
  require_command node || return 1
  expect_contains "$(node -e 'console.log("node-ok")' 2>&1)" 'node-ok' 'Node.js execution'
}

test_npm() {
  require_command npm || return 1
  expect_contains "$(npm --version 2>&1)" '.' 'npm launches'
}

test_protoc_version() {
  require_command protoc || return 1
  expect_contains "$(protoc --version 2>&1)" '36.2' 'protoc version'
}

test_buf() {
  require_command buf || return 1
  expect_contains "$(buf --version 2>&1)" '1.72.0' 'Buf version'
}

test_stripe() {
  require_command stripe || return 1
  expect_contains "$(stripe version 2>&1)" '1.53.1' 'Stripe CLI version'
}

test_protoc_go_plugins() {
  for tool in protoc protoc-gen-go protoc-gen-go-grpc; do
    require_command "$tool" || return 1
  done
  local tmpdir
  tmpdir=$(mktemp -d) || return 1
  trap 'rm -rf "$tmpdir"' EXIT
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
    "$tmpdir/smoke.proto" || return 1
  [[ -s "$tmpdir/smoke.pb.go" ]] || fail 'protoc-gen-go did not generate Go code' || return 1
  [[ -s "$tmpdir/smoke_grpc.pb.go" ]] || fail 'protoc-gen-go-grpc did not generate gRPC code' || return 1
}

test_sqlc() {
  require_command sqlc || return 1
  sqlc version >/dev/null 2>&1 || fail 'sqlc version command failed'
}

test_delve() {
  require_command dlv || return 1
  expect_contains "$(dlv version 2>&1)" 'Delve' 'Delve launches'
}

test_gopls() {
  require_command gopls || return 1
  expect_contains "$(gopls version 2>&1)" 'golang.org/x/tools/gopls' 'gopls launches'
}

test_staticcheck() {
  require_command staticcheck || return 1
  expect_contains "$(staticcheck -version 2>&1)" 'staticcheck' 'staticcheck launches'
}

test_java_home() {
  [[ -n "${JAVA_HOME:-}" ]] || fail 'JAVA_HOME is unset' || return 1
  [[ -x "$JAVA_HOME/bin/java" ]] || fail "JAVA_HOME does not contain java: ${JAVA_HOME}" || return 1
  local java_path java_home_path
  java_path=$(readlink -f "$(command -v java)" 2>/dev/null) || fail 'java is not on PATH' || return 1
  java_home_path=$(readlink -f "$JAVA_HOME/bin/java" 2>/dev/null) || fail 'JAVA_HOME java cannot be resolved' || return 1
  [[ "$java_path" == "$java_home_path" ]] || fail 'java on PATH does not match JAVA_HOME'
}

test_java_runtime_version() {
  require_command java || return 1
  expect_contains "$(java -version 2>&1)" '26.0.2' 'Java runtime version'
}

test_javac_version() {
  require_command javac || return 1
  expect_contains "$(javac -version 2>&1)" '26.0.2' 'Java compiler version'
}

test_java_compile_run() {
  for tool in java javac; do
    require_command "$tool" || return 1
  done
  local tmpdir
  tmpdir=$(mktemp -d) || return 1
  trap 'rm -rf "$tmpdir"' EXIT
  cat > "$tmpdir/JavaSmokeTest.java" <<'JAVA'
class JavaSmokeTest {
  public static void main(String[] args) {
    System.out.println("java-ok");
  }
}
JAVA
  javac "$tmpdir/JavaSmokeTest.java" 2>&1 || return 1
  expect_contains "$(java -cp "$tmpdir" JavaSmokeTest 2>&1)" 'java-ok' 'Java compile and run'
}

test_android_platform() {
  [[ -n "${ANDROID_HOME:-}" ]] || fail 'ANDROID_HOME is unset' || return 1
  [[ -d "$ANDROID_HOME/platforms/android-37.0" ]] || fail 'Android platform 37.0 is missing'
}

test_android_build_tools() {
  [[ -n "${ANDROID_HOME:-}" ]] || fail 'ANDROID_HOME is unset' || return 1
  [[ -x "$ANDROID_HOME/build-tools/37.0.0/aapt2" ]] || fail 'aapt2 is missing from Android Build Tools 37.0.0' || return 1
  [[ -x "$ANDROID_HOME/build-tools/37.0.0/d8" ]] || fail 'D8 is missing from Android Build Tools 37.0.0'
}

test_sdkmanager() {
  require_command sdkmanager || return 1
  expect_contains "$(sdkmanager --version 2>&1)" '.' 'Android sdkmanager launches'
}

test_adb() {
  require_command adb || return 1
  expect_contains "$(adb version 2>&1)" 'Android Debug Bridge' 'Android platform-tools launch'
}

test_aapt2() {
  [[ -n "${ANDROID_HOME:-}" ]] || fail 'ANDROID_HOME is unset' || return 1
  local aapt2="$ANDROID_HOME/build-tools/37.0.0/aapt2"
  [[ -x "$aapt2" ]] || fail "aapt2 is missing or not executable: $aapt2" || return 1
  expect_contains "$("$aapt2" version 2>&1)" 'Android Asset Packaging Tool' 'aapt2 launches'
}

test_d8() {
  [[ -n "${ANDROID_HOME:-}" ]] || fail 'ANDROID_HOME is unset' || return 1
  local d8="$ANDROID_HOME/build-tools/37.0.0/d8"
  [[ -x "$d8" ]] || fail "D8 is missing or not executable: $d8" || return 1
  expect_contains "$("$d8" --version 2>&1)" 'D8' 'D8 launches'
}

run_test 'Go 1.27.2' test_go_version
run_test 'Go compile and run' test_go_runtime
run_test 'Node.js version' test_node_version
run_test 'Node.js execution' test_node_runtime
run_test 'npm launches' test_npm
run_test 'protoc 36.2' test_protoc_version
run_test 'Buf 1.72.0' test_buf
run_test 'Stripe CLI 1.53.1' test_stripe
run_test 'protoc Go and gRPC plugins' test_protoc_go_plugins
run_test 'sqlc launches' test_sqlc
run_test 'Delve launches' test_delve
run_test 'gopls launches' test_gopls
run_test 'staticcheck launches' test_staticcheck

if [[ "$mode" == android ]]; then
  run_test 'JAVA_HOME points to the active Java runtime' test_java_home
  run_test 'Java runtime 26.0.2' test_java_runtime_version
  run_test 'Java compiler 26.0.2' test_javac_version
  run_test 'Java compile and run' test_java_compile_run
  run_test 'Android API 37.0 platform installed' test_android_platform
  run_test 'Android Build Tools 37.0.0 installed' test_android_build_tools
  run_test 'Android sdkmanager launches' test_sdkmanager
  run_test 'Android platform-tools launch' test_adb
  run_test 'Android aapt2 launches' test_aapt2
  run_test 'Android D8 launches' test_d8
elif [[ "$mode" != core ]]; then
  echo "FAIL: unknown test mode: $mode" >&2
  ((failures += 1))
fi

echo "Smoke-test results: $passes passed, $failures failed"
((failures == 0))
