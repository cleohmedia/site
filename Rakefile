TAILWIND_IN  = "assets/css/tailwind.css"
TAILWIND_OUT = "assets/css/site.css"

require "yaml"

OG_LANGS = YAML.load_file("_data/i18n.yml")["locales"].map { |l| l["code"] }
OG_FILES = OG_LANGS.map { |l| "assets/images/og-card-#{l}.png" }

FAVICON_SVG  = "assets/images/favicon.svg"
FAVICON_PNG  = "assets/images/favicon.png"
FAVICON_SIZE = 64

LOGO_SVG         = "assets/images/logo.svg"
APPLE_TOUCH_PNG  = "assets/images/apple-touch.png"
APPLE_TOUCH_SIZE = 180
PWA_ICON_SIZES   = [72, 96, 128, 144, 152, 192, 384, 512]
PWA_ICON_FILES   = PWA_ICON_SIZES.map { |s| "assets/images/icons/icon-#{s}.png" }
ICON_FILES       = [APPLE_TOUCH_PNG] + PWA_ICON_FILES


task default: :build

desc "Build CSS + OG cards + favicon + icons + Jekyll site"
task build: ["css:build", "og:build", "favicon:build", "icons:build", "jekyll:build"]

namespace :css do
  desc "Compile Tailwind CSS (minified)"
  task :build do
    sh "bundle exec tailwindcss -i #{TAILWIND_IN} -o #{TAILWIND_OUT} --minify"
  end

  desc "Watch and rebuild Tailwind CSS"
  task :watch do
    sh "bundle exec tailwindcss -i #{TAILWIND_IN} -o #{TAILWIND_OUT} --watch"
  end
end

namespace :jekyll do
  desc "Build site to _site/"
  task :build do
    sh "bundle exec jekyll build --trace"
  end

  desc "Serve site with livereload"
  task :serve do
    sh "bundle exec jekyll serve --livereload --trace"
  end
end

namespace :daisyui do
  desc "Update vendored daisyUI plugin to latest GitHub release"
  task :update do
    sh "curl -sL https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.js -o vendor/daisyui.js"
  end
end

desc "Local dev: watch CSS + serve Jekyll concurrently"
task :dev do
  pids = []
  pids << spawn("bundle exec tailwindcss -i #{TAILWIND_IN} -o #{TAILWIND_OUT} --watch")
  pids << spawn("bundle exec jekyll serve --livereload")
  trap("INT") do
    pids.each { |p| Process.kill("TERM", p) rescue nil }
  end
  pids.each { |p| Process.wait(p) }
end

# Spec §11's mechanical checks. The visual ones — legibility, dark mode, OG
# card rendering — stay human and live in README.md's release checklist.
desc "Assert the built site meets the spec's structural guarantees"
task :check do
  require "yaml"

  failures = []
  check = ->(desc, ok) { failures << desc unless ok }

  abort "Run `rake build` first — _site/ is missing." unless Dir.exist?("_site")

  locales = YAML.load_file("_data/i18n.yml")["locales"]

  # §11.1 — every locale built, plus the fixed pages and a non-empty stylesheet.
  locales.each do |l|
    page = File.join("_site", l["path"], "index.html")
    check.("#{l['code']} page missing at #{page}", File.size?(page).to_i > 0)
  end
  check.("404.html missing", File.size?("_site/404.html").to_i > 0)
  check.("site.css missing or empty", File.size?("_site/assets/css/site.css").to_i > 0)

  # CNAME arrives in Task 12. Once the source file exists it must reach _site
  # with the right apex, or the custom domain silently reverts to *.github.io.
  if File.exist?("CNAME")
    check.("CNAME not published to _site", File.exist?("_site/CNAME"))
    check.("CNAME apex wrong", File.exist?("_site/CNAME") && File.read("_site/CNAME").strip == "cleohmedia.com")
  end

  built = Dir.glob("_site/**/*.html")

  # §11.9 — no call to action anywhere.
  built.each do |f|
    html = File.read(f)
    check.("#{f} links to the app", !html.include?("app.cleohmedia.com"))
    check.("#{f} contains a <form>", !html.match?(/<form\b/i))
    check.("#{f} contains an <input>", !html.match?(/<input\b/i))
  end

  # §11.10 — no third-party requests. Allow only same-origin and mailto.
  built.each do |f|
    File.read(f).scan(/(?:src|href)="(https?:\/\/[^"]+)"/).flatten.each do |url|
      check.("#{f} loads third-party asset #{url}", url.start_with?("https://cleohmedia.com"))
    end
  end

  # §11.4 — canonical and hreflang are absolute and present on every locale.
  locales.each do |l|
    html = File.read(File.join("_site", l["path"], "index.html"))
    check.("#{l['code']} canonical wrong", html.include?(%(canonical" href="https://cleohmedia.com#{l['path']}")))
    check.("#{l['code']} missing x-default", html.include?('hreflang="x-default"'))
    check.("#{l['code']} lists itself as og:locale:alternate",
           !html.include?(%(og:locale:alternate" content="#{l['og_locale']}")))
    locales.each do |other|
      check.("#{l['code']} missing hreflang #{other['code']}", html.include?(%(hreflang="#{other['code']}")))
    end
  end

  # §11.3 — no copy outside the data file. Everything that is legitimately
  # not copy has to come out first: YAML front matter, inline JS, comments,
  # Liquid, markup (which carries attributes), and HTML entities. Whatever
  # survives is a bare word sitting in the template as visible text.
  #
  # "Cleoh" is the one allowed literal — the brand name in the navbar, hero
  # and 404 (see the plan's Global Constraints).
  sources = (Dir.glob("_includes/**/*.html") + Dir.glob("_layouts/*.html") +
             Dir.glob("*.html") + Dir.glob("en/*.html")).uniq
  sources.each do |f|
    text = File.read(f)
              .sub(/\A---\s*\n.*?\n---\s*\n/m, " ")            # YAML front matter
              .gsub(/<script\b.*?<\/script>/m, " ")            # inline JS is not copy
              .gsub(/<style\b.*?<\/style>/m, " ")
              .gsub(/<!--.*?-->/m, " ")                        # HTML comments
              .gsub(/\{%-?\s*comment.*?endcomment\s*-?%\}/m, " ")
              .gsub(/\{\{.*?\}\}/m, " ")                       # Liquid output is data
              .gsub(/\{%.*?%\}/m, " ")                         # Liquid tags
              .gsub(/<[^>]+>/m, " ")                           # markup, incl. attributes
              .gsub(/&[a-z]+;|&#\d+;/i, " ")                   # entities, e.g. &copy;
    stray = text.scan(/[A-Za-zÁÉÍÓÚÑáéíóúñ][A-Za-zÁÉÍÓÚÑáéíóúñ]{2,}/)
                .reject { |w| w == "Cleoh" }
    check.("#{f} contains literal copy: #{stray.uniq.first(5).join(', ')}", stray.empty?)
  end

# Code is written in English, exclusively — identifiers never carry Spanish.
# A full lexical check isn't practical, but these two catch the real failure
# modes: an accented identifier, and a half-finished rename that leaves an
# href pointing at an id that no longer exists.
built.each do |f|
  html = File.read(f)

  ids   = html.scan(/\bid="([^"]+)"/).flatten
  names = ids + html.scan(/\bhref="#([^"]+)"/).flatten + html.scan(/\bclass="([^"]*)"/).flatten

  names.each do |n|
    check.("#{f}: non-ASCII identifier #{n.inspect} — code must be English", n.ascii_only?)
  end

  html.scan(/\bhref="#([^"]+)"/).flatten.uniq.each do |target|
    next if target == "top" && ids.include?("top")
    check.("#{f}: href=\"##{target}\" has no matching id — broken or half-renamed anchor",
           ids.include?(target))
  end
end

  if failures.empty?
    puts "check: all #{locales.size}-locale structural assertions passed"
  else
    failures.each { |f| warn "FAIL  #{f}" }
    abort "check: #{failures.size} failure(s)"
  end
end

# One file rule per locale, so an untouched card is not re-rendered.
OG_LANGS.each do |lang|
  svg = "assets/images/og-card-#{lang}.svg"
  png = "assets/images/og-card-#{lang}.png"

  file png => svg do
    if system("command -v rsvg-convert > /dev/null 2>&1")
      sh "rsvg-convert -w 1200 -h 630 #{svg} -o #{png}"
    elsif system("command -v inkscape > /dev/null 2>&1")
      sh "inkscape #{svg} --export-type=png --export-filename=#{png} " \
         "--export-width=1200 --export-height=630"
    else
      abort "Need rsvg-convert (brew install librsvg / apt install librsvg2-bin) " \
            "or inkscape to render the OG cards."
    end
  end
end

namespace :og do
  desc "Render per-locale OG cards (1200x630)"
  task build: OG_FILES
end

# ImageMagick, not rsvg-convert: the favicon output must be padded to an
# exact square, and IM's -extent is the reliable way to guarantee it.
file FAVICON_PNG => FAVICON_SVG do
  cli =
    if    system("command -v magick  > /dev/null 2>&1") then "magick"
    elsif system("command -v convert > /dev/null 2>&1") then "convert"
    else abort "Need ImageMagick (brew install imagemagick / apt install imagemagick)."
    end

  sh "#{cli} -background none -density 600 #{FAVICON_SVG} " \
     "-resize #{FAVICON_SIZE}x#{FAVICON_SIZE} " \
     "-gravity center -extent #{FAVICON_SIZE}x#{FAVICON_SIZE} #{FAVICON_PNG}"
end

namespace :favicon do
  desc "Render favicon.svg -> favicon.png (64x64)"
  task build: [FAVICON_PNG]
end

def render_logo_icon(png, size)
  if system("command -v inkscape > /dev/null 2>&1")
    sh "inkscape #{LOGO_SVG} --export-type=png --export-filename=#{png} " \
       "--export-width=#{size} --export-height=#{size} --export-background-opacity=0"
  elsif system("command -v rsvg-convert > /dev/null 2>&1")
    sh "rsvg-convert -w #{size} -h #{size} #{LOGO_SVG} -o #{png}"
  elsif system("command -v magick > /dev/null 2>&1")
    sh "magick -background none -density 600 #{LOGO_SVG} -resize #{size}x#{size} #{png}"
  else
    abort "Need Inkscape, rsvg-convert or ImageMagick to render the app icons."
  end
end

file APPLE_TOUCH_PNG => LOGO_SVG do
  mkdir_p "assets/images"
  render_logo_icon(APPLE_TOUCH_PNG, APPLE_TOUCH_SIZE)
end

PWA_ICON_SIZES.each do |size|
  png = "assets/images/icons/icon-#{size}.png"
  file png => LOGO_SVG do
    mkdir_p "assets/images/icons"
    render_logo_icon(png, size)
  end
end

namespace :icons do
  desc "Render logo.svg -> apple-touch.png (180) + PWA icons (72-512)"
  task build: ICON_FILES
end
