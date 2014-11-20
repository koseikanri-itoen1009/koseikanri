CREATE OR REPLACE PACKAGE BODY XXCMM003A40C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A40C(body)
 * Description      : 顧客一括登録ワークテーブルに取込済のデータから顧客レコードを登録します。
 * MD.050           : 顧客一括登録 MD050_CMM_003_A40
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  validate_cust_wk       顧客一括登録ワークデータ妥当性チェック (A-4)
 *  add_report             顧客登録結果を格納するプロシージャ
 *  disp_report            顧客登録結果を出力するプロシージャ
 *  ins_cust_acct_api      顧客マスタ登録処理 (A-5)
 *  ins_location_api       顧客所在地マスタ登録処理 (A-5)
 *  ins_party_site_api     パーティサイトマスタ登録処理 (A-5)
 *  ins_cust_acct_site_api 顧客サイトマスタ登録処理 (A-5)
 *  ins_bill_to_api        顧客使用目的マスタ(請求先)登録処理 (A-5)
 *  ins_ship_to_api        顧客使用目的マスタ登録処理(出荷先) (A-5)
 *  ins_other_to_api       顧客使用目的マスタ登録処理(その他) (A-5)
 *  regist_resource_no_api 組織プロファイル拡張(担当営業員)登録処理 (A-5)
 *  ins_cmm_cust_acct      顧客追加情報マスタ登録処理
 *  ins_cmm_mst_crprt      顧客法人情報登録処理
 *  loop_main              顧客一括登録ワークデータ取得 (A-3)
 *  get_if_data            ファイルアップロードIFデータ取得 (A-2)
 *  proc_comp              終了処理 (A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/10/05    1.0   Shigeto.Niki     新規作成
 *  2010/11/05    1.1   Shigeto.Niki     E_本稼動_05492対応  担当営業員登録時のチェック追加
 *  2012/12/14    1.2   K.Furuyama       E_本稼動_09963対応  顧客区分：13、14追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
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
  --*** ロックエラー例外 ***
  global_check_lock_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCMM003A40C';                                      -- パッケージ名
--
  -- メッセージ
  cv_msg_xxcmm_00002     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';                                  -- プロファイル取得エラー
  cv_msg_xxcmm_00012     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00012';                                  -- データ削除エラー
  cv_msg_xxcmm_00018     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';                                  -- 業務日付取得エラー
  cv_msg_xxcmm_00021     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';                                  -- ファイルアップロード名称ノート
  cv_msg_xxcmm_00022     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';                                  -- CSVファイル名ノート
  cv_msg_xxcmm_00023     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';                                  -- FILE_IDノート
  cv_msg_xxcmm_00024     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';                                  -- フォーマットノート
  cv_msg_xxcmm_00028     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';                                  -- データ項目数エラー
  --
  cv_msg_xxcmm_10323     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10323';                                  -- パラメータNULLエラー
  cv_msg_xxcmm_10324     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10324';                                  -- 取得失敗エラー
  cv_msg_xxcmm_10325     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10325';                                  -- 自拠点判定エラー
  cv_msg_xxcmm_10326     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10326';                                  -- 全角文字チェックエラー
  cv_msg_xxcmm_10327     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10327';                                  -- 半角文字チェックエラー
  cv_msg_xxcmm_10328     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10328';                                  -- 値チェックエラー
  cv_msg_xxcmm_10329     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10329';                                  -- 値セット存在チェックエラー
  cv_msg_xxcmm_10330     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10330';                                  -- 参照コード存在チェックエラー
  cv_msg_xxcmm_10331     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10331';                                  -- 郵便番号チェックエラー
  cv_msg_xxcmm_10332     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10332';                                  -- 電話番号チェックエラー
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 delete start by Shigeto.Niki
--  cv_msg_xxcmm_10333     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10333';                                  -- 適用開始日入力チェックエラー
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 delete end by Shigeto.Niki
  cv_msg_xxcmm_10334     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10334';                                  -- 担当営業員存在チェックエラー
  cv_msg_xxcmm_10335     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10335';                                  -- データ登録エラー
  cv_msg_xxcmm_10336     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10336';                                  -- 顧客一括登録用CSVファイル取得エラー
  cv_msg_xxcmm_10337     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10337';                                  -- I/Fテーブルロック取得エラー
  cv_msg_xxcmm_10338     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10338';                                  -- ファイル項目チェックエラー
  cv_msg_xxcmm_10339     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10339';                                  -- 標準APIエラー
  cv_msg_xxcmm_10340     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10340';                                  -- 顧客追加情報マスタ登録エラー
  cv_msg_xxcmm_10341     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10341';                                  -- 顧客登録時のログ見出し
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_msg_xxcmm_10344     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10344';                                  -- 顧客法人情報マスタ登録エラー
  cv_msg_xxcmm_10345     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10345';                                  -- 決裁日付チェックエラー
  cv_msg_xxcmm_10346     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10346';                                  -- データ存在チェックエラー
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  -- トークン名
  cv_tkn_file_id         CONSTANT VARCHAR2(20)  := 'FILE_ID';                                           -- ファイルID
  cv_tkn_up_name         CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';                                       -- ファイルアップロード名称
  cv_tkn_file_format     CONSTANT VARCHAR2(20)  := 'FORMAT';                                            -- フォーマット
  cv_tkn_file_name       CONSTANT VARCHAR2(20)  := 'FILE_NAME';                                         -- ファイル名
  cv_file_upload_obj     CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';                            -- ファイルアップロードオブジェクト
  cv_tkn_param_name      CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                                        -- パラメータ名
  cv_tkn_ng_profile      CONSTANT VARCHAR2(20)  := 'NG_PROFILE';                                        -- プロファイル名
  cv_tkn_value           CONSTANT VARCHAR2(20)  := 'VALUE';                                             -- 値
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                                             -- テーブル名
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';                                             -- 処理件数
  cv_tkn_input_line_no   CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';                                     -- インタフェースの行番号
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';                                           -- エラー内容
  cv_tkn_input           CONSTANT VARCHAR2(20)  := 'INPUT';                                             -- 項目
  cv_tkn_apply_date      CONSTANT VARCHAR2(20)  := 'APPLY_DATE';                                        -- 適用開始日
  cv_tkn_cust_code       CONSTANT VARCHAR2(20)  := 'CUST_CODE';                                         -- 顧客コード
  cv_tkn_api_name        CONSTANT VARCHAR2(20)  := 'API_NAME';                                          -- 標準API名
  cv_tkn_seq_num         CONSTANT VARCHAR2(20)  := 'SEQ_NUM';                                           -- シーケンス番号
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_tkn_cust_id         CONSTANT VARCHAR2(20)  := 'CUST_ID';                                           -- 顧客ID
  cv_tkn_approval_date   CONSTANT VARCHAR2(20)  := 'APPROVAL_DATE';                                     -- 決裁日付
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  --
  cv_appl_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';                                             -- アプリケーション短縮名
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';                                             -- アドオン：共通・IF領域
  cv_log                 CONSTANT VARCHAR2(5)   := 'LOG';                                               -- ログ
  cv_output              CONSTANT VARCHAR2(6)   := 'OUTPUT';                                            -- アウトプット
  -- プロファイル名
  cv_prf_resp_id         CONSTANT VARCHAR2(60)  := 'RESP_ID';                                           -- プロファイル「職責ID」
  cv_prf_org_id          CONSTANT VARCHAR2(60)  := 'ORG_ID';                                            -- プロファイル「組織ID」
  cv_prf_resp_key        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_MGR_RESP_KEY';                        -- プロファイル「顧客一括登録管理者職責キー」
  cv_prf_resp_key_n      CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録管理者職責キー';                  -- プロファイル「顧客一括登録管理者職責キー」名称
  cv_prf_item_num_mc     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_MC_KOKYAKU_NUM';                      -- プロファイル「顧客一括登録データ項目数（MC顧客）」
  cv_prf_item_num_mc_n   CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録データ項目数（MC顧客）';          -- プロファイル「顧客一括登録データ項目数（MC顧客）」名称
  cv_prf_item_num_st     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_TENPO_EIGYO_NUM';                     -- プロファイル「顧客一括登録データ項目数（店舗営業）」
  cv_prf_item_num_st_n   CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録データ項目数（店舗営業）';        -- プロファイル「顧客一括登録データ項目数（店舗営業）」名称
  cv_prf_output_form     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_INI_OUTPUT_FORM';                     -- プロファイル「請求書出力形式初期値」
  cv_prf_output_form_n   CONSTANT VARCHAR2(60)  := 'XXCMM:請求書出力形式初期値';                        -- プロファイル「請求書出力形式初期値」名称
  cv_prf_prt_cycle       CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_INI_PRT_CYCLE';                       -- プロファイル「請求書発行サイクル初期値」
  cv_prf_prt_cycle_n     CONSTANT VARCHAR2(60)  := 'XXCMM:請求書発行サイクル初期値';                    -- プロファイル「請求書発行サイクル初期値」名称
  cv_prf_inv_unit        CONSTANT VARCHAR2(60)  := 'XCMM1_003A02_INI_INV_UNIT';                         -- プロファイル「請求書印刷単位初期値」
  cv_prf_inv_unit_n      CONSTANT VARCHAR2(60)  := 'XXCMM:請求書印刷単位初期値';                        -- プロファイル「請求書印刷単位初期値」名称
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_prf_set_of_bks_id   CONSTANT VARCHAR2(60)  := 'GL_SET_OF_BKS_ID';                                   -- プロファイル「会計帳簿ID」
  cv_prf_set_of_bks_id_n CONSTANT VARCHAR2(60)  := '会計帳簿ID';                                         -- プロファイル「会計帳簿ID」名称
  cv_prf_item_num_ho     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_CUST_HOUJIN_NUM';                      -- プロファイル「顧客一括登録データ項目数（法人顧客）」
  cv_prf_item_num_ho_n   CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録データ項目数（法人顧客）';         -- プロファイル「顧客一括登録データ項目数（法人顧客）」名称
  cv_prf_item_num_ur     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_CUST_URIKAKE_NUM';                     -- プロファイル「顧客一括登録データ項目数（売掛管理先顧客）」
  cv_prf_item_num_ur_n   CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録データ項目数（売掛管理先顧客）';   -- プロファイル「顧客一括登録データ項目数（売掛管理先顧客）」名称
  cv_prf_ur_kaisya       CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_KAISYA';                       -- プロファイル「顧客一括登録（売掛管理先顧客）用_会社」
  cv_prf_ur_kaisya_n     CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録（売掛管理先顧客）用_会社';        -- プロファイル「顧客一括登録（売掛管理先顧客）用_会社」名称
  cv_prf_ur_bumon        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_BUMON';                        -- プロファイル「顧客一括登録（売掛管理先顧客）用_部門」
  cv_prf_ur_bumon_n      CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録（売掛管理先顧客）用_部門';        -- プロファイル「顧客一括登録（売掛管理先顧客）用_部門」名称
  cv_prf_ur_kanjyou      CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_KANJYOU';                      -- プロファイル「顧客一括登録（売掛管理先顧客）用_勘定科目」
  cv_prf_ur_kanjyou_n    CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録（売掛管理先顧客）用_勘定科目';    -- プロファイル「顧客一括登録（売掛管理先顧客）用_勘定科目」名称
  cv_prf_ur_hojyo        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_HOJYO';                        -- プロファイル「顧客一括登録（売掛管理先顧客）用_補助科目」
  cv_prf_ur_hojyo_n      CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録（売掛管理先顧客）用_補助科目';    -- プロファイル「顧客一括登録（売掛管理先顧客）用_補助科目」名称
  cv_prf_ur_kokyaku      CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_KOKYAKU';                      -- プロファイル「顧客一括登録（売掛管理先顧客）用_顧客コード」
  cv_prf_ur_kokyaku_n    CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録（売掛管理先顧客）用_顧客コード';  -- プロファイル「顧客一括登録（売掛管理先顧客）用_顧客コード」名称
  cv_prf_ur_kigyou       CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_KIGYOU';                       -- プロファイル「顧客一括登録（売掛管理先顧客）用_企業コード」
  cv_prf_ur_kigyou_n     CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録（売掛管理先顧客）用_企業コード';  -- プロファイル「顧客一括登録（売掛管理先顧客）用_企業コード」名称
  cv_prf_ur_yobi1        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_YOBI1';                        -- プロファイル「顧客一括登録（売掛管理先顧客）用_予備１」
  cv_prf_ur_yobi1_n      CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録（売掛管理先顧客）用_予備１';      -- プロファイル「顧客一括登録（売掛管理先顧客）用_予備１」名称
  cv_prf_ur_yobi2        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_YOBI2';                        -- プロファイル「顧客一括登録（売掛管理先顧客）用_予備２」
  cv_prf_ur_yobi2_n      CONSTANT VARCHAR2(60)  := 'XXCMM:顧客一括登録（売掛管理先顧客）用_予備２';      -- プロファイル「顧客一括登録（売掛管理先顧客）用_予備２」名称
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  -- 値セット
  cv_aff_dept            CONSTANT VARCHAR2(15)  := 'XX03_DEPARTMENT';                                   -- LOOKUP：AFF部門マスタ
  -- LOOKUP
  cv_xxcmm_chain_code    CONSTANT VARCHAR2(16)  := 'XXCMM_CHAIN_CODE';                                  -- LOOKUP：チェーン店
  cv_lookup_chiku_code   CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_CHIKU_CODE';                             -- LOOKUP：地区コード
  cv_lookup_gyotai_sho   CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';                             -- LOOKUP：業態小分類
  cv_lookup_mcjuyodo     CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_MCJUYODO';                               -- LOOKUP：MC:重要度
  cv_lookup_mchotdo      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_MCHOTDO';                                -- LOOKUP：MC:HOT度
  cv_lookup_gyosyu       CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_KBN';                             -- LOOKUP：業種
  cv_lookup_torihiki     CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_TORIHIKI_KETAI';                         -- LOOKUP：取引形態
  cv_lookup_haiso        CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_HAISO_KETAI';                            -- LOOKUP：配送形態
  cv_lookup_cust_def_mc  CONSTANT VARCHAR2(30)  := 'XXCMM1_003A40_CUST_DEF_MC';                         -- LOOKUP：顧客一括登録データ項目定義(MC)
  cv_lookup_cust_def_st  CONSTANT VARCHAR2(30)  := 'XXCMM1_003A40_CUST_DEF_ST';                         -- LOOKUP：顧客一括登録データ項目定義(店舗営業)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_lookup_sohyo_kbn    CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_SOHYO_KBN';                              -- LOOKUP：総評区分
  cv_lookup_syohizei_kbn CONSTANT VARCHAR2(30)  := 'XXCMM_CSUT_SYOHIZEI_KBN';                           -- LOOKUP：消費税区分
  cv_lookup_tax_rule     CONSTANT VARCHAR2(30)  := 'AR_TAX_ROUNDING_RULE';                              -- LOOKUP：税金端数処理
  cv_lookup_invoice_grp  CONSTANT VARCHAR2(30)  := 'XXCMM_INVOICE_GRP_CODE';                            -- LOOKUP：売掛コード1（請求書）
  cv_lookup_sekyusyo_ksk CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_SEKYUSYO_SHUT_KSK';                      -- LOOKUP：請求書出力形式
  cv_lookup_invoice_cycl CONSTANT VARCHAR2(30)  := 'XXCMM_INVOICE_ISSUE_CYCLE';                         -- LOOKUP：請求書発行サイクル
  cv_lookup_cust_def_ho  CONSTANT VARCHAR2(30)  := 'XXCMM1_003A40_CUST_DEF_HO';                         -- LOOKUP：顧客一括登録データ項目定義(法人)
  cv_lookup_cust_def_ur  CONSTANT VARCHAR2(30)  := 'XXCMM1_003A40_CUST_DEF_UR';                         -- LOOKUP：顧客一括登録データ項目定義(売掛管理)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  --
  cv_file_format_mc      CONSTANT VARCHAR2(3)   := '501';                                               -- ファイルフォーマット(MC)
  cv_file_format_st      CONSTANT VARCHAR2(3)   := '502';                                               -- ファイルフォーマット(店舗営業)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_file_format_ho      CONSTANT VARCHAR2(3)   := '503';                                               -- ファイルフォーマット(法人)
  cv_file_format_ur      CONSTANT VARCHAR2(3)   := '504';                                               -- ファイルフォーマット(売掛管理)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  cv_sales_ou            CONSTANT VARCHAR2(20)  := 'SALES-OU';                                          -- 営業OU
  cv_base_kbn            CONSTANT VARCHAR2(2)   := '1';                                                 -- 顧客区分(拠点)
  cv_tenpo_kbn           CONSTANT VARCHAR2(2)   := '15';                                                -- 顧客区分(店舗営業)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_hojin_kbn           CONSTANT VARCHAR2(2)   := '13';                                                -- 顧客区分(法人)
  cv_urikake_kbn         CONSTANT VARCHAR2(2)   := '14';                                                -- 顧客区分(売掛管理)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  cv_cust_status_mc_cand CONSTANT VARCHAR2(2)   := '10';                                                -- 顧客ステータス：MC候補
  cv_cust_status_mc      CONSTANT VARCHAR2(2)   := '20';                                                -- 顧客ステータス：MC
  cv_cust_status_except  CONSTANT VARCHAR2(2)   := '99';                                                -- 顧客ステータス：対象外
  cv_site_use_bill_to    CONSTANT VARCHAR2(10)  := 'BILL_TO';                                           -- 使用目的コード(請求先)
  cv_site_use_ship_to    CONSTANT VARCHAR2(10)  := 'SHIP_TO';                                           -- 使用目的コード(出荷先)
  cv_site_use_other_to   CONSTANT VARCHAR2(10)  := 'OTHER_TO';                                          -- 使用目的コード(その他)
  cv_ui_flag_new         CONSTANT VARCHAR2(1)   := '1';                                                 -- 新規／更新フラグ（新規）
  -- ITEM
  cv_file_id             CONSTANT VARCHAR2(30)  := 'FILE_ID';                                           -- ファイルID
  cv_format              CONSTANT VARCHAR2(30)  := 'フォーマットパターン';                              -- フォーマットパターン
  cv_cust_upload         CONSTANT VARCHAR2(30)  := '顧客一括登録';                                      -- ワークテーブル名
  cv_upload_def_info     CONSTANT VARCHAR2(30)  := '顧客一括登録ワーク定義情報';                        -- 顧客一括登録ワーク定義情報
  cv_file_upload_name    CONSTANT VARCHAR2(30)  := 'ファイルアップロード名称';                          -- ファイルアップロード名称
  cv_user_resp_key       CONSTANT VARCHAR2(30)  := 'ＥＢＳログインユーザー職責キー';                    -- ＥＢＳログインユーザー職責キー
  cv_sal_org_id          CONSTANT VARCHAR2(30)  := '営業組織ＩＤ';                                      -- 営業組織ＩＤ
  cv_belong_base_code    CONSTANT VARCHAR2(30)  := '所属拠点コード';                                    -- 所属拠点コード
  cv_customer_name       CONSTANT VARCHAR2(30)  := '顧客名';                                            -- 顧客名
  cv_customer_name_kana  CONSTANT VARCHAR2(30)  := '顧客名（カナ）';                                    -- 顧客名（カナ）
  cv_customer_name_ryaku CONSTANT VARCHAR2(30)  := '略称';                                              -- 略称
  cv_customer_class_code CONSTANT VARCHAR2(30)  := '顧客区分';                                          -- 顧客区分
  cv_customer_status     CONSTANT VARCHAR2(30)  := '顧客ステータス';                                    -- 顧客ステータス
  cv_sale_base_code      CONSTANT VARCHAR2(30)  := '売上拠点';                                          -- 売上拠点
  cv_s_chain_code        CONSTANT VARCHAR2(30)  := '販売先チェーン';                                    -- 販売先チェーン
  cv_d_chain_code        CONSTANT VARCHAR2(30)  := '納品先チェーン';                                    -- 納品先チェーン
  cv_postal_code         CONSTANT VARCHAR2(30)  := '郵便番号';                                          -- 郵便番号
  cv_state               CONSTANT VARCHAR2(30)  := '都道府県';                                          -- 都道府県
  cv_city                CONSTANT VARCHAR2(30)  := '市・区';                                            -- 市・区
  cv_address1            CONSTANT VARCHAR2(30)  := '住所１';                                            -- 住所１
  cv_address2            CONSTANT VARCHAR2(30)  := '住所２';                                            -- 住所２
  cv_address3            CONSTANT VARCHAR2(30)  := '地区コード';                                        -- 地区コード
  cv_tel_no              CONSTANT VARCHAR2(30)  := '電話番号';                                          -- 電話番号
  cv_fax                 CONSTANT VARCHAR2(30)  := 'ＦＡＸ';                                            -- ＦＡＸ
  cv_b_row_type_tmp      CONSTANT VARCHAR2(30)  := '業態小分類（仮）';                                  -- 業態小分類（仮）
  cv_manager_name        CONSTANT VARCHAR2(30)  := '店長名';                                            -- 店長名
  cv_rest_emp_name       CONSTANT VARCHAR2(30)  := '担当者休日';                                        -- 担当者休日
  cv_mc_importance_deg   CONSTANT VARCHAR2(30)  := 'ＭＣ：重要度';                                      -- ＭＣ：重要度
  cv_mc_hot_deg          CONSTANT VARCHAR2(30)  := 'ＭＣ：ＨＯＴ度';                                    -- ＭＣ：ＨＯＴ度
  cv_mc_conf_info        CONSTANT VARCHAR2(30)  := 'ＭＣ：競合情報';                                    -- ＭＣ：競合情報
  cv_mc_b_talk_details   CONSTANT VARCHAR2(30)  := 'ＭＣ：商談経緯';                                    -- ＭＣ：商談経緯
  cv_resource_no         CONSTANT VARCHAR2(30)  := '担当営業員';                                        -- 担当営業員
  cv_gyotai_sho          CONSTANT VARCHAR2(30)  := '業態（小分類）';                                    -- 業態（小分類）
  cv_industry_div        CONSTANT VARCHAR2(30)  := '業種';                                              -- 業種
  cv_torihiki_form       CONSTANT VARCHAR2(30)  := '取引形態';                                          -- 取引形態
  cv_delivery_form       CONSTANT VARCHAR2(30)  := '配送形態';                                          -- 配送形態
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_base_code           CONSTANT VARCHAR2(30)  := '本部担当拠点';                                      -- 本部担当拠点
  cv_decide_div          CONSTANT VARCHAR2(30)  := '判定区分';                                          -- 判定区分
  cv_tax_div             CONSTANT VARCHAR2(30)  := '消費税区分';                                        -- 消費税区分
  cv_tax_rounding_rule   CONSTANT VARCHAR2(30)  := '税金端数処理';                                      -- 税金端数処理
  cv_invoice_grp_code    CONSTANT VARCHAR2(30)  := '売掛コード1（請求書）';                             -- 売掛コード1（請求書）
  cv_output_form         CONSTANT VARCHAR2(30)  := '請求書出力形式';                                    -- 請求書出力形式
  cv_prt_cycle           CONSTANT VARCHAR2(30)  := '請求書発行サイクル';                                -- 請求書発行サイクル
  cv_payment_term_id     CONSTANT VARCHAR2(30)  := '支払条件';                                          -- 支払条件
  cv_delivery_base_code  CONSTANT VARCHAR2(30)  := '納品拠点';                                          -- 納品拠点
  cv_bill_base_code      CONSTANT VARCHAR2(30)  := '請求拠点';                                          -- 請求拠点
  cv_receiv_base_code    CONSTANT VARCHAR2(30)  := '入金拠点';                                          -- 入金拠点
  cv_sales_head_base_cd  CONSTANT VARCHAR2(30)  := '販売先本部担当拠点';                                -- 販売先本部担当拠点
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  -- 標準API名
  cv_api_cust_acct       CONSTANT VARCHAR2(60)  := 'hz_cust_account_v2pub.create_cust_account';         -- 標準API：顧客マスタ作成
  cv_api_location        CONSTANT VARCHAR2(60)  := 'hz_location_v2pub.create_location';                 -- 標準API：顧客所在地マスタ作成
  cv_api_party_site      CONSTANT VARCHAR2(60)  := 'hz_party_site_v2pub.create_party_site';             -- 標準API：パーティサイトマスタ作成
  cv_api_acct_site       CONSTANT VARCHAR2(60)  := 'hz_cust_account_site_v2pub.create_cust_acct_site';  -- 標準API：顧客サイトマスタ作成
  cv_api_cust_site_use   CONSTANT VARCHAR2(60)  := 'hz_cust_account_site_v2pub.create_cust_site_use';   -- 標準API：顧客使用目的マスタ作成
  cv_api_regist_resource CONSTANT VARCHAR2(60)  := 'xxcso_rtn_rsrc_pkg.regist_resource_no';             -- 標準API：ルートNo/担当営業員更新処理関数
  -- TABLE名
  cv_table_xwcu          CONSTANT VARCHAR2(30)  := '顧客一括登録ワーク';                                -- XXCMM_WK_CUST_UPLOAD
  cv_table_file_ul_if    CONSTANT VARCHAR2(30)  := 'ファイルアップロードIF';                            -- XXCCP_MRP_FILE_UL_INTERFACE
  cv_table_cust_acct     CONSTANT VARCHAR2(30)  := '顧客マスタ';                                        -- 顧客マスタ
  cv_table_location      CONSTANT VARCHAR2(30)  := '顧客所在地マスタ';                                  -- 顧客所在地マスタ
  cv_table_party_site    CONSTANT VARCHAR2(30)  := 'パーティサイトマスタ';                              -- パーティサイトマスタ
  cv_table_acct_site     CONSTANT VARCHAR2(30)  := '顧客サイトマスタ';                                  -- 顧客サイトマスタ
  cv_table_bill_to       CONSTANT VARCHAR2(30)  := '顧客使用目的マスタ(請求先)';                        -- 顧客使用目的マスタ(請求先)
  cv_table_ship_to       CONSTANT VARCHAR2(30)  := '顧客使用目的マスタ(出荷先)';                        -- 顧客使用目的マスタ(出荷先)
  cv_table_other_to      CONSTANT VARCHAR2(30)  := '顧客使用目的マスタ(その他)';                        -- 顧客使用目的マスタ(その他)
  cv_table_resource      CONSTANT VARCHAR2(30)  := '担当営業員';                                        -- 担当営業員
  --
  cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';                                                 -- YES
  cv_no                  CONSTANT VARCHAR2(1)   := 'N';                                                 -- NO
  cv_r                   CONSTANT VARCHAR2(1)   := 'R';                                                 -- 顧客タイプ('R'：外部)
  cv_a                   CONSTANT VARCHAR2(1)   := 'A';                                                 -- ステータス('A'：有効)
  cv_y                   CONSTANT VARCHAR2(1)   := 'Y';                                                 -- ステータス('Y'：有効)
  cv_null_ok             CONSTANT VARCHAR2(10)  := 'NULL_OK';                                           -- 任意項目
  cv_null_ng             CONSTANT VARCHAR2(10)  := 'NULL_NG';                                           -- 必須項目
  cv_varchar             CONSTANT VARCHAR2(10)  := 'VARCHAR2';                                          -- 文字列
  cv_number              CONSTANT VARCHAR2(10)  := 'NUMBER';                                            -- 数値
  cv_date                CONSTANT VARCHAR2(10)  := 'DATE';                                              -- 日付
  cv_varchar_cd          CONSTANT VARCHAR2(1)   := '0';                                                 -- 文字列項目
  cv_number_cd           CONSTANT VARCHAR2(1)   := '1';                                                 -- 数値項目
  cv_date_cd             CONSTANT VARCHAR2(1)   := '2';                                                 -- 日付項目
  cv_not_null            CONSTANT VARCHAR2(1)   := '1';                                                 -- 必須
  cv_msg_comma           CONSTANT VARCHAR2(1)   := ',';                                                 -- カンマ
  cv_msg_comma_double    CONSTANT VARCHAR2(2)   := '、';                                                -- カンマ(全角)
  cv_max_date            CONSTANT VARCHAR2(10)  := '9999/12/31';                                        -- MAX日付
  cv_date_fmt_std        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                                        -- YYYY/MM/DD
  cv_category            CONSTANT VARCHAR2(10)  := 'EMPLOYEE';                                          -- カテゴリ
  cv_jp                  CONSTANT VARCHAR2(10)  := 'JP';                                                -- 国('JP'：日本)
  cv_1                   CONSTANT VARCHAR2(1)   := '1';                                                 -- 固定値１
  cv_vist_target         CONSTANT VARCHAR2(1)   := '1';                                                 -- 訪問対象
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_summary             CONSTANT VARCHAR2(10)  := 'SUMMARY';                                           -- 要約
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_item_def_rtype    IS RECORD                                                                    -- レコード型を宣言
      (item_name               VARCHAR2(100)                                                            -- 項目名
      ,item_attribute          VARCHAR2(100)                                                            -- 項目属性
      ,item_essential          VARCHAR2(100)                                                            -- 必須フラグ
      ,item_length             NUMBER                                                                   -- 項目の長さ(整数部分)
      ,decim                   NUMBER                                                                   -- 項目の長さ(小数点以下)
      );
  --
  TYPE g_item_def_ttype   IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;                    -- テーブル型の宣言
  --
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(4000)        INDEX BY BINARY_INTEGER;                    -- テーブル型の宣言
--
  -- 出力するログを格納するレコード
  TYPE report_rec IS RECORD(
    line_no                    xxcmm_wk_cust_upload.line_no%TYPE                                        -- 行番号
   ,account_number             hz_cust_accounts.account_number%TYPE                                     -- 顧客コード
   ,customer_status            xxcmm_wk_cust_upload.customer_status%TYPE                                -- 顧客ステータス
   ,resource_no                xxcmm_wk_cust_upload.resource_no%TYPE                                    -- 担当営業員
   ,resource_s_date            xxcmm_wk_cust_upload.resource_s_date%TYPE                                -- 適用開始日
   ,customer_name              xxcmm_wk_cust_upload.customer_name%TYPE                                  -- 顧客名
  );
  -- 出力するレポートを格納する結合配列
  TYPE report_tbl  IS TABLE OF report_rec   INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_file_id                    NUMBER;                                                                 -- パラメータ格納用変数
  gv_format                     VARCHAR2(100);                                                          -- パラメータ格納用変数
  gd_process_date               DATE;                                                                   -- 業務日付
  gd_system_date                DATE;                                                                   -- システム日付
  g_item_def_tab                g_item_def_ttype;                                                       -- テーブル型変数の宣言
  --
  gn_user_id                    NUMBER;                                                                 -- EBSログインユーザーID
  gt_belong_base_code           per_all_assignments_f.ass_attribute3%TYPE;                              -- EBSログインユーザー所属拠点コード
  gn_resp_id                    NUMBER;                                                                 -- EBSログインユーザー職責ID
  gt_responsibility_key         fnd_responsibility.responsibility_key%TYPE;                             -- EBSログインユーザー職責キー
  gn_resp_appl_id               NUMBER;                                                                 -- EBSログインユーザー職責アプリケーションID
  --
  gt_mgr_resp_key               fnd_profile_option_values.profile_option_value%TYPE;                    -- 管理者職責キー
  gn_item_num                   NUMBER;                                                                 -- 顧客一括登録データ項目数
  gv_output_form                VARCHAR2(1);                                                            -- 請求書出力形式初期値
  gv_prt_cycle                  VARCHAR2(1);                                                            -- 請求書発行サイクル初期値
  gv_inv_unit                   VARCHAR2(1);                                                            -- 請求書印刷単位初期値
  gv_sal_org_id                 hr_all_organization_units.organization_id%TYPE;                         -- 営業側の組織ID
  gd_apply_date                 DATE;                                                                   -- 適用開始日：日付型変換後
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  gt_set_of_bks_id              gl_sets_of_books.set_of_books_id%TYPE;                                  -- 会計帳簿ID
  gt_ur_kaisya                  gl_code_combinations.segment1%TYPE;                                     -- 顧客一括登録（売掛管理先顧客）用_会社
  gt_ur_bumon                   gl_code_combinations.segment2%TYPE;                                     -- 顧客一括登録（売掛管理先顧客）用_部門
  gt_ur_kanjyou                 gl_code_combinations.segment3%TYPE;                                     -- 顧客一括登録（売掛管理先顧客）用_勘定科目
  gt_ur_hojyo                   gl_code_combinations.segment4%TYPE;                                     -- 顧客一括登録（売掛管理先顧客）用_補助科目
  gt_ur_kokyaku                 gl_code_combinations.segment5%TYPE;                                     -- 顧客一括登録（売掛管理先顧客）用_顧客コード
  gt_ur_kigyou                  gl_code_combinations.segment6%TYPE;                                     -- 顧客一括登録（売掛管理先顧客）用_企業コード
  gt_ur_yobi1                   gl_code_combinations.segment7%TYPE;                                     -- 顧客一括登録（売掛管理先顧客）用_予備１
  gt_ur_yobi2                   gl_code_combinations.segment8%TYPE;                                     -- 顧客一括登録（売掛管理先顧客）用_予備２
  gt_urikake_misyuukin_id       gl_code_combinations.code_combination_id%TYPE;                          -- 売掛金/未収金
  gt_autocash_hierarchy_id      ar_autocash_hierarchies.autocash_hierarchy_id%TYPE;                     -- 自動消込基準セットID
  gt_payment_term_id            ra_terms.term_id%TYPE;                                                  -- 支払条件ID
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  --
  gv_warning_prg_name           VARCHAR2(100);                                                          -- 警告発生プロシージャ名
  --
  gn_insert_cnt                 NUMBER;                                                                 -- INSERT件数
  gn_update_cnt                 NUMBER;                                                                 -- UPDATE件数
--
  gt_report_tbl                 report_tbl;                                                             -- 結合配列の定義
--
  -- ===============================
  -- パッケージ・カーソル
  -- ===============================
  -- アップロードファイル存在確認カーソル
  CURSOR check_upload_file_cur(
    in_file_id  IN NUMBER,
    iv_format   IN VARCHAR2)
  IS
    SELECT xmf.file_name  file_name
    FROM   xxccp_mrp_file_ul_interface  xmf
    WHERE  xmf.file_id           = in_file_id
    AND    xmf.file_content_type = iv_format
    ;
  -- アップロードファイル存在確認カーソルレコード型
  check_upload_file_rec  check_upload_file_cur%ROWTYPE;
--
-- ===============================
-- パッケージRECORD型
-- ===============================
  -- API戻り値レコード型
  TYPE save_cust_key_info_rtype IS RECORD (
    ln_cust_account_id          hz_cust_accounts.cust_account_id%TYPE              -- 退避_顧客アカウントID
   ,lv_account_number           hz_cust_accounts.account_number%TYPE               -- 退避_顧客コード
   ,ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE      -- 退避_顧客サイトID
   ,ln_party_id                 hz_parties.party_id%TYPE                           -- 退避_パーティID
   ,ln_party_site_id            hz_party_sites.party_site_id%TYPE                  -- 退避_パーティサイトID
   ,ln_location_id              hz_locations.location_id%TYPE                      -- 退避_事業所ID
   ,lv_status                   VARCHAR2(1)                                        -- 退避_ステータス
   ,ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE             -- 退避_請求先_使用目的ID
   ,lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE           -- 退避_請求先_使用目的
   ,ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE  -- 退避_顧客プロファイルID
   ,ln_ship_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE             -- 退避_出荷先_使用目的ID
   ,lv_ship_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE           -- 退避_出荷先_使用目的
   ,ln_other_to_site_use_id     hz_cust_site_uses_all.site_use_id%TYPE             -- 退避_その他_使用目的ID
   ,lv_other_to_site_use_code   hz_cust_site_uses_all.site_use_code%TYPE           -- 退避_その他_使用目的
  );
-- ===============================
-- パッケージTABLE型
-- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_id    IN  VARCHAR2          -- ファイルID
   ,iv_format     IN  VARCHAR2          -- フォーマット
   ,ov_errbuf     OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--#####################  固定ローカル変数宣言部 START   ########################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    cv_ccid          CONSTANT VARCHAR2(20) := 'CCID';                           -- CCID
    cv_hrrchy_name   CONSTANT VARCHAR2(20) := '自動消込基準01';                 -- 自動消込基準01
    cv_aut_hrrchy_id CONSTANT VARCHAR2(20) := '自動消込基準セットID';           -- 自動消込基準セットID
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(10);                                     -- ステップ
    lv_tkn_value              VARCHAR2(100);                                    -- トークン値
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM
    --
    lv_upload_obj             VARCHAR2(100);                                    -- ファイルアップロード名称
    lv_up_name                VARCHAR2(1000);                                   -- アップロード名称出力用
    lv_file_id                VARCHAR2(1000);                                   -- ファイルID出力用
    lv_file_format            VARCHAR2(1000);                                   -- フォーマット出力用
    lv_file_name              VARCHAR2(1000);                                   -- ファイル名出力用
    -- ファイルアップロードIFテーブル項目
    lv_csv_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;       -- ファイル名格納用
    ln_created_by             xxccp_mrp_file_ul_interface.created_by%TYPE;      -- 作成者格納用
    ld_creation_date          xxccp_mrp_file_ul_interface.creation_date%TYPE;   -- 作成日格納用
    ln_cnt                    NUMBER;                                           -- カウンタ
--
    -- *** ローカル・カーソル ***
    -- データ項目定義取得用カーソル
    CURSOR     get_def_info_cur
    IS
      SELECT   flv.meaning                         AS item_name                 -- 内容
              ,DECODE(flv.attribute1, cv_varchar ,cv_varchar_cd
                                    , cv_number  ,cv_number_cd
                                    , cv_date_cd)  AS item_attribute            -- 項目属性
              ,DECODE(flv.attribute2, cv_not_null, cv_null_ng
                                    , cv_null_ok)  AS item_essential            -- 必須フラグ
              ,TO_NUMBER(flv.attribute3)           AS item_length               -- 項目の長さ(整数部分)
              ,TO_NUMBER(flv.attribute4)           AS decim                     -- 項目の長さ(小数点以下)
      FROM     fnd_lookup_values_vl  flv                                        -- LOOKUP表
      -- フォーマットパターン「501:MC顧客」の場合
      WHERE  ((gv_format = cv_file_format_mc
        AND      flv.lookup_type = cv_lookup_cust_def_mc)                       -- 顧客一括登録データ項目定義(MC顧客)
      -- フォーマットパターン「502:店舗営業」の場合
      OR      (gv_format = cv_file_format_st
        AND      flv.lookup_type = cv_lookup_cust_def_st)                       -- 顧客一括登録データ項目定義(店舗営業)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      -- フォーマットパターン「503:法人」の場合
      OR      ( gv_format       = cv_file_format_ho
        AND     flv.lookup_type = cv_lookup_cust_def_ho )                      -- 顧客一括登録データ項目定義(法人)
      -- フォーマットパターン「504:売掛管理」の場合
      OR      ( gv_format       = cv_file_format_ur
        AND     flv.lookup_type = cv_lookup_cust_def_ur ) )                    -- 顧客一括登録データ項目定義(売掛管理)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      AND      flv.enabled_flag = cv_yes                                        -- 使用可能フラグ
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- 適用開始日
      AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date   -- 適用終了日
      ORDER BY flv.lookup_code;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_param_expt            EXCEPTION;                              -- パラメータNULLエラー
    get_profile_expt          EXCEPTION;                              -- プロファイル取得エラー
    process_date_expt         EXCEPTION;                              -- 業務日付取得失敗エラー
    select_expt               EXCEPTION;                              -- 取得失敗エラー
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
    -- A-1.1 入力パラメータ（FILE_ID、フォーマット）のNULLチェック
    --==============================================================
    lv_step := 'A-1.1';
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_file_id;
      RAISE get_param_expt;
    END IF;
    -- 入力パラメータがNULLの場合
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_format;
      RAISE get_param_expt;
    END IF;
    --
    -- INパラメータを格納
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- A-1.2 プロファイル取得
    --==============================================================
    lv_step := 'A-1.2';
    -- XXCMM:顧客一括登録管理者職責キー
    gt_mgr_resp_key := FND_PROFILE.VALUE(cv_prf_resp_key);
    -- 取得エラー時
    IF ( gt_mgr_resp_key IS NULL ) THEN
      lv_tkn_value := cv_prf_resp_key_n;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:顧客一括登録データ項目数(MC顧客)
    -- フォーマットパターン「501:MC顧客」の場合
    IF ( gv_format = cv_file_format_mc ) THEN
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_mc));
      -- 取得エラー時
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_prf_item_num_mc_n;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
    -- XXCMM:顧客一括登録データ項目数(店舗営業)
    -- フォーマットパターン「502:店舗営業」の場合
    IF ( gv_format = cv_file_format_st ) THEN
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_st));
      -- 取得エラー時
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_prf_item_num_st_n;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- XXCMM:顧客一括登録データ項目数(法人顧客)
    -- フォーマットパターン「503:法人顧客」の場合
    IF ( gv_format = cv_file_format_ho ) THEN
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_ho));
      -- 取得エラー時
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_prf_item_num_ho_n;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
    -- XXCMM:顧客一括登録データ項目数(売掛管理先顧客)
    -- フォーマットパターン「504:売掛管理先顧客」の場合
    IF ( gv_format = cv_file_format_ur ) THEN
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_ur));
      -- 取得エラー時
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_prf_item_num_ur_n;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    -- XXCMM:請求書出力形式初期値
    gv_output_form := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_output_form));
    -- 取得エラー時
    IF ( gv_output_form IS NULL ) THEN
      lv_tkn_value := cv_prf_output_form_n;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:請求書発行サイクル初期値
    gv_prt_cycle := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_prt_cycle));
    -- 取得エラー時
    IF ( gv_prt_cycle IS NULL ) THEN
      lv_tkn_value := cv_prf_prt_cycle_n;
      RAISE get_profile_expt;
    END IF;
    -- XXCMM:請求書印刷単位初期値
    gv_inv_unit := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_inv_unit));
    -- 取得エラー時
    IF ( gv_inv_unit IS NULL ) THEN
      lv_tkn_value := cv_prf_inv_unit_n;
      RAISE get_profile_expt;
    END IF;
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- フォーマットパターン「504:売掛管理先顧客」の場合
    IF ( gv_format = cv_file_format_ur ) THEN
      --会計帳簿ID
      gt_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_set_of_bks_id));
      -- 取得エラー時
      IF ( gt_set_of_bks_id IS NULL ) THEN
        lv_tkn_value := cv_prf_set_of_bks_id_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- 顧客一括登録（売掛管理先顧客）用_会社
      gt_ur_kaisya := FND_PROFILE.VALUE(cv_prf_ur_kaisya);
      -- 取得エラー時
      IF ( gt_ur_kaisya IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_kaisya_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- 顧客一括登録（売掛管理先顧客）用_部門
      gt_ur_bumon := FND_PROFILE.VALUE(cv_prf_ur_bumon);
      -- 取得エラー時
      IF ( gt_ur_bumon IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_bumon_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- 顧客一括登録（売掛管理先顧客）用_勘定科目
      gt_ur_kanjyou := FND_PROFILE.VALUE(cv_prf_ur_kanjyou);
      -- 取得エラー時
      IF ( gt_ur_kanjyou IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_kanjyou_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- 顧客一括登録（売掛管理先顧客）用_補助科目
      gt_ur_hojyo := FND_PROFILE.VALUE(cv_prf_ur_hojyo);
      -- 取得エラー時
      IF ( gt_ur_hojyo IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_hojyo_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- 顧客一括登録（売掛管理先顧客）用_顧客コード
      gt_ur_kokyaku := FND_PROFILE.VALUE(cv_prf_ur_kokyaku);
      -- 取得エラー時
      IF ( gt_ur_kokyaku IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_kokyaku_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- 顧客一括登録（売掛管理先顧客）用_企業コード
      gt_ur_kigyou := FND_PROFILE.VALUE(cv_prf_ur_kigyou);
      -- 取得エラー時
      IF ( gt_ur_kigyou IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_kigyou_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- 顧客一括登録（売掛管理先顧客）用_予備１
      gt_ur_yobi1 := FND_PROFILE.VALUE(cv_prf_ur_yobi1);
      -- 取得エラー時
      IF ( gt_ur_yobi1 IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_yobi1_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- 顧客一括登録（売掛管理先顧客）用_予備２
      gt_ur_yobi2 := FND_PROFILE.VALUE(cv_prf_ur_yobi2);
      -- 取得エラー時
      IF ( gt_ur_yobi2 IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_yobi2_n;
        RAISE get_profile_expt;
      END IF;
      --
    END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    --
    --==============================================================
    -- A-1.3 業務日付の取得
    --==============================================================
    lv_step := 'A-1.3';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- NULLチェック
    IF ( gd_process_date IS NULL ) THEN
      RAISE process_date_expt;
    END IF;
    --
    --==============================================================
    -- A-1.4 顧客一括登録ワーク定義情報の取得
    --==============================================================
    lv_step := 'A-1.4';
    BEGIN
      -- 変数の初期化
      ln_cnt := 0;
      -- テーブル定義取得LOOP
      <<def_info_loop>>
      FOR get_def_info_rec IN get_def_info_cur LOOP
        ln_cnt := ln_cnt + 1;
        g_item_def_tab(ln_cnt).item_name      := get_def_info_rec.item_name;       -- 項目名
        g_item_def_tab(ln_cnt).item_attribute := get_def_info_rec.item_attribute;  -- 項目属性
        g_item_def_tab(ln_cnt).item_essential := get_def_info_rec.item_essential;  -- 必須フラグ
        g_item_def_tab(ln_cnt).item_length    := get_def_info_rec.item_length;     -- 項目の長さ(整数部分)
        g_item_def_tab(ln_cnt).decim          := get_def_info_rec.decim;           -- 項目の長さ(小数点以下)
      END LOOP def_info_loop
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value := cv_upload_def_info;
        RAISE select_expt;
    END;
    --
    --==============================================================
    -- A-1.5 ファイルアップロード名称取得
    --==============================================================
    lv_step := 'A-1.5';
    BEGIN
      SELECT   flv.meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv
      WHERE    flv.lookup_type  = cv_file_upload_obj                            -- ファイルアップロードオブジェクト
      AND      flv.lookup_code  = gv_format                                     -- ファイルフォーマット
      AND      flv.enabled_flag = cv_yes                                        -- 使用可能フラグ
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- 適用開始日
      AND      NVL(flv.end_date_active,   gd_process_date) >= gd_process_date   -- 適用終了日
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value := cv_file_upload_name;
        RAISE select_expt;
    END;
    --
    --==============================================================
    -- A-1.6 CSVファイル情報の取得＆ロック取得
    --==============================================================
    lv_step := 'A-1.6';
    SELECT   fui.file_name                                                      -- ファイル名
            ,fui.created_by                                                     -- 作成者
            ,fui.creation_date                                                  -- 作成日
    INTO     lv_csv_file_name
            ,ln_created_by
            ,ld_creation_date
    FROM     xxccp_mrp_file_ul_interface  fui                                   -- ファイルアップロードIFテーブル
    WHERE    fui.file_id           = gn_file_id                                 -- ファイルID
      AND    fui.file_content_type = gv_format                                  -- ファイルフォーマット
    FOR UPDATE NOWAIT
    ;
--
    --==============================================================
    -- A-1.7 EBSログインユーザー職責キー取得
    --==============================================================
    lv_step := 'A-1.7';
    -- 職責IDを取得
    gn_resp_id      := fnd_profile.value(cv_prf_resp_id);
    -- 職責アプリケーションIDを取得
    gn_resp_appl_id := fnd_global.resp_appl_id;
--
    -- EBSログインユーザの職責キー取得
    SELECT  fr.responsibility_key                             -- 職責キー
    INTO    gt_responsibility_key                             -- 職責キー
    FROM    fnd_responsibility fr                             -- 職責マスタ
    WHERE   fr.responsibility_id  = gn_resp_id
    AND     fr.application_id     = gn_resp_appl_id;          -- 職責アプリケーションID
--
    -- NULLチェック
    IF ( gt_responsibility_key IS NULL ) THEN
      lv_tkn_value := cv_user_resp_key;
      RAISE select_expt;
    END IF;
--
    --==============================================================
    -- A-1.8 営業OUの組織ID取得
    --==============================================================
    lv_step := 'A-1.8';
    -- 営業OUの組織ID取得
      SELECT haou.organization_id                               -- 営業組織ID
      INTO   gv_sal_org_id
      FROM   hr_all_organization_units haou                     -- 人事組織マスタテーブル
      WHERE  haou.name = cv_sales_ou
      AND    ROWNUM    = 1
      ;
--
    -- NULLチェック
    IF ( gv_sal_org_id IS NULL ) THEN
      lv_tkn_value := cv_sal_org_id;
      RAISE select_expt;
    END IF;
-- 
    --==============================================================
    -- A-1.9 所属拠点コード取得
    --==============================================================
    lv_step := 'A-1.9';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- フォーマットパターン「501:MC顧客」、「502:店舗営業」の場合
    IF ( gv_format IN ( cv_file_format_mc , cv_file_format_st )) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      -- 拠点担当者の場合、所属拠点コードを取得
      IF ( gt_responsibility_key <> gt_mgr_resp_key ) THEN
        -- EBSログインユーザーIDを取得
        gn_user_id  := fnd_global.user_id;
  --
        -- EBSログインユーザーIDから所属拠点コード取得
        SELECT   paaf.ass_attribute5                                      -- 所属コード(新)
        INTO     gt_belong_base_code                                      -- 拠点コード
        FROM     per_all_people_f       papf                              -- 従業員マスタ
                ,per_all_assignments_f  paaf                              -- アサイメントマスタ
                ,fnd_user               fu                                -- ユーザーマスタ
        WHERE    fu.user_id           = gn_user_id
        AND      fu.employee_id       = papf.person_id
        AND      papf.person_id       = paaf.person_id
        AND      TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                                    AND TRUNC(papf.effective_end_date)
        AND      TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date)
                                    AND TRUNC(paaf.effective_end_date);
        -- NULLチェック
        IF ( gt_belong_base_code IS NULL ) THEN
          lv_tkn_value := cv_belong_base_code;
          RAISE select_expt;
        END IF;
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- フォーマットパターン「504:売掛管理先顧客」の場合
    IF ( gv_format = cv_file_format_ur ) THEN
      --==============================================================
      -- A-1.10 CCID取得
      --==============================================================
      lv_step := 'A-1.10';
      -- A-1-2で取得した会計帳簿IDからCCIDを取得
      BEGIN
        SELECT glcc.code_combination_id code_combination_id
        INTO   gt_urikake_misyuukin_id
        FROM   gl_code_combinations glcc   -- CCID情報
              ,gl_sets_of_books     gsob   -- 勘定科目組合せ
        WHERE  gsob.set_of_books_id      = gt_set_of_bks_id           -- 会計帳簿ID
        AND    glcc.chart_of_accounts_id = gsob.chart_of_accounts_id  --勘定科目組合せID
        AND    glcc.segment1             = gt_ur_kaisya
        AND    glcc.segment2             = gt_ur_bumon
        AND    glcc.segment3             = gt_ur_kanjyou
        AND    glcc.segment4             = gt_ur_hojyo
        AND    glcc.segment5             = gt_ur_kokyaku
        AND    glcc.segment6             = gt_ur_kigyou
        AND    glcc.segment7             = gt_ur_yobi1
        AND    glcc.segment8             = gt_ur_yobi2
        AND    gd_process_date BETWEEN NVL( glcc.start_date_active, gd_process_date )
                               AND     NVL( glcc.end_date_active,   gd_process_date )
        AND    glcc.enabled_flag         =  cv_yes
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_value := cv_ccid;
          RAISE select_expt;
      END;
      --
      --==============================================================
      -- A-1.11 自動消込基準セットID取得
      --==============================================================
      lv_step := 'A-1.11';
      BEGIN
        SELECT aah.autocash_hierarchy_id autocash_hierarchy_id
        INTO   gt_autocash_hierarchy_id
        FROM   ar_autocash_hierarchies aah
        WHERE  aah.hierarchy_name  =  cv_hrrchy_name
        AND    aah.status          =  cv_a             -- 有効
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_value := cv_aut_hrrchy_id;
          RAISE select_expt;
      END;
    --
    END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    --
    --==============================================================
    -- A-1.12 INパラメータの出力
    --==============================================================
    lv_step := 'A-1.12';
    lv_up_name     := xxccp_common_pkg.get_msg(                                 -- アップロード名称の出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00021                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_up_name                       -- トークンコード1
                       ,iv_token_value1 => lv_upload_obj                        -- トークン値1
                      );
    lv_file_name   := xxccp_common_pkg.get_msg(                                 -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00022                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_name                     -- トークンコード1
                       ,iv_token_value1 => lv_csv_file_name                     -- トークン値1
                      );
    lv_file_id     := xxccp_common_pkg.get_msg(                                 -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00023                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_id                       -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(gn_file_id)                  -- トークン値1
                      );
    lv_file_format := xxccp_common_pkg.get_msg(                                 -- フォーマットの出力
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00024                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_format                    -- トークンコード1
                      ,iv_token_value1 => gv_format                             -- トークン値1
                      );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT                                 -- 出力に表示
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG                                    -- ログに表示
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
    --*** パラメータNULLエラー ***
    WHEN get_param_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10323            -- メッセージ
                    ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** プロファイル取得エラー ***
    WHEN get_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00002            -- メッセージ
                    ,iv_token_name1  => cv_tkn_ng_profile             -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** 業務日付取得失敗エラー ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00018            -- メッセージ
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** 取得失敗エラー ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10324            -- メッセージ
                    ,iv_token_name1  => cv_tkn_value                  -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10337            -- メッセージ
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : validate_cust_wk
   * Description      : 顧客一括登録ワークデータ妥当性チェック (A-4)
   ***********************************************************************************/
  PROCEDURE validate_cust_wk(
    i_wk_cust_rec  IN  xxcmm_wk_cust_upload%ROWTYPE                        -- 顧客一括登録ワーク情報
   ,ov_errbuf      OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_cust_wk';              -- プログラム名
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    lv_tkn_value              VARCHAR2(100);                          -- トークン値
    ln_cnt                    NUMBER;                                 -- カウント用
    lv_check_status           VARCHAR2(1);                            -- チェックステータス
    lv_check_flag             VARCHAR2(1);                            -- チェックフラグ
    l_validate_cust_tab       g_check_data_ttype;
    --
    ln_check_cnt              NUMBER;
    lv_required_item          VARCHAR2(2000);
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM変数退避用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- チェックステータスの初期化
    lv_check_status := cv_status_normal;
    --==============================================================
    -- メイン処理LOOP
    --==============================================================
    lv_step := 'A-4.1';
    --
    -- フォーマットパターン「501:MC顧客」の場合
    IF ( gv_format = cv_file_format_mc ) THEN
      l_validate_cust_tab(1)  := i_wk_cust_rec.customer_name;                         -- 顧客名
      l_validate_cust_tab(2)  := i_wk_cust_rec.customer_name_kana;                    -- 顧客名カナ
      l_validate_cust_tab(3)  := i_wk_cust_rec.customer_name_ryaku;                   -- 略称
      l_validate_cust_tab(4)  := i_wk_cust_rec.customer_status;                       -- 顧客ステータス
      l_validate_cust_tab(5)  := i_wk_cust_rec.sale_base_code;                        -- 売上拠点
      l_validate_cust_tab(6)  := i_wk_cust_rec.sales_chain_code;                      -- 販売先チェーン
      l_validate_cust_tab(7)  := i_wk_cust_rec.delivery_chain_code;                   -- 納品先チェーン
      l_validate_cust_tab(8)  := i_wk_cust_rec.postal_code;                           -- 郵便番号
      l_validate_cust_tab(9)  := i_wk_cust_rec.state;                                 -- 都道府県
      l_validate_cust_tab(10) := i_wk_cust_rec.city;                                  -- 市・区
      l_validate_cust_tab(11) := i_wk_cust_rec.address1;                              -- 住所１
      l_validate_cust_tab(12) := i_wk_cust_rec.address2;                              -- 住所２
      l_validate_cust_tab(13) := i_wk_cust_rec.address3;                              -- 地区コード
      l_validate_cust_tab(14) := i_wk_cust_rec.tel_no;                                -- 電話番号
      l_validate_cust_tab(15) := i_wk_cust_rec.fax;                                   -- FAX
      l_validate_cust_tab(16) := i_wk_cust_rec.business_low_type_tmp;                 -- 業態小分類(仮)
      l_validate_cust_tab(17) := i_wk_cust_rec.manager_name;                          -- 店長名
      l_validate_cust_tab(18) := i_wk_cust_rec.emp_number;                            -- 社員数
      l_validate_cust_tab(19) := i_wk_cust_rec.rest_emp_name;                         -- 担当者休日
      l_validate_cust_tab(20) := i_wk_cust_rec.mc_hot_deg;                            -- MC：HOT度
      l_validate_cust_tab(21) := i_wk_cust_rec.mc_importance_deg;                     -- MC：重要度
      l_validate_cust_tab(22) := i_wk_cust_rec.mc_conf_info;                          -- MC：競合情報
      l_validate_cust_tab(23) := i_wk_cust_rec.mc_business_talk_details;              -- MC：商談経緯
      l_validate_cust_tab(24) := i_wk_cust_rec.resource_no;                           -- 担当営業員
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 delete start by Shigeto.Niki
--      l_validate_cust_tab(25) := i_wk_cust_rec.resource_s_date;                       -- 適用開始日(担当営業員)
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 delete end by Shigeto.Niki
    --
    -- フォーマットパターン「502:店舗営業」の場合
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
    --ELSE
    ELSIF ( gv_format = cv_file_format_st ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
      l_validate_cust_tab(1)  := i_wk_cust_rec.customer_name;                         -- 顧客名
      l_validate_cust_tab(2)  := i_wk_cust_rec.customer_name_kana;                    -- 顧客名カナ
      l_validate_cust_tab(3)  := i_wk_cust_rec.customer_name_ryaku;                   -- 略称
      l_validate_cust_tab(4)  := i_wk_cust_rec.customer_class_code;                   -- 顧客区分
      l_validate_cust_tab(5)  := i_wk_cust_rec.customer_status;                       -- 顧客ステータス
      l_validate_cust_tab(6)  := i_wk_cust_rec.sale_base_code;                        -- 売上拠点
      l_validate_cust_tab(7)  := i_wk_cust_rec.sales_chain_code;                      -- 販売先チェーン
      l_validate_cust_tab(8)  := i_wk_cust_rec.delivery_chain_code;                   -- 納品先チェーン
      l_validate_cust_tab(9)  := i_wk_cust_rec.postal_code;                           -- 郵便番号
      l_validate_cust_tab(10) := i_wk_cust_rec.state;                                 -- 都道府県
      l_validate_cust_tab(11) := i_wk_cust_rec.city;                                  -- 市・区
      l_validate_cust_tab(12) := i_wk_cust_rec.address1;                              -- 住所１
      l_validate_cust_tab(13) := i_wk_cust_rec.address2;                              -- 住所２
      l_validate_cust_tab(14) := i_wk_cust_rec.address3;                              -- 地区コード
      l_validate_cust_tab(15) := i_wk_cust_rec.tel_no;                                -- 電話番号
      l_validate_cust_tab(16) := i_wk_cust_rec.fax;                                   -- FAX
      l_validate_cust_tab(17) := i_wk_cust_rec.business_low_type;                     -- 業態小分類
      l_validate_cust_tab(18) := i_wk_cust_rec.industry_div;                          -- 業種
      l_validate_cust_tab(19) := i_wk_cust_rec.torihiki_form;                         -- 取引形態
      l_validate_cust_tab(20) := i_wk_cust_rec.delivery_form;                         -- 配送形態
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- フォーマットパターン「503:法人」の場合
    ELSIF ( gv_format = cv_file_format_ho ) THEN
      l_validate_cust_tab(1)  := i_wk_cust_rec.customer_name;                         -- 顧客名
      l_validate_cust_tab(2)  := i_wk_cust_rec.customer_name_kana;                    -- 顧客名カナ
      l_validate_cust_tab(3)  := i_wk_cust_rec.customer_name_ryaku;                   -- 略称
      l_validate_cust_tab(4)  := i_wk_cust_rec.customer_class_code;                   -- 顧客区分
      l_validate_cust_tab(5)  := i_wk_cust_rec.customer_status;                       -- 顧客ステータス
      l_validate_cust_tab(6)  := i_wk_cust_rec.sale_base_code;                        -- 売上拠点
      l_validate_cust_tab(7)  := i_wk_cust_rec.postal_code;                           -- 郵便番号
      l_validate_cust_tab(8)  := i_wk_cust_rec.state;                                 -- 都道府県
      l_validate_cust_tab(9)  := i_wk_cust_rec.city;                                  -- 市・区
      l_validate_cust_tab(10) := i_wk_cust_rec.address1;                              -- 住所１
      l_validate_cust_tab(11) := i_wk_cust_rec.address2;                              -- 住所２
      l_validate_cust_tab(12) := i_wk_cust_rec.address3;                              -- 地区コード
      l_validate_cust_tab(13) := i_wk_cust_rec.tel_no;                                -- 電話番号
      l_validate_cust_tab(14) := i_wk_cust_rec.fax;                                   -- FAX
      l_validate_cust_tab(15) := i_wk_cust_rec.tdb_code;                              -- TDBコード
      l_validate_cust_tab(16) := i_wk_cust_rec.base_code;                             -- 本部担当拠点
      l_validate_cust_tab(17) := i_wk_cust_rec.credit_limit;                          -- 与信限度額
      l_validate_cust_tab(18) := i_wk_cust_rec.decide_div;                            -- 判定区分
      l_validate_cust_tab(19) := i_wk_cust_rec.approval_date;                         -- 決裁日付
    --
    -- フォーマットパターン「504:売掛管理」の場合
    ELSIF ( gv_format = cv_file_format_ur ) THEN
      l_validate_cust_tab(1)  := i_wk_cust_rec.customer_name;                         -- 顧客名
      l_validate_cust_tab(2)  := i_wk_cust_rec.customer_name_kana;                    -- 顧客名カナ
      l_validate_cust_tab(3)  := i_wk_cust_rec.customer_name_ryaku;                   -- 略称
      l_validate_cust_tab(4)  := i_wk_cust_rec.customer_class_code;                   -- 顧客区分
      l_validate_cust_tab(5)  := i_wk_cust_rec.customer_status;                       -- 顧客ステータス
      l_validate_cust_tab(6)  := i_wk_cust_rec.sale_base_code;                        -- 売上拠点
      l_validate_cust_tab(7)  := i_wk_cust_rec.sales_chain_code;                      -- 販売先チェーン
      l_validate_cust_tab(8)  := i_wk_cust_rec.delivery_chain_code;                   -- 納品先チェーン
      l_validate_cust_tab(9)  := i_wk_cust_rec.postal_code;                           -- 郵便番号
      l_validate_cust_tab(10) := i_wk_cust_rec.state;                                 -- 都道府県
      l_validate_cust_tab(11) := i_wk_cust_rec.city;                                  -- 市・区
      l_validate_cust_tab(12) := i_wk_cust_rec.address1;                              -- 住所１
      l_validate_cust_tab(13) := i_wk_cust_rec.address2;                              -- 住所２
      l_validate_cust_tab(14) := i_wk_cust_rec.address3;                              -- 地区コード
      l_validate_cust_tab(15) := i_wk_cust_rec.tel_no;                                -- 電話番号
      l_validate_cust_tab(16) := i_wk_cust_rec.fax;                                   -- FAX
      l_validate_cust_tab(17) := i_wk_cust_rec.business_low_type;                     -- 業態小分類
      l_validate_cust_tab(18) := i_wk_cust_rec.industry_div;                          -- 業種
      l_validate_cust_tab(19) := i_wk_cust_rec.tax_div;                               -- 消費税区分
      l_validate_cust_tab(20) := i_wk_cust_rec.tax_rounding_rule;                     -- 税金端数処理
      l_validate_cust_tab(21) := i_wk_cust_rec.invoice_grp_code;                      -- 売掛コード1（請求書）
      l_validate_cust_tab(22) := i_wk_cust_rec.output_form;                           -- 請求書出力形式
      l_validate_cust_tab(23) := i_wk_cust_rec.prt_cycle;                             -- 請求書発行サイクル
      l_validate_cust_tab(24) := i_wk_cust_rec.payment_term;                          -- 支払条件
      l_validate_cust_tab(25) := i_wk_cust_rec.delivery_base_code;                    -- 納品拠点
      l_validate_cust_tab(26) := i_wk_cust_rec.bill_base_code;                        -- 請求拠点
      l_validate_cust_tab(27) := i_wk_cust_rec.receiv_base_code;                      -- 入金拠点
      l_validate_cust_tab(28) := i_wk_cust_rec.sales_head_base_code;                  -- 販売先本部担当拠点
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    END IF;
    --
    -- カウンタの初期化
    ln_check_cnt := 0;
    --
    <<validate_column_loop>>
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      -- カウンタを加算
      ln_check_cnt := ln_check_cnt + 1;
      --
      lv_step := 'A-4.1～3';
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => g_item_def_tab(ln_check_cnt).item_name                   -- 項目名称
       ,iv_item_value   => l_validate_cust_tab(ln_check_cnt)                        -- 項目の値
       ,in_item_len     => g_item_def_tab(ln_check_cnt).item_length                 -- 項目の長さ(整数部分)
       ,in_item_decimal => g_item_def_tab(ln_check_cnt).decim                       -- 項目の長さ（小数点以下）
       ,iv_item_nullflg => g_item_def_tab(ln_check_cnt).item_essential              -- 必須フラグ
       ,iv_item_attr    => g_item_def_tab(ln_check_cnt).item_attribute              -- 項目の属性
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN                                    -- 戻り値が異常の場合
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        gv_out_msg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_10338                    -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_line_no                  -- トークンコード1
                        ,iv_token_value1  =>  i_wk_cust_rec.line_no                 -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_errmsg                         -- トークンコード2
                        ,iv_token_value2  =>  LTRIM(lv_errmsg)                      -- トークン値2
                       );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END LOOP validate_column_loop;
--
    -- 適用開始日をDATE型に変換
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 delete start by Shigeto.Niki
--    gd_apply_date := TO_DATE(i_wk_cust_rec.resource_s_date, cv_date_fmt_std);
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 delete end by Shigeto.Niki
--
    IF ( lv_check_status = cv_status_normal ) THEN
      --==============================================================
      -- A-4.2 顧客名チェック
      --==============================================================
      lv_step := 'A-4.2';
      -- 全角文字チェック
      IF ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.customer_name ) <> TRUE ) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 全角文字チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10326          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                -- トークンコード1
                      ,iv_token_value1 => cv_customer_name            -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.customer_name -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no        -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no       -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.3 略称チェック
      --==============================================================
      lv_step := 'A-4.3';
      -- 全角文字チェック
      IF ( i_wk_cust_rec.customer_name_ryaku IS NOT NULL ) 
        AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.customer_name_ryaku ) <> TRUE ) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 全角チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10326                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_customer_name_ryaku                -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.customer_name_ryaku     -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.4 顧客名（カナ）チェック
      --==============================================================
      lv_step := 'A-4.4';
      -- 半角文字チェック
      IF ( i_wk_cust_rec.customer_name_kana IS NOT NULL )
        AND ( xxccp_common_pkg.chk_single_byte( i_wk_cust_rec.customer_name_kana ) <> TRUE ) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 半角文字チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10327                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_customer_name_kana                 -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.customer_name_kana      -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.5 顧客区分チェック
      --==============================================================
      lv_step := 'A-4.5';
      -- 顧客区分チェック
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
--      IF ( gv_format = cv_file_format_st )
--        AND ( i_wk_cust_rec.customer_class_code <> cv_tenpo_kbn ) THEN
      -- フォーマットパターン「502:店舗営業」の場合、「15:店舗営業」のみ許容
      IF ( ( gv_format = cv_file_format_st ) AND ( i_wk_cust_rec.customer_class_code <> cv_tenpo_kbn ) )
        OR
      -- フォーマットパターン「503:法人」の場合、「13:法人」のみ許容
         ( ( gv_format = cv_file_format_ho ) AND ( i_wk_cust_rec.customer_class_code <> cv_hojin_kbn ) )
        OR
      -- フォーマットパターン「504:売掛管理」の場合、「14:売掛管理」のみ許容
         ( ( gv_format = cv_file_format_ur ) AND ( i_wk_cust_rec.customer_class_code <> cv_urikake_kbn ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 値チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10328                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_customer_class_code                -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.customer_class_code     -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.6 顧客ステータスチェック
      --==============================================================
      lv_step := 'A-4.6';
      -- 顧客ステータスチェック
      -- フォーマットパターン「501:MC顧客」の場合、「10:MC候補」「20:MC」のみ許容
      IF (( gv_format = cv_file_format_mc ) AND ( i_wk_cust_rec.customer_status NOT IN ( cv_cust_status_mc_cand, cv_cust_status_mc )))
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
        ---- フォーマットパターン「502:店舗営業」の場合、「99:対象外」のみ許容
        --OR (( gv_format = cv_file_format_st ) AND ( i_wk_cust_rec.customer_status <> cv_cust_status_except )) THEN
        -- フォーマットパターン「502:店舗営業」、「503:法人」、「504:売掛管理」の場合、「99:対象外」のみ許容
        OR ( ( gv_format IN ( cv_file_format_st , cv_file_format_ho , cv_file_format_ur ) )
             AND ( i_wk_cust_rec.customer_status <> cv_cust_status_except ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 値チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10328                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_customer_status                    -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.customer_status         -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.7 売上拠点チェック
      --==============================================================
      lv_step := 'A-4.7';
      -- 売上拠点存在チェック
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   fnd_flex_value_sets ffvs                                           -- 値セット定義マスタ
            ,fnd_flex_values     ffv                                            -- 値セットマスタ
      WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- 値セットID
      AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF部門(XX03_DEPARTMENT)
      AND    ffv.summary_flag         = cv_no                                   -- 子値
      AND    ffv.flex_value           = i_wk_cust_rec.sale_base_code            -- 売上拠点
      ;
      IF (ln_cnt = 0) THEN
        lv_check_status   := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 売上拠点存在チェックエラーメッセージ取得
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10329                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_sale_base_code                     -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.sale_base_code          -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.8 自拠点判定
      --==============================================================
      lv_step := 'A-4.8';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      -- フォーマットパターン「501:MC顧客」、「502:店舗営業」の場合
      IF ( gv_format IN ( cv_file_format_mc , cv_file_format_st )) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        -- 拠点担当者の場合、自拠点判定を行なう
        IF ( gt_responsibility_key <> gt_mgr_resp_key ) THEN
          SELECT COUNT(1)
          INTO   ln_cnt
          FROM   xxcmm_cust_accounts xca                                            -- 顧客追加情報マスタ
          WHERE  xca.sale_base_code = i_wk_cust_rec.sale_base_code
          AND    (EXISTS (SELECT 'X'
                          FROM   hz_cust_accounts    hca1                           -- 顧客マスタ
                                ,xxcmm_cust_accounts xca1                           -- 顧客追加情報マスタ
                          WHERE  hca1.cust_account_id      = xca1.customer_id
                            AND  hca1.cust_account_id      = xca.customer_id
                            AND  hca1.customer_class_code  = cv_base_kbn
                            AND  xca1.sale_base_code       = gt_belong_base_code
                         )
                     OR EXISTS (SELECT 'X'
                                FROM   hz_cust_accounts    hca2                     -- 顧客マスタ
                                      ,xxcmm_cust_accounts xca2                     -- 顧客追加情報マスタ
                                WHERE  hca2.cust_account_id      = xca2.customer_id
                                  AND  hca2.cust_account_id      = xca.customer_id
                                  AND  hca2.customer_class_code  = cv_base_kbn
                                  AND  xca2.sale_base_code
                                   IN  (SELECT  hca3.account_number
                                         FROM   hz_cust_accounts    hca3            -- 顧客マスタ
                                               ,xxcmm_cust_accounts xca3            -- 顧客追加情報マスタ
                                         WHERE  hca3.cust_account_id      = xca3.customer_id
                                           AND  hca3.customer_class_code  = cv_base_kbn
                                           AND  xca3.management_base_code = gt_belong_base_code
                                       )
                               )
                 )
           AND   ROWNUM = 1;
          -- 自拠点判定エラーメッセージ取得
          IF (ln_cnt = 0) THEN
            lv_check_status   := cv_status_error;
            ov_retcode        := cv_status_error;
            -- 自拠点判定エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_10325                    -- メッセージコード
                          ,iv_token_name1  => cv_tkn_input_line_no                  -- トークンコード1
                          ,iv_token_value1 => i_wk_cust_rec.line_no                 -- トークン値1
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
            --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      --
      --==============================================================
      -- A-4.9 販売先チェーンチェック
      --==============================================================
      lv_step := 'A-4.9';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      -- フォーマットパターン「501:MC」、「502:店舗営業」、「504:売掛管理」の場合、販売先チェーン存在チェックを実施
      IF ( gv_format IN ( cv_file_format_mc , cv_file_format_st , cv_file_format_ur ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        -- 販売先チェーン存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_xxcmm_chain_code                         -- チェーン店コード
        AND    flv.lookup_code        = i_wk_cust_rec.sales_chain_code              -- 販売先チェーン
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --販売先チェーン存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_s_chain_code                       -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.sales_chain_code        -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      --
      --==============================================================
      -- A-4.10 納品先チェーンチェック
      --==============================================================
      lv_step := 'A-4.10';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      -- フォーマットパターン「501:MC」、「502:店舗営業」、「504:売掛管理」の場合、販売先チェーン存在チェックを実施
      IF ( gv_format IN ( cv_file_format_mc , cv_file_format_st , cv_file_format_ur ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        -- 納品先チェーン存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_xxcmm_chain_code                         -- チェーン店コード
        AND    flv.lookup_code        = i_wk_cust_rec.delivery_chain_code           -- 納品先チェーン
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --納品先チェーン存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_d_chain_code                       -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.delivery_chain_code     -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      --
      --==============================================================
      -- A-4.11 郵便番号チェック
      --==============================================================
      lv_step := 'A-4.11';
      -- 郵便番号半角数字7桁チェック
      IF (xxccp_common_pkg.chk_number(i_wk_cust_rec.postal_code) <> TRUE)
        OR (LENGTHB(i_wk_cust_rec.postal_code) <> 7)
      THEN
        lv_check_status   := cv_status_error;
        ov_retcode        := cv_status_error;
        -- 郵便番号チェックエラーメッセージ取得
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10331                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_postal_code                        -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.postal_code             -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.12 都道府県チェック
      --==============================================================
      lv_step := 'A-4.12';
      -- 全角文字チェック
      IF (xxccp_common_pkg.chk_double_byte(i_wk_cust_rec.state) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 全角チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10326                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_state                              -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.state                   -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.13 市・区チェック
      --==============================================================
      lv_step := 'A-4.13';
      -- 全角文字チェック
      IF (xxccp_common_pkg.chk_double_byte(i_wk_cust_rec.city) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 全角チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10326                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_city                               -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.city                    -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.14 住所１チェック
      --==============================================================
      lv_step := 'A-4.14';
      -- 全角文字チェック
      IF (xxccp_common_pkg.chk_double_byte(i_wk_cust_rec.address1) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 全角チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10326                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_address1                           -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.address1                -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.15 住所２チェック
      --==============================================================
      lv_step := 'A-4.15';
      -- 全角文字チェック
      IF ( i_wk_cust_rec.address2 IS NOT NULL ) 
        AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.address2 ) <> TRUE ) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 全角チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10326                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_address2                           -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.address2                -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.16 地区コードチェック
      --==============================================================
      lv_step := 'A-4.16';
      -- 地区コード存在チェック
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
      WHERE  flv.lookup_type        = cv_lookup_chiku_code                        -- 地区コード
      AND    flv.lookup_code        = i_wk_cust_rec.address3                      -- 地区コード
      AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
      AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
      AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
      --
      IF (ln_cnt = 0) THEN
        lv_check_status   := cv_status_error;
        ov_retcode        := cv_status_error;
        -- 地区コード存在チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_address3                           -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.address3                -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.17 電話番号チェック
      --==============================================================
      lv_step := 'A-4.17';
      -- 電話番号チェック
      IF (xxccp_common_pkg.chk_tel_format(i_wk_cust_rec.tel_no) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 電話番号チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10332                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_tel_no                             -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.tel_no                  -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.18 FAXチェック
      --==============================================================
      lv_step := 'A-4.18';
      -- FAXチェック
      IF ( i_wk_cust_rec.fax IS NOT NULL ) 
        AND (xxccp_common_pkg.chk_tel_format(i_wk_cust_rec.fax) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- 電話番号チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10332                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_fax                                -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_cust_rec.fax                     -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.19 業態小分類(仮)チェック
      --==============================================================
      lv_step := 'A-4.19';
      -- フォーマットパターン「501:MC顧客」の場合
      IF ( gv_format = cv_file_format_mc ) THEN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_gyotai_sho                        -- 業態小分類
        AND    flv.lookup_code        = i_wk_cust_rec.business_low_type_tmp         -- 業態小分類(仮)
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- 業態小分類(仮)存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_b_row_type_tmp                     -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.business_low_type_tmp   -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.20 店長名チェック
      --==============================================================
      lv_step := 'A-4.20';
      -- フォーマットパターン「501:MC顧客」かつ、値が入っている場合
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.manager_name IS NOT NULL )
          AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.manager_name ) <> TRUE ) THEN
          lv_check_status := cv_status_error;
          ov_retcode      := cv_status_error;
          -- 全角チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10326                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_manager_name                       -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.manager_name            -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.21 担当者休日チェック
      --==============================================================
      lv_step := 'A-4.21';
      -- フォーマットパターン「501:MC顧客」かつ、値が入っている場合
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.rest_emp_name IS NOT NULL )
          AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.rest_emp_name ) <> TRUE ) THEN
          lv_check_status := cv_status_error;
          ov_retcode      := cv_status_error;
          -- 全角チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10326                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_rest_emp_name                      -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.rest_emp_name           -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.22 MC:重要度チェック
      --==============================================================
      lv_step := 'A-4.22';
      -- フォーマットパターン「501:MC顧客」かつ、値が入っている場合
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.mc_importance_deg IS NOT NULL ) THEN
        -- MC:重要度存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_mcjuyodo                          -- MC:重要度
        AND    flv.lookup_code        = i_wk_cust_rec.mc_importance_deg             -- MC:重要度
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- MC:重要度存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_mc_importance_deg                  -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.mc_importance_deg       -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.23 MC:HOT度チェック
      --==============================================================
      lv_step := 'A-4.23';
      -- フォーマットパターン「501:MC顧客」かつ、値が入っている場合
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.mc_hot_deg IS NOT NULL ) THEN
        -- MC:HOT度存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_mchotdo                           -- MC:HOT度
        AND    flv.lookup_code        = i_wk_cust_rec.mc_hot_deg                    -- MC:HOT度
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- MC:HOT度存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_mc_hot_deg                         -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.mc_hot_deg              -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.24 MC:競合情報チェック
      --==============================================================
      lv_step := 'A-4.24';
      -- フォーマットパターン「501:MC顧客」かつ、値が入っている場合
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.mc_conf_info IS NOT NULL )
          AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.mc_conf_info ) <> TRUE ) THEN
          lv_check_status := cv_status_error;
          ov_retcode      := cv_status_error;
          -- 全角チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10326                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_mc_conf_info                       -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.mc_conf_info            -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.25 MC:商談経緯チェック
      --==============================================================
      lv_step := 'A-4.25';
      -- フォーマットパターン「501:MC顧客」かつ、値が入っている場合
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.mc_business_talk_details IS NOT NULL )
          AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.mc_business_talk_details ) <> TRUE ) THEN
          lv_check_status := cv_status_error;
          ov_retcode      := cv_status_error;
          -- 全角チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                     -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10326                     -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                           -- トークンコード1
                        ,iv_token_value1 => cv_mc_b_talk_details                   -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                           -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.mc_business_talk_details -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                   -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                  -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.26 担当営業員チェック
      --==============================================================
      lv_step := 'A-4.26-1';
      -- フォーマットパターン「501:MC顧客」の場合
      IF ( gv_format = cv_file_format_mc ) THEN
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify start by Shigeto.Niki
--        -- 開始日 < 業務日付の場合はエラー
--        IF (gd_apply_date < gd_process_date) THEN
--          lv_check_status   := cv_status_error;
--          ov_retcode        := cv_status_error;
--          -- 適用開始日入力チェックエラー
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
--                        ,iv_name         => cv_msg_xxcmm_10333                    -- メッセージコード
--                        ,iv_token_name1  => cv_tkn_input_line_no                  -- トークンコード1
--                        ,iv_token_value1 => i_wk_cust_rec.line_no                 -- トークン値1
--                        ,iv_token_name2  => cv_tkn_apply_date                     -- トークンコード2
--                        ,iv_token_value2 => gd_apply_date                         -- トークン値2
--                       );
--          -- メッセージ出力
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.OUTPUT
--            ,buff   => gv_out_msg);
--          lv_check_flag := cv_status_error;
--          --
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--          lv_check_flag := cv_status_error;
--        END IF;
--        --
--        -- フォーマットパターン「501:MC顧客」かつ、適用開始日 => 業務日付の場合、
--        -- 担当営業員のリソースマスタ存在チェックを実施する
--        lv_step := 'A-4.26-2';
--        -- 担当営業員存在チェック
--        SELECT COUNT(1)
--        INTO   ln_cnt
--        FROM   jtf_rs_resource_extns   jrre         -- リソースマスタ
--              ,xxcso_employees_v3      xev3         -- 従業員マスタ（最新）ビュー3
--        WHERE  jrre.source_number    = xev3.employee_number
--        AND    jrre.category         = cv_category
--        AND    gd_apply_date BETWEEN jrre.start_date_active
--                                 AND NVL(jrre.end_date_active, TO_DATE(cv_max_date, cv_date_fmt_std))
--        AND    xev3.employee_number  = i_wk_cust_rec.resource_no
--        ;
        -- 担当営業員存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   jtf_rs_resource_extns_vl  jrre         -- リソース
              ,jtf_rs_group_members      jrgm         -- リソースグループメンバー
              ,jtf_rs_groups_vl          jrgv         -- リソースグループ
              ,per_all_people_f          papf         -- 従業員マスタ
              ,per_all_assignments_f     paaf         -- アサインメントマスタ
              ,per_periods_of_service    ppos         -- 従業員サービス期間マスタ
        WHERE  papf.person_id               = jrre.source_id
        AND    papf.person_id               = paaf.person_id
        AND    papf.current_emp_or_apl_flag = cv_yes
        AND    paaf.period_of_service_id    = ppos.period_of_service_id
        AND    papf.effective_start_date    = ppos.date_start
        AND    ppos.actual_termination_date IS NULL
        AND    jrre.category                = cv_category
        AND    jrre.resource_id             = jrgm.resource_id
        AND    gd_process_date BETWEEN jrre.start_date_active 
                               AND NVL(jrre.end_date_active,TO_DATE(cv_max_date, cv_date_fmt_std))
        AND    jrgm.group_id                = jrgv.group_id
        AND    jrgm.delete_flag             = cv_no
        AND    gd_process_date BETWEEN jrgv.start_date_active 
                               AND NVL(jrgv.end_date_active,TO_DATE(cv_max_date, cv_date_fmt_std))
        AND    papf.employee_number         = i_wk_cust_rec.resource_no           -- 従業員番号
        AND    jrgv.attribute1              = i_wk_cust_rec.sale_base_code        -- 拠点コード
        AND    paaf.ass_attribute5          = i_wk_cust_rec.sale_base_code        -- 拠点コード
        ;
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify end by Shigeto.Niki
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- 担当営業員存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10334                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_value                          -- トークンコード1
                        ,iv_token_value1 => i_wk_cust_rec.resource_no             -- トークン値1
                        ,iv_token_name2  => cv_tkn_input_line_no                  -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.line_no                 -- トークン値2
                        ,iv_token_name3  => cv_tkn_apply_date                     -- トークンコード3
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify start by Shigeto.Niki
--                        ,iv_token_value3 => gd_apply_date                         -- トークン値3
-- 2012/11/13 Ver1.2 SCSK K.Furuyama mod start
--                        ,iv_token_value3 => gd_process_date                        -- トークン値3
                        ,iv_token_value3 => TO_CHAR( gd_process_date, cv_date_fmt_std )
                                                                                  -- トークン値3
-- 2012/11/13 Ver1.2 SCSK K.Furuyama mod end
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify end by Shigeto.Niki
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
        --
      END IF;
      --
      --==============================================================
      -- A-4.27 業態小分類チェック
      --==============================================================
      lv_step := 'A-4.27';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
      ---- フォーマットパターン「502:店舗営業」の場合
      --IF ( gv_format = cv_file_format_st ) THEN
      -- フォーマットパターン「502:店舗営業」もしくは「504:売掛管理」の場合
      IF ( gv_format IN ( cv_file_format_st , cv_file_format_ur ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_gyotai_sho                        -- 業態小分類
        AND    flv.lookup_code        = i_wk_cust_rec.business_low_type             -- 業態小分類
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- 業態小分類存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_gyotai_sho                         -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.business_low_type       -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.28 業種チェック
      --==============================================================
      lv_step := 'A-4.28';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
      ---- フォーマットパターン「502:店舗営業」の場合
      --IF ( gv_format = cv_file_format_st ) THEN
      -- フォーマットパターン「502:店舗営業」もしくは「504:売掛管理」の場合
      IF ( gv_format IN ( cv_file_format_st , cv_file_format_ur ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_gyosyu                            -- 業種
        AND    flv.lookup_code        = i_wk_cust_rec.industry_div                  -- 業種
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- 業種存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_industry_div                       -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.industry_div            -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.29 取引形態チェック
      --==============================================================
      lv_step := 'A-4.29';
      -- フォーマットパターン「502:店舗営業」の場合
      IF ( gv_format = cv_file_format_st ) THEN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_torihiki                          -- 取引形態
        AND    flv.lookup_code        = i_wk_cust_rec.torihiki_form                 -- 取引形態
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- 取引形態存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_torihiki_form                      -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.torihiki_form           -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.30 配送形態チェック
      --==============================================================
      lv_step := 'A-4.30';
      -- フォーマットパターン「502:店舗営業」の場合
      IF ( gv_format = cv_file_format_st ) THEN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_haiso                             -- 配送形態
        AND    flv.lookup_code        = i_wk_cust_rec.delivery_form                 -- 配送形態
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- 配送形態存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_delivery_form                      -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.delivery_form           -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      --==============================================================
      -- A-4.31 本部担当拠点チェック
      --==============================================================
      lv_step := 'A-4.31';
      -- フォーマットパターン「503:法人」の場合
      IF ( gv_format = cv_file_format_ho ) THEN
        -- 本部担当拠点チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- 値セット定義マスタ
              ,fnd_flex_values     ffv                                            -- 値セットマスタ
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- 値セットID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF部門(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- 子値
        AND    ffv.flex_value           = i_wk_cust_rec.base_code                 -- 本部担当拠点
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- 開始日
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- 終了日
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- 本部担当拠点チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10329                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_base_code                          -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.base_code               -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
    --
      --==============================================================
      -- A-4.32 判定区分チェック
      --==============================================================
      lv_step := 'A-4.32';
      -- フォーマットパターン「503:法人」の場合
      IF ( gv_format = cv_file_format_ho ) THEN
        -- 判定区分チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_sohyo_kbn                         -- 総評区分
        AND    flv.lookup_code        = i_wk_cust_rec.decide_div                    -- 判定区分
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --判定区分チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_decide_div                         -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.decide_div              -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.33 決裁日付チェック
      --==============================================================
      lv_step := 'A-4.33';
      -- フォーマットパターン「503:法人」の場合
      IF ( gv_format = cv_file_format_ho ) THEN
        -- 決裁日付が業務日付より過去の日付の場合
        IF ( TO_DATE(i_wk_cust_rec.approval_date, cv_date_fmt_std) < gd_process_date ) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --決裁日付チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10345                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_approval_date                  -- トークンコード1
                        ,iv_token_value1 => i_wk_cust_rec.approval_date           -- トークン値1
                        ,iv_token_name2  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value2 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.34 消費税区分存在チェック
      --==============================================================
      lv_step := 'A-4.34';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 消費税区分存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_syohizei_kbn                      -- 消費税区分
        AND    flv.lookup_code        = i_wk_cust_rec.tax_div                       -- 消費税区分
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --消費税区分存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_tax_div                            -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.tax_div                 -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.35 税金端数処理チェック
      --==============================================================
      lv_step := 'A-4.35';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 税金端数処理チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_tax_rule                          -- 税金端数処理
        AND    flv.lookup_code        = i_wk_cust_rec.tax_rounding_rule             -- 税金端数処理
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --税金端数処理チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_tax_rounding_rule                  -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.tax_rounding_rule       -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.36 売掛コード1（請求書）存在チェック
      --==============================================================
      lv_step := 'A-4.36';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 売掛コード1（請求書）存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_invoice_grp                       -- 売掛コード1（請求書）
        AND    flv.lookup_code        = i_wk_cust_rec.invoice_grp_code              -- 売掛コード1（請求書）
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --売掛コード1（請求書）存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_invoice_grp_code                   -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.invoice_grp_code        -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.37 請求書出力形式存在チェック
      --==============================================================
      lv_step := 'A-4.37';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 請求書出力形式存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_sekyusyo_ksk                      -- 請求書出力形式
        AND    flv.lookup_code        = i_wk_cust_rec.output_form                   -- 請求書出力形式
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --請求書出力形式存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_output_form                        -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.output_form             -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.38 請求書発行サイクル存在チェック
      --==============================================================
      lv_step := 'A-4.38';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 請求書発行サイクル存在チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP表
        WHERE  flv.lookup_type        = cv_lookup_invoice_cycl                      -- 請求書発行サイクル
        AND    flv.lookup_code        = i_wk_cust_rec.prt_cycle                     -- 請求書発行サイクル
        AND    flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --請求書発行サイクル存在チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_prt_cycle                          -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.prt_cycle               -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.39 支払条件チェック
      --==============================================================
      lv_step := 'A-4.39';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 支払条件チェック
        BEGIN
          SELECT rt.term_id
          INTO   gt_payment_term_id
          FROM   ra_terms rt                                             -- 支払条件
          WHERE  rt.name = i_wk_cust_rec.payment_term                    -- 支払条件
          AND    NVL( rt.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
          AND    NVL( rt.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_check_status   := cv_status_error;
            ov_retcode        := cv_status_error;
            --支払条件チェックエラー
            gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_10346                    -- メッセージコード
                          ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                          ,iv_token_value1 => cv_payment_term_id                    -- トークン値1
                          ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                          ,iv_token_value2 => i_wk_cust_rec.payment_term            -- トークン値2
                          ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                          ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
            --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
        END;
      END IF;
      --==============================================================
      -- A-4.40 納品拠点チェック
      --==============================================================
      lv_step := 'A-4.40';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 納品拠点チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- 値セット定義マスタ
              ,fnd_flex_values     ffv                                            -- 値セットマスタ
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- 値セットID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF部門(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- 子値
        AND    ffv.flex_value           = i_wk_cust_rec.delivery_base_code        -- 納品拠点
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- 開始日
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- 終了日
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode      := cv_status_error;
          -- 納品拠点チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10329                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_delivery_base_code                 -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.delivery_base_code      -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.41 請求拠点チェック
      --==============================================================
      lv_step := 'A-4.41';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 請求拠点チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- 値セット定義マスタ
              ,fnd_flex_values     ffv                                            -- 値セットマスタ
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- 値セットID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF部門(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- 子値
        AND    ffv.flex_value           = i_wk_cust_rec.bill_base_code            -- 請求拠点
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- 開始日
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- 終了日
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode      := cv_status_error;
          -- 請求拠点チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10329                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_bill_base_code                     -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.bill_base_code          -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.42 入金拠点チェック
      --==============================================================
      lv_step := 'A-4.42';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 入金拠点チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- 値セット定義マスタ
              ,fnd_flex_values     ffv                                            -- 値セットマスタ
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- 値セットID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF部門(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- 子値
        AND    ffv.flex_value           = i_wk_cust_rec.receiv_base_code          -- 入金拠点
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- 開始日
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- 終了日
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode      := cv_status_error;
          -- 入金拠点チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10329                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_receiv_base_code                   -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.receiv_base_code        -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.43 販売先本部担当拠点チェック
      --==============================================================
      lv_step := 'A-4.43';
      -- フォーマットパターン「504:売掛管理」の場合
      IF ( gv_format = cv_file_format_ur ) THEN
        -- 販売先本部担当拠点チェック
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- 値セット定義マスタ
              ,fnd_flex_values     ffv                                            -- 値セットマスタ
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- 値セットID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF部門(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- 子値
        AND    ffv.flex_value           = i_wk_cust_rec.sales_head_base_code      -- 販売先本部担当拠点
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- 開始日
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- 終了日
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode      := cv_status_error;
          -- 販売先本部担当拠点チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10329                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_sales_head_base_cd                   -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_cust_rec.sales_head_base_code    -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- トークン値3
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    END IF;
  --
  -- チェック処理結果をセット
  IF ( lv_check_flag = cv_status_normal )THEN
    ov_retcode := cv_status_normal;
  ELSIF ( lv_check_flag = cv_status_error ) THEN
    ov_retcode := cv_status_error;
  END IF;
  --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END validate_cust_wk;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : 顧客登録結果をログ出力用テーブルに格納します。
   ***********************************************************************************/
  PROCEDURE add_report(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN  save_cust_key_info_rtype      -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_report'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    lr_report_rec report_rec;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- レポートレコードに値を設定
    lr_report_rec.line_no                  := i_wk_cust_rec.line_no;                        -- 行番号
    lr_report_rec.account_number           := io_save_cust_key_info_rec.lv_account_number;  -- 顧客コード
    lr_report_rec.customer_status          := i_wk_cust_rec.customer_status;                -- 顧客ステータス
    lr_report_rec.resource_no              := i_wk_cust_rec.resource_no;                    -- 担当営業員
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify start by Shigeto.Niki
--    lr_report_rec.resource_s_date          := i_wk_cust_rec.resource_s_date;                -- 適用開始日
-- 2012/11/13 Ver1.2 SCSK K.Furuyama mod start
--    lr_report_rec.resource_s_date          := gd_process_date;                              -- 業務日付
    lr_report_rec.resource_s_date          := TO_CHAR( gd_process_date, cv_date_fmt_std );  -- 業務日付
-- 2012/11/13 Ver1.2 SCSK K.Furuyama mod end
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify end by Shigeto.Niki
    lr_report_rec.customer_name            := i_wk_cust_rec.customer_name;                  -- 顧客名
    --
    -- レポートテーブルに追加
    gt_report_tbl(gn_normal_cnt+1)         := lr_report_rec;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END add_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : レポート用データを出力します
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf      OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2    --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_normal     CONSTANT VARCHAR2(20) := '<<レコード内容>>';  -- 見出し
    lv_sep_com    CONSTANT VARCHAR2(1)  := ',';     -- カンマ
    --
    -- *** ローカル変数 ***
    lv_dspbuf     VARCHAR2(5000);    -- エラー・メッセージ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --
    -- 処理結果見出し
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                 ,iv_name         => cv_msg_xxcmm_10341                   -- メッセージコード
                );
    --
    -- 見出し
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff => cv_normal --見出し１
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg --見出し２
    );
    -- 見出し
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff => cv_normal --見出し１
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg --見出し２
    );
    --
    <<report_loop>>
    FOR ln_disp_cnt IN 1..gn_normal_cnt LOOP
      lv_dspbuf := gt_report_tbl(ln_disp_cnt).line_no||lv_sep_com||            -- 行番号
                   gt_report_tbl(ln_disp_cnt).account_number||lv_sep_com||     -- 顧客コード
                   gt_report_tbl(ln_disp_cnt).customer_status||lv_sep_com||    -- 顧客ステータス
                   gt_report_tbl(ln_disp_cnt).resource_no||lv_sep_com||        -- 担当営業員
                   gt_report_tbl(ln_disp_cnt).resource_s_date||lv_sep_com||    -- 適用開始日
                   gt_report_tbl(ln_disp_cnt).customer_name                    -- 顧客名
                   ;
      -- 登録結果出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff => lv_dspbuf --正常データログ
      );
      --
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff => lv_dspbuf --正常データログ
      );
    END LOOP report_loop;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : ins_cust_acct_api
   * Description      : 顧客マスタ登録処理
   ***********************************************************************************/
  PROCEDURE ins_cust_acct_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  OUT save_cust_key_info_rtype      -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cust_acct_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_party_number             VARCHAR2(200);
    ln_profile_id               NUMBER;
    lv_sql_errm                 VARCHAR2(2000); -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_p_create_profile_amt     VARCHAR2(200) := fnd_api.g_false;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    -- 退避用
    ln_cust_account_id          NUMBER;                                                  -- 退避_顧客ID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
    ln_party_id                 hz_parties.party_id%TYPE;                                -- 退避_パーティID
--
    -- *** ローカル・カーソル ***
    -- hz_cust_account_v2pub.create_cust_account API
    l_cust_account_rec          hz_cust_account_v2pub.cust_account_rec_type;
    l_organization_rec          hz_party_v2pub.organization_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_party_rec                 hz_party_v2pub.party_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
--
    lv_create_profile           VARCHAR2(1) := fnd_api.g_false;
    lv_create_profile_amt       VARCHAR2(1) := fnd_api.g_false;
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- 標準APIエラー
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
    -- A-5.1-1 顧客マスタ登録用レコード作成
    --==============================================================
    lv_step := 'A-5.1-1';
    -- パラメータ初期化
    l_cust_account_rec      := NULL;
    l_organization_rec      := NULL;
    l_customer_profile_rec  := NULL;
--
    -- 顧客マスタ登録用レコード
    l_cust_account_rec.cust_account_id                := NULL;                                               -- 顧客アカウントID
    l_cust_account_rec.account_number                 := NULL;                                               -- 顧客アカウント番号
    l_cust_account_rec.account_name                   := i_wk_cust_rec.customer_name_ryaku;                  -- アカウント名
    l_cust_account_rec.customer_class_code            := i_wk_cust_rec.customer_class_code;                  -- 顧客区分
    l_cust_account_rec.customer_type                  := cv_r;                                               -- 顧客タイプ('R':外部)
    l_cust_account_rec.dormant_account_flag           := cv_no;                                              -- 休止フラグ('N':No)
    l_cust_account_rec.arrivalsets_include_lines_flag := cv_no;                                              -- 到着セット('N':No)
    l_cust_account_rec.sched_date_push_flag           := cv_no;                                              -- プッシュ・グループ予定日('N':No)
    l_cust_account_rec.status                         := cv_a;                                               -- ステータス('A':有効)
    l_cust_account_rec.created_by_module              := cv_pkg_name;                                        -- プログラムID
    -- 組織レコード登録用レコード
    l_organization_rec.organization_name              := i_wk_cust_rec.customer_name;                        -- 顧客名
    l_organization_rec.duns_number_c                  := i_wk_cust_rec.customer_status;                      -- 顧客ステータス
    l_organization_rec.organization_name_phonetic     := i_wk_cust_rec.customer_name_kana;                   -- 顧客名カナ
    l_organization_rec.gsa_indicator_flag             := cv_no;                                              -- GSAインディケータ('N':No)
    -- パーティレコード登録用レコード
    l_organization_rec.party_rec.validated_flag       := cv_no;                                              -- 検証済みフラグ('N':No)
    l_organization_rec.party_rec.attribute1           := i_wk_cust_rec.manager_name;                         -- 店長名
    l_organization_rec.party_rec.attribute2           := i_wk_cust_rec.emp_number;                           -- 社員数
    l_organization_rec.party_rec.attribute3           := i_wk_cust_rec.rest_emp_name;                        -- 担当者休日
    l_organization_rec.party_rec.attribute4           := i_wk_cust_rec.mc_hot_deg;                           -- MC：HOT度
    l_organization_rec.party_rec.attribute5           := i_wk_cust_rec.mc_importance_deg;                    -- MC：重要度
    l_organization_rec.party_rec.attribute6           := i_wk_cust_rec.mc_conf_info;                         -- MC：競合情報
    l_organization_rec.party_rec.attribute7           := i_wk_cust_rec.mc_business_talk_details;             -- MC：商談経緯
    l_organization_rec.party_rec.attribute8           := i_wk_cust_rec.business_low_type_tmp;                -- 業態小分類(仮)

--
    --==============================================================
    -- A-5.1-2 顧客マスタ登録
    --==============================================================
    lv_step := 'A-5.1-2';
    -- 顧客マスタ作成の標準APIをコール
    hz_cust_account_v2pub.create_cust_account(
      p_init_msg_list         => lv_init_msg_list            -- 初期メッセージリスト
     ,p_cust_account_rec      => l_cust_account_rec          -- 顧客マスタ登録用レコード
     ,p_organization_rec      => l_organization_rec          -- 組織レコード登録用レコード
     ,p_customer_profile_rec  => l_customer_profile_rec      -- 組織プロファイル登録用レコード
     ,p_create_profile_amt    => lv_p_create_profile_amt     -- 
     ,x_cust_account_id       => ln_cust_account_id          -- 顧客ID
     ,x_account_number        => lv_account_number           -- 顧客コード
     ,x_party_id              => ln_party_id                 -- パーティID
     ,x_party_number          => lv_party_number             -- パーティ番号
     ,x_profile_id            => ln_profile_id               -- プロファイルID
     ,x_return_status         => lv_return_status            -- リターンコード
     ,x_msg_count             => ln_msg_count                -- リターンメッセージ
     ,x_msg_data              => lv_msg_data                 -- リターンデータ
    );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- エラーメッセージ取得
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_cust_acct;                -- テーブル名
      lv_api_nm        := cv_api_cust_acct;                  -- API名
      lv_sql_errm      := lv_msg_data;                       -- APIエラーメッセージ
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF;
--
    -- 顧客マスタ作成結果のKEY情報を変数に退避します。
    io_save_cust_key_info_rec.ln_cust_account_id := ln_cust_account_id;  -- 退避_顧客アカウントID
    io_save_cust_key_info_rec.lv_account_number  := lv_account_number;   -- 退避_顧客コード
    io_save_cust_key_info_rec.ln_party_id        := ln_party_id;         -- 退避_パーティID
    --
--
  EXCEPTION
    -- *** 標準APIエラー ***
    WHEN ins_xxcmm_cust_api_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10339            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_table_nm                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_nm                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- トークン値3
                    ,iv_token_name4  => cv_tkn_cust_code              -- トークンコード4
                    ,iv_token_value4 => lv_account_number             -- トークン値4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- トークンコード5
                    ,iv_token_value5 => lv_sql_errm                   -- トークン値5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_cust_acct_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_location_api
   * Description      : 顧客所在地登録処理
   ***********************************************************************************/
  PROCEDURE ins_location_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_location_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    -- 退避用
    ln_cust_account_id          NUMBER;                                                  -- 退避_顧客ID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
    ln_party_id                 hz_parties.party_id%TYPE;                                -- 退避_パーティID
    ln_location_id              hz_locations.location_id%TYPE;                           -- 退避_事業所ID
--
    -- *** ローカル・カーソル ***
    -- hz_location_v2pub.create_cust_account
    l_location_rec              hz_location_v2pub.location_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- 標準APIエラー
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
    -- A-5.1-3 顧客所在地マスタ登録用レコード作成
    --==============================================================
    lv_step := 'A-5.1-3';
--
    -- パラメータ初期化
    ln_location_id       := NULL;   -- 退避_事業所ID
    l_location_rec       := NULL;   -- 所在地レコード
--
    l_location_rec       := NULL;
    -- メッセージ用
    lv_account_number                                 := io_save_cust_key_info_rec.lv_account_number;        -- 顧客コード
    -- 顧客所在地マスタ登録用レコード
    l_location_rec.location_id                        := NULL;                                               -- ロケーションID
    l_location_rec.country                            := cv_jp;                                              -- 国('JP'：日本)
    l_location_rec.postal_code                        := RPAD(i_wk_cust_rec.postal_code,7,'0');              -- 郵便番号
    l_location_rec.state                              := i_wk_cust_rec.state;                                -- 都道府県
    l_location_rec.city                               := i_wk_cust_rec.city;                                 -- 市・区
    l_location_rec.address1                           := i_wk_cust_rec.address1;                             -- 住所１
    --
    IF ( i_wk_cust_rec.address2 IS NOT NULL ) THEN
      l_location_rec.address2                         := i_wk_cust_rec.address2;                             -- 住所２
    ELSE
      l_location_rec.address2                         := fnd_api.g_miss_char;
    END IF;
    --
    l_location_rec.address3                           := i_wk_cust_rec.address3;                             -- 地区コード
    l_location_rec.address_lines_phonetic             := i_wk_cust_rec.tel_no;                               -- 電話番号
    l_location_rec.address4                           := i_wk_cust_rec.fax;                                  -- FAX
    l_location_rec.validated_flag                     := cv_no;                                              -- 検証済みフラグ('N':No)
    l_location_rec.sales_tax_inside_city_limits       := cv_1;                                               -- 売上税都市区内制限
    l_location_rec.created_by_module                  := cv_pkg_name;                                        -- プログラムID
--
    --==============================================================
    -- A-5.1-4 顧客所在地マスタ登録
    --==============================================================
    lv_step := 'A-5.1-4';
    -- 顧客所在地マスタ作成の標準APIをコール
    hz_location_v2pub.create_location(
      p_init_msg_list         => lv_init_msg_list            -- 初期メッセージリスト
     ,p_location_rec          => l_location_rec              -- 顧客所在地マスタ登録用レコード
     ,x_location_id           => ln_location_id              -- 事業所ID
     ,x_return_status         => lv_return_status            -- リターンコード
     ,x_msg_count             => ln_msg_count                -- リターンメッセージ
     ,x_msg_data              => lv_msg_data                 -- リターンデータ
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- エラーメッセージ取得
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_location;                 -- テーブル名
      lv_api_nm        := cv_api_location;                   -- API名
      lv_sql_errm      := lv_msg_data;                       -- APIエラーメッセージ
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF;
--
    -- 顧客マスタ作成結果のKEY情報を変数に退避します。
    io_save_cust_key_info_rec.ln_location_id := ln_location_id; -- 退避_事業所ID
--
  EXCEPTION
    -- *** 標準APIエラー ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- 標準APIエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10339            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_table_nm                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_nm                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- トークン値3
                    ,iv_token_name4  => cv_tkn_cust_code              -- トークンコード4
                    ,iv_token_value4 => lv_account_number             -- トークン値4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- トークンコード5
                    ,iv_token_value5 => lv_sql_errm                   -- トークン値5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_location_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_party_site_api
   * Description      : パーティサイトマスタ登録処理
   ***********************************************************************************/
  PROCEDURE ins_party_site_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_party_site_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    -- 退避用
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
    ln_location_id              hz_locations.location_id%TYPE;                           -- 退避_事業所ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- 退避_パーティサイトID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- 退避_パーティサイト番号
--
    -- *** ローカル・カーソル ***
    -- hz_party_site_v2pub.create_party_site
    l_party_site_rec            hz_party_site_v2pub.party_site_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- 標準APIエラー
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
    -- A-5.1-5 パーティサイトマスタ登録レコード作成
    --==============================================================
    lv_step := 'A-5.1-5';
--
    -- メッセージ用
    lv_account_number                                 := io_save_cust_key_info_rec.lv_account_number;       -- 顧客コード
    -- パーティサイトマスタ登録用レコード
    l_party_site_rec.party_site_id                    := NULL;                                              -- パーティサイトID
    l_party_site_rec.party_id                         := io_save_cust_key_info_rec.ln_party_id;             -- 退避_パーティID
    l_party_site_rec.location_id                      := io_save_cust_key_info_rec.ln_location_id;          -- 退避_事業所ID
    l_party_site_rec.status                           := cv_a;                                              -- 登録ステータス
    l_party_site_rec.identifying_address_flag         := cv_y;                                              -- 
    l_party_site_rec.party_site_number                := NULL;                                              -- パーティサイト番号
    l_party_site_rec.created_by_module                := cv_pkg_name;                                       -- プログラムID
--
    --==============================================================
    -- A-5.1-6 パーティサイトマスタ登録
    --==============================================================
    lv_step := 'A-5.1-6';
    -- パーティサイトマスタ作成の標準APIをコール
    hz_party_site_v2pub.create_party_site (
      p_init_msg_list         => lv_init_msg_list                -- 初期メッセージリスト
     ,p_party_site_rec        => l_party_site_rec                -- パーティサイトマスタ登録用レコード
     ,x_party_site_id         => ln_party_site_id                -- パーティサイトID
     ,x_party_site_number     => lv_party_site_number            -- パーティサイト番号
     ,x_return_status         => lv_return_status                -- リターンコード
     ,x_msg_count             => ln_msg_count                    -- リターンメッセージ
     ,x_msg_data              => lv_msg_data                     -- リターンデータ
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- エラーメッセージ取得
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_party_site;               -- テーブル名
      lv_api_nm        := cv_api_party_site;                 -- API名
      lv_sql_errm      := lv_msg_data;                       -- APIエラーメッセージ
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF; 
--
    -- パーティサイト作成結果のKEY情報を変数に退避します。
    io_save_cust_key_info_rec.ln_party_site_id     := ln_party_site_id;     -- 退避_パーティサイトID
--
  EXCEPTION
    -- *** 標準APIエラー ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- 標準APIエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10339            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_table_nm                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_nm                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- トークン値3
                    ,iv_token_name4  => cv_tkn_cust_code              -- トークンコード4
                    ,iv_token_value4 => lv_account_number             -- トークン値4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- トークンコード5
                    ,iv_token_value5 => lv_sql_errm                   -- トークン値5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_party_site_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_cust_acct_site_api
   * Description      : 顧客サイトマスタ登録処理
   ***********************************************************************************/
  PROCEDURE ins_cust_acct_site_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cust_acct_site_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    -- 退避用
    ln_cust_account_id          NUMBER;                                                  -- 退避_顧客ID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- 退避_パーティサイトID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- 退避_パーティサイト番号
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- 退避_顧客サイトID
--
    -- *** ローカル・カーソル ***
    -- hz_cust_account_site_v2pub.create_cust_site_use
    l_rec_cust_site_rec         hz_cust_account_site_v2pub.cust_acct_site_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- 標準APIエラー
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
    -- A-5.1-7 顧客サイトマスタ登録レコード作成
    --==============================================================
    lv_step := 'A-5.1-7';
--
    -- メッセージ用
    lv_account_number                                 := io_save_cust_key_info_rec.lv_account_number;       -- 顧客コード
    -- 顧客サイトマスタ登録用レコード
    l_rec_cust_site_rec.cust_acct_site_id             := NULL;                                              -- 顧客サイトID
    l_rec_cust_site_rec.cust_account_id               := io_save_cust_key_info_rec.ln_cust_account_id;      -- 退避_顧客アカウントID
    l_rec_cust_site_rec.party_site_id                 := io_save_cust_key_info_rec.ln_party_site_id;        -- 退避_パーティサイトID
    l_rec_cust_site_rec.attribute_category            := gv_sal_org_id;                                     -- アトリビュートカテゴリ(営業OU)
    l_rec_cust_site_rec.status                        := cv_a;                                              -- 登録ステータス
    l_rec_cust_site_rec.key_account_flag              := cv_no;                                             -- 
    l_rec_cust_site_rec.created_by_module             := cv_pkg_name;                                       -- プログラムID
--
    --==============================================================
    -- A-5.1-8 顧客サイトマスタ登録
    --==============================================================
    lv_step := 'A-5.1-8';
    -- 顧客サイトマスタ作成の標準APIをコール
    hz_cust_account_site_v2pub.create_cust_acct_site (
      p_init_msg_list         => lv_init_msg_list
     ,p_cust_acct_site_rec    => l_rec_cust_site_rec
     ,x_cust_acct_site_id     => ln_cust_acct_site_id
     ,x_return_status         => lv_return_status
     ,x_msg_count             => ln_msg_count
     ,x_msg_data              => lv_msg_data
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- エラーメッセージ取得
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_acct_site;                -- テーブル名
      lv_api_nm        := cv_api_acct_site;                  -- API名
      lv_sql_errm      := lv_msg_data;                       -- APIエラーメッセージ
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF; 
--
    -- 顧客サイト作成結果のKEY情報を変数に退避します。
    io_save_cust_key_info_rec.ln_cust_acct_site_id := ln_cust_acct_site_id; -- 顧客サイトID
--
  EXCEPTION
    -- *** 標準APIエラー ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- 標準APIエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10339            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_table_nm                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_nm                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- トークン値3
                    ,iv_token_name4  => cv_tkn_cust_code              -- トークンコード4
                    ,iv_token_value4 => lv_account_number             -- トークン値4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- トークンコード5
                    ,iv_token_value5 => lv_sql_errm                   -- トークン値5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_cust_acct_site_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_bill_to_api
   * Description      : 顧客使用目的マスタ(請求先)登録処理
   ***********************************************************************************/
  PROCEDURE ins_bill_to_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bill_to_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_create_profile           VARCHAR2(1)   := fnd_api.g_true;
    lv_create_profile_amt       VARCHAR2(1)   := fnd_api.g_false;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    ln_cust_account_id          NUMBER;                                                  -- 退避_顧客ID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
    ln_party_id                 hz_parties.party_id%TYPE;                                -- 退避_パーティID
    ln_location_id              hz_locations.location_id%TYPE;                           -- 退避_事業所ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- 退避_パーティサイトID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- 退避_パーティサイト番号
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- 退避_顧客サイトID
    ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_請求先_使用目的ID
    lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_請求先_使用目的
    ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;       -- 退避_顧客プロファイルID
--
    -- *** ローカル・カーソル ***
    -- hz_cust_account_v2pub.create_cust_account API
    l_cust_site_use_rec         hz_cust_account_site_v2pub.cust_site_use_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- 標準APIエラー
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
    -- A-5.1-9 顧客使用目的マスタ(請求先)登録レコード作成
    --==============================================================
    lv_step := 'A-5.1-9';
    --
    -- レコードクリア
    l_cust_site_use_rec     := NULL; -- 事業所レコード
    l_customer_profile_rec  := NULL; -- 顧客プロファイルレコード
    --
    -- メッセージ用
    lv_account_number                                   := io_save_cust_key_info_rec.lv_account_number;        -- 顧客コード
    -- 顧客使用目的マスタ(請求先)登録用レコード
    l_cust_site_use_rec.site_use_id                     := NULL;                                               -- 事業所ID
    l_cust_site_use_rec.cust_acct_site_id               := io_save_cust_key_info_rec.ln_cust_acct_site_id;     -- 退避_顧客サイトID
    l_cust_site_use_rec.status                          := cv_a;                                               -- 登録ステータス
    l_cust_site_use_rec.price_list_id                   := NULL;                                               -- 価格表ID
    l_cust_site_use_rec.attribute_category              := gv_sal_org_id;                                      -- アトリビュートカテゴリ
    l_cust_site_use_rec.primary_flag                    := cv_yes;                                             -- primary_flag
    l_cust_site_use_rec.gsa_indicator                   := cv_no;                                              -- GSAインディケータ('N'：No)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama del start
    --l_cust_site_use_rec.site_use_code                   := cv_site_use_bill_to;                                -- 使用目的('BILL_TO'：請求先)
    --l_cust_site_use_rec.attribute7                      := gv_output_form;                                     -- 請求書出力形式
    --l_cust_site_use_rec.attribute8                      := gv_prt_cycle;                                       -- 請求書発行サイクル
-- 2012/12/14 Ver1.2 SCSK K.Furuyama del end
    l_cust_site_use_rec.ship_sets_include_lines_flag    := cv_no;                                              -- ship_sets_include_lines_flag
    l_cust_site_use_rec.arrivalsets_include_lines_flag  := cv_no;                                              -- arrivalsets_include_lines_flag
    l_cust_site_use_rec.sched_date_push_flag            := cv_no;                                              -- sched_date_push_flag
    l_cust_site_use_rec.created_by_module               := cv_pkg_name;                                        -- プログラムID
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- フォーマットパターン「501:MC顧客」の場合
    IF ( gv_format = cv_file_format_mc ) THEN
      l_cust_site_use_rec.site_use_code                 := cv_site_use_bill_to;                                -- 使用目的('BILL_TO'：請求先)
      l_cust_site_use_rec.attribute7                    := gv_output_form;                                     -- 請求書出力形式
      l_cust_site_use_rec.attribute8                    := gv_prt_cycle;                                       -- 請求書発行サイクル
    -- フォーマットパターン「504:売掛管理」の場合
    ELSIF ( gv_format = cv_file_format_ur ) THEN
      l_cust_site_use_rec.site_use_code                 := cv_site_use_bill_to;                                -- 使用目的('BILL_TO'：請求先)
      l_cust_site_use_rec.attribute7                    := i_wk_cust_rec.output_form;                          -- 請求書出力形式
      l_cust_site_use_rec.attribute8                    := i_wk_cust_rec.prt_cycle;                            -- 請求書発行サイクル
      l_cust_site_use_rec.tax_rounding_rule             := i_wk_cust_rec.tax_rounding_rule;                    -- 税金端数処理
      l_cust_site_use_rec.attribute4                    := i_wk_cust_rec.invoice_grp_code;                     -- 売掛コード1（請求書）
      l_cust_site_use_rec.payment_term_id               := gt_payment_term_id;                                 -- 支払条件
      l_cust_site_use_rec.gl_id_rec                     := gt_urikake_misyuukin_id;                            -- 売掛金/未収金
      -- 顧客プロファイルレコード
      l_customer_profile_rec.autocash_hierarchy_id      := gt_autocash_hierarchy_id;                           -- 自動消込基準セット
      l_customer_profile_rec.cons_inv_flag              := cv_y;                                               -- 一括請求書発行(Y:使用可能)
      l_customer_profile_rec.cons_inv_type              := cv_summary;                                         -- 一括請求書発行タイプ(SUMMARY:要約)
    END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    -- 顧客プロファイルレコード
    l_customer_profile_rec.cust_account_profile_id      := NULL;                                               -- 顧客プロファイルID
    l_customer_profile_rec.cust_account_id              := io_save_cust_key_info_rec.ln_cust_account_id;       -- 退避_顧客アカウントID
    --
    --==============================================================
    -- A-5.1-10 顧客使用目的マスタ(請求先)登録
    --==============================================================
    lv_step := 'A-5.1-10';
    -- 事業所（請求先）作成の標準APIをコール
    hz_cust_account_site_v2pub.create_cust_site_use(
      p_init_msg_list        => lv_init_msg_list               -- 初期メッセージリスト
     ,p_cust_site_use_rec    => l_cust_site_use_rec            -- 顧客使用目的マスタ(請求先)レコード変数
     ,p_customer_profile_rec => l_customer_profile_rec         -- 顧客プロファイルレコード変数
     ,p_create_profile       => lv_create_profile
     ,p_create_profile_amt   => lv_create_profile_amt
     ,x_site_use_id          => ln_bill_to_site_use_id         -- 請求先_使用目的ID
     ,x_return_status        => lv_return_status               -- リターンコード
     ,x_msg_count            => ln_msg_count                   -- リターンメッセージ
     ,x_msg_data             => lv_msg_data                    -- リターンデータ
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN
      -- エラーメッセージ取得
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_bill_to;                -- テーブル名
      lv_api_nm        := cv_api_cust_site_use;            -- API名
      lv_sql_errm      := lv_msg_data;                     -- APIエラーメッセージ
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF;
    --
    -- 顧客使用目的マスタ(請求先)作成結果のKEY情報を変数に退避します。
    io_save_cust_key_info_rec.ln_bill_to_site_use_id   := ln_bill_to_site_use_id;             -- 退避_請求先_使用目的ID
    io_save_cust_key_info_rec.lv_bill_to_site_use_code := l_cust_site_use_rec.site_use_code;  -- 退避_請求先_使用目的
--
  EXCEPTION
    -- *** 標準APIエラー ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- 標準APIエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10339            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_table_nm                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_nm                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- トークン値3
                    ,iv_token_name4  => cv_tkn_cust_code              -- トークンコード4
                    ,iv_token_value4 => lv_account_number             -- トークン値4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- トークンコード5
                    ,iv_token_value5 => lv_sql_errm                   -- トークン値5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_bill_to_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_ship_to_api
   * Description      : 顧客使用目的マスタ(出荷先)登録処理
   ***********************************************************************************/
  PROCEDURE ins_ship_to_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ship_to_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_create_profile           VARCHAR2(1)   := fnd_api.g_false;
    lv_create_profile_amt       VARCHAR2(1)   := fnd_api.g_false;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    ln_cust_account_id          NUMBER;                                                  -- 退避_顧客ID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
    ln_party_id                 hz_parties.party_id%TYPE;                                -- 退避_パーティID
    ln_location_id              hz_locations.location_id%TYPE;                           -- 退避_事業所ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- 退避_パーティサイトID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- 退避_パーティサイト番号
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- 退避_顧客サイトID
    ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_請求先_使用目的ID
    lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_請求先_使用目的
    ln_ship_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_出荷先_使用目的ID
    lv_ship_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_出荷先_使用目的
    ln_other_to_site_use_id     hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_その他_使用目的ID
    lv_other_to_site_use_code   hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_その他_使用目的
    ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;       -- 退避_顧客プロファイルID
--
    -- *** ローカル・カーソル ***
    l_cust_site_use_rec         hz_cust_account_site_v2pub.cust_site_use_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- 標準APIエラー
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
    -- A-5.1-11 顧客使用目的マスタ(出荷先)登録レコード作成
    --==============================================================
    lv_step := 'A-5.1-11';
    --
    -- レコードクリア
    l_cust_site_use_rec     := NULL; -- 事業所レコード
    --
    -- メッセージ用
    lv_account_number                                   := io_save_cust_key_info_rec.lv_account_number;        -- 顧客コード
    -- 顧客使用目的マスタ(出荷先)登録用レコード
    l_cust_site_use_rec.site_use_id                     := NULL;                                               -- 事業所ID
    l_cust_site_use_rec.cust_acct_site_id               := io_save_cust_key_info_rec.ln_cust_acct_site_id;     -- 退避_顧客サイトID
    l_cust_site_use_rec.status                          := cv_a;                                               -- 登録ステータス
    l_cust_site_use_rec.bill_to_site_use_id             := io_save_cust_key_info_rec.ln_bill_to_site_use_id;   -- 退避_請求先_使用目的ID
    l_cust_site_use_rec.price_list_id                   := NULL;                                               -- 価格表ID
    l_cust_site_use_rec.attribute_category              := gv_sal_org_id;                                      -- アトリビュートカテゴリ
    l_cust_site_use_rec.primary_flag                    := cv_yes;                                             -- primary_flag
    l_cust_site_use_rec.gsa_indicator                   := cv_no;                                              -- GSAインディケータ('N'：No)
    l_cust_site_use_rec.site_use_code                   := cv_site_use_ship_to;                                -- 使用目的('SHIP_TO'：出荷先)
    l_cust_site_use_rec.ship_sets_include_lines_flag    := cv_no;                                              -- ship_sets_include_lines_flag
    l_cust_site_use_rec.arrivalsets_include_lines_flag  := cv_no;                                              -- arrivalsets_include_lines_flag
    l_cust_site_use_rec.sched_date_push_flag            := cv_no;                                              -- sched_date_push_flag
    l_cust_site_use_rec.created_by_module               := cv_pkg_name;                                        -- プログラムID
    --
    --==============================================================
    -- A-5.1-12 顧客使用目的マスタ(出荷先)登録
    --==============================================================
    lv_step := 'A-5.1-12';
    -- 事業所（出荷先）作成の標準APIをコール
    hz_cust_account_site_v2pub.create_cust_site_use(
      p_init_msg_list        => lv_init_msg_list               -- 初期メッセージリスト
     ,p_cust_site_use_rec    => l_cust_site_use_rec            -- 顧客使用目的マスタ(出荷先レコード変数)
     ,p_customer_profile_rec => l_customer_profile_rec         -- 
     ,p_create_profile       => lv_create_profile              -- 
     ,p_create_profile_amt   => lv_create_profile_amt          -- 
     ,x_site_use_id          => ln_ship_to_site_use_id         -- 出荷先_使用目的ID
     ,x_return_status        => lv_return_status               -- リターンコード
     ,x_msg_count            => ln_msg_count                   -- リターンメッセージ
     ,x_msg_data             => lv_msg_data                    -- リターンデータ
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- エラーメッセージ取得
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_ship_to;                -- テーブル名
      lv_api_nm        := cv_api_cust_site_use;            -- API名
      lv_sql_errm      := lv_msg_data;                     -- APIエラーメッセージ
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF; 
    -- 顧客使用目的マスタ(請求先)作成結果のKEY情報を変数に退避します。
    io_save_cust_key_info_rec.ln_ship_to_site_use_id   := ln_ship_to_site_use_id;             -- 退避_出荷先_使用目的ID
    io_save_cust_key_info_rec.lv_ship_to_site_use_code := l_cust_site_use_rec.site_use_code;  -- 退避_出荷先_使用目的
    --
--
  EXCEPTION
    -- *** 標準APIエラー ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- 標準APIエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10339            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_table_nm                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_nm                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- トークン値3
                    ,iv_token_name4  => cv_tkn_cust_code              -- トークンコード4
                    ,iv_token_value4 => lv_account_number             -- トークン値4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- トークンコード5
                    ,iv_token_value5 => lv_sql_errm                   -- トークン値5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_ship_to_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_other_to_api
   * Description      : 顧客使用目的マスタ(その他)登録処理
   ***********************************************************************************/
  PROCEDURE ins_other_to_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_other_to_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_party_number             VARCHAR2(200);
    ln_profile_id               NUMBER;
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_false;
    lv_create_profile           VARCHAR2(1)   := fnd_api.g_false;
    lv_create_profile_amt       VARCHAR2(1)   := fnd_api.g_false;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    ln_cust_account_id          NUMBER;                                                  -- 退避_顧客ID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
    ln_party_id                 hz_parties.party_id%TYPE;                                -- 退避_パーティID
    ln_location_id              hz_locations.location_id%TYPE;                           -- 退避_事業所ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- 退避_パーティサイトID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- 退避_パーティサイト番号
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- 退避_顧客サイトID
    ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_請求先_使用目的ID
    lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_請求先_使用目的
    ln_ship_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_出荷先_使用目的ID
    lv_ship_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_出荷先_使用目的
    ln_other_to_site_use_id     hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_その他_使用目的ID
    lv_other_to_site_use_code   hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_その他_使用目的
    ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;       -- 退避_顧客プロファイルID
--
    -- *** ローカル・カーソル ***
    l_cust_site_use_rec         hz_cust_account_site_v2pub.cust_site_use_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- 標準APIエラー
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
    -- A-5.1-13 顧客使用目的マスタ(その他)登録レコード作成
    --==============================================================
    lv_step := 'A-5.1-13';
    --
    -- レコードクリア
    l_cust_site_use_rec     := NULL; -- 事業所レコード
    --
    -- メッセージ用
    lv_account_number                                   := io_save_cust_key_info_rec.lv_account_number;        -- 顧客コード
    -- 顧客使用目的マスタ(その他)登録用レコード
    l_cust_site_use_rec.site_use_id                     := NULL;                                               -- 事業所ID
    l_cust_site_use_rec.cust_acct_site_id               := io_save_cust_key_info_rec.ln_cust_acct_site_id;     -- 退避_顧客サイトID
    l_cust_site_use_rec.status                          := cv_a;                                               -- 登録ステータス
    l_cust_site_use_rec.attribute_category              := gv_sal_org_id;                                      -- アトリビュートカテゴリ
    l_cust_site_use_rec.primary_flag                    := cv_yes;                                             -- primary_flag
    l_cust_site_use_rec.gsa_indicator                   := cv_no;                                              -- GSAインディケータ('N'：No)
    l_cust_site_use_rec.site_use_code                   := cv_site_use_other_to;                               -- 使用目的('OTHER_TO'：その他)
    l_cust_site_use_rec.ship_sets_include_lines_flag    := cv_no;                                              -- ship_sets_include_lines_flag
    l_cust_site_use_rec.arrivalsets_include_lines_flag  := cv_no;                                              -- arrivalsets_include_lines_flag
    l_cust_site_use_rec.sched_date_push_flag            := cv_no;                                              -- sched_date_push_flag
    l_cust_site_use_rec.created_by_module               := cv_pkg_name;                                        -- プログラムID
    --
    --==============================================================
    -- A-5.1-14 顧客使用目的マスタ(その他)登録
    --==============================================================
    lv_step := 'A-5.1-14';
    -- 顧客使用目的マスタ(その他)作成の標準APIをコール
    hz_cust_account_site_v2pub.create_cust_site_use(
      p_init_msg_list        => lv_init_msg_list               -- 初期メッセージリスト
     ,p_cust_site_use_rec    => l_cust_site_use_rec            -- 顧客使用目的マスタ(その他レコード変数)
     ,p_customer_profile_rec => l_customer_profile_rec         -- 
     ,p_create_profile       => lv_create_profile              -- 
     ,p_create_profile_amt   => lv_create_profile_amt          -- 
     ,x_site_use_id          => ln_other_to_site_use_id        -- その他_使用目的ID
     ,x_return_status        => lv_return_status               -- リターンコード
     ,x_msg_count            => ln_msg_count                   -- リターンメッセージ
     ,x_msg_data             => lv_msg_data                    -- リターンデータ
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- エラーメッセージ取得
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_other_to     ;          -- テーブル名
      lv_api_nm        := cv_api_cust_site_use;            -- API名
      lv_sql_errm      := lv_msg_data;                     -- APIエラーメッセージ
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 標準APIエラー ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- 標準APIエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10339            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_table_nm                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_nm                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- トークン値3
                    ,iv_token_name4  => cv_tkn_cust_code              -- トークンコード4
                    ,iv_token_value4 => lv_account_number             -- トークン値4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- トークンコード5
                    ,iv_token_value5 => lv_sql_errm                   -- トークン値5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_other_to_api;
--
  /**********************************************************************************
   * Procedure Name   : regist_resource_no_api
   * Description      : 組織プロファイル拡張(担当営業員)登録処理
   ***********************************************************************************/
  PROCEDURE regist_resource_no_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_resource_no_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    -- 退避用
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
--
    lv_resource_no              xxcmm_wk_cust_upload.resource_no%TYPE;                   -- 担当営業員
    ld_start_date               xxcmm_wk_cust_upload.resource_s_date%TYPE;               -- 適用開始日
--
    -- *** ローカル・カーソル ***
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- 標準APIエラー
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
    -- A-5.1-15 組織プロファイル拡張(担当営業員)登録
    --==============================================================
    lv_step := 'A-5.1-15';
    --
    -- 組織プロファイル拡張(担当営業員)登録用レコード
--
    lv_account_number    := io_save_cust_key_info_rec.lv_account_number;              -- 顧客コード
    lv_resource_no       := i_wk_cust_rec.resource_no;                                -- レコード変数.担当営業員
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify start by Shigeto.Niki
--    gd_apply_date        := TO_DATE(i_wk_cust_rec.resource_s_date, cv_date_fmt_std);  -- レコード変数.適用開始日
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify end by Shigeto.Niki
    --
    -- 担当営業員登録の標準APIをコール
    xxcso_rtn_rsrc_pkg.regist_resource_no(
      iv_account_number    => lv_account_number     -- 顧客コード
     ,iv_resource_no       => lv_resource_no        -- 担当営業員（従業員コード）
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify start by Shigeto.Niki
--     ,id_start_date        => gd_apply_date         -- 適用開始日
     ,id_start_date        => gd_process_date       -- 業務日付
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 modify end by Shigeto.Niki
     ,ov_errbuf            => lv_errbuf             -- システムメッセージ
     ,ov_retcode           => lv_retcode            -- 処理結果('0':正常, '1':警告, '2':エラー)
     ,ov_errmsg            => lv_errmsg             -- ユーザーメッセージ
      );
    --
    IF ( lv_retcode <> xxcso_common_pkg.gv_status_normal ) THEN 
      lv_table_nm      := cv_table_resource;               -- テーブル名
      lv_api_nm        := cv_api_regist_resource;          -- API名
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF; 
--
  EXCEPTION
    -- *** 標準APIエラー ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- 標準APIエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10339            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_table_nm                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_nm                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- トークン値3
                    ,iv_token_name4  => cv_tkn_cust_code              -- トークンコード4
                    ,iv_token_value4 => lv_account_number             -- トークン値4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- トークンコード5
                    ,iv_token_value5 => lv_errbuf                     -- トークン値5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END regist_resource_no_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_cmm_cust_acct
   * Description      : 顧客追加情報登録処理
   ***********************************************************************************/
  PROCEDURE ins_cmm_cust_acct(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cmm_cust_acct'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_tkn_value                VARCHAR2(100);                                           -- トークン値
    ln_cnt                      NUMBER;                                                  -- カウント用
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    -- 退避用
    ln_cust_account_id          NUMBER;                                                  -- 退避_顧客ID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
    ln_party_id                 hz_parties.party_id%TYPE;                                -- 退避_パーティID
    ln_location_id              hz_locations.location_id%TYPE;                           -- 退避_事業所ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- 退避_パーティサイトID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- 退避_パーティサイト番号
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- 退避_顧客サイトID
    ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_請求先_使用目的ID
    lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_請求先_使用目的
    ln_ship_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_出荷先_使用目的ID
    lv_ship_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_出荷先_使用目的
    ln_other_to_site_use_id     hz_cust_site_uses_all.site_use_id%TYPE;                  -- 退避_その他_使用目的ID
    lv_other_to_site_use_code   hz_cust_site_uses_all.site_use_code%TYPE;                -- 退避_その他_使用目的
    ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;       -- 退避_顧客プロファイルID
--
    -- 顧客追加情報登録用
    lv_business_low_type        xxcmm_cust_accounts.business_low_type%TYPE;              -- 業態小分類
    lv_industry_div             xxcmm_cust_accounts.industry_div%TYPE;                   -- 業種
    lv_torihiki_form            xxcmm_cust_accounts.torihiki_form%TYPE;                  -- 取引形態
    lv_delivery_form            xxcmm_cust_accounts.delivery_form%TYPE;                  -- 配送形態
    lv_bill_base_code           xxcmm_cust_accounts.bill_base_code%TYPE;                 -- 請求拠点コード
    lv_receiv_base_code         xxcmm_cust_accounts.receiv_base_code%TYPE;               -- 入金拠点コード
    lv_invoice_printing_unit    xxcmm_cust_accounts.invoice_printing_unit%TYPE;          -- 請求書印刷単位
    lv_vist_target_div          xxcmm_cust_accounts.vist_target_div%TYPE;                -- 訪問対象区分
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    lv_delivery_base_code       xxcmm_cust_accounts.delivery_base_code%TYPE;             -- 納品拠点コード
    lv_sales_head_base_code     xxcmm_cust_accounts.sales_head_base_code%TYPE;           -- 販売先本部担当拠点コード
    lv_sales_chain_code         xxcmm_cust_accounts.sales_chain_code%TYPE;               -- 販売先チェーンコード
    lv_delivery_chain_code      xxcmm_cust_accounts.delivery_chain_code%TYPE;            -- 納品先チェーンコード
    lv_tax_div                  xxcmm_cust_accounts.tax_div%TYPE;                        -- 消費税区分
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_cust_acct_expt    EXCEPTION;                                               -- 顧客追加情報マスタ登録エラー
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
    -- A-5.2 顧客追加情報マスタ登録
    --==============================================================
    lv_step := 'A-5.2';
    BEGIN
        lv_account_number        := io_save_cust_key_info_rec.lv_account_number; -- 顧客コード
      -- フォーマットパターン「501:MC顧客」の場合
      IF ( gv_format = cv_file_format_mc ) THEN
        lv_business_low_type     := NULL;                                  -- 業態小分類
        lv_industry_div          := NULL;                                  -- 業種
        lv_torihiki_form         := NULL;                                  -- 取引形態
        lv_delivery_form         := NULL;                                  -- 配送形態
        lv_bill_base_code        := i_wk_cust_rec.sale_base_code;          -- 請求拠点コード
        lv_receiv_base_code      := i_wk_cust_rec.sale_base_code;          -- 入金拠点コード
        lv_invoice_printing_unit := gv_inv_unit;                           -- 請求書印刷単位
        lv_vist_target_div       := NULL;                                  -- 訪問対象区分
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
        lv_delivery_base_code    := NULL;                                  -- 納品拠点コード
        lv_sales_head_base_code  := NULL;                                  -- 販売先本部担当拠点コード
        lv_sales_chain_code      := i_wk_cust_rec.sales_chain_code;        -- 販売先チェーンコード
        lv_delivery_chain_code   := i_wk_cust_rec.delivery_chain_code;     -- 納品先チェーンコード
        lv_tax_div               := NULL;                                  -- 消費税区分
      --ELSE
      -- フォーマットパターン「502:店舗営業」の場合
      ELSIF ( gv_format = cv_file_format_st ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        lv_business_low_type     := i_wk_cust_rec.business_low_type;       -- 業態小分類
        lv_industry_div          := i_wk_cust_rec.industry_div;            -- 業種
        lv_torihiki_form         := i_wk_cust_rec.torihiki_form;           -- 取引形態
        lv_delivery_form         := i_wk_cust_rec.delivery_form;           -- 配送形態
        lv_bill_base_code        := NULL;                                  -- 請求拠点コード
        lv_receiv_base_code      := NULL;                                  -- 入金拠点コード
        lv_invoice_printing_unit := NULL;                                  -- 請求書印刷単位
        lv_vist_target_div       := cv_vist_target;                        -- 訪問対象区分
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
        lv_delivery_base_code    := NULL;                                  -- 納品拠点コード
        lv_sales_head_base_code  := NULL;                                  -- 販売先本部担当拠点コード
        lv_sales_chain_code      := i_wk_cust_rec.sales_chain_code;        -- 販売先チェーンコード
        lv_delivery_chain_code   := i_wk_cust_rec.delivery_chain_code;     -- 納品先チェーンコード
        lv_tax_div               := NULL;                                  -- 消費税区分
      -- フォーマットパターン「503:法人」の場合
      ELSIF ( gv_format = cv_file_format_ho ) THEN
        lv_business_low_type     := NULL;                                  -- 業態小分類
        lv_industry_div          := NULL;                                  -- 業種
        lv_torihiki_form         := NULL;                                  -- 取引形態
        lv_delivery_form         := NULL;                                  -- 配送形態
        lv_bill_base_code        := NULL;                                  -- 請求拠点コード
        lv_receiv_base_code      := NULL;                                  -- 入金拠点コード
        lv_invoice_printing_unit := NULL;                                  -- 請求書印刷単位
        lv_vist_target_div       := NULL;                                  -- 訪問対象区分
        lv_delivery_base_code    := NULL;                                  -- 納品拠点コード
        lv_sales_head_base_code  := NULL;                                  -- 販売先本部担当拠点コード
        lv_sales_chain_code      := NULL;                                  -- 販売先チェーンコード
        lv_delivery_chain_code   := NULL;                                  -- 納品先チェーンコード
        lv_tax_div               := NULL;                                  -- 消費税区分
      -- フォーマットパターン「504:売掛管理」の場合
      ELSIF ( gv_format = cv_file_format_ur ) THEN
        lv_business_low_type     := i_wk_cust_rec.business_low_type;       -- 業態小分類
        lv_industry_div          := i_wk_cust_rec.industry_div;            -- 業種
        lv_torihiki_form         := NULL;                                  -- 取引形態
        lv_delivery_form         := NULL;                                  -- 配送形態
        lv_bill_base_code        := i_wk_cust_rec.bill_base_code;          -- 請求拠点コード
        lv_receiv_base_code      := i_wk_cust_rec.receiv_base_code;        -- 入金拠点コード
        lv_invoice_printing_unit := NULL;                                  -- 請求書印刷単位
        lv_vist_target_div       := NULL;                                  -- 訪問対象区分
        lv_delivery_base_code    := i_wk_cust_rec.delivery_base_code;      -- 納品拠点コード
        lv_sales_head_base_code  := i_wk_cust_rec.sales_head_base_code;    -- 販売先本部担当拠点コード
        lv_sales_chain_code      := i_wk_cust_rec.sales_chain_code;        -- 販売先チェーンコード
        lv_delivery_chain_code   := i_wk_cust_rec.delivery_chain_code;     -- 納品先チェーンコード
        lv_tax_div               := i_wk_cust_rec.tax_div;                 -- 消費税区分
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      END IF;
      --
      -- 顧客追加情報テーブルの登録
      INSERT INTO xxcmm_cust_accounts
      (
        customer_id,                                    -- 顧客ID
        customer_code,                                  -- 顧客コード
        cust_update_flag,                               -- 新規／更新フラグ
        business_low_type,                              -- 業態（小分類）
        industry_div,                                   -- 業種
        selling_transfer_div,                           -- 売上実績振替
        torihiki_form,                                  -- 取引形態
        delivery_form,                                  -- 配送形態
        wholesale_ctrl_code,                            -- 問屋管理コード
        ship_storage_code,                              -- 出荷元保管場所(EDI)
        start_tran_date,                                -- 初回取引日
        final_tran_date,                                -- 最終取引日
        past_final_tran_date,                           -- 前月最終取引日
        final_call_date,                                -- 最終訪問日
        stop_approval_date,                             -- 中止決裁日
        stop_approval_reason,                           -- 中止理由
        vist_untarget_date,                             -- 顧客対象外変更日
        vist_target_div,                                -- 訪問対象区分
        party_representative_name,                      -- 代表者名（相手先）
        party_emp_name,                                 -- 担当者（相手先）
        sale_base_code,                                 -- 売上拠点コード
        past_sale_base_code,                            -- 前月売上拠点コード
        rsv_sale_base_act_date,                         -- 予約売上拠点有効開始日
        rsv_sale_base_code,                             -- 予約売上拠点コード
        delivery_base_code,                             -- 納品拠点コード
        sales_head_base_code,                           -- 販売先本部担当拠点
        chain_store_code,                               -- チェーン店コード（EDI）
        store_code,                                     -- 店舗コード
        cust_store_name,                                -- 顧客店舗名称
        torihikisaki_code,                              -- 取引先コード
        sales_chain_code,                               -- 販売先チェーンコード
        delivery_chain_code,                            -- 納品先チェーンコード
        policy_chain_code,                              -- 政策用チェーンコード
        intro_chain_code1,                              -- 紹介者チェーンコード１
        intro_chain_code2,                              -- 紹介者チェーンコード２
        tax_div,                                        -- 消費税区分
        rate,                                           -- 消化計算用掛率
        receiv_discount_rate,                           -- 入金値引率
        conclusion_day1,                                -- 消化計算締め日１
        conclusion_day2,                                -- 消化計算締め日２
        conclusion_day3,                                -- 消化計算締め日３
        contractor_supplier_code,                       -- 契約者仕入先コード
        bm_pay_supplier_code1,                          -- 紹介者BM支払仕入先コード１
        bm_pay_supplier_code2,                          -- 紹介者BM支払仕入先コード２
        delivery_order,                                 -- 配送順（EDI)
        edi_district_code,                              -- EDI地区コード（EDI)
        edi_district_name,                              -- EDI地区名（EDI)
        edi_district_kana,                              -- EDI地区名カナ（EDI)
        center_edi_div,                                 -- センターEDI区分
        tsukagatazaiko_div,                             -- 通過在庫型区分（EDI）
        establishment_location,                         -- 設置ロケーション
        open_close_div,                                 -- 物件オープン・クローズ区分
        operation_div,                                  -- オペレーション区分
        change_amount,                                  -- 釣銭
        vendor_machine_number,                          -- 自動販売機番号（相手先）
        established_site_name,                          -- 設置先名（相手先）
        cnvs_date,                                      -- 顧客獲得日
        cnvs_base_code,                                 -- 獲得拠点コード
        cnvs_business_person,                           -- 獲得営業員
        new_point_div,                                  -- 新規ポイント区分
        new_point,                                      -- 新規ポイント
        intro_base_code,                                -- 紹介拠点コード
        intro_business_person,                          -- 紹介営業員
        edi_chain_code,                                 -- チェーン店コード(EDI)【親レコード用】
        latitude,                                       -- 緯度
        longitude,                                      -- 経度
        management_base_code,                           -- 管理元拠点コード
        edi_item_code_div,                              -- EDI連携品目コード区分
        edi_forward_number,                             -- EDI伝送追番
        handwritten_slip_div,                           -- EDI手書伝票伝送区分
        deli_center_code,                               -- EDI納品センターコード
        deli_center_name,                               -- EDI納品センター名
        dept_hht_div,                                   -- 百貨店用HHT区分
        bill_base_code,                                 -- 請求拠点コード
        receiv_base_code,                               -- 入金拠点コード
        child_dept_shop_code,                           -- 百貨店伝区コード
        parnt_dept_shop_code,                           -- 百貨店伝区コード【親レコード用】
        past_customer_status,                           -- 前月顧客ステータス
        card_company_div,                               -- カード会社区分
        card_company,                                   -- カード会社
        invoice_printing_unit,                          -- 請求書印刷単位
        invoice_code        ,                           -- 請求書用コード
        enclose_invoice_code,                           -- 統括請求書用コード
        store_cust_code,                                -- 店舗営業用顧客コード
        created_by,                                     -- 作成者
        creation_date,                                  -- 作成日
        last_updated_by,                                -- 最終更新者
        last_update_date,                               -- 最終更新日
        last_update_login,                              -- 最終更新ﾛｸﾞｲﾝ
        request_id,                                     -- 要求ID
        program_application_id,                         -- コンカレント･プログラム･アプリケーションID
        program_id,                                     -- コンカレント･プログラムID
        program_update_date                             -- プログラム更新日
      )
      VALUES
      (
        io_save_cust_key_info_rec.ln_cust_account_id,   -- 顧客ID
        io_save_cust_key_info_rec.lv_account_number,    -- 顧客コード
        cv_ui_flag_new,                                 -- 新規／更新フラグ
        lv_business_low_type,                           -- 業態（小分類）
        lv_industry_div,                                -- 業種
        NULL,                                           -- 売上実績振替
        lv_torihiki_form,                               -- 取引形態
        lv_delivery_form,                               -- 配送形態
        NULL,                                           -- 問屋管理コード
        NULL,                                           -- 出荷元保管場所(EDI)
        NULL,                                           -- 初回取引日
        NULL,                                           -- 最終取引日
        NULL,                                           -- 前月最終取引日
        NULL,                                           -- 最終訪問日
        NULL,                                           -- 中止決裁日
        NULL,                                           -- 中止理由
        NULL,                                           -- 顧客対象外変更日
        lv_vist_target_div,                             -- 訪問対象区分
        NULL,                                           -- 代表者名（相手先）
        NULL,                                           -- 担当者（相手先）
        SUBSTRB(i_wk_cust_rec.sale_base_code, 1, 4),    -- 売上拠点コード
        SUBSTRB(i_wk_cust_rec.sale_base_code, 1, 4),    -- 前月売上拠点コード
        NULL,                                           -- 予約売上拠点有効開始日
        NULL,                                           -- 予約売上拠点コード
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
        --NULL,                                           -- 納品拠点コード
        --NULL,                                           -- 販売先本部担当拠点
        lv_delivery_base_code,                          -- 納品拠点コード
        lv_sales_head_base_code,                        -- 販売先本部担当拠点
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        NULL,                                           -- チェーン店コード（EDI）
        NULL,                                           -- 店舗コード
        NULL,                                           -- 顧客店舗名称
        NULL,                                           -- 取引先コード
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
        --i_wk_cust_rec.sales_chain_code,                 -- 販売先チェーンコード
        --i_wk_cust_rec.delivery_chain_code,              -- 納品先チェーンコード
        lv_sales_chain_code,                            -- 販売先チェーンコード
        lv_delivery_chain_code,                         -- 納品先チェーンコード
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        NULL,                                           -- 政策用チェーンコード
        NULL,                                           -- 紹介者チェーンコード１
        NULL,                                           -- 紹介者チェーンコード２
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
        --NULL,                                           -- 消費税区分
        lv_tax_div,                                     -- 消費税区分
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        NULL,                                           -- 消化計算用掛率
        NULL,                                           -- 入金値引率
        NULL,                                           -- 消化計算締め日１
        NULL,                                           -- 消化計算締め日２
        NULL,                                           -- 消化計算締め日３
        NULL,                                           -- 契約者仕入先コード
        NULL,                                           -- 紹介者BM支払仕入先コード１
        NULL,                                           -- 紹介者BM支払仕入先コード２
        NULL,                                           -- 配送順（EDI)
        NULL,                                           -- EDI地区コード（EDI)
        NULL,                                           -- EDI地区名（EDI)
        NULL,                                           -- EDI地区名カナ（EDI)
        NULL,                                           -- センターEDI区分
        NULL,                                           -- 通過在庫型区分（EDI）
        NULL,                                           -- 設置ロケーション
        NULL,                                           -- 物件オープン・クローズ区分
        NULL,                                           -- オペレーション区分
        NULL,                                           -- 釣銭
        NULL,                                           -- 自動販売機番号（相手先）
        NULL,                                           -- 設置先名（相手先）
        NULL,                                           -- 顧客獲得日
        NULL,                                           -- 獲得拠点コード
        NULL,                                           -- 獲得営業員
        NULL,                                           -- 新規ポイント区分
        NULL,                                           -- 新規ポイント
        NULL,                                           -- 紹介拠点コード
        NULL,                                           -- 紹介営業員
        NULL,                                           -- チェーン店コード(EDI)【親レコード用】
        NULL,                                           -- 緯度
        NULL,                                           -- 経度
        NULL,                                           -- 管理元拠点コード
        NULL,                                           -- EDI連携品目コード区分
        NULL,                                           -- EDI伝送追番
        NULL,                                           -- EDI手書伝票伝送区分
        NULL,                                           -- EDI納品センターコード
        NULL,                                           -- EDI納品センター名
        NULL,                                           -- 百貨店用HHT区分
        lv_bill_base_code,                              -- 請求拠点コード
        lv_receiv_base_code,                            -- 入金拠点コード
        NULL,                                           -- 百貨店伝区コード
        NULL,                                           -- 百貨店伝区コード【親レコード用】
        NULL,                                           -- 前月顧客ステータス
        NULL,                                           -- カード会社区分
        NULL,                                           -- カード会社
        lv_invoice_printing_unit,                       -- 請求書印刷単位
        NULL,                                           -- 請求書用コード
        NULL,                                           -- 統括請求書用コード
        NULL,                                           -- 店舗営業用顧客コード
        cn_created_by,                                  -- 作成者
        cd_creation_date,                               -- 作成日
        cn_last_updated_by,                             -- 最終更新者
        cd_last_update_date,                            -- 最終更新日
        cn_last_update_login,                           -- 最終更新ログイン
        cn_request_id,                                  -- 要求ID
        cn_program_application_id,                      -- コンカレント･プログラム･アプリケーションID
        cn_program_id,                                  -- コンカレント･プログラムID
        cd_program_update_date                          -- プログラム更新日
      )
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN                   -- 顧客追加情報登録エラー
        -- エラーメッセージ取得
        lv_api_nm        := cv_api_regist_resource;            -- API名
        lv_sql_errm      := SQLERRM;
        RAISE ins_xxcmm_cust_acct_expt;
    END;
--
  EXCEPTION
    --*** 顧客追加情報マスタ登録エラー ***
    WHEN ins_xxcmm_cust_acct_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10340            -- メッセージ
                    ,iv_token_name1  => cv_tkn_seq_num                -- トークンコード1
                    ,iv_token_value1 => i_wk_cust_rec.line_no         -- トークン値1
                    ,iv_token_name2  => cv_tkn_cust_code              -- トークンコード2
                    ,iv_token_value2 => lv_account_number             -- トークン値2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- トークンコード3
                    ,iv_token_value3 => lv_sql_errm                   -- トークン値3
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_cmm_cust_acct;
--
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  /**********************************************************************************
   * Procedure Name   : ins_cmm_mst_crprt
   * Description      : 顧客法人情報登録処理
   ***********************************************************************************/
  PROCEDURE ins_cmm_mst_crprt(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- 顧客一括登録ワーク情報
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- 退避KEY情報レコード
   ,ov_errbuf                  OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cmm_mst_crprt'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                     VARCHAR2(10);                                            -- ステップ
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_api_nm                   VARCHAR2(200);                                           -- API名
    lv_api_err_msg              VARCHAR2(2000);                                          -- APIエラーメッセージ
    lv_table_nm                 VARCHAR2(200);                                           -- テーブル名
--
    -- 退避用
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- 退避_顧客コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカルユーザー定義例外 ***
    ins_xxcmm_mst_crprt_expt    EXCEPTION;                                               -- 顧客法人情報マスタ登録エラー
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
    -- A-5.3 顧客法人情報マスタ登録
    --==============================================================
    lv_step := 'A-5.3';
    BEGIN
      lv_account_number        := io_save_cust_key_info_rec.lv_account_number; -- 顧客コード
      -- 顧客法人情報テーブルの登録
      INSERT INTO xxcmm_mst_corporate
      (
          customer_id                                            -- 顧客ID
         ,tdb_code                                               -- TDBコード
         ,base_code                                              -- 本部担当拠点
         ,credit_limit                                           -- 与信限度額
         ,decide_div                                             -- 判定区分
         ,approval_date                                          -- 決裁日付
         ,enterprise_group_code                                  -- 企業グループコード
         ,representative_name                                    -- 代表者名
         ,applicant_base_code                                    -- 申請拠点
         ,created_by                                             -- 作成者
         ,creation_date                                          -- 作成日
         ,last_updated_by                                        -- 最終更新者
         ,last_update_date                                       -- 最終更新日
         ,last_update_login                                      -- 最終更新ログイン
         ,request_id                                             -- 要求ID
         ,program_application_id                                 -- コンカレント･プログラム･アプリケーションID
         ,program_id                                             -- コンカレント･プログラムID
         ,program_update_date                                    -- プログラム更新日
      )
      VALUES
      (
          io_save_cust_key_info_rec.ln_cust_account_id           -- 顧客ID
         ,i_wk_cust_rec.tdb_code                                 -- TDBコード
         ,i_wk_cust_rec.base_code                                -- 本部担当拠点
         ,TO_NUMBER(i_wk_cust_rec.credit_limit)                  -- 与信限度額
         ,i_wk_cust_rec.decide_div                               -- 判定区分
         ,TO_DATE(i_wk_cust_rec.approval_date , cv_date_fmt_std) -- 決裁日付
         ,NULL                                                   -- 企業グループコード
         ,NULL                                                   -- 代表者名
         ,NULL                                                   -- 申請拠点
         ,cn_created_by                                          -- 作成者
         ,cd_creation_date                                       -- 作成日
         ,cn_last_updated_by                                     -- 最終更新者
         ,cd_last_update_date                                    -- 最終更新日
         ,cn_last_update_login                                   -- 最終更新ログイン
         ,cn_request_id                                          -- 要求ID
         ,cn_program_application_id                              -- コンカレント･プログラム･アプリケーションID
         ,cn_program_id                                          -- コンカレント･プログラムID
         ,cd_program_update_date                                 -- プログラム更新日
      )
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN                   -- 顧客法人情報登録エラー
        -- エラーメッセージ取得
        lv_api_nm        := cv_api_regist_resource;            -- API名
        lv_sql_errm      := SQLERRM;
        RAISE ins_xxcmm_mst_crprt_expt;
    END;
--
  EXCEPTION
    --*** 顧客法人情報マスタ登録エラー ***
    WHEN ins_xxcmm_mst_crprt_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10344            -- メッセージ
                    ,iv_token_name1  => cv_tkn_seq_num                -- トークンコード1
                    ,iv_token_value1 => i_wk_cust_rec.line_no         -- トークン値1
                    ,iv_token_name2  => cv_tkn_cust_code              -- トークンコード2
                    ,iv_token_value2 => lv_account_number             -- トークン値2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- トークンコード3
                    ,iv_token_value3 => lv_sql_errm                   -- トークン値3
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_cmm_mst_crprt;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 顧客一括登録ワークデータ取得 (A-3)
   ***********************************************************************************/
  PROCEDURE loop_main(
    iv_file_id    IN  VARCHAR2          -- 1.ファイルID
   ,iv_format     IN  VARCHAR2          -- 2.フォーマット
   ,ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- プログラム名
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
    lv_step                   VARCHAR2(10);                                     -- ステップ
    ln_line_cnt               NUMBER;                                           -- 行カウンタ
    lv_check_flag             VARCHAR2(1);                                      -- チェックフラグ
    lv_error_flag             VARCHAR2(1);                                      -- 退避用リターン・コード
    ln_request_id             NUMBER;                                           -- 要求ID
    lv_status_val             VARCHAR2(5000);                                   -- ステータス値
--
    l_save_cust_key_info_rec  save_cust_key_info_rtype;                         -- 退避KEY情報レコード
--
    -- *** ローカル・カーソル ***
    -- 顧客一括登録ワークデータ取得カーソル
    CURSOR get_data_cur
    IS
      SELECT     xwcu.file_id                             -- ファイルID
                ,xwcu.line_no                             -- 行番号
                ,xwcu.customer_name                       -- 顧客名
                ,xwcu.customer_name_kana                  -- 顧客名カナ
                ,xwcu.customer_name_ryaku                 -- 略称
                ,xwcu.customer_class_code                 -- 顧客区分
                ,xwcu.customer_status                     -- 顧客ステータス
                ,xwcu.sale_base_code                      -- 売上拠点
                ,xwcu.sales_chain_code                    -- 販売先チェーン
                ,xwcu.delivery_chain_code                 -- 納品先チェーン
                ,xwcu.postal_code                         -- 郵便番号
                ,xwcu.state                               -- 都道府県
                ,xwcu.city                                -- 市・区
                ,xwcu.address1                            -- 住所１
                ,xwcu.address2                            -- 住所２
                ,xwcu.address3                            -- 地区コード
                ,xwcu.tel_no                              -- 電話番号
                ,xwcu.fax                                 -- FAX
                ,xwcu.business_low_type_tmp               -- 業態小分類(仮)
                ,xwcu.manager_name                        -- 店長名
                ,xwcu.emp_number                          -- 社員数
                ,xwcu.rest_emp_name                       -- 担当者休日
                ,xwcu.mc_hot_deg                          -- MC：HOT度
                ,xwcu.mc_importance_deg                   -- MC：重要度
                ,xwcu.mc_conf_info                        -- MC：競合情報
                ,xwcu.mc_business_talk_details            -- MC：商談経緯
                ,xwcu.resource_no                         -- 担当営業員
                ,xwcu.resource_s_date                     -- 適用開始日(担当営業員)
                ,xwcu.business_low_type                   -- 業態小分類
                ,xwcu.industry_div                        -- 業種
                ,xwcu.torihiki_form                       -- 取引形態
                ,xwcu.delivery_form                       -- 配送形態
                ,xwcu.created_by                          -- 作成者
                ,xwcu.creation_date                       -- 作成日
                ,xwcu.last_updated_by                     -- 最終更新者
                ,xwcu.last_update_date                    -- 最終更新日
                ,xwcu.last_update_login                   -- 最終更新ログインID
                ,xwcu.request_id                          -- 要求ID
                ,xwcu.program_application_id              -- コンカレント・プログラムのアプリケーションID
                ,xwcu.program_id                          -- コンカレント・プログラムID
                ,xwcu.program_update_date                 -- プログラムによる更新日
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
                ,xwcu.tdb_code                            -- TDBコード
                ,xwcu.base_code                           -- 本部担当拠点
                ,xwcu.credit_limit                        -- 与信限度額
                ,xwcu.decide_div                          -- 判定区分
                ,xwcu.approval_date                       -- 決裁日付
                ,xwcu.tax_div                             -- 消費税区分
                ,xwcu.tax_rounding_rule                   -- 税金端数処理
                ,xwcu.invoice_grp_code                    -- 売掛コード1（請求書）
                ,xwcu.output_form                         -- 請求書出力形式
                ,xwcu.prt_cycle                           -- 請求書発行サイクル
                ,xwcu.payment_term                        -- 支払条件
                ,xwcu.delivery_base_code                  -- 納品拠点
                ,xwcu.bill_base_code                      -- 請求拠点
                ,xwcu.receiv_base_code                    -- 入金拠点
                ,xwcu.sales_head_base_code                -- 販売先本部担当拠点
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      FROM       xxcmm_wk_cust_upload  xwcu               -- 顧客一括登録ワーク
      WHERE      xwcu.request_id = cn_request_id          -- 要求ID
      ORDER BY   xwcu.line_no                             -- ファイルSEQ
      ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    -- 初期化
    lv_check_flag            := cv_status_normal;
    ln_line_cnt              := 0;
    --
    <<main_loop>>
    FOR get_data_rec IN get_data_cur LOOP
      -- 初期化
      lv_error_flag := cv_status_normal;
      -- 行カウンタアップ
      ln_line_cnt := ln_line_cnt + 1;
      --
      --==============================================================
      -- A-4  データ妥当性チェック
      --==============================================================
      lv_step := 'A-4';
      validate_cust_wk(
        i_wk_cust_rec  => get_data_rec             -- 顧客一括登録ワーク情報
       ,ov_errbuf      => lv_errbuf                -- エラー・メッセージ
       ,ov_retcode     => lv_retcode               -- リターン・コード
       ,ov_errmsg      => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      --
      -- 処理結果チェック
      IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  データ登録
          --  A-5.1-1  顧客マスタ登録用レコード作成
          --  A-5.1-2  顧客マスタ登録処理
          --==============================================================
          lv_step := 'A-5';
          ins_cust_acct_api(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  データ登録
          --  A-5.1-3  顧客所在地マスタ登録用レコード作成
          --  A-5.1-4  顧客所在地マスタ登録処理
          --==============================================================
          ins_location_api(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  データ登録
          --  A-5.1-5  パーティサイトマスタ登録用レコード作成
          --  A-5.1-6  パーティサイトマスタ登録処理
          --==============================================================
          ins_party_site_api(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  データ登録
          --  A-5.1-7  顧客サイトマスタ登録用レコード作成
          --  A-5.1-8  顧客サイトマスタ登録処理
          --==============================================================
          ins_cust_acct_site_api(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal )
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
          --AND ( gv_format = cv_file_format_mc ) THEN
          -- フォーマットパターン「501:MC顧客」もしくは「504:売掛管理」の場合
          AND ( gv_format IN ( cv_file_format_mc , cv_file_format_ur ) )THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
          --==============================================================
          -- A-5  データ登録
          --  A-5.1-9  顧客使用目的マスタ(請求先)登録用レコード作成
          --  A-5.1-10 顧客使用目的マスタ(請求先)登録処理
          --==============================================================
          ins_bill_to_api(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal )
          AND ( gv_format = cv_file_format_mc ) THEN
          --==============================================================
          -- A-5  データ登録
          --  A-5.1-11 顧客使用目的マスタ(出荷先)登録用レコード作成
          --  A-5.1-12 顧客使用目的マスタ(出荷先)登録処理
          --==============================================================
          ins_ship_to_api(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal )
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
          --AND ( gv_format = cv_file_format_st ) THEN
          -- フォーマットパターン「502:店舗営業」もしくは「503:法人」の場合
          AND ( gv_format IN ( cv_file_format_st , cv_file_format_ho )) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
          --==============================================================
          -- A-5  データ登録
          --  A-5.1-13 顧客使用目的マスタ(その他)登録用レコード作成
          --  A-5.1-14 顧客使用目的マスタ(その他)登録処理
          --==============================================================
          ins_other_to_api(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal )
          AND ( gv_format = cv_file_format_mc ) THEN
          --==============================================================
          -- A-5  データ登録
          --  A-5.1-15  組織プロファイル拡張(担当営業員)登録処理
          --==============================================================
          regist_resource_no_api(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  データ登録
          --  A-5.2-1 顧客追加情報登録処理
          --==============================================================
          ins_cmm_cust_acct(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal )
          -- フォーマットパターン「503:法人」の場合
          AND ( gv_format = cv_file_format_ho ) THEN
          --==============================================================
          -- A-5  データ登録
          --  A-5.3-1 顧客法人情報登録処理
          --==============================================================
          ins_cmm_mst_crprt(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal ) THEN
          -- 顧客登録結果をログ出力用テーブルに格納する
          add_report(
            i_wk_cust_rec               => get_data_rec             -- 顧客一括登録ワーク情報
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- 退避KEY情報レコード
           ,ov_errbuf                   => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode                  => lv_retcode               -- リターン・コード
           ,ov_errmsg                   => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        END IF;
      ELSE
        -- データ妥当性チェックエラーの場合
        -- エラーステータス退避
        lv_check_flag := cv_status_error;
        lv_error_flag := lv_retcode;
      END IF;
      --
      -- 処理結果をセット
      lv_error_flag := lv_retcode;
      --
      --==============================================================
      -- 処理件数加算
      --==============================================================
      IF ( lv_error_flag = cv_status_normal ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt + 1;
        lv_check_flag := cv_status_error;
      END IF;
    END LOOP main_loop;
  --
  -- 妥当性、登録エラーの場合、エラーをセット
  IF ( lv_check_flag = cv_status_error ) THEN
    lv_retcode := cv_status_error;
  END IF;
  -- 処理結果が正常であればCOMMIT、正常以外であればROLLBACK
  IF ( lv_retcode = cv_status_normal ) THEN
    COMMIT;
  ELSE
    ROLLBACK;
  END IF;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_main;
--
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';        -- プログラム名
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    --
    ln_line_cnt               NUMBER;                                 -- 行カウンタ
    ln_item_num               NUMBER;                                 -- 項目数
    ln_item_cnt               NUMBER;                                 -- 項目数カウンタ
    lv_file_name              VARCHAR2(100);                          -- ファイル名格納用
    ln_ins_item_cnt           NUMBER;                                 -- 登録件数カウンタ
--
    l_wk_item_tab             g_check_data_ttype;                     -- テーブル型変数を宣言(項目分割)
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      -- テーブル型変数を宣言
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_if_data_expt          EXCEPTION;                              -- データ項目数エラー例外
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    ln_ins_item_cnt := 0;
    --
    --==============================================================
    -- A-2.1 対象データの分割(レコード分割)
    --==============================================================
    lv_step := 'A-2.1';
    xxccp_common_pkg2.blob_to_varchar2(          -- BLOBデータ変換共通関数
      in_file_id   => gn_file_id                 -- ファイルID
     ,ov_file_data => l_if_data_tab              -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    ------------------
    -- レコードLOOP
    ------------------
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 1..l_if_data_tab.COUNT LOOP
      ------------------
      -- ヘッダレコード
      -- 1行目：タイトル行
      ------------------
      IF ( ln_line_cnt > 1 ) THEN
        ------------------
        -- 明細レコード
        ------------------
        --==============================================================
        -- A-2.2 項目数のチェック
        --==============================================================
        lv_step := 'A-2.2';
        -- データ項目数を格納
        ln_item_num := ( LENGTHB(l_if_data_tab( ln_line_cnt))
                     - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '')))
                     + 1);
        -- 項目数が一致しない場合
        IF ( gn_item_num <> ln_item_num ) THEN
          RAISE get_if_data_expt;
        END IF;
        --
        --==============================================================
        -- A-2.3.1 対象データの分割(項目分割)
        --==============================================================
        lv_step := 'A-2.3.1';
        <<get_column_loop>>
        FOR ln_item_cnt IN 1..gn_item_num LOOP
          -- 変数に項目の値を格納
          l_wk_item_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(  -- デリミタ文字変換共通関数
                                          iv_char     => l_if_data_tab(ln_line_cnt)
                                         ,iv_delim    => cv_msg_comma
                                         ,in_part_num => ln_item_cnt
                                        );
        END LOOP get_column_loop;
        --
        --==============================================================
        -- A-2.4 顧客一括登録ワークへ登録
        --==============================================================
        lv_step := 'A-2.4';
        BEGIN
          ln_ins_item_cnt := ln_ins_item_cnt + 1;
          --
          -- フォーマットパターン「501:MC顧客」の場合
          IF ( gv_format = cv_file_format_mc ) THEN
            INSERT INTO xxcmm_wk_cust_upload(
              file_id                       -- ファイルID
             ,line_no                       -- 行番号
             ,customer_name                 -- 顧客名
             ,customer_name_kana            -- 顧客名カナ
             ,customer_name_ryaku           -- 略称
             ,customer_class_code           -- 顧客区分
             ,customer_status               -- 顧客ステータス
             ,sale_base_code                -- 売上拠点
             ,sales_chain_code              -- 販売先チェーン
             ,delivery_chain_code           -- 納品先チェーン
             ,postal_code                   -- 郵便番号
             ,state                         -- 都道府県
             ,city                          -- 市・区
             ,address1                      -- 住所１
             ,address2                      -- 住所２
             ,address3                      -- 地区コード
             ,tel_no                        -- 電話番号
             ,fax                           -- FAX
             ,business_low_type_tmp         -- 業態小分類(仮)
             ,manager_name                  -- 店長名
             ,emp_number                    -- 社員数
             ,rest_emp_name                 -- 担当者休日
             ,mc_hot_deg                    -- MC：HOT度
             ,mc_importance_deg             -- MC：重要度
             ,mc_conf_info                  -- MC：競合情報
             ,mc_business_talk_details      -- MC：商談経緯
             ,resource_no                   -- 担当営業員
             ,resource_s_date               -- 適用開始日(担当営業員)
             ,business_low_type             -- 業態小分類
             ,industry_div                  -- 業種
             ,torihiki_form                 -- 取引形態
             ,delivery_form                 -- 配送形態
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
             ,tdb_code                      -- TDBコード
             ,base_code                     -- 本部担当拠点
             ,credit_limit                  -- 与信限度額
             ,decide_div                    -- 判定区分
             ,approval_date                 -- 決裁日付
             ,tax_div                       -- 消費税区分
             ,tax_rounding_rule             -- 税金端数処理
             ,invoice_grp_code              -- 売掛コード1（請求書）
             ,output_form                   -- 請求書出力形式
             ,prt_cycle                     -- 請求書発行サイクル
             ,payment_term                  -- 支払条件
             ,delivery_base_code            -- 納品拠点
             ,bill_base_code                -- 請求拠点
             ,receiv_base_code              -- 入金拠点
             ,sales_head_base_code          -- 販売先本部担当拠点
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
             ,created_by                    -- 作成者
             ,creation_date                 -- 作成日
             ,last_updated_by               -- 最終更新者
             ,last_update_date              -- 最終更新日
             ,last_update_login             -- 最終更新ログインID
             ,request_id                    -- 要求ID
             ,program_application_id        -- コンカレント・プログラムのアプリケーションID
             ,program_id                    -- コンカレント・プログラムID
             ,program_update_date           -- プログラムによる更新日
             ) VALUES (
              gn_file_id                    -- ファイルID
             ,ln_ins_item_cnt               -- ファイルSEQ
             ,l_wk_item_tab(1)              -- 顧客名
             ,l_wk_item_tab(2)              -- 顧客名カナ
             ,l_wk_item_tab(3)              -- 略称
             ,NULL                          -- 顧客区分
             ,l_wk_item_tab(4)              -- 顧客ステータス
             ,l_wk_item_tab(5)              -- 売上拠点
             ,l_wk_item_tab(6)              -- 販売先チェーン
             ,l_wk_item_tab(7)              -- 納品先チェーン
             ,l_wk_item_tab(8)              -- 郵便番号
             ,l_wk_item_tab(9)              -- 都道府県
             ,l_wk_item_tab(10)             -- 市・区
             ,l_wk_item_tab(11)             -- 住所１
             ,l_wk_item_tab(12)             -- 住所２
             ,l_wk_item_tab(13)             -- 地区コード
             ,l_wk_item_tab(14)             -- 電話番号
             ,l_wk_item_tab(15)             -- FAX
             ,l_wk_item_tab(16)             -- 業態小分類(仮)
             ,l_wk_item_tab(17)             -- 店長名
             ,l_wk_item_tab(18)             -- 社員数
             ,l_wk_item_tab(19)             -- 担当者休日
             ,l_wk_item_tab(20)             -- MC：HOT度
             ,l_wk_item_tab(21)             -- MC：重要度
             ,l_wk_item_tab(22)             -- MC：競合情報
             ,l_wk_item_tab(23)             -- MC：商談経緯
             ,l_wk_item_tab(24)             -- 担当営業員
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 delete start by Shigeto.Niki
--             ,l_wk_item_tab(25)             -- 適用開始日(担当営業員)
             ,gd_process_date               -- 業務日付
-- 2010/11/05 Ver1.1 障害：E_本稼動_05492 delete end by Shigeto.Niki
             ,NULL                          -- 業態小分類
             ,NULL                          -- 業種
             ,NULL                          -- 取引形態
             ,NULL                          -- 配送形態
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
             ,NULL                          -- TDBコード
             ,NULL                          -- 本部担当拠点
             ,NULL                          -- 与信限度額
             ,NULL                          -- 判定区分
             ,NULL                          -- 決裁日付
             ,NULL                          -- 消費税区分
             ,NULL                          -- 税金端数処理
             ,NULL                          -- 売掛コード1（請求書）
             ,NULL                          -- 請求書出力形式
             ,NULL                          -- 請求書発行サイクル
             ,NULL                          -- 支払条件
             ,NULL                          -- 納品拠点
             ,NULL                          -- 請求拠点
             ,NULL                          -- 入金拠点
             ,NULL                          -- 販売先本部担当拠点
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
             ,cn_created_by                 -- 作成者
             ,cd_creation_date              -- 作成日
             ,cn_last_updated_by            -- 最終更新者
             ,cd_last_update_date           -- 最終更新日
             ,cn_last_update_login          -- 最終更新ログインID
             ,cn_request_id                 -- 要求ID
             ,cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                 -- コンカレント・プログラムID
             ,cd_program_update_date        -- プログラムによる更新日
            );
          -- フォーマットパターン「502:店舗営業」の場合
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
          --ELSE
          ELSIF  ( gv_format = cv_file_format_st ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
            INSERT INTO xxcmm_wk_cust_upload(
              file_id                       -- ファイルID
             ,line_no                       -- 行番号
             ,customer_name                 -- 顧客名
             ,customer_name_kana            -- 顧客名カナ
             ,customer_name_ryaku           -- 略称
             ,customer_class_code           -- 顧客区分
             ,customer_status               -- 顧客ステータス
             ,sale_base_code                -- 売上拠点
             ,sales_chain_code              -- 販売先チェーン
             ,delivery_chain_code           -- 納品先チェーン
             ,postal_code                   -- 郵便番号
             ,state                         -- 都道府県
             ,city                          -- 市・区
             ,address1                      -- 住所１
             ,address2                      -- 住所２
             ,address3                      -- 地区コード
             ,tel_no                        -- 電話番号
             ,fax                           -- FAX
             ,business_low_type_tmp         -- 業態小分類(仮)
             ,manager_name                  -- 店長名
             ,emp_number                    -- 社員数
             ,rest_emp_name                 -- 担当者休日
             ,mc_hot_deg                    -- MC：HOT度
             ,mc_importance_deg             -- MC：重要度
             ,mc_conf_info                  -- MC：競合情報
             ,mc_business_talk_details      -- MC：商談経緯
             ,resource_no                   -- 担当営業員
             ,resource_s_date               -- 適用開始日(担当営業員)
             ,business_low_type             -- 業態小分類
             ,industry_div                  -- 業種
             ,torihiki_form                 -- 取引形態
             ,delivery_form                 -- 配送形態
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
             ,tdb_code                      -- TDBコード
             ,base_code                     -- 本部担当拠点
             ,credit_limit                  -- 与信限度額
             ,decide_div                    -- 判定区分
             ,approval_date                 -- 決裁日付
             ,tax_div                       -- 消費税区分
             ,tax_rounding_rule             -- 税金端数処理
             ,invoice_grp_code              -- 売掛コード1（請求書）
             ,output_form                   -- 請求書出力形式
             ,prt_cycle                     -- 請求書発行サイクル
             ,payment_term                  -- 支払条件
             ,delivery_base_code            -- 納品拠点
             ,bill_base_code                -- 請求拠点
             ,receiv_base_code              -- 入金拠点
             ,sales_head_base_code          -- 販売先本部担当拠点
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
             ,created_by                    -- 作成者
             ,creation_date                 -- 作成日
             ,last_updated_by               -- 最終更新者
             ,last_update_date              -- 最終更新日
             ,last_update_login             -- 最終更新ログインID
             ,request_id                    -- 要求ID
             ,program_application_id        -- コンカレント・プログラムのアプリケーションID
             ,program_id                    -- コンカレント・プログラムID
             ,program_update_date           -- プログラムによる更新日
             ) VALUES (
              gn_file_id                    -- ファイルID
             ,ln_ins_item_cnt               -- ファイルSEQ
             ,l_wk_item_tab(1)              -- 顧客名
             ,l_wk_item_tab(2)              -- 顧客名カナ
             ,l_wk_item_tab(3)              -- 略称
             ,l_wk_item_tab(4)              -- 顧客区分
             ,l_wk_item_tab(5)              -- 顧客ステータス
             ,l_wk_item_tab(6)              -- 売上拠点
             ,l_wk_item_tab(7)              -- 販売先チェーン
             ,l_wk_item_tab(8)              -- 納品先チェーン
             ,l_wk_item_tab(9)              -- 郵便番号
             ,l_wk_item_tab(10)             -- 都道府県
             ,l_wk_item_tab(11)             -- 市・区
             ,l_wk_item_tab(12)             -- 住所１
             ,l_wk_item_tab(13)             -- 住所２
             ,l_wk_item_tab(14)             -- 地区コード
             ,l_wk_item_tab(15)             -- 電話番号
             ,l_wk_item_tab(16)             -- FAX
             ,NULL                          -- 業態小分類(仮)
             ,NULL                          -- 店長名
             ,NULL                          -- 社員数
             ,NULL                          -- 担当者休日
             ,NULL                          -- MC：HOT度
             ,NULL                          -- MC：重要度
             ,NULL                          -- MC：競合情報
             ,NULL                          -- MC：商談経緯
             ,NULL                          -- 担当営業員
             ,NULL                          -- 適用開始日(担当営業員)
             ,l_wk_item_tab(17)             -- 業態小分類
             ,l_wk_item_tab(18)             -- 業種
             ,l_wk_item_tab(19)             -- 取引形態
             ,l_wk_item_tab(20)             -- 配送形態
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
             ,NULL                          -- TDBコード
             ,NULL                          -- 本部担当拠点
             ,NULL                          -- 与信限度額
             ,NULL                          -- 判定区分
             ,NULL                          -- 決裁日付
             ,NULL                          -- 消費税区分
             ,NULL                          -- 税金端数処理
             ,NULL                          -- 売掛コード1（請求書）
             ,NULL                          -- 請求書出力形式
             ,NULL                          -- 請求書発行サイクル
             ,NULL                          -- 支払条件
             ,NULL                          -- 納品拠点
             ,NULL                          -- 請求拠点
             ,NULL                          -- 入金拠点
             ,NULL                          -- 販売先本部担当拠点
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
             ,cn_created_by                 -- 作成者
             ,cd_creation_date              -- 作成日
             ,cn_last_updated_by            -- 最終更新者
             ,cd_last_update_date           -- 最終更新日
             ,cn_last_update_login          -- 最終更新ログインID
             ,cn_request_id                 -- 要求ID
             ,cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                 -- コンカレント・プログラムID
             ,cd_program_update_date        -- プログラムによる更新日
            );
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
          -- フォーマットパターン「503:法人」の場合
          ELSIF  ( gv_format = cv_file_format_ho ) THEN
            INSERT INTO xxcmm_wk_cust_upload(
              file_id                       -- ファイルID
             ,line_no                       -- 行番号
             ,customer_name                 -- 顧客名
             ,customer_name_kana            -- 顧客名カナ
             ,customer_name_ryaku           -- 略称
             ,customer_class_code           -- 顧客区分
             ,customer_status               -- 顧客ステータス
             ,sale_base_code                -- 売上拠点
             ,sales_chain_code              -- 販売先チェーン
             ,delivery_chain_code           -- 納品先チェーン
             ,postal_code                   -- 郵便番号
             ,state                         -- 都道府県
             ,city                          -- 市・区
             ,address1                      -- 住所１
             ,address2                      -- 住所２
             ,address3                      -- 地区コード
             ,tel_no                        -- 電話番号
             ,fax                           -- FAX
             ,business_low_type_tmp         -- 業態小分類(仮)
             ,manager_name                  -- 店長名
             ,emp_number                    -- 社員数
             ,rest_emp_name                 -- 担当者休日
             ,mc_hot_deg                    -- MC：HOT度
             ,mc_importance_deg             -- MC：重要度
             ,mc_conf_info                  -- MC：競合情報
             ,mc_business_talk_details      -- MC：商談経緯
             ,resource_no                   -- 担当営業員
             ,resource_s_date               -- 適用開始日(担当営業員)
             ,business_low_type             -- 業態小分類
             ,industry_div                  -- 業種
             ,torihiki_form                 -- 取引形態
             ,delivery_form                 -- 配送形態
             ,tdb_code                      -- TDBコード
             ,base_code                     -- 本部担当拠点
             ,credit_limit                  -- 与信限度額
             ,decide_div                    -- 判定区分
             ,approval_date                 -- 決裁日付
             ,tax_div                       -- 消費税区分
             ,tax_rounding_rule             -- 税金端数処理
             ,invoice_grp_code              -- 売掛コード1（請求書）
             ,output_form                   -- 請求書出力形式
             ,prt_cycle                     -- 請求書発行サイクル
             ,payment_term                  -- 支払条件
             ,delivery_base_code            -- 納品拠点
             ,bill_base_code                -- 請求拠点
             ,receiv_base_code              -- 入金拠点
             ,sales_head_base_code          -- 販売先本部担当拠点
             ,created_by                    -- 作成者
             ,creation_date                 -- 作成日
             ,last_updated_by               -- 最終更新者
             ,last_update_date              -- 最終更新日
             ,last_update_login             -- 最終更新ログインID
             ,request_id                    -- 要求ID
             ,program_application_id        -- コンカレント・プログラムのアプリケーションID
             ,program_id                    -- コンカレント・プログラムID
             ,program_update_date           -- プログラムによる更新日
             ) VALUES (
              gn_file_id                    -- ファイルID
             ,ln_ins_item_cnt               -- ファイルSEQ
             ,l_wk_item_tab(1)              -- 顧客名
             ,l_wk_item_tab(2)              -- 顧客名カナ
             ,l_wk_item_tab(3)              -- 略称
             ,l_wk_item_tab(4)              -- 顧客区分
             ,l_wk_item_tab(5)              -- 顧客ステータス
             ,l_wk_item_tab(6)              -- 売上拠点
             ,NULL                          -- 販売先チェーン
             ,NULL                          -- 納品先チェーン
             ,l_wk_item_tab(7)              -- 郵便番号
             ,l_wk_item_tab(8)              -- 都道府県
             ,l_wk_item_tab(9)              -- 市・区
             ,l_wk_item_tab(10)             -- 住所１
             ,l_wk_item_tab(11)             -- 住所２
             ,l_wk_item_tab(12)             -- 地区コード
             ,l_wk_item_tab(13)             -- 電話番号
             ,l_wk_item_tab(14)             -- FAX
             ,NULL                          -- 業態小分類(仮)
             ,NULL                          -- 店長名
             ,NULL                          -- 社員数
             ,NULL                          -- 担当者休日
             ,NULL                          -- MC：HOT度
             ,NULL                          -- MC：重要度
             ,NULL                          -- MC：競合情報
             ,NULL                          -- MC：商談経緯
             ,NULL                          -- 担当営業員
             ,NULL                          -- 適用開始日(担当営業員)
             ,NULL                          -- 業態小分類
             ,NULL                          -- 業種
             ,NULL                          -- 取引形態
             ,NULL                          -- 配送形態
             ,l_wk_item_tab(15)             -- TDBコード
             ,l_wk_item_tab(16)             -- 本部担当拠点
             ,l_wk_item_tab(17)             -- 与信限度額
             ,l_wk_item_tab(18)             -- 判定区分
             ,l_wk_item_tab(19)             -- 決裁日付
             ,NULL                          -- 消費税区分
             ,NULL                          -- 税金端数処理
             ,NULL                          -- 売掛コード1（請求書）
             ,NULL                          -- 請求書出力形式
             ,NULL                          -- 請求書発行サイクル
             ,NULL                          -- 支払条件
             ,NULL                          -- 納品拠点
             ,NULL                          -- 請求拠点
             ,NULL                          -- 入金拠点
             ,NULL                          -- 販売先本部担当拠点
             ,cn_created_by                 -- 作成者
             ,cd_creation_date              -- 作成日
             ,cn_last_updated_by            -- 最終更新者
             ,cd_last_update_date           -- 最終更新日
             ,cn_last_update_login          -- 最終更新ログインID
             ,cn_request_id                 -- 要求ID
             ,cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                 -- コンカレント・プログラムID
             ,cd_program_update_date        -- プログラムによる更新日
            );
          -- フォーマットパターン「504:売掛管理」の場合
          ELSIF  ( gv_format = cv_file_format_ur ) THEN
            INSERT INTO xxcmm_wk_cust_upload(
              file_id                       -- ファイルID
             ,line_no                       -- 行番号
             ,customer_name                 -- 顧客名
             ,customer_name_kana            -- 顧客名カナ
             ,customer_name_ryaku           -- 略称
             ,customer_class_code           -- 顧客区分
             ,customer_status               -- 顧客ステータス
             ,sale_base_code                -- 売上拠点
             ,sales_chain_code              -- 販売先チェーン
             ,delivery_chain_code           -- 納品先チェーン
             ,postal_code                   -- 郵便番号
             ,state                         -- 都道府県
             ,city                          -- 市・区
             ,address1                      -- 住所１
             ,address2                      -- 住所２
             ,address3                      -- 地区コード
             ,tel_no                        -- 電話番号
             ,fax                           -- FAX
             ,business_low_type_tmp         -- 業態小分類(仮)
             ,manager_name                  -- 店長名
             ,emp_number                    -- 社員数
             ,rest_emp_name                 -- 担当者休日
             ,mc_hot_deg                    -- MC：HOT度
             ,mc_importance_deg             -- MC：重要度
             ,mc_conf_info                  -- MC：競合情報
             ,mc_business_talk_details      -- MC：商談経緯
             ,resource_no                   -- 担当営業員
             ,resource_s_date               -- 適用開始日(担当営業員)
             ,business_low_type             -- 業態小分類
             ,industry_div                  -- 業種
             ,torihiki_form                 -- 取引形態
             ,delivery_form                 -- 配送形態
             ,tdb_code                      -- TDBコード
             ,base_code                     -- 本部担当拠点
             ,credit_limit                  -- 与信限度額
             ,decide_div                    -- 判定区分
             ,approval_date                 -- 決裁日付
             ,tax_div                       -- 消費税区分
             ,tax_rounding_rule             -- 税金端数処理
             ,invoice_grp_code              -- 売掛コード1（請求書）
             ,output_form                   -- 請求書出力形式
             ,prt_cycle                     -- 請求書発行サイクル
             ,payment_term                  -- 支払条件
             ,delivery_base_code            -- 納品拠点
             ,bill_base_code                -- 請求拠点
             ,receiv_base_code              -- 入金拠点
             ,sales_head_base_code          -- 販売先本部担当拠点
             ,created_by                    -- 作成者
             ,creation_date                 -- 作成日
             ,last_updated_by               -- 最終更新者
             ,last_update_date              -- 最終更新日
             ,last_update_login             -- 最終更新ログインID
             ,request_id                    -- 要求ID
             ,program_application_id        -- コンカレント・プログラムのアプリケーションID
             ,program_id                    -- コンカレント・プログラムID
             ,program_update_date           -- プログラムによる更新日
             ) VALUES (
              gn_file_id                    -- ファイルID
             ,ln_ins_item_cnt               -- ファイルSEQ
             ,l_wk_item_tab(1)              -- 顧客名
             ,l_wk_item_tab(2)              -- 顧客名カナ
             ,l_wk_item_tab(3)              -- 略称
             ,l_wk_item_tab(4)              -- 顧客区分
             ,l_wk_item_tab(5)              -- 顧客ステータス
             ,l_wk_item_tab(6)              -- 売上拠点
             ,l_wk_item_tab(7)              -- 販売先チェーン
             ,l_wk_item_tab(8)              -- 納品先チェーン
             ,l_wk_item_tab(9)              -- 郵便番号
             ,l_wk_item_tab(10)             -- 都道府県
             ,l_wk_item_tab(11)             -- 市・区
             ,l_wk_item_tab(12)             -- 住所１
             ,l_wk_item_tab(13)             -- 住所２
             ,l_wk_item_tab(14)             -- 地区コード
             ,l_wk_item_tab(15)             -- 電話番号
             ,l_wk_item_tab(16)             -- FAX
             ,NULL                          -- 業態小分類(仮)
             ,NULL                          -- 店長名
             ,NULL                          -- 社員数
             ,NULL                          -- 担当者休日
             ,NULL                          -- MC：HOT度
             ,NULL                          -- MC：重要度
             ,NULL                          -- MC：競合情報
             ,NULL                          -- MC：商談経緯
             ,NULL                          -- 担当営業員
             ,NULL                          -- 適用開始日(担当営業員)
             ,l_wk_item_tab(17)             -- 業態小分類
             ,l_wk_item_tab(18)             -- 業種
             ,NULL                          -- 取引形態
             ,NULL                          -- 配送形態
             ,NULL                          -- TDBコード
             ,NULL                          -- 本部担当拠点
             ,NULL                          -- 与信限度額
             ,NULL                          -- 判定区分
             ,NULL                          -- 決裁日付
             ,l_wk_item_tab(19)             -- 消費税区分
             ,l_wk_item_tab(20)             -- 税金端数処理
             ,l_wk_item_tab(21)             -- 売掛コード1（請求書）
             ,l_wk_item_tab(22)             -- 請求書出力形式
             ,l_wk_item_tab(23)             -- 請求書発行サイクル
             ,l_wk_item_tab(24)             -- 支払条件
             ,l_wk_item_tab(25)             -- 納品拠点
             ,l_wk_item_tab(26)             -- 請求拠点
             ,l_wk_item_tab(27)             -- 入金拠点
             ,l_wk_item_tab(28)             -- 販売先本部担当拠点
             ,cn_created_by                 -- 作成者
             ,cd_creation_date              -- 作成日
             ,cn_last_updated_by            -- 最終更新者
             ,cd_last_update_date           -- 最終更新日
             ,cn_last_update_login          -- 最終更新ログインID
             ,cn_request_id                 -- 要求ID
             ,cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                 -- コンカレント・プログラムID
             ,cd_program_update_date        -- プログラムによる更新日
            );
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
          END IF;
        EXCEPTION
          -- *** データ登録例外ハンドラ ***
          WHEN OTHERS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcmm       -- アプリケーション短縮名
                           ,iv_name         => cv_msg_xxcmm_10335       -- メッセージコード
                           ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                           ,iv_token_value1 => cv_table_xwcu            -- トークン値1
                           ,iv_token_name2  => cv_tkn_input_line_no     -- トークンコード2
                           ,iv_token_value2 => ln_ins_item_cnt          -- トークン値2
                           ,iv_token_name3  => cv_tkn_errmsg            -- トークンコード4
                           ,iv_token_value3 => SQLERRM                  -- トークン値4
                          );
            lv_errbuf  := lv_errmsg;
            -- メッセージ出力
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg --ユーザー・エラーメッセージ
            );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
             ,buff   => lv_errbuf --エラーメッセージ
            );
            -- エラー件数カウントアップ
            gn_error_cnt := gn_error_cnt + 1;
        END;
        --
      END IF;
      --
    END LOOP ins_wk_loop;
    --
    -- 処理対象件数を格納(ヘッダ件数を除く)
    gn_target_cnt := l_if_data_tab.COUNT - 1 ;
    --
  EXCEPTION
    -- *** データ項目数エラー例外ハンドラ ***
    WHEN get_if_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00028            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => cv_cust_upload                -- トークン値1
                    ,iv_token_name2  => cv_tkn_count                  -- トークンコード2
                    ,iv_token_value2 => ln_item_num                   -- トークン値2
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_if_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : 終了処理 (A-6)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- プログラム名
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    lv_check_status           VARCHAR2(1);                            -- チェックステータス
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
--
    -- チェックステータスの初期化
    lv_check_status := cv_status_normal;
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    --==============================================================
    -- A-6.1 顧客一括登録データ削除
    --==============================================================
    BEGIN
      lv_step := 'A-6.1';
      DELETE FROM xxcmm_wk_cust_upload
      ;
      -- COMMIT発行
      COMMIT;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- データ削除エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00012          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table                -- トークンコード1
                      ,iv_token_value1 => cv_table_xwcu               -- トークン値1
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END;
    --
    --==============================================================
    -- A-6.2 ファイルアップロードIFテーブルデータ削除
    --==============================================================
    BEGIN
      lv_step := 'A-6.2';
      DELETE FROM xxccp_mrp_file_ul_interface
      WHERE  file_id = gn_file_id
      ;
      -- COMMIT発行
      COMMIT;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- データ削除エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00012          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table                -- トークンコード1
                      ,iv_token_value1 => cv_table_file_ul_if         -- トークン値1
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2          -- ファイルID
   ,iv_format     IN  VARCHAR2          -- フォーマット
   ,ov_errbuf     OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    --
    ln_loop_cnt               NUMBER;                                 -- ループカウンター
    --
    ln_target_cnt             NUMBER;                                 -- 対象件数
    ln_insert_cnt             NUMBER;                                 -- INSERT件数
    ln_update_cnt             NUMBER;                                 -- UPDATE件数
    ln_warn_cnt               NUMBER;                                 -- スキップ件数
--
    -- *** ローカル・カーソル ***
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- 退避KEY情報レコード
    l_cust_account_rec          hz_cust_account_v2pub.cust_account_rec_type;
    l_organization_rec          hz_party_v2pub.organization_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_cmm_cust_acct_rec         xxcmm_cust_accounts%ROWTYPE;                             -- 顧客追加情報レコード
    l_location_rec              hz_location_v2pub.location_rec_type;
    l_cust_site_use_rec         hz_cust_account_site_v2pub.cust_site_use_rec_type;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    sub_proc_expt             EXCEPTION;                              -- サブプログラムエラー
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
    gn_insert_cnt := 0;
    gn_update_cnt := 0;
    --
    gn_normal_cnt := 0;
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
    --
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --==============================================================
    -- A-1.  初期処理
    --==============================================================
    lv_step := 'A-1';
    init(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      gn_error_cnt := 1;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-2.  ファイルアップロードIFデータ取得
    --==============================================================
    lv_step := 'A-2';
    get_if_data(                        -- get_if_dataをコール
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      gn_error_cnt := 1;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    -- A-3  顧客一括登録ワークデータ取得
    --  A-4  顧客一括登録ワークテーブルデータ妥当性チェック
    --  A-5  顧客一括登録処理
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-6  終了処理
    --==============================================================
    lv_step := 'A-6';
    proc_comp(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      RAISE sub_proc_expt;
    END IF;
    --
    -- エラーがあればリターン・コードをエラー、正常件数＝0件で返します
    IF ( gn_error_cnt > 0 ) THEN
      gn_normal_cnt := 0;
      ov_retcode    := cv_status_error;
    END IF;
    --
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT    VARCHAR2       --   エラー・メッセージ  --# 固定 #
   ,retcode       OUT    VARCHAR2       --   エラーコード        --# 固定 #
   ,iv_file_id    IN     VARCHAR2       --   ファイルID
   ,iv_format     IN     VARCHAR2       --   フォーマット
  )
  IS
--
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_target_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    --
    cv_cnt_token               CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);     -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code            VARCHAR2(100);   -- 終了メッセージコード
    --
    lv_submain_retcode         VARCHAR2(1);     -- リターン・コード
  BEGIN
--
--###########################  固定部 END   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_log
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- メッセージ(OUTPUT)出力
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- submainのリターンコードを退避
    lv_submain_retcode := lv_retcode;
    --
    --エラー出力
    IF ( lv_submain_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
    --Submainのリターンコードが正常であれば顧客登録結果を出力
    IF ( lv_submain_retcode = cv_status_normal ) THEN
        disp_report(
          lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,lv_retcode  -- リターン・コード             --# 固定 #
         ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_submain_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_submain_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_submain_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --ステータスセット
    retcode := lv_submain_retcode;
    --終了ステータスが正常以外の場合はROLLBACK
    IF ( retcode <> cv_status_normal ) THEN
      ROLLBACK;
    ELSE
      -- COMMIT発行
      COMMIT;
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
END XXCMM003A40C;
/
