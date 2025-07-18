class HTMLElement
    def set_id n
        @id = n
    end

    def id
        if @id.nil?
            ""
        else
            "id=#{@id}"
        end
    end

    def classes
        if @classes.nil?
            ""
        else
            "class=\"#{@classes.join " "}\""
        end
    end

    def props
        [id, classes]
            .select do |prop|
                not prop.empty?
            end
            .join " "
    end
end

class String
    def render
        self
    end
end

module Container
    def render_children
        @contents
            .map do |child|
                child.render
            end
            .join "\n" 
    end
end

class Page < HTMLElement
    include Container

    def initialize title, *contents
        @title = title
        @contents = contents
    end

    def render
        %Q{<!DOCTYPE html>
        <html lang="en">
            <head>
                <title>#{@title}</title>
                <link rel="preconnect" href="https://fonts.googleapis.com">
                <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:ital,wght@0,100..800;1,100..800&family=Quicksand:wght@300..700&family=Russo+One&display=swap" rel="stylesheet">
                <link rel="stylesheet" href="style.css">
            </head>
            <body #{id}>
                #{render_children}
            </body>
        </html>}
    end
end

class Div < HTMLElement
    include Container

    def initialize classes, *contents
        @classes = classes
        @contents = contents
    end

    def render
        %Q{<div #{props}>
            #{render_children}
        </div>}
    end
end

class LoremIpsum < HTMLElement
    def render
        %Q{<p #{id}>
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
            Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
            Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        </p>}
    end
end

def filling
    Div.new ["filling"]
end

def page name, *elements
    content = Div.new ["dark", "vertical", "scrollable", "container"], *elements
    content.set_id "content"
    root = Div.new ["light", "packed", "right", "container"], filling, content, filling
    root.set_id "root"
    Page.new name, root
end

def intro
    %Q{<div class="vertical container">
        <h1>Kitsune Vi</h1>
        <p>
            Hello, my name is Violet, I am a pure mathematician turned functional programmer.
            I hope to use my understanding to improve the way we program
            by crafting multi-paradigm patterns that:
        </p>
        <ul>
            <li>Create a rich and flexible type lattice.</li>
            <li>Interact organically with <a href="https://en.wikipedia.org/wiki/WYSIWYG">WYSIWYG</a> tooling.</li>
            <li>Balance iteration speed and performance within idiomatic code.</li>
            <li>Provide strong safety guarantees that make types more meaningful.</li>
        </ul>
        <b>So much more is possible then what we have right now.</b>
    </div>}
end

p = page "Kitsune Vi Portfolio Site", intro

File.open('generated.html', 'w') do |file|
    file.puts p.render
end