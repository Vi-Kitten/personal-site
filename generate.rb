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
            <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24..48,400,0..1,0" rel="stylesheet" />
            <link rel="stylesheet" href="/style.css">
            <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"></script>
            <script src="/main.js"></script>
        </head>
        <body>
            #{elements.join}
        </body>
    </html>}
end

# specifies default themeing in case js is not enabled
def primary 
    ["primary", "dark"]
end

def write_standard_page path, name, *elements
    File.open(path, 'w') do |file|
        content = div ["vertical", "packed", "scrollable", "padded", "container"], *elements, style: "width: 60%; margin: 0 auto;"
        side = div ["filling ramp"]
        root = div [*primary, "packed", "horizontal", "padded", "container"], side, content, side, style: "height: 100vh;"
        generated = page name, root
        file.puts generated
    end
end

def div classes, *elements, style: ""
    %Q{<div #{with_classes *classes} #{with_style style}>
        #{elements.join}
    </div>}
end

def render_markdown path
    File.open(path, 'r') do |file|
        PandocRuby.convert(file.read, from: :markdown, to: :html)
    end
end

intro = div ["vertical", "padded", "container"], (render_markdown "index/intro.md")

blog_names = ["the-chiral-product"]

blogs = now do |;intro|
    intro = render_markdown "index/blogs-intro.md"
    cards = blog_names.map do |blog_name|
        content = div ["vertical", "padded", "container", "blog"], (render_markdown "blogs/#{blog_name}.md")
        write_standard_page "blogs/#{blog_name}.html", blog_name, content
        div ["bordered"], (render_markdown "blogs/#{blog_name}-card.md")
    end
    card_container = div ["horizontal", "full", "wrapping", "padded", "container"], *cards
    div ["ramp", "vertical", "padded", "container"], intro, card_container
end

write_standard_page "generated.html", "Kitsune Vi Portfolio Site", intro, blogs