    void
normal_cmd(
    oparg_T	*oap,
    int		toplevel UNUSED)	// TRUE when called from main()
{
    cmdarg_T	ca;			// command arguments
    int		c;
    int		ctrl_w = FALSE;		// got CTRL-W command
    int		old_col = curwin->w_curswant;
#ifdef FEAT_CMDL_INFO
    int		need_flushbuf;		// need to call out_flush()
#endif
    pos_T	old_pos;		// cursor position before command
    int		mapped_len;
    static int	old_mapped_len = 0;
    int		idx;
#ifdef FEAT_EVAL
    int		set_prevcount = FALSE;
#endif
    int		save_did_cursorhold = did_cursorhold;

    CLEAR_FIELD(ca);	// also resets ca.retval
    ca.oap = oap;

    // Use a count remembered from before entering an operator.  After typing
    // "3d" we return from normal_cmd() and come back here, the "3" is
    // remembered in "opcount".
    ca.opcount = opcount;

    /*
     * If there is an operator pending, then the command we take this time
     * will terminate it. Finish_op tells us to finish the operation before
     * returning this time (unless the operation was cancelled).
     */
#ifdef CURSOR_SHAPE
    c = finish_op;
#endif
    finish_op = (oap->op_type != OP_NOP);
#ifdef CURSOR_SHAPE
    if (finish_op != c)
    {
	ui_cursor_shape();		// may show different cursor shape
# ifdef FEAT_MOUSESHAPE
	update_mouseshape(-1);
# endif
    }
#endif

    // When not finishing an operator and no register name typed, reset the
    // count.
    if (!finish_op && !oap->regname)
    {
	ca.opcount = 0;
#ifdef FEAT_EVAL
	set_prevcount = TRUE;
#endif
    }

    // Restore counts from before receiving K_CURSORHOLD.  This means after
    // typing "3", handling K_CURSORHOLD and then typing "2" we get "32", not
    // "3 * 2".
    if (oap->prev_opcount > 0 || oap->prev_count0 > 0)
    {
	ca.opcount = oap->prev_opcount;
	ca.count0 = oap->prev_count0;
	oap->prev_opcount = 0;
	oap->prev_count0 = 0;
    }

    mapped_len = typebuf_maplen();

    State = NORMAL_BUSY;
#ifdef USE_ON_FLY_SCROLL
    dont_scroll = FALSE;	// allow scrolling here
#endif

#ifdef FEAT_EVAL
    // Set v:count here, when called from main() and not a stuffed
    // command, so that v:count can be used in an expression mapping
    // when there is no count. Do set it for redo.
    if (toplevel && readbuf1_empty())
	set_vcount_ca(&ca, &set_prevcount);
#endif

    /*
     * Get the command character from the user.
     */
    c = safe_vgetc();
    LANGMAP_ADJUST(c, get_real_state() != SELECTMODE);

    /*
     * If a mapping was started in Visual or Select mode, remember the length
     * of the mapping.  This is used below to not return to Insert mode for as
     * long as the mapping is being executed.
     */
    if (restart_edit == 0)
	old_mapped_len = 0;
    else if (old_mapped_len
		|| (VIsual_active && mapped_len == 0 && typebuf_maplen() > 0))
	old_mapped_len = typebuf_maplen();

    if (c == NUL)
	c = K_ZERO;

    /*
     * In Select mode, typed text replaces the selection.
     */
    if (VIsual_active
	    && VIsual_select
	    && (vim_isprintc(c) || c == NL || c == CAR || c == K_KENTER))
    {
	// Fake a "c"hange command.  When "restart_edit" is set (e.g., because
	// 'insertmode' is set) fake a "d"elete command, Insert mode will
	// restart automatically.
	// Insert the typed character in the typeahead buffer, so that it can
	// be mapped in Insert mode.  Required for ":lmap" to work.
	ins_char_typebuf(vgetc_char, vgetc_mod_mask);
	if (restart_edit != 0)
	    c = 'd';
	else
	    c = 'c';
	msg_nowait = TRUE;	// don't delay going to insert mode
	old_mapped_len = 0;	// do go to Insert mode
    }

#ifdef FEAT_CMDL_INFO
    need_flushbuf = add_to_showcmd(c);
#endif

getcount:
    if (!(VIsual_active && VIsual_select))
    {
	/*
	 * Handle a count before a command and compute ca.count0.
	 * Note that '0' is a command and not the start of a count, but it's
	 * part of a count after other digits.
	 */
	while (    (c >= '1' && c <= '9')
		|| (ca.count0 != 0 && (c == K_DEL || c == K_KDEL || c == '0')))
	{
	    if (c == K_DEL || c == K_KDEL)
	    {
		ca.count0 /= 10;
#ifdef FEAT_CMDL_INFO
		del_from_showcmd(4);	// delete the digit and ~@%
#endif
	    }
	    else
		ca.count0 = ca.count0 * 10 + (c - '0');
	    if (ca.count0 < 0)	    // overflow
		ca.count0 = 999999999L;
#ifdef FEAT_EVAL
	    // Set v:count here, when called from main() and not a stuffed
	    // command, so that v:count can be used in an expression mapping
	    // right after the count. Do set it for redo.
	    if (toplevel && readbuf1_empty())
		set_vcount_ca(&ca, &set_prevcount);
#endif
	    if (ctrl_w)
	    {
		++no_mapping;
		++allow_keys;		// no mapping for nchar, but keys
	    }
	    ++no_zero_mapping;		// don't map zero here
	    c = plain_vgetc();
	    LANGMAP_ADJUST(c, TRUE);
	    --no_zero_mapping;
	    if (ctrl_w)
	    {
		--no_mapping;
		--allow_keys;
	    }
#ifdef FEAT_CMDL_INFO
	    need_flushbuf |= add_to_showcmd(c);
#endif
	}

	/*
	 * If we got CTRL-W there may be a/another count
	 */
	if (c == Ctrl_W && !ctrl_w && oap->op_type == OP_NOP)
	{
	    ctrl_w = TRUE;
	    ca.opcount = ca.count0;	// remember first count
	    ca.count0 = 0;
	    ++no_mapping;
	    ++allow_keys;		// no mapping for nchar, but keys
	    c = plain_vgetc();		// get next character
	    LANGMAP_ADJUST(c, TRUE);
	    --no_mapping;
	    --allow_keys;
#ifdef FEAT_CMDL_INFO
	    need_flushbuf |= add_to_showcmd(c);
#endif
	    goto getcount;		// jump back
	}
    }

    if (c == K_CURSORHOLD)
    {
	// Save the count values so that ca.opcount and ca.count0 are exactly
	// the same when coming back here after handling K_CURSORHOLD.
	oap->prev_opcount = ca.opcount;
	oap->prev_count0 = ca.count0;
    }
    else if (ca.opcount != 0)
    {
	/*
	 * If we're in the middle of an operator (including after entering a
	 * yank buffer with '"') AND we had a count before the operator, then
	 * that count overrides the current value of ca.count0.
	 * What this means effectively, is that commands like "3dw" get turned
	 * into "d3w" which makes things fall into place pretty neatly.
	 * If you give a count before AND after the operator, they are
	 * multiplied.
	 */
	if (ca.count0)
	    ca.count0 *= ca.opcount;
	else
	    ca.count0 = ca.opcount;
	if (ca.count0 < 0)	    // overflow
	    ca.count0 = 999999999L;
    }

    /*
     * Always remember the count.  It will be set to zero (on the next call,
     * above) when there is no pending operator.
     * When called from main(), save the count for use by the "count" built-in
     * variable.
     */
    ca.opcount = ca.count0;
    ca.count1 = (ca.count0 == 0 ? 1 : ca.count0);

#ifdef FEAT_EVAL
    /*
     * Only set v:count when called from main() and not a stuffed command.
     * Do set it for redo.
     */
    if (toplevel && readbuf1_empty())
	set_vcount(ca.count0, ca.count1, set_prevcount);
#endif

    /*
     * Find the command character in the table of commands.
     * For CTRL-W we already got nchar when looking for a count.
     */
    if (ctrl_w)
    {
	ca.nchar = c;
	ca.cmdchar = Ctrl_W;
    }
    else
	ca.cmdchar = c;
    idx = find_command(ca.cmdchar);
    if (idx < 0)
    {
	// Not a known command: beep.
	clearopbeep(oap);
	goto normal_end;
    }

    if (text_locked() && (nv_cmds[idx].cmd_flags & NV_NCW))
    {
	// This command is not allowed while editing a cmdline: beep.
	clearopbeep(oap);
	text_locked_msg();
	goto normal_end;
    }
    if ((nv_cmds[idx].cmd_flags & NV_NCW) && curbuf_locked())
	goto normal_end;

    /*
     * In Visual/Select mode, a few keys are handled in a special way.
     */
    if (VIsual_active)
    {
	// when 'keymodel' contains "stopsel" may stop Select/Visual mode
	if (km_stopsel
		&& (nv_cmds[idx].cmd_flags & NV_STS)
		&& !(mod_mask & MOD_MASK_SHIFT))
	{
	    end_visual_mode();
	    redraw_curbuf_later(INVERTED);
	}

	// Keys that work different when 'keymodel' contains "startsel"
	if (km_startsel)
	{
	    if (nv_cmds[idx].cmd_flags & NV_SS)
	    {
		unshift_special(&ca);
		idx = find_command(ca.cmdchar);
		if (idx < 0)
		{
		    // Just in case
		    clearopbeep(oap);
		    goto normal_end;
		}
	    }
	    else if ((nv_cmds[idx].cmd_flags & NV_SSS)
					       && (mod_mask & MOD_MASK_SHIFT))
		mod_mask &= ~MOD_MASK_SHIFT;
	}
    }

#ifdef FEAT_RIGHTLEFT
    if (curwin->w_p_rl && KeyTyped && !KeyStuffed
					  && (nv_cmds[idx].cmd_flags & NV_RL))
    {
	// Invert horizontal movements and operations.  Only when typed by the
	// user directly, not when the result of a mapping or "x" translated
	// to "dl".
	switch (ca.cmdchar)
	{
	    case 'l':	    ca.cmdchar = 'h'; break;
	    case K_RIGHT:   ca.cmdchar = K_LEFT; break;
	    case K_S_RIGHT: ca.cmdchar = K_S_LEFT; break;
	    case K_C_RIGHT: ca.cmdchar = K_C_LEFT; break;
	    case 'h':	    ca.cmdchar = 'l'; break;
	    case K_LEFT:    ca.cmdchar = K_RIGHT; break;
	    case K_S_LEFT:  ca.cmdchar = K_S_RIGHT; break;
	    case K_C_LEFT:  ca.cmdchar = K_C_RIGHT; break;
	    case '>':	    ca.cmdchar = '<'; break;
	    case '<':	    ca.cmdchar = '>'; break;
	}
	idx = find_command(ca.cmdchar);
    }
#endif

    /*
     * Get an additional character if we need one.
     */
    if ((nv_cmds[idx].cmd_flags & NV_NCH)
	    && (((nv_cmds[idx].cmd_flags & NV_NCH_NOP) == NV_NCH_NOP
		    && oap->op_type == OP_NOP)
		|| (nv_cmds[idx].cmd_flags & NV_NCH_ALW) == NV_NCH_ALW
		|| (ca.cmdchar == 'q'
		    && oap->op_type == OP_NOP
		    && reg_recording == 0
		    && reg_executing == 0)
		|| ((ca.cmdchar == 'a' || ca.cmdchar == 'i')
		    && (oap->op_type != OP_NOP || VIsual_active))))
    {
	int	*cp;
	int	repl = FALSE;	// get character for replace mode
	int	lit = FALSE;	// get extra character literally
	int	langmap_active = FALSE;    // using :lmap mappings
	int	lang;		// getting a text character
#ifdef HAVE_INPUT_METHOD
	int	save_smd;	// saved value of p_smd
#endif

	++no_mapping;
	++allow_keys;		// no mapping for nchar, but allow key codes
	// Don't generate a CursorHold event here, most commands can't handle
	// it, e.g., nv_replace(), nv_csearch().
	did_cursorhold = TRUE;
	if (ca.cmdchar == 'g')
	{
	    /*
	     * For 'g' get the next character now, so that we can check for
	     * "gr", "g'" and "g`".
	     */
	    ca.nchar = plain_vgetc();
	    LANGMAP_ADJUST(ca.nchar, TRUE);
#ifdef FEAT_CMDL_INFO
	    need_flushbuf |= add_to_showcmd(ca.nchar);
#endif
	    if (ca.nchar == 'r' || ca.nchar == '\'' || ca.nchar == '`'
						       || ca.nchar == Ctrl_BSL)
	    {
		cp = &ca.extra_char;	// need to get a third character
		if (ca.nchar != 'r')
		    lit = TRUE;			// get it literally
		else
		    repl = TRUE;		// get it in replace mode
	    }
	    else
		cp = NULL;		// no third character needed
	}
	else
	{
	    if (ca.cmdchar == 'r')		// get it in replace mode
		repl = TRUE;
	    cp = &ca.nchar;
	}
	lang = (repl || (nv_cmds[idx].cmd_flags & NV_LANG));

	/*
	 * Get a second or third character.
	 */
	if (cp != NULL)
	{
	    if (repl)
	    {
		State = REPLACE;	// pretend Replace mode
#ifdef CURSOR_SHAPE
		ui_cursor_shape();	// show different cursor shape
#endif
	    }
	    if (lang && curbuf->b_p_iminsert == B_IMODE_LMAP)
	    {
		// Allow mappings defined with ":lmap".
		--no_mapping;
		--allow_keys;
		if (repl)
		    State = LREPLACE;
		else
		    State = LANGMAP;
		langmap_active = TRUE;
	    }
#ifdef HAVE_INPUT_METHOD
	    save_smd = p_smd;
	    p_smd = FALSE;	// Don't let the IM code show the mode here
	    if (lang && curbuf->b_p_iminsert == B_IMODE_IM)
		im_set_active(TRUE);
#endif
	    if ((State & INSERT) && !p_ek)
	    {
#ifdef FEAT_JOB_CHANNEL
		ch_log_output = TRUE;
#endif
		// Disable bracketed paste and modifyOtherKeys here, we won't
		// recognize the escape sequences with 'esckeys' off.
		out_str(T_BD);
		out_str(T_CTE);
	    }

	    *cp = plain_vgetc();

	    if ((State & INSERT) && !p_ek)
	    {
#ifdef FEAT_JOB_CHANNEL
		ch_log_output = TRUE;
#endif
		// Re-enable bracketed paste mode and modifyOtherKeys
		out_str(T_BE);
		out_str(T_CTI);
	    }

	    if (langmap_active)
	    {
		// Undo the decrement done above
		++no_mapping;
		++allow_keys;
		State = NORMAL_BUSY;
	    }
#ifdef HAVE_INPUT_METHOD
	    if (lang)
	    {
		if (curbuf->b_p_iminsert != B_IMODE_LMAP)
		    im_save_status(&curbuf->b_p_iminsert);
		im_set_active(FALSE);
	    }
	    p_smd = save_smd;
#endif
	    State = NORMAL_BUSY;
#ifdef FEAT_CMDL_INFO
	    need_flushbuf |= add_to_showcmd(*cp);
#endif

	    if (!lit)
	    {
#ifdef FEAT_DIGRAPHS
		// Typing CTRL-K gets a digraph.
		if (*cp == Ctrl_K
			&& ((nv_cmds[idx].cmd_flags & NV_LANG)
			    || cp == &ca.extra_char)
			&& vim_strchr(p_cpo, CPO_DIGRAPH) == NULL)
		{
		    c = get_digraph(FALSE);
		    if (c > 0)
		    {
			*cp = c;
# ifdef FEAT_CMDL_INFO
			// Guessing how to update showcmd here...
			del_from_showcmd(3);
			need_flushbuf |= add_to_showcmd(*cp);
# endif
		    }
		}
#endif

		// adjust chars > 127, except after "tTfFr" commands
		LANGMAP_ADJUST(*cp, !lang);
#ifdef FEAT_RIGHTLEFT
		// adjust Hebrew mapped char
		if (p_hkmap && lang && KeyTyped)
		    *cp = hkmap(*cp);
#endif
	    }

	    /*
	     * When the next character is CTRL-\ a following CTRL-N means the
	     * command is aborted and we go to Normal mode.
	     */
	    if (cp == &ca.extra_char
		    && ca.nchar == Ctrl_BSL
		    && (ca.extra_char == Ctrl_N || ca.extra_char == Ctrl_G))
	    {
		ca.cmdchar = Ctrl_BSL;
		ca.nchar = ca.extra_char;
		idx = find_command(ca.cmdchar);
	    }
	    else if ((ca.nchar == 'n' || ca.nchar == 'N') && ca.cmdchar == 'g')
		ca.oap->op_type = get_op_type(*cp, NUL);
	    else if (*cp == Ctrl_BSL)
	    {
		long towait = (p_ttm >= 0 ? p_ttm : p_tm);

		// There is a busy wait here when typing "f<C-\>" and then
		// something different from CTRL-N.  Can't be avoided.
		while ((c = vpeekc()) <= 0 && towait > 0L)
		{
		    do_sleep(towait > 50L ? 50L : towait, FALSE);
		    towait -= 50L;
		}
		if (c > 0)
		{
		    c = plain_vgetc();
		    if (c != Ctrl_N && c != Ctrl_G)
			vungetc(c);
		    else
		    {
			ca.cmdchar = Ctrl_BSL;
			ca.nchar = c;
			idx = find_command(ca.cmdchar);
		    }
		}
	    }

	    // When getting a text character and the next character is a
	    // multi-byte character, it could be a composing character.
	    // However, don't wait for it to arrive. Also, do enable mapping,
	    // because if it's put back with vungetc() it's too late to apply
	    // mapping.
	    --no_mapping;
	    while (enc_utf8 && lang && (c = vpeekc()) > 0
				 && (c >= 0x100 || MB_BYTE2LEN(vpeekc()) > 1))
	    {
		c = plain_vgetc();
		if (!utf_iscomposing(c))
		{
		    vungetc(c);		// it wasn't, put it back
		    break;
		}
		else if (ca.ncharC1 == 0)
		    ca.ncharC1 = c;
		else
		    ca.ncharC2 = c;
	    }
	    ++no_mapping;
	}
	--no_mapping;
	--allow_keys;
    }

#ifdef FEAT_CMDL_INFO
    /*
     * Flush the showcmd characters onto the screen so we can see them while
     * the command is being executed.  Only do this when the shown command was
     * actually displayed, otherwise this will slow down a lot when executing
     * mappings.
     */
    if (need_flushbuf)
	out_flush();
#endif
    if (ca.cmdchar != K_IGNORE)
    {
	if (ex_normal_busy)
	    did_cursorhold = save_did_cursorhold;
	else
	    did_cursorhold = FALSE;
    }

    State = NORMAL;

    if (ca.nchar == ESC)
    {
	clearop(oap);
	if (restart_edit == 0 && goto_im())
	    restart_edit = 'a';
	goto normal_end;
    }

    if (ca.cmdchar != K_IGNORE)
    {
	msg_didout = FALSE;    // don't scroll screen up for normal command
	msg_col = 0;
    }

    old_pos = curwin->w_cursor;		// remember where cursor was

    // When 'keymodel' contains "startsel" some keys start Select/Visual
    // mode.
    if (!VIsual_active && km_startsel)
    {
	if (nv_cmds[idx].cmd_flags & NV_SS)
	{
	    start_selection();
	    unshift_special(&ca);
	    idx = find_command(ca.cmdchar);
	}
	else if ((nv_cmds[idx].cmd_flags & NV_SSS)
					   && (mod_mask & MOD_MASK_SHIFT))
	{
	    start_selection();
	    mod_mask &= ~MOD_MASK_SHIFT;
	}
    }

    /*
     * Execute the command!
     * Call the command function found in the commands table.
     */
    ca.arg = nv_cmds[idx].cmd_arg;
    (nv_cmds[idx].cmd_func)(&ca);

    /*
     * If we didn't start or finish an operator, reset oap->regname, unless we
     * need it later.
     */
    if (!finish_op
	    && !oap->op_type
	    && (idx < 0 || !(nv_cmds[idx].cmd_flags & NV_KEEPREG)))
    {
	clearop(oap);
#ifdef FEAT_EVAL
	reset_reg_var();
#endif
    }

    // Get the length of mapped chars again after typing a count, second
    // character or "z333<cr>".
    if (old_mapped_len > 0)
	old_mapped_len = typebuf_maplen();

    /*
     * If an operation is pending, handle it.  But not for K_IGNORE or
     * K_MOUSEMOVE.
     */
    if (ca.cmdchar != K_IGNORE && ca.cmdchar != K_MOUSEMOVE)
	do_pending_operator(&ca, old_col, FALSE);

    /*
     * Wait for a moment when a message is displayed that will be overwritten
     * by the mode message.
     * In Visual mode and with "^O" in Insert mode, a short message will be
     * overwritten by the mode message.  Wait a bit, until a key is hit.
     * In Visual mode, it's more important to keep the Visual area updated
     * than keeping a message (e.g. from a /pat search).
     * Only do this if the command was typed, not from a mapping.
     * Don't wait when emsg_silent is non-zero.
     * Also wait a bit after an error message, e.g. for "^O:".
     * Don't redraw the screen, it would remove the message.
     */
    if (       ((p_smd
		    && msg_silent == 0
		    && (restart_edit != 0
			|| (VIsual_active
			    && old_pos.lnum == curwin->w_cursor.lnum
			    && old_pos.col == curwin->w_cursor.col)
		       )
		    && (clear_cmdline
			|| redraw_cmdline)
		    && (msg_didout || (msg_didany && msg_scroll))
		    && !msg_nowait
		    && KeyTyped)
		|| (restart_edit != 0
		    && !VIsual_active
		    && (msg_scroll
			|| emsg_on_display)))
	    && oap->regname == 0
	    && !(ca.retval & CA_COMMAND_BUSY)
	    && stuff_empty()
	    && typebuf_typed()
	    && emsg_silent == 0
	    && !in_assert_fails
	    && !did_wait_return
	    && oap->op_type == OP_NOP)
    {
	int	save_State = State;

	// Draw the cursor with the right shape here
	if (restart_edit != 0)
	    State = INSERT;

	// If need to redraw, and there is a "keep_msg", redraw before the
	// delay
	if (must_redraw && keep_msg != NULL && !emsg_on_display)
	{
	    char_u	*kmsg;

	    kmsg = keep_msg;
	    keep_msg = NULL;
	    // Showmode() will clear keep_msg, but we want to use it anyway.
	    // First update w_topline.
	    setcursor();
	    update_screen(0);
	    // now reset it, otherwise it's put in the history again
	    keep_msg = kmsg;

	    kmsg = vim_strsave(keep_msg);
	    if (kmsg != NULL)
	    {
		msg_attr((char *)kmsg, keep_msg_attr);
		vim_free(kmsg);
	    }
	}
	setcursor();
#ifdef CURSOR_SHAPE
	ui_cursor_shape();		// may show different cursor shape
#endif
	cursor_on();
	out_flush();
	if (msg_scroll || emsg_on_display)
	    ui_delay(1003L, TRUE);	// wait at least one second
	ui_delay(3003L, FALSE);		// wait up to three seconds
	State = save_State;

	msg_scroll = FALSE;
	emsg_on_display = FALSE;
    }

    /*
     * Finish up after executing a Normal mode command.
     */
normal_end:

    msg_nowait = FALSE;

#ifdef FEAT_EVAL
    if (finish_op)
	reset_reg_var();
#endif

    // Reset finish_op, in case it was set
#ifdef CURSOR_SHAPE
    c = finish_op;
#endif
    finish_op = FALSE;
#ifdef CURSOR_SHAPE
    // Redraw the cursor with another shape, if we were in Operator-pending
    // mode or did a replace command.
    if (c || ca.cmdchar == 'r')
    {
	ui_cursor_shape();		// may show different cursor shape
# ifdef FEAT_MOUSESHAPE
	update_mouseshape(-1);
# endif
    }
#endif

#ifdef FEAT_CMDL_INFO
    if (oap->op_type == OP_NOP && oap->regname == 0
	    && ca.cmdchar != K_CURSORHOLD)
	clear_showcmd();
#endif

    checkpcmark();		// check if we moved since setting pcmark
    vim_free(ca.searchbuf);

    if (has_mbyte)
	mb_adjust_cursor();

    if (curwin->w_p_scb && toplevel)
    {
	validate_cursor();	// may need to update w_leftcol
	do_check_scrollbind(TRUE);
    }

    if (curwin->w_p_crb && toplevel)
    {
	validate_cursor();	// may need to update w_leftcol
	do_check_cursorbind();
    }

#ifdef FEAT_TERMINAL
    // don't go to Insert mode if a terminal has a running job
    if (term_job_running(curbuf->b_term))
	restart_edit = 0;
#endif

    /*
     * May restart edit(), if we got here with CTRL-O in Insert mode (but not
     * if still inside a mapping that started in Visual mode).
     * May switch from Visual to Select mode after CTRL-O command.
     */
    if (       oap->op_type == OP_NOP
	    && ((restart_edit != 0 && !VIsual_active && old_mapped_len == 0)
		|| restart_VIsual_select == 1)
	    && !(ca.retval & CA_COMMAND_BUSY)
	    && stuff_empty()
	    && oap->regname == 0)
    {
	if (restart_VIsual_select == 1)
	{
	    VIsual_select = TRUE;
	    showmode();
	    restart_VIsual_select = 0;
	}
	if (restart_edit != 0 && !VIsual_active && old_mapped_len == 0)
	    (void)edit(restart_edit, FALSE, 1L);
    }

    if (restart_VIsual_select == 2)
	restart_VIsual_select = 1;

    // Save count before an operator for next time.
    opcount = ca.opcount;
}
