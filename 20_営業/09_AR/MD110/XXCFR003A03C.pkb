CREATE OR REPLACE PACKAGE BODY XXCFR003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A03C(body)
 * Description      : 請求明細データ作成
 * MD.050           : MD050_CFR_003_A03_請求明細データ作成
 * MD.070           : MD050_CFR_003_A03_請求明細データ作成
 * Version          : 1.200
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_target_inv_header  p 対象請求ヘッダデータ抽出処理            (A-2)
 *  ins_inv_detail_data    p 請求明細データ作成処理                  (A-3)
 *  get_update_target_bill p 請求更新対象取得処理                    (A-10)
 *  update_invoice_lines   p 請求金額更新処理 請求明細情報テーブル   (A-11)
 *  update_bill_amount     p 請求金額更新処理 請求ヘッダ情報テーブル (A-11)
 *  update_trx_status      p 取引データステータス更新処理            (A-9)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.00 SCS 松尾 泰生    初回作成
 *  2009/02/20    1.10 SCS 松尾 泰生    [障害CFR_012]容器群項目追加対応
 *  2009/02/23    1.20 SCS 松尾 泰生    [障害CFR_013]AR部門入力データ売上金額不具合対応
 *  2009/07/22    1.30 SCS 廣瀬 真佐人  [障害0000763]パフォーマンス改善
 *  2009/08/03    1.40 SCS 廣瀬 真佐人  [障害0000914]パフォーマンス改善
 *  2009/09/29    1.50 SCS 廣瀬 真佐人  [共通課題IE535] 請求書問題
 *  2009/11/02    1.60 SCS 廣瀬 真佐人  [共通課題IE603] EDI用に出力項目を追加(納品先チェーンコード)
 *  2009/11/16    1.70 SCS 廣瀬 真佐人  [共通課題IE678] パフォーマンス対応
 *  2009/12/02    1.80 SCS 松尾 泰生    [障害本稼動00404] 本振顧客でのデータ取得エラー対応
 *  2010/01/04    1.90 SCS 松尾 泰生    [障害本稼動00826] EDI請求売上返品区分NULLエラー対応
 *  2010/10/19    1.100 SCS 小山 伸男   [障害本稼動05091] 請求書の一部伝票金額が重複している件
 *                                                        ※販売実績明細との条件追加
 *  2011/10/11    1.110 SCS 白川 篤史   [障害本稼動07906] EDIの流通BMS対応
 *  2012/11/06    1.120 SCSK 中村 健一  [障害本稼動10090] 夜間ジョブパフォーマンス対応(JOBの分割対応)
 *                                                        使用していない変数の削除
 *  2013/01/17    1.130 SCSK 中野 徹也  [障害本稼動09964] 請求書再作成時の仕様見直し対応
 *  2013/06/10    1.140 SCSK 中野 徹也  [障害本稼動09964再対応] 請求書再作成時の仕様見直し対応
 *  2016/03/02    1.150 SCSK 小路 恭弘  [障害本稼動13510] 請求書に表示されない品目がある
 *  2019/07/26    1.160 SCSK 箕浦 健治  [E_本稼動_15472] 軽減税率対応
 *  2019/09/06    1.170 SCSK 渡邊 直樹  [E_本稼動_15472] 軽減税率対応 追加対応
 *  2019/09/19    1.180 SCSK 郭 有司    [E_本稼動_15472] 軽減税率対応 再々対応
 *  2023/07/04    1.190 SCSK 赤地 学    [E_本稼動_18983] 消費税差額自動作成
 *                                      [E_本稼動_19082]【AR】インボイス対応_標準請求書
 *  2023/10/25    1.200 SCSK 赤地 学    [E_本稼動_19546] 請求書の消費税額訂正
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg              VARCHAR2(2000);
  gv_sep_msg              VARCHAR2(2000);
  gv_exec_user            VARCHAR2(100);
  gv_conc_name            VARCHAR2(30);
  gv_conc_status          VARCHAR2(30);
  gn_target_header_cnt    NUMBER;                    -- 対象件数(請求ヘッダ単位)
  gn_target_line_cnt      NUMBER;                    -- 対象件数(請求明細単位)
  gn_target_aroif_cnt     NUMBER;                    -- 対象件数(AR取引OIF登録件数)
-- Modify 2012.11.06 Ver1.120 Start
--  gn_target_del_head_cnt  NUMBER;                    -- 対象件数(ヘッダデータ削除件数)
--  gn_target_del_line_cnt  NUMBER;                    -- 対象件数(明細データ削除件数)
--  gn_normal_cnt           NUMBER;                    -- 正常件数
-- Modify 2012.11.06 Ver1.120 End
  gn_error_cnt            NUMBER;                    -- エラー件数
-- Modify 2012.11.06 Ver1.120 Start
--  gn_warn_cnt             NUMBER;                    -- スキップ件数
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.06.10 Ver1.140 Start
-- Modify 2013.01.17 Ver1.130 Start
--  gn_target_up_header_cnt NUMBER;                    -- 更新件数(請求ヘッダ単位)
-- Modify 2013.01.17 Ver1.130 End
-- Modify 2013.06.10 Ver1.140 End
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
  dml_expt              EXCEPTION;      -- ＤＭＬエラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  PRAGMA EXCEPTION_INIT(dml_expt, -24381);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A03C'; -- パッケージ名
  -- プロファイルオプション
-- Modify 2009.09.29 Ver1.5 Start
--  cv_prof_trx_source     CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_TAX_DIFF_TRX_SOURCE';          -- 税差額取引ソース
--  cv_prof_trx_type       CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_TAX_DIFF_TRX_TYPE';            -- 税差額取引タイプ
--  cv_prof_trx_memo_dtl   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_TAX_DIFF_TRX_MEMO_DETAIL';     -- 税差額取引メモ明細
--  cv_prof_trx_dtl_cont   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_TAX_DIFF_TRX_DETAIL_CONTEX';   -- 税差額取引明細コンテキスト値
--  cv_prof_inv_prg_itvl   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_AUTO_INV_MST_PRG_INTERVAL';    -- 要求完了チェック待機秒数
--  cv_prof_inv_prg_wait   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_AUTO_INV_MST_PRG_MAX_WAIT';    -- 要求完了待機最大秒数
-- Modify 2009.09.29 Ver1.5 End
  cv_prof_ar_trx_source  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_AR_DEPT_INPUT_TRX_SOURCE';     -- AR部門入力取引ソース
  cv_prof_mtl_org_code   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_MTL_ORGANIZATION_CODE';        -- 品目マスタ組織コード
-- Modify 2009.08.03 Ver1.4 Start
  cv_prof_bulk_limit     CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_BULK_LIMIT';                   -- バルクリミット値
-- Modify 2009.08.03 Ver1.4 End
  cv_org_id              CONSTANT VARCHAR2(6)  := 'ORG_ID';                     -- 組織ID
  cv_set_of_books_id     CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';           -- 会計帳簿ID
  cv_prof_user_name      CONSTANT VARCHAR2(8)  := 'USERNAME';                   -- ユーザ名
--
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5) := 'XXCFR';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5) := 'XXCCP';
--
  -- メッセージ番号
  cv_msg_ccp_90000  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; --対象件数メッセージ
  cv_msg_ccp_90001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; --成功件数メッセージ
  cv_msg_ccp_90002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; --エラー件数メッセージ
-- Modify 2009.09.29 Ver1.5 Start
--  cv_msg_ccp_90003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003'; --スキップ件数メッセージ
--  cv_msg_ccp_90004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; --正常終了メッセージ
--  cv_msg_ccp_90005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005'; --警告終了メッセージ
--  cv_msg_ccp_90006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; --エラー終了全ロールバックメッセージ
--  cv_msg_ccp_90007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; --エラー終了一部処理メッセージ
-- Modify 2009.09.29 Ver1.5 End
--
  cv_msg_cfr_00003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --ロックエラーメッセージ
  cv_msg_cfr_00004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_cfr_00006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --業務処理日付エラーメッセージ
-- Modify 2009.09.29 Ver1.5 Start
--  cv_msg_cfr_00007  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --データ削除エラーメッセージ
--  cv_msg_cfr_00012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00012'; --コンカレント起動エラーメッセージ
-- Modify 2009.09.29 Ver1.5 End
  cv_msg_cfr_00015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; --取得エラーメッセージ  
  cv_msg_cfr_00016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --データ挿入エラーメッセージ
  cv_msg_cfr_00017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017'; --データ更新エラーメッセージ
  cv_msg_cfr_00018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00018'; --メッセージタイトル(ヘッダ部)
  cv_msg_cfr_00019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00019'; --メッセージタイトル(明細部)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_msg_cfr_00043  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00043'; --自動インボイス処理エラーメッセージ
--  cv_msg_cfr_00044  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00044'; --税差額取引作成エラーメッセージ
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2012.11.06 Ver1.120 Start
--  cv_msg_cfr_00045  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00045'; --エラー終了（請求データ削除済）メッセージ
-- Modify 2012.11.06 Ver1.120 End
  cv_msg_cfr_00046  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00046'; --エラー終了（請求データ未削除）メッセージ
-- Modify 2009.09.29 Ver1.5 Start
--  cv_msg_cfr_00059  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00059'; --トランザクション確定メッセージ
--  cv_msg_cfr_00060  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00060'; --請求データ削除メッセージ
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2012.11.06 Ver1.120 Start
  cv_msg_cfr_00125  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00125'; --入力パラメータ「パラレル実行区分」チェックエラーメッセージ
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.01.17 Ver1.130 Start
  cv_msg_cfr_00146  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00146'; --更新件数メッセージ
-- Modify 2013.01.17 Ver1.130 End
--
  -- 日本語辞書参照コード
-- Modify 2009.09.29 Ver1.5 Start
--  cv_dict_cfr_00303001  CONSTANT VARCHAR2(20) := 'CFR003A03001'; -- 税差額取引会計配分OIF用データ
--  cv_dict_cfr_00303002  CONSTANT VARCHAR2(20) := 'CFR003A03002'; -- 税差額取引ソースID
-- Modify 2009.09.29 Ver1.5 End
  cv_dict_cfr_00303003  CONSTANT VARCHAR2(20) := 'CFR003A03003'; -- AR部門入力取引ソースID
-- Modify 2009.09.29 Ver1.5 Start
--  cv_dict_cfr_00303004  CONSTANT VARCHAR2(20) := 'CFR003A03004'; -- AR取引OIF登録用シーケンス
--  cv_dict_cfr_00303005  CONSTANT VARCHAR2(20) := 'CFR003A03005'; -- AR取引OIFテーブル(LINE行)
--  cv_dict_cfr_00303006  CONSTANT VARCHAR2(20) := 'CFR003A03006'; -- AR取引OIFテーブル(TAX行)
--  cv_dict_cfr_00303007  CONSTANT VARCHAR2(20) := 'CFR003A03007'; -- AR取引会計配分テーブル(REC行)
--  cv_dict_cfr_00303008  CONSTANT VARCHAR2(20) := 'CFR003A03008'; -- AR取引会計配分テーブル(REV行)
--  cv_dict_cfr_00303009  CONSTANT VARCHAR2(20) := 'CFR003A03009'; -- AR取引会計配分テーブル(TAX行)
--  cv_dict_cfr_00303010  CONSTANT VARCHAR2(20) := 'CFR003A03010'; -- 自動インボイス・マスター・プログラム処理
-- Modify 2009.09.29 Ver1.5 End
  cv_dict_cfr_00303011  CONSTANT VARCHAR2(20) := 'CFR003A03011'; -- 取引テーブル
-- Modify 2009.09.29 Ver1.5 Start
--  cv_dict_cfr_00303012  CONSTANT VARCHAR2(20) := 'CFR003A03012'; -- 税差額取引タイプID
-- Modify 2009.09.29 Ver1.5 End
  cv_dict_cfr_00303013  CONSTANT VARCHAR2(20) := 'CFR003A03013'; -- 品目マスタ組織ID
  cv_dict_cfr_00303014  CONSTANT VARCHAR2(20) := 'CFR003A03014'; -- 処理対象コンカレント要求ID
-- Modify 2013.01.17 Ver1.130 Start
  cv_dict_cfr_00302009  CONSTANT VARCHAR2(20) := 'CFR003A02009'; -- 対象取引データ件数
  cv_dict_cfr_00303015  CONSTANT VARCHAR2(20) := 'CFR003A03015'; -- 請求ヘッダデータ作成パラメータ請求先顧客
-- Modify 2013.01.17 Ver1.130 End
--
  -- メッセージトークン
  cv_tkn_prof_name  CONSTANT VARCHAR2(30)  := 'PROF_NAME';       -- プロファイルオプション名
  cv_tkn_table      CONSTANT VARCHAR2(30)  := 'TABLE';           -- テーブル名
-- Modify 2009.09.29 Ver1.5 Start
--  cv_tkn_prg_name   CONSTANT VARCHAR2(30)  := 'PROGRAM_NAME';    -- プログラム名
--  cv_tkn_sqlerrm    CONSTANT VARCHAR2(30)  := 'SQLERRM';         -- SQLエラーメッセージ
--  cv_tkn_req_id     CONSTANT VARCHAR2(30)  := 'REQUEST_ID';      -- 要求ID
--  cv_tkn_cust_code  CONSTANT VARCHAR2(30)  := 'CUST_CODE';       -- 顧客コード
--  cv_tkn_cust_name  CONSTANT VARCHAR2(30)  := 'CUST_NAME';       -- 顧客名
-- Modify 2009.09.29 Ver1.5 End
  cv_tkn_data       CONSTANT VARCHAR2(30)  := 'DATA';            -- データ
  cv_tkn_count      CONSTANT VARCHAR2(30)  := 'COUNT';           -- 件数
--
  -- 使用DB名
  cv_table_xiit       CONSTANT VARCHAR2(100) := 'XXCFR_INV_INFO_TRANSFER';     -- 請求情報引渡テーブル
  cv_table_xtcl       CONSTANT VARCHAR2(100) := 'XXCFR_INV_TARGET_CUST_LIST';  -- 請求締対象顧客ワークテーブル
  cv_table_xxih       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_HEADERS';       -- 請求ヘッダ情報テーブル
  cv_table_xxil       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_LINES';         -- 請求明細情報テーブル
  cv_table_xxgt       CONSTANT VARCHAR2(100) := 'XXCFR_TAX_GAP_TRX_LIST';      -- 税差額取引作成テーブル
--
  -- 参照タイプ
-- Modify 2009.09.29 Ver1.5 Start
--  cv_lookup_aroif_dist     CONSTANT VARCHAR2(100) := 'XXCFR1_TAX_DIFF_AR_IF_DIST';  -- 取引OIF配分用データ
-- Modify 2009.09.29 Ver1.5 End
  cv_lookup_itm_yokigun    CONSTANT VARCHAR2(100) := 'XXCMM_ITM_YOKIGUN';           -- 容器群
  cv_lookup_itm_yokikubun  CONSTANT VARCHAR2(100) := 'XXCMM_YOKI_KUBUN';            -- 容器区分
  cv_lookup_slip_class     CONSTANT VARCHAR2(100) := 'XXCOS1_DELIVERY_SLIP_CLASS';  -- 納品伝票区分
  cv_lookup_sale_class     CONSTANT VARCHAR2(100) := 'XXCOS1_SALE_CLASS';           -- 売上区分
  cv_lookup_vd_class_type  CONSTANT VARCHAR2(100) := 'XXCFR1_VD_TARGET_CLASS_TYPE'; -- 汎用請求VD対象所分類
--
  -- ファイル出力
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log      CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  cv_account_class_rec  CONSTANT VARCHAR2(3)  := 'REC';       -- 勘定区分(売掛/未収金)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_account_class_rev  CONSTANT VARCHAR2(3)  := 'REV';       -- 勘定区分(収益)
--  cv_account_class_tax  CONSTANT VARCHAR2(3)  := 'TAX';       -- 勘定区分(税金)
-- Modify 2009.09.29 Ver1.5 End
  cv_inv_hold_status_o  CONSTANT VARCHAR2(4)  := 'OPEN';      -- 請求書保留ステータス(オープン)
  cv_inv_hold_status_r  CONSTANT VARCHAR2(7)  := 'REPRINT';   -- 請求書保留ステータス(再請求)
  cv_inv_hold_status_p  CONSTANT VARCHAR2(7)  := 'PRINTED';   -- 請求書保留ステータス(印刷済)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_inv_hold_status_w  CONSTANT VARCHAR2(7)  := 'WAITING';   -- 請求書保留ステータス(保留)
-- Modify 2009.09.29 Ver1.5 End
  cv_line_type_tax      CONSTANT VARCHAR2(3)  := 'TAX';       -- 取引明細タイプ(税金)
  cv_line_type_line     CONSTANT VARCHAR2(4)  := 'LINE';      -- 取引明細タイプ(明細)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_get_acct_name_f    CONSTANT VARCHAR2(1)  := '0';         -- 顧客名称取得関数パラメータ(全角)
--  cv_get_acct_name_k    CONSTANT VARCHAR2(1)  := '1';         -- 顧客名称取得関数パラメータ(カナ)
-- Modify 2009.09.29 Ver1.5 End
  cv_inv_type_no        CONSTANT VARCHAR2(2)  := '00';        -- 請求区分(通常)
  cv_inv_type_re        CONSTANT VARCHAR2(2)  := '01';        -- 請求区分(再請求)
  cv_tax_div_outtax     CONSTANT VARCHAR2(1)  := '1';         -- 消費税区分(外税)
  cv_tax_div_inslip     CONSTANT VARCHAR2(1)  := '2';         -- 消費税区分(内税(伝票))
  cv_tax_div_inunit     CONSTANT VARCHAR2(1)  := '3';         -- 消費税区分(内税(単価))
  cv_tax_div_notax      CONSTANT VARCHAR2(1)  := '4';         -- 消費税区分(非課税)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_currency_code      CONSTANT VARCHAR2(3)  := 'JPY';       -- 通貨コード
--  cv_conversion_type    CONSTANT VARCHAR2(4)  := 'User';      -- 換算タイプ
--  cn_conversion_rate    CONSTANT NUMBER       := 1;           -- 換算レート
--  cv_amt_incl_tax_flg_n CONSTANT VARCHAR2(1)  := 'N';         -- 税込金額フラグ(N)
--  cv_amt_incl_tax_flg_y CONSTANT VARCHAR2(1)  := 'Y';         -- 税込金額フラグ(Y)
--  cv_enabled_flag_y     CONSTANT VARCHAR2(1)  := 'Y';         -- 有効フラグ(Y)
--
--  -- 自動インボイス起動用
--  cv_auto_inv_appl_name CONSTANT VARCHAR2(2)   := 'AR';       -- 自動インボイスアプリケーション名
--  cv_auto_inv_prg_name  CONSTANT VARCHAR2(6)   := 'RAXMTR';   -- 自動インボイスプログラム名
--  cv_conc_phase_cmplt   CONSTANT VARCHAR2(8)   := 'COMPLETE'; -- コンカレント状態(完了)
--  cv_conc_status_norml  CONSTANT VARCHAR2(6)   := 'NORMAL';   -- コンカレント終了ステータス(正常)
  -- 受注ソース(媒体区分)
  cv_medium_class_edi   CONSTANT VARCHAR2(2)  := '00';          -- 媒体区分:EDI
  cv_medium_class_mnl   CONSTANT VARCHAR2(2)  := '01';          -- 媒体区分:手入力
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2010.01.04 Ver1.9 Start
  cv_sold_return_type_ar  CONSTANT VARCHAR2(1)  := '1';         -- 売上返品区分(AR部門入力用)
-- Modify 2010.01.04 Ver1.9 End
-- Modify 2012.11.06 Ver1.120 Start
  cv_judge_type_batch   CONSTANT VARCHAR2(1)  := '2';           -- 夜間手動判断区分(夜間)
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.06.10 Ver1.140 Start
  cv_inv_creation_flag  CONSTANT VARCHAR2(1)  := 'Y';           -- 請求作成対象フラグ(Y)
-- Modify 2013.06.10 Ver1.140 End
-- Ver1.190 Add Start
  -- 端数処理区分
  cv_tax_rounding_rule_down        CONSTANT VARCHAR2(10)    :=  'DOWN';    -- 切り捨て
  cv_output_format_1               CONSTANT VARCHAR2(1)     :=   '1';      -- 請求書出力形式（伊藤園標準）
  cv_output_format_4               CONSTANT VARCHAR2(1)     :=   '4';      -- 請求書出力形式（業者委託）
  cv_output_format_5               CONSTANT VARCHAR2(1)     :=   '5';      -- 請求書出力形式（発行なし）
-- Ver1.190 Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
-- Modify 2012.11.06 Ver1.120 Start
--    TYPE get_invoice_id_ttype    IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE 
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_cust_code_ttype     IS TABLE OF xxcfr_invoice_headers.bill_cust_code%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_cutoff_date_ttype   IS TABLE OF xxcfr_invoice_headers.cutoff_date%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_cust_acct_id_ttype  IS TABLE OF xxcfr_invoice_headers.bill_cust_account_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_cust_site_id_ttype  IS TABLE OF xxcfr_invoice_headers.bill_cust_acct_site_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_gap_amt_ttype   IS TABLE OF xxcfr_invoice_headers.tax_gap_amount%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_term_name_ttype     IS TABLE OF xxcfr_invoice_headers.term_name%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_term_id_ttype       IS TABLE OF xxcfr_invoice_headers.term_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_send_addr1_ttype    IS TABLE OF xxcfr_invoice_headers.send_address1%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_send_addr2_ttype    IS TABLE OF xxcfr_invoice_headers.send_address2%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_send_addr3_ttype    IS TABLE OF xxcfr_invoice_headers.send_address3%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_rec_loc_code_ttype  IS TABLE OF xxcfr_invoice_headers.receipt_location_code%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_type_ttype      IS TABLE OF xxcfr_invoice_headers.tax_type%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_bil_loc_code_ttype  IS TABLE OF xxcfr_invoice_headers.bill_location_code%TYPE
--                                             INDEX BY PLS_INTEGER;
----
--    gt_invoice_id_tab        get_invoice_id_ttype;
--    gt_cust_code_tab         get_cust_code_ttype;
--    gt_cutoff_date_tab       get_cutoff_date_ttype;
--    gt_cust_acct_id_tab      get_cust_acct_id_ttype;
--    gt_cust_site_id_tab      get_cust_site_id_ttype;
--    gt_tax_gap_amt_tab       get_tax_gap_amt_ttype;
--    gt_term_name_tab         get_term_name_ttype;
--    gt_term_id_tab           get_term_id_ttype;
--    gt_send_addr1_tab        get_send_addr1_ttype;
--    gt_send_addr2_tab        get_send_addr2_ttype;
--    gt_send_addr3_tab        get_send_addr3_ttype;
--    gt_rec_loc_code_tab      get_rec_loc_code_ttype;
--    gt_tax_type_tab          get_tax_type_ttype;
--    gt_bil_loc_code_tab      get_bil_loc_code_ttype;
-- Modify 2012.11.06 Ver1.120 End
--
-- Modify 2013.01.17 Ver1.130 Start
    TYPE get_inv_id_ttype          IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_amt_no_tax_ttype      IS TABLE OF xxcfr_invoice_headers.inv_amount_no_tax%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_tax_amt_sum_ttype     IS TABLE OF xxcfr_invoice_headers.tax_amount_sum%TYPE
                                                  INDEX BY PLS_INTEGER;
-- Ver1.190 Del Start
--    TYPE get_amd_inc_tax_ttype     IS TABLE OF xxcfr_invoice_headers.inv_amount_includ_tax%TYPE
--                                                  INDEX BY PLS_INTEGER;
-- Ver1.190 Del End
--
    gt_get_inv_id_tab            get_inv_id_ttype;
-- Ver1.190 Del Start
--    gt_get_amt_no_tax_tab        get_amt_no_tax_ttype;
--    gt_get_tax_amt_sum_tab       get_tax_amt_sum_ttype;
--    gt_get_amd_inc_tax_tab       get_amd_inc_tax_ttype;
-- Ver1.190 Del End
-- Modify 2013.01.17 Ver1.130 End
-- Ver1.190 Add Start
    TYPE get_tax_gap_amount_ttype    IS TABLE OF xxcfr_invoice_headers.tax_gap_amount%TYPE      INDEX BY PLS_INTEGER;
    TYPE get_inv_gap_amount_ttype    IS TABLE OF xxcfr_invoice_headers.inv_gap_amount%TYPE      INDEX BY PLS_INTEGER;
    TYPE get_invoice_tax_div_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_tax_div%TYPE     INDEX BY PLS_INTEGER;
    TYPE get_output_format_ttype     IS TABLE OF xxcfr_invoice_headers.output_format%TYPE       INDEX BY PLS_INTEGER;
    TYPE get_tax_div_ttype           IS TABLE OF xxcmm_cust_accounts.tax_div%TYPE               INDEX BY PLS_INTEGER;
--
    gt_invoice_tax_div_tab    get_invoice_tax_div_ttype;       -- 請求書消費税積上げ計算方式
    gt_output_format_tab      get_output_format_ttype;         -- 請求書出力形式
    gt_tax_gap_amount_tab     get_tax_gap_amount_ttype;        -- 税差額
    gt_tax_sum1_tab           get_tax_amt_sum_ttype;           -- 税額合計１
    gt_tax_sum2_tab           get_tax_amt_sum_ttype;           -- 税額合計２
    gt_inv_gap_amount_tab     get_inv_gap_amount_ttype;        -- 本体差額
    gt_no_tax_sum1_tab        get_amt_no_tax_ttype;            -- 税抜合計１
    gt_no_tax_sum2_tab        get_amt_no_tax_ttype;            -- 税抜合計２
    gt_tax_div_tab            get_tax_div_ttype;               -- 消費税区分
-- Ver1.190 Add End
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- Modify 2009.09.29 Ver1.5 Start
--  gt_taxd_trx_source     fnd_profile_option_values.profile_option_value%TYPE;  -- 税差額取引ソース
--  gt_taxd_trx_type       fnd_profile_option_values.profile_option_value%TYPE;  -- 税差額取引タイプ
--  gt_taxd_trx_memo_dtl   fnd_profile_option_values.profile_option_value%TYPE;  -- 税差額取引メモ明細
--  gt_taxd_trx_dtl_cont   fnd_profile_option_values.profile_option_value%TYPE;  -- 税差額取引明細コンテキスト値
--  gt_taxd_inv_prg_itvl   fnd_profile_option_values.profile_option_value%TYPE;  -- 要求完了チェック待機秒数
--  gt_taxd_inv_prg_wait   fnd_profile_option_values.profile_option_value%TYPE;  -- 要求完了待機最大秒数
-- Modify 2009.09.29 Ver1.5 End
  gt_taxd_ar_trx_source  fnd_profile_option_values.profile_option_value%TYPE;  -- AR部門入力取引ソース
  gt_mtl_org_code        fnd_profile_option_values.profile_option_value%TYPE;  -- 品目マスタ組織コード
-- Modify 2009.09.29 Ver1.5 Start
--  gt_rec_aff_segment1    gl_code_combinations.segment1%TYPE;                   -- AFF会社
--  gt_rec_aff_segment2    gl_code_combinations.segment2%TYPE;                   -- AFF部門
--  gt_rec_aff_segment5    gl_code_combinations.segment5%TYPE;                   -- AFF顧客コード
--  gt_rec_aff_segment6    gl_code_combinations.segment6%TYPE;                   -- AFF企業コード
--  gt_rec_aff_segment7    gl_code_combinations.segment7%TYPE;                   -- AFF予備１
--  gt_rec_aff_segment8    gl_code_combinations.segment8%TYPE;                   -- AFF予備２
-- Modify 2009.09.29 Ver1.5 End
  gt_user_name           fnd_profile_option_values.profile_option_value%TYPE;  -- ユーザ名
-- Modify 2009.09.29 Ver1.5 Start
--  gt_tax_gap_trx_source_id  ra_batch_sources_all.batch_source_id%TYPE;         -- 税差額取引ソースID
-- Modify 2009.09.29 Ver1.5 End
  gt_arinput_trx_source_id  ra_batch_sources_all.batch_source_id%TYPE;         -- AR部門入力取引ソースID
-- Modify 2009.09.29 Ver1.5 Start
--  gt_tax_gap_trx_type_id    ra_cust_trx_types_all.cust_trx_type_id%TYPE;       -- 税差額取引タイプID
-- Modify 2009.09.29 Ver1.5 End
  gt_target_request_id      xxcfr_inv_info_transfer.target_request_id%TYPE;    -- 処理対象コンカレント要求ID
  gt_mtl_organization_id mtl_parameters.organization_id%TYPE;                  -- 品目マスタ組織ID
-- Modify 2013.01.17 Ver1.130 Start
  gt_bill_acct_code         xxcfr_inv_info_transfer.bill_acct_code%TYPE;       -- 請求先顧客コード
-- Modify 2013.01.17 Ver1.130 End
--
-- Modify 2012.11.06 Ver1.120 Start
--  gd_target_date         DATE;                                                 -- 締日(日付型)
-- Modify 2012.11.06 Ver1.120 End
  gn_org_id              NUMBER;                                               -- 組織ID
  gn_set_book_id         NUMBER;                                               -- 会計帳簿ID
  gd_process_date        DATE;                                                 -- 業務処理日付
-- Modify 2012.11.06 Ver1.120 Start
--  gd_work_day_ago1       DATE;                                                 -- 1営業日前日
--  gd_work_day_ago2       DATE;                                                 -- 2営業日前日
--  gv_warning_flag        VARCHAR2(1);                                          -- 警告フラグ
--  gv_auto_inv_err_flag   VARCHAR2(1);                                          -- 自動インボイスエラーフラグ
-- Modify 2012.11.06 Ver1.120 End
--
-- Modify 2009.08.03 Ver1.4 Start
  gn_bulk_limit          PLS_INTEGER;     -- バルクのリミット値
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2012.11.06 Ver1.120 Start
  gn_parallel_type       NUMBER      DEFAULT NULL; -- パラレル実行区分
  gv_batch_on_judge_type VARCHAR2(1) DEFAULT NULL; -- 夜間手動判断区分
-- Modify 2012.11.06 Ver1.120 End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- Modify 2012.11.06 Ver1.120 Start
    iv_parallel_type        IN  VARCHAR2,     -- パラレル実行区分
    iv_batch_on_judge_type  IN  VARCHAR2,     -- 夜間手動判断区分
-- Modify 2012.11.06 Ver1.120 End
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_prof_name        fnd_profile_options_tl.user_profile_option_name%TYPE;
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out        -- メッセージ出力
-- Modify 2012.11.06 Ver1.120 Start
      ,iv_conc_param1  => iv_parallel_type        -- パラレル実行区分
      ,iv_conc_param2  => iv_batch_on_judge_type  -- 夜間手動判断区分
-- Modify 2012.11.06 Ver1.120 End
      ,ov_errbuf       => lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode              -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log        -- ログ出力
-- Modify 2012.11.06 Ver1.120 Start
      ,iv_conc_param1  => iv_parallel_type        -- パラレル実行区分
      ,iv_conc_param2  => iv_batch_on_judge_type  -- 夜間手動判断区分
-- Modify 2012.11.06 Ver1.120 End
      ,ov_errbuf       => lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode              -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
-- Modify 2012.11.06 Ver1.120 Start
    -- 入力パラメータ「夜間手動判断区分」の設定
    gv_batch_on_judge_type := iv_batch_on_judge_type;
    --
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- 入力パラメータ「夜間手動判断区分」が'2'(夜間)の場合
    IF ( gv_batch_on_judge_type = cv_judge_type_batch ) THEN
      -- 入力パラメータ「パラレル実行区分」必須チェック
      IF ( iv_parallel_type IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr       -- アプリケーション短縮名
                                             ,iv_name         => cv_msg_cfr_00125);  -- メッセージ
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_api_expt;
      END IF;
      -- 入力パラメータ「パラレル実行区分」数値チェック
      BEGIN
        gn_parallel_type := TO_NUMBER( iv_parallel_type );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr       -- アプリケーション短縮名
                                               ,iv_name         => cv_msg_cfr_00125);  -- メッセージ
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
-- Modify 2012.11.06 Ver1.120 End
    --==============================================================
    --プロファイル取得処理
    --==============================================================
-- Modify 2009.09.29 Ver1.5 Start
--    --税差額取引ソース
--    gt_taxd_trx_source := fnd_profile.value(cv_prof_trx_source);
--    IF (gt_taxd_trx_source IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_source);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --税差額取引タイプ
--    gt_taxd_trx_type := fnd_profile.value(cv_prof_trx_type);
--    IF (gt_taxd_trx_type IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_type);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --税差額取引メモ明細
--    gt_taxd_trx_memo_dtl := fnd_profile.value(cv_prof_trx_memo_dtl);
--    IF (gt_taxd_trx_memo_dtl IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_memo_dtl);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --税差額取引明細コンテキスト値
--    gt_taxd_trx_dtl_cont := fnd_profile.value(cv_prof_trx_dtl_cont);
--    IF (gt_taxd_trx_dtl_cont IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_dtl_cont);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --要求完了チェック待機秒数
--    gt_taxd_inv_prg_itvl := fnd_profile.value(cv_prof_inv_prg_itvl);
--    IF (gt_taxd_inv_prg_itvl IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_inv_prg_itvl);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --要求完了待機最大秒数
--    gt_taxd_inv_prg_wait := fnd_profile.value(cv_prof_inv_prg_wait);
--    IF (gt_taxd_inv_prg_wait IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_inv_prg_wait);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- Modify 2009.09.29 Ver1.5 End
--
    --AR部門入力取引ソース
    gt_taxd_ar_trx_source := fnd_profile.value(cv_prof_ar_trx_source);
    IF (gt_taxd_ar_trx_source IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_ar_trx_source);
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
                                                    ,iv_name         => cv_msg_cfr_00004
                                                    ,iv_token_name1  => cv_tkn_prof_name
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --品目マスタ組織コード
    gt_mtl_org_code := fnd_profile.value(cv_prof_mtl_org_code);
    IF (gt_mtl_org_code IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_mtl_org_code);
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
                                                    ,iv_name         => cv_msg_cfr_00004
                                                    ,iv_token_name1  => cv_tkn_prof_name
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --組織ID
    gn_org_id := TO_NUMBER(fnd_profile.value(cv_org_id));
    IF (gn_org_id IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_org_id);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --会計帳簿ID
    gn_set_book_id := TO_NUMBER(fnd_profile.value(cv_set_of_books_id));
    IF (gn_set_book_id IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_set_of_books_id);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --ユーザ名
    gt_user_name := fnd_profile.value(cv_prof_user_name);
    IF (gt_user_name IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_user_name);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.08.03 Ver1.4 Start
    -- バルクのリミット値を設定
    gn_bulk_limit := fnd_profile.value(cv_prof_bulk_limit);
    IF (gn_bulk_limit IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_bulk_limit);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Modify 2009.08.03 Ver1.4 End
    --==============================================================
    --業務処理日付取得処理
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date());
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00006  )
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.09.29 Ver1.5 Start
--    --==============================================================
--    --税差額取引会計配分用OIFレコード用データ抽出処理
--    --==============================================================
--    BEGIN
--      SELECT fnlv.attribute1     attribute1,
--             fnlv.attribute2     attribute2,
--             fnlv.attribute5     attribute5,
--             fnlv.attribute6     attribute6,
--             fnlv.attribute7     attribute7,
--             fnlv.attribute8     attribute8
--      INTO   gt_rec_aff_segment1,
--             gt_rec_aff_segment2,
--             gt_rec_aff_segment5,
--             gt_rec_aff_segment6,
--             gt_rec_aff_segment7,
--             gt_rec_aff_segment8
--      FROM   fnd_lookup_values         fnlv        -- クイックコード
--      WHERE  fnlv.lookup_code  = cv_account_class_rec          --勘定区分(売掛/未収金)
--      AND    fnlv.lookup_type  = cv_lookup_aroif_dist
--      AND    fnlv.language     = USERENV( 'LANG' )
--      AND    fnlv.enabled_flag = 'Y'
--      AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active, gd_process_date ) )
--                                 AND  TRUNC( NVL( fnlv.end_date_active,   gd_process_date ) )
--      AND    ROWNUM = 1
--      ;
----
--    EXCEPTION
--      -- *** OTHERS例外ハンドラ ***
--      WHEN OTHERS THEN
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                               iv_keyword            => cv_dict_cfr_00303001);    -- 配分OIF用データ
--        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cfr,
--                               iv_name         => cv_msg_cfr_00015,  
--                               iv_token_name1  => cv_tkn_data,  
--                               iv_token_value1 => lt_look_dict_word),
--                             1,
--                             5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
----
--    --==============================================================
--    --取引ソースIDの抽出処理
--    --==============================================================
--    --税差額取引ソースID
--    BEGIN
--      SELECT rbsa.batch_source_id     batch_source_id
--      INTO   gt_tax_gap_trx_source_id
--      FROM   ra_batch_sources_all  rbsa
--      WHERE  rbsa.name = gt_taxd_trx_source
--      AND    rbsa.org_id = gn_org_id
--      ;
----
--    EXCEPTION
--        -- *** OTHERS例外ハンドラ ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303002);    -- 税差額取引ソースID
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr,
--                                 iv_name         => cv_msg_cfr_00015,  
--                                 iv_token_name1  => cv_tkn_data,  
--                                 iv_token_value1 => lt_look_dict_word),
--                               1,
--                               5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
-- Modify 2009.09.29 Ver1.5 End
--
    --AR部門入力取引ソースID
    BEGIN
      SELECT rbsa.batch_source_id      batch_source_id
      INTO   gt_arinput_trx_source_id
      FROM   ra_batch_sources_all  rbsa
      WHERE  rbsa.name = gt_taxd_ar_trx_source
      AND    rbsa.org_id = gn_org_id
      ;
--
    EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00303003);    -- AR部門入力取引ソースID
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
-- Modify 2009.09.29 Ver1.5 Start
--    --==============================================================
--    --税差額要取引タイプID抽出処理
--    --==============================================================
--    -- 取引タイプID
--    BEGIN
--      SELECT rctt.cust_trx_type_id    batch_source_id
--      INTO   gt_tax_gap_trx_type_id
--      FROM   ra_cust_trx_types_all    rctt
--      WHERE  rctt.name = gt_taxd_trx_type                 -- 取引タイプ名
--      AND    gd_process_date BETWEEN  TRUNC( NVL( rctt.start_date, gd_process_date ) )
--                                 AND  TRUNC( NVL( rctt.end_date,   gd_process_date ) )
--      AND    rctt.set_of_books_id = gn_set_book_id        -- 会計帳簿ID
--      AND    rctt.org_id = gn_org_id                      -- 組織ID
--      ;
----
--    EXCEPTION
--        -- *** OTHERS例外ハンドラ ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303012);    -- 税差額取引タイプID
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr,
--                                 iv_name         => cv_msg_cfr_00015,  
--                                 iv_token_name1  => cv_tkn_data,  
--                                 iv_token_value1 => lt_look_dict_word),
--                               1,
--                               5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
-- Modify 2009.09.29 Ver1.5 End
--
    --==============================================================
    --品目マスタ組織ID抽出処理
    --==============================================================
    --品目マスタ組織ID
    BEGIN
      SELECT mtlp.organization_id
      INTO   gt_mtl_organization_id
      FROM   mtl_parameters mtlp
      WHERE  mtlp.organization_code = gt_mtl_org_code
      ;
--
    EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00303013);    -- 品目マスタ組織ID
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;

--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** データ取得例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_target_inv_header
   * Description      : 対象請求ヘッダデータ抽出処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_inv_header(
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_inv_header'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ローカル・カーソル ***
    -- 請求ヘッダデータカーソル
-- Modify 2012.11.06 Ver1.120 Start
--    CURSOR get_inv_header_cur(
--      iv_request_id    VARCHAR2
--    )
--    IS
---- Modify 2009.08.03 Ver1.4 Start
----      SELECT xxih.invoice_id              invoice_id,             -- 一括請求書ID
--      SELECT /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
--             xxih.invoice_id              invoice_id,             -- 一括請求書ID
------ Modify 2009.08.03 Ver1.4 End
--             xxih.bill_cust_code          bill_cust_code,         -- 請求先顧客コード
--             xxih.cutoff_date             cutoff_date,            -- 締日
--             xxih.bill_cust_account_id    bill_cust_account_id,   -- 請求先顧客ID
--             xxih.bill_cust_acct_site_id  bill_cust_acct_site_id, -- 請求先顧客所在地ID
--             xxih.tax_gap_amount          tax_gap_amount,         -- 税差額
--             xxih.term_name               term_name,              -- 支払条件
--             xxih.term_id                 term_id,                -- 支払条件ID
--             xxih.send_address1           send_address1,          -- 送付先住所1
--             xxih.send_address2           send_address2,          -- 送付先住所2
--             xxih.send_address3           send_address3,          -- 送付先住所3
--             xxih.receipt_location_code   receipt_location_code,  -- 入金拠点コード
--             xxih.tax_type                tax_type,               -- 消費税区分
--             xxih.bill_location_code      bill_location_code      -- 請求拠点コード
--      FROM   xxcfr_invoice_headers xxih                   -- 請求ヘッダ情報テーブル
--      WHERE  xxih.request_id = iv_request_id              -- コンカレント要求ID
--      AND    xxih.org_id = gn_org_id                      -- 組織ID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- 会計帳簿ID
--      FOR UPDATE NOWAIT
    CURSOR get_inv_header_cur
    IS
      SELECT /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
             COUNT(1)              xxih_count             -- 件数
      FROM   xxcfr_invoice_headers xxih                   -- 請求ヘッダ情報テーブル
      WHERE  xxih.request_id       = gt_target_request_id -- コンカレント要求ID
      AND    xxih.org_id           = gn_org_id            -- 組織ID
      AND    xxih.set_of_books_id  = gn_set_book_id       -- 会計帳簿ID
      AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- 夜間手動判断区分が'2'(夜間)
      AND     ( xxih.parallel_type      = gn_parallel_type ) )  -- パラレル実行区分が一致
      OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- 夜間手動判断区分が'0'(手動)
      AND     ( xxih.parallel_type     IS NULL ) ) )            -- パラレル実行区分がNULL
-- Modify 2012.11.06 Ver1.120 End
    ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --請求情報引渡テーブルデータ抽出処理
    --==============================================================
    -- 処理対象コンカレント要求ID抽出
--
    BEGIN
      SELECT xiit.target_request_id  target_request_id
      INTO   gt_target_request_id
      FROM   xxcfr_inv_info_transfer xiit
      WHERE  xiit.set_of_books_id = gn_set_book_id
      AND    xiit.org_id = gn_org_id
      ;
--
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00303014);    -- 処理対象コンカレント要求ID
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
-- Modify 2013.01.17 Ver1.130 Start
    -- 請求ヘッダデータ作成パラメータ請求先顧客抽出（手動実行時用）
    IF (gv_batch_on_judge_type != cv_judge_type_batch) THEN
      BEGIN
        SELECT xiit.bill_acct_code     bill_acct_code
        INTO   gt_bill_acct_code
        FROM   xxcfr_inv_info_transfer xiit
        WHERE  xiit.set_of_books_id = gn_set_book_id
        AND    xiit.org_id = gn_org_id
        ;
--
      EXCEPTION
      -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00303015);  -- 請求ヘッダデータ作成請求先顧客
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr,
                                   iv_name         => cv_msg_cfr_00015,  
                                   iv_token_name1  => cv_tkn_data,  
                                   iv_token_value1 => lt_look_dict_word),
                                 1,
                                 5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
      -- 請求ヘッダデータ作成パラメータ請求先顧客の必須チェック
      IF ( gt_bill_acct_code IS NULL ) THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00303015);  -- 請求ヘッダデータ作成請求先顧客
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
-- Modify 2013.01.17 Ver1.130 End
    --請求ヘッダ情報データ抽出処理
-- Modify 2012.11.06 Ver1.120 Start
--    -- カーソルオープン
--    OPEN get_inv_header_cur(
--           gt_target_request_id
--         );
--
--    -- データの一括取得
--    FETCH get_inv_header_cur 
--    BULK COLLECT INTO gt_invoice_id_tab,    -- 一括請求書ID
--                      gt_cust_code_tab,     -- 請求先顧客コード
--                      gt_cutoff_date_tab,   -- 締日
--                      gt_cust_acct_id_tab,  -- 請求先顧客ID
--                      gt_cust_site_id_tab,  -- 請求先顧客所在地ID
--                      gt_tax_gap_amt_tab,   -- 税差額
--                      gt_term_name_tab,     -- 支払条件
--                      gt_term_id_tab,       -- 支払条件ID
--                      gt_send_addr1_tab,    -- 送付先住所1
--                      gt_send_addr2_tab,    -- 送付先住所2
--                      gt_send_addr3_tab,    -- 送付先住所3
--                      gt_rec_loc_code_tab,  -- 入金拠点コード
--                      gt_tax_type_tab,      -- 消費税区分
--                      gt_bil_loc_code_tab   -- 請求拠点コード
--    ;
----
--    -- 処理件数のセット
--    gn_target_header_cnt := gt_invoice_id_tab.COUNT;
    -- カーソルオープン
    OPEN get_inv_header_cur;
    --
    -- 処理件数のセット
    FETCH get_inv_header_cur INTO gn_target_header_cnt;
-- Modify 2012.11.06 Ver1.120 End
--
    -- カーソルクローズ
    CLOSE get_inv_header_cur;
--
  EXCEPTION
    -- *** テーブルロックエラーハンドラ ***
    WHEN lock_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_inv_header_cur%ISOPEN ) THEN
        CLOSE get_inv_header_cur;
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                             ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                             ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                       -- 請求ヘッダ情報テーブル
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_inv_header_cur%ISOPEN ) THEN
        CLOSE get_inv_header_cur;
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_inv_header_cur%ISOPEN ) THEN
        CLOSE get_inv_header_cur;
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_target_inv_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_inv_detail_data
   * Description      : 請求明細データ作成処理(A-3)
   ***********************************************************************************/
  PROCEDURE ins_inv_detail_data(
-- Modify 2009.07.22 Ver1.3 Start
--    in_invoice_id           IN  NUMBER,       -- 一括請求書ID
--    iv_cust_acct_id         IN  VARCHAR2,     -- 請求先顧客ID
--    id_cutoff_date          IN  DATE,         -- 締日
--    iv_tax_type             IN  VARCHAR2,     -- 消費税区分
-- Modify 2009.07.22 Ver1.3 End
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_detail_data'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt       NUMBER;         -- 対象件数
--
    -- *** ローカル・カーソル ***
-- Modify 2009.08.03 Ver1.4 Start
    CURSOR main_data_cur 
    IS
    SELECT inlv.invoice_id                   invoice_id,                    -- 一括請求書ID
           ROWNUM                            invoice_detail_num,            -- 一括請求書明細No
           inlv.note_line_id                 note_line_id,                  -- 伝票明細No
           inlv.ship_cust_code               ship_cust_code,                -- 納品先顧客コード
-- Modify 2009.09.29 Ver1.5 Start
--           ship.party_name                   ship_cust_name,                -- 納品先顧客名
--           ship.organization_name_phonetic   ship_cust_kana_name,           -- 納品先顧客カナ名
           inlv.ship_cust_name               ship_cust_name,                -- 納品先顧客名
           inlv.ship_cust_kana_name          ship_cust_kana_name,           -- 納品先顧客カナ名
-- Modify 2009.09.29 Ver1.5 End
           inlv.sold_location_code           sold_location_code,            -- 売上拠点コード
-- Modify 2009.09.29 Ver1.5 Start
--           sold.party_name                   sold_location_name,            -- 売上拠点名
           inlv.sold_location_name           sold_location_name,            -- 売上拠点名
-- Modify 2009.09.29 Ver1.5 End
           inlv.ship_shop_code               ship_shop_code,                -- 納品先店舗コード
           inlv.ship_shop_name               ship_shop_name,                -- 納品先店名
           inlv.vd_num                       vd_num,                        -- 自動販売機番号
           inlv.vd_cust_type                 vd_cust_type,                  -- VD顧客区分
           inlv.inv_type                     inv_type,                      -- 請求区分
           inlv.chain_shop_code              chain_shop_code,               -- チェーン店コード
           inlv.delivery_date                delivery_date,                 -- 納品日
           inlv.slip_num                     slip_num,                      -- 伝票番号
           inlv.order_num                    order_num,                     -- オーダーNO
           inlv.column_num                   column_num,                    -- コラムNo
           inlv.slip_type                    slip_type,                     -- 伝票区分
           inlv.classify_type                classify_type,                 -- 分類区分
           inlv.customer_dept_code           customer_dept_code,            -- お客様部門コード
           inlv.customer_division_code       customer_division_code,        -- お客様課コード
           inlv.sold_return_type             sold_return_type,              -- 売上返品区分
           inlv.nichiriu_by_way_type         nichiriu_by_way_type,          -- ニチリウ経由区分
           inlv.sale_type                    sale_type,                     -- 特売区分
           inlv.direct_num                   direct_num,                    -- 便No
           inlv.po_date                      po_date,                       -- 発注日
           inlv.acceptance_date              acceptance_date,               -- 検収日
           inlv.item_code                    item_code,                     -- 商品CD
           inlv.item_name                    item_name,                     -- 商品名
           inlv.item_kana_name               item_kana_name,                -- 商品カナ名
           inlv.policy_group                 policy_group,                  -- 政策群コード
           inlv.jan_code                     jan_code,                      -- JANコード
           inlv.vessel_type                  vessel_type,                   -- 容器区分
           inlv.vessel_type_name             vessel_type_name,              -- 容器区分名
           inlv.vessel_group                 vessel_group,                  -- 容器群
           inlv.vessel_group_name            vessel_group_name,             -- 容器群名
           inlv.quantity                     quantity,                      -- 数量
           inlv.unit_price                   unit_price,                    -- 単価
           inlv.dlv_qty                      dlv_qty,                       -- 納品数量
           inlv.dlv_unit_price               dlv_unit_price,                -- 納品単価
           inlv.dlv_uom_code                 dlv_uom_code,                  -- 納品単位
           inlv.standard_uom_code            standard_uom_code,             -- 基準単位
           inlv.standard_unit_price_excluded standard_unit_price_excluded,  -- 税抜基準単価
           inlv.business_cost                business_cost,                 -- 営業原価
           inlv.tax_amount                   tax_amount,                    -- 消費税金額
           inlv.tax_rate                     tax_rate,                      -- 消費税率
           inlv.ship_amount                  ship_amount,                   -- 納品金額
           inlv.sold_amount                  sold_amount,                   -- 売上金額
           inlv.red_black_slip_type          red_black_slip_type,           -- 赤伝黒伝区分
           inlv.trx_id                       trx_id,                        -- 取引ID
           inlv.trx_number                   trx_number,                    -- 取引番号
           inlv.cust_trx_type_id             cust_trx_type_id,              -- 取引タイプID
           inlv.batch_source_id              batch_source_id,               -- 取引ソースID
           inlv.created_by                   created_by,                    -- 作成者
           inlv.creation_date                creation_date,                 -- 作成日
           inlv.last_updated_by              last_updated_by,               -- 最終更新者
           inlv.last_update_date             last_update_date,              -- 最終更新日
           inlv.last_update_login            last_update_login ,            -- 最終更新ログイン
           inlv.request_id                   request_id,                    -- 要求ID
           inlv.program_application_id       program_application_id,        -- アプリケーションID
           inlv.program_id                   program_id,                    -- プログラムID
-- Modify 2009.09.29 Ver1.5 Start
--           inlv.program_update_date          program_update_date            -- プログラム更新日
           inlv.program_update_date          program_update_date,           -- プログラム更新日
           inlv.cutoff_date                  cutoff_date,                   -- 締日
           inlv.num_of_cases                 num_of_cases,                  -- ケース入数
-- Modify 2009.11.02 Ver1.6 Start
--           inlv.medium_class                 medium_class                   -- 受注ソース
           inlv.medium_class                 medium_class,                  -- 受注ソース
           inlv.delivery_chain_code          delivery_chain_code            -- 納品先チェーンコード
-- Modify 2009.11.02 Ver1.6 End
-- Modify 2009.09.29 Ver1.5 End
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD START
          ,inlv.bms_header_data              bms_header_data                -- 流通ＢＭＳヘッダデータ
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD END
-- Add 2019.07.26 Ver1.160 START
          ,inlv.tax_code                     tax_code                       -- 税金コード
-- Add 2019.07.26 Ver1.160 END
-- Ver1.190 Add Start
          ,NULL                              tax_gap_amount                 -- 税差額
          ,NULL                              tax_amount_sum                 -- 税額合計１
          ,NULL                              tax_amount_sum2                -- 税額合計２
          ,NULL                              category                       -- 内訳分類
          ,NULL                              inv_gap_amount                 -- 本体差額
          ,NULL                              inv_amount_sum                 -- 税抜合計１
          ,NULL                              inv_amount_sum2                -- 税抜合計２
          ,NULL                              invoice_printing_unit          -- 請求書印刷単位
          ,NULL                              customer_for_sum               -- 顧客(集計用)
-- Ver1.200 Add Start
          ,NULL                              invoice_id_bef                 -- 一括請求書ID(最新請求先適用前)
          ,NULL                              invoice_detail_num_bef         -- 一括請求書明細No(最新請求先適用前)
-- Ver1.200 Add End
-- Ver1.190 Add End
    FROM   (--請求明細データ(AR部門入力) 
            SELECT /*+ FIRST_ROWS
-- Modify 2009.09.29 Ver1.5 Start
--                       LEADING(xih)
                       LEADING(xih rcta hzca hp_ship xxca hc_sold hp_sold hzsa rlli rlta rgda arta fnvd)
-- Modify 2009.09.29 Ver1.5 End
                       INDEX(xih  XXCFR_INVOICE_HEADERS_N02)
                       INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
                       INDEX(hzca HZ_CUST_ACCOUNTS_U1)
                       INDEX(xxca XXCMM_CUST_ACCOUNTS_PK)
-- Modify 2009.09.29 Ver1.5 Start
                       INDEX(hp_ship HZ_PARTIES_U1)
                       INDEX(hc_sold HZ_CUST_ACCOUNTS_U2)
                       INDEX(hp_sold HZ_PARTIES_U1)
-- Modify 2009.09.29 Ver1.5 End
                       INDEX(hzsa HZ_CUST_ACCT_SITES_N2)
                       INDEX(rlli RA_CUSTOMER_TRX_LINES_N2)
                       INDEX(rlta RA_CUSTOMER_TRX_LINES_N3)
                       INDEX(rgda RA_CUST_TRX_LINE_GL_DIST_N6)
                       INDEX(arta AR_VAT_TAX_ALL_B_U1)
                       INDEX(fnvd FND_LOOKUP_VALUES_U1)
                   */
                   xih.invoice_id                                 invoice_id,             -- 一括請求書ID
                   NULL                                           note_line_id,           -- 伝票明細No
                   hzca.account_number                            ship_cust_code,         -- 納品先顧客コード
-- Modify 2009.09.29 Ver1.5 Start
--                   hzca.party_id                                  ship_party_id,
                   hp_ship.party_name                             ship_cust_name,      -- 納品先顧客名
                   hp_ship.organization_name_phonetic             ship_cust_kana_name, -- 納品先顧客カナ名
-- Modify 2009.09.29 Ver1.5 End
                   xxca.sale_base_code                            sold_location_code,     -- 売上拠点コード
-- Modify 2009.09.29 Ver1.5 Start
                   hp_sold.party_name                             sold_location_name,     -- 売上拠点名
-- Modify 2009.09.29 Ver1.5 End
                   xxca.store_code                                ship_shop_code,         -- 納品先店舗コード
                   xxca.cust_store_name                           ship_shop_name,         -- 納品先店名
                   xxca.vendor_machine_number                     vd_num,                 -- 自動販売機番号
                   NVL(fnvd.attribute1, '0')                      vd_cust_type,           -- VD顧客区分
                   DECODE(rcta.attribute7,
                            cv_inv_hold_status_r, cv_inv_type_re
                                                , cv_inv_type_no) inv_type,               -- 請求区分
                   xxca.chain_store_code                          chain_shop_code,        -- チェーン店コード
                   rgda.gl_date                                   delivery_date,          -- 納品日
                   rlli.interface_line_attribute3                 slip_num,               -- 伝票番号
                   NULL                                           order_num,              -- オーダーNO
                   NULL                                           column_num,             -- コラムNo
                   NULL                                           slip_type,              -- 伝票区分
                   NULL                                           classify_type,          -- 分類区分
                   NULL                                           customer_dept_code,     -- お客様部門コード
                   NULL                                           customer_division_code, -- お客様課コード
-- Modify 2010.01.04 Ver1.9 Start
--                   NULL                                           sold_return_type,       -- 売上返品区分
                   cv_sold_return_type_ar                         sold_return_type,       -- 売上返品区分
-- Modify 2010.01.04 Ver1.9 End
                   NULL                                           nichiriu_by_way_type,   -- ニチリウ経由区分
                   NULL                                           sale_type,              -- 特売区分
                   NULL                                           direct_num,             -- 便No
                   NULL                                           po_date,                -- 発注日
                   rcta.trx_date                                  acceptance_date,        -- 検収日
                   NULL                                           item_code,              -- 商品CD
                   NULL                                           item_name,              -- 商品名
                   NULL                                           item_kana_name,         -- 商品カナ名
                   NULL                                           policy_group,           -- 政策群コード
                   NULL                                           jan_code,               -- JANコード
                   NULL                                           vessel_type,            -- 容器区分
                   NULL                                           vessel_type_name,       -- 容器区分名
                   NULL                                           vessel_group,           -- 容器群
                   NULL                                           vessel_group_name,      -- 容器群名
                   rlli.quantity_invoiced                         quantity,               -- 数量
                   rlli.unit_selling_price                        unit_price,             -- 単価
                   rlli.quantity_invoiced                         dlv_qty,                      -- 納品数量
                   rlli.unit_selling_price                        dlv_unit_price,               -- 納品単価
                   NULL                                           dlv_uom_code,                 -- 納品単位
                   NULL                                           standard_uom_code,            -- 基準単位
                   NULL                                           standard_unit_price_excluded, -- 税抜基準単価
                   NULL                                           business_cost,                -- 営業原価
                   rlta.extended_amount                           tax_amount,             -- 消費税金額
                   arta.tax_rate                                  tax_rate,               -- 消費税率
                   rlli.extended_amount                           ship_amount,            -- 納品金額
                   DECODE(xih.tax_type,
                            cv_tax_div_outtax,   rlli.extended_amount,    -- 外税　：税抜額
                            cv_tax_div_notax,    rlli.extended_amount,    -- 非課税：税抜額
                            cv_tax_div_inslip,   rlli.extended_amount,    -- 内税(伝票)：税抜額
                            rlli.extended_amount + rlta.extended_amount)  -- 内税(単価)：税込額
                                                                  sold_amount,            -- 売上金額
                   NULL                                           red_black_slip_type,    -- 赤伝黒伝区分
                   rcta.customer_trx_id                           trx_id,                 -- 取引ID
                   rcta.trx_number                                trx_number,             -- 取引番号
                   rcta.cust_trx_type_id                          cust_trx_type_id,       -- 取引タイプID
                   rcta.batch_source_id                           batch_source_id,        -- 取引ソースID
                   cn_created_by                                  created_by,             -- 作成者
                   cd_creation_date                               creation_date,          -- 作成日
                   cn_last_updated_by                             last_updated_by,        -- 最終更新者
                   cd_last_update_date                            last_update_date,       -- 最終更新日
                   cn_last_update_login                           last_update_login ,     -- 最終更新ログイン
                   cn_request_id                                  request_id,             -- 要求ID
                   cn_program_application_id                      program_application_id, -- アプリケーションID
                   cn_program_id                                  program_id,             -- プログラムID
-- Modify 2009.09.29 Ver1.5 Start
--                   cd_program_update_date                         program_update_date     -- プログラム更新日
                   cd_program_update_date                         program_update_date,    -- プログラム更新日
                   xih.cutoff_date                                cutoff_date,            -- 締日
                   NULL                                           num_of_cases,           -- ケース入数
-- Modify 2009.11.02 Ver1.6 Start
--                   NULL                                           medium_class            -- 受注ソース
                   NULL                                           medium_class,           -- 受注ソース
                   xxca.delivery_chain_code                       delivery_chain_code     -- 納品先チェーンコード
-- Modify 2009.11.02 Ver1.6 End
-- Modify 2009.09.29 Ver1.5 End
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD START
                  ,NULL                                           bms_header_data         -- 流通ＢＭＳヘッダデータ
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD END
-- Add 2019.07.26 Ver1.160 START
                  ,arta.tax_code                                  tax_code                -- 税金コード
-- Add 2019.07.26 Ver1.160 END
            FROM   
                   xxcfr_invoice_headers         xih,               -- アドオン請求書ヘッダ
                   ra_customer_trx               rcta,              -- 取引テーブル
-- Modify 2009.09.29 Ver1.5 Start
                   hz_parties                    hp_sold,           -- パーティー(売上拠点)
                   hz_cust_accounts              hc_sold,           -- 顧客マスタ(売上拠点)
                   hz_parties                    hp_ship,           -- パーティー(納入先)
-- Modify 2009.09.29 Ver1.5 End
                   hz_cust_accounts              hzca,              -- 顧客マスタ
                   xxcmm_cust_accounts           xxca,              -- 顧客追加情報
                   hz_cust_acct_sites            hzsa,              -- 顧客所在地
                   ra_customer_trx_lines         rlli,              -- 取引明細(明細)テーブル
                   ra_customer_trx_lines         rlta,              -- 取引明細(税額)テーブル
                   ra_cust_trx_line_gl_dist      rgda,              -- 取引会計情報テーブル
                   ar_vat_tax_all_b              arta,              -- 税金マスタ
                   fnd_lookup_values             fnvd               -- クイックコード(VD顧客区分)
            WHERE  xih.request_id            = gt_target_request_id       -- ターゲットとなる要求ID
-- Modify 2012.11.06 Ver1.120 Start
            AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- 夜間手動判断区分が'2'(夜間)
            AND     ( xih.parallel_type       = gn_parallel_type ) )  -- パラレル実行区分が一致
            OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- 夜間手動判断区分が'0'(手動)
            AND     ( xih.parallel_type      IS NULL ) ) )            -- パラレル実行区分がNULL
-- Modify 2012.11.06 Ver1.120 End
            AND    rcta.trx_date            <= xih.cutoff_date            -- 取引日
            AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- 請求先顧客ID
            AND    xih.org_id                = gn_org_id                      -- 組織ID
            AND    xih.set_of_books_id       = gn_set_book_id        -- 会計帳簿ID
            AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                       cv_inv_hold_status_r)        -- 請求書保留ステータス
            AND    rcta.set_of_books_id = gn_set_book_id            -- 会計帳簿ID
            AND    rcta.batch_source_id = gt_arinput_trx_source_id  -- 取引ソース
            AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
-- Modify 2009.09.29 Ver1.5 Start
            AND    xxca.sale_base_code  = hc_sold.account_number(+)  -- 売上拠点コード
            AND    hc_sold.party_id     = hp_sold.party_id(+)        -- パーティーID
            AND    hzca.party_id        = hp_ship.party_id           -- パーティーID
-- Modify 2009.09.29 Ver1.5 End
            AND    rcta.ship_to_customer_id = xxca.customer_id(+)
            AND    hzca.cust_account_id = hzsa.cust_account_id(+)
            AND    rcta.customer_trx_id = rlli.customer_trx_id
            AND    rlli.customer_trx_id = rlta.customer_trx_id(+)
            AND    rlli.customer_trx_line_id = rlta.link_to_cust_trx_line_id(+)
            AND    rlli.line_type = cv_line_type_line
            AND    rlta.line_type(+) = cv_line_type_tax
            AND    rcta.customer_trx_id = rgda.customer_trx_id
            AND    rgda.account_class = cv_account_class_rec
            AND    rlta.vat_tax_id = arta.vat_tax_id
            AND    fnvd.lookup_type(+)  = cv_lookup_vd_class_type    -- 参照タイプ(汎用請求VD対象小分類)
            AND    fnvd.language(+)     = USERENV( 'LANG' )
            AND    fnvd.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fnvd.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fnvd.end_date_active(+),   gd_process_date ) )
            AND    xxca.business_low_type = fnvd.lookup_code(+)
              UNION ALL
            --請求明細データ(販売実績) 
            SELECT /*+ FIRST_ROWS
-- Modify 2009.12.02 Ver1.8 Start
-- Modify 2009.09.29 Ver1.5 Start
--                       LEADING(xih)
--                       LEADING(xih rcta hzca hp_ship xxca hc_sold hp_sold hzsa rlli xxeh xedh fdsc)
                       LEADING(xih rcta rlli xxeh hzca xxca hzsa xedh fdsc hp_ship hc_sold hp_sold)
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2009.12.02 Ver1.8 End
                       INDEX(xih  XXCFR_INVOICE_HEADERS_N02)
                       INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
-- Modify 2009.12.02 Ver1.8 Start
--                       INDEX(hzca HZ_CUST_ACCOUNTS_U1)
--                       INDEX(xxca XXCMM_CUST_ACCOUNTS_PK)
                       INDEX(hzca HZ_CUST_ACCOUNTS_U2)
                       INDEX(xxca XXCMM_CUST_ACCOUNTS_N06)
-- Modify 2009.12.02 Ver1.8 End
-- Modify 2009.09.29 Ver1.5 Start
                       INDEX(hp_ship HZ_PARTIES_U1)
                       INDEX(hc_sold HZ_CUST_ACCOUNTS_U2)
                       INDEX(hp_sold HZ_PARTIES_U1)
-- Modify 2009.09.29 Ver1.5 End
                       INDEX(hzsa HZ_CUST_ACCT_SITES_N2)
                       INDEX(rlli RA_CUSTOMER_TRX_LINES_N2)
                       INDEX(arta AR_VAT_TAX_ALL_B_U1)
                       INDEX(xxeh XXCOS_SALES_EXP_HEADERS_PK)
                       INDEX(xxel XXCOS_SALES_EXP_LINES_N01)
                       INDEX(xedh XXCOS_EDI_HEADERS_N03)
                       INDEX(mtib MTL_SYSTEM_ITEMS_B_N1)
                       INDEX(xxib XXCMN_IMB_N02)
-- Modify 2009.12.02 Ver1.8 Start
                       USE_NL(hzca xxca)
-- Modify 2009.12.02 Ver1.8 End
                   */
                   xih.invoice_id                                  invoice_id,             -- 一括請求書ID
                   xxel.dlv_invoice_line_number                    note_line_id,            -- 伝票明細No
-- Modify 2009.12.02 Ver1.8 Start
--                   hzca.account_number                             ship_cust_code,          -- 納品先顧客コード
                   xxeh.ship_to_customer_code                     ship_cust_code,         -- 納品先顧客コード
-- Modify 2009.12.02 Ver1.8 End
-- Modify 2009.09.29 Ver1.5 Start
--                   hzca.party_id                                   ship_party_id,
                   hp_ship.party_name                              ship_cust_name,          -- 納品先顧客名
                   hp_ship.organization_name_phonetic              ship_cust_kana_name,     -- 納品先顧客カナ名
-- Modify 2009.09.29 Ver1.5 End
                   xxca.sale_base_code                             sold_location_code,      -- 売上拠点コード
-- Modify 2009.09.29 Ver1.5 Start
                   hp_sold.party_name                              sold_location_name,      -- 売上拠点名
-- Modify 2009.09.29 Ver1.5 End
                   xxca.store_code                                 ship_shop_code,          -- 納品先店舗コード
                   xxca.cust_store_name                            ship_shop_name,          -- 納品先店名
                   xxca.vendor_machine_number                      vd_num,                  -- 自動販売機番号
                   NVL(fvdt.attribute1, '0')                       vd_cust_type,            -- VD顧客区分
                   DECODE(rcta.attribute7,
                            cv_inv_hold_status_r, cv_inv_type_re
                                                , cv_inv_type_no)  inv_type,                -- 請求区分
                   xxca.chain_store_code                           chain_shop_code,         -- チェーン店コード
                   xxeh.delivery_date                              delivery_date,           -- 納品日
                   xxeh.dlv_invoice_number                         slip_num,                -- 伝票番号
                   xxeh.order_invoice_number                       order_num,               -- オーダーNO
                   xxel.column_no                                  column_num,              -- コラムNo
                   xxeh.invoice_class                              slip_type,               -- 伝票区分
                   xxeh.invoice_classification_code                classify_type,           -- 分類区分
                   xedh.other_party_department_code                customer_dept_code,      -- お客様部門コード
                   xedh.delivery_to_section_code                   customer_division_code,  -- お客様課コード
                   fdsc.attribute1                                 sold_return_type,        -- 売上返品区分
                   NULL                                            nichiriu_by_way_type,    -- ニチリウ経由区分
                   fscl.attribute8                                 sale_type,               -- 特売区分
                   xedh.opportunity_no                             direct_num,              -- 便No
                   xedh.order_date                                 po_date,                 -- 発注日
                   rcta.trx_date                                   acceptance_date,         -- 検収日
                   xxel.item_code                                  item_code,               -- 商品CD
                   mtib.description                                item_name,               -- 商品名
                   xxmb.item_name_alt                              item_kana_name,          -- 商品カナ名
                   icmb.attribute2                                 policy_group,            -- 政策群コード
                   icmb.attribute21                                jan_code,                -- JANコード
                   fnlv.attribute1                                 vessel_type,             -- 容器区分
                   fykn.meaning                                    vessel_type_name,        -- 容器区分名
                   xxib.vessel_group                               vessel_group,            -- 容器群
                   fnlv.meaning                                    vessel_group_name,       -- 容器群名
                   xxel.standard_qty                               quantity,                -- 数量(基準数量)
                   xxel.standard_unit_price                        unit_price,              -- 単価(基準単価)
                   xxel.dlv_qty                                    dlv_qty,                 -- 納品数量
                   xxel.dlv_unit_price                             dlv_unit_price,               -- 納品単価
                   xxel.dlv_uom_code                               dlv_uom_code,                 -- 納品単位
                   xxel.standard_uom_code                          standard_uom_code,            -- 基準単位
                   xxel.standard_unit_price_excluded               standard_unit_price_excluded, -- 税抜基準単価
                   xxel.business_cost                              business_cost,                -- 営業原価
                   xxel.tax_amount                                 tax_amount,              -- 消費税金額
-- Modify 2019.07.26 Ver1.160 Start
--                   xxeh.tax_rate                                   tax_rate,                -- 消費税率
-- Modify Ver1.170 Start
--                   xxel.tax_rate                                   tax_rate,                -- 消費税率
                   NVL(xxel.tax_rate,xxeh.tax_rate)                tax_rate,                -- 消費税率
-- Modify Ver1.170 End
-- Modify 2019.07.26 Ver1.160 End
                   xxel.pure_amount                                ship_amount,             -- 納品金額
                   xxel.sale_amount                                sold_amount,             -- 売上金額
                   NULL                                            red_black_slip_type,     -- 赤伝黒伝区分
                   rcta.customer_trx_id                            trx_id,                  -- 取引ID
                   rcta.trx_number                                 trx_number,              -- 取引番号
                   rcta.cust_trx_type_id                           cust_trx_type_id,        -- 取引タイプID
                   rcta.batch_source_id                            batch_source_id,         -- 取引ソースID
                   cn_created_by                                   created_by,              -- 作成者
                   cd_creation_date                                creation_date,           -- 作成日
                   cn_last_updated_by                              last_updated_by,         -- 最終更新者
                   cd_last_update_date                             last_update_date,        -- 最終更新日
                   cn_last_update_login                            last_update_login ,      -- 最終更新ログイン
                   cn_request_id                                   request_id,              -- 要求ID
                   cn_program_application_id                       program_application_id,  -- アプリケーションID
                   cn_program_id                                   program_id,              -- プログラムID
-- Modify 2009.09.29 Ver1.5 Start
--                   cd_program_update_date                          program_update_date      -- プログラム更新日
                   cd_program_update_date                          program_update_date,     -- プログラム更新日
                   xih.cutoff_date                                 cutoff_date,             -- 締日
                   icmb.attribute11                                num_of_cases,            -- ケース入数
-- Modify 2009.11.02 Ver1.6 Start
--                   NVL( xedh.medium_class , cv_medium_class_mnl)   medium_class             -- 受注ソース
                   NVL( xedh.medium_class , cv_medium_class_mnl)   medium_class,            -- 受注ソース
                   xxca.delivery_chain_code                        delivery_chain_code      -- 納品先チェーンコード
-- Modify 2009.11.02 Ver1.6 End
-- Modify 2009.09.29 Ver1.5 End
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD START
                  ,xedh.bms_header_data                            bms_header_data          -- 流通ＢＭＳヘッダデータ
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD END
-- Add 2019.07.26 Ver1.160 START
-- Modify Ver1.170 Start
--                  ,xxel.tax_code                                   tax_code                 -- 税金コード
                  ,NVL(xxel.tax_code,xxeh.tax_code)                tax_code                 -- 税金コード
-- Modify Ver1.170 End
-- Add 2019.07.26 Ver1.160 END
            FROM   
                   xxcfr_invoice_headers         xih,            -- アドオン請求書ヘッダ
                   ra_customer_trx               rcta,           -- 取引テーブル
-- Modify 2009.09.29 Ver1.5 Start
                   hz_parties                    hp_sold,        -- パーティー(売上拠点)
                   hz_cust_accounts              hc_sold,        -- 顧客マスタ(売上拠点)
                   hz_parties                    hp_ship,        -- パーティー(納入先)
-- Modify 2009.09.29 Ver1.5 End
                   hz_cust_accounts              hzca,           -- 顧客マスタ
                   xxcmm_cust_accounts           xxca,           -- 顧客追加情報
                   hz_cust_acct_sites            hzsa,           -- 顧客所在地
                   ra_customer_trx_lines         rlli,           -- 取引明細テーブル
                   xxcos_sales_exp_headers       xxeh,           -- 販売実績ヘッダテーブル
                   xxcos_sales_exp_lines         xxel,           -- 販売実績明細テーブル
                   xxcos_edi_headers             xedh,           -- EDIヘッダ情報テーブル
                   mtl_system_items_b            mtib,           -- 品目マスタ
                   xxcmm_system_items_b          xxib,           -- Disc品目アドオン
                   fnd_lookup_values             fnlv,           -- クイックコード(容器群)
                   fnd_lookup_values             fykn,           -- クイックコード(容器区分)
                   fnd_lookup_values             fdsc,           -- クイックコード(納品伝票区分)
                   fnd_lookup_values             fscl,           -- クイックコード(売上区分)
                   fnd_lookup_values             fvdt,           -- クイックコード(VD顧客区分)
                   ic_item_mst_b                 icmb,           -- OPM品目マスタ
                   xxcmn_item_mst_b              xxmb            -- OPM品目アドオン
            WHERE  xih.request_id            = gt_target_request_id       -- ターゲットとなる要求ID
-- Modify 2012.11.06 Ver1.120 Start
            AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- 夜間手動判断区分が'2'(夜間)
            AND     ( xih.parallel_type       = gn_parallel_type ) )  -- パラレル実行区分が一致
            OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- 夜間手動判断区分が'0'(手動)
            AND     ( xih.parallel_type      IS NULL ) ) )            -- パラレル実行区分がNULL
-- Modify 2012.11.06 Ver1.120 End
            AND    rcta.trx_date            <= xih.cutoff_date            -- 取引日
            AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- 請求先顧客ID
            AND    xih.org_id                = gn_org_id                      -- 組織ID
            AND    xih.set_of_books_id       = gn_set_book_id        -- 会計帳簿ID
            AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                       cv_inv_hold_status_r)         -- 請求書保留ステータス
            AND    rcta.set_of_books_id = gn_set_book_id             -- 会計帳簿ID
            AND    rcta.batch_source_id != gt_arinput_trx_source_id  -- 取引ソース(AR部門入力以外)
-- Modify 2009.12.02 Ver1.8 Start
--            AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
            AND    xxeh.ship_to_customer_code = hzca.account_number
-- Modify 2009.12.02 Ver1.8 End
-- Modify 2009.09.29 Ver1.5 Start
            AND    xxca.sale_base_code  = hc_sold.account_number(+)  -- 売上拠点コード
            AND    hc_sold.party_id     = hp_sold.party_id(+)        -- パーティーID
            AND    hzca.party_id        = hp_ship.party_id           -- パーティーID
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2009.12.02 Ver1.8 Start
--            AND    rcta.ship_to_customer_id = xxca.customer_id(+)
--            AND    hzca.cust_account_id = hzsa.cust_account_id(+)
            AND    xxeh.ship_to_customer_code = xxca.customer_code
            AND    hzca.cust_account_id = hzsa.cust_account_id
-- Modify 2009.12.02 Ver1.8 End
            AND    rcta.customer_trx_id = rlli.customer_trx_id
            AND    rlli.line_type = cv_line_type_line
-- 2019/09/19 Ver1.180 ADD Start
            AND    rlli.customer_trx_line_id = (  SELECT MIN(rctla.customer_trx_line_id) customer_trx_line_id
                                                  FROM   ra_customer_trx_lines  rctla
                                                  WHERE  rctla.customer_trx_id           = rcta.customer_trx_id
                                                  AND    rctla.line_type                 = cv_line_type_line
                                                  AND    rctla.interface_line_attribute7 = rlli.interface_line_attribute7  )
-- 2019/09/19 Ver1.180 ADD End
            AND    rlli.interface_line_attribute7 = xxeh.sales_exp_header_id  -- 販売実績ヘッダ内部ID
            AND    xxeh.sales_exp_header_id = xxel.sales_exp_header_id
-- 2019/09/19 Ver1.180 ADD Start
            AND    xxel.goods_prod_cls IS NOT NULL
-- 2019/09/19 Ver1.180 ADD End
-- Add 2010.10.19 Ver1.100 Start
-- 2019/09/19 Ver1.180 DEL Start
--            AND   ((rlli.interface_line_attribute8 IS NULL)
--               OR  (rlli.interface_line_attribute8 = xxel.goods_prod_cls))    -- 品目区分
-- 2019/09/19 Ver1.180 DEL End
-- Add 2010.10.19 Ver1.100 End
            AND    xxeh.order_connection_number = xedh.order_connection_number(+)
            AND    xxel.item_code = mtib.segment1(+)
            AND    mtib.organization_id(+) = gt_mtl_organization_id  -- 品目マスタ組織ID
            AND    fdsc.lookup_type(+)  = cv_lookup_slip_class    -- 参照タイプ(納品伝票区分)
            AND    fdsc.language(+)     = USERENV( 'LANG' )
            AND    fdsc.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fdsc.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fdsc.end_date_active(+),   gd_process_date ) )
            AND    xxeh.dlv_invoice_class = fdsc.lookup_code(+)
            AND    fscl.lookup_type(+)  = cv_lookup_sale_class    -- 参照タイプ(売上区分)
            AND    fscl.language(+)     = USERENV( 'LANG' )
            AND    fscl.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fscl.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fscl.end_date_active(+),   gd_process_date ) )
            AND    xxel.sales_class = fscl.lookup_code(+)
            AND    mtib.segment1 = icmb.item_no(+)
            AND    icmb.item_id  = xxmb.item_id(+)
-- Del 2016.03.02 Ver1.150 Start
--            AND    xxmb.active_flag(+) = 'Y'
-- Del 2016.03.02 Ver1.150 End
            AND    xih.cutoff_date >= NVL(TRUNC(xxmb.start_date_active), xih.cutoff_date)
            AND    xih.cutoff_date <= NVL(xxmb.end_date_active, xih.cutoff_date)
            AND    icmb.item_id = xxib.item_id(+)
            AND    fnlv.lookup_type(+)  = cv_lookup_itm_yokigun   -- 参照タイプ(容器群)
            AND    fnlv.language(+)     = USERENV( 'LANG' )
            AND    fnlv.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
            AND    xxib.vessel_group = fnlv.lookup_code(+)
            AND    fykn.lookup_type(+)  = cv_lookup_itm_yokikubun   -- 参照タイプ(容器区分)
            AND    fykn.language(+)     = USERENV( 'LANG' )
            AND    fykn.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fykn.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fykn.end_date_active(+),   gd_process_date ) )
            AND    fnlv.attribute1 = fykn.lookup_code(+)
            AND    fvdt.lookup_type(+)  = cv_lookup_vd_class_type    -- 参照タイプ(汎用請求VD対象小分類)
            AND    fvdt.language(+)     = USERENV( 'LANG' )
            AND    fvdt.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fvdt.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fvdt.end_date_active(+),   gd_process_date ) )
            AND    xxca.business_low_type = fvdt.lookup_code(+)
-- Modify 2009.09.29 Ver1.5 Start
--          )                inlv,
--          hz_parties       ship,   -- パーティー(納品先)
--          hz_parties       sold,   -- パーティー(売上拠点)
--          hz_cust_accounts soldca  -- 顧客マスタ
--    WHERE inlv.ship_party_id      = ship.party_id
--      AND inlv.sold_location_code = soldca.account_number
--      AND soldca.party_id         = sold.party_id
          )                inlv
-- Modify 2009.09.29 Ver1.5 End
    ;
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2013.01.17 Ver1.130 Start
    --手動実行用
    CURSOR main_data_manual_cur 
    IS
    SELECT inlv.invoice_id                   invoice_id,                    -- 一括請求書ID
           TO_NUMBER(TO_CHAR(SYSDATE, 'yyyymmddhh24miss') || TO_CHAR(ROWNUM))  invoice_detail_num,  -- 一括請求書明細No
           inlv.note_line_id                 note_line_id,                  -- 伝票明細No
           inlv.ship_cust_code               ship_cust_code,                -- 納品先顧客コード
           inlv.ship_cust_name               ship_cust_name,                -- 納品先顧客名
           inlv.ship_cust_kana_name          ship_cust_kana_name,           -- 納品先顧客カナ名
           inlv.sold_location_code           sold_location_code,            -- 売上拠点コード
           inlv.sold_location_name           sold_location_name,            -- 売上拠点名
           inlv.ship_shop_code               ship_shop_code,                -- 納品先店舗コード
           inlv.ship_shop_name               ship_shop_name,                -- 納品先店名
           inlv.vd_num                       vd_num,                        -- 自動販売機番号
           inlv.vd_cust_type                 vd_cust_type,                  -- VD顧客区分
           inlv.inv_type                     inv_type,                      -- 請求区分
           inlv.chain_shop_code              chain_shop_code,               -- チェーン店コード
           inlv.delivery_date                delivery_date,                 -- 納品日
           inlv.slip_num                     slip_num,                      -- 伝票番号
           inlv.order_num                    order_num,                     -- オーダーNO
           inlv.column_num                   column_num,                    -- コラムNo
           inlv.slip_type                    slip_type,                     -- 伝票区分
           inlv.classify_type                classify_type,                 -- 分類区分
           inlv.customer_dept_code           customer_dept_code,            -- お客様部門コード
           inlv.customer_division_code       customer_division_code,        -- お客様課コード
           inlv.sold_return_type             sold_return_type,              -- 売上返品区分
           inlv.nichiriu_by_way_type         nichiriu_by_way_type,          -- ニチリウ経由区分
           inlv.sale_type                    sale_type,                     -- 特売区分
           inlv.direct_num                   direct_num,                    -- 便No
           inlv.po_date                      po_date,                       -- 発注日
           inlv.acceptance_date              acceptance_date,               -- 検収日
           inlv.item_code                    item_code,                     -- 商品CD
           inlv.item_name                    item_name,                     -- 商品名
           inlv.item_kana_name               item_kana_name,                -- 商品カナ名
           inlv.policy_group                 policy_group,                  -- 政策群コード
           inlv.jan_code                     jan_code,                      -- JANコード
           inlv.vessel_type                  vessel_type,                   -- 容器区分
           inlv.vessel_type_name             vessel_type_name,              -- 容器区分名
           inlv.vessel_group                 vessel_group,                  -- 容器群
           inlv.vessel_group_name            vessel_group_name,             -- 容器群名
           inlv.quantity                     quantity,                      -- 数量
           inlv.unit_price                   unit_price,                    -- 単価
           inlv.dlv_qty                      dlv_qty,                       -- 納品数量
           inlv.dlv_unit_price               dlv_unit_price,                -- 納品単価
           inlv.dlv_uom_code                 dlv_uom_code,                  -- 納品単位
           inlv.standard_uom_code            standard_uom_code,             -- 基準単位
           inlv.standard_unit_price_excluded standard_unit_price_excluded,  -- 税抜基準単価
           inlv.business_cost                business_cost,                 -- 営業原価
           inlv.tax_amount                   tax_amount,                    -- 消費税金額
           inlv.tax_rate                     tax_rate,                      -- 消費税率
           inlv.ship_amount                  ship_amount,                   -- 納品金額
           inlv.sold_amount                  sold_amount,                   -- 売上金額
           inlv.red_black_slip_type          red_black_slip_type,           -- 赤伝黒伝区分
           inlv.trx_id                       trx_id,                        -- 取引ID
           inlv.trx_number                   trx_number,                    -- 取引番号
           inlv.cust_trx_type_id             cust_trx_type_id,              -- 取引タイプID
           inlv.batch_source_id              batch_source_id,               -- 取引ソースID
           inlv.created_by                   created_by,                    -- 作成者
           inlv.creation_date                creation_date,                 -- 作成日
           inlv.last_updated_by              last_updated_by,               -- 最終更新者
           inlv.last_update_date             last_update_date,              -- 最終更新日
           inlv.last_update_login            last_update_login ,            -- 最終更新ログイン
           inlv.request_id                   request_id,                    -- 要求ID
           inlv.program_application_id       program_application_id,        -- アプリケーションID
           inlv.program_id                   program_id,                    -- プログラムID
           inlv.program_update_date          program_update_date,           -- プログラム更新日
           inlv.cutoff_date                  cutoff_date,                   -- 締日
           inlv.num_of_cases                 num_of_cases,                  -- ケース入数
           inlv.medium_class                 medium_class,                  -- 受注ソース
           inlv.delivery_chain_code          delivery_chain_code            -- 納品先チェーンコード
          ,inlv.bms_header_data              bms_header_data                -- 流通ＢＭＳヘッダデータ
-- Add 2019.07.26 Ver1.160 START
          ,inlv.tax_code                     tax_code                       -- 税金コード
-- Add 2019.07.26 Ver1.160 END
-- Ver1.190 Add Start
          ,NULL                              tax_gap_amount                 -- 税差額
          ,NULL                              tax_amount_sum                 -- 税額合計１
          ,NULL                              tax_amount_sum2                -- 税額合計２
          ,NULL                              category                       -- 内訳分類
          ,NULL                              inv_gap_amount                 -- 本体差額
          ,NULL                              inv_amount_sum                 -- 税抜合計１
          ,NULL                              inv_amount_sum2                -- 税抜合計２
          ,NULL                              invoice_printing_unit          -- 請求書印刷単位
          ,NULL                              customer_for_sum               -- 顧客(集計用)
-- Ver1.200 Add Start
          ,NULL                              invoice_id_bef                 -- 一括請求書ID(最新請求先適用前)
          ,NULL                              invoice_detail_num_bef         -- 一括請求書明細No(最新請求先適用前)
-- Ver1.200 Add End
-- Ver1.190 Add End
    FROM   (--請求明細データ(AR部門入力) 
            SELECT /*+ FIRST_ROWS
                       LEADING(xih rcta hzca hp_ship xxca hc_sold hp_sold hzsa rlli rlta rgda arta fnvd)
                       INDEX(xih  XXCFR_INVOICE_HEADERS_N02)
                       INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
                       INDEX(hzca HZ_CUST_ACCOUNTS_U1)
                       INDEX(xxca XXCMM_CUST_ACCOUNTS_PK)
                       INDEX(hp_ship HZ_PARTIES_U1)
                       INDEX(hc_sold HZ_CUST_ACCOUNTS_U2)
                       INDEX(hp_sold HZ_PARTIES_U1)
                       INDEX(hzsa HZ_CUST_ACCT_SITES_N2)
                       INDEX(rlli RA_CUSTOMER_TRX_LINES_N2)
                       INDEX(rlta RA_CUSTOMER_TRX_LINES_N3)
                       INDEX(rgda RA_CUST_TRX_LINE_GL_DIST_N6)
                       INDEX(arta AR_VAT_TAX_ALL_B_U1)
                       INDEX(fnvd FND_LOOKUP_VALUES_U1)
                   */
                   xih.invoice_id                                 invoice_id,             -- 一括請求書ID
                   NULL                                           note_line_id,           -- 伝票明細No
                   hzca.account_number                            ship_cust_code,         -- 納品先顧客コード
                   hp_ship.party_name                             ship_cust_name,      -- 納品先顧客名
                   hp_ship.organization_name_phonetic             ship_cust_kana_name, -- 納品先顧客カナ名
                   xxca.sale_base_code                            sold_location_code,     -- 売上拠点コード
                   hp_sold.party_name                             sold_location_name,     -- 売上拠点名
                   xxca.store_code                                ship_shop_code,         -- 納品先店舗コード
                   xxca.cust_store_name                           ship_shop_name,         -- 納品先店名
                   xxca.vendor_machine_number                     vd_num,                 -- 自動販売機番号
                   NVL(fnvd.attribute1, '0')                      vd_cust_type,           -- VD顧客区分
                   DECODE(rcta.attribute7,
                            cv_inv_hold_status_r, cv_inv_type_re
                                                , cv_inv_type_no) inv_type,               -- 請求区分
                   xxca.chain_store_code                          chain_shop_code,        -- チェーン店コード
                   rgda.gl_date                                   delivery_date,          -- 納品日
                   rlli.interface_line_attribute3                 slip_num,               -- 伝票番号
                   NULL                                           order_num,              -- オーダーNO
                   NULL                                           column_num,             -- コラムNo
                   NULL                                           slip_type,              -- 伝票区分
                   NULL                                           classify_type,          -- 分類区分
                   NULL                                           customer_dept_code,     -- お客様部門コード
                   NULL                                           customer_division_code, -- お客様課コード
                   cv_sold_return_type_ar                         sold_return_type,       -- 売上返品区分
                   NULL                                           nichiriu_by_way_type,   -- ニチリウ経由区分
                   NULL                                           sale_type,              -- 特売区分
                   NULL                                           direct_num,             -- 便No
                   NULL                                           po_date,                -- 発注日
                   rcta.trx_date                                  acceptance_date,        -- 検収日
                   NULL                                           item_code,              -- 商品CD
                   NULL                                           item_name,              -- 商品名
                   NULL                                           item_kana_name,         -- 商品カナ名
                   NULL                                           policy_group,           -- 政策群コード
                   NULL                                           jan_code,               -- JANコード
                   NULL                                           vessel_type,            -- 容器区分
                   NULL                                           vessel_type_name,       -- 容器区分名
                   NULL                                           vessel_group,           -- 容器群
                   NULL                                           vessel_group_name,      -- 容器群名
                   rlli.quantity_invoiced                         quantity,               -- 数量
                   rlli.unit_selling_price                        unit_price,             -- 単価
                   rlli.quantity_invoiced                         dlv_qty,                      -- 納品数量
                   rlli.unit_selling_price                        dlv_unit_price,               -- 納品単価
                   NULL                                           dlv_uom_code,                 -- 納品単位
                   NULL                                           standard_uom_code,            -- 基準単位
                   NULL                                           standard_unit_price_excluded, -- 税抜基準単価
                   NULL                                           business_cost,                -- 営業原価
                   rlta.extended_amount                           tax_amount,             -- 消費税金額
                   arta.tax_rate                                  tax_rate,               -- 消費税率
                   rlli.extended_amount                           ship_amount,            -- 納品金額
                   DECODE(xih.tax_type,
                            cv_tax_div_outtax,   rlli.extended_amount,    -- 外税　：税抜額
                            cv_tax_div_notax,    rlli.extended_amount,    -- 非課税：税抜額
                            cv_tax_div_inslip,   rlli.extended_amount,    -- 内税(伝票)：税抜額
                            rlli.extended_amount + rlta.extended_amount)  -- 内税(単価)：税込額
                                                                  sold_amount,            -- 売上金額
                   NULL                                           red_black_slip_type,    -- 赤伝黒伝区分
                   rcta.customer_trx_id                           trx_id,                 -- 取引ID
                   rcta.trx_number                                trx_number,             -- 取引番号
                   rcta.cust_trx_type_id                          cust_trx_type_id,       -- 取引タイプID
                   rcta.batch_source_id                           batch_source_id,        -- 取引ソースID
                   cn_created_by                                  created_by,             -- 作成者
                   cd_creation_date                               creation_date,          -- 作成日
                   cn_last_updated_by                             last_updated_by,        -- 最終更新者
                   cd_last_update_date                            last_update_date,       -- 最終更新日
                   cn_last_update_login                           last_update_login ,     -- 最終更新ログイン
                   cn_request_id                                  request_id,             -- 要求ID
                   cn_program_application_id                      program_application_id, -- アプリケーションID
                   cn_program_id                                  program_id,             -- プログラムID
                   cd_program_update_date                         program_update_date,    -- プログラム更新日
                   xih.cutoff_date                                cutoff_date,            -- 締日
                   NULL                                           num_of_cases,           -- ケース入数
                   NULL                                           medium_class,           -- 受注ソース
                   xxca.delivery_chain_code                       delivery_chain_code     -- 納品先チェーンコード
                  ,NULL                                           bms_header_data         -- 流通ＢＭＳヘッダデータ
-- Add 2019.07.26 Ver1.160 START
                  ,arta.tax_code                                  tax_code                -- 税金コード
-- Add 2019.07.26 Ver1.160 END
            FROM   
                   xxcfr_invoice_headers         xih,               -- アドオン請求書ヘッダ
                   ra_customer_trx               rcta,              -- 取引テーブル
                   hz_parties                    hp_sold,           -- パーティー(売上拠点)
                   hz_cust_accounts              hc_sold,           -- 顧客マスタ(売上拠点)
                   hz_parties                    hp_ship,           -- パーティー(納入先)
                   hz_cust_accounts              hzca,              -- 顧客マスタ
                   xxcmm_cust_accounts           xxca,              -- 顧客追加情報
                   hz_cust_acct_sites            hzsa,              -- 顧客所在地
                   ra_customer_trx_lines         rlli,              -- 取引明細(明細)テーブル
                   ra_customer_trx_lines         rlta,              -- 取引明細(税額)テーブル
                   ra_cust_trx_line_gl_dist      rgda,              -- 取引会計情報テーブル
                   ar_vat_tax_all_b              arta,              -- 税金マスタ
                   fnd_lookup_values             fnvd               -- クイックコード(VD顧客区分)
            WHERE  xih.request_id            = gt_target_request_id       -- ターゲットとなる要求ID
            AND    rcta.trx_date            <= xih.cutoff_date            -- 取引日
            AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- 請求先顧客ID
            AND    xih.org_id                = gn_org_id                      -- 組織ID
            AND    xih.set_of_books_id       = gn_set_book_id        -- 会計帳簿ID
-- Modify 2013.06.10 Ver1.140 Start
            AND    xih.inv_creation_flag     = cv_inv_creation_flag  --請求作成対象フラグ
-- Modify 2013.06.10 Ver1.140 End
            AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                       cv_inv_hold_status_r)        -- 請求書保留ステータス
            AND    rcta.set_of_books_id = gn_set_book_id            -- 会計帳簿ID
            AND    rcta.batch_source_id = gt_arinput_trx_source_id  -- 取引ソース
            AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
            AND    xxca.sale_base_code  = hc_sold.account_number(+)  -- 売上拠点コード
            AND    hc_sold.party_id     = hp_sold.party_id(+)        -- パーティーID
            AND    hzca.party_id        = hp_ship.party_id           -- パーティーID
            AND    rcta.ship_to_customer_id = xxca.customer_id(+)
            AND    hzca.cust_account_id = hzsa.cust_account_id(+)
            AND    rcta.customer_trx_id = rlli.customer_trx_id
            AND    rlli.customer_trx_id = rlta.customer_trx_id(+)
            AND    rlli.customer_trx_line_id = rlta.link_to_cust_trx_line_id(+)
            AND    rlli.line_type = cv_line_type_line
            AND    rlta.line_type(+) = cv_line_type_tax
            AND    rcta.customer_trx_id = rgda.customer_trx_id
            AND    rgda.account_class = cv_account_class_rec
            AND    rlta.vat_tax_id = arta.vat_tax_id
            AND    fnvd.lookup_type(+)  = cv_lookup_vd_class_type    -- 参照タイプ(汎用請求VD対象小分類)
            AND    fnvd.language(+)     = USERENV( 'LANG' )
            AND    fnvd.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fnvd.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fnvd.end_date_active(+),   gd_process_date ) )
            AND    xxca.business_low_type = fnvd.lookup_code(+)
            AND    EXISTS (
                     -- 請求ヘッダデータ作成パラメータ請求先顧客に紐付く納品先顧客を処理対象とする
                     SELECT  'X'
                     FROM    hz_cust_acct_relate    bill_hcar
                            ,(
                       SELECT  bill_hzca.account_number    bill_account_number
                              ,ship_hzca.account_number    ship_account_number
                              ,bill_hzca.cust_account_id   bill_account_id
                              ,ship_hzca.cust_account_id   ship_account_id
                       FROM    hz_cust_accounts          bill_hzca
                              ,hz_cust_acct_sites        bill_hzsa
                              ,hz_cust_site_uses         bill_hsua
                              ,hz_cust_accounts          ship_hzca
                              ,hz_cust_acct_sites        ship_hasa
                              ,hz_cust_site_uses         ship_hsua
                       WHERE   bill_hzca.cust_account_id   = bill_hzsa.cust_account_id
                       AND     bill_hzsa.cust_acct_site_id = bill_hsua.cust_acct_site_id
                       AND     ship_hzca.cust_account_id   = ship_hasa.cust_account_id
                       AND     ship_hasa.cust_acct_site_id = ship_hsua.cust_acct_site_id
                       AND     ship_hsua.bill_to_site_use_id = bill_hsua.site_use_id
                       AND     ship_hzca.customer_class_code = '10'
                       AND     bill_hsua.site_use_code = 'BILL_TO'
                       AND     bill_hsua.status = 'A'
                       AND     ship_hsua.status = 'A'
                     )  ship_cust_info
                     WHERE   hzca.cust_account_id = ship_cust_info.ship_account_id
                     AND     ship_cust_info.bill_account_id = bill_hcar.cust_account_id(+)
                     AND     bill_hcar.related_cust_account_id(+) = ship_cust_info.ship_account_id
                     AND     bill_hcar.attribute1(+) = '1'
                     AND     bill_hcar.status(+)     = 'A'
                     AND     ship_cust_info.bill_account_number = gt_bill_acct_code
                   )
              UNION ALL
            --請求明細データ(販売実績) 
            SELECT /*+ FIRST_ROWS
                       LEADING(xih rcta rlli xxeh hzca xxca hzsa xedh fdsc hp_ship hc_sold hp_sold)
                       INDEX(xih  XXCFR_INVOICE_HEADERS_N02)
                       INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
                       INDEX(hzca HZ_CUST_ACCOUNTS_U2)
                       INDEX(xxca XXCMM_CUST_ACCOUNTS_N06)
                       INDEX(hp_ship HZ_PARTIES_U1)
                       INDEX(hc_sold HZ_CUST_ACCOUNTS_U2)
                       INDEX(hp_sold HZ_PARTIES_U1)
                       INDEX(hzsa HZ_CUST_ACCT_SITES_N2)
                       INDEX(rlli RA_CUSTOMER_TRX_LINES_N2)
                       INDEX(arta AR_VAT_TAX_ALL_B_U1)
                       INDEX(xxeh XXCOS_SALES_EXP_HEADERS_PK)
                       INDEX(xxel XXCOS_SALES_EXP_LINES_N01)
                       INDEX(xedh XXCOS_EDI_HEADERS_N03)
                       INDEX(mtib MTL_SYSTEM_ITEMS_B_N1)
                       INDEX(xxib XXCMN_IMB_N02)
                       USE_NL(hzca xxca)
                   */
                   xih.invoice_id                                  invoice_id,             -- 一括請求書ID
                   xxel.dlv_invoice_line_number                    note_line_id,            -- 伝票明細No
                   xxeh.ship_to_customer_code                     ship_cust_code,         -- 納品先顧客コード
                   hp_ship.party_name                              ship_cust_name,          -- 納品先顧客名
                   hp_ship.organization_name_phonetic              ship_cust_kana_name,     -- 納品先顧客カナ名
                   xxca.sale_base_code                             sold_location_code,      -- 売上拠点コード
                   hp_sold.party_name                              sold_location_name,      -- 売上拠点名
                   xxca.store_code                                 ship_shop_code,          -- 納品先店舗コード
                   xxca.cust_store_name                            ship_shop_name,          -- 納品先店名
                   xxca.vendor_machine_number                      vd_num,                  -- 自動販売機番号
                   NVL(fvdt.attribute1, '0')                       vd_cust_type,            -- VD顧客区分
                   DECODE(rcta.attribute7,
                            cv_inv_hold_status_r, cv_inv_type_re
                                                , cv_inv_type_no)  inv_type,                -- 請求区分
                   xxca.chain_store_code                           chain_shop_code,         -- チェーン店コード
                   xxeh.delivery_date                              delivery_date,           -- 納品日
                   xxeh.dlv_invoice_number                         slip_num,                -- 伝票番号
                   xxeh.order_invoice_number                       order_num,               -- オーダーNO
                   xxel.column_no                                  column_num,              -- コラムNo
                   xxeh.invoice_class                              slip_type,               -- 伝票区分
                   xxeh.invoice_classification_code                classify_type,           -- 分類区分
                   xedh.other_party_department_code                customer_dept_code,      -- お客様部門コード
                   xedh.delivery_to_section_code                   customer_division_code,  -- お客様課コード
                   fdsc.attribute1                                 sold_return_type,        -- 売上返品区分
                   NULL                                            nichiriu_by_way_type,    -- ニチリウ経由区分
                   fscl.attribute8                                 sale_type,               -- 特売区分
                   xedh.opportunity_no                             direct_num,              -- 便No
                   xedh.order_date                                 po_date,                 -- 発注日
                   rcta.trx_date                                   acceptance_date,         -- 検収日
                   xxel.item_code                                  item_code,               -- 商品CD
                   mtib.description                                item_name,               -- 商品名
                   xxmb.item_name_alt                              item_kana_name,          -- 商品カナ名
                   icmb.attribute2                                 policy_group,            -- 政策群コード
                   icmb.attribute21                                jan_code,                -- JANコード
                   fnlv.attribute1                                 vessel_type,             -- 容器区分
                   fykn.meaning                                    vessel_type_name,        -- 容器区分名
                   xxib.vessel_group                               vessel_group,            -- 容器群
                   fnlv.meaning                                    vessel_group_name,       -- 容器群名
                   xxel.standard_qty                               quantity,                -- 数量(基準数量)
                   xxel.standard_unit_price                        unit_price,              -- 単価(基準単価)
                   xxel.dlv_qty                                    dlv_qty,                 -- 納品数量
                   xxel.dlv_unit_price                             dlv_unit_price,               -- 納品単価
                   xxel.dlv_uom_code                               dlv_uom_code,                 -- 納品単位
                   xxel.standard_uom_code                          standard_uom_code,            -- 基準単位
                   xxel.standard_unit_price_excluded               standard_unit_price_excluded, -- 税抜基準単価
                   xxel.business_cost                              business_cost,                -- 営業原価
                   xxel.tax_amount                                 tax_amount,              -- 消費税金額
-- Modify 2019.07.26 Ver1.160 Start
--                   xxeh.tax_rate                                   tax_rate,                -- 消費税率
-- Modify Ver1.170 Start
--                   xxel.tax_rate                                   tax_rate,                -- 消費税率
                   NVL(xxel.tax_rate,xxeh.tax_rate)                tax_rate,                -- 消費税率
-- Modify Ver1.170 End
-- Modify 2019.07.26 Ver1.160 End
                   xxel.pure_amount                                ship_amount,             -- 納品金額
                   xxel.sale_amount                                sold_amount,             -- 売上金額
                   NULL                                            red_black_slip_type,     -- 赤伝黒伝区分
                   rcta.customer_trx_id                            trx_id,                  -- 取引ID
                   rcta.trx_number                                 trx_number,              -- 取引番号
                   rcta.cust_trx_type_id                           cust_trx_type_id,        -- 取引タイプID
                   rcta.batch_source_id                            batch_source_id,         -- 取引ソースID
                   cn_created_by                                   created_by,              -- 作成者
                   cd_creation_date                                creation_date,           -- 作成日
                   cn_last_updated_by                              last_updated_by,         -- 最終更新者
                   cd_last_update_date                             last_update_date,        -- 最終更新日
                   cn_last_update_login                            last_update_login ,      -- 最終更新ログイン
                   cn_request_id                                   request_id,              -- 要求ID
                   cn_program_application_id                       program_application_id,  -- アプリケーションID
                   cn_program_id                                   program_id,              -- プログラムID
                   cd_program_update_date                          program_update_date,     -- プログラム更新日
                   xih.cutoff_date                                 cutoff_date,             -- 締日
                   icmb.attribute11                                num_of_cases,            -- ケース入数
                   NVL( xedh.medium_class , cv_medium_class_mnl)   medium_class,            -- 受注ソース
                   xxca.delivery_chain_code                        delivery_chain_code      -- 納品先チェーンコード
                  ,xedh.bms_header_data                            bms_header_data          -- 流通ＢＭＳヘッダデータ
-- Add 2019.07.26 Ver1.160 START
-- Modify Ver1.170 Start
--                  ,xxel.tax_code                                   tax_code                 -- 税金コード
                  ,NVL(xxel.tax_code,xxeh.tax_code)                tax_code                 -- 税金コード
-- Modify Ver1.170 End
-- Add 2019.07.26 Ver1.160 END
            FROM   
                   xxcfr_invoice_headers         xih,            -- アドオン請求書ヘッダ
                   ra_customer_trx               rcta,           -- 取引テーブル
                   hz_parties                    hp_sold,        -- パーティー(売上拠点)
                   hz_cust_accounts              hc_sold,        -- 顧客マスタ(売上拠点)
                   hz_parties                    hp_ship,        -- パーティー(納入先)
                   hz_cust_accounts              hzca,           -- 顧客マスタ
                   xxcmm_cust_accounts           xxca,           -- 顧客追加情報
                   hz_cust_acct_sites            hzsa,           -- 顧客所在地
                   ra_customer_trx_lines         rlli,           -- 取引明細テーブル
                   xxcos_sales_exp_headers       xxeh,           -- 販売実績ヘッダテーブル
                   xxcos_sales_exp_lines         xxel,           -- 販売実績明細テーブル
                   xxcos_edi_headers             xedh,           -- EDIヘッダ情報テーブル
                   mtl_system_items_b            mtib,           -- 品目マスタ
                   xxcmm_system_items_b          xxib,           -- Disc品目アドオン
                   fnd_lookup_values             fnlv,           -- クイックコード(容器群)
                   fnd_lookup_values             fykn,           -- クイックコード(容器区分)
                   fnd_lookup_values             fdsc,           -- クイックコード(納品伝票区分)
                   fnd_lookup_values             fscl,           -- クイックコード(売上区分)
                   fnd_lookup_values             fvdt,           -- クイックコード(VD顧客区分)
                   ic_item_mst_b                 icmb,           -- OPM品目マスタ
                   xxcmn_item_mst_b              xxmb            -- OPM品目アドオン
            WHERE  xih.request_id            = gt_target_request_id       -- ターゲットとなる要求ID
            AND    rcta.trx_date            <= xih.cutoff_date            -- 取引日
            AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- 請求先顧客ID
            AND    xih.org_id                = gn_org_id                      -- 組織ID
            AND    xih.set_of_books_id       = gn_set_book_id        -- 会計帳簿ID
-- Modify 2013.06.10 Ver1.140 Start
            AND    xih.inv_creation_flag     = cv_inv_creation_flag  --請求作成対象フラグ
-- Modify 2013.06.10 Ver1.140 End
            AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                       cv_inv_hold_status_r)         -- 請求書保留ステータス
            AND    rcta.set_of_books_id = gn_set_book_id             -- 会計帳簿ID
            AND    rcta.batch_source_id != gt_arinput_trx_source_id  -- 取引ソース(AR部門入力以外)
            AND    xxeh.ship_to_customer_code = hzca.account_number
            AND    xxca.sale_base_code  = hc_sold.account_number(+)  -- 売上拠点コード
            AND    hc_sold.party_id     = hp_sold.party_id(+)        -- パーティーID
            AND    hzca.party_id        = hp_ship.party_id           -- パーティーID
            AND    xxeh.ship_to_customer_code = xxca.customer_code
            AND    hzca.cust_account_id = hzsa.cust_account_id
            AND    rcta.customer_trx_id = rlli.customer_trx_id
            AND    rlli.line_type = cv_line_type_line
-- 2019/09/19 Ver1.180 ADD Start
            AND    rlli.customer_trx_line_id = (  SELECT MIN(rctla.customer_trx_line_id) customer_trx_line_id
                                                  FROM   ra_customer_trx_lines  rctla
                                                  WHERE  rctla.customer_trx_id           = rcta.customer_trx_id
                                                  AND    rctla.line_type                 = cv_line_type_line
                                                  AND    rctla.interface_line_attribute7 = rlli.interface_line_attribute7  )
-- 2019/09/19 Ver1.180 ADD End
            AND    rlli.interface_line_attribute7 = xxeh.sales_exp_header_id  -- 販売実績ヘッダ内部ID
            AND    xxeh.sales_exp_header_id = xxel.sales_exp_header_id
-- 2019/09/19 Ver1.180 ADD Start
            AND    xxel.goods_prod_cls IS NOT NULL
-- 2019/09/19 Ver1.180 ADD End
-- 2019/09/19 Ver1.180 DEL Start
--            AND   ((rlli.interface_line_attribute8 IS NULL)
--               OR  (rlli.interface_line_attribute8 = xxel.goods_prod_cls))    -- 品目区分
-- 2019/09/19 Ver1.180 DEL End
            AND    xxeh.order_connection_number = xedh.order_connection_number(+)
            AND    xxel.item_code = mtib.segment1(+)
            AND    mtib.organization_id(+) = gt_mtl_organization_id  -- 品目マスタ組織ID
            AND    fdsc.lookup_type(+)  = cv_lookup_slip_class    -- 参照タイプ(納品伝票区分)
            AND    fdsc.language(+)     = USERENV( 'LANG' )
            AND    fdsc.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fdsc.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fdsc.end_date_active(+),   gd_process_date ) )
            AND    xxeh.dlv_invoice_class = fdsc.lookup_code(+)
            AND    fscl.lookup_type(+)  = cv_lookup_sale_class    -- 参照タイプ(売上区分)
            AND    fscl.language(+)     = USERENV( 'LANG' )
            AND    fscl.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fscl.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fscl.end_date_active(+),   gd_process_date ) )
            AND    xxel.sales_class = fscl.lookup_code(+)
            AND    mtib.segment1 = icmb.item_no(+)
            AND    icmb.item_id  = xxmb.item_id(+)
-- Del 2016.03.02 Ver1.150 Start
--            AND    xxmb.active_flag(+) = 'Y'
-- Del 2016.03.02 Ver1.150 End
            AND    xih.cutoff_date >= NVL(TRUNC(xxmb.start_date_active), xih.cutoff_date)
            AND    xih.cutoff_date <= NVL(xxmb.end_date_active, xih.cutoff_date)
            AND    icmb.item_id = xxib.item_id(+)
            AND    fnlv.lookup_type(+)  = cv_lookup_itm_yokigun   -- 参照タイプ(容器群)
            AND    fnlv.language(+)     = USERENV( 'LANG' )
            AND    fnlv.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
            AND    xxib.vessel_group = fnlv.lookup_code(+)
            AND    fykn.lookup_type(+)  = cv_lookup_itm_yokikubun   -- 参照タイプ(容器区分)
            AND    fykn.language(+)     = USERENV( 'LANG' )
            AND    fykn.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fykn.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fykn.end_date_active(+),   gd_process_date ) )
            AND    fnlv.attribute1 = fykn.lookup_code(+)
            AND    fvdt.lookup_type(+)  = cv_lookup_vd_class_type    -- 参照タイプ(汎用請求VD対象小分類)
            AND    fvdt.language(+)     = USERENV( 'LANG' )
            AND    fvdt.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fvdt.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fvdt.end_date_active(+),   gd_process_date ) )
            AND    xxca.business_low_type = fvdt.lookup_code(+)
            AND    EXISTS (
                     -- 請求ヘッダデータ作成パラメータ請求先顧客に紐付く納品先顧客を処理対象とする
                     SELECT  'X'
                     FROM    hz_cust_acct_relate    bill_hcar
                            ,(
                       SELECT  bill_hzca.account_number    bill_account_number
                              ,ship_hzca.account_number    ship_account_number
                              ,bill_hzca.cust_account_id   bill_account_id
                              ,ship_hzca.cust_account_id   ship_account_id
                       FROM    hz_cust_accounts          bill_hzca
                              ,hz_cust_acct_sites        bill_hzsa
                              ,hz_cust_site_uses         bill_hsua
                              ,hz_cust_accounts          ship_hzca
                              ,hz_cust_acct_sites        ship_hasa
                              ,hz_cust_site_uses         ship_hsua
                       WHERE   bill_hzca.cust_account_id   = bill_hzsa.cust_account_id
                       AND     bill_hzsa.cust_acct_site_id = bill_hsua.cust_acct_site_id
                       AND     ship_hzca.cust_account_id   = ship_hasa.cust_account_id
                       AND     ship_hasa.cust_acct_site_id = ship_hsua.cust_acct_site_id
                       AND     ship_hsua.bill_to_site_use_id = bill_hsua.site_use_id
                       AND     ship_hzca.customer_class_code = '10'
                       AND     bill_hsua.site_use_code = 'BILL_TO'
                       AND     bill_hsua.status = 'A'
                       AND     ship_hsua.status = 'A'
                     )  ship_cust_info
                     WHERE   hzca.cust_account_id = ship_cust_info.ship_account_id
                     AND     ship_cust_info.bill_account_id = bill_hcar.cust_account_id(+)
                     AND     bill_hcar.related_cust_account_id(+) = ship_cust_info.ship_account_id
                     AND     bill_hcar.attribute1(+) = '1'
                     AND     bill_hcar.status(+)     = 'A'
                     AND     ship_cust_info.bill_account_number = gt_bill_acct_code
                   )
          )                inlv
-- Modify 2013.01.17 Ver1.130 End
    ;
--
    -- *** ローカル・レコード ***
-- Modify 2009.08.03 Ver1.4 Start
  TYPE get_main_data_ttype IS TABLE OF main_data_cur%ROWTYPE 
                           INDEX BY PLS_INTEGER;    -- メインカーソル用
  lt_main_data_tab  get_main_data_ttype;            -- メインカーソル用
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2013.01.17 Ver1.130 Start
  TYPE get_main_data_manual_ttype IS TABLE OF main_data_manual_cur%ROWTYPE 
                           INDEX BY PLS_INTEGER;          -- 手動実行メインカーソル用
  lt_main_data_manual_tab  get_main_data_manual_ttype;    -- 手動実行メインカーソル用
-- Modify 2013.01.17 Ver1.130 End
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
-- Modify 2013.01.17 Ver1.130 Start
-- Modify 2009.08.03 Ver1.4 Start
--    lt_main_data_tab.DELETE;  -- メインカーソル用
-- Modify 2009.08.03 Ver1.4 End
    IF (gv_batch_on_judge_type = cv_judge_type_batch) THEN
      lt_main_data_tab.DELETE;  -- メインカーソル用
    ELSE
      lt_main_data_manual_tab.DELETE;  -- メインカーソル用(手動実行)
    END IF;
-- Modify 2013.01.17 Ver1.130 End
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --請求明細情報テーブル登録処理
    --==============================================================
    -- 請求明細情報テーブル登録
-- Modify 2009.08.03 Ver1.4 Start
--    BEGIN
--      INSERT INTO xxcfr_invoice_lines(
--        invoice_id,                               -- 一括請求書ID
--        invoice_detail_num,                       -- 一括請求書明細No
--        note_line_id,                             -- 伝票明細No
--        ship_cust_code,                           -- 納品先顧客コード
--        ship_cust_name,                           -- 納品先顧客名
--        ship_cust_kana_name,                      -- 納品先顧客カナ名
--        sold_location_code,                       -- 売上拠点コード
--        sold_location_name,                       -- 売上拠点名
--        ship_shop_code,                           -- 納品先店舗コード
--        ship_shop_name,                           -- 納品先店名
--        vd_num,                                   -- 自動販売機番号
--        vd_cust_type,                             -- VD顧客区分
--        inv_type,                                 -- 請求区分
--        chain_shop_code,                          -- チェーン店コード
--        delivery_date,                            -- 納品日
--        slip_num,                                 -- 伝票番号
--        order_num,                                -- オーダーNO
--        column_num,                               -- コラムNo
--        slip_type,                                -- 伝票区分
--        classify_type,                            -- 分類区分
--        customer_dept_code,                       -- お客様部門コード
--        customer_division_code,                   -- お客様課コード
--        sold_return_type,                         -- 売上返品区分
--        nichiriu_by_way_type,                     -- ニチリウ経由区分
--        sale_type,                                -- 特売区分
--        direct_num,                               -- 便No
--        po_date,                                  -- 発注日
--        acceptance_date,                          -- 検収日
--        item_code,                                -- 商品CD
--        item_name,                                -- 商品名
--        item_kana_name,                           -- 商品カナ名
--        policy_group,                             -- 政策群コード
--        jan_code,                                 -- JANコード
--        vessel_type,                              -- 容器区分
--        vessel_type_name,                         -- 容器区分名
--        vessel_group,                             -- 容器群
--        vessel_group_name,                        -- 容器群名
--        quantity,                                 -- 数量
--        unit_price,                               -- 単価
--        dlv_qty,                                  -- 納品数量
--        dlv_unit_price,                           -- 納品単価
--        dlv_uom_code,                             -- 納品単位
--        standard_uom_code,                        -- 基準単位
--        standard_unit_price_excluded,             -- 税抜基準単価
--        business_cost,                            -- 営業原価
--        tax_amount,                               -- 消費税金額
--        tax_rate,                                 -- 消費税率
--        ship_amount,                              -- 納品金額
--        sold_amount,                              -- 売上金額
--        red_black_slip_type,                      -- 赤伝黒伝区分
--        trx_id,                                   -- 取引ID
--        trx_number,                               -- 取引番号
--        cust_trx_type_id,                         -- 取引タイプID
--        batch_source_id,                          -- 取引ソースID
--        created_by,                               -- 作成者
--        creation_date,                            -- 作成日
--        last_updated_by,                          -- 最終更新者
--        last_update_date,                         -- 最終更新日
--        last_update_login ,                       -- 最終更新ログイン
--        request_id,                               -- 要求ID
--        program_application_id,                   -- アプリケーションID
--        program_id,                               -- プログラムID
--        program_update_date                       -- プログラム更新日
--    ) 
--      SELECT inlv.invoice_id                   invoice_id,                    -- 一括請求書ID
--             ROWNUM                            invoice_detail_num,            -- 一括請求書明細No
--             inlv.note_line_id                 note_line_id,                  -- 伝票明細No
--             inlv.ship_cust_code               ship_cust_code,                -- 納品先顧客コード
---- Modify 2009.07.22 Ver1.3 Start
----             inlv.ship_cust_name               ship_cust_name,                -- 納品先顧客名
----             inlv.ship_cust_kana_name          ship_cust_kana_name,           -- 納品先顧客カナ名
--             ship.party_name                   ship_cust_name,                -- 納品先顧客名
--             ship.organization_name_phonetic   ship_cust_kana_name,           -- 納品先顧客カナ名
---- Modify 2009.07.22 Ver1.3 End
--             inlv.sold_location_code           sold_location_code,            -- 売上拠点コード
---- Modify 2009.07.22 Ver1.3 Start
----             inlv.sold_location_name           sold_location_name,            -- 売上拠点名
--             sold.party_name                   sold_location_name,            -- 売上拠点名
---- Modify 2009.07.22 Ver1.3 End
--             inlv.ship_shop_code               ship_shop_code,                -- 納品先店舗コード
--             inlv.ship_shop_name               ship_shop_name,                -- 納品先店名
--             inlv.vd_num                       vd_num,                        -- 自動販売機番号
--             inlv.vd_cust_type                 vd_cust_type,                  -- VD顧客区分
--             inlv.inv_type                     inv_type,                      -- 請求区分
--             inlv.chain_shop_code              chain_shop_code,               -- チェーン店コード
--             inlv.delivery_date                delivery_date,                 -- 納品日
--             inlv.slip_num                     slip_num,                      -- 伝票番号
--             inlv.order_num                    order_num,                     -- オーダーNO
--             inlv.column_num                   column_num,                    -- コラムNo
--             inlv.slip_type                    slip_type,                     -- 伝票区分
--             inlv.classify_type                classify_type,                 -- 分類区分
--             inlv.customer_dept_code           customer_dept_code,            -- お客様部門コード
--             inlv.customer_division_code       customer_division_code,        -- お客様課コード
--             inlv.sold_return_type             sold_return_type,              -- 売上返品区分
--             inlv.nichiriu_by_way_type         nichiriu_by_way_type,          -- ニチリウ経由区分
--             inlv.sale_type                    sale_type,                     -- 特売区分
--             inlv.direct_num                   direct_num,                    -- 便No
--             inlv.po_date                      po_date,                       -- 発注日
--             inlv.acceptance_date              acceptance_date,               -- 検収日
--             inlv.item_code                    item_code,                     -- 商品CD
--             inlv.item_name                    item_name,                     -- 商品名
--             inlv.item_kana_name               item_kana_name,                -- 商品カナ名
--             inlv.policy_group                 policy_group,                  -- 政策群コード
--             inlv.jan_code                     jan_code,                      -- JANコード
--             inlv.vessel_type                  vessel_type,                   -- 容器区分
--             inlv.vessel_type_name             vessel_type_name,              -- 容器区分名
--             inlv.vessel_group                 vessel_group,                  -- 容器群
--             inlv.vessel_group_name            vessel_group_name,             -- 容器群名
--             inlv.quantity                     quantity,                      -- 数量
--             inlv.unit_price                   unit_price,                    -- 単価
--             inlv.dlv_qty                      dlv_qty,                       -- 納品数量
--             inlv.dlv_unit_price               dlv_unit_price,                -- 納品単価
--             inlv.dlv_uom_code                 dlv_uom_code,                  -- 納品単位
--             inlv.standard_uom_code            standard_uom_code,             -- 基準単位
--             inlv.standard_unit_price_excluded standard_unit_price_excluded,  -- 税抜基準単価
--             inlv.business_cost                business_cost,                 -- 営業原価
--             inlv.tax_amount                   tax_amount,                    -- 消費税金額
--             inlv.tax_rate                     tax_rate,                      -- 消費税率
--             inlv.ship_amount                  ship_amount,                   -- 納品金額
--             inlv.sold_amount                  sold_amount,                   -- 売上金額
--             inlv.red_black_slip_type          red_black_slip_type,           -- 赤伝黒伝区分
--             inlv.trx_id                       trx_id,                        -- 取引ID
--             inlv.trx_number                   trx_number,                    -- 取引番号
--             inlv.cust_trx_type_id             cust_trx_type_id,              -- 取引タイプID
--             inlv.batch_source_id              batch_source_id,               -- 取引ソースID
--             inlv.created_by                   created_by,                    -- 作成者
--             inlv.creation_date                creation_date,                 -- 作成日
--             inlv.last_updated_by              last_updated_by,               -- 最終更新者
--             inlv.last_update_date             last_update_date,              -- 最終更新日
--             inlv.last_update_login            last_update_login ,            -- 最終更新ログイン
--             inlv.request_id                   request_id,                    -- 要求ID
--             inlv.program_application_id       program_application_id,        -- アプリケーションID
--             inlv.program_id                   program_id,                    -- プログラムID
--             inlv.program_update_date          program_update_date            -- プログラム更新日
--      FROM  (
--        --請求明細データ(AR部門入力) 
---- Modify 2009.07.22 Ver1.3 Start
----        SELECT in_invoice_id                                  invoice_id,             -- 一括請求書ID
--        SELECT xih.invoice_id                                 invoice_id,             -- 一括請求書ID
---- Modify 2009.07.22 Ver1.3 End
--               NULL                                           note_line_id,           -- 伝票明細No
--               hzca.account_number                            ship_cust_code,         -- 納品先顧客コード
---- Modify 2009.07.22 Ver1.3 Start
----               xxcfr_common_pkg.get_cust_account_name(
----                 hzca.account_number,
----                 cv_get_acct_name_f)                          ship_cust_name,         -- 納品先顧客名
----               xxcfr_common_pkg.get_cust_account_name(
----                 hzca.account_number,
----                 cv_get_acct_name_k)                          ship_cust_kana_name,    -- 納品先顧客カナ名
--               hzca.party_id                                  ship_party_id,
---- Modify 2009.07.22 Ver1.3 End
--               xxca.sale_base_code                            sold_location_code,     -- 売上拠点コード
---- Modify 2009.07.22 Ver1.3 Start
----               xxcfr_common_pkg.get_cust_account_name(
----                 xxca.sale_base_code,
----                 cv_get_acct_name_f)                          sold_location_name,     -- 売上拠点名
---- Modify 2009.07.22 Ver1.3 End
--               xxca.store_code                                ship_shop_code,         -- 納品先店舗コード
--               xxca.cust_store_name                           ship_shop_name,         -- 納品先店名
--               xxca.vendor_machine_number                     vd_num,                 -- 自動販売機番号
--               NVL(fnvd.attribute1, '0')                      vd_cust_type,           -- VD顧客区分
--               DECODE(rcta.attribute7,
--                        cv_inv_hold_status_r, cv_inv_type_re
--                                            , cv_inv_type_no) inv_type,               -- 請求区分
--               xxca.chain_store_code                          chain_shop_code,        -- チェーン店コード
--               rgda.gl_date                                   delivery_date,          -- 納品日
--               rlli.interface_line_attribute3                 slip_num,               -- 伝票番号
--               NULL                                           order_num,              -- オーダーNO
--               NULL                                           column_num,             -- コラムNo
--               NULL                                           slip_type,              -- 伝票区分
--               NULL                                           classify_type,          -- 分類区分
--               NULL                                           customer_dept_code,     -- お客様部門コード
--               NULL                                           customer_division_code, -- お客様課コード
--               NULL                                           sold_return_type,       -- 売上返品区分
--               NULL                                           nichiriu_by_way_type,   -- ニチリウ経由区分
--               NULL                                           sale_type,              -- 特売区分
--               NULL                                           direct_num,             -- 便No
--               NULL                                           po_date,                -- 発注日
--               rcta.trx_date                                  acceptance_date,        -- 検収日
--               NULL                                           item_code,              -- 商品CD
--               NULL                                           item_name,              -- 商品名
--               NULL                                           item_kana_name,         -- 商品カナ名
--               NULL                                           policy_group,           -- 政策群コード
--               NULL                                           jan_code,               -- JANコード
--               NULL                                           vessel_type,            -- 容器区分
--               NULL                                           vessel_type_name,       -- 容器区分名
--               NULL                                           vessel_group,           -- 容器群
--               NULL                                           vessel_group_name,      -- 容器群名
--               rlli.quantity_invoiced                         quantity,               -- 数量
--               rlli.unit_selling_price                        unit_price,             -- 単価
--               rlli.quantity_invoiced                         dlv_qty,                      -- 納品数量
--               rlli.unit_selling_price                        dlv_unit_price,               -- 納品単価
--               NULL                                           dlv_uom_code,                 -- 納品単位
--               NULL                                           standard_uom_code,            -- 基準単位
--               NULL                                           standard_unit_price_excluded, -- 税抜基準単価
--               NULL                                           business_cost,                -- 営業原価
--               rlta.extended_amount                           tax_amount,             -- 消費税金額
--               arta.tax_rate                                  tax_rate,               -- 消費税率
--               rlli.extended_amount                           ship_amount,            -- 納品金額
---- Modify 2009.07.22 Ver1.3 Start
----               DECODE(iv_tax_type,
--               DECODE(xih.tax_type,
---- Modify 2009.07.22 Ver1.3 End
--                        cv_tax_div_outtax,   rlli.extended_amount,    -- 外税　：税抜額
--                        cv_tax_div_notax,    rlli.extended_amount,    -- 非課税：税抜額
--                        cv_tax_div_inslip,   rlli.extended_amount,    -- 内税(伝票)：税抜額
--                        rlli.extended_amount + rlta.extended_amount)  -- 内税(単価)：税込額
--                                                              sold_amount,            -- 売上金額
--               NULL                                           red_black_slip_type,    -- 赤伝黒伝区分
--               rcta.customer_trx_id                           trx_id,                 -- 取引ID
--               rcta.trx_number                                trx_number,             -- 取引番号
--               rcta.cust_trx_type_id                          cust_trx_type_id,       -- 取引タイプID
--               rcta.batch_source_id                           batch_source_id,        -- 取引ソースID
--               cn_created_by                                  created_by,             -- 作成者
--               cd_creation_date                               creation_date,          -- 作成日
--               cn_last_updated_by                             last_updated_by,        -- 最終更新者
--               cd_last_update_date                            last_update_date,       -- 最終更新日
--               cn_last_update_login                           last_update_login ,     -- 最終更新ログイン
--               cn_request_id                                  request_id,             -- 要求ID
--               cn_program_application_id                      program_application_id, -- アプリケーションID
--               cn_program_id                                  program_id,             -- プログラムID
--               cd_program_update_date                         program_update_date     -- プログラム更新日
--        FROM   
---- Modify 2009.07.22 Ver1.3 Start
--               xxcfr_invoice_headers         xih,               -- アドオン請求書ヘッダ
----               ra_customer_trx_all           rcta,              -- 取引テーブル
--               ra_customer_trx               rcta,              -- 取引テーブル
---- Modify 2009.07.22 Ver1.3 End
--               hz_cust_accounts              hzca,              -- 顧客マスタ
--               xxcmm_cust_accounts           xxca,              -- 顧客追加情報
---- Modify 2009.07.22 Ver1.3 Start
----               hz_cust_acct_sites_all        hzsa,              -- 顧客所在地
----               ra_customer_trx_lines_all     rlli,              -- 取引明細(明細)テーブル
----               ra_customer_trx_lines_all     rlta,              -- 取引明細(税額)テーブル
----               ra_cust_trx_line_gl_dist_all  rgda,              -- 取引会計情報テーブル
--               hz_cust_acct_sites            hzsa,              -- 顧客所在地
--               ra_customer_trx_lines         rlli,              -- 取引明細(明細)テーブル
--               ra_customer_trx_lines         rlta,              -- 取引明細(税額)テーブル
--               ra_cust_trx_line_gl_dist      rgda,              -- 取引会計情報テーブル
---- Modify 2009.07.22 Ver1.3 End
--               ar_vat_tax_all_b              arta,              -- 税金マスタ
--               fnd_lookup_values             fnvd               -- クイックコード(VD顧客区分)
---- Modify 2009.07.22 Ver1.3 Start
----        WHERE  rcta.trx_date <= id_cutoff_date                  -- 取引日
--        WHERE  xih.request_id            = gt_target_request_id       -- ターゲットとなる要求ID
--        AND    rcta.trx_date            <= xih.cutoff_date            -- 取引日
--        AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- 請求先顧客ID
--        AND    xih.org_id                = gn_org_id                      -- 組織ID
--        AND    xih.set_of_books_id       = gn_set_book_id        -- 会計帳簿ID
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                   cv_inv_hold_status_r)        -- 請求書保留ステータス
---- Modify 2009.07.22 Ver1.3 Start
----        AND    rcta.bill_to_customer_id = iv_cust_acct_id       -- 請求先顧客ID
----        AND    rcta.org_id          = gn_org_id                 -- 組織ID
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.set_of_books_id = gn_set_book_id            -- 会計帳簿ID
--        AND    rcta.batch_source_id = gt_arinput_trx_source_id  -- 取引ソース
--        AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
--        AND    rcta.ship_to_customer_id = xxca.customer_id(+)
--        AND    hzca.cust_account_id = hzsa.cust_account_id(+)
---- Modify 2009.07.22 Ver1.3 Start
----        AND    hzsa.org_id(+) = gn_org_id
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.customer_trx_id = rlli.customer_trx_id
--        AND    rlli.customer_trx_id = rlta.customer_trx_id(+)
--        AND    rlli.customer_trx_line_id = rlta.link_to_cust_trx_line_id(+)
--        AND    rlli.line_type = cv_line_type_line
--        AND    rlta.line_type(+) = cv_line_type_tax
--        AND    rcta.customer_trx_id = rgda.customer_trx_id
--        AND    rgda.account_class = cv_account_class_rec
--        AND    rlta.vat_tax_id = arta.vat_tax_id
--        AND    fnvd.lookup_type(+)  = cv_lookup_vd_class_type    -- 参照タイプ(汎用請求VD対象小分類)
--        AND    fnvd.language(+)     = USERENV( 'LANG' )
--        AND    fnvd.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fnvd.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fnvd.end_date_active(+),   gd_process_date ) )
--        AND    xxca.business_low_type = fnvd.lookup_code(+)
--        UNION ALL
--        --請求明細データ(販売実績) 
---- Modify 2009.07.22 Ver1.3 Start
----        SELECT in_invoice_id                                   invoice_id,             -- 一括請求書ID
--        SELECT xih.invoice_id                                  invoice_id,             -- 一括請求書ID
---- Modify 2009.07.22 Ver1.3 End
--               xxel.dlv_invoice_line_number                    note_line_id,            -- 伝票明細No
--               hzca.account_number                             ship_cust_code,          -- 納品先顧客コード
---- Modify 2009.07.22 Ver1.3 Start
----               xxcfr_common_pkg.get_cust_account_name(
----                 hzca.account_number,
----                 cv_get_acct_name_f)                           ship_cust_name,          -- 納品先顧客名
----               xxcfr_common_pkg.get_cust_account_name(
----                 hzca.account_number,
----                 cv_get_acct_name_k)                           ship_cust_kana_name,     -- 納品先顧客カナ名
--               hzca.party_id                                   ship_party_id,
---- Modify 2009.07.22 Ver1.3 End
--               xxca.sale_base_code                             sold_location_code,      -- 売上拠点コード
---- Modify 2009.07.22 Ver1.3 Start
----               xxcfr_common_pkg.get_cust_account_name(
----                 xxca.sale_base_code,
----                 cv_get_acct_name_f)                           sold_location_name,      -- 売上拠点名
---- Modify 2009.07.22 Ver1.3 End
--               xxca.store_code                                 ship_shop_code,          -- 納品先店舗コード
--               xxca.cust_store_name                            ship_shop_name,          -- 納品先店名
--               xxca.vendor_machine_number                      vd_num,                  -- 自動販売機番号
--               NVL(fvdt.attribute1, '0')                       vd_cust_type,            -- VD顧客区分
--               DECODE(rcta.attribute7,
--                        cv_inv_hold_status_r, cv_inv_type_re
--                                            , cv_inv_type_no)  inv_type,                -- 請求区分
--               xxca.chain_store_code                           chain_shop_code,         -- チェーン店コード
--               xxeh.delivery_date                              delivery_date,           -- 納品日
--               xxeh.dlv_invoice_number                         slip_num,                -- 伝票番号
--               xxeh.order_invoice_number                       order_num,               -- オーダーNO
--               xxel.column_no                                  column_num,              -- コラムNo
--               xxeh.invoice_class                              slip_type,               -- 伝票区分
--               xxeh.invoice_classification_code                classify_type,           -- 分類区分
--               xedh.other_party_department_code                customer_dept_code,      -- お客様部門コード
--               xedh.delivery_to_section_code                   customer_division_code,  -- お客様課コード
--               fdsc.attribute1                                 sold_return_type,        -- 売上返品区分
--               NULL                                            nichiriu_by_way_type,    -- ニチリウ経由区分
--               fscl.attribute8                                 sale_type,               -- 特売区分
--               xedh.opportunity_no                             direct_num,              -- 便No
--               xedh.order_date                                 po_date,                 -- 発注日
--               rcta.trx_date                                   acceptance_date,         -- 検収日
--               xxel.item_code                                  item_code,               -- 商品CD
--               mtib.description                                item_name,               -- 商品名
--               xxmb.item_name_alt                              item_kana_name,          -- 商品カナ名
--               icmb.attribute2                                 policy_group,            -- 政策群コード
--               icmb.attribute21                                jan_code,                -- JANコード
--               fnlv.attribute1                                 vessel_type,             -- 容器区分
--               fykn.meaning                                    vessel_type_name,        -- 容器区分名
--               xxib.vessel_group                               vessel_group,            -- 容器群
--               fnlv.meaning                                    vessel_group_name,       -- 容器群名
--               xxel.standard_qty                               quantity,                -- 数量(基準数量)
--               xxel.standard_unit_price                        unit_price,              -- 単価(基準単価)
--               xxel.dlv_qty                                    dlv_qty,                 -- 納品数量
--               xxel.dlv_unit_price                             dlv_unit_price,               -- 納品単価
--               xxel.dlv_uom_code                               dlv_uom_code,                 -- 納品単位
--               xxel.standard_uom_code                          standard_uom_code,            -- 基準単位
--               xxel.standard_unit_price_excluded               standard_unit_price_excluded, -- 税抜基準単価
--               xxel.business_cost                              business_cost,                -- 営業原価
--               xxel.tax_amount                                 tax_amount,              -- 消費税金額
--               xxeh.tax_rate                                   tax_rate,                -- 消費税率
--               xxel.pure_amount                                ship_amount,             -- 納品金額
--               xxel.sale_amount                                sold_amount,             -- 売上金額
--               NULL                                            red_black_slip_type,     -- 赤伝黒伝区分
--               rcta.customer_trx_id                            trx_id,                  -- 取引ID
--               rcta.trx_number                                 trx_number,              -- 取引番号
--               rcta.cust_trx_type_id                           cust_trx_type_id,        -- 取引タイプID
--               rcta.batch_source_id                            batch_source_id,         -- 取引ソースID
--               cn_created_by                                   created_by,              -- 作成者
--               cd_creation_date                                creation_date,           -- 作成日
--               cn_last_updated_by                              last_updated_by,         -- 最終更新者
--               cd_last_update_date                             last_update_date,        -- 最終更新日
--               cn_last_update_login                            last_update_login ,      -- 最終更新ログイン
--               cn_request_id                                   request_id,              -- 要求ID
--               cn_program_application_id                       program_application_id,  -- アプリケーションID
--               cn_program_id                                   program_id,              -- プログラムID
--               cd_program_update_date                          program_update_date      -- プログラム更新日
--        FROM   
---- Modify 2009.07.22 Ver1.3 Start
--               xxcfr_invoice_headers         xih,               -- アドオン請求書ヘッダ
----               ra_customer_trx_all           rcta,           -- 取引テーブル
--               ra_customer_trx               rcta,           -- 取引テーブル
---- Modify 2009.07.22 Ver1.3 End
--               hz_cust_accounts              hzca,           -- 顧客マスタ
--               xxcmm_cust_accounts           xxca,           -- 顧客追加情報
---- Modify 2009.07.22 Ver1.3 Start
----               hz_cust_acct_sites_all        hzsa,           -- 顧客所在地
----               ra_customer_trx_lines_all     rlli,           -- 取引明細テーブル
--               hz_cust_acct_sites            hzsa,           -- 顧客所在地
--               ra_customer_trx_lines         rlli,           -- 取引明細テーブル
---- Modify 2009.07.22 Ver1.3 End
--               xxcos_sales_exp_headers       xxeh,           -- 販売実績ヘッダテーブル
--               xxcos_sales_exp_lines         xxel,           -- 販売実績明細テーブル
--               xxcos_edi_headers             xedh,           -- EDIヘッダ情報テーブル
--               mtl_system_items_b            mtib,           -- 品目マスタ
--               xxcmm_system_items_b          xxib,           -- Disc品目アドオン
--               fnd_lookup_values             fnlv,           -- クイックコード(容器群)
--               fnd_lookup_values             fykn,           -- クイックコード(容器区分)
--               fnd_lookup_values             fdsc,           -- クイックコード(納品伝票区分)
--               fnd_lookup_values             fscl,           -- クイックコード(売上区分)
--               fnd_lookup_values             fvdt,           -- クイックコード(VD顧客区分)
--               ic_item_mst_b                 icmb,           -- OPM品目マスタ
--               xxcmn_item_mst_b              xxmb            -- OPM品目アドオン
---- Modify 2009.07.22 Ver1.3 Start
----        WHERE  rcta.trx_date <= id_cutoff_date                  -- 取引日
--        WHERE  xih.request_id            = gt_target_request_id       -- ターゲットとなる要求ID
--        AND    rcta.trx_date            <= xih.cutoff_date            -- 取引日
--        AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- 請求先顧客ID
--        AND    xih.org_id                = gn_org_id                      -- 組織ID
--        AND    xih.set_of_books_id       = gn_set_book_id        -- 会計帳簿ID
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                   cv_inv_hold_status_r)         -- 請求書保留ステータス
---- Modify 2009.07.22 Ver1.3 Start
----        AND    rcta.bill_to_customer_id = iv_cust_acct_id        -- 請求先顧客ID
----        AND    rcta.org_id          = gn_org_id                  -- 組織ID
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.set_of_books_id = gn_set_book_id             -- 会計帳簿ID
--        AND    rcta.batch_source_id != gt_arinput_trx_source_id  -- 取引ソース(AR部門入力以外)
--        AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
--        AND    rcta.ship_to_customer_id = xxca.customer_id(+)
--        AND    hzca.cust_account_id = hzsa.cust_account_id(+)
---- Modify 2009.07.22 Ver1.3 Start
----        AND    hzsa.org_id(+) = gn_org_id
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.customer_trx_id = rlli.customer_trx_id
--        AND    rlli.line_type = cv_line_type_line
--        AND    rlli.interface_line_attribute7 = xxeh.sales_exp_header_id  -- 販売実績ヘッダ内部ID
--        AND    xxeh.sales_exp_header_id = xxel.sales_exp_header_id
--        AND    xxeh.order_connection_number = xedh.order_connection_number(+)
--        AND    xxel.item_code = mtib.segment1(+)
--        AND    mtib.organization_id(+) = gt_mtl_organization_id  -- 品目マスタ組織ID
--        AND    fdsc.lookup_type(+)  = cv_lookup_slip_class    -- 参照タイプ(納品伝票区分)
--        AND    fdsc.language(+)     = USERENV( 'LANG' )
--        AND    fdsc.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fdsc.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fdsc.end_date_active(+),   gd_process_date ) )
--        AND    xxeh.dlv_invoice_class = fdsc.lookup_code(+)
--        AND    fscl.lookup_type(+)  = cv_lookup_sale_class    -- 参照タイプ(売上区分)
--        AND    fscl.language(+)     = USERENV( 'LANG' )
--        AND    fscl.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fscl.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fscl.end_date_active(+),   gd_process_date ) )
--        AND    xxel.sales_class = fscl.lookup_code(+)
--        AND    mtib.segment1 = icmb.item_no(+)
--        AND    icmb.item_id  = xxmb.item_id(+)
--        AND    xxmb.active_flag(+) = 'Y'
---- Modify 2009.07.22 Ver1.3 Start
----        AND    id_cutoff_date >= TRUNC(xxmb.start_date_active(+))
----        AND    id_cutoff_date <= NVL(xxmb.end_date_active(+), id_cutoff_date)
--        AND    xih.cutoff_date >= NVL(TRUNC(xxmb.start_date_active), xih.cutoff_date)
--        AND    xih.cutoff_date <= NVL(xxmb.end_date_active, xih.cutoff_date)
---- Modify 2009.07.22 Ver1.3 End
--        AND    icmb.item_id = xxib.item_id(+)
--        AND    fnlv.lookup_type(+)  = cv_lookup_itm_yokigun   -- 参照タイプ(容器群)
--        AND    fnlv.language(+)     = USERENV( 'LANG' )
--        AND    fnlv.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
--        AND    xxib.vessel_group = fnlv.lookup_code(+)
--        AND    fykn.lookup_type(+)  = cv_lookup_itm_yokikubun   -- 参照タイプ(容器区分)
--        AND    fykn.language(+)     = USERENV( 'LANG' )
--        AND    fykn.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fykn.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fykn.end_date_active(+),   gd_process_date ) )
--        AND    fnlv.attribute1 = fykn.lookup_code(+)
--        AND    fvdt.lookup_type(+)  = cv_lookup_vd_class_type    -- 参照タイプ(汎用請求VD対象小分類)
--        AND    fvdt.language(+)     = USERENV( 'LANG' )
--        AND    fvdt.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fvdt.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fvdt.end_date_active(+),   gd_process_date ) )
--        AND    xxca.business_low_type = fvdt.lookup_code(+)
--        
--      )  inlv
---- Modify 2009.07.22 Ver1.3 Start
--     ,hz_parties       ship    -- 
--     ,hz_parties       sold    -- 
--     ,hz_cust_accounts soldca  -- 
--    WHERE inlv.ship_party_id      = ship.party_id
--      AND inlv.sold_location_code = soldca.account_number
--      AND soldca.party_id         = sold.party_id
---- Modify 2009.07.22 Ver1.3 End
--    ;
----
--    --請求明細データ登録件数カウント
--    gn_target_line_cnt := gn_target_line_cnt + SQL%ROWCOUNT;
----
--    EXCEPTION
--    -- *** OTHERS例外ハンドラ ***
--      WHEN OTHERS THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
--                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
--                                                      -- 請求明細情報テーブル
--                             ,1
--                             ,5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
--
-- Modify 2013.01.17 Ver1.130 Start
    --夜間手動判断区分の判断(夜間ジョブと手動実行で分割)
    IF (gv_batch_on_judge_type = cv_judge_type_batch) THEN
-- Modify 2013.01.17 Ver1.130 End
    OPEN main_data_cur;
--
    <<main_loop>>
    LOOP
--
      -- 対象データを一括取得(リミット単位)
      FETCH main_data_cur BULK COLLECT INTO lt_main_data_tab LIMIT gn_bulk_limit;
--
      -- 対象データがなくなったら終了
      EXIT WHEN lt_main_data_tab.COUNT < 1;
--
      BEGIN
--
        -- 対象データを一括登録(リミット単位)
        FORALL ln_loop_cnt IN lt_main_data_tab.FIRST..lt_main_data_tab.LAST
--
          INSERT INTO xxcfr_invoice_lines
          VALUES      lt_main_data_tab(ln_loop_cnt)
         ;
--
      --請求明細データ登録件数カウント
      gn_target_line_cnt := gn_target_line_cnt + SQL%ROWCOUNT;
--
      EXCEPTION
      -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
                                                        -- 請求明細情報テーブル
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
      -- 変数を初期化
      lt_main_data_tab.DELETE;
--
    END LOOP main_loop;
--
    -- カーソルクローズ
    CLOSE main_data_cur;
--
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2013.01.17 Ver1.130 Start
    --手動実行用
    ELSE
--
    OPEN main_data_manual_cur;
--
    <<main_manual_loop>>
    LOOP
--
      -- 対象データを一括取得(リミット単位)
      FETCH main_data_manual_cur BULK COLLECT INTO lt_main_data_manual_tab LIMIT gn_bulk_limit;
--
      -- 対象データがなくなったら終了
      EXIT WHEN lt_main_data_manual_tab.COUNT < 1;
--
      BEGIN
--
        -- 対象データを一括登録(リミット単位)
        FORALL ln_loop_cnt IN lt_main_data_manual_tab.FIRST..lt_main_data_manual_tab.LAST
--
          INSERT INTO xxcfr_invoice_lines
          VALUES      lt_main_data_manual_tab(ln_loop_cnt)
         ;
--
      --請求明細データ登録件数カウント
      gn_target_line_cnt := gn_target_line_cnt + SQL%ROWCOUNT;
--
      EXCEPTION
      -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
                                                        -- 請求明細情報テーブル
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
      -- 変数を初期化
      lt_main_data_manual_tab.DELETE;
--
    END LOOP main_manual_loop;
--
    -- カーソルクローズ
    CLOSE main_data_manual_cur;
--
    END IF;
-- Modify 2013.01.17 Ver1.130 End
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( main_data_cur%ISOPEN ) THEN
        CLOSE main_data_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( main_data_manual_cur%ISOPEN ) THEN
        CLOSE main_data_manual_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( main_data_cur%ISOPEN ) THEN
        CLOSE main_data_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( main_data_manual_cur%ISOPEN ) THEN
        CLOSE main_data_manual_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( main_data_cur%ISOPEN ) THEN
        CLOSE main_data_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( main_data_manual_cur%ISOPEN ) THEN
        CLOSE main_data_manual_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( main_data_cur%ISOPEN ) THEN
        CLOSE main_data_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( main_data_manual_cur%ISOPEN ) THEN
        CLOSE main_data_manual_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_inv_detail_data;
--
-- Modify 2009.09.29 Ver1.5 Start
--  /**********************************************************************************
--   * Procedure Name   : ins_aroif_data
--   * Description      : AR取引OIF登録処理(A-4)
--   ***********************************************************************************/
--  PROCEDURE ins_aroif_data(
--    in_invoice_id           IN  NUMBER,       -- 一括請求書ID
--    in_tax_gap_amt          IN  NUMBER,       -- 税差額
--    iv_term_name            IN  VARCHAR2,     -- 支払条件名
--    in_term_id              IN  NUMBER,       -- 支払条件ID
--    in_cust_acct_id         IN  NUMBER,       -- 請求先顧客ID
--    in_cust_site_id         IN  NUMBER,       -- 請求先顧客所在地ID
--    iv_bill_loc_code        IN  VARCHAR2,     -- 請求拠点コード
--    iv_rec_loc_code         IN  VARCHAR2,     -- 入金拠点コード
--    id_cutoff_date          IN  DATE,         -- 締日
--    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
--    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
--    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
--  )
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_aroif_data'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_target_cnt       NUMBER;         -- 対象件数
--    ln_tab_num          NUMBER;
--    ln_line_oif_cnt     NUMBER;
--    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--    lt_aroif_seq        ra_interface_lines_all.interface_line_attribute1%TYPE;  -- AR取引OIF登録用シーケンス
----
--    -- *** ローカル・カーソル ***
----
--    -- 税差額データ抽出カーソル
--    CURSOR get_tax_gap_info_cur
--    IS
--      SELECT xxgt.bill_cust_name            bill_cust_name,           -- 請求先顧客名
--             xxgt.tax_code                  tax_code,                 -- 税コード
--             xxgt.tax_code_id               tax_code_id,              -- 税金コードID
--             xxgt.segment3                  segment3,                 -- 勘定科目
--             xxgt.segment4                  segment4,                 -- 補助科目
--             xxgt.tax_gap_amount            tax_gap_amount,           -- 税差額
--             xxgt.note                      note,                     -- 注釈
--             arta.tax_account_id            tax_ccid,                 -- 税コードCCID
--             glcc.segment1                  tax_segment1,             -- 税コードAFF(segment1)
--             glcc.segment2                  tax_segment2,             -- 税コードAFF(segment2)
--             glcc.segment3                  tax_segment3,             -- 税コードAFF(segment3)
--             glcc.segment4                  tax_segment4,             -- 税コードAFF(segment4)
--             glcc.segment5                  tax_segment5,             -- 税コードAFF(segment5)
--             glcc.segment6                  tax_segment6,             -- 税コードAFF(segment6)
--             glcc.segment7                  tax_segment7,             -- 税コードAFF(segment7)
--             glcc.segment8                  tax_segment8,             -- 税コードAFF(segment8)
--             arta.amount_includes_tax_flag  amount_includes_tax_flag  -- 内税フラグ
--      FROM   xxcfr_tax_gap_trx_list xxgt,
--             ar_vat_tax_all_b       arta,
--             gl_code_combinations   glcc
--      WHERE  xxgt.invoice_id = in_invoice_id
--      AND    arta.tax_code(+) = xxgt.tax_code
--      AND    gd_process_date BETWEEN arta.start_date(+)
--                                 AND NVL(arta.end_date(+), gd_process_date)
--      AND    arta.enabled_flag(+) = cv_enabled_flag_y
--      AND    arta.org_id(+) = gn_org_id
--      AND    arta.set_of_books_id(+) = gn_set_book_id
--      AND    arta.tax_account_id = glcc.code_combination_id(+)
--      ;
----
--    TYPE get_cust_name_ttype     IS TABLE OF xxcfr_tax_gap_trx_list.bill_cust_name%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_code_ttype      IS TABLE OF xxcfr_tax_gap_trx_list.tax_code%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_code_id_ttype   IS TABLE OF xxcfr_tax_gap_trx_list.tax_code_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_segment3_ttype      IS TABLE OF xxcfr_tax_gap_trx_list.segment3%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_segment4_ttype      IS TABLE OF xxcfr_tax_gap_trx_list.segment4%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_gap_amt_ttype   IS TABLE OF xxcfr_tax_gap_trx_list.tax_gap_amount%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_note_ttype          IS TABLE OF xxcfr_tax_gap_trx_list.note%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_ccid_ttype      IS TABLE OF ar_vat_tax_all_b.tax_account_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment1_ttype  IS TABLE OF gl_code_combinations.segment1%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment2_ttype  IS TABLE OF gl_code_combinations.segment2%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment3_ttype  IS TABLE OF gl_code_combinations.segment3%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment4_ttype  IS TABLE OF gl_code_combinations.segment4%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment5_ttype  IS TABLE OF gl_code_combinations.segment5%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment6_ttype  IS TABLE OF gl_code_combinations.segment6%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment7_ttype  IS TABLE OF gl_code_combinations.segment7%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment8_ttype  IS TABLE OF gl_code_combinations.segment8%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_incl_tax_flag_ttype IS TABLE OF ar_vat_tax_all_b.amount_includes_tax_flag%TYPE
--                                             INDEX BY PLS_INTEGER;
--    lt_get_cust_name_tab         get_cust_name_ttype;
--    lt_get_tax_code_tab          get_tax_code_ttype;
--    lt_get_tax_code_id_tab       get_tax_code_id_ttype;
--    lt_get_segment3_tab          get_segment3_ttype;
--    lt_get_segment4_tab          get_segment4_ttype;
--    lt_get_tax_gap_amt_tab       get_tax_gap_amt_ttype;
--    lt_get_note_tab              get_note_ttype;
--    lt_get_tax_ccid_tab          get_tax_ccid_ttype;
--    lt_get_tax_segment1_tab      get_tax_segment1_ttype;
--    lt_get_tax_segment2_tab      get_tax_segment2_ttype;
--    lt_get_tax_segment3_tab      get_tax_segment3_ttype;
--    lt_get_tax_segment4_tab      get_tax_segment4_ttype;
--    lt_get_tax_segment5_tab      get_tax_segment5_ttype;
--    lt_get_tax_segment6_tab      get_tax_segment6_ttype;
--    lt_get_tax_segment7_tab      get_tax_segment7_ttype;
--    lt_get_tax_segment8_tab      get_tax_segment8_ttype;
--    lt_get_incl_tax_flag         get_incl_tax_flag_ttype;
----
--    -- *** ローカル・レコード ***
----
--    -- *** ローカル例外 ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ローカル変数の初期化
--    ln_target_cnt     := 0;
--    ln_line_oif_cnt   := 1;
----
--    --==============================================================
--    --税差額データ抽出処理
--    --==============================================================
--    -- 税差額データ抽出カーソルオープン
--    OPEN get_tax_gap_info_cur;
----
--    -- データの一括取得
--    FETCH get_tax_gap_info_cur 
--    BULK COLLECT INTO  lt_get_cust_name_tab   ,
--                       lt_get_tax_code_tab    ,
--                       lt_get_tax_code_id_tab ,
--                       lt_get_segment3_tab    ,
--                       lt_get_segment4_tab    ,
--                       lt_get_tax_gap_amt_tab ,
--                       lt_get_note_tab        ,
--                       lt_get_tax_ccid_tab    ,
--                       lt_get_tax_segment1_tab,
--                       lt_get_tax_segment2_tab,
--                       lt_get_tax_segment3_tab,
--                       lt_get_tax_segment4_tab,
--                       lt_get_tax_segment5_tab,
--                       lt_get_tax_segment6_tab,
--                       lt_get_tax_segment7_tab,
--                       lt_get_tax_segment8_tab,
--                       lt_get_incl_tax_flag
--    ;
----
--    -- 処理件数のセット
--    ln_target_cnt := lt_get_cust_name_tab.COUNT;
--    -- カーソルクローズ
--    CLOSE get_tax_gap_info_cur;
----
--    --==============================================================
--    --シーケンスから連番を取得処理
--    --==============================================================
--    -- 対象データが存在時
--    IF (ln_target_cnt > 0) THEN
--      BEGIN
--        --AR取引OIF登録用シーケンスから連番取得
--        SELECT  TO_CHAR(xxcfr_ar_trx_interface_s1.NEXTVAL)  aroif_seq
--        INTO    lt_aroif_seq
--        FROM    DUAL
--        ;
----
--      EXCEPTION
--        -- *** OTHERS例外ハンドラ ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303004);    -- AR取引OIF登録用シーケンス
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr,
--                                 iv_name         => cv_msg_cfr_00015,  
--                                 iv_token_name1  => cv_tkn_data,  
--                                 iv_token_value1 => lt_look_dict_word),
--                               1,
--                               5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
----
--      <<tax_gap_loop>>
--      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
----
--        --==============================================================
--        --AR取引OIF登録処理(LINE行)
--        --==============================================================
--        --AR取引OIFデータ登録(LINE行)
--        BEGIN
--          -- AR取引OIF(LINE行)
--          INSERT INTO ra_interface_lines_all(
--            interface_line_context,        -- 取引明細コンテキスト値
--            interface_line_attribute1,     -- 取引明細DFF1
--            interface_line_attribute2,     -- 取引明細DFF2
--            batch_source_name,             -- 取引ソース
--            set_of_books_id,               -- 会計帳簿ID
--            line_type,                     -- 明細タイプ
--            currency_code,                 -- 通貨
--            amount,                        -- 金額
--            cust_trx_type_name,            -- 取引タイプ名
--            cust_trx_type_id,              -- 取引タイプID
--            description,                   -- 品目明細摘要
--            term_name,                     -- 支払条件名
--            term_id,                       -- 支払条件ID
--            orig_system_bill_customer_id,  -- 請求先顧客ID
--            orig_system_bill_address_id,   -- 請求先顧客所在地ID
--            conversion_type,               -- 換算タイプ
--            conversion_rate,               -- 換算レート
--            trx_date,                      -- 取引日
--            gl_date,                       -- GL記帳日
--            quantity,                      -- 数量
--            unit_selling_price,            -- 販売単価
--            unit_standard_price,           -- 標準単価
--            tax_code,                      -- 税金コード
--            header_attribute_category,     -- ヘッダーDFFカテゴリ(組織ID)
--            header_attribute5,             -- ヘッダーDFF5(ユーザの所属部門)
--            header_attribute6,             -- ヘッダーDFF6(ユーザ)
--            header_attribute7,             -- ヘッダーDFF7(請求書保留ステータス)
--            header_attribute8,             -- ヘッダーDFF8(個別請求書印刷ステータス)
--            header_attribute9,             -- ヘッダーDFF9(一括請求書印刷ステータス)
--            header_attribute11,            -- ヘッダーDFF11(入金拠点)
--            comments,                      -- 注釈
--            created_by,                    -- 作成者
--            creation_date,                 -- 作成日
--            last_updated_by,               -- 最終更新者
--            last_update_date,              -- 最終更新日
--            last_update_login,             -- 最終更新ログイン
--            org_id,                        -- 営業単位ID
--            amount_includes_tax_flag       -- 税込金額フラグ
--          ) VALUES (
--            gt_taxd_trx_dtl_cont,                 -- 取引明細コンテキスト値
--            lt_aroif_seq,                         -- 取引明細DFF1
--            TO_CHAR(ln_line_oif_cnt),             -- 取引明細DFF2
--            gt_taxd_trx_source,                   -- 取引ソース
--            gn_set_book_id,                       -- 会計帳簿ID
--            cv_line_type_line,                    -- 明細タイプ
--            cv_currency_code,                     -- 通貨
--            lt_get_tax_gap_amt_tab(ln_loop_cnt),  -- 金額
--            gt_taxd_trx_type,                     -- 取引タイプ名
--            gt_tax_gap_trx_type_id,               -- 取引タイプID
--            gt_taxd_trx_memo_dtl,                 -- 品目明細摘要
--            iv_term_name,                         -- 支払条件名
--            in_term_id,                           -- 支払条件ID
--            in_cust_acct_id,                      -- 請求先顧客ID
--            in_cust_site_id,                      -- 請求先顧客所在地ID
--            cv_conversion_type,                   -- 換算タイプ
--            cn_conversion_rate,                   -- 換算レート
--            id_cutoff_date,                       -- 取引日
--            id_cutoff_date,                       -- GL記帳日
--            1,                                    -- 数量
--            lt_get_tax_gap_amt_tab(ln_loop_cnt),  -- 販売単価
--            lt_get_tax_gap_amt_tab(ln_loop_cnt),  -- 標準単価
--            lt_get_tax_code_tab(ln_loop_cnt),     -- 税金コード
--            gn_org_id,                            -- ヘッダーDFFカテゴリ(組織ID)
--            iv_bill_loc_code,                     -- ヘッダーDFF5(ユーザの所属部門)
--            gt_user_name,                         -- ヘッダーDFF6(ユーザ)
--            cv_inv_hold_status_p,                 -- ヘッダーDFF7(請求書保留ステータス)
--            cv_inv_hold_status_w,                 -- ヘッダーDFF8(個別請求書印刷ステータス)
--            cv_inv_hold_status_w,                 -- ヘッダーDFF9(一括請求書印刷ステータス)
--            iv_rec_loc_code,                      -- ヘッダーDFF11(入金拠点)
--            lt_get_note_tab(ln_loop_cnt),         -- 注釈
--            cn_created_by,                        -- 作成者
--            cd_creation_date,                     -- 作成日
--            cn_last_updated_by,                   -- 最終更新者
--            cd_last_update_date,                  -- 最終更新日
--            cn_last_update_login,                 -- 最終更新ログイン
--            gn_org_id,                            -- 営業単位ID
--            lt_get_incl_tax_flag(ln_loop_cnt)     -- 税込金額フラグ
--          );
----
--        EXCEPTION
--          -- *** OTHERS例外ハンドラ ***
--          WHEN OTHERS THEN
--            lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                   iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                   iv_keyword            => cv_dict_cfr_00303005);    -- AR取引OIFテーブル(LINE行)
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,cv_msg_cfr_00016      -- データ挿入エラー
--                                 ,cv_tkn_table          -- トークン'TABLE'
--                                 ,lt_look_dict_word)
--                               ,1
--                               ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--        END;
----
--        --==============================================================
--        --AR取引会計配分用OIF登録処理(REV行)
--        --==============================================================
--        --AR取引会計配分用OIF登録(REV行)
--        BEGIN
--          INSERT INTO ra_interface_distributions_all(
--            interface_line_context,                 -- 取引明細コンテキスト値
--            interface_line_attribute1,              -- 取引明細DFF1
--            interface_line_attribute2,              -- 取引明細DFF2
--            account_class,                          -- 勘定科目区分
--            amount,                                 -- 金額
--            percent,                                -- パーセント
--            code_combination_id,                    -- 勘定科目組合せID
--            segment1,                               -- セグメント1
--            segment2,                               -- セグメント2
--            segment3,                               -- セグメント3
--            segment4,                               -- セグメント4
--            segment5,                               -- セグメント5
--            segment6,                               -- セグメント6
--            segment7,                               -- セグメント7
--            segment8,                               -- セグメント8
--            attribute_category,                     -- DFFカテゴリ
--            created_by,                             -- 作成者
--            creation_date,                          -- 作成日
--            last_updated_by,                        -- 最終更新者
--            last_update_date,                       -- 最終更新日
--            last_update_login,                      -- 最終更新ログイン
--            org_id                                  -- 営業単位ID
--          ) VALUES (
--            gt_taxd_trx_dtl_cont,                   -- 取引明細コンテキスト値
--            lt_aroif_seq,                           -- 取引明細DFF1
--            TO_CHAR(ln_line_oif_cnt),               -- 取引明細DFF2
--            cv_account_class_rev,                   -- 勘定科目区分
--            lt_get_tax_gap_amt_tab(ln_loop_cnt),    -- 金額
--            100,                                    -- パーセント
--            lt_get_tax_ccid_tab(ln_loop_cnt),       -- 勘定科目組合せID
--            lt_get_tax_segment1_tab(ln_loop_cnt),   -- セグメント1
--            lt_get_tax_segment2_tab(ln_loop_cnt),   -- セグメント2
--            lt_get_tax_segment3_tab(ln_loop_cnt),   -- セグメント3
--            lt_get_tax_segment4_tab(ln_loop_cnt),   -- セグメント4
--            lt_get_tax_segment5_tab(ln_loop_cnt),   -- セグメント5
--            lt_get_tax_segment6_tab(ln_loop_cnt),   -- セグメント6
--            lt_get_tax_segment7_tab(ln_loop_cnt),   -- セグメント7
--            lt_get_tax_segment8_tab(ln_loop_cnt),   -- セグメント8
--            gn_org_id,                              -- DFFカテゴリ
--            cn_created_by,                          -- 作成者
--            cd_creation_date,                       -- 作成日
--            cn_last_updated_by,                     -- 最終更新者
--            cd_last_update_date,                    -- 最終更新日
--            cn_last_update_login,                   -- 最終更新ログイン
--            gn_org_id                               -- 営業単位ID
--          );
----
--        EXCEPTION
--          -- *** OTHERS例外ハンドラ ***
--          WHEN OTHERS THEN
--            lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                   iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                   iv_keyword            => cv_dict_cfr_00303008);
--                                                              -- AR取引会計配分テーブル(REV行)
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
--                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                 ,iv_token_value1 => lt_look_dict_word)
--                               ,1
--                               ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--        END;
----
--        -- AR取引OIF一意キーカウント
--        ln_line_oif_cnt := ln_line_oif_cnt + 1;
----
--        --==============================================================
--        --AR取引OIF登録処理(TAX行)
--        --==============================================================
--        --AR取引OIFデータ登録(TAX行)
--        BEGIN
--          -- AR取引OIF(TAX行)
--          INSERT INTO ra_interface_lines_all(
--            interface_line_context,        -- 取引明細コンテキスト値
--            interface_line_attribute1,     -- 取引明細DFF1
--            interface_line_attribute2,     -- 取引明細DFF2
--            batch_source_name,             -- 取引ソース
--            set_of_books_id,               -- 会計帳簿ID
--            line_type,                     -- 明細タイプ
--            description,                   -- 品目明細摘要
--            currency_code,                 -- 通貨
--            amount,                        -- 金額
--            cust_trx_type_name,            -- 取引タイプ名
--            cust_trx_type_id,              -- 取引タイプID
--            term_name,                     -- 支払条件名
--            term_id,                       -- 支払条件ID
--            orig_system_bill_customer_id,  -- 請求先顧客ID
--            orig_system_bill_address_id,   -- 請求先顧客所在地ID
--            link_to_line_context,          -- リンク先明細コンテキスト
--            link_to_line_attribute1,       -- リンク先明細DFF1
--            link_to_line_attribute2,       -- リンク先明細DFF2
--            conversion_type,               -- 換算タイプ
--            conversion_rate,               -- 換算レート
--            trx_date,                      -- 取引日
--            gl_date,                       -- GL記帳日
--            unit_selling_price,            -- 販売単価
--            unit_standard_price,           -- 標準単価
--            tax_code,                      -- 税金コード
--            header_attribute_category,     -- ヘッダーDFFカテゴリ(組織ID)
--            header_attribute5,             -- ヘッダーDFF5(ユーザの所属部門)
--            header_attribute6,             -- ヘッダーDFF6(ユーザ)
--            header_attribute7,             -- ヘッダーDFF7(請求書保留ステータス)
--            header_attribute8,             -- ヘッダーDFF8(個別請求書印刷ステータス)
--            header_attribute9,             -- ヘッダーDFF9(一括請求書印刷ステータス)
--            header_attribute11,            -- ヘッダーDFF11(入金拠点)
--            comments,                      -- 注釈
--            created_by,                    -- 作成者
--            creation_date,                 -- 作成日
--            last_updated_by,               -- 最終更新者
--            last_update_date,              -- 最終更新日
--            last_update_login,             -- 最終更新ログイン
--            org_id,                        -- 営業単位ID
--            amount_includes_tax_flag       -- 税込金額フラグ
--          ) VALUES (
--            gt_taxd_trx_dtl_cont,                 -- 取引明細コンテキスト値
--            lt_aroif_seq,                         -- 取引明細DFF1
--            ln_line_oif_cnt,                      -- 取引明細DFF2
--            gt_taxd_trx_source,                   -- 取引ソース
--            gn_set_book_id,                       -- 会計帳簿ID
--            cv_line_type_tax,                     -- 明細タイプ
--            gt_taxd_trx_memo_dtl,                 -- 品目明細摘要
--            cv_currency_code,                     -- 通貨
--            0,                                    -- 金額
--            gt_taxd_trx_type,                     -- 取引タイプ名
--            gt_tax_gap_trx_type_id,               -- 取引タイプID
--            iv_term_name,                         -- 支払条件名
--            in_term_id,                           -- 支払条件ID
--            in_cust_acct_id,                      -- 請求先顧客ID
--            in_cust_site_id,                      -- 請求先顧客所在地ID
--            gt_taxd_trx_dtl_cont,                 -- リンク先明細コンテキスト
--            lt_aroif_seq,                         -- リンク先明細DFF1
--            TO_CHAR(ln_line_oif_cnt - 1),         -- リンク先明細DFF2
--            cv_conversion_type,                   -- 換算タイプ
--            cn_conversion_rate,                   -- 換算レート
--            id_cutoff_date,                       -- 取引日
--            id_cutoff_date,                       -- GL記帳日
--            0,                                    -- 販売単価
--            0,                                    -- 標準単価
--            lt_get_tax_code_tab(ln_loop_cnt),     -- 税金コード
--            gn_org_id,                            -- ヘッダーDFFカテゴリ(組織ID)
--            iv_bill_loc_code,                     -- ヘッダーDFF5(ユーザの所属部門)
--            gt_user_name,                         -- ヘッダーDFF6(ユーザ)
--            cv_inv_hold_status_p,                 -- ヘッダーDFF7(請求書保留ステータス)
--            cv_inv_hold_status_w,                 -- ヘッダーDFF8(個別請求書印刷ステータス)
--            cv_inv_hold_status_w,                 -- ヘッダーDFF9(一括請求書印刷ステータス)
--            iv_rec_loc_code,                      -- ヘッダーDFF11(入金拠点)
--            lt_get_note_tab(ln_loop_cnt),         -- 注釈
--            cn_created_by,                        -- 作成者
--            cd_creation_date,                     -- 作成日
--            cn_last_updated_by,                   -- 最終更新者
--            cd_last_update_date,                  -- 最終更新日
--            cn_last_update_login,                 -- 最終更新ログイン
--            gn_org_id,                            -- 営業単位ID
--            lt_get_incl_tax_flag(ln_loop_cnt)     -- 税込金額フラグ
--          );
----
--          -- AR取引OIF一意キーカウント
--          ln_line_oif_cnt := ln_line_oif_cnt + 1;
----
--        EXCEPTION
--          -- *** OTHERS例外ハンドラ ***
--          WHEN OTHERS THEN
--            lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                   iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                   iv_keyword            => cv_dict_cfr_00303006);    -- AR取引OIFテーブル(TAX行)
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
--                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                 ,iv_token_value1 => lt_look_dict_word)
--                               ,1
--                               ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--        END;
----
--      END LOOP tax_gap_loop;
----
--      ln_tab_num := lt_get_segment3_tab.FIRST;
----
--      --AR取引会計配分用OIF登録(REC行)
--      BEGIN
--        INSERT INTO ra_interface_distributions_all(
--          interface_line_context,                 -- 取引明細コンテキスト値
--          interface_line_attribute1,              -- 取引明細DFF1
--          interface_line_attribute2,              -- 取引明細DFF2
--          account_class,                          -- 勘定科目区分
--          percent,                                -- パーセント
--          segment1,                               -- セグメント1
--          segment2,                               -- セグメント2
--          segment3,                               -- セグメント3
--          segment4,                               -- セグメント4
--          segment5,                               -- セグメント5
--          segment6,                               -- セグメント6
--          segment7,                               -- セグメント7
--          segment8,                               -- セグメント8
--          attribute_category,                     -- DFFカテゴリ
--          created_by,                             -- 作成者
--          creation_date,                          -- 作成日
--          last_updated_by,                        -- 最終更新者
--          last_update_date,                       -- 最終更新日
--          last_update_login,                      -- 最終更新ログイン
--          org_id                                  -- 営業単位ID
--        ) VALUES (
--          gt_taxd_trx_dtl_cont,                   -- 取引明細コンテキスト値
--          lt_aroif_seq,                           -- 取引明細DFF1
--          1,                                      -- 取引明細DFF2
--          cv_account_class_rec,                   -- 勘定科目区分
--          100,                                    -- パーセント
--          gt_rec_aff_segment1,                    -- セグメント1
--          gt_rec_aff_segment2,                    -- セグメント2
--          lt_get_segment3_tab(ln_tab_num),        -- セグメント3
--          lt_get_segment4_tab(ln_tab_num),        -- セグメント4
--          gt_rec_aff_segment5,                    -- セグメント5
--          gt_rec_aff_segment6,                    -- セグメント6
--          gt_rec_aff_segment7,                    -- セグメント7
--          gt_rec_aff_segment8,                    -- セグメント8
--          gn_org_id,                              -- DFFカテゴリ
--          cn_created_by,                          -- 作成者
--          cd_creation_date,                       -- 作成日
--          cn_last_updated_by,                     -- 最終更新者
--          cd_last_update_date,                    -- 最終更新日
--          cn_last_update_login,                   -- 最終更新ログイン
--          gn_org_id                               -- 営業単位ID
--        );
----
--      --対象件数(AR取引OIF登録件数)カウントアップ
--      gn_target_aroif_cnt := gn_target_aroif_cnt + 1;
----
--      EXCEPTION
--        -- *** OTHERS例外ハンドラ ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303007);
--                                                            -- AR取引会計配分テーブル(REC行)
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                ,iv_name         => cv_msg_cfr_00016      -- データ挿入エラー
--                                ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                ,iv_token_value1 => lt_look_dict_word)
--                               ,1
--                               ,5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
----
--    END IF;
----
--  EXCEPTION
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END ins_aroif_data;
-- Modify 2009.09.29 Ver1.5 End
--
-- Modify 2009.09.29 Ver1.5 Start
--  /**********************************************************************************
--   * Procedure Name   : start_auto_invoice
--   * Description      : 自動インボイス起動処理(A-6)
--   ***********************************************************************************/
--  PROCEDURE start_auto_invoice(
--    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
--    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
--    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
--  )
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_auto_invoice'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_target_cnt       NUMBER;           -- 対象件数
--    ln_request_id       NUMBER;           -- 起動コンカレント要求ID
--    lv_conc_err_flg     VARCHAR2(1);      -- コンカレントエラーフラグ
--    lb_request_status   BOOLEAN;          -- コンカレントステータス
--    lv_rphase           VARCHAR2(255);    -- コンカレント終了待機OUTパラメータ
--    lv_dphase           VARCHAR2(255);    -- コンカレント終了待機OUTパラメータ
--    lv_rstatus          VARCHAR2(255);    -- コンカレント終了待機OUTパラメータ
--    lv_dstatus          VARCHAR2(255);    -- コンカレント終了待機OUTパラメータ
--    lv_message          VARCHAR2(32000);  -- コンカレント終了待機OUTパラメータ
--    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
----
--    -- *** ローカル・カーソル ***
----
--    -- 請求ヘッダデータカーソル
--    CURSOR get_inv_err_header_cur(
--      iv_request_id    VARCHAR2
--    )
--    IS
--      SELECT xxih.invoice_id    invoice_id
--      FROM   xxcfr_invoice_headers  xxih                  -- 請求ヘッダ情報テーブル
--      WHERE  EXISTS (
--               SELECT xxil.invoice_id
--               FROM   xxcfr_invoice_lines   xxil          -- 請求明細情報テーブル
--               WHERE  xxih.invoice_id = xxil.invoice_id
--               )
--      AND    xxih.request_id = iv_request_id              -- コンカレント要求ID
--      AND    xxih.org_id = gn_org_id                      -- 組織ID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- 会計帳簿ID
--      FOR UPDATE NOWAIT
--    ;
----
--    TYPE get_del_invoice_id_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    lt_del_invoice_id_tab            get_del_invoice_id_ttype;
----
--    -- *** ローカル・レコード ***
----
--    -- *** ローカル例外 ***
--    auto_inv_expt       EXCEPTION;      -- 自動インボイス起動エラー
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ローカル変数の初期化
--    ln_target_cnt     := 0;
--    lv_conc_err_flg   := 'N';
----
--    --==============================================================
--    --自動インボイス起動処理
--    --==============================================================
--    -- コンカレント起動
--    ln_request_id := fnd_request.submit_request(
--                       application => cv_auto_inv_appl_name,     -- アプリケーション
--                       program     => cv_auto_inv_prg_name,      -- プログラム
--                       description => NULL,                      -- 摘要
--                       start_time  => NULL,                      -- 開始時間
--                       sub_request => FALSE,                     -- サブ要求ID
--                       argument1   => 1,                         -- 発生数
--                       argument2   => gt_tax_gap_trx_source_id,  -- 税差額要取引ソースID
--                       argument3   => gt_taxd_trx_source,        -- 税差額要取引ソース名
--                       argument4   => gd_process_date,           -- デフォルト日付
--                       argument5   => NULL,                      -- 取引フレックスフィールド
--                       argument6   => NULL,                      -- 取引タイプ
--                       argument7   => NULL,                      -- (自)請求先顧客番号
--                       argument8   => NULL,                      -- (至)請求先顧客番号
--                       argument9   => NULL,                      -- (自)請求先顧客名
--                       argument10  => NULL,                      -- (至)請求先顧客名
--                       argument11  => NULL,                      -- (自)GL記帳日 
--                       argument12  => NULL,                      -- (至)GL記帳日
--                       argument13  => NULL,                      -- (自)出荷日 
--                       argument14  => NULL,                      -- (至)出荷日
--                       argument15  => NULL,                      -- (自)取引番号
--                       argument16  => NULL,                      -- (至)取引番号
--                       argument17  => NULL,                      -- (自)受注番号
--                       argument18  => NULL,                      -- (至)受注番号
--                       argument19  => NULL,                      -- (自)請求日 
--                       argument20  => NULL,                      -- (至)請求日
--                       argument21  => NULL,                      -- (自)出荷先顧客番号 
--                       argument22  => NULL,                      -- (至)出荷先顧客番号
--                       argument23  => NULL,                      -- (自)出荷先顧客名
--                       argument24  => NULL,                      -- (至)出荷先顧客名
--                       argument25  => 'Y',                       -- (自)取引日を基準に支払期日計算
--                       argument26  => NULL,                      -- (至) 支払期日修正日数
--                       argument27  => gn_org_id                  -- 組織ID
--                     );
----
--    -- 戻り値(コンカレント要求ID)の判断
--    -- コンカレントが正常に発行された場合
--    IF (ln_request_id != 0) THEN
----
--      -- 処理を確定
--      COMMIT;
----
--      -- コンカレントの終了まで待機
--      lb_request_status := fnd_concurrent.wait_for_request(
--                             request_id => ln_request_id,         -- 要求ID
--                             interval   => gt_taxd_inv_prg_itvl,  -- チェック待機秒数
--                             max_wait   => gt_taxd_inv_prg_wait,  -- 要求完了待機最大秒数
--                             phase      => lv_rphase ,            -- 要求フェーズ
--                             status     => lv_rstatus ,           -- 要求ステータス
--                             dev_phase  => lv_dphase,             -- 要求フェーズコード
--                             dev_status => lv_dstatus,            -- 要求ステータスコード
--                             message    => lv_message             -- 完了メッセージ
--                           );
----
--      -- 戻り値がFALSEの場合
--      IF (lb_request_status = FALSE ) THEN
--        -- エラーメッセージ引数取得
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                               iv_keyword            => cv_dict_cfr_00303010);
--                                 -- 自動インボイス・マスター・プログラム処理
--        -- エラーメッセージ取得
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00012      -- コンカレント起動エラーメッセージ
--                               ,iv_token_name1  => cv_tkn_prg_name       -- トークン'PROGRAM_NAME'
--                               ,iv_token_value1 => lt_look_dict_word
--                               ,iv_token_name2  => cv_tkn_sqlerrm        -- トークン'SQLERRM'
--                               ,iv_token_value2 => SQLERRM)
--                             ,1
--                             ,5000);
--        lv_errbuf := lv_errmsg;
----
--        -- エラーメッセージ出力
--        fnd_file.put_line(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--        );
----
--        -- エラーフラグをセット
--        lv_conc_err_flg := 'Y';
----
--      END IF;
----
--      -- OUTパラメータ.状態が完了かつ
--      -- OUTパラメータ.ステータスが正常以外の場合
--      IF   (lv_dphase  != cv_conc_phase_cmplt) 
--        OR (lv_dstatus != cv_conc_status_norml)
--      THEN
--        -- エラーメッセージ出力
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00043      -- 自動インボイス処理エラーメッセージ
--                               ,iv_token_name1  => cv_tkn_req_id         -- トークン'PROGRAM_NAME'
--                               ,iv_token_value1 => TO_CHAR(ln_request_id))
--                             ,1
--                             ,5000);
--        lv_errbuf := lv_errmsg;
----
--        -- エラーメッセージ出力
--        fnd_file.put_line(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--        );
----
--        -- エラーフラグをセット
--        lv_conc_err_flg := 'Y';
----
--      END IF;
----
--    -- コンカレントが正常に発行されなかった(要求ID = 0)場合
--    ELSE
--      -- エラーメッセージ出力
--      lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303010);
--                                                            -- 自動インボイス・マスター・プログラム処理
----
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                             ,iv_name         => cv_msg_cfr_00012      -- コンカレント起動エラーメッセージ
--                             ,iv_token_name1  => cv_tkn_prg_name       -- トークン'PROGRAM_NAME'
--                             ,iv_token_value1 => lt_look_dict_word
--                             ,iv_token_name2  => cv_tkn_sqlerrm        -- トークン'SQLERRM'
--                             ,iv_token_value2 => SQLERRM)
--                           ,1
--                           ,5000);
--      lv_errbuf := lv_errmsg;
----
--      -- エラーメッセージ出力
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
----
--      -- エラーフラグをセット
--      lv_conc_err_flg := 'Y';
----
--    END IF;
----
--    -- 自動インボイス処理でエラーが発生した場合
--    IF (lv_conc_err_flg = 'Y') THEN
--      --==============================================================
--      -- 自動インボイスエラー時処理
--      --==============================================================
--      -- カーソルオープン
--      OPEN get_inv_err_header_cur(
--             gt_target_request_id
--           );
----
--      -- データの一括取得
--      FETCH get_inv_err_header_cur
--      BULK COLLECT INTO lt_del_invoice_id_tab;
----
--      -- 処理件数のセット
--      ln_target_cnt := lt_del_invoice_id_tab.COUNT;
----
--      -- カーソルクローズ
--      CLOSE get_inv_err_header_cur;
----
--      -- 対象データが存在する場合レコードを削除する
--      IF (ln_target_cnt > 0) THEN
----
--        -- 請求明細情報テーブル削除処理
--        BEGIN
--          <<del_invoice_lines_loop>>
--          FORALL ln_loop_cnt IN 1..ln_target_cnt
--            DELETE FROM xxcfr_invoice_lines
--            WHERE invoice_id = lt_del_invoice_id_tab(ln_loop_cnt);
----
--        EXCEPTION
--          -- *** OTHERS例外ハンドラ ***
--          WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00007      -- テーブル削除エラー
--                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
--                                                                           -- 請求明細情報テーブル
--                               ,1
--                               ,5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--        END;
----
--        -- 請求ヘッダ情報テーブル削除処理
--        BEGIN
--          <<del_invoice_header_loop>>
--          FORALL ln_loop_cnt IN 1..ln_target_cnt
--            DELETE FROM xxcfr_invoice_headers
--            WHERE invoice_id = lt_del_invoice_id_tab(ln_loop_cnt);
----
--        EXCEPTION
--          -- *** OTHERS例外ハンドラ ***
--          WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00007      -- テーブル削除エラー
--                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                           -- 請求ヘッダ情報テーブル
--                               ,1
--                               ,5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--        END;
----
--        -- 請求データ削除処理をコミット
--        COMMIT;
----
--        -- メッセージ取得
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr      -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00060    -- 請求データ削除メッセージ
--                               ,iv_token_name1  => cv_tkn_req_id       -- トークン'REQUEST_ID'
--                               ,iv_token_value1 => gt_target_request_id)
--                             ,1
--                             ,5000);
----
--        -- 自動インボイス起動エラーを発生
--        RAISE auto_inv_expt;
----
--      END IF;
----
--    END IF;
----
--  EXCEPTION
--    -- *** 自動インボイス起動エラーハンドラ ***
--    WHEN auto_inv_expt THEN
--      -- 自動インボイスエラーフラグをセット
--      gv_auto_inv_err_flag := 'Y';
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** テーブルロックエラーハンドラ ***
--    WHEN lock_expt THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                             ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
--                             ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                       -- 請求ヘッダ情報テーブル
--                           ,1
--                           ,5000);
--      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END start_auto_invoice;
-- Modify 2009.09.29 Ver1.5 End
--
-- Modify 2009.09.29 Ver1.5 Start
--  /**********************************************************************************
--   * Procedure Name   : end_auto_invoice
--   * Description      : 自動インボイス終了処理(A-7)
--   ***********************************************************************************/
--  PROCEDURE end_auto_invoice(
--    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
--    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
--    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
--  )
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_auto_invoice'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_target_cnt       NUMBER;         -- 対象件数
--    ln_del_target_cnt   NUMBER;         -- 削除対象件数
----
--    -- *** ローカル・カーソル ***
--    -- AR取引OIFエラー抽出カーソル
--    CURSOR get_aroif_err_cur
--    IS
--      SELECT DISTINCT
--             hzca.cust_account_id                           cust_account_id,  -- 請求先顧客ID
--             hzca.account_number                            account_number,   -- 請求先顧客コード
--             xxcfr_common_pkg.get_cust_account_name(
--               hzca.account_number,
--               cv_get_acct_name_f)                          customer_name     -- 請求先顧客名
--      FROM   hz_cust_accounts        hzca                       -- 顧客マスタ
--      WHERE  EXISTS (SELECT 'X'
--                     FROM   ra_interface_lines_all  rila            -- AR取引OIF
--                           ,xxcfr_tax_gap_trx_list  xxgt            -- 税差額取引作成
--                           ,hz_cust_accounts        ihzc            -- 顧客マスタ
--                     WHERE  xxgt.request_id = gt_target_request_id  -- 要求ID
--                     AND    rila.interface_line_context = gt_taxd_trx_dtl_cont -- コンテキスト値(税差額)
--                     AND    rila.line_type = cv_line_type_line                 -- 明細タイプ(LINE)
--                     AND    xxgt.bill_cust_code = ihzc.account_number
--                     AND    rila.orig_system_bill_customer_id = ihzc.cust_account_id
--                     AND    rila.orig_system_bill_customer_id = hzca.cust_account_id)
--      ;
----
--    TYPE get_cust_account_id_ttype  IS TABLE OF hz_cust_accounts.cust_account_id%TYPE
--                                      INDEX BY PLS_INTEGER;
--    TYPE get_account_number_ttype   IS TABLE OF hz_cust_accounts.account_number%TYPE
--                                      INDEX BY PLS_INTEGER;
--    TYPE get_customer_name_ttype    IS TABLE OF hz_parties.party_name%TYPE
--                                      INDEX BY PLS_INTEGER;
--    lt_get_cust_acct_id_tab         get_cust_account_id_ttype;
--    lt_get_acct_number_tab          get_account_number_ttype;
--    lt_get_cust_name_tab            get_customer_name_ttype;
----
----
--    -- 請求ヘッダデータカーソル
--    CURSOR get_aroif_err_data_cur(
--      iv_request_id    VARCHAR2,
--      iv_cust_acct_id  NUMBER
--    )
--    IS
--      SELECT xxih.invoice_id    invoice_id
--      FROM   xxcfr_invoice_headers  xxih                  -- 請求ヘッダ情報テーブル
--      WHERE  EXISTS (
--               SELECT xxil.invoice_id
--               FROM   xxcfr_invoice_lines   xxil          -- 請求明細情報テーブル
--               WHERE  xxih.invoice_id = xxil.invoice_id
--               )
--      AND    xxih.request_id = iv_request_id              -- コンカレント要求ID
--      AND    xxih.org_id = gn_org_id                      -- 組織ID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- 会計帳簿ID
--      AND    xxih.bill_cust_account_id = iv_cust_acct_id  -- 請求先顧客ID
--      FOR UPDATE NOWAIT
--    ;
----
--    TYPE get_del_invoice_id_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    lt_del_invoice_id_tab           get_del_invoice_id_ttype;  -- 請求データ内部ID
----
--    -- *** ローカル・レコード ***
----
--    -- *** ローカル例外 ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ローカル変数の初期化
--    ln_target_cnt     := 0;
--    ln_del_target_cnt := 0;
----
--    --==============================================================
--    --AR取引OIFエラーデータ抽出カーソル
--    --==============================================================
--    -- AR取引OIFエラー抽出カーソルオープン
--    OPEN get_aroif_err_cur;
----
--    -- データの一括取得
--    FETCH get_aroif_err_cur
--    BULK COLLECT INTO lt_get_cust_acct_id_tab,
--                      lt_get_acct_number_tab ,
--                      lt_get_cust_name_tab
--    ;
----
--    -- 処理件数のセット
--    ln_target_cnt := lt_get_cust_acct_id_tab.COUNT;
----
--    -- カーソルクローズ
--    CLOSE get_aroif_err_cur;
----
--    --==============================================================
--    --エラーデータログ出力処理
--    --==============================================================
--    -- 対象データが存在時
--    IF (ln_target_cnt > 0) THEN
----
--      <<aroif_err_loop>>
--      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--        -- 警告データ件数をカウント
--        gn_warn_cnt := gn_warn_cnt + 1;
--        -- 警告フラグをセットする。
--        gv_conc_status := cv_status_warn;
----
--        -- エラーメッセージを取得
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr      -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00044    -- 請求データ削除メッセージ
--                               ,iv_token_name1  => cv_tkn_cust_code    -- トークン'CUST_CODE'
--                               ,iv_token_value1 => lt_get_acct_number_tab(ln_loop_cnt)
--                               ,iv_token_name2  => cv_tkn_cust_name    -- トークン'CUST_NAME'
--                               ,iv_token_value2 => lt_get_cust_name_tab(ln_loop_cnt))
--                             ,1
--                             ,5000);
----
--        -- エラーメッセージ出力
--        fnd_file.put_line(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--        );
----
--        --==============================================================
--        --エラー請求データ削除処理
--        --==============================================================
--        -- 請求ヘッダデータカーソル
--        OPEN get_aroif_err_data_cur(
--               gt_target_request_id,
--               lt_get_cust_acct_id_tab(ln_loop_cnt)
--             );
----
--        -- データの一括取得
--        FETCH get_aroif_err_data_cur
--        BULK COLLECT INTO lt_del_invoice_id_tab;
----
--        -- 削除処理件数のセット
--        ln_del_target_cnt := lt_del_invoice_id_tab.COUNT;
----
--        -- 請求ヘッダデータ削除件数
--        gn_target_del_head_cnt := gn_target_del_head_cnt + ln_del_target_cnt;
----
--        -- カーソルクローズ
--        CLOSE get_aroif_err_data_cur;
----
--        -- 削除対象データが存在する場合レコードを削除する
--        IF (ln_del_target_cnt > 0) THEN
----
--          -- 請求明細情報テーブル削除処理
--          BEGIN
--            <<del_invoice_lines_loop>>
--            FOR ln_loop_cnt IN 1..ln_del_target_cnt LOOP
--              -- 請求明細データ削除
--              DELETE FROM xxcfr_invoice_lines
--              WHERE invoice_id = lt_del_invoice_id_tab(ln_loop_cnt);
----
--              -- 請求明細データ削除件数カウント
--              gn_target_del_line_cnt := gn_target_del_line_cnt + SQL%ROWCOUNT;
----
--            END LOOP del_invoice_lines_loop;
----
--          EXCEPTION
--            -- *** OTHERS例外ハンドラ ***
--            WHEN OTHERS THEN
--            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                    iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                   ,iv_name         => cv_msg_cfr_00007      -- テーブル削除エラー
--                                   ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                   ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
--                                                                             -- 請求明細情報テーブル
--                                 ,1
--                                 ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--          END;
----
--          -- 請求ヘッダ情報テーブル削除処理
--          BEGIN
--            <<del_invoice_header_loop>>
--            FORALL ln_loop_cnt IN 1..ln_del_target_cnt
--              DELETE FROM xxcfr_invoice_headers
--              WHERE invoice_id = lt_del_invoice_id_tab(ln_loop_cnt);
----
--          EXCEPTION
--            -- *** OTHERS例外ハンドラ ***
--            WHEN OTHERS THEN
--            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                    iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                   ,iv_name         => cv_msg_cfr_00007      -- テーブル削除エラー
--                                   ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                                   ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                             -- 請求ヘッダ情報テーブル
--                                 ,1
--                                 ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--          END;
----
--        END IF;
----
--      END LOOP aroif_err_loop;
----
--    END IF;
----
--  EXCEPTION
--    -- *** テーブルロックエラーハンドラ ***
--    WHEN lock_expt THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                             ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
--                             ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                       -- 請求ヘッダ情報テーブル
--                           ,1
--                           ,5000);
--      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END end_auto_invoice;
-- Modify 2009.09.29 Ver1.5 End
--
-- Modify 2009.09.29 Ver1.5 Start
--  /**********************************************************************************
--   * Procedure Name   : update_inv_header
--   * Description      : 請求ヘッダ情報更新処理(A-8)
--   ***********************************************************************************/
--  PROCEDURE update_inv_header(
--    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
--    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
--    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
--  )
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_inv_header'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_target_cnt       NUMBER;                             -- 対象件数
----
--    -- *** ローカル・カーソル ***
--    -- 請求ヘッダ情報テーブルロックカーソル
--    CURSOR get_inv_header_lock_cur
--    IS
--      SELECT xxih.invoice_id    invoice_id
--      FROM   xxcfr_invoice_headers xxih                   -- 請求ヘッダ情報テーブル
--      WHERE  xxih.request_id = gt_target_request_id       -- コンカレント要求ID
--      AND    xxih.org_id = gn_org_id                      -- 組織ID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- 会計帳簿ID
--      AND    xxih.tax_gap_trx_id IS NULL                  -- 税差額取引ID
--      AND    xxih.tax_type = cv_tax_div_outtax            -- 消費税区分(外税)
--      FOR UPDATE NOWAIT
--    ;
----
--    TYPE get_upd_invoice_id_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    lt_upd_invoice_id_tab           get_upd_invoice_id_ttype;  -- 請求データ内部ID
----
--    -- *** ローカル・レコード ***
----
--    -- *** ローカル例外 ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ローカル変数の初期化
--    ln_target_cnt     := 0;
----
--    --==============================================================
--    --請求ヘッダ情報テーブル更新処理
--    --==============================================================
--    -- 請求ヘッダ情報テーブルロック
--    BEGIN
----
--      -- 請求ヘッダ情報テーブルロックカーソルオープン
--      OPEN get_inv_header_lock_cur;
----
--      -- データの一括取得
--      FETCH get_inv_header_lock_cur
--      BULK COLLECT INTO lt_upd_invoice_id_tab;
----
--      -- 処理件数のセット
--      ln_target_cnt := lt_upd_invoice_id_tab.COUNT;
----
--      -- カーソルクローズ
--      CLOSE get_inv_header_lock_cur;
----
--    EXCEPTION
--      -- *** OTHERS例外ハンドラ ***
--      WHEN OTHERS THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
--                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                         -- 請求ヘッダ情報テーブル
--                             ,1
--                             ,5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE lock_expt;
--    END;
----
--    BEGIN
--      -- 請求ヘッダ情報テーブル更新
--      UPDATE xxcfr_invoice_headers
--      SET    tax_gap_trx_id = (                   -- 税差額取引ID
--               SELECT MAX(rcta.customer_trx_id)
--               FROM   ra_customer_trx_all   rcta
--               WHERE  rcta.batch_source_id = gt_tax_gap_trx_source_id                        -- 取引ソースID
--               AND    rcta.bill_to_customer_id = xxcfr_invoice_headers.bill_cust_account_id  -- 請求先顧客ID
--               AND    rcta.trx_date = xxcfr_invoice_headers.cutoff_date                      -- 取引日
--               AND    rcta.org_id = xxcfr_invoice_headers.org_id                             -- 組織ID
--               AND    rcta.set_of_books_id = xxcfr_invoice_headers.set_of_books_id           -- 会計帳簿ID
--               )
--      WHERE  request_id = gt_target_request_id       -- コンカレント要求ID
--      AND    org_id = gn_org_id                      -- 組織ID
--      AND    set_of_books_id = gn_set_book_id        -- 会計帳簿ID
--      AND    tax_gap_trx_id IS NULL                  -- 税差額取引ID
--      AND    tax_type = cv_tax_div_outtax            -- 消費税区分(外税)
--      ;
----
--    EXCEPTION
--      -- *** OTHERS例外ハンドラ ***
--      WHEN OTHERS THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00017      -- テーブル更新エラー
--                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                         -- 請求ヘッダ情報テーブル
--                             ,1
--                             ,5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
----
--  EXCEPTION
--    -- *** テーブルロックエラーハンドラ ***
--    WHEN lock_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END update_inv_header;
-- Modify 2009.09.29 Ver1.5 End
--
  /**********************************************************************************
   * Procedure Name   : update_trx_status
   * Description      : 取引データステータス更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE update_trx_status(
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_trx_status'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt       NUMBER;                             -- 対象件数
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ローカル・カーソル ***
    -- 取引テーブルロックカーソル
    CURSOR get_cust_trx_lock_cur
    IS
-- Modify 2009.08.03 Ver1.4 Start
--      SELECT rcta.customer_trx_id    customer_trx_id
      SELECT /*+ LEADING(xiit)
                 USE_NL(rcta)
                 INDEX(xxih XXCFR_INVOICE_HEADERS_N02)
                 INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
             */
             rcta.customer_trx_id    customer_trx_id
-- Modify 2009.08.03 Ver1.4 End
      FROM   ra_customer_trx_all     rcta,                -- 取引テーブル
             xxcfr_invoice_headers   xxih,                -- 請求ヘッダ情報テーブル
             xxcfr_inv_info_transfer xiit                 -- 請求情報引渡テーブル
      WHERE  rcta.set_of_books_id = xxih.set_of_books_id           -- 会計帳簿ID
      AND    rcta.org_id = xxih.org_id                             -- 組織ID
      AND    rcta.bill_to_customer_id = xxih.bill_cust_account_id  -- 請求先顧客ID
      AND    rcta.trx_date <= xxih.cutoff_date                     -- 取引日
      AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                 cv_inv_hold_status_r)             -- 請求書保留ステータス
      AND    xxih.request_id = xiit.target_request_id              -- 要求ID
-- Modify 2012.11.06 Ver1.120 Start
      AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- 夜間手動判断区分が'2'(夜間)
      AND     ( xxih.parallel_type      = gn_parallel_type ) )  -- パラレル実行区分が一致
      OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- 夜間手動判断区分が'0'(手動)
      AND     ( xxih.parallel_type     IS NULL ) ) )            -- パラレル実行区分がNULL
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2009.08.03 Ver1.4 Start
--      FOR UPDATE NOWAIT
      FOR UPDATE OF rcta.customer_trx_id NOWAIT -- 取引ヘッダテーブルのみをロック
-- Modify 2009.08.03 Ver1.4 End
    ;
--
-- Modify 2013.01.17 Ver1.130 Start
    -- 取引テーブルロックカーソル(手動実行用)
    CURSOR get_manual_cust_trx_lock_cur
    IS
      SELECT /*+ LEADING(xiit)
                 USE_NL(rcta)
                 INDEX(xxih XXCFR_INVOICE_HEADERS_N02)
                 INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
             */
             rcta.customer_trx_id    customer_trx_id
      FROM   ra_customer_trx_all     rcta,                -- 取引テーブル
             xxcfr_invoice_headers   xxih,                -- 請求ヘッダ情報テーブル
             xxcfr_inv_info_transfer xiit                 -- 請求情報引渡テーブル
      WHERE  rcta.set_of_books_id = xxih.set_of_books_id           -- 会計帳簿ID
      AND    rcta.org_id = xxih.org_id                             -- 組織ID
      AND    rcta.bill_to_customer_id = xxih.bill_cust_account_id  -- 請求先顧客ID
      AND    rcta.trx_date <= xxih.cutoff_date                     -- 取引日
      AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                 cv_inv_hold_status_r)             -- 請求書保留ステータス
      AND    xxih.request_id = xiit.target_request_id              -- 要求ID
      AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- 夜間手動判断区分が'2'(夜間)
      AND     ( xxih.parallel_type      = gn_parallel_type ) )  -- パラレル実行区分が一致
      OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- 夜間手動判断区分が'0'(手動)
      AND     ( xxih.parallel_type     IS NULL ) ) )            -- パラレル実行区分がNULL
      AND  ( 
             -- 請求ヘッダデータ作成パラメータ請求先顧客に紐付く納品先顧客を処理対象とする
             ( EXISTS (
                 SELECT  'X'
                 FROM    hz_cust_acct_relate    bill_hcar
                        ,(
                   SELECT  bill_hzca.account_number    bill_account_number
                          ,ship_hzca.account_number    ship_account_number
                          ,bill_hzca.cust_account_id   bill_account_id
                          ,ship_hzca.cust_account_id   ship_account_id
                   FROM    hz_cust_accounts          bill_hzca
                          ,hz_cust_acct_sites        bill_hzsa
                          ,hz_cust_site_uses         bill_hsua
                          ,hz_cust_accounts          ship_hzca
                          ,hz_cust_acct_sites        ship_hasa
                          ,hz_cust_site_uses         ship_hsua
                   WHERE   bill_hzca.cust_account_id   = bill_hzsa.cust_account_id
                   AND     bill_hzsa.cust_acct_site_id = bill_hsua.cust_acct_site_id
                   AND     ship_hzca.cust_account_id   = ship_hasa.cust_account_id
                   AND     ship_hasa.cust_acct_site_id = ship_hsua.cust_acct_site_id
                   AND     ship_hsua.bill_to_site_use_id = bill_hsua.site_use_id
                   AND     ship_hzca.customer_class_code = '10'
                   AND     bill_hsua.site_use_code = 'BILL_TO'
                   AND     bill_hsua.status = 'A'
                   AND     ship_hsua.status = 'A'
                 )  ship_cust_info
                 WHERE   rcta.ship_to_customer_id = ship_cust_info.ship_account_id
                 AND     ship_cust_info.bill_account_id = bill_hcar.cust_account_id(+)
                 AND     bill_hcar.related_cust_account_id(+) = ship_cust_info.ship_account_id
                 AND     bill_hcar.attribute1(+) = '1'
                 AND     bill_hcar.status(+)     = 'A'
               AND     ship_cust_info.bill_account_number = gt_bill_acct_code )
             )
             -- または、請求ヘッダデータ作成パラメータ請求先顧客が14番顧客の単独で存在する場合は処理対象とする
         OR ( EXISTS (
                SELECT  'X'
                FROM    hz_cust_accounts          bill_hzca
                WHERE   bill_hzca.cust_account_id = rcta.bill_to_customer_id
                AND     bill_hzca.account_number = gt_bill_acct_code
                AND     rcta.ship_to_customer_id IS NULL )
            )
         )
      FOR UPDATE OF rcta.customer_trx_id NOWAIT -- 取引ヘッダテーブルのみをロック
    ;
-- Modify 2013.01.17 Ver1.130 End
--
    TYPE get_upd_trx_id_ttype   IS TABLE OF ra_customer_trx_all.customer_trx_id%TYPE
                                            INDEX BY PLS_INTEGER;
    lt_upd_trx_id_tab           get_upd_trx_id_ttype;  -- 取引テーブル内部ID
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
-- Modify 2009.08.03 Ver1.4 Start
    lt_upd_trx_id_tab.DELETE;
-- Modify 2009.08.03 Ver1.4 End
--
    --==============================================================
    --取引テーブルDFF請求書保留ステータス更新処理
    --==============================================================
    -- 取引テーブルロック
--
-- Modify 2013.01.17 Ver1.130 Start
    --夜間手動判断区分の判断（夜間バッチと手動実行で分割）
    IF (gv_batch_on_judge_type = cv_judge_type_batch) THEN
-- Modify 2013.01.17 Ver1.130 Start
    OPEN get_cust_trx_lock_cur;
--
-- Modify 2009.08.03 Ver1.4 Start
--    -- データの一括取得
--    FETCH get_cust_trx_lock_cur
--    BULK COLLECT INTO lt_upd_trx_id_tab;
----
--    -- 処理件数のセット
--    ln_target_cnt := lt_upd_trx_id_tab.COUNT;
----
--    -- カーソルクローズ
--    CLOSE get_cust_trx_lock_cur;
----
--    BEGIN
--      -- 取引テーブルDFF更新
--      UPDATE ra_customer_trx_all
--      SET    attribute7 = cv_inv_hold_status_p    -- 請求書保留ステータス(印刷済)
--      WHERE  customer_trx_id IN (
--               SELECT rcta.customer_trx_id    customer_trx_id
--               FROM   ra_customer_trx_all     rcta,                -- 取引テーブル
--                      xxcfr_invoice_headers   xxih,                -- 請求ヘッダ情報テーブル
--                      xxcfr_inv_info_transfer xiit                 -- 請求情報引渡テーブル
--               WHERE  rcta.set_of_books_id = xxih.set_of_books_id           -- 会計帳簿ID
--               AND    rcta.org_id = xxih.org_id                             -- 組織ID
--               AND    rcta.bill_to_customer_id = xxih.bill_cust_account_id  -- 請求先顧客ID
--               AND    rcta.trx_date <= xxih.cutoff_date                     -- 取引日
--               AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                          cv_inv_hold_status_r)             -- 請求書保留ステータス
--               AND    xxih.request_id = xiit.target_request_id              -- 要求ID
--               )
--      ;
--    EXCEPTION
--      -- *** OTHERS例外ハンドラ ***
--      WHEN OTHERS THEN
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                   iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                   iv_keyword            => cv_dict_cfr_00303011);
--                                                            -- 取引テーブル
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00017      -- テーブル更新エラー
--                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
--                               ,iv_token_value1 => lt_look_dict_word)    -- 取引テーブル
--                             ,1
--                             ,5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--      END;
    <<main_loop>>
    LOOP
      -- 対象データを一括取得(リミット単位)
      FETCH get_cust_trx_lock_cur BULK COLLECT INTO lt_upd_trx_id_tab LIMIT gn_bulk_limit;
      -- 取得できなくなったら終了
      EXIT WHEN lt_upd_trx_id_tab.COUNT < 1;
      --
      BEGIN
        FORALL ln_loop_cnt IN lt_upd_trx_id_tab.FIRST..lt_upd_trx_id_tab.LAST
          UPDATE ra_customer_trx_all rcta
          SET    rcta.attribute7      = cv_inv_hold_status_p    -- 請求書保留ステータス(印刷済)
-- Modify 2009.11.16 Ver1.7 Start
                ,rcta.last_updated_by        = cn_last_updated_by         --最終更新者
                ,rcta.last_update_date       = cd_last_update_date        --最終更新日
                ,rcta.last_update_login      = cn_last_update_login       --最終更新ログイン
                ,rcta.request_id             = cn_request_id              --要求ID
                ,rcta.program_application_id = cn_program_application_id  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                ,rcta.program_id             = cn_program_id              --コンカレントプログラ
                ,rcta.program_update_date    = cd_program_update_date     --ﾌﾟﾛｸﾞﾗﾑ更新日
-- Modify 2009.11.16 Ver1.7 End
          WHERE  rcta.customer_trx_id = lt_upd_trx_id_tab(ln_loop_cnt)
          ;
--
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                     iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                     iv_keyword            => cv_dict_cfr_00303011);
                                                              -- 取引テーブル
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00017      -- テーブル更新エラー
                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                                 ,iv_token_value1 => lt_look_dict_word)    -- 取引テーブル
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
      -- 初期化
      lt_upd_trx_id_tab.DELETE;
--
    END LOOP main_loop;
--
    -- カーソルクローズ
    CLOSE get_cust_trx_lock_cur;
--
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2013.01.17 Ver1.130 Start
    --手動実行用
    ELSE
    -- 請求ヘッダ情報テーブルロックカーソルオープン
    OPEN get_manual_cust_trx_lock_cur;
--
    <<main_manual_loop>>
    LOOP
      -- 対象データを一括取得(リミット単位)
      FETCH get_manual_cust_trx_lock_cur BULK COLLECT INTO lt_upd_trx_id_tab LIMIT gn_bulk_limit;
      -- 取得できなくなったら終了
      EXIT WHEN lt_upd_trx_id_tab.COUNT < 1;
      --
      BEGIN
        FORALL ln_loop_cnt IN lt_upd_trx_id_tab.FIRST..lt_upd_trx_id_tab.LAST
          UPDATE ra_customer_trx_all rcta
          SET    rcta.attribute7      = cv_inv_hold_status_p    -- 請求書保留ステータス(印刷済)
                ,rcta.last_updated_by        = cn_last_updated_by         --最終更新者
                ,rcta.last_update_date       = cd_last_update_date        --最終更新日
                ,rcta.last_update_login      = cn_last_update_login       --最終更新ログイン
                ,rcta.request_id             = cn_request_id              --要求ID
                ,rcta.program_application_id = cn_program_application_id  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                ,rcta.program_id             = cn_program_id              --コンカレントプログラ
                ,rcta.program_update_date    = cd_program_update_date     --ﾌﾟﾛｸﾞﾗﾑ更新日
          WHERE  rcta.customer_trx_id = lt_upd_trx_id_tab(ln_loop_cnt)
            ;
--
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                     iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                     iv_keyword            => cv_dict_cfr_00303011);
                                                              -- 取引テーブル
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00017      -- テーブル更新エラー
                                 ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                                 ,iv_token_value1 => lt_look_dict_word)    -- 取引テーブル
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
    -- 初期化
    lt_upd_trx_id_tab.DELETE;
--
    END LOOP main_manual_loop;
--
    -- カーソルクローズ
    CLOSE get_manual_cust_trx_lock_cur;
--
    END IF;
-- Modify 2013.01.17 Ver1.130 End
--
  EXCEPTION
    -- *** テーブルロックエラーハンドラ ***
    WHEN lock_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( get_manual_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_manual_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00303011);
                                                          -- 取引テーブル
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                             ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                             ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                             ,iv_token_value1 => lt_look_dict_word)    -- 取引テーブル
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( get_manual_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_manual_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( get_manual_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_manual_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_trx_status;
--
-- Ver1.190 Add Start
--
  /**********************************************************************************
   * Procedure Name   : update_invoice_lines
   * Description      : 請求金額更新処理 請求明細情報テーブル(A-11)
   ***********************************************************************************/
  PROCEDURE update_invoice_lines(
    in_invoice_id             IN  NUMBER,       -- 請求書ID
    in_invoice_detail_num     IN  NUMBER,       -- 一括請求書明細No
    in_tax_gap_amount         IN  NUMBER,       -- 税差額
    in_tax_sum1               IN  NUMBER,       -- 税額合計１
    in_tax_sum2               IN  NUMBER,       -- 税額合計２
    in_inv_gap_amount         IN  NUMBER,       -- 本体差額
    in_no_tax_sum1            IN  NUMBER,       -- 税抜合計１
    in_no_tax_sum2            IN  NUMBER,       -- 税抜合計２
    iv_category               IN  VARCHAR2,     -- 内訳分類
    iv_invoice_printing_unit  IN  VARCHAR2,     -- 請求書印刷単位
    iv_customer_for_sum       IN  VARCHAR2,     -- 顧客(集計用)
    iv_tax_div                IN  VARCHAR2,     -- 消費税区分
    ov_errbuf                 OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_invoice_lines'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 請求明細情報テーブル請求金額更新
    BEGIN
--
      UPDATE  xxcfr_invoice_lines  xxil   -- 請求明細情報テーブル
      SET     xxil.tax_gap_amount        = in_tax_gap_amount         -- 税差額
             ,xxil.tax_amount_sum        = in_tax_sum1               -- 税額合計１
             ,xxil.tax_amount_sum2       = in_tax_sum2               -- 税額合計２
             ,xxil.inv_gap_amount        = in_inv_gap_amount         -- 本体差額
             ,xxil.inv_amount_sum        = in_no_tax_sum1            -- 税抜合計１
             ,xxil.inv_amount_sum2       = in_no_tax_sum2            -- 税抜合計２
             ,xxil.category              = iv_category               -- 内訳分類
             ,xxil.invoice_printing_unit = iv_invoice_printing_unit  -- 請求書印刷単位
             ,xxil.customer_for_sum      = iv_customer_for_sum       -- 顧客(集計用)
      WHERE   xxil.invoice_id = in_invoice_id                        -- 一括請求書ID
      AND     xxil.invoice_detail_num = in_invoice_detail_num        -- 一括請求書明細No
      ;
--
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- データ更新エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil)) -- 請求明細情報テーブル
                               ,1
                               ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_invoice_lines;
--
-- Ver1.190 Add End
-- Modify 2013.01.17 Ver1.130 Start
--
  /**********************************************************************************
   * Procedure Name   : get_update_target_bill
   * Description      : 請求更新対象取得処理(A-10)
   ***********************************************************************************/
  PROCEDURE get_update_target_bill(
    ov_target_trx_cnt       OUT NUMBER,       -- 対象取引件数
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_update_target_bill'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
-- Ver1.190 Add Start
    ln_int             PLS_INTEGER := 0;
    lt_invoice_id      xxcfr_invoice_headers.invoice_id%TYPE;     -- 一括請求書ID
    lt_tax_gap_amount  xxcfr_invoice_lines.tax_gap_amount%TYPE;   -- 税差額
    lt_tax_sum1        xxcfr_invoice_lines.tax_amount_sum%TYPE;   -- 税額合計１
    lt_inv_gap_amount  xxcfr_invoice_lines.inv_gap_amount%TYPE;   -- 本体差額
    lt_no_tax_sum1     xxcfr_invoice_lines.inv_amount_sum%TYPE;   -- 税抜合計１
-- Ver1.190 Add End
--
    -- *** ローカル・カーソル ***
    --対象請求書情報データロックカーソル
    CURSOR lock_target_inv_cur
    IS
      SELECT  /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
              xxih.invoice_id         invoice_id    -- 請求書ID
      FROM    xxcfr_invoice_headers xxih            -- 請求ヘッダ情報テーブル
      WHERE   xxih.request_id = gt_target_request_id   -- コンカレント要求ID
-- Ver1.190 Add Start
      AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- 夜間手動判断区分が'2'(夜間)
      AND     ( xxih.parallel_type      = gn_parallel_type ) )  -- パラレル実行区分が一致
      OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- 夜間手動判断区分が'0'(手動)
      AND     ( xxih.parallel_type     IS NULL ) ) )            -- パラレル実行区分がNULL
-- Ver1.190 Add End
      FOR UPDATE NOWAIT
      ;
--
-- Ver1.190 Add Start
   --請求明細情報データロックカーソル
    CURSOR lock_target_inv_lines_cur
    IS
      SELECT  xxil.invoice_id         invoice_id    -- 請求書ID
      FROM    xxcfr_invoice_lines xxil              -- 請求明細情報テーブル
      WHERE   EXISTS (SELECT 1 
                      FROM xxcfr_invoice_headers xxih            -- 請求ヘッダ情報テーブル
                      WHERE  xxih.invoice_id = xxil.invoice_id
                      AND    xxih.request_id = gt_target_request_id   -- コンカレント要求ID
                      AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- 夜間手動判断区分が'2'(夜間)
                      AND     ( xxih.parallel_type      = gn_parallel_type ) )  -- パラレル実行区分が一致
                      OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- 夜間手動判断区分が'0'(手動)
                      AND     ( xxih.parallel_type     IS NULL ) ) )            -- パラレル実行区分がNULL
                     )
      FOR UPDATE NOWAIT
      ;
-- Ver1.190 Add End
--
    --
    CURSOR get_target_inv_cur
    IS
      SELECT  /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
              xxih.invoice_id                 invoice_id    -- 請求書ID
-- Ver1.190 Add Start
             ,MIN(xxil.invoice_detail_num)    invoice_detail_num     -- 一括請求書明細No
-- Ver1.190 Add End
             ,SUM(NVL(xxil.ship_amount, 0))   ship_amount   -- 税抜額合計
             ,SUM(NVL(xxil.tax_amount, 0))    tax_amount    -- 税額合計
             ,SUM(NVL(xxil.ship_amount, 0) + NVL(xxil.tax_amount, 0)) sold_amount  -- 税込額合計
-- Ver1.190 Add Start
             ,flv.attribute2                  category               -- 内訳分類
             ,CASE WHEN hcsu.attribute7 IN ( cv_output_format_1, cv_output_format_4, cv_output_format_5 )
                   THEN
                     DECODE(xcal.invoice_printing_unit,
                            '0',xxil.ship_cust_code,'1',xcal.invoice_code,'2',xxil.ship_cust_code,
                            '3',xxih.bill_cust_code,'4',xcal.invoice_code,'5',xxih.bill_cust_code,
                            '6',xcal.invoice_code,  '7',xcal.invoice_code,'8',xcal20.enclose_invoice_code,
                            '9',xxih.bill_cust_code,'A',xxih.bill_cust_code,'B',xxih.bill_cust_code,
                            'C',xxih.bill_cust_code,'D',xxil.ship_cust_code, null)
                   ELSE NULL
              END                             customer_for_sum       -- 顧客(集計用)
             ,hcsu.attribute7                 output_format          -- 請求書出力形式
             ,xxil.tax_rate                   tax_rate               -- 消費税率
             ,NVL(xxca.invoice_tax_div,'N')   invoice_tax_div        -- 請求書消費税積上げ計算方式
             ,xxca.tax_div                    tax_div                -- 消費税区分
             ,xcal.invoice_printing_unit      invoice_printing_unit  -- 請求書印刷単位
-- Ver1.190 Add End
      FROM    xxcfr_invoice_headers xxih                          -- 請求ヘッダ情報テーブル
             ,xxcfr_invoice_lines   xxil                          -- 請求明細情報テーブル
-- Ver1.190 Add Start
             ,xxcmm_cust_accounts   xxca                          -- 顧客追加情報
             ,hz_cust_accounts      hca                           -- 顧客マスタ
             ,hz_cust_acct_sites    hcas                          -- 顧客所在地
             ,hz_cust_site_uses     hcsu                          -- 顧客使用目的
             ,fnd_lookup_values     flv                           -- 参照表（税分類）
             ,xxcmm_cust_accounts   xcal20                        -- 顧客追加情報(請求書用顧客)
             ,xxcmm_cust_accounts   xcal                          -- 顧客追加情報(納品先顧客)
-- Ver1.190 Add End
      WHERE   xxih.request_id = gt_target_request_id              -- コンカレント要求ID
      AND     xxih.invoice_id = xxil.invoice_id
-- Ver1.190 Add Start
      AND     xxih.bill_cust_account_id = hca.cust_account_id     -- 請求ヘッダ.請求先顧客ID = 顧客マスタ.顧客ID
      AND     hca.cust_account_id       = xxca.customer_id        -- 顧客マスタ.顧客ID = 顧客追加情報.顧客ID
      AND     hca.cust_account_id       = hcas.cust_account_id    -- 顧客マスタ.顧客ID = 顧客所在地.顧客ID
      AND     hcas.cust_acct_site_id    = hcsu.cust_acct_site_id  -- 顧客所在地.顧客所在地ID = 顧客使用目的.顧客所在地ID
      AND     hcsu.site_use_code        = 'BILL_TO'               -- 顧客使用目的.使用目的コード = 請求先 
      AND     hcsu.status               = 'A'                     -- 顧客使用目的.ステータス = 有効 
      AND     flv.lookup_type(+)        = 'XXCFR1_TAX_CATEGORY'   -- 税分類
      AND     flv.lookup_code(+)        = xxil.tax_code           -- 参照表（税分類）.ルックアップコード = 請求明細.税金コード
      AND     flv.language(+)           = USERENV( 'LANG' )
      AND     flv.enabled_flag(+)       = 'Y'
      AND     flv.attribute2(+)         IS NOT NULL               -- 内訳分類
      AND     xxil.ship_cust_code       = xcal.customer_code
      AND     xcal20.customer_code(+)   = xcal.invoice_code
-- Ver1.190 Add End
      GROUP BY xxih.invoice_id
-- Ver1.190 Add Start
              ,flv.attribute2                  -- 内訳分類
              ,CASE WHEN hcsu.attribute7 IN ( cv_output_format_1, cv_output_format_4, cv_output_format_5 )
                    THEN
                      DECODE(xcal.invoice_printing_unit,
                             '0',xxil.ship_cust_code,'1',xcal.invoice_code,'2',xxil.ship_cust_code,
                             '3',xxih.bill_cust_code,'4',xcal.invoice_code,'5',xxih.bill_cust_code,
                             '6',xcal.invoice_code,  '7',xcal.invoice_code,'8',xcal20.enclose_invoice_code,
                             '9',xxih.bill_cust_code,'A',xxih.bill_cust_code,'B',xxih.bill_cust_code,
                             'C',xxih.bill_cust_code,'D',xxil.ship_cust_code, null)
                    ELSE NULL
               END
              ,hcsu.attribute7                 -- 請求書出力形式
              ,xxil.tax_rate                   -- 税率
              ,NVL(xxca.invoice_tax_div,'N')   -- 請求書消費税積上げ計算方式
              ,xxca.tax_div                    -- 消費税区分
              ,xcal.invoice_printing_unit      -- 請求書印刷単位
      ORDER BY 
               invoice_id
              ,category
              ,customer_for_sum
-- Ver1.190 Add End
      ;
--
    -- *** ローカル・レコード ***
--
-- Ver1.190 Add Start
    get_target_inv_rec  get_target_inv_cur%ROWTYPE;
-- Ver1.190 Add End
--
-- Ver1.190 Add Start
    -- *** ローカル・ファンクション ***
    -- 税額合計１（税抜き）算出処理
    FUNCTION calc_tax_sum1(
       it_ship_amount        IN   xxcfr_invoice_lines.ship_amount%TYPE      -- 税抜額合計
      ,it_tax_rate           IN   xxcfr_invoice_lines.tax_rate%TYPE         -- 消費税率
    ) RETURN NUMBER
    IS
--
      ln_tax_sum1  NUMBER;          -- 戻り値：税額合計１
--
    BEGIN
      ln_tax_sum1 := 0;
      -- 少数点以下の端数を切り捨てします。
      ln_tax_sum1 := TRUNC( it_ship_amount * ( it_tax_rate / 100 ) );
--
      RETURN ln_tax_sum1;
    END calc_tax_sum1;
--
    -- *** ローカル・ファンクション ***
    -- 税抜合計１算出処理
    FUNCTION calc_no_tax_sum1(
       it_sold_amount        IN   xxcfr_invoice_lines.sold_amount%TYPE      -- 税込額合計
      ,it_tax_rate           IN   xxcfr_invoice_lines.tax_rate%TYPE         -- 消費税率
    ) RETURN NUMBER
    IS
--
      ln_no_tax_sum1  NUMBER;          -- 戻り値：税抜合計１
--
    BEGIN
      ln_no_tax_sum1 := 0;
      -- 少数点以下の端数を切り捨てします。
      ln_no_tax_sum1 := TRUNC( it_sold_amount / ( it_tax_rate / 100 + 1 ) );
--
      RETURN ln_no_tax_sum1;
    END calc_no_tax_sum1;
-- Ver1.190 Add End
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数の初期化
    ov_target_trx_cnt := 0;
--
    --==============================================================
    --請求テーブルロック情報取得処理
    --==============================================================
    BEGIN
      OPEN lock_target_inv_cur;
--
      CLOSE lock_target_inv_cur;
--
    EXCEPTION
      -- *** テーブルロックエラーハンドラ ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- 請求ヘッダ情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
-- Ver1.190 Add Start
    --==============================================================
    --請求明細テーブルロック情報取得処理
    --==============================================================
    BEGIN
      OPEN lock_target_inv_lines_cur;
--
      CLOSE lock_target_inv_lines_cur;
--
    EXCEPTION
      -- *** テーブルロックエラーハンドラ ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- テーブルロックエラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))  -- 請求明細情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
-- Ver1.190 Add End
-- Ver1.190 Del Start
--    --==============================================================
--    --請求ヘッダ情報テーブル更新処理
--    --==============================================================
--    --対象請求書情報取得カーソルオープン
--    OPEN get_target_inv_cur;
----
---- データの一括取得
--    FETCH get_target_inv_cur 
--    BULK COLLECT INTO gt_get_inv_id_tab
--                     ,gt_get_amt_no_tax_tab
--                     ,gt_get_tax_amt_sum_tab
--                     ,gt_get_amd_inc_tax_tab
--    ;
----
--    -- 処理件数のセット
--    ov_target_trx_cnt := gt_get_inv_id_tab.COUNT;
----
--    --対象請求書情報取得カーソルクローズ
--    CLOSE get_target_inv_cur;
--
-- Ver1.190 Del End
-- Ver1.190 Add Start
    --==============================================================
    --請求明細情報更新処理
    --==============================================================
    --
    <<edit_loop>>
    FOR get_target_inv_rec IN get_target_inv_cur LOOP
--
      IF ( get_target_inv_rec.customer_for_sum IS NOT NULL ) THEN
        --初回、又は、一括請求書IDが変わった場合ブレーク
        IF (
             ( lt_invoice_id IS NULL )
             OR
             ( lt_invoice_id <> get_target_inv_rec.invoice_id )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_int                           := ln_int + 1;                             -- 配列カウントアップ
          gt_get_inv_id_tab(ln_int)        := get_target_inv_rec.invoice_id;          -- 一括請求書ID
          gt_invoice_tax_div_tab(ln_int)   := get_target_inv_rec.invoice_tax_div;     -- 請求書消費税積上げ計算方式
          gt_output_format_tab(ln_int)     := get_target_inv_rec.output_format;       -- 請求書出力形式
          gt_tax_div_tab(ln_int)           := get_target_inv_rec.tax_div;             -- 消費税区分
--
          lt_tax_sum1       := 0;  -- 税額合計１
          lt_no_tax_sum1    := 0;  -- 税抜合計１
          lt_tax_gap_amount := 0;  -- 税差額
          lt_inv_gap_amount := 0;  -- 本体差額
          --
          -- 税抜き（消費税区分：外税、非課税）
          IF ( get_target_inv_rec.tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) ) THEN
            -- 税額合計１（税抜き）算出処理
            IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
               lt_tax_sum1 := calc_tax_sum1( get_target_inv_rec.ship_amount
                                            ,get_target_inv_rec.tax_rate );
            END IF;
            -- 税抜合計１は取得した税抜額合計
            lt_no_tax_sum1 := get_target_inv_rec.ship_amount;
            -- 本体差額は0
            lt_inv_gap_amount := 0;
          --
          -- 税込み（消費税区分：内税(伝票)、内税(単価)）
          ELSIF ( get_target_inv_rec.tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
            -- 税抜合計１算出処理
            IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
              lt_no_tax_sum1 := calc_no_tax_sum1( get_target_inv_rec.sold_amount
                                                 ,get_target_inv_rec.tax_rate );
            END IF;
            -- 税額合計１
            lt_tax_sum1 := get_target_inv_rec.sold_amount - lt_no_tax_sum1;
            -- 本体差額
            -- 請求書消費税積上げ計算方式がYの場合は0
            IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
               lt_inv_gap_amount := 0;
            ELSE
            -- 請求書消費税積上げ計算方式がY以外の場合、税抜合計１ −税抜合計２
               lt_inv_gap_amount := lt_no_tax_sum1 - get_target_inv_rec.ship_amount;
            END IF;
          END IF;
          -- 税差額
          -- 請求書消費税積上げ計算方式がYの場合は0
          IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
             lt_tax_gap_amount := 0;
          ELSE
          -- 請求書消費税積上げ計算方式がY以外の場合、税額合計１ −税額合計２
             lt_tax_gap_amount := lt_tax_sum1 - get_target_inv_rec.tax_amount;
          END IF;
--
          -- 請求ヘッダ更新用にデータを保持します
          gt_tax_gap_amount_tab(ln_int) := lt_tax_gap_amount;                      -- 税差額
          gt_tax_sum1_tab(ln_int)       := lt_tax_sum1;                            -- 税額合計１
          gt_tax_sum2_tab(ln_int)       := get_target_inv_rec.tax_amount;          -- 税額合計２
          gt_inv_gap_amount_tab(ln_int) := lt_inv_gap_amount;                      -- 本体差額
          gt_no_tax_sum1_tab(ln_int)    := lt_no_tax_sum1;                         -- 税抜合計１
          gt_no_tax_sum2_tab(ln_int)    := get_target_inv_rec.ship_amount;         -- 税抜合計２
          lt_invoice_id                 := get_target_inv_rec.invoice_id;          -- ブレークコード設定
--
          -- 請求明細更新(A-11)
          update_invoice_lines(
            get_target_inv_rec.invoice_id,             -- 請求書ID
            get_target_inv_rec.invoice_detail_num,     -- 一括請求書明細No
            lt_tax_gap_amount,                         -- 税差額
            lt_tax_sum1,                               -- 税額合計１
            get_target_inv_rec.tax_amount,             -- 税額合計２
            lt_inv_gap_amount,                         -- 本体差額
            lt_no_tax_sum1,                            -- 税抜合計１
            get_target_inv_rec.ship_amount,            -- 税抜合計２
            get_target_inv_rec.category,               -- 内訳分類
            get_target_inv_rec.invoice_printing_unit,  -- 請求書印刷単位
            get_target_inv_rec.customer_for_sum,       -- 顧客(集計用)
            get_target_inv_rec.tax_div,                -- 消費税区分
            lv_errbuf,                                 -- エラー・メッセージ           --# 固定 #
            lv_retcode,                                -- リターン・コード             --# 固定 #
            lv_errmsg                                  -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
        ELSE
          -- 2レコード目以降
          lt_tax_sum1       := 0;  -- 税額合計１
          lt_no_tax_sum1    := 0;  -- 税抜合計１
          lt_tax_gap_amount := 0;  -- 税差額
          lt_inv_gap_amount := 0;  -- 本体差額
          --
          -- 税抜き（消費税区分：外税、非課税）
          IF ( get_target_inv_rec.tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) ) THEN
            -- 税額合計１（税抜き）算出処理
            IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
               lt_tax_sum1 := calc_tax_sum1( get_target_inv_rec.ship_amount
                                            ,get_target_inv_rec.tax_rate );
            END IF;
            -- 税抜合計１は取得した税抜額合計
            lt_no_tax_sum1 := get_target_inv_rec.ship_amount;
            -- 本体差額は0
            lt_inv_gap_amount := 0;
          --
          -- 税込み（消費税区分：内税(伝票)、内税(単価)）
          ELSIF ( get_target_inv_rec.tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
            -- 税抜合計１算出処理
            IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
              lt_no_tax_sum1 := calc_no_tax_sum1( get_target_inv_rec.sold_amount
                                                 ,get_target_inv_rec.tax_rate );
            END IF;
            -- 税額合計１
            lt_tax_sum1 := get_target_inv_rec.sold_amount - lt_no_tax_sum1;
            -- 本体差額
            -- 請求書消費税積上げ計算方式がYの場合は0
            IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
               lt_inv_gap_amount := 0;
            ELSE
            -- 請求書消費税積上げ計算方式がY以外の場合、税抜合計１ −税抜合計２
               lt_inv_gap_amount := lt_no_tax_sum1 - get_target_inv_rec.ship_amount;
            END IF;
          END IF;
          -- 税差額
          -- 請求書消費税積上げ計算方式がYの場合は0
          IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
             lt_tax_gap_amount := 0;
          ELSE
          -- 請求書消費税積上げ計算方式がY以外の場合、税額合計１ −税額合計２
             lt_tax_gap_amount := lt_tax_sum1 - get_target_inv_rec.tax_amount;
          END IF;
--
          -- 請求ヘッダ更新用にデータを保持します
          gt_tax_gap_amount_tab(ln_int) := gt_tax_gap_amount_tab(ln_int) + lt_tax_gap_amount;                -- 税差額
          gt_tax_sum1_tab(ln_int)       := gt_tax_sum1_tab(ln_int) + lt_tax_sum1;                            -- 税額合計１
          gt_tax_sum2_tab(ln_int)       := gt_tax_sum2_tab(ln_int) + get_target_inv_rec.tax_amount;          -- 税額合計２
          gt_inv_gap_amount_tab(ln_int) := gt_inv_gap_amount_tab(ln_int) + lt_inv_gap_amount;                -- 本体差額
          gt_no_tax_sum1_tab(ln_int)    := gt_no_tax_sum1_tab(ln_int) + lt_no_tax_sum1;                      -- 税抜合計１
          gt_no_tax_sum2_tab(ln_int)    := gt_no_tax_sum2_tab(ln_int) + get_target_inv_rec.ship_amount;      -- 税抜合計２
--
          -- 請求明細更新(A-11)
          update_invoice_lines(
            get_target_inv_rec.invoice_id,             -- 請求書ID
            get_target_inv_rec.invoice_detail_num,     -- 一括請求書明細No
            lt_tax_gap_amount,                         -- 税差額
            lt_tax_sum1,                               -- 税額合計１
            get_target_inv_rec.tax_amount,             -- 税額合計２
            lt_inv_gap_amount,                         -- 本体差額
            lt_no_tax_sum1,                            -- 税抜合計１
            get_target_inv_rec.ship_amount,            -- 税抜合計２
            get_target_inv_rec.category,               -- 内訳分類
            get_target_inv_rec.invoice_printing_unit,  -- 請求書印刷単位
            get_target_inv_rec.customer_for_sum,       -- 顧客(集計用)
            get_target_inv_rec.tax_div,                -- 消費税区分
            lv_errbuf,                                 -- エラー・メッセージ           --# 固定 #
            lv_retcode,                                -- リターン・コード             --# 固定 #
            lv_errmsg                                  -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
        END IF;
      END IF;
--
    END LOOP edit_loop;
--
    -- 処理件数のセット
    ov_target_trx_cnt := gt_get_inv_id_tab.COUNT;
--
-- Ver1.190 Add End
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_update_target_bill;
--
--
  /**********************************************************************************
   * Procedure Name   : update_bill_amount
   * Description      : 請求金額更新処理 請求ヘッダ情報テーブル(A-11)
   ***********************************************************************************/
  PROCEDURE update_bill_amount(
    in_invoice_id           IN  NUMBER,       -- 請求書ID
-- Ver1.190 Del Start
--    in_amt_no_tax           IN  NUMBER,       -- 納品金額
--    in_tax_amt_sum          IN  NUMBER,       -- 消費税金額
--    in_amd_inc_tax          IN  NUMBER,       -- 売上金額
-- Ver1.190 Del End
-- Ver1.190 Add Start
    in_tax_gap_amount       IN  NUMBER,       -- 税差額
    in_tax_amount_sum       IN  NUMBER,       -- 税額合計１
    in_tax_amount_sum2      IN  NUMBER,       -- 税額合計２
    in_inv_gap_amount       IN  NUMBER,       -- 本体差額
    in_inv_amount_sum       IN  NUMBER,       -- 税抜額合計１
    in_inv_amount_sum2      IN  NUMBER,       -- 税抜額合計２
    iv_invoice_tax_div      IN  VARCHAR2,     -- 請求書消費税積上げ計算方式
    iv_output_format        IN  VARCHAR2,     -- 請求書出力形式
    iv_tax_div              IN  VARCHAR2,     -- 税区分
-- Ver1.190 Add End
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_bill_amount'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt       NUMBER;         -- 対象件数
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
-- Ver1.190 Add Start
    lt_inv_gap_amount              xxcfr_invoice_headers.inv_gap_amount%TYPE;              -- 本体差額
    lt_inv_amount_no_tax           xxcfr_invoice_headers.inv_amount_no_tax%TYPE;           -- 税抜請求金額合計
    lt_tax_amount_sum              xxcfr_invoice_headers.tax_amount_sum%TYPE;              -- 税額合計
    lt_inv_amount_includ_tax       xxcfr_invoice_headers.inv_amount_includ_tax%TYPE;       -- 税込請求金額合計
    lt_tax_diff_amount_create_flg  xxcfr_invoice_headers.tax_diff_amount_create_flg%TYPE;  -- 消費税差額作成フラグ
-- Ver1.190 Add End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数の初期化
    ln_target_cnt     := 0;
-- Ver1.190 Add Start
    lt_inv_gap_amount              := 0;
    lt_inv_amount_no_tax           := 0;
    lt_tax_amount_sum              := 0;
    lt_inv_amount_includ_tax       := 0;
    lt_tax_diff_amount_create_flg  := NULL;
-- Ver1.190 Add Start
--
    -- 請求作成対象データ取得
    -- 請求ヘッダ情報と請求明細情報を作成せずに、明細データ削除のみを実施しているパターンがある
    -- 上記の場合は請求ヘッダ更新として件数をカウントアップする必要がある為、取引データから請求作成対象があるか判断する
-- Modify 2013.06.10 Ver1.140 Start
--    BEGIN
--
--      SELECT COUNT('X')               cnt    -- レコード件数
--      INTO   ln_target_cnt
--      FROM   ra_customer_trx_all      rcta
--           , xxcfr_invoice_headers    xxih
--      WHERE  xxih.invoice_id           = in_invoice_id                        -- 請求書ID
--      AND    rcta.trx_date            <= xxih.cutoff_date                     -- 締日
--      AND    rcta.bill_to_customer_id  = xxih.bill_cust_account_id            -- 請求先顧客ID
--      AND    rcta.attribute7 IN (cv_inv_hold_status_o, cv_inv_hold_status_r)  -- 請求書保留ステータス
--      AND    xxih.org_id          = rcta.org_id                               -- 組織ID
--      AND    xxih.set_of_books_id = rcta.set_of_books_id                      -- 会計帳簿ID
--      AND    EXISTS (
--               SELECT  'X'
--               FROM    hz_cust_acct_relate    bill_hcar
--                      ,(
--                 SELECT  bill_hzca.account_number    bill_account_number
--                        ,ship_hzca.account_number    ship_account_number
--                        ,bill_hzca.cust_account_id   bill_account_id
--                        ,ship_hzca.cust_account_id   ship_account_id
--                 FROM    hz_cust_accounts          bill_hzca
--                        ,hz_cust_acct_sites        bill_hzsa
--                        ,hz_cust_site_uses         bill_hsua
--                        ,hz_cust_accounts          ship_hzca
--                        ,hz_cust_acct_sites        ship_hasa
--                        ,hz_cust_site_uses         ship_hsua
--                 WHERE   bill_hzca.cust_account_id   = bill_hzsa.cust_account_id
--                 AND     bill_hzsa.cust_acct_site_id = bill_hsua.cust_acct_site_id
--                 AND     ship_hzca.cust_account_id   = ship_hasa.cust_account_id
--                 AND     ship_hasa.cust_acct_site_id = ship_hsua.cust_acct_site_id
--                 AND     ship_hsua.bill_to_site_use_id = bill_hsua.site_use_id
--                 AND     ship_hzca.customer_class_code = '10'
--                 AND     bill_hsua.site_use_code = 'BILL_TO'
--                 AND     bill_hsua.status = 'A'
--                 AND     ship_hsua.status = 'A'
--               )  ship_cust_info
--               WHERE   rcta.ship_to_customer_id = ship_cust_info.ship_account_id
--               AND     ship_cust_info.bill_account_id = bill_hcar.cust_account_id(+)
--               AND     bill_hcar.related_cust_account_id(+) = ship_cust_info.ship_account_id
--               AND     bill_hcar.attribute1(+) = '1'
--               AND     bill_hcar.status(+)     = 'A'
--               AND     ship_cust_info.bill_account_number = gt_bill_acct_code
--               )
--      ;
--
--    EXCEPTION
--    -- *** OTHERS例外ハンドラ ***
--      WHEN OTHERS THEN
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                               iv_loopup_type_prefix => cv_msg_kbn_cfr,         -- 'XXCFR'
--                               iv_keyword            => cv_dict_cfr_00302009);  -- 対象取引データ件数
--        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cfr,               -- 'XXCFR'
--                               iv_name         => cv_msg_cfr_00015,             -- データ取得エラー
--                               iv_token_name1  => cv_tkn_data,
--                               iv_token_value1 => lt_look_dict_word),
--                             1,
--                             5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
--
-- Modify 2013.06.10 Ver1.140 End
--
-- Ver1.190 Add Start
    -- 税差額を設定する
--    IF ( iv_invoice_tax_div = 'Y' ) THEN
--      lt_tax_gap_amount := 0;
--    ELSE
--      lt_tax_gap_amount := in_tax_gap_amount;
--    END IF;
--
    -- 税額合計
    IF ( iv_invoice_tax_div = 'Y' ) THEN
      lt_tax_amount_sum := in_tax_amount_sum2;  -- 税額合計に税額合計２を設定
    ELSE
      lt_tax_amount_sum := in_tax_amount_sum;   -- 税額合計に税額合計１を設定
    END IF;
    -- 税抜きの場合
    IF ( iv_tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) )  THEN
      lt_inv_gap_amount    := 0;                    -- 本体差額に0を設定
      lt_inv_amount_no_tax := in_inv_amount_sum2;   -- 税抜請求金額合計に税抜額合計２を設定
--
    -- 税込みの場合
    ELSIF ( iv_tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
      IF ( iv_invoice_tax_div = 'Y' ) THEN
        lt_inv_gap_amount    := 0;                  -- 本体差額に0を設定
        lt_inv_amount_no_tax := in_inv_amount_sum2; -- 税抜請求金額合計に税抜額合計２を設定
      ELSE
        lt_inv_gap_amount    := in_inv_gap_amount;  -- 本体差額
        lt_inv_amount_no_tax := in_inv_amount_sum;  -- 税抜請求金額合計に税抜額合計１を設定
      END IF;
    END IF;
--
    -- 税込請求金額合計 = 税抜請求金額合計 ＋ 税額合計
    lt_inv_amount_includ_tax := NVL(lt_inv_amount_no_tax,0) + lt_tax_amount_sum;
    -- 消費税差額作成フラグ
    -- 請求書消費税積上げ計算方式がY以外かつ税差額または本体差額が0またはNULLでない場合
    IF ( iv_invoice_tax_div <> 'Y' AND
         (( NVL(in_tax_gap_amount,0) <> 0 ) OR ( NVL(lt_inv_gap_amount,0) <> 0 )) ) THEN
      lt_tax_diff_amount_create_flg := '0';
    END IF;
-- Ver1.190 Add End
--
    -- 請求ヘッダ情報テーブル請求金額更新
    BEGIN
--
      UPDATE  xxcfr_invoice_headers  xxih -- 請求ヘッダ情報テーブル
-- Ver1.190 Mod Start
--      SET     xxih.inv_amount_no_tax      =  in_amt_no_tax  --税抜請求金額合計
--             ,xxih.tax_amount_sum         =  in_tax_amt_sum --税額合計
--             ,xxih.inv_amount_includ_tax  =  in_amd_inc_tax --税込請求金額合計
      SET    xxih.tax_gap_amount              =  in_tax_gap_amount         -- 税差額
            ,xxih.inv_amount_no_tax           =  lt_inv_amount_no_tax      -- 税抜請求金額合計
            ,xxih.tax_amount_sum              =  lt_tax_amount_sum         -- 税額合計
            ,xxih.inv_amount_includ_tax       =  lt_inv_amount_includ_tax  -- 税込請求金額合計
            ,xxih.inv_gap_amount              =  lt_inv_gap_amount         -- 本体差額
            ,xxih.invoice_tax_div             =  iv_invoice_tax_div        -- 請求書消費税積上げ計算方式
            ,xxih.tax_diff_amount_create_flg  =  lt_tax_diff_amount_create_flg  -- 消費税差額作成フラグ
            ,xxih.tax_rounding_rule           =  cv_tax_rounding_rule_down      -- 税金−端数処理
            ,xxih.output_format               =  iv_output_format          -- 請求書出力形式
-- Ver1.190 Mod End
      WHERE   xxih.invoice_id = in_invoice_id          -- 請求書ID
      ;
--
      --==============================================================
      --請求ヘッダ更新件数カウントアップ
      --==============================================================
      -- 請求ヘッダ情報を更新している、かつ請求作成対象がない場合、
      -- 請求ヘッダ更新件数をカウントアップする(それ以外は成功件数としてカウントアップされている)
-- Modify 2013.06.10 Ver1.140 Start
--      IF (SQL%ROWCOUNT > 0) AND (ln_target_cnt = 0) THEN
--        gn_target_up_header_cnt := gn_target_up_header_cnt + 1;
--      END IF;
-- Modify 2013.06.10 Ver1.140 End
--
    EXCEPTION
    -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- データ更新エラー
                               ,iv_token_name1  => cv_tkn_table          -- トークン'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- 請求ヘッダ情報テーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_bill_amount;
--
-- Modify 2013.01.17 Ver1.130 End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- Modify 2012.11.06 Ver1.120 Start
    iv_parallel_type          IN  VARCHAR2,     -- パラレル実行区分
    iv_batch_on_judge_type    IN  VARCHAR2,     -- 夜間手動判断区分
-- Modify 2012.11.06 Ver1.120 End
    ov_errbuf                 OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_target_trx_cnt   NUMBER; -- 請求対象取引データ件数
    lv_msg     VARCHAR2(5000);  -- 出力メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_header_cnt   := 0;
    gn_target_line_cnt     := 0;
    gn_target_aroif_cnt    := 0;
-- Modify 2012.11.06 Ver1.120 Start
--    gn_target_del_head_cnt := 0;
--    gn_target_del_line_cnt := 0;
--    gn_normal_cnt  := 0;
-- Modify 2012.11.06 Ver1.120 End
    gn_error_cnt   := 0;
-- Modify 2012.11.06 Ver1.120 Start
--    gn_warn_cnt    := 0;
-- Modify 2012.11.06 Ver1.120 End
    gv_conc_status := cv_status_normal;
-- Modify 2012.11.06 Ver1.120 Start
--    gv_auto_inv_err_flag := 'N';
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.06.10 Ver1.140 Start
-- Modify 2013.01.17 Ver1.130 Start
--    gn_target_up_header_cnt := 0;
-- Modify 2013.01.17 Ver1.130 End
-- Modify 2013.06.10 Ver1.140 End
--
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
-- Modify 2012.11.06 Ver1.120 Start
       iv_parallel_type        -- パラレル実行区分
      ,iv_batch_on_judge_type  -- 夜間手動判断区分
-- Modify 2012.11.06 Ver1.120 End
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- 対象請求ヘッダデータ抽出処理 (A-2)
    -- =====================================================
    get_target_inv_header(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --処理対象件数が0件の場合
    IF (gn_target_header_cnt = 0) THEN
      --処理を終了する
      RETURN;
    END IF;
--
-- Modify 2009.07.22 Ver1.3 Start
--    --ループ
--    <<for_loop>>
--    FOR ln_loop_cnt IN gt_invoice_id_tab.FIRST..gt_invoice_id_tab.LAST LOOP
-- Modify 2009.07.22 Ver1.3 End
--
      -- =====================================================
      -- 請求明細データ作成処理 (A-3)
      -- =====================================================
      ins_inv_detail_data(
-- Modify 2009.07.22 Ver1.3 Start
--         gt_invoice_id_tab(ln_loop_cnt),      -- 一括請求書ID
--         gt_cust_acct_id_tab(ln_loop_cnt),    -- 請求先顧客ID
--         gt_cutoff_date_tab(ln_loop_cnt),     -- 締日
--         gt_tax_type_tab(ln_loop_cnt),        -- 消費税区分
-- Modify 2009.07.22 Ver1.3 Start
         lv_errbuf,            -- エラー・メッセージ           --# 固定 #
         lv_retcode,           -- リターン・コード             --# 固定 #
         lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
-- Modify 2009.07.22 Ver1.3 Start
-- Modify 2009.09.29 Ver1.5 Start
--    --ループ
--    <<for_loop>>
--    FOR ln_loop_cnt IN gt_invoice_id_tab.FIRST..gt_invoice_id_tab.LAST LOOP
---- Modify 2009.07.22 Ver1.3 End
--      -- 税差額が発生した場合
--      IF (NVL(gt_tax_gap_amt_tab(ln_loop_cnt), 0) != 0) THEN
----
--        -- =====================================================
--        -- AR取引OIF登録処理 (A-4)
--        -- =====================================================
--        ins_aroif_data(
--           gt_invoice_id_tab(ln_loop_cnt),      -- 一括請求書ID
--           gt_tax_gap_amt_tab(ln_loop_cnt),     -- 税差額
--           gt_term_name_tab(ln_loop_cnt),       -- 支払条件名
--           gt_term_id_tab(ln_loop_cnt),         -- 支払条件ID
--           gt_cust_acct_id_tab(ln_loop_cnt),    -- 請求先顧客ID
--           gt_cust_site_id_tab(ln_loop_cnt),    -- 請求先顧客所在地ID
--           gt_bil_loc_code_tab(ln_loop_cnt),    -- 請求拠点コード
--           gt_rec_loc_code_tab(ln_loop_cnt),    -- 入金拠点コード
--           gt_cutoff_date_tab(ln_loop_cnt),     -- 締日
--           lv_errbuf,                           -- エラー・メッセージ           --# 固定 #
--           lv_retcode,                          -- リターン・コード             --# 固定 #
--           lv_errmsg);                          -- ユーザー・エラー・メッセージ --# 固定 #
--        IF (lv_retcode = cv_status_error) THEN
--          --(エラー処理)
--          RAISE global_process_expt;
--        END IF;
----
--      END IF;
----
--    END LOOP for_loop;
----
--    --処理対象件数が0件の場合
--    IF  (gn_target_header_cnt = 0) THEN
--      --処理を終了する
--      RETURN;
--    END IF;
----
--    --AR取引OIF登録件数が0件の場合
--    IF (gn_target_aroif_cnt > 0) THEN
--      -- =====================================================
--      -- トランザクション確定処理 (A-5)
--      -- =====================================================
--      -- COMMITの発行
--      COMMIT;
----
--      -- COMMIT発行メッセージ取得
--      lv_msg := SUBSTRB(xxccp_common_pkg.get_msg(
--                          iv_application  => cv_msg_kbn_cfr,
--                          iv_name         => cv_msg_cfr_00059),
--                        1,
--                        5000);
----
--      -- COMMIT発行をログに出力
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_msg
--      );
----
--      -- =====================================================
--      -- 自動インボイス起動処理 (A-6)
--      -- =====================================================
--      start_auto_invoice(
--         lv_errbuf                             -- エラー・メッセージ           --# 固定 #
--        ,lv_retcode                            -- リターン・コード             --# 固定 #
--        ,lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
--      IF (lv_retcode = cv_status_error) THEN
--        --(エラー処理)
--        RAISE global_process_expt;
--      END IF;
----
--      -- =====================================================
--      -- 自動インボイス終了処理 (A-7)
--      -- =====================================================
--      end_auto_invoice(
--         lv_errbuf,                              -- エラー・メッセージ           --# 固定 #
--         lv_retcode,                             -- リターン・コード             --# 固定 #
--         lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
--      );
----
--      IF (lv_retcode = cv_status_error) THEN
--        --(エラー処理)
--        RAISE global_process_expt;
--      END IF;
----
--      -- =====================================================
--      -- 請求ヘッダ情報更新処理 (A-8)
--      -- =====================================================
--      update_inv_header(
--         lv_errbuf,                                  -- エラー・メッセージ           --# 固定 #
--         lv_retcode,                                 -- リターン・コード             --# 固定 #
--         lv_errmsg                                   -- ユーザー・エラー・メッセージ --# 固定 #
--      );
----
--      IF (lv_retcode = cv_status_error) THEN
--        --(エラー処理)
--        RAISE global_process_expt;
--      END IF;
----
--    END IF;
-- Modify 2009.09.29 Ver1.5 End
--
-- Ver1.200 Del Start
---- Modify 2013.01.17 Ver1.130 Start
--    --夜間手動判断区分の判断（手動実行用）
--    --手動実行では請求ヘッダ情報の請求金額を再計算する必要がある為、下記で再計算する
---- Ver1.190 Del Start
----   IF (gv_batch_on_judge_type != cv_judge_type_batch) THEN
---- Ver1.190 Del End
---- 夜間、手動共に請求ヘッダ情報の請求金額を再計算する。
--      --変数初期化
--      ln_target_trx_cnt := 0;
--      -- =====================================================
--      -- 請求更新対象取得処理 (A-10)
--      -- =====================================================
--      get_update_target_bill(
--         ln_target_trx_cnt,                      -- 対象取引件数
--         lv_errbuf,                              -- エラー・メッセージ           --# 固定 #
--         lv_retcode,                             -- リターン・コード             --# 固定 #
--         lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF (lv_retcode = cv_status_error) THEN
--        --(エラー処理)
--        RAISE global_process_expt;
--      END IF;
----
--      IF (ln_target_trx_cnt > 0) THEN
--      --ループ
--      <<for_loop>>
--      FOR ln_loop_cnt IN gt_get_inv_id_tab.FIRST..gt_get_inv_id_tab.LAST LOOP
--        -- =====================================================
--        -- 請求金額更新処理 請求ヘッダ情報テーブル(A-11)
--        -- =====================================================
--        update_bill_amount(
--           gt_get_inv_id_tab(ln_loop_cnt),         -- 請求書ID
---- Ver1.190 Del Start
----           gt_get_amt_no_tax_tab(ln_loop_cnt),     -- 税抜総額（合計）
----           gt_get_tax_amt_sum_tab(ln_loop_cnt),    -- 消費税額（合計）
----           gt_get_amd_inc_tax_tab(ln_loop_cnt),    -- 売上金額
---- Ver1.190 Del End
---- Ver1.190 Add Start
--           gt_tax_gap_amount_tab(ln_loop_cnt),     -- 税差額
--           gt_tax_sum1_tab(ln_loop_cnt),           -- 税額合計１
--           gt_tax_sum2_tab(ln_loop_cnt),           -- 税額合計２
--           gt_inv_gap_amount_tab(ln_loop_cnt),     -- 本体差額
--           gt_no_tax_sum1_tab(ln_loop_cnt),        -- 税抜額合計１
--           gt_no_tax_sum2_tab(ln_loop_cnt),        -- 税抜額合計２
--           gt_invoice_tax_div_tab(ln_loop_cnt),    -- 請求書消費税積上げ計算方式
--           gt_output_format_tab(ln_loop_cnt),      -- 請求書出力形式
--           gt_tax_div_tab(ln_loop_cnt),            -- 税区分
---- Ver1.190 Add End
--           lv_errbuf,                              -- エラー・メッセージ           --# 固定 #
--           lv_retcode,                             -- リターン・コード             --# 固定 #
--           lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        IF (lv_retcode = cv_status_error) THEN
--          --(エラー処理)
--          RAISE global_process_expt;
--        END IF;
--      END LOOP for_loop;
----
--      END IF;
----
---- Ver1.190 Del Start
----    END IF;
---- Ver1.190 Del End
----
---- Modify 2013.01.17 Ver1.130 End
--- Ver1.200 Del END
--
    -- =====================================================
    -- 取引データステータス更新処理 (A-9)
    -- =====================================================
    update_trx_status(
       lv_errbuf,                              -- エラー・メッセージ           --# 固定 #
       lv_retcode,                             -- リターン・コード             --# 固定 #
       lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 警告フラグが警告となっている場合
    IF (gv_conc_status = cv_status_warn) THEN
      -- リターン・コードに警告をセット
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                  OUT     VARCHAR2,         -- エラー・メッセージ
-- Modify 2012.11.06 Ver1.120 Start
--    retcode                 OUT     VARCHAR2          -- エラーコード
    retcode                 OUT     VARCHAR2,         -- エラーコード
    iv_parallel_type        IN      VARCHAR2,         -- パラレル実行区分
    iv_batch_on_judge_type  IN      VARCHAR2          -- 夜間手動判断区分
-- Modify 2012.11.06 Ver1.120 End
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   -- メッセージコード
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバックメッセージ
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
-- Modify 2012.11.06 Ver1.120 Start
       iv_parallel_type          -- パラレル実行区分
      ,iv_batch_on_judge_type    -- 夜間手動判断区分
-- Modify 2012.11.06 Ver1.120 End
      ,lv_errbuf                 -- エラー・メッセージ           
      ,lv_retcode                -- リターン・コード             
      ,lv_errmsg                 -- ユーザー・エラー・メッセージ 
    );
--
--###########################  固定部 START   #####################################################
--
    --エラーメッセージが設定されている場合、エラー出力
-- Modify 2013.01.17 Ver1.130 Start
--    IF (lv_errmsg IS NOT NULL) THEN
    IF (lv_retcode = cv_status_error) THEN
-- Modify 2013.01.17 Ver1.130 End
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --終了ステータスが異常終了の場合
    IF (lv_retcode = cv_status_error) THEN
      gn_target_header_cnt := 0;
      gn_target_line_cnt := 0;
-- Modify 2012.11.06 Ver1.120 Start
--      gn_target_del_head_cnt := 0;
--      gn_target_del_line_cnt := 0;
--      gn_normal_cnt := 0;
-- Modify 2012.11.06 Ver1.120 End
      gn_error_cnt  := 1;
-- Modify 2013.06.10 Ver1.140 Start
-- Modify 2013.01.17 Ver1.130 Start
--      gn_target_up_header_cnt := 0;
-- Modify 2013.01.17 Ver1.130 End
-- Modify 2013.06.10 Ver1.140 End
    END IF;
    --
    --メッセージタイトル(ヘッダ部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_cfr_00018
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(ヘッダ部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力(ヘッダ部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
-- Modify 2013.01.17 Ver1.130 Start
-- Modify 2012.11.06 Ver1.120 Start
--                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt - gn_target_del_head_cnt)
--                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt)
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.06.10 Ver1.140 Start
--                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt - gn_target_up_header_cnt)
                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt)
-- Modify 2013.01.17 Ver1.130 End
-- Modify 2013.06.10 Ver1.140 End
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力(ヘッダ部)
-- Modify 2012.11.06 Ver1.120 Start
--    IF (lv_retcode = cv_status_error) THEN
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_ccp
--                      ,iv_name         => cv_msg_ccp_90002
--                      ,iv_token_name1  => cv_tkn_count
--                      ,iv_token_value1 => '1'
--                     );
--
--    ELSE
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_ccp
--                      ,iv_name         => cv_msg_ccp_90002
--                      ,iv_token_name1  => cv_tkn_count
--                      ,iv_token_value1 => TO_CHAR(gn_target_del_head_cnt)
--                     );
--    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
-- Modify 2012.11.06 Ver1.120 End
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- Modify 2013.06.10 Ver1.140 Start
-- Modify 2013.01.17 Ver1.130 Start
--    --更新件数出力(ヘッダ部)
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cfr
--                    ,iv_name         => cv_msg_cfr_00146
--                    ,iv_token_name1  => cv_tkn_count
--                    ,iv_token_value1 => TO_CHAR(gn_target_up_header_cnt)
--                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- Modify 2013.06.10 Ver1.140 End
    --
-- Modify 2013.01.17 Ver1.130 End
    --メッセージタイトル(明細部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_cfr_00019
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力(明細部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_line_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力(明細部)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
-- Modify 2012.11.06 Ver1.120 Start
--                    ,iv_token_value1 => TO_CHAR(gn_target_line_cnt - gn_target_del_line_cnt)
                    ,iv_token_value1 => TO_CHAR(gn_target_line_cnt)
-- Modify 2012.11.06 Ver1.120 End
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力(明細部)
-- Modify 2012.11.06 Ver1.120 Start
--    IF (lv_retcode = cv_status_error) THEN
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_ccp
--                      ,iv_name         => cv_msg_ccp_90002
--                      ,iv_token_name1  => cv_tkn_count
--                      ,iv_token_value1 => '1'
--                     );
--
--    ELSE
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_ccp
--                      ,iv_name         => cv_msg_ccp_90002
--                      ,iv_token_name1  => cv_tkn_count
--                      ,iv_token_value1 => TO_CHAR(gn_target_del_line_cnt)
--                     );
--    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
-- Modify 2012.11.06 Ver1.120 End
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) 
-- Modify 2012.11.06 Ver1.120 Start
--      AND(gv_auto_inv_err_flag = 'Y')
--    THEN
--      lv_message_code := cv_msg_cfr_00045;
--    ELSIF(lv_retcode = cv_status_error) 
--      AND(gv_auto_inv_err_flag = 'N')
-- Modify 2012.11.06 Ver1.120 End
    THEN
      lv_message_code := cv_msg_cfr_00046;
    END IF;
    --
    --異常終了の場合
    IF (lv_retcode = cv_status_error) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => lv_message_code
                     );
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_ccp
                      ,iv_name         => lv_message_code
                     );
    END IF;
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFR003A03C;
/
