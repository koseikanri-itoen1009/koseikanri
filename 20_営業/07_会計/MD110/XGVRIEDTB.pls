CREATE OR REPLACE PACKAGE BODY xgv_riq
--
--  XGVRIEDTB.pls
--
--  Copyright (c) Oracle Corporation 2001-2007. All Rights Reserved
--
--  NAME
--    xgv_riq
--  FUNCTION
--    Edit condition for Receivables invoice inquiry(Body)
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
  --Description: Get record for receivables invoice query
  --Note:
  --Parameter(s):
  --  p_ri_invoice_query_rec: Record for receivables invoice query
  --  p_query_id            : Query id
  --==========================================================
  PROCEDURE set_query_condition(
    p_ri_invoice_query_rec OUT xgv_common.ar_invoice_query_rtype,
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
                      WHERE  xuiv.inquiry_type = 'RI'
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
      WHERE  xuiv.inquiry_type = 'RI'
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
    CURSOR l_riq_segs_cur
    IS
      SELECT 1 order1,
             xuiv.item_order oder2,
             xuiv.item_code segment_type
      FROM   xgv_usable_items_vl xuiv
      WHERE  xuiv.inquiry_type = 'RI'
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
        AND  xfsv.application_id = xgv_common.get_ar_appl_id
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
    INTO   p_ri_invoice_query_rec.query_id,
           p_ri_invoice_query_rec.query_name,
           p_ri_invoice_query_rec.result_format,
           p_ri_invoice_query_rec.file_name,
           p_ri_invoice_query_rec.description,
           p_ri_invoice_query_rec.result_rows,
           p_ri_invoice_query_rec.creation_date,
           p_ri_invoice_query_rec.created_by,
           p_ri_invoice_query_rec.last_update_date,
           p_ri_invoice_query_rec.last_updated_by
    FROM   xgv_queries xq
    WHERE  xq.query_id = p_query_id
      AND  xq.inquiry_type = 'RI';

    FOR  l_other_conditions_rec IN l_other_conditions_cur(p_query_id)
    LOOP

      -- Subtotal Item
      IF  l_other_conditions_rec.segment_type = 'BREAKKEY'
      THEN
        p_ri_invoice_query_rec.break_key := l_other_conditions_rec.condition;

      -- Display Subtotal Only
      ELSIF  l_other_conditions_rec.segment_type = 'SUBTOTAL'
      THEN
        p_ri_invoice_query_rec.show_subtotalonly := l_other_conditions_rec.condition;

      -- Display Total
      ELSIF  l_other_conditions_rec.segment_type = 'TOTAL'
      THEN
        p_ri_invoice_query_rec.show_total := l_other_conditions_rec.condition;

      -- Display bring forward line
      ELSIF  l_other_conditions_rec.segment_type = 'BRGFORWARD'
      THEN
        p_ri_invoice_query_rec.show_bringforward := l_other_conditions_rec.condition;

      END IF;

    END LOOP;

    FOR  l_seg_conditions_rec IN l_seg_conditions_cur(p_query_id)
    LOOP

      p_ri_invoice_query_rec.segment_type_tab(l_seg_conditions_cur%ROWCOUNT) := l_seg_conditions_rec.segment_type;
      p_ri_invoice_query_rec.show_order_tab(l_seg_conditions_cur%ROWCOUNT)   := l_seg_conditions_rec.show_order;
      p_ri_invoice_query_rec.sort_order_tab(l_seg_conditions_cur%ROWCOUNT)   := l_seg_conditions_rec.sort_order;
      p_ri_invoice_query_rec.sort_method_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.sort_method;

      -- Data Refer(Hidden items)
      IF  l_seg_conditions_rec.segment_type = 'EXDD'
      THEN
        p_ri_invoice_query_rec.show_order_tab(l_seg_conditions_cur%ROWCOUNT) := 1;

      -- Transaction Date
      ELSIF  l_seg_conditions_rec.segment_type = 'TRXP'
      THEN
        p_ri_invoice_query_rec.trx_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_ri_invoice_query_rec.trx_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_ri_invoice_query_rec.trx_date_from, 'RRRRMMDD')
        THEN
          p_ri_invoice_query_rec.trx_date_from :=
            to_char(to_date(p_ri_invoice_query_rec.trx_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_ri_invoice_query_rec.trx_date_to, 'RRRRMMDD')
        THEN
          p_ri_invoice_query_rec.trx_date_to :=
            to_char(to_date(p_ri_invoice_query_rec.trx_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- Status
      ELSIF  l_seg_conditions_rec.segment_type = 'APPSTATUS'
      THEN
        p_ri_invoice_query_rec.app_status := l_seg_conditions_rec.condition;

      -- Posted status
      ELSIF  l_seg_conditions_rec.segment_type = 'POSTSTATUS'
      THEN
        p_ri_invoice_query_rec.post_status := l_seg_conditions_rec.condition;

      -- Complete status
      ELSIF  l_seg_conditions_rec.segment_type = 'COMPSTATUS'
      THEN
        p_ri_invoice_query_rec.comp_status := l_seg_conditions_rec.condition;

      -- Print count
      ELSIF  l_seg_conditions_rec.segment_type = 'PRINTCOUNT'
      THEN
        p_ri_invoice_query_rec.print_count := l_seg_conditions_rec.condition;

      -- Document Sequenctial Number
      ELSIF  l_seg_conditions_rec.segment_type = 'ARDOCNUM'
      THEN
        p_ri_invoice_query_rec.doc_seq_from := to_number(xgv_common.split(l_seg_conditions_rec.condition, ','));
        p_ri_invoice_query_rec.doc_seq_to   := to_number(xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2));

      -- Invoice Amount
      ELSIF  l_seg_conditions_rec.segment_type = 'INVAMOUNT'
      THEN
        p_ri_invoice_query_rec.inv_amount_from := to_number(xgv_common.split(l_seg_conditions_rec.condition, ','));
        p_ri_invoice_query_rec.inv_amount_to   := to_number(xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2));

      -- Term Due Date
      ELSIF  l_seg_conditions_rec.segment_type = 'DUEDATE'
      THEN
        p_ri_invoice_query_rec.due_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_ri_invoice_query_rec.due_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_ri_invoice_query_rec.due_date_from, 'RRRRMMDD')
        THEN
          p_ri_invoice_query_rec.due_date_from :=
            to_char(to_date(p_ri_invoice_query_rec.due_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_ri_invoice_query_rec.due_date_to, 'RRRRMMDD')
        THEN
          p_ri_invoice_query_rec.due_date_to :=
            to_char(to_date(p_ri_invoice_query_rec.due_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- General Ledger date
      ELSIF  l_seg_conditions_rec.segment_type = 'GLDATE'
      THEN
        p_ri_invoice_query_rec.gl_date_from := xgv_common.split(l_seg_conditions_rec.condition, ',');
        p_ri_invoice_query_rec.gl_date_to   := xgv_common.split(l_seg_conditions_rec.condition, ',', 1, 2);
        IF  xgv_common.is_date(p_ri_invoice_query_rec.gl_date_from, 'RRRRMMDD')
        THEN
          p_ri_invoice_query_rec.gl_date_from :=
            to_char(to_date(p_ri_invoice_query_rec.gl_date_from, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;
        IF  xgv_common.is_date(p_ri_invoice_query_rec.gl_date_to, 'RRRRMMDD')
        THEN
          p_ri_invoice_query_rec.gl_date_to :=
            to_char(to_date(p_ri_invoice_query_rec.gl_date_to, 'RRRRMMDD'), xgv_common.get_date_mask);
        END IF;

      -- Line Number(Line Type)
      -- Customer name, Customer site name, Transaction class, Transaction type
      -- Batch invoice number, Invoice number, Currency, Term, Payment method
      -- Transaction header description, Transaction source, Transaction batch
      -- Invoice line type, Invoice line item name, Invoice line description
      -- Transaction distribution class
      ELSIF  l_seg_conditions_rec.segment_type IN ('LINENUM',
                                                   'CUST', 'CUSTSITE', 'TRXCLASS', 'TRXTYPE',
                                                   'BINVNUM', 'INVNUM', 'INVCUR', 'TERM', 'PAYMETHOD',
                                                   'HDESC', 'SOURCE', 'BATCH',
                                                   'LTYPE', 'LITEM', 'LDESC',
                                                   'DCLASS')
      THEN
        p_ri_invoice_query_rec.condition_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.condition;

      -- AFF/DFF Segments
      ELSIF  xgv_common.is_number(l_seg_conditions_rec.segment_type)
      THEN
        p_ri_invoice_query_rec.condition_tab(l_seg_conditions_cur%ROWCOUNT)  := l_seg_conditions_rec.condition;
      END IF;

    END LOOP;

  --------------------------------------------------
  -- Exception
  --------------------------------------------------
  EXCEPTION

    WHEN  NO_DATA_FOUND
    THEN
      -- Set default value
      p_ri_invoice_query_rec.query_id          := NULL;
      p_ri_invoice_query_rec.query_name        := NULL;
      p_ri_invoice_query_rec.break_key         := NULL;
      p_ri_invoice_query_rec.show_subtotalonly := 'N';
      p_ri_invoice_query_rec.show_total        := 'N';
      p_ri_invoice_query_rec.show_bringforward := 'N';
      p_ri_invoice_query_rec.result_format     := nvl(xgv_common.get_profile_option_value('XGV_DEFAULT_RESULT_FORMAT'), 'HTML');
      p_ri_invoice_query_rec.file_name         := NULL;
      p_ri_invoice_query_rec.description       := NULL;
      p_ri_invoice_query_rec.result_rows       := NULL;
      p_ri_invoice_query_rec.creation_date     := NULL;
      p_ri_invoice_query_rec.created_by        := NULL;
      p_ri_invoice_query_rec.last_update_date  := NULL;
      p_ri_invoice_query_rec.last_updated_by   := NULL;

      FOR  l_riq_segs_rec IN l_riq_segs_cur
      LOOP

        -- Set default value
        p_ri_invoice_query_rec.segment_type_tab(l_riq_segs_cur%ROWCOUNT) := l_riq_segs_rec.segment_type;
        p_ri_invoice_query_rec.show_order_tab(l_riq_segs_cur%ROWCOUNT)   := NULL;
        p_ri_invoice_query_rec.sort_order_tab(l_riq_segs_cur%ROWCOUNT)   := NULL;
        p_ri_invoice_query_rec.sort_method_tab(l_riq_segs_cur%ROWCOUNT)  := NULL;

        -- Data Refer(Hidden items)
        IF  l_riq_segs_rec.segment_type = 'EXDD'
        THEN
          p_ri_invoice_query_rec.show_order_tab(l_riq_segs_cur%ROWCOUNT) := 1;

        -- Line Number(Line Type)
        ELSIF  l_riq_segs_rec.segment_type = 'LINENUM'
        THEN
          p_ri_invoice_query_rec.show_order_tab(l_riq_segs_cur%ROWCOUNT) := 3;
          p_ri_invoice_query_rec.sort_order_tab(l_riq_segs_cur%ROWCOUNT) := 3;
          p_ri_invoice_query_rec.condition_tab(l_riq_segs_cur%ROWCOUNT)  := 'HLADP';

        -- Transaction Date
        ELSIF  l_riq_segs_rec.segment_type = 'TRXP'
        THEN
          p_ri_invoice_query_rec.trx_date_from := NULL;
          p_ri_invoice_query_rec.trx_date_to   := NULL;
          p_ri_invoice_query_rec.show_order_tab(l_riq_segs_cur%ROWCOUNT) := 1;
          p_ri_invoice_query_rec.sort_order_tab(l_riq_segs_cur%ROWCOUNT) := 1;

        -- Status
        ELSIF  l_riq_segs_rec.segment_type = 'APPSTATUS'
        THEN
          p_ri_invoice_query_rec.app_status := 'YNP';

        -- Posted status
        ELSIF  l_riq_segs_rec.segment_type = 'POSTSTATUS'
        THEN
          p_ri_invoice_query_rec.post_status := 'YNP';

        -- Complete status
        ELSIF  l_riq_segs_rec.segment_type = 'COMPSTATUS'
        THEN
          p_ri_invoice_query_rec.comp_status := 'YN';

        -- Print count
        ELSIF  l_riq_segs_rec.segment_type = 'PRINTCOUNT'
        THEN
          p_ri_invoice_query_rec.print_count := '01';

        -- Invoice Number
        ELSIF  l_riq_segs_rec.segment_type = 'INVNUM'
        THEN
          p_ri_invoice_query_rec.show_order_tab(l_riq_segs_cur%ROWCOUNT) := 2;
          p_ri_invoice_query_rec.sort_order_tab(l_riq_segs_cur%ROWCOUNT) := 2;
          p_ri_invoice_query_rec.condition_tab(l_riq_segs_cur%ROWCOUNT)  := NULL;

        -- Document Sequenctial Number
        ELSIF  l_riq_segs_rec.segment_type = 'ARDOCNUM'
        THEN
          p_ri_invoice_query_rec.doc_seq_from := NULL;
          p_ri_invoice_query_rec.doc_seq_to   := NULL;

        -- Invoice Amount
        ELSIF  l_riq_segs_rec.segment_type = 'INVAMOUNT'
        THEN
          p_ri_invoice_query_rec.inv_amount_from := NULL;
          p_ri_invoice_query_rec.inv_amount_to   := NULL;

        -- Term Due Date
        ELSIF  l_riq_segs_rec.segment_type = 'DUEDATE'
        THEN
          p_ri_invoice_query_rec.due_date_from := NULL;
          p_ri_invoice_query_rec.due_date_to   := NULL;

        -- General Ledger date
        ELSIF  l_riq_segs_rec.segment_type = 'GLDATE'
        THEN
          p_ri_invoice_query_rec.gl_date_from := NULL;
          p_ri_invoice_query_rec.gl_date_to   := NULL;

        -- Customer name, Customer site name, Transaction class, Transaction type
        -- Batch invoice number, Currency, Term, Payment method
        -- Transaction header description, Transaction source, Transaction batch
        -- Invoice line type, Invoice line item name, Invoice line description,
        -- Transaction distribution class
        ELSIF  l_riq_segs_rec.segment_type IN ('CUST', 'CUSTSITE', 'TRXCLASS', 'TRXTYPE',
                                               'BINVNUM', 'INVCUR', 'TERM', 'PAYMETHOD',
                                               'HDESC', 'SOURCE', 'BATCH',
                                               'LTYPE', 'LITEM', 'LDESC',
                                               'DCLASS')
        THEN
          p_ri_invoice_query_rec.condition_tab(l_riq_segs_cur%ROWCOUNT)  := NULL;

        -- AFF/DFF Segments
        ELSIF  xgv_common.is_number(l_riq_segs_rec.segment_type)
        THEN
          p_ri_invoice_query_rec.condition_tab(l_riq_segs_cur%ROWCOUNT)  := NULL;
        END IF;

      END LOOP;

  END set_query_condition;

  --==========================================================
  --Procedure Name: set_query_condition_local
  --Description: Set record for Payables inquiry
  --Note:
  --Parameter(s):
  --  p_ri_invoice_query_rec: Record for receivable invoice query
  --  p_query_id            : Query id
  --  p_show_header_line    : Display header line
  --  p_cust                : Customer name
  --  p_cust_site           : Customer site name
  --  p_trx_date_from       : Transaction date(From)
  --  p_trx_date_to         : Transaction date(To)
  --  p_trx_class           : Transaction class
  --  p_trx_type            : Transaction type
  --  p_receipt             : Status(receipt)
  --  p_partreceipt         : Status(no receipt, or part receipt)
  --  p_posted              : Posted status(posted)
  --  p_unposted            : Posted status(unposted)
  --  p_partposted          : Posted status(partially posted)
  --  p_complete            : Complete status(complete)
  --  p_uncomplete          : Complete status(uncomplete)
  --  p_printcount_zero     : Print count(zero)
  --  p_printcount_one      : Print count(one more than)
  --  p_batch_inv_num       : Batch invoice number
  --  p_inv_num             : Invoice number
  --  p_doc_seq_from        : Document sequence number(From)
  --  p_doc_seq_to          : Document sequence number(To)
  --  p_currency_code       : Currency
  --  p_inv_amount_from     : Invoice amount(From)
  --  p_inv_amount_to       : Invoice amount(To)
  --  p_due_date_from       : Term due date(From)
  --  p_due_date_to         : Term due date(To)
  --  p_term                : Term
  --  p_payment_method      : Payment method
  --  p_header_description  : Transaction header description
  --  p_source              : Transaction source
  --  p_batch               : Transaction batch
  --  p_h_dff_condition     : Segment condition of transaction header dff
  --  p_line_type           : Invoice line type
  --  p_line_item           : Invoice line item name
  --  p_line_description    : Invoice line description
  --  p_dist_class          : Transaction distribution class
  --  p_gl_date_from        : General Ledger date(From)
  --  p_gl_date_to          : General Ledger date(To)
  --  p_aff_condition       : Segment condition of transaction distribution aff
  --  p_d_dff_condition     : Segment condition of transaction distribution dff
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
    p_ri_invoice_query_rec OUT xgv_common.ar_invoice_query_rtype,
    p_query_id             IN  NUMBER,
    p_show_header_line     IN  VARCHAR2,
    p_cust                 IN  VARCHAR2,
    p_cust_site            IN  VARCHAR2,
    p_trx_date_from        IN  VARCHAR2,
    p_trx_date_to          IN  VARCHAR2,
    p_trx_class            IN  VARCHAR2,
    p_trx_type             IN  VARCHAR2,
    p_receipt              IN  VARCHAR2,
    p_partreceipt          IN  VARCHAR2,
    p_posted               IN  VARCHAR2,
    p_unposted             IN  VARCHAR2,
    p_partposted           IN  VARCHAR2,
    p_complete             IN  VARCHAR2,
    p_uncomplete           IN  VARCHAR2,
    p_printcount_zero      IN  VARCHAR2,
    p_printcount_one       IN  VARCHAR2,
    p_batch_inv_num        IN  VARCHAR2,
    p_inv_num              IN  VARCHAR2,
    p_doc_seq_from         IN  NUMBER,
    p_doc_seq_to           IN  NUMBER,
    p_currency_code        IN  VARCHAR2,
    p_inv_amount_from      IN  NUMBER,
    p_inv_amount_to        IN  NUMBER,
    p_due_date_from        IN  VARCHAR2,
    p_due_date_to          IN  VARCHAR2,
    p_term                 IN  VARCHAR2,
    p_payment_method       IN  VARCHAR2,
    p_header_description   IN  VARCHAR2,
    p_source               IN  VARCHAR2,
    p_batch                IN  VARCHAR2,
    p_h_dff_condition      IN  xgv_common.array_ttype,
    p_line_type            IN  VARCHAR2,
    p_line_item            IN  VARCHAR2,
    p_line_description     IN  VARCHAR2,
    p_dist_class           IN  VARCHAR2,
    p_gl_date_from         IN  VARCHAR2,
    p_gl_date_to           IN  VARCHAR2,
    p_aff_condition        IN  xgv_common.array_ttype,
    p_d_dff_condition      IN  xgv_common.array_ttype,
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
    l_index_d_dff_condition  NUMBER := 0;

  BEGIN

    IF  p_query_id IS NULL
    THEN
      p_ri_invoice_query_rec.query_id := NULL;
      p_ri_invoice_query_rec.query_name := NULL;
      p_ri_invoice_query_rec.creation_date := NULL;
      p_ri_invoice_query_rec.created_by := NULL;
      p_ri_invoice_query_rec.last_update_date := NULL;
      p_ri_invoice_query_rec.last_updated_by := NULL;

    -- Set WHO columns
    ELSE
      SELECT xq.query_id,
             xq.query_name,
             xq.creation_date,
             xq.created_by,
             xq.last_update_date,
             xq.last_updated_by
      INTO   p_ri_invoice_query_rec.query_id,
             p_ri_invoice_query_rec.query_name,
             p_ri_invoice_query_rec.creation_date,
             p_ri_invoice_query_rec.created_by,
             p_ri_invoice_query_rec.last_update_date,
             p_ri_invoice_query_rec.last_updated_by
      FROM   xgv_queries xq
      WHERE  xq.query_id = p_query_id;
    END IF;

    -- Set conditions
    p_ri_invoice_query_rec.break_key         := p_break_key;
    p_ri_invoice_query_rec.show_subtotalonly := p_show_subtotalonly;
    p_ri_invoice_query_rec.show_total        := p_show_total;
    p_ri_invoice_query_rec.show_bringforward := p_show_bringforward;
    p_ri_invoice_query_rec.result_format     := p_result_format;
    p_ri_invoice_query_rec.file_name         := p_file_name;
    p_ri_invoice_query_rec.description       := p_description;
    p_ri_invoice_query_rec.result_rows       := xgv_common.get_result_rows;

    FOR  l_index IN 1..p_segment_type.COUNT
    LOOP

      -- Display Order, Sort Order, Sort Method, Segment Type
      p_ri_invoice_query_rec.show_order_tab(l_index)   := to_number(p_show_order(l_index));
      p_ri_invoice_query_rec.sort_order_tab(l_index)   := to_number(p_sort_order(l_index));
      p_ri_invoice_query_rec.sort_method_tab(l_index)  := p_sort_method(l_index);
      p_ri_invoice_query_rec.segment_type_tab(l_index) := p_segment_type(l_index);

      -- Line Number(Line Type)
      IF  p_segment_type(l_index) = 'LINENUM'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index)  :=
          xgv_common.r_decode(p_show_header_line, 'Y', 'H', NULL)
          || 'LADP';

      -- Customer name
      ELSIF  p_segment_type(l_index) = 'CUST'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_cust;

      -- Customer site name
      ELSIF  p_segment_type(l_index) = 'CUSTSITE'
      THEN
         p_ri_invoice_query_rec.condition_tab(l_index) := p_cust_site;

      -- Transaction date
      ELSIF  p_segment_type(l_index) = 'TRXP'
      THEN
        p_ri_invoice_query_rec.trx_date_from := p_trx_date_from;
        p_ri_invoice_query_rec.trx_date_to   := p_trx_date_to;

      -- Transaction class
      ELSIF  p_segment_type(l_index) = 'TRXCLASS'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_trx_class;

      -- Transaction type
      ELSIF  p_segment_type(l_index) = 'TRXTYPE'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_trx_type;

      -- Status
      ELSIF  p_segment_type(l_index) = 'APPSTATUS'
      THEN
        p_ri_invoice_query_rec.app_status :=
          xgv_common.r_decode(p_receipt, 'Y', 'Y', NULL)
          || xgv_common.r_decode(p_partreceipt, 'Y', 'NP', NULL);

      -- Posted status
      ELSIF  p_segment_type(l_index) = 'POSTSTATUS'
      THEN
        p_ri_invoice_query_rec.post_status :=
          xgv_common.r_decode(p_posted, 'Y', 'Y', NULL)
          || xgv_common.r_decode(p_unposted, 'Y', 'N', NULL)
          || xgv_common.r_decode(p_partposted, 'Y', 'P', NULL);

      -- Complete status
      ELSIF  p_segment_type(l_index) = 'COMPSTATUS'
      THEN
        p_ri_invoice_query_rec.comp_status :=
          xgv_common.r_decode(p_complete, 'Y', 'Y', NULL)
          || xgv_common.r_decode(p_uncomplete, 'Y', 'N', NULL);

      -- Print count
      ELSIF  p_segment_type(l_index) = 'PRINTCOUNT'
      THEN
        p_ri_invoice_query_rec.print_count :=
          xgv_common.r_decode(p_printcount_zero, 'Y', '0', NULL)
          || xgv_common.r_decode(p_printcount_one, 'Y', '1', NULL);

      -- Batch invoice number
      ELSIF  p_segment_type(l_index) = 'BINVNUM'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_batch_inv_num;

      -- Invoice number
      ELSIF  p_segment_type(l_index) = 'INVNUM'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_inv_num;

      -- Document sequence number
      ELSIF  p_segment_type(l_index) = 'ARDOCNUM'
      THEN
        p_ri_invoice_query_rec.doc_seq_from := p_doc_seq_from;
        p_ri_invoice_query_rec.doc_seq_to   := p_doc_seq_to;

      -- Currency
      -- Currency
      ELSIF  p_segment_type(l_index) = 'INVCUR'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_currency_code;

      -- Invoice Amount
      ELSIF  p_segment_type(l_index) = 'INVAMOUNT'
      THEN
        p_ri_invoice_query_rec.inv_amount_from := p_inv_amount_from;
        p_ri_invoice_query_rec.inv_amount_to   := p_inv_amount_to;

      -- Term due date
      ELSIF  p_segment_type(l_index) = 'DUEDATE'
      THEN
        p_ri_invoice_query_rec.due_date_from := p_due_date_from;
        p_ri_invoice_query_rec.due_date_to   := p_due_date_to;

      -- Term
      ELSIF  p_segment_type(l_index) = 'TERM'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_term;

      -- Payment method
      ELSIF  p_segment_type(l_index) = 'PAYMETHOD'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_payment_method;

      -- Transaction header description
      ELSIF  p_segment_type(l_index) = 'HDESC'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_header_description;

      -- Transaction source
      ELSIF  p_segment_type(l_index) = 'SOURCE'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_source;

      -- Transaction batch
      ELSIF  p_segment_type(l_index) = 'BATCH'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_batch;

      -- Invoice line type
      ELSIF  p_segment_type(l_index) = 'LTYPE'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_line_type;

      -- Invoice line item name
      ELSIF  p_segment_type(l_index) = 'LITEM'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_line_item;

      -- Invoice line description
      ELSIF  p_segment_type(l_index) = 'LDESC'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_line_description;

      -- Transaction distribution class
      ELSIF  p_segment_type(l_index) = 'DCLASS'
      THEN
        p_ri_invoice_query_rec.condition_tab(l_index) := p_dist_class;

      -- General Ledger date
      ELSIF  p_segment_type(l_index) = 'GLDATE'
      THEN
        p_ri_invoice_query_rec.gl_date_from := p_gl_date_from;
        p_ri_invoice_query_rec.gl_date_to   := p_gl_date_to;

      -- DFF of "Transaction Information"
      -- AFF
      -- DFF of "Line Distribution Information"
      ELSIF  xgv_common.is_number(p_segment_type(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(p_segment_type(l_index))) = 'RA_CUSTOMER_TRX'
        THEN
          l_index_h_dff_condition := l_index_h_dff_condition + 1;
          p_ri_invoice_query_rec.condition_tab(l_index) := p_h_dff_condition(l_index_h_dff_condition);

        ELSIF  xgv_common.get_flexfield_name(to_number(p_segment_type(l_index))) = 'GL#'
        THEN
          l_index_aff_condition := l_index_aff_condition + 1;
          p_ri_invoice_query_rec.condition_tab(l_index) := p_aff_condition(l_index_aff_condition);

        ELSIF  xgv_common.get_flexfield_name(to_number(p_segment_type(l_index))) = 'RA_CUST_TRX_LINE_GL_DIST'
        THEN
          l_index_d_dff_condition := l_index_d_dff_condition + 1;
          p_ri_invoice_query_rec.condition_tab(l_index) := p_d_dff_condition(l_index_d_dff_condition);
        END IF;
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
        || get_tag('TEXT_NEW_CONDITION', 'E', 'javascript:gotoPage(''riq'');');

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
        || get_tag('TEXT_OPEN_CONDITION', 'E', 'javascript:gotoPage(''riq.open'');');

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
  --Description: Display condition editor for Payables inquiry
  --Note:
  --Parameter(s):
  --  p_modify_flag         : Modify flag(Yes/No)
  --  p_ri_invoice_query_rec: Query condition record
  --==========================================================
  PROCEDURE show_query_editor(
    p_modify_flag          IN VARCHAR2,
    p_ri_invoice_query_rec IN xgv_common.ar_invoice_query_rtype)
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
      WHERE  xuiv.inquiry_type = 'RI'
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
        AND  xfsv.flexfield_name IN ('RA_CUSTOMER_TRX', 'RA_CUSTOMER_TRX_LINES')
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
      UNION ALL
      SELECT 5 order1,
             xfsv.segment_id order2,
             '<option value="' || to_char(xfsv.segment_id)
             || decode(to_char(xfsv.segment_id), p_default, '" selected>', '">')
             || xfsv.segment_name output_string
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.flexfield_name = 'RA_CUST_TRX_LINE_GL_DIST'
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
    htp.p('<input type="hidden" name="p_query_id" value="' || p_ri_invoice_query_rec.query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' || htf.escape_sc(p_ri_invoice_query_rec.query_name) || '">');

    htp.p('<table width="100%" border="0" cellpadding="0" cellspacing="0">');

    htp.p('<tr>');
    htp.p('<td><script>t(20, 1);</script></td>');
    htp.p('<td colspan="2" width="100%">');

    xgv_common.show_title(
      xgv_common.get_message('TITLE_CONDITION_NAME', nvl(p_ri_invoice_query_rec.query_name, ' ')),
      '<span class="OraTextInline">'
      || '<img src="/XGV_IMAGE/ii-required_status.gif">'
      || xgv_common.get_message('NOTE_MANDATORY_CONDITION'),
      p_fontsize=>'M');

    --------------------------------------------------
    -- Display query condition information
    --------------------------------------------------
    IF  p_ri_invoice_query_rec.query_name IS NOT NULL
    THEN
      htp.p('<table border="0" cellpadding="0" cellspacing="0">');

      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_CREATED_BY')
        ||  '</th>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<td class="OraDataText">'
        ||  xgv_common.escape_sc(xgv_common.get_user_name(p_ri_invoice_query_rec.created_by))
        ||  '</td>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_CREATION_DATE')
        ||  '</th>'
        ||  '<td><script>t(12, 0);</script></td>'
        ||  '<td class="OraDataText">' || p_ri_invoice_query_rec.creation_date || '</td>'
        ||  '</tr>');
      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_UPDATED_BY')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataText">'
        ||  xgv_common.escape_sc(xgv_common.get_user_name(p_ri_invoice_query_rec.last_updated_by))
        ||  '</td>'
        ||  '<td></td>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_UPDATE_DATE')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataText">' || p_ri_invoice_query_rec.last_update_date || '</td>'
        ||  '</tr>');
      htp.p('<tr>'
        ||  '<th class="OraPromptText" nowrap>'
        ||  xgv_common.get_message('PROMPT_LAST_COUNT_ROWS')
        ||  '</th>'
        ||  '<td></td>'
        ||  '<td class="OraDataNumber">' || to_char(p_ri_invoice_query_rec.result_rows, '999G999G999G990') || '</td>'
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
      ||  xgv_common.get_message('PROMPT_SHOW_AR_HEADER_LINE')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText" nowrap>'
      ||  '<input type="checkbox" name="p_show_header_line" value="Y"'
      ||  xgv_common.r_decode(
            instr(nvl(p_ri_invoice_query_rec.condition_tab(
              xgv_common.get_segment_index(p_ri_invoice_query_rec.segment_type_tab, 'LINENUM')), 'HLADP'),
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
    FOR  l_index IN 1..p_ri_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Data Refer(Hidden items)
      IF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'EXDD'
      THEN
        htp.p('<input type="hidden" name="p_show_order" value="'
          ||  p_ri_invoice_query_rec.show_order_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_sort_order" value="'
          ||  p_ri_invoice_query_rec.sort_order_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_sort_method" value="'
          ||  p_ri_invoice_query_rec.sort_method_tab(l_index) || '">');
        htp.p('<input type="hidden" name="p_segment_type" value="'
          ||  p_ri_invoice_query_rec.segment_type_tab(l_index) || '">');

      -- Line Number(Line Type)
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LINENUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LINENUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.get_message('TIP_AR_LINE_NUMBER')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LINENUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Customer Name
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'CUST'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'CUST'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_cust" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestCustomers_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="CUST">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Customer Site Name
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'CUSTSITE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'CUSTSITE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_cust_site" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestCustomerSites_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="CUSTSITE">');
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
    FOR  l_index IN 1..p_ri_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Transaction Date
      IF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'TRXP'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'TRXP'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_trx_date_from" size="20" maxlength="11" value="'
          ||  p_ri_invoice_query_rec.trx_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Trxdate_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_trx_date_to" size="20" maxlength="11" value="'
          ||  p_ri_invoice_query_rec.trx_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_Trxdate_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="TRXP">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Transaction Class
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'TRXCLASS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'TRXCLASS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_trx_class" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestTrxClasses_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="TRXCLASS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Transaction Type
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'TRXTYPE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'TRXTYPE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_trx_type" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestTrxTypes_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="TRXTYPE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Status
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'APPSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'APPSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_receipt" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.app_status, '*'), 'Y'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_COLLECTED')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_partreceipt" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.app_status, '*'), 'NP'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_OPENORPART')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="APPSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Posted Status
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'POSTSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_posted" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.post_status, '*'), 'Y'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_POSTED')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_unposted" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.post_status, '*'), 'N'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_UNPOSTED')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_partposted" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.post_status, '*'), 'P'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_PARTPOSTED')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="POSTSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

        -- Complete Status
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'COMPSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'COMPSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_complete" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.comp_status, '*'), 'Y'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_COMPLATE')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_uncomplete" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.comp_status, '*'), 'N'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_UNCOMPLATE')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="COMPSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

        -- Print Count
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PRINTCOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<img src="/XGV_IMAGE/ii-required_status.gif">'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PRINTCOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="checkbox" name="p_printcount_zero" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.print_count, '*'), '0'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_PRINT_COUNT_0')
          ||  '<script>t(12, 0);</script>'
          ||  '<input type="checkbox" name="p_printcount_one" value="Y"'
          ||  xgv_common.r_decode(instr(nvl(p_ri_invoice_query_rec.print_count, '*'), '1'), 0, '>', ' checked>')
          ||  xgv_common.get_message('PROMPT_AR_PRINT_COUNT_1')
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PRINTCOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Batch Invoice Number
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'BINVNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'BINVNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_batch_inv_num" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="BINVNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Number
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'INVNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'INVNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_inv_num" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="INVNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Document Sequence Number
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ARDOCNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'ARDOCNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_doc_seq_from" size="20" maxlength="15" value="'
          ||  p_ri_invoice_query_rec.doc_seq_from
          ||  '">'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_doc_seq_to" size="20" maxlength="15" value="'
          ||  p_ri_invoice_query_rec.doc_seq_to
          ||  '">'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="ARDOCNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Currency
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'INVCUR'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'INVCUR'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<select name="p_currency_code">');
        FOR  l_currency_rec IN xgv_common.g_tag_currency_cur(p_ri_invoice_query_rec.condition_tab(l_index), 'Y')
        LOOP
          htp.p(l_currency_rec.output_string);
        END LOOP;
        htp.p('</select>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="INVCUR">');
        IF  xgv_common.get_profile_option_value('XGV_ENABLE_SHOW_AR_RATE') = 'Y'
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
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'INVAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'INVAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_inv_amount_from" size="20" maxlength="15" value="'
          ||  p_ri_invoice_query_rec.inv_amount_from
          ||  '">'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_inv_amount_to" size="20" maxlength="15" value="'
          ||  p_ri_invoice_query_rec.inv_amount_to
          ||  '">'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="INVAMOUNT">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="ORGIAMOUNT">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="GAINAMOUNT">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="TAXAMOUNT">');
        htp.p('<input type="hidden" name="p_show_order" value="">'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="REMAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Term Due Date
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'DUEDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'DUEDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_due_date_from" size="20" maxlength="11" value="'
          ||  p_ri_invoice_query_rec.due_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_DueDate_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_due_date_to" size="20" maxlength="11" value="'
          ||  p_ri_invoice_query_rec.due_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_DueDate_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="DUEDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Term
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'TERM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'TERM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_term" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestTerms_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="TERM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Method
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PAYMETHOD'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PAYMETHOD'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_payment_method" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestPayMethods_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PAYMETHOD">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Transaction Header Description
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'HDESC'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'HDESC'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_header_description" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="HDESC">'
          ||  '</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Transaction Source
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'SOURCE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'SOURCE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_source" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestSources_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="SOURCE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Transaction Batch
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'BATCH'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'BATCH'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_batch" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestBatches_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="BATCH">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- DFF of "Transaction Information"
      ELSIF  xgv_common.get_flexfield_name(p_ri_invoice_query_rec.segment_type_tab(l_index)) = 'RA_CUSTOMER_TRX'
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
          AND  xfsv.segment_id = to_number(p_ri_invoice_query_rec.segment_type_tab(l_index));

        IF  l_hide_flag = 'N'
        THEN
          htp.p('<tr>');
          htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
            ||  xgv_common.r_decode(l_mandatory_flag,
                  'Y', '<img src="/XGV_IMAGE/ii-required_status.gif">', NULL)
            ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_ri_invoice_query_rec.segment_type_tab(l_index)))
            ||  '</td>');
          htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
            ||  '<input type="text" name="p_h_dff_condition" size="60" maxlength="100" value="'
            ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
            ||  '">'
            ||  xgv_common.r_nvl2(l_show_lov_proc,
                  '<a href="javascript:requestH_DFF_LOV('
                  ||  p_ri_invoice_query_rec.segment_type_tab(l_index) || ', ' || l_parent_segment_id || ')">'
                  ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
                  ||  '</a>',
                  '<img src="/XGV_IMAGE/ai-search_disabled.gif" border="0">')
            ||  '</td>');
          htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
          output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
          htp.p('</td>');
          htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
          output_tag_sort_order(
            p_ri_invoice_query_rec.sort_order_tab(l_index),
            p_ri_invoice_query_rec.sort_method_tab(l_index));
          htp.p('<input type="hidden" name="p_segment_type" value="'
            ||  p_ri_invoice_query_rec.segment_type_tab(l_index)
            ||  '">');
          htp.p('</td>');
          htp.p('<td></td>');
          htp.p('</tr>');

        ELSE
          htp.p('<input type="hidden" name="p_h_dff_condition" value="'
            ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index)) || '">'
            ||  '<input type="hidden" name="p_show_order" value="">'
            ||  '<input type="hidden" name="p_sort_order" value="">'
            ||  '<input type="hidden" name="p_sort_method" value="">'
            ||  '<input type="hidden" name="p_segment_type" value="'
            ||  p_ri_invoice_query_rec.segment_type_tab(l_index) || '">');
        END IF;
      END IF;

    END LOOP;

    --------------------------------------------------
    -- Display invoice line conditions
    --------------------------------------------------
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_INVOICE_LINE_CONDITIONS'), p_fontsize=>'S');
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
    FOR  l_index IN 1..p_ri_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Invoice Line Line Number
      IF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LLINENUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LLINENUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LLINENUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Line Type
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LTYPE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LTYPE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_line_type" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestLineTypes_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LTYPE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Line Item Name
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LITEM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LITEM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_line_item" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestLineItems_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LITEM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Line Unit Price
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LUPRICE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LUPRICE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LUPRICE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Line Quantity
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LQTY'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LQTY'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LQTY">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Line Unit Of Measure
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LUOM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LUOM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LUOM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Line Amount
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="LAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Line Tax Code
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LTAXCODE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LTAXCODE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="LTAXCODE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Line Description
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'LDESC'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'LDESC'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_line_description" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="hidden" name="p_sort_order" value="">'
          ||  '<input type="hidden" name="p_sort_method" value="">'
          ||  '<input type="hidden" name="p_segment_type" value="LDESC">'
          ||  '</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- DFF of "Invoice Line Information"
      ELSIF  xgv_common.is_number(p_ri_invoice_query_rec.segment_type_tab(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(p_ri_invoice_query_rec.segment_type_tab(l_index))) = 'RA_CUSTOMER_TRX_LINES'
        THEN
          SELECT nvl(xfsv.parent_segment_id, 0),
                 xfsv.show_lov_proc,
                 hide_flag
          INTO   l_parent_segment_id,
                 l_show_lov_proc,
                 l_hide_flag
          FROM   xgv_flex_structures_vl xfsv
          WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
            AND  xfsv.segment_id = to_number(p_ri_invoice_query_rec.segment_type_tab(l_index));

          IF  l_hide_flag = 'N'
          THEN
            htp.p('<tr>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_ri_invoice_query_rec.segment_type_tab(l_index)))
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
            htp.p('</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_sort_order(
              p_ri_invoice_query_rec.sort_order_tab(l_index),
              p_ri_invoice_query_rec.sort_method_tab(l_index));
            htp.p('<input type="hidden" name="p_segment_type" value="'
              ||  p_ri_invoice_query_rec.segment_type_tab(l_index)
              ||  '">');
            htp.p('</td>');
            htp.p('<td></td>');
            htp.p('</tr>');

          ELSE
            htp.p('<input type="hidden" name="p_show_order" value="">'
              ||  '<input type="hidden" name="p_sort_order" value="">'
              ||  '<input type="hidden" name="p_sort_method" value="">'
              ||  '<input type="hidden" name="p_segment_type" value="'
              ||  p_ri_invoice_query_rec.segment_type_tab(l_index) || '">');
          END IF;
        END IF;
      END IF;

    END LOOP;

    --------------------------------------------------
    -- Display invoice adjustment conditions
    --------------------------------------------------
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_INVOICE_ADJ_CONDITIONS'), p_fontsize=>'S');
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
    FOR  l_index IN 1..p_ri_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Invoice Adjustment Number
      IF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ADJNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'ADJNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="ADJNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Adjustment Recode Name
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ADJRECNAME'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'ADJRECNAME'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="ADJRECNAME">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Adjustment Type
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ADJTYPE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'ADJTYPE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="ADJTYPE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Adjustment Status
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ADJSTATUS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'ADJSTATUS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="ADJSTATUS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Adjustment Amount
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ADJAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'ADJAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="ADJAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Adjustment Line Amount
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ADJLAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'ADJLAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="ADJLAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Adjustment Tax
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ADJTAX'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'ADJTAX'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="ADJTAX">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');
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
    FOR  l_index IN 1..p_ri_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Invoice Distribution Line Number
      IF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'DLINENUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'DLINENUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="DLINENUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Distribution Other Line Number
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'DOLINENUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'DOLINENUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="DOLINENUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Distribution Class
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'DCLASS'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'DCLASS'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<input type="text" name="p_dist_class" size="60" maxlength="100" value="'
          ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
          ||  '">'
          ||  '<a href="javascript:requestDistClasses_LOV();">'
          ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="DCLASS">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- General Ledger date
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'GLDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'GLDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '<table width="100%" border="0" cellpadding="0" cellspacing="0">'
          ||  '<tr>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_FROM')
          ||  '<input type="text" name="p_gl_date_from" size="20" maxlength="11" value="'
          ||  p_ri_invoice_query_rec.gl_date_from
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_GLPost_Date_from();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '<td>'
          ||  xgv_common.get_message('PROMPT_TO')
          ||  '<input type="text" name="p_gl_date_to" size="20" maxlength="11" value="'
          ||  p_ri_invoice_query_rec.gl_date_to
          ||  '">'
          ||  '<a href="javascript:requestDatePicker_GLPost_Date_to();">'
          ||  '<img src="/XGV_IMAGE/ai-datepicker_enabled.gif" border="0">'
          ||  '</a>'
          ||  '</td>'
          ||  '</tr>'
          ||  '</table>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="GLDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Invoice Distribution Amount
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'DAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'DAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="DAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- AFF
      -- DFF of "Line Distribution Information"
      ELSIF  xgv_common.is_number(p_ri_invoice_query_rec.segment_type_tab(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(p_ri_invoice_query_rec.segment_type_tab(l_index))) = 'GL#'
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
            AND  xfsv.segment_id = to_number(p_ri_invoice_query_rec.segment_type_tab(l_index));

          IF  l_hide_flag = 'N'
          THEN
            htp.p('<tr>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_ri_invoice_query_rec.segment_type_tab(l_index)))
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  '<input type="text" name="p_aff_condition" size="60" maxlength="100" value="'
              ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
              ||  '">'
              ||  xgv_common.r_nvl2(l_show_lov_proc,
                    '<a href="javascript:requestAFF_LOV('
                    ||  p_ri_invoice_query_rec.segment_type_tab(l_index) || ', ' || l_parent_segment_id || ')">'
                    ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
                    ||  '</a>',
                    '<img src="/XGV_IMAGE/ai-search_disabled.gif" border="0">')
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
            htp.p('</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_sort_order(
              p_ri_invoice_query_rec.sort_order_tab(l_index),
              p_ri_invoice_query_rec.sort_method_tab(l_index));
            htp.p('<input type="hidden" name="p_segment_type" value="'
              ||  p_ri_invoice_query_rec.segment_type_tab(l_index)
              ||  '">');
            htp.p('</td>');
            htp.p('<td></td>');
            htp.p('</tr>');

          ELSE
            htp.p('<input type="hidden" name="p_aff_condition" value="'
              ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index)) || '">'
              ||  '<input type="hidden" name="p_show_order" value="">'
              ||  '<input type="hidden" name="p_sort_order" value="">'
              ||  '<input type="hidden" name="p_sort_method" value="">'
              ||  '<input type="hidden" name="p_segment_type" value="'
              ||  p_ri_invoice_query_rec.segment_type_tab(l_index) || '">');
          END IF;

        ELSIF  xgv_common.get_flexfield_name(to_number(p_ri_invoice_query_rec.segment_type_tab(l_index))) = 'RA_CUST_TRX_LINE_GL_DIST'
        THEN
          SELECT nvl(xfsv.parent_segment_id, 0),
                 xfsv.show_lov_proc,
                 hide_flag
          INTO   l_parent_segment_id,
                 l_show_lov_proc,
                 l_hide_flag
          FROM   xgv_flex_structures_vl xfsv
          WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
            AND  xfsv.segment_id = to_number(p_ri_invoice_query_rec.segment_type_tab(l_index));

          IF  l_hide_flag = 'N'
          THEN
            htp.p('<tr>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  xgv_common.escape_sc(xgv_common.get_segment_name(p_ri_invoice_query_rec.segment_type_tab(l_index)))
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
              ||  '<input type="text" name="p_d_dff_condition" size="60" maxlength="100" value="'
              ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index))
              ||  '">'
              ||  xgv_common.r_nvl2(l_show_lov_proc,
                    '<a href="javascript:requestD_DFF_LOV('
                    ||  p_ri_invoice_query_rec.segment_type_tab(l_index) || ', ' || l_parent_segment_id || ')">'
                    ||  '<img src="/XGV_IMAGE/ai-search_enabled.gif" border="0">'
                    ||  '</a>',
                    '<img src="/XGV_IMAGE/ai-search_disabled.gif" border="0">')
              ||  '</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
            htp.p('</td>');
            htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
            output_tag_sort_order(
              p_ri_invoice_query_rec.sort_order_tab(l_index),
              p_ri_invoice_query_rec.sort_method_tab(l_index));
            htp.p('<input type="hidden" name="p_segment_type" value="'
              ||  p_ri_invoice_query_rec.segment_type_tab(l_index)
              ||  '">');
            htp.p('</td>');
            htp.p('<td></td>');
            htp.p('</tr>');

          ELSE
            htp.p('<input type="hidden" name="p_d_dff_condition" value="'
              ||  htf.escape_sc(p_ri_invoice_query_rec.condition_tab(l_index)) || '">'
              ||  '<input type="hidden" name="p_show_order" value="">'
              ||  '<input type="hidden" name="p_sort_order" value="">'
              ||  '<input type="hidden" name="p_sort_method" value="">'
              ||  '<input type="hidden" name="p_segment_type" value="'
              ||  p_ri_invoice_query_rec.segment_type_tab(l_index) || '">');
          END IF;
        END IF;
      END IF;

    END LOOP;

    --------------------------------------------------
    -- Display payment schedule conditions
    --------------------------------------------------
    htp.p('<tr>'
      ||  '<td colspan="5">'
      ||  '<script>t(1, 10);</script>');
    xgv_common.show_title(xgv_common.get_message('TITLE_AR_PAY_SCHDLE_CONDITIONS'), p_fontsize=>'S');
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
    FOR  l_index IN 1..p_ri_invoice_query_rec.segment_type_tab.COUNT
    LOOP

      -- Payment Schedule Number
      IF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Schedule Sequence Number
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PSEQNUM'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PSEQNUM'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PSEQNUM">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Schedule Due Date
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PDUEDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PDUEDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="PDUEDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Schedule Currency
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PCUR'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PCUR'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          p_ri_invoice_query_rec.sort_method_tab(l_index));
        htp.p('<input type="hidden" name="p_segment_type" value="PCUR">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Schedule Original Amount
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PORGAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PORGAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="PORGAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Schedule Amount Remaining
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PREMAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PREMAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="PREMAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Schedule Applied Amount
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PAPPAMOUNT'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PAPPAMOUNT'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="PAPPAMOUNT">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Schedule GL Posted Date
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PGLDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PGLDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="PGLDATE">');
        htp.p('</td>');
        htp.p('<td></td>');
        htp.p('</tr>');

      -- Payment Schedule Paid Date
      ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PPAIDDATE'
      THEN
        htp.p('<tr>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  xgv_common.escape_sc(xgv_common.get_segment_name('RI', 'PPAIDDATE'))
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>'
          ||  '</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_show_order(p_ri_invoice_query_rec.show_order_tab(l_index));
        htp.p('</td>');
        htp.p('<td style="border:1px solid #cccc99" class="OraTableCellText" nowrap>');
        output_tag_sort_order(
          p_ri_invoice_query_rec.sort_order_tab(l_index),
          nvl(p_ri_invoice_query_rec.sort_method_tab(l_index), 'ASC'));
        htp.p('<input type="hidden" name="p_segment_type" value="PPAIDDATE">');
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

    -- Display summary segment and display subtotal line only
    htp.p('<tr>'
      ||  '<th class="OraPromptText" nowrap>'
      ||  xgv_common.get_message('PROMPT_SUBTOTAL_ITEM')
      ||  '</th>'
      ||  '<td><script>t(12, 0);</script></td>'
      ||  '<td class="OraDataText">'
      ||  '<select name="p_break_key">');
    FOR  l_break_key_rec IN l_tag_breakkey_cur(p_ri_invoice_query_rec.break_key)
    LOOP
      htp.p(l_break_key_rec.output_string);
    END LOOP;
    htp.p('</select>'
      ||  '<script>t(12, 0);</script>'
      ||  '<input type="checkbox" name="p_show_subtotalonly" value="Y"'
      ||  xgv_common.r_decode(p_ri_invoice_query_rec.show_subtotalonly, 'Y', ' checked>', '>')
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
      ||  xgv_common.r_decode(p_ri_invoice_query_rec.show_total, 'Y', ' checked>', '>')
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
    --   ||  xgv_common.r_decode(p_ri_invoice_query_rec.show_bringforward, 'Y', ' checked>', '>')
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
    FOR  l_tag_result_format_rec IN l_tag_result_format_cur(p_ri_invoice_query_rec.result_format)  /* 13-May-2005 Changed by ytsujiha_jp */
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
      ||  htf.escape_sc(p_ri_invoice_query_rec.file_name) || '">'
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
  --  p_cust              : Customer name
  --  p_cust_site         : Customer site name
  --  p_trx_date_from     : Transaction date(From)
  --  p_trx_date_to       : Transaction date(To)
  --  p_trx_class         : Transaction class
  --  p_trx_type          : Transaction type
  --  p_receipt           : Status(receipt)
  --  p_partreceipt       : Status(no receipt, or part receipt)
  --  p_posted            : Posted status(posted)
  --  p_unposted          : Posted status(unposted)
  --  p_partposted        : Posted status(partially posted)
  --  p_complete          : Complete status(complete)
  --  p_uncomplete        : Complete status(uncomplete)
  --  p_printcount_zero   : Print count(zero)
  --  p_printcount_one    : Print count(one more than)
  --  p_batch_inv_num     : Batch invoice number
  --  p_inv_num           : Invoice number
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_inv_amount_from   : Invoice amount(From)
  --  p_inv_amount_to     : Invoice amount(To)
  --  p_due_date_from     : Term due date(From)
  --  p_due_date_to       : Term due date(To)
  --  p_term              : Term
  --  p_payment_method    : Payment method
  --  p_header_description: Transaction header description
  --  p_source            : Transaction source
  --  p_batch             : Transaction batch
  --  p_h_dff_condition   : Segment condition of transaction header dff
  --  p_line_type         : Invoice line type
  --  p_line_item         : Invoice line item name
  --  p_line_description  : Invoice line description
  --  p_dist_class        : Transaction distribution class
  --  p_gl_date_from      : General Ledger date(From)
  --  p_gl_date_to        : General Ledger date(To)
  --  p_aff_condition     : Segment condition of transaction distribution aff
  --  p_d_dff_condition   : Segment condition of transaction distribution dff
  --  p_show_order        : Segment Display order
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
    p_cust               IN VARCHAR2 DEFAULT NULL,
    p_cust_site          IN VARCHAR2 DEFAULT NULL,
    p_trx_date_from      IN VARCHAR2 DEFAULT NULL,
    p_trx_date_to        IN VARCHAR2 DEFAULT NULL,
    p_trx_class          IN VARCHAR2 DEFAULT NULL,
    p_trx_type           IN VARCHAR2 DEFAULT NULL,
    p_receipt            IN VARCHAR2 DEFAULT 'N',
    p_partreceipt        IN VARCHAR2 DEFAULT 'N',
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_partposted         IN VARCHAR2 DEFAULT 'N',
    p_complete           IN VARCHAR2 DEFAULT 'N',
    p_uncomplete         IN VARCHAR2 DEFAULT 'N',
    p_printcount_zero    IN VARCHAR2 DEFAULT 'N',
    p_printcount_one     IN VARCHAR2 DEFAULT 'N',
    p_batch_inv_num      IN VARCHAR2 DEFAULT NULL,
    p_inv_num            IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_inv_amount_from    IN NUMBER   DEFAULT NULL,
    p_inv_amount_to      IN NUMBER   DEFAULT NULL,
    p_due_date_from      IN VARCHAR2 DEFAULT NULL,
    p_due_date_to        IN VARCHAR2 DEFAULT NULL,
    p_term               IN VARCHAR2 DEFAULT NULL,
    p_payment_method     IN VARCHAR2 DEFAULT NULL,
    p_header_description IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_h_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_line_type          IN VARCHAR2 DEFAULT NULL,
    p_line_item          IN VARCHAR2 DEFAULT NULL,
    p_line_description   IN VARCHAR2 DEFAULT NULL,
    p_dist_class         IN VARCHAR2 DEFAULT NULL,
    p_gl_date_from       IN VARCHAR2 DEFAULT NULL,
    p_gl_date_to         IN VARCHAR2 DEFAULT NULL,
    p_aff_condition      IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_d_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
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

    l_ri_invoice_query_rec  xgv_common.ar_invoice_query_rtype;

    l_1st_h_dff_segment_id  xgv_flex_structures_vl.segment_id%TYPE := NULL;
    l_1st_d_dff_segment_id  xgv_flex_structures_vl.segment_id%TYPE := NULL;

    CURSOR l_mandatory_flag_cur
    IS
      SELECT xfsv.mandatory_flag mandatory_flag
      FROM   xgv_flex_structures_vl xfsv
      WHERE  xfsv.set_of_books_id = xgv_common.get_sob_id
        AND  xfsv.flexfield_name = 'RA_CUSTOMER_TRX'
      ORDER BY xfsv.segment_id;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('RIQ.TOP');

    DECLARE
      l_cookie  owa_cookie.cookie;
    BEGIN
      /* Bug#211005 15-Sep-2005 Changed by ytsujiha_jp */
      l_cookie := owa_cookie.get('XGV_SESSION');
      IF  l_cookie.num_vals != 1
      THEN
        raise_application_error(-20025, xgv_common.get_message('XGV-20025'));
      END IF;
      /* Bug#211005 15-Sep-2005 Changed by ytsujiha_jp */
      IF  xgv_common.split(l_cookie.vals(1), ',', 1, 5) != xgv_common.ARWI  /* Req#230009 30-Jul-2007 Changed by ytsujiha_jp */
      THEN
        owa_util.mime_header('text/html', FALSE);
        owa_cookie.send('XGV_SESSION',
          xgv_common.split(l_cookie.vals(1), ',', 1, 1) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 2) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 3) || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 4) || ','
          || xgv_common.ARWI || ','
          || xgv_common.split(l_cookie.vals(1), ',', 1, 6));  /* Req#230009 30-Jul-2007 Changed by ytsujiha_jp */
        owa_util.http_header_close;

        htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
        htp.p('<html dir="ltr">');
        htp.p('<body>');
        htp.p('<form name="f_refresh" method="post" action="./xgv_riq.top"></form>');
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
      set_query_condition(l_ri_invoice_query_rec, p_query_id);

    -- Count rows
    ELSIF  p_mode = 'R'
    THEN
      NULL;
      -- Count rows
      xgv_common.open_output_dest('W');
      xgv_rie.execute_sql(
        p_query_id, p_query_name,
        p_show_header_line,
        p_cust, p_cust_site,
        p_trx_date_from, p_trx_date_to,
        p_trx_class, p_trx_type,
        p_receipt, p_partreceipt,
        p_posted, p_unposted, p_partposted,
        p_complete, p_uncomplete,
        p_printcount_zero, p_printcount_one,
        p_batch_inv_num, p_inv_num, p_doc_seq_from, p_doc_seq_to,
        p_currency_code, p_inv_amount_from, p_inv_amount_to,
        p_due_date_from, p_due_date_to, p_term, p_payment_method,
        p_header_description, p_source, p_batch, p_h_dff_condition,
        p_line_type, p_line_item, p_line_description,
        p_dist_class, p_gl_date_from, p_gl_date_to,
        p_aff_condition, p_d_dff_condition,
        p_show_order, p_sort_order, p_sort_method, p_segment_type,
        NULL, 'N', 'N', 'N', 'COUNT', NULL);

      -- Set query condition
      set_query_condition_local(
        l_ri_invoice_query_rec, p_query_id,
        p_show_header_line,
        p_cust, p_cust_site, p_trx_date_from, p_trx_date_to,
        p_trx_class, p_trx_type, p_receipt, p_partreceipt,
        p_posted, p_unposted, p_partposted,
        p_complete, p_uncomplete, p_printcount_zero, p_printcount_one,
        p_batch_inv_num, p_inv_num, p_doc_seq_from, p_doc_seq_to, p_currency_code,
        p_inv_amount_from, p_inv_amount_to,
        p_due_date_from, p_due_date_to, p_term, p_payment_method,
        p_header_description, p_source, p_batch, p_h_dff_condition,
        p_line_type, p_line_item, p_line_description,
        p_dist_class, p_gl_date_from, p_gl_date_to,
        p_aff_condition, p_d_dff_condition,
        p_show_order, p_sort_order, p_sort_method, p_segment_type,
        p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
        p_result_format, p_file_name, NULL);

    ELSE
      -- Set query condition
      set_query_condition_local(
        l_ri_invoice_query_rec, p_query_id,
        p_show_header_line,
        p_cust, p_cust_site, p_trx_date_from, p_trx_date_to,
        p_trx_class, p_trx_type, p_receipt, p_partreceipt,
        p_posted, p_unposted, p_partposted,
        p_complete, p_uncomplete, p_printcount_zero, p_printcount_one,
        p_batch_inv_num, p_inv_num, p_doc_seq_from, p_doc_seq_to, p_currency_code,
        p_inv_amount_from, p_inv_amount_to,
        p_due_date_from, p_due_date_to, p_term, p_payment_method,
        p_header_description, p_source, p_batch, p_h_dff_condition,
        p_line_type, p_line_item, p_line_description,
        p_dist_class, p_gl_date_from, p_gl_date_to,
        p_aff_condition, p_d_dff_condition,
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
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<script language="JavaScript">');
    htp.p('<!--');
    htp.p('window.name = "xgv_main";');
    htp.p('// -->');
    htp.p('</script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_AR_INVOICE_INQUIRY', xgv_common.get_resp_name) || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();">');

    -- Display Header
    xgv_common.show_header(
      xgv_common.get_global_buttons_tag('MAIN'),
      xgv_common.get_tabs_tag('RIQ'));

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
        'MESSAGE_COUNT_ROWS', ltrim(to_char(l_ri_invoice_query_rec.result_rows, '999G999G999G990')));

    -- Display svae confirmation message
    ELSIF  p_mode = 'S'
    THEN
      htp.prn('<script>t(1, 7);</script>');
      xgv_common.show_messagebox('C', 'MESSAGE_SAVE_CONDITION');
    END IF;

    -- Display title
    htp.prn('<script>t(1, 7);</script>');
    xgv_common.show_title(
      xgv_common.get_message('TITLE_AR_INVOICE_INQUIRY', xgv_common.get_resp_name),
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
    show_query_editor(p_modify_flag, l_ri_invoice_query_rec);

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

    FOR  l_index IN 1..l_ri_invoice_query_rec.segment_type_tab.COUNT
    LOOP
      IF  xgv_common.is_number(l_ri_invoice_query_rec.segment_type_tab(l_index))
      THEN
        IF  xgv_common.get_flexfield_name(to_number(l_ri_invoice_query_rec.segment_type_tab(l_index))) = 'RA_CUSTOMER_TRX'
        AND l_1st_h_dff_segment_id IS NULL
        THEN
          l_1st_h_dff_segment_id := to_number(l_ri_invoice_query_rec.segment_type_tab(l_index));

        ELSIF  xgv_common.get_flexfield_name(to_number(l_ri_invoice_query_rec.segment_type_tab(l_index))) = 'RA_CUST_TRX_LINE_GL_DIST'
        AND l_1st_d_dff_segment_id IS NULL
        THEN
          l_1st_d_dff_segment_id := to_number(l_ri_invoice_query_rec.segment_type_tab(l_index));
        END IF;
      END IF;
    END LOOP;

    htp.p('<form name="f_information">');
    htp.p('<input type="hidden" name="p_functional_currency" value="' || xgv_common.get_functional_currency || '">');
    htp.p('<input type="hidden" name="p_1st_h_dff_segment_id" value="' || to_char(l_1st_h_dff_segment_id) || '">');
    htp.p('<input type="hidden" name="p_1st_d_dff_segment_id" value="' || to_char(l_1st_d_dff_segment_id) || '">');
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

    htp.p('<form name="f_lov_customers" method="post" action="./xgv_riq.show_lov_customers" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_customer_sites" method="post" action="./xgv_riq.show_lov_customer_sites" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_customer_condition" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_trx_classes" method="post" action="./xgv_riq.show_lov_trx_classes" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_trx_types" method="post" action="./xgv_riq.show_lov_trx_types" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_terms" method="post" action="./xgv_riq.show_lov_terms" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_pay_methods" method="post" action="./xgv_riq.show_lov_pay_methods" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_sources" method="post" action="./xgv_riq.show_lov_sources" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_batches" method="post" action="./xgv_riq.show_lov_batches" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_h_dff" method="post" action="./xgv_riq.show_lov_h_dff" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_child_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_condition" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_line_types" method="post" action="./xgv_riq.show_lov_line_types" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_line_items" method="post" action="./xgv_riq.show_lov_line_items" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_dist_classes" method="post" action="./xgv_riq.show_lov_dist_classes" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_aff" method="post" action="./xgv_riq.show_lov_aff" target="xgv_lov">');
    htp.p('<input type="hidden" name="p_list_filter_value" value="">');
    htp.p('<input type="hidden" name="p_child_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_segment_id" value="">');
    htp.p('<input type="hidden" name="p_parent_condition" value="">');
    htp.p('</form>');

    htp.p('<form name="f_lov_d_dff" method="post" action="./xgv_riq.show_lov_d_dff" target="xgv_lov">');
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
  --Procedure Name: show_lov_customers
  --Description: Display LOV for customers
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_customers(
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_CUSTOMERS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_CUSTOMERS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_cust.value">');

    l_sql_rec.text(1) := 'SELECT count(hca.cust_account_id)';
    l_sql_rec.text(2) := 'FROM   hz_cust_accounts hca,';
    l_sql_rec.text(3) := '       hz_parties hp';
    l_sql_rec.text(4) := 'WHERE  hp.party_id = hca.party_id';
    l_sql_rec.text(5) := '  AND  EXISTS';                            /* 15-Jun-2005 Added by ytsujiha_jp */
    l_sql_rec.text(6) := '       (SELECT hcsu.site_use_id';
    l_sql_rec.text(7) := '        FROM   hz_cust_acct_sites hcas,';
    l_sql_rec.text(8) := '               hz_cust_site_uses hcsu';
    l_sql_rec.text(9) := '        WHERE  hcas.cust_account_id = hca.cust_account_id';
    l_sql_rec.text(10) := '          AND  hcsu.cust_acct_site_id = hcas.cust_acct_site_id';   /* Bug#230027 04-Dec-2007 Changed by ytsujiha_jp */
    l_sql_rec.text(11) := '          AND  ROWNUM <= 1)';                                      /* Bug#230027 04-Dec-2007 Changed by ytsujiha_jp */

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'hca', 'account_number', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(hp.party_name) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT hca.account_number, hp.party_name';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY hca.account_number ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY hp.party_name ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_CUSTOMERS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_customers', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addCustomersValue();');

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

  END show_lov_customers;

  --==========================================================
  --Procedure Name: show_lov_customer_sites
  --Description: Display LOV for customer sites
  --Note:
  --Parameter(s):
  --  p_list_filter_item  : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value : Filter value for list
  --  p_start_listno      : Start list no
  --  p_sort_item         : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method       : Sort method(ASC/DESC)
  --  p_customer_condition: Condition of Vendor
  --==========================================================
  PROCEDURE show_lov_customer_sites(
    p_list_filter_item    IN VARCHAR2 DEFAULT 'VALUE',
    p_list_filter_value   IN VARCHAR2 DEFAULT NULL,
    p_start_listno        IN NUMBER   DEFAULT 1,
    p_sort_item           IN VARCHAR2 DEFAULT 'VALUE',
    p_sort_method         IN VARCHAR2 DEFAULT 'ASC',
    p_customer_condition  IN VARCHAR2 DEFAULT NULL)
  IS

    l_sql_rec  xgv_common.sql_rtype;
    l_count_sql  VARCHAR2(32767);
    l_list_sql  VARCHAR2(32767);

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('RIQ.SHOW_LOV_CUSTOMER_SITES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_CUSTOMER_SITES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_cust_site.value">');

    l_sql_rec.text(1) := 'SELECT count(hcsa.account_number)';
    l_sql_rec.text(2) := 'FROM   (SELECT distinct hca.account_number, hp.party_name, hcsu.location';
    l_sql_rec.text(3) := '        FROM   hz_cust_site_uses hcsu,';
    l_sql_rec.text(4) := '               hz_cust_acct_sites hcas,';
    l_sql_rec.text(5) := '               hz_cust_accounts hca,';
    l_sql_rec.text(6) := '               hz_parties hp';
    l_sql_rec.text(7) := '        WHERE  hcas.cust_acct_site_id = hcsu.cust_acct_site_id';
    l_sql_rec.text(8) := '          AND  hca.cust_account_id = hcas.cust_account_id';
    l_sql_rec.text(9) := '          AND  hp.party_id = hca.party_id';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '          AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'hcsu', 'location', p_list_filter_value,
          'hca', 'account_number');
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '          AND upper(hcsu.location) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    IF  p_customer_condition IS NOT NULL
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '          AND (';
      xgv_common.get_where_clause(
        l_sql_rec, 'hca', 'account_number', p_customer_condition);
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';
    END IF;

    l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '       ) hcsa';

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT hcsa.account_number, hcsa.party_name, hcsa.location, hcsa.location';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY hcsa.account_number, hcsa.location ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY hcsa.account_number, hcsa.location ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_CUSTOMER_SITES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_customer_sites',
      '<input type="hidden" name="p_customer_condition" value="' || htf.escape_sc(p_customer_condition) ||'">',
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addCustomerSitesValue();',
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

  END show_lov_customer_sites;

  --==========================================================
  --Procedure Name: show_lov_trx_classes
  --Description: Display LOV for transactopn classes
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_trx_classes(
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_TRX_CLASSES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_TRX_CLASSES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_trx_class.value">');

    l_sql_rec.text(1) := 'SELECT count(al.meaning)';
    l_sql_rec.text(2) := 'FROM   ar_lookups al';
    l_sql_rec.text(3) := 'WHERE  al.lookup_type = ''INV/CM''';
    l_sql_rec.text(4) := '  AND  al.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'al', 'meaning', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(al.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT al.meaning, al.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY al.meaning ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY al.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_TRX_CLASSES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_trx_classes', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addTrxClassesValue();');

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

  END show_lov_trx_classes;

  --==========================================================
  --Procedure Name: show_lov_trx_types
  --Description: Display LOV for transactopn types
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_trx_types(
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_TRX_TYPES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_TRX_TYPES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_trx_type.value">');

    l_sql_rec.text(1) := 'SELECT count(rctt.cust_trx_type_id)';
    l_sql_rec.text(2) := 'FROM   ra_cust_trx_types rctt';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'WHERE (';
        xgv_common.get_where_clause(
          l_sql_rec, 'rctt', 'name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'WHERE upper(rctt.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT rctt.name, rctt.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY rctt.name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY rctt.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_TRX_TYPES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_trx_types', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addTrxTypesValue();');

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

  END show_lov_trx_types;

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
    xgv_common.write_access_log('RIQ.SHOW_LOV_TERMS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_TERMS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_term.value">');

    l_sql_rec.text(1) := 'SELECT count(rt.term_id)';
    l_sql_rec.text(2) := 'FROM   ra_terms rt';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'WHERE (';
        xgv_common.get_where_clause(
          l_sql_rec, 'rt', 'name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'WHERE upper(rt.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT rt.name, rt.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY rt.name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY rt.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_TERMS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_terms', NULL,
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_PAY_METHODS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_PAY_METHODS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_payment_method.value">');

    l_sql_rec.text(1) := 'SELECT count(arm.receipt_method_id)';
    l_sql_rec.text(2) := 'FROM   ar_receipt_methods arm';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'WHERE (';
        xgv_common.get_where_clause(
          l_sql_rec, 'arm', 'name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'WHERE upper(arm.name) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT arm.name, arm.name';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY arm.name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY arm.name ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_PAY_METHODS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_pay_methods', NULL,
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_SOURCES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_SOURCES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_source.value">');

    l_sql_rec.text(1) := 'SELECT count(rbs.batch_source_id)';
    l_sql_rec.text(2) := 'FROM   ra_batch_sources rbs';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'WHERE (';
        xgv_common.get_where_clause(
          l_sql_rec, 'rbs', 'name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'WHERE upper(rbs.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT rbs.name, rbs.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY rbs.name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY rbs.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_SOURCES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_sources', NULL,
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_BATCHES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_BATCHES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_batch.value">');

    l_sql_rec.text(1) := 'SELECT count(rb.batch_id)';
    l_sql_rec.text(2) := 'FROM   ra_batches rb';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'WHERE (';
        xgv_common.get_where_clause(
          l_sql_rec, 'rb', 'name', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'WHERE upper(rb.name) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT rb.name, rb.name';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY rb.name ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY rb.name ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_BATCHES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_batches', NULL,
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_H_DFF');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
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
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_h_dff',
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
  --Procedure Name: show_lov_line_types
  --Description: Display LOV for line types
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_line_types(
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_LINE_TYPES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_LINE_TYPES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_trx_class.value">');

    l_sql_rec.text(1) := 'SELECT count(al.meaning)';
    l_sql_rec.text(2) := 'FROM   ar_lookups al';
    l_sql_rec.text(3) := 'WHERE  al.lookup_type = ''STD_LINE_TYPE''';
    l_sql_rec.text(4) := '  AND  al.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'al', 'meaning', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(al.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT al.meaning, al.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY al.meaning ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY al.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_LINE_TYPES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_line_types', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addLineTypesValue();');

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

  END show_lov_line_types;

  --==========================================================
  --Procedure Name: show_lov_line_items
  --Description: Display LOV for line items
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_line_items(
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_LINE_ITEMS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_LINE_ITEMS') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_line_item.value">');

    l_sql_rec.text(1) := 'SELECT count(msiv.inventory_item_id)';
    l_sql_rec.text(2) := 'FROM   mtl_system_items_vl msiv';
    l_sql_rec.text(3) := 'WHERE  msiv.organization_id = xgv_common.get_org_id';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'msiv', 'segment1', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(msiv.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT msiv.segment1, msiv.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY msiv.segment1 ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY msiv.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_LINE_ITEMS', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_line_items', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addLineItemsValue();');

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

  END show_lov_line_items;

  --==========================================================
  --Procedure Name: show_lov_dist_classes
  --Description: Display LOV for line types
  --Note:
  --Parameter(s):
  --  p_list_filter_item : Filter item for list(VALUE/DESCRIPTION)
  --  p_list_filter_value: Filter value for list
  --  p_start_listno     : Start list no
  --  p_sort_item        : Sort item(VALUE/DESCRIPTION)
  --  p_sort_method      : Sort method(ASC/DESC)
  --==========================================================
  PROCEDURE show_lov_dist_classes(
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_DIST_CLASSES');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
    htp.p('<title>' || xgv_common.get_message('TITLE_LOV_RI_DIST_CLASSES') || '</title>');
    htp.p('</head>');

    htp.p('<body class="OraBody" onLoad="window.focus();'
      ||  ' document.f_select_value.p_select_values.disabled=true;'
      ||  ' document.f_select_value.p_select_values.value=window.opener.document.f_query.p_dist_class.value">');

    l_sql_rec.text(1) := 'SELECT count(al.meaning)';
    l_sql_rec.text(2) := 'FROM   ar_lookups al';
    l_sql_rec.text(3) := 'WHERE  al.lookup_type = ''AUTOGL_TYPE''';
    l_sql_rec.text(4) := '  AND  al.enabled_flag = ''Y''';

    IF  p_list_filter_value IS NOT NULL
    THEN
      IF  p_list_filter_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '  AND (';
        xgv_common.get_where_clause(
          l_sql_rec, 'al', 'meaning', p_list_filter_value);
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := ')';

      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_list_filter_value));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          '  AND upper(al.description) LIKE :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
    END IF;

    xgv_common.get_plain_sql_statement(l_count_sql, l_sql_rec);

    l_sql_rec.text(1) := 'SELECT al.meaning, al.description';
    IF  p_sort_item = 'VALUE'
    THEN
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY al.meaning ' || p_sort_method;
    ELSE
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY al.description ' || p_sort_method;
    END IF;

    xgv_common.get_plain_sql_statement(l_list_sql, l_sql_rec);

    xgv_common.show_multiselect_lov(
      'TITLE_LOV_RI_DIST_CLASSES', NULL,
      l_count_sql,
      l_list_sql,
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_dist_classes', NULL,
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addDistClassesValue();');

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

  END show_lov_dist_classes;

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
    xgv_common.write_access_log('RIQ.SHOW_LOV_AFF');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
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
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_aff',
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
  --Procedure Name: show_lov_d_dff
  --Description: Display LOV for distribution DFF
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
  PROCEDURE show_lov_d_dff(
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
    xgv_common.write_access_log('RIQ.SHOW_LOV_D_DFF');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
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
      p_list_filter_item, p_list_filter_value, './xgv_riq.show_lov_d_dff',
        '<input type="hidden" name="p_child_segment_id" value="' || p_child_segment_id || '">'
        || '<input type="hidden" name="p_parent_segment_id" value="' || p_parent_segment_id || '">'
        || '<input type="hidden" name="p_parent_condition" value="' || htf.escape_sc(p_parent_condition) || '">',
      p_start_listno, p_sort_item, p_sort_method,
      p_copyfunction=>'javascript:addD_DFFValue(' || to_char(p_child_segment_id) || ');',
      p_used_parent_value=>TRUE);

    htp.p('</body>');

    htp.p('</html>');

    htp.p('<script language="JavaScript">');
    htp.p('<!--  ');
    htp.p('function setSelectValue()');
    htp.p('{');
    htp.p('  if (isNaN(window.opener.document.f_query.p_d_dff_condition.length))');
    htp.p('  { document.f_select_value.p_select_values.value=window.opener.document.f_query.p_d_dff_condition.value; }');
    htp.p('  else');
    htp.p('  { document.f_select_value.p_select_values.value=window.opener.document.f_query.p_d_dff_condition['
      ||  to_char(p_child_segment_id) || ' - window.opener.document.f_information.p_1st_d_dff_segment_id.value].value; }');
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

  END show_lov_d_dff;

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
  --  p_cust              : Customer name
  --  p_cust_site         : Customer site name
  --  p_trx_date_from     : Transaction date(From)
  --  p_trx_date_to       : Transaction date(To)
  --  p_trx_class         : Transaction class
  --  p_trx_type          : Transaction type
  --  p_receipt           : Status(receipt)
  --  p_partreceipt       : Status(no receipt, or part receipt)
  --  p_posted            : Posted status(posted)
  --  p_unposted          : Posted status(unposted)
  --  p_partposted        : Posted status(partially posted)
  --  p_complete          : Complete status(complete)
  --  p_uncomplete        : Complete status(uncomplete)
  --  p_printcount_zero   : Print count(zero)
  --  p_printcount_one    : Print count(one more than)
  --  p_batch_inv_num     : Batch invoice number
  --  p_inv_num           : Invoice number
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_inv_amount_from   : Invoice amount(From)
  --  p_inv_amount_to     : Invoice amount(To)
  --  p_due_date_from     : Term due date(From)
  --  p_due_date_to       : Term due date(To)
  --  p_term              : Term
  --  p_payment_method    : Payment method
  --  p_header_description: Transaction header description
  --  p_source            : Transaction source
  --  p_batch             : Transaction batch
  --  p_h_dff_condition   : Segment condition of transaction header dff
  --  p_line_type         : Invoice line type
  --  p_line_item         : Invoice line item name
  --  p_line_description  : Invoice line description
  --  p_dist_class        : Transaction distribution class
  --  p_gl_date_from      : General Ledger date(From)
  --  p_gl_date_to        : General Ledger date(To)
  --  p_aff_condition     : Segment condition of transaction distribution aff
  --  p_d_dff_condition   : Segment condition of transaction distribution dff
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
  PROCEDURE request_async_exec(
    p_mode               IN VARCHAR2 DEFAULT NULL,
    p_modify_flag        IN VARCHAR2 DEFAULT 'N',
    p_query_id           IN NUMBER   DEFAULT NULL,
    p_query_name         IN VARCHAR2 DEFAULT NULL,
    p_show_header_line   IN VARCHAR2 DEFAULT 'N',
    p_cust               IN VARCHAR2 DEFAULT NULL,
    p_cust_site          IN VARCHAR2 DEFAULT NULL,
    p_trx_date_from      IN VARCHAR2 DEFAULT NULL,
    p_trx_date_to        IN VARCHAR2 DEFAULT NULL,
    p_trx_class          IN VARCHAR2 DEFAULT NULL,
    p_trx_type           IN VARCHAR2 DEFAULT NULL,
    p_receipt            IN VARCHAR2 DEFAULT 'N',
    p_partreceipt        IN VARCHAR2 DEFAULT 'N',
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_partposted         IN VARCHAR2 DEFAULT 'N',
    p_complete           IN VARCHAR2 DEFAULT 'N',
    p_uncomplete         IN VARCHAR2 DEFAULT 'N',
    p_printcount_zero    IN VARCHAR2 DEFAULT 'N',
    p_printcount_one     IN VARCHAR2 DEFAULT 'N',
    p_batch_inv_num      IN VARCHAR2 DEFAULT NULL,
    p_inv_num            IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_inv_amount_from    IN NUMBER   DEFAULT NULL,
    p_inv_amount_to      IN NUMBER   DEFAULT NULL,
    p_due_date_from      IN VARCHAR2 DEFAULT NULL,
    p_due_date_to        IN VARCHAR2 DEFAULT NULL,
    p_term               IN VARCHAR2 DEFAULT NULL,
    p_payment_method     IN VARCHAR2 DEFAULT NULL,
    p_header_description IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_h_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_line_type          IN VARCHAR2 DEFAULT NULL,
    p_line_item          IN VARCHAR2 DEFAULT NULL,
    p_line_description   IN VARCHAR2 DEFAULT NULL,
    p_dist_class         IN VARCHAR2 DEFAULT NULL,
    p_gl_date_from       IN VARCHAR2 DEFAULT NULL,
    p_gl_date_to         IN VARCHAR2 DEFAULT NULL,
    p_aff_condition      IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_d_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
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
    xgv_common.write_access_log('RIQ.REQUEST_ASYNC_EXEC');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
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
      xgv_common.get_tabs_tag('RIQ'));

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

    htp.p('<form name="f_submitasync" method="post" action="./xgv_rie.submit_request_async_exec">');
    htp.p('<input type="hidden" name="p_execute_time" value="">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_show_header_line" value="' || p_show_header_line || '">');
    htp.p('<input type="hidden" name="p_cust" value="' || htf.escape_sc(p_cust) || '">');
    htp.p('<input type="hidden" name="p_cust_site" value="' || htf.escape_sc(p_cust_site) || '">');
    htp.p('<input type="hidden" name="p_trx_date_from" value="' || p_trx_date_from || '">');
    htp.p('<input type="hidden" name="p_trx_date_to" value="' || p_trx_date_to || '">');
    htp.p('<input type="hidden" name="p_trx_class" value="' || htf.escape_sc(p_trx_class) || '">');
    htp.p('<input type="hidden" name="p_trx_type" value="' || htf.escape_sc(p_trx_type) || '">');
    htp.p('<input type="hidden" name="p_receipt" value="' || p_receipt || '">');
    htp.p('<input type="hidden" name="p_partreceipt" value="' || p_partreceipt || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_partposted" value="' || p_partposted || '">');
    htp.p('<input type="hidden" name="p_complete" value="' || p_complete || '">');
    htp.p('<input type="hidden" name="p_uncomplete" value="' || p_uncomplete || '">');
    htp.p('<input type="hidden" name="p_printcount_zero" value="' || p_printcount_zero || '">');
    htp.p('<input type="hidden" name="p_printcount_one" value="' || p_printcount_one || '">');
    htp.p('<input type="hidden" name="p_batch_inv_num" value="' || htf.escape_sc(p_batch_inv_num) || '">');
    htp.p('<input type="hidden" name="p_inv_num" value="' || htf.escape_sc(p_inv_num) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || to_char(p_doc_seq_from) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || to_char(p_doc_seq_to) || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_inv_amount_from" value="' || to_char(p_inv_amount_from) || '">');
    htp.p('<input type="hidden" name="p_inv_amount_to" value="' || to_char(p_inv_amount_to) || '">');
    htp.p('<input type="hidden" name="p_due_date_from" value="' || p_due_date_from || '">');
    htp.p('<input type="hidden" name="p_due_date_to" value="' || p_due_date_to || '">');
    htp.p('<input type="hidden" name="p_term" value="' || htf.escape_sc(p_term) || '">');
    htp.p('<input type="hidden" name="p_payment_method" value="' || htf.escape_sc(p_payment_method) || '">');
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    FOR  l_index IN 1..p_h_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_h_dff_condition" value="' || htf.escape_sc(p_h_dff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_line_type" value="' || htf.escape_sc(p_line_type) || '">');
    htp.p('<input type="hidden" name="p_line_item" value="' || htf.escape_sc(p_line_item) || '">');
    htp.p('<input type="hidden" name="p_line_description" value="' || htf.escape_sc(p_line_description) || '">');
    htp.p('<input type="hidden" name="p_dist_class" value="' || htf.escape_sc(p_dist_class) || '">');
    htp.p('<input type="hidden" name="p_gl_date_from" value="' || p_gl_date_from || '">');
    htp.p('<input type="hidden" name="p_gl_date_to" value="' || p_gl_date_to || '">');
    FOR  l_index IN 1..p_aff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_aff_condition" value="' || htf.escape_sc(p_aff_condition(l_index)) || '">');
    END LOOP;
    FOR  l_index IN 1..p_d_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_d_dff_condition" value="' || htf.escape_sc(p_d_dff_condition(l_index)) || '">');
    END LOOP;
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

    htp.p('<form name="f_cancelasync" method="post" action="./xgv_riq.top">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || p_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_show_header_line" value="' || p_show_header_line || '">');
    htp.p('<input type="hidden" name="p_cust" value="' || htf.escape_sc(p_cust) || '">');
    htp.p('<input type="hidden" name="p_cust_site" value="' || htf.escape_sc(p_cust_site) || '">');
    htp.p('<input type="hidden" name="p_trx_date_from" value="' || p_trx_date_from || '">');
    htp.p('<input type="hidden" name="p_trx_date_to" value="' || p_trx_date_to || '">');
    htp.p('<input type="hidden" name="p_trx_class" value="' || htf.escape_sc(p_trx_class) || '">');
    htp.p('<input type="hidden" name="p_trx_type" value="' || htf.escape_sc(p_trx_type) || '">');
    htp.p('<input type="hidden" name="p_receipt" value="' || p_receipt || '">');
    htp.p('<input type="hidden" name="p_partreceipt" value="' || p_partreceipt || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_partposted" value="' || p_partposted || '">');
    htp.p('<input type="hidden" name="p_complete" value="' || p_complete || '">');
    htp.p('<input type="hidden" name="p_uncomplete" value="' || p_uncomplete || '">');
    htp.p('<input type="hidden" name="p_printcount_zero" value="' || p_printcount_zero || '">');
    htp.p('<input type="hidden" name="p_printcount_one" value="' || p_printcount_one || '">');
    htp.p('<input type="hidden" name="p_batch_inv_num" value="' || htf.escape_sc(p_batch_inv_num) || '">');
    htp.p('<input type="hidden" name="p_inv_num" value="' || htf.escape_sc(p_inv_num) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || to_char(p_doc_seq_from) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || to_char(p_doc_seq_to) || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_inv_amount_from" value="' || to_char(p_inv_amount_from) || '">');
    htp.p('<input type="hidden" name="p_inv_amount_to" value="' || to_char(p_inv_amount_to) || '">');
    htp.p('<input type="hidden" name="p_due_date_from" value="' || p_due_date_from || '">');
    htp.p('<input type="hidden" name="p_due_date_to" value="' || p_due_date_to || '">');
    htp.p('<input type="hidden" name="p_term" value="' || htf.escape_sc(p_term) || '">');
    htp.p('<input type="hidden" name="p_payment_method" value="' || htf.escape_sc(p_payment_method) || '">');
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    FOR  l_index IN 1..p_h_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_h_dff_condition" value="' || htf.escape_sc(p_h_dff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_line_type" value="' || htf.escape_sc(p_line_type) || '">');
    htp.p('<input type="hidden" name="p_line_item" value="' || htf.escape_sc(p_line_item) || '">');
    htp.p('<input type="hidden" name="p_line_description" value="' || htf.escape_sc(p_line_description) || '">');
    htp.p('<input type="hidden" name="p_dist_class" value="' || htf.escape_sc(p_dist_class) || '">');
    htp.p('<input type="hidden" name="p_gl_date_from" value="' || p_gl_date_from || '">');
    htp.p('<input type="hidden" name="p_gl_date_to" value="' || p_gl_date_to || '">');
    FOR  l_index IN 1..p_aff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_aff_condition" value="' || htf.escape_sc(p_aff_condition(l_index)) || '">');
    END LOOP;
    FOR  l_index IN 1..p_d_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_d_dff_condition" value="' || htf.escape_sc(p_d_dff_condition(l_index)) || '">');
    END LOOP;
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
    xgv_common.write_access_log('RIQ.LIST_CONDITIONS');

    htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    htp.p('<html dir="ltr">');

    htp.p('<head>');
    htp.p('<meta http-equiv="Content-Type" content="text/html; charset=' || xgv_common.get_char_set_name || '">');
    htp.p('<link rel="stylesheet" type="text/css" href="/XGV_HTML/style.css">');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_COMMON.js"></script>');
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
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
      xgv_common.get_tabs_tag('RIQ'));

    htp.p('<table border="0" cellpadding="0" cellspacing="0">');
    htp.p('<tr style="vertical-align: top">');

    -- Display side navigator
    htp.p('<td>');
    show_side_navigator('OPEN');
    htp.p('</td>');

    -- Display list for query condition
    htp.p('<td width="100%">');

    xgv_common.list_conditions(p_mode, 'RI',
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
    p_ri_invoice_query_rec IN  xgv_common.ar_invoice_query_rtype,
    p_save_mode            IN  VARCHAR2,
    p_save_category        IN  VARCHAR2,
    p_message_type         OUT VARCHAR2,
    p_message_id           OUT VARCHAR2)
  RETURN NUMBER
  IS

    l_query_id  xgv_queries.query_id%TYPE := p_ri_invoice_query_rec.query_id;
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
        WHERE  xq.query_name = p_ri_invoice_query_rec.query_name
          AND  xq.inquiry_type = 'RI'
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
              l_query_id, p_ri_invoice_query_rec.query_name, 'RI',
              xgv_common.get_sob_id,
              decode(p_save_category, 'R', xgv_common.get_resp_appl_id, NULL),
              decode(p_save_category, 'R', xgv_common.get_resp_id, NULL),
              decode(p_save_category, 'U', xgv_common.get_user_id, NULL),
              p_ri_invoice_query_rec.result_format, p_ri_invoice_query_rec.file_name,
              p_ri_invoice_query_rec.description,
              sysdate, xgv_common.get_user_id, sysdate, xgv_common.get_user_id);

            -- Subtotal Item
            insert_condition_data(l_query_id, 'BREAKKEY', NULL, NULL, NULL,
              p_ri_invoice_query_rec.break_key);
            -- Display Subtotal Only
            insert_condition_data(l_query_id, 'SUBTOTAL', NULL, NULL, NULL,
              p_ri_invoice_query_rec.show_subtotalonly);
            -- Display Total
            insert_condition_data(l_query_id, 'TOTAL', NULL, NULL, NULL,
              p_ri_invoice_query_rec.show_total);
            -- Display bring forward line
            insert_condition_data(l_query_id, 'BRGFORWARD', NULL, NULL, NULL,
              p_ri_invoice_query_rec.show_bringforward);

            FOR  l_index IN 1..p_ri_invoice_query_rec.segment_type_tab.COUNT
            LOOP

              -- Transaction Date
              IF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'TRXP'
              THEN
                IF  xgv_common.is_date(p_ri_invoice_query_rec.trx_date_from)
                THEN
                  l_date := to_char(to_date(p_ri_invoice_query_rec.trx_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_ri_invoice_query_rec.trx_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_ri_invoice_query_rec.trx_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_ri_invoice_query_rec.trx_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_ri_invoice_query_rec.trx_date_to;
                END IF;
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Status
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'APPSTATUS'
              THEN
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_ri_invoice_query_rec.app_status);

              -- Posted status
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
              THEN
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_ri_invoice_query_rec.post_status);

              -- Complete status
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'COMPSTATUS'
              THEN
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_ri_invoice_query_rec.comp_status);

              -- Print count
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PRINTCOUNT'
              THEN
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_ri_invoice_query_rec.print_count);

              -- Document Sequence Number
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ARDOCNUM'
              THEN
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  to_char(p_ri_invoice_query_rec.doc_seq_from)
                  || ',' || to_char(p_ri_invoice_query_rec.doc_seq_to));

              -- Invoice Amount
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'INVAMOUNT'
              THEN
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  to_char(p_ri_invoice_query_rec.inv_amount_from)
                  || ',' || to_char(p_ri_invoice_query_rec.inv_amount_to));

              -- Term Due Date
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'DUEDATE'
              THEN
                IF  xgv_common.is_date(p_ri_invoice_query_rec.due_date_from)
                THEN
                  l_date := to_char(to_date(p_ri_invoice_query_rec.due_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_ri_invoice_query_rec.due_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_ri_invoice_query_rec.due_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_ri_invoice_query_rec.due_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_ri_invoice_query_rec.due_date_to;
                END IF;
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- General Ledger date
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'GLDATE'
              THEN
                IF  xgv_common.is_date(p_ri_invoice_query_rec.gl_date_from)
                THEN
                  l_date := to_char(to_date(p_ri_invoice_query_rec.gl_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_ri_invoice_query_rec.gl_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_ri_invoice_query_rec.gl_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_ri_invoice_query_rec.gl_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_ri_invoice_query_rec.gl_date_to;
                END IF;
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Line Number(Line Type)
              -- Customer Name, Customer Site Name
              -- Transaction Class, Transaction Type
              -- Batch Invoice Number, Invoice Number
              -- Currency, Term, Payment Method
              -- Transaction Header Description, Transaction Source, Transaction Batch
              -- Invoice line Type, Invoice Line Item Name, Invoice Line Description
              -- Transaction Distribution Class
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) IN ('LINENUM',
                                                                          'CUST', 'CUSTSITE',
                                                                          'TRXCLASS', 'TRXTYPE',
                                                                          'BINVNUM', 'INVNUM',
                                                                          'INVCUR', 'TERM', 'PAYMETHOD',
                                                                          'HDESC', 'SOURCE', 'BATCH',
                                                                          'LTYPE', 'LITEM', 'LDESC',
                                                                          'DCLASS')
              THEN
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  p_ri_invoice_query_rec.condition_tab(l_index));

              -- Invoice Line Line Number
              -- Invoice Line Unit Price, Invoice Line Quantity, Invoice Line Unit Of Measure
              -- Invoice Line Amount, Invoice Line Tax Code
              -- Invoice Adjustment Number, Invoice Adjustment Recode Name
              -- Invoice Adjustment Type, Invoice Adjustment Status
              -- Invoice Adjustment Amount, Invoice Adjustment Line Amount,
              -- Invoice Adjustment Tax, Invoice Distribution Line Number,
              -- Invoice Distribution Other Line Number, Invoice Distribution Amount,
              -- Payment Schedule Number, Payment Schedule Sequence Number,
              -- Payment Schedule Due Date, Payment Schedule Currency,
              -- Payment Schedule Original Amount, Payment Schedule Amount Remaining,
              -- Payment Schedule Applied Amount, Payment Schedule GL Posted Date,
              -- Payment Schedule Paid Date
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) IN ('LLINENUM',
                                                                          'LUPRICE', 'LQTY', 'LUOM',
                                                                          'LAMOUNT', 'LTAXCODE',
                                                                          'ADJNUM', 'ADJRECNAME',
                                                                          'ADJTYPE', 'ADJSTATUS',
                                                                          'ADJAMOUNT', 'ADJLAMOUNT',
                                                                          'ADJTAX', 'DLINENUM',
                                                                          'DOLINENUM', 'DAMOUNT',
                                                                          'PNUM', 'PSEQNUM',
                                                                          'PDUEDATE', 'PCUR',
                                                                          'PORGAMOUNT', 'PREMAMOUNT',
                                                                          'PAPPAMOUNT', 'PGLDATE',
                                                                          'PPAIDDATE')
              THEN
                insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  NULL);

              -- AFF
              -- DFF of "Transaction Information"
              -- DFF of "Invoice Line Information"
              -- DFF of "Line Distribution Information"
              ELSIF  xgv_common.is_number(p_ri_invoice_query_rec.segment_type_tab(l_index))
              THEN
                IF  xgv_common.get_flexfield_name(to_number(p_ri_invoice_query_rec.segment_type_tab(l_index))) IN ('RA_CUSTOMER_TRX',
                                                                                                                   'GL#',
                                                                                                                   'RA_CUST_TRX_LINE_GL_DIST')
                THEN
                  insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                    p_ri_invoice_query_rec.show_order_tab(l_index),
                    p_ri_invoice_query_rec.sort_order_tab(l_index),
                    NULL,
                    p_ri_invoice_query_rec.condition_tab(l_index));

                ELSIF  xgv_common.get_flexfield_name(to_number(p_ri_invoice_query_rec.segment_type_tab(l_index))) = 'RA_CUSTOMER_TRX_LINES'
                THEN
                  insert_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                    p_ri_invoice_query_rec.show_order_tab(l_index),
                    p_ri_invoice_query_rec.sort_order_tab(l_index),
                    NULL,
                    NULL);
                END IF;
              END IF;

            END LOOP;

            p_message_type := 'C';
          EXCEPTION
            WHEN  OTHERS
            THEN
              ROLLBACK;

              l_query_id := p_ri_invoice_query_rec.query_id;
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
        IF  p_ri_invoice_query_rec.created_by != xgv_common.get_user_id
        THEN
          RAISE e_invalid_authority;
        END IF;

        SELECT xq.query_name
        INTO   l_dummy
        FROM   xgv_queries xq
        WHERE  xq.query_id != l_query_id
          AND  xq.query_name = p_ri_invoice_query_rec.query_name
          AND  xq.inquiry_type = 'RI'    /* Bug#212010 07-Dec-2005 Changed by ytsujiha_jp */
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
            SET    query_name = p_ri_invoice_query_rec.query_name,
                   application_id = decode(p_save_category, 'R', xgv_common.get_resp_appl_id, NULL),
                   responsibility_id = decode(p_save_category, 'R', xgv_common.get_resp_id, NULL),
                   user_id = decode(p_save_category, 'U', xgv_common.get_user_id, NULL),
                   result_format = p_ri_invoice_query_rec.result_format,
                   file_name = p_ri_invoice_query_rec.file_name,
                   description = p_ri_invoice_query_rec.description,
                   last_update_date = sysdate,
                   last_updated_by = xgv_common.get_user_id
            WHERE  query_id = l_query_id;

            -- Subtotal Item
            update_condition_data(l_query_id, 'BREAKKEY', NULL, NULL, NULL,
              p_ri_invoice_query_rec.break_key);
            -- Display Subtotal Only
            update_condition_data(l_query_id, 'SUBTOTAL', NULL, NULL, NULL,
              p_ri_invoice_query_rec.show_subtotalonly);
            -- Display Total
            update_condition_data(l_query_id, 'TOTAL', NULL, NULL, NULL,
              p_ri_invoice_query_rec.show_total);
            -- Display bring forward line
            update_condition_data(l_query_id, 'BRGFORWARD', NULL, NULL, NULL,
              p_ri_invoice_query_rec.show_bringforward);

            FOR  l_index IN 1..p_ri_invoice_query_rec.segment_type_tab.COUNT
            LOOP

              -- Transaction Date
              IF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'TRXP'
              THEN
                IF  xgv_common.is_date(p_ri_invoice_query_rec.trx_date_from)
                THEN
                  l_date := to_char(to_date(p_ri_invoice_query_rec.trx_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_ri_invoice_query_rec.trx_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_ri_invoice_query_rec.trx_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_ri_invoice_query_rec.trx_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_ri_invoice_query_rec.trx_date_to;
                END IF;
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Status
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'APPSTATUS'
              THEN
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_ri_invoice_query_rec.app_status);

              -- Posted status
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'POSTSTATUS'
              THEN
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_ri_invoice_query_rec.post_status);

              -- Complete status
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'COMPSTATUS'
              THEN
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_ri_invoice_query_rec.comp_status);

              -- Print count
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'PRINTCOUNT'
              THEN
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  NULL,
                  p_ri_invoice_query_rec.print_count);

              -- Document Sequence Number
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'ARDOCNUM'
              THEN
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  to_char(p_ri_invoice_query_rec.doc_seq_from)
                  || ',' || to_char(p_ri_invoice_query_rec.doc_seq_to));

              -- Invoice Amount
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'INVAMOUNT'
              THEN
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  to_char(p_ri_invoice_query_rec.inv_amount_from)
                  || ',' || to_char(p_ri_invoice_query_rec.inv_amount_to));

              -- Term Due Date
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'DUEDATE'
              THEN
                IF  xgv_common.is_date(p_ri_invoice_query_rec.due_date_from)
                THEN
                  l_date := to_char(to_date(p_ri_invoice_query_rec.due_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_ri_invoice_query_rec.due_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_ri_invoice_query_rec.due_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_ri_invoice_query_rec.due_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_ri_invoice_query_rec.due_date_to;
                END IF;
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- General Ledger date
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) = 'GLDATE'
              THEN
                IF  xgv_common.is_date(p_ri_invoice_query_rec.gl_date_from)
                THEN
                  l_date := to_char(to_date(p_ri_invoice_query_rec.gl_date_from), 'RRRRMMDD') || ',';
                ELSE
                  l_date := p_ri_invoice_query_rec.gl_date_from || ',';
                END IF;
                IF  xgv_common.is_date(p_ri_invoice_query_rec.gl_date_to)
                THEN
                  l_date := l_date || to_char(to_date(p_ri_invoice_query_rec.gl_date_to), 'RRRRMMDD');
                ELSE
                  l_date := l_date || p_ri_invoice_query_rec.gl_date_to;
                END IF;
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  l_date);

              -- Line Number(Line Type)
              -- Customer Name, Customer Site Name
              -- Transaction Class, Transaction Type
              -- Batch Invoice Number, Invoice Number
              -- Currency, Term, Payment Method
              -- Transaction Header Description, Transaction Source, Transaction Batch
              -- Invoice line Type, Invoice Line Item Name, Invoice Line Description
              -- Transaction Distribution Class
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) IN ('LINENUM',
                                                                          'CUST', 'CUSTSITE',
                                                                          'TRXCLASS', 'TRXTYPE',
                                                                          'BINVNUM', 'INVNUM',
                                                                          'INVCUR', 'TERM', 'PAYMETHOD',
                                                                          'HDESC', 'SOURCE', 'BATCH',
                                                                          'LTYPE', 'LITEM', 'LDESC',
                                                                          'DCLASS')
              THEN
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  p_ri_invoice_query_rec.condition_tab(l_index));

              -- Invoice Line Line Number
              -- Invoice Line Unit Price, Invoice Line Quantity, Invoice Line Unit Of Measure
              -- Invoice Line Amount, Invoice Line Tax Code
              -- Invoice Adjustment Number, Invoice Adjustment Recode Name
              -- Invoice Adjustment Type, Invoice Adjustment Status
              -- Invoice Adjustment Amount, Invoice Adjustment Line Amount,
              -- Invoice Adjustment Tax, Invoice Distribution Line Number,
              -- Invoice Distribution Other Line Number, Invoice Distribution Amount,
              -- Payment Schedule Number, Payment Schedule Sequence Number,
              -- Payment Schedule Due Date, Payment Schedule Currency,
              -- Payment Schedule Original Amount, Payment Schedule Amount Remaining,
              -- Payment Schedule Applied Amount, Payment Schedule GL Posted Date,
              -- Payment Schedule Paid Date
              ELSIF  p_ri_invoice_query_rec.segment_type_tab(l_index) IN ('LLINENUM',
                                                                          'LUPRICE', 'LQTY', 'LUOM',
                                                                          'LAMOUNT', 'LTAXCODE',
                                                                          'ADJNUM', 'ADJRECNAME',
                                                                          'ADJTYPE', 'ADJSTATUS',
                                                                          'ADJAMOUNT', 'ADJLAMOUNT',
                                                                          'ADJTAX', 'DLINENUM',
                                                                          'DOLINENUM', 'DAMOUNT',
                                                                          'PNUM', 'PSEQNUM',
                                                                          'PDUEDATE', 'PCUR',
                                                                          'PORGAMOUNT', 'PREMAMOUNT',
                                                                          'PAPPAMOUNT', 'PGLDATE',
                                                                          'PPAIDDATE')
              THEN
                update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                  p_ri_invoice_query_rec.show_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_order_tab(l_index),
                  p_ri_invoice_query_rec.sort_method_tab(l_index),
                  NULL);

              -- AFF
              -- DFF of "Transaction Information"
              -- DFF of "Invoice Line Information"
              -- DFF of "Line Distribution Information"
              ELSIF  xgv_common.is_number(p_ri_invoice_query_rec.segment_type_tab(l_index))
              THEN
                IF  xgv_common.get_flexfield_name(to_number(p_ri_invoice_query_rec.segment_type_tab(l_index))) IN ('RA_CUSTOMER_TRX',
                                                                                                                   'GL#',
                                                                                                                   'RA_CUST_TRX_LINE_GL_DIST')
                THEN
                  update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                    p_ri_invoice_query_rec.show_order_tab(l_index),
                    p_ri_invoice_query_rec.sort_order_tab(l_index),
                    NULL,
                    p_ri_invoice_query_rec.condition_tab(l_index));

                ELSIF  xgv_common.get_flexfield_name(to_number(p_ri_invoice_query_rec.segment_type_tab(l_index))) = 'RA_CUSTOMER_TRX_LINES'
                THEN
                  update_condition_data(l_query_id, p_ri_invoice_query_rec.segment_type_tab(l_index),
                    p_ri_invoice_query_rec.show_order_tab(l_index),
                    p_ri_invoice_query_rec.sort_order_tab(l_index),
                    NULL,
                    NULL);
                END IF;
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
  --  p_cust              : Customer name
  --  p_cust_site         : Customer site name
  --  p_trx_date_from     : Transaction date(From)
  --  p_trx_date_to       : Transaction date(To)
  --  p_trx_class         : Transaction class
  --  p_trx_type          : Transaction type
  --  p_receipt           : Status(receipt)
  --  p_partreceipt       : Status(no receipt, or part receipt)
  --  p_posted            : Posted status(posted)
  --  p_unposted          : Posted status(unposted)
  --  p_partposted        : Posted status(partially posted)
  --  p_complete          : Complete status(complete)
  --  p_uncomplete        : Complete status(uncomplete)
  --  p_printcount_zero   : Print count(zero)
  --  p_printcount_one    : Print count(one more than)
  --  p_batch_inv_num     : Batch invoice number
  --  p_inv_num           : Invoice number
  --  p_doc_seq_from      : Document sequence number(From)
  --  p_doc_seq_to        : Document sequence number(To)
  --  p_currency_code     : Currency
  --  p_inv_amount_from   : Invoice amount(From)
  --  p_inv_amount_to     : Invoice amount(To)
  --  p_due_date_from     : Term due date(From)
  --  p_due_date_to       : Term due date(To)
  --  p_term              : Term
  --  p_payment_method    : Payment method
  --  p_header_description: Transaction header description
  --  p_source            : Transaction source
  --  p_batch             : Transaction batch
  --  p_h_dff_condition   : Segment condition of transaction header dff
  --  p_line_type         : Invoice line type
  --  p_line_item         : Invoice line item name
  --  p_line_description  : Invoice line description
  --  p_dist_class        : Transaction distribution class
  --  p_gl_date_from      : General Ledger date(From)
  --  p_gl_date_to        : General Ledger date(To)
  --  p_aff_condition     : Segment condition of transaction distribution aff
  --  p_d_dff_condition   : Segment condition of transaction distribution dff
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
  --  p_description       : Description
  --==========================================================
  PROCEDURE save_condition(
    p_mode               IN VARCHAR2 DEFAULT 'ND',
    p_modify_flag        IN VARCHAR2 DEFAULT 'N',
    p_save_category      IN VARCHAR2 DEFAULT 'U',
    p_query_id           IN NUMBER   DEFAULT NULL,
    p_query_name         IN VARCHAR2 DEFAULT NULL,
    p_show_header_line   IN VARCHAR2 DEFAULT 'N',
    p_cust               IN VARCHAR2 DEFAULT NULL,
    p_cust_site          IN VARCHAR2 DEFAULT NULL,
    p_trx_date_from      IN VARCHAR2 DEFAULT NULL,
    p_trx_date_to        IN VARCHAR2 DEFAULT NULL,
    p_trx_class          IN VARCHAR2 DEFAULT NULL,
    p_trx_type           IN VARCHAR2 DEFAULT NULL,
    p_receipt            IN VARCHAR2 DEFAULT 'N',
    p_partreceipt        IN VARCHAR2 DEFAULT 'N',
    p_posted             IN VARCHAR2 DEFAULT 'N',
    p_unposted           IN VARCHAR2 DEFAULT 'N',
    p_partposted         IN VARCHAR2 DEFAULT 'N',
    p_complete           IN VARCHAR2 DEFAULT 'N',
    p_uncomplete         IN VARCHAR2 DEFAULT 'N',
    p_printcount_zero    IN VARCHAR2 DEFAULT 'N',
    p_printcount_one     IN VARCHAR2 DEFAULT 'N',
    p_batch_inv_num      IN VARCHAR2 DEFAULT NULL,
    p_inv_num            IN VARCHAR2 DEFAULT NULL,
    p_doc_seq_from       IN NUMBER   DEFAULT NULL,
    p_doc_seq_to         IN NUMBER   DEFAULT NULL,
    p_currency_code      IN VARCHAR2 DEFAULT NULL,
    p_inv_amount_from    IN NUMBER   DEFAULT NULL,
    p_inv_amount_to      IN NUMBER   DEFAULT NULL,
    p_due_date_from      IN VARCHAR2 DEFAULT NULL,
    p_due_date_to        IN VARCHAR2 DEFAULT NULL,
    p_term               IN VARCHAR2 DEFAULT NULL,
    p_payment_method     IN VARCHAR2 DEFAULT NULL,
    p_header_description IN VARCHAR2 DEFAULT NULL,
    p_source             IN VARCHAR2 DEFAULT NULL,
    p_batch              IN VARCHAR2 DEFAULT NULL,
    p_h_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_line_type          IN VARCHAR2 DEFAULT NULL,
    p_line_item          IN VARCHAR2 DEFAULT NULL,
    p_line_description   IN VARCHAR2 DEFAULT NULL,
    p_dist_class         IN VARCHAR2 DEFAULT NULL,
    p_gl_date_from       IN VARCHAR2 DEFAULT NULL,
    p_gl_date_to         IN VARCHAR2 DEFAULT NULL,
    p_aff_condition      IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
    p_d_dff_condition    IN xgv_common.array_ttype DEFAULT xgv_common.array_tab,
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
    l_ri_invoice_query_rec  xgv_common.ar_invoice_query_rtype;
    l_message_type  VARCHAR2(1) := NULL;
    l_message_id  VARCHAR2(255) := NULL;

  BEGIN

    -- Initialize
    xgv_common.init;

    -- Write access log
    /* 19-May-2005 Added by ytsujiha_jp */
    xgv_common.write_access_log('RIQ.SAVE_CONDITION');

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
          l_ri_invoice_query_rec, NULL,
          p_show_header_line,
          p_cust, p_cust_site, p_trx_date_from, p_trx_date_to,
          p_trx_class, p_trx_type, p_receipt, p_partreceipt,
          p_posted, p_unposted, p_partposted,
          p_complete, p_uncomplete, p_printcount_zero, p_printcount_one,
          p_batch_inv_num, p_inv_num, p_doc_seq_from, p_doc_seq_to, p_currency_code,
          p_inv_amount_from, p_inv_amount_to,
          p_due_date_from, p_due_date_to, p_term, p_payment_method,
          p_header_description, p_source, p_batch, p_h_dff_condition,
          p_line_type, p_line_item, p_line_description,
          p_dist_class, p_gl_date_from, p_gl_date_to,
          p_aff_condition, p_d_dff_condition,
          p_show_order, p_sort_order, p_sort_method, p_segment_type,
          p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
          p_result_format, p_file_name, p_description);
        l_ri_invoice_query_rec.query_id := p_query_id;

      ELSE
        set_query_condition_local(
          l_ri_invoice_query_rec, p_query_id,
          p_show_header_line,
          p_cust, p_cust_site, p_trx_date_from, p_trx_date_to,
          p_trx_class, p_trx_type, p_receipt, p_partreceipt,
          p_posted, p_unposted, p_partposted,
          p_complete, p_uncomplete, p_printcount_zero, p_printcount_one,
          p_batch_inv_num, p_inv_num, p_doc_seq_from, p_doc_seq_to, p_currency_code,
          p_inv_amount_from, p_inv_amount_to,
          p_due_date_from, p_due_date_to, p_term, p_payment_method,
          p_header_description, p_source, p_batch, p_h_dff_condition,
          p_line_type, p_line_item, p_line_description,
          p_dist_class, p_gl_date_from, p_gl_date_to,
          p_aff_condition, p_d_dff_condition,
          p_show_order, p_sort_order, p_sort_method, p_segment_type,
          p_break_key, p_show_subtotalonly, p_show_total, p_show_bringforward,
          p_result_format, p_file_name, p_description);
      END IF;

      l_ri_invoice_query_rec.query_name := p_query_name;
      l_query_id := execute_save_condition(
        l_ri_invoice_query_rec, p_mode, p_save_category, l_message_type, l_message_id);

      IF  l_message_type = 'C'
      THEN
        htp.p('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
        htp.p('<html dir="ltr">');
        htp.p('<body>');
        htp.p('<form name="f_refresh" method="post" action="./xgv_riq.top">');
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
          AND  xq.inquiry_type = 'RI';
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
    htp.p('<script language="JavaScript" src="/XGV_JS/' || xgv_common.get_lang || '/XGV_RIQ.js"></script>');
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
      xgv_common.get_tabs_tag('RIQ'));

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

    htp.p('<form name="f_savedialog" method="post" action="./xgv_riq.save_condition">');
    htp.p('<input type="hidden" name="p_mode" value="N">');
    htp.p('<input type="hidden" name="p_show_header_line" value="' || p_show_header_line || '">');
    htp.p('<input type="hidden" name="p_cust" value="' || htf.escape_sc(p_cust) || '">');
    htp.p('<input type="hidden" name="p_cust_site" value="' || htf.escape_sc(p_cust_site) || '">');
    htp.p('<input type="hidden" name="p_trx_date_from" value="' || p_trx_date_from || '">');
    htp.p('<input type="hidden" name="p_trx_date_to" value="' || p_trx_date_to || '">');
    htp.p('<input type="hidden" name="p_trx_class" value="' || htf.escape_sc(p_trx_class) || '">');
    htp.p('<input type="hidden" name="p_trx_type" value="' || htf.escape_sc(p_trx_type) || '">');
    htp.p('<input type="hidden" name="p_receipt" value="' || p_receipt || '">');
    htp.p('<input type="hidden" name="p_partreceipt" value="' || p_partreceipt || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_partposted" value="' || p_partposted || '">');
    htp.p('<input type="hidden" name="p_complete" value="' || p_complete || '">');
    htp.p('<input type="hidden" name="p_uncomplete" value="' || p_uncomplete || '">');
    htp.p('<input type="hidden" name="p_printcount_zero" value="' || p_printcount_zero || '">');
    htp.p('<input type="hidden" name="p_printcount_one" value="' || p_printcount_one || '">');
    htp.p('<input type="hidden" name="p_batch_inv_num" value="' || htf.escape_sc(p_batch_inv_num) || '">');
    htp.p('<input type="hidden" name="p_inv_num" value="' || htf.escape_sc(p_inv_num) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || to_char(p_doc_seq_from) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || to_char(p_doc_seq_to) || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_inv_amount_from" value="' || to_char(p_inv_amount_from) || '">');
    htp.p('<input type="hidden" name="p_inv_amount_to" value="' || to_char(p_inv_amount_to) || '">');
    htp.p('<input type="hidden" name="p_due_date_from" value="' || p_due_date_from || '">');
    htp.p('<input type="hidden" name="p_due_date_to" value="' || p_due_date_to || '">');
    htp.p('<input type="hidden" name="p_term" value="' || htf.escape_sc(p_term) || '">');
    htp.p('<input type="hidden" name="p_payment_method" value="' || htf.escape_sc(p_payment_method) || '">');
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    FOR  l_index IN 1..p_h_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_h_dff_condition" value="' || htf.escape_sc(p_h_dff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_line_type" value="' || htf.escape_sc(p_line_type) || '">');
    htp.p('<input type="hidden" name="p_line_item" value="' || htf.escape_sc(p_line_item) || '">');
    htp.p('<input type="hidden" name="p_line_description" value="' || htf.escape_sc(p_line_description) || '">');
    htp.p('<input type="hidden" name="p_dist_class" value="' || htf.escape_sc(p_dist_class) || '">');
    htp.p('<input type="hidden" name="p_gl_date_from" value="' || p_gl_date_from || '">');
    htp.p('<input type="hidden" name="p_gl_date_to" value="' || p_gl_date_to || '">');
    FOR  l_index IN 1..p_aff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_aff_condition" value="' || htf.escape_sc(p_aff_condition(l_index)) || '">');
    END LOOP;
    FOR  l_index IN 1..p_d_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_d_dff_condition" value="' || htf.escape_sc(p_d_dff_condition(l_index)) || '">');
    END LOOP;
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

    htp.p('<form name="f_cancelsave" method="post" action="./xgv_riq.top">');
    htp.p('<input type="hidden" name="p_mode" value="C">');
    htp.p('<input type="hidden" name="p_modify_flag" value="' || p_modify_flag || '">');  /* Bug#200022 16-Jun-2004 Added by ytsujiha_jp */
    htp.p('<input type="hidden" name="p_query_id" value="' || l_query_id || '">');
    htp.p('<input type="hidden" name="p_query_name" value="' ||  htf.escape_sc(p_query_name) || '">');
    htp.p('<input type="hidden" name="p_show_header_line" value="' || p_show_header_line || '">');
    htp.p('<input type="hidden" name="p_cust" value="' || htf.escape_sc(p_cust) || '">');
    htp.p('<input type="hidden" name="p_cust_site" value="' || htf.escape_sc(p_cust_site) || '">');
    htp.p('<input type="hidden" name="p_trx_date_from" value="' || p_trx_date_from || '">');
    htp.p('<input type="hidden" name="p_trx_date_to" value="' || p_trx_date_to || '">');
    htp.p('<input type="hidden" name="p_trx_class" value="' || htf.escape_sc(p_trx_class) || '">');
    htp.p('<input type="hidden" name="p_trx_type" value="' || htf.escape_sc(p_trx_type) || '">');
    htp.p('<input type="hidden" name="p_receipt" value="' || p_receipt || '">');
    htp.p('<input type="hidden" name="p_partreceipt" value="' || p_partreceipt || '">');
    htp.p('<input type="hidden" name="p_posted" value="' || p_posted || '">');
    htp.p('<input type="hidden" name="p_unposted" value="' || p_unposted || '">');
    htp.p('<input type="hidden" name="p_partposted" value="' || p_partposted || '">');
    htp.p('<input type="hidden" name="p_complete" value="' || p_complete || '">');
    htp.p('<input type="hidden" name="p_uncomplete" value="' || p_uncomplete || '">');
    htp.p('<input type="hidden" name="p_printcount_zero" value="' || p_printcount_zero || '">');
    htp.p('<input type="hidden" name="p_printcount_one" value="' || p_printcount_one || '">');
    htp.p('<input type="hidden" name="p_batch_inv_num" value="' || htf.escape_sc(p_batch_inv_num) || '">');
    htp.p('<input type="hidden" name="p_inv_num" value="' || htf.escape_sc(p_inv_num) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_from" value="' || to_char(p_doc_seq_from) || '">');
    htp.p('<input type="hidden" name="p_doc_seq_to" value="' || to_char(p_doc_seq_to) || '">');
    htp.p('<input type="hidden" name="p_currency_code" value="' || p_currency_code || '">');
    htp.p('<input type="hidden" name="p_inv_amount_from" value="' || to_char(p_inv_amount_from) || '">');
    htp.p('<input type="hidden" name="p_inv_amount_to" value="' || to_char(p_inv_amount_to) || '">');
    htp.p('<input type="hidden" name="p_due_date_from" value="' || p_due_date_from || '">');
    htp.p('<input type="hidden" name="p_due_date_to" value="' || p_due_date_to || '">');
    htp.p('<input type="hidden" name="p_term" value="' || htf.escape_sc(p_term) || '">');
    htp.p('<input type="hidden" name="p_payment_method" value="' || htf.escape_sc(p_payment_method) || '">');
    htp.p('<input type="hidden" name="p_header_description" value="' || htf.escape_sc(p_header_description) || '">');
    htp.p('<input type="hidden" name="p_source" value="' || htf.escape_sc(p_source) || '">');
    htp.p('<input type="hidden" name="p_batch" value="' || htf.escape_sc(p_batch) || '">');
    FOR  l_index IN 1..p_h_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_h_dff_condition" value="' || htf.escape_sc(p_h_dff_condition(l_index)) || '">');
    END LOOP;
    htp.p('<input type="hidden" name="p_line_type" value="' || htf.escape_sc(p_line_type) || '">');
    htp.p('<input type="hidden" name="p_line_item" value="' || htf.escape_sc(p_line_item) || '">');
    htp.p('<input type="hidden" name="p_line_description" value="' || htf.escape_sc(p_line_description) || '">');
    htp.p('<input type="hidden" name="p_dist_class" value="' || htf.escape_sc(p_dist_class) || '">');
    htp.p('<input type="hidden" name="p_gl_date_from" value="' || p_gl_date_from || '">');
    htp.p('<input type="hidden" name="p_gl_date_to" value="' || p_gl_date_to || '">');
    FOR  l_index IN 1..p_aff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_aff_condition" value="' || htf.escape_sc(p_aff_condition(l_index)) || '">');
    END LOOP;
    FOR  l_index IN 1..p_d_dff_condition.COUNT
    LOOP
      htp.p('<input type="hidden" name="p_d_dff_condition" value="' || htf.escape_sc(p_d_dff_condition(l_index)) || '">');
    END LOOP;
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
    xgv_common.write_access_log('RIQ.DELETE_CONDITION');

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
    htp.p('<form name="f_refresh" method="post" action="./xgv_riq.list_conditions">');
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

END xgv_riq;
/
