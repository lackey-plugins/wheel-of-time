# frozen_string_literal: true

CSV::Converters[:boolean] = ->(value) {
  if value == "TRUE"
    true
  else
    value == "FALSE" ? false : value
  end
}

module Pagemaster
  #
  #
  class Collection
    attr_reader :config, :source, :id_key, :layout, :data, :dir

    #
    #
    def initialize(name, config)
      @name   = name
      @config = config
      @sources = fetch 'sources'
      @id_key = fetch 'id_key'
      @layout = fetch 'layout'
      @data_version = `git rev-parse --short HEAD`.strip
      # @build_version = `git rev-parse --short origin/develop`.strip
    end

    def label
      @name
    end

    #
    #
    def fetch(key)
      raise Error::InvalidCollection unless @config.key? key

      @config.dig key
    end

    #
    #
    def ingest_source(source, data_dir)
      file = "#{data_dir}/#{source}"
      raise Error::InvalidSource, "Cannot find source file #{file}" unless File.exist? file

      case File.extname file
      when '.csv'
        CSV.read(file, headers: true, converters: [:numeric, :boolean]).map(&:to_hash)
      when '.tsv'
        CSV.read(file, headers: true, converters: [:numeric, :boolean], col_sep: "\t", quote_char: nil).map(&:to_hash)
      when '.json'
        JSON.parse(File.read(file).encode('UTF-8'))
      when /\.ya?ml/
        YAML.load_file file
      else
        raise Error::InvalidSource, "Collection source #{file} must have a valid extension (.csv, .tsv, .yml, or .json)"
      end
    rescue StandardError => e
      puts "Rescued: #{e.inspect}"
      raise Error::InvalidSource, "Cannot load #{file}. check for typos and rebuild."
    end

    #
    #
    def validate_data
      ids = @data.map { |d| d.dig @id_key }
      raise Error::InvalidCollection, "One or more items in collection '#{@name}' is missing required id for the id_key '#{@id_key}'" unless ids.all?

      duplicates = ids.detect { |i| ids.count(i) > 1 } || []
      raise Error::InvalidCollection, "The collection '#{@name}' has the follwing duplicate ids for id_key #{@id_key}: \n#{duplicates}" unless duplicates.empty?
    end

    #
    #
    def overwrite_pages
      return unless @dir

      FileUtils.rm_rf @dir
      puts Rainbow("Overwriting #{@dir} directory with --force.").cyan
    end

    def load_data(data_dir)
      @data = []
      @sources.map do |source|
        @data.concat(ingest_source(source, data_dir))
      end
      validate_data
      @data
    end

    #
    #
    def generate_links(base)
      @base = base
      links = Hash.new

      @data.map do |d|
        path = [@name, d.dig(@id_key)].join("/")
        links[d.dig(@id_key)] = [@base, path].join('/') + ".json"
      end

      links
    end

    def build_relationships(d, links, data)
      relationships = Hash.new

      if @config.key? 'related'
        base = @config['image_base'] ? @config['image_base'] : @base

        if d.key? 'image' or d.key? 'ImageFile'
          relationships['images'] = { "links" => { "related" => [] } }

          image = d.key?('image') ? d['image'] : d['ImageFile'] + ".jpg"
          relationships['images']['links']['related'].append(
            {
              "meta" => { "type" => "front" },
              "href" => [base, image].join('/')
            }
          )

          unless @config['image_cardback'].nil?
            relationships['images']['links']['related'].append(
              {
                "meta" => { "type" => "back" },
                "href" => [base, @config['image_cardback']].join('/')
              }
            )
          end
        end

        related_config = @config['related']

        unless related_config.nil?
          related_config.each do |c|

            from_field = c.dig 'from_field'
            to_field = c.dig 'to_field'
            collection = c.dig 'collection'

            relationships[collection] = { "links" => { "related" => [] } } if relationships[collection].nil?

            col_relations = []
            if c.key? 'parse_column'
              column = c['parse_column']['column']
              if c['parse_column'].key? 'multiline'
                d[column].split('\n').each do |line|
                  col_relations.append(line)
                end
              else
                col_relations.append(d[column])
              end
              col_relations = col_relations.map do |r|
                matches = r.match(Regexp.new c['parse_column']['regex'])
                matches.named_captures
              end
            else
              col_relations.append(d)
            end

            col_relations.map do |dr|
              meta = (c['extra']['meta'] if c.key? 'extra') or {}
              if %w[from_field to_field collection].all? {|s| c.key? s}
                value = dr.dig(from_field)
                data[collection].select {|row| row[to_field] === value }.each do |r|
                  rel = {
                      "href" => links[collection][r.dig(@id_key)]
                  }
                  rel["meta"] = meta.map {|k, v| [k, (r.key?(v) ? (Integer(r.dig(v)) rescue r.dig(v)) : v)]}.to_h unless meta.nil?
                  relationships[collection]["links"]["related"].append(rel)
                end
              end
            end
          end
        end
      end

      relationships
    end
    #
    #
    def generate_pages(opts, collections_dir, source_dir, links, _data)
      @opts   = opts
      @dir    = File.join [source_dir, collections_dir, "_#{@name}"].compact
      @source_dir = source_dir

      overwrite_pages if @opts.fetch :force, false
      FileUtils.mkdir_p @dir

      @data.map do |d|
        path = [@name, d.dig(@id_key)].join("/")

        res = Hash.new
        res['jsonapi'] = { "version" => @build_version }
        res['links'] = { "self" => links[@name][d.dig(@id_key)] }
        res['meta'] = { "version" => @data_version }
        res['data'] = {
          "type" => "#{@name}",
          "id" => d.dig(@id_key),
          "attributes" => d.clone.tap { |hs| hs.delete(@id_key) },
          "relationships" => build_relationships(d, links, _data)
        }
        res['layout'] = @layout
        res['permalink'] = "#{path}"

        path_components = "#{@dir}/#{path}.pagemaster".split('/')
        final_path = path_components.join('/') + ".json"

        if File.exist? final_path
          puts Rainbow("#{final_path} already exists. Skipping.").cyan
        else
          FileUtils.mkdir_p path_components.take(path_components.size - 1).join('/') + "/"
          File.open(final_path, 'w') { |f| f.write("#{res.to_yaml}---") }
        end
        path
      end

      # Indices
      if @config.has_key? 'index'
        create_index "#{@name}/_index", links, _data
      end

      # Filters
      if @config.has_key? 'filters'
        filters = @config.dig 'filters'
        filters.each do |filter|
          filter_values = @data.map {|d| slug(d.dig(filter)) unless d.dig(filter).nil? }.uniq.compact
          filter_values.each do |filter_value|
            create_index("#{@name}/_filter/#{filter}=#{filter_value}", links, _data, filter, filter_value)
          end
        end
      end

    end

    def create_index(path, links, _data, filter_key=nil, filter_value=nil)
      path_components = "#{@dir}/#{path}.pagemaster".split('/')
      final_path = path_components.join('/') + ".json"

      data = @data

      unless filter_key.nil? and filter_value.nil?
        data = data.select {|item| item.dig(filter_key).nil? ? false : slug(item.dig filter_key) == filter_value}
      end

      res = Hash.new
      res['jsonapi'] = { "version" => @build_version }
      res['links'] = { "self" => [@base, path].join('/') + ".json" }
      res['meta'] = { "version" => @data_version }
      res['data'] = {
        "relationships" => {
          "#{@name}" => {
            "related" => data.map {|d| links[@name][d.dig(@id_key)]}
          }
        }
      }
      res['layout'] = @layout
      res['permalink'] = "#{path}"

      if File.exist? final_path
        puts Rainbow("#{final_path} already exists. Skipping.").cyan
      else
        FileUtils.mkdir_p path_components.take(path_components.size - 1).join('/') + "/"
        File.open(final_path, 'w') { |f| f.write("#{res.to_yaml}---") }
      end
    end

    #
    #
    def slug(str)
      str.downcase.tr(' ', '_').gsub(/[^:\w-]/, '').gsub(/_+/, '_')
    end
  end
end
