CREATE OR REPLACE VIEW xxcmn_sourcing_rules2_v
(
  sourcing_rules_id,
  item_code,
  base_code,
  ship_to_code,
  start_date_active,
  end_date_active,
  delivery_whse_code,
  move_from_whse_code1,
  move_from_whse_code2,
  vendor_site_code1,
  vendor_site_code2,
  plan_item_flag
)
AS
  SELECT  xsr.sourcing_rules_id,
          xsr.item_code,
          xsr.base_code,
          xsr.ship_to_code,
          xsr.start_date_active,
          xsr.end_date_active,
          xsr.delivery_whse_code,
          xsr.move_from_whse_code1,
          xsr.move_from_whse_code2,
          xsr.vendor_site_code1,
          xsr.vendor_site_code2,
          xsr.plan_item_flag
  FROM    xxcmn_sourcing_rules  xsr
;
--
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.sourcing_rules_id     IS '�����\���A�h�I��ID';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.item_code             IS '�i�ڃR�[�h';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.base_code             IS '���_�R�[�h';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.ship_to_code          IS '�z����R�[�h';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.start_date_active     IS '�K�p�J�n��';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.end_date_active       IS '�K�p�I����';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.delivery_whse_code    IS '�o�וۊǑq�ɃR�[�h';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.move_from_whse_code1  IS '�ړ����ۊǑq�ɃR�[�h1';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.move_from_whse_code2  IS '�ړ����ۊǑq�ɃR�[�h2';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.vendor_site_code1     IS '�d����T�C�g�R�[�h1';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.vendor_site_code2     IS '�d����T�C�g�R�[�h2';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.plan_item_flag        IS '�v�揤�i�t���O';
--
COMMENT ON TABLE  xxcmn_sourcing_rules2_v IS '�����\�����VIEW';
