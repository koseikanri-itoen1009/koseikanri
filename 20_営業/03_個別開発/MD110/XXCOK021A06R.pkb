CREATE OR REPLACE PACKAGE BODY XXCOK021A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A06R(body)
 * Description      : 帳合問屋に関する請求書と見積書を突き合わせ、品目別に請求書と見積書の内容を表示
 * MD.050           : 問屋販売条件支払チェック表 MD050_COK_021_A06
 * Version          : 1.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_wholesale_pay      ワークテーブルデータ削除(A-6)
 *  start_svf              SVF起動(A-5)
 *  ins_wholesale_pay      ワークテーブルデータ登録(A-4)
 *  get_target_data        対象データ取得(A-2)・見積書情報取得(A-3)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   K.Iwabuchi       新規作成
 *  2009/02/05    1.1   K.Iwabuchi       [障害COK_011] パラメータ不具合対応
 *  2009/02/06    1.2   K.Iwabuchi       [障害COK_015] クイックコードビュー有効日付判定追加対応
 *  2009/02/17    1.3   K.Iwabuchi       [障害COK_036] 登録項目算出修正、見積書情報取得修正、営業単位ID条件追加、無効日判断追加
 *  2009/04/17    1.4   M.Hiruta         [障害T1_0414] 請求金額が0である場合、補填・問屋マージン・拡売費の3項に
 *                                                     値が出力されないよう変更
 *                                                     補填の値がマイナスであっても、合計の辻褄が合うよう変更
 *  2009/09/01    1.5   S.Moriyama       [障害0001230] OPM品目マスタ取得条件追加
 *  2009/12/01    1.6   S.Moriyama       [E_本稼動_00229] 支払金額=補填+問屋マージン+拡売費を満たさない場合
 *                                                        問屋マージンで金額調整を行うように修正（端数調整）
 *  2009/12/18    1.7   S.Moriyama       [E_本稼動_00539] 横計調整を勘定科目支払時は行わないように修正
 *                                                        勘定科目支払時に以下の設定を実施
 *                                                        補助科目:05103は問屋マージン
 *                                                        補助科目:05132は拡売費、その他はその他科目へ設定
 *  2009/12/24    1.8   S.Moriyama       [E_本稼動_00608] SQLチューニング
 *  2010/01/27    1.9   K.Kiriu          [E_本稼動_01176] 口座種別追加に伴う口座種別名取得元クイックコード変更
 *  2010/04/23    1.10  K.Yamaguchi      [E_本稼動_02088] NET掛け率・CSマージン額で請求単位（ボール）を考慮
 *  2012/03/12    1.11  K.Nakamura       [E_本稼動_08318] レイアウト改修対応
 *  2012/07/12    1.12  S.Niki           [E_本稼動_09806] 単位別にNET価格と営業原価の比較方法を変更
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOK021A06R';
  -- アプリケーション短縮名
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';
  -- ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- メッセージコード
  cv_msg_code_00001          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';          -- 対象データなしメッセージ
  cv_msg_code_00003          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';          -- プロファイル取得エラー
  cv_msg_code_00013          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00013';          -- 在庫組織ID取得エラー
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
  cv_msg_code_00015          CONSTANT VARCHAR2(25)  := 'APP-XXCOK1-00015';          -- クイックコード取得エラーメッセージ
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  cv_msg_code_00018          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00018';          -- 拠点コード(入力パラメータ)
  cv_msg_code_00028          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';          -- 業務処理日付取得エラー
  cv_msg_code_00040          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00040';          -- SVF起動APIエラー
  cv_msg_code_00068          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00068';          -- 問屋管理コード(入力パラメータ)
  cv_msg_code_00069          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00069';          -- 顧客コード(入力パラメータ)
  cv_msg_code_00070          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00070';          -- 問屋帳合先コード(入力パラメータ)
  cv_msg_code_00071          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00071';          -- 支払年月日(入力パラメータ)
  cv_msg_code_00072          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00072';          -- 売上対象年月(入力パラメータ)
  cv_msg_code_10043          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10043';          -- データ削除エラー
  cv_msg_code_10044          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10044';          -- データ型チェックエラー(支払年月日)
  cv_msg_code_10045          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10045';          -- データ型チェックエラー(売上対象年月)
  cv_msg_code_10047          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10047';          -- 見積書情報取得エラー
  cv_msg_code_10392          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10392';          -- ロック取得エラー
  cv_msg_code_90000          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- 対象件数
  cv_msg_code_90001          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- 成功件数
  cv_msg_code_90002          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- エラー件数
  cv_msg_code_90004          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- 正常終了
  cv_msg_code_90006          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- エラー終了全ロールバック
  -- トークン
  cv_token_location_code     CONSTANT VARCHAR2(15)  := 'LOCATION_CODE';
  cv_token_cust_code         CONSTANT VARCHAR2(15)  := 'CUST_CODE';
  cv_token_pay_date          CONSTANT VARCHAR2(15)  := 'PAY_DATE';
  cv_token_target_period     CONSTANT VARCHAR2(15)  := 'TARGET_PERIOD';
  cv_token_profile           CONSTANT VARCHAR2(15)  := 'PROFILE';
  cv_token_org_code          CONSTANT VARCHAR2(15)  := 'ORG_CODE';
  cv_token_ctrl_code         CONSTANT VARCHAR2(15)  := 'CONTROL_CODE';
  cv_token_balance_code      CONSTANT VARCHAR2(15)  := 'BALANCE_CODE';
  cv_token_item_code         CONSTANT VARCHAR2(15)  := 'ITEM_CODE';
  cv_token_demand_price      CONSTANT VARCHAR2(15)  := 'DEMAND_PRICE';
  cv_token_demand_unit       CONSTANT VARCHAR2(15)  := 'DEMAND_UNIT';
  cv_token_request_id        CONSTANT VARCHAR2(15)  := 'REQUEST_ID';
  cv_token_count             CONSTANT VARCHAR2(15)  := 'COUNT';
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
  cv_token_lookup_value_set  CONSTANT VARCHAR2(25)  := 'LOOKUP_VALUE_SET';
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  -- プロファイル
  cv_prof_org_code_sales     CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';     -- 在庫組織コード_営業組織
  cv_prof_org_id             CONSTANT VARCHAR2(25)  := 'ORG_ID';                    -- 営業単位ID
-- 2009/12/18 Ver.1.7 [E_本稼動_00543] SCS S.Moriyama ADD START
  cv_prof_aff3_fee           CONSTANT VARCHAR2(25)  := 'XXCOK1_AFF3_SELL_FEE';      -- 勘定科目_販売手数料（問屋）
  cv_prof_aff3_support       CONSTANT VARCHAR2(25)  := 'XXCOK1_AFF3_SELL_SUPPORT';  -- 勘定科目_販売協賛金（問屋）
  cv_prof_aff4_fee           CONSTANT VARCHAR2(25)  := 'XXCOK1_AFF4_SELL_FEE';      -- 補助科目_問屋条件
  cv_prof_aff4_support       CONSTANT VARCHAR2(25)  := 'XXCOK1_AFF4_SELL_SUPPORT';  -- 補助科目_拡売費
-- 2009/12/18 Ver.1.7 [E_本稼動_00543] SCS S.Moriyama ADD END
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
  cv_prof_warn_margin_rate   CONSTANT VARCHAR2(25)  := 'XXCOK1_WARN_MARGIN_RATE';   -- 警告マージン率
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  -- フォーマット
  cv_format_fxyyyy_mm_dd     CONSTANT VARCHAR2(12)  := 'FXYYYY/MM/DD';
  cv_format_fxyyyy_mm        CONSTANT VARCHAR2(9)   := 'FXYYYY/MM';
  cv_format_yyyy_mm_dd       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_format_yyyy_mm          CONSTANT VARCHAR2(7)   := 'YYYY/MM';
  cv_format_yyyymm           CONSTANT VARCHAR2(6)   := 'YYYYMM';
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
  -- 記号
  cv_hyphen                  CONSTANT VARCHAR2(1)   := '-';
  -- 数値
  cn_number_0                CONSTANT NUMBER        := 0;
  cn_number_1                CONSTANT NUMBER        := 1;
  cn_number_100              CONSTANT NUMBER        := 100;
  -- 出力区分
  cv_which                   CONSTANT VARCHAR2(3)   := 'LOG'; -- 出力区分
  -- 主銀行フラグ
  cv_primary_flag            CONSTANT VARCHAR2(1)   := 'Y';   -- 主銀行
  -- タイプ
  cv_lookup_type_tonya       CONSTANT VARCHAR2(20)  := 'XXCMM_TONYA_CODE';
-- 2010/01/27 Ver.1.9 [E_本稼動_01176] SCS K.Kiiru UPD START
--  cv_lookup_type_bank        CONSTANT VARCHAR2(20)  := 'JP_BANK_ACCOUNT_TYPE';
  cv_lookup_type_bank        CONSTANT VARCHAR2(20)  := 'XXCSO1_KOZA_TYPE';
-- 2010/01/27 Ver.1.9 [E_本稼動_01176] SCS K.Kiiru UPD END
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
  cv_lookup_type_stamp       CONSTANT VARCHAR2(30)  := 'XXCOK1_WHOLESALE_PAY_STAMP';
  cv_lookup_type_chilled     CONSTANT VARCHAR2(30)  := 'XXCOK1_ITM_YOKIGUN_CHILLED';
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  -- 請求単位
  cv_unit_type_cs            CONSTANT VARCHAR2(1)   := '2';   -- C/S
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi ADD START
  cv_unit_type_unit          CONSTANT VARCHAR2(1)   := '1';   -- 本
  cv_unit_type_bl            CONSTANT VARCHAR2(1)   := '3';   -- ボール
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi ADD END
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
  -- 有効フラグ
  cv_enabled_flag            CONSTANT VARCHAR2(1)   := 'Y';   -- 有効
  -- チルド品判定フラグ
  cv_chilled_flag            CONSTANT VARCHAR2(1)   := 'Y';   -- チルド品
  -- 見積区分
  cv_quote_div_no            CONSTANT VARCHAR2(1)   := '0';   -- 0:見積書なし
  -- 添え字(記号用)
  cv_index_1                 CONSTANT VARCHAR2(1)   := '1';   -- クイックコード
  cv_index_2                 CONSTANT VARCHAR2(1)   := '2';   -- クイックコード
  cv_index_3                 CONSTANT VARCHAR2(1)   := '3';   -- クイックコード
  -- ダミー値
  cv_dummy                   CONSTANT VARCHAR2(5)   := 'dummy';              -- ダミー値
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  -- SVF起動パラメータ
  cv_file_id                 CONSTANT VARCHAR2(20)  := 'XXCOK021A06R';       -- 帳票ID
  cv_output_mode             CONSTANT VARCHAR2(1)   := '1';                  -- 出力区分(PDF出力)
  cv_extension               CONSTANT VARCHAR2(10)  := '.pdf';               -- 出力ファイル名拡張子(PDF出力)
  cv_frm_file                CONSTANT VARCHAR2(20)  := 'XXCOK021A06S.xml';   -- フォーム様式ファイル名
  cv_vrq_file                CONSTANT VARCHAR2(20)  := 'XXCOK021A06S.vrq';   -- クエリー様式ファイル名
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  gn_target_cnt                NUMBER        DEFAULT 0;     -- 対象件数
  gn_normal_cnt                NUMBER        DEFAULT 0;     -- 正常件数
  gn_error_cnt                 NUMBER        DEFAULT 0;     -- エラー件数
  gv_org_code_sales            VARCHAR2(50)  DEFAULT NULL;  -- プロファイル値(在庫組織コード_営業組織)
  gn_org_id_sales              NUMBER        DEFAULT NULL;  -- 在庫組織ID
  gn_org_id                    NUMBER        DEFAULT NULL;  -- 営業単位ID
  gd_process_date              DATE          DEFAULT NULL;  -- 業務処理日付
  gv_no_data_msg               VARCHAR2(30)  DEFAULT NULL;  -- 対象データなしメッセージ
  gn_market_amt                NUMBER        DEFAULT NULL;  -- 建値
  gn_allowance_amt             NUMBER        DEFAULT NULL;  -- 値引(割戻し)
  gn_normal_store_deliver_amt  NUMBER        DEFAULT NULL;  -- 通常店納
  gn_once_store_deliver_amt    NUMBER        DEFAULT NULL;  -- 今回店納
  gn_net_selling_price         NUMBER        DEFAULT NULL;  -- NET価格
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
  gn_normal_net_selling_price  NUMBER        DEFAULT NULL;  -- 通常NET価格(NET価格差照合時のみ)
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  gv_estimated_type            VARCHAR2(1)   DEFAULT NULL;  -- 見積区分
-- 2009/12/18 Ver.1.7 [E_本稼動_00543] SCS S.Moriyama ADD START
  gv_aff3_fee                  VARCHAR2(50);                -- プロファイル値(販売手数料（問屋）)
  gv_aff3_support              VARCHAR2(50);                -- プロファイル値(販売協賛金（問屋）)
  gv_aff4_fee                  VARCHAR2(50);                -- プロファイル値(問屋条件)
  gv_aff4_support              VARCHAR2(50);                -- プロファイル値(拡売費)
-- 2009/12/18 Ver.1.7 [E_本稼動_00543] SCS S.Moriyama ADD END
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
  gn_warn_margin_rate          NUMBER        DEFAULT NULL;  -- プロファイル値(警告マージン率)
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
  CURSOR g_target_cur(
    iv_base_code             IN VARCHAR2  -- 拠点コード
  , iv_payment_date          IN VARCHAR2  -- 支払年月日
  , lv_selling_month         IN VARCHAR2  -- 売上対象年月
  , iv_wholesale_code_admin  IN VARCHAR2  -- 問屋管理コード
  , iv_cust_code             IN VARCHAR2  -- 顧客コード
  , iv_sales_outlets_code    IN VARCHAR2  -- 問屋帳合先コード
  )
  IS
    SELECT xwbl.wholesale_bill_detail_id  AS wholesale_bill_detail_id       -- 問屋請求書明細ID
         , xwbl.bill_no                   AS bill_no                        -- 請求書No
         , xwbh.base_code                 AS base_code                      -- 拠点コード
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
         , ( SELECT xbav.base_name                                          -- 拠点名称
             FROM   xxcok_base_all_v xbav                                   -- 拠点ビュー
             WHERE  xbav.base_code = xwbh.base_code                         -- 拠点コード
           )                              AS base_name                      -- 拠点名
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
         , xwbh.cust_code                 AS cust_code                      -- 顧客コード
         , xwbl.sales_outlets_code        AS sales_outlets_code             -- 問屋帳合先コード
         , xwbl.selling_month             AS selling_month                  -- 売上対象年月
         , NVL( xwbl.item_code, xwbl.acct_code || cv_hyphen || xwbl.sub_acct_code )
                                          AS item_code                      -- 品目コード(NULL：勘定科目コード-補助科目コード)
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
         , xwbl.item_code                 AS item_code_judge                -- 品目コード(判定用)
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
         , xwbl.demand_qty                AS demand_qty                     -- 請求数量
         , xwbl.demand_unit_price         AS demand_unit_price              -- 請求単価
         , xwbl.demand_amt                AS demand_amt                     -- 請求金額
         , xwbl.demand_unit_type          AS demand_unit_type               -- 請求単位
         , xwbl.payment_qty               AS payment_qty                    -- 支払数量
         , xwbl.payment_unit_price        AS payment_unit_price             -- 支払単価
         , xwbl.payment_amt               AS payment_amt                    -- 支払金額
         , xwbh.supplier_code             AS supplier_code                  -- 仕入先コード
         , xwbl.acct_code                 AS acct_code                      -- 勘定科目コード
         , xwbl.sub_acct_code             AS sub_acct_code                  -- 補助科目コード
         , xca.wholesale_ctrl_code        AS wholesale_ctrl_code            -- 問屋管理コード
         , hp.party_name                  AS cust_name                      -- 顧客名称
         , hp2.party_name                 AS sales_outlets_name             -- 問屋帳合先名
         , NVL( item.item_short_name, xav.description || cv_hyphen || xsav.description )
                                          AS item_short_name                -- 品名・略名(NULL：勘定科目名称-補助科目名称)
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi REPAIR START
--         , item.inc_num                   AS inc_num                        -- 入数
         , item.cs_count                  AS cs_count                       -- ケース入数
         , item.bl_count                  AS bl_count                       -- ボール入数
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi REPAIR END
         , CASE WHEN NVL( TO_DATE( item.fixed_price_start_date, cv_format_yyyy_mm_dd ) , gd_process_date ) > gd_process_date
           THEN item.old_fixed_price                                        -- 旧定価
           ELSE item.new_fixed_price                                        -- 定価(新)
           END                            AS fixed_price                    -- 定価
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
         , item.new_trading_cost          AS trading_cost                   -- 営業原価(新)
         , item.vessel_group              AS vessel_group                   -- 容器群
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
         , pv.vendor_name                 AS vendor_name                    -- 仕入先名
         , bank.bank_name                 AS bank_name                      -- 銀行名
         , bank.bank_branch_name          AS bank_branch_name               -- 銀行支店名
         , bank.bank_account_type         AS bank_account_type              -- 口座種別
         , bank.bank_account_num          AS bank_account_num               -- 口座番号
         , xlv.meaning                    AS wholesale_ctrl_name            -- 問屋管理名
    FROM   xxcok_wholesale_bill_head      xwbh                              -- 問屋請求書ヘッダーテーブル
         , xxcok_wholesale_bill_line      xwbl                              -- 問屋請求書明細テーブル
         , hz_cust_accounts               hca                               -- 顧客マスタ
         , hz_cust_accounts               hca2                              -- 顧客マスタ(問屋帳合先用)
         , hz_parties                     hp                                -- パーティマスタ
         , hz_parties                     hp2                               -- パーティマスタ(問屋帳合先)
         , xxcmm_cust_accounts            xca                               -- 顧客追加情報
         , xx03_accounts_v                xav                               -- 勘定科目ビュー
         , xx03_sub_accounts_v            xsav                              -- 補助科目ビュー
         , po_vendors                     pv                                -- 仕入先マスタ
         , po_vendor_sites_all            pvsa                              -- 仕入先サイトマスタ
-- 2009/12/24 Ver.1.8 [E_本稼動_00608] SCS S.Moriyama UPD START
--         , xxcok_lookups_v                xlv                               -- クイックコードビュー
         , fnd_lookup_values              xlv                               -- クイックコード
-- 2009/12/24 Ver.1.8 [E_本稼動_00608] SCS S.Moriyama UPD END
         ,( SELECT msib.segment1                 AS item_code               -- 品目コード
                 , TO_NUMBER( iimb.attribute4 )  AS old_fixed_price         -- 旧定価
                 , TO_NUMBER( iimb.attribute5 )  AS new_fixed_price         -- 定価(新)
                 , iimb.attribute6               AS fixed_price_start_date  -- 定価適用開始日
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
                 , TO_NUMBER( iimb.attribute8 )  AS new_trading_cost        -- 営業原価(新)
                 , xsib.vessel_group             AS vessel_group            -- 容器群
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi REPAIR START
--                 , TO_NUMBER( iimb.attribute11 ) AS inc_num                 -- 入数
                 , TO_NUMBER( iimb.attribute11 ) AS cs_count                -- ケース入数
                 , xsib.bowl_inc_num             AS bl_count                -- ボール入り数
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi REPAIR END
                 , ximb.item_short_name          AS item_short_name         -- 品名・略名
            FROM   mtl_system_items_b  msib                                 -- 品目マスタ
                 , ic_item_mst_b       iimb                                 -- OPM品目マスタ
                 , xxcmn_item_mst_b    ximb                                 -- OPM品目アドオンマスタ
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi ADD START
                 , xxcmm_system_items_b  xsib                               -- DISC品目アドオン
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi ADD END
            WHERE  msib.organization_id  = gn_org_id_sales
            AND    msib.segment1         = iimb.item_no
            AND    iimb.item_id          = ximb.item_id
-- 2009/09/01 Ver.1.5 [障害0001230] SCS S.Moriyama ADD START
            AND    gd_process_date BETWEEN ximb.start_date_active
                                       AND NVL ( ximb.end_date_active , gd_process_date )
-- 2009/09/01 Ver.1.5 [障害0001230] SCS S.Moriyama ADD END
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi ADD START
            AND    msib.segment1         = xsib.item_code
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi ADD END
          ) item
         ,( SELECT abau.vendor_id        AS vendor_id                       -- 内部仕入先ID
                 , abau.vendor_site_id   AS vendor_site_id                  -- 内部仕入先サイトID
                 , abb.bank_name         AS bank_name                       -- 銀行名
                 , abb.bank_branch_name  AS bank_branch_name                -- 銀行支店名
                 , hl.meaning            AS bank_account_type               -- 口座種別
                 , abaa.bank_account_num AS bank_account_num                -- 口座番号
            FROM   ap_bank_branches              abb                        -- 銀行支店情報
                 , ap_bank_accounts_all          abaa                       -- 銀行口座情報
                 , ap_bank_account_uses_all      abau                       -- 銀行口座使用情報
                 , hr_lookups                    hl                         -- クイックコード
            WHERE  abau.external_bank_account_id = abaa.bank_account_id
            AND    abaa.bank_branch_id           = abb.bank_branch_id
            AND    abaa.org_id                   = gn_org_id
            AND    abaa.bank_account_type        = hl.lookup_code(+)
            AND    hl.lookup_type(+)             = cv_lookup_type_bank
            AND    abau.primary_flag             = cv_primary_flag
            AND    abau.org_id                   = gn_org_id
            AND    ( abau.start_date            <= gd_process_date OR abau.start_date IS NULL )
            AND    ( abau.end_date              >= gd_process_date OR abau.end_date   IS NULL )
          ) bank
    WHERE  xwbh.expect_payment_date      = TO_DATE( iv_payment_date, cv_format_fxyyyy_mm_dd )
    AND    xwbh.base_code                = NVL( iv_base_code, xwbh.base_code )
    AND    xwbh.cust_code                = NVL( iv_cust_code, xwbh.cust_code )
    AND    xwbl.sales_outlets_code       = NVL( iv_sales_outlets_code, xwbl.sales_outlets_code )
    AND    xwbl.selling_month            = NVL( lv_selling_month, xwbl.selling_month )
    AND    xca.wholesale_ctrl_code       = NVL( iv_wholesale_code_admin, xca.wholesale_ctrl_code )
    AND    xca.customer_id               = hca.cust_account_id
    AND    hca.account_number            = xwbh.cust_code
    AND    hca2.account_number           = xwbl.sales_outlets_code
    AND    hca.party_id                  = hp.party_id
    AND    hca2.party_id                 = hp2.party_id
    AND    xca.wholesale_ctrl_code       = xlv.lookup_code
    AND    xlv.lookup_type               = cv_lookup_type_tonya
    AND    gd_process_date               BETWEEN NVL( xlv.start_date_active, gd_process_date )
                                             AND NVL( xlv.end_date_active,   gd_process_date )
-- 2009/12/24 Ver.1.8 [E_本稼動_00608] SCS S.Moriyama ADD START
    AND    xlv.language                  = USERENV('LANG')
-- 2009/12/24 Ver.1.8 [E_本稼動_00608] SCS S.Moriyama ADD END
    AND    xwbl.acct_code                = xav.flex_value(+)
    AND    xwbl.sub_acct_code            = xsav.flex_value(+)
    AND    xwbl.acct_code                = xsav.parent_flex_value_low(+)
    AND    xwbl.item_code                = item.item_code(+)
    AND    xwbh.supplier_code            = pv.segment1
    AND    pv.vendor_id                  = pvsa.vendor_id
    AND    pvsa.vendor_id                = bank.vendor_id(+)
    AND    pvsa.vendor_site_id           = bank.vendor_site_id(+)
    AND    pvsa.org_id                   = gn_org_id
    AND    ( pvsa.inactive_date > gd_process_date OR pvsa.inactive_date IS NULL )
    AND    xwbh.wholesale_bill_header_id = xwbl.wholesale_bill_header_id;
  TYPE g_target_ttype IS TABLE OF g_target_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_target_tab g_target_ttype;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
  CURSOR lookup_stamp_cur
  IS
    SELECT flv.lookup_code   AS lookup_code
         , flv.meaning       AS meaning
         , flv.description   AS description
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_stamp
    AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                               AND NVL( flv.end_date_active, gd_process_date )
    AND    flv.language     = USERENV('LANG')
    AND    flv.enabled_flag = cv_enabled_flag
    ORDER BY flv.lookup_code
  ;
  lookup_stamp_rec   lookup_stamp_cur%ROWTYPE;
  TYPE g_lookup_stamp_ttype IS TABLE OF lookup_stamp_cur%ROWTYPE INDEX BY VARCHAR2(1);
  g_lookup_stamp_tab g_lookup_stamp_ttype;
  --
  CURSOR lookup_chilled_cur
  IS
    SELECT flv.lookup_code   AS lookup_code
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_chilled
    AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                               AND NVL( flv.end_date_active, gd_process_date )
    AND    flv.language     = USERENV('LANG')
    AND    flv.enabled_flag = cv_enabled_flag
  ;
  TYPE g_lookup_chilled_ttype IS TABLE OF lookup_chilled_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_lookup_chilled_tab g_lookup_chilled_ttype;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  -- ===============================================
  -- 共通例外
  -- ===============================================
  --*** ロックエラー ***
  global_lock_fail          EXCEPTION;
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  /**********************************************************************************
   * Procedure Name   : del_wholesale_pay
   * Description      : ワークテーブルデータ削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_wholesale_pay(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20) := 'del_wholesale_pay';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR wholesale_pay_cur
    IS
      SELECT 'X'
      FROM   xxcok_rep_wholesale_pay  xrwp
      WHERE  xrwp.request_id = cn_request_id
      FOR UPDATE OF xrwp.wholesale_bill_detail_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 問屋販売条件支払チェック帳票ワークテーブルロック取得
    -- ===============================================
    OPEN  wholesale_pay_cur;
    CLOSE wholesale_pay_cur;
    -- ===============================================
    -- 問屋販売条件支払チェック帳票ワークテーブルデータ削除
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_rep_wholesale_pay  xrwp
      WHERE  xrwp.request_id = cn_request_id;
      -- ===============================================
      -- 成功件数取得
      -- ===============================================
      gn_normal_cnt := SQL%ROWCOUNT;
    EXCEPTION
      -- *** 削除処理エラー ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10043
                      , iv_token_name1  => cv_token_request_id
                      , iv_token_value1 => cn_request_id
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    --*** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10392
                    , iv_token_name1  => cv_token_request_id
                    , iv_token_value1 => cn_request_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_wholesale_pay;
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF起動(A-5)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(10) := 'start_svf'; -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg    VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode   BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    lv_date      VARCHAR2(8)    DEFAULT NULL;              -- 出力ファイル名用日付
    lv_file_name VARCHAR2(100)  DEFAULT NULL;              -- 出力ファイル名
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- システム日付型変換
    -- ===============================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    -- ===============================================
    -- 出力ファイル名(帳票ID + YYYYMMDD + 要求ID)
    -- ===============================================
    lv_file_name := cv_file_id || lv_date || TO_CHAR( cn_request_id ) || cv_extension;
    -- ===============================================
    -- SVFコンカレント起動
    -- ===============================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                  -- エラーバッファ
      , ov_retcode       => lv_retcode                 -- リターンコード
      , ov_errmsg        => lv_errmsg                  -- エラーメッセージ
      , iv_conc_name     => cv_pkg_name                -- コンカレント名
      , iv_file_name     => lv_file_name               -- 出力ファイル名
      , iv_file_id       => cv_file_id                 -- 帳票ID
      , iv_output_mode   => cv_output_mode             -- 出力区分
      , iv_frm_file      => cv_frm_file                -- フォーム様式ファイル名
      , iv_vrq_file      => cv_vrq_file                -- クエリー様式ファイル名
      , iv_org_id        => TO_CHAR( gn_org_id_sales ) -- ORG_ID
      , iv_user_name     => fnd_global.user_name       -- ログイン・ユーザ名
      , iv_resp_name     => fnd_global.resp_name       -- ログイン・ユーザ職責名
      , iv_doc_name      => NULL                       -- 文書名
      , iv_printer_name  => NULL                       -- プリンタ名
      , iv_request_id    => TO_CHAR( cn_request_id )   -- 要求ID
      , iv_nodata_msg    => NULL                       -- データなしメッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => cn_number_0
                    );
      RAISE global_api_expt;
    END IF;
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
  /**********************************************************************************
   * Procedure Name   : ins_wholesale_pay
   * Description      : ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_wholesale_pay(
    ov_errbuf                    OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode                   OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                    OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_base_code                 IN VARCHAR2   -- 拠点コード
  , iv_payment_date              IN VARCHAR2   -- 支払年月日
  , iv_selling_month             IN VARCHAR2   -- 売上対象年月
  , iv_wholesale_code_admin      IN VARCHAR2   -- 問屋管理コード
  , iv_cust_code                 IN VARCHAR2   -- 顧客コード
  , iv_sales_outlets_code        IN VARCHAR2   -- 問屋帳合先コード
  , in_i                         IN NUMBER     -- LOOPカウンタ
-- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
  , in_backmargin_amt            IN NUMBER DEFAULT NULL -- 販売手数料
  , in_sales_support_amt         IN NUMBER DEFAULT NULL -- 販売協賛金
-- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20) := 'ins_wholesale_pay';     -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    ln_payment_qty           NUMBER         DEFAULT NULL;              -- 支払数量
    ln_payment_unit_price    NUMBER         DEFAULT NULL;              -- 支払単価
    ln_payment_amt           NUMBER         DEFAULT NULL;              -- 支払金額
    ln_market_amt            NUMBER         DEFAULT NULL;              -- 建値
    ln_net_pct               NUMBER         DEFAULT NULL;              -- NET掛率
    ln_margin_pct            NUMBER         DEFAULT NULL;              -- マージン率
    ln_coverage_amt          NUMBER         DEFAULT NULL;              -- 補填
    ln_wholesale_margin_sum  NUMBER         DEFAULT NULL;              -- 問屋マージン
    ln_cs_margin_amt         NUMBER         DEFAULT NULL;              -- C/Sマージン額
    ln_expansion_sales_amt   NUMBER         DEFAULT NULL;              -- 拡売費
    ln_misc_acct_amt         NUMBER         DEFAULT NULL;              -- その他科目
    lv_selling_month         VARCHAR2(7)    DEFAULT NULL;              -- 売上対象年月
-- 2009/12/01 Ver.1.6 [E_本稼動_00229] SCS S.Moriyama ADD START
    ln_fraction_amount       NUMBER         DEFAULT NULL;              -- 端数計算用
-- 2009/12/01 Ver.1.6 [E_本稼動_00229] SCS S.Moriyama ADD END
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
    lv_stamp                 VARCHAR2(2)    DEFAULT NULL;              -- 印
    lv_error_rate            VARCHAR2(2)    DEFAULT NULL;              -- 異常率
    lv_chilled_flag          VARCHAR2(1)    DEFAULT NULL;              -- チルド品判定フラグ
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
-- 2012/07/12 Ver.1.12 [E_本稼動_09806] SCSK S.Niki ADD START
    ln_trading_cost          NUMBER         DEFAULT NULL;              -- 営業原価(比較用)
-- 2012/07/12 Ver.1.12 [E_本稼動_09806] SCSK S.Niki ADD END
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 登録対象項目計算
    -- ===============================================
    IF ( gn_target_cnt <> 0 ) THEN
      -- ===============================================
      -- 支払数量・支払単価・支払金額(請求数量・請求単価・請求金額とすべて一致する場合、NULL)
      -- ===============================================
      ln_payment_qty        := g_target_tab( in_i ).payment_qty;         -- 支払数量
      ln_payment_unit_price := g_target_tab( in_i ).payment_unit_price;  -- 支払単価
      ln_payment_amt        := g_target_tab( in_i ).payment_amt;         -- 支払金額
      IF (    ln_payment_qty        = g_target_tab( in_i ).demand_qty )
        AND ( ln_payment_unit_price = g_target_tab( in_i ).demand_unit_price )
        AND ( ln_payment_amt        = g_target_tab( in_i ).demand_amt )
      THEN
        ln_payment_qty        := NULL;
        ln_payment_unit_price := NULL;
        ln_payment_amt        := NULL;
      END IF;
      -- ===============================================
      -- (実)建値(建値-値引)
      -- ===============================================
      ln_market_amt := NVL( gn_market_amt, 0 ) - NVL( gn_allowance_amt, 0 );
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      -- ===============================================
      -- 印
      -- ===============================================
      -- 見積書なしの場合の表示
      IF ( gv_estimated_type = cv_quote_div_no ) THEN
        lv_stamp := g_lookup_stamp_tab( cv_index_1 ).meaning;
      -- 営業原価＞NET価格の場合の表示
-- 2012/07/12 Ver.1.12 [E_本稼動_09806] SCSK S.Niki MOD START
--      ELSIF ( gv_estimated_type IS NOT NULL )
--        AND ( g_target_tab( in_i ).trading_cost > gn_net_selling_price ) THEN
--        lv_stamp := g_lookup_stamp_tab( cv_index_2 ).meaning;
      ELSIF ( gv_estimated_type IS NOT NULL ) THEN
        -- 単位：本の場合、営業原価
        IF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_unit ) THEN
          ln_trading_cost := g_target_tab( in_i ).trading_cost;
        -- 単位：ケースの場合、営業原価 * ケース入数
        ELSIF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
          ln_trading_cost := g_target_tab( in_i ).trading_cost
                           * NVL( g_target_tab( in_i ).cs_count, 0 );
        -- 単位：ボールの場合、営業原価 * ボール入数
        ELSIF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_bl ) THEN
          ln_trading_cost := g_target_tab( in_i ).trading_cost
                           * NVL( g_target_tab( in_i ).bl_count, 0 );
        END IF;
        -- ===============================================
        -- 営業原価(比較用)＞NET価格の場合、印を表示
        -- ===============================================
        IF ( ln_trading_cost > gn_net_selling_price ) THEN
          lv_stamp := g_lookup_stamp_tab( cv_index_2 ).meaning;
        END IF;
-- 2012/07/12 Ver.1.12 [E_本稼動_09806] SCSK S.Niki MOD END
      END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
      -- ===============================================
      -- NET掛率(NET価格/定価*100)  請求単位が2(C/S)の場合、NET価格/入数/定価*100
      -- ===============================================
      -- 定価がNULLまたは0の場合、NET掛率は0
      IF (   g_target_tab( in_i ).fixed_price IS NULL )
        OR ( g_target_tab( in_i ).fixed_price = cn_number_0 )
      THEN
        ln_net_pct := cn_number_0;
      ELSE
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi REPAIR START
--        IF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
--          -- 入数がNULLまたは0の場合、NET掛率は0
--          IF (   g_target_tab( in_i ).inc_num IS NULL )
--            OR ( g_target_tab( in_i ).inc_num = cn_number_0 )
--          THEN
--            ln_net_pct := cn_number_0;
--          ELSE
--            ln_net_pct := NVL( gn_net_selling_price, 0 ) / g_target_tab( in_i ).inc_num / g_target_tab( in_i ).fixed_price * cn_number_100;
--          END IF;
--        ELSE
--          ln_net_pct := NVL( gn_net_selling_price, 0 ) / g_target_tab( in_i ).fixed_price * cn_number_100;
--        END IF;
        -- 単位：本
        IF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_unit ) THEN
          ln_net_pct :=   NVL( gn_net_selling_price, 0 )
                        / g_target_tab( in_i ).fixed_price
                        * cn_number_100;
        -- 単位：ケース
        ELSIF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
          IF ( NVL( g_target_tab( in_i ).cs_count, 0 ) = 0 ) THEN
            ln_net_pct := 0;
          ELSE
            ln_net_pct :=   NVL( gn_net_selling_price, 0 )
                          / g_target_tab( in_i ).cs_count
                          / g_target_tab( in_i ).fixed_price
                          * cn_number_100;
          END IF;
        -- 単位：ボール
        ELSIF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_bl ) THEN
          IF ( NVL( g_target_tab( in_i ).bl_count, 0 ) = 0 ) THEN
            ln_net_pct := 0;
          ELSE
            ln_net_pct :=   NVL( gn_net_selling_price, 0 )
                          / g_target_tab( in_i ).bl_count
                          / g_target_tab( in_i ).fixed_price
                          * cn_number_100;
          END IF;
        ELSE
          ln_net_pct := 0;
        END IF;
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi REPAIR END
      END IF;
      -- ===============================================
      -- マージン率((今回店納-NET価格)/今回店納*100)  今回店納がNULL・0以外の場合今回店納、NULLまたは0の場合通常店納
      -- ===============================================
      IF (    gn_once_store_deliver_amt IS NOT NULL )
        AND ( gn_once_store_deliver_amt <> cn_number_0 )
      THEN
        ln_margin_pct := ( gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 ) ) / gn_once_store_deliver_amt * cn_number_100;
      ELSE
        IF (    gn_normal_store_deliver_amt IS NOT NULL )
          AND ( gn_normal_store_deliver_amt <> cn_number_0 )
        THEN
          ln_margin_pct := ( gn_normal_store_deliver_amt - NVL( gn_net_selling_price, 0 ) ) / gn_normal_store_deliver_amt * cn_number_100;
        ELSE
          ln_margin_pct := cn_number_0;
        END IF;
      END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      -- ===============================================
      -- 異常マージン率  チルド品以外かつ、マージン率がプロファイル値(警告マージン率)を超えている場合、表示
      -- ===============================================
      -- マージン率がプロファイル値(警告マージン率)を超えている場合
      IF ( TRUNC( ln_margin_pct, 1 ) > gn_warn_margin_rate ) THEN
        <<error_margin_loop>>
        FOR i IN 1 .. g_lookup_chilled_tab.COUNT LOOP
          -- チルド品以外の場合
          IF ( g_lookup_chilled_tab(i).lookup_code <> NVL( g_target_tab( in_i ).vessel_group, cv_dummy ) ) THEN
            lv_error_rate := g_lookup_stamp_tab( cv_index_3 ).meaning;
          -- チルド品の場合
          ELSE
            lv_chilled_flag := cv_chilled_flag;
          END IF;
        END LOOP error_margin_loop;
        -- チルド品の場合、NULLにする
        IF ( lv_chilled_flag = cv_chilled_flag ) THEN
          lv_error_rate := NULL;
        END IF;
      END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
      -- ===============================================
      -- C/Sマージン額((今回店納-NET価格)*入数  今回店納がNULL・0以外の場合今回店納、NULLまたは0の場合通常店納  請求単位が2(C/S)の場合、入数を掛けない
      -- ===============================================
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi REPAIR START
--      IF (    gn_once_store_deliver_amt IS NOT NULL )
--        AND ( gn_once_store_deliver_amt <> cn_number_0 )
--      THEN
--        IF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
--          ln_cs_margin_amt := gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 );
--        ELSE
--          ln_cs_margin_amt := ( gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 ) ) * NVL( g_target_tab( in_i ).inc_num, 0 );
--        END IF;
--      ELSE
--        IF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
--          ln_cs_margin_amt := NVL( gn_normal_store_deliver_amt, 0 ) - NVL( gn_net_selling_price, 0 );
--        ELSE
--          ln_cs_margin_amt := ( NVL( gn_normal_store_deliver_amt, 0 ) - NVL( gn_net_selling_price, 0 ) ) * NVL( g_target_tab( in_i ).inc_num, 0 );
--        END IF;
--      END IF;
      IF ( NVL( gn_once_store_deliver_amt, 0 ) <> 0 ) THEN
        -- 単位：本
        IF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_unit ) THEN
          ln_cs_margin_amt :=   ( gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 ) )
                              * NVL( g_target_tab( in_i ).cs_count, 0 );
        -- 単位：ケース
        ELSIF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
          ln_cs_margin_amt := gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 );
        -- 単位：ボール
        ELSIF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_bl ) THEN
          IF( NVL( g_target_tab( in_i ).bl_count, 0 ) = 0 ) THEN
            ln_cs_margin_amt := 0;
          ELSE
            ln_cs_margin_amt :=   ( gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 ) )
                                / g_target_tab( in_i ).bl_count
                                * NVL( g_target_tab( in_i ).cs_count, 0 );
          END IF;
        ELSE
          ln_cs_margin_amt := 0;
        END IF;
      ELSE
        -- 単位：本
        IF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_unit ) THEN
          ln_cs_margin_amt :=   ( gn_normal_store_deliver_amt - NVL( gn_net_selling_price, 0 ) )
                              * NVL( g_target_tab( in_i ).cs_count, 0 );
        -- 単位：ケース
        ELSIF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
          ln_cs_margin_amt := gn_normal_store_deliver_amt - NVL( gn_net_selling_price, 0 );
        -- 単位：ボール
        ELSIF( g_target_tab( in_i ).demand_unit_type = cv_unit_type_bl ) THEN
          IF( NVL( g_target_tab( in_i ).bl_count, 0 ) = 0 ) THEN
            ln_cs_margin_amt := 0;
          ELSE
            ln_cs_margin_amt :=   ( gn_normal_store_deliver_amt - NVL( gn_net_selling_price, 0 ) )
                                / g_target_tab( in_i ).bl_count
                                * NVL( g_target_tab( in_i ).cs_count, 0 );
          END IF;
        ELSE
          ln_cs_margin_amt := 0;
        END IF;
      END IF;
-- 2010/04/23 Ver.1.10 [E_本稼動_02088] SCS K.Yamaguchi REPAIR END
-- 2009/12/01 Ver.1.6 [E_本稼動_00229] SCS S.Moriyama UPD START
--      -- ===============================================
--      -- 補填(((実)建値-通常店納)*支払数量)
--      -- 以下の場合補填は0
--      -- (実)建値-通常店納が0より小さい場合
--      -- A-3.販売手数料がNULLの場合
--      -- A-3.販売手数料が0以下の場合
--      -- ===============================================
---- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
----      IF ( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0 ) < cn_number_0 ) THEN
--      IF ( ( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0 ) < cn_number_0 )
--        OR ( ( in_backmargin_amt IS NULL ) OR ( in_backmargin_amt <= cn_number_0 ) ) )
--      THEN
---- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
--        ln_coverage_amt := cn_number_0;
--      ELSE
--        ln_coverage_amt := ( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0 ) ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
--      END IF;
---- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
--      -- ===============================================
--      -- 問屋マージン
--      -- T1_0414修正前 ((今回店納-NET価格)*支払数量  今回店納がNULL・0以外の場合今回店納、NULLまたは0の場合通常店納
--      -- T1_0414修正後 A-3.販売手数料が0より大きい場合 A-3.販売手数料 × 支払数量 － 補填
--      --               上記以外                        A-3.販売手数料 × 支払数量
--      -- ===============================================
----      IF (    gn_once_store_deliver_amt IS NOT NULL )
----        AND ( gn_once_store_deliver_amt <> cn_number_0 )
----      THEN
----        ln_wholesale_margin_sum := ( gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 ) ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
----      ELSE
----        ln_wholesale_margin_sum := ( NVL( gn_normal_store_deliver_amt, 0 ) - NVL( gn_net_selling_price, 0 ) ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
----      END IF;
--      IF ( in_backmargin_amt > cn_number_0 ) THEN
--        ln_wholesale_margin_sum := NVL( in_backmargin_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 ) - ln_coverage_amt;
--      ELSE
--        ln_wholesale_margin_sum := NVL( in_backmargin_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
--      END IF;
--      -- ===============================================
--      -- 拡売費
--      -- T1_0414修正前 ((通常店納-今回店納)*支払数量)  今回店納がNULLまたは0の場合、拡売費は0
--      -- T1_0414修正後 A-3.販売協賛金 × 支払数量
--      -- ===============================================
----      IF (   gn_once_store_deliver_amt IS NULL )
----        OR ( gn_once_store_deliver_amt = cn_number_0 )
----      THEN
----        ln_expansion_sales_amt := cn_number_0;
----      ELSE
----        ln_expansion_sales_amt := ( gn_normal_store_deliver_amt - gn_once_store_deliver_amt ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
----      END IF;
--      ln_expansion_sales_amt := NVL( in_sales_support_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
---- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
-- 2009/12/18 Ver.1.7 [E_本稼動_00543] SCS S.Moriyama UPD START
--      -- ===============================================
--      -- 補填(((実)建値-通常店納)*支払数量)
--      -- 以下の場合補填は0
--      -- (実)建値-通常店納が0より小さい場合
--      -- A-3.販売手数料がNULLの場合
--      -- A-3.販売手数料が0以下の場合
--      -- ===============================================
--      IF ( ( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0 ) < cn_number_0 )
--        OR ( ( in_backmargin_amt IS NULL ) OR ( in_backmargin_amt <= cn_number_0 ) ) )
--      THEN
--        ln_coverage_amt := cn_number_0;
--      ELSE
--        ln_coverage_amt := ROUND(( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0) ) * NVL( g_target_tab( in_i ).payment_qty, 0 ));
--      END IF;
--      -- ===============================================
--      -- 問屋マージン
--      -- A-3.販売手数料が0より大きい場合 A-3.販売手数料 × 支払数量 － 補填
--      -- 上記以外                        A-3.販売手数料 × 支払数量
--      -- ===============================================
--      IF ( in_backmargin_amt > cn_number_0 ) THEN
--        ln_wholesale_margin_sum := ROUND(NVL( in_backmargin_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 ) - ln_coverage_amt);
--      ELSE
--        ln_wholesale_margin_sum := ROUND(NVL( in_backmargin_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 ));
--      END IF;
--      -- ===============================================
--      -- 拡売費
--      -- A-3.販売協賛金 × 支払数量
--      -- ===============================================
--      ln_expansion_sales_amt := ROUND(NVL( in_sales_support_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 ));
--      -- ===============================================
--      -- 端数処理
--      -- 支払金額=補填+問屋マージン+拡売費を満たさない場合
--      -- 問屋マージンにて金額調整を行う
--      -- ===============================================
--      ln_fraction_amount := ROUND(ln_coverage_amt + ln_wholesale_margin_sum + ln_expansion_sales_amt);
----
--      IF ( NVL(ln_payment_amt,g_target_tab( in_i ).demand_amt) != ln_fraction_amount ) THEN
--        ln_wholesale_margin_sum := ln_wholesale_margin_sum + ( NVL(ln_payment_amt,g_target_tab( in_i ).demand_amt) - ln_fraction_amount );
--      END IF;
---- 2009/12/01 Ver.1.6 [E_本稼動_00229] SCS S.Moriyama UPD END
--      -- ===============================================
--      -- その他科目(支払金額) 勘定科目に値がある場合のみ
--      -- ===============================================
--      IF ( g_target_tab( in_i ).acct_code IS NOT NULL ) THEN
--        ln_misc_acct_amt := NVL( g_target_tab( in_i ).payment_amt, 0 );
--      END IF;
--
--
      IF ( g_target_tab( in_i ).acct_code IS NULL ) THEN
        -- ===============================================
        -- 横計調整を含め補填・マージン・拡売費は勘定科目支払以外の未実施
        -- 補填(((実)建値-通常店納)*支払数量)
        -- 以下の場合補填は0
        -- (実)建値-通常店納が0より小さい場合
        -- A-3.販売手数料がNULLの場合
        -- A-3.販売手数料が0以下の場合
        -- ===============================================
        IF ( ( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0 ) < cn_number_0 )
          OR ( ( in_backmargin_amt IS NULL ) OR ( in_backmargin_amt <= cn_number_0 ) ) )
        THEN
          ln_coverage_amt := cn_number_0;
        ELSE
          ln_coverage_amt := ROUND(( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0) ) * NVL( g_target_tab( in_i ).payment_qty, 0 ));
        END IF;
        -- ===============================================
        -- 問屋マージン
        -- A-3.販売手数料が0より大きい場合 A-3.販売手数料 × 支払数量 － 補填
        -- 上記以外                        A-3.販売手数料 × 支払数量
        -- ===============================================
        IF ( in_backmargin_amt > cn_number_0 ) THEN
          ln_wholesale_margin_sum := ROUND(NVL( in_backmargin_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 ) - ln_coverage_amt);
        ELSE
          ln_wholesale_margin_sum := ROUND(NVL( in_backmargin_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 ));
        END IF;
        -- ===============================================
        -- 拡売費
        -- A-3.販売協賛金 × 支払数量
        -- ===============================================
        ln_expansion_sales_amt := ROUND(NVL( in_sales_support_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 ));
        -- ===============================================
        -- 端数処理
        -- 支払金額=補填+問屋マージン+拡売費を満たさない場合
        -- 問屋マージンにて金額調整を行う
        -- ===============================================
        ln_fraction_amount := ROUND(ln_coverage_amt + ln_wholesale_margin_sum + ln_expansion_sales_amt);
--
        IF ( NVL(ln_payment_amt,g_target_tab( in_i ).demand_amt) != ln_fraction_amount ) THEN
          ln_wholesale_margin_sum := ln_wholesale_margin_sum + ( NVL(ln_payment_amt,g_target_tab( in_i ).demand_amt) - ln_fraction_amount );
        END IF;
      ELSE
        -- ===============================================
        -- 勘定科目支払時
        -- 83110-05103⇒問屋マージンへ設定
        -- 83111-05132⇒拡売費へ設定
        -- 上記以外⇒その他科目へ設定
        -- ===============================================
        IF ( g_target_tab( in_i ).acct_code = gv_aff3_fee
             AND g_target_tab( in_i ).sub_acct_code = gv_aff4_fee ) THEN
          ln_wholesale_margin_sum := NVL( g_target_tab( in_i ).payment_amt, 0 );
        ELSIF (g_target_tab( in_i ).acct_code = gv_aff3_support
             AND g_target_tab( in_i ).sub_acct_code = gv_aff4_support ) THEN
          ln_expansion_sales_amt := NVL( g_target_tab( in_i ).payment_amt, 0 );
        ELSE
          ln_misc_acct_amt := NVL( g_target_tab( in_i ).payment_amt, 0 );
        END IF;
      END IF;
-- 2009/12/18 Ver.1.7 [E_本稼動_00543] SCS S.Moriyama UPD END
      -- ===============================================
      -- 売上対象年月(YYYY/MM)データ変換
      -- ===============================================
      lv_selling_month := TO_CHAR( TO_DATE( g_target_tab( in_i ).selling_month, cv_format_yyyymm ), cv_format_yyyy_mm );
      -- ===============================================
      -- ワークテーブルデータ登録
      -- ===============================================
      INSERT INTO xxcok_rep_wholesale_pay(
        wholesale_bill_detail_id                       -- 問屋請求書明細ID
      , p_base_code                                    -- 拠点コード(入力パラメータ)
      , p_wholesale_code_admin                         -- 問屋管理コード(入力パラメータ)
      , p_cust_code                                    -- 顧客コード(入力パラメータ)
      , p_sales_outlets_code                           -- 問屋帳合先コード(入力パラメータ)
      , p_payment_date                                 -- 支払年月日(入力パラメータ)
      , p_selling_month                                -- 売上対象年月(入力パラメータ)
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      , stamp1                                         -- ヘッダ用印１
      , stamp1_description                             -- ヘッダ用印１摘要
      , stamp2                                         -- ヘッダ用印２
      , stamp2_description                             -- ヘッダ用印２摘要
      , stamp3                                         -- ヘッダ用印３
      , stamp3_description                             -- ヘッダ用印３摘要
      , base_code                                      -- 拠点コード
      , base_name                                      -- 拠点名
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
      , payment_date                                   -- 支払年月日
      , selling_month                                  -- 売上年月
      , bill_no                                        -- 請求書No.
      , cust_code                                      -- 顧客コード
      , cust_name                                      -- 顧客名
      , sales_outlets_code                             -- 問屋帳合先コード
      , sales_outlets_name                             -- 問屋帳合先名
      , wholesale_code_admin                           -- 問屋管理コード
      , wholesale_name_admin                           -- 問屋管理名
      , supplier_code                                  -- 仕入先コード
      , supplier_name                                  -- 仕入先名
      , bank_name                                      -- 銀行名
      , bank_branch_name                               -- 支店名
      , bank_acct_type                                 -- 口座種別
      , bank_acct_no                                   -- 口座番号
      , item_code                                      -- 品名コード
      , item_name                                      -- 品名
      , unit_type                                      -- 単位
      , demand_qty                                     -- 請求数量
      , demand_unit_price                              -- 請求単価
      , demand_amt                                     -- 請求金額
      , payment_qty                                    -- 支払数量
      , payment_unit_price                             -- 支払単価
      , payment_amt_disp                               -- 支払金額(表示用)
      , payment_amt_calc                               -- 支払金額(計算用)
      , normal_special_type                            -- 通特区分
      , market_amt                                     -- (実)建値
      , normal_store_deliver_amt                       -- 通常店納
      , once_store_deliver_amt                         -- 今回店納
      , net_selling_price                              -- NET価格
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      , net_selling_price_low                          -- NET価格(下段)
      , stamp                                          -- 印
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
      , net_pct                                        -- NET掛率
      , margin_pct                                     -- マージン率
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      , error_rate                                     -- 異常率
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
      , cs_margin_amt                                  -- C/Sマージン額
      , coverage_amt                                   -- 補填
      , wholesale_margin_sum                           -- 問屋マージン
      , expansion_sales_amt                            -- 拡売費
      , misc_acct_amt                                  -- その他科目
      , no_data_message                                -- 0件メッセージ
      , created_by                                     -- 作成者
      , creation_date                                  -- 作成日
      , last_updated_by                                -- 最終更新者
      , last_update_date                               -- 最終更新日
      , last_update_login                              -- 最終更新ログイン
      , request_id                                     -- 要求ID
      , program_application_id                         -- コンカレント・プログラム・アプリケーションID
      , program_id                                     -- コンカレント・プログラムID
      , program_update_date                            -- プログラム更新日
      ) VALUES (
        g_target_tab( in_i ).wholesale_bill_detail_id  -- wholesale_bill_detail_id
      , iv_base_code                                   -- p_base_code
      , iv_wholesale_code_admin                        -- p_wholesale_code_admin
      , iv_cust_code                                   -- p_cust_code
      , iv_sales_outlets_code                          -- p_sales_outlets_code
      , iv_payment_date                                -- p_payment_date
      , iv_selling_month                               -- p_selling_month
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      , g_lookup_stamp_tab( cv_index_1 ).meaning       -- stamp1
      , g_lookup_stamp_tab( cv_index_1 ).description   -- stamp1_description
      , g_lookup_stamp_tab( cv_index_2 ).meaning       -- stamp1
      , g_lookup_stamp_tab( cv_index_2 ).description   -- stamp1_description
      , g_lookup_stamp_tab( cv_index_3 ).meaning       -- stamp1
      , g_lookup_stamp_tab( cv_index_3 ).description   -- stamp1_description
      , g_target_tab( in_i ).base_code                 -- base_code
      , g_target_tab( in_i ).base_name                 -- base_name
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
      , iv_payment_date                                -- payment_date
      , lv_selling_month                               -- selling_month
      , g_target_tab( in_i ).bill_no                   -- bill_no
      , g_target_tab( in_i ).cust_code                 -- cust_code
      , g_target_tab( in_i ).cust_name                 -- cust_name
      , g_target_tab( in_i ).sales_outlets_code        -- sales_outlets_code
      , g_target_tab( in_i ).sales_outlets_name        -- sales_outlets_name
      , g_target_tab( in_i ).wholesale_ctrl_code       -- wholesale_code_admin
      , g_target_tab( in_i ).wholesale_ctrl_name       -- wholesale_name_admin
      , g_target_tab( in_i ).supplier_code             -- supplier_code
      , g_target_tab( in_i ).vendor_name               -- supplier_name
      , g_target_tab( in_i ).bank_name                 -- bank_name
      , g_target_tab( in_i ).bank_branch_name          -- bank_branch_name
      , g_target_tab( in_i ).bank_account_type         -- bank_acct_type
      , g_target_tab( in_i ).bank_account_num          -- bank_acct_no
      , g_target_tab( in_i ).item_code                 -- item_code
      , g_target_tab( in_i ).item_short_name           -- item_name
      , g_target_tab( in_i ).demand_unit_type          -- unit_type
      , g_target_tab( in_i ).demand_qty                -- demand_qty
      , g_target_tab( in_i ).demand_unit_price         -- demand_unit_price
      , g_target_tab( in_i ).demand_amt                -- demand_amt
      , ln_payment_qty                                 -- payment_qty
      , ln_payment_unit_price                          -- payment_unit_price
      , ln_payment_amt                                 -- payment_amt_disp
      , g_target_tab( in_i ).payment_amt               -- payment_amt_calc
      , gv_estimated_type                              -- normal_special_type
      , ln_market_amt                                  -- market_amt
      , gn_normal_store_deliver_amt                    -- normal_store_deliver_amt
      , gn_once_store_deliver_amt                      -- once_store_deliver_amt
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura MOD START
      , gn_net_selling_price                           -- net_selling_price
      , gn_normal_net_selling_price                    -- net_selling_price_low
      , lv_stamp                                       -- stamp
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura MOD END
      , ln_net_pct                                     -- net_pct
      , ln_margin_pct                                  -- margin_pct
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      , lv_error_rate                                  -- error_rate
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
      , ln_cs_margin_amt                               -- cs_margin_amt
      , ln_coverage_amt                                -- coverage_amt
      , ln_wholesale_margin_sum                        -- wholesale_margin_sum
      , ln_expansion_sales_amt                         -- expansion_sales_amt
      , ln_misc_acct_amt                               -- misc_acct_amt
      , NULL                                           -- no_data_message
      , cn_created_by                                  -- created_by
      , SYSDATE                                        -- creation_date
      , cn_last_updated_by                             -- last_updated_by
      , SYSDATE                                        -- last_update_date
      , cn_last_update_login                           -- last_update_login
      , cn_request_id                                  -- request_id
      , cn_program_application_id                      -- program_application_id
      , cn_program_id                                  -- program_id
      , SYSDATE                                        -- program_update_date
      );
    ELSE
      -- ===============================================
      -- 対象件数0件時ワークテーブルデータ登録
      -- ===============================================
      INSERT INTO xxcok_rep_wholesale_pay(
        p_base_code                -- 拠点コード(入力パラメータ)
      , p_wholesale_code_admin     -- 問屋管理コード(入力パラメータ)
      , p_cust_code                -- 顧客コード(入力パラメータ)
      , p_sales_outlets_code       -- 問屋帳合先コード(入力パラメータ)
      , p_payment_date             -- 支払年月日(入力パラメータ)
      , p_selling_month            -- 売上対象年月(入力パラメータ)
      , no_data_message            -- 0件メッセージ
      , created_by                 -- 作成者
      , creation_date              -- 作成日
      , last_updated_by            -- 最終更新者
      , last_update_date           -- 最終更新日
      , last_update_login          -- 最終更新ログイン
      , request_id                 -- 要求ID
      , program_application_id     -- コンカレント・プログラム・アプリケーションID
      , program_id                 -- コンカレント・プログラムID
      , program_update_date        -- プログラム更新日
      ) VALUES (
        iv_base_code               -- p_base_code
      , iv_wholesale_code_admin    -- p_wholesale_code_admin
      , iv_cust_code               -- p_cust_code
      , iv_sales_outlets_code      -- p_sales_outlets_code
      , iv_payment_date            -- p_payment_date
      , iv_selling_month           -- p_selling_month
      , gv_no_data_msg             -- no_data_message
      , cn_created_by              -- created_by
      , SYSDATE                    -- creation_date
      , cn_last_updated_by         -- last_updated_by
      , SYSDATE                    -- last_update_date
      , cn_last_update_login       -- last_update_login
      , cn_request_id              -- request_id
      , cn_program_application_id  -- program_application_id
      , cn_program_id              -- program_id
      , SYSDATE                    -- program_update_date
      );
    END IF;
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_wholesale_pay;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : 対象データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf                OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_month         IN  VARCHAR2  -- 売上対象年月
  , iv_wholesale_code_admin  IN  VARCHAR2  -- 問屋管理コード
  , iv_cust_code             IN  VARCHAR2  -- 顧客コード
  , iv_sales_outlets_code    IN  VARCHAR2  -- 問屋帳合先コード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'get_target_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf         VARCHAR2(5000)  DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode        VARCHAR2(1)     DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg         VARCHAR2(5000)  DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg         VARCHAR2(5000)  DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode        BOOLEAN         DEFAULT TRUE;              -- メッセージ出力関数戻り値
    lv_selling_month  VARCHAR2(6)     DEFAULT NULL;              -- 売上対象年月(YYYYMM)
    lv_dummy          VARCHAR2(20)    DEFAULT NULL;              -- 関数未使用項目
    ln_dummy          NUMBER          DEFAULT NULL;              -- 関数未使用項目
-- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
    ln_backmargin_amt    NUMBER       DEFAULT NULL;              -- 販売手数料
    ln_sales_support_amt NUMBER       DEFAULT NULL;              -- 販売協賛金
-- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 売上対象年月形式変換
    -- ===============================================
    IF ( iv_selling_month IS NOT NULL ) THEN
      lv_selling_month := TO_CHAR( TO_DATE( iv_selling_month, cv_format_yyyy_mm ), cv_format_yyyymm );
    END IF;
    -- ===============================================
    -- カーソル
    -- ===============================================
    OPEN  g_target_cur(
      iv_base_code             -- 拠点コード
    , iv_payment_date          -- 支払年月日
    , lv_selling_month         -- 売上対象年月
    , iv_wholesale_code_admin  -- 問屋管理コード
    , iv_cust_code             -- 顧客コード
    , iv_sales_outlets_code    -- 問屋帳合先コード
    );
    FETCH g_target_cur BULK COLLECT INTO g_target_tab;
    CLOSE g_target_cur;
    -- ===============================================
    -- 対象件数取得
    -- ===============================================
    gn_target_cnt := g_target_tab.COUNT;
    IF ( gn_target_cnt = 0 ) THEN
      -- ===============================================
      -- 対象データなしメッセージ取得
      -- ===============================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ワークテーブルデータ登録(A-4)
      -- ===============================================
      ins_wholesale_pay(
          ov_errbuf                =>  lv_errbuf                -- エラーバッファ
        , ov_retcode               =>  lv_retcode               -- リターンコード
        , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
        , iv_base_code             =>  iv_base_code             -- 拠点コード
        , iv_payment_date          =>  iv_payment_date          -- 支払年月日
        , iv_selling_month         =>  iv_selling_month         -- 売上対象年月
        , iv_wholesale_code_admin  =>  iv_wholesale_code_admin  -- 問屋管理コード
        , iv_cust_code             =>  iv_cust_code             -- 顧客コード
        , iv_sales_outlets_code    =>  iv_sales_outlets_code    -- 問屋帳合先コード
        , in_i                     =>  cn_number_0              -- LOOPカウンタ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      <<main_loop>>
      FOR i IN g_target_tab.FIRST .. g_target_tab.LAST LOOP
        -- ===============================================
        -- 見積書情報取得(A-3)
        -- ===============================================
        xxcok_common_pkg.get_wholesale_req_est_p(
          ov_errbuf                    => lv_errbuf                              -- エラーバッファ
        , ov_retcode                   => lv_retcode                             -- リターンコード
        , ov_errmsg                    => lv_errmsg                              -- エラーメッセージ
        , iv_wholesale_code            => g_target_tab( i ).wholesale_ctrl_code  -- 問屋管理コード
        , iv_sales_outlets_code        => g_target_tab( i ).sales_outlets_code   -- 問屋帳合先コード
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura MOD START
--        , iv_item_code                 => g_target_tab( i ).item_code            -- 品目コード
        , iv_item_code                 => g_target_tab( i ).item_code_judge      -- 品目コード(判定用)
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura MOD END
        , in_demand_unit_price         => g_target_tab( i ).payment_unit_price   -- 支払単価
        , iv_demand_unit_type          => g_target_tab( i ).demand_unit_type     -- 請求単位
        , iv_selling_month             => g_target_tab( i ).selling_month        -- 売上対象年月
        , ov_estimated_no              => lv_dummy                               -- 見積書No.(未使用)
        , on_quote_line_id             => ln_dummy                               -- 明細ID(未使用)
        , ov_emp_code                  => lv_dummy                               -- 担当者コード(未使用)
        , on_market_amt                => gn_market_amt                          -- 建値
        , on_allowance_amt             => gn_allowance_amt                       -- 値引(割戻し)
        , on_normal_store_deliver_amt  => gn_normal_store_deliver_amt            -- 通常店納
        , on_once_store_deliver_amt    => gn_once_store_deliver_amt              -- 今回店納
        , on_net_selling_price         => gn_net_selling_price                   -- NET価格
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
        , on_normal_net_selling_price  => gn_normal_net_selling_price            -- 通常NET価格(NET価格差照合時のみ)
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
        , ov_estimated_type            => gv_estimated_type                      -- 見積区分
-- Start 2009/04/16 Ver_ T1_ M.Hiruta
--        , on_backmargin_amt            => ln_dummy                               -- 販売手数料(未使用)
--        , on_sales_support_amt         => ln_dummy                               -- 販売協賛金(未使用)
        , on_backmargin_amt            => ln_backmargin_amt                      -- 販売手数料
        , on_sales_support_amt         => ln_sales_support_amt                   -- 販売協賛金
-- End   2009/04/16 Ver_ T1_ M.Hiruta
        );
        IF ( lv_retcode = cv_status_error ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10047
                        , iv_token_name1  => cv_token_ctrl_code                     -- CONTROL_CODE(問屋管理コード)
                        , iv_token_value1 => g_target_tab( i ).wholesale_ctrl_code
                        , iv_token_name2  => cv_token_balance_code                  -- BALANCE_CODE(問屋帳合先コード)
                        , iv_token_value2 => g_target_tab( i ).sales_outlets_code
                        , iv_token_name3  => cv_token_item_code                     -- ITEM_CODE(品目コード)
                        , iv_token_value3 => g_target_tab( i ).item_code
                        , iv_token_name4  => cv_token_demand_price                  -- DEMAND_PRICE(請求単価)
                        , iv_token_value4 => g_target_tab( i ).demand_unit_price
                        , iv_token_name5  => cv_token_demand_unit                   -- DEMAND_UNIT(請求単位)
                        , iv_token_value5 => g_target_tab( i ).demand_unit_type
                        , iv_token_name6  => cv_token_target_period                 -- TARGET_PERIOD(売上対象年月)
                        , iv_token_value6 => g_target_tab( i ).selling_month
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_outmsg
                        , in_new_line => cn_number_0
                        );
          RAISE global_api_expt;
        END IF;
        -- ===============================================
        -- ワークテーブルデータ登録(A-4)
        -- ===============================================
        ins_wholesale_pay(
          ov_errbuf                =>  lv_errbuf                -- エラーバッファ
        , ov_retcode               =>  lv_retcode               -- リターンコード
        , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
        , iv_base_code             =>  iv_base_code             -- 拠点コード
        , iv_payment_date          =>  iv_payment_date          -- 支払年月日
        , iv_selling_month         =>  iv_selling_month         -- 売上対象年月
        , iv_wholesale_code_admin  =>  iv_wholesale_code_admin  -- 問屋管理コード
        , iv_cust_code             =>  iv_cust_code             -- 顧客コード
        , iv_sales_outlets_code    =>  iv_sales_outlets_code    -- 問屋帳合先コード
        , in_i                     =>  i                        -- LOOPカウンタ
-- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
        , in_backmargin_amt        =>  ln_backmargin_amt        -- 販売手数料
        , in_sales_support_amt     =>  ln_sales_support_amt     -- 販売協賛金
-- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP main_loop;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_month         IN  VARCHAR2  -- 売上対象年月
  , iv_wholesale_code_admin  IN  VARCHAR2  -- 問屋管理コード
  , iv_cust_code             IN  VARCHAR2  -- 顧客コード
  , iv_sales_outlets_code    IN  VARCHAR2  -- 問屋帳合先コード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(10) := 'init';     -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    ld_chk_date DATE           DEFAULT NULL;              -- チェック用変数
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 初期処理エラー ***
    init_fail_expt             EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- プログラム入力項目を出力
    -- ===============================================
    -- 拠点コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00018
                  , iv_token_name1  => cv_token_location_code
                  , iv_token_value1 => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 支払年月日
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00071
                  , iv_token_name1  => cv_token_pay_date
                  , iv_token_value1 => iv_payment_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 売上対象年月
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00072
                  , iv_token_name1  => cv_token_target_period
                  , iv_token_value1 => iv_selling_month
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 問屋管理コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00068
                  , iv_token_name1  => cv_token_ctrl_code
                  , iv_token_value1 => iv_wholesale_code_admin
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 顧客コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00069
                  , iv_token_name1  => cv_token_cust_code
                  , iv_token_value1 => iv_cust_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- 問屋帳合先コード
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00070
                  , iv_token_name1  => cv_token_balance_code
                  , iv_token_value1 => iv_sales_outlets_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_1
                  );
    -- ===============================================
    -- 支払年月日型チェック
    -- ===============================================
    BEGIN
      ld_chk_date := TO_DATE( iv_payment_date, cv_format_fxyyyy_mm_dd );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10044
                      , iv_token_name1  => cv_token_pay_date
                      , iv_token_value1 => iv_payment_date
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE init_fail_expt;
    END;
    -- ===============================================
    -- 売上対象年月型チェック(NULLの場合、対象外)
    -- ===============================================
    IF ( iv_selling_month IS NOT NULL ) THEN
      BEGIN
        ld_chk_date := TO_DATE( iv_selling_month, cv_format_fxyyyy_mm );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10045
                        , iv_token_name1  => cv_token_target_period
                        , iv_token_value1 => iv_selling_month
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE init_fail_expt;
      END;
    END IF;
    -- ===============================================
    -- プロファイル取得(在庫組織コード_営業組織)
    -- ===============================================
    gv_org_code_sales := FND_PROFILE.VALUE( cv_prof_org_code_sales );
    IF ( gv_org_code_sales IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(営業単位ID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
-- 2009/12/18 Ver.1.7 [E_本稼動_00543] SCS S.Moriyama ADD START
    -- ===============================================
    -- プロファイル取得(販売手数料（問屋）)
    -- ===============================================
    gv_aff3_fee := FND_PROFILE.VALUE( cv_prof_aff3_fee );
    IF ( gv_aff3_fee IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_aff3_fee
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(販売協賛金（問屋）)
    -- ===============================================
    gv_aff3_support := FND_PROFILE.VALUE( cv_prof_aff3_support );
    IF ( gv_aff3_support IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_aff3_support
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(問屋条件)
    -- ===============================================
    gv_aff4_fee := FND_PROFILE.VALUE( cv_prof_aff4_fee );
    IF ( gv_aff4_fee IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_aff4_fee
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(拡売費)
    -- ===============================================
    gv_aff4_support := FND_PROFILE.VALUE( cv_prof_aff4_support );
    IF ( gv_aff4_support IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_aff4_support
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
    -- ===============================================
    -- プロファイル取得(警告マージン率)
    -- ===============================================
    gn_warn_margin_rate := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_warn_margin_rate ) );
    IF ( gn_warn_margin_rate IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_warn_margin_rate
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
-- 2009/12/18 Ver.1.7 [E_本稼動_00543] SCS S.Moriyama ADD END
    -- ===============================================
    -- 在庫組織ID取得
    -- ===============================================
    gn_org_id_sales := xxcoi_common_pkg.get_organization_id( gv_org_code_sales );
    IF ( gn_org_id_sales IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00013
                    , iv_token_name1  => cv_token_org_code
                    , iv_token_value1 => gv_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 業務処理日付取得
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
    -- ===============================================
    -- クイックコード取得(問屋販売条件支払チェック表印)
    -- ===============================================
    <<lookup_stamp_loop>>
    FOR lookup_stamp_rec IN lookup_stamp_cur LOOP
      g_lookup_stamp_tab( lookup_stamp_rec.lookup_code ).meaning     := lookup_stamp_rec.meaning;
      g_lookup_stamp_tab( lookup_stamp_rec.lookup_code ).description := lookup_stamp_rec.description;
    END LOOP lookup_stamp_loop;
    IF ( g_lookup_stamp_tab.COUNT = 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00015
                    , iv_token_name1  => cv_token_lookup_value_set
                    , iv_token_value1 => cv_lookup_type_stamp
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- クイックコード取得(容器群コード（チルド）)
    -- ===============================================
    OPEN lookup_chilled_cur;
    FETCH lookup_chilled_cur BULK COLLECT INTO g_lookup_chilled_tab;
    CLOSE lookup_chilled_cur;
    IF ( g_lookup_chilled_tab.COUNT = 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00015
                    , iv_token_name1  => cv_token_lookup_value_set
                    , iv_token_value1 => cv_lookup_type_chilled
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  EXCEPTION
    -- *** 初期処理エラー ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      IF ( lookup_stamp_cur%ISOPEN ) THEN
        CLOSE lookup_stamp_cur;
      END IF;
      IF ( lookup_chilled_cur%ISOPEN ) THEN
        CLOSE lookup_chilled_cur;
      END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD START
      IF ( lookup_stamp_cur%ISOPEN ) THEN
        CLOSE lookup_stamp_cur;
      END IF;
      IF ( lookup_chilled_cur%ISOPEN ) THEN
        CLOSE lookup_chilled_cur;
      END IF;
-- 2012/03/12 Ver.1.11 [E_本稼動_08318] SCSK K.Nakamura ADD END
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_month         IN  VARCHAR2  -- 売上対象年月
  , iv_wholesale_code_admin  IN  VARCHAR2  -- 問屋管理コード
  , iv_cust_code             IN  VARCHAR2  -- 顧客コード
  , iv_sales_outlets_code    IN  VARCHAR2  -- 問屋帳合先コード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'submain';    -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      ov_errbuf                => lv_errbuf                -- エラー・メッセージ
    , ov_retcode               => lv_retcode               -- リターン・コード
    , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ
    , iv_base_code             => iv_base_code             -- 拠点コード
    , iv_payment_date          => iv_payment_date          -- 支払年月日
    , iv_selling_month         => iv_selling_month         -- 売上対象年月
    , iv_wholesale_code_admin  => iv_wholesale_code_admin  -- 問屋管理コード
    , iv_cust_code             => iv_cust_code             -- 顧客コード
    , iv_sales_outlets_code    => iv_sales_outlets_code    -- 問屋帳合先コード
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- 対象データ取得(A-2)・見積書情報取得(A-3)・ワークテーブルデータ登録(A-4)
    -- ===============================================
    get_target_data(
      ov_errbuf                => lv_errbuf                -- エラー・メッセージ
    , ov_retcode               => lv_retcode               -- リターン・コード
    , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ
    , iv_base_code             => iv_base_code             -- 拠点コード
    , iv_payment_date          => iv_payment_date          -- 支払年月日
    , iv_selling_month         => iv_selling_month         -- 売上対象年月
    , iv_wholesale_code_admin  => iv_wholesale_code_admin  -- 問屋管理コード
    , iv_cust_code             => iv_cust_code             -- 顧客コード
    , iv_sales_outlets_code    => iv_sales_outlets_code    -- 問屋帳合先コード
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ワークテーブルデータ確定
    -- ===============================================
    COMMIT;
    -- ===============================================
    -- SVF起動(A-5)
    -- ===============================================
    start_svf(
      ov_errbuf   => lv_errbuf   -- エラー・メッセージ
    , ov_retcode  => lv_retcode  -- リターン・コード
    , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ワークテーブルデータ削除(A-6)
    -- ===============================================
    del_wholesale_pay(
      ov_errbuf   => lv_errbuf   -- エラー・メッセージ
    , ov_retcode  => lv_retcode  -- リターン・コード
    , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf                   OUT VARCHAR2  -- エラー・メッセージ
  , retcode                  OUT VARCHAR2  -- リターン・コード
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_month         IN  VARCHAR2  -- 売上対象年月
  , iv_wholesale_code_admin  IN  VARCHAR2  -- 問屋管理コード
  , iv_cust_code             IN  VARCHAR2  -- 顧客コード
  , iv_sales_outlets_code    IN  VARCHAR2  -- 問屋帳合先コード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name        CONSTANT VARCHAR2(10) := 'main';        -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg        VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- 終了メッセージコード
    lb_retcode       BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
--
  BEGIN
    -- ===============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    , iv_which   => cv_which
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf                => lv_errbuf                -- エラー・メッセージ
    , ov_retcode               => lv_retcode               -- リターン・コード
    , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ
    , iv_base_code             => iv_base_code             -- 拠点コード
    , iv_payment_date          => iv_payment_date          -- 支払年月日
    , iv_selling_month         => iv_selling_month         -- 売上対象年月
    , iv_wholesale_code_admin  => iv_wholesale_code_admin  -- 問屋管理コード
    , iv_cust_code             => iv_cust_code             -- 顧客コード
    , iv_sales_outlets_code    => iv_sales_outlets_code    -- 問屋帳合先コード
    );
    -- ===============================================
    -- エラー出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errmsg      -- メッセージ
                    , in_new_line => cn_number_0    -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errbuf
                    , in_new_line => cn_number_1
                    );
    END IF;
    -- ===============================================
    -- 対象件数出力
    -- ===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90000
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
      gn_error_cnt  := cn_number_1;
    ELSE
      IF ( gn_target_cnt = cn_number_0 ) THEN
        gn_normal_cnt := cn_number_0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90001
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- エラー件数出力
    -- ===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90002
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_1
                  );
    -- ===============================================
    -- 処理終了メッセージ出力
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    ELSE
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- 終了ステータスエラー時、ロールバック
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK021A06R;
/
