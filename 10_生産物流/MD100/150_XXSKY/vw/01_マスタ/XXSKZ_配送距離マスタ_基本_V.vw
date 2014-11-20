/*************************************************************************
 * 
 * View  Name      : XXSKZ_配送距離マスタ_基本_V
 * Description     : XXSKZ_配送距離マスタ_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_配送距離マスタ_基本_V
(
 商品区分
,商品区分名
,運送業者コード
,運送業者名
,出庫倉庫
,出庫倉庫名
,コード区分
,コード区分名
,配送先コード
,配送先名
,適用開始日
,適用終了日
,車立距離
,小口距離
,混載割増距離
,実際距離
,エリアA
,エリアB
,エリアC
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XDD.goods_classe                 --商品区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning                    --商品区分名
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01    --クイックコード(商品区分名)
         WHERE FLV01.language = 'JA'
           AND FLV01.lookup_type = 'XXWIP_ITEM_TYPE'
           AND FLV01.lookup_code = XDD.GOODS_CLASSE
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDD.delivery_company_code        --運送業者コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XCRV.party_name                  --運送業者名
       ,(SELECT XCRV.party_name
         FROM xxskz_carriers_v XCRV   --運送業者情報VIEW
         WHERE XDD.delivery_company_code = XCRV.freight_code
        ) XCRV_party_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDD.origin_shipment              --出庫倉庫
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,XILV.description                 --出庫倉庫名
       ,(SELECT XILV.description
         FROM xxskz_item_locations_v XILV   --OPM保管場所情報VIEW
         WHERE XDD.origin_shipment =  XILV.segment1
        ) XILV_description
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDD.code_division                --コード区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                    --コード区分名
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02    --クイックコード(コード区分名)
         WHERE FLV02.language = 'JA'
           AND FLV02.lookup_type = 'XXWIP_CODE_TYPE'
           AND FLV02.lookup_code = XDD.CODE_DIVISION
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDD.shipping_address_code        --配送先コード
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,SAC.name    shipping_address_code_name    --配送先名
       ,CASE 
          --コード区分が'1:倉庫'の場合はOPM保管倉庫名を取得
          WHEN XDD.code_division = 1 THEN
            (SELECT description           --保管倉庫名
             FROM xxskz_item_locations_v  --保管倉庫
             WHERE segment1 = XDD.shipping_address_code)
          --コード区分が'2:取引先'の場合は取引先サイト名を取得
          WHEN XDD.code_division = 2 THEN
            (SELECT vendor_site_name      --取引先サイト名
             FROM xxskz_vendor_sites_v    --仕入先サイトVIEW
             WHERE vendor_site_code = XDD.shipping_address_code)
          --コード区分が'3:配送先'の場合は配送先名を取得
          WHEN XDD.code_division = 3 THEN
            (SELECT party_site_name       --配送先名
             FROM xxskz_party_sites_v     --配送先VIEW
             WHERE party_site_number = XDD.shipping_address_code)
          ELSE NULL
        END shipping_address_code_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDD.start_date_active            --適用開始日
       ,XDD.end_date_active              --適用終了日
       ,XDD.post_distance                --車立距離
       ,XDD.small_distance               --小口距離
       ,XDD.consolid_add_distance        --混載割増距離
       ,XDD.actual_distance              --実際距離
       ,XDD.area_a                       --エリアA
       ,XDD.area_b                       --エリアB
       ,XDD.area_c                       --エリアC
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                  --作成者
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XDD.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XDD.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --作成日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                  --最終更新者
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XDD.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XDD.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --最終更新日
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                  --最終更新ログイン
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
             ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XDD.last_update_login = FL_LL.login_id
           AND FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxwip_delivery_distance   XDD    --配送距離アドオンマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,xxsky_carriers_v          XCRV   --運送業者情報VIEW
       --,xxsky_item_locations_v    XILV   --OPM保管場所情報VIEW
       --,(--配送先名取得用（コード区分の値によって取得先が異なる）
       --     --コード区分が'1:倉庫'の場合はOPM保管倉庫名を取得
       --     SELECT 1                    class    --1:倉庫
       --           ,segment1             code     --保管倉庫No
       --           ,description          name     --保管倉庫名
       --       FROM xxsky_item_locations_v  --保管倉庫
       --   UNION ALL
       --     --コード区分が'2:取引先'の場合は取引先サイト名を取得
       --     SELECT 2                    class    --2:取引先
       --           ,vendor_site_code     code     --取引先サイトNo
       --           ,vendor_site_name     name     --取引先サイト名
       --       FROM xxsky_vendor_sites_v  --仕入先サイトVIEW
       --   UNION ALL
       --     --コード区分が'3:配送先'の場合は配送先名を取得
       --     SELECT 3                    class    --3:配送先
       --           ,party_site_number    code     --配送先No
       --           ,party_site_name      name     --配送先名
       --       FROM xxsky_party_sites_v   --配送先VIEW
       -- )                       SAC      --配送先名取得用
       --,fnd_user                FU_CB    --ユーザーマスタ(created_by名称取得用)
       --,fnd_user                FU_LU    --ユーザーマスタ(last_updated_by名称取得用)
       --,fnd_user                FU_LL    --ユーザーマスタ(last_update_login名称取得用)
       --,fnd_logins              FL_LL    --ログインマスタ(last_update_login名称取得用)
       --,fnd_lookup_values       FLV01    --クイックコード(商品区分名)
       --,fnd_lookup_values       FLV02    --クイックコード(コード区分名)
 --WHERE  XDD.delivery_company_code = XCRV.freight_code(+)
   --AND  XDD.origin_shipment =  XILV.segment1(+)
   --AND  XDD.code_division = SAC.class(+)          --配送先名取得用
   --AND  XDD.shipping_address_code = SAC.code(+)   --配送先名取得用
   --AND  XDD.created_by        = FU_CB.user_id(+)
   --AND  XDD.last_updated_by   = FU_LU.user_id(+)
   --AND  XDD.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
   --AND  FLV01.language = 'JA'
   --AND  FLV01.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   --AND  FLV01.lookup_code(+) = XDD.GOODS_CLASSE
   --AND  FLV02.language = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXWIP_CODE_TYPE'
   --AND  FLV02.lookup_code(+) = XDD.CODE_DIVISION
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKZ_配送距離マスタ_基本_V IS 'SKYLINK用配送距離マスタ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.商品区分         IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.商品区分名       IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.運送業者コード   IS '運送業者コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.運送業者名       IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.出庫倉庫         IS '出庫倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.出庫倉庫名       IS '出庫倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.コード区分       IS 'コード区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.コード区分名     IS 'コード区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.配送先コード     IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.配送先名         IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.適用開始日       IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.適用終了日       IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.車立距離         IS '車立距離'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.小口距離         IS '小口距離'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.混載割増距離     IS '混載割増距離'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.実際距離         IS '実際距離'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.エリアA          IS 'エリアA'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.エリアB          IS 'エリアB'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.エリアC          IS 'エリアC'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.作成者           IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.作成日           IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.最終更新者       IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.最終更新日       IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送距離マスタ_基本_V.最終更新ログイン IS '最終更新ログイン'
/