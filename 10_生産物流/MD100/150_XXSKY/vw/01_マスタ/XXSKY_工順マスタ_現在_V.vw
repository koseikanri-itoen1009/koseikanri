CREATE OR REPLACE VIEW APPS.XXSKY_工順マスタ_現在_V
(
 工順番号
,工順名
,工順略称
,有効_自
,有効_至
,区分
,区分名
,ライン区分
,ライン区分名
,ステータス
,ステータス名
,計画損失
,数量
,単位
,取引先
,取引先名
,賃率
,標準能力
,MIN能力
,MAX能力
,納品場所
,納品場所名
,工場区分
,工場区分名
,工場内ライン配分率
,リードタイム
,伝票区分
,伝票区分名
,成績管理部署
,成績管理部署名
,内外区分
,内外区分名
,製造品区分
,製造品区分名
,新缶煎区分
,新缶煎区分名
,HHT送信対象フラグ
,HHT送信対象フラグ名
,固有記号
,固有記号名
,作業部署
,作業部署名
,納品倉庫
,納品倉庫名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  GRB.routing_no                 --工順番号
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,GRT.routing_desc               --工順名
       ,(SELECT GRT.routing_desc
         FROM gmd_routings_tl GRT     --工順マスタ(言語)
         WHERE GRB.routing_id = GRT.routing_id
           AND  GRT.language  = 'JA'
        ) GRT_routing_desc      --ステータス名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute1                 --工順略称
       ,GRB.effective_start_date       --有効_自
       ,GRB.effective_end_date         --有効_至
       ,GRB.routing_class              --区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,GRCT.routing_class_desc        --区分名
       ,(SELECT GRCT.routing_class_desc
         FROM gmd_routing_class_tl GRCT   --工順区分マスタ日本語
         WHERE GRB.routing_class = GRCT.routing_class
           AND GRCT.language     = 'JA'
        ) GRCT_routing_class_desc      --ステータス名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute2                 --ライン区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --クイックコード(ライン区分名)
         WHERE FLV01.language    = 'JA'
           AND FLV01.lookup_type = 'XXCMN_PRODUCTION_LINE'
           AND FLV01.lookup_code = GRB.attribute2
        ) line_class_name                --ライン区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.routing_status             --ステータス
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,GQST.meaning
       ,(SELECT GQST.meaning
         FROM gmd_qc_status_tl GQST   --
         WHERE GQST.status_code = GRB.routing_status
           AND GQST.language    = 'JA'
           AND GQST.entity_type = 'S'
        ) status_name                    --ステータス名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.process_loss               --計画損失
       ,GRB.routing_qty                --数量
       ,GRB.item_um                    --単位
       ,GRB.attribute3                 --取引先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,IWM01.whse_name                --取引先名
       ,(SELECT IWM01.whse_name
         FROM ic_whse_mst IWM01  --倉庫(取引先名)
         WHERE IWM01.whse_code = GRB.attribute3
        ) IWM01_whse_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,NVL( TO_NUMBER( GRB.attribute5 ), 0 )
                                       --賃率
       ,NVL( TO_NUMBER( GRB.attribute6 ), 0 )
                                       --標準能力
       ,NVL( TO_NUMBER( GRB.attribute7 ), 0 )
                                       --MIN能力
       ,NVL( TO_NUMBER( GRB.attribute8 ), 0 )
                                       --MAX能力
       ,GRB.attribute9                 --納品場所
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,MIL.description                --納品場所名
       ,(SELECT MIL.description
         FROM mtl_item_locations MIL    --OPM保管場所マスタ
         WHERE MIL.segment1 = GRB.attribute9
        ) MIL_description
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute10                --工場区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --クイックコード(工場区分名)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXCMN_K04'
           AND FLV02.lookup_code = GRB.attribute10
        ) routing_class_name             --工場区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,NVL( TO_NUMBER( GRB.attribute11 ), 0 )
                                       --工場内ライン配分率
       ,NVL( TO_NUMBER( GRB.attribute12 ), 0 )
                                       --リードタイム
       ,GRB.attribute13                --伝票区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --クイックコード(伝票区分名)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXCMN_L03'
           AND FLV03.lookup_code = GRB.attribute13
        ) den_class_name                 --伝票区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute14                --成績管理部署
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV04.meaning
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04  --クイックコード(成績管理部署名)
         WHERE FLV04.language    = 'JA'
           AND FLV04.lookup_type = 'XXCMN_L10'
           AND FLV04.lookup_code = GRB.attribute14
        ) seise_class_name               --成績管理部署名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute15                --内外区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV05.meaning
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05  --クイックコード(内外区分名)
         WHERE FLV05.language    = 'JA'
           AND FLV05.lookup_type = 'XXWIP_IN_OUT_TYPE'
           AND FLV05.lookup_code = GRB.attribute15
        ) inout_class_name               --内外区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute16                --製造品区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV06.meaning
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06  --クイックコード(製造品区分名)
         WHERE FLV06.language    = 'JA'
           AND FLV06.lookup_type = 'XXWIP_PROD_TYPE'
           AND FLV06.lookup_code = GRB.attribute16
        ) seizo_class_name               --製造品区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute17                --新缶煎区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV07.meaning
       ,(SELECT FLV07.meaning
         FROM fnd_lookup_values FLV07  --クイックコード(新缶煎区分名)
         WHERE FLV07.language    = 'JA'
           AND FLV07.lookup_type = 'XXWIP_NEW_LINE'
           AND FLV07.lookup_code = GRB.attribute17
        ) sinka_class_name               --新缶煎区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute18                --HHT送信対象フラグ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV08.meaning
       ,(SELECT FLV08.meaning
         FROM fnd_lookup_values FLV08  --クイックコード(HHT送信対象フラグ名)
         WHERE FLV08.language    = 'JA'
           AND FLV08.lookup_type = 'XXWIP_HHT_FLAG'
           AND FLV08.lookup_code = GRB.attribute18
        ) hht_flg_name                   --HHT送信対象フラグ名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute19                --固有記号
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV09.meaning
       ,(SELECT FLV09.meaning
         FROM fnd_lookup_values FLV09  --クイックコード(固有記号名)
         WHERE FLV09.language    = 'JA'
           AND FLV09.lookup_type = 'XXCMN_PLANT_UNIQE_SIGN'
           AND FLV09.lookup_code = GRB.attribute19
        ) koyu_name                      --固有記号名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute20                --作業部署
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XLV.location_name              --作業部署名
       ,(SELECT XLV.location_name
         FROM xxsky_locations_v XLV    --事業所情報VIEW
         WHERE XLV.location_code = GRB.attribute20
        ) XLV_location_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,GRB.attribute21                --納品倉庫
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,IWM02.whse_name                --納品倉庫名
       ,(SELECT IWM02.whse_name
         FROM ic_whse_mst IWM02  --倉庫(納品倉庫名)
         WHERE IWM02.whse_code = GRB.attribute21
        ) IWM02_whse_name
       --,FU_CB.user_name                --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE GRB.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( GRB.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE GRB.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( GRB.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE GRB.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  gmd_routings_b          GRB    --工順マスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,gmd_routings_tl         GRT    --工順マスタ(言語)
       --,gmd_routing_class_tl    GRCT   --工順区分マスタ日本語
       --,gmd_qc_status_tl        GQST   --
       --,ic_whse_mst             IWM01  --倉庫(取引先名)
       --,mtl_item_locations      MIL    --OPM保管場所マスタ
       --,xxsky_locations_v       XLV    --事業所情報VIEW
       --,ic_whse_mst             IWM02  --倉庫(納品倉庫名)
       --,fnd_lookup_values       FLV01  --クイックコード(ライン区分名)
       --,fnd_lookup_values       FLV02  --クイックコード(工場区分名)
       --,fnd_lookup_values       FLV03  --クイックコード(伝票区分名)
       --,fnd_lookup_values       FLV04  --クイックコード(成績管理部署名)
       --,fnd_lookup_values       FLV05  --クイックコード(内外区分名)
       --,fnd_lookup_values       FLV06  --クイックコード(製造品区分名)
       --,fnd_lookup_values       FLV07  --クイックコード(新缶煎区分名)
       --,fnd_lookup_values       FLV08  --クイックコード(HHT送信対象フラグ名)
       --,fnd_lookup_values       FLV09  --クイックコード(固有記号名)
       --,fnd_user                FU_CB  --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                FU_LL  --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins              FL_LL  --ログインマスタ(last_update_login名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  GRB.delete_mark        = 0
   AND  TRUNC(GRB.effective_start_date) <= TRUNC(SYSDATE)
   AND (TRUNC(GRB.effective_end_date)   >= TRUNC(SYSDATE)
           OR GRB.effective_end_date IS NULL)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  GRB.routing_id         = GRT.routing_id(+)
   --AND  GRT.language(+)        = 'JA'
   --AND  GRB.routing_class      = GRCT.routing_class(+)
   --AND  GRCT.language(+)       = 'JA'
   --AND  GQST.status_code(+)    = GRB.routing_status
   --AND  GQST.language(+)       = 'JA'
   --AND  GQST.entity_type(+)    = 'S'
   --AND  IWM01.whse_code(+)     = GRB.attribute3
   --AND  IWM02.whse_code(+)     = GRB.attribute21
   --AND  MIL.segment1(+)        = GRB.attribute9
   --AND  XLV.location_code(+)   = GRB.attribute20
   --AND  GRB.attribute21        = IWM02.whse_code(+)
   --AND  FLV01.language(+)      = 'JA'
   --AND  FLV01.lookup_type(+)   = 'XXCMN_PRODUCTION_LINE'
   --AND  FLV01.lookup_code(+)   = GRB.attribute2
   --AND  FLV02.language(+)      = 'JA'
   --AND  FLV02.lookup_type(+)   = 'XXCMN_K04'
   --AND  FLV02.lookup_code(+)   = GRB.attribute10
   --AND  FLV03.language(+)      = 'JA'
   --AND  FLV03.lookup_type(+)   = 'XXCMN_L03'
   --AND  FLV03.lookup_code(+)   = GRB.attribute13
   --AND  FLV04.language(+)      = 'JA'
   --AND  FLV04.lookup_type(+)   = 'XXCMN_L10'
   --AND  FLV04.lookup_code(+)   = GRB.attribute14
   --AND  FLV05.language(+)      = 'JA'
   --AND  FLV05.lookup_type(+)   = 'XXWIP_IN_OUT_TYPE'
   --AND  FLV05.lookup_code(+)   = GRB.attribute15
   --AND  FLV06.language(+)      = 'JA'
   --AND  FLV06.lookup_type(+)   = 'XXWIP_PROD_TYPE'
   --AND  FLV06.lookup_code(+)   = GRB.attribute16
   --AND  FLV07.language(+)      = 'JA'
   --AND  FLV07.lookup_type(+)   = 'XXWIP_NEW_LINE'
   --AND  FLV07.lookup_code(+)   = GRB.attribute17
   --AND  FLV08.language(+)      = 'JA'
   --AND  FLV08.lookup_type(+)   = 'XXWIP_HHT_FLAG'
   --AND  FLV08.lookup_code(+)   = GRB.attribute18
   --AND  FLV09.language(+)      = 'JA'
   --AND  FLV09.lookup_type(+)   = 'XXCMN_PLANT_UNIQE_SIGN'
   --AND  FLV09.lookup_code(+)   = GRB.attribute19
   --AND  GRB.created_by         = FU_CB.user_id(+)
   --AND  GRB.last_updated_by    = FU_LU.user_id(+)
   --AND  GRB.last_update_login  = FL_LL.login_id(+)
   --AND  FL_LL.user_id          = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKY_工順マスタ_現在_V IS 'SKYLINK用工順マスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.工順番号                       IS '工順番号'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.工順名                         IS '工順名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.工順略称                       IS '工順略称'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.有効_自                        IS '有効_自'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.有効_至                        IS '有効_至'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.区分                           IS '区分'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.区分名                         IS '区分名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.ライン区分                     IS 'ライン区分'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.ライン区分名                   IS 'ライン区分名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.ステータス                     IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.ステータス名                   IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.計画損失                       IS '計画損失'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.数量                           IS '数量'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.単位                           IS '単位'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.取引先                         IS '取引先'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.取引先名                       IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.賃率                           IS '賃率'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.標準能力                       IS '標準能力'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.MIN能力                        IS 'MIN能力'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.MAX能力                        IS 'MAX能力'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.納品場所                       IS '納品場所'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.納品場所名                     IS '納品場所名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.工場区分                       IS '工場区分'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.工場区分名                     IS '工場区分名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.工場内ライン配分率             IS '工場内ライン配分率'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.リードタイム                   IS 'リードタイム'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.伝票区分                       IS '伝票区分'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.伝票区分名                     IS '伝票区分名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.成績管理部署                   IS '成績管理部署'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.成績管理部署名                 IS '成績管理部署名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.内外区分                       IS '内外区分'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.内外区分名                     IS '内外区分名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.製造品区分                     IS '製造品区分'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.製造品区分名                   IS '製造品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.新缶煎区分                     IS '新缶煎区分'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.新缶煎区分名                   IS '新缶煎区分名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.HHT送信対象フラグ              IS 'HHT送信対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.HHT送信対象フラグ名            IS 'HHT送信対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.固有記号                       IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.固有記号名                     IS '固有記号名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.作業部署                       IS '作業部署'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.作業部署名                     IS '作業部署名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.納品倉庫                       IS '納品倉庫'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.納品倉庫名                     IS '納品倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_工順マスタ_現在_V.最終更新ログイン               IS '最終更新ログイン'
/
