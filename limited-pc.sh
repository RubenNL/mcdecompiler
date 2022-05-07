set -e
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
cd ..

curl https://launchermeta.mojang.com/mc/game/version_manifest_v2.json | jq -c '.versions | .[:-(length - ([.[] | .id=="19w36a"] | index(true)))] | .[]' > versions
download_version(){
	set -e
	rm client.{jar,txt} parsed.jar decompiled git/* -r 2>/dev/null || true
	line=$1
	version=$(jq -r .id <<< $line)
	cd git
	if [ $(git tag -l "$version") ]; then
		echo "$version already has a tag, so not running."
		exit
	fi
	cd ..
	type=$(jq -r .type <<< $line)
	url=$(jq -r .url <<< $line)
	release=$(jq -r .releaseTime <<< $line)
	downloads=$(curl $url | jq -r .downloads)
	wget $(jq -r .client.url <<< $downloads)
	wget $(jq -r .client_mappings.url <<< $downloads)
	java -cp "deob-lib/*" net.md_5.specialsource.SpecialSource --in-jar client.jar --out-jar parsed.jar --srg-in client.txt --kill-lvt > /dev/null
	rm client.{jar,txt}
	java -jar cfr-0.148.jar parsed.jar --outputdir decompiled 2> /dev/null
	rm parsed.jar
	mv decompiled/* git
	rm decompiled -r
	cd git
	git add .
	sed -i "1 i\\$version" summary.txt
	git reset summary.txt
	git commit -F summary.txt
	git tag -a $version -m $version
	git repack
	git gc --aggressive
	git repack
	git config gc.auto 1
	rm summary.txt
	cd ..
}
export -f download_version
xargs -L1 -d'\n' bash -c 'download_version "$0"' < versions

cd git
git config gc.auto 1
cd ..
