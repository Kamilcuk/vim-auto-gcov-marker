
if !exists("g:auto_gcov_marker_line_covered")
	let g:auto_gcov_marker_line_covered = '✓'
endif
if !exists("g:auto_gcov_marker_line_uncovered")
	let g:auto_gcov_marker_line_uncovered = '✘'
endif
if !exists("g:auto_gcov_marker_branch_covered")
	let g:auto_gcov_marker_branch_covered = '✓✓'
endif
if !exists("g:auto_gcov_marker_branch_partly_covered")
	let g:auto_gcov_marker_branch_partly_covered = '✓✘'
endif
if !exists("g:auto_gcov_marker_branch_uncovered")
	let g:auto_gcov_marker_branch_uncovered = '✘✘'
endif
if !exists("g:auto_gcov_marker_gcov_path")
	let g:auto_gcov_marker_gcov_path = '.'
endif
if !exists("g:auto_gcov_marker_gcno_path")
	let g:auto_gcov_marker_gcno_path = '.'
endif

if !hlexists('GcovLineCovered')
	highlight GCovLineCovered ctermfg=green guifg=green
endif
if !hlexists('GcovLineUncovered')
	highlight GCovLineUncovered ctermfg=red guifg=red
endif
if !hlexists('GcovBranchCovered')
	highlight GCovBranchCovered ctermfg=green guifg=green
endif
if !hlexists('GcovBranchPartlyCovered')
	highlight GCovBranchPartlyCovered ctermfg=yellow guifg=yellow
endif
if !hlexists('GcovBranchUncovered')
	highlight GCovBranchUncovered ctermfg=red guifg=red
endif

function auto_gcov_marker#BuildCov(...)
    let filename = expand('%:t:r')
    let gcno = globpath(g:auto_gcov_marker_gcno_path, '/**/' . filename . '.gcno', 1, 1)
    if len(gcno) == '0'
        let filename = expand('%:t')
        let gcno = globpath(g:auto_gcov_marker_gcno_path, '/**/' . filename . '.gcno', 1, 1)
    endif
    if len(gcno) == '0'
        echo "gcno file not found"
        return
    elseif len(gcno) != '1'
        echo "too many gcno files"
        return
    endif
    let gcno = fnamemodify(gcno[0], ':p')

    silent exe '!(cd ' . g:auto_gcov_marker_gcov_path . '; gcov -i -b -m ' . gcno . ') > /dev/null'
    redraw!

    let gcov = g:auto_gcov_marker_gcov_path . '/' . expand('%:t') . '.gcov'
    if(!filereadable(gcov))
        let gcov = g:auto_gcov_marker_gcov_path . '/' . expand('%:t') . '.gcno.gcov'
    endif

    if(filereadable(gcov))
        call auto_gcov_marker#SetCov(gcov)
    endif
endfunction

let s:marks = []

function auto_gcov_marker#ClearCov(...)
	exe ":sign unplace * group=gcovmarker"
	let s:marks = []
endfunction

function auto_gcov_marker#SetCov(...)
    if(a:0 == 1)
        let filename = a:1
    else
        return
    endif

    " Clear previous markers.
    call auto_gcov_marker#ClearCov()

    " Prepare signs
    exe ":sign define gcov_line_covered texthl=GcovLineCovered text=" . g:auto_gcov_marker_line_covered
    exe ":sign define gcov_line_uncovered texthl=GcovLineUncovered text=" . g:auto_gcov_marker_line_uncovered
    exe ":sign define gcov_branch_covered texthl=GcovBranchCovered text=" . g:auto_gcov_marker_branch_covered
    exe ":sign define gcov_branch_partly_covered texthl=GcovBranchPartlyCovered text=" . g:auto_gcov_marker_branch_partly_covered
    exe ":sign define gcov_branch_uncovered texthl=GcovBranchUncovered text=" . g:auto_gcov_marker_branch_uncovered

    " Read files and fillin marks dictionary
    try
        let gcovfile = readfile(filename)
    catch
        echo "Failed to read gcov file"
        return
    endtry

    for line in gcovfile
		let tt = split(line, ':')
		let mark = trim(tt[0])
		if mark == "#####" || mark == "$$$$$"
			let type = "gcov_line_uncovered"
		elseif mark == "=====" || mark == "%%%%%"
			let type = "gcov_branch_partly_covered"
		elseif mark == '^0\*\?$'
			let type = "gcov_line_uncovered"
		elseif mark == '0*'
			let type = "gcov_branch_uncovered"
		elseif mark =~ '^[0-9]\+$'
			let type = "gcov_line_covered"
		elseif mark =~ '^[0-9]\+\*$'
			let type = "gcov_branch_partly_covered"
		else
			let type = ""
		endif
		" echo mark "." type "." line
		if type != ""
			let linenum = trim(tt[1])
			let s:marks += [[linenum, type]]
		endif
    endfor


	" Iterate over marks dictionary and place signs
	for [line, marktype] in s:marks
		execute ":sign place ".line." group=gcovmarker line=".line." name=".marktype." file=".expand("%:p")
	endfor

    " Set the coverage file for the current buffer
    "let b:coveragefile = fnamemodify(filename, ':p')
endfunction
