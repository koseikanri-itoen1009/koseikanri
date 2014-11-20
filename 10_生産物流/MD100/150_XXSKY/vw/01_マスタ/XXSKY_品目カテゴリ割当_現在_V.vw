CREATE OR REPLACE VIEW APPS.XXSKY_品目カテゴリ割当_現在_V
(
 品目コード
,品目名
,品目略称
,品目カナ名
,適用開始日
,適用終了日
,群コード
,政策群コード
,マーケ用群コード
,経理部用群コード
,商品製品区分
,商品製品区分名
,商品区分
,商品区分名
,本社商品区分
,本社商品区分名
,品目区分
,品目区分名
,品質区分
,品質区分名
,バラ茶区分
,バラ茶区分名
,内外区分
,内外区分名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  IIMB.item_no                  item_no                 --品目コード
       ,XIMB.item_name                item_name               --品目名
       ,XIMB.item_short_name          item_short_name         --品目略称
       ,XIMB.item_name_alt            item_name_alt           --品目カナ名
       ,XIMB.start_date_active        start_date_active       --適用開始日
       ,XIMB.end_date_active          end_date_active         --適用終了日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,IC01.crowd_code               crowd_code              --群コード
       ,( SELECT MCB.segment1                                 --群コード
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '群コード'
            AND  XIMB.item_id = GIC.item_id
        )  crowd_code
       --,IC02.crowd_s_code             crowd_s_code            --政策群コード
       ,( SELECT MCB.segment1                                 --政策群コード
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '政策群コード'
            AND  XIMB.item_id = GIC.item_id
        )  crowd_s_code
       --,IC03.crowd_m_code             crowd_m_code            --マーケ用群コード
       ,( SELECT MCB.segment1                                 --マーケ用群コード
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = 'マーケ用群コード'
            AND  XIMB.item_id = GIC.item_id
        )  crowd_m_code
       --,IC04.crowd_k_code             crowd_k_code            --経理部用群コード
       ,( SELECT MCB.segment1                                 --経理部用群コード
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '経理部用群コード'
            AND  XIMB.item_id = GIC.item_id
        )  crowd_k_code
       --,IC05.prod_item_class          prod_item_class         --商品製品区分
       ,( SELECT MCB.segment1                                 --商品製品区分
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '商品製品区分'
            AND  XIMB.item_id = GIC.item_id
        )  prod_item_class
       --,IC05.prod_item_class_name     prod_item_class_name    --商品製品区分名
       ,( SELECT MCT.description                              --商品製品区分名
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '商品製品区分'
            AND  XIMB.item_id = GIC.item_id
        )  prod_item_class_name
       --,IC06.prod_class               prod_class              --商品区分
       ,( SELECT MCB.segment1                                 --商品区分
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '商品区分'
            AND  XIMB.item_id = GIC.item_id
        )  prod_class
       --,IC06.prod_class_name          prod_class_name         --商品区分名
       ,( SELECT MCT.description                              --商品区分名
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '商品区分'
            AND  XIMB.item_id = GIC.item_id
        )  prod_class_name
       --,IC07.prod_class_h             prod_class_h            --本社商品区分
       ,( SELECT MCB.segment1                                 --本社商品区分
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '本社商品区分'
            AND  XIMB.item_id = GIC.item_id
        )  prod_class_h
       --,IC07.prod_class_h_name        prod_class_h_name       --本社商品区分名
       ,( SELECT MCT.description                              --本社商品区分名
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '本社商品区分'
            AND  XIMB.item_id = GIC.item_id
        )  prod_class_h_name
       --,IC08.item_class               item_class              --品目区分
       ,( SELECT MCB.segment1                                 --品目区分
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '品目区分'
            AND  XIMB.item_id = GIC.item_id
        )  item_class
       --,IC08.item_class_name          item_class_name         --品目区分名
       ,( SELECT MCT.description                              --品目区分名
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '品目区分'
            AND  XIMB.item_id = GIC.item_id
        )  item_class_name
       --,IC09.quality_class            quality_class           --品質区分
       ,( SELECT MCB.segment1                                 --品質区分
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '品質区分'
            AND  XIMB.item_id = GIC.item_id
        )  quality_class
       --,IC09.quality_class_name       quality_class_name      --品質区分名
       ,( SELECT MCT.description                              --品質区分名
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '品質区分'
            AND  XIMB.item_id = GIC.item_id
        )  quality_class_name
       --,IC10.b_tea_class              b_tea_class             --バラ茶区分
       ,( SELECT MCB.segment1                                 --バラ茶区分
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = 'バラ茶区分'
            AND  XIMB.item_id = GIC.item_id
        )  b_tea_class
       --,IC10.b_tea_class_name         b_tea_class_name        --バラ茶区分名
       ,( SELECT MCT.description                              --バラ茶区分名
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = 'バラ茶区分'
            AND  XIMB.item_id = GIC.item_id
        )  b_tea_class_name
       --,IC11.in_out_class             in_out_class            --内外区分
       ,( SELECT MCB.segment1                                 --内外区分
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '内外区分'
            AND  XIMB.item_id = GIC.item_id
        )  in_out_class
       --,IC11.in_out_class_name        in_out_class_name       --内外区分名
       ,( SELECT MCT.description                              --内外区分名
           FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
                ,mtl_categories_b       MCB                   --品目カテゴリマスタ
                ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
                ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
          WHERE  GIC.category_id = MCB.category_id
            AND  MCB.category_id = MCT.category_id
            AND  MCT.language = 'JA'
            AND  MCT.source_lang = 'JA'
            AND  GIC.category_set_id = MCS.category_set_id
            AND  MCS.language = 'JA'
            AND  MCS.source_lang = 'JA'
            AND  MCS.category_set_name = '内外区分'
            AND  XIMB.item_id = GIC.item_id
        )  in_out_class_name
       --,FU_CB.user_name               created_by_name         --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XIMB.created_by = FU_CB.user_id
        ) created_by_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XIMB.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                      creation_date           --作成日時
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name               last_updated_by_name    --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XIMB.last_updated_by = FU_LU.user_id
        ) last_updated_by_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XIMB.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                      last_update_date        --更新日時
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name               last_update_login_name  --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XIMB.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) last_update_login_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  ic_item_mst_b                 IIMB                    --OPM品目マスタ
       ,xxcmn_item_mst_b              XIMB                    --品目マスタアドオン
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
        --群コード
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          crowd_code             --群コード
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '群コード'
       -- )  IC01
        --政策群コード
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          crowd_s_code           --政策群コード
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '政策群コード'
       -- )  IC02
        --マーケ用群コード
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          crowd_m_code           --マーケ用群コード
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = 'マーケ用群コード'
       -- )  IC03
        --経理部用群コード
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          crowd_k_code           --経理部用群コード
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '経理部用群コード'
       -- )  IC04
        --商品製品区分
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          prod_item_class        --商品製品区分
       --         ,MCT.description       prod_item_class_name   --商品製品区分名
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '商品製品区分'
       -- )  IC05
        --商品区分
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          prod_class             --商品区分
       --         ,MCT.description       prod_class_name        --商品区分名
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '商品区分'
       -- )  IC06
        --本社商品区分
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          prod_class_h           --本社商品区分
       --         ,MCT.description       prod_class_h_name      --本社商品区分名
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '本社商品区分'
       -- )  IC07
        --品目区分
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          item_class             --品目区分
       --         ,MCT.description       item_class_name        --品目区分名
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '品目区分'
       -- )  IC08
        --品質区分
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          quality_class          --品質区分
       --         ,MCT.description       quality_class_name     --品質区分名
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '品質区分'
       -- )  IC09
        --バラ茶区分
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          b_tea_class            --バラ茶区分
       --         ,MCT.description       b_tea_class_name       --バラ茶区分名
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = 'バラ茶区分'
       -- )  IC10
        --内外区分
       --,( SELECT GIC.item_id
       --         ,MCB.segment1          in_out_class           --内外区分
       --         ,MCT.description       in_out_class_name      --内外区分名
       --    FROM  gmi_item_categories    GIC                   --OPM品目カテゴリ割当
       --         ,mtl_categories_b       MCB                   --品目カテゴリマスタ
       --         ,mtl_categories_tl      MCT                   --品目カテゴリマスタ日本語
       --         ,mtl_category_sets_tl   MCS                   --品目カテゴリセット日本語
       --   WHERE  GIC.category_id = MCB.category_id
       --     AND  MCB.category_id = MCT.category_id
       --     AND  MCT.language = 'JA'
       --     AND  MCT.source_lang = 'JA'
       --     AND  GIC.category_set_id = MCS.category_set_id
       --     AND  MCS.language = 'JA'
       --     AND  MCS.source_lang = 'JA'
       --     AND  MCS.category_set_name = '内外区分'
       -- )  IC11
       --,fnd_user                    FU_CB                     --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user                    FU_LU                     --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user                    FU_LL                     --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins                  FL_LL                     --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  IIMB.inactive_ind <> '1'
   AND  XIMB.obsolete_class <> '1'
   AND  XIMB.start_date_active <= TRUNC(SYSDATE)
   AND  XIMB.end_date_active   >= TRUNC(SYSDATE)
   AND  IIMB.item_id = XIMB.item_id
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XIMB.item_id = IC01.item_id(+)
   --AND  XIMB.item_id = IC02.item_id(+)
   --AND  XIMB.item_id = IC03.item_id(+)
   --AND  XIMB.item_id = IC04.item_id(+)
   --AND  XIMB.item_id = IC05.item_id(+)
   --AND  XIMB.item_id = IC06.item_id(+)
   --AND  XIMB.item_id = IC07.item_id(+)
   --AND  XIMB.item_id = IC08.item_id(+)
   --AND  XIMB.item_id = IC09.item_id(+)
   --AND  XIMB.item_id = IC10.item_id(+)
   --AND  XIMB.item_id = IC11.item_id(+)
   --WHOカラム取得
   --AND  XIMB.created_by = FU_CB.user_id(+)
   --AND  XIMB.last_updated_by = FU_LU.user_id(+)
   --AND  XIMB.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKY_品目カテゴリ割当_現在_V IS 'SKYLINK用品目カテゴリ割当（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.品目コード        IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.品目名            IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.品目略称          IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.品目カナ名        IS '品目カナ名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.適用開始日        IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.適用終了日        IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.群コード          IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.政策群コード      IS '政策群コード'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.マーケ用群コード  IS 'マーケ用群コード'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.経理部用群コード  IS '経理部用群コード'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.商品製品区分      IS '商品製品区分'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.商品製品区分名    IS '商品製品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.商品区分          IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.商品区分名        IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.本社商品区分      IS '本社商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.本社商品区分名    IS '本社商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.品目区分          IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.品目区分名        IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.品質区分          IS '品質区分'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.品質区分名        IS '品質区分名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.バラ茶区分        IS 'バラ茶区分'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.バラ茶区分名      IS 'バラ茶区分名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.内外区分          IS '内外区分'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.内外区分名        IS '内外区分名'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.作成者            IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.作成日            IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.最終更新者        IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.最終更新日        IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_品目カテゴリ割当_現在_V.最終更新ログイン  IS '最終更新ログイン'
/
