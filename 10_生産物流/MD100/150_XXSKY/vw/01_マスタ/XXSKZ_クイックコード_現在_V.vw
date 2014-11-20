/*************************************************************************
 * 
 * View  Name      : XXSKZ_クイックコード_現在_V
 * Description     : XXSKZ_クイックコード_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_クイックコード_現在_V
(
 参照タイプ
,参照タイプ名
,参照タイプ摘要
,アプリケーション名
,参照コード
,参照コード_内容
,参照コード_摘要
,コンテキスト
,属性１
,属性２
,属性３
,属性４
,属性５
,属性６
,属性７
,属性８
,属性９
,属性１０
,属性１１
,属性１２
,属性１３
,属性１４
,属性１５
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        FLV.lookup_type                  --参照タイプ
       ,FLTT.meaning                     --参照タイプ名
       ,FLTT.description                 --参照タイプ摘要
       ,FAT.application_name             --アプリケーション名
       ,FLV.lookup_code                  --参照コード
       ,FLV.meaning                      --参照コード_内容
       ,FLV.description                  --参照コード_摘要
       ,FLV.attribute_category           --コンテキスト
       ,FLV.attribute1                   --属性１
       ,FLV.attribute2                   --属性２
       ,FLV.attribute3                   --属性３
       ,FLV.attribute4                   --属性４
       ,FLV.attribute5                   --属性５
       ,FLV.attribute6                   --属性６
       ,FLV.attribute7                   --属性７
       ,FLV.attribute8                   --属性８
       ,FLV.attribute9                   --属性９
       ,FLV.attribute10                  --属性１０
       ,FLV.attribute11                  --属性１１
       ,FLV.attribute12                  --属性１２
       ,FLV.attribute13                  --属性１３
       ,FLV.attribute14                  --属性１４
       ,FLV.attribute15                  --属性１５
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                  --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB     --ユーザーマスタ(created_by名称取得用)
         WHERE FLV.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( FLV.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                  --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU     --ユーザーマスタ(last_updated_by名称取得用)
         WHERE FLV.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( FLV.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                  --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL     --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL     --ログインマスタ(last_update_login名称取得用)
         WHERE FLV.last_update_login = FL_LL.login_id
         AND  FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  fnd_application        FA        --
       ,fnd_lookup_types       FLT       --
       ,fnd_lookup_values      FLV       --クイックコード値
       ,fnd_lookup_types_tl    FLTT      --
       ,fnd_application_tl     FAT       --
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,fnd_user               FU_CB     --ユーザーマスタ(created_by名称取得用)
       --,fnd_user               FU_LU     --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user               FU_LL     --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins             FL_LL     --ログインマスタ(last_update_login名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  SUBSTRB(FA.application_short_name, 1, 2) = 'XX'
   AND  FA.application_id = FLT.application_id
   AND  FLT.lookup_type = FLV.lookup_type(+)
   AND  FLV.start_date_active <= TRUNC(SYSDATE)
   AND  (FLV.end_date_active   >= TRUNC(SYSDATE)
         OR FLV.end_date_active IS NULL)
   AND  FLV.language(+) = 'JA'
   AND  FLT.lookup_type = FLTT.lookup_type(+)
   AND  FLT.view_application_id = FLTT.view_application_id(+)
   AND  FLT.security_group_id = FLTT.security_group_id(+)
   AND  FLTT.language(+) = 'JA'
   AND  FLT.application_id = FAT.application_id(+)
   AND  FAT.language = 'JA'
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  FLV.created_by        = FU_CB.user_id(+)
   --AND  FLV.last_updated_by   = FU_LU.user_id(+)
   --AND  FLV.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKZ_クイックコード_現在_V IS 'SKYLINK用クイックコード（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.参照タイプ         IS '参照タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.参照タイプ名       IS '参照タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.参照タイプ摘要     IS '参照タイプ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.アプリケーション名 IS 'アプリケーション名'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.参照コード         IS '参照コード'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.参照コード_内容    IS '参照コード_内容'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.参照コード_摘要    IS '参照コード_摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.コンテキスト       IS 'コンテキスト'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性１             IS '属性１'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性２             IS '属性２'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性３             IS '属性３'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性４             IS '属性４'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性５             IS '属性５'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性６             IS '属性６'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性７             IS '属性７'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性８             IS '属性８'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性９             IS '属性９'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性１０           IS '属性１０'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性１１           IS '属性１１'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性１２           IS '属性１２'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性１３           IS '属性１３'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性１４           IS '属性１４'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.属性１５           IS '属性１５'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_クイックコード_現在_V.最終更新ログイン   IS '最終更新ログイン'
/