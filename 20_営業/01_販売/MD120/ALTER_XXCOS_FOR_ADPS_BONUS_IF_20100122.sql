ALTER TABLE XXCOS.XXCOS_FOR_ADPS_BONUS_IF MODIFY(    -- 人事システム向け販売実績（賞与）テーブル
     P_VISIT_COUNT             NUMBER(7)             -- 個訪問件数
    ,G_VISIT_COUNT             NUMBER(7)             -- 小個訪問件数
    ,B_VISIT_COUNT             NUMBER(7)             -- 拠訪問件数
    ,A_VISIT_COUNT             NUMBER(7)             -- 地訪問件数
    ,D_VISIT_COUNT             NUMBER(7)             -- 本訪問件数
    ,S_VISIT_COUNT             NUMBER(7)             -- 全訪問件数
)
/