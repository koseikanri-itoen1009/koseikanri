CREATE OR REPLACE PACKAGE BODY xgv_piq
--
--  XGVPIEDTB.pls
--
--  Copyright (c) Oracle Corporation 2001-2007. All Rights Reserved
--
--  NAME
--    xgv_piq
--  FUNCTION
--    Edit condition for Payables invoice inquiry(Body)
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
  --Description: Get record for payables invoice query
  --Note:
  --Parameter(s):
  --  p_pi_invoice_query_rec: Record for payables invoice query
  --  p_query_id            : Query id
  --==========================================================
  PROCEDURE set_query_condition(
    p_pi_invoice_query_rec OUT xgv_common.ap_invoice_query_rtype,
    p_query_id             IN  NUMBER)
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
              FROM   (SELECT xuiv.item_code segment_type
                      FROM   xgv_usable_items_vl xuiv
                      WHERE  xuiv.inquiry_type = 'PI'
                        AND  xuiv.enabled_flag = 'Y'
                      UNION ALL
                      SELECT to_char(xfsv.segment_id) segment_type
                      FROM   xgv_flex_structures_vl xfsv
                      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id) xuiv_xfsv
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
      WHERE  xuiv.inquiry_type = 'PI'
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
        AND  to_char(xfsv.segment_id) = xqc.segment_type
        AND  xqc.query_id = p_query_id
      ORDER BY 1, 2;

    -- Select usable items and AFF,DFF defines
    CURSOR l_piq_segs_cur
    IS
      SELECT 1 order1,
             xuiv.item_order oder2,
             xuiv.item_code segment_type
      FROM   xgv_usable_items_vl xuiv
      WHERE  xuiv.inquiry_type = 'PI'
        AND  xuiv.enabled_flag = 'Y'
      UNION ALL
      SELECT 2 order1,
             xfsv.segment_id order2,
             to_char(xfsv.segment_id) segment_type
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_gl_appl_id
        AND  xfsv.flexfield_name = 'GL#'
      UNION ALL
      SELECT 3 order1,
             xfsv.segment_id order2,
             to_char(xfsv.segment_id) segment_type
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.application_id = xgv_common.get_ap_appl_id
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
    INTO   p_pi_invoice_query_rec.query_id,
           p_pi_invoice_query_rec.query_name,
           p_pi_invoice_query_rec.result_format,
           p_pi_invoice_query_rec.file_name,
           p_pi_invoice_query_rec.description,
           p_pi_invoice_query_rec.result_rows,
           p_pi_invoice_query_rec.creation_date,
           p_pi_invoice_query_rec.created_by,
           p_pi_invoice_query_rec.last_update_date,
           p_pi_invoice_query_rec.last_updated_by
    FROM   xgv_queries xq
    WHERE  xq.query_id = p_query_id
      AND  xq.inquiry_type = 'PI';

    FOR  l_other_conditions_rec IN l_other_conditions_cur(p_query_id)
    LOOP

      -- Subtotal Item
      IF  l_other_conditions_rec.segment_type = 'BREAKKEY'
      THEN
        p_pi_invoice_query_rec.break_key := l_other_conditions_rec.condition;

      -- Display Subtotal Only
      ELSIF  l_other_conditions_rec.segment_type = 'SUBTOTAL'
      THEN
        p_pi_invoice_query_rec.show_subtotalonly := l_other_conditions_rec.condition;

      -- Display Total
      ELSIF  l_other_conditions_rec.segment_type = 'TOTAL'
      THEN
        p_pi_invoice_query_rec.show_total := l_other_conditions_rec.condition;

      -- Display bring forward line
      ELSIF  l_other_conditions_rec.segment_type = 'BRGFORWARD'
      THEN
        p_pi_invoice_query_rec.show_bringforward := l_other_conditions_rec.condition;

      END IF;

    END LOOP;

    FOR  l_seg_conditions_rec IN l_seg_conditions_cur(p_query_id)
    LOOP

      p_pi_invoice_query_rec.segment_type_tab(l_seg_conditions_cur%ROWCOUNT) := l_seg_conditions_rec.segment_type;
      p_pi_invoice_query_rec.show_order_tab(l_seg_conditions_cur%ROWCOUNT)   := l_seg_conditions_rec.show_order;
      p_pi_invoice_query_rec.sort_order_tab(l_seg_conditions_cur%ROWCOUNT)   := l_seg_conditions_rec.sort_order;
      p_pi_invoice_query_rec.sort_method_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.sort_method;

      -- Data Refer(Hidden items)
      IF  l_seg_conditions_rec.segment_type = 'EXDD'
      THEN
        p_pi_invoice_query_rec.show_order_tab(l_seg_conditions_cur%ROWCOUNT) := 1;

      -- Invoice Date
      ELSIF  l_seg_conditions_rec.segment_type = 'INVP'
      THEN
        p_pi_invoice_query_rec.invoice_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_pi_invoice_query_rec.invoice_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_pi_invoice_query_rec.invoice_date_from, 'RRRRMMDD')
        THEN
          p_pi_invoice_query_rec.invoice_date_from :=
            to_char(to_date(p_pi_invoice_query_rec.invoice_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_pi_invoice_query_rec.invoice_date_to, 'RRRRMMDD')
        THEN
          p_pi_invoice_query_rec.invoice_date_to :=
            to_char(to_date(p_pi_invoice_query_rec.invoice_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- Paid Status
      ELSIF  l_seg_conditions_rec.segment_type = 'PAIDSTATUS'
      THEN
        p_pi_invoice_query_rec.paid_status := l_seg_conditions_rec.condition;

      -- Posted Status
      ELSIF  l_seg_conditions_rec.segment_type = 'POSTSTATUS'
      THEN
        p_pi_invoice_query_rec.post_status := l_seg_conditions_rec.condition;

      -- Hold All Payments Status
      /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
      ELSIF  l_seg_conditions_rec.segment_type = 'ALLHLDSTAT'
      THEN
        p_pi_invoice_query_rec.hold_all_status := l_seg_conditions_rec.condition;

      -- Held Status
      ELSIF  l_seg_conditions_rec.segment_type = 'HOLDSTATUS'
      THEN
        p_pi_invoice_query_rec.hold_status := l_seg_conditions_rec.condition;

      -- Document Sequenctial Number
      ELSIF  l_seg_conditions_rec.segment_type = 'APDOCNUM'
      THEN
        p_pi_invoice_query_rec.doc_seq_from := to_number(xgv_common.split(l_seg_conditions_rec.condition, ','));
        p_pi_invoice_query_rec.doc_seq_to   := to_number(xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2));

      -- Invoice Amount
      ELSIF  l_seg_conditions_rec.segment_type = 'INVAMOUNT'
      THEN
        p_pi_invoice_query_rec.inv_amount_from := to_number(xgv_common.split(l_seg_conditions_rec.condition, ','));
        p_pi_invoice_query_rec.inv_amount_to   := to_number(xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2));

      -- Term Date
      ELSIF  l_seg_conditions_rec.segment_type = 'TERMDATE'
      THEN
        p_pi_invoice_query_rec.term_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_pi_invoice_query_rec.term_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_pi_invoice_query_rec.term_date_from, 'RRRRMMDD')
        THEN
          p_pi_invoice_query_rec.term_date_from :=
            to_char(to_date(p_pi_invoice_query_rec.term_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_pi_invoice_query_rec.term_date_to, 'RRRRMMDD')
        THEN
          p_pi_invoice_query_rec.term_date_to :=
            to_char(to_date(p_pi_invoice_query_rec.term_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- GL Date
      ELSIF  l_seg_conditions_rec.segment_type = 'GLDATE'
      THEN
        p_pi_invoice_query_rec.gl_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_pi_invoice_query_rec.gl_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_pi_invoice_query_rec.gl_date_from, 'RRRRMMDD')
        THEN
          p_pi_invoice_query_rec.gl_date_from :=
            to_char(to_date(p_pi_invoice_query_rec.gl_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_pi_invoice_query_rec.gl_date_to, 'RRRRMMDD')
        THEN
          p_pi_invoice_query_rec.gl_date_to :=
            to_char(to_date(p_pi_invoice_query_rec.gl_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- Payment Due Date
      ELSIF  l_seg_conditions_rec.segment_type = 'DUEDATE'
      THEN
        p_pi_invoice_query_rec.due_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_pi_invoice_query_rec.due_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_pi_invoice_query_rec.due_date_from, 'RRRRMMDD')
        THEN
          p_pi_invoice_query_rec.due_date_from :=
            to_char(to_date(p_pi_invoice_query_rec.due_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_pi_invoice_query_rec.due_date_to, 'RRRRMMDD')
        THEN
          p_pi_invoice_query_rec.due_date_to :=
            to_char(to_date(p_pi_invoice_query_rec.due_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- Payment Holds Flag
      /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
      ELSIF  l_seg_conditions_rec.segment_type = 'HOLDFLAG'
      THEN
        p_pi_invoice_query_rec.hold_flag := l_seg_conditions_rec.condition;

      -- Line Number(Line Type)
      -- Vendor Name, Vendor Site Name, Invoice Type, Approval Status,
      -- Invoice Number, Currency, Term, Payment Method, Payment Group,
      -- Invoice Header Description, Invoice Source, Invoice Batch,
      -- Invoice Distribution Type, Invoice Distribution Description
      -- Payment Currency
      ELSIF  l_seg_conditions_rec.segment_type IN ('LINENUM',
                                                   'VENDOR', 'VENDORSITE', 'INVTYPE', 'APPSTATUS',
                                                   'INVNUM', 'INVCUR', 'TERM', 'PAYMETHOD', 'PAYGRP',
                                                   'HDESC', 'SOURCE', 'BATCH',
                                                   'DTYPE', 'DDESC',
                                                   'PAYCUR')
      THEN
        p_pi_invoice_query_rec.condition_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.condition;

      -- AFF/DFF Segments
      ELSIF  xgv_common.is_number(l_seg_conditions_rec.segment_type)
      THEN
        p_pi_invoice_query_rec.condition_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.condition;
      END IF;

    END LOOP;

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  NO_DATA_FOUND
    THEN
      -- Set default value
      p_pi_invoice_query_rec.query_id          := NULL;
      p_pi_invoice_query_rec.query_name        := NULL;
      p_pi_invoice_query_rec.break_key         := NULL;
      p_pi_invoice_query_rec.show_subtotalonly := 'N';
      p_pi_invoice_query_rec.show_total        := 'N';
      p_pi_invoice_query_rec.show_bringforward := 'N';
      p_pi_invoice_query_rec.result_format     := nvl(xgv_common.get_profile_option_value('XGV_DEFAULT_RESULT_FORMAT'), 'HTML');
      p_pi_invoice_query_rec.file_name         := NULL;
      p_pi_invoice_query_rec.description       := NULL;
      p_pi_invoice_query_rec.result_rows       := NULL;
      p_pi_invoice_query_rec.creation_date     := NULL;
      p_pi_invoice_query_rec.created_by        := NULL;
      p_pi_invoice_query_rec.last_update_date  := NULL;
      p_pi_invoice_query_rec.last_updated_by   := NULL;

      FOR  l_piq_segs_rec IN l_piq_segs_cur
      LOOP

        -- Set default value
        p_pi_invoice_query_rec.segment_type_tab(l_piq_segs_cur%ROWCOUNT) := l_piq_segs_rec.segment_type;
        p_pi_invoice_query_rec.show_order_tab(l_piq_segs_cur%ROWCOUNT)   := NULL;
        p_pi_invoice_query_rec.sort_order_tab(l_piq_segs_cur%ROWCOUNT)   := NULL;
        p_pi_invoice_query_rec.sort_method_tab(l_piq_segs_cur%ROWCOUNT)  := NULL;

        -- Data Refer(Hidden items)
        IF  l_piq_segs_rec.segment_type = 'EXDD'
        THEN
          p_pi_invoice_query_rec.show_order_tab(l_piq_segs_cur%ROWCOUNT) := 1;

        -- Line Number(Line Type)
        ELSIF  l_piq_segs_rec.segment_type = 'LINENUM'
        THEN
          p_pi_invoice_query_rec.show_order_tab(l_piq_segs_cur%ROWCOUNT) := 3;
          p_pi_invoice_query_rec.sort_order_tab(l_piq_segs_cur%ROWCOUNT) := 3;
          p_pi_invoice_query_rec.condition_tab(l_piq_segs_cur%ROWCOUNT)  := 'HDP';

        -- Invoice Date
        ELSIF  l_piq_segs_rec.segment_type = 'INVP'
        THEN
          p_pi_invoice_query_rec.invoice_date_from := NULL;
          p_pi_invoice_query_rec.invoice_date_to   := NULL;
          p_pi_invoice_query_rec.show_order_tab(l_piq_segs_cur%ROWCOUNT) := 1;
          p_pi_invoice_query_rec.sort_order_tab(l_piq_segs_cur%ROWCOUNT) := 1;

        -- Paid Status
        ELSIF  l_piq_segs_rec.segment_type = 'PAIDSTATUS'
        THEN
          p_pi_invoice_query_rec.paid_status := 'YNP';

        -- Posted Status
        ELSIF  l_piq_segs_rec.segment_type = 'POSTSTATUS'
        THEN
          p_pi_invoice_query_rec.post_status := 'YNPS';

        -- Hold All Payments Status
        /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
        ELSIF  l_piq_segs_rec.segment_type = 'ALLHLDSTAT'
        THEN
          p_pi_invoice_query_rec.hold_all_status := NULL;

        -- Held Status
        ELSIF  l_piq_segs_rec.segment_type = 'HOLDSTATUS'
        THEN
          p_pi_invoice_query_rec.hold_status := NULL;

        -- Invoice Number
        ELSIF  l_piq_segs_rec.segment_type = 'INVNUM'
        THEN
          p_pi_invoice_query_rec.show_order_tab(l_piq_segs_cur%ROWCOUNT) := 2;
          p_pi_invoice_query_rec.sort_order_tab(l_piq_segs_cur%ROWCOUNT) := 2;
          p_pi_invoice_query_rec.condition_tab(l_piq_segs_cur%ROWCOUNT)  := NULL;

        -- Document Sequenctial Number
        ELSIF  l_piq_segs_rec.segment_type = 'APDOCNUM'
        THEN
          p_pi_invoice_query_rec.doc_seq_from := NULL;
          p_pi_invoice_query_rec.doc_seq_to   := NULL;

        -- Currency
        ELSIF  l_piq_segs_rec.segment_type = 'INVCUR'
        THEN
          p_pi_invoice_query_rec.condition_tab(l_piq_segs_cur%ROWCOUNT)  := NULL;

        -- Invoice Amount
        ELSIF  l_piq_segs_rec.segment_type = 'INVAMOUNT'
        THEN
          p_pi_invoice_query_rec.inv_amount_from := NULL;
          p_pi_invoice_query_rec.inv_amount_to   := NULL;

        -- Term Date
        ELSIF  l_piq_segs_rec.segment_type = 'TERMDATE'
        THEN
          p_pi_invoice_query_rec.term_date_from := NULL;
          p_pi_invoice_query_rec.term_date_to   := NULL;

        -- GL date
        ELSIF  l_piq_segs_rec.segment_type = 'GLDATE'
        THEN
          p_pi_invoice_query_rec.gl_date_from := NULL;
          p_pi_invoice_query_rec.gl_date_to   := NULL;

        -- Payment Currency
        ELSIF  l_piq_segs_rec.segment_type = 'PAYCUR'
        THEN
          p_pi_invoice_query_rec.condition_tab(l_piq_segs_cur%ROWCOUNT)  := NULL;

        -- Payment Due Date
        ELSIF  l_piq_segs_rec.segment_type = 'DUEDATE'
        THEN
          p_pi_invoice_query_rec.due_date_from := NULL;
          p_pi_invoice_query_rec.due_date_to   := NULL;

        -- Payment Holds Flag
        /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
        ELSIF  l_piq_segs_rec.segment_type = 'HOLDFLAG'
        THEN
          p_pi_invoice_query_rec.hold_flag := NULL;

        -- Vendor Name, Vendor Site Name, Invoice Type, Approval Status,
        -- Term, Payment Method, Payment Group,
        -- Invoice Header Description, Invoice Source, Invoice Batch,
        -- Invoice Distribution Type, Invoice Distribution Description
        ELSIF  l_piq_segs_rec.segment_type IN ('VENDOR', 'VENDORSITE', 'INVTYPE', 'APPSTATUS',
                                               'TERM', 'PAYMETHOD', 'PAYGRP',
                                               'HDESC', 'SOURCE', 'BATCH',
                                               'DTYPE', 'DDESC',
                                               'PAYCUR')
        THEN
          p_pi_invoice_query_rec.condition_tab(l_piq_segs_cur%ROWCOUNT)  := NULL;

        -- AFF/DFF Segments
        ELSIF  xgv_common.is_number(l_piq_segs_rec.segment_type)
        THEN
          p_pi_invoice_query_rec.condition_tab(l_piq_segs_cur%ROWCOUNT)  := NULL;
        END IF;

      END LOOP;

  END set_query_condition;

  --==========================================================
  --Procedure Name: set_query_condition_local
  --Description: Set record for Payables inquiry
  --Note:
  --Parameter(s):
  --  p_pi_invoice_query_rec: Record for payables invoice query
  --  p_query_id            : Query id
  --  p_show_header_line    : Display header line
  --  p_vendor              : Vendor name
  --  p_vendor_site         : Vendor site name
  --  p_inv_date_from       : Invoice date(From)
  --  p_inv_date_to         : Invoice date(To)
  --  p_invoice_type        : Invoice type
  --  p_paid                : Paid status(paid)
  --  p_notpaid             : Paid status(not paid)
  --  p_partpaid            : Paid status(partially paid)
  --  p_posted              : Posted status(posted)
  --  p_unposted            : Posted status(unposted)
  --  p_partposted          : Posted status(partially posted)
  --  p_selectposted        : Posted status(selectively posted)
  --  p_approvalstatus      : Approval status
  --  p_all_holdstatus      : Hold all payments status(Y)
  --  p_no_all_holdstatus   : Hold all payments status(N)
  --  p_heldstatus          : Held status(Y, N, R)
  --  p_inv_num             : Invoice number
  --  p_doc_seq_from        : Document sequence number(From)
  --  p_doc_seq_to          : Document sequence number(To)
  --  p_currency_code       : Currency
  --  p_inv_amount_from     : Invoice amount(From)
  --  p_inv_amount_to       : Invoice amount(To)
  --  p_term_date_from      : Term date(From)
  --  p_term_date_to        : Term date(To)
  --  p_term                : Term
  --  p_payment_method      : Payment method
  --  p_payment_group       : Payment group
  --  p_header_description  : Invoice header description
  --  p_source              : Invoice source
  --  p_batch               : Invoice batch
  --  p_h_dff_condition     : Segment condition of invoice header dff
  --  p_dist_type           : Invoice distribution type
  --  p_dist_description    : Invoice distribution description
  --  p_gl_date_from        : General Ledger posted date(From)
  --  p_gl_date_to          : General Ledger posted date(To)
  --  p_aff_condition       : Segment condition of aff
  --  p_pay_currency_code   : Payment currency
  --  p_due_date_from       : Payment due date(From)
  --  p_due_date_to         : Payment due date(To)
  --  p_pay_hold_flag       : Payment holds flag(Y)
  --  p_no_pay_hold_flag    : Payment holds flag(N)
  --  p_show_order          : Segment display order
  --  p_sort_order          : Segment sort order
  --  p_sort_method         : Segment sort method
  --  p_segment_type        : Segment type
  --  p_break_key           : Break key
  --  p_show_subtotalonly   : Display subtotal only
  --  p_show_total          : Display total
  --  p_show_bringforward   : Display bring forward
  --  p_result_format       : Result format
  --  p_file_name           : Filename
  --  p_description         : Description
  --==========================================================
  PROCEDURE set_query_condition_local(
    p_pi_invoice_query_rec OUT xgv_common.ap_invoice_query_rtype,
    p_query_id             IN  NUMBER,
    p_show_header_line     IN  VARCHAR2,
    p_vendor               IN  VARCHAR2,
    p_vendor_site          IN  VARCHAR2,
    p_inv_date_from        IN  VARCHAR2,
    p_inv_date_to          IN  VARCHAR2,
    p_invoice_type         IN  VARCHAR2,
    p_paid                 IN  VARCHAR2,
    p_notpaid              IN  VARCHAR2,
    p_partpaid             IN  VARCHAR2,
    p_posted               IN  VARCHAR2,
    p_unposted             IN  VARCHAR2,
    p_partposted           IN  VARCHAR2,
    p_selectposted         IN  VARCHAR2,
    p_approvalstatus       IN  VARCHAR2,
    p_all_holdstatus       IN  VARCHAR2,              /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
    p_no_all_holdstatus    IN  VARCHAR2,              /* Req#210004 23-Aug-2005 Added by ytsujiha_jp */
    p_heldstatus           IN  VARCHAR2,
    p_inv_num              IN  VARCHAR2,
    p_doc_seq_from         IN  NUMBER,
    p_doc_seq_to           IN  NUMBER,
    p_currency_code        IN  VARCHAR2,
    p_inv_amount_from      IN  NUMBER,
    p_inv_amount_to        IN  NUMBER,
    p_term_date_from       IN  VARCHAR2,
    p_term_date_to         IN  VARCHAR2,
    p_term                 IN  VARCHAR2,
    p_payment_method       IN  VARCHAR2,
    p_payment_group        IN  VARCHAR2,
    p_header_description   IN  VARCHAR2,
    p_source               IN  VARCHAR2,
    p_batch                IN  VARCHAR2,
    p_h_dff_condition      IN  xgv_common.array_ttype,
    p_dist_type            IN  VARCHAR2,
    p_dist_description     IN  VARCHAR2,
    p_gl_date_from         IN  VARCHAR2,
    p_gl_date_to           IN  VARCHAR2,
    p_aff_condition        IN  xgv_common.array_ttype,
    p_pay_currency_code    IN  VARCHAR2 DEFAULT NULL,
    p_due_date_from        IN  VARCHAR2 DEFAULT NULL,
    p_due_date_to          IN  VARCHAR2 DEFAULT NULL,
    p_pay_hold_flag        IN  VARCHAR2,              /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
    p_no_pay_hold_flag     IN  VARCHAR2,              /* Req#210005 23-Aug-2005 Added by ytsujiha_jp */
    p_show_order           IN  xgv_common.array_ttype,
    p_sort_order           IN  xgv_common.array_ttype,
    p_sort_method          IN  xgv_common.array_ttype,
    p_segment_type         IN  xgv_common.array_ttype,
    p_break_key            IN  VARCHAR2,
    p_show_subtotalonly    IN  VARCHAR2,
    p_show_total           IN  VARCHAR2,
    p_show_bringforward    IN  VARCHAR2,
    p_result_format        IN  VARCHAR2,
    p_file_name            IN  VARCHAR2,
    p_description          IN  VARCHAR2)
  IS

    l_index_h_dff_condition  NUMBER := 0;
    l_index_aff_condition  NUMBER := 0;

  BEGIN

    IF  p_query_id IS NULL
    THEN
      p_pi_invoice_query_rec.query_id := NULL;
      p_pi_invoice_query_rec.query_name := NULL;
      p_pi_invoice_query_rec.creation_date := NULL;
      p_pi_invoice_query_rec.created_by := NULL;
      p_pi_invoice_query_rec.last_update_date := NULL;
      p_pi_invoice_query_rec.last_updated_by := NULL;

    -- Set WHO columns
    ELSE
      SELECT xq.query_id,
             xq.query_name,
             xq.creation_date,
             xq.created_by,
             xq.last_update_date,
             xq.last_updated_by
      INTO   p_pi_invoice_query_rec.query_id,
             p_pi_invoice_query_rec.query_name,
             p_pi_invoice_query_rec.creation_date,
             p_pi_invoice_query_rec.created_by,
             p_pi_invoice_query_rec.last_update_date,
             p_pi_invoice_query_rec.last_updated_by
      FROM   xgv_queries xq
      WHERE  xq.query_id = p_query_id;
    END IF;

    -- Set conditions
    p_pi_invoice_query_rec.break_key         := p_break_key;
    p_pi_invoice_query_rec.show_subtotalonly := p_show_subtotalonly;
    p_pi_invoice_query_rec.show_total        := p_show_total;
    p_pi_invoice_query_rec.show_bringforward := p_show_bringforward;
    p_pi_invoice_query_rec.result_format     := p_result_format;
    p_pi_invoice_query_rec.file_name         := p_file_name;
    p_pi_invoice_query_rec.description       := p_description;
    p_pi_invoice_query_rec.result_rows       := xgv_common.get_result_rows;

    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP

      -- Display Order, Sort Order, Sort Method, Segment Type
      p_pi_invoice_query_rec.show_order_tab(l_index)   := to_number(p_show_order(l_index));
      p_pi_invoice_query_rec.sort_order_tab(l_index)   := to_number(p_sort_order(l_index));
      p_pi_invoice_query_rec.sort_method_tab(l_index)  := p_sort_method(l_index);
      p_pi_invoice_query_rec.segment_type_tab(l_index) := p_segment_type(l_index);

      -- Line Number(Line Type)
      IF  p_segment_type(l_index) = 'LINENUM'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index)  :=
          xgv_common.r_decode(p_show_header_line, 'Y', 'H', NULL)
          || 'DP';

      -- Vendor Name
      ELSIF  p_segment_type(l_index) = 'VENDOR'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_vendor;

      -- Vendor Site Name
      ELSIF  p_segment_type(l_index) = 'VENDORSITE'
      THEN
         p_pi_invoice_query_rec.condition_tab(l_index) := p_vendor_site;

      -- Invoice Date
      ELSIF  p_segment_type(l_index) = 'INVP'
      THEN
        p_pi_invoice_query_rec.invoice_date_from := p_inv_date_from;
        p_pi_invoice_query_rec.invoice_date_to   := p_inv_date_to;

      -- Invoice Type
      ELSIF  p_segment_type(l_index) = 'INVTYPE'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_invoice_type;

      -- Paid Status
      ELSIF  p_segment_type(l_index) = 'PAIDSTATUS'
      THEN
        p_pi_invoice_query_rec.paid_status :=
          xgv_common.r_decode(p_paid, 'Y', 'Y', NULL)
          || xgv_common.r_decode(p_notpaid, 'Y', 'N', NULL)
          || xgv_common.r_decode(p_partpaid, 'Y', 'P', NULL);

      -- Paid Status
      ELSIF  p_segment_type(l_index) = 'POSTSTATUS'
      THEN
        p_pi_invoice_query_rec.post_status :=
          xgv_common.r_decode(p_posted, 'Y', 'Y', NULL)
          || xgv_common.r_decode(p_unposted, 'Y', 'N', NULL)
          || xgv_common.r_decode(p_partposted, 'Y', 'P', NULL)
          || xgv_common.r_decode(p_selectposted, 'Y', 'S', NULL);

      -- Approval Method
      ELSIF  p_segment_type(l_index) = 'APPSTATUS'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_approvalstatus;

      -- Hold All Payments Status
      /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
      ELSIF  p_segment_type(l_index) = 'ALLHLDSTAT'
      THEN
        p_pi_invoice_query_rec.hold_all_status :=
          xgv_common.r_decode(p_all_holdstatus, 'Y', 'Y', NULL)
          || xgv_common.r_decode(p_no_all_holdstatus, 'Y', 'N', NULL);  /* Req#210004 23-Aug-2005 Changed by ytsujiha_jp */

      -- Held Status
      ELSIF  p_segment_type(l_index) = 'HOLDSTATUS'
      THEN
        p_pi_invoice_query_rec.hold_status := p_heldstatus;

      -- Invoice Number
      ELSIF  p_segment_type(l_index) = 'INVNUM'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_inv_num;

      -- Document Sequence Number
      ELSIF  p_segment_type(l_index) = 'APDOCNUM'
      THEN
        p_pi_invoice_query_rec.doc_seq_from := p_doc_seq_from;
        p_pi_invoice_query_rec.doc_seq_to   := p_doc_seq_to;

      -- Currency
      ELSIF  p_segment_type(l_index) = 'INVCUR'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_currency_code;

      -- Invoice Amount
      ELSIF  p_segment_type(l_index) = 'INVAMOUNT'
      THEN
        p_pi_invoice_query_rec.inv_amount_from := p_inv_amount_from;
        p_pi_invoice_query_rec.inv_amount_to   := p_inv_amount_to;

      -- Term Date
      ELSIF  p_segment_type(l_index) = 'TERMDATE'
      THEN
        p_pi_invoice_query_rec.term_date_from := p_term_date_from;
        p_pi_invoice_query_rec.term_date_to   := p_term_date_to;

      -- Term
      ELSIF  p_segment_type(l_index) = 'TERM'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_term;

      -- Payment Method
      ELSIF  p_segment_type(l_index) = 'PAYMETHOD'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_payment_method;

      -- Payment Group
      ELSIF  p_segment_type(l_index) = 'PAYGRP'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_payment_group;

      -- Invoice Header Description
      ELSIF  p_segment_type(l_index) = 'HDESC'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_header_description;

      -- Invoice Source
      ELSIF  p_segment_type(l_index) = 'SOURCE'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_source;

      -- Invoice Batch
      ELSIF  p_segment_type(l_index) = 'BATCH'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_batch;

      -- DFF of "Invoice"
      -- AFF
      ELSIF  xgv_common.is_number(p_segment_type(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(p_segment_type(l_index))) = 'AP_INVOICES'
        THEN
          l_index_h_dff_condition := l_index_h_dff_condition + 1;
          p_pi_invoice_query_rec.condition_tab(l_index) := p_h_dff_condition(l_index_h_dff_condition);

        ELSIF  xgv_common.get_flexfield_name(to_number(p_segment_type(l_index))) = 'GL#'
        THEN
          l_index_aff_condition := l_index_aff_condition + 1;
          p_pi_invoice_query_rec.condition_tab(l_index) := p_aff_condition(l_index_aff_condition);
        END IF;

      -- Invoice Distribution Type
      ELSIF  p_segment_type(l_index) = 'DTYPE'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_dist_type;

      -- Invoice Distribution Description
      ELSIF  p_segment_type(l_index) = 'DDESC'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_dist_description;

      -- GL Date
      ELSIF  p_segment_type(l_index) = 'GLDATE'
      THEN
        p_pi_invoice_query_rec.gl_date_from := p_gl_date_from;
        p_pi_invoice_query_rec.gl_date_to   := p_gl_date_to;

      -- Payment Currency
      ELSIF  p_segment_type(l_index) = 'PAYCUR'
      THEN
        p_pi_invoice_query_rec.condition_tab(l_index) := p_pay_currency_code;

      -- Payment Due Date
      ELSIF  p_segment_type(l_index) = 'DUEDATE'
      THEN
        p_pi_invoice_query_rec.due_date_from := p_due_date_from;
        p_pi_invoice_query_rec.due_date_to   := p_due_date_to;

      -- Payment Holds Flag
      /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
      ELSIF  p_segment_type(l_index) = 'HOLDFLAG'
      THEN
        p_pi_invoice_query_rec.hold_flag :=
          xgv_common.r_decode(p_pay_hold_flag, 'Y', 'Y', NULL)
          || xgv_common.r_decode(p_no_pay_hold_flag, 'Y', 'N', NULL);  /* Req#210005 23-Aug-2005 Changed by ytsujiha_jp */
      END IF;

    END LOOP;

  END set_query_condition_local;

  --==========================================================
  --Procedure Name: show_side_navigator
  --Description: Display side navigator for Payables inquiry
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
        || get_tag('TEXT_NEW_CONDITION', 'E', 'javascript:gotoPage(''piq'');');

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
        || get_tag('TEXT_OPEN_CONDITION', 'E', 'javascript:gotoPage(''piq.open'');');

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
  --Function Name: get_displayed_field
  --Description: Get "DISPLAYED_FIELD" from AP_LOOKUP_CODE
  --Note:
  --Parameter(s):
  --  p_lookup_type: Lookup type
  --  p_lookup_code: Lookup code
  --==========================================================
  FUNCTION get_displayed_field(
    p_lookup_type  IN VARCHAR2,
    p_lookup_code  IN VARCHAR2)
    RETURN VARCHAR2
  IS

    l_displayed_field  ap_lookup_codes.displayed_field%TYPE;

  BEGIN

    SELECT displayed_field
    INTO   l_displayed_field
    FROM   ap_lookup_codes
    WHERE  lookup_type = p_lookup_type
      AND  lookup_code = p_lookup_code;

    RETURN l_displayed_field;

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  NO_DATA_FOUND
    THEN
      RETURN NULL;

  END get_displayed_field;

  --==========================================================
  --Procedure Name: show_query_editor
  --Description: Display condition editor for Payables inquiry
  --Note:
  --Parameter(s):
  --  p_modify_flag         : Modify flag(Yes/No)
  --  p_pi_invoice_query_rec: Query condition record
  --==========================================================
  PROCEDURE show_query_editor(
    p_modify_flag          IN VARCHAR2,
    p_pi_invoice_query_rec IN xgv_common.ap_invoice_query_rtype)
  IS

    l_parent_segment_id  xgv_flex_structures_vl.parent_segment_id%TYPE;
    l_show_lov_proc  xgv_flex_structures_vl.show_lov_proc%TYPE;
    l_hide_flag  xgv_flex_structures_vl.hide_flag%TYPE;
    l_mandatory_flag  xgv_flex_structures_vl.mandatory_flag%TYPE;

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
      WHERE  xuiv.inquiry_type = 'PI'
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
        AND  xfsv.flexfield_name IN ('AP_INVOICES', 'AP_INVOICE_DISTRIBUTIONS')
        AND  xfsv.hide_flag = 'N'
      UNION ALL
      SELECT 4 order1,
             xfsv.segment_id order2,
             '<option value="' || to_char(xfsv.segment_id)
             || decode(to_char(xfsv.segment_id), p_default, '" selected>', '">')
             || xfsv.segment_name output_string
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
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
    htp.p('<input type="hidden" name="p_query_id" value="' || p_pi_invoice_query_rec.query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' || htf.escape_sc(p_pi_invoice_query_rec.query_name) || '">');

    htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">');

    htp.p('<tr>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td colspan="2" width="100%">');

    xgv_common.show_title(
      xgv_common.get_message('TITLE_CONDITION_NAME', nvl(p_pi_invoice_query_rec.query_name, ' ')),
      '<span class="OraTextInline">'
      || '<img src="/XGV_IMAGE/ii-required_status.gif">'
      || xgv_common.get_message('NOTE_MANDATORY_CONDITION'),
      p_fontsize=>'M');

    --------------------------------------------------
    -- Display query condition information
    --------------------------------------------------
    IF  p_pi_invoice_query_rec.query_name IS NOT NULL
    THEN
      htp.p('<table border="0" cellpadding="0" cellspacing="0">');

      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_CREATED_BY')
        ||  '</th>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<td class="OraDataText">'
        ||  xgv_common.escape_sc(xgv_common.get_user_name(p_pi_invoice_query_rec.created_by))
        ||  '</td>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_CREATION_DATE')
        ||  '</th>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<td class="OraDataText">' || p_pi_invoice_query_rec.creation_date || '</td>'
        ||  '</tr>');
      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_UPDATED_BY')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataText">'
        ||  xgv_common.escape_sc(xgv_common.get_user_name(p_pi_invoice_query_rec.last_updated_by))
        ||  '</td>'
        ||  '<td></td>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_UPDATE_DATE')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataText">' || p_pi_invoice_query_rec.last_update_date || '</td>'
        ||  '</tr>');
      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_COUNT_ROWS')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataNumber">' || to_char(p_pi_invoice_query_rec.result_rows, '999G999G999G990') || '</td>'
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
    htp.p('<table style="border-collapse:collapse" cellpadding="1" cellspacing="0">');

    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_BASIC_CONDITIONS'), p_fontsize=>'S');
    htp.p('</th>'
      ||  '</tr>');

    -- Display header line
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<table border="0" cellpadding="0" cellspacing="0">'
      ||  '<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_SHOW_AP_HEADER_LINE')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText" nowrap>'
      ||  '<input type="checkbox" name="p_show_header_line" value="Y"'
      ||  xgv_common.r_decode(
            instr(nvl(p_pi_invoice_query_rec.condition_tab(
              xgv_common.get_segment_index(p_pi_invoice_query_rec.segment_type_tab, 'LINENUM')), 'HDP'),
            'H'), 0, '>', ' checked>')
      ||  '</td>'
      ||  '</tr>'
      ||  '</table>'
      ||  '</th>'
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
    FOR  l_index IN 1..p_pi_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Data Refer(Hidden items)
      IF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'EXDD'
      THEN
        htp.p('<input type="hidden" name="p_show_order" value="'
          ||  p_pi_invoice_query_rec.show_order_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_sort_order" value="'
          ||  p_pi_invoice_query_rec.sort_order_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_sort_method" value="'
          ||  p_pi_invoice_query_rec.sort_method_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_segment_type" value="'
          ||  p_pi_invoice_query_rec.segment_type_tab(l_index) || '">');

      -- Line Number(Line Type)
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'LINENUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'LINENUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.get_message('TIP_AP_LINE_NUMBER')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LINENUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Vendor Name
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'VENDOR'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'VENDOR'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_vendor" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestVendors_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="VENDOR">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Vendor Site Name
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'VENDORSITE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'VENDORSITE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_vendor_site" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestVendorSites_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="VENDORSITE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');
      END IF;

    END LOOP;

    --------------------------------------------------
    -- Display invoice conditions
    --------------------------------------------------
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_INVOICE_CONDITIONS'), p_fontsize=>'S');
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
    FOR  l_index IN 1..p_pi_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Invoice Date
      IF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVP'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'INVP'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_inv_date_from" size="20" maxlength="11" value="'
          ||  p_pi_invoice_query_rec.invoice_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Invdate_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_inv_date_to" size="20" maxlength="11" value="'
          ||  p_pi_invoice_query_rec.invoice_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Invdate_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="INVP">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Type
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVTYPE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'INVTYPE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_invoice_type" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestInvoiceTypes_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="INVTYPE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Paid Status
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'PAIDSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'PAIDSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_paid" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.paid_status, '*'), 'Y'), 0, '>', ' checked>')
          ||  get_displayed_field('INVOICE PAYMENT STATUS', 'Y')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_notpaid" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.paid_status, '*'), 'N'), 0, '>', ' checked>')
          ||  get_displayed_field('INVOICE PAYMENT STATUS', 'N')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_partpaid" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.paid_status, '*'), 'P'), 0, '>', ' checked>')
          ||  get_displayed_field('INVOICE PAYMENT STATUS', 'P')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PAIDSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Posted Status
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'POSTSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_posted" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.post_status, '*'), 'Y'), 0, '>', ' checked>')
          ||  get_displayed_field('POSTING STATUS', 'Y')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_unposted" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.post_status, '*'), 'N'), 0, '>', ' checked>')
          ||  get_displayed_field('POSTING STATUS', 'N')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_partposted" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.post_status, '*'), 'P'), 0, '>', ' checked>')
          ||  get_displayed_field('POSTING STATUS', 'P')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_selectposted" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.post_status, '*'), 'S'), 0, '>', ' checked>')
          ||  get_displayed_field('POSTING STATUS', 'S')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="POSTSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Approval Method
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'APPSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'APPSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_approvalstatus" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestApprovalStatuses_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="APPSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Hold All Payments Status
      /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'ALLHLDSTAT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'ALLHLDSTAT'))
          ||  '</td>');
        /* Req#210004 23-Aug-2005 Changed by ytsujiha_jp */
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_all_holdstatus" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.hold_all_status, '*'), 'Y'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_HOLD_ALL_PAY_STATUS')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_no_all_holdstatus" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.hold_all_status, '*'), 'N'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_NO_HOLD_ALL_PAY_STATUS')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="ALLHLDSTAT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Held Status
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'HOLDSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'HOLDSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_heldstatus" value="Y"'
          ||  ' onClick="javascript:checkHoldStatus(''Y'')"'
          ||  xgv_common.r_decode(p_pi_invoice_query_rec.hold_status, 'Y', ' checked>', '>')
          ||  xgv_common.get_message('PROMPT_HELD')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_heldstatus" value="YR"'
          ||  ' onClick="javascript:checkHoldStatus(''YR'')"'
          ||  xgv_common.r_decode(p_pi_invoice_query_rec.hold_status, 'YR', ' checked>', '>')
          ||  xgv_common.get_message('PROMPT_HELDORRELEASE')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="HOLDSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Number
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'INVNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_inv_num" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="INVNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Document Sequence Number
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'APDOCNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'APDOCNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_doc_seq_from" size="20" maxlength="15" value="'
          ||  p_pi_invoice_query_rec.doc_seq_from
          ||  '">'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_doc_seq_to" size="20" maxlength="15" value="'
          ||  p_pi_invoice_query_rec.doc_seq_to
          ||  '">'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="APDOCNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Currency
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVCUR'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'INVCUR'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<select name="p_currency_code">');
        FOR  l_currency_rec IN xgv_common.g_tag_currency_cur(p_pi_invoice_query_rec.condition_tab(l_index), 'Y')
        LOOP
          htp.p(l_currency_rec.output_string);
        END LOOP;
        htp.p('</select>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="INVCUR">');
        IF  xgv_common.get_profile_option_value('XGV_ENABLE_SHOW_AP_RATE') = 'Y'
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
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Amount
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'INVAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_inv_amount_from" size="20" maxlength="15" value="'
          ||  p_pi_invoice_query_rec.inv_amount_from
          ||  '">'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_inv_amount_to" size="20" maxlength="15" value="'
          ||  p_pi_invoice_query_rec.inv_amount_to
          ||  '">'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="INVAMOUNT">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="INVBAMOUNT">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="DISCAMOUNT">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="PAIDAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Term Date
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'TERMDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'TERMDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_term_date_from" size="20" maxlength="11" value="'
          ||  p_pi_invoice_query_rec.term_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_TermDate_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_term_date_to" size="20" maxlength="11" value="'
          ||  p_pi_invoice_query_rec.term_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_TermDate_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="TERMDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Term
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'TERM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'TERM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_term" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestTerms_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="TERM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Method
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'PAYMETHOD'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'PAYMETHOD'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_payment_method" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestPayMethods_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PAYMETHOD">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Group
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'PAYGRP'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'PAYGRP'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_payment_group" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestPayGroups_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PAYGRP">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Header Description
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'HDESC'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'HDESC'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_header_description" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="HDESC">'
          ||  '</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Source
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'SOURCE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'SOURCE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_source" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestSources_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="SOURCE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Batch
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'BATCH'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'BATCH'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_batch" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestBatches_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="BATCH">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- DFF of "Invoice"
      ELSIF  xgv_common.is_number(p_pi_invoice_query_rec.segment_type_tab(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(p_pi_invoice_query_rec.segment_type_tab(l_index))) = 'AP_INVOICES'
        THEN
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
            AND  xfsv.segment_id = to_number(p_pi_invoice_query_rec.segment_type_tab(l_index));

          IF  l_hide_flag = 'N'
          THEN
            htp.p('<tr>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  xgv_common.r_decode(l_mandatory_flag,
                    'Y', '<img src="/XGV_IMAGE/ii-required_status.gif">', NULL)
              ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_pi_invoice_query_rec.segment_type_tab(l_index)))
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  '<input type="text" name="p_h_dff_condition" size="60" maxlength="100" value="'
              ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
              ||  '">'
              ||  xgv_common.r_nvl2(l_show_lov_proc,
                    '<a href="javascript:requestH_DFF_LOV('
                    ||  p_pi_invoice_query_rec.segment_type_tab(l_index) || ', ' || l_parent_segment_id || ')">'
                    ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
                    ||  '</a>',
                    '<img src="/XGV_IMAGE/ai-search_disabled.gif" border="0">')
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
            htp.p('</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_sort_order(
              p_pi_invoice_query_rec.sort_order_tab(l_index),
              p_pi_invoice_query_rec.sort_method_tab(l_index));
            htp.p('<input type="hidden" name="p_segment_type" value="'
              ||  p_pi_invoice_query_rec.segment_type_tab(l_index)
              ||  '">');
            htp.p('</td>');
            htp.p('<td></td>');
            htp.p('</tr>');

          ELSE
            htp.p('<input type="hidden" name="p_h_dff_condition" value="'
              ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index)) || '">'
              ||  '<input type="hidden" name="p_show_order" value="">'
              ||  '<input type="hidden" name="p_sort_order" value="">'
              ||  '<input type="hidden" name="p_sort_method" value="">'
              ||  '<input type="hidden" name="p_segment_type" value="'
              ||  p_pi_invoice_query_rec.segment_type_tab(l_index) || '">');
          END IF;
        END IF;
      END IF;

    END LOOP;

    --------------------------------------------------
    -- Display invoice distribution conditions
    --------------------------------------------------
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_INVOICE_DIST_CONDITIONS'), p_fontsize=>'S');
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
    FOR  l_index IN 1..p_pi_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Invoice Distribution Line Number
      IF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DLINENUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'DLINENUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="DLINENUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Distribution Type
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DTYPE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'DTYPE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_dist_type" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestDistTypes_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="DTYPE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Distribution Amount
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'DAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        IF  xgv_common.get_profile_option_value('XGV_ENABLE_SHOW_AP_RATE') = 'Y'
        THEN
          htp.p('<input type="hidden" name="p_show_order" value="">'
            ||  '<input type="hidden" name="p_sort_order" value="">'
            ||  '<input type="hidden" name="p_sort_method" value="">'
            ||  '<input type="hidden" name="p_segment_type" value="DTRANSDATE">');
          htp.p('<input type="hidden" name="p_show_order" value="">'
            ||  '<input type="hidden" name="p_sort_order" value="">'
            ||  '<input type="hidden" name="p_sort_method" value="">'
            ||  '<input type="hidden" name="p_segment_type" value="DTRANSTYPE">');
          htp.p('<input type="hidden" name="p_show_order" value="">'
            ||  '<input type="hidden" name="p_sort_order" value="">'
            ||  '<input type="hidden" name="p_sort_method" value="">'
            ||  '<input type="hidden" name="p_segment_type" value="DTRANSRATE">');
        END IF;
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="DAMOUNT">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="DBAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Distribution Tax Code
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DTAXCODE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'DTAXCODE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="DTAXCODE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Distribution Prepay Amount Remaining
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DREMAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'DREMAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="DREMAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Distribution Description
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DDESC'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'DDESC'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_dist_description" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="DDESC">'
          ||  '</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- DFF of "Invoice Distributions"
      ELSIF  xgv_common.is_number(p_pi_invoice_query_rec.segment_type_tab(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(p_pi_invoice_query_rec.segment_type_tab(l_index))) = 'AP_INVOICE_DISTRIBUTIONS'
        THEN
          SELECT nvl(xfsv.parent_segment_id, 0),
                 xfsv.show_lov_proc,
                 hide_flag
          INTO   l_parent_segment_id,
                 l_show_lov_proc,
                 l_hide_flag
          FROM   xgv_flex_structures_vl xfsv
          WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
            AND  xfsv.segment_id = to_number(p_pi_invoice_query_rec.segment_type_tab(l_index));

          IF  l_hide_flag = 'N'
          THEN
            htp.p('<tr>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_pi_invoice_query_rec.segment_type_tab(l_index)))
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
            htp.p('</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_sort_order(
              p_pi_invoice_query_rec.sort_order_tab(l_index),
              p_pi_invoice_query_rec.sort_method_tab(l_index));
            htp.p('<input type="hidden" name="p_segment_type" value="'
              ||  p_pi_invoice_query_rec.segment_type_tab(l_index)
              ||  '">');
            htp.p('</td>');
            htp.p('<td></td>');
            htp.p('</tr>');

          ELSE
            htp.p('<input type="hidden" name="p_show_order" value="">'
              ||  '<input type="hidden" name="p_sort_order" value="">'
              ||  '<input type="hidden" name="p_sort_method" value="">'
              ||  '<input type="hidden" name="p_segment_type" value="'
              ||  p_pi_invoice_query_rec.segment_type_tab(l_index) || '">');
          END IF;
        END IF;
      END IF;

    END LOOP;

    --------------------------------------------------
    -- Display AFF conditions
    --------------------------------------------------
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_AFF_CONDITIONS'), p_fontsize=>'S');
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
    FOR  l_index IN 1..p_pi_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- GL Date
      IF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'GLDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'GLDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_gl_date_from" size="20" maxlength="11" value="'
          ||  p_pi_invoice_query_rec.gl_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_GLPost_Date_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_gl_date_to" size="20" maxlength="11" value="'
          ||  p_pi_invoice_query_rec.gl_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_GLPost_Date_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="GLDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- AFF
      ELSIF  xgv_common.is_number(p_pi_invoice_query_rec.segment_type_tab(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(p_pi_invoice_query_rec.segment_type_tab(l_index))) = 'GL#'
        THEN
          SELECT nvl(xfsv.parent_segment_id, 0),
                 xfsv.show_lov_proc,
                 hide_flag
          INTO   l_parent_segment_id,
                 l_show_lov_proc,
                 l_hide_flag
          FROM   xgv_flex_structures_vl xfsv
          WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
            AND  xfsv.application_id = xgv_common.get_gl_appl_id
            AND  xfsv.segment_id = to_number(p_pi_invoice_query_rec.segment_type_tab(l_index));

          IF  l_hide_flag = 'N'
          THEN
            htp.p('<tr>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_pi_invoice_query_rec.segment_type_tab(l_index)))
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  '<input type="text" name="p_aff_condition" size="60" maxlength="100" value="'
              ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index))
              ||  '">'
              ||  xgv_common.r_nvl2(l_show_lov_proc,
                    '<a href="javascript:requestAFF_LOV('
                    ||  p_pi_invoice_query_rec.segment_type_tab(l_index) || ', ' || l_parent_segment_id || ')">'
                    ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
                    ||  '</a>',
                    '<img src="/XGV_IMAGE/ai-search_disabled.gif" border="0">')
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
            htp.p('</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_sort_order(
              p_pi_invoice_query_rec.sort_order_tab(l_index),
              p_pi_invoice_query_rec.sort_method_tab(l_index));
            htp.p('<input type="hidden" name="p_segment_type" value="'
              ||  p_pi_invoice_query_rec.segment_type_tab(l_index)
              ||  '">');
            htp.p('</td>');
            htp.p('<td></td>');
            htp.p('</tr>');

          ELSE
            htp.p('<input type="hidden" name="p_aff_condition" value="'
              ||  htf.escape_sc(p_pi_invoice_query_rec.condition_tab(l_index)) || '">'
              ||  '<input type="hidden" name="p_show_order" value="">'
              ||  '<input type="hidden" name="p_sort_order" value="">'
              ||  '<input type="hidden" name="p_sort_method" value="">'
              ||  '<input type="hidden" name="p_segment_type" value="'
              ||  p_pi_invoice_query_rec.segment_type_tab(l_index) || '">');
          END IF;
        END IF;
      END IF;

    END LOOP;

    --------------------------------------------------
    -- Display payment schedule and check conditions
    --------------------------------------------------
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_PAY_SCHEDULE_CONDITIONS'), p_fontsize=>'S');
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
    FOR  l_index IN 1..p_pi_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Payment Currency
      IF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'PAYCUR'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'PAYCUR'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<select name="p_pay_currency_code">');
        FOR  l_currency_rec IN xgv_common.g_tag_currency_cur(p_pi_invoice_query_rec.condition_tab(l_index), 'Y')
        LOOP
          htp.p(l_currency_rec.output_string);
        END LOOP;
        htp.p('</select>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PAYCUR">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Due Date
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DUEDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'DUEDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_due_date_from" size="20" maxlength="11" value="'
          ||  p_pi_invoice_query_rec.due_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Due_Date_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_due_date_to" size="20" maxlength="11" value="'
          ||  p_pi_invoice_query_rec.due_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Due_Date_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="DUEDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Holds Flag
      /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'HOLDFLAG'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'HOLDFLAG'))
          ||  '</td>');
        /* Req#210005 23-Aug-2005 Changed by ytsujiha_jp */
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_pay_hold_flag" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.hold_flag, '*'), 'Y'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_HOLD_PAY_FLAG')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_no_pay_hold_flag" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_pi_invoice_query_rec.hold_flag, '*'), 'N'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_NO_HOLD_PAY_FLAG')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="HOLDFLAG">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Paid By
      /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'PAIDBY'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', 'PAIDBY'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          p_pi_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PAIDBY">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Amount
      -- Payment Amount Remaining
      -- Paid Date
      ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) IN ('PAYAMOUNT', 'REMAMOUNT', 'PAIDDATE')
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('PI', p_pi_invoice_query_rec.segment_type_tab(l_index)))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_pi_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_pi_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_pi_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="'
          ||  p_pi_invoice_query_rec.segment_type_tab(l_index)
          ||  '">');
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
    FOR  l_break_key_rec IN l_tag_breakkey_cur(p_pi_invoice_query_rec.break_key)
    LOOP
      htp.p(l_break_key_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="checkbox" name="p_show_subtotalonly" value="Y"'
      ||  xgv_common.r_decode(p_pi_invoice_query_rec.show_subtotalonly, 'Y', ' checked>', '>')
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
      ||  xgv_common.r_decode(p_pi_invoice_query_rec.show_total, 'Y', ' checked>', '>')
      ||  '</td>'
      ||  '</tr>');

    -- Display bring forward line
    -- htp.p('<tr>'
    --   ||  '<th class="OraPromptText" nowrap>'
    --   ||  xgv_common.get_message('PROMPT_SHOW_BRINGFORWARD')
    --   ||  '</th>'
    --   ||  '<td></td>'
    --   ||  '<td class="OraDataText">'
    --   ||  '<input type="checkbox" name="p_show_bringforward" value="Y"'
    --   ||  xgv_common.r_decode(p_pi_invoice_query_rec.show_bringforward, 'Y', ' checked>', '>')
    --   ||  '</td>'
    --   ||  '</tr>');

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
    FOR  l_tag_result_format_rec IN l_tag_result_format_cur(p_pi_invoice_query_rec.result_format)  /* 13-May-2005 Changed by ytsujiha_jp */
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
      ||  htf.escape_sc(p_pi_invoice_query_rec.file_name) || '">'
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
  --Description: Display condition editor for Payables inquiry
  --Note:
  --Parameter(s):
  --  p_mode              : Display mode
  --                        (Editor/execute Background query/
  --                         count Rows/Save confirm/save Cnacel)
  --  p_modify_flag       : Modify flag(Yes/No)
  --  p_query_id          : Query id
  --  p_async_query_id    : Background query id
  --  p_query_name        : Query name
  --  p_show_header_line  : Display header line
  --  p_vendor            : Vendor name
  --  p_vendor_site       : Vendor site name
  --  p_inv_date_from     : Invoice date(From)
  --  p_inv_date_to       : Invoice date(To)
  --  p_invoice_type      : Invoice type
  --  p_paid              : Paid status(paid)
  --  p_notpaid           : Paid status(not paid)
  --  p_partpaid          : Paid status(partially paid)
  --  p_posted            : Posted status(posted)
  --  p_unposted          : Posted status(unposted)
  --  p_partposted        : Posted status(partially posted)
  --  p_selectposted      : Posted status(selectively posted)
  --  p_approvalstatus    : Approval status
  --  p_all_holdstatus    : Hold all payments status(Y)
  --  p_no_all_holdstatus : Hold all payments status(N)
  --  p_heldstatus        : Held status(Y, N, R)
  --  p_inv_num           : Invoice number
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_inv_amount_from   : Invoice amount(From)
  --  p_inv_amount_to     : Invoice amount(To)
  --  p_term_date_from    : Term date(From)
  --  p_term_date_to      : Term date(To)
  --  p_term              : Term
  --  p_payment_method    : Payment method
  --  p_payment_group     : Payment group
  --  p_header_description: Invoice header description
  --  p_source            : Invoice source
  --  p_batch             : Invoice batch
  --  p_h_dff_condition   : Segment condition of invoice header dff
  --  p_dist_type         : Invoice distribution type
  --  p_dist_description  : Invoice distribution description
  --  p_gl_date_from      : General Ledger posted date(From)
  --  p_gl_date_to        : General Ledger posted date(To)
  --  p_aff_condition     : Segment condition of aff
  --  p_pay_currency_code : Payment currency
  --  p_due_date_from     : Payment due date(From)
  --  p_due_date_to       : Payment due date(To)
  --  p_pay_hold_flag     : Payment holds flag(Y)
  --  p_no_pay_hold_flag  : Payment holds flag(N)
  --  p_show_order        : Segment display order
  --  p_sort_order        : Segment sort order
  --  p_sort_method       : Segment sort method
  --  p_segment_type      : Segment type
  --  p_break_key         : Break key
  --  p_show_subtotalonly : Display subtotal only
  --  p_show_total        : Display total
  --  p_show_bringforward : Display bring forward
  --  p_result_format     : Result format
  --  p_file_name         : Filename
  --==========================================================
  PROCEDURE top(
    p_mode               IN VARCHAR2 DEFAULT 'E',
    p_modify_flag        IN VARCHAR2 DEFAULT 'N',
    p_query_id           IN NUMBER   DEFAULT NULL,
    p_async_query_id     IN NUMBER   DEFAULT NULL,
    p_query_name         IN VARCHAR2 DEFAULT NULL,
    p_show_header_line   IN VARCHAR2 DEFAULT 'N',
    p_vendor             IN VARCHAR2 DEFAULT NULL,
    p_vendor_site        IN VARCHAR2 DEFAULT NULL,
    p_inv_date_from      IN VARCHAR2 DEFAULT NULL,
    p_inv_date_to        IN VARCHAR2 DEFAULT NULL,
    p_invoice_type       IN VARCHAR2 DEFAULT NULL,
    p_paid               IN VARCHAR2 DEFAULT 'N',
    p_notpaid            IN VARCHAR2 DEFAULT 'N',
    p_partpaid           IN VARCHAR2 DEFAULT 'N',
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_partposted         IN VARCHAR2 DEFAULT 'N',
    p_selectposted       IN VARCHAR2 DEFAULT 'N',
    p_approvalstatus     IN VARCHAR2 DEFAULT NULL,
    p_all_holdstatus     IN VARCHAR2 DEFAULT 'N',     /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
    p_no_all_holdstatus  IN VARCHAR2 DEFAULT 'N',     /* Req#210004 23-Aug-2005 Added by ytsujiha_jp */
    p_heldstatus         IN VARCHAR2 DEFAULT 'N',
    p_inv_num            IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_inv_amount_from    IN NUMBER   DEFAULT NULL,
    p_inv_amount_to      IN NUMBER   DEFAULT NULL,
    p_term_date_from     IN VARCHAR2 DEFAULT NULL,
    p_term_date_to       IN VARCHAR2 DEFAULT NULL,
    p_term               IN VARCHAR2 DEFAULT NULL,
    p_payment_method     IN VARCHAR2 DEFAULT NULL,
    p_payment_group      IN VARCHAR2 DEFAULT NULL,
    p_header_description IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_h_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_dist_type          IN VARCHAR2 DEFAULT NULL,
    p_dist_description   IN VARCHAR2 DEFAULT NULL,
    p_gl_date_from       IN VARCHAR2 DEFAULT NULL,
    p_gl_date_to         IN VARCHAR2 DEFAULT NULL,
    p_aff_condition      IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_pay_currency_code  IN VARCHAR2 DEFAULT NULL,
    p_due_date_from      IN VARCHAR2 DEFAULT NULL,
    p_due_date_to        IN VARCHAR2 DEFAULT NULL,
    p_pay_hold_flag      IN VARCHAR2 DEFAULT 'N',     /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
    p_no_pay_hold_flag   IN VARCHAR2 DEFAULT 'N',     /* Req#210005 23-Aug-2005 Added by ytsujiha_jp */
    p_show_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_method        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type       IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_break_key          IN VARCHAR2 DEFAULT NULL,
    p_show_subtotalonly  IN VARCHAR2 DEFAULT 'N',
    p_show_total         IN VARCHAR2 DEFAULT 'N',
    p_show_bringforward  IN VARCHAR2 DEFAULT 'N',
    p_result_format      IN VARCHAR2 DEFAULT NULL,
    p_file_name          IN VARCHAR2 DEFAULT NULL)
  IS

    l_pi_invoice_query_rec  xgv_common.ap_invoice_query_rtype;

    l_1st_h_dff_segment_id  xgv_flex_structures_vl.segment_id%TYPE;

    CURSOR l_mandatory_flag_cur
    IS
      SELECT xfsv.mandatory_flag mandatory_flag
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.flexfield_name = 'AP_INVOICES'
      ORDER BY xfsv.segment_id;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('PIQ.TOP');

    DECLARE
      l_cookie  owa_cookie.cookie;
    BEGIN
      /* Bug#211005 15-Sep-2005 Changed by ytsujiha_jp */
      l_cookie := owa_cookie.get('XGV_SESSION');
      IF  l_cookie.num_vals != 1
      THEN
        raise_application_error(-20025, xgv_common.get_message('XGV-20025'));
      END IF;
      IF  xgv_common.split(l_cookie.vals(1), ',', 1, 5) != xgv_common.APWI  /* Req#230009 30-Jul-2007 Changed by ytsujiha_jp */
      THEN
        owa_util.mime_header('text/html', FALSE);
        /* Bug#211005 15-Sep-2005 Changed by ytsujiha_jp */
        owa_cookie.send('XGV_SESSION',
          xgv_common.split(l_cookie.vals(1), ',', 1, 1) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 2) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 3) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 4) || ','
          || xgv_common.APWI || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 6));  /* Req#230009 30-Jul-2007 Changed by ytsujiha_jp */
        owa_util.http_header_close;

        htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
        htp.p('<html dir="ltr">');
        htp.p('<body>');
        htp.p('<form name="f_refresh" method="post" action="./xgv_piq.top"></form>');
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
      set_query_condition(l_pi_invoice_query_rec, p_query_id);

    -- Count rows
    ELSIF  p_mode = 'R'
    THEN
      -- Count rows
      xgv_common.open_output_dest('W');
      xgv_pie.execute_sql(
        p_query_id, p_query_name,
        p_show_header_line,
        p_vendor, p_vendor_site,
        p_inv_date_from, p_inv_date_to,
        p_invoice_type,
        p_paid, p_notpaid, p_partpaid,
        p_posted, p_unposted, p_partposted, p_selectposted,
        p_approvalstatus, p_all_holdstatus, p_no_all_holdstatus, p_heldstatus,  /* Req#210004 23-Aug-2005 Changed by ytsujiha_jp */
        p_inv_num, p_doc_seq_from, p_doc_seq_to,
        p_currency_code, p_inv_amount_from, p_inv_amount_to,
        p_term_date_from, p_term_date_to, p_term,
        p_payment_method, p_payment_group, p_header_description,
        p_source, p_batch, p_h_dff_condition,
        p_dist_type, p_dist_description,
        p_gl_date_from, p_gl_date_to, p_aff_condition,
        p_pay_currency_code, p_due_date_from, p_due_date_to,
        p_pay_hold_flag, p_no_pay_hold_flag,                        /* Req#210005 23-Aug-2005 Changed by ytsujiha_jp */
        p_show_order, p_sort_order, p_sort_method, p_segment_type,
        NULL, 'N', 'N', 'N', 'COUNT', NULL);

      -- Set query condition
      set_query_condition_local(
        l_pi_invoice_query_rec, p_query_id,
        p_show_header_line,
        p_vendor, p_vendor_site, p_inv_date_from, p_inv_date_to,
        p_invoice_type, p_paid, p_notpaid, p_partpaid,
        p_posted, p_unposted, p_partposted, p_selectposted,
        p_approvalstatus, p_all_holdstatus, p_no_all_holdstatus, p_heldstatus,  /* Req#210004 23-Aug-2005 Changed by ytsujiha_jp */
        p_inv_num, p_doc_seq_from, p_doc_seq_to, p_currency_code,
        p_inv_amount_from, p_inv_amount_to,
        p_term_date_from, p_term_date_to,
        p_term, p_payment_method, p_payment_group, p_header_description,
        p_source, p_batch, p_h_dff_condition,
        p_dist_type, p_dist_description,
        p_gl_date_from, p_gl_date_to, p_aff_condition,
        p_pay_currency_code, p_due_date_from, p_due_date_to,
        p_pay_hold_flag, p_no_pay_hold_flag,                                  /* Req#210005 23-Aug-2005 Changed by ytsujiha_jp */
        p_show_order, p_sort_order, p_sort_method, p_segment_type,
        p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
        p_result_format, p_file_name, NULL);

    ELSE
      -- Set query condition
      set_query_condition_local(
        l_pi_invoice_query_rec, p_query_id,
        p_show_header_line,
        p_vendor, p_vendor_site, p_inv_date_from, p_inv_date_to,
        p_invoice_type, p_paid, p_notpaid, p_partpaid,
        p_posted, p_unposted, p_partposted, p_selectposted,
        p_approvalstatus, p_all_holdstatus, p_no_all_holdstatus, p_heldstatus,  /* Req#210004 23-Aug-2005 Changed by ytsujiha_jp */
        p_inv_num, p_doc_seq_from, p_doc_seq_to, p_currency_code,
        p_inv_amount_from, p_inv_amount_to,
        p_term_date_from, p_term_date_to,
        p_term, p_payment_method, p_payment_group, p_header_description,
        p_source, p_batch, p_h_dff_condition,
        p_dist_type, p_dist_description,
        p_gl_date_from, p_gl_date_to, p_aff_condition,
        p_pay_currency_code, p_due_date_from, p_due_date_to,
        p_pay_hold_flag, p_no_pay_hold_flag,                                  /* Req#210005 23-Aug-2005 Changed by ytsujiha_jp */
        p_show_order, p_sort_order, p_sort_method, p_segment_type,
        p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
        p_result_format, p_file_name, NULL);
    END IF;

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<script language="JavaScript">');
    htp.p('<!--');
    htp.p('window.name = "xgv_main";');
    htp.p('// -->');
    htp.p('</script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_AP_INVOICE_INQUIRY', xgv_common.get_resp_name) || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();">');

    -- Display Header
    xgv_common.show_header(
      xgv_common.get_global_buttons_tag('MAIN'),
      xgv_common.get_tabs_tag('PIQ'));

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr style="vertical-align: top">');

    -- Display side navigator
    htp.p('<td>');
    show_side_navigator('EDITOR');
    htp.p('</td>');

    -- Display condition editor for query condition
    htp.p('<td width="100%">');

    -- Display Count Rows
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

    ELSIF  p_mode = 'R'
    THEN
      htp.prn('<script>t(1, 7);</script>');
      xgv_common.show_messagebox('C',
        'MESSAGE_COUNT_ROWS', ltrim(to_char(l_pi_invoice_query_rec.result_rows, '999G999G999G990')));

    -- Display svae confirmation message
    ELSIF  p_mode = 'S'
    THEN
      htp.prn('<script>t(1, 7);</script>');
      xgv_common.show_messagebox('C', 'MESSAGE_SAVE_CONDITION');
    END IF;

    -- Display title
    htp.prn('<script>t(1, 7);</script>');
    xgv_common.show_title(
      xgv_common.get_message('TITLE_AP_INVOICE_INQUIRY', xgv_common.get_resp_name),
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
    show_query_editor(p_modify_flag, l_pi_invoice_query_rec);

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

    FOR  l_index IN 1..l_pi_invoice_query_rec.segment_type_tab.COUNT
    LOOP
      IF  xgv_common.is_number(l_pi_invoice_query_rec.segment_type_tab(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(l_pi_invoice_query_rec.segment_type_tab(l_index))) = 'AP_INVOICES'
        THEN
          l_1st_h_dff_segment_id := to_number(l_pi_invoice_query_rec.segment_type_tab(l_index));
          EXIT;
        END IF;
      END IF;
    END LOOP;

    htp.p('<form name="f_information">');
    htp.p('<input type="hidden" name="p_functional_currency" value="' || xgv_common.get_functional_currency || '">');
    htp.p('<input type="hidden" name="p_1st_h_dff_segment_id" value="' || to_char(l_1st_h_dff_segment_id) || '">');
    htp.p('</form>');

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
    htp.p('<input type="hidden" name="p_year" value="' || to_char(sysdate, 'RRRR') ||'">');
    htp.p('<input type="hidden" name="p_month" value="' || to_char(sysdate, 'MM') ||'">');
    htp.p('<input type="hidden" name="p_element_id" value="">');
    htp.p('<input type="hidden" name="p_date_mask" value="' || xgv_common.get_date_mask || '">');
    htp.p('</form>');

    htp.p('<form name="f_lov_vendors" method="post" action="./xgv_piq.show_lov_vendors" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_vendor_sites" method="post" action="./xgv_piq.show_lov_vendor_sites" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_vendor_condition" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_invoice_types" method="post" action="./xgv_piq.show_lov_invoice_types" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_approval_statuses" method="post" action="./xgv_piq.show_lov_approval_statuses" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_terms" method="post" action="./xgv_piq.show_lov_terms" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_pay_methods" method="post" action="./xgv_piq.show_lov_pay_methods" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_pay_groups" method="post" action="./xgv_piq.show_lov_pay_groups" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_sources" method="post" action="./xgv_piq.show_lov_sources" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_batches" method="post" action="./xgv_piq.show_lov_batches" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_h_dff" method="post" action="./xgv_piq.show_lov_h_dff" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_child_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_condition" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_dist_types" method="post" action="./xgv_piq.show_lov_dist_types" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_aff" method="post" action="./xgv_piq.show_lov_aff" target="xgv_lov">');
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
  --Procedure Name: show_lov_vendors
  --Description: Display LOV for vendors
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_vendors(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_VENDORS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_PI_VENDORS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_vendor.value">');

    l_sql_rec.text(1) := 'SELECT count(pv.vendor_id)';
    l_sql_rec.text(2) := 'FROM   po_vendors pv';
    l_sql_rec.text(3) := 'WHERE  pv.enabled_flag = ''Y''';
    l_sql_rec.text(4) := '  AND  EXISTS';                                 /* 15-Jun-2005 Added by ytsujiha_jp */
    l_sql_rec.text(5) := '       (SELECT pvs.vendor_site_id';
    l_sql_rec.text(6) := '        FROM   po_vendor_sites pvs';
    l_sql_rec.text(7) := '        WHERE  pvs.vendor_id = pv.vendor_id';   /* Bug#230027 04-Dec-2007 Changed by ytsujiha_jp */
    l_sql_rec.text(8) := '          AND  ROWNUM <= 1)';                   /* Bug#230027 04-Dec-2007 Changed by ytsujiha_jp */

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'pv', 'segment1', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(pv.vendor_name) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT pv.segment1, pv.vendor_name';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY pv.segment1 ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY pv.vendor_name ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_PI_VENDORS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_vendors', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addVendorsValue();');

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

  END show_lov_vendors;

  --==========================================================
  --Procedure Name: show_lov_vendor_sites
  --Description: Display LOV for vendor sites
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --  p_vendor_condition : Condition of Vendor
  --==========================================================
  PROCEDURE show_lov_vendor_sites(
    p_list_filter_item  IN VARCHAR2 DEFAULT 'VALUE',
    p_list_filter_value IN VARCHAR2 DEFAULT NULL,
    p_start_listno      IN NUMBER   DEFAULT 1,
    p_sort_item         IN VARCHAR2 DEFAULT 'VALUE',
    p_sort_method       IN VARCHAR2 DEFAULT 'ASC',
    p_vendor_condition  IN VARCHAR2 DEFAULT NULL)
  IS

    l_sql_rec  xgv_common.sql_rtype;
    l_count_sql  VARCHAR2(32767);
    l_list_sql  VARCHAR2(32767);

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('PIQ.SHOW_LOV_VENDOR_SITES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_PI_VENDOR_SITES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_vendor_site.value">');

    l_sql_rec.text(1) := 'SELECT count(pvs.vendor_site_id)';
    l_sql_rec.text(2) := 'FROM   po_vendors pv,';
    l_sql_rec.text(3) := '       po_vendor_sites pvs';
    l_sql_rec.text(4) := 'WHERE  pv.enabled_flag = ''Y''';
    l_sql_rec.text(5) := '  AND  pvs.vendor_id = pv.vendor_id';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'pvs', 'vendor_site_code', p_list_filter_value,
          'pv', 'segment1');
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(pvs.vendor_site_code_alt) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    IF  p_vendor_condition IS NOT NULL
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
      xgv_common.get_where_clause(
        l_sql_rec, 'pv', 'segment1', p_vendor_condition);
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT pv.segment1, pv.vendor_name, pvs.vendor_site_code, nvl(pvs.vendor_site_code_alt, pvs.vendor_site_code)';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY pv.segment1, pvs.vendor_site_code ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY pv.vendor_name, pvs.vendor_site_code_alt ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_PI_VENDOR_SITES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_vendor_sites',
      '<input type="hidden" name="p_vendor_condition" value="' || htf.escape_sc(p_vendor_condition) ||'">',
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addVendorSitesValue();',
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

  END show_lov_vendor_sites;

  --==========================================================
  --Procedure Name: show_lov_invoice_types
  --Description: Display LOV for invoice types
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_invoice_types(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_INVOICE_TYPES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_PI_INVOICE_TYPES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_invoice_type.value">');

    l_sql_rec.text(1) := 'SELECT count(alc.displayed_field)';
    l_sql_rec.text(2) := 'FROM   ap_lookup_codes alc';
    l_sql_rec.text(3) := 'WHERE  alc.lookup_type = ''INVOICE TYPE''';
    l_sql_rec.text(4) := '  AND  alc.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'alc', 'displayed_field', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(alc.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT alc.displayed_field, alc.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.displayed_field ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_PI_INVOICE_TYPES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_invoice_types', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addInvoiceTypesValue();');

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

  END show_lov_invoice_types;

  --==========================================================
  --Procedure Name: show_lov_approval_statuses
  --Description: Display LOV for approval statuses
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_approval_statuses(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_APPROVAL_STATUSES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_PI_APPROVAL_STATUS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_approvalstatus.value">');

    l_sql_rec.text(1)  := 'SELECT count(alc.displayed_field)';
    l_sql_rec.text(2)  := 'FROM';
    l_sql_rec.text(3)  := '       (SELECT *';
    l_sql_rec.text(4)  := '        FROM   ap_lookup_codes';
    l_sql_rec.text(5)  := '        WHERE  lookup_type = ''NLS TRANSLATION''';
    l_sql_rec.text(6)  := '          AND  lookup_code IN (''APPROVED'', ''NEEDS REAPPROVAL'', ''NEVER APPROVED'', ''CANCELLED'')';
    l_sql_rec.text(7)  := '        UNION ALL';
    l_sql_rec.text(8)  := '        SELECT *';
    l_sql_rec.text(9)  := '        FROM   ap_lookup_codes';
    l_sql_rec.text(10) := '        WHERE  lookup_type = ''PREPAY STATUS''';
    l_sql_rec.text(11) := '          AND  lookup_code IN (''AVAILABLE'', ''CANCELLED'', ''FULL'', ''PERMANENT'', ''UNAPPROVED'', ''UNPAID'')';
    l_sql_rec.text(12) := '       ) alc';
    l_sql_rec.text(13) := 'WHERE  alc.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'alc', 'displayed_field', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(alc.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT alc.displayed_field, alc.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.displayed_field ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_PI_APPROVAL_STATUS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_approval_statuses', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addApprovalStatusesValue();');

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

  END show_lov_approval_statuses;

  --==========================================================
  --Procedure Name: show_lov_terms
  --Description: Display LOV for terms
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_terms(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_TERMS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_PI_TERMS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_term.value">');

    l_sql_rec.text(1) := 'SELECT count(at.term_id)';
    l_sql_rec.text(2) := 'FROM   ap_terms at';
    l_sql_rec.text(3) := 'WHERE  at.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'at', 'name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(at.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT at.name, at.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY at.name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY at.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_PI_TERMS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_terms', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addTermsValue();');

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

  END show_lov_terms;

  --==========================================================
  --Procedure Name: show_lov_pay_methods
  --Description: Display LOV for pay methods
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_pay_methods(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_PAY_METHODS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_PI_PAY_METHODS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_payment_method.value">');

    l_sql_rec.text(1) := 'SELECT count(alc.displayed_field)';
    l_sql_rec.text(2) := 'FROM   ap_lookup_codes alc';
    l_sql_rec.text(3) := 'WHERE  alc.lookup_type = ''PAYMENT METHOD''';
    l_sql_rec.text(4) := '  AND  alc.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'alc', 'displayed_field', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(alc.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT alc.displayed_field, alc.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.displayed_field ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_PI_PAY_METHODS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_pay_methods', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addPayMethodsValue();');

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

  END show_lov_pay_methods;

  --==========================================================
  --Procedure Name: show_lov_pay_groups
  --Description: Display LOV for pay methods
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_pay_groups(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_PAY_GROUPS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_PI_PAY_GROUPS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_payment_group.value">');

    l_sql_rec.text(1) := 'SELECT count(plc.displayed_field)';
    l_sql_rec.text(2) := 'FROM   po_lookup_codes plc';
    l_sql_rec.text(3) := 'WHERE  plc.lookup_type = ''PAY GROUP''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'plc', 'displayed_field', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(plc.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT plc.displayed_field, plc.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY plc.displayed_field ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY plc.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_PI_PAY_GROUPS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_pay_groups', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addPayGroupsValue();');

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

  END show_lov_pay_groups;

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
    xgv_common.write_access_log('PIQ.SHOW_LOV_SOURCES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_SOURCES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_source.value">');

    l_sql_rec.text(1) := 'SELECT count(alc.displayed_field)';
    l_sql_rec.text(2) := 'FROM   ap_lookup_codes alc';
    l_sql_rec.text(3) := 'WHERE  alc.lookup_type = ''SOURCE''';
    l_sql_rec.text(4) := '  AND  alc.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'alc', 'displayed_field', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(alc.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT alc.displayed_field, alc.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.displayed_field ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_SOURCES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_sources', NULL,
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
  --Procedure Name: show_lov_batches
  --Description: Display LOV for batches
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_batches(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_BATCHES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_BATCHES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_batch.value">');

    htp.p('<body class="OraBody" onLoad="window.focus();">');

    l_sql_rec.text(1) := 'SELECT count(ab.batch_id)';
    l_sql_rec.text(2) := 'FROM   ap_batches ab';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'WHERE (';
        xgv_common.get_where_clause(
          l_sql_rec, 'ab', 'batch_name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'WHERE upper(ab.batch_name) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT ab.batch_name, ab.batch_name';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY ab.batch_name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY ab.batch_name ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_BATCHES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_batches', NULL,
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
  --Procedure Name: show_lov_h_dff
  --Description: Display LOV for header DFF
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
  PROCEDURE show_lov_h_dff(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_H_DFF');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>'
      ||  xgv_common.get_message('TITLE_LOV_AFF_DFF', xgv_common.get_segment_name(p_child_segment_id))
      ||  '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true; setSelectValue();">');

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
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_h_dff',
        '<input type="hidden" name="p_child_segment_id" value="' || p_child_segment_id || '">'
        || '<input type="hidden" name="p_parent_segment_id" value="' || p_parent_segment_id || '">'
        || '<input type="hidden" name="p_parent_condition" value="' || htf.escape_sc(p_parent_condition) || '">',
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addH_DFFValue(' || to_char(p_child_segment_id) || ');',
      p_used_parent_value=>TRUE);

    htp.p('</body>');

    htp.p('</html>');

    htp.p('<script language="JavaScript">');
    htp.p('<!--  ');
    htp.p('function setSelectValue()');
    htp.p('{');
    htp.p('  if (isNaN(window.opener.document.f_query.p_h_dff_condition.length))');
    htp.p('  { document.f_select_value.p_select_values.value=window.opener.document.f_query.p_h_dff_condition.value; }');
    htp.p('  else');
    htp.p('  { document.f_select_value.p_select_values.value=window.opener.document.f_query.p_h_dff_condition['
      ||  to_char(p_child_segment_id) || ' - window.opener.document.f_information.p_1st_h_dff_segment_id.value].value; }');
    htp.p('}');
    htp.p('//-->  ');
    htp.p('</script>');

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

  END show_lov_h_dff;

  --==========================================================
  --Procedure Name: show_lov_dist_types
  --Description: Display LOV for distribution types
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_dist_types(
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
    xgv_common.write_access_log('PIQ.SHOW_LOV_DIST_TYPES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_PI_DIST_TYPES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_dist_type.value">');

    l_sql_rec.text(1) := 'SELECT count(alc.displayed_field)';
    l_sql_rec.text(2) := 'FROM   ap_lookup_codes alc';
    l_sql_rec.text(3) := 'WHERE  alc.lookup_type = ''INVOICE DISTRIBUTION TYPE''';
    l_sql_rec.text(4) := '  AND  alc.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'alc', 'displayed_field', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(alc.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT alc.displayed_field, alc.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.displayed_field ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY alc.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_PI_DIST_TYPES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_dist_types', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addDistTypesValues();');

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

  END show_lov_dist_types;

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
    xgv_common.write_access_log('PIQ.SHOW_LOV_AFF');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
    htp.p('<title>'
      ||  xgv_common.get_message('TITLE_LOV_AFF_DFF', xgv_common.get_segment_name(p_child_segment_id))
      ||  '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_aff_condition['
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
      p_list_filter_item, p_list_filter_value, './xgv_piq.show_lov_aff',
        '<input type="hidden" name="p_child_segment_id" value="' || p_child_segment_id || '">'
        || '<input type="hidden" name="p_parent_segment_id" value="' || p_parent_segment_id || '">'
        || '<input type="hidden" name="p_parent_condition" value="' || htf.escape_sc(p_parent_condition) || '">',
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addAFFValue(' || to_char(p_child_segment_id) || ');',
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
  --  p_show_header_line  : Display header line
  --  p_vendor            : Vendor name
  --  p_vendor_site       : Vendor site name
  --  p_inv_date_from     : Invoice date(From)
  --  p_inv_date_to       : Invoice date(To)
  --  p_invoice_type      : Invoice type
  --  p_paid              : Paid status(paid)
  --  p_notpaid           : Paid status(not paid)
  --  p_partpaid          : Paid status(partially paid)
  --  p_posted            : Posted status(posted)
  --  p_unposted          : Posted status(unposted)
  --  p_partposted        : Posted status(partially posted)
  --  p_selectposted      : Posted status(selectively posted)
  --  p_approvalstatus    : Approval status
  --  p_all_holdstatus    : Hold all payments status(Y)
  --  p_no_all_holdstatus : Hold all payments status(N)
  --  p_heldstatus        : Held status(Y, N, R)
  --  p_inv_num           : Invoice number
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_inv_amount_from   : Invoice amount(From)
  --  p_inv_amount_to     : Invoice amount(To)
  --  p_term_date_from    : Term date(From)
  --  p_term_date_to      : Term date(To)
  --  p_term              : Term
  --  p_payment_method    : Payment method
  --  p_payment_group     : Payment group
  --  p_header_description: Invoice header description
  --  p_source            : Invoice source
  --  p_batch             : Invoice batch
  --  p_h_dff_condition   : Segment condition of invoice header dff
  --  p_dist_type         : Invoice distribution type
  --  p_dist_description  : Invoice distribution description
  --  p_gl_date_from      : General Ledger posted date(From)
  --  p_gl_date_to        : General Ledger posted date(To)
  --  p_aff_condition     : Segment condition of aff
  --  p_pay_currency_code : Payment currency
  --  p_due_date_from     : Payment due date(From)
  --  p_due_date_to       : Payment due date(To)
  --  p_pay_hold_flag     : Payment holds flag(Y)
  --  p_no_pay_hold_flag  : Payment holds flag(N)
  --  p_show_order        : Segment show order
  --  p_sort_order        : Segment sort order
  --  p_sort_method       : Segment sort method
  --  p_segment_type      : Segment type
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
    p_show_header_line   IN VARCHAR2 DEFAULT 'N',
    p_vendor             IN VARCHAR2 DEFAULT NULL,
    p_vendor_site        IN VARCHAR2 DEFAULT NULL,
    p_inv_date_from      IN VARCHAR2 DEFAULT NULL,
    p_inv_date_to        IN VARCHAR2 DEFAULT NULL,
    p_invoice_type       IN VARCHAR2 DEFAULT NULL,
    p_paid               IN VARCHAR2 DEFAULT 'N',
    p_notpaid            IN VARCHAR2 DEFAULT 'N',
    p_partpaid           IN VARCHAR2 DEFAULT 'N',
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_partposted         IN VARCHAR2 DEFAULT 'N',
    p_selectposted       IN VARCHAR2 DEFAULT 'N',
    p_approvalstatus     IN VARCHAR2 DEFAULT NULL,
    p_all_holdstatus     IN VARCHAR2 DEFAULT 'N',     /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
    p_no_all_holdstatus  IN VARCHAR2 DEFAULT 'N',     /* Req#210004 23-Aug-2005 Added by ytsujiha_jp */
    p_heldstatus         IN VARCHAR2 DEFAULT 'N',
    p_inv_num            IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_inv_amount_from    IN NUMBER   DEFAULT NULL,
    p_inv_amount_to      IN NUMBER   DEFAULT NULL,
    p_term_date_from     IN VARCHAR2 DEFAULT NULL,
    p_term_date_to       IN VARCHAR2 DEFAULT NULL,
    p_term               IN VARCHAR2 DEFAULT NULL,
    p_payment_method     IN VARCHAR2 DEFAULT NULL,
    p_payment_group      IN VARCHAR2 DEFAULT NULL,
    p_header_description IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_h_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_dist_type          IN VARCHAR2 DEFAULT NULL,
    p_dist_description   IN VARCHAR2 DEFAULT NULL,
    p_gl_date_from       IN VARCHAR2 DEFAULT NULL,
    p_gl_date_to         IN VARCHAR2 DEFAULT NULL,
    p_aff_condition      IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_pay_currency_code  IN VARCHAR2 DEFAULT NULL,
    p_due_date_from      IN VARCHAR2 DEFAULT NULL,
    p_due_date_to        IN VARCHAR2 DEFAULT NULL,
    p_pay_hold_flag      IN VARCHAR2 DEFAULT 'N',     /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
    p_no_pay_hold_flag   IN VARCHAR2 DEFAULT 'N',     /* Req#210005 23-Aug-2005 Added by ytsujiha_jp */
    p_show_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_method        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type       IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
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
    xgv_common.write_access_log('PIQ.REQUEST_ASYNC_EXEC');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
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
      xgv_common.get_tabs_tag('PIQ'));

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

    htp.p('<form name="f_submitasync" method="post" action="./xgv_pie.submit_request_async_exec">');
    htp.p('<input type="hidden" name="p_execute_time" value="">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_show_header_line" value="' || p_show_header_line || '">');
    htp.p('<input type="hidden" name="p_vendor" value="' || htf.escape_sc(p_vendor) || '">');
    htp.p('<input type="hidden" name="p_vendor_site" value="' || htf.escape_sc(p_vendor_site) || '">');
    htp.p('<input type="hidden" name="p_inv_date_from" value="' || p_inv_date_from || '">');
    htp.p('<input type="hidden" name="p_inv_date_to" value="' || p_inv_date_to || '">');
    htp.p('<input type="hidden" name="p_invoice_type" value="' || htf.escape_sc(p_invoice_type) || '">');
    htp.p('<input type="hidden" name="p_paid" value="' || p_paid || '">');
    htp.p('<input type="hidden" name="p_notpaid" value="' || p_notpaid || '">');
    htp.p('<input type="hidden" name="p_partpaid" value="' || p_partpaid || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_partposted" value="' || p_partposted || '">');
    htp.p('<input type="hidden" name="p_selectposted" value="' || p_selectposted || '">');
    htp.p('<input type="hidden" name="p_approvalstatus" value="' || htf.escape_sc(p_approvalstatus) || '">');
    htp.p('<input type="hidden" name="p_all_holdstatus" value="' || p_all_holdstatus || '">');        /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_no_all_holdstatus" value="' || p_no_all_holdstatus || '">');  /* Req#210004 23-Aug-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_heldstatus" value="' || p_heldstatus || '">');
    htp.p('<input type="hidden" name="p_inv_num" value="' || htf.escape_sc(p_inv_num) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || p_doc_seq_from || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || p_doc_seq_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_inv_amount_from" value="' || p_inv_amount_from || '">');
    htp.p('<input type="hidden" name="p_inv_amount_to" value="' || p_inv_amount_to || '">');
    htp.p('<input type="hidden" name="p_term_date_from" value="' || p_term_date_from || '">');
    htp.p('<input type="hidden" name="p_term_date_to" value="' || p_term_date_to || '">');
    htp.p('<input type="hidden" name="p_term" value="' || htf.escape_sc(p_term) || '">');
    htp.p('<input type="hidden" name="p_payment_method" value="' || htf.escape_sc(p_payment_method) || '">');
    htp.p('<input type="hidden" name="p_payment_group" value="' || htf.escape_sc(p_payment_group) || '">');
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    FOR  l_index IN 1..p_h_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_h_dff_condition" value="' || htf.escape_sc(p_h_dff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_dist_type" value="' || htf.escape_sc(p_dist_type) || '">');
    htp.p('<input type="hidden" name="p_dist_description" value="' || htf.escape_sc(p_dist_description) || '">');
    htp.p('<input type="hidden" name="p_gl_date_from" value="' || p_gl_date_from || '">');
    htp.p('<input type="hidden" name="p_gl_date_to" value="' || p_gl_date_to || '">');
    FOR  l_index IN 1..p_aff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_aff_condition" value="' || htf.escape_sc(p_aff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_pay_currency_code" value="' || p_pay_currency_code || '">');
    htp.p('<input type="hidden" name="p_due_date_from" value="' || p_due_date_from || '">');
    htp.p('<input type="hidden" name="p_due_date_to" value="' || p_due_date_to || '">');
    htp.p('<input type="hidden" name="p_pay_hold_flag" value="' || p_pay_hold_flag || '">');        /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_no_pay_hold_flag" value="' || p_no_pay_hold_flag || '">');  /* Req#210005 23-Aug-2005 Added by ytsujiha_jp */
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

    htp.p('<form name="f_cancelasync" method="post" action="./xgv_piq.top">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_show_header_line" value="' || p_show_header_line || '">');
    htp.p('<input type="hidden" name="p_vendor" value="' || htf.escape_sc(p_vendor) || '">');
    htp.p('<input type="hidden" name="p_vendor_site" value="' || htf.escape_sc(p_vendor_site) || '">');
    htp.p('<input type="hidden" name="p_inv_date_from" value="' || p_inv_date_from || '">');
    htp.p('<input type="hidden" name="p_inv_date_to" value="' || p_inv_date_to || '">');
    htp.p('<input type="hidden" name="p_invoice_type" value="' || htf.escape_sc(p_invoice_type) || '">');
    htp.p('<input type="hidden" name="p_paid" value="' || p_paid || '">');
    htp.p('<input type="hidden" name="p_notpaid" value="' || p_notpaid || '">');
    htp.p('<input type="hidden" name="p_partpaid" value="' || p_partpaid || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_partposted" value="' || p_partposted || '">');
    htp.p('<input type="hidden" name="p_selectposted" value="' || p_selectposted || '">');
    htp.p('<input type="hidden" name="p_approvalstatus" value="' || htf.escape_sc(p_approvalstatus) || '">');
    htp.p('<input type="hidden" name="p_all_holdstatus" value="' || p_all_holdstatus || '">');        /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_no_all_holdstatus" value="' || p_no_all_holdstatus || '">');  /* Req#210004 23-Aug-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_heldstatus" value="' || p_heldstatus || '">');
    htp.p('<input type="hidden" name="p_inv_num" value="' || htf.escape_sc(p_inv_num) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || p_doc_seq_from || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || p_doc_seq_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_inv_amount_from" value="' || p_inv_amount_from || '">');
    htp.p('<input type="hidden" name="p_inv_amount_to" value="' || p_inv_amount_to || '">');
    htp.p('<input type="hidden" name="p_term_date_from" value="' || p_term_date_from || '">');
    htp.p('<input type="hidden" name="p_term_date_to" value="' || p_term_date_to || '">');
    htp.p('<input type="hidden" name="p_term" value="' || htf.escape_sc(p_term) || '">');
    htp.p('<input type="hidden" name="p_payment_method" value="' || htf.escape_sc(p_payment_method) || '">');
    htp.p('<input type="hidden" name="p_payment_group" value="' || htf.escape_sc(p_payment_group) || '">');
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    FOR  l_index IN 1..p_h_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_h_dff_condition" value="' || htf.escape_sc(p_h_dff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_dist_type" value="' || htf.escape_sc(p_dist_type) || '">');
    htp.p('<input type="hidden" name="p_dist_description" value="' || htf.escape_sc(p_dist_description) || '">');
    htp.p('<input type="hidden" name="p_gl_date_from" value="' || p_gl_date_from || '">');
    htp.p('<input type="hidden" name="p_gl_date_to" value="' || p_gl_date_to || '">');
    FOR  l_index IN 1..p_aff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_aff_condition" value="' || htf.escape_sc(p_aff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_pay_currency_code" value="' || p_pay_currency_code || '">');
    htp.p('<input type="hidden" name="p_due_date_from" value="' || p_due_date_from || '">');
    htp.p('<input type="hidden" name="p_due_date_to" value="' || p_due_date_to || '">');
    htp.p('<input type="hidden" name="p_pay_hold_flag" value="' || p_pay_hold_flag || '">');        /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_no_pay_hold_flag" value="' || p_no_pay_hold_flag || '">');  /* Req#210005 23-Aug-2005 Added by ytsujiha_jp */
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
  --Description: Display list condition for Payables inquiry
  --Note:
  --Parameter(s):
  --  p_mode                : Display mode
  --                          (List/Delete confirm/Fail delete)
  --  p_list_filter_value   : Filter string for list
  --  p_list_filter_opttion : Filter option for list
  --  p_start_listno        : Start list no
  --  p_sort_item           : Sort item
  --  p_sort_method         : Sort method(Asc/Desc)
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
    xgv_common.write_access_log('PIQ.LIST_CONDITIONS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
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
      xgv_common.get_tabs_tag('PIQ'));

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr style="vertical-align: top">');

    -- Display side navigator
    htp.p('<td>');
    show_side_navigator('OPEN');
    htp.p('</td>');

    -- Display list for query condition
    htp.p('<td width="100%">');

    xgv_common.list_conditions(p_mode, 'PI',
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
  --  p_pi_invoice_query_rec: Query condition record
  --  p_save_mode           : Save mode(Update/New)
  --  p_save_category       : Save category(Sob/Responsibility/User)
  --  p_message_type        : Message type(E/C)
  --  p_message_id          : Message id
  --Result: Query id
  --==========================================================
  FUNCTION execute_save_condition(
    p_pi_invoice_query_rec IN  xgv_common.ap_invoice_query_rtype,
    p_save_mode            IN  VARCHAR2,
    p_save_category        IN  VARCHAR2,
    p_message_type         OUT VARCHAR2,
    p_message_id           OUT VARCHAR2)
  RETURN NUMBER
  IS

    l_query_id  xgv_queries.query_id%TYPE := p_pi_invoice_query_rec.query_id;
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
        WHERE  xq.query_name = p_pi_invoice_query_rec.query_name
          AND  xq.inquiry_type = 'PI'
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
              l_query_id, p_pi_invoice_query_rec.query_name, 'PI',
              xgv_common.get_sob_id,
              decode(p_save_category, 'R', xgv_common.get_resp_appl_id, NULL),
              decode(p_save_category, 'R', xgv_common.get_resp_id, NULL),
              decode(p_save_category, 'U', xgv_common.get_user_id, NULL),
              p_pi_invoice_query_rec.result_format, p_pi_invoice_query_rec.file_name,
              p_pi_invoice_query_rec.description,
              sysdate, xgv_common.get_user_id, sysdate, xgv_common.get_user_id);

            -- Subtotal Item
            insert_condition_data(l_query_id, 'BREAKKEY', NULL, NULL, NULL,
              p_pi_invoice_query_rec.break_key);
            -- Display Subtotal Only
            insert_condition_data(l_query_id, 'SUBTOTAL', NULL, NULL, NULL,
              p_pi_invoice_query_rec.show_subtotalonly);
            -- Display Total
            insert_condition_data(l_query_id, 'TOTAL', NULL, NULL, NULL,
              p_pi_invoice_query_rec.show_total);
            -- Display bring forward line
            insert_condition_data(l_query_id, 'BRGFORWARD', NULL, NULL, NULL,
              p_pi_invoice_query_rec.show_bringforward);

            FOR  l_index IN 1..p_pi_invoice_query_rec.segment_type_tab.COUNT
            LOOP

              -- Invoice Date
              IF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVP'
              THEN
                IF  xgv_common.is_date(p_pi_invoice_query_rec.invoice_date_from)
                THEN
                  l_date := to_char(to_date(p_pi_invoice_query_rec.invoice_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_pi_invoice_query_rec.invoice_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_pi_invoice_query_rec.invoice_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_pi_invoice_query_rec.invoice_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_pi_invoice_query_rec.invoice_date_to;
                END IF;
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Paid Status
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'PAIDSTATUS'
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.paid_status);

              -- Posted Status
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.post_status);

              -- Hold All Payments Status
              /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'ALLHLDSTAT'
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.hold_all_status);

              -- Held Status
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'HOLDSTATUS'
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.hold_status);

              -- Document Sequence Number
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'APDOCNUM'
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  to_char(p_pi_invoice_query_rec.doc_seq_from)
                  || ',' || to_char(p_pi_invoice_query_rec.doc_seq_to));

              -- Invoice Amount
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVAMOUNT'
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  to_char(p_pi_invoice_query_rec.inv_amount_from)
                  || ',' || to_char(p_pi_invoice_query_rec.inv_amount_to));

              -- Term Date
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'TERMDATE'
              THEN
                IF  xgv_common.is_date(p_pi_invoice_query_rec.term_date_from)
                THEN
                  l_date := to_char(to_date(p_pi_invoice_query_rec.term_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_pi_invoice_query_rec.term_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_pi_invoice_query_rec.term_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_pi_invoice_query_rec.term_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_pi_invoice_query_rec.term_date_to;
                END IF;
                insert_condition_data(l_query_id, 'TERMDATE',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- DFF of "Invoice"
              -- DFF of "Invoice Distributions"
              ELSIF  xgv_common.is_number(p_pi_invoice_query_rec.segment_type_tab(l_index))
              THEN
                IF  xgv_common.get_flexfield_name(to_number(p_pi_invoice_query_rec.segment_type_tab(l_index))) IN ('AP_INVOICES', 'GL#')
                THEN
                  insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                    p_pi_invoice_query_rec.show_order_tab(l_index),
                    p_pi_invoice_query_rec.sort_order_tab(l_index),
                    NULL,
                    p_pi_invoice_query_rec.condition_tab(l_index));

                ELSIF  xgv_common.get_flexfield_name(to_number(p_pi_invoice_query_rec.segment_type_tab(l_index))) = 'AP_INVOICE_DISTRIBUTIONS'
                THEN
                  insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                    p_pi_invoice_query_rec.show_order_tab(l_index),
                    p_pi_invoice_query_rec.sort_order_tab(l_index),
                    NULL,
                    NULL);
                END IF;

              -- GL Date
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'GLDATE'
              THEN
                IF  xgv_common.is_date(p_pi_invoice_query_rec.gl_date_from)
                THEN
                  l_date := to_char(to_date(p_pi_invoice_query_rec.gl_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_pi_invoice_query_rec.gl_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_pi_invoice_query_rec.gl_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_pi_invoice_query_rec.gl_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_pi_invoice_query_rec.gl_date_to;
                END IF;
                insert_condition_data(l_query_id, 'GLDATE',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Payment Due Date
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DUEDATE'
              THEN
                IF  xgv_common.is_date(p_pi_invoice_query_rec.due_date_from)
                THEN
                  l_date := to_char(to_date(p_pi_invoice_query_rec.due_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_pi_invoice_query_rec.due_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_pi_invoice_query_rec.due_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_pi_invoice_query_rec.due_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_pi_invoice_query_rec.due_date_to;
                END IF;
                insert_condition_data(l_query_id, 'DUEDATE',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Payment Holds Flag
              /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'HOLDFLAG'
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.hold_flag);

              -- Line Number(Line Type)
              -- Vendor Name, Vendor Site Name
              -- Invoice Type, Approval Status
              -- Invoice Number, Currency
              -- Term, Payment Method
              -- Payment Group, Invoice Header Description
              -- Invoice Source, Invoice Batch
              -- Invoice Distribution Type, Invoice Distribution Description
              -- Payment Currency
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) IN ('LINENUM',
                                                                          'VENDOR', 'VENDORSITE',
                                                                          'INVTYPE', 'APPSTATUS',
                                                                          'INVNUM', 'INVCUR',
                                                                          'TERM', 'PAYMETHOD',
                                                                          'PAYGRP', 'HDESC',
                                                                          'SOURCE', 'BATCH',
                                                                          'DTYPE', 'DDESC',
                                                                          'PAYCUR')
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  p_pi_invoice_query_rec.condition_tab(l_index));

              -- Invoice Distribution Line Number, Invoice Distribution Amount
              -- Invoice Distribution Tax Code, Invoice Distribution Prepay Amount Remaining
              -- Paid By
              -- Payment Amount, Payment Amount Remaining,
              -- Paid Date
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) IN ('DLINENUM', 'DAMOUNT',
                                                                          'DTAXCODE', 'DREMAMOUNT',
                                                                          'PAIDBY',
                                                                          'PAYAMOUNT', 'REMAMOUNT',
                                                                          'PAIDDATE')
              THEN
                insert_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  NULL);
              END IF;

            END LOOP;

            p_message_type := 'C';
          EXCEPTION
            WHEN  OTHERS
            THEN
              ROLLBACK;

              l_query_id := p_pi_invoice_query_rec.query_id;
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
        IF  p_pi_invoice_query_rec.created_by != xgv_common.get_user_id
        THEN
          RAISE e_invalid_authority;
        END IF;

        SELECT xq.query_name
        INTO   l_dummy
        FROM   xgv_queries xq
        WHERE  xq.query_id != l_query_id
          AND  xq.query_name = p_pi_invoice_query_rec.query_name
          AND  xq.inquiry_type = 'PI'    /* Bug#212010 07-Dec-2005 Changed by ytsujiha_jp */
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
            SET    query_name = p_pi_invoice_query_rec.query_name,
                   application_id = decode(p_save_category, 'R', xgv_common.get_resp_appl_id, NULL),
                   responsibility_id = decode(p_save_category, 'R', xgv_common.get_resp_id, NULL),
                   user_id = decode(p_save_category, 'U', xgv_common.get_user_id, NULL),
                   result_format = p_pi_invoice_query_rec.result_format,
                   file_name = p_pi_invoice_query_rec.file_name,
                   description = p_pi_invoice_query_rec.description,
                   last_update_date = sysdate,
                   last_updated_by = xgv_common.get_user_id
            WHERE  query_id = l_query_id;

            -- Subtotal Item
            update_condition_data(l_query_id, 'BREAKKEY', NULL, NULL, NULL,
              p_pi_invoice_query_rec.break_key);
            -- Display Subtotal Only
            update_condition_data(l_query_id, 'SUBTOTAL', NULL, NULL, NULL,
              p_pi_invoice_query_rec.show_subtotalonly);
            -- Display Total
            update_condition_data(l_query_id, 'TOTAL', NULL, NULL, NULL,
              p_pi_invoice_query_rec.show_total);
            -- Display bring forward line
            update_condition_data(l_query_id, 'BRGFORWARD', NULL, NULL, NULL,
              p_pi_invoice_query_rec.show_bringforward);

            FOR  l_index IN 1..p_pi_invoice_query_rec.segment_type_tab.COUNT
            LOOP

              -- Invoice Date
              IF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVP'
              THEN
                IF  xgv_common.is_date(p_pi_invoice_query_rec.invoice_date_from)
                THEN
                  l_date := to_char(to_date(p_pi_invoice_query_rec.invoice_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_pi_invoice_query_rec.invoice_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_pi_invoice_query_rec.invoice_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_pi_invoice_query_rec.invoice_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_pi_invoice_query_rec.invoice_date_to;
                END IF;
                update_condition_data(l_query_id, 'INVP',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Paid Status
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'PAIDSTATUS'
              THEN
                update_condition_data(l_query_id, 'PAIDSTATUS',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.paid_status);

              -- Posted Status
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
              THEN
                update_condition_data(l_query_id, 'POSTSTATUS',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.post_status);

              -- Hold All Payments Status
              /* Req#210002 27-Jun-2005 Added by ytsujiha_jp */
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'ALLHLDSTAT'
              THEN
                update_condition_data(l_query_id, 'ALLHLDSTAT',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.hold_all_status);

              -- Held Status
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'HOLDSTATUS'
              THEN
                update_condition_data(l_query_id, 'HOLDSTATUS',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.hold_status);

              -- Document Sequence Number
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'APDOCNUM'
              THEN
                update_condition_data(l_query_id, 'APDOCNUM',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  to_char(p_pi_invoice_query_rec.doc_seq_from)
                  || ',' || to_char(p_pi_invoice_query_rec.doc_seq_to));

              -- Invoice Amount
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'INVAMOUNT'
              THEN
                update_condition_data(l_query_id, 'INVAMOUNT',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  to_char(p_pi_invoice_query_rec.inv_amount_from)
                  || ',' || to_char(p_pi_invoice_query_rec.inv_amount_to));

              -- Term Date
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'TERMDATE'
              THEN
                IF  xgv_common.is_date(p_pi_invoice_query_rec.term_date_from)
                THEN
                  l_date := to_char(to_date(p_pi_invoice_query_rec.term_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_pi_invoice_query_rec.term_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_pi_invoice_query_rec.term_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_pi_invoice_query_rec.term_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_pi_invoice_query_rec.term_date_to;
                END IF;
                update_condition_data(l_query_id, 'TERMDATE',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- DFF of "Invoice"
              -- DFF of "Invoice Distributions"
              ELSIF  xgv_common.is_number(p_pi_invoice_query_rec.segment_type_tab(l_index))
              THEN
                IF  xgv_common.get_flexfield_name(to_number(p_pi_invoice_query_rec.segment_type_tab(l_index))) IN ('AP_INVOICES', 'GL#')
                THEN
                  update_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                    p_pi_invoice_query_rec.show_order_tab(l_index),
                    p_pi_invoice_query_rec.sort_order_tab(l_index),
                    NULL,
                    p_pi_invoice_query_rec.condition_tab(l_index));

                ELSIF  xgv_common.get_flexfield_name(to_number(p_pi_invoice_query_rec.segment_type_tab(l_index))) = 'AP_INVOICE_DISTRIBUTIONS'
                THEN
                  update_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                    p_pi_invoice_query_rec.show_order_tab(l_index),
                    p_pi_invoice_query_rec.sort_order_tab(l_index),
                    NULL,
                    NULL);
                END IF;

              -- GL Date
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'GLDATE'
              THEN
                IF  xgv_common.is_date(p_pi_invoice_query_rec.gl_date_from)
                THEN
                  l_date := to_char(to_date(p_pi_invoice_query_rec.gl_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_pi_invoice_query_rec.gl_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_pi_invoice_query_rec.gl_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_pi_invoice_query_rec.gl_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_pi_invoice_query_rec.gl_date_to;
                END IF;
                update_condition_data(l_query_id, 'GLDATE',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Due Date
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'DUEDATE'
              THEN
                IF  xgv_common.is_date(p_pi_invoice_query_rec.due_date_from)
                THEN
                  l_date := to_char(to_date(p_pi_invoice_query_rec.due_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_pi_invoice_query_rec.due_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_pi_invoice_query_rec.due_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_pi_invoice_query_rec.due_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_pi_invoice_query_rec.due_date_to;
                END IF;
                update_condition_data(l_query_id, 'DUEDATE',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Payment Holds Flag
              /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) = 'HOLDFLAG'
              THEN
                update_condition_data(l_query_id, 'HOLDFLAG',
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_pi_invoice_query_rec.hold_flag);

              -- Line Number(Line Type)
              -- Vendor Name, Vendor Site Name
              -- Invoice Type, Approval Method
              -- Invoice Number, Currency
              -- Term, Payment Method
              -- Payment Group, Invoice Header Description
              -- Invoice Source, Invoice Batch
              -- Invoice Distribution Type, Invoice Distribution Description
              -- Payment Currency
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) IN ('LINENUM',
                                                                          'VENDOR', 'VENDORSITE',
                                                                          'INVTYPE', 'APPSTATUS',
                                                                          'INVNUM', 'INVCUR',
                                                                          'TERM', 'PAYMETHOD',
                                                                          'PAYGRP', 'HDESC',
                                                                          'SOURCE', 'BATCH',
                                                                          'DTYPE', 'DDESC',
                                                                          'PAYCUR')
              THEN
                update_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  p_pi_invoice_query_rec.condition_tab(l_index));

              -- Invoice Distribution Line Number, Invoice Distribution Amount
              -- Invoice Distribution Tax Code, Invoice Distribution Prepay Amount Remaining
              -- Paid By
              -- Payment Amount, Payment Amount Remaining,
              -- Paid Date
              ELSIF  p_pi_invoice_query_rec.segment_type_tab(l_index) IN ('DLINENUM', 'DAMOUNT',
                                                                          'DTAXCODE', 'DREMAMOUNT',
                                                                          'PAIDBY',
                                                                          'PAYAMOUNT', 'REMAMOUNT',
                                                                          'PAIDDATE')
              THEN
                update_condition_data(l_query_id, p_pi_invoice_query_rec.segment_type_tab(l_index),
                  p_pi_invoice_query_rec.show_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_order_tab(l_index),
                  p_pi_invoice_query_rec.sort_method_tab(l_index),
                  NULL);
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
  --Description: Save condition for Payables inquiry
  --Note:
  --Parameter(s):
  --  p_mode              : Display mode
  --                        (New save Dialog/Update save Dialog/New save/Update save)
  --  p_modify_flag       : Modify flag(Yes/No)
  --  p_save_category     : Save category(Sob/Responsibility/User)
  --  p_query_id          : Query id
  --  p_query_name        : Query name
  --  p_show_header_line  : Display header line
  --  p_vendor            : Vendor name
  --  p_vendor_site       : Vendor site name
  --  p_inv_date_from     : Invoice date(From)
  --  p_inv_date_to       : Invoice date(To)
  --  p_invoice_type      : Invoice type
  --  p_paid              : Paid status(paid)
  --  p_notpaid           : Paid status(not paid)
  --  p_partpaid          : Paid status(partially paid)
  --  p_posted            : Posted status(posted)
  --  p_unposted          : Posted status(unposted)
  --  p_partposted        : Posted status(partially posted)
  --  p_selectposted      : Posted status(selectively posted)
  --  p_approvalstatus    : Approval status
  --  p_all_holdstatus    : Hold all payments status(Y)
  --  p_no_all_holdstatus : Hold all payments status(N)
  --  p_heldstatus        : Held status(Y, N, R)
  --  p_inv_num           : Invoice number
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_inv_amount_from   : Invoice amount(From)
  --  p_inv_amount_to     : Invoice amount(To)
  --  p_term_date_from    : Term date(From)
  --  p_term_date_to      : Term date(To)
  --  p_term              : Term
  --  p_payment_method    : Payment method
  --  p_payment_group     : Payment group
  --  p_header_description: Invoice header description
  --  p_source            : Invoice source
  --  p_batch             : Invoice batch
  --  p_h_dff_condition   : Segment condition of invoice header dff
  --  p_dist_type         : Invoice distribution type
  --  p_dist_description  : Invoice distribution description
  --  p_gl_date_from      : General Ledger posted date(From)
  --  p_gl_date_to        : General Ledger posted date(To)
  --  p_aff_condition     : Segment condition of aff
  --  p_pay_currency_code : Payment currency
  --  p_due_date_from     : Payment due date(From)
  --  p_due_date_to       : Payment due date(To)
  --  p_pay_hold_flag     : Payment holds flag(Y)
  --  p_no_pay_hold_flag  : Payment holds flag(N)
  --  p_show_order        : Segment show order
  --  p_sort_order        : Segment sort order
  --  p_sort_method       : Segment sort method
  --  p_segment_type      : Segment type
  --  p_break_key         : Break key
  --  p_show_subtotalonly : Display subtotal only
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
    p_show_header_line   IN VARCHAR2 DEFAULT 'N',
    p_vendor             IN VARCHAR2 DEFAULT NULL,
    p_vendor_site        IN VARCHAR2 DEFAULT NULL,
    p_inv_date_from      IN VARCHAR2 DEFAULT NULL,
    p_inv_date_to        IN VARCHAR2 DEFAULT NULL,
    p_invoice_type       IN VARCHAR2 DEFAULT NULL,
    p_paid               IN VARCHAR2 DEFAULT 'N',
    p_notpaid            IN VARCHAR2 DEFAULT 'N',
    p_partpaid           IN VARCHAR2 DEFAULT 'N',
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_partposted         IN VARCHAR2 DEFAULT 'N',
    p_selectposted       IN VARCHAR2 DEFAULT 'N',
    p_approvalstatus     IN VARCHAR2 DEFAULT NULL,
    p_all_holdstatus     IN VARCHAR2 DEFAULT 'N',     /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
    p_no_all_holdstatus  IN VARCHAR2 DEFAULT 'N',     /* Req#210004 23-Aug-2005 Added by ytsujiha_jp */
    p_heldstatus         IN VARCHAR2 DEFAULT 'N',
    p_inv_num            IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_inv_amount_from    IN NUMBER   DEFAULT NULL,
    p_inv_amount_to      IN NUMBER   DEFAULT NULL,
    p_term_date_from     IN VARCHAR2 DEFAULT NULL,
    p_term_date_to       IN VARCHAR2 DEFAULT NULL,
    p_term               IN VARCHAR2 DEFAULT NULL,
    p_payment_method     IN VARCHAR2 DEFAULT NULL,
    p_payment_group      IN VARCHAR2 DEFAULT NULL,
    p_header_description IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_h_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_dist_type          IN VARCHAR2 DEFAULT NULL,
    p_dist_description   IN VARCHAR2 DEFAULT NULL,
    p_gl_date_from       IN VARCHAR2 DEFAULT NULL,
    p_gl_date_to         IN VARCHAR2 DEFAULT NULL,
    p_aff_condition      IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_pay_currency_code  IN VARCHAR2 DEFAULT NULL,
    p_due_date_from      IN VARCHAR2 DEFAULT NULL,
    p_due_date_to        IN VARCHAR2 DEFAULT NULL,
    p_pay_hold_flag      IN VARCHAR2 DEFAULT 'N',     /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
    p_no_pay_hold_flag   IN VARCHAR2 DEFAULT 'N',     /* Req#210005 23-Aug-2005 Added by ytsujiha_jp */
    p_show_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_order         IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_sort_method        IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_segment_type       IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
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
    l_pi_invoice_query_rec  xgv_common.ap_invoice_query_rtype;
    l_message_type  VARCHAR2(1) := NULL;
    l_message_id  VARCHAR2(255) := NULL;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('PIQ.SAVE_CONDITION');

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
          l_pi_invoice_query_rec, NULL,
          p_show_header_line,
          p_vendor, p_vendor_site, p_inv_date_from, p_inv_date_to,
          p_invoice_type, p_paid, p_notpaid, p_partpaid,
          p_posted, p_unposted, p_partposted, p_selectposted,
          p_approvalstatus, p_all_holdstatus, p_no_all_holdstatus, p_heldstatus,  /* Req#210004 23-Aug-2005 Changed by ytsujiha_jp */
          p_inv_num, p_doc_seq_from, p_doc_seq_to, p_currency_code,
          p_inv_amount_from, p_inv_amount_to,
          p_term_date_from, p_term_date_to,
          p_term, p_payment_method, p_payment_group, p_header_description,
          p_source, p_batch, p_h_dff_condition,
          p_dist_type, p_dist_description,
          p_gl_date_from, p_gl_date_to, p_aff_condition,
          p_pay_currency_code, p_due_date_from, p_due_date_to,
          p_pay_hold_flag, p_no_pay_hold_flag,                                    /* Req#210005 23-Aug-2005 Changed by ytsujiha_jp */
          p_show_order, p_sort_order, p_sort_method, p_segment_type,
          p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
          p_result_format, p_file_name, p_description);
        l_pi_invoice_query_rec.query_id := p_query_id;

      ELSE
        set_query_condition_local(
          l_pi_invoice_query_rec, p_query_id,
          p_show_header_line,
          p_vendor, p_vendor_site, p_inv_date_from, p_inv_date_to,
          p_invoice_type, p_paid, p_notpaid, p_partpaid,
          p_posted, p_unposted, p_partposted, p_selectposted,
          p_approvalstatus, p_all_holdstatus, p_no_all_holdstatus, p_heldstatus,  /* Req#210004 23-Aug-2005 Changed by ytsujiha_jp */
          p_inv_num, p_doc_seq_from, p_doc_seq_to, p_currency_code,
          p_inv_amount_from, p_inv_amount_to,
          p_term_date_from, p_term_date_to,
          p_term, p_payment_method, p_payment_group, p_header_description,
          p_source, p_batch, p_h_dff_condition,
          p_dist_type, p_dist_description,
          p_gl_date_from, p_gl_date_to, p_aff_condition,
          p_pay_currency_code, p_due_date_from, p_due_date_to,
          p_pay_hold_flag, p_no_pay_hold_flag,                                    /* Req#210005 23-Aug-2005 Changed by ytsujiha_jp */
          p_show_order, p_sort_order, p_sort_method, p_segment_type,
          p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
          p_result_format, p_file_name, p_description);
      END IF;

      l_pi_invoice_query_rec.query_name := p_query_name;
      l_query_id := execute_save_condition(
        l_pi_invoice_query_rec, p_mode, p_save_category, l_message_type, l_message_id);

      IF  l_message_type = 'C'
      THEN
        htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
        htp.p('<html dir="ltr">');
        htp.p('<body>');
        htp.p('<form name="f_refresh" method="post" action="./xgv_piq.top">');
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
          AND  xq.inquiry_type = 'PI';
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
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_PIQ.js"></script>');
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
      xgv_common.get_tabs_tag('PIQ'));

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

    htp.p('<form name="f_savedialog" method="post" action="./xgv_piq.save_condition">');
    htp.p('<input type="hidden" name="p_mode" value="N">');
    htp.p('<input type="hidden" name="p_show_header_line" value="' || p_show_header_line || '">');
    htp.p('<input type="hidden" name="p_vendor" value="' || htf.escape_sc(p_vendor) || '">');
    htp.p('<input type="hidden" name="p_vendor_site" value="' || htf.escape_sc(p_vendor_site) || '">');
    htp.p('<input type="hidden" name="p_inv_date_from" value="' || p_inv_date_from || '">');
    htp.p('<input type="hidden" name="p_inv_date_to" value="' || p_inv_date_to || '">');
    htp.p('<input type="hidden" name="p_invoice_type" value="' || htf.escape_sc(p_invoice_type) || '">');
    htp.p('<input type="hidden" name="p_paid" value="' || p_paid || '">');
    htp.p('<input type="hidden" name="p_notpaid" value="' || p_notpaid || '">');
    htp.p('<input type="hidden" name="p_partpaid" value="' || p_partpaid || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_partposted" value="' || p_partposted || '">');
    htp.p('<input type="hidden" name="p_selectposted" value="' || p_selectposted || '">');
    htp.p('<input type="hidden" name="p_approvalstatus" value="' || htf.escape_sc(p_approvalstatus) || '">');
    htp.p('<input type="hidden" name="p_all_holdstatus" value="' || p_all_holdstatus || '">');        /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_no_all_holdstatus" value="' || p_no_all_holdstatus || '">');  /* Req#210004 23-Aug-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_heldstatus" value="' || p_heldstatus || '">');
    htp.p('<input type="hidden" name="p_inv_num" value="' || htf.escape_sc(p_inv_num) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || p_doc_seq_from || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || p_doc_seq_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_inv_amount_from" value="' || p_inv_amount_from || '">');
    htp.p('<input type="hidden" name="p_inv_amount_to" value="' || p_inv_amount_to || '">');
    htp.p('<input type="hidden" name="p_term_date_from" value="' || p_term_date_from || '">');
    htp.p('<input type="hidden" name="p_term_date_to" value="' || p_term_date_to || '">');
    htp.p('<input type="hidden" name="p_term" value="' || htf.escape_sc(p_term) || '">');
    htp.p('<input type="hidden" name="p_payment_method" value="' || htf.escape_sc(p_payment_method) || '">');
    htp.p('<input type="hidden" name="p_payment_group" value="' || htf.escape_sc(p_payment_group) || '">');
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    FOR  l_index IN 1..p_h_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_h_dff_condition" value="' || htf.escape_sc(p_h_dff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_dist_type" value="' || htf.escape_sc(p_dist_type) || '">');
    htp.p('<input type="hidden" name="p_dist_description" value="' || htf.escape_sc(p_dist_description) || '">');
    htp.p('<input type="hidden" name="p_gl_date_from" value="' || p_gl_date_from || '">');
    htp.p('<input type="hidden" name="p_gl_date_to" value="' || p_gl_date_to || '">');
    FOR  l_index IN 1..p_aff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_aff_condition" value="' || htf.escape_sc(p_aff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_pay_currency_code" value="' || p_pay_currency_code || '">');
    htp.p('<input type="hidden" name="p_due_date_from" value="' || p_due_date_from || '">');
    htp.p('<input type="hidden" name="p_due_date_to" value="' || p_due_date_to || '">');
    htp.p('<input type="hidden" name="p_pay_hold_flag" value="' || p_pay_hold_flag || '">');        /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_no_pay_hold_flag" value="' || p_no_pay_hold_flag || '">');  /* Req#210005 23-Aug-2005 Added by ytsujiha_jp */
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

    htp.p('<form name="f_cancelsave" method="post" action="./xgv_piq.top">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || l_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_show_header_line" value="' || p_show_header_line || '">');
    htp.p('<input type="hidden" name="p_vendor" value="' || htf.escape_sc(p_vendor) || '">');
    htp.p('<input type="hidden" name="p_vendor_site" value="' || htf.escape_sc(p_vendor_site) || '">');
    htp.p('<input type="hidden" name="p_inv_date_from" value="' || p_inv_date_from || '">');
    htp.p('<input type="hidden" name="p_inv_date_to" value="' || p_inv_date_to || '">');
    htp.p('<input type="hidden" name="p_invoice_type" value="' || htf.escape_sc(p_invoice_type) || '">');
    htp.p('<input type="hidden" name="p_paid" value="' || p_paid || '">');
    htp.p('<input type="hidden" name="p_notpaid" value="' || p_notpaid || '">');
    htp.p('<input type="hidden" name="p_partpaid" value="' || p_partpaid || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_partposted" value="' || p_partposted || '">');
    htp.p('<input type="hidden" name="p_selectposted" value="' || p_selectposted || '">');
    htp.p('<input type="hidden" name="p_approvalstatus" value="' || htf.escape_sc(p_approvalstatus) || '">');
    htp.p('<input type="hidden" name="p_all_holdstatus" value="' || p_all_holdstatus || '">');        /* Req#210002 24-Jun-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_no_all_holdstatus" value="' || p_no_all_holdstatus || '">');  /* Req#210004 23-Aug-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_heldstatus" value="' || p_heldstatus || '">');
    htp.p('<input type="hidden" name="p_inv_num" value="' || htf.escape_sc(p_inv_num) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || p_doc_seq_from || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || p_doc_seq_to || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_inv_amount_from" value="' || p_inv_amount_from || '">');
    htp.p('<input type="hidden" name="p_inv_amount_to" value="' || p_inv_amount_to || '">');
    htp.p('<input type="hidden" name="p_term_date_from" value="' || p_term_date_from || '">');
    htp.p('<input type="hidden" name="p_term_date_to" value="' || p_term_date_to || '">');
    htp.p('<input type="hidden" name="p_term" value="' || htf.escape_sc(p_term) || '">');
    htp.p('<input type="hidden" name="p_payment_method" value="' || htf.escape_sc(p_payment_method) || '">');
    htp.p('<input type="hidden" name="p_payment_group" value="' || htf.escape_sc(p_payment_group) || '">');
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    FOR  l_index IN 1..p_h_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_h_dff_condition" value="' || htf.escape_sc(p_h_dff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_dist_type" value="' || htf.escape_sc(p_dist_type) || '">');
    htp.p('<input type="hidden" name="p_dist_description" value="' || htf.escape_sc(p_dist_description) || '">');
    htp.p('<input type="hidden" name="p_gl_date_from" value="' || p_gl_date_from || '">');
    htp.p('<input type="hidden" name="p_gl_date_to" value="' || p_gl_date_to || '">');
    FOR  l_index IN 1..p_aff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_aff_condition" value="' || htf.escape_sc(p_aff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_pay_currency_code" value="' || p_pay_currency_code || '">');
    htp.p('<input type="hidden" name="p_due_date_from" value="' || p_due_date_from || '">');
    htp.p('<input type="hidden" name="p_due_date_to" value="' || p_due_date_to || '">');
    htp.p('<input type="hidden" name="p_pay_hold_flag" value="' || p_pay_hold_flag || '">');        /* Req#210003 24-Jun-2005 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_no_pay_hold_flag" value="' || p_no_pay_hold_flag || '">');  /* Req#210005 23-Aug-2005 Added by ytsujiha_jp */
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
  --Description: Delete condition for Payables inquiry
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
    xgv_common.write_access_log('PIQ.DELETE_CONDITION');

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
    htp.p('<form name="f_refresh" method="post" action="./xgv_piq.list_conditions">');
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

END xgv_piq;
/
