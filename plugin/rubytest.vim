" Vim plugin for running ruby tests
" Last Change: Jan 14, 2016
" Maintainer: Jan <jan.h.xie@gmail.com>
" License: MIT License

if exists("rubytest_loaded")
  finish
endif
let rubytest_loaded = 1

if !exists("g:rubytest_in_quickfix")
  let g:rubytest_in_quickfix = 0
endif
if !exists("g:rubytest_spec_drb")
  let g:rubytest_spec_drb = 0
endif
if !exists("g:rubytest_cmd_test")
  let g:rubytest_cmd_test = "ruby '%p'"
endif
if !exists("g:rubytest_cmd_testcase")
  let g:rubytest_cmd_testcase = "ruby '%p' -n '%c'"
endif
if !exists("g:rubytest_cmd_spec")
  let g:rubytest_cmd_spec = "rspec %p"
endif
if !exists("g:rubytest_cmd_example")
  let g:rubytest_cmd_example = "rspec %p:%c"
endif
if !exists("g:rubytest_cmd_feature")
  let g:rubytest_cmd_feature = "cucumber '%p'"
endif
if !exists("g:rubytest_cmd_story")
  let g:rubytest_cmd_story = "cucumber '%p' -n '%c'"
endif

function s:FindCase(patterns)
  let ln = a:firstline
  while ln > 0
    let line = getline(ln)
    for pattern in keys(a:patterns)
      if line =~ pattern
        if s:pattern == 'spec'
          return a:patterns[pattern](ln)
        else
          return a:patterns[pattern](line)
        endif
      endif
    endfor
    let ln -= 1
  endwhile
  return 'false'
endfunction

function s:EscapeBackSlash(str)
  return substitute(a:str, '\', '\\\\', 'g')
endfunction

function s:ExecTest(cmd)
  let g:rubytest_last_cmd = a:cmd

  let cmd = substitute(a:cmd, '#', '\\#', 'g')
  if g:rubytest_in_quickfix > 0
    echo "Running... " . cmd
    let s:oldefm = &efm
    let &efm = s:efm . s:efm_backtrace . ',' . s:efm_ruby . ',' . s:oldefm . ',%-G%.%#'

    cex system(cmd)
    redraw!
    botright copen

    let &efm = s:oldefm
  else
    exe "!echo '" . cmd . "' && " . cmd
  endif
endfunction

function s:RunTest()
  if s:test_scope == 1
    let cmd = g:rubytest_cmd_testcase
  elseif s:test_scope == 2
    let cmd = g:rubytest_cmd_test
  end

  let case = s:FindCase(s:test_case_patterns['test'])
  let suite = s:FindCase(s:test_case_patterns['test_suite'])
  let spec_case = s:FindCase(s:test_case_patterns['spec'])
  if s:test_scope == 2 || case != 'false'
    let case = substitute(case, "'\\|\"", '.', 'g')
    let cmd = substitute(cmd, '%c', case, 'g')
    let cmd = substitute(cmd, '%s', suite, 'g')
    let cmd = substitute(cmd, '%p', s:EscapeBackSlash(@%), 'g')

    if @% =~ '^test'
      let cmd = substitute(cmd, '^ruby ', 'ruby -Itest ', '')
    endif

    call s:ExecTest(cmd)
  elseif spec_case != 'false'
    let name = matchstr( spec_case, '\v%("([^"]*)"|''([^'']*)'')' )
    let name = substitute(name, '\s\+', '\.', 'g')
    let name = substitute(name, '^["|'']*\(.\{-}\)["|'']$', '\1', '')
    let spec_case = substitute(spec_case, '.*', name, '')
    let cmd = substitute(cmd, '%c', spec_case, 'g')
    let cmd = substitute(cmd, '%p', s:EscapeBackSlash(@%), 'g')

    if @% =~ '^test'
      let cmd = substitute(cmd, '^ruby ', 'ruby -Itest ', '')
    endif

    call s:ExecTest(cmd)
  else
    echo 'No test case found.'
  endif
endfunction

function s:RunSpec()
  if s:test_scope == 1
    let cmd = g:rubytest_cmd_example
  elseif s:test_scope == 2
    let cmd = g:rubytest_cmd_spec
  endif

  if g:rubytest_spec_drb > 0
    let cmd = cmd . " --drb"
  endif

  let case = s:FindCase(s:test_case_patterns['spec'])
  if s:test_scope == 2 || case != 'false'
    let cmd = substitute(cmd, '%c', case, 'g')
    let cmd = substitute(cmd, '%p', s:EscapeBackSlash(@%), 'g')
    call s:ExecTest(cmd)
  else
    echo 'No spec found.'
  endif
endfunction

function s:RunFeature()
  let s:old_in_quickfix = g:rubytest_in_quickfix
  let g:rubytest_in_quickfix = 0

  if s:test_scope == 1
    let cmd = g:rubytest_cmd_story
  elseif s:test_scope == 2
    let cmd = g:rubytest_cmd_feature
  endif

  let case = s:FindCase(s:test_case_patterns['feature'])
  if s:test_scope == 2 || case != 'false'
    let cmd = substitute(cmd, '%c', case, 'g')
    let cmd = substitute(cmd, '%p', s:EscapeBackSlash(@%), 'g')
    call s:ExecTest(cmd)
  else
    echo 'No story found.'
  endif

  let g:rubytest_in_quickfix = s:old_in_quickfix
endfunction

let s:test_patterns = {}
let s:test_patterns['test'] = function('s:RunTest')
let s:test_patterns['spec'] = function('s:RunSpec')
let s:test_patterns['\.feature$'] = function('s:RunFeature')

function s:GetTestCaseName1(str)
  return split(a:str)[1]
endfunction

function s:GetTestCaseName2(str)
  return "test_" . join(split(split(a:str, '"')[1]), '_')
endfunction

function s:GetTestCaseName3(str)
  return split(a:str, '"')[1]
endfunction

function s:GetTestCaseName4(str)
  return "test_" . join(split(split(a:str, "'")[1]), '_')
endfunction

function s:GetTestCaseName5(str)
  return split(a:str, "'")[1]
endfunction

function s:GetTestSuiteName(str)
  return split(a:str)[1]
endfunction

function s:GetSpecLine(str)
  return a:str
endfunction

function s:GetStoryLine(str)
  return join(split(split(a:str, 'Scenario\( Outline\)\?:')[1]))
endfunction

let s:test_case_patterns = {}
let s:test_case_patterns['test'] = {'^\s*def test':function('s:GetTestCaseName1'), '^\s*test \s*"':function('s:GetTestCaseName2'), "^\\s*test \\s*'":function('s:GetTestCaseName4'), '^\s*should \s*"':function('s:GetTestCaseName3'), "^\\s*should \\s*'":function('s:GetTestCaseName5')}
let s:test_case_patterns['test_suite'] = {'^\s*class Test\|\(\w\+Test\>\)':function('s:GetTestSuiteName')}
let s:test_case_patterns['spec'] = {'^\s*\(it\|example\|scenario\|describe\|context\|feature\) \s*':function('s:GetSpecLine')}
let s:test_case_patterns['feature'] = {'^\s*Scenario\( Outline\)\?:':function('s:GetStoryLine')}

let s:save_cpo = &cpo
set cpo&vim

if !hasmapto('<Plug>RubyTestRun')
  map <unique> <Leader>t <Plug>RubyTestRun
endif
if !hasmapto('<Plug>RubyFileRun')
  map <unique> <Leader>T <Plug>RubyFileRun
endif
if !hasmapto('<Plug>RubyLastRun')
  map <unique> <Leader>l <Plug>RubyLastRun
endif

function s:IsRubyTest()
  for pattern in keys(s:test_patterns)
    if @% =~ pattern
      let s:pattern = pattern
      return 1
    endif
  endfor
endfunction

function s:Run(scope)
  if !s:IsRubyTest()
    echo "This file doesn't contain ruby test."
  else
    " test scope define what to test
    " 1: test case under cursor
    " 2: all tests in file
    let s:test_scope = a:scope
    call s:test_patterns[s:pattern]()
  endif
endfunction

function s:RunLast()
  if !exists("g:rubytest_last_cmd")
    echo "No previous test has been run"
  else
    let r = s:ExecTest(g:rubytest_last_cmd)
  end
endfunction

noremap <unique> <script> <Plug>RubyTestRun <SID>RunTest
noremap <unique> <script> <Plug>RubyFileRun <SID>RunFile
noremap <unique> <script> <Plug>RubyLastRun <SID>RunLast
noremap <SID>RunTest :call <SID>Run(1)<CR>
noremap <SID>RunFile :call <SID>Run(2)<CR>
noremap <SID>RunLast :call <SID>RunLast()<CR>

let s:efm='%A\ \ %\\d%\\+)%.%#,'
      \.'%C\ \ \ \ \ #\ %f:%l:%.%#,'
      \.'%C\ \ \ \ \ %m,'
      \.'%Z,'

" below errorformats are copied from rails.vim
" Current directory
let s:efm=s:efm
      \.'%A%\\d%\\+)%.%#,'
      \.'%D(in\ %f),'
" Failure and Error headers, start a multiline message
let s:efm=s:efm
      \.'%A\ %\\+%\\d%\\+)\ Failure:,'
      \.'%A\ %\\+%\\d%\\+)\ Error:,'
      \.'%+A'."'".'%.%#'."'".'\ FAILED,'
" Exclusions
let s:efm=s:efm
      \.'%C%.%#(eval)%.%#,'
      \.'%C-e:%.%#,'
      \.'%C%.%#/lib/gems/%\\d.%\\d/gems/%.%#,'
      \.'%C%.%#/lib/ruby/%\\d.%\\d/%.%#,'
      \.'%C%.%#/vendor/rails/%.%#,'
" Specific to template errors
let s:efm=s:efm
      \.'%C\ %\\+On\ line\ #%l\ of\ %f,'
      \.'%CActionView::TemplateError:\ compile\ error,'
" stack backtrace is in brackets. if multiple lines, it starts on a new line.
let s:efm=s:efm
      \.'%Ctest_%.%#(%.%#):%#,'
      \.'%C%.%#\ [%f:%l]:,'
      \.'%C\ \ \ \ [%f:%l:%.%#,'
      \.'%C\ \ \ \ %f:%l:%.%#,'
      \.'%C\ \ \ \ \ %f:%l:%.%#]:,'
      \.'%C\ \ \ \ \ %f:%l:%.%#,'
" Catch all
let s:efm=s:efm
      \.'%Z%f:%l:\ %#%m,'
      \.'%Z%f:%l:,'
      \.'%C%m,'
" Syntax errors in the test itself
let s:efm=s:efm
      \.'%.%#.rb:%\\d%\\+:in\ `load'."'".':\ %f:%l:\ syntax\ error\\\, %m,'
      \.'%.%#.rb:%\\d%\\+:in\ `load'."'".':\ %f:%l:\ %m,'
" And required files
let s:efm=s:efm
      \.'%.%#:in\ `require'."'".':in\ `require'."'".':\ %f:%l:\ syntax\ error\\\, %m,'
      \.'%.%#:in\ `require'."'".':in\ `require'."'".':\ %f:%l:\ %m,'
" Exclusions
let s:efm=s:efm
      \.'%-G%.%#/lib/gems/%\\d.%\\d/gems/%.%#,'
      \.'%-G%.%#/lib/ruby/%\\d.%\\d/%.%#,'
      \.'%-G%.%#/vendor/rails/%.%#,'
      \.'%-G%.%#%\\d%\\d:%\\d%\\d:%\\d%\\d%.%#,'
" Final catch all for one line errors
let s:efm=s:efm
      \.'%-G%\\s%#from\ %.%#,'
      \.'%f:%l:\ %#%m,'

let s:efm_backtrace='%D(in\ %f),'
    \.'%\\s%#from\ %f:%l:%m,'
    \.'%\\s%#from\ %f:%l:,'
    \.'%\\s#{RAILS_ROOT}/%f:%l:\ %#%m,'
    \.'%\\s%#[%f:%l:\ %#%m,'
    \.'%\\s%#%f:%l:\ %#%m,'
    \.'%\\s%#%f:%l:,'
    \.'%m\ [%f:%l]:'

let s:efm_ruby='\%-E-e:%.%#,\%+E%f:%l:\ parse\ error,%W%f:%l:\ warning:\ %m,%E%f:%l:in\ %*[^:]:\ %m,%E%f:%l:\ %m,%-C%\tfrom\ %f:%l:in\ %.%#,%-Z%\tfrom\ %f:%l,%-Z%p^'

let &cpo = s:save_cpo
