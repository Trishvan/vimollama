function! asyncomplete#sources#llama#completor(opt, ctx) abort
  let l:typed = a:ctx['typed']
  if len(l:typed) < 3
    return
  endif

  let l:tmpfile = tempname() . '.cpp'
  call writefile(getline(1, '$'), l:tmpfile)

  let l:cmd = 'llama-agent complete ' . shellescape(l:tmpfile)
  let l:result = systemlist(l:cmd)

  if v:shell_error || empty(l:result)
    return
  endif

  call asyncomplete#complete(a:opt['name'], a:ctx, [{
        \ 'word': l:result[0],
        \ 'menu': '[LLAMA]',
        \ 'info': join(l:result, "\n")
        \ }], 0)
endfunction

