/*************************************************************************
 * 
 * View  Name      : XXSKZ_外注出来高実績_基本_V
 * Description     : XXSKZ_外注出来高実績_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/21    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_外注出来高実績_基本_V
(
 処理タイプ
,処理タイプ名
,生産日
,取引先コード
,取引先名
,工場コード
,工場名
,納入先コード
,納入先名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,ロットNO
,製造日
,固有記号
,賞味期限
,数量
,単位コード
,出来高数量
,訂正数量
,出来高単位コード
,換算入数
,発注作成フラグ
,発注作成日
,摘要
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XVST.txns_type                      --処理タイプ
       ,FLV.meaning                         --処理タイプ名
       ,XVST.manufactured_date              --生産日
       ,XVST.vendor_code                    --取引先コード
       ,XVV.vendor_name                     --取引先名
       ,XVST.factory_code                   --工場コード
       ,XVSV.vendor_site_name               --工場名
       ,XVST.location_code                  --納入先コード
       ,XILV.description                    --納入先名
       ,PRODC.prod_class_code               --商品区分
       ,PRODC.prod_class_name               --商品区分名
       ,ITEMC.item_class_code               --品目区分
       ,ITEMC.item_class_name               --品目区分名
       ,CROWD.crowd_code                    --群コード
       ,XVST.item_code                      --品目コード
       ,XIMV.item_name                      --品目名
       ,XIMV.item_short_name                --品目略称
       ,XVST.lot_number                     --ロットNo
       ,XVST.producted_date                 --製造日
       ,XVST.koyu_code                      --固有記号
       ,ILM.attribute3                      --賞味期限
       ,XVST.quantity                       --数量
       ,XVST.uom                            --単位コード
       ,XVST.producted_quantity             --出来高数量
       ,XVST.corrected_quantity             --訂正数量
       ,XVST.producted_uom                  --出来高単位コード
       ,XVST.conversion_factor              --換算入数
       ,XVST.order_created_flg              --発注作成フラグ
       ,XVST.order_created_date             --発注作成日
       ,XVST.description                    --摘要
       ,FU_CB.user_name                     --作成者
       ,TO_CHAR( XVST.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --作成日
       ,FU_LU.user_name                     --最終更新者
       ,TO_CHAR( XVST.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --最終更新日
       ,FU_LL.user_name                     --最終更新ログイン
FROM
        xxpo_vendor_supply_txns XVST        --外注出来高実績アドオン
       ,fnd_lookup_values       FLV         --処理タイプ名取得用
       ,xxskz_vendors2_v        XVV         --取引名取得用
       ,xxskz_vendor_sites2_v   XVSV        --工場名取得用
       ,xxskz_item_locations2_v XILV        --納入先名取得用
       ,xxskz_item_mst2_v       XIMV        --品目名取得用
       ,xxskz_prod_class_v      PRODC       --商品区分取得用
       ,xxskz_item_class_v      ITEMC       --品目区分取得用
       ,xxskz_crowd_code_v      CROWD       --群コード取得用
       ,ic_lots_mst             ILM         --ロット情報取得用
       ,fnd_user                FU_CB       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                FU_LU       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                FU_LL       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins              FL_LL       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE 
--処理タイプ名取得用結合
      FLV.language(+) = 'JA'                  
  AND FLV.lookup_type(+) = 'XXCMN_PRODUCTION_RESULTS'
  AND FLV.lookup_code(+) = XVST.txns_type
--取引名取得用結合
  AND XVV.vendor_id(+) = XVST.vendor_id
  AND XVV.start_date_active(+) <= XVST.manufactured_date
  AND XVV.end_date_active(+) >= XVST.manufactured_date
--工場名取得用結合
  AND XVSV.vendor_site_id(+) = XVST.factory_id
  AND XVSV.start_date_active(+) <= XVST.manufactured_date
  AND XVSV.end_date_active(+) >= XVST.manufactured_date
--納入先名取得用結合
  AND XILV.inventory_location_id(+) = XVST.location_id
--品目名取得用結合
  AND XIMV.item_id(+) = XVST.item_id
  AND XIMV.start_date_active(+) <= XVST.manufactured_date
  AND XIMV.end_date_active(+) >= XVST.manufactured_date
--品目カテゴリ情報取得用結合
  AND XVST.item_id = PRODC.item_id(+)
  AND XVST.item_id = ITEMC.item_id(+)
  AND XVST.item_id = CROWD.item_id(+)
--ロット情報取得用結合
  AND ILM.item_id(+) = XVST.item_id
  AND ILM.lot_id(+) = XVST.lot_id
--ユーザ名取得用結合
  AND  FU_CB.user_id(+)  = XVST.created_by
  AND  FU_LU.user_id(+)  = XVST.last_updated_by
  AND  FL_LL.login_id(+) = XVST.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_外注出来高実績_基本_V IS 'XXSKZ_外注出来高実績（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.処理タイプ         IS '処理タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.処理タイプ名       IS '処理タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.生産日             IS '生産日'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.取引先コード       IS '取引先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.取引先名           IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.工場コード         IS '工場コード'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.工場名             IS '工場名'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.納入先コード       IS '納入先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.納入先名           IS '納入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.商品区分           IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.商品区分名         IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.品目区分           IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.品目区分名         IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.群コード           IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.品目コード         IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.品目名             IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.品目略称           IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.ロットNO           IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.製造日             IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.固有記号           IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.賞味期限           IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.数量               IS '数量'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.単位コード         IS '単位コード'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.出来高数量         IS '出来高数量'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.訂正数量           IS '訂正数量'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.出来高単位コード   IS '出来高単位コード'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.換算入数           IS '換算入数'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.発注作成フラグ     IS '発注作成フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.発注作成日         IS '発注作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.摘要               IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_外注出来高実績_基本_V.最終更新ログイン   IS '最終更新ログイン'
/
