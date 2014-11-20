CREATE OR REPLACE VIEW APPS.XXSKY_フォーミュラ_現在_V
(
 フォーミュラ番号
,フォーミュラ名称
,フォーミュラ名称２
,フォーミュラ摘要
,フォーミュラ摘要２
,バージョン
,スケーリング可
,ステータス
,ステータス名
,調合量
,調合量_単位
,内容量
,内容量_単位
,密度
,工場固有記号
,初回生産日
,パッカー
,パッカー名
,生産工場
,生産工場名
,振替半製品
,振替半製品名
,原料分解要否
,原料分解要否名
,歩留計算要否
,歩留計算要否名
,オンラインフラグ
,オンラインフラグ名
,明細タイプ
,明細タイプ名
,明細番号
,品目コード
,品目名
,品目略称
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,数量
,単位
,収率タイプ
,収率タイプ名
,メーカー
,メーカー名
,配合率
,一本当り使用量
,一本当り使用量_単位
,基準単価
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  FFMB.formula_no                 --フォーミュラ番号
       ,FFMT.formula_desc1              --フォーミュラ名称
       ,FFMT.formula_desc2              --フォーミュラ名称２
       ,FFMT.formula_desc1              --フォーミュラ摘要
       ,FFMT.formula_desc2              --フォーミュラ摘要２
       ,FFMB.formula_vers               --バージョン
       ,FFMB.scale_type                 --スケーリング可
       ,FFMB.formula_status             --ステータス
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,GQST.meaning                    --ステータス名
       ,(SELECT GQST.meaning
         FROM gmd_qc_status_tl        GQST    --
         WHERE GQST.status_code = FFMB.formula_status
         AND   GQST.language    = 'JA'
         AND   GQST.entity_type = 'S'
        ) GQST_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,NVL( TO_NUMBER( FFMB.attribute1 ), 0 )
                                        --調合量
       ,FFMB.attribute2                 --調合量_単位
       ,NVL( TO_NUMBER( FFMB.attribute3 ), 0 )
                                        --内容量
       ,FFMB.attribute4                 --内容量_単位
       ,NVL( TO_NUMBER( FFMB.attribute5 ), 0 )
                                        --密度
       ,FFMB.attribute6                 --工場固有記号
       ,FFMB.attribute7                 --初回生産日
       ,FFMB.attribute8                 --パッカー
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV01.vendor_name               --パッカー名
       ,(SELECT XVV01.vendor_name
         FROM xxsky_vendors_v XVV01   --仕入先情報VIEW(パッカー名)
         WHERE XVV01.segment1 = FFMB.attribute8
        ) XVV01_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,FFMB.attribute9                 --生産工場
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVSV.vendor_site_name           --生産工場名
       ,(SELECT XVSV.vendor_site_name
         FROM xxsky_vendor_sites_v XVSV    --仕入先サイト情報VIEW
         WHERE XVSV.vendor_site_code = FFMB.attribute9
        ) XVSV_vendor_site_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,FFMB.attribute10                --振替半製品
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XIMV01.item_name                --振替半製品名
       ,(SELECT XIMV01.item_name
         FROM xxsky_item_mst_v XIMV01  --品目情報VIEW(振替半製品名)
         WHERE XIMV01.item_no = FFMB.attribute10
        ) XIMV01_item_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,FFMB.attribute11                --原料分解要否
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01   --クイックコード(原料分解要否名)
         WHERE FLV01.language    = 'JA'
         AND   FLV01.lookup_type = 'XXCMN_MATER_ANALY'
         AND   FLV01.lookup_code = FFMB.attribute11
        ) gen_bunkai_youhi                --原料分解要否名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,FFMB.attribute12                --歩留計算要否
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02   --クイックコード(歩留計算要否名)
         WHERE FLV02.language    = 'JA'
         AND   FLV02.lookup_type = 'XXCMN_YIELD_COUNT'
         AND   FLV02.lookup_code = FFMB.attribute12
        ) budomari_keisan_youhi           --歩留計算要否名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,FFMB.attribute13                --オンラインフラグ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03   --クイックコード(オンラインフラグ名)
         WHERE FLV03.language    = 'JA'
         AND   FLV03.lookup_type = 'XXCMN_ONLINE_FLAG'
         AND   FLV03.lookup_code = FFMB.attribute13
        ) online_flag                     --オンラインフラグ名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,FMD.line_type                   --明細タイプ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV04.meaning
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04   --クイックコード(明細タイプ名)
         WHERE FLV04.language    = 'JA'
         AND   FLV04.lookup_type = 'GMD_FORMULA_ITEM_TYPE'
         AND   FLV04.lookup_code = FMD.line_type
        ) line_type_name                  --明細タイプ名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,FMD.line_no                     --明細番号
       ,XIMV02.item_no                  --品目コード
       ,XIMV02.item_name                --品目名
       ,XIMV02.item_short_name          --品目略称
       ,XPCV.prod_class_code            --商品区分
       ,XPCV.prod_class_name            --商品区分名
       ,XICV.item_class_code            --品目区分
       ,XICV.item_class_name            --品目区分名
       ,XCCV.crowd_code                 --群コード
       ,FMD.qty                         --数量
       ,FMD.item_um                     --単位
       ,FMD.release_type                --収率タイプ
       ,DECODE(FMD.release_type, 0, '自動', 1, '手動')    --収率タイプ名
       ,FMD.attribute1                  --メーカー
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV02.vendor_name               --メーカー名
       ,(SELECT XVV02.vendor_name
         FROM xxsky_vendors_v XVV02   --仕入先情報VIEW(メーカー名)
         WHERE XVV02.segment1 = FMD.attribute1
        ) XVV02_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,NVL( TO_NUMBER( FMD.attribute2 ), 0 )
                                        --配合率
       ,NVL( TO_NUMBER( FMD.attribute3 ), 0 )
                                        --一本当り使用量
       ,FMD.attribute4                  --一本当り使用量_単位
       ,NVL(TO_NUMBER(FMD.attribute5), 0)
                                        --基準単価
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                 --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE FFMB.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( FFMB.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                 --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE FFMB.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( FFMB.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                 --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE FFMB.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  fm_form_mst_b           FFMB    --フォーミュラマスタ
       ,fm_form_mst_tl          FFMT    --フォーミュラマスタ(言語)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,gmd_qc_status_tl        GQST    --
       --,xxsky_vendors_v         XVV01   --仕入先情報VIEW(パッカー名)
       --,xxsky_vendor_sites_v    XVSV    --仕入先サイト情報VIEW
       --,xxsky_item_mst_v        XIMV01  --品目情報VIEW(振替半製品名)
       --,fnd_lookup_values       FLV01   --クイックコード(原料分解要否名)
       --,fnd_lookup_values       FLV02   --クイックコード(歩留計算要否名)
       --,fnd_lookup_values       FLV03   --クイックコード(オンラインフラグ名)
       --,fnd_lookup_values       FLV04   --クイックコード(明細タイプ名)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
       ,fm_matl_dtl             FMD     --フォーミュラマスタ明細
       ,xxsky_item_mst_v        XIMV02  --品目情報VIEW(明細品目名)
       ,xxsky_prod_class_v      XPCV    --商品区分情報VIEW
       ,xxsky_item_class_v      XICV    --品目区分情報VIEW
       ,xxsky_crowd_code_v      XCCV    --郡コード情報VIEW
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxsky_vendors_v         XVV02   --仕入先情報VIEW(メーカー名)
       --,fnd_user                FU_CB   --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                FU_LU   --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                FU_LL   --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins              FL_LL   --ログインマスタ(last_update_login名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
WHERE   SUBSTRB( FFMB.formula_no, 8, 3 ) <> '-9-'        --『品目振替』対象外
  AND   FFMB.delete_mark         = 0
  AND   FFMB.formula_id          = FMD.formula_id
  AND   FFMT.formula_id(+)       = FFMB.formula_id
  AND   FFMT.language(+)         = 'JA'
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
  --AND   GQST.status_code(+)      = FFMB.formula_status
  --AND   GQST.language(+)         = 'JA'
  --AND   GQST.entity_type(+)      = 'S'
  --AND   XVV01.segment1(+)        = FFMB.attribute8
  --AND   XVSV.vendor_site_code(+) = FFMB.attribute9
  --AND   XIMV01.item_no(+)        = FFMB.attribute10
  --AND   XIMV02.item_id(+)        = FMD.item_id
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
  AND   XIMV02.item_id        = FMD.item_id
  AND   XPCV.item_id(+)          = FMD.item_id
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
  --AND   XICV.item_id(+)          = FMD.item_id
  --AND   XCCV.item_id(+)          = FMD.item_id
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
  AND   XPCV.item_id             = XICV.item_id
  AND   XPCV.item_id             = XCCV.item_id
  AND   XICV.item_id             = XCCV.item_id
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
  --AND   XVV02.segment1(+)        = FMD.attribute1
  --AND   FLV01.language(+)        = 'JA'
  --AND   FLV01.lookup_type(+)     = 'XXCMN_MATER_ANALY'
  --AND   FLV01.lookup_code(+)     = FFMB.attribute11
  --AND   FLV02.language(+)        = 'JA'
  --AND   FLV02.lookup_type(+)     = 'XXCMN_YIELD_COUNT'
  --AND   FLV02.lookup_code(+)     = FFMB.attribute12
  --AND   FLV03.language(+)        = 'JA'
  --AND   FLV03.lookup_type(+)     = 'XXCMN_ONLINE_FLAG'
  --AND   FLV03.lookup_code(+)     = FFMB.attribute13
  --AND   FLV04.language(+)        = 'JA'
  --AND   FLV04.lookup_type(+)     = 'GMD_FORMULA_ITEM_TYPE'
  --AND   FLV04.lookup_code(+)     = FMD.line_type
  --AND   FFMB.created_by          = FU_CB.user_id(+)
  --AND   FFMB.last_updated_by     = FU_LU.user_id(+)
  --AND   FFMB.last_update_login   = FL_LL.login_id(+)
  --AND   FL_LL.user_id            = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKY_フォーミュラ_現在_V IS 'SKYLINK用フォーミュラマスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.フォーミュラ番号               IS 'フォーミュラ番号'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.フォーミュラ名称               IS 'フォーミュラ名称'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.フォーミュラ名称２             IS 'フォーミュラ名称２'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.フォーミュラ摘要               IS 'フォーミュラ摘要'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.フォーミュラ摘要２             IS 'フォーミュラ摘要２'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.バージョン                     IS 'バージョン'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.スケーリング可                 IS 'スケーリング可'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.ステータス                     IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.ステータス名                   IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.調合量                         IS '調合量'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.調合量_単位                    IS '調合量_単位'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.内容量                         IS '内容量'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.内容量_単位                    IS '内容量_単位'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.密度                           IS '密度'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.工場固有記号                   IS '工場固有記号'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.初回生産日                     IS '初回生産日'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.パッカー                       IS 'パッカー'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.パッカー名                     IS 'パッカー名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.生産工場                       IS '生産工場'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.生産工場名                     IS '生産工場名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.振替半製品                     IS '振替半製品'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.振替半製品名                   IS '振替半製品名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.原料分解要否                   IS '原料分解要否'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.原料分解要否名                 IS '原料分解要否名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.歩留計算要否                   IS '歩留計算要否'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.歩留計算要否名                 IS '歩留計算要否名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.オンラインフラグ               IS 'オンラインフラグ'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.オンラインフラグ名             IS 'オンラインフラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.明細タイプ                     IS '明細タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.明細タイプ名                   IS '明細タイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.明細番号                       IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.品目コード                     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.品目名                         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.品目略称                       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.品目区分                       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.品目区分名                     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.群コード                       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.数量                           IS '数量'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.単位                           IS '単位'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.収率タイプ                     IS '収率タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.収率タイプ名                   IS '収率タイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.メーカー                       IS 'メーカー'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.メーカー名                     IS 'メーカー名'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.配合率                         IS '配合率'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.一本当り使用量                 IS '一本当り使用量'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.一本当り使用量_単位            IS '一本当り使用量_単位'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.基準単価                       IS '基準単価'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_フォーミュラ_現在_V.最終更新ログイン               IS '最終更新ログイン'
/
