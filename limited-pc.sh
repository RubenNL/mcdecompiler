set -e
echo 'loading git...'
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

echo 'downloading version list...'
rm temp -rf 2>/dev/null || true
while read line; do
	echo ""
	set -e
	version=$(jq -r .id <<< $line)
	echo "$version - started"
	cd git
	if [ $(git tag -l "$version") ]; then
		cd ..
		rm temp -rf
		echo "$version - already has a tag, so not running."
		continue
	fi
	cd ..
	mkdir temp
	type=$(jq -r .type <<< $line)
	url=$(jq -r .url <<< $line)
	release=$(jq -r .releaseTime <<< $line)
	echo "$version - downloading version info..."
	downloads=$(curl -s $url | jq -r .downloads)
	echo "$version - downloading client.jar..."
	wget -O temp/client.jar -q $(jq -r .client.url <<< $downloads)
	echo "$version - downloading mappings..."
	wget -O temp/client.txt -q $(jq -r .client_mappings.url <<< $downloads)
	echo "$version - start deobfuscate..."
	java -cp "deob-lib/*" net.md_5.specialsource.SpecialSource --in-jar temp/client.jar --out-jar temp/parsed.jar --srg-in temp/client.txt --kill-lvt > /dev/null
	rm temp/client.{jar,txt}
	echo "$version - start decompile..."
	java -jar cfr-0.148.jar temp/parsed.jar --outputdir git 2> /dev/null
	rm temp -r
	cd git
	echo "DO NOT STOP THE SCRIPT FROM HERE"
	echo "$version - started git..."
	git add .
	sed -i "1 i\\$version" summary.txt
	git reset -q summary.txt
	git commit -q -F summary.txt
	git tag -a $version -m $version
##### Enable those lines if you *really* don't have any disk space left. this reduces the maximal total usage by max 500 mb, but slows down the full process by at least 10%.
#	git repack -q
#	git gc -q --aggressive
#	git repack -q
	echo "You can stop the script, if you'd like"
	rm summary.txt
	cd ..
	echo "$version - Done!"
done <<< $(curl -s https://launchermeta.mojang.com/mc/game/version_manifest_v2.json | jq -c '.versions | .[:-(length - ([.[] | .id=="19w36a"] | index(true)))] | .[]' | tac)

cd git
git config gc.auto 1
git repack -q
git gc -q --aggressive
git repack -q
cd ..

echo "so, how long did it take? I think way too long."
