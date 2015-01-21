"   Vim Swoop   1.0.5

"Copyright (C) 2015 copyright Clément CREPY
"
"This program is free software; you can redistribute it and/or modify
"it under the terms of the GNU General Public License as published by
"the Free Software Foundation; either version 2 of the License, or
"(at your option) any later version.
"
"This program is distributed in the hope that it will be useful,
"but WITHOUT ANY WARRANTY; without even the implied warranty of
"MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
"GNU General Public License for more details.
"
"You should have received a copy of the GNU General Public License
"along with this program; if not, see <http://www.gnu.org/licenses/>.



"   ===========================
"   CONFIGURATION AND VARIABLES
"   ===========================
let g:swoopUseDefaultKeyMap = 1
"let g:swoopHighlight =
let g:swoopWindowsVerticalLayout = 0
let g:swoopLazyLoadFileType = 1

let g:swoopAutoInsertMode = 1
let g:swoopPatternSpaceInsertsWildcard = 1

let s:multiSwoop = -1
let s:freezeContext = 0

let s:swoopSeparator = "\t"


"   =======================
"   BEGIN / EXIT WORKAROUND
"   =======================
function! s:initSwoop()
    let s:beforeSwoopBuf = bufnr('%')
    let s:beforeSwoopPos =  getpos('.')
    let initFileType = &ft

    let s:displayWin = bufwinnr('%')

    if g:swoopWindowsVerticalLayout == 1
        silent bot vsplit swoopBuf
    else
        silent bot split swoopBuf
    endif

    execute "setlocal filetype=".initFileType
    let s:swoopBuf = bufnr('%')

    call s:initHighlight()

    imap <buffer> <silent> <CR> <Esc>
    nmap <buffer> <silent> <CR> :call SwoopSelect()<CR>
endfunction

function! s:initHighlight()
    if exists("g:swoopHighlight")
        for val in g:swoopHighlight
            execute val
        endfor
    else
        redir => backgroundColor
        silent set background?
        redir END
        let backgroundColor = split(backgroundColor, '=')[1]
        if backgroundColor == 'dark'
            highlight SwoopBufferLineHi term=bold ctermfg=lightgreen gui=bold guifg=lightgreen
            highlight SwoopPatternHi term=bold ctermfg=lightblue gui=bold guifg=lightblue
        else
            highlight SwoopBufferLineHi term=bold ctermfg=lightgreen guibg=lightgreen
            highlight SwoopPatternHi term=bold ctermfg=lightblue guibg=lightblue
        endif
    endif
endfunction

function! s:exitSwoop()
    silent bw! swoopBuf
    call clearmatches()
    let s:multiSwoop = -1
endfunction



"   ==========================
"   USER SHOSRTCUT INTERACTION
"   ==========================
function! Swoop()
    if s:multiSwoop == 0
        call setline(1, "")
    endif
    if s:multiSwoop == -1
        let s:multiSwoop = 0
        call s:initSwoop()
    endif
    if s:multiSwoop == 1
        let s:multiSwoop = 0
        let pattern = getline(2)
        call setline(1, pattern)
    endif

    execute ':1'
    if g:swoopAutoInsertMode == 1
        startinsert
    endif
endfunction

function! SwoopMulti()
    if s:multiSwoop == 1
        call setline(2, "")
        execute ":2"
    endif
    if s:multiSwoop == -1
        let s:multiSwoop = 1
        call s:initSwoop()
        call append(1, [""])
        execute ":2"
    endif
    if s:multiSwoop == 0
        let s:multiSwoop = 1
        let pattern = getline(1)
        call setline(1, "")
        call append(1, [pattern])
        execute ':1'
    endif

    if g:swoopAutoInsertMode == 1
        startinsert
    endif
endfunction

function! SwoopQuit()
    call s:exitSwoop()

    execute s:displayWin." wincmd w"
    execute "buffer ". s:beforeSwoopBuf
    call clearmatches()
    call setpos('.', s:beforeSwoopPos)
endfunction

function! SwoopSave()
    let currentLine = line('.')
    execute "g/.*/call s:setSwoopLine(s:getCurrentLineSwoopInfo())"
    execute ":".currentLine
endfunction

function! SwoopSaveAndQuit()
    call SwoopSave()
    silent call SwoopQuit()
endfunction

function! SwoopSelect()
    if s:multiSwoop == 0
        if line('.') > 2
            call s:selectSwoopInfo()
        else
            normal j
        endif
    else
        if line('.') > 3
            call s:selectSwoopInfo()
        else
            normal j
        endif
    endif
    normal zz
endfunction

function! SwoopSelection()
    let selectedText = s:getVisualSelectionSingleLine()
    call SwoopPattern(selectedText)
endf

function! SwoopMultiSelection()
    let selectedText = s:getVisualSelectionSingleLine()
    call SwoopMultiPattern(selectedText)
endf



"   ========================
"   USER COMMAND INTERACTION
"   ========================
function! SwoopPattern(pattern)
    call Swoop()
    call setline(1, a:pattern)
    stopinsert
endfunction

function! SwoopMultiPattern(pattern, ...)
    call SwoopMulti()
    if a:0 == 1
        call setline(1, a:000)
    else
        call setline(1, "")
    endif
    call setline(2, a:pattern)
    stopinsert
endfunction

function! s:RunSwoop(searchPattern, isMulti)
    if empty(a:isMulti)
        call SwoopPattern(a:searchPattern)
    else
        call SwoopMultiPattern(a:searchPattern)
    endif
    stopinsert
endfunction
command! -bang -nargs=* Swoop :call <SID>RunSwoop(<q-args>, '<bang>')



"   =======================
"   USER HIDDEN INTERACTION
"   =======================
function! s:cursorMoved()
    if s:needFreezeContext() == 1
        return
    endif
    let beforeCursorMoved = getpos('.')
    let currentLine = beforeCursorMoved[1]

    if s:multiSwoop == 0
        if currentLine == 1
            call s:displaySwoopResult(beforeCursorMoved)
        else
            call s:displayCurrentContext()
        endif
    else
        if currentLine == 1
            call s:displaySwoopBuffer(beforeCursorMoved)
            let s:bufferLineList = [1]
        else
            if currentLine == 2
                call s:displaySwoopResult(beforeCursorMoved)
            else
                call s:displayCurrentContext()
            endif
        endif
    endif
    call s:displayHighlight()
endfunction

function! s:selectSwoopInfo()
    let swoopInfo = s:getCurrentLineSwoopInfo()
    call s:exitSwoop()

    if len(swoopInfo) >= 3
        execute "buffer ". swoopInfo[0]
        execute ":".swoopInfo[1]
    endif
endfunction



"   =======
"   DISPLAY
"   =======
function! s:displaySwoopResult(beforeCursorMoved)
    let pattern = s:getSwoopPattern()
    let bufferList = s:getSwoopBufList()

    let results = s:getSwoopResultsLine(bufferList, pattern)
    exec "buffer ". s:swoopBuf
    if s:multiSwoop == 0
        silent! exec "2,$d_"
        call append(1, results)
    else
        silent! exec "3,$d_"
        call append(2, results)
    endif
    call setpos('.', a:beforeCursorMoved)
endfunction

function! s:displaySwoopBuffer(beforeCursorMoved)
    exec "buffer ". s:swoopBuf
    silent! exec "3,$d_"
    let swoopBufList = s:getSwoopBufList()
    let swoopBufStrList = map(copy(swoopBufList), 's:getBufferStr(v:val)')

    call append(2, swoopBufStrList)
    call setpos('.', a:beforeCursorMoved)
endfunction

function! s:displayCurrentContext()
    let swoopInfo = s:getCurrentLineSwoopInfo()
    if len(swoopInfo) >= 3
        let bufNumber = swoopInfo[0]
        let lineNumber = swoopInfo[1]
        let pattern = s:getSwoopPattern()

        exec s:displayWin." wincmd w"
        exec "buffer ". bufNumber
        let currentFileType = &ft

        if g:swoopLazyLoadFileType == 1
            if empty(currentFileType)
                execute "filetype detect"
                let currentFileType = $ft
            endif
        endif
        exec ":".lineNumber
        normal zz

        execute "wincmd p"
        execute "setlocal filetype=".currentFileType
    endif
endfunction

function! s:displayHighlight()
    let pattern = s:getSwoopPattern()

    call clearmatches()

    if s:multiSwoop == 1
        if line('.') == 1
            let bufPattern = s:getBufPattern()
            call matchadd("SwoopBufferLineHi", bufPattern)
        endif
    endif

    call matchadd("SwoopPatternHi", pattern)

    exec s:displayWin." wincmd w"
    call clearmatches()
    call matchadd("SwoopPatternHi", pattern)
    execute "wincmd p"

    call s:matchBufferLine(s:bufferLineList)
endfunction



"   ================================
"   ACCESSOR - SINGLE POINT OF ENTRY
"   ================================
function! s:extractCurrentLineSwoopInfo()
    return join([bufnr('%'), line('.'), getline('.')], s:swoopSeparator)
endfunction

function! s:getCurrentLineSwoopInfo()
    return split(getline('.'), s:swoopSeparator)
endfunction

function! s:getBufferStr(bufNr)
    return join([a:bufNr, bufname(a:bufNr)], s:swoopSeparator)
endfunction

function! s:getSwoopResultsLine(bufferList, pattern)
    let results = []
    let s:bufferLineList = s:multiSwoop == 1 ? [1] : []

    for currentBuffer in a:bufferList
        execute "buffer ". currentBuffer
        let currentBufferResults = []
        execute 'g/' . a:pattern . "/call add(currentBufferResults, s:extractCurrentLineSwoopInfo())"
        if !empty(currentBufferResults)
            call add(results, bufname('%'))
            call add(s:bufferLineList, len(results) + 1 + s:multiSwoop)
            call extend(results, currentBufferResults)
            call add(results, "")
        endif
    endfor
    return results
endfunction

function! s:getSwoopPattern()
    if s:multiSwoop == 0
        let patternLine = getline(1)
    else
        let patternLine = getline(2)
    endif

    if empty(patternLine)
        return ''
    else
        let patternLine = patternLine.'\c'
    endif

    return g:swoopPatternSpaceInsertsWildcard == 1 ? join(split(patternLine), '.*')  : patternLine
endfunction

function! s:getBufPattern()
    return g:swoopPatternSpaceInsertsWildcard == 1 ? join(split(getline(1)), '.*') : getline(1)
endf

function! s:getSwoopBufList()
    if s:multiSwoop == 0
        let bufList = [s:beforeSwoopBuf]
    else
        let bufList = s:getAllBuffer()
        let bufPattern = s:getBufPattern()
        call filter(bufList, 's:getBufferStr(v:val) =~? bufPattern')
    endif
    return bufList
endfunction

function! s:getAllBuffer()
    let allBuf = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    let swoopIndex = index(allBuf, s:swoopBuf)
    call remove(allBuf, swoopIndex)
    return allBuf
endfunction

function! s:setSwoopLine(swoopInfo)
    if len(a:swoopInfo) >= 3
        let bufTarget = a:swoopInfo[0]
        let lineTarget = a:swoopInfo[1]
        let newLine = join(a:swoopInfo[2:], s:swoopSeparator)

        execute "buffer ". bufTarget
        let oldLine = getline(lineTarget)

        if oldLine !=# newLine
            call setline(lineTarget, newLine)
        endif

    endif
    execute "buffer ". s:swoopBuf
endfunction



"   ======================
"   COMPATIBILITY FUNCTION
"   ======================
function! s:matchBufferLine(bufferLineList)
    if exists("*matchaddpos") == 0
        for line in a:bufferLineList
            call matchadd("SwoopBufferLineHi", '\%'.line.'l')
        endfor
    else
        call matchaddpos("SwoopBufferLineHi", s:bufferLineList)
    endif
endfunction

function! s:needFreezeContext()
    if mode() == 'v'
        return 1
    else
       if s:freezeContext == 1
           return 1
       else
           return 0
       endif
    endif
endfunction

function! SwoopFreezeContext()
    let s:freezeContext = 1
endfunction

function! SwoopUnFreezeContext()
    let s:freezeContext = 0
endfunction

function! s:getVisualSelectionSingleLine()
    return getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]]
endfunction



"   =======
"   COMMAND
"   =======
if g:swoopUseDefaultKeyMap == 1
    nmap <Leader>l :call Swoop()<CR>
    nmap <Leader>ml :call SwoopMulti()<CR>
    vmap <Leader>l :call SwoopSelection()<CR>
    vmap <Leader>ml :call SwoopMultiSelection()<CR>
endif



"   ============
"   AUTO COMMAND
"   ============
augroup swoopAutoCmd
    autocmd!    CursorMovedI   swoopBuf   :call   s:cursorMoved()
    autocmd!    CursorMoved    swoopBuf    :call   s:cursorMoved()

    autocmd!    BufWriteCmd    swoopBuf    :call   SwoopSave()
    autocmd!    BufLeave   swoopBuf   :call    SwoopSaveAndQuit()
augroup END
