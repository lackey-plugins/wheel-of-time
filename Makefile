.ONESHELL:
api:
	cd _api

	gem install bundler
	bundle config path vendor/bundle
	bundle install --jobs 4 --retry 3

	bundle exec jekyll pagemaster cards sets decks --trace
	bundle exec jekyll build --trace

.ONESHELL:
lackey:
	cd _lackey

	gem install bundler
	bundle config path vendor/bundle
	bundle install --jobs 4 --retry 3

	mkdir -p _data
	cp -r ../data/formats.tsv _data
	cp -r ../data/packs.tsv _data

	mkdir -p sets
	for f in ../data/cards/*.tsv; do \
		bundle exec ruby _scripts/convert_tsv.rb $$f "sets/$$(basename $$f .tsv).txt"; \
	done

	# first build
	bundle exec jekyll pagemaster cards sets decks --trace
	bundle exec jekyll build --trace
	cp -r _site/* _tmp/
	
	# updatelist
	cp _tmp/updatelist.txt.md ./
	
	# second build
	bundle exec jekyll build

all: api lackey

.ONESHELL:
clean_api:
	cd _api
	rm -rf ./cards ./sets ./_index.pagemaster.json

.ONESHELL:
clean_lackey:
	cd _lackey
	rm -rf _data _cards _sets _decks _site sets _tmp/formats _tmp/packs _tmp/sets _tmp/decks _tmp/formats.txt _tmp/updatelist.txt
	rm -rf .jekyll-cache updatelist.txt.md 

clean: clean_api clean_lackey