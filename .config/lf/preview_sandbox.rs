#!/usr/bin/rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4.5.4", features = ["derive"] }
//! dirs = "5.0.1"
//! rust-utils = { version = "0.3.1", git = "ssh://git@ssh.github.com:443/gaesa/rust-utils.git" }
//!
//! [profile.release]
//! lto = true
//! panic = "abort"
//! strip = true
//! codegen-units = 1
//!
//! [net]
//! offline = true
//! ```
#![allow(clippy::needless_return)]

use std::path::PathBuf;
use std::process::{ExitCode, Stdio};

use clap::Parser;
use rust_utils::files::path_to_string;
use rust_utils::processes::Processes;

#[derive(Debug, Parser)]
#[clap()]
struct Cli {
    file: PathBuf,
    remaining: Vec<String>,
}

fn get_cmd_args(cli: Cli) -> Vec<String> {
    #[cfg(debug_assertions)]
    {
        use std::fs;
        fs::write(
            dirs::runtime_dir().unwrap().join("lf-debug.log"),
            format!("{:?}\n{:?}\n", cli.file.clone(), cli.remaining.clone()),
        )
        .unwrap();
    }

    let config_path = dirs::config_dir().unwrap().join("lf/preview-sandbox.toml");
    let file = path_to_string(cli.file.canonicalize().unwrap()).unwrap();
    let mut cmd_args = vec![
        "friendly-bwrap".to_owned(),
        format!("--ro-bind={}", file.as_str()),
        path_to_string(config_path).unwrap(),
        file,
    ];
    cmd_args.extend(cli.remaining);
    return cmd_args;
}

fn main() -> ExitCode {
    let cmd_args = get_cmd_args(Cli::parse());
    Processes::new(cmd_args)
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .run()
        .expect("Failed to execute command");
    // this is done on purpose to notify `lf` to clear the last displayed image
    return ExitCode::from(1);
}
