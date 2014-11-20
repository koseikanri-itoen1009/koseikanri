CREATE OR REPLACE VIEW APPS.XXCSM_SALES_EXP_HEADERS_V
(
  sales_exp_header_id,
  dlv_invoice_number,
  order_invoice_number,
  order_number,
  order_no_hht,
  digestion_ln_number,
  order_connection_number,
  dlv_invoice_class,
  cancel_correct_class,
  input_class,
  cust_gyotai_sho,
  delivery_date,
  orig_delivery_date,
  inspect_date,
  orig_inspect_date,
  ship_to_customer_code,
  sale_amount_sum,
  pure_amount_sum,
  tax_amount_sum,
  consumption_tax_class,
  tax_code,
  tax_rate,
  results_employee_code,
  sales_base_code,
  receiv_base_code,
  order_source_id,
  card_sale_class,
  invoice_class,
  invoice_classification_code,
  change_out_time_100,
  change_out_time_10,
  ar_interface_flag,
  gl_interface_flag,
  dwh_interface_flag,
  edi_interface_flag,
  edi_send_date,
  hht_dlv_input_date,
  dlv_by_code,
  create_class,
  business_date,
  created_by,
  creation_date,
  last_updated_by,
  last_update_date,
  last_update_login,
  request_id,
  program_application_id,
  program_id,
  program_update_date
)
AS
SELECT sales_exp_header_id,
       dlv_invoice_number,
       order_invoice_number,
       order_number,
       order_no_hht,
       digestion_ln_number,
       order_connection_number,
       dlv_invoice_class,
       cancel_correct_class,
       input_class,
       cust_gyotai_sho,
       delivery_date,
       orig_delivery_date,
       inspect_date,
       orig_inspect_date,
       ship_to_customer_code,
       sale_amount_sum,
       pure_amount_sum,
       tax_amount_sum,
       consumption_tax_class,
       tax_code,
       tax_rate,
       results_employee_code,
       sales_base_code,
       receiv_base_code,
       order_source_id,
       card_sale_class,
       invoice_class,
       invoice_classification_code,
       change_out_time_100,
       change_out_time_10,
       ar_interface_flag,
       gl_interface_flag,
       dwh_interface_flag,
       edi_interface_flag,
       edi_send_date,
       hht_dlv_input_date,
       dlv_by_code,
       create_class,
       business_date,
       created_by,
       creation_date,
       last_updated_by,
       last_update_date,
       last_update_login,
       request_id,
       program_application_id,
       program_id,
       program_update_date
FROM   apps.xxcos_sales_exp_headers
;
--
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.sales_exp_header_id           IS '�̔����уw�b�_ID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.dlv_invoice_number            IS '�[�i�`�[�ԍ�';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_invoice_number          IS '�����`�[�ԍ�';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_number                  IS '�󒍔ԍ�';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_no_hht                  IS '��No�iHHT)';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.digestion_ln_number           IS '��No�iHHT�j�}��';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_connection_number       IS '�󒍊֘A�ԍ�';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.dlv_invoice_class             IS '�[�i�`�[�敪';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.cancel_correct_class          IS '����E�����敪';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.input_class                   IS '���͋敪';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.cust_gyotai_sho               IS '�Ƒԏ�����';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.delivery_date                 IS '�[�i��';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.orig_delivery_date            IS '�I���W�i���[�i��';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.inspect_date                  IS '������';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.orig_inspect_date             IS '�I���W�i��������';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.ship_to_customer_code         IS '�ڋq�y�[�i��z';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.sale_amount_sum               IS '������z���v';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.pure_amount_sum               IS '�{�̋��z���v';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.tax_amount_sum                IS '����ŋ��z���v';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.consumption_tax_class         IS '����ŋ敪';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.tax_code                      IS '�ŋ��R�[�h';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.tax_rate                      IS '����ŗ�';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.results_employee_code         IS '���ьv��҃R�[�h';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.sales_base_code               IS '���㋒�_�R�[�h';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.receiv_base_code              IS '�������_�R�[�h';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_source_id               IS '�󒍃\�[�XID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.card_sale_class               IS '�J�[�h����敪';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.invoice_class                 IS '�`�[�敪';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.invoice_classification_coDE   IS '�`�[���ރR�[�h';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.change_out_time_100           IS '��K�؂ꎞ�ԂP�O�O�~';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.change_out_time_10            IS '��K�؂ꎞ�ԂP�O�~';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.ar_interface_flag             IS 'AR�C���^�t�F�[�X�σt���O';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.gl_interface_flag             IS 'GL�C���^�t�F�[�X�σt���O';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.dwh_interface_flag            IS '���V�X�e���C���^�t�F�[�X�σt���O';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.edi_interface_flag            IS 'EDI���M�ς݃t���O';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.edi_send_date                 IS 'EDI���M����';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.hht_dlv_input_date            IS 'HHT�[�i���͓���';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.dlv_by_code                   IS '�[�i�҃R�[�h';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.create_class                  IS '�쐬���敪';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.business_date                 IS '�o�^�Ɩ����t';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.created_by                    IS '�쐬��';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.creation_date                 IS '�쐬��';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.last_updated_by               IS '�ŏI�X�V��';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.last_update_date              IS '�ŏI�X�V��';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.last_update_login             IS '�ŏI�X�V۸޲�';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.request_id                    IS '�v��ID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.program_application_id        IS '�ݶ��ĥ��۸��ѥ���ع����ID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.program_id                    IS '�ݶ��ĥ��۸���ID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.program_update_date           IS '��۸��эX�V��';
COMMENT ON TABLE  apps.xxcsm_sales_exp_headers_v                               IS '�̔����уw�b�_�r���[';
