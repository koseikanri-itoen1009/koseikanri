ALTER TABLE xxcmn.xxcmn_item_mst_b ADD (
  expiration_month  NUMBER(4,0)
 ,expiration_type   VARCHAR2(2)
);
COMMENT ON COLUMN xxcmn.xxcmn_item_mst_b.expiration_month IS '�ܖ����ԁi���j';
COMMENT ON COLUMN xxcmn.xxcmn_item_mst_b.expiration_type  IS '�\���敪';
