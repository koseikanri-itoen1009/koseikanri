CREATE OR REPLACE VIEW xxcmn_item_locations_v
(
  mtl_organization_id,
  inventory_location_id,
  whse_code,
  whse_name,
  orgn_code,
  customer_stock_whse,
  whse_spare1,
  whse_spare2,
  whse_spare3,
  whse_spare4,
  whse_spare5,
  whse_spare6,
  whse_spare7,
  whse_spare8,
  whse_spare9,
  location_id,
  segment1,
  description,
  subinventory_code,
  eos_control_type,
  eos_detination,
  whse_department,
  allow_pickup_flag,
  frequent_whse,
  distribution_block,
  frequent_mover,
  frequent_whse_code,
  whse_inside_outside_div,
  drink_calender,
  d1_whse_code,
  short_name,
  purchase_code,
  leaf_calender,
  direct_ship_type,
  purchase_site_code
)
AS
  SELECT  iwm.mtl_organization_id,
          mil.inventory_location_id,
          iwm.whse_code,
          iwm.whse_name,
          iwm.orgn_code,
          iwm.attribute1,
          iwm.attribute2,
          iwm.attribute3,
          iwm.attribute4,
          iwm.attribute5,
          iwm.attribute6,
          iwm.attribute7,
          iwm.attribute8,
          iwm.attribute9,
          iwm.attribute10,
          haou.location_id,
          mil.segment1,
          mil.description,
          mil.subinventory_code,
          CASE
            WHEN mil.attribute2 IS NULL
              THEN '0'
              ELSE '1'
          END,
          mil.attribute2,
          mil.attribute3,
          mil.attribute4,
          mil.attribute5,
          mil.attribute6,
          mil.attribute7,
          mil.attribute8,
          mil.attribute9,
          mil.attribute10,
          mil.attribute11,
          mil.attribute12,
          mil.attribute13,
          mil.attribute14,
          mil.attribute15,
          mil.attribute1
  FROM    ic_whse_mst               iwm,
          hr_all_organization_units haou,
          mtl_item_locations        mil
  WHERE iwm.mtl_organization_id =   haou.organization_id
  AND   haou.organization_id    =   mil.organization_id
  AND   haou.date_from          <=  TRUNC(SYSDATE)
  AND   ( haou.date_to IS NULL OR haou.date_to >= TRUNC(SYSDATE) )
  AND   mil.disable_date        IS NULL
;
--
COMMENT ON COLUMN xxcmn_item_locations_v.mtl_organization_id     IS '�݌ɑg�DID';
COMMENT ON COLUMN xxcmn_item_locations_v.inventory_location_id   IS '�q��ID';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_code               IS '�q�ɃR�[�h';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_name               IS '�q�ɖ�';
COMMENT ON COLUMN xxcmn_item_locations_v.orgn_code               IS '�v�����g�R�[�h';
COMMENT ON COLUMN xxcmn_item_locations_v.customer_stock_whse     IS '�����݌ɊǗ��Ώ�';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare1             IS '�q�ɗ\��1';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare2             IS '�q�ɗ\��2';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare3             IS '�q�ɗ\��3';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare4             IS '�q�ɗ\��4';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare5             IS '�q�ɗ\��5';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare6             IS '�q�ɗ\��6';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare7             IS '�q�ɗ\��7';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare8             IS '�q�ɗ\��8';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare9             IS '�q�ɗ\��9';
COMMENT ON COLUMN xxcmn_item_locations_v.location_id             IS '���Ə�ID';
COMMENT ON COLUMN xxcmn_item_locations_v.segment1                IS '�ۊǑq�ɃR�[�h';
COMMENT ON COLUMN xxcmn_item_locations_v.description             IS '�ۊǑq�ɖ�';
COMMENT ON COLUMN xxcmn_item_locations_v.subinventory_code       IS '�ۊǏꏊ�R�[�h';
COMMENT ON COLUMN xxcmn_item_locations_v.eos_control_type        IS '�d�n�r�Ǘ��敪';
COMMENT ON COLUMN xxcmn_item_locations_v.eos_detination          IS '�d�n�r����';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_department         IS '�q�ɊǗ�����';
COMMENT ON COLUMN xxcmn_item_locations_v.allow_pickup_flag       IS '�o�׈����Ώۃt���O';
COMMENT ON COLUMN xxcmn_item_locations_v.frequent_whse           IS '��\�q��';
COMMENT ON COLUMN xxcmn_item_locations_v.distribution_block      IS '�����u���b�N';
COMMENT ON COLUMN xxcmn_item_locations_v.frequent_mover          IS '��\�^�����';
COMMENT ON COLUMN xxcmn_item_locations_v.frequent_whse_code      IS '��v�ۊǑq�ɃR�[�h';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_inside_outside_div IS '���O�q�ɋ敪';
COMMENT ON COLUMN xxcmn_item_locations_v.drink_calender          IS '�h�����N��J�����_';
COMMENT ON COLUMN xxcmn_item_locations_v.d1_whse_code            IS '�c�{�P�q�Ƀt���O';
COMMENT ON COLUMN xxcmn_item_locations_v.short_name              IS '����';
COMMENT ON COLUMN xxcmn_item_locations_v.purchase_code           IS '�d����R�[�h';
COMMENT ON COLUMN xxcmn_item_locations_v.leaf_calender           IS '���[�t��J�����_';
COMMENT ON COLUMN xxcmn_item_locations_v.direct_ship_type        IS '�����q�ɋ敪';
COMMENT ON COLUMN xxcmn_item_locations_v.purchase_site_code      IS '�d����T�C�g�R�[�h';
--
COMMENT ON TABLE  xxcmn_item_locations_v IS 'OPM�ۊǏꏊ���VIEW';
