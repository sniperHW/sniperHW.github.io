# Opower's Engineering Blog

## Install and setup

Presumably if you are here it is because you want to contribute to our blog.
Thank you.  Here are some helpful instructions for making that process easy.

1. Clone the repo
1. Install bundler if you don't already have it: `gem install bundler`
1. Install the required gems, using bundler: `bundle install`
1. Start up Jekyll in "watch" mode: `bundle exec jekyll serve --watch`
1. Load up the site locally: `open http://localhost:4000`

## Making and submitting edits or new blog posts

The Jekyll content lives in the `working` branch, while the published content
lives in the `master` branch.  The default branch when you clone is the
`working` branch, and you should never have a need to switch to `master` unless
you are a blog owner.  We have organized our branches in this non-standard way
so that we can be in full control of the content that is published.  If we just
committed posts to `master`, then the standard GitHub Pages workflow would
use Jekyll to convert them to publishable content.  In that case, we are
restricted by what GitHub has decided is safe for them to run.

The workflow for submitting a post goes like this:

1. Fork the repo on github.com: `open https://github.com/opower/opower.github.io/fork`
1. Add the fork to your local repo: `git remote add <remote-name> <fork-url>`
1. Make sure you are on the `working` branch: `git checkout working`
1. Update your local repo: `git pull origin`
1. Fetch your fork, too: `git pull <remote-name>`
1. Create a branch for your post: `git checkout -b <post-slug>`
1. Write your new post: `vim _posts/<date>-<post-slug>.markdown`
1. Run Jekyll to check the content looks good: `bundle exec jekyll serve --watch`
1. Commit your draft: `git commit _posts/<date>-<post-slug>.markdown`
1. Push your draft to your fork: `git push <remote-name> <post-slug>`
1. Open a pull request against `origin/working` on github.com

One of the blog owners will work with you to finalize the post and will publish
it.

## Standards

Posts should follow these standards:

* Written in Markdown using [kramdown][]'s syntax extensions
* End with a `.markdown` extension
* Include at least the following in the [YAML Front Matter][yaml]:
  * `layout: post`
  * `title: <The post title>`
  * `author: <first.last>`
* Wrap at 80 characters
* Use the [`{% highlight %}`][highlight] tag around code blocks, preferably
  specifying the language
* Link to images or assets from the root URL: `![Cats](/img/cats.png)`

To help with some of the formating, for the vim users, we suggest using the
[vim-markdown][vm] plugin from Tim Pope, in conjunction with Tim's
[vim-pathogen][path] plugin.  Additionally, be sure to set `set textwidth=80`
for Markdown files to have vim wrap automatically for you.

[kramdown]: http://kramdown.rubyforge.org/index.html
[highlight]: http://jekyllrb.com/docs/posts/#highlighting_code_snippets
[vm]: https://github.com/tpope/vim-markdown
[path]: https://github.com/tpope/vim-pathogen
[yaml]: http://jekyllrb.com/docs/frontmatter/
