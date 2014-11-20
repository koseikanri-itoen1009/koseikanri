/*************************************************************************
 * 
 * View  Name      : XXSKZ_価格表_現在_V
 * Description     : XXSKZ_価格表_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_価格表_現在_V
(
 価格表名
,仕入先コード
,仕入先名
,仕入先略称
,適用開始日
,適用終了日
,通貨
,通貨名
,丸め処理先
,有効フラグ
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,明細_適用開始日
,明細_適用終了日
,単位
,基準単位
,適用方法
,適用方法名
,値
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        QLHT.name                        --価格表名
       ,QLHT.name                        --仕入先コード
       ,VNDR.vendor_name                 --仕入先名
       ,VNDR.vendor_short_name           --仕入先略称
       ,QLHB.start_date_active           --適用開始日
       ,QLHB.end_date_active             --適用終了日
       ,QLHB.currency_code               --通貨
       ,FCT.name                         --通貨名
       ,QLHB.rounding_factor             --丸め処理先
       ,QLHB.active_flag                 --有効フラグ
       ,XPCV.prod_class_code             --商品区分
       ,XPCV.prod_class_name             --商品区分名
       ,XICV.item_class_code             --品目区分
       ,XICV.item_class_name             --品目区分名
       ,XCCV.crowd_code                  --群コード
       ,XIMV.item_no                     --品目コード
       ,XIMV.item_name                   --品目名
       ,XIMV.item_short_name             --品目略称
       ,QLL.start_date_active            --明細_適用開始日
       ,QLL.end_date_active              --明細_適用終了日
       ,QPA.product_uom_code             --単位
       ,QLL.primary_uom_flag             --基準単位
       ,QLL.arithmetic_operator          --適用方法
       ,FLV01.meaning                    --適用方法名
       ,QLL.operand                      --値
       ,FU_CB.user_name                  --作成者
       ,TO_CHAR( QLL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --作成日
       ,FU_LU.user_name                  --最終更新者
       ,TO_CHAR( QLL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --最終更新日
       ,FU_LL.user_name                  --最終更新ログイン
  FROM
        qp_list_headers_b       QLHB     --価格表ヘッダ
       ,qp_list_lines           QLL      --価格表明細
       ,qp_pricing_attributes   QPA      --価格表単位マスタ
       ,qp_list_headers_tl      QLHT     --価格表名
       ,xxskz_vendors_v         VNDR     --仕入先マスタ(現在日付検索用)
       ,fnd_currencies_tl       FCT      --価格表通貨マスタ
       ,xxskz_item_mst_v        XIMV     --OPM品目情報VIEW(品目)
       ,xxskz_prod_class_v      XPCV     --OPM品目区分VIEW(商品区分)
       ,xxskz_item_class_v      XICV     --OPM品目区分VIEW(品目区分)
       ,xxskz_crowd_code_v      XCCV     --OPM品目区分VIEW(群コード)
       ,fnd_user                FU_CB    --ユーザーマスタ(created_by名称取得用)
       ,fnd_user                FU_LU    --ユーザーマスタ(last_updated_by名称取得用)
       ,fnd_user                FU_LL    --ユーザーマスタ(last_update_login名称取得用)
       ,fnd_logins              FL_LL    --ログインマスタ(last_update_login名称取得用)
       ,fnd_lookup_values       FLV01    --クイックコード(適用方法名)
 WHERE
   --価格表情報取得
        QLHB.active_flag <> 'N'
   AND  (  QLHB.start_date_active IS NULL
        OR QLHB.start_date_active <= TRUNC(SYSDATE) )
   AND  (  QLHB.end_date_active IS NULL
        OR QLHB.end_date_active >= TRUNC(SYSDATE) )
   AND  QLHB.list_header_id = QLL.list_header_id
   --価格表単位マスタ情報取得
   AND  QPA.product_attribute_context = 'ITEM'             --製品コンテキストが「Item」
   AND  QPA.product_attribute = 'PRICING_ATTRIBUTE1'       --製品属性が「品目番号」
   AND  QLL.list_line_id = QPA.list_line_id
   --価格表名(仕入先コード)取得
   AND  QLHT.language(+) = 'JA'	
   AND  QLHB.list_header_id = QLHT.list_header_id(+)
   --仕入先名取得
   AND  QLHT.name = VNDR.segment1(+)
   --価格表通貨情報取得
   AND  FCT.language(+) = 'JA'
   AND  FCT.currency_code(+) = QLHB.currency_code
   --品目情報取得
   AND  QPA.product_attr_value = XIMV.inventory_item_id(+)
   --品目カテゴリ情報取得
   AND  XIMV.item_id = XPCV.item_id(+)
   AND  XIMV.item_id = XICV.item_id(+)
   AND  XIMV.item_id = XCCV.item_id(+)
   --WHOカラム情報取得
   AND  QLL.created_by        = FU_CB.user_id(+)
   AND  QLL.last_updated_by   = FU_LU.user_id(+)
   AND  QLL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   --【クイックコード】適用方法名取得
   AND  FLV01.language(+)    = 'JA'                        --言語
   AND  FLV01.lookup_type(+) = 'ARITHMETIC_OPERATOR'       --クイックコードタイプ
   AND  FLV01.lookup_code(+) = QLL.ARITHMETIC_OPERATOR     --クイックコード
/
COMMENT ON TABLE APPS.XXSKZ_価格表_現在_V IS 'SKYLINK用価格表（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.価格表名         IS '価格表名'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.仕入先コード     IS '仕入先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.仕入先名         IS '仕入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.仕入先略称       IS '仕入先略称'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.適用開始日       IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.適用終了日       IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.通貨             IS '通貨'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.通貨名           IS '通貨名'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.丸め処理先       IS '丸め処理先'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.有効フラグ       IS '有効フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.商品区分         IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.商品区分名       IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.品目区分         IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.品目区分名       IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.群コード         IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.品目コード       IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.品目名           IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.品目略称         IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.明細_適用開始日  IS '明細_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.明細_適用終了日  IS '明細_適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.単位             IS '単位'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.基準単位         IS '基準単位'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.適用方法         IS '適用方法'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.適用方法名       IS '適用方法名'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.値               IS '値'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.作成者           IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.作成日           IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.最終更新者       IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.最終更新日       IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_価格表_現在_V.最終更新ログイン IS '最終更新ログイン'
/