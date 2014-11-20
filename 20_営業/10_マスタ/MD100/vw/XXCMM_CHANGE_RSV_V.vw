CREATE OR REPLACE VIEW APPS.XXCMM_CHANGE_RSV_V
AS
SELECT      xsibh.item_hst_id,              --品目変更履歴ID
            xsibh.item_id,                  --品目ID
            xsibh.item_code,                --品目コード
            xoiv.parent_item_id,            --親品目ID
            xoiv.item_name,                 --正式名
            xsibh.apply_date,               --適用日（適用開始日）
            xsibh.apply_flag,               --適用有無
            xsibh.item_status,              --品目ステータス
            itm.item_status_mean,           --摘要（品目ステータス）
            xsibh.policy_group,             --群コード（政策群コード）
            xsibh.fixed_price,              --定価
            xsibh.discrete_cost,            --営業原価
            cmp.standard_cost,              --標準原価
            xsibh.first_apply_flag,         --初回適用フラグ
            xsibh.created_by,               --作成者
            xsibh.creation_date,            --作成日
            xsibh.last_updated_by,          --最終更新者
            xsibh.last_update_date,         --最終更新日
            xsibh.last_update_login,        --最終更新ログイン
            xsibh.request_id,               --要求ID
            xsibh.program_application_id,   --コンカレント・プログラムのアプリケーションID
            xsibh.program_id,               --コンカレント・プログラムID
            xsibh.program_update_date       --プログラムによる更新日
FROM        xxcmm_system_items_b_hst xsibh,
            xxcmm_opmmtl_items_v     xoiv,
            cm_cldr_dtl              ccc,   -- OPM原価カレンダ
          ( SELECT    flv.lookup_code,
                      flv.meaning  item_status_mean
            FROM      fnd_lookup_values_vl flv
            WHERE     flv.lookup_type          = 'XXCMM_ITM_STATUS'
            ORDER BY  flv.lookup_code
          ) itm,
          ( SELECT    SUM(ccd.cmpnt_cost)  AS standard_cost,
                      ccd.item_id          AS item_id,
                      ccd.calendar_code    AS calendar_code,
                      ccd.period_code      AS period_code
            FROM      cm_cmpt_dtl ccd,     -- OPM原価
                      cm_cldr_dtl ccc      -- OPM原価カレンダ 2009/01/21追加
            WHERE     ccd.calendar_code  = ccc.calendar_code
            AND       ccd.period_code    = ccc.period_code
--2009/01/21 追加
            AND       ccc.start_date    <= xxccp_common_pkg2.get_working_day(SYSDATE, 0, NULL)
            AND       ccc.end_date      >= xxccp_common_pkg2.get_working_day(SYSDATE, 0, NULL)
--2009/01/21 追加
            GROUP BY  ccd.item_id,
                      ccd.calendar_code,
                      ccd.period_code
          ) cmp    -- OPM原価
WHERE       xsibh.item_code          = xoiv.item_code
AND         xsibh.item_status        = itm.lookup_code(+)
AND         xoiv.start_date_active   <= TRUNC( SYSDATE )
AND         xoiv.end_date_active     >= TRUNC( SYSDATE )
AND         xoiv.item_id             =  cmp.item_id(+)
AND         cmp.calendar_code        =  ccc.calendar_code(+)
AND         cmp.period_code          =  ccc.period_code(+)
ORDER BY    xsibh.item_code,
            xsibh.apply_date DESC
/
COMMENT ON TABLE APPS.XXCMM_CHANGE_RSV_V IS '変更予約画面ビュー'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_HST_ID IS '品目変更履歴ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_ID IS '品目ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_CODE IS '品名コード'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.PARENT_ITEM_ID IS '親品目ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_NAME IS '正式名'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.APPLY_DATE IS '適用日（適用開始日）'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.APPLY_FLAG IS '適用有無'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_STATUS IS '品目ステータス'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_STATUS_MEAN IS '摘要（品目ステータス）'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.POLICY_GROUP IS '群コード（政策群コード）'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.FIXED_PRICE IS '定価'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.DISCRETE_COST IS '営業原価'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.STANDARD_COST IS '標準原価'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.FIRST_APPLY_FLAG IS '初回適用フラグ'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.CREATED_BY IS '作成者'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.CREATION_DATE IS '作成日'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.LAST_UPDATED_BY IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.LAST_UPDATE_DATE IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.LAST_UPDATE_LOGIN IS '最終更新ログイン'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.REQUEST_ID IS '要求ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.PROGRAM_APPLICATION_ID IS 'コンカレント・プログラムのアプリケーションID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.PROGRAM_ID IS 'コンカレント・プログラムID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.PROGRAM_UPDATE_DATE IS 'プログラムによる更新日'
/
