#!/usr/bin/env -S uv run --script
# Score computation for Lynn processor synthesis + coremark results
# James Kaden Cassidy 1/22/2026 kacassidy@hmc.edu
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

import os
import re
import sys
from datetime import datetime


def find_latest_synth_folder(synth_work_dir):
    """Find the most recently generated synthesis output folder."""
    if not os.path.isdir(synth_work_dir):
        raise FileNotFoundError(f"Synthesis work directory not found: {synth_work_dir}")

    folders = [f for f in os.listdir(synth_work_dir)
               if os.path.isdir(os.path.join(synth_work_dir, f)) and f.startswith('synth_top')]

    if not folders:
        raise FileNotFoundError(f"No synthesis folders found in {synth_work_dir}")

    # Sort by modification time, get latest
    latest = max(folders, key=lambda f: os.path.getmtime(os.path.join(synth_work_dir, f)))
    return os.path.join(synth_work_dir, latest)

def parse_qor_report(qor_file):
    """Parse QOR (Quality of Results) report to extract timing and area metrics."""
    if not os.path.isfile(qor_file):
        raise FileNotFoundError(f"QOR report not found: {qor_file}")

    metrics = {}

    with open(qor_file) as f:
        content = f.read()

    # Extract Critical Path Length (in nanoseconds)
    match = re.search(r'Critical Path Length:\s+([\d.]+)', content)
    if match:
        metrics['critical_path_length'] = float(match.group(1))
    else:
        raise ValueError("Could not find Critical Path Length in QOR report")

    # Extract Total Cell Area (in µm²)
    match = re.search(r'Cell Area:\s+([\d.]+)', content)
    if match:
        metrics['total_area'] = float(match.group(1))
    else:
        raise ValueError("Could not find Cell Area in QOR report")

    # Extract Worst Negative Slack (WNS)
    match = re.search(r'Design\s+WNS:\s+([\d.-]+)', content)
    if match:
        metrics['wns'] = float(match.group(1))

    # Extract Total Negative Slack (TNS)
    match = re.search(r'Design\s+WNS:.*TNS:\s+([\d.-]+)', content)
    if match:
        metrics['tns'] = float(match.group(1))

    # Extract number of violating paths
    match = re.search(r'Number of Violating Paths:\s+(\d+)', content)
    if match:
        metrics['violating_paths'] = int(match.group(1))

    # Extract leaf cell count
    match = re.search(r'Leaf Cell Count:\s+(\d+)', content)
    if match:
        metrics['leaf_cells'] = int(match.group(1))

    # Extract combinational and noncombinational areas
    match = re.search(r'Combinational Area:\s+([\d.]+)', content)
    if match:
        metrics['comb_area'] = float(match.group(1))

    match = re.search(r'Noncombinational Area:\s+([\d.]+)', content)
    if match:
        metrics['noncomb_area'] = float(match.group(1))

    # Extract levels of logic
    match = re.search(r'Levels of Logic:\s+([\d.]+)', content)
    if match:
        metrics['levels_of_logic'] = int(float(match.group(1)))

    return metrics

def parse_coremark_log(sim_log_file):
    """Parse coremark simulation log to extract benchmark metrics."""
    if not os.path.isfile(sim_log_file):
        raise FileNotFoundError(f"Coremark simulation log not found: {sim_log_file}")

    metrics = {}

    with open(sim_log_file) as f:
        content = f.read()

    # Check for successful run
    if 'SUCCESS' not in content:
        raise RuntimeError("Coremark simulation did not complete successfully (no SUCCESS marker)")

    metrics['success'] = True

    # Extract Elapsed MTIME (cycles)
    match = re.search(r'Elapsed MTIME:\s+(\d+)', content)
    if match:
        metrics['elapsed_mtime'] = int(match.group(1))
    else:
        raise ValueError("Could not find Elapsed MTIME in coremark log")

    # Extract Elapsed MINSTRET (instructions)
    match = re.search(r'Elapsed MINSTRET:\s+(\d+)', content)
    if match:
        metrics['elapsed_minstret'] = int(match.group(1))

    # Extract COREMARK/MHz score
    match = re.search(r'COREMARK/MHz Score:\s+([\d,]+)\s*/\s*(\d+)\s*=\s*([\d.]+)', content)
    if match:
        metrics['coremark_score'] = float(match.group(3))

    # Extract CPI
    match = re.search(r'CPI:\s+(\d+)\s*/\s+(\d+)\s*=\s*([\d.]+)', content)
    if match:
        metrics['cpi'] = float(match.group(3))

    # Extract CoreMark Size
    match = re.search(r'CoreMark Size\s*:\s+(\d+)', content)
    if match:
        metrics['coremark_size'] = int(match.group(1))

    # Extract Iterations
    match = re.search(r'Iterations\s*:\s+(\d+)', content)
    if match:
        metrics['iterations'] = int(match.group(1))

    return metrics

def compute_score(mtime, critical_path_ns, area_um2):
    """
    Compute composite score: (MTIME x Critical_Path_Length)^2 / Area

    This metric combines:
    - Execution time (MTIME x critical path = total execution time in ns)
    - Squared to heavily penalize slow designs
    - Normalized by area to reward efficient designs
    """
    execution_time_ns = mtime * critical_path_ns
    score = (execution_time_ns ** 2) / area_um2
    return score

def main():
    # Parse arguments
    if len(sys.argv) < 3:
        print("Usage: score.py <synth_work_dir> <coremark_work_dir> [--output-log <path>]")
        sys.exit(1)

    synth_work_dir = sys.argv[1]
    coremark_work_dir = sys.argv[2]

    # Default log output to current directory
    log_file = "score.log"
    if "--output-log" in sys.argv:
        idx = sys.argv.index("--output-log")
        if idx + 1 < len(sys.argv):
            log_file = sys.argv[idx + 1]

    try:
        # Find latest synthesis folder
        latest_synth_dir = find_latest_synth_folder(synth_work_dir)
        qor_file = os.path.join(latest_synth_dir, "reports", "qor.rep")

        # Parse reports
        synth_metrics = parse_qor_report(qor_file)

        # Find coremark log
        coremark_log = os.path.join(coremark_work_dir, "coremark.bare.riscv.sim.log")
        coremark_metrics = parse_coremark_log(coremark_log)

        # Compute score
        score = compute_score(
            coremark_metrics['elapsed_mtime'],
            synth_metrics['critical_path_length'],
            synth_metrics['total_area']
        )

        # Generate diagnostic report
        report = []
        report.append("=" * 80)
        report.append("LYNN PROCESSOR SCORE REPORT")
        report.append("=" * 80)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Synthesis Folder: {latest_synth_dir}")
        report.append(f"Coremark Log: {coremark_log}")
        report.append("")

        # Score section
        report.append("-" * 80)
        report.append("FINAL SCORE")
        report.append("-" * 80)
        score_int = int(score)
        score_dec = score - score_int
        report.append(f"Score: {score_int:,}.{int(score_dec * 100):02d}")
        report.append("  Formula: (MTIME x Critical_Path_Length)^2 / Area")
        report.append(f"  MTIME (cycles): {coremark_metrics['elapsed_mtime']:,}")
        report.append(f"  Critical Path Length (ns): {synth_metrics['critical_path_length']:.6f}")
        report.append(f"  Total Area (µm²): {synth_metrics['total_area']:,.2f}")
        report.append(f"  Execution Time (ns): {coremark_metrics['elapsed_mtime'] * synth_metrics['critical_path_length']:,.2f}")
        report.append("")

        # Coremark diagnostics
        report.append("-" * 80)
        report.append("COREMARK BENCHMARK DIAGNOSTICS")
        report.append("-" * 80)
        report.append(f"Status: {'PASSED' if coremark_metrics['success'] else 'FAILED'}")
        report.append(f"CoreMark Size: {coremark_metrics['coremark_size']}")
        report.append(f"Iterations: {coremark_metrics['iterations']}")
        report.append(f"Total Cycles (MTIME): {coremark_metrics['elapsed_mtime']:,}")
        report.append(f"Total Instructions (MINSTRET): {coremark_metrics['elapsed_minstret']:,}")
        report.append(f"CPI (Cycles Per Instruction): {coremark_metrics['cpi']:.3f}")
        report.append(f"COREMARK/MHz Score: {coremark_metrics['coremark_score']:.2f}")
        report.append("")

        # Timing diagnostics
        report.append("-" * 80)
        report.append("SYNTHESIS TIMING DIAGNOSTICS")
        report.append("-" * 80)
        report.append(f"Critical Path Length (ns): {synth_metrics['critical_path_length']:.6f}")
        report.append(f"Levels of Logic: {synth_metrics['levels_of_logic']}")
        report.append(f"Worst Negative Slack (ns): {synth_metrics['wns']:.6f}")
        report.append(f"Total Negative Slack (ns): {synth_metrics['tns']:.2f}")
        report.append(f"Number of Violating Paths: {synth_metrics['violating_paths']:,}")
        report.append("")

        # Area diagnostics
        report.append("-" * 80)
        report.append("SYNTHESIS AREA DIAGNOSTICS")
        report.append("-" * 80)
        report.append(f"Total Cell Area (µm²): {synth_metrics['total_area']:.2f}")
        report.append(f"  Combinational: {synth_metrics['comb_area']:.2f} µm²")
        report.append(f"  Noncombinational: {synth_metrics['noncomb_area']:.2f} µm²")
        report.append(f"Leaf Cell Count: {synth_metrics['leaf_cells']:,}")
        report.append("")
        report.append("=" * 80)

        # Write log file
        log_content = "\n".join(report)
        with open(log_file, 'w') as f:
            f.write(log_content)

        # Print score to stdout with exciting formatting
        score_int = int(score)
        score_dec = score - score_int
        print("")
        print("╔" + "═" * 78 + "╗")
        print("║" + " " * 78 + "║")
        print("║" + f"  LYNN PROCESSOR SCORE: {score_int:,}.{int(score_dec * 100):02d}".ljust(78) + "║")
        print("║" + " " * 78 + "║")
        print("╚" + "═" * 78 + "╝")
        print("")
        print(f"Details saved to: {log_file}")

        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
