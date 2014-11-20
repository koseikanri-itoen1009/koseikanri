/*************************************************************************
 * 
 * View  Name      : XXSKZ_棚卸月末在庫_基本_V
 * Description     : XXSKZ_棚卸月末在庫_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_棚卸月末在庫_基本_V
(
 棚卸年月
,倉庫コード
,倉庫名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,ロットNO
,製造年月日
,固有記号
,賞味期限
,月末在庫数
,月末在庫ケース数
,積送中在庫数
,積送中在庫ケース数
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XSIM.invent_ym                                --棚卸年月
       ,XSIM.whse_code                                --倉庫コード
       ,IWM.whse_name                                 --倉庫名
       ,XPCV.prod_class_code                          --商品区分
       ,XPCV.prod_class_name                          --商品区分名
       ,XICV.item_class_code                          --品目区分
       ,XICV.item_class_name                          --品目区分名
       ,XCCV.crowd_code                               --群コード
       ,XSIM.item_code                                --品目コード
       ,XIMV.item_name                                --品目名
       ,XIMV.item_short_name                          --品目略称
       ,XSIM.lot_no                                   --ロットNO
       ,ILM.attribute1                                --製造年月日
       ,ILM.attribute2                                --固有記号
       ,ILM.attribute3                                --賞味期限
       ,XSIM.monthly_stock                            --月末在庫数
       ,NVL( XSIM.monthly_stock / XIMV.num_of_cases ,0 )
                                                      --月末在庫ケース数
       ,XSIM.cargo_stock                              --積送中在庫数
       ,NVL( XSIM.cargo_stock / XIMV.num_of_cases ,0 )
                                                      --積送中在庫ケース数
       ,FU_CB.user_name                               --作成者
       ,TO_CHAR( XSIM.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                      --作成日
       ,FU_LU.user_name                               --最終更新者
       ,TO_CHAR( XSIM.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                      --最終更新日
       ,FU_LL.user_name                               --最終更新ログイン
  FROM  xxcmn_stc_inv_month_stck_arc    XSIM          --棚卸月末在庫（アドオン）バックアップ
       ,ic_whse_mst                     IWM           --倉庫名取得
       ,xxskz_item_mst2_v               XIMV          --品目取得
       ,xxskz_prod_class_v              XPCV          --商品区分取得
       ,xxskz_item_class_v              XICV          --品目区分取得
       ,xxskz_crowd_code_v              XCCV          --群コード取得
       ,ic_lots_mst                     ILM           --ロット情報取得
       ,fnd_user                        FU_CB         --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                        FU_LU         --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                        FU_LL         --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                      FL_LL         --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
   -- 倉庫名取得
        XSIM.whse_code = IWM.whse_code(+)
   -- OPM品目情報取得
   AND  XSIM.item_id = XIMV.item_id(+)
   AND  TO_DATE( XSIM.invent_ym || '01', 'YYYYMMDD' ) >= XIMV.start_date_active(+)
   AND  TO_DATE( XSIM.invent_ym || '01', 'YYYYMMDD' ) <= XIMV.end_date_active(+)
   -- 商品区分取得用結合
   AND  XSIM.item_id = XPCV.item_id(+)
   -- 品目区分取得用結合
   AND  XSIM.item_id = XICV.item_id(+)
   -- 群コード取得用結合
   AND  XSIM.item_id = XCCV.item_id(+)
   -- ロット情報取得用結合
   AND  XSIM.item_id = ILM.item_id
   AND  XSIM.lot_id = ILM.lot_id
   -- 受入_作成者・最終更新者
   AND  XSIM.created_by        = FU_CB.user_id(+)
   AND  XSIM.last_updated_by   = FU_LU.user_id(+)
   AND  XSIM.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_棚卸月末在庫_基本_V IS 'SKYLINK用棚卸月末在庫（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.棚卸年月           IS '棚卸年月'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.倉庫コード         IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.倉庫名             IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.商品区分           IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.商品区分名         IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.品目区分           IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.品目区分名         IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.群コード           IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.品目コード         IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.品目名             IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.品目略称           IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.製造年月日         IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.固有記号           IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.賞味期限           IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.ロットNO           IS 'ロットNO'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.月末在庫数         IS '月末在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.月末在庫ケース数   IS '月末在庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.積送中在庫ケース数 IS '積送中在庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.積送中在庫数       IS '積送中在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸月末在庫_基本_V.最終更新ログイン   IS '最終更新ログイン'
/
