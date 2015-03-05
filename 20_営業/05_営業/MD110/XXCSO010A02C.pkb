CREATE OR REPLACE PACKAGE BODY APPS.XXCSO010A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO010A02C(body)
 * Description      : 自動販売機設置契約情報登録/更新画面によって登録・更新された自動販売
 *                    機設置契約書情報を顧客マスタに更新します。またBM仕入先情報を仕入先マ
 *                    スタ、銀行口座マスタ、販手条件マスタに登録・更新します。またオーナー
 *                    変更が指示されていた場合、物件情報をインストールベースマスタに更新し
 *                    ます。
 * MD.050           : MD050_CSO_010_A02_マスタ連携機能
 *
 * Version          : 1.19
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  start_proc             初期処理(A-1)
 *  upd_cont_manage_bef    契約管理情報更新処理(A-2)
 *  reg_vendor_if          ベンダー中間I/Fテーブル登録処理(A-5)
 *  reg_vendor             仕入先情報登録/更新処理(A-6)
 *  confirm_reg_vendor     仕入先情報登録/更新完了確認処理(A-7)
 *  error_reg_vendor       仕入先情報登録/更新エラー時処理(A-8)
 *  associate_vendor_id    仕入先ID関連付け処理(A-9)
 *  reg_backmargin         販売手数料情報登録/更新処理(A-10)
 *  upd_install_at         設置先顧客情報更新処理(A-11)
 *  upd_install_base       物件情報更新処理(A-12)
 *  upd_cont_manage_aft    契約情報更新処理(A-13)
 *  submain                メイン処理プロシージャ
 *                           契約管理情報取得処理(A-3)
 *                           仕入先情報取得処理(A-4)
 *  main                   実行ファイル登録プロシージャ
 *                           終了処理(A-14)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-07    1.0   Kazuo.Satomura   新規作成
 *  2009-02-13          Kazuo.Satomura   ・仕入先変更時、変更前の口座情報が存在しない場合
 *                                         エラーとならないよう修正
 *                                       ・A-8のカーソルの条件に要求ＩＤを追加
 *                                       ・電話番号の市外局番にハイフンを追加
 *  2009-02-19          Kazuo.Satomura   結合障害対応(不具合ID17)
 *                                       ・物件コードが未入力の場合、A-12の処理を行わない
 *                                         よう修正
 *  2009-02-20          Kazuo.Satomura   結合障害対応(不具合ID18,19,20)
 *                                       ・値引額がなしでも取引条件が1,2の場合は、販手条
 *                                         件マスタを登録更新対象とするよう修正
 *                                       ・パーティマスタを更新するよう修正
 *                                       ・ベンダー中間I/Fの予備カテゴリに組織ＩＤを設定
 *  2009-02-23          Kazuo.Satomura   結合障害対応(不具合ID24)
 *                                       ・取引条件区分が5の場合、販手条件の登録更新を行
 *                                         わないよう修正
 *  2009-02-24          Kazuo.Satomura   結合障害対応(不具合ID26)
 *                                       ・口座割当マスタ廃止用中間テーブル登録条件に、口
 *                                         座番号が変わった場合を追加
 *  2009-03-06          Kazuo.Satomura   内部課題対応
 *                                       ・物件マスタ更新項目に、パーティサイトＩＤを追加
 *                                       ・販手条件廃止条件を業務処理日を含むように修正
 *                                       ・不具合ID24の修正を取消
 *                                         (取引条件区分が5のケースが無くなった為)
 *                                       ・販手条件の作成更新条件変更
 *                                         (ＢＭ１～３の入力が無い、又は0の場合は処理を行
 *                                         わない)
 *  2009-03-24    1.1   Kazuo.Satomura   システムテスト障害(障害番号T1_0135,0136,0140)
 *  2009-04-02    1.2   Kazuo.Satomura   システムテスト障害(障害番号T1_0227)
 *  2009-04-08    1.3   Kazuo.Satomura   システムテスト障害(障害番号T1_0287)
 *  2009-04-08    1.4   Kazuo.Satomura   システムテスト障害(障害番号T1_0617)
 *  2009-04-27    1.5   Kazuo.Satomura   システムテスト障害(障害番号T1_0766)
 *  2009-04-28    1.6   Kazuo.Satomura   システムテスト障害(障害番号T1_0733)
 *  2009-05-01    1.7   Tomoko.Mori      T1_0897対応
 *  2009-05-15    1.8   Kazuo.Satomura   システムテスト障害(障害番号T1_1010)
 *  2009-09-25    1.9   Daisuke.Abe      共通課題IE548
 *  2009-10-15    1.10  Daisuke.Abe      0001537対応
 *  2009-11-26    1.11  Kazuo.Satomura   E_本稼動_00109対応
 *  2009-12-18    1.12  Daisuke.Abe      E_本稼動_00536対応
 *  2010-01-06    1.13  Kazuyo.Hosoi     E_本稼動_00890,00891対応
 *  2010-01-20    1.14  Daisuke.Abe      E_本稼動_01176対応
 *  2010-02-05    1.15  Daisuke.Abe      E_本稼動_01537対応
 *  2010-03-04    1.16  Kazuyo.Hosoi     E_本稼動_01678対応
 *  2011-12-26    1.17  T.Ishiwata       E_本稼動_08363対応
 *  2013-04-11    1.18  K.Nakamura       E_本稼動_09603対応
 *  2015-02-25    1.19  H.Wajima         E_本稼働_12565対応
 *
 *****************************************************************************************/
  --
  --#######################  固定グローバル定数宣言部 START   #######################
  --
  -- ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
  --
  --################################  固定部 END   ##################################
  --
  --#######################  固定グローバル変数宣言部 START   #######################
  --
  gv_out_msg           VARCHAR2(2000);
  gv_sep_msg           VARCHAR2(2000);
  gv_exec_user         VARCHAR2(100);
  gv_conc_name         VARCHAR2(30);
  gv_conc_status       VARCHAR2(30);
  gn_vendor_target_cnt NUMBER; -- 対象件数(仕入先取込)
  gn_mst_target_cnt    NUMBER; -- 対象件数(マスタ連携)
  gn_vendor_normal_cnt NUMBER; -- 正常件数(仕入先取込)
  gn_mst_normal_cnt    NUMBER; -- 正常件数(マスタ連携)
  gn_vendor_error_cnt  NUMBER; -- エラー件数(仕入先取込)
  gn_mst_error_cnt     NUMBER; -- エラー件数(マスタ連携)
  gn_vendor_warn_cnt   NUMBER; -- スキップ件数(仕入先取込)
  gn_mst_warn_cnt      NUMBER; -- スキップ件数(マスタ連携)
  --
  --################################  固定部 END   ##################################
  --
  --##########################  固定共通例外宣言部 START  ###########################
  --
  --*** 処理部共通例外 ***
  global_process_expt EXCEPTION;
  --
  --*** 共通関数例外 ***
  global_api_expt EXCEPTION;
  --
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO010A02C';                                    -- パッケージ名
  cv_sales_appl_short_name  CONSTANT VARCHAR2(5)   := 'XXCSO';                                           -- 営業用アプリケーション短縮名
  cn_number_zero            CONSTANT NUMBER        := 0;
  cn_number_one             CONSTANT NUMBER        := 1;
  cv_create_flag            CONSTANT VARCHAR2(1)   := 'I';
  cv_update_flag            CONSTANT VARCHAR2(1)   := 'U';
  cv_flag_yes               CONSTANT VARCHAR2(1)   := 'Y';                                               -- フラグY
  cv_flag_no                CONSTANT VARCHAR2(1)   := 'N';                                               -- フラグN
  cv_flag_off               CONSTANT VARCHAR2(1)   := '0';                                               -- フラグOFF
  cv_flag_on                CONSTANT VARCHAR2(1)   := '1';                                               -- フラグON
  cv_date_format1           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';                           -- 日付フォーマット
  cv_date_format2           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD';                                      -- 日付フォーマット
  cv_year_format            CONSTANT VARCHAR2(21)  := 'YYYY';                                            -- 日付フォーマット（年）
  cv_month_format           CONSTANT VARCHAR2(21)  := 'MM';                                              -- 日付フォーマット（月）
  cv_day_format             CONSTANT VARCHAR2(21)  := 'DD';                                              -- 日付フォーマット（日）
  cd_sysdate                CONSTANT DATE          := SYSDATE;                                           -- システム日付
  cd_process_date           CONSTANT DATE          := xxccp_common_pkg2.get_process_date;                -- 業務処理日付
  cv_lang                   CONSTANT VARCHAR2(2)   := USERENV('LANG');                                   -- 言語
  cn_org_id                 CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ログイン組織ＩＤ
  cv_batch_proc_status_norm CONSTANT xxcso_contract_managements.batch_proc_status%TYPE := '0';           -- バッチ処理ステータス＝正常
  cv_batch_proc_status_coa  CONSTANT xxcso_contract_managements.batch_proc_status%TYPE := '1';           -- バッチ処理ステータス＝連携中
  cv_batch_proc_status_err  CONSTANT xxcso_contract_managements.batch_proc_status%TYPE := '2';           -- バッチ処理ステータス＝エラー
  cv_status                 CONSTANT VARCHAR2(1)   := '1';                                               -- ステータス＝確定済
  cv_un_cooperate           CONSTANT VARCHAR2(1)   := '0';                                               -- マスタ連携フラグ＝未連携
  cv_finish_cooperate       CONSTANT VARCHAR2(1)   := '1';                                               -- マスタ連携フラグ＝連携済
  ct_bm_payment_type_no     CONSTANT xxcso_sp_decision_custs.bm_payment_type%TYPE := '5';                -- 支払なし
  /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
  ct_bllng_dtls_dv_cash     CONSTANT xxcso_destinations.belling_details_div%TYPE := '4';                 -- 現金支払
  ct_dmmy_bnk_act           CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'XXCSO1_DUMMY_BANK_ACCOUNT'; -- ＢＭ現金支払ダミー口座参照コードタイプ
  ct_dmmy_act               CONSTANT fnd_lookup_values_vl.lookup_code%TYPE := 'DUMMY_ACCOUNT';             -- ＢＭ現金支払ダミー口座クイックコード
  /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
  ct_sp_dec_cust_class_bm1  CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '3';     -- ＳＰ専決顧客ＢＭ１
  ct_sp_dec_cust_class_bm2  CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '4';     -- ＳＰ専決顧客ＢＭ２
  ct_sp_dec_cust_class_bm3  CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '5';     -- ＳＰ専決顧客ＢＭ３
  ct_delivery_div_bm1       CONSTANT xxcso_destinations.delivery_div%TYPE                    := '1';     -- 送付先ＢＭ１
  ct_delivery_div_bm2       CONSTANT xxcso_destinations.delivery_div%TYPE                    := '2';     -- 送付先ＢＭ２
  ct_delivery_div_bm3       CONSTANT xxcso_destinations.delivery_div%TYPE                    := '3';     -- 送付先ＢＭ３
  /* 2013.04.11 K.Nakamura E_本稼動_09603 START */
  cv_duns_number_approved   CONSTANT hz_parties.duns_number_c%TYPE                           := '25';    -- 顧客ステータス：25(SP承認済)
  /* 2013.04.11 K.Nakamura E_本稼動_09603 END */
  --
  -- メッセージコード
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011'; -- 業務処理日付取得エラー
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00337'; -- データ更新エラー
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00500'; -- ＳＰ専決顧客存在エラー
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173'; -- 参照タイプなしエラーメッセージ
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00329'; -- データ取得エラー
  cv_tkn_number_06 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00330'; -- データ登録エラー
  cv_tkn_number_07 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00383'; -- シーケンス取得エラー
  cv_tkn_number_08 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00456'; -- コンカレント起動エラー
  cv_tkn_number_09 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00457'; -- コンカレント終了確認エラー
  cv_tkn_number_10 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00458'; -- コンカレント異常終了エラー
  /* 2013.04.11 K.Nakamura E_本稼動_09603 START */
  -- cv_tkn_number_11 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00459'; -- コンカレント警告終了エラー
  /* 2013.04.11 K.Nakamura E_本稼動_09603 END */
  cv_tkn_number_12 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00389'; -- 顧客マスタ更新時エラー
  cv_tkn_number_13 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00343'; -- 取引タイプID抽出エラーメッセージ
  cv_tkn_number_14 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00504'; -- 物件マスタ更新時エラー
  cv_tkn_number_15 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00505'; -- 対象件数メッセージ
  cv_tkn_number_16 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00506'; -- 成功件数メッセージ
  cv_tkn_number_17 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00507'; -- エラー件数メッセージ
  cv_tkn_number_18 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了メッセージ
  /* 2015.02.25 H.Wajima E_本稼動_12565 START */
  cv_tkn_number_19 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00722'; -- 消費税率取得エラーメッセージ
  /* 2015.02.25 H.Wajima E_本稼動_12565 END */
  --
  -- トークンコード
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_action           CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_error_message    CONSTANT VARCHAR2(20) := 'ERROR_MESSAGE';
  cv_tkn_cont_manage_id   CONSTANT VARCHAR2(20) := 'CONT_MANAGE_ID';
  cv_tkn_sp_dec_head_id   CONSTANT VARCHAR2(20) := 'SP_DEC_HEAD_ID';
  cv_tkn_task_name        CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_key_name         CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_id           CONSTANT VARCHAR2(20) := 'KEY_ID';
  cv_tkn_api_name         CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_api_msg          CONSTANT VARCHAR2(20) := 'API_MSG';
  cv_tkn_proc_name        CONSTANT VARCHAR2(20) := 'PROC_NAME';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_sequence         CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_src_tran_type    CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';
  --
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1  CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg2  CONSTANT VARCHAR2(200) := 'cd_process_date = ';
  cv_debug_msg3  CONSTANT VARCHAR2(200) := '<< 契約管理情報 >>';
  cv_debug_msg4  CONSTANT VARCHAR2(200) := 'contract_management_id = ';
  cv_debug_msg5  CONSTANT VARCHAR2(200) := 'sp_decision_header_id  = ';
  cv_debug_msg6  CONSTANT VARCHAR2(200) := 'install_account_id     = ';
  cv_debug_msg7  CONSTANT VARCHAR2(200) := 'install_account_number = ';
  cv_debug_msg8  CONSTANT VARCHAR2(200) := 'install_party_name     = ';
  cv_debug_msg9  CONSTANT VARCHAR2(200) := 'install_postal_code    = ';
  cv_debug_msg10 CONSTANT VARCHAR2(200) := 'install_state          = ';
  cv_debug_msg11 CONSTANT VARCHAR2(200) := 'install_city           = ';
  cv_debug_msg12 CONSTANT VARCHAR2(200) := 'install_address1       = ';
  cv_debug_msg13 CONSTANT VARCHAR2(200) := 'install_address2       = ';
  cv_debug_msg14 CONSTANT VARCHAR2(200) := '<< 仕入先情報 >>';
  cv_debug_msg15 CONSTANT VARCHAR2(200) := 'supplier_id                  = ';
  cv_debug_msg16 CONSTANT VARCHAR2(200) := 'delivery_div                 = ';
  cv_debug_msg17 CONSTANT VARCHAR2(200) := 'payment_name                 = ';
  cv_debug_msg18 CONSTANT VARCHAR2(200) := 'payment_name_alt             = ';
  cv_debug_msg19 CONSTANT VARCHAR2(200) := 'bank_transfer_fee_charge_div = ';
  cv_debug_msg20 CONSTANT VARCHAR2(200) := 'belling_details_div          = ';
  cv_debug_msg21 CONSTANT VARCHAR2(200) := 'inquery_charge_hub_cd        = ';
  cv_debug_msg22 CONSTANT VARCHAR2(200) := 'post_code                    = ';
  cv_debug_msg23 CONSTANT VARCHAR2(200) := 'prefectures                  = ';
  cv_debug_msg24 CONSTANT VARCHAR2(200) := 'city_ward                    = ';
  cv_debug_msg25 CONSTANT VARCHAR2(200) := 'address_1                    = ';
  cv_debug_msg26 CONSTANT VARCHAR2(200) := 'address_2                    = ';
  cv_debug_msg27 CONSTANT VARCHAR2(200) := 'address_lines_phonetic       = ';
  cv_debug_msg28 CONSTANT VARCHAR2(200) := 'bank_number                  = ';
  cv_debug_msg29 CONSTANT VARCHAR2(200) := 'bank_name                    = ';
  cv_debug_msg30 CONSTANT VARCHAR2(200) := 'branch_number                = ';
  cv_debug_msg31 CONSTANT VARCHAR2(200) := 'branch_name                  = ';
  cv_debug_msg32 CONSTANT VARCHAR2(200) := 'bank_account_type            = ';
  cv_debug_msg33 CONSTANT VARCHAR2(200) := 'bank_account_number          = ';
  cv_debug_msg34 CONSTANT VARCHAR2(200) := 'bank_account_name_kana       = ';
  cv_debug_msg35 CONSTANT VARCHAR2(200) := 'bank_account_name_kanji      = ';
  cv_debug_msg36 CONSTANT VARCHAR2(200) := '<< ＳＰ専決顧客情報 >>';
  cv_debug_msg37 CONSTANT VARCHAR2(200) := 'customer_id     = ';
  cv_debug_msg38 CONSTANT VARCHAR2(200) := 'bm_payment_type = ';
  cv_debug_msg39 CONSTANT VARCHAR2(200) := '<< 預金種目名 >>';
  cv_debug_msg40 CONSTANT VARCHAR2(200) := 'bank_account_type_name = ';
  cv_debug_msg41 CONSTANT VARCHAR2(200) := '<< 仕入先情報 >>';
  cv_debug_msg42 CONSTANT VARCHAR2(200) := 'vendor_number  = ';
  cv_debug_msg43 CONSTANT VARCHAR2(200) := 'vendor_site_id = ';
  cv_debug_msg44 CONSTANT VARCHAR2(200) := '<< 更新前口座情報 >>';
  cv_debug_msg45 CONSTANT VARCHAR2(200) := 'bank_number = ';
  cv_debug_msg46 CONSTANT VARCHAR2(200) := 'bank_num    = ';
  /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
  --cv_debug_msg47 CONSTANT VARCHAR2(200) := '<< ダミー口座情報 >>';
  cv_debug_msg47 CONSTANT VARCHAR2(200) := '<< ダミー口座キー情報 >>';
  /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
  cv_debug_msg48 CONSTANT VARCHAR2(200) := 'bank_number = ';
  cv_debug_msg49 CONSTANT VARCHAR2(200) := 'bank_num    = ';
  cv_debug_msg50 CONSTANT VARCHAR2(200) := '<< 採番仕入先番号 >>';
  cv_debug_msg51 CONSTANT VARCHAR2(200) := 'vendor_number = ';
  cv_debug_msg52 CONSTANT VARCHAR2(200) := '<< 要求ＩＤ >>';
  cv_debug_msg53 CONSTANT VARCHAR2(200) := 'request_id = ';
  cv_debug_msg54 CONSTANT VARCHAR2(200) := '<< 仕入先登録エラー情報 >>';
  cv_debug_msg55 CONSTANT VARCHAR2(200) := 'vendor_name            = ';
  cv_debug_msg56 CONSTANT VARCHAR2(200) := 'error_reason           = ';
  cv_debug_msg57 CONSTANT VARCHAR2(200) := '<< 仕入先ＩＤ >>';
  cv_debug_msg58 CONSTANT VARCHAR2(200) := 'vendor_id = ';
  cv_debug_msg59 CONSTANT VARCHAR2(200) := '<< ＳＰ専決顧客ＩＤ >>';
  cv_debug_msg60 CONSTANT VARCHAR2(200) := 'customer_id = ';
  cv_debug_msg61 CONSTANT VARCHAR2(200) := ' << ＳＰ専決情報 >> ';
  cv_debug_msg62 CONSTANT VARCHAR2(200) := 'condition_business_type = ';
  cv_debug_msg63 CONSTANT VARCHAR2(200) := 'electricity_type        = ';
  cv_debug_msg64 CONSTANT VARCHAR2(200) := 'electricity_amount      = ';
  cv_debug_msg65 CONSTANT VARCHAR2(200) := 'sp_container_type       = ';
  cv_debug_msg66 CONSTANT VARCHAR2(200) := 'sales_price             = ';
  cv_debug_msg67 CONSTANT VARCHAR2(200) := 'bm1_bm_rate             = ';
  cv_debug_msg68 CONSTANT VARCHAR2(200) := 'bm1_bm_amount           = ';
  cv_debug_msg69 CONSTANT VARCHAR2(200) := 'bm2_bm_rate             = ';
  cv_debug_msg70 CONSTANT VARCHAR2(200) := 'bm2_bm_amount           = ';
  cv_debug_msg71 CONSTANT VARCHAR2(200) := 'bm3_bm_rate             = ';
  cv_debug_msg72 CONSTANT VARCHAR2(200) := 'bm3_bm_amount           = ';
  cv_debug_msg73 CONSTANT VARCHAR2(200) := 'bm_container_type       = ';
  cv_debug_msg74 CONSTANT VARCHAR2(200) := 'contract_number        = ';
  cv_debug_msg75 CONSTANT VARCHAR2(200) := 'discount_amt            = ';
  cv_debug_msg76 CONSTANT VARCHAR2(200) := ' << 仕入先登録処理開始（ＢＦＡ起動） >> ';
  cv_debug_msg77 CONSTANT VARCHAR2(200) := ' << 仕入先登録処理終了 >> ';
  cv_debug_msg78 CONSTANT VARCHAR2(200) := ' << 仕入先登録処理完了確認処理開始 >> ';
  cv_debug_msg79 CONSTANT VARCHAR2(200) := ' << 仕入先登録処理完了確認処理終了 >> ';
  /* 2009.10.15 D.Abe 0001537対応 START */
  cv_debug_msg80 CONSTANT VARCHAR2(200) := 'delivery_id             = ';
  /* 2009.10.15 D.Abe 0001537対応 END */
  /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
  cv_debug_msg81 CONSTANT VARCHAR2(200) := 'bank_account_num = ';
  cv_debug_msg82 CONSTANT VARCHAR2(200) := '<< ダミー口座情報 >>';
  cv_debug_msg83 CONSTANT VARCHAR2(200) := 'bank_account_name = ';
  cv_debug_msg84 CONSTANT VARCHAR2(200) := 'bank_account_type = ';
  cv_debug_msg85 CONSTANT VARCHAR2(200) := 'account_holder_name = ';
  cv_debug_msg86 CONSTANT VARCHAR2(200) := 'account_holder_name_alt = ';
  /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
  /* 2015.02.25 H.Wajima E_本稼動_12565 START */
  cv_debug_msg87 CONSTANT VARCHAR2(200) := 'electric_payment_type   = ';
  cv_debug_msg88 CONSTANT VARCHAR2(200) := 'tax_type                = ';
  /* 2015.02.25 H.Wajima E_本稼動_12565 END */
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
  gt_bank_number             ap_bank_branches.bank_number%TYPE;                    -- 銀行コード
  gt_bank_num                ap_bank_branches.bank_num%TYPE;                       -- 支店コード
  gt_bank_account_num        ap_bank_accounts.bank_account_num%TYPE;               -- 口座番号
  gt_bank_account_name       ap_bank_accounts.bank_account_name%TYPE;              -- 口座名称
  gt_bank_account_type       ap_bank_accounts.bank_account_type%TYPE;              -- 預金種目
  gt_account_holder_name     ap_bank_accounts.account_holder_name%TYPE;            -- 口座名義人
  gt_account_holder_name_alt ap_bank_accounts.account_holder_name_alt%TYPE;        -- 口座名義人（カナ）
  /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
  /* 2015.02.25 H.Wajima E_本稼動_12565 START */
  gt_tax_rate                xxcso_qt_ap_tax_rate_v.ap_tax_rate%TYPE;              -- 消費税率
  /* 2015.02.25 H.Wajima E_本稼動_12565 END */
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 契約管理情報構造体
  TYPE g_mst_regist_info_rtype IS RECORD(
    -- 契約管理情報
     contract_management_id xxcso_contract_managements.contract_management_id%TYPE -- 自動販売機設置契約書ＩＤ
    ,contract_number        xxcso_contract_managements.contract_number%TYPE        -- 契約書番号
    ,sp_decision_header_id  xxcso_contract_managements.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
    ,install_account_id     xxcso_contract_managements.install_account_id%TYPE     -- 設置先顧客ＩＤ
    ,install_account_number xxcso_contract_managements.install_account_number%TYPE -- 設置先顧客コード
    ,install_party_name     xxcso_contract_managements.install_party_name%TYPE     -- 設置先顧客名
    ,install_postal_code    xxcso_contract_managements.install_postal_code%TYPE    -- 設置先郵便番号
    ,install_state          xxcso_contract_managements.install_state%TYPE          -- 設置先都道府県
    ,install_city           xxcso_contract_managements.install_city%TYPE           -- 設置先市区
    ,install_address1       xxcso_contract_managements.install_address1%TYPE       -- 設置先住所１
    ,install_address2       xxcso_contract_managements.install_address2%TYPE       -- 設置先住所２
    ,install_date           xxcso_contract_managements.install_date%TYPE           -- 設置日
    ,install_code           xxcso_contract_managements.install_code%TYPE           -- 物件コード
    -- 送付先情報
    ,supplier_id                  xxcso_destinations.supplier_id%TYPE                  -- 仕入先ＩＤ
    ,delivery_div                 xxcso_destinations.delivery_div%TYPE                 -- 送付先区分
    ,payment_name                 xxcso_destinations.payment_name%TYPE                 -- 支払先名
    ,payment_name_alt             xxcso_destinations.payment_name_alt%TYPE             -- 支払先名カナ
    ,bank_transfer_fee_charge_div xxcso_destinations.bank_transfer_fee_charge_div%TYPE -- 振込手数料負担区分
    ,belling_details_div          xxcso_destinations.belling_details_div%TYPE          -- 支払明細書区分
    ,inquery_charge_hub_cd        xxcso_destinations.inquery_charge_hub_cd%TYPE        -- 問合せ担当拠点コード
    ,post_code                    xxcso_destinations.post_code%TYPE                    -- 郵便番号
    ,prefectures                  xxcso_destinations.prefectures%TYPE                  -- 都道府県
    ,city_ward                    xxcso_destinations.city_ward%TYPE                    -- 市区
    ,address_1                    xxcso_destinations.address_1%TYPE                    -- 住所１
    ,address_2                    xxcso_destinations.address_2%TYPE                    -- 住所２
    ,address_lines_phonetic       xxcso_destinations.address_lines_phonetic%TYPE       -- 電話番号
    /* 2009.10.15 D.Abe 0001537対応 START */
    ,delivery_id                  xxcso_destinations.delivery_id%TYPE                  -- 送付先ID
    /* 2009.10.15 D.Abe 0001537対応 END */
    -- 銀行口座情報
    ,bank_number             xxcso_bank_accounts.bank_number%TYPE             -- 銀行番号
    ,bank_name               xxcso_bank_accounts.bank_name%TYPE               -- 銀行名
    ,branch_number           xxcso_bank_accounts.branch_number%TYPE           -- 支店番号
    ,branch_name             xxcso_bank_accounts.branch_name%TYPE             -- 支店名
    ,bank_account_type       xxcso_bank_accounts.bank_account_type%TYPE       -- 口座種別
    ,bank_account_number     xxcso_bank_accounts.bank_account_number%TYPE     -- 口座番号
    ,bank_account_name_kana  xxcso_bank_accounts.bank_account_name_kana%TYPE  -- 口座名義カナ
    ,bank_account_name_kanji xxcso_bank_accounts.bank_account_name_kanji%TYPE -- 口座名義漢字
    ,bank_account_dummy_flag xxcso_bank_accounts.bank_account_dummy_flag%TYPE -- 銀行口座ダミーフラグ
  );
  --
  /**********************************************************************************
   * Procedure Name   : start_proc
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE start_proc(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_proc'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_tkn_value_processdate CONSTANT VARCHAR2(30) := '業務日付';
    /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
    cv_tkn_value_task_name2  CONSTANT VARCHAR2(50) := 'ＢＭ現金支払ダミー口座が';
    cv_tkn_value_act_dmy_bk  CONSTANT VARCHAR2(50) := 'ダミー口座情報';
    cv_tkn_val_ky_nm_bk_num1 CONSTANT VARCHAR2(50) := '銀行コード = ';
    cv_tkn_val_ky_nm_bk_num2 CONSTANT VARCHAR2(50) := '、支店コード';
    cv_tkn_val_ky_nm_bk_num3 CONSTANT VARCHAR2(50) := '、口座番号';
    /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
    --
    -- *** ローカル変数 ***
    lv_msg_from VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ======================
    -- 業務日付チェック
    -- ======================
    IF (cd_process_date IS NULL) THEN
      -- 業務日付が未入力の場合エラー
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item              -- トークコード1
                     ,iv_token_value1 => cv_tkn_value_processdate -- トークン値1
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG START ***
    -- 業務日付をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || TO_CHAR(cd_process_date, 'YYYY/MM/DD') || CHR(10) || ''
    );
    -- *** DEBUG_LOG END ***
    /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
    -- ======================
    -- ダミー口座情報取得
    -- ======================
    BEGIN
      SELECT  flv.attribute1 bank_number         -- 銀行コード
             ,flv.attribute2 bank_num            -- 支店コード
             ,flv.attribute3 bank_account_num    -- 口座番号
      INTO    gt_bank_number
             ,gt_bank_num
             ,gt_bank_account_num
      FROM   fnd_lookup_values_vl flv -- 参照コード
      WHERE  flv.lookup_type                            =  ct_dmmy_bnk_act
      AND    flv.lookup_code                            =  ct_dmmy_act
      AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
      AND    flv.enabled_flag                           =  cv_flag_yes
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_name         -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_task_name2  -- トークン値1
                       ,iv_token_name2  => cv_tkn_lookup_type_name  -- トークンコード2
                       ,iv_token_value2 => ct_dmmy_bnk_act          -- トークン値2
                     );
        --
        RAISE global_api_expt;
        --
    END;
    -- *** DEBUG_LOG START ***
    -- ダミー口座キー情報をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg47 || CHR(10) ||
                 cv_debug_msg48 || gt_bank_number      || CHR(10) ||
                 cv_debug_msg49 || gt_bank_num         || CHR(10) ||
                 cv_debug_msg81 || gt_bank_account_num || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    -- ================================
    -- ダミー口座情報取得
    -- ================================
    BEGIN
      SELECT bac.bank_account_name                bank_account_name       -- 口座名称
            ,bac.bank_account_type                bank_account_type       -- 預金種目
            ,bac.account_holder_name              account_holder_name     -- 口座名義人
            ,bac.account_holder_name_alt          account_holder_name_alt -- 口座名義人（カナ）
      INTO   gt_bank_account_name
            ,gt_bank_account_type
            ,gt_account_holder_name
            ,gt_account_holder_name_alt
      FROM   ap_bank_branches     bbr -- 銀行マスタ
            ,ap_bank_accounts     bac -- 口座マスタビュー
      WHERE  bbr.bank_number          = gt_bank_number
      AND    bbr.bank_num             = gt_bank_num
      AND    bac.bank_branch_id       = bbr.bank_branch_id
      AND    bac.bank_account_num     = gt_bank_account_num
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                      -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_act_dmy_bk            -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                    -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_ky_nm_bk_num1     || gt_bank_number
                                            || cv_tkn_val_ky_nm_bk_num2 || gt_bank_num
                                            || cv_tkn_val_ky_nm_bk_num3       -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                      -- トークンコード3
                       ,iv_token_value3 => gt_bank_account_num                -- トークン値3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    -- *** DEBUG_LOG START ***
    -- ダミー口座情報をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg82 || CHR(10) ||
                 cv_debug_msg83 || gt_bank_account_name       || CHR(10) ||
                 cv_debug_msg84 || gt_bank_account_type       || CHR(10) ||
                 cv_debug_msg85 || gt_account_holder_name     || CHR(10) ||
                 cv_debug_msg86 || gt_account_holder_name_alt || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
    --
    /* 2015.02.25 H.Wajima E_本稼動_12565 START */
    -- ================================
    -- 消費税率取得
    -- ================================
    BEGIN
      SELECT  xqatrv.ap_tax_rate tax_rate
      INTO    gt_tax_rate
      FROM    xxcso_qt_ap_tax_rate_v xqatrv
      WHERE   xqatrv.start_date  <= cd_process_date
      AND     NVL( xqatrv.end_date, cd_process_date ) >= cd_process_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                  iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_19         -- メッセージコード
               );
        --
        RAISE global_api_expt;
    END;
    /* 2015.02.25 H.Wajima E_本稼動_12565 END */
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END start_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_cont_manage_bef
   * Description      : 契約管理情報更新処理(A-2)
   ***********************************************************************************/
  PROCEDURE upd_cont_manage_bef(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_cont_manage_bef'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_value_cont_manage CONSTANT VARCHAR2(50) := '契約管理テーブル';
    --
    -- *** ローカル変数 ***
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ==============================
    -- 契約管理情報更新
    -- ==============================
    -- 処理対象件数カウント
    SELECT COUNT(1) count
    INTO   gn_vendor_target_cnt
    FROM   xxcso_contract_managements xcm
    WHERE  xcm.status         = cv_status
    AND    xcm.cooperate_flag = cv_un_cooperate
    ;
    --
    BEGIN
      UPDATE xxcso_contract_managements xcm -- 契約管理テーブル
      SET    xcm.batch_proc_status = cv_batch_proc_status_coa
      WHERE  xcm.status         = cv_status
      AND    xcm.cooperate_flag = cv_un_cooperate
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_cont_manage -- トークン値1
                       ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END upd_cont_manage_bef;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_vendor_if
   * Description      : ベンダー中間I/Fテーブル登録処理(A-5)
   ***********************************************************************************/
  PROCEDURE reg_vendor_if(
     it_mst_regist_info_rec IN         g_mst_regist_info_rtype -- マスタ登録情報
    ,ov_errbuf              OUT NOCOPY VARCHAR2                -- エラー・メッセージ           --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                -- リターン・コード             --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_vendor_if';  -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    /* 2010.01.20 D.Abe E_本稼動_01176対応 START */
    --cv_bank_account_type     CONSTANT VARCHAR2(30)                          := 'JP_BANK_ACCOUNT_TYPE'; -- 預金種目参照コードタイプ
    cv_bank_account_type     CONSTANT VARCHAR2(30)                          := 'XXCSO1_KOZA_TYPE'; -- 預金種目参照コードタイプ
    /* 2010.01.20 D.Abe E_本稼動_01176対応 END */
    /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
    --ct_dummy_bank            CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'XXCSO1_DUMMY_BANK';    -- ダミー銀行参照コードタイプ
    --ct_dummy_bank_number     CONSTANT fnd_lookup_values_vl.lookup_code%TYPE := 'BANK_NUMBER';          -- ダミー銀行クイックコード
    --ct_dummy_bank_num        CONSTANT fnd_lookup_values_vl.lookup_code%TYPE := 'BANK_NUM';             -- ダミー支店クイックコード
    /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
    cv_vendor_type           CONSTANT VARCHAR2(30)                          := 'VD';                   -- 仕入先タイプ
    cv_country_code          CONSTANT VARCHAR2(30)                          := 'JP';                   -- 国コード
    cv_currency_code         CONSTANT VARCHAR2(3)                           := 'JPY';                  -- 通貨コード
    cv_hyphen                CONSTANT VARCHAR2(1)                           := '-';
    cv_diagonal              CONSTANT VARCHAR2(1)                           := '/';
    cv_status                CONSTANT VARCHAR2(1)                           := '0';
    --
    -- ダミー口座用
    cv_dummy_bank_acct_name       CONSTANT ap_bank_accounts.bank_account_name%TYPE       := 'ダミー銀行/営業ダミー支店/普通'; -- 口座名称
    cv_dummy_bank_acct_num        CONSTANT ap_bank_accounts.bank_account_num%TYPE        := 'D000001';        -- 口座番号
    cv_dummy_bank_acct_type       CONSTANT ap_bank_accounts.bank_account_type%TYPE       := '1';              -- 預金種別
    cv_dummy_acct_holder_name     CONSTANT ap_bank_accounts.account_holder_name%TYPE     := '営業ダミー口座'; -- 口座名義人名 
    cv_dummy_acct_holder_name_alt CONSTANT ap_bank_accounts.account_holder_name_alt%TYPE := 'ｴｲｷﾞﾖｳﾀﾞﾐｰｺｳｻﾞ'; -- 口座名義人名（カナ）
    --
    -- トークン用定数
    cv_tkn_value_task_name1    CONSTANT VARCHAR2(50) := '予期種目名称が';
    /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
    --cv_tkn_value_task_name2    CONSTANT VARCHAR2(50) := 'ダミー銀行コードが';
    --cv_tkn_value_task_name3    CONSTANT VARCHAR2(50) := 'ダミー支店コードが';
    /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
    cv_tkn_value_action_vendor CONSTANT VARCHAR2(50) := '仕入先情報';
    cv_tkn_value_action_bank   CONSTANT VARCHAR2(50) := '口座情報';
    cv_tkn_value_key_name      CONSTANT VARCHAR2(50) := '仕入先ＩＤ';
    cv_tkn_value_table         CONSTANT VARCHAR2(50) := 'ベンダー中間I/Fテーブル';
    cv_tkn_value_sequence      CONSTANT VARCHAR2(40) := '仕入先番号';
    /* 2009.10.15 D.Abe 0001537対応 START */
    cv_tkn_value_destination   CONSTANT VARCHAR2(50) := '送付先テーブル';
    /* 2009.10.15 D.Abe 0001537対応 END */
    --
    -- *** ローカル変数 ***
    lt_customer_id             xxcso_sp_decision_custs.customer_id%TYPE;      -- 顧客ＩＤ
    lt_bm_payment_type         xxcso_sp_decision_custs.bm_payment_type%TYPE;  -- ＢＭ支払区分
    ln_sp_dec_custs_count      NUMBER;                                        -- ＳＰ専決顧客テーブル件数
    lv_bank_account_type_name  fnd_lookup_values_vl.meaning%TYPE;             -- 預金種目名称
    lt_vendor_number           po_vendors.segment1%TYPE;                      -- 仕入先番号
    lt_vendor_site_id          po_vendor_sites.vendor_site_id%TYPE;           -- 仕入先サイトＩＤ
    ln_before_bank_count       NUMBER;                                        -- 変更前口座件数
    lt_bank_number             ap_bank_branches.bank_number%TYPE;             -- 銀行コード
    lt_bank_num                ap_bank_branches.bank_num%TYPE;                -- 支店コード
    lt_bank_account_name       ap_bank_accounts.bank_account_name%TYPE;       -- 口座名称
    lt_bank_account_num        ap_bank_accounts.bank_account_num%TYPE;        -- 口座番号
    lt_bank_account_type       ap_bank_accounts.bank_account_type%TYPE;       -- 預金種目
    lt_account_holder_name     ap_bank_accounts.account_holder_name%TYPE;     -- 口座名義人
    lt_account_holder_name_alt ap_bank_accounts.account_holder_name_alt%TYPE; -- 口座名義人（カナ）
    ld_start_date              ap_bank_account_uses.start_date%TYPE;          -- 有効開始日
    ln_phone_number_length     NUMBER;                                        -- 電話番号バイト数
    lv_area_code               VARCHAR2(100);                                 -- 市外局番
    lv_phone_number            VARCHAR2(100);                                 -- 市内局番
    ln_work_count              NUMBER := cn_number_zero;                      -- ワークカウント
    --
    -- *** ローカル・カーソル ***
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    ln_sp_dec_custs_count := cn_number_zero;
    --
    -- ============================
    -- ＳＰ専決顧客テーブルチェック
    -- ============================
    BEGIN
      SELECT xsd.customer_id     customer_id     -- 顧客ＩＤ
            ,xsd.bm_payment_type bm_payment_type -- ＢＭ支払区分
      INTO   lt_customer_id
            ,lt_bm_payment_type
      FROM   xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
      WHERE  xsd.sp_decision_header_id      = it_mst_regist_info_rec.sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      AND    xsd.sp_decision_customer_class = DECODE(it_mst_regist_info_rec.delivery_div
                                                    ,ct_delivery_div_bm1, ct_sp_dec_cust_class_bm1
                                                    ,ct_delivery_div_bm2, ct_sp_dec_cust_class_bm2
                                                    ,ct_delivery_div_bm3, ct_sp_dec_cust_class_bm3
                                                    ) -- ＳＰ専決顧客区分
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ＳＰ専決顧客が存在しない場合は処理を中断する。
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03                              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_cont_manage_id                         -- トークンコード1
                       ,iv_token_value1 => it_mst_regist_info_rec.contract_management_id -- トークン値1
                       ,iv_token_name2  => cv_tkn_sp_dec_head_id                         -- トークンコード2
                       ,iv_token_value2 => it_mst_regist_info_rec.sp_decision_header_id  -- トークン値2
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- ＳＰ専決顧客情報をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg36 || CHR(10) ||
                 cv_debug_msg37 || lt_customer_id     || CHR(10) ||
                 cv_debug_msg38 || lt_bm_payment_type || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
    IF (lt_bm_payment_type <> ct_bm_payment_type_no) THEN
      -- ＢＭ支払区分が5：支払なしの場合は処理は行わない
      -- ============================
      -- 預金種目名取得
      -- ============================
      IF it_mst_regist_info_rec.bank_account_type IS NOT NULL THEN
        BEGIN
          SELECT flv.meaning bank_account_type_name -- 預金種目名
          INTO   lv_bank_account_type_name
          FROM   fnd_lookup_values_vl flv -- 参照コード
          WHERE  flv.lookup_type                            =  cv_bank_account_type
          AND    flv.lookup_code                            =  it_mst_regist_info_rec.bank_account_type
          AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
          AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
          AND    flv.enabled_flag                           = cv_flag_yes
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_04         -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_name         -- トークンコード1
                           ,iv_token_value1 => cv_tkn_value_task_name1  -- トークン値1
                           ,iv_token_name2  => cv_tkn_lookup_type_name  -- トークンコード2
                           ,iv_token_value2 => cv_bank_account_type     -- トークン値2
                         );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- *** DEBUG_LOG START ***
        -- 預金種目名をログ出力
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg39 || CHR(10) ||
                     cv_debug_msg40 || lv_bank_account_type_name || CHR(10) ||
                     ''
        );
        -- *** DEBUG_LOG END ***
        --
      END IF;
      --
      -- ===================
      -- 電話番号分割処理
      -- ===================
      /* 2009.09.25 D.Abe IE548対応 START */
      ---- 電話番号のバイト数を取得
      --ln_phone_number_length := LENGTHB(it_mst_regist_info_rec.address_lines_phonetic);
      ----
      ---- 最初のハイフンのあるバイト数を取得
      --ln_work_count := INSTRB(it_mst_regist_info_rec.address_lines_phonetic, cv_hyphen, 1);
      ----
      ---- 電話番号を市外局番と市内局番に分割
      --lv_area_code    := SUBSTRB(it_mst_regist_info_rec.address_lines_phonetic, 1, ln_work_count);
      --lv_phone_number := SUBSTRB(it_mst_regist_info_rec.address_lines_phonetic, ln_work_count + 1, ln_phone_number_length);
      lv_phone_number := it_mst_regist_info_rec.address_lines_phonetic;
      /* 2009.09.25 D.Abe IE548対応 END   */
      --
      /* 2009.10.15 D.Abe 0001537対応 START */
      --IF lt_customer_id IS NOT NULL THEN
      --  -- 取得した顧客ＩＤが入力されている場合
      -- 送付先の仕入先が登録されている場合
      IF it_mst_regist_info_rec.supplier_id IS NOT NULL THEN
      /* 2009.10.15 D.Abe 0001537対応 END */
        -- ================================
        -- 仕入先番号・仕入先サイトＩＤ取得
        -- ================================
        BEGIN
          SELECT pve.segment1       vendor_number  -- 仕入先番号
                ,pvs.vendor_site_id vendor_site_id -- 仕入先サイトＩＤ
          INTO   lt_vendor_number
                ,lt_vendor_site_id
          FROM   po_vendors      pve -- 仕入先
                ,po_vendor_sites pvs -- 仕入先サイトビュー
          WHERE  pve.vendor_id = it_mst_regist_info_rec.supplier_id
          AND    pve.vendor_id = pvs.vendor_id
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_05                   -- メッセージコード
                           ,iv_token_name1  => cv_tkn_action                      -- トークンコード1
                           ,iv_token_value1 => cv_tkn_value_action_vendor         -- トークン値1
                           ,iv_token_name2  => cv_tkn_key_name                    -- トークンコード2
                           ,iv_token_value2 => cv_tkn_value_key_name              -- トークン値2
                           ,iv_token_name3  => cv_tkn_key_id                      -- トークンコード3
                           ,iv_token_value3 => it_mst_regist_info_rec.supplier_id -- トークン値3
                         );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- *** DEBUG_LOG START ***
        -- 仕入先情報をログ出力
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg41 || CHR(10) ||
                     cv_debug_msg42 || lt_vendor_number  || CHR(10) ||
                     cv_debug_msg43 || lt_vendor_site_id || CHR(10) ||
                     ''
        );
        -- *** DEBUG_LOG END ***
        --
        -- ================================
        -- 変更前口座情報取得
        -- ================================
        SELECT COUNT(1) count
        INTO   ln_before_bank_count
        FROM   ap_bank_account_uses aba -- 口座割当マスタビュー
        WHERE  aba.vendor_id      = it_mst_regist_info_rec.supplier_id
        AND    aba.vendor_site_id = lt_vendor_site_id
        ;
        --
        IF ln_before_bank_count >= cn_number_one THEN
          -- 変更前の口座が存在する場合
          BEGIN
            SELECT bbr.bank_number                      bank_number             -- 銀行コード
                  ,bbr.bank_num                         bank_num                -- 支店コード
                  ,bac.bank_account_name                bank_account_name       -- 口座名称
                  ,bac.bank_account_num                 bank_account_num        -- 口座番号
                  ,bac.bank_account_type                bank_account_type       -- 預金種目
                  ,bac.account_holder_name              account_holder_name     -- 口座名義人
                  ,bac.account_holder_name_alt          account_holder_name_alt -- 口座名義人（カナ）
                  ,NVL(bau.start_date, cd_process_date) start_date              -- 有効開始日
            INTO   lt_bank_number
                  ,lt_bank_num
                  ,lt_bank_account_name
                  ,lt_bank_account_num
                  ,lt_bank_account_type
                  ,lt_account_holder_name
                  ,lt_account_holder_name_alt
                  ,ld_start_date
            FROM   ap_bank_branches     bbr -- 銀行マスタ
                  ,ap_bank_accounts     bac -- 口座マスタビュー
                  ,ap_bank_account_uses bau -- 口座割当マスタビュー
            WHERE  bau.vendor_id                               =  it_mst_regist_info_rec.supplier_id
            AND    TRUNC(NVL(bau.start_date, cd_process_date)) <= TRUNC(cd_process_date)
            AND    bau.end_date                                IS NULL
            AND    bau.external_bank_account_id                =  bac.bank_account_id
            AND    bac.bank_branch_id                          =  bbr.bank_branch_id
            /* 2009.11.26 K.Satomura E_本稼動_00109対応 START */
            AND    bau.primary_flag                            =  cv_flag_yes
            /* 2009.11.26 K.Satomura E_本稼動_00109対応 END */
            /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 START */
            AND    bau.vendor_site_id                          =  lt_vendor_site_id
            /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 END */
            ;
            --
          EXCEPTION
            WHEN OTHERS THEN
              lv_errbuf := xxccp_common_pkg.get_msg(
                              iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_number_05                   -- メッセージコード
                             ,iv_token_name1  => cv_tkn_action                      -- トークンコード1
                             ,iv_token_value1 => cv_tkn_value_action_bank           -- トークン値1
                             ,iv_token_name2  => cv_tkn_key_name                    -- トークンコード2
                             ,iv_token_value2 => cv_tkn_value_key_name              -- トークン値2
                             ,iv_token_name3  => cv_tkn_key_id                      -- トークンコード3
                             ,iv_token_value3 => it_mst_regist_info_rec.supplier_id -- トークン値3
                           );
              --
              RAISE global_api_expt;
              --
          END;
          --
          -- *** DEBUG_LOG START ***
          -- 更新前口座情報をログ出力
          fnd_file.put_line(
             which  => fnd_file.log
            ,buff   => cv_debug_msg44 || CHR(10) ||
                       cv_debug_msg45 || lt_bank_number || CHR(10) ||
                       cv_debug_msg46 || lt_bank_num    || CHR(10) ||
                       ''
          );
          -- *** DEBUG_LOG END ***
          --
          /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
          IF ((it_mst_regist_info_rec.belling_details_div = ct_bllng_dtls_dv_cash)
            AND  ((gt_bank_number      <> lt_bank_number)
              OR  (gt_bank_num         <> lt_bank_num)
              OR  (gt_bank_account_num <> lt_bank_account_num)
                 )
             )
            OR
          --IF ((NVL(it_mst_regist_info_rec.bank_number, fnd_api.g_miss_char) <> lt_bank_number)
          --  OR (NVL(it_mst_regist_info_rec.branch_number, fnd_api.g_miss_char) <> lt_bank_num)
          --  OR (NVL(it_mst_regist_info_rec.bank_account_number, fnd_api.g_miss_char) <> lt_bank_account_num))
             ((it_mst_regist_info_rec.belling_details_div <> ct_bllng_dtls_dv_cash)
            AND  ((NVL(it_mst_regist_info_rec.bank_number, fnd_api.g_miss_char)         <> lt_bank_number)
              OR  (NVL(it_mst_regist_info_rec.branch_number, fnd_api.g_miss_char)       <> lt_bank_num)
              OR  (NVL(it_mst_regist_info_rec.bank_account_number, fnd_api.g_miss_char) <> lt_bank_account_num)
                 )
             )
          /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
          THEN
            -- 取得した銀行・支店コードと変更前の銀行・支店コード・口座番号が変わっていた場合
            -- ===================================================
            -- ベンダー中間I/Fテーブル登録（口座割当マスタ廃止用）
            -- ===================================================
            BEGIN
              INSERT INTO xx03_vendors_interface(
                 vendors_interface_id         -- 仕入先インターフェースＩＤ
                ,insert_update_flag           -- 追加更新フラグ
                ,vndr_vendor_id               -- 仕入先仕入先ＩＤ
                ,vndr_vendor_name             -- 仕入先仕入先名
                ,vndr_segment1                -- 仕入先仕入先番号
                ,vndr_vendor_type_lkup_code   -- 仕入先仕入先タイプ
                ,vndr_vendor_name_alt         -- 仕入先仕入先カナ名称
                ,site_vendor_site_id          -- 仕入先サイト仕入先サイトＩＤ
                ,site_vendor_site_code        -- 仕入先サイト仕入先サイト名
                ,site_address_line1           -- 仕入先サイト所在地1
                ,site_address_line2           -- 仕入先サイト所在地2
                ,site_city                    -- 仕入先サイト住所・郡市区
                ,site_state                   -- 仕入先サイト住所・都道府県
                ,site_zip                     -- 仕入先サイト住所・郵便番号
                ,site_country                 -- 仕入先サイト国
                ,site_area_code               -- 仕入先サイト市外局番
                ,site_phone                   -- 仕入先サイト電話番号
                ,site_bank_account_name       -- 仕入先サイト口座名称
                ,site_bank_account_num        -- 仕入先サイト口座番号
                ,site_bank_num                -- 仕入先サイト銀行コード
                ,site_bank_account_type       -- 仕入先サイト預金種別
                ,site_attribute_category      -- 仕入先サイト予備カテゴリ
                ,site_attribute1              -- 仕入先サイト予備1
                ,site_attribute3              -- 仕入先サイト予備3
                ,site_attribute4              -- 仕入先サイト予備4
                ,site_attribute5              -- 仕入先サイト予備5
                ,site_bank_number             -- 仕入先サイト銀行支店コード
                ,site_vendor_site_code_alt    -- 仕入先サイト仕入先サイト名（カナ）
                ,site_bank_charge_bearer      -- 仕入先サイト銀行手数料負担者
                ,acnt_bank_number             -- 銀行口座銀行支店コード
                ,acnt_bank_num                -- 銀行口座銀行コード
                ,acnt_bank_account_name       -- 銀行口座口座名称
                ,acnt_bank_account_num        -- 銀行口座口座番号
                ,acnt_currency_code           -- 銀行口座通貨コード
                ,acnt_bank_account_type       -- 銀行口座預金種別
                ,acnt_account_holder_name     -- 銀行口座口座名義人名
                ,acnt_account_holder_name_alt -- 銀行口座口座名義人名（カナ）
                ,uses_start_date              -- 銀行口座割当開始日
                ,uses_end_date                -- 銀行口座割当終了日
                ,status_flag                  -- ステータスフラグ
                ,creation_date                -- 作成日
                ,created_by                   -- 作成者
                ,last_update_date             -- 最終更新日
                ,last_updated_by              -- 最終更新者
                ,last_update_login            -- 最終更新ログイン
                ,request_id                   -- リクエストＩＤ
                ,program_application_id       -- プログラムアプリケーションＩＤ
                ,program_id                   -- プログラムＩＤ
                ,program_update_date          -- プログラム更新日
              )
              VALUES(
                 xxcso_xx03_vendors_if_s01.NEXTVAL                             -- 仕入先インターフェースＩＤ
                ,cv_update_flag                                                -- 追加更新フラグ
                ,it_mst_regist_info_rec.supplier_id                            -- 仕入先仕入先ＩＤ
                /* 2009.10.15 D.Abe 0001537対応 START */
                --,SUBSTRB(it_mst_regist_info_rec.payment_name, 1, 80)           -- 仕入先仕入先名
                ,SUBSTRB(lt_vendor_number || it_mst_regist_info_rec.payment_name, 1, 80) -- 仕入先仕入先名
                /* 2009.10.15 D.Abe 0001537対応 END */
                ,SUBSTRB(lt_vendor_number, 1, 30)                              -- 仕入先仕入先番号
                ,SUBSTRB(cv_vendor_type, 1, 30)                                -- 仕入先仕入先タイプ
                ,SUBSTRB(it_mst_regist_info_rec.payment_name_alt, 1, 320)      -- 仕入先仕入先カナ名称
                ,lt_vendor_site_id                                             -- 仕入先サイト仕入先サイトＩＤ
                ,SUBSTRB(lt_vendor_number, 1, 320)                             -- 仕入先サイト仕入先サイト名
                ,SUBSTRB(it_mst_regist_info_rec.address_1, 1, 35)              -- 仕入先サイト所在地1
                ,SUBSTRB(it_mst_regist_info_rec.address_2, 1, 35)              -- 仕入先サイト所在地2
                ,SUBSTRB(it_mst_regist_info_rec.city_ward, 1, 25)              -- 仕入先サイト住所・郡市区
                ,SUBSTRB(it_mst_regist_info_rec.prefectures, 1, 25)            -- 仕入先サイト住所・都道府県
                ,SUBSTRB(it_mst_regist_info_rec.post_code, 1, 20)              -- 仕入先サイト住所・郵便番号
                ,SUBSTRB(cv_country_code, 1, 25)                               -- 仕入先サイト国
                ,SUBSTRB(lv_area_code, 1, 10)                                  -- 仕入先サイト市外局番
                ,SUBSTRB(lv_phone_number, 1, 15)                               -- 仕入先サイト電話番号
                ,SUBSTRB(lt_bank_account_name, 1, 80)                          -- 仕入先サイト口座名称
                ,SUBSTRB(lt_bank_account_num, 1, 30)                           -- 仕入先サイト口座番号
                ,SUBSTRB(lt_bank_number, 1, 25)                                -- 仕入先サイト銀行コード
                ,SUBSTRB(lt_bank_account_type, 1, 25)                          -- 仕入先サイト預金種別
                ,cn_org_id                                                     -- 仕入先サイト予備カテゴリ
                ,SUBSTRB(it_mst_regist_info_rec.payment_name, 1, 150)          -- 仕入先サイト予備1
                ,SUBSTRB(cv_flag_yes, 1, 150)                                  -- 仕入先サイト予備3
                ,SUBSTRB(it_mst_regist_info_rec.belling_details_div, 1, 150)   -- 仕入先サイト予備4
                ,SUBSTRB(it_mst_regist_info_rec.inquery_charge_hub_cd, 1, 150) -- 仕入先サイト予備5
                ,SUBSTRB(lt_bank_num, 1, 30)                                   -- 仕入先サイト支店コード
                ,SUBSTRB(it_mst_regist_info_rec.payment_name_alt, 1, 320)      -- 仕入先サイト仕入先サイト名（カナ）
                ,it_mst_regist_info_rec.bank_transfer_fee_charge_div           -- 仕入先サイト銀行手数料負担者
                ,SUBSTRB(lt_bank_num, 1, 30)                                   -- 銀行口座銀行支店コード
                ,SUBSTRB(lt_bank_number, 1, 25)                                -- 銀行口座銀行コード
                ,SUBSTRB(lt_bank_account_name, 1, 80)                          -- 銀行口座口座名称
                ,SUBSTRB(lt_bank_account_num, 1, 30)                           -- 銀行口座口座番号
                ,cv_currency_code                                              -- 銀行口座通貨コード
                ,SUBSTRB(lt_bank_account_type, 1, 25)                          -- 銀行口座預金種別
                ,SUBSTRB(lt_account_holder_name, 1, 240)                       -- 銀行口座口座名義人名
                ,SUBSTRB(lt_account_holder_name_alt, 1, 150)                   -- 銀行口座口座名義人名（カナ）
                ,ld_start_date                                                 -- 銀行口座割当開始日
                ,cd_process_date                                               -- 銀行口座割当終了日
                ,cv_status                                                     -- ステータスフラグ
                ,cd_creation_date                                              -- 作成日
                ,cn_created_by                                                 -- 作成者
                ,cd_last_update_date                                           -- 最終更新日
                ,cn_last_updated_by                                            -- 最終更新者
                ,cn_last_update_login                                          -- 最終更新ログイン
                ,cn_request_id                                                 -- リクエストＩＤ
                ,cn_program_application_id                                     -- プログラムアプリケーションＩＤ
                ,cn_program_id                                                 -- プログラムＩＤ
                ,cd_program_update_date                                        -- プログラム更新日
              );
              --
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_06         -- メッセージコード
                               ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                               ,iv_token_value1 => cv_tkn_value_table       -- トークン値1
                               ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                               ,iv_token_value2 => SQLERRM                  -- トークン値2
                            );
                --
                RAISE global_api_expt;
                --
            END;
          END IF;
          --
        END IF;
        --
      END IF;
      --
      /* 2010.03.04 K.Hosoi E_本稼動_01678対応 START */
      --IF (it_mst_regist_info_rec.bank_account_dummy_flag = cv_flag_on) THEN
      --  -- 銀行口座ダミーフラグがONの場合
      --  -- ================================
      --  -- ダミー銀行コード取得
      --  -- ================================
      --  BEGIN
      --    SELECT flv.meaning bank_number -- 銀行コード
      --    INTO   lt_bank_number
      --    FROM   fnd_lookup_values_vl flv -- 参照コード
      --    WHERE  flv.lookup_type                            =  ct_dummy_bank
      --    AND    flv.lookup_code                            =  ct_dummy_bank_number
      --    AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      --    AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
      --    AND    flv.enabled_flag                           = cv_flag_yes
      --    ;
      --    --
      --  EXCEPTION
      --    WHEN OTHERS THEN
      --      lv_errbuf := xxccp_common_pkg.get_msg(
      --                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
      --                     ,iv_name         => cv_tkn_number_04         -- メッセージコード
      --                     ,iv_token_name1  => cv_tkn_task_name         -- トークンコード1
      --                     ,iv_token_value1 => cv_tkn_value_task_name2  -- トークン値1
      --                     ,iv_token_name2  => cv_tkn_lookup_type_name  -- トークンコード2
      --                     ,iv_token_value2 => ct_dummy_bank            -- トークン値2
      --                   );
      --      --
      --      RAISE global_api_expt;
      --      --
      --  END;
      --  --
      --  -- ================================
      --  -- ダミー支店コード取得
      --  -- ================================
      --  BEGIN
      --    SELECT flv.meaning bank_number -- 支店コード
      --    INTO   lt_bank_num
      --    FROM   fnd_lookup_values_vl flv -- 参照コード
      --    WHERE  flv.lookup_type                            =  ct_dummy_bank
      --    AND    flv.lookup_code                            =  ct_dummy_bank_num
      --    AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      --    AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
      --    AND    flv.enabled_flag                           = cv_flag_yes
      --    ;
      --    --
      --  EXCEPTION
      --    WHEN OTHERS THEN
      --      lv_errbuf := xxccp_common_pkg.get_msg(
      --                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
      --                     ,iv_name         => cv_tkn_number_04         -- メッセージコード
      --                     ,iv_token_name1  => cv_tkn_task_name         -- トークンコード1
      --                     ,iv_token_value1 => cv_tkn_value_task_name3  -- トークン値1
      --                     ,iv_token_name2  => cv_tkn_lookup_type_name  -- トークンコード2
      --                     ,iv_token_value2 => ct_dummy_bank            -- トークン値2
      --                   );
      --      --
      --      RAISE global_api_expt;
      --      --
      --  END;
      --  --
      --  -- *** DEBUG_LOG START ***
      --  -- ダミー口座情報をログ出力
      --  fnd_file.put_line(
      --     which  => fnd_file.log
      --    ,buff   => cv_debug_msg47 || CHR(10) ||
      --               cv_debug_msg48 || lt_bank_number || CHR(10) ||
      --               cv_debug_msg49 || lt_bank_num    || CHR(10) ||
      --               ''
      --  );
      --  -- *** DEBUG_LOG END ***
      --  --
      --  lt_bank_account_name       := cv_dummy_bank_acct_name;       -- 口座名称
      --  lt_bank_account_num        := cv_dummy_bank_acct_num;        -- 口座番号
      --  lt_bank_account_type       := cv_dummy_bank_acct_type;       -- 預金種別
      --  lt_account_holder_name     := cv_dummy_acct_holder_name;     -- 口座名義人名
      --  lt_account_holder_name_alt := cv_dummy_acct_holder_name_alt; -- 口座名義人名（カナ）
      IF (it_mst_regist_info_rec.belling_details_div = ct_bllng_dtls_dv_cash) THEN
      -- ＢＭ支払区分が4：現金支払の場合
        -- ================================
        -- ダミー口座情報設定
        -- ================================
        lt_bank_number              := gt_bank_number;                                -- 銀行コード
        lt_bank_num                 := gt_bank_num;                                   -- 銀行支店コード
        lt_bank_account_name        := gt_bank_account_name;                          -- 口座名称
        lt_bank_account_num         := gt_bank_account_num;                           -- 口座番号
        lt_bank_account_type        := gt_bank_account_type;                          -- 預金種別
        lt_account_holder_name      := gt_account_holder_name;                        -- 口座名義人名
        lt_account_holder_name_alt  := gt_account_holder_name_alt;                    -- 口座名義人名（カナ）
      /* 2010.03.04 K.Hosoi E_本稼動_01678対応 END */
        --
      ELSE
        lt_bank_number             := it_mst_regist_info_rec.bank_number;             -- 銀行コード
        lt_bank_num                := it_mst_regist_info_rec.branch_number;           -- 銀行支店コード
        lt_bank_account_name       := it_mst_regist_info_rec.bank_name   || cv_diagonal ||
                                      it_mst_regist_info_rec.branch_name || cv_diagonal ||
                                      lv_bank_account_type_name;                      -- 口座名称
        lt_bank_account_num        := it_mst_regist_info_rec.bank_account_number;     -- 口座番号
        lt_bank_account_type       := it_mst_regist_info_rec.bank_account_type;       -- 預金種別
        lt_account_holder_name     := it_mst_regist_info_rec.bank_account_name_kanji; -- 口座名義人名
        lt_account_holder_name_alt := it_mst_regist_info_rec.bank_account_name_kana;  -- 口座名義人名（カナ）
        --
      END IF;
      --
      -- ===================================================
      -- ベンダー中間I/Fテーブル登録（登録・更新用）
      -- ===================================================
      /* 2009.10.15 D.Abe 0001537対応 START */
      --IF lt_customer_id IS NULL THEN
      IF it_mst_regist_info_rec.supplier_id IS NULL THEN
      /* 2009.10.15 D.Abe 0001537対応 END */
        -- 顧客ＩＤがNULLの場合、仕入先番号を採番
        BEGIN
          SELECT xxcso_po_vendors_s01.NEXTVAL vendor_number
          INTO   lt_vendor_number
          FROM   DUAL
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_07         -- メッセージコード
                           ,iv_token_name1  => cv_tkn_sequence          -- トークンコード1
                           ,iv_token_value1 => cv_tkn_value_sequence    -- トークン値1
                           ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード2
                           ,iv_token_value2 => SQLERRM                  -- トークン値2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- *** DEBUG_LOG START ***
        -- 採番した仕入先番号をログ出力
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg50 || CHR(10) ||
                     cv_debug_msg51 || lt_vendor_number || CHR(10) ||
                     ''
        );
        -- *** DEBUG_LOG END ***
        --
      END IF;
      --
      BEGIN
        INSERT INTO xx03_vendors_interface(
           vendors_interface_id         -- 仕入先インターフェースＩＤ
          ,insert_update_flag           -- 追加更新フラグ
          ,vndr_vendor_id               -- 仕入先仕入先ＩＤ
          ,vndr_vendor_name             -- 仕入先仕入先名
          ,vndr_segment1                -- 仕入先仕入先番号
          ,vndr_vendor_type_lkup_code   -- 仕入先仕入先タイプ
          ,vndr_vendor_name_alt         -- 仕入先仕入先カナ名称
          ,site_vendor_site_id          -- 仕入先サイト仕入先サイトＩＤ
          ,site_vendor_site_code        -- 仕入先サイト仕入先サイト名
          ,site_address_line1           -- 仕入先サイト所在地1
          ,site_address_line2           -- 仕入先サイト所在地2
          ,site_city                    -- 仕入先サイト住所・郡市区
          ,site_state                   -- 仕入先サイト住所・都道府県
          ,site_zip                     -- 仕入先サイト住所・郵便番号
          ,site_country                 -- 仕入先サイト国
          ,site_area_code               -- 仕入先サイト市外局番
          ,site_phone                   -- 仕入先サイト電話番号
          ,site_bank_account_name       -- 仕入先サイト口座名称
          ,site_bank_account_num        -- 仕入先サイト口座番号
          ,site_bank_num                -- 仕入先サイト銀行コード
          ,site_bank_account_type       -- 仕入先サイト預金種別
          ,site_attribute_category      -- 仕入先サイト予備カテゴリ
          ,site_attribute1              -- 仕入先サイト予備1
          ,site_attribute3              -- 仕入先サイト予備3
          ,site_attribute4              -- 仕入先サイト予備4
          ,site_attribute5              -- 仕入先サイト予備5
          ,site_bank_number             -- 仕入先サイト銀行支店コード
          ,site_vendor_site_code_alt    -- 仕入先サイト仕入先サイト名（カナ）
          ,site_bank_charge_bearer      -- 仕入先サイト銀行手数料負担者
          ,acnt_bank_number             -- 銀行口座銀行支店コード
          ,acnt_bank_num                -- 銀行口座銀行コード
          ,acnt_bank_account_name       -- 銀行口座口座名称
          ,acnt_bank_account_num        -- 銀行口座口座番号
          ,acnt_currency_code           -- 銀行口座通貨コード
          ,acnt_bank_account_type       -- 銀行口座預金種別
          ,acnt_account_holder_name     -- 銀行口座口座名義人名
          ,acnt_account_holder_name_alt -- 銀行口座口座名義人名（カナ）
          ,uses_start_date              -- 銀行口座割当開始日
          ,status_flag                  -- ステータスフラグ
          ,creation_date                -- 作成日
          ,created_by                   -- 作成者
          ,last_update_date             -- 最終更新日
          ,last_updated_by              -- 最終更新者
          ,last_update_login            -- 最終更新ログイン
          ,request_id                   -- リクエストＩＤ
          ,program_application_id       -- プログラムアプリケーションＩＤ
          ,program_id                   -- プログラムＩＤ
          ,program_update_date          -- プログラム更新日
        )
        VALUES(
           xxcso_xx03_vendors_if_s01.NEXTVAL                             -- 仕入先インターフェースＩＤ
          /* 2009.10.15 D.Abe 0001537対応 START */
          --,DECODE(lt_customer_id
          ,DECODE(it_mst_regist_info_rec.supplier_id
          /* 2009.10.15 D.Abe 0001537対応 END */
                 ,NULL, cv_create_flag
                 ,cv_update_flag)                                        -- 追加更新フラグ
          /* 2009.10.15 D.Abe 0001537対応 START */
          --,DECODE(lt_customer_id
          ,DECODE(it_mst_regist_info_rec.supplier_id
          /* 2009.10.15 D.Abe 0001537対応 END */
                 ,NULL, NULL
                 ,it_mst_regist_info_rec.supplier_id)                    -- 仕入先仕入先ＩＤ
          /* 2009.10.15 D.Abe 0001537対応 START */
          --,SUBSTRB(it_mst_regist_info_rec.payment_name, 1, 80)           -- 仕入先仕入先名
          ,SUBSTRB(lt_vendor_number || it_mst_regist_info_rec.payment_name, 1, 80) -- 仕入先仕入先名
          /* 2009.10.15 D.Abe 0001537対応 END */
          ,SUBSTRB(lt_vendor_number, 1, 30)                              -- 仕入先仕入先番号
          ,SUBSTRB(cv_vendor_type, 1, 30)                                -- 仕入先仕入先タイプ
          ,SUBSTRB(it_mst_regist_info_rec.payment_name_alt, 1, 320)      -- 仕入先仕入先カナ名称
          /* 2009.10.15 D.Abe 0001537対応 START */
          --,DECODE(lt_customer_id
          ,DECODE(it_mst_regist_info_rec.supplier_id
          /* 2009.10.15 D.Abe 0001537対応 END */
                 ,NULL, NULL
                 ,lt_vendor_site_id)                                     -- 仕入先サイト仕入先サイトＩＤ
          ,SUBSTRB(lt_vendor_number, 1, 320)                             -- 仕入先サイト仕入先サイト名
          ,SUBSTRB(it_mst_regist_info_rec.address_1, 1, 35)              -- 仕入先サイト所在地1
          ,SUBSTRB(it_mst_regist_info_rec.address_2, 1, 35)              -- 仕入先サイト所在地2
          ,SUBSTRB(it_mst_regist_info_rec.city_ward, 1, 25)              -- 仕入先サイト住所・郡市区
          ,SUBSTRB(it_mst_regist_info_rec.prefectures, 1, 25)            -- 仕入先サイト住所・都道府県
          ,SUBSTRB(it_mst_regist_info_rec.post_code, 1, 20)              -- 仕入先サイト住所・郵便番号
          ,SUBSTRB(cv_country_code, 1, 25)                               -- 仕入先サイト国
          ,SUBSTRB(lv_area_code, 1, 10)                                  -- 仕入先サイト市外局番
          ,SUBSTRB(lv_phone_number, 1, 15)                               -- 仕入先サイト電話番号
          /* 2009.10.15 D.Abe 0001537対応 START */
          --,SUBSTRB(it_mst_regist_info_rec.bank_name || cv_diagonal ||
          -- it_mst_regist_info_rec.branch_name       || cv_diagonal ||
          -- lt_bank_account_name, 1, 80)                                  -- 仕入先サイト口座名称
          ,SUBSTRB(lt_bank_account_name, 1, 80)                        -- 仕入先サイト口座名称
          /* 2009.10.15 D.Abe 0001537対応 END */
          ,SUBSTRB(lt_bank_account_num, 1, 30)                           -- 仕入先サイト口座番号
          ,SUBSTRB(lt_bank_number, 1, 25)                                -- 仕入先サイト銀行コード
          ,SUBSTRB(lt_bank_account_type, 1, 25)                          -- 仕入先サイト預金種別
          ,cn_org_id                                                     -- 仕入先サイト予備カテゴリ
          ,SUBSTRB(it_mst_regist_info_rec.payment_name, 1, 150)          -- 仕入先サイト予備1
          ,SUBSTRB(cv_flag_yes, 1, 150)                                  -- 仕入先サイト予備3
          ,SUBSTRB(it_mst_regist_info_rec.belling_details_div, 1, 150)   -- 仕入先サイト予備4
          ,SUBSTRB(it_mst_regist_info_rec.inquery_charge_hub_cd, 1, 150) -- 仕入先サイト予備5
          ,SUBSTRB(lt_bank_num, 1, 30)                                   -- 仕入先サイト支店コード
          ,SUBSTRB(it_mst_regist_info_rec.payment_name_alt, 1, 320)      -- 仕入先サイト仕入先サイト名（カナ）
          ,it_mst_regist_info_rec.bank_transfer_fee_charge_div           -- 仕入先サイト銀行手数料負担者
          ,SUBSTRB(lt_bank_num, 1, 30)                                   -- 銀行口座銀行支店コード
          ,SUBSTRB(lt_bank_number, 1, 25)                                -- 銀行口座銀行コード
          ,SUBSTRB(lt_bank_account_name, 1, 80)                          -- 銀行口座口座名称
          ,SUBSTRB(lt_bank_account_num, 1, 30)                           -- 銀行口座口座番号
          ,cv_currency_code                                              -- 銀行口座通貨コード
          ,SUBSTRB(lt_bank_account_type, 1, 25)                          -- 銀行口座預金種別
          ,SUBSTRB(lt_account_holder_name, 1, 240)                       -- 銀行口座口座名義人名
          ,SUBSTRB(lt_account_holder_name_alt, 1, 150)                   -- 銀行口座口座名義人名（カナ）
          ,cd_process_date                                               -- 銀行口座割当開始日
          ,cv_status                                                     -- ステータスフラグ
          ,cd_creation_date                                              -- 作成日
          ,cn_created_by                                                 -- 作成者
          ,cd_last_update_date                                           -- 最終更新日
          ,cn_last_updated_by                                            -- 最終更新者
          ,cn_last_update_login                                          -- 最終更新ログイン
          ,cn_request_id                                                 -- リクエストＩＤ
          ,cn_program_application_id                                     -- プログラムアプリケーションＩＤ
          ,cn_program_id                                                 -- プログラムＩＤ
          ,cd_program_update_date                                        -- プログラム更新日
        );
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_table       -- トークン値1
                         ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                         ,iv_token_value2 => SQLERRM                  -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      /* 2009.10.15 D.Abe 0001537対応 START */
      --
      -- ================================
      -- 送付先仕入先番号更新
      -- ================================
      BEGIN
        UPDATE xxcso_destinations xde -- 送付先テーブル
        SET    xde.vendor_number          = lt_vendor_number          -- 仕入先番号
              ,xde.last_updated_by        = cn_last_updated_by        -- 最終更新者
              ,xde.last_update_date       = cd_last_update_date       -- 最終更新日
              ,xde.last_update_login      = cn_last_update_login      -- 最終更新ログイン
              ,xde.request_id             = cn_request_id             -- 要求ID
              ,xde.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xde.program_id             = cn_program_id             -- コンカレント・プログラムID
              ,xde.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE xde.delivery_id = it_mst_regist_info_rec.delivery_id    -- 送付先ＩＤ
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_02         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_destination -- トークン値1
                         ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                         ,iv_token_value2 => SQLERRM                  -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      /* 2009.10.15 D.Abe 0001537対応 END */
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END reg_vendor_if;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_vendor
   * Description      : 仕入先情報登録/更新処理(A-6)
   ***********************************************************************************/
  PROCEDURE reg_vendor(
     on_request_id OUT NOCOPY NUMBER   -- 要求ＩＤ
    ,ov_errbuf     OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_vendor';  -- プログラム名
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
    cv_application CONSTANT VARCHAR2(4)  := 'XX03';
    cv_program     CONSTANT VARCHAR2(20) := 'XX03PVI001C';
    cv_argument1   CONSTANT VARCHAR2(1)  := '0';
    --
    -- トークン用定数
    cv_tkn_value_proc_name CONSTANT VARCHAR2(100) := 'I009_XX03_移行_仕入先_インポート処理';
    --
    -- *** ローカル変数 ***
    ln_request_id NUMBER;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    -- *** DEBUG_LOG START ***
    -- ＢＦＡ起動開始をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg76 || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    --
    -- ============================
    -- 発注依頼ヘッダ・明細登録処理
    -- ============================
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_program
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => cv_argument1
                       ,argument2   => cd_process_date
                     );
    --
    IF (ln_request_id = 0) THEN
      -- 要求ＩＤが0の場合エラーメッセージを取得します。
      fnd_message.retrieve(msgout => lv_errbuf);
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_08         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_proc_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- トークン値1
                     ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード1
                     ,iv_token_value2 => lv_errbuf                -- トークン値1
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    -- *** DEBUG_LOG START ***
    -- ＢＦＡ起動終了をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg77 || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    --
    -- *** DEBUG_LOG START ***
    -- 要求ＩＤをログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg52 || CHR(10) ||
                 cv_debug_msg53 || ln_request_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
    on_request_id := ln_request_id;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : confirm_reg_vendor
   * Description      : 仕入先情報登録/更新完了確認処理(A-7)
   ***********************************************************************************/
  PROCEDURE confirm_reg_vendor(
     in_request_id IN         NUMBER   -- 要求ＩＤ
    ,ov_errbuf     OUT NOCOPY VARCHAR2 -- エラー・メッセージ --# 固定 #
    ,ov_retcode    OUT NOCOPY VARCHAR2 -- リターン・コード   --# 固定 #
    ,ov_errmsg     OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'confirm_reg_vendor';  -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_profile_option_name1 CONSTANT VARCHAR2(30) := 'XXCSO1_MST_LINK_WAIT_TIME';
    cv_profile_option_name2 CONSTANT VARCHAR2(30) := 'XXCSO1_CONC_MAX_WAIT_TIME';
    --
    -- 実行フェーズ
    cv_phase_complete CONSTANT VARCHAR2(20) := 'COMPLETE'; -- 完了
    --
    -- トークン用定数
    cv_tkn_value_proc_name CONSTANT VARCHAR2(50) := 'I009_XX03_移行_仕入先_インポート処理';
    --
    -- *** ローカル変数 ***
    lb_return     BOOLEAN;
    lv_phase      VARCHAR2(5000);
    lv_status     VARCHAR2(5000);
    lv_dev_phase  VARCHAR2(5000);
    lv_dev_status VARCHAR2(5000);
    lv_message    VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    -- *** DEBUG_LOG START ***
    -- 仕入先登録処理完了確認処理開始をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg78 || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    --
    -- ================================
    -- 仕入先情報登録/更新完了確認
    -- ================================
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => in_request_id
                   ,interval   => fnd_profile.value(cv_profile_option_name1)
                   ,max_wait   => fnd_profile.value(cv_profile_option_name2)
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF NOT (lb_return) THEN
      -- 戻り値がFALSEの場合
      fnd_message.retrieve(msgout => lv_errbuf);
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_09         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_proc_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- トークン値1
                     ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード1
                     ,iv_token_value2 => lv_errbuf                -- トークン値1
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    -- *** DEBUG_LOG START ***
    -- 仕入先登録処理完了確認処理終了をログ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg79 || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    IF (lv_dev_phase <> cv_phase_complete) THEN
      -- 実行フェーズが正常以外の場合
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_proc_name         -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- トークン値1
                     ,iv_token_name2  => cv_tkn_proc_name         -- トークンコード2
                     ,iv_token_value2 => lv_dev_phase             -- トークン値2
                     ,iv_token_name3  => cv_tkn_proc_name         -- トークンコード3
                     ,iv_token_value3 => lv_dev_status            -- トークン値3
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END confirm_reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : error_reg_vendor
   * Description      : 仕入先情報登録/更新エラー時処理(A-8)
   ***********************************************************************************/
  PROCEDURE error_reg_vendor(
     it_contract_management_id IN         xxcso_contract_managements.contract_management_id%TYPE -- 自動販売機設置契約書ＩＤ
    ,it_contract_number        IN         xxcso_contract_managements.contract_number%TYPE        -- 契約書番号
    ,in_request_id             IN         NUMBER                                                 -- 要求ＩＤ
    ,ov_err_flag               OUT NOCOPY VARCHAR2                                               -- 仕入先エラーフラグ
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                               -- エラー・メッセージ --# 固定 #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                               -- リターン・コード   --# 固定 #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                               -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'error_reg_vendor'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_msg_lookup_type CONSTANT VARCHAR2(100) := 'XX03_VENDOR_IF_ERROR_REASON';
    cv_status_flag     CONSTANT xx03_vendors_interface.status_flag%TYPE := 'E';
    --
    -- トークン用定数
    cv_tkn_value_cont_manage CONSTANT VARCHAR2(50) := '契約管理テーブル';
    --
    -- *** ローカル変数 ***
    lv_update_flag VARCHAR2(1) := cv_flag_no; -- 更新済フラグ
    --
    -- *** ローカル・カーソル ***
    CURSOR destinations_cur
    IS
      SELECT xx03_get_error_message_pkg.get_error_message(cv_msg_lookup_type, xvi.error_reason) err_msg -- エラー理由
            ,xvi.vndr_vendor_name vendor_name -- 仕入先仕入先名
      FROM   xxcso_destinations     xde -- 送付先テーブル
            ,xx03_vendors_interface xvi -- ベンダー中間I/Fテーブル
      WHERE  xde.contract_management_id = it_contract_management_id  -- 自動販売機設置契約書ＩＤ
      /* 2009.04.02 K.Satomura 障害番号T1_0227対応 START */
      --AND    xvi.vndr_vendor_name       LIKE xde.payment_name || '%' -- 仕入先名
      /* 2009.10.15 D.Abe 0001537対応 START */
      --AND    xvi.vndr_vendor_name       = xde.payment_name           -- 仕入先名
      AND    xvi.vndr_segment1          = xde.vendor_number          -- 仕入先番号
      /* 2009.10.15 D.Abe 0001537対応 END */
      /* 2009.04.02 K.Satomura 障害番号T1_0227対応 END */
      AND    xvi.status_flag            = cv_status_flag             -- ステータスフラグ
      AND    xvi.request_id             = in_request_id              -- 要求ＩＤ
      ;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    ov_err_flag := cv_flag_no;
    --
    -- ================================
    -- エラー情報取得
    -- ================================
    <<error_data_get_loop>>
    FOR lt_destinations_rec IN destinations_cur LOOP
      ov_err_flag := cv_flag_yes;
      --
      -- ================================
      -- エラー情報更新
      -- ================================
      IF (lv_update_flag = cv_flag_no) THEN
        BEGIN
          UPDATE xxcso_contract_managements xcm -- 契約管理テーブル
          SET    xcm.batch_proc_status      = cv_batch_proc_status_err  -- バッチ処理ステータス
                ,xcm.last_updated_by        = cn_last_updated_by        -- 最終更新者
                ,xcm.last_update_date       = cd_last_update_date       -- 最終更新日
                ,xcm.last_update_login      = cn_last_update_login      -- 最終更新ログイン
                ,xcm.request_id             = cn_request_id             -- 要求ID
                ,xcm.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
                ,xcm.program_id             = cn_program_id             -- コンカレント・プログラムID
                ,xcm.program_update_date    = cd_program_update_date    -- プログラム更新日
          WHERE xcm.contract_management_id = it_contract_management_id -- 自動販売機設置契約書ＩＤ
          ;
          --
          lv_update_flag := cv_flag_yes;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_02         -- メッセージコード
                           ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                           ,iv_token_value1 => cv_tkn_value_cont_manage -- トークン値1
                           ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                           ,iv_token_value2 => SQLERRM                  -- トークン値2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      END IF;
      --
      -- *** DEBUG_LOG START ***
      -- エラーメッセージをログ出力
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg54 || CHR(10) ||
                   cv_debug_msg74 || it_contract_number               || CHR(10) ||
                   cv_debug_msg55 || lt_destinations_rec.vendor_name  || CHR(10) ||
                   cv_debug_msg56 || lt_destinations_rec.err_msg      || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
    END LOOP error_data_get_loop;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END error_reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : associate_vendor_id
   * Description      : 仕入先ID関連付け処理(A-9)
   ***********************************************************************************/
  PROCEDURE associate_vendor_id(
     it_contract_management_id IN         xxcso_contract_managements.contract_management_id%TYPE -- 自動販売機設置契約書ＩＤ
    ,it_sp_decision_header_id  IN         xxcso_contract_managements.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                               -- エラー・メッセージ --# 固定 #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                               -- リターン・コード   --# 固定 #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                               -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'associate_vendor_id'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    /* 2009.04.27 K.Satomura T1_0766対応 START */
    cv_bm1_send_type_other CONSTANT xxcso_sp_decision_headers.bm1_send_type%TYPE := '3'; -- ＢＭ１送付先区分=その他
    /* 2009.04.27 K.Satomura T1_0766対応 END */
    --
    -- トークン用定数
    cv_tkn_value_action_vendor CONSTANT VARCHAR2(50) := '仕入先ＩＤ関連付け処理時：仕入先マスタ';
    cv_tkn_value_key_name_ven  CONSTANT VARCHAR2(50) := '支払先名';
    cv_tkn_value_sp_dec_cust   CONSTANT VARCHAR2(50) := 'ＳＰ専決顧客テーブル';
    cv_tkn_value_key_name_sp   CONSTANT VARCHAR2(50) := 'ＳＰ専決ヘッダＩＤ';
    cv_tkn_value_destination   CONSTANT VARCHAR2(50) := '送付先テーブル';
    /* 2009.04.27 K.Satomura T1_0766対応 START */
    cv_tkn_value_sp_dec_head   CONSTANT VARCHAR2(50) := 'ＳＰ専決ヘッダテーブル';
    /* 2009.04.27 K.Satomura T1_0766対応 END */
    --
    -- *** ローカル変数 ***
    lt_vendor_id               po_vendors.vendor_id%TYPE;
    lt_sp_decision_customer_id xxcso_sp_decision_custs.sp_decision_customer_id%TYPE;
    lt_customer_id             xxcso_sp_decision_custs.customer_id%TYPE;
    --
    -- *** ローカル・カーソル ***
    CURSOR destinations_cur
    IS
      SELECT xde.delivery_id  delivery_id  -- 送付先ＩＤ
            ,xde.payment_name payment_name -- 支払先名
            ,xde.delivery_div delivery_div -- 送付区分
            /* 2009.10.15 D.Abe 0001537対応 START */
            ,xde.vendor_number vendor_number -- 仕入先番号
            ,xde.supplier_id   supplier_id -- 仕入先ID
            /* 2009.10.15 D.Abe 0001537対応 END */
      FROM   xxcso_destinations xde -- 送付先テーブル
      WHERE  xde.contract_management_id = it_contract_management_id -- 自動販売機設置契約書ＩＤ
      ORDER BY xde.delivery_div ASC
      ;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ================================
    -- 送付先テーブル取得
    -- ================================
    <<destinations_loop>>
    FOR lt_destinations_rec IN destinations_cur LOOP
      lt_customer_id := NULL;
      --
      -- ================================
      -- 仕入先ＩＤ取得
      -- ================================
      BEGIN
        SELECT pve.vendor_id vendor_id -- 仕入先ＩＤ
        INTO   lt_vendor_id
        FROM   po_vendors pve -- 仕入先マスタ
        /* 2009.04.02 K.Satomura 障害番号T1_0227対応 START */
        --WHERE  pve.vendor_name LIKE lt_destinations_rec.payment_name || '%'
        /* 2009.10.15 D.Abe 0001537対応 START */
        --WHERE  pve.vendor_name = lt_destinations_rec.payment_name
        WHERE  pve.segment1 = lt_destinations_rec.vendor_number
        /* 2009.10.15 D.Abe 0001537対応 END */
        /* 2009.04.02 K.Satomura 障害番号T1_0227対応 END */
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name         -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_05                 -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action                    -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_action_vendor       -- トークン値1
                         ,iv_token_name2  => cv_tkn_key_name                  -- トークンコード2
                         ,iv_token_value2 => cv_tkn_value_key_name_ven        -- トークン値2
                         ,iv_token_name3  => cv_tkn_key_id                    -- トークンコード3
                         ,iv_token_value3 => lt_destinations_rec.payment_name -- トークン値3
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- *** DEBUG_LOG START ***
      -- 仕入先ＩＤをログ出力
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg57 || CHR(10) ||
                   cv_debug_msg58 || lt_vendor_id || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
      -- ================================
      -- ＳＰ専決顧客顧客ＩＤ更新
      -- ================================
      BEGIN
        SELECT xsd.sp_decision_customer_id sp_decision_customer_id -- ＳＰ専決顧客ＩＤ
              ,xsd.customer_id             customer_id             -- 顧客ＩＤ
        INTO   lt_sp_decision_customer_id
              ,lt_customer_id
        FROM   xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
        WHERE  xsd.sp_decision_header_id      = it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
        AND    xsd.sp_decision_customer_class = DECODE(lt_destinations_rec.delivery_div
                                                      ,ct_delivery_div_bm1, ct_sp_dec_cust_class_bm1
                                                      ,ct_delivery_div_bm2, ct_sp_dec_cust_class_bm2
                                                      ,ct_delivery_div_bm3, ct_sp_dec_cust_class_bm3
                                                )
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_05         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_sp_dec_cust -- トークン値1
                         ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                         ,iv_token_value2 => cv_tkn_value_key_name_sp -- トークン値2
                         ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                         ,iv_token_value3 => it_sp_decision_header_id -- トークン値3
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- *** DEBUG_LOG START ***
      -- 顧客ＩＤをログ出力
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg59 || CHR(10)        ||
                   cv_debug_msg60 || lt_customer_id || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
      /* 2009.10.15 D.Abe 0001537対応 START */
      --IF (lt_customer_id IS NULL) THEN
      /* 2010.02.05 D.Abe E_本稼動_01537対応 START */
      --IF (lt_destinations_rec.supplier_id IS NULL) THEN
      /* 2010.02.05 D.Abe E_本稼動_01537対応 END */
      /* 2009.10.15 D.Abe 0001537対応 END */
      -- 顧客ＩＤがNULLの場合のみ顧客ＩＤ・仕入先ＩＤを更新する。
      BEGIN
        UPDATE xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
        SET    xsd.customer_id            = lt_vendor_id              -- 顧客ＩＤ
              ,xsd.last_updated_by        = cn_last_updated_by        -- 最終更新者
              ,xsd.last_update_date       = cd_last_update_date       -- 最終更新日
              ,xsd.last_update_login      = cn_last_update_login      -- 最終更新ログイン
              ,xsd.request_id             = cn_request_id             -- 要求ID
              ,xsd.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xsd.program_id             = cn_program_id             -- コンカレント・プログラムID
              ,xsd.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE xsd.sp_decision_customer_id = lt_sp_decision_customer_id
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_02         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_sp_dec_cust -- トークン値1
                         ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                         ,iv_token_value2 => SQLERRM                  -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- ================================
      -- 送付先仕入先ＩＤ更新
      -- ================================
      BEGIN
        UPDATE xxcso_destinations xde -- 送付先テーブル
        SET    xde.supplier_id            = lt_vendor_id              -- 仕入先ＩＤ
              ,xde.last_updated_by        = cn_last_updated_by        -- 最終更新者
              ,xde.last_update_date       = cd_last_update_date       -- 最終更新日
              ,xde.last_update_login      = cn_last_update_login      -- 最終更新ログイン
              ,xde.request_id             = cn_request_id             -- 要求ID
              ,xde.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xde.program_id             = cn_program_id             -- コンカレント・プログラムID
              ,xde.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE xde.delivery_id = lt_destinations_rec.delivery_id -- 送付先ＩＤ
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_02         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_destination -- トークン値1
                         ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                         ,iv_token_value2 => SQLERRM                  -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      /* 2010.02.05 D.Abe E_本稼動_01537対応 START */
      --END IF;
      /* 2010.02.05 D.Abe E_本稼動_01537対応 END */

      --
      /* 2009.04.27 K.Satomura T1_0766対応 START */
      IF (lt_destinations_rec.delivery_div = ct_delivery_div_bm1) THEN
        -- 送付先区分が1:BM1の場合
        -- ================================
        -- ＢＭ１送付先区分更新
        -- ================================
        BEGIN
          UPDATE xxcso_sp_decision_headers xsd -- ＳＰ専決ヘッダテーブル
          SET    xsd.bm1_send_type = cv_bm1_send_type_other -- ＢＭ１送付先区分
          WHERE  xsd.sp_decision_header_id = it_sp_decision_header_id
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_02         -- メッセージコード
                           ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                           ,iv_token_value1 => cv_tkn_value_sp_dec_head -- トークン値1
                           ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                           ,iv_token_value2 => SQLERRM                  -- トークン値2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      END IF;
      /* 2009.04.27 K.Satomura T1_0766対応 END */
    END LOOP destinations_loop;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END associate_vendor_id;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_backmargin
   * Description      : 販売手数料情報登録/更新処理(A-10)
   ***********************************************************************************/
  PROCEDURE reg_backmargin(
     it_sp_decision_header_id  IN         xxcso_contract_managements.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
    ,it_install_account_number IN         xxcso_contract_managements.install_account_number%TYPE -- 設置先顧客コード
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                               -- エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                               -- リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                               -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_backmargin'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_cond_business_type_01 CONSTANT xxcso_sp_decision_headers.condition_business_type%TYPE := '1';   -- 売価別条件
    cv_cond_business_type_02 CONSTANT xxcso_sp_decision_headers.condition_business_type%TYPE := '2';   -- 売価別条件[寄付金登録用]
    cv_cond_business_type_03 CONSTANT xxcso_sp_decision_headers.condition_business_type%TYPE := '3';   -- 一律・容器別条件
    cv_cond_business_type_04 CONSTANT xxcso_sp_decision_headers.condition_business_type%TYPE := '4';   -- 一律・容器別条件[寄付金登録用]
    cv_electricity_type_1    CONSTANT xxcso_sp_decision_headers.electricity_type%TYPE        := '1';   -- 定額
    /* 2015.02.25 H.Wajima E_本稼動_12565 START */
    cv_electric_pay_type_1   CONSTANT xxcso_sp_decision_headers.electric_payment_type%TYPE   := '1';   -- 契約先
    cv_tax_type_2            CONSTANT xxcso_sp_decision_headers.tax_type%TYPE                := '2';   -- 税抜き
    /* 2015.02.25 H.Wajima E_本稼動_12565 END */
    cv_sp_container_type_all CONSTANT xxcso_sp_decision_lines.sp_container_type%TYPE         := 'ALL'; -- 全容器
    cv_electricity_amount_01 CONSTANT xxcso_sp_decision_headers.electricity_amount%TYPE      := '1';   -- 定額
    cv_calc_type_01          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '10';  -- 売価別条件
    cv_calc_type_02          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '20';  -- 容器区分別条件
    /* 2009.03.24 K.Satomura 障害番号T1_0136応 START */
    --cv_calc_type_03          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '40';  -- 定率条件
    cv_calc_type_03          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '30';  -- 定率条件
    /* 2009.03.24 K.Satomura 障害番号T1_0136対応 END */
    cv_calc_type_04          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '50';  -- 電気料(固定)
    cv_lookup_type           CONSTANT fnd_lookup_values_vl.lookup_type%TYPE                  := 'XXCSO1_SP_RULE_BOTTLE';
    --
    -- トークン用定数
    cv_tkn_value_mst_bm  CONSTANT VARCHAR2(100) := '販手条件マスタ';
    cv_tkn_value_sp_info CONSTANT VARCHAR2(100) := '販売手数料情報登録/更新処理時：ＳＰ専決ヘッダテーブル・ＳＰ専決明細';
    cv_tkn_value_sp_id   CONSTANT VARCHAR2(100) := 'ＳＰ専決ヘッダＩＤ';
    /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 START */
    cn_zero              CONSTANT NUMBER        := 0;
    /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 END */
    --
    -- *** ローカル変数 ***
    ln_sp_decision_count  NUMBER := 0;
    lt_electricity_type   xxcso_sp_decision_headers.electricity_type%TYPE;
    /* 2015.02.25 H.Wajima E_本稼動_12565 START */
    --lt_electricity_amount xxcso_sp_decision_headers.electricity_amount%TYPE;
    lt_electricity_amount xxcok_mst_bm_contract.bm1_amt%TYPE;
    lt_electric_payment_type xxcso_sp_decision_headers.electric_payment_type%TYPE;
    lt_tax_type              xxcso_sp_decision_headers.tax_type%TYPE;
    /* 2015.02.25 H.Wajima E_本稼動_12565 END */
    lv_mst_bm_flag        VARCHAR2(1);
    ln_rowid              ROWID;
    lv_no_data_found_flag VARCHAR2(1);
    /* 2011.12.26 T.Ishiwata E_本稼動_08363 START */
    ln_bm_rate_amount     NUMBER;                                -- ＢＭ率・ＢＭ金額の合計値
    /* 2011.12.26 T.Ishiwata E_本稼動_08363 END */
    --
    -- *** ローカルカーソル ***
    CURSOR sp_decision_cur
    IS
      SELECT sdh.condition_business_type condition_business_type -- 取引条件区分
            ,sdh.electricity_type        electricity_type        -- 電気代区分
            ,sdh.electricity_amount      electricity_amount      -- 電気代
            /* 2015.02.25 H.Wajima E_本稼動_12565 START */
            ,sdh.electric_payment_type   electric_payment_type   -- 支払条件（電気代）
            ,sdh.tax_type                tax_type                -- 税区分
            /* 2015.02.25 H.Wajima E_本稼動_12565 END */
            ,sdl.sp_container_type       sp_container_type       -- ＳＰ容器区分
            ,sdl.sales_price             sales_price             -- 売価
            ,sdl.discount_amt            discount_amt            -- 値引額
            ,sdl.bm1_bm_rate             bm1_bm_rate             -- ＢＭ率１
            ,sdl.bm1_bm_amount           bm1_bm_amount           -- ＢＭ１金額
            ,sdl.bm2_bm_rate             bm2_bm_rate             -- ＢＭ率２
            ,sdl.bm2_bm_amount           bm2_bm_amount           -- ＢＭ２金額
            ,sdl.bm3_bm_rate             bm3_bm_rate             -- ＢＭ率３
            ,sdl.bm3_bm_amount           bm3_bm_amount           -- ＢＭ３金額
            ,lup.bm_container_type       bm_container_type       -- 販手容器区分
      FROM   xxcso_sp_decision_headers sdh -- ＳＰ専決ヘッダテーブル
            ,xxcso_sp_decision_lines   sdl -- ＳＰ専決明細テーブル
            ,(
               SELECT flv.lookup_code lookup_code
                     ,flv.attribute1  bm_container_type
               FROM   fnd_lookup_values_vl flv -- 参照コード
               WHERE  flv.lookup_type                            =  cv_lookup_type
               AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
               AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
               AND    flv.enabled_flag                           =  cv_flag_yes
             ) lup
      WHERE  sdh.sp_decision_header_id =  it_sp_decision_header_id
      AND    sdh.sp_decision_header_id =  sdl.sp_decision_header_id
      AND    sdl.sp_container_type     =  lup.lookup_code(+)
      ;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ================================
    -- 販手条件マスタ無効化
    -- ================================
    BEGIN
      UPDATE xxcok_mst_bm_contract xmb -- 販手条件マスタ
      SET    xmb.calc_target_flag       = cv_flag_no                -- 計算対象フラグ
            ,xmb.end_date_active        = cd_process_date           -- 有効日(To)
            ,xmb.last_update_date       = cd_last_update_date       -- 最終更新日
            ,xmb.last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,xmb.last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,xmb.request_id             = cn_request_id             -- リクエストＩＤ
            ,xmb.program_application_id = cn_program_application_id -- プログラムアプリケーションＩＤ
            ,xmb.program_id             = cn_program_id             -- プログラムＩＤ
            ,xmb.program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE xmb.cust_code                =  it_install_account_number -- 顧客コード
      AND   xmb.calc_target_flag         =  cv_flag_yes               -- 計算対象フラグ
      AND   TRUNC(xmb.start_date_active) <= TRUNC(cd_process_date)    -- 有効日(From)
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_mst_bm      -- トークン値1
                       ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    /* 2011.12.26 T.Ishiwata E_本稼動_08363 START */
    BEGIN
      SELECT SUM(( (NVL(sdl.bm1_bm_rate  ,cn_number_zero))
                 + (NVL(sdl.bm2_bm_rate  ,cn_number_zero))
                 + (NVL(sdl.bm3_bm_rate  ,cn_number_zero)))
                 + ( (NVL(sdl.bm1_bm_amount,cn_number_zero))
                 + (NVL(sdl.bm2_bm_amount,cn_number_zero))
                 + (NVL(sdl.bm3_bm_amount,cn_number_zero)))) bm_rate_amount  -- ＢＭ率・ＢＭ金額の合計値
      INTO   ln_bm_rate_amount
      FROM   xxcso_sp_decision_headers sdh                                   -- ＳＰ専決ヘッダテーブル
            ,xxcso_sp_decision_lines   sdl                                   -- ＳＰ専決明細テーブル
      WHERE  sdh.sp_decision_header_id =  sdl.sp_decision_header_id
      AND    sdh.sp_decision_header_id =  it_sp_decision_header_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --
        RAISE global_api_others_expt;
        --
    END;
    /* 2011.12.26 T.Ishiwata E_本稼動_08363 END   */
    --
    -- ================================
    -- ＳＰ専決情報取得
    -- ================================
    <<sp_decision_info_loop>>
    FOR lt_sp_decision_rec IN sp_decision_cur LOOP
      ln_sp_decision_count  := ln_sp_decision_count + cn_number_one;
      lt_electricity_type   := lt_sp_decision_rec.electricity_type;
      /* 2015.02.25 H.Wajima E_本稼動_12565 START */
      --lt_electricity_amount := lt_sp_decision_rec.electricity_amount;
      lt_electric_payment_type := lt_sp_decision_rec.electric_payment_type;
      lt_tax_type              := lt_sp_decision_rec.tax_type;
      -- 税区分が税抜きの場合、電気代＊消費税の計算を行う
      IF (lt_tax_type = cv_tax_type_2) THEN
        lt_electricity_amount  := TRUNC(lt_sp_decision_rec.electricity_amount * gt_tax_rate);
      ELSE
        lt_electricity_amount  := lt_sp_decision_rec.electricity_amount;
      END IF;
      /* 2015.02.25 H.Wajima E_本稼動_12565 END */
      --
      -- *** DEBUG_LOG START ***
      -- ＳＰ専決情報をログ出力
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg61 || CHR(10) ||
                   cv_debug_msg62 || lt_sp_decision_rec.condition_business_type || CHR(10) ||
                   cv_debug_msg63 || lt_sp_decision_rec.electricity_type        || CHR(10) ||
                   cv_debug_msg64 || lt_sp_decision_rec.electricity_amount      || CHR(10) ||
                   /* 2015.02.25 H.Wajima E_本稼動_12565 START */
                   cv_debug_msg87 || lt_sp_decision_rec.electric_payment_type   || CHR(10) ||
                   cv_debug_msg88 || lt_sp_decision_rec.tax_type                || CHR(10) ||
                   /* 2015.02.25 H.Wajima E_本稼動_12565 END */
                   cv_debug_msg65 || lt_sp_decision_rec.sp_container_type       || CHR(10) ||
                   cv_debug_msg66 || lt_sp_decision_rec.sales_price             || CHR(10) ||
                   cv_debug_msg67 || lt_sp_decision_rec.bm1_bm_rate             || CHR(10) ||
                   cv_debug_msg68 || lt_sp_decision_rec.bm1_bm_amount           || CHR(10) ||
                   cv_debug_msg69 || lt_sp_decision_rec.bm2_bm_rate             || CHR(10) ||
                   cv_debug_msg70 || lt_sp_decision_rec.bm2_bm_amount           || CHR(10) ||
                   cv_debug_msg71 || lt_sp_decision_rec.bm3_bm_rate             || CHR(10) ||
                   cv_debug_msg72 || lt_sp_decision_rec.bm3_bm_amount           || CHR(10) ||
                   cv_debug_msg73 || lt_sp_decision_rec.bm_container_type       || CHR(10) ||
                   cv_debug_msg75 || lt_sp_decision_rec.discount_amt            || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
    /* 2011.12.26 T.Ishiwata E_本稼動_08363 START */
--      IF (NVL(lt_sp_decision_rec.bm1_bm_rate, cn_number_zero) = cn_number_zero
--        AND NVL(lt_sp_decision_rec.bm1_bm_amount, cn_number_zero) = cn_number_zero
--        AND NVL(lt_sp_decision_rec.bm2_bm_rate, cn_number_zero) = cn_number_zero
--        AND NVL(lt_sp_decision_rec.bm2_bm_amount, cn_number_zero) = cn_number_zero
--        AND NVL(lt_sp_decision_rec.bm3_bm_rate, cn_number_zero) = cn_number_zero
--        AND NVL(lt_sp_decision_rec.bm3_bm_amount, cn_number_zero) = cn_number_zero)
      IF ( ln_bm_rate_amount = cn_number_zero )
    /* 2011.12.26 T.Ishiwata E_本稼動_08363 END   */
      THEN
        -- ＢＭ率１～３とＢＭ金額１～３の値が全て未入力又は、０の場合は販手条件の処理を行わない
        NULL;
        --
      ELSE
        IF ((lt_sp_decision_rec.condition_business_type IN (cv_cond_business_type_01, cv_cond_business_type_02))
          OR ((lt_sp_decision_rec.discount_amt IS NOT NULL)
          AND (lt_sp_decision_rec.condition_business_type IN (cv_cond_business_type_03, cv_cond_business_type_04))))
        THEN
          -- ======================================
          -- 販手条件マスタ存在チェック(取引条件別)
          -- ======================================
          BEGIN
            SELECT ROWID row_id
            INTO   ln_rowid
            FROM   xxcok_mst_bm_contract xmb -- 販手条件マスタ
            WHERE  xmb.cust_code = it_install_account_number -- 顧客コード
            AND    xmb.calc_type = DECODE(lt_sp_decision_rec.condition_business_type
                                         ,cv_cond_business_type_01, cv_calc_type_01
                                         ,cv_cond_business_type_02, cv_calc_type_01
                                         ,cv_cond_business_type_03, DECODE(NVL(lt_sp_decision_rec.sp_container_type, fnd_api.g_miss_char)
                                                                          ,cv_sp_container_type_all, cv_calc_type_03
                                                                          ,cv_calc_type_02)
                                         ,cv_cond_business_type_04, DECODE(NVL(lt_sp_decision_rec.sp_container_type, fnd_api.g_miss_char)
                                                                          ,cv_sp_container_type_all, cv_calc_type_03
                                                                          ,cv_calc_type_02)
                                         ) -- 計算条件
            AND    NVL(xmb.selling_price, fnd_api.g_miss_num)        = NVL(lt_sp_decision_rec.sales_price, fnd_api.g_miss_num) -- 売価
            AND    NVL(xmb.container_type_code, fnd_api.g_miss_char) = NVL(lt_sp_decision_rec.bm_container_type, fnd_api.g_miss_char) -- 容器区分
            AND    TRUNC(xmb.start_date_active)                      = TRUNC(cd_process_date)               -- 有効日(From)
            /* 2009.03.24 K.Satomura 障害番号T1_0140対応 START */
            --AND    xmb.calc_target_flag                              = cv_flag_yes                          -- 計算対象フラグ
            /* 2009.03.24 K.Satomura 障害番号T1_0140対応 END */
            ;
            --
            lv_no_data_found_flag := cv_flag_no;
            --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_no_data_found_flag := cv_flag_yes;
              --
          END;
          --
          IF (lv_no_data_found_flag = cv_flag_yes) THEN
            -- 販手条件マスタが存在しない場合
            -- ================================
            -- 販売手数料情報登録(取引条件別)
            -- ================================
            BEGIN
              INSERT INTO xxcok_mst_bm_contract(
                 bm_contract_id         -- 販手条件ＩＤ
                ,cust_code              -- 顧客コード
                ,calc_type              -- 計算条件
                ,container_type_code    -- 容器区分
                ,selling_price          -- 売価
                ,bm1_pct                -- BM1率(%)
                ,bm1_amt                -- BM1金額
                ,bm2_pct                -- BM2率(%)
                ,bm2_amt                -- BM2金額
                ,bm3_pct                -- BM3率(%)
                ,bm3_amt                -- BM3金額
                ,calc_target_flag       -- 計算対象フラグ
                ,start_date_active      -- 有効日(From)
                ,created_by             -- 作成者
                ,creation_date          -- 作成日
                ,last_updated_by        -- 最終更新者
                ,last_update_date       -- 最終更新日
                ,last_update_login      -- 最終更新ログイン
                ,request_id             -- 要求ID
                ,program_application_id -- コンカレント・プログラム・アプリケーションID
                ,program_id             -- コンカレント・プログラムID
                ,program_update_date)   -- プログラム更新日
              VALUES(
                 xxcok_mst_bm_contract_s01.NEXTVAL -- 販手条件ＩＤ
                ,it_install_account_number         -- 顧客コード
                ,DECODE(lt_sp_decision_rec.condition_business_type
                       ,cv_cond_business_type_01, cv_calc_type_01
                       ,cv_cond_business_type_02, cv_calc_type_01
                       ,cv_cond_business_type_03, DECODE(lt_sp_decision_rec.sp_container_type
                                                        ,cv_sp_container_type_all, cv_calc_type_03
                                                        ,cv_calc_type_02)
                       ,cv_cond_business_type_04, DECODE(lt_sp_decision_rec.sp_container_type
                                                        ,cv_sp_container_type_all, cv_calc_type_03
                                                        ,cv_calc_type_02)
                       ) -- 計算条件
                ,DECODE(lt_sp_decision_rec.condition_business_type
                       ,cv_cond_business_type_03, lt_sp_decision_rec.bm_container_type
                       ,cv_cond_business_type_04, lt_sp_decision_rec.bm_container_type
                       ,NULL
                       ) -- 容器区分
                ,DECODE(lt_sp_decision_rec.condition_business_type
                       ,cv_cond_business_type_01, lt_sp_decision_rec.sales_price
                       ,cv_cond_business_type_02, lt_sp_decision_rec.sales_price
                       ,NULL
                       ) -- 売価
                /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 START */
                --,lt_sp_decision_rec.bm1_bm_rate   -- BM1率(%)
                --,lt_sp_decision_rec.bm1_bm_amount -- BM1金額
                --,lt_sp_decision_rec.bm2_bm_rate   -- BM2率(%)
                --,lt_sp_decision_rec.bm2_bm_amount -- BM2金額
                --,lt_sp_decision_rec.bm3_bm_rate   -- BM3率(%)
                --,lt_sp_decision_rec.bm3_bm_amount -- BM3金額
                ,DECODE(lt_sp_decision_rec.bm1_bm_rate
                       ,cn_zero, NULL
                       ,lt_sp_decision_rec.bm1_bm_rate
                       ) -- BM1率(%)
                ,DECODE(lt_sp_decision_rec.bm1_bm_amount
                       ,cn_zero, NULL
                       ,lt_sp_decision_rec.bm1_bm_amount
                       ) -- BM1金額
                ,DECODE(lt_sp_decision_rec.bm2_bm_rate
                       ,cn_zero, NULL
                       ,lt_sp_decision_rec.bm2_bm_rate
                       ) -- BM2率(%)
                ,DECODE(lt_sp_decision_rec.bm2_bm_amount
                       ,cn_zero, NULL
                       ,lt_sp_decision_rec.bm2_bm_amount
                       ) -- BM2金額
                ,DECODE(lt_sp_decision_rec.bm3_bm_rate
                       ,cn_zero, NULL
                       ,lt_sp_decision_rec.bm3_bm_rate
                       ) -- BM3率(%)
                ,DECODE(lt_sp_decision_rec.bm3_bm_amount
                       ,cn_zero, NULL
                       ,lt_sp_decision_rec.bm3_bm_amount
                       ) -- BM3金額
                /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 END */
                ,cv_flag_yes                      -- 計算対象フラグ
                ,cd_process_date                  -- 有効日(From)
                ,cn_created_by                    -- 作成者
                ,cd_creation_date                 -- 作成日
                ,cn_last_updated_by               -- 最終更新者
                ,cd_last_update_date              -- 最終更新日
                ,cn_last_update_login             -- 最終更新ログイン
                ,cn_request_id                    -- 要求ID
                ,cn_program_application_id        -- コンカレント・プログラム・アプリケーションID
                ,cn_program_id                    -- コンカレント・プログラムID
                ,cd_program_update_date           -- プログラム更新日
              );
              --
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_06         -- メッセージコード
                               ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                               ,iv_token_value1 => cv_tkn_value_mst_bm      -- トークン値1
                               ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                               ,iv_token_value2 => SQLERRM                  -- トークン値2
                            );
                --
                RAISE global_api_expt;
                --
            END;
            --
          ELSE
            -- 販手条件マスタが存在した場合
            -- ================================
            -- 販売手数料情報更新(取引条件別)
            -- ================================
            BEGIN
              UPDATE xxcok_mst_bm_contract xmb -- 販手条件マスタ
              /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 START */
              --SET    xmb.bm1_pct                = lt_sp_decision_rec.bm1_bm_rate   -- BM1率(%)
              --      ,xmb.bm1_amt                = lt_sp_decision_rec.bm1_bm_amount -- BM1金額
              --      ,xmb.bm2_pct                = lt_sp_decision_rec.bm2_bm_rate   -- BM2率(%)
              --      ,xmb.bm2_amt                = lt_sp_decision_rec.bm2_bm_amount -- BM2金額
              --      ,xmb.bm3_pct                = lt_sp_decision_rec.bm3_bm_rate   -- BM3率(%)
              --      ,xmb.bm3_amt                = lt_sp_decision_rec.bm3_bm_amount -- BM3金額
              SET    xmb.bm1_pct                = DECODE(lt_sp_decision_rec.bm1_bm_rate
                                                        ,cn_zero, NULL
                                                        ,lt_sp_decision_rec.bm1_bm_rate
                                                        ) -- BM1率(%)
                    ,xmb.bm1_amt                = DECODE(lt_sp_decision_rec.bm1_bm_amount
                                                        ,cn_zero, NULL
                                                        ,lt_sp_decision_rec.bm1_bm_amount
                                                        ) -- BM1金額
                    ,xmb.bm2_pct                = DECODE(lt_sp_decision_rec.bm2_bm_rate
                                                        ,cn_zero, NULL
                                                        ,lt_sp_decision_rec.bm2_bm_rate
                                                        ) -- BM2率(%)
                    ,xmb.bm2_amt                = DECODE(lt_sp_decision_rec.bm2_bm_amount
                                                        ,cn_zero, NULL
                                                        ,lt_sp_decision_rec.bm2_bm_amount
                                                        ) -- BM2金額
                    ,xmb.bm3_pct                = DECODE(lt_sp_decision_rec.bm3_bm_rate
                                                        ,cn_zero, NULL
                                                        ,lt_sp_decision_rec.bm3_bm_rate
                                                        ) -- BM3率(%)
                    ,xmb.bm3_amt                = DECODE(lt_sp_decision_rec.bm3_bm_amount
                                                        ,cn_zero, NULL
                                                        ,lt_sp_decision_rec.bm3_bm_amount
                                                        ) -- BM3金額
                    ,xmb.end_date_active        = NULL    -- 有効日(To)
              /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 END */
                    ,xmb.calc_target_flag       = cv_flag_yes                      -- 計算対象フラグ
                    ,xmb.last_updated_by        = cn_last_updated_by               -- 最終更新者
                    ,xmb.last_update_date       = cd_last_update_date              -- 最終更新日
                    ,xmb.last_update_login      = cn_last_update_login             -- 最終更新ログイン
                    ,xmb.request_id             = cn_request_id                    -- 要求ID
                    ,xmb.program_application_id = cn_program_application_id        -- コンカレント・プログラム・アプリケーションID
                    ,xmb.program_id             = cn_program_id                    -- コンカレント・プログラムID
                    ,xmb.program_update_date    = cd_program_update_date           -- プログラム更新日
              WHERE  ROWID = ln_rowid
              ;
              --
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_02         -- メッセージコード
                               ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                               ,iv_token_value1 => cv_tkn_value_mst_bm      -- トークン値1
                               ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                               ,iv_token_value2 => SQLERRM                  -- トークン値2
                            );
                --
                RAISE global_api_expt;
                --
            END;
            --
          END IF;
          --
        END IF;
        --
      END IF;
      --
      lt_sp_decision_rec := NULL;
      --
    END LOOP sp_decision_info_loop;
    --
    IF (ln_sp_decision_count <= cn_number_zero) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_05         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_sp_info     -- トークン値1
                     ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                     ,iv_token_value2 => cv_tkn_value_sp_id       -- トークン値2
                     ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                     ,iv_token_value3 => it_sp_decision_header_id -- トークン値3
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ========================================
    -- 販手条件マスタ存在チェック(電気代区分別)
    -- ========================================
    /* 2015.02.25 H.Wajima E_本稼動_12565 START */
    --IF (lt_electricity_type =  cv_electricity_type_1) THEN
    --  -- 電気代区分が1(定額)の場合
    -- 電気代区分が1（定額） かつ、 支払条件（電気代）が1（契約先）の場合
    IF (lt_electricity_type =  cv_electricity_type_1) 
      AND (lt_electric_payment_type = cv_electric_pay_type_1) THEN
    /* 2015.02.25 H.Wajima E_本稼動_12565 END */
      BEGIN
        SELECT ROWID row_id
        INTO   ln_rowid
        FROM   xxcok_mst_bm_contract xmb -- 販手条件マスタ
        WHERE  xmb.cust_code                = it_install_account_number -- 顧客コード
        AND    xmb.calc_type                = cv_calc_type_04           -- 計算条件
        AND    TRUNC(xmb.start_date_active) = TRUNC(cd_process_date)    -- 有効日(From)
        /* 2009.03.24 K.Satomura 障害番号T1_0140対応 START */
        --AND    xmb.calc_target_flag         = cv_flag_yes               -- 計算対象フラグ
        /* 2009.04.27 K.Satomura 障害番号T1_0766対応 START */
        --AND    xmb.calc_target_flag         = cv_flag_yes               -- 計算対象フラグ
        /* 2009.04.27 K.Satomura 障害番号T1_0766対応 START */
        /* 2009.03.24 K.Satomura 障害番号T1_0140対応 END */
        ;
        --
        lv_no_data_found_flag := cv_flag_no;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_no_data_found_flag := cv_flag_yes;
          --
      END;
      --
      IF (lv_no_data_found_flag = cv_flag_yes) THEN
        -- 販手条件マスタが存在しない場合
        -- ================================
        -- 販売手数料情報登録(電気代区分別)
        -- ================================
        BEGIN
          INSERT INTO xxcok_mst_bm_contract(
             bm_contract_id         -- 販手条件ＩＤ
            ,cust_code              -- 顧客コード
            ,calc_type              -- 計算条件
            ,bm1_amt                -- BM1金額
            ,calc_target_flag       -- 計算対象フラグ
            ,start_date_active      -- 有効日(From)
            ,created_by             -- 作成者
            ,creation_date          -- 作成日
            ,last_updated_by        -- 最終更新者
            ,last_update_date       -- 最終更新日
            ,last_update_login      -- 最終更新ログイン
            ,request_id             -- 要求ID
            ,program_application_id -- コンカレント・プログラム・アプリケーションID
            ,program_id             -- コンカレント・プログラムID
            ,program_update_date)   -- プログラム更新日
          VALUES(
             xxcok_mst_bm_contract_s01.NEXTVAL -- 販手条件ＩＤ
            ,it_install_account_number         -- 顧客コード
            ,cv_calc_type_04                   -- 計算条件
            ,lt_electricity_amount             -- BM1金額
            ,cv_flag_yes                       -- 計算対象フラグ
            ,cd_process_date                   -- 有効日(From)
            ,cn_created_by                     -- 作成者
            ,cd_creation_date                  -- 作成日
            ,cn_last_updated_by                -- 最終更新者
            ,cd_last_update_date               -- 最終更新日
            ,cn_last_update_login              -- 最終更新ログイン
            ,cn_request_id                     -- 要求ID
            ,cn_program_application_id         -- コンカレント・プログラム・アプリケーションID
            ,cn_program_id                     -- コンカレント・プログラムID
            ,cd_program_update_date            -- プログラム更新日
          );
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_06         -- メッセージコード
                           ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                           ,iv_token_value1 => cv_tkn_value_mst_bm      -- トークン値1
                           ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                           ,iv_token_value2 => SQLERRM                  -- トークン値2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      ELSE
        -- 販手条件マスタが存在した場合
        -- ================================
        -- 販売手数料情報更新(電気代区分別)
        -- ================================
        BEGIN
          UPDATE xxcok_mst_bm_contract xmb -- 販手条件マスタ
          SET    xmb.bm1_amt                = lt_electricity_amount     -- BM1金額
                /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 START */
                ,xmb.end_date_active        = NULL                      -- 有効日(To)
                /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 END */
                ,xmb.calc_target_flag       = cv_flag_yes               -- 計算対象フラグ
                ,xmb.last_updated_by        = cn_last_updated_by        -- 最終更新者
                ,xmb.last_update_date       = cd_last_update_date       -- 最終更新日
                ,xmb.last_update_login      = cn_last_update_login      -- 最終更新ログイン
                ,xmb.request_id             = cn_request_id             -- 要求ID
                ,xmb.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
                ,xmb.program_id             = cn_program_id             -- コンカレント・プログラムID
                ,xmb.program_update_date    = cd_program_update_date    -- プログラム更新日
          WHERE  ROWID = ln_rowid
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_02         -- メッセージコード
                           ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                           ,iv_token_value1 => cv_tkn_value_mst_bm      -- トークン値1
                           ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                           ,iv_token_value2 => SQLERRM                  -- トークン値2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END reg_backmargin;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_install_at
   * Description      : 設置先顧客情報更新処理(A-11)
   ***********************************************************************************/
  PROCEDURE upd_install_at(
     it_mst_regist_info_rec IN  g_mst_regist_info_rtype         -- マスタ登録情報
    ,ot_party_id            OUT NOCOPY hz_parties.party_id%TYPE -- パーティＩＤ
    ,ov_errbuf              OUT NOCOPY VARCHAR2                 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                 -- リターン・コード             --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_install_at'; -- プログラム名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_territory_code        CONSTANT VARCHAR2(2) := 'JP'; -- 国コード
    /* 2009.03.24 K.Satomura 障害番号T1_0135対応 START */
    cv_business_low_type     CONSTANT xxcmm_cust_accounts.business_low_type%TYPE := '24';
    /* 2009.03.24 K.Satomura 障害番号T1_0135対応 END */
    cv_vendor_contact_code1  CONSTANT VARCHAR2(8) := 'FLVDDMY1';
    cv_vendor_contact_code2  CONSTANT VARCHAR2(8) := 'FLVDDMY2';
    cv_vendor_contact_code3  CONSTANT VARCHAR2(8) := 'FLVDDMY3';
    --
    -- トークン用定数
    cv_tkn_value_cust_acct       CONSTANT VARCHAR2(50) := '設置先顧客情報更新処理時：顧客マスタ';
    cv_tkn_value_location        CONSTANT VARCHAR2(50) := '設置先顧客情報更新処理時：顧客事業所マスタ';
    cv_tkn_value_cust_acct_id    CONSTANT VARCHAR2(50) := '顧客ＩＤ';
    cv_tkn_value_account_update  CONSTANT VARCHAR2(50) := '顧客マスタ更新';
    cv_tkn_value_location_update CONSTANT VARCHAR2(50) := '顧客事業所マスタ更新';
    cv_tkn_value_cust_addon      CONSTANT VARCHAR2(50) := 'アカウントアドオンマスタ更新';
    cv_tkn_value_party           CONSTANT VARCHAR2(50) := '設置先顧客情報更新処理時：パーティマスタ';
    cv_tkn_value_party_id        CONSTANT VARCHAR2(50) := 'パーティＩＤ';
    cv_tkn_value_party_update    CONSTANT VARCHAR2(50) := 'パーティマスタ更新';
    --
    -- *** ローカル変数 ***
    ln_object_version_number NUMBER;
    lt_cust_account_rec      hz_cust_account_v2pub.cust_account_rec_type;
    lt_location_rec          hz_location_v2pub.location_rec_type;
    lt_location_id           hz_locations.location_id%TYPE;
    lt_party_id              hz_party_sites.party_id%TYPE;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    lt_vendor_number1        po_vendors.segment1%TYPE;
    lt_vendor_number2        po_vendors.segment1%TYPE;
    lt_vendor_number3        po_vendors.segment1%TYPE;
    lt_organization_rec      hz_party_v2pub.organization_rec_type;
    lt_profile_id            hz_organization_profiles.organization_profile_id%TYPE;
    /* 2013.04.11 K.Nakamura E_本稼動_09603 START */
    lt_duns_number_c         hz_parties.duns_number_c%TYPE;
    /* 2013.04.11 K.Nakamura E_本稼動_09603 END */
    --
    -- 顧客マスタ用ＡＰＩ変数
    --
    -- *** ローカル・カーソル ***
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ====================================
    -- 顧客マスタ情報取得
    -- ====================================
    BEGIN
      SELECT hca.object_version_number -- オブジェクトバージョン番号
      INTO   ln_object_version_number
      FROM   hz_cust_accounts hca -- 顧客マスタ
      WHERE  hca.cust_account_id = it_mst_regist_info_rec.install_account_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05                          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_cust_acct                    -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                           -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_cust_acct_id                 -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                             -- トークンコード3
                       ,iv_token_value3 => it_mst_regist_info_rec.install_account_id -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ====================================
    -- 顧客マスタ更新
    -- ====================================
    lt_cust_account_rec.cust_account_id := it_mst_regist_info_rec.install_account_id;                  -- 顧客ＩＤ
    lt_cust_account_rec.account_name    := SUBSTRB(it_mst_regist_info_rec.install_party_name, 1, 240); -- 顧客名
    --
    hz_cust_account_v2pub.update_cust_account(
       p_init_msg_list         => fnd_api.g_true
      ,p_cust_account_rec      => lt_cust_account_rec
      ,p_object_version_number => ln_object_version_number
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
    --
    IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
      -- リターンコードがS以外の場合
      IF (ln_msg_count > cn_number_one) THEN
        lv_msg_data := fnd_msg_pub.get(
                          p_msg_index => cn_number_one
                         ,p_encoded   => fnd_api.g_true
                       );
        --
      END IF;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_api_name             -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_account_update -- トークン値1
                     ,iv_token_name2  => cv_tkn_api_msg              -- トークンコード2
                     ,iv_token_value2 => lv_msg_data                 -- トークン値2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ====================================
    -- 顧客事業所マスタ情報取得
    -- ====================================
    BEGIN
      SELECT hlo.location_id           -- 顧客事業所ＩＤ
            ,hlo.object_version_number -- オブジェクトバージョン番号
            ,hps.party_id              -- パーティＩＤ
      INTO   lt_location_id
            ,ln_object_version_number
            ,lt_party_id
      FROM   hz_locations     hlo -- 顧客事業所マスタ
            ,hz_party_sites   hps -- パーティサイトマスタ
            /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 START */
            ,hz_cust_acct_sites hcas -- 顧客サイトマスタ
            /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 END */
            ,hz_cust_accounts hca -- 顧客マスタ
      WHERE  hca.cust_account_id = it_mst_regist_info_rec.install_account_id
      AND    hca.party_id        = hps.party_id
      /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 START */
      AND    hcas.party_site_id   = hps.party_site_id
      AND    hcas.cust_account_id = hca.cust_account_id
      /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 END */
      AND    hps.location_id     = hlo.location_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05                          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_location                     -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                           -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_cust_acct_id                 -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                             -- トークンコード3
                       ,iv_token_value3 => it_mst_regist_info_rec.install_account_id -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ====================================
    -- 顧客事業所マスタ更新
    -- ====================================
    lt_location_rec.location_id            := lt_location_id;                                             -- 顧客事業所ＩＤ
    lt_location_rec.country                := cv_territory_code;                                          -- 国コード
    lt_location_rec.postal_code            := SUBSTRB(it_mst_regist_info_rec.install_postal_code, 1, 60); -- 郵便番号
    lt_location_rec.state                  := SUBSTRB(it_mst_regist_info_rec.install_state, 1, 60);       -- 都道府県
    lt_location_rec.city                   := SUBSTRB(it_mst_regist_info_rec.install_city, 1, 60);        -- 市・区
    lt_location_rec.address1               := SUBSTRB(it_mst_regist_info_rec.install_address1, 1, 240);   -- 住所１
    lt_location_rec.address2               := SUBSTRB(it_mst_regist_info_rec.install_address2, 1, 240);   -- 住所２
    --
    hz_location_v2pub.update_location(
       p_init_msg_list         => fnd_api.g_true
      ,p_location_rec          => lt_location_rec
      ,p_object_version_number => ln_object_version_number
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
    --
    IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
      -- リターンコードがS以外の場合
      IF (ln_msg_count > 1) THEN
        lv_msg_data := fnd_msg_pub.get(
                          p_msg_index => cn_number_one
                         ,p_encoded   => fnd_api.g_true
                       );
        --
      END IF;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name     -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_api_name              -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_location_update -- トークン値1
                     ,iv_token_name2  => cv_tkn_api_msg               -- トークンコード2
                     ,iv_token_value2 => lv_msg_data                  -- トークン値2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ====================================
    -- 仕入先番号取得
    -- ====================================
    BEGIN
      SELECT pve.segment1 -- 仕入先番号
      INTO   lt_vendor_number1 -- 仕入先番号１
      FROM   xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
            ,po_vendors              pve -- 仕入先マスタ
      WHERE  xsd.sp_decision_header_id      = it_mst_regist_info_rec.sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_bm1
      AND    xsd.customer_id                = pve.vendor_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        /* 2009.03.24 K.Satomura 障害番号T1_0135対応 START */
        --lt_vendor_number1 := cv_vendor_contact_code1;
        lt_vendor_number1 := NULL;
        /* 2009.03.24 K.Satomura 障害番号T1_0135対応 END */
        --
    END;
    --
    BEGIN
      SELECT pve.segment1 -- 仕入先番号
      INTO   lt_vendor_number2 -- 仕入先番号２
      FROM   xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
            ,po_vendors              pve -- 仕入先マスタ
      WHERE  xsd.sp_decision_header_id      = it_mst_regist_info_rec.sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_bm2
      AND    xsd.customer_id                = pve.vendor_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        /* 2009.03.24 K.Satomura 障害番号T1_0135対応 START */
        --lt_vendor_number2 := cv_vendor_contact_code2;
        lt_vendor_number2 := NULL;
        /* 2009.03.24 K.Satomura 障害番号T1_0135対応 END */
        --
    END;
    --
    BEGIN
      SELECT pve.segment1 -- 仕入先番号
      INTO   lt_vendor_number3 -- 仕入先番号３
      FROM   xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
            ,po_vendors              pve -- 仕入先マスタ
      WHERE  xsd.sp_decision_header_id      = it_mst_regist_info_rec.sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_bm3
      AND    xsd.customer_id                = pve.vendor_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        /* 2009.03.24 K.Satomura 障害番号T1_0135対応 START */
        --lt_vendor_number3 := cv_vendor_contact_code3;
        lt_vendor_number3 := NULL;
        /* 2009.03.24 K.Satomura 障害番号T1_0135対応 END */
        --
    END;
    --
    -- ====================================
    -- 顧客アドオンマスタ更新
    -- ====================================
    BEGIN
      UPDATE xxcmm_cust_accounts xca -- 顧客アドオンマスタ
      /* 2009.04.08 K.Satomura 障害番号T1_0287対応 START */
      --SET    xca.contractor_supplier_code = DECODE(xca.business_low_type
      --                                            /* 2009.03.24 K.Satomura 障害番号T1_0135対応 START */
      --                                            --,cv_business_low_type, lt_vendor_number1
      --                                            --,cv_vendor_contact_code1) -- 契約者仕入先コード
      --                                            ,cv_business_low_type, cv_vendor_contact_code1
      --                                            ,lt_vendor_number1) -- 契約者仕入先コード
      --                                            /* 2009.03.24 K.Satomura 障害番号T1_0135対応 END */
      --      ,xca.bm_pay_supplier_code1    = DECODE(xca.business_low_type
      --                                            /* 2009.03.24 K.Satomura 障害番号T1_0135対応 START */
      --                                            --,cv_business_low_type, lt_vendor_number2
      --                                            --,cv_vendor_contact_code2) -- 紹介者BM支払仕入先コード１
      --                                            ,cv_business_low_type, cv_vendor_contact_code2
      --                                            ,lt_vendor_number2) -- 紹介者BM支払仕入先コード１
      --                                            /* 2009.03.24 K.Satomura 障害番号T1_0135対応 END */
      --      ,xca.bm_pay_supplier_code2    = DECODE(xca.business_low_type
      --                                            /* 2009.03.24 K.Satomura 障害番号T1_0135対応 START */
      --                                            --,cv_business_low_type, lt_vendor_number3
      --                                            --,cv_vendor_contact_code3) -- 紹介者BM支払仕入先コード２
      --                                            ,cv_business_low_type, cv_vendor_contact_code3
      --                                            ,lt_vendor_number3) -- 紹介者BM支払仕入先コード２
      --                                            /* 2009.03.24 K.Satomura 障害番号T1_0135対応 END */
      SET    xca.contractor_supplier_code = DECODE(xca.business_low_type
                                                  ,cv_business_low_type,
                                                    CASE
                                                      WHEN (
                                                        SELECT SUM(NVL(sdl.bm1_bm_rate,0)) + SUM(NVL(sdl.bm1_bm_amount,0))
                                                        FROM   xxcso_sp_decision_lines sdl
                                                        WHERE  sdl.sp_decision_header_id = it_mst_regist_info_rec.sp_decision_header_id
                                                      ) <= cn_number_zero THEN
                                                        NULL
                                                      ELSE
                                                        cv_vendor_contact_code1
                                                    END
                                                  ,lt_vendor_number1) -- 契約者仕入先コード
            ,xca.bm_pay_supplier_code1    = DECODE(xca.business_low_type
                                                  ,cv_business_low_type,
                                                    CASE
                                                      WHEN (
                                                        SELECT SUM(NVL(sdl.bm2_bm_rate,0)) + SUM(NVL(sdl.bm2_bm_amount,0))
                                                        FROM   xxcso_sp_decision_lines sdl
                                                        WHERE  sdl.sp_decision_header_id = it_mst_regist_info_rec.sp_decision_header_id
                                                      ) <= cn_number_zero THEN
                                                        NULL
                                                      ELSE
                                                        cv_vendor_contact_code2
                                                    END
                                                  ,lt_vendor_number2) -- 紹介者BM支払仕入先コード１
            ,xca.bm_pay_supplier_code2    = DECODE(xca.business_low_type
                                                  ,cv_business_low_type,
                                                    CASE
                                                      WHEN (
                                                        SELECT SUM(NVL(sdl.bm3_bm_rate,0)) + SUM(NVL(sdl.bm3_bm_amount,0))
                                                        FROM   xxcso_sp_decision_lines sdl
                                                        WHERE  sdl.sp_decision_header_id = it_mst_regist_info_rec.sp_decision_header_id
                                                      ) <= cn_number_zero THEN
                                                        NULL
                                                      ELSE
                                                        cv_vendor_contact_code3
                                                    END
                                                  ,lt_vendor_number3) -- 紹介者BM支払仕入先コード２
      /* 2009.04.08 K.Satomura 障害番号T1_0287対応 END */
            /* 2009.04.28 K.Satomura 障害番号T1_0733対応 START */
            /* 2009.05.15 K.Satomura 障害番号T1_1010対応 START */
            --,xca.cnvs_date                = cd_process_date           -- 顧客獲得日
            /* 2009.12.18 D.Abe E_本稼動_00536対応 START */
            --,xca.cnvs_date                = DECODE(it_mst_regist_info_rec.install_code
            --                                      ,NULL, xca.cnvs_date
            --                                      ,cd_process_date)   -- 顧客獲得日
            ,xca.cnvs_date                = DECODE(it_mst_regist_info_rec.install_code
                                                               ,NULL,xca.cnvs_date
                                                               ,DECODE(xca.cnvs_date,NULL,it_mst_regist_info_rec.install_date
                                                                                    ,xca.cnvs_date
                                                                      )
                                                  ) -- 顧客獲得日
            /* 2009.12.18 D.Abe E_本稼動_00536対応 END */
            /* 2009.05.15 K.Satomura 障害番号T1_1010対応 END */
            /* 2009.04.28 K.Satomura 障害番号T1_0733対応 END */
            ,xca.last_update_date         = cd_last_update_date       -- 最終更新日
            ,xca.last_updated_by          = cn_last_updated_by        -- 最終更新者
            ,xca.last_update_login        = cn_last_update_login      -- 最終更新ログイン
            ,xca.request_id               = cn_request_id             -- リクエストＩＤ
            ,xca.program_application_id   = cn_program_application_id -- プログラムアプリケーションＩＤ
            ,xca.program_id               = cn_program_id             -- プログラムＩＤ
            ,xca.program_update_date      = cd_program_update_date    -- プログラム更新日
      WHERE  xca.customer_id = it_mst_regist_info_rec.install_account_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_cust_addon  -- トークン値1
                       ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ====================================
    -- パーティマスタ情報取得
    -- ====================================
    BEGIN
      SELECT hpa.object_version_number -- オブジェクトバージョン番号
            /* 2013.04.11 K.Nakamura E_本稼動_09603 START */
            ,hpa.duns_number_c duns_number_c -- 顧客ステータス
            /* 2013.04.11 K.Nakamura E_本稼動_09603 END */
      INTO   ln_object_version_number
            /* 2013.04.11 K.Nakamura E_本稼動_09603 START */
            ,lt_duns_number_c
            /* 2013.04.11 K.Nakamura E_本稼動_09603 END */
      FROM   hz_parties hpa -- パーティマスタ
      WHERE  hpa.party_id = lt_party_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_party       -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_party_id    -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => lt_party_id              -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ====================================
    -- パーティマスタ更新
    -- ====================================
    lt_organization_rec.organization_name  := SUBSTRB(it_mst_regist_info_rec.install_party_name, 1, 360); -- 顧客名
    lt_organization_rec.party_rec.party_id := lt_party_id;                                                -- パーティＩＤ
    /* 2013.04.11 K.Nakamura E_本稼動_09603 START */
    -- 顧客ステータスが25(SP承認済)より前の場合
    IF ( lt_duns_number_c < cv_duns_number_approved ) THEN
      lt_organization_rec.duns_number_c    := cv_duns_number_approved; -- 顧客ステータス：25(SP承認済)に変更
    END IF;
    /* 2013.04.11 K.Nakamura E_本稼動_09603 END */
    --
    hz_party_v2pub.update_organization(
       p_init_msg_list               => fnd_api.g_true
      ,p_organization_rec            => lt_organization_rec
      ,p_party_object_version_number => ln_object_version_number
      ,x_profile_id                  => lt_profile_id
      ,x_return_status               => lv_return_status
      ,x_msg_count                   => ln_msg_count
      ,x_msg_data                    => lv_msg_data
    );
    --
    IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
      -- リターンコードがS以外の場合
      IF (ln_msg_count > 1) THEN
        lv_msg_data := fnd_msg_pub.get(
                          p_msg_index => cn_number_one
                         ,p_encoded   => fnd_api.g_true
                       );
        --
      END IF;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_api_name           -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_party_update -- トークン値1
                     ,iv_token_name2  => cv_tkn_api_msg            -- トークンコード2
                     ,iv_token_value2 => lv_msg_data               -- トークン値2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    ot_party_id := lt_party_id;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END upd_install_at;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_install_base
   * Description      : 物件情報更新処理(A-12)
   ***********************************************************************************/
  PROCEDURE upd_install_base(
     it_mst_regist_info_rec IN         g_mst_regist_info_rtype  -- マスタ登録情報
    ,it_party_id            IN         hz_parties.party_id%TYPE -- パーティＩＤ
    ,ov_errbuf              OUT NOCOPY VARCHAR2                 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                 -- リターン・コード             --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_install_base'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_api_version            CONSTANT NUMBER        := 1.0;
    cv_party_source_table     CONSTANT VARCHAR2(100) := 'HZ_PARTIES';
    cv_relationship_type_code CONSTANT VARCHAR2(100) := 'OWNER';
    cv_src_tran_type          CONSTANT VARCHAR2(5)   := 'IB_UI';
    cv_location_type_code     CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';
    --
    -- トークン用定数
    cv_tkn_value_task_name         CONSTANT VARCHAR2(50) := '取引タイプの取引タイプID';
    cv_tkn_value_install_base      CONSTANT VARCHAR2(50) := '物件情報更新処理時：インストールベースマスタ';
    cv_tkn_value_install_code      CONSTANT VARCHAR2(50) := '物件コード';
    cv_tkn_value_instance_party    CONSTANT VARCHAR2(50) := '物件情報更新処理時：インスタンスパーティマスタ';
    cv_tkn_value_instance_id       CONSTANT VARCHAR2(50) := 'インスタンスＩＤ';
    cv_tkn_value_instance_acct     CONSTANT VARCHAR2(50) := '物件情報更新処理時：インスタンスアカウントマスタ';
    cv_tkn_value_instance_party_id CONSTANT VARCHAR2(50) := 'インスタンスパーティＩＤ';
    cv_tkn_value_party_site        CONSTANT VARCHAR2(50) := '物件情報更新処理時：パーティサイトマスタ';
    cv_tkn_value_party_id          CONSTANT VARCHAR2(50) := 'パーティＩＤ';
    cv_tkn_value_ib_update         CONSTANT VARCHAR2(50) := 'インストールベースマスタ更新';
    --
    -- *** ローカル変数 ***
    lt_instance_id                csi_item_instances.instance_id%TYPE;
    ln_instance_object_vnum       csi_item_instances.object_version_number%TYPE;
    lt_instance_party_id          csi_i_parties.instance_party_id%TYPE;
    ln_instance_party_object_vnum csi_i_parties.object_version_number%TYPE;
    lt_ip_account_id              csi_ip_accounts.ip_account_id%TYPE;
    ln_instance_acct_object_vnum  csi_ip_accounts.object_version_number%TYPE;
    lt_transaction_type_id        csi_txn_types.transaction_type_id%TYPE;
    lt_party_site_id              hz_party_sites.party_site_id%TYPE;
    --
    -- 物件情報更新用ＡＰＩ
    lt_instance_rec          csi_datastructures_pub.instance_rec;
    lt_ext_attrib_values_tbl csi_datastructures_pub.extend_attrib_values_tbl;
    lt_party_tbl             csi_datastructures_pub.party_tbl;
    lt_account_tbl           csi_datastructures_pub.party_account_tbl;
    lt_pricing_attrib_tbl    csi_datastructures_pub.pricing_attribs_tbl;
    lt_org_assignments_tbl   csi_datastructures_pub.organization_units_tbl;
    lt_asset_assignment_tbl  csi_datastructures_pub.instance_asset_tbl;
    lt_txn_rec               csi_datastructures_pub.transaction_rec;
    lt_instance_id_lst       csi_datastructures_pub.id_tbl;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ================================================
    -- インスタンス情報取得
    -- ================================================
    BEGIN
      SELECT cii.instance_id           -- インスタンスＩＤ
            ,cii.object_version_number -- オブジェクトバージョン番号
      INTO   lt_instance_id
            ,ln_instance_object_vnum
      FROM   csi_item_instances cii -- インストールベースマスタ
      WHERE  cii.external_reference = it_mst_regist_info_rec.install_code
      AND    cii.attribute4         = cv_flag_no
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05                    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                       -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_install_base           -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                     -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_install_code           -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                       -- トークンコード3
                       ,iv_token_value3 => it_mst_regist_info_rec.install_code -- トークン値3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- インスタンスパーティ情報取得
    -- ================================================
    BEGIN
      SELECT cip.instance_party_id     -- インスタンスパーティＩＤ
            ,cip.object_version_number -- オブジェクトバージョン番号
      INTO   lt_instance_party_id
            ,ln_instance_party_object_vnum
      FROM   csi_i_parties cip -- インスタンスパーティマスタ
      WHERE  cip.instance_id = lt_instance_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action               -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_instance_party -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name             -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_instance_id    -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id               -- トークンコード3
                       ,iv_token_value3 => lt_instance_id              -- トークン値3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- インスタンスアカウント情報取得
    -- ================================================
    BEGIN
      SELECT cia.ip_account_id         -- インスタンスアカウントＩＤ
            ,cia.object_version_number -- オブジェクトバージョン番号
      INTO   lt_ip_account_id
            ,ln_instance_acct_object_vnum
      FROM   csi_ip_accounts cia -- インスタンスアカウントマスタ
      WHERE  cia.instance_party_id = lt_instance_party_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name       -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action                  -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_instance_acct     -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name                -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_instance_party_id -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id                  -- トークンコード3
                       ,iv_token_value3 => lt_instance_party_id           -- トークン値3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- パーティサイトＩＤ取得
    -- ================================================
    BEGIN
      SELECT hps.party_site_id -- パーティサイトＩＤ
      INTO   lt_party_site_id
      FROM   hz_party_sites hps -- パーティサイトマスタ
      /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 START */
            ,hz_cust_accounts   hca  -- 顧客マスタ
            ,hz_cust_acct_sites hcas -- 顧客サイトマスタ
      --WHERE  hps.party_id = it_party_id
      WHERE  hca.party_id        = it_party_id
      AND    hca.cust_account_id = hcas.cust_account_id
      AND    hcas.party_site_id  = hps.party_site_id
      /* 2010.01.06 K.Hosoi E_本稼動_00890,00891対応 END */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_party_site  -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_party_id    -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => it_party_id              -- トークン値3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- 取引タイプＩＤ取得
    -- ================================================
    BEGIN
      SELECT ctt.transaction_type_id transaction_type_id -- 取引タイプＩＤ
      INTO   lt_transaction_type_id
      FROM   csi_txn_types ctt -- 取引タイプテーブル
      WHERE  ctt.source_transaction_type = cv_src_tran_type
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_name         -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_task_name   -- トークン値1
                       ,iv_token_name2  => cv_tkn_src_tran_type     -- トークンコード2
                       ,iv_token_value2 => cv_src_tran_type         -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg           -- トークンコード3
                       ,iv_token_value3 => SQLERRM                  -- トークン値3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- 物件情報更新
    -- ================================================
    -- 構造体初期化
    lt_ext_attrib_values_tbl.DELETE;
    lt_party_tbl.DELETE;
    lt_account_tbl.DELETE;
    lt_pricing_attrib_tbl.DELETE;
    lt_org_assignments_tbl.DELETE;
    lt_asset_assignment_tbl.DELETE;
    lt_instance_id_lst.DELETE;
    --
    -- インストールベール情報
    lt_instance_rec.instance_id           := lt_instance_id;                      -- インスタンスＩＤ
    lt_instance_rec.external_reference    := it_mst_regist_info_rec.install_code; -- 物件コード
    lt_instance_rec.install_date          := it_mst_regist_info_rec.install_date; -- 設置日
    lt_instance_rec.location_type_code    := cv_location_type_code;               -- 現行事業所タイプ
    lt_instance_rec.location_id           := lt_party_site_id;                    -- 現行事業所ＩＤ
    lt_instance_rec.object_version_number := ln_instance_object_vnum;             -- オブジェクトバージョン番号
    --
    -- インスタンスパーティ情報
    lt_party_tbl(1).instance_party_id      := lt_instance_party_id;          -- インスタンスパーティＩＤ
    lt_party_tbl(1).party_source_table     := cv_party_source_table;         -- パーティソーステーブル
    lt_party_tbl(1).party_id               := it_party_id;                   -- パーティＩＤ
    lt_party_tbl(1).relationship_type_code := cv_relationship_type_code;     -- リレーションタイプコード
    lt_party_tbl(1).contact_flag           := cv_flag_no;                    -- コンタクトフラグ
    lt_party_tbl(1).object_version_number  := ln_instance_party_object_vnum; -- オブジェクトバージョン番号
    --
    -- インスタンスアカウント情報
    lt_account_tbl(1).ip_account_id          := lt_ip_account_id;                          -- インスタンスアカウントＩＤ
    lt_account_tbl(1).instance_party_id      := lt_instance_party_id;                      -- インスタンスパーティＩＤ 
    lt_account_tbl(1).parent_tbl_index       := cn_number_one;                             -- インデックス
    lt_account_tbl(1).party_account_id       := it_mst_regist_info_rec.install_account_id; -- 顧客ＩＤ
    lt_account_tbl(1).relationship_type_code := cv_relationship_type_code;                 -- リレーションタイプコード
    lt_account_tbl(1).object_version_number  := ln_instance_acct_object_vnum;              -- オブジェクトバージョン番号
    --
    -- トランザクションタイプ構造体
    lt_txn_rec.transaction_date        := SYSDATE;
    lt_txn_rec.source_transaction_date := SYSDATE;
    lt_txn_rec.transaction_type_id     := lt_transaction_type_id;
    --
    csi_item_instance_pub.update_item_instance(
       p_api_version           => cn_api_version
      ,p_commit                => fnd_api.g_false
      ,p_init_msg_list         => fnd_api.g_true
      ,p_validation_level      => fnd_api.g_valid_level_full
      ,p_instance_rec          => lt_instance_rec
      ,p_ext_attrib_values_tbl => lt_ext_attrib_values_tbl
      ,p_party_tbl             => lt_party_tbl
      ,p_account_tbl           => lt_account_tbl
      ,p_pricing_attrib_tbl    => lt_pricing_attrib_tbl
      ,p_org_assignments_tbl   => lt_org_assignments_tbl
      ,p_asset_assignment_tbl  => lt_asset_assignment_tbl
      ,p_txn_rec               => lt_txn_rec
      ,x_instance_id_lst       => lt_instance_id_lst
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
    --
    IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
      -- リターンコードがS以外の場合
      IF (ln_msg_count > 1) THEN
        lv_msg_data := fnd_msg_pub.get(
                          p_msg_index => cn_number_one
                         ,p_encoded   => fnd_api.g_true
                       );
        --
      END IF;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_14         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_api_name          -- トークンコード1
                     ,iv_token_value1 => cv_tkn_value_ib_update   -- トークン値1
                     ,iv_token_name2  => cv_tkn_api_msg           -- トークンコード2
                     ,iv_token_value2 => lv_msg_data              -- トークン値2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END upd_install_base;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_cont_manage_aft
   * Description      : 契約情報更新処理(A-13)
   ***********************************************************************************/
  PROCEDURE upd_cont_manage_aft(
     it_contract_management_id IN         xxcso_contract_managements.contract_management_id%TYPE -- 自動販売機設置契約書ＩＤ
    ,iv_err_flag               IN         VARCHAR2                                               -- エラーフラグ
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                               -- エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                               -- リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                               -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_cont_manage_aft'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- トークン用定数
    cv_tkn_value_cont_manage CONSTANT VARCHAR2(50) := '契約管理テーブル';
    --
    -- *** ローカル変数 ***
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ================================================
    -- 契約情報更新
    -- ================================================
    BEGIN
      UPDATE xxcso_contract_managements xcm -- 契約管理テーブル
      SET    xcm.cooperate_flag         = cv_finish_cooperate -- マスタ連携フラグ
            ,xcm.batch_proc_status      = DECODE(iv_err_flag
                                                ,cv_flag_no, cv_batch_proc_status_norm
                                                ,cv_batch_proc_status_err
                                          ) -- バッチ処理ステータス
            ,xcm.last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,xcm.last_update_date       = cd_last_update_date       -- 最終更新日
            ,xcm.last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,xcm.request_id             = cn_request_id             -- 要求ID
            ,xcm.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
            ,xcm.program_id             = cn_program_id             -- コンカレント・プログラムID
            ,xcm.program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE xcm.contract_management_id = it_contract_management_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_cont_manage -- トークン値1
                       ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END upd_cont_manage_aft;
  --
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
    lt_mst_regist_info_rec    g_mst_regist_info_rtype;
    lt_contract_management_id xxcso_contract_managements.contract_management_id%TYPE;
    ln_request_id             NUMBER;
    ln_work_count             NUMBER;
    lv_vendor_err_flag        VARCHAR2(1);
    lv_mst_err_flag           VARCHAR2(1);
    lt_party_id               hz_parties.party_id%TYPE;
    --
    -- *** ローカル・カーソル ***
    -- A-3,A-8用カーソル
    CURSOR contract_management_cur
    IS
      SELECT xcm.contract_management_id contract_management_id -- 自動販売機設置契約書ＩＤ
            ,xcm.contract_number        contract_number        -- 契約書番号
            ,xcm.sp_decision_header_id  sp_decision_header_id  -- ＳＰ専決ヘッダＩＤ
            ,xcm.install_account_id     install_account_id     -- 設置先顧客ＩＤ
            ,xcm.install_account_number install_account_number -- 設置先顧客コード
            ,xcm.install_party_name     install_party_name     -- 設置先顧客名
            ,xcm.install_postal_code    install_postal_code    -- 設置先郵便番号
            ,xcm.install_state          install_state          -- 設置先都道府県
            ,xcm.install_city           install_city           -- 設置先市区
            ,xcm.install_address1       install_address1       -- 設置先住所１
            ,xcm.install_address2       install_address2       -- 設置先住所２
            ,xcm.install_date           install_date           -- 設置日
            ,xcm.install_code           install_code           -- 物件コード
      FROM   xxcso_contract_managements xcm -- 契約管理テーブル
      WHERE  xcm.status            = cv_status                -- ステータス
      AND    xcm.cooperate_flag    = cv_un_cooperate          -- マスタ連携フラグ
      AND    xcm.batch_proc_status = cv_batch_proc_status_coa -- バッチ処理ステータス
      ORDER BY xcm.contract_management_id
      ;
    --
    -- A-4用カーソル
    CURSOR vendor_info_cur
    IS
      SELECT xde.supplier_id                  supplier_id                  -- 仕入先ＩＤ
            ,xde.delivery_div                 delivery_div                 -- 送付先区分
            ,xde.payment_name                 payment_name                 -- 支払先名
            ,xde.payment_name_alt             payment_name_alt             -- 支払先名カナ
            ,xde.bank_transfer_fee_charge_div bank_transfer_fee_charge_div -- 振込手数料負担区分
            ,xde.belling_details_div          belling_details_div          -- 支払明細書区分
            ,xde.inquery_charge_hub_cd        inquery_charge_hub_cd        -- 問合せ担当拠点コード
            ,xde.post_code                    post_code                    -- 郵便番号
            ,xde.prefectures                  prefectures                  -- 都道府県
            ,xde.city_ward                    city_ward                    -- 市区
            ,xde.address_1                    address_1                    -- 住所１
            ,xde.address_2                    address_2                    -- 住所２
            ,xde.address_lines_phonetic       address_lines_phonetic       -- 電話番号
            /* 2009.10.15 D.Abe 0001537対応 START */
            ,xde.delivery_id                  delivery_id                  -- 送付先ＩＤ
            /* 2009.10.15 D.Abe 0001537対応 END */
            ,xba.bank_number                  bank_number                  -- 銀行番号
            ,xba.bank_name                    bank_name                    -- 銀行名
            ,xba.branch_number                branch_number                -- 支店番号
            ,xba.branch_name                  branch_name                  -- 支店名
            ,xba.bank_account_type            bank_account_type            -- 口座種別
            ,xba.bank_account_number          bank_account_number          -- 口座番号
            ,xba.bank_account_name_kana       bank_account_name_kana       -- 口座名義カナ
            ,xba.bank_account_name_kanji      bank_account_name_kanji      -- 口座名義漢字
            ,xba.bank_account_dummy_flag      bank_account_dummy_flag      -- 銀行口座ダミーフラグ
      FROM   xxcso_destinations  xde -- 送付先テーブル
            ,xxcso_bank_accounts xba -- 銀行口座アドオンマスタ
      WHERE  xde.contract_management_id = lt_contract_management_id -- 自動販売機設置契約書ＩＤ
      AND    xde.delivery_id            = xba.delivery_id           -- 送付先ＩＤ
      ;
    --
    -- *** ローカル・レコード ***
    --
    -- *** ローカル例外 ***
    mst_coalition_expt EXCEPTION;
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
    gn_vendor_target_cnt := cn_number_zero;
    gn_mst_target_cnt    := cn_number_zero;
    gn_vendor_normal_cnt := cn_number_zero;
    gn_mst_normal_cnt    := cn_number_zero;
    gn_vendor_error_cnt  := cn_number_zero;
    gn_mst_error_cnt     := cn_number_zero;
    /* 2009.04.17 K.Satomura T1_0617対応 START */
    ln_work_count        := cn_number_zero;
    /* 2009.04.17 K.Satomura T1_0617対応 END */
    --
    -- ============
    -- A-1.初期処理
    -- ============
    start_proc(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===================================
    -- A-2. 契約管理情報更新処理
    -- ===================================
    upd_cont_manage_bef(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      ROLLBACK;
      RAISE global_process_expt;
      --
    ELSE
      COMMIT;
      --
    END IF;
    --
    -- **************************************************
    --
    -- 仕入先・口座情報登録処理
    --
    -- **************************************************
    -- ==========================
    -- A-3.契約管理情報取得処理
    -- ==========================
    <<contract_management_loop1>>
    FOR lt_contract_management_rec IN contract_management_cur LOOP
      lt_mst_regist_info_rec.contract_management_id := lt_contract_management_rec.contract_management_id;
      lt_mst_regist_info_rec.contract_number        := lt_contract_management_rec.contract_number;
      lt_mst_regist_info_rec.sp_decision_header_id  := lt_contract_management_rec.sp_decision_header_id;
      lt_mst_regist_info_rec.install_account_id     := lt_contract_management_rec.install_account_id;
      lt_mst_regist_info_rec.install_account_number := lt_contract_management_rec.install_account_number;
      lt_mst_regist_info_rec.install_party_name     := lt_contract_management_rec.install_party_name;
      lt_mst_regist_info_rec.install_postal_code    := lt_contract_management_rec.install_postal_code;
      lt_mst_regist_info_rec.install_state          := lt_contract_management_rec.install_state;
      lt_mst_regist_info_rec.install_city           := lt_contract_management_rec.install_city;
      lt_mst_regist_info_rec.install_address1       := lt_contract_management_rec.install_address1;
      lt_mst_regist_info_rec.install_address2       := lt_contract_management_rec.install_address2;
      lt_contract_management_id                     := lt_contract_management_rec.contract_management_id;
      --
      -- *** DEBUG_LOG START ***
      -- 契約管理情報をログ出力
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg3  || CHR(10) ||
                   cv_debug_msg4  || lt_contract_management_rec.contract_management_id || CHR(10) ||
                   cv_debug_msg74 || lt_mst_regist_info_rec.contract_number            || CHR(10) ||
                   cv_debug_msg5  || lt_contract_management_rec.sp_decision_header_id  || CHR(10) ||
                   cv_debug_msg6  || lt_contract_management_rec.install_account_id     || CHR(10) ||
                   cv_debug_msg7  || lt_contract_management_rec.install_account_number || CHR(10) ||
                   cv_debug_msg8  || lt_contract_management_rec.install_party_name     || CHR(10) ||
                   cv_debug_msg9  || lt_contract_management_rec.install_postal_code    || CHR(10) ||
                   cv_debug_msg10 || lt_contract_management_rec.install_state          || CHR(10) ||
                   cv_debug_msg11 || lt_contract_management_rec.install_city           || CHR(10) ||
                   cv_debug_msg12 || lt_contract_management_rec.install_address1       || CHR(10) ||
                   cv_debug_msg13 || lt_contract_management_rec.install_address2       || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
      -- ============================================
      -- A-4.仕入先情報取得処理
      -- ============================================
      /* 2009.04.17 K.Satomura T1_0617対応 START */
      --ln_work_count := cn_number_zero;
      /* 2009.04.17 K.Satomura T1_0617対応 END */
      --
      <<vendor_info_loop>>
      FOR lt_vendor_info_rec IN vendor_info_cur LOOP
        ln_work_count := ln_work_count + cn_number_one;
        --
        lt_mst_regist_info_rec.supplier_id                  := lt_vendor_info_rec.supplier_id;
        lt_mst_regist_info_rec.delivery_div                 := lt_vendor_info_rec.delivery_div;
        lt_mst_regist_info_rec.payment_name                 := lt_vendor_info_rec.payment_name;
        lt_mst_regist_info_rec.payment_name_alt             := lt_vendor_info_rec.payment_name_alt;
        lt_mst_regist_info_rec.bank_transfer_fee_charge_div := lt_vendor_info_rec.bank_transfer_fee_charge_div;
        lt_mst_regist_info_rec.belling_details_div          := lt_vendor_info_rec.belling_details_div;
        lt_mst_regist_info_rec.inquery_charge_hub_cd        := lt_vendor_info_rec.inquery_charge_hub_cd;
        lt_mst_regist_info_rec.post_code                    := lt_vendor_info_rec.post_code;
        lt_mst_regist_info_rec.prefectures                  := lt_vendor_info_rec.prefectures;
        lt_mst_regist_info_rec.city_ward                    := lt_vendor_info_rec.city_ward;
        lt_mst_regist_info_rec.address_1                    := lt_vendor_info_rec.address_1;
        lt_mst_regist_info_rec.address_2                    := lt_vendor_info_rec.address_2;
        lt_mst_regist_info_rec.address_lines_phonetic       := lt_vendor_info_rec.address_lines_phonetic;
        /* 2009.10.15 D.Abe 0001537対応 START */
        lt_mst_regist_info_rec.delivery_id                  := lt_vendor_info_rec.delivery_id;
        /* 2009.10.15 D.Abe 0001537対応 END */
        lt_mst_regist_info_rec.bank_number                  := lt_vendor_info_rec.bank_number;
        lt_mst_regist_info_rec.bank_name                    := lt_vendor_info_rec.bank_name;
        lt_mst_regist_info_rec.branch_number                := lt_vendor_info_rec.branch_number;
        lt_mst_regist_info_rec.branch_name                  := lt_vendor_info_rec.branch_name;
        lt_mst_regist_info_rec.bank_account_type            := lt_vendor_info_rec.bank_account_type;
        lt_mst_regist_info_rec.bank_account_number          := lt_vendor_info_rec.bank_account_number;
        lt_mst_regist_info_rec.bank_account_name_kana       := lt_vendor_info_rec.bank_account_name_kana;
        lt_mst_regist_info_rec.bank_account_name_kanji      := lt_vendor_info_rec.bank_account_name_kanji;
        --
        -- *** DEBUG_LOG START ***
        -- 仕入先情報をログ出力
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg14 || CHR(10) ||
                     cv_debug_msg15 || lt_vendor_info_rec.supplier_id                  || CHR(10) ||
                     cv_debug_msg16 || lt_vendor_info_rec.delivery_div                 || CHR(10) ||
                     cv_debug_msg17 || lt_vendor_info_rec.payment_name                 || CHR(10) ||
                     cv_debug_msg18 || lt_vendor_info_rec.payment_name_alt             || CHR(10) ||
                     cv_debug_msg19 || lt_vendor_info_rec.bank_transfer_fee_charge_div || CHR(10) ||
                     cv_debug_msg20 || lt_vendor_info_rec.belling_details_div          || CHR(10) ||
                     cv_debug_msg21 || lt_vendor_info_rec.inquery_charge_hub_cd        || CHR(10) ||
                     cv_debug_msg22 || lt_vendor_info_rec.post_code                    || CHR(10) ||
                     cv_debug_msg23 || lt_vendor_info_rec.prefectures                  || CHR(10) ||
                     cv_debug_msg24 || lt_vendor_info_rec.city_ward                    || CHR(10) ||
                     cv_debug_msg25 || lt_vendor_info_rec.address_1                    || CHR(10) ||
                     cv_debug_msg26 || lt_vendor_info_rec.address_2                    || CHR(10) ||
                     cv_debug_msg27 || lt_vendor_info_rec.address_lines_phonetic       || CHR(10) ||
                     /* 2009.10.15 D.Abe 0001537対応 START */
                     cv_debug_msg80 || lt_vendor_info_rec.delivery_id                  || CHR(10) ||
                     /* 2009.10.15 D.Abe 0001537対応 END */
                     cv_debug_msg28 || lt_vendor_info_rec.bank_number                  || CHR(10) ||
                     cv_debug_msg29 || lt_vendor_info_rec.bank_name                    || CHR(10) ||
                     cv_debug_msg30 || lt_vendor_info_rec.branch_number                || CHR(10) ||
                     cv_debug_msg31 || lt_vendor_info_rec.branch_name                  || CHR(10) ||
                     cv_debug_msg32 || lt_vendor_info_rec.bank_account_type            || CHR(10) ||
                     cv_debug_msg33 || lt_vendor_info_rec.bank_account_number          || CHR(10) ||
                     cv_debug_msg34 || lt_vendor_info_rec.bank_account_name_kana       || CHR(10) ||
                     cv_debug_msg35 || lt_vendor_info_rec.bank_account_name_kanji      || CHR(10) ||

                     ''
        );
        -- *** DEBUG_LOG END ***
        --
        -- ===================================
        -- A-5.ベンダー中間I/Fテーブル登録処理
        -- ===================================
        reg_vendor_if(
           it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
          ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ           --# 固定 #
          ,ov_retcode             => lv_retcode             -- リターン・コード             --# 固定 #
          ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          ROLLBACK;
          gn_vendor_error_cnt := gn_vendor_error_cnt + cn_number_one;
          RAISE global_process_expt;
          --
        END IF;
        --
        lt_vendor_info_rec := NULL;
        --
      END LOOP vendor_info_loop;
      --
      lt_contract_management_rec := NULL;
      lt_mst_regist_info_rec     := NULL;
      --
    END LOOP contract_management_loop1;
    --
    IF (gn_vendor_target_cnt > cn_number_zero) THEN
      IF (ln_work_count > cn_number_zero) THEN
        -- ==========================
        -- A-6.仕入先情報登録/更新処理
        -- ==========================
        reg_vendor(
           on_request_id => ln_request_id -- 要求ＩＤ
          ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ           --# 固定 #
          ,ov_retcode    => lv_retcode    -- リターン・コード             --# 固定 #
          ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          ROLLBACK;
          RAISE global_process_expt;
          --
        ELSE
          COMMIT;
          --
        END IF;
        --
        -- =========================================
        -- A-7.仕入先情報登録/更新完了確認処理
        -- =========================================
        confirm_reg_vendor(
           in_request_id => ln_request_id -- 要求ＩＤ
          ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ           --# 固定 #
          ,ov_retcode    => lv_retcode    -- リターン・コード             --# 固定 #
          ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          gn_vendor_error_cnt := gn_vendor_error_cnt + cn_number_one;
          RAISE global_process_expt;
          --
        END IF;
        --
      END IF;
      --
      <<contract_management_loop2>>
      FOR lt_contract_management_rec IN contract_management_cur LOOP
        lv_vendor_err_flag                            := cv_flag_no;
        lt_mst_regist_info_rec.contract_management_id := lt_contract_management_rec.contract_management_id;
        lt_mst_regist_info_rec.contract_number        := lt_contract_management_rec.contract_number;
        lt_mst_regist_info_rec.sp_decision_header_id  := lt_contract_management_rec.sp_decision_header_id ;
        lt_mst_regist_info_rec.install_account_id     := lt_contract_management_rec.install_account_id;
        lt_mst_regist_info_rec.install_account_number := lt_contract_management_rec.install_account_number;
        lt_mst_regist_info_rec.install_party_name     := lt_contract_management_rec.install_party_name;
        lt_mst_regist_info_rec.install_postal_code    := lt_contract_management_rec.install_postal_code;
        lt_mst_regist_info_rec.install_state          := lt_contract_management_rec.install_state;
        lt_mst_regist_info_rec.install_city           := lt_contract_management_rec.install_city;
        lt_mst_regist_info_rec.install_address1       := lt_contract_management_rec.install_address1;
        lt_mst_regist_info_rec.install_address2       := lt_contract_management_rec.install_address2;
        lt_mst_regist_info_rec.install_date           := lt_contract_management_rec.install_date;
        lt_mst_regist_info_rec.install_code           := lt_contract_management_rec.install_code;
        --
        -- ===================================
        -- A-8.仕入先情報登録/更新エラー時処理
        -- ===================================
        error_reg_vendor(
           it_contract_management_id => lt_contract_management_rec.contract_management_id -- 自動販売機設置契約書ＩＤ
          ,it_contract_number        => lt_contract_management_rec.contract_number        -- 契約書番号
          ,in_request_id             => ln_request_id                                     -- 要求ＩＤ
          ,ov_err_flag               => lv_vendor_err_flag                                -- 仕入先取込エラーフラグ
          ,ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
          ,ov_retcode                => lv_retcode                                        -- リターン・コード             --# 固定 #
          ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          ROLLBACK;
          gn_vendor_error_cnt := gn_vendor_error_cnt + cn_number_one;
          RAISE global_process_expt;
          --
        ELSE
          COMMIT;
          --
        END IF;
        --
        -- **************************************************
        --
        -- マスタ情報登録・更新処理
        --
        -- **************************************************
        IF (lv_vendor_err_flag = cv_flag_no) THEN
          -- A-8の処理でエラーがなかったデータのみ以降の処理を行う。
          gn_vendor_normal_cnt := gn_vendor_normal_cnt + cn_number_one; -- 仕入先取込が正常に登録されたものをカウント
          gn_mst_target_cnt    := gn_mst_target_cnt + cn_number_one;    -- マスタ連携処理対象件数カウント
          SAVEPOINT msg_coalition;
          --
          BEGIN
            -- ================================
            -- A-9.仕入先ID関連付け処理
            -- ================================
            associate_vendor_id(
               it_contract_management_id => lt_contract_management_rec.contract_management_id -- 自動販売機設置契約書ＩＤ
              ,it_sp_decision_header_id  => lt_contract_management_rec.sp_decision_header_id  -- ＳＰ専決ヘッダＩＤ
              ,ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
              ,ov_retcode                => lv_retcode                                        -- リターン・コード             --# 固定 #
              ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            --
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE mst_coalition_expt;
              --
            END IF;
            --
            -- =========================================
            -- A-10.販売手数料情報登録/更新処理
            -- =========================================
            reg_backmargin(
               it_sp_decision_header_id  => lt_contract_management_rec.sp_decision_header_id  -- ＳＰ専決ヘッダＩＤ
              ,it_install_account_number => lt_contract_management_rec.install_account_number -- 設置先顧客コード
              ,ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
              ,ov_retcode                => lv_retcode                                        -- リターン・コード             --# 固定 #
              ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            --
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE mst_coalition_expt;
              --
            END IF;
            --
            -- =========================================
            -- A-11.設置先顧客情報更新処理
            -- =========================================
            upd_install_at(
               it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
              ,ot_party_id            => lt_party_id            -- パーティＩＤ
              ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ           --# 固定 #
              ,ov_retcode             => lv_retcode             -- リターン・コード             --# 固定 #
              ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
            );
            --
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE mst_coalition_expt;
              --
            END IF;
            --
            -- =========================================
            -- A-12.物件情報更新処理
            -- =========================================
            IF (TRIM(lt_mst_regist_info_rec.install_code)) IS NOT NULL THEN
              upd_install_base(
                 it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
                ,it_party_id            => lt_party_id            -- パーティＩＤ
                ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ           --# 固定 #
                ,ov_retcode             => lv_retcode             -- リターン・コード             --# 固定 #
                ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
              );
              --
              IF (lv_retcode <> cv_status_normal) THEN
                RAISE mst_coalition_expt;
                --
              END IF;
              --
            END IF;
            --
            lv_mst_err_flag   := cv_flag_no;
            gn_mst_normal_cnt := gn_mst_normal_cnt + cn_number_one; -- マスタ連携で正常に登録されたものをカウント
            --
          EXCEPTION
            WHEN mst_coalition_expt THEN
              -- マスタ連携でエラーがあった場合、ロールバックをしメッセージを出力
              ROLLBACK TO msg_coalition;
              --
              fnd_file.put_line(
                 which  => fnd_file.output
                ,buff   => lv_errbuf
              );
              --
              lv_mst_err_flag  := cv_flag_yes;
              gn_mst_error_cnt := gn_mst_error_cnt + cn_number_one; -- マスタ連携でエラーがあったものをカウント
              --
          END;
          --
        ELSE
          gn_vendor_error_cnt := gn_vendor_error_cnt + cn_number_one; -- 仕入先取込でエラーがあったものをカウント
          --
        END IF;
        --
        -- =============================================
        -- A-13.契約情報更新処理
        -- =============================================
        upd_cont_manage_aft(
           it_contract_management_id => lt_contract_management_rec.contract_management_id -- 自動販売機設置契約書ＩＤ
          ,iv_err_flag               => lv_mst_err_flag                                   -- エラーフラグ
          ,ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
          ,ov_retcode                => lv_retcode                                        -- リターン・コード             --# 固定 #
          ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        lt_contract_management_rec := NULL;
        --
      END LOOP contract_management_loop2;
      --
    END IF;
    --
    IF ((gn_mst_error_cnt > cn_number_zero)
      OR (gn_vendor_error_cnt > cn_number_zero))
    THEN
      -- マスタ連携又は仕入先取込でエラーがあった場合
      ov_retcode := cv_status_warn;
      --
    END IF;
    --
    COMMIT;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** 処理部共通例外ハンドラ ***
      -- 契約管理テーブルを全て更新
      UPDATE xxcso_contract_managements xcm -- 契約管理テーブル
      SET    xcm.cooperate_flag         = cv_finish_cooperate       -- マスタ連携フラグ
            ,xcm.batch_proc_status      = cv_batch_proc_status_err  -- バッチ処理ステータス
            ,xcm.last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,xcm.last_update_date       = cd_last_update_date       -- 最終更新日
            ,xcm.last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,xcm.request_id             = cn_request_id             -- 要求ID
            ,xcm.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
            ,xcm.program_id             = cn_program_id             -- コンカレント・プログラムID
            ,xcm.program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE  xcm.status            = cv_status                -- ステータス
      AND    xcm.cooperate_flag    = cv_un_cooperate          -- マスタ連携フラグ
      AND    xcm.batch_proc_status = cv_batch_proc_status_coa -- バッチ処理ステータス
      ;
      COMMIT;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      -- 契約管理テーブルを全て更新
      UPDATE xxcso_contract_managements xcm -- 契約管理テーブル
      SET    xcm.cooperate_flag         = cv_finish_cooperate       -- マスタ連携フラグ
            ,xcm.batch_proc_status      = cv_batch_proc_status_err  -- バッチ処理ステータス
            ,xcm.last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,xcm.last_update_date       = cd_last_update_date       -- 最終更新日
            ,xcm.last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,xcm.request_id             = cn_request_id             -- 要求ID
            ,xcm.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
            ,xcm.program_id             = cn_program_id             -- コンカレント・プログラムID
            ,xcm.program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE  xcm.status            = cv_status                -- ステータス
      AND    xcm.cooperate_flag    = cv_un_cooperate          -- マスタ連携フラグ
      AND    xcm.batch_proc_status = cv_batch_proc_status_coa -- バッチ処理ステータス
      ;
      COMMIT;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ --# 固定 #
    ,retcode OUT NOCOPY VARCHAR2 -- リターン・コード   --# 固定 #
  )
  --
  --###########################  固定部 START   ###########################
  --
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   -- 終了メッセージコード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_value_vendor CONSTANT VARCHAR2(50) := '仕入先取込';
    cv_tkn_value_mst    CONSTANT VARCHAR2(50) := 'マスタ連携';
    --
    -- *** ローカル変数 ***
    --
  BEGIN
    --
    --###########################  固定部 START   #####################################################
    --
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
      --
    END IF;
    --
    --###########################  固定部 END   #############################
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
       -- エラー出力
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
       );
       --
       fnd_file.put_line(
          which  => fnd_file.log
         ,buff   => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf --エラーメッセージ
       );
       --
    END IF;
    --
    -- =======================
    -- A-14.終了処理
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    -- 対象件数出力(仕入先取込)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_15
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_vendor
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_vendor_target_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- 対象件数出力(マスタ連携)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_15
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_mst
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_mst_target_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- 成功件数出力(仕入先取込)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_16
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_vendor
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_vendor_normal_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- 成功件数出力(マスタ連携)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_16
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_mst
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_mst_normal_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- エラー件数出力(仕入先取込)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_17
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_vendor
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_vendor_error_cnt)
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    -- エラー件数出力(マスタ連携)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_17
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_mst
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_mst_error_cnt)
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
      --
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
      --
    ELSIF(lv_retcode = cv_status_error) THEN
      IF ((gn_vendor_normal_cnt = cn_number_zero)
        AND (gn_mst_normal_cnt = cn_number_zero))
      THEN
        -- 正常の件数が1件もない場合
        lv_message_code := cv_error_msg;
        --
      ELSE
        lv_message_code := cv_tkn_number_18;
        --
      END IF;
      --
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- ステータスセット
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    --
  EXCEPTION
    --
    --###########################  固定部 START   #####################################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
  END main;
  --
  --###########################  固定部 END   #######################################################
  --
END XXCSO010A02C;
/
