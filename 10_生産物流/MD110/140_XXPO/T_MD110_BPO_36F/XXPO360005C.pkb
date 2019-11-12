CREATE OR REPLACE PACKAGE BODY xxpo360005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360005C(body)
 * Description      : 仕入（帳票）
 * MD.050/070       : 仕入（帳票）Issue1.0  (T_MD050_BPO_360)
 *                    代行請求書            (T_MD070_BPO_36F)
 * Version          : 1.24
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_get_in_statement      FUNCTION  : IN句の内容を返します。(vendor_type)
 *  fnc_get_in_statement      FUNCTION  : IN句の内容を返します。(dept_code_type)
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_out_xml               PROCEDURE : XML出力処理
 *  prc_initialize            PROCEDURE : 前処理(F-2)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(F-3-1)
 *  prc_edit_data             PROCEDURE : 取得データ編集(F-3-2)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成
 *  prc_set_param             PROCEDURE : パラメータの取得
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/04    1.0   T.Endou          新規作成
 *  2008/05/09    1.1   T.Endou          発注なし仕入先返品データが抽出されない対応
 *  2008/05/13    1.2   T.Endou          OPM品目情報VIEW参照を削除
 *  2008/05/13    1.3   T.Endou          発注なし仕入先返品のときに使用する単価が不正
 *                                       「単価」から「粉引後単価」に修正
 *  2008/05/14    1.4   T.Endou          セキュリティ要件不具合対応
 *  2008/05/23    1.5   Y.Majikina       数量取得項目の変更。金額計算の不備を修正
 *  2008/05/26    1.6   T.Endou          発注あり仕入先返品の場合は、以下を使用する修正
 *                                       1.返品アドオン.粉引後単価
 *                                       2.返品アドオン.預かり口銭金額
 *                                       3.返品アドオン.賦課金額
 *  2008/05/26    1.7   T.Endou          外部倉庫ユーザーのセキュリティは不要なため削除
 *  2008/06/25    1.8   T.Endou          特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/10/22    1.9   I.Higa           取引先の取得項目が不正（仕入先名⇒正式名）
 *  2008/10/24    1.10  T.Ohashi         T_S_432対応（敬称の付与）
 *  2008/11/04    1.11  Y.Yamamoto       統合障害#471
 *  2008/11/28    1.12  T.Yoshimoto      本番障害#204
 *  2009/01/08    1.13  N.Yoshida        本番障害#970
 *  2009/03/30    1.14  A.Shiina         本番障害#1346
 *  2009/05/26    1.15  T.Yoshimoto      本番障害#1478
 *  2009/06/02    1.16  T.Yoshimoto      本番障害#1516
 *  2009/06/22    1.17  T.Yoshimoto      本番障害#1516(再)※v1.15対応時の障害
 *  2009/08/10    1.18  T.Yoshimoto      本番障害#1596
 *  2009/09/24    1.19  T.Yoshimoto      本番障害#1523
 *  2012/08/16    1.20  T.Makuta         E_本稼動_09898
 *  2013/07/05    1.21  R.Watanabe       E_本稼動_10839
 *  2019/08/30    1.22  Y.Shoji          E_本稼働_15601
 *  2019/10/18    1.23  H.Ishii          E_本稼働_15601
 *  2019/11/12    1.24  H.Ishii          E_本稼働_16036
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XPO360005C';  -- パッケージ名
  gv_print_name             CONSTANT VARCHAR2(20) := '代行請求書';  -- 帳票名
  gv_report_id              CONSTANT VARCHAR2(12) := 'XXPO360005T'; -- 帳票ID
  gd_exec_date              CONSTANT DATE         := SYSDATE;       -- 実施日
--
  gv_org_id                 CONSTANT VARCHAR2(20) := 'ORG_ID'; -- 営業単位
-- 2019/08/30 Ver1.22 Add Start
  cv_sales_org_id           CONSTANT VARCHAR2(20) := 'XXCMN_SALES_ORG_ID';   -- XXCMN:営業ORG_ID
  cv_tax_kbn_0000           CONSTANT VARCHAR2(20) := 'XXPO_TAX_KBN_0000';    -- XXPO:税区分_対象外
  cv_max_line_9             CONSTANT VARCHAR2(20) := 'XXPO_MAX_LINE_NUMBER'; -- XXPO:表示可能明細数算出用
-- 2019/08/30 Ver1.22 Add End
--
-- 2019/08/30 Ver1.22 Add Start
  cv_xxpo_tax_type          CONSTANT VARCHAR2(13) := 'XXPO_TAX_TYPE';      -- XXPO:税区分
  cv_xxpo_line_count        CONSTANT VARCHAR2(15) := 'XXPO_LINE_COUNT';    -- XXPO:明細数
-- 2019/08/30 Ver1.22 Add End
  gv_xxcmn_consumption_tax_rate CONSTANT VARCHAR2(26) := 'XXCMN_CONSUMPTION_TAX_RATE'; -- 消費税
  gv_seqrt_view             CONSTANT VARCHAR2(30) := '有償支給セキュリティview' ;
  gv_seqrt_view_key         CONSTANT VARCHAR2(20) := '従業員ID' ;
-- add start 1.10
  gv_keishou                CONSTANT VARCHAR2(10) := '殿' ;
-- add end 1.10
--
  ------------------------------
  -- セキュリティ区分
  ------------------------------
  gc_seqrt_class_vender   CONSTANT VARCHAR2(1) := '2'; -- 取引先（斡旋者）
  gc_seqrt_class_outside  CONSTANT VARCHAR2(1) := '4'; -- 外部倉庫
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ; -- アプリケーション
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;  -- アプリケーション（XXPO）
-- 2019/08/30 Ver1.22 Add Start
  -- メッセージコード
  cv_msg_po_10127         CONSTANT VARCHAR2(50) := 'APP-XXPO-10127';    -- 取得不可エラー
  cv_msg_po_10156         CONSTANT VARCHAR2(50) := 'APP-XXPO-10156';    -- プロファイル取得エラー
  cv_msg_po_10296         CONSTANT VARCHAR2(50) := 'APP-XXPO-10296';    -- 振込先情報取得エラー
--
  -- トークン
  cv_tkn_entry            CONSTANT VARCHAR2(20) := 'ENTRY';             -- トークン：エントリ名
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';             -- トークン：テーブル名
  cv_tkn_name             CONSTANT VARCHAR2(20) := 'NAME';              -- トークン：名称
  cv_tkn_vendor           CONSTANT VARCHAR2(20) := 'VENDOR';            -- トークン：取引先コード
  cv_tkn_factory          CONSTANT VARCHAR2(20) := 'FACTORY';           -- トークン：工場コード
--
  -- トークン値
  cv_msg_out_data_01      CONSTANT VARCHAR2(30) := 'APP-XXPO-50001';    -- 請求先情報
  cv_msg_out_data_02      CONSTANT VARCHAR2(30) := 'APP-XXPO-50002';    -- 参照表
  cv_msg_out_data_03      CONSTANT VARCHAR2(30) := 'APP-XXPO-50003';    -- 税区分内訳表情報
  cv_msg_out_data_04      CONSTANT VARCHAR2(30) := 'APP-XXPO-50004';    -- 明細数
-- 2019/08/30 Ver1.22 Add End
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_yyyy_format     CONSTANT VARCHAR2(30) := 'YYYY' ;
  gc_char_yy_format       CONSTANT VARCHAR2(30) := 'YY' ;
  gc_char_mm_format       CONSTANT VARCHAR2(30) := 'MM' ;
  gc_char_dd_format       CONSTANT VARCHAR2(30) := 'DD' ;
  gc_char_yyyymm_format   CONSTANT VARCHAR2(30) := 'YYYY/MM' ;
--
  gv_s01                  CONSTANT VARCHAR2(3) := '/01';
  gn_zero                 CONSTANT NUMBER := 0;
  gn_one                  CONSTANT NUMBER := 1;
  gn_10                   CONSTANT NUMBER := 10;
  gn_11                   CONSTANT NUMBER := 11;
  gn_15                   CONSTANT NUMBER := 15;
  gn_16                   CONSTANT NUMBER := 16;
  gn_20                   CONSTANT NUMBER := 20;
  gn_21                   CONSTANT NUMBER := 21;
  gn_30                   CONSTANT NUMBER := 30;
-- add start 1.10
  gn_40                   CONSTANT NUMBER := 40;
-- add end 1.10
-- 2019/08/30 Ver1.22 Add Start
  gn_75                   CONSTANT NUMBER := 75;
  gn_76                   CONSTANT NUMBER := 76;
  gn_150                  CONSTANT NUMBER := 150;
-- 2019/08/30 Ver1.22 Add End
  gv_n                    CONSTANT VARCHAR2(1) := 'N';
  gv_ja                   CONSTANT VARCHAR2(2) := 'JA';
  gv_ast                  CONSTANT VARCHAR2(1) := '*';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE vendor_type    IS TABLE OF xxcmn_vendors2_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE dept_code_type IS TABLE OF po_headers_all.attribute10%TYPE INDEX BY BINARY_INTEGER;
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data IS RECORD(
      deliver_from       VARCHAR2(10)   -- 納入日FROM
     ,deliver_to         VARCHAR2(10)   -- 納入日TO
     ,d_deliver_from     DATE           -- 納入日FROM(日付型)
     ,d_deliver_to       DATE           -- 納入日TO(日付型)
     ,vendor_code        vendor_type    -- 取引先１～５
     ,assen_vendor_code  vendor_type    -- 斡旋者１～５
     ,dept_code          dept_code_type -- 担当部署１～５
     ,security_flg       VARCHAR2(1)    -- セキュリティ区分
    ) ;
--
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
  -- 代行請求書データ格納用レコード変数(編集前)
  TYPE rec_data_type_dtl2  IS RECORD(
      segment1_s           xxcmn_vendors2_v.segment1%TYPE         -- 仕入先コード
     ,segment1_a           xxcmn_vendors2_v.segment1%TYPE         -- 斡旋者コード
     ,vendor_name          xxcmn_vendors2_v.vendor_name%TYPE      -- 仕入先名
     ,zip                  xxcmn_vendors2_v.zip%TYPE              -- 郵便番号
     ,address_line1        xxcmn_vendors2_v.address_line1%TYPE    -- 取引先住所１
     ,address_line2        xxcmn_vendors2_v.address_line2%TYPE    -- 取引先住所２
     ,phone                xxcmn_vendors2_v.phone%TYPE            -- 取引先電話
     ,fax                  xxcmn_vendors2_v.fax%TYPE              -- 取引先FAX
     ,vendor_full_name     xxcmn_vendors2_v.vendor_full_name%TYPE -- 斡旋者名１
     ,attribute10          po_headers_all.attribute10%TYPE        -- 部署コード(発注)
     ,quantity             xxpo_rcv_and_rtn_txns.quantity%TYPE    -- 数量
     ,purchase_amount      NUMBER                                 -- 仕入金額
     ,attribute5           po_line_locations_all.attribute5%TYPE  -- 預かり口銭金額
     ,attribute8           po_line_locations_all.attribute8%TYPE  -- 賦課金額
     ,purchase_amount_tax  NUMBER                                 -- 仕入金額(消費税)
     ,attribute5_tax       po_line_locations_all.attribute5%TYPE  -- 預かり口銭金額(消費税)
     ,txns_type            xxpo_rcv_and_rtn_txns.txns_type%TYPE   -- 実績区分
     ,kobiki_mae           po_lines_all.attribute8%TYPE           -- 単価(粉引前単価)
     ,unit_price           po_line_locations_all.attribute2%TYPE  -- 単価(粉引後単価)
     ,kobiki_rate          po_line_locations_all.attribute1%TYPE  -- 粉引率
     ,kousen_k             po_line_locations_all.attribute3%TYPE  -- 口銭区分
     ,kousen               po_line_locations_all.attribute4%TYPE  -- 口銭
     ,fukakin_k            po_line_locations_all.attribute6%TYPE  -- 賦課金区分
     ,fukakin              po_line_locations_all.attribute7%TYPE  -- 賦課金
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
     ,tax_date             po_headers_all.attribute4%TYPE         -- 消費税基準日
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
-- 2019/08/30 Ver1.22 Add Start
     ,factory_code         xxpo_rcv_and_rtn_txns.factory_code%TYPE -- 工場コード
     ,tax                  xxcmm_item_tax_rate_v.tax%TYPE          -- 税率
     ,tax_code             xxcmm_item_tax_rate_v.tax_code_ex%TYPE  -- 税コード
     ,tax_kbn              fnd_lookup_values.description%type      -- 税区分
     ,attribute3           fnd_lookup_values.attribute3%TYPE       -- 税区分
-- 2019/08/30 Ver1.22 Add End
    ) ;
  TYPE tab_data_type_dtl2 IS TABLE OF rec_data_type_dtl2 INDEX BY BINARY_INTEGER ;
-- 2009/05/26 v1.15 T.Yoshimoto Add End
--
  -- 代行請求書データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
      segment1_s           xxcmn_vendors2_v.segment1%TYPE         -- 仕入先コード
     ,segment1_a           xxcmn_vendors2_v.segment1%TYPE         -- 斡旋者コード
     ,vendor_name          xxcmn_vendors2_v.vendor_name%TYPE      -- 仕入先名
     ,zip                  xxcmn_vendors2_v.zip%TYPE              -- 郵便番号
     ,address_line1        xxcmn_vendors2_v.address_line1%TYPE    -- 取引先住所１
     ,address_line2        xxcmn_vendors2_v.address_line2%TYPE    -- 取引先住所２
     ,phone                xxcmn_vendors2_v.phone%TYPE            -- 取引先電話
     ,fax                  xxcmn_vendors2_v.fax%TYPE              -- 取引先FAX
     ,vendor_full_name     xxcmn_vendors2_v.vendor_full_name%TYPE -- 斡旋者名１
     ,attribute10          po_headers_all.attribute10%TYPE        -- 部署コード(発注)
     ,quantity             xxpo_rcv_and_rtn_txns.quantity%TYPE    -- 数量
     ,purchase_amount      NUMBER                                 -- 仕入金額
     ,attribute5           po_line_locations_all.attribute5%TYPE  -- 預かり口銭金額
     ,attribute8           po_line_locations_all.attribute8%TYPE  -- 賦課金額
-- 2009/01/08 v1.13 N.Yoshida Mod Start 本番#970
     ,purchase_amount_tax  NUMBER                                 -- 仕入金額(消費税)
     ,attribute5_tax       po_line_locations_all.attribute5%TYPE  -- 預かり口銭金額(消費税)
-- 2009/01/08 v1.13 N.Yoshida Mod End 本番#970
-- 2019/08/30 Ver1.22 Add Start
     ,purchase_tax_kbn      fnd_lookup_values.description%TYPE                -- 仕入税区分
     ,comm_price_tax_kbn    fnd_lookup_values.attribute1%TYPE                 -- 口銭税区分
     ,bank_name             ap_bank_branches.bank_name%TYPE                   -- 金融機関名
     ,bank_branch_name      ap_bank_branches.bank_branch_name%TYPE            -- 支店名
     ,bank_account_type     VARCHAR2(4)                                       -- 預金区分
     ,bank_account_num      ap_bank_accounts_all.bank_account_num%TYPE        -- 口座No
     ,bank_account_name_alt ap_bank_accounts_all.account_holder_name_alt%TYPE -- 口座名義ｶﾅ
     ,break_page_flg        VARCHAR2(1)                                       -- 改ページフラグ
-- 2019/08/30 Ver1.22 Add End
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
-- 2019/08/30 Ver1.22 Add Start
  -- 税区分内訳情報
  TYPE g_description_ttype            IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY PLS_INTEGER;
  gt_description_tbl                  g_description_ttype;
  -- 税区分内訳情報
  TYPE g_attribute2_ttype            IS TABLE OF fnd_lookup_values.attribute2%TYPE INDEX BY PLS_INTEGER;
  gt_attribute2_tbl                  g_attribute2_ttype;
  -- 税区分
  TYPE g_tax_kbn_bd_ttype             IS TABLE OF VARCHAR2(8) INDEX BY PLS_INTEGER;
  gt_tax_kbn_bd_tab                   g_tax_kbn_bd_ttype;
  -- 税区分(税区分内訳出力用)
  TYPE g_tax_kbn_bd_1_ttype           IS TABLE OF VARCHAR2(14) INDEX BY PLS_INTEGER;
  gt_tax_kbn_bd_1_tab                 g_tax_kbn_bd_1_ttype;
  -- 仕入金額(税抜)
  TYPE g_p_amount_bd_ttype            IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_p_amount_bd_tab                  g_p_amount_bd_ttype;
  -- 仕入消費税
  TYPE g_p_amount_tax_bd_ttype        IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_p_amount_tax_bd_tab              g_p_amount_tax_bd_ttype;
  -- 口銭金額(税抜)
  TYPE g_unit_price_rate_bd_ttype     IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_unit_price_rate_bd_tab           g_unit_price_rate_bd_ttype;
  -- 口銭消費税
  TYPE g_unit_price_rate_tax_bd_ttype IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_unit_price_rate_tax_bd_tab         g_unit_price_rate_tax_bd_ttype;
  -- 賦課金
  TYPE g_l_unit_price_rate_bd_ttype   IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_l_unit_price_rate_bd_tab         g_l_unit_price_rate_bd_ttype;
  -- 賦課金消費税
  TYPE g_l_u_price_rate_tax_bd_ttype  IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_l_u_price_rate_tax_bd_tab        g_l_u_price_rate_tax_bd_ttype;
  -- 合計(税抜金額)
  TYPE g_tax_exc_amount_bd_ttype      IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_tax_exc_amount_bd_tab            g_tax_exc_amount_bd_ttype;
  -- 合計(消費税)
  TYPE g_ded_amount_tax_bd_ttype      IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_ded_amount_tax_bd_tab            g_ded_amount_tax_bd_ttype;
-- 2019/08/30 Ver1.22 Add End
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
--  
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;        -- 営業単位（生産）
-- 2019/08/30 Ver1.22 Add Start
  gn_sales_org_id           po_vendor_sites_all.org_id%TYPE ;             -- 営業単位（営業）
-- 2019/08/30 Ver1.22 Add End
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE; -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;      -- 担当者
  gv_user_vender            xxpo_per_all_people_f_v.attribute4%TYPE;      -- 仕入先コード
  gv_user_vender_site       xxpo_per_all_people_f_v.attribute6%TYPE;      -- 仕入先サイトコード
  gn_user_vender_id         po_vendors.vendor_id%TYPE;                    -- 仕入先ID
--
  gn_tax                    NUMBER; -- 消費税係数
-- 2019/08/30 Ver1.22 Add Start
--
  gv_tax_kbn_0000           VARCHAR2(20);     -- XXPO:税区分_対象外
--
  gn_tax_kbn                NUMBER DEFAULT 0; -- 税区分内訳表カウント
  gn_line_count             NUMBER DEFAULT 0; -- 表示可能明細数
  gn_max_line_9             NUMBER DEFAULT 0; -- 表示可能明細数算出用
--
  gv_break_page_flg         VARCHAR2(60);     -- 最終仕入先の帳票改ページフラグ
  gv_from_dept_name         VARCHAR2(60);     -- 請求先名
  gv_from_postal_code       VARCHAR2(8);      -- 郵便番号
  gv_from_address           VARCHAR2(60);     -- 住所

-- 2019/08/30 Ver1.22 Add End
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(vendor_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_vendor_type IN vendor_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<vendor_code_loop>>
    FOR ln_cnt IN 1..itbl_vendor_type.COUNT LOOP
      lv_in := lv_in || '''' || itbl_vendor_type(ln_cnt) || ''',';
    END LOOP vendor_code_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(dept_code_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_dept_code_type IN dept_code_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<dept_code_type_loop>>
    FOR ln_cnt IN 1..itbl_dept_code_type.COUNT LOOP
      lv_in := lv_in || '''' || itbl_dept_code_type(ln_cnt) || ''',';
    END LOOP dept_code_type_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml
   * Description      : XML出力処理
   ***********************************************************************************/
  PROCEDURE prc_out_xml(
      ov_errbuf         OUT VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
     ,ir_param          IN  rec_param_data -- 入力パラメータ群
     ,it_xml_data_table IN  XML_DATA       -- 取得レコード群
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_xml_string        VARCHAR2(32000);
--
    -- *** ローカル・例外処理 ***
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- ＸＭＬヘッダー出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- ＸＭＬデータ部出力
    <<xml_data_table>>
    FOR i IN 1 .. it_xml_data_table.COUNT LOOP
      -- 編集したデータをタグに変換
      lv_xml_string := fnc_conv_xml(
                          iv_name   => it_xml_data_table(i).tag_name    -- タグネーム
                         ,iv_value  => it_xml_data_table(i).tag_value   -- タグデータ
                         ,ic_type   => it_xml_data_table(i).tag_type    -- タグタイプ
                        ) ;
      -- ＸＭＬタグ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- ＸＭＬフッダー出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_out_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(F-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ov_errbuf     OUT    VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
     ,ir_param      IN     rec_param_data   -- 入力パラメータ群
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
-- 2019/08/30 Ver1.22 Add Start
    -- *** ローカル・定数 ***
    cv_xxpo_billing_information CONSTANT VARCHAR2(24) := 'XXPO_BILLING_INFORMATION'; -- XXPO：請求先情報
--
-- 2019/08/30 Ver1.22 Add End
    -- *** ローカル変数 ***
-- 2019/08/30 Ver1.22 Add Start
    lt_lookup_code    fnd_lookup_values.lookup_code%TYPE;
-- 2019/08/30 Ver1.22 Add End
--
    -- *** ローカル・例外処理 ***
    get_value_expt    EXCEPTION ;     -- 値取得エラー
-- 2013/07/05 v1.21 R.Watanabe Del Start E_本稼動_10839
--    lv_tax            fnd_lookup_values.lookup_code%TYPE; -- 消費税
-- 2013/07/05 v1.21 R.Watanabe Del End E_本稼動_10839
    ld_deliver_from   DATE; -- 納入日FROMの年月の1日
--
-- 2019/08/30 Ver1.22 Add Start
    -- *** ローカル・カーソル ***
    -- 税区分内訳情報
    CURSOR  tax_kbn_cur
    IS
--      SELECT xlv2.description AS description  -- 税区分
      SELECT xlv2.description AS description  -- 税区分
            ,xlv2.attribute2  AS attribute2   -- 税区分_税区分内訳出力用
      FROM   xxcmn_lookup_values2_v xlv2
      WHERE  xlv2.lookup_type = cv_xxpo_tax_type
      AND    FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
                              BETWEEN xlv2.start_date_active
                              AND     NVL(xlv2.end_date_active ,FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format ))
      ORDER BY xlv2.attribute1
      ;
--
-- 2019/08/30 Ver1.22 Add End
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 営業単位取得
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( gv_org_id ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-00005' ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
-- 2019/08/30 Ver1.22 Add Start
    -- ====================================================
    -- 営業単位取得
    -- ====================================================
    gn_sales_org_id := FND_PROFILE.VALUE( cv_sales_org_id ) ;
    IF ( gn_sales_org_id IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,cv_msg_po_10156
                                            ,cv_tkn_name
                                            ,cv_sales_org_id ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- 税区分_対象外取得
    -- ====================================================
    gv_tax_kbn_0000 := FND_PROFILE.VALUE( cv_tax_kbn_0000 ) ;
    IF ( gv_tax_kbn_0000 IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,cv_msg_po_10156
                                            ,cv_tkn_name
                                            ,cv_tax_kbn_0000 ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- 表示可能明細数算出用取得
    -- ====================================================
    gn_max_line_9 := FND_PROFILE.VALUE( cv_max_line_9 ) ;
    IF ( gn_max_line_9 IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,cv_msg_po_10156
                                            ,cv_tkn_name
                                            ,cv_max_line_9 ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
-- 2019/08/30 Ver1.22 Add End
-- 2013/07/05 v1.21 R.Watanabe Del Start E_本稼動_10839
/*
    -- ====================================================
    -- 消費税取得
    -- ====================================================
    -- 納入日FROMの年月の1日
    ld_deliver_from := FND_DATE.STRING_TO_DATE(
      (TO_CHAR(ir_param.d_deliver_from,gc_char_yyyymm_format) || gv_s01),gc_char_dt_format);
    BEGIN
      SELECT
        flv.lookup_code
      INTO
        lv_tax
      FROM
        xxcmn_lookup_values2_v flv
      WHERE
            flv.lookup_type = gv_xxcmn_consumption_tax_rate
        AND ((flv.start_date_active <= ld_deliver_from)
          OR (flv.start_date_active IS NULL))
        AND ((flv.end_date_active   >= ld_deliver_from)
          OR (flv.end_date_active   IS NULL));
      -- 消費税係数
      gn_tax := TO_NUMBER(lv_tax) / 100;
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gc_application_po
                      ,'APP-XXPO-00006');
        lv_retcode  := gv_status_error ;
        RAISE get_value_expt ;
    END;
*/
-- 2013/07/05 v1.21 R.Watanabe Del End E_本稼動_10839
--
    -- ====================================================
    -- 担当部署名取得
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- 担当者名取得
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- 仕入先コード・仕入先サイトコード取得
    -- ====================================================
    BEGIN
--
      SELECT xssv.vendor_code
            ,xssv.vendor_site_code
            ,vnd.vendor_id
      INTO   gv_user_vender
            ,gv_user_vender_site
            ,gn_user_vender_id
      FROM  xxpo_security_supply_v xssv
           ,xxcmn_vendors2_v       vnd
      WHERE xssv.vendor_code    = vnd.segment1 (+)
      AND   xssv.user_id        = gn_user_id
      AND   xssv.security_class = ir_param.security_flg
      AND   FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
            BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+) ;
--
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        -- メッセージセット
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                              ,'APP-XXCMN-10001'
                                              ,'TABLE'
                                              ,gv_seqrt_view
                                              ,'KEY'
                                              ,gv_seqrt_view_key ) ;
        lv_retcode := gv_status_error;
        RAISE get_value_expt ;
    END;
--
-- 2019/08/30 Ver1.22 Add Start
    -- ====================================================
    -- 請求先情報の取得
    -- ====================================================
    BEGIN
--
      SELECT flv.attribute1  from_dept_name    -- 請求先名
            ,flv.attribute2  from_postal_code  -- 郵便番号
            ,flv.attribute3  from_address      -- 住所
      INTO   gv_from_dept_name
            ,gv_from_postal_code
            ,gv_from_address
      FROM   xxcmn_lookup_values2_v flv
      WHERE  flv.lookup_type = cv_xxpo_billing_information
      AND    FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
             BETWEEN flv.start_date_active
             AND     NVL(flv.end_date_active ,FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format ))
      ;
--
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        -- メッセージセット
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                              ,cv_msg_po_10127
                                              ,cv_tkn_entry
                                              ,cv_msg_out_data_01
                                              ,cv_tkn_table
                                              ,cv_msg_out_data_02 ) ;
        lv_retcode := gv_status_error;
        RAISE get_value_expt ;
    END;
--
    -- ====================================================
    -- 税区分内訳表情報の取得
    -- ====================================================
    -- オープン
    OPEN tax_kbn_cur;
    -- バルクフェッチ
    FETCH tax_kbn_cur BULK COLLECT INTO gt_description_tbl,gt_attribute2_tbl;
    -- カーソルクローズ
    CLOSE tax_kbn_cur;
--
    -- 取得データが０件の場合
    IF ( gt_description_tbl.COUNT = 0 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,cv_msg_po_10127
                                            ,cv_tkn_entry
                                            ,cv_msg_out_data_03
                                            ,cv_tkn_table
                                            ,cv_msg_out_data_02 ) ;
      lv_retcode  := gv_status_error ;
      RAISE get_value_expt ;
    END IF;
--
    lt_lookup_code := TO_CHAR(gt_description_tbl.count);
--
    -- 税区分に対して、1ページに表示可能な明細数を取得
    BEGIN
      SELECT TO_NUMBER(xlv2.description) AS line_count  -- 明細数
      INTO   gn_line_count
      FROM   xxcmn_lookup_values2_v xlv2
      WHERE  xlv2.lookup_type = cv_xxpo_line_count
      AND    xlv2.lookup_code = lt_lookup_code
      AND    FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
                              BETWEEN xlv2.start_date_active
                              AND     NVL(xlv2.end_date_active ,FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format ))
      ORDER BY xlv2.attribute1
      ;
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        -- メッセージセット
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                              ,cv_msg_po_10127
                                              ,cv_tkn_entry
                                              ,cv_msg_out_data_04
                                              ,cv_tkn_table
                                              ,cv_msg_out_data_02 ) ;
        lv_retcode := gv_status_error;
        RAISE get_value_expt ;
    END;
-- 2019/08/30 Ver1.22 Add End
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(F-3-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ov_errbuf     OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  -- ユーザー・エラー・メッセージ --# 固定 #
     ,ir_param      IN  rec_param_data            -- 入力パラメータ群
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
--     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 取得レコード群
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl2  -- 取得レコード群
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_item_class       CONSTANT VARCHAR2( 1) := '5';        -- 品目区分(製品)
    cv_pln_cancel_flag  CONSTANT VARCHAR2( 1) := 'Y';        -- 取消フラグ(取消)
    cv_poh_approved     CONSTANT VARCHAR2(10) := 'APPROVED'; -- 発注ステータス(承認済み)
--
    cv_poh_decision     CONSTANT VARCHAR2( 2) := '35';       -- 発注ｱﾄﾞｵﾝｽﾃｰﾀｽ(金額確定)
    cv_poh_cancel       CONSTANT VARCHAR2( 2) := '99';       -- 発注ｱﾄﾞｵﾝｽﾃｰﾀｽ(取消)
--
    cv_txn_type_acc     CONSTANT VARCHAR2( 1) := '1';-- 実績区分:XXPO_TXNS_TYPE(受入)
    cv_txn_type_rtn     CONSTANT VARCHAR2( 1) := '2';-- 実績区分:XXPO_TXNS_TYPE(仕入先返品)
    cv_txn_type_rtn_3   CONSTANT VARCHAR2( 1) := '3';-- 実績区分:XXPO_TXNS_TYPE(発注なし仕入先返品)
--
    -- *** ローカル・変数 ***
    lv_sql        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_in         VARCHAR2(1000) ;
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;  -- 取得レコードなし
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ----------------------------------------------------
    -- ＳＥＬＥＣＴ句生成
    -- ----------------------------------------------------
    lv_sql :=
         ' SELECT'
-- 2019/08/30 Ver1.22 Add Start
      || '   /*+ push_pred(xitrv) */ '
-- 2019/08/30 Ver1.22 Add End
      || '   xvv_s.segment1            AS segment1_s          ' -- 仕入先番号
      || '  ,xvv_a.segment1            AS segment1_a          ' -- 斡旋者コード
      || '  ,xvv_s.vendor_full_name    AS vendor_name         ' -- 仕入先名
      || '  ,xvv_s.zip                 AS zip                 ' -- 郵便番号
      || '  ,xvv_s.address_line1       AS address_line1       ' -- 取引先住所１
      || '  ,xvv_s.address_line2       AS address_line2       ' -- 取引先住所２
      || '  ,xvv_s.phone               AS phone               ' -- 取引先電話
      || '  ,xvv_s.fax                 AS fax                 ' -- 取引先FAX
      || '  ,xvv_a.vendor_full_name    AS vendor_full_name    ' -- 斡旋者名１
      || '  ,comm.attribute10          AS attribute10         ' -- 部署コード(発注)
      || '  ,comm.quantity             AS quantity            ' -- 数量
      || '  ,comm.purchase_amount      AS purchase_amount     ' -- 仕入金額
      || '  ,comm.attribute5           AS attribute5          ' -- 預かり口銭金額
      || '  ,comm.attribute8           AS attribute8          ' -- 賦課金額
-- 2009/01/08 v1.13 N.Yoshida Mod Start 本番#970
      || '  ,comm.purchase_amount_tax  AS purchase_amount_tax ' -- 仕入金額(消費税)
      || '  ,comm.attribute5_tax       AS attribute5_tax      ' -- 預かり口銭金額(消費税)
-- 2009/01/08 v1.13 N.Yoshida Mod End 本番#970
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '  ,comm.txns_type            AS txns_type           ' -- 実績区分
      || '  ,comm.kobiki_mae           AS kobiki_mae          ' -- 単価(粉引前単価)
      || '  ,comm.unit_price           AS unit_price          ' -- 粉引後単価
      || '  ,comm.kobiki_rate          AS kobiki_rate         ' -- 粉引率
      || '  ,comm.kousen_k             AS kousen_k            ' -- 口銭区分
      || '  ,comm.kousen               AS kousen              ' -- 口銭
      || '  ,comm.fukakin_k            AS fukakin_k           ' -- 賦課金区分
      || '  ,comm.fukakin              AS fukakin             ' -- 賦課金
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
      || '  ,comm.tax_date              AS tax_date             ' -- 消費税基準日
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
-- 2019/08/30 Ver1.22 Add Start
      || '  ,comm.factory_code          AS factory_code         ' -- 工場コード
      || '  ,TO_NUMBER(xitrv.tax) / 100 AS tax                  ' -- 税率
      || '  ,xitrv.tax_code_ex          AS tax_code             ' -- 税コード
      || '  ,xlv2.description           AS tax_kbn              ' -- 税区分
      || '  ,xlv2.attribute3            AS attribute3           ' -- 税区分_出力用
-- 2019/08/30 Ver1.22 Add End
      || ' FROM'
      || '   ('
      || '    SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '      com.txns_type     AS txns_type '                -- 実績区分
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '     ,com.vendor_id     AS vendor_id'
      || '     ,com.attribute3    AS attribute3'
      || '     ,com.attribute10   AS attribute10'
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
/*
      || '     ,SUM(com.sum_quantity) AS quantity'
-- 2009/01/08 v1.13 N.Yoshida Mod Start 本番#970
--      || '     ,SUM(NVL(com.sum_quantity,0) * com.unit_price) AS purchase_amount'
      || '     ,SUM(ROUND(NVL(com.sum_quantity,0) * com.unit_price)) AS purchase_amount'
      || '     ,SUM(com.attribute5) AS attribute5'
      || '     ,SUM(ROUND(ROUND(NVL(com.sum_quantity,0) * com.unit_price ) * ' || gn_tax || ')) AS purchase_amount_tax'
      || '     ,SUM(ROUND(com.attribute5 * ' || gn_tax || ')) AS attribute5_tax'
-- 2009/01/08 v1.13 N.Yoshida Mod End 本番#970
      || '     ,SUM(com.attribute8) AS attribute8'
*/
      || '      ,com.sum_quantity AS quantity '
      || '      ,ROUND(NVL(com.sum_quantity,0) * com.unit_price) AS purchase_amount '
      || '      ,com.attribute5 AS attribute5 '
-- 2013/07/05 v1.21 R.Watanabe Mod Start E_本稼動_10839
--      || '      ,ROUND(ROUND(NVL(com.sum_quantity,0) * com.unit_price ) * .05) AS purchase_amount_tax '
--      || '      ,ROUND(com.attribute5 * .05) AS attribute5_tax '
       || '      ,ROUND(NVL(com.sum_quantity,0) * com.unit_price ) AS purchase_amount_tax '
       || '      ,ROUND(com.attribute5) AS attribute5_tax '
-- 2013/07/05 v1.21 R.Watanabe Mod End E_本稼動_10839
      || '      ,com.attribute8              AS attribute8 '
      || '      ,com.kobiki_mae              AS kobiki_mae '     -- 単価(粉引前単価)  -- Add T.Yoshimoto
      || '      ,com.unit_price              AS unit_price '     -- 粉引後単価        -- Add T.Yoshimoto
      || '      ,com.kobiki_rate             AS kobiki_rate '    -- 粉引率            -- Add T.Yoshimoto
      || '      ,com.kousen_k                AS kousen_k '       -- 口銭区分          -- Add T.Yoshimoto
      || '      ,com.kousen                  AS kousen '         -- 口銭              -- Add T.Yoshimoto
      || '      ,com.fukakin_k               AS fukakin_k '      -- 賦課金区分        -- Add T.Yoshimoto
      || '      ,com.fukakin                 AS fukakin '        -- 賦課金            -- Add T.Yoshimoto
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
      || '      ,com.tax_date              AS tax_date '          -- 消費税基準日
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
-- 2019/08/30 Ver1.22 Add Start
      || '       ,com.factory_code           AS factory_code '   -- 工場コード
      || '       ,com.item_id                AS item_id '        -- 品目ID
-- 2019/08/30 Ver1.22 Add End
      || '   FROM'
      || '     ('
                --受入実績
      || '      SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        xrart2.txns_type AS txns_type ' -- 実績区分
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,poh.vendor_id   AS vendor_id '  -- 仕入先番号(取引先)
      || '       ,poh.attribute3  AS attribute3'  -- 仕入先番号(斡旋者)
      || '       ,poh.attribute10 AS attribute10' -- 部署コード
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
/*
-- 2008/11/28 v1.12 T.Yoshimoto Mod Start 本番#204
--      || '       ,pla.unit_price  AS unit_price'  -- 単価(粉引後単価)
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute2,0)) AS unit_price'  -- 単価(粉引後単価)
      || '         FROM   po_line_locations_all plla' -- 発注納入明細
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS unit_price'
-- 2008/11/28 v1.12 T.Yoshimoto Mod End 本番#204
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute5,0)) AS attribute5'-- 預かり口銭金額
      || '         FROM   po_line_locations_all plla' -- 発注納入明細
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS attribute5'
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute8,0)) AS attribute8'-- 賦課金額
      || '         FROM   po_line_locations_all plla' -- 発注納入明細
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS attribute8'
      || '       ,xrart.sum_quantity AS sum_quantity'; -- 受入返品
*/
      || '       ,TO_NUMBER(NVL(pla.attribute8,0))  AS kobiki_mae '   -- 単価(粉引前単価)
      || '       ,TO_NUMBER(NVL(plla.attribute2,0)) AS unit_price '   -- 単価(粉引後単価)
      || '       ,TO_NUMBER(NVL(plla.attribute5,0)) AS attribute5 '   -- 預かり口銭金額
      || '       ,TO_NUMBER(NVL(plla.attribute8,0)) AS attribute8 '   -- 賦課金額
      || '       ,NVL(plla.ATTRIBUTE1,0)            AS kobiki_rate '  -- 粉引率
      || '       ,NVL(plla.ATTRIBUTE3,3)            AS kousen_k '     -- 口銭区分
      || '       ,NVL(plla.ATTRIBUTE4,0)            AS kousen '       -- 口銭
      || '       ,NVL(plla.ATTRIBUTE6,3)            AS fukakin_k '    -- 賦課金区分
      || '       ,NVL(plla.ATTRIBUTE7,0)            AS fukakin '      -- 賦課金
      || '       ,xrart2.quantity                   AS sum_quantity ' -- 受入返品
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
      || '       ,poh.attribute4                    AS tax_date '     -- 納入日
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
-- 2019/08/30 Ver1.22 Add Start
      || '       ,pla.attribute2                    AS factory_code ' -- 工場コード
      || '       ,xrart2.item_id                    AS item_id '      -- 品目ID
-- 2019/08/30 Ver1.22 Add End
      ;
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '      FROM'
      || '        po_headers_all        poh'   -- 発注ヘッダ
      || '       ,po_lines_all          pla'   -- 発注明細
      || '       ,xxpo_headers_all      xha'   -- 発注ヘッダ（アドオン）
      || '       ,xxcmn_locations2_v    xlv'   -- 事業所情報VIEW2
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,po_line_locations_all plla'   -- 発注納入明細
      || '       ,xxpo_rcv_and_rtn_txns xrart2' -- 受入返品実績(アドオン)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '      ,('
      || '        SELECT'
      || '          xrart.source_document_number   AS source_document_number'
      || '         ,xrart.source_document_line_num AS source_document_line_num'
      || '         ,MAX(xrart.txns_date)           AS txns_date'
-- 2009/05/26 v1.15 T.Yoshimoto Del Start
--      || '         ,SUM(xrart.quantity)            AS sum_quantity'
-- 2009/05/26 v1.15 T.Yoshimoto Del End
      || '        FROM'
      || '          xxpo_rcv_and_rtn_txns xrart' -- 受入返品実績(アドオン)
      || '        WHERE'
      || '          xrart.txns_type = ''' || cv_txn_type_acc || '''' -- 受入
      || '        GROUP BY'
      || '          xrart.source_document_number'
      || '         ,xrart.source_document_line_num'
      || '       ) xrart';
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '      WHERE'
           -- 発注ヘッダ
      || '            poh.org_id        = ''' || gn_sales_class || ''''
      || '        AND poh.segment1      = xha.po_header_number'
      || '        AND poh.po_header_id  = pla.po_header_id'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        AND plla.po_line_id = pla.po_line_id '
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2009/09/24 v1.19 T.Yoshimoto Del Start 本番#1523
      --|| '        AND poh.authorization_status =  ''' || cv_poh_approved || ''''
-- 2009/09/24 v1.19 T.Yoshimoto Del End 本番#1523
      || '        AND poh.attribute1           >= ''' || cv_poh_decision || '''' -- 金額確定
      || '        AND poh.attribute1           <  ''' || cv_poh_cancel   || '''' -- 取消
      || '        AND ( '
      || '             (pla.cancel_flag = ''' || gv_n || ''') '
      || '          OR (pla.cancel_flag IS NULL) '     -- キャンセルフラグ
      || '            ) '
-- 2009/03/30 v1.14 ADD START
      || '        AND poh.org_id        = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.14 ADD END
           -- 受入返品実績アドオン
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        AND xrart2.txns_type = ''' || cv_txn_type_acc || ''''
      || '        AND xrart2.source_document_number   = poh.segment1'
      || '        AND xrart2.source_document_line_num = pla.line_num'
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '        AND xrart.source_document_number   = poh.segment1'
      || '        AND xrart.source_document_line_num = pla.line_num'
      || '        AND xrart.txns_date '
      || '          BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                        || gc_char_d_format || ''')'
      || '            AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                      || gc_char_d_format || ''')';
--
    -- パラメータ担当部署
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1件のみ
      lv_sql := lv_sql
        || '        AND poh.attribute10 = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1件以上
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '        AND poh.attribute10  IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- 部署
      || '        AND xlv.start_date_active <= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '        AND ((xlv.end_date_active >= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                || gc_char_d_format || '''))'
      || '          OR (xlv.end_date_active IS NULL)) '
      || '        AND poh.attribute10 = xlv.location_code ';
--
    -- セキュリティ区分の絞込み条件
    -- 「取引先」の場合
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || '        AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
        || '          OR ( poh.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ログインユーザーの仕入先サイトコードが設定されている場合
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || '        AND  NOT EXISTS(SELECT po_line_id '
          || '                        FROM   po_lines_all pl_sub '
          || '                        WHERE  pl_sub.po_header_id = poh.po_header_id '
          || '                        AND  NVL(pl_sub.attribute2,''' || gv_ast || ''') '
          || '                          <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
-- 発注あり仕入先返品
    lv_sql := lv_sql
      || '      UNION ALL'
      || '      SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        xrart.txns_type    AS txns_type '    -- 実績区分
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,poh.vendor_id      AS vendor_id '    -- 仕入先番号(取引先)
      || '       ,poh.attribute3     AS attribute3'    -- 仕入先番号(斡旋者)
      || '       ,poh.attribute10    AS attribute10'   -- 部署コード
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,xrart.kobiki_mae   AS kobiki_mae'    -- 単価(粉引前単価)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,xrart.unit_price   AS unit_price'    -- 単価(粉引後単価)
      || '       ,xrart.attribute5   AS attribute5'    -- 預かり口銭金額
      || '       ,xrart.attribute8   AS attribute8'    -- 賦課金額
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,NULL               AS kobiki_rate '  -- 粉引率
      || '       ,NULL               AS kousen_k '     -- 口銭区分
      || '       ,NULL               AS kousen '       -- 口銭
      || '       ,NULL               AS fukakin_k '    -- 賦課金区分
      || '       ,NULL               AS fukakin '      -- 賦課金
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
     -- || '       ,xrart.sum_quantity AS sum_quantity'; -- 受入返品
      || '       ,xrart.sum_quantity AS sum_quantity'  -- 受入返品
      || '       ,poh.attribute4     AS tax_date '     -- 返品元発注納入日
-- 2019/08/30 Ver1.22 Add Start
      || '       ,pla.attribute2     AS factory_code ' -- 工場コード
      || '       ,xrart.item_id      AS item_id '      -- 品目ID
-- 2019/08/30 Ver1.22 Add End
      ;
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '      FROM'
      || '        po_headers_all        poh'   -- 発注ヘッダ
      || '       ,po_lines_all          pla'   -- 発注明細
      || '       ,xxpo_headers_all      xha'   -- 発注ヘッダ（アドオン）
      || '       ,xxcmn_locations2_v    xlv'   -- 事業所情報VIEW2
      || '       ,('
      || '         SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '          xrart.txns_type                 AS txns_type '       -- 実績区分
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '         ,xrart.source_document_number    AS source_document_number'
      || '         ,xrart.source_document_line_num  AS source_document_line_num'
      || '         ,MAX(xrart.txns_date)            AS txns_date'
      || '         ,SUM(xrart.quantity * -1)        AS sum_quantity'     -- マイナス
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '         ,NULL                            AS kobiki_mae'       -- 単価(粉引前単価)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '         ,AVG(xrart.kobki_converted_unit_price) AS unit_price' -- 粉引後単価
      || '         ,SUM(xrart.kousen_price * -1)    AS attribute5'       -- 預かり口銭金額
      || '         ,SUM(xrart.fukakin_price * -1)   AS attribute8'       -- 賦課金額
-- 2019/08/30 Ver1.22 Add Start
      || '         ,xrart.item_id                   AS item_id'          -- 品目ID
-- 2019/08/30 Ver1.22 Add End
      || '         FROM'
      || '           xxpo_rcv_and_rtn_txns xrart' -- 受入返品実績(アドオン)
      || '         WHERE'
      || '               xrart.txns_type  = ''' || cv_txn_type_rtn || '''' -- 仕入先返品
      || '           AND xrart.txns_date '
      || '             BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                           || gc_char_d_format || ''')'
      || '           AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                 || gc_char_d_format || ''')'
      || '           AND xrart.quantity > ' || gn_zero || ''
      || '         GROUP BY'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '           xrart.txns_type '               -- 実績区分
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '          ,xrart.source_document_number'
      || '          ,xrart.source_document_line_num'
-- 2019/08/30 Ver1.22 Add Start
      || '          ,xrart.item_id'
-- 2019/08/30 Ver1.22 Add End
      || '        ) xrart';
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '      WHERE'
           -- 発注ヘッダ
      || '            poh.org_id        = ''' || gn_sales_class || ''''
      || '        AND poh.segment1      = xha.po_header_number'
      || '        AND poh.po_header_id  = pla.po_header_id'
-- 2009/09/24 v1.19 T.Yoshimoto Del Start 本番#1523
      --|| '        AND poh.authorization_status =  ''' || cv_poh_approved || ''''
-- 2009/09/24 v1.19 T.Yoshimoto Del End 本番#1523
      || '        AND poh.attribute1           >= ''' || cv_poh_decision || '''' -- 金額確定
      || '        AND poh.attribute1           <  ''' || cv_poh_cancel   || '''' -- 取消
      || '        AND ( '
      || '             (pla.cancel_flag = ''' || gv_n || ''') '
      || '          OR (pla.cancel_flag IS NULL) '     -- キャンセルフラグ
      || '            ) '
-- 2009/03/30 v1.14 ADD START
      || '        AND poh.org_id        = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.14 ADD END
           -- 受入返品実績アドオン
      || '        AND xrart.source_document_number   = poh.segment1'
      || '        AND xrart.source_document_line_num = pla.line_num'
      || '        AND xrart.txns_date '
      || '          BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                        || gc_char_d_format || ''')'
      || '            AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                      || gc_char_d_format || ''')';
--
    -- パラメータ担当部署
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1件のみ
      lv_sql := lv_sql
        || '        AND poh.attribute10 = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1件以上
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '        AND poh.attribute10  IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- 部署
      || '        AND xlv.start_date_active <= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '        AND ((xlv.end_date_active >= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                || gc_char_d_format || '''))'
      || '          OR (xlv.end_date_active IS NULL)) '
      || '        AND poh.attribute10 = xlv.location_code ';
--
    -- セキュリティ区分の絞込み条件
    -- 「取引先」の場合
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || '        AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
        || '          OR ( poh.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ログインユーザーの仕入先サイトコードが設定されている場合
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || '        AND  NOT EXISTS(SELECT po_line_id '
          || '                        FROM   po_lines_all pl_sub '
          || '                        WHERE  pl_sub.po_header_id = poh.po_header_id '
          || '                        AND  NVL(pl_sub.attribute2,''' || gv_ast || ''') '
          || '                          <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
-- 発注なし仕入先返品
    lv_sql :=  lv_sql
      || ' UNION ALL'
      || '      SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        xrart.txns_type                    AS txns_type '    -- 実績区分
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,xrart.vendor_id                    AS vendor_id '  -- 仕入先番号(取引先)
      || '       ,TO_CHAR(xrart.assen_vendor_id)     AS attribute3'  -- 仕入先番号(斡旋者)
      || '       ,xrart.department_code              AS attribute10' -- 部署コード
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,NULL                               AS kobiki_mae'    -- 単価(粉引前単価)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,xrart.kobki_converted_unit_price   AS unit_price'  -- 単価
      || '       ,xrart.kousen_price * -1            AS attribute5'  -- 預かり口銭金額
      || '       ,xrart.fukakin_price * -1           AS attribute8'  -- 賦課金額
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,NULL                               AS kobiki_rate '  -- 粉引率
      || '       ,NULL                               AS kousen_k '     -- 口銭区分
      || '       ,NULL                               AS kousen '       -- 口銭
      || '       ,NULL                               AS fukakin_k '    -- 賦課金区分
      || '       ,NULL                               AS fukakin '      -- 賦課金
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
     -- || '       ,xrart.quantity * -1                AS sum_quantity'; -- 数量
      || '       ,xrart.quantity * -1                AS sum_quantity'  -- 数量
      || '       ,TO_CHAR(xrart.txns_date,''YYYY/MM/DD'')     AS tax_date '    -- 取引日
-- 2019/08/30 Ver1.22 Add Start
      || '       ,xrart.factory_code                 AS factory_code ' -- 工場コード
      || '       ,xrart.item_id                      AS item_id '      -- 品目ID
-- 2019/08/30 Ver1.22 Add End
      ;
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '   FROM '
      || '     xxpo_rcv_and_rtn_txns xrart'  -- 受入返品実績(アドオン)
      || '    ,xxcmn_locations2_v    xlv ';  -- 事業所情報VIEW2
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '   WHERE '
      || '         xrart.txns_type = ''' || cv_txn_type_rtn_3 || '''' -- 発注なし仕入先返品
      || '     AND xrart.quantity  > ' || gn_zero || ''
      || '     AND xrart.txns_date'
      || '           BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                         || gc_char_d_format || ''')'
      || '     AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                               || gc_char_d_format || ''')';
--
    -- パラメータ担当部署
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1件のみ
      lv_sql := lv_sql
        || '     AND xrart.department_code = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1件以上
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '     AND xrart.department_code IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- 部署
      || '     AND xlv.start_date_active <= '
      || '       FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                             || gc_char_d_format || ''')'
      || '     AND ((xlv.end_date_active >= '
      || '       FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                             || gc_char_d_format || '''))'
      || '       OR (xlv.end_date_active IS NULL)) '
      || '     AND xrart.department_code = xlv.location_code ';
--
    -- セキュリティ区分の絞込み条件
    -- 「取引先」の場合
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || ' AND (   ( xrart.assen_vendor_id = ''' || gn_user_vender_id || ''')'
        || '      OR ( xrart.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ログインユーザーの仕入先サイトコードが設定されている場合
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || ' AND  NOT EXISTS(SELECT xrart_sub.factory_code '
          || '                 FROM   xxpo_rcv_and_rtn_txns xrart_sub '
          || '                 WHERE  xrart_sub.rcv_rtn_number = xrart.rcv_rtn_number '
          || '                   AND  NVL(xrart_sub.factory_code,''' || gv_ast || ''') '
          || '                        <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
--
    lv_sql := lv_sql
      || '     ) com '
-- 2009/05/26 v1.15 T.Yoshimoto Del Start
--      || '   GROUP BY '
--      || '     com.vendor_id '
--      || '    ,com.attribute3 '
--      || '    ,com.attribute10 '
-- 2009/05/26 v1.15 T.Yoshimoto Del End
      || '   ) comm '
      || '  ,xxcmn_vendors2_v xvv_s ' -- 仕入先情報VIEW2 取引先
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
/*
      || '  ,('
      || '    SELECT'
      || '      xvv_a.vendor_id        AS vendor_id'
      || '     ,xvv_a.segment1         AS segment1'
      || '     ,xvv_a.vendor_full_name AS vendor_full_name'
      || '    FROM xxcmn_vendors2_v xvv_a'
      || '    WHERE'
      || '      xvv_a.start_date_active <= '
      || '        FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '    AND ((xvv_a.end_date_active >= '
      || '      FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                            || gc_char_d_format || '''))'
      || '      OR (xvv_a.end_date_active IS NULL)) '
      || '   ) xvv_a' -- 仕入先情報VIEW2 斡旋
*/
      || '  ,xxcmn_vendors2_v xvv_a '
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
-- 2019/08/30 Ver1.22 Add Start
      || '  ,xxcmm_item_tax_rate_v  xitrv '
      || '  ,xxcmn_lookup_values2_v xlv2 '
-- 2019/08/30 Ver1.22 Add End
      || ' WHERE '
      -- 斡旋者
      || '   xvv_a.vendor_id(+) = comm.attribute3 '
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
      || '   AND NVL(xvv_a.start_date_active, FND_DATE.STRING_TO_DATE(''1900/01/01'',''YYYY/MM/DD'')) <= '
      || '        FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '   AND ((NVL(xvv_a.end_date_active, FND_DATE.STRING_TO_DATE(''9999/12/31'',''YYYY/MM/DD'')) >= '
      || '     FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                            || gc_char_d_format || '''))'
      || '      OR (xvv_a.end_date_active IS NULL)) '
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
      -- 取引先
      || '   AND xvv_s.start_date_active <= '
      || '     FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                           || gc_char_d_format || ''')'
      || '   AND ((xvv_s.end_date_active >= '
      || '     FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                           || gc_char_d_format || '''))'
      || '     OR (xvv_s.end_date_active IS NULL)) '
-- 2019/08/30 Ver1.22 Mod Start
--      || '   AND xvv_s.vendor_id = comm.vendor_id ';
      || '   AND xvv_s.vendor_id = comm.vendor_id '
      -- 税率
      || '   AND comm.item_id  =  xitrv.item_id '
      || '   AND TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''') >= xitrv.start_date_active '
      || '   AND TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''') <= NVL(xitrv.end_date_active ,TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''')) '
      -- 税区分
      || '   AND xitrv.tax_code_ex = xlv2.lookup_code '
      || '   AND xlv2.lookup_type  = ''' || cv_xxpo_tax_type || ''''
      || '   AND TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''' ) >= xlv2.start_date_active '
      || '   AND TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''') <= NVL(xlv2.end_date_active ,TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''')) ';
-- 2019/08/30 Ver1.22 Mod End
--
      -- パラメータ斡旋者
      IF (ir_param.assen_vendor_code.COUNT = gn_one) THEN
        -- 1件のみ
        lv_sql := lv_sql
          || '     AND xvv_a.segment1 = ''' || ir_param.assen_vendor_code(gn_one) || '''';
      ELSIF (ir_param.assen_vendor_code.COUNT > gn_one) THEN
        -- 1件以上
        lv_in := fnc_get_in_statement(ir_param.assen_vendor_code);
        lv_sql := lv_sql
          || '     AND xvv_a.segment1 IN(' || lv_in || ') ';
      END IF;
      -- パラ取引先
      IF (ir_param.vendor_code.COUNT = gn_one) THEN
        -- 1件のみ
        lv_sql := lv_sql
          || '     AND xvv_s.segment1 = ''' || ir_param.vendor_code(gn_one) || '''';
      ELSIF (ir_param.vendor_code.COUNT > gn_one) THEN
        -- 1件以上
        lv_in := fnc_get_in_statement(ir_param.vendor_code);
        lv_sql := lv_sql
          || '     AND xvv_s.segment1 IN(' || lv_in || ') ';
      END IF;
--
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || ' ORDER BY'
      || '  segment1_s' -- 仕入先コード
      || ' ,segment1_a' -- 斡旋者コード
-- 2009/06/02 v1.16 T.Yoshimoto Add Start 本番#1516
      || ' ,attribute10' -- 発注部署コード
-- 2009/06/02 v1.16 T.Yoshimoto Add End 本番#1516
-- 2019/08/30 Ver1.22 Add Start
      || ' ,TO_NUMBER(xlv2.attribute1)' -- ソート順
-- 2019/08/30 Ver1.22 Add End
      ;
--
--      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_sql) ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- オープン
    OPEN lc_ref FOR lv_sql;
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    -- カーソルクローズ
    CLOSE lc_ref;
    IF ( ot_data_rec.COUNT = 0 ) THEN
      -- 取得データが０件の場合
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data ;
--
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
  /**********************************************************************************
   * Procedure Name   : prc_edit_data
   * Description      : ＸＭＬデータ作成(F-3-2)
   ***********************************************************************************/
  PROCEDURE prc_edit_data(
      ov_errbuf         OUT VARCHAR2           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2           -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
     ,it_data_rec       IN  tab_data_type_dtl2 -- 取得レコード群
     ,ot_data_rec       OUT tab_data_type_dtl  -- 取得レコード群(編集後)
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_edit_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル定数 ***
-- 2019/08/30 Ver1.22 Add Start
    cv_lookup_koza_type CONSTANT VARCHAR2(16) := 'XXCSO1_KOZA_TYPE';
    cv_flag_y           CONSTANT VARCHAR2(1)  := 'Y';                -- フラグ:Y
    cv_flag_n           CONSTANT VARCHAR2(1)  := 'N';                -- フラグ:N
-- 2019/08/30 Ver1.22 Add End
--
    -- *** ローカル変数 ***
    ln_count      NUMBER DEFAULT 1;
    ln_loop_index NUMBER DEFAULT 0;
-- 2019/08/30 Ver1.22 Add Start
    ln_line_count NUMBER DEFAULT 0;
    ln_loop_tax   NUMBER DEFAULT 1;
-- 2019/08/30 Ver1.22 Add End
--
    lv_dept_code     VARCHAR2(4);
    lv_assen_no      VARCHAR2(4);
    lv_siire_no      VARCHAR2(4);
-- 2019/08/30 Ver1.22 Add Start
    lv_tax_code      VARCHAR2(4);
-- 2019/08/30 Ver1.22 Add End
--
    -- 金額計算用
    ln_siire                NUMBER DEFAULT 0;         -- 仕入金額
    ln_kousen               NUMBER DEFAULT 0;         -- 口銭金額
    ln_kobiki_gaku          NUMBER DEFAULT 0;         -- 粉引額
    ln_fuka                 NUMBER DEFAULT 0;         -- 賦課金額
--
    ln_sum_qty              NUMBER DEFAULT 0;         -- 入庫総数
    ln_sum_conv_qty         NUMBER DEFAULT 0;         -- 入庫総数(換算後)
    ln_kobikigo_tanka       NUMBER DEFAULT 0;         -- 粉引後単価
    ln_sum_siire            NUMBER DEFAULT 0;         -- 仕入金額
    ln_sum_kosen            NUMBER DEFAULT 0;         -- 口銭金額
    ln_sum_fuka             NUMBER DEFAULT 0;         -- 賦課金額
    ln_sum_sasihiki         NUMBER DEFAULT 0;         -- 差引金額
    ln_sum_tax_siire        NUMBER DEFAULT 0;         -- 消費税(仕入金額)
    ln_sum_tax_kousen       NUMBER DEFAULT 0;         -- 消費税(口銭金額)
    ln_sum_tax_sasihiki     NUMBER DEFAULT 0;         -- 消費税(差引金額)
    ln_sum_jun_siire        NUMBER DEFAULT 0;         -- 純仕入金額
    ln_sum_jun_kosen        NUMBER DEFAULT 0;         -- 純口銭金額
    ln_sum_jun_sasihiki     NUMBER DEFAULT 0;         -- 純差引金額
--
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
    -- 消費税取得用
    lv_tax            fnd_lookup_values.lookup_code%TYPE; -- 消費税
    ld_tax_date                                     DATE; -- 消費税基準日
-- 2019/08/30 Ver1.22 Add Start
    lv_comm_price_tax_kbn fnd_lookup_values.attribute1%TYPE; -- 税区分（標準）
    lv_comm_price_tax_kbn_1 fnd_lookup_values.attribute1%TYPE; -- ブレイク時出力用税区分（標準）
    -- 振込先情報取得用
    lt_bank_name             ap_bank_branches.bank_name%TYPE;                   -- 金融機関名
    lt_bank_branch_name      ap_bank_branches.bank_branch_name%TYPE;            -- 支店名
    lv_bank_account_type     VARCHAR2(4);                                       -- 預金区分
    lt_bank_account_num      ap_bank_accounts_all.bank_account_num%TYPE;        -- 口座No
    lt_bank_account_name_alt ap_bank_accounts_all.account_holder_name_alt%TYPE; -- 口座名義ｶﾅ
--
    lv_break_flg             VARCHAR2(1);                                       -- ブレイクフラグ
    lv_break_init_flg        VARCHAR2(1);                                       -- ブレイク初期化フラグ
--
-- 2019/08/30 Ver1.22 Add End
    -- *** ローカル・例外処理 ***
    get_value_expt    EXCEPTION ;     -- 値取得エラー
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- ==========================
    --  ブレイク用変数初期化
    -- ==========================
    lv_dept_code   := it_data_rec(1).attribute10;               -- 部署コード
    lv_assen_no    := NVL(it_data_rec(1).segment1_a, 'NULL');   -- 斡旋者コード
    lv_siire_no    := it_data_rec(1).segment1_s;                -- 仕入先コード
-- 2019/08/30 Ver1.22 Add Start
    lv_tax_code    := it_data_rec(1).tax_code;                  -- 税コード
--
    gt_tax_kbn_bd_tab.DELETE;                            -- 税区分
    gt_tax_kbn_bd_1_tab.DELETE;                          -- 税区分_税区分内訳出力用
    gt_p_amount_bd_tab.DELETE;                           -- 仕入金額(税抜)
    gt_p_amount_tax_bd_tab.DELETE;                       -- 仕入消費税
    gt_unit_price_rate_bd_tab.DELETE;                    -- 口銭金額(税抜)
    gt_unit_price_rate_tax_bd_tab.DELETE;                -- 口銭消費税
    gt_l_unit_price_rate_bd_tab.DELETE;                  -- 賦課金
    gt_l_u_price_rate_tax_bd_tab.DELETE;                 -- 賦課金消費税
    gt_tax_exc_amount_bd_tab.DELETE;                     -- 合計(税抜金額)
    gt_ded_amount_tax_bd_tab.DELETE;                     -- 合計(消費税)
--
    lv_break_flg      := cv_flag_y;                      -- ブレイクフラグ
    lv_break_init_flg := cv_flag_n;                      -- ブレイク初期化フラグ
-- 2019/08/30 Ver1.22 Add End
--
    <<main_data_loop>>
    FOR ln_loop_index IN 1..it_data_rec.COUNT LOOP
--
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
      -- ====================================================
      -- 基準日取得
      -- ====================================================
      -- 基準日を取得
        ld_tax_date := FND_DATE.STRING_TO_DATE (it_data_rec(ln_loop_index).tax_date ,gc_char_d_format);
--
      -- 基準日より消費税を取得
      BEGIN
        SELECT
          flv.lookup_code
-- 2019/08/30 Ver1.22 Add Start
         ,flv.attribute1
-- 2019/08/30 Ver1.22 Add End
        INTO
          lv_tax
-- 2019/08/30 Ver1.22 Add Start
         ,lv_comm_price_tax_kbn
-- 2019/08/30 Ver1.22 Add End
        FROM
          xxcmn_lookup_values2_v flv
        WHERE
          flv.lookup_type = gv_xxcmn_consumption_tax_rate
        AND ((flv.start_date_active <= ld_tax_date )
          OR (flv.start_date_active IS NULL))
        AND ((flv.end_date_active   >= ld_tax_date )
          OR (flv.end_date_active   IS NULL));
--
        EXCEPTION
              -- データなし
          WHEN NO_DATA_FOUND THEN
          -- メッセージセット
            lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                                  ,'APP-XXPO-10127'
                                                  ,'ENTRY'
                                                  ,'消費税率'
                                                  ,'TABLE'
                                                  ,'xxcmn_lookup_values2_v' ||  '、' || it_data_rec(ln_loop_index).tax_date ) ;
            lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
--
      -- 消費税係数
      gn_tax := TO_NUMBER(lv_tax) / 100;
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
--
-- 2019/08/30 Ver1.22 Mod Start
      --初回件数取得
      IF (ln_line_count = 0) THEN
        ln_line_count := 1;
      END IF;
-- 2019/08/30 Ver1.22 Mod End
--
      -- ==========================
      --  レコードをブレイク
      -- ==========================
      -- 部署コード/仕入先/斡旋者/税コードが変更した場合
      IF ( ( lv_dept_code <> it_data_rec(ln_loop_index).attribute10 )
        OR ( lv_assen_no <> NVL(it_data_rec(ln_loop_index).segment1_a, 'NULL') )
-- 2019/08/30 Ver1.22 Mod Start
--        OR ( lv_siire_no <> it_data_rec(ln_loop_index).segment1_s ) ) THEN
        OR ( lv_siire_no <> it_data_rec(ln_loop_index).segment1_s )
        OR ( lv_tax_code <> it_data_rec(ln_loop_index).tax_code) ) THEN
-- 2019/08/30 Ver1.22 Mod End
--
-- 2019/08/30 Ver1.22 Add Start
        -- 明細行数をカウント
--        ln_line_count := ln_line_count + 1;
--
        -- 仕入先が変更した場合
        IF (lv_siire_no <> NVL(it_data_rec(ln_loop_index).segment1_s, 'NULL')) THEN
          -- ブレイクフラグON
          lv_break_flg      := cv_flag_y;
          -- ブレイク初期化フラグOFF
          lv_break_init_flg := cv_flag_n;
--
          -- (明細行数) / (1ページ最大行数)の余りが表示可能明細数より大きい場合
          IF ( MOD(ln_line_count , gn_max_line_9) > gn_line_count ) THEN
            -- 帳票改ページフラグON
            ot_data_rec(ln_count).break_page_flg := cv_flag_y;
          ELSE
            -- 帳票改ページフラグOFF
            ot_data_rec(ln_count).break_page_flg := cv_flag_n;
          END IF;
--
          -- 明細行数初期化
          ln_line_count := 0;
--
        ELSE
          -- 明細行数をカウント
            ln_line_count := ln_line_count + 1;
--
        END IF;
--
        -- 工場コードより、振込先情報を取得
        BEGIN
          SELECT abb.bank_name                  bank_name                -- 金融機関名
                ,abb.bank_branch_name           bank_branch_name         -- 支店名
                ,flv.meaning                    bank_account_type        -- 預金区分名
                ,aba.bank_account_num           bank_account_num         -- 口座No
                ,aba.account_holder_name_alt    bank_account_name_alt    -- 口座名義ｶﾅ
          INTO   lt_bank_name
                ,lt_bank_branch_name
                ,lv_bank_account_type
                ,lt_bank_account_num
                ,lt_bank_account_name_alt
          FROM   ap_bank_account_uses_all  abaua       -- 口座使用情報テーブル
                ,ap_bank_accounts_all      aba         -- 銀行口座
                ,ap_bank_branches          abb         -- 銀行支店
                ,po_vendors                pv          -- 仕入先
                ,po_vendor_sites_all       pvsa_sales  -- 仕入先サイト(営業)
                ,po_vendor_sites_all       pvsa_mfg    -- 仕入先サイト(生産)
                ,xxcmn_lookup_values2_v    flv         -- クイックコード（口座種別）
          WHERE  abaua.external_bank_account_id = aba.bank_account_id
          AND    aba.bank_branch_id             = abb.bank_branch_id
          AND    ld_tax_date                    BETWEEN abaua.start_date
                                                AND     NVL(abaua.end_date ,ld_tax_date)
          AND    abaua.vendor_id                = pv.vendor_id
          AND    abaua.vendor_id                = pvsa_sales.vendor_id
          AND    abaua.vendor_site_id           = pvsa_sales.vendor_site_id
          AND    pvsa_sales.org_id              = gn_sales_org_id
          AND    pvsa_sales.vendor_site_code    = pvsa_mfg.attribute5
          AND    pvsa_mfg.org_id                = gn_sales_class
          AND    pvsa_mfg.vendor_site_code      = it_data_rec(ln_loop_index-1).factory_code -- 工場コード
          AND    aba.bank_account_type          = flv.lookup_code
          AND    flv.lookup_type                = cv_lookup_koza_type
          AND    ld_tax_date                    BETWEEN flv.start_date_active
                                                AND     NVL(flv.end_date_active ,ld_tax_date)
          ;
--
          EXCEPTION
                -- データなし
            WHEN NO_DATA_FOUND THEN
            -- メッセージセット
              lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                                    ,cv_msg_po_10296
                                                    ,cv_tkn_vendor
                                                    ,it_data_rec(ln_loop_index-1).segment1_s
                                                    ,cv_tkn_factory
                                                    ,it_data_rec(ln_loop_index-1).factory_code ) ;
              lv_retcode  := gv_status_error ;
            RAISE get_value_expt ;
        END;
-- 2019/08/30 Ver1.22 Add End
--
        --差引金額
        ln_sum_sasihiki     := ln_sum_siire - ln_sum_kosen - ln_sum_fuka;
--
-- 2009/06/02 v1.16 T.Yoshimoto Del Start 本番#1516
        --消費税(仕入金額)
        --ln_sum_tax_siire    := ROUND(NVL(ln_sum_siire, 0) * NVL(gn_tax , 0) ,0);
        --消費税(口銭金額)
        --ln_sum_tax_kousen   := ROUND(NVL(ln_sum_kosen, 0) * NVL(gn_tax , 0) ,0);
-- 2009/06/02 v1.16 T.Yoshimoto Del End 本番#1516
--
        --消費税(差引金額)
        ln_sum_tax_sasihiki := ln_sum_tax_siire - ln_sum_tax_kousen;
--
        --純仕入金額
        ln_sum_jun_siire    := ln_sum_siire + ln_sum_tax_siire;
        --純口銭金額
        ln_sum_jun_kosen    := ln_sum_kosen + ln_sum_tax_kousen;
        --純差引金額
        ln_sum_jun_sasihiki := ln_sum_sasihiki + ln_sum_tax_sasihiki;
--
        -- ==========================
        --  編集後レコードとして格納
        -- ==========================
        ot_data_rec(ln_count).segment1_s           := it_data_rec(ln_loop_index-1).segment1_s;       --仕入先番号
        ot_data_rec(ln_count).vendor_name          := it_data_rec(ln_loop_index-1).vendor_name;      --仕入先名称
        ot_data_rec(ln_count).zip                  := it_data_rec(ln_loop_index-1).zip;              --郵便番号
        ot_data_rec(ln_count).address_line1        := it_data_rec(ln_loop_index-1).address_line1;    --取引先住所１
        ot_data_rec(ln_count).address_line2        := it_data_rec(ln_loop_index-1).address_line2;    --取引先住所２
        ot_data_rec(ln_count).phone                := it_data_rec(ln_loop_index-1).phone;            --取引先電話
        ot_data_rec(ln_count).fax                  := it_data_rec(ln_loop_index-1).fax;              --取引先FAX
--
        ot_data_rec(ln_count).segment1_a           := it_data_rec(ln_loop_index-1).segment1_a;       --斡旋者仕入先番号
        ot_data_rec(ln_count).vendor_full_name     := it_data_rec(ln_loop_index-1).vendor_full_name; --斡旋者名１
--
        ot_data_rec(ln_count).attribute10          := it_data_rec(ln_loop_index-1).attribute10;      --部署コード
--
        ot_data_rec(ln_count).quantity             := ln_sum_qty;                                    --数量
        ot_data_rec(ln_count).purchase_amount      := ln_sum_siire;                                  --仕入金額
        ot_data_rec(ln_count).attribute5           := ln_sum_kosen;                                  --預り口銭金額
        ot_data_rec(ln_count).attribute8           := ln_sum_fuka;                                   --賦課金額
        ot_data_rec(ln_count).purchase_amount_tax  := ln_sum_tax_siire;                              --仕入金額(消費税)
        ot_data_rec(ln_count).attribute5_tax       := ln_sum_tax_kousen;                             --預かり口銭金額(消費税)
--
-- 2019/08/30 Ver1.22 Add Start
        ot_data_rec(ln_count).purchase_tax_kbn      := it_data_rec(ln_loop_index-1).attribute3;      --仕入税区分
        ot_data_rec(ln_count).comm_price_tax_kbn    := lv_comm_price_tax_kbn_1;                      --口銭税区分
--
        ot_data_rec(ln_count).bank_name             := lt_bank_name;                                 --金融機関名
        ot_data_rec(ln_count).bank_branch_name      := lt_bank_branch_name;                          --支店名
        ot_data_rec(ln_count).bank_account_type     := lv_bank_account_type;                         --預金区分
        ot_data_rec(ln_count).bank_account_num      := lt_bank_account_num;                          --口座No
        ot_data_rec(ln_count).bank_account_name_alt := lt_bank_account_name_alt;                     --口座名義ｶﾅ
--
-- 2019/08/30 Ver1.22 Add End
        -- ブレイク用変数へ代入
        lv_dept_code   := it_data_rec(ln_loop_index).attribute10;
        lv_assen_no    := NVL(it_data_rec(ln_loop_index).segment1_a, 'NULL');
        lv_siire_no    := it_data_rec(ln_loop_index).segment1_s;
-- 2019/08/30 Ver1.22 Add Start
        lv_tax_code    := it_data_rec(ln_loop_index).tax_code;
-- 2019/08/30 Ver1.22 Add End
--
        -- 金額計算用変数の初期化
        ln_siire             := 0;  -- 仕入金額
        ln_kousen            := 0;  -- 口銭金額
        ln_kobiki_gaku       := 0;  -- 粉引額
        ln_fuka              := 0;  -- 賦課金額
        ln_sum_qty           := 0;  -- 入庫総数(換算後)
        ln_kobikigo_tanka    := 0;  -- 粉引後単価
        ln_sum_siire         := 0;  -- 仕入金額
        ln_sum_kosen         := 0;  -- 口銭金額
        ln_sum_fuka          := 0;  -- 賦課金額
        ln_sum_sasihiki      := 0;  -- 差引金額
        ln_sum_tax_siire     := 0;  -- 消費税(仕入金額)
        ln_sum_tax_kousen    := 0;  -- 消費税(口銭金額)
        ln_sum_tax_sasihiki  := 0;  -- 消費税(差引金額)
        ln_sum_jun_siire     := 0;  -- 純仕入金額
        ln_sum_jun_kosen     := 0;  -- 純口銭金額
        ln_sum_jun_sasihiki  := 0;  -- 純差引金額
--
        -- カウントアップ
        ln_count := ln_count + 1;
      END IF;
--
      -- ==========================
      --  出力項目を計算
      -- ==========================
      -- 受入実績の場合
      IF (it_data_rec(ln_loop_index).txns_type = '1') THEN
-- 2009/08/10 v1.18 T.Yoshimoto Mod Start 本番#1596
/*
        -- 仕入金額(切捨て)
        ln_siire :=  TRUNC( NVL(it_data_rec(ln_loop_index).quantity, 0) *
                            NVL(it_data_rec(ln_loop_index).unit_price, 0) );
*/
        -- 仕入金額(四捨五入)
        ln_siire :=  ROUND( NVL(it_data_rec(ln_loop_index).quantity, 0) *
                            NVL(it_data_rec(ln_loop_index).unit_price, 0), 0);
-- 2009/08/10 v1.18 T.Yoshimoto Mod End 本番#1596
--
        -- 口銭金額
        -- 口銭区分が「率」の場合
        IF ( it_data_rec(ln_loop_index).kousen_k = '2' ) THEN
          -- 預かり口銭金額＝単価*数量*口銭/100
          ln_kousen := TRUNC( it_data_rec(ln_loop_index).kobiki_mae * 
                              NVL(it_data_rec(ln_loop_index).quantity, 0) * NVL(it_data_rec(ln_loop_index).kousen, 0) / 100 );
        -- 口銭区分が「円」の場合
        ELSIF ( it_data_rec(ln_loop_index).kousen_k = '1' ) THEN
          -- 預り口銭金額＝口銭*数量
          ln_kousen := TRUNC( NVL(it_data_rec(ln_loop_index).kousen, 0) * 
                              NVL(it_data_rec(ln_loop_index).quantity, 0));
        ELSE
          ln_kousen := 0;
        END IF;
--
        -- 賦課金額
        -- 賦課金区分が「率」の場合
        IF ( it_data_rec(ln_loop_index).fukakin_k = '2' ) THEN
--
          -- 粉引額＝単価 * 数量 * 粉引率 / 100
          ln_kobiki_gaku := it_data_rec(ln_loop_index).kobiki_mae * NVL(it_data_rec(ln_loop_index).quantity, 0) * 
                              NVL(it_data_rec(ln_loop_index).kobiki_rate,0) / 100;
          -- 賦課金額＝（単価 * 数量 - 粉引額）* 賦課率 / 100
          ln_fuka := TRUNC(( it_data_rec(ln_loop_index).kobiki_mae * 
                             NVL(it_data_rec(ln_loop_index).quantity, 0) - ln_kobiki_gaku) * 
                             NVL(it_data_rec(ln_loop_index).fukakin,0) / 100);
--
        -- 賦課金区分が「円」の場合
        ELSIF ( it_data_rec(ln_loop_index).fukakin_k = '1' ) THEN
          -- 賦課金額＝賦課金*数量
          ln_fuka := TRUNC( NVL(it_data_rec(ln_loop_index).fukakin,0) * NVL(it_data_rec(ln_loop_index).quantity, 0) );
        ELSE
          ln_fuka := 0;
        END IF;
--
      -- 発注あり返品/発注なし返品の場合
      ELSE
--
-- 2009/08/10 v1.18 T.Yoshimoto Mod Start 本番#1596
/*
        --仕入金額(切捨て)
        ln_siire  :=  TRUNC( NVL(it_data_rec(ln_loop_index).purchase_amount, 0));
*/
        --仕入金額(四捨五入)
        ln_siire  :=  ROUND( NVL(it_data_rec(ln_loop_index).purchase_amount, 0), 0);
-- 2009/08/10 v1.18 T.Yoshimoto Mod End 本番#1596
--
        --口銭金額
        ln_kousen := it_data_rec(ln_loop_index).attribute5;
--
        --賦課金額
        ln_fuka   := it_data_rec(ln_loop_index).attribute8;
--
      END IF;
--
      -- ==========================
      --  必要項目をサマリー
      -- ==========================
      --消費税(仕入金額)
-- 2019/08/30 Ver1.22 Mod Start
--      ln_sum_tax_siire    := ln_sum_tax_siire + (ROUND(NVL(ln_siire, 0) * gn_tax ,0));
      ln_sum_tax_siire    := ln_sum_tax_siire + (ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0));
-- 2019/08/30 Ver1.22 Mod End
      --消費税(口銭金額)
      ln_sum_tax_kousen   := ln_sum_tax_kousen + (ROUND(NVL(ln_kousen, 0) * gn_tax ,0));
      -- 入庫総数を加算
      ln_sum_qty          := ln_sum_qty + it_data_rec(ln_loop_index).quantity;
      -- 仕入金額を加算
      ln_sum_siire        := ln_sum_siire + ln_siire;
      -- 口銭金額を加算
      ln_sum_kosen        := ln_sum_kosen + ln_kousen;
      -- 賦課金額を加算
      ln_sum_fuka         := ln_sum_fuka + ln_fuka;
--
-- 2019/08/30 Ver1.22 Add Start
      -- 税区分内訳表計算
      <<tax_kbn_loop>>
      FOR ln_loop_tax IN 1..gt_description_tbl.COUNT LOOP
        -- カウントアップ
        gn_tax_kbn := gn_tax_kbn + 1;
--
        -- ブレイク後の場合
        IF(lv_break_flg = cv_flag_y) THEN
          -- 値設定
          gt_tax_kbn_bd_tab(gn_tax_kbn)             := gt_description_tbl(ln_loop_tax);  -- 税区分
          gt_tax_kbn_bd_1_tab(gn_tax_kbn)           := gt_attribute2_tbl(ln_loop_tax);   -- 税区分_税区分内訳出力用
          gt_p_amount_bd_tab(gn_tax_kbn)            := 0;                                -- 仕入金額(税抜)
          gt_p_amount_tax_bd_tab(gn_tax_kbn)        := 0;                                -- 仕入消費税
          gt_unit_price_rate_bd_tab(gn_tax_kbn)     := 0;                                -- 口銭金額(税抜)
          gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) := 0;                                -- 口銭消費税
          gt_l_unit_price_rate_bd_tab(gn_tax_kbn)   := 0;                                -- 賦課金
          gt_l_u_price_rate_tax_bd_tab(gn_tax_kbn)  := 0;                                -- 賦課金消費税
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := 0;                                -- 合計(税抜金額)
          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      := 0;                                -- 合計(消費税)
        -- ブレイクしていない場合
        ELSE
          -- 初期化
          IF (lv_break_init_flg = cv_flag_n) THEN
            gn_tax_kbn := gn_tax_kbn - gt_description_tbl.COUNT;
            lv_break_init_flg := cv_flag_y;
          END IF;
        END IF;
--
        -- 税区分が仕入税区分と口銭税区分と一致した場合 ※賦課金にて出力する為、税区分が対象外のデータを除く
        IF (gt_description_tbl(ln_loop_tax) = it_data_rec(ln_loop_index).tax_kbn)
          AND (gt_description_tbl(ln_loop_tax) <> gv_tax_kbn_0000)
          AND (it_data_rec(ln_loop_index).attribute3 = lv_comm_price_tax_kbn) THEN
          -- 金額の設定
          gt_p_amount_bd_tab(gn_tax_kbn)            := gt_p_amount_bd_tab(gn_tax_kbn)            + ln_siire;                                                    -- 仕入金額(税抜)
          gt_p_amount_tax_bd_tab(gn_tax_kbn)        := gt_p_amount_tax_bd_tab(gn_tax_kbn)        + ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0); -- 仕入消費税
          gt_unit_price_rate_bd_tab(gn_tax_kbn)     := gt_unit_price_rate_bd_tab(gn_tax_kbn)     + (ln_kousen * -1);                                            -- 口銭金額(税抜)(マイナス表示)
          gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) := gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) + (ROUND(NVL(ln_kousen, 0) * gn_tax ,0) * -1);                -- 口銭消費税(マイナス表示)
          -- 仕入金額(税抜) + 口銭金額(税抜)
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := gt_tax_exc_amount_bd_tab(gn_tax_kbn)      + ln_siire + (ln_kousen * -1);                                 -- 合計(税抜金額)
          -- 仕入消費税 + 口銭消費税
          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      :=   gt_ded_amount_tax_bd_tab(gn_tax_kbn)
                                                       + (ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0))
                                                       + ((ROUND(NVL(ln_kousen, 0) * gn_tax ,0)) * -1);                                                         -- 合計(消費税)
        END IF;
--
        -- 税区分が仕入税区分と一致し、口銭税区分と不一致となる場合 ※賦課金にて出力する為、税区分が対象外のデータを除く
        IF (gt_description_tbl(ln_loop_tax) = it_data_rec(ln_loop_index).tax_kbn)
          AND (gt_description_tbl(ln_loop_tax) <> gv_tax_kbn_0000)
          AND (it_data_rec(ln_loop_index).attribute3 <> lv_comm_price_tax_kbn) THEN
          -- 金額の設定
          gt_p_amount_bd_tab(gn_tax_kbn)            := gt_p_amount_bd_tab(gn_tax_kbn)            + ln_siire;                                                    -- 仕入金額(税抜)
          gt_p_amount_tax_bd_tab(gn_tax_kbn)        := gt_p_amount_tax_bd_tab(gn_tax_kbn)        + ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0); -- 仕入消費税
          -- 仕入金額(税抜) + 口銭金額(税抜)
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := gt_tax_exc_amount_bd_tab(gn_tax_kbn)      + ln_siire;                                                    -- 合計(税抜金額)
          -- 仕入消費税 + 口銭消費税
          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      :=   gt_ded_amount_tax_bd_tab(gn_tax_kbn)
                                                       + (ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0));                                         -- 合計(消費税)
        END IF;
--
        -- 税区分が口銭税区分と一致し、仕入税区分と不一致となる場合 ※賦課金にて出力する為、税区分が対象外のデータを除く
        IF (gt_description_tbl(ln_loop_tax) = lv_comm_price_tax_kbn)
          AND (gt_description_tbl(ln_loop_tax) <> gv_tax_kbn_0000)
          AND (it_data_rec(ln_loop_index).attribute3 <> lv_comm_price_tax_kbn) THEN
          gt_unit_price_rate_bd_tab(gn_tax_kbn)     := gt_unit_price_rate_bd_tab(gn_tax_kbn)     + (ln_kousen * -1);                                            -- 口銭金額(税抜)(マイナス表示)
          gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) := gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) + (ROUND(NVL(ln_kousen, 0) * gn_tax ,0) * -1);                -- 口銭消費税(マイナス表示)
          -- 仕入金額(税抜) + 口銭金額(税抜)
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := gt_tax_exc_amount_bd_tab(gn_tax_kbn)      + (ln_kousen * -1);                                            -- 合計(税抜金額)
          -- 仕入消費税 + 口銭消費税
          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      :=   gt_ded_amount_tax_bd_tab(gn_tax_kbn)
                                                       + ((ROUND(NVL(ln_kousen, 0) * gn_tax ,0)) * -1);                                                         -- 合計(消費税)
        END IF;
--
        -- 税区分が対象外の場合
        IF (gt_description_tbl(ln_loop_tax) = gv_tax_kbn_0000 ) THEN
          gt_l_unit_price_rate_bd_tab(gn_tax_kbn)   := gt_l_unit_price_rate_bd_tab(gn_tax_kbn)   + (ln_fuka * -1);                                              -- 賦課金(マイナス表示)
          gt_l_u_price_rate_tax_bd_tab(gn_tax_kbn)  := gt_l_u_price_rate_tax_bd_tab(gn_tax_kbn)  + (0 * -1);                                                    -- 賦課金消費税(マイナス表示)
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := gt_tax_exc_amount_bd_tab(gn_tax_kbn)      + (ln_fuka * -1);                                              -- 合計(税抜金額)
          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      := gt_ded_amount_tax_bd_tab(gn_tax_kbn)      + (0 * -1);                                                    -- 合計(消費税)
        END IF;
--
      END LOOP tax_kbn_loop;
--
      -- ブレイクフラグOFF
      lv_break_flg := cv_flag_n;
      -- ブレイク初期化フラグOFF
      lv_break_init_flg := cv_flag_n;
      --ブレイク時出力用口銭税区分保持
      lv_comm_price_tax_kbn_1 := lv_comm_price_tax_kbn;
--
-- 2019/08/30 Ver1.22 Add End
    END LOOP main_data_loop ;
--
--
    IF ( it_data_rec.COUNT > 0 ) THEN
--
      ln_loop_index := it_data_rec.COUNT;
--
      --差引金額
      ln_sum_sasihiki     := ln_sum_siire - ln_sum_kosen - ln_sum_fuka;
--
      --消費税(差引金額)
      ln_sum_tax_sasihiki := ln_sum_tax_siire - ln_sum_tax_kousen;
--
      --純仕入金額
      ln_sum_jun_siire    := ln_sum_siire + ln_sum_tax_siire;
      --純口銭金額
      ln_sum_jun_kosen    := ln_sum_kosen + ln_sum_tax_kousen;
      --純差引金額
      ln_sum_jun_sasihiki := ln_sum_sasihiki + ln_sum_tax_sasihiki;
--
-- 2019/08/30 Ver1.22 Add Start
      -- 工場コードより、振込先情報を取得
      BEGIN
        SELECT abb.bank_name                  bank_name                -- 金融機関名
              ,abb.bank_branch_name           bank_branch_name         -- 支店名
              ,flv.meaning                    bank_account_type        -- 預金区分名
              ,aba.bank_account_num           bank_account_num         -- 口座No
              ,aba.account_holder_name_alt    bank_account_name_alt    -- 口座名義ｶﾅ
        INTO   lt_bank_name
              ,lt_bank_branch_name
              ,lv_bank_account_type
              ,lt_bank_account_num
              ,lt_bank_account_name_alt
        FROM   ap_bank_account_uses_all  abaua       -- 口座使用情報テーブル
              ,ap_bank_accounts_all      aba         -- 銀行口座
              ,ap_bank_branches          abb         -- 銀行支店
              ,po_vendors                pv          -- 仕入先
              ,po_vendor_sites_all       pvsa_sales  -- 仕入先サイト(営業)
              ,po_vendor_sites_all       pvsa_mfg    -- 仕入先サイト(生産)
              ,xxcmn_lookup_values2_v    flv         -- クイックコード（口座種別）
        WHERE  abaua.external_bank_account_id = aba.bank_account_id
        AND    aba.bank_branch_id             = abb.bank_branch_id
-- 2019/11/12 Ver1.24 Add Start
        AND    ld_tax_date                    BETWEEN abaua.start_date
                                              AND     NVL(abaua.end_date ,ld_tax_date)
-- 2019/11/12 Ver1.24 Add End
        AND    abaua.vendor_id                = pv.vendor_id
        AND    abaua.vendor_id                = pvsa_sales.vendor_id
        AND    abaua.vendor_site_id           = pvsa_sales.vendor_site_id
        AND    pvsa_sales.org_id              = gn_sales_org_id
        AND    pvsa_sales.vendor_site_code    = pvsa_mfg.attribute5
        AND    pvsa_mfg.org_id                = gn_sales_class
        AND    pvsa_mfg.vendor_site_code      = it_data_rec(ln_loop_index).factory_code -- 工場コード
        AND    aba.bank_account_type          = flv.lookup_code
        AND    flv.lookup_type                = cv_lookup_koza_type
        AND    ld_tax_date                    BETWEEN flv.start_date_active
                                              AND     NVL(flv.end_date_active ,ld_tax_date)
        ;
--
        EXCEPTION
          -- データなし
          WHEN NO_DATA_FOUND THEN
          -- メッセージセット
            lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                                  ,cv_msg_po_10296
                                                  ,cv_tkn_vendor
                                                  ,it_data_rec(ln_loop_index).segment1_s
                                                  ,cv_tkn_factory
                                                  ,it_data_rec(ln_loop_index).factory_code ) ;
            lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
-- 2019/08/30 Ver1.22 Add End
      -- ==========================
      --  編集後レコードとして格納
      -- ==========================
      ot_data_rec(ln_count).segment1_s           := it_data_rec(ln_loop_index).segment1_s;       --仕入先番号
      ot_data_rec(ln_count).vendor_name          := it_data_rec(ln_loop_index).vendor_name;      --仕入先名称
      ot_data_rec(ln_count).zip                  := it_data_rec(ln_loop_index).zip;              --郵便番号
      ot_data_rec(ln_count).address_line1        := it_data_rec(ln_loop_index).address_line1;    --取引先住所１
      ot_data_rec(ln_count).address_line2        := it_data_rec(ln_loop_index).address_line2;    --取引先住所２
      ot_data_rec(ln_count).phone                := it_data_rec(ln_loop_index).phone;            --取引先電話
      ot_data_rec(ln_count).fax                  := it_data_rec(ln_loop_index).fax;              --取引先FAX
--
      ot_data_rec(ln_count).segment1_a           := it_data_rec(ln_loop_index).segment1_a;       --斡旋者仕入先番号
      ot_data_rec(ln_count).vendor_full_name     := it_data_rec(ln_loop_index).vendor_full_name; --斡旋者名１
--
      ot_data_rec(ln_count).attribute10          := it_data_rec(ln_loop_index).attribute10;      --部署コード
--
      ot_data_rec(ln_count).quantity             := ln_sum_qty;                                    --数量
      ot_data_rec(ln_count).purchase_amount      := ln_sum_siire;                                  --仕入金額
      ot_data_rec(ln_count).attribute5           := ln_sum_kosen;                                  --預り口銭金額
      ot_data_rec(ln_count).attribute8           := ln_sum_fuka;                                   --賦課金額
      ot_data_rec(ln_count).purchase_amount_tax  := ln_sum_tax_siire;                              --仕入金額(消費税)
      ot_data_rec(ln_count).attribute5_tax       := ln_sum_tax_kousen;                             --預かり口銭金額(消費税)
--
-- 2019/08/30 Ver1.22 Add Start
-- 2019/10/18 Ver1.23 H.Ishii Mod Start
--      ot_data_rec(ln_count).purchase_tax_kbn      := it_data_rec(ln_loop_index-1).attribute3;      --仕入税区分
      ot_data_rec(ln_count).purchase_tax_kbn      := it_data_rec(ln_loop_index).attribute3;        --仕入税区分
-- 2019/10/18 Ver1.23 H.Ishii Mod End
      ot_data_rec(ln_count).comm_price_tax_kbn    := lv_comm_price_tax_kbn;                        --口銭税区分
--
      ot_data_rec(ln_count).bank_name             := lt_bank_name;                                 --金融機関名
      ot_data_rec(ln_count).bank_branch_name      := lt_bank_branch_name;                          --支店名
      ot_data_rec(ln_count).bank_account_type     := lv_bank_account_type;                         --預金区分
      ot_data_rec(ln_count).bank_account_num      := lt_bank_account_num;                          --口座No
      ot_data_rec(ln_count).bank_account_name_alt := lt_bank_account_name_alt;                     --口座名義ｶﾅ
--
      -- (明細行数) / (1ページ最大行数)の余りが表示可能明細数より大きい場合
      IF ( MOD(ln_line_count ,gn_max_line_9) > gn_line_count ) THEN
        -- 最終仕入先の帳票改ページフラグON
        gv_break_page_flg := cv_flag_y;
      ELSE
        -- 帳票改ページフラグOFF
        gv_break_page_flg := cv_flag_n;
      END IF;
--
-- 2019/08/30 Ver1.22 Add End
    END IF;
--
-- 2013/07/05 v1.21 R.Watanabe Add Start E_本稼動_10839
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode ;
-- 2013/07/05 v1.21 R.Watanabe Add End E_本稼動_10839
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_edit_data;
-- 2009/05/26 v1.15 T.Yoshimoto Add End
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
     ,ir_param          IN  rec_param_data    -- パラメータ
     ,it_data_rec       IN  tab_data_type_dtl -- 取得レコード群
     ,ot_xml_data_table OUT XML_DATA          -- XMLデータ
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル定数 ***
    -- キーブレイク判断用
    lc_break_init           VARCHAR2(100) DEFAULT '*' ;            -- 初期値
    lc_break_null           VARCHAR2(100) DEFAULT '**' ;           -- ＮＵＬＬ判定
-- 2019/08/30 Ver1.22 Add Start
    cv_flag_y               CONSTANT VARCHAR2(1)  := 'Y';          -- フラグ:Y
-- 2019/08/30 Ver1.22 Add End
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_company_code         VARCHAR2(100) DEFAULT lc_break_init;   -- 会社コード
-- add start 1.10
    ln_vendor_name_len      NUMBER;                                -- 取引先名称文字数
-- add end 1.10
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;  -- 取得レコードなし
--
    lv_from_year            VARCHAR2(4); -- 期間開始：年
    lv_from_month           VARCHAR2(2); -- 期間開始：月
    lv_from_date            VARCHAR2(2); -- 期間開始：日
    lv_to_year              VARCHAR2(4); -- 期間終了：年
    lv_to_month             VARCHAR2(2); -- 期間終了：月
    lv_to_date              VARCHAR2(2); -- 期間終了：日
-- 2019/08/30 Ver1.22 Mod Start
--    lv_to_year_yy           VARCHAR2(2); -- 期間終了：年(YY)
    lv_year_yyyy            VARCHAR2(4); -- 期間：年(YYYY)
--
    ln_tax_kbn              NUMBER DEFAULT 1; -- 税区分内訳表カウント    
-- 2019/08/30 Ver1.22 Mod End
--
-- Del Start 1.20
--- lv_postal_code      xxcmn_locations2_v.zip%TYPE;           -- 郵便番号
--- lv_address          xxcmn_locations2_v.address_line1%TYPE; -- 住所
--- lv_tel_num          xxcmn_locations2_v.phone%TYPE;         -- 電話番号
--- lv_fax_num          xxcmn_locations2_v.fax%TYPE;           -- FAX番号
--- lv_dept_formal_name xxcmn_locations2_v.location_name%TYPE; -- 部署正式名
-- Del End 1.20
--
    ln_quantity                   NUMBER; -- 数量
    ln_purchase_amount            NUMBER; -- 仕入金額
    ln_purchase_amount_tax        NUMBER; -- 消費税:仕入金額
    ln_pure_purchase_amount       NUMBER; -- 純仕入金額
    ln_cupr_tax                   NUMBER; -- 消費税:口銭金額
    ln_pure_cupr_tax              NUMBER; -- 純口銭金額
    ln_deduction_amount           NUMBER; -- 差引金額
    ln_deduction_amount_tax       NUMBER; -- 消費税:差引金額
    ln_pure_deduction_amount      NUMBER; -- 純差引金額
--
    lt_xml_idx                NUMBER DEFAULT 0; -- ＸＭＬデータタグ表のインデックス
    lv_errmsg_no_data         VARCHAR2(5000);   -- データなしメッセージ
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    lv_from_year  := TO_CHAR(ir_param.d_deliver_from,gc_char_yyyy_format);
    lv_from_month := TO_CHAR(ir_param.d_deliver_from,gc_char_mm_format);
    lv_from_date  := TO_CHAR(ir_param.d_deliver_from,gc_char_dd_format);
    lv_to_year    := TO_CHAR(ir_param.d_deliver_to,gc_char_yyyy_format);
-- 2019/08/30 Ver1.22 Mod Start
--    lv_to_year_yy := TO_CHAR(ir_param.d_deliver_to,gc_char_yy_format);
    lv_year_yyyy  := TO_CHAR(ir_param.d_deliver_to,gc_char_yyyy_format);
-- 2019/08/30 Ver1.22 Mod End
    lv_to_month   := TO_CHAR(ir_param.d_deliver_to,gc_char_mm_format);
    lv_to_date    := TO_CHAR(ir_param.d_deliver_to,gc_char_dd_format);
    -- -----------------------------------------------------
    -- ユーザーＧ開始タグ出力
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
    -- 帳票ＩＤ
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_id' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := gv_report_id ;
    -- 実施日
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'exec_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- 年
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_name_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- 2019/08/30 Ver1.22 Mod Start
--    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_year_yy ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_year_yyyy ;
-- 2019/08/30 Ver1.22 Mod End
    -- 月
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_name_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_month ;
    -- 年：期間開始
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_year ;
    -- 月：期間開始
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_month ;
    -- 日：期間開始
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_date ;
    -- 年：期間終了
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_year ;
    -- 月：期間終了
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_month ;
    -- 日：期間終了
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_date ;
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 取引先ＬＧ開始タグ出力
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    -- 件数確認
    IF (it_data_rec.COUNT = gn_zero) THEN
      -- ０件メッセージ出力
      lv_errmsg_no_data := xxcmn_common_pkg.get_msg( gc_application_po
                                                   ,'APP-XXPO-00009' ) ;
--
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_company_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'msg' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := lv_errmsg_no_data;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    END IF;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..it_data_rec.COUNT LOOP
      -- =====================================================
      -- 取引先コードブレイク
      -- =====================================================
      -- 取引先コードが切り替わった場合
      IF ( NVL( it_data_rec(i).segment1_s, lc_break_null ) <> lv_company_code ) THEN
--
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_company_code <> lc_break_init ) THEN
          ------------------------------
          -- 斡旋者コードヘッダＧ終了タグ
          ------------------------------
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_mediator_code' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
-- 2019/08/30 Ver1.22 Add Start
          ------------------------------
          -- 改ページ
          ------------------------------
          IF (it_data_rec(i-1).break_page_flg = cv_flag_y) THEN
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'break_page' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := '' ;
          END IF;
          ------------------------------
          -- 税区分内訳表の出力
          ------------------------------
          <<tax_kbn_bd_loop>>
          FOR i IN 1..gt_description_tbl.COUNT LOOP
            ------------------------------
            -- 税区分内訳表ヘッダＧ開始タグ
            ------------------------------
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'g_tax_kbn' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
            -- 税区分
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'tax_kbn_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := gt_tax_kbn_bd_1_tab(ln_tax_kbn) ;
            -- 仕入金額(税抜)
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_p_amount_bd_tab(ln_tax_kbn) ,0) ;
            -- 仕入消費税
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_tax_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_p_amount_tax_bd_tab(ln_tax_kbn) ,0) ;
            -- 口銭金額(税抜)
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_unit_price_rate_bd_tab(ln_tax_kbn) ,0) ;
            -- 口銭消費税
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_tax_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_unit_price_rate_tax_bd_tab(ln_tax_kbn) ,0) ;
            -- 賦課金
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_l_unit_price_rate_bd_tab(ln_tax_kbn) ,0) ;
            -- 賦課金消費税
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_2_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_l_u_price_rate_tax_bd_tab(ln_tax_kbn) ,0) ;
            -- 合計(税抜金額)
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'tax_excluded_amount_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_tax_exc_amount_bd_tab(ln_tax_kbn) ,0) ;
            -- 合計(消費税)
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount_tax_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_ded_amount_tax_bd_tab(ln_tax_kbn) ,0) ;
--
            ------------------------------
            -- 税区分内訳表ヘッダＧ終了タグ
            ------------------------------
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := '/g_tax_kbn' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
            -- 出力回数カウントアップ
            ln_tax_kbn := ln_tax_kbn + 1;
          END LOOP tax_kbn_bd_loop;
-- 2019/08/30 Ver1.22 Add End
          ------------------------------
          -- 取引先コードヘッダＧ終了タグ
          ------------------------------
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/g_company_code' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 取引先Ｇ開始タグ出力
        -- -----------------------------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_company_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
-- 2019/08/30 Ver1.22 Del Start
---- add start 1.10
--        -- 取引先名の文字数取得
--        ln_vendor_name_len := LENGTH(it_data_rec(i).vendor_name);
---- add end 1.10
-- 2019/08/30 Ver1.22 Del End
        -- 取引先名１
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- 2019/08/30 Ver1.22 Mod Start
---- mod start 1.10
----        ot_xml_data_table(lt_xml_idx).tag_value :=
----          SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_15) ;
--        IF (ln_vendor_name_len <= gn_20) THEN
--          -- 敬称を付ける
--          ot_xml_data_table(lt_xml_idx).tag_value :=
--            SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_20) || gv_keishou ;
--        ELSE
--          ot_xml_data_table(lt_xml_idx).tag_value :=
--            SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_20) ;
--        END IF;
---- mod end 1.10
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_15) ;
-- 2019/08/30 Ver1.22 Mod End
        -- 取引先名２
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_name2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- 2019/08/30 Ver1.22 Mod Start
---- mod start 1.10
----        ot_xml_data_table(lt_xml_idx).tag_value :=
----          SUBSTR(it_data_rec(i).vendor_name,gn_16,gn_30) ;
--        IF (ln_vendor_name_len >= gn_21) THEN
--          -- 敬称を付ける
--          ot_xml_data_table(lt_xml_idx).tag_value :=
--            SUBSTR(it_data_rec(i).vendor_name,gn_21,gn_40) || gv_keishou ;
--        ELSE
--          ot_xml_data_table(lt_xml_idx).tag_value :=
--            SUBSTR(it_data_rec(i).vendor_name,gn_21,gn_40) ;
--        END IF;
---- mod end 1.10
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(it_data_rec(i).vendor_name,gn_16,gn_30) ;
-- 2019/08/30 Ver1.22 Mod End
        -- 貴社コード
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'your_company_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).segment1_s ;
        -- 郵便番号
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_postal_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).zip ;
        -- 取引先住所１
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_address' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).address_line1,gn_one,gn_15) ;
        -- 取引先住所２
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_address2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).address_line2,gn_one,gn_15) ;
        -- 取引先TEL
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_telephone_number' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).phone,gn_one,gn_15) ;
        -- 取引先FAX
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_fax_number' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).fax,gn_one,gn_15) ;
--
        -- 部署情報の取得
-- Del Start 1.20
------- xxcmn_common_pkg.get_dept_info(
-------   iv_dept_cd          => it_data_rec(i).attribute10  -- 部署コード(事業所CD)
-------  ,id_appl_date        => ir_param.d_deliver_from -- 基準日
-------  ,ov_postal_code      => lv_postal_code      -- 郵便番号
-------  ,ov_address          => lv_address          -- 住所
-------  ,ov_tel_num          => lv_tel_num          -- 電話番号
-------  ,ov_fax_num          => lv_fax_num          -- FAX番号
-------  ,ov_dept_formal_name => lv_dept_formal_name -- 部署正式名
-------  ,ov_errbuf           => lv_errbuf
-------  ,ov_retcode          => lv_retcode
-------  ,ov_errmsg           => lv_errmsg);
-- Del End 1.20
--
-- 2019/08/30 Ver1.22 Mod Start
--        -- 送付元住所
--        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
--        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_address' ;
--        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
---- Mod Start 1.20
--------- ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_address,gn_one,gn_15) ;
--        ot_xml_data_table(lt_xml_idx).tag_value := NULL;
---- Mod End 1.20
--        -- 送付元TEL
--        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
--        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_telephone_number' ;
--        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
---- Mod Start 1.20
--------- ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_tel_num,gn_one,gn_15) ;
--        ot_xml_data_table(lt_xml_idx).tag_value := NULL ;
---- Mod End 1.20
--        -- 送付元FAX
--        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
--        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_fax_number' ;
--        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
---- Mod Start 1.20
--------- ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_fax_num,gn_one,gn_15) ;
--        ot_xml_data_table(lt_xml_idx).tag_value := NULL;
---- Mod End 1.20
--        -- 送付元部署
--        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
--        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_dept_name' ;
--        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
---- Mod Start 1.20
--------- ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_dept_formal_name,gn_one,gn_15) ;
--        ot_xml_data_table(lt_xml_idx).tag_value := NULL;
---- Mod End 1.20
        ------------------------------
        -- 請求先情報
        ------------------------------
        -- 請求先名
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_dept_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := gv_from_dept_name;
        -- 請求先郵便番号
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_postal_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := gv_from_postal_code;
        -- 請求先住所
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_address' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := gv_from_address;
--
        ------------------------------
        -- 振込先情報
        ------------------------------
        -- 金融機関名
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).bank_name ;
        -- 支店名
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_brach_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).bank_branch_name ;
        -- 預金区分
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_account_type' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).bank_account_type ;
        -- 口座No.
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_account_num' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).bank_account_num ;
        -- 口座名義1
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_account_name_alt1' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(it_data_rec(i).bank_account_name_alt,gn_one,gn_75) ;
        -- 口座名義2
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_account_name_alt2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(it_data_rec(i).bank_account_name_alt,gn_76,gn_150) ;
--
-- 2019/08/30 Ver1.22 Mod End
        ------------------------------
        -- 斡旋者ヘッダ
        ------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_mediator_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_company_code  := NVL( it_data_rec(i).segment1_s, lc_break_null )  ;
--
      END IF ;
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
      -- 明細クリア
      ln_quantity              := 0; -- 数量
      ln_purchase_amount       := 0; -- 仕入金額
      ln_purchase_amount_tax   := 0; -- 消費税:仕入金額
      ln_pure_purchase_amount  := 0; -- 純仕入金額
      ln_cupr_tax              := 0; -- 消費税:口銭金額
      ln_pure_cupr_tax         := 0; -- 純口銭金額
      ln_deduction_amount      := 0; -- 差引金額
      ln_deduction_amount_tax  := 0; -- 消費税:差引金額
      ln_pure_deduction_amount := 0; -- 純差引金額
      -- -----------------------------------------------------
      -- 明細
      -- -----------------------------------------------------
      -- 斡旋者ヘッダ
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      -- 斡旋者コード
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).segment1_a;
      -- 斡旋者名
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_one,gn_10) ;
      -- 斡旋者名２
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name2' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_11,gn_20) ;
      -- 斡旋者名３
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name3' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_21,gn_30) ;
      -- 数量
      ln_quantity := ROUND(it_data_rec(i).quantity,3);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'quantity' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_quantity);
      -- 仕入金額
-- 2009/08/10 v1.18 T.Yoshimoto Mod Start 本番#1596(四捨五入化)
-- 2008/11/04 v1.11 Y.Yamamoto update start
      ln_purchase_amount := ROUND(it_data_rec(i).purchase_amount);
--      ln_purchase_amount := TRUNC(it_data_rec(i).purchase_amount);
-- 2008/11/04 v1.11 Y.Yamamoto update end
-- 2009/08/10 v1.18 T.Yoshimoto Mod End 本番#1596(四捨五入化)
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_purchase_amount);
      -- 消費税:仕入金額
-- 2009/01/08 v1.13 N.Yoshida Mod Start 本番#970
--      ln_purchase_amount_tax := ROUND(ln_purchase_amount * gn_tax);
      ln_purchase_amount_tax := it_data_rec(i).purchase_amount_tax;
-- 2009/01/08 v1.13 N.Yoshida Mod End 本番#970
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_tax' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_purchase_amount_tax);
      -- 純仕入金額
      ln_pure_purchase_amount := ln_purchase_amount + ln_purchase_amount_tax;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_purchase_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_purchase_amount);
-- 2019/08/30 Ver1.22 Add Start
      -- 仕入税区分
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_tax_kbn' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).purchase_tax_kbn;
-- 2019/08/30 Ver1.22 Add End
      -- 口銭
      IF (it_data_rec(i).attribute5 IS NOT NULL) THEN
        -- 口銭金額
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).attribute5;
        -- 消費税:口銭金額
-- 2009/01/08 v1.13 N.Yoshida Mod Start 本番#970
--        ln_cupr_tax := ROUND(it_data_rec(i).attribute5 * gn_tax);
        ln_cupr_tax := it_data_rec(i).attribute5_tax;
-- 2009/01/08 v1.13 N.Yoshida Mod End 本番#970
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_tax' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_cupr_tax);
        -- 純口銭金額
        ln_pure_cupr_tax := it_data_rec(i).attribute5 + ln_cupr_tax;
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_commission_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_cupr_tax);
-- 2019/08/30 Ver1.22 Add Start
        -- 口銭税区分
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_tax_kbn' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).comm_price_tax_kbn;
-- 2019/08/30 Ver1.22 Add End
      END IF;
      -- 賦課
      IF (it_data_rec(i).attribute8 IS NOT NULL) THEN
        -- 賦課金額
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(it_data_rec(i).attribute8);
        -- 賦課金額(3段目)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(it_data_rec(i).attribute8);
      END IF;
      -- 差引金額
      ln_deduction_amount :=
        ln_purchase_amount - NVL(it_data_rec(i).attribute5,0) - NVL(it_data_rec(i).attribute8,0);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_deduction_amount);
      -- 消費税:差引金額
      ln_deduction_amount_tax := ln_purchase_amount_tax - ln_cupr_tax;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount_tax' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_deduction_amount_tax);
      -- 純差引金額
      ln_pure_deduction_amount :=
        ln_pure_purchase_amount - ln_pure_cupr_tax - NVL(it_data_rec(i).attribute8,0);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_deduction_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_deduction_amount);
      -- 斡旋者ヘッダ
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 斡旋者コードＧ終了タグ
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_mediator_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
-- 2019/08/30 Ver1.22 Add Start
    -- 件数確認
    IF (it_data_rec.COUNT <> gn_zero) THEN
      ------------------------------
      -- 改ページ
      ------------------------------
      IF (gv_break_page_flg = cv_flag_y) THEN
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'break_page' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := '' ;
      END IF;
      ------------------------------
      -- 税区分内訳表の出力
      ------------------------------
      <<tax_kbn_bd_loop>>
      FOR i IN 1..gt_description_tbl.COUNT LOOP
        ------------------------------
        -- 税区分内訳表ヘッダＧ開始タグ
        ------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_tax_kbn' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
        -- 税区分
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'tax_kbn_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
--        ot_xml_data_table(lt_xml_idx).tag_value := gt_tax_kbn_bd_tab(ln_tax_kbn) ;
        ot_xml_data_table(lt_xml_idx).tag_value := gt_tax_kbn_bd_1_tab(ln_tax_kbn) ;
        -- 仕入金額(税抜)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_p_amount_bd_tab(ln_tax_kbn) ,0) ;
        -- 仕入消費税
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_tax_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_p_amount_tax_bd_tab(ln_tax_kbn) ,0) ;
        -- 口銭金額(税抜)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_unit_price_rate_bd_tab(ln_tax_kbn) ,0) ;
        -- 口銭消費税
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_tax_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_unit_price_rate_tax_bd_tab(ln_tax_kbn) ,0) ;
        -- 賦課金
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_l_unit_price_rate_bd_tab(ln_tax_kbn) ,0) ;
        -- 賦課金消費税
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_2_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_l_u_price_rate_tax_bd_tab(ln_tax_kbn) ,0) ;
        -- 合計(税抜金額)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'tax_excluded_amount_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_tax_exc_amount_bd_tab(ln_tax_kbn) ,0) ;
        -- 合計(消費税)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount_tax_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_ded_amount_tax_bd_tab(ln_tax_kbn) ,0) ;
--
        ------------------------------
        -- 税区分内訳表ヘッダＧ終了タグ
        ------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := '/g_tax_kbn' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
        -- 出力回数カウントアップ
        ln_tax_kbn := ln_tax_kbn + 1;
      END LOOP tax_kbn_bd_loop;
    END IF;
-- 2019/08/30 Ver1.22 Add End
    ------------------------------
    -- 取引先コードＧ終了タグ
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/g_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 取引先ＬＧ終了タグ
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- データＬＧ終了タグ
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_create_xml_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_set_param
   * Description      : パラメータの取得
   ***********************************************************************************/
  PROCEDURE prc_set_param(
      ov_errbuf             OUT VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_deliver_from       IN  VARCHAR2       -- 納入日FROM
     ,iv_deliver_to         IN  VARCHAR2       -- 納入日TO
     ,iv_vendor_code1       IN  VARCHAR2       -- 取引先１
     ,iv_vendor_code2       IN  VARCHAR2       -- 取引先２
     ,iv_vendor_code3       IN  VARCHAR2       -- 取引先３
     ,iv_vendor_code4       IN  VARCHAR2       -- 取引先４
     ,iv_vendor_code5       IN  VARCHAR2       -- 取引先５
     ,iv_assen_vendor_code1 IN  VARCHAR2       -- 斡旋者１
     ,iv_assen_vendor_code2 IN  VARCHAR2       -- 斡旋者２
     ,iv_assen_vendor_code3 IN  VARCHAR2       -- 斡旋者３
     ,iv_assen_vendor_code4 IN  VARCHAR2       -- 斡旋者４
     ,iv_assen_vendor_code5 IN  VARCHAR2       -- 斡旋者５
     ,iv_dept_code1         IN  VARCHAR2       -- 担当部署１
     ,iv_dept_code2         IN  VARCHAR2       -- 担当部署２
     ,iv_dept_code3         IN  VARCHAR2       -- 担当部署３
     ,iv_dept_code4         IN  VARCHAR2       -- 担当部署４
     ,iv_dept_code5         IN  VARCHAR2       -- 担当部署５
     ,iv_security_flg       IN  VARCHAR2       -- セキュリティ区分
     ,or_param_rec          OUT rec_param_data -- 入力パラメータ群
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_set_param' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_vendor_code       NUMBER DEFAULT 0; -- 取引先
    ln_assen_vendor_code NUMBER DEFAULT 0; -- 斡旋者
    ln_dept_code         NUMBER DEFAULT 0; -- 担当部署
--
    -- *** ローカル・例外処理 ***
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 納入日(FROM)日付型
    or_param_rec.d_deliver_from := FND_DATE.STRING_TO_DATE(iv_deliver_from,gc_char_dt_format);
    -- 納入日(TO)  日付型
    or_param_rec.d_deliver_to   := FND_DATE.STRING_TO_DATE(iv_deliver_to,gc_char_dt_format);
    -- 納入日(FROM)
    or_param_rec.deliver_from   := TO_CHAR(or_param_rec.d_deliver_from ,gc_char_d_format);
    -- 納入日(TO)
    or_param_rec.deliver_to     := TO_CHAR(or_param_rec.d_deliver_to ,gc_char_d_format);
    -- セキュリティ区分
    or_param_rec.security_flg   := iv_security_flg;
--
    -- 取引先１
    IF (TRIM(iv_vendor_code1) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code1;
    END IF;
    -- 取引先２
    IF (TRIM(iv_vendor_code2) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code2;
    END IF;
    -- 取引先３
    IF (TRIM(iv_vendor_code3) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code3;
    END IF;
    -- 取引先４
    IF (TRIM(iv_vendor_code4) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code4;
    END IF;
    -- 取引先５
    IF (TRIM(iv_vendor_code5) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code5;
    END IF;
--
    -- 斡旋者１
    IF (TRIM(iv_assen_vendor_code1) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code1;
    END IF;
    -- 斡旋者２
    IF (TRIM(iv_assen_vendor_code2) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code2;
    END IF;
    -- 斡旋者３
    IF (TRIM(iv_assen_vendor_code3) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code3;
    END IF;
    -- 斡旋者４
    IF (TRIM(iv_assen_vendor_code4) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code4;
    END IF;
    -- 斡旋者５
    IF (TRIM(iv_assen_vendor_code5) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code5;
    END IF;
--
    -- 担当部署１
    IF (TRIM(iv_dept_code1) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code1;
    END IF;
    -- 担当部署２
    IF (TRIM(iv_dept_code2) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code2;
    END IF;
    -- 担当部署３
    IF (TRIM(iv_dept_code3) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code3;
    END IF;
    -- 担当部署４
    IF (TRIM(iv_dept_code4) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code4;
    END IF;
    -- 担当部署５
    IF (TRIM(iv_dept_code5) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code5;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_set_param ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf             OUT VARCHAR2        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2        -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_deliver_from       IN  VARCHAR2        -- 納入日FROM
     ,iv_deliver_to         IN  VARCHAR2        -- 納入日TO
     ,iv_vendor_code1       IN  VARCHAR2        -- 取引先１
     ,iv_vendor_code2       IN  VARCHAR2        -- 取引先２
     ,iv_vendor_code3       IN  VARCHAR2        -- 取引先３
     ,iv_vendor_code4       IN  VARCHAR2        -- 取引先４
     ,iv_vendor_code5       IN  VARCHAR2        -- 取引先５
     ,iv_assen_vendor_code1 IN  VARCHAR2        -- 斡旋者１
     ,iv_assen_vendor_code2 IN  VARCHAR2        -- 斡旋者２
     ,iv_assen_vendor_code3 IN  VARCHAR2        -- 斡旋者３
     ,iv_assen_vendor_code4 IN  VARCHAR2        -- 斡旋者４
     ,iv_assen_vendor_code5 IN  VARCHAR2        -- 斡旋者５
     ,iv_dept_code1         IN  VARCHAR2        -- 担当部署１
     ,iv_dept_code2         IN  VARCHAR2        -- 担当部署２
     ,iv_dept_code3         IN  VARCHAR2        -- 担当部署３
     ,iv_dept_code4         IN  VARCHAR2        -- 担当部署４
     ,iv_dept_code5         IN  VARCHAR2        -- 担当部署５
     ,iv_security_flg       IN  VARCHAR2        -- セキュリティ区分
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1) ;                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000) ;                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lr_param_rec         rec_param_data ;          -- パラメータ受渡し用
--
    lv_xml_string        VARCHAR2(32000) ;
    ln_retcode           NUMBER ;
--
    ------------------------------
    -- ＸＭＬ用
    ------------------------------
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
    lt_main_data_before       tab_data_type_dtl2; -- 取得レコード表(編集前)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
    lt_main_data              tab_data_type_dtl; -- 取得レコード表
    lt_xml_data_table         XML_DATA;          -- ＸＭＬデータタグ表
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- パラメータ格納
    -- =====================================================
    prc_set_param(
        ov_errbuf             => lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
       ,iv_deliver_from       => iv_deliver_from       -- 納入日FROM
       ,iv_deliver_to         => iv_deliver_to         -- 納入日TO
       ,iv_vendor_code1       => iv_vendor_code1       -- 取引先１
       ,iv_vendor_code2       => iv_vendor_code2       -- 取引先２
       ,iv_vendor_code3       => iv_vendor_code3       -- 取引先３
       ,iv_vendor_code4       => iv_vendor_code4       -- 取引先４
       ,iv_vendor_code5       => iv_vendor_code5       -- 取引先５
       ,iv_assen_vendor_code1 => iv_assen_vendor_code1 -- 斡旋者１
       ,iv_assen_vendor_code2 => iv_assen_vendor_code2 -- 斡旋者２
       ,iv_assen_vendor_code3 => iv_assen_vendor_code3 -- 斡旋者３
       ,iv_assen_vendor_code4 => iv_assen_vendor_code4 -- 斡旋者４
       ,iv_assen_vendor_code5 => iv_assen_vendor_code5 -- 斡旋者５
       ,iv_dept_code1         => iv_dept_code1         -- 担当部署１
       ,iv_dept_code2         => iv_dept_code2         -- 担当部署２
       ,iv_dept_code3         => iv_dept_code3         -- 担当部署３
       ,iv_dept_code4         => iv_dept_code4         -- 担当部署４
       ,iv_dept_code5         => iv_dept_code5         -- 担当部署５
       ,iv_security_flg       => iv_security_flg       -- セキュリティ区分
       ,or_param_rec          => lr_param_rec          -- 入力パラメータ群
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
       ,ir_param          => lr_param_rec       -- 入力パラメータ群
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data(
        ov_errbuf     => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
       ,ir_param      => lr_param_rec   -- 入力パラメータ群
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
--       ,ot_data_rec   => lt_main_data   -- 取得レコード群
       ,ot_data_rec   => lt_main_data_before   -- 取得レコード群
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2009/06/22 v1.17 T.Yoshimoto Add Start 本番障害#1516(再)※v1.15対応時の障害
    IF ( lt_main_data_before.COUNT > 0 ) THEN
-- 2009/06/22 v1.17 T.Yoshimoto Add End 本番障害#1516(再)※v1.15対応時の障害
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      -- =====================================================
      -- 取得レコードを編集処理
      -- =====================================================
      prc_edit_data(
          ov_errbuf     => lv_errbuf             -- エラー・メッセージ           --# 固定 #
         ,ov_retcode    => lv_retcode            -- リターン・コード             --# 固定 #
         ,ov_errmsg     => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
         ,it_data_rec   => lt_main_data_before   -- 入力パラメータ群
         ,ot_data_rec   => lt_main_data   -- 取得レコード群
      ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2009/06/22 v1.17 T.Yoshimoto Add Start 本番障害#1516(再)※v1.15対応時の障害
    END IF;
-- 2009/06/22 v1.17 T.Yoshimoto Add End 本番障害#1516(再)※v1.15対応時の障害
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
       ,ir_param          => lr_param_rec       -- 入力パラメータレコード
       ,it_data_rec       => lt_main_data       -- 取得レコード群
       ,ot_xml_data_table => lt_xml_data_table  -- XMLデータ
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML出力処理
    -- =====================================================
    prc_out_xml(
        ov_errbuf         => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
       ,ir_param          => lr_param_rec      -- 入力パラメータ群
       ,it_xml_data_table => lt_xml_data_table -- 取得レコード群
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF (lt_main_data.COUNT = 0) THEN
      lv_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
    END IF;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  固定部 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_deliver_from       IN     VARCHAR2         -- 納入日FROM
     ,iv_deliver_to         IN     VARCHAR2         -- 納入日TO
     ,iv_vendor_code1       IN     VARCHAR2         -- 取引先１
     ,iv_vendor_code2       IN     VARCHAR2         -- 取引先２
     ,iv_vendor_code3       IN     VARCHAR2         -- 取引先３
     ,iv_vendor_code4       IN     VARCHAR2         -- 取引先４
     ,iv_vendor_code5       IN     VARCHAR2         -- 取引先５
     ,iv_assen_vendor_code1 IN     VARCHAR2         -- 斡旋者１
     ,iv_assen_vendor_code2 IN     VARCHAR2         -- 斡旋者２
     ,iv_assen_vendor_code3 IN     VARCHAR2         -- 斡旋者３
     ,iv_assen_vendor_code4 IN     VARCHAR2         -- 斡旋者４
     ,iv_assen_vendor_code5 IN     VARCHAR2         -- 斡旋者５
     ,iv_dept_code1         IN     VARCHAR2         -- 担当部署１
     ,iv_dept_code2         IN     VARCHAR2         -- 担当部署２
     ,iv_dept_code3         IN     VARCHAR2         -- 担当部署３
     ,iv_dept_code4         IN     VARCHAR2         -- 担当部署４
     ,iv_dept_code5         IN     VARCHAR2         -- 担当部署５
     ,iv_security_flg       IN     VARCHAR2         -- セキュリティ区分
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1) ;         --   リターン・コード
    lv_errmsg               VARCHAR2(5000) ;      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain(
        ov_errbuf             => lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
       ,iv_deliver_from       => iv_deliver_from       -- 納入日FROM
       ,iv_deliver_to         => iv_deliver_to         -- 納入日TO
       ,iv_vendor_code1       => iv_vendor_code1       -- 取引先１
       ,iv_vendor_code2       => iv_vendor_code2       -- 取引先２
       ,iv_vendor_code3       => iv_vendor_code3       -- 取引先３
       ,iv_vendor_code4       => iv_vendor_code4       -- 取引先４
       ,iv_vendor_code5       => iv_vendor_code5       -- 取引先５
       ,iv_assen_vendor_code1 => iv_assen_vendor_code1 -- 斡旋者１
       ,iv_assen_vendor_code2 => iv_assen_vendor_code2 -- 斡旋者２
       ,iv_assen_vendor_code3 => iv_assen_vendor_code3 -- 斡旋者３
       ,iv_assen_vendor_code4 => iv_assen_vendor_code4 -- 斡旋者４
       ,iv_assen_vendor_code5 => iv_assen_vendor_code5 -- 斡旋者５
       ,iv_dept_code1         => iv_dept_code1         -- 担当部署１
       ,iv_dept_code2         => iv_dept_code2         -- 担当部署２
       ,iv_dept_code3         => iv_dept_code3         -- 担当部署３
       ,iv_dept_code4         => iv_dept_code4         -- 担当部署４
       ,iv_dept_code5         => iv_dept_code5         -- 担当部署５
       ,iv_security_flg       => iv_security_flg       -- セキュリティ区分
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxpo360005c ;

/
