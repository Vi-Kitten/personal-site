require 'pandoc-ruby'
require 'now-do'

def with_classes *classes
    if classes.nil?
        ""
    else
        "class=\"#{classes.join " "}\""
    end
end

def with_style style
    "style=\"#{style}\""
end

def page title, *elements
    %Q{<!DOCTYPE html>
    <html lang="en">
        <head>
            <title>#{title}</title>
            <meta charset="utf-8">
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
            <link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@300..700&family=Quicksand:wght@300..700&family=Russo+One&display=swap" rel="stylesheet">
            <link rel="stylesheet" href="/style.css">
        </head>
        <body>
            #{elements.join}
        </body>
    </html>}
end

def write_standard_page path, name, *elements
    File.open(path, 'w') do |file|
        content = div ["dark", "vertical", "scrollable", "container"], *elements, style: "width: 60%; margin: 0 auto;"
        root = div ["light", "packed", "right", "container"], filling, content, filling, style: "height: 100vh;"
        generated = page name, root
        file.puts generated
    end
end

def div classes, *elements, style: ""
    %Q{<div #{with_classes *classes} #{with_style style}>
        #{elements.join}
    </div>}
end

def filling
    div ["filling"]
end

def card *elements
    div ["bordered", "card"], *elements
end

def render_markdown path
    File.open(path, 'r') do |file|
        PandocRuby.convert(file.read, from: :markdown, to: :html)
    end
end

intro = div ["vertical", "container"], (render_markdown "index/intro.md")

blog_names = ["the-chiral-product"]

blogs = now do |;intro|
    intro = render_markdown "index/blogs-intro.md"
    cards = blog_names.map do |blog_name|
        content = render_markdown "blogs/#{blog_name}.md"
        write_standard_page "blogs/#{blog_name}.html", blog_name, content
        card (render_markdown "blogs/#{blog_name}-card.md")
    end
    card_container = div ["horizontal", "full", "wrapping", "container"], *cards
    div ["ramp", "vertical", "container"], intro, card_container
end

write_standard_page "generated.html", "Kitsune Vi Portfolio Site", intro, blogs