ALTER TABLE XXCOS.XXCOS_FOR_ADPS_MONTHLY_IF MODIFY(    -- 人事システム向け販売実績（月次）テーブル
     P_NEW_COUNT_SUM            NUMBER(7)              -- 個新規件数合計
    ,P_NEW_COUNT_VD             NUMBER(7)              -- 個新規件数ﾍﾞﾝﾀﾞｰ
    ,G_NEW_COUNT_SUM            NUMBER(7)              -- 小新規件数合計
    ,G_NEW_COUNT_VD             NUMBER(7)              -- 小新規件数ﾍﾞﾝﾀﾞｰ
    ,B_NEW_COUNT_SUM            NUMBER(7)              -- 拠新規件数合計
    ,B_NEW_COUNT_VD             NUMBER(7)              -- 拠新規件数ﾍﾞﾝﾀﾞｰ
    ,A_NEW_COUNT_SUM            NUMBER(7)              -- 地新規件数合計
    ,A_NEW_COUNT_VD             NUMBER(7)              -- 地新規件数ﾍﾞﾝﾀﾞｰ
    ,D_NEW_COUNT_SUM            NUMBER(7)              -- 本新規件数合計
    ,D_NEW_COUNT_VD             NUMBER(7)              -- 本新規件数ﾍﾞﾝﾀﾞｰ
    ,S_NEW_COUNT_SUM            NUMBER(7)              -- 全新規件数合計
    ,S_NEW_COUNT_VD             NUMBER(7)              -- 全新規件数ﾍﾞﾝﾀﾞｰ
)
/