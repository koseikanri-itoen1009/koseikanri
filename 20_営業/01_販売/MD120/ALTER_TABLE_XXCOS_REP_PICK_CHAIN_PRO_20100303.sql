ALTER TABLE XXCOS.XXCOS_REP_PICK_CHAIN_PRO  ADD (
  REGULAR_SALE_CLASS_HEAD                 VARCHAR2(4)           -- ��ԓ����敪�i�w�b�_�j
 ,REGULAR_SALE_CLASS_LINE                 VARCHAR2(4)           -- ��ԓ����敪�i���ׁj
);
--
COMMENT ON COLUMN XXCOS.XXCOS_REP_PICK_CHAIN_PRO.REGULAR_SALE_CLASS_HEAD           IS  '��ԓ����敪�i�w�b�_�j';
COMMENT ON COLUMN XXCOS.XXCOS_REP_PICK_CHAIN_PRO.REGULAR_SALE_CLASS_LINE           IS  '��ԓ����敪�i���ׁj';
