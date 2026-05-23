use rssp_core::{math::round_sig_figs_itg, normalize_difficulty_label};
use serde_json::Value;
use std::collections::HashMap;
use std::env;
use std::ffi::OsStr;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::{self, Command};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc;
use std::thread;
use walkdir::WalkDir;
use zstd::stream::{decode_all, encode_all};

struct Config {
    packs_dir: PathBuf,
    baseline_dir: PathBuf,
    assp_exe: PathBuf,
    temp_dir: PathBuf,
    baseline_layout: BaselineLayout,
    baseline_suffix: Option<String>,
    compare_mode: CompareMode,
    filter: Option<String>,
    skips: Vec<String>,
    jobs: usize,
    max_failures: usize,
    exact: bool,
    update: bool,
    list: bool,
    quiet: bool,
    keep_temp: bool,
}

#[derive(Clone, Copy, Eq, PartialEq)]
enum BaselineLayout {
    Auto,
    Path,
    Hash,
}

#[derive(Clone, Copy, Eq, PartialEq)]
enum CompareMode {
    Mixed,
    Json,
}

struct TestCase {
    name: String,
    relative_path: PathBuf,
    source_path: PathBuf,
    compressed: bool,
}

enum TestStatus {
    Ok,
    Updated,
}

struct Failure {
    name: String,
    message: String,
}

struct PreparedInput {
    path: PathBuf,
    md5: String,
}

fn main() {
    let mut config = match parse_config() {
        Ok(config) => config,
        Err(message) => {
            eprintln!("{message}");
            eprintln!();
            eprintln!("{}", usage());
            process::exit(2);
        }
    };

    let code = match run(&mut config) {
        Ok(code) => code,
        Err(message) => {
            eprintln!("{message}");
            2
        }
    };

    if !config.keep_temp {
        let _ = fs::remove_dir_all(&config.temp_dir);
    }

    process::exit(code);
}

fn parse_config() -> Result<Config, String> {
    let mut config = Config {
        packs_dir: PathBuf::new(),
        baseline_dir: PathBuf::new(),
        assp_exe: PathBuf::new(),
        temp_dir: env::temp_dir().join(format!("assp-baseline-{}", process::id())),
        baseline_layout: BaselineLayout::Auto,
        baseline_suffix: None,
        compare_mode: CompareMode::Mixed,
        filter: None,
        skips: Vec::new(),
        jobs: default_jobs(),
        max_failures: 50,
        exact: false,
        update: false,
        list: false,
        quiet: false,
        keep_temp: false,
    };

    let mut args = env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "-h" | "--help" => {
                println!("{}", usage());
                process::exit(0);
            }
            "--packs-dir" => config.packs_dir = take_path(&mut args, "--packs-dir")?,
            "--baseline-dir" => config.baseline_dir = take_path(&mut args, "--baseline-dir")?,
            "--assp-exe" => config.assp_exe = take_path(&mut args, "--assp-exe")?,
            "--temp-dir" => config.temp_dir = take_path(&mut args, "--temp-dir")?,
            "--baseline-layout" => config.baseline_layout = take_baseline_layout(&mut args)?,
            "--baseline-suffix" => {
                config.baseline_suffix = Some(take_string(&mut args, "--baseline-suffix")?)
            }
            "--compare-mode" => config.compare_mode = take_compare_mode(&mut args)?,
            "--filter" => config.filter = Some(take_string(&mut args, "--filter")?),
            "--skip" => config.skips.push(take_string(&mut args, "--skip")?),
            "--jobs" => config.jobs = take_jobs(&mut args)?,
            "--max-failures" => config.max_failures = take_max_failures(&mut args)?,
            "--exact" => config.exact = true,
            "--update" => config.update = true,
            "--list" => config.list = true,
            "--quiet" => config.quiet = true,
            "--keep-temp" => config.keep_temp = true,
            "--" => {}
            _ if arg.starts_with('-') => return Err(format!("unknown argument: {arg}")),
            _ if config.filter.is_none() => config.filter = Some(arg),
            _ => return Err(format!("unexpected positional argument: {arg}")),
        }
    }

    config.packs_dir = require_existing_dir(&config.packs_dir, "packs dir")?;
    if !config.list {
        config.assp_exe = require_existing_file(&config.assp_exe, "ASSP executable")?;
        config.baseline_dir = absolute_path(&config.baseline_dir, "baseline dir")?;
    } else if !config.baseline_dir.as_os_str().is_empty() {
        config.baseline_dir = absolute_path(&config.baseline_dir, "baseline dir")?;
    }
    config.temp_dir = absolute_path(&config.temp_dir, "temp dir")?;
    if let Some(filter) = &mut config.filter {
        *filter = filter.replace('/', "\\");
    }

    Ok(config)
}

fn take_string(args: &mut impl Iterator<Item = String>, name: &str) -> Result<String, String> {
    args.next()
        .ok_or_else(|| format!("{name} requires a value"))
}

fn take_path(args: &mut impl Iterator<Item = String>, name: &str) -> Result<PathBuf, String> {
    Ok(PathBuf::from(take_string(args, name)?))
}

fn take_jobs(args: &mut impl Iterator<Item = String>) -> Result<usize, String> {
    let value = take_string(args, "--jobs")?;
    let jobs = value
        .parse::<usize>()
        .map_err(|_| format!("--jobs requires a positive integer, got {value}"))?;
    if jobs == 0 {
        return Err("--jobs must be at least 1".to_owned());
    }
    Ok(jobs)
}

fn take_max_failures(args: &mut impl Iterator<Item = String>) -> Result<usize, String> {
    let value = take_string(args, "--max-failures")?;
    value
        .parse::<usize>()
        .map_err(|_| format!("--max-failures requires a non-negative integer, got {value}"))
}

fn take_baseline_layout(args: &mut impl Iterator<Item = String>) -> Result<BaselineLayout, String> {
    let value = take_string(args, "--baseline-layout")?;
    match value.as_str() {
        "auto" => Ok(BaselineLayout::Auto),
        "path" => Ok(BaselineLayout::Path),
        "hash" => Ok(BaselineLayout::Hash),
        _ => Err(format!(
            "--baseline-layout must be auto, path, or hash, got {value}"
        )),
    }
}

fn take_compare_mode(args: &mut impl Iterator<Item = String>) -> Result<CompareMode, String> {
    let value = take_string(args, "--compare-mode")?;
    match value.as_str() {
        "mixed" => Ok(CompareMode::Mixed),
        "json" => Ok(CompareMode::Json),
        _ => Err(format!("--compare-mode must be mixed or json, got {value}")),
    }
}

fn default_jobs() -> usize {
    thread::available_parallelism()
        .map(|count| count.get().min(8))
        .unwrap_or(1)
}

fn usage() -> &'static str {
    "Usage: assp_baseline --packs-dir <dir> --baseline-dir <dir> --assp-exe <path> [options] [filter]\n\
\n\
Options:\n\
  --update              write/update ASSP baselines instead of comparing\n\
  --filter <text>       only run tests whose relative path contains text\n\
  --exact               make --filter or positional filter an exact match\n\
  --skip <text>         skip tests whose relative path contains text; repeatable\n\
  --jobs <count>        parallel ASSP processes for quiet runs; defaults to min(cpu, 8)\n\
  --max-failures <n>    stop after this many failures; defaults to 50, 0 disables\n\
  --baseline-layout <auto|hash|path>\n\
                        baseline lookup layout; auto prefers existing hash baselines\n\
  --baseline-suffix <name>\n\
                        hash baseline suffix, for example rssp or assp\n\
  --compare-mode <mixed|json>\n\
                        mixed follows RSSP all_parity baseline sourcing\n\
  --list                list selected simfiles without running ASSP\n\
  --quiet               suppress per-test ok lines\n\
  --temp-dir <dir>      temp directory for decompressed .zst simfiles\n\
  --keep-temp           leave decompressed .zst temp files on disk"
}

fn require_existing_dir(path: &Path, label: &str) -> Result<PathBuf, String> {
    if path.as_os_str().is_empty() {
        return Err(format!("{label} is required"));
    }
    let path = fs::canonicalize(path).map_err(|err| format!("{label} was not found: {err}"))?;
    if !path.is_dir() {
        return Err(format!("{label} is not a directory: {}", path.display()));
    }
    Ok(path)
}

fn require_existing_file(path: &Path, label: &str) -> Result<PathBuf, String> {
    if path.as_os_str().is_empty() {
        return Err(format!("{label} is required"));
    }
    let path = fs::canonicalize(path).map_err(|err| format!("{label} was not found: {err}"))?;
    if !path.is_file() {
        return Err(format!("{label} is not a file: {}", path.display()));
    }
    Ok(path)
}

fn absolute_path(path: &Path, label: &str) -> Result<PathBuf, String> {
    if path.as_os_str().is_empty() {
        return Err(format!("{label} is required"));
    }
    let path = if path.is_absolute() {
        path.to_path_buf()
    } else {
        env::current_dir()
            .map_err(|err| format!("failed to read current directory: {err}"))?
            .join(path)
    };
    Ok(path)
}

fn run(config: &mut Config) -> Result<i32, String> {
    let tests = discover_tests(config)?;
    if config.list {
        for test in &tests {
            println!("{}", test.name);
        }
        if !config.quiet {
            println!("listed {} selected simfiles", tests.len());
        }
        return Ok(0);
    }

    if config.update {
        fs::create_dir_all(&config.baseline_dir).map_err(|err| {
            format!(
                "failed to create baseline dir {}: {err}",
                config.baseline_dir.display()
            )
        })?;
    } else if !config.baseline_dir.is_dir() {
        return Err(format!(
            "baseline dir was not found: {}\nrun with --update to create baselines",
            config.baseline_dir.display()
        ));
    }

    let mut active_jobs = if config.quiet {
        config.jobs.min(tests.len().max(1))
    } else {
        1
    };
    if config.max_failures > 0 {
        active_jobs = active_jobs.min(config.max_failures);
    }
    if !config.quiet {
        println!(
            "running {} selected simfiles with {} using {} job(s)",
            tests.len(),
            config.assp_exe.display(),
            active_jobs
        );
    }

    let (failures, updated) = if active_jobs > 1 {
        run_tests_parallel(config, &tests)
    } else {
        run_tests_sequential(config, &tests)
    };

    if failures.is_empty() {
        if config.update {
            println!(
                "ok: {} selected simfiles checked, {} baselines updated",
                tests.len(),
                updated
            );
        } else {
            println!(
                "ok: {} selected simfiles matched ASSP baselines",
                tests.len()
            );
        }
        Ok(0)
    } else {
        eprintln!();
        eprintln!("{} failures:", failures.len());
        let shown = if config.max_failures == 0 {
            failures.len()
        } else {
            failures.len().min(config.max_failures)
        };
        for failure in failures.iter().take(shown) {
            eprintln!("{}:", failure.name);
            eprintln!("  {}", failure.message);
        }
        if shown < failures.len() {
            eprintln!("showing first {shown} failures");
        }
        if config.max_failures > 0
            && failures.len() >= config.max_failures
            && failures.len() < tests.len()
        {
            eprintln!(
                "stopped after reaching the failure limit ({})",
                config.max_failures
            );
            eprintln!("pass --max-failures 0 to collect every failure");
        }
        Ok(101)
    }
}

fn run_tests_sequential(config: &Config, tests: &[TestCase]) -> (Vec<Failure>, usize) {
    let mut failures = Vec::new();
    let mut updated = 0usize;
    for (index, test) in tests.iter().enumerate() {
        if !config.quiet {
            print!("test {} ... ", test.name);
            let _ = io::stdout().flush();
        }

        match run_test(config, test, index) {
            Ok(TestStatus::Ok) => {
                if !config.quiet {
                    println!("ok");
                }
            }
            Ok(TestStatus::Updated) => {
                updated += 1;
                if !config.quiet {
                    println!("updated");
                }
            }
            Err(message) => {
                if !config.quiet {
                    println!("FAILED");
                } else {
                    eprintln!("test {} ... FAILED", test.name);
                }
                failures.push(Failure {
                    name: test.name.clone(),
                    message,
                });
                if config.max_failures > 0 && failures.len() >= config.max_failures {
                    break;
                }
            }
        }
    }
    (failures, updated)
}

fn run_tests_parallel(config: &Config, tests: &[TestCase]) -> (Vec<Failure>, usize) {
    let mut jobs = config.jobs.min(tests.len().max(1));
    if config.max_failures > 0 {
        jobs = jobs.min(config.max_failures);
    }
    let next = AtomicUsize::new(0);
    let failed = AtomicUsize::new(0);
    let (tx, rx) = mpsc::channel();

    thread::scope(|scope| {
        for _ in 0..jobs {
            let tx = tx.clone();
            let next = &next;
            let failed = &failed;
            scope.spawn(move || {
                loop {
                    if config.max_failures > 0
                        && failed.load(Ordering::Relaxed) >= config.max_failures
                    {
                        break;
                    }
                    let index = next.fetch_add(1, Ordering::Relaxed);
                    if index >= tests.len() {
                        break;
                    }
                    let test = &tests[index];
                    let result = run_test(config, test, index);
                    if result.is_err() {
                        failed.fetch_add(1, Ordering::Relaxed);
                    }
                    if tx.send((index, result)).is_err() {
                        break;
                    }
                }
            });
        }
        drop(tx);
    });

    let mut results = rx.into_iter().collect::<Vec<_>>();
    results.sort_by_key(|(index, _)| *index);

    let mut failures = Vec::new();
    let mut updated = 0usize;
    for (index, result) in results {
        match result {
            Ok(TestStatus::Ok) => {}
            Ok(TestStatus::Updated) => updated += 1,
            Err(message) => {
                failures.push(Failure {
                    name: tests[index].name.clone(),
                    message,
                });
            }
        }
    }
    (failures, updated)
}

fn discover_tests(config: &Config) -> Result<Vec<TestCase>, String> {
    if config.exact
        && let Some(filter) = &config.filter
    {
        return discover_exact_test(config, filter);
    }

    let mut tests = Vec::new();
    for entry in WalkDir::new(&config.packs_dir).follow_links(false) {
        let entry = entry.map_err(|err| format!("failed to walk packs dir: {err}"))?;
        if !entry.file_type().is_file() {
            continue;
        }

        let source_path = entry.into_path();
        let Some(compressed) = simfile_compression(&source_path) else {
            continue;
        };
        let relative_path = source_path
            .strip_prefix(&config.packs_dir)
            .map_err(|err| format!("failed to make relative path: {err}"))?
            .to_path_buf();
        let name = display_relative(&relative_path);
        if !selected(config, &name) {
            continue;
        }

        tests.push(TestCase {
            name,
            relative_path,
            source_path,
            compressed,
        });
    }

    tests.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(tests)
}

fn discover_exact_test(config: &Config, filter: &str) -> Result<Vec<TestCase>, String> {
    if config.skips.iter().any(|skip| filter.contains(skip)) {
        return Ok(Vec::new());
    }

    let relative_path = path_from_name(filter);
    let source_path = config.packs_dir.join(&relative_path);
    if !source_path.is_file() {
        return Ok(Vec::new());
    }
    let Some(compressed) = simfile_compression(&source_path) else {
        return Ok(Vec::new());
    };

    Ok(vec![TestCase {
        name: display_relative(&relative_path),
        relative_path,
        source_path,
        compressed,
    }])
}

fn path_from_name(name: &str) -> PathBuf {
    let mut path = PathBuf::new();
    for part in name.split('\\').filter(|part| !part.is_empty()) {
        path.push(part);
    }
    path
}

fn simfile_compression(path: &Path) -> Option<bool> {
    match lower_extension(path)?.as_str() {
        "sm" | "ssc" => Some(false),
        "zst" => {
            let stem = path.file_stem()?;
            match lower_extension(Path::new(stem))?.as_str() {
                "sm" | "ssc" => Some(true),
                _ => None,
            }
        }
        _ => None,
    }
}

fn lower_extension(path: &Path) -> Option<String> {
    path.extension()
        .and_then(OsStr::to_str)
        .map(str::to_ascii_lowercase)
}

fn display_relative(path: &Path) -> String {
    path.components()
        .map(|component| component.as_os_str().to_string_lossy())
        .collect::<Vec<_>>()
        .join("\\")
}

fn selected(config: &Config, name: &str) -> bool {
    if config.skips.iter().any(|skip| name.contains(skip)) {
        return false;
    }
    match &config.filter {
        Some(filter) if config.exact => name == filter,
        Some(filter) => name.contains(filter),
        None => true,
    }
}

fn run_test(config: &Config, test: &TestCase, index: usize) -> Result<TestStatus, String> {
    let input = prepare_input(config, test, index)?;
    let actual = run_assp_json(config, &input.path)?;

    if !config.update && config.compare_mode == CompareMode::Mixed {
        compare_mixed_baselines(config, test, &input.md5, &actual)?;
        return Ok(TestStatus::Ok);
    }

    let baseline_path = resolve_baseline_path(config, test, &input.md5)?;
    if !config.update && !baseline_path.exists() {
        return Err(format!(
            "missing baseline {}\nrun with --update to create ASSP baselines, or check --baseline-dir",
            baseline_path.display()
        ));
    }

    if config.update {
        let needs_write = read_baseline(&baseline_path)
            .map(|expected| expected != actual)
            .unwrap_or(true);
        if needs_write {
            write_baseline(&baseline_path, &actual)?;
            Ok(TestStatus::Updated)
        } else {
            Ok(TestStatus::Ok)
        }
    } else {
        let expected = read_baseline(&baseline_path)?;
        if values_equal(&expected, &actual) {
            Ok(TestStatus::Ok)
        } else {
            let diff = first_diff(&expected, &actual, "$");
            Err(format!(
                "mismatch at {}: expected {}, actual {}",
                diff.path,
                brief_json(diff.expected),
                brief_json(diff.actual)
            ))
        }
    }
}

fn prepare_input(config: &Config, test: &TestCase, index: usize) -> Result<PreparedInput, String> {
    if !test.compressed {
        let bytes = fs::read(&test.source_path)
            .map_err(|err| format!("failed to read {}: {err}", test.source_path.display()))?;
        return Ok(PreparedInput {
            path: test.source_path.clone(),
            md5: format!("{:x}", md5::compute(&bytes)),
        });
    }

    fs::create_dir_all(&config.temp_dir).map_err(|err| {
        format!(
            "failed to create temp dir {}: {err}",
            config.temp_dir.display()
        )
    })?;
    let bytes = fs::read(&test.source_path)
        .map_err(|err| format!("failed to read {}: {err}", test.source_path.display()))?;
    let decoded = decode_all(&bytes[..])
        .map_err(|err| format!("failed to decompress {}: {err}", test.source_path.display()))?;
    let md5 = format!("{:x}", md5::compute(&decoded));
    let inner_ext = test
        .source_path
        .file_stem()
        .and_then(|stem| Path::new(stem).extension())
        .and_then(OsStr::to_str)
        .unwrap_or("ssc");
    let temp_path = config.temp_dir.join(format!("{index:06}.{inner_ext}"));
    fs::write(&temp_path, &decoded).map_err(|err| {
        format!(
            "failed to write temp simfile {}: {err}",
            temp_path.display()
        )
    })?;
    Ok(PreparedInput {
        path: temp_path,
        md5,
    })
}

fn run_assp_json(config: &Config, input_path: &Path) -> Result<Value, String> {
    let output = Command::new(&config.assp_exe)
        .arg(input_path)
        .arg("--json")
        .output()
        .map_err(|err| format!("failed to run {}: {err}", config.assp_exe.display()))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let stdout = String::from_utf8_lossy(&output.stdout);
        return Err(format!(
            "ASSP exited with {}: {}{}",
            output.status,
            brief_text(&stderr),
            brief_text(&stdout)
        ));
    }

    serde_json::from_slice(&output.stdout).map_err(|err| {
        format!(
            "ASSP produced invalid JSON for {}: {err}",
            input_path.display()
        )
    })
}

type ChartKey = (String, String);
type ChartIndex = HashMap<ChartKey, Vec<usize>>;

#[derive(Clone, Copy)]
enum ChartShape {
    Harness,
    RsspJson,
}

fn compare_mixed_baselines(
    config: &Config,
    test: &TestCase,
    file_md5: &str,
    actual: &Value,
) -> Result<(), String> {
    let harness_path = hash_baseline_path(config, file_md5, "");
    let rssp_path = hash_baseline_path(config, file_md5, "rssp");
    if !harness_path.exists() {
        return Err(format!(
            "missing harness baseline {}\nexpected ITGmania/reference values for most fields",
            harness_path.display()
        ));
    }
    if !rssp_path.exists() {
        return Err(format!(
            "missing RSSP baseline {}\nexpected RSSP-owned values for matrix/breakdown/pattern fields",
            rssp_path.display()
        ));
    }

    let harness = read_baseline(&harness_path)?;
    let rssp = read_baseline(&rssp_path)?;
    let harness_charts = harness.as_array().ok_or_else(|| {
        format!(
            "harness baseline {} should be a chart array",
            harness_path.display()
        )
    })?;
    let rssp_charts = array_at(&rssp, &["charts"]).ok_or_else(|| {
        format!(
            "RSSP baseline {} should contain a charts array",
            rssp_path.display()
        )
    })?;
    let actual_charts =
        array_at(actual, &["charts"]).ok_or_else(|| "ASSP JSON missing charts array".to_owned())?;

    compare_metadata(test, harness_charts, actual)?;

    let harness_index = build_chart_index(harness_charts, ChartShape::Harness);
    let rssp_index = build_chart_index(rssp_charts, ChartShape::RsspJson);
    let actual_index = build_chart_index(actual_charts, ChartShape::RsspJson);

    compare_harness_charts(&harness_index, harness_charts, &actual_index, actual_charts)?;
    compare_rssp_charts(&rssp_index, rssp_charts, &actual_index, actual_charts)?;
    Ok(())
}

fn compare_metadata(
    test: &TestCase,
    harness_charts: &[Value],
    actual: &Value,
) -> Result<(), String> {
    let first = harness_charts
        .first()
        .ok_or_else(|| "harness baseline has no charts".to_owned())?;
    for field in [
        "title",
        "subtitle",
        "artist",
        "title_translated",
        "subtitle_translated",
        "artist_translated",
    ] {
        let expected = string_at(first, &[field]).unwrap_or_default();
        for chart in harness_charts.iter().skip(1) {
            if string_at(chart, &[field]).unwrap_or_default() != expected {
                return Err(format!(
                    "inconsistent harness metadata field {field} in {}",
                    test.name
                ));
            }
        }
    }

    compare_metadata_field(
        actual,
        "title",
        string_at(first, &["title"]).unwrap_or_default(),
    )?;
    compare_metadata_field(
        actual,
        "subtitle",
        string_at(first, &["subtitle"]).unwrap_or_default(),
    )?;
    compare_metadata_field(
        actual,
        "artist",
        string_at(first, &["artist"]).unwrap_or_default(),
    )?;
    compare_metadata_field(
        actual,
        "title_trans",
        string_at(first, &["title_translated"]).unwrap_or_default(),
    )?;
    compare_metadata_field(
        actual,
        "subtitle_trans",
        string_at(first, &["subtitle_translated"]).unwrap_or_default(),
    )?;
    compare_metadata_field(
        actual,
        "artist_trans",
        string_at(first, &["artist_translated"]).unwrap_or_default(),
    )
}

fn compare_metadata_field(
    actual: &Value,
    actual_field: &str,
    expected: &str,
) -> Result<(), String> {
    let actual_value = actual_metadata_value(actual, actual_field);
    let ok = actual_value == expected
        || ((actual_field == "subtitle" || actual_field == "subtitle_trans")
            && expected.is_empty()
            && has_hash_prefix(actual_value))
        || ((actual_field == "artist" || actual_field == "artist_trans")
            && expected == "Unknown artist"
            && has_hash_prefix(actual_value));
    if ok {
        Ok(())
    } else {
        Err(format!(
            "metadata mismatch at {actual_field} from harness baseline: expected {:?}, actual {:?}",
            expected, actual_value
        ))
    }
}

fn actual_metadata_value<'a>(actual: &'a Value, field: &str) -> &'a str {
    match field {
        "title_trans" => string_at(actual, &["title_trans"])
            .filter(|value| !value.is_empty())
            .or_else(|| string_at(actual, &["title"]))
            .unwrap_or_default(),
        "subtitle_trans" => string_at(actual, &["subtitle_trans"])
            .filter(|value| !value.is_empty())
            .or_else(|| string_at(actual, &["subtitle"]))
            .unwrap_or_default(),
        "artist_trans" => string_at(actual, &["artist_trans"])
            .filter(|value| !value.is_empty())
            .or_else(|| string_at(actual, &["artist"]))
            .unwrap_or_default(),
        _ => string_at(actual, &[field]).unwrap_or_default(),
    }
}

fn has_hash_prefix(value: &str) -> bool {
    value.trim_start().starts_with('#')
}

fn build_chart_index(charts: &[Value], shape: ChartShape) -> ChartIndex {
    let mut map = HashMap::new();
    for (index, chart) in charts.iter().enumerate() {
        if let Some(key) = chart_key(chart, shape) {
            map.entry(key).or_insert_with(Vec::new).push(index);
        }
    }
    map
}

fn chart_key(chart: &Value, shape: ChartShape) -> Option<ChartKey> {
    let (step_type, difficulty) = match shape {
        ChartShape::Harness => (
            string_at(chart, &["steps_type"])?,
            string_at(chart, &["difficulty"])?,
        ),
        ChartShape::RsspJson => (
            string_at(chart, &["chart_info", "step_type"])?,
            string_at(chart, &["chart_info", "difficulty"])?,
        ),
    };
    let step_type = step_type.trim().replace('_', "-").to_ascii_lowercase();
    if step_type != "dance-single" && step_type != "dance-double" {
        return None;
    }
    let difficulty = normalize_difficulty_label(difficulty).to_ascii_lowercase();
    Some((step_type, difficulty))
}

fn sorted_index_entries(index: &ChartIndex) -> Vec<(&ChartKey, &Vec<usize>)> {
    let mut entries = index.iter().collect::<Vec<_>>();
    entries.sort_by(|a, b| a.0.cmp(b.0));
    entries
}

fn compare_harness_charts(
    harness_index: &ChartIndex,
    harness_charts: &[Value],
    actual_index: &ChartIndex,
    actual_charts: &[Value],
) -> Result<(), String> {
    for (key, expected_indices) in sorted_index_entries(harness_index) {
        let actual_indices = actual_index
            .get(key)
            .ok_or_else(|| missing_chart_message("harness", key))?;
        compare_chart_count("harness", key, expected_indices, actual_indices)?;
        for (ordinal, (&expected_index, &actual_index)) in
            expected_indices.iter().zip(actual_indices).enumerate()
        {
            let expected = &harness_charts[expected_index];
            let actual = &actual_charts[actual_index];
            let label = chart_label(key, ordinal, expected);
            compare_harness_chart(&label, expected, actual)?;
        }
    }
    Ok(())
}

fn compare_harness_chart(label: &str, expected: &Value, actual: &Value) -> Result<(), String> {
    compare_path_value(
        label,
        "step_artist",
        "harness",
        get_path(expected, &["step_artist"]),
        get_path(actual, &["chart_info", "step_artists"]),
    )?;
    compare_path_value(
        label,
        "sha1",
        "harness",
        get_path(expected, &["hash"]),
        get_path(actual, &["chart_info", "sha1"]),
    )?;
    compare_path_value(
        label,
        "timing.hash_bpms",
        "harness",
        get_path(expected, &["hash_bpms"]),
        get_path(actual, &["timing", "hash_bpms"]),
    )?;
    compare_path_value(
        label,
        "timing.bpms_formatted",
        "harness",
        get_path(expected, &["bpms"]),
        get_path(actual, &["timing", "bpms_formatted"]),
    )?;
    for (expected_path, actual_path) in [
        ("bpm_min", "timing.bpm_min"),
        ("bpm_max", "timing.bpm_max"),
        ("display_bpm", "timing.display_bpm"),
        ("display_bpm_min", "timing.display_bpm_min"),
        ("display_bpm_max", "timing.display_bpm_max"),
    ] {
        compare_path_value(
            label,
            actual_path,
            "harness",
            get_path(expected, &[expected_path]),
            get_dotted_path(actual, actual_path),
        )?;
    }
    compare_rounded_number(
        label,
        "timing.duration_seconds",
        "harness",
        get_path(expected, &["duration_seconds"]),
        get_path(actual, &["timing", "duration_seconds"]),
    )?;
    compare_harness_timing(label, expected, actual)?;
    compare_harness_nps(label, expected, actual)?;
    compare_harness_counts(label, expected, actual)?;
    compare_harness_tech_counts(label, expected, actual)?;
    compare_harness_streams(label, expected, actual)
}

fn compare_harness_timing(label: &str, expected: &Value, actual: &Value) -> Result<(), String> {
    for field in [
        "beat0_offset_seconds",
        "beat0_group_offset_seconds",
        "bpms",
        "stops",
        "delays",
        "time_signatures",
        "warps",
        "labels",
        "tickcounts",
        "combos",
        "speeds",
        "scrolls",
        "fakes",
    ] {
        compare_path_value(
            label,
            &format!("timing.{field}"),
            "harness",
            get_path(expected, &["timing", field]),
            get_path(actual, &["timing", field]),
        )?;
    }
    Ok(())
}

fn compare_harness_nps(label: &str, expected: &Value, actual: &Value) -> Result<(), String> {
    for (expected_path, actual_path) in [
        ("peak_nps", "nps.max_nps"),
        ("notes_per_measure", "nps.notes_per_measure"),
        ("nps_per_measure", "nps.nps_per_measure"),
        (
            "equally_spaced_per_measure",
            "nps.equally_spaced_per_measure",
        ),
    ] {
        compare_path_value(
            label,
            actual_path,
            "harness",
            get_path(expected, &[expected_path]),
            get_dotted_path(actual, actual_path),
        )?;
    }
    Ok(())
}

fn compare_harness_counts(label: &str, expected: &Value, actual: &Value) -> Result<(), String> {
    for (expected_path, actual_path) in [
        ("holds", "arrow_stats.holds"),
        ("mines", "arrow_stats.mines"),
        ("rolls", "arrow_stats.rolls"),
        ("notes", "arrow_stats.total_arrows"),
        ("lifts", "gimmicks.lifts"),
        ("fakes", "gimmicks.fakes"),
        ("jumps", "arrow_stats.jumps"),
        ("hands", "arrow_stats.hands"),
    ] {
        compare_path_value(
            label,
            actual_path,
            "harness",
            get_path(expected, &[expected_path]),
            get_dotted_path(actual, actual_path),
        )?;
    }

    let expected_steps =
        get_path(expected, &["taps_and_holds"]).or_else(|| get_path(expected, &["total_steps"]));
    compare_path_value(
        label,
        "arrow_stats.total_steps",
        "harness",
        expected_steps,
        get_path(actual, &["arrow_stats", "total_steps"]),
    )
}

fn compare_harness_tech_counts(
    label: &str,
    expected: &Value,
    actual: &Value,
) -> Result<(), String> {
    for field in [
        "crossovers",
        "footswitches",
        "sideswitches",
        "jacks",
        "brackets",
        "doublesteps",
    ] {
        compare_path_value(
            label,
            &format!("tech_counts.{field}"),
            "harness",
            get_path(expected, &["tech_counts", field]),
            get_path(actual, &["tech_counts", field]),
        )?;
    }
    Ok(())
}

fn compare_harness_streams(label: &str, expected: &Value, actual: &Value) -> Result<(), String> {
    for (expected_path, actual_path) in [
        ("streams_breakdown", "stream_breakdown.detailed_breakdown"),
        (
            "streams_breakdown_level1",
            "stream_breakdown.partial_breakdown",
        ),
        (
            "streams_breakdown_level2",
            "stream_breakdown.simple_breakdown",
        ),
        ("total_stream_measures", "stream_info.total_streams"),
        ("total_break_measures", "stream_info.total_breaks"),
        ("stream_sequences", "stream_info.stream_sequences"),
    ] {
        compare_path_value(
            label,
            actual_path,
            "harness",
            get_path(expected, &[expected_path]),
            get_dotted_path(actual, actual_path),
        )?;
    }
    Ok(())
}

fn compare_rssp_charts(
    rssp_index: &ChartIndex,
    rssp_charts: &[Value],
    actual_index: &ChartIndex,
    actual_charts: &[Value],
) -> Result<(), String> {
    let compare_patterns = actual_charts.iter().any(|chart| {
        get_path(chart, &["mono_candle_stats"]).is_some()
            || get_path(chart, &["pattern_counts"]).is_some()
    });

    for (key, expected_indices) in sorted_index_entries(rssp_index) {
        let actual_indices = actual_index
            .get(key)
            .ok_or_else(|| missing_chart_message("RSSP", key))?;
        compare_chart_count("RSSP", key, expected_indices, actual_indices)?;
        for (ordinal, (&expected_index, &actual_index)) in
            expected_indices.iter().zip(actual_indices).enumerate()
        {
            let expected = &rssp_charts[expected_index];
            let actual = &actual_charts[actual_index];
            let label = chart_label(key, ordinal, expected);
            compare_rssp_chart(&label, expected, actual, compare_patterns)?;
        }
    }
    Ok(())
}

fn compare_rssp_chart(
    label: &str,
    expected: &Value,
    actual: &Value,
    compare_patterns: bool,
) -> Result<(), String> {
    compare_path_value(
        label,
        "chart_info.matrix_rating",
        "RSSP",
        get_path(expected, &["chart_info", "matrix_rating"]),
        get_path(actual, &["chart_info", "matrix_rating"]),
    )?;
    compare_path_value(
        label,
        "breakdown",
        "RSSP",
        get_path(expected, &["breakdown"]),
        get_path(actual, &["breakdown"]),
    )?;
    compare_path_value(
        label,
        "stream_info.sn_breaks",
        "RSSP",
        get_path(expected, &["stream_info", "sn_breaks"]),
        get_path(actual, &["stream_info", "sn_breaks"]),
    )?;

    if compare_patterns {
        compare_path_value(
            label,
            "mono_candle_stats",
            "RSSP",
            get_path(expected, &["mono_candle_stats"]),
            get_path(actual, &["mono_candle_stats"]),
        )?;
        for field in ["boxes", "anchors"] {
            compare_path_value(
                label,
                &format!("pattern_counts.{field}"),
                "RSSP",
                get_path(expected, &["pattern_counts", field]),
                get_path(actual, &["pattern_counts", field]),
            )?;
        }
    }
    Ok(())
}

fn missing_chart_message(source: &str, key: &ChartKey) -> String {
    format!(
        "missing actual chart for {source} baseline entry {} {}",
        key.0, key.1
    )
}

fn compare_chart_count(
    source: &str,
    key: &ChartKey,
    expected: &[usize],
    actual: &[usize],
) -> Result<(), String> {
    if expected.len() == actual.len() {
        Ok(())
    } else {
        Err(format!(
            "chart count mismatch for {source} baseline entry {} {}: expected {}, actual {}",
            key.0,
            key.1,
            expected.len(),
            actual.len()
        ))
    }
}

fn chart_label(key: &ChartKey, ordinal: usize, chart: &Value) -> String {
    let rating = string_at(chart, &["meter"])
        .or_else(|| string_at(chart, &["chart_info", "rating"]))
        .unwrap_or("");
    if rating.is_empty() {
        format!("{} {} #{}", key.0, key.1, ordinal + 1)
    } else {
        format!("{} {} [{}]", key.0, key.1, rating)
    }
}

fn compare_path_value(
    chart: &str,
    field: &str,
    source: &str,
    expected: Option<&Value>,
    actual: Option<&Value>,
) -> Result<(), String> {
    match (expected, actual) {
        (Some(expected), Some(actual)) if values_equal(expected, actual) => Ok(()),
        _ => Err(format!(
            "{chart}: mismatch at {field} from {source} baseline: expected {}, actual {}",
            option_brief_json(expected),
            option_brief_json(actual)
        )),
    }
}

fn compare_rounded_number(
    chart: &str,
    field: &str,
    source: &str,
    expected: Option<&Value>,
    actual: Option<&Value>,
) -> Result<(), String> {
    let expected = expected.and_then(Value::as_f64).map(round_sig_figs_itg);
    let actual = actual.and_then(Value::as_f64).map(round_sig_figs_itg);
    if expected.is_some() && expected == actual {
        Ok(())
    } else {
        Err(format!(
            "{chart}: mismatch at {field} from {source} baseline: expected {}, actual {}",
            expected.map_or_else(|| "missing".to_owned(), |value| value.to_string()),
            actual.map_or_else(|| "missing".to_owned(), |value| value.to_string())
        ))
    }
}

fn get_dotted_path<'a>(value: &'a Value, path: &str) -> Option<&'a Value> {
    let parts = path.split('.').collect::<Vec<_>>();
    get_path(value, &parts)
}

fn get_path<'a>(value: &'a Value, path: &[&str]) -> Option<&'a Value> {
    let mut current = value;
    for key in path {
        current = current.get(*key)?;
    }
    Some(current)
}

fn array_at<'a>(value: &'a Value, path: &[&str]) -> Option<&'a Vec<Value>> {
    get_path(value, path)?.as_array()
}

fn string_at<'a>(value: &'a Value, path: &[&str]) -> Option<&'a str> {
    get_path(value, path).and_then(Value::as_str)
}

fn option_brief_json(value: Option<&Value>) -> String {
    value.map_or_else(|| "missing".to_owned(), brief_json)
}

fn resolve_baseline_path(
    config: &Config,
    test: &TestCase,
    file_md5: &str,
) -> Result<PathBuf, String> {
    if config.update {
        return Ok(match config.baseline_layout {
            BaselineLayout::Path => path_baseline_path(config, test, None),
            BaselineLayout::Auto | BaselineLayout::Hash => hash_baseline_path(
                config,
                file_md5,
                config.baseline_suffix.as_deref().unwrap_or("assp"),
            ),
        });
    }

    match config.baseline_layout {
        BaselineLayout::Path => Ok(path_baseline_path(
            config,
            test,
            config.baseline_suffix.as_deref(),
        )),
        BaselineLayout::Hash => {
            if let Some(suffix) = config.baseline_suffix.as_deref() {
                Ok(hash_baseline_path(config, file_md5, suffix))
            } else {
                first_existing_hash_baseline(config, file_md5).ok_or_else(|| {
                    missing_hash_baseline_message(
                        config,
                        file_md5,
                        &hash_baseline_candidates(config, file_md5),
                    )
                })
            }
        }
        BaselineLayout::Auto => {
            let mut candidates = hash_baseline_candidates(config, file_md5);
            candidates.push(path_baseline_path(
                config,
                test,
                config.baseline_suffix.as_deref(),
            ));
            candidates
                .iter()
                .find(|path| path.exists())
                .cloned()
                .ok_or_else(|| missing_hash_baseline_message(config, file_md5, &candidates))
        }
    }
}

fn path_baseline_path(config: &Config, test: &TestCase, suffix: Option<&str>) -> PathBuf {
    let mut path = config.baseline_dir.clone();
    if let Some(parent) = test.relative_path.parent() {
        path.push(parent);
    }
    let file_name = test
        .relative_path
        .file_name()
        .map(|name| name.to_string_lossy())
        .unwrap_or_else(|| "baseline".into());
    let suffix = suffix
        .filter(|suffix| !suffix.trim().is_empty())
        .map(normalize_suffix);
    match suffix {
        Some(suffix) => path.push(format!("{file_name}.{suffix}")),
        None => path.push(format!("{file_name}.json.zst")),
    }
    path
}

fn first_existing_hash_baseline(config: &Config, file_md5: &str) -> Option<PathBuf> {
    hash_baseline_candidates(config, file_md5)
        .into_iter()
        .find(|path| path.exists())
}

fn hash_baseline_candidates(config: &Config, file_md5: &str) -> Vec<PathBuf> {
    if let Some(suffix) = config.baseline_suffix.as_deref() {
        return vec![hash_baseline_path(config, file_md5, suffix)];
    }
    ["assp", "rssp", ""]
        .into_iter()
        .map(|suffix| hash_baseline_path(config, file_md5, suffix))
        .collect()
}

fn hash_baseline_path(config: &Config, file_md5: &str, suffix: &str) -> PathBuf {
    let subfolder = &file_md5[0..2];
    config
        .baseline_dir
        .join(subfolder)
        .join(format!("{file_md5}.{}", normalize_suffix(suffix)))
}

fn normalize_suffix(suffix: &str) -> String {
    let suffix = suffix.trim().trim_matches('.');
    match suffix {
        "" | "json.zst" => "json.zst".to_owned(),
        _ if suffix.ends_with(".json.zst") => suffix.to_owned(),
        _ => format!("{suffix}.json.zst"),
    }
}

fn missing_hash_baseline_message(
    config: &Config,
    file_md5: &str,
    candidates: &[PathBuf],
) -> String {
    let expected = candidates
        .iter()
        .map(|path| format!("\n  {}", path.display()))
        .collect::<String>();
    format!(
        "missing baseline for uncompressed MD5 {file_md5}. Checked:{expected}\nrun with --update to create ASSP baselines, or pass --baseline-suffix rssp to require RSSP baselines under {}",
        config.baseline_dir.display()
    )
}

fn read_baseline(path: &Path) -> Result<Value, String> {
    let bytes = fs::read(path).map_err(|err| {
        format!(
            "failed to read baseline {}: {err}\nrun with --update to create or refresh it",
            path.display()
        )
    })?;
    let json = decode_all(&bytes[..])
        .map_err(|err| format!("failed to decompress baseline {}: {err}", path.display()))?;
    serde_json::from_slice(&json)
        .map_err(|err| format!("baseline {} is not valid JSON: {err}", path.display()))
}

fn write_baseline(path: &Path, value: &Value) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|err| format!("failed to create baseline dir {}: {err}", parent.display()))?;
    }
    let json = serde_json::to_vec(value).map_err(|err| format!("failed to encode JSON: {err}"))?;
    let compressed = encode_all(&json[..], 3)
        .map_err(|err| format!("failed to compress baseline {}: {err}", path.display()))?;
    fs::write(path, compressed)
        .map_err(|err| format!("failed to write baseline {}: {err}", path.display()))
}

struct JsonDiff<'a> {
    path: String,
    expected: &'a Value,
    actual: &'a Value,
}

fn values_equal(expected: &Value, actual: &Value) -> bool {
    match (expected, actual) {
        (Value::Number(expected), Value::Number(actual)) => numbers_equal(expected, actual),
        (Value::Array(expected), Value::Array(actual)) => {
            expected.len() == actual.len()
                && expected
                    .iter()
                    .zip(actual)
                    .all(|(expected, actual)| values_equal(expected, actual))
        }
        (Value::Object(expected), Value::Object(actual)) => {
            expected.len() == actual.len()
                && expected.iter().all(|(key, expected)| {
                    actual
                        .get(key)
                        .is_some_and(|actual| values_equal(expected, actual))
                })
        }
        _ => expected == actual,
    }
}

fn numbers_equal(expected: &serde_json::Number, actual: &serde_json::Number) -> bool {
    if let (Some(expected), Some(actual)) = (expected.as_i64(), actual.as_i64()) {
        return expected == actual;
    }
    if let (Some(expected), Some(actual)) = (expected.as_u64(), actual.as_u64()) {
        return expected == actual;
    }
    match (expected.as_f64(), actual.as_f64()) {
        (Some(expected), Some(actual)) => (expected - actual).abs() <= f64::EPSILON,
        _ => false,
    }
}

fn first_diff<'a>(expected: &'a Value, actual: &'a Value, path: &str) -> JsonDiff<'a> {
    match (expected, actual) {
        (Value::Array(expected_items), Value::Array(actual_items)) => {
            for (index, (expected_item, actual_item)) in
                expected_items.iter().zip(actual_items.iter()).enumerate()
            {
                if !values_equal(expected_item, actual_item) {
                    return first_diff(expected_item, actual_item, &format!("{path}[{index}]"));
                }
            }
            JsonDiff {
                path: format!("{path}.len"),
                expected,
                actual,
            }
        }
        (Value::Object(expected_map), Value::Object(actual_map)) => {
            for (key, expected_value) in expected_map {
                match actual_map.get(key) {
                    Some(actual_value) if values_equal(expected_value, actual_value) => {}
                    Some(actual_value) => {
                        return first_diff(expected_value, actual_value, &format!("{path}.{key}"));
                    }
                    None => {
                        return JsonDiff {
                            path: format!("{path}.{key}"),
                            expected: expected_value,
                            actual,
                        };
                    }
                }
            }
            for (key, actual_value) in actual_map {
                if !expected_map.contains_key(key) {
                    return JsonDiff {
                        path: format!("{path}.{key}"),
                        expected,
                        actual: actual_value,
                    };
                }
            }
            JsonDiff {
                path: path.to_owned(),
                expected,
                actual,
            }
        }
        _ => JsonDiff {
            path: path.to_owned(),
            expected,
            actual,
        },
    }
}

fn brief_json(value: &Value) -> String {
    let text = serde_json::to_string(value).unwrap_or_else(|_| "<json encode failed>".to_owned());
    brief_text(&text)
}

fn brief_text(text: &str) -> String {
    let text = text.trim();
    const LIMIT: usize = 240;
    if text.chars().count() <= LIMIT {
        text.to_owned()
    } else {
        format!("{}...", text.chars().take(LIMIT).collect::<String>())
    }
}
