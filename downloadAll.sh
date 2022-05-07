set -e
curl https://launchermeta.mojang.com/mc/game/version_manifest_v2.json | jq -c '.versions | .[:-(length - ([.[] | .id=="19w36a"] | index(true)))] | .[]' > versions
download_json(){
	set -e
	line=$1
	version=$(jq -r .id <<< $line)
	echo "starting $version"
	type=$(jq -r .type <<< $line)
	url=$(jq -r .url <<< $line)
	release=$(jq -r .releaseTime <<< $line)
	mkdir -p downloads/$version
	jq empty downloads/$version/json.json > /dev/null 2>&1
	if [ $? -ne 0 ] || [ -s downloads/$version/json.json ]
	then
		echo "$version already downloaded"
	else
		wget -q -O downloads/$version/json.json $url
		echo "$version downloaded"
	fi
	downloads=$(jq -r .downloads < downloads/$version/json.json)
	echo "$release $version $(jq -r .client.url <<< $downloads) $(jq -r .client.sha1 <<< $downloads)" >> unsortedUrls
	echo "$release $version $(jq -r .client_mappings.url <<< $downloads) $(jq -r .client_mappings.sha1 <<< $downloads)" >> unsortedUrls
	echo "$version done"
} 
export -f download_json
echo '' > unsortedUrls
xargs -L1 -d'\n' -P8 bash -c 'download_json "$0"' < versions
sort unsortedUrls | cut -d' ' -f2- > downloadUrls

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
cut -d' ' -f1 downloadUrls  | uniq | xargs -L1 -P2 bash -c 'unpack_version $1'
cut -d' ' -f1 < downloadUrls | uniq | tac > gitVersions
if [ -d "git" ]; then
	cd git
else
	mkdir git
	cd git
	git init
	git config commit.gpgsign false
	git config user.email "git@example.com"
	git config user.name "git"
fi
git config gc.auto 0
while read version
do

	if [ "${version}" = "" ]
	then
		continue
	fi
	if [ $(git tag -l "$version") ]; then
		echo "$version already has a tag."
	else
		git rm -r --cached .
		cp ../downloads/$version/decompiled/* . -r
		git add .
		sed -i "1 i\\$version" summary.txt
		git reset summary.txt
		git commit -F summary.txt
		git tag -a $version -m $version
	fi
done < ../gitVersions
rm summary.txt
git repack
git gc --aggressive
git repack
git config gc.auto 1
