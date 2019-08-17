#!/usr/bin/env bash

_html_changelog=$( pandoc -t html "./README.md" )

echo "$_html_changelog" | sed \
    -e 's/<\(\/\)\?\(b\|i\|u\)>/[\1\2]/g' \
    -e 's/<\(\/\)\?em>/[\1i]/g' \
    -e 's/<\(\/\)\?strong>/[\1b]/g' \
    -e 's/<ul[^>]*>/[list]/g' -e 's/<ol[^>]*>/[list="1"]/g' \
    -e 's/<\/[ou]l>/[\/list]\n/g' \
    -e 's/<li>/[*]/g' -e 's/<\/li>//g' -e '/^\s*$/d' \
    -e 's/<h1[^>]*>/[size="6"]/g' -e 's/<h2[^>]*>/[size="5"]/g' -e 's/<h3[^>]*>/[size="4"]/g' \
    -e 's/<h4[^>]*>/[size="3"]/g' -e 's/<h5[^>]*>/[size="3"]/g' -e 's/<h6[^>]*>/[size="3"]/g' \
    -e 's/<\/h[1-6]>/[\/size]\n/g' \
    -e 's/<a href=\"\([^"]\+\)\"[^>]*>/[url="\1"]/g' -e 's/<\/a>/\[\/url]/g' \
    -e 's/<img src=\"\([^"]\+\)\"[^>]*>/[img]\1[\/img]/g' \
    -e 's/<\(\/\)\?blockquote>/[\1quote]\n/g' \
    -e 's/<pre><code>/[code]\n/g' -e 's/<\/code><\/pre>/[\/code]\n/g' \
    -e 's/<code>/[font="monospace"]/g' -e 's/<\/code>/[\/font]/g' \
    -e 's/<\/p>/\n/g' \
    -e 's/<[^>]\+>//g' \
    -e 's/&quot;/"/g' \
    -e 's/&amp;/&/g' \
    -e 's/&lt;/</g' \
    -e 's/&gt;/>/g' \
    -e "s/&#39;/'/g" > "build/readme.bbcode.txt"