let theme_override = "";
function renderTheme(theme) {
    $(".primary").removeClass("light dark").addClass(`${theme}`)
}
function overrideTheme(theme) {
    theme_override = theme
    renderTheme(theme)
}
$(document).ready(() => {
    renderTheme(new URLSearchParams(window.location.search).get('theme') || (window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark"));
    window.matchMedia("(prefers-color-scheme: light)").addEventListener('change', (e) => { if (e.matches) {
        theme_override = "";
        renderTheme("light")
    }});
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener('change', (e) => { if (e.matches) {
        theme_override = "";
        renderTheme("dark")
    }});
    $("a[href^='/']").click(function(event) {
        event.preventDefault();
        let url = new URL(window.location.origin + $(this).attr('href'));
        if (theme_override) url.searchParams.set("theme", theme_override);
        window.location.assign(url);
    });
})