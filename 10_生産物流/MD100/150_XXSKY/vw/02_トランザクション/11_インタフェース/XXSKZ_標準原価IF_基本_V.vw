/*************************************************************************
 * 
 * View  Name      : XXSKZ_標準原価IF_基本_V
 * Description     : XXSKZ_標準原価IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_標準原価IF_基本_V
(
 商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目
,品目名
,品目略称
,適用開始日
,費目区分
,費目区分名
,項目区分
,項目区分名
,内訳品目
,内訳品目名
,内訳品目略称
,単価
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XPCV.prod_class_code                --商品区分
       ,XPCV.prod_class_name                --商品区分名
       ,XICV.item_class_code                --品目区分
       ,XICV.item_class_name                --品目区分名
       ,XCCV.crowd_code                     --群コード
       ,XSCI.item_code                      --品目
       ,XIMV_HIN.item_name                  --品目名
       ,XIMV_HIN.item_short_name            --品目略称
       ,XSCI.start_date_active              --適用開始日
       ,XSCI.expence_item_type              --費目区分
       ,FLV_HI.meaning                      --費目区分名
       ,XSCI.expence_item_detail_type       --項目区分
       ,FLV_KO.meaning                      --項目区分名
       ,XSCI.item_code_detail               --内訳品目
       ,XIMV_HIN.item_name                  --内訳品目名
       ,XIMV_HIN.item_short_name            --内訳品目略称
       ,XSCI.unit_price                     --単価
       ,FU_CB.user_name                     --作成者
       ,TO_CHAR( XSCI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --作成日
       ,FU_LU.user_name                     --最終更新者
       ,TO_CHAR( XSCI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --最終更新日
       ,FU_LL.user_name                     --最終更新ログイン
FROM    xxcmn_standard_cost_if  XSCI        --標準原価インタフェース
       ,xxskz_item_mst2_v       XIMV_HIN    --品目名取得
       ,xxskz_prod_class_v      XPCV        --商品区分取得
       ,xxskz_item_class_v      XICV        --品目区分取得
       ,xxskz_crowd_code_v      XCCV        --群コード取得
       ,fnd_lookup_values       FLV_HI      --費目区分名取得
       ,fnd_lookup_values       FLV_KO      --項目区分名取得
       ,xxskz_item_mst2_v       XIMV_UCH    --内訳品目名取得
       ,fnd_user                FU_CB       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                FU_LU       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                FU_LL       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins              FL_LL       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE  XIMV_HIN.ITEM_NO(+) = XSCI.item_code                     --品目名取得
  AND  XIMV_HIN.start_date_active(+) <= XSCI.start_date_active  --品目名取得
  AND  XIMV_HIN.end_date_active(+)   >= XSCI.start_date_active  --品目名取得
  AND  XIMV_HIN.item_id = XPCV.item_id(+)                       --商品区分取得
  AND  XIMV_HIN.item_id = XICV.item_id(+)                       --品目区分取得
  AND  XIMV_HIN.item_id = XCCV.item_id(+)                       --群コード取得
  AND  FLV_HI.language(+) = 'JA'                                --費目区分取得
  AND  FLV_HI.lookup_type(+) = 'XXPO_EXPENSE_ITEM_TYPE'         --費目区分取得
  AND  FLV_HI.attribute1(+) = XSCI.expence_item_type            --費目区分取得
  AND  FLV_KO.language(+) = 'JA'                                --項目区分名取得
  AND  FLV_KO.lookup_type(+) = 'XXPO_EXPENSE_ITEM_DETAIL_TYPE'  --項目区分名取得
  AND  FLV_KO.attribute1(+) = XSCI.expence_item_detail_type     --項目区分名取得
  AND  XIMV_UCH.ITEM_NO(+) = XSCI.item_code                     --内訳品目名取得
  AND  XIMV_UCH.start_date_active(+) <= XSCI.start_date_active  --内訳品目名取得
  AND  XIMV_UCH.end_date_active(+)   >= XSCI.start_date_active  --内訳品目名取得
  AND  FU_CB.user_id(+)  = XSCI.created_by
  AND  FU_LU.user_id(+)  = XSCI.last_updated_by
  AND  FL_LL.login_id(+) = XSCI.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_標準原価IF_基本_V IS 'XXSKZ_標準原価IF(基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.商品区分         IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.商品区分名       IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.品目区分         IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.品目区分名       IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.群コード         IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.品目             IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.品目名           IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.品目略称         IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.適用開始日       IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.費目区分         IS '費目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.費目区分名       IS '費目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.項目区分         IS '項目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.項目区分名       IS '項目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.内訳品目         IS '内訳品目'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.内訳品目名       IS '内訳品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.内訳品目略称     IS '内訳品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.単価             IS '単価'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.作成者           IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.作成日           IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.最終更新者       IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.最終更新日       IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価IF_基本_V.最終更新ログイン IS '最終更新ログイン'
/
