require 'pandoc-ruby'
require 'now-do'

Dir.mkdir('site') unless Dir.exist?('site')
Dir.mkdir('site/blogs') unless Dir.exist?('site/blogs')

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

def tape
    div ["tape"]
end

def under_construction
    crane = %Q{<img src="/crane.svg" style="height: 6rem; width: 6rem;">}
    message = %Q{<p style="font-size: 3rem;">UNDER CONSTRUTION</p>}
    div ["horizontal", "centering", "warning", "filling", "very-padded", "container"], crane, message, style: "justify-content: center;"
end

def wip
    %Q{<span class="warning"><span class="material-symbols-outlined">construction</span></span>}
end

def render_markdown path
    File.open(path, 'r') do |file|
        PandocRuby.convert(file.read, from: :markdown, to: :html)
    end
end

class PageData
    attr_reader :name
    attr_reader :excerpt

    def initialize name, excerpt, tags={}
        @name = name
        @tags = tags
        @excerpt = excerpt
    end

    def is id, default: false
        @tags.fetch(id, default)
    end

    def tags
        html = []
        if not is :complete then html.push wip end
        html
    end
end

intro = div ["vertical", "padded", "container"], (render_markdown "content/intro.md")

blogs = {
    "the-chiral-product" => PageData.new("The Chiral Product", "<p>An algebraic approach to mutation in linearly typed systems.</p>")
}

blog_links = now do |;intro|
    intro = render_markdown "content/blogs-intro.md"
    cards = blogs.map do |blog_name, page_data|
        prose = div ["vertical", "padded", "container", "blog"], (render_markdown "content/blogs/#{blog_name}.md")
        content = if page_data.is :complete then
            div ["vertical", "packed", "container"], prose
        else
            div ["vertical", "packed", "container"], prose, tape, under_construction
        end
        write_standard_page "site/blogs/#{blog_name}.html", page_data.name, content
        title = div ["centering", "horizontal", "container"], %Q{<h3><a href="/blogs/#{blog_name}.html">#{page_data.name}</a>#{page_data.tags.join ""}</h3>}
        div ["ramp", "detail"], title, page_data.excerpt, style: "flex-grow: 1;"
    end
    card_container = div ["horizontal", "full", "wrapping", "padded", "container"], *cards
    div ["vertical", "padded", "container"], intro, card_container
end

write_standard_page "site/index.html", "Kitsune Vi Portfolio Site", intro, blog_links, tape, under_construction