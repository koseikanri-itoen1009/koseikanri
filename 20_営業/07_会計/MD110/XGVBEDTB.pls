CREATE OR REPLACE PACKAGE BODY xgv_bq
--
--  XGVBEDTB.pls
--
--  Copyright (c) Oracle Corporation 2001-2007. All Rights Reserved
--
--  NAME
--    xgv_bq
--  FUNCTION
--    Edit condition for Balance inquiry(Body)
--  NOTES
--
--
AS

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  -- Invalid authority error.
  e_invalid_authority  EXCEPTION;

  --==========================================================
  --Procedure Name: set_query_condition
  --Description: Get record for balance query
  --Note:
  --Parameter(s):
  --  p_balance_query_rec: Record for balance query
  --  p_query_id         : Query id
  --==========================================================
  PROCEDURE set_query_condition(
    p_balance_query_rec OUT xgv_common.balance_query_rtype,
    p_query_id          IN  NUMBER)
  IS

    -- Select save other segment conditions
    CURSOR l_other_conditions_cur(
      p_query_id NUMBER)
    IS
      SELECT xqc.segment_type segment_type,
             xqc.condition condition
      FROM   xgv_query_conditions xqc
      WHERE  xqc.query_id = p_query_id
        AND  NOT EXISTS
             (SELECT *
              FROM   xgv_flex_structures_vl xfsv
              WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
                AND  xfsv.application_id = xgv_common.get_gl_appl_id
                AND  xfsv.flexfield_name = 'GL#'
                AND  to_char(xfsv.segment_id) = xqc.segment_type);

    -- Select save segment conditions
    /* Bug#200011 08-Jun-2004 Changed by ytsujiha_jp */
    CURSOR l_seg_conditions_cur(
      p_query_id NUMBER)
    IS
      SELECT xfsv.segment_id order1,
             xqc.segment_type segment_type,
             xqc.condition condition,
             xqc.show_order show_order
      FROM   xgv_flex_structures_vl xfsv,
             xgv_query_conditions xqc
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  to_char(xfsv.segment_id) = xqc.segment_type
        AND  xqc.query_id = p_query_id
      ORDER BY 1;

    -- Select AFF Defines
    CURSOR l_aff_segs_cur
    IS
      SELECT xfsv.segment_id segment_type
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
        AND  xfsv.flexfield_name = 'GL#'
      ORDER BY 1;

  BEGIN

    IF  p_query_id IS NULL
    THEN
      RAISE NO_DATA_FOUND;
    END IF;

    -- Get save other segment conditions
    SELECT xq.query_id,
           xq.query_name,
           xq.result_format,
           xq.file_name,
           xq.description,
           xq.result_rows,
           xq.creation_date,
           xq.created_by,
           xq.last_update_date,
           xq.last_updated_by
    INTO   p_balance_query_rec.query_id,
           p_balance_query_rec.query_name,
           p_balance_query_rec.result_format,
           p_balance_query_rec.file_name,
           p_balance_query_rec.description,
           p_balance_query_rec.result_rows,
           p_balance_query_rec.creation_date,
           p_balance_query_rec.created_by,
           p_balance_query_rec.last_update_date,
           p_balance_query_rec.last_updated_by
    FROM   xgv_queries xq
    WHERE  xq.query_id = p_query_id
      AND  xq.inquiry_type = 'B';

    FOR  l_other_conditions_rec IN l_other_conditions_cur(p_query_id)
    LOOP

      -- Accounting Periods
      IF  l_other_conditions_rec.segment_type = 'ACTP'
      THEN
        p_balance_query_rec.period_from := to_number(xgv_common.split(l_other_conditions_rec.condition, ','));
        p_balance_query_rec.period_to   := to_number(xgv_common.split(l_other_conditions_rec.condition, ',', 1, 2));

      -- Currency
      ELSIF  l_other_conditions_rec.segment_type = 'CUR'
      THEN
        p_balance_query_rec.currency_code := l_other_conditions_rec.condition;

      -- Entered Currency
      ELSIF  l_other_conditions_rec.segment_type = 'ENTER'
      THEN
        p_balance_query_rec.show_entered := l_other_conditions_rec.condition;

      -- Translated Currency
      ELSIF  l_other_conditions_rec.segment_type = 'TRANS'
      THEN
        p_balance_query_rec.show_translated := l_other_conditions_rec.condition;

      -- Balance Type(Actual/Budget/Budget and Actual)
      ELSIF  l_other_conditions_rec.segment_type = 'TYPE'
      THEN
        p_balance_query_rec.balance_type := l_other_conditions_rec.condition;

      -- Budget Version ID
      ELSIF  l_other_conditions_rec.segment_type = 'BUDID'
      THEN
        p_balance_query_rec.budget_version_id := to_number(l_other_conditions_rec.condition);

      -- Display Forward Balance
      /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
      ELSIF  l_other_conditions_rec.segment_type = 'FWDTYPE'
      THEN
        p_balance_query_rec.forward_type := l_other_conditions_rec.condition;

      -- Display Balance Amount
      ELSIF  l_other_conditions_rec.segment_type = 'BALTYPE'
      THEN
        p_balance_query_rec.bs_balance_type := xgv_common.split(l_other_conditions_rec.condition, ',');
        p_balance_query_rec.pl_balance_type := xgv_common.split(l_other_conditions_rec.condition, ',', 1, 2);

      -- Display Debit and Credit
      ELSIF  l_other_conditions_rec.segment_type = 'DRCR'
      THEN
        p_balance_query_rec.show_dr_cr := l_other_conditions_rec.condition;

      -- Display Summary Accounts
      ELSIF  l_other_conditions_rec.segment_type = 'SUMMARYACT'
      THEN
        p_balance_query_rec.show_summary := l_other_conditions_rec.condition;

      -- Summary Template ID
      /* Req＃220020 30-Mar-2007 Added by ytsujiha_jp */
      ELSIF  l_other_conditions_rec.segment_type = 'SUMMARYTMP'
      THEN
        p_balance_query_rec.summary_template_id := to_number(l_other_conditions_rec.condition);

      -- Display Parent Value Only
      /* Req#200003 09-Jul-2004 Added by ytsujiha_jp */
      ELSIF  l_other_conditions_rec.segment_type = 'PARENTONLY'
      THEN
        p_balance_query_rec.parent_only := l_other_conditions_rec.condition;

      -- Display Parent Value
      /* Req#200003 05-Jul-2004 Added by ytsujiha_jp */
      ELSIF  l_other_conditions_rec.segment_type = 'PARENTVAL'
      THEN
        DECLARE
          l_segment  PLS_INTEGER;
        BEGIN
          -- Setting default value
          FOR  l_index IN 1..xgv_common.get_num_aff_segs
          LOOP
            p_balance_query_rec.parent_value_tab(l_index) := 'N';
          END LOOP;
          -- Setting saved value
          FOR  l_index IN 1..xgv_common.get_num_aff_segs
          LOOP
            l_segment := to_number(xgv_common.split(l_other_conditions_rec.condition, ',', 1, l_index));
            IF  l_segment IS NULL
            THEN
              EXIT;
            ELSE
              p_balance_query_rec.parent_value_tab(l_segment) := 'Y';
            END IF;
          END LOOP;
        END;

      -- Subtotal Item
      ELSIF  l_other_conditions_rec.segment_type = 'BREAKKEY'
      THEN
        p_balance_query_rec.break_key := l_other_conditions_rec.condition;

      -- Display Total
      ELSIF  l_other_conditions_rec.segment_type = 'TOTAL'
      THEN
        p_balance_query_rec.show_total := l_other_conditions_rec.condition;

      -- Drilldown Template ID
      ELSIF  l_other_conditions_rec.segment_type = 'DDTMP'
      THEN
        p_balance_query_rec.dd_template_id := to_number(l_other_conditions_rec.condition);
        BEGIN
          SELECT xq.query_name
          INTO   p_balance_query_rec.dd_template_name
          FROM   xgv_queries xq
          WHERE  xq.query_id = p_balance_query_rec.dd_template_id;
        EXCEPTION
          WHEN  NO_DATA_FOUND
          THEN
            p_balance_query_rec.dd_template_id := NULL;
        END;
      END IF;

    END LOOP;

    -- Get save segment conditions
    FOR  l_seg_conditions_rec IN l_seg_conditions_cur(p_query_id)
    LOOP
      IF  l_seg_conditions_rec.segment_type != to_char(l_seg_conditions_cur%ROWCOUNT)
      THEN
        raise_application_error(-20100,
          xgv_common.get_message('XGV-20100',
            xgv_common.get_sob_id,
            p_balance_query_rec.query_name,
            l_seg_conditions_cur%ROWCOUNT,
            l_seg_conditions_rec.segment_type));
      END IF;

      p_balance_query_rec.condition_tab(l_seg_conditions_cur%ROWCOUNT)    := l_seg_conditions_rec.condition;
      p_balance_query_rec.show_order_tab(l_seg_conditions_cur%ROWCOUNT)   := l_seg_conditions_rec.show_order;
      p_balance_query_rec.segment_type_tab(l_seg_conditions_cur%ROWCOUNT) := l_seg_conditions_rec.segment_type;
    END LOOP;

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  NO_DATA_FOUND
    THEN
      -- Set default value
      p_balance_query_rec.query_id            := NULL;
      p_balance_query_rec.query_name          := NULL;
      p_balance_query_rec.period_from         := xgv_common.get_current_period;
      p_balance_query_rec.period_to           := xgv_common.get_current_period;
      p_balance_query_rec.currency_code       := xgv_common.get_functional_currency;
      p_balance_query_rec.show_entered        := 'Y';
      p_balance_query_rec.show_translated     := 'N';
      p_balance_query_rec.balance_type        := 'A';
      p_balance_query_rec.budget_version_id   := NULL;
      p_balance_query_rec.forward_type        := 'YTD';        /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
      p_balance_query_rec.bs_balance_type     := 'YTD';
      p_balance_query_rec.pl_balance_type     := 'PTD';
      p_balance_query_rec.show_dr_cr          := 'N';
      p_balance_query_rec.show_summary        := 'N';
      p_balance_query_rec.summary_template_id := NULL;         /* Req＃220020 30-Mar-2007 Added by ytsujiha_jp */
      p_balance_query_rec.parent_only         := 'N';
      p_balance_query_rec.break_key           := NULL;
      p_balance_query_rec.show_total          := 'N';
      p_balance_query_rec.result_format       := nvl(xgv_common.get_profile_option_value('XGV_DEFAULT_RESULT_FORMAT'), 'HTML');
      p_balance_query_rec.file_name           := NULL;
      p_balance_query_rec.dd_template_id      := NULL;
      p_balance_query_rec.description         := NULL;
      p_balance_query_rec.result_rows         := NULL;
      p_balance_query_rec.creation_date       := NULL;
      p_balance_query_rec.created_by          := NULL;
      p_balance_query_rec.last_update_date    := NULL;
      p_balance_query_rec.last_updated_by     := NULL;

      FOR  l_aff_segs_rec IN l_aff_segs_cur
      LOOP
        IF  l_aff_segs_rec.segment_type != to_char(l_aff_segs_cur%ROWCOUNT)
        THEN
          raise_application_error(-20100,
            xgv_common.get_message('XGV-20100',
              xgv_common.get_sob_id,
              ' ',
              l_aff_segs_cur%ROWCOUNT,
              l_aff_segs_rec.segment_type));
        END IF;

        p_balance_query_rec.parent_value_tab(l_aff_segs_cur%ROWCOUNT) := 'N';  /* Req#200003 05-Jul-2004 Added by ytsujiha_jp */
        p_balance_query_rec.condition_tab(l_aff_segs_cur%ROWCOUNT)    := NULL;
        p_balance_query_rec.show_order_tab(l_aff_segs_cur%ROWCOUNT)   := NULL;
        p_balance_query_rec.segment_type_tab(l_aff_segs_cur%ROWCOUNT) := l_aff_segs_rec.segment_type;
      END LOOP;

  END set_query_condition;

  --==========================================================
  --Procedure Name: set_query_condition_local
  --Description: Set record for balance query
  --Note:
  --Parameter(s):
  --  p_balance_query_rec  : Record for balance query
  --  p_query_id           : Query id
  --  p_period_from        : Accounting periods(From)
  --  p_period_to          : Accounting periods(To)
  --  p_currency_code      : Currency
  --  p_show_entered       : Display entered currency
  --  p_show_translated    : Display translated currency
  --  p_balance_type       : Balance type
  --  p_budget_version_id  : Budget version id
  --  p_forward_type       : Display balance amount of forward balance
  --  p_bs_balance_type    : Display balance amount of B/S account
  --  p_pl_balance_type    : Display balance amount of P/L account
  --  p_show_dr_cr         : Display debit and credit
  --  p_show_summary       : Display summary accounts
  --  p_summary_template_id: Summary template id
  --  p_parent_only        : Display parent value only
  --  p_parent_value       : Display parent value
  --  p_condition          : Segment condition
  --  p_show_order         : Segment show order
  --  p_segment_type       : Segment type
  --  p_break_key          : Break key
  --  p_show_total         : Display total
  --  p_result_format      : Result format
  --  p_file_name          : Filename
  --  p_dd_template_id     : Drilldown template id
  --  p_description        : Description
  --==========================================================
  PROCEDURE set_query_condition_local(
    p_balance_query_rec   OUT xgv_common.balance_query_rtype,
    p_query_id            IN  NUMBER,
    p_period_from         IN  NUMBER,
    p_period_to           IN  NUMBER,
    p_currency_code       IN  VARCHAR2,
    p_show_entered        IN  VARCHAR2,
    p_show_translated     IN  VARCHAR2,
    p_balance_type        IN  VARCHAR2,
    p_budget_version_id   IN  NUMBER,
    p_forward_type        IN  VARCHAR2,    /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
    p_bs_balance_type     IN  VARCHAR2,
    p_pl_balance_type     IN  VARCHAR2,
    p_show_dr_cr          IN  VARCHAR2,
    p_show_summary        IN  VARCHAR2,
    p_summary_template_id IN  NUMBER,      /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    p_parent_only         IN  VARCHAR2,
    p_parent_value        IN  xgv_common.array_ttype,
    p_condition           IN  xgv_common.array_ttype,
    p_show_order          IN  xgv_common.array_ttype,
    p_segment_type        IN  xgv_common.array_ttype,
    p_break_key           IN  VARCHAR2,
    p_show_total          IN  VARCHAR2,
    p_result_format       IN  VARCHAR2,
    p_file_name           IN  VARCHAR2,
    p_dd_template_id      IN  NUMBER,
    p_description         IN  VARCHAR2)
  IS
  BEGIN

    IF  p_query_id IS NULL
    THEN
      p_balance_query_rec.query_id := NULL;
      p_balance_query_rec.query_name := NULL;
      p_balance_query_rec.creation_date := NULL;
      p_balance_query_rec.created_by := NULL;
      p_balance_query_rec.last_update_date := NULL;
      p_balance_query_rec.last_updated_by := NULL;

    -- Set WHO columns
    ELSE
      SELECT xq.query_id,
             xq.query_name,
             xq.creation_date,
             xq.created_by,
             xq.last_update_date,
             xq.last_updated_by
      INTO   p_balance_query_rec.query_id,
             p_balance_query_rec.query_name,
             p_balance_query_rec.creation_date,
             p_balance_query_rec.created_by,
             p_balance_query_rec.last_update_date,
             p_balance_query_rec.last_updated_by
      FROM   xgv_queries xq
      WHERE  xq.query_id = p_query_id;
    END IF;

    -- Set other segment conditions
    p_balance_query_rec.period_from         := p_period_from;
    p_balance_query_rec.period_to           := p_period_to;
    p_balance_query_rec.currency_code       := p_currency_code;
    p_balance_query_rec.show_entered        := p_show_entered;
    p_balance_query_rec.show_translated     := p_show_translated;
    p_balance_query_rec.balance_type        := p_balance_type;
    p_balance_query_rec.budget_version_id   := p_budget_version_id;
    p_balance_query_rec.forward_type        := nvl(p_forward_type, 'YTD'); /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
    p_balance_query_rec.bs_balance_type     := nvl(p_bs_balance_type, 'YTD');
    p_balance_query_rec.pl_balance_type     := nvl(p_pl_balance_type, 'PTD');
    p_balance_query_rec.show_dr_cr          := p_show_dr_cr;
    p_balance_query_rec.show_summary        := p_show_summary;
    p_balance_query_rec.summary_template_id := p_summary_template_id;      /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    p_balance_query_rec.parent_only         := p_parent_only;
    p_balance_query_rec.break_key           := p_break_key;
    p_balance_query_rec.show_total          := p_show_total;
    p_balance_query_rec.result_format       := p_result_format;
    p_balance_query_rec.file_name           := p_file_name;
    p_balance_query_rec.dd_template_id      := p_dd_template_id;
    p_balance_query_rec.description         := p_description;
    p_balance_query_rec.result_rows         := xgv_common.get_result_rows;
    BEGIN
      SELECT xq.query_name
      INTO   p_balance_query_rec.dd_template_name
      FROM   xgv_queries xq
      WHERE  xq.query_id = p_balance_query_rec.dd_template_id;
    EXCEPTION
      WHEN  NO_DATA_FOUND
      THEN
        p_balance_query_rec.dd_template_id := NULL;
    END;

    -- Set segment conditions
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      IF  p_segment_type(l_index) != l_index
      THEN
        raise_application_error(-20111,
          xgv_common.get_message('XGV-20111', l_index, p_segment_type(l_index)));
      END IF;

      p_balance_query_rec.parent_value_tab(l_index) := 'N';  /* Req#200003 05-Jul-2004 Added by ytsujiha_jp */
      p_balance_query_rec.condition_tab(l_index)    := p_condition(l_index);
      p_balance_query_rec.show_order_tab(l_index)   := p_show_order(l_index);
      p_balance_query_rec.segment_type_tab(l_index) := p_segment_type(l_index);
    END LOOP;

    -- Setting "Display parent value" to p_balance_query_rec.parent_value_tab
    /* Req#200003 05-Jul-2004 Added by ytsujiha_jp */
    FOR  l_index IN 1..p_parent_value.COUNT
    LOOP
      p_balance_query_rec.parent_value_tab(to_number(p_parent_value(l_index))) := 'Y';
    END LOOP;

  END set_query_condition_local;

  --==========================================================
  --Procedure Name: show_side_navigator
  --Description: Display side navigator for Balance inquiry
  --Note:
  --Parameter(s):
  --  p_selected_func: Selected Function
  --==========================================================
  PROCEDURE show_side_navigator(
    p_selected_func IN VARCHAR2 DEFAULT 'EDITOR')
  IS

    -- Tag of side navigator
    l_side_nav  VARCHAR2(2000);

    FUNCTION get_tag(
      p_title_id IN VARCHAR2,
      p_status   IN VARCHAR2 DEFAULT 'E',
      p_link_url IN VARCHAR2 DEFAULT NULL,
      p_indent   IN NUMBER DEFAULT 0)
    RETURN VARCHAR2
    IS

      l_class  VARCHAR2(256);

    BEGIN

      IF  p_status = 'S'
      THEN
        l_class := 'OraSelected';
      ELSIF  p_status = 'E'
      THEN
        l_class := 'OraSideBar';
      ELSE
        l_class := 'OraSideBar';
      END IF;

      RETURN
        '<tr>'
        || '<td class="' || l_class || '"><script>t(8, 1);</script></td>'
        || '<td class="' || l_class || '" nowrap>'
        || '<script>t(' || to_char(20 * p_indent) || ', 1);</script>'
        || xgv_common.r_nvl2(p_link_url, '<a href="' || p_link_url || '">', NULL)
        || xgv_common.r_decode(p_status, 'D', '<span class="OraDisabled">', NULL)
        || xgv_common.get_message(p_title_id)
        || xgv_common.r_decode(p_status, 'D', '</span>', NULL)
        || xgv_common.r_nvl2(p_link_url, '</a>', NULL)
        || '</td>'
        || '<td class="' || l_class || '"><script>t(8, 1);</script></td>'
        || '</tr>';

    END get_tag;

  BEGIN

    l_side_nav := '<table border="0" cellpadding="0" cellspacing="0">';

    -- Display 'Condition Editor'
    IF  p_selected_func = 'EDITOR'
    THEN
      l_side_nav := l_side_nav || get_tag('TEXT_CONDITION_EDITOR', 'S');

    ELSE
      l_side_nav := l_side_nav
        || get_tag('TEXT_CONDITION_EDITOR', 'D');
    END IF;

    l_side_nav := l_side_nav
      || '<tr><td colspan="3"><script>t(1, 9);</script></td></tr>'
      || '<tr><td class="OraSelected" colspan="3"><script>t(1, 1);</script></td></tr>'
      || '<tr><td colspan="3"><script>t(1, 9);</script></td></tr>';

    -- Display 'New'
    IF  p_selected_func IN ('EDITOR', 'OPEN')
    THEN
      l_side_nav := l_side_nav
        || get_tag('TEXT_NEW_CONDITION', 'E', 'javascript:gotoPage(''bq'');');

    ELSE
      l_side_nav := l_side_nav
        || get_tag('TEXT_NEW_CONDITION', 'D', NULL);
    END IF;

    l_side_nav := l_side_nav
      || '<tr><td colspan="3"><script>t(1, 9);</script></td></tr>';

    -- Display 'Open'
    IF  p_selected_func = 'OPEN'
    THEN
      l_side_nav := l_side_nav || get_tag('TEXT_OPEN_CONDITION', 'S');

    ELSIF  p_selected_func = 'EDITOR'
    THEN
      l_side_nav := l_side_nav
        || get_tag('TEXT_OPEN_CONDITION', 'E', 'javascript:gotoPage(''bq.open'');');

    ELSE
      l_side_nav := l_side_nav || get_tag('TEXT_OPEN_CONDITION', 'D');
    END IF;

    l_side_nav := l_side_nav
      || '<tr><td colspan="3"><script>t(1, 9);</script></td></tr>'
      || '<tr><td class="OraSelected" colspan="3"><script>t(1, 1);</script></td></tr>'
      || '<tr><td colspan="3"><script>t(1, 9);</script></td></tr>';

    -- Display 'Save'
    IF  p_selected_func = 'SAVE'
    THEN
      l_side_nav := l_side_nav || get_tag('TITLE_SAVE_CONDITION', 'S');

    ELSIF  p_selected_func = 'EDITOR'
    THEN
      l_side_nav := l_side_nav
        || get_tag('TEXT_SAVE_CONDITION', 'E', 'javascript:requestSaveDialog(''UD'');');

    ELSE
      l_side_nav := l_side_nav || get_tag('TEXT_SAVE_CONDITION', 'D');
    END IF;

    l_side_nav := l_side_nav
      || '<tr><td colspan="3"><script>t(1, 9);</script></td></tr>';

    -- Display 'Save As'
    IF  p_selected_func = 'SAVEAS'
    THEN
      l_side_nav := l_side_nav || get_tag('TITLE_SAVEAS_CONDITION', 'S');

    ELSIF  p_selected_func = 'EDITOR'
    THEN
      l_side_nav := l_side_nav
        || get_tag('TITLE_SAVEAS_CONDITION', 'E', 'javascript:requestSaveDialog(''ND'');');

    ELSE
      l_side_nav := l_side_nav || get_tag('TITLE_SAVEAS_CONDITION', 'D');
    END IF;

    l_side_nav := l_side_nav || '</table>';

    xgv_common.show_side_navigation(l_side_nav);

  END show_side_navigator;

  --==========================================================
  --Procedure Name: show_query_editor
  --Description: Display condition editor for Balance inquiry
  --Note:
  --Parameter(s):
  --  p_modify_flag      : Modify flag(Yes/No)
  --  p_balance_query_rec: Query condition record
  --==========================================================
  PROCEDURE show_query_editor(
    p_modify_flag       IN VARCHAR2,
    p_balance_query_rec IN xgv_common.balance_query_rtype)
  IS

    l_parent_segment_id  xgv_flex_structures_vl.parent_segment_id%TYPE;
    l_show_lov_proc  xgv_flex_structures_vl.show_lov_proc%TYPE;
    l_hide_flag  xgv_flex_structures_vl.hide_flag%TYPE;
    l_mandatory_flag  xgv_flex_structures_vl.mandatory_flag%TYPE;

    CURSOR l_tag_breakkey_cur(p_default NUMBER DEFAULT NULL)
    IS
      SELECT 1 order1,
             to_number(NULL) order2,
             '<option value=""' || decode(p_default, NULL, ' selected>', '>')
             || xgv_common.get_message('TEXT_NO_SELECT') output_string
      FROM   dual
      UNION  ALL
      SELECT 2 order1,
             xfsv.segment_id order2,
             '<option value="' || xfsv.segment_id
             || decode(xfsv.segment_id, p_default, '" selected>', '">')
             || xfsv.segment_name output_string
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
        AND  xfsv.flexfield_name = 'GL#'
        AND  xfsv.hide_flag = 'N'
      ORDER BY 1, 2;

    /* 13-May-2005 Added by ytsujiha_jp */
    /* Req#210007 30-Nov-2005 Changed by ytsujiha_jp */
    CURSOR l_tag_result_format_cur(p_default VARCHAR2 DEFAULT NULL)
    IS
      SELECT '<option value="' || xlv.lookup_code
             || decode(xlv.lookup_code, p_default, '" selected>', '">')
             || htf.escape_sc(xlv.meaning) output_string
      FROM   (SELECT lookup_code,
                     meaning
              FROM   xgv_lookups_vl
              WHERE  lookup_type = 'RESULT_FORMAT'
                AND  enabled_flag = 'Y'
                AND  (start_date_active <= sysdate OR start_date_active IS NULL)
                AND  (end_date_active >= trunc(sysdate) OR end_date_active IS NULL)
                AND  nvl(
                       xgv_common.get_profile_option_value(
                         decode(lookup_code, 'HTML', 'XGV_RESULT_FORMAT_HTML',
                                             'TEXT', 'XGV_RESULT_FORMAT_TEXT',
                                             'EXCEL', 'XGV_RESULT_FORMAT_EXCEL',
                                             'CSV', 'XGV_RESULT_FORMAT_CSV')), 'N') = 'Y'
              ORDER BY lookup_code) xlv
      UNION
      SELECT '<option value="' || xtv.template_code
             || decode(xtv.template_code, p_default, '" selected>', '">')
             || htf.escape_sc(xtv.description) output_string
      FROM   (SELECT template_code,
                     description
              FROM   xgv_xdo_templates_vl
              WHERE  nvl(xgv_common.get_profile_option_value('XGV_RESULT_FORMAT_XDO'), 'N') = 'Y'
              ORDER BY template_code) xtv;

  BEGIN

    htp.p('<form name="f_query" method="post">');
    htp.p('<input type="hidden" name="p_mode">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_balance_query_rec.query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' || htf.escape_sc(p_balance_query_rec.query_name) || '">');

    htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td colspan="2" width="100%">');

    xgv_common.show_title(
      xgv_common.get_message('TITLE_CONDITION_NAME', nvl(p_balance_query_rec.query_name, ' ')),
      '<span class="OraTextInline">'
      || '<img src="/XGV_IMAGE/ii-required_status.gif">'
      || xgv_common.get_message('NOTE_MANDATORY_CONDITION'),
      p_fontsize=>'M');

    --------------------------------------------------
    -- Display query condition information
    --------------------------------------------------
    IF  p_balance_query_rec.query_name IS NOT NULL
    THEN
      htp.p('<table border="0" cellpadding="0" cellspacing="0">');

      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_CREATED_BY')
        ||  '</th>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<td class="OraDataText">'
        ||  xgv_common.escape_sc(xgv_common.get_user_name(p_balance_query_rec.created_by))
        ||  '</td>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_CREATION_DATE')
        ||  '</th>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<td class="OraDataText">' || p_balance_query_rec.creation_date || '</td>'
        ||  '</tr>');
      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_UPDATED_BY')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataText">'
        ||  xgv_common.escape_sc(xgv_common.get_user_name(p_balance_query_rec.last_updated_by))
        ||  '</td>'
        ||  '<td></td>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_UPDATE_DATE')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataText">' || p_balance_query_rec.last_update_date || '</td>'
        ||  '</tr>');
      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_COUNT_ROWS')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataNumber">' || to_char(p_balance_query_rec.result_rows, '999G999G999G990') || '</td>'
        ||  '<td colspan="4"></td>'
        ||  '</tr>');

      htp.p('</table>');
    END IF;

    htp.p('</td>');
    htp.p('</tr>');

    htp.p('<tr>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td width="100%">');

    --------------------------------------------------
    -- Display basic conditions
    --------------------------------------------------
    htp.prn('<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_BASIC_CONDITIONS'), p_fontsize=>'S');

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');

    -- Display accounting periods
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_PERIODS')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  xgv_common.get_message('PROMPT_FROM')
      ||  '<select name="p_period_from" onChange="validatePeriod(this)">');
    FOR  l_period_rec IN xgv_common.g_tag_period_cur('FROM', p_balance_query_rec.period_from)
    LOOP
      htp.p(l_period_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '<script>t(12, 0);</script>'
      ||  xgv_common.get_message('PROMPT_TO')
      ||  '<select name="p_period_to" onChange="validatePeriod(this)">');
    FOR  l_period_rec IN xgv_common.g_tag_period_cur('TO', p_balance_query_rec.period_to)
    LOOP
      htp.p(l_period_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '</td>'
      ||  '</tr>');

    -- Display currency and currency option
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_CURRENCY')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_currency_code">');
    FOR  l_currency_rec IN xgv_common.g_tag_currency_cur(p_balance_query_rec.currency_code)
    LOOP
      htp.p(l_currency_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="checkbox" name="p_show_entered" value="Y"'
      ||  xgv_common.r_decode(p_balance_query_rec.show_entered, 'Y', ' checked>', '>')
      ||  xgv_common.get_message('PROMPT_ENTERED_CURRENCY')
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="checkbox" name="p_show_translated" value="Y"'
      ||  xgv_common.r_decode(p_balance_query_rec.show_translated, 'Y', ' checked>', '>')
      ||  xgv_common.get_message('PROMPT_TRANSLATED_CURRENCY')
      ||  '</td>'
      ||  '</tr>');

    -- Display balance type
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_BALANCE_TYPE')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_balance_type">');
    FOR  lookups_rec IN xgv_common.g_tag_lookups_cur('BALANCE_TYPE', p_balance_query_rec.balance_type)
    LOOP
      htp.p(lookups_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '</td>'
      ||  '</tr>');

    -- Display budget name
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_BUDGET_NAME')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_budget_version_id">');
    FOR  l_budget_rec IN xgv_common.g_tag_budget_cur(p_balance_query_rec.budget_version_id)
    LOOP
      htp.p(l_budget_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '</td>'
      ||  '</tr>');

    -- Display balance amount of forward balance
    /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
    htp.p('<tr>'
      ||  '<th class="OraPromptText" valign="top" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_SHOW_FORWARD_AMOUNT')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td>'
      ||  '<table border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr>'
      ||  '<td class="OraDataText">'
      ||  '<input type="radio" name="p_forward_type" value="YTD"'
      ||  xgv_common.r_decode(p_balance_query_rec.forward_type, 'YTD', ' checked>', '>')
      ||  xgv_common.get_message('TEXT_YTD')
      ||  '</td>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="radio" name="p_forward_type" value="QTD"'
      ||  xgv_common.r_decode(p_balance_query_rec.forward_type, 'QTD', ' checked>', '>')
      ||  xgv_common.get_message('TEXT_QTD')
      ||  '</td>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="radio" name="p_forward_type" value="PJTD"'
      ||  xgv_common.r_decode(p_balance_query_rec.forward_type, 'PJTD', ' checked>', '>')
      ||  xgv_common.get_message('TEXT_PJTD')
      ||  '</td>'
      ||  '</tr>'
      ||  '</table>'
      ||  '</td>'
      ||  '</tr>');

    -- Display balance amount of period
    htp.p('<tr>'
      ||  '<th class="OraPromptText" valign="top" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_SHOW_BALANCE_AMOUNT')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td>'
      ||  '<table border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr>'
      ||  '<td class="OraDataText">' || xgv_common.get_message('PROMPT_BS_ACCOUNT') || '</td>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="radio" name="p_bs_balance_type" value="YTD"'
      ||  xgv_common.r_decode(p_balance_query_rec.bs_balance_type, 'YTD', ' checked>', '>')
      ||  xgv_common.get_message('TEXT_SUMTD')             /* Req#220016 05-Apr-2007 Changed by ytsujiha_jp */
      ||  '</td>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="radio" name="p_bs_balance_type" value="PTD"'
      ||  xgv_common.r_decode(p_balance_query_rec.bs_balance_type, 'PTD', ' checked>', '>')
      ||  xgv_common.get_message('TEXT_PTD')
      ||  '</td>'
      ||  '</tr>'
      ||  '<tr>'
      ||  '<td class="OraDataText">' || xgv_common.get_message('PROMPT_PL_ACCOUNT') || '</td>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="radio" name="p_pl_balance_type" value="YTD"'
      ||  xgv_common.r_decode(p_balance_query_rec.pl_balance_type, 'YTD', ' checked>', '>')
      ||  xgv_common.get_message('TEXT_SUMTD')             /* Req#220016 05-Apr-2007 Changed by ytsujiha_jp */
      ||  '</td>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="radio" name="p_pl_balance_type" value="PTD"'
      ||  xgv_common.r_decode(p_balance_query_rec.pl_balance_type, 'PTD', ' checked>', '>')
      ||  xgv_common.get_message('TEXT_PTD')
      ||  '</td>'
      ||  '</tr>'
      ||  '</table>'
      ||  '</td>'
      ||  '</tr>');

    -- Display etc
    /* 02-Apr-2007 Changed by ytsujiha_jp */
    htp.p('<tr>'
      ||  '<th class="OraPromptText" valign="top" nowrap>'
      ||  xgv_common.get_message('PROMPT_ETC_CONDITIONS')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td>'
      ||  '<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr>'
      ||  '<td>'
      ||  '<input type="checkbox" name="p_show_dr_cr" value="Y"'
      ||  xgv_common.r_decode(p_balance_query_rec.show_dr_cr, 'Y', ' checked>', '>')
      ||  '</td>'
      ||  '<td class="OraDataText">'
      ||  xgv_common.get_message('PROMPT_SHOW_DR_CR')
      ||  '</td>'
      ||  '</tr>');
    /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    htp.p('<tr>'
      ||  '<td>'
      ||  '<input type="checkbox" name="p_show_summary" value="Y"'
      ||  xgv_common.r_decode(p_balance_query_rec.show_summary, 'Y', ' checked>', '>')
      ||  '</td>'
      ||  '<td class="OraDataText">'
      ||  xgv_common.get_message('PROMPT_SHOW_SUMMARYACCOUNT')
      ||  '</td>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  xgv_common.get_message('TEXT_SUMMARYACCOUNT')
      ||  '<script>t(6, 0);</script>'
      ||  '<select name="p_summary_template_id">');
    FOR  l_summary_template_rec IN xgv_common.g_tag_summary_template_cur(p_balance_query_rec.summary_template_id)
    LOOP
      htp.p(l_summary_template_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '</td>'
      ||  '</tr>');
    /* Req#200003 09-Jul-2004 Added by ytsujiha_jp */
    htp.p('<tr>'
      ||  '<td>'
      ||  '<input type="checkbox" name="p_parent_only" value="Y"'
      ||  xgv_common.r_decode(p_balance_query_rec.parent_only, 'Y', ' checked>', '>')
      ||  '</td>'
      ||  '<td class="OraDataText">'
      ||  xgv_common.get_message('PROMPT_SHOW_PARENT_ONLY')
      ||  '</td>'
      ||  '</tr>');
    /* 02-Apr-2007 Changed by ytsujiha_jp */
    htp.p('</table>'
      ||  '</td>'
      ||  '</tr>');

    htp.p('</table>');

    --------------------------------------------------
    -- Display AFF conditions
    --------------------------------------------------
    htp.prn('<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_AFF_CONDITIONS'), p_fontsize=>'S');

    htp.p('<table style="border-collapse:collapse" cellpadding="1" cellspacing="0">');
    htp.p('<tr>'
      ||  '<th class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_SEGMENT_NAME')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_SEGMENT_CONDITION')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_SEGMENT_SHOW_ORDER')
      ||  '</th>'
      ||  '</tr>');

    -- Display each segment
    FOR  l_index IN 1..p_balance_query_rec.segment_type_tab.COUNT
    LOOP

      SELECT nvl(xfsv.parent_segment_id, 0),
             xfsv.show_lov_proc,
             hide_flag,
             mandatory_flag
      INTO   l_parent_segment_id,
             l_show_lov_proc,
             l_hide_flag,
             l_mandatory_flag
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
        AND  xfsv.segment_id = to_number(p_balance_query_rec.segment_type_tab(l_index));

      IF  l_hide_flag = 'N'
      THEN
        htp.p('<tr>');

        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.r_decode(l_mandatory_flag,
                'Y', '<img src="/XGV_IMAGE/ii-required_status.gif">', NULL)
          ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_balance_query_rec.segment_type_tab(l_index)))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_parent_value" value="'
          ||  p_balance_query_rec.segment_type_tab(l_index) || '"'
          ||  xgv_common.r_decode(p_balance_query_rec.parent_value_tab(l_index), 'Y', ' checked>', '>')
          ||  '<input type="text" name="p_condition" size="60" maxlength="1999" value="'
          ||  htf.escape_sc(p_balance_query_rec.condition_tab(l_index)) || '">'
          ||  xgv_common.r_nvl2(l_show_lov_proc,
                '<a href="javascript:requestAFF_LOV('
                ||  p_balance_query_rec.segment_type_tab(l_index) || ', ' || l_parent_segment_id || ')">'
                ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
                ||  '</a>',
                '<img src="/XGV_IMAGE/ai-search_disabled.gif" border="0">')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_show_order" size="4" maxlength="2" value="'
          ||  p_balance_query_rec.show_order_tab(l_index) || '">'
          ||  '<input type="hidden" name="p_segment_type" value="'
          ||  p_balance_query_rec.segment_type_tab(l_index) || '">'
          ||  '</td>');

        htp.p('</tr>');

      ELSE
        htp.p('<input type="hidden" name="p_condition" value="'
          ||  htf.escape_sc(p_balance_query_rec.condition_tab(l_index)) || '">'
          ||  '<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="'
          ||  p_balance_query_rec.segment_type_tab(l_index) || '">');
      END IF;

    END LOOP;

    htp.p('</table>');

    htp.p('<table border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr>'
      ||  '<td>');
    xgv_common.show_tip('TIP_SEARCH_PARENT_VALUE');
    htp.p('</td>'
      ||  '</tr>'
      ||  '</table>');

    --------------------------------------------------
    -- Display summary option
    --------------------------------------------------
    htp.prn('<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_SUMMARY_OPTIONS'), p_fontsize=>'S');

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');

    -- Display subtotal item
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_SUBTOTAL_ITEM')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_break_key">');
    FOR  l_break_key_rec IN l_tag_breakkey_cur(p_balance_query_rec.break_key)
    LOOP
      htp.p(l_break_key_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '</td>'
      ||  '</tr>');

    -- Display total
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_SHOW_TOTAL')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="checkbox" name="p_show_total" value="Y"'
      ||  xgv_common.r_decode(p_balance_query_rec.show_total, 'Y', ' checked>', '>')
      ||  '</td>'
      ||  '</tr>');

    htp.p('</table>');

    --------------------------------------------------
    -- Display result option
    --------------------------------------------------
    htp.prn('<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_RESULT_OPTIONS'), p_fontsize=>'S');

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');

    -- Display result format
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_RESULT_FORMAT')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_result_format">');
    FOR  l_tag_result_format_rec IN l_tag_result_format_cur(p_balance_query_rec.result_format)  /* 13-May-2005 Changed by ytsujiha_jp */
    LOOP
      htp.p(l_tag_result_format_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '</td>'
      ||  '</tr>');

    -- Display filename
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_RESULT_FILENAME')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="text" name="p_file_name" size="30" maxlength="255" value="'
      ||  htf.escape_sc(p_balance_query_rec.file_name)
      ||  '">'
      ||  '</td>'
      ||  '</tr>'
      ||  '<tr>'
      ||  '<td colspan="2"></td>'
      ||  '<td>');
    xgv_common.show_tip('TIP_FILENAME');
    htp.p('</td>'
      ||  '</tr>');

    -- Display drilldown template
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_DRILLDOWN_TEMPLATE')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="hidden" name="p_dd_template_id" value="'
      ||  to_char(p_balance_query_rec.dd_template_id) || '">'
      ||  '<input type="text" name="p_dd_template_name" size="30" maxlength="100" value="'
      ||  htf.escape_sc(p_balance_query_rec.dd_template_name)
      ||  '">'
      ||  '<a href="javascript:requestDdTemplate_LOV()">'
      ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
      ||  '</a>'
      ||  '</td>'
      ||  '</tr>'
      ||  '<tr>'
      ||  '<td colspan="2"></td>'
      ||  '<td>');
    xgv_common.show_tip('TIP_DRILLDOWN_TEMPLATE');
    htp.p('</td>'
      ||  '</tr>');

    htp.p('</table>');

    htp.p('</td>');
    htp.p('</tr>');
    htp.p('</table>');

    htp.p('</form>');

  END show_query_editor;

  --==========================================================
  --Procedure Name: top
  --Description: Display condition editor for Balance inquiry
  --Note:
  --Parameter(s):
  --  p_mode               : Display mode
  --                         (Editor/execute Background query/
  --                          count Rows/Save confirm/save Cnacel/
  --                          Drilldown)
  --  p_modify_flag        : Modify flag(Yes/No)
  --  p_query_id           : Query id
  --  p_async_query_id     : Background query id
  --  p_query_name         : Query name
  --  p_period_from        : Accounting periods(From)
  --  p_period_to          : Accounting periods(To)
  --  p_currency_code      : Currency
  --  p_show_entered       : Display entered currency
  --  p_show_translated    : Display translated currency
  --  p_balance_type       : Balance type
  --  p_budget_version_id  : Budget version id
  --  p_forward_type       : Display balance amount of forward balance
  --  p_bs_balance_type    : Display balance amount of B/S account
  --  p_pl_balance_type    : Display balance amount of P/L account
  --  p_show_dr_cr         : Display debit and credit
  --  p_show_summary       : Display summary accounts
  --  p_summary_template_id: Summary template id
  --  p_parent_only        : Display parent value only
  --  p_parent_value       : Display parent value
  --  p_condition          : Segment condition
  --  p_show_order         : Segment show order
  --  p_segment_type       : Segment type
  --  p_break_key          : Break key
  --  p_show_total         : Display total
  --  p_result_format      : Result format
  --  p_file_name          : Filename
  --  p_dd_template_id     : Drilldown template id
  --  p_dd_template_name   : Drilldown template name
  --  p_direct_drilldown   : Direct drilldown mode
  --                         (Drilldown is used)
  --                         Y=> Direct drilldown
  --==========================================================
  PROCEDURE top(
    p_mode                IN VARCHAR2 DEFAULT 'E',
    p_modify_flag         IN VARCHAR2 DEFAULT 'N',
    p_query_id            IN NUMBER   DEFAULT NULL,
    p_async_query_id      IN NUMBER   DEFAULT NULL,
    p_query_name          IN VARCHAR2 DEFAULT NULL,
    p_period_from         IN NUMBER   DEFAULT NULL,
    p_period_to           IN NUMBER   DEFAULT NULL,
    p_currency_code       IN VARCHAR2 DEFAULT NULL,
    p_show_entered        IN VARCHAR2 DEFAULT 'N',
    p_show_translated     IN VARCHAR2 DEFAULT 'N',
    p_balance_type        IN VARCHAR2 DEFAULT NULL,
    p_budget_version_id   IN NUMBER   DEFAULT NULL,
    p_forward_type        IN VARCHAR2 DEFAULT NULL,        /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
    p_bs_balance_type     IN VARCHAR2 DEFAULT NULL,
    p_pl_balance_type     IN VARCHAR2 DEFAULT NULL,
    p_show_dr_cr          IN VARCHAR2 DEFAULT 'N',
    p_show_summary        IN VARCHAR2 DEFAULT 'N',
    p_summary_template_id IN NUMBER   DEFAULT NULL,        /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    p_parent_only         IN VARCHAR2 DEFAULT 'N',
    p_parent_value        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_condition           IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_show_order          IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_break_key           IN VARCHAR2 DEFAULT NULL,
    p_show_total          IN VARCHAR2 DEFAULT 'N',
    p_result_format       IN VARCHAR2 DEFAULT NULL,
    p_file_name           IN VARCHAR2 DEFAULT NULL,
    p_dd_template_id      IN NUMBER   DEFAULT NULL,
    p_dd_template_name    IN VARCHAR2 DEFAULT NULL,
    p_direct_drilldown    IN VARCHAR2 DEFAULT 'N')
  IS

    l_balance_query_rec  xgv_common.balance_query_rtype;
    l_drilldown_error  BOOLEAN := FALSE;       /* Bug#220019 01-Feb-2007 Changed by ytsujiha_jp */
    l_dummy1  NUMBER;
    l_dummy2  NUMBER;

    CURSOR l_mandatory_flag_cur
    IS
      SELECT xfsv.mandatory_flag mandatory_flag
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
        AND  xfsv.flexfield_name = 'GL#'
      ORDER BY xfsv.segment_id;

    /* Bug#230005 08-May-2007 Added by ytsujiha_jp */
    /* Bug#230006 08-May-2007 Added by ytsujiha_jp */
    FUNCTION check_parent_value(
      p_segment_id        IN NUMBER,
      p_parent_flex_value IN VARCHAR2)
    RETURN VARCHAR2
    IS

      l_summary_flag  fnd_flex_values.summary_flag%TYPE;

    BEGIN

      SELECT DISTINCT ffv.summary_flag                      /* Bug#230019 06-Sep-2007 Changed by ytsujiha_jp */
      INTO   l_summary_flag
      FROM   xgv_flex_structures_vl xfsv,
             fnd_flex_values ffv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.segment_id = p_segment_id
        AND  ffv.flex_value_set_id = xfsv.flex_value_set_id
        AND  ffv.flex_value = p_parent_flex_value
        AND  ffv.enabled_flag = 'Y';                        /* Bug#230019 06-Sep-2007 Changed by ytsujiha_jp */

      RETURN l_summary_flag;

    END check_parent_value;

    PROCEDURE add_child_value(
      p_condition              IN OUT VARCHAR2,
      p_segment_id             IN     NUMBER,
      p_parent_flex_value_low  IN     VARCHAR2,
      p_parent_flex_value_high IN     VARCHAR2)
    IS

      CURSOR l_hierarchy_value_cur
      IS
        SELECT ffvnh.range_attribute range_attribute,
               ffvnh.child_flex_value_low flex_value_low,
               ffvnh.child_flex_value_high flex_value_high
        FROM   xgv_flex_structures_vl xfsv,
               fnd_flex_value_norm_hierarchy ffvnh
        WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
          AND  xfsv.segment_id = p_segment_id
          AND  ffvnh.flex_value_set_id = xfsv.flex_value_set_id
          AND  ffvnh.parent_flex_value BETWEEN p_parent_flex_value_low
                                           AND p_parent_flex_value_high;

    BEGIN

      FOR  l_hierarchy_value_rec IN l_hierarchy_value_cur
      LOOP
        IF  l_hierarchy_value_rec.range_attribute = 'P'
        THEN
          add_child_value(
            p_condition, p_segment_id,
            l_hierarchy_value_rec.flex_value_low,
            l_hierarchy_value_rec.flex_value_high);
        ELSE
          IF  p_condition IS NOT NULL
          THEN
            p_condition := p_condition || ',';
          END IF;
          IF  l_hierarchy_value_rec.flex_value_low = l_hierarchy_value_rec.flex_value_high
          THEN
            /* Bug#220014 12-Nov-2006 Changed by ytsujiha_jp */
            /* Bug#220021 26-Feb-2007 Changed(Delete) by ytsujiha_jp */
            p_condition := p_condition || l_hierarchy_value_rec.flex_value_low;
          ELSE
            /* Bug#220014 12-Nov-2006 Changed by ytsujiha_jp */
            /* Bug#220021 26-Feb-2007 Changed(Delete) by ytsujiha_jp */
            p_condition := p_condition
              || l_hierarchy_value_rec.flex_value_low || '-' || l_hierarchy_value_rec.flex_value_high;
          END IF;
        END IF;
      END LOOP;

    END add_child_value;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('BQ.TOP');

    /* 11-Aug-2004 Added by ytsujiha_jp */
    DECLARE
      l_cookie  owa_cookie.cookie;
    BEGIN
      /* Bug#211005 15-Sep-2005 Changed by ytsujiha_jp */
      l_cookie := owa_cookie.get('XGV_SESSION');
      IF  l_cookie.num_vals != 1
      THEN
        raise_application_error(-20025, xgv_common.get_message('XGV-20025'));
      END IF;
      IF  xgv_common.split(l_cookie.vals(1), ',', 1, 5) != xgv_common.GLWI  /* Req#230009 30-Jul-2007 Changed by ytsujiha_jp */
      THEN
        owa_util.mime_header('text/html', FALSE);
        owa_cookie.send('XGV_SESSION',
          xgv_common.split(l_cookie.vals(1), ',', 1, 1) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 2) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 3) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 4) || ','
          || xgv_common.GLWI || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 6));  /* Req#230009 30-Jul-2007 Changed by ytsujiha_jp */
        owa_util.http_header_close;

        htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
        htp.p('<html dir="ltr">');
        htp.p('<body>');
        htp.p('<form name="f_refresh" method="post" action="./xgv_bq.top"></form>');
        htp.p('<script language="JavaScript">');
        htp.p('<!--');
        htp.p('document.f_refresh.submit();');
        htp.p('// -->');
        htp.p('</script>');
        htp.p('</body>');
        htp.p('</html>');

        RETURN;
      END IF;
    END;

    -- Display editor or count rows?
    IF  p_mode IN ('E', 'S')
    THEN
      set_query_condition(l_balance_query_rec, p_query_id);

    ELSIF  p_mode = 'R'
    THEN
      -- Count rows
      xgv_common.open_output_dest('W');
      xgv_be.execute_sql(
        p_query_id, p_query_name, p_period_from, p_period_to, p_currency_code,
        'Y', 'N', p_balance_type, p_budget_version_id,
        p_forward_type, p_bs_balance_type, p_pl_balance_type, 'N',             /* Req#220016 05-Apr-2007 Changed by ytsujiha_jp */
        p_show_summary, p_summary_template_id, p_parent_only,                  /* Req#220020 30-Mar-2007 Changed by ytsujiha_jp */
        p_parent_value, p_condition, p_show_order, p_segment_type, NULL,
        'N', 'COUNT', NULL, NULL, NULL, l_dummy1, l_dummy2);

      -- Set query condition
      set_query_condition_local(
        l_balance_query_rec, p_query_id, p_period_from, p_period_to, p_currency_code,
        p_show_entered, p_show_translated, p_balance_type, p_budget_version_id,
        p_forward_type, p_bs_balance_type, p_pl_balance_type, p_show_dr_cr,    /* Req#220016 05-Apr-2007 Changed by ytsujiha_jp */
        p_show_summary, p_summary_template_id, p_parent_only,                  /* Req#220020 30-Mar-2007 Changed by ytsujiha_jp */
        p_parent_value, p_condition, p_show_order, p_segment_type,
        p_break_key, p_show_total, p_result_format, p_file_name, p_dd_template_id, NULL);

    -- Drilldown
    ELSIF  p_mode = 'D'
    THEN
      set_query_condition_local(
        l_balance_query_rec, p_query_id, p_period_from, p_period_to, p_currency_code,
        p_show_entered, p_show_translated, p_balance_type, p_budget_version_id,
        p_forward_type, p_bs_balance_type, p_pl_balance_type, p_show_dr_cr,    /* Req#220016 05-Apr-2007 Changed by ytsujiha_jp */
        'N', NULL, 'N',                                                        /* Req#220020 30-Mar-2007 Changed by ytsujiha_jp */
        xgv_common.array_tab, p_condition, p_show_order, p_segment_type,
        p_break_key, p_show_total, p_result_format, p_file_name, p_dd_template_id, NULL);

      /* Req#220017 28-Mar-2007 Changed by ytsujiha_jp */
      /* 09-May-2007 Changed(Combined the logic, because logic was the same) by ytsujiha_jp*/
      /* Bug#230006 09-May-2007 Changed(Chaned the loop logic) by ytsujiha_jp */
      -- Drilldown from parent value or summary account
      FOR  l_index IN 1..p_segment_type.COUNT
      LOOP

        IF  p_show_order(to_number(p_segment_type(l_index))) IS NOT NULL
        THEN

          l_balance_query_rec.condition_tab(to_number(p_segment_type(l_index))) := NULL;

          /* Bug#230005 08-May-2007 Changed by ytsujiha_jp */
          /* Bug#230006 08-May-2007 Changed by ytsujiha_jp */
          IF  check_parent_value(
                to_number(p_segment_type(l_index)),
                p_condition(to_number(p_segment_type(l_index)))) = 'Y'
          THEN

            /* Bug#220019 01-Feb-2007 Changed by ytsujiha_jp */
            BEGIN
              add_child_value(
                l_balance_query_rec.condition_tab(to_number(p_segment_type(l_index))),
                to_number(p_segment_type(l_index)),
                p_condition(to_number(p_segment_type(l_index))),
                p_condition(to_number(p_segment_type(l_index))));
            -- Exception
            EXCEPTION
              WHEN  OTHERS
              THEN
                l_drilldown_error := TRUE;
            END;

          ELSE
            l_balance_query_rec.condition_tab(to_number(p_segment_type(l_index))) :=
              p_condition(to_number(p_segment_type(l_index)));
          END IF;

        END IF;

      END LOOP;

    ELSE
      set_query_condition_local(
        l_balance_query_rec, p_query_id, p_period_from, p_period_to, p_currency_code,
        p_show_entered, p_show_translated, p_balance_type, p_budget_version_id,
        p_forward_type, p_bs_balance_type, p_pl_balance_type, p_show_dr_cr,    /* Req#220016 05-Apr-2007 Changed by ytsujiha_jp */
        p_show_summary, p_summary_template_id, p_parent_only,                  /* Req#220020 30-Mar-2007 Changed by ytsujiha_jp */
        p_parent_value, p_condition, p_show_order, p_segment_type,
        p_break_key, p_show_total, p_result_format, p_file_name, p_dd_template_id, NULL);
    END IF;

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_BQ.js"></script>');
    htp.p('<script language="JavaScript">');
    htp.p('<!--');
    htp.p('window.name = "xgv_main";');
    htp.p('function parent_value_disabled()');
    htp.p('{');
    FOR  l_index IN 1..xgv_common.get_num_aff_segs
    LOOP
      IF  xgv_common.get_enable_search_parent_value = 'N'
      OR  NOT xgv_common.get_flexfield_validation_type(l_index) IN ('I', 'D')
      THEN
        htp.p('  document.f_query.p_parent_value[' || to_char(l_index - 1) || '].disabled=true;');
      END IF;
    END LOOP;
    htp.p('}');
    htp.p('// -->');
    htp.p('</script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_BALANCE_INQUIRY', xgv_common.get_resp_name) || '</title>');
    htp.p('</head>');

    -- No direct drilldown
    /* Bug#220019 01-Feb-2007 Changed by ytsujiha_jp */
    IF  p_direct_drilldown = 'N'
    OR  l_drilldown_error = TRUE
    THEN
      htp.p('<body class="OraBody" onLoad="window.focus(); document.f_query.p_dd_template_name.disabled=true; parent_value_disabled();">');
    ELSE
      /* Req#230010 12-Dec-2007 Changed by ytsujiha_jp */
      htp.p('<body class="OraBody" onLoad="document.f_query.p_dd_template_name.disabled=true; parent_value_disabled(); javascript:requestExecute('''
        ||  xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'), 'N', 'S', 'A')
        ||  ''');">');
    END IF;

    -- Display Header
    xgv_common.show_header(
      xgv_common.get_global_buttons_tag('MAIN'),
      xgv_common.get_tabs_tag('BQ'));

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr style="vertical-align: top">');

    -- Display side navigator
    htp.p('<td>');
    show_side_navigator('EDITOR');
    htp.p('</td>');

    -- Display condition editor for query condition
    htp.p('<td width="100%">');

    -- Display execute background query
    IF  p_mode = 'B'
    THEN
      DECLARE
        l_request_id  fnd_concurrent_requests.request_id%TYPE;
      BEGIN
        SELECT request_id
        INTO   l_request_id
        FROM   xgv_async_queries
        WHERE  query_id = p_async_query_id;
        htp.prn('<script>t(1, 7);</script>');
        xgv_common.show_messagebox('C', 'MESSAGE_SUBMIT_ASYNCQUERY', l_request_id);
      EXCEPTION
        WHEN  NO_DATA_FOUND
        THEN
          NULL;
      END;

    -- Display Count Rows
    ELSIF  p_mode = 'R'
    THEN
      htp.prn('<script>t(1, 7);</script>');
      xgv_common.show_messagebox('C',
        'MESSAGE_COUNT_ROWS', ltrim(to_char(l_balance_query_rec.result_rows, '999G999G999G990')));

    -- Display svae confirmation message
    ELSIF  p_mode = 'S'
    THEN
      htp.prn('<script>t(1, 7);</script>');
      xgv_common.show_messagebox('C', 'MESSAGE_SAVE_CONDITION');

    -- Display drilldown error message
    /* Bug#220019 01-Feb-2007 Changed by ytsujiha_jp */
    ELSIF  l_drilldown_error = TRUE
    THEN
      htp.prn('<script>t(1, 7);</script>');
      xgv_common.show_messagebox('W', 'ERROR_PARENT_DRILLDOWN');
    END IF;

    -- Display title
    htp.prn('<script>t(1, 7);</script>');
    xgv_common.show_title(
      xgv_common.get_message('TITLE_BALANCE_INQUIRY', xgv_common.get_resp_name),
      NULL,
      xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'),
        'N', '<a href="javascript:requestExecute(''S'');">'
             || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-sync_enabled.gif" border="0">'
             || '</a>'
             || '<script>t(8, 1);</script>', NULL)          /* Req#230010 12-Dec-2007 Changed by ytsujiha_jp */
      || '<a href="javascript:requestExecute(''A'');">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-async_enabled.gif" border="0">'
      || '</a>'
      || xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'),
           'N', '<script>t(8, 1);</script>'
                || '<a href="javascript:requestCountRows();">'
                || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-countrows_enabled.gif" border="0">'
                || '</a>', NULL));                          /* Req#230010 12-Dec-2007 Changed by ytsujiha_jp */

    /* Bug#200022 16-Jun-2004 Changed by ytsujiha_jp */
    show_query_editor(p_modify_flag, l_balance_query_rec);

    htp.p('</td>');

    htp.p('</tr>');
    htp.p('</table>');

    -- Display footer
    xgv_common.show_footer(
      xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'),
        'N', '<a href="javascript:requestExecute(''S'');">'
             || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-sync_enabled.gif" border="0">'
             || '</a>'
             || '<script>t(8, 1);</script>', NULL)          /* Req#230010 12-Dec-2007 Changed by ytsujiha_jp */
      || '<a href="javascript:requestExecute(''A'');">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-async_enabled.gif" border="0">'
      || '</a>'
      || xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'),
           'N', '<script>t(8, 1);</script>'
                || '<a href="javascript:requestCountRows();">'
                || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-countrows_enabled.gif" border="0">'
                || '</a>', NULL));                          /* Req#230010 12-Dec-2007 Changed by ytsujiha_jp */

    htp.p('<form name="f_mandatory_flag">');
    FOR  l_mandatory_flag_rec IN l_mandatory_flag_cur
    LOOP
    htp.p('<input type="hidden" name="p_mandatory_flag" value="'
      ||  l_mandatory_flag_rec.mandatory_flag
      ||  '">');
    END LOOP;
    htp.p('</form>');

    htp.p('<form name="f_lov_aff" method="post" action="./xgv_bq.show_lov_aff" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_child_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_condition" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_drilldown_tmp" method="post" action="./xgv_bq.show_lov_drilldown_tmp" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_goto" method="post" action=""></form>');

    htp.p('</body>');

    htp.p('</html>');

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  xgv_user_auth.e_invalid_session
    THEN
      xgv_user_auth.show_session_error;

    WHEN  OTHERS
    THEN
      xgv_common.show_error_page(SQLERRM);

  END top;

  --==========================================================
  --Procedure Name: show_lov_aff
  --Description: Display LOV for AFF
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list(Segment condition)
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --  p_child_segment_id : Segment id
  --  p_parent_segment_id: Parent segment id
  --  p_parent_condition : Parent segment condition
  --==========================================================
  PROCEDURE show_lov_aff(
    p_list_filter_item  IN VARCHAR2 DEFAULT 'VALUE',
    p_list_filter_value IN VARCHAR2 DEFAULT NULL,
    p_start_listno      IN NUMBER   DEFAULT 1,
    p_sort_item         IN VARCHAR2 DEFAULT 'VALUE',
    p_sort_method       IN VARCHAR2 DEFAULT 'ASC',
    p_child_segment_id  IN NUMBER,
    p_parent_segment_id IN NUMBER   DEFAULT NULL,
    p_parent_condition  IN VARCHAR2 DEFAULT NULL)
  IS

    l_proc_name  xgv_flex_structures_vl.show_lov_proc%TYPE;
    l_count_sql  VARCHAR2(32767);
    l_list_sql  VARCHAR2(32767);

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('BQ.SHOW_LOV_AFF');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_BQ.js"></script>');
    htp.p('<title>'
      ||  xgv_common.get_message('TITLE_LOV_AFF_DFF', xgv_common.get_segment_name(p_child_segment_id))
      ||  '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_condition['
      ||  to_char(p_child_segment_id - 1) || '].value">');

    SELECT xfsv.show_lov_proc
    INTO   l_proc_name
    FROM   xgv_flex_structures_vl xfsv
    WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
      AND  xfsv.segment_id = p_child_segment_id;

    IF  l_proc_name IS NULL
    THEN
      raise_application_error(-20013,
        xgv_common.get_message('XGV-20013', xgv_common.get_sob_id, p_child_segment_id));
    END IF;

    EXECUTE IMMEDIATE
      'BEGIN ' || l_proc_name ||'(:ph1, :ph2, :ph3, :ph4, :ph5, :ph6, :ph7, :ph8); END;'
    USING 'COUNT', IN OUT l_count_sql, p_list_filter_item, p_sort_item, p_sort_method,
      p_child_segment_id, p_list_filter_value, p_parent_condition;

    EXECUTE IMMEDIATE
      'BEGIN ' || l_proc_name ||'(:ph1, :ph2, :ph3, :ph4, :ph5, :ph6, :ph7, :ph8); END;'
    USING 'LIST', IN OUT l_list_sql, p_list_filter_item, p_sort_item, p_sort_method,
      p_child_segment_id, p_list_filter_value, p_parent_condition;

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_AFF_DFF', xgv_common.get_segment_name(p_child_segment_id),
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_bq.show_lov_aff',
        '<input type="hidden" name="p_child_segment_id" value="' || p_child_segment_id || '">'
        || '<input type="hidden" name="p_parent_segment_id" value="' || p_parent_segment_id || '">'
        || '<input type="hidden" name="p_parent_condition" value="' || htf.escape_sc(p_parent_condition) || '">',
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addFlexValue(' || to_char(p_child_segment_id) || ');',
      p_used_parent_value=>TRUE);

    htp.p('</body>');

    htp.p('</html>');

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  xgv_user_auth.e_invalid_session
    THEN
      xgv_user_auth.show_session_error;

    WHEN  OTHERS
    THEN
      xgv_common.show_error_page(SQLERRM);

  END show_lov_aff;

  --==========================================================
  --Procedure Name: show_lov_drilldown_tmp
  --Description: Display LOV for drilldown template
  --Note:
  --Parameter(s):
  --  p_list_filter_value  : Filter string for list
  --  p_list_filter_opttion: Filter option for list
  --  p_start_listno       : Start list no
  --  p_sort_item          : Sort item
  --  p_sort_method        : Sort method(Asc/Desc)
  --==========================================================
  PROCEDURE show_lov_drilldown_tmp(
    p_list_filter_value   IN VARCHAR2 DEFAULT NULL,
    p_list_filter_opttion IN VARCHAR2 DEFAULT 'AIS',
    p_start_listno        IN NUMBER   DEFAULT 1,
    p_sort_item           IN VARCHAR2 DEFAULT 'UPDATE',
    p_sort_method         IN VARCHAR2 DEFAULT 'DESC')
  IS

    type  l_cursor_ctype is REF CURSOR;

    l_list_cur  l_cursor_ctype;
    l_where_str  VARCHAR2(32767);
    l_order_str  VARCHAR2(255);
    l_query_id  xgv_queries.query_id%TYPE;
    l_query_name  xgv_queries.query_name%TYPE;
    l_description xgv_queries.description%TYPE;
    l_created_by  xgv_queries.created_by%TYPE;
    l_creation_date  xgv_queries.creation_date%TYPE;
    l_lastupdate_by  xgv_queries.last_updated_by%TYPE;
    l_lastupdate_date  xgv_queries.last_update_date%TYPE;

    l_total_listno  NUMBER := 0;
    l_start_listno  NUMBER;
    l_prev_listno  NUMBER;
    l_next_listno  NUMBER;
    l_lineperpage  NUMBER;
    l_show_data_flag  BOOLEAN := FALSE;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('BQ.SHOW_LOV_DRILLDOWN_TMP');

    l_where_str := ' WHERE xq.inquiry_type = ''J'''
      || ' AND xq.set_of_books_id = xgv_common.get_sob_id'
      || ' AND ((xq.application_id IS NULL'
      || ' AND xq.responsibility_id IS NULL'
      || ' AND xq.user_id IS NULL)'
      || ' OR (xq.application_id = xgv_common.get_resp_appl_id'
      || ' AND xq.responsibility_id = xgv_common.get_resp_id)'
      || ' OR xq.user_id = xgv_common.get_user_id)';
    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_opttion = 'AIS'
      THEN
        l_where_str := l_where_str || ' AND upper(xq.query_name) = ''' || upper(p_list_filter_value) || '''';
      ELSIF  p_list_filter_opttion = 'CCONTAIN'
      THEN
        l_where_str := l_where_str || ' AND upper(xq.query_name) LIKE ''%' || upper(p_list_filter_value) || '%''';
      ELSIF  p_list_filter_opttion = 'DSTART'
      THEN
        l_where_str := l_where_str || ' AND upper(xq.query_name) LIKE ''' || upper(p_list_filter_value) || '%''';
      ELSIF  p_list_filter_opttion = 'EEND'
      THEN
        l_where_str := l_where_str || ' AND upper(xq.query_name) LIKE ''%' || upper(p_list_filter_value) || '''';
      END IF;
    END IF;
    l_order_str := xgv_common.r_decode(p_sort_item, 'NAME', ' ORDER BY xq.query_name ',
      xgv_common.r_decode(p_sort_item, 'UPDATE', ' ORDER BY xq.last_update_date ', NULL))
      || p_sort_method;

    -- Count rows
    EXECUTE IMMEDIATE 'SELECT count(xq.query_id) + 1 FROM xgv_queries xq' || l_where_str
    INTO l_total_listno;

    -- Open cursor
    OPEN l_list_cur
    FOR  'SELECT to_number(NULL), xgv_common.get_message(''TEXT_NO_TEMPLATE'', NULL, NULL, NULL, NULL, NULL, ''N''),'
         || ' xgv_common.get_message(''NOTE_NO_TEMPLATE'', NULL, NULL, NULL, NULL, NULL, ''N''),'
         || ' to_number(NULL), to_date(NULL), to_number(NULL), to_date(NULL)'
         || ' FROM dual'
         || ' UNION ALL'
         || ' SELECT xq.query_id, xq.query_name, xq.description,'
         || ' xq.created_by, xq.creation_date, xq.last_updated_by, xq.last_update_date'
         || ' FROM (SELECT xq.query_id, xq.query_name, xq.description,'
         || ' xq.created_by, xq.creation_date, xq.last_updated_by, xq.last_update_date'
         || ' FROM xgv_queries xq'
         || l_where_str
         || l_order_str
         || ') xq';

    -- Set previous lineno and next lineno
    l_lineperpage := xgv_common.get_lov_line_per_page;
    l_start_listno := p_start_listno - mod(p_start_listno, l_lineperpage) + 1;
    IF  l_start_listno <= 1
    THEN
      l_start_listno := 1;
      l_prev_listno := NULL;
    ELSE
      l_prev_listno := l_start_listno - l_lineperpage;
    END IF;
    l_next_listno := l_start_listno + l_lineperpage;
    IF  l_start_listno >= l_total_listno
    THEN
      l_start_listno := l_total_listno;
      l_next_listno := NULL;
    ELSIF  l_total_listno < l_next_listno
    THEN
      l_next_listno := NULL;
    END IF;

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_BQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_DRILLDOWN_TEMPLATE') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();">');

    -- Display title
    htp.prn('<script>t(1, 7);</script>');
    xgv_common.show_title(
      xgv_common.get_message('TITLE_LOV_DRILLDOWN_TEMPLATE'),
      NULL,
      '<a href="javascript:window.close();">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-cancel_enabled.gif" border="0">'
      || '</a>');

    htp.prn('<script>t(1, 10);</script>');
    htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">');

    htp.p('<tr>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td width="100%">');

    xgv_common.show_title(
      xgv_common.get_message('TITLE_FILTER_SEARCH'),
      xgv_common.get_message('NOTE_FILTER_SEARCH'),
      p_fontsize=>'M');

    htp.p('<form name="f_filterList" method="post" action="./xgv_bq.show_lov_drilldown_tmp">');
    htp.p('<input type="hidden" name="p_start_listno" value="1">');
    htp.p('<input type="hidden" name="p_sort_item" value="' || p_sort_item || '">');
    htp.p('<input type="hidden" name="p_sort_method" value="' || p_sort_method || '">');

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');

    htp.p('<tr>'
      ||  '<th class="OraPromptText">'
      ||  xgv_common.get_message('PROMPT_CONDITION_NAME')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_list_filter_opttion">');
    FOR  lookups_rec IN xgv_common.g_tag_lookups_cur('FILTER_OPTION', p_list_filter_opttion)
    LOOP
      htp.p(lookups_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '<input type="text" name="p_list_filter_value" size="30" maxlength="100" value="'
      ||  htf.escape_sc(p_list_filter_value) || '">'
      ||  '</td>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<th></th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<a href="javascript:document.f_filterList.submit();">'
      ||  '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-find_enabled.gif" border="0">'
      ||  '</a>'
      ||  '<script>t(12, 0);</script>'
      ||  '<a href="javascript:clearFilter();">'
      ||  '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-clear_enabled.gif" border="0">'
      ||  '</a>'
      ||  '</td>'
      ||  '</tr>');
    htp.p('</table>');

    htp.p('</form>');

    htp.p('<form name="f_select">');

    xgv_common.show_title(xgv_common.get_message('TITLE_FILTER_RESULTS'), p_fontsize=>'M');

    htp.p('<table style="border-collapse:collapse" cellpadding="1" cellspacing="0">');
    htp.p('<tr>'
      ||  '<th class="OraTableColumnHeader" colspan="7" nowrap>'
      ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr>'
      ||  '<th class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('TEXT_SELECT_OBJECT_AND')
      ||  '</th>'
      ||  '<th class="OraTableColumnHeaderNumber" nowrap>'
      ||  '<a href="javascript:selectDdTemplate();">'
      ||  '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-select_enabled.gif" border="0">'
      ||  '</a>'
      ||  '<script>t(12, 0);</script>'
      ||  '</th>'
      ||  '</tr>'
      ||  '</table>'
      ||  '</th>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<td style="border:1px solid #cccc99" colspan="7" align="right" nowrap>'
      ||  '<table border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr valign="top">'
      ||  xgv_common.r_nvl2(l_prev_listno,
            '<td>'
            || '<a href="javascript:requestPrevNextList(' || l_prev_listno || ')">'
            || '<img src="/XGV_IMAGE/li-previous_enabled.gif" border="0">'
            || '</a>'
            || '</td>'
            || '<td class="OraRecordNavText">'
            || '<a href="javascript:requestPrevNextList(' || l_prev_listno || ')">'
            || xgv_common.get_message('TEXT_PREVIOUS', to_char(l_lineperpage))
            || '</a>'
            || '</td>',
            '<td>'
            || '<img src="/XGV_IMAGE/li-previous_disabled.gif" border="0">'
            || '</td>'
            || '<td class="OraRecordNavText">'
            || xgv_common.get_message('TEXT_PREVIOUS', to_char(l_lineperpage))
            || '</td>')
      ||  '<td>'
      ||  xgv_common.r_decode(l_total_listno,
            0, '<script>t(12, 0);</script>',
            '<script>t(12, 0);</script>'
            || xgv_common.get_message('TEXT_SHOWCOUNT_PER_TOTALCOUNT',
                 l_start_listno, nvl(l_next_listno - 1, l_total_listno), l_total_listno)
            || '<script>t(12, 0);</script>')
      ||  '</td>'
      ||  xgv_common.r_nvl2(l_next_listno,
            '<td class="OraRecordNavText">'
            || '<a href="javascript:requestPrevNextList(' || l_next_listno || ')">'
            || xgv_common.get_message('TEXT_NEXT', to_char(l_lineperpage))
            || '</a>'
            || '</td>'
            || '<td>'
            || '<a href="javascript:requestPrevNextList(' || l_next_listno || ')">'
            || '<img src="/XGV_IMAGE/li-next_enabled.gif" border="0">'
            || '</a>'
            || '</td>',
            '<td class="OraRecordNavText">'
            || xgv_common.get_message('TEXT_NEXT', to_char(l_lineperpage))
            || '</td>'
            || '<td>'
            || '<img src="/XGV_IMAGE/li-next_disabled.gif" border="0">'
            || '</td>')
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '</tr>'
      ||  '</table>'
      ||  '</td>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<th class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_SELECT')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" width="30%" nowrap>'
      ||  xgv_common.get_message('PROMPT_CONDITION_NAME')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" width="70%" nowrap>'
      ||  xgv_common.get_message('PROMPT_SAVE_DESCRIPTION')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_CREATED_BY')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_CREATION_DATE')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_LAST_UPDATED_BY')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_LAST_UPDATE_DATE')
      ||  '</th>'
      ||  '</tr>');

    -- Dummy item
    htp.p('<input type="hidden" name="p_query_id" value="">'
      ||  '<input type="hidden" name="p_query_name" value="">');

    LOOP
      FETCH l_list_cur
      INTO  l_query_id, l_query_name, l_description,
            l_created_by, l_creation_date, l_lastupdate_by, l_lastupdate_date;
      EXIT WHEN l_list_cur%NOTFOUND
             OR l_list_cur%ROWCOUNT >= l_next_listno;

      IF  l_start_listno <= l_list_cur%ROWCOUNT
      THEN

        htp.p('<tr>');

        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellSelect" nowrap>'
          ||  '<input type="radio" name="p_query_id" value="' || to_char(l_query_id) || '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="hidden" name="p_query_name" value="'
          ||  xgv_common.r_nvl2(l_query_id, htf.escape_sc(l_query_name), NULL) || '">'
          ||  xgv_common.escape_sc(l_query_name)
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText">'
          ||  xgv_common.escape_sc(l_description)
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.r_nvl2(
                l_created_by, xgv_common.escape_sc(xgv_common.get_user_name(l_created_by)), NULL)
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  l_creation_date
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.r_nvl2(
                l_created_by, xgv_common.escape_sc(xgv_common.get_user_name(l_lastupdate_by)), NULL)
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  l_lastupdate_date
          ||  '</td>');

        htp.p('</tr>');

        l_show_data_flag := TRUE;

      END IF;

    END LOOP;

    -- No data exists.
    IF  l_show_data_flag = FALSE
    THEN
      htp.p('<tr>');
      htp.p('<td style="border:1px solid #cccc99" class="OraTableCellSelect" nowrap>&nbsp;</td>');
      htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
        ||  xgv_common.get_message('TEXT_NO_CONDITION_EXIST')
        ||  '</td>');
      htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>&nbsp;</td>');
      htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>&nbsp;</td>');
      htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>&nbsp;</td>');
      htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>&nbsp;</td>');
      htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>&nbsp;</td>');
      htp.p('</tr>');
    END IF;

    htp.p('<tr>'
      ||  '<td style="border:1px solid #cccc99" colspan="7" align="right" nowrap>'
      ||  '<table border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr valign="top">'
      ||  xgv_common.r_nvl2(l_prev_listno,
            '<td>'
            || '<a href="javascript:requestPrevNextList(' || l_prev_listno || ')">'
            || '<img src="/XGV_IMAGE/li-previous_enabled.gif" border="0">'
            || '</a>'
            || '</td>'
            || '<td class="OraRecordNavText">'
            || '<a href="javascript:requestPrevNextList(' || l_prev_listno || ')">'
            || xgv_common.get_message('TEXT_PREVIOUS', to_char(l_lineperpage))
            || '</a>'
            || '</td>',
            '<td>'
            || '<img src="/XGV_IMAGE/li-previous_disabled.gif" border="0">'
            || '</td>'
            || '<td class="OraRecordNavText">'
            || xgv_common.get_message('TEXT_PREVIOUS', to_char(l_lineperpage))
            || '</td>')
      ||  '<td>'
      ||  xgv_common.r_decode(l_total_listno,
            0, '<script>t(12, 0);</script>',
            '<script>t(12, 0);</script>'
            || xgv_common.get_message('TEXT_SHOWCOUNT_PER_TOTALCOUNT',
                 l_start_listno, nvl(l_next_listno - 1, l_total_listno), l_total_listno)
            || '<script>t(12, 0);</script>')
      ||  '</td>'
      ||  xgv_common.r_nvl2(l_next_listno,
            '<td class="OraRecordNavText">'
            || '<a href="javascript:requestPrevNextList(' || l_next_listno || ')">'
            || xgv_common.get_message('TEXT_NEXT', to_char(l_lineperpage))
            || '</a>'
            || '</td>'
            || '<td>'
            || '<a href="javascript:requestPrevNextList(' || l_next_listno || ')">'
            || '<img src="/XGV_IMAGE/li-next_enabled.gif" border="0">'
            || '</a>'
            || '</td>',
            '<td class="OraRecordNavText">'
            || xgv_common.get_message('TEXT_NEXT', to_char(l_lineperpage))
            || '</td>'
            || '<td>'
            || '<img src="/XGV_IMAGE/li-next_disabled.gif" border="0">'
            || '</td>')
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '</tr>'
      ||  '</table>'
      ||  '</td>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<th class="OraTableColumnHeader" colspan="7" nowrap>'
      ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr>'
      ||  '<th class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('TEXT_SELECT_OBJECT_AND')
      ||  '</th>'
      ||  '<th class="OraTableColumnHeaderNumber" nowrap>'
      ||  '<a href="javascript:selectDdTemplate();">'
      ||  '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-select_enabled.gif" border="0">'
      ||  '</a>'
      ||  '<script>t(12, 0);</script>'
      ||  '</th>'
      ||  '</tr>'
      ||  '</table>'
      ||  '</th>'
      ||  '</tr>');

    htp.p('</table>');

    htp.p('</form>');

    htp.p('</td>');
    htp.p('</tr>');

    htp.p('</table>');

    htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr>'
      ||  '<td><script>t(1, 10);</script></td>'
      ||  '</tr>'
      ||  '<tr>'
      ||  '<td class="OraBGAccentDark" width="100%"><script>t(1, 1);</script></td>'
      ||  '</tr>'
      ||  '<tr>'
      ||  '<td><script>t(1, 2);</script></td>'
      ||  '</tr>'
      ||  '<tr>'
      ||  '<td align="right">'
      ||  '<a href="javascript:window.close();">'
      ||  '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-cancel_enabled.gif" border="0">'
      ||  '</a>'
      ||  '</td>'
      ||  '</tr>'
      ||  '</table>');

    htp.p('<form name="f_List" method="post" action="./xgv_bq.show_lov_drilldown_tmp">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="' || htf.escape_sc(p_list_filter_value) || '">');
    htp.p('<input type="hidden" name="p_list_filter_opttion" value="' || p_list_filter_opttion || '">');
    htp.p('<input type="hidden" name="p_start_listno" value="">');
    htp.p('<input type="hidden" name="p_sort_item" value="' || p_sort_item || '">');
    htp.p('<input type="hidden" name="p_sort_method" value="' || p_sort_method || '">');
    htp.p('</form>');

    htp.p('</body>');

    htp.p('</html>');

    CLOSE l_list_cur;

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  xgv_user_auth.e_invalid_session
    THEN
      xgv_user_auth.show_session_error;

    WHEN  OTHERS
    THEN
      xgv_common.show_error_page(SQLERRM);

  END show_lov_drilldown_tmp;

  --==========================================================
  --Procedure Name: request_async_exec
  --Description: Request background query
  --Note:
  --Parameter(s):
  --  p_mode               : Display mode(Not use)
  --  p_modify_flag        : Modify flag(Yes/No)
  --  p_query_id           : Query id
  --  p_query_name         : Query name
  --  p_period_from        : Accounting periods(From)
  --  p_period_to          : Accounting periods(To)
  --  p_currency_code      : Currency
  --  p_show_entered       : Display entered currency
  --  p_show_translated    : Display translated currency
  --  p_balance_type       : Balance type
  --  p_budget_version_id  : Budget version id
  --  p_forward_type       : Display balance amount of forward balance
  --  p_bs_balance_type    : Display balance amount of B/S account
  --  p_pl_balance_type    : Display balance amount of P/L account
  --  p_show_dr_cr         : Display debit and credit
  --  p_show_summary       : Display summary accounts
  --  p_summary_template_id: Summary template id
  --  p_parent_only        : Display parent value only
  --  p_parent_value       : Display parent value
  --  p_condition          : Segment condition
  --  p_show_order         : Segment show order
  --  p_segment_type       : Segment type
  --  p_break_key          : Break key
  --  p_show_total         : Display total
  --  p_result_format      : Result format
  --  p_file_name          : Filename
  --  p_dd_template_id     : Drilldown template id
  --  p_dd_template_name   : Drilldown template name
  --==========================================================
  PROCEDURE request_async_exec(
    p_mode                IN VARCHAR2 DEFAULT NULL,
    p_modify_flag         IN VARCHAR2 DEFAULT 'N',
    p_query_id            IN NUMBER   DEFAULT NULL,
    p_query_name          IN VARCHAR2 DEFAULT NULL,
    p_period_from         IN NUMBER   DEFAULT NULL,
    p_period_to           IN NUMBER   DEFAULT NULL,
    p_currency_code       IN VARCHAR2 DEFAULT NULL,
    p_show_entered        IN VARCHAR2 DEFAULT 'N',
    p_show_translated     IN VARCHAR2 DEFAULT 'N',
    p_balance_type        IN VARCHAR2 DEFAULT NULL,
    p_budget_version_id   IN NUMBER   DEFAULT NULL,
    p_forward_type        IN VARCHAR2 DEFAULT NULL,        /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
    p_bs_balance_type     IN VARCHAR2 DEFAULT NULL,
    p_pl_balance_type     IN VARCHAR2 DEFAULT NULL,
    p_show_dr_cr          IN VARCHAR2 DEFAULT 'N',
    p_show_summary        IN VARCHAR2 DEFAULT 'N',
    p_summary_template_id IN NUMBER   DEFAULT NULL,        /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    p_parent_only         IN VARCHAR2 DEFAULT 'N',
    p_parent_value        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_condition           IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_show_order          IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_break_key           IN VARCHAR2 DEFAULT NULL,
    p_show_total          IN VARCHAR2 DEFAULT 'N',
    p_result_format       IN VARCHAR2 DEFAULT NULL,
    p_file_name           IN VARCHAR2 DEFAULT NULL,
    p_dd_template_id      IN NUMBER   DEFAULT NULL,
    p_dd_template_name    IN VARCHAR2 DEFAULT NULL)
  IS
  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('BQ.REQUEST_ASYNC_EXEC');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_BQ.js"></script>');
    htp.p('<script language="JavaScript">');
    htp.p('<!--');
    htp.p('window.name = "xgv_main";');
    htp.p('// -->');
    htp.p('</script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_REQUEST_ASYNC') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus(); disableBackgroundSchedule('''
      || xgv_common.get_profile_option_value('XGV_ENABLE_BACKGROUND_SCHEDULE') || ''');">');

    -- Display Header
    xgv_common.show_header(
      xgv_common.get_global_buttons_tag('MAIN'),
      xgv_common.get_tabs_tag('BQ'));

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr style="vertical-align: top">');

    -- Display side navigator
    htp.p('<td>');
    show_side_navigator('REQUEST_ASYNC');
    htp.p('</td>');

    -- Display request time for background query
    htp.p('<td width="100%">');

    -- Display title
    htp.prn('<script>t(1, 7);</script>');
    xgv_common.show_title(
      xgv_common.get_message('TITLE_REQUEST_ASYNC'),
        NULL,
        '<a href="javascript:document.f_cancelasync.submit();">'
        || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-cancel_enabled.gif" border="0">'
        || '</a>'
        || '<script>t(8, 1);</script>'
        || '<a href="javascript:requestExecute_async();">'
        || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-execute_enabled.gif" border="0">'
        || '</a>');

    htp.p('<form name="f_execute_time">');

    htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td width="100%">');

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');

    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_EXECUTE_TIME')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText" nowrap>'
      ||  '<input type="radio" name="p_request_type" checked>'
      ||  '<script>t(8, 0);</script>'
      ||  xgv_common.get_message('TEXT_REQUEST_TIME_NOW')
      ||  '</td>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<td colspan="3"></td>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<td></td>'
      ||  '<td></td>'
      ||  '<td class="OraDataText" nowrap>'
      ||  '<input type="radio" name="p_request_type">'
      ||  '<script>t(8, 0);</script>'
      ||  xgv_common.get_message('TEXT_REQUEST_TIME_ASSIGN')
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="text" name="p_date" size="20" maxlength="11" value="'
      ||  to_char(sysdate, xgv_common.get_date_mask)
      ||  '" onChange="javascript:document.f_execute_time[1].checked=true;">'
      ||  xgv_common.r_decode(xgv_common.get_profile_option_value('XGV_ENABLE_BACKGROUND_SCHEDULE'),
            'Y', '<a href="javascript:requestDatePicker_ExecuteDate();">'
                 || '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
                 || '</a>',
            '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">')
      ||  '<script>t(12, 0);</script>');
    htp.p('<select name="p_hour" onChange="javascript:document.f_execute_time[1].checked=true;">');
    FOR  l_hour IN 0..23
    LOOP
      htp.p('<option value="'
        ||  lpad(to_char(l_hour), 2, '0')
        ||  xgv_common.r_decode(
              lpad(to_char(l_hour), 2, '0'), to_char(sysdate + 1/24, 'HH24'), '" selected>', '">')
        ||  to_char(l_hour));
    END LOOP;
    htp.prn('</select>');
    htp.p('<script>t(4, 0);</script>:<script>t(4, 0);</script>'
      ||  '<select name="p_min" onChange="javascript:document.f_execute_time[1].checked=true;">');
    FOR  l_min IN 0..3
    LOOP
      htp.p('<option value="'
        ||  lpad(to_char(15 * l_min), 2, '0')
        ||  '">'
        ||  lpad(to_char(15 * l_min), 2, '0'));
    END LOOP;
    htp.p('</select>');
    htp.p('</td>'
      ||  '</tr>');

    htp.p('</table>');

    htp.p('</td>');
    htp.p('</tr>');
    htp.p('</table>');

    htp.p('</form>');

    htp.p('<form name="f_datepick" method="post" action="./xgv_common.show_datepicker" target="xgv_datepick">');
    htp.p('<input type="hidden" name="p_title_id" value="TITLE_REQUEST_DATE">');
    htp.p('<input type="hidden" name="p_year" value="' || to_char(sysdate, 'RRRR') || '">');
    htp.p('<input type="hidden" name="p_month" value="' || to_char(sysdate, 'MM') || '">');
    htp.p('<input type="hidden" name="p_element_id" value="">');
    htp.p('<input type="hidden" name="p_date_mask" value="' || xgv_common.get_date_mask || '">');
    htp.p('</form>');

    htp.p('</td>');

    htp.p('</tr>');
    htp.p('</table>');

    -- Display footer
    xgv_common.show_footer(
        '<a href="javascript:document.f_cancelasync.submit();">'
        || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-cancel_enabled.gif" border="0">'
        || '</a>'
        || '<script>t(8, 1);</script>'
        || '<a href="javascript:requestExecute_async();">'
        || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-execute_enabled.gif" border="0">'
        || '</a>');

    htp.p('<form name="f_submitasync" method="post" action="./xgv_be.submit_request_async_exec">');
    htp.p('<input type="hidden" name="p_execute_time" value="">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' || htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_period_from" value="' || p_period_from || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || p_period_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_show_entered" value="' || p_show_entered || '">');
    htp.p('<input type="hidden" name="p_show_entered" value="' || p_show_entered || '">');
    htp.p('<input type="hidden" name="p_show_translated" value="' || p_show_translated || '">');
    htp.p('<input type="hidden" name="p_balance_type" value="' || p_balance_type || '">');
    htp.p('<input type="hidden" name="p_budget_version_id" value="' || p_budget_version_id || '">');
    htp.p('<input type="hidden" name="p_forward_type" value="' || p_forward_type || '">');  /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_bs_balance_type" value="' || p_bs_balance_type || '">');
    htp.p('<input type="hidden" name="p_pl_balance_type" value="' || p_pl_balance_type || '">');
    htp.p('<input type="hidden" name="p_show_dr_cr" value="' || p_show_dr_cr || '">');
    htp.p('<input type="hidden" name="p_show_summary" value="' || p_show_summary || '">');
    htp.p('<input type="hidden" name="p_summary_template_id" value="' || p_summary_template_id || '">');  /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_parent_only" value="' || p_parent_only || '">');
    FOR  l_index IN 1..p_parent_value.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_parent_value" value="' ||  p_parent_value(l_index) || '">');
    END LOOP;
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_condition" value="'
        ||  htf.escape_sc(p_condition(l_index)) || '">');
      htp.p('<input type="hidden" name="p_show_order" value="' ||  p_show_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_segment_type" value="' ||  p_segment_type(l_index) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_break_key" value="' || p_break_key || '">');
    htp.p('<input type="hidden" name="p_show_total" value="' || p_show_total || '">');
    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_file_name" value="' || htf.escape_sc(p_file_name) || '">');
    htp.p('<input type="hidden" name="p_dd_template_id" value="' || p_dd_template_id || '">');
    htp.p('</form>');

    htp.p('<form name="f_cancelasync" method="post" action="./xgv_bq.top">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_period_from" value="' || p_period_from || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || p_period_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_show_entered" value="' || p_show_entered || '">');
    htp.p('<input type="hidden" name="p_show_entered" value="' || p_show_entered || '">');
    htp.p('<input type="hidden" name="p_show_translated" value="' || p_show_translated || '">');
    htp.p('<input type="hidden" name="p_balance_type" value="' || p_balance_type || '">');
    htp.p('<input type="hidden" name="p_budget_version_id" value="' || p_budget_version_id || '">');
    htp.p('<input type="hidden" name="p_forward_type" value="' || p_forward_type || '">');  /* Req#220016 05-Apr-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_bs_balance_type" value="' || p_bs_balance_type || '">');
    htp.p('<input type="hidden" name="p_pl_balance_type" value="' || p_pl_balance_type || '">');
    htp.p('<input type="hidden" name="p_show_dr_cr" value="' || p_show_dr_cr || '">');
    htp.p('<input type="hidden" name="p_show_summary" value="' || p_show_summary || '">');
    htp.p('<input type="hidden" name="p_summary_template_id" value="' || p_summary_template_id || '">');  /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_parent_only" value="' || p_parent_only || '">');
    FOR  l_index IN 1..p_parent_value.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_parent_value" value="' ||  p_parent_value(l_index) || '">');
    END LOOP;
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_condition" value="'
        ||  htf.escape_sc(p_condition(l_index)) || '">');
      htp.p('<input type="hidden" name="p_show_order" value="' ||  p_show_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_segment_type" value="' ||  p_segment_type(l_index) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_break_key" value="' || p_break_key || '">');
    htp.p('<input type="hidden" name="p_show_total" value="' || p_show_total || '">');
    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_file_name" value="' || htf.escape_sc(p_file_name) || '">');
    htp.p('<input type="hidden" name="p_dd_template_id" value="' || p_dd_template_id || '">');
    htp.p('</form>');

    htp.p('<form name="f_query">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('</form>');

    htp.p('<form name="f_goto" method="post" action=""></form>');

    htp.p('</body>');

    htp.p('</html>');

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  xgv_user_auth.e_invalid_session
    THEN
      xgv_user_auth.show_session_error;

    WHEN  OTHERS
    THEN
      xgv_common.show_error_page(SQLERRM);

  END request_async_exec;

  --==========================================================
  --Procedure Name: list_conditions
  --Description: Display list condition for Balance inquiry
  --Note:
  --Parameter(s):
  --  p_mode               : Display mode
  --                         (List/Delete confirm/delete Fail)
  --  p_list_filter_value  : Filter string for list
  --  p_list_filter_opttion: Filter option for list
  --  p_start_listno       : Start list number
  --  p_sort_item          : Sort item
  --  p_sort_method        : Sort method(Asc/Desc)
  --==========================================================
  PROCEDURE list_conditions(
    p_mode                IN VARCHAR2 DEFAULT 'L',
    p_list_filter_value   IN VARCHAR2 DEFAULT NULL,
    p_list_filter_opttion IN VARCHAR2 DEFAULT 'AIS',
    p_start_listno        IN NUMBER   DEFAULT 1,
    p_sort_item           IN VARCHAR2 DEFAULT 'NAME',
    p_sort_method         IN VARCHAR2 DEFAULT 'ASC')
  IS
  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('BQ.LIST_CONDITIONS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_BQ.js"></script>');
    htp.p('<script language="JavaScript">');
    htp.p('<!--');
    htp.p('window.name = "xgv_main";');
    htp.p('// -->');
    htp.p('</script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_OPEN_CONDITION') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();">');

    -- Display Header
    xgv_common.show_header(
      xgv_common.get_global_buttons_tag('MAIN'),
      xgv_common.get_tabs_tag('BQ'));

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr style="vertical-align: top">');

    -- Display side navigator
    htp.p('<td>');
    show_side_navigator('OPEN');
    htp.p('</td>');

    -- Display list for query condition
    htp.p('<td width="100%">');

    xgv_common.list_conditions(p_mode, 'B',
      p_list_filter_value, p_list_filter_opttion, p_start_listno, p_sort_item, p_sort_method);

    htp.p('</td>');

    htp.p('</tr>');
    htp.p('</table>');

    -- Display footer
    xgv_common.show_footer;

    htp.p('<form name="f_goto" method="post" action=""></form>');

    htp.p('</body>');

    htp.p('</html>');

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  xgv_user_auth.e_invalid_session
    THEN
      xgv_user_auth.show_session_error;

    WHEN  OTHERS
    THEN
      xgv_common.show_error_page(SQLERRM);

  END list_conditions;

  --==========================================================
  --Function Name: execute_save_condition
  --Description: Execute save condition for Balance inquiry
  --Note:
  --Parameter(s):
  --  p_balance_query_rec: Query condition record
  --  p_save_mode        : Save mode(Update/New)
  --  p_save_category    : Save category(Sob/Responsibility/User)
  --  p_message_type     : Message type(E/C)
  --  p_message_id       : Message id
  --Result: Query id
  --==========================================================
  FUNCTION execute_save_condition(
    p_balance_query_rec IN  xgv_common.balance_query_rtype,
    p_save_mode         IN  VARCHAR2,
    p_save_category     IN  VARCHAR2,
    p_message_type      OUT VARCHAR2,
    p_message_id        OUT VARCHAR2)
  RETURN NUMBER
  IS

    l_query_id  xgv_queries.query_id%TYPE := p_balance_query_rec.query_id;
    l_dummy  xgv_queries.query_name%TYPE;
    l_parent_value  xgv_query_conditions.condition%TYPE;

    PROCEDURE insert_condition_data(
      p_query_id     IN NUMBER,
      p_segment_type IN VARCHAR2,
      p_show_order   IN NUMBER,
      p_condition    IN VARCHAR2)
    IS
    BEGIN

      INSERT INTO xgv_query_conditions(
        query_id,
        segment_type,
        show_order,
        condition,
        creation_date, created_by, last_update_date, last_updated_by)
      VALUES(
        p_query_id,
        p_segment_type,
        p_show_order,
        p_condition,
        sysdate, xgv_common.get_user_id, sysdate, xgv_common.get_user_id);

    END insert_condition_data;

    PROCEDURE update_condition_data(
      p_query_id     IN NUMBER,
      p_segment_type IN VARCHAR2,
      p_show_order   IN NUMBER,
      p_condition    IN VARCHAR2)
    IS
    BEGIN

      UPDATE xgv_query_conditions
      SET    show_order = p_show_order,
             condition = p_condition,
             last_update_date = sysdate,
             last_updated_by = xgv_common.get_user_id
      WHERE  query_id = p_query_id
        AND  segment_type = p_segment_type;

    END update_condition_data;

  BEGIN

    IF  l_query_id IS NULL
    OR  p_save_mode = 'N'
    THEN
      BEGIN
        SELECT xq.query_name
        INTO   l_dummy
        FROM   xgv_queries xq
        WHERE  xq.query_name = p_balance_query_rec.query_name
          AND  xq.inquiry_type = 'B'
          AND  xq.set_of_books_id = xgv_common.get_sob_id
          AND  nvl(xq.application_id, -1) = decode(p_save_category, 'R', xgv_common.get_resp_appl_id, -1)
          AND  nvl(xq.responsibility_id, -1) = decode(p_save_category, 'R', xgv_common.get_resp_id, -1)
          AND  nvl(xq.user_id, -1) = decode(p_save_category, 'U', xgv_common.get_user_id, -1);

        p_message_type := 'E';
        p_message_id := 'ERROR_DUPLICATE_CONDITIONNAME';
      EXCEPTION
        WHEN  NO_DATA_FOUND
        THEN
          BEGIN
            -- Get query(condition) id
            SELECT xgv_queries_s.NEXTVAL
            INTO   l_query_id
            FROM   dual;

            --------------------------------------------------
            -- Insert query conditions
            --------------------------------------------------
            -- Basic condition
            INSERT INTO xgv_queries(
              query_id, query_name, inquiry_type,
              set_of_books_id,
              application_id,
              responsibility_id,
              user_id,
              result_format, file_name,
              description,
              creation_date, created_by, last_update_date, last_updated_by)
            VALUES(
              l_query_id, p_balance_query_rec.query_name, 'B',
              xgv_common.get_sob_id,
              decode(p_save_category, 'R', xgv_common.get_resp_appl_id, NULL),
              decode(p_save_category, 'R', xgv_common.get_resp_id, NULL),
              decode(p_save_category, 'U', xgv_common.get_user_id, NULL),
              p_balance_query_rec.result_format, p_balance_query_rec.file_name,
              p_balance_query_rec.description,
              sysdate, xgv_common.get_user_id, sysdate, xgv_common.get_user_id);

            -- Accounting Periods
            insert_condition_data(l_query_id, 'ACTP', NULL,
              to_char(p_balance_query_rec.period_from)
              || ',' || to_char(p_balance_query_rec.period_to));
            -- Currency
            insert_condition_data(l_query_id, 'CUR', NULL, p_balance_query_rec.currency_code);
            -- Entered Currency
            insert_condition_data(l_query_id, 'ENTER', NULL, p_balance_query_rec.show_entered);
            -- Translated Currency
            insert_condition_data(l_query_id, 'TRANS', NULL, p_balance_query_rec.show_translated);
            -- Balance Type(Actual/Budget/Budget and Actual)
            insert_condition_data(l_query_id, 'TYPE', NULL, p_balance_query_rec.balance_type);
            -- Budget Version ID
            insert_condition_data(l_query_id, 'BUDID', NULL, to_char(p_balance_query_rec.budget_version_id));
            -- Display Balance Amount Of Forward Balance
            /* Req#220016 09-Apr-2007 Added by ytsujiha_jp */
            insert_condition_data(l_query_id, 'FWDTYPE', NULL, p_balance_query_rec.forward_type);
            -- Display Balance Amount
            insert_condition_data(l_query_id, 'BALTYPE', NULL,
              p_balance_query_rec.bs_balance_type || ',' || p_balance_query_rec.pl_balance_type);
            -- Display Debit and Credit
            insert_condition_data(l_query_id, 'DRCR', NULL, p_balance_query_rec.show_dr_cr);
            -- Display Summary Accounts
            insert_condition_data(l_query_id, 'SUMMARYACT', NULL, p_balance_query_rec.show_summary);
            -- Summary Template ID
            /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
            insert_condition_data(l_query_id, 'SUMMARYTMP', NULL, to_char(p_balance_query_rec.summary_template_id));
            -- Display Parent Value Only
            /* Req#200003 09-Jul-2004 Added by ytsujiha_jp */
            insert_condition_data(l_query_id, 'PARENTONLY', NULL, p_balance_query_rec.parent_only);
            -- Display Parent Value
            /* Req#200003 05-Jul-2004 Added by ytsujiha_jp */
            l_parent_value := NULL;
            FOR  l_index IN 1..p_balance_query_rec.parent_value_tab.COUNT
            LOOP
              IF  p_balance_query_rec.parent_value_tab(l_index) = 'Y'
              THEN
                l_parent_value := l_parent_value
                  || xgv_common.r_nvl2(l_parent_value, ',', NULL) || to_char(l_index);
              END IF;
            END LOOP;
            insert_condition_data(l_query_id, 'PARENTVAL', NULL, l_parent_value);
            -- Subtotal Item
            insert_condition_data(l_query_id, 'BREAKKEY', NULL, p_balance_query_rec.break_key);
            -- Display Total
            insert_condition_data(l_query_id, 'TOTAL', NULL, p_balance_query_rec.show_total);
            -- Drilldown Template ID
            insert_condition_data(l_query_id, 'DDTMP', NULL, to_char(p_balance_query_rec.dd_template_id));

            FOR  l_index IN 1..p_balance_query_rec.segment_type_tab.COUNT
            LOOP
              insert_condition_data(l_query_id,
                p_balance_query_rec.segment_type_tab(l_index),
                p_balance_query_rec.show_order_tab(l_index),
                p_balance_query_rec.condition_tab(l_index));
            END LOOP;

            p_message_type := 'C';
          EXCEPTION
            WHEN  OTHERS
            THEN
              ROLLBACK;

              l_query_id := p_balance_query_rec.query_id;
              p_message_type := 'E';
              p_message_id := 'XGV-20015';

              IF  xgv_common.get_profile_option_value('XGV_DEBUG_MODE') = 'Y'
              THEN
                DECLARE
                  l_pipe_status  INTEGER;
                BEGIN
                  IF  dbms_pipe.create_pipe('XGV$DEBUG', private=>FALSE) = 0  /* Bug#230009 25-May-2007 Changed by ytsujiha_jp */
                  THEN
                    dbms_pipe.reset_buffer;
                    dbms_pipe.pack_message(SQLERRM);
                    l_pipe_status := dbms_pipe.send_message('XGV$DEBUG', 0);
                  END IF;
                END;
              END IF;
          END;
      END;

    ELSE
      BEGIN
        IF  p_balance_query_rec.created_by != xgv_common.get_user_id
        THEN
          RAISE e_invalid_authority;
        END IF;

        SELECT xq.query_name
        INTO   l_dummy
        FROM   xgv_queries xq
        WHERE  xq.query_id != l_query_id
          AND  xq.query_name = p_balance_query_rec.query_name
          AND  xq.inquiry_type = 'B'
          AND  xq.set_of_books_id = xgv_common.get_sob_id
          AND  nvl(xq.application_id, -1) = decode(p_save_category, 'R', xgv_common.get_resp_appl_id, -1)
          AND  nvl(xq.responsibility_id, -1) = decode(p_save_category, 'R', xgv_common.get_resp_id, -1)
          AND  nvl(xq.user_id, -1) = decode(p_save_category, 'U', xgv_common.get_user_id, -1);

        p_message_type := 'E';
        p_message_id := 'ERROR_DUPLICATE_CONDITIONNAME';
      EXCEPTION
        WHEN  e_invalid_authority
        THEN
          p_message_type := 'E';
          p_message_id := 'ERROR_FAIL_UPDATE';

        WHEN  NO_DATA_FOUND
        THEN
          BEGIN
            --------------------------------------------------
            -- Update query conditions
            --------------------------------------------------
            -- Basic condition
            UPDATE xgv_queries
            SET    query_name = p_balance_query_rec.query_name,
                   application_id = decode(p_save_category, 'R', xgv_common.get_resp_appl_id, NULL),
                   responsibility_id = decode(p_save_category, 'R', xgv_common.get_resp_id, NULL),
                   user_id = decode(p_save_category, 'U', xgv_common.get_user_id, NULL),
                   result_format = p_balance_query_rec.result_format,
                   file_name = p_balance_query_rec.file_name,
                   description = p_balance_query_rec.description,
                   last_update_date = sysdate,
                   last_updated_by = xgv_common.get_user_id
            WHERE  query_id = l_query_id;

            -- Accounting Periods
            update_condition_data(l_query_id, 'ACTP', NULL,
              to_char(p_balance_query_rec.period_from)
              || ',' || to_char(p_balance_query_rec.period_to));
            -- Currency
            update_condition_data(l_query_id, 'CUR', NULL, p_balance_query_rec.currency_code);
            -- Entered Currency
            update_condition_data(l_query_id, 'ENTER', NULL, p_balance_query_rec.show_entered);
            -- Translated Currency
            update_condition_data(l_query_id, 'TRANS', NULL, p_balance_query_rec.show_translated);
            -- Balance Type(Actual/Budget/Budget and Actual)
            update_condition_data(l_query_id, 'TYPE', NULL, p_balance_query_rec.balance_type);
            -- Budget Version ID
            update_condition_data(l_query_id, 'BUDID', NULL, to_char(p_balance_query_rec.budget_version_id));
            -- Display Balance Amount Of Forward Balance
            /* Req#220016 09-Apr-2007 Added by ytsujiha_jp */
            update_condition_data(l_query_id, 'FWDTYPE', NULL, p_balance_query_rec.forward_type);
            -- Display Balance Amount
            update_condition_data(l_query_id, 'BALTYPE', NULL,
              p_balance_query_rec.bs_balance_type || ',' || p_balance_query_rec.pl_balance_type);
            -- Display Debit and Credit
            update_condition_data(l_query_id, 'DRCR', NULL, p_balance_query_rec.show_dr_cr);
            -- Display Summary Accounts
            update_condition_data(l_query_id, 'SUMMARYACT', NULL, p_balance_query_rec.show_summary);
            -- Summary Template ID
            /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
            update_condition_data(l_query_id, 'SUMMARYTMP', NULL, to_char(p_balance_query_rec.summary_template_id));
            -- Display Parent Value Only
            /* Req#200003 09-Jul-2004 Added by ytsujiha_jp */
            update_condition_data(l_query_id, 'PARENTONLY', NULL, p_balance_query_rec.parent_only);
            -- Display Parent Value
            /* Req#200003 05-Jul-2004 Added by ytsujiha_jp */
            l_parent_value := NULL;
            FOR  l_index IN 1..p_balance_query_rec.parent_value_tab.COUNT
            LOOP
              IF  p_balance_query_rec.parent_value_tab(l_index) = 'Y'
              THEN
                l_parent_value := l_parent_value
                  || xgv_common.r_nvl2(l_parent_value, ',', NULL) || to_char(l_index);
              END IF;
            END LOOP;
            update_condition_data(l_query_id, 'PARENTVAL', NULL, l_parent_value);
            -- Subtotal Item
            update_condition_data(l_query_id, 'BREAKKEY', NULL, p_balance_query_rec.break_key);
            -- Display Total
            update_condition_data(l_query_id, 'TOTAL', NULL, p_balance_query_rec.show_total);
            -- Drilldown Template ID
            update_condition_data(l_query_id, 'DDTMP', NULL, p_balance_query_rec.dd_template_id);

            FOR  l_index IN 1..p_balance_query_rec.segment_type_tab.COUNT
            LOOP
              update_condition_data(l_query_id,
                p_balance_query_rec.segment_type_tab(l_index),
                p_balance_query_rec.show_order_tab(l_index),
                p_balance_query_rec.condition_tab(l_index));
            END LOOP;

            p_message_type := 'C';
          EXCEPTION
            WHEN  OTHERS
            THEN
              ROLLBACK;

              p_message_type := 'E';
              p_message_id := 'XGV-20015';

              IF  xgv_common.get_profile_option_value('XGV_DEBUG_MODE') = 'Y'
              THEN
                DECLARE
                  l_pipe_status  INTEGER;
                BEGIN
                  IF  dbms_pipe.create_pipe('XGV$DEBUG', private=>FALSE) = 0  /* Bug#230009 25-May-2007 Changed by ytsujiha_jp */
                  THEN
                    dbms_pipe.reset_buffer;
                    dbms_pipe.pack_message(SQLERRM);
                    l_pipe_status := dbms_pipe.send_message('XGV$DEBUG', 0);
                  END IF;
                END;
              END IF;
          END;
      END;
    END IF;

    RETURN l_query_id;

  END execute_save_condition;

  --==========================================================
  --Procedure Name: save_condition
  --Description: Save condition for Balance inquiry
  --Note:
  --Parameter(s):
  --  p_mode               : Display mode
  --                         (New save Dialog/Update save Dialog/New save/Update save)
  --  p_modify_flag        : Modify flag(Yes/No)
  --  p_save_category      : Save category(Sob/Responsibility/User)
  --  p_query_id           : Query id
  --  p_query_name         : Query name
  --  p_period_from        : Accounting periods(From)
  --  p_period_to          : Accounting periods(To)
  --  p_currency_code      : Currency
  --  p_show_entered       : Display entered currency
  --  p_show_translated    : Display translated currency
  --  p_balance_type       : Balance type
  --  p_budget_version_id  : Budget version id
  --  p_forward_type       : Display balance amount of forward balance
  --  p_bs_balance_type    : Display balance amount of B/S account
  --  p_pl_balance_type    : Display balance amount of P/L account
  --  p_show_dr_cr         : Display debit and credit
  --  p_show_summary       : Display summary accounts
  --  p_summary_template_id: Summary template id
  --  p_parent_only        : Display parent value only
  --  p_parent_value       : Display parent value
  --  p_condition          : Segment condition
  --  p_show_order         : Segment show order
  --  p_segment_type       : Segment type
  --  p_break_key          : Break key
  --  p_show_total         : Display total
  --  p_result_format      : Result format
  --  p_file_name          : Filename
  --  p_dd_template_id     : Drilldown template id
  --  p_dd_template_name   : Drilldown template name
  --  p_description        : Description
  --==========================================================
  PROCEDURE save_condition(
    p_mode                IN VARCHAR2 DEFAULT 'ND',
    p_modify_flag         IN VARCHAR2 DEFAULT 'N',
    p_save_category       IN VARCHAR2 DEFAULT 'U',
    p_query_id            IN NUMBER   DEFAULT NULL,
    p_query_name          IN VARCHAR2 DEFAULT NULL,
    p_period_from         IN NUMBER   DEFAULT NULL,
    p_period_to           IN NUMBER   DEFAULT NULL,
    p_currency_code       IN VARCHAR2 DEFAULT NULL,
    p_show_entered        IN VARCHAR2 DEFAULT 'N',
    p_show_translated     IN VARCHAR2 DEFAULT 'N',
    p_balance_type        IN VARCHAR2 DEFAULT NULL,
    p_budget_version_id   IN NUMBER   DEFAULT NULL,
    p_forward_type        IN VARCHAR2 DEFAULT NULL,        /* Req#220016 09-Apr-2007 Added by ytsujiha_jp */
    p_bs_balance_type     IN VARCHAR2 DEFAULT NULL,
    p_pl_balance_type     IN VARCHAR2 DEFAULT NULL,
    p_show_dr_cr          IN VARCHAR2 DEFAULT 'N',
    p_show_summary        IN VARCHAR2 DEFAULT 'N',
    p_summary_template_id IN NUMBER   DEFAULT NULL,        /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    p_parent_only         IN VARCHAR2 DEFAULT 'N',
    p_parent_value        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_condition           IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_show_order          IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_break_key           IN VARCHAR2 DEFAULT NULL,
    p_show_total          IN VARCHAR2 DEFAULT 'N',
    p_result_format       IN VARCHAR2 DEFAULT NULL,
    p_file_name           IN VARCHAR2 DEFAULT NULL,
    p_dd_template_id      IN NUMBER   DEFAULT NULL,
    p_dd_template_name    IN VARCHAR2 DEFAULT NULL,
    p_description         IN VARCHAR2 DEFAULT NULL)
  IS

    l_mode  VARCHAR2(2) := p_mode;
    l_save_category  VARCHAR2(1) := p_save_category;
    l_query_id  xgv_queries.query_id%TYPE := p_query_id;
    l_description  xgv_queries.description%TYPE := p_description;
    l_balance_query_rec  xgv_common.balance_query_rtype;
    l_message_type  VARCHAR2(1) := NULL;
    l_message_id  VARCHAR2(255) := NULL;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('BQ.SAVE_CONDITION');

    -- Adjustment mode
    IF  p_query_id IS NULL
    AND l_mode = 'UD'
    THEN
      l_mode := 'ND';
    END IF;

    -- Save mode
    IF  l_mode IN ('N', 'U')
    THEN
      IF  l_mode = 'N'
      THEN
        set_query_condition_local(
          l_balance_query_rec, NULL, p_period_from, p_period_to, p_currency_code,
          p_show_entered, p_show_translated, p_balance_type, p_budget_version_id,
          p_forward_type, p_bs_balance_type, p_pl_balance_type, p_show_dr_cr,  /* Req#220016 09-Apr-2007 Changed by ytsujiha_jp */
          p_show_summary, p_summary_template_id, p_parent_only,                /* Req#220020 30-Mar-2007 Changed by ytsujiha_jp */
          p_parent_value, p_condition, p_show_order, p_segment_type,
          p_break_key, p_show_total, p_result_format, p_file_name, p_dd_template_id,
          l_description);
        l_balance_query_rec.query_id := p_query_id;

      ELSE
        set_query_condition_local(
          l_balance_query_rec, p_query_id, p_period_from, p_period_to, p_currency_code,
          p_show_entered, p_show_translated, p_balance_type, p_budget_version_id,
          p_forward_type, p_bs_balance_type, p_pl_balance_type, p_show_dr_cr,  /* Req#220016 09-Apr-2007 Changed by ytsujiha_jp */
          p_show_summary, p_summary_template_id, p_parent_only,                /* Req#220020 30-Mar-2007 Changed by ytsujiha_jp */
          p_parent_value, p_condition, p_show_order, p_segment_type,
          p_break_key, p_show_total, p_result_format, p_file_name, p_dd_template_id,
          l_description);
      END IF;

      l_balance_query_rec.query_name := p_query_name;
      l_query_id := execute_save_condition(
        l_balance_query_rec, l_mode, p_save_category, l_message_type, l_message_id);

      IF  l_message_type = 'C'
      THEN
        htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
        htp.p('<html dir="ltr">');
        htp.p('<body>');
        htp.p('<form name="f_refresh" method="post" action="./xgv_bq.top">');
        htp.p('<input type="hidden" name="p_mode" value="S">');
        htp.p('<input type="hidden" name="p_query_id" value="' || l_query_id || '">');
        htp.p('</form>');
        htp.p('<script language="JavaScript">');
        htp.p('<!--');
        htp.p('document.f_refresh.submit();');
        htp.p('// -->');
        htp.p('</script>');
        htp.p('</body>');
        htp.p('</html>');

        RETURN;

      ELSE
        l_mode := xgv_common.r_decode(l_mode, 'N', 'ND', 'UD');
      END IF;
    END IF;

    -- Get save category and description
    BEGIN
      IF  l_message_type IS NULL
      AND p_query_id IS NOT NULL
      THEN
        SELECT decode(xq.user_id,
                 NULL, decode(xq.responsibility_id, NULL, 'S', 'R'), 'U'),
               xq.description
        INTO   l_save_category,
               l_description
        FROM   xgv_queries xq
        WHERE  xq.query_id = p_query_id
          AND  xq.inquiry_type = 'B';
      END IF;
    EXCEPTION
      WHEN  NO_DATA_FOUND
      THEN
        NULL;
    END;

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_BQ.js"></script>');
    htp.p('<script language="JavaScript">');
    htp.p('<!--');
    htp.p('window.name = "xgv_main";');
    htp.p('// -->');
    htp.p('</script>');
    htp.p('<title>'
      ||  xgv_common.r_decode(l_mode,
            'ND', xgv_common.get_message('TITLE_SAVEAS_CONDITION'),
            xgv_common.get_message('TITLE_SAVE_CONDITION'))
      || '</title>');
    htp.p('</head>');

    IF  l_mode = 'ND'
    THEN
      htp.p('<body class="OraBody" onLoad="document.f_savedialog.p_query_name.focus();">');
    ELSE
      htp.p('<body class="OraBody" onLoad="window.focus();">');
    END IF;

    -- Display Header
    xgv_common.show_header(
      xgv_common.get_global_buttons_tag('MAIN'),
      xgv_common.get_tabs_tag('BQ'));

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr style="vertical-align: top">');

    -- Display side navigator
    htp.p('<td>');
    show_side_navigator(xgv_common.r_decode(l_mode, 'ND', 'SAVEAS', 'SAVE'));
    htp.p('</td>');

    -- Display condition editor for query condition
    htp.p('<td width="100%">');

    -- Display error message
    IF  l_message_type = 'E'
    THEN
      htp.prn('<script>t(1, 7);</script>');
      xgv_common.show_messagebox('E', l_message_id);
    END IF;

    -- Display title
    htp.prn('<script>t(1, 7);</script>');
    xgv_common.show_title(
      xgv_common.get_message(
        xgv_common.r_decode(l_mode, 'ND', 'TITLE_SAVEAS_CONDITION', 'TITLE_SAVE_CONDITION')),
      NULL,
      '<a href="javascript:document.f_cancelsave.submit();">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-cancel_enabled.gif" border="0">'
      || '</a>'
      || '<script>t(8, 1);</script>'
      || '<a href="javascript:requestSave(''' || xgv_common.r_decode(l_mode, 'ND', 'N', 'U') || ''');">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-save_enabled.gif" border="0">'
      || '</a>');
-- 2011/12/09 Add E_本稼動_08742 Start
    htp.p(
      '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
      || '<tr>'
      || '<td colspan="5"><span class="OraErrorHeader">' || xxccp_common_pkg.get_msg('XXCFO','APP-XXCFO1-00040')
      || '</span></td></tr>'
      || '</table>');
-- 2011/12/09 Add E_本稼動_08742 End

    htp.p('<form name="f_savedialog" method="post" action="./xgv_bq.save_condition">');
    htp.p('<input type="hidden" name="p_mode" value="N">');
    htp.p('<input type="hidden" name="p_period_from" value="' || p_period_from || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || p_period_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_show_entered" value="' || p_show_entered || '">');
    htp.p('<input type="hidden" name="p_show_entered" value="' || p_show_entered || '">');
    htp.p('<input type="hidden" name="p_show_translated" value="' || p_show_translated || '">');
    htp.p('<input type="hidden" name="p_balance_type" value="' || p_balance_type || '">');
    htp.p('<input type="hidden" name="p_budget_version_id" value="' || p_budget_version_id || '">');
    htp.p('<input type="hidden" name="p_forward_type" value="' || p_forward_type || '">');     /* Req#220016 09-Apr-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_bs_balance_type" value="' || p_bs_balance_type || '">');
    htp.p('<input type="hidden" name="p_pl_balance_type" value="' || p_pl_balance_type || '">');
    htp.p('<input type="hidden" name="p_show_dr_cr" value="' || p_show_dr_cr || '">');
    htp.p('<input type="hidden" name="p_show_summary" value="' || p_show_summary || '">');
    htp.p('<input type="hidden" name="p_summary_template_id" value="' || p_summary_template_id || '">');  /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_parent_only" value="' || p_parent_only || '">');
    FOR  l_index IN 1..p_parent_value.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_parent_value" value="' ||  p_parent_value(l_index) || '">');
    END LOOP;
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_condition" value="'
        ||  htf.escape_sc(p_condition(l_index)) || '">');
      htp.p('<input type="hidden" name="p_show_order" value="' ||  p_show_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_segment_type" value="' ||  p_segment_type(l_index) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_break_key" value="' || p_break_key || '">');
    htp.p('<input type="hidden" name="p_show_total" value="' || p_show_total || '">');
    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_file_name" value="' || htf.escape_sc(p_file_name) || '">');
    htp.p('<input type="hidden" name="p_dd_template_id" value="' || p_dd_template_id || '">');

    htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">');

    htp.p('<tr>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td width="100%">');

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');

    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_CONDITION_NAME')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="hidden" name="p_query_id" value="' || l_query_id || '">'
      ||  xgv_common.r_decode(l_mode,
            'ND', '<input type="text" name="p_query_name" size="60" maxlength="100" value="'
              || htf.escape_sc(p_query_name) || '">',
            '<input type="hidden" name="p_query_name" value="' || htf.escape_sc(p_query_name) || '">'
              || xgv_common.escape_sc(p_query_name))
      ||  '</td>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_SAVE_CATEGORY')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="radio" name="p_save_category" value="S"'
-- 2011/12/09 Mod E_本稼動_08742 Start
--      ||  xgv_common.r_decode(l_save_category, 'S', ' checked>', '>')
      ||  '>'
-- 2011/12/09 Mod E_本稼動_08742 End
      ||  xgv_common.get_message('PROMPT_UNIT_SET_OF_BOOKS')
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="radio" name="p_save_category" value="R"'
-- 2011/12/09 Mod E_本稼動_08742 Start
--      ||  xgv_common.r_decode(l_save_category, 'R', ' checked>', '>')
      ||  '>'
-- 2011/12/09 Mod E_本稼動_08742 End
      ||  xgv_common.get_message('PROMPT_UNIT_RESPONSIBILITY')
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="radio" name="p_save_category" value="U"'
-- 2011/12/09 Mod E_本稼動_08742 Start
--      ||  xgv_common.r_decode(l_save_category, 'U', ' checked>', '>')
      ||  ' checked>'
-- 2011/12/09 Mod E_本稼動_08742 End
      ||  xgv_common.get_message('PROMPT_UNIT_USER')
      ||  '</td>'
      ||  '</tr>');
    htp.p('<tr>'
      ||  '<th class="OraPromptText" valign="top" nowrap>'
      ||  xgv_common.get_message('PROMPT_SAVE_DESCRIPTION')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<textarea name="p_description" rows="5" cols="50" wrap="soft">'
      ||  htf.escape_sc(l_description)
      ||  '</textarea>'
      ||  '</td>'
      ||  '</tr>');

    htp.p('</table>');

    htp.p('</td>');
    htp.p('</tr>');

    htp.p('</table>');

    htp.p('</form>');

    htp.p('</td>');

    htp.p('</tr>');
    htp.p('</table>');

    -- Display footer
    xgv_common.show_footer(
      '<a href="javascript:document.f_cancelsave.submit();">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-cancel_enabled.gif" border="0">'
      || '</a>'
      || '<script>t(8, 1);</script>'
      || '<a href="javascript:requestSave(''' || xgv_common.r_decode(l_mode, 'ND', 'N', 'U') || ''');">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-save_enabled.gif" border="0">'
      || '</a>');

    htp.p('<form name="f_cancelsave" method="post" action="./xgv_bq.top">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || l_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_period_from" value="' || p_period_from || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || p_period_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_show_entered" value="' || p_show_entered || '">');
    htp.p('<input type="hidden" name="p_show_entered" value="' || p_show_entered || '">');
    htp.p('<input type="hidden" name="p_show_translated" value="' || p_show_translated || '">');
    htp.p('<input type="hidden" name="p_balance_type" value="' || p_balance_type || '">');
    htp.p('<input type="hidden" name="p_budget_version_id" value="' || p_budget_version_id || '">');
    htp.p('<input type="hidden" name="p_forward_type" value="' || p_forward_type || '">');     /* Req#220016 09-Apr-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_bs_balance_type" value="' || p_bs_balance_type || '">');
    htp.p('<input type="hidden" name="p_pl_balance_type" value="' || p_pl_balance_type || '">');
    htp.p('<input type="hidden" name="p_show_dr_cr" value="' || p_show_dr_cr || '">');
    htp.p('<input type="hidden" name="p_show_summary" value="' || p_show_summary || '">');
    htp.p('<input type="hidden" name="p_summary_template_id" value="' || p_summary_template_id || '">');  /* Req#220020 30-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_parent_only" value="' || p_parent_only || '">');
    FOR  l_index IN 1..p_parent_value.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_parent_value" value="' ||  p_parent_value(l_index) || '">');
    END LOOP;
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_condition" value="'
        ||  htf.escape_sc(p_condition(l_index)) || '">');
      htp.p('<input type="hidden" name="p_show_order" value="' ||  p_show_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_segment_type" value="' ||  p_segment_type(l_index) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_break_key" value="' || p_break_key || '">');
    htp.p('<input type="hidden" name="p_show_total" value="' || p_show_total || '">');
    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_file_name" value="' || htf.escape_sc(p_file_name) || '">');
    htp.p('<input type="hidden" name="p_dd_template_id" value="' || p_dd_template_id || '">');
    htp.p('</form>');

    htp.p('<form name="f_query">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('</form>');

    htp.p('<form name="f_goto" method="post" action=""></form>');

    htp.p('</body>');

    htp.p('</html>');

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  xgv_user_auth.e_invalid_session
    THEN
      xgv_user_auth.show_session_error;

    WHEN  OTHERS
    THEN
      xgv_common.show_error_page(SQLERRM);

  END save_condition;

  --==========================================================
  --Procedure Name: delete_condition
  --Description: Delete condition for Balance inquiry
  --Note:
  --Parameter(s):
  --  p_query_id           : Query id
  --  p_list_filter_value  : Filter string for list
  --  p_list_filter_opttion: Filter option for list
  --  p_sort_item          : Sort item
  --  p_sort_method        : Sort method(Asc/Desc)
  --==========================================================
  PROCEDURE delete_condition(
    p_query_id            IN NUMBER,
    p_list_filter_value   IN VARCHAR2 DEFAULT NULL,
    p_list_filter_opttion IN VARCHAR2 DEFAULT 'AIS',
    p_sort_item           IN VARCHAR2 DEFAULT 'NAME',
    p_sort_method         IN VARCHAR2 DEFAULT 'ASC')
  IS

    l_mode  VARCHAR2(1) := 'D';
    l_created_by  xgv_queries.created_by%TYPE;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('BQ.DELETE_CONDITION');

    BEGIN
      SELECT xq.created_by
      INTO   l_created_by
      FROM   xgv_queries xq
      WHERE  xq.query_id = p_query_id;

      IF  l_created_by != xgv_common.get_user_id
      THEN
        RAISE e_invalid_authority;
      END IF;

      DELETE xgv_query_conditions xqc
      WHERE  xqc.query_id = p_query_id;
      DELETE xgv_queries xq
      WHERE  xq.query_id = p_query_id;

    EXCEPTION
      WHEN  NO_DATA_FOUND OR e_invalid_authority
      THEN
        l_mode := 'F';
    END;

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');
    htp.p('<body>');
    htp.p('<form name="f_refresh" method="post" action="./xgv_bq.list_conditions">');
    htp.p('<input type="hidden" name="p_mode" value="' || l_mode || '">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="' || htf.escape_sc(p_list_filter_value) || '">');
    htp.p('<input type="hidden" name="p_list_filter_opttion" value="' || p_list_filter_opttion || '">');
    htp.p('<input type="hidden" name="p_sort_item" value="' || p_sort_item || '">');
    htp.p('<input type="hidden" name="p_sort_method" value="' || p_sort_method || '">');
    htp.p('</form>');
    htp.p('<script language="JavaScript">');
    htp.p('<!--');
    htp.p('document.f_refresh.submit();');
    htp.p('// -->');
    htp.p('</script>');
    htp.p('</body>');
    htp.p('</html>');

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  xgv_user_auth.e_invalid_session
    THEN
      xgv_user_auth.show_session_error;

    WHEN  OTHERS
    THEN
      xgv_common.show_error_page(SQLERRM);

  END delete_condition;

END xgv_bq;
/
