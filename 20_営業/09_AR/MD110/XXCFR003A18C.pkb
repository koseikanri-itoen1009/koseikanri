CREATE OR REPLACE PACKAGE BODY XXCFR003A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A18C(body)
 * Description      : 標準請求書税込(店舗別内訳)
 * MD.050           : MD050_CFR_003_A18_標準請求書税込(店舗別内訳)
 * MD.070           : MD050_CFR_003_A18_標準請求書税込(店舗別内訳)
 * Version          : 1.96
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_profile_value      p プロファイル取得処理                    (A-2)
 *  chk_inv_all_dept       P 全社出力権限チェック処理                (A-3)
 *  put_account_warning    p 顧客紐付け警告出力
 *  update_work_table      p ワークテーブルデータ更新                (A-11)
 *  insert_work_table      p 対象顧客取得処理(A-4)、売掛管理先顧客取得処理(A-5)、ワークテーブルデータ登録(A-6))
 *  chk_account_data       p 口座情報取得チェック                    (A-7)
 *  start_svf_api          p SVF起動                                 (A-8)
 *  delete_work_table      p ワークテーブルデータ削除                (A-9)
 *  exec_submit_req        p 店舗別明細出力要求発行処理              (A-13)
 *  func_wait_for_request  p コンカレント終了待機処理                (A-14)
 *  chk_bill_red_dept      p 請求書朱印部門チェック処理              (A-15)
 *  get_company_info       P 会社別関連情報の取得処理                (A-16)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/09/25    1.00 SCS 安川 智博    初回作成
 *  2009/11/11    1.10 SCS 安川 智博    共通課題「I_E_664」対応
 *  2010/02/03    1.20 SCS 安川 智博    障害「E_本稼動_01503」対応
 *  2010/12/10    1.30 SCS 石渡 賢和    障害「E_本稼動_05401」対応
 *  2011/01/17    1.40 SCS 廣瀬 真佐人  障害「E_本稼動_00580」対応
 *  2011/03/10    1.50 SCS 石渡 賢和    障害「E_本稼動_06753」対応
 *  2013/12/13    1.60 SCSK 中野 徹也   障害「E_本稼動_11330」対応
 *  2014/03/27    1.70 SCSK 山下 翔太   障害「E_本稼動_11617」対応
 *  2015/07/31    1.80 SCSK 小路 恭弘   障害「E_本稼動_12963」対応
 *  2016/03/31    1.90 SCSK 小路 恭弘   障害「E_本稼動_13511」対応
 *  2016/09/06    1.91 SCSK 小路 恭弘   障害「E_本稼動_13849」対応
 *  2018/10/25    1.92 SCSK 奈良 和宏   障害「E_本稼動_15307」対応
 *  2019/09/03    1.93 SCSK 桑子 駿介   障害「E_本稼動_15472」対応
 *  2022/04/12    1.94 SCSK 冨江 広大   障害「E_本稼動_18096」対応
 *  2023/07/04    1.95 SCSK 奥山 徹     障害「E_本稼動_19082」インボイス対応
 *  2023/11/20    1.96 SCSK 大山 洋介   障害「E_本稼動_19496」グループ会社統合対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  file_not_exists_expt  EXCEPTION;      -- ファイル存在エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A18C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- メッセージ番号
  cv_msg_003a18_001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
  cv_msg_003a18_002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
  cv_msg_003a18_003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
  cv_msg_003a18_004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
  cv_msg_003a18_005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
  cv_msg_003a18_006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
  cv_msg_003a18_007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバックメッセージ
  cv_msg_003a18_008  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; -- エラー終了一部処理メッセージ
  cv_msg_003a18_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; -- システムエラーメッセージ
--
  cv_msg_003a18_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- プロファイル取得エラーメッセージ
  cv_msg_003a18_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- ロックエラーメッセージ
  cv_msg_003a18_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; -- データ削除エラーメッセージ
  cv_msg_003a18_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; -- テーブル挿入エラー
  cv_msg_003a18_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00023'; -- 帳票０件メッセージ
  cv_msg_003a18_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00011'; -- APIエラーメッセージ
  cv_msg_003a18_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- 帳票０件ログメッセージ
  cv_msg_003a18_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; -- 値取得エラーメッセージ
  cv_msg_003a18_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00038'; -- 振込口座未登録メッセージ
  cv_msg_003a18_019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00051'; -- 振込口座未登録情報
  cv_msg_003a18_020  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00052'; -- 振込口座未登録件数メッセージ
  cv_msg_003a18_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; -- 共通関数エラーメッセージ
  cv_msg_003a18_022  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00079'; -- 請求書用顧客存在なしメッセージ
  cv_msg_003a18_023  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00080'; -- 売掛管理先顧客存在なしメッセージ
  cv_msg_003a18_024  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00082'; -- 統括請求書用顧客存在なしメッセージ
  cv_msg_003a18_025  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00081'; -- 顧客コード複数指定メッセージ
-- Add 2013.12.13 Ver1.60 Start
  cv_msg_003a18_026  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017'; -- テーブル更新エラー
-- Add 2013.12.13 Ver1.60 End
-- Add 2015.07.31 Ver1.80 Start
  cv_msg_003a18_027  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00153'; -- 請求書タイプ定義なしエラーメッセージ
  cv_msg_003a18_028  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00154'; -- コンカレント起動エラー
  cv_msg_003a18_029  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00155'; -- コンカレント待機時間経過エラー
  cv_msg_003a18_030  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00156'; -- コンカレント待機正常メッセージ
  cv_msg_003a18_031  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00157'; -- コンカレント待機警告メッセージ
  cv_msg_003a18_032  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00158'; -- コンカレント待機エラーメッセージ
-- Add 2015.07.31 Ver1.80 End
-- Ver1.96 ADD START
  cv_msg_003a18_033  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00165'; -- 会社コード指定不可エラーメッセージ
  cv_msg_003a18_034  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00166'; -- パラメータ制約エラーメッセージ
  cv_msg_003a18_035  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00163'; -- トークン値(登録番号)
  cv_msg_003a18_036  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00164'; -- トークン値(請求書SVF情報)
-- Ver1.96 ADD END
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_api         CONSTANT VARCHAR2(15) := 'API_NAME';         -- API名
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- コメント
  cv_tkn_get_data    CONSTANT VARCHAR2(30) := 'DATA';             -- 取得対象データ
  cv_tkn_ac_code     CONSTANT VARCHAR2(30) := 'ACCOUNT_CODE';     -- 顧客コード
  cv_tkn_ac_name     CONSTANT VARCHAR2(30) := 'ACCOUNT_NAME';     -- 顧客名
  cv_tkn_lc_name     CONSTANT VARCHAR2(30) := 'KYOTEN_NAME';      -- 拠点名
  cv_tkn_count       CONSTANT VARCHAR2(30) := 'COUNT';            -- カウント数
  cv_tkn_func        CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- 共通関数名
-- Add 2015.07.31 Ver1.80 Start
  cv_tkn_lookup_type CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';      -- 参照タイプ
  cv_tkn_lookup_code CONSTANT VARCHAR2(15) := 'LOOKUP_CODE';      -- コード
  cv_tkn_request_id  CONSTANT VARCHAR2(15) := 'REQUEST_ID';       -- リクエストID
  cv_tkn_conc        CONSTANT VARCHAR2(15) := 'CONC_NAME';        -- コンカレント名
-- Add 2015.07.31 Ver1.80 End
-- Ver1.96 ADD START
  cv_tkn_date        CONSTANT VARCHAR2(15) := 'DATE';             -- 日付
-- Ver1.96 ADD END
--
  -- 日本語辞書
  cv_dict_date       CONSTANT VARCHAR2(100) := 'CFR000A00003';    -- 日付パラメータ変換関数
  cv_dict_svf        CONSTANT VARCHAR2(100) := 'CFR000A00004';    -- SVF起動
--
  cv_dict_ymd4       CONSTANT VARCHAR2(100) := 'CFR000A00007';    -- YYYY"年"MM"月"DD"日"
  cv_dict_ymd2       CONSTANT VARCHAR2(100) := 'CFR000A00008';    -- YY"年"MM"月"DD"日"
  cv_dict_year       CONSTANT VARCHAR2(100) := 'CFR000A00009';    -- 年
  cv_dict_month      CONSTANT VARCHAR2(100) := 'CFR000A00010';    -- 月
  cv_dict_bank       CONSTANT VARCHAR2(100) := 'CFR000A00011';    -- 銀行
  cv_dict_central    CONSTANT VARCHAR2(100) := 'CFR000A00015';    -- 本店
  cv_dict_branch     CONSTANT VARCHAR2(100) := 'CFR000A00012';    -- 支店
  cv_dict_account    CONSTANT VARCHAR2(100) := 'CFR000A00013';    -- 普通
  cv_dict_current    CONSTANT VARCHAR2(100) := 'CFR000A00014';    -- 当座
  cv_dict_zip_mark   CONSTANT VARCHAR2(100) := 'CFR000A00016';    -- 〒
  cv_dict_bank_damy  CONSTANT VARCHAR2(100) := 'CFR000A00017';    -- 銀行ダミーコード
  cv_dict_date_func  CONSTANT VARCHAR2(100) := 'CFR000A00002';    -- 営業日付取得関数
--
  --プロファイル
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
-- Add 2023.07.04 Ver1.95 Start
  cv_t_number        CONSTANT VARCHAR2(30) := 'XXCMM1_INVOICE_T_NO'; -- XXCMM:適格請求書発行事業者登録番号
-- Add 2023.07.04 Ver1.95 End
-- Add 2015.07.31 Ver1.80 Start
  cv_interval        CONSTANT VARCHAR2(30) := 'XXCFR1_INTERVAL';  -- XXCFR:待機間隔
  cv_max_wait        CONSTANT VARCHAR2(30) := 'XXCFR1_MAX_WAIT';  -- XXCFR:最大待機時間
-- Add 2015.07.31 Ver1.80 End
-- Ver1.96 ADD START
  cv_hkd_start_date  CONSTANT VARCHAR2(30) := 'XXCMM1_ITOEN_HKD_START_DATE'; -- XXCMM:伊藤園北海道適用開始日付  (※YYYYMMDD)
-- Ver1.96 ADD END
--
  -- 使用DB名
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INVOICE_INC_TAX_D';  -- ワークテーブル名
-- Add 2015.07.31 Ver1.80 Start
  cv_table_a_h       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_A_H';    -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダ名
  cv_table_a_l       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_A_L';    -- 標準請求書税込帳票内訳印刷単位Aワークテーブル明細名
  cv_table_b_h       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_B_H';    -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダ名
  cv_table_b_l       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_B_L';    -- 標準請求書税込帳票内訳印刷単位Bワークテーブル明細名
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
  cv_table_c_h       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_C_H';    -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ名
  cv_table_c_l       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_C_L';    -- 標準請求書税込帳票内訳印刷単位Cワークテーブル明細名
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
  cv_table_d_h       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_D_H';            -- 標準請求書帳票内訳印刷単位Dワークテーブルヘッダ名
  cv_table_d_l       CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INV_INC_TAX_D_L';    -- 標準請求書税込帳票内訳印刷単位Dワークテーブル明細名
-- Ver.1.92 [障害E_本稼動_15307] ADD END
--
  -- 請求書タイプ
  cv_invoice_type    CONSTANT VARCHAR2(1)   := 'S';                        -- ‘S’(標準請求書)
--
-- Add 2023.07.04 Ver1.95 Start
  -- 請求書消費税積上げ計算方式
  cn_invoice_tax_div CONSTANT VARCHAR2(1)   := 'N';                        -- 税込請求金額サマリに消費税率を乗じた値を摘要
-- Add 2023.07.04 Ver1.95 End
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10)  := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10)  := 'LOG';       -- ログ出力
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)   := 'Y';         -- 有効フラグ（Ｙ）
--
  cv_status_yes      CONSTANT VARCHAR2(1)   := '1';         -- 有効ステータス（1：有効）
  cv_status_no       CONSTANT VARCHAR2(1)   := '0';         -- 有効ステータス（0：無効）
--
-- Add 2015.07.31 Ver1.80 Start
  cv_taget_flag_0    CONSTANT VARCHAR2(1)   := '0';               -- 明細0件フラグ（0：対象顧客なし）
  cv_taget_flag_1    CONSTANT VARCHAR2(1)   := '1';               -- 明細0件フラグ（1：対象データなし）
  cv_taget_flag_2    CONSTANT VARCHAR2(1)   := '2';               -- 明細0件フラグ（2：対象データあり）
--
  -- 店舗別明細帳票ID
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--  cv_report_id_01    CONSTANT VARCHAR2(14)  := 'XXCFR003A2001C';  -- 請求書（14顧客合計_店舗別一覧）税込
--  cv_report_id_02    CONSTANT VARCHAR2(14)  := 'XXCFR003A2002C';  -- 店舗別明細（店舗別改ページ）税込
--  cv_report_id_03    CONSTANT VARCHAR2(14)  := 'XXCFR003A2003C';  -- 請求総括表（14顧客合計）税込
--  cv_report_id_04    CONSTANT VARCHAR2(14)  := 'XXCFR003A2004C';  -- 請求書（店舗別改ページ）税込
---- Add 2016.03.31 Ver1.90 Start
--  cv_report_id_09    CONSTANT VARCHAR2(14)  := 'XXCFR003A2009C';  -- 請求書（14顧客合計_店舗別一覧）税込
--  cv_report_id_10    CONSTANT VARCHAR2(14)  := 'XXCFR003A2010C';  -- 伝票別明細税込
---- Add 2016.03.31 Ver1.90 End
  cv_report_id_01    CONSTANT VARCHAR2(14)  := 'XXCFR003A2001C';  -- 請求書A税込ヘッダ
  cv_report_id_02    CONSTANT VARCHAR2(14)  := 'XXCFR003A2002C';  -- 請求書A税込明細
  cv_report_id_03    CONSTANT VARCHAR2(14)  := 'XXCFR003A2003C';  -- 請求書B税込ヘッダ
  cv_report_id_04    CONSTANT VARCHAR2(14)  := 'XXCFR003A2004C';  -- 請求書B税込明細
  cv_report_id_09    CONSTANT VARCHAR2(14)  := 'XXCFR003A2009C';  -- 請求書C税込ヘッダ
  cv_report_id_10    CONSTANT VARCHAR2(14)  := 'XXCFR003A2010C';  -- 請求書C税込明細
-- Ver.1.92 [障害E_本稼動_15307] MOD END
-- Ver.1.92 [障害E_本稼動_15307] ADD START
  cv_report_id_13    CONSTANT VARCHAR2(14)  := 'XXCFR003A2013C';  -- 請求書Dヘッダ
  cv_report_id_14    CONSTANT VARCHAR2(14)  := 'XXCFR003A2014C';  -- 請求書D税込明細
-- Ver.1.92 [障害E_本稼動_15307] ADD END
--
  -- 店舗別明細の請求書タイプ
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--  cv_bill_type_01    CONSTANT VARCHAR2(2)   := '01';              -- 請求書（14顧客合計_店舗別一覧）税込
--  cv_bill_type_02    CONSTANT VARCHAR2(2)   := '02';              -- 店舗別明細（店舗別改ページ）税込
--  cv_bill_type_03    CONSTANT VARCHAR2(2)   := '03';              -- 請求総括表（14顧客合計）税込
--  cv_bill_type_04    CONSTANT VARCHAR2(2)   := '04';              -- 請求書（店舗別改ページ）税込
---- Add 2016.03.31 Ver1.90 Start
--  cv_bill_type_09    CONSTANT VARCHAR2(2)   := '09';              -- 請求書（14顧客合計_店舗別一覧）税込
--  cv_bill_type_10    CONSTANT VARCHAR2(2)   := '10';              -- 伝票別明細税込
---- Add 2016.03.31 Ver1.90 End
  cv_bill_type_01    CONSTANT VARCHAR2(2)   := '01';              -- 請求書A税込ヘッダ
  cv_bill_type_02    CONSTANT VARCHAR2(2)   := '02';              -- 請求書A税込明細
  cv_bill_type_03    CONSTANT VARCHAR2(2)   := '03';              -- 請求書B税込ヘッダ
  cv_bill_type_04    CONSTANT VARCHAR2(2)   := '04';              -- 請求書B税込明細
  cv_bill_type_09    CONSTANT VARCHAR2(2)   := '09';              -- 請求書C税込ヘッダ
  cv_bill_type_10    CONSTANT VARCHAR2(2)   := '10';              -- 請求書C税込明細
-- Ver.1.92 [障害E_本稼動_15307] MOD END
-- Ver.1.92 [障害E_本稼動_15307] ADD START
  cv_bill_type_13    CONSTANT VARCHAR2(2)   := '13';              -- 請求書Dヘッダ
  cv_bill_type_14    CONSTANT VARCHAR2(2)   := '14';              -- 請求書D税込明細
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- Ver1.94 add start
  cv_bill_type_01_2  CONSTANT VARCHAR2(4)   := '01_2';            -- 朱印請求書A税込ヘッダ
  cv_bill_type_02_2  CONSTANT VARCHAR2(4)   := '02_2';            -- 朱印請求書A税込明細
  cv_bill_type_03_2  CONSTANT VARCHAR2(4)   := '03_2';            -- 朱印請求書B税込ヘッダ
  cv_bill_type_04_2  CONSTANT VARCHAR2(4)   := '04_2';            -- 朱印請求書B税込明細
  cv_bill_type_09_2  CONSTANT VARCHAR2(4)   := '09_2';            -- 朱印請求書C税込ヘッダ
  cv_bill_type_13_2  CONSTANT VARCHAR2(4)   := '13_2';            -- 朱印請求書Dヘッダ
  cv_bill_type_14_2  CONSTANT VARCHAR2(4)   := '14_2';            -- 朱印請求書D税込明細
-- Ver1.94 add end
--
  -- コンカレントdevステータス
  cv_dev_status_normal  CONSTANT VARCHAR2(6)  := 'NORMAL';  -- '正常'
  cv_dev_status_warn    CONSTANT VARCHAR2(7)  := 'WARNING'; -- '警告'
--
-- Add 2015.07.31 Ver1.80 End
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';             -- 日付フォーマット（年月日）
  cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';     -- 日付フォーマット（年月日時分秒
  cv_format_date_ymds   CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';           -- 日付フォーマット（年月日スラッシュ付）
  cv_format_date_ymds2  CONSTANT VARCHAR2(8)  := 'YY/MM/DD';             -- 日付フォーマット（2桁年月日スラッシュ付）
--
  cd_max_date           CONSTANT DATE         := TO_DATE('9999/12/31',cv_format_date_ymds);
--
  -- 顧客区分
  cv_customer_class_code14 CONSTANT VARCHAR2(2) := '14';      -- 顧客区分14(売掛管理先)
  cv_customer_class_code21 CONSTANT VARCHAR2(2) := '21';      -- 顧客区分21(統括請求書用)
  cv_customer_class_code20 CONSTANT VARCHAR2(2) := '20';      -- 顧客区分20(請求書用)
  cv_customer_class_code10 CONSTANT VARCHAR2(2) := '10';      -- 顧客区分10(顧客)
--
  -- 請求書印刷単位
  cv_invoice_printing_unit_a1 CONSTANT VARCHAR2(2) := '9';    -- 請求書印刷単位:'A1'
  cv_invoice_printing_unit_a2 CONSTANT VARCHAR2(2) := '8';    -- 請求書印刷単位:'A2'
  cv_invoice_printing_unit_a3 CONSTANT VARCHAR2(2) := '6';    -- 請求書印刷単位:'A3'
  cv_invoice_printing_unit_a4 CONSTANT VARCHAR2(2) := '7';    -- 請求書印刷単位:'A4'
  cv_invoice_printing_unit_a5 CONSTANT VARCHAR2(2) := '5';    -- 請求書印刷単位:'A5'
  cv_invoice_printing_unit_a6 CONSTANT VARCHAR2(2) := '4';    -- 請求書印刷単位:'A6'
-- Add 2015.07.31 Ver1.80 Start
  cv_invoice_printing_unit_a7 CONSTANT VARCHAR2(2) := 'A';    -- 請求書印刷単位:'A7'
  cv_invoice_printing_unit_a8 CONSTANT VARCHAR2(2) := 'B';    -- 請求書印刷単位:'A8'
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
  cv_invoice_printing_unit_a9 CONSTANT VARCHAR2(2) := 'C';    -- 請求書印刷単位:'A9'
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
  cv_invoice_printing_unit_a10  CONSTANT VARCHAR2(2) := 'D';  -- 請求書印刷単位:'A10'
-- Ver.1.92 [障害E_本稼動_15307] ADD END
--
  -- 使用目的
  cv_site_use_code_bill_to CONSTANT VARCHAR(10) := 'BILL_TO';  -- 使用目的：「請求先」
-- Add 2010-02-03 Ver1.20 Start
  cv_site_use_stat_act     CONSTANT VARCHAR2(1) := 'A';        -- 使用目的ステータス：有効
-- Add 2010-02-03 Ver1.20 End
--
  -- 顧客関連処理対象ステータス
  cv_acct_relate_status    CONSTANT VARCHAR2(1) := 'A';
--
  -- 顧客関連
  cv_acct_relate_type_bill CONSTANT VARCHAR2(1) := '1';     -- 請求関連
--
  -- AFF部門値セット名
  cv_ffv_set_name_dept CONSTANT VARCHAR2(100) := 'XX03_DEPARTMENT';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
-- Add 2015.07.31 Ver1.80 Start
  -- 店舗別明細出力要求ID
  TYPE g_org_request_rtype IS RECORD(
    request_id                    fnd_concurrent_requests.request_id%TYPE
-- Ver.1.92 [障害E_本稼動_15307] ADD START
   ,conc_name                     fnd_lookup_values_vl.attribute1%TYPE
-- Ver.1.92 [障害E_本稼動_15307] ADD END
  );
  TYPE g_org_request_ttype IS TABLE OF g_org_request_rtype INDEX BY PLS_INTEGER;
  g_org_request  g_org_request_ttype;
--
-- Add 2015.07.31 Ver1.80 End
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_target_date        DATE;                                      -- パラメータ．締日（データ型変換用）
-- Ver1.96 ADD START
  gv_target_date        VARCHAR2(8);                               -- パラメータ．締日（文字列:YYYYMMDD）
-- Ver1.96 ADD END
  gn_org_id             NUMBER;                                    -- 組織ID
  gn_set_of_bks_id      NUMBER;                                    -- 会計帳簿ID
-- Add 2023.07.04 Ver1.95 Start
  gv_t_number           VARCHAR2(14);                              -- 登録番号
-- Add 2023.07.04 Ver1.95 End
  gt_user_dept          per_all_people_f.attribute28%TYPE := NULL; -- ログインユーザ所属部門
  gv_inv_all_flag       VARCHAR2(1) := '0';                        -- 全社出力権限所持部門フラグ
  gv_warning_flag       VARCHAR2(1) := cv_status_no;               -- 顧客紐付け警告存在フラグ
-- Add 2015.07.31 Ver1.80 Start
  gn_interval           NUMBER;                                    -- 待機間隔
  gn_max_wait           NUMBER;                                    -- 最大待機時間
  gv_target_a_flag      VARCHAR2(1) := '0';                        -- 明細0件フラグA
  gv_target_b_flag      VARCHAR2(1) := '0';                        -- 明細0件フラグB
-- Add 2016.03.31 Ver1.90 Start
  gv_target_c_flag      VARCHAR2(1) := '0';                        -- 明細0件フラグC
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
  gv_target_d_flag      VARCHAR2(1) := '0';                        -- 明細0件フラグD
-- Ver.1.92 [障害E_本稼動_15307] ADD END
  gn_target_cnt_a_h     NUMBER      := 0;                          -- 印刷単位Aヘッダーの対象件数
  gn_target_cnt_a_l     NUMBER      := 0;                          -- 印刷単位A明細の対象件数
  gn_target_cnt_b_h     NUMBER      := 0;                          -- 印刷単位Bヘッダーの対象件数
  gn_target_cnt_b_l     NUMBER      := 0;                          -- 印刷単位B明細の対象件数
-- Add 2016.03.31 Ver1.90 Start
  gn_target_cnt_c_h     NUMBER      := 0;                          -- 印刷単位Cヘッダーの対象件数
  gn_target_cnt_c_l     NUMBER      := 0;                          -- 印刷単位C明細の対象件数
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
  gn_target_cnt_d_h     NUMBER      := 0;                          -- 印刷単位Dヘッダーの対象件数
  gn_target_cnt_d_l     NUMBER      := 0;                          -- 印刷単位D明細の対象件数
-- Ver.1.92 [障害E_本稼動_15307] ADD END
  gn_req_cnt            NUMBER;                                    -- 店舗別明細出力要求発行数
-- Add 2015.07.31 Ver1.80 End
-- Ver1.94 add start
  gv_bill_red_flag      VARCHAR2(1) := '0';                        -- 請求書朱印部門存在フラグ
-- Ver1.94 add end
-- Ver1.96 ADD START
  gd_hkd_start_date     DATE;                                      -- 伊藤園北海道適用開始日付
  gv_comp_spin_off_flag VARCHAR2(1);                               -- 分社化対応フラグ(Y/N)
  gv_drafting_company   VARCHAR2(3);                               -- 請求書作成会社コード
  gv_frm_file           VARCHAR2(150);                             -- フォーム様式ファイル名
  gv_vrq_file           VARCHAR2(150);                             -- クエリー様式ファイル名
-- Ver1.96 ADD END
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_customer_code14     IN      VARCHAR2,         -- 売掛管理先顧客
    iv_customer_code21     IN      VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code20     IN      VARCHAR2,         -- 請求書用顧客
    iv_customer_code10     IN      VARCHAR2,         -- 顧客
-- Add 2010.12.10 Ver1.30 Start
    iv_bill_pub_cycle      IN      VARCHAR2,         -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
    iv_tax_output_type     IN      VARCHAR2,         -- 税別内訳出力区分
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
    iv_bill_invoice_type   IN      VARCHAR2,         -- 請求書出力形式
-- Add 2014.03.27 Ver1.70 End
-- Ver1.96 ADD START
    iv_company_cd          IN      VARCHAR2,         -- 会社コード
-- Ver1.96 ADD END
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    param_expt EXCEPTION;  -- 顧客コード複数指定例外
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
--
    -- パラメータ．締日をDATE型に変換する
    gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
    IF (gd_target_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_021 -- 共通関数エラー
                                                    ,cv_tkn_func       -- トークン'FUNC_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                       ,cv_dict_date_func))
                                                    -- 営業日付取得関数
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
-- Ver1.96 ADD START
    gv_target_date := TO_CHAR(gd_target_date, cv_format_date_ymd);
-- Ver1.96 ADD END
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log             -- ログ出力
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date
                                                              ,cv_format_date_ymds) -- コンカレントパラメータ１
                                   ,iv_conc_param2  => iv_customer_code10           -- コンカレントパラメータ２
                                   ,iv_conc_param3  => iv_customer_code20           -- コンカレントパラメータ３
                                   ,iv_conc_param4  => iv_customer_code21           -- コンカレントパラメータ４
                                   ,iv_conc_param5  => iv_customer_code14           -- コンカレントパラメータ５
-- Add 2010.12.10 Ver1.30 Start
                                   ,iv_conc_param6  => iv_bill_pub_cycle            -- コンカレントパラメータ６
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
                                   ,iv_conc_param7  => iv_tax_output_type           -- コンカレントパラメータ７
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
                                   ,iv_conc_param8  => iv_bill_invoice_type         -- コンカレントパラメータ８
-- Add 2014.03.27 Ver1.70 End
-- Ver1.96 ADD START
                                   ,iv_conc_param9  => iv_company_cd                -- コンカレントパラメータ９
-- Ver1.96 ADD END
                                   ,ov_errbuf       => ov_errbuf                    -- エラー・メッセージ
                                   ,ov_retcode      => ov_retcode                   -- リターン・コード
                                   ,ov_errmsg       => ov_errmsg);                  -- ユーザー・エラー・メッセージ 
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- パラメータ顧客コードの指定数チェック 顧客コードは１つのみ指定していることをチェック
    IF (iv_customer_code14 IS NOT NULL) THEN
      IF (iv_customer_code21 IS NOT NULL)
      OR (iv_customer_code20 IS NOT NULL)
      OR (iv_customer_code10 IS NOT NULL)
      THEN
        RAISE param_expt;
      END IF;
    ELSIF (iv_customer_code21 IS NOT NULL) THEN
      IF (iv_customer_code20 IS NOT NULL)
      OR (iv_customer_code10 IS NOT NULL)
      THEN
        RAISE param_expt;
      END IF;
    ELSIF (iv_customer_code20 IS NOT NULL)
    AND   (iv_customer_code10 IS NOT NULL)
    THEN
      RAISE param_expt;
    END IF;
  EXCEPTION
    WHEN param_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr
                                            ,iv_name         => cv_msg_003a18_025);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id      := FND_PROFILE.VALUE(cv_set_of_bks_id);
--
    -- 取得エラー時
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                     -- 会計帳簿ID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから組織ID取得
    gn_org_id      := FND_PROFILE.VALUE(cv_org_id);
--
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                     -- 組織ID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
-- Add 2015.07.31 Ver1.80 Start
--
    -- プロファイルから待機間隔取得
    gn_interval := TO_NUMBER(FND_PROFILE.VALUE(cv_interval));
--
    -- 取得エラー時
    IF (gn_interval IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_interval))
                                                     -- 待機間隔
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから最大待機時間取得
    gn_max_wait := TO_NUMBER(FND_PROFILE.VALUE(cv_max_wait));
--
    -- 取得エラー時
    IF (gn_max_wait IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_max_wait))
                                                     -- 最大待機時間
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
-- Add 2015.07.31 Ver1.80 End
--
-- Ver1.96 DEL START
---- Add 2023.07.04 Ver1.95 Start
--    -- プロファイルから登録番号取得
--    gv_t_number := FND_PROFILE.VALUE(cv_t_number);
----
--    -- 取得エラー時
--    IF (gv_t_number IS NULL) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                    ,cv_msg_003a18_010 -- プロファイル取得エラー
--                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
--                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_t_number))
--                                                     -- 登録番号
--                          ,1
--                          ,5000);
--      RAISE global_api_expt;
--    END IF;
---- Add 2023.07.04 Ver1.95 End
-- Ver1.96 DEL END
--
-- Ver1.96 ADD START
    -- プロファイルから伊藤園北海道適用開始日付を取得
    gd_hkd_start_date := TO_DATE(FND_PROFILE.VALUE(cv_hkd_start_date), cv_format_date_ymd);
    --
    -- 取得エラー時
    IF (gd_hkd_start_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_hkd_start_date))
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
-- Ver1.96 ADD END
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : chk_inv_all_dept
   * Description      : 全社出力権限チェック処理 (A-3)
   ***********************************************************************************/
  PROCEDURE chk_inv_all_dept(
    ov_errbuf           OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_inv_all_dept'; -- プログラム名
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
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- 従業員マスタDFF名
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- 従業員マスタDFF28(所属部署)カラム名
--
    -- *** ローカル変数 ***
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; -- 所属部門取得エラー時のメッセージトークン値
    lv_valid_flag  VARCHAR2(1) := 'N'; -- 有効フラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    get_user_dept_expt EXCEPTION;  -- ユーザ所属部門取得例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ログインユーザ所属部門取得処理
    gt_user_dept := xxcfr_common_pkg.get_user_dept(cn_created_by -- ユーザID
                                                  ,SYSDATE);     -- 取得日付
--
    -- 取得エラー時
    IF (gt_user_dept IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
--
    -- 全社出力権限所持部門判定処理
      lv_valid_flag := xxcfr_common_pkg.chk_invoice_all_dept(gt_user_dept      -- 所属部門コード
                                                            ,cv_invoice_type); -- 請求書タイプ
      IF lv_valid_flag = cv_enabled_yes THEN
        gv_inv_all_flag := '1';
      END IF;
--
  EXCEPTION
--
    -- *** 所属部門が取得できない場合 ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
        AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a18_017 -- 値取得エラー
                                                    ,cv_tkn_get_data   -- トークン'DATA'
                                                    ,lv_token_value)   -- 'ログインユーザ所属部門'
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END chk_inv_all_dept;
--
-- Ver1.94 add start
  /**********************************************************************************
   * Procedure Name   : chk_bill_red_dept
   * Description      : 請求書朱印部門チェック処理(A-15)
   ***********************************************************************************/
  PROCEDURE chk_bill_red_dept(
    ov_errbuf           OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_bill_red_dept'; -- プログラム名
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
    cv_bill_red_dept         CONSTANT VARCHAR2(30) := 'XXCFR1_BILL_RED_DEPT';    --請求書朱印部門
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
    --請求書朱印部門チェック処理
      BEGIN
        SELECT '1' AS bill_red_flag
        INTO   gv_bill_red_flag
        FROM   fnd_lookup_values flv
        WHERE  flv.lookup_type  = cv_bill_red_dept
        AND    flv.lookup_code  = gt_user_dept
        AND    TRUNC(SYSDATE) BETWEEN NVL( flv.start_date_active, TRUNC(SYSDATE) )
                              AND     NVL( flv.end_date_active, TRUNC(SYSDATE) )
        AND    flv.enabled_flag = cv_enabled_yes
        AND    flv.language     = USERENV( 'LANG' )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END chk_bill_red_dept;
--
-- Ver1.94 add end
--
-- Ver1.96 ADD START
  /**********************************************************************************
   * Procedure Name   : get_company_info
   * Description      : 会社別関連情報の取得処理(A-16)
   ***********************************************************************************/
  PROCEDURE get_company_info(
    iv_customer_code14  IN  VARCHAR2,   -- 売掛管理先顧客
    iv_customer_code21  IN  VARCHAR2,   -- 統括請求書用顧客
    iv_customer_code20  IN  VARCHAR2,   -- 請求書用顧客
    iv_customer_code10  IN  VARCHAR2,   -- 顧客
    iv_company_cd       IN  VARCHAR2,   -- 会社コード
    ov_errbuf           OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_company_info'; -- プログラム名
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
    lv_err_flag               VARCHAR2(1);        -- エラーフラグ
    lv_cond_cust_cd           xxcmm_cust_accounts.customer_code%TYPE;  -- 顧客番号
    lv_invoice_type           VARCHAR2(5);        -- 請求書タイプ
    lv_frm_file               VARCHAR2(150);      -- フォーム様式ファイル名
    lv_vrq_file               VARCHAR2(150);      -- クエリー様式ファイル名
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
    --============================================
    -- 分社化対応フラグ（グルーバル変数）を設定
    --============================================
    gv_comp_spin_off_flag := 'Y';
    IF (gd_target_date < gd_hkd_start_date) THEN
      -- パラメータ「締日」 ＜ プロファイル「伊藤園北海道適用開始日付」の場合
      gv_comp_spin_off_flag := 'N';
    END IF;
    --
    --============================================
    -- 会社コード指定不可チェック
    --============================================
    IF (gv_comp_spin_off_flag = 'N' AND iv_company_cd IS NOT NULL) THEN
      -- 分社化対応フラグがN、かつ、パラメータ「会社コード」に入力がある場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_msg_kbn_cfr      -- 'XXCFR'
                    ,cv_msg_003a18_033   -- 会社コード指定不可エラーメッセージ
                    ,cv_tkn_date         -- トークン
                    ,TO_CHAR(gd_hkd_start_date, cv_format_date_ymds)  -- プロファイル「伊藤園北海道適用開始日付」
                   );
      RAISE global_api_expt;
    END IF;
    --
    --============================================
    -- 顧客番号、会社コードの制約チェック
    --============================================
    lv_err_flag := 'N';
    IF (gv_comp_spin_off_flag = 'Y') THEN
      -- 分社化対応フラグがYの場合
      IF (iv_customer_code14 IS NULL AND
          iv_customer_code21 IS NULL AND
          iv_customer_code20 IS NULL AND
          iv_customer_code10 IS NULL) THEN
        -- パラメータ「顧客番号」がすべてNULL
        IF (iv_company_cd IS NULL) THEN
          -- パラメータ「会社コード」もNULL
          lv_err_flag := 'Y';
        END IF;
      ELSE
        -- パラメータ「顧客番号」のいずれかがNOT NULL
        IF (iv_company_cd IS NOT NULL) THEN
          -- パラメータ「会社コード」もNOT NULL
          lv_err_flag := 'Y';
        END IF;
      END IF;
      --
      IF (lv_err_flag = 'Y') THEN
        -- 制約エラーありの場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_msg_kbn_cfr      -- 'XXCFR'
                      ,cv_msg_003a18_034   -- パラメータ制約エラーメッセージ
                     );
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    --============================================
    -- 請求書作成会社コードを取得
    --============================================
    lv_cond_cust_cd := NULL;
    IF (gv_comp_spin_off_flag = 'N') THEN
      -- 分社化対応フラグがNの場合
      gv_drafting_company := '001';
    ELSE
      -- 分社化対応フラグがYの場合
      --
      IF (iv_customer_code14 IS NOT NULL) THEN
        -- パラメータ「売掛管理先顧客」がNOT NULLの場合
        lv_cond_cust_cd := iv_customer_code14;
      ELSIF (iv_customer_code21 IS NOT NULL) THEN
        -- パラメータ「統括請求書用顧客」がNOT NULLの場合
        lv_cond_cust_cd := iv_customer_code21;
      ELSIF (iv_customer_code20 IS NOT NULL) THEN
        -- パラメータ「請求書用顧客」がNOT NULLの場合
        lv_cond_cust_cd := iv_customer_code20;
      ELSIF (iv_customer_code10 IS NOT NULL) THEN
        -- パラメータ「顧客」がNOT NULLの場合
        lv_cond_cust_cd := iv_customer_code10;
      END IF;
      --
      IF (lv_cond_cust_cd IS NOT NULL) THEN
        -- 顧客番号がNOT NULLの場合
        --
        -- 顧客番号に紐づく請求拠点より請求書作成会社コードを取得
        SELECT NVL(
                 -- 会社コード取得（部門経由）関数
                 xxcfr_common_pkg.get_company_code(
                   xca.bill_base_code    -- 請求拠点コード
                  ,gn_set_of_bks_id      -- 会計帳簿ID
                  ,gd_target_date        -- 締日
                 )
                ,'001'
               )
        INTO   gv_drafting_company
        FROM   xxcmm_cust_accounts    xca  -- 顧客追加情報テーブル
        WHERE  xca.customer_code = lv_cond_cust_cd
        ;
      ELSIF (iv_company_cd IS NOT NULL) THEN
        -- パラメータ「会社コード」がNOT NULLの場合
        gv_drafting_company :=
          -- 会社コード変換関数
          xxcfr_common_pkg.conv_company_code(
            iv_company_cd   -- 会社コード
           ,gd_target_date  -- 締日
          );
      END IF;
    END IF;
    --
    --============================================
    -- 請求書作成会社の登録番号を取得
    --============================================
    gv_t_number := xxcfr_common_pkg.get_invoice_regnum(
                     gv_drafting_company    -- 請求書作成会社コード
                   );
    --
    IF (gv_t_number IS NULL) THEN
      -- 登録番号がNULLの場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_msg_kbn_cfr      -- 'XXCFR'
                    ,cv_msg_003a18_017   -- 値取得エラーメッセージ
                    ,cv_tkn_get_data     -- トークン
                    ,cv_msg_003a18_035   -- トークン値(登録番号)
                   );
      RAISE global_api_expt;
    END IF;
    --
    --============================================
    -- 請求書作成会社の請求書SVF情報を取得
    --============================================
    -- 請求書タイプを設定
    IF (gv_bill_red_flag = '0') THEN
      -- 請求書朱印部門存在フラグが0(存在しない)の場合
      lv_invoice_type := '01';   -- 黒色
    ELSE
      lv_invoice_type := '01_2'; -- 朱色
    END IF;
    --
    -- 請求書SVF情報取得関数
    xxcfr_common_pkg.get_invoice_svf_info(
      iv_file_id          => cv_pkg_name               -- 帳票ID
     ,iv_invoice_type     => lv_invoice_type           -- 請求書タイプ
     ,iv_company_code     => gv_drafting_company       -- 会社コード
     ,ov_frm_file         => lv_frm_file               -- フォーム様式ファイル名
     ,ov_vrq_file         => lv_vrq_file               -- クエリー様式ファイル名
     ,ov_errbuf           => lv_errbuf                 -- エラーメッセージ
     ,ov_retcode          => lv_retcode                -- リターンコード
     ,ov_errmsg           => lv_errmsg                 -- ユーザーエラーメッセージ
    );
    --
    IF (lv_errbuf <> cv_status_normal) THEN
      -- 正常終了しなかった場合
      RAISE global_api_expt;
    ELSIF (lv_frm_file IS NULL OR lv_vrq_file IS NULL) THEN
      -- 様式ファイル名のいずれかがNULLの場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_msg_kbn_cfr      -- 'XXCFR'
                    ,cv_msg_003a18_017   -- 値取得エラーメッセージ
                    ,cv_tkn_get_data     -- トークン
                    ,cv_msg_003a18_036   -- トークン値(請求書SVF情報)
                   );
      RAISE global_api_expt;
    ELSE
      -- 各様式ファイル名をグローバル変数に格納
      gv_frm_file := lv_frm_file;  -- フォーム様式ファイル名
      gv_vrq_file := lv_vrq_file;  -- クエリー様式ファイル名
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END get_company_info;
-- Ver1.96 ADD END
--
  /**********************************************************************************
   * Procedure Name   : put_account_warning
   * Description      : 顧客紐付け警告出力
   ***********************************************************************************/
  PROCEDURE put_account_warning(
    iv_customer_class_code  IN   VARCHAR2,            -- 顧客区分
    iv_customer_code        IN   VARCHAR2,            -- 顧客コード
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_account_warning'; -- プログラム名
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
    lv_data_msg  VARCHAR2(5000);        -- ログ出力メッセージ
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
    -- 売掛管理先顧客存在なしメッセージ出力
    IF (iv_customer_class_code = cv_customer_class_code14) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a18_023
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- 統括請求書用顧客存在なしメッセージ出力
    ELSIF (iv_customer_class_code = cv_customer_class_code21) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a18_024
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- 請求書用顧客存在なしメッセージ出力
    ELSIF (iv_customer_class_code = cv_customer_class_code20) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a18_022
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    END IF;
--
    -- 顧客紐付け警告存在フラグを存在ありに変更する
    gv_warning_flag := cv_status_yes;
--
--###########################  固定部 END   ############################
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END put_account_warning;
--
-- Add 2013.12.13 Ver1.60 Start
  /**********************************************************************************
   * Procedure Name   : update_work_table
   * Description      : ワークテーブルデータ更新(A-11)
   ***********************************************************************************/
  PROCEDURE update_work_table(
-- Add 2016.09.06 Ver1.91 Start
    iv_tax_output_type     IN VARCHAR2,   -- 税別内訳出力区分
-- Add 2016.09.06 Ver1.91 End
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_work_table'; -- プログラム名
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
    cn_no_tax          CONSTANT NUMBER := 0;
-- Add 2016.09.06 Ver1.91 Start
    cv_tax_op_type_yes CONSTANT VARCHAR2(1) := '2';            -- 税別内訳出力あり
-- Add 2016.09.06 Ver1.91 End
--
    -- *** ローカル変数 ***
    lt_bill_cust_code  xxcfr_rep_st_invoice_inc_tax_d.bill_cust_code%TYPE;
    lt_location_code   xxcfr_rep_st_invoice_inc_tax_d.location_code%TYPE;
-- Add 2015.07.31 Ver1.80 Start
    lt_bill_cust_code2 xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE;
    lt_location_code2  xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE;
    lt_bill_cust_code3 xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE;
    lt_location_code3  xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE;
    lt_ship_cust_code3 xxcfr_rep_st_inv_inc_tax_a_l.ship_cust_code%TYPE;
    lt_bill_cust_code5 xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE;
    lt_location_code5  xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE;
    lt_bill_cust_code6 xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE;
    lt_location_code6  xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE;
    lt_ship_cust_code6 xxcfr_rep_st_inv_inc_tax_b_l.ship_cust_code%TYPE;
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
    lt_bill_cust_code8 xxcfr_rep_st_inv_inc_tax_c_l.bill_cust_code%TYPE;
    lt_location_code8  xxcfr_rep_st_inv_inc_tax_c_l.location_code%TYPE;
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
    lt_bill_cust_code9 xxcfr_rep_st_inv_inc_tax_d_l.bill_cust_code%TYPE;
    lt_location_code9  xxcfr_rep_st_inv_inc_tax_d_l.location_code%TYPE;
    lt_ship_cust_code9 xxcfr_rep_st_inv_inc_tax_d_l.ship_cust_code%TYPE;
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- 2023/07/04 Ver1.95 ADD Start
    lt_bill_cust_code11 xxcfr_rep_st_inv_inc_tax_d_l.bill_cust_code%TYPE;
    lt_location_code11  xxcfr_rep_st_inv_inc_tax_d_l.location_code%TYPE;
-- 2023/07/04 Ver1.95 ADD End
    ln_cust_cnt        PLS_INTEGER;
    ln_int             PLS_INTEGER := 0;
--
    -- *** ローカル・カーソル ***
    CURSOR update_work_cur
    IS
      SELECT xrsi.bill_cust_code      bill_cust_code      ,  --顧客コード
             xrsi.location_code       location_code       ,  --担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsi.tax_rate            tax_rate            ,  --税率
             xrsi.category            category            ,  --内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
-- Modify 2023.07.04 Ver1.95 Start
--             SUM( xrsi.slip_sum ) + SUM( xrsi.slip_tax_sum ) tax_rate_by_sum  --税率別お買上げ金額
             SUM( CASE WHEN xrsi.invoice_tax_div IS NULL THEN
                xrsi.slip_sum                                -- 伝票金額
             WHEN xrsi.invoice_tax_div = cn_invoice_tax_div THEN
                xrsi.inv_amount_sum                          -- 税抜合計１（税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsi.inv_amount_sum2                         -- 税抜合計２（明細毎の税抜額）
             END )                    tax_rate_by_sum,       -- 税抜お買上げ金額
             --
             SUM( CASE WHEN xrsi.invoice_tax_div IS NULL THEN
                xrsi.slip_tax_sum                            -- 伝票税額
             WHEN xrsi.invoice_tax_div = cn_invoice_tax_div THEN
                xrsi.tax_amount_sum                          -- 税額合計１（税込請求金額 - 税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsi.tax_amount_sum2                         -- 税額合計２（明細毎の積上税額）
             END )                    tax_rate_by_tax_sum    -- 消費税額
-- Modify 2023.07.04 Ver1.95 End
      FROM   xxcfr_rep_st_invoice_inc_tax_d  xrsi
      WHERE  xrsi.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsi.tax_rate   <> cn_no_tax                    --非課税（税率0%)以外
      AND    xrsi.category   IS NOT NULL                     --内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsi.bill_cust_code, -- 顧客コード
             xrsi.location_code,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsi.tax_rate        -- 消費税率(編集用)
             xrsi.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsi.bill_cust_code, -- 顧客コード
             xrsi.location_code,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsi.tax_rate        -- 消費税率(編集用) ※税率の小さい順に設定
             xrsi.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
-- Add 2023.07.04 Ver1.95 Start
    --ヘッダー用の当月お買上げ額、及び消費税額を取得
    CURSOR update_work_1b_cur
    IS
      SELECT xrsi.bill_cust_code      bill_cust_code      ,  -- 顧客コード
             xrsi.location_code       location_code       ,  -- 担当拠点コード
             SUM( CASE WHEN xrsi.invoice_tax_div IS NULL THEN
                xrsi.slip_sum                                -- 伝票金額
             WHEN xrsi.invoice_tax_div = cn_invoice_tax_div THEN
                xrsi.inv_amount_sum                          -- 税抜合計１（税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsi.inv_amount_sum2                         -- 税抜合計２（明細毎の税抜額）
             END )                    slip_sum,              -- 税抜お買上げ金額
             --
             SUM( CASE WHEN xrsi.invoice_tax_div IS NULL THEN
                    xrsi.slip_tax_sum                        -- 伝票税額
                  WHEN xrsi.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsi.tax_amount_sum                      -- 税額合計１（税込請求金額 - 税込請求金額サマリに消費税率を除した値）
                  ELSE
                    xrsi.tax_amount_sum2                     -- 税額合計２（明細毎の積上税額）
             END )                    tax_sum                -- ヘッダー用当月消費税額
      FROM   xxcfr_rep_st_invoice_inc_tax_d  xrsi
      WHERE  xrsi.request_id  = cn_request_id
      GROUP BY
             xrsi.bill_cust_code,                            -- 顧客コード
             xrsi.location_code                              -- 担当拠点コード
      ORDER BY
             xrsi.bill_cust_code,                            -- 顧客コード
             xrsi.location_code                              -- 担当拠点コード
      ;
-- Add 2023.07.04 Ver1.95 End
--
-- Add 2015.07.31 Ver1.80 Start
    CURSOR update_work_2_cur
    IS
      SELECT xrsial.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsial.location_code                                location_code  ,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate                                     tax_rate       ,  -- 消費税率(編集用)
             xrsial.category                                     category       ,  -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
-- Modify 2023.07.04 Ver1.95 Start
--             SUM( xrsial.slip_sum ) + SUM( xrsial.slip_tax_sum ) tax_rate_by_sum   -- 税別お買上げ額
             SUM( CASE WHEN xrsial.invoice_tax_div IS NULL THEN
                xrsial.slip_sum                                -- 伝票金額
             WHEN xrsial.invoice_tax_div = cn_invoice_tax_div THEN
                xrsial.inv_amount_sum                          -- 税抜合計１（税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsial.inv_amount_sum2                         -- 税抜合計２（明細毎の税抜額）
             END )                    tax_rate_by_sum,         -- 税抜お買上げ金額
             --
             SUM( CASE WHEN xrsial.invoice_tax_div IS NULL THEN
                xrsial.slip_tax_sum                            -- 伝票税額
             WHEN xrsial.invoice_tax_div = cn_invoice_tax_div THEN
                xrsial.tax_amount_sum                          -- 税額合計１（税込請求金額 - 税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsial.tax_amount_sum2                         -- 税額合計２（明細毎の積上税額）
             END )                    tax_rate_by_tax_sum      -- 消費税額
-- Modify 2023.07.04 Ver1.95 End
      FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsial
      WHERE  xrsial.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsial.tax_rate   <> cn_no_tax                    -- 非課税（税率0%)以外
      AND    xrsial.category   IS NOT NULL                     --内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsial.bill_cust_code, -- 顧客コード
             xrsial.location_code,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate        -- 消費税率(編集用)
             xrsial.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsial.bill_cust_code, -- 顧客コード
             xrsial.location_code,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate        -- 消費税率(編集用) ※税率の小さい順に設定
             xrsial.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
-- Add 2023.07.04 Ver1.95 Start
    --ヘッダー用の当月お買上げ額、及び消費税額を取得
    CURSOR update_work_2b_cur
    IS
      SELECT xrsial.bill_cust_code      bill_cust_code      ,  -- 顧客コード
             xrsial.location_code       location_code       ,  -- 担当拠点コード
             SUM( CASE WHEN xrsial.invoice_tax_div IS NULL THEN
                xrsial.slip_sum                                -- 伝票金額
             WHEN xrsial.invoice_tax_div = cn_invoice_tax_div THEN
                xrsial.inv_amount_sum                          -- 税抜合計１（税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsial.inv_amount_sum2                         -- 税抜合計２（明細毎の税抜額）
             END )                    slip_sum,                -- 税抜お買上げ金額
             --
             SUM( CASE WHEN xrsial.invoice_tax_div IS NULL THEN
                    xrsial.slip_tax_sum                        -- 伝票税額
                  WHEN xrsial.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsial.tax_amount_sum                      -- 税額合計１（税込請求金額 - 税込請求金額サマリに消費税率を除した値）
                  ELSE
                    xrsial.tax_amount_sum2                     -- 税額合計２（明細毎の積上税額）
             END )                    tax_sum                  -- ヘッダー用当月消費税額
      FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsial
      WHERE  xrsial.request_id  = cn_request_id
      GROUP BY
             xrsial.bill_cust_code,                            -- 顧客コード
             xrsial.location_code                              -- 担当拠点コード
      ORDER BY
             xrsial.bill_cust_code,                            -- 顧客コード
             xrsial.location_code                              -- 担当拠点コード
      ;
-- Add 2023.07.04 Ver1.95 End
--
    CURSOR update_work_3_cur
    IS
      SELECT xrsial.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsial.location_code                                location_code  ,  -- 担当拠点コード
             xrsial.ship_cust_code                               ship_cust_code ,  -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate                                     tax_rate       ,  -- 消費税率(編集用)
             xrsial.category                                     category       ,  -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsial.slip_sum ) + SUM( xrsial.slip_tax_sum ) tax_rate_by_sum   -- 税込お買上げ額
      FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsial
      WHERE  xrsial.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsial.tax_rate   <> cn_no_tax                    -- 非課税（税率0%)以外
      AND    xrsial.category   IS NOT NULL                     --内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsial.bill_cust_code, -- 顧客コード
             xrsial.location_code,  -- 担当拠点コード
             xrsial.ship_cust_code, -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate        -- 消費税率(編集用)
             xrsial.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsial.bill_cust_code, -- 顧客コード
             xrsial.location_code,  -- 担当拠点コード
             xrsial.ship_cust_code, -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsial.tax_rate        -- 消費税率(編集用) ※税率の小さい順に設定
             xrsial.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
    CURSOR update_work_4_cur
    IS
      SELECT xrsial.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsial.location_code                                location_code  ,  -- 担当拠点コード
             xrsial.ship_cust_code                               ship_cust_code ,  -- 納品先顧客コード
             SUM( xrsial.slip_sum ) + SUM( xrsial.slip_tax_sum ) store_sum         -- 税込お買上げ額
      FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsial
      WHERE  xrsial.request_id  = cn_request_id
      GROUP BY
             xrsial.bill_cust_code, -- 顧客コード
             xrsial.location_code,  -- 担当拠点コード
             xrsial.ship_cust_code  -- 納品先顧客コード
      ORDER BY
             xrsial.bill_cust_code, -- 顧客コード
             xrsial.location_code,  -- 担当拠点コード
             xrsial.ship_cust_code  -- 納品先顧客コード
      ;
--
    CURSOR update_work_5_cur
    IS
      SELECT xrsibl.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsibl.location_code                                location_code  ,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate                                     tax_rate       ,  -- 消費税率(編集用)
             xrsibl.category                                     category       ,  -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
-- Modify 2023.07.04 Ver1.95 Start
--             SUM( xrsibl.slip_sum ) + SUM( xrsibl.slip_tax_sum ) tax_rate_by_sum   -- 税別お買上げ額
             SUM( CASE WHEN xrsibl.invoice_tax_div IS NULL THEN
                xrsibl.slip_sum                                -- 伝票金額
             WHEN xrsibl.invoice_tax_div = cn_invoice_tax_div THEN
                xrsibl.inv_amount_sum                          -- 税抜合計１（税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsibl.inv_amount_sum2                         -- 税抜合計２（明細毎の税抜額）
             END )                    tax_rate_by_sum,         -- 税抜お買上げ金額
             --
             SUM( CASE WHEN xrsibl.invoice_tax_div IS NULL THEN
                xrsibl.slip_tax_sum                            -- 伝票税額
             WHEN xrsibl.invoice_tax_div = cn_invoice_tax_div THEN
                xrsibl.tax_amount_sum                          -- 税額合計１（税込請求金額 - 税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsibl.tax_amount_sum2                         -- 税額合計２（明細毎の積上税額）
             END )                    tax_rate_by_tax_sum      -- 消費税額
-- Modify 2023.07.04 Ver1.95 End
      FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
      WHERE  xrsibl.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsibl.tax_rate   <> cn_no_tax                    -- 非課税（税率0%)以外
      AND    xrsibl.category   IS NOT NULL                     --内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsibl.bill_cust_code, -- 顧客コード
             xrsibl.location_code,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate        -- 消費税率(編集用)
             xrsibl.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsibl.bill_cust_code, -- 顧客コード
             xrsibl.location_code,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate        -- 消費税率(編集用) ※税率の小さい順に設定
             xrsibl.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
-- Add 2023.07.04 Ver1.95 Start
    --ヘッダー用の当月お買上げ額、及び消費税額を取得
    CURSOR update_work_5b_cur
    IS
      SELECT xrsibl.bill_cust_code      bill_cust_code      ,  -- 顧客コード
             xrsibl.location_code       location_code       ,  -- 担当拠点コード
             SUM( CASE WHEN xrsibl.invoice_tax_div IS NULL THEN
                xrsibl.slip_sum                                -- 伝票金額
             WHEN xrsibl.invoice_tax_div = cn_invoice_tax_div THEN
                xrsibl.inv_amount_sum                          -- 税抜合計１（税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsibl.inv_amount_sum2                         -- 税抜合計２（明細毎の税抜額）
             END )                    slip_sum,                -- 税抜お買上げ金額
             --
             SUM( CASE WHEN xrsibl.invoice_tax_div IS NULL THEN
                    xrsibl.slip_tax_sum                        -- 伝票税額
                  WHEN xrsibl.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsibl.tax_amount_sum                      -- 税額合計１（税込請求金額 - 税込請求金額サマリに消費税率を除した値）
                  ELSE
                    xrsibl.tax_amount_sum2                     -- 税額合計２（明細毎の積上税額）
             END )                    tax_sum                  -- ヘッダー用当月消費税額
      FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
      WHERE  xrsibl.request_id  = cn_request_id
      GROUP BY
             xrsibl.bill_cust_code,                            -- 顧客コード
             xrsibl.location_code                              -- 担当拠点コード
      ORDER BY
             xrsibl.bill_cust_code,                            -- 顧客コード
             xrsibl.location_code                              -- 担当拠点コード
      ;
-- Add 2023.07.04 Ver1.95 End
--
    CURSOR update_work_6_cur
    IS
      SELECT xrsibl.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsibl.location_code                                location_code  ,  -- 担当拠点コード
             xrsibl.ship_cust_code                               ship_cust_code ,  -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate                                     tax_rate       ,  -- 消費税率(編集用)
             xrsibl.category                                     category       ,  -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
             SUM( xrsibl.slip_sum ) + SUM( xrsibl.slip_tax_sum ) tax_rate_by_sum   -- 税込お買上げ額
      FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
      WHERE  xrsibl.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsibl.tax_rate   <> cn_no_tax                    -- 非課税（税率0%)以外
      AND    xrsibl.category   IS NOT NULL                     --内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsibl.bill_cust_code, -- 顧客コード
             xrsibl.location_code,  -- 担当拠点コード
             xrsibl.ship_cust_code, -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate        -- 消費税率(編集用)
             xrsibl.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsibl.bill_cust_code, -- 顧客コード
             xrsibl.location_code,  -- 担当拠点コード
             xrsibl.ship_cust_code, -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsibl.tax_rate        -- 消費税率(編集用) ※税率の小さい順に設定
             xrsibl.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
    CURSOR update_work_7_cur
    IS
      SELECT xrsibl.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsibl.location_code                                location_code  ,  -- 担当拠点コード
             xrsibl.ship_cust_code                               ship_cust_code ,  -- 納品先顧客コード
             SUM( xrsibl.slip_sum ) + SUM( xrsibl.slip_tax_sum ) store_sum         -- 税込お買上げ額
      FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
      WHERE  xrsibl.request_id  = cn_request_id
      GROUP BY
             xrsibl.bill_cust_code, -- 顧客コード
             xrsibl.location_code,  -- 担当拠点コード
             xrsibl.ship_cust_code  -- 納品先顧客コード
      ORDER BY
             xrsibl.bill_cust_code, -- 顧客コード
             xrsibl.location_code,  -- 担当拠点コード
             xrsibl.ship_cust_code  -- 納品先顧客コード
      ;
--
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
    CURSOR update_work_8_cur
    IS
      SELECT xrsicl.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsicl.location_code                                location_code  ,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsicl.tax_rate                                     tax_rate       ,  -- 消費税率(編集用)
             xrsicl.category                                     category       ,  -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
-- Modify 2023.07.04 Ver1.95 Start
--             SUM( xrsicl.slip_sum ) + SUM( xrsicl.slip_tax_sum ) tax_rate_by_sum   -- 税別お買上げ額
             SUM( CASE WHEN xrsicl.invoice_tax_div IS NULL THEN
                xrsicl.slip_sum                                -- 伝票金額
             WHEN xrsicl.invoice_tax_div = cn_invoice_tax_div THEN
                xrsicl.inv_amount_sum                          -- 税抜合計１（税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsicl.inv_amount_sum2                         -- 税抜合計２（明細毎の税抜額）
             END )                    tax_rate_by_sum,         -- 税抜お買上げ金額
             --
             SUM( CASE WHEN xrsicl.invoice_tax_div IS NULL THEN
                xrsicl.slip_tax_sum                            -- 伝票税額
             WHEN xrsicl.invoice_tax_div = cn_invoice_tax_div THEN
                xrsicl.tax_amount_sum                          -- 税額合計１（税込請求金額 - 税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsicl.tax_amount_sum2                         -- 税額合計２（明細毎の積上税額）
             END )                    tax_rate_by_tax_sum      -- 消費税額
-- Modify 2023.07.04 Ver1.95 End
      FROM   xxcfr_rep_st_inv_inc_tax_c_l  xrsicl
      WHERE  xrsicl.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsicl.tax_rate   <> cn_no_tax                    -- 非課税（税率0%)以外
      AND    xrsicl.category   IS NOT NULL                     --内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsicl.bill_cust_code, -- 顧客コード
             xrsicl.location_code,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsicl.tax_rate        -- 消費税率(編集用)
             xrsicl.category        --  内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsicl.bill_cust_code, -- 顧客コード
             xrsicl.location_code,  -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsicl.tax_rate        -- 消費税率(編集用) ※税率の小さい順に設定
             xrsicl.category        --  内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
-- Add 2023.07.04 Ver1.95 Start
    --ヘッダー用の当月お買上げ額、及び消費税額を取得
    CURSOR update_work_8b_cur
    IS
      SELECT xrsicl.bill_cust_code      bill_cust_code      ,  -- 顧客コード
             xrsicl.location_code       location_code       ,  -- 担当拠点コード
             SUM( CASE WHEN xrsicl.invoice_tax_div IS NULL THEN
                xrsicl.slip_sum                                -- 伝票金額
             WHEN xrsicl.invoice_tax_div = cn_invoice_tax_div THEN
                xrsicl.inv_amount_sum                          -- 税抜合計１（税込請求金額サマリに消費税率を除した値）
             ELSE
                xrsicl.inv_amount_sum2                         -- 税抜合計２（明細毎の税抜額）
             END )                    slip_sum,                -- 税抜お買上げ金額
             --
             SUM( CASE WHEN xrsicl.invoice_tax_div IS NULL THEN
                    xrsicl.slip_tax_sum                        -- 伝票税額
                  WHEN xrsicl.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsicl.tax_amount_sum                      -- 税額合計１（税込請求金額 - 税込請求金額サマリに消費税率を除した値）
                  ELSE
                    xrsicl.tax_amount_sum2                     -- 税額合計２（明細毎の積上税額）
             END )                    tax_sum                  -- ヘッダー用当月消費税額
      FROM   xxcfr_rep_st_inv_inc_tax_c_l  xrsicl
      WHERE  xrsicl.request_id  = cn_request_id
      GROUP BY
             xrsicl.bill_cust_code,                            -- 顧客コード
             xrsicl.location_code                              -- 担当拠点コード
      ORDER BY
             xrsicl.bill_cust_code,                            -- 顧客コード
             xrsicl.location_code                              -- 担当拠点コード
      ;
-- Add 2023.07.04 Ver1.95 End
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
    --単位D明細の税別内訳更新用
    CURSOR update_work_9_cur
    IS
      SELECT xrsidl.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsidl.location_code                                location_code  ,  -- 担当拠点コード
             xrsidl.ship_cust_code                               ship_cust_code ,  -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsidl.tax_rate                                     tax_rate       ,  -- 消費税率(編集用)
             xrsidl.category                                     category       ,  -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
-- 2023/07/04 Ver1.95 MOD Start
             SUM( CASE WHEN xrsidl.invoice_tax_div IS NULL THEN
                    xrsidl.slip_sum                            -- 伝票金額
                  WHEN xrsidl.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsidl.inv_amount_sum                      -- 税抜合計１
                  ELSE
                    xrsidl.inv_amount_sum2                     -- 税抜合計２
                  END )                                          tax_rate_by_sum,  -- お買上げ額(税別内訳)
             SUM( CASE WHEN xrsidl.invoice_tax_div IS NULL THEN
                    xrsidl.slip_tax_sum                        -- 伝票税額
                  WHEN xrsidl.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsidl.tax_amount_sum                      -- 税額合計１
                  ELSE
                    xrsidl.tax_amount_sum2                     -- 税額合計２
                  END )                                          tax_rate_by_tax_sum -- 消費税等(税別内訳)
--             SUM( xrsidl.slip_sum ) + SUM( xrsidl.slip_tax_sum ) tax_rate_by_sum   -- 税別お買上げ額
-- 2023/07/04 Ver1.95 MOD End
      FROM   xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
      WHERE  xrsidl.request_id  = cn_request_id
-- Modify 2019.09.03 Ver1.93 Start
--      AND    xrsidl.tax_rate   <> cn_no_tax                    -- 非課税（税率0%)以外
      AND    xrsidl.category   IS NOT NULL                     --内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      GROUP BY
             xrsidl.bill_cust_code, -- 顧客コード
             xrsidl.location_code,  -- 担当拠点コード
             xrsidl.ship_cust_code, -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsidl.tax_rate        -- 消費税率(編集用)
             xrsidl.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ORDER BY
             xrsidl.bill_cust_code, -- 顧客コード
             xrsidl.location_code,  -- 担当拠点コード
             xrsidl.ship_cust_code, -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--             xrsidl.tax_rate        -- 消費税率(編集用) ※税率の小さい順に設定
             xrsidl.category        -- 内訳分類(編集用)
-- Modify 2019.09.03 Ver1.93 End
      ;
--
    --単位D明細の当月ご請求額更新用
    CURSOR update_work_10_cur
    IS
      SELECT xrsidl.bill_cust_code                               bill_cust_code ,  -- 顧客コード
             xrsidl.location_code                                location_code  ,  -- 担当拠点コード
             xrsidl.ship_cust_code                               ship_cust_code ,  -- 納品先顧客コード
-- 2023/07/04 Ver1.95 MOD Start
             SUM( CASE WHEN xrsidl.invoice_tax_div IS NULL THEN
                    xrsidl.slip_sum                            -- 伝票金額
                  WHEN xrsidl.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsidl.inv_amount_sum                      -- 税抜合計１
                  ELSE
                    xrsidl.inv_amount_sum2                     -- 税抜合計２
                  END )                                          store_sum,        -- お買上げ額(税別内訳)
             SUM( CASE WHEN xrsidl.invoice_tax_div IS NULL THEN
                    xrsidl.slip_tax_sum                        -- 伝票税額
                  WHEN xrsidl.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsidl.tax_amount_sum                      -- 税額合計１
                  ELSE
                    xrsidl.tax_amount_sum2                     -- 税額合計２
                  END )                                          store_tax_sum     -- 消費税等(税別内訳)
--             SUM( xrsidl.slip_sum ) + SUM( xrsidl.slip_tax_sum ) store_sum         -- 税別お買上げ額
-- 2023/07/04 Ver1.95 MOD End
      FROM   xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
      WHERE  xrsidl.request_id  = cn_request_id
      GROUP BY
             xrsidl.bill_cust_code, -- 顧客コード
             xrsidl.location_code,  -- 担当拠点コード
             xrsidl.ship_cust_code  -- 納品先顧客コード
      ORDER BY
             xrsidl.bill_cust_code, -- 顧客コード
             xrsidl.location_code,  -- 担当拠点コード
             xrsidl.ship_cust_code  -- 納品先顧客コード
      ;
--
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- 2023/07/04 Ver1.95 ADD Start
    -- 単位D総括表の税別内訳
    CURSOR update_work_11_cur
    IS
      SELECT xrsidl.bill_cust_code      bill_cust_code      ,  -- 顧客コード
             xrsidl.location_code       location_code       ,  -- 担当拠点コード
             xrsidl.category            category            ,  -- 内訳分類(編集用)
             SUM( CASE WHEN xrsidl.invoice_tax_div IS NULL THEN
                    xrsidl.slip_sum                            -- 伝票金額
                  WHEN xrsidl.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsidl.inv_amount_sum                      -- 税抜合計１
                  ELSE
                    xrsidl.inv_amount_sum2                     -- 税抜合計２
                  END )                 slip_sum,              -- お買上げ額(税別内訳)
             SUM( CASE WHEN xrsidl.invoice_tax_div IS NULL THEN
                    xrsidl.slip_tax_sum                        -- 伝票税額
                  WHEN xrsidl.invoice_tax_div = cn_invoice_tax_div THEN
                    xrsidl.tax_amount_sum                      -- 税額合計１
                  ELSE
                    xrsidl.tax_amount_sum2                     -- 税額合計２
                  END )                 tax_sum                -- 消費税等(税別内訳)
      FROM   xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
      WHERE  xrsidl.request_id  = cn_request_id
      AND    xrsidl.category    IS NOT NULL
      GROUP BY
             xrsidl.bill_cust_code,                            -- 顧客コード
             xrsidl.location_code,                             -- 担当拠点コード
             xrsidl.category                                   -- 内訳分類(編集用)
      ORDER BY
             xrsidl.bill_cust_code,                            -- 顧客コード
             xrsidl.location_code,                             -- 担当拠点コード
             xrsidl.category                                   -- 内訳分類(編集用)
      ;
--
    -- 単位D総括表の当月お買上げ額、消費税等
    CURSOR update_work_12_cur
    IS
      SELECT xrsidh.bill_cust_code        bill_cust_code    ,  -- 顧客コード
             xrsidh.location_code         location_code     ,  -- 担当拠点コード
             SUM(xrsidh.store_charge_sum) slip_sum          ,  -- 店舗金額(合計)
             SUM(xrsidh.store_tax_sum)    tax_sum              -- 店舗税額(合計)
      FROM   xxcfr_rep_st_inv_d_h  xrsidh
      WHERE  xrsidh.request_id  = cn_request_id
      GROUP BY
             xrsidh.bill_cust_code,                            -- 顧客コード
             xrsidh.location_code                              -- 担当拠点コード
      ORDER BY
             xrsidh.bill_cust_code,                            -- 顧客コード
             xrsidh.location_code                              -- 担当拠点コード
      ;
-- 2023/07/04 Ver1.95 ADD End
    -- *** ローカル・レコード ***
    update_work_rec  update_work_cur%ROWTYPE;
-- Add 2015.07.31 Ver1.80 Start
    update_work_2_rec  update_work_2_cur%ROWTYPE;
    update_work_3_rec  update_work_3_cur%ROWTYPE;
    update_work_4_rec  update_work_4_cur%ROWTYPE;
    update_work_5_rec  update_work_5_cur%ROWTYPE;
    update_work_6_rec  update_work_6_cur%ROWTYPE;
    update_work_7_rec  update_work_7_cur%ROWTYPE;
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
    update_work_8_rec  update_work_8_cur%ROWTYPE;
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
    update_work_9_rec  update_work_9_cur%ROWTYPE;
    update_work_10_rec update_work_10_cur%ROWTYPE;
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- Add 2023.07.04 Ver1.95 Start
    update_work_1b_rec  update_work_1b_cur%ROWTYPE;
    update_work_2b_rec  update_work_2b_cur%ROWTYPE;
    update_work_5b_rec  update_work_5b_cur%ROWTYPE;
    update_work_8b_rec  update_work_8b_cur%ROWTYPE;
-- Add 2023.07.04 Ver1.95 End
--
    -- *** ローカル・タイプ ***
    TYPE l_bill_cust_code_ttype IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_ttype  IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.location_code%TYPE   INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_ttype       IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_ttype       IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_ttype IS TABLE OF xxcfr_rep_st_invoice_inc_tax_d.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
-- Add 2015.07.31 Ver1.80 Start
--
    TYPE l_bill_cust_code_2_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_2_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE   INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_2_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_2_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_2_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_3_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_3_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_3_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_3_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_3_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_3_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_4_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_4_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_4_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_store_sum_4_ttype      IS TABLE OF xxcfr_rep_st_inv_inc_tax_a_l.store_sum%TYPE       INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_5_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_5_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE   INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_5_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_5_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_5_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_6_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_6_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_6_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_6_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_6_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_6_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
--
    TYPE l_bill_cust_code_7_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_7_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_7_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_store_sum_7_ttype      IS TABLE OF xxcfr_rep_st_inv_inc_tax_b_l.store_sum%TYPE       INDEX BY PLS_INTEGER;
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
--
    TYPE l_bill_cust_code_8_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_8_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.location_code%TYPE   INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_8_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_8_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.category%TYPE        INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_8_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_c_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
--
    TYPE l_bill_cust_code_9_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_9_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_9_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 Start
--    TYPE l_tax_rate_9_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.tax_rate1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_category_9_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.category1%TYPE       INDEX BY PLS_INTEGER;
-- Modify 2019.09.03 Ver1.93 End
    TYPE l_inc_tax_charge_9_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
-- 2023/07/04 Ver1.95 ADD Start
    TYPE l_tax_sum_9_ttype        IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.tax_sum1%TYPE        INDEX BY PLS_INTEGER;
-- 2023/07/04 Ver1.95 ADD End
--
    TYPE l_bill_cust_code_10_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_10_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_ship_cust_code_10_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.ship_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_store_sum_10_ttype      IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.store_sum%TYPE       INDEX BY PLS_INTEGER;
-- 2023/07/04 Ver1.95 ADD Start
    TYPE l_store_tax_sum_10_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.store_tax_sum%TYPE   INDEX BY PLS_INTEGER;
-- 2023/07/04 Ver1.95 ADD End
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- 2023/07/04 Ver1.95 ADD Start
    TYPE l_bill_cust_code_11_ttype IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.bill_cust_code%TYPE  INDEX BY PLS_INTEGER;
    TYPE l_location_code_11_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.location_code%TYPE   INDEX BY PLS_INTEGER;
    TYPE l_category_11_ttype       IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.category1%TYPE       INDEX BY PLS_INTEGER;
    TYPE l_ex_tax_charge_11_ttype  IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.inc_tax_charge1%TYPE INDEX BY PLS_INTEGER;
    TYPE l_tax_sum_11_ttype        IS TABLE OF xxcfr_rep_st_inv_inc_tax_d_l.tax_sum1%TYPE        INDEX BY PLS_INTEGER;
-- 2023/07/04 Ver1.95 ADD End
--
    l_bill_cust_code_tab     l_bill_cust_code_ttype;  --顧客コード
    l_location_code_tab      l_location_code_ttype;   --担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_tab          l_tax_rate_ttype;        --消費税率１
    l_category1_tab          l_category_ttype;        --内訳分類１
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_tab    l_inc_tax_charge_ttype;  --当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_tab          l_tax_rate_ttype;        --消費税率２
    l_category2_tab          l_category_ttype;        --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_tab    l_inc_tax_charge_ttype;  --当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
    l_category3_tab          l_category_ttype;        --内訳分類３
    l_inc_tax_charge3_tab    l_inc_tax_charge_ttype;  --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
--
-- Add 2015.07.31 Ver1.80 Start
    l_bill_cust_code_2_tab   l_bill_cust_code_2_ttype;  -- 顧客コード
    l_location_code_2_tab    l_location_code_2_ttype;   -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_2_tab        l_tax_rate_2_ttype;        -- 消費税率１
    l_category1_2_tab        l_category_2_ttype;        --内訳分類１
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_2_tab  l_inc_tax_charge_2_ttype;  -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_2_tab        l_tax_rate_2_ttype;        -- 消費税率２
    l_category2_2_tab        l_category_2_ttype;        --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_2_tab  l_inc_tax_charge_2_ttype;  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
    l_category3_2_tab        l_category_2_ttype;        --内訳分類３
    l_inc_tax_charge3_2_tab  l_inc_tax_charge_2_ttype;  --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_3_tab   l_bill_cust_code_3_ttype;  -- 顧客コード
    l_location_code_3_tab    l_location_code_3_ttype;   -- 担当拠点コード
    l_ship_cust_code_3_tab   l_ship_cust_code_3_ttype;  -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_3_tab        l_tax_rate_3_ttype;        -- 消費税率１
    l_category1_3_tab        l_category_3_ttype;        --内訳分類１
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_3_tab  l_inc_tax_charge_3_ttype;  -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_3_tab        l_tax_rate_3_ttype;        -- 消費税率２
    l_category2_3_tab        l_category_3_ttype;        --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_3_tab  l_inc_tax_charge_3_ttype;  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
    l_category3_3_tab        l_category_3_ttype;        --内訳分類３
    l_inc_tax_charge3_3_tab  l_inc_tax_charge_3_ttype;  --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_4_tab   l_bill_cust_code_4_ttype;  -- 顧客コード
    l_location_code_4_tab    l_location_code_4_ttype;   -- 担当拠点コード
    l_ship_cust_code_4_tab   l_ship_cust_code_4_ttype;  -- 納品先顧客コード
    l_store_sum_4_tab        l_store_sum_4_ttype;       -- 税別お買上げ額
--
    l_bill_cust_code_5_tab   l_bill_cust_code_5_ttype;  -- 顧客コード
    l_location_code_5_tab    l_location_code_5_ttype;   -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_5_tab        l_tax_rate_5_ttype;        -- 消費税率１
    l_category1_5_tab        l_category_5_ttype;        --内訳分類１
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_5_tab  l_inc_tax_charge_5_ttype;  -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_5_tab        l_tax_rate_5_ttype;        -- 消費税率２
    l_category2_5_tab        l_category_5_ttype;        --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_5_tab  l_inc_tax_charge_5_ttype;  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
    l_category3_5_tab        l_category_5_ttype;        --内訳分類３
    l_inc_tax_charge3_5_tab  l_inc_tax_charge_5_ttype;  --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_6_tab   l_bill_cust_code_6_ttype;  -- 顧客コード
    l_location_code_6_tab    l_location_code_6_ttype;   -- 担当拠点コード
    l_ship_cust_code_6_tab   l_ship_cust_code_6_ttype;  -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_6_tab        l_tax_rate_6_ttype;        -- 消費税率１
    l_category1_6_tab        l_category_6_ttype;        --内訳分類１
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_6_tab  l_inc_tax_charge_6_ttype;  -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_6_tab        l_tax_rate_6_ttype;        -- 消費税率２
    l_category2_6_tab        l_category_6_ttype;        --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_6_tab  l_inc_tax_charge_6_ttype;  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
    l_category3_6_tab        l_category_6_ttype;        --内訳分類３
    l_inc_tax_charge3_6_tab  l_inc_tax_charge_6_ttype;  --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_7_tab   l_bill_cust_code_7_ttype;  -- 顧客コード
    l_location_code_7_tab    l_location_code_7_ttype;   -- 担当拠点コード
    l_ship_cust_code_7_tab   l_ship_cust_code_7_ttype;  -- 納品先顧客コード
    l_store_sum_7_tab        l_store_sum_7_ttype;       -- 税別お買上げ額
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
--
    l_bill_cust_code_8_tab   l_bill_cust_code_8_ttype;  -- 顧客コード
    l_location_code_8_tab    l_location_code_8_ttype;   -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_8_tab        l_tax_rate_8_ttype;        -- 消費税率１
    l_category1_8_tab        l_category_8_ttype;        --内訳分類１
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_8_tab  l_inc_tax_charge_8_ttype;  -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_8_tab        l_tax_rate_8_ttype;        -- 消費税率２
    l_category2_8_tab        l_category_8_ttype;        --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_8_tab  l_inc_tax_charge_8_ttype;  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
    l_category3_8_tab        l_category_8_ttype;        --内訳分類３
    l_inc_tax_charge3_8_tab  l_inc_tax_charge_8_ttype;  --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
--
    l_bill_cust_code_9_tab   l_bill_cust_code_9_ttype;  -- 顧客コード
    l_location_code_9_tab    l_location_code_9_ttype;   -- 担当拠点コード
    l_ship_cust_code_9_tab   l_ship_cust_code_9_ttype;  -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate1_9_tab        l_tax_rate_9_ttype;        -- 消費税率１
    l_category1_9_tab        l_category_9_ttype;        --内訳分類１
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge1_9_tab  l_inc_tax_charge_9_ttype;  -- 当月お買上げ額１
-- 2023/07/04 Ver1.95 ADD Start
    l_tax_sum1_9_tab         l_tax_sum_9_ttype;         -- 消費税額１
-- 2023/07/04 Ver1.95 ADD End
-- Modify 2019.09.03 Ver1.93 Start
--    l_tax_rate2_9_tab        l_tax_rate_9_ttype;        -- 消費税率２
    l_category2_9_tab        l_category_9_ttype;        --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
    l_inc_tax_charge2_9_tab  l_inc_tax_charge_9_ttype;  -- 当月お買上げ額２
-- 2023/07/04 Ver1.95 ADD Start
    l_tax_sum2_9_tab         l_tax_sum_9_ttype;         -- 消費税額２
-- 2023/07/04 Ver1.95 ADD End
-- Add 2019.09.03 Ver1.93 Start
    l_category3_9_tab        l_category_9_ttype;        --内訳分類３
    l_inc_tax_charge3_9_tab  l_inc_tax_charge_9_ttype;  --当月お買上げ額３
-- 2023/07/04 Ver1.95 ADD Start
    l_tax_sum3_9_tab         l_tax_sum_9_ttype;         -- 消費税額３
-- 2023/07/04 Ver1.95 ADD End
-- Add 2019.09.03 Ver1.93 End
--
    l_bill_cust_code_10_tab  l_bill_cust_code_10_ttype;  -- 顧客コード
    l_location_code_10_tab   l_location_code_10_ttype;   -- 担当拠点コード
    l_ship_cust_code_10_tab  l_ship_cust_code_10_ttype;  -- 納品先顧客コード
    l_store_sum_10_tab       l_store_sum_10_ttype;       -- 税別お買上げ額
-- 2023/07/04 Ver1.95 ADD Start
    l_store_tax_sum_10_tab   l_store_tax_sum_10_ttype;   -- 消費税等
-- 2023/07/04 Ver1.95 ADD End
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- 2023/07/04 Ver1.95 ADD Start
    l_bill_cust_code_11_tab  l_bill_cust_code_11_ttype; -- 顧客コード
    l_location_code_11_tab   l_location_code_11_ttype;  -- 担当拠点コード
    l_category1_11_tab       l_category_11_ttype;       -- 内訳分類１
    l_ex_tax_charge1_11_tab  l_ex_tax_charge_11_ttype;  -- 当月お買上げ額１
    l_tax_sum1_11_tab        l_tax_sum_11_ttype;        -- 消費税額１
    l_category2_11_tab       l_category_11_ttype;       -- 内訳分類２
    l_ex_tax_charge2_11_tab  l_ex_tax_charge_11_ttype;  -- 当月お買上げ額２
    l_tax_sum2_11_tab        l_tax_sum_11_ttype;        -- 消費税額２
    l_category3_11_tab       l_category_11_ttype;       -- 内訳分類３
    l_ex_tax_charge3_11_tab  l_ex_tax_charge_11_ttype;  -- 当月お買上げ額３
    l_tax_sum3_11_tab        l_tax_sum_11_ttype;        -- 消費税額３
-- 2023/07/04 Ver1.95 ADD End
--
-- Add 2023.07.04 Ver1.95 Start
    TYPE l_tax_sum_ttype     IS TABLE OF xxcfr_rep_st_invoice_ex_tax_d.tax_sum1%TYPE       INDEX BY PLS_INTEGER;
    l_tax_sum1_tab           l_tax_sum_ttype;            --消費税額１
    l_tax_sum2_tab           l_tax_sum_ttype;            --消費税額２
    l_tax_sum3_tab           l_tax_sum_ttype;            --消費税額３
-- Add 2023.07.04 Ver1.95 End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- Mod 2015.07.31 Ver1.80 Start
--    <<edit_loop>>
--    FOR update_work_rec IN update_work_cur LOOP
----
--      --初回、又は、顧客コード・担当拠点コードがブレーク
--      IF (
--           ( lt_bill_cust_code IS NULL )
--           OR
--           ( lt_bill_cust_code <> update_work_rec.bill_cust_code )
--           OR
--           ( lt_location_code  <> update_work_rec.location_code )
--         )
--      THEN
--        --初期化、及び、１レコード目の税別項目設定
--        ln_cust_cnt                   := 1;                                   --ブレーク毎レコード件数初期化
--        ln_int                        := ln_int + 1;                          --配列カウントアップ
--        l_bill_cust_code_tab(ln_int)  := update_work_rec.bill_cust_code;      --顧客コード
--        l_location_code_tab(ln_int)   := update_work_rec.location_code;       --担当拠点コード
--        l_tax_rate1_tab(ln_int)       := update_work_rec.tax_rate;            --消費税率1
--        l_inc_tax_charge1_tab(ln_int) := update_work_rec.tax_rate_by_sum;     --当月お買上げ額１
--        l_tax_rate2_tab(ln_int)       := NULL;                                --消費税率２
--        l_inc_tax_charge2_tab(ln_int) := NULL;                                --当月お買上げ額２
--        lt_bill_cust_code             := update_work_rec.bill_cust_code;      --ブレークコード設定(顧客コード)
--        lt_location_code              := update_work_rec.location_code;       --ブレークコード設定(担当拠点コード)
--      ELSE
--        --同一顧客・担当拠点で2レコード目以降(2レコード以上は設定しない)
--        ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
--        --1顧客につき最大２つの税別項目を設定
--        IF ( ln_cust_cnt = 2 ) THEN
--          --２レコード目
--          l_tax_rate2_tab(ln_int)       := update_work_rec.tax_rate;          --消費税率２
--          l_inc_tax_charge2_tab(ln_int) := update_work_rec.tax_rate_by_sum;   --当月お買上げ額２
--        END IF;
--      END IF;
----
--    END LOOP edit_loop;
----
--    --一括更新
--    BEGIN
--      <<update_loop>>
--      FORALL i IN l_bill_cust_code_tab.FIRST..l_bill_cust_code_tab.LAST
--        UPDATE  xxcfr_rep_st_invoice_inc_tax_d  xrsi
--        SET     xrsi.tax_rate1        = l_tax_rate1_tab(i)
--               ,xrsi.inc_tax_charge1  = l_inc_tax_charge1_tab(i)
--               ,xrsi.tax_rate2        = l_tax_rate2_tab(i)
--               ,xrsi.inc_tax_charge2  = l_inc_tax_charge2_tab(i)
--        WHERE   xrsi.bill_cust_code   = l_bill_cust_code_tab(i)
--        AND     xrsi.location_code    = l_location_code_tab(i)
--        AND     xrsi.request_id       = cn_request_id
--        ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
--                                                       ,cv_msg_003a18_026    -- テーブル更新エラー
--                                                       ,cv_tkn_table         -- トークン'TABLE'
--                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
--                                                      -- 標準請求書税抜帳票ワークテーブル
--                             ,1
--                             ,5000);
--        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_api_expt;
--    END;
-- Mod 2016.09.06 Ver1.91 Start
    -- 登録データが存在する、かつ税別内訳出力ありの場合
--    IF ( gn_target_cnt <> 0 ) THEN
    IF ( gn_target_cnt <> 0 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- Mod 2016.09.06 Ver1.91 End
      <<edit_loop>>
      FOR update_work_rec IN update_work_cur LOOP
--
        --初回、又は、顧客コード・担当拠点コードがブレーク
        IF (
             ( lt_bill_cust_code IS NULL )
             OR
             ( lt_bill_cust_code <> update_work_rec.bill_cust_code )
             OR
             ( lt_location_code  <> update_work_rec.location_code )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_cust_cnt                   := 1;                                   --ブレーク毎レコード件数初期化
          ln_int                        := ln_int + 1;                          --配列カウントアップ
          l_bill_cust_code_tab(ln_int)  := update_work_rec.bill_cust_code;      --顧客コード
          l_location_code_tab(ln_int)   := update_work_rec.location_code;       --担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_tab(ln_int)       := update_work_rec.tax_rate;            --消費税率1
          l_category1_tab(ln_int)       := update_work_rec.category;            --内訳分類１
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_tab(ln_int) := update_work_rec.tax_rate_by_sum;     --当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_tab(ln_int)       := NULL;                                --消費税率２
          l_category2_tab(ln_int)       := NULL;                                --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_tab(ln_int) := NULL;                                --当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
          l_category3_tab(ln_int)       := NULL;                                --内訳分類３
          l_inc_tax_charge3_tab(ln_int) := NULL;                                --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code             := update_work_rec.bill_cust_code;      --ブレークコード設定(顧客コード)
          lt_location_code              := update_work_rec.location_code;       --ブレークコード設定(担当拠点コード)
-- Add 2023.07.04 Ver1.95 Start
          l_tax_sum1_tab(ln_int)        := update_work_rec.tax_rate_by_tax_sum; --消費税額１
          l_tax_sum2_tab(ln_int)        := NULL;                                --消費税額２
          l_tax_sum3_tab(ln_int)        := NULL;                                --消費税額３
-- Add 2023.07.04 Ver1.95 End
        ELSE
          --同一顧客・担当拠点で2レコード目以降(3レコード以上は設定しない)
          ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
          --1顧客につき最大２つの税別項目を設定
          IF ( ln_cust_cnt = 2 ) THEN
            --２レコード目
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_tab(ln_int)       := update_work_rec.tax_rate;          --消費税率２
            l_category2_tab(ln_int)       := update_work_rec.category;          --内訳分類２
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_tab(ln_int) := update_work_rec.tax_rate_by_sum;   --当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
-- Add 2023.07.04 Ver1.95 Start
            l_tax_sum2_tab(ln_int)        := update_work_rec.tax_rate_by_tax_sum; --消費税額２
-- Add 2023.07.04 Ver1.95 End
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --３レコード目
            l_category3_tab(ln_int)       := update_work_rec.category;          --内訳分類３
            l_inc_tax_charge3_tab(ln_int) := update_work_rec.tax_rate_by_sum;   --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
-- Add 2023.07.04 Ver1.95 Start
            l_tax_sum3_tab(ln_int)        := update_work_rec.tax_rate_by_tax_sum; --消費税額３
-- Add 2023.07.04 Ver1.95 End
          END IF;
        END IF;
--
      END LOOP edit_loop;
--
      --一括更新
      BEGIN
        <<update_loop>>
        FORALL i IN l_bill_cust_code_tab.FIRST..l_bill_cust_code_tab.LAST
          UPDATE  xxcfr_rep_st_invoice_inc_tax_d  xrsi
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsi.tax_rate1        = l_tax_rate1_tab(i)
--                 ,xrsi.inc_tax_charge1  = l_inc_tax_charge1_tab(i)
--                 ,xrsi.tax_rate2        = l_tax_rate2_tab(i)
--                 ,xrsi.inc_tax_charge2  = l_inc_tax_charge2_tab(i)
          SET     xrsi.category1        = l_category1_tab(i)
                 ,xrsi.inc_tax_charge1  = l_inc_tax_charge1_tab(i)
                 ,xrsi.category2        = l_category2_tab(i)
                 ,xrsi.inc_tax_charge2  = l_inc_tax_charge2_tab(i)
                 ,xrsi.category3        = l_category3_tab(i)
                 ,xrsi.inc_tax_charge3  = l_inc_tax_charge3_tab(i)
-- Modify 2019.09.03 Ver1.93 End
-- Add 2023.07.04 Ver1.95 Start
                 ,xrsi.tax_sum1         = l_tax_sum1_tab(i)         --消費税額１
                 ,xrsi.tax_sum2         = l_tax_sum2_tab(i)         --消費税額２
                 ,xrsi.tax_sum3         = l_tax_sum3_tab(i)         --消費税額３
-- Add 2023.07.04 Ver1.95 End
          WHERE   xrsi.bill_cust_code   = l_bill_cust_code_tab(i)
          AND     xrsi.location_code    = l_location_code_tab(i)
          AND     xrsi.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- 標準請求書税込帳票ワークテーブル
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
-- Mod 2015.07.31 Ver1.80 End
--
-- Add 2023.07.04 Ver1.95 Start
      <<update_1b_loop>>
      FOR update_work_1b_rec IN update_work_1b_cur LOOP
      --ヘッダー用の当月お買上げ額、及び消費税額の一括更新
        BEGIN
          UPDATE  xxcfr_rep_st_invoice_inc_tax_d  xrsi                           -- 標準請求書税込帳票内訳ワークテーブル
          SET     xrsi.ex_tax_charge_header = update_work_1b_rec.slip_sum        -- ヘッダー用当月お買上げ額
                 ,xrsi.tax_sum_header       = update_work_1b_rec.tax_sum         -- ヘッダー用当月消費税額
          WHERE   xrsi.bill_cust_code = update_work_1b_rec.bill_cust_code        -- 顧客コード
          AND     xrsi.location_code  = update_work_1b_rec.location_code         -- 担当拠点コード
          AND     xrsi.request_id     = cn_request_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                           ,cv_msg_003a18_026    -- テーブル更新エラー
                                                           ,cv_tkn_table         -- トークン'TABLE'
                                                           ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                            -- 標準請求書税込帳票内訳ワークテーブル
                                 ,1
                                 ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
      END LOOP update_1b_loop;
-- Add 2023.07.04 Ver1.95 End
--
-- Add 2015.07.31 Ver1.80 Start
    -- 2.税別の消費税額、及び、当月お買上げ額を計算し標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダを更新
-- Mod 2016.09.06 Ver1.91 Start
    -- 明細0件フラグA＝2である、かつ税別内訳出力ありの場合
--    IF ( gv_target_a_flag = cv_taget_flag_2 ) THEN
    IF ( gv_target_a_flag = cv_taget_flag_2 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- Mod 2016.09.06 Ver1.91 End
      -- 変数の初期化
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop2>>
      FOR update_work_2_rec IN update_work_2_cur LOOP
--
        --初回、又は、顧客コード・担当拠点コードがブレーク
        IF (
             ( lt_bill_cust_code2 IS NULL )
             OR
             ( lt_bill_cust_code2 <> update_work_2_rec.bill_cust_code )
             OR
             ( lt_location_code2  <> update_work_2_rec.location_code )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_cust_cnt                      := 1;                                     -- ブレーク毎レコード件数初期化
          ln_int                           := ln_int + 1;                            -- 配列カウントアップ
          l_bill_cust_code_2_tab(ln_int)   := update_work_2_rec.bill_cust_code;      -- 顧客コード
          l_location_code_2_tab(ln_int)    := update_work_2_rec.location_code;       -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_2_tab(ln_int)        := update_work_2_rec.tax_rate;            -- 消費税率(編集用)
          l_category1_2_tab(ln_int)        := update_work_2_rec.category;            -- 内訳分類１
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_2_tab(ln_int)  := update_work_2_rec.tax_rate_by_sum;     -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_2_tab(ln_int)        := NULL;                                  -- 消費税率２
          l_category2_2_tab(ln_int)        := NULL;                                  -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_2_tab(ln_int)  := NULL;                                  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
          l_category3_2_tab(ln_int)        := NULL;                                  -- 内訳分類３
          l_inc_tax_charge3_2_tab(ln_int)  := NULL;                                  -- 当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code2               := update_work_2_rec.bill_cust_code;      -- ブレークコード設定(顧客コード)
          lt_location_code2                := update_work_2_rec.location_code;       -- ブレークコード設定(担当拠点コード)
-- Add 2023.07.04 Ver1.95 Start
          l_tax_sum1_tab(ln_int)           := update_work_2_rec.tax_rate_by_tax_sum; --消費税額１
          l_tax_sum2_tab(ln_int)           := NULL;                                  --消費税額２
          l_tax_sum3_tab(ln_int)           := NULL;                                  --消費税額３
-- Add 2023.07.04 Ver1.95 End
        ELSE
          --同一顧客・担当拠点で2レコード目以降(3レコード以上は設定しない)
-- Modify 2019.09.03 Ver1.93 End
          ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
          --1顧客につき最大２つの税別項目を設定
          IF ( ln_cust_cnt = 2 ) THEN
            --２レコード目
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_2_tab(ln_int)       := update_work_2_rec.tax_rate;            -- 消費税率２
            l_category2_2_tab(ln_int)       := update_work_2_rec.category;            -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_2_tab(ln_int) := update_work_2_rec.tax_rate_by_sum;     -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
-- Add 2023.07.04 Ver1.95 Start
            l_tax_sum2_tab(ln_int)          := update_work_2_rec.tax_rate_by_tax_sum; --消費税額２
-- Add 2023.07.04 Ver1.95 End
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --３レコード目
            l_category3_2_tab(ln_int)       := update_work_2_rec.category;            --内訳分類３
            l_inc_tax_charge3_2_tab(ln_int) := update_work_2_rec.tax_rate_by_sum;     --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
-- Add 2023.07.04 Ver1.95 Start
            l_tax_sum3_tab(ln_int)          := update_work_2_rec.tax_rate_by_tax_sum; --消費税額３
-- Add 2023.07.04 Ver1.95 End
          END IF;
        END IF;
--
      END LOOP edit_loop2;
--
      --一括更新
      BEGIN
        <<update_loop2>>
        FORALL i IN l_bill_cust_code_2_tab.FIRST..l_bill_cust_code_2_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_a_h  xrsiah
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsiah.tax_rate1        = l_tax_rate1_2_tab(i)        -- 消費税率1
--                 ,xrsiah.inc_tax_charge1  = l_inc_tax_charge1_2_tab(i)  -- 当月お買上げ額１
--                 ,xrsiah.tax_rate2        = l_tax_rate2_2_tab(i)        -- 消費税率２
--                 ,xrsiah.inc_tax_charge2  = l_inc_tax_charge2_2_tab(i)  -- 当月お買上げ額２
          SET     xrsiah.category1        = l_category1_2_tab(i)        -- 内訳分類１
                 ,xrsiah.inc_tax_charge1  = l_inc_tax_charge1_2_tab(i)  -- 当月お買上げ額１
                 ,xrsiah.category2        = l_category2_2_tab(i)        -- 内訳分類２
                 ,xrsiah.inc_tax_charge2  = l_inc_tax_charge2_2_tab(i)  -- 当月お買上げ額２
                 ,xrsiah.category3        = l_category3_2_tab(i)        -- 内訳分類３
                 ,xrsiah.inc_tax_charge3  = l_inc_tax_charge3_2_tab(i)  -- 当月お買上げ額３
-- Modify 2019.09.03 Ver1.93 End
-- Add 2023.07.04 Ver1.95 Start
                 ,xrsiah.tax_sum1         = l_tax_sum1_tab(i)           --消費税額１
                 ,xrsiah.tax_sum2         = l_tax_sum2_tab(i)           --消費税額２
                 ,xrsiah.tax_sum3         = l_tax_sum3_tab(i)           --消費税額３
-- Add 2023.07.04 Ver1.95 End
          WHERE   xrsiah.bill_cust_code   = l_bill_cust_code_2_tab(i)
          AND     xrsiah.location_code    = l_location_code_2_tab(i)
          AND     xrsiah.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_a_h))
                                                        -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダー
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
      -- 3.税別の消費税額、及び、当月お買上げ額を計算し標準請求書税込帳票内訳印刷単位Aワークテーブル明細を更新
      -- 変数の初期化
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop3>>
      FOR update_work_3_rec IN update_work_3_cur LOOP
--
        --初回、又は、顧客コード・担当拠点コード・納品先顧客コードがブレーク
        IF (
             ( lt_bill_cust_code3 IS NULL )
             OR
             ( lt_bill_cust_code3 <> update_work_3_rec.bill_cust_code )
             OR
             ( lt_location_code3  <> update_work_3_rec.location_code )
             OR
             ( lt_ship_cust_code3 <> update_work_3_rec.ship_cust_code )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_cust_cnt                     := 1;                                     -- ブレーク毎レコード件数初期化
          ln_int                          := ln_int + 1;                            -- 配列カウントアップ
          l_bill_cust_code_3_tab(ln_int)  := update_work_3_rec.bill_cust_code;      -- 顧客コード
          l_location_code_3_tab(ln_int)   := update_work_3_rec.location_code;       -- 担当拠点コード
          l_ship_cust_code_3_tab(ln_int)  := update_work_3_rec.ship_cust_code;      -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_3_tab(ln_int)       := update_work_3_rec.tax_rate;            -- 消費税率(編集用)
          l_category1_3_tab(ln_int)       := update_work_3_rec.category;            -- 内訳分類１
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_3_tab(ln_int) := update_work_3_rec.tax_rate_by_sum;     -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_3_tab(ln_int)       := NULL;                                  -- 消費税率２
          l_category2_3_tab(ln_int)       := NULL;                                  -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_3_tab(ln_int) := NULL;                                  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
          l_category3_3_tab(ln_int)       := NULL;                                  -- 内訳分類３
          l_inc_tax_charge3_3_tab(ln_int) := NULL;                                  -- 当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code3              := update_work_3_rec.bill_cust_code;      -- ブレークコード設定(顧客コード)
          lt_location_code3               := update_work_3_rec.location_code;       -- ブレークコード設定(担当拠点コード)
          lt_ship_cust_code3              := update_work_3_rec.ship_cust_code;      -- ブレークコード設定(納品先顧客コード)
        ELSE
-- Modify 2019.09.03 Ver1.93 Start
--          --同一顧客・担当拠点・納品先顧客コードで2レコード目以降(2レコード以上は設定しない)
          --同一顧客・担当拠点・納品先顧客コードで2レコード目以降(3レコード以上は設定しない)
-- Modify 2019.09.03 Ver1.93 End
          ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
          --1店舗につき最大２つの税別項目を設定
          IF ( ln_cust_cnt = 2 ) THEN
            --２レコード目
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_3_tab(ln_int)       := update_work_3_rec.tax_rate;            -- 消費税率２
            l_category2_3_tab(ln_int)       := update_work_3_rec.category;            -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_3_tab(ln_int) := update_work_3_rec.tax_rate_by_sum;     -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --３レコード目
            l_category3_3_tab(ln_int)       := update_work_3_rec.category;            --内訳分類３
            l_inc_tax_charge3_3_tab(ln_int) := update_work_3_rec.tax_rate_by_sum;     --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop3;
--
      --一括更新
      BEGIN
        <<update_loop3>>
        FORALL i IN l_bill_cust_code_3_tab.FIRST..l_bill_cust_code_3_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_a_l  xrsial
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsial.tax_rate1        = l_tax_rate1_3_tab(i)        -- 消費税率1
--                 ,xrsial.inc_tax_charge1  = l_inc_tax_charge1_3_tab(i)  -- 当月お買上げ額１
--                 ,xrsial.tax_rate2        = l_tax_rate2_3_tab(i)        -- 消費税率２
--                 ,xrsial.inc_tax_charge2  = l_inc_tax_charge2_3_tab(i)  -- 当月お買上げ額２
          SET      xrsial.category1       = l_category1_3_tab(i)        -- 内訳分類１
                  ,xrsial.inc_tax_charge1 = l_inc_tax_charge1_3_tab(i)  -- 当月お買上げ額１
                  ,xrsial.category2       = l_category2_3_tab(i)        -- 内訳分類２
                  ,xrsial.inc_tax_charge2 = l_inc_tax_charge2_3_tab(i)  -- 当月お買上げ額２
                  ,xrsial.category3       = l_category3_3_tab(i)        -- 内訳分類２
                  ,xrsial.inc_tax_charge3 = l_inc_tax_charge3_3_tab(i)  -- 当月お買上げ額３
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsial.bill_cust_code   = l_bill_cust_code_3_tab(i)
          AND     xrsial.location_code    = l_location_code_3_tab(i)
          AND     xrsial.ship_cust_code   = l_ship_cust_code_3_tab(i)
          AND     xrsial.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                        -- 標準請求書税込帳票内訳印刷単位Aワークテーブル明細
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
-- Add 2016.09.06 Ver1.91 Start
    END IF;
--
    -- -- 明細0件フラグA＝2である場合
    IF ( gv_target_a_flag = cv_taget_flag_2 ) THEN
-- Add 2023.07.04 Ver1.95 Start
      <<update_2b_loop>>
      FOR update_work_2b_rec IN update_work_2b_cur LOOP
      --ヘッダー用の当月お買上げ額、及び消費税額の一括更新
        BEGIN
          UPDATE  xxcfr_rep_st_inv_inc_tax_a_h  xrsiah                           -- 標準請求書税抜帳票内訳印刷単位Aワークテーブルヘッダ
          SET     xrsiah.ex_tax_charge_header = update_work_2b_rec.slip_sum      -- ヘッダー用当月お買上げ額
                 ,xrsiah.tax_sum_header       = update_work_2b_rec.tax_sum       -- ヘッダー用当月消費税額
          WHERE   xrsiah.bill_cust_code = update_work_2b_rec.bill_cust_code      -- 顧客コード
          AND     xrsiah.location_code  = update_work_2b_rec.location_code       -- 担当拠点コード
          AND     xrsiah.request_id     = cn_request_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                           ,cv_msg_003a18_026    -- テーブル更新エラー
                                                           ,cv_tkn_table         -- トークン'TABLE'
                                                           ,xxcfr_common_pkg.get_table_comment(cv_table_a_h))
                                                            -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダ
                                 ,1
                                 ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
      END LOOP update_2b_loop;
--
-- Add 2023.07.04 Ver1.95 End
-- Add 2016.09.06 Ver1.91 End
      -- 4.当月お買上げ額と消費税額を計算し標準請求書税込帳票内訳印刷単位Aワークテーブル明細を更新
      -- 変数の初期化
      ln_int      := 0;
--
      <<edit_loop4>>
      FOR update_work_4_rec IN update_work_4_cur LOOP
        ln_int                          := ln_int + 1;                            -- 配列カウントアップ
        l_bill_cust_code_4_tab(ln_int)  := update_work_4_rec.bill_cust_code;      -- 顧客コード
        l_location_code_4_tab(ln_int)   := update_work_4_rec.location_code;       -- 担当拠点コード
        l_ship_cust_code_4_tab(ln_int)  := update_work_4_rec.ship_cust_code;      -- 納品先顧客コード
        l_store_sum_4_tab(ln_int)       := update_work_4_rec.store_sum;           -- 当月ご請求額（税込）
      END LOOP edit_loop4;
--
      --一括更新
      BEGIN
        <<update_loop4>>
        FORALL i IN l_bill_cust_code_4_tab.FIRST..l_bill_cust_code_4_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_a_l  xrsial
          SET     xrsial.store_sum        = l_store_sum_4_tab(i)        -- 当月ご請求額（税込）
          WHERE   xrsial.bill_cust_code   = l_bill_cust_code_4_tab(i)
          AND     xrsial.location_code    = l_location_code_4_tab(i)
          AND     xrsial.ship_cust_code   = l_ship_cust_code_4_tab(i)
          AND     xrsial.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                        -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダー
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
-- Mod 2016.09.06 Ver1.91 Start
    -- 明細0件フラグB＝2である、かつ税別内訳出力ありの場合
--    IF ( gv_target_b_flag = cv_taget_flag_2 ) THEN
    IF ( gv_target_b_flag = cv_taget_flag_2 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- Mod 2016.09.06 Ver1.91 End
      -- 5.税別の消費税額、及び、当月お買上げ額を計算し標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダを更新
      -- 変数の初期化
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop5>>
      FOR update_work_5_rec IN update_work_5_cur LOOP
--
        --初回、又は、顧客コード・担当拠点コードがブレーク
        IF (
             ( lt_bill_cust_code5 IS NULL )
             OR
             ( lt_bill_cust_code5 <> update_work_5_rec.bill_cust_code )
             OR
             ( lt_location_code5  <> update_work_5_rec.location_code )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_cust_cnt                     := 1;                                     -- ブレーク毎レコード件数初期化
          ln_int                          := ln_int + 1;                            -- 配列カウントアップ
          l_bill_cust_code_5_tab(ln_int)  := update_work_5_rec.bill_cust_code;      -- 顧客コード
          l_location_code_5_tab(ln_int)   := update_work_5_rec.location_code;       -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_5_tab(ln_int)       := update_work_5_rec.tax_rate;            -- 消費税率(編集用)
          l_category1_5_tab(ln_int)       := update_work_5_rec.category;            -- 内訳分類１
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_5_tab(ln_int) := update_work_5_rec.tax_rate_by_sum;     -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_5_tab(ln_int)       := NULL;                                  -- 消費税率２
          l_category2_5_tab(ln_int)       := NULL;                                  -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_5_tab(ln_int) := NULL;                                  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
          l_category3_5_tab(ln_int)       := NULL;                                  -- 内訳分類３
          l_inc_tax_charge3_5_tab(ln_int) := NULL;                                  -- 当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code5              := update_work_5_rec.bill_cust_code;      -- ブレークコード設定(顧客コード)
          lt_location_code5               := update_work_5_rec.location_code;       -- ブレークコード設定(担当拠点コード)
-- Add 2023.07.04 Ver1.95 Start
          l_tax_sum1_tab(ln_int)          := update_work_5_rec.tax_rate_by_tax_sum; --消費税額１
          l_tax_sum2_tab(ln_int)          := NULL;                                  --消費税額２
          l_tax_sum3_tab(ln_int)          := NULL;                                  --消費税額３
-- Add 2023.07.04 Ver1.95 End
        ELSE
          --同一顧客・担当拠点で2レコード目以降(3レコード以上は設定しない)
          ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
          --1顧客につき最大２つの税別項目を設定
          IF ( ln_cust_cnt = 2 ) THEN
            --２レコード目
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_5_tab(ln_int)       := update_work_5_rec.tax_rate;            -- 消費税率２
            l_category2_5_tab(ln_int)       := update_work_5_rec.category;            -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_5_tab(ln_int) := update_work_5_rec.tax_rate_by_sum;     -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
-- Add 2023.07.04 Ver1.95 Start
            l_tax_sum2_tab(ln_int)          := update_work_5_rec.tax_rate_by_tax_sum; --消費税額２
-- Add 2023.07.04 Ver1.95 End
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --３レコード目
            l_category3_5_tab(ln_int)       := update_work_5_rec.category;            --内訳分類３
            l_inc_tax_charge3_5_tab(ln_int) := update_work_5_rec.tax_rate_by_sum;     --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
-- Add 2023.07.04 Ver1.95 Start
            l_tax_sum3_tab(ln_int)          := update_work_5_rec.tax_rate_by_tax_sum; --消費税額３
-- Add 2023.07.04 Ver1.95 End
          END IF;
        END IF;
--
      END LOOP edit_loop5;
--
      --一括更新
      BEGIN
        <<update_loop5>>
        FORALL i IN l_bill_cust_code_5_tab.FIRST..l_bill_cust_code_5_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_b_h  xrsibh
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsibh.tax_rate1        = l_tax_rate1_5_tab(i)        -- 消費税率1
--                 ,xrsibh.inc_tax_charge1  = l_inc_tax_charge1_5_tab(i)  -- 当月お買上げ額１
--                 ,xrsibh.tax_rate2        = l_tax_rate2_5_tab(i)        -- 消費税率２
--                 ,xrsibh.inc_tax_charge2  = l_inc_tax_charge2_5_tab(i)  -- 当月お買上げ額２
          SET     xrsibh.category1        = l_category1_5_tab(i)        -- 内訳分類１
                 ,xrsibh.inc_tax_charge1  = l_inc_tax_charge1_5_tab(i)  -- 当月お買上げ額１
                 ,xrsibh.category2        = l_category2_5_tab(i)        -- 内訳分類２
                 ,xrsibh.inc_tax_charge2  = l_inc_tax_charge2_5_tab(i)  -- 当月お買上げ額２
                 ,xrsibh.category3        = l_category3_5_tab(i)        -- 内訳分類３
                 ,xrsibh.inc_tax_charge3  = l_inc_tax_charge3_5_tab(i)  -- 当月お買上げ額３
-- Modify 2019.09.03 Ver1.93 End
-- Add 2023.07.04 Ver1.95 Start
                 ,xrsibh.tax_sum1         = l_tax_sum1_tab(i)           --消費税額１
                 ,xrsibh.tax_sum2         = l_tax_sum2_tab(i)           --消費税額２
                 ,xrsibh.tax_sum3         = l_tax_sum3_tab(i)           --消費税額３
-- Add 2023.07.04 Ver1.95 End
          WHERE   xrsibh.bill_cust_code   = l_bill_cust_code_5_tab(i)
          AND     xrsibh.location_code    = l_location_code_5_tab(i)
          AND     xrsibh.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_b_h))
                                                        -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダー
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
      -- 6.税別の消費税額、及び、当月お買上げ額を計算し標準請求書税込帳票内訳印刷単位Bワークテーブル明細を更新
      -- 変数の初期化
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop6>>
      FOR update_work_6_rec IN update_work_6_cur LOOP
--
        --初回、又は、顧客コード・担当拠点コード・納品先顧客コードがブレーク
        IF (
             ( lt_bill_cust_code6 IS NULL )
             OR
             ( lt_bill_cust_code6 <> update_work_6_rec.bill_cust_code )
             OR
             ( lt_location_code6  <> update_work_6_rec.location_code )
             OR
             ( lt_ship_cust_code6 <> update_work_6_rec.ship_cust_code )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_cust_cnt                     := 1;                                     -- ブレーク毎レコード件数初期化
          ln_int                          := ln_int + 1;                            -- 配列カウントアップ
          l_bill_cust_code_6_tab(ln_int)  := update_work_6_rec.bill_cust_code;      -- 顧客コード
          l_location_code_6_tab(ln_int)   := update_work_6_rec.location_code;       -- 担当拠点コード
          l_ship_cust_code_6_tab(ln_int)  := update_work_6_rec.ship_cust_code;      -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_6_tab(ln_int)       := update_work_6_rec.tax_rate;            -- 消費税率(編集用)
          l_category1_6_tab(ln_int)       := update_work_6_rec.category;            -- 内訳分類１
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_6_tab(ln_int) := update_work_6_rec.tax_rate_by_sum;     -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_6_tab(ln_int)       := NULL;                                  -- 消費税率２
          l_category2_6_tab(ln_int)       := NULL;                                  -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_6_tab(ln_int) := NULL;                                  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
          l_category3_6_tab(ln_int)       := NULL;                                  -- 内訳分類３
          l_inc_tax_charge3_6_tab(ln_int) := NULL;                                  -- 当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code6              := update_work_6_rec.bill_cust_code;      -- ブレークコード設定(顧客コード)
          lt_location_code6               := update_work_6_rec.location_code;       -- ブレークコード設定(担当拠点コード)
          lt_ship_cust_code6              := update_work_6_rec.ship_cust_code;      -- ブレークコード設定(納品先顧客コード)
        ELSE
          --同一顧客・担当拠点・納品先顧客コードで2レコード目以降(3レコード以上は設定しない)
          ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
          --1店舗につき最大２つの税別項目を設定
          IF ( ln_cust_cnt = 2 ) THEN
            --２レコード目
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_6_tab(ln_int)       := update_work_6_rec.tax_rate;            -- 消費税率２
            l_category2_6_tab(ln_int)       := update_work_6_rec.category;            -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_6_tab(ln_int) := update_work_6_rec.tax_rate_by_sum;     -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --３レコード目
            l_category3_6_tab(ln_int)       := update_work_6_rec.category;            --内訳分類３
            l_inc_tax_charge3_6_tab(ln_int) := update_work_6_rec.tax_rate_by_sum;     --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop6;
--
      --一括更新
      BEGIN
        <<update_loop6>>
        FORALL i IN l_bill_cust_code_6_tab.FIRST..l_bill_cust_code_6_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsibl.tax_rate1        = l_tax_rate1_6_tab(i)        -- 消費税率1
--                 ,xrsibl.inc_tax_charge1  = l_inc_tax_charge1_6_tab(i)  -- 当月お買上げ額１
--                 ,xrsibl.tax_rate2        = l_tax_rate2_6_tab(i)        -- 消費税率２
--                 ,xrsibl.inc_tax_charge2  = l_inc_tax_charge2_6_tab(i)  -- 当月お買上げ額２
          SET     xrsibl.category1        = l_category1_6_tab(i)        -- 内訳分類１
                 ,xrsibl.inc_tax_charge1  = l_inc_tax_charge1_6_tab(i)  -- 当月お買上げ額１
                 ,xrsibl.category2        = l_category2_6_tab(i)        -- 内訳分類２
                 ,xrsibl.inc_tax_charge2  = l_inc_tax_charge2_6_tab(i)  -- 当月お買上げ額２
                 ,xrsibl.category3        = l_category3_6_tab(i)        -- 内訳分類３
                 ,xrsibl.inc_tax_charge3  = l_inc_tax_charge3_6_tab(i)  -- 当月お買上げ額３
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsibl.bill_cust_code   = l_bill_cust_code_6_tab(i)
          AND     xrsibl.location_code    = l_location_code_6_tab(i)
          AND     xrsibl.ship_cust_code   = l_ship_cust_code_6_tab(i)
          AND     xrsibl.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                        -- 標準請求書税込帳票内訳印刷単位Bワークテーブル明細
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
-- Add 2016.09.06 Ver1.91 Start
    END IF;
--
    -- -- 明細0件フラグB＝2である場合
    IF ( gv_target_b_flag = cv_taget_flag_2 ) THEN
-- Add 2023.07.04 Ver1.95 Start
      <<update_5b_loop>>
      FOR update_work_5b_rec IN update_work_5b_cur LOOP
      --ヘッダー用の当月お買上げ額、及び消費税額の一括更新
        BEGIN
          UPDATE  xxcfr_rep_st_inv_inc_tax_b_h  xrsibh                           -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダ
          SET     xrsibh.ex_tax_charge_header = update_work_5b_rec.slip_sum      -- ヘッダー用当月お買上げ額
                 ,xrsibh.tax_sum_header       = update_work_5b_rec.tax_sum       -- ヘッダー用当月消費税額
          WHERE   xrsibh.bill_cust_code = update_work_5b_rec.bill_cust_code      -- 顧客コード
          AND     xrsibh.location_code  = update_work_5b_rec.location_code       -- 担当拠点コード
          AND     xrsibh.request_id     = cn_request_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                           ,cv_msg_003a18_026    -- テーブル更新エラー
                                                           ,cv_tkn_table         -- トークン'TABLE'
                                                           ,xxcfr_common_pkg.get_table_comment(cv_table_b_h))
                                                            -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダ
                                 ,1
                                 ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
      END LOOP update_5b_loop;
--
-- Add 2023.07.04 Ver1.95 End
-- Add 2016.09.06 Ver1.91 End
      -- 7.当月お買上げ額と消費税額を計算し標準請求書税込帳票内訳印刷単位Bワークテーブル明細を更新
      -- 変数の初期化
      ln_int      := 0;
--
      <<edit_loop7>>
      FOR update_work_7_rec IN update_work_7_cur LOOP
        ln_int                          := ln_int + 1;                            -- 配列カウントアップ
        l_bill_cust_code_7_tab(ln_int)  := update_work_7_rec.bill_cust_code;      -- 顧客コード
        l_location_code_7_tab(ln_int)   := update_work_7_rec.location_code;       -- 担当拠点コード
        l_ship_cust_code_7_tab(ln_int)  := update_work_7_rec.ship_cust_code;      -- 納品先顧客コード
        l_store_sum_7_tab(ln_int)       := update_work_7_rec.store_sum;           -- 当月ご請求額（税込）
      END LOOP edit_loop7;
--
      --一括更新
      BEGIN
        <<update_loop7>>
        FORALL i IN l_bill_cust_code_7_tab.FIRST..l_bill_cust_code_7_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_b_l  xrsibl
          SET     xrsibl.store_sum        = l_store_sum_7_tab(i)        -- 当月ご請求額（税込）
          WHERE   xrsibl.bill_cust_code   = l_bill_cust_code_7_tab(i)
          AND     xrsibl.location_code    = l_location_code_7_tab(i)
          AND     xrsibl.ship_cust_code   = l_ship_cust_code_7_tab(i)
          AND     xrsibl.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                        -- 標準請求書税込帳票内訳印刷単位Bワークテーブル明細
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
-- Add 2016.03.31 Ver1.90 Start
    -- 8.税別の消費税額、及び、当月お買上げ額を計算し、
    --   標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダと
    --   標準請求書税込帳票内訳印刷単位Cワークテーブル明細を更新
-- Mod 2016.09.06 Ver1.91 Start
    -- 明細0件フラグC＝2である、かつ税別内訳出力ありの場合
--    IF ( gv_target_c_flag = cv_taget_flag_2 ) THEN
    IF ( gv_target_c_flag = cv_taget_flag_2 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- Mod 2016.09.06 Ver1.91 End
      -- 変数の初期化
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop8>>
      FOR update_work_8_rec IN update_work_8_cur LOOP
--
        --初回、又は、顧客コード・担当拠点コードがブレーク
        IF (
             ( lt_bill_cust_code8 IS NULL )
             OR
             ( lt_bill_cust_code8 <> update_work_8_rec.bill_cust_code )
             OR
             ( lt_location_code8  <> update_work_8_rec.location_code )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_cust_cnt                      := 1;                                     -- ブレーク毎レコード件数初期化
          ln_int                           := ln_int + 1;                            -- 配列カウントアップ
          l_bill_cust_code_8_tab(ln_int)   := update_work_8_rec.bill_cust_code;      -- 顧客コード
          l_location_code_8_tab(ln_int)    := update_work_8_rec.location_code;       -- 担当拠点コード
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_8_tab(ln_int)        := update_work_8_rec.tax_rate;            -- 消費税率(編集用)
          l_category1_8_tab(ln_int)        := update_work_8_rec.category;            -- 内訳分類１
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_8_tab(ln_int)  := update_work_8_rec.tax_rate_by_sum;     -- 当月お買上げ額１
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_8_tab(ln_int)        := NULL;                                  -- 消費税率２
          l_category2_8_tab(ln_int)        :=  NULL;                                 -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_8_tab(ln_int)  := NULL;                                  -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
          l_category3_8_tab(ln_int)        := NULL;                                  -- 内訳分類３
          l_inc_tax_charge3_8_tab(ln_int)  := NULL;                                  -- 当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code8               := update_work_8_rec.bill_cust_code;      -- ブレークコード設定(顧客コード)
          lt_location_code8                := update_work_8_rec.location_code;       -- ブレークコード設定(担当拠点コード)
-- Add 2023.07.04 Ver1.95 Start
          l_tax_sum1_tab(ln_int)           := update_work_8_rec.tax_rate_by_tax_sum; --消費税額１
          l_tax_sum2_tab(ln_int)           := NULL;                                  --消費税額２
          l_tax_sum3_tab(ln_int)           := NULL;                                  --消費税額３
-- Add 2023.07.04 Ver1.95 End
        ELSE
          --同一顧客・担当拠点で2レコード目以降(3レコード以上は設定しない)
          ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
          --1顧客につき最大２つの税別項目を設定
          IF ( ln_cust_cnt = 2 ) THEN
            --２レコード目
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_8_tab(ln_int)       := update_work_8_rec.tax_rate;            -- 消費税率２
            l_category2_8_tab(ln_int)       := update_work_8_rec.category;           -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_8_tab(ln_int) := update_work_8_rec.tax_rate_by_sum;    -- 当月お買上げ額２
-- Add 2019.09.03 Ver1.93 Start
-- Add 2023.07.04 Ver1.95 Start
            l_tax_sum2_tab(ln_int)          := update_work_8_rec.tax_rate_by_tax_sum; --消費税額２
-- Add 2023.07.04 Ver1.95 End
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --３レコード目
            l_category3_8_tab(ln_int)       := update_work_8_rec.category;           --内訳分類３
            l_inc_tax_charge3_8_tab(ln_int) := update_work_8_rec.tax_rate_by_sum;     --当月お買上げ額３
-- Add 2019.09.03 Ver1.93 End
-- Add 2023.07.04 Ver1.95 Start
            l_tax_sum3_tab(ln_int)          := update_work_8_rec.tax_rate_by_tax_sum; --消費税額３
-- Add 2023.07.04 Ver1.95 End
          END IF;
        END IF;
--
      END LOOP edit_loop8;
--
      -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダの一括更新
      BEGIN
        <<update_loop8>>
        FORALL i IN l_bill_cust_code_8_tab.FIRST..l_bill_cust_code_8_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_c_h  xrsich
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsich.tax_rate1        = l_tax_rate1_8_tab(i)        -- 消費税率1
--                 ,xrsich.inc_tax_charge1  = l_inc_tax_charge1_8_tab(i)  -- 当月お買上げ額１
--                 ,xrsich.tax_rate2        = l_tax_rate2_8_tab(i)        -- 消費税率２
--                 ,xrsich.inc_tax_charge2  = l_inc_tax_charge2_8_tab(i)  -- 当月お買上げ額２
          SET     xrsich.category1        = l_category1_8_tab(i)        -- 内訳分類１
                 ,xrsich.inc_tax_charge1  = l_inc_tax_charge1_8_tab(i)  -- 当月お買上げ額１
                 ,xrsich.category2        = l_category2_8_tab(i)        -- 内訳分類２
                 ,xrsich.inc_tax_charge2  = l_inc_tax_charge2_8_tab(i)  -- 当月お買上げ額２
                 ,xrsich.category3        = l_category3_8_tab(i)        -- 内訳分類３
                 ,xrsich.inc_tax_charge3  = l_inc_tax_charge3_8_tab(i)  -- 当月お買上げ額３
-- Modify 2019.09.03 Ver1.93 END
-- Add 2023.07.04 Ver1.95 Start
                 ,xrsich.tax_sum1         = l_tax_sum1_tab(i)           --消費税額１
                 ,xrsich.tax_sum2         = l_tax_sum2_tab(i)           --消費税額２
                 ,xrsich.tax_sum3         = l_tax_sum3_tab(i)           --消費税額３
-- Add 2023.07.04 Ver1.95 End
          WHERE   xrsich.bill_cust_code   = l_bill_cust_code_8_tab(i)
          AND     xrsich.location_code    = l_location_code_8_tab(i)
          AND     xrsich.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_c_h))
                                                        -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
-- Add 2016.03.31 Ver1.90 End
-- Add 2015.07.31 Ver1.80 End
-- Add 2023.07.04 Ver1.95 Start
    IF ( gv_target_c_flag = cv_taget_flag_2 ) THEN
      <<update_8b_loop>>
      FOR update_work_8b_rec IN update_work_8b_cur LOOP
      --ヘッダー用の当月お買上げ額、及び消費税額の一括更新
        BEGIN
          UPDATE  xxcfr_rep_st_inv_inc_tax_c_h  xrsich                           -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ
          SET     xrsich.ex_tax_charge_header = update_work_8b_rec.slip_sum      -- ヘッダー用当月お買上げ額
                 ,xrsich.tax_sum_header       = update_work_8b_rec.tax_sum       -- ヘッダー用当月消費税額
          WHERE   xrsich.bill_cust_code = update_work_8b_rec.bill_cust_code      -- 顧客コード
          AND     xrsich.location_code  = update_work_8b_rec.location_code       -- 担当拠点コード
          AND     xrsich.request_id     = cn_request_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                           ,cv_msg_003a18_026    -- テーブル更新エラー
                                                           ,cv_tkn_table         -- トークン'TABLE'
                                                           ,xxcfr_common_pkg.get_table_comment(cv_table_c_h))
                                                            -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ
                                 ,1
                                 ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
      END LOOP update_8b_loop;
    END IF;
--
-- Add 2023.07.04 Ver1.95 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
    -- 明細0件フラグD＝2である、かつ税別内訳出力ありの場合
    IF ( gv_target_d_flag = cv_taget_flag_2 AND iv_tax_output_type = cv_tax_op_type_yes ) THEN
-- 2023/07/04 Ver1.95 ADD Start
      -- 単位D総括表の税別内訳の更新
      -- 変数の初期化
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop11>>
      FOR update_work_11_rec IN update_work_11_cur LOOP
--
        --初回、又は、請求顧客・担当拠点がブレーク
        IF (
             ( lt_bill_cust_code11 IS NULL )
             OR
             ( lt_bill_cust_code11 <> update_work_11_rec.bill_cust_code )
             OR
             ( lt_location_code11  <> update_work_11_rec.location_code )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_cust_cnt                     := 1;                                     -- ブレーク毎レコード件数初期化
          ln_int                          := ln_int + 1;                            -- 配列カウントアップ
          l_bill_cust_code_11_tab(ln_int) := update_work_11_rec.bill_cust_code;     -- 顧客コード
          l_location_code_11_tab(ln_int)  := update_work_11_rec.location_code;      -- 担当拠点コード
          l_category1_11_tab(ln_int)      := update_work_11_rec.category;           -- 内訳分類１
          l_ex_tax_charge1_11_tab(ln_int) := update_work_11_rec.slip_sum;           -- 当月お買上げ額１
          l_tax_sum1_11_tab(ln_int)       := update_work_11_rec.tax_sum;            -- 消費税額１
          l_category2_11_tab(ln_int)      := NULL;                                  -- 内訳分類２
          l_ex_tax_charge2_11_tab(ln_int) := NULL;                                  -- 当月お買上げ額２
          l_tax_sum2_11_tab(ln_int)       := NULL;                                  -- 消費税額２
          l_category3_11_tab(ln_int)      := NULL;                                  -- 内訳分類３
          l_ex_tax_charge3_11_tab(ln_int) := NULL;                                  -- 当月お買上げ額３
          l_tax_sum3_11_tab(ln_int)       := NULL;                                  -- 消費税額２
          lt_bill_cust_code11             := update_work_11_rec.bill_cust_code;     -- ブレークコード設定(請求顧客)
          lt_location_code11              := update_work_11_rec.location_code;      -- ブレークコード設定(担当拠点)
        ELSE
          --同一請求顧客・担当拠点で２レコード目以降
          ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
          --１店舗につき最大３つの税別項目を設定
          IF ( ln_cust_cnt = 2 ) THEN
            --２レコード目
            l_category2_11_tab(ln_int)       := update_work_11_rec.category;        -- 内訳分類２
            l_ex_tax_charge2_11_tab(ln_int) := update_work_11_rec.slip_sum;         -- 当月お買上げ額２
            l_tax_sum2_11_tab(ln_int)        := update_work_11_rec.tax_sum;         -- 消費税額２
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --３レコード目
            l_category3_11_tab(ln_int)       := update_work_11_rec.category;        --内訳分類３
            l_ex_tax_charge3_11_tab(ln_int) := update_work_11_rec.slip_sum;         --当月お買上げ額３
            l_tax_sum3_11_tab(ln_int)        := update_work_11_rec.tax_sum;         -- 消費税額３
          END IF;
        END IF;
--
      END LOOP edit_loop11;
--
      --一括更新
      BEGIN
        <<update_loop11>>
        FORALL i IN l_bill_cust_code_11_tab.FIRST..l_bill_cust_code_11_tab.LAST
          UPDATE  xxcfr_rep_st_inv_d_h  xrsidh
          SET     xrsidh.category1        = l_category1_11_tab(i)                   -- 内訳分類１
                 ,xrsidh.ex_tax_charge1  = l_ex_tax_charge1_11_tab(i)               -- 当月お買上げ額１
                 ,xrsidh.tax_sum1         = l_tax_sum1_11_tab(i)                    -- 消費税額１
                 ,xrsidh.category2        = l_category2_11_tab(i)                   -- 内訳分類２
                 ,xrsidh.ex_tax_charge2  = l_ex_tax_charge2_11_tab(i)               -- 当月お買上げ額２
                 ,xrsidh.tax_sum2         = l_tax_sum2_11_tab(i)                    -- 消費税額２
                 ,xrsidh.category3        = l_category3_11_tab(i)                   -- 内訳分類３
                 ,xrsidh.ex_tax_charge3  = l_ex_tax_charge3_11_tab(i)               -- 当月お買上げ額３
                 ,xrsidh.tax_sum3         = l_tax_sum3_11_tab(i)                    -- 消費税額３
          WHERE   xrsidh.bill_cust_code   = l_bill_cust_code_11_tab(i)
          AND     xrsidh.location_code    = l_location_code_11_tab(i)
          AND     xrsidh.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_d_h))
                                                        -- 標準請求書税込帳票内訳印刷単位Dワークテーブルヘッダ
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
-- 2023/07/04 Ver1.95 ADD End
      -- 9.税別の消費税額、及び、当月お買上げ額を計算し標準請求書税込帳票内訳印刷単位Dワークテーブル明細を更新
      -- 変数の初期化
      ln_cust_cnt := 0;
      ln_int      := 0;
--
      <<edit_loop9>>
      FOR update_work_9_rec IN update_work_9_cur LOOP
--
        --初回、又は、顧客コード・担当拠点コード・納品先顧客コードがブレーク
        IF (
             ( lt_bill_cust_code9 IS NULL )
             OR
             ( lt_bill_cust_code9 <> update_work_9_rec.bill_cust_code )
             OR
             ( lt_location_code9  <> update_work_9_rec.location_code )
             OR
             ( lt_ship_cust_code9 <> update_work_9_rec.ship_cust_code )
           )
        THEN
          --初期化、及び、１レコード目の税別項目設定
          ln_cust_cnt                     := 1;                                     -- ブレーク毎レコード件数初期化
          ln_int                          := ln_int + 1;                            -- 配列カウントアップ
          l_bill_cust_code_9_tab(ln_int)  := update_work_9_rec.bill_cust_code;      -- 顧客コード
          l_location_code_9_tab(ln_int)   := update_work_9_rec.location_code;       -- 担当拠点コード
          l_ship_cust_code_9_tab(ln_int)  := update_work_9_rec.ship_cust_code;      -- 納品先顧客コード
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate1_9_tab(ln_int)       := update_work_9_rec.tax_rate;            -- 消費税率(編集用)
          l_category1_9_tab(ln_int)       := update_work_9_rec.category;            -- 内訳分類１
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge1_9_tab(ln_int) := update_work_9_rec.tax_rate_by_sum;     -- 当月お買上げ額１
-- 2023/07/04 Ver1.95 ADD Start
          l_tax_sum1_9_tab(ln_int)        := update_work_9_rec.tax_rate_by_tax_sum; -- 消費税額１
-- 2023/07/04 Ver1.95 ADD End
-- Modify 2019.09.03 Ver1.93 Start
--          l_tax_rate2_9_tab(ln_int)       := NULL;                                  -- 消費税率２
          l_category2_9_tab(ln_int)       := NULL;                                  -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
          l_inc_tax_charge2_9_tab(ln_int) := NULL;                                  -- 当月お買上げ額２
-- 2023/07/04 Ver1.95 ADD Start
          l_tax_sum2_9_tab(ln_int)        := NULL;                                  -- 消費税額２
-- 2023/07/04 Ver1.95 ADD End
-- Add 2019.09.03 Ver1.93 Start
          l_category3_9_tab(ln_int)       := NULL;                                  -- 内訳分類３
          l_inc_tax_charge3_9_tab(ln_int) := NULL;                                  -- 当月お買上げ額３
-- 2023/07/04 Ver1.95 ADD Start
          l_tax_sum3_9_tab(ln_int)        := NULL;                                  -- 消費税額２
-- 2023/07/04 Ver1.95 ADD End
-- Add 2019.09.03 Ver1.93 End
          lt_bill_cust_code9              := update_work_9_rec.bill_cust_code;      -- ブレークコード設定(顧客コード)
          lt_location_code9               := update_work_9_rec.location_code;       -- ブレークコード設定(担当拠点コード)
          lt_ship_cust_code9              := update_work_9_rec.ship_cust_code;      -- ブレークコード設定(納品先顧客コード)
        ELSE
-- Modify 2019.09.03 Ver1.93 Start
--          --同一顧客・担当拠点・納品先顧客コードで2レコード目以降(2レコード以上は設定しない)
          --同一顧客・担当拠点・納品先顧客コードで2レコード目以降(3レコード以上は設定しない)
-- Modify 2019.09.03 Ver1.93 End
          ln_cust_cnt := ln_cust_cnt + 1;  --ブレーク毎件数カウントアップ
          --1店舗につき最大２つの税別項目を設定
          IF ( ln_cust_cnt = 2 ) THEN
            --２レコード目
-- Modify 2019.09.03 Ver1.93 Start
--            l_tax_rate2_9_tab(ln_int)       := update_work_9_rec.tax_rate;            -- 消費税率２
            l_category2_9_tab(ln_int)       := update_work_9_rec.category;            -- 内訳分類２
-- Modify 2019.09.03 Ver1.93 End
            l_inc_tax_charge2_9_tab(ln_int) := update_work_9_rec.tax_rate_by_sum;     -- 当月お買上げ額２
-- 2023/07/04 Ver1.95 ADD Start
            l_tax_sum2_9_tab(ln_int)       := update_work_9_rec.tax_rate_by_tax_sum; -- 消費税額２
-- 2023/07/04 Ver1.95 ADD End
-- Add 2019.09.03 Ver1.93 Start
          ELSIF ( ln_cust_cnt = 3 ) THEN
            --３レコード目
            l_category3_9_tab(ln_int)       := update_work_9_rec.category;            --内訳分類３
            l_inc_tax_charge3_9_tab(ln_int) := update_work_9_rec.tax_rate_by_sum;     --当月お買上げ額３
-- 2023/07/04 Ver1.95 ADD Start
            l_tax_sum3_9_tab(ln_int)       := update_work_9_rec.tax_rate_by_tax_sum; -- 消費税額３
-- 2023/07/04 Ver1.95 ADD End
-- Add 2019.09.03 Ver1.93 End
          END IF;
        END IF;
--
      END LOOP edit_loop9;
--
      --一括更新
      BEGIN
        <<update_loop9>>
        FORALL i IN l_bill_cust_code_9_tab.FIRST..l_bill_cust_code_9_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
-- Modify 2019.09.03 Ver1.93 Start
--          SET     xrsidl.tax_rate1        = l_tax_rate1_9_tab(i)        -- 消費税率1
--                 ,xrsidl.inc_tax_charge1  = l_inc_tax_charge1_9_tab(i)  -- 当月お買上げ額１
--                 ,xrsidl.tax_rate2        = l_tax_rate2_9_tab(i)        -- 消費税率２
--                 ,xrsidl.inc_tax_charge2  = l_inc_tax_charge2_9_tab(i)  -- 当月お買上げ額２
          SET     xrsidl.category1        = l_category1_9_tab(i)        -- 内訳分類１
                 ,xrsidl.inc_tax_charge1  = l_inc_tax_charge1_9_tab(i)  -- 当月お買上げ額１
-- 2023/07/04 Ver1.95 ADD Start
                 ,xrsidl.tax_sum1         = l_tax_sum1_9_tab(i)         -- 消費税額１
-- 2023/07/04 Ver1.95 ADD End
                 ,xrsidl.category2        = l_category2_9_tab(i)        -- 内訳分類２
                 ,xrsidl.inc_tax_charge2  = l_inc_tax_charge2_9_tab(i)  -- 当月お買上げ額２
-- 2023/07/04 Ver1.95 ADD Start
                 ,xrsidl.tax_sum2         = l_tax_sum2_9_tab(i)         -- 消費税額２
-- 2023/07/04 Ver1.95 ADD End
                 ,xrsidl.category3        = l_category3_9_tab(i)        -- 内訳分類３
                 ,xrsidl.inc_tax_charge3  = l_inc_tax_charge3_9_tab(i)  -- 当月お買上げ額３
-- 2023/07/04 Ver1.95 ADD Start
                 ,xrsidl.tax_sum3         = l_tax_sum3_9_tab(i)         -- 消費税額３
-- 2023/07/04 Ver1.95 ADD End
-- Modify 2019.09.03 Ver1.93 End
          WHERE   xrsidl.bill_cust_code   = l_bill_cust_code_9_tab(i)
          AND     xrsidl.location_code    = l_location_code_9_tab(i)
          AND     xrsidl.ship_cust_code   = l_ship_cust_code_9_tab(i)
          AND     xrsidl.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                        -- 標準請求書税込帳票内訳印刷単位Dワークテーブル明細
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
    -- -- 明細0件フラグD＝2である場合
    IF ( gv_target_d_flag = cv_taget_flag_2 ) THEN
-- 2023/07/04 Ver1.95 ADD Start
      <<update_12_loop>>
      FOR update_work_12_rec IN update_work_12_cur LOOP
      --ヘッダー用の当月お買上げ額、及び消費税額の更新
        BEGIN
          UPDATE  xxcfr_rep_st_inv_d_h  xrsidh                                   -- 標準請求書帳票内訳印刷単位Dワークテーブルヘッダ
          SET     xrsidh.ex_tax_charge_header = update_work_12_rec.slip_sum      -- ヘッダー用当月お買上げ額
                 ,xrsidh.tax_sum_header       = update_work_12_rec.tax_sum       -- ヘッダー用当月消費税額
          WHERE   xrsidh.bill_cust_code = update_work_12_rec.bill_cust_code      -- 顧客コード
          AND     xrsidh.location_code  = update_work_12_rec.location_code       -- 担当拠点コード
          AND     xrsidh.request_id     = cn_request_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                           ,cv_msg_003a18_026    -- テーブル更新エラー
                                                           ,cv_tkn_table         -- トークン'TABLE'
                                                           ,xxcfr_common_pkg.get_table_comment(cv_table_d_h))
                                                            -- 標準請求書税込帳票内訳印刷単位Dワークテーブルヘッダ
                                 ,1
                                 ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
      END LOOP update_12_loop;
-- 2023/07/04 Ver1.95 ADD End
      -- 10.当月お買上げ額と消費税額を計算し標準請求書税込帳票内訳印刷単位Dワークテーブル明細を更新
      -- 変数の初期化
      ln_int      := 0;
--
      <<edit_loop10>>
      FOR update_work_10_rec IN update_work_10_cur LOOP
        ln_int                          := ln_int + 1;                            -- 配列カウントアップ
        l_bill_cust_code_10_tab(ln_int)  := update_work_10_rec.bill_cust_code;    -- 顧客コード
        l_location_code_10_tab(ln_int)   := update_work_10_rec.location_code;     -- 担当拠点コード
        l_ship_cust_code_10_tab(ln_int)  := update_work_10_rec.ship_cust_code;    -- 納品先顧客コード
        l_store_sum_10_tab(ln_int)       := update_work_10_rec.store_sum;         -- 当月ご請求額（税込）
-- 2023/07/04 Ver1.95 ADD Start
        l_store_tax_sum_10_tab(ln_int)   := update_work_10_rec.store_tax_sum;       -- 消費税等
-- 2023/07/04 Ver1.95 ADD End
      END LOOP edit_loop10;
--
      --一括更新
      BEGIN
        <<update_loop10>>
        FORALL i IN l_bill_cust_code_10_tab.FIRST..l_bill_cust_code_10_tab.LAST
          UPDATE  xxcfr_rep_st_inv_inc_tax_d_l  xrsidl
          SET     xrsidl.store_sum        = l_store_sum_10_tab(i)        -- 当月ご請求額（税込）
-- 2023/07/04 Ver1.95 ADD Start
                 ,xrsidl.store_tax_sum    = l_store_tax_sum_10_tab(i)    -- 消費税等
-- 2023/07/04 Ver1.95 ADD End
          WHERE   xrsidl.bill_cust_code   = l_bill_cust_code_10_tab(i)
          AND     xrsidl.location_code    = l_location_code_10_tab(i)
          AND     xrsidl.ship_cust_code   = l_ship_cust_code_10_tab(i)
          AND     xrsidl.request_id       = cn_request_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                         ,cv_msg_003a18_026    -- テーブル更新エラー
                                                         ,cv_tkn_table         -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                        -- 標準請求書税込帳票内訳印刷単位Dワークテーブル明細
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
-- Ver.1.92 [障害E_本稼動_15307] ADD END
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
  END update_work_table;
--
-- Add 2013.12.13 Ver1.60 End
  /********************************************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : 対象顧客取得処理(A-4)、売掛管理先顧客取得処理(A-5)、ワークテーブルデータ登録(A-6))
   ********************************************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- 締日
    iv_customer_code14      IN   VARCHAR2,         -- 売掛管理先顧客
    iv_customer_code21      IN   VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code20      IN   VARCHAR2,         -- 請求書用顧客
    iv_customer_code10      IN   VARCHAR2,         -- 顧客
-- Add 2010.12.10 Ver1.30 Start
    iv_bill_pub_cycle       IN   VARCHAR2,         -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
    iv_tax_output_type      IN   VARCHAR2,         -- 税別内訳出力区分
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
    iv_bill_invoice_type    IN   VARCHAR2,         -- 請求書出力形式
-- Add 2014.03.27 Ver1.70 End
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- プログラム名
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
    -- 消費税区分
    cv_syohizei_kbn_inc2 CONSTANT VARCHAR2(1) := '2';                      -- 内税(伝票)
    cv_syohizei_kbn_inc3 CONSTANT VARCHAR2(1) := '3';                      -- 内税(単価)
    -- 請求書出力区分
    cv_inv_prt_type     CONSTANT VARCHAR2(1)  := '1';                       -- 1.伊藤園標準
-- Add 2013.12.13 Ver1.60 Start
-- Del 2016.09.06 Ver1.91 Start
--    cv_tax_op_type_yes  CONSTANT VARCHAR2(1)  := '2';                       -- 2.税別内訳出力あり
-- Del 2016.09.06 Ver1.91 End
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
    -- 業者委託フラグ
    cv_os_flag_y        CONSTANT VARCHAR2(1)  := 'Y';                      -- Y.業者委託
    -- 請求書出力形式
    cv_bill_invoice_type_os  CONSTANT VARCHAR2(1) := '4';                  -- 4.業者委託
-- Add 2014.03.27 Ver1.70 End
-- Add 2019.09.03 Ver1.93 Start
    -- 参照タイプ
    cv_xxcfr_tax_category    CONSTANT VARCHAR2(20) := 'XXCFR1_TAX_CATEGORY';     -- 税分類
-- Add 2019.09.03 Ver1.93 End
--
    -- *** ローカル変数 ***
    -- 書式整形用変数
    lv_format_date_jpymd4  VARCHAR2(25); -- YYYY"年"MM"月"DD"日"
    lv_format_date_jpymd2  VARCHAR2(25); -- YY"年"MM"月"DD"日"
    lv_format_date_year    VARCHAR2(10); -- 年
    lv_format_date_month   VARCHAR2(10); -- 月
    lv_format_date_bank    VARCHAR2(10); -- 銀行
    lv_format_date_central VARCHAR2(10); -- 本店
    lv_format_date_branch  VARCHAR2(10); -- 支店
    lv_format_date_account VARCHAR2(10); -- 普通
    lv_format_date_current VARCHAR2(10); -- 当座
    lv_format_zip_mark     VARCHAR2(10); -- 〒
    lv_format_bank_dummy   VARCHAR2(10); -- D%
--
    ln_target_cnt   NUMBER := 0;    -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    lv_no_data_msg  VARCHAR2(5000); -- 帳票０件メッセージ
    lv_func_status  VARCHAR2(1);    -- SVF帳票共通関数(0件出力メッセージ)終了ステータス
--
    -- *** ローカル・カーソル ***
    -- 顧客取得カーソルタイプ
    TYPE cursor_rec_type IS RECORD(customer_id           xxcmm_cust_accounts.customer_id%TYPE,           -- 顧客区分10顧客ID
                                   customer_code         xxcmm_cust_accounts.customer_code%TYPE,         -- 顧客区分10顧客コード
                                   invoice_printing_unit xxcmm_cust_accounts.invoice_printing_unit%TYPE, -- 顧客区分10請求書印刷単位
-- Add 2011.01.17 Ver1.40 Start
                                   store_code            xxcmm_cust_accounts.store_code%TYPE,            -- 顧客区分10店舗コード
-- Add 2011.01.17 Ver1.40 End
                                   bill_base_code        xxcmm_cust_accounts.bill_base_code%TYPE);       -- 顧客区分10請求拠点コード
    TYPE cursor_ref_type IS REF CURSOR;
    get_all_account_cur cursor_ref_type;
    all_account_rec cursor_rec_type;
--
    -- 顧客10取得カーソル文字列
    cv_get_all_account_cur   CONSTANT VARCHAR2(3000) := 
-- Ver1.96 MOD START
--    'SELECT xxca.customer_id           AS customer_id, '||            -- 顧客ID
    'SELECT /*+ LEADING(xxca) INDEX(XXCMM_CUST_ACCOUNTS_N24) */ '||
    '       xxca.customer_id           AS customer_id, '||            -- 顧客ID
-- Ver1.96 MOD END
    '       xxca.customer_code         AS customer_code, '||          -- 顧客コード
    '        xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.40 Start
    '       xxca.store_code             AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.40 End
    '        xxca.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    ' FROM xxcmm_cust_accounts xxca, '||                                     -- 顧客追加情報
    '      hz_cust_accounts    hzca '||                                      -- 顧客マスタ
    ' WHERE xxca.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a1||''','||
                                          ''''||cv_invoice_printing_unit_a2||''','||
                                          ''''||cv_invoice_printing_unit_a3||''','||
                                          ''''||cv_invoice_printing_unit_a4||''','||
                                          ''''||cv_invoice_printing_unit_a5||''','||
-- Mod 2015.07.31 Ver1.80 Start
--                                          ''''||cv_invoice_printing_unit_a6||''') '|| -- 請求書印刷単位
                                          ''''||cv_invoice_printing_unit_a6||''','||
                                          ''''||cv_invoice_printing_unit_a7||''','||
-- Mod 2016.03.31 Ver1.90 Start
--                                          ''''||cv_invoice_printing_unit_a8||''') '|| -- 請求書印刷単位
                                          ''''||cv_invoice_printing_unit_a8||''','||
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--                                          ''''||cv_invoice_printing_unit_a9||''') '|| -- 請求書印刷単位
                                          ''''||cv_invoice_printing_unit_a9||''','||
                                          ''''||cv_invoice_printing_unit_a10||''') '|| -- 請求書印刷単位
-- Ver.1.92 [障害E_本稼動_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
    ' AND   hzca.customer_class_code = '''||cv_customer_class_code10||''' '||         -- 顧客区分:10
-- Ver1.96 MOD START
--    ' AND   xxca.customer_id = hzca.cust_account_id ';
    ' AND   xxca.customer_id = hzca.cust_account_id ' ||
    'AND   ( '                                                                                  ||
    '        ''' || gv_comp_spin_off_flag || ''' = ''N'' '                                      ||
    '        OR '                                                                               ||
    '        (  '                                                                               ||
    '          ''' || gv_comp_spin_off_flag || ''' = ''Y'' '                                    ||
    '          AND '                                                                            ||
    '          EXISTS ( '                                                                       ||
    '            SELECT 1 '                                                                     ||
    '            FROM   xxcfr_bd_dept_comp_info_v  xbdciv '                                     ||
    '            WHERE  xbdciv.dept_code        = xxca.bill_base_code '                         ||
    '            AND    xbdciv.set_of_books_id  = ' || gn_set_of_bks_id                         ||
    '            AND    TO_DATE( :gv_target_date,''YYYYMMDD'') '                                ||
    '                   BETWEEN xbdciv.comp_start_date '                                        ||
    '                   AND     NVL(xbdciv.comp_end_date, TO_DATE(''99991231'',''YYYYMMDD'')) ' ||
    '            AND    xbdciv.company_code_bd  = ''' || gv_drafting_company || ''' '           ||
    '          ) '                                                                              ||
    '        ) '                                                                                ||
    '      ) ';
-- Ver1.96 MOD END
--
    -- 顧客10取得カーソル文字列(売掛管理先顧客指定時)
    cv_get_14account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     hz_cust_accounts    hzca10, '||                                     -- 顧客10顧客マスタ
    '     hz_cust_acct_sites  hasa10, '||                                     -- 顧客10顧客所在地
    '     hz_cust_site_uses   hsua10, '||                                     -- 顧客10顧客使用目的
    '     hz_cust_accounts    hzca14, '||                                     -- 顧客14顧客マスタ
    '     hz_cust_acct_relate hcar14, '||                                     -- 顧客関連マスタ
    '     hz_cust_acct_sites  hasa14, '||                                     -- 顧客14顧客所在地
    '     hz_cust_site_uses   hsua14 '||                                      -- 顧客14顧客使用目的
-- Mod 2015.07.31 Ver1.80 Start
--    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a1||''' '||    -- 請求書印刷単位
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a1||''','||
                                           ''''||cv_invoice_printing_unit_a7||''','||
-- Mod 2016.03.31 Ver1.90 Start
--                                           ''''||cv_invoice_printing_unit_a8||''')'||
                                           ''''||cv_invoice_printing_unit_a8||''','||
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--                                           ''''||cv_invoice_printing_unit_a9||''')'||
                                           ''''||cv_invoice_printing_unit_a9||''','||
                                           ''''||cv_invoice_printing_unit_a10||''')'||
-- Ver.1.92 [障害E_本稼動_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||         -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   hzca14.account_number = :iv_customer_code14 '||
    'AND   hzca14.cust_account_id = hcar14.cust_account_id '||
    'AND   hcar14.related_cust_account_id = hzca10.cust_account_id '||
    'AND   hzca14.customer_class_code = '''||cv_customer_class_code14||''' '||
    'AND   hcar14.status = '''||cv_acct_relate_status||''' '||
    'AND   hcar14.attribute1 = '''||cv_acct_relate_type_bill||''' '||
    'AND   hzca14.cust_account_id = hasa14.cust_account_id '||
    'AND   hasa14.cust_acct_site_id = hsua14.cust_acct_site_id '||
    'AND   hsua14.site_use_code = '''||cv_site_use_code_bill_to||''' '||
-- Add 2010-02-03 Ver1.20 Start
    'AND   hsua14.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010-02-03 Ver1.20 End
    'AND   hzca10.cust_account_id = hasa10.cust_account_id '||
    'AND   hasa10.cust_acct_site_id = hsua10.cust_acct_site_id '||
-- Add 2010-02-03 Ver1.20 Start
    'AND   hsua10.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010-02-03 Ver1.20 End
-- Ver1.96 MOD START
--    'AND   hsua10.bill_to_site_use_id = hsua14.site_use_id ';
    'AND   hsua10.bill_to_site_use_id = hsua14.site_use_id ' ||
    'AND   ( '                                                                                  ||
    '        ''' || gv_comp_spin_off_flag || ''' = ''N'' '                                      ||
    '        OR '                                                                               ||
    '        (  '                                                                               ||
    '          ''' || gv_comp_spin_off_flag || ''' = ''Y'' '                                    ||
    '          AND '                                                                            ||
    '          EXISTS ( '                                                                       ||
    '            SELECT 1 '                                                                     ||
    '            FROM   xxcfr_bd_dept_comp_info_v  xbdciv '                                     ||
    '            WHERE  xbdciv.dept_code        = xxca10.bill_base_code '                       ||
    '            AND    xbdciv.set_of_books_id  = ' || gn_set_of_bks_id                         ||
    '            AND    TO_DATE( :gv_target_date,''YYYYMMDD'') '                                ||
    '                   BETWEEN xbdciv.comp_start_date '                                        ||
    '                   AND     NVL(xbdciv.comp_end_date, TO_DATE(''99991231'',''YYYYMMDD'')) ' ||
    '            AND    xbdciv.company_code_bd  = ''' || gv_drafting_company || ''' '           ||
    '          ) '                                                                              ||
    '        ) '                                                                                ||
    '      ) ';
-- Ver1.96 MOD END
--
    -- 顧客10取得カーソル文字列(統括請求書用顧客指定時)
    cv_get_21account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     xxcmm_cust_accounts xxca20, '||                                     -- 顧客20顧客追加情報
    '     xxcmm_cust_accounts xxca21, '||                                     -- 顧客21顧客追加情報
    '     hz_cust_accounts    hzca10 '||                                      -- 顧客10顧客マスタ
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a2||''' '||     -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||          -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.enclose_invoice_code = xxca21.customer_code '||
-- Ver1.96 MOD START
--    'AND   xxca21.customer_code = :iv_customer_code21 ';
    'AND   xxca21.customer_code = :iv_customer_code21 ' ||
    'AND   ( '                                                                                  ||
    '        ''' || gv_comp_spin_off_flag || ''' = ''N'' '                                      ||
    '        OR '                                                                               ||
    '        (  '                                                                               ||
    '          ''' || gv_comp_spin_off_flag || ''' = ''Y'' '                                    ||
    '          AND '                                                                            ||
    '          EXISTS ( '                                                                       ||
    '            SELECT 1 '                                                                     ||
    '            FROM   xxcfr_bd_dept_comp_info_v  xbdciv '                                     ||
    '            WHERE  xbdciv.dept_code        = xxca10.bill_base_code '                       ||
    '            AND    xbdciv.set_of_books_id  = ' || gn_set_of_bks_id                         ||
    '            AND    TO_DATE( :gv_target_date,''YYYYMMDD'') '                                ||
    '                   BETWEEN xbdciv.comp_start_date '                                        ||
    '                   AND     NVL(xbdciv.comp_end_date, TO_DATE(''99991231'',''YYYYMMDD'')) ' ||
    '            AND    xbdciv.company_code_bd  = ''' || gv_drafting_company || ''' '           ||
    '          ) '                                                                              ||
    '        ) '                                                                                ||
    '      ) ';
-- Ver1.96 MOD END
--
    -- 顧客10取得カーソル文字列(請求書用顧客指定時)
    cv_get_20account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     xxcmm_cust_accounts xxca20, '||                                     -- 顧客20顧客追加情報
    '     hz_cust_accounts    hzca10 '||                                      -- 顧客10顧客マスタ
-- Modify 2009-11-11 Ver1.10 Start
--    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a3||''','||
--                                           ''''||cv_invoice_printing_unit_a4||''') '||   -- 請求書印刷単位
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a3||''' '||      -- 請求書印刷単位
-- Modify 2009-11-11 Ver1.10 End
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||           -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.customer_code = :iv_customer_code20 '||
-- Ver1.96 ADD START
    'AND   ( '                                                                                  ||
    '        ''' || gv_comp_spin_off_flag || ''' = ''N'' '                                      ||
    '        OR '                                                                               ||
    '        (  '                                                                               ||
    '          ''' || gv_comp_spin_off_flag || ''' = ''Y'' '                                    ||
    '          AND '                                                                            ||
    '          EXISTS ( '                                                                       ||
    '            SELECT 1 '                                                                     ||
    '            FROM   xxcfr_bd_dept_comp_info_v  xbdciv '                                     ||
    '            WHERE  xbdciv.dept_code        = xxca10.bill_base_code '                       ||
    '            AND    xbdciv.set_of_books_id  = ' || gn_set_of_bks_id                         ||
    '            AND    TO_DATE( :gv_target_date,''YYYYMMDD'') '                                ||
    '                   BETWEEN xbdciv.comp_start_date '                                        ||
    '                   AND     NVL(xbdciv.comp_end_date, TO_DATE(''99991231'',''YYYYMMDD'')) ' ||
    '            AND    xbdciv.company_code_bd  = ''' || gv_drafting_company || ''' '           ||
    '          ) '                                                                              ||
    '        ) '                                                                                ||
    '      ) '                                                                                  ||
-- Ver1.96 ADD END
-- Modify 2009-11-11 Ver1.10 Start
    'UNION ALL '||
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     xxcmm_cust_accounts xxca20, '||                                     -- 顧客20顧客追加情報
    '     xxcmm_cust_accounts xxca21, '||                                     -- 顧客21顧客追加情報
    '     hz_cust_accounts    hzca10 '||                                      -- 顧客10顧客マスタ
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a4||''' '||     -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||          -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.enclose_invoice_code = xxca21.customer_code '||
    'AND EXISTS (SELECT ''X'' '||
    '            FROM xxcmm_cust_accounts xxca20_sub '||
    '            WHERE xxca20_sub.customer_code = :iv_customer_code20 '||
-- Ver1.96 MOD START
--    '            AND   xxca20_sub.enclose_invoice_code = xxca21.customer_code) ';
    '            AND   xxca20_sub.enclose_invoice_code = xxca21.customer_code) ' ||
    'AND   ( '                                                                                  ||
    '        ''' || gv_comp_spin_off_flag || ''' = ''N'' '                                      ||
    '        OR '                                                                               ||
    '        (  '                                                                               ||
    '          ''' || gv_comp_spin_off_flag || ''' = ''Y'' '                                    ||
    '          AND '                                                                            ||
    '          EXISTS ( '                                                                       ||
    '            SELECT 1 '                                                                     ||
    '            FROM   xxcfr_bd_dept_comp_info_v  xbdciv '                                     ||
    '            WHERE  xbdciv.dept_code        = xxca10.bill_base_code '                       ||
    '            AND    xbdciv.set_of_books_id  = ' || gn_set_of_bks_id                         ||
    '            AND    TO_DATE( :gv_target_date,''YYYYMMDD'') '                                ||
    '                   BETWEEN xbdciv.comp_start_date '                                        ||
    '                   AND     NVL(xbdciv.comp_end_date, TO_DATE(''99991231'',''YYYYMMDD'')) ' ||
    '            AND    xbdciv.company_code_bd  = ''' || gv_drafting_company || ''' '           ||
    '          ) '                                                                              ||
    '        ) '                                                                                ||
    '      ) ';
-- Ver1.96 MOD END
-- Modify 2009-11-11 Ver1.10 End
--
    -- 顧客10取得カーソル文字列(顧客指定時)
-- Modify 2009-11-11 Ver1.10 Start
    cv_get_10account_cur   CONSTANT VARCHAR2(5000) := 
--    'SELECT xxca.customer_id           AS customer_id, '||           -- 顧客ID
--    '       xxca.customer_code         AS customer_code, '||         -- 顧客コード
--    '       xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
--    '       xxca.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
--    'FROM xxcmm_cust_accounts xxca, '||                                     -- 顧客追加情報
--    '     hz_cust_accounts    hzca '||                                      -- 顧客マスタ
--    'WHERE xxca.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a5||''','||
--                                         ''''||cv_invoice_printing_unit_a6||''') '||    -- 請求書印刷単位
--    'AND   hzca.customer_class_code = '''||cv_customer_class_code10||''' '||            -- 顧客区分:10
--    'AND   xxca.customer_id = hzca.cust_account_id '||
--    'AND   xxca.customer_code = :iv_customer_code10 ';
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     hz_cust_accounts    hzca10, '||                                     -- 顧客10顧客マスタ
    '     hz_cust_acct_sites  hasa10, '||                                     -- 顧客10顧客所在地
    '     hz_cust_site_uses   hsua10, '||                                     -- 顧客10顧客使用目的
    '     hz_cust_accounts    hzca14, '||                                     -- 顧客14顧客マスタ
    '     hz_cust_acct_relate hcar14, '||                                     -- 顧客関連マスタ
    '     hz_cust_acct_sites  hasa14, '||                                     -- 顧客14顧客所在地
    '     hz_cust_site_uses   hsua14 '||                                      -- 顧客14顧客使用目的
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a5||''' '||    -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||         -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   hzca14.cust_account_id = hcar14.cust_account_id '||
    'AND   hcar14.related_cust_account_id = hzca10.cust_account_id '||
    'AND   hzca14.customer_class_code = '''||cv_customer_class_code14||''' '||
    'AND   hcar14.status = '''||cv_acct_relate_status||''' '||
    'AND   hcar14.attribute1 = '''||cv_acct_relate_type_bill||''' '||
    'AND   hzca14.cust_account_id = hasa14.cust_account_id '||
    'AND   hasa14.cust_acct_site_id = hsua14.cust_acct_site_id '||
    'AND   hsua14.site_use_code = '''||cv_site_use_code_bill_to||''' '||
-- Add 2010-02-03 Ver1.20 Start
    'AND   hsua14.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010-02-03 Ver1.20 End
    'AND   hzca10.cust_account_id = hasa10.cust_account_id '||
    'AND   hasa10.cust_acct_site_id = hsua10.cust_acct_site_id '||
-- Add 2010-02-03 Ver1.20 Start
    'AND   hsua10.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010-02-03 Ver1.20 End
    'AND   hsua10.bill_to_site_use_id = hsua14.site_use_id '||
    'AND EXISTS (SELECT ''X'' '||
    '            FROM hz_cust_accounts          bill_hzca_1, '||             --顧客14顧客マスタ
    '                 hz_cust_accounts          ship_hzca_1, '||             --顧客10顧客マスタ
    '                 hz_cust_acct_sites        bill_hasa_1, '||             --顧客14顧客所在地
    '                 hz_cust_site_uses         bill_hsua_1, '||             --顧客14顧客使用目的
    '                 hz_cust_acct_relate       bill_hcar_1, '||             --顧客関連マスタ(請求関連)
    '                 hz_cust_acct_sites        ship_hasa_1, '||             --顧客10顧客所在地
    '                 hz_cust_site_uses         ship_hsua_1 '||              --顧客10顧客使用目的
    '            WHERE ship_hzca_1.account_number = :iv_customer_code10 '||
    '            AND   bill_hzca_1.account_number = hzca14.account_number '||
    '            AND   bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id '||                   --顧客14顧客マスタ.顧客ID = 顧客関連マスタ.顧客ID
    '            AND   bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id '||           --顧客関連マスタ.関連先顧客ID = 顧客10顧客マスタ.顧客ID
    '            AND   bill_hzca_1.customer_class_code = '''||cv_customer_class_code14||''' '||        --顧客14顧客マスタ.顧客区分 = '14'(売掛管理先顧客)
    '            AND   bill_hcar_1.status = '''||cv_acct_relate_status||''' '||                        --顧客関連マスタ.ステータス = ‘A’
    '            AND   bill_hcar_1.attribute1 = '''||cv_acct_relate_type_bill||''' '||                 --顧客関連マスタ.関連分類 = ‘1’ (請求)
    '            AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id '||                   --顧客14顧客マスタ.顧客ID = 顧客14顧客所在地.顧客ID
    '            AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id '||               --顧客14顧客所在地.顧客所在地ID = 顧客14顧客使用目的.顧客所在地ID
    '            AND   bill_hsua_1.site_use_code = '''||cv_site_use_code_bill_to||''' '||              --顧客14顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010-02-03 Ver1.20 Start
    '            AND   bill_hsua_1.status = '''||cv_site_use_stat_act||''' '||                         --顧客14顧客使用目的.ステータス = 'A'
-- Add 2010-02-03 Ver1.20 End
    '            AND   ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id '||                   --顧客10顧客マスタ.顧客ID = 顧客10顧客所在地.顧客ID
    '            AND   ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id '||               --顧客10顧客所在地.顧客所在地ID = 顧客10顧客使用目的.顧客所在地ID
-- Add 2010-02-03 Ver1.20 Start
    '            AND   ship_hsua_1.status = '''||cv_site_use_stat_act||''' '||                         --顧客14顧客使用目的.ステータス = 'A'
-- Add 2010-02-03 Ver1.20 End
    '            AND   ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id) '||                  --顧客10顧客使用目的.請求先事業所ID = 顧客14顧客使用目的.使用目的ID
-- Ver1.96 ADD START
    'AND   ( '                                                                                  ||
    '        ''' || gv_comp_spin_off_flag || ''' = ''N'' '                                      ||
    '        OR '                                                                               ||
    '        (  '                                                                               ||
    '          ''' || gv_comp_spin_off_flag || ''' = ''Y'' '                                    ||
    '          AND '                                                                            ||
    '          EXISTS ( '                                                                       ||
    '            SELECT 1 '                                                                     ||
    '            FROM   xxcfr_bd_dept_comp_info_v  xbdciv '                                     ||
    '            WHERE  xbdciv.dept_code        = xxca10.bill_base_code '                       ||
    '            AND    xbdciv.set_of_books_id  = ' || gn_set_of_bks_id                         ||
    '            AND    TO_DATE( :gv_target_date,''YYYYMMDD'') '                                ||
    '                   BETWEEN xbdciv.comp_start_date '                                        ||
    '                   AND     NVL(xbdciv.comp_end_date, TO_DATE(''99991231'',''YYYYMMDD'')) ' ||
    '            AND    xbdciv.company_code_bd  = ''' || gv_drafting_company || ''' '           ||
    '          ) '                                                                              ||
    '        ) '                                                                                ||
    '      ) '                                                                                  ||
-- Ver1.96 ADD END
    'UNION ALL '||
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.40 Start
    '       xxca10.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.40 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     xxcmm_cust_accounts xxca20, '||                                     -- 顧客20顧客追加情報
    '     hz_cust_accounts    hzca10 '||                                      -- 顧客10顧客マスタ
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_a6||''' '||      -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||           -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   EXISTS (SELECT ''X'' '||
    '              FROM xxcmm_cust_accounts xxca10_sub '||
    '              WHERE xxca10_sub.customer_code = :iv_customer_code10 '||
-- Ver1.96 MOD START
--    '              AND   xxca10_sub.invoice_code = xxca20.customer_code) ';
    '              AND   xxca10_sub.invoice_code = xxca20.customer_code) ' ||
    'AND   ( '                                                                                  ||
    '        ''' || gv_comp_spin_off_flag || ''' = ''N'' '                                      ||
    '        OR '                                                                               ||
    '        (  '                                                                               ||
    '          ''' || gv_comp_spin_off_flag || ''' = ''Y'' '                                    ||
    '          AND '                                                                            ||
    '          EXISTS ( '                                                                       ||
    '            SELECT 1 '                                                                     ||
    '            FROM   xxcfr_bd_dept_comp_info_v  xbdciv '                                     ||
    '            WHERE  xbdciv.dept_code        = xxca10.bill_base_code '                       ||
    '            AND    xbdciv.set_of_books_id  = ' || gn_set_of_bks_id                         ||
    '            AND    TO_DATE( :gv_target_date,''YYYYMMDD'') '                                ||
    '                   BETWEEN xbdciv.comp_start_date '                                        ||
    '                   AND     NVL(xbdciv.comp_end_date, TO_DATE(''99991231'',''YYYYMMDD'')) ' ||
    '            AND    xbdciv.company_code_bd  = ''' || gv_drafting_company || ''' '           ||
    '          ) '                                                                              ||
    '        ) '                                                                                ||
    '      ) ';
-- Ver1.96 MOD END
-- Modify 2009-11-11 Ver1.10 End
--
    -- 顧客14取得カーソル
    CURSOR get_14account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT bill_hzca_1.cust_account_id         AS cash_account_id,         --顧客14ID
            bill_hzca_1.account_number          AS cash_account_number,     --顧客14コード
            bill_hzpa_1.party_name              AS cash_account_name,       --顧客14顧客名
            ship_hzca_1.cust_account_id         AS ship_account_id,         --顧客10顧客ID        
            ship_hzca_1.account_number          AS ship_account_number,     --顧客10顧客コード 
            bill_hzad_1.bill_base_code          AS bill_base_code,          --顧客14請求拠点コード
            bill_hzlo_1.postal_code             AS bill_postal_code,        --顧客14郵便番号            
            bill_hzlo_1.state                   AS bill_state,              --顧客14都道府県            
            bill_hzlo_1.city                    AS bill_city,               --顧客14市・区              
            bill_hzlo_1.address1                AS bill_address1,           --顧客14住所1               
            bill_hzlo_1.address2                AS bill_address2,           --顧客14住所2
            bill_hzlo_1.address_lines_phonetic  AS phone_num,               --顧客14電話番号
            bill_hzad_1.tax_div                 AS bill_tax_div,            --顧客14消費税区分
            bill_hsua_1.attribute7              AS bill_invoice_type,       --顧客14請求書出力形式      
            bill_hsua_1.payment_term_id         AS bill_payment_term_id,    --顧客14支払条件
-- Add 2010.12.10 Ver1.30 Start
            bill_hsua_1.attribute8              AS bill_pub_cycle,          --顧客14請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
            bill_hcp.cons_inv_flag              AS cons_inv_flag            --一括請求書式
     FROM hz_cust_accounts          bill_hzca_1,              --顧客14顧客マスタ
          hz_cust_accounts          ship_hzca_1,              --顧客10顧客マスタ
          xxcmm_cust_accounts       bill_hzad_1,              --顧客14顧客追加情報
          hz_cust_acct_sites        bill_hasa_1,              --顧客14顧客所在地
          hz_locations              bill_hzlo_1,              --顧客14顧客事業所
          hz_cust_site_uses         bill_hsua_1,              --顧客14顧客使用目的
          hz_cust_acct_relate       bill_hcar_1,              --顧客関連マスタ(請求関連)
          hz_cust_acct_sites        ship_hasa_1,              --顧客10顧客所在地
          hz_cust_site_uses         ship_hsua_1,              --顧客10顧客使用目的
          hz_party_sites            bill_hzps_1,              --顧客14パーティサイト
          hz_parties                bill_hzpa_1,              --顧客14パーティ
          hz_customer_profiles      bill_hcp                  --顧客プロファイル
     WHERE ship_hzca_1.cust_account_id = iv_customer_id
     AND   bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --顧客14顧客マスタ.顧客ID = 顧客関連マスタ.顧客ID
     AND   bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --顧客関連マスタ.関連先顧客ID = 顧客10顧客マスタ.顧客ID
     AND   bill_hzca_1.customer_class_code = cv_customer_class_code14        --顧客14顧客マスタ.顧客区分 = '14'(売掛管理先顧客)
     AND   bill_hcar_1.status = cv_acct_relate_status                        --顧客関連マスタ.ステータス = ‘A’
     AND   bill_hcar_1.attribute1 = cv_acct_relate_type_bill                 --顧客関連マスタ.関連分類 = ‘1’ (請求)
     AND   bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --顧客14顧客マスタ.顧客ID = 顧客14顧客追加情報.顧客ID
     AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --顧客14顧客マスタ.顧客ID = 顧客14顧客所在地.顧客ID
     AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --顧客14顧客所在地.顧客所在地ID = 顧客14顧客使用目的.顧客所在地ID
     AND   bill_hsua_1.site_use_code = cv_site_use_code_bill_to              --顧客14顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010-02-03 Ver1.20 Start
     AND   bill_hsua_1.status = cv_site_use_stat_act                         --顧客14顧客使用目的.ステータス = 'A'
-- Add 2010-02-03 Ver1.20 End
     AND   ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --顧客10顧客マスタ.顧客ID = 顧客10顧客所在地.顧客ID
     AND   ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --顧客10顧客所在地.顧客所在地ID = 顧客10顧客使用目的.顧客所在地ID
-- Add 2010-02-03 Ver1.20 Start
     AND   ship_hsua_1.status = cv_site_use_stat_act                         --顧客10顧客使用目的.ステータス = 'A'
-- Add 2010-02-03 Ver1.20 End
     AND   ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --顧客10顧客使用目的.請求先事業所ID = 顧客14顧客使用目的.使用目的ID
     AND   bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --顧客14顧客所在地.パーティサイトID = 顧客14パーティサイト.パーティサイトID  
     AND   bill_hzps_1.location_id = bill_hzlo_1.location_id                 --顧客14パーティサイト.事業所ID = 顧客14顧客事業所.事業所ID                  
     AND   bill_hzca_1.party_id = bill_hzpa_1.party_id                       --顧客14顧客マスタ.パーティID = 顧客14.パーティID
     AND   bill_hsua_1.site_use_id = bill_hcp.site_use_id;                   --顧客14顧客使用目的.使用目的ID = 顧客プロファイル.使用目的ID
--
    get_14account_rec get_14account_cur%ROWTYPE;
--
    -- 顧客21取得カーソル
    CURSOR get_21account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT xxca21.customer_id                  AS bill_account_id,         --顧客21ID
            xxca21.customer_code                AS bill_account_number,     --顧客21コード
            hzpa21.party_name                   AS bill_account_name,       --顧客21顧客名
            xxca21.bill_base_code               AS bill_base_code21,        --顧客21請求拠点コード
            hzlo21.postal_code                  AS bill_postal_code,        --顧客21郵便番号
            hzlo21.state                        AS bill_state,              --顧客21都道府県
            hzlo21.city                         AS bill_city,               --顧客21市・区
            hzlo21.address1                     AS bill_address1,           --顧客21住所1
            hzlo21.address2                     AS bill_address2,           --顧客21住所2
            hzlo21.address_lines_phonetic       AS phone_num,               --顧客21電話番号
            xxca20.bill_base_code               AS bill_base_code20         --顧客20請求拠点コード
     FROM xxcmm_cust_accounts       xxca21,                   --顧客21顧客追加情報
          xxcmm_cust_accounts       xxca20,                   --顧客20顧客追加情報
          xxcmm_cust_accounts       xxca10,                   --顧客10顧客追加情報
          hz_cust_accounts          hzca20,                   --顧客20顧客マスタ
          hz_cust_accounts          hzca21,                   --顧客21顧客マスタ
          hz_parties                hzpa21,                   --顧客21パーティ
          hz_cust_acct_sites        hcas21,                   --顧客21顧客所在地
          hz_party_sites            hzps21,                   --顧客21パーティサイト
          hz_locations              hzlo21                    --顧客21顧客事業所
     WHERE xxca10.customer_id = iv_customer_id
     AND   xxca10.invoice_code = xxca20.customer_code                        --顧客10顧客追加情報.請求書用コード = 顧客20顧客追加情報.顧客コード
     AND   xxca20.enclose_invoice_code = xxca21.customer_code                --顧客20顧客追加情報.統括請求書用コード = 顧客21顧客追加情報.顧客コード
     AND   hzca20.customer_class_code = cv_customer_class_code20             --顧客20顧客マスタ.顧客区分 = '20'(請求書用)
     AND   hzca20.cust_account_id = xxca20.customer_id                       --顧客20顧客マスタ.顧客ID = 顧客20顧客追加情報.顧客コード
     AND   hzca21.customer_class_code = cv_customer_class_code21             --顧客21顧客マスタ.顧客区分 = '21'(統括請求書用)
     AND   hzca21.cust_account_id = xxca21.customer_id                       --顧客21顧客マスタ.顧客ID = 顧客21顧客追加情報.顧客コード
     AND   hzca21.party_id = hzpa21.party_id                                 --顧客21顧客マスタ.パーティID = 顧客21パーティ.パーティID
     AND   hzca21.cust_account_id = hcas21.cust_account_id                   --顧客21顧客マスタ.顧客ID = 顧客21所在地.顧客ID
     AND   hcas21.party_site_id = hzps21.party_site_id                       --顧客所在地21.パーティサイト = 顧客21パーティサイト.顧客21パーティサイトID
     AND   hzps21.location_id = hzlo21.location_id;                          --顧客21パーティサイト.事業所ID = 顧客21顧客事業所.事業所ID
--
    get_21account_rec get_21account_cur%ROWTYPE;
--
    -- 顧客20取得カーソル
    CURSOR get_20account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT xxca20.customer_id                  AS bill_account_id,         --顧客20ID
            xxca20.customer_code                AS bill_account_number,     --顧客20コード
            hzpa20.party_name                   AS bill_account_name,       --顧客20顧客名
            xxca20.bill_base_code               AS bill_base_code,          --顧客20請求拠点コード
            hzlo20.postal_code                  AS bill_postal_code,        --顧客20郵便番号
            hzlo20.state                        AS bill_state,              --顧客20都道府県
            hzlo20.city                         AS bill_city,               --顧客20市・区
            hzlo20.address1                     AS bill_address1,           --顧客20住所1
            hzlo20.address2                     AS bill_address2,           --顧客20住所2
            hzlo20.address_lines_phonetic       AS phone_num                --顧客20電話番号
     FROM xxcmm_cust_accounts       xxca20,                   --顧客20顧客追加情報
          xxcmm_cust_accounts       xxca10,                   --顧客10顧客追加情報
          hz_cust_accounts          hzca20,                   --顧客20顧客マスタ
          hz_parties                hzpa20,                   --顧客20パーティ
          hz_cust_acct_sites        hcas20,                   --顧客20顧客所在地
          hz_party_sites            hzps20,                   --顧客20パーティサイト
          hz_locations              hzlo20                    --顧客20顧客事業所
     WHERE xxca10.customer_id = iv_customer_id
     AND   xxca10.invoice_code = xxca20.customer_code                        --顧客10顧客追加情報.請求書用コード = 顧客20顧客追加情報.顧客コード
     AND   hzca20.customer_class_code = cv_customer_class_code20             --顧客20顧客マスタ.顧客区分 = '20'(請求書用)
     AND   hzca20.cust_account_id = xxca20.customer_id                       --顧客20顧客マスタ.顧客ID = 顧客20顧客追加情報.顧客コード
     AND   hzca20.party_id = hzpa20.party_id                                 --顧客20顧客マスタ.パーティID = 顧客20パーティ.パーティID
     AND   hzca20.cust_account_id = hcas20.cust_account_id                   --顧客20顧客マスタ.顧客ID = 顧客2-所在地.顧客ID
     AND   hcas20.party_site_id = hzps20.party_site_id                       --顧客所在地20.パーティサイト = 顧客20パーティサイト.顧客21パーティサイトID
     AND   hzps20.location_id = hzlo20.location_id;                          --顧客20パーティサイト.事業所ID = 顧客20顧客事業所.事業所ID
--
    get_20account_rec get_20account_cur%ROWTYPE;
--
-- Add 2013.12.13 Ver1.60 Start
    -- *** ローカル例外 ***
    update_work_expt  EXCEPTION;
-- Add 2013.12.13 Ver1.60 End
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 日本語文字列取得
    -- ====================================================
    lv_format_date_jpymd4 := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                        ,cv_dict_ymd4 )  -- YYYY"年"MM"月"DD"日"
                                    ,1
                                    ,5000);
    lv_format_date_jpymd2 := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                        ,cv_dict_ymd2 )  -- YY"年"MM"月"DD"日"
                                    ,1
                                    ,5000);
    lv_format_date_year := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                      ,cv_dict_year )  -- 年
                                  ,1
                                  ,5000);
    lv_format_date_month := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr   -- 'XXCFR'
                                                                       ,cv_dict_month )  -- 月
                                   ,1
                                   ,5000);
    lv_format_date_bank := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                      ,cv_dict_bank )  -- 銀行
                                  ,1
                                  ,5000);
    lv_format_date_central := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                        ,cv_dict_central )  -- 本店
                                     ,1
                                     ,5000);
    lv_format_date_branch := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                        ,cv_dict_branch )  -- 支店
                                     ,1
                                     ,5000);
    lv_format_date_account := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                         ,cv_dict_account ) -- 普通
                                     ,1
                                     ,5000);
    lv_format_date_current := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                         ,cv_dict_current ) -- 当座
                                    ,1
                                    ,5000);
    lv_format_zip_mark := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr     -- 'XXCFR'
                                                                     ,cv_dict_zip_mark ) -- 〒
                                  ,1
                                  ,5000);
    lv_format_bank_dummy := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr     -- 'XXCFR'
                                                                       ,cv_dict_bank_damy ) -- D
                                   ,1
                                   ,5000);
--
    -- ====================================================
    -- 帳票０件メッセージ取得
    -- ====================================================
    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                       ,cv_msg_003a18_014 ) -- 帳票０件メッセージ
                              ,1
                              ,5000);
--
    -- ====================================================
    -- ワークテーブルへの登録
    -- ====================================================
    BEGIN
--
      -- 売掛管理先顧客指定時
      IF (iv_customer_code14 IS NOT NULL) THEN
-- Ver1.96 MOD START
--        OPEN get_all_account_cur FOR cv_get_14account_cur USING iv_customer_code14;
        OPEN get_all_account_cur FOR cv_get_14account_cur USING iv_customer_code14, gv_target_date;
-- Ver1.96 MOD END
      -- 統括請求書用顧客指定時
      ELSIF (iv_customer_code21 IS NOT NULL) THEN
-- Ver1.96 MOD START
--        OPEN get_all_account_cur FOR cv_get_21account_cur USING iv_customer_code21;
        OPEN get_all_account_cur FOR cv_get_21account_cur USING iv_customer_code21, gv_target_date;
-- Ver1.96 MOD END
      -- 請求書用顧客指定時
      ELSIF (iv_customer_code20 IS NOT NULL) THEN
-- Modify 2009-11-11 Ver1.10 Start
--        OPEN get_all_account_cur FOR cv_get_20account_cur USING iv_customer_code20;
-- Ver1.96 MOD START
--        OPEN get_all_account_cur FOR cv_get_20account_cur USING iv_customer_code20,iv_customer_code20;
        OPEN get_all_account_cur FOR cv_get_20account_cur
        USING iv_customer_code20
             ,gv_target_date
             ,iv_customer_code20
             ,gv_target_date;
-- Ver1.96 MOD END
-- Modify 2009-11-11 Ver1.10 End
      -- 顧客指定時
      ELSIF (iv_customer_code10 IS NOT NULL) THEN
-- Modify 2009-11-11 Ver1.10 Start
--        OPEN get_all_account_cur FOR cv_get_10account_cur USING iv_customer_code10;
-- Ver1.96 MOD START
--        OPEN get_all_account_cur FOR cv_get_10account_cur USING iv_customer_code10,iv_customer_code10;
        OPEN get_all_account_cur FOR cv_get_10account_cur
        USING iv_customer_code10
             ,gv_target_date
             ,iv_customer_code10
             ,gv_target_date;
-- Ver1.96 MOD END
-- Modify 2009-11-11 Ver1.10 End
      -- パラメータ指定なし時
      ELSE
-- Ver1.96 MOD START
--        OPEN get_all_account_cur FOR cv_get_all_account_cur;
        OPEN get_all_account_cur FOR cv_get_all_account_cur USING gv_target_date;
-- Ver1.96 MOD END
      END IF;
--
      <<get_account10_loop>>
      LOOP 
        FETCH get_all_account_cur INTO all_account_rec;
        EXIT WHEN get_all_account_cur%NOTFOUND;
--
        -- 請求書印刷単位が内訳ありのパターンのみ処理を行う
        IF all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_a1,
                                                     cv_invoice_printing_unit_a2,
                                                     cv_invoice_printing_unit_a3,
                                                     cv_invoice_printing_unit_a4,
                                                     cv_invoice_printing_unit_a5,
-- Mod 2015.07.31 Ver1.80 Start
--                                                     cv_invoice_printing_unit_a6) THEN
                                                     cv_invoice_printing_unit_a6,
                                                     cv_invoice_printing_unit_a7,
-- Mod 2016.03.31 Ver1.90 Start
--                                                     cv_invoice_printing_unit_a8) THEN
                                                     cv_invoice_printing_unit_a8,
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--                                                     cv_invoice_printing_unit_a9) THEN
                                                     cv_invoice_printing_unit_a9,
                                                     cv_invoice_printing_unit_a10) THEN
-- Ver.1.92 [障害E_本稼動_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
          -- 顧客区分14の顧客に紐づく、顧客区分14の顧客を取得
          OPEN get_14account_cur(all_account_rec.customer_id);
          FETCH get_14account_cur INTO get_14account_rec;
--
          -- 紐づく顧客区分14の顧客が存在しない場合
          IF get_14account_cur%NOTFOUND THEN
            -- 全社出力権限部門の場合と、該当顧客の請求拠点がログインユーザの所属部門と一致する場合
            IF (all_account_rec.bill_base_code = gt_user_dept)
            OR (gv_inv_all_flag = cv_status_yes)
            THEN
              -- 顧客区分14存在なしメッセージ出力
              put_account_warning(iv_customer_class_code => cv_customer_class_code14
                                 ,iv_customer_code       => all_account_rec.customer_code
                                 ,ov_errbuf              => lv_errbuf
                                 ,ov_retcode             => lv_retcode
                                 ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(エラー処理)
                RAISE global_process_expt;
              END IF;
            END IF;
--
          --請求書印刷単位 = 'A1'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a1)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- 消費税区分 IN (内税(伝票),内税(単価))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
-- Modify 2014.03.27 Ver1.70 End
          AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.30 End
          THEN
            INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
              report_id               , -- 帳票ＩＤ
              issue_date              , -- 発行日
              zip_code                , -- 郵便番号
              send_address1           , -- 住所１
              send_address2           , -- 住所２
              send_address3           , -- 住所３
              bill_cust_code          , -- 顧客コード(ソート順２)
              bill_cust_name          , -- 顧客名
              location_code           , -- 担当拠点コード
              location_name           , -- 担当拠点名
              phone_num               , -- 電話番号
              target_date             , -- 対象年月
              payment_cust_code       , -- 入金先顧客コード
              payment_cust_name       , -- 入金先顧客名
              ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
              payment_due_date        , -- 入金予定日
              bank_account            , -- 振込口座情報
              ship_cust_code          , -- ★納品先顧客コード
              ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
              store_code              , -- 店舗コード
              store_code_sort         , -- 店舗コード(ソート用)
              ship_account_number     , -- 納品先顧客コード(ソート用)
              invo_account_number     , -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
              slip_date               , -- 伝票日付(ソート順３)
              slip_num                , -- 伝票No(ソート順４)
              slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
              slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--              tax_rate                , -- 消費税率(編集用)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- 摘要
              category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
              outsourcing_flag        , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
              data_empty_message      , -- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
              invoice_tax_div         , -- 請求書消費税積上げ計算方式
              tax_amount_sum          , -- 税額合計１
              tax_amount_sum2         , -- 税額合計２
              inv_amount_sum          , -- 税抜合計１
              inv_amount_sum2         , -- 税抜合計２
              invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
              created_by              , -- 作成者
              creation_date           , -- 作成日
              last_updated_by         , -- 最終更新者
              last_update_date        , -- 最終更新日
              last_update_login       , -- 最終更新ログイン
              request_id              , -- 要求ID
              program_application_id  , -- アプリケーションID
              program_id              , -- コンカレント・プログラムID
              program_update_date     ) -- プログラム更新日
            SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                   get_14account_rec.bill_state||get_14account_rec.bill_city                  send_address1    , -- 住所１
                   get_14account_rec.bill_address1                                        send_address2    , -- 住所２
                   get_14account_rec.bill_address2                                        send_address3    , -- 住所３
                   get_14account_rec.cash_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                   get_14account_rec.cash_account_name                                    bill_cust_name   , -- 顧客名
                   get_14account_rec.bill_base_code                                       bill_base_code   , -- 担当拠点コード
                   xffvv.description                                                  location_name    , -- 担当拠点名
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num        , -- 電話番号
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                   get_14account_rec.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                   get_14account_rec.cash_account_name                                payment_cust_name, -- 入金先顧客名
                   get_14account_rec.cash_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END                                                                account_data     , -- 振込口座情報
                   xil.ship_cust_code                                                 ship_cust_code   , -- 納品先顧客コード
                   hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code         ,  -- 店舗コード
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- 店舗コード(ソート用)
                   xil.ship_cust_code                                                 ship_account_number,  -- 納品先顧客コード(ソート用)
                   NULL                                                               invo_account_number,  -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                   xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                   SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                   SUM(xil.tax_amount)                                                tax_sum          , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                   xil.tax_rate                                                       tax_rate         , -- 消費税率
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                           description      , -- 摘要
                   flvv.attribute2                                                    category         , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                outsourcing_flag , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                   NULL                                                               data_empty_message,-- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                   xih.invoice_tax_div                                                invoice_tax_div  , -- 請求書消費税積上げ計算方式
                   SUM(xil.tax_amount_sum)                                            tax_amount_sum   , -- 税額合計１
                   SUM(xil.tax_amount_sum2)                                           tax_amount_sum2  , -- 税額合計２
                   SUM(xil.inv_amount_sum)                                            inv_amount_sum   , -- 税抜合計１
                   SUM(xil.inv_amount_sum2)                                           inv_amount_sum2  , -- 税抜合計２
                   gv_t_number                                                        invoice_t_no     , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                   cn_created_by                                                      created_by,             -- 作成者
                   cd_creation_date                                                   creation_date,          -- 作成日
                   cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                   cd_last_update_date                                                last_update_date,       -- 最終更新日
                   cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                   cn_request_id                                                      request_id,             -- 要求ID
                   cn_program_application_id                                          program_application_id, -- アプリケーションID
                   cn_program_id                                                      program_id,
                                                                                      -- コンカレント・プログラムID
                   cd_program_update_date                                             program_update_date     -- プログラム更新日
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                       ar_receipt_method_accounts_all arma , --AR支払方法口座
                       ap_bank_accounts_all           abaa , --銀行口座
                       ap_bank_branches               abb    --銀行支店
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                 (SELECT flex_value,
                         description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets
                          WHERE   flex_value_set_name = cv_ffv_set_name_dept
                          AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
              AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
              AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                     xil.slip_num;
                     xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                     xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
-- Modify 2023.07.04 Ver1.95 Start
--                     END
                     END,
                     xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
-- Modify 2014.03.27 Ver1.70 End
                     ;
-- Modify 2013.12.13 Ver1.60 End
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          --請求書印刷単位 = 'A2'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a2)
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- 消費税区分 IN (内税(伝票),内税(単価))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.30 End
          THEN
            OPEN get_21account_cur(all_account_rec.customer_id);
            FETCH get_21account_cur INTO get_21account_rec;
--
            --顧客区分21の顧客が存在しない場合
            IF get_21account_cur%NOTFOUND THEN
              -- 全社出力権限部門の場合と、該当顧客の請求拠点がログインユーザの所属部門と一致する場合
              IF (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
              THEN
                -- 顧客区分21存在なしメッセージ出力
                put_account_warning(iv_customer_class_code => cv_customer_class_code21
                                   ,iv_customer_code       => all_account_rec.customer_code
                                   ,ov_errbuf              => lv_errbuf
                                   ,ov_retcode             => lv_retcode
                                   ,ov_errmsg              => lv_errmsg);
                IF (lv_retcode = cv_status_error) THEN
                  --(エラー処理)
                  RAISE global_process_expt;
                END IF;
              END IF;
            --
            -- 全社出力権限部門 OR 統括請求書用顧客の請求拠点がログインユーザの所属部門の場合
            ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                  ((gv_inv_all_flag = cv_status_no) AND  (get_21account_rec.bill_base_code21 = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
            THEN
              INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
                report_id               , -- 帳票ＩＤ
                issue_date              , -- 発行日
                zip_code                , -- 郵便番号
                send_address1           , -- 住所１
                send_address2           , -- 住所２
                send_address3           , -- 住所３
                bill_cust_code          , -- 顧客コード(ソート順２)
                bill_cust_name          , -- 顧客名
                location_code           , -- 担当拠点コード
                location_name           , -- 担当拠点名
                phone_num               , -- 電話番号
                target_date             , -- 対象年月
                payment_cust_code       , -- 入金先顧客コード
                payment_cust_name       , -- 入金先顧客名
                ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
                payment_due_date        , -- 入金予定日
                bank_account            , -- 振込口座情報
                ship_cust_code          , -- ★納品先顧客コード
                ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                store_code              , -- 店舗コード
                store_code_sort         , -- 店舗コード(ソート用)
                ship_account_number     , -- 納品先顧客コード(ソート用)
                invo_account_number     , -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                slip_date               , -- 伝票日付(ソート順３)
                slip_num                , -- 伝票No(ソート順４)
                slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
                slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                tax_rate                , -- 消費税率(編集用)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                description             , -- 摘要
                category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                outsourcing_flag        , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                data_empty_message      , -- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
              invoice_tax_div         , -- 請求書消費税積上げ計算方式
              tax_amount_sum          , -- 税額合計１
              tax_amount_sum2         , -- 税額合計２
              inv_amount_sum          , -- 税抜合計１
              inv_amount_sum2         , -- 税抜合計２
              invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                created_by              , -- 作成者
                creation_date           , -- 作成日
                last_updated_by         , -- 最終更新者
                last_update_date        , -- 最終更新日
                last_update_login       , -- 最終更新ログイン
                request_id              , -- 要求ID
                program_application_id  , -- アプリケーションID
                program_id              , -- コンカレント・プログラムID
                program_update_date     ) -- プログラム更新日
              SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                     TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                     DECODE(get_21account_rec.bill_postal_code,
                            NULL,NULL,
                            lv_format_zip_mark||SUBSTR(get_21account_rec.bill_postal_code,1,3)||'-'||
                            SUBSTR(get_21account_rec.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                     get_21account_rec.bill_state||get_21account_rec.bill_city                  send_address1    , -- 住所１
                     get_21account_rec.bill_address1                                        send_address2    , -- 住所２
                     get_21account_rec.bill_address2                                        send_address3    , -- 住所３
                     get_21account_rec.bill_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                     get_21account_rec.bill_account_name                                    bill_cust_name   , -- 顧客名
                     get_21account_rec.bill_base_code21                                     bill_base_code   , -- 担当拠点コード
                     xffvv.description                                                  location_name    , -- 担当拠点名
                     xxcfr_common_pkg.get_base_target_tel_num(get_21account_rec.bill_account_number)   phone_num        , -- 電話番号
                     SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                     SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                     get_14account_rec.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                     get_14account_rec.cash_account_name                                payment_cust_name, -- 入金先顧客名
                     get_21account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                     TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END                                                                account_data     , -- 振込口座情報
                     xxca.invoice_code                                                 ship_cust_code   , -- 納品先顧客コード
                     hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                     NULL                                                               store_code         ,  -- 店舗コード
-- Modify 2011.03.10 Ver1.50 Start
--                    LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- 店舗コード(ソート用)
--                    all_account_rec.customer_code                                      ship_account_number,  -- 納品先顧客コード(ソート用)
                     NULL                                                               store_code_sort    ,  -- 店舗コード(ソート用)
                     NULL                                                               ship_account_number,  -- 納品先顧客コード(ソート用)
-- Modify 2011.03.10 Ver1.50 End
                     xxca.invoice_code                                                  invo_account_number,  -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                             cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                     xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                     SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                     SUM(xil.tax_amount)                                                tax_sum          , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                     xil.tax_rate                                                       tax_rate         , -- 消費税率
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     NVL(flvv.attribute1,' ')                                           description      , -- 摘要
                     flvv.attribute2                                                    category         , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END                                                                outsourcing_flag , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                     NULL                                                               data_empty_message,-- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                     xih.invoice_tax_div                                                invoice_tax_div  , -- 請求書消費税積上げ計算方式
                     SUM(xil.tax_amount_sum)                                            tax_amount_sum   , -- 税額合計１
                     SUM(xil.tax_amount_sum2)                                           tax_amount_sum2  , -- 税額合計２
                     SUM(xil.inv_amount_sum)                                            inv_amount_sum   , -- 税抜合計１
                     SUM(xil.inv_amount_sum2)                                           inv_amount_sum2  , -- 税抜合計２
                     gv_t_number                                                        invoice_t_no     , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                     cn_created_by                                                      created_by,             -- 作成者
                     cd_creation_date                                                   creation_date,          -- 作成日
                     cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                     cd_last_update_date                                                last_update_date,       -- 最終更新日
                     cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                     cn_request_id                                                      request_id,             -- 要求ID
                     cn_program_application_id                                          program_application_id, -- アプリケーションID
                     cn_program_id                                                      program_id,
                                                                                        -- コンカレント・プログラムID
                     cd_program_update_date                                             program_update_date     -- プログラム更新日
              FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                   xxcfr_invoice_lines            xil  , -- 請求明細
                   hz_cust_accounts               hzca , -- 顧客20顧客マスタ
                   hz_parties                     hzp  , -- 顧客20パーティマスタ
                   xxcmm_cust_accounts            xxca , -- 顧客10追加情報
                   (SELECT all_account_rec.customer_code ship_cust_code,
                           rcrm.customer_id              customer_id,
                           abb.bank_number               bank_number,
                           abb.bank_name                 bank_name,
                           abb.bank_branch_name          bank_branch_name,
                           abaa.bank_account_type        bank_account_type,
                           abaa.bank_account_num         bank_account_num,
                           abaa.account_holder_name      account_holder_name,
                           abaa.account_holder_name_alt  account_holder_name_alt
                    FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                         ar_receipt_method_accounts_all arma , --AR支払方法口座
                         ap_bank_accounts_all           abaa , --銀行口座
                         ap_bank_branches               abb    --銀行支店
                    WHERE rcrm.primary_flag = cv_enabled_yes
                      AND get_14account_rec.cash_account_id = rcrm.customer_id
                      AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                      AND rcrm.site_use_id IS NOT NULL
                      AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND arma.bank_account_id = abaa.bank_account_id(+)
                      AND abaa.bank_branch_id = abb.bank_branch_id(+)
                      AND arma.org_id = gn_org_id
                      AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = cv_ffv_set_name_dept
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                  ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
              WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
                AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
                AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND get_21account_rec.bill_base_code21 = xffvv.flex_value
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND xxca.customer_id = all_account_rec.customer_id
                AND hzca.account_number = xxca.invoice_code
                AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
                AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
                AND xil.tax_code         = flvv.lookup_code(+)
                AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
              GROUP BY cv_pkg_name,
                       xih.inv_creation_date,
                       DECODE(get_21account_rec.bill_postal_code,
                                   NULL,NULL,
                                   lv_format_zip_mark||SUBSTR(get_21account_rec.bill_postal_code,1,3)||'-'||
                                   SUBSTR(get_21account_rec.bill_postal_code,4,4)),
                       get_21account_rec.bill_state||get_21account_rec.bill_city,
                       get_21account_rec.bill_address1,
                       get_21account_rec.bill_address2,
                       get_21account_rec.bill_account_number,
                       get_21account_rec.bill_account_name,
                       xffvv.description,
                       xih.object_month,
                       get_14account_rec.cash_account_number,
                       get_14account_rec.cash_account_name,
                       get_21account_rec.bill_account_number||' '||xih.term_name,
                       xih.payment_date,
                       CASE
                       WHEN account.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(account.bank_number,1,1),
                         lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                         CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                           CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                             account.bank_name
                           ELSE
                             account.bank_name ||lv_format_date_bank
                           END
                         ELSE
                          account.bank_name 
                         END||' '||                                                       -- 銀行名
                         CASE WHEN INSTR(account.bank_branch_name
                                        ,lv_format_date_central)>0 THEN
                           account.bank_branch_name
                         ELSE
                           account.bank_branch_name||lv_format_date_branch 
                         END||' '||                                                       -- 支店名
                         DECODE( account.bank_account_type,
                                 1,lv_format_date_account,
                                 2,lv_format_date_current,
                                 account.bank_account_type) ||' '||                       -- 口座種別
                         account.bank_account_num ||' '||                                 -- 口座番号
                         account.account_holder_name||' '||                               -- 口座名義人
                         account.account_holder_name_alt)                                 -- 口座名義人カナ名
                       END,
                       xxca.invoice_code,
                       hzp.party_name,
                       TO_CHAR(DECODE(xil.acceptance_date,
                                      NULL,xil.delivery_date,
                                      xil.acceptance_date),
                       cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                       xil.slip_num;
                       xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                       xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                       xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                       flvv.attribute1,
                       flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                       CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                         cv_os_flag_y
                       ELSE
                         NULL
-- Modify 2023.07.04 Ver1.95 Start
--                     END
                     END,
                     xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
-- Modify 2014.03.27 Ver1.70 End
                       ;
-- Modify 2013.12.13 Ver1.60 End
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            ELSE
              NULL;
            END IF;
--
            CLOSE get_21account_cur;
--
          --請求書印刷単位 = 'A3'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a3)
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- 消費税区分 IN (内税(伝票),内税(単価))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.30 End
          THEN
            OPEN get_20account_cur(all_account_rec.customer_id);
            FETCH get_20account_cur INTO get_20account_rec;
            --顧客区分20の顧客が存在しない場合
            IF get_20account_cur%NOTFOUND THEN
              -- 全社出力権限部門の場合と、該当顧客の請求拠点がログインユーザの所属部門と一致する場合
              IF (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
              THEN
                -- 顧客区分20存在なしメッセージ出力
                put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                   ,iv_customer_code       => all_account_rec.customer_code
                                   ,ov_errbuf              => lv_errbuf
                                   ,ov_retcode             => lv_retcode
                                   ,ov_errmsg              => lv_errmsg);
                IF (lv_retcode = cv_status_error) THEN
                  --(エラー処理)
                  RAISE global_process_expt;
                END IF;
              END IF;
            ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                  ((gv_inv_all_flag = cv_status_no) AND  (get_20account_rec.bill_base_code = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
            THEN
              INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
                report_id               , -- 帳票ＩＤ
                issue_date              , -- 発行日
                zip_code                , -- 郵便番号
                send_address1           , -- 住所１
                send_address2           , -- 住所２
                send_address3           , -- 住所３
                bill_cust_code          , -- 顧客コード(ソート順２)
                bill_cust_name          , -- 顧客名
                location_code           , -- 拠点コード
                location_name           , -- 担当拠点名
                phone_num               , -- 電話番号
                target_date             , -- 対象年月
                payment_cust_code       , -- 入金先顧客コード
                payment_cust_name       , -- 入金先顧客名
                ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
                payment_due_date        , -- 入金予定日
                bank_account            , -- 振込口座情報
                ship_cust_code          , -- ★納品先顧客コード
                ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                store_code              , -- 店舗コード
                store_code_sort         , -- 店舗コード(ソート用)
                ship_account_number     , -- 納品先顧客コード(ソート用)
                invo_account_number     , -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                slip_date               , -- 伝票日付(ソート順３)
                slip_num                , -- 伝票No(ソート順４)
                slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
                slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                tax_rate                , -- 消費税率(編集用)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                description             , -- 摘要
                category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                outsourcing_flag        , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                data_empty_message      , -- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                invoice_tax_div         , -- 請求書消費税積上げ計算方式
                tax_amount_sum          , -- 税額合計１
                tax_amount_sum2         , -- 税額合計２
                inv_amount_sum          , -- 税抜合計１
                inv_amount_sum2         , -- 税抜合計２
                invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                created_by              , -- 作成者
                creation_date           , -- 作成日
                last_updated_by         , -- 最終更新者
                last_update_date        , -- 最終更新日
                last_update_login       , -- 最終更新ログイン
                request_id              , -- 要求ID
                program_application_id  , -- アプリケーションID
                program_id              , -- コンカレント・プログラムID
                program_update_date     ) -- プログラム更新日
              SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                     TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                     DECODE(get_20account_rec.bill_postal_code,
                            NULL,NULL,
                            lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                            SUBSTR(get_20account_rec.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                     get_20account_rec.bill_state||get_20account_rec.bill_city                  send_address1    , -- 住所１
                     get_20account_rec.bill_address1                                        send_address2    , -- 住所２
                     get_20account_rec.bill_address2                                        send_address3    , -- 住所３
                     get_20account_rec.bill_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                     get_20account_rec.bill_account_name                                    bill_cust_name   , -- 顧客名
                     get_20account_rec.bill_base_code                                       bill_base_code   , -- 担当拠点コード
                     xffvv.description                                                  location_name    , -- 担当拠点名
                     xxcfr_common_pkg.get_base_target_tel_num(get_20account_rec.bill_account_number)   phone_num        , -- 電話番号
                     SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                     SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                     get_14account_rec.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                     get_14account_rec.cash_account_name                                payment_cust_name, -- 入金先顧客名
                     get_20account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                     TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END                                                                account_data     , -- 振込口座情報
                     xil.ship_cust_code                                                 ship_cust_code   , -- 納品先顧客コード
                     hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                     LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code         ,  -- 店舗コード
                     LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- 店舗コード(ソート用)
                     xil.ship_cust_code                                                 ship_account_number,  -- 納品先顧客コード(ソート用)
                     NULL                                                               invo_account_number,  -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                             cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                     xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                     SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                     SUM(xil.tax_amount)                                                tax_sum          , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                     xil.tax_rate                                                       tax_rate         , -- 消費税率
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     NVL(flvv.attribute1,' ')                                           description      , -- 摘要
                     flvv.attribute2                                                    category         , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END                                                                outsourcing_flag , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                     NULL                                                               data_empty_message,-- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                     xih.invoice_tax_div                                                invoice_tax_div  , -- 請求書消費税積上げ計算方式
                     SUM(xil.tax_amount_sum)                                            tax_amount_sum   , -- 税額合計１
                     SUM(xil.tax_amount_sum2)                                           tax_amount_sum2  , -- 税額合計２
                     SUM(xil.inv_amount_sum)                                            inv_amount_sum   , -- 税抜合計１
                     SUM(xil.inv_amount_sum2)                                           inv_amount_sum2  , -- 税抜合計２
                     gv_t_number                                                        invoice_t_no     , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                     cn_created_by                                                      created_by,             -- 作成者
                     cd_creation_date                                                   creation_date,          -- 作成日
                     cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                     cd_last_update_date                                                last_update_date,       -- 最終更新日
                     cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                     cn_request_id                                                      request_id,             -- 要求ID
                     cn_program_application_id                                          program_application_id, -- アプリケーションID
                     cn_program_id                                                      program_id,
                                                                                        -- コンカレント・プログラムID
                     cd_program_update_date                                             program_update_date     -- プログラム更新日
              FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                   xxcfr_invoice_lines            xil  , -- 請求明細
                   hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                   hz_parties                     hzp  , -- 顧客10パーティマスタ
                   (SELECT all_account_rec.customer_code ship_cust_code,
                           rcrm.customer_id             customer_id,
                           abb.bank_number              bank_number,
                           abb.bank_name                bank_name,
                           abb.bank_branch_name         bank_branch_name,
                           abaa.bank_account_type       bank_account_type,
                           abaa.bank_account_num        bank_account_num,
                           abaa.account_holder_name     account_holder_name,
                           abaa.account_holder_name_alt account_holder_name_alt
                    FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                         ar_receipt_method_accounts_all arma , --AR支払方法口座
                         ap_bank_accounts_all           abaa , --銀行口座
                         ap_bank_branches               abb    --銀行支店
                    WHERE rcrm.primary_flag = cv_enabled_yes
                      AND get_14account_rec.cash_account_id = rcrm.customer_id
                      AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                      AND rcrm.site_use_id IS NOT NULL
                      AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND arma.bank_account_id = abaa.bank_account_id(+)
                      AND abaa.bank_branch_id = abb.bank_branch_id(+)
                      AND arma.org_id = gn_org_id
                      AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = cv_ffv_set_name_dept
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                  ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
              WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
                AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
                AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND get_20account_rec.bill_base_code = xffvv.flex_value
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND hzca.cust_account_id = all_account_rec.customer_id
                AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
                AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
                AND xil.tax_code         = flvv.lookup_code(+)
                AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
              GROUP BY cv_pkg_name,
                       xih.inv_creation_date,
                       DECODE(get_20account_rec.bill_postal_code,
                                   NULL,NULL,
                                   lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                                   SUBSTR(get_20account_rec.bill_postal_code,4,4)),
                       get_20account_rec.bill_state||get_20account_rec.bill_city,
                       get_20account_rec.bill_address1,
                       get_20account_rec.bill_address2,
                       get_20account_rec.bill_account_number,
                       get_20account_rec.bill_account_name,
                       xffvv.description,
                       xih.object_month,
                       get_14account_rec.cash_account_number,
                       get_14account_rec.cash_account_name,
                       get_20account_rec.bill_account_number||' '||xih.term_name,
                       xih.payment_date,
                       CASE
                       WHEN account.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(account.bank_number,1,1),
                         lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                         CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                           CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                             account.bank_name
                           ELSE
                             account.bank_name ||lv_format_date_bank
                           END
                         ELSE
                          account.bank_name 
                         END||' '||                                                       -- 銀行名
                         CASE WHEN INSTR(account.bank_branch_name
                                        ,lv_format_date_central)>0 THEN
                           account.bank_branch_name
                         ELSE
                           account.bank_branch_name||lv_format_date_branch 
                         END||' '||                                                       -- 支店名
                         DECODE( account.bank_account_type,
                                 1,lv_format_date_account,
                                 2,lv_format_date_current,
                                 account.bank_account_type) ||' '||                       -- 口座種別
                         account.bank_account_num ||' '||                                 -- 口座番号
                         account.account_holder_name||' '||                               -- 口座名義人
                         account.account_holder_name_alt)                                 -- 口座名義人カナ名
                       END,
                       xil.ship_cust_code,
                       hzp.party_name,
                       TO_CHAR(DECODE(xil.acceptance_date,
                                      NULL,xil.delivery_date,
                                      xil.acceptance_date),
                       cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                       xil.slip_num;
                       xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                     xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
-- Modify 2023.07.04 Ver1.95 Start
--                     END
                     END,
                     xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
-- Modify 2014.03.27 Ver1.70 End
                     ;
-- Modify 2013.12.13 Ver1.60 End
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            ELSE
              NULL;
            END IF;
--
            CLOSE get_20account_cur;
--
          --請求書印刷単位 = 'A4'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a4)
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- 消費税区分 IN (内税(伝票),内税(単価))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.30 End
          THEN
            OPEN get_21account_cur(all_account_rec.customer_id);
            FETCH get_21account_cur INTO get_21account_rec;
            --顧客区分21の顧客が存在しない場合
            IF get_21account_cur%NOTFOUND THEN
              -- 全社出力権限部門の場合と、該当顧客の請求拠点がログインユーザの所属部門と一致する場合
              IF (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
              THEN
                -- 顧客区分21存在なしメッセージ出力
                put_account_warning(iv_customer_class_code => cv_customer_class_code21
                                   ,iv_customer_code       => all_account_rec.customer_code
                                   ,ov_errbuf              => lv_errbuf
                                   ,ov_retcode             => lv_retcode
                                   ,ov_errmsg              => lv_errmsg);
                IF (lv_retcode = cv_status_error) THEN
                  --(エラー処理)
                  RAISE global_process_expt;
                END IF;
              END IF;
            ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                  ((gv_inv_all_flag = cv_status_no) AND  (get_21account_rec.bill_base_code20 = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
            THEN
              INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
                report_id               , -- 帳票ＩＤ
                issue_date              , -- 発行日
                zip_code                , -- 郵便番号
                send_address1           , -- 住所１
                send_address2           , -- 住所２
                send_address3           , -- 住所３
                bill_cust_code          , -- 顧客コード(ソート順２)
                bill_cust_name          , -- 顧客名
                location_code           , -- 担当拠点コード
                location_name           , -- 担当拠点名
                phone_num               , -- 電話番号
                target_date             , -- 対象年月
                payment_cust_code       , -- 入金先顧客コード
                payment_cust_name       , -- 入金先顧客名
                ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
                payment_due_date        , -- 入金予定日
                bank_account            , -- 振込口座情報
                ship_cust_code          , -- ★納品先顧客コード
                ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                store_code              , -- 店舗コード
                store_code_sort         , -- 店舗コード(ソート用)
                ship_account_number     , -- 納品先顧客コード(ソート用)
                invo_account_number     , -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                slip_date               , -- 伝票日付(ソート順３)
                slip_num                , -- 伝票No(ソート順４)
                slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
                slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                tax_rate                , -- 消費税率(編集用)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                description             , -- 摘要
                category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                outsourcing_flag        , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                data_empty_message      , -- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                invoice_tax_div         , -- 請求書消費税積上げ計算方式
                tax_amount_sum          , -- 税額合計１
                tax_amount_sum2         , -- 税額合計２
                inv_amount_sum          , -- 税抜合計１
                inv_amount_sum2         , -- 税抜合計２
                invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                created_by              , -- 作成者
                creation_date           , -- 作成日
                last_updated_by         , -- 最終更新者
                last_update_date        , -- 最終更新日
                last_update_login       , -- 最終更新ログイン
                request_id              , -- 要求ID
                program_application_id  , -- アプリケーションID
                program_id              , -- コンカレント・プログラムID
                program_update_date     ) -- プログラム更新日
              SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                     TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                     DECODE(get_21account_rec.bill_postal_code,
                            NULL,NULL,
                            lv_format_zip_mark||SUBSTR(get_21account_rec.bill_postal_code,1,3)||'-'||
                            SUBSTR(get_21account_rec.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                     get_21account_rec.bill_state||get_21account_rec.bill_city                  send_address1    , -- 住所１
                     get_21account_rec.bill_address1                                        send_address2    , -- 住所２
                     get_21account_rec.bill_address2                                        send_address3    , -- 住所３
                     get_21account_rec.bill_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                     get_21account_rec.bill_account_name                                    bill_cust_name   , -- 顧客名
                     get_21account_rec.bill_base_code20                                     bill_base_code   , -- 担当拠点コード
                     xffvv.description                                                  location_name    , -- 担当拠点名
                     xxcfr_common_pkg.get_base_target_tel_num(xxca.invoice_code)    phone_num        , -- 電話番号
                     SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                     SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                     get_14account_rec.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                     get_14account_rec.cash_account_name                                payment_cust_name, -- 入金先顧客名
                     get_21account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                     TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END                                                                account_data     , -- 振込口座情報
                     xxca.invoice_code                                                 ship_cust_code   , -- 納品先顧客コード
                     hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                     NULL                                                               store_code         ,  -- 店舗コード
-- Modify 2011.03.10 Ver1.50 Start
--                    LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- 店舗コード(ソート用)
--                    all_account_rec.customer_code                                      ship_account_number,  -- 納品先顧客コード(ソート用)
                     NULL                                                               store_code_sort    ,  -- 店舗コード(ソート用)
                     NULL                                                               ship_account_number,  -- 納品先顧客コード(ソート用)
-- Modify 2011.03.10 Ver1.50 End
                     xxca.invoice_code                                                  invo_account_number,  -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                             cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                     xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                     SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                     SUM(xil.tax_amount)                                                tax_sum          , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                     xil.tax_rate                                                       tax_rate         , -- 消費税率
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     NVL(flvv.attribute1,' ')                                           description      , -- 摘要
                     flvv.attribute2                                                    category         , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END                                                                outsourcing_flag , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                     NULL                                                               data_empty_message,-- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                     xih.invoice_tax_div                                                invoice_tax_div  , -- 請求書消費税積上げ計算方式
                     SUM(xil.tax_amount_sum)                                            tax_amount_sum   , -- 税額合計１
                     SUM(xil.tax_amount_sum2)                                           tax_amount_sum2  , -- 税額合計２
                     SUM(xil.inv_amount_sum)                                            inv_amount_sum   , -- 税抜合計１
                     SUM(xil.inv_amount_sum2)                                           inv_amount_sum2  , -- 税抜合計２
                     gv_t_number                                                        invoice_t_no     , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                     cn_created_by                                                      created_by,             -- 作成者
                     cd_creation_date                                                   creation_date,          -- 作成日
                     cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                     cd_last_update_date                                                last_update_date,       -- 最終更新日
                     cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                     cn_request_id                                                      request_id,             -- 要求ID
                     cn_program_application_id                                          program_application_id, -- アプリケーションID
                     cn_program_id                                                      program_id,
                                                                                        -- コンカレント・プログラムID
                     cd_program_update_date                                             program_update_date     -- プログラム更新日
              FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                   xxcfr_invoice_lines            xil  , -- 請求明細
                   hz_cust_accounts               hzca , -- 顧客20顧客マスタ
                   hz_parties                     hzp  , -- 顧客20パーティマスタ
                   xxcmm_cust_accounts            xxca , -- 顧客10追加情報
                   (SELECT all_account_rec.customer_code ship_cust_code,
                           rcrm.customer_id             customer_id,
                           abb.bank_number              bank_number,
                           abb.bank_name                bank_name,
                           abb.bank_branch_name         bank_branch_name,
                           abaa.bank_account_type       bank_account_type,
                           abaa.bank_account_num        bank_account_num,
                           abaa.account_holder_name     account_holder_name,
                           abaa.account_holder_name_alt account_holder_name_alt
                    FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                         ar_receipt_method_accounts_all arma , --AR支払方法口座
                         ap_bank_accounts_all           abaa , --銀行口座
                         ap_bank_branches               abb    --銀行支店
                    WHERE rcrm.primary_flag = cv_enabled_yes
                      AND get_14account_rec.cash_account_id = rcrm.customer_id
                      AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                      AND rcrm.site_use_id IS NOT NULL
                      AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND arma.bank_account_id = abaa.bank_account_id(+)
                      AND abaa.bank_branch_id = abb.bank_branch_id(+)
                      AND arma.org_id = gn_org_id
                      AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = cv_ffv_set_name_dept
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                  ,fnd_lookup_values_vl           flvv   -- 参照表
-- Add 2019.09.03 Ver1.93 End
              WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
                AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
                AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND get_21account_rec.bill_base_code20 = xffvv.flex_value
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND xxca.customer_id = all_account_rec.customer_id
                AND hzca.account_number = xxca.invoice_code
                AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
                AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
                AND xil.tax_code         = flvv.lookup_code(+)
                AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
              GROUP BY cv_pkg_name,
                       xih.inv_creation_date,
                       DECODE(get_21account_rec.bill_postal_code,
                                   NULL,NULL,
                                   lv_format_zip_mark||SUBSTR(get_21account_rec.bill_postal_code,1,3)||'-'||
                                   SUBSTR(get_21account_rec.bill_postal_code,4,4)),
                       get_21account_rec.bill_state||get_21account_rec.bill_city,
                       get_21account_rec.bill_address1,
                       get_21account_rec.bill_address2,
                       get_21account_rec.bill_account_number,
                       get_21account_rec.bill_account_name,
                       xffvv.description,
                       xih.object_month,
                       get_14account_rec.cash_account_number,
                       get_14account_rec.cash_account_name,
                       get_21account_rec.bill_account_number||' '||xih.term_name,
                       xih.payment_date,
                       CASE
                       WHEN account.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(account.bank_number,1,1),
                         lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                         CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                           CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                             account.bank_name
                           ELSE
                             account.bank_name ||lv_format_date_bank
                           END
                         ELSE
                          account.bank_name 
                         END||' '||                                                       -- 銀行名
                         CASE WHEN INSTR(account.bank_branch_name
                                        ,lv_format_date_central)>0 THEN
                           account.bank_branch_name
                         ELSE
                           account.bank_branch_name||lv_format_date_branch 
                         END||' '||                                                       -- 支店名
                         DECODE( account.bank_account_type,
                                 1,lv_format_date_account,
                                 2,lv_format_date_current,
                                 account.bank_account_type) ||' '||                       -- 口座種別
                         account.bank_account_num ||' '||                                 -- 口座番号
                         account.account_holder_name||' '||                               -- 口座名義人
                         account.account_holder_name_alt)                                 -- 口座名義人カナ名
                       END,
                       xxca.invoice_code,
                       hzp.party_name,
                       TO_CHAR(DECODE(xil.acceptance_date,
                                      NULL,xil.delivery_date,
                                      xil.acceptance_date),
                       cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                       xil.slip_num;
                       xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                       xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                       xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                       flvv.attribute1,
                       flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                       CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                         cv_os_flag_y
                       ELSE
                         NULL
-- Modify 2023.07.04 Ver1.95 Start
--                     END
                     END,
                     xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
-- Modify 2014.03.27 Ver1.70 End
                       ;
-- Modify 2013.12.13 Ver1.60 End
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            ELSE
              NULL;
            END IF;
--
            CLOSE get_21account_cur;
--
          --請求書印刷単位 = 'A5'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a5)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (all_account_rec.bill_base_code = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- 消費税区分 IN (内税(伝票),内税(単価))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.30 End
          THEN
            INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
              report_id               , -- 帳票ＩＤ
              issue_date              , -- 発行日
              zip_code                , -- 郵便番号
              send_address1           , -- 住所１
              send_address2           , -- 住所２
              send_address3           , -- 住所３
              bill_cust_code          , -- 顧客コード(ソート順２)
              bill_cust_name          , -- 顧客名
              location_code           , -- 担当拠点コード
              location_name           , -- 担当拠点名
              phone_num               , -- 電話番号
              target_date             , -- 対象年月
              payment_cust_code       , -- 入金先顧客コード
              payment_cust_name       , -- 入金先顧客名
              ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
              payment_due_date        , -- 入金予定日
              bank_account            , -- 振込口座情報
              ship_cust_code          , -- ★納品先顧客コード
              ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
              store_code              , -- 店舗コード
              store_code_sort         , -- 店舗コード(ソート用)
              ship_account_number     , -- 納品先顧客コード(ソート用)
              invo_account_number     , -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
              slip_date               , -- 伝票日付(ソート順３)
              slip_num                , -- 伝票No(ソート順４)
              slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
              slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--              tax_rate                , -- 消費税率(編集用)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- 摘要
              category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
              outsourcing_flag        , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
              data_empty_message      , -- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
              invoice_tax_div         , -- 請求書消費税積上げ計算方式
              tax_amount_sum          , -- 税額合計１
              tax_amount_sum2         , -- 税額合計２
              inv_amount_sum          , -- 税抜合計１
              inv_amount_sum2         , -- 税抜合計２
              invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
              created_by              , -- 作成者
              creation_date           , -- 作成日
              last_updated_by         , -- 最終更新者
              last_update_date        , -- 最終更新日
              last_update_login       , -- 最終更新ログイン
              request_id              , -- 要求ID
              program_application_id  , -- アプリケーションID
              program_id              , -- コンカレント・プログラムID
              program_update_date     ) -- プログラム更新日
            SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                   get_14account_rec.bill_state||get_14account_rec.bill_city                  send_address1    , -- 住所１
                   get_14account_rec.bill_address1                                        send_address2    , -- 住所２
                   get_14account_rec.bill_address2                                        send_address3    , -- 住所３
                   get_14account_rec.cash_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                   get_14account_rec.cash_account_name                                    bill_cust_name   , -- 顧客名
                   all_account_rec.bill_base_code                                         bill_base_code   , -- 担当拠点コード
                   xffvv.description                                                  location_name    , -- 担当拠点名
                   xxcfr_common_pkg.get_base_target_tel_num(xil.ship_cust_code)  phone_num             , -- 電話番号
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                   get_14account_rec.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                   get_14account_rec.cash_account_name                                payment_cust_name, -- 入金先顧客名
                   get_14account_rec.cash_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END                                                                account_data     , -- 振込口座情報
                   xil.ship_cust_code                                                 ship_cust_code   , -- 納品先顧客コード
                   hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code         ,  -- 店舗コード
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- 店舗コード(ソート用)
                   xil.ship_cust_code                                                 ship_account_number,  -- 納品先顧客コード(ソート用)
                   NULL                                                               invo_account_number,  -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                   xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                   SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                   SUM(xil.tax_amount)                                                tax_sum          , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                   xil.tax_rate                                                       tax_rate         , -- 消費税率
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                            description      , -- 摘要
                   flvv.attribute2                                                    category         , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                outsourcing_flag , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                   NULL                                                               data_empty_message,-- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                   xih.invoice_tax_div                                                invoice_tax_div  , -- 請求書消費税積上げ計算方式
                   SUM(xil.tax_amount_sum)                                            tax_amount_sum   , -- 税額合計１
                   SUM(xil.tax_amount_sum2)                                           tax_amount_sum2  , -- 税額合計２
                   SUM(xil.inv_amount_sum)                                            inv_amount_sum   , -- 税抜合計１
                   SUM(xil.inv_amount_sum2)                                           inv_amount_sum2  , -- 税抜合計２
                   gv_t_number                                                        invoice_t_no     , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                   cn_created_by                                                      created_by,             -- 作成者
                   cd_creation_date                                                   creation_date,          -- 作成日
                   cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                   cd_last_update_date                                                last_update_date,       -- 最終更新日
                   cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                   cn_request_id                                                      request_id,             -- 要求ID
                   cn_program_application_id                                          program_application_id, -- アプリケーションID
                   cn_program_id                                                      program_id,
                                                                                      -- コンカレント・プログラムID
                   cd_program_update_date                                             program_update_date     -- プログラム更新日
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                       ar_receipt_method_accounts_all arma , --AR支払方法口座
                       ap_bank_accounts_all           abaa , --銀行口座
                       ap_bank_branches               abb    --銀行支店
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                 (SELECT flex_value,
                         description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets
                          WHERE   flex_value_set_name = cv_ffv_set_name_dept
                          AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
              AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
              AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND all_account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                     xil.slip_num;
                     xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                     xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
-- Modify 2023.07.04 Ver1.95 Start
--                     END
                     END,
                     xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
-- Modify 2014.03.27 Ver1.70 End
                     ;
-- Modify 2013.12.13 Ver1.60 End
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          --請求書印刷単位 = 'A6'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a6)
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))  -- 消費税区分 IN (内税(伝票),内税(単価))
-- Modify 2014.03.27 Ver1.70 Start
--           AND  (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type) -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
-- Modify 2014.03.27 Ver1.70 End
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.30 Start
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.30 End
          THEN
            OPEN get_20account_cur(all_account_rec.customer_id);
            FETCH get_20account_cur INTO get_20account_rec;
            --顧客区分20の顧客が存在しない場合
            IF get_20account_cur%NOTFOUND THEN
              -- 全社出力権限部門の場合と、該当顧客の請求拠点がログインユーザの所属部門と一致する場合
              IF (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
              THEN
                -- 顧客区分20存在なしメッセージ出力
                put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                   ,iv_customer_code       => all_account_rec.customer_code
                                   ,ov_errbuf              => lv_errbuf
                                   ,ov_retcode             => lv_retcode
                                   ,ov_errmsg              => lv_errmsg);
                IF (lv_retcode = cv_status_error) THEN
                  --(エラー処理)
                  RAISE global_process_expt;
                END IF;
              END IF;
            ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                  ((gv_inv_all_flag = cv_status_no) AND  (all_account_rec.bill_base_code = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
            THEN
              INSERT INTO xxcfr_rep_st_invoice_inc_tax_d(
                report_id               , -- 帳票ＩＤ
                issue_date              , -- 発行日
                zip_code                , -- 郵便番号
                send_address1           , -- 住所１
                send_address2           , -- 住所２
                send_address3           , -- 住所３
                bill_cust_code          , -- 顧客コード(ソート順２)
                bill_cust_name          , -- 顧客名
                location_code           , -- 担当拠点コード
                location_name           , -- 担当拠点名
                phone_num               , -- 電話番号
                target_date             , -- 対象年月
                payment_cust_code       , -- 入金先顧客コード
                payment_cust_name       , -- 入金先顧客名
                ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
                payment_due_date        , -- 入金予定日
                bank_account            , -- 振込口座情報
                ship_cust_code          , -- ★納品先顧客コード
                ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                store_code              , -- 店舗コード
                store_code_sort         , -- 店舗コード(ソート用)
                ship_account_number     , -- 納品先顧客コード(ソート用)
                invo_account_number     , -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                slip_date               , -- 伝票日付(ソート順３)
                slip_num                , -- 伝票No(ソート順４)
                slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
                slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                tax_rate                , -- 消費税率(編集用)
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                description             , -- 摘要
                category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                outsourcing_flag        , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                data_empty_message      , -- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                invoice_tax_div         , -- 請求書消費税積上げ計算方式
                tax_amount_sum          , -- 税額合計１
                tax_amount_sum2         , -- 税額合計２
                inv_amount_sum          , -- 税抜合計１
                inv_amount_sum2         , -- 税抜合計２
                invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                created_by              , -- 作成者
                creation_date           , -- 作成日
                last_updated_by         , -- 最終更新者
                last_update_date        , -- 最終更新日
                last_update_login       , -- 最終更新ログイン
                request_id              , -- 要求ID
                program_application_id  , -- アプリケーションID
                program_id              , -- コンカレント・プログラムID
                program_update_date     ) -- プログラム更新日
              SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                     TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                     DECODE(get_20account_rec.bill_postal_code,
                            NULL,NULL,
                            lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                            SUBSTR(get_20account_rec.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                     get_20account_rec.bill_state||get_20account_rec.bill_city                  send_address1    , -- 住所１
                     get_20account_rec.bill_address1                                        send_address2    , -- 住所２
                     get_20account_rec.bill_address2                                        send_address3    , -- 住所３
                     get_20account_rec.bill_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                     get_20account_rec.bill_account_name                                    bill_cust_name   , -- 顧客名
                     all_account_rec.bill_base_code                                         bill_base_code   , -- 担当拠点コード
                     xffvv.description                                                  location_name    , -- 担当拠点名
                     xxcfr_common_pkg.get_base_target_tel_num(xil.ship_cust_code)   phone_num        , -- 電話番号
                     SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                     SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                     get_14account_rec.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                     get_14account_rec.cash_account_name                                payment_cust_name, -- 入金先顧客名
                     get_20account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                     TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END                                                                account_data     , -- 振込口座情報
                     xil.ship_cust_code                                                 ship_cust_code   , -- 納品先顧客コード
                     hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.40 Start
                     LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code         ,  -- 店舗コード
                     LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code_sort    ,  -- 店舗コード(ソート用)
                     xil.ship_cust_code                                                 ship_account_number,  -- 納品先顧客コード(ソート用)
                     NULL                                                               invo_account_number,  -- 請求用顧客コード(ソート用)
-- Add 2011.01.17 Ver1.40 End
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                             cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                     xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                     SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                     SUM(xil.tax_amount)                                                tax_sum          , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
-- Add 2013.12.13 Ver1.60 Start
--                     xil.tax_rate                                                       tax_rate         , -- 消費税率
-- Add 2013.12.13 Ver1.60 End
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     NVL(flvv.attribute1,' ')                                           description      , -- 摘要
                     flvv.attribute2                                                    category         , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
-- Add 2014.03.27 Ver1.70 Start
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END                                                                outsourcing_flag , -- 業者委託フラグ
-- Add 2014.03.27 Ver1.70 End
                     NULL                                                               data_empty_message,-- 0件メッセージ
-- Add 2023.07.04 Ver1.95 Start
                     xih.invoice_tax_div                                                invoice_tax_div  , -- 請求書消費税積上げ計算方式
                     SUM(xil.tax_amount_sum)                                            tax_amount_sum   , -- 税額合計１
                     SUM(xil.tax_amount_sum2)                                           tax_amount_sum2  , -- 税額合計２
                     SUM(xil.inv_amount_sum)                                            inv_amount_sum   , -- 税抜合計１
                     SUM(xil.inv_amount_sum2)                                           inv_amount_sum2  , -- 税抜合計２
                     gv_t_number                                                        invoice_t_no     , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                     cn_created_by                                                      created_by,             -- 作成者
                     cd_creation_date                                                   creation_date,          -- 作成日
                     cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                     cd_last_update_date                                                last_update_date,       -- 最終更新日
                     cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                     cn_request_id                                                      request_id,             -- 要求ID
                     cn_program_application_id                                          program_application_id, -- アプリケーションID
                     cn_program_id                                                      program_id,
                                                                                        -- コンカレント・プログラムID
                     cd_program_update_date                                             program_update_date     -- プログラム更新日
              FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                   xxcfr_invoice_lines            xil  , -- 請求明細
                   hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                   hz_parties                     hzp  , -- 顧客10パーティマスタ
                   (SELECT all_account_rec.customer_code ship_cust_code,
                           rcrm.customer_id             customer_id,
                           abb.bank_number              bank_number,
                           abb.bank_name                bank_name,
                           abb.bank_branch_name         bank_branch_name,
                           abaa.bank_account_type       bank_account_type,
                           abaa.bank_account_num        bank_account_num,
                           abaa.account_holder_name     account_holder_name,
                           abaa.account_holder_name_alt account_holder_name_alt
                    FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                         ar_receipt_method_accounts_all arma , --AR支払方法口座
                         ap_bank_accounts_all           abaa , --銀行口座
                         ap_bank_branches               abb    --銀行支店
                    WHERE rcrm.primary_flag = cv_enabled_yes
                      AND get_14account_rec.cash_account_id = rcrm.customer_id
                      AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                      AND rcrm.site_use_id IS NOT NULL
                      AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND arma.bank_account_id = abaa.bank_account_id(+)
                      AND abaa.bank_branch_id = abb.bank_branch_id(+)
                      AND arma.org_id = gn_org_id
                      AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = cv_ffv_set_name_dept
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                  ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
              WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
                AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
                AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND all_account_rec.bill_base_code = xffvv.flex_value
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND hzca.cust_account_id = all_account_rec.customer_id
                AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
                AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
                AND xil.tax_code         = flvv.lookup_code(+)
                AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
              GROUP BY cv_pkg_name,
                       xih.inv_creation_date,
                       DECODE(get_20account_rec.bill_postal_code,
                                   NULL,NULL,
                                   lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                                   SUBSTR(get_20account_rec.bill_postal_code,4,4)),
                       get_20account_rec.bill_state||get_20account_rec.bill_city,
                       get_20account_rec.bill_address1,
                       get_20account_rec.bill_address2,
                       get_20account_rec.bill_account_number,
                       get_20account_rec.bill_account_name,
                       xffvv.description,
                       xih.object_month,
                       get_14account_rec.cash_account_number,
                       get_14account_rec.cash_account_name,
                       get_20account_rec.bill_account_number||' '||xih.term_name,
                       xih.payment_date,
                       CASE
                       WHEN account.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(account.bank_number,1,1),
                         lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                         CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                           CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                             account.bank_name
                           ELSE
                             account.bank_name ||lv_format_date_bank
                           END
                         ELSE
                          account.bank_name 
                         END||' '||                                                       -- 銀行名
                         CASE WHEN INSTR(account.bank_branch_name
                                        ,lv_format_date_central)>0 THEN
                           account.bank_branch_name
                         ELSE
                           account.bank_branch_name||lv_format_date_branch 
                         END||' '||                                                       -- 支店名
                         DECODE( account.bank_account_type,
                                 1,lv_format_date_account,
                                 2,lv_format_date_current,
                                 account.bank_account_type) ||' '||                       -- 口座種別
                         account.bank_account_num ||' '||                                 -- 口座番号
                         account.account_holder_name||' '||                               -- 口座名義人
                         account.account_holder_name_alt)                                 -- 口座名義人カナ名
                       END,
                       xil.ship_cust_code,
                       hzp.party_name,
                       TO_CHAR(DECODE(xil.acceptance_date,
                                      NULL,xil.delivery_date,
                                      xil.acceptance_date),
                       cv_format_date_ymds2),
-- Modify 2013.12.13 Ver1.60 Start
--                       xil.slip_num;
                       xil.slip_num,
-- Modify 2014.03.27 Ver1.70 Start
--                       xil.tax_rate
-- Del 2019.09.03 Ver1.93 Start
--                       xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                       flvv.attribute1,
                       flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                       CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                         cv_os_flag_y
                       ELSE
                         NULL
-- Modify 2023.07.04 Ver1.95 Start
--                     END
                     END,
                     xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
-- Modify 2014.03.27 Ver1.70 End
                       ;
-- Modify 2013.12.13 Ver1.60 End
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            ELSE
              NULL;
            END IF;
--
            CLOSE get_20account_cur;
--
-- Add 2015.07.31 Ver1.80 Start
          --請求書印刷単位 = 'A7'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a7)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))   -- 請求拠点 = ログインユーザの拠点
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))               -- 消費税区分 IN (内税(伝票),内税(単価))
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type)                                  -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes)                                             -- 一括請求書式 = 'Y'(有効)
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
          THEN
            BEGIN
            -- 印刷単位：Aの顧客あり
            gv_target_a_flag := cv_taget_flag_1;
--
            INSERT INTO xxcfr_rep_st_inv_inc_tax_a_l(
              report_id               , -- 帳票ＩＤ
              issue_date              , -- 発行日付
              zip_code                , -- 郵便番号
              send_address1           , -- 住所１
              send_address2           , -- 住所２
              send_address3           , -- 住所３
              bill_cust_code          , -- 顧客コード(ソート順２)
              bill_cust_name          , -- 顧客名
              location_code           , -- 担当拠点コード
              location_name           , -- 担当拠点名
              phone_num               , -- 電話番号
              target_date             , -- 対象年月
              payment_cust_code       , -- 売掛管理コード
              payment_cust_name       , -- 売掛管理顧客名
              ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
              payment_due_date        , -- 入金予定日
              bank_account            , -- 振込口座情報
              ship_cust_code          , -- 納品先顧客コード
              ship_cust_name          , -- 納品先顧客名
              store_code              , -- 店舗コード
              store_code_sort         , -- 店舗コード(ソート用)
              ship_account_number     , -- 納品先顧客コード(ソート用)
              slip_date               , -- 伝票日付(ソート順３)
              slip_num                , -- 伝票No(ソート順４)
              slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
              slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
--              tax_rate                , -- 消費税率(編集用)
-- Del 2019.09.03 Ver1.93 Start
-- Add 2019.09.03 Ver1.93 Start
              description             , -- 摘要
              category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
              outsourcing_flag        , -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
              invoice_tax_div         , -- 請求書消費税積上げ計算方式
              tax_amount_sum          , -- 税額合計１
              tax_amount_sum2         , -- 税額合計２
              inv_amount_sum          , -- 税抜合計１
              inv_amount_sum2         , -- 税抜合計２
              invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
              created_by              , -- 作成者
              creation_date           , -- 作成日
              last_updated_by         , -- 最終更新者
              last_update_date        , -- 最終更新日
              last_update_login       , -- 最終更新ログイン
              request_id              , -- 要求ID
              program_application_id  , -- アプリケーションID
              program_id              , -- コンカレント・プログラムID
              program_update_date     ) -- プログラム更新日
            SELECT cv_report_id_02                                                        report_id             , -- 帳票ＩＤ
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)                   issue_date            , -- 発行日
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code              , -- 郵便番号
                   get_14account_rec.bill_state||get_14account_rec.bill_city              send_address1         , -- 住所１
                   get_14account_rec.bill_address1                                        send_address2         , -- 住所２
                   get_14account_rec.bill_address2                                        send_address3         , -- 住所３
                   get_14account_rec.cash_account_number                                  bill_cust_code        , -- 顧客コード(ソート順２)
                   get_14account_rec.cash_account_name                                    bill_cust_name        , -- 顧客名
                   get_14account_rec.bill_base_code                                       bill_base_code        , -- 担当拠点コード
                   xffvv.description                                                      location_name         , -- 担当拠点名
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num   , -- 電話番号
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                     target_date           , -- 対象年月
                   get_14account_rec.cash_account_number                                  payment_cust_code     , -- 入金先顧客コード
                   get_14account_rec.cash_account_name                                    payment_cust_name     , -- 入金先顧客名
                   get_14account_rec.cash_account_number||' '||xih.term_name              ar_concat_text        , -- 売掛管理コード連結文字列
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                       payment_due_date      , -- 入金予定日
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END                                                                    account_data          , -- 振込口座情報
                   xil.ship_cust_code                                                     ship_cust_code        , -- 納品先顧客コード
                   hzp.party_name                                                         ship_cust_name        , -- 納品先顧客名
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code            , -- 店舗コード
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code_sort       , -- 店舗コード(ソート用)
                   xil.ship_cust_code                                                     ship_account_number   , -- 納品先顧客コード(ソート用)
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                          slip_date             , -- 伝票日付(ソート順３)
                   xil.slip_num                                                           slip_num              , -- 伝票No(ソート順４)
                   SUM(xil.ship_amount)                                                   slip_sum              , -- 伝票金額(税抜額)
                   SUM(xil.tax_amount)                                                    tax_sum               , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
--                   xil.tax_rate                                                           tax_rate              , -- 消費税率
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                               description      , -- 摘要
                   flvv.attribute2                                                        category         , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                    outsourcing_flag      , -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
                   xih.invoice_tax_div                                                    invoice_tax_div  , -- 請求書消費税積上げ計算方式
                   SUM(xil.tax_amount_sum)                                                tax_amount_sum   , -- 税額合計１
                   SUM(xil.tax_amount_sum2)                                               tax_amount_sum2  , -- 税額合計２
                   SUM(xil.inv_amount_sum)                                                inv_amount_sum   , -- 税抜合計１
                   SUM(xil.inv_amount_sum2)                                               inv_amount_sum2  , -- 税抜合計２
                   gv_t_number                                                            invoice_t_no     , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                   cn_created_by                                                          created_by            , -- 作成者
                   cd_creation_date                                                       creation_date         , -- 作成日
                   cn_last_updated_by                                                     last_updated_by       , -- 最終更新者
                   cd_last_update_date                                                    last_update_date      , -- 最終更新日
                   cn_last_update_login                                                   last_update_login     , -- 最終更新ログイン
                   cn_request_id                                                          request_id            , -- 要求ID
                   cn_program_application_id                                              program_application_id, -- アプリケーションID
                   cn_program_id                                                          program_id            , -- コンカレント・プログラムID
                   cd_program_update_date                                                 program_update_date     -- プログラム更新日
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                       ar_receipt_method_accounts_all arma , --AR支払方法口座
                       ap_bank_accounts_all           abaa , --銀行口座
                       ap_bank_branches               abb    --銀行支店
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                 (SELECT ffv.flex_value   flex_value,
                         ffv.description  description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets ffvs
                          WHERE   ffvs.flex_value_set_name = cv_ffv_set_name_dept
                          AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                                       -- 一括請求書ID
              AND xil.cutoff_date = gd_target_date                                      -- パラメータ．締日
              AND xil.ship_cust_code = account.ship_cust_code(+)                        -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num,
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
-- Modify 2023.07.04 Ver1.95 Start
--                       END                                                                -- 業者委託フラグ
                       END,                                                                -- 業者委託フラグ
                       xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
                       ;
--
            EXCEPTION
              WHEN OTHERS THEN  -- 登録時エラー
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                               ,cv_msg_003a18_013    -- テーブル登録エラー
                                                               ,cv_tkn_table         -- トークン'TABLE'
                                                               ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                              -- 標準請求書税込帳票内訳印刷単位Aワークテーブル明細
                                     ,1
                                     ,5000);
                lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
                RAISE global_api_expt;
            END;
--
            gn_target_cnt_a_l := gn_target_cnt_a_l + SQL%ROWCOUNT;
--
          --請求書印刷単位 = 'A8'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a8)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))   -- 請求拠点 = ログインユーザの拠点
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))               -- 消費税区分 IN (内税(伝票),内税(単価))
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type)                                  -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes)                                            -- 一括請求書式 = 'Y'(有効)
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
          THEN
            BEGIN
            -- 印刷単位：Bの顧客あり
            gv_target_b_flag := cv_taget_flag_1;
--
            INSERT INTO xxcfr_rep_st_inv_inc_tax_b_l(
              report_id               , -- 帳票ＩＤ
              issue_date              , -- 発行日付
              zip_code                , -- 郵便番号
              send_address1           , -- 住所１
              send_address2           , -- 住所２
              send_address3           , -- 住所３
              bill_cust_code          , -- 顧客コード(ソート順２)
              bill_cust_name          , -- 顧客名
              location_code           , -- 担当拠点コード
              location_name           , -- 担当拠点名
              phone_num               , -- 電話番号
              target_date             , -- 対象年月
              payment_cust_code       , -- 売掛管理顧客コード
              payment_cust_name       , -- 売掛管理顧客名
              ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
              payment_due_date        , -- 入金予定日
              bank_account            , -- 振込口座情報
              ship_cust_code          , -- 納品先顧客コード
              ship_cust_name          , -- 納品先顧客名
              store_code              , -- 店舗コード
              store_code_sort         , -- 店舗コード(ソート用)
              ship_account_number     , -- 納品先顧客コード(ソート用)
              slip_date               , -- 伝票日付(ソート順３)
              slip_num                , -- 伝票No(ソート順４)
              slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
              slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
--              tax_rate                , -- 消費税率(編集用)
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- 摘要
              category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
              outsourcing_flag        , -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
              invoice_tax_div         , -- 請求書消費税積上げ計算方式
              tax_amount_sum          , -- 税額合計１
              tax_amount_sum2         , -- 税額合計２
              inv_amount_sum          , -- 税抜合計１
              inv_amount_sum2         , -- 税抜合計２
              invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
              created_by              , -- 作成者
              creation_date           , -- 作成日
              last_updated_by         , -- 最終更新者
              last_update_date        , -- 最終更新日
              last_update_login       , -- 最終更新ログイン
              request_id              , -- 要求ID
              program_application_id  , -- アプリケーションID
              program_id              , -- コンカレント・プログラムID
              program_update_date     ) -- プログラム更新日
            SELECT cv_report_id_04                                                        report_id             , -- 帳票ＩＤ
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)                   issue_date            , -- 発行日
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code              , -- 郵便番号
                   get_14account_rec.bill_state||get_14account_rec.bill_city              send_address1         , -- 住所１
                   get_14account_rec.bill_address1                                        send_address2         , -- 住所２
                   get_14account_rec.bill_address2                                        send_address3         , -- 住所３
                   get_14account_rec.cash_account_number                                  bill_cust_code        , -- 顧客コード(ソート順２)
                   get_14account_rec.cash_account_name                                    bill_cust_name        , -- 顧客名
                   get_14account_rec.bill_base_code                                       bill_base_code        , -- 担当拠点コード
                   xffvv.description                                                      location_name         , -- 担当拠点名
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num   , -- 電話番号
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                     target_date           , -- 対象年月
                   get_14account_rec.cash_account_number                                  payment_cust_code     , -- 入金先顧客コード
                   get_14account_rec.cash_account_name                                    payment_cust_name     , -- 入金先顧客名
                   get_14account_rec.cash_account_number||' '||xih.term_name              ar_concat_text        , -- 売掛管理コード連結文字列
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                       payment_due_date      , -- 入金予定日
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END                                                                    account_data          , -- 振込口座情報
                   xil.ship_cust_code                                                     ship_cust_code        , -- 納品先顧客コード
                   hzp.party_name                                                         ship_cust_name        , -- 納品先顧客名
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code            , -- 店舗コード
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code_sort       , -- 店舗コード(ソート用)
                   xil.ship_cust_code                                                     ship_account_number   , -- 納品先顧客コード(ソート用)
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                          slip_date             , -- 伝票日付(ソート順３)
                   xil.slip_num                                                           slip_num              , -- 伝票No(ソート順４)
                   SUM(xil.ship_amount)                                                   slip_sum              , -- 伝票金額(税抜額)
                   SUM(xil.tax_amount)                                                    tax_sum               , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
--                   xil.tax_rate                                                           tax_rate              , -- 消費税率
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                              description           , -- 摘要
                   flvv.attribute2                                                        category              , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                    outsourcing_flag      , -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
                   xih.invoice_tax_div                                                    invoice_tax_div       , -- 請求書消費税積上げ計算方式
                   SUM(xil.tax_amount_sum)                                                tax_amount_sum        , -- 税額合計１
                   SUM(xil.tax_amount_sum2)                                               tax_amount_sum2       , -- 税額合計２
                   SUM(xil.inv_amount_sum)                                                inv_amount_sum        , -- 税抜合計１
                   SUM(xil.inv_amount_sum2)                                               inv_amount_sum2       , -- 税抜合計２
                   gv_t_number                                                            invoice_t_no          , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                   cn_created_by                                                          created_by            , -- 作成者
                   cd_creation_date                                                       creation_date         , -- 作成日
                   cn_last_updated_by                                                     last_updated_by       , -- 最終更新者
                   cd_last_update_date                                                    last_update_date      , -- 最終更新日
                   cn_last_update_login                                                   last_update_login     , -- 最終更新ログイン
                   cn_request_id                                                          request_id            , -- 要求ID
                   cn_program_application_id                                              program_application_id, -- アプリケーションID
                   cn_program_id                                                          program_id            , -- コンカレント・プログラムID
                   cd_program_update_date                                                 program_update_date     -- プログラム更新日
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                       ar_receipt_method_accounts_all arma , --AR支払方法口座
                       ap_bank_accounts_all           abaa , --銀行口座
                       ap_bank_branches               abb    --銀行支店
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                 (SELECT ffv.flex_value   flex_value,
                         ffv.description  description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets ffvs
                          WHERE   ffvs.flex_value_set_name = cv_ffv_set_name_dept
                          AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                                       -- 一括請求書ID
              AND xil.cutoff_date = gd_target_date                                      -- パラメータ．締日
              AND xil.ship_cust_code = account.ship_cust_code(+)                        -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num,
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
-- Modify 2023.07.04 Ver1.95 Start
--                       END                                                                -- 業者委託フラグ
                       END,                                                                -- 業者委託フラグ
                       xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
                       ;
--
            EXCEPTION
              WHEN OTHERS THEN  -- 登録時エラー
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                               ,cv_msg_003a18_013    -- テーブル登録エラー
                                                               ,cv_tkn_table         -- トークン'TABLE'
                                                               ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                              -- 標準請求書税込帳票内訳印刷単位Bワークテーブル明細
                                     ,1
                                     ,5000);
                lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
                RAISE global_api_expt;
            END;
--
            gn_target_cnt_b_l := gn_target_cnt_b_l + SQL%ROWCOUNT;
--
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
          --請求書印刷単位 = 'A9'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a9)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))   -- 請求拠点 = ログインユーザの拠点
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))               -- 消費税区分 IN (内税(伝票),内税(単価))
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type)                                  -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes)                                             -- 一括請求書式 = 'Y'(有効)
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
          THEN
            BEGIN
            -- 印刷単位：Cの顧客あり
            gv_target_c_flag := cv_taget_flag_1;
--
            INSERT INTO xxcfr_rep_st_inv_inc_tax_c_l(
              report_id               , -- 帳票ＩＤ
              issue_date              , -- 発行日付
              zip_code                , -- 郵便番号
              send_address1           , -- 住所１
              send_address2           , -- 住所２
              send_address3           , -- 住所３
              bill_cust_code          , -- 顧客コード(ソート順２)
              bill_cust_name          , -- 顧客名
              location_code           , -- 担当拠点コード
              location_name           , -- 担当拠点名
              phone_num               , -- 電話番号
              target_date             , -- 対象年月
              payment_cust_code       , -- 売掛管理コード
              payment_cust_name       , -- 売掛管理顧客名
              ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
              payment_due_date        , -- 入金予定日
              bank_account            , -- 振込口座情報
              ship_cust_code          , -- 納品先顧客コード
              ship_cust_name          , -- 納品先顧客名
              store_code              , -- 店舗コード
              store_code_sort         , -- 店舗コード(ソート用)
              ship_account_number     , -- 納品先顧客コード(ソート用)
              slip_date               , -- 伝票日付(ソート順３)
              slip_num                , -- 伝票No(ソート順４)
              slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
              slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
--              tax_rate                , -- 消費税率(編集用)
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- 摘要
              category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
              outsourcing_flag        , -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
              invoice_tax_div         , -- 請求書消費税積上げ計算方式
              tax_amount_sum          , -- 税額合計１
              tax_amount_sum2         , -- 税額合計２
              inv_amount_sum          , -- 税抜合計１
              inv_amount_sum2         , -- 税抜合計２
              invoice_t_no            , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
              created_by              , -- 作成者
              creation_date           , -- 作成日
              last_updated_by         , -- 最終更新者
              last_update_date        , -- 最終更新日
              last_update_login       , -- 最終更新ログイン
              request_id              , -- 要求ID
              program_application_id  , -- アプリケーションID
              program_id              , -- コンカレント・プログラムID
              program_update_date     ) -- プログラム更新日
            SELECT cv_report_id_10                                                        report_id             , -- 帳票ＩＤ
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)                   issue_date            , -- 発行日
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code              , -- 郵便番号
                   get_14account_rec.bill_state||get_14account_rec.bill_city              send_address1         , -- 住所１
                   get_14account_rec.bill_address1                                        send_address2         , -- 住所２
                   get_14account_rec.bill_address2                                        send_address3         , -- 住所３
                   get_14account_rec.cash_account_number                                  bill_cust_code        , -- 顧客コード(ソート順２)
                   get_14account_rec.cash_account_name                                    bill_cust_name        , -- 顧客名
                   get_14account_rec.bill_base_code                                       bill_base_code        , -- 担当拠点コード
                   xffvv.description                                                      location_name         , -- 担当拠点名
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num   , -- 電話番号
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                     target_date           , -- 対象年月
                   get_14account_rec.cash_account_number                                  payment_cust_code     , -- 入金先顧客コード
                   get_14account_rec.cash_account_name                                    payment_cust_name     , -- 入金先顧客名
                   get_14account_rec.cash_account_number||' '||xih.term_name              ar_concat_text        , -- 売掛管理コード連結文字列
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                       payment_due_date      , -- 入金予定日
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END                                                                    account_data          , -- 振込口座情報
                   xil.ship_cust_code                                                     ship_cust_code        , -- 納品先顧客コード
                   hzp.party_name                                                         ship_cust_name        , -- 納品先顧客名
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code            , -- 店舗コード
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code_sort       , -- 店舗コード(ソート用)
                   xil.ship_cust_code                                                     ship_account_number   , -- 納品先顧客コード(ソート用)
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                          slip_date             , -- 伝票日付(ソート順３)
                   xil.slip_num                                                           slip_num              , -- 伝票No(ソート順４)
                   SUM(xil.ship_amount)                                                   slip_sum              , -- 伝票金額(税抜額)
                   SUM(xil.tax_amount)                                                    tax_sum               , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
--                   xil.tax_rate                                                           tax_rate              , -- 消費税率
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                               description           , -- 摘要
                   flvv.attribute2                                                        category              , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                    outsourcing_flag      , -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
                   xih.invoice_tax_div                                                    invoice_tax_div       , -- 請求書消費税積上げ計算方式
                   SUM(xil.tax_amount_sum)                                                tax_amount_sum        , -- 税額合計１
                   SUM(xil.tax_amount_sum2)                                               tax_amount_sum2       , -- 税額合計２
                   SUM(xil.inv_amount_sum)                                                inv_amount_sum        , -- 税抜合計１
                   SUM(xil.inv_amount_sum2)                                               inv_amount_sum2       , -- 税抜合計２
                   gv_t_number                                                            invoice_t_no          , -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                   cn_created_by                                                          created_by            , -- 作成者
                   cd_creation_date                                                       creation_date         , -- 作成日
                   cn_last_updated_by                                                     last_updated_by       , -- 最終更新者
                   cd_last_update_date                                                    last_update_date      , -- 最終更新日
                   cn_last_update_login                                                   last_update_login     , -- 最終更新ログイン
                   cn_request_id                                                          request_id            , -- 要求ID
                   cn_program_application_id                                              program_application_id, -- アプリケーションID
                   cn_program_id                                                          program_id            , -- コンカレント・プログラムID
                   cd_program_update_date                                                 program_update_date     -- プログラム更新日
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                       ar_receipt_method_accounts_all arma , --AR支払方法口座
                       ap_bank_accounts_all           abaa , --銀行口座
                       ap_bank_branches               abb    --銀行支店
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                 (SELECT ffv.flex_value   flex_value,
                         ffv.description  description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets ffvs
                          WHERE   ffvs.flex_value_set_name = cv_ffv_set_name_dept
                          AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                                       -- 一括請求書ID
              AND xil.cutoff_date = gd_target_date                                      -- パラメータ．締日
              AND xil.ship_cust_code = account.ship_cust_code(+)                        -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num,
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
-- Modify 2023.07.04 Ver1.95 Start
--                       END                                                                -- 業者委託フラグ
                       END,                                                                -- 業者委託フラグ
                       xih.invoice_tax_div                                                -- 請求書消費税積上げ計算方式
-- Modify 2023.07.04 Ver1.95 End
                       ;
--
            EXCEPTION
              WHEN OTHERS THEN  -- 登録時エラー
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                               ,cv_msg_003a18_013    -- テーブル登録エラー
                                                               ,cv_tkn_table         -- トークン'TABLE'
                                                               ,xxcfr_common_pkg.get_table_comment(cv_table_c_l))
                                                              -- 標準請求書税込帳票内訳印刷単位Cワークテーブル明細
                                     ,1
                                     ,5000);
                lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
                RAISE global_api_expt;
            END;
--
            gn_target_cnt_c_l := gn_target_cnt_c_l + SQL%ROWCOUNT;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
          --請求書印刷単位 = 'A10'
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_a10)
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (get_14account_rec.bill_base_code = gt_user_dept)))   -- 請求拠点 = ログインユーザの拠点
           AND  (get_14account_rec.bill_tax_div IN (cv_syohizei_kbn_inc2,cv_syohizei_kbn_inc3))               -- 消費税区分 IN (内税(伝票),内税(単価))
           AND  (get_14account_rec.bill_invoice_type = iv_bill_invoice_type)                                  -- 請求書出力形式 = 入力パラメータ「請求書出力形式」
           AND  (get_14account_rec.cons_inv_flag = cv_enabled_yes)                                            -- 一括請求書式 = 'Y'(有効)
           AND  (get_14account_rec.bill_pub_cycle = NVL(iv_bill_pub_cycle, get_14account_rec.bill_pub_cycle)) -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
          THEN
--
            BEGIN
            -- 印刷単位：Dの顧客あり
            gv_target_d_flag := cv_taget_flag_1;
--
            INSERT INTO xxcfr_rep_st_inv_inc_tax_d_l(
              report_id               , -- 帳票ＩＤ
              issue_date              , -- 発行日付
              zip_code                , -- 郵便番号
              send_address1           , -- 住所１
              send_address2           , -- 住所２
              send_address3           , -- 住所３
              bill_cust_code          , -- 顧客コード(ソート順２)
              bill_cust_name          , -- 顧客名
              location_code           , -- 担当拠点コード
              location_name           , -- 担当拠点名
              phone_num               , -- 電話番号
              target_date             , -- 対象年月
              payment_cust_code       , -- 売掛管理顧客コード
              payment_cust_name       , -- 売掛管理顧客名
              ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
              payment_due_date        , -- 入金予定日
              bank_account            , -- 振込口座情報
              ship_cust_code          , -- 納品先顧客コード
              ship_cust_name          , -- 納品先顧客名
              store_code              , -- 店舗コード
              store_code_sort         , -- 店舗コード(ソート用)
              ship_account_number     , -- 納品先顧客コード(ソート用)
              slip_date               , -- 伝票日付(ソート順３)
              slip_num                , -- 伝票No(ソート順４)
              slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
              slip_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
-- Del 2019.09.03 Ver1.93 Start
--              tax_rate                , -- 消費税率(編集用)
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
              description             , -- 摘要
              category                , -- 内訳分類(編集用)
-- Add 2019.09.03 Ver1.93 End
              outsourcing_flag        , -- 業者委託フラグ
-- 2023/07/04 Ver1.95 ADD Start
              invoice_tax_div         , -- 請求書消費税積上げ計算方式
              tax_amount_sum          , -- 税額合計１
              tax_amount_sum2         , -- 税額合計２
              inv_amount_sum          , -- 税抜合計１
              inv_amount_sum2         , -- 税抜合計２
              invoice_t_no            , -- 適格請求書発行事業者登録番号
-- 2023/07/04 Ver1.95 ADD End
              created_by              , -- 作成者
              creation_date           , -- 作成日
              last_updated_by         , -- 最終更新者
              last_update_date        , -- 最終更新日
              last_update_login       , -- 最終更新ログイン
              request_id              , -- 要求ID
              program_application_id  , -- アプリケーションID
              program_id              , -- コンカレント・プログラムID
              program_update_date     ) -- プログラム更新日
            SELECT cv_report_id_14                                                        report_id             , -- 帳票ＩＤ
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)                   issue_date            , -- 発行日
                   DECODE(get_14account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_14account_rec.bill_postal_code,4,4))                 zip_code              , -- 郵便番号
                   get_14account_rec.bill_state||get_14account_rec.bill_city              send_address1         , -- 住所１
                   get_14account_rec.bill_address1                                        send_address2         , -- 住所２
                   get_14account_rec.bill_address2                                        send_address3         , -- 住所３
                   get_14account_rec.cash_account_number                                  bill_cust_code        , -- 顧客コード(ソート順２)
                   get_14account_rec.cash_account_name                                    bill_cust_name        , -- 顧客名
                   get_14account_rec.bill_base_code                                       bill_base_code        , -- 担当拠点コード
                   xffvv.description                                                      location_name         , -- 担当拠点名
                   xxcfr_common_pkg.get_base_target_tel_num(get_14account_rec.cash_account_number)  phone_num   , -- 電話番号
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                     target_date           , -- 対象年月
                   get_14account_rec.cash_account_number                                  payment_cust_code     , -- 入金先顧客コード
                   get_14account_rec.cash_account_name                                    payment_cust_name     , -- 入金先顧客名
                   get_14account_rec.cash_account_number||' '||xih.term_name              ar_concat_text        , -- 売掛管理コード連結文字列
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                       payment_due_date      , -- 入金予定日
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END                                                                    account_data          , -- 振込口座情報
                   xil.ship_cust_code                                                     ship_cust_code        , -- 納品先顧客コード
                   hzp.party_name                                                         ship_cust_name        , -- 納品先顧客名
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code            , -- 店舗コード
                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                       store_code_sort       , -- 店舗コード(ソート用)
                   xil.ship_cust_code                                                     ship_account_number   , -- 納品先顧客コード(ソート用)
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                          slip_date             , -- 伝票日付(ソート順３)
                   xil.slip_num                                                           slip_num              , -- 伝票No(ソート順４)
                   SUM(xil.ship_amount)                                                   slip_sum              , -- 伝票金額(税抜額)
                   SUM(xil.tax_amount)                                                    tax_sum               , -- 伝票税額
-- Del 2019.09.03 Ver1.93 Start
--                   xil.tax_rate                                                           tax_rate              , -- 消費税率
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                   NVL(flvv.attribute1,' ')                                               description           , -- 摘要
                   flvv.attribute2                                                        category              , -- 内部分類(編集用)
-- Add 2019.09.03 Ver1.93 End
                   CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                     cv_os_flag_y
                   ELSE
                     NULL
                   END                                                                    outsourcing_flag      , -- 業者委託フラグ
-- 2023/07/04 Ver1.95 ADD Start
                   xih.invoice_tax_div                                                    invoice_tax_div       , -- 請求書消費税積上げ計算方式
                   SUM(xil.tax_amount_sum)                                                tax_amount_sum        , -- 税額合計１
                   SUM(xil.tax_amount_sum2)                                               tax_amount_sum2       , -- 税額合計２
                   SUM(xil.inv_amount_sum)                                                inv_amount_sum        , -- 税抜合計１
                   SUM(xil.inv_amount_sum2)                                               inv_amount_sum2       , -- 税抜合計２
                   gv_t_number                                                            invoice_t_no          , -- 適格請求書発行事業者登録番号
-- 2023/07/04 Ver1.95 ADD End
                   cn_created_by                                                          created_by            , -- 作成者
                   cd_creation_date                                                       creation_date         , -- 作成日
                   cn_last_updated_by                                                     last_updated_by       , -- 最終更新者
                   cd_last_update_date                                                    last_update_date      , -- 最終更新日
                   cn_last_update_login                                                   last_update_login     , -- 最終更新ログイン
                   cn_request_id                                                          request_id            , -- 要求ID
                   cn_program_application_id                                              program_application_id, -- アプリケーションID
                   cn_program_id                                                          program_id            , -- コンカレント・プログラムID
                   cd_program_update_date                                                 program_update_date     -- プログラム更新日
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                       ar_receipt_method_accounts_all arma , --AR支払方法口座
                       ap_bank_accounts_all           abaa , --銀行口座
                       ap_bank_branches               abb    --銀行支店
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND get_14account_rec.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                 (SELECT ffv.flex_value   flex_value,
                         ffv.description  description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets ffvs
                          WHERE   ffvs.flex_value_set_name = cv_ffv_set_name_dept
                          AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id)) xffvv
-- Add 2019.09.03 Ver1.93 Start
                ,fnd_lookup_values_vl           flvv    -- 参照表
-- Add 2019.09.03 Ver1.93 End
            WHERE xih.invoice_id = xil.invoice_id                                       -- 一括請求書ID
              AND xil.cutoff_date = gd_target_date                                      -- パラメータ．締日
              AND xil.ship_cust_code = account.ship_cust_code(+)                        -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_14account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
-- Add 2019.09.03 Ver1.93 Start
              AND flvv.lookup_type(+)  = cv_xxcfr_tax_category
              AND xil.tax_code         = flvv.lookup_code(+)
              AND flvv.enabled_flag(+) = cv_enabled_yes
-- Add 2019.09.03 Ver1.93 End
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_14account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_14account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_14account_rec.bill_postal_code,4,4)),
                     get_14account_rec.bill_state||get_14account_rec.bill_city,
                     get_14account_rec.bill_address1,
                     get_14account_rec.bill_address2,
                     get_14account_rec.cash_account_number,
                     get_14account_rec.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     get_14account_rec.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num,
-- Del 2019.09.03 Ver1.93 Start
--                     xil.tax_rate,
-- Del 2019.09.03 Ver1.93 End
-- Add 2019.09.03 Ver1.93 Start
                     flvv.attribute1,
                     flvv.attribute2,
-- Add 2019.09.03 Ver1.93 End
                     CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
                       cv_os_flag_y
                     ELSE
                       NULL
                     END
-- 2023/07/04 Ver1.95 ADD Start
                    ,xih.invoice_tax_div
-- 2023/07/04 Ver1.95 ADD End
                     ;
--
            EXCEPTION
              WHEN OTHERS THEN  -- 登録時エラー
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                               ,cv_msg_003a18_013    -- テーブル登録エラー
                                                               ,cv_tkn_table         -- トークン'TABLE'
                                                               ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                              -- 標準請求書税込帳票内訳印刷単位Dワークテーブル明細
                                     ,1
                                     ,5000);
                lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
                RAISE global_api_expt;
            END;
--
            gn_target_cnt_d_l := gn_target_cnt_d_l + SQL%ROWCOUNT;
--
-- Ver.1.92 [障害E_本稼動_15307] ADD END
          ELSE
            NULL;
          END IF;
--
          CLOSE get_14account_cur;
--
        END IF;
      END LOOP get_account10_loop;
--
      -- 登録データが１件も存在しない場合、０件メッセージレコード追加
      IF ( gn_target_cnt = 0 ) THEN
--
        INSERT INTO xxcfr_rep_st_invoice_inc_tax_d (
          data_empty_message           , -- 0件メッセージ
-- Modify 2014.03.27 Ver1.70 Start
          outsourcing_flag             , -- 業者委託フラグ
-- Modify 2014.03.27 Ver1.70 End
          created_by                   , -- 作成者
          creation_date                , -- 作成日
          last_updated_by              , -- 最終更新者
          last_update_date             , -- 最終更新日
          last_update_login            , -- 最終更新ログイン
          request_id                   , -- 要求ID
          program_application_id       , -- コンカレント・プログラム・アプリケーションID
          program_id                   , -- コンカレント・プログラムID
          program_update_date          ) -- プログラム更新日
        VALUES (
          lv_no_data_msg               , -- 0件メッセージ
-- Modify 2014.03.27 Ver1.70 Start
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- 業者委託フラグ
-- Modify 2014.03.27 Ver1.70 End
          cn_created_by                , -- 作成者
          cd_creation_date             , -- 作成日
          cn_last_updated_by           , -- 最終更新者
          cd_last_update_date          , -- 最終更新日
          cn_last_update_login         , -- 最終更新ログイン
          cn_request_id                , -- 要求ID
          cn_program_application_id    , -- コンカレント・プログラム・アプリケーションID
          cn_program_id                , -- コンカレント・プログラムID
          cd_program_update_date       );-- プログラム更新日
--
        -- 警告終了
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_016 )  -- 対象データ0件警告
                             ,1
                             ,5000);
        ov_errmsg  := lv_errmsg;
--
        ov_retcode := cv_status_warn;
--
-- Add 2015.07.31 Ver1.80 Start
      END IF;
--
      -- 印刷単位A明細の対象件数が0以外の場合
      IF ( gn_target_cnt_a_l <> 0 ) THEN
        -- 明細0件フラグ（2：対象データあり）
        gv_target_a_flag := cv_taget_flag_2;
        -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダの登録
        INSERT INTO xxcfr_rep_st_inv_inc_tax_a_h(
           report_id                -- 帳票ID
          ,issue_date               -- 発行日付
          ,zip_code                 -- 郵便番号
          ,send_address1            -- 住所１
          ,send_address2            -- 住所２
          ,send_address3            -- 住所３
          ,bill_cust_code           -- 顧客コード
          ,bill_cust_name           -- 顧客名
          ,location_code            -- 担当拠点コード
          ,location_name            -- 担当拠点名
          ,phone_num                -- 電話番号
          ,target_date              -- 対象年月
          ,payment_cust_code        -- 売掛管理コード
          ,payment_cust_name        -- 売掛管理顧客名
          ,ar_concat_text           -- 売掛管理コード連結文字列
          ,payment_due_date         -- 入金予定日
          ,bank_account             -- 振込口座
          ,ship_cust_code           -- 納品先顧客コード
          ,ship_cust_name           -- 納品先顧客名
          ,store_code               -- 店舗コード
          ,store_code_sort          -- 店舗コード（ソート用）
          ,ship_account_number      -- 納品先顧客コード（ソート用）
          ,outsourcing_flag         -- 業者委託フラグ
          ,store_charge_sum         -- 店舗金額
          ,store_tax_sum            -- 店舗税額
-- Add 2023.07.04 Ver1.95 Start
          ,invoice_t_no             -- 登録番号
-- Add 2023.07.04 Ver1.95 End
          ,created_by               -- 作成者
          ,creation_date            -- 作成日
          ,last_updated_by          -- 最終更新者
          ,last_update_date         -- 最終更新日
          ,last_update_login        -- 最終更新ログイン
          ,request_id               -- 要求ID
          ,program_application_id   -- コンカレント・プログラム・アプリケーションID
          ,program_id               -- コンカレント・プログラムID
          ,program_update_date      -- プログラム更新日
        )
        SELECT cv_report_id_01             -- 帳票ID
              ,xrsal.issue_date            -- 発行日付
              ,xrsal.zip_code              -- 郵便番号
              ,xrsal.send_address1         -- 住所１
              ,xrsal.send_address2         -- 住所２
              ,xrsal.send_address3         -- 住所３
              ,xrsal.bill_cust_code        -- 顧客コード
              ,xrsal.bill_cust_name        -- 顧客名
              ,xrsal.location_code         -- 担当拠点コード
              ,xrsal.location_name         -- 担当拠点名
              ,xrsal.phone_num             -- 電話番号
              ,xrsal.target_date           -- 対象年月
              ,xrsal.payment_cust_code     -- 売掛管理コード
              ,xrsal.payment_cust_name     -- 売掛管理顧客名
              ,xrsal.ar_concat_text        -- 売掛管理コード連結文字列
              ,xrsal.payment_due_date      -- 入金予定日
              ,xrsal.bank_account          -- 振込口座
              ,xrsal.ship_cust_code        -- 納品先顧客コード
              ,xrsal.ship_cust_name        -- 納品先顧客名
              ,xrsal.store_code            -- 店舗コード
              ,xrsal.store_code_sort       -- 店舗コード（ソート用）
              ,xrsal.ship_account_number   -- 納品先顧客コード（ソート用）
              ,xrsal.outsourcing_flag      -- 業者委託フラグ
              ,SUM(xrsal.slip_sum)         -- 店舗金額
              ,SUM(xrsal.slip_tax_sum)     -- 店舗税額
-- Add 2023.07.04 Ver1.95 Start
              ,xrsal.invoice_t_no          -- 登録番号
-- Add 2023.07.04 Ver1.95 End
              ,cn_created_by               -- 作成者
              ,cd_creation_date            -- 作成日
              ,cn_last_updated_by          -- 最終更新者
              ,cd_last_update_date         -- 最終更新日
              ,cn_last_update_login        -- 最終更新ログイン
              ,cn_request_id               -- 要求ID
              ,cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
              ,cn_program_id               -- コンカレント・プログラムID
              ,cd_program_update_date      -- プログラム更新日
        FROM   xxcfr_rep_st_inv_inc_tax_a_l  xrsal
        WHERE  xrsal.request_id = cn_request_id
        GROUP BY cv_report_id_01             -- 帳票ID
                ,xrsal.issue_date            -- 発行日付
                ,xrsal.zip_code              -- 郵便番号
                ,xrsal.send_address1         -- 住所１
                ,xrsal.send_address2         -- 住所２
                ,xrsal.send_address3         -- 住所３
                ,xrsal.bill_cust_code        -- 顧客コード
                ,xrsal.bill_cust_name        -- 顧客名
                ,xrsal.location_code         -- 担当拠点コード
                ,xrsal.location_name         -- 担当拠点名
                ,xrsal.phone_num             -- 電話番号
                ,xrsal.target_date           -- 対象年月
                ,xrsal.payment_cust_code     -- 売掛管理コード
                ,xrsal.payment_cust_name     -- 売掛管理顧客名
                ,xrsal.ar_concat_text        -- 売掛管理コード連結文字列
                ,xrsal.payment_due_date      -- 入金予定日
                ,xrsal.bank_account          -- 振込口座
                ,xrsal.ship_cust_code        -- 納品先顧客コード
                ,xrsal.ship_cust_name        -- 納品先顧客名
                ,xrsal.store_code            -- 店舗コード
                ,xrsal.store_code_sort       -- 店舗コード（ソート用）
                ,xrsal.ship_account_number   -- 納品先顧客コード（ソート用）
                ,xrsal.outsourcing_flag      -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
                ,xrsal.invoice_t_no          -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                ,cn_created_by               -- 作成者
                ,cd_creation_date            -- 作成日
                ,cn_last_updated_by          -- 最終更新者
                ,cd_last_update_date         -- 最終更新日
                ,cn_last_update_login        -- 最終更新ログイン
                ,cn_request_id               -- 要求ID
                ,cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
                ,cn_program_id               -- コンカレント・プログラムID
                ,cd_program_update_date      -- プログラム更新日
        ;
--
        gn_target_cnt_a_h := SQL%ROWCOUNT;
--
      -- 印刷単位：Aの顧客あり、かつ対象データがない場合
      ELSIF ( gv_target_a_flag = cv_taget_flag_1 ) THEN
        -- 帳票０件メッセージを標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダに登録
        INSERT INTO xxcfr_rep_st_inv_inc_tax_a_h (
          data_empty_message           , -- 0件メッセージ
          outsourcing_flag             , -- 業者委託フラグ
          created_by                   , -- 作成者
          creation_date                , -- 作成日
          last_updated_by              , -- 最終更新者
          last_update_date             , -- 最終更新日
          last_update_login            , -- 最終更新ログイン
          request_id                   , -- 要求ID
          program_application_id       , -- コンカレント・プログラム・アプリケーションID
          program_id                   , -- コンカレント・プログラムID
          program_update_date          ) -- プログラム更新日
        VALUES (
          lv_no_data_msg               , -- 0件メッセージ
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- 業者委託フラグ
          cn_created_by                , -- 作成者
          cd_creation_date             , -- 作成日
          cn_last_updated_by           , -- 最終更新者
          cd_last_update_date          , -- 最終更新日
          cn_last_update_login         , -- 最終更新ログイン
          cn_request_id                , -- 要求ID
          cn_program_application_id    , -- コンカレント・プログラム・アプリケーションID
          cn_program_id                , -- コンカレント・プログラムID
          cd_program_update_date       );-- プログラム更新日
      END IF;
--
      IF ( gn_target_cnt_b_l <> 0 ) THEN
        -- 明細0件フラグ（2：対象データあり）
        gv_target_b_flag := cv_taget_flag_2;
--
        -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダの登録
        INSERT INTO xxcfr_rep_st_inv_inc_tax_b_h(
           report_id                -- 帳票ID
          ,issue_date               -- 発行日付
          ,zip_code                 -- 郵便番号
          ,send_address1            -- 住所１
          ,send_address2            -- 住所２
          ,send_address3            -- 住所３
          ,bill_cust_code           -- 顧客コード
          ,bill_cust_name           -- 顧客名
          ,location_code            -- 担当拠点コード
          ,location_name            -- 担当拠点名
          ,phone_num                -- 電話番号
          ,target_date              -- 対象年月
          ,payment_cust_code        -- 売掛管理コード
          ,payment_cust_name        -- 売掛管理顧客名
          ,ar_concat_text           -- 売掛管理コード連結文字列
          ,payment_due_date         -- 入金予定日
          ,bank_account             -- 振込口座
          ,outsourcing_flag         -- 業者委託フラグ
          ,total_charge             -- 請求金額
-- Add 2023.07.04 Ver1.95 Start
          ,invoice_t_no             -- 登録番号
-- Add 2023.07.04 Ver1.95 End
          ,created_by               -- 作成者
          ,creation_date            -- 作成日
          ,last_updated_by          -- 最終更新者
          ,last_update_date         -- 最終更新日
          ,last_update_login        -- 最終更新ログイン
          ,request_id               -- 要求ID
          ,program_application_id   -- コンカレント・プログラム・アプリケーションID
          ,program_id               -- コンカレント・プログラムID
          ,program_update_date      -- プログラム更新日
        )
        SELECT cv_report_id_03                                   -- 帳票ID
              ,xrsbl.issue_date                                  -- 発行日付
              ,xrsbl.zip_code                                    -- 郵便番号
              ,xrsbl.send_address1                               -- 住所１
              ,xrsbl.send_address2                               -- 住所２
              ,xrsbl.send_address3                               -- 住所３
              ,xrsbl.bill_cust_code                              -- 顧客コード
              ,xrsbl.bill_cust_name                              -- 顧客名
              ,xrsbl.location_code                               -- 担当拠点コード
              ,xrsbl.location_name                               -- 担当拠点名
              ,xrsbl.phone_num                                   -- 電話番号
              ,xrsbl.target_date                                 -- 対象年月
              ,xrsbl.payment_cust_code                           -- 売掛管理コード
              ,xrsbl.payment_cust_name                           -- 売掛管理顧客名
              ,xrsbl.ar_concat_text                              -- 売掛管理コード連結文字列
              ,xrsbl.payment_due_date                            -- 入金予定日
              ,xrsbl.bank_account                                -- 振込口座
              ,xrsbl.outsourcing_flag                            -- 業者委託フラグ
              ,SUM(xrsbl.slip_sum) + SUM(xrsbl.slip_tax_sum)     -- 店舗金額 + 店舗税額
-- Add 2023.07.04 Ver1.95 Start
                ,xrsbl.invoice_t_no          -- 登録番号
-- Add 2023.07.04 Ver1.95 End
              ,cn_created_by                                     -- 作成者
              ,cd_creation_date                                  -- 作成日
              ,cn_last_updated_by                                -- 最終更新者
              ,cd_last_update_date                               -- 最終更新日
              ,cn_last_update_login                              -- 最終更新ログイン
              ,cn_request_id                                     -- 要求ID
              ,cn_program_application_id                         -- コンカレント・プログラム・アプリケーションID
              ,cn_program_id                                     -- コンカレント・プログラムID
              ,cd_program_update_date                            -- プログラム更新日
        FROM   xxcfr_rep_st_inv_inc_tax_b_l  xrsbl
        WHERE  xrsbl.request_id = cn_request_id
        GROUP BY cv_report_id_03             -- 帳票ID
                ,xrsbl.issue_date            -- 発行日付
                ,xrsbl.zip_code              -- 郵便番号
                ,xrsbl.send_address1         -- 住所１
                ,xrsbl.send_address2         -- 住所２
                ,xrsbl.send_address3         -- 住所３
                ,xrsbl.bill_cust_code        -- 顧客コード
                ,xrsbl.bill_cust_name        -- 顧客名
                ,xrsbl.location_code         -- 担当拠点コード
                ,xrsbl.location_name         -- 担当拠点名
                ,xrsbl.phone_num             -- 電話番号
                ,xrsbl.target_date           -- 対象年月
                ,xrsbl.payment_cust_code     -- 売掛管理コード
                ,xrsbl.payment_cust_name     -- 売掛管理顧客名
                ,xrsbl.ar_concat_text        -- 売掛管理コード連結文字列
                ,xrsbl.payment_due_date      -- 入金予定日
                ,xrsbl.bank_account          -- 振込口座
                ,xrsbl.outsourcing_flag      -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
                ,xrsbl.invoice_t_no          -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                ,cn_created_by               -- 作成者
                ,cd_creation_date            -- 作成日
                ,cn_last_updated_by          -- 最終更新者
                ,cd_last_update_date         -- 最終更新日
                ,cn_last_update_login        -- 最終更新ログイン
                ,cn_request_id               -- 要求ID
                ,cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
                ,cn_program_id               -- コンカレント・プログラムID
                ,cd_program_update_date      -- プログラム更新日
        ;
--
        gn_target_cnt_b_h := SQL%ROWCOUNT;
--
      -- 印刷単位：Bの顧客あり、かつ対象データがない場合
      ELSIF ( gv_target_b_flag = cv_taget_flag_1 ) THEN
        -- 帳票０件メッセージを標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダに登録
        INSERT INTO xxcfr_rep_st_inv_inc_tax_b_h (
          data_empty_message           , -- 0件メッセージ
          outsourcing_flag             , -- 業者委託フラグ
          created_by                   , -- 作成者
          creation_date                , -- 作成日
          last_updated_by              , -- 最終更新者
          last_update_date             , -- 最終更新日
          last_update_login            , -- 最終更新ログイン
          request_id                   , -- 要求ID
          program_application_id       , -- コンカレント・プログラム・アプリケーションID
          program_id                   , -- コンカレント・プログラムID
          program_update_date          ) -- プログラム更新日
        VALUES (
          lv_no_data_msg               , -- 0件メッセージ
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- 業者委託フラグ
          cn_created_by                , -- 作成者
          cd_creation_date             , -- 作成日
          cn_last_updated_by           , -- 最終更新者
          cd_last_update_date          , -- 最終更新日
          cn_last_update_login         , -- 最終更新ログイン
          cn_request_id                , -- 要求ID
          cn_program_application_id    , -- コンカレント・プログラム・アプリケーションID
          cn_program_id                , -- コンカレント・プログラムID
          cd_program_update_date       );-- プログラム更新日
--
      END IF;
--
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
      -- 印刷単位C明細の対象件数が0以外の場合
      IF ( gn_target_cnt_c_l <> 0 ) THEN
        -- 明細0件フラグ（2：対象データあり）
        gv_target_c_flag := cv_taget_flag_2;
        -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダの登録
        INSERT INTO xxcfr_rep_st_inv_inc_tax_c_h(
           report_id                -- 帳票ID
          ,issue_date               -- 発行日付
          ,zip_code                 -- 郵便番号
          ,send_address1            -- 住所１
          ,send_address2            -- 住所２
          ,send_address3            -- 住所３
          ,bill_cust_code           -- 顧客コード
          ,bill_cust_name           -- 顧客名
          ,location_code            -- 担当拠点コード
          ,location_name            -- 担当拠点名
          ,phone_num                -- 電話番号
          ,target_date              -- 対象年月
          ,payment_cust_code        -- 売掛管理コード
          ,payment_cust_name        -- 売掛管理顧客名
          ,ar_concat_text           -- 売掛管理コード連結文字列
          ,payment_due_date         -- 入金予定日
          ,bank_account             -- 振込口座
          ,ship_cust_code           -- 納品先顧客コード
          ,ship_cust_name           -- 納品先顧客名
          ,store_code               -- 店舗コード
          ,store_code_sort          -- 店舗コード（ソート用）
          ,ship_account_number      -- 納品先顧客コード（ソート用）
          ,outsourcing_flag         -- 業者委託フラグ
          ,store_charge_sum         -- 店舗金額
          ,store_tax_sum            -- 店舗税額
-- Add 2023.07.04 Ver1.95 Start
          ,invoice_t_no             -- 登録番号
-- Add 2023.07.04 Ver1.95 End
          ,created_by               -- 作成者
          ,creation_date            -- 作成日
          ,last_updated_by          -- 最終更新者
          ,last_update_date         -- 最終更新日
          ,last_update_login        -- 最終更新ログイン
          ,request_id               -- 要求ID
          ,program_application_id   -- コンカレント・プログラム・アプリケーションID
          ,program_id               -- コンカレント・プログラムID
          ,program_update_date      -- プログラム更新日
        )
        SELECT cv_report_id_09             -- 帳票ID
              ,xrscl.issue_date            -- 発行日付
              ,xrscl.zip_code              -- 郵便番号
              ,xrscl.send_address1         -- 住所１
              ,xrscl.send_address2         -- 住所２
              ,xrscl.send_address3         -- 住所３
              ,xrscl.bill_cust_code        -- 顧客コード
              ,xrscl.bill_cust_name        -- 顧客名
              ,xrscl.location_code         -- 担当拠点コード
              ,xrscl.location_name         -- 担当拠点名
              ,xrscl.phone_num             -- 電話番号
              ,xrscl.target_date           -- 対象年月
              ,xrscl.payment_cust_code     -- 売掛管理コード
              ,xrscl.payment_cust_name     -- 売掛管理顧客名
              ,xrscl.ar_concat_text        -- 売掛管理コード連結文字列
              ,xrscl.payment_due_date      -- 入金予定日
              ,xrscl.bank_account          -- 振込口座
              ,xrscl.ship_cust_code        -- 納品先顧客コード
              ,xrscl.ship_cust_name        -- 納品先顧客名
              ,xrscl.store_code            -- 店舗コード
              ,xrscl.store_code_sort       -- 店舗コード（ソート用）
              ,xrscl.ship_account_number   -- 納品先顧客コード（ソート用）
              ,xrscl.outsourcing_flag      -- 業者委託フラグ
              ,SUM(xrscl.slip_sum)         -- 店舗金額
              ,SUM(xrscl.slip_tax_sum)     -- 店舗税額
-- Add 2023.07.04 Ver1.95 Start
              ,xrscl.invoice_t_no          -- 登録番号
-- Add 2023.07.04 Ver1.95 End
              ,cn_created_by               -- 作成者
              ,cd_creation_date            -- 作成日
              ,cn_last_updated_by          -- 最終更新者
              ,cd_last_update_date         -- 最終更新日
              ,cn_last_update_login        -- 最終更新ログイン
              ,cn_request_id               -- 要求ID
              ,cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
              ,cn_program_id               -- コンカレント・プログラムID
              ,cd_program_update_date      -- プログラム更新日
        FROM   xxcfr_rep_st_inv_inc_tax_c_l  xrscl
        WHERE  xrscl.request_id = cn_request_id
        GROUP BY cv_report_id_09             -- 帳票ID
                ,xrscl.issue_date            -- 発行日付
                ,xrscl.zip_code              -- 郵便番号
                ,xrscl.send_address1         -- 住所１
                ,xrscl.send_address2         -- 住所２
                ,xrscl.send_address3         -- 住所３
                ,xrscl.bill_cust_code        -- 顧客コード
                ,xrscl.bill_cust_name        -- 顧客名
                ,xrscl.location_code         -- 担当拠点コード
                ,xrscl.location_name         -- 担当拠点名
                ,xrscl.phone_num             -- 電話番号
                ,xrscl.target_date           -- 対象年月
                ,xrscl.payment_cust_code     -- 売掛管理コード
                ,xrscl.payment_cust_name     -- 売掛管理顧客名
                ,xrscl.ar_concat_text        -- 売掛管理コード連結文字列
                ,xrscl.payment_due_date      -- 入金予定日
                ,xrscl.bank_account          -- 振込口座
                ,xrscl.ship_cust_code        -- 納品先顧客コード
                ,xrscl.ship_cust_name        -- 納品先顧客名
                ,xrscl.store_code            -- 店舗コード
                ,xrscl.store_code_sort       -- 店舗コード（ソート用）
                ,xrscl.ship_account_number   -- 納品先顧客コード（ソート用）
                ,xrscl.outsourcing_flag      -- 業者委託フラグ
-- Add 2023.07.04 Ver1.95 Start
                ,xrscl.invoice_t_no          -- 登録番号
-- Add 2023.07.04 Ver1.95 End
                ,cn_created_by               -- 作成者
                ,cd_creation_date            -- 作成日
                ,cn_last_updated_by          -- 最終更新者
                ,cd_last_update_date         -- 最終更新日
                ,cn_last_update_login        -- 最終更新ログイン
                ,cn_request_id               -- 要求ID
                ,cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
                ,cn_program_id               -- コンカレント・プログラムID
                ,cd_program_update_date      -- プログラム更新日
        ;
--
        gn_target_cnt_c_h := SQL%ROWCOUNT;
--
      -- 印刷単位：Cの顧客あり、かつ対象データがない場合
      ELSIF ( gv_target_c_flag = cv_taget_flag_1 ) THEN
        -- 帳票０件メッセージを標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダに登録
        INSERT INTO xxcfr_rep_st_inv_inc_tax_c_h (
          data_empty_message           , -- 0件メッセージ
          outsourcing_flag             , -- 業者委託フラグ
          created_by                   , -- 作成者
          creation_date                , -- 作成日
          last_updated_by              , -- 最終更新者
          last_update_date             , -- 最終更新日
          last_update_login            , -- 最終更新ログイン
          request_id                   , -- 要求ID
          program_application_id       , -- コンカレント・プログラム・アプリケーションID
          program_id                   , -- コンカレント・プログラムID
          program_update_date          ) -- プログラム更新日
        VALUES (
          lv_no_data_msg               , -- 0件メッセージ
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- 業者委託フラグ
          cn_created_by                , -- 作成者
          cd_creation_date             , -- 作成日
          cn_last_updated_by           , -- 最終更新者
          cd_last_update_date          , -- 最終更新日
          cn_last_update_login         , -- 最終更新ログイン
          cn_request_id                , -- 要求ID
          cn_program_application_id    , -- コンカレント・プログラム・アプリケーションID
          cn_program_id                , -- コンカレント・プログラムID
          cd_program_update_date       );-- プログラム更新日
      END IF;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
      -- 印刷単位D明細の対象件数が0以外の場合
      IF ( gn_target_cnt_d_l <> 0 ) THEN
        -- 明細0件フラグ（2：対象データあり）
        gv_target_d_flag := cv_taget_flag_2;
--
        -- 標準請求書帳票内訳印刷単位Dワークテーブルヘッダの登録
        INSERT INTO xxcfr_rep_st_inv_d_h(
           report_id                -- 帳票ID
          ,issue_date               -- 発行日付
          ,zip_code                 -- 郵便番号
          ,send_address1            -- 住所１
          ,send_address2            -- 住所２
          ,send_address3            -- 住所３
          ,bill_cust_code           -- 顧客コード
          ,bill_cust_name           -- 顧客名
          ,location_code            -- 担当拠点コード
          ,location_name            -- 担当拠点名
          ,phone_num                -- 電話番号
-- 2023/07/04 Ver1.95 ADD Start
          ,target_date              -- 対象年月
-- 2023/07/04 Ver1.95 ADD End
          ,payment_cust_code        -- 売掛管理コード
          ,payment_cust_name        -- 売掛管理顧客名
-- 2023/07/04 Ver1.95 ADD Start
          ,ar_concat_text           -- 売掛管理コード連結文字列
          ,payment_due_date         -- 入金予定日
          ,ship_cust_code           -- 納品先顧客コード
          ,ship_cust_name           -- 納品先顧客名
          ,store_code               -- 店舗コード
          ,store_code_sort          -- 店舗コード(ソート用)
          ,ship_account_number      -- 納品先顧客コード(ソート用)
          ,store_charge_sum         -- 店舗金額
          ,store_tax_sum            -- 店舗税額
-- 2023/07/04 Ver1.95 ADD End
          ,bank_account             -- 振込口座情報
          ,outsourcing_flag         -- 業者委託フラグ
-- 2023/07/04 Ver1.95 ADD Start
          ,invoice_t_no             -- 適格請求書発行事業者登録番号
-- 2023/07/04 Ver1.95 ADD End
          ,created_by               -- 作成者
          ,creation_date            -- 作成日
          ,last_updated_by          -- 最終更新者
          ,last_update_date         -- 最終更新日
          ,last_update_login        -- 最終更新ログイン
          ,request_id               -- 要求ID
          ,program_application_id   -- コンカレント・プログラム・アプリケーションID
          ,program_id               -- コンカレント・プログラムID
          ,program_update_date      -- プログラム更新日
        )
        SELECT cv_report_id_13                                   -- 帳票ID
              ,xrsdl.issue_date                                  -- 発行日付
              ,xrsdl.zip_code                                    -- 郵便番号
              ,xrsdl.send_address1                               -- 住所１
              ,xrsdl.send_address2                               -- 住所２
              ,xrsdl.send_address3                               -- 住所３
              ,xrsdl.bill_cust_code                              -- 顧客コード
              ,xrsdl.bill_cust_name                              -- 顧客名
              ,xrsdl.location_code                               -- 担当拠点コード
              ,xrsdl.location_name                               -- 担当拠点名
              ,xrsdl.phone_num                                   -- 電話番号
-- 2023/07/04 Ver1.95 ADD Start
              ,xrsdl.target_date                                 -- 対象年月
-- 2023/07/04 Ver1.95 ADD End
              ,xrsdl.payment_cust_code                           -- 売掛管理コード
              ,xrsdl.payment_cust_name                           -- 売掛管理顧客名
-- 2023/07/04 Ver1.95 ADD Start
              ,xrsdl.ar_concat_text                              -- 売掛管理コード連結文字列
              ,xrsdl.payment_due_date                            -- 入金予定日
              ,xrsdl.ship_cust_code                              -- 納品先顧客コード
              ,xrsdl.ship_cust_name                              -- 納品先顧客名
              ,xrsdl.store_code                                  -- 店舗コード
              ,xrsdl.store_code_sort                             -- 店舗コード(ソート用)
              ,xrsdl.ship_account_number                         -- 納品先顧客コード(ソート用)
              ,SUM( CASE WHEN xrsdl.invoice_tax_div IS NULL THEN
                      xrsdl.slip_sum                             -- 伝票金額
                    WHEN xrsdl.invoice_tax_div = cn_invoice_tax_div THEN
                      xrsdl.inv_amount_sum                       -- 税抜合計１
                    ELSE
                      xrsdl.inv_amount_sum2                      -- 税抜合計２
                    END )                                        -- 店舗金額
              ,SUM( CASE WHEN xrsdl.invoice_tax_div IS NULL THEN
                      xrsdl.slip_tax_sum                         -- 伝票税額
                    WHEN xrsdl.invoice_tax_div = cn_invoice_tax_div THEN
                      xrsdl.tax_amount_sum                       -- 税額合計１
                    ELSE
                      xrsdl.tax_amount_sum2                      -- 税額合計２
                    END )                                        -- 店舗税額
-- 2023/07/04 Ver1.95 ADD End
              ,xrsdl.bank_account                                -- 振込口座情報
              ,xrsdl.outsourcing_flag                            -- 業者委託フラグ
-- 2023/07/04 Ver1.95 ADD Start
              ,gv_t_number                                       -- 適格請求書発行事業者登録番号
-- 2023/07/04 Ver1.95 ADD End
              ,cn_created_by                                     -- 作成者
              ,cd_creation_date                                  -- 作成日
              ,cn_last_updated_by                                -- 最終更新者
              ,cd_last_update_date                               -- 最終更新日
              ,cn_last_update_login                              -- 最終更新ログイン
              ,cn_request_id                                     -- 要求ID
              ,cn_program_application_id                         -- コンカレント・プログラム・アプリケーションID
              ,cn_program_id                                     -- コンカレント・プログラムID
              ,cd_program_update_date                            -- プログラム更新日
        FROM   xxcfr_rep_st_inv_inc_tax_d_l  xrsdl
        WHERE  xrsdl.request_id = cn_request_id
        GROUP BY cv_report_id_13             -- 帳票ID
                ,xrsdl.issue_date            -- 発行日付
                ,xrsdl.zip_code              -- 郵便番号
                ,xrsdl.send_address1         -- 住所１
                ,xrsdl.send_address2         -- 住所２
                ,xrsdl.send_address3         -- 住所３
                ,xrsdl.bill_cust_code        -- 顧客コード
                ,xrsdl.bill_cust_name        -- 顧客名
                ,xrsdl.location_code         -- 担当拠点コード
                ,xrsdl.location_name         -- 担当拠点名
                ,xrsdl.phone_num             -- 電話番号
-- 2023/07/04 Ver1.95 ADD Start
                ,xrsdl.target_date           -- 対象年月
-- 2023/07/04 Ver1.95 ADD End
                ,xrsdl.payment_cust_code     -- 売掛管理コード
                ,xrsdl.payment_cust_name     -- 売掛管理顧客名
-- 2023/07/04 Ver1.95 ADD Start
                ,xrsdl.ar_concat_text        -- 売掛管理コード連結文字列
                ,xrsdl.payment_due_date      -- 入金予定日
                ,xrsdl.ship_cust_code        -- 納品先顧客コード
                ,xrsdl.ship_cust_name        -- 納品先顧客名
                ,xrsdl.store_code            -- 店舗コード
                ,xrsdl.store_code_sort       -- 店舗コード(ソート用)
                ,xrsdl.ship_account_number   -- 納品先顧客コード(ソート用)
-- 2023/07/04 Ver1.95 ADD End
                ,xrsdl.bank_account          -- 振込口座情報
                ,xrsdl.outsourcing_flag      -- 業者委託フラグ
                ,cn_created_by               -- 作成者
                ,cd_creation_date            -- 作成日
                ,cn_last_updated_by          -- 最終更新者
                ,cd_last_update_date         -- 最終更新日
                ,cn_last_update_login        -- 最終更新ログイン
                ,cn_request_id               -- 要求ID
                ,cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
                ,cn_program_id               -- コンカレント・プログラムID
                ,cd_program_update_date      -- プログラム更新日
        ;
--
        gn_target_cnt_d_h := SQL%ROWCOUNT;
--
      -- 印刷単位：Dの顧客あり、かつ対象データがない場合
      ELSIF ( gv_target_d_flag = cv_taget_flag_1 ) THEN
        -- 帳票０件メッセージを標準請求書帳票内訳印刷単位Dワークテーブルヘッダに登録
        INSERT INTO xxcfr_rep_st_inv_d_h (
          data_empty_message           , -- 0件メッセージ
          outsourcing_flag             , -- 業者委託フラグ
          created_by                   , -- 作成者
          creation_date                , -- 作成日
          last_updated_by              , -- 最終更新者
          last_update_date             , -- 最終更新日
          last_update_login            , -- 最終更新ログイン
          request_id                   , -- 要求ID
          program_application_id       , -- コンカレント・プログラム・アプリケーションID
          program_id                   , -- コンカレント・プログラムID
          program_update_date          ) -- プログラム更新日
        VALUES (
          lv_no_data_msg               , -- 0件メッセージ
          CASE WHEN iv_bill_invoice_type = cv_bill_invoice_type_os THEN
            cv_os_flag_y
          ELSE
            NULL
          END                          , -- 業者委託フラグ
          cn_created_by                , -- 作成者
          cd_creation_date             , -- 作成日
          cn_last_updated_by           , -- 最終更新者
          cd_last_update_date          , -- 最終更新日
          cn_last_update_login         , -- 最終更新ログイン
          cn_request_id                , -- 要求ID
          cn_program_application_id    , -- コンカレント・プログラム・アプリケーションID
          cn_program_id                , -- コンカレント・プログラムID
          cd_program_update_date       );-- プログラム更新日
--
      END IF;
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- Add 2013.12.13 Ver1.60 Start
-- Mod 2015.07.31 Ver1.80 Start
--      ELSE
      IF ( ( gn_target_cnt <> 0 )
        OR ( gv_target_a_flag = cv_taget_flag_2 )
-- Mod 2016.03.31 Ver1.90 Start
--        OR ( gv_target_b_flag = cv_taget_flag_2 ) ) THEN
        OR ( gv_target_b_flag = cv_taget_flag_2 )
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--        OR ( gv_target_c_flag = cv_taget_flag_2 ) ) THEN
        OR ( gv_target_c_flag = cv_taget_flag_2 )
        OR ( gv_target_d_flag = cv_taget_flag_2 ) ) THEN
-- Ver.1.92 [障害E_本稼動_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
-- Mod 2016.09.06 Ver1.91 Start
--        --税別内訳出力ありの場合、税別の金額を編集する
--        IF ( iv_tax_output_type = cv_tax_op_type_yes ) THEN
--          -- =====================================================
--          --  ワークテーブルデータ更新  (A-11)
--          -- =====================================================
--          update_work_table(
--             lv_errbuf             -- エラー・メッセージ           --# 固定 #
--            ,lv_retcode            -- リターン・コード             --# 固定 #
--            ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
--          );
--          IF (lv_retcode = cv_status_error) THEN
--            --(エラー処理)
--            RAISE update_work_expt;
--          END IF;
--        END IF;
        -- =====================================================
        --  ワークテーブルデータ更新  (A-11)
        -- =====================================================
        update_work_table(
           iv_tax_output_type    -- 税別内訳出力区分
          ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode            -- リターン・コード             --# 固定 #
          ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE update_work_expt;
        END IF;
-- Mod 2016.09.06 Ver1.91 End
-- Add 2013.12.13 Ver1.60 End
      END IF;
--
    EXCEPTION
-- Ver.1.92 [障害E_本稼動_15307] ADD START
      WHEN global_api_expt THEN
        RAISE global_api_expt;
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- Add 2013.12.13 Ver1.60 Start
      --ワーク更新例外
      WHEN update_work_expt THEN
        RAISE global_api_expt;
-- Add 2013.12.13 Ver1.60 End
      WHEN OTHERS THEN  -- 登録時エラー
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_013    -- テーブル登録エラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- 標準請求書税抜帳票ワークテーブル
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- 成功件数の設定
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
  END insert_work_table;
--
  /**********************************************************************************
   * Procedure Name   : chk_account_data
   * Description      : 口座情報取得チェック (A-7)
   ***********************************************************************************/
  PROCEDURE chk_account_data(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_account_data'; -- プログラム名
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
    ln_target_cnt    NUMBER;         -- 対象件数
    ln_loop_cnt      NUMBER;         -- ループカウンタ
    lv_warn_msg      VARCHAR2(5000);
    lv_bill_data_msg VARCHAR2(5000);
    lv_warn_bill_num VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR sel_no_account_data_cur
    IS
      SELECT xrsi.payment_cust_code  lv_payment_cust_code ,
             xrsi.payment_cust_name  lv_payment_cust_name ,
             xrsi.location_name      lv_location_name
      FROM xxcfr_rep_st_invoice_inc_tax_d  xrsi
      WHERE xrsi.request_id  = cn_request_id  -- 要求ID
-- Mod 2015.07.31 Ver1.80 Start
--        AND bank_account IS NULL
        AND xrsi.bank_account       IS NULL           -- 振込口座
        AND xrsi.data_empty_message IS NULL           -- 0件メッセージ
-- Mod 2015.07.31 Ver1.80 End
      GROUP BY xrsi.payment_cust_code ,
               xrsi.payment_cust_name,
               xrsi.location_name
-- Add 2015.07.31 Ver1.80 Start
      UNION ALL
      SELECT xrsia.payment_cust_code  lv_payment_cust_code ,
             xrsia.payment_cust_name  lv_payment_cust_name ,
             xrsia.location_name      lv_location_name
      FROM xxcfr_rep_st_inv_inc_tax_a_h  xrsia
      WHERE xrsia.request_id         = cn_request_id  -- 要求ID
        AND xrsia.bank_account       IS NULL          -- 振込口座
        AND xrsia.data_empty_message IS NULL          -- 0件メッセージ
      GROUP BY xrsia.payment_cust_code ,
               xrsia.payment_cust_name,
               xrsia.location_name
      UNION ALL
      SELECT xrsib.payment_cust_code  lv_payment_cust_code ,
             xrsib.payment_cust_name  lv_payment_cust_name ,
             xrsib.location_name      lv_location_name
      FROM xxcfr_rep_st_inv_inc_tax_b_h  xrsib
      WHERE xrsib.request_id         = cn_request_id  -- 要求ID
        AND xrsib.bank_account       IS NULL          -- 振込口座
        AND xrsib.data_empty_message IS NULL          -- 0件メッセージ
      GROUP BY xrsib.payment_cust_code ,
               xrsib.payment_cust_name,
               xrsib.location_name
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
      UNION ALL
      SELECT xrsic.payment_cust_code  lv_payment_cust_code ,
             xrsic.payment_cust_name  lv_payment_cust_name ,
             xrsic.location_name      lv_location_name
      FROM xxcfr_rep_st_inv_inc_tax_c_h  xrsic
      WHERE xrsic.request_id         = cn_request_id  -- 要求ID
        AND xrsic.bank_account       IS NULL          -- 振込口座
        AND xrsic.data_empty_message IS NULL          -- 0件メッセージ
      GROUP BY xrsic.payment_cust_code ,
               xrsic.payment_cust_name,
               xrsic.location_name
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
      UNION ALL
      SELECT xrsid.payment_cust_code  lv_payment_cust_code ,
             xrsid.payment_cust_name  lv_payment_cust_name ,
             xrsid.location_name      lv_location_name
      FROM xxcfr_rep_st_inv_d_h  xrsid
      WHERE xrsid.request_id         = cn_request_id  -- 要求ID
        AND xrsid.bank_account       IS NULL          -- 振込口座
        AND xrsid.data_empty_message IS NULL          -- 0件メッセージ
      GROUP BY xrsid.payment_cust_code ,
               xrsid.payment_cust_name,
               xrsid.location_name
-- Ver.1.92 [障害E_本稼動_15307] ADD END
-- Mod 2015.07.31 Ver1.80 Start
--      ORDER BY xrsi.payment_cust_code ASC;
      ORDER BY lv_payment_cust_code ASC;
-- Mod 2015.07.31 Ver1.80 End
--
    TYPE g_sel_no_account_data_ttype IS TABLE OF sel_no_account_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_sel_no_account_tab    g_sel_no_account_data_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 請求書発行対象データが存在する場合以下の処理を実行
-- Mod 2015.07.31 Ver1.80 Start
--    IF ( gn_target_cnt > 0 ) THEN
    IF ( ( gn_target_cnt > 0 ) 
      OR ( gn_target_cnt_a_h > 0 )
-- Mod 2016.03.31 Ver1.90 Start
--      OR ( gn_target_cnt_b_h > 0 ) ) THEN
      OR ( gn_target_cnt_b_h > 0 )
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--      OR ( gn_target_cnt_c_h > 0 ) ) THEN
      OR ( gn_target_cnt_c_h > 0 )
      OR ( gn_target_cnt_d_h > 0 ) ) THEN
-- Ver.1.92 [障害E_本稼動_15307] MOD END
-- Mod 2016.03.31 Ver1.90 End
-- Mod 2015.07.31 Ver1.80 End
--
      -- カーソルオープン
      OPEN sel_no_account_data_cur;
--
      -- データの一括取得
      FETCH sel_no_account_data_cur BULK COLLECT INTO lt_sel_no_account_tab;
--
      -- 処理件数のセット
      ln_target_cnt := lt_sel_no_account_tab.COUNT;
--
      -- カーソルクローズ
      CLOSE sel_no_account_data_cur;
--
      -- 対象データが存在する場合ログに出力する
      IF (ln_target_cnt > 0) THEN
--
        -- 振込口座未登録メッセージ出力
        lv_warn_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_003a18_018);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        -- 顧客コード・顧客名メッセージ出力
        BEGIN
          <<data_loop>>
          FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
            lv_bill_data_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr
                                  ,iv_name         => cv_msg_003a18_019
                                  ,iv_token_name1  => cv_tkn_ac_code
                                  ,iv_token_value1 => lt_sel_no_account_tab(ln_loop_cnt).lv_payment_cust_code
                                  ,iv_token_name2  => cv_tkn_ac_name
                                  ,iv_token_value2 => lt_sel_no_account_tab(ln_loop_cnt).lv_payment_cust_name);
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_bill_data_msg --エラーメッセージ
            );
          END LOOP data_loop;
        END;
        -- 顧客コードの件数をメッセージ出力
        lv_warn_bill_num := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_003a18_020
                        ,iv_token_name1  => cv_tkn_count
                        ,iv_token_value1 => TO_CHAR(ln_target_cnt)
                       );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_bill_num
        );
--
        --１行改行
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => '' --ユーザー・エラーメッセージ
        );
--
        -- 警告終了
        ov_retcode := cv_status_warn;
--
      END IF;
    END IF;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
  END chk_account_data;
--
  /**********************************************************************************
   * Procedure Name   : start_svf_api
   * Description      : SVF起動 (A-8)
   ***********************************************************************************/
  PROCEDURE start_svf_api(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf_api'; -- プログラム名
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFR003A18S.xml';  -- フォーム様式ファイル名
-- Ver1.94 add start
    cv_svf_form_name2 CONSTANT  VARCHAR2(20) := 'XXCFR003A18S_2.xml';-- フォーム様式ファイル名
-- Ver1.94 add end
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFR003A18S.vrq';  -- クエリー様式ファイル名
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';                -- 出力区分(=1：PDF出力）
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';              -- 拡張子（pdf）
--
    -- *** ローカル変数 ***
    lv_no_data_msg     VARCHAR2(5000);  -- 帳票０件メッセージ
    lv_svf_file_name   VARCHAR2(100);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
-- Ver1.94 add start
    lv_svf_form_name   VARCHAR2(20);    -- フォーム様式ファイル名
-- Ver1.94 add end
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    --  SVF起動 (A-4)
    -- =====================================================
--
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
--
    -- コンカレント名の設定
      lv_conc_name := cv_pkg_name;
--
    -- ファイルIDの設定
      lv_file_id := cv_pkg_name;
--
-- Ver1.94 add start
    -- フォーム様式ファイル名設定
      IF (gv_bill_red_flag = cv_status_yes) THEN
        lv_svf_form_name := cv_svf_form_name2;
      ELSE
        lv_svf_form_name := cv_svf_form_name;
      END IF;
--
-- Ver1.94 add end
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_svf_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      ,iv_conc_name    => lv_conc_name          -- コンカレント名
      ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
      ,iv_file_id      => lv_file_id            -- 帳票ID
      ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
-- Ver1.94 mod start
--      ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
-- Ver1.96 MOD START
--      ,iv_frm_file     => lv_svf_form_name      -- フォーム様式ファイル名
      ,iv_frm_file     => gv_frm_file           -- フォーム様式ファイル名
-- Ver1.96 MOD END
-- Ver1.94 mod end
-- Ver1.96 MOD START
--      ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
      ,iv_vrq_file     => gv_vrq_file           -- クエリー様式ファイル名
-- Ver1.96 MOD END
      ,iv_org_id       => gn_org_id             -- ORG_ID
      ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
      ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
      ,iv_doc_name     => NULL                  -- 文書名
      ,iv_printer_name => NULL                  -- プリンタ名
      ,iv_request_id   => cn_request_id         -- 要求ID
      ,iv_nodata_msg   => NULL                  -- データなしメッセージ
    );
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a18_015    -- APIエラー
                                                     ,cv_tkn_api           -- トークン'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_msg_kbn_cfr
                                                       ,cv_dict_svf 
                                                      )  -- SVF起動
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
  END start_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : ワークテーブルデータ削除 (A-9)
   ***********************************************************************************/
  PROCEDURE delete_work_table(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- プログラム名
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
    ln_target_cnt   NUMBER;         -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR del_rep_st_inv_ex_cur
    IS
      SELECT xrsi.rowid        ln_rowid
      FROM xxcfr_rep_st_invoice_inc_tax_d xrsi -- 標準請求書税抜帳票ワークテーブル
      WHERE xrsi.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_ex_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_ex_data    g_del_rep_st_inv_ex_ttype;
--
-- Add 2015.07.31 Ver1.80 Start
    -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダ抽出
    CURSOR del_rep_st_inv_inc_a_h_cur
    IS
      SELECT xrsiah.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_a_h xrsiah  -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダ
      WHERE xrsiah.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_a_h_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_a_h_data    g_del_rep_st_inv_inc_a_h_ttype;
--
    -- 標準請求書税込帳票内訳印刷単位Aワークテーブル明細抽出
    CURSOR del_rep_st_inv_inc_a_l_cur
    IS
      SELECT xrsial.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_a_l xrsial  -- 標準請求書税込帳票内訳印刷単位Aワークテーブル明細
      WHERE xrsial.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_a_l_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_a_l_data    g_del_rep_st_inv_inc_a_l_ttype;
--
    -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダ抽出
    CURSOR del_rep_st_inv_inc_b_h_cur
    IS
      SELECT xrsibh.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_b_h xrsibh  -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダ
      WHERE xrsibh.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_b_h_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_b_h_data    g_del_rep_st_inv_inc_b_h_ttype;
--
    -- 標準請求書税込帳票内訳印刷単位Bワークテーブル明細抽出
    CURSOR del_rep_st_inv_inc_b_l_cur
    IS
      SELECT xrsibl.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_b_l xrsibl  -- 標準請求書税込帳票内訳印刷単位Bワークテーブル明細
      WHERE xrsibl.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_b_l_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_b_l_data    g_del_rep_st_inv_inc_b_l_ttype;
--
-- Add 2015.07.31 Ver1.80 End
-- Add 2016.03.31 Ver1.90 Start
    -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ抽出
    CURSOR del_rep_st_inv_inc_c_h_cur
    IS
      SELECT xrsich.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_c_h xrsich  -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ
      WHERE xrsich.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_c_h_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_c_h_data    g_del_rep_st_inv_inc_c_h_ttype;
--
    -- 標準請求書税込帳票内訳印刷単位Cワークテーブル明細抽出
    CURSOR del_rep_st_inv_inc_c_l_cur
    IS
      SELECT xrsicl.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_c_l xrsicl  -- 標準請求書税込帳票内訳印刷単位Cワークテーブル明細
      WHERE xrsicl.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_c_l_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_c_l_data    g_del_rep_st_inv_inc_c_l_ttype;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
    -- 標準請求書帳票内訳印刷単位Dワークテーブルヘッダ抽出
    CURSOR del_rep_st_inv_d_h_cur
    IS
      SELECT xrsidh.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_d_h xrsidh  -- 標準請求書帳票内訳印刷単位Dワークテーブルヘッダ
      WHERE xrsidh.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_d_h_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_d_h_data        g_del_rep_st_inv_d_h_ttype;
--
    -- 標準請求書税込帳票内訳印刷単位Dワークテーブル明細抽出
    CURSOR del_rep_st_inv_inc_d_l_cur
    IS
      SELECT xrsidl.rowid        ln_rowid
      FROM xxcfr_rep_st_inv_inc_tax_d_l xrsidl  -- 標準請求書税込帳票内訳印刷単位Dワークテーブル明細
      WHERE xrsidl.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_inc_d_l_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_inc_d_l_data    g_del_rep_st_inv_inc_d_l_ttype;
--
-- Ver.1.92 [障害E_本稼動_15307] ADD END
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- Mod 2015.07.31 Ver1.80 Start
--    -- カーソルオープン
--    OPEN del_rep_st_inv_ex_cur;
----
--    -- データの一括取得
--    FETCH del_rep_st_inv_ex_cur BULK COLLECT INTO lt_del_rep_st_inv_ex_data;
----
--    -- 処理件数のセット
--    ln_target_cnt := lt_del_rep_st_inv_ex_data.COUNT;
----
--    -- カーソルクローズ
--    CLOSE del_rep_st_inv_ex_cur;
----
--    -- 対象データが存在する場合レコードを削除する
--    IF (ln_target_cnt > 0) THEN
--      BEGIN
--        <<data_loop>>
--        FORALL ln_loop_cnt IN 1..ln_target_cnt
--          DELETE FROM xxcfr_rep_st_invoice_inc_tax_d
--          WHERE ROWID = lt_del_rep_st_inv_ex_data(ln_loop_cnt);
----
--        -- コミット発行
--        COMMIT;
----
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                        ,cv_msg_003a18_012 -- データ削除エラー
--                                                        ,cv_tkn_table         -- トークン'TABLE'
--                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
--                                                        -- 標準請求書税抜帳票ワークテーブル
--                              ,1
--                              ,5000);
--          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_api_expt;
--      END;
----
--    END IF;
--  EXCEPTION
--    WHEN lock_expt THEN  -- テーブルロックできなかった
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
--                                                     ,cv_msg_003a18_011    -- テーブルロックエラー
--                                                     ,cv_tkn_table         -- トークン'TABLE'
--                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
--                                                    -- 標準請求書税抜帳票ワークテーブル
--                           ,1
--                           ,5000);
--      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
    -- �@標準請求書税込帳票ワークテーブル削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_ex_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_ex_cur BULK COLLECT INTO lt_del_rep_st_inv_ex_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_ex_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_ex_cur;
--
      -- 対象データが存在する場合レコードを削除する
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_invoice_inc_tax_d rep
            WHERE rep.rowid = lt_del_rep_st_inv_ex_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                          ,cv_msg_003a18_012 -- データ削除エラー
                                                          ,cv_tkn_table         -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                          -- 標準請求書税込帳票ワークテーブル
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- 標準請求書税込帳票ワークテーブル
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �A標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダ削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_inc_a_h_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_inc_a_h_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_a_h_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_inc_a_h_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_inc_a_h_cur;
--
      -- 対象データが存在する場合レコードを削除する
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_a_h rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_a_h_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- データ削除エラー
                                                          ,cv_tkn_table         -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_a_h))
                                                          -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダ
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_a_h))
                                                      -- 標準請求書税込帳票内訳印刷単位Aワークテーブルヘッダ
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �B標準請求書税込帳票内訳印刷単位Aワークテーブル明細削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_inc_a_l_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_inc_a_l_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_a_l_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_inc_a_l_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_inc_a_l_cur;
--
      -- 対象データが存在する場合レコードを削除する
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_a_l rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_a_l_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- データ削除エラー
                                                          ,cv_tkn_table         -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                          -- 標準請求書税込帳票内訳印刷単位Aワークテーブル明細
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_a_l))
                                                      -- 標準請求書税込帳票内訳印刷単位Aワークテーブル明細
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �C標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダ削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_inc_b_h_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_inc_b_h_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_b_h_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_inc_b_h_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_inc_b_h_cur;
--
      -- 対象データが存在する場合レコードを削除する
     IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_b_h rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_b_h_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- データ削除エラー
                                                          ,cv_tkn_table         -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_b_h))
                                                          -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダ
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_b_h))
                                                      -- 標準請求書税込帳票内訳印刷単位Bワークテーブルヘッダ
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �D標準請求書税込帳票内訳印刷単位Bワークテーブル明細削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_inc_b_l_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_inc_b_l_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_b_l_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_inc_b_l_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_inc_b_l_cur;
--
      -- 対象データが存在する場合レコードを削除する
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_b_l rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_b_l_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                          ,cv_msg_003a18_012 -- データ削除エラー
                                                          ,cv_tkn_table      -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                          -- 標準請求書税込帳票内訳印刷単位Bワークテーブル明細
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_b_l))
                                                      -- 標準請求書税込帳票内訳印刷単位Bワークテーブル明細
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
-- Add 2016.03.31 Ver1.90 Start
    -- �E標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_inc_c_h_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_inc_c_h_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_c_h_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_inc_c_h_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_inc_c_h_cur;
--
      -- 対象データが存在する場合レコードを削除する
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_c_h rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_c_h_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- データ削除エラー
                                                          ,cv_tkn_table         -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_c_h))
                                                          -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_c_h))
                                                      -- 標準請求書税込帳票内訳印刷単位Cワークテーブルヘッダ
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �F標準請求書税込帳票内訳印刷単位Cワークテーブル明細削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_inc_c_l_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_inc_c_l_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_c_l_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_inc_c_l_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_inc_c_l_cur;
--
      -- 対象データが存在する場合レコードを削除する
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_c_l rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_c_l_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                          ,cv_msg_003a18_012 -- データ削除エラー
                                                          ,cv_tkn_table      -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_c_l))
                                                          -- 標準請求書税込帳票内訳印刷単位Cワークテーブル明細
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_c_l))
                                                      -- 標準請求書税込帳票内訳印刷単位Cワークテーブル明細
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
-- Add 2016.03.31 Ver1.90 End
-- Ver.1.92 [障害E_本稼動_15307] ADD START
    -- �G標準請求書帳票内訳印刷単位Dワークテーブルヘッダ削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_d_h_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_d_h_cur BULK COLLECT INTO lt_del_rep_st_inv_d_h_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_d_h_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_d_h_cur;
--
      -- 対象データが存在する場合レコードを削除する
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_d_h rep
            WHERE rep.rowid = lt_del_rep_st_inv_d_h_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                          ,cv_msg_003a18_012    -- データ削除エラー
                                                          ,cv_tkn_table         -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_d_h))
                                                          -- 標準請求書帳票内訳印刷単位Dワークテーブルヘッダ
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_d_h))
                                                      -- 標準請求書帳票内訳印刷単位Dワークテーブルヘッダ
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �H標準請求書税込帳票内訳印刷単位Dワークテーブル明細削除処理
    BEGIN
      -- カーソルオープン
      OPEN del_rep_st_inv_inc_d_l_cur;
--
      -- データの一括取得
      FETCH del_rep_st_inv_inc_d_l_cur BULK COLLECT INTO lt_del_rep_st_inv_inc_d_l_data;
--
      -- 処理件数のセット
      ln_target_cnt := lt_del_rep_st_inv_inc_d_l_data.COUNT;
--
      -- カーソルクローズ
      CLOSE del_rep_st_inv_inc_d_l_cur;
--
      -- 対象データが存在する場合レコードを削除する
      IF (ln_target_cnt > 0) THEN
        BEGIN
          <<data_loop>>
          FORALL ln_loop_cnt IN 1..ln_target_cnt
            DELETE FROM xxcfr_rep_st_inv_inc_tax_d_l rep
            WHERE rep.rowid = lt_del_rep_st_inv_inc_d_l_data(ln_loop_cnt);
--
          -- コミット発行
          COMMIT;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                          ,cv_msg_003a18_012 -- データ削除エラー
                                                          ,cv_tkn_table      -- トークン'TABLE'
                                                          ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                          -- 標準請求書税込帳票内訳印刷単位Dワークテーブル明細
                                ,1
                                ,5000);
            lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_api_expt;
        END;
--
      END IF;
--
    EXCEPTION
      WHEN lock_expt THEN  -- テーブルロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a18_011    -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_d_l))
                                                      -- 標準請求書税込帳票内訳印刷単位Dワークテーブル明細
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
-- Ver.1.92 [障害E_本稼動_15307] ADD END
  EXCEPTION
-- Mod 2015.07.31 Ver1.80 End
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
  END delete_work_table;
--
-- Add 2015.07.31 Ver1.80 Start
--
  /**********************************************************************************
   * Procedure Name   : exec_submit_req
   * Description      : 店舗別明細出力要求発行処理(A-13)
   ***********************************************************************************/
  PROCEDURE exec_submit_req(
    iv_bill_type          IN  VARCHAR2, -- 請求書タイプ
    in_req_cnt            IN  NUMBER,   -- 要求発行数
    in_target_cnt         IN  NUMBER,   -- 対象件数
    ov_errbuf             OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_submit_req'; -- プログラム名
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_conc_name        CONSTANT VARCHAR2(20) := '店舗別明細出力';       -- エラーメッセージトークン
    -- 参照タイプ
    cv_xxcfr_bill_type  CONSTANT VARCHAR2(20) := 'XXCFR1_BILL_TYPE';     -- 請求書タイプ
-- Del 2016.03.31 Ver1.90 Start
--    -- 覚書出力コンカレント名
--    cv_xxcfr003a20      CONSTANT VARCHAR2(20) := 'XXCFR003A20C';         -- 店舗別明細出力
-- Del 2016.03.31 Ver1.90 End
    -- 帳票区分
    cv_report_type      CONSTANT VARCHAR2(20) := '1';                    -- PDF
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_conc_name  VARCHAR2(100);
-- Add 2016.03.31 Ver1.90 Start
    lv_conc_short_name VARCHAR2(100);
-- Add 2016.03.31 Ver1.90 End
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- 店舗別明細出力のコンカレント名称に使用する文言を取得
    --==============================================================
    BEGIN
      SELECT flvv.description AS conc_name
-- Add 2016.03.31 Ver1.90 Start
            ,flvv.attribute1  AS conc_short_name
-- Add 2016.03.31 Ver1.90 End
      INTO   lv_conc_name
-- Add 2016.03.31 Ver1.90 Start
            ,lv_conc_short_name
-- Add 2016.03.31 Ver1.90 End
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type  = cv_xxcfr_bill_type
      AND    flvv.lookup_code  = iv_bill_type
      AND    flvv.enabled_flag = cv_enabled_yes
      AND    TRUNC(NVL(flvv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      AND    TRUNC(NVL(flvv.end_date_active,   SYSDATE)) >= TRUNC(SYSDATE)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfr         -- アプリケーション短縮名
                         , iv_name         => cv_msg_003a18_027      -- メッセージコード
                         , iv_token_name1  => cv_tkn_lookup_type     -- トークンコード1
                         , iv_token_value1 => cv_xxcfr_bill_type     -- トークン値1
                         , iv_token_name2  => cv_tkn_lookup_code     -- トークンコード2
                         , iv_token_value2 => iv_bill_type           -- トークン値2
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- コンカレント発行
    --==============================================================
-- Ver.1.92 [障害E_本稼動_15307] ADD START
    g_org_request(in_req_cnt).conc_name := lv_conc_name;
-- Ver.1.92 [障害E_本稼動_15307] ADD END
    g_org_request(in_req_cnt).request_id := fnd_request.submit_request(
                                               application => cv_msg_kbn_cfr         -- アプリケーション短縮名
-- Mod 2016.03.31 Ver1.90 Start
--                                              ,program     => cv_xxcfr003a20         -- コンカレントプログラム名
                                              ,program     => lv_conc_short_name     -- コンカレントプログラム名
-- Mod 2016.03.31 Ver1.90 Start
                                              ,description => lv_conc_name           -- 摘要
                                              ,start_time  => NULL                   -- 開始時間
                                              ,sub_request => FALSE                  -- サブ要求
                                              ,argument1   => cv_report_type         -- 帳票区分
                                              ,argument2   => iv_bill_type           -- 請求書タイプ
                                              ,argument3   => TO_CHAR(cn_request_id) -- 発行元要求ID
                                              ,argument4   => TO_CHAR(in_target_cnt) -- 対象件数
-- Ver1.96 ADD START
                                              ,argument5   => gv_drafting_company    -- 請求書作成会社コード
-- Ver1.96 ADD END
                      );
    -- 正常以外の場合
    IF ( g_org_request(in_req_cnt).request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr                                -- アプリケーション短縮名
                     , iv_name         => cv_msg_003a18_028                             -- メッセージコード
                     , iv_token_name1  => cv_tkn_conc                                   -- トークンコード１
                     , iv_token_value1 => cv_conc_name                                  -- 店舗別明細出力
                   );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- 親コンカレント用リターンコード
      ov_retcode := cv_status_error;
    END IF;
--
    -- コミット発行
    COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END exec_submit_req;
--
  /**********************************************************************************
   * Procedure Name   : func_wait_for_request
   * Description      : コンカレント終了待機処理(A-14)
   ***********************************************************************************/
  PROCEDURE func_wait_for_request(
    ig_org_request_id           IN  g_org_request_ttype,   -- 要求ID
    ov_errbuf                   OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)              -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_wait_for_request'; -- プログラム名
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_conc_name  CONSTANT VARCHAR2(14)   := '店舗別明細出力';        -- エラーメッセージトークン
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lb_wait_request           BOOLEAN        DEFAULT TRUE;
    lv_phase                  VARCHAR2(50)   DEFAULT NULL;
    lv_status                 VARCHAR2(50)   DEFAULT NULL;
    lv_dev_phase              VARCHAR2(50)   DEFAULT NULL;
    lv_dev_status             VARCHAR2(50)   DEFAULT NULL;
    lv_message                VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<wait_req>>
    FOR i IN ig_org_request_id.FIRST..ig_org_request_id.LAST LOOP
      -- 正常に発行できたもののみ
      IF ( ig_org_request_id(i).request_id <> 0 ) THEN
        --==============================================================
        -- コンカレント要求待機
        --==============================================================
        lb_wait_request := fnd_concurrent.wait_for_request(
                              request_id => ig_org_request_id(i).request_id -- 要求ID
                             ,interval   => gn_interval                     -- コンカレント監視間隔
                             ,max_wait   => gn_max_wait                     -- コンカレント監視最大時間
                             ,phase      => lv_phase                        -- 要求フェーズ
                             ,status     => lv_status                       -- 要求ステータス
                             ,dev_phase  => lv_dev_phase                    -- 要求フェーズコード
                             ,dev_status => lv_dev_status                   -- 要求ステータスコード
                             ,message    => lv_message                      -- 完了メッセージ
                           );
        -- 戻り値がFALSEの場合
        IF ( lb_wait_request = FALSE ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cfr
                         ,iv_name         => cv_msg_003a18_029
                         ,iv_token_name1  => cv_tkn_conc
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--                         ,iv_token_value1 => cv_conc_name
                         ,iv_token_value1 => ig_org_request_id(i).conc_name
-- Ver.1.92 [障害E_本稼動_15307] MOD END
                         ,iv_token_name2  => cv_tkn_request_id
                         ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                       );
          lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
          -- 親コンカレント用リターンコード
          ov_retcode := cv_status_error;
        ELSE
          -- 正常終了メッセージ出力
          IF ( lv_dev_status = cv_dev_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cfr
                           ,iv_name         => cv_msg_003a18_030
                           ,iv_token_name1  => cv_tkn_conc
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--                           ,iv_token_value1 => cv_conc_name
                           ,iv_token_value1 => ig_org_request_id(i).conc_name
-- Ver.1.92 [障害E_本稼動_15307] MOD END
                           ,iv_token_name2  => cv_tkn_request_id
                           ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := lv_errmsg;
          -- 警告終了メッセージ出力
          ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cfr
                           ,iv_name         => cv_msg_003a18_031
                           ,iv_token_name1  => cv_tkn_conc
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--                           ,iv_token_value1 => cv_conc_name
                           ,iv_token_value1 => ig_org_request_id(i).conc_name
-- Ver.1.92 [障害E_本稼動_15307] MOD END
                           ,iv_token_name2  => cv_tkn_request_id
                           ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := lv_errmsg;
            ov_retcode := cv_status_warn;
          -- エラー終了メッセージ出力
          ELSE
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cfr
                           , iv_name         => cv_msg_003a18_032
                           , iv_token_name1  => cv_tkn_conc
-- Ver.1.92 [障害E_本稼動_15307] MOD START
--                           , iv_token_value1 => cv_conc_name
                           ,iv_token_value1 => ig_org_request_id(i).conc_name
-- Ver.1.92 [障害E_本稼動_15307] MOD END
                           , iv_token_name2  => cv_tkn_request_id
                           , iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
            -- 親コンカレント用リターンコード
            ov_retcode := cv_status_error;
          END IF;
        END IF;
        -- ログ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf
        );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
    END LOOP wait_req;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END func_wait_for_request;
-- Add 2015.07.31 Ver1.80 End
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_customer_code14     IN      VARCHAR2,         -- 売掛管理先顧客
    iv_customer_code21     IN      VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code20     IN      VARCHAR2,         -- 請求書用顧客
    iv_customer_code10     IN      VARCHAR2,         -- 顧客
-- Add 2010.12.10 Ver1.30 Start
    iv_bill_pub_cycle      IN      VARCHAR2,         -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
    iv_tax_output_type     IN      VARCHAR2,         -- 税別内訳出力区分
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
    iv_bill_invoice_type   IN      VARCHAR2,         -- 請求書出力形式
-- Add 2014.03.27 Ver1.70 End
-- Ver1.96 ADD START
    iv_company_cd          IN      VARCHAR2,         -- 会社コード
-- Ver1.96 ADD END
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
-- Add 2015.07.31 Ver1.80 Start
    gn_req_cnt    := 0;
-- Add 2015.07.31 Ver1.80 End
--
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_target_date         -- 締日
      ,iv_customer_code14     -- 売掛管理先顧客
      ,iv_customer_code21     -- 統括請求書用顧客
      ,iv_customer_code20     -- 請求書用顧客
      ,iv_customer_code10     -- 顧客
-- Add 2010.12.10 Ver1.30 Start
      ,iv_bill_pub_cycle      -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
      ,iv_tax_output_type     -- 税別内訳出力区分
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
      ,iv_bill_invoice_type   -- 請求書出力形式
-- Add 2014.03.27 Ver1.70 End
-- Ver1.96 ADD START
      ,iv_company_cd          -- 会社コード
-- Ver1.96 ADD END
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  全社出力権限チェック処理(A-3)
    -- =====================================================
    chk_inv_all_dept(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
-- Ver1.94 add start
    -- =====================================================
    --  請求書朱印部門チェック処理 (A-15)
    -- =====================================================
    chk_bill_red_dept(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
--Ver1.94 add end
--
-- Ver1.96 ADD START
    -- =====================================================
    --  会社別関連情報の取得処理 (A-16)
    -- =====================================================
    get_company_info(
       iv_customer_code14    -- 売掛管理先顧客
      ,iv_customer_code21    -- 統括請求書用顧客
      ,iv_customer_code20    -- 請求書用顧客
      ,iv_customer_code10    -- 顧客
      ,iv_company_cd         -- 会社コード
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
-- Ver1.96 ADD END
--
    -- ======================================================================================
    --  対象顧客取得処理(A-4)、売掛管理先顧客取得処理(A-5)、ワークテーブルデータ登録(A-6))
    -- ======================================================================================
    insert_work_table(
       iv_target_date         -- 締日
      ,iv_customer_code14     -- 売掛管理先顧客
      ,iv_customer_code21     -- 統括請求書用顧客
      ,iv_customer_code20     -- 請求書用顧客
      ,iv_customer_code10     -- 顧客
-- Add 2010.12.10 Ver1.30 Start
      ,iv_bill_pub_cycle      -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
      ,iv_tax_output_type     -- 税別内訳出力区分
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
      ,iv_bill_invoice_type   -- 請求書出力形式
-- Add 2014.03.27 Ver1.70 End
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
    ELSIF (gv_warning_flag = cv_status_yes) THEN  -- 顧客紐付け警告存在時
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  口座情報取得チェック (A-7)
    -- =====================================================
    chk_account_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  SVF起動 (A-8)
    -- =====================================================
    start_svf_api(
       lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode_svf            -- リターン・コード             --# 固定 #
      ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
--
-- Add 2015.07.31 Ver1.80 Start
    -- =====================================================
    --  店舗別明細出力要求発行処理 (A-13)
    -- =====================================================
--Ver1.94 add start
    IF ( gv_bill_red_flag = cv_status_yes ) THEN
      -- 明細0件フラグA＝1の場合
      IF ( gv_target_a_flag = cv_taget_flag_1 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：01_2の要求発行
        exec_submit_req(
           cv_bill_type_01_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_a_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- 明細0件フラグA＝2の場合
      ELSIF ( gv_target_a_flag =  cv_taget_flag_2 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：01_2の要求発行
        exec_submit_req(
           cv_bill_type_01_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_a_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：02_2の要求発行
        exec_submit_req(
           cv_bill_type_02_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_a_l         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
  --
      -- 明細0件フラグB＝1の場合
      IF ( gv_target_b_flag = cv_taget_flag_1 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：03_2の要求発行
        exec_submit_req(
           cv_bill_type_03_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_b_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- 明細0件フラグB＝2の場合
      ELSIF ( gv_target_b_flag =  cv_taget_flag_2 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：03_2の要求発行
        exec_submit_req(
           cv_bill_type_03_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_b_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：04_2の要求発行
        exec_submit_req(
           cv_bill_type_04_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_b_l         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
  --
      -- 明細0件フラグC＝1の場合
      IF ( gv_target_c_flag = cv_taget_flag_1 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：09_2の要求発行
        exec_submit_req(
           cv_bill_type_09_2           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_c_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- 明細0件フラグC＝2の場合
      ELSIF ( gv_target_c_flag =  cv_taget_flag_2 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：09_2の要求発行
        exec_submit_req(
           cv_bill_type_09_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_c_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：10の要求発行
        exec_submit_req(
           cv_bill_type_10           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_c_l         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
  --
      -- 明細0件フラグD＝1の場合
      IF ( gv_target_d_flag = cv_taget_flag_1 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：13_2の要求発行
        exec_submit_req(
           cv_bill_type_13_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_d_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- 明細0件フラグD＝2の場合
      ELSIF ( gv_target_d_flag =  cv_taget_flag_2 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：13_2の要求発行
        exec_submit_req(
           cv_bill_type_13_2         -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_d_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：14_2の要求発行
        exec_submit_req(
           cv_bill_type_14_2           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_d_l         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
    ELSE
--Ver1.94 add end
      -- 明細0件フラグA＝1の場合
      IF ( gv_target_a_flag = cv_taget_flag_1 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：01の要求発行
        exec_submit_req(
           cv_bill_type_01           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_a_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- 明細0件フラグA＝2の場合
      ELSIF ( gv_target_a_flag =  cv_taget_flag_2 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：01の要求発行
        exec_submit_req(
           cv_bill_type_01           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_a_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：02の要求発行
        exec_submit_req(
           cv_bill_type_02           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_a_l         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
  --
      -- 明細0件フラグB＝1の場合
      IF ( gv_target_b_flag = cv_taget_flag_1 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：03の要求発行
        exec_submit_req(
           cv_bill_type_03           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_b_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- 明細0件フラグB＝2の場合
      ELSIF ( gv_target_b_flag =  cv_taget_flag_2 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：03の要求発行
        exec_submit_req(
           cv_bill_type_03           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_b_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：04の要求発行
        exec_submit_req(
           cv_bill_type_04           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_b_l         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
  --
-- Add 2016.03.31 Ver1.90 Start
      -- 明細0件フラグC＝1の場合
      IF ( gv_target_c_flag = cv_taget_flag_1 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：09の要求発行
        exec_submit_req(
           cv_bill_type_09           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_c_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- 明細0件フラグC＝2の場合
      ELSIF ( gv_target_c_flag =  cv_taget_flag_2 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：09の要求発行
        exec_submit_req(
           cv_bill_type_09           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_c_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：10の要求発行
        exec_submit_req(
           cv_bill_type_10           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_c_l         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
  --
-- Add 2016.03.31 Ver1.90 End
  -- Ver.1.92 [障害E_本稼動_15307] ADD START
      -- 明細0件フラグD＝1の場合
      IF ( gv_target_d_flag = cv_taget_flag_1 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：13の要求発行
        exec_submit_req(
           cv_bill_type_13           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_d_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- 明細0件フラグD＝2の場合
      ELSIF ( gv_target_d_flag =  cv_taget_flag_2 ) THEN
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：13の要求発行
        exec_submit_req(
           cv_bill_type_13           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_d_h         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
        gn_req_cnt := gn_req_cnt + 1;
        -- 請求書タイプ：14の要求発行
        exec_submit_req(
           cv_bill_type_14           -- 請求書タイプ
          ,gn_req_cnt                -- 要求発行数
          ,gn_target_cnt_d_l         -- 対象件数
          ,lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode_svf            -- リターン・コード             --# 固定 #
          ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
-- Ver1.94 add start
    END IF;
-- Ver1.94 add end
--
-- Ver.1.92 [障害E_本稼動_15307] ADD END
    -- =====================================================
    --  コンカレント終了待機処理(A-14)
    -- =====================================================
    IF (  ( g_org_request.COUNT <> 0 )
      AND ( lv_retcode_svf <> cv_status_error ) ) THEN
      --発行した店舗別明細出力を待機する
      func_wait_for_request(
         ig_org_request_id    => g_org_request
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );
    END IF;
--
-- Add 2015.07.31 Ver1.80 End
    -- =====================================================
    --  ワークテーブルデータ削除 (A-9)
    -- =====================================================
    delete_work_table(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  SVF起動APIエラーチェック (A-8)
    -- =====================================================
    IF (lv_retcode_svf = cv_status_error) THEN
      --(エラー処理)
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
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
    errbuf                 OUT     VARCHAR2,         -- エラー・メッセージ  #固定#
    retcode                OUT     VARCHAR2,         -- エラーコード        #固定#
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_customer_code10     IN      VARCHAR2,         -- 顧客
    iv_customer_code20     IN      VARCHAR2,         -- 請求書用顧客
    iv_customer_code21     IN      VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code14     IN      VARCHAR2          -- 売掛管理先顧客
-- Add 2010.12.10 Ver1.30 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
   ,iv_tax_output_type     IN      VARCHAR2          -- 税別内訳出力区分
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
   ,iv_bill_invoice_type   IN      VARCHAR2          -- 請求書出力形式
-- Add 2014.03.27 Ver1.70 End
-- Ver1.96 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- 会社コード
-- Ver1.96 ADD END
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
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
    lv_errbuf2      VARCHAR2(5000);  -- エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
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
       iv_target_date     => iv_target_date -- 締日
      ,iv_customer_code14 => iv_customer_code14     -- 売掛管理先顧客
      ,iv_customer_code21 => iv_customer_code21     -- 統括請求書用顧客
      ,iv_customer_code20 => iv_customer_code20     -- 請求書用顧客
      ,iv_customer_code10 => iv_customer_code10     -- 顧客
-- Add 2010.12.10 Ver1.30 Start
      ,iv_bill_pub_cycle  => iv_bill_pub_cycle      -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.13 Ver1.60 Start
      ,iv_tax_output_type => iv_tax_output_type     -- 税別内訳出力区分
-- Add 2013.12.13 Ver1.60 End
-- Add 2014.03.27 Ver1.70 Start
      ,iv_bill_invoice_type => iv_bill_invoice_type -- 請求書出力形式
-- Add 2014.03.27 Ver1.70 End
-- Ver1.96 ADD START
      ,iv_company_cd      => iv_company_cd          -- 会社コード
-- Ver1.96 ADD END
      ,ov_errbuf          => lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
    --正常でない場合、エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
--
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- システムエラーメッセージ出力
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a18_009
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --エラーメッセージ
      );
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
        --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
    );
    END IF;
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
    );
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFR003A18C;
/
