CREATE OR REPLACE VIEW APPS.XXSKY_仕入先サイト_現在_V
(
 仕入先コード
,仕入先名
,仕入先サイトコード
,仕入先サイト名
,仕入先サイト略称
,仕入先サイトカナ名
,適用開始日
,適用終了日
,郵便番号
,住所１
,住所２
,電話番号
,FAX番号
,相手先在庫入庫先
,相手先在庫入庫先名
,発注納入先
,発注納入先名
,備考
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        XVV.segment1                     --仕入先コード
       ,XVV.vendor_name                  --仕入先名
       ,PVSA.vendor_site_code            --仕入先サイトコード
       ,XVSA.vendor_site_name            --仕入先サイト名
       ,XVSA.vendor_site_short_name      --仕入先サイト略称
       ,XVSA.vendor_site_name_alt        --仕入先サイトカナ名
       ,XVSA.start_date_active           --適用開始日
       ,XVSA.end_date_active             --適用終了日
       ,XVSA.zip                         --郵便番号
       ,XVSA.address_line1               --住所１
       ,XVSA.address_line2               --住所２
       ,XVSA.phone                       --電話番号
       ,XVSA.fax                         --FAX番号
       ,PVSA.attribute1                  --相手先在庫入庫先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV01.description               --相手先在庫入庫先名
       ,(SELECT XILV01.description
         FROM xxsky_item_locations_v XILV01   --OPM保管場所情報VIEW(相手先在庫入庫先名)
         WHERE PVSA.attribute1 = XILV01.segment1
        ) XILV01_description
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PVSA.attribute2                  --発注納入先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV02.description               --発注納入先名
       ,(SELECT XILV02.description
         FROM xxsky_item_locations_v XILV02   --OPM保管場所情報VIEW(発注納入先名)
         WHERE PVSA.attribute2 = XILV02.segment1
        ) XILV02_description
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,PVSA.attribute4                  --備考
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                  --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XVSA.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XVSA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                  --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XVSA.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XVSA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                  --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XVSA.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxcmn_vendor_sites_all  XVSA     --仕入先サイトアドオン
       ,po_vendor_sites_all     PVSA     --仕入先サイト
       ,xxsky_vendors_v         XVV      --仕入先情報VIEW
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxsky_item_locations_v  XILV01   --OPM保管場所情報VIEW(相手先在庫入庫先名)
       --,xxsky_item_locations_v  XILV02   --OPM保管場所情報VIEW(発注納入先名)
       --,fnd_user                FU_CB    --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                FU_LU    --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                FU_LL    --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins              FL_LL    --ログインマスタ(last_update_login名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XVSA.vendor_id         = PVSA.vendor_id
   AND  XVSA.vendor_site_id    = PVSA.vendor_site_id
   AND  PVSA.org_id            = FND_PROFILE.VALUE('ORG_ID')
   AND  PVSA.inactive_date     IS NULL
   AND  XVSA.start_date_active <= TRUNC(SYSDATE)
   AND  XVSA.end_date_active   >= TRUNC(SYSDATE)
   AND  XVSA.vendor_id         = XVV.vendor_id(+)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  PVSA.attribute1        = XILV01.segment1(+)
   --AND  PVSA.attribute2        = XILV02.segment1(+)
   --AND  XVSA.created_by        = FU_CB.user_id(+)
   --AND  XVSA.last_updated_by   = FU_LU.user_id(+)
   --AND  XVSA.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id          = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKY_仕入先サイト_現在_V IS 'SKYLINK用仕入先サイト（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.仕入先コード       IS '仕入先コード'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.仕入先名           IS '仕入先名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.仕入先サイトコード IS '仕入先サイトコード'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.仕入先サイト名     IS '仕入先サイト名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.仕入先サイト略称   IS '仕入先サイト略称'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.仕入先サイトカナ名 IS '仕入先サイトカナ名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.適用開始日         IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.適用終了日         IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.郵便番号           IS '郵便番号'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.住所１             IS '住所１'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.住所２             IS '住所２'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.電話番号           IS '電話番号'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.FAX番号            IS 'FAX番号'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.相手先在庫入庫先   IS '相手先在庫入庫先'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.相手先在庫入庫先名 IS '相手先在庫入庫先名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.発注納入先         IS '発注納入先'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.発注納入先名       IS '発注納入先名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.備考               IS '備考'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_仕入先サイト_現在_V.最終更新ログイン   IS '最終更新ログイン'
/
