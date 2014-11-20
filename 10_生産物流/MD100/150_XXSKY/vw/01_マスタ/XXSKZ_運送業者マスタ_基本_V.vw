/*************************************************************************
 * 
 * View  Name      : XXSKZ_運送業者マスタ_基本_V
 * Description     : XXSKZ_運送業者マスタ_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_運送業者マスタ_基本_V
(
 運送業者コード
,運送業者名
,運送業者略称
,運送業者カナ名
,適用開始日
,適用終了日
,ステータス
,ステータス名
,郵便番号
,住所１
,住所２
,電話番号
,FAX番号
,EOS宛先
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  WC.freight_code            --運送業者コード
       ,XP.party_name              --運送業者名
       ,XP.party_short_name        --運送業者略称
       ,XP.party_name_alt          --運送業者カナ名
       ,XP.start_date_active       --適用開始日
       ,XP.end_date_active         --適用終了日
       ,HP.status                  --ステータス
       ,DECODE(HP.status,  'A','有効',  'I','無効')       --ステータス名
       ,XP.zip                     --郵便番号
       ,XP.address_line1           --住所１
       ,XP.address_line2           --住所２
       ,XP.phone                   --電話番号
       ,XP.fax                     --FAX番号
       ,XP.eos_detination          --EOS宛先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name            --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XP.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XP.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                   --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name            --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XP.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XP.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                   --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name            --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
             ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XP.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id        = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxcmn_parties   XP         --パーティアドオンマスタ
       ,wsh_carriers    WC
       ,hz_parties      HP         --パーティマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,fnd_user        FU_CB      --ユーザーマスタ(created_by名称取得用)
       --,fnd_user        FU_LU      --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user        FU_LL      --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins      FL_LL      --ログインマスタ(last_update_login名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XP.party_id = WC.carrier_id
   AND  XP.party_id = HP.party_id
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XP.created_by        = FU_CB.user_id(+)
   --AND  XP.last_updated_by   = FU_LU.user_id(+)
   --AND  XP.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id        = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
   AND  HP.status            = 'A'  --ステータス：有効
/
COMMENT ON TABLE APPS.XXSKZ_運送業者マスタ_基本_V IS 'SKYLINK用運送業者マスタ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.運送業者コード IS '運送業者コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.運送業者名 IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.運送業者略称 IS '運送業者略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.運送業者カナ名 IS '運送業者カナ名'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.適用開始日 IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.適用終了日 IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.ステータス IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.ステータス名 IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.郵便番号 IS '郵便番号'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.住所１ IS '住所１'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.住所２ IS '住所２'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.電話番号 IS '電話番号'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.FAX番号 IS 'FAX番号'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.EOS宛先 IS 'EOS宛先'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_運送業者マスタ_基本_V.最終更新ログイン IS '最終更新ログイン'
/
