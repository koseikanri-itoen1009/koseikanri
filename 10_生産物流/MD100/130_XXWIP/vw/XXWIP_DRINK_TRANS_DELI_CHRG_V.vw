CREATE OR REPLACE FORCE VIEW apps.xxwip_drink_trans_deli_chrg_v
 (
   godds_classification
 , foothold_macrotaxonomy
 , start_date_active
 , end_date_active
 ) AS 
  SELECT   xdtdc.godds_classification
         , xdtdc.foothold_macrotaxonomy
         , xdtdc.start_date_active
         , xdtdc.end_date_active
  FROM  xxwip_drink_trans_deli_chrgs xdtdc
  GROUP BY   xdtdc.godds_classification
           , xdtdc.foothold_macrotaxonomy
           , xdtdc.start_date_active
           , xdtdc.end_date_active
  ;
--
COMMENT ON COLUMN apps.xxwip_drink_trans_deli_chrg_v.godds_classification    IS '商品分類';
COMMENT ON COLUMN apps.xxwip_drink_trans_deli_chrg_v.foothold_macrotaxonomy  IS '拠点大分類';
COMMENT ON COLUMN apps.xxwip_drink_trans_deli_chrg_v.start_date_active       IS '適用開始日';
COMMENT ON COLUMN apps.xxwip_drink_trans_deli_chrg_v.end_date_active         IS '適用終了日';
--
COMMENT ON TABLE  apps.xxwip_drink_trans_deli_chrg_v IS 'ドリンク振替運賃マスタVIEW';
