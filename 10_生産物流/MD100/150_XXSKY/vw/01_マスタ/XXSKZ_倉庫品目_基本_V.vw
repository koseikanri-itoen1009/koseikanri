/*************************************************************************
 * 
 * View  Name      : XXSKZ_倉庫品目_基本_V
 * Description     : XXSKZ_倉庫品目_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_倉庫品目_基本_V
(
 元倉庫コード
,元倉庫名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,代表倉庫コード
,代表倉庫名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  XFIL.item_location_code         --元倉庫コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV1.description               --元倉庫名
       ,(SELECT XILV1.description
         FROM xxskz_item_locations_v XILV1  --OPM保管場所情報VIEW(元倉庫名用)
         WHERE XFIL.item_location_id = XILV1.inventory_location_id
        ) XILV1_description
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPCV.prod_class_code            --商品区分
       ,XPCV.prod_class_name            --商品区分名
       ,XICV.item_class_code            --品目区分
       ,XICV.item_class_name            --品目区分名
       ,XCCV.crowd_code                 --群コード
       ,XFIL.item_code                  --品目コード
       ,XIMV.item_name                  --品目名
       ,XIMV.item_short_name            --品目略称
       ,XFIL.frq_item_location_code     --代表倉庫コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV2.description               --代表倉庫名
       ,(SELECT XILV2.description
         FROM xxskz_item_locations_v XILV2  --OPM保管場所情報VIEW(代表倉庫名用)
         WHERE XFIL.frq_item_location_id = XILV2.inventory_location_id
        ) XILV2_description
       --,FU_CB.user_name                 --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XFIL.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XFIL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                 --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XFIL.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XFIL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                 --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XFIL.last_update_login    = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxwsh_frq_item_locations XFIL   --倉庫品目アドオンマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxsky_item_locations_v   XILV1  --OPM保管場所情報VIEW(元倉庫名用)
       --,xxsky_item_locations_v   XILV2  --OPM保管場所情報VIEW(代表倉庫名用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
       ,xxskz_prod_class_v       XPCV   --SKYLINK用 商品区分取得VIEW
       ,xxskz_item_class_v       XICV   --SKYLINK用 品目区分取得VIEW
       ,xxskz_crowd_code_v       XCCV   --SKYLINK用 郡コード取得VIEW
       ,xxskz_item_mst_v         XIMV   --OPM品目情報VIEW
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,fnd_user                 FU_CB  --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user                 FU_LU  --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user                 FU_LL  --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins               FL_LL  --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XFIL.item_id              = XPCV.item_id(+)
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
   --AND  XFIL.item_id              = XICV.item_id(+)
   --AND  XFIL.item_id              = XCCV.item_id(+)
   AND  XPCV.item_id              = XICV.item_id
   AND  XPCV.item_id              = XCCV.item_id
   AND  XICV.item_id              = XCCV.item_id
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
   AND  XFIL.item_id              = XIMV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XFIL.item_location_id     = XILV1.inventory_location_id(+)
   --AND  XFIL.frq_item_location_id = XILV2.inventory_location_id(+)
   --AND  XFIL.created_by           = FU_CB.user_id(+)
   --AND  XFIL.last_updated_by      = FU_LU.user_id(+)
   --AND  XFIL.last_update_login    = FL_LL.login_id(+)
   --AND  FL_LL.user_id             = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKZ_倉庫品目_基本_V IS 'SKYLINK用倉庫品目（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.元倉庫コード                   IS '元倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.元倉庫名                       IS '元倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.品目区分                       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.品目区分名                     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.群コード                       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.品目コード                     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.品目名                         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.品目略称                       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.代表倉庫コード                 IS '代表倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.代表倉庫名                     IS '代表倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫品目_基本_V.最終更新ログイン               IS '最終更新ログイン'
/
