" plugin/llama.vim
" Vim plugin for triggering local AI completions via llama3.2 using your Go backend

if exists('g:loaded_vimollama')
  finish
endif
let g:loaded_vimollama = 1

" Automatically define the command and keymap on C++ files
augroup vimollama
  autocmd!
  autocmd FileType cpp nnoremap <buffer> <leader>a :call LlamaComplete()<CR>
augroup END

function! LlamaComplete()
  " Get the full path of the current file
  let l:file = expand('%:p')

  " Use a temporary file to store the output
  let l:tmpfile = '/tmp/llama_output.txt'

  " Build the command to call your Go agent
  let l:cmd = 'llama-agent complete ' . shellescape(l:file) . ' > ' . l:tmpfile

  " Execute the command silently
  silent execute '!' . l:cmd

  " Check if the file exists and has content
  if filereadable(l:tmpfile)
    " Open a new split and read in the AI output
    new
    execute 'read ' . l:tmpfile
    execute 'normal! ggdd' " remove first (empty) line
    execute 'setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile'
    execute 'file AI_Completion'
  else
    echoerr "LLaMA output failed or file not readable."
  endif
endfunction

