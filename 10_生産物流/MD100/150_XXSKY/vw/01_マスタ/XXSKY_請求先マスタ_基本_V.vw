CREATE OR REPLACE VIEW APPS.XXSKY_請求先マスタ_基本_V
(
 請求先コード
,請求年月
,請求先名
,郵便番号
,住所
,電話番号
,FAX番号
,振込日
,支払条件設定日
,前月請求額
,今回入金額
,調整額
,繰越額
,今回請求金額
,請求金額合計
,今月売上額
,消費税
,通行料等
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XBM.billing_code                --請求先コード
       ,XBM.billing_date                --請求年月
       ,XBM.billing_name                --請求先名
       ,XBM.post_no                     --郵便番号
       ,XBM.address                     --住所
       ,XBM.telephone_no                --電話番号
       ,XBM.fax_no                      --FAX番号
       ,XBM.money_transfer_date         --振込日
       ,XBM.condition_setting_date      --支払条件設定日
       ,XBM.last_month_charge_amount    --前月請求額
       ,XBM.amount_receipt_money        --今回入金額
       ,XBM.amount_adjustment           --調整額
       ,XBM.balance_carried_forward     --繰越額
       ,XBM.charged_amount              --今回請求金額
       ,XBM.charged_amount_total        --請求金額合計
       ,XBM.month_sales                 --今月売上額
       ,XBM.consumption_tax             --消費税
       ,XBM.congestion_charge           --通行料等
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                 --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XBM.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XBM.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                 --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XBM.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XBM.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                 --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XBM.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxwip_billing_mst   XBM         --請求先アドオンマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,fnd_user            FU_CB       --ユーザーマスタ(created_by名称取得用)
       --,fnd_user            FU_LU       --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user            FU_LL       --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins          FL_LL       --ログインマスタ(last_update_login名称取得用)
 --WHERE  XBM.created_by        = FU_CB.user_id(+)
   --AND  XBM.last_updated_by   = FU_LU.user_id(+)
   --AND  XBM.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKY_請求先マスタ_基本_V IS 'SKYLINK用請求先マスタ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.請求先コード      IS '請求先コード'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.請求年月          IS '請求年月'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.請求先名          IS '請求先名'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.郵便番号          IS '郵便番号'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.住所              IS '住所'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.電話番号          IS '電話番号'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.FAX番号           IS 'FAX番号'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.振込日            IS '振込日'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.支払条件設定日    IS '支払条件設定日'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.前月請求額        IS '前月請求額'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.今回入金額        IS '今回入金額'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.調整額            IS '調整額'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.繰越額            IS '繰越額'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.今回請求金額      IS '今回請求金額'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.請求金額合計      IS '請求金額合計'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.今月売上額        IS '今月売上額'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.消費税            IS '消費税'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.通行料等          IS '通行料等'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.作成者            IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.作成日            IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.最終更新者        IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.最終更新日        IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_請求先マスタ_基本_V.最終更新ログイン  IS '最終更新ログイン'
/