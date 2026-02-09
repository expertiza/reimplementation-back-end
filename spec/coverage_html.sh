#!/bin/bash

# Function to display help
show_help() {
  echo "Usage: ./coverage_html.sh [OPTIONS]"
  echo ""
  echo "Generate HTML test coverage reports from SimpleCov data."
  echo ""
  echo "Options:"
  echo "  -h, --help        Display this help message"
  echo "  -r, --run         Run tests before generating reports" 
  echo "  -f, --force       Generate complete coverage report for all tracked files"
  echo "  -o, --output DIR  Output directory (default: coverage/html_reports)"
  echo "  -l, --list        List all tracked files with coverage percentages"
  echo ""
  echo "Examples:"
  echo "  ./coverage_html.sh              # Generate reports using existing data"
  echo "  ./coverage_html.sh -r           # Run tests first, then generate reports"
  echo "  ./coverage_html.sh -f           # Force complete coverage report"
  echo "  ./coverage_html.sh -l           # List all tracked files"
  echo "  ./coverage_html.sh -o my_reports # Change output directory"
}

# Default values
RUN_TESTS=false
FORCE_COMPLETE=false
OUTPUT_DIR="coverage/html_reports"
LIST_FILES=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -r|--run)
      RUN_TESTS=true
      shift
      ;;
    -f|--force)
      FORCE_COMPLETE=true
      shift
      ;;
    -o|--output)
      if [[ -z "$2" || $2 == -* ]]; then
        echo "Error: -o requires an output directory path"
        exit 1
      fi
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -l|--list)
      LIST_FILES=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Run tests if requested
if [[ $RUN_TESTS == true ]]; then
  echo "Running tests with coverage..."
  cd ..  # Move up to the project root directory
  RAILS_ENV=test bundle exec rspec spec  # Run all tests in the spec directory
  cd spec  # Return to the spec directory
fi

# Check for SimpleCov data
if [[ ! -d "../coverage" ]]; then
  echo "Error: Coverage directory not found."
  echo "Please run tests with SimpleCov enabled first, or use the -r option."
  exit 1
fi

# List all tracked files if requested
if [[ $LIST_FILES == true ]]; then
  if [[ -f "../coverage/.resultset.json" ]]; then
    echo "Listing all tracked files with coverage percentages:"
    echo "------------------------------------------------"
    # Use grep and sed to extract file paths and coverage data
    grep -oE '"[^"]+\.rb":[[]' "../coverage/.resultset.json" | sed 's/":[[]//' | sed 's/"//g' | while read -r file_path; do
      # For each file, extract its coverage data from resultset.json
      # This is a simplified approach and might need adjusting based on your resultset.json structure
      if grep -q "\"$file_path\"" "../coverage/.resultset.json"; then
        # Extract coverage data from the file section
        file_section=$(grep -A 100 "\"$file_path\"" "../coverage/.resultset.json" | grep -m 1 -B 100 "],\"")
        
        # Count covered/total lines from the file section
        covered_lines=0
        total_lines=0
        
        # Process each line number in the coverage data
        echo "$file_section" | grep -oE '[0-9]+,' | sed 's/,//' | while read -r count; do
          if [[ "$count" != "0" && "$count" != "null" ]]; then
            ((covered_lines++))
          fi
          ((total_lines++))
        done
        
        # Calculate coverage percentage
        if [[ $total_lines -gt 0 ]]; then
          coverage_percent=$(echo "scale=2; 100 * $covered_lines / $total_lines" | bc)
        else
          coverage_percent="0.00"
        fi
        
        echo "$file_path: $coverage_percent% ($covered_lines/$total_lines lines)"
      else
        echo "$file_path: No coverage data found"
      fi
    done
    exit 0
  else
    echo "Error: No .resultset.json found in coverage directory."
    echo "Please run tests with SimpleCov enabled first, or use the -r option."
    exit 1
  fi
fi

# Create output directory (in the project root)
mkdir -p "../$OUTPUT_DIR"
mkdir -p "../$OUTPUT_DIR/files"

# Create main CSS file
# (CSS content remains the same, so I've omitted it for brevity)

# Function to extract data from .resultset.json
extract_coverage_data() {
  local file_path="$1"
  local result_json="../coverage/.resultset.json"
  
  # Get file relative path for searching in the JSON
  local search_path=${file_path#"../app/"}
  
  # Check if file exists in the resultset.json
  if grep -q "\"$search_path\"" "$result_json"; then
    # Extract coverage data section for the file
    file_section=$(grep -A 100 "\"$search_path\"" "$result_json" | grep -m 1 -B 100 "\\],")
    
    # Count covered/total lines
    covered_lines=0
    total_lines=0
    
    # Extract coverage data and count
    echo "$file_section" | grep -oE '[0-9]+,' | sed 's/,//' | while read -r count; do
      if [[ "$count" != "0" && "$count" != "null" ]]; then
        ((covered_lines++))
      fi
      if [[ "$count" != "null" ]]; then
        ((total_lines++))
      fi
    done
    
    # Calculate percentage
    if [[ $total_lines -gt 0 ]]; then
      coverage_percent=$(echo "scale=2; 100 * $covered_lines / $total_lines" | bc)
    else
      coverage_percent="0.00"
    fi
    
    echo "$coverage_percent:$covered_lines:$total_lines"
  else
    # File not found in resultset
    echo "0.00:0:$(wc -l < "$file_path")"
  fi
}

# Function to get coverage data from SimpleCov
process_coverage_data() {
  echo "Processing coverage data..."

  # Extract overall stats directly from .resultset.json if it exists
  if [[ -f "../coverage/.resultset.json" && $FORCE_COMPLETE == true ]]; then
    echo "Extracting data directly from .resultset.json for complete report..."
    
    # Get all files tracked by SimpleCov
    all_files=$(grep -oE '"[^"]+\.rb":[[]' "../coverage/.resultset.json" | sed 's/":[[]//' | sed 's/"//g')
    
    # Count total files
    COV_FILES=$(echo "$all_files" | wc -l)
    
    # Initialize counters for overall stats
    total_covered_lines=0
    total_lines=0
    
    # Process each file for coverage data
    echo "$all_files" | while read -r file_path; do
      # Extract coverage data for the file
      file_data=$(extract_coverage_data "../app/$file_path")
      
      # Parse the data
      IFS=':' read -r percent covered total <<< "$file_data"
      
      # Update overall counters
      ((total_covered_lines += covered))
      ((total_lines += total))
    done
    
    # Calculate overall percentage
    if [[ $total_lines -gt 0 ]]; then
      COV_PERCENT=$(echo "scale=2; 100 * $total_covered_lines / $total_lines" | bc)
    else
      COV_PERCENT="0.00"
    fi
    
    COV_COVERED=$total_covered_lines
    COV_LINES=$total_lines
  elif [[ -f "../coverage/index.html" ]]; then
    # Use the index.html file for basic stats
    COV_PERCENT=$(grep -o "[0-9]\+\.[0-9]\+%" "../coverage/index.html" | head -1 | sed 's/%//')
    COV_FILES=$(grep -o "[0-9]\+ files" "../coverage/index.html" | head -1 | sed 's/ files//')
    COV_LINES=$(grep -o "[0-9]\+ relevant lines" "../coverage/index.html" | head -1 | sed 's/ relevant lines//')
    COV_COVERED=$(grep -o "[0-9]\+ lines covered" "../coverage/index.html" | head -1 | sed 's/ lines covered//')
  else
    echo "Warning: SimpleCov index file not found. Using placeholder data."
    COV_PERCENT="0.0"
    COV_FILES="0"
    COV_LINES="0"
    COV_COVERED="0"
  fi

  # Determine coverage level for styling
  if (( $(echo "$COV_PERCENT >= 80" | bc -l) )); then
    COV_LEVEL="high"
  elif (( $(echo "$COV_PERCENT >= 50" | bc -l) )); then
    COV_LEVEL="medium"
  else
    COV_LEVEL="low"
  fi

  # Create the main index file (HTML generation code remains mostly the same)
  cat > "../$OUTPUT_DIR/index.html" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rails Test Coverage Report</title>
  <link rel="stylesheet" href="style.css">
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      // Tab switching functionality
      const tabs = document.querySelectorAll('.tab');
      tabs.forEach(tab => {
        tab.addEventListener('click', function() {
          // Remove active class from all tabs and content
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
          document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
          
          // Add active class to clicked tab and corresponding content
          this.classList.add('active');
          document.getElementById(this.dataset.tab).classList.add('active');
        });
      });
      
      // Initialize table sorting
      const getCellValue = (tr, idx) => tr.children[idx].innerText || tr.children[idx].textContent;
      
      const comparer = (idx, asc) => (a, b) => {
        const valA = getCellValue(asc ? a : b, idx);
        const valB = getCellValue(asc ? b : a, idx);
        
        // Handle numeric sorting correctly
        const numA = parseFloat(valA);
        const numB = parseFloat(valB);
        
        if (!isNaN(numA) && !isNaN(numB)) {
          return numA - numB;
        }
        
        return valA.localeCompare(valB);
      };
      
      document.querySelectorAll('th').forEach(th => {
        th.addEventListener('click', (() => {
          const table = th.closest('table');
          const tbody = table.querySelector('tbody');
          Array.from(tbody.querySelectorAll('tr'))
            .sort(comparer(Array.from(th.parentNode.children).indexOf(th), this.asc = !this.asc))
            .forEach(tr => tbody.appendChild(tr));
        }));
      });
    });
  </script>
</head>
<body>
  <h1>Test Coverage Report</h1>
  
  <div class="dashboard">
    <div class="stat-card">
      <h3>Overall Coverage</h3>
      <div class="stat-value ${COV_LEVEL}">${COV_PERCENT}%</div>
      <div class="progress-container">
        <div class="progress-bar ${COV_LEVEL}" style="width: ${COV_PERCENT}%"></div>
      </div>
    </div>
    
    <div class="stat-card">
      <h3>Files</h3>
      <div class="stat-value">${COV_FILES}</div>
      <p>Total files analyzed</p>
    </div>
    
    <div class="stat-card">
      <h3>Lines of Code</h3>
      <div class="stat-value">${COV_LINES}</div>
      <p>Total relevant lines of code</p>
    </div>
    
    <div class="stat-card">
      <h3>Lines Covered</h3>
      <div class="stat-value">${COV_COVERED}</div>
      <p>${COV_PERCENT}% of all relevant lines</p>
    </div>
  </div>
  
  <p>
    <strong>Tip:</strong> Run <code>./coverage_html.sh -l</code> to see a complete list of all tracked files with coverage percentages.
  </p>
  
  <div class="tab-container">
    <div class="tabs">
      <div class="tab active" data-tab="tab-by-module">By Module</div>
      <div class="tab" data-tab="tab-all-files">All Files</div>
    </div>
    
    <div id="tab-by-module" class="tab-content active">
HTML

  # Add section for each type of file (controllers, models, services, etc.)
  for section in "Controllers" "Models" "Services" "Helpers"; do
    section_path=$(echo $section | tr '[:upper:]' '[:lower:]')
    
    cat >> "../$OUTPUT_DIR/index.html" << HTML
      <div class="section">
        <h2>${section}</h2>
        <table>
          <thead>
            <tr>
              <th>File</th>
              <th>Lines</th>
              <th>Lines Covered</th>
              <th>Coverage</th>
            </tr>
          </thead>
          <tbody>
HTML

    # Get all files of this type
    if [[ $FORCE_COMPLETE == true && -f "../coverage/.resultset.json" ]]; then
      # For force complete mode, extract files directly from resultset.json
      section_files=$(grep -oE "\"[^\"]+/${section_path}/[^\"]+\.rb\"" "../coverage/.resultset.json" | sed 's/"//g')
      
      echo "$section_files" | while read -r rel_path; do
        if [[ -n "$rel_path" ]]; then
          file="../app/$rel_path"
          filename=$(basename "$file")
          
          # Extract coverage data directly
          file_data=$(extract_coverage_data "$file")
          IFS=':' read -r cov_percent covered lines <<< "$file_data"
          
          # Determine coverage level
          if (( $(echo "$cov_percent >= 80" | bc -l) )); then
            cov_class="coverage-high"
          elif (( $(echo "$cov_percent >= 50" | bc -l) )); then
            cov_class="coverage-medium"
          else
            cov_class="coverage-low"
          fi
          
          # Create a dedicated file report
          file_id=$(echo "$file" | md5sum | cut -d' ' -f1)
          file_html="files/$file_id.html"
          
          # Add row to the table
          cat >> "../$OUTPUT_DIR/index.html" << HTML
            <tr>
              <td class="file-name"><a href="${file_html}" class="file-link">${filename}</a></td>
              <td>${lines}</td>
              <td>${covered}</td>
              <td><span class="coverage-badge ${cov_class}">${cov_percent}%</span></td>
            </tr>
HTML
          
          # Create file-specific HTML report (similar to your existing code)
          # ...
        fi
      done
    else
      # Use find as before for regular mode
      find "../app/${section_path}" -name "*.rb" 2>/dev/null | sort | while read -r file; do
        filename=$(basename "$file")
        rel_path=${file#"../app/"}
        
        # Extract coverage data (using your existing code)
        if [[ -f "../coverage/index.html" ]]; then
          file_html="../coverage/${rel_path/.rb/.rb.html}"
          if [[ -f "$file_html" ]]; then
            cov_percent=$(grep -o "[0-9]\+\.[0-9]\+%" "$file_html" | head -1 | sed 's/%//')
            lines=$(grep -o "LOC ([0-9]\+" "$file_html" | head -1 | sed 's/LOC (//')
            covered=$(grep -o "[0-9]\+\.[0-9]\+)" "$file_html" | head -1 | sed 's/)//')
          else
            cov_percent="0.0"
            lines=$(wc -l < "$file")
            covered="0"
          fi
        else
          cov_percent="0.0"
          lines=$(wc -l < "$file")
          covered="0"
        fi
        
        # Determine coverage level
        if (( $(echo "$cov_percent >= 80" | bc -l) )); then
          cov_class="coverage-high"
        elif (( $(echo "$cov_percent >= 50" | bc -l) )); then
          cov_class="coverage-medium"
        else
          cov_class="coverage-low"
        fi
        
        # Create a dedicated file report
        file_id=$(echo "$file" | md5sum | cut -d' ' -f1)
        file_html="files/$file_id.html"
        
        # Add row to the table
        cat >> "../$OUTPUT_DIR/index.html" << HTML
            <tr>
              <td class="file-name"><a href="${file_html}" class="file-link">${filename}</a></td>
              <td>${lines}</td>
              <td>${covered}</td>
              <td><span class="coverage-badge ${cov_class}">${cov_percent}%</span></td>
            </tr>
HTML
      done
    fi
    
    cat >> "../$OUTPUT_DIR/index.html" << HTML
          </tbody>
        </table>
      </div>
HTML
  done
  
  # Close the tab-by-module div
  cat >> "../$OUTPUT_DIR/index.html" << HTML
    </div>
    
    <div id="tab-all-files" class="tab-content">
      <table>
        <thead>
          <tr>
            <th>File</th>
            <th>Lines</th>
            <th>Lines Covered</th>
            <th>Coverage</th>
          </tr>
        </thead>
        <tbody>
HTML

  # Add all files to the All Files tab
  if [[ $FORCE_COMPLETE == true && -f "../coverage/.resultset.json" ]]; then
    # Extract all files from resultset.json
    all_files=$(grep -oE '"[^"]+\.rb":[[]' "../coverage/.resultset.json" | sed 's/":[[]//' | sed 's/"//g')
    
    echo "$all_files" | while read -r rel_path; do
      file="../app/$rel_path"
      if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        
        # Extract coverage data directly
        file_data=$(extract_coverage_data "$file")
        IFS=':' read -r cov_percent covered lines <<< "$file_data"
        
        # Determine coverage level
        if (( $(echo "$cov_percent >= 80" | bc -l) )); then
          cov_class="coverage-high"
        elif (( $(echo "$cov_percent >= 50" | bc -l) )); then
          cov_class="coverage-medium"
        else
          cov_class="coverage-low"
        fi
        
        # Create a dedicated file report
        file_id=$(echo "$file" | md5sum | cut -d' ' -f1)
        file_html="files/$file_id.html"
        
        # Add row to the table
        cat >> "../$OUTPUT_DIR/index.html" << HTML
          <tr>
            <td class="file-name"><a href="${file_html}" class="file-link">${file}</a></td>
            <td>${lines}</td>
            <td>${covered}</td>
            <td><span class="coverage-badge ${cov_class}">${cov_percent}%</span></td>
          </tr>
HTML
      fi
    done
  else
    # Use find as before
    find "../app" -name "*.rb" 2>/dev/null | sort | while read -r file; do
      filename=$(basename "$file")
      rel_path=${file#"../app/"}
      
      # Extract coverage data (using your existing code)
      # ...
      
      # Add row to the table
      # ...
    done
  fi

  # Close the all files tab and complete the HTML
  cat >> "../$OUTPUT_DIR/index.html" << HTML
          </tbody>
        </table>
      </div>
    </div>
  </div>
  
  <p class="timestamp">Generated on $(date)</p>
  <p><a href="../coverage/index.html" class="file-link">View Original SimpleCov Report</a></p>
</body>
</html>
HTML

  echo "HTML coverage report generated successfully at $OUTPUT_DIR/index.html"
}

# Main execution
process_coverage_data

# Open the report in the browser
if [[ -f "../$OUTPUT_DIR/index.html" ]]; then
  echo "Opening the HTML report..."
  open "../$OUTPUT_DIR/index.html"
else
  echo "Error: Failed to generate the HTML report."
  exit 1
fi

require 'json'

# Parse the SimpleCov .resultset.json file
resultset_path = File.join(Dir.pwd, 'coverage', '.resultset.json')
if File.exist?(resultset_path)
  data = JSON.parse(File.read(resultset_path))
  
  # Get the first coverage result (usually there's only one)
  result_key = data.keys.first
  coverage_data = data[result_key]['coverage']
  
  puts "SimpleCov tracked files (#{coverage_data.keys.count} total):"
  puts "----------------------------------------"
  
  # Sort files by path for easier reading
  coverage_data.keys.sort.each do |file_path|
    # Calculate coverage percentage
    coverage_array = coverage_data[file_path]
    next unless coverage_array.is_a?(Array)
    
    total_lines = coverage_array.count { |line| line != nil }
    covered_lines = coverage_array.count { |line| line.is_a?(Integer) && line > 0 }
    
    if total_lines > 0
      percentage = (covered_lines.to_f / total_lines * 100).round(2)
    else
      percentage = 0.0
    end
    
    puts "- #{file_path} (#{percentage}%)"
  end
else
  puts "Error: No SimpleCov .resultset.json file found at #{resultset_path}"
end