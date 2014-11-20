CREATE OR REPLACE VIEW APPS.XXSKY_事業所マスタ_基本_V
(
 事業所コード
,事業所名
,事業所略称
,事業所カナ名
,適用開始日
,適用終了日
,郵便番号
,住所
,電話番号
,FAX番号
,本部コード
,失効日
,使用用途
,使用用途名
,出荷管理元区分
,出荷管理元区分名
,購買担当フラグ
,購買担当フラグ名
,出荷担当フラグ
,出荷担当フラグ名
,担当職責１
,担当職責２
,担当職責３
,担当職責４
,担当職責５
,担当職責６
,担当職責７
,担当職責８
,担当職責９
,担当職責１０
,親事業所コード
,親事業所名
,他拠点出荷依頼作成可否区分
,他拠点出荷依頼作成可否区分名
,地区コード
,地区名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  HLA.location_code              --事業所コード
       ,XLA.location_name              --事業所名
       ,XLA.location_short_name        --事業所略称
       ,XLA.location_name_alt          --事業所カナ名
       ,XLA.start_date_active          --適用開始日
       ,XLA.end_date_active            --適用終了日
       ,XLA.zip                        --郵便番号
       ,XLA.address_line1              --住所
       ,XLA.phone                      --電話番号
       ,XLA.fax                        --FAX番号
       ,XLA.division_code              --本部コード
       ,HLA.inactive_date              --失効日
       ,HLA.attribute_category         --使用用途
       ,DECODE(HLA.attribute_category, 'DEPT','部署', 'WHS','倉庫' )  --使用用途名
       ,HLA.attribute1                 --出荷管理元区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                  --出荷管理元区分名
       ,(SELECT FLV02.meaning
           FROM fnd_lookup_values FLV02    --クイックコード(出荷管理元区分名)
          WHERE FLV02.language    = 'JA'
           AND  FLV02.lookup_type = 'XXCMN_SHIPMENT_MANAGEMENT'
           AND  FLV02.lookup_code = HLA.attribute1
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,HLA.attribute3                 --購買担当フラグ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning                  --購買担当フラグ名
       ,(SELECT FLV03.meaning
           FROM fnd_lookup_values FLV03    --クイックコード(購買担当フラグ名)
          WHERE FLV03.language    = 'JA'
            AND FLV03.lookup_type = 'XXCMN_PURCHASING_FLAG'
            AND FLV03.lookup_code = HLA.attribute3
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,HLA.attribute4                 --出荷担当フラグ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV04.meaning                  --出荷担当フラグ名
       ,(SELECT FLV04.meaning
           FROM fnd_lookup_values FLV04    --クイックコード(出荷担当フラグ名)
          WHERE FLV04.language    = 'JA'
            AND FLV04.lookup_type = 'XXCMN_SHIPPING_FLAG'
            AND FLV04.lookup_code = HLA.attribute4
        ) FLV04_meaning
       --,RES01.responsibility_name      --担当職責１
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute5)  = FR.responsibility_id
        ) RES01_responsibility_name
       --,RES02.responsibility_name      --担当職責２
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute6)  = FR.responsibility_id
        ) RES02_responsibility_name
       --,RES03.responsibility_name      --担当職責３
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute7)  = FR.responsibility_id
        )  RES03_responsibility_name
       --,RES04.responsibility_name      --担当職責４
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute8)  = FR.responsibility_id
        )  RES04_responsibility_name
       --,RES05.responsibility_name      --担当職責５
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute9)  = FR.responsibility_id
        )  RES05_responsibility_name
       --,RES06.responsibility_name      --担当職責６
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute10) = FR.responsibility_id
        )  RES06_responsibility_name
       --,RES07.responsibility_name      --担当職責７
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute11) = FR.responsibility_id
        )  RES07_responsibility_name
       --,RES08.responsibility_name      --担当職責８
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute12) = FR.responsibility_id
        )  RES08_responsibility_name
       --,RES09.responsibility_name      --担当職責９
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute13) = FR.responsibility_id
        )  RES09_responsibility_name
       --,RES10.responsibility_name      --担当職責１０
       ,(SELECT FR.responsibility_name
           FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
               ,fnd_application         FA       --アプリケーションマスタ
          WHERE FA.application_short_name = 'XXCMN'
            AND FR.application_id = FA.application_id
            AND FR.language = 'JA'
            AND TO_NUMBER(HLA.attribute14) = FR.responsibility_id
        )  RES10_responsibility_name
       ,XLV.location_code              --親事業所コード
       ,XLV.location_name              --親事業所名
       ,HLA.attribute18                --他拠点出荷依頼作成可否区分
       --,FLV05.meaning                  --他拠点出荷依頼作成可否区分名
       ,(SELECT FLV05.meaning
           FROM fnd_lookup_values FLV05    --クイックコード(他拠点出荷依頼作成可否区分名)
          WHERE FLV05.language    = 'JA'
            AND FLV05.lookup_type = 'XXCMN_INCLUDE_EXCLUDE'
            AND FLV05.lookup_code = HLA.attribute18
        ) FLV05_meaning
       ,HLA.attribute20                --地区コード
       --,FLV06.meaning                  --地区名
       ,(SELECT FLV06.meaning
           FROM fnd_lookup_values FLV06    --クイックコード(地区名)
          WHERE FLV06.language    = 'JA'
            AND FLV06.lookup_type = 'XXCMN_AREA'
            AND FLV06.lookup_code = HLA.attribute20
        ) FLV06_meaning
       --,FU_CB.user_name                --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XLA.created_by = FU_CB.user_id
        ) FU_CB_user_name
       ,TO_CHAR( XLA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                       --作成日
       --,FU_LU.user_name                --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XLA.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
       ,TO_CHAR( XLA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                       --最終更新日
       --,FU_LL.user_name                --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XLA.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxcmn_locations_all XLA        --事業所アドオン
       ,hr_locations_all    HLA        --事業所マスタ
       ,xxsky_locations_v   XLV        --SKYLINK用中間VIEW 事業所情報VIEW
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES01                                 --担当職責1名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES02                                 --担当職責2名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES03                                 --担当職責3名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES04                                 --担当職責4名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES05                                 --担当職責5名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES06                                 --担当職責6名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES07                                 --担当職責7名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES08                                 --担当職責8名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES09                                 --担当職責9名取得用
       --,(SELECT FR.responsibility_id
       --        ,FR.responsibility_name
       --    FROM fnd_responsibility_tl   FR       --職責マスタ(日本語)
       --        ,fnd_application         FA       --アプリケーションマスタ
       --   WHERE FA.application_short_name = 'XXCMN'
       --     AND FR.application_id = FA.application_id
       --     AND FR.language = 'JA'
       -- )  RES10                                 --担当職責10名取得用
       --,fnd_lookup_values               FLV02    --クイックコード(出荷管理元区分名)
       --,fnd_lookup_values               FLV03    --クイックコード(購買担当フラグ名)
       --,fnd_lookup_values               FLV04    --クイックコード(出荷担当フラグ名)
       --,fnd_lookup_values               FLV05    --クイックコード(他拠点出荷依頼作成可否区分名)
       --,fnd_lookup_values               FLV06    --クイックコード(地区名)
       --,fnd_user                        FU_CB    --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user                        FU_LU    --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user                        FU_LL    --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins                      FL_LL    --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XLA.location_id = HLA.location_id
   AND  TO_NUMBER(HLA.attribute17) = XLV.location_id(+)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  TO_NUMBER(HLA.attribute5)  = RES01.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute6)  = RES02.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute7)  = RES03.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute8)  = RES04.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute9)  = RES05.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute10) = RES06.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute11) = RES07.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute12) = RES08.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute13) = RES09.responsibility_id(+)
   --AND  TO_NUMBER(HLA.attribute14) = RES10.responsibility_id(+)
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_SHIPMENT_MANAGEMENT'
   --AND  FLV02.lookup_code(+) = HLA.attribute1
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_PURCHASING_FLAG'
   --AND  FLV03.lookup_code(+) = HLA.attribute3
   --AND  FLV04.language(+)    = 'JA'
   --AND  FLV04.lookup_type(+) = 'XXCMN_SHIPPING_FLAG'
   --AND  FLV04.lookup_code(+) = HLA.attribute4
   --AND  FLV05.language(+)    = 'JA'
   --AND  FLV05.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   --AND  FLV05.lookup_code(+) = HLA.attribute18
   --AND  FLV06.language(+)    = 'JA'
   --AND  FLV06.lookup_type(+) = 'XXCMN_AREA'
   --AND  FLV06.lookup_code(+) = HLA.attribute20
   --AND  XLA.created_by         = FU_CB.user_id(+)
   --AND  XLA.last_updated_by    = FU_LU.user_id(+)
   --AND  XLA.last_update_login  = FL_LL.login_id(+)
   --AND  FL_LL.user_id          = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
   AND  HLA.inactive_date IS NULL
/
COMMENT ON TABLE APPS.XXSKY_事業所マスタ_基本_V IS 'SKYLINK用事業所マスタ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.事業所コード                  IS '事業所コード'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.事業所名                      IS '事業所名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.事業所略称                    IS '事業所略称'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.事業所カナ名                  IS '事業所カナ名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.適用開始日                    IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.適用終了日                    IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.郵便番号                      IS '郵便番号'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.住所                          IS '住所'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.電話番号                      IS '電話番号'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.FAX番号                       IS 'FAX番号'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.本部コード                    IS '本部コード'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.失効日                        IS '失効日'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.使用用途                      IS '使用用途'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.使用用途名                    IS '使用用途名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.出荷管理元区分                IS '出荷管理元区分'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.出荷管理元区分名              IS '出荷管理元区分名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.購買担当フラグ                IS '購買担当フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.購買担当フラグ名              IS '購買担当フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.出荷担当フラグ                IS '出荷担当フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.出荷担当フラグ名              IS '出荷担当フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責１                    IS '担当職責１'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責２                    IS '担当職責２'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責３                    IS '担当職責３'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責４                    IS '担当職責４'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責５                    IS '担当職責５'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責６                    IS '担当職責６'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責７                    IS '担当職責７'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責８                    IS '担当職責８'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責９                    IS '担当職責９'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.担当職責１０                  IS '担当職責１０'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.親事業所コード                IS '親事業所コード'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.親事業所名                    IS '親事業所名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.他拠点出荷依頼作成可否区分    IS '他拠点出荷依頼作成可否区分'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.他拠点出荷依頼作成可否区分名  IS '他拠点出荷依頼作成可否区分名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.地区コード                    IS '地区コード'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.地区名                        IS '地区名'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.作成者                        IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.作成日                        IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.最終更新者                    IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.最終更新日                    IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_事業所マスタ_基本_V.最終更新ログイン              IS '最終更新ログイン'
/
