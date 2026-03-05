#!/usr/bin/env bats

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"

  cat << 'SCRIPT' > "$TEST_TEMP_DIR/clear_env.sh"
#!/usr/bin/env bash
ALLOWED_VARS=("$1")
KEEP_VARS=("HOME" "USER" "LOGNAME" "PATH" "TERM" "SHELL" "LANG" "LC_ALL" "DISPLAY")
ENV_ARGS=()
for var in "${ALLOWED_VARS[@]}" "${KEEP_VARS[@]}"; do
    if [[ -v "$var" ]]; then
        ENV_ARGS+=("$var=${!var}")
    fi
done
exec env -i "${ENV_ARGS[@]}" bash -c 'env'
SCRIPT
  chmod +x "$TEST_TEMP_DIR/clear_env.sh"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "env clearing keeps allowed vars" {
  export MY_VAR="my_value"
  run "$TEST_TEMP_DIR/clear_env.sh" "MY_VAR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MY_VAR=my_value"* ]]
}

@test "env clearing perfectly preserves multiline variables" {
  export MULTILINE="line1
line2
line3"
  run "$TEST_TEMP_DIR/clear_env.sh" "MULTILINE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MULTILINE=line1
line2
line3"* ]]
}

@test "env clearing perfectly preserves special characters" {
  export SPECIAL="special !@#\$%^&*() value"
  run "$TEST_TEMP_DIR/clear_env.sh" "SPECIAL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SPECIAL=special !@#\$%^&*() value"* ]]
}

@test "env clearing strips non-allowed variables" {
  export SECRET="dont_show"
  run "$TEST_TEMP_DIR/clear_env.sh" "MY_VAR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"SECRET="* ]]
}
