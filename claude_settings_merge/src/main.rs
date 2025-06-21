use clap::Parser;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::fs;
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Enable debug mode to show found files
    #[arg(short, long)]
    debug: bool,

    /// Directory to search (defaults to current directory)
    #[arg(default_value = ".")]
    directory: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct Settings {
    permissions: Permissions,
}

#[derive(Debug, Deserialize, Serialize)]
struct Permissions {
    #[serde(default)]
    allow: Vec<String>,
    #[serde(default)]
    deny: Vec<String>,
}

fn find_claude_settings_files(root_dir: &str) -> Vec<String> {
    let mut settings_files = Vec::new();

    for entry in WalkDir::new(root_dir)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();
        if path.is_file() 
            && path.file_name().unwrap_or_default() == "settings.local.json"
            && path.parent()
                .and_then(|p| p.file_name())
                .and_then(|n| n.to_str())
                .map(|n| n == ".claude")
                .unwrap_or(false)
        {
            if let Some(path_str) = path.to_str() {
                settings_files.push(path_str.to_string());
            }
        }
    }

    settings_files
}

fn extract_allow_deny_lists(file_path: &str) -> Permissions {
    match fs::read_to_string(file_path) {
        Ok(content) => {
            match serde_json::from_str::<Settings>(&content) {
                Ok(settings) => settings.permissions,
                Err(e) => {
                    eprintln!("Error parsing {}: {}", file_path, e);
                    Permissions {
                        allow: Vec::new(),
                        deny: Vec::new(),
                    }
                }
            }
        }
        Err(e) => {
            eprintln!("Error reading {}: {}", file_path, e);
            Permissions {
                allow: Vec::new(),
                deny: Vec::new(),
            }
        }
    }
}

fn merge_lists(all_settings: Vec<Permissions>) -> Permissions {
    let mut allow_seen = HashSet::new();
    let mut deny_seen = HashSet::new();
    let mut allow_list = Vec::new();
    let mut deny_list = Vec::new();

    for settings in all_settings {
        for item in settings.allow {
            if allow_seen.insert(item.clone()) {
                allow_list.push(item);
            }
        }
        
        for item in settings.deny {
            if deny_seen.insert(item.clone()) {
                deny_list.push(item);
            }
        }
    }

    allow_list.sort();
    deny_list.sort();

    Permissions {
        allow: allow_list,
        deny: deny_list,
    }
}

fn main() {
    let args = Args::parse();

    // Find all .claude/settings.local.json files
    let settings_files = find_claude_settings_files(&args.directory);

    if args.debug {
        eprintln!("Debug mode: Found {} settings.local.json files:", settings_files.len());
        for file_path in &settings_files {
            eprintln!("  - {}", file_path);
        }
        eprintln!();
    }

    if settings_files.is_empty() {
        let output = Settings {
            permissions: Permissions {
                allow: Vec::new(),
                deny: Vec::new(),
            }
        };
        println!("{}", serde_json::to_string_pretty(&output).unwrap());
        return;
    }

    // Extract allow and deny lists from each file
    let all_settings: Vec<Permissions> = settings_files
        .iter()
        .map(|file_path| extract_allow_deny_lists(file_path))
        .collect();

    // Merge all lists
    let merged = merge_lists(all_settings);

    // Output as JSON with correct structure
    let output = Settings {
        permissions: merged,
    };
    
    println!("{}", serde_json::to_string_pretty(&output).unwrap());
}