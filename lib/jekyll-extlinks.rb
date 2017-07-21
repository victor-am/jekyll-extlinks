# Jekyll ExtLinks Plugin
# Adds custom attributes to external links (rel="nofollow", target="_blank", etc.)
#
# Configuration example in _config.yml (notice the indentation matters):
#
# extlinks:
#   attributes: {rel: nofollow, target: _blank}
#   exclude: ['host3.com']
#
# (only attributes is required, the other settings are optional)
# Relative links will not be processed.
#
# Links to hosts listed in exclude will skip any attribute tampering.
#
# Links which have the attribute already will keep the attribute unchanged, like
# this one in Markdown:
# [Link text](http://someurl.com){:rel="dofollow"}
#
# Using in layouts: {{ content | extlinks }}
#
# Developed by Dmitry Ogarkov - http://ogarkov.com/jekyll/plugins/extlinks/
# Based on http://dev.mensfeld.pl/2014/12/rackrails-middleware-that-will-ensure-relnofollow-for-all-your-links/

require 'jekyll'
require 'nokogiri'

module Jekyll
  module ExtLinks
    # Access plugin config in _config.yml
    def config
      @context.registers[:site].config['extlinks'] || {}
    end

    def extlinks(content)
      attributes = Array(config['attributes'])
      exclusions = Array(config['exclude'])
      doc        = Nokogiri::HTML.fragment(content)

      # Stop if we could't parse with HTML or there are no attributes
      return content unless doc && attributes

      links = doc.css('a')

      links.each do |a|
        next if skip_link?(a.get_attribute('href'), exclusions)

        attributes.each do |attr, value|
          # TODO: Find a way to case insensitively match attributes
          element_attr = a.get_attribute(attr)
          next if element_attr && element_attr != ''

          a.set_attribute(attr, value)
        end
      end

      doc.to_s
    end

    private

    # Checks if the link should be modified
    def skip_link?(href, exclusions)
      local_link?(href) || excluded?(href, exclusions)
    end

    def local_link?(href)
      !(href =~ /\Ahttp/i)
    end

    def excluded?(url, exclusions)
      exclusions && Regexp.union(exclusions) =~ url
    end
  end
end

Liquid::Template.register_filter(Jekyll::ExtLinks)
