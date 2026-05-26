use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use assp::{NoteStats, count_note_stats_4};
use rssp_core::parse::{decode_bytes, extract_sections};
use rssp_core::stats::{ArrowStats, minimize_chart_and_count_with_lanes};

#[derive(Debug)]
struct Args {
    path: PathBuf,
    chart: usize,
    list: bool,
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(msg) => {
            eprintln!("{msg}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> Result<(), String> {
    let args = parse_args()?;
    let ext = file_ext(&args.path)?;
    let bytes =
        fs::read(&args.path).map_err(|e| format!("failed to read {}: {e}", args.path.display()))?;
    let parsed = extract_sections(&bytes, ext).map_err(|e| format!("parse failed: {e}"))?;

    if parsed.notes_list.is_empty() {
        return Err("no charts found".to_string());
    }

    if args.list {
        print_chart_list(&parsed.notes_list);
        return Ok(());
    }

    let Some(chart) = parsed.notes_list.get(args.chart) else {
        return Err(format!(
            "chart index {} is out of range; file has {} charts",
            args.chart,
            parsed.notes_list.len()
        ));
    };

    let step_type = text(chart.fields[0]);
    let lanes = lanes_for_step_type(&step_type)?;
    if lanes != 4 {
        return Err(format!(
            "asmssp_count_note_stats_4 only supports 4 lanes today; chart uses {lanes}"
        ));
    }

    let asm = count_note_stats_4(chart.note_data)
        .ok_or_else(|| "assembly note stat counter rejected input".to_string())?;
    let (_, rust, densities) = minimize_chart_and_count_with_lanes(chart.note_data, lanes);

    println!("file: {}", args.path.display());
    println!("charts: {}", parsed.notes_list.len());
    println!("selected chart: {}", args.chart);
    println!("step_type: {}", step_type);
    println!("difficulty: {}", text(chart.fields[2]));
    println!("meter: {}", text(chart.fields[3]));
    println!("description: {}", text(chart.fields[1]));
    println!("note_data_bytes: {}", chart.note_data.len());
    println!("measures: {}", densities.len());
    println!();
    print_stats("asmssp", &asm);
    println!();
    print_rssp_stats(&rust);
    println!();
    print_match(&asm, &rust);

    Ok(())
}

fn parse_args() -> Result<Args, String> {
    let mut path = None;
    let mut chart = 0usize;
    let mut list = false;
    let mut it = env::args_os().skip(1);

    while let Some(arg) = it.next() {
        let arg_str = arg.to_string_lossy();
        match arg_str.as_ref() {
            "-h" | "--help" => return Err(usage()),
            "--list" => list = true,
            "--chart" => {
                let Some(value) = it.next() else {
                    return Err("--chart requires an index".to_string());
                };
                chart = value
                    .to_string_lossy()
                    .parse::<usize>()
                    .map_err(|_| "--chart requires a non-negative integer".to_string())?;
            }
            _ if arg_str.starts_with('-') => return Err(format!("unknown option: {arg_str}")),
            _ => {
                if path.replace(PathBuf::from(arg)).is_some() {
                    return Err("only one simfile path is accepted".to_string());
                }
            }
        }
    }

    let Some(path) = path else {
        return Err(usage());
    };

    Ok(Args { path, chart, list })
}

fn usage() -> String {
    "usage: asmssp <song.sm|song.ssc> [--chart N] [--list]".to_string()
}

fn file_ext(path: &Path) -> Result<&str, String> {
    let ext = path
        .extension()
        .and_then(|s| s.to_str())
        .ok_or_else(|| "input path needs a .sm or .ssc extension".to_string())?;
    if ext.eq_ignore_ascii_case("sm") || ext.eq_ignore_ascii_case("ssc") {
        Ok(ext)
    } else {
        Err(format!("unsupported extension: {ext}"))
    }
}

fn text(bytes: &[u8]) -> String {
    decode_bytes(bytes).trim().to_string()
}

fn lanes_for_step_type(step_type: &str) -> Result<usize, String> {
    let lower = step_type.to_ascii_lowercase();
    if lower.contains("double") {
        Ok(8)
    } else if lower.contains("single") {
        Ok(4)
    } else {
        Err(format!("unsupported step type: {step_type}"))
    }
}

fn print_chart_list(charts: &[rssp_core::parse::ParsedChartEntry<'_>]) {
    for (i, chart) in charts.iter().enumerate() {
        println!(
            "{i}: {} {} {} {}",
            text(chart.fields[0]),
            text(chart.fields[2]),
            text(chart.fields[3]),
            text(chart.fields[1])
        );
    }
}

fn print_stats(label: &str, s: &NoteStats) {
    println!("{label}:");
    println!("  rows: {}", s.rows);
    println!("  steps: {}", s.steps);
    println!("  arrows: {}", s.arrows);
    println!("  jumps: {}", s.jumps);
    println!("  hands: {}", s.hands);
    println!("  holds: {}", s.holds);
    println!("  rolls: {}", s.rolls);
    println!("  mines: {}", s.mines);
    println!("  lifts: {}", s.lifts);
    println!("  fakes: {}", s.fakes);
    println!(
        "  lanes: L={} D={} U={} R={}",
        s.left, s.down, s.up, s.right
    );
    println!("  malformed_rows: {}", s.malformed_rows);
}

fn print_rssp_stats(s: &ArrowStats) {
    println!("rssp-core:");
    println!("  steps: {}", s.total_steps);
    println!("  arrows: {}", s.total_arrows);
    println!("  jumps: {}", s.jumps);
    println!("  hands: {}", s.hands);
    println!("  holds: {}", s.holds);
    println!("  rolls: {}", s.rolls);
    println!("  mines: {}", s.mines);
    println!("  lifts: {}", s.lifts);
    println!("  fakes: {}", s.fakes);
    println!(
        "  lanes: L={} D={} U={} R={}",
        s.left, s.down, s.up, s.right
    );
}

fn print_match(asm: &NoteStats, rust: &ArrowStats) {
    let matched = asm.steps == u64::from(rust.total_steps)
        && asm.arrows == u64::from(rust.total_arrows)
        && asm.jumps == u64::from(rust.jumps)
        && asm.hands == u64::from(rust.hands)
        && asm.holds == u64::from(rust.holds)
        && asm.rolls == u64::from(rust.rolls)
        && asm.mines == u64::from(rust.mines)
        && asm.lifts == u64::from(rust.lifts)
        && asm.fakes == u64::from(rust.fakes)
        && asm.left == u64::from(rust.left)
        && asm.down == u64::from(rust.down)
        && asm.up == u64::from(rust.up)
        && asm.right == u64::from(rust.right);

    println!(
        "rssp-core stat parity: {}",
        if matched { "ok" } else { "MISMATCH" }
    );
}
