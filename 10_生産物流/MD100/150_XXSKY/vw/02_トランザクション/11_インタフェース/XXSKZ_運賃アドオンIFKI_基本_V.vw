/*************************************************************************
 * 
 * View  Name      : XXSKZ_運賃アドオンIFKI_基本_V
 * Description     : XXSKZ_運賃アドオンIFKI_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_運賃アドオンIFKI_基本_V
(
 パターン区分
,パターン区分名
,運送業者
,運送業者名
,配送NO
,送り状NO
,支払請求区分
,支払請求区分名
,配送区分
,配送区分名
,請求運賃
,個数１
,個数２
,重量１
,重量２
,距離
,諸料金
,通行料
,ピッキング料
,混載割増金額
,合計
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT 
        XDI.pattern_flag                                  --パターン区分
       ,CASE XDI.pattern_flag                             --パターン区分名
            WHEN '1' THEN '外部用'
            WHEN '2' THEN '伊藤園産業用'
        END                      pattern_name
       ,XDI.delivery_company_code                         --運送業者
       ,XCV.party_name                                    --運送業者名
       ,XDI.delivery_no                                   --配送No
       ,XDI.invoice_no                                    --送り状No
       ,XDI.p_b_classe                                    --支払請求区分
       ,FLV01.meaning                                     --支払請求区分名
       ,XDI.delivery_classe                               --配送区分
       ,FLV02.meaning                                     --配送区分名
       ,XDI.charged_amount                                --請求運賃
       ,XDI.qty1                                          --個数１
       ,XDI.qty2                                          --個数２
       ,XDI.delivery_weight1                              --重量１
       ,XDI.delivery_weight2                              --重量２
       ,XDI.distance                                      --距離
       ,XDI.many_rate                                     --諸料金
       ,XDI.congestion_charge                             --通行料
       ,XDI.picking_charge                                --ピッキング料
       ,XDI.consolid_surcharge                            --混載割増金額
       ,XDI.total_amount                                  --合計
       ,FU_CB.user_name         created_by_name           --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XDI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date             --作成日時
       ,FU_LU.user_name         last_updated_by_name      --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XDI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date          --更新日時
       ,FU_LL.user_name         last_update_login_name    --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  xxwip_deliverys_if      XDI                       --運賃アドオンインタフェース
       ,xxskz_carriers_v        XCV                       --SKYLINK用中間VIEW 運送業者取得VIEW
       ,fnd_lookup_values       FLV01                     --支払請求区分名取得用
       ,fnd_lookup_values       FLV02                     --配送区分名取得用
       ,fnd_user                FU_CB                     --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                FU_LU                     --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                FU_LL                     --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins              FL_LL                     --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE  XDI.delivery_company_code = XCV.freight_code(+)
    --請求データ
   AND  XDI.p_b_classe            = '2'
    --支払請求区分名取得条件
   AND  FLV01.language(+)         = 'JA'
   AND  FLV01.lookup_type(+)      = 'XXWIP_PAYCHARGE_TYPE'
   AND  FLV01.lookup_code(+)      = XDI.p_b_classe
   --配送区分名取得条件
   AND  FLV02.language(+)         = 'JA'
   AND  FLV02.lookup_type(+)      = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+)      = XDI.delivery_classe
   --WHOカラム取得
   AND  XDI.created_by            = FU_CB.user_id(+)
   AND  XDI.last_updated_by       = FU_LU.user_id(+)
   AND  XDI.last_update_login     = FL_LL.login_id(+)
   AND  FL_LL.user_id             = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_運賃アドオンIFKI_基本_V                     IS 'SKYLINK用運賃アドオンIF（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.パターン区分       IS 'パターン区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.パターン区分名     IS 'パターン区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.運送業者           IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.運送業者名         IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.配送NO             IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.送り状NO           IS '送り状No'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.支払請求区分       IS '支払請求区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.支払請求区分名     IS '支払請求区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.配送区分           IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.配送区分名         IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.請求運賃           IS '請求運賃'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.個数１             IS '個数１'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.個数２             IS '個数２'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.重量１             IS '重量１'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.重量２             IS '重量２'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.距離               IS '距離'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.諸料金             IS '諸料金'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.通行料             IS '通行料'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.ピッキング料       IS 'ピッキング料'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.混載割増金額       IS '混載割増金額'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.合計               IS '合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃アドオンIFKI_基本_V.最終更新ログイン   IS '最終更新ログイン'
/
