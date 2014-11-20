CREATE OR REPLACE VIEW APPS.XXSKY_ロットマスタ_現在_V
(
 商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,ロット番号
,製造年月日
,固有記号
,賞味期限
,納入日_初回
,納入日_最終
,在庫入数
,在庫単価
,取引先
,取引先名
,仕入形態
,仕入形態名
,茶期区分
,茶期区分名
,年度
,産地
,産地名
,タイプ
,ランク１
,ランク２
,ランク３
,生産伝票区分
,生産伝票区分名
,ラインNO
,摘要
,原料製造工場
,原料製造元ロット番号
,検査依頼NO
,ロットステータス
,ロットステータス名
,作成区分
,作成区分名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  XPCV.prod_class_code          --商品区分
       ,XPCV.prod_class_name          --商品区分名
       ,XICV.item_class_code          --品目区分
       ,XICV.item_class_name          --品目区分名
       ,XCCV.crowd_code               --群コード
       ,XIMV.item_no                  --品目コード
       ,XIMV.item_name                --品目名
       ,XIMV.item_short_name          --品目略称
       ,CASE WHEN ILM.lot_id = 0 THEN '0'          --'DEFAULTLOT'は'0'に変換
             ELSE                     ILM.lot_no
        END                 lot_no    --ロット番号
       ,ILM.attribute1                --製造年月日
       ,ILM.attribute2                --固有記号
       ,ILM.attribute3                --賞味期限
       ,ILM.attribute4                --納入日(初回)
       ,ILM.attribute5                --納入日(最終)
       ,NVL(TO_NUMBER(ILM.attribute6), 0)
                                      --在庫入数
       ,NVL(TO_NUMBER(ILM.attribute7), 0)
                                      --在庫単価
       ,ILM.attribute8                --取引先
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV.vendor_name               --取引先名
       ,(SELECT XVV.vendor_name
         FROM xxsky_vendors_v XVV     --仕入先VIEW
         WHERE  ILM.attribute8 = XVV.segment1
        ) XVV_vendor_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,ILM.attribute9                --仕入形態
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning                 --仕入形態名
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01   --クイックコード(仕入形態名)
         WHERE FLV01.language    = 'JA'
         AND   FLV01.lookup_type = 'XXCMN_L05'
         AND   FLV01.lookup_code = ILM.attribute9
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,ILM.attribute10               --茶期区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                 --茶期区分名
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02   --クイックコード(茶期区分名)
         WHERE  FLV02.language    = 'JA'
         AND    FLV02.lookup_type = 'XXCMN_L06'
         AND    FLV02.lookup_code = ILM.attribute10
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,ILM.attribute11               --年度
       ,ILM.attribute12               --産地
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning                 --産地名
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03   --クイックコード(産地名)
         WHERE FLV03.language    = 'JA'
         AND   FLV03.lookup_type = 'XXCMN_L07'
         AND   FLV03.lookup_code = ILM.attribute12
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_NUMBER( ILM.attribute13 )  --タイプ
       ,ILM.attribute14               --ランク１
       ,ILM.attribute15               --ランク２
       ,ILM.attribute19               --ランク３
       ,ILM.attribute16               --生産伝票区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV04.meaning                 --生産伝票区分名
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04   --クイックコード(生産伝票区分名)
         WHERE FLV04.language    = 'JA'
         AND   FLV04.lookup_type = 'XXCMN_L03'
         AND   FLV04.lookup_code = ILM.attribute16
        ) FLV04_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,ILM.attribute17               --ラインNo
       ,ILM.attribute18               --摘要
       ,ILM.attribute20               --原料製造工場
       ,ILM.attribute21               --原料製造元ロット番号
       ,ILM.attribute22               --検査依頼No
       ,ILM.attribute23               --ロットステータス
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV05.meaning                 --ロットステータス名
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05   --クイックコード(ロットステータス名)
         WHERE FLV05.language    = 'JA'
         AND   FLV05.lookup_type = 'XXCMN_LOT_STATUS'
         AND   FLV05.lookup_code = ILM.attribute23
        ) FLV05_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,ILM.attribute24               --作成区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV06.meaning                 --作成区分名
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06   --クイックコード(作成区分名)
         WHERE FLV06.language    = 'JA'
         AND   FLV06.lookup_type = 'XXCMN_DERIVE_DIV'
         AND   FLV06.lookup_code = ILM.attribute24
        ) FLV06_meaning
       --,FU_CB.user_name               --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE ILM.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( ILM.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                      --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name               --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE ILM.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( ILM.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                      --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name               --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE ILM.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  ic_lots_mst           ILM     --ロットマスタ
       ,xxsky_prod_class_v    XPCV    --SKYLINK用 商品区分取得VIEW
       ,xxsky_item_class_v    XICV    --SKYLINK用 品目区分取得VIEW
       ,xxsky_crowd_code_v    XCCV    --SKYLINK用 郡コード取得VIEW
       ,xxsky_item_mst_v      XIMV    --OPM品目情報VIEW
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxsky_vendors_v       XVV     --仕入先VIEW
       --,fnd_lookup_values     FLV01   --クイックコード(仕入形態名)
       --,fnd_lookup_values     FLV02   --クイックコード(茶期区分名)
       --,fnd_lookup_values     FLV03   --クイックコード(産地名)
       --,fnd_lookup_values     FLV04   --クイックコード(生産伝票区分名)
       --,fnd_lookup_values     FLV05   --クイックコード(ロットステータス名)
       --,fnd_lookup_values     FLV06   --クイックコード(作成区分名)
       --,fnd_user              FU_CB   --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user              FU_LU   --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user              FU_LL   --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins            FL_LL   --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  ILM.item_id          = XPCV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  ILM.item_id          = XICV.item_id(+)
   --AND  ILM.item_id          = XCCV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
   AND  XPCV.item_id         = XICV.item_id
   AND  XPCV.item_id         = XCCV.item_id
   AND  XICV.item_id         = XCCV.item_id
   AND  ILM.item_id          = XIMV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  ILM.attribute8       = XVV.segment1(+)
   --AND  FLV01.language(+)    = 'JA'
   --AND  FLV01.lookup_type(+) = 'XXCMN_L05'
   --AND  FLV01.lookup_code(+) = ILM.attribute9
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_L06'
   --AND  FLV02.lookup_code(+) = ILM.attribute10
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_L07'
   --AND  FLV03.lookup_code(+) = ILM.attribute12
   --AND  FLV04.language(+)    = 'JA'
   --AND  FLV04.lookup_type(+) = 'XXCMN_L03'
   --AND  FLV04.lookup_code(+) = ILM.attribute16
   --AND  FLV05.language(+)    = 'JA'
   --AND  FLV05.lookup_type(+) = 'XXCMN_LOT_STATUS'
   --AND  FLV05.lookup_code(+) = ILM.attribute23
   --AND  FLV06.language(+)    = 'JA'
   --AND  FLV06.lookup_type(+) = 'XXCMN_DERIVE_DIV'
   --AND  FLV06.lookup_code(+) = ILM.attribute24
   --AND  ILM.created_by           = FU_CB.user_id(+)
   --AND  ILM.last_updated_by      = FU_LU.user_id(+)
   --AND  ILM.last_update_login    = FL_LL.login_id(+)
   --AND  FL_LL.user_id            = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
   AND  ILM.inactive_ind  = 0
   AND  ILM.delete_mark   = 0
/
COMMENT ON TABLE APPS.XXSKY_ロットマスタ_現在_V IS 'SKYLINK用ロットマスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.品目区分                       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.品目区分名                     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.群コード                       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.品目コード                     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.品目名                         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.品目略称                       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.ロット番号                     IS 'ロット番号'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.製造年月日                     IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.固有記号                       IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.賞味期限                       IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.納入日_初回                    IS '納入日_初回'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.納入日_最終                    IS '納入日_最終'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.在庫入数                       IS '在庫入数'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.在庫単価                       IS '在庫単価'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.取引先                         IS '取引先'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.取引先名                       IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.仕入形態                       IS '仕入形態'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.仕入形態名                     IS '仕入形態名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.茶期区分                       IS '茶期区分'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.茶期区分名                     IS '茶期区分名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.年度                           IS '年度'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.産地                           IS '産地'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.産地名                         IS '産地名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.タイプ                         IS 'タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.ランク１                       IS 'ランク１'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.ランク２                       IS 'ランク２'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.ランク３                       IS 'ランク３'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.生産伝票区分                   IS '生産伝票区分'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.生産伝票区分名                 IS '生産伝票区分名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.ラインNO                       IS 'ラインNo'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.摘要                           IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.原料製造工場                   IS '原料製造工場'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.原料製造元ロット番号           IS '原料製造元ロット番号'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.検査依頼NO                     IS '検査依頼No'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.ロットステータス               IS 'ロットステータス'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.ロットステータス名             IS 'ロットステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.作成区分                       IS '作成区分'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.作成区分名                     IS '作成区分名'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_ロットマスタ_現在_V.最終更新ログイン               IS '最終更新ログイン'
/
