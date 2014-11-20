/*************************************************************************
 * 
 * View  Name      : XXSKZ_引取計画_基本_V
 * Description     : XXSKZ_引取計画_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_引取計画_基本_V
(
需要予測日
,予測セットコード
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,内外区分
,内外区分名
,ケース入数
,出庫元倉庫コード
,出庫元倉庫名
,拠点コード
,拠点名
,取込部署コード
,取込部署名
,予測当初数量
,予測現在数量
,元ケース数量
,元バラ数量
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        MFD.forecast_date                       --需要予測日
       ,MFD.forecast_set                        --予測セットコード
       ,XPCV.prod_class_code                    --商品区分
       ,XPCV.prod_class_name                    --商品区分名
       ,XICV.item_class_code                    --品目区分
       ,XICV.item_class_name                    --品目区分名
       ,XCCV.crowd_code                         --群コード
       ,XIMV.item_no                            --品目コード
       ,XIMV.item_name                          --品目名
       ,XIMV.item_short_name                    --品目略称
       ,XIOCV.inout_class_code                  --内外区分
       ,XIOCV.inout_class_name                  --内外区分名
       ,XIMV.num_of_cases                       --ケース入数
       ,MFD.attribute2                          --出庫元倉庫コード
       ,XILV.description                        --出庫元倉庫名
       ,MFD.attribute5                          --拠点コード
       ,XCAV.party_name                         --拠点名
       ,MFD.attribute4_tori                     --取込部署コード
       ,XLV.location_name                       --取込部署名
       ,MFD.original_forecast_quantity          --予測当初数量
       ,MFD.current_forecast_quantity           --予測現在数量
       ,MFD.attribute6_case                     --元ケース数量
       ,MFD.attribute4_bara                     --元バラ数量
       ,FU_CB.user_name                         --作成者
       ,TO_CHAR( MFD.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --作成日
       ,FU_LU.user_name                         --最終更新者
       ,TO_CHAR( MFD.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --最終更新日
       ,FU_LL.user_name                         --最終更新ログイン
FROM
       (SELECT
            MFDT.forecast_date                  --需要予測日
           ,MFDT.inventory_item_id              --商品ID
           ,MFDS.forecast_set                   --予測セットコード
           ,MFDS.attribute2                     --出庫元倉庫コード
           ,MFDT.attribute5                     --拠点コード
           ,MFDS.attribute4 AS attribute4_tori  --取込部署コード
           ,MFDT.original_forecast_quantity     --予測当初数量
           ,MFDT.current_forecast_quantity      --予測現在数量
           ,NVL(TO_NUMBER(MFDT.attribute6), 0) AS attribute6_case  --元ケース数量
           ,NVL(TO_NUMBER(MFDT.attribute4), 0) AS attribute4_bara  --元バラ数量
           ,MFDT.created_by                     --作成者
           ,MFDT.creation_date                  --作成日
           ,MFDT.last_update_date               --最終更新日
           ,MFDT.last_updated_by                --最終更新者
           ,MFDT.last_update_login              --最終更新ログイン
       FROM
            mrp_forecast_dates          MFDT    --フォーキャスト日付
           ,mrp_forecast_designators    MFDS    --フォーキャストDESIGNATOR
       WHERE
            --フォーキャスト日付・フォーキャストDESIGNATOR 内部結合
                  MFDT.organization_id = fnd_profile.value('XXCMN_MASTER_ORG_ID')
              AND MFDS.forecast_designator = MFDT.forecast_designator
              AND MFDS.attribute1 = '01'        --attribute1=01:引取計画
       )                                MFD     --フォーキャスト日付・フォーキャストDESIGNATOR
       ,xxskz_item_mst2_v               XIMV    --品目名取得用
       ,xxskz_prod_class_v              XPCV    --商品区分取得用
       ,xxskz_crowd_code_v              XCCV    --群コード取得用
       ,xxskz_item_class_v              XICV    --品目区分取得用
       ,xxskz_inout_class_v             XIOCV   --内外区分取得用
       ,xxskz_item_locations2_v         XILV    --出庫倉庫名取得用
       ,xxskz_cust_accounts2_v          XCAV    --拠点名取得用
       ,xxskz_locations2_v              XLV     --事業所取得用
       ,fnd_user                        FU_CB   --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                        FU_LU   --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                        FU_LL   --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                      FL_LL   --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
--品目名取得結合
  XIMV.inventory_item_id = MFD.inventory_item_id
  AND XIMV.start_date_active(+) <= MFD.forecast_date
  AND XIMV.end_date_active(+)   >= MFD.forecast_date
--商品区分取得結合（｢品目名取得｣で取得した品目IDを使用）
  AND XPCV.item_id(+) = XIMV.item_id            
--群コード取得結合（｢品目名取得｣で取得した品目IDを使用）
  AND XCCV.item_id(+) = XIMV.item_id
--品目区分取得結合（｢品目名取得｣で取得した品目IDを使用）
  AND XICV.item_id(+) = XIMV.item_id
--内外区分取得結合（｢品目名取得｣で取得した品目IDを使用）
  AND XIOCV.item_id(+) = XIMV.item_id
--出庫倉庫名取得結合
  AND XILV.segment1(+) = MFD.attribute2
--拠点名取得結合
  AND XCAV.party_number(+) = MFD.attribute5
  AND XCAV.start_date_active(+) <= MFD.forecast_date
  AND XCAV.end_date_active(+)   >= MFD.forecast_date
--事業所取得結合
  AND XLV.location_code(+) = MFD.attribute4_tori
  AND XLV.start_date_active(+) <= MFD.forecast_date
  AND XLV.end_date_active(+)   >= MFD.forecast_date
--ユーザーマスタ(CREATED_BY名称取得用結合)
  AND  FU_CB.user_id(+)  = MFD.created_by
--ユーザーマスタ(LAST_UPDATE_BY名称取得用結合)
  AND  FU_LU.user_id(+)  = MFD.last_updated_by
--ログインマスタ・ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用結合)
  AND  FL_LL.login_id(+) = MFD.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_引取計画_基本_V IS 'XXSKZ_引取計画 (基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.需要予測日          IS '需要予測日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.予測セットコード    IS '予測セットコード'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.商品区分            IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.商品区分名          IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.品目区分            IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.品目区分名          IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.群コード            IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.品目コード          IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.品目名              IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.品目略称            IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.内外区分            IS '内外区分'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.内外区分名          IS '内外区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.ケース入数          IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.出庫元倉庫コード    IS '出庫元倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.出庫元倉庫名        IS '出庫元倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.拠点コード          IS '拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.拠点名              IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.取込部署コード      IS '取込部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.取込部署名          IS '取込部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.予測当初数量        IS '予測当初数量'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.予測現在数量        IS '予測現在数量'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.元ケース数量        IS '元ケース数量'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.元バラ数量          IS '元バラ数量'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.作成者              IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.作成日              IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.最終更新者          IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.最終更新日          IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_基本_V.最終更新ログイン    IS '最終更新ログイン'
/
