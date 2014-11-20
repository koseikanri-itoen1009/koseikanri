/*************************************************************************
 * 
 * View  Name      : XXSKZ_ドリンク振替運賃_現在_V
 * Description     : XXSKZ_ドリンク振替運賃_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_ドリンク振替運賃_現在_V
(
 商品分類
,商品分類名
,配送区分
,配送区分名
,拠点大分類
,拠点大分類名
,適用開始日
,適用終了日
,設定単価
,ペナルティ単価
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        XDTDC.godds_classification          --商品分類
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning                       --商品分類名
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --クイックコード(商品分類名)
         WHERE FLV01.language   = 'JA'                        --言語
         AND  FLV01.lookup_type = 'XXCMN_D02'                 --クイックコードタイプ
         AND  FLV01.lookup_code = XDTDC.godds_classification  --クイックコード
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDTDC.dellivary_classe              --配送区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                       --配送区分名
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --クイックコード(配送区分名)
         WHERE FLV02.language   = 'JA'
         AND  FLV02.lookup_type = 'XXCMN_SHIP_METHOD'
         AND  FLV02.lookup_code = XDTDC.dellivary_classe
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDTDC.foothold_macrotaxonomy        --拠点大分類
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning                       --拠点大分類名
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --クイックコード(配送区分名)
         WHERE FLV03.language   = 'JA'
         AND  FLV03.lookup_type = 'XXWIP_BASE_MAJOR_DIVISION'
         AND  FLV03.lookup_code = XDTDC.foothold_macrotaxonomy
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDTDC.start_date_active             --適用開始日
       ,XDTDC.end_date_active               --適用終了日
       ,XDTDC.setting_amount                --設定単価
       ,XDTDC.penalty_amount                --ペナルティ単価
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                     --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XDTDC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XDTDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                     --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XDTDC.last_updated_by   = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XDTDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                     --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XDTDC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id           = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxwip_drink_trans_deli_chrgs XDTDC  --ドリンク振替運賃アドオンマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,fnd_user                     FU_CB  --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                     FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                     FU_LL  --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins                   FL_LL  --ログインマスタ(last_update_login名称取得用)
       --,fnd_lookup_values            FLV01  --クイックコード(商品分類名)
       --,fnd_lookup_values            FLV02  --クイックコード(配送区分名)
       --,fnd_lookup_values            FLV03  --クイックコード(拠点大分類名)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XDTDC.start_date_active <= TRUNC(SYSDATE)
   AND  XDTDC.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XDTDC.created_by        = FU_CB.user_id(+)
   --AND  XDTDC.last_updated_by   = FU_LU.user_id(+)
   --AND  XDTDC.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id           = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'                        --言語
   --AND  FLV01.lookup_type(+) = 'XXCMN_D02'                 --クイックコードタイプ
   --AND  FLV01.lookup_code(+) = XDTDC.godds_classification  --クイックコード
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   --AND  FLV02.lookup_code(+) = XDTDC.dellivary_classe
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXWIP_BASE_MAJOR_DIVISION'
   --AND  FLV03.lookup_code(+) = XDTDC.foothold_macrotaxonomy
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/  
COMMENT ON TABLE APPS.XXSKZ_ドリンク振替運賃_現在_V IS 'SKYLINK用ドリンク振替運賃（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.商品分類                       IS '商品分類'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.商品分類名                     IS '商品分類名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.配送区分                       IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.配送区分名                     IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.拠点大分類                     IS '拠点大分類'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.拠点大分類名                   IS '拠点大分類名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.適用開始日                     IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.適用終了日                     IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.設定単価                       IS '設定単価'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.ペナルティ単価                 IS 'ペナルティ単価'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク振替運賃_現在_V.最終更新ログイン               IS '最終更新ログイン'
/
