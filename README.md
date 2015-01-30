vim swoop
=========

Vim swoop is directly inspired from [helm-swoop](https://github.com/ShingoFukuyama/helm-swoop) we can find as emacs' plugin.

It allows you to find and replace occurences in many buffers being aware of the context.

An animation means more than a boring speech...


![](https://github.com/pelodelfuego/vim-swoop/blob/dev/doc/images/moveSwoop.gif)

You can edit the swoopBuffer and the changes you applied will be save for all corresponding files by saving the buffer

Especially useful to refactor a name in multiple files and keep control on it...


Usage
-----

When you start vim-swoop (multi or single buffer mode) you get 2 windows.

First one contain context, the other is the swoop buffer. As you move the cursor to a match, the display windows will show the context.

From the swoop buffer, you can:
* Interactivly edit your search
* Navigate in results (and context) by moving the cursor
* Edit and save Swoop Buffer ```:w```.
*The changes will be repercuted on all files by saving the Swoop Buffer*
* Select current result.
*Exit and Save Swoop and go to the location of current match when you press \<CR\>*
* Quit Swoop ```:q```.
*Exit Swoop will save modifications and bring you back to the initial buffer and position.*
* Toggle single and multi buffer mode

###single buffer mode
Start in insert mode, first line contains the search pattern.

As you type the pattern, results will interactivly be displayed bellow.

![](https://raw.githubusercontent.com/pelodelfuego/vim-swoop/dev/doc/images/singleModeScreenshot.png)


###multi buffer mode
Start in insert mode, first line contains the buffer pattern, no pattern means all buffers.

Buffer will be displayed interactivly bellow

![](https://raw.githubusercontent.com/pelodelfuego/vim-swoop/dev/doc/images/multiModeBufferPatternScreenshot.png)

Second line contains the search pattern just like in single buffer mode

![](https://raw.githubusercontent.com/pelodelfuego/vim-swoop/dev/doc/images/multiModeSwoopPatternScreenshot.png)


Interactions
--------

###KeyMap
Default mapping to use vim-swoop are:

* Swoop current buffer
```
nmap <Leader>l :call Swoop()<CR>
vmap <Leader>l :call SwoopSelection()<CR>
```

* Swoop multi buffers
```
nmap <Leader>ml :call SwoopMulti()<CR>
vmap <Leader>ml :call SwoopMultiSelection()<CR>
```

You can disabledefault mapping by:
```
let g:swoopUseDefaultKeyMap = 0
```

###Function
Those 2 action are also exposed by the following function:

* Current buffer function
```
:call SwoopPattern(pattern)
```

* Multi buffer function

For all buffer
```
:call SwoopMultiPattern(searchPattern)
```

For specific buffer
```
:call SwoopMultiPattern(searchPattern, bufPattern)
```

###Command
A third way to acces Swoop is by a direct command:

For single buffer mode
```
:Swoop <pattern>
```

For all buffer mode
```
:Swoop! <pattern>
```


Configuration
-------------

* set search case insensitive

    By default, smartcase is set, you can go to case insensitive search by:
```
let g:swoopIgnoreCase = 1
```

* Disable quick regex mode

    By default, typing ```<Space>``` in the search pattern is replaced by ```.*```. And to type an actual space, you will need to escape it  ```\<Space>```.
    You can get classic mode by:
```
let g:swoopPatternSpaceInsertsWildcard = 0
```

* Disable auto insert mode

    By default, you will start in insert mode, you can disable it by:
```
let g:swoopAutoInserMode = 0
```

* Change default layout

    By default, layout will be horizontal, you can set it vertical by:
```
let g:swoopWindowsVerticalLayout = 1
```

* Lazy Filetype Load

    By default, filetype are lazy loaded when itering over multifile, you can disable this by:
```
let g:swoopLazyLoadFileType = 0
```

* Edit default HightLight

    If default highlight is not relevant with your colorscheme, you can edit it by editing g:swoopHighlight variable, here is an example:
```
let g:swoopHighlight = ["hi! link SwoopBufferLineHi Warning", "hi! link SwoopPatternHi Error"]
```


Tips and Tricks
---------------
* Use CursorLine

    I strongly advise to highlight current line. It will help you to keep focus on the context of the current match.

* Toggle mode

    You can toggle single and multi buffer mode, your Pattern will stay the same.

    Calling again a mode while your already in will reset the search pattern.

* Search in swoop buffer

    Since the context display depends of the cursor movement, you can lauch a search inside the search buffer.

* Use VisualMode in the swoop Buffer

    When you use visual mode in the swoopBuffer, the context will freeze if you select more than 2 lines.
    But it is really usefull on refactoring session: you can keep only the lines you want to refactor and execute global replace.


* Use last search

    When you start swoop (either the mode) and don't enter any pattern, search result will be your last search.


Interaction with other plugin
-----------------------------
* [ vim-multiple-cursor ]( https://github.com/terryma/vim-multiple-cursors )

    You can combine multiple and vim-swoop, to make it compatible (no context move while multiple cursor), you want to add this to you .vimrc
    ```
    function! Multiple_cursors_before()
        if exists('*SwoopFreezeContext') != 0
            call SwoopFreezeContext()
        endif
    endfunction

    function! Multiple_cursors_after()
        if exists('*SwoopUnFreezeContext') != 0
            call SwoopUnFreezeContext()
        endif
    endfunction
    ```

* Other plugin

    The main issue you will have will be displaying the context, to have compatibility 2 functions are exposed:
    ```
    call SwoopFreezeContext()
    ```

    ```
    call SwoopUnFreezeContext()
    ```
    If you need anything else to enchanche compatibility with other plugin, please open an issue.


Installation and dependancies
-----------------------------

Vim-Swoop is a pure vimscript plugin, no other dependancies.


#### [Pathogen](https://github.com/tpope/vim-pathogen)
```
git clone https://github.com/pelodelfuego/vim-swoop ~/.vim/bundle/vim-swoop
```


Upcomming feature and improvement
-----------------


Credit
------
Special thanks to [ Shingo Fukuyama ]( https://github.com/ShingoFukuyama ) for his amazing idea which has juste been ported to vim.

