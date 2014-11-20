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

COMMENT ON COLUMN xxcos.xxcos_rep_order_list.invoice_class             IS '�`�[�敪';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.classification_class      IS '���ދ敪';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.report_output_type        IS '�o�͋敪';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.edi_re_output_flag        IS 'EDI�ďo�̓t���O';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.chain_code                IS '�`�F�[���X�R�[�h';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.chain_name                IS '�`�F�[���X����';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.order_creation_date_from  IS '��M��(FROM)';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.order_creation_date_to    IS '��M��(TO)';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.dlv_date_header_from      IS '�[�i��(�w�b�_)(FROM)';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.dlv_date_header_to        IS '�[�i��(�w�b�_)(TO)';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.record_type               IS '���R�[�h�^�C�v';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.order_amount_total        IS '�󒍋��z���v';
COMMENT ON COLUMN xxcos.xxcos_rep_order_list.dlv_date_header           IS '�[�i��(�w�b�_)';
