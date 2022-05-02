old=$1
new=$2
./download.sh $old &
./download.sh $new &
wait
diff --brief --recursive downloads/{$old,$new}/decompiled > changedFiles
