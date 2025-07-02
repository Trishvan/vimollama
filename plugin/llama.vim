" plugin/llama.vim
" Enhanced Vim plugin for AI-assisted coding with llama-agent

if exists('g:loaded_vimollama')
  finish
endif
let g:loaded_vimollama = 1

" Configuration variables
if !exists('g:llama_agent_path')
  let g:llama_agent_path = 'llama-agent'
endif

if !exists('g:llama_agent_model')
  let g:llama_agent_model = 'llama3.2'
endif

if !exists('g:llama_auto_complete')
  let g:llama_auto_complete = 0
endif

if !exists('g:llama_show_progress')
  let g:llama_show_progress = 1
endif

" Supported file types
let s:supported_filetypes = ['cpp', 'c', 'go', 'python', 'javascript', 'typescript', 'java', 'rust', 'ruby']

" Auto-commands for supported file types
augroup vimollama
  autocmd!
  for ft in s:supported_filetypes
    execute 'autocmd FileType ' . ft . ' call s:SetupLlamaKeymaps()'
  endfor
augroup END

" Setup key mappings for supported file types
function! s:SetupLlamaKeymaps()
  " Code completion
  nnoremap <buffer> <leader>lc :call LlamaComplete()<CR>
  inoremap <buffer> <C-l> <C-o>:call LlamaCompleteInline()<CR>
  
  " Chat and explanation
  nnoremap <buffer> <leader>le :call LlamaExplain()<CR>
  nnoremap <buffer> <leader>lq :call LlamaChat()<CR>
  
  " Code improvement
  nnoremap <buffer> <leader>lf :call LlamaFix()<CR>
  nnoremap <buffer> <leader>lt :call LlamaTest()<CR>
  
  " Utility commands
  nnoremap <buffer> <leader>ls :call LlamaStatus()<CR>
  nnoremap <buffer> <leader>lr :call LlamaRestart()<CR>
endfunction

" Main completion function
function! LlamaComplete()
  if !s:IsSupported()
    echo "LLaMA: File type not supported"
    return
  endif

  let l:file = expand('%:p')
  let l:line = line('.')
  let l:col = col('.')
  
  if g:llama_show_progress
    echo "LLaMA: Generating completion..."
  endif
  
  call s:RunLlamaCommand('complete', l:file, [l:line, l:col], function('s:HandleCompletion'))
endfunction

" Inline completion (for insert mode)
function! LlamaCompleteInline()
  if !s:IsSupported()
    return
  endif

  let l:file = expand('%:p')
  let l:line = line('.')
  let l:col = col('.')
  
  call s:RunLlamaCommand('complete', l:file, [l:line, l:col], function('s:HandleInlineCompletion'))
endfunction

" Explain code function
function! LlamaExplain()
  if !s:IsSupported()
    echo "LLaMA: File type not supported"
    return
  endif

  let l:file = expand('%:p')
  let l:line = line('.')
  
  if g:llama_show_progress
    echo "LLaMA: Explaining code..."
  endif
  
  call s:RunLlamaCommand('explain', l:file, [l:line], function('s:HandleExplanation'))
endfunction

" Chat with AI about code
function! LlamaChat()
  if !s:IsSupported()
    echo "LLaMA: File type not supported"
    return
  endif

  let l:prompt = input('Ask about your code: ')
  if empty(l:prompt)
    return
  endif
  
  let l:file = expand('%:p')
  
  if g:llama_show_progress
    echo "LLaMA: Processing question..."
  endif
  
  call s:RunLlamaCommand('chat', l:file, [l:prompt], function('s:HandleChat'))
endfunction

" Suggest fixes for code
function! LlamaFix()
  if !s:IsSupported()
    echo "LLaMA: File type not supported"
    return
  endif

  let l:file = expand('%:p')
  
  if g:llama_show_progress
    echo "LLaMA: Analyzing code for issues..."
  endif
  
  call s:RunLlamaCommand('fix', l:file, [], function('s:HandleFix'))
endfunction

" Generate unit tests
function! LlamaTest()
  if !s:IsSupported()
    echo "LLaMA: File type not supported"
    return
  endif

  let l:file = expand('%:p')
  
  if g:llama_show_progress
    echo "LLaMA: Generating unit tests..."
  endif
  
  call s:RunLlamaCommand('test', l:file, [], function('s:HandleTest'))
endfunction

" Show LLaMA status and configuration
function! LlamaStatus()
  echo "LLaMA Agent Status:"
  echo "Agent path: " . g:llama_agent_path
  echo "Model: " . g:llama_agent_model
  echo "Auto-complete: " . (g:llama_auto_complete ? "enabled" : "disabled")
  echo "File type: " . &filetype . " (" . (s:IsSupported() ? "supported" : "not supported") . ")"
  
  " Test agent availability
  let l:result = system(g:llama_agent_path . ' config 2>/dev/null')
  if v:shell_error
    echo "Status: Agent not available (check installation)"
  else
    echo "Status: Agent available"
  endif
endfunction

" Restart/reload configuration
function! LlamaRestart()
  echo "LLaMA: Reloading configuration..."
  " Force reload of plugin
  unlet! g:loaded_vimollama
  runtime! plugin/llama.vim
  echo "LLaMA: Configuration reloaded"
endfunction

" Check if current file type is supported
function! s:IsSupported()
  return index(s:supported_filetypes, &filetype) >= 0
endfunction

" Run llama-agent command asynchronously
function! s:RunLlamaCommand(cmd, file, args, callback)
  if !executable(g:llama_agent_path)
    echohl ErrorMsg
    echo "LLaMA: Agent not found at " . g:llama_agent_path
    echohl None
    return
  endif

  " Save file if modified
  if &modified
    write
  endif

  " Build command
  let l:command = [g:llama_agent_path, a:cmd, a:file] + a:args
  let l:job_options = {
    \ 'callback': a:callback,
    \ 'close_cb': function('s:JobClose'),
    \ 'err_cb': function('s:JobError'),
    \ 'out_mode': 'raw',
    \ 'err_mode': 'raw'
  \ }

  " Start job
  if has('job')
    let l:job = job_start(l:command, l:job_options)
    if job_status(l:job) == 'fail'
      echohl ErrorMsg
      echo "LLaMA: Failed to start agent"
      echohl None
    endif
  else
    " Fallback for older Vim versions
    let l:result = system(join(l:command, ' '))
    if v:shell_error
      echohl ErrorMsg
      echo "LLaMA: Command failed"
      echohl None
    else
      call a:callback(0, l:result)
    endif
  endif
endfunction

" Handle completion response
function! s:HandleCompletion(channel, msg)
  if empty(a:msg)
    echo "LLaMA: No completion available"
    return
  endif

  let l:code = s:ExtractCodeFromResponse(a:msg)
  if empty(l:code)
    echo "LLaMA: No code found in completion"
    return
  endif

  let l:code = substitute(l:code, '^\s*', '', '')
  let l:code = substitute(l:code, '\r', '', 'g')
  let l:code = substitute(l:code, '\n', '\r\n', 'g')
  let l:code = substitute(l:code, '^  \+', '\t', 'g')
  let l:code = substitute(l:code, '^ +', '\t', 'g')

  " Store original buffer and position
  let b:llama_orig_buf = bufnr('#')
  let b:llama_orig_pos = getpos('.')

  new
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal filetype=text
  file LLaMA_Completion
  call setline(1, split(l:code, '\n'))
  normal! ggdd

  let l:original_ft = getbufvar(b:llama_orig_buf, '&filetype')
  if !empty(l:original_ft)
    execute 'setlocal filetype=' . l:original_ft
  endif

  " Map <Tab> to insert completion into original buffer
  nnoremap <buffer> <Tab> :call s#LlamaInsertCompletion()<CR>
  echo "LLaMA: Completion ready. Press <Tab> to insert."

" Insert completion from completion buffer into original buffer at saved position
function! s#LlamaInsertCompletion() abort
  if !exists('b:llama_orig_buf') || !exists('b:llama_orig_pos')
    echo "LLaMA: No original buffer info."
    return
  endif
  let l:lines = getline(1, '$')
  let l:buf = b:llama_orig_buf
  let l:pos = b:llama_orig_pos
  execute 'b' . l:buf
  call setpos('.', l:pos)
  call append(line('.')-1, l:lines)
  " Move cursor to end of inserted text
  call setpos('.', [l:buf, l:pos[1]+len(l:lines), 1, 0])
  " Close the completion buffer
  execute 'bdelete! LLaMA_Completion'
endfunction
endfunction

" Handle inline completion (insert at cursor)
function! s:HandleInlineCompletion(channel, msg)
  if empty(a:msg)
    echo "LLaMA: No completion available"
    return
  endif

  let l:code = s:ExtractCodeFromResponse(a:msg)
  if empty(l:code)
    echo "LLaMA: No code found in completion"
    return
  endif

  let l:code = substitute(l:code, '^\s*', '', '')
  let l:code = substitute(l:code, '\r', '', 'g')
  let l:code = substitute(l:code, '^  \+', '\t', 'g')
  let l:code = substitute(l:code, '^ +', '\t', 'g')
  let l:lines = split(l:code, '\n')

  if len(l:lines) == 1
    execute "normal! a" . l:lines[0]
  else
    let l:current_indent = indent('.')
    let l:indent_str = repeat('\t', l:current_indent)
    for i in range(len(l:lines))
      if i == 0
        execute "normal! a" . l:lines[i]
      else
        execute "normal! o" . l:indent_str . l:lines[i]
      endif
    endfor
  endif

  echo "LLaMA: Completion inserted"

" Extract only the code block from the response, fallback to first code-looking lines
function! s:ExtractCodeFromResponse(msg) abort
  let l:lines = split(a:msg, '\n')
  let l:code = []
  let l:in_code = 0
  for l:line in l:lines
    if l:line =~ '^```'
      if l:in_code
        break
      else
        let l:in_code = 1
        continue
      endif
    endif
    if l:in_code
      call add(l:code, l:line)
    endif
  endfor
  if !empty(l:code)
    return join(l:code, "\n")
  endif
  " Fallback: return first non-empty, non-explanation lines
  let l:filtered = []
  for l:line in l:lines
    if l:line =~? '^\s*\(here''s the completion\|the completion is\|complete with\|suggestion\|explanation\|output\|result\|answer\|\)$'
      continue
    endif
    if l:line =~ '^\s*$'
      continue
    endif
    call add(l:filtered, l:line)
  endfor
  if !empty(l:filtered)
    return join(l:filtered, "\n")
  endif
  return ''
endfunction
endfunction

" Handle explanation response
function! s:HandleExplanation(channel, msg)
  if empty(a:msg)
    echo "LLaMA: No explanation available"
    return
  endif

  call s:ShowResponse("LLaMA_Explanation", a:msg, "markdown")
  echo "LLaMA: Explanation ready"
endfunction

" Handle chat response
function! s:HandleChat(channel, msg)
  if empty(a:msg)
    echo "LLaMA: No response available"
    return
  endif

  call s:ShowResponse("LLaMA_Chat", a:msg, "markdown")
  echo "LLaMA: Response ready"
endfunction

" Handle fix suggestions
function! s:HandleFix(channel, msg)
  if empty(a:msg)
    echo "LLaMA: No issues found"
    return
  endif

  call s:ShowResponse("LLaMA_Fixes", a:msg, "markdown")
  echo "LLaMA: Fix suggestions ready"
endfunction

" Handle test generation
function! s:HandleTest(channel, msg)
  if empty(a:msg)
    echo "LLaMA: No tests generated"
    return
  endif

  let l:original_ft = &filetype
  call s:ShowResponse("LLaMA_Tests", a:msg, l:original_ft)
  echo "LLaMA: Tests generated"
endfunction

" Show response in a new buffer
function! s:ShowResponse(name, content, filetype)
  " Check if buffer already exists
  let l:bufnum = bufnr(a:name)
  if l:bufnum != -1
    " Buffer exists, switch to it
    let l:winnum = bufwinnr(l:bufnum)
    if l:winnum != -1
      execute l:winnum . 'wincmd w'
    else
      execute 'sbuffer ' . l:bufnum
    endif
    " Clear existing content
    %delete _
  else
    " Create new buffer
    new
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    execute 'file ' . a:name
  endif
  
  " Set content and filetype
  put =a:content
  normal! ggdd
  execute 'setlocal filetype=' . a:filetype
  
  " Add some helpful mappings
  nnoremap <buffer> q :close<CR>
  nnoremap <buffer> <CR> :close<CR>
endfunction

" Job completion callback
function! s:JobClose(channel)
  " Job finished
endfunction

" Job error callback
function! s:JobError(channel, msg)
  if !empty(a:msg)
    echohl ErrorMsg
    echo "LLaMA Error: " . a:msg
    echohl None
  endif
endfunction

" Auto-completion on text change (if enabled)
if g:llama_auto_complete
  augroup llama_auto
    autocmd!
    autocmd TextChangedI * call s:AutoComplete()
  augroup END
endif

function! s:AutoComplete()
  if !s:IsSupported() || !g:llama_auto_complete
    return
  endif
  
  " Only trigger after certain characters or word boundaries
  let l:line = getline('.')
  let l:col = col('.') - 1
  let l:char = l:col > 0 ? l:line[l:col-1] : ''
  
  " Trigger characters: space, dot, arrow, colon
  if l:char =~ '[. >:]' || (l:col > 2 && l:line[l:col-2:l:col-1] == '->')
    " Debounce: only complete if user stopped typing for a moment
    call timer_stop(get(b:, 'llama_timer', -1))
    let b:llama_timer = timer_start(1000, function('s:DelayedAutoComplete'))
  endif
endfunction

function! s:DelayedAutoComplete(timer)
  if mode() == 'i'  " Still in insert mode
    call LlamaCompleteInline()
  endif
endfunction

" Commands for manual invocation
command! LlamaComplete call LlamaComplete()
command! LlamaExplain call LlamaExplain()
command! LlamaChat call LlamaChat()
command! LlamaFix call LlamaFix()
command! LlamaTest call LlamaTest()
command! LlamaStatus call LlamaStatus()
command! LlamaRestart call LlamaRestart()

" Toggle auto-completion
command! LlamaToggleAuto call s:ToggleAutoComplete()

function! s:ToggleAutoComplete()
  let g:llama_auto_complete = !g:llama_auto_complete
  echo "LLaMA auto-complete: " . (g:llama_auto_complete ? "enabled" : "disabled")
  
  if g:llama_auto_complete
    augroup llama_auto
      autocmd!
      autocmd TextChangedI * call s:AutoComplete()
    augroup END
  else
    autocmd! llama_auto
  endif
endfunction

" Help command
command! LlamaHelp call s:ShowHelp()

function! s:ShowHelp()
  new
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal filetype=help
  file LLaMA_Help
  
  let l:help_text = [
    \ "LLaMA Agent for Vim - Help",
    \ "==========================",
    \ "",
    \ "Key Mappings (in supported file types):",
    \ "  <leader>lc  - Complete code at cursor",
    \ "  <C-l>       - Inline completion (insert mode)",
    \ "  <leader>le  - Explain current code",
    \ "  <leader>lq  - Ask question about code",
    \ "  <leader>lf  - Suggest fixes for code",
    \ "  <leader>lt  - Generate unit tests",
    \ "  <leader>ls  - Show LLaMA status",
    \ "  <leader>lr  - Restart/reload LLaMA",
    \ "",
    \ "Commands:",
    \ "  :LlamaComplete    - Complete code",
    \ "  :LlamaExplain     - Explain code",
    \ "  :LlamaChat        - Chat about code",
    \ "  :LlamaFix         - Suggest fixes",
    \ "  :LlamaTest        - Generate tests",
    \ "  :LlamaStatus      - Show status",
    \ "  :LlamaRestart     - Restart plugin",
    \ "  :LlamaToggleAuto  - Toggle auto-completion",
    \ "  :LlamaHelp        - Show this help",
    \ "",
    \ "Supported File Types:",
    \ "  " . join(s:supported_filetypes, ", "),
    \ "",
    \ "Configuration Variables:",
    \ "  g:llama_agent_path     - Path to llama-agent binary",
    \ "  g:llama_agent_model    - Model to use (default: llama3.2)",
    \ "  g:llama_auto_complete  - Enable auto-completion (default: 0)",
    \ "  g:llama_show_progress  - Show progress messages (default: 1)",
    \ "",
    \ "Example Configuration (~/.vimrc):",
    \ "  let g:llama_agent_path = '/usr/local/bin/llama-agent'",
    \ "  let g:llama_agent_model = 'codellama'",
    \ "  let g:llama_auto_complete = 1",
    \ "",
    \ "Press 'q' or <Enter> to close this help."
  \ ]
  
  call setline(1, l:help_text)
  normal! gg
  
  nnoremap <buffer> q :close<CR>
  nnoremap <buffer> <CR> :close<CR>
endfunction
