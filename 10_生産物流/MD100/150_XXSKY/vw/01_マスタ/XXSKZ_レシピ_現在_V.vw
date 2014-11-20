/*************************************************************************
 * 
 * View  Name      : XXSKZ_レシピ_現在_V
 * Description     : XXSKZ_レシピ_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_レシピ_現在_V
(
 レシピ番号
,レシピ名称
,レシピ摘要
,バージョン
,ステータス
,ステータス名
,所有者組織コード
,所有者組織名
,作成組織コード
,作成組織名
,フォーミュラ番号
,フォーミュラ名称
,フォーミュラ名称２
,フォーミュラ摘要
,フォーミュラ摘要２
,工順番号
,工順名
,調達区分
,調達区分名
,包装難度
,管理区分
,管理区分名
,品目コード
,品目名
,品目略称
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,レシピ使用
,妥当性ルール日付_自
,妥当性ルール日付_至
,最小数量
,最大数量
,標準数量
,単位
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  GRB.recipe_no                        --レシピ番号
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,GRT.recipe_description               --レシピ名称
       ,(SELECT GRT.recipe_description
         FROM GMD_RECIPES_TL GRT      --レシピマスタ(言語)
         WHERE GRT.recipe_id = GRB.recipe_id
         AND   GRT.language  = 'JA'
        ) GRT_recipe_description
       --,GRT.recipe_description               --レシピ摘要
       ,(SELECT GRT.recipe_description
         FROM GMD_RECIPES_TL GRT      --レシピマスタ(言語)
         WHERE GRT.recipe_id = GRB.recipe_id
         AND   GRT.language  = 'JA'
        ) GRT_recipe_description2
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.recipe_version                   --バージョン
       ,GRB.recipe_status                    --ステータス
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,GQST.meaning                         --ステータス名
       ,(SELECT GQST.meaning
         FROM GMD_QC_STATUS_TL GQST     --
         WHERE GQST.status_code = GRB.recipe_status
         AND   GQST.language    = 'JA'
         AND   GQST.entity_type = 'S'
        ) GQST_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.owner_orgn_code                  --所有者組織コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,SOMT01.orgn_name                     --所有者組織名
       ,(SELECT SOMT01.orgn_name
         FROM SY_ORGN_MST_TL SOMT01   --OPMプラントマスタ日本語(所有者組織名)
         WHERE SOMT01.orgn_code = GRB.owner_orgn_code
         AND   SOMT01.language  = 'JA'
        ) SOMT01_orgn_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.creation_orgn_code               --作成組織コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,SOMT02.orgn_name                     --作成組織名
       ,(SELECT SOMT02.orgn_name
         FROM SY_ORGN_MST_TL SOMT02   --OPMプラントマスタ日本語(作成組織名)
         WHERE SOMT02.orgn_code = GRB.creation_orgn_code
         AND   SOMT02.language  = 'JA'
        ) SOMT02_orgn_name
       --,FFMB.formula_no                      --フォーミュラ番号
       ,(SELECT FFMB.formula_no
         FROM FM_FORM_MST_B FFMB     --フォーミュラマスタ
         WHERE FFMB.formula_id = GRB.formula_id
        ) FFMB_formula_no
       --,FFMT.formula_desc1                   --フォーミュラ名称
       ,(SELECT FFMT.formula_desc1
         FROM FM_FORM_MST_TL FFMT     --フォーミュラマスタ(日本語)
         WHERE FFMT.formula_id = GRB.formula_id
         AND   FFMT.language   = 'JA'
        ) FFMT_formula_desc1
       --,FFMT.formula_desc2                   --フォーミュラ名称２
       ,(SELECT FFMT.formula_desc2
         FROM FM_FORM_MST_TL FFMT     --フォーミュラマスタ(日本語)
         WHERE FFMT.formula_id = GRB.formula_id
         AND   FFMT.language   = 'JA'
        ) FFMT_formula_desc2
       --,FFMT.formula_desc1                   --フォーミュラ摘要
       ,(SELECT FFMT.formula_desc1
         FROM FM_FORM_MST_TL FFMT     --フォーミュラマスタ(日本語)
         WHERE FFMT.formula_id = GRB.formula_id
         AND   FFMT.language   = 'JA'
        ) FFMT_formula_desc11
       --,FFMT.formula_desc2                   --フォーミュラ摘要２
       ,(SELECT FFMT.formula_desc2
         FROM FM_FORM_MST_TL FFMT     --フォーミュラマスタ(日本語)
         WHERE FFMT.formula_id = GRB.formula_id
         AND   FFMT.language   = 'JA'
        ) FFMT_formula_desc22
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GROB.routing_no                      --工順番号
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,GROT.routing_desc                    --工順名
       ,(SELECT GROT.routing_desc
         FROM GMD_ROUTINGS_TL GROT     --工順マスタ(日本語)
         WHERE GROT.routing_id = GRB.routing_id
         AND   GROT.language   = 'JA'
        ) GROT_routing_desc
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute1                       --調達区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01    --クイックコード(調達区分名)
         WHERE FLV01.language    = 'JA'
         AND   FLV01.lookup_type = 'XXCMN_K02'
         AND   FLV01.lookup_code = GRB.attribute1
        ) tyoutatsu_kbn                        --調達区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute2                       --包装難度
       ,GRB.attribute3                       --管理区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02    --クイックコード(管理区分名)
         WHERE FLV02.language    = 'JA'
         AND   FLV02.lookup_type = 'XXCMN_K07'
         AND   FLV02.lookup_code = GRB.attribute3
        ) kanri_kbn                            --管理区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMV.item_no                         --品目コード
       ,XIMV.item_name                       --品目名
       ,XIMV.item_short_name                 --品目略称
       ,XPCV.prod_class_code                 --商品区分
       ,XPCV.prod_class_name                 --商品区分名
       ,XICV.item_class_code                 --品目区分
       ,XICV.item_class_name                 --品目区分名
       ,XCCV.crowd_code                      --群コード
       ,GRVR.recipe_use                      --レシピ使用
       ,GRVR.start_date                      --妥当性ルール日付_自
       ,GRVR.end_date                        --妥当性ルール日付_至
       ,GRVR.min_qty                         --最小数量
       ,GRVR.max_qty                         --最大数量
       ,GRVR.std_qty                         --標準数量
       ,GRVR.item_um                         --単位
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                      --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE GRB.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( GRB.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                             --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                      --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE GRB.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( GRB.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                             --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                      --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE GRB.last_update_login   = FL_LL.login_id
         AND   FL_LL.user_id           = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  GMD_RECIPES_B               GRB      --レシピマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,GMD_RECIPES_TL              GRT      --レシピマスタ(言語)
       --,GMD_QC_STATUS_TL            GQST     --
       --,SY_ORGN_MST_TL              SOMT01   --OPMプラントマスタ日本語(所有者組織名)
       --,SY_ORGN_MST_TL              SOMT02   --OPMプラントマスタ日本語(作成組織名)
       --,FM_FORM_MST_B               FFMB     --フォーミュラマスタ
       --,FM_FORM_MST_TL              FFMT     --フォーミュラマスタ(日本語)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
       ,GMD_ROUTINGS_B              GROB     --工順マスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,GMD_ROUTINGS_TL             GROT     --工順マスタ(日本語)
       --,fnd_lookup_values           FLV01    --クイックコード(調達区分名)
       --,fnd_lookup_values           FLV02    --クイックコード(管理区分名)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
       ,XXSKZ_ITEM_MST_V            XIMV     --品目情報VIEW
       ,XXSKZ_PROD_CLASS_V          XPCV     --商品区分情報VIEW
       ,XXSKZ_ITEM_CLASS_V          XICV     --品目区分情報VIEW
       ,XXSKZ_CROWD_CODE_V          XCCV     --郡コード情報VIEW
       ,GMD_RECIPE_VALIDITY_RULES   GRVR     --妥当性ルール
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,fnd_user                    FU_CB    --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                    FU_LU    --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                    FU_LL    --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins                  FL_LL    --ログインマスタ(last_update_login名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
WHERE   GROB.routing_class     <> '70'       --『品目振替』対象外
  AND   GRB.delete_mark         = 0          --『削除フラグ』が '1:削除'ではない
  AND   GROB.routing_id         = GRB.routing_id
  AND   GRB.recipe_id           = GRVR.recipe_id
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
  --AND   GRT.recipe_id(+)        = GRB.recipe_id
  --AND   GRT.language            = 'JA'
  --AND   GQST.status_code(+)     = GRB.recipe_status
  --AND   GQST.language(+)        = 'JA'
  --AND   GQST.entity_type(+)     = 'S'
  --AND   SOMT01.orgn_code(+)     = GRB.owner_orgn_code
  --AND   SOMT01.language         = 'JA'
  --AND   SOMT02.orgn_code(+)     = GRB.creation_orgn_code
  --AND   SOMT02.language         = 'JA'
  --AND   FFMB.formula_id(+)      = GRB.formula_id
  --AND   FFMT.formula_id(+)      = GRB.formula_id
  --AND   FFMT.language           = 'JA'
  --AND   GROT.routing_id(+)      = GRB.routing_id
  --AND   GROT.language           = 'JA'
  --AND   FLV01.language(+)       = 'JA'
  --AND   FLV01.lookup_type(+)    = 'XXCMN_K02'
  --AND   FLV01.lookup_code(+)    = GRB.attribute1
  --AND   FLV02.language(+)       = 'JA'
  --AND   FLV02.lookup_type(+)    = 'XXCMN_K07'
  --AND   FLV02.lookup_code(+)    = GRB.attribute3
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
  AND   XIMV.item_id(+)         = GRVR.item_id
  AND   XPCV.item_id(+)         = GRVR.item_id
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
  --AND   XICV.item_id(+)         = GRVR.item_id
  --AND   XCCV.item_id(+)         = GRVR.item_id
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
  AND   XICV.item_id            = XPCV.item_id
  AND   XCCV.item_id            = XPCV.item_id
  AND   XICV.item_id            = XCCV.item_id
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
  --AND   GRB.created_by          = FU_CB.user_id(+)
  --AND   GRB.last_updated_by     = FU_LU.user_id(+)
  --AND   GRB.last_update_login   = FL_LL.login_id(+)
  --AND   FL_LL.user_id           = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKZ_レシピ_現在_V IS 'SKYLINK用レシピマスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.レシピ番号                     IS 'レシピ番号'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.レシピ名称                     IS 'レシピ名称'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.レシピ摘要                     IS 'レシピ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.バージョン                     IS 'バージョン'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.ステータス                     IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.ステータス名                   IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.所有者組織コード               IS '所有者組織コード'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.所有者組織名                   IS '所有者組織名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.作成組織コード                 IS '作成組織コード'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.作成組織名                     IS '作成組織名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.フォーミュラ番号               IS 'フォーミュラ番号'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.フォーミュラ名称               IS 'フォーミュラ名称'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.フォーミュラ名称２             IS 'フォーミュラ名称２'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.フォーミュラ摘要               IS 'フォーミュラ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.フォーミュラ摘要２             IS 'フォーミュラ摘要２'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.工順番号                       IS '工順番号'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.工順名                         IS '工順名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.調達区分                       IS '調達区分'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.調達区分名                     IS '調達区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.包装難度                       IS '包装難度'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.管理区分                       IS '管理区分'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.管理区分名                     IS '管理区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.品目コード                     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.品目名                         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.品目略称                       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.品目区分                       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.品目区分名                     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.群コード                       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.レシピ使用                     IS 'レシピ使用'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.妥当性ルール日付_自            IS '妥当性ルール日付_自'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.妥当性ルール日付_至            IS '妥当性ルール日付_至'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.最小数量                       IS '最小数量'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.最大数量                       IS '最大数量'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.標準数量                       IS '標準数量'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.単位                           IS '単位'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_レシピ_現在_V.最終更新ログイン               IS '最終更新ログイン'
/
