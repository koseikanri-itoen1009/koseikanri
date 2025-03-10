CREATE OR REPLACE PACKAGE BODY apps.xxcos_edi_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcos_edi_common_pkg(body)
 * Description            :
 * MD.070                 : MD070_IPO_COS_共通関数
 * Version                : 1.12
 *
 * Program List
 *  ----------------------------- ---- ----- -----------------------------------------
 *   Name                         Type  Ret   Description
 *  ----------------------------- ---- ----- -----------------------------------------
 *  edi_manual_order_acquisition  P          EDI受注手入力分取込
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/26   1.0   H.Fujimoto       新規作成
 *  2009/03/03   1.1   H.Fujimoto       結合不具合No152
 *  2009/03/24   1.2   T.Miyata         ST障害：T1_0126
 *  2009/04/24   1.3   K.Kiriu          ST障害：T1_0112
 *  2009/06/19   1.4   N.Maeda          [T1_1358]対応
 *  2009/07/13   1.5   K.Kiriu          [0000660]対応
 *  2009/07/14   1.6   K.Kiriu          [0000064]対応
 *  2009/08/11   1.7   K.Kiriu          [0000966]対応
 *  2010/03/09   1.8   S.Karikomi       [E_本稼働_01637]対応
 *  2010/04/15   1.9   S.Karikomi       [E_本稼動_02296]対応
 *  2010/07/13   1.10  S.Niki           [E_本稼動_02637]対応
 *  2012/08/24   1.11  K.Onotsuka       [E_本稼動_09938]対応
 *  2018/07/03   1.12  K.Kiriu          [E_本稼動_15116]対応
 *****************************************************************************************/
  -- ===============================
  -- グローバル変数
  -- ===============================
  gv_msg_part VARCHAR2(100) := ' : ';
--
  /**********************************************************************************
   * Procedure Name   : edi_manual_order_acquisition
   * Description      : EDI受注手入力分取込
   ***********************************************************************************/
  PROCEDURE edi_manual_order_acquisition(
               iv_edi_chain_code           IN VARCHAR2  DEFAULT NULL  -- EDIチェーン店コード
              ,iv_edi_forward_number       IN VARCHAR2  DEFAULT NULL  -- EDI伝送追番
              ,id_shop_delivery_date_from  IN DATE      DEFAULT NULL  -- 店舗納品日(From)
              ,id_shop_delivery_date_to    IN DATE      DEFAULT NULL  -- 店舗納品日(To)
              ,iv_regular_ar_sale_class    IN VARCHAR2  DEFAULT NULL  -- 定番特売区分
              ,iv_area_code                IN VARCHAR2  DEFAULT NULL  -- 地区コード
              ,id_center_delivery_date     IN DATE      DEFAULT NULL  -- センター納品日
              ,in_organization_id          IN NUMBER    DEFAULT NULL  -- 在庫組織ID
/* 2010/07/13 Ver1.10 Add Start */
              ,iv_boot_flag                IN VARCHAR2  DEFAULT NULL  -- 起動種別(1:コンカレント、2:画面)
              ,ov_err_flag                 OUT NOCOPY VARCHAR2        -- エラー種別
/* 2010/07/13 Ver1.10 Add End */
              ,ov_errbuf                   OUT NOCOPY VARCHAR2        -- エラー・メッセージ           --# 固定 #
              ,ov_retcode                  OUT NOCOPY VARCHAR2        -- リターン・コード             --# 固定 #
              ,ov_errmsg                   OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
            )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_edi_common_pkg.edi_manual_order_acquisition'; -- プログラム名
--
/* 2009/07/13 Ver1.5 Add Start */
    --メッセージ
    cv_msg_sales_class      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00034';  --売上区分混在エラー
    cv_msg_not_outbound     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13593';  --OUTBOUD可否エラー
/* 2009/08/11 Ver1.7 Add Start */
    cv_msg_prf_err          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';  --プロファイル取得エラー
    cv_msg_org_prf_name     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';  --MO:営業単位
/* 2009/08/11 Ver1.7 Add End   */
/* 2010/07/13 Ver1.10 Add Start */
    cv_msg_cust_item_err    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13597';  --顧客品目チェックエラー
/* 2010/07/13 Ver1.10 Add End */
    --トークン
    cv_tkn_order_no         CONSTANT VARCHAR2(20) := 'ORDER_NO';          --伝票番号
    cv_tkn_line_no          CONSTANT VARCHAR2(20) := 'LINE_NUMBER';       --明細番号
/* 2009/07/13 Ver1.5 Add End   */
/* 2009/08/11 Ver1.7 Add Start */
    cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';           --プロファイル
/* 2012/08/24 Ver1.11 Add Start */
    cv_tkn_invoice_number   CONSTANT VARCHAR2(14) := 'INVOICE_NUMBER';    -- 伝票番号
/* 2012/08/24 Ver1.11 Add End */
/* 2009/08/11 Ver1.7 Add End   */
    cv_cstm_class_base      CONSTANT VARCHAR2(2)  := '1';       -- 顧客区分:拠点
/* 2010/04/15 Ver1.9 Add Start */
    cv_hw_slip_div_yes      CONSTANT VARCHAR2(1)  := '1';       -- EDI手書伝票伝送区分:伝送あり
/* 2010/04/15 Ver1.9 Add End   */
/* 2018/07/03 Ver1.12 Add Start */
    cv_hw_slip_div_yes3     CONSTANT VARCHAR2(1)  := '3';       -- EDI手書伝票伝送区分:伝送あり(HHT)
    cv_hw_slip_div_yes4     CONSTANT VARCHAR2(1)  := '4';       -- EDI手書伝票伝送区分:伝送あり(全て)
    cv_create_hht           CONSTANT VARCHAR2(1)  := '1';       -- 発生元区分（HHT）
/* 2018/07/03 Ver1.12 Add End  */
    cv_cstm_class_customer  CONSTANT VARCHAR2(2)  := '10';      -- 顧客区分:顧客
    cv_cstm_class_chain     CONSTANT VARCHAR2(2)  := '18';      -- 顧客区分:チェーン店
    cv_flow_status_entry    CONSTANT VARCHAR2(6)  := 'BOOKED';  -- ステータス:記帳済み
--*** 2009/03/24 Ver1.3 MODIFY START ***
--  cn_order_source         CONSTANT NUMBER       := 0;         -- 受注ソースID:画面入力
--  cn_order_type           CONSTANT NUMBER       := 1068;      -- 受注タイプID:通常受注
--  cn_line_type            CONSTANT NUMBER       := 1054;      -- 明細タイプID:通常出荷
    cv_xxcos_appl_short_nm  CONSTANT VARCHAR2(5)  := 'XXCOS';   -- 販物短縮アプリ名
    cv_xxcos1_order_edi_common                                  -- EDI手入力特定マスタ
                            CONSTANT VARCHAR2(23) := 'XXCOS1_ORDER_EDI_COMMON';
--*** 2009/03/24 Ver1.3 MODIFY END   ***
    cv_tukzik_div_tuk       CONSTANT VARCHAR2(2)  := '11';      -- 通過在庫型区分:センター納品(通過型・受注)
    cv_tukzik_div_zik       CONSTANT VARCHAR2(2)  := '12';      -- 通過在庫型区分:センター納品(在庫型・受注)
    cv_tukzik_div_tnp       CONSTANT VARCHAR2(2)  := '24';      -- 通過在庫型区分:店舗納品
    cv_flag_yes             CONSTANT VARCHAR2(1)  := 'Y';       -- フラグ:'Y'
    cv_flag_no              CONSTANT VARCHAR2(1)  := 'N';       -- フラグ:'N'
--************************** 2009/06/19 N.Maeda Mod start *********************************--
--    cv_ras_class_all        CONSTANT VARCHAR2(1)  := '0';       -- 定番特売区分:ALL
    cv_ras_class_all        CONSTANT VARCHAR2(2)  := '00';      -- 定番特売区分:ALL
--************************** 2009/06/19 N.Maeda Mod  end  *********************************--
    cv_unit_case            CONSTANT VARCHAR2(2)  := 'CS';      -- 単位:ケース
    cv_unit_bowl            CONSTANT VARCHAR2(2)  := 'BL';      -- 単位:ボール
/* 2009/07/13 Ver1.5 Del Start */
--    cv_sale_class_error     CONSTANT VARCHAR2(1)  := '1';       -- 売上区分混在エラー
--    cv_outbound_error       CONSTANT VARCHAR2(1)  := '2';       -- OUTBOUND可否エラー
/* 2009/07/13 Ver1.5 Del End   */
    cv_medium_class         CONSTANT VARCHAR2(2)  := '01';      -- 媒体区分
    cv_data_type_code       CONSTANT VARCHAR2(2)  := '11';      -- データ種コード
    cv_creation_class       CONSTANT VARCHAR2(2)  := '01';      -- 作成元区分
    cv_file_no              CONSTANT VARCHAR2(2)  := '00';      -- ファイルＮｏ
    cv_stockout_class       CONSTANT VARCHAR2(2)  := '00';      -- 欠品区分
    cv_user_env_lang        CONSTANT VARCHAR2(4)  := 'lang';    -- 環境変数:言語
    cv_ltype_sale_class     CONSTANT VARCHAR2(25) := 'XXCOS1_SALE_CLASS';  -- 参照タイプ・コード:売上区分
    cv_tbl_name_head        CONSTANT VARCHAR2(13) := 'EDIヘッダ情報';      -- テーブル名:EDIヘッダ情報
    cv_tbl_name_line        CONSTANT VARCHAR2(11) := 'EDI明細情報';        -- テーブル名:EDI明細情報
/* 2010/07/13 Ver1.10 Add Start */
    cv_flag_0               CONSTANT VARCHAR2(1)  := '0';       -- 0:初期値
    cv_flag_1               CONSTANT VARCHAR2(1)  := '1';       -- 1:未登録
    cv_flag_2               CONSTANT VARCHAR2(1)  := '2';       -- 2:複数件登録
    cv_flag_3               CONSTANT VARCHAR2(1)  := '3';       -- 3:両方
    cv_boot_flag_conc       CONSTANT VARCHAR2(1)  := '1';       -- 1:コンカレント起動
    cv_boot_flag_form       CONSTANT VARCHAR2(1)  := '2';       -- 2:画面起動
/* 2010/07/13 Ver1.10 Add End */
/* 2012/08/24 Ver1.11 Add Start */
    cv_invoice_number       CONSTANT VARCHAR2(16) := ' 、伝票コード： '; -- 固定値:伝票コード：(品目例外エラーメッセージ用)
    cv_message_end          CONSTANT VARCHAR2(2)  := ' )';               -- 固定値:)(品目例外エラーメッセージ用)
/* 2012/08/24 Ver1.11 Add End */
/* 2009/08/11 Ver1.7 Add Start */
    --プロファイル名称
    ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID'; --MO:営業単位
/* 2009/08/11 Ver1.7 Add Start */
--
    -- ヘッダテーブル
    TYPE order_head_rtype IS RECORD (
         acquisition_flag       xxcos_edi_headers.order_connection_number%TYPE   -- EDIヘッダ情報.受注関連番号
        ,header_id              oe_order_headers_all.header_id%TYPE              -- 受注ヘッダ.受注ヘッダID
        ,ordered_date           oe_order_headers_all.ordered_date%TYPE           -- 受注ヘッダ.受注日
        ,request_date           oe_order_headers_all.request_date%TYPE           -- 受注ヘッダ.要求日
        ,cust_po_number         oe_order_headers_all.cust_po_number%TYPE         -- 受注ヘッダ.顧客発注
        ,order_number           oe_order_headers_all.order_number%TYPE           -- 受注ヘッダ.受注番号
        ,orig_sys_document_ref  oe_order_headers_all.orig_sys_document_ref%TYPE  -- 受注ヘッダ.外部システム受注番号
        ,price_list_id          oe_order_headers_all.price_list_id%TYPE          -- 受注ヘッダ.価格表ID
/* 2009/07/14 Ver1.6 Add Start */
        ,invoice_class          oe_order_headers_all.attribute5%TYPE             -- 受注ヘッダ.DFF5(伝票区分)
        ,classification_code    oe_order_headers_all.attribute20%TYPE            -- 受注ヘッダ.DFF20(分類区分)
/* 2009/07/14 Ver1.6 Add End   */
        ,account_number         hz_cust_accounts.account_number%TYPE             -- 顧客マスタ(顧客).顧客コード
        ,customer_name          hz_parties.party_name%TYPE                       -- パーティ(顧客).名称
        ,customer_name_alt      hz_parties.organization_name_phonetic%TYPE       -- パーティ(顧客).名称(カナ)
        ,base_code              xxcmm_cust_accounts.delivery_base_code%TYPE      -- 顧客追加(顧客).納品拠点コード
        ,store_code             xxcmm_cust_accounts.store_code%TYPE              -- 顧客追加(顧客).店舗コード
        ,cust_store_name        xxcmm_cust_accounts.cust_store_name%TYPE         -- 顧客追加(顧客).顧客店舗名称
        ,edi_district_code      xxcmm_cust_accounts.edi_district_code%TYPE       -- 顧客追加(顧客).EDI地区コード(EDI)
        ,edi_district_name      xxcmm_cust_accounts.edi_district_name%TYPE       -- 顧客追加(顧客).EDI地区名(EDI)
        ,edi_district_kana      xxcmm_cust_accounts.edi_district_kana%TYPE       -- 顧客追加(顧客).EDI地区名カナ(EDI)
        ,edi_chain_code         xxcmm_cust_accounts.edi_chain_code%TYPE          -- 顧客追加(ﾁｪｰﾝ).EDIチェーン店コード
        ,edi_chain_name         hz_parties.party_name%TYPE                       -- パーティ(ﾁｪｰﾝ).名称
        ,edi_chain_name_alt     hz_parties.organization_name_phonetic%TYPE       -- パーティ(ﾁｪｰﾝ).名称(カナ)
        ,base_name              hz_parties.party_name%TYPE                       -- パーティ(拠点).名称
        ,base_name_alt          hz_parties.organization_name_phonetic%TYPE       -- パーティ(拠点).名称(カナ)
    );
    -- 明細テーブル
    TYPE order_line_rtype IS RECORD (
         line_number         oe_order_lines_all.line_number%TYPE         -- 受注明細.行番号
        ,ordered_item        oe_order_lines_all.ordered_item%TYPE        -- 受注明細.受注品目
        ,order_quantity_uom  oe_order_lines_all.order_quantity_uom%TYPE  -- 受注明細.受注単位
        ,ordered_quantity    oe_order_lines_all.ordered_quantity%TYPE    -- 受注明細.受注数量
        ,orig_sys_line_refw  oe_order_lines_all.orig_sys_line_ref%TYPE   -- 受注明細.外部システム受注明細番号
        ,unit_selling_price  oe_order_lines_all.unit_selling_price%TYPE  -- 販売単価
/* 2010/03/09 Ver1.8 Add Start */
        ,selling_price       xxcos_edi_lines.selling_price%TYPE          -- 売単価
        ,order_price_amt     xxcos_edi_lines.order_price_amt%TYPE        -- 売価金額(発注)
/* 2010/03/09 Ver1.8 Add  End  */
        ,num_of_case         ic_item_mst_b.attribute11%TYPE              -- OPM品目.DFF11(ケース入数)
        ,jan_code            ic_item_mst_b.attribute21%TYPE              -- OPM品目.DFF21(JANコード)
        ,itf_code            ic_item_mst_b.attribute22%TYPE              -- OPM品目.DFF22(ITFコード)
        ,item_code           mtl_system_items_b.segment1%TYPE            -- Disc品目.品名コード
        ,num_of_bowl         xxcmm_system_items_b.bowl_inc_num%TYPE      -- Disc品目アドオン.ボール入数
        ,regular_sale_class  fnd_lookup_values.attribute8%TYPE           -- クイックコード.DFF8(定番特売区分)
        ,outbound_flag       fnd_lookup_values.attribute10%TYPE          -- クイックコード.DFF10(OUTBOUND可否)
/* 2009/03/03 Ver1.1 Add Start */
        ,item_name           xxcmn_item_mst_b.item_name%TYPE             -- OPM品目アドオン.正式名
        ,item_name_alt       xxcmn_item_mst_b.item_name_alt%TYPE         -- OPM品目アドオン.カナ名
/* 2009/03/03 Ver1.1 Add  End  */
/* 2009/04/24 Ver1.3 Add Start */
        ,edi_rep_uom         mtl_units_of_measure_tl.attribute1%TYPE     -- EDI・帳票用単位
/* 2009/04/24 Ver1.3 Add End   */
    );
    -- 伝票計テーブル
    TYPE invoice_sum_rtype IS RECORD (
         invoice_number               VARCHAR2(50)      -- 伝票番号
        ,invoice_indv_order_qty       NUMBER DEFAULT 0  -- 発注数量(バラ)
        ,invoice_case_order_qty       NUMBER DEFAULT 0  -- 発注数量(ケース)
        ,invoice_ball_order_qty       NUMBER DEFAULT 0  -- 発注数量(ボール)
        ,invoice_sum_order_qty        NUMBER DEFAULT 0  -- 発注数量(合計、バラ)
        ,invoice_indv_shipping_qty    NUMBER DEFAULT 0  -- 出荷数量(バラ)
        ,invoice_case_shipping_qty    NUMBER DEFAULT 0  -- 出荷数量(ケース)
        ,invoice_ball_shipping_qty    NUMBER DEFAULT 0  -- 出荷数量(ボール)
        ,invoice_pallet_shipping_qty  NUMBER DEFAULT 0  -- 出荷数量(パレット)
        ,invoice_sum_shipping_qty     NUMBER DEFAULT 0  -- 出荷数量(合計、バラ)
        ,invoice_indv_stockout_qty    NUMBER DEFAULT 0  -- 欠品数量(バラ)
        ,invoice_case_stockout_qty    NUMBER DEFAULT 0  -- 欠品数量(ケース)
        ,invoice_ball_stockout_qty    NUMBER DEFAULT 0  -- 欠品数量(ボール)
        ,invoice_sum_stockout_qty     NUMBER DEFAULT 0  -- 欠品数量(合計、バラ)
        ,invoice_case_qty             NUMBER DEFAULT 0  -- ケース個口数
        ,invoice_fold_container_qty   NUMBER DEFAULT 0  -- オリコン(バラ)個口数
        ,invoice_order_cost_amt       NUMBER DEFAULT 0  -- 原価金額(発注)
        ,invoice_shipping_cost_amt    NUMBER DEFAULT 0  -- 原価金額(出荷)
        ,invoice_stockout_cost_amt    NUMBER DEFAULT 0  -- 原価金額(欠品)
        ,invoice_order_price_amt      NUMBER DEFAULT 0  -- 売価金額(発注)
        ,invoice_shipping_price_amt   NUMBER DEFAULT 0  -- 売価金額(出荷)
        ,invoice_stockout_price_amt   NUMBER DEFAULT 0  -- 売価金額(欠品)
    );
    -- ヘッダ編集テーブル
    TYPE head_edit_rtype IS RECORD (
         edi_header_info_id  xxcos_edi_headers.edi_header_info_id%TYPE  -- EDIヘッダ情報ID
        ,ar_sale_class       xxcos_edi_headers.ar_sale_class%TYPE       -- 特売区分
    );
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    -- PL/SQL表型
    TYPE order_head_ttype   IS TABLE OF order_head_rtype   INDEX BY BINARY_INTEGER;  -- ヘッダテーブル
    TYPE order_line_ttype   IS TABLE OF order_line_rtype   INDEX BY BINARY_INTEGER;  -- 明細テーブル
    TYPE invoice_sum_ttype  IS TABLE OF invoice_sum_rtype  INDEX BY BINARY_INTEGER;  -- 伝票計テーブル
    TYPE head_edit_ttype    IS TABLE OF head_edit_rtype    INDEX BY BINARY_INTEGER;  -- ヘッダ編集テーブル
--
    -- PL/SQL表
    lt_head_tab          order_head_ttype;     -- ヘッダテーブル
    lt_line_tab          order_line_ttype;     -- 明細テーブル
    lt_invoice_tab       invoice_sum_ttype;    -- 伝票計テーブル
    lt_head_edit_tab     head_edit_ttype;      -- ヘッダ編集テーブル
--
    ln_head_cnt          NUMBER;           -- ヘッダテーブル用カウンタ
    ln_line_cnt          NUMBER;           -- 明細テーブル用カウンタ
    ln_invoice_cnt       NUMBER;           -- 伝票計テーブル用カウンタ
    lv_sale_class_check  VARCHAR2(1);      -- 売上区分対象
    ln_line_info_id      NUMBER;           -- EDI明細情報ID
    ln_user_id           NUMBER;           -- ユーザID
    ln_login_id          NUMBER;           -- ログインID
    ld_sysdate           DATE;             -- システム日付
    ln_case_qty          NUMBER;           -- ケース数
    ln_bowl_qty          NUMBER;           -- ボール数
    ln_indv_qty          NUMBER;           -- バラ数
    lv_language          VARCHAR2(10);     -- 言語
--
    lv_product_code2     VARCHAR2(16);     -- 商品コード２
    lv_jan_code          VARCHAR2(13);     -- JANコード
    lv_case_jan_code     VARCHAR2(13);     -- ケースJANコード
/* 2010/07/13 Ver1.10 Add Start */
    lv_err_flag          VARCHAR2(1);      -- エラー種別(1:未登録、2:複数件登録、3:両方)
    lv_err_flag_tmp      VARCHAR2(1);      -- エラー種別tmp
/* 2010/07/13 Ver1.10 Add End */
    lv_table_name        VARCHAR2(15);     -- テーブル名
    lv_errbuf            VARCHAR2(5000);   -- エラー・メッセージエラー
    lv_retcode           VARCHAR2(1);      -- リターン・コード
    lv_errmsg            VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
    lv_ret_normal        VARCHAR2(1);      -- リターン・コード:正常
/* 2010/07/13 Ver1.10 Add Start */
    lv_ret_warn          VARCHAR2(1);      -- リターン・コード:警告
    lv_ret_error         VARCHAR2(1);      -- リターン・コード:エラー
    lv_warn_flag         VARCHAR2(1);      -- 警告フラグ
/* 2010/07/13 Ver1.10 Add End */
/* 2009/08/11 Ver1.7 Add Start */
    ln_org_id            NUMBER;           -- ORG_ID
    lv_msg_string        VARCHAR2(5000);   -- メッセージ用文字列格納変数
    ld_shop_delivery_date_from DATE;       -- 引数TRUNC用(店舗納品日Form)
    ld_shop_delivery_date_to   DATE;       -- 引数TRUNC用(店舗納品日To)
    ld_center_delivery_date    DATE;       -- 引数TRUNC用(センター納品日)
/* 2009/08/11 Ver1.7 Add End   */
--
    -- ================
    -- ユーザー定義例外
    -- ================
    sale_class_expt    EXCEPTION;  -- 売上区分が混在した場合の例外
    outbound_expt      EXCEPTION;  -- OUTBOUND可否が'N'の場合の例外
    table_insert_expt  EXCEPTION;  -- 挿入に失敗した場合の例外
    item_conv_expt     EXCEPTION;  -- 品目変換の例外
/* 2009/08/11 Ver1.7 Add Start */
    org_id_expt        EXCEPTION;  -- ORG_ID取得例外
/* 2009/08/11 Ver1.7 Add End   */
/* 2010/07/13 Ver1.10 Add Start */
    conv_err_expt      EXCEPTION;  -- 品目変換の例外
/* 2010/07/13 Ver1.10 Add End   */
--
    PRAGMA EXCEPTION_INIT(sale_class_expt,   -20000);
    PRAGMA EXCEPTION_INIT(outbound_expt,     -20001);
    PRAGMA EXCEPTION_INIT(table_insert_expt, -20002);
    PRAGMA EXCEPTION_INIT(item_conv_expt,    -20003);
/* 2009/08/11 Ver1.7 Add Start */
    PRAGMA EXCEPTION_INIT(org_id_expt,       -20004);
/* 2009/08/11 Ver1.7 Add End   */
/* 2010/07/13 Ver1.10 Add Start */
    PRAGMA EXCEPTION_INIT(conv_err_expt,     -20005);
/* 2010/07/13 Ver1.10 Add End   */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := xxccp_common_pkg.set_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_user_id     := FND_GLOBAL.USER_ID;                  -- ユーザID
    ln_login_id    := FND_GLOBAL.LOGIN_ID;                 -- ログインID
    ld_sysdate     := TRUNC(SYSDATE);                      -- システム日付
    lv_language    := USERENV(cv_user_env_lang);           -- 言語
    lv_ret_normal  := xxccp_common_pkg.set_status_normal;  -- リターンコード:正常
/* 2010/07/13 Ver1.10 Add Start */
    lv_ret_warn    := xxccp_common_pkg.set_status_warn;    -- リターンコード:警告
    lv_ret_error   := xxccp_common_pkg.set_status_error;   -- リターンコード:エラー
/* 2010/07/13 Ver1.10 Add End */
/* 2009/08/11 Ver1.7 Add Start */
    ld_shop_delivery_date_from  := TRUNC(id_shop_delivery_date_from);  -- 引数をTRUNC(店舗納品日Form)
    ld_shop_delivery_date_to    := TRUNC(id_shop_delivery_date_to);    -- 引数をTRUNC(店舗納品日To)
    ld_center_delivery_date     := TRUNC(id_center_delivery_date);     -- 引数をTRUNC(センター納品日)
--
    ln_org_id      := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_org_id ) ); -- ORG_ID
--
    --ORG_IDが取得できない場合はエラー
    IF ( ln_org_id IS NULL ) THEN
      lv_msg_string := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_appl_short_nm
                         ,iv_name        => cv_msg_org_prf_name
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_nm
                     ,iv_name         => cv_msg_prf_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => lv_msg_string
                   );
      RAISE org_id_expt;
    END IF;
/* 2009/08/11 Ver1.7 Add End   */
--
/* 2010/07/13 Ver1.10 Add Start */
      -- フラグ初期化
      lv_warn_flag    := cv_flag_no;
      lv_err_flag_tmp := cv_flag_0;
/* 2010/07/13 Ver1.10 Add End */
--
    -- ヘッダ情報読込
    SELECT
/* 2009/08/11 Ver1.7 Add Start */
       /*+
          LEADING(xca2)
          USE_NL(xca1)
       */
/* 2009/08/11 Ver1.7 Add End   */
       xeh.order_connection_number     -- EDIヘッダ情報.受注関連番号
      ,ooha.header_id                  -- 受注ヘッダ.受注ヘッダID
      ,ooha.ordered_date               -- 受注ヘッダ.受注日
      ,ooha.request_date               -- 受注ヘッダ.要求日
      ,ooha.cust_po_number             -- 受注ヘッダ.顧客発注
      ,ooha.order_number               -- 受注ヘッダ.受注番号
      ,ooha.orig_sys_document_ref      -- 受注ヘッダ.外部システム受注番号
      ,ooha.price_list_id              -- 受注ヘッダ.価格表ID
/* 2009/07/14 Ver1.6 Add Start */
      ,ooha.attribute5                 -- 受注ヘッダ.DFF5(伝票区分)
      ,ooha.attribute20                -- 受注ヘッダ.DFF20(分類区分)
/* 2009/07/14 Ver1.6 Add End   */
      ,hca1.account_number             -- 顧客マスタ(顧客).顧客コード
      ,hp1.party_name                  -- パーティ(顧客).名称
      ,hp1.organization_name_phonetic  -- パーティ(顧客).名称(カナ)
      ,xca1.delivery_base_code         -- 顧客追加(顧客).納品拠点コード
      ,xca1.store_code                 -- 顧客追加(顧客).店舗コード
      ,xca1.cust_store_name            -- 顧客追加(顧客).顧客店舗名称
      ,xca1.edi_district_code          -- 顧客追加(顧客).EDI地区コード(EDI)
      ,xca1.edi_district_name          -- 顧客追加(顧客).EDI地区名(EDI)
      ,xca1.edi_district_kana          -- 顧客追加(顧客).EDI地区名カナ(EDI)
      ,xca2.edi_chain_code             -- 顧客追加(ﾁｪｰﾝ).EDIチェーン店コード
      ,hp2.party_name                  -- パーティ(ﾁｪｰﾝ).名称
      ,hp2.organization_name_phonetic  -- パーティ(ﾁｪｰﾝ).名称(カナ)
      ,hp3.party_name                  -- パーティ(拠点).名称
      ,hp3.organization_name_phonetic  -- パーティ(拠点).名称(カナ)
     BULK COLLECT INTO lt_head_tab
     FROM oe_order_headers_all  ooha  -- 受注ヘッダ
         ,hz_cust_accounts      hca1  -- 顧客マスタ(顧客)
         ,xxcmm_cust_accounts   xca1  -- 顧客追加(顧客)
         ,hz_parties            hp1   -- パーティ(顧客)
         ,hz_cust_accounts      hca2  -- 顧客マスタ(ﾁｪｰﾝ)
         ,xxcmm_cust_accounts   xca2  -- 顧客追加(ﾁｪｰﾝ)
         ,hz_parties            hp2   -- パーティ(ﾁｪｰﾝ)
         ,hz_cust_accounts      hca3  -- 顧客マスタ(拠点)
         ,hz_parties            hp3   -- パーティ(拠点)
         ,xxcos_edi_headers     xeh   -- EDIヘッダ情報
--*** 2009/03/24 Ver1.3 ADD    START ***
         ,oe_order_sources        oos   -- 受注ソーステーブル
         ,oe_transaction_types_tl ottt  -- 受注タイプテーブル
--*** 2009/03/24 Ver1.3 ADD    END   ***/
     WHERE ooha.sold_to_org_id         =  hca1.cust_account_id            -- 受注ヘッダ      ＝顧客マスタ(顧客)
/* 2009/08/11 Ver1.7 Mod Start */
--     AND   hca1.cust_account_id        =  xca1.customer_id                -- 顧客マスタ(顧客)＝顧客追加(顧客)
     AND   hca1.account_number         =  xca1.customer_code              -- 顧客マスタ(顧客)＝顧客追加(顧客)
/* 2009/08/11 Ver1.7 Mod End   */
     AND   hca1.party_id               =  hp1.party_id                    -- 顧客マスタ(顧客)＝パーティ(顧客)
     AND   xca1.chain_store_code       =  xca2.edi_chain_code             -- 顧客追加(顧客)  ＝顧客追加(ﾁｪｰﾝ)
     AND   hca2.cust_account_id        =  xca2.customer_id                -- 顧客マスタ(ﾁｪｰﾝ)＝顧客追加(ﾁｪｰﾝ)
     AND   hca2.party_id               =  hp2.party_id                    -- 顧客マスタ(ﾁｪｰﾝ)＝パーティ(ﾁｪｰﾝ)
     AND   xca1.delivery_base_code     =  hca3.account_number             -- 顧客マスタ(顧客)＝顧客マスタ(拠点)
     AND   hca3.party_id               =  hp3.party_id                    -- 顧客マスタ(拠点)＝パーティ(拠点)
     AND   ooha.orig_sys_document_ref  =  xeh.order_connection_number(+)  -- 受注ヘッダ      ＝EDIヘッダ情報
     /* 顧客区分 */
     AND   hca1.customer_class_code    =  cv_cstm_class_customer   -- 顧客マスタ(顧客).顧客区分='10'(顧客)
     AND   hca2.customer_class_code    =  cv_cstm_class_chain      -- 顧客マスタ(ﾁｪｰﾝ).顧客区分='18'(ﾁｪｰﾝ店)
     AND   hca3.customer_class_code    =  cv_cstm_class_base       -- 顧客マスタ(拠点).顧客区分='1'(拠点)
/* 2010/04/15 Ver1.9 Add Start */
     /* EDI手書伝票伝送区分 */ 
/* 2018/07/03 Ver1.12 Mod Start */
--     AND   xca2.handwritten_slip_div   =  cv_hw_slip_div_yes       -- 顧客追加(ﾁｪｰﾝ).EDI手書伝票伝送区分＝'1'(伝送あり)
     AND   (
             (
               ( xca2.handwritten_slip_div = cv_hw_slip_div_yes )   -- 顧客追加(ﾁｪｰﾝ).EDI手書伝票伝送区分＝'1'(伝送あり（クイック受注）)
               AND
               ( ooha.global_attribute5 IS NULL )                   -- 発生元区分：NULL=クイック受注
             )
             OR
             (
               ( xca2.handwritten_slip_div = cv_hw_slip_div_yes3 )  -- 顧客追加(ﾁｪｰﾝ).EDI手書伝票伝送区分＝'3'(伝送あり（HHT）)
               AND
               ( ooha.global_attribute5 = cv_create_hht )           -- 発生元区分：1=HHT
             )
             OR
             (
               ( xca2.handwritten_slip_div = cv_hw_slip_div_yes4 )    -- 顧客追加(ﾁｪｰﾝ).EDI手書伝票伝送区分＝'4'(伝送あり（全て）)
             )
           )
/* 2018/07/03 Ver1.12 Mod End   */
/* 2010/04/15 Ver1.9 Add End   */
     /* 受注ヘッダ抽出条件 */
/* 2009/08/11 Ver1.7 Add Start */
     AND   ooha.org_id                 =  ln_org_id              -- ORG_ID＝プロファイル値
/* 2009/08/11 Ver1.7 Add End   */
     AND   ooha.flow_status_code       =  cv_flow_status_entry   -- ステータス  ＝記帳済み
--*** 2009/03/24 Ver1.3 MODIFY START ***
--   AND   ooha.order_source_id        =  cn_order_source        -- 受注ソースID＝画面入力
--   AND   ooha.order_type_id          =  cn_order_type          -- 受注タイプID＝通常受注
--
     AND   ooha.order_source_id        =  oos.order_source_id      -- 受注ヘッダ.受注ソースID＝受注ソース.受注ソースID
     AND   ooha.order_type_id          =  ottt.transaction_type_id -- 受注ヘッダ.受注タイプID＝受注タイプ.受注タイプID
/* 2009/08/11 Ver1.7 Mod Start */
--     AND   ottt.language               =  USERENV('LANG')          -- 受注タイプ.言語＝日本語
     AND   ottt.language               =  lv_language            -- 受注タイプ.言語＝日本語
/* 2009/08/11 Ver1.7 Mod End   */
     AND   EXISTS (
                   SELECT 'X'
/* 2009/08/11 Ver1.7 Mod Start */
--                   FROM (
--                          SELECT
--                            flv.attribute1 AS order_source_name  -- 受注ソース
--                           ,flv.attribute2 AS order_h_type_name  -- 受注ヘッダタイプ
--                          FROM
--                             fnd_application               fa,
--                             fnd_lookup_types              flt,
--                             fnd_lookup_values             flv
--                           WHERE
--                               fa.application_id           = flt.application_id
--                           AND flt.lookup_type             = flv.lookup_type
--                           AND fa.application_short_name   = cv_xxcos_appl_short_nm
--                           AND flv.lookup_type             = cv_xxcos1_order_edi_common
--                           AND flv.start_date_active      <= TRUNC( ld_sysdate )
--                           AND TRUNC( ld_sysdate )        <= NVL( flv.end_date_active, TRUNC( ld_sysdate ) )
--                           AND flv.enabled_flag            = cv_flag_yes
--                           AND flv.language                = USERENV( 'LANG' )
--                        ) flvs
--                      WHERE
--                          oos.name       = flvs.order_source_name  -- 受注ソース．名前＝参照タイプ．受注ソース名
--                      AND ottt.name      = flvs.order_h_type_name  -- 受注タイプ．名前＝参照タイプ．受注ヘッダタイプ名
                   FROM   fnd_lookup_values  flv
                   WHERE  flv.lookup_type   = cv_xxcos1_order_edi_common
                   AND    ld_sysdate        BETWEEN NVL( flv.start_date_active, ld_sysdate )
                                            AND     NVL( flv.end_date_active, ld_sysdate )
                   AND    flv.enabled_flag  = cv_flag_yes
                   AND    flv.language      = lv_language
                   AND    flv.attribute1    = oos.name
                   AND    flv.attribute2    = ottt.name
/* 2009/08/11 Ver1.7 Mod End   */
                  )
--*** 2009/03/24 Ver1.3 MODIFY END   ***/
     /* 通過型在庫区分 */
     AND   xca1.tsukagatazaiko_div     IN ( cv_tukzik_div_tuk    -- センター納品(通過型・受注)
                                          , cv_tukzik_div_zik    -- センター納品(在庫型・受注)
                                          , cv_tukzik_div_tnp )  -- 店舗納品
     /* パラメータによる絞り込み */
/* 2009/08/11 Ver1.7 Mod Start */
--     AND ( xca2.chain_store_code       =  iv_edi_chain_code                  -- EDIチェーン店コード
--     OR    iv_edi_chain_code           IS NULL )
     AND   xca2.edi_chain_code         =  iv_edi_chain_code                  -- EDIチェーン店コード
/* 2009/08/11 Ver1.7 Mod End   */
     AND ( xca1.edi_forward_number     =  iv_edi_forward_number              -- EDI伝送追番
     OR    iv_edi_forward_number       IS NULL )
/* 2009/08/11 Ver1.7 Mod Start */
--     AND ( TRUNC(ooha.request_date)    >= TRUNC(id_shop_delivery_date_from)  -- 店舗納品日(From)
--     OR    id_shop_delivery_date_from  IS NULL )
--     AND ( TRUNC(ooha.request_date)    <= TRUNC(id_shop_delivery_date_to)    -- 店舗納品日(To)
--     OR    id_shop_delivery_date_to    IS NULL )
--     AND ( xca1.edi_district_code      =  iv_area_code                       -- 地区コード
--     OR    iv_area_code                IS NULL )
--     AND ( TRUNC(ooha.request_date)    =  TRUNC(id_center_delivery_date)     -- センター納品日
--     OR    id_center_delivery_date     IS NULL )
     AND (
           TRUNC(ooha.request_date)    >= ld_shop_delivery_date_from  -- 店舗納品日(From)
         OR
           ld_shop_delivery_date_from  IS NULL
         )
     AND (
           TRUNC(ooha.request_date)    <= ld_shop_delivery_date_to    -- 店舗納品日(To)
         OR
           ld_shop_delivery_date_to    IS NULL
         )
     AND (
           xca1.edi_district_code      =  iv_area_code                -- 地区コード
         OR
           iv_area_code                IS NULL
         )
     AND (
           TRUNC(ooha.request_date)    =  ld_center_delivery_date     -- センター納品日
         OR
           ld_center_delivery_date     IS NULL
         )
/* 2009/08/11 Ver1.7 Mod End   */
    ;
--
    -- 該当データなし
    IF ( lt_head_tab.COUNT = 0 ) THEN
      RETURN;
    END IF;
--
    -- 伝票計
    ln_invoice_cnt := 1;
    lt_invoice_tab(ln_invoice_cnt).invoice_number := lt_head_tab(1).cust_po_number;
--
    <<head_proc_loop>>
    FOR ln_head_cnt IN 1 .. lt_head_tab.COUNT LOOP
      -- ヘッダ編集テーブル初期化
      lt_head_edit_tab(ln_head_cnt).edi_header_info_id := NULL;
--
      -- 取り込み済み？
      IF ( lt_head_tab(ln_head_cnt).acquisition_flag IS NULL ) THEN
        lt_line_tab.DELETE;  -- 明細テーブルクリア
--
        -- 明細情報読込
        SELECT
          oola.line_number            line_number         -- 受注明細.行番号
         ,oola.ordered_item           ordered_item        -- 受注明細.受注品目
         ,oola.order_quantity_uom     order_quantity_uom  -- 受注明細.受注単位
         ,oola.ordered_quantity       ordered_quantity    -- 受注明細.受注数量
         ,oola.orig_sys_line_ref      orig_sys_line_refw  -- 受注明細.外部システム受注明細番号
         ,oola.unit_selling_price     unit_selling_price  -- 販売単価
/* 2010/03/09 Ver1.8 Add Start */
         ,TO_NUMBER(oola.attribute10) selling_price       -- 売単価
         ,TO_NUMBER(oola.attribute10)
          * oola.ordered_quantity     order_price_amt     -- 売価金額(発注)
/* 2010/03/09 Ver1.8 Add  End  */
         ,iimb.attribute11            num_of_case         -- OPM品目.DFF11(ケース入数)
         ,iimb.attribute21            jan_code            -- OPM品目.DFF21(JANコード)
         ,iimb.attribute22            itf_code            -- OPM品目.DFF22(ITFコード)
         ,msib.segment1               item_code           -- Disc品目.品名コード
         ,xsib.bowl_inc_num           num_of_bowl         -- Disc品目アドオン.ボール入数
         ,flv.attribute8              regular_sale_class  -- クイックコード.DFF8(定番特売区分)
         ,flv.attribute10             outbound_flag       -- クイックコード.DFF10(OUTBOUND可否)
/* 2009/03/03 Ver1.1 Add Start */
         ,ximb.item_name              item_name           -- OPM品目アドオン.正式名
         ,ximb.item_name_alt          item_name_alt       -- OPM品目アドオン.カナ名
/* 2009/03/03 Ver1.1 Add  End  */
/* 2009/04/24 Ver1.3 Add Start */
         ,muom.attribute1             edi_rep_uom         -- EDI・帳票用単位
/* 2009/04/24 Ver1.3 Add End   */
        BULK COLLECT INTO lt_line_tab
        FROM oe_order_lines_all    oola  -- 受注明細
            ,ic_item_mst_b         iimb  -- OPM品目マスタ
            ,xxcmn_item_mst_b      ximb  -- OPM品目アドオン
            ,mtl_system_items_b    msib  -- Disc品目
            ,xxcmm_system_items_b  xsib  -- Disc品目アドオン
            ,fnd_lookup_values     flv   -- クイックコード
--*** 2009/03/24 Ver1.3 ADD    START ***/
            ,oe_transaction_types_tl ottt  -- 受注タイプテーブル
--*** 2009/03/24 Ver1.3 ADD    END   ***/
/* 2009/04/24 Ver1.3 Add Start */
            ,mtl_units_of_measure_tl muom  -- 単位マスタ
/* 2009/04/24 Ver1.3 Add End   */
        WHERE oola.header_id            = lt_head_tab(ln_head_cnt).header_id
        AND   oola.ordered_item         = iimb.item_no
        AND   iimb.item_id              = ximb.item_id
        AND   ximb.start_date_active   <= ld_sysdate
        AND   ximb.end_date_active     >= ld_sysdate
        AND   oola.ordered_item         = msib.segment1
        AND   msib.organization_id      = in_organization_id
        AND   msib.segment1             = xsib.item_code
        AND   oola.attribute5           = flv.lookup_code(+)
        AND   flv.lookup_type(+)        = cv_ltype_sale_class
        AND   flv.start_date_active(+) <= ld_sysdate
        AND ( flv.end_date_active      >= ld_sysdate
        OR    flv.end_date_active      IS NULL )
        AND   flv.enabled_flag(+)       = cv_flag_yes
        AND   flv.language(+)           = lv_language
--*** 2009/03/24 Ver1.3 MODIFY START ***
--      AND   oola.line_type_ID         = cn_line_type
        AND   oola.line_type_id         = ottt.transaction_type_id -- 受注ヘッダ.受注タイプID＝受注タイプ.受注タイプID
/* 2009/08/11 Ver1.7 Mod Start */
--        AND   ottt.language             = USERENV('LANG')          -- 受注タイプ.言語＝日本語
        AND   ottt.language             = lv_language              -- 受注タイプ.言語＝日本語
/* 2009/08/11 Ver1.7 Mod End   */
        AND   EXISTS (
                      SELECT 'X'
/* 2009/08/11 Ver1.7 Mod Start */
--                      FROM (
--                             SELECT
--                               flv.attribute3 AS order_l_type_name -- 受注明細タイプ
--                             FROM
--                                fnd_application               fa,
--                                fnd_lookup_types              flt,
--                                fnd_lookup_values             flv
--                              WHERE
--                                  fa.application_id           = flt.application_id
--                              AND flt.lookup_type             = flv.lookup_type
--                              AND fa.application_short_name   = cv_xxcos_appl_short_nm
--                              AND flv.lookup_type             = cv_xxcos1_order_edi_common
--                              AND flv.start_date_active      <= TRUNC( ld_sysdate )
--                              AND TRUNC( ld_sysdate )        <= NVL( flv.end_date_active, TRUNC( ld_sysdate ) )
--                              AND flv.enabled_flag            = cv_flag_yes
--                              AND flv.language                = USERENV( 'LANG' )
--                           ) flvs
--                         WHERE
--                             ottt.name      = flvs.order_l_type_name  -- 受注タイプ．名前＝参照タイプ．受注明細タイプ名
                      FROM   fnd_lookup_values  flv
                      WHERE  flv.lookup_type   = cv_xxcos1_order_edi_common
                      AND    ld_sysdate        BETWEEN NVL( flv.start_date_active, ld_sysdate )
                                               AND     NVL( flv.end_date_active, ld_sysdate )
                      AND    flv.enabled_flag  = cv_flag_yes
                      AND    flv.language      = lv_language
                      AND    flv.attribute3    = ottt.name
/* 2009/08/11 Ver1.7 Mod End   */
                     )
--*** 2009/03/24 Ver1.3 MODIFY END   ***
/* 2009/04/24 Ver1.3 Add Start */
        AND   oola.order_quantity_uom   = muom.uom_code            -- 受注明細.受注単位＝単位マスタ.単位コード
/* 2009/08/11 Ver1.7 Mod Start */
--        AND   muom.language             = USERENV('LANG')          -- 単位マスタ.言語＝日本語
        AND   muom.language             = lv_language          -- 単位マスタ.言語＝日本語
/* 2009/08/11 Ver1.7 Mod End   */
/* 2009/04/24 Ver1.3 Add End   */
        ;
--
        -- 該当明細あり？
        IF ( lt_line_tab.COUNT <> 0 ) THEN
          -- 受注明細情報チェック
          <<line_check_loop>>
          FOR ln_line_cnt IN 1 .. lt_line_tab.COUNT LOOP
            -- 定番売上区分が(1)と(n)で異なる場合、エラー
            IF ( lt_line_tab(1).regular_sale_class <> lt_line_tab(ln_line_cnt).regular_sale_class ) THEN
/* 2009/07/13 Ver1.5 Add Start */
              lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application     => cv_xxcos_appl_short_nm
                              ,iv_name            => cv_msg_sales_class
                              ,iv_token_name1     => cv_tkn_order_no
                              ,iv_token_value1    => lt_head_tab(ln_head_cnt).cust_po_number
                              );
/* 2009/07/13 Ver1.5 Add End   */
              RAISE sale_class_expt;
            END IF;
            -- OUTBOUD可否が'N'の場合、エラー
            IF ( lt_line_tab(ln_line_cnt).outbound_flag = cv_flag_no ) THEN
/* 2009/07/13 Ver1.5 Add Start */
              lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application     => cv_xxcos_appl_short_nm
                              ,iv_name            => cv_msg_not_outbound
                              ,iv_token_name1     => cv_tkn_order_no
                              ,iv_token_value1    => lt_head_tab(ln_head_cnt).cust_po_number
                              ,iv_token_name2     => cv_tkn_line_no
                              ,iv_token_value2    => TO_CHAR( lt_line_tab(ln_line_cnt).line_number )
                              );
/* 2009/07/13 Ver1.5 Add End   */
              RAISE outbound_expt;
            END IF;
          END LOOP line_check_loop;
--
          -- パラメータ.定番特売区分＝未設定 or ALL
          IF ( iv_regular_ar_sale_class IS NULL )
          OR ( iv_regular_ar_sale_class = cv_ras_class_all )
          THEN
            lv_sale_class_check := cv_flag_yes;      -- 対象
          ELSE
            -- パラメータ.定番特売区分＝受注明細.定番特売区分
            IF ( iv_regular_ar_sale_class = lt_line_tab(1).regular_sale_class ) THEN
              lv_sale_class_check := cv_flag_yes;    -- 対象
            ELSE
              lv_sale_class_check := cv_flag_no;     -- 対象外
            END IF;
          END IF;
--
          -- 売上区分対象？
          IF ( lv_sale_class_check = cv_flag_yes ) THEN
            <<line_insert_loop>>
            FOR ln_line_cnt IN 1 .. lt_line_tab.COUNT LOOP
              -- 伝票計
              IF ( lt_invoice_tab(ln_invoice_cnt).invoice_number <> lt_head_tab(ln_head_cnt).cust_po_number ) THEN
                ln_invoice_cnt := ln_invoice_cnt + 1;
                lt_invoice_tab(ln_invoice_cnt).invoice_number := lt_head_tab(ln_head_cnt).cust_po_number;
              END IF;
--
              ln_case_qty := 0;  -- ケース数
              ln_bowl_qty := 0;  -- ボール数
              ln_indv_qty := 0;  -- バラ数
--
              CASE lt_line_tab(ln_line_cnt).order_quantity_uom
                WHEN cv_unit_case THEN  -- ケース
                  ln_case_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 出荷数量(ケース)
                  lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 出荷数量(合計、バラ)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity
                     * TO_NUMBER( lt_line_tab(ln_line_cnt).num_of_case );
                WHEN cv_unit_bowl THEN  -- ボール
                  ln_bowl_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 出荷数量(ボール)
                  lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 出荷数量(合計、バラ)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity
                     * lt_line_tab(ln_line_cnt).num_of_bowl;
                ELSE                    -- バラ
                  ln_indv_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 出荷数量(バラ)
                  lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 出荷数量(合計、バラ)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
              END CASE;
--
              IF ( lt_head_edit_tab(ln_head_cnt).edi_header_info_id IS NULL ) THEN
                -- ヘッダID採番
                SELECT xxcos.xxcos_edi_headers_s01.NEXTVAL
                INTO   lt_head_edit_tab(ln_head_cnt).edi_header_info_id
                FROM   dual;
                -- 特売区分
                lt_head_edit_tab(ln_head_cnt).ar_sale_class := lt_line_tab(1).regular_sale_class;
              END IF;
--
              -- 明細ID採番
              SELECT xxcos.xxcos_edi_lines_s01.NEXTVAL
              INTO   ln_line_info_id
              FROM   dual;
--
              -- 品目変換(EBS→EDI)
              xxcos_common2_pkg.conv_edi_item_code(
                   lt_head_tab(ln_head_cnt).edi_chain_code      -- EDIチェーン店コード
                 , lt_line_tab(ln_line_cnt).ordered_item        -- 品目コード
                 , in_organization_id                           -- 在庫組織ID
                 , lt_line_tab(ln_line_cnt).order_quantity_uom  -- 単位コード
                 , lv_product_code2                             -- 商品コード２
                 , lv_jan_code                                  -- JANコード
                 , lv_case_jan_code                             -- ケースJANコード
/* 2010/07/13 Ver1.10 Add Start */
                 , lv_err_flag                                  -- エラー種別(1:未登録、2:複数件登録、3:両方)
/* 2010/07/13 Ver1.10 Add End */
                 , lv_errbuf                                    -- エラー・メッセージエラー
                 , lv_retcode                                   -- リターン・コード
                 , lv_errmsg                                    -- ユーザー・エラー・メッセージ
              );
/* 2010/07/13 Ver1.10 Mod Start */
--              -- リターンコードが正常でない場合
--              IF ( lv_retcode <> lv_ret_normal ) THEN
--                ov_errbuf  := cv_prg_name || lv_errbuf;
--                ov_errmsg  := lv_errmsg;
--                RAISE item_conv_expt;
--              END IF;
              -- リターンコードが警告の場合
              IF ( lv_retcode = lv_ret_warn ) THEN
                --コンカレント起動の場合
                IF ( iv_boot_flag = cv_boot_flag_conc ) THEN
/* 2012/08/24 Ver1.11 Add Start */
                  -- エラーメッセージの末尾に該当の伝票番号を表示する
                  lv_errbuf := REPLACE(lv_errbuf
                                     , cv_message_end
                                     , cv_invoice_number || lt_head_tab(ln_head_cnt).cust_po_number || cv_message_end);
                  lv_errmsg := REPLACE(lv_errmsg
                                     , cv_message_end
                                     , cv_invoice_number || lt_head_tab(ln_head_cnt).cust_po_number || cv_message_end);
/* 2012/08/24 Ver1.11 Add End */
                  -- 共通関数からのメッセージをログと出力に出力する
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.OUTPUT
                    ,buff   => lv_errmsg
                  );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.LOG
                    ,buff   => lv_errmsg
                  );
                END IF;
                -- 警告フラグにYESをセット
                lv_warn_flag := cv_flag_yes;
                -- エラー種別の制御
                IF ( lv_err_flag_tmp = cv_flag_0 ) THEN
                  lv_err_flag_tmp := lv_err_flag;
                  ov_err_flag     := lv_err_flag;
                ELSIF ( lv_err_flag_tmp <> cv_flag_0 ) AND ( lv_err_flag_tmp <> lv_err_flag ) THEN
                  lv_err_flag := cv_flag_3;
                  ov_err_flag := cv_flag_3;
                END IF;
              END IF;
              -- リターンコードがエラーの場合
              IF ( lv_retcode = lv_ret_error ) THEN
                ov_errbuf    := cv_prg_name || lv_errbuf;
                ov_errmsg    := lv_errmsg;
                RAISE item_conv_expt;
              END IF;
/* 2010/07/13 Ver1.10 Mod End */
/* 2010/07/13 Ver1.10 Add Start */
              -- 警告フラグがYES以外の場合
              IF (  lv_warn_flag <> cv_flag_yes ) THEN
/* 2010/07/13 Ver1.10 Add End */
              -- EDI明細情報テーブル挿入
              BEGIN
                INSERT INTO xxcos_edi_lines
                (
                  edi_line_info_id              -- EDI明細情報ID
                 ,edi_header_info_id            -- EDIヘッダ情報ID
                 ,line_no                       -- 行Ｎｏ
                 ,stockout_class                -- 欠品区分
                 ,stockout_reason               -- 欠品理由
                 ,product_code_itouen           -- 商品コード(伊藤園)
                 ,product_code1                 -- 商品コード１
                 ,product_code2                 -- 商品コード２
                 ,jan_code                      -- ＪＡＮコード
                 ,itf_code                      -- ＩＴＦコード
                 ,extension_itf_code            -- 内箱ＩＴＦコード
                 ,case_product_code             -- ケース商品コード
                 ,ball_product_code             -- ボール商品コード
                 ,product_code_item_type        -- 商品コード品種
                 ,prod_class                    -- 商品区分
                 ,product_name                  -- 商品名(漢字)
                 ,product_name1_alt             -- 商品名１(カナ)
                 ,product_name2_alt             -- 商品名２(カナ)
                 ,item_standard1                -- 規格１
                 ,item_standard2                -- 規格２
                 ,qty_in_case                   -- 入数
                 ,num_of_cases                  -- ケース入数
                 ,num_of_ball                   -- ボール入数
                 ,item_color                    -- 色
                 ,item_size                     -- サイズ
                 ,expiration_date               -- 賞味期限日
                 ,product_date                  -- 製造日
                 ,order_uom_qty                 -- 発注単位数
                 ,shipping_uom_qty              -- 出荷単位数
                 ,packing_uom_qty               -- 梱包単位数
                 ,deal_code                     -- 引合
                 ,deal_class                    -- 引合区分
                 ,collation_code                -- 照合
                 ,uom_code                      -- 単位
                 ,unit_price_class              -- 単価区分
                 ,parent_packing_number         -- 親梱包番号
                 ,packing_number                -- 梱包番号
                 ,product_group_code            -- 商品群コード
                 ,case_dismantle_flag           -- ケース解体不可フラグ
                 ,case_class                    -- ケース区分
                 ,indv_order_qty                -- 発注数量(バラ)
                 ,case_order_qty                -- 発注数量(ケース)
                 ,ball_order_qty                -- 発注数量(ボール)
                 ,sum_order_qty                 -- 発注数量(合計、バラ)
                 ,indv_shipping_qty             -- 出荷数量(バラ)
                 ,case_shipping_qty             -- 出荷数量(ケース)
                 ,ball_shipping_qty             -- 出荷数量(ボール)
                 ,pallet_shipping_qty           -- 出荷数量(パレット)
                 ,sum_shipping_qty              -- 出荷数量(合計、バラ)
                 ,indv_stockout_qty             -- 欠品数量(バラ)
                 ,case_stockout_qty             -- 欠品数量(ケース)
                 ,ball_stockout_qty             -- 欠品数量(ボール)
                 ,sum_stockout_qty              -- 欠品数量(合計、バラ)
                 ,case_qty                      -- ケース個口数
                 ,fold_container_indv_qty       -- オリコン(バラ)個口数
                 ,order_unit_price              -- 原単価(発注)
                 ,shipping_unit_price           -- 原単価(出荷)
                 ,order_cost_amt                -- 原価金額(発注)
                 ,shipping_cost_amt             -- 原価金額(出荷)
                 ,stockout_cost_amt             -- 原価金額(欠品)
                 ,selling_price                 -- 売単価
                 ,order_price_amt               -- 売価金額(発注)
                 ,shipping_price_amt            -- 売価金額(出荷)
                 ,stockout_price_amt            -- 売価金額(欠品)
                 ,a_column_department           -- Ａ欄(百貨店)
                 ,d_column_department           -- Ｄ欄(百貨店)
                 ,standard_info_depth           -- 規格情報・奥行き
                 ,standard_info_height          -- 規格情報・高さ
                 ,standard_info_width           -- 規格情報・幅
                 ,standard_info_weight          -- 規格情報・重量
                 ,general_succeeded_item1       -- 汎用引継ぎ項目１
                 ,general_succeeded_item2       -- 汎用引継ぎ項目２
                 ,general_succeeded_item3       -- 汎用引継ぎ項目３
                 ,general_succeeded_item4       -- 汎用引継ぎ項目４
                 ,general_succeeded_item5       -- 汎用引継ぎ項目５
                 ,general_succeeded_item6       -- 汎用引継ぎ項目６
                 ,general_succeeded_item7       -- 汎用引継ぎ項目７
                 ,general_succeeded_item8       -- 汎用引継ぎ項目８
                 ,general_succeeded_item9       -- 汎用引継ぎ項目９
                 ,general_succeeded_item10      -- 汎用引継ぎ項目１０
                 ,general_add_item1             -- 汎用付加項目１
                 ,general_add_item2             -- 汎用付加項目２
                 ,general_add_item3             -- 汎用付加項目３
                 ,general_add_item4             -- 汎用付加項目４
                 ,general_add_item5             -- 汎用付加項目５
                 ,general_add_item6             -- 汎用付加項目６
                 ,general_add_item7             -- 汎用付加項目７
                 ,general_add_item8             -- 汎用付加項目８
                 ,general_add_item9             -- 汎用付加項目９
                 ,general_add_item10            -- 汎用付加項目１０
                 ,chain_peculiar_area_line      -- チェーン店固有エリア(明細)
                 ,item_code                     -- 品目コード
                 ,line_uom                      -- 明細単位
                 ,hht_delivery_schedule_flag    -- HHT納品予定連携済フラグ
                 ,order_connection_line_number  -- 受注関連明細番号
                 ,created_by                    -- 作成者
                 ,creation_date                 -- 作成日
                 ,last_updated_by               -- 最終更新者
                 ,last_update_date              -- 最終更新日
                 ,last_update_login             -- 最終更新ログイン
                 ,request_id                    -- 要求ID
                 ,program_application_id        -- コンカレント・プログラム・アプリケーションID
                 ,program_id                    -- コンカレント・プログラムID
                 ,program_update_date           -- プログラム更新日
                ) VALUES (
                  ln_line_info_id                                  -- EDI明細情報ID
                 ,lt_head_edit_tab(ln_head_cnt).edi_header_info_id -- EDIヘッダ情報ID
                 ,lt_line_tab(ln_line_cnt).line_number             -- 行Ｎｏ
                 ,cv_stockout_class                                -- 欠品区分
                 ,NULL                                             -- 欠品理由
                 ,lt_line_tab(ln_line_cnt).ordered_item            -- 商品コード(伊藤園)
                 ,NULL                                             -- 商品コード１
                 ,lv_product_code2                                 -- 商品コード２
                 ,lt_line_tab(ln_line_cnt).jan_code                -- ＪＡＮコード
                 ,lt_line_tab(ln_line_cnt).itf_code                -- ＩＴＦコード
                 ,NULL                                             -- 内箱ＩＴＦコード
                 ,NULL                                             -- ケース商品コード
                 ,NULL                                             -- ボール商品コード
                 ,NULL                                             -- 商品コード品種
                 ,NULL                                             -- 商品区分
/* 2009/03/03 Ver1.1 Mod Start */
--               ,NULL                                             -- 商品名(漢字)
                 ,SUBSTRB(lt_line_tab(ln_line_cnt).item_name, 1, 60)     -- 商品名(漢字)
                 ,NULL                                             -- 商品名１(カナ)
--               ,NULL                                             -- 商品名２(カナ)
                 ,SUBSTRB(lt_line_tab(ln_line_cnt).item_name_alt, 1, 15) -- 商品名２(カナ)
/* 2009/03/03 Ver1.1 Mod  End  */
                 ,NULL                                             -- 規格１
                 ,NULL                                             -- 規格２
                 ,NULL                                             -- 入数
                 ,lt_line_tab(ln_line_cnt).num_of_case             -- ケース入数
                 ,lt_line_tab(ln_line_cnt).num_of_bowl             -- ボール入数
                 ,NULL                                             -- 色
                 ,NULL                                             -- サイズ
                 ,NULL                                             -- 賞味期限日
                 ,NULL                                             -- 製造日
                 ,NULL                                             -- 発注単位数
                 ,NULL                                             -- 出荷単位数
                 ,NULL                                             -- 梱包単位数
                 ,NULL                                             -- 引合
                 ,NULL                                             -- 引合区分
                 ,NULL                                             -- 照合
/* 2009/04/24 Ver1.3 Mod Start */
--                 ,lt_line_tab(ln_line_cnt).order_quantity_uom      -- 単位
                 ,lt_line_tab(ln_line_cnt).edi_rep_uom             -- 単位
/* 2009/04/24 Ver1.3 Mod End   */
                 ,NULL                                             -- 単価区分
                 ,NULL                                             -- 親梱包番号
                 ,NULL                                             -- 梱包番号
                 ,NULL                                             -- 商品群コード
                 ,NULL                                             -- ケース解体不可フラグ
                 ,NULL                                             -- ケース区分
                 ,ln_indv_qty                                      -- 発注数量(バラ)
                 ,ln_case_qty                                      -- 発注数量(ケース)
                 ,ln_bowl_qty                                      -- 発注数量(ボール)
                 ,lt_line_tab(ln_line_cnt).ordered_quantity        -- 発注数量(合計、バラ)
                 ,ln_indv_qty                                      -- 出荷数量(バラ)
                 ,ln_case_qty                                      -- 出荷数量(ケース)
                 ,ln_bowl_qty                                      -- 出荷数量(ボール)
                 ,NULL                                             -- 出荷数量(パレット)
                 ,lt_line_tab(ln_line_cnt).ordered_quantity        -- 出荷数量(合計、バラ)
                 ,0                                                -- 欠品数量(バラ)
                 ,0                                                -- 欠品数量(ケース)
                 ,0                                                -- 欠品数量(ボール)
                 ,0                                                -- 欠品数量(合計、バラ)
                 ,NULL                                             -- ケース個口数
                 ,NULL                                             -- オリコン(バラ)個口数
                 ,lt_line_tab(ln_line_cnt).unit_selling_price      -- 原単価(発注)
                 ,lt_line_tab(ln_line_cnt).unit_selling_price      -- 原単価(出荷)
                 ,NULL                                             -- 原価金額(発注)
                 ,NULL                                             -- 原価金額(出荷)
                 ,NULL                                             -- 原価金額(欠品)
/* 2010/03/09 Ver1.8 Mod Start */
--                 ,NULL                                             -- 売単価
--                 ,NULL                                             -- 売価金額(発注)
                 ,lt_line_tab(ln_line_cnt).selling_price           -- 売単価
                 ,lt_line_tab(ln_line_cnt).order_price_amt         -- 売価金額(発注)
/* 2010/03/09 Ver1.8 Mod  End  */
                 ,NULL                                             -- 売価金額(出荷)
                 ,NULL                                             -- 売価金額(欠品)
                 ,NULL                                             -- Ａ欄(百貨店)
                 ,NULL                                             -- Ｄ欄(百貨店)
                 ,NULL                                             -- 規格情報・奥行き
                 ,NULL                                             -- 規格情報・高さ
                 ,NULL                                             -- 規格情報・幅
                 ,NULL                                             -- 規格情報・重量
                 ,NULL                                             -- 汎用引継ぎ項目１
                 ,NULL                                             -- 汎用引継ぎ項目２
                 ,NULL                                             -- 汎用引継ぎ項目３
                 ,NULL                                             -- 汎用引継ぎ項目４
                 ,NULL                                             -- 汎用引継ぎ項目５
                 ,NULL                                             -- 汎用引継ぎ項目６
                 ,NULL                                             -- 汎用引継ぎ項目７
                 ,NULL                                             -- 汎用引継ぎ項目８
                 ,NULL                                             -- 汎用引継ぎ項目９
                 ,NULL                                             -- 汎用引継ぎ項目１０
                 ,NULL                                             -- 汎用付加項目１
                 ,NULL                                             -- 汎用付加項目２
                 ,NULL                                             -- 汎用付加項目３
                 ,NULL                                             -- 汎用付加項目４
                 ,NULL                                             -- 汎用付加項目５
                 ,NULL                                             -- 汎用付加項目６
                 ,NULL                                             -- 汎用付加項目７
                 ,NULL                                             -- 汎用付加項目８
                 ,NULL                                             -- 汎用付加項目９
                 ,NULL                                             -- 汎用付加項目１０
                 ,NULL                                             -- チェーン店固有エリア(明細)
                 ,lt_line_tab(ln_line_cnt).ordered_item            -- 品目コード
                 ,lt_line_tab(ln_line_cnt).order_quantity_uom      -- 明細単位
                 ,cv_flag_no                                       -- HHT納品予定連携済フラグ
                 ,lt_line_tab(ln_line_cnt).orig_sys_line_refw      -- 受注関連明細番号
                 ,ln_user_id                                       -- 作成者
                 ,SYSDATE                                          -- 作成日
                 ,ln_user_id                                       -- 最終更新者
                 ,SYSDATE                                          -- 最終更新日
                 ,ln_login_id                                      -- 最終更新ログイン
                 ,NULL                                             -- 要求ID
                 ,NULL                                             -- コンカレント・プログラム・アプリケーションID
                 ,NULL                                             -- コンカレント・プログラムID
                 ,NULL                                             -- プログラム更新日
                );
              EXCEPTION
                WHEN OTHERS THEN
                  lv_table_name := cv_tbl_name_line;
                  RAISE table_insert_expt;
              END;
--
/* 2010/07/13 Ver1.10 Add Start */
              END IF;   -- 警告フラグがYES以外の場合？
/* 2010/07/13 Ver1.10 Add End */
            END LOOP line_insert_loop;
          END IF;      -- 売上区分対象？
        END IF;        -- 該当明細あり？
      END IF;          -- 取り込み済み？
    END LOOP head_proc_loop;
--
/* 2010/07/13 Ver1.10 Add Start */
    --警告フラグが'Yの場合は処理終了
    IF ( lv_warn_flag = cv_flag_yes ) THEN
      --コンカレント起動の場合
      IF ( iv_boot_flag = cv_boot_flag_conc ) THEN
        -- エラーメッセージを設定
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_nm
                     ,iv_name         => cv_msg_cust_item_err
                   );
      END IF;
      RAISE conv_err_expt;
    END IF;
/* 2010/07/13 Ver1.10 Add End */
--
    ln_invoice_cnt := 1;
    <<head_insert_loop>>
    FOR ln_head_cnt IN 1 .. lt_head_tab.COUNT LOOP
      -- ヘッダ処理対象？
      IF ( lt_head_edit_tab(ln_head_cnt).edi_header_info_id IS NOT NULL ) THEN
        -- 伝票計
        IF ( lt_invoice_tab(ln_invoice_cnt).invoice_number <> lt_head_tab(ln_head_cnt).cust_po_number ) THEN
          ln_invoice_cnt := ln_invoice_cnt + 1;
        END IF;
--
/* 2010/07/13 Ver1.10 Add Start */
        -- 警告フラグがYES以外の場合
        IF (  lv_warn_flag <> cv_flag_yes ) THEN
/* 2010/07/13 Ver1.10 Add End */
        -- EDIヘッダ情報テーブル挿入
        BEGIN
          INSERT INTO xxcos_edi_headers
          (
            edi_header_info_id            -- EDIヘッダ情報ID
           ,medium_class                  -- 媒体区分
           ,data_type_code                -- データ種コード
           ,file_no                       -- ファイルＮｏ
           ,info_class                    -- 情報区分
           ,process_date                  -- 処理日
           ,process_time                  -- 処理時刻
           ,base_code                     -- 拠点(部門)コード
           ,base_name                     -- 拠点名(正式名)
           ,base_name_alt                 -- 拠点名(カナ)
           ,edi_chain_code                -- ＥＤＩチェーン店コード
           ,edi_chain_name                -- ＥＤＩチェーン店名(漢字)
           ,edi_chain_name_alt            -- ＥＤＩチェーン店名(カナ)
           ,chain_code                    -- チェーン店コード
           ,chain_name                    -- チェーン店名(漢字)
           ,chain_name_alt                -- チェーン店名(カナ)
           ,report_code                   -- 帳票コード
           ,report_show_name              -- 帳票表示名
           ,customer_code                 -- 顧客コード
           ,customer_name                 -- 顧客名(漢字)
           ,customer_name_alt             -- 顧客名(カナ)
           ,company_code                  -- 社コード
           ,company_name                  -- 社名(漢字)
           ,company_name_alt              -- 社名(カナ)
           ,shop_code                     -- 店コード
           ,shop_name                     -- 店名(漢字)
           ,shop_name_alt                 -- 店名(カナ)
           ,delivery_center_code          -- 納入センターコード
           ,delivery_center_name          -- 納入センター名(漢字)
           ,delivery_center_name_alt      -- 納入センター名(カナ)
           ,order_date                    -- 発注日
           ,center_delivery_date          -- センター納品日
           ,result_delivery_date          -- 実納品日
           ,shop_delivery_date            -- 店舗納品日
           ,data_creation_date_edi_data   -- データ作成日(ＥＤＩデータ中)
           ,data_creation_time_edi_data   -- データ作成時刻(ＥＤＩデータ中)
           ,invoice_class                 -- 伝票区分
           ,small_classification_code     -- 小分類コード
           ,small_classification_name     -- 小分類名
           ,middle_classification_code    -- 中分類コード
           ,middle_classification_name    -- 中分類名
           ,big_classification_code       -- 大分類コード
           ,big_classification_name       -- 大分類名
           ,other_party_department_code   -- 相手先部門コード
           ,other_party_order_number      -- 相手先発注番号
           ,check_digit_class             -- チェックデジット有無区分
           ,invoice_number                -- 伝票番号
           ,check_digit                   -- チェックデジット
           ,close_date                    -- 月限
           ,order_no_ebs                  -- 受注Ｎｏ(ＥＢＳ)
           ,ar_sale_class                 -- 特売区分
           ,delivery_classe               -- 配送区分
           ,opportunity_no                -- 便Ｎｏ
           ,contact_to                    -- 連絡先
           ,route_sales                   -- ルートセールス
           ,corporate_code                -- 法人コード
           ,maker_name                    -- メーカー名
           ,area_code                     -- 地区コード
           ,area_name                     -- 地区名(漢字)
           ,area_name_alt                 -- 地区名(カナ)
           ,vendor_code                   -- 取引先コード
           ,vendor_name                   -- 取引先名(漢字)
           ,vendor_name1_alt              -- 取引先名１(カナ)
           ,vendor_name2_alt              -- 取引先名２(カナ)
           ,vendor_tel                    -- 取引先ＴＥＬ
           ,vendor_charge                 -- 取引先担当者
           ,vendor_address                -- 取引先住所(漢字)
           ,deliver_to_code_itouen        -- 届け先コード(伊藤園)
           ,deliver_to_code_chain         -- 届け先コード(チェーン店)
           ,deliver_to                    -- 届け先(漢字)
           ,deliver_to1_alt               -- 届け先１(カナ)
           ,deliver_to2_alt               -- 届け先２(カナ)
           ,deliver_to_address            -- 届け先住所(漢字)
           ,deliver_to_address_alt        -- 届け先住所(カナ)
           ,deliver_to_tel                -- 届け先ＴＥＬ
           ,balance_accounts_code         -- 帳合先コード
           ,balance_accounts_company_code -- 帳合先社コード
           ,balance_accounts_shop_code    -- 帳合先店コード
           ,balance_accounts_name         -- 帳合先名(漢字)
           ,balance_accounts_name_alt     -- 帳合先名(カナ)
           ,balance_accounts_address      -- 帳合先住所(漢字)
           ,balance_accounts_address_alt  -- 帳合先住所(カナ)
           ,balance_accounts_tel          -- 帳合先ＴＥＬ
           ,order_possible_date           -- 受注可能日
           ,permission_possible_date      -- 許容可能日
           ,forward_month                 -- 先限年月日
           ,payment_settlement_date       -- 支払決済日
           ,handbill_start_date_active    -- チラシ開始日
           ,billing_due_date              -- 請求締日
           ,shipping_time                 -- 出荷時刻
           ,delivery_schedule_time        -- 納品予定時間
           ,order_time                    -- 発注時間
           ,general_date_item1            -- 汎用日付項目１
           ,general_date_item2            -- 汎用日付項目２
           ,general_date_item3            -- 汎用日付項目３
           ,general_date_item4            -- 汎用日付項目４
           ,general_date_item5            -- 汎用日付項目５
           ,arrival_shipping_class        -- 入出荷区分
           ,vendor_class                  -- 取引先区分
           ,invoice_detailed_class        -- 伝票内訳区分
           ,unit_price_use_class          -- 単価使用区分
           ,sub_distribution_center_code  -- サブ物流センターコード
           ,sub_distribution_center_name  -- サブ物流センターコード名
           ,center_delivery_method        -- センター納品方法
           ,center_use_class              -- センター利用区分
           ,center_whse_class             -- センター倉庫区分
           ,center_area_class             -- センター地域区分
           ,center_arrival_class          -- センター入荷区分
           ,depot_class                   -- デポ区分
           ,tcdc_class                    -- ＴＣＤＣ区分
           ,upc_flag                      -- ＵＰＣフラグ
           ,simultaneously_class          -- 一斉区分
           ,business_id                   -- 業務ＩＤ
           ,whse_directly_class           -- 倉直区分
           ,premium_rebate_class          -- 景品割戻区分
           ,item_type                     -- 項目種別
           ,cloth_house_food_class        -- 衣家食区分
           ,mix_class                     -- 混在区分
           ,stk_class                     -- 在庫区分
           ,last_modify_site_class        -- 最終修正場所区分
           ,report_class                  -- 帳票区分
           ,addition_plan_class           -- 追加・計画区分
           ,registration_class            -- 登録区分
           ,specific_class                -- 特定区分
           ,dealings_class                -- 取引区分
           ,order_class                   -- 発注区分
           ,sum_line_class                -- 集計明細区分
           ,shipping_guidance_class       -- 出荷案内以外区分
           ,shipping_class                -- 出荷区分
           ,product_code_use_class        -- 商品コード使用区分
           ,cargo_item_class              -- 積送品区分
           ,ta_class                      -- Ｔ／Ａ区分
           ,plan_code                     -- 企画コード
           ,category_code                 -- カテゴリーコード
           ,category_class                -- カテゴリー区分
           ,carrier_means                 -- 運送手段
           ,counter_code                  -- 売場コード
           ,move_sign                     -- 移動サイン
           ,eos_handwriting_class         -- ＥＯＳ・手書区分
           ,delivery_to_section_code      -- 納品先課コード
           ,invoice_detailed              -- 伝票内訳
           ,attach_qty                    -- 添付数
           ,other_party_floor             -- フロア
           ,text_no                       -- ＴＥＸＴＮｏ
           ,in_store_code                 -- インストアコード
           ,tag_data                      -- タグ
           ,competition_code              -- 競合
           ,billing_chair                 -- 請求口座
           ,chain_store_code              -- チェーンストアーコード
           ,chain_store_short_name        -- チェーンストアーコード略式名称
           ,direct_delivery_rcpt_fee      -- 直配送／引取料
           ,bill_info                     -- 手形情報
           ,description                   -- 摘要
           ,interior_code                 -- 内部コード
           ,order_info_delivery_category  -- 発注情報 納品カテゴリー
           ,purchase_type                 -- 仕入形態
           ,delivery_to_name_alt          -- 納品場所名(カナ)
           ,shop_opened_site              -- 店出場所
           ,counter_name                  -- 売場名
           ,extension_number              -- 内線番号
           ,charge_name                   -- 担当者名
           ,price_tag                     -- 値札
           ,tax_type                      -- 税種
           ,consumption_tax_class         -- 消費税区分
           ,brand_class                   -- ＢＲ
           ,id_code                       -- ＩＤコード
           ,department_code               -- 百貨店コード
           ,department_name               -- 百貨店名
           ,item_type_number              -- 品別番号
           ,description_department        -- 摘要(百貨店)
           ,price_tag_method              -- 値札方法
           ,reason_column                 -- 自由欄
           ,a_column_header               -- Ａ欄ヘッダ
           ,d_column_header               -- Ｄ欄ヘッダ
           ,brand_code                    -- ブランドコード
           ,line_code                     -- ラインコード
           ,class_code                    -- クラスコード
           ,a1_column                     -- Ａ−１欄
           ,b1_column                     -- Ｂ−１欄
           ,c1_column                     -- Ｃ−１欄
           ,d1_column                     -- Ｄ−１欄
           ,e1_column                     -- Ｅ−１欄
           ,a2_column                     -- Ａ−２欄
           ,b2_column                     -- Ｂ−２欄
           ,c2_column                     -- Ｃ−２欄
           ,d2_column                     -- Ｄ−２欄
           ,e2_column                     -- Ｅ−２欄
           ,a3_column                     -- Ａ−３欄
           ,b3_column                     -- Ｂ−３欄
           ,c3_column                     -- Ｃ−３欄
           ,d3_column                     -- Ｄ−３欄
           ,e3_column                     -- Ｅ−３欄
           ,f1_column                     -- Ｆ−１欄
           ,g1_column                     -- Ｇ−１欄
           ,h1_column                     -- Ｈ−１欄
           ,i1_column                     -- Ｉ−１欄
           ,j1_column                     -- Ｊ−１欄
           ,k1_column                     -- Ｋ−１欄
           ,l1_column                     -- Ｌ−１欄
           ,f2_column                     -- Ｆ−２欄
           ,g2_column                     -- Ｇ−２欄
           ,h2_column                     -- Ｈ−２欄
           ,i2_column                     -- Ｉ−２欄
           ,j2_column                     -- Ｊ−２欄
           ,k2_column                     -- Ｋ−２欄
           ,l2_column                     -- Ｌ−２欄
           ,f3_column                     -- Ｆ−３欄
           ,g3_column                     -- Ｇ−３欄
           ,h3_column                     -- Ｈ−３欄
           ,i3_column                     -- Ｉ−３欄
           ,j3_column                     -- Ｊ−３欄
           ,k3_column                     -- Ｋ−３欄
           ,l3_column                     -- Ｌ−３欄
           ,chain_peculiar_area_header    -- チェーン店固有エリア(ヘッダー)
           ,order_connection_number       -- 受注関連番号
           ,invoice_indv_order_qty        -- (伝票計)発注数量(バラ)
           ,invoice_case_order_qty        -- (伝票計)発注数量(ケース)
           ,invoice_ball_order_qty        -- (伝票計)発注数量(ボール)
           ,invoice_sum_order_qty         -- (伝票計)発注数量(合計、バラ)
           ,invoice_indv_shipping_qty     -- (伝票計)出荷数量(バラ)
           ,invoice_case_shipping_qty     -- (伝票計)出荷数量(ケース)
           ,invoice_ball_shipping_qty     -- (伝票計)出荷数量(ボール)
           ,invoice_pallet_shipping_qty   -- (伝票計)出荷数量(パレット)
           ,invoice_sum_shipping_qty      -- (伝票計)出荷数量(合計、バラ)
           ,invoice_indv_stockout_qty     -- (伝票計)欠品数量(バラ)
           ,invoice_case_stockout_qty     -- (伝票計)欠品数量(ケース)
           ,invoice_ball_stockout_qty     -- (伝票計)欠品数量(ボール)
           ,invoice_sum_stockout_qty      -- (伝票計)欠品数量(合計、バラ)
           ,invoice_case_qty              -- (伝票計)ケース個口数
           ,invoice_fold_container_qty    -- (伝票計)オリコン(バラ)個口数
           ,invoice_order_cost_amt        -- (伝票計)原価金額(発注)
           ,invoice_shipping_cost_amt     -- (伝票計)原価金額(出荷)
           ,invoice_stockout_cost_amt     -- (伝票計)原価金額(欠品)
           ,invoice_order_price_amt       -- (伝票計)売価金額(発注)
           ,invoice_shipping_price_amt    -- (伝票計)売価金額(出荷)
           ,invoice_stockout_price_amt    -- (伝票計)売価金額(欠品)
           ,total_indv_order_qty          -- (総合計)発注数量(バラ)
           ,total_case_order_qty          -- (総合計)発注数量(ケース)
           ,total_ball_order_qty          -- (総合計)発注数量(ボール)
           ,total_sum_order_qty           -- (総合計)発注数量(合計、バラ)
           ,total_indv_shipping_qty       -- (総合計)出荷数量(バラ)
           ,total_case_shipping_qty       -- (総合計)出荷数量(ケース)
           ,total_ball_shipping_qty       -- (総合計)出荷数量(ボール)
           ,total_pallet_shipping_qty     -- (総合計)出荷数量(パレット)
           ,total_sum_shipping_qty        -- (総合計)出荷数量(合計、バラ)
           ,total_indv_stockout_qty       -- (総合計)欠品数量(バラ)
           ,total_case_stockout_qty       -- (総合計)欠品数量(ケース)
           ,total_ball_stockout_qty       -- (総合計)欠品数量(ボール)
           ,total_sum_stockout_qty        -- (総合計)欠品数量(合計、バラ)
           ,total_case_qty                -- (総合計)ケース個口数
           ,total_fold_container_qty      -- (総合計)オリコン(バラ)個口数
           ,total_order_cost_amt          -- (総合計)原価金額(発注)
           ,total_shipping_cost_amt       -- (総合計)原価金額(出荷)
           ,total_stockout_cost_amt       -- (総合計)原価金額(欠品)
           ,total_order_price_amt         -- (総合計)売価金額(発注)
           ,total_shipping_price_amt      -- (総合計)売価金額(出荷)
           ,total_stockout_price_amt      -- (総合計)売価金額(欠品)
           ,total_line_qty                -- トータル行数
           ,total_invoice_qty             -- トータル伝票枚数
           ,chain_peculiar_area_footer    -- チェーン店固有エリア(フッター)
           ,conv_customer_code            -- 変更後顧客コード
           ,order_forward_flag            -- 受注連携済フラグ
           ,creation_class                -- 作成元区分
           ,edi_delivery_schedule_flag    -- EDI納品予定送信済フラグ
           ,price_list_header_id          -- 価格表ヘッダID
           ,created_by                    -- 作成者
           ,creation_date                 -- 作成日
           ,last_updated_by               -- 最終更新者
           ,last_update_date              -- 最終更新日
           ,last_update_login             -- 最終更新ログイン
           ,request_id                    -- 要求ID
           ,program_application_id        -- コンカレント・プログラム・アプリケーションID
           ,program_id                    -- コンカレント・プログラムID
           ,program_update_date           -- プログラム更新日
           ) VALUES (
            lt_head_edit_tab(ln_head_cnt).edi_header_info_id            -- EDIヘッダ情報ID
           ,cv_medium_class                                             -- 媒体区分
           ,cv_data_type_code                                           -- データ種コード
           ,cv_file_no                                                  -- ファイルＮｏ
           ,NULL                                                        -- 情報区分
           ,NULL                                                        -- 処理日
           ,NULL                                                        -- 処理時刻
           ,lt_head_tab(ln_head_cnt).base_code                          -- 拠点(部門)コード
           ,lt_head_tab(ln_head_cnt).base_name                          -- 拠点名(正式名)
           ,lt_head_tab(ln_head_cnt).base_name_alt                      -- 拠点名(カナ)
           ,lt_head_tab(ln_head_cnt).edi_chain_code                     -- ＥＤＩチェーン店コード
           ,lt_head_tab(ln_head_cnt).edi_chain_name                     -- ＥＤＩチェーン店名(漢字)
           ,lt_head_tab(ln_head_cnt).edi_chain_name_alt                 -- ＥＤＩチェーン店名(カナ)
           ,NULL                                                        -- チェーン店コード
           ,NULL                                                        -- チェーン店名(漢字)
           ,NULL                                                        -- チェーン店名(カナ)
           ,NULL                                                        -- 帳票コード
           ,NULL                                                        -- 帳票表示名
           ,lt_head_tab(ln_head_cnt).account_number                     -- 顧客コード
           ,lt_head_tab(ln_head_cnt).customer_name                      -- 顧客名(漢字)
           ,lt_head_tab(ln_head_cnt).customer_name_alt                  -- 顧客名(カナ)
           ,NULL                                                        -- 社コード
           ,NULL                                                        -- 社名(漢字)
           ,NULL                                                        -- 社名(カナ)
           ,lt_head_tab(ln_head_cnt).store_code                         -- 店コード
           ,lt_head_tab(ln_head_cnt).cust_store_name                    -- 店名(漢字)
           ,NULL                                                        -- 店名(カナ)
           ,NULL                                                        -- 納入センターコード
           ,NULL                                                        -- 納入センター名(漢字)
           ,NULL                                                        -- 納入センター名(カナ)
           ,lt_head_tab(ln_head_cnt).ordered_date                       -- 発注日
           ,lt_head_tab(ln_head_cnt).request_date                       -- センター納品日
           ,NULL                                                        -- 実納品日
           ,lt_head_tab(ln_head_cnt).request_date                       -- 店舗納品日
           ,NULL                                                        -- データ作成日(ＥＤＩデータ中)
           ,NULL                                                        -- データ作成時刻(ＥＤＩデータ中)
/* 2009/07/14 Ver1.6 Mod Start */
--           ,NULL                                                        -- 伝票区分
           ,lt_head_tab(ln_head_cnt).invoice_class                      -- 伝票区分
/* 2009/07/14 Ver1.6 Mod End   */
           ,NULL                                                        -- 小分類コード
           ,NULL                                                        -- 小分類名
           ,NULL                                                        -- 中分類コード
           ,NULL                                                        -- 中分類名
/* 2009/07/14 Ver1.6 Mod Start */
--           ,NULL                                                        -- 大分類コード
           ,lt_head_tab(ln_head_cnt).classification_code                -- 大分類コード
/* 2009/07/14 Ver1.6 Mod End   */
           ,NULL                                                        -- 大分類名
           ,NULL                                                        -- 相手先部門コード
           ,NULL                                                        -- 相手先発注番号
           ,NULL                                                        -- チェックデジット有無区分
           ,lt_head_tab(ln_head_cnt).cust_po_number                     -- 伝票番号
           ,NULL                                                        -- チェックデジット
           ,NULL                                                        -- 月限
           ,lt_head_tab(ln_head_cnt).order_number                       -- 受注Ｎｏ(ＥＢＳ)
           ,lt_head_edit_tab(ln_head_cnt).ar_sale_class                 -- 特売区分
           ,NULL                                                        -- 配送区分
           ,NULL                                                        -- 便Ｎｏ
           ,NULL                                                        -- 連絡先
           ,NULL                                                        -- ルートセールス
           ,NULL                                                        -- 法人コード
           ,NULL                                                        -- メーカー名
           ,lt_head_tab(ln_head_cnt).edi_district_code                  -- 地区コード
           ,lt_head_tab(ln_head_cnt).edi_district_name                  -- 地区名(漢字)
           ,lt_head_tab(ln_head_cnt).edi_district_kana                  -- 地区名(カナ)
           ,NULL                                                        -- 取引先コード
           ,NULL                                                        -- 取引先名(漢字)
           ,NULL                                                        -- 取引先名１(カナ)
           ,NULL                                                        -- 取引先名２(カナ)
           ,NULL                                                        -- 取引先ＴＥＬ
           ,NULL                                                        -- 取引先担当者
           ,NULL                                                        -- 取引先住所(漢字)
           ,NULL                                                        -- 届け先コード(伊藤園)
           ,NULL                                                        -- 届け先コード(チェーン店)
           ,NULL                                                        -- 届け先(漢字)
           ,NULL                                                        -- 届け先１(カナ)
           ,NULL                                                        -- 届け先２(カナ)
           ,NULL                                                        -- 届け先住所(漢字)
           ,NULL                                                        -- 届け先住所(カナ)
           ,NULL                                                        -- 届け先ＴＥＬ
           ,NULL                                                        -- 帳合先コード
           ,NULL                                                        -- 帳合先社コード
           ,NULL                                                        -- 帳合先店コード
           ,NULL                                                        -- 帳合先名(漢字)
           ,NULL                                                        -- 帳合先名(カナ)
           ,NULL                                                        -- 帳合先住所(漢字)
           ,NULL                                                        -- 帳合先住所(カナ)
           ,NULL                                                        -- 帳合先ＴＥＬ
           ,NULL                                                        -- 受注可能日
           ,NULL                                                        -- 許容可能日
           ,NULL                                                        -- 先限年月日
           ,NULL                                                        -- 支払決済日
           ,NULL                                                        -- チラシ開始日
           ,NULL                                                        -- 請求締日
           ,NULL                                                        -- 出荷時刻
           ,NULL                                                        -- 納品予定時間
           ,NULL                                                        -- 発注時間
           ,NULL                                                        -- 汎用日付項目１
           ,NULL                                                        -- 汎用日付項目２
           ,NULL                                                        -- 汎用日付項目３
           ,NULL                                                        -- 汎用日付項目４
           ,NULL                                                        -- 汎用日付項目５
           ,NULL                                                        -- 入出荷区分
           ,NULL                                                        -- 取引先区分
           ,NULL                                                        -- 伝票内訳区分
           ,NULL                                                        -- 単価使用区分
           ,NULL                                                        -- サブ物流センターコード
           ,NULL                                                        -- サブ物流センターコード名
           ,NULL                                                        -- センター納品方法
           ,NULL                                                        -- センター利用区分
           ,NULL                                                        -- センター倉庫区分
           ,NULL                                                        -- センター地域区分
           ,NULL                                                        -- センター入荷区分
           ,NULL                                                        -- デポ区分
           ,NULL                                                        -- ＴＣＤＣ区分
           ,NULL                                                        -- ＵＰＣフラグ
           ,NULL                                                        -- 一斉区分
           ,NULL                                                        -- 業務ＩＤ
           ,NULL                                                        -- 倉直区分
           ,NULL                                                        -- 景品割戻区分
           ,NULL                                                        -- 項目種別
           ,NULL                                                        -- 衣家食区分
           ,NULL                                                        -- 混在区分
           ,NULL                                                        -- 在庫区分
           ,NULL                                                        -- 最終修正場所区分
           ,NULL                                                        -- 帳票区分
           ,NULL                                                        -- 追加・計画区分
           ,NULL                                                        -- 登録区分
           ,NULL                                                        -- 特定区分
           ,NULL                                                        -- 取引区分
           ,NULL                                                        -- 発注区分
           ,NULL                                                        -- 集計明細区分
           ,NULL                                                        -- 出荷案内以外区分
           ,NULL                                                        -- 出荷区分
           ,NULL                                                        -- 商品コード使用区分
           ,NULL                                                        -- 積送品区分
           ,NULL                                                        -- Ｔ／Ａ区分
           ,NULL                                                        -- 企画コード
           ,NULL                                                        -- カテゴリーコード
           ,NULL                                                        -- カテゴリー区分
           ,NULL                                                        -- 運送手段
           ,NULL                                                        -- 売場コード
           ,NULL                                                        -- 移動サイン
           ,NULL                                                        -- ＥＯＳ・手書区分
           ,NULL                                                        -- 納品先課コード
           ,NULL                                                        -- 伝票内訳
           ,NULL                                                        -- 添付数
           ,NULL                                                        -- フロア
           ,NULL                                                        -- ＴＥＸＴＮｏ
           ,NULL                                                        -- インストアコード
           ,NULL                                                        -- タグ
           ,NULL                                                        -- 競合
           ,NULL                                                        -- 請求口座
           ,NULL                                                        -- チェーンストアーコード
           ,NULL                                                        -- チェーンストアーコード略式名称
           ,NULL                                                        -- 直配送／引取料
           ,NULL                                                        -- 手形情報
           ,NULL                                                        -- 摘要
           ,NULL                                                        -- 内部コード
           ,NULL                                                        -- 発注情報 納品カテゴリー
           ,NULL                                                        -- 仕入形態
           ,NULL                                                        -- 納品場所名(カナ)
           ,NULL                                                        -- 店出場所
           ,NULL                                                        -- 売場名
           ,NULL                                                        -- 内線番号
           ,NULL                                                        -- 担当者名
           ,NULL                                                        -- 値札
           ,NULL                                                        -- 税種
           ,NULL                                                        -- 消費税区分
           ,NULL                                                        -- ＢＲ
           ,NULL                                                        -- ＩＤコード
           ,NULL                                                        -- 百貨店コード
           ,NULL                                                        -- 百貨店名
           ,NULL                                                        -- 品別番号
           ,NULL                                                        -- 摘要(百貨店)
           ,NULL                                                        -- 値札方法
           ,NULL                                                        -- 自由欄
           ,NULL                                                        -- Ａ欄ヘッダ
           ,NULL                                                        -- Ｄ欄ヘッダ
           ,NULL                                                        -- ブランドコード
           ,NULL                                                        -- ラインコード
           ,NULL                                                        -- クラスコード
           ,NULL                                                        -- Ａ−１欄
           ,NULL                                                        -- Ｂ−１欄
           ,NULL                                                        -- Ｃ−１欄
           ,NULL                                                        -- Ｄ−１欄
           ,NULL                                                        -- Ｅ−１欄
           ,NULL                                                        -- Ａ−２欄
           ,NULL                                                        -- Ｂ−２欄
           ,NULL                                                        -- Ｃ−２欄
           ,NULL                                                        -- Ｄ−２欄
           ,NULL                                                        -- Ｅ−２欄
           ,NULL                                                        -- Ａ−３欄
           ,NULL                                                        -- Ｂ−３欄
           ,NULL                                                        -- Ｃ−３欄
           ,NULL                                                        -- Ｄ−３欄
           ,NULL                                                        -- Ｅ−３欄
           ,NULL                                                        -- Ｆ−１欄
           ,NULL                                                        -- Ｇ−１欄
           ,NULL                                                        -- Ｈ−１欄
           ,NULL                                                        -- Ｉ−１欄
           ,NULL                                                        -- Ｊ−１欄
           ,NULL                                                        -- Ｋ−１欄
           ,NULL                                                        -- Ｌ−１欄
           ,NULL                                                        -- Ｆ−２欄
           ,NULL                                                        -- Ｇ−２欄
           ,NULL                                                        -- Ｈ−２欄
           ,NULL                                                        -- Ｉ−２欄
           ,NULL                                                        -- Ｊ−２欄
           ,NULL                                                        -- Ｋ−２欄
           ,NULL                                                        -- Ｌ−２欄
           ,NULL                                                        -- Ｆ−３欄
           ,NULL                                                        -- Ｇ−３欄
           ,NULL                                                        -- Ｈ−３欄
           ,NULL                                                        -- Ｉ−３欄
           ,NULL                                                        -- Ｊ−３欄
           ,NULL                                                        -- Ｋ−３欄
           ,NULL                                                        -- Ｌ−３欄
           ,NULL                                                        -- チェーン店固有エリア(ヘッダー)
           ,lt_head_tab(ln_head_cnt).orig_sys_document_ref              -- 受注関連番号
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_order_qty       -- (伝票計)発注数量(バラ)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_order_qty       -- (伝票計)発注数量(ケース)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_order_qty       -- (伝票計)発注数量(ボール)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_order_qty        -- (伝票計)発注数量(合計、バラ)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty    -- (伝票計)出荷数量(バラ)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty    -- (伝票計)出荷数量(ケース)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty    -- (伝票計)出荷数量(ボール)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_pallet_shipping_qty  -- (伝票計)出荷数量(パレット)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty     -- (伝票計)出荷数量(合計、バラ)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_stockout_qty    -- (伝票計)欠品数量(バラ)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_stockout_qty    -- (伝票計)欠品数量(ケース)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_stockout_qty    -- (伝票計)欠品数量(ボール)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_stockout_qty     -- (伝票計)欠品数量(合計、バラ)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_qty             -- (伝票計)ケース個口数
           ,lt_invoice_tab(ln_invoice_cnt).invoice_fold_container_qty   -- (伝票計)オリコン(バラ)個口数
           ,lt_invoice_tab(ln_invoice_cnt).invoice_order_cost_amt       -- (伝票計)原価金額(発注)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_shipping_cost_amt    -- (伝票計)原価金額(出荷)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_stockout_cost_amt    -- (伝票計)原価金額(欠品)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_order_price_amt      -- (伝票計)売価金額(発注)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_shipping_price_amt   -- (伝票計)売価金額(出荷)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_stockout_price_amt   -- (伝票計)売価金額(欠品)
           ,NULL                                                        -- (総合計)発注数量(バラ)
           ,NULL                                                        -- (総合計)発注数量(ケース)
           ,NULL                                                        -- (総合計)発注数量(ボール)
           ,NULL                                                        -- (総合計)発注数量(合計、バラ)
           ,NULL                                                        -- (総合計)出荷数量(バラ)
           ,NULL                                                        -- (総合計)出荷数量(ケース)
           ,NULL                                                        -- (総合計)出荷数量(ボール)
           ,NULL                                                        -- (総合計)出荷数量(パレット)
           ,NULL                                                        -- (総合計)出荷数量(合計、バラ)
           ,NULL                                                        -- (総合計)欠品数量(バラ)
           ,NULL                                                        -- (総合計)欠品数量(ケース)
           ,NULL                                                        -- (総合計)欠品数量(ボール)
           ,NULL                                                        -- (総合計)欠品数量(合計、バラ)
           ,NULL                                                        -- (総合計)ケース個口数
           ,NULL                                                        -- (総合計)オリコン(バラ)個口数
           ,NULL                                                        -- (総合計)原価金額(発注)
           ,NULL                                                        -- (総合計)原価金額(出荷)
           ,NULL                                                        -- (総合計)原価金額(欠品)
           ,NULL                                                        -- (総合計)売価金額(発注)
           ,NULL                                                        -- (総合計)売価金額(出荷)
           ,NULL                                                        -- (総合計)売価金額(欠品)
           ,NULL                                                        -- トータル行数
           ,NULL                                                        -- トータル伝票枚数
           ,NULL                                                        -- チェーン店固有エリア(フッター)
           ,lt_head_tab(ln_head_cnt).account_number                     -- 変更後顧客コード
           ,cv_flag_yes                                                 -- 受注連携済フラグ
           ,cv_creation_class                                           -- 作成元区分
           ,cv_flag_no                                                  -- EDI納品予定送信済フラグ
           ,lt_head_tab(ln_head_cnt).price_list_id                      -- 価格表ヘッダID
           ,ln_user_id                                                  -- 作成者
           ,SYSDATE                                                     -- 作成日
           ,ln_user_id                                                  -- 最終更新者
           ,SYSDATE                                                     -- 最終更新日
           ,ln_login_id                                                 -- 最終更新ログイン
           ,NULL                                                        -- 要求ID
           ,NULL                                                        -- コンカレント・プログラム・アプリケーションID
           ,NULL                                                        -- コンカレント・プログラムID
           ,NULL                                                        -- プログラム更新日
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_table_name := cv_tbl_name_head;
            RAISE table_insert_expt;
        END;
/* 2010/07/13 Ver1.10 Add Start */
        END IF;   -- 警告フラグがYES以外の場合？
/* 2010/07/13 Ver1.10 Add End */
      END IF;  -- ヘッダ処理対象？
    END LOOP head_insert_loop;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
/* 2009/08/11 Ver1.7 Add Start */
    -- *** ORG_ID取得例外ハンドラ ***
    WHEN org_id_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/08/11 Ver1.7 Add End   */
    -- *** 売上区分混在例外ハンドラ ***
    WHEN sale_class_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := cv_prg_name;
--      ov_errmsg  := cv_sale_class_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod End   */
--
    -- *** OUTBOUND可否例外ハンドラ ***
    WHEN outbound_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := cv_prg_name;
--      ov_errmsg  := cv_outbound_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod End   */
--
    -- *** 挿入例外ハンドラ ***
    WHEN table_insert_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := SUBSTRB(lv_table_name||SQLERRM,1,5000);
--
    -- *** 品目変換例外ハンドラ ***
    WHEN item_conv_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
--
/* 2010/07/13 Ver1.10 Add Start */
    -- *** 品目変換例外ハンドラ ***
    WHEN conv_err_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2010/07/13 Ver1.10 Add End */
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := SUBSTRB( cv_prg_name || SQLERRM, 1, 5000 );
--      ov_errmsg  := xxccp_common_pkg.get_msg(
--                       iv_application => 'XXCOS'
--                      ,iv_name        => 'APP-XXCOS-xxxxx'
--                    );
      lv_errmsg  := SUBSTRB( SQLERRM, 1, 5000);
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod Start */
--
--#####################################  固定部 END   ##########################################
--
  END edi_manual_order_acquisition;
--
END xxcos_edi_common_pkg;
/
