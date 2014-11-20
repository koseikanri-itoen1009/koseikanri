/*************************************************************************
 * 
 * View  Name      : XXSKZ_仕入先マスタ_現在_V
 * Description     : XXSKZ_仕入先マスタ_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_仕入先マスタ_現在_V
(
 仕入先コード
,仕入先名
,仕入先略称
,仕入先カナ名
,適用開始日
,適用終了日
,郵便番号
,住所１
,住所２
,電話番号
,FAX番号
,部署
,部署名
,支払条件設定日
,支払先
,支払先名
,斡旋者
,斡旋者名
,顧客コード
,顧客名
,生産実績処理タイプ
,生産実績処理タイプ名
,仕入先区分
,仕入先区分名
,代表工場
,代表工場名
,代表納入先
,代表納入先名
,支給価格表
,関連取引先
,関連取引先名
,備考
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        PV.segment1                      --仕入先コード
       ,XV.vendor_name                   --仕入先名
       ,XV.vendor_short_name             --仕入先略称
       ,XV.vendor_name_alt               --仕入先カナ名
       ,XV.start_date_active             --適用開始日
       ,XV.end_date_active               --適用終了日
       ,XV.zip                           --郵便番号
       ,XV.address_line1                 --住所１
       ,XV.address_line2                 --住所２
       ,XV.phone                         --電話番号
       ,XV.fax                           --FAX番号
       ,XV.department                    --部署
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XLV.location_name                --部署名
       ,(SELECT XLV.location_name
         FROM xxskz_locations_v XLV      --事業所情報VIEW
         WHERE XV.department = XLV.location_code
        ) XLV_location_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XV.terms_date                    --支払条件設定日
       ,XV.payment_to                    --支払先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV01.vendor_name                --支払先名
       ,(SELECT XVV01.vendor_name
         FROM xxskz_vendors_v XVV01    --仕入先情報VIEW(支払先名)
         WHERE XV.payment_to = XVV01.segment1
        ) XVV01_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XV.mediation                     --斡旋者
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV02.vendor_name                --斡旋者名
       ,(SELECT XVV02.vendor_name
         FROM xxskz_vendors_v XVV02    --仕入先情報VIEW(斡旋者名)
         WHERE XV.mediation = XVV02.segment1
        ) XVV02_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PV.customer_num                  --顧客コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XCAV.party_name                  --顧客名
       ,(SELECT XCAV.party_name
         FROM xxskz_cust_accounts_v XCAV     --顧客情報VIEW(顧客名)
         WHERE PV.customer_num = XCAV.party_number
        ) XCAV_party_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PV.attribute3                    --生産実績処理タイプ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning                    --生産実績処理タイプ名
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01    --クイックコード(生産実績処理タイプ名)
         WHERE FLV01.language    = 'JA'                        --言語
           AND FLV01.lookup_type = 'XXCMN_PURCHASING_FLAG'     --クイックコードタイプ
           AND FLV01.lookup_code = PV.attribute3               --クイックコード
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PV.attribute5                    --仕入先区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                    --仕入先区分名
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02    --クイックコード(仕入先区分名)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXCMN_VENDOR_CLASS'
           AND FLV02.lookup_code = PV.attribute5
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PV.attribute2                    --代表工場
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVSV.vendor_site_name            --代表工場名
       ,(SELECT XVSV.vendor_site_name
         FROM xxskz_vendor_sites_v XVSV     --仕入先サイト情報VIEW(代表工場名)
         WHERE PV.vendor_id  = XVSV.vendor_id
           AND PV.attribute2 = XVSV.vendor_site_code
        ) XVSV_vendor_site_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PV.attribute4                    --代表納入先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV.description                 --代表納入先名
       ,(SELECT XILV.description
         FROM xxskz_item_locations_v XILV     --OPM保管場所情報VIEW(代表納入先)
         WHERE PV.attribute4 = XILV.segment1
        ) XILV_description
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PV.attribute7                    --支給価格表
       ,PV.attribute8                    --関連取引先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV03.vendor_name                --関連取引先名
       ,(SELECT XVV03.vendor_name
         FROM xxskz_vendors_v XVV03    --仕入先情報VIEW(取引先名)
         WHERE PV.attribute8 = XVV03.segment1
        ) XVV03_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PV.attribute6                    --備考
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                  --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XV.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XV.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                  --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XV.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XV.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                  --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XV.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxcmn_vendors           XV       --仕入先アドオン
       ,po_vendors              PV       --仕入先マスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxskz_locations_v       XLV      --事業所情報VIEW
       --,xxskz_vendors_v         XVV01    --仕入先情報VIEW(支払先名)
       --,xxskz_vendors_v         XVV02    --仕入先情報VIEW(斡旋者名)
       --,xxskz_vendors_v         XVV03    --仕入先情報VIEW(取引先名)
       --,xxskz_cust_accounts_v   XCAV     --顧客情報VIEW(顧客名)
       --,xxskz_vendor_sites_v    XVSV     --仕入先サイト情報VIEW(代表工場名)
       --,xxskz_item_locations_v  XILV     --OPM保管場所情報VIEW(代表納入先)
       --,fnd_user                FU_CB    --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                FU_LU    --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                FU_LL    --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins              FL_LL    --ログインマスタ(last_update_login名称取得用)
       --,fnd_lookup_values       FLV01    --クイックコード(生産実績処理タイプ名)
       --,fnd_lookup_values       FLV02    --クイックコード(仕入先区分名)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XV.vendor_id         = PV.vendor_id
   AND  PV.end_date_active   IS NULL
   AND  XV.start_date_active <= TRUNC(SYSDATE)
   AND  XV.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XV.department        = XLV.location_code(+)
   --AND  XV.payment_to        = XVV01.segment1(+)
   --AND  XV.mediation         = XVV02.segment1(+)  
   --AND  PV.customer_num      = XCAV.party_number(+)
   --AND  PV.vendor_id         = XVSV.vendor_id(+)
   --AND  PV.attribute2        = XVSV.vendor_site_code(+)
   --AND  PV.attribute4        = XILV.segment1(+)
   --AND  PV.attribute8        = XVV03.segment1(+)
   --AND  XV.created_by        = FU_CB.user_id(+)
   --AND  XV.last_updated_by   = FU_LU.user_id(+)
   --AND  XV.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id        = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'                        --言語
   --AND  FLV01.lookup_type(+) = 'XXCMN_PURCHASING_FLAG'     --クイックコードタイプ
   --AND  FLV01.lookup_code(+) = PV.attribute3               --クイックコード
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_VENDOR_CLASS'
   --AND  FLV02.lookup_code(+) = PV.attribute5
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKZ_仕入先マスタ_現在_V IS 'SKYLINK用仕入先マスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.仕入先コード         IS '仕入先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.仕入先名             IS '仕入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.仕入先略称           IS '仕入先略称'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.仕入先カナ名         IS '仕入先カナ名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.適用開始日           IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.適用終了日           IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.郵便番号             IS '郵便番号'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.住所１               IS '住所１'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.住所２               IS '住所２'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.電話番号             IS '電話番号'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.FAX番号              IS 'FAX番号'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.部署                 IS '部署'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.部署名               IS '部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.支払条件設定日       IS '支払条件設定日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.支払先               IS '支払先'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.支払先名             IS '支払先名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.斡旋者               IS '斡旋者'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.斡旋者名             IS '斡旋者名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.顧客コード           IS '顧客コード'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.顧客名               IS '顧客名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.生産実績処理タイプ   IS '生産実績処理タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.生産実績処理タイプ名 IS '生産実績処理タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.仕入先区分           IS '仕入先区分'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.仕入先区分名         IS '仕入先区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.代表工場             IS '代表工場'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.代表工場名           IS '代表工場名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.代表納入先           IS '代表納入先'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.代表納入先名         IS '代表納入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.支給価格表           IS '支給価格表'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.関連取引先           IS '関連取引先'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.関連取引先名         IS '関連取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.備考                 IS '備考'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.作成者               IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.作成日               IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.最終更新者           IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.最終更新日           IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入先マスタ_現在_V.最終更新ログイン     IS '最終更新ログイン'
/