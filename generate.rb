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

%Q{<#{elem} style="#{kwargs[:style]}" class="#{kwargs[:class].join " "}">

#{elements.join "\n\n"}

</#{elem}>}
end

def div *elements, **kwargs
    render_tag "div", elements, kwargs 
end

def padded_vertical *elements, **kwargs
    render_tag "div", elements, kwargs, class: ["vertical", "padded", "container"]
end

def packed_vertical *elements, **kwargs
    render_tag "div", elements, kwargs, class: ["vertical", "packed", "container"]
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
            <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"></script>
        </head>
        <body>
            #{elements.join}
        </body>
    </html>}
end

def close_button
    %Q{<label><input type="checkbox" class="close"><span class="material-symbols-outlined">close</span></label>}
end

# def scope_warning
#     no_scope_support = %Q{<p>
#         Your browser does not support <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/@scope">css scopes</a>!
#         As a result some things on this page may not render properly!
#     </p>}
#     box = div no_scope_support, close_button, class: ["horizontal", "spaced", "mildly-padded", "bordered", "filling", "container"]
#     div box, class: ["scope-warning", "padded", "warning", "popup"]
# end

def show_ancestry path
    prev = ""
    elems = path
        .split('/')[0...-1]
        .map do |name|
            prev += name + '/'
            name = "home" unless not name.empty?
            %Q{<a href="#{prev}index.html">#{name}</a>}
        end
    padded_horizontal *elems, class: ["wrapping", "secondary"]
end

def write_standard_page path, name, *elements
    File.open("site#{path}.html", 'w') do |file|
        content = packed_vertical *elements
        main_content = main content, style: "overflow-y: scroll;", class: ["forward-theme"]
        scoll_pressure_wrapper = div main_content, style: "width: 60%; height: 100%;", class: ["pressure-no-propgate"]
        side = div class: ["filling", "ramp"]
        tripple = packed_horizontal side, scoll_pressure_wrapper, side, class: ["primary", "filling"]
        root = packed_vertical (show_ancestry path), tripple
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
        root = div tape, under_construction, tape, style: "height: 100vh; max-height: 100vh;", class: ["primary", "packed", "vertical", "centering", "filling", "container"]
        generated = page name, root
        file.puts generated
    end
end

def wip
    %Q{<span class="warning" title="Work in progress"><span class="material-symbols-outlined">construction</span></span>}
end

def theory
    %Q{<span class="material-symbols-outlined" title="Theory">architecture</span>}
end

def interpolate text
    escaped = text
        .gsub("{", "{".dump)
        .gsub("}", "}".dump)
    code = "%Q{#{escaped}}"
        .gsub("::[", "#" + "{")
        .gsub("]::", "}")
        .gsub("[::", " (yield %Q{")
        .gsub("::]", "}) ")
    begin
        yield eval(code)
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
    %Q{<span class="attention material-symbols-outlined summary-icon">group_work</span>}
end

def section *elements, **kwargs
    render_tag "blockquote", [(div *elements, class: ["vertical", "container"])], kwargs
end

def details title, technical, layman=""
%Q{<div>

<details><summary><div class="horizontal centering container" style="gap: 1rem;">

#{summary_icon}

#{title}

</div></summary></details>

#{section technical, class: ["ramp", "attention-border", "detail"]}

#{section layman}

</div>}
end

def h2_content content
%Q{<div class="vertical container h2-content">
#{content}
</div>
}
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

blog_links = now do |;intro|
    intro = render_markdown "content/blogs-intro.md"
    cards = blogs.map do |blog_name, page_data|
        prose = padded_vertical (render_markdown "content/blogs/#{blog_name}.md"), class: ["blog"]
        content = if page_data.is :complete then
            packed_vertical prose
        else
            packed_vertical prose, tape, under_construction
        end
        article_content = article content, class: ["blog", "forward-theme"]
        write_standard_page "/blogs/#{blog_name}", page_data.name, article_content

        title = div %Q{<h3><a href="/blogs/#{blog_name}.html">#{page_data.name}</a>#{page_data.tags.join ""}</h3>}, class: ["centering", "horizontal", "container"]
        div title, page_data.excerpt, style: "flex-grow: 1;", class: ["ramp", "detail"]
    end
    card_container = padded_horizontal *cards, class: ["full", "wrapping"]
    padded_vertical intro, card_container
end

write_placeholder_page "/blogs/index", "Blogs"

write_standard_page "/index", "Kitsune Vi Portfolio Site", intro, blog_links, tape, under_construction