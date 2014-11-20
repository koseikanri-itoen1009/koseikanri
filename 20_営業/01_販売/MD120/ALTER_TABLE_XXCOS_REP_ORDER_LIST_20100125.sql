ALTER TABLE xxcos.xxcos_rep_order_list  ADD (
  invoice_class             VARCHAR2(2),
  classification_class      VARCHAR2(4),
  report_output_type        VARCHAR2(10),
  edi_re_output_flag        VARCHAR2(1),
  chain_code                VARCHAR2(4),
  chain_name                VARCHAR2(360),
  order_creation_date_from  DATE,
  order_creation_date_to    DATE,
  dlv_date_header_from      DATE,
  dlv_date_header_to        DATE,
  record_type               NUMBER,
  order_amount_total        NUMBER,
  dlv_date_header           DATE
);

COMMENT ON COLUMN xxcos.xxcos_rep_order_list.invoice_class             IS '伝票区分';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.classification_class      IS '分類区分';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.report_output_type        IS '出力区分';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.edi_re_output_flag        IS 'EDI再出力フラグ';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.chain_code                IS 'チェーン店コード';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.chain_name                IS 'チェーン店名称';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.order_creation_date_from  IS '受信日(FROM)';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.order_creation_date_to    IS '受信日(TO)';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.dlv_date_header_from      IS '納品日(ヘッダ)(FROM)';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.dlv_date_header_to        IS '納品日(ヘッダ)(TO)';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.record_type               IS 'レコードタイプ';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.order_amount_total        IS '受注金額合計';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.dlv_date_header           IS '納品日(ヘッダ)';
