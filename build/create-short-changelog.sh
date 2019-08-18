#!/bin/bash
#
# Copies the changelog to a format that can be loaded into WoW and displayed in-game

INPUT=CHANGELOG.md
if [ ! -f "$INPUT" ]; then
    echo "$INPUT does not exist"
	exit 1
fi



OUTPUT="CHANGELOG.short.md"
echo -e "" > $OUTPUT;
IFS=''

max_versions=1
versions=0
while read line; do
	if [[ "$line" == *"## v"* ]]; then
		((versions=versions+1))
		if [ $versions -gt $max_versions ]; then
			break;
		fi
	fi

	echo "$line";
done <$INPUT >>$OUTPUT

echo "Wrote changelog up to $max_versions versions to $OUTPUT";

# `git add`ing this is required to make the packager not exclude it.
echo 
echo git add $OUTPUT
git add $OUTPUT 2> /dev/null

exit 0
