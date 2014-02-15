module Jekyll
  class TeamConfiguration
    DEFAULTS = {
      'team_index' => true,
      'team_dest'  => 'team'
    }

    def self.team_configuration(config)
      DEFAULTS.merge(config['team'] || {})
    end
  end

  class TeamIndex < Page
    def initialize(site, base, dir)
      @site = site
      @base = base
      @dir  = dir
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'team.html')
      self.data['team'] = self.get_team(site)
    end

    def get_team(site)
      {}.tap do |team|
        Dir['_team/*.yml'].each do |path|
          name   = File.basename(path, '.yml')
          config = YAML.load(File.read(File.join(@base, path)))
          type   = config['type']

          if config['active']
            team[type] = {} if team[type].nil?
            team[type][name] = config
          end
        end
      end
    end
  end

  class PersonIndex < Page
    def initialize(site, base, dir, path)
      @site     = site
      @base     = base
      @dir      = dir
      @name     = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'profile.html')
      self.data = self.data.merge(YAML.load(File.read(File.join(@base, path))))
      self.data['title'] = self.data['name']
    end
  end

  class GenerateTeam < Generator
    safe true
    priority :normal

    def generate(site)
      config = TeamConfiguration.team_configuration(site.config)
      write_team(site, config)
    end

    # Loops through the list of team pages and processes each one.
    def write_team(site, config)
      if Dir.exists?('_team')
        Dir.chdir('_team')
        Dir["*.yml"].each do |path|
          name = File.basename(path, '.yml')
          self.write_person_index(site, config, "_team/#{path}", name)
        end

        Dir.chdir(site.source)
        if config['team_index']
          self.write_team_index(site, config)
        end
      end
    end

    def write_team_index(site, config)
      team = TeamIndex.new(site, site.source, "/#{config['team_dest']}")
      site.pages << team
    end

    def write_person_index(site, config, path, name)
      person = PersonIndex.new(site, site.source, "/#{config['team_dest']}/#{name}", path)
      site.pages << person
    end
  end

  module AuthorsFilter
    def to_author_links(authors)
      connector = "and"
      return templatize(authors) if authors.is_a?(String)
      case authors.length
      when 0
        ""
      when 1
        templatize(authors[0])
      when 2
        "#{templatize(authors[0])} #{connector} #{templatize(authors[1])}"
      else
        "#{authors[0...-1].map{|a| templatize(a)}.join(', ')}, #{connector} #{templatize(authors[-1])}"
      end
    end

    private
    def templatize(author)
      site = @context.environments.first["site"]
      config = TeamConfiguration.team_configuration(@context.registers[:site].config)

      template = File.read(File.join(site['source'], '_includes', 'author.html'))
      slug = "#{author.downcase.gsub(/[ .]/, '-')}"
      file = File.join(site['source'], '_team', "#{slug}.yml")
      if File.exists?(file)
        data              = YAML.load(File.read(file))
        data['permalink'] = "/#{config['team_dest']}/#{slug}"

        Liquid::Template.parse(template).render('author' => data)
      else
        author
      end
    end
  end

end

Liquid::Template.register_filter(Jekyll::AuthorsFilter)
