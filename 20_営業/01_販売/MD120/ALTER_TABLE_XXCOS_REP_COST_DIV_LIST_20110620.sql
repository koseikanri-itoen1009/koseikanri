--項目の追加
ALTER TABLE XXCOS.XXCOS_REP_COST_DIV_LIST  ADD (
    UNIT_PRICE_CHECK_MARK     VARCHAR2(2),                                 --異常掛率卸価格チェック(表示用)
    UNIT_PRICE_CHECK_SORT     VARCHAR2(1)                                  --異常掛率卸価格チェック(ソート用)
);
--項目コメントの設定
COMMENT ON COLUMN XXCOS.XXCOS_REP_COST_DIV_LIST.UNIT_PRICE_CHECK_MARK      IS '異常掛率卸価格チェック(表示用)';
COMMENT ON COLUMN XXCOS.XXCOS_REP_COST_DIV_LIST.UNIT_PRICE_CHECK_SORT      IS '異常掛率卸価格チェック(ソート用)';
--
--桁数の調整
ALTER TABLE XXCOS.XXCOS_REP_COST_DIV_LIST  MODIFY (
    DELIVER_TO_NAME     VARCHAR2(28)                                       --出荷先
);

