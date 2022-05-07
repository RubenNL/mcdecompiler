set -e
curl https://launchermeta.mojang.com/mc/game/version_manifest_v2.json | jq -c '.versions | .[:-(length - ([.[] | .id=="19w36a"] | index(true)))] | .[]' > versions
while read line; do
	version=$(jq -r .id <<< $line)
	type=$(jq -r .type <<< $line)
	url=$(jq -r .url <<< $line)
	mkdir -p downloads/$version
	jq empty downloads/$version/json.json > /dev/null 2>&1 || wget -O downloads/$version/json.json $url
	downloads=$(jq -r .downloads < downloads/$version/json.json)
	echo "$version $(jq -r .client.url <<< $downloads) $(jq -r .client.sha1 <<< $downloads)"
	echo "$version $(jq -r .client_mappings.url <<< $downloads) $(jq -r .client_mappings.sha1 <<< $downloads)"
done < versions > downloadUrls


download_version(){
	filename=downloads/$0/$(basename $1)
    test "$(sha1sum $filename 2>/dev/null | cut -d' ' -f1)" = "$2" && echo $filename already downloaded. || (echo "downloading $filename..." && wget -q -O $filename $1)
}
export -f download_version
xargs -L1 -P8 bash -c 'download_version $1 $2 $3' < downloadUrls

unpack_version(){
	set -e
	if test -f "downloads/$0/done"; then
		echo "$0 already done."
	else
		echo "$0 started"
		(rm downloads/$0/{parsed.jar,decompiled} -r 2>/dev/null) || true
		java -cp "deob-lib/*" net.md_5.specialsource.SpecialSource --in-jar downloads/$0/client.jar --out-jar downloads/$0/parsed.jar --srg-in downloads/$0/client.txt --kill-lvt > /dev/null
		java -jar cfr-0.148.jar downloads/$0/parsed.jar --outputdir downloads/$0/decompiled 2> /dev/null
		echo "done" > downloads/$0/done
		echo $0 done
	fi
}
export -f unpack_version
cut -d' ' -f1 downloadUrls  | uniq | xargs -L1 -P2 bash -c 'unpack_version $1 $2 $3'