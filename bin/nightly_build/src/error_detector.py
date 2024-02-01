import argparse
import datetime

def add_failure_to_markdown(tag, output_file, input_file = None):
    # Get the current date and time
    current_datetime = datetime.datetime.now()
    formatted_datetime = current_datetime.strftime("%Y-%m-%d %H:%M:%S")

    # Create the failure message based on the provided tag and input content
    if tag == "make":
        failure_message = f"# {tag.capitalize()} riscof comilation failure - {formatted_datetime}\n\n"
        failure_message += f"The error was due to a problem in compiling the the riscof tests:\n\n"
        if input_file != None:
            failure_message += f"The particular error: {input_file}\n\n"
    else:
        failure_message = f"# {tag.capitalize()} Failure - {formatted_datetime}\n\n"
        failure_message += f":\n\n"

    # Append the failure message to the specified output file
    with open(output_file, "a") as file:
        file.write(failure_message)

    print(f"Failure information added to {output_file}.")

if __name__ == "__main__":
    # Set up argparse
    parser = argparse.ArgumentParser(description="Add failure information to Markdown file.")
    parser.add_argument("--tag", required=True, help="Specify the tag for the failure type (e.g., 'make', 'custom').")
    parser.add_argument("-i", required=False, help="Specify the input file containing failure details.")
    parser.add_argument("-o", required=True, help="Specify the output file to write the failure information.")

    # Parse command-line arguments
    args = parser.parse_args()

    # Call the function with the specified tag, input file, and output file
    add_failure_to_markdown(args.tag,  args.o)

