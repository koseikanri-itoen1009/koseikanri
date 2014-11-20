/*************************************************************************
 * 
 * View  Name      : XXSKZ_運賃用運送業者_現在_V
 * Description     : XXSKZ_運賃用運送業者_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_運賃用運送業者_現在_V
(
 商品区分
,商品区分名
,運送業者コード
,運送業者名
,適用開始日
,適用終了日
,オンライン化対応区分
,オンライン化対応区分名
,請求締め日
,消費税区分
,消費税区分名
,四捨五入区分
,四捨五入区分名
,支払判断区分
,支払判断区分名
,請求先コード
,請求先名
,請求基準
,請求基準名
,小口重量
,支払ピッキング単価
,請求ピッキング単価
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT 
        XDC.goods_classe               --商品区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning                  --商品区分名
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --クイックコード(商品区分名)
         WHERE FLV01.language    = 'JA'
           AND FLV01.lookup_type = 'XXWIP_ITEM_TYPE'
           AND FLV01.lookup_code = XDC.goods_classe
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDC.delivery_company_code      --運送業者コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XCRV.party_name                --運送業者名
       ,(SELECT XCRV.party_name
         FROM xxskz_carriers_v XCRV   --運送業者取得用VIEW
         WHERE XDC.delivery_company_code = XCRV.freight_code
        ) XCRV_party_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDC.start_date_active          --適用開始日
       ,XDC.end_date_active            --適用終了日
       ,XDC.online_classe              --オンライン化対応区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                  --オンライン化対応区分名
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --クイックコード(オンライン化対応区分名)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXWIP_ONLINE_TYPE'
           AND FLV02.lookup_code = XDC.online_classe
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDC.due_billing_date           --請求締め日
       ,XDC.consumption_tax_classe     --消費税区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning                  --消費税区分名
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --クイックコード(消費税区分名)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXWIP_FARETAX_TYPE'
           AND FLV03.lookup_code = XDC.consumption_tax_classe
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDC.half_adjust_classe         --四捨五入区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV04.meaning                  --四捨五入区分名
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04  --クイックコード(四捨五入区分名)
         WHERE FLV04.language    = 'JA'
           AND FLV04.lookup_type = 'XXCMN_ROUND'
           AND FLV04.lookup_code = XDC.half_adjust_classe
        ) FLV04_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDC.payments_judgment_classe   --支払判断区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV05.meaning                  --支払判断区分名
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05  --クイックコード(支払判断区分名)
         WHERE FLV05.language     = 'JA'
           AND FLV05.lookup_type = 'XXCMN_PAY_JUDGEMENT'
           AND FLV05.lookup_code = XDC.payments_judgment_classe
        ) FLV05_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDC.billing_code               --請求先コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XLCV.location_name             --請求先名
       ,(SELECT XLCV.location_name
         FROM xxskz_locations_v XLCV   --請求先名取得用VIEW
         WHERE XDC.billing_code = XLCV.location_code
        ) XLCV_location_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDC.billing_standard           --請求基準
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV06.meaning                  --請求基準名
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06  --クイックコード(請求基準名)
         WHERE FLV06.language    = 'JA'
           AND FLV06.lookup_type = 'XXWIP_CLAIM_PAY_STD'
           AND FLV06.lookup_code = XDC.billing_standard
        ) FLV06_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDC.small_weight               --小口重量
       ,XDC.pay_picking_amount         --支払ピッキング単価
       ,XDC.bill_picking_amount        --請求ピッキング単価
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XDC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XDC.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
             ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XDC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxwip_delivery_company  XDC    --運賃用運送業者アドオンマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxskz_carriers_v        XCRV   --運送業者取得用VIEW
       --,xxskz_locations_v       XLCV   --請求先名取得用VIEW
       --,fnd_user                FU_CB  --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                FU_LL  --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins              FL_LL  --ログインマスタ(last_update_login名称取得用)
       --,fnd_lookup_values       FLV01  --クイックコード(商品区分名)
       --,fnd_lookup_values       FLV02  --クイックコード(オンライン化対応区分名)
       --,fnd_lookup_values       FLV03  --クイックコード(消費税区分名)
       --,fnd_lookup_values       FLV04  --クイックコード(四捨五入区分名)
       --,fnd_lookup_values       FLV05  --クイックコード(支払判断区分名)
       --,fnd_lookup_values       FLV06  --クイックコード(請求基準名)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XDC.start_date_active <= TRUNC(SYSDATE)
   AND  XDC.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XDC.delivery_company_code = XCRV.freight_code(+)
   --AND  XDC.billing_code          = XLCV.location_code(+)
   --AND  XDC.created_by        = FU_CB.user_id(+)
   --AND  XDC.last_updated_by   = FU_LU.user_id(+)
   --AND  XDC.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
   --AND  FLV01.language(+)     = 'JA'
   --AND  FLV01.lookup_type(+)  = 'XXWIP_ITEM_TYPE'
   --AND  FLV01.lookup_code(+)  = XDC.goods_classe
   --AND  FLV02.language(+)     = 'JA'
   --AND  FLV02.lookup_type(+)  = 'XXWIP_ONLINE_TYPE'
   --AND  FLV02.lookup_code(+)  = XDC.online_classe
   --AND  FLV03.language(+)     = 'JA'
   --AND  FLV03.lookup_type(+)  = 'XXWIP_FARETAX_TYPE'
   --AND  FLV03.lookup_code(+)  = XDC.consumption_tax_classe
   --AND  FLV04.language(+)     = 'JA'
   --AND  FLV04.lookup_type(+)  = 'XXCMN_ROUND'
   --AND  FLV04.lookup_code(+)  = XDC.half_adjust_classe
   --AND  FLV05.language(+)     = 'JA'
   --AND  FLV05.lookup_type(+)  = 'XXCMN_PAY_JUDGEMENT'
   --AND  FLV05.lookup_code(+)  = XDC.payments_judgment_classe
   --AND  FLV06.language(+)     = 'JA'
   --AND  FLV06.lookup_type(+)  = 'XXWIP_CLAIM_PAY_STD'
   --AND  FLV06.lookup_code(+)  = XDC.billing_standard
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKZ_運賃用運送業者_現在_V IS 'SKYLINK用運賃用運送業者（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.運送業者コード                 IS '運送業者コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.運送業者名                     IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.適用開始日                     IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.適用終了日                     IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.オンライン化対応区分           IS 'オンライン化対応区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.オンライン化対応区分名         IS 'オンライン化対応区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.請求締め日                     IS '請求締め日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.消費税区分                     IS '消費税区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.消費税区分名                   IS '消費税区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.四捨五入区分                   IS '四捨五入区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.四捨五入区分名                 IS '四捨五入区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.支払判断区分                   IS '支払判断区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.支払判断区分名                 IS '支払判断区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.請求先コード                   IS '請求先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.請求先名                       IS '請求先名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.請求基準                       IS '請求基準'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.請求基準名                     IS '請求基準名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.小口重量                       IS '小口重量'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.支払ピッキング単価             IS '支払ピッキング単価'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.請求ピッキング単価             IS '請求ピッキング単価'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃用運送業者_現在_V.最終更新ログイン               IS '最終更新ログイン'
/

