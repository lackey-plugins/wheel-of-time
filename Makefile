.ONESHELL:
api:
	cd _api

	gem install bundler
	bundle config path vendor/bundle
	bundle install --jobs 4 --retry 3

	bundle exec jekyll pagemaster cards sets --trace
	bundle exec jekyll build --trace

.ONESHELL:
jekyll:
	cd _lackey

	gem install bundler
	bundle config path vendor/bundle
	bundle install --jobs 4 --retry 3

	# sets
	mkdir -p sets
	for f in ../data/cards/*.tsv; do \
		bundle exec ruby _scripts/convert_tsv.rb $$f "sets/$$(basename $$f .tsv).txt"; \
	done

	# decks
	mkdir -p decks
	cp ../data/decks/* decks

	# formats
	mkdir -p _data
	cp ../data/formats.tsv _data

	# packdefinitions
	tr \" \' < ../data/packs.tsv > _data/packs.tsv # Hack because Jekyll doesn't like quotes in TSVs

	# first build
	bundle exec jekyll build
	cp -r _site/* _tmp/
	
	# updatelist
	cp _tmp/updatelist.txt.md ./
	
	# second build
	bundle exec jekyll build

all: api jekyll

.ONESHELL:
clean_api:
	cd _api
	rm -rf ./cards ./sets ./_index.pagemaster.json

.ONESHELL:
clean_lackey:
	cd _lackey
	rm -rf _data _site sets decks _tmp/formats _tmp/decks _tmp/packs _tmp/sets _tmp/formats.txt _tmp/updatelist.txt
	rm -rf .jekyll-cache updatelist.txt.md ./_index.pagemaster.json

clean: clean_api clean_lackey