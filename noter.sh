#!/bin/bash
# noter 1.1.1 - "the oops im lazy update" - @k@layer8.space - mit

nlog() {
    local ORANGE='\033[0;33m'
    local NO_COLOR='\033[0m'
    echo -e "${ORANGE}[noter] | ${1} ${NO_COLOR}"
}

if [ ! -d "notes" ]; then
    nlog "Error: 'notes' folder not found!"
    exit 1
fi

checksetting() {
  # Use this function to check for a setting without repetition
  # Eg:
  # checksetting "yourmom" "$isyourmom"
  if [ "$2" = true ]; then
    echo "$1" >>"$output_file"
  fi

givefavicon() {
  local file_path="$1"

  if [ -f "$file_path" ]; then
    local base64_data="$(base64 -w 0 "$file_path")"
    echo "data:image/png;base64,$base64_data"
  fi
}

generate_note_html() {
    local note_date="$(date -d "$(basename "$1" .txt)" +"%B %d, %Y")"
    for img in $(grep -oP '(?<=<img src=").*?(?=")' "$1"); do
        sed -i "s|<img src=\"$img\"|<img src=\"$img\" loading=\"lazy\"|g" "$1"
    done
    echo "<a name='$(basename "$1" .txt)'></a>"
    echo "<div class='note'>"
    if [ "$2" = true ]; then
        echo "<h3><a href='#$(date -d "$(basename "$1" .txt)" +"%Y")'>$(date -d "$(basename "$1" .txt)" +"%Y")</a></h3>"
    fi
    echo "<h4><a href='$(basename "$1" .txt).html'>$note_date</a></h4>"
    echo "<pre>$(cat "$1")</pre>"
    echo "</div>"
}

generate_top_year_bar() {
    local years=$(find notes -name "*.txt" ! -empty | cut -d'/' -f2 | cut -d'-' -f1 | sort -u | tac)
    local top_bar="<center><div class='top-bar'>"
    local first_year=true
    for year in $years; do
        if [ "$first_year" = false ]; then
            top_bar+=" | "
        else
            first_year=false
        fi
        top_bar+="<a href='#$(find notes -name "$year-*.txt" ! -empty | sort -n | head -n1 | cut -d'/' -f2 | cut -d'.' -f1)'>$year</a>"
    done
    top_bar+="</div></center><br>"
    echo "$top_bar"
}

notecount=$(find notes -name "*.txt" ! -empty | wc -l)

# Create HTML file
output_file="notes.html"
echo "<!DOCTYPE html>
<html>
<head>
  <meta charset='utf-8'>
  <title>$notecount notes | noter</title>
  <meta property='og:title' content='koutsies telenotes' />
  <meta property='og:description' content='thoughts about mainly computers... maybe recipes and cats too?' />
  <meta property='og:type' content='website' />
  <meta property='og:generator' content='noter' />
  <!-- those who seek, shall see - but thy shall be prepared... -->
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
    a:link, a:visited, a:hover, a:active {
      color: #ff6600;
      text-decoration: underline;
      font-style: italic;
    }
  </style>
</head>
<body>
<div class='container'><h1>notes</h1>" >"$output_file"
generate_top_year_bar >>"$output_file"
# loop for every note in notes
nlog "generating page..."
for file in $(ls -r notes/*.txt); do
    nlog "processing: $file"
    if [ -f "$file" ] && [ -s "$file" ]; then
        generate_note_html "$file" >>"$output_file"
    fi
done

# bottom navigation
checksetting "<div class='generated-with'>generated with <a href='https://git.sr.ht/~koutsie/noter'>noter</a></div>" "$showgenerator"
checksetting "<div class='back-to-top'><a href='#'>Back to Top</a></div>" "$backtotop"
checksetting "<div class='last-updated'>last Updated: $(date +"%Y-%m-%d %H:%M:%S")</div>" "$lastupdated"

echo "</div>
</body>
</html>" >>"$output_file"

nlog "Done, please see: $output_file."
