#!/bin/bash
## makeps3 iso script for autogenerating isos from source folder
## should be able to run as cronjob, no software installation required, except bash and a path to your makeps3iso binary
## Expect to work: sed, tee, awk, print and find. not tested on busybox or sh, and I probably won't
## I could have implemented some cleaning up, but that would have required a safety check for succesful conversion, and there was no need for that. maybe in future revisions
## proper logging not really tested
## 1. setting variables, insert your own here
## your source folder - IMPORTANT TO LEAVE THE TRAILING SLASH
# gamedirs="/path/to/your/gamefolders/"
gamedirs="/path/to/your/gamefolders/"

## your target folder - NO TRAILING SLASH, yay, consistency. Fight me. i needed it for the slash** below
# isodir="/path/to/your/ISOs"
isodir="/path/to/your/ISOs"

## binary path
## command="/path/to/your/makeps3iso"
command="/home/USERNAME/ps3iso-utils/makeps3iso/makeps3iso"

## a tmpfile to read from later
tmpfile="/tmp/gamedirs"

## /path/to/your/logfile
logfile="/path/to/your/logfile"

## Start - you shouldn't need to edit anything below this line
## 2. preprocessing
## this removes anything but the slashes from the gamedir, and adds an N at the end of the resulting string
## hey, at least now there is no longer a hardcoded constant in here, so it should work dynamically... until it won't
## the N is just to increment the character amount by one, since, well, strings. Did I mention I'm not a coder? Works for me.
## yes this is a variable, but yes, it needs to be done after #1, so yea. preprocessing.
depth=${gamedirs//[^'/']}N

## 3. something, something, logfile, creation, y'know
echo Conversion Started > $logfile

## 4. find paths which contain a PS3 gamefolder, cut away all parent folders, put it in a tmpfile, and write something to log.
find $gamedirs -name "PS3_GAME*" -type d | sed 's,/*[^/]\+/*$,,' | tee -a $logfile | tee $tmpfile ;

## 5. starting the loop for all elements found with the find command above
## the i is the generic line index from tmpfile below that cycles through all folders
## this is to enable conversion from any (parent-) directory that contains maybe pkgfiles, isos as well as gamefolders, so you don't need to restructure everything
## also, I read somewhere this is the proper way to read...*
while read i; do

## generate a new outfile-name for each cycle - and I like having that slash here
## also, since we need the n'th part of the string, which was counted + 1 we added the N earlier.
## again. too lazy for type conversion, so...
## defining outfile, 2 lines because string nesting is naaaaasty.
## this sets the iso folder to what was set above, and adds the filename for the ISO,
## which is being read from the tmpfile(i) with the parent directory cut off on position (depth+1)
## so that the filename is drawn from the folder name + iso.
## and that defines the output
## also; THAT -v- Slash here** (:
outfile=$isodir/$(awk -F "/" '{print $'${#depth}'}' <<< "$i").iso
## again, this ^ one! (:

## probe for existing files on target, continue if NOT existing already (good for reruns/cronjob with no need for deleting your folders in source)
if [ ! -f "$outfile" ]; then

## we only want to log something and then convert , so that's what we do
## print some output for logging or whatever
echo "creating $outfile ..." >> $logfile
## actually converting the folder now, detach the process from the terminal and put something in the logfile
## tried to silence output here, but I gave up, it works, and this was basically my target that I guilt everything around, hence the vars.
$command "$i" "$outfile" & >> $logfile &> /dev/null

## if iso with same name exists on target, print a message and exit
else
   echo "Overwrite protection. Image for $i already exists, skipping... (Delete or rename manually if rebuild desired.)" | tee -a $logfile
fi

## *...a tmpfile into a loop
done <$tmpfile
