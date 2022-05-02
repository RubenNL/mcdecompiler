old=$1
new=$2
./download.sh $old &
./download.sh $new &
wait
diff --brief --recursive downloads/{$old,$new}/decompiled | grep -v world | grep -v gui | grep -v render | grep -v dispenser > changedFiles
#                       'differ' because i ignore files added or removed. i don't care about those.
cat changedFiles | grep 'differ' | cut -d' ' -f2,4 | xargs -L1 diff > diffLines
