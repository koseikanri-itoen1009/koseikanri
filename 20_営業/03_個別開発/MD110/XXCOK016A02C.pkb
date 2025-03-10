CREATE OR REPLACE PACKAGE BODY XXCOK016A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK016A02C(body)
 * Description      : 本機能は処理パラメータにて、以下の２機能を切り替えて処理します。
 *
 *                    【振込口座事前チェック用FB作成】
 *                    実際の振込処理前に、振込口座が正しいかをチェックするためのデータを作成します。
 *
 *                    【本振用FBデータ作成】
 *                    自販機販売手数料を振り込むためのFBデータを作成します。
 *
 * MD.050           : FBデータファイル作成（FBデータ作成） MD050_COK_016_A02
 * Version          : 1.14
 *
 * Program List
 * -------------------------------- ----------------------------------------------------------
 *  Name                             Description
 * -------------------------------- ----------------------------------------------------------
 *  init                             初期処理 (A-1)
-- Ver.1.13 DEL START
-- *  get_bank_acct_chk_fb_line        FB作成明細データの取得（振込口座事前チェック用FB作成処理）(A-2)
-- *  get_fb_line                      FB作成明細データの取得（本振用FBデータ作成処理）(A-3)
-- Ver.1.13 DEL END
 *  get_fb_header                    FB作成ヘッダーデータの取得(A-4)
 *  storage_fb_header                FB作成ヘッダーデータの格納(A-5)
 *  storage_bank_acct_chk_fb_line    FB作成明細データの格納（振込口座事前チェック用FB作成処理）(A-7)
 *  get_fb_line_add_info             FB作成明細データ付加情報の取得（本振用FBデータ作成処理）(A-8)
 *  storage_fb_line                  FB作成明細データの格納（本振用FBデータ作成処理）(A-9)
 *  upd_backmargin_balance           FB作成データ出力結果の更新(A-11)
 *  storage_fb_trailer_data          FB作成トレーラレコードの格納(A-12)
 *  storage_fb_end_data              FB作成エンドレコードの格納(A-14)
 *  output_data                      FB作成ヘッダーデータの出力(A-6)
 *                                   FB作成データレコードの出力(A-10)
 *                                   FB作成トレーラレコードの出力(A-13)
 *                                   FB作成エンドレコードの出力(A-15)
 *  upd_carried_forward_data         翌月繰り越しデータの更新(A-17)
 *  dmy_acct_chk                     FB作成対象外ダミー口座判定
-- Ver.1.13 ADD START
 *  insert_data                      FBデータ明細ワークテーブル登録(A-10B)
 *  delete_data                      ワークテーブルデータ削除(A-18)
-- Ver.1.13 ADD END
 *  submain                          メイン処理プロシージャ
 *  main                             コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/06    1.0   T.Abe            新規作成
 *  2009/03/25    1.1   S.Kayahara       最終行にスラッシュ追加
 *  2009/04/27    1.2   M.Hiruta         [障害T1_0817対応]本振用FBデータ作成処理時の拠点コード抽出元テーブルを変更
 *  2009/05/12    1.3   M.Hiruta         [障害T1_0832対応]本振用FBデータ作成処理時、
 *                                                        以下の条件のレコードを出力しないように変更
 *                                                          1.振込手数料負担者が伊藤園、且つ支払予定額 <= 0
 *                                                          2.振込手数料負担者が伊藤園ではない、
 *                                                            且つ支払予定額 - 振込手数料 <= 0
 *  2009/05/29    1.4   K.Yamaguchi      [障害T1_1147対応]販手残高テーブル更新項目追加
 *  2009/07/02    1.5   K.Yamaguchi      [障害0000291対応]パフォーマンス障害対応
 *  2009/08/03    1.6   M.Hiruta         [障害0000843対応]振込元口座情報の取得条件の取得条件を修正
 *  2009/12/16    1.7   S.Moriyama       [E_本稼動_00512対応]振手相手負担時に振込額から振手を減額して出力するように修正
 *  2009/12/16    1.8   S.Moriyama       [E_本稼動_00512対応]FBトレーラレコードに設定している出力件数を対象件数から出力件数へ修正
 *  2009/12/17    1.9   S.Moriyama       [E_本稼動_00511対応]FB明細レコードの振込金額の次項目として
 *                                                           91byte目に半角数値0を設定するように修正
 *                                                           顧客コード1、顧客コード2については10byte前0埋めを行うように修正
 *  2010/09/30    1.10  S.Arizumi        [E_本稼動_01144対応]当月保留分を翌月のイセトー経由の支払案内書に含む修正
 *                                                           金額確定ステータスが確定済のレコードのみ対象とするように修正
 *  2018/08/07    1.11  K.Nara           [E_本稼動_15203対応]本振用FBデータ作成で振込先がダミー口座は作成対象外とする
 *  2023/06/06    1.12  Y.Ooyama         [E_本稼動_19179対応]インボイス対応（BM関連）
 *  2023/10/25    1.13  T.Okuyama        [E_本稼動_19540対応]「振り分け上手」アプリの代替え対応
 *  2024/02/02    1.14  T.Okuyama        [E_本稼動_19496対応] グループ会社対応
 *****************************************************************************************/
--
  --===============================
  -- グローバル定数
  --===============================
  --ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by               CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
-- Ver.1.13 ADD START
  cd_creation_date            CONSTANT DATE          := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date         CONSTANT DATE          := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date      CONSTANT DATE          := SYSDATE;                            -- PROGRAM_UPDATE_DATE
-- Ver.1.13 ADD END
  --
  cv_msg_part                 CONSTANT VARCHAR2(3)   := ' : ';                              -- コロン
  cv_msg_cont                 CONSTANT VARCHAR2(3)   := '.';                                -- ピリオド
  --
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOK016A02C';                     -- パッケージ名
  -- プロファイル
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
--  cv_prof_bm_acc_number       CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_OUR_BANK_ACC_NUMBER';    -- 当社銀行口座番号
--  cv_prof_bm_bra_number       CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_OUR_BANK_BRA_NUMBER';    -- 当社銀行支店番号
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
  cv_prof_bm_request_code     CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_OUR_REQUEST_CODE';       -- 当社依頼人コード
  cv_prof_trans_criterion     CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- 銀行手数料(振込基準額)
  cv_prof_less_fee_criterion  CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- 銀行手数料額(基準未満)
  cv_prof_more_fee_criterion  CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- 銀行手数料額(基準以上)
  cv_prof_fb_term_name        CONSTANT VARCHAR2(35)  := 'XXCOK1_FB_TERM_NAME';              -- FB支払条件
  cv_prof_bm_tax              CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_TAX';                    -- 消費税率
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  cv_prof_org_id              CONSTANT VARCHAR2(35)  := 'ORG_ID';                           -- 営業単位
  cv_prof_bank_trns_fee_we    CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_TRNS_FEE_WE';          -- 振込手数料_当方
  cv_prof_bank_trns_fee_ctpty CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_TRNS_FEE_CTPTY';       -- 振込手数料_相手方
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  cv_prof_acc_type_internal   CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_ACC_TYPE_INTERNAL';      -- 振込手数料_当社_口座使用
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  -- アプリケーション名
  cv_appli_xxccp              CONSTANT VARCHAR2(5)   := 'XXCCP';               -- 'XXCCP'
  cv_appli_xxcok              CONSTANT VARCHAR2(5)   := 'XXCOK';               -- 'XXCOK'
  -- メッセージ
  cv_msg_cok_00044            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00044';    -- コンカレント入力パラメータメッセージ
-- Ver.1.14 Add Start
  cv_msg_cok_10878            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10878';    -- コンカレント入力パラメータ（会社コード）
  cv_msg_cok_10879            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10879';    -- 会社コード取得エラーメッセージ
-- Ver.1.14 Add End
  cv_msg_cok_00003            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00003';    -- プロファイル値取得エラーメッセージ
  cv_msg_cok_00028            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00028';    -- 業務処理日付取得エラーメッセージ
  cv_msg_cok_00014            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00014';    -- 値セット値取得エラー
  cv_msg_cok_00036            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00036';    -- 締め・支払日付の取得エラー
  cv_msg_cok_10254            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10254';    -- FB作成明細情報取得エラー
  cv_msg_cok_10255            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10255';    -- FB作成ヘッダー情報取得エラー
  cv_msg_cok_10256            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10256';    -- FB作成ヘッダー情報重複エラー
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi REPAIR START
--  cv_msg_cok_10243            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10243';    -- FB作成結果更新ロックエラー
--  cv_msg_cok_10244            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10244';    -- FB作成結果更新エラー
  cv_msg_cok_00053            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00053';    -- 販手残高テーブル更新ロックエラー
  cv_msg_cok_00054            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00054';    -- 販手残高テーブル更新エラー
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi REPAIR END
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
  cv_msg_cok_10561            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10561';    -- FBデータのダミー口座警告
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
  cv_msg_ccp_90000            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000';    -- 抽出件数メッセージ
  cv_msg_ccp_90002            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002';    -- エラー件数メッセージ
  cv_msg_ccp_90001            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90001';    -- ファイル出力件数メッセージ
  cv_msg_ccp_90004            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004';    -- 正常終了メッセージ
  cv_msg_ccp_90006            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006';    -- エラー終了全ロールバックメッセージ
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  cv_msg_cok_10453            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10453';    -- FBデータの支払金額0円以下警告
  cv_msg_ccp_90003            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90003';    -- スキップ件数メッセージ
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Ver.1.13 ADD START
  cv_msg_cok_10861            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10861';    -- データ登録エラー
  cv_msg_cok_10862            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10862';    -- データ削除エラー
  cv_msg_cok_10863            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10863';    -- テーブルロック取得エラー
-- Ver.1.13 ADD END
  -- メッセージ・トークン
-- Ver.1.14 Add Start
  cv_token_company_code       CONSTANT VARCHAR2(15)  := 'COMPANY_CODE';        -- 会社コードパラメータ
-- Ver.1.14 Add End
  cv_token_proc_type          CONSTANT VARCHAR2(15)  := 'PROC_TYPE';           -- 処理パラメータ
  cv_token_profile            CONSTANT VARCHAR2(15)  := 'PROFILE';             -- カスタムプロファイルの物理名
  cv_token_flex_value_set     CONSTANT VARCHAR2(15)  := 'FLEX_VALUE_SET';      -- 値セットの物理名
  cv_token_count              CONSTANT VARCHAR2(15)  := 'COUNT';               -- 件数
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  cv_token_conn_loc           CONSTANT VARCHAR2(15)  := 'CONN_LOC';            -- 問合せ担当拠点
  cv_token_vendor_code        CONSTANT VARCHAR2(15)  := 'VENDOR_CODE';         -- 支払先コード
  cv_token_payment_amt        CONSTANT VARCHAR2(15)  := 'PAYMENT_AMT';         -- 支払金額
  cv_token_bank_charge_bearer CONSTANT VARCHAR2(20)  := 'BANK_CHARGE_BEARER';  -- 銀行手数料負担者
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
  cv_token_bank_number       CONSTANT VARCHAR2(15)  := 'BANK_NUMBER';          -- 銀行番号
  cv_token_bank_num          CONSTANT VARCHAR2(15)  := 'BANK_NUM';             -- 銀行支店番号
  cv_token_account_type      CONSTANT VARCHAR2(15)  := 'ACCOUNT_TYPE';         -- 預金種別
  cv_token_account_num       CONSTANT VARCHAR2(20)  := 'ACCOUNT_NUM';          -- 銀行口座番号
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
-- Ver.1.13 ADD START
  cv_tkn_tbl                 CONSTANT VARCHAR2(30)  := 'TABLE';                -- テーブル名
  cv_tkn_err_msg             CONSTANT VARCHAR2(30)  := 'ERR_MSG';              -- エラーメッセージ
  cv_tbl_nm                  CONSTANT VARCHAR2(100) := 'FBデータ明細ワークテーブル';
-- Ver.1.13 ADD END
  -- 値セット
  cv_value_cok_fb_proc_type   CONSTANT VARCHAR2(30)  := 'XXCOK1_FB_PROC_TYPE'; -- 値セット名
  -- 定数
  cv_log                      CONSTANT VARCHAR2(3)   := 'LOG';                 -- ログ出力指定
  cv_yes                      CONSTANT VARCHAR2(1)   := 'Y';                   -- フラグ:'Y'
  cv_no                       CONSTANT VARCHAR2(1)   := 'N';                   -- フラグ:'N'
  cv_space                    CONSTANT VARCHAR2(1)   := ' ';                   -- スペース1文字
  cv_zero                     CONSTANT VARCHAR2(1)   := '0';                   -- 文字型数字：'0'
  cv_1                        CONSTANT VARCHAR2(1)   := '1';                   -- 文字型数字：'1'
  cv_2                        CONSTANT VARCHAR2(1)   := '2';                   -- 文字型数字：'2'
--
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD START
  cn_zero                     CONSTANT NUMBER        := 0;                     -- 数値：0
  cn_1                        CONSTANT NUMBER        := 1;                     -- 数値：1
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD END
--
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  cv_i                        CONSTANT VARCHAR2(1)   := 'I';                   -- 銀行手数料負担者：'I'（当方）
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  cv_lookup_type_bank         CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_BANK_ACCOUNT'; -- 参照タイプ：当社銀行口座情報
  cv_lookup_code_bank         CONSTANT VARCHAR2(10)  := 'VDBM_FB';                -- 参照コード：VDBM振込元口座
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
  cv_lookup_type_fb_not       CONSTANT VARCHAR2(50)  := 'XXCOK1_FB_NOT_TARGET';   -- 参照タイプ：FB作成対象外ダミー口座
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
-- Ver.1.12 ADD START
  cv_tax_rounding_rule_down   CONSTANT VARCHAR2(4)   := 'DOWN';                   -- 端数処理区分：切捨て
  cv_get_target_amt_with_tax  CONSTANT VARCHAR2(1)   := '3';                      -- 取得対象金額：支払金額(税込)
  cv_snapshot_timing_2_bd     CONSTANT VARCHAR2(1)   := '1';                      -- スナップショットタイミング：2営
  cv_tax_calc_kbn_line        CONSTANT VARCHAR2(1)   := '2';                      -- 税計算区分：明細単位
  cv_tax_kbn_with_tax         CONSTANT VARCHAR2(1)   := '1';                      -- 税区分：税込み
-- Ver.1.12 ADD END
-- Ver.1.14 Add Start
  cv_sob_id                   CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';       -- GL会計帳簿ID
  cv_settlement_kbn           CONSTANT VARCHAR2(1)   := '7';                      -- 振込指定区分（決済優先度）7:電信振込
-- Ver.1.14 Add End
  --
  --===============================
  -- グローバル変数
  --===============================
  -- 出力メッセージ
  gv_out_msg                  VARCHAR2(2000) DEFAULT NULL;                            -- 出力メッセージ
  -- カウンタ
  gn_target_cnt               NUMBER         DEFAULT NULL;                            -- 対象件数
  gn_normal_cnt               NUMBER         DEFAULT NULL;                            -- 正常件数
  gn_error_cnt                NUMBER         DEFAULT NULL;                            -- エラー件数
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--  gn_warn_cnt                 NUMBER         DEFAULT NULL;                            -- スキップ件数
  gn_skip_cnt                 NUMBER         DEFAULT NULL;                            -- スキップ件数
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  gn_out_cnt                  NUMBER         DEFAULT NULL;                            -- 成功件数
  -- プロファイル
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
--  gt_prof_bm_acc_number       fnd_profile_option_values.profile_option_value%TYPE;    -- 銀行口座番号
--  gt_prof_bm_bra_number       fnd_profile_option_values.profile_option_value%TYPE;    -- 銀行支店番号
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
  gt_prof_bm_request_code     fnd_profile_option_values.profile_option_value%TYPE;    -- 依頼人コード
  gt_prof_trans_fee_criterion fnd_profile_option_values.profile_option_value%TYPE;    -- 振込額の基準金額
  gt_prof_less_fee_criterion  fnd_profile_option_values.profile_option_value%TYPE;    -- 銀行手数料額(基準未満)
  gt_prof_more_fee_criterion  fnd_profile_option_values.profile_option_value%TYPE;    -- 銀行手数料額(基準以上)
  gt_prof_fb_term_name        fnd_profile_option_values.profile_option_value%TYPE;    -- FB支払条件
  gt_prof_bm_tax              fnd_profile_option_values.profile_option_value%TYPE;    -- 消費税率
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  gt_prof_org_id              fnd_profile_option_values.profile_option_value%TYPE;    -- 営業単位
  gt_prof_bank_trns_fee_we    fnd_profile_option_values.profile_option_value%TYPE;    -- 振込手数料_当方
  gt_prof_bank_trns_fee_ctpty fnd_profile_option_values.profile_option_value%TYPE;    -- 振込手数料_相手方
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  gt_prof_acc_type_internal   fnd_profile_option_values.profile_option_value%TYPE;    -- 振込手数料_当社_口座使用
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  -- 種別コード
  gt_values_type_code         fnd_flex_values.attribute1%TYPE;                        -- 種別コード
  -- 日付
  gd_pay_date                 DATE;                                                   -- 当月の支払日
  gd_proc_date                DATE;                                                   -- 業務処理日付
-- Ver.1.14 Add Start
  gt_set_of_books_id          gl_sets_of_books.set_of_books_id%TYPE;                  -- GL会計帳簿ID
  gv_company_code             xxcfo_company_v.company_code%TYPE;                      -- パラメータ.会社コード
-- Ver.1.14 Add End
  --===============================
  -- グローバル・カーソル
  --===============================
  -- FB作成明細データ（振込口座事前チェック用FB作成処理）
  CURSOR bac_fb_line_cur
  IS
  SELECT  pv.segment1                  AS segment1                  -- 仕入先コード
         ,pvsa.vendor_site_code        AS vendor_site_code          -- 仕入先サイトコード
         ,abb.bank_number              AS bank_number               -- 銀行番号
         ,abb.bank_name_alt            AS bank_name_alt             -- 銀行名カナ
         ,abb.bank_num                 AS bank_num                  -- 銀行支店番号
         ,abb.bank_branch_name_alt     AS bank_branch_name_alt      -- 銀行支店名カナ
         ,abaa.bank_account_type       AS bank_account_type         -- 預金種別
         ,abaa.bank_account_num        AS bank_account_num          -- 銀行口座番号
         ,abaa.account_holder_name_alt AS account_holder_name_alt   -- 口座名義人カナ
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD START
         ,pvsa.attribute5              AS base_code                 -- 問合せ担当拠点コード
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD END
  FROM    po_vendors                      pv                        -- 仕入先マスタ
         ,po_vendor_sites_all             pvsa                      -- 仕入先サイトマスタ
         ,ap_bank_account_uses_all        abaua                     -- 銀行口座使用情報
         ,ap_bank_accounts_all            abaa                      -- 銀行口座マスタ
         ,ap_bank_branches                abb                       -- 銀行支店マスタ
-- Ver.1.14 Add Start
         ,xxcfr_bd_dept_comp_info_v       xbdciv                    -- 担当拠点会社情報ビュー
-- Ver.1.14 Add End
  WHERE pv.vendor_id                   = pvsa.vendor_id
  AND   TRUNC( pvsa.creation_date )    BETWEEN ADD_MONTHS( gd_proc_date, -1 ) AND gd_proc_date
  AND   pvsa.vendor_id                 = abaua.vendor_id
  AND   pvsa.vendor_site_id            = abaua.vendor_site_id
  AND   abaua.external_bank_account_id = abaa.bank_account_id
  AND   abaa.bank_branch_id            = abb.bank_branch_id
  AND   ( pvsa.inactive_date           IS NULL  OR pvsa.inactive_date >= gd_pay_date )
  AND   pvsa.attribute4                IN( cv_1, cv_2 )
  AND   abaua.primary_flag             = cv_yes
  AND   ( gd_pay_date                 >= abaua.start_date  OR abaua.start_date IS NULL )
  AND   ( gd_pay_date                 <= abaua.end_date    OR abaua.end_date   IS NULL )
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  AND    pvsa.org_id                   = TO_NUMBER( gt_prof_org_id )
  AND    abaua.org_id                  = TO_NUMBER( gt_prof_org_id )
  AND    abaa.org_id                   = TO_NUMBER( gt_prof_org_id )
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Ver.1.14 Add Start
  AND    xbdciv.company_code_bd = gv_company_code                          -- パラメータ.会社コード
  AND    xbdciv.set_of_books_id = gt_set_of_books_id                       -- GL会計帳簿ID
  AND    xbdciv.dept_code       = pvsa.attribute5                          -- 担当拠点
  AND    gd_proc_date BETWEEN NVL(xbdciv.comp_start_date, gd_proc_date)    -- FB作成実行日（業務日付）
                          AND NVL(xbdciv.comp_end_date,   gd_proc_date)
-- Ver.1.14 Add End
  ORDER BY pv.segment1 ASC;
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi DELETE START
--  bac_fb_line_rec  bac_fb_line_cur%ROWTYPE;
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi DELETE END
  -- FB作成明細データ（本振用FBデータ作成処理）
  CURSOR fb_line_cur
  IS
-- Start 2009/04/27 Ver_1.2 T1_0817 M.Hiruta
--  SELECT pv.attribute5                                   AS base_code                -- 拠点コード
  SELECT pvsa.attribute5                                 AS base_code                -- 拠点コード
-- End   2009/04/27 Ver_1.2 T1_0817 M.Hiruta
        ,xbb.supplier_code                               AS supplier_code            -- 仕入先コード
        ,xbb.supplier_site_code                          AS supplier_site_code       -- 仕入先サイトコード
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--        ,SUM( xbb.backmargin )                           AS backmargin               -- 販売手数料
--        ,SUM( xbb.backmargin_tax )                       AS backmargin_tax           -- 販売手数料消費税額
--        ,SUM( xbb.electric_amt )                         AS electric_amt             -- 電気料
--        ,SUM( xbb.electric_amt_tax )                     AS electric_amt_tax         -- 電気料消費税額
--        ,SUM( xbb.backmargin + xbb.backmargin_tax +
--              xbb.electric_amt + xbb.electric_amt_tax )  AS trns_amt                 -- 振込額
-- Ver.1.12 MOD START
--        ,SUM( xbb.expect_payment_amt_tax )               AS trns_amt                 -- 振込額
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
        ,xxcok_common_pkg.recalc_pay_amt_f(                       -- [支払金額再計算ファンクション]
           MAX(pvsa.attribute4)                                   -- 支払区分
         , NVL(MAX(xbbs.tax_calc_kbn), cv_tax_calc_kbn_line)      -- 税計算区分 ※NULLの場合:明細単位
         , NVL(MAX(pvsa.attribute6), cv_tax_kbn_with_tax)         -- 税区分     ※NULLの場合:税込み
         , cv_tax_rounding_rule_down                              -- 端数処理区分
         , gt_prof_bm_tax                                         -- 税率
         , NVL(SUM(xbb.backmargin + xbb.electric_amt), 0)         -- 支払金額（税抜）   <= 販売手数料 + 電気料
         , NVL(SUM(xbb.backmargin_tax + xbb.electric_amt_tax), 0) -- 支払金額（消費税） <= 販売手数料（消費税額） + 電気料（消費税額）
         , NVL(SUM(xbb.expect_payment_amt_tax), 0)                -- 支払金額（税込）   <= 支払予定額（税込）
         , cv_get_target_amt_with_tax                             -- 取得対象金額
         )                                               AS trns_amt                 -- 振込額
-- Ver.1.12 MOD END
        ,pvsa.bank_charge_bearer                         AS bank_charge_bearer       -- 銀行手数料負担者
        ,abb.bank_number                                 AS bank_number              -- 銀行番号
        ,abb.bank_name_alt                               AS bank_name_alt            -- 銀行名カナ
        ,abb.bank_num                                    AS bank_num                 -- 銀行支店番号
        ,abb.bank_branch_name_alt                        AS bank_branch_name_alt     -- 銀行支店名カナ
        ,abaa.bank_account_type                          AS bank_account_type        -- 預金種別
        ,abaa.bank_account_num                           AS bank_account_num         -- 銀行口座番号
        ,abaa.account_holder_name_alt                    AS account_holder_name_alt  -- 口座名義人カナ
-- Ver.1.14 Add Start
        ,xbdciv.company_code_bd                          AS company_code             -- 会社コード
-- Ver.1.14 Add End
  FROM   xxcok_backmargin_balance      xbb                                           -- 販手残高テーブル
-- Ver.1.12 ADD START
        ,xxcok_bm_balance_snap         xbbs                                          -- 販手残高テーブルスナップショット
-- Ver.1.12 ADD END
        ,po_vendors                    pv                                            -- 仕入先マスタ
        ,po_vendor_sites_all           pvsa                                          -- 仕入先サイトマスタ
        ,ap_bank_account_uses_all      abaua                                         -- 銀行口座使用情報
        ,ap_bank_accounts_all          abaa                                          -- 銀行口座マスタ
        ,ap_bank_branches              abb                                           -- 銀行支店マスタ
-- Ver.1.14 Add Start
        ,xxcfr_bd_dept_comp_info_v     xbdciv                                        -- 担当拠点会社情報ビュー
-- Ver.1.14 Add End
  WHERE  xbb.fb_interface_status        = cv_zero
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD START
  AND    xbb.gl_interface_status        = cv_zero
  AND    xbb.amt_fix_status             = cv_1
  AND    xbb.payment_amt_tax            = cn_zero
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD END
  AND    xbb.resv_flag                 IS NULL
  AND    xbb.expect_payment_date       <= gd_pay_date
  AND    xbb.supplier_code              = pv.segment1
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE START
--  AND    xbb.supplier_site_code         = pvsa.vendor_site_code
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE END
  AND    pvsa.hold_all_payments_flag    = cv_no
  AND    ( pvsa.inactive_date          IS NULL OR pvsa.inactive_date >= gd_pay_date )
  AND    pvsa.attribute4               IN( cv_1, cv_2 )
  AND    pv.vendor_id                   = pvsa.vendor_id
  AND    pvsa.vendor_id                 = abaua.vendor_id
  AND    pvsa.vendor_site_id            = abaua.vendor_site_id
  AND    abaua.external_bank_account_id = abaa.bank_account_id
  AND    abaa.bank_branch_id            = abb.bank_branch_id
  AND    abaua.primary_flag             = cv_yes
  AND    ( gd_pay_date                 >= abaua.start_date  OR abaua.start_date IS NULL )
  AND    ( gd_pay_date                 <= abaua.end_date    OR abaua.end_date   IS NULL )
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  AND    pvsa.org_id                    = TO_NUMBER( gt_prof_org_id )
  AND    abaua.org_id                   = TO_NUMBER( gt_prof_org_id )
  AND    abaa.org_id                    = TO_NUMBER( gt_prof_org_id )
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Ver.1.12 ADD START
  AND    xbb.bm_balance_id              = xbbs.bm_balance_id(+)            -- 販手残高ID
  AND    xbbs.snapshot_create_ym(+)     = TO_CHAR(gd_proc_date, 'YYYYMM')  -- スナップショット作成年月   = 業務日付の年月
  AND    xbbs.snapshot_timing(+)        = cv_snapshot_timing_2_bd          -- スナップショットタイミング = 2営
-- Ver.1.12 ADD END
-- Ver.1.14 Add Start
  AND    xbdciv.company_code_bd = gv_company_code                          -- パラメータ.会社コード
  AND    xbdciv.set_of_books_id = gt_set_of_books_id                       -- GL会計帳簿ID
  AND    xbdciv.dept_code       = pvsa.attribute5                          -- 担当拠点
  AND    gd_proc_date BETWEEN NVL(xbdciv.comp_start_date, gd_proc_date)    -- FB作成実行日（業務日付）
                          AND NVL(xbdciv.comp_end_date,   gd_proc_date)
-- Ver.1.14 Add End
-- Start 2009/04/27 Ver_1.2 T1_0817 M.Hiruta
--  GROUP BY pv.attribute5
  GROUP BY pvsa.attribute5
-- End   2009/04/27 Ver_1.2 T1_0817 M.Hiruta
          ,xbb.supplier_code
          ,xbb.supplier_site_code
          ,pvsa.bank_charge_bearer
          ,abb.bank_number
          ,abb.bank_name_alt
          ,abb.bank_num
          ,abb.bank_branch_name_alt
          ,abaa.bank_account_type
          ,abaa.bank_account_num
          ,abaa.account_holder_name_alt
-- Ver.1.14 Add Start
          ,xbdciv.company_code_bd
-- Ver.1.14 Add End
-- Start 2009/04/27 Ver_1.2 T1_0817 M.Hiruta
--  ORDER BY pv.attribute5 ASC
  ORDER BY pvsa.attribute5 ASC
-- End   2009/04/27 Ver_1.2 T1_0817 M.Hiruta
          ,xbb.supplier_code  ASC;
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi DELETE START
--  fb_line_rec  fb_line_cur%ROWTYPE;
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi DELETE END
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
  -- FB作成対象外ダミー口座取得カーソル
  CURSOR dmy_acct_cur
  IS
  SELECT flv.attribute1  AS  bank_number         --銀行番号
        ,flv.attribute2  AS  bank_num            --支店番号
        ,flv.attribute3  AS  bank_account_type   --口座種別
        ,flv.attribute4  AS  bank_account_num    --口座番号
  FROM   fnd_lookup_values flv
  WHERE  flv.lookup_type  = cv_lookup_type_fb_not
  AND    flv.enabled_flag = cv_yes
  AND    gd_pay_date BETWEEN NVL(flv.start_date_active, gd_pay_date)
                         AND NVL(flv.end_date_active, gd_pay_date)
  AND    flv.language     = USERENV('LANG')
  ;
  TYPE g_dmy_acct_ttype IS TABLE OF dmy_acct_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_dmy_acct_tab       g_dmy_acct_ttype;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
  --================================
  -- グローバル・TABLE型
  --================================
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi DELETE START
--  -- FB作成明細データ（振込口座事前チェック用FB作成処理）
--  TYPE bac_fb_line_ttpye IS TABLE OF bac_fb_line_cur%ROWTYPE
--  INDEX BY BINARY_INTEGER;
--  gt_bac_fb_line_tab    bac_fb_line_ttpye;
--  -- FB作成明細データ（本振用FBデータ作成処理）
--  TYPE fb_line_ttpye IS TABLE OF fb_line_cur%ROWTYPE
--  INDEX BY BINARY_INTEGER;
--  gt_fb_line_tab        fb_line_ttpye;
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi DELETE END
  --=================================
  -- 共通例外
  --=================================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** ロック取得共通例外 ***
  global_lock_err_expt      EXCEPTION;
  --=================================
  -- プラグマ
  --=================================
  PRAGMA EXCEPTION_INIT( global_api_others_expt,-20000 );
  PRAGMA EXCEPTION_INIT( global_lock_err_expt, -54 );
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ
-- Ver.1.14 Add Start
    ,iv_company_code IN  VARCHAR2   -- パラメータ：会社コード
-- Ver.1.14 Add End
    ,iv_proc_type  IN  VARCHAR2     -- 処理パラメータ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name      CONSTANT       VARCHAR2(100) := 'init';     -- プログラム名
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE START
--    cn_zero          CONSTANT       NUMBER        := 0;          -- 数値:0
--    cn_1             CONSTANT       NUMBER        := 1;          -- 数値:1
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE END
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;          -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;          -- リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;          -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000) DEFAULT NULL;          -- メッセージ
    ld_close_date    DATE;                                 -- 締め日
    ld_pay_date      DATE;                                 -- 支払日
    lv_profile       VARCHAR2(35)   DEFAULT NULL;          -- プロファイル
    lb_retcode       BOOLEAN;                              -- リターン・コード
    --===============================
    -- ローカル例外
    --===============================
    --*** 業務処理日付取得例外 ***
    no_process_date_expt     EXCEPTION;
    --*** プロファイルの取得例外 ***
    no_profile_expt          EXCEPTION;
    --*** 値セット取得例外 ***
    values_err_expt          EXCEPTION;
    --*** 支払日取得例外 ***
    no_pay_date_expt         EXCEPTION;
-- Ver.1.14 Add Start
    --*** 初期処理例外 ***
    init_expt                EXCEPTION;
-- Ver.1.14 Add End
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --==========================================================
    --コンカレントプログラム入力項目をメッセージ出力する
    --==========================================================
-- Ver.1.14 Add Start
    -- パラメータ：会社コードの出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok
                   ,iv_name         => cv_msg_cok_10878
                   ,iv_token_name1  => cv_token_company_code
                   ,iv_token_value1 => iv_company_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG         -- 出力区分
                   ,iv_message  => lv_out_msg           -- メッセージ
                   ,in_new_line => 0                    -- 改行
                  );
    -- パラメータ：実行区分の出力
-- Ver.1.14 Add End
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok
                   ,iv_name         => cv_msg_cok_00044
                   ,iv_token_name1  => cv_token_proc_type
                   ,iv_token_value1 => iv_proc_type
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG         -- 出力区分
                   ,iv_message  => lv_out_msg           -- メッセージ
                   ,in_new_line => 1                    -- 改行
                  );
    --==========================================================
    --業務処理日付取得
    --==========================================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF( gd_proc_date IS NULL ) THEN
      -- 業務処理日付取得エラーメッセージ
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_00028
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      RAISE no_process_date_expt;
    END IF;
    --==========================================================
    --カスタム・プロファイルの取得
    --==========================================================
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
--    gt_prof_bm_acc_number       := FND_PROFILE.VALUE( cv_prof_bm_acc_number );        -- 銀行口座番号
--    gt_prof_bm_bra_number       := FND_PROFILE.VALUE( cv_prof_bm_bra_number );        -- 銀行支店番号
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
    gt_prof_bm_request_code     := FND_PROFILE.VALUE( cv_prof_bm_request_code );      -- 依頼人コード
    gt_prof_trans_fee_criterion := FND_PROFILE.VALUE( cv_prof_trans_criterion );      -- 振込額の基準金額
    gt_prof_less_fee_criterion  := FND_PROFILE.VALUE( cv_prof_less_fee_criterion );   -- 銀行手数料額(基準未満)
    gt_prof_more_fee_criterion  := FND_PROFILE.VALUE( cv_prof_more_fee_criterion );   -- 銀行手数料額(基準以上)
    gt_prof_fb_term_name        := FND_PROFILE.VALUE( cv_prof_fb_term_name );         -- FB支払条件
    gt_prof_bm_tax              := FND_PROFILE.VALUE( cv_prof_bm_tax );               -- 消費税率
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    gt_prof_org_id              := FND_PROFILE.VALUE( cv_prof_org_id );               -- 営業単位
    gt_prof_bank_trns_fee_we    := FND_PROFILE.VALUE( cv_prof_bank_trns_fee_we );     -- 振込手数料_当方
    gt_prof_bank_trns_fee_ctpty := FND_PROFILE.VALUE( cv_prof_bank_trns_fee_ctpty );  -- 振込手数料_相手方
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
    gt_prof_acc_type_internal   := FND_PROFILE.VALUE( cv_prof_acc_type_internal );    -- 振込手数料_当社_口座使用
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
-- Ver.1.14 Add Start
    gt_set_of_books_id          := FND_PROFILE.VALUE( cv_sob_id );                    -- GL会計帳簿ID
-- Ver.1.14 Add End
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
--    -- プロファイル値取得エラー
--    IF( gt_prof_bm_acc_number IS NULL ) THEN
--      lv_profile := cv_prof_bm_acc_number;
--      RAISE no_profile_expt;
--    END IF;
--    -- プロファイル値取得エラー
--    IF( gt_prof_bm_bra_number IS NULL ) THEN
--      lv_profile := cv_prof_bm_bra_number;
--      RAISE no_profile_expt;
--    END IF;
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
    -- プロファイル値取得エラー
    IF( gt_prof_bm_request_code IS NULL ) THEN
      lv_profile := cv_prof_bm_request_code;
      RAISE no_profile_expt;
    END IF;
    -- プロファイル値取得エラー
    IF( gt_prof_trans_fee_criterion IS NULL ) THEN
      lv_profile := cv_prof_trans_criterion;
      RAISE no_profile_expt;
    END IF;
    -- プロファイル値取得エラー
    IF( gt_prof_less_fee_criterion IS NULL ) THEN
      lv_profile := cv_prof_less_fee_criterion;
      RAISE no_profile_expt;
    END IF;
    -- プロファイル値取得エラー
    IF( gt_prof_more_fee_criterion IS NULL ) THEN
      lv_profile := cv_prof_more_fee_criterion;
      RAISE no_profile_expt;
    END IF;
    -- プロファイル値取得エラー
    IF( gt_prof_fb_term_name IS NULL ) THEN
      lv_profile := cv_prof_fb_term_name;
      RAISE no_profile_expt;
    END IF;
    -- プロファイル値取得エラー
    IF( gt_prof_bm_tax IS NULL ) THEN
      lv_profile := cv_prof_bm_tax;
      RAISE no_profile_expt;
    END IF;
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    -- プロファイル値取得エラー
    IF( gt_prof_org_id IS NULL ) THEN
      lv_profile := cv_prof_org_id;
      RAISE no_profile_expt;
    END IF;
    -- プロファイル値取得エラー
    IF( gt_prof_bank_trns_fee_we IS NULL ) THEN
      lv_profile := cv_prof_bank_trns_fee_we;
      RAISE no_profile_expt;
    END IF;
    -- プロファイル値取得エラー
    IF( gt_prof_bank_trns_fee_ctpty IS NULL ) THEN
      lv_profile := cv_prof_bank_trns_fee_ctpty;
      RAISE no_profile_expt;
    END IF;
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
    -- プロファイル値取得エラー
    IF( gt_prof_acc_type_internal IS NULL ) THEN
      lv_profile := cv_prof_acc_type_internal;
      RAISE no_profile_expt;
    END IF;
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
-- Ver.1.14 Add Start
    -- プロファイル値取得エラー
    IF( gt_set_of_books_id IS NULL ) THEN
      lv_profile := cv_sob_id;
      RAISE no_profile_expt;
    END IF;
--
    -- 会社コードチェック
    BEGIN
      SELECT company_code AS company_code INTO gv_company_code
      FROM   xxcfo_company_v
      WHERE  company_code  = iv_company_code;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        gv_company_code := NULL;
      WHEN OTHERS THEN
        gv_company_code := NULL;
    END;
    IF( gv_company_code IS NULL ) THEN
      -- 会社コード取得エラーメッセージ
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_10879
                     ,iv_token_name1  => cv_token_company_code
                     ,iv_token_value1 => iv_company_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      RAISE init_expt;
    END IF;
-- Ver.1.14 Add End
    --=========================================================
    --当月の支払日を取得する
    --=========================================================
    -- 締め・支払日取得
    xxcok_common_pkg.get_close_date_p(
      ov_errbuf     => lv_errbuf
     ,ov_retcode    => lv_retcode
     ,ov_errmsg     => lv_errmsg
     ,iv_pay_cond   => gt_prof_fb_term_name
     ,od_close_date => ld_close_date
     ,od_pay_date   => ld_pay_date
    );
    IF( lv_retcode = cv_status_error ) THEN
      -- 締め・支払日取得エラーメッセージ
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_00036
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      RAISE no_pay_date_expt;
    END IF;
    -- 営業日取得
    gd_pay_date := xxcok_common_pkg.get_operating_day_f(
                     id_proc_date => ld_pay_date
                    ,in_days      => cn_zero
                    ,in_proc_type => cn_1
                   );
--
    BEGIN
      --=========================================================
      -- 種別コードを取得する
      --=========================================================
      SELECT ffv.attribute1     AS type_code   -- 種別コード
      INTO   gt_values_type_code               -- 種別コード
      FROM   fnd_flex_value_sets   ffvs        -- 値セット
            ,fnd_flex_values       ffv         -- 値セット値
      WHERE ffv.value_category     = cv_value_cok_fb_proc_type
      AND   ffvs.flex_value_set_id = ffv.flex_value_set_id
      AND   ffv.flex_value         = iv_proc_type
      AND   ffv.enabled_flag       = cv_yes
      AND   gd_proc_date BETWEEN NVL( ffv.start_date_active, gd_proc_date )
                         AND     NVL( ffv.end_date_active, gd_proc_date );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok
                       ,iv_name         => cv_msg_cok_00014
                       ,iv_token_name1  => cv_token_flex_value_set
                       ,iv_token_value1 => cv_value_cok_fb_proc_type
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG       -- 出力区分
                       ,iv_message  => lv_out_msg         -- メッセージ
                       ,in_new_line => 0                  -- 改行
                      );
      RAISE values_err_expt;
    END;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
    --=========================================================
    --FB作成対象外ダミー口座を取得する
    --=========================================================
    OPEN dmy_acct_cur;
    FETCH dmy_acct_cur BULK COLLECT INTO g_dmy_acct_tab;
    CLOSE dmy_acct_cur;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
--
  EXCEPTION
-- Ver.1.14 Add Start
    WHEN init_expt THEN
    --*** 初期処理例外 ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
-- Ver.1.14 Add End
    WHEN no_process_date_expt THEN
      -- *** 業務処理日付取得例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN no_profile_expt THEN
      -- *** プロファイル取得例外ハンドラ ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_00003
                     ,iv_token_name1  => cv_token_profile
                     ,iv_token_value1 => lv_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN no_pay_date_expt THEN
      -- *** 締め・支払日取得例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN values_err_expt THEN
      -- *** 値セット取得例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END init;
--
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi DELETE START
--  /**********************************************************************************
--   * Procedure Name   : get_bank_acct_chk_fb_line
--   * Description      : FB作成明細データの取得（振込口座事前チェック用FB作成処理）(A-2)
--   ***********************************************************************************/
--  PROCEDURE get_bank_acct_chk_fb_line(
--     ov_errbuf  OUT VARCHAR2            -- エラー・メッセージ
--    ,ov_retcode OUT VARCHAR2            -- リターン・コード
--    ,ov_errmsg  OUT VARCHAR2            -- ユーザー・エラー・メッセージ
--  )
--  IS
--    --===============================
--    -- ローカル定数
--    --===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bank_acct_chk_fb_line'; -- FB作成明細データの取得
--    --===============================
--    -- ローカル変数
--    --===============================
--    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;          -- エラー・メッセージ
--    lv_retcode    VARCHAR2(1)    DEFAULT NULL;          -- リターン・コード
--    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;          -- ユーザー・エラー・メッセージ
--    lv_out_msg    VARCHAR2(2000) DEFAULT NULL;          -- メッセージ
--    lb_retcode    BOOLEAN;                              -- リターン・コード
--    --===============================
--    -- ローカル例外
--    --===============================
--    --*** データ取得例外 ***
--    no_data_expt  EXCEPTION;
----
--  BEGIN
--    -- ステータス初期化
--    ov_retcode := cv_status_normal;
----
--    OPEN bac_fb_line_cur;
--      FETCH bac_fb_line_cur BULK COLLECT INTO gt_bac_fb_line_tab;
--    CLOSE bac_fb_line_cur;
--    --==================================================
--    -- FB作成明細情報取得エラー
--    --==================================================
--    IF( gt_bac_fb_line_tab.COUNT = 0 ) THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application => cv_appli_xxcok
--                      ,iv_name        => cv_msg_cok_10254
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG       -- 出力区分
--                     ,iv_message  => lv_out_msg         -- メッセージ
--                     ,in_new_line => 1                  -- 改行
--                    );
--      RAISE no_data_expt;
--    END IF;
----
--  EXCEPTION
--    WHEN no_data_expt THEN
--    -- *** FB作成明細情報取得例外ハンドラ ****
--      ov_errmsg  := lv_errmsg;
--      ov_retcode := cv_status_normal;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END get_bank_acct_chk_fb_line;
----
--  /**********************************************************************************
--   * Procedure Name   : get_fb_line
--   * Description      : FB作成明細データの取得（本振用FBデータ作成処理）(A-3)
--   ***********************************************************************************/
--  PROCEDURE get_fb_line(
--     ov_errbuf  OUT VARCHAR2       -- エラー・メッセージ
--    ,ov_retcode OUT VARCHAR2       -- リターン・コード
--    ,ov_errmsg  OUT VARCHAR2       -- ユーザー・エラー・メッセージ
--  )
--  IS
--    --===============================
--    -- ローカル定数
--    --===============================
--    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_fb_line'; -- プログラム名
--    --================================
--    -- ローカル変数
--    --================================
--    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
--    lv_retcode   VARCHAR2(1)    DEFAULT NULL;              -- リターン・コード
--    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--    lv_out_msg   VARCHAR2(2000) DEFAULT NULL;              -- メッセージ
--    lb_retcode   BOOLEAN;                                  -- リターン・コード
--    --===============================
--    -- ローカル例外
--    --===============================
--    --*** データ取得例外 ***
--    no_data_expt  EXCEPTION;
----
--  BEGIN
--    -- ステータス初期化
--    ov_retcode := cv_status_normal;
--    --
--    OPEN fb_line_cur;
--      FETCH fb_line_cur BULK COLLECT INTO gt_fb_line_tab;
--    CLOSE fb_line_cur;
--    --======================================================
--    -- FB作成明細情報取得エラー
--    --======================================================
--    IF( gt_fb_line_tab.COUNT = 0 ) THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application => cv_appli_xxcok
--                      ,iv_name        => cv_msg_cok_10254
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG       -- 出力区分
--                     ,iv_message  => lv_out_msg         -- メッセージ
--                     ,in_new_line => 1                  -- 改行
--                    );
--      RAISE no_data_expt;
--    END IF;
----
--  EXCEPTION
--    WHEN no_data_expt THEN
--      -- *** FB作成明細情報取得例外ハンドラ ****
--      ov_errmsg  := lv_errmsg;
--      ov_retcode := cv_status_normal;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END get_fb_line;
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi DELETE END
--
  /**********************************************************************************
   * Procedure Name   : get_fb_header
   * Description      : FB作成ヘッダーデータの取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_fb_header(
     ov_errbuf                  OUT VARCHAR2                                            -- エラー・メッセージ
    ,ov_retcode                 OUT VARCHAR2                                            -- リターン・コード
    ,ov_errmsg                  OUT VARCHAR2                                            -- ユーザー・エラー・メッセージ
    ,ot_bank_number             OUT ap_bank_branches.bank_number%TYPE                   -- 銀行番号
    ,ot_bank_name_alt           OUT ap_bank_branches.bank_name_alt%TYPE                 -- 銀行名カナ
    ,ot_bank_num                OUT ap_bank_branches.bank_num%TYPE                      -- 銀行支店番号
    ,ot_bank_branch_name_alt    OUT ap_bank_branches.bank_branch_name_alt%TYPE          -- 銀行支店名カナ
    ,ot_bank_account_type       OUT ap_bank_accounts_all.bank_account_type%TYPE         -- 預金種別
    ,ot_bank_account_num        OUT ap_bank_accounts_all.bank_account_num%TYPE          -- 銀行口座番号
    ,ot_account_holder_name_alt OUT ap_bank_accounts_all.account_holder_name_alt%TYPE   -- 口座名義人カナ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fb_header';                            -- プログラム名
    --================================
    -- ローカル変数
    --================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;                            -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;                            -- リターン・コード
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;                            -- ユーザー・エラー・メッセージ
    lv_out_msg                  VARCHAR2(2000) DEFAULT NULL;                            -- メッセージ
    lb_retcode                  BOOLEAN;                                                -- リターン・コード
    lt_bank_number              ap_bank_branches.bank_number%TYPE;                      -- 銀行番号
    lt_bank_name_alt            ap_bank_branches.bank_name_alt%TYPE;                    -- 銀行名カナ
    lt_bank_num                 ap_bank_branches.bank_num%TYPE;                         -- 銀行支店番号
    lt_bank_branch_name_alt     ap_bank_branches.bank_branch_name_alt%TYPE;             -- 銀行支店名カナ
    lt_bank_account_type        ap_bank_accounts_all.bank_account_type%TYPE;            -- 預金種別
    lt_bank_account_num         ap_bank_accounts_all.bank_account_num%TYPE;             -- 銀行口座番号
    lt_account_holder_name_alt  ap_bank_accounts_all.account_holder_name_alt%TYPE;      -- 口座名義人カナ
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --=========================================
    -- FB作成ヘッダーデータの取得(A-4)
    --=========================================
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta REPAIR
--    SELECT  abb.bank_number               AS  bank_number             -- 銀行番号
--           ,abb.bank_name_alt             AS  bank_name_alt           -- 銀行名カナ
--           ,abb.bank_num                  AS  bank_num                -- 銀行支店番号
--           ,abb.bank_branch_name_alt      AS  bank_branch_name_alt    -- 銀行支店名カナ
--           ,abaa.bank_account_type        AS  bank_account_type       -- 預金種別
--           ,abaa.bank_account_num         AS  bank_account_num        -- 銀行口座番号
--           ,abaa.account_holder_name_alt  AS  account_holder_name_alt -- 口座名義人カナ
--    INTO    lt_bank_number                                            -- 銀行番号
--           ,lt_bank_name_alt                                          -- 銀行名カナ
--           ,lt_bank_num                                               -- 銀行支店番号
--           ,lt_bank_branch_name_alt                                   -- 銀行支店名カナ
--           ,lt_bank_account_type                                      -- 預金種別
--           ,lt_bank_account_num                                       -- 銀行口座番号
--           ,lt_account_holder_name_alt                                -- 口座名義人カナ
--    FROM    ap_bank_accounts_all          abaa                        -- 銀行口座マスタ
--           ,ap_bank_branches              abb                         -- 銀行支店マスタ
--    WHERE  abaa.bank_account_num = gt_prof_bm_acc_number
--    AND    abaa.bank_branch_id   = abb.bank_branch_id
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    AND    abaa.org_id           = TO_NUMBER( gt_prof_org_id )
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    AND    abb.bank_num          = gt_prof_bm_bra_number;
    SELECT  abb.bank_number               AS  bank_number             -- 銀行番号
           ,abb.bank_name_alt             AS  bank_name_alt           -- 銀行名カナ
           ,abb.bank_num                  AS  bank_num                -- 銀行支店番号
           ,abb.bank_branch_name_alt      AS  bank_branch_name_alt    -- 銀行支店名カナ
           ,abaa.bank_account_type        AS  bank_account_type       -- 預金種別
           ,abaa.bank_account_num         AS  bank_account_num        -- 銀行口座番号
           ,abaa.account_holder_name_alt  AS  account_holder_name_alt -- 口座名義人カナ
    INTO    lt_bank_number                                            -- 銀行番号
           ,lt_bank_name_alt                                          -- 銀行名カナ
           ,lt_bank_num                                               -- 銀行支店番号
           ,lt_bank_branch_name_alt                                   -- 銀行支店名カナ
           ,lt_bank_account_type                                      -- 預金種別
           ,lt_bank_account_num                                       -- 銀行口座番号
           ,lt_account_holder_name_alt                                -- 口座名義人カナ
    FROM    ap_bank_accounts_all          abaa                        -- 銀行口座マスタ
           ,ap_bank_branches              abb                         -- 銀行支店マスタ
           ,fnd_lookup_values             flv                         -- 参照コード
    WHERE  abaa.bank_branch_id    = abb.bank_branch_id
    AND    abb.bank_number        = flv.attribute1            -- 銀行番号
    AND    abb.bank_num           = flv.attribute2            -- 銀行支店番号
    AND    abaa.account_type      = gt_prof_acc_type_internal -- 口座使用
    AND    abaa.bank_account_type = flv.attribute3            -- 口座種別
    AND    abaa.bank_account_num  = flv.attribute4            -- 銀行口座番号
    AND    abaa.org_id            = TO_NUMBER( gt_prof_org_id )
    AND    flv.lookup_type        = cv_lookup_type_bank
    AND    flv.lookup_code        = cv_lookup_code_bank
    AND    flv.enabled_flag       = cv_yes
    AND    gd_proc_date           BETWEEN flv.start_date_active
                                  AND     NVL( flv.end_date_active, gd_proc_date )
    AND    flv.language           = USERENV('LANG');
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta REPAIR
--
    ot_bank_number             := lt_bank_number;                    -- 銀行番号
    ot_bank_name_alt           := lt_bank_name_alt;                  -- 銀行名カナ
    ot_bank_num                := lt_bank_num;                       -- 銀行支店番号
    ot_bank_branch_name_alt    := lt_bank_branch_name_alt;           -- 銀行支店名カナ
    ot_bank_account_type       := lt_bank_account_type;              -- 預金種別
    ot_bank_account_num        := lt_bank_account_num;               -- 銀行口座番号
    ot_account_holder_name_alt := lt_account_holder_name_alt;        -- 口座名義人カナ
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** FB作成ヘッダー情報取得例外ハンドラ ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10255
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN
      -- *** FB作成ヘッダー情報重複例外ハンドラ ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10256
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_fb_header;
--
  /**********************************************************************************
   * Procedure Name   : storage_fb_header
   * Description      : FB作成ヘッダーデータの格納(A-5)
   ***********************************************************************************/
  PROCEDURE storage_fb_header(
     ov_errbuf                  OUT VARCHAR2                                            -- エラー・メッセージ
    ,ov_retcode                 OUT VARCHAR2                                            -- リターン・コード
    ,ov_errmsg                  OUT VARCHAR2                                            -- ユーザー・エラー・メッセージ
    ,ov_fb_header_data          OUT VARCHAR2                                            -- FB作成ヘッダーレコード
    ,it_bank_number             IN  ap_bank_branches.bank_number%TYPE                   -- 銀行番号
    ,it_bank_name_alt           IN  ap_bank_branches.bank_name_alt%TYPE                 -- 銀行名カナ
    ,it_bank_num                IN  ap_bank_branches.bank_num%TYPE                      -- 銀行支店番号
    ,it_bank_branch_name_alt    IN  ap_bank_branches.bank_branch_name_alt%TYPE          -- 銀行支店名カナ
    ,it_bank_account_type       IN  ap_bank_accounts_all.bank_account_type%TYPE         -- 預金種別
    ,it_bank_account_num        IN  ap_bank_accounts_all.bank_account_num%TYPE          -- 銀行口座番号
    ,it_account_holder_name_alt IN  ap_bank_accounts_all.account_holder_name_alt%TYPE   -- 口座名義人カナ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'storage_fb_header';   -- プログラム名
    cv_code_type   CONSTANT VARCHAR2(1)   := '0';                   -- コード区分
    cv_zero        CONSTANT VARCHAR2(1)   := '0';                   -- '0'
    cv_data_type   CONSTANT VARCHAR2(1)   := '1';                   -- データ区分
    --================================
    -- ローカル変数
    --================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;       -- リターン・コード
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lv_out_msg                  VARCHAR2(2000) DEFAULT NULL;       -- メッセージ
    lv_data_type                VARCHAR2(1)    DEFAULT NULL;       -- データ区分
    lv_type_code                VARCHAR2(2)    DEFAULT NULL;       -- 種別コード
    lv_code_type                VARCHAR2(1)    DEFAULT NULL;       -- コード区分
    lv_sc_client_code           VARCHAR2(10)   DEFAULT NULL;       -- 依頼人コード
    lv_client_name              VARCHAR2(40)   DEFAULT NULL;       -- 依頼人名
    lv_pay_date                 VARCHAR2(4)    DEFAULT NULL;       -- 振込指定日
    lv_bank_number              VARCHAR2(4)    DEFAULT NULL;       -- 仕向金融機関番号
    lv_bank_name_alt            VARCHAR2(15)   DEFAULT NULL;       -- 仕向金融機関名
    lv_bank_num                 VARCHAR2(3)    DEFAULT NULL;       -- 仕向支店番号
    lv_bank_branch_name_alt     VARCHAR2(15)   DEFAULT NULL;       -- 仕向支店名
    lv_bank_account_type        VARCHAR2(1)    DEFAULT NULL;       -- 預金種目（依頼人）
    lv_bank_account_num         VARCHAR2(7)    DEFAULT NULL;       -- 口座番号（依頼人）
    lv_dummy                    VARCHAR2(17)   DEFAULT NULL;       -- ダミー
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
--
    lv_data_type            := cv_data_type;                                              -- データ区分
    lv_type_code            := LPAD( gt_values_type_code, 2, cv_zero );                   -- 種別コード
    lv_code_type            := cv_code_type;                                              -- コード区分
    lv_sc_client_code       := LPAD( gt_prof_bm_request_code, 10, cv_zero );              -- 依頼人コード
    lv_client_name          := RPAD( NVL( it_account_holder_name_alt, cv_space ), 40 );   -- 依頼人名
    lv_pay_date             := TO_CHAR( gd_pay_date, 'MMDD' );                            -- 振込指定日
    lv_bank_number          := LPAD( NVL( it_bank_number, cv_zero ), 4, cv_zero );        -- 仕向金融機関番号
    lv_bank_name_alt        := RPAD( NVL( it_bank_name_alt, cv_space ), 15 );             -- 仕向金融機関名
    lv_bank_num             := LPAD( NVL( it_bank_num, cv_zero ), 3, cv_zero );           -- 仕向支店番号
    lv_bank_branch_name_alt := RPAD( NVL( it_bank_branch_name_alt, cv_space ), 15 );      -- 仕向支店名
    lv_bank_account_type    := NVL( it_bank_account_type, cv_zero );                      -- 預金種目(依頼人)
    lv_bank_account_num     := LPAD( NVL( it_bank_account_num, cv_zero ), 7, cv_zero );   -- 口座番号(依頼人)
    lv_dummy                := LPAD( cv_space, 17, cv_space );                            -- ダミー
--
    ov_fb_header_data       := lv_data_type            ||                     -- データ区分
                               lv_type_code            ||                     -- 種別コード
                               lv_code_type            ||                     -- コード区分
                               lv_sc_client_code       ||                     -- 依頼人コード
                               lv_client_name          ||                     -- 依頼人名
                               lv_pay_date             ||                     -- 振込指定日
                               lv_bank_number          ||                     -- 仕向金融機関番号
                               lv_bank_name_alt        ||                     -- 仕向金融機関名
                               lv_bank_num             ||                     -- 仕向支店番号
                               lv_bank_branch_name_alt ||                     -- 仕向支店名
                               lv_bank_account_type    ||                     -- 預金種目(依頼人)
                               lv_bank_account_num     ||                     -- 口座番号(依頼人)
                               lv_dummy;                                      -- ダミー
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END storage_fb_header;
--
  /**********************************************************************************
   * Procedure Name   : storage_bank_acct_chk_fb_line
   * Description      : FB作成明細データの格納（振込口座事前チェック用FB作成処理）(A-7)
   ***********************************************************************************/
  PROCEDURE storage_bank_acct_chk_fb_line(
     ov_errbuf       OUT VARCHAR2           -- エラー・メッセージ
    ,ov_retcode      OUT VARCHAR2           -- リターン・コード
    ,ov_errmsg       OUT VARCHAR2           -- ユーザー・エラー・メッセージ
    ,ov_fb_line_data OUT VARCHAR2           -- FB作成明細レコード
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--    ,in_cnt          IN  NUMBER             -- 索引カウンタ
    ,i_bac_fb_line_rec IN  bac_fb_line_cur%ROWTYPE  -- FB作成明細データ
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'storage_bank_acct_chk_fb_line';  -- FB作成明細データの格納
    cv_data_type       CONSTANT VARCHAR2(1)   := '2';                              -- '2' データ区分
    --=================================
    -- ローカル変数
    --=================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;         -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;         -- リターン・コード
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;         -- ユーザー・エラー・メッセージ
    --
    lv_data_type                VARCHAR2(1)    DEFAULT NULL;         -- データ区分
    lv_bank_number              VARCHAR2(4)    DEFAULT NULL;         -- 被仕向金融機関番号
    lv_bank_name_alt            VARCHAR2(15)   DEFAULT NULL;         -- 被仕向金融機関名
    lv_bank_num                 VARCHAR2(3)    DEFAULT NULL;         -- 被仕向支店番号
    lv_bank_branch_name_alt     VARCHAR2(15)   DEFAULT NULL;         -- 被仕向支店名
    lv_clearinghouse_no         VARCHAR2(4)    DEFAULT NULL;         -- 手形交換所番号
    lv_bank_account_type        VARCHAR2(1)    DEFAULT NULL;         -- 預金種目
    lv_bank_account_num         VARCHAR2(7)    DEFAULT NULL;         -- 口座番号
    lv_account_holder_name_alt  VARCHAR2(30)   DEFAULT NULL;         -- 受取人名
    lv_transfer_amount          VARCHAR2(17)   DEFAULT NULL;         -- 振込金額
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD START
--    lv_base_code                VARCHAR2(4)    DEFAULT NULL;         -- 拠点コード
--    lv_supplier_code            VARCHAR2(9)    DEFAULT NULL;         -- 仕入先コード
    lv_base_code                VARCHAR2(10)   DEFAULT NULL;         -- 拠点コード
    lv_supplier_code            VARCHAR2(10)   DEFAULT NULL;         -- 仕入先コード
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD END
    lv_dummy                    VARCHAR2(17)   DEFAULT NULL;         -- ダミー
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
--
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--    lv_data_type               := cv_data_type;                                                                      -- データ区分
--    lv_bank_number             := LPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_number, cv_zero ), 4, cv_zero );      -- 被仕向金融機関番号
--    lv_bank_name_alt           := RPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_name_alt, cv_space ), 15 );           -- 被仕向金融機関名
--    lv_bank_num                := LPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_num, cv_zero ), 3, cv_zero );         -- 被仕向支店番号
--    lv_bank_branch_name_alt    := RPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_branch_name_alt, cv_space ), 15 );    -- 被仕向支店名
--    lv_clearinghouse_no        := LPAD( cv_space, 4, cv_space );                                                     -- 手形交換所番号
--    lv_bank_account_type       := NVL( gt_bac_fb_line_tab( in_cnt ).bank_account_type, cv_zero );                    -- 預金種目
--    lv_bank_account_num        := LPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_account_num, cv_zero ), 7, cv_zero ); -- 口座番号
--    lv_account_holder_name_alt := RPAD( NVL( gt_bac_fb_line_tab( in_cnt ).account_holder_name_alt, cv_space ), 30 ); -- 受取人名
--    lv_transfer_amount         := LPAD( cv_zero, 10, cv_zero );                                                      -- 振込金額
--    lv_base_code               := LPAD( cv_space, 4, cv_space );                                                     -- 拠点コード
--    lv_supplier_code           := LPAD( NVL( gt_bac_fb_line_tab( in_cnt ).segment1, cv_space ), 9 );                 -- 仕入先コード
--    lv_dummy                   := LPAD( cv_space, 17, cv_space );                                                    -- ダミー
    lv_data_type               := cv_data_type;                                                                      -- データ区分
    lv_bank_number             := LPAD( NVL( i_bac_fb_line_rec.bank_number, cv_zero ), 4, cv_zero );      -- 被仕向金融機関番号
    lv_bank_name_alt           := RPAD( NVL( i_bac_fb_line_rec.bank_name_alt, cv_space ), 15 );           -- 被仕向金融機関名
    lv_bank_num                := LPAD( NVL( i_bac_fb_line_rec.bank_num, cv_zero ), 3, cv_zero );         -- 被仕向支店番号
    lv_bank_branch_name_alt    := RPAD( NVL( i_bac_fb_line_rec.bank_branch_name_alt, cv_space ), 15 );    -- 被仕向支店名
    lv_clearinghouse_no        := LPAD( cv_space, 4, cv_space );                                                     -- 手形交換所番号
    lv_bank_account_type       := NVL( i_bac_fb_line_rec.bank_account_type, cv_zero );                    -- 預金種目
    lv_bank_account_num        := LPAD( NVL( i_bac_fb_line_rec.bank_account_num, cv_zero ), 7, cv_zero ); -- 口座番号
    lv_account_holder_name_alt := RPAD( NVL( i_bac_fb_line_rec.account_holder_name_alt, cv_space ), 30 ); -- 受取人名
    lv_transfer_amount         := LPAD( cv_zero, 10, cv_zero );                                                      -- 振込金額
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD START
--    lv_base_code               := LPAD( cv_space, 4, cv_space );                                                     -- 拠点コード
--    lv_supplier_code           := LPAD( NVL( i_bac_fb_line_rec.segment1, cv_space ), 9 );                 -- 仕入先コード
--    lv_dummy                   := LPAD( cv_space, 17, cv_space );                                                    -- ダミー
    lv_base_code               := LPAD( NVL( i_bac_fb_line_rec.base_code, cv_space ), 10 , cv_zero );     -- 拠点コード
    lv_supplier_code           := LPAD( NVL( i_bac_fb_line_rec.segment1, cv_space ), 10 , cv_zero );      -- 仕入先コード
-- Ver.1.14 Mod Start
--    lv_dummy                   := LPAD( cv_space, 9, cv_space );                                          -- ダミー
    lv_dummy                   := LPAD( cv_space, 8, cv_space );                                          -- ダミー
-- Ver.1.14 Mod End
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD END
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
--
    ov_fb_line_data            := lv_data_type               ||          -- データ区分
                                  lv_bank_number             ||          -- 被仕向金融機関番号
                                  lv_bank_name_alt           ||          -- 被仕向金融機関名
                                  lv_bank_num                ||          -- 被仕向支店番号
                                  lv_bank_branch_name_alt    ||          -- 被仕向支店名
                                  lv_clearinghouse_no        ||          -- 手形交換所番号
                                  lv_bank_account_type       ||          -- 預金種目
                                  lv_bank_account_num        ||          -- 口座番号
                                  lv_account_holder_name_alt ||          -- 受取人名
                                  lv_transfer_amount         ||          -- 振込金額
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD START
                                  cv_zero                    ||          -- 新規レコード
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD END
                                  lv_base_code               ||          -- 拠点コード
                                  lv_supplier_code           ||          -- 仕入先コード
-- Ver.1.14 Add Start
                                  cv_settlement_kbn          ||         -- 振込指定区分（決済優先度）
-- Ver.1.14 Add End
                                  lv_dummy;                              -- ダミー
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END storage_bank_acct_chk_fb_line;
--
  /**********************************************************************************
   * Procedure Name   : get_fb_line_add_info
   * Description      : FB作成明細データ付加情報の取得（本振用FBデータ作成処理）(A-8)
   ***********************************************************************************/
  PROCEDURE get_fb_line_add_info(
     ov_errbuf          OUT VARCHAR2       -- エラー・メッセージ
    ,ov_retcode         OUT VARCHAR2       -- リターン・コード
    ,ov_errmsg          OUT VARCHAR2       -- ユーザー・エラー・メッセージ
    ,on_transfer_amount OUT NUMBER         -- 振込金額
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    ,on_fee             OUT NUMBER         -- 銀行手数料（振込手数料）
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--    ,in_cnt             IN  NUMBER         -- 索引カウンタ
    ,i_fb_line_rec      IN  fb_line_cur%ROWTYPE      -- FB作成明細レコード
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'get_fb_line_add_info';  -- プログラム名
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    -- グローバル定数化
--    cv_i               CONSTANT VARCHAR2(1)   := 'I';                     -- 当方
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE START
--    cn_zero            CONSTANT NUMBER        := 0;                       -- 数値：0
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE END
    --================================
    -- ローカル変数
    --================================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;                       -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;                       -- リターン・コード
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;                       -- ユーザー・エラー・メッセージ
    lv_out_msg         VARCHAR2(2000) DEFAULT NULL;                       -- メッセージ
    ln_transfer_amount NUMBER;                                            -- 振込金額
    ln_bm_tax          NUMBER;                                            -- 消費税率
    ln_fee             NUMBER;                                            -- 手数料
    ln_fee_no_tax      NUMBER;                                            -- 手数料(税抜き)
--
  BEGIN
    -- ステータス初期化
    ov_retcode         := cv_status_normal;
    ln_transfer_amount := 0;
    on_transfer_amount := 0;
    ln_bm_tax          := 0;
    ln_fee             := 0;
    ln_fee_no_tax      := 0;
--
    ln_bm_tax := TO_NUMBER( gt_prof_bm_tax );                       -- 消費税率
--
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
/*
    -- 本振用FB作成明細情報.銀行手数料負担者が当方の場合
    IF( gt_fb_line_tab( in_cnt ).bank_charge_bearer = cv_i ) THEN
      -- 本振用FB作成明細情報.振込額が、「銀行手数料_振込額基準」未満の場合
      IF( NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero ) < TO_NUMBER( gt_prof_trans_fee_criterion )) THEN
        ln_fee_no_tax := TO_NUMBER( gt_prof_less_fee_criterion );
        ln_fee        := ln_fee_no_tax * ( ln_bm_tax / 100 + 1 );
      -- 本振用FB作成明細情報.振込額が、「銀行手数料_振込額基準」以上の場合
      ELSIF( NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero ) >= gt_prof_trans_fee_criterion ) THEN
        ln_fee_no_tax := TO_NUMBER( gt_prof_more_fee_criterion );
        ln_fee        := ln_fee_no_tax * ( ln_bm_tax / 100 + 1 );
      END IF;
      -- 振込金額に銀行手数料を加算する
      ln_transfer_amount := NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero );
      IF( ln_transfer_amount > 0 ) THEN
        on_transfer_amount := ln_transfer_amount + ln_fee;
      END IF;
    ELSE
      ln_transfer_amount := NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero );
      on_transfer_amount := ln_transfer_amount;
    END IF;
*/
    -- 支払金額を変数へ格納
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--    ln_transfer_amount := NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero );
    ln_transfer_amount := NVL( i_fb_line_rec.trns_amt, cn_zero );
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
--
    -- 本振用FB作成明細情報.振込額が、「銀行手数料_振込額基準」未満の場合
    IF( ln_transfer_amount < TO_NUMBER( gt_prof_trans_fee_criterion )) THEN
      ln_fee_no_tax := TO_NUMBER( gt_prof_less_fee_criterion );
      ln_fee        := ln_fee_no_tax * ( ln_bm_tax / 100 + 1 );
    -- 本振用FB作成明細情報.振込額が、「銀行手数料_振込額基準」以上の場合
    ELSE
      ln_fee_no_tax := TO_NUMBER( gt_prof_more_fee_criterion );
      ln_fee        := ln_fee_no_tax * ( ln_bm_tax / 100 + 1 );
    END IF;
--
-- 2009/12/16 Ver.1.7 [E_本稼動_00512] SCS S.Moriyama UPD START
--    -- 本振用FB作成明細情報.銀行手数料負担者が当方の場合、振込金額に銀行手数料を加算する
---- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
----    IF( gt_fb_line_tab( in_cnt ).bank_charge_bearer = cv_i AND ln_transfer_amount > 0 ) THEN
--    IF( i_fb_line_rec.bank_charge_bearer = cv_i AND ln_transfer_amount > 0 ) THEN
---- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
--      on_transfer_amount := ln_transfer_amount + ln_fee;
--    ELSE
--      on_transfer_amount := ln_transfer_amount;
--    END IF;
--
    -- 振込手数料負担が相手負担の場合は振込額より手数料を減額する
    IF( i_fb_line_rec.bank_charge_bearer != cv_i AND ln_transfer_amount > 0 ) THEN
      on_transfer_amount := ln_transfer_amount + ( ln_fee * -1 );
    ELSE
      on_transfer_amount := ln_transfer_amount;
    END IF;
-- 2009/12/16 Ver.1.7 [E_本稼動_00512] SCS S.Moriyama UPD END
--
    -- 銀行手数料（振込手数料）をアウトパラメータに格納
    on_fee := ln_fee;
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_fb_line_add_info;
--
   /**********************************************************************************
   * Procedure Name   : storage_fb_line
   * Description      : FB作成明細データの格納（本振用FBデータ作成処理）(A-9)
   ***********************************************************************************/
  PROCEDURE storage_fb_line(
     ov_errbuf                OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode               OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg                OUT VARCHAR2     -- ユーザー・エラー・メッセージ
    ,ov_fb_line_data          OUT VARCHAR2     -- FB明細
    ,in_transfer_amount       IN  NUMBER       -- 振込金額
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--    ,in_cnt                   IN  NUMBER       -- 索引カウンタ
    ,i_fb_line_rec            IN  fb_line_cur%ROWTYPE     -- FB作成明細レコード
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'storage_fb_line';   -- プログラム名
    --
    cv_data_type       CONSTANT VARCHAR2(1)   := '2';                 -- データ区分
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE END
--    cn_zero            CONSTANT NUMBER        := 0;                   -- 数値：0
--    cn_1               CONSTANT NUMBER        := 1;                   -- 数値：1
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE END
    --=================================
    -- ローカル変数
    --=================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;      -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;      -- リターン・コード
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;      -- ユーザー・エラー・メッセージ
    lv_out_msg                  VARCHAR2(2000) DEFAULT NULL;      -- メッセージ出力
    lv_data_type                VARCHAR2(1)    DEFAULT NULL;      -- データ区分
    lv_bank_number              VARCHAR2(4)    DEFAULT NULL;      -- 被仕向金融機関番号
    lv_bank_name_alt            VARCHAR2(15)   DEFAULT NULL;      -- 被仕向金融機関名
    lv_bank_num                 VARCHAR2(3)    DEFAULT NULL;      -- 被仕向支店番号
    lv_bank_branch_name_alt     VARCHAR2(15)   DEFAULT NULL;      -- 被仕向支店名
    lv_clearinghouse_no         VARCHAR2(4)    DEFAULT NULL;      -- 手形交換所番号
    lv_bank_account_type        VARCHAR2(1)    DEFAULT NULL;      -- 預金種目
    lv_bank_account_num         VARCHAR2(7)    DEFAULT NULL;      -- 口座番号
    lv_account_holder_name_alt  VARCHAR2(30)   DEFAULT NULL;      -- 受取人名
    lv_transfer_amount          VARCHAR2(10)   DEFAULT NULL;      -- 振込金額
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD START
--    lv_base_code                VARCHAR2(1)    DEFAULT NULL;      -- 拠点コード
--    lv_supplier_code            VARCHAR2(9)    DEFAULT NULL;      -- 仕入先コード
    lv_base_code                VARCHAR2(10)   DEFAULT NULL;      -- 拠点コード
    lv_supplier_code            VARCHAR2(10)   DEFAULT NULL;      -- 仕入先コード
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD END
    lv_dummy                    VARCHAR2(17)   DEFAULT NULL;      -- ダミー
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
--
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--    lv_data_type               := cv_data_type;                                                                  -- データ区分
--    lv_bank_number             := LPAD( NVL( gt_fb_line_tab( in_cnt ).bank_number, cv_zero ), 4, cv_zero );      -- 被仕向金融機関番号
--    lv_bank_name_alt           := RPAD( NVL( gt_fb_line_tab( in_cnt ).bank_name_alt, cv_space ), 15 );           -- 被仕向金融機関名
--    lv_bank_num                := LPAD( NVL( gt_fb_line_tab( in_cnt ).bank_num, cv_zero ), 3, cv_zero );         -- 被仕向支店番号
--    lv_bank_branch_name_alt    := RPAD( NVL( gt_fb_line_tab( in_cnt ).bank_branch_name_alt, cv_space ), 15 );    -- 被仕向支店名
--    lv_clearinghouse_no        := LPAD( cv_space, 4 );                                                           -- 手形交換所番号
--    lv_bank_account_type       := NVL( gt_fb_line_tab( in_cnt ).bank_account_type, cv_zero );                    -- 預金種目
--    lv_bank_account_num        := LPAD( NVL( gt_fb_line_tab( in_cnt ).bank_account_num, cv_zero ), 7, cv_zero ); -- 口座番号
--    lv_account_holder_name_alt := RPAD( NVL( gt_fb_line_tab( in_cnt ).account_holder_name_alt, cv_space ), 30 ); -- 受取人名
--    lv_transfer_amount         := TO_CHAR( NVL( in_transfer_amount, cn_zero ), 'FM0000000000');                  -- 振込金額
--    lv_base_code               := LPAD( NVL( gt_fb_line_tab( in_cnt ).base_code, cv_space ), 4 );                -- 拠点コード
--    lv_supplier_code           := LPAD( NVL( gt_fb_line_tab( in_cnt ).supplier_code, cv_space ), 9 );            -- 仕入先コード
--    lv_dummy                   := LPAD( cv_space, 17, cv_space );                                                -- ダミー
    lv_data_type               := cv_data_type;                                                                  -- データ区分
    lv_bank_number             := LPAD( NVL( i_fb_line_rec.bank_number, cv_zero ), 4, cv_zero );      -- 被仕向金融機関番号
    lv_bank_name_alt           := RPAD( NVL( i_fb_line_rec.bank_name_alt, cv_space ), 15 );           -- 被仕向金融機関名
    lv_bank_num                := LPAD( NVL( i_fb_line_rec.bank_num, cv_zero ), 3, cv_zero );         -- 被仕向支店番号
    lv_bank_branch_name_alt    := RPAD( NVL( i_fb_line_rec.bank_branch_name_alt, cv_space ), 15 );    -- 被仕向支店名
    lv_clearinghouse_no        := LPAD( cv_space, 4 );                                                           -- 手形交換所番号
    lv_bank_account_type       := NVL( i_fb_line_rec.bank_account_type, cv_zero );                    -- 預金種目
    lv_bank_account_num        := LPAD( NVL( i_fb_line_rec.bank_account_num, cv_zero ), 7, cv_zero ); -- 口座番号
    lv_account_holder_name_alt := RPAD( NVL( i_fb_line_rec.account_holder_name_alt, cv_space ), 30 ); -- 受取人名
    lv_transfer_amount         := TO_CHAR( NVL( in_transfer_amount, cn_zero ), 'FM0000000000');                  -- 振込金額
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD START
--    lv_base_code               := LPAD( NVL( i_fb_line_rec.base_code, cv_space ), 4 );                -- 拠点コード
--    lv_supplier_code           := LPAD( NVL( i_fb_line_rec.supplier_code, cv_space ), 9 );            -- 仕入先コード
--    lv_dummy                   := LPAD( cv_space, 17, cv_space );                                                    -- ダミー
    lv_base_code               := LPAD( NVL( i_fb_line_rec.base_code, cv_space ), 10 , cv_zero );     -- 拠点コード
    lv_supplier_code           := LPAD( NVL( i_fb_line_rec.supplier_code, cv_space ), 10 , cv_zero ); -- 仕入先コード
-- Ver.1.14 Mod Start
--    lv_dummy                   := LPAD( cv_space, 9, cv_space );                                      -- ダミー
    lv_dummy                   := LPAD( cv_space, 8, cv_space );                                      -- ダミー
-- Ver.1.14 Mod End
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD END
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
--
    ov_fb_line_data            := lv_data_type               ||         -- データ区分
                                  lv_bank_number             ||         -- 被仕向金融機関番号
                                  lv_bank_name_alt           ||         -- 被仕向金融機関名
                                  lv_bank_num                ||         -- 被仕向支店番号
                                  lv_bank_branch_name_alt    ||         -- 被仕向支店名
                                  lv_clearinghouse_no        ||         -- 手形交換所番号
                                  lv_bank_account_type       ||         -- 預金種目
                                  lv_bank_account_num        ||         -- 口座番号
                                  lv_account_holder_name_alt ||         -- 受取人名
                                  lv_transfer_amount         ||         -- 振込金額
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD START
                                  cv_zero                    ||         -- 新規レコード
-- 2009/12/17 Ver.1.9 [E_本稼動_00511] SCS S.Moriyama UPD END
                                  lv_base_code               ||         -- 拠点コード
                                  lv_supplier_code           ||         -- 仕入先コード
-- Ver.1.14 Add Start
                                  cv_settlement_kbn          ||         -- 振込指定区分（決済優先度）
-- Ver.1.14 Add End
                                  lv_dummy;                             -- ダミー
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END storage_fb_line;
--
   /**********************************************************************************
   * Procedure Name   : upd_backmargin_balance
   * Description      : FB作成データ出力結果の更新(A-11)
   ***********************************************************************************/
  PROCEDURE upd_backmargin_balance(
     ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--    ,in_cnt        IN  NUMBER       -- 索引カウンタ
    ,i_fb_line_rec IN  fb_line_cur%ROWTYPE       -- FB作成明細レコード
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_backmargin_balance'; -- プログラム名
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE START
--    cn_zero       CONSTANT NUMBER        := 0;                        -- 数値：0
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi DELETE END
    --================================
    -- ローカル変数
    --================================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;          -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;          -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;          -- ユーザー・エラー・メッセージ
    lv_out_msg    VARCHAR2(2000) DEFAULT NULL;          -- メッセージ
    lb_retcode    BOOLEAN;                              -- リターン・コード
    --=================================
    -- ローカルカーソル
    --=================================
    -- ロック取得
    CURSOR lock_bm_bal_cur
    IS
    SELECT xbb.bm_balance_id  AS bm_balance_id          -- 販手残高ID
    FROM   xxcok_backmargin_balance  xbb                -- 販手残高テーブル
    WHERE  xbb.fb_interface_status  = cv_zero
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD START
    AND    xbb.gl_interface_status  = cv_zero
    AND    xbb.amt_fix_status       = cv_1
    AND    xbb.payment_amt_tax      = cn_zero
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD END
    AND    xbb.resv_flag           IS NULL
    AND    xbb.expect_payment_date <= gd_pay_date
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--    AND    xbb.supplier_code        = gt_fb_line_tab( in_cnt ).supplier_code
--    AND    xbb.supplier_site_code   = gt_fb_line_tab( in_cnt ).supplier_site_code
    AND    xbb.supplier_code        = i_fb_line_rec.supplier_code
    AND    xbb.supplier_site_code   = i_fb_line_rec.supplier_site_code
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
    FOR UPDATE NOWAIT;
    --=================================
    -- ローカル例外
    --=================================
    --*** 更新処理例外 ***
    update_err_expt           EXCEPTION;
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    -- ロック取得
    OPEN  lock_bm_bal_cur;
    CLOSE lock_bm_bal_cur;
--
    BEGIN
      --更新処理
      UPDATE xxcok_backmargin_balance   xbb                                            -- 販手残高テーブル
      SET  xbb.expect_payment_amt_tax = cv_zero                                        -- 支払予定額
          ,xbb.payment_amt_tax        = NVL( xbb.expect_payment_amt_tax, cn_zero )     -- 支払額
          ,xbb.fb_interface_status    = cv_1                                           -- 連携ステータス（本振用FB）
          ,xbb.fb_interface_date      = gd_proc_date                                   -- 連携日（本振用FB）
-- 2009/05/29 Ver.1.4 [障害T1_1147] SCS K.Yamaguchi ADD START
          ,xbb.publication_date       = gd_pay_date                                    -- 案内書発効日
          ,xbb.edi_interface_status   = cv_1                                           -- 連携ステータス（EDI支払案内書）
          ,xbb.edi_interface_date     = gd_proc_date                                   -- 連携日（EDI支払案内書）
          ,xbb.request_id             = cn_request_id
          ,xbb.program_application_id = cn_program_application_id
          ,xbb.program_id             = cn_program_id
          ,xbb.program_update_date    = SYSDATE
-- 2009/05/29 Ver.1.4 [障害T1_1147] SCS K.Yamaguchi ADD END
          ,xbb.last_updated_by        = cn_last_updated_by                             -- 最終更新者
          ,xbb.last_update_date       = SYSDATE                                        -- 最終更新日
          ,xbb.last_update_login      = cn_last_update_login                           -- 最終更新ログインID
      WHERE xbb.fb_interface_status   = cv_zero
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD START
      AND   xbb.gl_interface_status   = cv_zero
      AND   xbb.amt_fix_status        = cv_1
      AND   xbb.payment_amt_tax       = cn_zero
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD END
      AND   xbb.resv_flag            IS NULL
      AND   xbb.expect_payment_date  <= gd_pay_date
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--      AND   xbb.supplier_code         = gt_fb_line_tab( in_cnt ).supplier_code
--      AND   xbb.supplier_site_code    = gt_fb_line_tab( in_cnt ).supplier_site_code;
      AND   xbb.supplier_code         = i_fb_line_rec.supplier_code
      AND   xbb.supplier_site_code    = i_fb_line_rec.supplier_site_code;
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
--
    EXCEPTION
      -- *** 更新例外ハンドラ ***
      WHEN OTHERS THEN
        RAISE update_err_expt;
    END;
--
  EXCEPTION
    WHEN global_lock_err_expt THEN
      -- *** ロック取得例外ハンドラ ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi REPAIR START
--                      ,iv_name         => cv_msg_cok_10243
                      ,iv_name         => cv_msg_cok_00053
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi REPAIR END
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN update_err_expt THEN
      -- *** 更新例外ハンドラ ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi REPAIR START
--                      ,iv_name         => cv_msg_cok_10244
                      ,iv_name         => cv_msg_cok_00054
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi REPAIR END
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END upd_backmargin_balance;
--
   /**********************************************************************************
   * Procedure Name   : storage_fb_trailer_data
   * Description      : FB作成トレーラレコードの格納(A-12)
   ***********************************************************************************/
  PROCEDURE storage_fb_trailer_data(
     ov_errbuf                OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode               OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg                OUT VARCHAR2     -- ユーザー・エラー・メッセージ
    ,ov_fb_trailer_data       OUT VARCHAR2     -- FB作成トレーラレコード
    ,iv_proc_type             IN  VARCHAR2     -- データ区分
    ,in_total_transfer_amount IN  NUMBER       -- 振込金額計
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'storage_fb_trailer_data';  -- プログラム名
    cv_data_type  CONSTANT VARCHAR2(1)   := '8';                         -- データ区分
    --=================================
    -- ローカル変数
    --=================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;         -- エラー・メッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT NULL;         -- リターン・コード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;         -- ユーザー・エラー・メッセージ
    lv_out_msg   VARCHAR2(2000) DEFAULT NULL;         -- メッセージ
    lv_data_type VARCHAR2(1)    DEFAULT NULL;         -- データ区分
    lv_total_cnt VARCHAR2(6)    DEFAULT NULL;         -- 合計件数
    lv_total_amt VARCHAR2(12)   DEFAULT NULL;         -- 合計金額
    lv_dummy     VARCHAR2(101)  DEFAULT NULL;         -- ダミー
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    -- 処理区分が1の場合
    IF( iv_proc_type = cv_1 ) THEN
      lv_total_amt := LPAD( cv_zero, 12, cv_zero );                              -- 振込金額計
    -- 処理区分が2の場合
    ELSIF( iv_proc_type = cv_2 ) THEN
      lv_total_amt := LPAD( TO_CHAR( in_total_transfer_amount ), 12, cv_zero );  -- 振込金額計
    END IF;
--
    lv_data_type := cv_data_type;                                -- データ区分
-- 2009/12/16 Ver.1.8 [E_本稼動_00512] SCS S.Moriyama UPD START
--    lv_total_cnt := LPAD( gn_target_cnt, 6, cv_zero );           -- 合計件数
    lv_total_cnt := LPAD( gn_out_cnt, 6, cv_zero );           -- 合計件数
-- 2009/12/16 Ver.1.8 [E_本稼動_00512] SCS S.Moriyama UPD END
    lv_dummy     := LPAD( cv_space, 101, cv_space );             -- ダミー
--
    ov_fb_trailer_data := lv_data_type ||            -- データ区分
                          lv_total_cnt ||            -- 合計件数
                          lv_total_amt ||            -- 振込金額計
                          lv_dummy;                  -- ダミー
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END storage_fb_trailer_data;
--
   /**********************************************************************************
   * Procedure Name   : storage_fb_end_data
   * Description      : FB作成エンドレコードの格納(A-14)
   ***********************************************************************************/
  PROCEDURE storage_fb_end_data(
     ov_errbuf      OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode     OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg      OUT VARCHAR2     -- ユーザー・エラー・メッセージ
    ,ov_fb_end_data OUT VARCHAR2     -- FB作成エンドレコード
  )
  IS
    --================================
    -- ローカル定数
    --================================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'storage_fb_end_data';    -- プログラム名
    cv_data_type CONSTANT VARCHAR2(1)   := '9';                      -- データ区分
    cv_at_mark   CONSTANT VARCHAR2(1)   := CHR( 64 );                -- アットマーク
    --================================
    -- ローカル変数
    --================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;        -- エラー・メッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT NULL;        -- リターン・コード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;        -- ユーザー・エラー・メッセージ
    lv_out_msg   VARCHAR2(2000) DEFAULT NULL;        -- メッセージ
    lv_data_type VARCHAR2(1)    DEFAULT NULL;        -- データ区分
    lv_dummy1    VARCHAR2(117)  DEFAULT NULL;        -- ダミー1
    lv_dummy2    VARCHAR2(1)    DEFAULT NULL;        -- ダミー2
    lv_dummy3    VARCHAR2(1)    DEFAULT NULL;        -- ダミー3
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    lv_data_type := cv_data_type;                    -- データ区分
    lv_dummy1    := LPAD( cv_space, 117, cv_space ); -- ダミー1
    lv_dummy2    := cv_at_mark;                      -- ダミー2
    lv_dummy3    := cv_space;                        -- ダミー3
--
    ov_fb_end_data := lv_data_type ||                -- データ区分
                      lv_dummy1    ||                -- ダミー1
                      lv_dummy2    ||                -- ダミー2
                      lv_dummy3;                     -- ダミー3
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END storage_fb_end_data;
--
   /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : FB作成ヘッダーデータの出力  (A-6)
   *                    FB作成データレコードの出力  (A-10)
   *                    FB作成トレーラレコードの出力(A-13)
   *                    FB作成エンドレコードの出力  (A-15)
   ***********************************************************************************/
  PROCEDURE output_data(
     ov_errbuf  OUT VARCHAR2          -- エラー・メッセージ
    ,ov_retcode OUT VARCHAR2          -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2          -- ユーザー・エラー・メッセージ
    ,iv_data    IN  VARCHAR2          -- 出力するデータ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
    --================================
    -- ローカル変数
    --================================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;         -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;         -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;         -- ユーザー・エラー・メッセージ
    lv_out_msg    VARCHAR2(2000) DEFAULT NULL;         -- メッセージ
    lb_retcode    BOOLEAN;                             -- リターン・コード
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --=======================================================
    -- データ出力
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- 出力区分
                   ,iv_message  => iv_data             -- メッセージ
                   ,in_new_line => 0                   -- 改行
                  );
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END output_data;
--
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR START
--  /**********************************************************************************
--   * Procedure Name   : submain
--   * Description      : メイン処理プロシージャ
--   **********************************************************************************/
--  PROCEDURE submain(
--     ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ
--    ,ov_retcode    OUT VARCHAR2     -- リターン・コード
--    ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ
--    ,iv_proc_type  IN  VARCHAR2     -- 処理パラメータ
--  )
--  IS
--    --===============================
--    -- ローカル定数
--    --===============================
--    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';  -- プログラム名
--    --
--    -- ===============================
--    -- ローカル変数
--    -- ===============================
--    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- エラー・メッセージ
--    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                        -- リターン・コード
--    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- ユーザー・エラー・メッセージ
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                        -- メッセージ
--    lb_retcode                 BOOLEAN        DEFAULT NULL;                        -- メッセージ・リターン・コード
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    --
--    ln_cnt                     NUMBER         DEFAULT NULL;                        -- 索引カウンタ
--    --
--    lt_bank_number             ap_bank_branches.bank_number%TYPE;                  -- 銀行番号
--    lt_bank_name_alt           ap_bank_branches.bank_name_alt%TYPE;                -- 銀行名カナ
--    lt_bank_num                ap_bank_branches.bank_num%TYPE;                     -- 銀行支店番号
--    lt_bank_branch_name_alt    ap_bank_branches.bank_branch_name_alt%TYPE;         -- 銀行支店名カナ
--    lt_bank_account_type       ap_bank_accounts_all.bank_account_type%TYPE;        -- 預金種別
--    lt_bank_account_num        ap_bank_accounts_all.bank_account_num%TYPE;         -- 銀行口座番号
--    lt_account_holder_name_alt ap_bank_accounts_all.account_holder_name_alt%TYPE;  -- 口座名義人カナ
--    --
--    lv_fb_header_data          VARCHAR2(2000) DEFAULT NULL;                        -- FB作成ヘッダーデータ
--    lv_fb_line_data            VARCHAR2(5000) DEFAULT NULL;                        -- FB作成明細データ
--    lv_fb_trailer_data         VARCHAR2(2000) DEFAULT NULL;                        -- FB作成トレーラレコード
--    lv_fb_end_data             VARCHAR2(2000) DEFAULT NULL;                        -- FB作成エンドレコード
--    ln_transfer_amount         NUMBER;                                             -- 振込金額
--    ln_total_transfer_amount   NUMBER;                                             -- 振込金額計
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    ln_fee                     NUMBER;                                             -- 銀行手数料（振込手数料）
--    lv_bank_charge_bearer      VARCHAR2(30)   DEFAULT NULL;                        -- 銀行手数料負担者
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
----
--  BEGIN
--    -- ステータス初期化
--    ov_retcode := cv_status_normal;
--    -- グローバル変数の初期化
--    gn_target_cnt            := 0;        -- 対象件数
--    gn_normal_cnt            := 0;        -- 正常件数
--    gn_error_cnt             := 0;        -- エラー件数
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    -- 未使用のためコメントアウト
----    gn_warn_cnt              := 0;        -- 警告件数
--    gn_skip_cnt              := 0;        -- スキップ件数
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    gn_out_cnt               := 0;        -- 成功件数
--    -- ローカル変数の初期化
--    ln_total_transfer_amount := 0;        -- 振込金額計
--    --===============================
--    -- A-1.初期処理
--    --===============================
--    init(
--       ov_errbuf    => lv_errbuf         -- エラー・メッセージ
--      ,ov_retcode   => lv_retcode        -- リターン・コード
--      ,ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ
--      ,iv_proc_type => iv_proc_type      -- 処理パラメータ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- 処理区分が'1'(振込口座事前チェックFB作成処理)の場合
--    IF( iv_proc_type = cv_1 ) THEN
--      --===============================================================
--      -- A-2.FB作成明細データの取得（振込口座事前チェック用FB作成処理）
--      --===============================================================
--      get_bank_acct_chk_fb_line(
--         ov_errbuf  => lv_errbuf    -- エラー・メッセージ
--        ,ov_retcode => lv_retcode   -- リターン・コード
--        ,ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- 対象件数
--      gn_target_cnt := gt_bac_fb_line_tab.COUNT;
--    -- 処理区分が'2'(本振用FBデータ作成処理)の場合
--    ELSIF( iv_proc_type = cv_2 ) THEN
--      --===============================================================
--      -- A-3.FB作成明細データの取得（本振用FBデータ作成処理）
--      --===============================================================
--      get_fb_line(
--         ov_errbuf  => lv_errbuf    -- エラー・メッセージ
--        ,ov_retcode => lv_retcode   -- リターン・コード
--        ,ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- 対象件数
--      gn_target_cnt := gt_fb_line_tab.COUNT;
--    END IF;
--    -- 振込口座事前チェック用FB作成
--    IF( iv_proc_type = cv_1 ) THEN
--      --=================================================
--      -- A-4.FB作成ヘッダーデータの取得
--      --=================================================
--      get_fb_header(
--         ov_errbuf                  => lv_errbuf                     -- エラー・メッセージ
--        ,ov_retcode                 => lv_retcode                    -- リターン・コード
--        ,ov_errmsg                  => lv_errmsg                     -- ユーザー・エラー・メッセージ
--        ,ot_bank_number             => lt_bank_number                -- 銀行番号
--        ,ot_bank_name_alt           => lt_bank_name_alt              -- 銀行名カナ
--        ,ot_bank_num                => lt_bank_num                   -- 銀行支店番号
--        ,ot_bank_branch_name_alt    => lt_bank_branch_name_alt       -- 銀行支店名カナ
--        ,ot_bank_account_type       => lt_bank_account_type          -- 預金種別
--        ,ot_bank_account_num        => lt_bank_account_num           -- 銀行口座番号
--        ,ot_account_holder_name_alt => lt_account_holder_name_alt    -- 口座名義人カナ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --=================================================
--      -- A-5.FB作成ヘッダーデータの格納
--      --=================================================
--      storage_fb_header(
--         ov_errbuf                  => lv_errbuf                     -- エラー・メッセージ
--        ,ov_retcode                 => lv_retcode                    -- リターン・コード
--        ,ov_errmsg                  => lv_errmsg                     -- ユーザー・エラー・メッセージ
--        ,ov_fb_header_data          => lv_fb_header_data             -- FB作成ヘッダーデータ
--        ,it_bank_number             => lt_bank_number                -- 銀行番号
--        ,it_bank_name_alt           => lt_bank_name_alt              -- 銀行名カナ
--        ,it_bank_num                => lt_bank_num                   -- 銀行支店番号
--        ,it_bank_branch_name_alt    => lt_bank_branch_name_alt       -- 銀行支店名カナ
--        ,it_bank_account_type       => lt_bank_account_type          -- 預金種別
--        ,it_bank_account_num        => lt_bank_account_num           -- 銀行口座番号
--        ,it_account_holder_name_alt => lt_account_holder_name_alt    -- 口座名義人カナ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --=================================================
--      -- A-6.FB作成ヘッダーデータの出力
--      --=================================================
--      output_data(
--         ov_errbuf  => lv_errbuf           -- エラー・メッセージ
--        ,ov_retcode => lv_retcode          -- リターン・コード
--        ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
--        ,iv_data    => lv_fb_header_data   -- 出力するデータ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      <<bac_fb_line_loop>>
--      FOR ln_cnt IN 1 .. gt_bac_fb_line_tab.COUNT LOOP
--        --===============================================================
--        -- A-7.FB作成明細データの格納（振込口座事前チェック用FB作成処理）
--        --===============================================================
--        storage_bank_acct_chk_fb_line(
--           ov_errbuf       => lv_errbuf            -- エラー・メッセージ
--          ,ov_retcode      => lv_retcode           -- リターン・コード
--          ,ov_errmsg       => lv_errmsg            -- ユーザー・エラー・メッセージ
--          ,ov_fb_line_data => lv_fb_line_data      -- FB作成明細レコード
--          ,in_cnt          => ln_cnt               -- 索引カウンタ
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        --===============================
--        -- A-10.FB作成データレコードの出力
--        --===============================
--        output_data(
--          ov_errbuf  => lv_errbuf            -- エラー・メッセージ
--         ,ov_retcode => lv_retcode           -- リターン・コード
--         ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ
--         ,iv_data    => lv_fb_line_data      -- 出力するデータ
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        -- 成功件数
--        gn_out_cnt := gn_out_cnt + 1;
--      END LOOP bac_fb_line_loop;
--    -- 本振用FBデータ作成
--    ELSIF( iv_proc_type = cv_2 ) THEN
--      --=================================================
--      -- A-4.FB作成ヘッダーデータの取得
--      --=================================================
--      get_fb_header(
--         ov_errbuf                  => lv_errbuf                     -- エラー・メッセージ
--        ,ov_retcode                 => lv_retcode                    -- リターン・コード
--        ,ov_errmsg                  => lv_errmsg                     -- ユーザー・エラー・メッセージ
--        ,ot_bank_number             => lt_bank_number                -- 銀行番号
--        ,ot_bank_name_alt           => lt_bank_name_alt              -- 銀行名カナ
--        ,ot_bank_num                => lt_bank_num                   -- 銀行支店番号
--        ,ot_bank_branch_name_alt    => lt_bank_branch_name_alt       -- 銀行支店名カナ
--        ,ot_bank_account_type       => lt_bank_account_type          -- 預金種別
--        ,ot_bank_account_num        => lt_bank_account_num           -- 銀行口座番号
--        ,ot_account_holder_name_alt => lt_account_holder_name_alt    -- 口座名義人カナ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --=================================================
--      -- A-5.FB作成ヘッダーデータの格納
--      --=================================================
--      storage_fb_header(
--         ov_errbuf                  => lv_errbuf                     -- エラー・メッセージ
--        ,ov_retcode                 => lv_retcode                    -- リターン・コード
--        ,ov_errmsg                  => lv_errmsg                     -- ユーザー・エラー・メッセージ
--        ,ov_fb_header_data          => lv_fb_header_data             -- FB作成ヘッダーレコード
--        ,it_bank_number             => lt_bank_number                -- 銀行番号
--        ,it_bank_name_alt           => lt_bank_name_alt              -- 銀行名カナ
--        ,it_bank_num                => lt_bank_num                   -- 銀行支店番号
--        ,it_bank_branch_name_alt    => lt_bank_branch_name_alt       -- 銀行支店名カナ
--        ,it_bank_account_type       => lt_bank_account_type          -- 預金種別
--        ,it_bank_account_num        => lt_bank_account_num           -- 銀行口座番号
--        ,it_account_holder_name_alt => lt_account_holder_name_alt    -- 口座名義人カナ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --=================================================
--      -- A-6.FB作成ヘッダーデータの出力
--      --=================================================
--      output_data(
--         ov_errbuf  => lv_errbuf            -- エラー・メッセージ
--        ,ov_retcode => lv_retcode           -- リターン・コード
--        ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ
--        ,iv_data    => lv_fb_header_data    -- 出力するデータ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      <<fb_loop>>
--      FOR ln_cnt IN 1 .. gt_fb_line_tab.COUNT LOOP
--        --==========================================================
--        -- A-8.FB作成明細データ付加情報の取得（本振用FBデータ作成処理）
--        --==========================================================
--        get_fb_line_add_info(
--           ov_errbuf          => lv_errbuf               -- エラー・メッセージ
--          ,ov_retcode         => lv_retcode              -- リターン・コード
--          ,ov_errmsg          => lv_errmsg               -- ユーザー・エラー・メッセージ
--          ,on_transfer_amount => ln_transfer_amount      -- 振込金額
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--          ,on_fee             => ln_fee                  -- 銀行手数料（振込手数料）
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--          ,in_cnt             => ln_cnt                  -- 索引カウンタ
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--        IF(( gt_fb_line_tab( ln_cnt ).bank_charge_bearer = cv_i   AND
--             gt_fb_line_tab( ln_cnt ).trns_amt <= 0
--           ) OR
--           ( gt_fb_line_tab( ln_cnt ).bank_charge_bearer <> cv_i  AND
--             ( gt_fb_line_tab( ln_cnt ).trns_amt - ln_fee ) <= 0
--           )
--          )
--        THEN
--          -- スキップ件数のカウントアップ
--          gn_skip_cnt := gn_skip_cnt + 1;
----
--          -- 出力用の銀行手数料負担者を選定
--          IF ( gt_fb_line_tab( ln_cnt ).bank_charge_bearer = cv_i ) THEN
--            lv_bank_charge_bearer := gt_prof_bank_trns_fee_we;
--          ELSE
--            lv_bank_charge_bearer := gt_prof_bank_trns_fee_ctpty;
--          END IF;
----
--          -- FBデータの支払金額0円以下警告メッセージ出力
--         lv_out_msg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_appli_xxcok
--                         ,iv_name         => cv_msg_cok_10453
--                         ,iv_token_name1  => cv_token_conn_loc
--                         ,iv_token_value1 => gt_fb_line_tab( ln_cnt ).base_code      -- 問合せ担当拠点
--                         ,iv_token_name2  => cv_token_vendor_code
--                         ,iv_token_value2 => gt_fb_line_tab( ln_cnt ).supplier_code  -- 支払先コード
--                         ,iv_token_name3  => cv_token_payment_amt
--                         ,iv_token_value3 => TO_CHAR( gt_fb_line_tab( ln_cnt ).trns_amt ) -- 振込額
--                         ,iv_token_name4  => cv_token_bank_charge_bearer
--                         ,iv_token_value4 => lv_bank_charge_bearer                   -- 銀行手数料
--                       );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.LOG       -- 出力区分
--                        ,iv_message  => lv_out_msg         -- メッセージ
--                        ,in_new_line => 0                  -- 改行
--                       );
----
--        ELSE
--          -- 振込金額計
--          ln_total_transfer_amount := ln_total_transfer_amount + ln_transfer_amount;
--          --=============================================================
--          -- A-9.FB作成明細データの格納（本振用FBデータ作成処理）
--          --=============================================================
--          storage_fb_line(
--            ov_errbuf                => lv_errbuf                   -- エラー・メッセージ
--           ,ov_retcode               => lv_retcode                  -- リターン・コード
--           ,ov_errmsg                => lv_errmsg                   -- ユーザー・エラー・メッセージ
--           ,ov_fb_line_data          => lv_fb_line_data             -- FB明細
--           ,in_transfer_amount       => ln_transfer_amount          -- 振込金額
--           ,in_cnt                   => ln_cnt                      -- 索引カウンタ
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
--          --
--          --================================
--          -- A-10.FB作成データレコードの出力
--          --================================
--          output_data(
--            ov_errbuf  => lv_errbuf           -- エラー・メッセージ
--           ,ov_retcode => lv_retcode          -- リターン・コード
--           ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージF
--           ,iv_data    => lv_fb_line_data     -- 出力するデータ
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
--          --===================================
--          -- A-11.FB作成データ出力結果の更新
--          --===================================
--          upd_backmargin_balance(
--             ov_errbuf  => lv_errbuf          -- エラー・メッセージ
--            ,ov_retcode => lv_retcode         -- リターン・コード
--            ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ
--            ,in_cnt     => ln_cnt             -- 索引カウンタ
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
--          -- 成功件数
--          gn_out_cnt := gn_out_cnt + 1;
--        END IF;
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--      END LOOP fb_loop;
--    END IF;
--    --=======================================
--    -- A-12.FB作成トレーラレコードの格納
--    --=======================================
--    storage_fb_trailer_data(
--       ov_errbuf                => lv_errbuf                  -- エラー・メッセージ
--      ,ov_retcode               => lv_retcode                 -- リターン・コード
--      ,ov_errmsg                => lv_errmsg                  -- ユーザー・エラー・メッセージ
--      ,ov_fb_trailer_data       => lv_fb_trailer_data         -- FB作成トレーラレコード
--      ,iv_proc_type             => iv_proc_type               -- データ区分
--      ,in_total_transfer_amount => ln_total_transfer_amount   -- 振込金額計
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--    END IF;
--    --=======================================
--    -- A-13.FB作成トレーラレコードの出力
--    --=======================================
--    output_data(
--       ov_errbuf  => lv_errbuf               -- エラー・メッセージ
--      ,ov_retcode => lv_retcode              -- リターン・コード
--      ,ov_errmsg  => lv_errmsg               -- ユーザー・エラー・メッセージ
--      ,iv_data    => lv_fb_trailer_data      -- 出力するデータ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--    END IF;
--    --=======================================
--    -- A-14.FB作成エンドレコードの格納
--    --=======================================
--    storage_fb_end_data(
--       ov_errbuf      => lv_errbuf            -- エラー・メッセージ
--      ,ov_retcode     => lv_retcode           -- リターン・コード
--      ,ov_errmsg      => lv_errmsg            -- ユーザー・エラー・メッセージ
--      ,ov_fb_end_data => lv_fb_end_data       -- FB作成エンドレコード
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--    END IF;
--    --=======================================
--    -- A-15.FB作成エンドレコードの出力
--    --=======================================
--    output_data(
--       ov_errbuf  => lv_errbuf         -- エラー・メッセージ
--      ,ov_retcode => lv_retcode        -- リターン・コード
--      ,ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ
--      ,iv_data    => lv_fb_end_data    -- 出力するデータ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      IF( lv_errbuf IS NOT NULL ) THEN
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      END IF;
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END submain;
--
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD START
   /**********************************************************************************
   * Procedure Name   : upd_carried_forward_data
   * Description      : 翌月繰り越しデータの更新(A-17)
   ***********************************************************************************/
  PROCEDURE upd_carried_forward_data(
      ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
    , ov_retcode  OUT VARCHAR2  -- リターン・コード
    , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
   , iv_proc_type IN  VARCHAR2  -- 処理パラメータ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100)  := 'upd_carried_forward_data';  -- プログラム名
    --================================
    -- ローカル変数
    --================================
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL; -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL; -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL; -- メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE; -- リターン・コード
    --=================================
    -- ローカルカーソル
    --=================================
    -- ロック取得
    CURSOR xbb_update_lock_cur
    IS
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi REPAIR START
--      SELECT  /*+ INDEX( xbb xxcok_backmargin_balance_n10 ) */
--              xbb.bm_balance_id AS bm_balance_id  -- 販手残高ID
--      FROM    xxcok_backmargin_balance  xbb -- 販手残高テーブル
--      WHERE   xbb.fb_interface_status     =  '0'  -- 連携ステータス（本振用FB）     ：未連携
--        AND   xbb.gl_interface_status     =  '0'  -- 連携ステータス（GL）           ：未連携
--        AND   xbb.edi_interface_status    =  '1'  -- 連携ステータス（EDI支払案内書）：連携済
--        AND   xbb.expect_payment_amt_tax  <> 0
--        AND   xbb.payment_amt_tax         =  0
--        AND   (     xbb.publication_date  IS NOT NULL
--                 OR xbb.org_slip_number   IS NOT NULL
--              )
      SELECT  /*+
               */
              xbb.bm_balance_id AS bm_balance_id  -- 販手残高ID
      FROM    xxcok_backmargin_balance  xbb -- 販手残高テーブル
      WHERE   xbb.expect_payment_date     <= gd_pay_date
        AND   xbb.amt_fix_status          =  cv_1     -- 金額確定ステータス             ：確定済
        AND   xbb.fb_interface_status     =  cv_zero  -- 連携ステータス（本振用FB）     ：未連携
        AND   xbb.gl_interface_status     =  cv_zero  -- 連携ステータス（GL）           ：未連携
        AND   xbb.edi_interface_status    =  cv_1     -- 連携ステータス（EDI支払案内書）：連携済
        AND   xbb.expect_payment_amt_tax  <> cn_zero
        AND   xbb.payment_amt_tax         =  cn_zero
        AND   (     xbb.publication_date  IS NOT NULL
                 OR xbb.org_slip_number   IS NOT NULL
              )
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi REPAIR END
      FOR UPDATE NOWAIT
    ;
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
--
    --==================================================
    -- 処理区分が'2'(本振用FBデータ作成処理)の場合
    --==================================================
    IF( iv_proc_type = cv_2 ) THEN
      <<update_lock_loop>>
      FOR xbb_update_lock_rec IN xbb_update_lock_cur LOOP
        UPDATE  xxcok_backmargin_balance  xbb -- 販手残高テーブル
        SET xbb.publication_date        = NULL                      -- 案内書発効日
          , xbb.edi_interface_status    = cv_zero                   -- 連携ステータス（EDI支払案内書）
          , xbb.edi_interface_date      = NULL                      -- 連携日        （EDI支払案内書）
          , xbb.org_slip_number         = NULL                      -- 元伝票番号
          , xbb.request_id              = cn_request_id             -- 要求ID
          , xbb.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
          , xbb.program_id              = cn_program_id             -- コンカレント・プログラムID
          , xbb.program_update_date     = SYSDATE                   -- プログラム更新日
          , xbb.last_updated_by         = cn_last_updated_by        -- 最終更新者
          , xbb.last_update_date        = SYSDATE                   -- 最終更新日
          , xbb.last_update_login       = cn_last_update_login      -- 最終更新ログイン
        WHERE xbb.bm_balance_id =  xbb_update_lock_rec.bm_balance_id
        ;
      END LOOP update_lock_loop;
    END IF;
--
  EXCEPTION
    -- *** ロック取得例外ハンドラ ***
    WHEN global_lock_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok
                      , iv_name         => cv_msg_cok_00053
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which         => FND_FILE.LOG
                     , iv_message       => lv_out_msg
                     , in_new_line      => 0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok
                      , iv_name         => cv_msg_cok_00054
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which         => FND_FILE.LOG
                     , iv_message       => lv_out_msg
                     , in_new_line      => 0
                    );
  END upd_carried_forward_data;
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD END
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
--
  /**********************************************************************************
   * Procedure Name   : dmy_acct_chk
   * Description      : ダミー口座チェック
   **********************************************************************************/
  PROCEDURE dmy_acct_chk(
     ov_errbuf            OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode           OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg            OUT VARCHAR2     -- ユーザー・エラー・メッセージ
    ,iv_base_code         IN  VARCHAR2     -- 問合せ担当拠点
    ,iv_supplier_code     IN  VARCHAR2     -- 支払先コード
    ,it_bank_number       IN  ap_bank_branches.bank_number%TYPE            -- 銀行番号
    ,it_bank_num          IN  ap_bank_branches.bank_num%TYPE               -- 銀行支店番号
    ,it_bank_account_type IN  ap_bank_accounts_all.bank_account_type%TYPE  -- 預金種別
    ,it_bank_account_num  IN  ap_bank_accounts_all.bank_account_num%TYPE   -- 銀行口座番号
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'dmy_acct_chk';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                        -- リターン・コード
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- ユーザー・エラー・メッセージ
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                        -- メッセージ
    lb_retcode                 BOOLEAN        DEFAULT NULL;                        -- メッセージ・リターン・コード
    --===============================
    -- ローカル例外
    --===============================
    dmy_acct_expt              EXCEPTION; -- スキップ処理
    --
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    ov_retcode := cv_status_normal;
    --==================================================
    -- ダミー口座チェック
    --==================================================
    << dmy_acct_loop >>
    FOR i IN 1..g_dmy_acct_tab.COUNT LOOP
      IF    ( NVL(it_bank_number, cv_space)       = NVL(g_dmy_acct_tab(i).bank_number, cv_space) )
        AND ( NVL(it_bank_num, cv_space)          = NVL(g_dmy_acct_tab(i).bank_num, cv_space) )
        AND ( NVL(it_bank_account_type, cv_space) = NVL(g_dmy_acct_tab(i).bank_account_type, cv_space) )
        AND ( NVL(it_bank_account_num, cv_space)  = NVL(g_dmy_acct_tab(i).bank_account_num, cv_space) )
      THEN
        RAISE dmy_acct_expt;
      END IF;
    END LOOP dmy_acct_loop;
  EXCEPTION
    WHEN dmy_acct_expt THEN
      -- FB作成対象外ダミー口座警告メッセージ出力
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                    , iv_name         => cv_msg_cok_10561
                    , iv_token_name1  => cv_token_conn_loc
                    , iv_token_value1 => iv_base_code          -- 問合せ担当拠点
                    , iv_token_name2  => cv_token_vendor_code
                    , iv_token_value2 => iv_supplier_code      -- 支払先コード
                    , iv_token_name3  => cv_token_bank_number
                    , iv_token_value3 => it_bank_number        -- 銀行番号
                    , iv_token_name4  => cv_token_bank_num
                    , iv_token_value4 => it_bank_num           -- 銀行支店番号
                    , iv_token_name5  => cv_token_account_type
                    , iv_token_value5 => it_bank_account_type  -- 預金種別
                    , iv_token_name6  => cv_token_account_num
                    , iv_token_value6 => it_bank_account_num   -- 銀行口座番号
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
      -- 警告ステータスの設定
      ov_retcode := cv_status_warn;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END dmy_acct_chk;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
-- Ver.1.13 ADD START
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : FBデータ明細ワークテーブル登録(A-10B)
   ***********************************************************************************/
  PROCEDURE insert_data(
     ov_errbuf          OUT NOCOPY VARCHAR2                      -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT NOCOPY VARCHAR2                      -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT NOCOPY VARCHAR2                      -- ユーザー・エラー・メッセージ  --# 固定 #
    ,it_bank_number     IN  ap_bank_branches.bank_number%TYPE    -- 仕向金融機関番号
    ,in_transfer_amount IN  NUMBER                               -- 振込金額
    ,i_fb_line_rec      IN  fb_line_cur%ROWTYPE                  -- FB作成明細レコード
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_data';     -- プログラム名
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
    cv_header_rec_type   CONSTANT VARCHAR2(1)   := '1';      -- ヘッダーレコード区分
    cv_date_rec_type     CONSTANT VARCHAR2(1)   := '2';      -- データレコード区分
    cv_code_type         CONSTANT VARCHAR2(1)   := '0';      -- コード区分
    cv_zero              CONSTANT VARCHAR2(1)   := '0';      -- '0'
    cv_space             CONSTANT VARCHAR2(1)   := ' ';      -- スペース1文字
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      -- ワークテーブルに登録
      INSERT INTO xxcok_fb_lines_work
-- Ver.1.14 Mod Start
        (  company_code                            -- 会社コード
          ,internal_bank_number                    -- 仕向金融機関番号
--        (  internal_bank_number                    -- 仕向金融機関番号
-- Ver.1.14 Mod End
          ,header_data_type                        -- ヘッダーレコード区分
          ,type_code                               -- 種別コード
          ,code_type                               -- コード区分
          ,pay_date                                -- 振込指定日
          ,data_type                               -- データレコード区分
          ,bank_number                             -- 被仕向金融機関番号
          ,bank_name_alt                           -- 被仕向金融機関名
          ,bank_num                                -- 被仕向支店番号
          ,bank_branch_name_alt                    -- 被仕向支店名
          ,clearinghouse_no                        -- 手形交換所番号
          ,bank_account_type                       -- 預金種目
          ,bank_account_num                        -- 口座番号
          ,account_holder_name_alt                 -- 受取人名
          ,transfer_amount                         -- 振込金額
          ,record_type                             -- 新規レコード
          ,base_code                               -- 拠点コード
          ,supplier_code                           -- 仕入先コード
-- Ver.1.14 Add Start
          ,settlement_priority                     -- 振込指定区分（決済優先度）
-- Ver.1.14 Add End
          ,implemented_flag                        -- FB振分実行済区分
          ,created_by                              -- 作成者
          ,creation_date                           -- 作成日
          ,last_updated_by                         -- 最終更新者
          ,last_update_date                        -- 最終更新日
          ,last_update_login                       -- 最終更新ログイン
          ,request_id                              -- 要求ID
          ,program_application_id                  -- アプリケーションID
          ,program_id                              -- プログラムID
          ,program_update_date                     -- プログラム更新日
        )
      VALUES
-- Ver.1.14 Mod Start
        (  gv_company_code                                                         -- パラメータ.会社コード
          ,SUBSTRB(it_bank_number, 1,4)                                            -- 仕向金融機関番号
--        (  SUBSTRB(it_bank_number, 1,4)                                            -- 仕向金融機関番号
-- Ver.1.14 Mod End
          ,cv_header_rec_type                                                      -- ヘッダーレコード区分
          ,LPAD( gt_values_type_code, 2, cv_zero )                                 -- 種別コード
          ,cv_code_type                                                            -- コード区分
          ,TO_CHAR( gd_pay_date, 'MMDD' )                                          -- 振込指定日
          ,cv_date_rec_type                                                        -- データレコード区分
          ,LPAD( NVL( i_fb_line_rec.bank_number, cv_zero ), 4, cv_zero )           -- 被仕向金融機関番号
          ,RPAD( NVL( i_fb_line_rec.bank_name_alt, cv_space ), 15 )                -- 被仕向金融機関名
          ,LPAD( NVL( i_fb_line_rec.bank_num, cv_zero ), 3, cv_zero )              -- 被仕向支店番号
          ,RPAD( NVL( i_fb_line_rec.bank_branch_name_alt, cv_space ), 15 )         -- 被仕向支店名
          ,LPAD( cv_space, 4 )                                                     -- 手形交換所番号
          ,SUBSTRB(NVL( i_fb_line_rec.bank_account_type, cv_zero ), 1, 1)          -- 預金種目
          ,LPAD( NVL( i_fb_line_rec.bank_account_num, cv_zero ), 7, cv_zero )      -- 口座番号
          ,RPAD( NVL( i_fb_line_rec.account_holder_name_alt, cv_space ), 30 )      -- 受取人名
          ,in_transfer_amount                                                      -- 振込金額
          ,cv_zero                                                                 -- 新規レコード
          ,LPAD( NVL( i_fb_line_rec.base_code, cv_space ), 10 , cv_zero )          -- 拠点コード
          ,LPAD( NVL( i_fb_line_rec.supplier_code, cv_space ), 10 , cv_zero )      -- 仕入先コード
-- Ver.1.14 Add Start
          ,cv_settlement_kbn                                                       -- 振込指定区分（決済優先度）
-- Ver.1.14 Add End
          ,NULL                                                                    -- FB振分実行済区分
          ,cn_created_by                                                           -- 作成者
          ,cd_creation_date                                                        -- 作成日
          ,cn_last_updated_by                                                      -- 最終更新者
          ,cd_last_update_date                                                     -- 最終更新日
          ,cn_last_update_login                                                    -- 最終更新ログイン
          ,cn_request_id                                                           -- 要求ID
          ,cn_program_application_id                                               -- アプリケーションID
          ,cn_program_id                                                           -- プログラムID
          ,cd_program_update_date                                                  -- プログラム更新日
        );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       --アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10861                     --メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           --トークンコード1
                 ,iv_token_value1 => cv_tbl_nm                            --トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       --トークンコード2
                 ,iv_token_value2 => SQLERRM                              --トークン値2
                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
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
  END insert_data;
-- Ver.1.13 ADD END
--
-- Ver.1.13 ADD START
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : ワークテーブルデータ削除(A-18)
   ***********************************************************************************/
  PROCEDURE delete_data(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
-- Ver.1.14 Add Start
  ,iv_company_code   IN  VARCHAR2  -- パラメータ：会社コード
-- Ver.1.14 Add End
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_data';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR fb_lines_cur
    IS
      SELECT 'X'
      FROM   xxcok_fb_lines_work  xflw
-- Ver.1.14 Mod Start
--      WHERE  xflw.request_id < cn_request_id
      WHERE  xflw.request_id <> cn_request_id
      AND    xflw.company_code = iv_company_code  -- パラメータ：会社コード
-- Ver.1.14 Mod End
      FOR UPDATE OF xflw.request_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- FBデータ明細ワークテーブルロック取得
    -- ===============================================
    OPEN  fb_lines_cur;
    CLOSE fb_lines_cur;
    -- ===============================================
    -- FBデータ明細ワークテーブルデータ削除
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_fb_lines_work  xflw
      WHERE  xflw.request_id <> cn_request_id
-- Ver.1.14 Add Start
      AND    xflw.company_code = iv_company_code  -- パラメータ：会社コード
-- Ver.1.14 Add End
      ;
--
    EXCEPTION
      -- *** 削除処理エラー ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       --アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10862                     --メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           --トークンコード1
                 ,iv_token_value1 => cv_tbl_nm                            --トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       --トークンコード2
                 ,iv_token_value2 => SQLERRM                              --トークン値2
                );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
  --*** ロックエラー ***
  WHEN global_lock_err_expt THEN
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => CHR(10)
    );
    lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appli_xxcok                       --アプリケーション短縮名
               ,iv_name         => cv_msg_cok_10863                     --メッセージコード
               ,iv_token_name1  => cv_tkn_tbl                           --トークンコード1
               ,iv_token_value1 => cv_tbl_nm                            --トークン値1
               ,iv_token_name2  => cv_tkn_err_msg                       --トークンコード2
               ,iv_token_value2 => SQLERRM                              --トークン値2
              );
      lv_errbuf := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
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
  END delete_data;
-- Ver.1.13 ADD END
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ
-- Ver.1.14 Add Start
    ,iv_company_code IN  VARCHAR2   -- パラメータ：会社コード
-- Ver.1.14 Add End
    ,iv_proc_type  IN  VARCHAR2     -- 処理パラメータ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';  -- プログラム名
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                        -- リターン・コード
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- ユーザー・エラー・メッセージ
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                        -- メッセージ
    lb_retcode                 BOOLEAN        DEFAULT NULL;                        -- メッセージ・リターン・コード
    --
    ln_cnt                     NUMBER         DEFAULT NULL;                        -- 索引カウンタ
    --
    lt_bank_number             ap_bank_branches.bank_number%TYPE;                  -- 銀行番号
    lt_bank_name_alt           ap_bank_branches.bank_name_alt%TYPE;                -- 銀行名カナ
    lt_bank_num                ap_bank_branches.bank_num%TYPE;                     -- 銀行支店番号
    lt_bank_branch_name_alt    ap_bank_branches.bank_branch_name_alt%TYPE;         -- 銀行支店名カナ
    lt_bank_account_type       ap_bank_accounts_all.bank_account_type%TYPE;        -- 預金種別
    lt_bank_account_num        ap_bank_accounts_all.bank_account_num%TYPE;         -- 銀行口座番号
    lt_account_holder_name_alt ap_bank_accounts_all.account_holder_name_alt%TYPE;  -- 口座名義人カナ
    --
    lv_fb_header_data          VARCHAR2(2000) DEFAULT NULL;                        -- FB作成ヘッダーデータ
    lv_fb_line_data            VARCHAR2(5000) DEFAULT NULL;                        -- FB作成明細データ
    lv_fb_trailer_data         VARCHAR2(2000) DEFAULT NULL;                        -- FB作成トレーラレコード
    lv_fb_end_data             VARCHAR2(2000) DEFAULT NULL;                        -- FB作成エンドレコード
    ln_transfer_amount         NUMBER;                                             -- 振込金額
    ln_total_transfer_amount   NUMBER         DEFAULT 0;                           -- 振込金額計
    ln_fee                     NUMBER;                                             -- 銀行手数料（振込手数料）
    lv_bank_charge_bearer      VARCHAR2(30)   DEFAULT NULL;                        -- 銀行手数料負担者
    --
    --===============================
    -- ローカル例外
    --===============================
    skip_expt                      EXCEPTION; -- スキップ処理
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
    dmy_acct_skip_expt             EXCEPTION; -- ダミー口座スキップ処理
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    ov_retcode := cv_status_normal;
    --==================================================
    -- グローバル変数の初期化
    --==================================================
    gn_target_cnt            := 0;        -- 対象件数
    gn_normal_cnt            := 0;        -- 正常件数
    gn_error_cnt             := 0;        -- エラー件数
    gn_skip_cnt              := 0;        -- スキップ件数
    gn_out_cnt               := 0;        -- 成功件数
    --==================================================
    -- A-1.初期処理
    --==================================================
    init(
      ov_errbuf    => lv_errbuf         -- エラー・メッセージ
    , ov_retcode   => lv_retcode        -- リターン・コード
    , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ
-- Ver.1.14 Add Start
    , iv_company_code => iv_company_code  -- パラメータ：会社コード
-- Ver.1.14 Add End
    , iv_proc_type => iv_proc_type      -- 処理パラメータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-4.FB作成ヘッダーデータの取得
    --==================================================
    get_fb_header(
      ov_errbuf                  => lv_errbuf                     -- エラー・メッセージ
    , ov_retcode                 => lv_retcode                    -- リターン・コード
    , ov_errmsg                  => lv_errmsg                     -- ユーザー・エラー・メッセージ
    , ot_bank_number             => lt_bank_number                -- 銀行番号
    , ot_bank_name_alt           => lt_bank_name_alt              -- 銀行名カナ
    , ot_bank_num                => lt_bank_num                   -- 銀行支店番号
    , ot_bank_branch_name_alt    => lt_bank_branch_name_alt       -- 銀行支店名カナ
    , ot_bank_account_type       => lt_bank_account_type          -- 預金種別
    , ot_bank_account_num        => lt_bank_account_num           -- 銀行口座番号
    , ot_account_holder_name_alt => lt_account_holder_name_alt    -- 口座名義人カナ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-5.FB作成ヘッダーデータの格納
    --==================================================
    storage_fb_header(
      ov_errbuf                  => lv_errbuf                     -- エラー・メッセージ
    , ov_retcode                 => lv_retcode                    -- リターン・コード
    , ov_errmsg                  => lv_errmsg                     -- ユーザー・エラー・メッセージ
    , ov_fb_header_data          => lv_fb_header_data             -- FB作成ヘッダーデータ
    , it_bank_number             => lt_bank_number                -- 銀行番号
    , it_bank_name_alt           => lt_bank_name_alt              -- 銀行名カナ
    , it_bank_num                => lt_bank_num                   -- 銀行支店番号
    , it_bank_branch_name_alt    => lt_bank_branch_name_alt       -- 銀行支店名カナ
    , it_bank_account_type       => lt_bank_account_type          -- 預金種別
    , it_bank_account_num        => lt_bank_account_num           -- 銀行口座番号
    , it_account_holder_name_alt => lt_account_holder_name_alt    -- 口座名義人カナ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-6.FB作成ヘッダーデータの出力
    --==================================================
    output_data(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
    , ov_retcode => lv_retcode          -- リターン・コード
    , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    , iv_data    => lv_fb_header_data   -- 出力するデータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 処理区分が'1'(振込口座事前チェックFB作成処理)の場合
    --==================================================
    IF( iv_proc_type = cv_1 ) THEN
      << bac_fb_line_loop >>
      FOR bac_fb_line_rec IN bac_fb_line_cur LOOP
        gn_target_cnt := gn_target_cnt + 1;
        --==================================================
        -- 明細作成
        --==================================================
        BEGIN
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
          --==================================================
          -- FB作成対象外ダミー口座判定
          --==================================================
          dmy_acct_chk(
            ov_errbuf            => lv_errbuf                      -- エラー・メッセージ
          , ov_retcode           => lv_retcode                     -- リターン・コード
          , ov_errmsg            => lv_errmsg                      -- ユーザー・エラー・メッセージ
          , iv_base_code         => bac_fb_line_rec.base_code      -- 拠点コード
          , iv_supplier_code     => bac_fb_line_rec.segment1       -- 仕入先コード
          , it_bank_number       => bac_fb_line_rec.bank_number        -- 銀行番号
          , it_bank_num          => bac_fb_line_rec.bank_num           -- 銀行支店番号
          , it_bank_account_type => bac_fb_line_rec.bank_account_type  -- 預金種別
          , it_bank_account_num  => bac_fb_line_rec.bank_account_num   -- 銀行口座番号
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE dmy_acct_skip_expt;
          END IF;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
          --==================================================
          -- A-7.FB作成明細データの格納（振込口座事前チェック用FB作成処理）
          --==================================================
          storage_bank_acct_chk_fb_line(
            ov_errbuf         => lv_errbuf            -- エラー・メッセージ
          , ov_retcode        => lv_retcode           -- リターン・コード
          , ov_errmsg         => lv_errmsg            -- ユーザー・エラー・メッセージ
          , ov_fb_line_data   => lv_fb_line_data      -- FB作成明細レコード
          , i_bac_fb_line_rec => bac_fb_line_rec      -- FB作成明細レコード
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --==================================================
          -- A-10.FB作成データレコードの出力
          --==================================================
          output_data(
            ov_errbuf  => lv_errbuf            -- エラー・メッセージ
          , ov_retcode => lv_retcode           -- リターン・コード
          , ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ
          , iv_data    => lv_fb_line_data      -- 出力するデータ
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          -- 成功件数
          gn_out_cnt := gn_out_cnt + 1;
        EXCEPTION
          WHEN skip_expt THEN
            gn_skip_cnt := gn_skip_cnt + 1;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
          WHEN dmy_acct_skip_expt THEN
            gn_skip_cnt := gn_skip_cnt + 1;
            ov_retcode  := cv_status_warn;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
        END;
      END LOOP bac_fb_line_loop;
    --==================================================
    -- 処理区分が'2'(本振用FBデータ作成処理)の場合
    --==================================================
    ELSIF( iv_proc_type = cv_2 ) THEN
      << fb_loop >>
      FOR fb_line_rec IN fb_line_cur LOOP
        gn_target_cnt := gn_target_cnt + 1;
        --==================================================
        -- 明細作成
        --==================================================
        BEGIN
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
          --==================================================
          -- FB作成対象外ダミー口座判定
          --==================================================
          dmy_acct_chk(
            ov_errbuf            => lv_errbuf                      -- エラー・メッセージ
          , ov_retcode           => lv_retcode                     -- リターン・コード
          , ov_errmsg            => lv_errmsg                      -- ユーザー・エラー・メッセージ
          , iv_base_code         => fb_line_rec.base_code          -- 拠点コード
          , iv_supplier_code     => fb_line_rec.supplier_code      -- 仕入先コード
          , it_bank_number       => fb_line_rec.bank_number        -- 銀行番号
          , it_bank_num          => fb_line_rec.bank_num           -- 銀行支店番号
          , it_bank_account_type => fb_line_rec.bank_account_type  -- 預金種別
          , it_bank_account_num  => fb_line_rec.bank_account_num   -- 銀行口座番号
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE dmy_acct_skip_expt;
          END IF;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
          --==================================================
          -- A-8.FB作成明細データ付加情報の取得（本振用FBデータ作成処理）
          --==================================================
          get_fb_line_add_info(
            ov_errbuf          => lv_errbuf               -- エラー・メッセージ
          , ov_retcode         => lv_retcode              -- リターン・コード
          , ov_errmsg          => lv_errmsg               -- ユーザー・エラー・メッセージ
          , on_transfer_amount => ln_transfer_amount      -- 振込金額
          , on_fee             => ln_fee                  -- 銀行手数料（振込手数料）
          , i_fb_line_rec      => fb_line_rec             -- FB作成明細レコード
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --==================================================
          -- 0円以下警告判定
          --==================================================
          IF(    (     ( fb_line_rec.bank_charge_bearer  = cv_i )
                   AND ( fb_line_rec.trns_amt           <= 0    )
                 )
              OR (     ( fb_line_rec.bank_charge_bearer <> cv_i )
                   AND ( fb_line_rec.trns_amt - ln_fee  <= 0    )
                 )
          ) THEN
            RAISE skip_expt;
          END IF;
          -- 振込金額計
          ln_total_transfer_amount := ln_total_transfer_amount + ln_transfer_amount;
          --==================================================
          -- A-9.FB作成明細データの格納（本振用FBデータ作成処理）
          --==================================================
          storage_fb_line(
            ov_errbuf                => lv_errbuf                   -- エラー・メッセージ
          , ov_retcode               => lv_retcode                  -- リターン・コード
          , ov_errmsg                => lv_errmsg                   -- ユーザー・エラー・メッセージ
          , ov_fb_line_data          => lv_fb_line_data             -- FB明細
          , in_transfer_amount       => ln_transfer_amount          -- 振込金額
          , i_fb_line_rec            => fb_line_rec                 -- FB作成明細レコード
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
          --==================================================
          -- A-10.FB作成データレコードの出力
          --==================================================
          output_data(
            ov_errbuf  => lv_errbuf           -- エラー・メッセージ
          , ov_retcode => lv_retcode          -- リターン・コード
          , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージF
          , iv_data    => lv_fb_line_data     -- 出力するデータ
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
-- Ver.1.13 ADD START
          -- ========================================
          -- A-10B.FBデータ明細ワークテーブル登録
          -- ========================================
          insert_data(
             ov_errbuf              => lv_errbuf              -- エラー・メッセージ
           , ov_retcode             => lv_retcode             -- リターン・コード
           , ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ
           , it_bank_number         => lt_bank_number         -- 仕向金融機関番号
           , in_transfer_amount     => ln_transfer_amount     -- 振込金額
           , i_fb_line_rec          => fb_line_rec            -- FB作成明細レコード
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
-- Ver.1.13 ADD END
          --==================================================
          -- A-11.FB作成データ出力結果の更新
          --==================================================
          upd_backmargin_balance(
            ov_errbuf      => lv_errbuf          -- エラー・メッセージ
          , ov_retcode     => lv_retcode         -- リターン・コード
          , ov_errmsg      => lv_errmsg          -- ユーザー・エラー・メッセージ
          , i_fb_line_rec  => fb_line_rec        -- FB作成明細レコード
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          -- 成功件数
          gn_out_cnt := gn_out_cnt + 1;
        EXCEPTION
          WHEN skip_expt THEN
            -- 出力用の銀行手数料負担者を選定
            IF ( fb_line_rec.bank_charge_bearer = cv_i ) THEN
              lv_bank_charge_bearer := gt_prof_bank_trns_fee_we;
            ELSE
              lv_bank_charge_bearer := gt_prof_bank_trns_fee_ctpty;
            END IF;
            -- FBデータの支払金額0円以下警告メッセージ出力
            lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appli_xxcok
                          , iv_name         => cv_msg_cok_10453
                          , iv_token_name1  => cv_token_conn_loc
                          , iv_token_value1 => fb_line_rec.base_code      -- 問合せ担当拠点
                          , iv_token_name2  => cv_token_vendor_code
                          , iv_token_value2 => fb_line_rec.supplier_code  -- 支払先コード
                          , iv_token_name3  => cv_token_payment_amt
                          , iv_token_value3 => TO_CHAR( fb_line_rec.trns_amt ) -- 振込額
                          , iv_token_name4  => cv_token_bank_charge_bearer
                          , iv_token_value4 => lv_bank_charge_bearer                   -- 銀行手数料
                          );
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which    => FND_FILE.LOG       -- 出力区分
                           ,iv_message  => lv_out_msg         -- メッセージ
                           ,in_new_line => 0                  -- 改行
                          );
            -- スキップ件数のカウントアップ
            gn_skip_cnt := gn_skip_cnt + 1;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD START
          WHEN dmy_acct_skip_expt THEN
            gn_skip_cnt := gn_skip_cnt + 1;
            ov_retcode  := cv_status_warn;
-- Ver.1.11 [障害E_本稼動_15203] SCSK K.Nara ADD END
        END;
      END LOOP fb_loop;
    END IF;
    --======================================================
    -- FB作成明細情報取得エラー
    --======================================================
    IF( gn_target_cnt = 0 ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_appli_xxcok
                      ,iv_name        => cv_msg_cok_10254
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 1                  -- 改行
                    );
-- Ver.1.14 Add Start
      ov_retcode  := cv_status_warn;
-- Ver.1.14 Add End
    END IF;
    --==================================================
    -- A-12.FB作成トレーラレコードの格納
    --==================================================
    storage_fb_trailer_data(
      ov_errbuf                => lv_errbuf                  -- エラー・メッセージ
    , ov_retcode               => lv_retcode                 -- リターン・コード
    , ov_errmsg                => lv_errmsg                  -- ユーザー・エラー・メッセージ
    , ov_fb_trailer_data       => lv_fb_trailer_data         -- FB作成トレーラレコード
    , iv_proc_type             => iv_proc_type               -- データ区分
    , in_total_transfer_amount => ln_total_transfer_amount   -- 振込金額計
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-13.FB作成トレーラレコードの出力
    --==================================================
    output_data(
      ov_errbuf  => lv_errbuf               -- エラー・メッセージ
    , ov_retcode => lv_retcode              -- リターン・コード
    , ov_errmsg  => lv_errmsg               -- ユーザー・エラー・メッセージ
    , iv_data    => lv_fb_trailer_data      -- 出力するデータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-14.FB作成エンドレコードの格納
    --==================================================
    storage_fb_end_data(
      ov_errbuf      => lv_errbuf            -- エラー・メッセージ
    , ov_retcode     => lv_retcode           -- リターン・コード
    , ov_errmsg      => lv_errmsg            -- ユーザー・エラー・メッセージ
    , ov_fb_end_data => lv_fb_end_data       -- FB作成エンドレコード
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-15.FB作成エンドレコードの出力
    --==================================================
    output_data(
      ov_errbuf  => lv_errbuf         -- エラー・メッセージ
    , ov_retcode => lv_retcode        -- リターン・コード
    , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ
    , iv_data    => lv_fb_end_data    -- 出力するデータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD START
    --==================================================
    -- A-17.翌月繰り越しデータの更新
    --==================================================
    upd_carried_forward_data(
        ov_errbuf     => lv_errbuf    -- エラー・メッセージ
      , ov_retcode    => lv_retcode   -- リターン・コード
      , ov_errmsg     => lv_errmsg    -- ユーザー・エラー・メッセージ
      , iv_proc_type  => iv_proc_type -- 処理パラメータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2010/09/30 Ver.1.10 [E_本稼動_01144] SCS S.Arizumi ADD END
-- Ver.1.14 Add/Mod Start
    --==================================================
    -- 処理区分が'2'(本振用FBデータ作成処理)の場合
    --==================================================
    IF( iv_proc_type = cv_2 ) THEN
-- Ver.1.13 ADD START
      -- ===============================================
      -- ワークテーブルデータ削除(A-18)
      -- ===============================================
      delete_data(
        ov_errbuf   => lv_errbuf   -- エラー・メッセージ
      , ov_retcode  => lv_retcode  -- リターン・コード
      , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
      , iv_company_code => iv_company_code  -- パラメータ：会社コード
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- Ver.1.13 ADD END
    END IF;
-- Ver.1.14 Add/Mod End
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF( lv_errbuf IS NOT NULL ) THEN
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      END IF;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END submain;
-- 2009/07/02 Ver.1.5 [障害0000291] SCS K.Yamaguchi REPAIR END
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
     errbuf        OUT VARCHAR2      -- エラー・メッセージ
    ,retcode       OUT VARCHAR2      -- リターン・コード
-- Ver.1.14 Add Start
    ,iv_company_code IN  VARCHAR2    -- パラメータ：会社コード
-- Ver.1.14 Add End
    ,iv_proc_type  IN  VARCHAR2      -- 処理パラメータ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';   -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_out_msg    VARCHAR2(2000) DEFAULT NULL;
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;        -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;        -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;        -- ユーザー・エラー・メッセージ
    lb_retcode    BOOLEAN;                            -- メッセージ
--
  BEGIN
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf    => lv_errbuf      -- エラー・メッセージ
      ,ov_retcode   => lv_retcode     -- リターン・コード
      ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ
-- Ver.1.14 Add Start
      ,iv_company_code => iv_company_code        -- 会社コードパラメータ
-- Ver.1.14 Add End
      ,iv_proc_type => iv_proc_type   -- 処理パラメータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      -- 成功件数
      gn_out_cnt := 0;
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
      gn_skip_cnt := 0;
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
      -- エラー件数
      gn_error_cnt := 1;
    END IF;
    IF( lv_retcode = cv_status_error ) THEN
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- 出力区分
                   ,iv_message  => lv_errmsg          -- メッセージ
                   ,in_new_line => 0                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- 出力区分
                   ,iv_message  => lv_errbuf          -- メッセージ
                   ,in_new_line => 0                  -- 改行
                  );
    END IF;
    --================================================
    -- A-16.終了処理
    --================================================
    -- 空行
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    IF( lv_retcode = cv_status_error ) THEN
    IF( lv_retcode = cv_status_error OR gn_skip_cnt > 0 ) THEN
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,NULL
                     ,1
                    );
    END IF;
    -- 対象件数
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90000
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 0                  -- 改行
                  );
    --成功件数
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90001
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_out_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 0                  -- 改行
                  );
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    --スキップ件数
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90003
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 0                  -- 改行
                  );
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    --エラー件数
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90002
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- 出力区分
                   ,iv_message  => lv_out_msg         -- メッセージ
                   ,in_new_line => 1                  -- 改行
                  );
    --終了メッセージ
    IF( lv_retcode = cv_status_normal ) THEN
      --メッセージ出力
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxccp
                     ,iv_name         => cv_msg_ccp_90004
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
    END IF;
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
      --エラー終了
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appli_xxccp
                     ,iv_name        => cv_msg_ccp_90006
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_out_msg         -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
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
END XXCOK016A02C;
/
