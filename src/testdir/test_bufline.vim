" Tests for setbufline(), getbufline(), appendbufline(), deletebufline()

source shared.vim
source screendump.vim
source check.vim

func Test_setbufline_getbufline()
  " similar to Test_set_get_bufline()
  new
  let b = bufnr('%')
  hide
  call assert_equal(0, setbufline(b, 1, ['foo', 'bar']))
  call assert_equal(['foo'], getbufline(b, 1))
  call assert_equal(['bar'], getbufline(b, '$'))
  call assert_equal(['foo', 'bar'], getbufline(b, 1, 2))
  exe "bd!" b
  call assert_equal([], getbufline(b, 1, 2))

  split Xtest
  call setline(1, ['a', 'b', 'c'])
  let b = bufnr('%')
  wincmd w

  call assert_equal(1, setbufline(b, 5, 'x'))
  call assert_equal(1, setbufline(b, 5, ['x']))
  call assert_equal(1, setbufline(b, 5, []))
  call assert_equal(1, setbufline(b, 5, test_null_list()))

  call assert_equal(1, 'x'->setbufline(bufnr('$') + 1, 1))
  call assert_equal(1, ['x']->setbufline(bufnr('$') + 1, 1))
  call assert_equal(1, []->setbufline(bufnr('$') + 1, 1))
  call assert_equal(1, test_null_list()->setbufline(bufnr('$') + 1, 1))

  call assert_equal(['a', 'b', 'c'], getbufline(b, 1, '$'))

  call assert_equal(0, setbufline(b, 4, ['d', 'e']))
  call assert_equal(['c'], b->getbufline(3))
  call assert_equal(['d'], getbufline(b, 4))
  call assert_equal(['e'], getbufline(b, 5))
  call assert_equal([], getbufline(b, 6))
  call assert_equal([], getbufline(b, 2, 1))

  if has('job')
    call setbufline(b, 2, [function('eval'), #{key: 123}, test_null_job()])
    call assert_equal(["function('eval')",
                    \ "{'key': 123}",
                    \ "no process"],
                    \ getbufline(b, 2, 4))
  endif
  exe "bwipe! " . b
endfunc

func Test_setbufline_getbufline_fold()
  split Xtest
  setlocal foldmethod=expr foldexpr=0
  let b = bufnr('%')
  new
  call assert_equal(0, setbufline(b, 1, ['foo', 'bar']))
  call assert_equal(['foo'], getbufline(b, 1))
  call assert_equal(['bar'], getbufline(b, 2))
  call assert_equal(['foo', 'bar'], getbufline(b, 1, 2))
  exe "bwipe!" b
  bwipe!
endfunc

func Test_setbufline_getbufline_fold_tab()
  split Xtest
  setlocal foldmethod=expr foldexpr=0
  let b = bufnr('%')
  tab new
  call assert_equal(0, setbufline(b, 1, ['foo', 'bar']))
  call assert_equal(['foo'], getbufline(b, 1))
  call assert_equal(['bar'], getbufline(b, 2))
  call assert_equal(['foo', 'bar'], getbufline(b, 1, 2))
  exe "bwipe!" b
  bwipe!
endfunc

func Test_setline_startup()
  let cmd = GetVimCommand('Xscript')
  if cmd == ''
    return
  endif
  call writefile(['call setline(1, "Hello")', 'silent w Xtest', 'q!'], 'Xscript')
  call system(cmd)
  call assert_equal(['Hello'], readfile('Xtest'))

  call delete('Xscript')
  call delete('Xtest')
endfunc

func Test_appendbufline()
  new
  let b = bufnr('%')
  hide
  call assert_equal(0, appendbufline(b, 0, ['foo', 'bar']))
  call assert_equal(['foo'], getbufline(b, 1))
  call assert_equal(['bar'], getbufline(b, 2))
  call assert_equal(['foo', 'bar'], getbufline(b, 1, 2))
  exe "bd!" b
  call assert_equal([], getbufline(b, 1, 2))

  split Xtest
  call setline(1, ['a', 'b', 'c'])
  let b = bufnr('%')
  wincmd w

  call assert_equal(1, appendbufline(b, -1, 'x'))
  call assert_equal(1, appendbufline(b, -1, ['x']))
  call assert_equal(1, appendbufline(b, -1, []))
  call assert_equal(1, appendbufline(b, -1, test_null_list()))

  call assert_equal(1, appendbufline(b, 4, 'x'))
  call assert_equal(1, appendbufline(b, 4, ['x']))
  call assert_equal(1, appendbufline(b, 4, []))
  call assert_equal(1, appendbufline(b, 4, test_null_list()))

  call assert_equal(1, appendbufline(1234, 1, 'x'))
  call assert_equal(1, appendbufline(1234, 1, ['x']))
  call assert_equal(1, appendbufline(1234, 1, []))
  call assert_equal(1, appendbufline(1234, 1, test_null_list()))

  call assert_equal(0, appendbufline(b, 1, []))
  call assert_equal(0, appendbufline(b, 1, test_null_list()))
  call assert_equal(1, appendbufline(b, 3, []))
  call assert_equal(1, appendbufline(b, 3, test_null_list()))

  call assert_equal(['a', 'b', 'c'], getbufline(b, 1, '$'))

  call assert_equal(0, appendbufline(b, 3, ['d', 'e']))
  call assert_equal(['c'], getbufline(b, 3))
  call assert_equal(['d'], getbufline(b, 4))
  call assert_equal(['e'], getbufline(b, 5))
  call assert_equal([], getbufline(b, 6))
  exe "bwipe! " . b
endfunc

func Test_appendbufline_no_E315()
  let after =<< trim [CODE]
    set stl=%f ls=2
    new
    let buf = bufnr("%")
    quit
    vsp
    exec "buffer" buf
    wincmd w
    call appendbufline(buf, 0, "abc")
    redraw
    while getbufline(buf, 1)[0] =~ "^\\s*$"
      sleep 10m
    endwhile
    au VimLeavePre * call writefile([v:errmsg], "Xerror")
    au VimLeavePre * call writefile(["done"], "Xdone")
    qall!
  [CODE]

  if !RunVim([], after, '--clean')
    return
  endif
  call assert_notmatch("^E315:", readfile("Xerror")[0])
  call assert_equal("done", readfile("Xdone")[0])
  call delete("Xerror")
  call delete("Xdone")
endfunc

func Test_deletebufline()
  new
  let b = bufnr('%')
  call setline(1, ['aaa', 'bbb', 'ccc'])
  hide
  call assert_equal(0, deletebufline(b, 2))
  call assert_equal(['aaa', 'ccc'], getbufline(b, 1, 2))
  call assert_equal(0, deletebufline(b, 2, 8))
  call assert_equal(['aaa'], getbufline(b, 1, 2))
  exe "bd!" b
  call assert_equal(1, b->deletebufline(1))

  call assert_equal(1, deletebufline(-1, 1))

  split Xtest
  call setline(1, ['a', 'b', 'c'])
  call cursor(line('$'), 1)
  let b = bufnr('%')
  wincmd w
  call assert_equal(1, deletebufline(b, 4))
  call assert_equal(0, deletebufline(b, 1))
  call assert_equal(['b', 'c'], getbufline(b, 1, 2))
  exe "bwipe! " . b

  edit XbufOne
  let one = bufnr()
  call setline(1, ['a', 'b', 'c'])
  setlocal nomodifiable
  split XbufTwo
  let two = bufnr()
  call assert_fails('call deletebufline(one, 1)', 'E21:')
  call assert_equal(two, bufnr())
  bwipe! XbufTwo
  bwipe! XbufOne
endfunc

func Test_appendbufline_redraw()
  CheckScreendump

  let lines =<< trim END
    new foo
    let winnr = 'foo'->bufwinnr()
    let buf = bufnr('foo')
    wincmd p
    call appendbufline(buf, '$', range(1,200))
    exe winnr .. 'wincmd w'
    norm! G
    wincmd p
    call deletebufline(buf, 1, '$')
    call appendbufline(buf, '$', 'Hello Vim world...')
  END
  call writefile(lines, 'XscriptMatchCommon')
  let buf = RunVimInTerminal('-S XscriptMatchCommon', #{rows: 10})
  call VerifyScreenDump(buf, 'Test_appendbufline_1', {})

  call StopVimInTerminal(buf)
  call delete('XscriptMatchCommon')
endfunc

func Test_setbufline_select_mode()
  new
  call setline(1, ['foo', 'bar'])
  call feedkeys("j^v2l\<C-G>", 'nx')

  let bufnr = bufadd('Xdummy')
  call bufload(bufnr)
  call setbufline(bufnr, 1, ['abc'])

  call feedkeys("x", 'nx')
  call assert_equal(['foo', 'x'], getline(1, 2))

  exe "bwipe! " .. bufnr
  bwipe!
endfunc

func Test_deletebufline_select_mode()
  new
  call setline(1, ['foo', 'bar'])
  call feedkeys("j^v2l\<C-G>", 'nx')

  let bufnr = bufadd('Xdummy')
  call bufload(bufnr)
  call setbufline(bufnr, 1, ['abc', 'def'])
  call deletebufline(bufnr, 1)

  call feedkeys("x", 'nx')
  call assert_equal(['foo', 'x'], getline(1, 2))

  exe "bwipe! " .. bufnr
  bwipe!
endfunc

" vim: shiftwidth=2 sts=2 expandtab