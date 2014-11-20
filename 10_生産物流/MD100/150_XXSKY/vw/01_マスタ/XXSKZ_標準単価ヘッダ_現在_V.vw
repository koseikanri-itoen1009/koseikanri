/*************************************************************************
 * 
 * View  Name      : XXSKZ_標準単価ヘッダ_現在_V
 * Description     : XXSKZ_標準単価ヘッダ_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_標準単価ヘッダ_現在_V
(
 商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,付帯コード
,取引先コード
,取引先名
,工場コード
,工場名
,支給先コード
,支給先名
,固有記号
,計算区分
,計算区分名
,適用開始日
,適用終了日
,内訳合計
,変更処理フラグ
,摘要
,ヘッダID
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  XPCV.prod_class_code         --商品区分
       ,XPCV.prod_class_name         --商品区分名
       ,XICV.item_class_code         --品目区分
       ,XICV.item_class_name         --品目区分名
       ,XCCV.crowd_code              --群コード
       ,XPH.item_code                --品目コード
       ,XIMV.item_name               --品目名
       ,XIMV.item_short_name         --品目略称
       ,XPH.futai_code               --付帯コード
       ,XPH.vendor_code              --取引先コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV_T.vendor_name            --取引先名
       ,(SELECT XVV_T.vendor_name
         FROM xxskz_vendors_v XVV_T  --仕入先情報VIEW(取引先名取得用)
         WHERE XPH.vendor_id = XVV_T.vendor_id
        ) XVV_T_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPH.factory_code             --工場コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVSV.vendor_site_name        --工場名
       ,(SELECT XVSV.vendor_site_name
         FROM xxskz_vendor_sites_v XVSV   --仕入先サイト情報VIEW
         WHERE XPH.factory_id = XVSV.vendor_site_id
        ) XVSV_vendor_site_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPH.supply_to_code           --支給先コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV_S.vendor_name            --支給先名
       ,(SELECT XVV_S.vendor_name
         FROM xxskz_vendors_v XVV_S  --仕入先情報VIEW(支給先名取得用)
         WHERE XPH.supply_to_id = XVV_S.vendor_id
        ) XVV_S_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPH.koyu_code                --固有記号
       ,XPH.calculate_type           --計算区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --クイックコード(計算区分名)
         WHERE FLV01.language    = 'JA'                    --言語
           AND FLV01.lookup_type = 'XXWIP_CALCULATE_TYPE'  --クイックコードタイプ
           AND FLV01.lookup_code = XPH.calculate_type      --クイックコード
        ) calculate_type_name          --計算区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPH.start_date_active        --適用開始日
       ,XPH.end_date_active          --適用終了日
       ,XPH.total_amount             --内訳合計
       ,XPH.record_change_flg        --変更処理フラグ
       ,XPH.description              --摘要
       ,XPH.price_header_id          --ヘッダID
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name              --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XPH.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XPH.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                     --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name              --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XPH.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XPH.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                     --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name              --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
             ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XPH.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxpo_price_headers    XPH    --仕入／標準単価ヘッダアドオン
       ,xxskz_prod_class_v    XPCV   --SKYLINK用 商品区分取得VIEW
       ,xxskz_item_class_v    XICV   --SKYLINK用 品目区分取得VIEW
       ,xxskz_crowd_code_v    XCCV   --SKYLINK用 郡コード取得VIEW
       ,xxskz_item_mst_v      XIMV   --OPM品目情報VIEW
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxsky_vendors_v       XVV_T  --仕入先情報VIEW(取引先名取得用)
       --,xxsky_vendor_sites_v  XVSV   --仕入先サイト情報VIEW
       --,xxsky_vendors_v       XVV_S  --仕入先情報VIEW(支給先名取得用)
       --,fnd_lookup_values     FLV01  --クイックコード(計算区分名)
       --,fnd_user              FU_CB  --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user              FU_LU  --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user              FU_LL  --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins            FL_LL  --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XPH.price_type   = '2' --標準
   AND  XPH.item_id      = XPCV.item_id(+)
   AND  XPH.item_id      = XICV.item_id(+)
   AND  XPH.item_id      = XCCV.item_id(+)
   AND  XPH.item_id      = XIMV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XPH.vendor_id    = XVV_T.vendor_id(+)
   --AND  XPH.factory_id   = XVSV.vendor_site_id(+)
   --AND  XPH.supply_to_id = XVV_S.vendor_id(+)
   --AND  FLV01.language(+)    = 'JA'                    --言語
   --AND  FLV01.lookup_type(+) = 'XXWIP_CALCULATE_TYPE'  --クイックコードタイプ
   --AND  FLV01.lookup_code(+) = XPH.calculate_type      --クイックコード
   --AND  XPH.created_by        = FU_CB.user_id(+)
   --AND  XPH.last_updated_by   = FU_LU.user_id(+)
   --AND  XPH.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
   AND  XPH.start_date_active <= TRUNC(SYSDATE)
   AND  XPH.end_date_active   >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKZ_標準単価ヘッダ_現在_V IS 'SKYLINK用標準単価ヘッダ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.品目区分                       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.品目区分名                     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.群コード                       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.品目コード                     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.品目名                         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.品目略称                       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.付帯コード                     IS '付帯コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.取引先コード                   IS '取引先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.取引先名                       IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.工場コード                     IS '工場コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.工場名                         IS '工場名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.支給先コード                   IS '支給先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.支給先名                       IS '支給先名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.固有記号                       IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.計算区分                       IS '計算区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.計算区分名                     IS '計算区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.適用開始日                     IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.適用終了日                     IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.内訳合計                       IS '内訳合計'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.変更処理フラグ                 IS '変更処理フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.摘要                           IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.ヘッダID                       IS 'ヘッダID'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準単価ヘッダ_現在_V.最終更新ログイン               IS '最終更新ログイン'
/
