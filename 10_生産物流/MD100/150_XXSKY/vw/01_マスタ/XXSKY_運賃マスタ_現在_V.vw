CREATE OR REPLACE VIEW APPS.XXSKY_運賃マスタ_現在_V
(
 支払請求区分
,支払請求区分名
,商品区分
,商品区分名
,運送業者
,運送業者名
,配送区分
,配送区分名
,運賃距離
,重量
,適用開始日
,適用終了日
,運送費
,リーフ混載割増
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        XDC.p_b_classe                 --支払請求区分
       ,FLV01.meaning                  --支払請求区分名
       ,XDC.goods_classe               --商品区分
       ,FLV02.meaning                  --商品区分名
       ,XDC.delivery_company_code      --運送業者コード
       ,XCRV.party_name                --運送業者名
       ,XDC.shipping_address_classe    --配送区分
       ,FLV03.meaning                  --配送区分名
       ,XDC.delivery_distance          --運賃距離
       ,XDC.delivery_weight            --重量
       ,XDC.start_date_active          --適用開始日
       ,XDC.end_date_active            --適用終了日
       ,XDC.shipping_expenses          --運送費
       ,XDC.leaf_consolid_add          --リーフ混載割増
       ,FU_CB.user_name                --作成者
       ,TO_CHAR( XDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --作成日
       ,FU_LU.user_name                --最終更新者
       ,TO_CHAR( XDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --最終更新日
       ,FU_LL.user_name                --最終更新ログイン
  FROM  xxwip_delivery_charges  XDC    --運賃アドオンマスタインタフェース
       ,xxsky_carriers_v        XCRV   --運送業者情報VIEW
       ,fnd_user                FU_CB  --ユーザーマスタ(created_by名称取得用)
       ,fnd_user                FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
       ,fnd_user                FU_LL  --ユーザーマスタ(last_update_login名称取得用)
       ,fnd_logins              FL_LL  --ログインマスタ(last_update_login名称取得用)
       ,fnd_lookup_values       FLV01  --クイックコード(支払請求区分名)
       ,fnd_lookup_values       FLV02  --クイックコード(商品区分名)
       ,fnd_lookup_values       FLV03  --クイックコード(配送区分名)
 WHERE  XDC.start_date_active <= TRUNC(SYSDATE)
   AND  XDC.end_date_active   >= TRUNC(SYSDATE)
   AND  XDC.delivery_company_code = XCRV.freight_code(+)
   AND  XDC.created_by        = FU_CB.user_id(+)
   AND  XDC.last_updated_by   = FU_LU.user_id(+)
   AND  XDC.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXWIP_PAYCHARGE_TYPE'
   AND  FLV01.lookup_code(+) = XDC.p_b_classe
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV02.lookup_code(+) = XDC.goods_classe
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV03.lookup_code(+) = XDC.shipping_address_classe
/
COMMENT ON TABLE APPS.XXSKY_運賃マスタ_現在_V IS 'SKYLINK用運賃マスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.支払請求区分                IS '支払請求区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.支払請求区分名              IS '支払請求区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.商品区分                    IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.商品区分名                  IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.運送業者                    IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.運送業者名                  IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.配送区分                    IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.配送区分名                  IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.運賃距離                    IS '運賃距離'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.重量                        IS '重量'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.適用開始日                  IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.適用終了日                  IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.運送費                      IS '運送費'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.リーフ混載割増              IS 'リーフ混載割増'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.作成者                      IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.作成日                      IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.最終更新者                  IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.最終更新日                  IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃マスタ_現在_V.最終更新ログイン            IS '最終更新ログイン'
/
