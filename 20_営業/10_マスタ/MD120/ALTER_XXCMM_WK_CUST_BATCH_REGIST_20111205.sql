-- �ڋq�ꊇ�X�V�o�^���[�N�e�[�u�����ڒǉ�
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  DELIVERY_ORDER          VARCHAR2(14),
  EDI_DISTRICT_CODE       VARCHAR2(8),
  EDI_DISTRICT_NAME       VARCHAR2(40),
  EDI_DISTRICT_KANA       VARCHAR2(20),
  TSUKAGATAZAIKO_DIV      VARCHAR2(2),
  DELI_CENTER_CODE        VARCHAR2(8),
  DELI_CENTER_NAME        VARCHAR2(20),
  EDI_FORWARD_NUMBER      VARCHAR2(2),
  CUST_STORE_NAME         VARCHAR2(30),
  TORIHIKISAKI_CODE       VARCHAR2(8)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.delivery_order IS '�z�����iEDI�j'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.edi_district_code IS 'EDI�n��R�[�h�iEDI)'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.edi_district_name IS 'EDI�n�於�iEDI�j'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.edi_district_kana IS 'EDI�n�於�J�i�iEDI�j'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.tsukagatazaiko_div IS '�ʉߍ݌Ɍ^�敪�iEDI�j'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.deli_center_code IS 'EDI�[�i�Z���^�[�R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.deli_center_name IS 'EDI�[�i�Z���^�[��'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.edi_forward_number IS 'EDI�`���ǔ�'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.cust_store_name IS '�ڋq�X�ܖ���'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.torihikisaki_code IS '�����R�[�h'
/
