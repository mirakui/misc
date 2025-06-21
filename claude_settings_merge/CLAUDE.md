# Claude Settings Merge Tool

## Overview
A tool (available in Ruby and Rust) that finds all `.claude/settings.local.json` files in subdirectories, extracts their permission lists, merges them (removing duplicates), and outputs a consolidated JSON to stdout.

## Usage

### Ruby version
```bash
ruby merge_claude_settings.rb [options] [directory]
```

### Rust version
```bash
# Build
cargo build --release

# Run
./target/release/merge_claude_settings [options] [directory]
```

Options:
- `--debug` or `-d`: Show found file paths to stderr
- `[directory]`: Root directory to search (default: current directory)

## Features
- Recursively searches for `.claude/settings.local.json` files
- Merges `allow` and `deny` permission lists from all found files
- Removes duplicates while preserving order of first occurrence
- Sorts the final lists alphabetically
- Outputs in the correct Claude settings JSON structure
- Debug mode shows which files were processed

## Example Output
```json
{
  "permissions": {
    "allow": [
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Read(*.rb)"
    ],
    "deny": [
      "Bash(rm:*)",
      "Bash(sudo:*)"
    ]
  }
}
```

## TODO List
- [x] Create script to find and merge .claude/settings.json files
- [x] Change to search for settings.local.json instead of settings.json
- [x] Implement debug mode to show target filenames
- [x] Fix JSON structure to use nested permissions object
- [x] Add sorting to allow and deny lists
- [x] Test sorting functionality
- [x] スクリプトをrustにして (Rewrite script in Rust)