import os
import argparse
from datetime import datetime
import re
from colorama import init, Fore, Style

def parse_regression_output(output):
    passed_configs = []
    failed_configs = []

    lines = output.split('\n')
    index = 0

    while index < len(lines):
        # Remove ANSI escape codes
        line = re.sub(r'\x1b\[[0-9;]*[mGK]', '', lines[index])  
        if "Success" in line:
            passed_configs.append(line.split(':')[0].strip())
        elif "Failures detected in output" in line:
            try:
                config_name = line.split(':')[0].strip()
                log_file = os.path.abspath(config_name+".log") 
                failed_configs.append((config_name, log_file))
            except:
                failed_configs.append((config_name, "Log file not found"))

        index += 1

    # alphabetically sort the configurations
    passed_configs.sort()
    failed_configs.sort()
    return passed_configs, failed_configs

def write_to_markdown(passed_configs, failed_configs, output_file):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with open(output_file, 'a') as md_file:
        md_file.write(f"\n\n# Coverage Test Results - {timestamp}\n\n")

        md_file.write("\n## Failed Configurations\n")
        for config, log_file in failed_configs:
            md_file.write(f"- <span class=\"failure\" style=\"color: red;\">{config}</span> ({log_file})\n")
            if len(failed_configs) == 0:
                md_file.write(" - no failures\n")

        md_file.write("\n## Passed Configurations\n")
        for config in passed_configs:
            md_file.write(f"- <span class=\"success\" style=\"color: green;\">{config}</span>\n")


def write_new_markdown(passed_configs, failed_configs):
    timestamp = datetime.now().strftime("%Y-%m-%d")
    output_file = f"/home/thkidd/nightly_runs/build-results/builds/coverage/wally_coverage_{timestamp}.md"
    
    with open(output_file, 'w') as md_file:
        # Title
        md_file.write(f"\n\n# Coverage Test Results - {timestamp}\n\n")
        
        ## File path
        md_file.write(f"\n**File:** {output_file}\n")

        md_file.write("\n## Failed Configurations\n")
        # add in if there were no failures
        if len(failed_configs) == 0:
            md_file.write(f"No Failures\n")
        
        for config, log_file in failed_configs:
                md_file.write(f"- <span class=\"failure regression\" style=\"color: red;\">{config}</span> ({log_file})\n")

        md_file.write("\n## Passed Configurations\n")
        for config in passed_configs:
            md_file.write(f"- <span class=\"success regression\" style=\"color: green;\">{config}</span>\n")




if __name__ == "__main__":
    init(autoreset=True)  # Initialize colorama
    parser = argparse.ArgumentParser(description='Parse regression test output and append to a markdown file.')
    parser.add_argument('-i', '--input', help='Input file containing regression test output', required=True)
    parser.add_argument('-o', '--output', help='Output markdown file', default='regression_results.md')
    args = parser.parse_args()

    with open(args.input, 'r') as input_file:
        regression_output = input_file.read()

    passed_configs, failed_configs = parse_regression_output(regression_output)
    write_to_markdown(passed_configs, failed_configs, args.output)

    print(f"Markdown file updated: {args.output}")

    write_new_markdown(passed_configs, failed_configs)

    print("New markdown file created")

