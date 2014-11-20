/*************************************************************************
 * 
 * View  Name      : XXSKZ_ロット引当情報IF_基本_V
 * Description     : XXSKZ_ロット引当情報IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_ロット引当情報IF_基本_V
(
会社名
,データ種別
,伝送用枝番
,依頼NO
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,明細摘要
,ロットNO
,引当数量
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XLRI.corporation_name               --会社名
       ,XLRI.data_class                     --データ種別
       ,XLRI.transfer_branch_no             --伝送用枝番
       ,XLRI.request_no                     --依頼No
       ,XPCV.prod_class_code                --商品区分
       ,XPCV.prod_class_name                --商品区分名
       ,XICV.item_class_code                --品目区分
       ,XICV.item_class_name                --品目区分名
       ,XCCV.crowd_code                     --群コード
       ,XLRI.item_code                      --品目コード
       ,XIMV.item_name                      --品目名称
       ,XIMV.item_short_name                --品目略称
       ,XLRI.line_description               --明細摘要
       ,XLRI.lot_no                         --ロットNo
       ,XLRI.reserved_quantity              --引当数量
       ,FU_CB.user_name                     --作成者
       ,TO_CHAR( XLRI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --作成日
       ,FU_LU.user_name                     --最終更新者
       ,TO_CHAR( XLRI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --最終更新日
       ,FU_LL.user_name                     --最終更新ログイン
  FROM  xxpo_lot_reserve_if XLRI            --ロット引当情報インターフェースアドオン
       ,xxskz_prod_class_v  XPCV            --SKYLINK用中間VIEW OPM品目区分VIEW(商品区分)
       ,xxskz_item_class_v  XICV            --SKYLINK用中間VIEW OPM品目区分VIEW(品目区分)
       ,xxskz_crowd_code_v  XCCV            --SKYLINK用中間VIEW OPM品目区分VIEW(群コード)
       ,xxskz_item_mst_v    XIMV            --SKYLINK用中間VIEW OPM品目情報VIEW(品目名)
       ,fnd_user            FU_CB           --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user            FU_LU           --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user            FU_LL           --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins          FL_LL           --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE  XLRI.item_code          = XIMV.item_no(+)
   AND  XIMV.item_id            = XPCV.item_id(+)
   AND  XIMV.item_id            = XICV.item_id(+)
   AND  XIMV.item_id            = XCCV.item_id(+)
   AND  XLRI.created_by         = FU_CB.user_id(+)
   AND  XLRI.last_updated_by    = FU_LU.user_id(+)
   AND  XLRI.last_update_login  = FL_LL.login_id(+)
   AND  FL_LL.user_id           = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_ロット引当情報IF_基本_V IS 'SKYLINK用ロット引当情報インターフェース（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.会社名             IS '会社名'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.データ種別         IS 'データ種別'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.伝送用枝番         IS '伝送用枝版'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.依頼NO             IS '依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.商品区分           IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.商品区分名         IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.品目区分           IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.品目区分名         IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.群コード           IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.品目コード         IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.品目名             IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.品目略称           IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.明細摘要           IS '明細摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.ロットNO           IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.引当数量           IS '引当数量'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_ロット引当情報IF_基本_V.最終更新ログイン   IS '最終更新ログイン'
/
