CREATE OR REPLACE PACKAGE BODY XXCOK014A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A04R(body)
 * Description      : 「支払先」「売上計上拠点」「顧客」単位に販手残高情報を出力
 * MD.050           : 自販機販手残高一覧 MD050_COK_014_A04
 * Version          : 1.18
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_worktable_data     ワークテーブルデータ削除(A-9)
 *  start_svf              SVF起動(A-8)
 *  upd_resv_payment_rec   支払ステータス「消込済」更新処理(A-11)
 *  upd_resv_payment       支払ステータス「自動繰越」更新処理(A-10)
 *  ins_worktable_data     ワークテーブルデータ登録(A-7)
 *  upd_worktable_data     ワークテーブルデータ更新処理(A-12)
 *  break_judge            ブレイク判定処理(A-6)
 *  get_bm_contract_err    販手エラー情報抽出処理(A-5)
 *  get_vendor_data        仕入先・銀行情報抽出処理(A-4)
 *  get_cust_data          売上拠点・顧客情報抽出処理(A-3)
 *  get_target_data        販手残高情報抽出処理(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   SCS T.Taniguchi  新規作成
 *  2009/02/18    1.1   SCS T.Taniguchi  [障害COK_046]
 *                                       1.仕入先取得条件修正
 *                                       2.入力パラメータ支払日のフォーマットチェック修正
 *  2009/02/25    1.2   SCS T.Taniguchi  [障害COK_054] 入力パラメータの表示対象名を値セットより取得
 *  2009/03/02    1.3   SCS M.Hiruta     [障害COK_068]
 *                                       1.自拠点含むのデータ抽出条件修正
 *                                       2.当月BM及び電気料を当月分のみ集計
 *  2009/04/17    1.4   SCS T.Taniguchi  [障害T1_0647] 桁数修正
 *  2009/04/23    1.5   SCS T.Taniguchi  [障害T1_0684] 問合せ拠点修正
 *  2009/05/19    1.6   SCS T.Taniguchi  [障害T1_1070] グローバルカーソルのソート順追加
 *  2009/07/15    1.7   SCS T.Taniguchi  [障害0000689] 銀行手数料負担者、全支払の保留フラグの取得先変更
 *  2009/09/17    1.8   SCS S.Moriyama   [障害0001390] パラメータ制御変更に伴う所属部門業務管理部チェックを削除
 *  2009/10/02    1.9   SCS S.Moriyama   [障害E_T3_00630] VDBM残高一覧表が出力されない
 *                                                        銀行コード、支店コードの異常桁数対応
 *  2009/12/15    1.10  SCS K.Nakamura   [障害E_本稼動_00461] ソート順対応によるBM支払区分(コード値)の追加
 *                                                            1顧客に前月・当月の2レコード存在する場合、締め・支払日共に最新の日付を設定
 *  2010/01/27    1.11  SCS K.Kiriu      [障害E_本稼動_01176] 口座種別追加に伴う口座種別名取得元クイックコード変更
 *  2011/01/24    1.12  SCS S.Niki       [障害E_本稼動_06199] パフォーマンス改善対応
 *  2011/03/15    1.13  SCS S.Niki       [障害E_本稼動_05408,05409] 年次切替対応
 *  2011/04/28    1.14  SCS S.Niki       [障害E_本稼動_02100] 現金支払の場合、銀行情報に固定文字を出力する対応
 *  2012/07/23    1.15  SCSK K.Onotsuka  [障害E_本稼動_08365,08367] VDBM残高一覧の支払ステータスに「消込済」「自動繰越」
 *                                                              残高取消後も「前月まで未払」金額を出力
 *  2013/01/29    1.16  SCSK K.Taniguchi [障害E_本稼動_10381] 支払ステータス「自動繰越」出力条件変更
 *  2013/04/04    1.17  SCSK K.Nakamura  [障害E_本稼動_10595,10609] 支払ステータス「保留」「消込済」出力条件変更
 *  2013/05/21    1.18  SCSK S.Niki      [障害E_本稼動_10595再]「消込済」出力条件変更
 *                                       [障害E_本稼動_10411]   パラメータ「支払先コード」「支払ステータス」追加
 *                                                              変動電気代未入力マーク出力、ソート順変更
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCOK014A04R';
  -- アプリケーション短縮名
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCCP';
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
  cv_msg_code_00001          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00001';          -- 対象データなしメッセージ
  cv_msg_code_00003          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00003';          -- プロファイル取得エラー
  cv_msg_code_10337          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10337';          -- 支払日フォーマットエラー
  cv_msg_code_10338          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10338';          -- 表示対象チェックエラー
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama DEL START
--  cv_msg_code_00012          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00012';          -- 所属拠点取得エラー
--  cv_msg_code_10372          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10372';          -- 拠点セキュリティーエラー
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama DEL END
  cv_msg_code_00048          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00048';          -- 売上計上拠点情報取得エラー
  cv_msg_code_00047          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00047';          -- 売上計上拠点情報複数件エラー
  cv_msg_code_00035          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00035';          -- 顧客情報取得エラー
  cv_msg_code_00046          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00046';          -- 顧客情報複数件エラー
  cv_msg_code_10333          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10333';          -- 仕入・銀行情報取得エラー
  cv_msg_code_10334          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10334';          -- 仕入・銀行情報複数件エラー
  cv_msg_code_00015          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00015';          -- クイックコード取得エラー
  cv_msg_code_00071          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00071';          -- パラメータ(支払年月日)
  cv_msg_code_00073          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00073';          -- パラメータ(問合せ担当拠点)
  cv_msg_code_00074          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00074';          -- パラメータ(売上計上拠点)
  cv_msg_code_00075          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00075';          -- パラメータ(表示対象)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  cv_msg_code_00094          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00094';          -- パラメータ(支払先コード)
  cv_msg_code_00095          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00095';          -- パラメータ(支払ステータス)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
  cv_msg_code_00040          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00040';          -- SVF起動APIエラー
  cv_msg_code_90000          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000';          -- 対象件数
  cv_msg_code_90001          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90001';          -- 成功件数
  cv_msg_code_90002          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002';          -- エラー件数
  cv_msg_code_90004          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004';          -- 正常終了
  cv_msg_code_90005          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90005';          -- 警告終了
  cv_msg_code_90006          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006';          -- エラー終了全ロールバック
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
--  cv_msg_code_00013          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00013';          -- 在庫組織ID取得エラー
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
  cv_msg_code_10393          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10393';          -- 削除エラー
  cv_msg_code_10394          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10394';          -- ロックエラー
  cv_msg_code_00028          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00028';          -- 業務処理日付取得エラー
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  cv_msg_code_10535          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10535';          -- 帳票ワークテーブル更新エラー
  cv_msg_code_10536          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10536';          -- 帳票ワークテーブル削除エラー
  cv_msg_code_10537          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10537';          -- 帳票ワークテーブル登録エラー
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
  -- トークン
  cv_token_user_id           CONSTANT VARCHAR2(7)   := 'USER_ID';
  cv_token_sales_loc         CONSTANT VARCHAR2(9)   := 'SALES_LOC';
  cv_token_cust_code         CONSTANT VARCHAR2(9)   := 'CUST_CODE';
  cv_token_cost_code         CONSTANT VARCHAR2(9)   := 'COST_CODE';
  cv_token_vendor_code       CONSTANT VARCHAR2(11)  := 'VENDOR_CODE';
  cv_token_vendor_site_code  CONSTANT VARCHAR2(16)  := 'VENDOR_SITE_CODE';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(16)  := 'LOOKUP_VALUE_SET';
  cv_token_location_code     CONSTANT VARCHAR2(13)  := 'LOCATION_CODE';
  cv_token_profile           CONSTANT VARCHAR2(7)   := 'PROFILE';
  cv_token_count             CONSTANT VARCHAR2(5)   := 'COUNT';
  cv_token_pay_date          CONSTANT VARCHAR2(8)   := 'PAY_DATE';
  cv_token_ref_base_cd       CONSTANT VARCHAR2(13)  := 'REF_BASE_CODE';
  cv_token_selling_base_cd   CONSTANT VARCHAR2(17)  := 'SELLING_BASE_CODE';
  cv_token_target_disp       CONSTANT VARCHAR2(11)  := 'TARGET_DISP';
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  cv_token_payment_cd        CONSTANT VARCHAR2(12)  := 'PAYMENT_CODE';
  cv_token_resv_payment      CONSTANT VARCHAR2(12)  := 'RESV_PAYMENT';
  cv_token_errmsg            CONSTANT VARCHAR2(6)   := 'ERRMSG';
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
--  cv_token_org_code          CONSTANT VARCHAR2(8)   := 'ORG_CODE';
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
  cv_token_request_id        CONSTANT VARCHAR2(10)  := 'REQUEST_ID';
  -- プロファイル
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama DEL START
--  cv_prof_aff2_dept_act      CONSTANT VARCHAR2(20)  := 'XXCOK1_AFF2_DEPT_ACT';               --部門コード_業務管理部
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama DEL END
  cv_prof_error_mark         CONSTANT VARCHAR2(32)  := 'XXCOK1_BL_LIST_PROMPT_ERROR_MARK';   --残高一覧_ｴﾗｰﾏｰｸ見出し
  cv_prof_pay_stop_name      CONSTANT VARCHAR2(35)  := 'XXCOK1_BL_LIST_PROMPT_PAY_STOP_NAME';--残高一覧_停止中見出し
  cv_prof_bk_trns_fee_we     CONSTANT VARCHAR2(23)  := 'XXCOK1_BANK_TRNS_FEE_WE';            --振込手数料_当方
  cv_prof_bk_trns_fee_ctpty  CONSTANT VARCHAR2(26)  := 'XXCOK1_BANK_TRNS_FEE_CTPTY';         --振込手数料_相手方
  cv_prof_pay_res_name       CONSTANT VARCHAR2(34)  := 'XXCOK1_BL_LIST_PROMPT_PAY_RES_NAME'; --残高一覧_保留見出し
-- 2012/07/04 Ver.1.15 [障害E_本稼動_08365] SCSK K.Onotsuka ADD START
  cv_prof_pay_rec_name       CONSTANT VARCHAR2(34)  := 'XXCOK1_BL_LIST_PROMPT_PAY_REC_NAME';      --残高一覧_消込済見出し
  cv_prof_pay_auto_res_name  CONSTANT VARCHAR2(39)  := 'XXCOK1_BL_LIST_PROMPT_PAY_AUTO_RES_NAME'; --残高一覧_自動繰越見出し
-- 2012/07/04 Ver.1.15 [障害E_本稼動_08365] SCSK K.Onotsuka ADD END
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD START
  cv_prof_trans_criterion    CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_TRANS_CRITERION';    --銀行手数料_振込額基準
  cv_prof_less_fee_criterion CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_LESS_CRITERION';     --銀行手数料_基準額未満
  cv_prof_more_fee_criterion CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_MORE_CRITERION';     --銀行手数料_基準額以上
  cv_prof_bm_tax             CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_TAX';                      --販売手数料_消費税率
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD END
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
--  cv_prof_org_code_sales     CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';              --在庫組織コード_営業組織
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
  cv_prof_org_id             CONSTANT VARCHAR2(6)   := 'ORG_ID';                             --営業単位ID
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  cv_prof_unpaid_elec_mark   CONSTANT VARCHAR2(38)  := 'XXCOK1_BL_LIST_PROMPT_UNPAID_ELEC_MARK';
                                                                                             --残高一覧_変動電気代未払ﾏｰｸ見出し
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
  -- フォーマット
  cv_format_yyyymmdd         CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_format_yyyymmdd2        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
-- 2012/07/10 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka ADD START
  cv_format_mm               CONSTANT VARCHAR2(6)   := 'MM';
-- 2012/07/10 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka ADD END
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)   := '.';
  -- 数値
  cn_number_0                CONSTANT NUMBER        := 0;
  cn_number_1                CONSTANT NUMBER        := 1;
  -- 顧客区分
  cv_cust_class_code1        CONSTANT VARCHAR2(1)   := '1';  -- 拠点
  cv_cust_class_code10       CONSTANT VARCHAR2(2)   := '10'; -- 顧客
  -- フラグ
  cv_flag_y                  CONSTANT VARCHAR2(1)   := 'Y';
  -- 参照タイプ
  cv_lookup_type_bm_kbn      CONSTANT VARCHAR2(20)  := 'XXCMM_BM_PAYMENT_KBN';
-- 2010/01/27 Ver.1.11 [障害E_本稼動_01176] SCS K.Kiriu START
--  cv_lookup_type_bank        CONSTANT VARCHAR2(20)  := 'JP_BANK_ACCOUNT_TYPE';
  cv_lookup_type_bank        CONSTANT VARCHAR2(16)  := 'XXCSO1_KOZA_TYPE';
-- 2010/01/27 Ver.1.11 [障害E_本稼動_01176] SCS K.Kiriu END
  -- 値セット
  cv_set_name                CONSTANT VARCHAR2(18)  := 'XXCOK1_TARGET_DISP';
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  cv_set_name_rp             CONSTANT VARCHAR2(19)  := 'XXCOK1_RESV_PAYMENT';
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
  -- SVF起動パラメータ
  cv_file_id                 CONSTANT VARCHAR2(12)  := 'XXCOK014A04R';       -- 帳票ID
  cv_output_mode             CONSTANT VARCHAR2(1)   := '1';                  -- 出力区分(PDF出力)
  cv_frm_file                CONSTANT VARCHAR2(16)  := 'XXCOK014A04S.xml';   -- フォーム様式ファイル名
  cv_vrq_file                CONSTANT VARCHAR2(16)  := 'XXCOK014A04S.vrq';   -- クエリー様式ファイル名
  cv_pdf                     CONSTANT VARCHAR2(4)   := '.pdf';               -- 出力ファイル拡張子
  -- 表示対象
  cv_target_disp1            CONSTANT VARCHAR2(1)   := '1'; -- 自拠点のみ
  cv_target_disp2            CONSTANT VARCHAR2(1)   := '2'; -- 自拠点含む
  cv_target_disp1_nm         CONSTANT VARCHAR2(1)   := '1'; -- 自拠点のみ
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki ADD START
  -- 固定文字
  cv_em_dash                 CONSTANT VARCHAR2(2)   := '―'; -- 全角ダッシュ
-- 20.1/04/26 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki ADD END
-- 2012/07/04 Ver.1.15 [障害E_本稼動_08365] SCSK K.Onotsuka ADD START
  cv_proc_type0_upd          CONSTANT VARCHAR2(1)  := '0';  -- (UPDATE用)処理区分：保留解除(初期値)
  cv_proc_type1_upd          CONSTANT VARCHAR2(1)  := '1';  -- (UPDATE用)処理区分：消込済
  cv_proc_type2_upd          CONSTANT VARCHAR2(1)  := '2';  -- (UPDATE用)処理区分：保留
-- 2012/07/04 Ver.1.15 [障害E_本稼動_08365] SCSK K.Onotsuka ADD END
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD START
  cv_bm_payment_type1        CONSTANT VARCHAR2(1)  := '1'; -- BM支払区分(1：本振（案内書あり）)
  cv_bm_payment_type2        CONSTANT VARCHAR2(1)  := '2'; -- BM支払区分(2：本振（案内書なし）)
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD END
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  ct_status_comp             CONSTANT xxcso_contract_managements.status%TYPE           := '1';  -- 確定済
  ct_cooperate_comp          CONSTANT xxcso_contract_managements.cooperate_flag%TYPE   := '1';  -- 連携済み
  ct_electricity_type0       CONSTANT xxcso_sp_decision_headers.electricity_type%TYPE  := '0';  -- 電気代なし
  ct_electricity_type2       CONSTANT xxcso_sp_decision_headers.electricity_type%TYPE  := '2';  -- 変動電気代
  cv_ja                      CONSTANT VARCHAR2(2)  := 'JA'; -- 日本語
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  gn_target_cnt              NUMBER        DEFAULT 0;    -- 対象件数
  gn_normal_cnt              NUMBER        DEFAULT 0;    -- 正常件数
  gn_error_cnt               NUMBER        DEFAULT 0;    -- エラー件数
  gd_payment_date            DATE          DEFAULT NULL; -- 支払日
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama DEL START
--  gv_base_code               VARCHAR2(4)   DEFAULT NULL; -- 所属拠点コード
--  gv_aff2_dept_act           VARCHAR2(4)   DEFAULT NULL; -- 業務管理部の部門コード
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama DEL END
  gv_error_mark              VARCHAR2(2)   DEFAULT NULL; -- エラーマーク見出し
  gv_pay_stop_name           VARCHAR2(6)   DEFAULT NULL; -- 停止中見出し
  gv_bk_trns_fee_we          VARCHAR2(10)  DEFAULT NULL; -- 振込手数料_当方
  gv_bk_trns_fee_ctpty       VARCHAR2(8)   DEFAULT NULL; -- 振込手数料_相手方
  gv_pay_res_name            VARCHAR2(4)   DEFAULT NULL; -- 保留見出し
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD START
  gn_trans_fee               NUMBER        DEFAULT 0;    -- 銀行手数料(振込額基準)
  gn_less_fee                NUMBER        DEFAULT 0;    -- 銀行手数料(基準未満)
  gn_more_fee                NUMBER        DEFAULT 0;    -- 銀行手数料(基準以上)
  gn_bm_tax                  NUMBER        DEFAULT 0;    -- 消費税率
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD END
-- 2012/07/04 Ver.1.15 [障害E_本稼動_08365] SCSK K.Onotsuka ADD START
  gv_pay_rec_name            VARCHAR2(6)   DEFAULT NULL; -- 消込済見出し
  gv_pay_auto_res_name       VARCHAR2(8)   DEFAULT NULL; -- 自動繰越見出し
-- 2012/07/04 Ver.1.15 [障害E_本稼動_08365] SCSK K.Onotsuka ADD END
  gv_ref_base_code           VARCHAR2(4)   DEFAULT NULL; -- 問合せ担当拠点
  gv_selling_base_code       VARCHAR2(4)   DEFAULT NULL; -- 売上計上拠点
  gv_target_disp             VARCHAR2(12)  DEFAULT NULL; -- 表示対象
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  gv_unpaid_elec_mark        VARCHAR2(2)   DEFAULT NULL;                           -- 変動電気代未払マーク見出し
  gt_payment_code            xxcok_rep_bm_balance.payment_code%TYPE  DEFAULT NULL; -- 支払先コード
  gt_resv_payment            xxcok_rep_bm_balance.resv_payment%TYPE  DEFAULT NULL; -- 支払ステータス
  gv_resv_payment_nm         VARCHAR2(10)  DEFAULT NULL;                           -- 支払ステータス名
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
--  gv_org_code                VARCHAR2(50)  DEFAULT NULL; -- 在庫組織コード_営業組織
--  gn_organization_id         NUMBER        DEFAULT NULL; -- 在庫組織ID
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
  gv_no_data_msg             VARCHAR2(30)  DEFAULT NULL; -- 対象データなしメッセージ
  gn_index                   NUMBER        DEFAULT 0;    -- 索引
  gn_org_id                  NUMBER        DEFAULT NULL; -- 営業単位ID
  gd_process_date            DATE          DEFAULT NULL; -- 業務処理日付
  gv_target_disp_nm          VARCHAR2(20)  DEFAULT NULL; -- 表示対象名
  -- 退避用
  gt_payment_code_bk         xxcok_rep_bm_balance.payment_code%TYPE               DEFAULT NULL; -- 支払先コード
  gt_payment_name_bk         xxcok_rep_bm_balance.payment_name%TYPE               DEFAULT NULL; -- 支払先名
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD START
--  gt_bank_no_bk              xxcok_rep_bm_balance.bank_no%TYPE                    DEFAULT NULL; -- 銀行番号
  gt_bank_no_bk              ap_bank_branches.bank_number%TYPE                    DEFAULT NULL; -- 銀行番号
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD END
  gt_bank_name_bk            xxcok_rep_bm_balance.bank_name%TYPE                  DEFAULT NULL; -- 銀行名
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD START
--  gt_bank_branch_no_bk       xxcok_rep_bm_balance.bank_branch_no%TYPE             DEFAULT NULL; -- 銀行支店番号
  gt_bank_branch_no_bk       ap_bank_branches.bank_num%TYPE                       DEFAULT NULL; -- 銀行支店番号
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD END
  gt_bank_branch_name_bk     xxcok_rep_bm_balance.bank_branch_name%TYPE           DEFAULT NULL; -- 銀行支店名
  gt_bank_acct_type_bk       xxcok_rep_bm_balance.bank_acct_type%TYPE             DEFAULT NULL; -- 口座種別
  gt_bank_acct_type_name_bk  xxcok_rep_bm_balance.bank_acct_type_name%TYPE        DEFAULT NULL; -- 口座種別名
  gt_bank_acct_no_bk         xxcok_rep_bm_balance.bank_acct_no%TYPE               DEFAULT NULL; -- 口座番号
  gt_bank_acct_name_bk       xxcok_rep_bm_balance.bank_acct_name%TYPE             DEFAULT NULL; -- 銀行口座名
  gt_ref_base_code_bk        xxcok_rep_bm_balance.ref_base_code%TYPE              DEFAULT NULL; -- 問合せ担当拠点コード
  gt_ref_base_name_bk        xxcok_rep_bm_balance.ref_base_name%TYPE              DEFAULT NULL; -- 問合せ担当拠点名
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi START
--  gt_bm_type_bk              xxcmn_lookup_values_v.lookup_code%TYPE               DEFAULT NULL; -- BM支払区分
  gt_bm_type_bk              xxcok_lookups_v.lookup_code%TYPE                     DEFAULT NULL; -- BM支払区分
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi END
  gt_bm_payment_type_bk      xxcok_rep_bm_balance.bm_payment_type%TYPE            DEFAULT NULL; -- BM支払区分名
  gt_bank_trns_fee_bk        xxcok_rep_bm_balance.bank_trns_fee%TYPE              DEFAULT NULL; -- 振込手数料
  gt_payment_stop_bk         xxcok_rep_bm_balance.payment_stop%TYPE               DEFAULT NULL; -- 支払停止
  gt_selling_base_code_bk    xxcok_rep_bm_balance.selling_base_code%TYPE          DEFAULT NULL; -- 売上計上拠点コード
  gt_selling_base_name_bk    xxcok_rep_bm_balance.selling_base_name%TYPE          DEFAULT NULL; -- 売上計上拠点名
  gt_warnning_mark_bk        xxcok_rep_bm_balance.warnning_mark%TYPE              DEFAULT NULL; -- 警告マーク
  gt_cust_code_bk            xxcok_rep_bm_balance.cust_code%TYPE                  DEFAULT NULL; -- 顧客コード
  gt_cust_name_bk            xxcok_rep_bm_balance.cust_name%TYPE                  DEFAULT NULL; -- 顧客名
  gt_resv_payment_bk         xxcok_rep_bm_balance.resv_payment%TYPE               DEFAULT NULL; -- 支払保留
  gt_payment_date_bk         xxcok_rep_bm_balance.payment_date%TYPE               DEFAULT NULL; -- 支払日
  gt_closing_date_bk         xxcok_rep_bm_balance.closing_date%TYPE               DEFAULT NULL; -- 締め日
  gt_section_code_bk         xxcok_rep_bm_balance.selling_base_section_code%TYPE  DEFAULT NULL; -- 地区コード
  -- 集計用
  gt_unpaid_last_month_sum xxcok_rep_bm_balance.unpaid_last_month%TYPE          DEFAULT 0;  -- 前月までの未払
  gt_bm_this_month_sum     xxcok_rep_bm_balance.bm_this_month%TYPE              DEFAULT 0;  -- 当月BM
  gt_electric_amt_sum      xxcok_rep_bm_balance.electric_amt%TYPE               DEFAULT 0;  -- 電気料
  gt_unpaid_balance_sum    xxcok_rep_bm_balance.unpaid_balance%TYPE             DEFAULT 0;  -- 未払残高
  -- ===============================
  -- レコードタイプの宣言部
  -- ===============================
  TYPE rep_bm_balance_rec IS RECORD(
    PAYMENT_CODE                 VARCHAR2(9)   -- 支払先コード
   ,PAYMENT_NAME                 VARCHAR2(240) -- 支払先名
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD START
--   ,BANK_NO                      VARCHAR2(4)   -- 銀行番号
   ,BANK_NO                      VARCHAR2(30)  -- 銀行番号
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD END
   ,BANK_NAME                    VARCHAR2(60)  -- 銀行名
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD START
--   ,BANK_BRANCH_NO               VARCHAR2(4)   -- 銀行支店番号
   ,BANK_BRANCH_NO               VARCHAR2(25)  -- 銀行支店番号
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD END
   ,BANK_BRANCH_NAME             VARCHAR2(60)  -- 銀行支店名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki ADD START
--   ,BANK_ACCT_TYPE               VARCHAR2(1)   -- 口座種別
   ,BANK_ACCT_TYPE               VARCHAR2(2)   -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki ADD END
   ,BANK_ACCT_TYPE_NAME          VARCHAR2(4)   -- 口座種別名
-- 2009/04/17 Ver.1.4 [障害T1_0647] SCS T.Taniguchi START
--   ,BANK_ACCT_NO                 VARCHAR2(7)   -- 口座番号
   ,BANK_ACCT_NO                 VARCHAR2(30)  -- 口座番号
-- 2009/04/17 Ver.1.4 [障害T1_0647] SCS T.Taniguchi END
   ,BANK_ACCT_NAME               VARCHAR2(150) -- 銀行口座名
   ,REF_BASE_CODE                VARCHAR2(4)   -- 問合せ担当拠点コード
   ,REF_BASE_NAME                VARCHAR2(240) -- 問合せ担当拠点名
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD START
   ,BM_PAYMENT_CODE              VARCHAR2(30)  -- BM支払区分(コード値)
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD END
   ,BM_PAYMENT_TYPE              VARCHAR2(80)  -- BM支払区分
   ,BANK_TRNS_FEE                VARCHAR2(20)  -- 振込手数料
   ,PAYMENT_STOP                 VARCHAR2(20)  -- 支払停止
   ,SELLING_BASE_CODE            VARCHAR2(4)   -- 売上計上拠点コード
   ,SELLING_BASE_NAME            VARCHAR2(240) -- 売上計上拠点名
   ,WARNNING_MARK                VARCHAR2(2)   -- 警告マーク
   ,CUST_CODE                    VARCHAR2(9)   -- 顧客コード
   ,CUST_NAME                    VARCHAR2(360) -- 顧客名
   ,BM_THIS_MONTH                NUMBER        -- 当月BM
   ,ELECTRIC_AMT                 NUMBER        -- 電気料
   ,UNPAID_LAST_MONTH            NUMBER        -- 前月までの未払
   ,UNPAID_BALANCE               NUMBER        -- 未払残高
-- 2012/07/11 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka UPD START
--   ,RESV_PAYMENT                 VARCHAR2(4)   -- 支払保留
   ,RESV_PAYMENT                 VARCHAR2(8)   -- 支払保留
-- 2012/07/11 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka UPD START
   ,PAYMENT_DATE                 DATE          -- 支払日
   ,CLOSING_DATE                 DATE          -- 締め日
   ,SELLING_BASE_SECTION_CODE    VARCHAR2(5)   -- 地区コード（売上計上拠点）
  );
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki ADD START
  TYPE g_target_rtype IS RECORD(
    bm_balance_id                xxcok_backmargin_balance.bm_balance_id%TYPE           -- 内部ID
   ,base_code                    xxcok_backmargin_balance.base_code%TYPE               -- 拠点コード
   ,supplier_code                xxcok_backmargin_balance.supplier_code%TYPE           -- 仕入先コード
   ,supplier_site_code           xxcok_backmargin_balance.supplier_site_code%TYPE      -- 仕入先サイトコード
   ,cust_code                    xxcok_backmargin_balance.cust_code%TYPE               -- 顧客コード
   ,closing_date                 xxcok_backmargin_balance.closing_date%TYPE            -- 締め日
   ,backmargin                   xxcok_backmargin_balance.backmargin%TYPE              -- 販売手数料
   ,backmargin_tax               xxcok_backmargin_balance.backmargin_tax%TYPE          -- 販売手数料（消費税額）
   ,electric_amt                 xxcok_backmargin_balance.electric_amt%TYPE            -- 電気料
   ,electric_amt_tax             xxcok_backmargin_balance.electric_amt_tax%TYPE        -- 電気料（消費税額）
   ,expect_payment_date          xxcok_backmargin_balance.expect_payment_date%TYPE     -- 支払予定日
   ,expect_payment_amt_tax       xxcok_backmargin_balance.expect_payment_amt_tax%TYPE  -- 支払予定額（税込）
   ,resv_flag                    xxcok_backmargin_balance.resv_flag%TYPE               -- 保留フラグ
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD START
   ,payment_amt_tax              xxcok_backmargin_balance.payment_amt_tax%TYPE         -- 支払額（税込）
   ,fb_interface_date            xxcok_backmargin_balance.fb_interface_date%TYPE       -- 連携日（本振用FB）
   ,proc_type                    xxcok_backmargin_balance.proc_type%TYPE               -- 処理区分
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD END
  );
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki ADD END
  -- ===============================
  -- テーブルタイプの宣言部
  -- ===============================
  TYPE rep_bm_balance_tbl IS TABLE OF rep_bm_balance_rec INDEX BY BINARY_INTEGER;
  g_bm_balance_ttype  rep_bm_balance_tbl;
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki UPD START
--  CURSOR g_target_cur(
--    iv_target_disp_flg          IN VARCHAR2  -- 表示フラグ
--  )
--  IS
--    SELECT bm_balance_id          -- 内部ID
--          ,base_code              -- 拠点コード
--          ,supplier_code          -- 仕入先コード
--          ,supplier_site_code     -- 仕入先サイトコード
--          ,cust_code              -- 顧客コード
--          ,closing_date           -- 締め日
--          ,backmargin             -- 販売手数料
--          ,backmargin_tax         -- 販売手数料（消費税額
--          ,electric_amt           -- 電気料
--          ,electric_amt_tax       -- 電気料（消費税額）
--          ,expect_payment_date    -- 支払予定日
--          ,expect_payment_amt_tax -- 支払予定額（税込）
--          ,resv_flag              -- 保留フラグ
--    FROM (SELECT  xbb.bm_balance_id                    AS  bm_balance_id         -- 内部ID
--                 ,xbb.base_code                        AS base_code              -- 拠点コード
--                 ,xbb.supplier_code                    AS supplier_code          -- 仕入先コード
--                 ,xbb.supplier_site_code               AS supplier_site_code     -- 仕入先サイトコード
--                 ,xbb.cust_code                        AS cust_code              -- 顧客コード
--                 ,xbb.closing_date                     AS closing_date           -- 締め日
--                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- 販売手数料
--                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- 販売手数料（消費税額）
--                 ,NVL( xbb.electric_amt ,0)            AS electric_amt           -- 電気料
--                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- 電気料（消費税額）
--                 ,xbb.expect_payment_date              AS expect_payment_date    -- 支払予定日
--                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- 支払予定額（税込）
--                 ,xbb.resv_flag                        AS resv_flag              -- 保留フラグ
--          FROM   xxcok_backmargin_balance  xbb    -- 販手残高テーブル
--                ,po_vendors                pv     -- 仕入先マスタ
--                ,po_vendor_sites_all       pvsa   -- 仕入先サイト
--          WHERE  xbb.base_code                                 = NVL( gv_selling_base_code ,xbb.base_code)
--          AND    TRUNC( xbb.expect_payment_date )             <= gd_payment_date
--          AND    pv.vendor_id                                  = pvsa.vendor_id
--          AND    pv.segment1                                   = xbb.supplier_code
--          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
--          AND    cv_target_disp1                               = iv_target_disp_flg
--          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
--          AND    pvsa.org_id                                   = gn_org_id
--          UNION
--          SELECT  xbb.bm_balance_id                    AS bm_balance_id          -- 内部ID
--                 ,xbb.base_code                        AS base_code              -- 拠点コード
--                 ,xbb.supplier_code                    AS supplier_code          -- 仕入先コード
--                 ,xbb.supplier_site_code               AS supplier_site_code     -- 仕入先サイトコード
--                 ,xbb.cust_code                        AS cust_code              -- 顧客コード
--                 ,xbb.closing_date                     AS closing_date           -- 締め日
--                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- 販売手数料
--                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- 販売手数料（消費税額）
--                 ,NVL( xbb.electric_amt ,0 )           AS electric_amt           -- 電気料
--                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- 電気料（消費税額）
--                 ,xbb.expect_payment_date              AS expect_payment_date    -- 支払予定日
--                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- 支払予定額（税込）
--                 ,xbb.resv_flag                        AS resv_flag              -- 保留フラグ
--          FROM   xxcok_backmargin_balance xbb     -- 販手残高テーブル
--                ,po_vendors                pv     -- 仕入先マスタ
--                ,po_vendor_sites_all       pvsa   -- 仕入先サイト
--          WHERE  xbb.supplier_code IN (SELECT supplier_code                 -- 仕入先コード
--                                       FROM   xxcok_backmargin_balance      -- 販手残高テーブル
--                                       WHERE  TRUNC( expect_payment_date ) <= gd_payment_date
--                                       AND    base_code = NVL( gv_selling_base_code ,base_code )
--                                  )
--          AND    TRUNC( xbb.expect_payment_date )             <= gd_payment_date
--          AND    pv.vendor_id                                  = pvsa.vendor_id
--          AND    pv.segment1                                   = xbb.supplier_code
--          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
--          AND    cv_target_disp2                               = iv_target_disp_flg
--          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
--          AND    pvsa.org_id                                   = gn_org_id
--          )
--    ORDER BY  supplier_code       -- 仕入先コード
--             ,base_code           -- 拠点コード
--             ,cust_code           -- 顧客コード
---- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
--             ,expect_payment_date -- 支払予定日
---- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
---- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD START
--             ,closing_date        -- 締め日
---- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD END
--    ;
----
--  g_target_rec g_target_cur%ROWTYPE;
  --
  -- 入力パラメータの表示対象が「1:自拠点のみ」またはNULLの場合
  CURSOR g_target_cur1
  IS
    SELECT /*+
             leading(xbb2 xbb pv pvsa)
             use_nl (xbb2 xbb pv pvsa)
             index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
             index  (pv   PO_VENDORS_U3)
             index  (pvsa PO_VENDOR_SITES_U2)
           */
           bm_balance_id          -- 内部ID
          ,base_code              -- 拠点コード
          ,supplier_code          -- 仕入先コード
          ,supplier_site_code     -- 仕入先サイトコード
          ,cust_code              -- 顧客コード
          ,closing_date           -- 締め日
          ,backmargin             -- 販売手数料
          ,backmargin_tax         -- 販売手数料（消費税額
          ,electric_amt           -- 電気料
          ,electric_amt_tax       -- 電気料（消費税額）
          ,expect_payment_date    -- 支払予定日
          ,expect_payment_amt_tax -- 支払予定額（税込）
          ,resv_flag              -- 保留フラグ
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD START
          ,payment_amt_tax        -- 支払額（税込）
          ,fb_interface_date      -- 連携日（本振用FB）
          ,proc_type              -- 処理区分
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD END
    FROM (SELECT /*+
                   leading(xbb2 xbb pv pvsa)
                   use_nl (xbb2 xbb pv pvsa)
                   index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
                   index  (pv   PO_VENDORS_U3)
                   index  (pvsa PO_VENDOR_SITES_U2)
                 */
                  xbb.bm_balance_id                    AS  bm_balance_id         -- 内部ID
                 ,xbb.base_code                        AS base_code              -- 拠点コード
                 ,xbb.supplier_code                    AS supplier_code          -- 仕入先コード
                 ,xbb.supplier_site_code               AS supplier_site_code     -- 仕入先サイトコード
                 ,xbb.cust_code                        AS cust_code              -- 顧客コード
                 ,xbb.closing_date                     AS closing_date           -- 締め日
                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- 販売手数料
                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- 販売手数料（消費税額）
                 ,NVL( xbb.electric_amt ,0)            AS electric_amt           -- 電気料
                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- 電気料（消費税額）
                 ,xbb.expect_payment_date              AS expect_payment_date    -- 支払予定日
                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- 支払予定額（税込）
                 ,xbb.resv_flag                        AS resv_flag              -- 保留フラグ
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD START
                 ,NVL( xbb.payment_amt_tax ,0 )        AS payment_amt_tax        -- 支払額（税込）
                 ,xbb.fb_interface_date                AS fb_interface_date      -- 連携日（本振用FB）
                 ,xbb.proc_type                        AS proc_type              -- 処理区分
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD END
          FROM   xxcok_backmargin_balance  xbb    -- 販手残高テーブル
                ,po_vendors                pv     -- 仕入先マスタ
                ,po_vendor_sites_all       pvsa   -- 仕入先サイト
-- 2011/03/15 Ver.1.13 [障害E_本稼動_05408,05409] SCS S.Niki ADD START
                ,xxcmm_cust_accounts       xca    -- 顧客追加情報
-- 2011/03/15 Ver.1.13 [障害E_本稼動_05408,05409] SCS S.Niki ADD END
-- 2011/03/15 Ver.1.13 [障害E_本稼動_05408,05409] SCS S.Niki UPD START
--          WHERE  xbb.base_code                                 = NVL( gv_selling_base_code ,xbb.base_code)
          WHERE  xbb.cust_code                                 = xca.customer_code
          AND    xca.past_sale_base_code                       = NVL( gv_selling_base_code ,xca.past_sale_base_code)
-- 2011/03/15 Ver.1.13 [障害E_本稼動_05408,05409] SCS S.Niki UPD END
          AND    xbb.expect_payment_date                      <= gd_payment_date
          AND    xbb.supplier_code                             = pv.segment1
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
          AND    pv.segment1                                   = NVL( gt_payment_code ,pv.segment1 )
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
          AND    pv.vendor_id                                  = pvsa.vendor_id
          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
          AND    pvsa.org_id                                   = gn_org_id
          )
    ORDER BY  supplier_code       -- 仕入先コード
             ,base_code           -- 拠点コード
             ,cust_code           -- 顧客コード
             ,expect_payment_date -- 支払予定日
             ,closing_date        -- 締め日
    ;
  --
  -- 入力パラメータの表示対象が「2:他拠点を含む」の場合
  CURSOR g_target_cur2
  IS
    SELECT /*+
             leading(xbb2 xbb pv pvsa)
             use_nl (xbb2 xbb pv pvsa)
             index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
             index  (pv   PO_VENDORS_U3)
             index  (pvsa PO_VENDOR_SITES_U2)
           */
           bm_balance_id          -- 内部ID
          ,base_code              -- 拠点コード
          ,supplier_code          -- 仕入先コード
          ,supplier_site_code     -- 仕入先サイトコード
          ,cust_code              -- 顧客コード
          ,closing_date           -- 締め日
          ,backmargin             -- 販売手数料
          ,backmargin_tax         -- 販売手数料（消費税額
          ,electric_amt           -- 電気料
          ,electric_amt_tax       -- 電気料（消費税額）
          ,expect_payment_date    -- 支払予定日
          ,expect_payment_amt_tax -- 支払予定額（税込）
          ,resv_flag              -- 保留フラグ
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD START
          ,payment_amt_tax        -- 支払額（税込）
          ,fb_interface_date      -- 連携日（本振用FB）
          ,proc_type              -- 処理区分
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD END
    FROM (SELECT /*+
                   leading(xbb2 xbb pv pvsa)
                   use_nl (xbb2 xbb pv pvsa)
                   index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
                   index  (pv   PO_VENDORS_U3)
                   index  (pvsa PO_VENDOR_SITES_U2)
                 */
                  xbb.bm_balance_id                    AS bm_balance_id          -- 内部ID
                 ,xbb.base_code                        AS base_code              -- 拠点コード
                 ,xbb.supplier_code                    AS supplier_code          -- 仕入先コード
                 ,xbb.supplier_site_code               AS supplier_site_code     -- 仕入先サイトコード
                 ,xbb.cust_code                        AS cust_code              -- 顧客コード
                 ,xbb.closing_date                     AS closing_date           -- 締め日
                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- 販売手数料
                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- 販売手数料（消費税額）
                 ,NVL( xbb.electric_amt ,0 )           AS electric_amt           -- 電気料
                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- 電気料（消費税額）
                 ,xbb.expect_payment_date              AS expect_payment_date    -- 支払予定日
                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- 支払予定額（税込）
                 ,xbb.resv_flag                        AS resv_flag              -- 保留フラグ
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD START
                 ,NVL( xbb.payment_amt_tax ,0 )        AS payment_amt_tax        -- 支払額（税込）
                 ,xbb.fb_interface_date                AS fb_interface_date      -- 連携日（本振用FB）
                 ,xbb.proc_type                        AS proc_type              -- 処理区分
-- 2012/07/23 Ver.1.15 [障害E_本稼動_08365,08367] SCSK K.Onotsuka ADD END
          FROM   xxcok_backmargin_balance xbb     -- 販手残高テーブル
                ,po_vendors                pv     -- 仕入先マスタ
                ,po_vendor_sites_all       pvsa   -- 仕入先サイト
          WHERE  xbb.supplier_code IN (SELECT /*+
                                                index(xbb2 XXCOK_BACKMARGIN_BALANCE_N08)
                                              */
                                              xbb2.supplier_code            -- 仕入先コード
                                       FROM   xxcok_backmargin_balance xbb2 -- 販手残高テーブル
-- 2011/03/15 Ver.1.13 [障害E_本稼動_05408,05409] SCS S.Niki ADD START
                                             ,xxcmm_cust_accounts      xca  -- 顧客追加情報
-- 2011/03/15 Ver.1.13 [障害E_本稼動_05408,05409] SCS S.Niki ADD END
                                       WHERE  xbb2.expect_payment_date <= gd_payment_date
-- 2011/03/15 Ver.1.13 [障害E_本稼動_05408,05409] SCS S.Niki UPD START
--                                       AND    xbb2.base_code = NVL( gv_selling_base_code ,xbb2.base_code )
                                       AND    xbb2.cust_code     = xca.customer_code
                                       AND    xca.past_sale_base_code = NVL( gv_selling_base_code ,xca.past_sale_base_code)
-- 2011/03/15 Ver.1.13 [障害E_本稼動_05408,05409] SCS S.Niki UPD END
                                  )
          AND    xbb.expect_payment_date                      <= gd_payment_date
          AND    xbb.supplier_code                             = pv.segment1
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
          AND    pv.segment1                                   = NVL( gt_payment_code ,pv.segment1 )
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
          AND    pv.vendor_id                                  = pvsa.vendor_id
          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
          AND    pvsa.org_id                                   = gn_org_id
          )
    ORDER BY  supplier_code       -- 仕入先コード
             ,base_code           -- 拠点コード
             ,cust_code           -- 顧客コード
             ,expect_payment_date -- 支払予定日
             ,closing_date        -- 締め日
    ;
  --
  g_target_rec g_target_rtype;
  --
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki UPD END
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
   * Procedure Name   : del_worktable_data
   * Description      : ワークテーブルデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE del_worktable_data(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(18) := 'del_worktable_data';  -- プログラム名
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
    CURSOR bm_balance_cur
    IS
      SELECT 'X'
      FROM   xxcok_rep_bm_balance  xrbb
      WHERE  xrbb.request_id = cn_request_id
      FOR UPDATE OF xrbb.request_id NOWAIT;

  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高一覧帳票ワークテーブルロック取得
    -- ===============================================
    OPEN  bm_balance_cur;
    CLOSE bm_balance_cur;
    -- ===============================================
    -- 販手残高一覧帳票ワークテーブルデータ削除
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_rep_bm_balance
      WHERE  request_id = cn_request_id
      ;
      gn_normal_cnt := SQL%ROWCOUNT;
    EXCEPTION
      -- *** 削除処理エラー ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10393
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
--
  EXCEPTION
    --*** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10394
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
  END del_worktable_data;
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF起動(A-8)
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
    cv_prg_name      CONSTANT VARCHAR2(9) := 'start_svf'; -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg    VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode   BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    lv_file_name VARCHAR2(50)   DEFAULT NULL;              -- 出力ファイル名
    lv_date      VARCHAR2(8)    DEFAULT NULL;              -- 日付(YYYYMMDD)
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 出力ファイル名(帳票ID + YYYYMMDD + 要求ID)
    -- ===============================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    lv_file_name := cv_file_id || lv_date || TO_CHAR( cn_request_id ) || cv_pdf;
    -- ===============================================
    -- SVFコンカレント起動
    -- ===============================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                     -- エラーバッファ
      , ov_retcode       => lv_retcode                    -- リターンコード
      , ov_errmsg        => lv_errmsg                     -- エラーメッセージ
      , iv_conc_name     => cv_pkg_name                   -- コンカレント名
      , iv_file_name     => lv_file_name                  -- 出力ファイル名
      , iv_file_id       => cv_file_id                    -- 帳票ID
      , iv_output_mode   => cv_output_mode                -- 出力区分
      , iv_frm_file      => cv_frm_file                   -- フォーム様式ファイル名
      , iv_vrq_file      => cv_vrq_file                   -- クエリー様式ファイル名
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
--      , iv_org_id        => TO_CHAR( gn_organization_id ) -- ORG_ID
      , iv_org_id        => gn_org_id                     -- ORG_ID
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
      , iv_user_name     => fnd_global.user_name          -- ログイン・ユーザ名
      , iv_resp_name     => fnd_global.resp_name          -- ログイン・ユーザ職責名
      , iv_doc_name      => NULL                          -- 文書名
      , iv_printer_name  => NULL                          -- プリンタ名
      , iv_request_id    => TO_CHAR( cn_request_id )      -- 要求ID
      , iv_nodata_msg    => NULL                          -- データなしメッセージ
    );
    IF( lv_retcode <> cv_status_normal ) THEN
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
--
-- 2013/04/04 Ver.1.17 [障害E_本稼動_10595,10609] SCSK K.Nakamura ADD START
  /**********************************************************************************
   * Procedure Name   : upd_resv_payment_rec
   * Description      : 支払ステータス「消込済」更新処理(A-11)
   ***********************************************************************************/
  PROCEDURE upd_resv_payment_rec(
    ov_errbuf                OUT VARCHAR2           -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2           -- リターン・コード
  , ov_errmsg                OUT VARCHAR2           -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20) := 'upd_resv_payment_rec';    -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 支払ステータス「消込済」更新処理
    -- ===============================================
    -- 対象の支払ステータスを「消込済」に更新する
    UPDATE xxcok_rep_bm_balance xrbb              -- 販手残高一覧帳票ワークテーブル
    SET    xrbb.resv_payment    = gv_pay_rec_name -- 支払ステータス("消込済")
    WHERE  xrbb.request_id      = cn_request_id   -- 要求ID(今回実行分)
    AND    xrbb.resv_payment    IS NULL           -- 支払保留
-- Ver.1.18 [障害E_本稼動_10595再] SCSK S.Niki MOD START
--    AND    xrbb.unpaid_balance  = 0               -- 未払残高
    AND EXISTS ( SELECT 'X'
                 FROM   xxcok_backmargin_balance xbb  -- 販手残高テーブル
                 WHERE  xbb.supplier_code  = xrbb.payment_code  -- 支払先コード
                 AND    xbb.cust_code      = xrbb.cust_code     -- 顧客コード
                 AND    xbb.closing_date   = xrbb.closing_date  -- 締め日
                 AND    xbb.proc_type      = cv_proc_type1_upd  -- 処理区分("消込済")
               )
-- Ver.1.18 [障害E_本稼動_10595再] SCSK S.Niki MOD END
    ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_resv_payment_rec;
--
-- 2013/04/04 Ver.1.17 [障害E_本稼動_10595,10609] SCSK K.Nakamura ADD END
--
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD START
  /**********************************************************************************
   * Procedure Name   : upd_resv_payment
   * Description      : 支払ステータス「自動繰越」更新処理(A-10)
   ***********************************************************************************/
  PROCEDURE upd_resv_payment(
    ov_errbuf                OUT VARCHAR2           -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2           -- リターン・コード
  , ov_errmsg                OUT VARCHAR2           -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(18) := 'upd_resv_payment';    -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    ln_transfer_fee          NUMBER DEFAULT 0;                         -- 振込手数料
    ln_transfer_amount       NUMBER DEFAULT 0;                         -- 振込金額
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 支払先ごとの販手残高一覧データ
    -- (本振、未払分が対象)
    CURSOR l_payment_cur
    IS
      SELECT
            xrbb.payment_code                 AS  payment_code        -- 支払先コード
           ,xrbb.bm_payment_code              AS  bm_payment_code     -- BM支払区分
           ,xrbb.bank_trns_fee                AS  bank_trns_fee       -- 振込手数料負担者
           ,NVL(SUM(xrbb.unpaid_balance), 0)  AS  unpaid_balance      -- 未払残高
      FROM
            xxcok_rep_bm_balance    xrbb  -- 販手残高一覧帳票ワークテーブル
      WHERE
            xrbb.request_id           =  cn_request_id                              -- 要求ID(今回実行分)
      AND   xrbb.bm_payment_code     IN  (cv_bm_payment_type1, cv_bm_payment_type2) -- BM支払区分(本振)
      GROUP BY
            -- 支払先ごと
            xrbb.payment_code                       -- 支払先コード
           ,xrbb.bm_payment_code                    -- BM支払区分
           ,xrbb.bank_trns_fee                      -- 振込手数料(負担先)
      HAVING
            NVL(SUM(xrbb.unpaid_balance), 0)  >  0  -- 未払分が対象
      ORDER BY
            xrbb.payment_code                       -- 支払先コード
    ;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 支払ステータス「自動繰越」更新処理
    -- ===============================================
    -- 支払先ごとの販手残高一覧データをループ
    FOR l_payment_rec IN l_payment_cur LOOP
      --
      -- 振込手数料の算出
      ln_transfer_fee := CASE WHEN ( l_payment_rec.unpaid_balance >= gn_trans_fee )
                           -- 未払残高が基準額以上の場合
                           THEN gn_more_fee * ( 1 + gn_bm_tax / 100 ) -- 銀行手数料(基準以上)の税込額
                           -- 未払残高が基準額未満の場合
                           ELSE gn_less_fee * ( 1 + gn_bm_tax / 100 ) -- 銀行手数料(基準未満)の税込額
                         END;
      --
      -- 振込金額の算出
      ln_transfer_amount := CASE WHEN ( l_payment_rec.bank_trns_fee = gv_bk_trns_fee_we )
                              -- 振込手数料負担者＝当方の場合
                              THEN l_payment_rec.unpaid_balance                    -- 未払残高
                              -- 振込手数料負担者＝相手先の場合
                              ELSE l_payment_rec.unpaid_balance - ln_transfer_fee  -- 未払残高－振込手数料
                            END;
      --
      -- 振込金額が0円以下になる場合
      IF ( ln_transfer_amount <= 0 ) THEN
        --
        -- 対象の支払先の支払ステータスを「自動繰越」に更新する
        UPDATE  xxcok_rep_bm_balance                        -- 販手残高一覧帳票ワークテーブル
        SET     resv_payment  =  gv_pay_auto_res_name       -- 支払ステータス("自動繰越")
        WHERE   request_id    =  cn_request_id              -- 要求ID(今回実行分)
        AND     payment_code  =  l_payment_rec.payment_code -- 対象の支払先コード
        ;
      END IF;
      --
    END LOOP;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_resv_payment;
--
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD END
  /**********************************************************************************
   * Procedure Name   : ins_worktable_data
   * Description      : ワークテーブルデータ登録(A-7)
   ***********************************************************************************/
  PROCEDURE ins_worktable_data(
    ov_errbuf                OUT VARCHAR2           -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2           -- リターン・コード
  , ov_errmsg                OUT VARCHAR2           -- ユーザー・エラー・メッセージ
  , in_index                 IN  NUMBER  DEFAULT 1  -- インデックス
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(18) := 'ins_worktable_data';    -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- ワークテーブルデータ登録
    -- ===============================================
    INSERT INTO xxcok_rep_bm_balance(
      p_payment_date                  -- 支払日(入力パラメータ)
    , p_ref_base_code                 -- 問合せ担当拠点(入力パラメータ)
    , p_selling_base_code             -- 売上計上拠点(入力パラメータ)
    , p_target_disp                   -- 表示対象(入力パラメータ)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , p_payment_code                  -- 支払先コード(入力パラメータ)
    , p_resv_payment                  -- 支払ステータス(入力パラメータ)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    , h_warnning_mark                 -- 警告マーク(ヘッダ出力)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , h_unpaid_elec_mark              -- 変動電気代未払マーク(ヘッダ出力)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    , payment_code                    -- 支払先コード
    , payment_name                    -- 支払先名
    , bank_no                         -- 銀行番号
    , bank_name                       -- 銀行名
    , bank_branch_no                  -- 銀行支店番号
    , bank_branch_name                -- 銀行支店名
    , bank_acct_type                  -- 口座種別
    , bank_acct_type_name             -- 口座種別名
    , bank_acct_no                    -- 口座番号
    , bank_acct_name                  -- 銀行口座名
    , ref_base_code                   -- 問合せ担当拠点コード
    , ref_base_name                   -- 問合せ担当拠点名
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD START
    , bm_payment_code                 -- BM支払区分(コード値)
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD END
    , bm_payment_type                 -- BM支払区分
    , bank_trns_fee                   -- 振込手数料
    , payment_stop                    -- 支払停止
    , selling_base_code               -- 売上計上拠点コード
    , selling_base_name               -- 売上計上拠点名
    , warnning_mark                   -- 警告マーク
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , unpaid_elec_mark                -- 変動電気代未払マーク
    , err_flag                        -- エラーフラグ
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    , cust_code                       -- 顧客コード
    , cust_name                       -- 顧客名
    , bm_this_month                   -- 当月BM
    , electric_amt                    -- 電気料
    , unpaid_last_month               -- 前月までの未払
    , unpaid_balance                  -- 未払残高
    , resv_payment                    -- 支払保留
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , resv_payment_sort               -- 支払ステータス並び順
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    , payment_date                    -- 支払日
    , closing_date                    -- 締め日
    , selling_base_section_code       -- 地区コード（売上計上拠点）
    , no_data_message                 -- 0件メッセージ
    , created_by                      -- 作成者
    , creation_date                   -- 作成日
    , last_updated_by                 -- 最終更新者
    , last_update_date                -- 最終更新日
    , last_update_login               -- 最終更新ログイン
    , request_id                      -- 要求ID
    , program_application_id          -- コンカレント・プログラム・アプリケーションID
    , program_id                      -- コンカレント・プログラムID
    , program_update_date             -- プログラム更新日
    ) VALUES (
      TO_CHAR( gd_payment_date ,cv_format_yyyymmdd )         -- 支払日(入力パラメータ)
    , gv_ref_base_code                                       -- 問合せ担当拠点(入力パラメータ)
    , gv_selling_base_code                                   -- 売上計上拠点(入力パラメータ)
    , gv_target_disp_nm                                      -- 表示対象(入力パラメータ)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , gt_payment_code                                        -- 支払先コード(入力パラメータ)
    , gv_resv_payment_nm                                     -- 支払ステータス(入力パラメータ)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    , gv_error_mark                                          -- 警告マーク(ヘッダ出力)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , gv_unpaid_elec_mark                                    -- 変動電気代未払マーク(ヘッダ出力)
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    , g_bm_balance_ttype(in_index).PAYMENT_CODE              -- 支払先コード
    , g_bm_balance_ttype(in_index).PAYMENT_NAME              -- 支払先名
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD START
--    , g_bm_balance_ttype(in_index).BANK_NO                   -- 銀行番号
    , SUBSTRB( g_bm_balance_ttype(in_index).BANK_NO , 1 , 4 )-- 銀行番号
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD END
    , g_bm_balance_ttype(in_index).BANK_NAME                 -- 銀行名
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD START
--    , g_bm_balance_ttype(in_index).BANK_BRANCH_NO            -- 銀行支店番号
    , SUBSTRB( g_bm_balance_ttype(in_index).BANK_BRANCH_NO , 1 , 4 ) -- 銀行支店番号
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama UPD END
    , g_bm_balance_ttype(in_index).BANK_BRANCH_NAME          -- 銀行支店名
    , g_bm_balance_ttype(in_index).BANK_ACCT_TYPE            -- 口座種別
    , g_bm_balance_ttype(in_index).BANK_ACCT_TYPE_NAME       -- 口座種別名
    , g_bm_balance_ttype(in_index).BANK_ACCT_NO              -- 口座番号
    , g_bm_balance_ttype(in_index).BANK_ACCT_NAME            -- 銀行口座名
    , g_bm_balance_ttype(in_index).REF_BASE_CODE             -- 問合せ担当拠点コード
    , g_bm_balance_ttype(in_index).REF_BASE_NAME             -- 問合せ担当拠点名
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD START
    , g_bm_balance_ttype(in_index).BM_PAYMENT_CODE           -- BM支払区分(コード値)
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD END
    , g_bm_balance_ttype(in_index).BM_PAYMENT_TYPE           -- BM支払区分
    , g_bm_balance_ttype(in_index).BANK_TRNS_FEE             -- 振込手数料
    , g_bm_balance_ttype(in_index).PAYMENT_STOP              -- 支払停止
    , g_bm_balance_ttype(in_index).SELLING_BASE_CODE         -- 売上計上拠点コード
    , g_bm_balance_ttype(in_index).SELLING_BASE_NAME         -- 売上計上拠点名
    , g_bm_balance_ttype(in_index).WARNNING_MARK             -- 警告マーク
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , NULL                                                   -- 変動電気代未払マーク
    , NULL                                                   -- エラーフラグ
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    , g_bm_balance_ttype(in_index).CUST_CODE                 -- 顧客コード
    , g_bm_balance_ttype(in_index).CUST_NAME                 -- 顧客名
    , g_bm_balance_ttype(in_index).BM_THIS_MONTH             -- 当月BM
    , g_bm_balance_ttype(in_index).ELECTRIC_AMT              -- 電気料
    , g_bm_balance_ttype(in_index).UNPAID_LAST_MONTH         -- 前月までの未払
    , g_bm_balance_ttype(in_index).UNPAID_BALANCE            -- 未払残高
    , g_bm_balance_ttype(in_index).RESV_PAYMENT              -- 支払保留
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , NULL                                                   -- 支払ステータス並び順
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    , g_bm_balance_ttype(in_index).PAYMENT_DATE              -- 支払日
    , g_bm_balance_ttype(in_index).CLOSING_DATE              -- 締め日
    , g_bm_balance_ttype(in_index).SELLING_BASE_SECTION_CODE -- 地区コード（売上計上拠点）
    , gv_no_data_msg                                         -- 0件メッセージ
    , cn_created_by                                          -- created_by
    , SYSDATE                                                -- creation_date
    , cn_last_updated_by                                     -- last_updated_by
    , SYSDATE                                                -- last_update_date
    , cn_last_update_login                                   -- last_update_login
    , cn_request_id                                          -- request_id
    , cn_program_application_id                              -- program_application_id
    , cn_program_id                                          -- program_id
    , SYSDATE                                                -- program_update_date
    );
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_worktable_data;
--
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
--
  /**********************************************************************************
   * Procedure Name   : upd_worktable_data
   * Description      : ワークテーブルデータ更新処理(A-12)
   ***********************************************************************************/
  PROCEDURE upd_worktable_data(
    ov_errbuf                OUT VARCHAR2           -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2           -- リターン・コード
  , ov_errmsg                OUT VARCHAR2           -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(18) := 'upd_worktable_data';    -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lb_retcode               BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    lv_electricity_type      VARCHAR2(1)    DEFAULT NULL;              -- 電気代区分
    lv_err_flag              VARCHAR2(1)    DEFAULT NULL;              -- エラーフラグ
    ln_worktable_cnt         NUMBER         DEFAULT 0;                 -- ワークテーブル件数
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 販手残高一覧データ
    CURSOR l_worktable_cur
    IS
      SELECT  xrbb.payment_code            AS  payment_code       -- 支払先コード
            , xrbb.cust_code               AS  cust_code          -- 顧客コード
            , xrbb.warnning_mark           AS  warnning_mark      -- 警告マーク
            , xrbb.electric_amt            AS  electric_amt       -- 電気料
            , xrbb.resv_payment            AS  resv_payment       -- 支払ステータス
      FROM    xxcok_rep_bm_balance  xrbb
      WHERE   xrbb.request_id  = cn_request_id
      ;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 1. 変動電気代未払フラグ更新
    -- ===============================================
    -- 販手残高一覧データをループ
    FOR l_worktable_rec IN l_worktable_cur LOOP
      --
      ----------------------------
      -- 電気代区分取得
      ----------------------------
      -- 最新の確定済み契約に紐付くSP専決書を取得
      BEGIN
        SELECT xsdh.electricity_type   AS electricity_type   -- 電気代区分
        INTO   lv_electricity_type
        FROM   xxcso_sp_decision_headers   xsdh       -- SP専決ヘッダ
             , xxcso_contract_managements  xcm1       -- 契約管理テーブル
        WHERE  xsdh.sp_decision_header_id  = xcm1.sp_decision_header_id
        AND    xcm1.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                               FROM   xxcso_contract_managements xcm2   -- 契約管理テーブル
                                               WHERE  xcm2.install_account_id = xcm1.install_account_id
                                               AND    xcm2.status             = ct_status_comp     -- 確定済
                                               AND    xcm2.cooperate_flag     = ct_cooperate_comp  -- マスタ連携済
                                             )
        AND    xcm1.install_account_number = l_worktable_rec.cust_code    -- 対象の顧客コード
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 契約情報が取得できない場合、「0：電気代なし」を返却
          lv_electricity_type := ct_electricity_type0;
      END;
      --
      ----------------------------
      -- 変動電気代未払マーク更新
      ----------------------------
      -- 変動電気代対象顧客かつ、BM1支払先コードかつ、電気代が0円の場合
      IF ( lv_electricity_type = ct_electricity_type2 )
        AND ( l_worktable_rec.electric_amt = 0 ) THEN
        --
        BEGIN
          -- 変動電気代未払マークを更新する
          UPDATE  xxcok_rep_bm_balance  xrbb
          SET     xrbb.unpaid_elec_mark = gv_unpaid_elec_mark          -- 変動電気代未払マーク
          WHERE   xrbb.request_id       = cn_request_id
          AND     xrbb.payment_code     = l_worktable_rec.payment_code -- 対象の支払先コード
          AND     xrbb.cust_code        = l_worktable_rec.cust_code    -- 対象の顧客コード
          AND     EXISTS  ( SELECT 'X'
                            FROM   xxcmm_cust_accounts xca
                            WHERE  xca.contractor_supplier_code = xrbb.payment_code
                            AND    xca.customer_code            = xrbb.cust_code
                          )
          ;
        --
        EXCEPTION
          WHEN OTHERS THEN
            -- 帳票ワークテーブル更新エラー
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_xxcok_appl_short_name
                          , iv_name         => cv_msg_code_10535
                          , iv_token_name1  => cv_token_errmsg
                          , iv_token_value1 => SQLERRM
                          );
            RAISE global_process_expt;
        END;
      END IF;
      --
    END LOOP;
    --
    -- ===============================================
    -- 2. エラーフラグ更新(支払先単位)
    -- ===============================================
    -- 販手条件エラーまたは変動電気代未払の場合、支払先単位にエラーフラグ更新
    BEGIN
      UPDATE  xxcok_rep_bm_balance  xrbb1
      SET     xrbb1.err_flag    = cv_flag_y
      WHERE   xrbb1.request_id  = cn_request_id
      AND     EXISTS ( SELECT 'X'
                       FROM   xxcok_rep_bm_balance  xrbb2
                       WHERE  xrbb1.payment_code = xrbb2.payment_code
                       AND  ( ( xrbb2.warnning_mark    IS NOT NULL )   -- 警告マーク
                         OR   ( xrbb2.unpaid_elec_mark IS NOT NULL ) ) -- 変動電気代未払マーク
                     )
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- 帳票ワークテーブル更新エラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10535
                      , iv_token_name1  => cv_token_errmsg
                      , iv_token_value1 => SQLERRM
                      );
        RAISE global_process_expt;
    END;
    --
    -- ===============================================
    -- 3. 支払ステータス並び順更新
    -- ===============================================
    -- 支払ステータス名称から、値セットDFF1の「支払ステータス並び順」を設定
    BEGIN
      UPDATE  xxcok_rep_bm_balance   xrbb
      SET     xrbb.resv_payment_sort = ( SELECT TO_NUMBER( ffv.attribute1 )  -- 支払ステータス並び順
                                         FROM   fnd_flex_values       ffv
                                              , fnd_flex_values_tl    ffvt
                                              , fnd_flex_value_sets   ffvs
                                         WHERE  xrbb.resv_payment        = ffvt.description
                                         AND    ffv.flex_value_id        = ffvt.flex_value_id
                                         AND    ffvt.language            = cv_ja
                                         AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
                                         AND    ffvs.flex_value_set_name = cv_set_name_rp         -- 支払ステータス
                                       )
      WHERE   xrbb.request_id        = cn_request_id
      AND     xrbb.err_flag         IS NULL
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- 帳票ワークテーブル更新エラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10535
                      , iv_token_name1  => cv_token_errmsg
                      , iv_token_value1 => SQLERRM
                      );
        RAISE global_process_expt;
    END;
    --
    -- ===============================================
    -- 4. 不要データ削除
    -- ===============================================
    IF ( gv_resv_payment_nm IS NOT NULL ) THEN
      BEGIN
        -- パラメータ：支払ステータスに合致しないレコードを削除
        DELETE
        FROM   xxcok_rep_bm_balance  xrbb
        WHERE  NVL( xrbb.resv_payment ,'X' ) <> gv_resv_payment_nm  -- パラメータ：支払ステータス
        AND    xrbb.request_id                = cn_request_id
        ;
      --
      EXCEPTION
        WHEN OTHERS THEN
          -- 帳票ワークテーブル削除エラー
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10536
                        , iv_token_name1  => cv_token_errmsg
                        , iv_token_value1 => SQLERRM
                        );
          RAISE global_process_expt;
      END;
    END IF;
    --
    -- ===============================================
    -- 5. 0件データ登録
    -- ===============================================
    -- 帳票ワークの件数をカウント
    SELECT COUNT(*)
    INTO   ln_worktable_cnt
    FROM   xxcok_rep_bm_balance   xrbb
    WHERE  xrbb.request_id      = cn_request_id
    ;
    -- 帳票ワーク件数が0件の場合、0件データを登録
    IF ln_worktable_cnt = 0 THEN
      -- 対象データなし
      gn_target_cnt     := 0;
      gn_index          := 1;
      -- 項目のクリア
      g_bm_balance_ttype( gn_index ).PAYMENT_CODE                := NULL;  -- 支払先コード
      g_bm_balance_ttype( gn_index ).PAYMENT_NAME                := NULL;  -- 支払先名
      g_bm_balance_ttype( gn_index ).BANK_NO                     := NULL;  -- 銀行番号
      g_bm_balance_ttype( gn_index ).BANK_NAME                   := NULL;  -- 銀行名
      g_bm_balance_ttype( gn_index ).BANK_BRANCH_NO              := NULL;  -- 銀行支店番号
      g_bm_balance_ttype( gn_index ).BANK_BRANCH_NAME            := NULL;  -- 銀行支店名
      g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE              := NULL;  -- 口座種別
      g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE_NAME         := NULL;  -- 口座種別名
      g_bm_balance_ttype( gn_index ).BANK_ACCT_NO                := NULL;  -- 口座番号
      g_bm_balance_ttype( gn_index ).BANK_ACCT_NAME              := NULL;  -- 銀行口座名
      g_bm_balance_ttype( gn_index ).REF_BASE_CODE               := NULL;  -- 問合せ担当拠点コード
      g_bm_balance_ttype( gn_index ).REF_BASE_NAME               := NULL;  -- 問合せ担当拠点名
      g_bm_balance_ttype( gn_index ).BM_PAYMENT_CODE             := NULL;  -- BM支払区分(コード値)
      g_bm_balance_ttype( gn_index ).BM_PAYMENT_TYPE             := NULL;  -- BM支払区分
      g_bm_balance_ttype( gn_index ).BANK_TRNS_FEE               := NULL;  -- 振込手数料
      g_bm_balance_ttype( gn_index ).PAYMENT_STOP                := NULL;  -- 支払停止
      g_bm_balance_ttype( gn_index ).SELLING_BASE_CODE           := NULL;  -- 売上計上拠点コード
      g_bm_balance_ttype( gn_index ).SELLING_BASE_NAME           := NULL;  -- 売上計上拠点名
      g_bm_balance_ttype( gn_index ).WARNNING_MARK               := NULL;  -- 警告マーク
      g_bm_balance_ttype( gn_index ).CUST_CODE                   := NULL;  -- 顧客コード
      g_bm_balance_ttype( gn_index ).CUST_NAME                   := NULL;  -- 顧客名
      g_bm_balance_ttype( gn_index ).BM_THIS_MONTH               := NULL;  -- 当月BM
      g_bm_balance_ttype( gn_index ).ELECTRIC_AMT                := NULL;  -- 電気料
      g_bm_balance_ttype( gn_index ).UNPAID_LAST_MONTH           := NULL;  -- 前月までの未払
      g_bm_balance_ttype( gn_index ).UNPAID_BALANCE              := NULL;  -- 未払残高
      g_bm_balance_ttype( gn_index ).RESV_PAYMENT                := NULL;  -- 支払保留
      g_bm_balance_ttype( gn_index ).PAYMENT_DATE                := NULL;  -- 支払日
      g_bm_balance_ttype( gn_index ).CLOSING_DATE                := NULL;  -- 締め日
      g_bm_balance_ttype( gn_index ).SELLING_BASE_SECTION_CODE   := NULL;  -- 地区コード
--
      -- ===============================================
      -- 対象データなしメッセージ取得
      -- ===============================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ワークテーブルデータ登録(A-7)
      -- ===============================================
      ins_worktable_data(
          ov_errbuf                =>  lv_errbuf                -- エラーバッファ
        , ov_retcode               =>  lv_retcode               -- リターンコード
        , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        -- 帳票ワークテーブル登録エラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10537
                      , iv_token_name1  => cv_token_errmsg
                      , iv_token_value1 => lv_errbuf
                      );
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END upd_worktable_data;
--
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
--
  /**********************************************************************************
   * Procedure Name   : break_judge
   * Description      : ブレイク判定処理(A-6)
   ***********************************************************************************/
  PROCEDURE break_judge(
    ov_errbuf                  OUT VARCHAR2             -- エラー・メッセージ
  , ov_retcode                 OUT VARCHAR2             -- リターン・コード
  , ov_errmsg                  OUT VARCHAR2             -- ユーザー・エラー・メッセージ
  , iv_last_record_flg         IN  VARCHAR2                                          DEFAULT NULL -- 最終レコードフラグ
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki UPD START
--  , i_target_rec               IN  g_target_cur%ROWTYPE                              DEFAULT NULL -- カーソルレコード
  , i_target_rec               IN  g_target_rtype                                    DEFAULT NULL -- カーソルレコード
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki UPD END
  , it_bank_charge_bearer      IN  po_vendors.bank_charge_bearer%TYPE                DEFAULT NULL -- 銀行手数料負担者
  , it_hold_all_payments_flag  IN  po_vendors.hold_all_payments_flag%TYPE            DEFAULT NULL -- 全支払の保留フラグ
  , it_vendor_name             IN  po_vendors.vendor_name%TYPE                       DEFAULT NULL -- 仕入先名
  , it_bank_number             IN  ap_bank_branches.bank_number%TYPE                 DEFAULT NULL -- 銀行番号
  , it_bank_name               IN  ap_bank_branches.bank_name%TYPE                   DEFAULT NULL -- 銀行口座名
  , it_bank_num                IN  ap_bank_branches.bank_num%TYPE                    DEFAULT NULL -- 銀行支店番号
  , it_bank_branch_name        IN  ap_bank_branches.bank_branch_name%TYPE            DEFAULT NULL -- 銀行支店名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--  , it_bank_account_type       IN  ap_bank_accounts_all.bank_account_type%TYPE       DEFAULT NULL -- 口座種別
  , iv_bank_account_type       IN  VARCHAR2                                          DEFAULT NULL -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
  , iv_bk_account_type_nm      IN  VARCHAR2                                          DEFAULT NULL -- 口座種別名
  , it_bank_account_num        IN  ap_bank_accounts_all.bank_account_num%TYPE        DEFAULT NULL -- 銀行口座番号
  , it_account_holder_name_alt IN  ap_bank_accounts_all.account_holder_name_alt%TYPE DEFAULT NULL -- 口座名義人カナ
  , iv_ref_base_code           IN  VARCHAR2                                          DEFAULT NULL -- 問合せ担当拠点ｺｰﾄﾞ
  , it_selling_base_name       IN  hz_cust_accounts.account_name%TYPE                DEFAULT NULL -- 売上計上拠点名
  , iv_bm_kbn                  IN  VARCHAR2                                          DEFAULT NULL -- BM支払区分
  , iv_bm_kbn_nm               IN  VARCHAR2                                          DEFAULT NULL -- BM支払区分名
  , it_selling_base_code       IN  hz_cust_accounts.account_number%TYPE              DEFAULT NULL -- 売上計上拠点コード
  , it_ref_base_name           IN  hz_cust_accounts.account_name%TYPE                DEFAULT NULL -- 問合せ担当拠点名
  , it_account_number          IN  hz_cust_accounts.account_number%TYPE              DEFAULT NULL -- 顧客コード
  , it_party_name              IN  hz_parties.party_name%TYPE                        DEFAULT NULL -- 顧客名
  , it_address3                IN  hz_locations.address3%TYPE                        DEFAULT NULL -- 地区コード
  , in_error_count             IN  NUMBER                                            DEFAULT 0    -- 販手エラー件数
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(11) := 'break_judge';     -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    cv_bm_payment_type3      CONSTANT VARCHAR2(1)  := '3'; -- BM支払区分(3：AP支払)
    cv_bm_payment_type4      CONSTANT VARCHAR2(1)  := '4'; -- BM支払区分(4：現金支払)
    cv_bk_trns_fee_cd        CONSTANT VARCHAR2(1)  := 'I'; -- 銀行手数料負担者(当方)
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- ブレイク判定処理(A-6)
    -- ===============================================
--
    IF ( gt_payment_code_bk      <> i_target_rec.supplier_code )
      OR ( gt_selling_base_code_bk <> i_target_rec.base_code )
      OR ( gt_cust_code_bk         <> i_target_rec.cust_code )
      OR ( iv_last_record_flg = cv_flag_y ) THEN
      -- 集計した前月までの未払、および当月BM、電気料が0円以下の場合は作成しない
-- 2009/05/20 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
--      IF ( gt_unpaid_last_month_sum <= 0 )
--        AND ( gt_bm_this_month_sum  <= 0 )
--        AND ( gt_electric_amt_sum   <= 0 )
      IF ( gt_unpaid_last_month_sum = 0 )
        AND ( gt_bm_this_month_sum  = 0 )
        AND ( gt_electric_amt_sum   = 0 )
-- 2009/05/20 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
        AND ( gn_index > 0 ) THEN
        -------------------------
        -- 退避・集計項目の初期化
        -------------------------
        gt_payment_code_bk        := NULL;
        gt_payment_name_bk        := NULL;
        gt_bank_no_bk             := NULL;
        gt_bank_name_bk           := NULL;
        gt_bank_branch_no_bk      := NULL;
        gt_bank_branch_name_bk    := NULL;
        gt_bank_acct_type_bk      := NULL;
        gt_bank_acct_type_name_bk := NULL;
        gt_bank_acct_no_bk        := NULL;
        gt_bank_acct_name_bk      := NULL;
        gt_bm_type_bk             := NULL;
        gt_bm_payment_type_bk     := NULL;
        gt_bank_trns_fee_bk       := NULL;
        gt_payment_stop_bk        := NULL;
        gt_selling_base_code_bk   := NULL;
        gt_selling_base_name_bk   := NULL;
        gt_warnning_mark_bk       := NULL;
        gt_cust_code_bk           := NULL;
        gt_cust_name_bk           := NULL;
        gt_unpaid_last_month_sum  := 0;
        gt_bm_this_month_sum      := 0;
        gt_electric_amt_sum       := 0;
        gt_unpaid_balance_sum     := 0;
        gt_resv_payment_bk        := NULL;
        gt_payment_date_bk        := NULL;
        gt_closing_date_bk        := NULL;
        gt_section_code_bk        := NULL;
      ELSE
-- 2009/05/20 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
        IF ( gt_unpaid_last_month_sum <> 0 )
          OR ( gt_bm_this_month_sum  <> 0 )
          OR ( gt_electric_amt_sum   <> 0 ) THEN
-- 2009/05/20 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
          -- インデックスの発番
          gn_index := gn_index + 1;
          ----------------
          -- PL/SQL表格納
          ----------------
-- 2009/04/23 Ver.1.5 [障害T1_0684] SCS T.Taniguchi START
        -- BM支払区分より、問合せ担当拠点に設定する値を判定する
--        IF ( gt_bm_type_bk IN ( cv_bm_payment_type3 ,cv_bm_payment_type4 ) ) THEN
--          g_bm_balance_ttype( gn_index ).REF_BASE_CODE := gt_selling_base_code_bk; -- 問合せ担当拠点コード
--          g_bm_balance_ttype( gn_index ).REF_BASE_NAME := gt_selling_base_name_bk; -- 問合せ担当拠点名
--        ELSE
          g_bm_balance_ttype( gn_index ).REF_BASE_CODE             := gt_ref_base_code_bk;       -- 問合せ担当拠点コード
          g_bm_balance_ttype( gn_index ).REF_BASE_NAME             := gt_ref_base_name_bk;       -- 問合せ担当拠点名
--        END IF;
-- 2009/04/23 Ver.1.5 [障害T1_0684] SCS T.Taniguchi END
--
          g_bm_balance_ttype( gn_index ).PAYMENT_CODE              := gt_payment_code_bk;        -- 支払先コード
          g_bm_balance_ttype( gn_index ).PAYMENT_NAME              := gt_payment_name_bk;        -- 支払先名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki ADD START
        IF ( gt_bm_type_bk = cv_bm_payment_type4 ) THEN
          -- BM支払区分「4：現金支払」の場合、固定文字を設定する
          g_bm_balance_ttype( gn_index ).BANK_NO                   := cv_em_dash;                -- 銀行番号
          g_bm_balance_ttype( gn_index ).BANK_BRANCH_NO            := cv_em_dash;                -- 銀行支店番号
          g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE            := cv_em_dash;                -- 口座種別
          g_bm_balance_ttype( gn_index ).BANK_ACCT_NAME            := cv_em_dash;                -- 銀行口座名
        ELSE
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki ADD END
          g_bm_balance_ttype( gn_index ).BANK_NO                   := gt_bank_no_bk;             -- 銀行番号
          g_bm_balance_ttype( gn_index ).BANK_NAME                 := gt_bank_name_bk;           -- 銀行名
          g_bm_balance_ttype( gn_index ).BANK_BRANCH_NO            := gt_bank_branch_no_bk;      -- 銀行支店番号
          g_bm_balance_ttype( gn_index ).BANK_BRANCH_NAME          := gt_bank_branch_name_bk;    -- 銀行支店名
          g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE            := gt_bank_acct_type_bk;      -- 口座種別
          g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE_NAME       := gt_bank_acct_type_name_bk; -- 口座種別名
          g_bm_balance_ttype( gn_index ).BANK_ACCT_NO              := gt_bank_acct_no_bk;        -- 口座番号
          g_bm_balance_ttype( gn_index ).BANK_ACCT_NAME            := gt_bank_acct_name_bk;      -- 銀行口座名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki ADD START
        END IF;
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki ADD END
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD START
          g_bm_balance_ttype( gn_index ).BM_PAYMENT_CODE           := gt_bm_type_bk;             -- BM支払区分(コード値)
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD END
          g_bm_balance_ttype( gn_index ).BM_PAYMENT_TYPE           := gt_bm_payment_type_bk;     -- BM支払区分
          g_bm_balance_ttype( gn_index ).BANK_TRNS_FEE             := gt_bank_trns_fee_bk;       -- 振込手数料
          g_bm_balance_ttype( gn_index ).PAYMENT_STOP              := gt_payment_stop_bk;        -- 支払停止
          g_bm_balance_ttype( gn_index ).SELLING_BASE_CODE         := gt_selling_base_code_bk;   -- 売上計上拠点ｺｰﾄﾞ
          g_bm_balance_ttype( gn_index ).SELLING_BASE_NAME         := gt_selling_base_name_bk;   -- 売上計上拠点名
          g_bm_balance_ttype( gn_index ).WARNNING_MARK             := gt_warnning_mark_bk;       -- 警告マーク
          g_bm_balance_ttype( gn_index ).CUST_CODE                 := gt_cust_code_bk;           -- 顧客コード
          g_bm_balance_ttype( gn_index ).CUST_NAME                 := gt_cust_name_bk;           -- 顧客名
          g_bm_balance_ttype( gn_index ).UNPAID_LAST_MONTH         := gt_unpaid_last_month_sum;  -- 前月までの未払
          g_bm_balance_ttype( gn_index ).BM_THIS_MONTH             := gt_bm_this_month_sum;      -- 当月BM
          g_bm_balance_ttype( gn_index ).ELECTRIC_AMT              := gt_electric_amt_sum;       -- 電気料
          g_bm_balance_ttype( gn_index ).UNPAID_BALANCE            := gt_unpaid_balance_sum;     -- 未払残高
          g_bm_balance_ttype( gn_index ).RESV_PAYMENT              := gt_resv_payment_bk;        -- 支払保留
          g_bm_balance_ttype( gn_index ).PAYMENT_DATE              := gt_payment_date_bk;        -- 支払日
          g_bm_balance_ttype( gn_index ).CLOSING_DATE              := gt_closing_date_bk;        -- 締め日
          g_bm_balance_ttype( gn_index ).SELLING_BASE_SECTION_CODE := gt_section_code_bk;        -- 地区コード
          -- 対象件数変数に件数を設定
          gn_target_cnt             := gn_index;
        END IF;
        -------------------------
        -- 退避・集計項目の初期化
        -------------------------
        gt_payment_code_bk        := NULL;
        gt_payment_name_bk        := NULL;
        gt_bank_no_bk             := NULL;
        gt_bank_name_bk           := NULL;
        gt_bank_branch_no_bk      := NULL;
        gt_bank_branch_name_bk    := NULL;
        gt_bank_acct_type_bk      := NULL;
        gt_bank_acct_type_name_bk := NULL;
        gt_bank_acct_no_bk        := NULL;
        gt_bank_acct_name_bk      := NULL;
        gt_bm_type_bk             := NULL;
        gt_bm_payment_type_bk     := NULL;
        gt_bank_trns_fee_bk       := NULL;
        gt_payment_stop_bk        := NULL;
        gt_selling_base_code_bk   := NULL;
        gt_selling_base_name_bk   := NULL;
        gt_warnning_mark_bk       := NULL;
        gt_cust_code_bk           := NULL;
        gt_cust_name_bk           := NULL;
        gt_unpaid_last_month_sum  := 0;
        gt_bm_this_month_sum      := 0;
        gt_electric_amt_sum       := 0;
        gt_unpaid_balance_sum     := 0;
        gt_resv_payment_bk        := NULL;
        gt_payment_date_bk        := NULL;
        gt_closing_date_bk        := NULL;
        gt_section_code_bk        := NULL;
      END IF;
    END IF;
    ----------------------------
    -- 「前月までの未払」の集計
    ----------------------------
-- 2012/07/10 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka UPD START
--    IF ( i_target_rec.expect_payment_date <= LAST_DAY( ADD_MONTHS( gd_payment_date ,-1 ) ) ) THEN
--      gt_unpaid_last_month_sum := gt_unpaid_last_month_sum + i_target_rec.expect_payment_amt_tax;
    IF i_target_rec.fb_interface_date IS NULL THEN
      IF ( i_target_rec.expect_payment_date <= LAST_DAY( ADD_MONTHS( gd_payment_date ,-1 ) ) ) THEN
        gt_unpaid_last_month_sum := gt_unpaid_last_month_sum
                                  + i_target_rec.expect_payment_amt_tax;
      END IF;
    ELSE
      IF ( i_target_rec.expect_payment_date <= LAST_DAY( ADD_MONTHS( gd_payment_date ,-1 ) ) )
        AND ( TRUNC(gd_payment_date ,cv_format_mm) <= TRUNC(i_target_rec.fb_interface_date ,cv_format_mm)) THEN
        gt_unpaid_last_month_sum := gt_unpaid_last_month_sum
                                  + i_target_rec.payment_amt_tax;
      END IF;
    END IF;
    --
-- 2012/07/10 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka UPD END
    ----------------------------
    -- 「未払残高」の集計
    ----------------------------
    IF ( i_target_rec.expect_payment_date <= gd_payment_date ) THEN
      gt_unpaid_balance_sum := gt_unpaid_balance_sum + i_target_rec.expect_payment_amt_tax;
    END IF;
    ----------------------------
    -- 「当月BM」、「電気料」の集計
    ----------------------------
    IF ( TRUNC( i_target_rec.expect_payment_date ) BETWEEN TRUNC( gd_payment_date , 'MM' ) AND gd_payment_date ) THEN
      gt_bm_this_month_sum := gt_bm_this_month_sum + i_target_rec.backmargin + i_target_rec.backmargin_tax;
      gt_electric_amt_sum  := gt_electric_amt_sum + i_target_rec.electric_amt + i_target_rec.electric_amt_tax;
    END IF;
    ----------------------------
    -- 支払保留の設定
    ----------------------------
-- 2012/07/20 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka UPD START
--    IF ( gt_resv_payment_bk IS NULL ) AND ( i_target_rec.resv_flag = cv_flag_y ) THEN
    IF ( i_target_rec.resv_flag = cv_flag_y ) THEN
-- 2013/04/04 Ver.1.17 [障害E_本稼動_10595,10609] SCSK K.Nakamura UPD START
---- 2012/07/20 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka UPD END
---- 2012/07/11 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka UPD START
----      gt_resv_payment_bk := gv_pay_res_name;
--      IF ( i_target_rec.proc_type = cv_proc_type0_upd ) THEN
---- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi UPD START
----      --保留フラグ='Y'且つ、処理区分が'0'の場合は「自動繰越」
----        gt_resv_payment_bk := gv_pay_auto_res_name; -- 自動繰越
--        -- [障害E_本稼動_10381] 自動繰越の条件変更（upd_resv_paymentで実施）
--        NULL;
---- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi UPD END
--      ELSIF ( i_target_rec.proc_type = cv_proc_type2_upd ) THEN
--      --保留フラグ='Y'且つ、処理区分が'2'の場合は「保留」
--        gt_resv_payment_bk := gv_pay_res_name; -- 保留
--      END IF;
      --保留フラグ='Y'の場合は「保留」
        gt_resv_payment_bk := gv_pay_res_name; -- 保留
--    ELSIF ( i_target_rec.resv_flag IS NULL )
--      AND ( i_target_rec.proc_type = cv_proc_type1_upd ) THEN
--        --保留フラグ=NULL且つ、処理区分が'1'の場合は「消込済」
--        gt_resv_payment_bk := gv_pay_rec_name; -- 消込済
      -- [障害E_本稼動_10609] 消込済の条件変更（upd_resv_payment_recで実施）
-- 2013/04/04 Ver.1.17 [障害E_本稼動_10595,10609] SCSK K.Nakamura UPD END
    ELSE
      -- 保留解除時の残高、残高アップロード機能以外での残高更新データの場合、何も出力しない
      gt_resv_payment_bk := NULL;
-- 2012/07/11 Ver.1.15 [障害E_本稼動_08367] SCSK K.Onotsuka UPD END
    END IF;
    ----------------------------
    -- 警告マークの設定
    ----------------------------
    IF ( gt_warnning_mark_bk IS NULL ) AND ( in_error_count > 0 ) THEN
      gt_warnning_mark_bk := gv_error_mark;
    END IF;
    ----------------------------
    -- 振込手数料の設定
    ----------------------------
    IF it_bank_charge_bearer IS NOT NULL THEN
      IF ( it_bank_charge_bearer = cv_bk_trns_fee_cd ) THEN
        gt_bank_trns_fee_bk := gv_bk_trns_fee_we;    -- 振込手数料_当方
      ELSE
        gt_bank_trns_fee_bk := gv_bk_trns_fee_ctpty; -- 振込手数料_相手方
      END IF;
    END IF;
    ----------------------------
    -- 支払停止の設定
    ----------------------------
    IF ( it_hold_all_payments_flag = cv_flag_y ) THEN
      gt_payment_stop_bk := gv_pay_stop_name;
    END IF;
    ----------------------------
    -- その他の退避項目設定
    ----------------------------
    gt_payment_code_bk              := i_target_rec.supplier_code;       -- 支払先コード
    gt_payment_name_bk              := it_vendor_name;                   -- 支払先名
    gt_bank_no_bk                   := it_bank_number;                   -- 銀行番号
    gt_bank_name_bk                 := it_bank_name;                     -- 銀行名
    gt_bank_branch_no_bk            := it_bank_num;                      -- 銀行支店番号
    gt_bank_branch_name_bk          := it_bank_branch_name;              -- 銀行支店名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--    gt_bank_acct_type_bk            := it_bank_account_type;             -- 口座種別
    gt_bank_acct_type_bk            := iv_bank_account_type;             -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
    gt_bank_acct_type_name_bk       := iv_bk_account_type_nm;            -- 口座種別名
    gt_bank_acct_no_bk              := it_bank_account_num;              -- 口座番号
    gt_bank_acct_name_bk            := it_account_holder_name_alt;       -- 銀行口座名
    gt_ref_base_code_bk             := iv_ref_base_code;                 -- 問合せ担当拠点コード
    gt_ref_base_name_bk             := it_ref_base_name;                 -- 問合せ担当拠点名
    gt_bm_type_bk                   := iv_bm_kbn;                        -- BM支払区分
    gt_bm_payment_type_bk           := iv_bm_kbn_nm;                     -- BM支払区分名
    gt_selling_base_code_bk         := it_selling_base_code;             -- 売上計上拠点コード
    gt_selling_base_name_bk         := it_selling_base_name;             -- 売上計上拠点名
    gt_cust_code_bk                 := it_account_number;                -- 顧客コード
    gt_cust_name_bk                 := it_party_name;                    -- 顧客名
    gt_payment_date_bk              := i_target_rec.expect_payment_date; -- 支払日
    gt_closing_date_bk              := i_target_rec.closing_date;        -- 締め日
    gt_section_code_bk              := it_address3;                      -- 地区コード（売上計上拠点）
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END break_judge;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_contract_err
   * Description      : 販手エラー情報抽出処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_bm_contract_err(
    ov_errbuf                  OUT VARCHAR2              -- エラー・メッセージ
  , ov_retcode                 OUT VARCHAR2              -- リターン・コード
  , ov_errmsg                  OUT VARCHAR2              -- ユーザー・エラー・メッセージ
  , iv_selling_base_code       IN  VARCHAR2 DEFAULT NULL -- 売上計上拠点コード
  , iv_cust_code               IN  VARCHAR2 DEFAULT NULL -- 顧客コード
  , on_error_count             OUT NUMBER                -- エラーカウント
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(19) := 'get_bm_contract_err';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    SELECT COUNT(*)
    INTO   on_error_count
    FROM   xxcok_bm_contract_err -- 販手条件エラーテーブル
    WHERE  base_code = iv_selling_base_code
    AND    cust_code = iv_cust_code
    ;
--
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
  END get_bm_contract_err;
--
  /**********************************************************************************
   * Procedure Name   : get_vendor_data
   * Description      : 仕入先・銀行情報抽出処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_vendor_data(
    ov_errbuf                  OUT VARCHAR2              -- エラー・メッセージ
  , ov_retcode                 OUT VARCHAR2              -- リターン・コード
  , ov_errmsg                  OUT VARCHAR2              -- ユーザー・エラー・メッセージ
  , iv_supplier_code           IN  VARCHAR2 DEFAULT NULL                              -- 仕入先コード
  , iv_supplier_site_code      IN  VARCHAR2 DEFAULT NULL                              -- 仕入先サイトコード
  , ov_vendor_name             OUT po_vendors.vendor_name%TYPE                        -- 仕入先名
  , ov_bank_charge_bearer      OUT po_vendors.bank_charge_bearer%TYPE                 -- 銀行手数料負担者
  , ov_hold_all_payments_flag  OUT po_vendors.hold_all_payments_flag%TYPE             -- 全支払の保留フラグ
  , ov_ref_base_code           OUT po_vendor_sites_all.attribute5%TYPE                -- DFF5(問合せ担当拠点コード)
  , ov_bm_kbn_dff4             OUT po_vendor_sites_all.attribute4%TYPE                -- DFF4(BM支払区分)
  , ov_bank_number             OUT ap_bank_branches.bank_number%TYPE                  -- 銀行番号
  , ov_bank_name               OUT ap_bank_branches.bank_name%TYPE                    -- 銀行口座名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--  , ov_bank_account_type       OUT ap_bank_accounts_all.bank_account_type%TYPE        -- 口座種別
  , ov_bank_account_type       OUT VARCHAR2                                           -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
  , ov_bank_account_num        OUT ap_bank_accounts_all.bank_account_num%TYPE         -- 銀行口座番号
  , ov_account_holder_name_alt OUT ap_bank_accounts_all.account_holder_name_alt%TYPE  -- 口座名義人カナ
  , ov_bank_num                OUT ap_bank_branches.bank_num%TYPE                     -- 銀行支店番号
  , ov_bank_branch_name        OUT ap_bank_branches.bank_branch_name%TYPE             -- 銀行支店名
  , ov_account_name            OUT hz_cust_accounts.account_name%TYPE                 -- 問合せ担当拠点名
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi START
--  , ov_bm_kbn                  OUT xxcmn_lookup_values_v.lookup_code%TYPE             -- BM支払区分
--  , ov_bm_kbn_nm               OUT xxcmn_lookup_values_v.meaning%TYPE                 -- BM支払区分名
--  , ov_bk_account_type         OUT xxcmn_lookup_values_v.lookup_code%TYPE             -- 口座種別
--  , ov_bk_account_type_nm      OUT xxcmn_lookup_values_v.meaning%TYPE                 -- 口座種別名
  , ov_bm_kbn                  OUT xxcok_lookups_v.lookup_code%TYPE                   -- BM支払区分
  , ov_bm_kbn_nm               OUT xxcok_lookups_v.meaning%TYPE                       -- BM支払区分名
  , ov_bk_account_type         OUT xxcok_lookups_v.lookup_code%TYPE                   -- 口座種別
  , ov_bk_account_type_nm      OUT xxcok_lookups_v.meaning%TYPE                       -- 口座種別名
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi END
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(15) := 'get_vendor_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    -- 例外ハンドラ
    no_data_expt            EXCEPTION; -- データ取得エラー
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 仕入先・銀行情報
    -- ===============================================
    BEGIN
      SELECT pv.vendor_name                    -- 仕入先名
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi START
--            ,pv.bank_charge_bearer             -- 銀行手数料負担者
--            ,pv.hold_all_payments_flag         -- 全支払の保留フラグ
            ,pvsa.bank_charge_bearer           -- 銀行手数料負担者
            ,pvsa.hold_all_payments_flag       -- 全支払の保留フラグ
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi END
            ,pvsa.attribute4                   -- DFF4(BM支払区分)
            ,pvsa.attribute5                   -- DFF5(問合せ担当拠点コード)
            ,bank_data.bank_number             -- 銀行番号
            ,bank_data.bank_name               -- 銀行口座名
            ,bank_data.bank_account_type       -- 口座種別
            ,bank_data.bank_account_num        -- 銀行口座番号
            ,bank_data.account_holder_name_alt -- 口座名義人カナ
            ,bank_data.bank_num                -- 銀行支店番号
            ,bank_data.bank_branch_name        -- 銀行支店名
            ,hca.account_name                  -- 略称（アカウント名）
      INTO   ov_vendor_name
            ,ov_bank_charge_bearer
            ,ov_hold_all_payments_flag
            ,ov_bm_kbn_dff4
            ,ov_ref_base_code
            ,ov_bank_number
            ,ov_bank_name
            ,ov_bank_account_type
            ,ov_bank_account_num
            ,ov_account_holder_name_alt
            ,ov_bank_num
            ,ov_bank_branch_name
            ,ov_account_name
      FROM   po_vendors          pv       -- 仕入先マスタ
            ,po_vendor_sites_all pvsa     -- 仕入先サイト
            ,hz_cust_accounts       hca   -- 顧客マスタ
            ,(SELECT abaua.vendor_id              AS vendor_id               -- 仕入先ID
                    ,abaua.vendor_site_id         AS vendor_site_id          -- 仕入先サイトID
                    ,abaa.bank_account_type       AS bank_account_type       -- 口座種別
                    ,abaa.bank_account_num        AS bank_account_num        -- 銀行口座番号
                    ,abaa.account_holder_name_alt AS account_holder_name_alt -- 口座名義人カナ
                    ,abb.bank_name                AS bank_name               -- 銀行名
                    ,abb.bank_num                 AS bank_num                -- 銀行支店番号
                    ,abb.bank_branch_name         AS bank_branch_name        -- 銀行支店名
                    ,abb.bank_number              AS bank_number             -- 銀行番号
              FROM   ap_bank_account_uses_all abaua -- 銀行口座使用情報
                    ,ap_bank_accounts_all     abaa  -- 銀行口座
                    ,ap_bank_branches         abb   -- 銀行支店
              WHERE abaa.bank_account_id                     = abaua.external_bank_account_id
              AND   abaa.bank_branch_id                      = abb.bank_branch_id
              AND   abaua.primary_flag                       = cv_flag_y
              AND   NVL( TRUNC( abaua.start_date ), TRUNC( gd_process_date ) ) <= TRUNC( gd_process_date )
              AND   NVL( TRUNC( abaua.end_date )  , TRUNC( gd_process_date ) ) >= TRUNC( gd_process_date )
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
              AND   abaua.org_id                             = gn_org_id
              AND   abaa.org_id                              = gn_org_id
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
              ) bank_data
      WHERE  pv.vendor_id             = pvsa.vendor_id
      AND    pvsa.vendor_id           = bank_data.vendor_id(+)
      AND    pvsa.vendor_site_id      = bank_data.vendor_site_id(+)
      AND    pv.segment1              = iv_supplier_code
      AND    hca.account_number       = pvsa.attribute5
      AND    pvsa.attribute5          = NVL( gv_ref_base_code ,pvsa.attribute5 )
      AND    hca.customer_class_code  = cv_cust_class_code1-- 拠点
      AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
      AND    pvsa.org_id                                   = gn_org_id
      ;
    EXCEPTION
      -- 仕入・銀行情報取得エラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10333
                      , iv_token_name1  => cv_token_vendor_code
                      , iv_token_value1 => iv_supplier_code
                      , iv_token_name2  => cv_token_vendor_site_code
                      , iv_token_value2 => iv_supplier_site_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE no_data_expt;
      -- 仕入・銀行情報複数件エラー
      WHEN TOO_MANY_ROWS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10334
                      , iv_token_name1  => cv_token_vendor_code
                      , iv_token_value1 => iv_supplier_code
                      , iv_token_name2  => cv_token_vendor_site_code
                      , iv_token_value2 => iv_supplier_site_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
      RAISE no_data_expt;
    END;
    -- ===============================================
    -- BM支払区分情報
    -- ===============================================
    BEGIN
      SELECt lookup_code  -- BM支払区分
            ,meaning      -- BM支払区分名
      INTO   ov_bm_kbn
            ,ov_bm_kbn_nm
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi START
--      FROM   xxcmn_lookup_values_v
      FROM   xxcok_lookups_v
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi END
      WHERE  lookup_type = cv_lookup_type_bm_kbn
      AND    lookup_code = ov_bm_kbn_dff4
      ;
    EXCEPTION
      -- BM支払区分情報取得エラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00015
                      , iv_token_name1  => cv_token_lookup_value_set
                      , iv_token_value1 => cv_lookup_type_bm_kbn
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE no_data_expt;
    END;
    -- ===============================================
    -- 口座種別情報
    -- ===============================================
    IF ov_bank_account_type IS NOT NULL THEN
      BEGIN
        SELECt lookup_code  -- 口座種別
              ,meaning      -- 口座種別名
        INTO   ov_bk_account_type
              ,ov_bk_account_type_nm
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi START
--        FROM   xxcmn_lookup_values_v
        FROM   xxcok_lookups_v
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi END
        WHERE  lookup_type = cv_lookup_type_bank
        AND    lookup_code = ov_bank_account_type
        ;
      EXCEPTION
        -- 口座種別情報取得エラー
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00015
                        , iv_token_name1  => cv_token_lookup_value_set
                        , iv_token_value1 => cv_lookup_type_bank
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
      END;
    ELSE
      ov_bk_account_type    := NULL;
      ov_bk_account_type_nm := NULL;
    END IF;
--
  EXCEPTION
    -- *** データ取得例外 ***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END get_vendor_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_data
   * Description      : 売上拠点・顧客情報抽出処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_data(
    ov_errbuf            OUT VARCHAR2              -- エラー・メッセージ
  , ov_retcode           OUT VARCHAR2              -- リターン・コード
  , ov_errmsg            OUT VARCHAR2              -- ユーザー・エラー・メッセージ
  , iv_process_flg       IN  VARCHAR2 DEFAULT NULL -- 処理フラグ(1：売上拠点情報、2：顧客情報)
  , iv_selling_base_code IN  VARCHAR2 DEFAULT NULL -- 売上拠点
  , iv_cust_code         IN  VARCHAR2 DEFAULT NULL -- 顧客コード
  , ov_selling_base_code OUT VARCHAR2              -- 売上計上拠点コード
  , ov_account_name      OUT VARCHAR2              -- 売上計上拠点名
  , ov_address3          OUT VARCHAR2              -- 地区コード
  , ov_account_number    OUT VARCHAR2              -- 顧客コード
  , ov_party_name        OUT VARCHAR2              -- 顧客名
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(13) := 'get_cust_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    -- 例外ハンドラ
    no_data_expt            EXCEPTION; -- データ取得エラー
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    IF iv_process_flg = '1' THEN
      -- ===============================================
      -- 売上拠点情報
      -- ===============================================
      BEGIN
        SELECT hca.account_number           -- 売上計上拠点コード
              ,hca.account_name             -- 売上計上拠点名
              ,hl.address3                  -- 地区コード
        INTO   ov_selling_base_code
              ,ov_account_name
              ,ov_address3
        FROM   hz_cust_accounts       hca   -- 顧客マスタ
              ,hz_cust_acct_sites_all hcasa -- 顧客所在地マスタ
              ,hz_parties             hp    -- パーティマスタ
              ,hz_party_sites         hps   -- パーティサイトマスタ
              ,hz_locations           hl    -- 顧客事業所マスタ
        WHERE  hca.party_id            = hp.party_id
        AND    hca.cust_account_id     = hcasa.cust_account_id
        AND    hp.party_id             = hps.party_id
        AND    hps.party_site_id       = hcasa.party_site_id
        AND    hps.location_id         = hl.location_id
        AND    hca.account_number      = iv_selling_base_code
        AND    hca.customer_class_code = cv_cust_class_code1-- 拠点
        AND    hcasa.org_id            = gn_org_id
        ;
      EXCEPTION
        -- 売上計上拠点情報取得エラー
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00048
                        , iv_token_name1  => cv_token_sales_loc
                        , iv_token_value1 => iv_selling_base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
        -- 売上計上拠点情報複数件エラー
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00047
                        , iv_token_name1  => cv_token_sales_loc
                        , iv_token_value1 => iv_selling_base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
      END;
    ELSE
      -- ===============================================
      -- 顧客情報
      -- ===============================================
      BEGIN
        SELECT hca.account_number           -- 顧客コード
               ,hp.party_name                -- 顧客名
        INTO   ov_account_number
              ,ov_party_name
        FROM   hz_cust_accounts       hca   -- 顧客マスタ
              ,hz_parties             hp    -- パーティマスタ
        WHERE  hca.party_id        = hp.party_id
        AND    hca.account_number  = iv_cust_code
        AND    hca.customer_class_code = cv_cust_class_code10-- 顧客
        ;
      EXCEPTION
        -- 顧客情報取得エラー
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00035
                        , iv_token_name1  => cv_token_cust_code
                        , iv_token_value1 => iv_cust_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
        -- 顧客情報複数件エラー
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00046
                        , iv_token_name1  => cv_token_cost_code
                        , iv_token_value1 => iv_cust_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** データ取得例外 ***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END get_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : 販手残高情報抽出処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf                OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name         CONSTANT VARCHAR2(15) := 'get_target_data';  -- プログラム名
    cv_process_flg1     CONSTANT VARCHAR2(1)  := '1'; -- 処理フラグ(1：売上拠点情報)
    cv_process_flg2     CONSTANT VARCHAR2(1)  := '2'; -- 処理フラグ(2：顧客情報)
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg   VARCHAR2(5000)  DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;              -- メッセージ出力関数戻り値
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki DEL START
--    lv_target_disp_flg          VARCHAR2(1)                                       DEFAULT NULL; -- 表示対象フラグ
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki DEL END
    lt_selling_base_code        hz_cust_accounts.account_number%TYPE              DEFAULT NULL; -- 売上計上拠点コード
    lt_selling_base_name        hz_cust_accounts.account_name%TYPE                DEFAULT NULL; -- 売上計上拠点名
    lt_address3                 hz_locations.address3%TYPE                        DEFAULT NULL; -- 地区コード
    lt_selling_base_code_dummy  hz_cust_accounts.account_number%TYPE              DEFAULT NULL; -- 売上計上拠点コード
    lt_selling_base_name_dummy  hz_cust_accounts.account_name%TYPE                DEFAULT NULL; -- 売上計上拠点名
    lt_address3_dummy           hz_locations.address3%TYPE                        DEFAULT NULL; -- 地区コード
    lt_account_number           hz_cust_accounts.account_number%TYPE              DEFAULT NULL; -- 顧客コード
    lt_party_name               hz_parties.party_name%TYPE                        DEFAULT NULL; -- 顧客名
    lt_account_number_dummy     hz_cust_accounts.account_number%TYPE              DEFAULT NULL; -- 顧客コード
    lt_party_name_dummy         hz_parties.party_name%TYPE                        DEFAULT NULL; -- 顧客名
    lt_vendor_name              po_vendors.vendor_name%TYPE                       DEFAULT NULL; -- 仕入先名
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi START
    lt_bank_charge_bearer       po_vendor_sites_all.bank_charge_bearer%TYPE       DEFAULT NULL; -- 銀行手数料負担者
    lt_hold_all_payments_flag   po_vendor_sites_all.hold_all_payments_flag%TYPE   DEFAULT NULL; -- 全支払の保留フラグ
-- 2009/07/15 Ver.1.7 [障害0000689] SCS T.Taniguchi END
    lv_ref_base_code            VARCHAR2(4)                                       DEFAULT NULL; -- 問合せ担当拠点ｺｰﾄﾞ
    lv_bm_kbn_dff4              VARCHAR2(2)                                       DEFAULT NULL; -- DFF4(BM支払区分)
    lt_bank_number              ap_bank_branches.bank_number%TYPE                 DEFAULT NULL; -- 銀行番号
    lt_bank_name                ap_bank_branches.bank_name%TYPE                   DEFAULT NULL; -- 銀行口座名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--    lt_bank_account_type        ap_bank_accounts_all.bank_account_type%TYPE       DEFAULT NULL; -- 口座種別
    lv_bank_account_type        VARCHAR2(2)                                       DEFAULT NULL; -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
    lt_bank_account_num         ap_bank_accounts_all.bank_account_num%TYPE        DEFAULT NULL; -- 銀行口座番号
    lt_account_holder_name_alt  ap_bank_accounts_all.account_holder_name_alt%TYPE DEFAULT NULL; -- 口座名義人カナ
    lt_bank_num                 ap_bank_branches.bank_num%TYPE                    DEFAULT NULL; -- 銀行支店番号
    lt_bank_branch_name         ap_bank_branches.bank_branch_name%TYPE            DEFAULT NULL; -- 銀行支店名
    lt_ref_base_name            hz_cust_accounts.account_name%TYPE                DEFAULT NULL; -- 略称（アカウント名）
    lv_bm_kbn                   VARCHAR2(2)                                       DEFAULT NULL; -- BM支払区分
    lv_bm_kbn_nm                VARCHAR2(30)                                      DEFAULT NULL; -- BM支払区分名
    lv_bk_account_type_nm       VARCHAR2(4)                                       DEFAULT NULL; -- 口座種別名
    lv_bk_account_type          VARCHAR2(1)                                       DEFAULT NULL; -- 口座種別
    ln_error_count              NUMBER                                            DEFAULT 0;    -- 販手エラー件数
    ln_loop_cnt                 NUMBER                                            DEFAULT 0;    -- ループカウント
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高情報抽出処理
    -- ===============================================
    -- 入力パラメータの表示対象が「自拠点のみ」またはNULLの場合
    IF ( gv_target_disp = cv_target_disp1_nm )
      OR ( gv_target_disp IS NULL ) THEN
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki UPD START
--      lv_target_disp_flg := cv_target_disp1;
      -- 販手残高情報取得カーソル
      <<main_loop>>
      FOR g_target_rec IN g_target_cur1 LOOP
        --
        ln_loop_cnt := ln_loop_cnt + 1;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.base_code <> gt_selling_base_code_bk ) THEN
          -- ===============================================
          -- 売上拠点情報抽出処理(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf               -- エラー・メッセージ
           ,ov_retcode            => lv_retcode              -- リターン・コード
           ,ov_errmsg             => lv_errmsg               -- ユーザー・エラー・メッセージ
           ,iv_process_flg        => cv_process_flg1         -- 処理フラグ(1：売上拠点情報)
           ,iv_selling_base_code  => g_target_rec.base_code  -- 売上拠点
           ,iv_cust_code          => g_target_rec.cust_code  -- 顧客コード
           ,ov_selling_base_code  => lt_selling_base_code    -- 売上計上拠点コード
           ,ov_account_name       => lt_selling_base_name    -- 売上計上拠点名
           ,ov_address3           => lt_address3             -- 地区コード
           ,ov_account_number     => lt_account_number_dummy -- 顧客コード
           ,ov_party_name         => lt_party_name_dummy     -- 顧客名
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- 顧客情報抽出処理(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf                  -- エラー・メッセージ
           ,ov_retcode            => lv_retcode                 -- リターン・コード
           ,ov_errmsg             => lv_errmsg                  -- ユーザー・エラー・メッセージ
           ,iv_process_flg        => cv_process_flg2            -- 処理フラグ(2：顧客情報)
           ,iv_selling_base_code  => g_target_rec.base_code     -- 売上拠点
           ,iv_cust_code          => g_target_rec.cust_code     -- 顧客コード
           ,ov_selling_base_code  => lt_selling_base_code_dummy -- 売上計上拠点コード
           ,ov_account_name       => lt_selling_base_name_dummy -- 売上計上拠点名
           ,ov_address3           => lt_address3_dummy          -- 地区コード
           ,ov_account_number     => lt_account_number          -- 顧客コード
           ,ov_party_name         => lt_party_name              -- 顧客名
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.supplier_code <> gt_payment_code_bk ) THEN
          -- ===============================================
          -- 仕入先・銀行情報抽出処理(A-4)
          -- ===============================================
          get_vendor_data(
              ov_errbuf                  => lv_errbuf                       -- エラー・メッセージ
            , ov_retcode                 => lv_retcode                      -- リターン・コード
            , ov_errmsg                  => lv_errmsg                       -- ユーザー・エラー・メッセージ
            , iv_supplier_code           => g_target_rec.supplier_code      -- 仕入先コード
            , iv_supplier_site_code      => g_target_rec.supplier_site_code -- 仕入先サイトコード
            , ov_vendor_name             => lt_vendor_name                  -- 仕入先名
            , ov_bank_charge_bearer      => lt_bank_charge_bearer           -- 銀行手数料負担者
            , ov_hold_all_payments_flag  => lt_hold_all_payments_flag       -- 全支払の保留フラグ
            , ov_ref_base_code           => lv_ref_base_code                -- DFF5(問合せ担当拠点コード)
            , ov_bm_kbn_dff4             => lv_bm_kbn_dff4                  -- DFF4(BM支払区分)
            , ov_bank_number             => lt_bank_number                  -- 銀行番号
            , ov_bank_name               => lt_bank_name                    -- 銀行口座名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--            , ov_bank_account_type       => lt_bank_account_type            -- 口座種別
            , ov_bank_account_type       => lv_bank_account_type            -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
            , ov_bank_account_num        => lt_bank_account_num             -- 銀行口座番号
            , ov_account_holder_name_alt => lt_account_holder_name_alt      -- 口座名義人カナ
            , ov_bank_num                => lt_bank_num                     -- 銀行支店番号
            , ov_bank_branch_name        => lt_bank_branch_name             -- 銀行支店名
            , ov_account_name            => lt_ref_base_name                -- 問合せ担当拠点名
            , ov_bm_kbn                  => lv_bm_kbn                       -- BM支払区分
            , ov_bm_kbn_nm               => lv_bm_kbn_nm                    -- BM支払区分名
            , ov_bk_account_type         => lv_bk_account_type              -- 口座種別
            , ov_bk_account_type_nm      => lv_bk_account_type_nm           -- 口座種別名
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 )
          OR ( g_target_rec.base_code <> gt_selling_base_code_bk )
          OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- 販手エラー情報抽出処理(A-5)
          -- ===============================================
          get_bm_contract_err(
              ov_errbuf            => lv_errbuf                       -- エラー・メッセージ
            , ov_retcode           => lv_retcode                      -- リターン・コード
            , ov_errmsg            => lv_errmsg                       -- ユーザー・エラー・メッセージ
            , iv_selling_base_code => g_target_rec.base_code          -- 売上計上拠点コード
            , iv_cust_code         => g_target_rec.cust_code          -- 顧客コード
            , on_error_count       => ln_error_count                  -- エラーカウント
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        -- ===============================================
        -- ブレイク判定処理(A-6)
        -- ===============================================
        break_judge(
            ov_errbuf                  => lv_errbuf                  -- エラー・メッセージ
          , ov_retcode                 => lv_retcode                 -- リターン・コード
          , ov_errmsg                  => lv_errmsg                  -- ユーザー・エラー・メッセージ
          , i_target_rec               => g_target_rec               -- カーソルレコード
          , it_bank_charge_bearer      => lt_bank_charge_bearer      -- 銀行手数料負担者
          , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- 全支払の保留フラグ
          , it_vendor_name             => lt_vendor_name             -- 仕入先名
          , it_bank_number             => lt_bank_number             -- 銀行番号
          , it_bank_name               => lt_bank_name               -- 銀行口座名
          , it_bank_num                => lt_bank_num                -- 銀行支店番号
          , it_bank_branch_name        => lt_bank_branch_name        -- 銀行支店名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--          , it_bank_account_type       => lt_bank_account_type       -- 口座種別
          , iv_bank_account_type       => lv_bank_account_type       -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
          , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- 口座種別名
          , it_bank_account_num        => lt_bank_account_num        -- 銀行口座番号
          , it_account_holder_name_alt => lt_account_holder_name_alt -- 口座名義人カナ
          , iv_ref_base_code           => lv_ref_base_code           -- DFF5(問合せ担当拠点コード)
          , it_selling_base_name       => lt_selling_base_name       -- 売上計上拠点名
          , iv_bm_kbn                  => lv_bm_kbn                  -- BM支払区分
          , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM支払区分名
          , it_selling_base_code       => lt_selling_base_code       -- 売上計上拠点コード
          , it_ref_base_name           => lt_ref_base_name           -- 問合せ担当s拠点名
          , it_account_number          => lt_account_number          -- 顧客コード
          , it_party_name              => lt_party_name              -- 顧客名
          , it_address3                => lt_address3                -- 地区コード
          , in_error_count             => ln_error_count             -- 販手エラー件数
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP main_loop;
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki UPD END
    -- 入力パラメータの表示対象が「他拠点を含む」場合
    ELSE
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki UPD START
--      lv_target_disp_flg := cv_target_disp2;
      -- 販手残高情報取得カーソル
      <<main_loop>>
      FOR g_target_rec IN g_target_cur2 LOOP
        --
        ln_loop_cnt := ln_loop_cnt + 1;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.base_code <> gt_selling_base_code_bk ) THEN
          -- ===============================================
          -- 売上拠点情報抽出処理(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf               -- エラー・メッセージ
           ,ov_retcode            => lv_retcode              -- リターン・コード
           ,ov_errmsg             => lv_errmsg               -- ユーザー・エラー・メッセージ
           ,iv_process_flg        => cv_process_flg1         -- 処理フラグ(1：売上拠点情報)
           ,iv_selling_base_code  => g_target_rec.base_code  -- 売上拠点
           ,iv_cust_code          => g_target_rec.cust_code  -- 顧客コード
           ,ov_selling_base_code  => lt_selling_base_code    -- 売上計上拠点コード
           ,ov_account_name       => lt_selling_base_name    -- 売上計上拠点名
           ,ov_address3           => lt_address3             -- 地区コード
           ,ov_account_number     => lt_account_number_dummy -- 顧客コード
           ,ov_party_name         => lt_party_name_dummy     -- 顧客名
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- 顧客情報抽出処理(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf                  -- エラー・メッセージ
           ,ov_retcode            => lv_retcode                 -- リターン・コード
           ,ov_errmsg             => lv_errmsg                  -- ユーザー・エラー・メッセージ
           ,iv_process_flg        => cv_process_flg2            -- 処理フラグ(2：顧客情報)
           ,iv_selling_base_code  => g_target_rec.base_code     -- 売上拠点
           ,iv_cust_code          => g_target_rec.cust_code     -- 顧客コード
           ,ov_selling_base_code  => lt_selling_base_code_dummy -- 売上計上拠点コード
           ,ov_account_name       => lt_selling_base_name_dummy -- 売上計上拠点名
           ,ov_address3           => lt_address3_dummy          -- 地区コード
           ,ov_account_number     => lt_account_number          -- 顧客コード
           ,ov_party_name         => lt_party_name              -- 顧客名
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.supplier_code <> gt_payment_code_bk ) THEN
          -- ===============================================
          -- 仕入先・銀行情報抽出処理(A-4)
          -- ===============================================
          get_vendor_data(
              ov_errbuf                  => lv_errbuf                       -- エラー・メッセージ
            , ov_retcode                 => lv_retcode                      -- リターン・コード
            , ov_errmsg                  => lv_errmsg                       -- ユーザー・エラー・メッセージ
            , iv_supplier_code           => g_target_rec.supplier_code      -- 仕入先コード
            , iv_supplier_site_code      => g_target_rec.supplier_site_code -- 仕入先サイトコード
            , ov_vendor_name             => lt_vendor_name                  -- 仕入先名
            , ov_bank_charge_bearer      => lt_bank_charge_bearer           -- 銀行手数料負担者
            , ov_hold_all_payments_flag  => lt_hold_all_payments_flag       -- 全支払の保留フラグ
            , ov_ref_base_code           => lv_ref_base_code                -- DFF5(問合せ担当拠点コード)
            , ov_bm_kbn_dff4             => lv_bm_kbn_dff4                  -- DFF4(BM支払区分)
            , ov_bank_number             => lt_bank_number                  -- 銀行番号
            , ov_bank_name               => lt_bank_name                    -- 銀行口座名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--            , ov_bank_account_type       => lt_bank_account_type            -- 口座種別
            , ov_bank_account_type       => lv_bank_account_type            -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
            , ov_bank_account_num        => lt_bank_account_num             -- 銀行口座番号
            , ov_account_holder_name_alt => lt_account_holder_name_alt      -- 口座名義人カナ
            , ov_bank_num                => lt_bank_num                     -- 銀行支店番号
            , ov_bank_branch_name        => lt_bank_branch_name             -- 銀行支店名
            , ov_account_name            => lt_ref_base_name                -- 問合せ担当拠点名
            , ov_bm_kbn                  => lv_bm_kbn                       -- BM支払区分
            , ov_bm_kbn_nm               => lv_bm_kbn_nm                    -- BM支払区分名
            , ov_bk_account_type         => lv_bk_account_type              -- 口座種別
            , ov_bk_account_type_nm      => lv_bk_account_type_nm           -- 口座種別名
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 )
          OR ( g_target_rec.base_code <> gt_selling_base_code_bk )
          OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- 販手エラー情報抽出処理(A-5)
          -- ===============================================
          get_bm_contract_err(
              ov_errbuf            => lv_errbuf                       -- エラー・メッセージ
            , ov_retcode           => lv_retcode                      -- リターン・コード
            , ov_errmsg            => lv_errmsg                       -- ユーザー・エラー・メッセージ
            , iv_selling_base_code => g_target_rec.base_code          -- 売上計上拠点コード
            , iv_cust_code         => g_target_rec.cust_code          -- 顧客コード
            , on_error_count       => ln_error_count                  -- エラーカウント
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        -- ===============================================
        -- ブレイク判定処理(A-6)
        -- ===============================================
        break_judge(
            ov_errbuf                  => lv_errbuf                  -- エラー・メッセージ
          , ov_retcode                 => lv_retcode                 -- リターン・コード
          , ov_errmsg                  => lv_errmsg                  -- ユーザー・エラー・メッセージ
          , i_target_rec               => g_target_rec               -- カーソルレコード
          , it_bank_charge_bearer      => lt_bank_charge_bearer      -- 銀行手数料負担者
          , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- 全支払の保留フラグ
          , it_vendor_name             => lt_vendor_name             -- 仕入先名
          , it_bank_number             => lt_bank_number             -- 銀行番号
          , it_bank_name               => lt_bank_name               -- 銀行口座名
          , it_bank_num                => lt_bank_num                -- 銀行支店番号
          , it_bank_branch_name        => lt_bank_branch_name        -- 銀行支店名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--          , it_bank_account_type       => lt_bank_account_type       -- 口座種別
          , iv_bank_account_type       => lv_bank_account_type       -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
          , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- 口座種別名
          , it_bank_account_num        => lt_bank_account_num        -- 銀行口座番号
          , it_account_holder_name_alt => lt_account_holder_name_alt -- 口座名義人カナ
          , iv_ref_base_code           => lv_ref_base_code           -- DFF5(問合せ担当拠点コード)
          , it_selling_base_name       => lt_selling_base_name       -- 売上計上拠点名
          , iv_bm_kbn                  => lv_bm_kbn                  -- BM支払区分
          , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM支払区分名
          , it_selling_base_code       => lt_selling_base_code       -- 売上計上拠点コード
          , it_ref_base_name           => lt_ref_base_name           -- 問合せ担当拠点名
          , it_account_number          => lt_account_number          -- 顧客コード
          , it_party_name              => lt_party_name              -- 顧客名
          , it_address3                => lt_address3                -- 地区コード
          , in_error_count             => ln_error_count             -- 販手エラー件数
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP main_loop;
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki UPD END
    END IF;
--
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki DEL START
--    -- 販手残高情報取得カーソル
--    <<main_loop>>
--    FOR g_target_rec IN g_target_cur( lv_target_disp_flg ) LOOP
----
--      ln_loop_cnt := ln_loop_cnt + 1;
----
--      IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.base_code <> gt_selling_base_code_bk ) THEN
--        -- ===============================================
--        -- 売上拠点情報抽出処理(A-3)
--        -- ===============================================
--        get_cust_data(
--          ov_errbuf             => lv_errbuf               -- エラー・メッセージ
--         ,ov_retcode            => lv_retcode              -- リターン・コード
--         ,ov_errmsg             => lv_errmsg               -- ユーザー・エラー・メッセージ
--         ,iv_process_flg        => cv_process_flg1         -- 処理フラグ(1：売上拠点情報)
--         ,iv_selling_base_code  => g_target_rec.base_code  -- 売上拠点
--         ,iv_cust_code          => g_target_rec.cust_code  -- 顧客コード
--         ,ov_selling_base_code  => lt_selling_base_code    -- 売上計上拠点コード
--         ,ov_account_name       => lt_selling_base_name    -- 売上計上拠点名
--         ,ov_address3           => lt_address3             -- 地区コード
--         ,ov_account_number     => lt_account_number_dummy -- 顧客コード
--         ,ov_party_name         => lt_party_name_dummy     -- 顧客名
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
--        -- ===============================================
--        -- 顧客情報抽出処理(A-3)
--        -- ===============================================
--        get_cust_data(
--          ov_errbuf             => lv_errbuf                  -- エラー・メッセージ
--         ,ov_retcode            => lv_retcode                 -- リターン・コード
--         ,ov_errmsg             => lv_errmsg                  -- ユーザー・エラー・メッセージ
--         ,iv_process_flg        => cv_process_flg2            -- 処理フラグ(2：顧客情報)
--         ,iv_selling_base_code  => g_target_rec.base_code     -- 売上拠点
--         ,iv_cust_code          => g_target_rec.cust_code     -- 顧客コード
--         ,ov_selling_base_code  => lt_selling_base_code_dummy -- 売上計上拠点コード
--         ,ov_account_name       => lt_selling_base_name_dummy -- 売上計上拠点名
--         ,ov_address3           => lt_address3_dummy          -- 地区コード
--         ,ov_account_number     => lt_account_number          -- 顧客コード
--         ,ov_party_name         => lt_party_name              -- 顧客名
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.supplier_code <> gt_payment_code_bk ) THEN
--        -- ===============================================
--        -- 仕入先・銀行情報抽出処理(A-4)
--        -- ===============================================
--        get_vendor_data(
--            ov_errbuf                  => lv_errbuf                       -- エラー・メッセージ
--          , ov_retcode                 => lv_retcode                      -- リターン・コード
--          , ov_errmsg                  => lv_errmsg                       -- ユーザー・エラー・メッセージ
--          , iv_supplier_code           => g_target_rec.supplier_code      -- 仕入先コード
--          , iv_supplier_site_code      => g_target_rec.supplier_site_code -- 仕入先サイトコード
--          , ov_vendor_name             => lt_vendor_name                  -- 仕入先名
--          , ov_bank_charge_bearer      => lt_bank_charge_bearer           -- 銀行手数料負担者
--          , ov_hold_all_payments_flag  => lt_hold_all_payments_flag       -- 全支払の保留フラグ
--          , ov_ref_base_code           => lv_ref_base_code                -- DFF5(問合せ担当拠点コード)
--          , ov_bm_kbn_dff4             => lv_bm_kbn_dff4                  -- DFF4(BM支払区分)
--          , ov_bank_number             => lt_bank_number                  -- 銀行番号
--          , ov_bank_name               => lt_bank_name                    -- 銀行口座名
--          , ov_bank_account_type       => lt_bank_account_type            -- 口座種別
--          , ov_bank_account_num        => lt_bank_account_num             -- 銀行口座番号
--          , ov_account_holder_name_alt => lt_account_holder_name_alt      -- 口座名義人カナ
--          , ov_bank_num                => lt_bank_num                     -- 銀行支店番号
--          , ov_bank_branch_name        => lt_bank_branch_name             -- 銀行支店名
--          , ov_account_name            => lt_ref_base_name                -- 問合せ担当拠点名
--          , ov_bm_kbn                  => lv_bm_kbn                       -- BM支払区分
--          , ov_bm_kbn_nm               => lv_bm_kbn_nm                    -- BM支払区分名
--          , ov_bk_account_type         => lv_bk_account_type              -- 口座種別
--          , ov_bk_account_type_nm      => lv_bk_account_type_nm           -- 口座種別名
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      IF ( ln_loop_cnt = 1 )
--        OR ( g_target_rec.base_code <> gt_selling_base_code_bk )
--        OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
--        -- ===============================================
--        -- 販手エラー情報抽出処理(A-5)
--        -- ===============================================
--        get_bm_contract_err(
--            ov_errbuf            => lv_errbuf                       -- エラー・メッセージ
--          , ov_retcode           => lv_retcode                      -- リターン・コード
--          , ov_errmsg            => lv_errmsg                       -- ユーザー・エラー・メッセージ
--          , iv_selling_base_code => g_target_rec.base_code          -- 売上計上拠点コード
--          , iv_cust_code         => g_target_rec.cust_code          -- 顧客コード
--          , on_error_count       => ln_error_count                  -- エラーカウント
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      -- ===============================================
--      -- ブレイク判定処理(A-6)
--      -- ===============================================
--      break_judge(
--          ov_errbuf                  => lv_errbuf                  -- エラー・メッセージ
--        , ov_retcode                 => lv_retcode                 -- リターン・コード
--        , ov_errmsg                  => lv_errmsg                  -- ユーザー・エラー・メッセージ
--        , i_target_rec               => g_target_rec               -- カーソルレコード
--        , it_bank_charge_bearer      => lt_bank_charge_bearer      -- 銀行手数料負担者
--        , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- 全支払の保留フラグ
--        , it_vendor_name             => lt_vendor_name             -- 仕入先名
--        , it_bank_number             => lt_bank_number             -- 銀行番号
--        , it_bank_name               => lt_bank_name               -- 銀行口座名
--        , it_bank_num                => lt_bank_num                -- 銀行支店番号
--        , it_bank_branch_name        => lt_bank_branch_name        -- 銀行支店名
--        , it_bank_account_type       => lt_bank_account_type       -- 口座種別
--        , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- 口座種別名
--        , it_bank_account_num        => lt_bank_account_num        -- 銀行口座番号
--        , it_account_holder_name_alt => lt_account_holder_name_alt -- 口座名義人カナ
--        , iv_ref_base_code           => lv_ref_base_code           -- DFF5(問合せ担当拠点コード)
--        , it_selling_base_name       => lt_selling_base_name       -- 売上計上拠点名
--        , iv_bm_kbn                  => lv_bm_kbn                  -- BM支払区分
--        , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM支払区分名
--        , it_selling_base_code       => lt_selling_base_code       -- 売上計上拠点コード
--        , it_ref_base_name           => lt_ref_base_name           -- 問合せ担当拠点名
--        , it_account_number          => lt_account_number          -- 顧客コード
--        , it_party_name              => lt_party_name              -- 顧客名
--        , it_address3                => lt_address3                -- 地区コード
--        , in_error_count             => ln_error_count             -- 販手エラー件数
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- 
----
--    END LOOP main_loop;
----
-- 2011/01/24 Ver.1.12 [障害E_本稼動_06199] SCS S.Niki DEL END
    -- ===============================================
    -- ブレイク判定処理 最終行(A-6)
    -- ===============================================
    break_judge(
        ov_errbuf                  => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                 => lv_retcode                 -- リターン・コード
      , ov_errmsg                  => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , iv_last_record_flg         => cv_flag_y                  -- 最終レコードフラグ
      , i_target_rec               => g_target_rec               -- カーソルレコード
      , it_bank_charge_bearer      => lt_bank_charge_bearer      -- 銀行手数料負担者
      , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- 全支払の保留フラグ
      , it_vendor_name             => lt_vendor_name             -- 仕入先名
      , it_bank_number             => lt_bank_number             -- 銀行番号
      , it_bank_name               => lt_bank_name               -- 銀行口座名
      , it_bank_num                => lt_bank_num                -- 銀行支店番号
      , it_bank_branch_name        => lt_bank_branch_name        -- 銀行支店名
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD START
--      , it_bank_account_type       => lt_bank_account_type       -- 口座種別
      , iv_bank_account_type       => lv_bank_account_type       -- 口座種別
-- 2011/04/28 Ver.1.14 [障害E_本稼動_02100] SCS S.Niki UPD END
      , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- 口座種別名
      , it_bank_account_num        => lt_bank_account_num        -- 銀行口座番号
      , it_account_holder_name_alt => lt_account_holder_name_alt -- 口座名義人カナ
      , iv_ref_base_code           => lv_ref_base_code           -- DFF5(問合せ担当拠点コード)
      , it_selling_base_name       => lt_selling_base_name       -- 売上計上拠点名
      , iv_bm_kbn                  => lv_bm_kbn                  -- BM支払区分
      , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM支払区分名
      , it_selling_base_code       => lt_selling_base_code       -- 売上計上拠点コード
      , it_ref_base_name           => lt_ref_base_name           -- 問合せ担当拠点名
      , it_account_number          => lt_account_number          -- 顧客コード
      , it_party_name              => lt_party_name              -- 顧客名
      , it_address3                => lt_address3                -- 地区コード
      , in_error_count             => ln_error_count             -- 販手エラー件数
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 登録判定
    -- ===============================================
    IF ( ln_loop_cnt = 0 )
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
      OR ( gn_index = 0 )
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
      OR ( ( g_bm_balance_ttype( gn_index ).UNPAID_LAST_MONTH = 0 )
       AND ( g_bm_balance_ttype( gn_index ).BM_THIS_MONTH = 0 )
       AND ( g_bm_balance_ttype( gn_index ).ELECTRIC_AMT = 0 ) ) THEN
      -- 対象データなし
      gn_target_cnt := 0;
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
      gn_index      := 1;
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
      --項目のクリア(集計した前月までの未払、および当月BM、電気料が0円以下の場合を考慮)
      g_bm_balance_ttype( gn_index ).REF_BASE_CODE             := NULL;
      g_bm_balance_ttype( gn_index ).REF_BASE_NAME             := NULL;
      g_bm_balance_ttype( gn_index ).PAYMENT_CODE              := NULL;
      g_bm_balance_ttype( gn_index ).PAYMENT_NAME              := NULL;
      g_bm_balance_ttype( gn_index ).BANK_NO                   := NULL;
      g_bm_balance_ttype( gn_index ).BANK_NAME                 := NULL;
      g_bm_balance_ttype( gn_index ).BANK_BRANCH_NO            := NULL;
      g_bm_balance_ttype( gn_index ).BANK_BRANCH_NAME          := NULL;
      g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE            := NULL;
      g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE_NAME       := NULL;
      g_bm_balance_ttype( gn_index ).BANK_ACCT_NO              := NULL;
      g_bm_balance_ttype( gn_index ).BANK_ACCT_NAME            := NULL;
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD START
      g_bm_balance_ttype( gn_index ).BM_PAYMENT_CODE           := NULL;
-- 2009/12/15 Ver.1.10 [障害E_本稼動_00461] SCS K.Nakamura ADD END
      g_bm_balance_ttype( gn_index ).BM_PAYMENT_TYPE           := NULL;
      g_bm_balance_ttype( gn_index ).BANK_TRNS_FEE             := NULL;
      g_bm_balance_ttype( gn_index ).PAYMENT_STOP              := NULL;
      g_bm_balance_ttype( gn_index ).SELLING_BASE_CODE         := NULL;
      g_bm_balance_ttype( gn_index ).SELLING_BASE_NAME         := NULL;
      g_bm_balance_ttype( gn_index ).WARNNING_MARK             := NULL;
      g_bm_balance_ttype( gn_index ).CUST_CODE                 := NULL;
      g_bm_balance_ttype( gn_index ).CUST_NAME                 := NULL;
      g_bm_balance_ttype( gn_index ).UNPAID_LAST_MONTH         := NULL;
      g_bm_balance_ttype( gn_index ).BM_THIS_MONTH             := NULL;
      g_bm_balance_ttype( gn_index ).ELECTRIC_AMT              := NULL;
      g_bm_balance_ttype( gn_index ).UNPAID_BALANCE            := NULL;
      g_bm_balance_ttype( gn_index ).RESV_PAYMENT              := NULL;
      g_bm_balance_ttype( gn_index ).PAYMENT_DATE              := NULL;
      g_bm_balance_ttype( gn_index ).CLOSING_DATE              := NULL;
      g_bm_balance_ttype( gn_index ).SELLING_BASE_SECTION_CODE := NULL;
      -- ===============================================
      -- 対象データなしメッセージ取得
      -- ===============================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ワークテーブルデータ登録(A-7)
      -- ===============================================
      ins_worktable_data(
          ov_errbuf                =>  lv_errbuf                -- エラーバッファ
        , ov_retcode               =>  lv_retcode               -- リターンコード
        , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      <<ins_loop>>
      FOR i IN g_bm_balance_ttype.FIRST .. g_bm_balance_ttype.LAST LOOP
        -- ===============================================
        -- ワークテーブルデータ登録(A-7)
        -- ===============================================
        ins_worktable_data(
          ov_errbuf                =>  lv_errbuf                -- エラーバッファ
        , ov_retcode               =>  lv_retcode               -- リターンコード
        , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
        , in_index                 =>  i                        -- インデックス
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP ins_loop;
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD START
      -- ===============================================
      -- 支払ステータス「自動繰越」更新処理(A-10)
      -- ===============================================
      upd_resv_payment(
        ov_errbuf                =>  lv_errbuf                -- エラーバッファ
      , ov_retcode               =>  lv_retcode               -- リターンコード
      , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD END
-- 2013/04/04 Ver.1.17 [障害E_本稼動_10595,10609] SCSK K.Nakamura ADD START
      -- ===============================================
      -- 支払ステータス「消込済」更新処理(A-11)
      -- ===============================================
      upd_resv_payment_rec(
        ov_errbuf                =>  lv_errbuf                -- エラーバッファ
      , ov_retcode               =>  lv_retcode               -- リターンコード
      , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- 2013/04/04 Ver.1.17 [障害E_本稼動_10595,10609] SCSK K.Nakamura ADD END
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
      -- ===============================================
      -- ワークテーブルデータ更新(A-12)
      -- ===============================================
      upd_worktable_data(
        ov_errbuf                =>  lv_errbuf                -- エラーバッファ
      , ov_retcode               =>  lv_retcode               -- リターンコード
      , ov_errmsg                =>  lv_errmsg                -- エラーメッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    END IF;
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
    ov_errbuf                OUT VARCHAR2              -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2              -- リターン・コード
  , ov_errmsg                OUT VARCHAR2              -- ユーザー・エラー・メッセージ
  , iv_payment_date          IN  VARCHAR2 DEFAULT NULL -- 支払日
  , iv_ref_base_code         IN  VARCHAR2 DEFAULT NULL -- 問合せ担当拠点
  , iv_selling_base_code     IN  VARCHAR2 DEFAULT NULL -- 売上計上拠点
  , iv_target_disp           IN  VARCHAR2 DEFAULT NULL -- 表示対象
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  , iv_payment_code          IN  VARCHAR2 DEFAULT NULL -- 支払先コード
  , iv_resv_payment          IN  VARCHAR2 DEFAULT NULL -- 支払ステータス
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(4) := 'init';        -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg     VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_retcode    BOOLEAN        DEFAULT TRUE;              -- メッセージ出力関数戻り値
    lv_profile_nm VARCHAR2(40)   DEFAULT NULL;              -- プロファイル名称の格納用
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 初期処理エラー ***
    init_fail_expt             EXCEPTION; -- 初期処理エラー
    no_profile_expt            EXCEPTION; -- プロファイル値取得エラー
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- プログラム入力項目を出力
    -- ===============================================
    -- 支払年月日
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00071
                 , iv_token_name1  => cv_token_pay_date
                 , iv_token_value1 => iv_payment_date
                 );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_outmsg         --メッセージ
                  , in_new_line => cn_number_0       --改行
                  );
    -- 問合せ担当拠点
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00073
                 , iv_token_name1  => cv_token_ref_base_cd
                 , iv_token_value1 => iv_ref_base_code
                 );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_outmsg         --メッセージ
                  , in_new_line => cn_number_0       --改行
                  );
    -- 売上計上拠点
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00074
                 , iv_token_name1  => cv_token_selling_base_cd
                 , iv_token_value1 => iv_selling_base_code
                 );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_outmsg         --メッセージ
                  , in_new_line => cn_number_0       --改行
                  );
    -- 表示対象
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00075
                 , iv_token_name1  => cv_token_target_disp
                 , iv_token_value1 => iv_target_disp
                 );
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    -- 支払先コード
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00094
                 , iv_token_name1  => cv_token_payment_cd
                 , iv_token_value1 => iv_payment_code
                 );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_outmsg         --メッセージ
                  , in_new_line => cn_number_0       --改行
                  );
    -- 支払ステータス
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00095
                 , iv_token_name1  => cv_token_resv_payment
                 , iv_token_value1 => iv_resv_payment
                 );
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_outmsg         --メッセージ
                  , in_new_line => cn_number_1       --改行
                  );
--
    -- ===============================================
    -- 日付フォーマットチェック
    -- ===============================================
    BEGIN
      gd_payment_date := TO_DATE( iv_payment_date, cv_format_yyyymmdd2 ); -- 入力パラメータの支払日
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10337
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE init_fail_expt;
    END;
    -- ===============================================
    -- 2.	表示対象チェック
    -- ===============================================
    -- 売上計上拠点に値が設定されているが、表示対象に値が設定されていない
    IF ( iv_selling_base_code IS NOT NULL )
       AND ( iv_target_disp IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10338
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE init_fail_expt;
    END IF;
--
    -- 表示対象に値が設定されているが、売上計上拠点に値が設定されていない
    IF ( iv_target_disp IS NOT NULL )
       AND ( iv_selling_base_code IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10338
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE init_fail_expt;
    END IF;
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama DEL START
--    -- ===============================================
--    -- 所属拠点取得
--    -- ===============================================
--    gv_base_code := xxcok_common_pkg.get_base_code_f( SYSDATE , cn_created_by );
--    IF ( gv_base_code IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_short_name
--                    , iv_name         => cv_msg_code_00012
--                    , iv_token_name1  => cv_token_user_id
--                    , iv_token_value1 => cn_created_by
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG
--                    , iv_message  => lv_errmsg
--                    , in_new_line => cn_number_0
--                    );
--      RAISE init_fail_expt;
--    END IF;
--    -- ===============================================
--    -- プロファイル取得(部門コード_業務管理部)
--    -- ===============================================
--    gv_aff2_dept_act := FND_PROFILE.VALUE( cv_prof_aff2_dept_act );
--    IF ( gv_aff2_dept_act IS NULL ) THEN
--      lv_profile_nm := cv_prof_aff2_dept_act;
--      RAISE no_profile_expt;
--    END IF;
-- 2009/10/02 Ver.1.9 [障害E_T3_00630] SCS S.Moriyama DEL END
    -- ===============================================
    -- プロファイル取得(残高一覧_エラーマーク見出し)
    -- ===============================================
    gv_error_mark := FND_PROFILE.VALUE( cv_prof_error_mark );
    IF ( gv_error_mark IS NULL ) THEN
      lv_profile_nm := cv_prof_error_mark;
      RAISE no_profile_expt;
    END IF;
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    -- ===============================================
    -- プロファイル取得(残高一覧_変動電気代未払マーク見出し)
    -- ===============================================
    gv_unpaid_elec_mark := FND_PROFILE.VALUE( cv_prof_unpaid_elec_mark );
    IF ( gv_unpaid_elec_mark IS NULL ) THEN
      lv_profile_nm := cv_prof_unpaid_elec_mark;
      RAISE no_profile_expt;
    END IF;

-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    -- ===============================================
    -- プロファイル取得(残高一覧_停止中見出し)
    -- ===============================================
    gv_pay_stop_name := FND_PROFILE.VALUE( cv_prof_pay_stop_name );
    IF ( gv_pay_stop_name IS NULL ) THEN
      lv_profile_nm := cv_prof_pay_stop_name;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(振込手数料_当方)
    -- ===============================================
    gv_bk_trns_fee_we := FND_PROFILE.VALUE( cv_prof_bk_trns_fee_we );
    IF ( gv_bk_trns_fee_we IS NULL ) THEN
      lv_profile_nm := cv_prof_bk_trns_fee_we;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(振込手数料_相手方)
    -- ===============================================
    gv_bk_trns_fee_ctpty := FND_PROFILE.VALUE( cv_prof_bk_trns_fee_ctpty );
    IF ( gv_bk_trns_fee_ctpty IS NULL ) THEN
      lv_profile_nm := cv_prof_bk_trns_fee_ctpty;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(残高一覧_保留見出し)
    -- ===============================================
    gv_pay_res_name := FND_PROFILE.VALUE( cv_prof_pay_res_name );
    IF ( gv_pay_res_name IS NULL ) THEN
      lv_profile_nm := cv_prof_pay_res_name;
      RAISE no_profile_expt;
    END IF;
-- 2012/07/04 Ver.1.15 [障害E_本稼動_08365] SCSK K.Onotsuka ADD START
    -- ===============================================
    -- プロファイル取得(残高一覧_消込済見出し)
    -- ===============================================
    gv_pay_rec_name := FND_PROFILE.VALUE( cv_prof_pay_rec_name );
    IF ( gv_pay_rec_name IS NULL ) THEN
      lv_profile_nm := cv_prof_pay_rec_name;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(残高一覧_自動繰越見出し)
    -- ===============================================
    gv_pay_auto_res_name := FND_PROFILE.VALUE( cv_prof_pay_auto_res_name );
    IF ( gv_pay_auto_res_name IS NULL ) THEN
      lv_profile_nm := cv_prof_pay_auto_res_name;
      RAISE no_profile_expt;
    END IF;
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD START
    -- ===============================================
    -- プロファイル取得(銀行手数料(振込基準額))
    -- ===============================================
    gn_trans_fee := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_trans_criterion ) );
    IF ( gn_trans_fee IS NULL ) THEN
      lv_profile_nm := cv_prof_trans_criterion;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(銀行手数料額(基準未満))
    -- ===============================================
    gn_less_fee := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_less_fee_criterion ) );
    IF ( gn_less_fee IS NULL ) THEN
      lv_profile_nm := cv_prof_less_fee_criterion;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(銀行手数料額(基準以上))
    -- ===============================================
    gn_more_fee := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_more_fee_criterion ) );
    IF ( gn_more_fee IS NULL ) THEN
      lv_profile_nm := cv_prof_more_fee_criterion;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(消費税率)
    -- ===============================================
    gn_bm_tax := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bm_tax ) );
    IF ( gn_bm_tax IS NULL ) THEN
      lv_profile_nm := cv_prof_bm_tax;
      RAISE no_profile_expt;
    END IF;
-- 2013/01/29 Ver.1.16 [障害E_本稼動_10381] SCSK K.Taniguchi ADD END
-- 2012/07/04 Ver.1.15 [障害E_本稼動_08365] SCSK K.Onotsuka ADD END
    -- ===============================================
    -- プロファイル取得(在庫組織コード_営業組織)
    -- ===============================================
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
--    gv_org_code := FND_PROFILE.VALUE( cv_prof_org_code_sales );
--    IF ( gv_org_code IS NULL ) THEN
--      lv_profile_nm := cv_prof_org_code_sales;
--      RAISE no_profile_expt;
--    END IF;
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
    -- ===============================================
    -- プロファイル取得(営業単位ID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_nm := cv_prof_org_id;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- 在庫組織ID取得
    -- ===============================================
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi START
--    gn_organization_id := xxcoi_common_pkg.get_organization_id( gv_org_code );
--    IF ( gn_organization_id IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_short_name
--                    , iv_name         => cv_msg_code_00013
--                    , iv_token_name1  => cv_token_org_code
--                    , iv_token_value1 => gv_org_code
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG
--                    , iv_message  => lv_errmsg
--                    , in_new_line => cn_number_0
--                    );
--      RAISE init_fail_expt;
--    END IF;
-- 2009/05/19 Ver.1.6 [障害T1_1070] SCS T.Taniguchi END
-- 2009/09/17 Ver.1.8 [障害0001390] SCS S.Moriyama DEL START
--    -- ===============================================
--    -- 拠点セキュリティーチェック
--    -- ===============================================
--    IF ( gv_aff2_dept_act <> gv_base_code ) THEN
--      IF ( iv_selling_base_code IS NULL ) AND ( iv_ref_base_code IS NULL ) THEN
--        lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_xxcok_appl_short_name
--                      , iv_name         => cv_msg_code_10372
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG
--                      , iv_message  => lv_errmsg
--                      , in_new_line => cn_number_0
--                      );
--        RAISE init_fail_expt;
--      END IF;
--    END IF;
-- 2009/09/17 Ver.1.8 [障害0001390] SCS S.Moriyama DEL END
    -- =============================================
    -- 業務処理日付取得
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
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
    -- =============================================
    -- 入力パラメータの表示対象名取得
    -- =============================================
    IF ( iv_target_disp IS NOT NULL ) THEN
      SELECT ffvv.description
      INTO   gv_target_disp_nm
      FROM   fnd_flex_value_sets ffvs
            ,fnd_flex_values_vl  ffvv
      WHERE ffvs.flex_value_set_name = cv_set_name
      AND   ffvs.flex_value_set_id   = ffvv.flex_value_set_id
      AND   ffvv.enabled_flag        = cv_flag_y
      AND   ffvv.flex_value          = iv_target_disp
      ;
    END IF;
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    -- =============================================
    -- 入力パラメータの支払ステータス名取得
    -- =============================================
    IF ( iv_resv_payment IS NOT NULL ) THEN
      SELECT ffvv.description  AS resv_payment_nm
      INTO   gv_resv_payment_nm
      FROM   fnd_flex_value_sets ffvs
           , fnd_flex_values_vl  ffvv
      WHERE  ffvs.flex_value_set_name = cv_set_name_rp  -- 支払ステータス
      AND    ffvs.flex_value_set_id   = ffvv.flex_value_set_id
      AND    ffvv.enabled_flag        = cv_flag_y
      AND    ffvv.flex_value          = iv_resv_payment
      ;
    END IF;
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
    -- ===============================================
    -- 入力パラメータの退避
    -- ===============================================
    gv_ref_base_code     := iv_ref_base_code;     -- 問合せ担当拠点
    gv_selling_base_code := iv_selling_base_code; -- 売上計上拠点
    gv_target_disp       := iv_target_disp;       -- 表示対象
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    gt_payment_code      := iv_payment_code;      -- 支払先コード
    gt_resv_payment      := iv_resv_payment;      -- 支払ステータス
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
--
  EXCEPTION
    --*** プロファイル値取得エラー ***
    WHEN no_profile_expt THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_appl_short_name,
                     iv_name         => cv_msg_code_00003,
                     iv_token_name1  => cv_token_profile,
                     iv_token_value1 => lv_profile_nm
                   );
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 初期処理エラー ***
    WHEN init_fail_expt THEN
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                OUT VARCHAR2               -- エラー・メッセージ
  , ov_retcode               OUT VARCHAR2               -- リターン・コード
  , ov_errmsg                OUT VARCHAR2               -- ユーザー・エラー・メッセージ
  , iv_payment_date          IN  VARCHAR2  DEFAULT NULL -- 支払日
  , iv_ref_base_code         IN  VARCHAR2  DEFAULT NULL -- 問合せ担当拠点
  , iv_selling_base_code     IN  VARCHAR2  DEFAULT NULL -- 売上計上拠点
  , iv_target_disp           IN  VARCHAR2  DEFAULT NULL -- 表示対象
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  , iv_payment_code          IN  VARCHAR2  DEFAULT NULL -- 支払先コード
  , iv_resv_payment          IN  VARCHAR2  DEFAULT NULL -- 支払ステータス
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(7) := 'submain';     -- プログラム名
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
      ov_errbuf                => lv_errbuf            -- エラー・メッセージ
    , ov_retcode               => lv_retcode           -- リターン・コード
    , ov_errmsg                => lv_errmsg            -- ユーザー・エラー・メッセージ
    , iv_payment_date          => iv_payment_date      -- 支払日
    , iv_ref_base_code         => iv_ref_base_code     -- 問合せ担当拠点
    , iv_selling_base_code     => iv_selling_base_code -- 売上計上拠点
    , iv_target_disp           => iv_target_disp       -- 表示対象
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , iv_payment_code          => iv_payment_code      -- 支払先コード
    , iv_resv_payment          => iv_resv_payment      -- 支払ステータス
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
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
    del_worktable_data(
      ov_errbuf   => lv_errbuf   -- エラー・メッセージ
    , ov_retcode  => lv_retcode  -- リターン・コード
    , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
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
  , iv_payment_date          IN  VARCHAR2  -- 1:支払日
  , iv_ref_base_code         IN  VARCHAR2  -- 2:問合せ担当拠点
  , iv_selling_base_code     IN  VARCHAR2  -- 3:売上計上拠点
  , iv_target_disp           IN  VARCHAR2  -- 4:表示対象
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
  , iv_payment_code          IN  VARCHAR2  -- 5:支払先コード
  , iv_resv_payment          IN  VARCHAR2  -- 6:支払ステータス
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name        CONSTANT VARCHAR2(4) := 'main';         -- プログラム名
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
    , iv_which   => 'LOG'-- ログ出力
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf                => lv_errbuf            -- エラー・メッセージ
    , ov_retcode               => lv_retcode           -- リターン・コード
    , ov_errmsg                => lv_errmsg            -- ユーザー・エラー・メッセージ
    , iv_payment_date          => iv_payment_date      -- 支払日
    , iv_ref_base_code         => iv_ref_base_code     -- 問合せ担当拠点
    , iv_selling_base_code     => iv_selling_base_code -- 売上計上拠点
    , iv_target_disp           => iv_target_disp       -- 表示対象
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD START
    , iv_payment_code          => iv_payment_code      -- 支払先コード
    , iv_resv_payment          => iv_resv_payment      -- 支払ステータス
-- Ver.1.18 [障害E_本稼動_10411] SCSK S.Niki ADD END
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
                      in_which    => FND_FILE.LOG   -- 出力区分
                    , iv_message  => lv_errbuf      -- メッセージ
                    , in_new_line => cn_number_1    -- 改行
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
                    in_which    => FND_FILE.LOG     --出力区分
                  , iv_message  => lv_outmsg        --メッセージ
                  , in_new_line => cn_number_0      --改行
                  );
    -- ===============================================
    -- 成功件数出力(エラー発生時、成功件数:0件 エラー件数:1件)
    -- ===============================================
    -- 対象件数が0件の場合、正常件数を0件にする
    IF gn_target_cnt = 0 THEN
      gn_normal_cnt := 0;
    END IF;
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
      gn_error_cnt  := cn_number_1;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90001
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG     --出力区分
                  , iv_message  => lv_outmsg        --メッセージ
                  , in_new_line => cn_number_0      --改行
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
                    in_which    => FND_FILE.LOG     --出力区分
                  , iv_message  => lv_outmsg        --メッセージ
                  , in_new_line => cn_number_1      --改行
                  );
    -- ===============================================
    -- 処理終了メッセージ出力
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    ELSIF ( lv_retcode = cv_status_warn )   THEN
      lv_message_code := cv_msg_code_90005;
    ELSIF ( lv_retcode = cv_status_error )  THEN
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG        --出力区分
                  , iv_message  => lv_outmsg           --メッセージ
                  , in_new_line => cn_number_0         --改行
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
END XXCOK014A04R;
/
