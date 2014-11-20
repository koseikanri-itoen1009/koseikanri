ALTER TABLE XXCOS.XXCOS_REP_DLV_CHK_LIST MODIFY
  (
    SUDSTANCE_TOTAL_AMOUNT        NUMBER,                                      --本体合計金額
    WHOLESALE_UNIT_PLOCE          NUMBER(13,2),                                --卸単価
    PLOCE                         NUMBER(13,2),                                --売価
    CARD_AMOUNT                   NUMBER(13,2)                                 --カード金額
  );