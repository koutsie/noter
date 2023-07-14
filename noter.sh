#!/bin/bash
# noter 1.0.2 - @k@layer8.space - mit

# ---- ---- ---- Useless Settings
favicon="favicon.png"

# Show stuff at the bottom of the page:
showgenerator=true # Shows "generated with noter"
backtotop=true     # Shows a back to top button for easier navigation
lastupdated=true   # If we should show last update time at the bottom too

nlog() {
  local ORANGE='\033[0;33m'
  local NO_COLOR='\033[0m'
  echo -e "${ORANGE}[noter] | ${1} ${NO_COLOR}"
}

checksetting() {
  # Use this function to check for a setting without repetition
  # Eg:
  # checksetting "yourmom" "$isyourmom"
  if [ "$2" = true ]; then
    echo "$1" >>"$output_file"
  fi
}

givefavicon() {
  local file_path="$1"

  if [ -f "$file_path" ]; then
    local base64_data="$(base64 -w 0 "$file_path")"
    echo "data:image/png;base64,$base64_data"
  fi
}

generate_note_html() {
  local note_date="$(date -d "$(basename "$1" .txt)" +"%B %d, %Y")"
  echo "<div class='note'>"
  echo "<h3>$note_date</h3>"
  echo "<pre>$(cat "$1")</pre>"
  echo "</div>"
}

if [ ! -d "notes" ]; then
  nlog "Error: 'notes' folder not found!"
  exit 1
fi

notecount=$(find notes -name "*.txt" ! -empty | wc -l)

# Create HTML file
output_file="notes.html"
echo "<!DOCTYPE html>
<html>
<head>
  <meta charset='utf-8'> 
  <title>$notecount notes | noter</title>
  <meta property='og:title' content='noter | simple notes with bash' />
  <meta property='og:description' content='noter | view & share your notes' />
  <meta property='og:type' content='website' />
  <meta property='og:generator' content='noter' />
  <link rel='icon' type='image/png' href='$(givefavicon "$favicon")'>
  <meta name='last-generated' content='$(date +"%Y-%m-%d %H:%M:%S")' />
  <style>
    body {
      background-color: #0f0f0f;
      color: #fff;
      font-family: Arial, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100%;
      margin: 0;
    }
    .container {
      max-width: 800px;
      padding: 20px;
    }
    .note {
      background-color: #181717;
      padding: 10px;
      margin-bottom: 20px;
    }
    h1 {
      text-align: center;
    }
    h3 {
      color: #fff;
    }
    pre {
      color: #fff;
      white-space: pre-wrap;
    }
    .back-to-top {
      text-align: right;
      margin-top: 20px;
    }
    .last-updated {
      text-align: right;
      margin-bottom: 20px;
      color: #888;
      font-size: 12px;
    }
  </style>
</head>
<body>
<div class='container'><h1>notes</h1>" >"$output_file"

# loop for every note in notes
nlog "generating page..."
for file in $(ls -r notes/*.txt); do
  nlog "processing: $file"
  if [ -f "$file" ] && [ -s "$file" ]; then
    generate_note_html "$file" >>"$output_file"
  fi
done

# Bottom navigation
checksetting "<div class='generated-with'>generated with <a href='https://git.sr.ht/~koutsie/noter'>noter</a></div>" "$showgenerator"
checksetting "<div class='back-to-top'><a href='#'>Back to Top</a></div>" "$backtotop"
checksetting "<div class='last-updated'>last Updated: $(date +"%Y-%m-%d %H:%M:%S")</div>" "$lastupdated"

echo "</div>
</body>
</html>" >>"$output_file"

nlog "Done, please see: $output_file."
