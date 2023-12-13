#!/bin/bash
# noter 1.2.3 - "nice styles" - @k@layer8.space - mit

showgenerator="true"
backtotop="true"
lastupdated="true"
#rssfeed="true"


# a pretty nifty little logging utility!
nlog() {
    local ORANGE='\033[0;33m'
    local NO_COLOR='\033[0m'
    local calling_function=${FUNCNAME[1]}
    
    echo -e "${ORANGE}[noter] ${calling_function} | ${1} ${NO_COLOR}"
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
        nlog "$1 set to $2"
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
    # NOTE TO SELF: Figure out parsing html blocks (ie: <code>) so that we can apply styles for whole
    # elements instead of doing what we're doing right now...
    local note_date="$(date -d "$(basename "$1" .txt)" +"%B %d, %Y")"
    for img in $(grep -oP '(?<=<img src=").*?(?=")' "$1"); do
        # Check if the loading attribute already exists
        if ! grep -q "src=\"$img\" loading=\"lazy\"" "$1"; then
            # Add the loading attribute if it doesn't exist
            sed -i "s|<img src=\"$img\"|<img src=\"$img\" loading=\"lazy\"|g" "$1"
        fi
    done
    
    echo "<a name='$(basename "$1" .txt)'></a>"
    echo "<div class='note'>"
    if [ "$2" = true ]; then
        echo "<h3><a href='#$(date -d "$(basename "$1" .txt)" +"%Y")'>$(date -d "$(basename "$1" .txt)" +"%Y")</a></h3>"
    fi
    echo "<h4><a href='#$(basename "$1" .txt)'>$note_date</a></h4>"
    echo "$(cat "$1")</br>"
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


# this took way too long but fuck it
# im faster than Google at getting a
# feed going goddamit!
generate_rss_feed() {
    nlog "generating rss feed"
    local rss_file="feed.xml"
    local rss_title="koutsies telenotes"
    local rss_description="thoughts about mainly computers... maybe recipes and cats too?"
    local rss_link="https://k0.tel/"
    local rss_pubdate=$(date -u +"%a, %d %b %Y %H:%M:%S GMT")
    
    xml_escape() {
        local content="$1"
        sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g' <<< "$content"
    }
    
    # im sorry for these crimes against humanity
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
    <rss version=\"2.0\">
    <channel>
    <title>$(xml_escape "$rss_title")</title>
    <link>$rss_link</link>
    <description>$(xml_escape "$rss_description")</description>
    <pubDate>$rss_pubdate</pubDate>
    <lastBuildDate>$rss_pubdate</lastBuildDate>
    <docs>https://cyber.harvard.edu/rss/rss.html</docs>
    <generator>noter</generator>" >"$rss_file"
    
    # this works, don't touch.
    for file in $(find notes -name '*.txt' -type f -print0 | sort -zr | xargs -0); do
        if [ -f "$file" ] && [ -s "$file" ]; then
            nlog "$file"
            local note_date=$(date -d "$(basename "$file" .txt)" +"%a, %d %b %Y %H:%M:%S GMT")
            local note_link="$rss_link#$(basename "$file" .txt)"
            local note_title=$(basename "$file" .txt)
            local note_description=$(head -n 1 "$file")
            # Currently we use the first line of the note as the description
            # This could be improved uppon by using a selector or something to grab
            # the title for example from a h1 or something as (at least I) tend to
            # use those when i type posts.
            
            echo "  <item>
    <title>$(xml_escape "$note_title")</title>
    <link>$note_link</link>
    <description>$(xml_escape "$note_description")</description>
    <pubDate>$note_date</pubDate>
            </item>" >>"$rss_file"
        fi
    done
    
    echo "</channel>
    </rss>" >>"$rss_file"
    
    nlog "rss feed generated, please remember to move it too with the site: $rss_file"
}

# why is this stray here, im too afraid to move it
# godspeed notecount...
notecount=$(find notes -name "*.txt" ! -empty | wc -l)

# Create HTML file
output_file="index.html"
echo "<!DOCTYPE html>
<html>
<head>
  <meta charset='utf-8'>
  <title>$notecount notes | noter</title>
  <meta property='og:title' content='koutsies telenotes' />
  <meta property='og:description' content='thoughts about mainly computers... maybe recipes and cats too?' />
  <meta property='og:type' content='blog' />
  <meta property='og:generator' content='noter' />
  <!-- those who seek, shall see - but thy shall be prepared... -->
  <link rel='icon' type='image/png' href='$(givefavicon "$favicon")'>
  <link rel='alternate' type='application/atom+xml' title="rss" href='/feed.xml' />
  <meta name='last-generated' content='$(date +"%Y-%m-%d %H:%M:%S")' />
  <style>
    body {
      background-color: #0f0f0f;
      color: #fff;
      font-family: 'Arial Rounded MT', sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100%;
      margin: 0;
      /* font legibility optimizations */
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
      text-rendering: optimizeLegibility;
    }
    .container {
      max-width: 800px;
      padding: 20px;
      border-radius: 15px;
    }
    .note {
      background-color: #181717;
      padding: 10px;
      margin-bottom: 20px;
      border-radius: 10px;
    }
    h1 {
      text-align: center;
    }
    h3 {
      color: #fff;
    }
    img {
      border-radius: 5px;
    }
    note {
      color: #fff;
      white-space: pre-wrap;
    }
    code {
        color: #00ff62b5;
        font-family: "Lucida Console", "Courier New", monospace;
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
      font-size: 13px;
    }
    a:link, a:visited, a:hover, a:active {
      color: #ff7b00;
      font-style: normal;
      text-decoration: underline;
    }
    /* le tableee */
    table {
        width: 100%;
        border-collapse: collapse;
        border: 1px solid #fff;
        border-radius: 8px;
        overflow: hidden;
        color: #fff;
    }

    th, td {
        padding: 10px 15px;
        border: 1px solid #fff;
        border-radius: 8px;
    }

    th {
        background: #1f1f1f;
        text-align: left;
        font-weight: bold;
    }

    td {
        background: #0b0b0b;
    }
  </style>
</head>
<body>
<div class='container'>
<h1>koutsie's telenotes</h1><br>
<center> <a rel='me' href='https://layer8.space/@k'>fedi</a> | <a href="feed.xml">rss</a> | <a href="https://the-sauna.icu/">sauna</a> </center>" >"$output_file"
generate_top_year_bar >>"$output_file"

# loop for every note in notes
nlog "generating page..."
for file in $(ls -r notes/*.txt); do
    nlog "processing: $file"
    if [ -f "$file" ] && [ -s "$file" ]; then
        generate_note_html "$file" >>"$output_file"
    fi
done

# generate page's rss feed
# TODO: don't embed to site if not enabled:tm:
generate_rss_feed

# bottom navigation
nlog "applying settings"
checksetting "<div class='generated-with'>generated with <a href='https://git.sr.ht/~koutsie/noter'>noter</a></div>" "$showgenerator"
checksetting "<div class='back-to-top'><a href='#'>Back to Top</a></div>" "$backtotop"
checksetting "<div class='last-updated'>last Updated: $(date +"%Y-%m-%d %H:%M:%S")</div>" "$lastupdated"


echo "</div>
</body>
</html>" >>"$output_file"

nlog "Done, please see: $output_file."
