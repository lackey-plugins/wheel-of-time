formats:
	mkdir -p _data
	cp ../data/formats.tsv _data

packdefinitions:
	mkdir -p _data
	tr \" \' < ../data/packs.tsv > _data/packs.tsv # Hack because Jekyll doesn't like quotes in TSVs

sets:
	mkdir -p sets
	for f in ../data/cards/*.tsv; do \
		bundle exec ruby _scripts/convert_tsv.rb $$f "sets/$$(basename $$f .tsv).txt"; \
	done

decks:
	mkdir -p decks
	cp ../data/decks/* decks

jekyll: sets formats packdefinitions
	bundle exec jekyll build --trace
	cp -r _site/* _tmp/
	cp _tmp/updatelist.txt.md ./
	cp _tmp/plugininfo.txt ./
	bundle exec jekyll build --trace

clean:
	rm -rf _data _site sets _tmp/formats _tmp/decks _tmp/packs _tmp/sets _tmp/formats.txt _tmp/updatelist.txt
	rm -rf .jekyll-cache updatelist.txt.md