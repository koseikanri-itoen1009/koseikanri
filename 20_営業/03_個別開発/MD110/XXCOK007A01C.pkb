CREATE OR REPLACE PACKAGE BODY XXCOK007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK007A01C(body)
 * Description      : 売上実績振替情報作成(EDI)
 * MD.050           : 売上実績振替情報作成(EDI) MD050_COK_007_A01
 * Version          : 1.13
 *
 * Program List
 * -------------------------------- ---------------------------------------------------------
 *  Name                             Description
 * -------------------------------- ---------------------------------------------------------
 *  init                             初期処理(B-1)
 *  get_edi_wk_tab                   EDIワークテーブル抽出(B-2)
 *  chk_data                         データチェック(B-3)
 *  ins_tmp_tbl                      一時表作成(B-4)
 *  get_qty_amt_total                数量・売上金額の集計(B-5)
 *  ins_selling_trns_info            売上実績振替情報作成(B-6)
 *  upd_edi_tbl_error                EDIワークテーブル更新(エラー)(B-7)
 *  upd_edi_tbl_normal               EDIワークテーブル更新(正常)(B-8)
 *  del_wk_tbl                       EDIワークテーブル削除(B-9)
 *  get_cust_code                    顧客コードの変換(B-10)
 *  submain                          メイン処理プロシージャ
 *  main                             コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   S.Sasaki         新規作成
 *  2009/02/03    1.1   S.Sasaki         [障害COK_007]一時表レイアウト変更の対応
 *  2009/02/12    1.2   S.Sasaki         [障害COK_031]顧客受注可能フラグ、売上対象区分チェック追加
 *  2009/05/14    1.3   M.Hiruta         [障害T1_1003]文字列バッファ修正
 *  2009/05/19    1.4   M.Hiruta         [障害T1_1043]一時表作成時 売上金額・売上金額（税抜き）小数点以下切捨て
 *  2009/06/08    1.5   M.Hiruta         [障害T1_1354]EDIで取得した値のうち、マスターと突き合わせする文字列値の
 *                                                    前スペースを除去するよう修正
 *  2009/07/13    1.6   M.Hiruta         [障害0000514]処理対象に顧客ステータス「30:承認済」「50:休止」のデータを追加
 *                                                    APではなく、ARの税コードマスタを使用するよう修正
 *  2009/08/13    1.7   M.Hiruta         [障害0000997]EDIワークテーブルから納品単価と原価金額を取得する際の
 *                                                    取得箇所を修正
 *                                                    顧客名の取得元をパーティマスタへ修正
 *  2009/10/16    1.8   S.Moriyama       [E_T3_00632]伝票入力者対応により売上実績情報へ
 *                                                   売上振替元顧客コードを設定するように変更
 *  2009/10/19    1.9   K.Yamaguchi      [E_T3_00631]消費税コード取得方法を変更
 *  2009/12/05    1.10  S.Moriyama       [E_本稼動_00180]売上振替元顧客側の原価金額(発注)に対して
 *                                                       符号逆転を行うように修正（データパッチ時に緊急対応）
 *  2010/01/07    1.11  S.Moriyama       [E_本稼動_00180]価格表取得を振替元顧客で実施するように修正
 *                                       [E_本稼動_00834]価格表より納品単価を取得時に0円の場合は警告とするように修正
 *  2010/01/29    1.12  Y.Kuboshima      [E_本稼動_01297]売上拠点の取得方法を変更
 *                                                       店舗納品日が前月の場合：前月売上拠点
 *                                                       店舗納品日が当月の場合：売上拠点
 *                                                       担当営業員の処理日を「業務日付 -> 店舗納品日」に修正
 *                                                       顧客使用目的マスタの抽出条件に有効フラグを追加
 *  2010/02/18    1.13  S.Moriyama       [E_本稼動_00911]納品日先日付のEDI実績振替は一時表までの登録としスキップする
 *
 *****************************************************************************************/
  -- =========================
  -- グローバル定数
  -- =========================
  --パッケージ名
  cv_pkg_name            CONSTANT VARCHAR2(30)  := 'XXCOK007A01C';
  --アプリケーション短縮名
  cv_xxcok_appl_name     CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_name     CONSTANT VARCHAR2(10)  := 'XXCCP';
  --ステータス・コード
  cv_status_normal       CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  --正常:0
  cv_status_warn         CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    --警告:1
  cv_status_error        CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   --異常:2
  --メッセージ名称
  cv_message_00044       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00044';   --入力パラメータ(実行区分)
  cv_message_00006       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00006';   --入力パラメータ(ファイル名)
  cv_message_10072       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10072';   --パラメータチェックエラーメッセージ
  cv_message_00003       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00003';   --プロファイル値取得エラーメッセージ
  cv_message_00013       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00013';   --在庫組織ID取得エラーメッセージ
  cv_message_00028       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00028';   --業務日付取得エラーメッセージ
  cv_message_10074       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10074';   --EDI売上実績振替情報抽出エラーメッセージ
  cv_message_10373       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10373';   --必須項目：店舗納品日なし
  cv_message_10374       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10374';   --必須項目：伝票番号なし
  cv_message_10375       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10375';   --必須項目：行番号なし
  cv_message_10376       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10376';   --必須項目：EDIチェーン店コードなし
  cv_message_10377       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10377';   --必須項目：納入先センターコードなし
  cv_message_10378       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10378';   --必須項目：店コードなし
  cv_message_10379       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10379';   --必須項目：数量なし
  cv_message_10076       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10076';   --売上振替元顧客コード変換エラー
  cv_message_00045       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00045';   --売上担当設定なしエラーメッセージ
  cv_message_10095       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10095';   --価格表設定なしエラーメッセージ
  cv_message_10077       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10077';   --売上振替先顧客コード変換エラー
  cv_message_10082       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10082';   --単位設定なしエラーメッセージ
  cv_message_10085       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10085';   --納品単価設定なしエラーメッセージ
  cv_message_10086       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10086';   --営業原価設定なしエラーメッセージ
  cv_message_10013       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10013';   --消費税区分、消費税率設定なしエラーメッセージ
  cv_message_10073       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10073';   --EDI連携品目コード区分取得エラーメッセージ
  cv_message_10079       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10079';   --商品コード変換エラーメッセージ
  cv_message_10380       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10380';   --品目有効性エラーメッセージ(顧客受注可能以外)
  cv_message_10083       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10083';   --品目有効性エラーメッセージ(売上対象以外)
  cv_message_10087       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10087';   --売上実績振替情報挿入エラー
  cv_message_10088       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10088';   --EDI売上実績振替情報ロックエラーメッセージ
  cv_message_10089       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10089';   --EDI売上実績振替情報更新エラーメッセージ
  cv_message_10091       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10091';   --EDI売上実績振替情報削除エラー
  cv_message_10090       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10090';   --EDI売上実績振替情報ロックエラー(削除)
  cv_message_10414       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10414';   --EDI売上実績振替情報ロックエラー(エラー更新)
  cv_message_10415       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10415';   --EDI売上実績振替情報更新エラー(エラー更新)
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama ADD START
  cv_message_10473       CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10473';   --価格表単価0円エラーメッセージ
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama ADD END
  cv_message_90000       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90000';   --対象件数メッセージ
  cv_message_90001       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90001';   --成功件数メッセージ
  cv_message_90002       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90002';   --エラー件数メッセージ
  cv_message_90003       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90003';   --スキップ件数メッセージ
  cv_message_90004       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90004';   --正常終了メッセージ
  cv_message_90005       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90005';   --警告終了メッセージ
  cv_message_90006       CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90006';   --エラー終了全ロールバックメッセージ
  --プロファイル
  cv_purge_term_profile  CONSTANT VARCHAR2(100) := 'XXCOS1_EDI_PURGE_TERM';       --EDI情報削除期間
  cv_org_id_profile      CONSTANT VARCHAR2(100) := 'ORG_ID';                      --組織ID
  cv_case_uom_profile    CONSTANT VARCHAR2(100) := 'XXCOS1_CASE_UOM_CODE';        --ケース単位
  cv_org_code_profile    CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';    --在庫組織コード
-- Start 2009/07/29 Ver_1.6 0000514 M.Hiruta
  cv_set_of_books_id     CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';            -- 会計帳簿ID
-- End   2009/07/29 Ver_1.6 0000514 M.Hiruta
  --トークン
  cv_token_proc_type          CONSTANT VARCHAR2(10) := 'PROC_TYPE';               --トークン名(PROC_TYPE)
  cv_token_file_name          CONSTANT VARCHAR2(10) := 'FILE_NAME';               --トークン名(FILE_NAME)
  cv_token_profile            CONSTANT VARCHAR2(10) := 'PROFILE';                 --トークン名(PROFILE)
  cv_token_org_code           CONSTANT VARCHAR2(10) := 'ORG_CODE';                --トークン名(ORG_CODE)
  cv_token_type               CONSTANT VARCHAR2(5)  := 'TYPE';                    --トークン名(TYPE)
  cv_token_delivery_date      CONSTANT VARCHAR2(20) := 'STORE_DELIVERY_DATE';     --トークン名(STORE_DELIVERY_DATE)
  cv_token_slip_no            CONSTANT VARCHAR2(10) := 'SLIP_NO';                 --トークン名(SLIP_NO)
  cv_token_line_no            CONSTANT VARCHAR2(10) := 'LINE_NO';                 --トークン名(LINE_NO)
  cv_token_edi_chain_code     CONSTANT VARCHAR2(20) := 'EDI_CHAIN_CODE';          --トークン名(EDI_CHAIN_CODE)
  cv_token_center_code        CONSTANT VARCHAR2(20) := 'DELIVERY_CENTER_CODE';    --トークン名(DELIVERY_CENTER_CODE)
  cv_token_store_code         CONSTANT VARCHAR2(10) := 'STORE_CODE';              --トークン名(STORE_CODE)
  cv_token_qty                CONSTANT VARCHAR2(5)  := 'QTY';                     --トークン名(QTY)
  cv_token_customer_code      CONSTANT VARCHAR2(15) := 'CUSTOMER_CODE';           --トークン名(CUSTOMER_CODE)
  cv_token_customer_name      CONSTANT VARCHAR2(15) := 'CUSTOMER_NAME';           --トークン名(CUSTOMER_NAME)
  cv_token_tanto_loc_code     CONSTANT VARCHAR2(15) := 'TANTO_LOC_CODE';          --トークン名(TANTO_LOC_CODE)
  cv_token_tanto_code         CONSTANT VARCHAR2(10) := 'TANTO_CODE';              --トークン名(TANTO_CODE)
  cv_token_shohin_code        CONSTANT VARCHAR2(15) := 'SHOHIN_CODE';             --トークン名(SHOHIN_CODE)
  cv_token_item_code          CONSTANT VARCHAR2(10) := 'ITEM_CODE';               --トークン名(ITEM_CODE)
  cv_token_price_list_name    CONSTANT VARCHAR2(15) := 'PRICE_LIST_NAME';         --トークン名(PRICE_LIST_NAME)
  cv_token_unit_price_code    CONSTANT VARCHAR2(15) := 'UNIT_PRICE_CODE';         --トークン名(UNIT_TYPE_CODE)
  cv_token_tax_type           CONSTANT VARCHAR2(10) := 'TAX_TYPE';                --トークン名(TAX_TYPE)
  cv_token_edi_item_code_type CONSTANT VARCHAR2(20) := 'EDI_ITEM_CODE_TYPE';      --トークン名(EDI_ITEM_CODE_TYPE)
  cv_token_cust_order_e_flag  CONSTANT VARCHAR2(25) := 'CUST_ORDER_ENABLED_FLAG'; --トークン名(CUST_ORDER_ENABLED_FLAG)
  cv_token_selling_type       CONSTANT VARCHAR2(15) := 'SELLING_TYPE';            --トークン名(SELLING_TYPE)
  cv_token_org_id             CONSTANT VARCHAR2(10) := 'ORG_ID';                  --トークン名(ORG_ID)
  cv_token_delivery_price     CONSTANT VARCHAR2(15) := 'DELIVERY_PRICE';          --トークン名(DELIVERY_PRICE)
  cv_token_create_date        CONSTANT VARCHAR2(15) := 'CREATE_DATE';             --トークン名(CREATE_DATE)
  cv_token_count              CONSTANT VARCHAR2(5)  := 'COUNT';                   --トークン名(COUNT)
  --文字列
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi DELETE START
--  cv_lookup_type              CONSTANT VARCHAR2(50) := 'XXCOK1_CONSUMPTION_TAX_CLASS';   --値セット名
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi DELETE END
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
  -- 顧客使用目的
  cv_site_use_code_ship       CONSTANT VARCHAR2(10) := 'SHIP_TO'; -- 出荷先
  cv_site_use_code_bill       CONSTANT VARCHAR2(10) := 'BILL_TO'; -- 請求先
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
  cv_00                       CONSTANT VARCHAR2(2)  := '00';                             --文字列:00
  cv_0                        CONSTANT VARCHAR2(1)  := '0';                              --文字列:0
  cv_1                        CONSTANT VARCHAR2(1)  := '1';                              --文字列:1
  cv_2                        CONSTANT VARCHAR2(1)  := '2';                              --文字列:2
  cv_3                        CONSTANT VARCHAR2(1)  := '3';                              --文字列:3
  cv_4                        CONSTANT VARCHAR2(1)  := '4';                              --文字列:4
  cv_6                        CONSTANT VARCHAR2(1)  := '6';                              --文字列:6
  cv_10                       CONSTANT VARCHAR2(2)  := '10';                             --顧客区分(10:顧客)
  cv_18                       CONSTANT VARCHAR2(2)  := '18';                             --顧客区分(18:チェーン店)
  cv_40                       CONSTANT VARCHAR2(2)  := '40';                             --顧客ステータス(40:顧客)
-- Start 2009/07/13 Ver_1.6 0000514 M.Hiruta ADD
  cv_30                       CONSTANT VARCHAR2(2)  := '30';                             --顧客ステータス(30:承認済)
  cv_50                       CONSTANT VARCHAR2(2)  := '50';                             --顧客ステータス(50:休止)
-- End   2009/07/13 Ver_1.6 0000514 M.Hiruta ADD
  cv_99                       CONSTANT VARCHAR2(2)  := '99';                             --文字列:99
  cv_ship_to                  CONSTANT VARCHAR2(10) := 'SHIP_TO';                        --使用目的(出荷先)
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                              --フラグ(Y)
  cv_flag_n                   CONSTANT VARCHAR2(1)  := 'N';                              --フラグ(N)
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD START
  cv_flag_a                   CONSTANT VARCHAR2(1)  := 'A';                              --フラグ(A)
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD END
  cv_J                        CONSTANT VARCHAR2(1)  := 'J';                              --文字列:J
  cv_article_code             CONSTANT VARCHAR2(10) := '0000000000';                     --物件コード(固定値)
  --数値
  cn_0                        CONSTANT NUMBER       := 0;                                --数値:0
  cn_1                        CONSTANT NUMBER       := 1;                                --数値:1
  cn_100                      CONSTANT NUMBER       := 100;                              --数値:100
  --フォーマット
  cv_slip_no_format           CONSTANT VARCHAR2(9)  := '00000000';                       --伝票番号フォーマット
  cv_date_format              CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                     --日付フォーマット
  --WHOカラム
  cn_created_by               CONSTANT NUMBER       := fnd_global.user_id;               --CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER       := fnd_global.user_id;               --LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER       := fnd_global.login_id;              --LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER       := fnd_global.conc_request_id;       --REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER       := fnd_global.prog_appl_id;          --PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER       := fnd_global.conc_program_id;       --PROGRAM_ID
  cv_msg_part                 CONSTANT VARCHAR2(3)  := ' : ';                            --コロン
  cv_msg_cont                 CONSTANT VARCHAR2(3)  := '.';                              --ピリオド
  -- =========================
  -- グローバル変数
  -- =========================
  gn_target_cnt           NUMBER        DEFAULT 0;      --対象件数
  gn_normal_cnt           NUMBER        DEFAULT 0;      --成功件数
  gn_warn_cnt             NUMBER        DEFAULT 0;      --警告件数
  gn_error_cnt            NUMBER        DEFAULT 0;      --エラー件数
  gn_organization_id      NUMBER;                       --在庫組織ID
  gn_org_id               NUMBER;                       --プロファイル(組織ID)
  gn_line_no              NUMBER(3)     DEFAULT 0;      --明細番号
  gn_delivery_unit_price  NUMBER        DEFAULT 0;      --納品単価
  gv_case_uom             VARCHAR2(100) DEFAULT NULL;   --カスタムプロファイル(ケース単位)
  gv_purge_term           VARCHAR2(100) DEFAULT NULL;   --カスタムプロファイル(EDI情報削除期間)
  gv_keep_slip_no         VARCHAR2(9)   DEFAULT '0';    --伝票番号(保持用)
  gv_base_code            VARCHAR2(4)   DEFAULT '0';    --拠点コード
  gv_cust_code            VARCHAR2(9)   DEFAULT '0';    --顧客コード
  gv_item_code            VARCHAR2(7)   DEFAULT '0';    --品目コード
  gd_prdate               DATE;                         --業務日付
-- Start 2009/07/29 Ver_1.6 0000514 M.Hiruta ADD
  gn_set_of_books_id      NUMBER        DEFAULT NULL;   -- 会計帳簿ID
-- End   2009/07/29 Ver_1.6 0000514 M.Hiruta ADD
  -- =======================
  -- グローバルRECODE型
  -- =======================
  g_from_cust_rec xxcok_tmp_edi_selling_trns%ROWTYPE;
  g_to_cust_rec   xxcok_tmp_edi_selling_trns%ROWTYPE;
  -- =========================
  -- グローバル例外
  -- =========================
  -- *** ロックエラーハンドラ ***
  global_lock_fail          EXCEPTION;
  -- *** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  -- *** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  -- *** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  /**********************************************************************************
   * Procedure Name   : del_wk_tbl
   * Description      : EDIワークテーブル削除(B-9)
   ***********************************************************************************/
  PROCEDURE del_wk_tbl(
    ov_errbuf  OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode OUT VARCHAR2    --リターン・コード
  , ov_errmsg  OUT VARCHAR2)   --ユーザー・エラー・メッセージ
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(15) := 'del_wk_tbl';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                 VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    ln_edi_selling_trns_id NUMBER;                        --EDI売上実績振替情報ワークID
    ld_creation_date       DATE;                          --作成日
    lv_creation_date       VARCHAR2(10)   DEFAULT NULL;   --作成日(YYYY/MM/DD))
    lb_retcode             BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- 1.EDI売上実績振替情報ワークテーブルのロックを取得
    -- =============================================================================
    CURSOR edi_tbl_cur
    IS
      SELECT  xwest.creation_date AS creation_date
      FROM    xxcok_wk_edi_selling_trns xwest
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR START
--      WHERE   xwest.creation_date <= gd_prdate - gv_purge_term
      WHERE   xwest.creation_date <= gd_prdate - TO_NUMBER( gv_purge_term )
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR END
      FOR UPDATE NOWAIT;
    -- =======================
    -- ローカルレコード
    -- =======================
    edi_tbl_rec  edi_tbl_cur%ROWTYPE;
--
  BEGIN
    ov_retcode := cv_status_normal;
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR START
--    -- *** カーソルオープン ***
--    OPEN  edi_tbl_cur;
--    <<del_loop>>
--    LOOP
--      FETCH edi_tbl_cur INTO edi_tbl_rec;
--      EXIT WHEN edi_tbl_cur%NOTFOUND;
--      FETCH edi_tbl_cur INTO edi_tbl_rec;
--      ld_creation_date := edi_tbl_rec.creation_date;
--      -- =============================================================================
--      -- EDI売上実績振替情報ワークテーブルよりレコードを削除
--      -- =============================================================================
--      BEGIN
--        DELETE FROM xxcok_wk_edi_selling_trns xwest
--        WHERE  xwest.creation_date <= gd_prdate - gv_purge_term;
--      EXCEPTION
--        -- *** 削除に失敗した場合 ***
--        WHEN OTHERS THEN
--        lv_creation_date := TO_CHAR ( ld_creation_date, cv_date_format );
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_message_10091
--                  , iv_token_name1  => cv_token_create_date
--                  , iv_token_value1 => lv_creation_date
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT     --出力区分
--                      , iv_message  => lv_msg              --メッセージ
--                      , in_new_line => 0                   --改行
--                      );
--        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--        ov_retcode := cv_status_error;
--      END;
--    END LOOP del_loop;
--    CLOSE edi_tbl_cur;
    -- =============================================================================
    -- ロック取得
    -- =============================================================================
    OPEN  edi_tbl_cur;
    CLOSE edi_tbl_cur;
    -- =============================================================================
    -- EDI売上実績振替情報ワークテーブルよりレコードを削除
    -- =============================================================================
    BEGIN
      DELETE FROM xxcok_wk_edi_selling_trns xwest
      WHERE  xwest.creation_date <= gd_prdate - TO_NUMBER( gv_purge_term );
    EXCEPTION
      -- *** 削除に失敗した場合 ***
      WHEN OTHERS THEN
      lv_creation_date := TO_CHAR( gd_prdate - TO_NUMBER( gv_purge_term ), cv_date_format );
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10091
                , iv_token_name1  => cv_token_create_date
                , iv_token_value1 => lv_creation_date
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR END
  EXCEPTION
    -- ***ロックに失敗した場合 ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10090
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_wk_tbl;
--
  /**********************************************************************************
   * Procedure Name   : upd_edi_tbl_normal
   * Description      : EDIワークテーブル更新(正常)(B-8)
   ***********************************************************************************/
  PROCEDURE upd_edi_tbl_normal(
    ov_errbuf                  OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                 OUT VARCHAR2    --リターン・コード
  , ov_errmsg                  OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_edi_selling_info_wk_id  IN  NUMBER      --内部ID
  , iv_edi_chain_store_code    IN  VARCHAR2    --EDIチェーン店コード
  , iv_delivery_to_center_code IN  VARCHAR2    --納入先センターコード
  , iv_store_code              IN  VARCHAR2    --店コード
  , iv_goods_code              IN  VARCHAR2    --商品コード
  , in_delivery_unit_price     IN  NUMBER)     --納品単価
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'upd_edi_tbl_normal';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                 VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    ln_edi_selling_trns_id NUMBER;                        --EDI売上実績振替情報ワークID
    lb_retcode             BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- 1.EDI売上実績振替情報ワークテーブルのロックを取得
    -- =============================================================================
    CURSOR edi_tbl_cur
    IS
      SELECT xwest.edi_selling_trns_id AS edi_selling_trns_id
      FROM   xxcok_wk_edi_selling_trns xwest
      WHERE  xwest.edi_selling_trns_id = in_edi_selling_info_wk_id
      FOR UPDATE NOWAIT;
    -- =======================
    -- ローカルレコード
    -- =======================
    edi_tbl_rec  edi_tbl_cur%ROWTYPE;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** カーソルオープン ***
    OPEN edi_tbl_cur;
    <<upd_loop>>
    LOOP
      FETCH edi_tbl_cur INTO edi_tbl_rec;
      EXIT WHEN edi_tbl_cur%NOTFOUND;
      ln_edi_selling_trns_id := edi_tbl_rec.edi_selling_trns_id;
      -- =============================================================================
      -- 2.ステータスを更新
      -- =============================================================================
      BEGIN
        UPDATE  xxcok_wk_edi_selling_trns xwest
        SET     xwest.status                 = cv_1
              , xwest.last_updated_by        = cn_last_updated_by
              , xwest.last_update_date       = SYSDATE
              , xwest.last_update_login      = cn_last_update_login
              , xwest.request_id             = cn_request_id
              , xwest.program_application_id = cn_program_application_id
              , xwest.program_id             = cn_program_id
              , xwest.program_update_date    = SYSDATE
        WHERE   xwest.edi_selling_trns_id    = ln_edi_selling_trns_id;
        -- *** 成功件数カウント ***
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        -- *** 更新に失敗した場合 ***
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10089
                    , iv_token_name1  => cv_token_edi_chain_code
                    , iv_token_value1 => iv_edi_chain_store_code
                    , iv_token_name2  => cv_token_center_code
                    , iv_token_value2 => iv_delivery_to_center_code
                    , iv_token_name3  => cv_token_store_code
                    , iv_token_value3 => iv_store_code
                    , iv_token_name4  => cv_token_shohin_code
                    , iv_token_value4 => iv_goods_code
                    , iv_token_name5  => cv_token_delivery_price
                    , iv_token_value5 => in_delivery_unit_price
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
          ov_retcode := cv_status_error;
      END;
    END LOOP upd_loop;
    CLOSE edi_tbl_cur;
  EXCEPTION
    -- *** ロックに失敗した場合 ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10088
                , iv_token_name1  => cv_token_edi_chain_code
                , iv_token_value1 => iv_edi_chain_store_code
                , iv_token_name2  => cv_token_center_code
                , iv_token_value2 => iv_delivery_to_center_code
                , iv_token_name3  => cv_token_store_code
                , iv_token_value3 => iv_store_code
                , iv_token_name4  => cv_token_shohin_code
                , iv_token_value4 => iv_goods_code
                , iv_token_name5  => cv_token_delivery_price
                , iv_token_value5 => in_delivery_unit_price
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_edi_tbl_normal;
--
  /**********************************************************************************
   * Procedure Name   : upd_edi_tbl_error
   * Description      : EDIワークテーブル更新(エラー)(B-7)
   ***********************************************************************************/
  PROCEDURE upd_edi_tbl_error(
    ov_errbuf                 OUT VARCHAR2    --エラーメッセージ
  , ov_retcode                OUT VARCHAR2    --リターンコード
  , ov_errmsg                 OUT VARCHAR2    --ユーザーエラーメッセージ
  , in_edi_selling_info_wk_id IN  NUMBER      --内部ID
  , iv_slip_no                IN  VARCHAR2    --伝票番号
  , in_line_no                IN  NUMBER)     --行No
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'upd_edi_tbl_error';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                 VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    ln_edi_selling_trns_id NUMBER;                        --EDI売上実績振替情報ワークID
    lb_retcode             BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- 1.EDI売上実績振替情報ワークテーブルのロックを取得
    -- =============================================================================
    CURSOR edi_tbl_cur
    IS
      SELECT xwest.edi_selling_trns_id AS edi_selling_trns_id
      FROM   xxcok_wk_edi_selling_trns xwest
      WHERE  xwest.edi_selling_trns_id = in_edi_selling_info_wk_id
      FOR UPDATE NOWAIT;
    -- =======================
    -- ローカルレコード
    -- =======================
    edi_tbl_rec  edi_tbl_cur%ROWTYPE;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** カーソルオープン ***
    OPEN edi_tbl_cur;
    <<upd_loop>>
    LOOP
      FETCH edi_tbl_cur INTO edi_tbl_rec;
      EXIT WHEN edi_tbl_cur%NOTFOUND;
      ln_edi_selling_trns_id := edi_tbl_rec.edi_selling_trns_id;
      -- =============================================================================
      -- 2.ステータスを更新
      -- =============================================================================
      BEGIN
        UPDATE  xxcok_wk_edi_selling_trns xwest
        SET     xwest.status                 = cv_2
              , xwest.last_updated_by        = cn_last_updated_by
              , xwest.last_update_date       = SYSDATE
              , xwest.last_update_login      = cn_last_update_login
              , xwest.request_id             = cn_request_id
              , xwest.program_application_id = cn_program_application_id
              , xwest.program_id             = cn_program_id
              , xwest.program_update_date    = SYSDATE
        WHERE   xwest.edi_selling_trns_id    = ln_edi_selling_trns_id;
        -- *** スキップ件数カウント ***
        gn_warn_cnt := gn_warn_cnt + 1;
      EXCEPTION
        -- *** 更新に失敗した場合 ***
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10415
                    , iv_token_name1  => cv_token_slip_no
                    , iv_token_value1 => iv_slip_no
                    , iv_token_name2  => cv_token_line_no
                    , iv_token_value2 => in_line_no
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
          ov_retcode := cv_status_error;
      END;
    END LOOP upd_loop;
    CLOSE edi_tbl_cur;
  EXCEPTION
    -- *** ロックに失敗した場合 ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10414
                , iv_token_name1  => cv_token_slip_no
                , iv_token_value1 => iv_slip_no
                , iv_token_name2  => cv_token_line_no
                , iv_token_value2 => in_line_no
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_edi_tbl_error;
--
  /**********************************************************************************
   * Procedure Name   : ins_selling_trns_info
   * Description      : 売上実績振替情報作成(B-6)
   ***********************************************************************************/
  PROCEDURE ins_selling_trns_info(
    ov_errbuf                  OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                 OUT VARCHAR2    --リターン・コード
  , ov_errmsg                  OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , id_selling_date            IN  DATE        --売上計上日
  , iv_base_code               IN  VARCHAR2    --拠点コード
  , iv_cust_code               IN  VARCHAR2    --顧客コード
  , iv_selling_emp_code        IN  VARCHAR2    --担当営業コード
  , iv_cust_state_type         IN  VARCHAR2    --顧客業態区分
  , iv_selling_from_cust_code  IN  VARCHAR2    --売上振替元顧客コード
  , iv_item_code               IN  VARCHAR2    --品目コード
  , in_sum_qty                 IN  NUMBER      --数量
  , iv_unit_type               IN  VARCHAR2    --単位
  , in_delivery_unit_price     IN  NUMBER      --納品単価
  , in_sum_selling_amt         IN  NUMBER      --売上金額
  , in_sum_selling_amt_no_tax  IN  NUMBER      --売上金額（税抜き）
  , in_sum_trading_cost        IN  NUMBER      --営業原価
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--  , in_shipment_cost_amt       IN  NUMBER      --原価金額（出荷）
  , in_order_cost_amt          IN  NUMBER      --原価金額（発注）
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
  , iv_tax_type                IN  VARCHAR2    --消費税区分
  , in_tax_rate                IN  NUMBER      --消費税率
  , iv_selling_from_base_code  IN  VARCHAR2    --売上振替元拠点コード
  , iv_edi_chain_store_code    IN  VARCHAR2    --EDIチェーン店コード
  , iv_delivery_to_center_code IN  VARCHAR2    --納入先センターコード
  , iv_store_code              IN  VARCHAR2    --店コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR START
--  , iv_goods_code              IN  VARCHAR2)   --商品コード
  , iv_goods_code              IN  VARCHAR2    --商品コード
  , iv_bill_cust_code          IN  VARCHAR2    --請求先顧客コード
  , iv_tax_code                IN  VARCHAR2    --税コード
  )
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR END
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(25) := 'ins_selling_trns_info';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                   VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lv_slip_no               VARCHAR2(9)    DEFAULT NULL;   --伝票番号
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi DELETE START
--    lv_tax_code              VARCHAR2(4)    DEFAULT NULL;   --消費税コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi DELETE END
    ln_selling_trns_info_s02 NUMBER;                        --伝票番号
    lb_retcode               BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    lv_slip_no := gv_keep_slip_no;
    -- =============================================================================
    -- 伝票番号を設定(拠点コード、顧客コード、品目コード毎に採番)
    -- =============================================================================
    IF NOT (    ( gv_base_code = iv_base_code )
            AND ( gv_cust_code = iv_cust_code )
            AND ( gv_item_code = iv_item_code )
           ) THEN
      SELECT xxcok_selling_trns_info_s02.NEXTVAL AS xxcok_selling_trns_info_s02
      INTO   ln_selling_trns_info_s02
      FROM   DUAL;
      -- *** 伝票番号を設定 ***
      lv_slip_no := cv_J || LTRIM( TO_CHAR( ln_selling_trns_info_s02, cv_slip_no_format ) );
      -- *** 明細番号、納品単価を初期化 ***
      gn_line_no             := cn_0;
      gn_delivery_unit_price := cn_0;
      -- *** 各値を保持 ***
      gv_keep_slip_no := lv_slip_no;
      gv_base_code    := iv_base_code;
      gv_cust_code    := iv_cust_code;
      gv_item_code    := iv_item_code;
    END IF;
    -- =============================================================================
    -- 明細番号を設定(伝票番号毎に、納品単価毎に採番)
    -- =============================================================================
    IF (    ( gv_keep_slip_no         = lv_slip_no             )
        AND ( gn_delivery_unit_price <> in_delivery_unit_price )
       ) THEN
      gn_line_no := gn_line_no + 1;
      -- *** 納品単価を保持 ***
      gn_delivery_unit_price := in_delivery_unit_price;
    END IF;
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi DELETE START
--    -- =============================================================================
--    -- 消費税区分を消費税コードに変換
--    -- =============================================================================
--    SELECT flv.attribute1 AS tax_code
--    INTO   lv_tax_code
--    FROM   fnd_lookup_values flv
--    WHERE  flv.lookup_type   = cv_lookup_type
--    AND    flv.lookup_code   = iv_tax_type
--    AND    flv.enabled_flag  = cv_flag_y
--    AND    gd_prdate BETWEEN flv.start_date_active
--                         AND NVL( flv.end_date_active, gd_prdate )
--    AND    flv.language      = USERENV('LANG');
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi DELETE END
    -- =============================================================================
    -- 売上実績振替情報を作成
    -- =============================================================================
    BEGIN
      INSERT INTO xxcok_selling_trns_info(
        selling_trns_info_id                  --売上実績振替情報ID
      , selling_trns_type                     --実績振替区分
      , slip_no                               --伝票番号
      , detail_no                             --明細番号
      , selling_date                          --売上計上日
      , selling_type                          --売上区分
      , selling_return_type                   --売上返品区分
      , delivery_slip_type                    --納品伝票区分
      , base_code                             --拠点コード
      , cust_code                             --顧客コード
      , selling_emp_code                      --担当営業コード
      , cust_state_type                       --顧客業態区分
      , delivery_form_type                    --納品形態区分
      , article_code                          --物件コード
      , card_selling_type                     --カード売り区分
      , checking_date                         --検収日
      , demand_to_cust_code                   --請求先顧客コード
      , h_c                                   --H and C
      , column_no                             --コラムNo.
      , item_code                             --品目コード
      , qty                                   --数量
      , unit_type                             --単位
      , delivery_unit_price                   --納品単価
      , selling_amt                           --売上金額
      , selling_amt_no_tax                    --売上金額（税抜き）
      , trading_cost                          --営業原価
      , selling_cost_amt                      --売上原価金額
      , tax_code                              --消費税コード
      , tax_rate                              --消費税率
      , delivery_base_code                    --納品拠点コード
      , registration_date                     --業務登録日付
      , correction_flag                       --振戻フラグ
      , report_decision_flag                  --速報確定フラグ
      , info_interface_flag                   --情報系I/Fフラグ
      , gl_interface_flag                     --仕訳作成フラグ
      , org_slip_number                       --元伝票番号
-- 2009/10/16 Ver.1.8 [障害E_T3_00632] SCS S.Moriyama ADD START
      , selling_from_cust_code                --売上振替元顧客コード
-- 2009/10/16 Ver.1.8 [障害E_T3_00632] SCS S.Moriyama ADD END
      , created_by                            --作成者
      , creation_date                         --作成日
      , last_updated_by                       --最終更新者
      , last_update_date                      --最終更新日
      , last_update_login                     --最終更新ログイン
      , request_id                            --要求ID
      , program_application_id                --コンカレント・プログラム・アプリケーションID
      , program_id                            --コンカレント・プログラムID
      , program_update_date                   --プログラム更新日
      ) VALUES (
        XXCOK_SELLING_TRNS_INFO_S01.NEXTVAL   --selling_trns_info_id
      , cv_1                                  --selling_trns_type
      , gv_keep_slip_no                       --slip_no
      , gn_line_no                            --detail_no
      , id_selling_date                       --selling_date
      , cv_1                                  --selling_type
      , cv_1                                  --selling_return_type
      , cv_1                                  --delivery_slip_type
      , iv_base_code                          --base_code
      , iv_cust_code                          --cust_code
      , iv_selling_emp_code                   --selling_emp_code
      , iv_cust_state_type                    --cust_state_type
      , cv_6                                  --delivery_form_type
      , cv_article_code                       --article_code
      , cv_0                                  --card_selling_type
      , NULL                                  --checking_date
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR START
--      , iv_selling_from_cust_code             --demand_to_cust_code
      , iv_bill_cust_code                     --demand_to_cust_code
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR END
      , cv_1                                  --h_c
      , cv_00                                 --column_no
      , iv_item_code                          --item_code
      , in_sum_qty                            --qty
      , iv_unit_type                          --unit_type
      , in_delivery_unit_price                --delivery_unit_price
      , in_sum_selling_amt                    --selling_amt
      , in_sum_selling_amt_no_tax             --selling_amt_no_tax
      , in_sum_trading_cost                   --trading_cost
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      , in_shipment_cost_amt                  --selling_cost_amt
      , in_order_cost_amt                     --selling_cost_amt
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR START
--      , lv_tax_code                           --tax_code
      , iv_tax_code                           --tax_code
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR END
      , in_tax_rate                           --tax_rate
      , iv_selling_from_base_code             --delivery_base_code
      , gd_prdate                             --registration_date
      , cv_1                                  --correction_flag
      , cv_1                                  --report_decision_flag
      , cv_0                                  --info_interface_flag
      , cv_0                                  --gl_interface_flag
      , NULL                                  --org_slip_number
-- 2009/10/16 Ver.1.8 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_selling_from_cust_code             --selling_from_cust_code
-- 2009/10/16 Ver.1.8 [障害E_T3_00632] SCS S.Moriyama ADD END
      , cn_created_by                         --created_by
      , SYSDATE                               --creation_date
      , cn_last_updated_by                    --last_updated_by
      , SYSDATE                               --last_update_date
      , cn_last_update_login                  --last_update_login
      , cn_request_id                         --request_id
      , cn_program_application_id             --program_application_id
      , cn_program_id                         --program_id
      , SYSDATE                               --program_update_date
      );
    EXCEPTION
      -- *** テーブルの挿入に失敗 ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10087
                  , iv_token_name1  => cv_token_edi_chain_code
                  , iv_token_value1 => iv_edi_chain_store_code
                  , iv_token_name2  => cv_token_center_code
                  , iv_token_value2 => iv_delivery_to_center_code
                  , iv_token_name3  => cv_token_store_code
                  , iv_token_value3 => iv_store_code
                  , iv_token_name4  => cv_token_shohin_code
                  , iv_token_value4 => iv_goods_code
                  , iv_token_name5  => cv_token_delivery_price
                  , iv_token_value5 => in_delivery_unit_price
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --出力区分
                      , iv_message  => lv_msg              --メッセージ
                      , in_new_line => 0                   --改行
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_selling_trns_info;
--
  /**********************************************************************************
   * Procedure Name   : get_qty_amt_total
   * Description      : 数量・売上金額の集計(B-5)
   ***********************************************************************************/
  PROCEDURE get_qty_amt_total(
    ov_errbuf          OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode         OUT VARCHAR2    --リターン・コード
  , ov_errmsg          OUT VARCHAR2)   --ユーザー・エラー・メッセージ
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'get_qty_amt_total';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg          VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode      BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =======================================================================================
    -- 顧客コード、拠点コード、品目コード、納品単価毎に数量、売上金額、売上金額(税抜き)を集計
    -- =======================================================================================
    CURSOR tmp_edi_cur
    IS
      SELECT    xtest.selling_date             AS selling_date              --売上計上日
              , xtest.base_code                AS base_code                 --拠点コード
              , xtest.cust_code                AS cust_code                 --顧客コード
              , xtest.selling_emp_code         AS selling_emp_code          --担当営業コード
              , xtest.cust_state_type          AS cust_state_type           --顧客業態区分
              , xtest.item_code                AS item_code                 --品目コード
              , SUM(xtest.qty)                 AS sum_qty                   --数量
              , xtest.unit_type                AS unit_type                 --単位
              , xtest.delivery_unit_price      AS delivery_unit_price       --納品単価
              , SUM(xtest.selling_amt)         AS sum_selling_amt           --売上金額
              , SUM(xtest.selling_amt_no_tax)  AS sum_selling_amt_no_tax    --売上金額（税抜き）
              , xtest.tax_type                 AS tax_type                  --消費税区分
              , xtest.tax_rate                 AS tax_rate                  --消費税率
              , SUM(xtest.trading_cost)        AS sum_trading_cost          --営業原価
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--              , xtest.shipment_cost_amt        AS shipment_cost_amt         --原価金額（出荷）
              , xtest.order_cost_amt           AS order_cost_amt            --原価金額（発注）
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
              , xtest.selling_from_base_code   AS selling_from_base_code    --売上振替元拠点コード
              , xtest.selling_from_cust_code   AS selling_from_cust_code    --売上振替元顧客コード
              , xtest.edi_chain_store_code     AS edi_chain_store_code      --EDIチェーン店コード
              , xtest.delivery_to_center_code  AS delivery_to_center_code   --納入先センターコード
              , xtest.store_code               AS store_code                --店コード
              , xtest.goods_code               AS goods_code                --商品コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
              , xtest.bill_cust_code           AS bill_cust_code            --請求先顧客コード
              , xtest.tax_code                 AS tax_code                  --税コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
      FROM      xxcok_tmp_edi_selling_trns xtest
      GROUP BY  selling_date
              , base_code
              , cust_code
              , selling_emp_code
              , cust_state_type
              , item_code
              , unit_type
              , delivery_unit_price
              , tax_type
              , tax_rate
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--              , shipment_cost_amt
              , order_cost_amt
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
              , selling_from_base_code
              , selling_from_cust_code
              , edi_chain_store_code
              , delivery_to_center_code
              , store_code
              , goods_code
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
              , xtest.bill_cust_code
              , xtest.tax_code
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
      ORDER BY  base_code
              , cust_code
              , item_code
              , delivery_unit_price;
    -- =======================
    -- ローカルTABLE型
    -- =======================
    TYPE tab_type IS TABLE OF tmp_edi_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_tmp_edi_cur_tab  tab_type;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** カーソルオープン ***
    OPEN  tmp_edi_cur;
    FETCH tmp_edi_cur BULK COLLECT INTO l_tmp_edi_cur_tab;
    CLOSE tmp_edi_cur;
--
    <<loop_2>>
    FOR ln_idx IN 1 .. l_tmp_edi_cur_tab.COUNT LOOP
      -- =============================================================================
      -- 売上実績振替情報作成(B-6)の呼出し
      -- =============================================================================
      ins_selling_trns_info(
        ov_errbuf                  => lv_errbuf                                             --エラーメッセージ
      , ov_retcode                 => lv_retcode                                            --リターンコード
      , ov_errmsg                  => lv_errmsg                                             --ユーザーエラーメッセージ
      , id_selling_date            => l_tmp_edi_cur_tab( ln_idx ).selling_date              --売上計上日
      , iv_base_code               => l_tmp_edi_cur_tab( ln_idx ).base_code                 --拠点コード
      , iv_cust_code               => l_tmp_edi_cur_tab( ln_idx ).cust_code                 --顧客コード
      , iv_selling_emp_code        => l_tmp_edi_cur_tab( ln_idx ).selling_emp_code          --担当営業コード
      , iv_cust_state_type         => l_tmp_edi_cur_tab( ln_idx ).cust_state_type           --顧客業態区分
      , iv_selling_from_cust_code  => l_tmp_edi_cur_tab( ln_idx ).selling_from_cust_code    --売上振替元顧客コード
      , iv_item_code               => l_tmp_edi_cur_tab( ln_idx ).item_code                 --品目コード
      , in_sum_qty                 => l_tmp_edi_cur_tab( ln_idx ).sum_qty                   --数量
      , iv_unit_type               => l_tmp_edi_cur_tab( ln_idx ).unit_type                 --単位
      , in_delivery_unit_price     => l_tmp_edi_cur_tab( ln_idx ).delivery_unit_price       --納品単価
      , in_sum_selling_amt         => l_tmp_edi_cur_tab( ln_idx ).sum_selling_amt           --売上金額
      , in_sum_selling_amt_no_tax  => l_tmp_edi_cur_tab( ln_idx ).sum_selling_amt_no_tax    --売上金額（税抜き）
      , in_sum_trading_cost        => l_tmp_edi_cur_tab( ln_idx ).sum_trading_cost          --営業原価
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      , in_shipment_cost_amt       => l_tmp_edi_cur_tab( ln_idx ).shipment_cost_amt         --原価金額（出荷）
      , in_order_cost_amt          => l_tmp_edi_cur_tab( ln_idx ).order_cost_amt            --原価金額（発注）
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      , iv_tax_type                => l_tmp_edi_cur_tab( ln_idx ).tax_type                  --消費税区分
      , in_tax_rate                => l_tmp_edi_cur_tab( ln_idx ).tax_rate                  --消費税率
      , iv_selling_from_base_code  => l_tmp_edi_cur_tab( ln_idx ).selling_from_base_code    --売上振替元拠点コード
      , iv_edi_chain_store_code    => l_tmp_edi_cur_tab( ln_idx ).edi_chain_store_code      --EDIチェーン店コード
      , iv_delivery_to_center_code => l_tmp_edi_cur_tab( ln_idx ).delivery_to_center_code   --納入先センターコード
      , iv_store_code              => l_tmp_edi_cur_tab( ln_idx ).store_code                --店コード
      , iv_goods_code              => l_tmp_edi_cur_tab( ln_idx ).goods_code                --商品コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
      , iv_bill_cust_code          => l_tmp_edi_cur_tab( ln_idx ).bill_cust_code            --請求先顧客コード
      , iv_tax_code                => l_tmp_edi_cur_tab( ln_idx ).tax_code                  --税コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP loop_2;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_qty_amt_total;
--
  /**********************************************************************************
   * Procedure Name   : ins_tmp_tbl
   * Description      : 一時表作成(B-4)
   ***********************************************************************************/
  PROCEDURE ins_tmp_tbl(
    ov_errbuf          OUT VARCHAR2                               --エラー・メッセージ
  , ov_retcode         OUT VARCHAR2                               --リターン・コード
  , ov_errmsg          OUT VARCHAR2                               --ユーザー・エラー・メッセージ
  , it_from_cust_rec   IN  xxcok_tmp_edi_selling_trns%ROWTYPE     --テーブル型(振替元顧客コード)
  , it_to_cust_rec     IN  xxcok_tmp_edi_selling_trns%ROWTYPE)    --テーブル型(振替先顧客コード)
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(15) := 'ins_tmp_tbl';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg          VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode      BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 売上振替元顧客コードをキーとし、一時表を作成
    -- =============================================================================
    INSERT INTO xxcok_tmp_edi_selling_trns(
      selling_date                               --売上計上日
    , base_code                                  --拠点コード
    , cust_code                                  --顧客コード
    , selling_emp_code                           --担当営業コード
    , cust_state_type                            --顧客業態区分
    , item_code                                  --品目コード
    , qty                                        --数量
    , unit_type                                  --単位
    , delivery_unit_price                        --納品単価
    , selling_amt                                --売上金額
    , selling_amt_no_tax                         --売上金額（税抜き）
    , tax_type                                   --消費税区分
    , tax_rate                                   --消費税率
    , trading_cost                               --営業原価
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , shipment_cost_amt                          --原価金額（出荷）
    , order_cost_amt                             --原価金額（発注）
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , selling_from_base_code                     --売上振替元拠点コード
    , selling_from_cust_code                     --売上振替元顧客コード
    , edi_chain_store_code                       --EDIチェーン店コード
    , delivery_to_center_code                    --納入先センターコード
    , store_code                                 --店コード
    , goods_code                                 --商品コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
    , bill_cust_code                             --請求先顧客コード
    , tax_code                                   --税コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
    ) VALUES (
      it_from_cust_rec.selling_date              --selling_date
    , it_from_cust_rec.base_code                 --base_code
    , it_from_cust_rec.cust_code                 --cust_code
    , it_from_cust_rec.selling_emp_code          --selling_emp_code
    , it_from_cust_rec.cust_state_type           --cust_state_type
    , it_from_cust_rec.item_code                 --item_code
    , it_from_cust_rec.qty                       --qty
    , it_from_cust_rec.unit_type                 --unit_type
    , it_from_cust_rec.delivery_unit_price       --delivery_unit_price
-- Start 2009/05/19 Ver_1.4 T1_1043 M.Hiruta
--    , it_from_cust_rec.selling_amt               --selling_amt
--    , it_from_cust_rec.selling_amt_no_tax        --selling_amt_no_tax
    , TRUNC(it_from_cust_rec.selling_amt)        --selling_amt
    , TRUNC(it_from_cust_rec.selling_amt_no_tax) --selling_amt_no_tax
-- End   2009/05/19 Ver_1.4 T1_1043 M.Hiruta
    , it_from_cust_rec.tax_type                  --tax_type
    , it_from_cust_rec.tax_rate                  --tax_rate
    , it_from_cust_rec.trading_cost              --trading_cost
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , it_from_cust_rec.shipment_cost_amt         --shipment_cost_amt
    , it_from_cust_rec.order_cost_amt            --order_cost_amt
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , it_from_cust_rec.selling_from_base_code    --selling_from_base_code
    , it_from_cust_rec.selling_from_cust_code    --selling_from_cust_code
    , it_from_cust_rec.edi_chain_store_code      --edi_chain_store_code
    , it_from_cust_rec.delivery_to_center_code   --delivery_to_center_code
    , it_from_cust_rec.store_code                --store_code
    , it_from_cust_rec.goods_code                --goods_code
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
    , it_from_cust_rec.bill_cust_code            --bill_cust_code
    , it_from_cust_rec.tax_code                  --tax_code
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
    );
    -- =============================================================================
    -- 売上振替先顧客コードをキーとし、一時表を作成
    -- =============================================================================
    INSERT INTO xxcok_tmp_edi_selling_trns(
      selling_date                             --売上計上日
    , base_code                                --拠点コード
    , cust_code                                --顧客コード
    , selling_emp_code                         --担当営業コード
    , cust_state_type                          --顧客業態区分
    , item_code                                --品目コード
    , qty                                      --数量
    , unit_type                                --単位
    , delivery_unit_price                      --納品単価
    , selling_amt                              --売上金額
    , selling_amt_no_tax                       --売上金額（税抜き）
    , tax_type                                 --消費税区分
    , tax_rate                                 --消費税率
    , trading_cost                             --営業原価
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , shipment_cost_amt                        --原価金額（出荷）
    , order_cost_amt                           --原価金額（発注）
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , selling_from_base_code                   --売上振替元拠点コード
    , selling_from_cust_code                   --売上振替元顧客コード
    , edi_chain_store_code                     --EDIチェーン店コード
    , delivery_to_center_code                  --納入先センターコード
    , store_code                               --店コード
    , goods_code                               --商品コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
    , bill_cust_code                             --請求先顧客コード
    , tax_code                                   --税コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
    ) VALUES (
      it_to_cust_rec.selling_date              --selling_date
    , it_to_cust_rec.base_code                 --base_code
    , it_to_cust_rec.cust_code                 --cust_code
    , it_to_cust_rec.selling_emp_code          --selling_emp_code
    , it_to_cust_rec.cust_state_type           --cust_state_type
    , it_to_cust_rec.item_code                 --item_code
    , it_to_cust_rec.qty                       --qty
    , it_to_cust_rec.unit_type                 --unit_type
    , it_to_cust_rec.delivery_unit_price       --delivery_unit_price
-- Start 2009/05/19 Ver_1.4 T1_1043 M.Hiruta
--    , it_to_cust_rec.selling_amt               --selling_amt
--    , it_to_cust_rec.selling_amt_no_tax        --selling_amt_no_tax
    , TRUNC(it_to_cust_rec.selling_amt)        --selling_amt
    , TRUNC(it_to_cust_rec.selling_amt_no_tax) --selling_amt_no_tax
-- End   2009/05/19 Ver_1.4 T1_1043 M.Hiruta
    , it_to_cust_rec.tax_type                  --tax_type
    , it_to_cust_rec.tax_rate                  --tax_rate
    , it_to_cust_rec.trading_cost              --trading_cost
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , it_to_cust_rec.shipment_cost_amt         --shipment_cost_amt
    , it_to_cust_rec.order_cost_amt            --order_cost_amt
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    , it_to_cust_rec.selling_from_base_code    --selling_from_base_code
    , it_to_cust_rec.selling_from_cust_code    --selling_from_cust_code
    , it_to_cust_rec.edi_chain_store_code      --edi_chain_store_code
    , it_to_cust_rec.delivery_to_center_code   --delivery_to_center_code
    , it_to_cust_rec.store_code                --store_code
    , it_to_cust_rec.goods_code                --goods_code
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
    , it_to_cust_rec.bill_cust_code            --bill_cust_code
    , it_to_cust_rec.tax_code                  --tax_code
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
    );
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_tmp_tbl;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_code
   * Description      : 顧客コードの変換(B-10)
   ***********************************************************************************/
  PROCEDURE get_cust_code(
    ov_errbuf               OUT VARCHAR2    --エラーメッセージ
  , ov_retcode              OUT VARCHAR2    --リターンコード
  , ov_errmsg               OUT VARCHAR2    --ユーザーエラーメッセージ
  , iv_message_code         IN  VARCHAR2    --メッセージコード
  , iv_edi_chain_store_code IN  VARCHAR2    --EDIチェーン店コード
  , iv_code                 IN  VARCHAR2    --納入先センターコード・店コード
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--  , in_shipment_unit_price  IN  NUMBER      --納品単価
  , in_order_unit_price     IN  NUMBER      --納品単価
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD START
    --売上拠点,担当営業員の抽出のため追加
  , id_store_delivery_date  IN  DATE        --店舗納品日
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD END
  , iv_token                IN  VARCHAR2    --トークン名
  , ov_sale_base_code       OUT VARCHAR2    --拠点コード
  , ov_account_number       OUT VARCHAR2    --顧客コード
  , ov_sales_stuff_code     OUT VARCHAR2    --担当営業コード
  , ov_business_low_type    OUT VARCHAR2    --顧客業態区分
  , on_price_list_id        OUT NUMBER      --価格表ID
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama AND START
  , ov_account_name         OUT VARCHAR2)   --顧客名
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama AND END

  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(15) := 'get_cust_code';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg           VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama DEL START
---- Start 2009/05/15 Ver_1.3 T1_1003 M.Hiruta
----    lv_account_name  VARCHAR2(30)   DEFAULT NULL;   --顧客名
---- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
----    lv_account_name  hz_cust_accounts.account_name%TYPE  DEFAULT NULL; --顧客名
--    lv_account_name  hz_parties.party_name%TYPE  DEFAULT NULL; --顧客名
---- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
---- End   2009/05/15 Ver_1.3 T1_1003 M.Hiruta
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama DEL END
    lb_retcode       BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
    -- =======================
    -- ローカル例外
    -- =======================
    skip_expt  EXCEPTION;   --顧客コードの変換プロシージャ内エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 2.顧客コードの変換
    -- =============================================================================
    BEGIN
      SELECT  hca.account_number    AS account_number      --顧客コード
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--            , hca.account_name      AS account_name        --顧客名
            , hp.party_name         AS account_name        --顧客名
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima MOD START
--            , xca.sale_base_code    AS sale_base_code      --売上担当拠点コード
              -- 店舗納品日が当月の場合、売上拠点
              -- 前月の場合、前月売上拠点を出力
            , CASE WHEN (id_store_delivery_date < TRUNC(gd_prdate, 'MM')) THEN
                xca.past_sale_base_code
              ELSE
                xca.sale_base_code
              END                   AS sale_base_code      --売上担当拠点コード
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima MOD END
            , xca.business_low_type AS business_low_type   --業態(小分類)
            , hcsua.price_list_id   AS price_list_id       --価格表ID
      INTO    ov_account_number
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama UPD START
--            , lv_account_name
            , ov_account_name
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama UPD END
            , ov_sale_base_code
            , ov_business_low_type
            , on_price_list_id
      FROM    hz_cust_accounts       hca     --顧客マスタ
            , xxcmm_cust_accounts    xca     --顧客追加情報
            , hz_cust_acct_sites_all hcasa   --顧客所在地
            , hz_cust_site_uses_all  hcsua   --顧客使用目的
            , hz_parties             hp      --パーティマスタ
      WHERE   hca.cust_account_id      = hcasa.cust_account_id
      AND     hca.cust_account_id      = xca.customer_id
      AND     hcasa.cust_acct_site_id  = hcsua.cust_acct_site_id
      AND     hp.party_id              = hca.party_id
      AND     hca.customer_class_code  = cv_10
-- Start 2009/07/13 Ver_1.6 0000514 M.Hiruta REPAIR
--      AND     hp.duns_number_c         = cv_40
      AND     hp.duns_number_c        IN( cv_30 , cv_40 , cv_50 )
-- End   2009/07/13 Ver_1.6 0000514 M.Hiruta REPAIR
      AND     xca.selling_transfer_div = cv_1
      AND     xca.chain_store_code     = iv_edi_chain_store_code
      AND     xca.store_code           = iv_code
      AND     hcsua.site_use_code      = cv_ship_to
-- Start 2009/05/19 Ver_1.4 T1_1043 M.Hiruta
      AND     hcasa.org_id             = gn_org_id
-- End   2009/05/19 Ver_1.4 T1_1043 M.Hiruta
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD START
      AND     hcsua.status             = cv_flag_a
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD END
      AND     hcsua.org_id             = gn_org_id;
    EXCEPTION
    -- *** 顧客コードが取得できない場合(顧客コードの変換に失敗した場合) ***
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => iv_message_code
                  , iv_token_name1  => cv_token_edi_chain_code
                  , iv_token_value1 => iv_edi_chain_store_code
                  , iv_token_name2  => iv_token
                  , iv_token_value2 => iv_code
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE skip_expt;
    END;
    -- =============================================================================
    -- 担当営業コードを取得
    -- =============================================================================
    ov_sales_stuff_code := xxcok_common_pkg.get_sales_staff_code_f(
                             iv_customer_code => ov_account_number   --顧客コード
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima MOD START
--                           , id_proc_date     => gd_prdate           --処理日
                             -- 業務日付 -> 店舗納品日に変更
                           , id_proc_date     => id_store_delivery_date --処理日
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima MOD END
                           );
    -- =============================================================================
    -- 売上担当拠点コード、担当営業コードのどちらか、または両方に値が
    -- 設定されていない場合、例外処理
    -- =============================================================================
    IF (   ( ov_sale_base_code   IS NULL )
        OR ( ov_sales_stuff_code IS NULL )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00045
                , iv_token_name1  => cv_token_customer_code
                , iv_token_value1 => ov_account_number
                , iv_token_name2  => cv_token_customer_name
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama UPD START
--                , iv_token_value2 => lv_account_name
                , iv_token_value2 => ov_account_name
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama UPD END
                , iv_token_name3  => cv_token_tanto_loc_code
                , iv_token_value3 => ov_sale_base_code
                , iv_token_name4  => cv_token_tanto_code
                , iv_token_value4 => ov_sales_stuff_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE skip_expt;
    END IF;
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama DEL START
--    -- =============================================================================
--    -- B-2.で取得した納品単価がNULL、または、0の場合、かつ
--    -- 上記で取得した価格表IDに値が設定されていない場合、例外処理
--    -- =============================================================================
---- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
----    IF ( (   ( in_shipment_unit_price IS NULL )
----          OR ( in_shipment_unit_price = cn_0  )
----         )
----         AND ( on_price_list_id IS NULL )
----       ) THEN
--    IF ( (   ( in_order_unit_price IS NULL )
--          OR ( in_order_unit_price = cn_0  )
--         )
--         AND ( on_price_list_id IS NULL )
--       ) THEN
---- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_message_10095
--                , iv_token_name1  => cv_token_customer_code
--                , iv_token_value1 => ov_account_number
--                , iv_token_name2  => cv_token_customer_name
--                , iv_token_value2 => lv_account_name
--                , iv_token_name3  => cv_token_tanto_loc_code
--                , iv_token_value3 => ov_sale_base_code
--                , iv_token_name4  => cv_token_tanto_code
--                , iv_token_value4 => ov_sales_stuff_code
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      RAISE skip_expt;
--    END IF;
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama DEL END
  EXCEPTION
    -- *** 
    WHEN skip_expt THEN
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_cust_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : データチェック(B-3)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf                  OUT VARCHAR2                             --エラー・メッセージ
  , ov_retcode                 OUT VARCHAR2                             --リターン・コード
  , ov_errmsg                  OUT VARCHAR2                             --ユーザー・エラー・メッセージ
  , ot_from_cust_rec           OUT xxcok_tmp_edi_selling_trns%ROWTYPE   --テーブル型(振替元顧客コード)
  , ot_to_cust_rec             OUT xxcok_tmp_edi_selling_trns%ROWTYPE   --テーブル型(振替先顧客コード)
  , id_store_delivery_date     IN  DATE                                 --店舗納品日
  , iv_slip_no                 IN  VARCHAR2                             --伝票番号
  , in_line_no                 IN  NUMBER                               --行No
  , iv_edi_chain_store_code    IN  VARCHAR2                             --EDIチェーン店コード
  , iv_delivery_to_center_code IN  VARCHAR2                             --納入先センターコード
  , iv_store_code              IN  VARCHAR2                             --店コード
  , in_order_qty_sum           IN  NUMBER                               --数量
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--  , in_shipment_unit_price     IN  NUMBER                               --納品単価
  , in_order_unit_price        IN  NUMBER                               --納品単価
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
  , iv_goods_code_2            IN  VARCHAR2                             --商品コード2
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--  , in_shipment_cost_amt       IN  NUMBER)                              --原価金額(出荷)
  , in_order_cost_amt          IN  NUMBER)                              --原価金額(発注)
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(10) := 'chk_data';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf                       VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode                      VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg                       VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                          VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lv_parameter                    VARCHAR2(1)    DEFAULT NULL;   --パラメータ 1:エラー
    lv_from_account_number          VARCHAR2(9)    DEFAULT NULL;   --売上振替元顧客コード
    lv_to_account_number            VARCHAR2(9)    DEFAULT NULL;   --売上振替先顧客コード
    lv_sale_base_code               VARCHAR2(4)    DEFAULT NULL;   --売上拠点コード
    lv_sales_stuff_code             VARCHAR2(30)   DEFAULT NULL;   --担当営業員コード
    lv_business_low_type            VARCHAR2(2)    DEFAULT NULL;   --業態(小分類)
    lv_price_list_name              VARCHAR2(240)  DEFAULT NULL;   --価格表名
    lv_edi_item_code_div            VARCHAR2(1)    DEFAULT NULL;   --EDI連携品目コード区分
    lv_item_code                    VARCHAR2(7)    DEFAULT NULL;   --品目コード
    lv_customer_order_enabled_flag  VARCHAR2(1)    DEFAULT NULL;   --顧客受注可能フラグ
    lv_selling_type                 VARCHAR2(1)    DEFAULT NULL;   --売上対象区分
    lv_unit_type                    VARCHAR2(25)   DEFAULT NULL;   --単位
    lv_cost_item_unit_type          VARCHAR2(240)  DEFAULT NULL;   --営業原価(品目単位)
    lv_tax_type                     VARCHAR2(1)    DEFAULT NULL;   --消費税区分
    ln_price_list_id                NUMBER;                        --価格表ID
-- 2010/01/07 Ver.1.11 [E_本稼動_00180] SCS S.Moriyama ADD START
    lt_price_list_id_dummy          qp_list_headers_b.list_header_id%TYPE;      --価格表ID（振替先顧客格納用ダミー）
    lt_account_name                 hz_parties.party_name%TYPE;    --顧客名
-- 2010/01/07 Ver.1.11 [E_本稼動_00180] SCS S.Moriyama ADD END
    ln_item_id                      NUMBER;                        --品目ID
    ln_case_qty                     NUMBER(5);                     --ケース入数
    ln_qty                          NUMBER         DEFAULT 0;      --数量
    ln_unit_price                   NUMBER         DEFAULT 0;      --単価(共通関数で取得したもの)
    ln_trading_cost                 NUMBER         DEFAULT 0;      --算出した営業原価
    ln_tax_rate                     NUMBER;                        --消費税率
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
    lv_tax_code                     ar_vat_tax_all_b.tax_code%TYPE       DEFAULT NULL; -- 税コード
    lv_bill_cust_code               hz_cust_accounts.account_number%TYPE DEFAULT NULL; -- 請求先顧客コード
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
    ln_selling_amt                  NUMBER         DEFAULT 0;      --算出した売上金額
    ln_selling_amt_no_tax           NUMBER         DEFAULT 0;      --算出した売上金額(税抜き)
    lv_store_delivery_date          VARCHAR2(10)   DEFAULT NULL;   --店舗納品日(YYYY/MM/DD変換後)
    lb_retcode                      BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- ==================================================================================
    -- 商品コードを品目コードに変換
    -- ==================================================================================
    CURSOR get_item_code_cur
    IS
      SELECT  msib.inventory_item_id           AS inventory_item_id             --品目ID
            , msib.segment1                    AS item_code                     --品目コード
            , msib.customer_order_enabled_flag AS customer_order_enabled_flag   --顧客受注可能フラグ
            , iimb.attribute26                 AS selling_type                  --売上対象区分
            , iimb.attribute11                 AS case_qty                      --ケース入数
      FROM    mtl_system_items_b   msib   --品目マスタ
            , ic_item_mst_b        iimb   --OPM品目マスタ
            , xxcmm_system_items_b xsib   --品目マスタアドオン
      WHERE   msib.segment1         = xsib.item_code
      AND     msib.segment1         = iimb.item_no
      AND     xsib.case_jan_code    = iv_goods_code_2
      AND     msib.organization_id  = gn_organization_id;
    -- =======================
    -- ローカルレコード
    -- =======================
    get_item_code_rec  get_item_code_cur%ROWTYPE;
    -- =======================
    -- ローカル例外
    -- =======================
    chk_data_expt  EXCEPTION;   --データチェックエラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** レコード型に値をセット(原価金額(出荷)) ***
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    ot_from_cust_rec.shipment_cost_amt := in_shipment_cost_amt;
--    ot_to_cust_rec.shipment_cost_amt   := in_shipment_cost_amt;
-- 2009/12/03 Ver.1.10 [E_本稼動_00180] SCS S.Moriyama UPD START
--    ot_from_cust_rec.order_cost_amt := in_order_cost_amt;
    ot_from_cust_rec.order_cost_amt := in_order_cost_amt * -1;
-- 2009/12/03 Ver.1.10 [E_本稼動_00180] SCS S.Moriyama UPD END
    ot_to_cust_rec.order_cost_amt   := in_order_cost_amt;
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    -- *** レコード型に値をセット(商品コード) ***
    ot_from_cust_rec.goods_code := iv_goods_code_2;
    ot_to_cust_rec.goods_code   := iv_goods_code_2;
    -- =============================================================================
    -- 1.必須入力項目のチェック(①店舗納品日)
    -- =============================================================================
    IF ( id_store_delivery_date IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10373
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => id_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- *** レコード型に値をセット(売上計上日) ***
    ot_from_cust_rec.selling_date := id_store_delivery_date;
    ot_to_cust_rec.selling_date   := id_store_delivery_date;
    -- *** YYYY/MM/DD型に変換 ***
    lv_store_delivery_date := TO_CHAR ( id_store_delivery_date, cv_date_format );
    -- =============================================================================
    -- 1.必須入力項目のチェック(②伝票番号)
    -- =============================================================================
    IF (   ( iv_slip_no IS NULL )
        OR ( iv_slip_no = cv_0  )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10374
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- =============================================================================
    -- 1.必須入力項目のチェック(③行No)
    -- =============================================================================
    IF (   ( in_line_no IS NULL )
        OR ( in_line_no = cn_0  )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10375
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- =============================================================================
    -- 1.必須入力項目のチェック(④EDIチェーン店コード)
    -- =============================================================================
    IF ( iv_edi_chain_store_code IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10376
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no 
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- *** レコード型に値をセット(EDIチェーン店コード) ***
    ot_from_cust_rec.edi_chain_store_code := iv_edi_chain_store_code;
    ot_to_cust_rec.edi_chain_store_code   := iv_edi_chain_store_code;
    -- =============================================================================
    -- 1.必須入力項目のチェック(⑤納入先センターコード)
    -- =============================================================================
    IF ( iv_delivery_to_center_code IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10377
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no 
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
     -- *** レコード型に値をセット(納入先センターコード) ***
    ot_from_cust_rec.delivery_to_center_code := iv_delivery_to_center_code;
    ot_to_cust_rec.delivery_to_center_code   := iv_delivery_to_center_code;
     -- =============================================================================
    -- 1.必須入力項目のチェック(⑥店コード)
    -- =============================================================================
    IF ( iv_store_code IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10378
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no 
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
     -- *** レコード型に値をセット(店コード) ***
    ot_from_cust_rec.store_code := iv_store_code;
    ot_to_cust_rec.store_code   := iv_store_code;
    -- =============================================================================
    -- 1.必須入力項目のチェック(⑦数量)
    -- =============================================================================
    IF (   ( in_order_qty_sum IS NULL )
        OR ( in_order_qty_sum = cn_0  )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10379
                , iv_token_name1  => cv_token_delivery_date
                , iv_token_value1 => lv_store_delivery_date
                , iv_token_name2  => cv_token_slip_no
                , iv_token_value2 => iv_slip_no
                , iv_token_name3  => cv_token_line_no
                , iv_token_value3 => in_line_no 
                , iv_token_name4  => cv_token_edi_chain_code
                , iv_token_value4 => iv_edi_chain_store_code
                , iv_token_name5  => cv_token_center_code
                , iv_token_value5 => iv_delivery_to_center_code
                , iv_token_name6  => cv_token_store_code
                , iv_token_value6 => iv_store_code
                , iv_token_name7  => cv_token_qty
                , iv_token_value7 => in_order_qty_sum
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- =============================================================================
    -- 2.B-2で取得した納入先センターコードを使用し、 売上振替元顧客コードの変換
    -- =============================================================================
    get_cust_code(
      ov_errbuf               => lv_errbuf                    --エラーメッセージ
    , ov_retcode              => lv_retcode                   --リターンコード
    , ov_errmsg               => lv_errmsg                    --ユーザーエラーメッセージ
    , iv_message_code         => cv_message_10076             --メッセージコード
    , iv_edi_chain_store_code => iv_edi_chain_store_code      --EDIチェーン店コード
    , iv_code                 => iv_delivery_to_center_code   --納入先センターコード
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , in_shipment_unit_price  => in_shipment_unit_price       --納品単価
    , in_order_unit_price     => in_order_unit_price          --納品単価
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD START
    , id_store_delivery_date  => id_store_delivery_date       --店舗納品日
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD END
    , iv_token                => cv_token_center_code         --トークン名
    , ov_sale_base_code       => lv_sale_base_code            --拠点コード
    , ov_account_number       => lv_from_account_number       --顧客コード
    , ov_sales_stuff_code     => lv_sales_stuff_code          --担当営業コード
    , ov_business_low_type    => lv_business_low_type         --顧客業態区分
    , on_price_list_id        => ln_price_list_id             --価格表ID
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama ADD START
    , ov_account_name         => lt_account_name              --顧客名
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama ADD END
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE chk_data_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama ADD START
    ELSE
      -- =============================================================================
      -- EDIに納品単価が未設定であり振替元顧客に価格表が設定されていない場合はエラーとする
      -- =============================================================================
      IF ( (   ( in_order_unit_price IS NULL )
            OR ( in_order_unit_price = cn_0  )
           )
           AND ( ln_price_list_id IS NULL )
         ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10095
                  , iv_token_name1  => cv_token_customer_code
                  , iv_token_value1 => lv_from_account_number
                  , iv_token_name2  => cv_token_customer_name
                  , iv_token_value2 => lt_account_name
                  , iv_token_name3  => cv_token_tanto_loc_code
                  , iv_token_value3 => lv_sale_base_code
                  , iv_token_name4  => cv_token_tanto_code
                  , iv_token_value4 => lv_sales_stuff_code
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE chk_data_expt;
      END IF;
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama ADD END
    END IF;
    -- *** レコード型に値をセット ***
    ot_from_cust_rec.base_code              := lv_sale_base_code;         --拠点コード
    ot_from_cust_rec.cust_code              := lv_from_account_number;    --顧客コード
    ot_from_cust_rec.selling_emp_code       := lv_sales_stuff_code;       --担当営業コード
    ot_from_cust_rec.cust_state_type        := lv_business_low_type;      --顧客業態区分
    ot_from_cust_rec.selling_from_base_code := lv_sale_base_code;         --売上振替元拠点コード
    ot_from_cust_rec.selling_from_cust_code := lv_from_account_number;    --売上振替元顧客コード
    ot_to_cust_rec.selling_from_base_code   := lv_sale_base_code;         --売上振替元拠点コード
    ot_to_cust_rec.selling_from_cust_code   := lv_from_account_number;    --売上振替元顧客コード
    -- =============================================================================
    -- 3.B-2で取得した店コードを使用して、売上振替先顧客コードの変換
    -- =============================================================================
    get_cust_code(
      ov_errbuf               => lv_errbuf                    --エラーメッセージ
    , ov_retcode              => lv_retcode                   --リターンコード
    , ov_errmsg               => lv_errmsg                    --ユーザーエラーメッセージ
    , iv_message_code         => cv_message_10077             --メッセージコード
    , iv_edi_chain_store_code => iv_edi_chain_store_code      --EDIチェーン店コード
    , iv_code                 => iv_store_code                --店コード
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    , in_shipment_unit_price  => in_shipment_unit_price       --納品単価
    , in_order_unit_price     => in_order_unit_price          --納品単価
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD START
    , id_store_delivery_date  => id_store_delivery_date       --店舗納品日
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD END
    , iv_token                => cv_token_store_code          --トークン名
    , ov_sale_base_code       => lv_sale_base_code            --拠点コード
    , ov_account_number       => lv_to_account_number         --顧客コード
    , ov_sales_stuff_code     => lv_sales_stuff_code          --担当営業コード
    , ov_business_low_type    => lv_business_low_type         --顧客業態区分
-- 2010/01/07 Ver.1.11 [E_本稼動_00180] SCS S.Moriyama UPD START
--    , on_price_list_id        => ln_price_list_id             --価格表ID
    , on_price_list_id        => lt_price_list_id_dummy       --価格表ID（振替先顧客格納用ダミー）
    , ov_account_name         => lt_account_name              --顧客名
-- 2010/01/07 Ver.1.11 [E_本稼動_00180] SCS S.Moriyama UPD END
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE chk_data_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- *** レコード型に値をセット ***
    ot_to_cust_rec.base_code        := lv_sale_base_code;        --拠点コード
    ot_to_cust_rec.cust_code        := lv_to_account_number;     --顧客コード
    ot_to_cust_rec.selling_emp_code := lv_sales_stuff_code;      --担当営業コード
    ot_to_cust_rec.cust_state_type  := lv_business_low_type;     --顧客業態区分
    -- =============================================================================
    -- 4.商品コードの変換
    -- =============================================================================
    -- ===========================================
    -- (1)EDI連携品目コード区分取得
    -- ===========================================
    BEGIN
      SELECT  xca2.edi_item_code_div AS edi_item_code_div
      INTO    lv_edi_item_code_div
      FROM    hz_cust_accounts    hca1       --顧客マスタ
            , xxcmm_cust_accounts xca1       --顧客追加情報
            , hz_cust_accounts    hca2       --EDIチェーン店マスタ(顧客マスタ)
            , xxcmm_cust_accounts xca2       --EDIチェーン店マスタ追加情報(顧客追加情報)
            , hz_parties          hp         --パーティマスタ
      WHERE   hca1.account_number       = lv_to_account_number
      AND     hp.party_id               = hca1.party_id
      AND     hca1.customer_class_code  = cv_10
      AND     hca1.cust_account_id      = xca1.customer_id
-- Start 2009/07/13 Ver_1.6 0000514 M.Hiruta REPAIR
--      AND     hp.duns_number_c          = cv_40
      AND     hp.duns_number_c         IN( cv_30 , cv_40 , cv_50 )
-- End   2009/07/13 Ver_1.6 0000514 M.Hiruta REPAIR
      AND     xca1.selling_transfer_div = cv_1
      AND     xca1.chain_store_code     = xca2.edi_chain_code
      AND     hca2.cust_account_id      = xca2.customer_id
      AND     hca2.customer_class_code  = cv_18;
    EXCEPTION
      -- ==================================================================================
      -- EDI連携品目コード区分が取得できなかった場合、例外処理
      -- ==================================================================================
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10073
                  , iv_token_name1  => cv_token_edi_chain_code
                  , iv_token_value1 => iv_edi_chain_store_code
                  , iv_token_name2  => cv_token_customer_code
                  , iv_token_value2 => lv_to_account_number
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE chk_data_expt;
    END;
    -- ==================================================================================
    -- EDI連携品目コード区分が'1'(顧客品目)または、'2'(JANコード)以外の場合、例外処理
    -- ==================================================================================
    IF NOT(   ( lv_edi_item_code_div = cv_1 )
           OR ( lv_edi_item_code_div = cv_2 )
          ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10073
                , iv_token_name1  => cv_token_edi_chain_code
                , iv_token_value1 => iv_edi_chain_store_code
                , iv_token_name2  => cv_token_customer_code
                , iv_token_value2 => lv_to_account_number
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- ==================================================================================
    -- (2)上記で取得したEDI連携品目コード区分 = '2'(JANコード)の場合、
    --    商品コードを品目コードに変換
    -- ==================================================================================
    IF ( lv_edi_item_code_div = cv_2 ) THEN
      BEGIN
        SELECT  msib.inventory_item_id           AS inventory_item_id             --品目ID
              , msib.segment1                    AS item_code                     --品目コード
              , msib.customer_order_enabled_flag AS customer_order_enabled_flag   --顧客受注可能フラグ
              , iimb.attribute26                 AS selling_type                  --売上対象区分
              , msib.primary_unit_of_measure     AS primary_unit_of_measure       --単位
        INTO    ln_item_id
              , lv_item_code
              , lv_customer_order_enabled_flag
              , lv_selling_type
              , lv_unit_type
        FROM    mtl_system_items_b msib    --品目マスタ
              , ic_item_mst_b      iimb    --OPM品目マスタ
        WHERE   msib.segment1         = iimb.item_no
        AND     iimb.attribute21      = iv_goods_code_2
        AND     msib.organization_id  = gn_organization_id;
        -- ==================================================================================
        -- 単位、数量を設定
        -- ==================================================================================
        lv_unit_type := lv_unit_type;
        ln_qty       := in_order_qty_sum;
      EXCEPTION
        -- ==================================================================================
        -- (3)上記で取得したEDI連携品目コード区分 = '2'(JANコード) のとき、かつ
        --    上記で品目コードが変換できなかった場合、商品コードを品目コードに変換
        -- ==================================================================================
        WHEN NO_DATA_FOUND THEN
          OPEN get_item_code_cur;
          <<cur_loop>>
          LOOP
            FETCH get_item_code_cur INTO get_item_code_rec;
            EXIT WHEN get_item_code_cur%NOTFOUND;
            -- *** 取得した値をローカル変数に格納 ***
            ln_item_id                     := get_item_code_rec.inventory_item_id;             --品目ID
            lv_item_code                   := get_item_code_rec.item_code;                     --品目コード
            lv_customer_order_enabled_flag := get_item_code_rec.customer_order_enabled_flag;   --顧客受注可能フラグ
            lv_selling_type                := get_item_code_rec.selling_type;                  --売上対象区分
            ln_case_qty                    := get_item_code_rec.case_qty;                      --ケース入数
            -- ==================================================================================
            -- 単位、数量を設定
            -- ==================================================================================
            lv_unit_type := gv_case_uom;
            ln_qty       := in_order_qty_sum * ln_case_qty;
          END LOOP cur_loop;
          CLOSE get_item_code_cur;
          -- ==================================================================================
          -- 商品コードの変換に失敗した場合、例外処理
          -- ==================================================================================
          IF ( lv_item_code IS NULL ) THEN
            lv_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_name
                      , iv_name         => cv_message_10079
                      , iv_token_name1  => cv_token_edi_item_code_type
                      , iv_token_value1 => lv_edi_item_code_div
                      , iv_token_name2  => cv_token_customer_code
                      , iv_token_value2 => lv_to_account_number
                      , iv_token_name3  => cv_token_shohin_code
                      , iv_token_value3 => iv_goods_code_2
                      , iv_token_name4  => cv_token_org_id
                      , iv_token_value4 => gn_organization_id
                      );
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which    => FND_FILE.OUTPUT   --出力区分
                          , iv_message  => lv_msg            --メッセージ
                          , in_new_line => 0                 --改行
                          );
            RAISE chk_data_expt;
          END IF;
      END;
    END IF;
    -- ==================================================================================
    -- 上記で取得した顧客受注可能フラグが'Y'(受注可能)以外の場合、例外処理
    -- ==================================================================================
    IF NOT( lv_customer_order_enabled_flag = cv_flag_y ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10380
                , iv_token_name1  => cv_token_item_code
                , iv_token_value1 => lv_item_code
                , iv_token_name2  => cv_token_cust_order_e_flag
                , iv_token_value2 => lv_customer_order_enabled_flag
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- ==================================================================================
    -- 上記で取得した売上対象区分が'1'以外の場合、例外処理
    -- ==================================================================================
    IF NOT( lv_selling_type = cv_1 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10083
                , iv_token_name1  => cv_token_item_code
                , iv_token_value1 => lv_item_code
                , iv_token_name2  => cv_token_selling_type
                , iv_token_value2 => lv_selling_type
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- ==================================================================================
    -- (4)上記で取得したEDI連携品目コード区分 = '1'(顧客品目)の場合
    --    商品コードを品目コードに変換
    -- ==================================================================================
    IF ( lv_edi_item_code_div = cv_1 ) THEN
      BEGIN
        SELECT  mcix.inventory_item_id           AS inventory_item_id             --品目ID
              , msib.segment1                    AS item_code                     --品目コード
              , mci.attribute1                   AS attribute1                    --単位
              , msib.customer_order_enabled_flag AS customer_order_enabled_flag   --顧客受注可能フラグ
              , iimb.attribute26                 AS selling_type                  --売上対象区分
        INTO    ln_item_id
              , lv_item_code
              , lv_unit_type
              , lv_customer_order_enabled_flag
              , lv_selling_type
        FROM    mtl_customer_items      mci    --顧客品目
              , mtl_customer_item_xrefs mcix   --顧客品目相互参照
              , hz_cust_accounts        hca    --EDIチェーン店マスタ(顧客マスタ)
              , xxcmm_cust_accounts     xca    --EDIチェーン店マスタ追加情報(顧客マスタ追加情報)
              , mtl_system_items_b      msib   --品目マスタ
              , hz_parties              hp     --パーティマスタ
              , ic_item_mst_b           iimb   --OPM品目マスタ
        WHERE   mci.customer_item_id     = mcix.customer_item_id
        AND     mci.customer_id          = hca.cust_account_id
        AND     hca.cust_account_id      = xca.customer_id
        AND     hp.party_id              = hca.party_id
        AND     xca.edi_chain_code       = iv_edi_chain_store_code
        AND     hp.duns_number_c         = cv_99
        AND     hca.customer_class_code  = cv_18
        AND     mci.inactive_flag        = cv_flag_n
        AND     mcix.inactive_flag       = cv_flag_n
        AND     mcix.inventory_item_id   = msib.inventory_item_id
        AND     mci.customer_item_number = iv_goods_code_2
        AND     msib.segment1            = iimb.item_no
        AND     msib.organization_id     = gn_organization_id;
        -- =============================================================================
        -- 単位、数量を設定
        -- =============================================================================
        lv_unit_type := lv_unit_type;
        ln_qty       := in_order_qty_sum;
      EXCEPTION
        -- *** 上記で商品コードの変換に失敗した場合、例外処理 ***
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10079
                    , iv_token_name1  => cv_token_edi_item_code_type
                    , iv_token_value1 => lv_edi_item_code_div
                    , iv_token_name2  => cv_token_customer_code
                    , iv_token_value2 => lv_to_account_number
                    , iv_token_name3  => cv_token_shohin_code
                    , iv_token_value3 => iv_goods_code_2
                    , iv_token_name4  => cv_token_org_id
                    , iv_token_value4 => gn_organization_id
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --出力区分
                        , iv_message  => lv_msg            --メッセージ
                        , in_new_line => 0                 --改行
                        );
          RAISE chk_data_expt;
      END;
      -- ==================================================================================
      -- 上記で取得した顧客受注可能フラグが'Y'(受注可能)以外の場合、例外処理
      -- ==================================================================================
      IF NOT( lv_customer_order_enabled_flag = cv_flag_y ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10380
                  , iv_token_name1  => cv_token_item_code
                  , iv_token_value1 => lv_item_code
                  , iv_token_name2  => cv_token_cust_order_e_flag
                  , iv_token_value2 => lv_customer_order_enabled_flag
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE chk_data_expt;
      END IF;
      -- ==================================================================================
      -- 上記で取得した売上対象区分が'1'以外の場合、例外処理
      -- ==================================================================================
      IF NOT( lv_selling_type = cv_1 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10083
                  , iv_token_name1  => cv_token_item_code
                  , iv_token_value1 => lv_item_code
                  , iv_token_name2  => cv_token_selling_type
                  , iv_token_value2 => lv_selling_type
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE chk_data_expt;
      END IF;
    END IF;
    -- *** レコード型に値をセット(品目コード) ***
    ot_from_cust_rec.item_code := lv_item_code;
    ot_to_cust_rec.item_code   := lv_item_code;
    -- *** レコード型に値をセット(数量) ***
    ot_from_cust_rec.qty := ln_qty * -1;
    ot_to_cust_rec.qty   := ln_qty;
    -- =============================================================================
    -- 5.単位のチェック
    -- =============================================================================
    IF ( lv_unit_type IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10082
                , iv_token_name1  => cv_token_edi_chain_code
                , iv_token_value1 => iv_edi_chain_store_code
                , iv_token_name2  => cv_token_store_code
                , iv_token_value2 => iv_store_code
                , iv_token_name3  => cv_token_delivery_date
                , iv_token_value3 => lv_store_delivery_date
                , iv_token_name4  => cv_token_shohin_code
                , iv_token_value4 => iv_goods_code_2
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE chk_data_expt;
    END IF;
    -- *** レコード型に値をセット(単位) ***
    ot_from_cust_rec.unit_type := lv_unit_type;
    ot_to_cust_rec.unit_type   := lv_unit_type;
    -- =============================================================================
    -- 6.納品単価の取得
    -- =============================================================================
    -- *** B-2で取得した納品単価を設定 ***
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--    ln_unit_price := in_shipment_unit_price;
    ln_unit_price := in_order_unit_price;
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
    -- =============================================================================
    -- (1)B-2で取得した納品単価がNULL、または、0の場合、共通関数より単価を取得
    -- =============================================================================
    IF (   ( ln_unit_price IS NULL )
        OR ( ln_unit_price = cn_0  )
       ) THEN
      ln_unit_price := xxcos_common2_pkg.get_unit_price(
                         in_inventory_item_id    => ln_item_id
                       , in_price_list_header_id => ln_price_list_id
                       , iv_uom_code             => lv_unit_type
                       );
      -- *** 単価を取得できなかった場合 ***
      IF ( NVL ( ln_unit_price , 0 ) < cn_0 ) THEN
        -- *** 価格表名の取得 ***
        SELECT qlht.name AS price_list_name  --価格表名
        INTO   lv_price_list_name
        FROM   qp_list_headers_tl  qlht      --価格表ヘッダ
        WHERE  qlht.list_header_id = ln_price_list_id
        AND    qlht.language       = USERENV('LANG');
--
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10085
                  , iv_token_name1  => cv_token_edi_chain_code
                  , iv_token_value1 => iv_edi_chain_store_code
                  , iv_token_name2  => cv_token_item_code
                  , iv_token_value2 => lv_item_code
                  , iv_token_name3  => cv_token_price_list_name
                  , iv_token_value3 => lv_price_list_name
                  , iv_token_name4  => cv_token_unit_price_code
                  , iv_token_value4 => lv_unit_type
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE chk_data_expt;
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama ADD START
      -- *** 価格表に該当品目が登録されていない場合 ***
      ELSIF ( NVL ( ln_unit_price , 0 ) = cn_0 ) THEN
        -- *** 価格表名の取得 ***
        SELECT qlht.name AS price_list_name  --価格表名
        INTO   lv_price_list_name
        FROM   qp_list_headers_tl  qlht      --価格表ヘッダ
        WHERE  qlht.list_header_id = ln_price_list_id
        AND    qlht.language       = USERENV('LANG');
--
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10473
                  , iv_token_name1  => cv_token_price_list_name
                  , iv_token_value1 => lv_price_list_name
                  , iv_token_name2  => cv_token_item_code
                  , iv_token_value2 => lv_item_code
                  , iv_token_name3  => cv_token_unit_price_code
                  , iv_token_value3 => lv_unit_type
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE chk_data_expt;
-- 2010/01/07 Ver.1.11 [E_本稼動_00834] SCS S.Moriyama ADD END
      END IF;
    END IF;
    -- *** レコード型に値をセット(納品単価) ***
    ot_from_cust_rec.delivery_unit_price := ln_unit_price;
    ot_to_cust_rec.delivery_unit_price   := ln_unit_price;
    -- =============================================================================
    -- 7.営業原価(品目単位)の取得
    -- =============================================================================
    BEGIN
      SELECT iimb.attribute8 AS cost_item_unit_type
      INTO   lv_cost_item_unit_type
      FROM   ic_item_mst_b iimb     --OPM品目マスタ
      WHERE  iimb.item_no     = lv_item_code
      AND    iimb.attribute9 <= TO_CHAR( gd_prdate, cv_date_format );
      -- =============================================================================
      -- 営業原価を算出
      -- =============================================================================
      ln_trading_cost := TO_NUMBER( lv_cost_item_unit_type ) * ln_qty;
    EXCEPTION
      -- *** 上記で営業原価(品目単位)が取得できなかった場合、例外処理 ***
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10086
                  , iv_token_name1  => cv_token_item_code
                  , iv_token_value1 => lv_item_code
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE chk_data_expt;
    END;
    -- *** レコード型に値をセット(営業原価) ***
    ot_from_cust_rec.trading_cost := ln_trading_cost * -1;
    ot_to_cust_rec.trading_cost   := ln_trading_cost;
    -- =============================================================================
    -- 8.消費税の計算
    -- =============================================================================
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR START
--    -- =========================================
--    -- (1)消費税区分を取得
--    -- =========================================
--    BEGIN
--      SELECT  xca.tax_div AS tax_div
--      INTO    lv_tax_type
--      FROM    hz_cust_accounts    hca    --顧客マスタ
--            , xxcmm_cust_accounts xca    --顧客追加情報
--      WHERE   hca.account_number  = lv_to_account_number
--      AND     hca.cust_account_id = xca.customer_id;
    -- =========================================
    -- (1)消費税区分を取得
    -- =========================================
    BEGIN
      SELECT bill_hca.account_number    AS bill_cust_code
           , bill_xca.tax_div           AS tax_div
           , bill_xtv.tax_rate          AS tax_rate
           , bill_xtv.tax_code          AS tax_code
      INTO lv_bill_cust_code
         , lv_tax_type
         , ln_tax_rate
         , lv_tax_code
      FROM hz_cust_accounts        ship_hca
         , hz_cust_acct_sites      ship_hcas
         , hz_cust_site_uses       ship_hcsu
         , hz_cust_site_uses       bill_hcsu
         , hz_cust_acct_sites      bill_hcas
         , hz_cust_accounts        bill_hca
         , xxcmm_cust_accounts     bill_xca
         , xxcos_tax_v             bill_xtv
      WHERE ship_hca.account_number          = lv_from_account_number
        AND ship_hca.cust_account_id         = ship_hcas.cust_account_id
        AND ship_hcas.cust_acct_site_id      = ship_hcsu.cust_acct_site_id
        AND ship_hcsu.site_use_code          = cv_site_use_code_ship
        AND ship_hcsu.bill_to_site_use_id    = bill_hcsu.site_use_id
        AND bill_hcsu.site_use_code          = cv_site_use_code_bill
        AND bill_hcsu.cust_acct_site_id      = bill_hcas.cust_acct_site_id
        AND bill_hcas.cust_account_id        = bill_hca.cust_account_id
        AND bill_hca.cust_account_id         = bill_xca.customer_id
        AND bill_xca.tax_div                 = bill_xtv.tax_class
        AND bill_xtv.set_of_books_id         = gn_set_of_books_id
        AND id_store_delivery_date     BETWEEN NVL( bill_xtv.start_date_active, id_store_delivery_date )
                                           AND NVL( bill_xtv.end_date_active  , id_store_delivery_date )
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD START
        AND bill_hcsu.status                 = cv_flag_a
        AND ship_hcsu.status                 = cv_flag_a
-- 2010/01/28 Ver.1.12 [E_本稼動_01297] SCS Y.Kuboshima ADD END
      ;
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi REPAIR END
--
      IF ( lv_tax_type IS NULL ) THEN
        RAISE NO_DATA_FOUND;
      END IF;
--
      IF NOT(   ( lv_tax_type = cv_1 )
             OR ( lv_tax_type = cv_2 )
             OR ( lv_tax_type = cv_3 )
             OR ( lv_tax_type = cv_4 )
            ) THEN
        RAISE NO_DATA_FOUND;
      END IF;
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi DELETE START
--      -- ==================================================================================
--      -- (2)消費税区分 = '2'(内税(伝票課税))、'3'(内税(単価込み))の場合、消費税率を取得
--      -- ==================================================================================
--      IF (   ( lv_tax_type = cv_2 )
--          OR ( lv_tax_type = cv_3 )
--         ) THEN
---- Start 2009/07/29 Ver_1.6 0000514 M.Hiruta REPAIR
----        SELECT  atca.tax_rate AS tax_rate
----        INTO    ln_tax_rate
----        FROM    ap_tax_codes_all  atca     --税コードマスタ
----              , fnd_lookup_values flv      --参照タイプ
----        WHERE   flv.lookup_type  = cv_lookup_type
----        AND     flv.lookup_code  = lv_tax_type
----        AND     flv.enabled_flag = cv_flag_y
----        AND     gd_prdate BETWEEN flv.start_date_active
----                          AND     NVL( flv.end_date_active, gd_prdate )
----        AND     flv.language     = USERENV('LANG')
------ Start 2009/05/19 Ver_1.4 T1_1043 M.Hiruta
----        AND     atca.org_id      = gn_org_id
------ End   2009/05/19 Ver_1.4 T1_1043 M.Hiruta
----        AND     atca.name        = flv.attribute1;
--        SELECT  avtab.tax_rate AS tax_rate
--        INTO    ln_tax_rate
--        FROM    ar_vat_tax_all_b  avtab    --税コードマスタ
--              , fnd_lookup_values flv      --参照タイプ
--        WHERE   flv.lookup_type       = cv_lookup_type
--        AND     flv.lookup_code       = lv_tax_type
--        AND     flv.enabled_flag      = cv_flag_y
--        AND     gd_prdate      BETWEEN flv.start_date_active
--                               AND     NVL( flv.end_date_active, gd_prdate )
--        AND     flv.language          = USERENV('LANG')
--        AND     avtab.enabled_flag    = cv_flag_y
--        AND     gd_prdate      BETWEEN avtab.start_date
--                               AND     NVL( avtab.end_date, gd_prdate )
--        AND     avtab.set_of_books_id = gn_set_of_books_id
--        AND     avtab.org_id          = gn_org_id
--        AND     avtab.tax_code        = flv.attribute1;
---- End   2009/07/29 Ver_1.6 0000514 M.Hiruta REPAIR
--      END IF;
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi DELETE END
    EXCEPTION
      -- *** 上記で消費税区分、または、消費税率が取得できなかった場合、例外処理 ***
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10013
                  , iv_token_name1  => cv_token_customer_code
                  , iv_token_value1 => lv_to_account_number
                  , iv_token_name2  => cv_token_tax_type
                  , iv_token_value2 => lv_tax_type
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        RAISE chk_data_expt;
    END;
    -- =============================================================================
    -- (3)消費税を計算
    -- =============================================================================
    -- =========================================================
    -- 消費税区分が'1'(外税)、'4'(対象外)の場合
    -- =========================================================
    IF (   ( lv_tax_type = cv_1 )
        OR ( lv_tax_type = cv_4 )
       ) THEN
      ln_selling_amt        := ( ln_qty * ln_unit_price );   --売上金額
      ln_selling_amt_no_tax := ln_selling_amt;               --売上金額(税抜き)
    -- =========================================================
    -- 消費税区分が'2'(内税(伝票))、'3'(内税(単価)) の場合
    -- =========================================================
    ELSIF (   ( lv_tax_type = cv_2 )
           OR ( lv_tax_type = cv_3 )
          ) THEN
      ln_selling_amt        := ( ln_qty * ln_unit_price );                                     --売上金額
      ln_selling_amt_no_tax := ROUND( ln_selling_amt / ( cn_1 + ln_tax_rate / cn_100 ), 0 );   --売上金額(税抜き)
    END IF;
    -- *** レコード型に値をセット(売上金額) ***
    ot_from_cust_rec.selling_amt := ln_selling_amt * -1;
    ot_to_cust_rec.selling_amt   := ln_selling_amt;
    -- *** レコード型に値をセット(売上金額(税抜)) ***
    ot_from_cust_rec.selling_amt_no_tax := ln_selling_amt_no_tax * -1;
    ot_to_cust_rec.selling_amt_no_tax   := ln_selling_amt_no_tax;
    -- *** レコード型に値をセット(売上金額(消費税区分)) ***
    ot_from_cust_rec.tax_type := lv_tax_type;
    ot_to_cust_rec.tax_type   := lv_tax_type;
    -- *** レコード型に値をセット(売上金額(消費税率)) ***
    ot_from_cust_rec.tax_rate := ln_tax_rate;
    ot_to_cust_rec.tax_rate   := ln_tax_rate;
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD START
    -- *** レコード型に値をセット(請求先顧客コード) ***
    ot_from_cust_rec.bill_cust_code := lv_bill_cust_code;
    ot_to_cust_rec.bill_cust_code   := lv_bill_cust_code;
    -- *** レコード型に値をセット(税コード) ***
    ot_from_cust_rec.tax_code := lv_tax_code;
    ot_to_cust_rec.tax_code   := lv_tax_code;
-- 2009/10/19 Ver.1.9 [障害E_T3_00631] SCS K.Yamaguchi ADD END
  EXCEPTION
    -- *** データチェックエラー ***
    WHEN chk_data_expt THEN
      ov_retcode  := cv_status_warn;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : get_edi_wk_tab
   * Description      : EDIワークテーブル抽出(B-2)
   ***********************************************************************************/
  PROCEDURE get_edi_wk_tab(
    ov_errbuf         OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode        OUT VARCHAR2    --リターン・コード
  , ov_errmsg         OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_file_name      IN  VARCHAR2    --ファイル名
  , iv_execution_type IN  VARCHAR2)   --実行区分
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(15) := 'get_edi_wk_tab';    --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;    --エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;    --リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;    --ユーザー・エラー・メッセージ
    lv_msg      VARCHAR2(5000) DEFAULT NULL;    --メッセージ取得変数
    lb_retcode  BOOLEAN        DEFAULT NULL;    --メッセージ出力の戻り値
    -- =======================
    -- ローカル･カーソル
    -- =======================
    CURSOR get_wk_edi_cur
    IS
      SELECT    xwest.edi_selling_trns_id     AS edi_selling_trns_id       --内部ID
              , xwest.slip_no                 AS slip_no                   --伝票番号
              , xwest.line_no                 AS line_no                   --行No
              , xwest.store_delivery_date     AS store_delivery_date       --店舗納品日
-- Start 2009/06/08 Ver_1.5 T1_1354 M.Hiruta
--              , xwest.edi_chain_store_code    AS edi_chain_store_code      --EDIチェーン店コード
--              , xwest.delivery_to_center_code AS delivery_to_center_code   --納入先センターコード
--              , xwest.store_code              AS store_code                --店コード
--              , xwest.goods_code_2            AS goods_code_2              --商品コード2
              , LTRIM( xwest.edi_chain_store_code )    AS edi_chain_store_code      --EDIチェーン店コード
              , LTRIM( xwest.delivery_to_center_code ) AS delivery_to_center_code   --納入先センターコード
              , LTRIM( xwest.store_code )              AS store_code                --店コード
              , LTRIM( xwest.goods_code_2 )            AS goods_code_2              --商品コード2
-- End   2009/06/08 Ver_1.5 T1_1354 M.Hiruta
              , xwest.order_qty_sum           AS order_qty_sum             --数量(発注数量(合計、バラ))
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--              , xwest.shipment_unit_price     AS shipment_unit_price       --納品単価(原単価(出荷))
--              , xwest.shipment_cost_amt       AS shipment_cost_amt         --原価金額(出荷)
              , xwest.order_unit_price        AS order_unit_price          --納品単価(原単価(発注))
              , xwest.order_cost_amt          AS order_cost_amt            --原価金額(発注)
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      FROM      xxcok_wk_edi_selling_trns xwest
      WHERE     xwest.status = DECODE( iv_execution_type,
                                       cv_1, cv_0,
                                       cv_2 )
      AND       iv_file_name = xwest.if_file_name
-- 2010/02/18 Ver.1.13 [障害E_本稼動_00911] SCS S.Moriyama ADD START
      AND       xwest.store_delivery_date <= gd_prdate
-- 2010/02/18 Ver.1.13 [障害E_本稼動_00911] SCS S.Moriyama ADD END
      ORDER BY  store_delivery_date     ASC
              , slip_no                 ASC
              , line_no                 ASC
              , edi_chain_store_code    ASC
              , delivery_to_center_code ASC
              , store_code              ASC;
    -- =======================
    -- ローカルTABLE型
    -- =======================
    TYPE tab_type IS TABLE OF get_wk_edi_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_get_wk_edi_cur_tab  tab_type;
    -- =======================
    -- ローカル例外
    -- =======================
    get_edi_tbl_expt   EXCEPTION;   --EDI売上実績振替情報抽出エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** カーソルオープン ***
    OPEN  get_wk_edi_cur;
    FETCH get_wk_edi_cur BULK COLLECT INTO l_get_wk_edi_cur_tab;
    CLOSE get_wk_edi_cur;
    -- *** 対象件数カウント ***
    gn_target_cnt := l_get_wk_edi_cur_tab.COUNT;
    -- *** データが抽出できたか確認 ***
    IF ( gn_target_cnt = cn_0 ) THEN
      RAISE get_edi_tbl_expt;
    END IF;
--
    <<loop_1>>
    FOR ln_idx IN 1 .. l_get_wk_edi_cur_tab.COUNT LOOP
      -- =============================================================================
      -- データチェック(B-3)の呼出し
      -- =============================================================================
      chk_data(
        ov_errbuf                  => lv_errbuf                                          --エラーメッセージ
      , ov_retcode                 => lv_retcode                                         --リターンコード
      , ov_errmsg                  => lv_errmsg                                          --ユーザーエラーメッセージ
      , ot_from_cust_rec           => g_from_cust_rec                                    --レコード型(振替元顧客コード)
      , ot_to_cust_rec             => g_to_cust_rec                                      --レコード型(振替先顧客コード)
      , id_store_delivery_date     => l_get_wk_edi_cur_tab( ln_idx ).store_delivery_date       --店舗納品日
      , iv_slip_no                 => l_get_wk_edi_cur_tab( ln_idx ).slip_no                   --伝票番号
      , in_line_no                 => l_get_wk_edi_cur_tab( ln_idx ).line_no                   --行番号
      , iv_edi_chain_store_code    => l_get_wk_edi_cur_tab( ln_idx ).edi_chain_store_code      --EDIチェーン店コード
      , iv_delivery_to_center_code => l_get_wk_edi_cur_tab( ln_idx ).delivery_to_center_code   --納入先センターコード
      , iv_store_code              => l_get_wk_edi_cur_tab( ln_idx ).store_code                --店コード
      , in_order_qty_sum           => l_get_wk_edi_cur_tab( ln_idx ).order_qty_sum             --数量
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      , in_shipment_unit_price     => l_get_wk_edi_cur_tab( ln_idx ).shipment_unit_price       --納品単価
      , in_order_unit_price        => l_get_wk_edi_cur_tab( ln_idx ).order_unit_price          --納品単価
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      , iv_goods_code_2            => l_get_wk_edi_cur_tab( ln_idx ).goods_code_2              --商品コード2
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--      , in_shipment_cost_amt       => l_get_wk_edi_cur_tab( ln_idx ).shipment_cost_amt         --原価金額(出荷)
      , in_order_cost_amt          => l_get_wk_edi_cur_tab( ln_idx ).order_cost_amt            --原価金額(発注)
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- =============================================================================
      -- 一時表作成(B-4)の呼出し
      -- =============================================================================
      IF ( lv_retcode = cv_status_normal ) THEN
        ins_tmp_tbl(
          ov_errbuf        => lv_errbuf         --エラーメッセージ
        , ov_retcode       => lv_retcode        --リターンコード
        , ov_errmsg        => lv_errmsg         --ユーザーエラーメッセージ
        , it_from_cust_rec => g_from_cust_rec   --レコード型(振替元顧客コード)
        , it_to_cust_rec   => g_to_cust_rec     --レコード型(振替先顧客コード)
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- =============================================================================
        -- EDIワークテーブル更新(正常)(B-8)の呼出し
        -- =============================================================================
        upd_edi_tbl_normal(
          ov_errbuf                  => lv_errbuf                                           --エラーメッセージ
        , ov_retcode                 => lv_retcode                                          --リターンコード
        , ov_errmsg                  => lv_errmsg                                           --ユーザーエラーメッセージ
        , in_edi_selling_info_wk_id  => l_get_wk_edi_cur_tab( ln_idx ).edi_selling_trns_id     --内部ID
        , iv_edi_chain_store_code    => l_get_wk_edi_cur_tab( ln_idx ).edi_chain_store_code    --EDIチェーン店コード
        , iv_delivery_to_center_code => l_get_wk_edi_cur_tab( ln_idx ).delivery_to_center_code --納入先センターコード
        , iv_store_code              => l_get_wk_edi_cur_tab( ln_idx ).store_code              --店コード
        , iv_goods_code              => l_get_wk_edi_cur_tab( ln_idx ).goods_code_2            --商品コード
-- Start 2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
--        , in_delivery_unit_price     => l_get_wk_edi_cur_tab( ln_idx ).shipment_unit_price     --納品単価
        , in_delivery_unit_price     => l_get_wk_edi_cur_tab( ln_idx ).order_unit_price        --納品単価
-- End   2009/08/13 Ver.1.7 0000997 M.Hiruta REPAIR
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      -- =============================================================================
      --  EDIワークテーブル更新(エラー)(B-7)へ遷移
      -- =============================================================================
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        upd_edi_tbl_error(
          ov_errbuf                 => lv_errbuf                                            --エラーメッセージ
        , ov_retcode                => lv_retcode                                           --リターンコード
        , ov_errmsg                 => lv_errmsg                                            --ユーザーエラーメッセージ
        , in_edi_selling_info_wk_id => l_get_wk_edi_cur_tab( ln_idx ).edi_selling_trns_id   --内部ID
        , iv_slip_no                => l_get_wk_edi_cur_tab( ln_idx ).slip_no               --伝票番号
        , in_line_no                => l_get_wk_edi_cur_tab( ln_idx ).line_no               --行No
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP loop_1;
  EXCEPTION
    -- *** 取得に失敗した場合、例外処理 ***
    WHEN get_edi_tbl_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10074
                , iv_token_name1  => cv_token_type
                , iv_token_value1 => iv_execution_type
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_edi_wk_tab;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(B-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf         OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode        OUT VARCHAR2    --リターン・コード
  , ov_errmsg         OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_file_name      IN  VARCHAR2    --ファイル名
  , iv_execution_type IN  VARCHAR2)   --実行区分
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(5) := 'init';    --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg           VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lv_tax_type      VARCHAR2(100)  DEFAULT NULL;   --カスタムプロファイル(課税売上内税消費税区分)
    lv_org_code      VARCHAR2(100)  DEFAULT NULL;   --カスタムプロファイル(在庫組織コード)
    lv_profile_code  VARCHAR2(100)  DEFAULT NULL;   --プロファイル値
    lb_retcode       BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
    -- =======================
    -- ローカル例外
    -- =======================
    init_err_expt     EXCEPTION;   --init内エラー
    get_profile_expt  EXCEPTION;   --プロファイル値取得エラー
    get_process_expt  EXCEPTION;   --業務日付取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.コンカレントプログラム入力項目をメッセージ出力
    -- =============================================================================
        lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00006
              , iv_token_name1  => cv_token_file_name
              , iv_token_value1 => iv_file_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 0                 --改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 0                 --改行
                  );
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00044
              , iv_token_name1  => cv_token_proc_type
              , iv_token_value1 => iv_execution_type
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 1                 --改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 2                 --改行
                  );
    -- =============================================================================
    -- 2.コンカレントプログラム入力項目、実行区分のチェック
    -- =============================================================================
    IF NOT (   ( iv_execution_type = cv_1 )
            OR ( iv_execution_type = cv_2 )
           ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_xxcok_appl_name
                ,iv_name         => cv_message_10072
                ,iv_token_name1  => cv_token_type
                ,iv_token_value1 => iv_execution_type
              );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => FND_FILE.OUTPUT   --出力区分
                      ,iv_message  => lv_msg            --メッセージ
                      ,in_new_line => 0                 --改行
      );
      RAISE init_err_expt;
    END IF;
    -- =============================================================================
    -- 3.カスタム・プロファイル、EDI情報削除期間の取得
    -- =============================================================================
    gv_purge_term := FND_PROFILE.VALUE( cv_purge_term_profile );
--
    IF ( gv_purge_term IS NULL ) THEN
      lv_profile_code := cv_purge_term_profile;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 4.プロファイル、組織IDの取得
    -- =============================================================================
    gn_org_id := FND_PROFILE.VALUE( cv_org_id_profile );
--
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_code := cv_org_id_profile;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 5.カスタム・プロファイル、ケース単位の取得
    -- =============================================================================
    gv_case_uom := FND_PROFILE.VALUE( cv_case_uom_profile );
--
    IF ( gv_case_uom IS NULL ) THEN
      lv_profile_code := cv_case_uom_profile;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 6.カスタム・プロファイル、在庫組織コードの取得
    -- =============================================================================
    lv_org_code := FND_PROFILE.VALUE( cv_org_code_profile );
--
    IF ( lv_org_code IS NULL ) THEN
      lv_profile_code := cv_org_code_profile;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 7.在庫組織IDを取得
    -- =============================================================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                            iv_organization_code => lv_org_code
                          );
--
    IF ( gn_organization_id IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00013
                , iv_token_name1  => cv_token_org_code
                , iv_token_value1 => lv_org_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE init_err_expt;
    END IF;
    -- =============================================================================
    -- 8.業務日付を取得
    -- =============================================================================
    gd_prdate := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_prdate IS NULL ) THEN
      RAISE get_process_expt;
    END IF;
-- Start 2009/07/29 Ver_1.6 0000514 M.Hiruta ADD
    -- =============================================================================
    -- 9.プロファイル、会計帳簿IDの取得
    -- =============================================================================
    gn_set_of_books_id := FND_PROFILE.VALUE( cv_set_of_books_id );
--
    IF ( gn_set_of_books_id IS NULL ) THEN
      lv_profile_code := cv_set_of_books_id;
      RAISE get_profile_expt;
    END IF;
-- End   2009/07/29 Ver_1.6 0000514 M.Hiruta ADD
  EXCEPTION
    -- *** init内エラー ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** プロファイル値取得エラー ***
    WHEN get_profile_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00003
                , iv_token_name1  => cv_token_profile
                , iv_token_value1 => lv_profile_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 業務日付取得エラー ***
    WHEN get_process_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00028
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
    ov_errbuf         OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode        OUT VARCHAR2    --リターン・コード
  , ov_errmsg         OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_file_name      IN  VARCHAR2    --ファイル名
  , iv_execution_type IN  VARCHAR2)   --実行区分
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(10) := 'submain';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode  BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 初期処理(B-1)の呼出し
    -- =============================================================================
    init(
      ov_errbuf         => lv_errbuf           --エラー・メッセージ
    , ov_retcode        => lv_retcode          --リターン・コード
    , ov_errmsg         => lv_errmsg           --ユーザー・エラー・メッセージ
    , iv_file_name      => iv_file_name        --ファイル名
    , iv_execution_type => iv_execution_type   --実行区分
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- EDIワークテーブル抽出(B-2)
    -- =============================================================================
    get_edi_wk_tab(
      ov_errbuf         => lv_errbuf           --エラー・メッセージ
    , ov_retcode        => lv_retcode          --リターン・コード
    , ov_errmsg         => lv_errmsg           --ユーザー・エラー・メッセージ
    , iv_file_name      => iv_file_name        --ファイル名
    , iv_execution_type => iv_execution_type   --実行区分
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- 数量・売上金額の集計(B-5)の呼出し
    -- =============================================================================
    IF ( gn_target_cnt > gn_warn_cnt ) THEN
      get_qty_amt_total(
        ov_errbuf  => lv_errbuf           --エラー・メッセージ
      , ov_retcode => lv_retcode          --リターン・コード
      , ov_errmsg  => lv_errmsg           --ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    -- =============================================================================
    -- EDIワークテーブル削除(B-9)の呼出し
    -- =============================================================================
    del_wk_tbl(
      ov_errbuf  => lv_errbuf    --エラー・メッセージ
    , ov_retcode => lv_retcode   --リターン・コード
    , ov_errmsg  => lv_errmsg    --ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   ***********************************************************************************/
  PROCEDURE main(
    errbuf            OUT VARCHAR2    --エラー・メッセージ
  , retcode           OUT VARCHAR2    --リターン・コード
  , iv_file_name      IN  VARCHAR2    --ファイル名
  , iv_execution_type IN  VARCHAR2)   --実行区分
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(5) := 'main';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg          VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lv_message_code VARCHAR2(5000) DEFAULT NULL;   --メッセージコード
    lb_retcode      BOOLEAN        DEFAULT NULL;   --メッセージ出力の戻り値
--
  BEGIN
    -- =============================================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- =============================================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- =============================================================================
    -- submainの呼出し
    -- =============================================================================
    submain(
      ov_errbuf         => lv_errbuf           --エラー・メッセージ
    , ov_retcode        => lv_retcode          --リターン・コード
    , ov_errmsg         => lv_errmsg           --ユーザー・エラー・メッセージ
    , iv_execution_type => iv_execution_type   --実行区分
    , iv_file_name      => iv_file_name        --ファイル名
    );
    -- =============================================================================
    -- エラー出力
    -- =============================================================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_errmsg         --メッセージ
                    , in_new_line => 1                 --改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      --出力区分
                    , iv_message  => lv_errbuf         --メッセージ
                    , in_new_line => 0                 --改行
                    );
    END IF;
    -- =============================================================================
    -- エラー終了の場合、成功件数、スキップ件数を0件にし、エラー件数を1件にする。
    -- =============================================================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_0;
      gn_warn_cnt   := cn_0;
      gn_error_cnt  := cn_1;
    END IF;
    -- =============================================================================
    -- 警告終了の場合、空行を出力
    -- =============================================================================
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => NULL              --メッセージ
                    , in_new_line => 1                 --改行
                    );
    END IF;
    -- =============================================================================
    -- 対象件数出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90000
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_target_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    -- =============================================================================
    -- 成功件数出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90001
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_normal_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    -- =============================================================================
    -- スキップ件数出力
    -- =============================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      gn_warn_cnt := cn_0;
    END IF;
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90003
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_warn_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    -- =============================================================================
    -- エラー件数出力
    -- =============================================================================
    IF (   ( lv_retcode = cv_status_normal )
        OR ( lv_retcode = cv_status_warn   )
       ) THEN
      gn_error_cnt := cn_0;
    END IF;
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90002
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_error_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 1                   --改行
                  );
    -- =============================================================================
    -- 処理終了メッセージを出力
    -- =============================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_message_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_message_90005;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_message_90006;
    END IF;
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application => cv_xxccp_appl_name
              , iv_name        => lv_message_code
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    -- *** ステータスセット ***
    retcode := lv_retcode;
    -- *** 終了ステータスがエラーの場合はROLLBACK ***
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK007A01C;
/
