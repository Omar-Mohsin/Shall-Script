#!/bin/bash

# Function to display help section
show_help() {
  echo "Usage: ./file_summary.sh [OPTIONS] DIRECTORY"
  echo "Searches for files with specific extensions in the given directory and generates a comprehensive report with a summary."
  echo
  echo "Options:"
  echo "  -h, --help                    Display this help message and exit"
  echo "  -d, --directory DIRECTORY     Specify the directory path"
  echo "  -e, --extensions EXT          Specify file extensions separated by commas (e.g., -e txt,csv)"
  echo "  -s, --size                    Sort files by size in ascending order (smallest first)"
  echo "  -p, --permissions PERMISSIONS  Filter files by permissions (e.g., -p 'rwxr-xr--')"
  echo "  -m, --modified DATE           Sort files by last modified timestamp in descending order (latest first)"
  echo
}

directory=""
extension=""
sort_size=false
permissions=""
sort_modified=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0;;
        -d|--directory) directory="$2"; shift ;;
        -e|--extension) extension="$2"; shift ;;
        -s|--size) sort_size=true ;;
        -p|--permissions) permissions="$2"; shift ;;
        -m|--modified) sort_modified=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


# Check if directory argument is provided
if [ -z "$directory" ]; then
  echo "No directory specified."
  exit 1
fi

# Check if directory exists
if [ ! -d "$directory" ]; then
  echo "Directory '$directory' does not exist."
  exit 1
fi

# Search for files
echo "Content of '$directory':"
ls "$directory"
cd "$directory"

report_file="file_analysis.txt"
summary_file="summary.txt"

echo "File Analysis Report" > "$report_file"
echo "-----------------------------------------------------------------------" >> "$report_file"
echo "| File Name       | Size (bytes)  | Owner      | Permissions  | Last Modified       |" >> "$report_file"
echo "-----------------------------------------------------------------------" >> "$report_file"

find_command="find . -type f"
if [ -n "$extension" ]; then
  find_command+=" -name \"*.$extension\""
fi
if [ -n "$permissions" ]; then
  find_command+=" -perm $permissions"
fi

if $sort_size; then
  find_command+=" -exec du -b {} + | sort -n -k1,1 | cut -f2-"
fi

if $sort_modified; then
  find_command+=" -exec stat -c '%Y %n' {} + | sort -rn | cut -d' ' -f2-"
fi

eval "$find_command" | xargs stat -c "%n %s %U %A %y" | awk -F" " '{ file = $1; gsub(".*/", "", file); printf "| %-15s | %-13s | %-10s | %-12s | %-19s |\n", file, $2, $3, $4, $5 }' >> "$report_file"

# Summary variables
total_files=0
total_size=0

# Loop through the files and calculate statistics
while IFS= read -r file; do
  # Increment file count
  ((total_files++))

  # Extract the file size
  size=$(stat -c "%s" "$file")

  # Increment total size
  ((total_size += size))
done < <(eval "$find_command")

# Generate the summary report
echo "Summary Report" > "$summary_file"
echo "------------------------" >> "$summary_file"
echo "Total Files: $total_files" >> "$summary_file"
echo "Total Size: $total_size bytes" >> "$summary_file"
echo "------------------------" >> "$summary_file"

echo "report.txt has been generated. Open it to view the results."
cat "$report_file"
echo
echo
echo "summary.txt has been generated. Open it to view the summary."
cat "$summary_file"