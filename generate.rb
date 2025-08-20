require 'pandoc-ruby'
require 'now-do'

def run_key hash, key
    if hash.has_key?(key)
        yield hash[key]
    end
end

Dir.mkdir("site/blogs") unless Dir.exist?("site/blogs")

def render_tag elem, elements, kwargs, **mixin
    kwargs[:style] = "" unless kwargs.has_key? :style
    run_key mixin, :style do |style|
        kwargs[:style] += (";" + style)
    end

    kwargs[:class] = [] unless kwargs.has_key? :class
    run_key mixin, :class do |html_class|
        kwargs[:class] += html_class
    end

    title = if kwargs.has_key? :title then
        %Q{ title="#{kwargs[:title]}"}
    else
        ""
    end

    %Q{<#{elem} style="#{kwargs[:style]}" class="#{kwargs[:class].join " "}"#{title}>#{elements.join ""}</#{elem}>}
end

def div *elements, **kwargs
    render_tag "div", elements, kwargs 
end

def span *elements, **kwargs
    render_tag "span", elements, kwargs
end

def vertical *elements, **kwargs
    render_tag "div", elements, kwargs, class: ["vertical", "container"]
end

def padded_vertical *elements, **kwargs
    render_tag "div", elements, kwargs, class: ["vertical", "padded", "container"]
end

def packed_vertical *elements, **kwargs
    render_tag "div", elements, kwargs, class: ["vertical", "packed", "container"]
end

def horizontal *elements, **kwargs
    render_tag "div", elements, kwargs, class: ["horizontal", "container"]
end

def padded_horizontal *elements, **kwargs
    render_tag "div", elements, kwargs, class: ["horizontal", "padded", "container"]
end

def packed_horizontal *elements, **kwargs
    render_tag "div", elements, kwargs, class: ["horizontal", "packed", "container"]
end

def main *elements, **kwargs
    render_tag "main", elements, kwargs
end

def article *elements, **kwargs
    render_tag "article", elements, kwargs
end

def symbol name, **kwargs
    render_tag "span", [name], kwargs, class: ["material-symbols-outlined"]
end

def page title, *elements
%Q{<!DOCTYPE html>
<html lang="en">
    <head>
        <link rel="icon" type="image/x-icon" href="/favicon.ico">
        <title>#{title}</title>
        <meta charset="utf-8">
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@300..700&family=Quicksand:wght@300..700&family=Russo+One&display=swap" rel="stylesheet">
        <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24..48,400,0..1,0" rel="stylesheet" />
        <link rel="stylesheet" href="/style.css">
    </head>
    <body>



#{elements.join}



    </body>
</html>}
end

def close_button
    %Q{<label><input type="checkbox" class="close">#{symbol "close"}</label>}
end

def show_ancestry path
    prev = ""
    ancestors = path.delete_suffix("/index").split('/')
    this = ancestors.pop || "home"
    elems = ancestors
        .flat_map do |name|
            prev += name + '/'
            name = "home" unless not name.empty?
            [
                %Q{<a href="#{prev}">#{name}</a>},
                "⊳"
            ]
        end
    horizontal *elems, %Q{<span>#{this}</span>}, class: ["wrapping", "secondary", "lightly-padded"]
end

def write_standard_page path, name, *elements
    File.open("site#{path}.html", 'w') do |file|
        content = packed_vertical *elements
        main_content = main content, style: "overflow-y: scroll;", class: ["forward-theme"]
        scoll_pressure_wrapper = div main_content, style: "width: 60%; height: 100%;", class: ["pressure-no-propogate"]
        side = div class: ["filling", "ramp"]
        tripple = packed_horizontal side, scoll_pressure_wrapper, side, class: ["primary", "filling"]
        root = packed_vertical (show_ancestry path), tripple, class: ["filling"]
        generated = page name, root
        file.puts generated
    end
end

def tape
    div class: ["tape"]
end

def under_construction
    crane = %Q{<img src="/crane.svg" style="height: 6rem; width: 6rem;">}
    message = %Q{<p style="font-size: 3rem;">UNDER CONSTRUCTION</p>}
    div crane, message, style: "justify-content: center;", class: ["horizontal", "centering", "warning", "filling", "very-padded", "container"]
end

# def no_content
#     ruins = %Q{<img src="/ruins.svg" style="height: 6rem; width: 6rem;">}
#     message = %Q{<p style="font-size: 3rem;">Nothing Here</p>}
#     div ["default", "horizontal", "centering", "faded", "filling", "padded", "container"], ruins, message, style: "justify-content: center;"
# end

def write_placeholder_page path, name
    File.open("site#{path}.html", 'w') do |file|
        root = packed_vertical (show_ancestry path), tape, under_construction, tape, style: "height: 100vh;", class: ["primary", "centering", "filling"]
        generated = page name, root
        file.puts generated
    end
end

def wip
    symbol "construction", class: ["warning"], title: "Work in progress"
end

def theory
    symbol "architecture", title: "Theory"
end

def interpolate text
    escaped = text
        .gsub("{", "\\{")
        .gsub("}", "\\}")
        .gsub("\\", "\\\\")
    code = "yield %Q{#{escaped}}"
        .gsub("--[", "#" + "{")
        .gsub("]--", "}")
        .gsub("[--", " (yield %Q{")
        .gsub("--]", "}) ")
    begin
        eval(code)
    rescue
        STDERR.puts "---- | ---- evaluated code ----"
        code.lines.each.with_index 1 do |line, index|
            STDERR.puts "#{"%04d" % index} | #{line}"
        end
        STDERR.puts "---- | ------------------------"
        raise
    end
end

def render_markdown path
    File.open(path, 'r') do |file|
        result = interpolate file.read do |text|
            text
        end
        PandocRuby.convert(result, from: :markdown, to: :html)
    end
end

def summary_icon
    symbol "group_work", class: ["summary-icon", "attention"]
end

def section *elements, **kwargs
    render_tag "blockquote", [(div *elements, class: ["vertical", "container"])], kwargs
end

def details title, technical, layman=nil
%Q{<div>

<details><summary><div class="horizontal centering container" style="gap: 1rem;">

#{summary_icon}

#{title}

</div></summary></details>

#{section technical, class: ["ramp", "attention-border", "detail"]}

#{if layman.nil? then "" else section layman end}

</div>}
end

def h2_content content
%Q{<div class="vertical container h2-content">
#{content}
</div>}
end

class PageData
    attr_reader :name
    attr_reader :excerpt

    def initialize name, excerpt, *tags
        @name = name
        @tags = tags
        @excerpt = excerpt
    end

    def is id
        @tags.include? id
    end

    def tags
        html = []
        if is :theory then html.push theory end
        html.push wip unless is :complete
        html
    end
end

intro = padded_vertical (render_markdown "content/intro.md")

blogs = {
    "the-chiral-product" => PageData.new(
        "The Chiral Product",
        "<p>An algebraic approach to mutation in linearly typed systems.</p>",
        :theory
    )
}

blog_links = now do
    blog_intro = render_markdown "content/blogs-intro.md"
    cards = blogs.map do |blog_name, page_data|
        prose = padded_vertical (render_markdown "content/blogs/#{blog_name}.md"), class: ["blog"]
        content = if page_data.is :complete then
            packed_vertical prose
        else
            packed_vertical prose, tape, under_construction
        end
        article_content = article content, class: ["blog", "forward-theme"]
        write_standard_page "/blogs/#{blog_name}", page_data.name, article_content

        title = %Q{<h3><a href="/blogs/#{blog_name}.html">#{page_data.name}</a>#{" " + (page_data.tags.join "")}</h3>}
        section title, page_data.excerpt, class: ["ramp"]
    end
    padded_vertical blog_intro, *cards
end

write_placeholder_page "/blogs/index", "Blogs"

write_standard_page "/index", "Kitsune Vi Portfolio Site", intro, blog_links, tape, under_construction