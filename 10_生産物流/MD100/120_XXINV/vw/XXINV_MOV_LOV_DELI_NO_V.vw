CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_MOV_LOV_DELI_NO_V" (
  "DELIVERY_NO",
  "PRODUCT_FLG",
  "ITEM_CLASS"
  ) AS 
  SELECT
    DELIVERY_NO          -- �z��No
   ,PRODUCT_FLG          -- ���i���ʋ敪
   ,ITEM_CLASS           -- ���i�敪
  FROM  XXINV_MOV_REQ_INSTR_HEADERS  -- �ړ��˗��E�w���w�b�_(�A�h�I��)
  WHERE DELIVERY_NO IS NOT NULL
  GROUP BY
        DELIVERY_NO
       ,PRODUCT_FLG
       ,ITEM_CLASS
  ORDER BY
        DELIVERY_NO
  ;
--
COMMENT ON COLUMN XXINV_MOV_LOV_DELI_NO_V.DELIVERY_NO   IS '�z��No';
--
COMMENT ON TABLE  XXINV_MOV_LOV_DELI_NO_V IS '�ړ�_�l�Z�b�g�pVIEW_�z��No' ;
/