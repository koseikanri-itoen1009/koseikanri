ALTER TABLE XXCOS.XXCOS_REP_BUS_REPORT MODIFY
  (
    AFTERTAX_SALE                 NUMBER,                                 --売上金額
    PRETAX_PAYMENT                NUMBER,                                 --入金金額
    SALE_DISCOUNT                 NUMBER,                                 --売上値引
    QUANTITY1                     NUMBER(13,2),                           --数量1
    QUANTITY2                     NUMBER(13,2),                           --数量2
    QUANTITY3                     NUMBER(13,2),                           --数量3
    QUANTITY4                     NUMBER(13,2),                           --数量4
    QUANTITY5                     NUMBER(13,2),                           --数量5
    QUANTITY6                     NUMBER(13,2),                           --数量6
    DELAY_VISIT_COUNT             NUMBER,                                 --延訪問件数
    DELAY_VALID_COUNT             NUMBER,                                 --延有効件数
    DLV_TOTAL_SALE                NUMBER,                                 --納品合計純売上
    DLV_TOTAL_RTN                 NUMBER,                                 --納品合計返品
    DLV_TOTAL_DISCOUNT            NUMBER,                                 --納品合計値引
    PERFORMANCE_TOTAL_SALE        NUMBER,                                 --成績合計純売上
    PERFORMANCE_TOTAL_RTN         NUMBER,                                 --成績合計返品
    PERFORMANCE_TOTAL_DISCOUNT    NUMBER                                  --成績合計値引
  );