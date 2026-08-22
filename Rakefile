TAILWIND_IN  = "assets/css/tailwind.css"
TAILWIND_OUT = "assets/css/site.css"

task default: :build

desc "Build CSS + Jekyll site"
task build: ["css:build", "jekyll:build"]

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
