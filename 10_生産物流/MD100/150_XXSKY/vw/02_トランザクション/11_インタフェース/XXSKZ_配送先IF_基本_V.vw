/*************************************************************************
 * 
 * View  Name      : XXSKZ_配送先IF_基本_V
 * Description     : XXSKZ_配送先IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_配送先IF_基本_V
(
 SEQ番号
,更新区分
,更新区分名
,拠点コード
,拠点名
,配送先コード
,配送先名１
,配送先名２
,配送先住所１
,配送先住所２
,電話番号
,FAX番号
,郵便番号
,郵便番号２
,顧客コード
,顧客名１
,顧客名２
,当月売上拠点コード
,当月売上拠点名
,翌月_予約売上拠点コード
,翌月_予約売上拠点名
,売上チェーン店
,売上チェーン店名
,中止客申請フラグ
,中止客申請フラグ名
,直送区分
,直送区分名
)
AS
SELECT 
        XSI.seq_number                              --SEQ番号
       ,XSI.proc_code                               --更新区分
       ,CASE XSI.proc_code                          --更新区分名
            WHEN    1   THEN    '登録'
            WHEN    2   THEN    '更新'
            WHEN    3   THEN    '削除'
        END                     proc_name
       ,XSI.base_code                               --拠点コード
       ,XCAV01.party_name       party_name          --拠点名
       ,XSI.ship_to_code                            --配送先コード
       ,XSI.party_site_name1                        --配送先名１
       ,XSI.party_site_name2                        --配送先名２
       ,XSI.party_site_addr1                        --配送先住所１
       ,XSI.party_site_addr2                        --配送先住所２
       ,XSI.phone                                   --電話番号
       ,XSI.fax                                     --FAX番号
       ,XSI.ZIP                                     --郵便番号
       ,XSI.ZIP2                                    --郵便番号２
       ,XSI.party_num                               --顧客コード
       ,XSI.customer_name1                          --顧客名１
       ,XSI.customer_name2                          --顧客名２
       ,XSI.sale_base_code                          --当月売上拠点コード
       ,XCAV02.party_name       sale_base_name      --当月売上拠点名
       ,XSI.res_sale_base_code                      --翌月_予約売上拠点コード
       ,XCAV03.party_name       res_sale_base_name  --翌月_予約売上拠点名
       ,XSI.chain_store                             --売上チェーン店
       ,XSI.chain_store_name                        --売上チェーン店名
       ,XSI.cal_cust_app_flg                        --中止客申請フラグ
       ,FLV01.meaning                               --中止客申請フラグ名
       ,XSI.direct_ship_code                        --直送区分
       ,FLV02.meaning                               --直送区分名
  FROM  xxcmn_site_if           XSI                 --配送先インタフェース
       ,xxskz_cust_accounts_v   XCAV01              --SKYLINK用中間VIEW 拠点コード取得VIEW
       ,xxskz_cust_accounts_v   XCAV02              --SKYLINK用中間VIEW 拠点コード取得VIEW
       ,xxskz_cust_accounts_v   XCAV03              --SKYLINK用中間VIEW 拠点コード取得VIEW
       ,fnd_lookup_values       FLV01               --中止客申請フラグ名取得用
       ,fnd_lookup_values       FLV02               --直送区分名取得用
 WHERE
   --拠点名取得条件
        XCAV01.party_number(+)  = XSI.base_code
   --当月売上拠点名取得条件
   AND  XCAV02.party_number(+)  = XSI.sale_base_code
   --翌月_予約売上拠点名取得条件
   AND  XCAV03.party_number(+)  = XSI.res_sale_base_code
   --中止客申請フラグ名取得条件
   AND  FLV01.language(+)       = 'JA'
   AND  FLV01.lookup_type(+)    = 'XXCMN_CUST_ENABLE_FLAG'
   AND  FLV01.lookup_code(+)    = XSI.cal_cust_app_flg
   --直送区分名取得条件
   AND  FLV02.language(+)       = 'JA'
   AND  FLV02.lookup_type(+)    = 'XXCMN_DROP_SHIP_DIV'
   AND  FLV02.lookup_code(+)    = XSI.direct_ship_code
/
COMMENT ON TABLE APPS.XXSKZ_配送先IF_基本_V                             IS 'SKYLINK用配送先IF（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.SEQ番号                    IS 'SEQ番号'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.更新区分                   IS '更新区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.更新区分名                 IS '更新区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.拠点コード                 IS '拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.拠点名                     IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.配送先コード               IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.配送先名１                 IS '配送先名１'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.配送先名２                 IS '配送先名２'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.配送先住所１               IS '配送先住所１'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.配送先住所２               IS '配送先住所２'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.電話番号                   IS '電話番号'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.FAX番号                    IS 'FAX番号'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.郵便番号                   IS '郵便番号'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.郵便番号２                 IS '郵便番号２'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.顧客コード                 IS '顧客コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.顧客名１                   IS '顧客名１'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.顧客名２                   IS '顧客名２'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.当月売上拠点コード         IS '当月売上拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.当月売上拠点名             IS '当月売上拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.翌月_予約売上拠点コード    IS '翌月_予約売上拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.翌月_予約売上拠点名        IS '翌月_予約売上拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.売上チェーン店             IS '売上チェーン店'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.売上チェーン店名           IS '売上チェーン店名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.中止客申請フラグ           IS '中止客申請フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.中止客申請フラグ名         IS '中止客申請フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.直送区分                   IS '直送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配送先IF_基本_V.直送区分名                 IS '直送区分名'
/