" autoload/asyncomplete/sources/llama.vim
" Enhanced asyncomplete source for llama-agent

let s:supported_filetypes = ['cpp', 'c', 'go', 'python', 'javascript', 'typescript', 'java', 'rust', 'ruby']

function! asyncomplete#sources#llama#get_source_options(opt) abort
  return {
    \ 'name': 'llama',
    \ 'allowlist': s:supported_filetypes,
    \ 'blocklist': [],
    \ 'completor': function('asyncomplete#sources#llama#completor'),
    \ 'config': {
    \   'agent_path': get(g:, 'llama_agent_path', 'llama-agent'),
    \   'min_chars': get(g:, 'llama_min_chars', 3),
    \   'timeout': get(g:, 'llama_timeout', 10),
    \   'max_results': get(g:, 'llama_max_results', 5),
    \   'trigger_chars': ['.', '->', '::', '(', ' ']
    \ }
  \ }
endfunction

function! asyncomplete#sources#llama#completor(opt, ctx) abort
  let l:config = a:opt.config
  let l:typed = a:ctx['typed']
  
  " Check minimum character requirement
  if len(l:typed) < l:config.min_chars
    return
  endif
  
  " Check if we should trigger completion
  if !s:ShouldTrigger(l:typed, l:config.trigger_chars)
    return
  endif
  
  " Check if agent is available
  if !executable(l:config.agent_path)
    return
  endif
  
  " Save current file if modified
  if &modified
    silent write
  endif
  
  let l:file = expand('%:p')
  let l:line = a:ctx['lnum']
  let l:col = a:ctx['col']
  
  " Build command
  let l:cmd = [l:config.agent_path, 'complete', l:file, string(l:line), string(l:col)]
  
  " Start async job
  if has('job')
    let l:job_opts = {
      \ 'callback': function('s:OnComplete', [a:opt, a:ctx]),
      \ 'timeout': l:config.timeout * 1000,
      \ 'out_mode': 'raw'
    \ }
    
    call job_start(l:cmd, l:job_opts)
  else
    " Fallback for older Vim
    let l:result = system(join(l:cmd, ' '))
    if !v:shell_error && !empty(l:result)
      call s:ProcessResult(a:opt, a:ctx, l:result)
    endif
  endif
endfunction

function! s:ShouldTrigger(typed, trigger_chars) abort
  " Always trigger if we have enough characters
  if len(a:typed) >= 5
    return 1
  endif
  
  " Check for trigger characters
  let l:last_char = a:typed[-1:]
  if index(a:trigger_chars, l:last_char) >= 0
    return 1
  endif
  
  " Check for common C++ patterns
  if a:typed =~ '\w\+\.$' || a:typed =~ '\w\+->\w*$' || a:typed =~ '\w\+::\w*$'
    return 1
  endif
  
  " Check for function call patterns
  if a:typed =~ '\w\+($'
    return 1
  endif
  
  return 0
endfunction

function! s:OnComplete(opt, ctx, channel, msg) abort
  call s:ProcessResult(a:opt, a:ctx, a:msg)
endfunction

function! s:ProcessResult(opt, ctx, result) abort
  if empty(a:result)
    return
  endif
  
  let l:completions = s:ParseCompletion(a:result, a:opt.config.max_results)
  
  if !empty(l:completions)
    call asyncomplete#complete(a:opt['name'], a:ctx, l:completions, 1)
  endif
endfunction

function! s:ParseCompletion(result, max_results) abort
  let l:lines = split(a:result, '\n')
  let l:completions = []
  let l:count = 0
  
  for l:line in l:lines
    if l:count >= a:max_results
      break
    endif
    
    let l:line = substitute(l:line, '^\s\+', '', '')
    let l:line = substitute(l:line, '\s\+$', '', '')
    
    if empty(l:line)
      continue
    endif
    
    " Try to extract meaningful completions
    let l:completion = s:ExtractCompletion(l:line)
    if !empty(l:completion)
      call add(l:completions, l:completion)
      let l:count += 1
    endif
  endfor
  
  return l:completions
endfunction

function! s:ExtractCompletion(line) abort
  let l:line = a:line
  
  " Remove common prefixes that LLMs might add
  let l:prefixes = [
    \ 'Here''s the completion:',
    \ 'The completion is:',
    \ 'Complete with:',
    \ 'Suggestion:'
  \ ]
  
  for l:prefix in l:prefixes
    if l:line =~? '^\s*' . l:prefix
      let l:line = substitute(l:line, '^\s*' . l:prefix . '\s*', '', 'i')
      break
    endif
  endfor
  
  " Extract code from markdown code blocks
  if l:line =~ '^```'
    return {}
  endif
  
  " Simple heuristics to extract the actual completion
  let l:word = ''
  let l:info = l:line
  
  " Try to find the main word/phrase
  if l:line =~ '^\w\+('
    " Function call
    let l:word = matchstr(l:line, '^\w\+')
    let l:info = 'Function: ' . l:line
  elseif l:line =~ '^\w\+\s*='
    " Variable assignment  
    let l:word = matchstr(l:line, '^\w\+')
    let l:info = 'Variable: ' . l:line
  elseif l:line =~ '^\w\+\s\+'
    " Word followed by space (likely a keyword or type)
    let l:word = matchstr(l:line, '^\w\+')
  else
    " Default: use the first word
    let l:word = matchstr(l:line, '^\S\+')
  endif
  
  if empty(l:word)
    return {}
  endif
  
  " Determine completion kind
  let l:kind = s:GetCompletionKind(l:line)
  
  return {
    \ 'word': l:word,
    \ 'abbr': l:word,
    \ 'menu': '[LLaMA]',
    \ 'info': l:info,
    \ 'kind': l:kind,
    \ 'icase': 1
  \ }
endfunction

function! s:GetCompletionKind(line) abort
  if a:line =~ '^\w\+('
    return 'f'  " function
  elseif a:line =~ '^\w\+\s*='
    return 'v'  " variable
  elseif a:line =~ '^\(class\|struct\|enum\)\s'
    return 't'  " type
  elseif a:line =~ '^\(if\|for\|while\|switch\)\s'
    return 'k'  " keyword
  elseif a:line =~ '^\w\+::'
    return 'm'  " member
  elseif a:line =~ '^\#\(include\|define\|ifdef\)'
    return 'd'  " define
  else
    return 't'  " text/default
  endif
endfunction

" Register the source
function! asyncomplete#sources#llama#register() abort
  call asyncomplete#register_source(asyncomplete#sources#llama#get_source_options({
    \ 'name': 'llama'
  \ }))
endfunction
