/*************************************************************************
 * 
 * View  Name      : XXSKZ_出来高実績情報IF_基本_V
 * Description     : XXSKZ_出来高実績情報IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_出来高実績情報IF_基本_V
(
 会社名
,データ種別
,伝送用枝番
,生産日
,取引先コード
,取引先名
,工場コード
,工場名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,製造日
,固有記号
,出来高数量
,摘要
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT 
        XVSTI.corporation_name                          --会社名
       ,XVSTI.data_class                                --データ種別
       ,XVSTI.transfer_branch_no                        --伝送用枝番
       ,XVSTI.manufactured_date                         --生産日
       ,XVSTI.vendor_code                               --取引先コード
       ,XV2V.vendor_name                                --取引先名
       ,XVSTI.factory_code                              --工場コード
       ,XVS2V.vendor_site_name                          --工場名
       ,XPCV.prod_class_code                            --商品区分
       ,XPCV.prod_class_name                            --商品区分名
       ,XICV.item_class_code                            --品目区分
       ,XICV.item_class_name                            --品目区分名
       ,XCCV.crowd_code                                 --群コード
       ,XVSTI.item_code                                 --品目コード
       ,XIM2V.item_name                                 --品目名
       ,XIM2V.item_short_name                           --品目略称
       ,XVSTI.producted_date                            --製造日
       ,XVSTI.koyu_code                                 --固有記号
       ,XVSTI.producted_quantity                        --出来高数量
       ,XVSTI.description                               --摘要
       ,FU_CB.user_name         created_by_name         --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XVSTI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date           --作成日時
       ,FU_LU.user_name         last_updated_by_name    --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XVSTI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date        --更新日時
       ,FU_LL.user_name         last_update_login_name  --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  xxpo_vendor_supply_txns_if  XVSTI               --出来高実績情報インタフェースアドオン
       ,xxskz_vendors2_v            XV2V                --SKYLINK用中間VIEW 取引先コード取得VIEW
       ,xxskz_vendor_sites2_v       XVS2V               --SKYLINK用中間VIEW 工場コード取得VIEW
       ,xxskz_prod_class_v          XPCV                --SKYLINK用中間VIEW 商品区分取得VIEW
       ,xxskz_item_class_v          XICV                --SKYLINK用中間VIEW 品目商品区分取得VIEW
       ,xxskz_crowd_code_v          XCCV                --SKYLINK用中間VIEW 群コード取得VIEW
       ,xxskz_item_mst2_v           XIM2V               --SKYLINK用中間VIEW OPM品目情報VIEW2
       ,fnd_user                    FU_CB               --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                    FU_LU               --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                    FU_LL               --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                  FL_LL               --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE  XVSTI.vendor_code           =  XV2V.segment1(+)
   AND  XVSTI.manufactured_date     >= XV2V.start_date_active(+)
   AND  XVSTI.manufactured_date     <= XV2V.end_date_active(+)
   AND  XVSTI.factory_code          =  XVS2V.vendor_site_code(+)
   AND  XVSTI.manufactured_date     >= XVS2V.start_date_active(+)
   AND  XVSTI.manufactured_date     <= XVS2V.end_date_active(+)
   AND  XVSTI.item_code             =  XIM2V.item_no(+)
   AND  XVSTI.manufactured_date     >= XIM2V.start_date_active(+)
   AND  XVSTI.manufactured_date     <= XIM2V.end_date_active(+)
   AND  XIM2V.item_id               =  XPCV.item_id(+)
   AND  XIM2V.item_id               =  XICV.item_id(+)
   AND  XIM2V.item_id               =  XCCV.item_id(+)
   --WHOカラム取得
   AND  XVSTI.created_by            =  FU_CB.user_id(+)
   AND  XVSTI.last_updated_by       =  FU_LU.user_id(+)
   AND  XVSTI.last_update_login     =  FL_LL.login_id(+)
   AND  FL_LL.user_id               =  FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_出来高実績情報IF_基本_V                     IS 'SKYLINK用出来高実績情報IF（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.会社名             IS '会社名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.データ種別         IS 'データ種別'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.伝送用枝番         IS '伝送用枝番'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.生産日             IS '生産日'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.取引先コード       IS '取引先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.取引先名           IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.工場コード         IS '工場コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.工場名             IS '工場名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.商品区分           IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.商品区分名         IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.品目区分           IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.品目区分名         IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.群コード           IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.品目コード         IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.品目名             IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.品目略称           IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.製造日             IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.固有記号           IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.出来高数量         IS '出来高数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.摘要               IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績情報IF_基本_V.最終更新ログイン   IS '最終更新ログイン'
/