" 全設定をデフォルト値に設定する
set all&
autocmd!

" tiny と small はここで終了する

if !1 | finish | endif

" Ruby設定（動的にmiseのRubyパスを設定）
let g:ruby_host_prog = substitute(system('mise which ruby'), '\n', '', '')

" Perl設定（動的にmiseのPerlパスを設定）
let g:perl_host_prog = substitute(system('mise which perl'), '\n', '', '')

set nocompatible
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8,euc-jp,cp932

" ========================================
" vim標準機能による補完設定
" ========================================

" オムニ補完を有効化
set omnifunc=syntaxcomplete#Complete

" 自動補完の詳細設定
set completeopt=menu,menuone,noinsert,noselect,preview
set complete=.,w,b,u,t,i,k

" 補完時の大文字小文字の区別しない
set infercase

" 補完ポップアップの色設定
highlight Pmenu ctermbg=darkgray ctermfg=white
highlight PmenuSel ctermbg=blue ctermfg=white
highlight PmenuSbar ctermbg=gray
highlight PmenuThumb ctermbg=white

" ========================================
" 言語別スニペット機能（プラグインなし）
" ========================================

" Perlスニペット関数
function! InsertPerlSub()
  let name = input('サブルーチン名: ')
  if name != ''
    call append(line('.'), [
      \ 'sub ' . name . ' {',
      \ '    my (' . input('引数: ') . ') = @_;',
      \ '    ',
      \ '    return;',
      \ '}'
    \ ])
    normal! 3j$
  endif
endfunction

function! InsertPerlIf()
  call append(line('.'), [
    \ 'if (' . input('条件: ') . ') {',
    \ '    ',
    \ '}'
  \ ])
  normal! 2j$
endfunction

function! InsertPerlFor()
  call append(line('.'), [
    \ 'for my $' . input('変数名: ') . ' (@' . input('配列名: ') . ') {',
    \ '    ',
    \ '}'
  \ ])
  normal! 2j$
endfunction

function! InsertPerlPackage()
  let name = input('パッケージ名: ')
  if name != ''
    call append(line('.'), [
      \ 'package ' . name . ';',
      \ '',
      \ 'use strict;',
      \ 'use warnings;',
      \ '',
      \ '',
      \ '',
      \ '1;'
    \ ])
    normal! 6j$
  endif
endfunction

" Perlスニペット用キーマッピング
autocmd FileType perl inoremap <buffer> <Leader>sub <Esc>:call InsertPerlSub()<CR>
autocmd FileType perl inoremap <buffer> <Leader>if <Esc>:call InsertPerlIf()<CR>
autocmd FileType perl inoremap <buffer> <Leader>for <Esc>:call InsertPerlFor()<CR>
autocmd FileType perl inoremap <buffer> <Leader>pkg <Esc>:call InsertPerlPackage()<CR>

" Rubyスニペット関数
function! InsertRubyDef()
  let name = input('メソッド名: ')
  if name != ''
    call append(line('.'), [
      \ 'def ' . name . '(' . input('引数: ') . ')',
      \ '  ',
      \ 'end'
    \ ])
    normal! 2j$
  endif
endfunction

function! InsertRubyClass()
  let name = input('クラス名: ')
  if name != ''
    call append(line('.'), [
      \ 'class ' . name,
      \ '  def initialize(' . input('引数: ') . ')',
      \ '    ',
      \ '  end',
      \ '',
      \ '  ',
      \ 'end'
    \ ])
    normal! 6j$
  endif
endfunction

function! InsertRubyIf()
  call append(line('.'), [
    \ 'if ' . input('条件: '),
    \ '  ',
    \ 'end'
  \ ])
  normal! 2j$
endfunction

function! InsertRubyEach()
  call append(line('.'), [
    \ input('配列名: ') . '.each do |' . input('変数名: ') . '|',
    \ '  ',
    \ 'end'
  \ ])
  normal! 2j$
endfunction

function! InsertRubyModule()
  let name = input('モジュール名: ')
  if name != ''
    call append(line('.'), [
      \ 'module ' . name,
      \ '  ',
      \ 'end'
    \ ])
    normal! 2j$
  endif
endfunction

" Rubyスニペット用キーマッピング
autocmd FileType ruby inoremap <buffer> <Leader>def <Esc>:call InsertRubyDef()<CR>
autocmd FileType ruby inoremap <buffer> <Leader>class <Esc>:call InsertRubyClass()<CR>
autocmd FileType ruby inoremap <buffer> <Leader>if <Esc>:call InsertRubyIf()<CR>
autocmd FileType ruby inoremap <buffer> <Leader>each <Esc>:call InsertRubyEach()<CR>
autocmd FileType ruby inoremap <buffer> <Leader>mod <Esc>:call InsertRubyModule()<CR>

" TypeScriptスニペット関数
function! InsertTsFunction()
  let name = input('関数名: ')
  if name != ''
    let args = input('引数: ')
    let returnType = input('戻り値の型: ')
    call append(line('.'), [
      \ 'function ' . name . '(' . args . ')' . (returnType != '' ? ': ' . returnType : '') . ' {',
      \ '  ',
      \ '}'
    \ ])
    normal! 2j$
  endif
endfunction

function! InsertTsInterface()
  let name = input('インターフェース名: ')
  if name != ''
    call append(line('.'), [
      \ 'interface ' . name . ' {',
      \ '  ',
      \ '}'
    \ ])
    normal! 2j$
  endif
endfunction

function! InsertTsClass()
  let name = input('クラス名: ')
  if name != ''
    call append(line('.'), [
      \ 'class ' . name . ' {',
      \ '  constructor(' . input('引数: ') . ') {',
      \ '    ',
      \ '  }',
      \ '',
      \ '  ',
      \ '}'
    \ ])
    normal! 6j$
  endif
endfunction

function! InsertTsType()
  let name = input('型名: ')
  if name != ''
    let definition = input('型定義: ')
    call append(line('.'), [
      \ 'type ' . name . ' = ' . definition . ';'
    \ ])
    normal! 1j$
  endif
endfunction

function! InsertTsEnum()
  let name = input('Enum名: ')
  if name != ''
    call append(line('.'), [
      \ 'enum ' . name . ' {',
      \ '  ',
      \ '}'
    \ ])
    normal! 2j$
  endif
endfunction

function! InsertTsAsync()
  let name = input('async関数名: ')
  if name != ''
    let args = input('引数: ')
    let returnType = input('戻り値の型: ')
    call append(line('.'), [
      \ 'async function ' . name . '(' . args . ')' . (returnType != '' ? ': Promise<' . returnType . '>' : '') . ' {',
      \ '  ',
      \ '}'
    \ ])
    normal! 2j$
  endif
endfunction

" TypeScriptスニペット用キーマッピング
autocmd FileType typescript inoremap <buffer> <Leader>func <Esc>:call InsertTsFunction()<CR>
autocmd FileType typescript inoremap <buffer> <Leader>int <Esc>:call InsertTsInterface()<CR>
autocmd FileType typescript inoremap <buffer> <Leader>class <Esc>:call InsertTsClass()<CR>
autocmd FileType typescript inoremap <buffer> <Leader>type <Esc>:call InsertTsType()<CR>
autocmd FileType typescript inoremap <buffer> <Leader>enum <Esc>:call InsertTsEnum()<CR>
autocmd FileType typescript inoremap <buffer> <Leader>async <Esc>:call InsertTsAsync()<CR>

" ========================================
" ファイルタイプ別設定
" ========================================

" Perl設定
autocmd FileType perl setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd FileType perl setlocal omnifunc=perlcomplete#Complete
autocmd FileType perl setlocal commentstring=#\ %s

" Ruby設定  
autocmd FileType ruby setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
autocmd FileType ruby setlocal commentstring=#\ %s

" TypeScript設定
autocmd FileType typescript setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType typescript setlocal omnifunc=syntaxcomplete#Complete
autocmd FileType typescript setlocal commentstring=//\ %s

" JavaScript設定（TypeScript用設定を適用）
autocmd FileType javascript setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType javascript setlocal commentstring=//\ %s

" 全言語共通の補完キーマッピング
autocmd FileType perl,ruby,typescript,javascript inoremap <buffer> <C-x><C-o> <C-x><C-o>
autocmd FileType perl,ruby,typescript,javascript inoremap <buffer> <C-Space> <C-x><C-o>

filetype off

set statusline+=%#warningmsg#
set statusline+=%*

set mouse-=a
set ambiwidth=double
set nobackup
set noswapfile
set autoread
set hidden
set showcmd

set nostartofline
set showmatch matchtime=1
set nowritebackup

set relativenumber
set number
set nowrap
set virtualedit+=block
set autoindent
set noerrorbells
set belloff=all
set laststatus=2
set display=lastline
set cmdheight=2
set wildmode=list:full

set nolist
" インデントをshiftwidthの倍数に丸める
set shiftround
set smartindent
set tabstop=2
set shiftwidth=2
set expandtab
set softtabstop=2

set ignorecase
set smartcase
set incsearch
set wrapscan
set hlsearch
set shellslash

set scrolloff=20
set fileencoding=utf-8
set fileformats=unix,dos,mac

set shortmess+=c

set wildmenu
set wildmode=longest:list,full

" 補完の際の大文字小文字の区別しない
set infercase
" 新しく開く代わりにすでに開いてあるバッファを開く
set switchbuf=useopen

" 入力モード中に素早くjjと入力した場合はESCとみなす
inoremap jj <Esc>
" vを二回で行末まで選択
vnoremap v $h

nnoremap j gj
nnoremap k gk
nnoremap <S-l> $
nnoremap <S-h> ^
nnoremap == gg=G''
nnoremap n nzz
nnoremap N Nzz

" CTRL+l ２回で検索の強調表示を消す
nnoremap <silent><C-l><C-l> :<C-u>set nohlsearch!<CR><Esc>

let g:python3_host_prog = '/usr/bin/python3'
let g:python_host_prog = '/usr/bin/python'
let g:powerline_pycmd = 'py3'

" helpやQuickFixを 'q' で閉じる
nnoremap q <Nop>
autocmd FileType help,qf,vim,twitvim,denite,quickrun nnoremap <silent><buffer>q <C-w>c

" ++ と -- でバッファのウインドウサイズを変更する
nnoremap <silent> ++ :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> -- :exe "resize " . (winheight(0) * 2/3)<CR>

" 不要なキーを削除する
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>
nnoremap Q  <Nop>

" CTRL-F5 と CTRL-F6 で複数ファイルのタブ移動する
nnoremap <silent><C-F5> :tabprev<CR>
nnoremap <silent><C-F6> :tabnext<CR>

" .vimrc 再読込設定 & 編集時はReload
nnoremap <Leader>r :source $MYVIMRC<CR>
autocmd BufWritePost .vimrc source $MYVIMRC

" 個別設定
" Makefile
let _curfile=expand("%:r")
if _curfile == 'Makefile'
  setlocal noexpandtab
endif

filetype plugin indent on
" ビルトインカラースキームを使用
colorscheme desert
syntax enable
