" cw_logger
if ! exists("g:cw_logger_devinitials")
	let g:cw_logger_devinitials = "BR"
endif

" log
autocmd BufNewFile,BufRead,BufEnter *.php inoremap <c-l> <esc>o$GLOBALS['logger']->log( "<C-r>=g:cw_logger_devinitials<cr>: ", CW_LOG_DEV );<esc>T:a
autocmd BufNewFile,BufRead,BufEnter *.php noremap <c-l> o$GLOBALS['logger']->log( "<C-r>=g:cw_logger_devinitials<cr>: ", CW_LOG_DEV );<esc>T:a

" log_export
autocmd BufNewFile,BufRead,BufEnter *.php inoremap <c-x> <esc>lT$h<c-v>/<Bslash>w<Bslash>W<cr>y:let @/=""<cr>o$GLOBALS['logger']->log_export( <esc>p$a, CW_LOG_DEV, '<C-r>=g:cw_logger_devinitials<cr>: <esc>p$a' );
autocmd BufNewFile,BufRead,BufEnter *.php noremap <c-x> lT$h<c-v>/<Bslash>w<Bslash>W<cr>y:let @/=""<cr>o$GLOBALS['logger']->log_export( <esc>p$a, CW_LOG_DEV, '<C-r>=g:cw_logger_devinitials<cr>: <esc>p$a' );

autocmd BufNewFile,BufRead,BufEnter *.js,*.html inoremap <c-l> <esc>oconsole.log( "<C-r>=g:cw_logger_devinitials<cr>: " );<esc>T:a
autocmd BufNewFile,BufRead,BufEnter *.js,*.html noremap <c-l> oconsole.log( "<C-r>=g:cw_logger_devinitials<cr>: " );<esc>T:a

" tab_completion.vim
" vim.org tip
" Allows tab-completion when not at the beginning of a line.
function! InsertTabWrapper()
      let col = col('.') - 1
      if !col || getline('.')[col - 1] !~ '\k'
          return "\<tab>"
      else
          return "\<c-n>"
      endif
endfunction
inoremap <tab> <c-r>=InsertTabWrapper()<cr>

set completeopt=menu,preview,longest

" fufExtras
function! FufPattern( pattern )

	let s:listener = {}

	function! s:listener.onComplete(item, method)
		let a:i = split(a:item, "*")
		let a:n = split(a:i[0], "\\")
		let a:m = split(a:n[0], "\]")
		let a:t = split(a:m[0], "\[")
		exe "/" . a:t[0]
	endfunction

	function! s:listener.onAbort()
		echo "Abort"
	endfunction

	call fuf#callbackitem#launch( '', 0, ">", s:listener, BufferGrep( a:pattern ), "")

endfunction

command! -nargs=1 FufPattern call FufPattern( <q-args> )

function! FufAllFiles( )

	let s:listener = {}

	if !filereadable( ".project_index" )
		echo "Indexing, please try later."
		call ScreenIndexDir()
		return
	endif

	function! s:listener.onComplete(item, method)
		exe "edit " . a:item
	endfunction

	function! s:listener.onAbort()
		echo "Abort"
	endfunction

	let s.project_index = readfile( ".project_index" )

	call fuf#callbackitem#launch( '', 1, ">", s:listener, s.project_index, "")

endfunction



augroup Fufunction
	au!
	au BufEnter *.php command! FufFunction FufPattern ^[ \t]*(public |private |protected |static |abstract )?(public |private |protected |static |final )?(& ?)?(function|class)
	au BufEnter *.rb  command! FufFunction FufPattern ^[ \t]*(def|class|module)
	au BufEnter *.py  command! FufFunction FufPattern ^[ \t]*(def|class)
	au BufEnter *.m   command! FufFunction FufPattern ^- ?\\(
	au BufEnter *.h   command! FufFunction FufPattern ^- ?\\(
	au BufEnter *.vim command! FufFunction FufPattern ^[ \t]*fun
	au BufEnter *.js  command! FufFunction FufPattern ^[ \t]*function|: ?function|= ?function
	au BufEnter *.clj command! FufFunction FufPattern ^[ \t]*\\(defn
	au BufEnter *.el  command! FufFunction FufPattern ^[ \t]*\\(defun
	au BufEnter *.go  command! FufFunction FufPattern ^func
augroup END


" support.vim
command! D Explore %:h
command! -range -nargs=1 Flop call RFlop( "<args>" )
/gmmand! FixNewlines %s/
command! -range -nargs=1 S call SubSub( "<args>" )
command! -range -nargs=1 Flop S/^(.*?)(\\s*)<args>(\\s*)(.*?)$/\\4\\2<args>\\3\\1
command! ValPhp call ValPhp()

""""
function! Selection()
	"return [col("'<"), col("'>")]
	return strpart(getline("."), col("'<") - 1, col("'>") - col("'<") + 1)
endfunction


function! SelectionRange()
	return [col("'<") - 1, col("'>") - 1]
endfunction


function! SubSub( args )
ruby << EOR
	start  = VIM[ %Q{col("'<")} ].to_i - 1
	finish = VIM[ %Q{col("'>")} ].to_i - 1
	args   = VIM[ "a:args" ].split( "/" )
	find = args[1]
	replace = args[2]
	args = args.length > 3 ? args[3] : ""

	method = args =~ /g/ ? "gsub" : "sub"
	find = Regexp.new( find, args =~ /i/ )

	line   = VIM::Buffer.current.line

	line[start..finish] = line[start..finish].send( method, find, replace )
	VIM::Buffer.current.line = line
EOR
endfunction


function! BufferContents()
	return getline(1, "$")
endfunction


function! ArrayGrep( list, pattern )
	return split( StringGrep( join( a:list, "\n" ), a:pattern ), "\n" )
endfunction


function! StringGrep( string, pattern )
	return system( "ruby -e 'print STDIN.read.split(\"\n\").grep( %r{" . a:pattern . "} ).join(\"\n\")'", a:string )
endfunction


function! BufferGrep( pattern )
	return ArrayGrep( BufferContents(), a:pattern )
endfunction


function! RubyEval( string )
	return system( 'ruby -e "print eval STDIN.read"', a:string )
endfunction


function! IndexDir()
	let g:file_index = split( system( "find -E . -type f -not -regex '.*(svn|git|cvs).*'" ), "\n" )
endfunction


function! ValPhp()
	let s:results = system( "php -l " . expand("%") )
	if match( s:results, "No syntax errors detected" ) != -1
		return
	else
		echo s:results
	endif
endfunction

augroup PhpAuto
	au!
	au BufWritePost *.php ValPhp
augroup END
