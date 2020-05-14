formats:
	mkdir -p _data
	cp ../data/formats.tsv _data

packdefinitions:
	mkdir -p _data
	cp ../data/packs.tsv _data

jekyll: formats packdefinitions
	bundle exec jekyll build --trace
	cp -r _site/* _tmp/
	cp _tmp/updatelist.txt.md ./
	cp _tmp/plugininfo.txt ./
	bundle exec jekyll build

clean:
	rm -rf _data _site _tmp/formats _tmp/decks _tmp/packs _tmp/sets _tmp/formats.txt _tmp/updatelist.txt
	rm -rf .jekyll-cache updatelist.txt.md