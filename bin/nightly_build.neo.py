
import os
import shutil
from datetime import datetime, timedelta
import time
import re
import markdown
import subprocess
import argparse
import logging
from pathlib import Path
from git import Repo

class RunCase():
    """
    Class that contains information and commands to run a command

    Inputs:
        command: str to run command
        cvw_base: Path to cvw base
        envoverrides: dictionary of environment variable names as keys with envar values to be exported before running

    Accessible data classes:
        output: list of lines directly generated from terminal by doing run(), which exports the env
    """

    def __init__(self, command: str, cvw_base: Path, envoverrides: dict[str]):
        self.command: str = command
        self.cvw_base: Path = cvw_base
        self.output = None
        # Set envoverrides based on expected wally and other information
        if "WALLY" in envoverrides.keys():
            self.envoverrides = envoverrides
        else:
            self.envoverrides: dict[str] = {"WALLY": str(self.cvw_base)} + envoverrides
        return self

    def run(self):
        """
        run the test command with a specific function
        """
        # export environment overrides and save 

        # Generate the correct command in subprocess.run() by sourcing setup.sh in cvw_base and then running the command
        self.command = f"source {self.cvw_base}/setup.sh; {self.command}"


        subprocess.run(self.command, stdout = self.output, stderr=subprocess.STDOUT, text=True, capture_output=True)


class TestManager():

    def __init__(self, nightly_basedir: Path, git_repo_link: str, emails: list[str], logger: logging):
        """
        Function that creates the directory for testing using tree and stores the root directory of tests in an object
            nightly_run_path: path to the directory for this nightly run
            results_path: path to result storage
            cvw_path: path to the directory actually containing cvw for this run
            log_path: path to raw run logs (and the logfile for this run)

        It also packs inputs into objects
            git_repo: contains the Repo class from GitPython for this specific run https://gitpython.readthedocs.io/en/stable/tutorial.html#meet-the-repo-type
            emails: A comma-separated string of emails to send the test results to.

        It also initializes two empty lists of testcase and make classes as objects
            makecases: A list of make classes to do
            testcases: A list of testcase classes to run
        """
        # Initialize logger for the test manager
        self.logger = logger

        # file paths for where the results and repos will be saved: repos and results can be changed to whatever
        today = datetime.now().strftime("%Y-%m-%d")
        yesterday_dt = datetime.now() - timedelta(days=1)
        yesterday = yesterday_dt.strftime("%Y-%m-%d")
        self.nightly_run_path = Path.home().joinpath(nightly_basedir, today)
        self.results_path = Path.home().joinpath(nightly_basedir, today, "results")
        self.log_path = Path.home().joinpath(nightly_basedir, today, "logs")
        self.log_file_path = self.log_path.joinpath("nightly_build.log")
        self.cvw_path = Path.home().joinpath(nightly_basedir, today, "cvw")
        self.previous_cvw_path = Path.home().joinpath(nightly_basedir,yesterday, "cvw")

        # Create directories for current run, log path, and results path
        os.makedirs(self.nightly_run_path)
        os.makedirs(self.log_path)
        os.makedirs(self.results_path)

        # Initialize git repo in cvw_path
        if os.path.exists(self.cvw_path):
            shutil.rmtree(self.cvw_path) # This is dangerous!
            self.logger.info(f"Removed existing cvw repo in {self.cvw_path}")
        try:
           self.repo = Repo.clone_from(git_repo_link, self.cvw_path, multi_options=['--recurse-submodules'])
        except Exception as e:
            self.logger.error(f"ERROR: Failed to clone git repo for {git_repo_link} in {self.cvw_path}")
            self.logger.error(f"ERROR trace below:")
            self.logger.error(e)
            raise Exception

        # Initialize empty make and test targets
        self.make_targets: list[tuple] = []
        self.test_targets: list[tuple] = []

        # Initialize email sending list
        self.result_email_recipients: list[str] = emails     


def main():
    #############################################
    #                 ARG PARSER                #
    #############################################

    parser = argparse.ArgumentParser(description='Nightly Verification Testing for WALLY.')
    parser.add_argument('--path',default = "nightly", help='specify the path for where the nightly repositories will be cloned ex: "nightly-runs')
    parser.add_argument('--target', default = "all", help='types of tests you can make are: all, wally-riscv-arch-test, no')
    parser.add_argument('--tests', default = "nightly", help='types of tests you can run are: nightly, test, test_lint')
    parser.add_argument('--send_email',default = "", nargs="+", help='What emails to send test results to. Example: "[email1],[email2],..."')

    args = parser.parse_args()

    #############################################
    #                 SETUP                     #
    #############################################

    receiver_emails = args.send_email

    # Link to repository
    repo_link = "https://github.com/openhwgroup/cvw"

    # =--------------------=
    #   Initialize Logging # TODO: Decide if all logging will be moved into the TestManager
    # =--------------------=

    # Set up the logger
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)

    # Create a file handler
    #file_handler = logging.FileHandler('../../logs/nightly_build.log')
    
    file_handler = logging.FileHandler(log_file_path)
    file_handler.setLevel(logging.DEBUG)

    # Create a console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)

    # Create a formatter and add it to the handlers
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)

    # Add the handlers to the logger
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    logger.info(f"arg parser path: {args.path}")
    logger.info(f"arg parser repository: {args.repository}")
    logger.info(f"arg parser target: {args.target}")
    logger.info(f"arg parser send_email: {args.send_email}")
    logger.info(f"cvw path: {cvw_path}")
    logger.info(f"results path: {results_path}")
    logger.info(f"log folder path: {log_path}")
    logger.info(f"log file path: {log_file_path}")
    
    # =-----------------------=
    #    Generate test lists
    # =-----------------------=
    tests = []
    if ("all" in args.tests):
        tests.append = [["python", "./regression-wally", ["--nightly", "--buildroot"]]]
    if ("nightly" in args.tests):
        tests.append = [["python", "./regression-wally", ["--nightly"]]]
    elif ("regression" in args.tests):
        tests.append = [["python", "./regression-wally", []]]
    elif ("lint" in args.tests):
        tests.append = [["bash", "./lint-wally", ["--nightly"]]]
    else:
        print(f"Error: Invalid test {args.tests} specified")
        raise SystemExit

    if not tests:
        logger.error(f"No tests specified, exiting.")
        raise SystemExit

    test_targets = [get_test_tuple(test) for test in tests]
    
    #############################################
    #              MAKE TESTS                   #
    #############################################

    if args.target != "no":
        test_runner.execute_makefile(target = args.target, makefile_path=test_runner.cvw)
    if args.target == "all":
        # Compile Linux for local testing
        test_runner.set_env_var("RISCV",str(test_runner.cvw))
        linux_path = test_runner.cvw / "linux"
        test_runner.execute_makefile(target = "all", makefile_path=linux_path)

    #############################################
    #               RUN TESTS                   #
    #############################################


    output_log_list = [] # a list where the output markdown file locations will be saved to
    total_number_failures = 0  # an integer where the total number failures from all of the tests will be collected
    total_number_success = 0    # an integer where the total number of sucess will be collected

    total_failures = []
    total_success = []

    for test_type, test_name, test_extensions in test_list:
        
        check, output_location = test_runner.run_tests(test_type=test_type, test_name=test_name, test_extensions=test_extensions)
        try:
            if check: # this checks if the test actually ran successfuly
                output_log_list.append(output_location)
                logger.info(f"{test_name} ran successfuly. Output location: {output_location}")
                # format tests to markdown
                try:
                    passed, failed = test_runner.clean_format_output(input_file = output_location)
                    logger.info(f"{test_name} has been formatted to markdown")
                except:
                    logger.error(f"Error occured with formatting {test_name}")

                logger.info(f"The # of failures are for {test_name}: {len(failed)}")
                total_number_failures+= len(failed)
                total_failures.append(failed)

                logger.info(f"The # of sucesses are for {test_name}: {len(passed)}")
                total_number_success += len(passed)
                total_success.append(passed)
                test_runner.rewrite_to_markdown(test_name, passed, failed)
                
                newlinechar = "\n"
                logger.info(f"Failed tests: \n{newlinechar.join([x[0] for x in failed])}")
    
        except Exception as e:
            logger.error(f"There was an error in running the tests: {e}")

    logger.info(f"The total sucesses for all tests ran are: {total_number_success}")
    logger.info(f"The total failures for all tests ran are: {total_number_failures}")

    # Copy actual test logs from sim/questa, sim/verilator, sim/vcs
    if not args.tests == "test_lint":
        test_runner.copy_sim_logs([test_runner.cvw / "sim/questa/logs", test_runner.cvw / "sim/verilator/logs", test_runner.cvw / "sim/vcs/logs"])

    #############################################
    #               FORMAT TESTS                #
    #############################################

    # Combine multiple markdown files into one file
    try:
        test_runner.combine_markdown_files(passed_tests = total_success, failed_tests = total_failures, test_list = test_list, total_number_failures = total_number_failures, total_number_success = total_number_success, test_type=args.target, markdown_file=None, args=args)
    except Exception as e:
        logger.error(f"Error combining the markdown tests called from main: {e}")

    #############################################
    #             WRITE MD TESTS                #
    #############################################
    test_runner.convert_to_html()


    #############################################
    #                SEND EMAIL                 #
    #############################################

    if receiver_emails:
        test_runner.send_email(receiver_emails=receiver_emails)

    #############################################
    #   DELETE REPOSITORY OF PREVIOUS NIGHTLYS  #
    #############################################
    threshold = time.time() - 86400*1

    for log_dir in os.listdir(args.path):
        try:
            cvw_dir = os.path.join(args.path,log_dir,"cvw")
            cvw_mtime = os.stat(cvw_dir).st_mtime
            if cvw_mtime < threshold:
                    logger.info(f"Found {cvw_dir} older than 1 day, removing")
                    shutil.rmtree(cvw_dir)
        except Exception as e:
            if os.path.exists(cvw_dir):
                logger.info(f"ERROR: Failed to remove previous nightly run repo with error {e}")

    #############################################
    #      DELETE STALE LOGS AFTER TESTING      #
    #############################################
    folder_manager.remove_stale_folders(folder=args.path, days_old=30)

if __name__ == "__main__":
    main()