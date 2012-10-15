" CY Input Method for Chinese
" 穿越中文输入法 (Vim 版本)
" Author: Cyrus Baow <cy2081@baow.com>
" Last Change:	2012 Oct 15
" Release Version: 1.0
" License: GPL
"
" 主页：http://www.baow.com/help/cyim
"
" 特别说明和致谢：
" 以下程序，是基于 Yue Wu 的 ywvim 输入法开发的，关于 ywvim 输入法请参见：
" http://www.vim.org/scripts/script.php?script_id=2662 ，对 Yue Wu 所做的
" 工作表示衷心的最大程度的感谢。汉字编码主要采用了哲哲豆音形码 ，可参见：
" http://zzdzzd.ys168.com/，对部分词组进行了调整。  对哲哲豆音形码的作者所
" 做的工作表示衷心的最大程度的感谢。
"　
"
"
" 使用方法
" ========
" 
" 安装方法
" --------
"
"     把文件复制放到 plugin 目录下即可
"
"
" 快捷键
" ------
"
"   <Ctrl-x> 输入法开关.
"   <Ctrl-d> 取消当前的中文候选
"   <Ctrl-h> 和 <Backspace> 一样，用于删除前边输入的字母
"   <Ctrl-^> 显示菜单，设置输入法:
"    (m) 码表切换
"    (.) 中英标点切换
"    (p) 最大词长: 设为 1 为单字模试
"    (g) gb2312开关: 滤掉 gb2312 范围内的汉字
"    (c) 简繁转换开关
"    (q) 退出
"

"   ; 分号切换到临时英文，可在文件cy.cy当中的 EnChar 当中设置
"   { 大括号切换到临时拼音 ，在文件cy.cy当中的 PyChar 当中设置
"   大写英文字母切换到英文模式, 键盘左上角的反单引号 ` 回到中文模式 

"   - 向上翻页
"   = 向下翻页

"   空格或数字选字, 回车输英文
"   ; 分号选择第二候选词
"
" 注意事项
" --------
"
"  避免和其它插件产生冲突，如果报错，请先暂停其它相关插件的使用


" 配置开始
let g:cy_zhpunc = 1  " 设置默认中文标点输入开关, 1 为开, 默认中文标点, 0 为关，即英文标点
let g:cy_listmax = 10 " 候选项个数，最多 10 个
let g:cy_esc_autoff = 0 " 设置离开插入模式时是否自动关闭. 1 为自动关闭, 0 为不关闭，保持输入状态
let g:cy_autoinput = 1 " 设置是否自动上屏，1 为自动上屏，0 为不自动上屏
let g:cy_circlecandidates = 1 " 设为 1 表示可以在候选页中循环翻页
let g:cy_helpim_on = 0  " 设为 1 表示打开反查码表的功能，即切换到拼音输入法之后，显示对应编码
let g:cy_lockb = 1 "为 0 时, 在空码时不锁定键盘，可以继续输入，为 1 时，空码时停留在当前状态
let g:cy_preconv = 'g2b' " 默认简繁转换方向
let g:cy_conv = '' " 設置簡繁轉換方向, 'g2b' 為簡轉繁, 'b2g' 為繁轉簡, ''(留空)為關閉 
let g:cy_matchexact = 0  " 严格匹配
let g:cy_gb = 0 " 是否只输入 gb2312 范围汉字
" 配置结束 


" --------------------------------------------------------------------
scriptencoding utf-8
let g:cy_ims=[
            \['cy', '穿越', 'cy.cy'],
            \['py', '拼音', 'pinyin.cy'],
            \]
let g:cy_py = {'helpim':'cy', 'gb':0 } 
let g:cy_chinesecode = 1 " 是否显示中文字母名称

if exists("s:loaded_cy") | finish | endif
let s:loaded_cy = 1

let s:cy_path = expand("<sfile>:p:h")
let g:cy_to_english = 0
let g:cy_eng_target_keys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
let g:cy_buffer = ''

function s:Cy_SetVar(var, val) " Assign user var to script var{{{
    let s:{a:var} = a:val
    if exists('g:'.a:var)
        let s:{a:var} = g:{a:var}
        unlet g:{a:var}
    endif
endfunction "}}}

function s:Cy_loadvar() " Load global user vars.{{{
    let s:cy_ims = []
    if exists("g:cy_ims")
        for v in g:cy_ims
            let mbvar = v
            let mbintername = mbvar[0]
            let mbchinesename = mbvar[1]
            if get(mbvar, 2) != '' " Get mb file info
                let s:cy_{mbintername}_mbfile = mbvar[2]
                if !filereadable(expand(mbvar[2]))
                    let s:cy_{mbintername}_mbfile = matchstr(globpath(s:cy_path, '/**/'.mbvar[2]), "[^\n]*")
                    if s:cy_{mbintername}_mbfile == ''
                        continue
                    endif
                endif
            else
                continue
            endif
            call <SID>Cy_SetVar('cy_'.mbintername, {})
            call add(s:cy_ims, [mbintername, mbchinesename, s:cy_{mbintername}_mbfile])
        endfor
        unlet g:cy_ims
    endif
    if s:cy_ims==[]
        finish
    endif

    let varlst = [
                \["cy_lockb", 1],
                \["cy_zhpunc", 1],
                \["cy_autoinput", 1],
                \["cy_circlecandidates", 1],
                \["cy_helpim_on", 0],
                \["cy_matchexact", 0],
                \["cy_chinesecode", 1],
                \["cy_gb", 0],
                \["cy_esc_autoff", 0],
                \["cy_listmax", 10],
                \['cy_conv', ""],
                \['cy_preconv', "g2b"],
                \['cy_pageupkeys', "-"],
                \['cy_pagednkeys', "="],
                \['cy_inputzh_keys', " 	"],
                \['cy_inputzh_secondkeys', ";"],
                \['cy_inputen_keys', ""],
                \]
    for v in varlst
        call <SID>Cy_SetVar(v[0], v[1])
    endfor

    if s:cy_listmax > 10
        let s:cy_listmax = 10
    endif
endfunction "}}}

function s:Cy_loadmb(...) "{{{
    if exists("a:1")
        let mbintername = a:1
    elseif exists('b:cy_parameters["active_mb"]')
        let mbintername = b:cy_parameters["active_mb"]
    else
        let mbintername = s:cy_ims[0][0]
    endif
    if !exists("s:cy_{mbintername}_mb_encoded")
        let s:cy_{mbintername}_mb_encoded = 'utf-8'
    endif
    let b:cy_parameters["active_mb"] = mbintername
    if !exists("s:cy_{mbintername}_loaded") || (s:cy_{mbintername}_mb_encoded != &encoding)
        let s:cy_{mbintername}_mbdb = filter(readfile(s:cy_{mbintername}_mbfile), "v:val !~ '^\s*$'")
        if s:cy_{mbintername}_mb_encoded != &encoding
            call map(s:cy_{mbintername}_mbdb, 'iconv(v:val, s:cy_{mbintername}_mb_encoded, &encoding)')
            let s:cy_{mbintername}_mb_encoded = &encoding
        endif
        let s:cy_{mbintername}_desc_idxs = match(s:cy_{mbintername}_mbdb, '^\[Description]') + 1
        let s:cy_{mbintername}_desc_idxe = match(s:cy_{mbintername}_mbdb, '^\[[^]]\+]', s:cy_{mbintername}_desc_idxs) - 1
        let s:cy_{mbintername}_chardef_idxs = match(s:cy_{mbintername}_mbdb, '^\[CharDefinition]') + 1
        let s:cy_{mbintername}_chardef_idxe = match(s:cy_{mbintername}_mbdb, '^\[[^]]\+]', s:cy_{mbintername}_chardef_idxs) - 1
        let s:cy_{mbintername}_punc_idxs = match(s:cy_{mbintername}_mbdb, '^\[Punctuation]') + 1
        let s:cy_{mbintername}_punc_idxe = match(s:cy_{mbintername}_mbdb, '^\[[^]]\+]', s:cy_{mbintername}_punc_idxs) - 1
        let s:cy_{mbintername}_main_idxs = match(s:cy_{mbintername}_mbdb, '^\[Main]') + 1
        let s:cy_{mbintername}_main_idxe = len(s:cy_{mbintername}_mbdb) - 1

        let descriptlst = s:cy_{mbintername}_mbdb[s:cy_{mbintername}_desc_idxs : s:cy_{mbintername}_desc_idxe]
        let s:cy_{mbintername}_name = substitute(matchstr(matchstr(descriptlst, '^Name'), '^[^=]\+=\s*\zs.*'), '\s', '', 'g')
        let s:cy_{mbintername}_nameabbr = matchstr(s:cy_{mbintername}_name, '^.')
        let s:cy_{mbintername}_usedcodes =substitute(matchstr(matchstr(descriptlst, '^UsedCodes'), '^[^=]\+=\s*\zs.*'), '\s', '', 'g')
        let s:cy_{mbintername}_endcodes = '[' . matchstr(matchstr(descriptlst, '^EndCodes'), '^[^=]\+=\zs.*') . ']'
        call <SID>Cy_SetMbVar(mbintername, 'maxphraselength', matchstr(matchstr(descriptlst, '^MaxElement'), '^[^=]\+=\s*\zs.*'))
        let s:cy_{mbintername}_maxcodes = matchstr(matchstr(descriptlst, '^MaxCodes'), '^[^=]\+=\s*\zs.*')
        let s:cy_{mbintername}_endinput = matchstr(matchstr(descriptlst, '^EndInput'), '^[^=]\+=\s*\zs.*')
        let s:cy_{mbintername}_enchar = matchstr(matchstr(descriptlst, '^EnChar'), '^[^=]\+=\s*\zs.*')
        let s:cy_{mbintername}_pychar = matchstr(matchstr(descriptlst, '^PyChar'), '^[^=]\+=\s*\zs.*')
        call <SID>Cy_SetMbVar(mbintername, 'inputzh_secondkeys', matchstr(matchstr(descriptlst, '^InputZhSecKeys'), '^[^=]\+=\zs.*'))
        call <SID>Cy_SetMbVar(mbintername, 'inputzh_keys', matchstr(matchstr(descriptlst, '^InputZhKeys'), '^[^=]\+=\zs.*'))
        call <SID>Cy_SetMbVar(mbintername, 'inputen_keys', matchstr(matchstr(descriptlst, '^InputEnKeys'), '^[^=]\+=\zs.*'))
        let s:cy_{mbintername}_altpageupkeys = matchstr(matchstr(descriptlst, '^AltPageUpKeys'), '^[^=]\+=\zs.*')
        let s:cy_{mbintername}_altpagednkeys = matchstr(matchstr(descriptlst, '^AltPageDnKeys'), '^[^=]\+=\zs.*')
        let s:cy_{mbintername}_pageupkeys = '[' . s:cy_pageupkeys . s:cy_{mbintername}_altpageupkeys . ']'
        let s:cy_{mbintername}_pagednkeys = '[' . s:cy_pagednkeys . s:cy_{mbintername}_altpagednkeys . ']'
        let s:cy_{mbintername}_helpim_on = s:cy_helpim_on
        if has_key(s:cy_{mbintername}, 'helpim')
            let helpmb = s:cy_{mbintername}['helpim']
            if !exists("s:cy_{helpmb}_mbdb")
                call <SID>Cy_loadmb(helpmb)
            endif
            let s:cy_{mbintername}_helpmb = helpmb
        endif
        call <SID>Cy_SetScriptVar(mbintername, 'gb')
        call <SID>Cy_SetScriptVar(mbintername, 'matchexact')
        call <SID>Cy_SetScriptVar(mbintername, 'zhpunc')
        call <SID>Cy_SetScriptVar(mbintername, 'listmax')
        let s:cy_{mbintername}_puncdic = {}
        for p in s:cy_{mbintername}_mbdb[s:cy_{mbintername}_punc_idxs : s:cy_{mbintername}_punc_idxe]
            let pl = split(p, '\s\+')
            let s:cy_{mbintername}_puncdic[pl[0]] = pl[1 : -1]
        endfor
        let s:cy_{mbintername}_chardefs = {}
        for def in s:cy_{mbintername}_mbdb[s:cy_{mbintername}_chardef_idxs : s:cy_{mbintername}_chardef_idxe]
            let chardef = split(def, '\s\+')
            let s:cy_{mbintername}_chardefs[chardef[0]] = chardef[1]
        endfor
        let s:cy_{mbintername}_loaded = 1
    endif

    if s:cy_conv != ''
        call <SID>CyLoadConvertList()
    endif
    if s:cy_{mbintername}_gb
        call <SID>CyLoadGBList()
    endif

    if !exists("a:1")
        let b:keymap_name=s:cy_{mbintername}_nameabbr
    endif

    call <SID>CyHighlight()
    return ''
endfunction "}}}

function s:Cy_SetScriptVar(m, n) "{{{
    let s:cy_{a:m}_{a:n} = s:cy_{a:n}
    if has_key(s:cy_{a:m}, a:n)
        let s:cy_{a:m}_{a:n} = s:cy_{a:m}[a:n]
    endif
endfunction "}}}
function s:Cy_SetMbVar(m, n, v) "{{{
    let s:cy_{a:m}_{a:n} = a:v
    if s:cy_{a:m}_{a:n} == ''
        let s:cy_{a:m}_{a:n} = s:cy_{a:n}
    endif
endfunction "}}}
function s:CyLoadConvertList() "{{{
    if !exists("s:cy_clst")
        let s:cy_g2b_mb_encoded = 'utf-8'
        let s:cy_clst = []
        let clstfile = matchstr(globpath(s:cy_path, '/**/g2b.cy'), "[^\n]*")
        if filereadable(clstfile)
            let s:cy_clst = readfile(clstfile)
            let s:cy_clst_sep = index(s:cy_clst, '') + 1
        endif
    endif
    if s:cy_g2b_mb_encoded != &encoding
        call map(s:cy_clst, 'iconv(v:val, s:cy_g2b_mb_encoded, &encoding)')
    endif
endfunction "}}}
function s:CyLoadGBList() "{{{
    if !exists("s:cy_gbfilterlist")
        let s:cy_gbfilter_mb_encoded = 'utf-8'
        let s:cy_gbfilterlist = []
        let gblstfile = matchstr(globpath(s:cy_path, '/**/gb2312.cy'), "[^\n]*")
        if filereadable(gblstfile)
            let s:cy_gbfilterlist = readfile(gblstfile)
        endif
    endif
    if s:cy_gbfilter_mb_encoded != &encoding
        call map(s:cy_gbfilterlist, 'iconv(v:val, s:cy_gbfilter_mb_encoded, &encoding)')
    endif
endfunction "}}}
function s:CyHighlight() "{{{
    let b:cy_parameters["highlight_imname"] = 'MoreMsg'
    if s:cy_conv != ''
        let b:cy_parameters["highlight_imname"] = 'ErrorMsg'
        if s:cy_{b:cy_parameters["active_mb"]}_gb == 1
            let b:cy_parameters["highlight_imname"] = 'Todo'
        endif
    elseif s:cy_{b:cy_parameters["active_mb"]}_gb == 0
        let b:cy_parameters["highlight_imname"] = 'WarningMsg'
    endif
endfunction "}}}

function s:Cy_keymap_punc() "{{{
    for p in keys(s:cy_{b:cy_parameters["active_mb"]}_puncdic)
        if p == '\'
            let exe = 'lnoremap <buffer> <expr> \'." <SID>Cy_puncp('\\')"
        else
            let exe = 'lnoremap <buffer> <expr> '.escape(p, '\|')." <SID>Cy_puncp(".string(escape(p, '\|')).")"
        endif
        execute exe
    endfor
endfunction "}}}

function s:Cy_puncp(p) "{{{
    let pmap = s:cy_{b:cy_parameters["active_mb"]}_puncdic[a:p]
    let lenpmap = len(pmap)
    if lenpmap == 1
        return pmap[0]
    else
        let pid = char2nr(a:p)
        if !exists('b:cy_{b:cy_parameters["active_mb"]}_punc_{pid}')
            let b:cy_{b:cy_parameters["active_mb"]}_punc_{pid} = 1
            return pmap[0]
        else
            unlet b:cy_{b:cy_parameters["active_mb"]}_punc_{pid}
            return pmap[1]
        endif
    endif
endfunction "}}}

function s:Cy_keymap() "{{{
    for key in sort(split(s:cy_{b:cy_parameters["active_mb"]}_usedcodes,'\zs'))
        execute 'lnoremap <buffer> <expr> '.escape(key, '\|').'  <SID>Cy_char("'.key.'")'
    endfor
    if s:cy_{b:cy_parameters["active_mb"]}_zhpunc == 1
        call <SID>Cy_keymap_punc()
    endif
    if s:cy_{b:cy_parameters["active_mb"]}_enchar != ''
        execute 'lnoremap <buffer> <expr> '.s:cy_{b:cy_parameters["active_mb"]}_enchar.' <SID>Cy_enmode()'
    endif
    execute 'lnoremap <buffer> <expr> ` <SID>Cy_tocn()'
    for key in sort(split(g:cy_eng_target_keys,'\zs'))
        execute 'lnoremap <buffer> <expr> '.escape(key, '\|').'  <SID>Cy_toen("'.key.'")'
    endfor
    if s:cy_{b:cy_parameters["active_mb"]}_pychar != ''
        execute 'lnoremap <buffer> <expr> '.s:cy_{b:cy_parameters["active_mb"]}_pychar.' <SID>Cy_onepinyin()'
    endif
    lnoremap <buffer> <C-^> <C-^><C-R>=<SID>Cy_UIsetting(1)<CR>
    if s:cy_esc_autoff
        inoremap <buffer> <esc> <C-R>=Cy_toggle()<CR><C-R>=Cy_toggle()<CR><ESC>
    endif
    inoremap <buffer> <C-d> <ESC>a
    return ''
endfunction "}}}

function s:Cy_UIsetting(m) "{{{
    let punc='。'
    if s:cy_{b:cy_parameters["active_mb"]}_zhpunc == 0
        let punc='.'
    endif
    let pars = ''
    echohl Pmenu | redraw | echon "CY 参数设置[当前状态]\n"
    echohl Title | echon "(m)码表切换[" . s:cy_{b:cy_parameters["active_mb"]}_name . "]\n"
    let pars .= 'm'
    echon "(.)中英标点切换[" . punc . "]\n"
    let pars .= '.'
    echon "(p)最大词长[" . s:cy_{b:cy_parameters["active_mb"]}_maxphraselength . "]\n"
    let pars .= 'p'
    echon "(g)b2312开关[" . s:cy_{b:cy_parameters["active_mb"]}_gb . "]\n"
    let pars .= 'g'
    echon "(c)简繁转换开关[" . s:cy_conv . "]\n"
    let pars .= 'c'
    if exists('s:cy_{b:cy_parameters["active_mb"]}_helpmb')
        echon "(h)反查码表开关[" . s:cy_{b:cy_parameters["active_mb"]}_helpim_on . "]\n"
        let pars .= 'h'
    endif
    echon "(q)退出\n"
    let pars .= 'q'
    echohl None
    let par = ''
    while par !~ '[' . pars . ']'
        let par = nr2char(getchar())
    endwhile
    redraw
    if par == 'm'
        echon "码表切换:\n"
        let nr = 0
        for im in s:cy_ims
            let nr += 1
            echohl Number | echon nr
            echohl None | echon '. ' . im[1] . " "
        endfor
        let getnr = ''
        while getnr !~ '[' . join(range(1, nr), '') . ']'
            let getnr = nr2char(getchar())
        endwhile
        lmapclear <buffer>
        let b:cy_parameters["active_mb"] = s:cy_ims[getnr - 1][0]
        call <SID>Cy_loadmb()
        call <SID>Cy_keymap()
    elseif par == '.'
        if s:cy_{b:cy_parameters["active_mb"]}_zhpunc == 0
            call <SID>Cy_keymap_punc()
        else
            for p in keys(s:cy_{b:cy_parameters["active_mb"]}_puncdic)
                if p == '\'
                    execute 'lunmap <buffer> ' . p
                else
                    execute 'lunmap <buffer> ' . escape(p, '\|')
                endif

            endfor
        endif
        if s:cy_{b:cy_parameters["active_mb"]}_enchar != ''
            execute 'lnoremap <buffer> <expr> ' . s:cy_{b:cy_parameters["active_mb"]}_enchar . ' <SID>Cy_enmode()'
        endif
        let s:cy_{b:cy_parameters["active_mb"]}_zhpunc = 1 - s:cy_{b:cy_parameters["active_mb"]}_zhpunc
    elseif par == 'p'
        let s:cy_{b:cy_parameters["active_mb"]}_maxphraselength = input('最大词长: ', s:cy_{b:cy_parameters["active_mb"]}_maxphraselength)
    elseif par == 'g'
        let s:cy_{b:cy_parameters["active_mb"]}_gb = 1 - s:cy_{b:cy_parameters["active_mb"]}_gb
        if s:cy_{b:cy_parameters["active_mb"]}_gb
            call <SID>CyLoadGBList()
        endif
    elseif par == 'h'
        let s:cy_{b:cy_parameters["active_mb"]}_helpim_on = 1 - s:cy_{b:cy_parameters["active_mb"]}_helpim_on
    elseif par == 'c'
        if s:cy_conv != ''
            let s:oldcy_conv = s:cy_conv
            let s:cy_conv = ''
        else
            call <SID>CyLoadConvertList()
            if exists("s:oldcy_conv")
                let s:cy_conv = s:oldcy_conv
            else
                let s:cy_conv = s:cy_preconv
            endif
        endif
    endif
    call <SID>CyHighlight()
    redraw
    if a:m
        return "\<C-^>"
    endif
    return ""
endfunction "}}}

function s:Cy_comp(zhcode,...) "{{{
    " a:1: startline. a:2: endidx.
    if a:zhcode == ''
        return []
    endif
    let s:cy_complst = []
    let len_zhcode = len(a:zhcode)
    let exactp = '' " If match string extractly
    if s:cy_{b:cy_parameters["active_mb"]}_matchexact
        let exactp = ' '
    endif
    let zhcodep = '\V'.escape(a:zhcode, '\').exactp
    if exists("a:1")
        let s:cy_zhcode_idxs = a:1
    else
        let s:cy_zhcode_idxs = match(s:cy_{b:cy_parameters["active_mb"]}_mbdb, '^'.zhcodep, s:cy_{b:cy_parameters["active_mb"]}_main_idxs)
        let s:cy_zhcode_startidx = s:cy_zhcode_idxs
        let s:cy_zhcode_idxe = match(s:cy_{b:cy_parameters["active_mb"]}_mbdb, '^\%('.zhcodep.'\)\@!', s:cy_zhcode_idxs) - 1
        if s:cy_zhcode_idxe == -2
            let s:cy_zhcode_idxe = s:cy_{b:cy_parameters["active_mb"]}_main_idxe
        endif
    endif
    let lst = s:cy_{b:cy_parameters["active_mb"]}_mbdb[s:cy_zhcode_idxs : s:cy_zhcode_idxe]
    let nr = 0
    if exists("a:2")
        let s:cy_continue_idx = a:2
    else
        let s:cy_continue_idx = 1
    endif
    for i in lst
        let ilst = split(i, '\s\+')
        let suf = strpart(ilst[0], len_zhcode)
        for c in ilst[s:cy_continue_idx : -1]
            if s:cy_continue_idx == len(ilst) - 1
                let s:cy_zhcode_startidx += 1
                let s:cy_continue_idx = 1
            else
                let s:cy_continue_idx += 1
            endif
            let help = ''
            let cup = '\<' . c . '\>'
            if (s:cy_{b:cy_parameters["active_mb"]}_gb == 1) && (strlen(c) <= 3) && (index(s:cy_gbfilterlist, c) == -1)
                " strchars(c) == 1, strlen(c) <= 3: doesn't exist before vim 7.3!
                continue
            endif
            if s:cy_{b:cy_parameters["active_mb"]}_maxphraselength && (strlen(c) > 3 * s:cy_{b:cy_parameters["active_mb"]}_maxphraselength)
                continue
            endif
            if s:cy_{b:cy_parameters["active_mb"]}_helpim_on && exists('s:cy_{b:cy_parameters["active_mb"]}_helpmb') && (strlen(c) == 3)
                " FIXME too slow
                let help = matchstr(matchstr(s:cy_{s:cy_{b:cy_parameters["active_mb"]}_helpmb}_mbdb[s:cy_{s:cy_{b:cy_parameters["active_mb"]}_helpmb}_main_idxs : s:cy_{s:cy_{b:cy_parameters["active_mb"]}_helpmb}_main_idxe], cup), '^\S\+')
                if help != ''
                    let help = '[' . help . ']'
                endif
            endif
            let nr += 1
            let dic = {}
            let dic["word"] = c
            let dic["suf"] = suf
            let dic["nr"] = nr
            let dic["help"] = help
            call add(s:cy_complst, dic)
            if nr == s:cy_{b:cy_parameters["active_mb"]}_listmax
                let s:cy_terminate = 1
                break
            endif
        endfor
        if exists("s:cy_terminate")
            break
        endif
        let s:cy_continue_idx = 1
    endfor
    unlet! s:cy_terminate
    if !exists("a:1")
        let s:cy_pagenr = 0
        let s:cy_lastpagenr = 0
        let s:cy_pgbuf = {}
        let s:cy_pgbuf[0] = s:cy_complst
    endif
    return s:cy_complst
endfunction "}}}

function s:Cy_GetMode() "{{{
    let prepre = ''
    if mode() !~ '[in]'
        let cmdtype = getcmdtype()
        if cmdtype != '@'
            let prepre = cmdtype . getcmdline() . "\n"
        endif
    endif
    return prepre
endfunction "}}}

function s:Cy_echofinalresult(list) "{{{
    let cybarlist = a:list
    let columns = &columns
    let g:cy_buffer = a:list[3]
    let cybar = <SID>Cy_GetMode() . '[' . s:cy_{b:cy_parameters["active_mb"]}_nameabbr . ']' . ' ' . cybarlist[0] . ' ' . cybarlist[1] . ' ' . cybarlist[0]
    for c in cybarlist[2][0:-1]
        let cybar .= ' ' . c.nr . ':' . c.word . c.suf . c.help
    endfor
    " Try to prevent hit-enter-prompt.
    let cmdheight = ((strlen(cybar) + columns/2) / columns) + 1
    if cmdheight != &cmdheight
        execute 'setlocal cmdheight=' . cmdheight
        redraw
    endif
    let ModeStr = <SID>Cy_GetMode()
    echo ModeStr
    execute 'echohl '.b:cy_parameters["highlight_imname"]
    echon '['.s:cy_{b:cy_parameters["active_mb"]}_nameabbr.']' | echohl None
    echon ' '
    execute 'echohl Keyword'
    echon a:list[3] | echohl None
    echon ' '
    echon a:list[0]
    echon ' '
    echon a:list[1]
    echon ' '
    for c in a:list[2][0:-1]
        echon " "
        let nr = c.nr
        if nr == 10
            let nr = 0
        endif
        echohl LineNr | echon nr | echohl None
        if nr == 1
            echon ':' | echon ''
            echohl Keyword | echon c.word | echohl None
        else
            echon ':' | echon c.word
        endif
        echohl Comment | echon c.suf | echohl None
        echon c.help
    endfor
endfunction "}}}

function s:Cy_char(key) "{{{
    let char = ''
    let showchar = ''
    let keycode = char2nr(a:key)
    let temp_char = ''
    let temp_char2 = ''
    let old_char = ''
    while 1
        let maxcodes = s:cy_{b:cy_parameters["active_mb"]}_maxcodes
        let buffer_char = ''
        let swap_char = ''
        let to_char = ''
        let key = nr2char(keycode)
        let keypat = '\V'.escape(key, '\')
        if (keycode == "\<BS>") || (keycode == char2nr("\<C-h>")) "backspace
            if g:cy_to_english == 1
                return key
            endif
            let pgnr = 1
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            if char == ''
                let char = old_char
                let buffer_char = g:cy_buffer
            endif
            let char = matchstr(char, '.*\ze.')
            if char == ''
                let temp_char = ''
                let temp_char2 = ''
                return buffer_char.<SID>Cy_ReturnChar()
            endif
            let showchar = matchstr(showchar, '.*\ze.')
            let candidates = <SID>Cy_comp(char)
            "if len(old_char) == maxcodes
                "let buffer_char = temp_char
            "else
                "let buffer_char = temp_char2
            "endif
            "let buffer_char = temp_char
            "let temp_char = ''
            "let temp_char2 = ''
            call <SID>Cy_echofinalresult([showchar, '[' . (s:cy_pagenr + 1) . ']', candidates, buffer_char])
        elseif (key != '') && (match(g:cy_eng_target_keys, keypat) != -1) "to english
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            let temp_char = ''
            let temp_char2 = ''
            let to_char = ''
            if len(s:cy_pgbuf[s:cy_pagenr]) >= 1
                let to_char = <SID>Cy_ReturnChar(0)
            endif
            if g:cy_to_english == 0
                let g:cy_to_english = 1
                return buffer_char. to_char . key
            else
                return key
            endif
        elseif (key != '') && (match(s:cy_{b:cy_parameters["active_mb"]}_usedcodes, keypat) != -1)
            if g:cy_to_english>0
                let temp_char = ''
                let temp_char2 = ''
                return key
            endif
            let pgnr = 1
            if key != ' '
                let char .= key
                if s:cy_chinesecode && has_key(s:cy_{b:cy_parameters["active_mb"]}_chardefs, key)
                    let showchar .= s:cy_{b:cy_parameters["active_mb"]}_chardefs[key]
                else
                    let showchar .= key
                endif
            endif
            let candidates = <SID>Cy_comp(char)
            let charcomplen = len(s:cy_complst)
            if (charcomplen == 0) && (s:cy_matchexact == 0)
                if s:cy_lockb
                    let char = matchstr(char, '.*\ze.')
                    let showchar = matchstr(showchar, '.*\ze.')
                    let candidates = <SID>Cy_comp(char)
                endif
            endif
            if (s:cy_autoinput == 1) && (len(s:cy_pgbuf[s:cy_pagenr]) == 1)
                let swap_char = temp_char2
                let temp_char = ''
                let temp_char2 = ''
                return swap_char . <SID>Cy_ReturnChar(0)
            endif
            let old_char = char
            if s:cy_{b:cy_parameters["active_mb"]}_endinput == 1
                let showchar = char
                if len(char) ==  maxcodes
                    let char = ''
                    let temp_char = temp_char2
                    if len(s:cy_pgbuf[s:cy_pagenr]) >=1
                        let temp_char2  .=  <SID>Cy_ReturnChar(0)
                    else
                        let temp_char2 = g:cy_buffer
                    endif
                endif
            endif
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            if len(s:cy_pgbuf[s:cy_pagenr]) ==0
                let showchar = ''
                let char = ''
                if len(g:cy_buffer)>0
                    return g:cy_buffer.<SID>Cy_ReturnChar()
                else
                    return "".<SID>Cy_ReturnChar()  "sfjonjhr
                endif
            endif
            call <SID>Cy_echofinalresult([showchar, '[' . (s:cy_pagenr + 1) . ']', candidates, buffer_char])
        elseif (key != '') && (s:cy_{b:cy_parameters["active_mb"]}_pagednkeys =~ keypat)  "page down
            let s:cy_pagenr += 1
            if !has_key(s:cy_pgbuf, s:cy_pagenr)
                let page = <SID>Cy_comp(char,s:cy_zhcode_startidx,s:cy_continue_idx)
                if page != []
                    if s:cy_lastpagenr <= s:cy_pagenr
                        let s:cy_lastpagenr = s:cy_pagenr
                    endif
                    let s:cy_pgbuf[s:cy_pagenr] = page
                else
                    if s:cy_circlecandidates
                        let s:cy_pagenr = 0
                    else
                        let s:cy_pagenr -= 1
                    endif
                endif
            endif
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            call <SID>Cy_echofinalresult([showchar, '[' . (s:cy_pagenr + 1) . ']', s:cy_pgbuf[s:cy_pagenr], buffer_char])
            "if s:cy_autoinput && (len(s:cy_pgbuf[s:cy_pagenr]) == 1)
            "    let temp_char = ''
            "    let temp_char2 = ''
            "    return buffer_char .<SID>Cy_ReturnChar(0)
            "endif
        elseif (key != '') && (s:cy_{b:cy_parameters["active_mb"]}_pageupkeys =~ keypat)  "page up
            if s:cy_pagenr > 0
                let s:cy_pagenr -= 1
            elseif s:cy_circlecandidates
                let s:cy_pagenr = s:cy_lastpagenr
            endif
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            call <SID>Cy_echofinalresult([showchar, '[' . (s:cy_pagenr + 1) . ']', s:cy_pgbuf[s:cy_pagenr], buffer_char])
        elseif s:cy_{b:cy_parameters["active_mb"]}_inputzh_keys =~ keypat " input Chinese
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            let temp_char = ''
            let temp_char2 = ''

            if keycode==32
                if s:cy_pgbuf[s:cy_pagenr] != []
                    return buffer_char.<SID>Cy_ReturnChar(0)
                endif
                return buffer_char.<SID>Cy_ReturnChar()
            "else
                "return buffer_char.<SID>Cy_ReturnChar()
                "let g:cy_to_english = 1
                "return buffer_char.<SID>Cy_ReturnChar(showchar)."\<C-^>"
                "return <SID>Cy_ReturnChar(showchar)
            endif
        elseif '['.s:cy_{b:cy_parameters["active_mb"]}_inputzh_secondkeys.']' =~ keypat " input Second Chinese
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            let temp_char = ''
            let temp_char2 = ''
            if s:cy_pgbuf[s:cy_pagenr] != []
                let secondcharidx = 0
                if len(s:cy_pgbuf[s:cy_pagenr][0]) > 1
                    let secondcharidx = 1
                endif
                return buffer_char.<SID>Cy_ReturnChar(secondcharidx)
            endif
            return buffer_char.<SID>Cy_ReturnChar()
        "elseif key =~ '[0-' . s:cy_{b:cy_parameters["active_mb"]}_listmax . ']' " number selection
        elseif key =~ '[0-9]' " number selection
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            if key <= len(s:cy_pgbuf[s:cy_pagenr])
                let temp_char = ''
                let temp_char2 = ''
                return buffer_char.<SID>Cy_ReturnChar(key - 1)
            else
                call <SID>Cy_echofinalresult([showchar, '[' . (s:cy_pagenr + 1) . ']', candidates, buffer_char])
            endif
        elseif s:cy_{b:cy_parameters["active_mb"]}_inputen_keys =~ keypat " input English
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            let temp_char = ''
            let temp_char2 = ''
            return buffer_char.<SID>Cy_ReturnChar(showchar)
        elseif keycode == char2nr("\<C-^>") "config tools
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            let temp_char = ''
            let temp_char2 = ''
            return buffer_char.<SID>Cy_ReturnChar(0).<SID>Cy_UIsetting(0)
        elseif keycode == char2nr("\<C-x>")  "switch status
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            let temp_char = ''
            let temp_char2 = ''
            "return buffer_char.<SID>Cy_ReturnChar(showchar)."\<C-^>"
            return <SID>Cy_ReturnChar()."\<C-^>"
        elseif keycode == char2nr("\<C-d>")  "
            "return ""
            return <SID>Cy_ReturnChar()
        elseif s:cy_pgbuf[s:cy_pagenr] != [] "return first word and key
            if s:cy_{b:cy_parameters["active_mb"]}_zhpunc && has_key(s:cy_{b:cy_parameters["active_mb"]}_puncdic, key)
                let key = <SID>Cy_puncp(key)
            endif
            if len(old_char) == maxcodes
                let buffer_char = temp_char
            else
                let buffer_char = temp_char2
            endif
            let temp_char = ''
            let temp_char2 = ''
            return buffer_char.<SID>Cy_ReturnChar(0) . key 
        endif
        let keycode = getchar()
    endwhile
endfunction "}}}

function s:Cy_tocn() "{{{
    let g:cy_to_english = 0
    return ""
endfunction "}}}
function s:Cy_toen(key) "{{{
    let g:cy_to_english = 1
    return a:key
endfunction "}}}

function s:Cy_enmode() "{{{
    execute 'echohl ' . b:cy_parameters["highlight_imname"]
    echo <SID>Cy_GetMode() . "[En]: "
    let keycode = getchar()
    let str_en_mode = s:cy_{b:cy_parameters["active_mb"]}_enchar
    if keycode != char2nr(s:cy_{b:cy_parameters["active_mb"]}_enchar)
        let str_en_mode = input("[En]: ", nr2char(keycode)) | echohl None
        call histdel("input", -1)
    elseif s:cy_{b:cy_parameters["active_mb"]}_zhpunc && has_key(s:cy_{b:cy_parameters["active_mb"]}_puncdic, str_en_mode)
        let str_en_mode = <SID>Cy_puncp(str_en_mode)
    endif
    if mode() != 'c'
        echo ''
    endif
    return str_en_mode
endfunction "}}}

function s:Cy_onepinyin() "{{{
    let cy_active_oldmb = b:cy_parameters["active_mb"]
    let b:cy_parameters["active_mb"] = 'py'
    call <SID>Cy_loadmb()
    echo <SID>Cy_GetMode()
    execute 'echohl ' . b:cy_parameters["highlight_imname"]
    echon '[' | echon s:cy_py_nameabbr | echon ']'
    echohl None | echon ' '
    let char = <SID>Cy_char(nr2char(getchar()))
    let b:cy_parameters["active_mb"] = cy_active_oldmb
    call <SID>Cy_loadmb()
    return char
endfunction "}}}

function s:Cy_ReturnChar(...) "{{{
    let sb = ''
    if exists("a:1")
        let sb = a:1
        if a:1 =~ '\d\+'
            let sb = s:cy_pgbuf[s:cy_pagenr][a:1].word
            if s:cy_conv != ''
                let g2bidx = index(s:cy_clst, sb)
                if g2bidx != -1
                    if s:cy_conv == 'g2b' && g2bidx < s:cy_clst_sep
                        let sb = s:cy_clst[g2bidx + s:cy_clst_sep]
                    elseif s:cy_conv == 'b2g' && g2bidx > s:cy_clst_sep
                        let sb = s:cy_clst[g2bidx - s:cy_clst_sep]
                    endif
                endif
            endif
        endif
    elseif getcmdtype() != '@'
        echo getcmdtype() . getcmdline()
    endif
    if mode() != 'c'
        echo ''
    endif
    "return sb . " \<BS>"
    return sb
endfunction "}}}

function CY_Firefox(path)
    let g:file_title = readfile(a:path)[0]
    set statusline=%{g:file_title}\ [%t]\ %<\ %h%m%r%=%-14.(%l,%c%)\ %P\ [buf\ %n\ ]
endfunction

function Cy_toggle() "{{{
    if !exists("s:cy_ims")
        call <SID>Cy_loadvar()
    endif
    let togglekey = "\<C-^>"
    if !exists("b:cy_parameters")
        let b:cy_parameters = {}
        let b:cy_parameters["mode"] = ''
        if &iminsert == 1
            let togglekey .= "\<C-^>"
        endif
    endif
    let current_mode = mode()
    let on_modes = b:cy_parameters["mode"]
    let g:cy_to_english = 0
    if match(on_modes, current_mode) == -1
        let b:cy_parameters["oldcmdheight"] = &cmdheight
        call <SID>Cy_loadmb()
        call <SID>Cy_keymap()
        let b:cy_parameters["mode"] .= current_mode
    else
        execute 'setlocal cmdheight=' . b:cy_parameters["oldcmdheight"]
        unlet! s:cy_zhcode_idxs
        unlet! s:cy_zhcode_idxe
        unlet! s:cy_complst
        let puncvardic = filter(keys(getbufvar("",'')), "v:val=~'_punc_\\d'")
        for p in puncvardic
            unlet b:{p}
        endfor
        let b:cy_parameters["mode"] = substitute(b:cy_parameters["mode"], current_mode, '', '')
    endif
    return togglekey
endfunction "}}}

function Cy_toggle_post() "{{{
    if mode() =~ '[i]'
        redrawstatus
    endif
    return ""
endfunction "}}}

imap <silent> <C-x> <C-R>=Cy_toggle()<CR><C-R>=Cy_toggle_post()<CR>
cmap <silent> <C-x> <C-R>=Cy_toggle()<CR><C-R>=Cy_toggle_post()<CR>

" vim: foldmethod=marker:
