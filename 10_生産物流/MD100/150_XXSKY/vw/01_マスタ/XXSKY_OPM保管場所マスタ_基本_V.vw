CREATE OR REPLACE VIEW APPS.XXSKY_OPM保管場所マスタ_基本_V
(
 倉庫コード
,倉庫名
,プラントコード
,プラント名
,組織有効開始日
,組織有効終了日
,相手先在庫管理対象
,相手先在庫管理対象名
,保管倉庫コード
,保管倉庫名
,保管倉庫略称
,保管倉庫無効日
,保管場所コード
,保管場所名
,内外倉庫区分
,内外倉庫区分名
,物流ブロック
,物流ブロック名
,代表倉庫
,代表倉庫名
,代表倉庫略称
,代表運送会社
,代表運送会社名
,ＥＯＳ管理区分
,ＥＯＳ管理区分名
,ＥＯＳ宛先
,ＥＯＳ宛先名
,倉庫管理部署
,倉庫管理部署名
,主要保管倉庫コード
,主要保管倉庫名
,仕入先コード
,仕入先名
,仕入先サイトコード
,仕入先サイト名
,ドリンク基準カレンダ
,ドリンク基準カレンダ名
,リーフ基準カレンダ
,リーフ基準カレンダ名
,出荷引当対象フラグ
,出荷引当対象フラグ名
,Ｄ_１倉庫フラグ
,Ｄ_１倉庫フラグ名
,直送倉庫区分
,直送倉庫区分名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        IWM.whse_code                   --倉庫コード
       ,IWM.whse_name                   --倉庫名
       ,IWM.orgn_code                   --プラントコード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,SOMT.orgn_name                  --プラント名
       ,(SELECT SOMT.orgn_name
         FROM sy_orgn_mst_tl SOMT   --プラント
         WHERE IWM.orgn_code = SOMT.orgn_code
         AND  SOMT.language  = 'JA'
        ) SOMT_orgn_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,HAOU.date_from                  --組織有効開始日
       ,HAOU.date_to                    --組織有効終了日
       ,IWM.attribute1                  --相手先在庫管理対象
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning                   --相手先在庫管理対象名
       ,(SELECT FLV01.meaning
         FROM  fnd_lookup_values FLV01                           --クイックコード(相手先在庫管理対象名)
         WHERE  FLV01.language     = 'JA'                        --言語
         AND  FLV01.lookup_type    = 'XXCMN_INV_CTRL'            --クイックコードタイプ
         AND  FLV01.lookup_code    = IWM.attribute1              --クイックコード
        ) FLV01_meaning                       --相手先在庫管理対象名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.segment1                    --保管倉庫コード
       ,MIL.description                 --保管倉庫名
       ,MIL.attribute12                 --保管倉庫略称
       ,MIL.disable_date                --保管倉庫無効日
       ,MIL.subinventory_code           --保管場所コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,IWM02.whse_name                 --保管場所名
       ,(SELECT IWM02.whse_name
         FROM ic_whse_mst IWM02  --OPM倉庫マスタ(保管場所)
         WHERE MIL.subinventory_code = IWM02.whse_code
        ) IWM02_whse_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute9                  --内外倉庫区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                   --内外倉庫区分名
       ,(SELECT FLV02.meaning 
         FROM fnd_lookup_values FLV02  --クイックコード(内外倉庫区分名)
         WHERE  FLV02.language  = 'JA'
         AND  FLV02.lookup_type = 'XXCMN_LOCT_IN_OUT'
         AND  FLV02.lookup_code = MIL.attribute9
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute6                  --物流ブロック
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning                   --物流ブロック名
       ,(SELECT FLV03.meaning 
         FROM fnd_lookup_values FLV03  --クイックコード(物流ブロック名)
         WHERE FLV03.language   = 'JA'
         AND  FLV03.lookup_type = 'XXCMN_D12'
         AND  FLV03.lookup_code = MIL.attribute6
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute5                  --代表倉庫
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV01.description              --代表倉庫名
       ,(SELECT XILV01.description
         FROM xxsky_item_locations_v XILV01 --OPM保管場所情報VIEW(代表倉庫名)
         WHERE MIL.attribute5 = XILV01.segment1
        ) XILV01_description
       --,XILV01.short_name               --代表倉庫略称
       ,(SELECT XILV01.short_name
         FROM xxsky_item_locations_v XILV01 --OPM保管場所情報VIEW(代表倉庫名)
         WHERE MIL.attribute5 = XILV01.segment1
        ) XILV01_short_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute7                  --代表運送会社
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XCV.party_name                  --代表運送会社名
       ,(SELECT XCV.party_name
         FROM xxsky_carriers_v XCV    --運送業者情報VIEW
         WHERE MIL.attribute7 = XCV.freight_code
        ) XCV_party_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,DECODE(MIL.ATTRIBUTE2, NULL, '0', '1')
        attribute2                      --ＥＯＳ管理区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV04.meaning                   --ＥＯＳ管理区分名
       ,(SELECT FLV04.meaning 
         FROM fnd_lookup_values FLV04  --クイックコード(ＥＯＳ管理区分名)
         WHERE FLV04.language   = 'JA'
         AND  FLV04.lookup_type = 'XXCMN_MANAGE_EOS'
         AND  FLV04.lookup_code = DECODE(MIL.ATTRIBUTE2, NULL, '0', '1')
        ) FLV04_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute2                  --ＥＯＳ宛先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV02.description              --ＥＯＳ宛先名
       ,(SELECT XILV02.description
         FROM xxsky_item_locations_v XILV02 --OPM保管場所情報VIEW(ＥＯＳ宛先名)
         WHERE MIL.attribute2 = XILV02.segment1
        ) XILV02_description
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute3                  --倉庫管理部署
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XLV.location_name               --倉庫管理部署名
       ,(SELECT XLV.location_name
         FROM xxsky_locations_v XLV    --事業所情報VIEW(倉庫管理部署)
         WHERE MIL.attribute3 = XLV.location_code
        ) XLV_location_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute8                  --主要保管倉庫コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV03.description              --主要保管倉庫名
       ,(SELECT XILV03.description
         FROM xxsky_item_locations_v XILV03 --OPM保管場所情報VIEW(主要保管倉庫)
         WHERE MIL.attribute8 = XILV03.segment1
        ) XILV03_description
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute13                 --仕入先コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV.vendor_name                 --仕入先名
       ,(SELECT XVV.vendor_name
         FROM xxsky_vendors_v XVV    --仕入先情報VIEW(仕入先)
         WHERE MIL.attribute13 = XVV.segment1
        ) XVV_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute1                  --仕入先サイトコード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVSV.vendor_site_name           --仕入先サイト名
       ,(SELECT XVSV.vendor_site_name
         FROM xxsky_vendor_sites_v XVSV   --仕入先サイト情報VIEW(仕入先サイト名)
         WHERE MIL.attribute1 =  XVSV.vendor_site_code
        ) XVSV_vendor_site_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute10                 --ドリンク基準カレンダ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,MSH01.calendar_desc             --ドリンク基準カレンダ名
       ,(SELECT MSH01.calendar_desc
         FROM mr_shcl_hdr MSH01  --基準カレンダ(ドリンク)
         WHERE MIL.attribute10 = MSH01.calendar_no
        ) MSH01_calendar_desc
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute14                 --リーフ基準カレンダ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,MSH02.calendar_desc             --リーフ基準カレンダ名
       ,(SELECT MSH02.calendar_desc
         FROM mr_shcl_hdr MSH02  --基準カレンダ(リーフ)
         WHERE MIL.attribute14 = MSH02.calendar_no
        ) MSH02_calendar_desc
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute4                  --出荷引当対象フラグ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV05.meaning                   --出荷引当対象フラグ名
       ,(SELECT FLV05.meaning 
         FROM fnd_lookup_values FLV05  --クイックコード(出荷引当対象フラグ名)
         WHERE FLV05.language   = 'JA'
         AND  FLV05.lookup_type = 'XXCMN_ATP_FLAG'
         AND  FLV05.lookup_code = MIL.attribute4
        ) FLV05_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute11                 --Ｄ＋１倉庫フラグ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV06.meaning                   --Ｄ＋１倉庫フラグ名
       ,(SELECT FLV06.meaning 
         FROM fnd_lookup_values FLV06  --クイックコード(Ｄ＋１倉庫フラグ名)
         WHERE FLV06.language   = 'JA'
         AND  FLV06.lookup_type = 'XXCMN_D+1_LOCT_FLAG'
         AND  FLV06.lookup_code = MIL.attribute11
        ) FLV06_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,MIL.attribute15                 --直送倉庫区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV07.meaning                   --直送倉庫区分名
       ,(SELECT FLV07.meaning 
         FROM fnd_lookup_values FLV07  --クイックコード(直送倉庫区分名)
         WHERE FLV07.language   = 'JA'
         AND  FLV07.lookup_type = 'XXCMN_DROP_SHIP_LOCT_CLASS'
         AND  FLV07.lookup_code = MIL.attribute15
        ) FLV07_meaning
       --,FU_CB.user_name                  --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(CREATED_BY名称取得用)
         WHERE MIL.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( MIL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                  --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
         WHERE MIL.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( MIL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                  --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user   FU_LL  --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
             ,fnd_logins FL_LL  --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
         WHERE MIL.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  ic_whse_mst               IWM    --OPM倉庫マスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,ic_whse_mst               IWM02  --OPM倉庫マスタ(保管場所)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
       ,hr_all_organization_units HAOU   --倉庫
       ,mtl_item_locations        MIL    --倉庫
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,sy_orgn_mst_tl            SOMT   --プラント
       --,xxsky_item_locations_v    XILV01 --OPM保管場所情報VIEW(代表倉庫名)
       --,xxsky_item_locations_v    XILV02 --OPM保管場所情報VIEW(ＥＯＳ宛先名)
       --,xxsky_item_locations_v    XILV03 --OPM保管場所情報VIEW(主要保管倉庫)
       --,xxsky_carriers_v          XCV    --運送業者情報VIEW
       --,xxsky_locations_v         XLV    --事業所情報VIEW(倉庫管理部署)
       --,xxsky_vendors_v           XVV    --仕入先情報VIEW(仕入先)
       --,xxsky_vendor_sites_v      XVSV   --仕入先サイト情報VIEW(仕入先サイト名)
       --,mr_shcl_hdr               MSH01  --基準カレンダ(ドリンク)
       --,mr_shcl_hdr               MSH02  --基準カレンダ(リーフ)
       --,fnd_user                  FU_CB  --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user                  FU_LU  --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user                  FU_LL  --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins                FL_LL  --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_lookup_values         FLV01  --クイックコード(相手先在庫管理対象名)
       --,fnd_lookup_values         FLV02  --クイックコード(内外倉庫区分名)
       --,fnd_lookup_values         FLV03  --クイックコード(物流ブロック名)
       --,fnd_lookup_values         FLV04  --クイックコード(ＥＯＳ管理区分名)
       --,fnd_lookup_values         FLV05  --クイックコード(出荷引当対象フラグ名)
       --,fnd_lookup_values         FLV06  --クイックコード(Ｄ＋１倉庫フラグ名)
       --,fnd_lookup_values         FLV07  --クイックコード(直送倉庫区分名)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  IWM.mtl_organization_id = HAOU.organization_id
   AND  HAOU.organization_id = MIL.organization_id
   AND  MIL.disable_date IS NULL
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  IWM.orgn_code = SOMT.orgn_code(+)
   --AND  SOMT.language(+) = 'JA'
   --AND  MIL.subinventory_code = IWM02.whse_code(+)
   --AND  MIL.attribute5 = XILV01.segment1(+)
   --AND  MIL.attribute7 = XCV.freight_code(+)
   --AND  MIL.attribute2 = XILV02.segment1(+)
   --AND  MIL.attribute3 = XLV.location_code(+)
   --AND  MIL.attribute8 = XILV03.segment1(+)
   --AND  MIL.attribute13 = XVV.segment1(+)
   --AND  MIL.attribute1 =  XVSV.vendor_site_code(+)
   --AND  MIL.attribute10 = MSH01.calendar_no(+)
   --AND  MIL.attribute14 = MSH02.calendar_no(+)
   --AND  MIL.created_by        = FU_CB.user_id(+)
   --AND  MIL.last_updated_by   = FU_LU.user_id(+)
   --AND  MIL.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'                        --言語
   --AND  FLV01.lookup_type(+) = 'XXCMN_INV_CTRL'            --クイックコードタイプ
   --AND  FLV01.lookup_code(+) = IWM.attribute1              --クイックコード
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_LOCT_IN_OUT'
   --AND  FLV02.lookup_code(+) = MIL.attribute9
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_D12'
   --AND  FLV03.lookup_code(+) = MIL.attribute6
   --AND  FLV04.language(+)    = 'JA'
   --AND  FLV04.lookup_type(+) = 'XXCMN_MANAGE_EOS'
   --AND  FLV04.lookup_code(+) = DECODE(MIL.ATTRIBUTE2, NULL, '0', '1')
   --AND  FLV05.language(+)    = 'JA'
   --AND  FLV05.lookup_type(+) = 'XXCMN_ATP_FLAG'
   --AND  FLV05.lookup_code(+) = MIL.attribute4
   --AND  FLV06.language(+)    = 'JA'
   --AND  FLV06.lookup_type(+) = 'XXCMN_D+1_LOCT_FLAG'
   --AND  FLV06.lookup_code(+) = MIL.attribute11
   --AND  FLV07.language(+)    = 'JA'
   --AND  FLV07.lookup_type(+) = 'XXCMN_DROP_SHIP_LOCT_CLASS'
   --AND  FLV07.lookup_code(+) = MIL.attribute15
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKY_OPM保管場所マスタ_基本_V IS 'SKYLINK用OPM保管場所マスタ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.倉庫コード                IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.倉庫名                    IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.プラントコード            IS 'プラントコード'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.プラント名                IS 'プラント名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.組織有効開始日            IS '組織有効開始日'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.組織有効終了日            IS '組織有効終了日'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.相手先在庫管理対象        IS '相手先在庫管理対象'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.相手先在庫管理対象名      IS '相手先在庫管理対象名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.保管倉庫コード            IS '保管倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.保管倉庫名                IS '保管倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.保管倉庫略称              IS '保管倉庫略称'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.保管倉庫無効日            IS '保管倉庫無効日'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.保管場所コード            IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.保管場所名                IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.内外倉庫区分              IS '内外倉庫区分'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.内外倉庫区分名            IS '内外倉庫区分名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.物流ブロック              IS '物流ブロック'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.物流ブロック名            IS '物流ブロック名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.代表倉庫                  IS '代表倉庫'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.代表倉庫名                IS '代表倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.代表倉庫略称              IS '代表倉庫略称'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.代表運送会社              IS '代表運送会社'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.代表運送会社名            IS '代表運送会社名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.ＥＯＳ管理区分            IS 'ＥＯＳ管理区分'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.ＥＯＳ管理区分名          IS 'ＥＯＳ管理区分名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.ＥＯＳ宛先                IS 'ＥＯＳ宛先'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.ＥＯＳ宛先名              IS 'ＥＯＳ宛先名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.倉庫管理部署              IS '倉庫管理部署'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.倉庫管理部署名            IS '倉庫管理部署名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.主要保管倉庫コード        IS '主要保管倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.主要保管倉庫名            IS '主要保管倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.仕入先コード              IS '仕入先コード'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.仕入先名                  IS '仕入先名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.仕入先サイトコード        IS '仕入先サイトコード'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.仕入先サイト名            IS '仕入先サイト名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.ドリンク基準カレンダ      IS 'ドリンク基準カレンダ'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.ドリンク基準カレンダ名    IS 'ドリンク基準カレンダ名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.リーフ基準カレンダ        IS 'リーフ基準カレンダ'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.リーフ基準カレンダ名      IS 'リーフ基準カレンダ名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.出荷引当対象フラグ        IS '出荷引当対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.出荷引当対象フラグ名      IS '出荷引当対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.Ｄ_１倉庫フラグ           IS 'Ｄ＋１倉庫フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.Ｄ_１倉庫フラグ名         IS 'Ｄ＋１倉庫フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.直送倉庫区分              IS '直送倉庫区分'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.直送倉庫区分名            IS '直送倉庫区分名'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.作成者                    IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.作成日                    IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.最終更新者                IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.最終更新日                IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_OPM保管場所マスタ_基本_V.最終更新ログイン          IS '最終更新ログイン'
/