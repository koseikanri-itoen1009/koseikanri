CREATE OR REPLACE VIEW apps.xxcmn_delivery_lt3_v
(
  delivery_lt_id,
  code_class1,
  entering_despatching_code1,
  code_class2,
  entering_despatching_code2,
  lt_start_date_active,
  lt_end_date_active,
  delivery_lead_time,
  consolidated_flag,
  leaf_consolidated_flag,
  drink_lead_time_day,
  leaf_lead_time_day,
  receipt_change_lead_time_day
)
AS
  SELECT  xdl.delivery_lt_id,
          xdl.code_class1,
          xdl.entering_despatching_code1,
          xdl.code_class2,
          xdl.entering_despatching_code2,
          xdl.start_date_active,
          xdl.end_date_active,
          xdl.delivery_lead_time,
          xdl.consolidated_flag,
          xdl.leaf_consolidated_flag,
          xdl.drink_lead_time_day,
          xdl.leaf_lead_time_day,
          xdl.receipt_change_lead_time_day
  FROM    xxcmn_delivery_lt   xdl
;
--
COMMENT ON COLUMN xxcmn_delivery_lt3_v.delivery_lt_id              IS '�z��LT�A�h�I��ID';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.code_class1                 IS '�R�[�h�敪�P';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.entering_despatching_code1  IS '���o�ɏꏊ�R�[�h�P';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.code_class2                 IS '�R�[�h�敪�Q';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.entering_despatching_code2  IS '���o�ɏꏊ�R�[�h�Q';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.lt_start_date_active        IS '�z��LT�K�p�J�n��';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.lt_end_date_active          IS '�z��LT�K�p�I����';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.delivery_lead_time          IS '�z�����[�h�^�C��';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.consolidated_flag           IS '�h�����N���ڋ��t���O';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.leaf_consolidated_flag      IS '���[�t���ڋ��t���O';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.drink_lead_time_day         IS '�h�����N���Y����LT';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.leaf_lead_time_day          IS '���[�t���Y����LT';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.receipt_change_lead_time_day    IS '����ύXLT';
--
COMMENT ON TABLE  xxcmn_delivery_lt3_v IS '�z��L/T���VIEW3';
