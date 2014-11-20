ALTER TABLE XXCOS.XXCOS_REP_BUS_REPORT MODIFY
  (
    AFTERTAX_SALE                 NUMBER,                                 --������z
    PRETAX_PAYMENT                NUMBER,                                 --�������z
    SALE_DISCOUNT                 NUMBER,                                 --����l��
    QUANTITY1                     NUMBER(13,2),                           --����1
    QUANTITY2                     NUMBER(13,2),                           --����2
    QUANTITY3                     NUMBER(13,2),                           --����3
    QUANTITY4                     NUMBER(13,2),                           --����4
    QUANTITY5                     NUMBER(13,2),                           --����5
    QUANTITY6                     NUMBER(13,2),                           --����6
    DELAY_VISIT_COUNT             NUMBER,                                 --���K�⌏��
    DELAY_VALID_COUNT             NUMBER,                                 --���L������
    DLV_TOTAL_SALE                NUMBER,                                 --�[�i���v������
    DLV_TOTAL_RTN                 NUMBER,                                 --�[�i���v�ԕi
    DLV_TOTAL_DISCOUNT            NUMBER,                                 --�[�i���v�l��
    PERFORMANCE_TOTAL_SALE        NUMBER,                                 --���э��v������
    PERFORMANCE_TOTAL_RTN         NUMBER,                                 --���э��v�ԕi
    PERFORMANCE_TOTAL_DISCOUNT    NUMBER                                  --���э��v�l��
  );