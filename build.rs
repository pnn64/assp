use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

fn main() {
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();
    let target_env = env::var("CARGO_CFG_TARGET_ENV").unwrap_or_default();
    if target_arch != "x86_64" || target_env != "msvc" {
        panic!("asmssp currently supports only x86_64-pc-windows-msvc");
    }

    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let asm_dir = manifest.join("asm").join("core");
    let include_dir = manifest.join("include");

    println!("cargo:rerun-if-changed={}", asm_dir.display());
    println!("cargo:rerun-if-changed={}", include_dir.display());
    println!(
        "cargo:rerun-if-changed={}",
        include_dir.join("asmssp.inc").display()
    );
    println!(
        "cargo:rerun-if-changed={}",
        include_dir.join("asmssp.h").display()
    );

    let mut asm_files = Vec::new();
    collect_asm(&asm_dir, &mut asm_files);
    asm_files.sort();

    for asm in asm_files {
        println!("cargo:rerun-if-changed={}", asm.display());

        let rel = asm.strip_prefix(&asm_dir).unwrap();
        let stem = rel
            .to_string_lossy()
            .replace('\\', "_")
            .replace('/', "_")
            .replace(".asm", "");
        let obj = out_dir.join(format!("{stem}.obj"));

        let status = Command::new("nasm")
            .arg("-f")
            .arg("win64")
            .arg(format!("-I{}\\", include_dir.display()))
            .arg(&asm)
            .arg("-o")
            .arg(&obj)
            .status()
            .unwrap_or_else(|e| panic!("failed to run nasm for {}: {e}", asm.display()));

        if !status.success() {
            panic!("nasm failed for {}", asm.display());
        }

        println!("cargo:rustc-link-arg={}", obj.display());
    }
}

fn collect_asm(dir: &Path, out: &mut Vec<PathBuf>) {
    for entry in fs::read_dir(dir).unwrap() {
        let path = entry.unwrap().path();
        if path.is_dir() {
            collect_asm(&path, out);
        } else if path.extension().is_some_and(|ext| ext == "asm") {
            out.push(path);
        }
    }
}
