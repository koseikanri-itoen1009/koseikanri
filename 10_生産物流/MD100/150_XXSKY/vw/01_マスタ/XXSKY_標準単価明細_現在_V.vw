CREATE OR REPLACE VIEW APPS.XXSKY_標準単価明細_現在_V
(
 商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,内訳品目コード
,内訳品目名
,内訳品目略称
,付帯コード
,メーカーコード
,メーカー名
,費目区分
,費目区分名
,項目区分
,項目区分名
,数量
,数量単位
,単価
,単価単位
,歩留率
,仕入単価
,演算区分
,演算区分名
,実質単価
,ヘッダID
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
       ,XPL.item_code                 --内訳品目コード
       ,XIMV.item_name                --内訳品目名
       ,XIMV.item_short_name          --内訳品目略称
       ,XPL.futai_code                --付帯コード
       ,XPL.maker_code                --メーカーコード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XVV.vendor_name               --メーカー名
       ,(SELECT XVV.vendor_name
         FROM xxsky_vendors_v XVV   --仕入先情報VIEW
         WHERE XPL.maker_id = XVV.vendor_id
        ) XVV_vendor_name          --計算区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPL.expense_item_type         --費目区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01 --クイックコード(費目区分名)
         WHERE FLV01.language    = 'JA'                      --言語
           AND FLV01.lookup_type = 'XXPO_EXPENSE_ITEM_TYPE'  --クイックコードタイプ
           AND FLV01.attribute1  = XPL.expense_item_type     --クイックコード
        ) e_item_type_name              --費目区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPL.expense_item_detail_type  --項目区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02 --クイックコード(項目区分名)
         WHERE FLV02.language(+)    = 'JA'
           AND FLV02.lookup_type(+) = 'XXPO_EXPENSE_ITEM_DETAIL_TYPE'
           AND FLV02.attribute1(+)  = XPL.expense_item_detail_type
        ) e_item_detail_name            --項目区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPL.quantity                  --数量
       ,XPL.quantity_uom              --数量単位
       ,XPL.unit_price                --単価
       ,XPL.unit_price_uom            --単価単位
       ,XPL.yield_pct                 --歩留率
       ,XPL.purchase_unit_price       --仕入単価
       ,XPL.computation_type          --演算区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03 --クイックコード(演算区分名)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXPO_COMPUTATION_TYPE'
           AND FLV03.lookup_code = XPL.computation_type
        ) computation_type_name         --演算区分名
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XPL.real_unit_price           --実質単価
       ,XPL.price_header_id           --ヘッダID
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name               --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XPL.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XPL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                      --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name               --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XPL.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XPL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                      --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name               --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XPL.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxpo_price_lines    XPL       --仕入／標準単価明細アドオン
       ,xxpo_price_headers  XPH       --仕入／標準単価ヘッダアドオン
       ,xxsky_prod_class_v  XPCV      --SKYLINK用 商品区分取得VIEW
       ,xxsky_item_class_v  XICV      --SKYLINK用 品目区分取得VIEW
       ,xxsky_crowd_code_v  XCCV      --SKYLINK用 郡コード取得VIEW
       ,xxsky_item_mst_v    XIMV      --OPM品目情報VIEW
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxsky_vendors_v     XVV       --仕入先情報VIEW
       --,fnd_lookup_values   FLV01     --クイックコード(費目区分名)
       --,fnd_lookup_values   FLV02     --クイックコード(項目区分名)
       --,fnd_lookup_values   FLV03     --クイックコード(演算区分名)
       --,fnd_user            FU_CB     --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user            FU_LU     --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user            FU_LL     --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins          FL_LL     --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XPH.price_type      = '2'     --標準
   AND  XPH.price_header_id = XPL.price_header_id
   AND  XPL.item_id      = XPCV.item_id(+)
   AND  XPL.item_id      = XICV.item_id(+)
   AND  XPL.item_id      = XCCV.item_id(+)
   AND  XPL.item_id      = XIMV.item_id(+)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XPL.maker_id     = XVV.vendor_id(+)
   --AND  FLV01.language(+)    = 'JA'                      --言語
   --AND  FLV01.lookup_type(+) = 'XXPO_EXPENSE_ITEM_TYPE'  --クイックコードタイプ
   --AND  FLV01.attribute1(+)  = XPL.expense_item_type     --クイックコード
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXPO_EXPENSE_ITEM_DETAIL_TYPE'
   --AND  FLV02.attribute1(+)  = XPL.expense_item_detail_type
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXPO_COMPUTATION_TYPE'
   --AND  FLV03.lookup_code(+) = XPL.computation_type
   --AND  XPL.created_by        = FU_CB.user_id(+)
   --AND  XPL.last_updated_by   = FU_LU.user_id(+)
   --AND  XPL.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
   AND  XPH.start_date_active <= TRUNC(SYSDATE)
   AND  XPH.end_date_active   >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKY_標準単価明細_現在_V IS 'SKYLINK用標準単価明細（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.品目区分                       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.品目区分名                     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.群コード                       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.内訳品目コード                 IS '内訳品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.内訳品目名                     IS '内訳品目名'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.内訳品目略称                   IS '内訳品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.付帯コード                     IS '付帯コード'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.メーカーコード                 IS 'メーカーコード'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.メーカー名                     IS 'メーカー名'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.費目区分                       IS '費目区分'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.費目区分名                     IS '費目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.項目区分                       IS '項目区分'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.項目区分名                     IS '項目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.数量                           IS '数量'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.数量単位                       IS '数量単位'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.単価                           IS '単価'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.単価単位                       IS '単価単位'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.歩留率                         IS '歩留率'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.仕入単価                       IS '仕入単価'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.演算区分                       IS '演算区分'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.演算区分名                     IS '演算区分名'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.実質単価                       IS '実質単価'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.ヘッダID                       IS 'ヘッダID'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_標準単価明細_現在_V.最終更新ログイン               IS '最終更新ログイン'
/
