current_date=$(date "+%Y-%m-%d")
email_address="thomas.kidd@okstate.edu"
#email_address="WALLY-REGRESSION@LISTSERV.OKSTATE.EDU"
subject="WALLY regression and coverage test report"
attachments=""
html_body=""
host_name=$(hostname) 
os_info=$(lsb_release -a 2>/dev/null)
script_location=$WALLY/bin/nightly_build/

html_body="<div id='system-info'>
    <h3>System Information</h3>
    <p><strong>Server Name:</strong> $host_name@okstate.edu</p>  
    <p><strong>Operating System:</strong> $os_info</p>
    <p><strong>Script Origin:</strong> $script_location</p>
</div>

<p>Testing sending HTML content through mutt</p>"

# Iterate through the files and concatenate their content to the body
for file in $WALLY/../build-results/builds/*/wally_*_"$current_date"*.md; do
    attachments+=" -a $file"

    # Convert Markdown to HTML using pandoc
    html_content=$(pandoc "$file")

    # add the file full path
    # html_body+="<p>File: $file</p>"
    # Append the HTML content to the body
    html_body+="$html_content"
done
echo "Sending email"

# Get server hostname and OS information
host_name=$(hostname)
os_info=$(uname -a)

# Define HTML body content

# Use mutt to send the email with HTML body
#mutt -e "my_hdr From:James Stine <james.stine@okstate.edu>" -s "$subject" $attachments \
mutt -e "my_hdr From:Thomas Kidd <thomas.kidd@okstate.edu>" -s "$subject"  \
    -e "set content_type=text/html" -- $email_address <<EOF
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nightly Build Results - $current_date</title>
    <style>
        body {
            font-family: 'Helvetica Neue', Arial, sans-serif;
            margin: 20px;
            padding: 20px;
            background-color: #f4f4f4;
        }
        h1, h3, p {
            color: #333;
        }
        #system-info {
            border: 1px solid #ddd;
            padding: 15px;
            margin-bottom: 20px;
            background-color: #fff;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
<!--	.success { color: green; } -->
<!--    .failure { color: red; }   -->

    </style>
</head>
<body>
    <h1 id="test-results---$current_date">Test Results - $current_date</h1>
    
    $html_body
</body>
</html>
EOF

