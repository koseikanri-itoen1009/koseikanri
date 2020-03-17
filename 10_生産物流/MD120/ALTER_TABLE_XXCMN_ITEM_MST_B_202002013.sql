ALTER TABLE xxcmn.xxcmn_item_mst_b ADD (
  origin_restriction      VARCHAR2(5)
 ,tea_period_restriction  VARCHAR2(2)
 ,product_year            VARCHAR2(4)
 ,organic                 VARCHAR2(1)
);
COMMENT ON COLUMN xxcmn.xxcmn_item_mst_b.origin_restriction       IS '産地制限';
COMMENT ON COLUMN xxcmn.xxcmn_item_mst_b.tea_period_restriction   IS '茶期制限';
COMMENT ON COLUMN xxcmn.xxcmn_item_mst_b.product_year             IS '年度';
COMMENT ON COLUMN xxcmn.xxcmn_item_mst_b.organic                  IS '有機';
