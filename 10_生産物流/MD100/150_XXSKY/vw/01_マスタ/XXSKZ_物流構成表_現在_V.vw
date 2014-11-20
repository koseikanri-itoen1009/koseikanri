/*************************************************************************
 * 
 * View  Name      : XXSKZ_物流構成表_現在_V
 * Description     : XXSKZ_物流構成表_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_物流構成表_現在_V
(
 商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,拠点コード
,拠点名
,配送先コード
,配送先名
,適用開始日
,適用終了日
,出荷保管倉庫コード
,出荷保管倉庫名
,移動元保管倉庫コード１
,移動元保管倉庫名１
,移動元保管倉庫コード２
,移動元保管倉庫名２
,仕入先サイトコード１
,仕入先サイト名１
,仕入先サイトコード２
,仕入先サイト名２
,計画商品フラグ
,計画商品フラグ名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        XPCV.prod_class_code           --商品区分
       ,XPCV.prod_class_name           --商品区分名
       ,XICV.item_class_code           --品目区分
       ,XICV.item_class_name           --品目区分名
       ,XCCV.crowd_code                --群コード
       ,XSR.item_code                  --品目コード
       ,XIMV.item_name                 --品目名
       ,XIMV.item_short_name           --品目略称
       ,XSR.base_code                  --拠点コード
       ,XCAV.party_name                --拠点名
       ,XSR.ship_to_code               --配送先コード
       ,XPSV.party_site_name           --配送先名
       ,XSR.start_date_active          --適用開始日
       ,XSR.end_date_active            --適用終了日
       ,XSR.delivery_whse_code         --出荷保管倉庫コード
       ,XILV01.description             --出荷保管倉庫名
       ,XSR.move_from_whse_code1       --移動元保管倉庫コード１
       ,XILV02.description             --移動元保管倉庫名１
       ,XSR.move_from_whse_code2       --移動元保管倉庫コード２
       ,XILV03.description             --移動元保管倉庫名２
       ,XSR.vendor_site_code1          --仕入先サイトコード１
       ,XVSV01.vendor_site_name        --仕入先サイト名１
       ,XSR.vendor_site_code2          --仕入先サイトコード２
       ,XVSV02.vendor_site_name        --仕入先サイト名２
       ,XSR.plan_item_flag             --計画商品フラグ
       ,DECODE(XSR.plan_item_flag, '0', '計画商品非対象', '1', '計画商品対象')
        plan_item_flag_name            --計画商品フラグ名
       ,FU_CB.user_name                --作成者
       ,TO_CHAR( XSR.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --作成日
       ,FU_LU.user_name                --最終更新者
       ,TO_CHAR( XSR.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --最終更新日
       ,FU_LL.user_name                --最終更新ログイン
  FROM  xxcmn_sourcing_rules    XSR    --物流構成アドオンマスタ
       ,xxskz_item_mst_v        XIMV   --OPM品目情報VIEW
       ,xxskz_prod_class_v      XPCV   --SKYLINK用 OPM品目区分VIEW(商品区分)
       ,xxskz_item_class_v      XICV   --SKYLINK用 OPM品目区分VIEW(品目区分)
       ,xxskz_crowd_code_v      XCCV   --SKYLINK用 OPM品目区分VIEW(群コード)
       ,xxskz_cust_accounts_v   XCAV   --顧客情報VIEW(拠点)
       ,xxskz_party_sites_v     XPSV   --配送先情報VIEW(配送先)
       ,xxskz_item_locations_v  XILV01 --OPM保管場所情報VIEW(出荷保管倉庫)
       ,xxskz_item_locations_v  XILV02 --倉庫(移動元保管倉庫１)
       ,xxskz_item_locations_v  XILV03 --倉庫(移動元保管倉庫２)
       ,xxskz_vendor_sites_v    XVSV01 --仕入先サイト情報VIEW(仕入先サイト１)
       ,xxskz_vendor_sites_v    XVSV02 --仕入先サイト情報VIEW(仕入先サイト２)
       ,fnd_user                FU_CB  --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                FU_LU  --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                FU_LL  --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins              FL_LL  --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE  XSR.start_date_active <= TRUNC(SYSDATE)
   AND  XSR.end_date_active   >= TRUNC(SYSDATE)
   AND  XSR.item_code = XIMV.item_no(+)
   AND  XIMV.item_id  = XPCV.item_id(+)
   AND  XIMV.item_id  = XICV.item_id(+)
   AND  XIMV.item_id  = XCCV.item_id(+)
   AND  XSR.base_code = XCAV.party_number(+)
   AND  XSR.ship_to_code = XPSV.party_site_number(+)
   AND  XSR.delivery_whse_code = XILV01.segment1(+)
   AND  XSR.move_from_whse_code1 = XILV02.segment1(+)
   AND  XSR.move_from_whse_code2 = XILV03.segment1(+)
   AND  XSR.vendor_site_code1 =  XVSV01.vendor_site_code(+)
   AND  XSR.vendor_site_code2 =  XVSV02.vendor_site_code(+)
   AND  XSR.created_by        = FU_CB.user_id(+)
   AND  XSR.last_updated_by   = FU_LU.user_id(+)
   AND  XSR.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_物流構成表_現在_V IS 'SKYLINK用物流構成表（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.商品区分              IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.商品区分名            IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.品目区分              IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.品目区分名            IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.群コード              IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.品目コード            IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.品目名                IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.品目略称              IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.拠点コード            IS '拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.拠点名                IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.配送先コード          IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.配送先名              IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.適用開始日            IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.適用終了日            IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.出荷保管倉庫コード    IS '出荷保管倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.出荷保管倉庫名        IS '出荷保管倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.移動元保管倉庫コード１  IS '移動元保管倉庫コード１'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.移動元保管倉庫名１      IS '移動元保管倉庫名１'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.移動元保管倉庫コード２  IS '移動元保管倉庫コード２'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.移動元保管倉庫名２      IS '移動元保管倉庫名２'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.仕入先サイトコード１    IS '仕入先サイトコード１'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.仕入先サイト名１        IS '仕入先サイト名１'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.仕入先サイトコード２    IS '仕入先サイトコード２'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.仕入先サイト名２        IS '仕入先サイト名２'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.計画商品フラグ        IS '計画商品フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.計画商品フラグ名      IS '計画商品フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.作成者                IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.作成日                IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.最終更新者            IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.最終更新日            IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_物流構成表_現在_V.最終更新ログイン      IS '最終更新ログイン'
/