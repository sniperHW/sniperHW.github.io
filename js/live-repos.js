$(document).ready(function() {
    $(".project-list > .project").each(function() {
        var project = $(this);
        var repo = project.attr("repo");
        $.getJSON("https://api.github.com/repos/" + repo, function(data) {
            var html = '<h4><a href="' + data.html_url + '">' + data.name + '</a></h4>';
            if (data.description) {
                html += '<div class="description">' + data.description + '</div>';
            }
            html += '<div class="stats">';
            if (data.owner.login != "opower") {
                html += '<div class="author"><a href="' + data.owner.html_url + '">' + data.owner.login + '</a></div>';
            }
            if (data.language) {
                html += '<div class="language">' + data.language + '</div>';
            }
            html += '<div class="updatedon">Updated on ' + new Date(data.updated_at).toLocaleDateString() + '</div>' +
                    '<div class="forks"><span class="count">' + data.forks_count + '</span> forks</div>' +
                    '<div class="watchers"><span class="count">' + data.watchers_count + '</span> watchers</div>' +
                    '</div>';
            project.append(html);
        });
    });
});
