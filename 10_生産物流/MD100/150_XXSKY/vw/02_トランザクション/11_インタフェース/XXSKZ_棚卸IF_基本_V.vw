/*************************************************************************
 * 
 * View  Name      : XXSKZ_棚卸IF_基本_V
 * Description     : XXSKZ_棚卸IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_棚卸IF_基本_V
(
報告部署
,報告部署名
,棚卸日
,棚卸倉庫
,棚卸倉庫名
,棚卸連番
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目
,品目名
,品目略称
,ロットNO
,製造日
,賞味期限
,固有記号
,棚卸ケース数
,入数
,棚卸バラ
,ロケーション
,ラックNO１
,ラックNO２
,ラックNO３
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
         XSII.report_post_code                  --報告部署
        ,XL2V.location_name                     --報告部署名
        ,XSII.invent_date                       --棚卸日
        ,XSII.invent_whse_code                  --棚卸倉庫
        ,IWM.whse_name                          --棚卸倉庫名
        ,XSII.invent_seq                        --棚卸連番
        ,XPCV.prod_class_code                   --商品区分
        ,XPCV.prod_class_name                   --商品区分名
        ,XICV.item_class_code                   --品目区分
        ,XICV.item_class_name                   --品目区分名
        ,XCCV.crowd_code                        --群コード
        ,XSII.item_code                         --品目
        ,XIM2V.item_name                        --品目名
        ,XIM2V.item_short_name                  --品目略称
        ,XSII.lot_no                            --ロットNo
        ,XSII.maker_date                        --製造日
        ,XSII.limit_date                        --賞味期限
        ,XSII.proper_mark                       --固有記号
        ,XSII.case_amt                          --棚卸ケース数
        ,XSII.content                           --入数
        ,XSII.loose_amt                         --棚卸バラ
        ,XSII.location                          --ロケーション
        ,XSII.rack_no1                          --ラックNo1
        ,XSII.rack_no2                          --ラックNo2
        ,XSII.rack_no3                          --ラックNo3
        ,FU_CB.user_name                        --作成者
        ,TO_CHAR( XSII.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --作成日
        ,FU_LU.user_name                        --最終更新者
        ,TO_CHAR( XSII.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --最終更新日
        ,FU_LL.user_name                        --最終更新ログイン
  FROM   xxinv_stc_inventory_interface  XSII    --棚卸インタフェーステーブル(アドオン)
        ,xxskz_locations2_v             XL2V    --SKYLINK用中間VIEW 事業所情報VIEW2(部署名)
        ,ic_whse_mst                    IWM     --倉庫マスタ(倉庫名)
        ,xxskz_prod_class_v             XPCV    --SKYLINK用中間VIEW OPM品目区分VIEW(商品区分)
        ,xxskz_item_class_v             XICV    --SKYLINK用中間VIEW OPM品目区分VIEW(品目区分)
        ,xxskz_crowd_code_v             XCCV    --SKYLINK用中間VIEW OPM品目区分VIEW(群コード)
        ,xxskz_item_mst2_v              XIM2V   --SKYLINK用中間VIEW OPM品目情報VIEW2(品目名)
        ,fnd_user                       FU_CB   --ユーザーマスタ(CREATED_BY名称取得用)
        ,fnd_user                       FU_LU   --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
        ,fnd_user                       FU_LL   --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_logins                     FL_LL   --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE  XSII.report_post_code           = XL2V.location_code(+)
   AND  XL2V.start_date_active(+)       <= XSII.invent_date
   AND  XL2V.end_date_active(+)         >= XSII.invent_date
   AND  XSII.invent_whse_code           = IWM.whse_code(+)
   AND  XSII.item_code                  = XIM2V.item_no(+)
   AND  XIM2V.start_date_active(+)      <= XSII.invent_date
   AND  XIM2V.end_date_active(+)        >= XSII.invent_date
   AND  XIM2V.item_id                   = XPCV.item_id(+)
   AND  XIM2V.item_id                   = XICV.item_id(+)
   AND  XIM2V.item_id                   = XCCV.item_id(+)
   AND  XSII.created_by                 = FU_CB.user_id(+)
   AND  XSII.last_updated_by            = FU_LU.user_id(+)
   AND  XSII.last_update_login          = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_棚卸IF_基本_V IS 'SKYLINK用棚卸インターフェース（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.報告部署     IS '報告部署'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.報告部署名   IS '報告部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.棚卸日       IS '棚卸日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.棚卸倉庫     IS '棚卸倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.棚卸倉庫名   IS '棚卸倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.棚卸連番     IS '棚卸連番'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.商品区分     IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.商品区分名   IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.品目区分     IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.品目区分名   IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.群コード     IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.品目         IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.品目名       IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.品目略称     IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.ロットNO     IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.製造日       IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.賞味期限     IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.固有記号     IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.棚卸ケース数 IS '棚卸ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.入数         IS '入数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.棚卸バラ     IS '棚卸バラ'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.ロケーション IS 'ロケーション'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.ラックNO１   IS 'ラックNo１'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.ラックNO２   IS 'ラックNo２'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.ラックNO３   IS 'ラックNo３'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.作成者       IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.作成日       IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.最終更新者   IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.最終更新日   IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸IF_基本_V.最終更新ログイン     IS '最終更新ログイン'
/
