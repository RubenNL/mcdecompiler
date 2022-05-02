#!/bin/bash
version=$1
mkdir downloads
rm downloads/$version -r
mkdir downloads/$version
cd downloads/$version
url=$(curl https://launchermeta.mojang.com/mc/game/version_manifest_v2.json | jq '.versions[] | select(.id=="'$version'").url' -r)
downloads=$(curl $url | jq .downloads)
wget $(echo $downloads | jq .client.url -r)
wget $(echo $downloads | jq .client_mappings.url -r)

cd ../..
java -cp "deob-lib/*" net.md_5.specialsource.SpecialSource --in-jar downloads/$version/client.jar --out-jar downloads/$version/parsed.jar --srg-in downloads/$version/client.txt --kill-lvt 
java -jar cfr-0.148.jar downloads/$version/parsed.jar --outputdir downloads/$version/decompiled
