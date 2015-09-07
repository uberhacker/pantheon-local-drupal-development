#!/bin/bash
echo -n "Warning: This script will overwrite any existing vim settings.  Are you sure you want to proceed? (y/N): "; read -n 1 PROCEED
echo ""
if [ -z "$PROCEED" ]; then
  exit
fi
if [ "$PROCEED" == "Y" ]; then
  PROCEED=y
fi
if [ "$PROCEED" != "y" ]; then
  exit
fi
VIM_NOX=$(dpkg -l | grep vim-nox)
if [ -z "$VIM_NOX" ]; then
  sudo apt-get install vim-nox
fi
CTAGS=$(dpkg -l | grep exuberant-ctags)
if [ -z "$CTAGS" ]; then
  sudo apt-get install exuberant-ctags
fi
SCREEN=$(dpkg -l | grep screen)
if [ -z "$SCREEN" ]; then
  sudo apt-get install screen
fi
cd
rm -f .vimrc
rm -rf .vim/
mkdir .vim
cd .vim
mkdir bundle
git init
git submodule add https://github.com/tpope/vim-pathogen.git bundle/pathogen
git submodule update --init
ln -s bundle/pathogen/autoload/ autoload
git submodule add https://github.com/flazz/vim-colorschemes.git bundle/colorschemes
git submodule update --init
ln -s bundle/colorschemes/colors/ colors
git submodule add https://github.com/kien/ctrlp.vim.git bundle/ctrlp
git submodule update --init
git submodule add https://github.com/tpope/vim-fugitive.git bundle/fugitive
git submodule update --init
git submodule add https://github.com/wookiehangover/jshint.vim.git bundle/jshint
git submodule update --init
git submodule add https://github.com/scrooloose/nerdcommenter.git bundle/nerdcommenter
git submodule update --init
git submodule add https://github.com/scrooloose/nerdtree.git bundle/nerdtree
git submodule update --init
git submodule add https://github.com/Lokaltog/vim-powerline bundle/powerline
git submodule update --init
git submodule add https://github.com/ervandew/screen.git bundle/screen
git submodule update --init
git submodule add https://github.com/msanders/snipmate.vim.git bundle/snipmate
git submodule update --init
git submodule add https://github.com/ervandew/supertab.git bundle/supertab
git submodule update --init
git submodule add https://github.com/tpope/vim-surround.git bundle/surround
git submodule update --init
git submodule add https://github.com/scrooloose/syntastic.git bundle/syntastic
git submodule update --init
git submodule add https://github.com/vim-scripts/SyntaxComplete.git bundle/syntaxcomplete
git submodule update --init
git submodule add https://github.com/majutsushi/tagbar.git bundle/tagbar
git submodule update --init
git submodule add https://github.com/joonty/vdebug.git bundle/vdebug
git submodule update --init
git submodule add http://git.drupal.org/project/vimrc.git bundle/drupalvim
git submodule update --init
cat << "EOF" >> ~/.vimrc
" Allow Vim-only settings even if they break vi keybindings.
set nocompatible

" Always edit in utf-8:
set encoding=utf-8

" Enable filetype detection
filetype plugin on

" General settings
set incsearch               "Find as you type
set scrolloff=2             "Number of lines to keep above/below cursor
set number                  "Show line numbers
set wildmode=longest,list   "Complete longest string, then list alternatives
set pastetoggle=<F2>        "Toggle paste mode
set fileformats=unix        "Use Unix line endings
set history=300             "Number of commands to remember
set showmode                "Show whether in Visual, Replace, or Insert Mode
set showmatch               "Show matching brackets/parentheses
set backspace=2             "Use standard backspace behavior
set hlsearch                "Highlight matches in search
set ruler                   "Show line and column number
set formatoptions=1         "Don't wrap text after a one-letter word
set linebreak               "Break lines when appropriate
set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
set smartindent

" Enforce consistent line endings: if 'ff' is set to "unix" and there are any
" stray '\r' characters at ends of lines, then automatically remove them. See
" $VIMRUNTIME/indent/php.vim .
let PHP_removeCRwhenUnix = 1

" Persistent Undo (vim 7.3 and later)
if exists('&undofile') && !&undofile
  set undodir=~/.vim_runtime/undodir
  set undofile
endif

" Enable syntax highlighting
if &t_Co > 1
  syntax enable
endif
syntax on

" When in split screen, map <C-LeftArrow> and <C-RightArrow> to switch panes.
nn [5C <C-W>w
nn [5R <C-W>W

" Custom key mapping
map <S-u> :redo<cr>
map <C-n> :tabn<cr>
map <C-p> :tabp<cr>

" Uncomment the following to have Vim jump to the last position when
" reopening a file
if has("autocmd")
 au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
 \| exe "normal! g'\"" | endif
endif

" Load plugins
call pathogen#infect('~/.vim/bundle/drupalvim/bundle/vim-plugin-for-drupal/{}')
call pathogen#infect()
call pathogen#helptags()

" Set the color scheme
if ! has("gui_running")
 set t_Co=256
endif
" feel free to choose :set background=dark for a different style
set background=light
colors peaksea

" Check syntax
nnoremap <silent> <F5> :SyntasticCheck<CR>
let g:syntastic_aggregate_errors = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_jump = 2
let g:syntastic_auto_loc_list = 1
let g:syntastic_debug = 0
let g:syntastic_enable_highlighting = 1
let g:syntastic_enable_signs = 1
let g:syntastic_error_symbol = '✗'
let g:syntastic_php_checkers = ['php', 'phpcs', 'phpmd']
let g:syntastic_php_phpcs_args = '--standard=Drupal --report=csv --extensions=inc,install,module,php,profile,test,theme'
let g:syntastic_phpcs_disable = 1
let g:syntastic_quiet_messages = { "level": "warnings", "type": "syntax" }
let g:syntastic_stl_format = '[%E{Errors: %e starting on line %fe}%B{, }%W{Warnings: %w starting on line %fw}]'
let g:syntastic_style_error_symbol = 'S✗'
let g:syntastic_style_warning_symbol = 'S⚠'
let g:syntastic_warning_symbol = '⚠'
highlight SyntasticErrorLine guibg=red
highlight SyntasticWarningLine guibg=yellow

" Highlight trailing whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" Remove trailing whitespace
function! TrimWhiteSpace()
  %s/\s\+$//e
endfunction
autocmd BufWritePre *.inc,*.install,*.module,*.php,*.profile,*.test,*.theme :call TrimWhiteSpace()

" Start a screen shell session and compass watch
nnoremap <silent> <F6> :ScreenShell compass watch<CR>

" Toggle the NERDTree window
nnoremap <silent> <F7> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
let NERDTreeDirArrows=1
let NERDTreeAutoDeleteBuffer=1

" Toggle the Tagbar window
nnoremap <silent> <F8> :TagbarToggle<CR>

" Toggle line numbers
nnoremap <silent> <F10> :set invnumber<CR>

" Toggle current fold open/closed
nnoremap <Space> za
EOF
