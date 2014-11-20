CREATE OR REPLACE VIEW APPS.XXSKY_運送業者マスタ_現在_V
(
 運送業者コード
,運送業者名
,運送業者略称
,運送業者カナ名
,適用開始日
,適用終了日
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
       ,XP.zip                     --郵便番号
       ,XP.address_line1           --住所１
       ,XP.address_line2           --住所２
       ,XP.phone                   --電話番号
       ,XP.fax                     --FAX番号
       ,XP.eos_detination          --EOS宛先
       ,FU_CB.user_name            --作成者
       ,TO_CHAR( XP.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                   --作成日
       ,FU_LU.user_name            --最終更新者
       ,TO_CHAR( XP.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                   --最終更新日
       ,FU_LL.user_name            --最終更新ログイン
  FROM  xxcmn_parties   XP         --パーティアドオンマスタ
       ,wsh_carriers    WC
       ,hz_parties      HP         --パーティマスタ
       ,fnd_user        FU_CB      --ユーザーマスタ(created_by名称取得用)
       ,fnd_user        FU_LU      --ユーザーマスタ(last_updated_by名称取得用)
       ,fnd_user        FU_LL      --ユーザーマスタ(last_update_login名称取得用)
       ,fnd_logins      FL_LL      --ログインマスタ(last_update_login名称取得用)
 WHERE  XP.party_id = WC.carrier_id
   AND  XP.party_id = HP.party_id
   AND  XP.created_by        = FU_CB.user_id(+)
   AND  XP.last_updated_by   = FU_LU.user_id(+)
   AND  XP.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   AND  HP.status            = 'A'  --ステータス：有効
   AND  XP.start_date_active <= TRUNC(SYSDATE)
   AND  XP.end_date_active   >= TRUNC(SYSDATE)
/

COMMENT ON TABLE APPS.XXSKY_運送業者マスタ_現在_V IS 'SKYLINK用運送業者マスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.運送業者コード                 IS '運送業者コード'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.運送業者名                     IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.運送業者略称                   IS '運送業者略称'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.運送業者カナ名                 IS '運送業者カナ名'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.適用開始日                     IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.適用終了日                     IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.郵便番号                       IS '郵便番号'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.住所１                         IS '住所１'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.住所２                         IS '住所２'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.電話番号                       IS '電話番号'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.FAX番号                        IS 'FAX番号'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.EOS宛先                        IS 'EOS宛先'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_運送業者マスタ_現在_V.最終更新ログイン               IS '最終更新ログイン'
/
