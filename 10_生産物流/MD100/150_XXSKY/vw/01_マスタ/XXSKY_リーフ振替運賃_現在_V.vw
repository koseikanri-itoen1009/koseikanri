CREATE OR REPLACE VIEW APPS.XXSKY_リーフ振替運賃_現在_V
(
 適用開始日
,適用終了日
,便設定金額
,個数上限１
,設定金額１
,個数上限２
,設定金額２
,個数上限３
,設定金額３
,個数上限４
,設定金額４
,個数上限５
,設定金額５
,個数上限６
,設定金額６
,個数上限７
,設定金額７
,個数上限８
,設定金額８
,個数上限９
,設定金額９
,個数上限１０
,設定金額１０
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        XLTDC.start_date_active           --適用開始日
       ,XLTDC.end_date_active             --適用終了日
       ,XLTDC.setting_amount              --便設定金額
       ,XLTDC.upper_limit_number1         --個数上限1
       ,XLTDC.setting_amount1             --設定金額1
       ,XLTDC.upper_limit_number2         --個数上限2
       ,XLTDC.setting_amount2             --設定金額2
       ,XLTDC.upper_limit_number3         --個数上限3
       ,XLTDC.setting_amount3             --設定金額3
       ,XLTDC.upper_limit_number4         --個数上限4
       ,XLTDC.setting_amount4             --設定金額4
       ,XLTDC.upper_limit_number5         --個数上限5
       ,XLTDC.setting_amount5             --設定金額5
       ,XLTDC.upper_limit_number6         --個数上限6
       ,XLTDC.setting_amount6             --設定金額6
       ,XLTDC.upper_limit_number7         --個数上限7
       ,XLTDC.setting_amount7             --設定金額7
       ,XLTDC.upper_limit_number8         --個数上限8
       ,XLTDC.setting_amount8             --設定金額8
       ,XLTDC.upper_limit_number9         --個数上限9
       ,XLTDC.setting_amount9             --設定金額9
       ,XLTDC.upper_limit_number10        --個数上限10
       ,XLTDC.setting_amount10            --設定金額10
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                   --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XLTDC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XLTDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                          --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                   --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XLTDC.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XLTDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                          --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                   --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XLTDC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxwip_leaf_trans_deli_chrgs XLTDC --リーフ振替運賃アドオンマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,fnd_user                    FU_CB --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                    FU_LU --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                    FU_LL --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins                  FL_LL --ログインマスタ(last_update_login名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XLTDC.start_date_active <= TRUNC(SYSDATE)
   AND  XLTDC.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XLTDC.created_by        = FU_CB.user_id(+)
   --AND  XLTDC.last_updated_by   = FU_LU.user_id(+)
   --AND  XLTDC.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id           = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKY_リーフ振替運賃_現在_V IS 'SKYLINK用リーフ振替運賃（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.適用開始日                 IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.適用終了日                 IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.便設定金額                 IS '便設定金額'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限１                 IS '個数上限１'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額１                 IS '設定金額１'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限２                 IS '個数上限２'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額２                 IS '設定金額２'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限３                 IS '個数上限３'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額３                 IS '設定金額３'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限４                 IS '個数上限４'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額４                 IS '設定金額４'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限５                 IS '個数上限５'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額５                 IS '設定金額５'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限６                 IS '個数上限６'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額６                 IS '設定金額６'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限７                 IS '個数上限７'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額７                 IS '設定金額７'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限８                 IS '個数上限８'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額８                 IS '設定金額８'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限９                 IS '個数上限９'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額９                 IS '設定金額９'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.個数上限１０               IS '個数上限１０'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.設定金額１０               IS '設定金額１０'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.作成者                     IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.作成日                     IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.最終更新者                 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.最終更新日                 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_リーフ振替運賃_現在_V.最終更新ログイン           IS '最終更新ログイン'
/
