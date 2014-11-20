CREATE OR REPLACE PACKAGE BODY xgv_jq
--
--  XGVJEDTB.pls
--
--  Copyright (c) Oracle Corporation 2001-2007. All Rights Reserved
--
--  NAME
--    xgv_jq
--  FUNCTION
--    Edit condition for Journal entry lines inquiry(Body)
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
  --Description: Get record for journal entry lines query
  --Note:
  --Parameter(s):
  --  p_je_lines_query_rec: Record for journal entry lines query
  --  p_query_id          : Query id
  --==========================================================
  PROCEDURE set_query_condition(
    p_je_lines_query_rec OUT xgv_common.je_lines_query_rtype,
    p_query_id           IN  NUMBER)
  IS

    l_aff_dff_current_segment_id  PLS_INTEGER := 1;

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
              FROM   (SELECT xuiv.item_code segment_type
                      FROM   xgv_usable_items_vl xuiv
                      WHERE  xuiv.inquiry_type = 'J'
                        AND  xuiv.enabled_flag = 'Y'
                      UNION ALL
                      SELECT to_char(xfsv.segment_id) segment_type
                      FROM   xgv_flex_structures_vl xfsv
                      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
                        AND  xfsv.application_id = xgv_common.get_gl_appl_id) xuiv_xfsv
              WHERE  xuiv_xfsv.segment_type = xqc.segment_type);

    -- Select save segment conditions
    CURSOR l_seg_conditions_cur(
      p_query_id NUMBER)
    IS
      SELECT 1 order1,
             xuiv.item_order oder2,
             xuiv.item_code segment_type,
             xqc.condition condition,
             xqc.show_order show_order,
             xqc.sort_order sort_order,
             xqc.sort_method sort_method
      FROM   xgv_usable_items_vl xuiv,
             xgv_query_conditions xqc
      WHERE  xuiv.inquiry_type = 'J'
        AND  xuiv.enabled_flag = 'Y'
        AND  xqc.segment_type (+) = xuiv.item_code
        AND  xqc.query_id (+) = p_query_id
      UNION ALL
      SELECT 2 order1,
             xfsv.segment_id order2,
             xqc.segment_type segment_type,
             xqc.condition condition,
             xqc.show_order show_order,
             xqc.sort_order sort_order,
             xqc.sort_method sort_method
      FROM   xgv_flex_structures_vl xfsv,
             xgv_query_conditions xqc
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
        AND  to_char(xfsv.segment_id) = xqc.segment_type
        AND  xqc.query_id = p_query_id
      ORDER BY 1, 2;

    -- Select usable items and AFF,DFF defines
    CURSOR l_jq_segs_cur
    IS
      SELECT 1 order1,
             xuiv.item_order oder2,
             xuiv.item_code segment_type
      FROM   xgv_usable_items_vl xuiv
      WHERE  xuiv.inquiry_type = 'J'
        AND  xuiv.enabled_flag = 'Y'
      UNION ALL
      SELECT 2 order1,
             xfsv.segment_id order2,
             to_char(xfsv.segment_id) segment_type
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
      ORDER BY 1, 2;

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
    INTO   p_je_lines_query_rec.query_id,
           p_je_lines_query_rec.query_name,
           p_je_lines_query_rec.result_format,
           p_je_lines_query_rec.file_name,
           p_je_lines_query_rec.description,
           p_je_lines_query_rec.result_rows,
           p_je_lines_query_rec.creation_date,
           p_je_lines_query_rec.created_by,
           p_je_lines_query_rec.last_update_date,
           p_je_lines_query_rec.last_updated_by
    FROM   xgv_queries xq
    WHERE  xq.query_id = p_query_id
      AND  xq.inquiry_type = 'J';

    FOR  l_other_conditions_rec IN l_other_conditions_cur(p_query_id)
    LOOP

      -- Journal Entry Type(Actual/Budget)
      IF  l_other_conditions_rec.segment_type = 'TYPE'
      THEN
        p_je_lines_query_rec.je_type := l_other_conditions_rec.condition;

      -- Budget Version ID
      ELSIF  l_other_conditions_rec.segment_type = 'BUDID'
      THEN
        p_je_lines_query_rec.budget_version_id := to_number(l_other_conditions_rec.condition);

      -- Subtotal Item
      ELSIF  l_other_conditions_rec.segment_type = 'BREAKKEY'
      THEN
        p_je_lines_query_rec.break_key := l_other_conditions_rec.condition;

      -- Display Subtotal Only
      ELSIF  l_other_conditions_rec.segment_type = 'SUBTOTAL'
      THEN
        p_je_lines_query_rec.show_subtotalonly := l_other_conditions_rec.condition;

      -- Display Total
      ELSIF  l_other_conditions_rec.segment_type = 'TOTAL'
      THEN
        p_je_lines_query_rec.show_total := l_other_conditions_rec.condition;

      -- Display bring forward line
      ELSIF  l_other_conditions_rec.segment_type = 'BRGFORWARD'
      THEN
        p_je_lines_query_rec.show_bringforward := l_other_conditions_rec.condition;

      END IF;

    END LOOP;

    FOR  l_seg_conditions_rec IN l_seg_conditions_cur(p_query_id)
    LOOP

      p_je_lines_query_rec.segment_type_tab(l_seg_conditions_cur%ROWCOUNT) := l_seg_conditions_rec.segment_type;
      p_je_lines_query_rec.show_order_tab(l_seg_conditions_cur%ROWCOUNT)   := l_seg_conditions_rec.show_order;
      p_je_lines_query_rec.sort_order_tab(l_seg_conditions_cur%ROWCOUNT)   := l_seg_conditions_rec.sort_order;
      p_je_lines_query_rec.sort_method_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.sort_method;

      -- Header Refer, External Data Refer(Hidden items)
      IF  l_seg_conditions_rec.segment_type IN ('DD', 'EXDD')
      THEN
        p_je_lines_query_rec.show_order_tab(l_seg_conditions_cur%ROWCOUNT) := 1;

      -- Accounting Periods
      ELSIF  l_seg_conditions_rec.segment_type = 'ACTP'
      THEN
        p_je_lines_query_rec.period_from := to_number(xgv_common.split(l_seg_conditions_rec.condition, ','));
        p_je_lines_query_rec.period_to   := to_number(xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2));

      -- Journal Entry Effective Date
      ELSIF  l_seg_conditions_rec.segment_type = 'JEEDATE'
      THEN
        p_je_lines_query_rec.effect_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_je_lines_query_rec.effect_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_je_lines_query_rec.effect_date_from, 'RRRRMMDD')
        THEN
          p_je_lines_query_rec.effect_date_from :=
            to_char(to_date(p_je_lines_query_rec.effect_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_je_lines_query_rec.effect_date_to, 'RRRRMMDD')
        THEN
          p_je_lines_query_rec.effect_date_to :=
            to_char(to_date(p_je_lines_query_rec.effect_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- Journal Entry Post Status
      ELSIF  l_seg_conditions_rec.segment_type = 'POSTSTATUS'
      THEN
        IF  instr(l_seg_conditions_rec.condition, 'P', 1, 1) > 0
        THEN
          p_je_lines_query_rec.posted := 'Y';
        ELSE
          p_je_lines_query_rec.posted := 'N';
        END IF;
        IF  instr(l_seg_conditions_rec.condition, 'U', 1, 1) > 0
        THEN
          p_je_lines_query_rec.unposted := 'Y';
        ELSE
          p_je_lines_query_rec.unposted := 'N';
        END IF;
        IF  instr(l_seg_conditions_rec.condition, 'E', 1, 1) > 0
        THEN
          p_je_lines_query_rec.postederror := 'Y';
        ELSE
          p_je_lines_query_rec.postederror := 'N';
        END IF;

      -- Journal Entry Document Sequenctial Number
      ELSIF  l_seg_conditions_rec.segment_type = 'JEDOCNUM'
      THEN
        p_je_lines_query_rec.doc_seq_from := to_number(xgv_common.split(l_seg_conditions_rec.condition, ','));
        p_je_lines_query_rec.doc_seq_to   := to_number(xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2));

      -- Currency
      -- Journal Entry Batch Description, Journal Entry Description, Journal Entry Line Description
      -- Source, Category, Batch, Header Name
      /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
      ELSIF  l_seg_conditions_rec.segment_type IN ('CUR',
                                                   'BATCHDESC', 'HEADERDESC', 'DESC',
                                                   'SOURCE', 'CATEGORY', 'BATCH', 'HEADER')
      THEN
        p_je_lines_query_rec.condition_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.condition;

      -- Debit Amount
      ELSIF  l_seg_conditions_rec.segment_type = 'DR'
      THEN
        p_je_lines_query_rec.dr_from := to_number(xgv_common.split(l_seg_conditions_rec.condition, ','));
        p_je_lines_query_rec.dr_to   := to_number(xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2));

      -- Credit Amount
      ELSIF  l_seg_conditions_rec.segment_type = 'CR'
      THEN
        p_je_lines_query_rec.cr_from := to_number(xgv_common.split(l_seg_conditions_rec.condition, ','));
        p_je_lines_query_rec.cr_to   := to_number(xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2));

      -- AFF/DFF Segments
      ELSIF  xgv_common.is_number(l_seg_conditions_rec.segment_type)
      THEN
        IF  l_seg_conditions_rec.segment_type != to_char(l_aff_dff_current_segment_id)
        THEN
          raise_application_error(-20201,
            xgv_common.get_message('XGV-20201',
              xgv_common.get_sob_id,
              ' ',
              l_aff_dff_current_segment_id,
              l_seg_conditions_rec.segment_type));
        ELSE
          l_aff_dff_current_segment_id := l_aff_dff_current_segment_id + 1;
        END IF;

        p_je_lines_query_rec.condition_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.condition;

      -- Journal Entry Creation Date
      ELSIF  l_seg_conditions_rec.segment_type = 'JECDATE'
      THEN
        p_je_lines_query_rec.create_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_je_lines_query_rec.create_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_je_lines_query_rec.create_date_from, 'RRRRMMDD')
        THEN
          p_je_lines_query_rec.create_date_from :=
            to_char(to_date(p_je_lines_query_rec.create_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_je_lines_query_rec.create_date_to, 'RRRRMMDD')
        THEN
          p_je_lines_query_rec.create_date_to :=
            to_char(to_date(p_je_lines_query_rec.create_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- Journal Entry Posted Date
      ELSIF  l_seg_conditions_rec.segment_type = 'JEPDATE'
      THEN
        p_je_lines_query_rec.posted_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_je_lines_query_rec.posted_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_je_lines_query_rec.posted_date_from, 'RRRRMMDD')
        THEN
          p_je_lines_query_rec.posted_date_from :=
            to_char(to_date(p_je_lines_query_rec.posted_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_je_lines_query_rec.posted_date_to, 'RRRRMMDD')
        THEN
          p_je_lines_query_rec.posted_date_to :=
            to_char(to_date(p_je_lines_query_rec.posted_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
      END IF;

    END LOOP;

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  NO_DATA_FOUND
    THEN
      -- Set default value
      p_je_lines_query_rec.query_id          := NULL;
      p_je_lines_query_rec.query_name        := NULL;
      p_je_lines_query_rec.je_type           := 'A';
      p_je_lines_query_rec.budget_version_id := NULL;
      p_je_lines_query_rec.break_key         := NULL;
      p_je_lines_query_rec.show_subtotalonly := 'N';
      p_je_lines_query_rec.show_total        := 'N';
      p_je_lines_query_rec.show_bringforward := 'N';
      p_je_lines_query_rec.result_format     := nvl(xgv_common.get_profile_option_value('XGV_DEFAULT_RESULT_FORMAT'), 'HTML');
      p_je_lines_query_rec.file_name         := NULL;
      p_je_lines_query_rec.description       := NULL;
      p_je_lines_query_rec.result_rows       := NULL;
      p_je_lines_query_rec.creation_date     := NULL;
      p_je_lines_query_rec.created_by        := NULL;
      p_je_lines_query_rec.last_update_date  := NULL;
      p_je_lines_query_rec.last_updated_by   := NULL;

      FOR  l_jq_segs_rec IN l_jq_segs_cur
      LOOP

        -- Set default value
        p_je_lines_query_rec.segment_type_tab(l_jq_segs_cur%ROWCOUNT) := l_jq_segs_rec.segment_type;
        p_je_lines_query_rec.show_order_tab(l_jq_segs_cur%ROWCOUNT)   := NULL;
        p_je_lines_query_rec.sort_order_tab(l_jq_segs_cur%ROWCOUNT)   := NULL;
        p_je_lines_query_rec.sort_method_tab(l_jq_segs_cur%ROWCOUNT)  := NULL;

        -- Header Refer, External Data Refer(Hidden items)
        IF  l_jq_segs_rec.segment_type IN ('DD', 'EXDD')
        THEN
          p_je_lines_query_rec.show_order_tab(l_jq_segs_cur%ROWCOUNT) := 1;

        -- Accounting Periods
        ELSIF  l_jq_segs_rec.segment_type = 'ACTP'
        THEN
          p_je_lines_query_rec.period_from := xgv_common.get_current_period;
          p_je_lines_query_rec.period_to   := xgv_common.get_current_period;

        -- Journal Entry Effective Date
        ELSIF  l_jq_segs_rec.segment_type = 'JEEDATE'
        THEN
          p_je_lines_query_rec.effect_date_from := NULL;
          p_je_lines_query_rec.effect_date_to   := NULL;
          p_je_lines_query_rec.sort_order_tab(l_jq_segs_cur%ROWCOUNT) := 1;

        -- Journal Entry Post Status
        ELSIF  l_jq_segs_rec.segment_type = 'POSTSTATUS'
        THEN
          p_je_lines_query_rec.posted      := 'Y';
          p_je_lines_query_rec.unposted    := 'N';
          p_je_lines_query_rec.postederror := 'N';

        -- Journal Entry Document Sequenctial Number
        ELSIF  l_jq_segs_rec.segment_type = 'JEDOCNUM'
        THEN
          p_je_lines_query_rec.doc_seq_from := NULL;
          p_je_lines_query_rec.doc_seq_to   := NULL;

        -- Currency
        ELSIF  l_jq_segs_rec.segment_type = 'CUR'
        THEN
          p_je_lines_query_rec.condition_tab(l_jq_segs_cur%ROWCOUNT)  := xgv_common.get_functional_currency;

        -- Debit Amount
        ELSIF  l_jq_segs_rec.segment_type = 'DR'
        THEN
          p_je_lines_query_rec.dr_from := NULL;
          p_je_lines_query_rec.dr_to   := NULL;

        -- Credit Amount
        ELSIF  l_jq_segs_rec.segment_type = 'CR'
        THEN
          p_je_lines_query_rec.cr_from := NULL;
          p_je_lines_query_rec.cr_to   := NULL;

        -- Journal Entry Batch Description, Journal Entry Description, Journal Entry Line Description
        -- Source, Category, Batch, Header Name
        /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
        ELSIF  l_jq_segs_rec.segment_type IN ('BATCHDESC', 'HEADERDESC', 'DESC',
                                              'SOURCE', 'CATEGORY', 'BATCH', 'HEADER')
        THEN
          p_je_lines_query_rec.condition_tab(l_jq_segs_cur%ROWCOUNT)  := NULL;

        -- AFF/DFF Segments
        ELSIF  xgv_common.is_number(l_jq_segs_rec.segment_type)
        THEN
          IF  l_jq_segs_rec.segment_type != to_char(l_aff_dff_current_segment_id)
          THEN
            raise_application_error(-20201,
              xgv_common.get_message('XGV-20201',
                xgv_common.get_sob_id,
                ' ',
                l_aff_dff_current_segment_id,
                l_jq_segs_rec.segment_type));
          ELSE
            l_aff_dff_current_segment_id := l_aff_dff_current_segment_id + 1;
          END IF;

          p_je_lines_query_rec.condition_tab(l_jq_segs_cur%ROWCOUNT)  := NULL;

        -- Journal Entry Creation Date
        ELSIF  l_jq_segs_rec.segment_type = 'JECDATE'
        THEN
          p_je_lines_query_rec.create_date_from := NULL;
          p_je_lines_query_rec.create_date_to   := NULL;

        -- Journal Entry Posted Date
        ELSIF  l_jq_segs_rec.segment_type = 'JEPDATE'
        THEN
          p_je_lines_query_rec.posted_date_from := NULL;
          p_je_lines_query_rec.posted_date_to   := NULL;
        END IF;

      END LOOP;

  END set_query_condition;

  --==========================================================
  --Procedure Name: set_query_condition_local
  --Description: Set record for journal entry lines query
  --Note:
  --Parameter(s):
  --  p_je_lines_query_rec: Record for journal entry lines query
  --  p_query_id          : Query id
  --  p_journal_type      : Journal entry type
  --  p_budget_version_id : Budget version id
  --  p_posted            : Journal entry posted status(Posted)
  --  p_unposted          : Journal entry posted status(Unposted)
  --  p_postederror       : Journal entry posted status(Posted Error)
  --  p_period_from       : Accounting periods(From)
  --  p_period_to         : Accounting periods(To)
  --  p_effect_date_from  : Effective date(From)
  --  p_effect_date_to    : Effective date(To)
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_dr_from           : Debit amount of translated currency(From)
  --  p_dr_to             : Debit amount of translated currency(To)
  --  p_cr_from           : Credit amount of translated currency(From)
  --  p_cr_to             : Credit amount of translated currency(To)
  --  p_batch_description : Jornal entry batch description
  --  p_header_description: Jornal entry description
  --  p_line_description  : Jornal entry line description
  --  p_source            : Jornal entry source
  --  p_category          : Jornal entry category
  --  p_batch             : Jornal entry batch
  --  p_header_name       : Jornal entry header name
  --  p_condition         : Segment condition(AFF/DFF only)
  --  p_show_order        : Segment display order
  --  p_sort_order        : Segment sort order
  --  p_sort_method       : Segment sort method
  --  p_segment_type      : Segment type
  --  p_create_date_from  : Journal entry creation date(From)
  --  p_create_date_to    : Journal entry creation date(To)
  --  p_posted_date_from  : Journal entry posted date(From)
  --  p_posted_date_to    : Journal entry posted date(To)
  --  p_break_key         : Break key
  --  p_show_subtotalonly : Display subtotal only
  --  p_show_total        : Display total
  --  p_show_bringforward : Display bring forward
  --  p_result_format     : Result format
  --  p_file_name         : Filename
  --  p_description       : Description
  --==========================================================
  PROCEDURE set_query_condition_local(
    p_je_lines_query_rec OUT xgv_common.je_lines_query_rtype,
    p_query_id           IN  NUMBER,
    p_journal_type       IN  VARCHAR2,
    p_budget_version_id  IN  NUMBER,
    p_posted             IN  VARCHAR2,
    p_unposted           IN  VARCHAR2,
    p_postederror        IN  VARCHAR2,
    p_period_from        IN  NUMBER,
    p_period_to          IN  NUMBER,
    p_effect_date_from   IN  VARCHAR2,
    p_effect_date_to     IN  VARCHAR2,
    p_doc_seq_from       IN  NUMBER,
    p_doc_seq_to         IN  NUMBER,
    p_currency_code      IN  VARCHAR2,
    p_dr_from            IN  NUMBER,
    p_dr_to              IN  NUMBER,
    p_cr_from            IN  NUMBER,
    p_cr_to              IN  NUMBER,
    p_batch_description  IN  VARCHAR2,     /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    p_header_description IN  VARCHAR2,     /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    p_line_description   IN  VARCHAR2,
    p_source             IN  VARCHAR2,
    p_category           IN  VARCHAR2,
    p_batch              IN  VARCHAR2,
    p_header_name        IN  VARCHAR2,
    p_condition          IN  xgv_common.array_ttype,
    p_show_order         IN  xgv_common.array_ttype,
    p_sort_order         IN  xgv_common.array_ttype,
    p_sort_method        IN  xgv_common.array_ttype,
    p_segment_type       IN  xgv_common.array_ttype,
    p_create_date_from   IN  VARCHAR2,
    p_create_date_to     IN  VARCHAR2,
    p_posted_date_from   IN  VARCHAR2,
    p_posted_date_to     IN  VARCHAR2,
    p_break_key          IN  VARCHAR2,
    p_show_subtotalonly  IN  VARCHAR2,
    p_show_total         IN  VARCHAR2,
    p_show_bringforward  IN  VARCHAR2,
    p_result_format      IN  VARCHAR2,
    p_file_name          IN  VARCHAR2,
    p_description        IN  VARCHAR2)
  IS

    l_aff_dff_current_segment_id  PLS_INTEGER := 1;

  BEGIN

    IF  p_query_id IS NULL
    THEN
      p_je_lines_query_rec.query_id := NULL;
      p_je_lines_query_rec.query_name := NULL;
      p_je_lines_query_rec.creation_date := NULL;
      p_je_lines_query_rec.created_by := NULL;
      p_je_lines_query_rec.last_update_date := NULL;
      p_je_lines_query_rec.last_updated_by := NULL;

    -- Set WHO columns
    ELSE
      SELECT xq.query_id,
             xq.query_name,
             xq.creation_date,
             xq.created_by,
             xq.last_update_date,
             xq.last_updated_by
      INTO   p_je_lines_query_rec.query_id,
             p_je_lines_query_rec.query_name,
             p_je_lines_query_rec.creation_date,
             p_je_lines_query_rec.created_by,
             p_je_lines_query_rec.last_update_date,
             p_je_lines_query_rec.last_updated_by
      FROM   xgv_queries xq
      WHERE  xq.query_id = p_query_id;
    END IF;

    -- Set conditions
    p_je_lines_query_rec.je_type           := p_journal_type;
    p_je_lines_query_rec.budget_version_id := p_budget_version_id;
    p_je_lines_query_rec.break_key         := p_break_key;
    p_je_lines_query_rec.show_subtotalonly := p_show_subtotalonly;
    p_je_lines_query_rec.show_total        := p_show_total;
    p_je_lines_query_rec.show_bringforward := p_show_bringforward;
    p_je_lines_query_rec.result_format     := p_result_format;
    p_je_lines_query_rec.file_name         := p_file_name;
    p_je_lines_query_rec.description       := p_description;
    p_je_lines_query_rec.result_rows       := xgv_common.get_result_rows;

    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP

      -- Display Order, Sort Order, Sort Method, Segment Type
      p_je_lines_query_rec.show_order_tab(l_index)   := to_number(p_show_order(l_index));
      p_je_lines_query_rec.sort_order_tab(l_index)   := to_number(p_sort_order(l_index));
      p_je_lines_query_rec.sort_method_tab(l_index)  := p_sort_method(l_index);
      p_je_lines_query_rec.segment_type_tab(l_index) := p_segment_type(l_index);

      -- Header Refer, External Data Refer(Hidden items)
      IF  p_segment_type(l_index) IN ('DD', 'EXDD')
      THEN
        NULL;

      -- Accounting Periods
      ELSIF  p_segment_type(l_index) = 'ACTP'
      THEN
        p_je_lines_query_rec.period_from := p_period_from;
        p_je_lines_query_rec.period_to   := p_period_to;

      -- Journal Entry Effective Date
      ELSIF  p_segment_type(l_index) = 'JEEDATE'
      THEN
        p_je_lines_query_rec.effect_date_from := p_effect_date_from;
        p_je_lines_query_rec.effect_date_to   := p_effect_date_to;

      -- Journal Entry Post Status
      ELSIF  p_segment_type(l_index)  = 'POSTSTATUS'
      THEN
        p_je_lines_query_rec.posted := p_posted;
        p_je_lines_query_rec.unposted := p_unposted;
        p_je_lines_query_rec.postederror := p_postederror;

      -- Journal Entry Document Sequenctial Number
      ELSIF  p_segment_type(l_index) = 'JEDOCNUM'
      THEN
        p_je_lines_query_rec.doc_seq_from := p_doc_seq_from;
        p_je_lines_query_rec.doc_seq_to   := p_doc_seq_to;

      -- Currency
      ELSIF  p_segment_type(l_index) = 'CUR'
      THEN
        p_je_lines_query_rec.condition_tab(l_index) := p_currency_code;

      -- Debit Amount
      ELSIF  p_segment_type(l_index) = 'DR'
      THEN
        p_je_lines_query_rec.dr_from := p_dr_from;
        p_je_lines_query_rec.dr_to   := p_dr_to;

      -- Credit Amount
      ELSIF  p_segment_type(l_index) = 'CR'
      THEN
        p_je_lines_query_rec.cr_from := p_cr_from;
        p_je_lines_query_rec.cr_to   := p_cr_to;

      -- Journal Entry Batch Description
      /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
      ELSIF  p_segment_type(l_index) = 'BATCHDESC'
      THEN
        p_je_lines_query_rec.condition_tab(l_index) := p_batch_description;

      -- Journal Entry Description
      /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
      ELSIF  p_segment_type(l_index) = 'HEADERDESC'
      THEN
        p_je_lines_query_rec.condition_tab(l_index) := p_header_description;

      -- Journal Entry Line Description
      ELSIF  p_segment_type(l_index) = 'DESC'
      THEN
        p_je_lines_query_rec.condition_tab(l_index) := p_line_description;

      -- Journal Entry Source
      ELSIF  p_segment_type(l_index) = 'SOURCE'
      THEN
        p_je_lines_query_rec.condition_tab(l_index) := p_source;

      -- Journal Entry Category
      ELSIF  p_segment_type(l_index) = 'CATEGORY'
      THEN
        p_je_lines_query_rec.condition_tab(l_index) := p_category;

      -- Journal Entry Batch
      ELSIF  p_segment_type(l_index) = 'BATCH'
      THEN
        p_je_lines_query_rec.condition_tab(l_index) := p_batch;

      -- Journal Entry Header Name
      ELSIF  p_segment_type(l_index) = 'HEADER'
      THEN
        p_je_lines_query_rec.condition_tab(l_index) := p_header_name;

      -- AFF/DFF Segments
      ELSIF  xgv_common.is_number(p_segment_type(l_index))
      THEN
        IF  to_number(p_segment_type(l_index)) != l_aff_dff_current_segment_id
        THEN
          raise_application_error(-20111,
            xgv_common.get_message('XGV-20111', l_aff_dff_current_segment_id, p_segment_type(l_index)));
        ELSE
          l_aff_dff_current_segment_id := l_aff_dff_current_segment_id + 1;
        END IF;

        p_je_lines_query_rec.condition_tab(l_index) := p_condition(to_number(p_segment_type(l_index)));

      -- Journal Entry Creation Date
      ELSIF  p_segment_type(l_index) = 'JECDATE'
      THEN
        p_je_lines_query_rec.create_date_from := p_create_date_from;
        p_je_lines_query_rec.create_date_to   := p_create_date_to;

      -- Journal Entry Posted Date
      ELSIF  p_segment_type(l_index) = 'JEPDATE'
      THEN
        p_je_lines_query_rec.posted_date_from := p_posted_date_from;
        p_je_lines_query_rec.posted_date_to   := p_posted_date_to;
      END IF;

    END LOOP;

  END set_query_condition_local;

  --==========================================================
  --Procedure Name: set_drilldown_condition
  --Description: Set conditions for drilldown
  --Note:
  --Parameter(s):
  --  p_je_lines_query_rec: Record for journal entry lines query
  --  p_period_from       : Accounting periods(From)
  --  p_period_to         : Accounting periods(To)
  --  p_currency_code     : Currency
  --  p_show_dr_cr        : Display debit and credit
  --                        DR=>Debit side only, CR=>Credit side only
  --                        NULL=> Both
  --  p_condition         : Segment condition(AFF/DFF only)
  --  p_segment_type      : Segment type
  --  p_result_format     : Result format
  --  p_dd_template_id    : Drilldown template id
  --==========================================================
  PROCEDURE set_drilldown_condition(
    p_je_lines_query_rec OUT xgv_common.je_lines_query_rtype,
    p_period_from        IN  NUMBER,
    p_period_to          IN  NUMBER,
    p_currency_code      IN  VARCHAR2,
    p_show_dr_cr         IN  VARCHAR2 DEFAULT NULL,
    p_condition          IN  xgv_common.array_ttype,
    p_segment_type       IN  xgv_common.array_ttype,
    p_result_format      IN  VARCHAR2,
    p_dd_template_id     IN  NUMBER DEFAULT NULL)
  IS

    l_hide_flag  xgv_flex_structures_vl.hide_flag%TYPE;
    l_aff_show_order  PLS_INTEGER := 2;                        /* Bug#220027 20-Mar-2007 Changed by ytsujiha_jp */
    l_aff_segment_start_index  PLS_INTEGER;

  BEGIN

    set_query_condition(p_je_lines_query_rec, p_dd_template_id);

    -- Accounting Periods
    p_je_lines_query_rec.period_from := p_period_from;
    p_je_lines_query_rec.period_to   := p_period_to;

    -- Journal Entry Post Status
    p_je_lines_query_rec.posted      := 'Y';
    p_je_lines_query_rec.unposted    := 'N';
    p_je_lines_query_rec.postederror := 'N';

    -- Currency
    p_je_lines_query_rec.condition_tab(
      xgv_common.get_segment_index(p_je_lines_query_rec.segment_type_tab, 'CUR')) := p_currency_code;

    -- Display debit
    IF  p_show_dr_cr = 'DR'
    THEN
      /* Bug#220023 08-Mar-2007 Changed by ytsujiha_jp
      p_je_lines_query_rec.dr_from := -99999999999999;
      p_je_lines_query_rec.dr_to   := 999999999999999;
      */
      p_je_lines_query_rec.cr_from := 1;
      p_je_lines_query_rec.cr_to   := -1;

    -- Display credit
    ELSIF  p_show_dr_cr = 'CR'
    THEN
      /* Bug#220023 08-Mar-2007 Changed by ytsujiha_jp
      p_je_lines_query_rec.cr_from := -99999999999999;
      p_je_lines_query_rec.cr_to   := 999999999999999;
      */
      p_je_lines_query_rec.dr_from := 1;
      p_je_lines_query_rec.dr_to   := -1;
    END IF;

    -- Set default display order
    IF  p_dd_template_id IS NULL
    THEN
      p_je_lines_query_rec.show_order_tab(
        xgv_common.get_segment_index(p_je_lines_query_rec.segment_type_tab, 'JEEDATE')) := 1;

      /* Bug#220027 20-Mar-2007 Changed by ytsujiha_jp */
      IF  p_show_dr_cr = 'DR'
      OR  p_show_dr_cr IS NULL
      THEN
        p_je_lines_query_rec.show_order_tab(
          xgv_common.get_segment_index(p_je_lines_query_rec.segment_type_tab, 'DR')) := l_aff_show_order;
        l_aff_show_order := l_aff_show_order + 1;
      END IF;
      IF  p_show_dr_cr = 'CR'
      OR  p_show_dr_cr IS NULL
      THEN
        p_je_lines_query_rec.show_order_tab(
          xgv_common.get_segment_index(p_je_lines_query_rec.segment_type_tab, 'CR')) := l_aff_show_order;
        l_aff_show_order := l_aff_show_order + 1;
      END IF;

      l_aff_segment_start_index :=
        xgv_common.get_segment_index(p_je_lines_query_rec.segment_type_tab, p_segment_type(1));

      FOR  l_index IN l_aff_segment_start_index..p_je_lines_query_rec.segment_type_tab.COUNT
      LOOP
        SELECT hide_flag
        INTO   l_hide_flag
        FROM   xgv_flex_structures_vl xfsv
        WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
          AND  xfsv.application_id = xgv_common.get_gl_appl_id
          AND  xfsv.segment_id = to_number(p_je_lines_query_rec.segment_type_tab(l_index));

        IF  l_hide_flag = 'N'
        THEN
          p_je_lines_query_rec.show_order_tab(l_index) := l_aff_show_order;
          l_aff_show_order := l_aff_show_order + 1;
        END IF;
      END LOOP;
    END IF;

    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      IF  to_number(p_segment_type(l_index)) != l_index
      THEN
        raise_application_error(-20111,
          xgv_common.get_message('XGV-20111', l_index, p_segment_type(l_index)));
      END IF;

      /* Bug#220014 12-Nov-2006 Added by ytsujiha_jp */
      /* Bug#220021 26-Feb-2007 Changed(Delete) by ytsujiha_jp */
      p_je_lines_query_rec.condition_tab(
        xgv_common.get_segment_index(
          p_je_lines_query_rec.segment_type_tab, p_segment_type(l_index))) := p_condition(l_index);
    END LOOP;

    -- Display Total
    IF  p_dd_template_id IS NULL
    THEN
      p_je_lines_query_rec.show_total := 'Y';
    END IF;

    -- Result Format
    p_je_lines_query_rec.result_format := p_result_format;

  END set_drilldown_condition;

  --==========================================================
  --Procedure Name: show_side_navigator
  --Description: Display side navigator for Journal entry lines inquiry
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
        || get_tag('TEXT_NEW_CONDITION', 'E', 'javascript:gotoPage(''jq'');');

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
        || get_tag('TEXT_OPEN_CONDITION', 'E', 'javascript:gotoPage(''jq.open'');');

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
        || get_tag('TEXT_SAVE_CONDITION', 'E', 'javascript:requestSaveDialog(''UD'','
        || xgv_common.get_num_aff_segs || ');');

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
        || get_tag('TITLE_SAVEAS_CONDITION', 'E', 'javascript:requestSaveDialog(''ND'','
        || xgv_common.get_num_aff_segs || ');');

    ELSE
      l_side_nav := l_side_nav || get_tag('TITLE_SAVEAS_CONDITION', 'D');
    END IF;

    l_side_nav := l_side_nav || '</table>';

    xgv_common.show_side_navigation(l_side_nav);

  END show_side_navigator;

  --==========================================================
  --Procedure Name: show_query_editor
  --Description: Display condition editor for Journal entry lines inquiry
  --Note:
  --Parameter(s):
  --  p_modify_flag       : Modify flag(Yes/No)
  --  p_je_lines_query_rec: Query condition record
  --==========================================================
  PROCEDURE show_query_editor(
    p_modify_flag        IN VARCHAR2,
    p_je_lines_query_rec IN xgv_common.je_lines_query_rtype)
  IS

    l_parent_segment_id  xgv_flex_structures_vl.parent_segment_id%TYPE;
    l_show_lov_proc  xgv_flex_structures_vl.show_lov_proc%TYPE;
    l_hide_flag  xgv_flex_structures_vl.hide_flag%TYPE;
    l_mandatory_flag  xgv_flex_structures_vl.mandatory_flag%TYPE;
    l_aff_dff_current_segment_id  PLS_INTEGER := 1;

    CURSOR l_tag_breakkey_cur(p_default VARCHAR2 DEFAULT NULL)
    IS
      SELECT 1 order1,
             to_number(NULL) order2,
             '<option value=""' || decode(p_default, NULL, ' selected>', '>')
             || xgv_common.get_message('TEXT_NO_SELECT') output_string
      FROM   dual
      UNION  ALL
      SELECT 2 order1,
             xuiv.item_order order2,
             '<option value="' || xuiv.item_code
             || decode(xuiv.item_code, p_default, '" selected>', '">')
             || xuiv.meaning output_string
      FROM   xgv_usable_items_vl xuiv
      WHERE  xuiv.inquiry_type = 'J'
        AND  xuiv.enabled_flag = 'Y'
        AND  xuiv.is_break_key = 'Y'
      UNION ALL
      SELECT 3 order1,
             xfsv.segment_id order2,
             '<option value="' || to_char(xfsv.segment_id)
             || decode(to_char(xfsv.segment_id), p_default, '" selected>', '">')
             || xfsv.segment_name output_string
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
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

    PROCEDURE output_tag_show_order(
      p_show_order IN NUMBER DEFAULT NULL)
    IS
    BEGIN
      htp.p('<input type="text" name="p_show_order" size="4" maxlength="2"'
        ||  ' value="' || to_char(p_show_order) || '">');
    END output_tag_show_order;

    PROCEDURE output_tag_sort_order(
      p_sort_order  IN NUMBER   DEFAULT NULL,
      p_sort_method IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
      htp.p('<input type="text" name="p_sort_order" size="4" maxlength="2"'
        ||  ' value="' || to_char(p_sort_order) || '">');
      IF  p_sort_method IS NOT NULL
      THEN
        htp.p('<select name="p_sort_method">');
        htp.p('<option value="ASC"'
          ||  xgv_common.r_decode(p_sort_method,
                'ASC', ' selected>' || xgv_common.get_message('TEXT_SORT_METHOD_ASC'),
                '>' || xgv_common.get_message('TEXT_SORT_METHOD_ASC')));
        htp.p('<option value="DESC"'
          ||  xgv_common.r_decode(p_sort_method,
                'DESC', ' selected>' || xgv_common.get_message('TEXT_SORT_METHOD_DESC'),
                '>' || xgv_common.get_message('TEXT_SORT_METHOD_DESC')));
        htp.p('</select>');

      ELSE
        htp.p('<input type="hidden" name="p_sort_method" value="">');
      END IF;
    END output_tag_sort_order;

  BEGIN

    htp.p('<form name="f_query" method="post">');
    htp.p('<input type="hidden" name="p_mode">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_je_lines_query_rec.query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' || htf.escape_sc(p_je_lines_query_rec.query_name) || '">');

    htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">');

    htp.p('<tr>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td colspan="2" width="100%">');

    xgv_common.show_title(
      xgv_common.get_message('TITLE_CONDITION_NAME', nvl(p_je_lines_query_rec.query_name, ' ')),
      '<span class="OraTextInline">'
      || '<img src="/XGV_IMAGE/ii-required_status.gif">'
      || xgv_common.get_message('NOTE_MANDATORY_CONDITION'),
      p_fontsize=>'M');

    --------------------------------------------------
    -- Display query condition information
    --------------------------------------------------
    IF  p_je_lines_query_rec.query_name IS NOT NULL
    THEN
      htp.p('<table border="0" cellpadding="0" cellspacing="0">');

      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_CREATED_BY')
        ||  '</th>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<td class="OraDataText">'
        ||  xgv_common.escape_sc(xgv_common.get_user_name(p_je_lines_query_rec.created_by))
        ||  '</td>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_CREATION_DATE')
        ||  '</th>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<td class="OraDataText">' || p_je_lines_query_rec.creation_date || '</td>'
        ||  '</tr>');
      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_UPDATED_BY')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataText">'
        ||  xgv_common.escape_sc(xgv_common.get_user_name(p_je_lines_query_rec.last_updated_by))
        ||  '</td>'
        ||  '<td></td>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_UPDATE_DATE')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataText">' || p_je_lines_query_rec.last_update_date || '</td>'
        ||  '</tr>');
      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_COUNT_ROWS')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataNumber">' || to_char(p_je_lines_query_rec.result_rows, '999G999G999G990') || '</td>'
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

    -- Display line type
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
      ||  xgv_common.get_message('PROMPT_JOURNAL_TYPE')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_journal_type">');
    FOR  lookups_rec IN xgv_common.g_tag_lookups_cur('JE_TYPE', p_je_lines_query_rec.je_type)
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
    FOR  l_budget_rec IN xgv_common.g_tag_budget_cur(p_je_lines_query_rec.budget_version_id)
    LOOP
      htp.p(l_budget_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '</td>'
      ||  '</tr>');

    htp.p('</table>');

    --------------------------------------------------
    -- Display AFF/DFF and other segment conditions
    --------------------------------------------------
    htp.p('<table style="border-collapse:collapse" cellpadding="1" cellspacing="0">');

    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_LINE_AFF_DFF_CONDITIONS'), p_fontsize=>'S');
    htp.p('</th>'
      ||  '</tr>');

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
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_SEGMENT_SORT_ORDER')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #cccc99" width="100%"></th>'
      ||  '</tr>');

    -- Display each segment
    FOR  l_index IN 1..p_je_lines_query_rec.segment_type_tab.COUNT
    LOOP

      -- Header Refer, External Data Refer(Hidden items)
      IF  p_je_lines_query_rec.segment_type_tab(l_index) IN ('DD', 'EXDD')
      THEN
        htp.p('<input type="hidden" name="p_show_order" value="'
          ||  p_je_lines_query_rec.show_order_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_sort_order" value="'
          ||  p_je_lines_query_rec.sort_order_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_sort_method" value="'
          ||  p_je_lines_query_rec.sort_method_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_segment_type" value="'
          ||  p_je_lines_query_rec.segment_type_tab(l_index) || '">');

      -- Accounting Periods
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'ACTP'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'ACTP'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>');
        htp.p('<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<select name="p_period_from" onChange="validatePeriod(this)">');
        FOR  l_period_rec IN xgv_common.g_tag_period_cur('FROM', p_je_lines_query_rec.period_from)
        LOOP
          htp.p(l_period_rec.output_string);
        END LOOP;
        htp.p('</select>'
          ||  '</td>');
        htp.p('<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<select name="p_period_to" onChange="validatePeriod(this)">');
        FOR  l_period_rec IN xgv_common.g_tag_period_cur('TO', p_je_lines_query_rec.period_to)
        LOOP
          htp.p(l_period_rec.output_string);
        END LOOP;
        htp.p('</select>'
          ||  '</td>');
        htp.p('</tr>'
          ||  '</table>');
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          nvl(p_je_lines_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="ACTP">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Effective Date
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEEDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'JEEDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_effect_date_from" size="20" maxlength="11" value="'
          ||  p_je_lines_query_rec.effect_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Effectdate_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_effect_date_to" size="20" maxlength="11" value="'
          ||  p_je_lines_query_rec.effect_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Effectdate_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          nvl(p_je_lines_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="JEEDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Post Status
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'POSTSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_posted" value="Y"'
          ||  xgv_common.r_decode(p_je_lines_query_rec.posted, 'Y', ' checked>', '>')
          ||  xgv_common.get_message('PROMPT_POSTED')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_unposted" value="Y"'
          ||  xgv_common.r_decode(p_je_lines_query_rec.unposted, 'Y', ' checked>', '>')
          ||  xgv_common.get_message('PROMPT_UNPOSTED')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_postederror" value="Y"'
          ||  xgv_common.r_decode(p_je_lines_query_rec.postederror, 'Y', ' checked>', '>')
          ||  xgv_common.get_message('PROMPT_POSTED_ERROR')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          p_je_lines_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="POSTSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Document Sequenctial Number
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEDOCNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'JEDOCNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_doc_seq_from" size="20" maxlength="11" value="'
          ||  p_je_lines_query_rec.doc_seq_from
          ||  '">'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_doc_seq_to" size="20" maxlength="11" value="'
          ||  p_je_lines_query_rec.doc_seq_to
          ||  '">'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          nvl(p_je_lines_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="JEDOCNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Currency
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'CUR'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'CUR'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<select name="p_currency_code">');
        FOR  l_currency_rec IN xgv_common.g_tag_currency_cur(p_je_lines_query_rec.condition_tab(l_index))
        LOOP
          htp.p(l_currency_rec.output_string);
        END LOOP;
        htp.p('</select>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          p_je_lines_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="CUR">');
        IF  xgv_common.get_profile_option_value('XGV_ENABLE_SHOW_JE_LINES_RATE') = 'Y'
        THEN
          htp.p('<input type="hidden" name="p_show_order" value="">'
            ||  '<input type="hidden" name="p_sort_order" value="">'
            ||  '<input type="hidden" name="p_sort_method" value="">'
            ||  '<input type="hidden" name="p_segment_type" value="TRANSDATE">');
          htp.p('<input type="hidden" name="p_show_order" value="">'
            ||  '<input type="hidden" name="p_sort_order" value="">'
            ||  '<input type="hidden" name="p_sort_method" value="">'
            ||  '<input type="hidden" name="p_segment_type" value="TRANSTYPE">');
          htp.p('<input type="hidden" name="p_show_order" value="">'
            ||  '<input type="hidden" name="p_sort_order" value="">'
            ||  '<input type="hidden" name="p_sort_method" value="">'
            ||  '<input type="hidden" name="p_segment_type" value="TRANSRATE">');
        END IF;
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="ENTERDR">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="ENTERCR">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="ENTERBAL">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Debit Amount
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'DR'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'DR'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_dr_from" size="20" maxlength="15" value="'
          ||  p_je_lines_query_rec.dr_from
          ||  '">'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_dr_to" size="20" maxlength="15" value="'
          ||  p_je_lines_query_rec.dr_to
          ||  '">'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          nvl(p_je_lines_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="DR">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Credit Amount
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'CR'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'CR'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_cr_from" size="20" maxlength="15" value="'
          ||  p_je_lines_query_rec.cr_from
          ||  '">'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_cr_to" size="20" maxlength="15" value="'
          ||  p_je_lines_query_rec.cr_to
          ||  '">'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          nvl(p_je_lines_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="CR">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Balance Amount
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'BALANCE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'BALANCE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          nvl(p_je_lines_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="BALANCE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Batch Description
      /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'BATCHDESC'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'BATCHDESC'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_batch_description" size="60" maxlength="240" value="'
          ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="BATCHDESC">'
          ||  '</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Description
      /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'HEADERDESC'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'HEADERDESC'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_header_description" size="60" maxlength="240" value="'
          ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="HEADERDESC">'
          ||  '</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Line Description
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'DESC'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'DESC'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_line_description" size="60" maxlength="240" value="'
          ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="DESC">'
          ||  '</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Source
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'SOURCE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'SOURCE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_source" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestSources_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          p_je_lines_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="SOURCE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Category
      ELSIF p_je_lines_query_rec.segment_type_tab(l_index) = 'CATEGORY'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'CATEGORY'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_category" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestCategories_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          p_je_lines_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="CATEGORY">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Batch
      ELSIF p_je_lines_query_rec.segment_type_tab(l_index) = 'BATCH'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'BATCH'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_batch" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestBatches_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          p_je_lines_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="BATCH">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Header Name
      ELSIF p_je_lines_query_rec.segment_type_tab(l_index) = 'HEADER'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'HEADER'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_header_name" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestHeaderNames_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          p_je_lines_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="HEADER">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- AFF/DFF Segments
      ELSIF  xgv_common.is_number(p_je_lines_query_rec.segment_type_tab(l_index))
      THEN
        IF  p_je_lines_query_rec.segment_type_tab(l_index) != to_char(l_aff_dff_current_segment_id)
        THEN
          raise_application_error(-20111,
            xgv_common.get_message('XGV-20111',
              xgv_common.get_sob_id, NULL, l_aff_dff_current_segment_id, p_je_lines_query_rec.segment_type_tab(l_index)));
        ELSE
          l_aff_dff_current_segment_id := l_aff_dff_current_segment_id + 1;
        END IF;

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
          AND  xfsv.segment_id = to_number(p_je_lines_query_rec.segment_type_tab(l_index));

        IF  l_hide_flag = 'N'
        THEN
          htp.p('<tr>');
          htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
            ||  xgv_common.r_decode(l_mandatory_flag,
                  'Y', '<img src="/XGV_IMAGE/ii-required_status.gif">', NULL)
            ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_je_lines_query_rec.segment_type_tab(l_index)))
            ||  '</td>');
          htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
            ||  '<input type="text" name="p_condition" size="60" maxlength="1999" value="'
            ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index)) || '">'
            ||  xgv_common.r_nvl2(l_show_lov_proc,
                  '<a href="javascript:requestAFF_LOV('
                  ||  p_je_lines_query_rec.segment_type_tab(l_index) || ', ' || l_parent_segment_id || ')">'
                  ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
                  ||  '</a>',
                  '<img src="/XGV_IMAGE/ai-search_disabled.gif" border="0">')
            ||  '</td>');
          htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
          output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
          htp.p('</td>');
          htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
          output_tag_sort_order(
            p_je_lines_query_rec.sort_order_tab(l_index),
            p_je_lines_query_rec.sort_method_tab(l_index));
          htp.p('<input type="hidden" name="p_segment_type" value="'
            ||  p_je_lines_query_rec.segment_type_tab(l_index) || '">');
          htp.p('</td>');
          htp.p('<td></td>');
          htp.p('</tr>');

        ELSE
          htp.p('<input type="hidden" name="p_condition" value="'
            ||  htf.escape_sc(p_je_lines_query_rec.condition_tab(l_index)) || '">'
            ||  '<input type="hidden" name="p_show_order" value="">'
            ||  '<input type="hidden" name="p_sort_order" value="">'
            ||  '<input type="hidden" name="p_sort_method" value="">'
            ||  '<input type="hidden" name="p_segment_type" value="'
            ||  p_je_lines_query_rec.segment_type_tab(l_index) || '">');
        END IF;
      END IF;

    END LOOP;

    --------------------------------------------------
    -- Display creation date and posted date conditions
    --------------------------------------------------
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_DATE_CONDITIONS'), p_fontsize=>'S');
    htp.p('</th>'
      ||  '</tr>');

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
      ||  '<th style="border-left:1px solid #f7f7e7" class="OraTableColumnHeader" nowrap>'
      ||  xgv_common.get_message('PROMPT_SEGMENT_SORT_ORDER')
      ||  '</th>'
      ||  '<th style="border-left:1px solid #cccc99" width="100%"></th>'
      ||  '</tr>');

    -- Display each segment
    FOR  l_index IN 1..p_je_lines_query_rec.segment_type_tab.COUNT
    LOOP

      -- Journal Entry Creation Date
      IF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JECDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'JECDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_create_date_from" size="20" maxlength="11" value="'
          ||  p_je_lines_query_rec.create_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Creation_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  '<script>t(24, 0);</script>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_create_date_to" size="20" maxlength="11" value="'
          ||  p_je_lines_query_rec.create_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Creation_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          nvl(p_je_lines_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="JECDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Journal Entry Posted Date
      ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEPDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('J', 'JEPDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_posted_date_from" size="20" maxlength="11" value="'
          ||  p_je_lines_query_rec.posted_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Posted_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  '<script>t(24, 0);</script>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_posted_date_to" size="20" maxlength="11" value="'
          ||  p_je_lines_query_rec.posted_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Posted_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_je_lines_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_je_lines_query_rec.sort_order_tab(l_index),
          nvl(p_je_lines_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="JEPDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');
      END IF;

    END LOOP;

    htp.p('</table>');

    --------------------------------------------------
    -- Display summary option
    --------------------------------------------------
    htp.prn('<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_SUMMARY_OPTIONS'), p_fontsize=>'S');

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');

    -- Display summary segment and Display subtotal line only
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_SUBTOTAL_ITEM')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_break_key">');
    FOR  l_break_key_rec IN l_tag_breakkey_cur(p_je_lines_query_rec.break_key)
    LOOP
      htp.p(l_break_key_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="checkbox" name="p_show_subtotalonly" value="Y"'
      ||  xgv_common.r_decode(p_je_lines_query_rec.show_subtotalonly, 'Y', ' checked>', '>')
      ||  xgv_common.get_message('PROMPT_SHOW_SUBTOTAL_ONLY')
      ||  '</td>'
      ||  '</tr>');

    -- Display total
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_SHOW_TOTAL')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText" nowrap>'
      ||  '<input type="checkbox" name="p_show_total" value="Y"'
      ||  xgv_common.r_decode(p_je_lines_query_rec.show_total, 'Y', ' checked>', '>')
      ||  '</td>'
      ||  '</tr>');

    -- Display bring forward line
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_SHOW_BRINGFORWARD')
      ||  '</th>'
      ||  '<td></td>'
      ||  '<td class="OraDataText">'
      ||  '<input type="checkbox" name="p_show_bringforward" value="Y"'
      ||  xgv_common.r_decode(p_je_lines_query_rec.show_bringforward, 'Y', ' checked>', '>')
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
    FOR  l_tag_result_format_rec IN l_tag_result_format_cur(p_je_lines_query_rec.result_format)  /* 13-May-2005 Changed by ytsujiha_jp */
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
      ||  htf.escape_sc(p_je_lines_query_rec.file_name) || '">'
      ||  '</td>'
      ||  '</tr>'
      ||  '<tr>'
      ||  '<td colspan="2"></td>'
      ||  '<td>');
    xgv_common.show_tip('TIP_FILENAME');
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
  --Description: Display condition editor for Journal entry lines inquiry
  --Note:
  --Parameter(s):
  --  p_mode              : Display mode
  --                        (Editor/execute Background query/
  --                         count Rows/Save confirm/save Cancel/
  --                         Drilldown)
  --  p_modify_flag       : Modify flag(Yes/No)
  --  p_query_id          : Query id
  --  p_query_name        : Query name
  --  p_journal_type      : Journal entry line type
  --  p_budget_version_id : Budget version id
  --  p_posted            : Journal entry posted status(Posted)
  --  p_unposted          : Journal entry posted status(Unposted)
  --  p_postederror       : Journal entry posted status(Posted Error)
  --  p_period_from       : Accounting periods(From)
  --  p_period_to         : Accounting periods(To)
  --  p_effect_date_from  : Effective date(From)
  --  p_effect_date_to    : Effective date(To)
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_dr_from           : Debit amount of translated currency(From)
  --  p_dr_to             : Debit amount of translated currency(To)
  --  p_cr_from           : Credit amount of translated currency(From)
  --  p_cr_to             : Credit amount of translated currency(To)
  --  p_batch_description : Jornal entry batch description
  --  p_header_description: Jornal entry description
  --  p_line_description  : Jornal entry description
  --  p_source            : Jornal entry source
  --  p_category          : Jornal entry category
  --  p_batch             : Jornal entry batch
  --  p_header_name       : Jornal entry header name
  --  p_condition         : Segment condition(AFF/DFF only)
  --  p_show_order        : Segment display order
  --  p_sort_order        : Segment sort order
  --  p_sort_method       : Segment sort method
  --  p_segment_type      : Segment type
  --  p_create_date_from  : Journal entry creation date(From)
  --  p_create_date_to    : Journal entry creation date(To)
  --  p_posted_date_from  : Journal entry posted date(From)
  --  p_posted_date_to    : Journal entry posted date(To)
  --  p_break_key         : Break key
  --  p_show_subtotalonly : Display subtotal only
  --  p_show_total        : Display total
  --  p_show_bringforward : Display bring forward
  --  p_result_format     : Result format
  --  p_file_name         : Filename
  --  p_show_dr_cr        : Display debit and credit
  --                        (Drilldown is used)
  --                        DR=>Debit side only, CR=>Credit side only
  --                        NULL=> Both
  --  p_direct_drilldown  : Direct drilldown mode
  --                        (Drilldown is used)
  --                        Y=> Direct drilldown
  --==========================================================
  PROCEDURE top(
    p_mode               IN VARCHAR2 DEFAULT 'E',
    p_modify_flag        IN VARCHAR2 DEFAULT 'N',
    p_query_id           IN NUMBER   DEFAULT NULL,
    p_async_query_id     IN NUMBER   DEFAULT NULL,
    p_query_name         IN VARCHAR2 DEFAULT NULL,
    p_journal_type       IN VARCHAR2 DEFAULT NULL,
    p_budget_version_id  IN NUMBER   DEFAULT NULL,
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_postederror        IN VARCHAR2 DEFAULT 'N',
    p_period_from        IN NUMBER   DEFAULT NULL,
    p_period_to          IN NUMBER   DEFAULT NULL,
    p_effect_date_from   IN VARCHAR2 DEFAULT NULL,
    p_effect_date_to     IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_dr_from            IN NUMBER   DEFAULT NULL,
    p_dr_to              IN NUMBER   DEFAULT NULL,
    p_cr_from            IN NUMBER   DEFAULT NULL,
    p_cr_to              IN NUMBER   DEFAULT NULL,
    p_batch_description  IN VARCHAR2 DEFAULT NULL,     /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    p_header_description IN VARCHAR2 DEFAULT NULL,     /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    p_line_description   IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_category           IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_header_name        IN VARCHAR2 DEFAULT NULL,
    p_condition          IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_show_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_method        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type       IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_create_date_from   IN VARCHAR2 DEFAULT NULL,
    p_create_date_to     IN VARCHAR2 DEFAULT NULL,
    p_posted_date_from   IN VARCHAR2 DEFAULT NULL,
    p_posted_date_to     IN VARCHAR2 DEFAULT NULL,
    p_break_key          IN VARCHAR2 DEFAULT NULL,
    p_show_subtotalonly  IN VARCHAR2 DEFAULT 'N',
    p_show_total         IN VARCHAR2 DEFAULT 'N',
    p_show_bringforward  IN VARCHAR2 DEFAULT 'N',
    p_result_format      IN VARCHAR2 DEFAULT NULL,
    p_file_name          IN VARCHAR2 DEFAULT NULL,
    p_show_dr_cr         IN VARCHAR2 DEFAULT NULL,
    p_direct_drilldown   IN VARCHAR2 DEFAULT 'N')
  IS

    l_je_lines_query_rec  xgv_common.je_lines_query_rtype;
    l_dummy1  NUMBER;
    l_dummy2  NUMBER;

    CURSOR l_mandatory_flag_cur
    IS
      SELECT xfsv.mandatory_flag mandatory_flag
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
      ORDER BY xfsv.segment_id;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('JQ.TOP');

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
        htp.p('<form name="f_refresh" method="post" action="./xgv_jq.top"></form>');
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
      set_query_condition(l_je_lines_query_rec, p_query_id);

    -- Count rows
    ELSIF  p_mode = 'R'
    THEN
      -- Count rows
      xgv_common.open_output_dest('W');
      xgv_je.execute_sql(
        p_query_id, p_query_name, p_journal_type, p_budget_version_id,
        p_posted, p_unposted, p_postederror, NULL,
        p_period_from, p_period_to, p_effect_date_from, p_effect_date_to,
        p_doc_seq_from, p_doc_seq_to, p_currency_code,
        p_dr_from, p_dr_to, p_cr_from, p_cr_to,
        p_batch_description, p_header_description, p_line_description,         /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
        p_source, p_category, p_batch, p_header_name,
        p_condition, p_show_order, p_sort_order, p_sort_method, p_segment_type,
        p_create_date_from, p_create_date_to, p_posted_date_from, p_posted_date_to,
        NULL, 'N', 'N', 'N', 'COUNT', NULL, l_dummy1, l_dummy2);

      -- Set query condition
      set_query_condition_local(
        l_je_lines_query_rec, p_query_id, p_journal_type, p_budget_version_id,
        p_posted, p_unposted, p_postederror,
        p_period_from, p_period_to, p_effect_date_from, p_effect_date_to,
        p_doc_seq_from, p_doc_seq_to, p_currency_code,
        p_dr_from, p_dr_to, p_cr_from, p_cr_to,
        p_batch_description, p_header_description, p_line_description,         /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
        p_source, p_category, p_batch, p_header_name,
        p_condition, p_show_order, p_sort_order, p_sort_method, p_segment_type,
        p_create_date_from, p_create_date_to, p_posted_date_from, p_posted_date_to,
        p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
        p_result_format, p_file_name, NULL);

    -- Drilldown
    ELSIF  p_mode = 'D'
    THEN
      set_drilldown_condition(
        l_je_lines_query_rec, p_period_from, p_period_to,
        p_currency_code, p_show_dr_cr,
        p_condition, p_segment_type, p_result_format, p_query_id);

    ELSE
      set_query_condition_local(
        l_je_lines_query_rec, p_query_id, p_journal_type, p_budget_version_id,
        p_posted, p_unposted, p_postederror,
        p_period_from, p_period_to, p_effect_date_from, p_effect_date_to,
        p_doc_seq_from, p_doc_seq_to, p_currency_code,
        p_dr_from, p_dr_to, p_cr_from, p_cr_to,
        p_batch_description, p_header_description, p_line_description,         /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
        p_source, p_category, p_batch, p_header_name,
        p_condition, p_show_order, p_sort_order, p_sort_method, p_segment_type,
        p_create_date_from, p_create_date_to, p_posted_date_from, p_posted_date_to,
        p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
        p_result_format, p_file_name, NULL);
    END IF;

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
    htp.p('<script language="JavaScript">');
    htp.p('<!--');
    htp.p('window.name = "xgv_main";');
    htp.p('// -->');
    htp.p('</script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_JE_LINES_INQUIRY', xgv_common.get_resp_name) || '</title>');
    htp.p('</head>');

    -- No direct drilldown
    IF  p_direct_drilldown = 'N'
    THEN
      htp.p('<body class="OraBody" onLoad="window.focus();">');
    ELSE
      /* Req#230010 12-Dec-2007 Changed by ytsujiha_jp */
      htp.p('<body class="OraBody" onLoad="javascript:requestExecute('''
        ||  xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'), 'N', 'S', 'A')
        ||  ''',' ||  xgv_common.get_num_aff_segs || ');">');
    END IF;

    -- Display Header
    xgv_common.show_header(
      xgv_common.get_global_buttons_tag('MAIN'),
      xgv_common.get_tabs_tag('JQ'));

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
        'MESSAGE_COUNT_ROWS', ltrim(to_char(l_je_lines_query_rec.result_rows, '999G999G999G990')));

    -- Display svae confirmation message
    ELSIF  p_mode = 'S'
    THEN
      htp.prn('<script>t(1, 7);</script>');
      xgv_common.show_messagebox('C', 'MESSAGE_SAVE_CONDITION');
    END IF;

    -- Display title
    htp.prn('<script>t(1, 7);</script>');
    xgv_common.show_title(
      xgv_common.get_message('TITLE_JE_LINES_INQUIRY', xgv_common.get_resp_name),
      NULL,
      xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'),
        'N', '<a href="javascript:requestExecute(''S'',' || xgv_common.get_num_aff_segs || ');">'
             || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-sync_enabled.gif" border="0">'
             || '</a>'
             || '<script>t(8, 1);</script>', NULL)          /* Req#230010 12-Dec-2007 Changed by ytsujiha_jp */
      || '<a href="javascript:requestExecute(''A'',' || xgv_common.get_num_aff_segs || ');">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-async_enabled.gif" border="0">'
      || '</a>'
      || xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'),
           'N', '<script>t(8, 1);</script>'
                || '<a href="javascript:requestCountRows(' || xgv_common.get_num_aff_segs || ');">'
                || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-countrows_enabled.gif" border="0">'
                || '</a>', NULL));

    /* Bug#200022 16-Jun-2004 Changed by ytsujiha_jp */
    show_query_editor(p_modify_flag, l_je_lines_query_rec);

    htp.p('</td>');

    htp.p('</tr>');
    htp.p('</table>');

    -- Display footer
    xgv_common.show_footer(
      xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'),
        'N', '<a href="javascript:requestExecute(''S'',' || xgv_common.get_num_aff_segs || ');">'
             || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-sync_enabled.gif" border="0">'
             || '</a>'
             || '<script>t(8, 1);</script>', NULL)          /* Req#230010 12-Dec-2007 Changed by ytsujiha_jp */
      || '<a href="javascript:requestExecute(''A'',' || xgv_common.get_num_aff_segs || ');">'
      || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-async_enabled.gif" border="0">'
      || '</a>'
      || xgv_common.r_decode(nvl(xgv_common.get_profile_option_value('XGV_DISABLE_ONLINE_SEARCH'), 'N'),
           'N', '<script>t(8, 1);</script>'
                || '<a href="javascript:requestCountRows(' || xgv_common.get_num_aff_segs || ');">'
                || '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-countrows_enabled.gif" border="0">'
                || '</a>', NULL));

    htp.p('<form name="f_mandatory_flag">');
    FOR  l_mandatory_flag_rec IN l_mandatory_flag_cur
    LOOP
    htp.p('<input type="hidden" name="p_mandatory_flag" value="'
      ||  l_mandatory_flag_rec.mandatory_flag
      ||  '">');
    END LOOP;
    htp.p('</form>');

    htp.p('<form name="f_datepick" method="post" action="./xgv_common.show_datepicker" target="xgv_datepick">');
    htp.p('<input type="hidden" name="p_title_id" value="">');
    htp.p('<input type="hidden" name="p_period" value="">');
    htp.p('<input type="hidden" name="p_year" value="' || to_char(sysdate, 'RRRR') ||'">');  /* Bug#200025 02-Aug-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_month" value="' || to_char(sysdate, 'MM') ||'">');   /* Bug#200025 02-Aug-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_element_id" value="">');
    htp.p('<input type="hidden" name="p_date_mask" value="' || xgv_common.get_date_mask || '">');
    htp.p('</form>');

    htp.p('<form name="f_lov_sources" method="post" action="./xgv_jq.show_lov_sources" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_categories" method="post" action="./xgv_jq.show_lov_categories" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_batches" method="post" action="./xgv_jq.show_lov_batches" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_posted" value="">');
    htp.p('<input type="hidden" name="p_unposted" value="">');
    htp.p('<input type="hidden" name="p_postederror" value="">');
    htp.p('<input type="hidden" name="p_period_from" value="">');
    htp.p('<input type="hidden" name="p_period_to" value="">');
    htp.p('<input type="hidden" name="p_currency_code" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_headernames" method="post" action="./xgv_jq.show_lov_header_names" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_posted" value="">');
    htp.p('<input type="hidden" name="p_unposted" value="">');
    htp.p('<input type="hidden" name="p_postederror" value="">');
    htp.p('<input type="hidden" name="p_period_from" value="">');
    htp.p('<input type="hidden" name="p_period_to" value="">');
    htp.p('<input type="hidden" name="p_effect_date_from" value="">');
    htp.p('<input type="hidden" name="p_effect_date_to" value="">');
    htp.p('<input type="hidden" name="p_currency_code" value="">');
    htp.p('<input type="hidden" name="p_source" value="">');
    htp.p('<input type="hidden" name="p_category" value="">');
    htp.p('<input type="hidden" name="p_batch" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_aff" method="post" action="./xgv_jq.show_lov_aff" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_child_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_condition" value="">');
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
  --Procedure Name: show_lov_sources
  --Description: Display LOV for sources
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_sources(
    p_list_filter_item  IN VARCHAR2 DEFAULT 'VALUE',
    p_list_filter_value IN VARCHAR2 DEFAULT NULL,
    p_start_listno      IN NUMBER   DEFAULT 1,
    p_sort_item         IN VARCHAR2 DEFAULT 'VALUE',
    p_sort_method       IN VARCHAR2 DEFAULT 'ASC')
  IS

    l_sql_rec  xgv_common.sql_rtype;
    l_count_sql  VARCHAR2(32767);
    l_list_sql  VARCHAR2(32767);

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('JQ.SHOW_LOV_SOURCES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_SOURCES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_source.value">');

    l_sql_rec.text(1) := 'SELECT count(gjsv.je_source_name)';
    l_sql_rec.text(2) := 'FROM   gl_je_sources_vl gjsv';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'WHERE (';
        xgv_common.get_where_clause(
          l_sql_rec, 'gjsv', 'user_je_source_name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'WHERE upper(gjsv.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    -- Output debug information(SQL statement)
    xgv_common.show_sql_statement(l_sql_rec);

    l_sql_rec.text(1) := 'SELECT gjsv.user_je_source_name, gjsv.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY gjsv.user_je_source_name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY gjsv.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    -- Output debug information(SQL statement)
    xgv_common.show_sql_statement(l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_SOURCES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_jq.show_lov_sources', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addSourcesValue();');

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

  END show_lov_sources;

  --==========================================================
  --Procedure Name: show_lov_categories
  --Description: Display LOV for categories
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_categories(
    p_list_filter_item  IN VARCHAR2 DEFAULT 'VALUE',
    p_list_filter_value IN VARCHAR2 DEFAULT NULL,
    p_start_listno      IN NUMBER   DEFAULT 1,
    p_sort_item         IN VARCHAR2 DEFAULT 'VALUE',
    p_sort_method       IN VARCHAR2 DEFAULT 'ASC')
  IS

    l_sql_rec  xgv_common.sql_rtype;
    l_count_sql  VARCHAR2(32767);
    l_list_sql  VARCHAR2(32767);

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('JQ.SHOW_LOV_CATEGORIES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_CATEGORIES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_category.value">');

    l_sql_rec.text(1) := 'SELECT count(gjcv.je_category_name)';
    l_sql_rec.text(2) := 'FROM   gl_je_categories_vl gjcv';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'WHERE (';
        xgv_common.get_where_clause(
          l_sql_rec, 'gjcv', 'user_je_category_name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'WHERE upper(gjcv.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    -- Output debug information(SQL statement)
    xgv_common.show_sql_statement(l_sql_rec);

    l_sql_rec.text(1) := 'SELECT gjcv.user_je_category_name, gjcv.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY gjcv.user_je_category_name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY gjcv.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    -- Output debug information(SQL statement)
    xgv_common.show_sql_statement(l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_CATEGORIES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_jq.show_lov_categories', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addCategoriesValue();');

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

  END show_lov_categories;

  --==========================================================
  --Procedure Name: show_lov_batches
  --Description: Display LOV for batches
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --  p_posted           : Journal entry posted
  --  p_unposted         : Journal entry unposted
  --  p_period_from      : Accounting periods(From)
  --  p_period_to        : Accounting periods(To)
  --  p_postederror      : Jounal entry posted error
  --  p_currency_code    : Currency code
  --==========================================================
  PROCEDURE show_lov_batches(
    p_list_filter_item  IN VARCHAR2 DEFAULT 'VALUE',
    p_list_filter_value IN VARCHAR2 DEFAULT NULL,
    p_start_listno      IN NUMBER   DEFAULT 1,
    p_sort_item         IN VARCHAR2 DEFAULT 'VALUE',
    p_sort_method       IN VARCHAR2 DEFAULT 'ASC',
    p_posted            IN VARCHAR2 DEFAULT 'N',
    p_unposted          IN VARCHAR2 DEFAULT 'N',
    p_postederror       IN VARCHAR2 DEFAULT 'N',
    p_period_from       IN NUMBER   DEFAULT NULL,
    p_period_to         IN NUMBER   DEFAULT NULL,
    p_currency_code     IN VARCHAR2 DEFAULT NULL)
  IS

    -- Absolute accounting periods
    l_abs_period_from  gl_period_statuses.effective_period_num%TYPE;
    l_abs_period_to    gl_period_statuses.effective_period_num%TYPE;

    l_sql_rec  xgv_common.sql_rtype;
    l_count_sql  VARCHAR2(32767);
    l_list_sql  VARCHAR2(32767);

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('JQ.SHOW_LOV_BATCHES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_BATCHES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_batch.value">');

    -- Relative periods to Absolute periods
    l_abs_period_from := nvl(xgv_common.convert_relative_period(p_period_from), 0);
    l_abs_period_to   := nvl(xgv_common.convert_relative_period(p_period_to), 99999999);

    /* Bug#200031 21-Oct-2004 Changed by ytsujiha_jp */
    l_sql_rec.text(1) := 'SELECT count(distinct gjb.name)';
    l_sql_rec.text(2) := 'FROM   gl_je_batches gjb, gl_period_statuses gps, gl_je_headers gjh';
    l_sql_rec.text(3) := 'WHERE  gps.application_id = xgv_common.get_gl_appl_id';
    l_sql_rec.text(4) := '  AND  gps.set_of_books_id = xgv_common.get_sob_id';
    xgv_common.set_bind_value(l_sql_rec, l_abs_period_from);
    xgv_common.set_bind_value(l_sql_rec, l_abs_period_to);
    l_sql_rec.text(5) := '  AND  gps.effective_period_num '
      || 'BETWEEN :' || l_sql_rec.ph_name(l_sql_rec.num_ph - 1)
      || ' AND :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
    l_sql_rec.text(6) := '  AND  gjb.set_of_books_id = gps.set_of_books_id';
    l_sql_rec.text(7) := '  AND  gjb.default_period_name = gps.period_name';

    IF  (p_posted = 'Y' OR p_unposted = 'Y')
    AND p_postederror = 'N'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
        '  AND  gjb.status IN ('
        || xgv_common.r_decode(p_posted, 'Y', '''P''', NULL)
        || xgv_common.r_decode(p_unposted,
             'Y', xgv_common.r_decode(p_posted, 'Y', ',', NULL) || '''U'',''I'',''S''', NULL)
        || ')';
    ELSIF  p_postederror = 'Y'
    AND (p_posted = 'N' OR p_unposted = 'N')
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
        '  AND  gjb.status NOT IN ('
        || xgv_common.r_decode(p_posted, 'Y', '''U'',''I'',''S''', NULL)
        || xgv_common.r_decode(p_unposted,
             'Y', xgv_common.r_decode(p_posted, 'Y', ',', NULL) || '''P''', NULL)
        || xgv_common.r_decode(p_posted, 'N',
             xgv_common.r_decode(p_unposted, 'N', '''P'',''U'',''I'',''S''', NULL), NULL)
        || ')';
    END IF;

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  (';
        xgv_common.get_where_clause(
          l_sql_rec, 'gjb', 'name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '       )';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND  upper(gjb.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.set_of_books_id = gjb.set_of_books_id';
    l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.period_name = gjb.default_period_name';
    l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.je_batch_id = gjb.je_batch_id';

    IF  p_currency_code = xgv_common.get_functional_currency
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.currency_code != ''STAT''';
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.currency_code = ''' || p_currency_code || '''';
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    -- Output debug information(SQL statement)
    xgv_common.show_sql_statement(l_sql_rec);

    l_sql_rec.text(1) := 'SELECT distinct gjb.name, gjb.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY gjb.name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY gjb.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    -- Output debug information(SQL statement)
    xgv_common.show_sql_statement(l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_BATCHES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_jq.show_lov_batches',
      '<input type="hidden" name="p_posted" value="' || p_posted || '">'
      || '<input type="hidden" name="p_unposted" value="' || p_unposted || '">'
      || '<input type="hidden" name="p_postederror" value="' || p_postederror || '">'
      || '<input type="hidden" name="p_period_from" value="' || p_period_from || '">'
      || '<input type="hidden" name="p_period_to" value="' || p_period_to || '">'
      || '<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">',
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addBatchesValue();');

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

  END show_lov_batches;

  --==========================================================
  --Procedure Name: show_lov_header_names
  --Description: Display LOV for header names
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --  p_posted           : Journal entry posted
  --  p_unposted         : Journal entry unposted
  --  p_postederror      : Jounal entry posted error
  --  p_period_from      : Accounting periods(From)
  --  p_period_to        : Accounting periods(To)
  --  p_effect_date_from : Effective date(From)
  --  p_effect_date_to   : Effective date(To)
  --  p_currency_code    : Currency code
  --  p_source           : Jornal entry source
  --  p_category         : Jornal entry category
  --  p_batch            : Jornal entry batch
  --==========================================================
  PROCEDURE show_lov_header_names(
    p_list_filter_item  IN VARCHAR2 DEFAULT 'VALUE',
    p_list_filter_value IN VARCHAR2 DEFAULT NULL,
    p_start_listno      IN NUMBER   DEFAULT 1,
    p_sort_item         IN VARCHAR2 DEFAULT 'VALUE',
    p_sort_method       IN VARCHAR2 DEFAULT 'ASC',
    p_posted            IN VARCHAR2 DEFAULT 'N',
    p_unposted          IN VARCHAR2 DEFAULT 'N',
    p_postederror       IN VARCHAR2 DEFAULT 'N',
    p_period_from       IN NUMBER   DEFAULT NULL,
    p_period_to         IN NUMBER   DEFAULT NULL,
    p_effect_date_from  IN VARCHAR2 DEFAULT NULL,
    p_effect_date_to    IN VARCHAR2 DEFAULT NULL,
    p_currency_code     IN VARCHAR2 DEFAULT NULL,
    p_source            IN VARCHAR2 DEFAULT NULL,
    p_category          IN VARCHAR2 DEFAULT NULL,
    p_batch             IN VARCHAR2 DEFAULT NULL)
  IS

    -- Absolute accounting periods
    l_abs_period_from  gl_period_statuses.effective_period_num%TYPE;
    l_abs_period_to    gl_period_statuses.effective_period_num%TYPE;

    -- Absolute journal entry effective date
    l_abs_effect_date_from  VARCHAR2(100);
    l_abs_effect_date_to    VARCHAR2(100);

    l_sql_rec  xgv_common.sql_rtype;
    l_count_sql  VARCHAR2(32767);
    l_list_sql  VARCHAR2(32767);

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('JQ.SHOW_LOV_HEADER_NAMES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_HEADER_NAMES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_header_name.value">');

    -- Relative periods to Absolute periods
    l_abs_period_from := nvl(xgv_common.convert_relative_period(p_period_from), 0);
    l_abs_period_to   := nvl(xgv_common.convert_relative_period(p_period_to), 99999999);

    -- Relative journal entry effective date to Absolute journal entry effective date
    l_abs_effect_date_from := xgv_common.convert_relative_date(p_effect_date_from);
    l_abs_effect_date_to   := xgv_common.convert_relative_date(p_effect_date_to);

    /* Bug#200031 21-Oct-2004 Changed by ytsujiha_jp */
    l_sql_rec.text(1) := 'SELECT count(gjh.je_header_id)';
    l_sql_rec.text(2) := 'FROM   gl_je_headers gjh, gl_period_statuses gps, gl_je_batches gjb'
      || xgv_common.r_decode(p_category, NULL, NULL, ', gl_je_categories_vl gjcv')
      || xgv_common.r_decode(p_source, NULL, NULL, ', gl_je_sources_vl gjsv');
    l_sql_rec.text(3) := 'WHERE  gps.application_id = xgv_common.get_gl_appl_id';
    l_sql_rec.text(4) := '  AND  gps.set_of_books_id = xgv_common.get_sob_id';
    xgv_common.set_bind_value(l_sql_rec, l_abs_period_from);
    xgv_common.set_bind_value(l_sql_rec, l_abs_period_to);
    l_sql_rec.text(5) := '  AND  gps.effective_period_num '
      || 'BETWEEN :' || l_sql_rec.ph_name(l_sql_rec.num_ph - 1)
      || ' AND :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
    l_sql_rec.text(6) := '  AND  gjb.set_of_books_id = gps.set_of_books_id';
    l_sql_rec.text(7) := '  AND  gjb.default_period_name = gps.period_name';

    IF  (p_posted = 'Y' OR p_unposted = 'Y')
    AND p_postederror = 'N'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
        '  AND  gjb.status IN ('
        || xgv_common.r_decode(p_posted, 'Y', '''P''', NULL)
        || xgv_common.r_decode(p_unposted,
             'Y', xgv_common.r_decode(p_posted, 'Y', ',', NULL) || '''U'',''I'',''S''', NULL)
        || ')';
    ELSIF  p_postederror = 'Y'
    AND (p_posted = 'N' OR p_unposted = 'N')
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
        '  AND  gjb.status NOT IN ('
        || xgv_common.r_decode(p_posted, 'Y', '''U'',''I'',''S''', NULL)
        || xgv_common.r_decode(p_unposted,
             'Y', xgv_common.r_decode(p_posted, 'Y', ',', NULL) || '''P''', NULL)
        || xgv_common.r_decode(p_posted, 'N',
             xgv_common.r_decode(p_unposted, 'N', '''P'',''U'',''I'',''S''', NULL), NULL)
        || ')';
    END IF;

    IF  p_batch IS NOT NULL
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
      xgv_common.get_where_clause(
        l_sql_rec, 'gjb', 'name', p_batch);
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
    END IF;

    l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.set_of_books_id = gjb.set_of_books_id';
    l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.period_name = gjb.default_period_name';
    l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.je_batch_id = gjb.je_batch_id';

    IF  l_abs_effect_date_from IS NOT NULL
    THEN
      xgv_common.set_bind_value(l_sql_rec, l_abs_effect_date_from);
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
        '  AND  trunc(gjh.default_effective_date) >= to_date(:'
        || l_sql_rec.ph_name(l_sql_rec.num_ph) || ', '''
        || xgv_common.get_date_mask || ''')';
    END IF;
    IF  l_abs_effect_date_to IS NOT NULL
    THEN
      xgv_common.set_bind_value(l_sql_rec, l_abs_effect_date_to);
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
        '  AND  trunc(gjh.default_effective_date) <= to_date(:'
        || l_sql_rec.ph_name(l_sql_rec.num_ph) || ', '''
        || xgv_common.get_date_mask || ''')';
    END IF;

    IF  p_currency_code = xgv_common.get_functional_currency
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.currency_code != ''STAT''';
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND  gjh.currency_code = ''' || p_currency_code || '''';
    END IF;

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'gjh', 'name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(gjh.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    IF  p_category IS NOT NULL
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND gjcv.je_category_name = gjh.je_category';
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
      xgv_common.get_where_clause(
        l_sql_rec, 'gjcv', 'user_je_category_name', p_category);
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
    END IF;

    IF  p_source IS NOT NULL
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND gjsv.je_source_name = gjh.je_source';
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
      xgv_common.get_where_clause(
        l_sql_rec, 'gjsv', 'user_je_source_name', p_source);
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    -- Output debug information(SQL statement)
    xgv_common.show_sql_statement(l_sql_rec);

    l_sql_rec.text(1) := 'SELECT gjh.name, gjh.description';
    l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY gjh.creation_date ' || p_sort_method;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    -- Output debug information(SQL statement)
    xgv_common.show_sql_statement(l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_HEADER_NAMES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_jq.show_lov_header_names',
      '<input type="hidden" name="p_posted" value="' || p_posted || '">'
      || '<input type="hidden" name="p_unposted" value="' || p_unposted || '">'
      || '<input type="hidden" name="p_postederror" value="' || p_postederror || '">'
      || '<input type="hidden" name="p_period_from" value="' || p_period_from || '">'
      || '<input type="hidden" name="p_period_to" value="' || p_period_to || '">'
      || '<input type="hidden" name="p_effect_date_from" value="' || p_effect_date_from || '">'
      || '<input type="hidden" name="p_effect_date_to" value="' || p_effect_date_to || '">'
      || '<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">'
      || '<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">'
      || '<input type="hidden" name="p_category" value="' || htf.escape_sc(p_category) || '">'
      || '<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">',
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addHeaderNamesValue();');

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

  END show_lov_header_names;

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
    xgv_common.write_access_log('JQ.SHOW_LOV_AFF');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
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
  --Procedure Name: request_async_exec
  --Description: Request background query
  --Note:
  --Parameter(s):
  --  p_mode              : Display mode(Not use)
  --  p_modify_flag       : Modify flag(Yes/No)
  --  p_query_id          : Query id
  --  p_query_name        : Query name
  --  p_journal_type      : Journal entry line type
  --  p_budget_version_id : Budget version id
  --  p_posted            : Journal entry posted status(Posted)
  --  p_unposted          : Journal entry posted status(Unposted)
  --  p_postederror       : Journal entry posted status(Posted Error)
  --  p_period_from       : Accounting periods(From)
  --  p_period_to         : Accounting periods(To)
  --  p_effect_date_from  : Effective date(From)
  --  p_effect_date_to    : Effective date(To)
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_dr_from           : Debit amount of translated currency(From)
  --  p_dr_to             : Debit amount of translated currency(To)
  --  p_cr_from           : Credit amount of translated currency(From)
  --  p_cr_to             : Credit amount of translated currency(To)
  --  p_batch_description : Jornal entry batch description
  --  p_header_description: Jornal entry description
  --  p_line_description  : Jornal entry description
  --  p_source            : Jornal entry source
  --  p_category          : Jornal entry category
  --  p_batch             : Jornal entry batch
  --  p_header_name       : Jornal entry header name
  --  p_condition         : Segment condition
  --  p_show_order        : Segment display order
  --  p_sort_order        : Segment sort order
  --  p_sort_method       : Segment sort method
  --  p_segment_type      : Segment type
  --  p_create_date_from  : Journal entry creation date(From)
  --  p_create_date_to    : Journal entry creation date(To)
  --  p_posted_date_from  : Journal entry posted date(From)
  --  p_posted_date_to    : Journal entry posted date(To)
  --  p_break_key         : Break key
  --  p_show_subtotalonly : Display subtotal only
  --  p_show_total        : Display total
  --  p_show_bringforward : Display bring forward
  --  p_result_format     : Result format
  --  p_file_name         : Filename
  --==========================================================
  PROCEDURE request_async_exec(
    p_mode               IN VARCHAR2 DEFAULT NULL,
    p_modify_flag        IN VARCHAR2 DEFAULT 'N',
    p_query_id           IN NUMBER   DEFAULT NULL,
    p_query_name         IN VARCHAR2 DEFAULT NULL,
    p_journal_type       IN VARCHAR2 DEFAULT NULL,
    p_budget_version_id  IN NUMBER   DEFAULT NULL,
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_postederror        IN VARCHAR2 DEFAULT 'N',
    p_period_from        IN NUMBER   DEFAULT NULL,
    p_period_to          IN NUMBER   DEFAULT NULL,
    p_effect_date_from   IN VARCHAR2 DEFAULT NULL,
    p_effect_date_to     IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_dr_from            IN NUMBER   DEFAULT NULL,
    p_dr_to              IN NUMBER   DEFAULT NULL,
    p_cr_from            IN NUMBER   DEFAULT NULL,
    p_cr_to              IN NUMBER   DEFAULT NULL,
    p_batch_description  IN VARCHAR2 DEFAULT NULL,     /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    p_header_description IN VARCHAR2 DEFAULT NULL,     /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    p_line_description   IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_category           IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_header_name        IN VARCHAR2 DEFAULT NULL,
    p_condition          IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_show_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_method        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type       IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_create_date_from   IN VARCHAR2 DEFAULT NULL,
    p_create_date_to     IN VARCHAR2 DEFAULT NULL,
    p_posted_date_from   IN VARCHAR2 DEFAULT NULL,
    p_posted_date_to     IN VARCHAR2 DEFAULT NULL,
    p_break_key          IN VARCHAR2 DEFAULT NULL,
    p_show_subtotalonly  IN VARCHAR2 DEFAULT 'N',
    p_show_total         IN VARCHAR2 DEFAULT 'N',
    p_show_bringforward  IN VARCHAR2 DEFAULT 'N',
    p_result_format      IN VARCHAR2 DEFAULT NULL,
    p_file_name          IN VARCHAR2 DEFAULT NULL)
  IS
  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('JQ.REQUEST_ASYNC_EXEC');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
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
      xgv_common.get_tabs_tag('JQ'));

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

    htp.p('<form name="f_submitasync" method="post" action="./xgv_je.submit_request_async_exec">');
    htp.p('<input type="hidden" name="p_execute_time" value="">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_journal_type" value="' || p_journal_type || '">');
    htp.p('<input type="hidden" name="p_budget_version_id" value="' || p_budget_version_id || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_postederror" value="' || p_postederror || '">');
    htp.p('<input type="hidden" name="p_period_from" value="' || p_period_from || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || p_period_to || '">');
    htp.p('<input type="hidden" name="p_effect_date_from" value="' || p_effect_date_from || '">');
    htp.p('<input type="hidden" name="p_effect_date_to" value="' || p_effect_date_to || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || p_doc_seq_from || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || p_doc_seq_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_dr_from" value="' || p_dr_from || '">');
    htp.p('<input type="hidden" name="p_dr_to" value="' || p_dr_to || '">');
    htp.p('<input type="hidden" name="p_cr_from" value="' || p_cr_from || '">');
    htp.p('<input type="hidden" name="p_cr_to" value="' || p_cr_to || '">');
    htp.p('<input type="hidden" name="p_batch_description" value="' || htf.escape_sc(p_batch_description) || '">');      /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');    /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_line_description" value="' || htf.escape_sc(p_line_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    htp.p('<input type="hidden" name="p_category" value="' || htf.escape_sc(p_category) || '">');
    htp.p('<input type="hidden" name="p_header_name" value="' || htf.escape_sc(p_header_name) || '">');
    FOR  l_index IN 1..p_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_condition" value="' || htf.escape_sc(p_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_create_date_from" value="' || p_create_date_from || '">');
    htp.p('<input type="hidden" name="p_create_date_to" value="' || p_create_date_to || '">');
    htp.p('<input type="hidden" name="p_posted_date_from" value="' || p_posted_date_from || '">');
    htp.p('<input type="hidden" name="p_posted_date_to" value="' || p_posted_date_to || '">');
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_show_order" value="' || p_show_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_sort_order" value="' || p_sort_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_sort_method" value="' || p_sort_method(l_index) || '">');
      htp.p('<input type="hidden" name="p_segment_type" value="' || p_segment_type(l_index) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_break_key" value="' || p_break_key || '">');
    htp.p('<input type="hidden" name="p_show_subtotalonly" value="' || p_show_subtotalonly || '">');
    htp.p('<input type="hidden" name="p_show_total" value="' || p_show_total || '">');
    htp.p('<input type="hidden" name="p_show_bringforward" value="' || p_show_bringforward || '">');
    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_file_name" value="' || htf.escape_sc(p_file_name) || '">');
    htp.p('</form>');

    htp.p('<form name="f_cancelasync" method="post" action="./xgv_jq.top">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_journal_type" value="' || p_journal_type || '">');
    htp.p('<input type="hidden" name="p_budget_version_id" value="' || p_budget_version_id || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_postederror" value="' || p_postederror || '">');
    htp.p('<input type="hidden" name="p_period_from" value="' || p_period_from || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || p_period_to || '">');
    htp.p('<input type="hidden" name="p_effect_date_from" value="' || p_effect_date_from || '">');
    htp.p('<input type="hidden" name="p_effect_date_to" value="' || p_effect_date_to || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || p_doc_seq_from || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || p_doc_seq_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_dr_from" value="' || p_dr_from || '">');
    htp.p('<input type="hidden" name="p_dr_to" value="' || p_dr_to || '">');
    htp.p('<input type="hidden" name="p_cr_from" value="' || p_cr_from || '">');
    htp.p('<input type="hidden" name="p_cr_to" value="' || p_cr_to || '">');
    htp.p('<input type="hidden" name="p_batch_description" value="' || htf.escape_sc(p_batch_description) || '">');      /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');    /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_line_description" value="' || htf.escape_sc(p_line_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    htp.p('<input type="hidden" name="p_category" value="' || htf.escape_sc(p_category) || '">');
    htp.p('<input type="hidden" name="p_header_name" value="' || htf.escape_sc(p_header_name) || '">');
    FOR  l_index IN 1..p_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_condition" value="' || htf.escape_sc(p_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_create_date_from" value="' || p_create_date_from || '">');
    htp.p('<input type="hidden" name="p_create_date_to" value="' || p_create_date_to || '">');
    htp.p('<input type="hidden" name="p_posted_date_from" value="' || p_posted_date_from || '">');
    htp.p('<input type="hidden" name="p_posted_date_to" value="' || p_posted_date_to || '">');
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_show_order" value="' || p_show_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_sort_order" value="' || p_sort_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_sort_method" value="' || p_sort_method(l_index) || '">');
      htp.p('<input type="hidden" name="p_segment_type" value="' || p_segment_type(l_index) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_break_key" value="' || p_break_key || '">');
    htp.p('<input type="hidden" name="p_show_subtotalonly" value="' || p_show_subtotalonly || '">');
    htp.p('<input type="hidden" name="p_show_total" value="' || p_show_total || '">');
    htp.p('<input type="hidden" name="p_show_bringforward" value="' || p_show_bringforward || '">');
    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_file_name" value="' || htf.escape_sc(p_file_name) || '">');
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
  --Description: Display list condition for Journal entry lines inquiry
  --Note:
  --Parameter(s):
  --  p_mode               : Display mode
  --                         (List/Delete confirm/Fail delete)
  --  p_list_filter_value  : Filter string for list
  --  p_list_filter_opttion: Filter option for list
  --  p_start_listno       : Start list no
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
    xgv_common.write_access_log('JQ.LIST_CONDITIONS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
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
      xgv_common.get_tabs_tag('JQ'));

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr style="vertical-align: top">');

    -- Display side navigator
    htp.p('<td>');
    show_side_navigator('OPEN');
    htp.p('</td>');

    -- Display list for query condition
    htp.p('<td width="100%">');

    xgv_common.list_conditions(p_mode, 'J',
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
  --Description: Execute save condition for Journal entry lines inquiry
  --Note:
  --Parameter(s):
  --  p_je_lines_query_rec: Query condition record
  --  p_save_mode         : Save mode(Update/New)
  --  p_save_category     : Save category(Sob/Responsibility/User)
  --  p_message_type      : Message type(E/C)
  --  p_message_id        : Message id
  --Result: Query id
  --==========================================================
  FUNCTION execute_save_condition(
    p_je_lines_query_rec IN  xgv_common.je_lines_query_rtype,
    p_save_mode          IN  VARCHAR2,
    p_save_category      IN  VARCHAR2,
    p_message_type       OUT VARCHAR2,
    p_message_id         OUT VARCHAR2)
  RETURN NUMBER
  IS

    l_query_id  xgv_queries.query_id%TYPE := p_je_lines_query_rec.query_id;
    l_dummy  xgv_queries.query_name%TYPE;

    l_date  xgv_query_conditions.condition%TYPE;

    PROCEDURE insert_condition_data(
      p_query_id     IN NUMBER,
      p_segment_type IN VARCHAR2,
      p_show_order   IN NUMBER,
      p_sort_order   IN NUMBER,
      p_sort_method  IN VARCHAR2,
      p_condition    IN VARCHAR2)
    IS
    BEGIN

      INSERT INTO xgv_query_conditions(
        query_id,
        segment_type,
        show_order,
        sort_order,
        sort_method,
        condition,
        creation_date, created_by, last_update_date, last_updated_by)
      VALUES(
        p_query_id,
        p_segment_type,
        p_show_order,
        p_sort_order,
        p_sort_method,
        p_condition,
        sysdate, xgv_common.get_user_id, sysdate, xgv_common.get_user_id);

    END insert_condition_data;

    PROCEDURE update_condition_data(
      p_query_id     IN NUMBER,
      p_segment_type IN VARCHAR2,
      p_show_order   IN NUMBER,
      p_sort_order   IN NUMBER,
      p_sort_method  IN VARCHAR2,
      p_condition    IN VARCHAR2)
    IS
    BEGIN

      UPDATE xgv_query_conditions
      SET    show_order = p_show_order,
             sort_order = p_sort_order,
             sort_method = p_sort_method,
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
        WHERE  xq.query_name = p_je_lines_query_rec.query_name
          AND  xq.inquiry_type = 'J'
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
              l_query_id, p_je_lines_query_rec.query_name, 'J',
              xgv_common.get_sob_id,
              decode(p_save_category, 'R', xgv_common.get_resp_appl_id, NULL),
              decode(p_save_category, 'R', xgv_common.get_resp_id, NULL),
              decode(p_save_category, 'U', xgv_common.get_user_id, NULL),
              p_je_lines_query_rec.result_format, p_je_lines_query_rec.file_name,
              p_je_lines_query_rec.description,
              sysdate, xgv_common.get_user_id, sysdate, xgv_common.get_user_id);

            -- Journal Entry Type(Actual/Budget)
            insert_condition_data(l_query_id, 'TYPE', NULL, NULL, NULL,
              p_je_lines_query_rec.je_type);
            -- Budget Version ID
            insert_condition_data(l_query_id, 'BUDID', NULL, NULL, NULL,
              to_char(p_je_lines_query_rec.budget_version_id));
            -- Subtotal Item
            insert_condition_data(l_query_id, 'BREAKKEY', NULL, NULL, NULL,
              p_je_lines_query_rec.break_key);
            -- Display Subtotal Only
            insert_condition_data(l_query_id, 'SUBTOTAL', NULL, NULL, NULL,
              p_je_lines_query_rec.show_subtotalonly);
            -- Display Total
            insert_condition_data(l_query_id, 'TOTAL', NULL, NULL, NULL,
              p_je_lines_query_rec.show_total);
            -- Display bring forward line
            insert_condition_data(l_query_id, 'BRGFORWARD', NULL, NULL, NULL,
              p_je_lines_query_rec.show_bringforward);

            FOR  l_index IN 1..p_je_lines_query_rec.segment_type_tab.COUNT
            LOOP

              -- Accounting Periods
              IF  p_je_lines_query_rec.segment_type_tab(l_index) = 'ACTP'
              THEN
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  to_char(p_je_lines_query_rec.period_from)
                  || ',' || to_char(p_je_lines_query_rec.period_to));

              -- Journal Entry Effective Date
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEEDATE'
              THEN
                IF  xgv_common.is_date(p_je_lines_query_rec.effect_date_from)
                THEN
                  l_date := to_char(to_date(p_je_lines_query_rec.effect_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_je_lines_query_rec.effect_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_je_lines_query_rec.effect_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_je_lines_query_rec.effect_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_je_lines_query_rec.effect_date_to;
                END IF;
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Journal Entry Post Status
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
              THEN
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  xgv_common.r_decode(p_je_lines_query_rec.posted, 'Y', 'P', NULL)
                  || xgv_common.r_decode(p_je_lines_query_rec.unposted, 'Y', 'U', NULL)
                  || xgv_common.r_decode(p_je_lines_query_rec.postederror, 'Y', 'E', NULL));

              -- Journal Entry Document Sequenctial Number
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEDOCNUM'
              THEN
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  to_char(p_je_lines_query_rec.doc_seq_from)
                  || ',' || to_char(p_je_lines_query_rec.doc_seq_to));

              -- Debit Amount
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'DR'
              THEN
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  to_char(p_je_lines_query_rec.dr_from)
                  || ',' || to_char(p_je_lines_query_rec.dr_to));

              -- Credit Amount
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'CR'
              THEN
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  to_char(p_je_lines_query_rec.cr_from)
                  || ',' || to_char(p_je_lines_query_rec.cr_to));

              -- Balance Amount
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'BALANCE'
              THEN
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  NULL);

              -- Currency
              -- Journal Entry Batch Description, Journal Entry Description, Journal Entry Line Description
              -- Journal Entry Source, Journal Entry Category, Journal Entry Batch, Journal Entry Header Name
              /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) IN ('CUR',
                                                                        'BATCHDESC', 'HEADERDESC', 'DESC',
                                                                        'SOURCE', 'CATEGORY', 'BATCH', 'HEADER')
              THEN
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_je_lines_query_rec.condition_tab(l_index));

              -- AFF/DFF Segments
              ELSIF  xgv_common.is_number(p_je_lines_query_rec.segment_type_tab(l_index))
              THEN
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_je_lines_query_rec.condition_tab(l_index));

              -- Journal Entry Creation Date
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JECDATE'
              THEN
                IF  xgv_common.is_date(p_je_lines_query_rec.create_date_from)
                THEN
                  l_date := to_char(to_date(p_je_lines_query_rec.create_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_je_lines_query_rec.create_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_je_lines_query_rec.create_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_je_lines_query_rec.create_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_je_lines_query_rec.create_date_to;
                END IF;
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Journal Entry Posted Date
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEPDATE'
              THEN
                IF  xgv_common.is_date(p_je_lines_query_rec.posted_date_from)
                THEN
                  l_date := to_char(to_date(p_je_lines_query_rec.posted_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_je_lines_query_rec.posted_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_je_lines_query_rec.posted_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_je_lines_query_rec.posted_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_je_lines_query_rec.posted_date_to;
                END IF;
                insert_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  l_date);
              END IF;

            END LOOP;

            p_message_type := 'C';
          EXCEPTION
            WHEN  OTHERS
            THEN
              ROLLBACK;

              l_query_id := p_je_lines_query_rec.query_id;
              p_message_type := 'E';
              p_message_id := 'XGV-20001';

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
        IF  p_je_lines_query_rec.created_by != xgv_common.get_user_id
        THEN
          RAISE e_invalid_authority;
        END IF;

        SELECT xq.query_name
        INTO   l_dummy
        FROM   xgv_queries xq
        WHERE  xq.query_id != l_query_id
          AND  xq.query_name = p_je_lines_query_rec.query_name
          AND  xq.inquiry_type = 'J'
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
            SET    query_name = p_je_lines_query_rec.query_name,
                   application_id = decode(p_save_category, 'R', xgv_common.get_resp_appl_id, NULL),
                   responsibility_id = decode(p_save_category, 'R', xgv_common.get_resp_id, NULL),
                   user_id = decode(p_save_category, 'U', xgv_common.get_user_id, NULL),
                   result_format = p_je_lines_query_rec.result_format,
                   file_name = p_je_lines_query_rec.file_name,
                   description = p_je_lines_query_rec.description,
                   last_update_date = sysdate,
                   last_updated_by = xgv_common.get_user_id
            WHERE  query_id = l_query_id;

            -- Journal Entry Type(Actual/Budget)
            update_condition_data(l_query_id, 'TYPE', NULL, NULL, NULL,
              p_je_lines_query_rec.je_type);
            -- Budget Version ID
            update_condition_data(l_query_id, 'BUDID', NULL, NULL, NULL,
              to_char(p_je_lines_query_rec.budget_version_id));
            -- Subtotal Item
            update_condition_data(l_query_id, 'BREAKKEY', NULL, NULL, NULL,
              p_je_lines_query_rec.break_key);
            -- Display Subtotal Only
            update_condition_data(l_query_id, 'SUBTOTAL', NULL, NULL, NULL,
              p_je_lines_query_rec.show_subtotalonly);
            -- Display Total
            update_condition_data(l_query_id, 'TOTAL', NULL, NULL, NULL,
              p_je_lines_query_rec.show_total);
            -- Display bring forward line
            update_condition_data(l_query_id, 'BRGFORWARD', NULL, NULL, NULL,
              p_je_lines_query_rec.show_bringforward);

            FOR  l_index IN 1..p_je_lines_query_rec.segment_type_tab.COUNT
            LOOP

              -- Accounting Periods
              IF  p_je_lines_query_rec.segment_type_tab(l_index) = 'ACTP'
              THEN
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  to_char(p_je_lines_query_rec.period_from)
                  || ',' || to_char(p_je_lines_query_rec.period_to));

              -- Journal Entry Effective Date
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEEDATE'
              THEN
                IF  xgv_common.is_date(p_je_lines_query_rec.effect_date_from)
                THEN
                  l_date := to_char(to_date(p_je_lines_query_rec.effect_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_je_lines_query_rec.effect_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_je_lines_query_rec.effect_date_to)
                THEN
                  l_date := l_date ||
                    to_char(to_date(p_je_lines_query_rec.effect_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_je_lines_query_rec.effect_date_to;
                END IF;
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Journal Entry Post Status
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
              THEN
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  xgv_common.r_decode(p_je_lines_query_rec.posted, 'Y', 'P', NULL)
                  || xgv_common.r_decode(p_je_lines_query_rec.unposted, 'Y', 'U', NULL)
                  || xgv_common.r_decode(p_je_lines_query_rec.postederror, 'Y', 'E', NULL));

              -- Journal Entry Document Sequenctial Number
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEDOCNUM'
              THEN
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  to_char(p_je_lines_query_rec.doc_seq_from)
                  || ',' || to_char(p_je_lines_query_rec.doc_seq_to));

              -- Debit Amount
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'DR'
              THEN
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  to_char(p_je_lines_query_rec.dr_from)
                  || ',' || to_char(p_je_lines_query_rec.dr_to));

              -- Credit Amount
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'CR'
              THEN
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  to_char(p_je_lines_query_rec.cr_from)
                  || ',' || to_char(p_je_lines_query_rec.cr_to));

              -- Balance Amount
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'BALANCE'
              THEN
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  NULL);

              -- Currency
              -- Journal Entry Batch Description, Journal Entry Description, Journal Entry Line Description
              -- Journal Entry Source, Journal Entry Category, Journal Entry Batch, Journal Entry Header Name
              /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) IN ('CUR',
                                                                        'BATCHDESC', 'HEADERDESC', 'DESC',
                                                                        'SOURCE', 'CATEGORY', 'BATCH', 'HEADER')
              THEN
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_je_lines_query_rec.condition_tab(l_index));

              -- AFF/DFF Segments
              ELSIF  xgv_common.is_number(p_je_lines_query_rec.segment_type_tab(l_index))
              THEN
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_je_lines_query_rec.condition_tab(l_index));

              -- Journal Entry Creation Date
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JECDATE'
              THEN
                IF  xgv_common.is_date(p_je_lines_query_rec.create_date_from)
                THEN
                  l_date := to_char(to_date(p_je_lines_query_rec.create_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_je_lines_query_rec.create_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_je_lines_query_rec.create_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_je_lines_query_rec.create_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_je_lines_query_rec.create_date_to;
                END IF;
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Journal Entry Posted Date
              ELSIF  p_je_lines_query_rec.segment_type_tab(l_index) = 'JEPDATE'
              THEN
                IF  xgv_common.is_date(p_je_lines_query_rec.posted_date_from)
                THEN
                  l_date := to_char(to_date(p_je_lines_query_rec.posted_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_je_lines_query_rec.posted_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_je_lines_query_rec.posted_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_je_lines_query_rec.posted_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_je_lines_query_rec.posted_date_to;
                END IF;
                update_condition_data(l_query_id, p_je_lines_query_rec.segment_type_tab(l_index),
                  p_je_lines_query_rec.show_order_tab(l_index),
                  p_je_lines_query_rec.sort_order_tab(l_index),
                  p_je_lines_query_rec.sort_method_tab(l_index),
                  l_date);
              END IF;

            END LOOP;

            p_message_type := 'C';
          EXCEPTION
            WHEN  OTHERS
            THEN
              ROLLBACK;

              p_message_type := 'E';
              p_message_id := 'XGV-20001';

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
  --Description: Save condition for Journal entry lines inquiry
  --Note:
  --Parameter(s):
  --  p_mode              : Display mode
  --                        (New save Dialog/Update save Dialog/New save/Update save)
  --  p_modify_flag       : Modify flag(Yes/No)
  --  p_save_category     : Save category(Sob/Responsibility/User)
  --  p_query_id          : Query id
  --  p_query_name        : Query name
  --  p_journal_type      : Journal entry line type
  --  p_budget_version_id : Budget version id
  --  p_posted            : Journal entry posted status(Posted)
  --  p_unposted          : Journal entry posted status(Unposted)
  --  p_postederror       : Journal entry posted status(Posted Error)
  --  p_period_from       : Accounting periods(From)
  --  p_period_to         : Accounting periods(To)
  --  p_effect_date_from  : Effective date(From)
  --  p_effect_date_to    : Effective date(To)
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_dr_from           : Debit amount of translated currency(From)
  --  p_dr_to             : Debit amount of translated currency(To)
  --  p_cr_from           : Credit amount of translated currency(From)
  --  p_cr_to             : Credit amount of translated currency(To)
  --  p_batch_description : Jornal entry batch description
  --  p_header_description: Jornal entry description
  --  p_line_description  : Jornal entry description
  --  p_source            : Jornal entry source
  --  p_category          : Jornal entry category
  --  p_batch             : Jornal entry batch
  --  p_header_name       : Jornal entry header name
  --  p_condition         : Segment condition(AFF/DFF only)
  --  p_show_order        : Segment display order
  --  p_sort_order        : Segment sort order
  --  p_sort_method       : Segment sort method
  --  p_segment_type      : Segment type
  --  p_create_date_from  : Journal entry creation date(From)
  --  p_create_date_to    : Journal entry creation date(To)
  --  p_posted_date_from  : Journal entry posted date(From)
  --  p_posted_date_to    : Journal entry posted date(To)
  --  p_break_key         : Break key
  --  p_show_subtotalonly : Display only sub total
  --  p_show_total        : Display total
  --  p_show_bringforward : Display bring forward
  --  p_result_format     : Result format
  --  p_file_name         : Filename
  --  p_description       : Description
  --==========================================================
  PROCEDURE save_condition(
    p_mode               IN VARCHAR2 DEFAULT 'ND',
    p_modify_flag        IN VARCHAR2 DEFAULT 'N',
    p_save_category      IN VARCHAR2 DEFAULT 'U',
    p_query_id           IN NUMBER   DEFAULT NULL,
    p_query_name         IN VARCHAR2 DEFAULT NULL,
    p_journal_type       IN VARCHAR2 DEFAULT NULL,
    p_budget_version_id  IN NUMBER   DEFAULT NULL,
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_postederror        IN VARCHAR2 DEFAULT 'N',
    p_period_from        IN NUMBER   DEFAULT NULL,
    p_period_to          IN NUMBER   DEFAULT NULL,
    p_effect_date_from   IN VARCHAR2 DEFAULT NULL,
    p_effect_date_to     IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_dr_from            IN NUMBER   DEFAULT NULL,
    p_dr_to              IN NUMBER   DEFAULT NULL,
    p_cr_from            IN NUMBER   DEFAULT NULL,
    p_cr_to              IN NUMBER   DEFAULT NULL,
    p_batch_description  IN VARCHAR2 DEFAULT NULL,     /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    p_header_description IN VARCHAR2 DEFAULT NULL,     /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    p_line_description   IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_category           IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_header_name        IN VARCHAR2 DEFAULT NULL,
    p_condition          IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_show_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_method        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type       IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_create_date_from   IN VARCHAR2 DEFAULT NULL,
    p_create_date_to     IN VARCHAR2 DEFAULT NULL,
    p_posted_date_from   IN VARCHAR2 DEFAULT NULL,
    p_posted_date_to     IN VARCHAR2 DEFAULT NULL,
    p_break_key          IN VARCHAR2 DEFAULT NULL,
    p_show_subtotalonly  IN VARCHAR2 DEFAULT 'N',
    p_show_total         IN VARCHAR2 DEFAULT 'N',
    p_show_bringforward  IN VARCHAR2 DEFAULT 'N',
    p_result_format      IN VARCHAR2 DEFAULT NULL,
    p_file_name          IN VARCHAR2 DEFAULT NULL,
    p_description        IN VARCHAR2 DEFAULT NULL)
  IS

    l_mode  VARCHAR2(2) := p_mode;
    l_save_category  VARCHAR2(1) := p_save_category;
    l_query_id  xgv_queries.query_id%TYPE := p_query_id;
    l_description  xgv_queries.description%TYPE := p_description;
    l_je_lines_query_rec  xgv_common.je_lines_query_rtype;
    l_message_type  VARCHAR2(1) := NULL;
    l_message_id  VARCHAR2(255) := NULL;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('JQ.SAVE_CONDITION');

    -- Adjustment mode
    IF  p_query_id IS NULL
    AND l_mode = 'UD'
    THEN
      l_mode := 'ND';
    END IF;

    -- Save mode
    IF  p_mode IN ('N', 'U')
    THEN
      IF  p_mode = 'N'
      THEN
        set_query_condition_local(
          l_je_lines_query_rec, NULL, p_journal_type, p_budget_version_id,
          p_posted, p_unposted, p_postederror,
          p_period_from,p_period_to, p_effect_date_from, p_effect_date_to,
          p_doc_seq_from, p_doc_seq_to, p_currency_code,
          p_dr_from, p_dr_to, p_cr_from, p_cr_to,
          p_batch_description, p_header_description, p_line_description,       /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
          p_source, p_category, p_batch, p_header_name,
          p_condition, p_show_order, p_sort_order, p_sort_method, p_segment_type,
          p_create_date_from, p_create_date_to, p_posted_date_from, p_posted_date_to,
          p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
          p_result_format, p_file_name, p_description);
        l_je_lines_query_rec.query_id := p_query_id;

      ELSE
        set_query_condition_local(
          l_je_lines_query_rec, p_query_id, p_journal_type, p_budget_version_id,
          p_posted, p_unposted, p_postederror,
          p_period_from,p_period_to, p_effect_date_from, p_effect_date_to,
          p_doc_seq_from, p_doc_seq_to, p_currency_code,
          p_dr_from, p_dr_to, p_cr_from, p_cr_to,
          p_batch_description, p_header_description, p_line_description,       /* Req#220015 26-Mar-2007 Changed by ytsujiha_jp */
          p_source, p_category, p_batch, p_header_name,
          p_condition, p_show_order, p_sort_order, p_sort_method, p_segment_type,
          p_create_date_from, p_create_date_to, p_posted_date_from, p_posted_date_to,
          p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
          p_result_format, p_file_name, p_description);
      END IF;

      l_je_lines_query_rec.query_name := p_query_name;
      l_query_id := execute_save_condition(
        l_je_lines_query_rec, p_mode, p_save_category, l_message_type, l_message_id);

      IF  l_message_type = 'C'
      THEN
        htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
        htp.p('<html dir="ltr">');
        htp.p('<body>');
        htp.p('<form name="f_refresh" method="post" action="./xgv_jq.top">');
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
          AND  xq.inquiry_type = 'J';
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
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_JQ.js"></script>');
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
      xgv_common.get_tabs_tag('JQ'));

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
-- 2012/01/25 Add E_本稼動_08991 Start
    htp.p(
      '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
      || '<tr>'
      || '<td colspan="5"><span class="OraErrorHeader">' || xxccp_common_pkg.get_msg('XXCFO','APP-XXCFO1-00040')
      || '</span></td></tr>'
      || '</table>');
-- 2012/01/25 Add E_本稼動_08991 End

    htp.p('<form name="f_savedialog" method="post" action="./xgv_jq.save_condition">');
    htp.p('<input type="hidden" name="p_mode" value="N">');
    htp.p('<input type="hidden" name="p_journal_type" value="' || p_journal_type || '">');
    htp.p('<input type="hidden" name="p_budget_version_id" value="' || p_budget_version_id || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_postederror" value="' || p_postederror || '">');
    htp.p('<input type="hidden" name="p_period_from" value="' || p_period_from || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || p_period_to || '">');
    htp.p('<input type="hidden" name="p_effect_date_from" value="' || p_effect_date_from || '">');
    htp.p('<input type="hidden" name="p_effect_date_to" value="' || p_effect_date_to || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || p_doc_seq_from || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || p_doc_seq_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_dr_from" value="' || p_dr_from || '">');
    htp.p('<input type="hidden" name="p_dr_to" value="' || p_dr_to || '">');
    htp.p('<input type="hidden" name="p_cr_from" value="' || p_cr_from || '">');
    htp.p('<input type="hidden" name="p_cr_to" value="' || p_cr_to || '">');
    htp.p('<input type="hidden" name="p_batch_description" value="' || htf.escape_sc(p_batch_description) || '">');      /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');    /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_line_description" value="' || htf.escape_sc(p_line_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    htp.p('<input type="hidden" name="p_category" value="' || htf.escape_sc(p_category) || '">');
    htp.p('<input type="hidden" name="p_header_name" value="' || htf.escape_sc(p_header_name) || '">');
    FOR  l_index IN 1..p_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_condition" value="' || htf.escape_sc(p_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_create_date_from" value="' || p_create_date_from || '">');
    htp.p('<input type="hidden" name="p_create_date_to" value="' || p_create_date_to || '">');
    htp.p('<input type="hidden" name="p_posted_date_from" value="' || p_posted_date_from || '">');
    htp.p('<input type="hidden" name="p_posted_date_to" value="' || p_posted_date_to || '">');
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_show_order" value="' || p_show_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_sort_order" value="' || p_sort_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_sort_method" value="' || p_sort_method(l_index) || '">');
      htp.p('<input type="hidden" name="p_segment_type" value="' || p_segment_type(l_index) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_break_key" value="' || p_break_key || '">');
    htp.p('<input type="hidden" name="p_show_subtotalonly" value="' || p_show_subtotalonly || '">');
    htp.p('<input type="hidden" name="p_show_total" value="' || p_show_total || '">');
    htp.p('<input type="hidden" name="p_show_bringforward" value="' || p_show_bringforward || '">');
    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_file_name" value="' || htf.escape_sc(p_file_name) || '">');

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
-- 2012/01/25 Add E_本稼動_08991 Start
--      ||  xgv_common.r_decode(l_save_category, 'S', ' checked>', '>')
      ||  '>'
-- 2012/01/25 Add E_本稼動_08991 End
      ||  xgv_common.get_message('PROMPT_UNIT_SET_OF_BOOKS')
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="radio" name="p_save_category" value="R"'
-- 2012/01/25 Add E_本稼動_08991 Start
--      ||  xgv_common.r_decode(l_save_category, 'R', ' checked>', '>')
      ||  '>'
-- 2012/01/25 Add E_本稼動_08991 End
      ||  xgv_common.get_message('PROMPT_UNIT_RESPONSIBILITY')
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="radio" name="p_save_category" value="U"'
-- 2012/01/25 Add E_本稼動_08991 Start
--      ||  xgv_common.r_decode(l_save_category, 'U', ' checked>', '>')
      ||  ' checked>'
-- 2012/01/25 Add E_本稼動_08991 End
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

    htp.p('<form name="f_cancelsave" method="post" action="./xgv_jq.top">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || l_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_journal_type" value="' || p_journal_type || '">');
    htp.p('<input type="hidden" name="p_budget_version_id" value="' || p_budget_version_id || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_postederror" value="' || p_postederror || '">');
    htp.p('<input type="hidden" name="p_period_from" value="' || p_period_from || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || p_period_to || '">');
    htp.p('<input type="hidden" name="p_effect_date_from" value="' || p_effect_date_from || '">');
    htp.p('<input type="hidden" name="p_effect_date_to" value="' || p_effect_date_to || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || p_doc_seq_from || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || p_doc_seq_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_dr_from" value="' || p_dr_from || '">');
    htp.p('<input type="hidden" name="p_dr_to" value="' || p_dr_to || '">');
    htp.p('<input type="hidden" name="p_cr_from" value="' || p_cr_from || '">');
    htp.p('<input type="hidden" name="p_cr_to" value="' || p_cr_to || '">');
    htp.p('<input type="hidden" name="p_batch_description" value="' || htf.escape_sc(p_batch_description) || '">');      /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');    /* Req#220015 26-Mar-2007 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_line_description" value="' || htf.escape_sc(p_line_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    htp.p('<input type="hidden" name="p_category" value="' || htf.escape_sc(p_category) || '">');
    htp.p('<input type="hidden" name="p_header_name" value="' || htf.escape_sc(p_header_name) || '">');
    FOR  l_index IN 1..p_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_condition" value="' || htf.escape_sc(p_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_create_date_from" value="' || p_create_date_from || '">');
    htp.p('<input type="hidden" name="p_create_date_to" value="' || p_create_date_to || '">');
    htp.p('<input type="hidden" name="p_posted_date_from" value="' || p_posted_date_from || '">');
    htp.p('<input type="hidden" name="p_posted_date_to" value="' || p_posted_date_to || '">');
    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_show_order" value="' || p_show_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_sort_order" value="' || p_sort_order(l_index) || '">');
      htp.p('<input type="hidden" name="p_sort_method" value="' || p_sort_method(l_index) || '">');
      htp.p('<input type="hidden" name="p_segment_type" value="' || p_segment_type(l_index) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_break_key" value="' || p_break_key || '">');
    htp.p('<input type="hidden" name="p_show_subtotalonly" value="' || p_show_subtotalonly || '">');
    htp.p('<input type="hidden" name="p_show_total" value="' || p_show_total || '">');
    htp.p('<input type="hidden" name="p_show_bringforward" value="' || p_show_bringforward || '">');
    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_file_name" value="' || htf.escape_sc(p_file_name) || '">');
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
    xgv_common.write_access_log('JQ.DELETE_CONDITION');

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
    htp.p('<form name="f_refresh" method="post" action="./xgv_jq.list_conditions">');
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

  --==========================================================
  --Procedure Name: check_subsidiary
  --Description: Check responsibility of access to subsidiary
  --             sob.
  --Note: Req#220012 16-Jan-2007 Added by ytsujiha_jp
  --Parameter(s):
  --  p_header_id    : GL Journal header id
  --  p_result_format: Result format
  --==========================================================
  PROCEDURE check_subsidiary(
    p_header_id     IN NUMBER,
    p_result_format IN VARCHAR2)
  IS

    -- Set of books id, and books name
    l_sob_id    gl_sets_of_books.set_of_books_id%TYPE;
    l_sob_name  gl_sets_of_books.name%TYPE;

    -- Application id and Responsibility id
    l_app_resp_id  VARCHAR2(256);

    -- Flag show responsibility
    l_show_data_flag  BOOLEAN := FALSE;

    CURSOR l_resp_cur(
      p_gl_resp_only  VARCHAR2,
      p_enabled_glwi  VARCHAR2,
      p_sob_id        NUMBER)
    IS
      SELECT frv.application_id || ',' || frv.responsibility_id app_resp_id,
             frv.responsibility_name resp_name
      FROM   fnd_user_resp_groups fur,
             fnd_responsibility_vl frv,
             (SELECT DISTINCT set_of_books_id set_of_books_id
              FROM   xgv_flex_structures_vl) xfsv
      WHERE  fur.user_id = xgv_common.get_user_id
        AND  sysdate BETWEEN fur.start_date AND nvl(fur.end_date, sysdate)
        AND  frv.application_id = fur.responsibility_application_id
        AND  (p_gl_resp_only = 'N'
              OR
              (p_gl_resp_only = 'Y' AND p_enabled_glwi = 'Y'
               AND
               frv.application_id = xgv_common.get_gl_appl_id))
        AND  frv.responsibility_id = fur.responsibility_id
        AND  frv.responsibility_key NOT IN ('XGV_USER', 'XGV_ADMIN')
        AND  sysdate BETWEEN frv.start_date AND nvl(frv.end_date, sysdate)
        AND  xfsv.set_of_books_id = p_sob_id
        AND  xgv_common.get_profile_option_value(
               'GL_SET_OF_BKS_ID',
               fur.user_id,
               fur.responsibility_id,
               fur.responsibility_application_id) = xfsv.set_of_books_id
      ORDER BY frv.responsibility_name;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    xgv_common.write_access_log('JQ.CHECK_SUBSIDIARY');

    -- Get subsidiary set of books id
    SELECT gjh.set_of_books_id
    INTO   l_sob_id
    FROM   gl_je_headers gjh
    WHERE  gjh.je_header_id = p_header_id;

    BEGIN
      -- Get count of responsibility
      SELECT frv.application_id || ',' || frv.responsibility_id app_resp_id
      INTO   l_app_resp_id
      FROM   fnd_user_resp_groups fur,
             fnd_responsibility_vl frv,
             (SELECT DISTINCT set_of_books_id set_of_books_id
              FROM   xgv_flex_structures_vl) xfsv
      WHERE  fur.user_id = xgv_common.get_user_id
        AND  sysdate BETWEEN fur.start_date AND nvl(fur.end_date, sysdate)
        AND  frv.application_id = fur.responsibility_application_id
        AND  (xgv_common.get_allow_only_responsibility = 'N'
              OR
              (xgv_common.get_allow_only_responsibility = 'Y'
               AND
               xgv_common.get_enabled_glwi = 'Y'
               AND
               frv.application_id = xgv_common.get_gl_appl_id))
        AND  frv.responsibility_id = fur.responsibility_id
        AND  frv.responsibility_key NOT IN ('XGV_USER', 'XGV_ADMIN')
        AND  sysdate BETWEEN frv.start_date AND nvl(frv.end_date, sysdate)
        AND  xfsv.set_of_books_id = l_sob_id
        AND  xgv_common.get_profile_option_value(
               'GL_SET_OF_BKS_ID',
               fur.user_id,
               fur.responsibility_id,
               fur.responsibility_application_id) = xfsv.set_of_books_id;
    EXCEPTION
      WHEN  NO_DATA_FOUND OR TOO_MANY_ROWS
      THEN
        l_app_resp_id := NULL;
    END;

    -- If count of responsibility equal 1
    IF  l_app_resp_id IS NOT NULL
    THEN

      htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
      htp.p('<html dir="ltr">');
      htp.p('<head>');
      htp.p('<meta http-equiv="Pragma" content="no-cache">');
      htp.p('<meta http-equiv="Expires" content="-1">');
      htp.p('</head>');
      htp.p('<body>');
      htp.p('<form name="f_refresh" method="post" action="./xgv_jq.redirect_subsidiary">');
      htp.p('<input type="hidden" name="p_app_resp_id" value="' || l_app_resp_id || '">');
      htp.p('<input type="hidden" name="p_header_id" value="' || to_char(p_header_id) || '">');
      htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
      htp.p('</form>');
      htp.p('<script language="JavaScript">');
      htp.p('<!--');
      htp.p('document.f_refresh.submit();');
      htp.p('// -->');
      htp.p('</script>');
      htp.p('</body>');
      htp.p('</html>');

    ELSE

      htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
      htp.p('<html dir="ltr">');

      htp.p('<head>');
      htp.p('<meta http-equiv="Pragma" content="no-cache">');
      htp.p('<meta http-equiv="Expires" content="-1">');
      htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
      htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
      htp.p('<script language="JavaScript" src="/XGV_JS/US/XGV_COMMON.js"></script>');
      htp.p('<title>' || xgv_common.get_message('TITLE_SELECT_RESP') || '</title>');
      htp.p('</head>');

      htp.p('<body class="OraBody" onLoad="window.focus();">');

      -- Show Header
      xgv_common.show_header(
        xgv_common.get_global_buttons_tag('SELECT_RESP'));

      -- Show responsibility name and radio button
      FOR l_resp_rec IN l_resp_cur(xgv_common.get_allow_only_responsibility,
                                   xgv_common.get_enabled_glwi,
                                   l_sob_id)
      LOOP

        IF l_show_data_flag = FALSE
        THEN
          -- Show sub title
          htp.prn('<script>t(1, 7);</script>');
          xgv_common.show_title(
            xgv_common.get_message('TITLE_SELECT_RESP'),
            xgv_common.get_message('NOTE_SELECTRESP_SUBSIDIARY'),
            NULL,
            1);

          htp.p('<form name="f_resp" method="post" action="./xgv_jq.redirect_subsidiary">');

          htp.p('<table align="center" border="0" cellpadding="0" cellspacing="0">');

          htp.p('<tr>'
            ||  '<td class="OraFieldText">'
            ||  '<input type="radio" name="p_app_resp_id" value="' ||  l_resp_rec.app_resp_id || '" checked>'
            ||  l_resp_rec.resp_name
            ||  '</td>'
            ||  '</tr>');

        ELSE
          htp.p('<tr><td class="OraFieldText">'
            ||  '<input type="radio" name="p_app_resp_id" value="' ||  l_resp_rec.app_resp_id || '">'
            ||  l_resp_rec.resp_name
            ||  '</td>'
            ||  '</tr>');
        END IF;

        l_show_data_flag := TRUE;

      END LOOP;

      -- If show responsibirity
      IF  l_show_data_flag = TRUE
      THEN

        htp.p('<tr><td><script>t(1, 12);</script></td></tr>');
        htp.p('<tr>'
          ||  '<td align="center">'
          ||  '<a href="javascript:document.f_resp.submit();">'
          ||  '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-select_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>');

        htp.p('</table>');
        htp.p('<input type="hidden" name="p_header_id" value="' || to_char(p_header_id) || '">');
        htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');

        htp.p('</form>');

      ELSE

        -- Get set of books name
        SELECT gsob.name
        INTO   l_sob_name
        FROM   gl_sets_of_books gsob
        WHERE  gsob.set_of_books_id = l_sob_id;

        htp.prn('<script>t(1, 7);</script>');
        xgv_common.show_messagebox('EN', 'ERROR_NO_SELECTRESP_SUBSIDIARY', l_sob_id, l_sob_name);

        htp.p('<table align="center" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr><td><script>t(1, 12);</script></td></tr>'
          ||  '<tr>'
          ||  '<td align="center">'
          ||  '<a href="./xgv_jq.top">'
          ||  '<img src="/XGV_IMAGE/' || xgv_common.get_lang || '/ab-cancel_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>');

        htp.p('</table>');

      END IF;

      -- Show footer
      xgv_common.show_footer;

      htp.p('</body>');

      htp.p('</html>');

    END IF;

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

  END check_subsidiary;

  --==========================================================
  --Procedure Name: redirect_subsidiary
  --Description: Drilldown subsidiary sob.
  --Note: Req#220012 16-Jan-2007 Added by ytsujiha_jp
  --Parameter(s):
  --  p_app_resp_id  : Application id and Responsibility id
  --  p_header_id    : GL Journal header id
  --  p_result_format: Result format
  --==========================================================
  PROCEDURE redirect_subsidiary(
    p_app_resp_id   IN VARCHAR2,
    p_header_id     IN NUMBER,
    p_result_format IN VARCHAR2)
  IS

    l_cookie  owa_cookie.cookie;

    -- Application id
    l_app_id  fnd_application.application_id%TYPE;

    -- Responsibility id
    l_resp_id  fnd_responsibility.responsibility_id%TYPE;

    -- Set of books id
    l_sob_id  gl_je_headers.set_of_books_id%TYPE;

    -- Currency code
    l_currency_code  gl_je_headers.currency_code%TYPE;

    -- Journal header name
    l_header_name  gl_je_headers.name%TYPE;

    -- Journal batch name
    l_batch_name  gl_je_batches.name%TYPE;

    -- Accounting periods
    l_period_num  gl_period_statuses.effective_period_num%TYPE;

    l_hide_flag  xgv_flex_structures_vl.hide_flag%TYPE;
    l_show_order  PLS_INTEGER := 1;

    -- Select usable items and AFF,DFF defines
    CURSOR l_jq_segs_cur(
      p_sob_id  NUMBER)
    IS
      SELECT 1 order1,
             xuiv.item_order oder2,
             xuiv.item_code segment_type
      FROM   xgv_usable_items_vl xuiv
      WHERE  xuiv.inquiry_type = 'J'
        AND  xuiv.enabled_flag = 'Y'
      UNION ALL
      SELECT 2 order1,
             xfsv.segment_id order2,
             to_char(xfsv.segment_id) segment_type
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = p_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
      ORDER BY 1, 2;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Get journal header name, batch name, accounting periods
    SELECT gjh.set_of_books_id,
           gjh.currency_code,
           gjh.name,
           gjb.name,
           gps.effective_period_num
    INTO   l_sob_id,
           l_currency_code,
           l_header_name,
           l_batch_name,
           l_period_num
    FROM   gl_je_headers gjh,
           gl_je_batches gjb,
           gl_period_statuses gps
    WHERE  gjh.je_header_id = p_header_id
      AND  gjb.je_batch_id = gjh.je_batch_id
      AND  gps.application_id = xgv_common.get_gl_appl_id
      AND  gps.set_of_books_id = gjb.set_of_books_id
      AND  gps.period_name = gjb.default_period_name;

    -- Get cookie
    l_cookie := owa_cookie.get('XGV_SESSION');

    -- Open http header
    owa_util.mime_header('text/html', FALSE);

    l_app_id := to_number(substr(p_app_resp_id, 1, instr(p_app_resp_id, ',') - 1));
    l_resp_id := to_number(substr(p_app_resp_id, instr(p_app_resp_id, ',') + 1));

    -- Set cookie session id, user id, responsibility id, application id, application
    owa_cookie.send('XGV_SESSION',
      xgv_common.split(l_cookie.vals(1), ',', 1, 1) || ','
      || xgv_common.split(l_cookie.vals(1), ',', 1, 2) || ','
      || to_char(l_resp_id) || ','
      || to_char(l_app_id) || ','
      || xgv_common.GLWI || ','
      || xgv_common.split(l_cookie.vals(1), ',', 1, 6));  /* Req#230009 30-Jul-2007 Changed by ytsujiha_jp */

    -- Close http header
    owa_util.http_header_close;

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');
    htp.p('<body>');
    htp.p('<form name="f_refresh" method="post" action="./xgv_jq.top" target="xgv_main">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_posted" value="Y">');
    htp.p('<input type="hidden" name="p_unposted" value="Y">');
    htp.p('<input type="hidden" name="p_postederror" value="Y">');
    htp.p('<input type="hidden" name="p_period_from" value="' || to_char(l_period_num) || '">');
    htp.p('<input type="hidden" name="p_period_to" value="' || to_char(l_period_num) || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || l_currency_code || '">');
    htp.p('<input type="hidden" name="p_batch" value="&quot;' || htf.escape_sc(l_batch_name) || '&quot;">');
    htp.p('<input type="hidden" name="p_header_name" value="&quot;' || htf.escape_sc(l_header_name) || '&quot;">');

    FOR  l_jq_segs_rec IN l_jq_segs_cur(l_sob_id)
    LOOP

      -- If type of segment equal AFF/DFF, output NULL condition.
      IF  xgv_common.is_number(l_jq_segs_rec.segment_type)
      THEN
        htp.p('<input type="hidden" name="p_condition" value="">');
      END IF;

      -- Setting show order
      IF  l_jq_segs_rec.segment_type IN ('DD', 'EXDD')
      THEN
        htp.p('<input type="hidden" name="p_show_order" value="1">');
      ELSIF  l_jq_segs_rec.segment_type IN ('JEEDATE', 'DR', 'CR')
      THEN
        htp.p('<input type="hidden" name="p_show_order" value="' || to_char(l_show_order) || '">');
        l_show_order := l_show_order + 1;
      ELSIF  xgv_common.is_number(l_jq_segs_rec.segment_type)
      THEN
        -- Get flag of hide column
        SELECT xfsv.hide_flag
        INTO   l_hide_flag
        FROM   xgv_flex_structures_vl xfsv
        WHERE  xfsv.set_of_books_id = l_sob_id
          AND  xfsv.application_id = xgv_common.get_gl_appl_id
          AND  xfsv.segment_id = to_number(l_jq_segs_rec.segment_type);

        IF  l_hide_flag = 'N'
        THEN
          htp.p('<input type="hidden" name="p_show_order" value="' || to_char(l_show_order) || '">');
          l_show_order := l_show_order + 1;
        ELSE
          htp.p('<input type="hidden" name="p_show_order" value="">');
        END IF;
      ELSE
        htp.p('<input type="hidden" name="p_show_order" value="">');
      END IF;

      -- Setting sort order
      htp.p('<input type="hidden" name="p_sort_order" value="'
        ||  xgv_common.r_decode(l_jq_segs_rec.segment_type, 'JEEDATE', to_char(1), NULL)
        ||  '">');
      htp.p('<input type="hidden" name="p_sort_method" value="">');
      htp.p('<input type="hidden" name="p_segment_type" value="' || l_jq_segs_rec.segment_type || '">');

    END LOOP;

    htp.p('<input type="hidden" name="p_result_format" value="' || p_result_format || '">');
    htp.p('<input type="hidden" name="p_direct_drilldown" value="Y">');

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

  END redirect_subsidiary;

END xgv_jq;
/
