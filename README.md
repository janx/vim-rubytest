Rubytest.vim
============

Rubytest.vim is a vim (http://www.vim.org) plugin, which helps you to run ruby test (including vanilla test, rspec, shoulda etc.) in vim.

Installation
------------

Copy all files to your ~/.vim directory.

Usage
-----

After installation, press `<Leader>t` will run the test under your cursor if you are editing a ruby test file.

Example:

```
$ cd <your rails/merb root>
$ vim test/unit/user_test.rb
```
(move cursor into a test case, press `<Leader>t`)

(`<Leader>` is mapping to '\' by default in vim)

Be default, the plugin will print output in terminal. You can change this behavior by putting this line in your vimrc file:

    let g:rubytest_in_quickfix = 1

With this set, test errors will be displayed in quickfix window, and you can jump to the error location quickly by select the error message and hit return (or `Ctrl-w return` to open it in new window).

You can customize the command which will be used to run the test case by setting these options in your vimrc file:

    let g:rubytest_cmd_test = "ruby %p"
    let g:rubytest_cmd_testcase = "ruby %p -n '/%c/'"
    let g:rubytest_cmd_spec = "spec -f specdoc %p"
    let g:rubytest_cmd_example = "spec -f specdoc %p -e '%c'"
    let g:rubytest_cmd_feature = "cucumber %p"
    let g:rubytest_cmd_story = "cucumber %p -n '%c'"

### Using [Spork](https://github.com/sporkrb/spork)

    let g:rubytest_cmd_test = "bundle exec testdrb %p"
    let g:rubytest_cmd_testcase = "bundle exec testdrb %p -- -n '/%c/'"

### Using [Spring](https://github.com/rails/spring)

    let g:rubytest_cmd_test = "bundle exec spring testunit %p"
    let g:rubytest_cmd_testcase = "bundle exec spring testunit %p -n '/%c/'"

### Using [Zeus](https://github.com/burke/zeus)

Note that Zeus is not typically run from within the project's bundle context, so `bundle exec` is omitted from example

    let g:rubytest_cmd_test = "zeus test %p"
    let g:rubytest_cmd_testcase = "zeus test %p -n '/%c/'"

Placeholders:

* `%p`: path of test file
* `%c`: test case name
* `%s`: only for minitest, replaced by closest suite name (class whose name begin with 'Test'). This can be used to match test case more exactly:

    let g:rubytest_cmd_testcase = "ruby %p -n '%s#%c'"

Default Key Bindings
--------------------

* `<Leader>t`: run test case under cursor
* `<Leader>T`: run all tests in file
* `<Leader>l`: run the last test, from any buffer

You can change default key bindings:

    map <Leader>\ <Plug>RubyTestRun     " change from <Leader>t to <Leader>\
    map <Leader>] <Plug>RubyFileRun     " change from <Leader>T to <Leader>]
    map <Leader>/ <Plug>RubyTestRunLast " change from <Leader>l to <Leader>/

Tip
---

* Rubytest.vim works perfectly with vim-localvimrc, which enables you to set different test run command for different projects. Check details at: https://github.com/embear/vim-localvimrc

Contributors
------------

* Bogdan Gusiev
* Yung Hwa Kwon (nowk)
* J. Weir
* Ben Simpson (bsimpson)
* Alexander Belyaev (alexbel)
* Ivan Tkalin (ivalkeen)
