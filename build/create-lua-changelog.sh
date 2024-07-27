#!/usr/bin/env bash
#
# Copies the changelog to a format that can be loaded into WoW and displayed in-game

INPUT=CHANGELOG.md
if [ ! -f "$INPUT" ]; then
    echo "$INPUT does not exist"
	exit 1
fi

LAST_VERSION="10.0.0"
OUTPUT="Options/CHANGELOG.lua"
echo -e "if not TMW then return end\n\nTMW.CHANGELOG_LASTVER=\"$LAST_VERSION\"\n\nTMW.CHANGELOG = [==[" > $OUTPUT;
IFS=''
while read line; do
	if [[ "$line" == *"## v$LAST_VERSION"* ]]; then
		break;
	fi

	echo "$line";
done <$INPUT >>$OUTPUT

echo "]==]" >> $OUTPUT;

echo "Wrote changelog up to $LAST_VERSION to $OUTPUT";

echo 

echo git add $OUTPUT
git add $OUTPUT 2> /dev/null

exit 0
