# Cache-busting Liquid filter. Appends an 8-char MD5 of the file contents as a
# `?v=` query string so each deploy ships a stable URL for unchanged assets and
# a fresh URL for edited ones — bypasses GitHub Pages' fixed 600s Cache-Control
# and the browser's aggressive favicon cache without churning every asset on
# every deploy.

require "digest"

module Jekyll
  module AssetDigest
    @cache = {}

    def asset_digest(path)
      return path unless path.is_a?(String) && path.start_with?("/")

      site = @context.registers[:site]
      abs  = File.join(site.source, path.sub(%r{^/}, ""))

      digest = (AssetDigest.cache[abs] ||= File.exist?(abs) ? Digest::MD5.file(abs).hexdigest[0, 8] : nil)

      digest ? "#{path}?v=#{digest}" : path
    end

    class << self
      attr_reader :cache
    end
  end
end

Liquid::Template.register_filter(Jekyll::AssetDigest)
