CREATE OR REPLACE VIEW xxcmn_delivery_lt_v
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
  drink_lead_time_day,
  leaf_lead_time_day,
  receipt_change_lead_time_day,
  ship_methods_id,
  ship_method,
  sm_start_date_active,
  sm_end_date_active,
  drink_deadweight,
  leaf_deadweight,
  drink_loading_capacity,
  leaf_loading_capacity,
  palette_max_qty
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
          xdl.drink_lead_time_day,
          xdl.leaf_lead_time_day,
          xdl.receipt_change_lead_time_day,
          xsm.ship_methods_id,
          xsm.ship_method,
          xsm.start_date_active,
          xsm.end_date_active,
          xsm.drink_deadweight,
          xsm.leaf_deadweight,
          xsm.drink_loading_capacity,
          xsm.leaf_loading_capacity,
          xsm.palette_max_qty
  FROM    xxcmn_delivery_lt   xdl,
          xxcmn_ship_methods  xsm
  WHERE xdl.code_class1                 = xsm.code_class1(+)
  AND   xdl.entering_despatching_code1  = xsm.entering_despatching_code1(+)
  AND   xdl.code_class2                 = xsm.code_class2(+)
  AND   xdl.entering_despatching_code2  = xsm.entering_despatching_code2(+)
  AND   xdl.start_date_active           <= TRUNC(SYSDATE)
  AND   xdl.end_date_active             >= TRUNC(SYSDATE)
  AND   xsm.start_date_active(+)        <= TRUNC(SYSDATE)
  AND   xsm.end_date_active(+)          >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_delivery_lt_v.delivery_lt_id              IS '�z��LT�A�h�I��ID';
COMMENT ON COLUMN xxcmn_delivery_lt_v.code_class1                 IS '�R�[�h�敪�P';
COMMENT ON COLUMN xxcmn_delivery_lt_v.entering_despatching_code1  IS '���o�ɏꏊ�R�[�h�P';
COMMENT ON COLUMN xxcmn_delivery_lt_v.code_class2                 IS '�R�[�h�敪�Q';
COMMENT ON COLUMN xxcmn_delivery_lt_v.entering_despatching_code2  IS '���o�ɏꏊ�R�[�h�Q';
COMMENT ON COLUMN xxcmn_delivery_lt_v.lt_start_date_active        IS '�z��LT�K�p�J�n��';
COMMENT ON COLUMN xxcmn_delivery_lt_v.lt_end_date_active          IS '�z��LT�K�p�I����';
COMMENT ON COLUMN xxcmn_delivery_lt_v.delivery_lead_time          IS '�z�����[�h�^�C��';
COMMENT ON COLUMN xxcmn_delivery_lt_v.consolidated_flag           IS '���ڋ��t���O';
COMMENT ON COLUMN xxcmn_delivery_lt_v.drink_lead_time_day         IS '�h�����N���Y����LT';
COMMENT ON COLUMN xxcmn_delivery_lt_v.leaf_lead_time_day          IS '���[�t���Y����LT';
COMMENT ON COLUMN xxcmn_delivery_lt_v.receipt_change_lead_time_day    IS '����ύXLT';
COMMENT ON COLUMN xxcmn_delivery_lt_v.ship_methods_id             IS '�o�ו��@�A�h�I��ID';
COMMENT ON COLUMN xxcmn_delivery_lt_v.ship_method                 IS '�o�ו��@';
COMMENT ON COLUMN xxcmn_delivery_lt_v.sm_start_date_active        IS '�o�ו��@�K�p�J�n��';
COMMENT ON COLUMN xxcmn_delivery_lt_v.sm_end_date_active          IS '�o�ו��@�K�p�I����';
COMMENT ON COLUMN xxcmn_delivery_lt_v.drink_deadweight            IS '�h�����N�ύڏd��';
COMMENT ON COLUMN xxcmn_delivery_lt_v.leaf_deadweight             IS '���[�t�ύڏd��';
COMMENT ON COLUMN xxcmn_delivery_lt_v.drink_loading_capacity      IS '�h�����N�ύڗe��';
COMMENT ON COLUMN xxcmn_delivery_lt_v.leaf_loading_capacity       IS '���[�t�ύڗe��';
COMMENT ON COLUMN xxcmn_delivery_lt_v.palette_max_qty             IS '�p���b�g�ő喇��';
--
COMMENT ON TABLE  xxcmn_delivery_lt_v IS '�z��L/T���VIEW';
