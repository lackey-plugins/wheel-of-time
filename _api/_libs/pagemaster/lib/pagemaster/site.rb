# frozen_string_literal: true

module Pagemaster
  #
  #
  class Site
    attr_reader :config, :args, :opts, :collections

    #
    #
    def initialize(args, opts, config = nil)
      @args             = args
      @opts             = opts
      @config           = config || config_from_file
      @collections      = parse_collections
      @collections_dir  = @config.dig 'collections_dir'
      @source_dir       = @config.dig 'source_dir'
      @data_dir         = @config.dig 'data_dir'

      @base = "#{@config.dig 'url'}#{@config.dig 'baseurl'}"

      @data_version = `git rev-parse --short HEAD`.strip
      # @build_version = `git rev-parse --short origin/develop`.strip

      load_data
      generate_links
      create_index

      raise Error::MissingArgs, 'You must specify one or more collections after `jekyll pagemaster`' if @args.empty?
      raise Error::InvalidCollection, "Cannot find collection(s) #{@args} in config" if @collections.empty?
    end

    #
    #
    def config_from_file
      YAML.load_file "#{`pwd`.strip}/_config.yml"
    end

    #
    #
    def parse_collections
      collections_config = @config.dig 'collections'

      raise Error::InvalidConfig, "Cannot find 'collections' key in _config.yml" if collections_config.nil?

      args.map do |a|
        raise Error::InvalidArgument, "Cannot find requested collection #{a} in _config.yml" unless collections_config.key? a

        Collection.new(a, collections_config.fetch(a))
      end
    end

    #
    #
    def generate_links
      @links = Hash.new
      @collections.map do |c|
        @links[c.label] = c.generate_links @base
      end
    end

    def load_data
      @data = Hash.new
      @collections.map do |c|
        @data[c.label] = c.load_data(@data_dir)
      end
    end

    #
    #
    def generate_pages
      paths = @collections.map do |c|
        c.generate_pages @opts, @collections_dir, @source_dir, @links, @data
      end.flatten
      puts Rainbow('Done ✔').green

      paths
    end

    def create_index
      path = "_index.pagemaster.json"

      res = Hash.new
      res['jsonapi'] = { "version" => @build_version }
      res['links'] = { "self" => "#{@base}/_index.json" }
      res['meta'] = { "version" => @data_version }
      res['data'] = {
          "relationships" => {
              "collections" => {
                  "related" => @collections.map {|c| "#{@base}/#{c.label}/_index.json" if c.config.key? 'index' }
              }
          }
      }
      res['layout'] = 'jsonapi'
      res['permalink'] = "_index"

      if File.exist? path
        puts Rainbow("#{path} already exists. Skipping.").cyan
      else
        File.open(path, 'w') { |f| f.write("#{res.to_yaml}---") }
      end
    end

  end
end
