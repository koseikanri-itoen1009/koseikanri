CREATE OR REPLACE PACKAGE BODY XXCMM002A01C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A01C(body)
 * Description      : 社員データ取込処理
 * MD.050           : MD050_CMM_002_A01_社員データ取込
 * Version          : Issue3.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_supervisor         管理者取得プロシージャ
 *  get_job                役職取得プロシージャ
 *  get_location           事業所取得プロシージャ
 *  wsh_grants_proc        出荷ロールマスタの登録・削除処理を行うプロシージャ
 *  po_agents_proc         購買担当マスタの登録・削除処理を行うプロシージャ
 *  ins_user_sec           セキュリティ属性登録プロシージャ
 *  get_ccid               CCID取得プロシージャ
 *  init_get_profile       プロファイル取得プロシージャ
 *  init_file_lock         ファイルロック処理プロシージャ
 *  check_aff_bumon        AFF部門マスタ存在チェック処理プロシージャ
 *  get_location_id        ユーザーIDを取得し存在チェックを行うプロシージャ
 *  in_if_check_emp        データ連携対象チェック処理プロシージャ
 *  in_if_check            データ妥当性チェック処理プロシージャ(A-4)
 *  check_fnd_user         ユーザーID取得処理プロシージャ
 *  check_fnd_lookup       コードテーブル（参照マスタ）存在ファンクション
 *  check_code             コード存在チェック処理
 *  get_fnd_responsibility 職責・管理者情報の取得処理プロシージャ(A-7)
 *  check_insert           社員データ登録分チェック処理プロシージャ(A-5)
 *  check_update           社員データ更新分チェック処理プロシージャ(A-6)
 *  add_report             社員データエラー情報格納処理(A-11)
 *  disp_report            レポート用データを出力するプロシージャ
 *  update_resp_all        ユーザー職責マスタの更新処理を行うプロシージャ
 *  delete_resp_all        ユーザー職責マスタのデータを無効化するプロシージャ
 *  insert_resp_all        ユーザー職責マスタの登録処理を行うプロシージャ
 *  get_service_id         サービス期間IDの取得を行うプロシージャ
 *  get_person_type        パーソンタイプの取得を行うプロシージャ
 *  changes_proc           異動処理を行うプロシージャ
 *  retire_proc            退職処理を行うプロシージャ
 *  re_hire_proc           再雇用処理を行うプロシージャ
 *  re_hire_ass_proc       再雇用処理(アサインメントマスタ)を行うプロシージャ
 *  insert_proc            新規社員の登録を行うプロシージャ
 *  update_proc            既存社員の更新を行うプロシージャ
 *  delete_proc            退職者の再雇用を行うプロシージャ
 *  init                   初期処理を行うプロシージャ(A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   SCS 工藤 真純    初回作成
 *  2009/03/09    1.1   SCS 竹下 昭範    正常終了時だけ、CSVファイルを削除するように変更
 *  2009/04/03    1.2   SCS 吉川 博章    追加従業員情報詳細のコンテキスト設定を追加
 *  2009/04/16    1.3   SCS 吉川 博章    障害No.483 対応
 *                                       submain の処理を大幅修正
 *  2009/05/21    1.4   SCS 吉川 博章    障害No.T1_0966 対応
 *  2009/05/29                           障害No.T1_0966 対応(再雇用時の対応漏れ)
 *  2009/06/02    1.5   SCS 西村 昇      障害No.T1_1277 対応(APIエラーメッセージ)
 *                                       障害No.T1_1278 対応(SQLパフォーマンス)
 *                                       旧コード類のチェック追加
 *  2009/06/23    1.6   SCS 吉川 博章    障害No.T1_1389 対応
 *                                       (アサイメント管理者の抽出方法・場所を変更)
 *  2009/06/25    1.7   SCS 吉川 博章    障害No.0000161 対応
 *  2009/07/06    1.8   SCS 伊藤 和之    障害No.0000412 対応(PT対応)
 *  2009/07/10    1.9   SCS 吉川 博章    障害No.0000492 対応
 *  2009/08/06    1.10  SCS 久保島 豊    障害No.0000510,0000793,0000794,0000869,0000910,0000924 対応
 *                                       0000510 役職の設定処理を追加
 *                                       0000793 発令日チェック変更
 *                                               (「発令日 > 業務日付」->「発令日 > 業務日付 + 1」)
 *                                       0000794 最上位の管理者の場合、管理者を設定しないように変更
 *                                       0000869 所属コード(旧)、勤務地拠点コード(旧)の存在チェック方法変更
 *                                               (「全部門階層ビュー」->「AFF部門」)
 *                                       0000910 購買担当マスタ、出荷ロールマスタ登録・削除処理追加
 *                                       0000924 所属コード(新)が財務経理部の場合、照会範囲に'T'を設定するように変更
 *  2009/09/04    1.11 SCS 久保島 豊     障害No.0001283 対応
 *                                       0001283 所属拠点の判定にNVLを追加
 *                                               従業員の割当てる順番を従業員番号 -> 職位並順の昇順,入社年月日の昇順に変更
 *                                               管理者割当カーソルに入社日の並び順を追加
 *  2009/10/29    1.12 SCS 久保島 豊     障害E_最終移行リハ_00368 対応
 *                                       ・管理者の割当を直UPDATEに変更
 *                                         (APIの割当の場合 管理者の入社年月日 <= 従業員の入社年月日 の制約があるため)
 *                                       ・管理者取得のSQLの入社年月日の条件を変更
 *                                         (「管理者の入社年月日 <= 入社年月日 <= 管理者の退職年月日」 -> 退職していない管理者)
 *                                       ・継続雇用時の退職処理の退職日設定を変更
 *                                         (既存入社年月日 -> 新入社年月日 - 1)
 *                                       ・PT対応 職責自動割当カーソルの抽出条件を追加
 *  2009/12/11    1.13 SCS 久保島 豊     障害E_本番_00148 対応
 *                                       ・lr_check_recの変数初期化処理を追加
 *                                       障害E_本稼動_00103 対応
 *                                       ・新所属拠点に紐付く職責がない場合も、職責は無効化するように変更
 *                                       ・ログの出力内容を所属コード(旧)と勤務地拠点コード(旧)の順番を入れ替えるように変更
 *                                       ・職責・管理者変更の条件変更
 *                                         管理者(所属コード(新)が変更された場合)
 *                                         職責(所属コード(新)、資格コード(新)、職位コード(新)、職種コード(新)、職務コード(新)が変更された場合)
 *                                       ・対象データ比較チェック変更
 *                                         (資格名(新・旧)、職位名(新・旧)、職種名(新・旧)、職務名(新・旧)、適用労働名(新・旧)は除く)
 *                                       ・管理者の導出元を変更
 *                                         (勤務地拠点コード(新) -> 所属コード(新))
 *  2009/12/11    1.14 SCS 久保島 豊     障害E_本番_00148 対応 
 *  2010/01/29    1.15 SCS 仁木 重人     障害E_本稼動_01216 対応 
 *  2010/02/25    1.16 SCS 仁木 重人     障害E_本稼動_01581 対応
 *                                       ・購買担当マスタの有効開始日に「発令日」を設定
 *                                       ・出荷ロールマスタの有効開始日を「業務日付」->「発令日」に変更
 *  2010/03/02    1.17 SCS 久保島 豊     障害E_本稼動01810 対応
 *                                       ・PT対応 ユーザー職責マスタ(fnd_user_resp_groups_all)の取得方法変更
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --
  --WHOカラム
  cn_created_by              CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date           CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by         CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date        CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login       CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date     CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part                CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name     VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status   VARCHAR2(30);              -- 処理結果
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
  gn_skip_cnt      NUMBER;                    -- スキップ件数
  --
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  global_process2_expt      EXCEPTION;
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
  lock_expt                    EXCEPTION;     -- ロック取得例外
  --
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_appl_short_name           CONSTANT VARCHAR2(10)  := 'XXCMM';             -- アドオン：マスタ
  cv_common_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF
  cv_pkg_name                  CONSTANT VARCHAR2(15)  := 'XXCMM002A01C';      -- パッケージ名
--
-- Ver1.2  2009/04/03 Add コンテキストに SALES-OU を設定 
  gn_org_id                    CONSTANT NUMBER        := FND_GLOBAL.ORG_ID;   -- ORG_ID
-- End
  --
  -- 更新区分をあらわすステータス(masters_rec.proc_flg)
  gv_sts_error                 CONSTANT VARCHAR2(1)   := 'E';   --ステータス(更新中止)
  gv_sts_thru                  CONSTANT VARCHAR2(1)   := 'S';   --ステータス(変更なし)
  gv_sts_update                CONSTANT VARCHAR2(1)   := 'U';   --ステータス(処理対象)
  -- 連携区分・入社日連携区分・退職連携・職責自動連携をあらわすステータス(masters_rec.proc_kbn,ymd_kbn,retire_kbn,resp_kbn,location_id_kbn)
  gv_sts_yes                   CONSTANT VARCHAR2(1)   := 'Y';   --ステータス(連携対象)
  -- 職責自動連携(masters_rec.resp_kbn)
  gv_sts_no                    CONSTANT VARCHAR2(1)   := 'N';   --ステータス(自動職責不可)
  --
  -- 現社員状態をあらわすステータス(masters_rec.emp_kbn)
  gv_kbn_new                   CONSTANT VARCHAR2(1)   := 'I';   --ステータス(現データなし：新規社員)
  gv_kbn_employee              CONSTANT VARCHAR2(1)   := 'U';   --ステータス(既存社員)
  gv_kbn_retiree               CONSTANT VARCHAR2(1)   := 'D';   --ステータス(退職者)
  --
  gv_msg_pnt                   CONSTANT VARCHAR2(3)   := ',';
  gv_flg_on                    CONSTANT VARCHAR2(1)   := '1';
  gv_const_y                   CONSTANT VARCHAR2(1)   := 'Y';
  --
  gv_def_sex                   CONSTANT VARCHAR2(1)   := 'M';
  gv_owner                     CONSTANT VARCHAR2(4)   := 'CUST';
  gv_info_category             CONSTANT VARCHAR2(2)   := 'JP';
  gv_in_if_name                CONSTANT VARCHAR2(100) := 'xxcmm_in_people_if';
  gv_upd_mode                  CONSTANT VARCHAR2(15)  := 'CORRECTION';
  gv_user_person_type          CONSTANT VARCHAR2(10)  := '従業員';
  gv_user_person_type_ex       CONSTANT VARCHAR2(10)  := '退職者';
  --
  --メッセージ番号
  --共通メッセージ番号
  --
  -- メッセージ番号(マスタ)
  cv_file_data_no_err          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';  -- 対象データ無しメッセージ
  cv_prf_get_err               CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';  -- プロファイル取得エラー
  cv_file_pass_err             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';  -- ファイルパス不正エラー
  cv_file_priv_err             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';  -- ファイルアクセス権限エラー
  cv_file_lock_err             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';  -- ロック取得NGメッセージ
  cv_csv_file_err              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00219';  -- CSVファイル存在チェック
  cv_api_err                   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00014';  -- APIエラー(コンカレント)
  cv_shozoku_err               CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00015';  -- 登録外所属コード
  cv_dup_val_err               CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00016';  -- ユーザー登録分の重複チェックエラー
  cv_not_found_err             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00017';  -- ユーザー更新分の存在チェックエラー
  cv_process_date_err          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';  -- 業務日付取得エラー
  cv_no_data_err               CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00025';  -- マスタ存在チェックエラー
  cv_log_err_msg               CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00039';  -- ログ出力失敗メッセージ
  cv_data_check_err            CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00200';  -- 取込チェックエラー
  cv_st_ymd_err1               CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00201';  -- 入社日過去日付け変更エラ
  cv_st_ymd_err2               CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00202';  -- 入社日＞退職日エラー
  cv_st_ymd_err3               CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00210';  -- 入社日未来日付社員（登録更新不可）エラー
  cv_retiree_err1              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00203';  -- 退職者情報変更エラー
  cv_retiree_err2              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00204';  -- 再雇用日エラー
--  cv_out_resp_msg              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00206';  -- 職責自動割当て不可能(正常)
  cv_rep_msg                   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00207';  -- エラーの処理結果リストの見出し
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
  cv_announce_ymd_err          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00222';  -- 入社日 > 発令日エラー
  cv_hire_ymd_change_err       CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00223';  -- 入社日変更エラー
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
  -- メッセージ番号(共通・IF)
  cv_target_rec_msg            CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_success_rec_msg           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_error_rec_msg             CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_skip_rec_msg              CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
  cv_normal_msg                CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
  cv_warn_msg                  CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
  cv_error_msg                 CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
  cv_file_name                 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';  -- ファイル名メッセージ
  cv_input_no_msg              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  --
  --プロファイル
  cv_prf_dir                   CONSTANT VARCHAR2(30)  := 'XXCMM1_JINJI_IN_DIR';          -- 人事(INBOUND)連携用CSVファイル保管場所
  cv_prf_fil                   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_IN_FILE';        -- 人事連携用社員データ取込用CSVファイル出力先
-- Ver1.3 Add  2009/04/16
  cv_prf_bks_name              CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_NAME';           -- 会計帳簿名
-- End Ver1.3
  cv_prf_supervisor            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_SUPERVISOR_CD';  -- 管理者従業員番号
-- Ver1.3 Del  2009/04/16  各セグメント毎にプロファイル定義し不要のため
--  cv_prf_default               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_DEFAULT_CD';   -- デフォルト費用勘定
-- End Ver1.3
-- Ver1.3 Add  2009/04/16  デフォルト費用勘定各ＡＦＦセグメント毎にプロファイル定義
  cv_prf_def_aff1              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_DEF_AFF1';     -- AFF1(SEG1:会社)
  cv_prf_def_aff3              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_DEF_AFF3';     -- AFF3(SEG3:勘定科目)
  cv_prf_def_aff4              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_DEF_AFF4';     -- AFF4(SEG4:補助科目)
  cv_prf_def_aff5              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_DEF_AFF5';     -- AFF5(SEG5:顧客コード)
  cv_prf_def_aff6              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_DEF_AFF6';     -- AFF6(SEG6:企業コード)
  cv_prf_def_aff7              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_DEF_AFF7';     -- AFF7(SEG7:予備1)
  cv_prf_def_aff8              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_DEF_AFF8';     -- AFF8(SEG8:予備2)
-- End Ver1.3
  cv_prf_password              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_PASSWORD';     -- 初期パスワード
-- 2009/08/06 Ver1.10 障害0000510,0000910,0000924 add start by Yutaka.Kuboshima
  cv_prf_base_manager          CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_JOB_BASE_MANAGER'; -- 拠点・部門管理者_役職名
  cv_prf_base_chrge            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_JOB_BASE_CHRGE';   -- 拠点・部門担当者_役職名
  cv_prf_po_chrge              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_JOB_PO_CHRGE';     -- PO_購買担当者_役職名
  cv_prf_role_id               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_ROLE_ID';          -- 役割ID
  cv_prf_zaimu_bumon_cd        CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_ZAIMU_BUMON_CD';   -- 財務経理部_部門コード
  cv_prf_aff_dept_cd           CONSTANT VARCHAR2(30)  := 'XXCMM1_AFF_DEPT_DUMMY_CD';       -- AFFダミー部門コード
-- 2009/08/06 Ver1.10 障害0000510,0000910,0000924 add end by Yutaka.Kuboshima
  --
  -- トークン
  cv_cnt_token                 CONSTANT VARCHAR2(10)  := 'COUNT';              -- 件数メッセージ用トークン名
  cv_tkn_ng_profile            CONSTANT VARCHAR2(15)  := 'NG_PROFILE';         -- エラープロファイル名
  cv_tkn_ng_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';            -- エラー項目名
  cv_tkn_ng_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';            -- エラーデータ
  cv_tkn_ng_table              CONSTANT VARCHAR2(10)  := 'NG_TABLE';           -- エラーテーブル
  cv_tkn_ng_code               CONSTANT VARCHAR2(10)  := 'NG_CODE';            -- エラーコード
  cv_tkn_ng_user               CONSTANT VARCHAR2(10)  := 'NG_USER';            -- エラー社員番号
  cv_tkn_ng_err                CONSTANT VARCHAR2(10)  := 'NG_ERR';             -- エラー内容
  cv_tkn_filename              CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- ファイル名
  cv_tkn_apiname               CONSTANT VARCHAR2(10)  := 'API_NAME';           -- API名
  cv_prf_dir_nm                CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';  -- プロファイル;
  cv_prf_fil_nm                CONSTANT VARCHAR2(20)  := 'CSVファイル名';      -- プロファイル;
  cv_prf_supervisor_nm         CONSTANT VARCHAR2(20)  := '管理者従業員番号';   -- プロファイル;
  cv_prf_supervisor_nm2        CONSTANT VARCHAR2(40)  := '管理者従業員番号(従業員未登録データ)'; -- プロファイル;
-- Ver1.3 Del  2009/04/16  各セグメント毎にプロファイル定義し不要のため
--  cv_prf_default_nm            CONSTANT VARCHAR2(20)  := 'デフォルト費用勘定'; -- プロファイル;
-- End Ver1.3
-- Ver1.3 Add  2009/04/16  デフォルト費用勘定各ＡＦＦセグメント毎にプロファイル定義
  cv_prf_def_aff1_nm           CONSTANT VARCHAR2(40)  := 'デフォルト費用勘定ＡＦＦ１：会社';
  cv_prf_def_aff3_nm           CONSTANT VARCHAR2(40)  := 'デフォルト費用勘定ＡＦＦ３：勘定科目';
  cv_prf_def_aff4_nm           CONSTANT VARCHAR2(40)  := 'デフォルト費用勘定ＡＦＦ４：補助科目';
  cv_prf_def_aff5_nm           CONSTANT VARCHAR2(40)  := 'デフォルト費用勘定ＡＦＦ５：顧客コード';
  cv_prf_def_aff6_nm           CONSTANT VARCHAR2(40)  := 'デフォルト費用勘定ＡＦＦ６：企業コード';
  cv_prf_def_aff7_nm           CONSTANT VARCHAR2(40)  := 'デフォルト費用勘定ＡＦＦ７：予備１';
  cv_prf_def_aff8_nm           CONSTANT VARCHAR2(40)  := 'デフォルト費用勘定ＡＦＦ８：予備２';
-- End Ver1.3
-- 2009/08/06 Ver1.10 障害0000510,0000910,0000924 add start by Yutaka.Kuboshima
  cv_prf_base_manager_nm       CONSTANT VARCHAR2(40)  := '拠点・部門管理者_役職名';
  cv_prf_base_chrge_nm         CONSTANT VARCHAR2(40)  := '拠点・部門担当者_役職名';
  cv_prf_po_chrge_nm           CONSTANT VARCHAR2(40)  := 'PO_購買担当者_役職名';
  cv_prf_role_id_nm            CONSTANT VARCHAR2(40)  := '役割ID';
  cv_prf_zaimu_bumon_cd_nm     CONSTANT VARCHAR2(40)  := '財務経理部_部門コード';
  cv_prf_aff_dept_cd_nm        CONSTANT VARCHAR2(40)  := 'AFF部門ダミーコード';
-- 2009/08/06 Ver1.10 障害0000510,0000910,0000924 add end by Yutaka.Kuboshima
  cv_prf_password_nm           CONSTANT VARCHAR2(20)  := '初期パスワード';       -- プロファイル;
  cv_xxcmm1_in_if_nm           CONSTANT VARCHAR2(20)  := '社員インタフェース';   -- ファイル名
  cv_per_all_people_f_nm       CONSTANT VARCHAR2(20)  := '従業員マスタ';         -- ファイル名
  cv_per_all_assignments_f_nm  CONSTANT VARCHAR2(30)  := 'アサインメントマスタ'; -- ファイル名
  cv_fnd_user_nm               CONSTANT VARCHAR2(20)  := 'ユーザーマスタ';       -- ファイル名
  cv_fnd_user_resp_group_a_nm  CONSTANT VARCHAR2(20)  := 'ユーザー職責マスタ';   -- ファイル名
--Ver1.5 Add 2009/06/02
  cv_mst_tbl                   CONSTANT VARCHAR2(20)  := '社員情報';             -- メッセージ
--End Ver1.5
  cv_employee_nm               CONSTANT VARCHAR2(10)  := '社員番号';             -- 項目名
  cv_employee_err_nm           CONSTANT VARCHAR2(20)  := '社員番号重複';         -- 項目名
  cv_data_err                  CONSTANT VARCHAR2(20)  := 'データ異常';           -- 項目名
  --
  --参照コードマスタ.タイプ(fnd_lookup_values_vl.lookup_type)
  cv_flv_license               CONSTANT VARCHAR2(30)  := 'XXCMM_QUALIFICATION_CODE';    -- 資格テーブル
  cv_flv_job_post              CONSTANT VARCHAR2(30)  := 'XXCMM_POSITION_CODE';         -- 職位テーブル
  cv_flv_job_duty              CONSTANT VARCHAR2(30)  := 'XXCMM_JOB_CODE';              -- 職務テーブル
  cv_flv_job_type              CONSTANT VARCHAR2(30)  := 'XXCMM_OCCUPATIONAL_CODE';     -- 職種テーブル
  cv_flv_job_system            CONSTANT VARCHAR2(30)  := 'XXCMM_002A01_**';             -- 適用労働時間制テーブル
  cv_flv_consent               CONSTANT VARCHAR2(30)  := 'XXCMM_002A01_**';             -- 承認区分テーブル
  cv_flv_agent                 CONSTANT VARCHAR2(30)  := 'XXCMM_002A01_**';             -- 代行区分テーブル
  cv_flv_responsibility        CONSTANT VARCHAR2(30)  := 'XXCMM1_002A01_RESP';          -- 職責自動割当テーブル
  --
  -- テーブル名
  cd_sysdate                   DATE := SYSDATE;                -- 処理開始時間(YYYYMMDDHH24MISS)
  cd_process_date              DATE;                           -- 業務日付(YYYYMMDD)
  cc_process_date              CHAR(8);                        -- 業務日付(YYYYMMDD)
  --
-- Ver1.3 Add  2009/04/16  従業員 郵便送付先設定用
  cv_send_to_addres            CONSTANT VARCHAR2(1)   := 'O';    -- 郵便送付先(コード)
-- End Ver1.3
--
-- Ver1.4 Add  2009/05/21  アプリケーション短縮名(ICX)、セキュリティ属性名の固定値を追加  T1_0966
  cv_appl_short_nm_icx         CONSTANT VARCHAR2(10)  := 'ICX';                 -- Self-Service Web Applications
  cv_att_code_ihp              CONSTANT VARCHAR2(20)  := 'ICX_HR_PERSON_ID';    -- セキュリティ属性名（ICX_HR_PERSON_ID）
  cv_att_code_tp               CONSTANT VARCHAR2(20)  := 'TO_PERSON_ID';        -- セキュリティ属性名（TO_PERSON_ID）
-- End Ver1.4
-- 2009/08/06 Ver1.10 障害0000510,0000869,0000910 add start by Yutaka.Kuboshima
  cv_permission_on             CONSTANT VARCHAR2(1)   := '1';                   -- 購買担当、出荷担当権限有
  cv_permission_off            CONSTANT VARCHAR2(1)   := '0';                   -- 購買担当、出荷担当権限無
--
  cv_flex_aff_bumon            CONSTANT VARCHAR2(30)  := 'XX03_DEPARTMENT';     -- 値セット名(AFF部門)
  cv_no                        CONSTANT VARCHAR2(1)   := 'N';                   -- 有効フラグ(N)
-- 2009/08/06 Ver1.10 障害0000510,0000869,0000910 add start by Yutaka.Kuboshima
--
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX add start by Yutaka.Kuboshima
  cn_partition_id              CONSTANT NUMBER        := 2;                     -- パーティションID
  cv_role_orig_system          CONSTANT VARCHAR2(10)  := 'FND_RESP';            -- ロールシステム名
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX add end by Yutaka.Kuboshima
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  -- 各マスタへの反映処理に必要なデータを格納するレコード
  TYPE masters_rec IS RECORD(
   -- 従業員インタフェース
    -- 区分
    proc_flg                   VARCHAR2(1),     -- 更新区分('U':処理対象(gv_sts_update),'E':更新不可能(gv_sts_error),'S':変更なし(gv_sts_thru))
    proc_kbn                   VARCHAR2(1),     -- 連携区分('Y':連携するデータ)
    emp_kbn                    VARCHAR2(1),     -- 社員状態('I':新規社員(gv_kbn_new)、'U'：既存社員(gv_kbn_employee)、'D'：退職者(gv_kbn_retiree))
    ymd_kbn                    VARCHAR2(1),     -- 入社日連携区分('Y':日付変更データ)
    retire_kbn                 VARCHAR2(1),     -- 退職区分('Y':退職するデータ)
    resp_kbn                   VARCHAR2(1),     -- 職責・管理者変更区分('Y':変更するデータ,'N':自動割当不可,NULL：変更しない)
-- 2009/12/11 Ver1.13 E_本稼動_00103 add start by Y.Kuboshima
    supervisor_kbn             VARCHAR2(1),     -- 管理者変更区分('Y':変更する)
-- 2009/12/11 Ver1.13 E_本稼動_00103 add end by Y.Kuboshima
    location_id_kbn            VARCHAR2(1),     -- 事業所変更区分('Y':変更する)
    row_err_message            VARCHAR2(1000),  -- 警告メッセージ
    -- 社員取込インタフェース
    employee_number            xxcmm_in_people_if.employee_number%TYPE,              -- 社員番号
    hire_date                  xxcmm_in_people_if.hire_date%TYPE,                    -- 入社年月日
    actual_termination_date    xxcmm_in_people_if.actual_termination_date%TYPE,      -- 退職年月日
    last_name_kanji            xxcmm_in_people_if.last_name_kanji%TYPE,              -- 漢字姓
    first_name_kanji           xxcmm_in_people_if.first_name_kanji%TYPE,             -- 漢字名
    last_name                  xxcmm_in_people_if.last_name%TYPE,                    -- カナ姓
    first_name                 xxcmm_in_people_if.first_name%TYPE,                   -- カナ名
    sex                        xxcmm_in_people_if.sex%TYPE,                          -- 性別
    employee_division          xxcmm_in_people_if.employee_division%TYPE,            -- 社員・外部委託区分
    location_code              xxcmm_in_people_if.location_code%TYPE,                -- 所属コード（新）
    change_code                xxcmm_in_people_if.change_code%TYPE,                  -- 異動事由コード
    announce_date              xxcmm_in_people_if.announce_date%TYPE,                -- 発令日
    office_location_code       xxcmm_in_people_if.office_location_code%TYPE,         -- 勤務地拠点コード（新）
    license_code               xxcmm_in_people_if.license_code%TYPE,                 -- 資格コード（新）
    license_name               xxcmm_in_people_if.license_name%TYPE,                 -- 資格名（新）
    job_post                   xxcmm_in_people_if.job_post%TYPE,                     -- 職位コード（新）
    job_post_name              xxcmm_in_people_if.job_post_name%TYPE,                -- 職位名（新）
    job_duty                   xxcmm_in_people_if.job_duty%TYPE,                     -- 職務コード（新）
    job_duty_name              xxcmm_in_people_if.job_duty_name%TYPE,                -- 職務名（新）
    job_type                   xxcmm_in_people_if.job_type%TYPE,                     -- 職種コード（新）
    job_type_name              xxcmm_in_people_if.job_type_name%TYPE,                -- 職種名（新）
    job_system                 xxcmm_in_people_if.job_system%TYPE,                   -- 適用労働時間制コード（新）
    job_system_name            xxcmm_in_people_if.job_system_name%TYPE,              -- 適用労働名（新）
    job_post_order             xxcmm_in_people_if.job_post_order%TYPE,               -- 職位並順コード（新）
    consent_division           xxcmm_in_people_if.consent_division%TYPE,             -- 承認区分（新）
    agent_division             xxcmm_in_people_if.agent_division%TYPE,               -- 代行区分（新）
    office_location_code_old   xxcmm_in_people_if.office_location_code_old%TYPE,     -- 勤務地拠点コード（旧）
    location_code_old          xxcmm_in_people_if.location_code_old%TYPE,            -- 所属コード（旧）
    license_code_old           xxcmm_in_people_if.license_code_old%TYPE,             -- 資格コード（旧）
    license_code_name_old      xxcmm_in_people_if.license_code_name_old%TYPE,        -- 資格名（旧）
    job_post_old               xxcmm_in_people_if.job_post_old%TYPE,                 -- 職位コード（旧）
    job_post_name_old          xxcmm_in_people_if.job_post_name_old%TYPE,            -- 職位名（旧）
    job_duty_old               xxcmm_in_people_if.job_duty_old%TYPE,                 -- 職務コード（旧）
    job_duty_name_old          xxcmm_in_people_if.job_duty_name_old%TYPE,            -- 職務名（旧）
    job_type_old               xxcmm_in_people_if.job_type_old%TYPE,                 -- 職種コード（旧）
    job_type_name_old          xxcmm_in_people_if.job_type_name_old%TYPE,            -- 職種名（旧）
    job_system_old             xxcmm_in_people_if.job_system_old%TYPE,               -- 適用労働時間制コード（旧）
    job_system_name_old        xxcmm_in_people_if.job_system_name_old%TYPE,          -- 適用労働名（旧）
    job_post_order_old         xxcmm_in_people_if.job_post_order_old%TYPE,           -- 職位並順コード（旧）
    consent_division_old       xxcmm_in_people_if.consent_division_old%TYPE,         -- 承認区分（旧）
    agent_division_old         xxcmm_in_people_if.agent_division_old%TYPE,           -- 代行区分（旧）
    -- 従業員マスタ
    person_id                  per_all_people_f.person_id%TYPE,                      -- 従業員ID
    hire_date_old              per_all_people_f.effective_start_date%TYPE,           -- 既存_入社年月日
    pap_version                per_all_people_f.object_version_number%TYPE,          -- バージョン番号
    -- アサインメントマスタ
    assignment_id              per_all_assignments_f.assignment_id%TYPE,             -- アサインメントID
    assignment_number          per_all_assignments_f.assignment_number%TYPE,         -- アサインメント番号
    effective_start_date       per_all_assignments_f.effective_start_date%TYPE,      -- 登録年月日
    effective_end_date         per_all_assignments_f.effective_end_date%TYPE,        -- 登録期限年月日
    location_id                per_all_assignments_f.location_id%TYPE,               -- 事業所
    supervisor_id              per_all_assignments_f.supervisor_id%TYPE,             -- 管理者
    paa_version                per_all_assignments_f.object_version_number%TYPE,     -- バージョン番号
-- Ver1.3 Add  2009/04/16  デフォルト費用勘定ＣＣＩＤを追加
    default_code_comb_id       per_all_assignments_f.default_code_comb_id%TYPE,      -- デフォルト費用勘定
-- End Ver1.3
    -- ユーザマスタ
    user_id                    fnd_user.user_id%TYPE,                                -- ユーザーID
    -- サービス期間マスタ
    period_of_service_id       per_periods_of_service.period_of_service_id%TYPE,     -- サービスID
    ppos_version               per_periods_of_service.object_version_number%TYPE     -- バージョン番号
  );
  --
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY BINARY_INTEGER;
  --
  -- 各マスタのデータを格納するレコード
  TYPE check_rec IS RECORD(
    -- 従業員マスタ
    person_id                  per_all_people_f.person_id%TYPE,                      -- 従業員ID
    effective_start_date       per_all_people_f.effective_start_date%TYPE,           -- 登録年月日
    last_name                  per_all_people_f.last_name%TYPE,                      -- カナ姓
    employee_number            per_all_people_f.employee_number%TYPE,                -- 従業員番号
    first_name                 per_all_people_f.first_name%TYPE,                     -- カナ名
    sex                        per_all_people_f.sex%TYPE,                            -- 性別
    employee_division          per_all_people_f.attribute3%TYPE,                     -- 従業員区分
    license_code               per_all_people_f.attribute7%TYPE,                     -- 資格コード（新）
    license_name               per_all_people_f.attribute8%TYPE,                     -- 資格名（新）
    job_post                   per_all_people_f.attribute11%TYPE,                    -- 職位コード（新）
    job_post_name              per_all_people_f.attribute12%TYPE,                    -- 職位名（新）
    job_duty                   per_all_people_f.attribute15%TYPE,                    -- 職務コード（新）
    job_duty_name              per_all_people_f.attribute16%TYPE,                    -- 職務名（新）
    job_type                   per_all_people_f.attribute19%TYPE,                    -- 職種コード（新）
    job_type_name              per_all_people_f.attribute20%TYPE,                    -- 職種名（新）
    license_code_old           per_all_people_f.attribute9%TYPE,                     -- 資格コード（旧）
    license_code_name_old      per_all_people_f.attribute10%TYPE,                    -- 資格名（旧）
    job_post_old               per_all_people_f.attribute13%TYPE,                    -- 職位コード（旧）
    job_post_name_old          per_all_people_f.attribute14%TYPE,                    -- 職位名（旧）
    job_duty_old               per_all_people_f.attribute17%TYPE,                    -- 職務コード（旧）
    job_duty_name_old          per_all_people_f.attribute18%TYPE,                    -- 務名（旧）
    job_type_old               per_all_people_f.attribute21%TYPE,                    -- 職種コード（旧）
    job_type_name_old          per_all_people_f.attribute22%TYPE,                    -- 職種名（旧）
    pap_location_id            per_all_people_f.attribute28%TYPE,                    -- 起票部門
    last_name_kanji            per_all_people_f.per_information18%TYPE,              -- 漢字姓
    first_name_kanji           per_all_people_f.per_information19%TYPE,              -- 漢字名
    pap_version                per_all_people_f.object_version_number%TYPE,          -- バージョン番号
    -- アサインメントマスタ
    assignment_id              per_all_assignments_f.assignment_id%TYPE,             -- アサインメントID
    assignment_number          per_all_assignments_f.assignment_number%TYPE,         -- アサインメント番号
    paa_effective_start_date   per_all_assignments_f.effective_start_date%TYPE,      -- 登録年月日
    paa_effective_end_date     per_all_assignments_f.effective_end_date%TYPE,        -- 登録期限年月日
    location_id                per_all_assignments_f.location_id%TYPE,               -- 事業所
    supervisor_id              per_all_assignments_f.supervisor_id%TYPE,             -- 管理者
    change_code                per_all_assignments_f.ass_attribute1%TYPE,            -- 異動事由コード
    announce_date              per_all_assignments_f.ass_attribute2%TYPE,            -- 発令日
    office_location_code       per_all_assignments_f.ass_attribute3%TYPE,            -- 勤務地拠点コード（新）
    office_location_code_old   per_all_assignments_f.ass_attribute4%TYPE,            -- 勤務地拠点コード（旧）
    location_code              per_all_assignments_f.ass_attribute5%TYPE,            -- 拠点コード（新）
    location_code_old          per_all_assignments_f.ass_attribute6%TYPE,            -- 拠点コード（旧）
    job_system                 per_all_assignments_f.ass_attribute7%TYPE,            -- 適用労働時間制コード（新）
    job_system_name            per_all_assignments_f.ass_attribute8%TYPE,            -- 適用労働名（新）
    job_system_old             per_all_assignments_f.ass_attribute9%TYPE,            -- 適用労働時間制コード（旧）
    job_system_name_old        per_all_assignments_f.ass_attribute10%TYPE,           -- 適用労働名（旧）
    job_post_order             per_all_assignments_f.ass_attribute11%TYPE,           -- 職位並順コード（新）
    job_post_order_old         per_all_assignments_f.ass_attribute12%TYPE,           -- 職位並順コード（旧）
    consent_division           per_all_assignments_f.ass_attribute13%TYPE,           -- 承認区分（新）
    consent_division_old       per_all_assignments_f.ass_attribute14%TYPE,           -- 承認区分（旧）
    agent_division             per_all_assignments_f.ass_attribute15%TYPE,           -- 代行区分（新）
    agent_division_old         per_all_assignments_f.ass_attribute16%TYPE,           -- 代行区分（旧）
    paa_version                per_all_assignments_f.object_version_number%TYPE,     -- バージョン番号(アサインメント)
-- Ver1.3 Add  2009/04/16  デフォルト費用勘定ＣＣＩＤを追加
    default_code_comb_id       per_all_assignments_f.default_code_comb_id%TYPE,      -- デフォルト費用勘定
-- End Ver1.3
    -- 従業員サービス期間マスタ
    period_of_service_id       per_periods_of_service.period_of_service_id%TYPE,     -- サービスID
    actual_termination_date    per_periods_of_service.actual_termination_date%TYPE,  -- 退職年月日
    ppos_version               per_periods_of_service.object_version_number%TYPE
  );
  --
  lr_check_rec                 check_rec;  -- マスタ取得データ格納エリア
  --
  -- 出力するログを格納するレコード
  TYPE report_rec IS RECORD(
    -- 区分(masterと同じ)
    proc_flg                   VARCHAR2(1),  -- 更新区分('U':処理対象,'E':更新不可能,'S':変更なし)
    -- 出力内容(社員インターフェースと同じ)
    employee_number            xxcmm_in_people_if.employee_number%TYPE,           -- 社員番号
    hire_date                  xxcmm_in_people_if.hire_date%TYPE,                 -- 入社年月日
    actual_termination_date    xxcmm_in_people_if.actual_termination_date%TYPE,   -- 退職年月日
    last_name_kanji            xxcmm_in_people_if.last_name_kanji%TYPE,           -- 漢字姓
    first_name_kanji           xxcmm_in_people_if.first_name_kanji%TYPE,          -- 漢字名
    last_name                  xxcmm_in_people_if.last_name%TYPE,                 -- カナ姓
    first_name                 xxcmm_in_people_if.first_name%TYPE,                -- カナ名
    sex                        xxcmm_in_people_if.sex%TYPE,                       -- 性別
    employee_division          xxcmm_in_people_if.employee_division%TYPE,         -- 社員・外部委託区分
    location_code              xxcmm_in_people_if.location_code%TYPE,             -- 所属コード（新）
    change_code                xxcmm_in_people_if.change_code%TYPE,               -- 異動事由コード
    announce_date              xxcmm_in_people_if.announce_date%TYPE,             -- 発令日
    office_location_code       xxcmm_in_people_if.office_location_code%TYPE,      -- 勤務地拠点コード（新）
    license_code               xxcmm_in_people_if.license_code%TYPE,              -- 資格コード（新）
    license_name               xxcmm_in_people_if.license_name%TYPE,              -- 資格名（新）
    job_post                   xxcmm_in_people_if.job_post%TYPE,                  -- 職位コード（新）
    job_post_name              xxcmm_in_people_if.job_post_name%TYPE,             -- 職位名（新）
    job_duty                   xxcmm_in_people_if.job_duty%TYPE,                  -- 職務コード（新）
    job_duty_name              xxcmm_in_people_if.job_duty_name%TYPE,             -- 職務名（新）
    job_type                   xxcmm_in_people_if.job_type%TYPE,                  -- 職種コード（新）
    job_type_name              xxcmm_in_people_if.job_type_name%TYPE,             -- 職種名（新）
    job_system                 xxcmm_in_people_if.job_system%TYPE,                -- 適用労働時間制コード（新）
    job_system_name            xxcmm_in_people_if.job_system_name%TYPE,           -- 適用労働名（新）
    job_post_order             xxcmm_in_people_if.job_post_order%TYPE,            -- 職位並順コード（新）
    consent_division           xxcmm_in_people_if.consent_division%TYPE,          -- 承認区分（新）
    agent_division             xxcmm_in_people_if.agent_division%TYPE,            -- 代行区分（新）
    office_location_code_old   xxcmm_in_people_if.office_location_code_old%TYPE,  -- 勤務地拠点コード（旧）
    location_code_old          xxcmm_in_people_if.location_code_old%TYPE,         -- 所属コード（旧）
    license_code_old           xxcmm_in_people_if.license_code_old%TYPE,          -- 資格コード（旧）
    license_code_name_old      xxcmm_in_people_if.license_code_name_old%TYPE,     -- 資格名（旧）
    job_post_old               xxcmm_in_people_if.job_post_old%TYPE,              -- 職位コード（旧）
    job_post_name_old          xxcmm_in_people_if.job_post_name_old%TYPE,         -- 職位名（旧）
    job_duty_old               xxcmm_in_people_if.job_duty_old%TYPE,              -- 職務コード（旧）
    job_duty_name_old          xxcmm_in_people_if.job_duty_name_old%TYPE,         -- 職務名（旧）
    job_type_old               xxcmm_in_people_if.job_type_old%TYPE,              -- 職種コード（旧）
    job_type_name_old          xxcmm_in_people_if.job_type_name_old%TYPE,         -- 職種名（旧）
    job_system_old             xxcmm_in_people_if.job_system_old%TYPE,            -- 適用労働時間制コード（旧）
    job_system_name_old        xxcmm_in_people_if.job_system_name_old%TYPE,       -- 適用労働名（旧）
    job_post_order_old         xxcmm_in_people_if.job_post_order_old%TYPE,        -- 職位並順コード（旧）
    consent_division_old       xxcmm_in_people_if.consent_division_old%TYPE,      -- 承認区分（旧）
    agent_division_old         xxcmm_in_people_if.agent_division_old%TYPE,        -- 代行区分（旧）
    --
    message                    VARCHAR2(1000)
  );
  --
  -- 出力するレポートを格納する結合配列
  TYPE report_normal_tbl  IS TABLE OF report_rec   INDEX BY BINARY_INTEGER;
  TYPE report_warn_tbl    IS TABLE OF report_rec   INDEX BY BINARY_INTEGER;
  --
-- Ver1.4 Add  2009/05/21  セキュリティ属性登録用配列用構造体を追加  T1_0966
  -- セキュリティ属性登録用配列用構造体
  TYPE sec_att_code_ttype IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;
-- End Ver1.4
--
-- Ver1.3 Add  2009/04/16  ＣＣＩＤ取得用（fnd_flex_ext.get_combination_id）
  g_aff_segments_tab           fnd_flex_ext.segmentarray;
-- End Ver1.3
-- Ver1.4 Add  2009/05/21  セキュリティ属性登録用配列用構造体を追加  T1_0966
  -- セキュリティ属性登録用配列
  g_sec_att_code_tab           sec_att_code_ttype;
-- End Ver1.4
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- Ver1.3 Del  2009/04/16  使用しないため削除
--  gn_if                        NUMBER;     -- 社員インターフェースカウント
-- End Ver1.3
  gn_rep_n_cnt                 NUMBER;     -- レポート件数(正常)
  gn_rep_w_cnt                 NUMBER;     -- レポート件数(警告)
  --
  gv_bisiness_grp_id           per_person_types.business_group_id%TYPE;    -- ビジネスグループID(従業員)
  gv_bisiness_grp_id_ex        per_person_types.business_group_id%TYPE;    -- ビジネスグループID(退職者)
  gv_person_type               per_person_types.person_type_id%TYPE;       -- パーソンタイプ(従業員)
  gv_person_type_ex            per_person_types.person_type_id%TYPE;       -- パーソンタイプ(退職者)
  --
--プロファイル
  gv_directory                 VARCHAR2(255);         -- プロファイル・ファイルパス名
  gv_file_name                 VARCHAR2(255);         -- プロファイル・ファイル名
  gv_supervisor                VARCHAR2(255);         -- プロファイル・管理者従業員番号
-- Ver1.3 Del  2009/04/16  各セグメント毎にプロファイル定義し不要のため
--  gv_default                  VARCHAR2(255);          -- プロファイル・デフォルト費用勘定
-- End Ver1.3
  gv_password                  VARCHAR2(255);         -- プロファイル・初期パスワード
  gn_person_id                 NUMBER(10);            -- ﾌﾟﾛﾌｧｲﾙ管理者従業員番号をパーソンIDに変換
  gn_person_start              DATE;                  -- ﾌﾟﾛﾌｧｲﾙ管理者の入社年月日
--
-- Ver1.3 Add  2009/04/16  ＣＣＩＤ取得用（fnd_flex_ext.get_combination_id）
  gn_set_of_book_id            gl_sets_of_books.set_of_books_id%TYPE;
  gn_chart_of_acct_id          gl_sets_of_books.chart_of_accounts_id%TYPE;
  gv_id_flex_code              fnd_id_flex_structures_vl.id_flex_code%TYPE;
-- End Ver1.3
-- Ver1.4 Add  2009/05/21  アプリケーションID(ICX)用変数を追加  T1_0966
  -- アプリケーションID【ICX：Self-Service Web Applications】
  gn_appl_id_icx               fnd_application.application_id%TYPE;
-- End Ver1.4
-- 2009/08/06 Ver1.10 障害0000510,0000910,0000924 add start by Yutaka.Kuboshima
  gv_base_manager              VARCHAR2(255);         -- 拠点・部門担当者_役職名
  gv_base_chrge                VARCHAR2(255);         -- 拠点・部門管理者_役職名
  gv_po_chrge                  VARCHAR2(255);         -- PO_購買担当者_役職名
  gn_role_id                   NUMBER;                -- 役割ID
  gv_zaimu_bumon_cd            VARCHAR2(255);         -- 財務経理部_部門コード
  gv_aff_dept_cd               VARCHAR2(255);         -- AFFダミー部門コード
-- 2009/08/06 Ver1.10 障害0000510,0000910,0000924 add end by Yutaka.Kuboshima
--
  gf_file_hand                 UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
--
-- Ver1.3 Del  2009/04/16  グローバルである必要がなく、TABLEタイプである必要もないため削除
--  gt_mst_tbl                   masters_tbl;          -- 結合配列の定義
-- End Ver1.3
  gt_report_normal_tbl         report_normal_tbl;    -- 結合配列の定義
  gt_report_warn_tbl           report_warn_tbl;      -- 結合配列の定義
  --
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
  gv_retcode                   VARCHAR2(1);          -- 処理結果
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX add start by Yutaka.Kuboshima
  gn_security_group_id         NUMBER;               -- セキュリティグループID
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX add end by Yutaka.Kuboshima
  -- 定数
  gn_created_by                NUMBER;               -- 作成者
  gd_creation_date             DATE;                 -- 作成日
  gd_last_update_date          DATE;                 -- 最終更新日
  gn_last_update_by            NUMBER;               -- 最終更新者
  gn_last_update_login         NUMBER;               -- 最終更新ログイン
  gn_request_id                NUMBER;               -- 要求ID
  gn_program_application_id    NUMBER;               -- プログラムアプリケーションID
  gn_program_id                NUMBER;               -- プログラムID
  gd_program_update_date       DATE;                 -- プログラム更新日
  --
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  --
-- Ver 1.5 Add  2009/06/02  T1_1278
--  -- 社員インタフェース
--  CURSOR gc_xip_cur
--  IS
--    SELECT xip.employee_number
--    FROM   xxcmm_in_people_if xip    -- 従業員マスタ
--    FOR UPDATE OF xip.employee_number NOWAIT;
--  --
--  -- 従業員マスタ
--  CURSOR gc_ppf_cur
--  IS
--    SELECT pap.person_id
--    FROM   per_all_people_f pap    -- 従業員マスタ
--    WHERE  EXISTS
--          (SELECT xip.employee_number
--           FROM   xxcmm_in_people_if xip    -- 社員インタフェース
--           WHERE  xip.employee_number = pap.employee_number)
--    FOR UPDATE OF pap.person_id NOWAIT;
--  --
--  -- アサインメントマスタ
--  CURSOR gc_paf_cur
--  IS
--    SELECT paa.assignment_id
--    FROM   per_all_assignments_f paa    -- アサインメントマスタ
--    WHERE  EXISTS
--          (SELECT pap.person_id
--           FROM   per_all_people_f pap    -- 従業員マスタ
--           WHERE  EXISTS
--                 (SELECT xip.employee_number
--                  FROM   xxcmm_in_people_if xip    -- 社員インタフェース
--                  WHERE  xip.employee_number = pap.employee_number)
--           AND    pap.person_id = paa.person_id)
--    FOR UPDATE OF paa.assignment_id NOWAIT;
--  --
--  -- ユーザーマスタ
--  CURSOR gc_fu_cur
--  IS
--    SELECT fu.user_id
--    FROM   fnd_user fu    -- ユーザーマスタ
--    WHERE  EXISTS
--          (SELECT pap.person_id
--           FROM   per_all_people_f pap    -- 従業員マスタ
--           WHERE  EXISTS
--                 (SELECT xip.employee_number
--                  FROM   xxcmm_in_people_if xip    -- 社員インタフェース
--                  WHERE  xip.employee_number = pap.employee_number)
--           AND    pap.person_id = fu.employee_id)
--    FOR UPDATE OF fu.user_id NOWAIT;
--  --
--  -- ユーザー職責マスタ
--  CURSOR gc_fug_cur
--  IS
--    SELECT fug.user_id
--    FROM   fnd_user_resp_groups_all fug    -- ユーザー職責マスタ
--    WHERE  EXISTS
--          (SELECT fu.user_id
--           FROM   fnd_user fu    -- ユーザーマスタ
--           WHERE  EXISTS
--                 (SELECT pap.person_id
--                  FROM   per_all_people_f pap    -- 従業員マスタ
--                  WHERE  EXISTS
--                        (SELECT xip.employee_number
--                         FROM   xxcmm_in_people_if xip    -- 社員インタフェース
--                         WHERE  xip.employee_number = pap.employee_number)
--                  AND    pap.person_id = fu.employee_id)
--           AND    fu.user_id = fug.user_id)
--    FOR UPDATE OF fug.user_id NOWAIT;
  CURSOR gc_fug_cur
  IS
    SELECT xip.employee_number
          ,pap.person_id
          ,paa.assignment_id
          ,fu.user_id
          ,fug.user_id
    FROM   xxcmm_in_people_if xip          -- 社員インタフェース
          ,per_all_people_f pap            -- 従業員マスタ
          ,per_all_assignments_f paa       -- アサインメントマスタ
          ,fnd_user fu                     -- ユーザーマスタ
          ,fnd_user_resp_groups_all fug    -- ユーザー職責マスタ
    WHERE  xip.employee_number = pap.employee_number
    AND    pap.person_id       = paa.person_id
    AND    pap.person_id       = fu.employee_id
    AND    fu.user_id          = fug.user_id
    FOR UPDATE OF xip.employee_number
                 ,pap.person_id
                 ,paa.assignment_id
                 ,fu.user_id
                 ,fug.user_id NOWAIT;
-- End Ver 1.5
--
-- Ver1.6 Add  2009/06/22  管理者取得プロシージャを追加  T1_1389
  /***********************************************************************************
   * Procedure Name   : get_supervisor
   * Description      : 管理者を取得します。
   ***********************************************************************************/
  PROCEDURE get_supervisor(
    in_person_id               IN  NUMBER         --  従業員ID
   ,iv_office_location_code    IN  VARCHAR2       --  勤務地拠点コード(新)
   ,iv_job_post_order          IN  VARCHAR2       --  職位並順コード（新)
   ,id_hire_date               IN  DATE           --  入社日
   ,on_supervisor_id           OUT NUMBER         --  管理者ID
   ,ov_errbuf                  OUT VARCHAR2       --  エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2       --  リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2 )     --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_supervisor';   -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
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
    -- *** ローカル変数 ***
    ln_supervisor_id       per_all_people_f.person_id%TYPE;    -- 管理者(従業員)ID
    --
    -- 管理者割当カーソル
    CURSOR get_supervisor_cur
    IS
      SELECT    paa.person_id             person_id      -- 従業員ID
      FROM      per_periods_of_service    ppos           -- 従業員サービス期間マスタ
               ,per_all_assignments_f     paa            -- アサインメントマスタ
      WHERE     paa.person_id                            != in_person_id                    -- 自身以外
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
--      AND       paa.ass_attribute3                        = iv_office_location_code         -- 勤務地拠点コード(新)
      AND       paa.ass_attribute5                        = iv_office_location_code         -- 所属コード(新)
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify end by Y.Kuboshima
      AND       TO_NUMBER(NVL(paa.ass_attribute11,'99')) >  0                               -- 職位並順コード（新)
      AND       TO_NUMBER(NVL(paa.ass_attribute11,'99')) <= TO_NUMBER( iv_job_post_order )
      AND       paa.period_of_service_id                  = ppos.period_of_service_id       -- サービスID
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 管理者取得時の入社年月日チェックを変更
--      AND       ppos.date_start                          <= id_hire_date                    -- 入社日
--      AND       NVL( ppos.actual_termination_date, id_hire_date )
--                                                         >= id_hire_date                    -- 退職日
      AND       ppos.actual_termination_date IS NULL
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
      ORDER BY  paa.ass_attribute11                      -- 職位並順コード（新)
               ,ppos.actual_termination_date  DESC       -- 退職日の降順
-- 2009/09/04 Ver1.11 add start by Yutaka.Kuboshima
               ,ppos.date_start
-- 2009/09/04 Ver1.11 add end by Yutaka.Kuboshima
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --
    -- カーソルオープン
    OPEN  get_supervisor_cur;
    -- フェッチ
    FETCH get_supervisor_cur INTO ln_supervisor_id;
    --
    IF ( get_supervisor_cur%NOTFOUND ) THEN
      -- 管理者が取得できない場合
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 管理者取得の時の入社年月日チェックを削除
--      IF ( id_hire_date >= gn_person_start) THEN
--        --プロファイルの設定された社員のperson_idを設定
--        on_supervisor_id := gn_person_id;
--      ELSE
--        on_supervisor_id := NULL;
--      END IF;
      on_supervisor_id := gn_person_id;
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
    ELSE
      -- 管理者が取得できた場合
      on_supervisor_id := ln_supervisor_id;
    END IF;
    --
    -- クローズ
    CLOSE get_supervisor_cur;
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
  END get_supervisor;
-- End Ver1.6
--
--
-- 2009/08/06 Ver1.10 障害0000510 add start by Yutaka.Kuboshima
  /***********************************************************************************
   * Procedure Name   : get_job
   * Description      : 役職を取得します。
   ***********************************************************************************/
  PROCEDURE get_job(
    in_person_id               IN  NUMBER         --  従業員ID
   ,iv_location_code           IN  VARCHAR2       --  所属コード(新)
   ,iv_job_post_order          IN  VARCHAR2       --  職位並順コード（新)
   ,id_hire_date               IN  DATE           --  入社日
   ,iv_purchasing_flag         IN  VARCHAR2       --  購買担当フラグ
   ,on_job_id                  OUT NUMBER         --  役職ID
   ,ov_errbuf                  OUT VARCHAR2       --  エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2       --  リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2 )     --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_job';   -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
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
    -- *** ローカル変数 ***
    ln_supervisor_id       per_all_people_f.person_id%TYPE;    -- 管理者(従業員)ID
    lv_job_name            per_jobs.name%TYPE;                 -- 役職名
    ln_job_id              per_jobs.job_id%TYPE;               -- 役職ID
    --
    -- 管理者割当カーソル
    CURSOR get_job_cur
    IS
      SELECT    paa.person_id             person_id      -- 従業員ID
      FROM      per_periods_of_service    ppos           -- 従業員サービス期間マスタ
               ,per_all_assignments_f     paa            -- アサインメントマスタ
      WHERE     paa.person_id                            != in_person_id                    -- 自身以外
      AND       paa.ass_attribute5                        = iv_location_code                -- 所属コード(新)
      AND       TO_NUMBER(NVL(paa.ass_attribute11,'99')) >  0                               -- 職位並順コード（新)
      AND       TO_NUMBER(NVL(paa.ass_attribute11,'99')) <= TO_NUMBER( iv_job_post_order )
      AND       paa.period_of_service_id                  = ppos.period_of_service_id       -- サービスID
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 管理者取得の時の入社年月日チェックを変更、ソート順を削除
--      AND       ppos.date_start                          <= id_hire_date                    -- 入社日
--      AND       NVL( ppos.actual_termination_date, id_hire_date )
--                                                         >= id_hire_date                    -- 退職日
--      ORDER BY  paa.ass_attribute11                      -- 職位並順コード（新)
--               ,ppos.actual_termination_date  DESC       -- 退職日の降順
      AND       ppos.actual_termination_date IS NULL
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
    ;
    --
    -- 役職ID取得カーソル
    CURSOR get_job_id_cur(p_job_name IN VARCHAR2)
    IS
      SELECT    pj.job_id
      FROM      per_jobs pj -- 役職マスタ
      WHERE     pj.name = p_job_name;
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
    -- 購買担当フラグが'1'(購買担当権限有)の場合
    IF (iv_purchasing_flag = cv_permission_on) THEN
      lv_job_name := gv_po_chrge;
    ELSE
      -- カーソルオープン
      OPEN  get_job_cur;
      -- フェッチ
      FETCH get_job_cur INTO ln_supervisor_id;
      --
      -- 管理者が取得できない場合
      IF ( get_job_cur%NOTFOUND ) THEN
        -- 拠点・部門管理者の役職をセットします
        lv_job_name := gv_base_manager;
      ELSE
        -- 拠点・部門担当者の役職をセットします
        lv_job_name := gv_base_chrge;
      END IF;
      -- クローズ
      CLOSE get_job_cur;
    END IF;
    --
    -- 役職IDを取得します
    OPEN get_job_id_cur(lv_job_name);
    FETCH get_job_id_cur INTO ln_job_id;
    CLOSE get_job_id_cur;
    -- OUTパラメータにセットします
    on_job_id := ln_job_id;
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
  END get_job;
-- 2009/08/06 Ver1.10 障害0000510 add end by Yutaka.Kuboshima
--
-- 2009/08/06 Ver1.10 障害0000510,0000910 add start by Yutaka.Kuboshima
  /***********************************************************************************
   * Procedure Name   : get_location
   * Description      : 事業所を取得します。
   ***********************************************************************************/
  PROCEDURE get_location(
    iv_office_location_code    IN  VARCHAR2       --  勤務地拠点コード(新)
   ,ov_purchasing_flag         OUT VARCHAR2       --  購買担当フラグ
   ,ov_shipping_flag           OUT VARCHAR2       --  出荷担当フラグ
   ,ov_errbuf                  OUT VARCHAR2       --  エラー・メッセージ           --# 固定 #
   ,ov_retcode                 OUT VARCHAR2       --  リターン・コード             --# 固定 #
   ,ov_errmsg                  OUT VARCHAR2 )     --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location';   -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
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
    -- *** ローカル変数 ***
    ln_supervisor_id       per_all_people_f.person_id%TYPE;    -- 管理者(従業員)ID
    --
    -- 事業所取得カーソル
    CURSOR get_location_cur
    IS
      SELECT hla.attribute3 purchasing_flag   -- 購買担当フラグ
            ,hla.attribute4 shipping_flag     -- 出荷担当フラグ
      FROM   hr_locations_all hla             -- 事業所マスタ
      WHERE  hla.location_code = iv_office_location_code;
    -- 事業所取得カーソルレコード型
    get_location_rec get_location_cur%ROWTYPE;
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
    -- カーソルオープン
    OPEN  get_location_cur;
    -- フェッチ
    FETCH get_location_cur INTO get_location_rec;
    --
    -- 事業所が取得できない場合
    IF ( get_location_cur%NOTFOUND ) THEN
      ov_purchasing_flag := NULL;
      ov_shipping_flag   := NULL;
    -- 事業所が取得できた場合
    ELSE
      ov_purchasing_flag := get_location_rec.purchasing_flag;
      ov_shipping_flag   := get_location_rec.shipping_flag;
    END IF;
    --
    -- クローズ
    CLOSE get_location_cur;
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
  END get_location;
--
-- 2009/08/06 Ver1.10 障害0000510,0000910 add end by Yutaka.Kuboshima
--
-- 2009/08/06 Ver1.10 障害0000910 add start by Yutaka.Kuboshima
  /***********************************************************************************
   * Procedure Name   : wsh_grants_proc
   * Description      : 出荷ロールマスタの登録・削除処理を行います。
   ***********************************************************************************/
  PROCEDURE wsh_grants_proc(
    ir_masters_rec   IN     masters_rec, -- 対象従業員情報
    iv_shipping_flag IN     VARCHAR2,    -- 出荷担当フラグ
    ov_errbuf        OUT    VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wsh_grants_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
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
    ln_grant_id  wsh_grants.grant_id%TYPE;
    ln_cnt       NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- 出荷ロールマスタ存在チェックカーソル
    CURSOR wsh_grants_exists_cur
    IS
      SELECT COUNT(1)
      FROM   per_all_people_f papf
            ,fnd_user         fu
            ,wsh_grants       wgs
      WHERE  papf.person_id = fu.employee_id
        AND  wgs.user_id    = fu.user_id
        AND  papf.person_id = ir_masters_rec.person_id
        AND  ROWNUM = 1;
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 出荷ロールマスタが登録されているか
    OPEN wsh_grants_exists_cur;
    FETCH wsh_grants_exists_cur INTO ln_cnt;
    CLOSE wsh_grants_exists_cur;
    -- 出荷担当フラグが'1'(出荷担当権限有)の場合かつ、出荷ロールマスタが未登録の場合
    IF (iv_shipping_flag = cv_permission_on) AND (ln_cnt = 0) THEN
      -- 登録処理
      INSERT INTO wsh_grants
      (grant_id,
       user_id,
       role_id,
       organization_id,
       start_date,
       end_date,
       created_by,
       creation_date,
       last_updated_by,
       last_update_date,
       last_update_login
      )
      VALUES (
       wsh_grants_s.NEXTVAL,                      --GRANT_ID
       ir_masters_rec.user_id,                    --USER_ID
       gn_role_id,                                --ROLE_ID
       NULL,                                      --ORGANIZATION_ID
-- 2010/02/25 Ver1.16 障害E_本稼動_01581 modify start by Shigeto.Niki
--       cd_process_date,                           --START_DATE(生産システムではSYSDATE,営業システムでは業務日付)
       TO_DATE(ir_masters_rec.announce_date,'YYYY/MM/DD'),  --発令日
-- 2010/02/25 Ver1.16 障害E_本稼動_01581 modify end by Shigeto.Niki
       NULL,                                      --END_DATE
       gn_created_by,
       gd_creation_date,
       gn_last_update_by,
       gd_last_update_date,
       gn_last_update_login
      );
--
    -- 出荷担当フラグが'0'(出荷担当権限無)の場合かつ、出荷ロールマスタが登録されている場合
    -- または、退職区分が'Y'の場合
    ELSIF ( (iv_shipping_flag = cv_permission_off) AND (ln_cnt = 1) )
      OR (ir_masters_rec.retire_kbn = gv_sts_yes)
    THEN
      -- 削除処理
      DELETE wsh_grants
      WHERE  user_id = ir_masters_rec.user_id;
    END IF;
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
  END wsh_grants_proc;
--
  /***********************************************************************************
   * Procedure Name   : po_agents_proc
   * Description      : 購買担当マスタの登録・削除処理を行います。
   ***********************************************************************************/
  PROCEDURE po_agents_proc(
    ir_masters_rec     IN     masters_rec, -- 対象従業員情報
    iv_purchasing_flag IN     VARCHAR2,    -- 購買担当フラグ
    ov_errbuf          OUT    VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT    VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT    VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'po_agents_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
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
    lv_rowid                      ROWID;
    lv_api_name                   VARCHAR2(200);
    ln_cnt                        NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- 購買担当マスタ存在チェックカーソル
    CURSOR po_agents_exists_cur
    IS
      SELECT COUNT(1)
      FROM   per_all_people_f papf
            ,po_agents        po
      WHERE  papf.person_id = po.agent_id
        AND  papf.person_id = ir_masters_rec.person_id
        AND  ROWNUM = 1;
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 購買担当マスタが登録されているか
    OPEN po_agents_exists_cur;
    FETCH po_agents_exists_cur INTO ln_cnt;
    CLOSE po_agents_exists_cur;
    -- 購買担当フラグが'1'(購買担当権限有)の場合かつ、購買担当マスタが未登録の場合
    IF (iv_purchasing_flag = cv_permission_on) AND (ln_cnt = 0) THEN
      BEGIN
        -- 登録処理
        PO_AGENTS_PKG.INSERT_ROW(
          X_ROWID               => lv_rowid
         ,X_AGENT_ID            => ir_masters_rec.person_id           -- 従業員ID
         ,X_LAST_UPDATE_DATE    => gd_last_update_date
         ,X_LAST_UPDATED_BY     => gn_last_update_by
         ,X_LAST_UPDATE_LOGIN   => gn_last_update_login
         ,X_CREATION_DATE       => gd_creation_date
         ,X_CREATED_BY          => gn_last_update_by
         ,X_LOCATION_ID         => NULL
         ,X_CATEGORY_ID         => NULL
         ,X_AUTHORIZATION_LIMIT => NULL
-- 2010/02/25 Ver1.16 障害E_本稼動_01581 modify start by Shigeto.Niki
--         ,X_START_DATE_ACTIVE   => NULL
         ,X_START_DATE_ACTIVE   => TO_DATE(ir_masters_rec.announce_date,'YYYY/MM/DD')  -- 発令日
-- 2010/02/25 Ver1.16 障害E_本稼動_01581 modify end by Shigeto.Niki
         ,X_END_DATE_ACTIVE     => NULL
         ,X_ATTRIBUTE_CATEGORY  => NULL
         ,X_ATTRIBUTE1          => NULL
         ,X_ATTRIBUTE2          => NULL
         ,X_ATTRIBUTE3          => NULL
         ,X_ATTRIBUTE4          => NULL
         ,X_ATTRIBUTE5          => NULL
         ,X_ATTRIBUTE6          => NULL
         ,X_ATTRIBUTE7          => NULL
         ,X_ATTRIBUTE8          => NULL
         ,X_ATTRIBUTE9          => NULL
         ,X_ATTRIBUTE10         => NULL
         ,X_ATTRIBUTE11         => NULL
         ,X_ATTRIBUTE12         => NULL
         ,X_ATTRIBUTE13         => NULL
         ,X_ATTRIBUTE14         => NULL
         ,X_ATTRIBUTE15         => NULL
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'PO_AGENTS_PKG.INSERT_ROW';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
      END;
--
    -- 購買担当フラグが'0'(購買担当権限無)の場合かつ、購買担当マスタが登録されている場合
    -- または、退職区分が'Y'の場合
    ELSIF ( (iv_purchasing_flag = cv_permission_off) AND (ln_cnt = 1) )
      OR (ir_masters_rec.retire_kbn = gv_sts_yes)
    THEN
      -- 削除処理
      DELETE po_agents
      WHERE  agent_id = ir_masters_rec.person_id;
    END IF;
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
  END po_agents_proc;
--
-- 2009/08/06 Ver1.10 障害0000910 add end by Yutaka.Kuboshima
--
-- Ver1.4 Add  2009/05/21  セキュリティ属性登録プロシージャを追加  T1_0966
  /***********************************************************************************
   * Procedure Name   : ins_user_sec
   * Description      : セキュリティ属性を登録します。
   ***********************************************************************************/
  PROCEDURE ins_user_sec(
    ir_masters_rec IN  masters_rec    --   対象データ
   ,ov_errbuf      OUT VARCHAR2       --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2       --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2 )     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_user_sec';   -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
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
    lv_api_name                VARCHAR2(200);     -- エラートークン用
    lv_sqlerrm                 VARCHAR2(5000);    -- SQLERRM退避
    --
    ln_exist_cnt               NUMBER;
    --
    -- OUTパラメータ（ICX_USER_SEC_ATTR_PUB.CREATE_USER_SEC_ATTR）
    lv_return_status           VARCHAR2(200);
    ln_msg_count               NUMBER;
    lv_msg_data                VARCHAR2(200);
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
    <<user_sec_loop>>
    FOR ln_cnt IN 1..2 LOOP
      -- 登録済みチェック
      SELECT    COUNT( ROWID )
      INTO      ln_exist_cnt
      FROM      ak_web_user_sec_attr_values
      WHERE     web_user_id              = ir_masters_rec.user_id
      AND       attribute_code           = g_sec_att_code_tab( ln_cnt )
      AND       attribute_application_id = gn_appl_id_icx
      AND       ROWNUM = 1;
      --
      -- 未登録の場合登録する（更新APIが無いため）
      IF ( ln_exist_cnt = 0 ) THEN
        -- セキュリティ属性登録API
        ICX_USER_SEC_ATTR_PUB.CREATE_USER_SEC_ATTR(
          p_api_version_number    => 1.0
         ,p_init_msg_list         => FND_API.G_TRUE
         ,p_return_status         => lv_return_status                -- OUT
         ,p_msg_count             => ln_msg_count                    -- OUT
         ,p_msg_data              => lv_msg_data                     -- OUT
         ,p_web_user_id           => ir_masters_rec.user_id          -- ユーザID
         ,p_attribute_code        => g_sec_att_code_tab( ln_cnt )    -- 属性名 【ICX_HR_PERSON_ID, TO_PERSON_ID】
         ,p_attribute_appl_id     => gn_appl_id_icx                  -- アプリケーションID 【ICX】
         ,p_varchar2_value        => NULL
         ,p_date_value            => NULL
         ,p_number_value          => ir_masters_rec.person_id        -- 従業員ID
         ,p_created_by            => cn_created_by
         ,p_creation_date         => cd_creation_date
         ,p_last_updated_by       => cn_last_updated_by
         ,p_last_update_date      => cd_last_update_date
         ,p_last_update_login     => cn_last_update_login
        );
        -- APIでエラー発生か判定
        IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
          lv_sqlerrm := lv_msg_data;
          lv_api_name := 'ICX_USER_SEC_ATTR_PUB.CREATE_USER_SEC_ATTR';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
          lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
          RAISE global_process_expt;
        END IF;
        --
      END IF;
      --
    END LOOP user_sec_loop;
    --
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_user_sec;
-- End Ver1.4
--
-- Ver1.3 Add  2009/04/16  ＣＣＩＤ取得プロシージャ作成
  /***********************************************************************************
   * Procedure Name   : get_ccid
   * Description      : CCID取得
   ***********************************************************************************/
  PROCEDURE get_ccid(
    iv_aff_segment2    IN  VARCHAR2,     --   AFF02部門(所属部門)
    on_ccid            OUT NUMBER,       --   CCID
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ccid'; -- プログラム名
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
    cv_short_name         VARCHAR2(5) := 'SQLGL';
    --
    -- *** ローカル変数 ***
    lb_ret                BOOLEAN;
    ln_ccid               gl_code_combinations.code_combination_id%TYPE;
    --
    -- *** テーブル変数 ***
    l_aff_segments_tab    fnd_flex_ext.segmentarray;
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------
    -- ＡＦＦ設定
    ----------------
    -- セグメント値配列設定(SEG1:会社)
    l_aff_segments_tab( 1 ) := g_aff_segments_tab( 1 );
    -- セグメント値配列設定(SEG2:部門)  所属部門
    l_aff_segments_tab( 2 ) := iv_aff_segment2;
    -- セグメント値配列設定(SEG3:勘定科目)
    l_aff_segments_tab( 3 ) := g_aff_segments_tab( 3 );
    -- セグメント値配列設定(SEG4:補助科目)
    l_aff_segments_tab( 4 ) := g_aff_segments_tab( 4 );
    -- セグメント値配列設定(SEG5:顧客コード)
    l_aff_segments_tab( 5 ) := g_aff_segments_tab( 5 );
    -- セグメント値配列設定(SEG6:企業コード)
    l_aff_segments_tab( 6 ) := g_aff_segments_tab( 6 );
    -- セグメント値配列設定(SEG7:予備1)
    l_aff_segments_tab( 7 ) := g_aff_segments_tab( 7 );
    -- セグメント値配列設定(SEG8:予備2)
    l_aff_segments_tab( 8 ) := g_aff_segments_tab( 8 );
    --
    --
    -- CCID取得関数呼び出し
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name  => cv_short_name          -- アプリケーション短縮名(GL)
                ,key_flex_code           => gv_id_flex_code        -- キーフレックスコード
                ,structure_number        => gn_chart_of_acct_id    -- 勘定科目体系番号
                ,validation_date         => SYSDATE                -- 日付チェック
                ,n_segments              => 8                      -- セグメント数
                ,segments                => l_aff_segments_tab     -- セグメント値配列
                ,combination_id          => ln_ccid                -- CCID
              );
    --
    IF lb_ret THEN
      on_ccid := ln_ccid;
    ELSE
      lv_errmsg := fnd_flex_ext.get_message;
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
  END get_ccid;
-- End Ver1.3
--
  /***********************************************************************************
   * Procedure Name   : init_get_profile
   * Description      : プロファイルより初期値を取得します。
   ***********************************************************************************/
  PROCEDURE init_get_profile(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
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
    lv_token_value1  VARCHAR2(40);
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
    -- 社員データ取込用CSVファイル保管場所の取得
    gv_directory := fnd_profile.value(cv_prf_dir);
    --
    -- プロファイルが取得できない場合はエラー
    IF (gv_directory IS NULL) THEN
      lv_token_value1 := cv_prf_dir_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- 社員データ取込用ファイル名取得
    gv_file_name := FND_PROFILE.VALUE(cv_prf_fil);
    --
    -- プロファイルが取得できない場合はエラー
    IF (gv_file_name IS NULL) THEN
      lv_token_value1 := cv_prf_fil_nm;
      RAISE global_process_expt;
    END IF;
     --
    -- 管理者従業員番号取得
    gv_supervisor := fnd_profile.value(cv_prf_supervisor);
    --
    -- プロファイルが取得できない場合はエラー
    IF (gv_supervisor IS NULL) THEN
      lv_token_value1 := cv_prf_supervisor_nm;
      RAISE global_process_expt;
    ELSE
      -- 取得管理者の従業員番号を取得
      BEGIN
        SELECT paa.person_id,
               ppos.date_start
        INTO   gn_person_id,
               gn_person_start
        FROM   per_all_assignments_f paa,                           -- アサインメントマスタ
               per_periods_of_service ppos,                         -- 従業員サービス期間マスタ
               per_all_people_f pap                                 -- 従業員マスタ
        WHERE  pap.employee_number = gv_supervisor                  -- 従業員番号
        AND    pap.person_id = paa.person_id                        -- 従業員ID
        AND    paa.period_of_service_id = ppos.period_of_service_id -- サービスID
        AND    pap.effective_start_date = ppos.date_start           -- 登録年月日
        AND    ppos.actual_termination_date IS NULL;                -- 退職日
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            lv_token_value1 := cv_prf_supervisor_nm2;
            RAISE global_process_expt;
        WHEN OTHERS THEN
            RAISE global_api_others_expt;
      END;
    END IF;
--
-- Ver1.3 Del  2009/04/16  各セグメント毎にプロファイル定義し不要のため
--    -- デフォルト費用勘定取得
--    gv_default := FND_PROFILE.VALUE(cv_prf_default);
----
--    -- プロファイルが取得できない場合はエラー
--    IF (gv_default IS NULL) THEN
--      lv_token_value1 := cv_prf_default_nm;
--      RAISE global_process_expt;
--    END IF;
-- End Ver1.3
--
-- Ver1.3 Add  2009/04/16  デフォルト費用勘定各ＡＦＦセグメント毎にプロファイル定義
    -----------------------------------------
    -- デフォルト費用勘定ＡＦＦ値取得
    -----------------------------------------
    -- セグメント値配列設定(SEG1:会社)
    g_aff_segments_tab( 1 ) := FND_PROFILE.VALUE( cv_prf_def_aff1 );
    -- プロファイルが取得できない場合はエラー
    IF ( g_aff_segments_tab( 1 ) IS NULL ) THEN
      lv_token_value1 := cv_prf_def_aff1_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- セグメント値配列設定(SEG3:勘定科目)
    g_aff_segments_tab( 3 ) := FND_PROFILE.VALUE( cv_prf_def_aff3 );
    -- プロファイルが取得できない場合はエラー
    IF ( g_aff_segments_tab( 3 ) IS NULL ) THEN
      lv_token_value1 := cv_prf_def_aff3_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- セグメント値配列設定(SEG4:補助科目)
    g_aff_segments_tab( 4 ) := FND_PROFILE.VALUE( cv_prf_def_aff4 );
    -- プロファイルが取得できない場合はエラー
    IF ( g_aff_segments_tab( 4 ) IS NULL ) THEN
      lv_token_value1 := cv_prf_def_aff4_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- セグメント値配列設定(SEG5:顧客コード)
    g_aff_segments_tab( 5 ) := FND_PROFILE.VALUE( cv_prf_def_aff5 );
    -- プロファイルが取得できない場合はエラー
    IF ( g_aff_segments_tab( 5 ) IS NULL ) THEN
      lv_token_value1 := cv_prf_def_aff5_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- セグメント値配列設定(SEG6:企業コード)
    g_aff_segments_tab( 6 ) := FND_PROFILE.VALUE( cv_prf_def_aff6 );
    -- プロファイルが取得できない場合はエラー
    IF ( g_aff_segments_tab( 6 ) IS NULL ) THEN
      lv_token_value1 := cv_prf_def_aff6_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- セグメント値配列設定(SEG7:予備1)
    g_aff_segments_tab( 7 ) := FND_PROFILE.VALUE( cv_prf_def_aff7 );
    -- プロファイルが取得できない場合はエラー
    IF ( g_aff_segments_tab( 7 ) IS NULL ) THEN
      lv_token_value1 := cv_prf_def_aff7_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- セグメント値配列設定(SEG8:予備2)
    g_aff_segments_tab( 8 ) := FND_PROFILE.VALUE( cv_prf_def_aff8 );
    -- プロファイルが取得できない場合はエラー
    IF ( g_aff_segments_tab( 8 ) IS NULL ) THEN
      lv_token_value1 := cv_prf_def_aff8_nm;
      RAISE global_process_expt;
    END IF;
    --
-- End Ver1.3
    --
    -- 初期パスワード取得
    gv_password := FND_PROFILE.VALUE(cv_prf_password);
    --
    -- プロファイルが取得できない場合はエラー
    IF (gv_password IS NULL) THEN
      lv_token_value1 := cv_prf_password_nm;
      RAISE global_process_expt;
    END IF;
    --
-- 2009/08/06 Ver1.10 障害0000510,0000910 add start by Yutaka.Kuboshima
    --
    -- 拠点・部門管理者_役職名取得
    gv_base_manager := FND_PROFILE.VALUE(cv_prf_base_manager);
    -- プロファイルが取得できない場合はエラー
    IF (gv_base_manager IS NULL) THEN
      lv_token_value1 := cv_prf_base_manager_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- 拠点・部門担当者_役職名取得
    gv_base_chrge := FND_PROFILE.VALUE(cv_prf_base_chrge);
    -- プロファイルが取得できない場合はエラー
    IF (gv_base_chrge IS NULL) THEN
      lv_token_value1 := cv_prf_base_chrge_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- PO_購買担当者_役職名取得
    gv_po_chrge := FND_PROFILE.VALUE(cv_prf_po_chrge);
    -- プロファイルが取得できない場合はエラー
    IF (gv_po_chrge IS NULL) THEN
      lv_token_value1 := cv_prf_po_chrge_nm;
      RAISE global_process_expt;
    END IF;
    --
    BEGIN
      -- 役割ID取得
      gn_role_id := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_role_id));
      -- プロファイルが取得できない場合はエラー
      IF (gn_role_id IS NULL) THEN
        lv_token_value1 := cv_prf_role_id_nm;
        RAISE global_process_expt;
      END IF;
    EXCEPTION
      -- 数値変換エラー
      WHEN OTHERS THEN
        lv_token_value1 := cv_prf_role_id_nm;
        RAISE global_process_expt;
    END;
    --
    -- 財務経理部_部門コード取得
    gv_zaimu_bumon_cd := FND_PROFILE.VALUE(cv_prf_zaimu_bumon_cd);
    -- プロファイルが取得できない場合はエラー
    IF (gv_zaimu_bumon_cd IS NULL) THEN
      lv_token_value1 := cv_prf_zaimu_bumon_cd_nm;
      RAISE global_process_expt;
    END IF;
    --
    -- AFFダミー部門コード取得
    gv_aff_dept_cd := FND_PROFILE.VALUE(cv_prf_aff_dept_cd);
    -- プロファイルが取得できない場合はエラー
    IF (gv_aff_dept_cd IS NULL) THEN
      lv_token_value1 := cv_prf_aff_dept_cd_nm;
      RAISE global_process_expt;
    END IF;
    --
-- 2009/08/06 Ver1.10 障害0000510,0000910 add end by Yutaka.Kuboshima
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                   --*** プロファイル取得エラー ***--
      -- *** 任意で例外処理を記述する ****
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_prf_get_err
                   ,iv_token_name1  => cv_tkn_ng_profile
                   ,iv_token_value1 => lv_token_value1
                  );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END init_get_profile;
--
  /***********************************************************************************
   * Procedure Name   : init_file_lock
   * Description      : ファイルロック処理を行います。
   ***********************************************************************************/
  PROCEDURE init_file_lock(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_file_lock'; -- プログラム名
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
    lv_token_value1  VARCHAR2(40);
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
-- Ver1.5 Add  2009/06/02  T1_1278
--    -- 社員インタフェース
--    BEGIN
--      OPEN gc_xip_cur;
--    --
--    EXCEPTION
--      WHEN lock_expt THEN
--        lv_token_value1 := cv_xxcmm1_in_if_nm;
--        RAISE global_process_expt;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
--    CLOSE gc_xip_cur;
--    --
--    -- 従業員マスタ
--    BEGIN
--      OPEN gc_ppf_cur;
--    --
--    EXCEPTION
--      WHEN lock_expt THEN
--        lv_token_value1 := cv_per_all_people_f_nm;
--        RAISE global_process_expt;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
--    CLOSE gc_ppf_cur;
--    --
--    -- アサインメントマスタ
--    BEGIN
--      OPEN gc_paf_cur;
--    --
--    EXCEPTION
--      WHEN lock_expt THEN
--        lv_token_value1 := cv_per_all_assignments_f_nm;
--        RAISE global_process_expt;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
--    CLOSE gc_paf_cur;
--    --
--    -- ユーザーマスタ
--    BEGIN
--      OPEN gc_fu_cur;
--    --
--    EXCEPTION
--      WHEN lock_expt THEN
--        lv_token_value1 := cv_fnd_user_nm;
--        RAISE global_process_expt;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
--    CLOSE gc_fu_cur;
--    --
-- Ver1.5 End
    -- ユーザー職責マスタ
    BEGIN
      OPEN gc_fug_cur;
    EXCEPTION
      WHEN lock_expt THEN
--Ver1.5 Add  2009/06/02
        --lv_token_value1 := cv_fnd_user_resp_group_a_nm;
        lv_token_value1 := cv_mst_tbl;
--End Ver1.5
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_fug_cur;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** ファイルロックエラー ***--
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_file_lock_err
                  ,iv_token_name1  => cv_tkn_ng_table
                  ,iv_token_value1 => lv_token_value1
                 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--Ver1.5 Add  2009/06/02  T1_1278
--      IF (gc_xip_cur%ISOPEN) THEN
--      -- カーソルのクローズ
--         CLOSE gc_xip_cur;
--      END IF;
--      --
--      -- 従業員マスタ
--      IF (gc_ppf_cur%ISOPEN) THEN
--      -- カーソルのクローズ
--         CLOSE gc_ppf_cur;
--      END IF;
--      --
--      -- アサインメントマスタ
--      IF (gc_ppf_cur%ISOPEN) THEN
--         -- カーソルのクローズ
--         CLOSE gc_ppf_cur;
--      END IF;
--      --
--      -- ユーザーマスタ
--      IF (gc_fu_cur%ISOPEN) THEN
--         -- カーソルのクローズ
--        CLOSE gc_fu_cur;
--      END IF;
--      --
-- Ver1.5 End
      -- ユーザー職責マスタ
      IF (gc_fug_cur%ISOPEN) THEN
      -- カーソルのクローズ
        CLOSE gc_fug_cur;
      END IF;
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
--Ver1.5 Add  2009/06/02  T1_1278
--      IF (gc_xip_cur%ISOPEN) THEN
--      -- カーソルのクローズ
--         CLOSE gc_xip_cur;
--      END IF;
--      --
--      -- 従業員マスタ
--      IF (gc_ppf_cur%ISOPEN) THEN
--      -- カーソルのクローズ
--         CLOSE gc_ppf_cur;
--      END IF;
--      --
--      -- アサインメントマスタ
--      IF (gc_ppf_cur%ISOPEN) THEN
--         -- カーソルのクローズ
--         CLOSE gc_ppf_cur;
--      END IF;
--      --
--      -- ユーザーマスタ
--      IF (gc_fu_cur%ISOPEN) THEN
--         -- カーソルのクローズ
--        CLOSE gc_fu_cur;
--      END IF;
--      --
-- Ver1.5 End
      -- ユーザー職責マスタ
      IF (gc_fug_cur%ISOPEN) THEN
      -- カーソルのクローズ
        CLOSE gc_fug_cur;
      END IF;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END init_file_lock;
--
  /***********************************************************************************
   * Procedure Name   : check_aff_bumon
   * Description      : AFF部門マスタチェック処理（業務日付時点・過去データ込み）
   ***********************************************************************************/
  PROCEDURE check_aff_bumon(
    iv_bumon       IN  VARCHAR2,     --   チェック対象データ
    iv_flg         IN  VARCHAR2,     --   業務日付時点でのAFF部門''、部門階層ビュー不使用'A'
    iv_token       IN  VARCHAR2,     --   エラー時のトークン
    iv_employee_nm IN  VARCHAR2,     --   社員番号
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_aff_bumon'; -- プログラム名
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
    lv_bumon    VARCHAR2(4);
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
    IF iv_flg IS NULL THEN
      BEGIN
      -- AFF部門（部門階層ビュー）
--Ver1.8 Mod  2009/07/06  0000412 START
--        SELECT xhd.cur_dpt_cd
--        INTO   lv_bumon
--        FROM   xxcmm_hierarchy_dept_v xhd
--        WHERE  xhd.cur_dpt_cd = iv_bumon   -- 最下層部門コードが同じ
--        AND    ROWNUM = 1;
        SELECT xwhd.cur_dpt_cd
        INTO   lv_bumon
        FROM   xxcmm_wk_hiera_dept xwhd
        WHERE  xwhd.cur_dpt_cd  = iv_bumon   -- 最下層部門コードが同じ
        AND    xwhd.process_kbn = '2'        -- 処理区分(1：全部門、2：部門)
        AND    ROWNUM = 1;
--Ver1.8 Mod  2009/07/06  0000412 END
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bumon := NULL; -- 該当データなし
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    ELSE
      BEGIN
      -- AFF部門（全部門階層ビュー）
--Ver1.8 Mod  2009/07/06  0000412 START
--        SELECT xhd.cur_dpt_cd
--        INTO   lv_bumon
--        FROM   xxcmm_hierarchy_dept_all_v xhd
--        WHERE  xhd.cur_dpt_cd = iv_bumon   -- 最下層部門コードが同じ
--        AND    ROWNUM = 1;
-- 2009/08/06 Ver1.10 障害0000869 modify start by Yutaka.Kuboshima
--        SELECT xwhd.cur_dpt_cd
--        INTO   lv_bumon
--        FROM   xxcmm_wk_hiera_dept xwhd
--        WHERE  xwhd.cur_dpt_cd  = iv_bumon   -- 最下層部門コードが同じ
--        AND    xwhd.process_kbn = '1'        -- 処理区分(1：全部門、2：部門)
--        AND    ROWNUM = 1;
        -- 部門階層ビューから直接AFF部門から検索するように修正
        SELECT ffv.flex_value
        INTO   lv_bumon
        FROM   fnd_flex_values ffv
              ,fnd_flex_value_sets ffvs
        WHERE  ffv.flex_value_set_id    = ffvs.flex_value_set_id
          AND  ffvs.flex_value_set_name = cv_flex_aff_bumon
          AND  ffv.flex_value           = iv_bumon
          AND  ffv.summary_flag         = cv_no
          AND  ROWNUM = 1;
-- 2009/08/06 Ver1.10 障害0000869 modify start by Yutaka.Kuboshima
--Ver1.8 Mod  2009/07/06  0000412 END
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bumon := NULL; -- 該当データなし
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
    --
    IF (lv_bumon IS NULL) THEN
      -- マスタ存在チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                    ,iv_name         => cv_no_data_err
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => iv_token
                    ,iv_token_name2  => cv_tkn_ng_code
                    ,iv_token_value2 => iv_bumon
                    ,iv_token_name3  => cv_tkn_ng_user
                    ,iv_token_value3 => iv_employee_nm
                    );
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
--####################################  固定部 END   ##########################################
--
  END check_aff_bumon;
--
  /***********************************************************************************
   * Procedure Name   : get_location_id
   * Description      : ロケーションID(事業所)の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_location_id(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location_id'; -- プログラム名
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
    cv_office_location  CONSTANT VARCHAR2(30) := '勤務地拠点コード(新)'; -- 項目名
    cv_locations_all_nm CONSTANT VARCHAR2(20) := '事業所マスタ';         -- ファイル名
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
    BEGIN
    -- 事業所マスタ
      SELECT hla.location_id
      INTO   ir_masters_rec.location_id  -- ロケーションID
      FROM   hr_locations_all hla        -- 事業所マスタ
      WHERE  hla.location_code  = ir_masters_rec.office_location_code; -- 勤務地拠点コード(新)
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- マスタ存在チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_no_data_err
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => cv_locations_all_nm
                    ,iv_token_name2  => cv_tkn_ng_code
-- 2009/08/06 Ver1.10 modify start by Yutaka.Kuboshima
--                    ,iv_token_value2 => cv_office_location||ir_masters_rec.location_code
                    ,iv_token_value2 => cv_office_location||ir_masters_rec.office_location_code
-- 2009/08/06 Ver1.10 modify start by Yutaka.Kuboshima
                    ,iv_token_name3  => cv_tkn_ng_user
                    ,iv_token_value3 => ir_masters_rec.employee_number
                   );
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
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
  END get_location_id;
--
  /***********************************************************************************
   * Procedure Name   : in_if_check_emp
   * Description      : データ連携対象チェック
   ***********************************************************************************/
  PROCEDURE in_if_check_emp(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'in_if_check_emp'; -- プログラム名
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
    --
    -- *** ローカル・カーソル ***
    --
    -- 従業員マスタ/アサインメントマスタ/従業員サービス期間マスタ(※check_recと同じ並びにする）
    CURSOR gc_per_cur(lv_emp IN VARCHAR2)
    IS
      SELECT pap.person_id                   person_id,                   -- 従業員ID
             pap.effective_start_date        effective_start_date,        -- 登録年月日
             pap.last_name                   last_name,                   -- カナ姓
             pap.employee_number             employee_number,             -- 従業員番号
             pap.first_name                  first_name,                  -- カナ名
             pap.sex                         sex,                         -- 性別
             pap.attribute3                  employee_division,           -- 従業員区分
             pap.attribute7                  license_code,                -- 資格コード（新）
             pap.attribute8                  license_name,                -- 資格名（新）
             pap.attribute11                 job_post,                    -- 職位コード（新）
             pap.attribute12                 job_post_name,               -- 職位名（新）
             pap.attribute15                 job_duty,                    -- 職務コード（新）
             pap.attribute16                 job_duty_name,               -- 職務名（新）
             pap.attribute19                 job_type,                    -- 職種コード（新）
             pap.attribute20                 job_type_name,               -- 職種名（新）
             pap.attribute9                  license_code_old,            -- 資格コード（旧）
             pap.attribute10                 license_code_name_old,       -- 資格名（旧）
             pap.attribute13                 job_post_old,                -- 職位コード（旧）
             pap.attribute14                 job_post_name_old,           -- 職位名（旧）
             pap.attribute17                 job_duty_old,                -- 職務コード（旧）
             pap.attribute18                 job_duty_name_old,           -- 務名（旧）
             pap.attribute21                 job_type_old,                -- 職種コード（旧）
             pap.attribute22                 job_type_name_old,           -- 職種名（旧）
             pap.attribute28                 pap_location_code,           -- 起票部門
             pap.per_information18           last_name_kanji,             -- 漢字姓
             pap.per_information19           first_name_kanji,            -- 漢字名
             pap.object_version_number       pap_version,                 -- バージョン番号
             paa.assignment_id               assignment_id,               -- アサインメントID
             paa.assignment_number           assignment_number,           -- アサインメント番号
             paa.effective_start_date        paa_effective_start_date,    -- 登録年月日
             paa.effective_end_date          paa_effective_end_date,      -- 登録期限年月日
             paa.location_id                 location_id,                 -- 事業所
             paa.supervisor_id               supervisor_id,               -- 管理者
             paa.ass_attribute1              change_code,                 -- 異動事由コード
             paa.ass_attribute2              announce_date,               -- 発令日
             paa.ass_attribute3              office_location_code,        -- 勤務地拠点コード（新）
             paa.ass_attribute4              office_location_code_old,    -- 勤務地拠点コード（旧）
             paa.ass_attribute5              location_code,               -- 拠点コード（新）
             paa.ass_attribute6              location_code_old,           -- 拠点コード（旧）
             paa.ass_attribute7              job_system,                  -- 適用労働時間制コード（新）
             paa.ass_attribute8              job_system_name,             -- 適用労働名（新）
             paa.ass_attribute9              job_system_old,              -- 適用労働時間制コード（旧）
             paa.ass_attribute10             job_system_name_old,         -- 適用労働名（旧）
             paa.ass_attribute11             job_post_order,              -- 職位並順コード（新）
             paa.ass_attribute12             job_post_order_old,          -- 職位並順コード（旧）
             paa.ass_attribute13             consent_division,            -- 承認区分（新）
             paa.ass_attribute14             consent_division_old,        -- 承認区分（旧）
             paa.ass_attribute15             agent_division,              -- 代行区分（新）
             paa.ass_attribute16             agent_division_old,          -- 代行区分（旧）
             paa.object_version_number       paa_version,                 -- バージョン番号(アサインメント)
-- Ver1.3 Add  2009/04/16  デフォルト費用勘定を追加
             paa.default_code_comb_id        default_code_comb_id,        -- デフォルト費用勘定
-- End Ver1.3
             ppos.period_of_service_id       period_of_service_id,        -- サービスID
             ppos.actual_termination_date    actual_termination_date,     -- 退職年月日
             ppos.object_version_number      ppos_version                 -- バージョン番号(サービス期間マスタ)
      FROM   per_periods_of_service          ppos,                        -- 従業員サービス期間マスタ
             per_all_assignments_f           paa,                         -- アサインメントマスタ
             per_all_people_f                pap                          -- 従業員マスタ
      WHERE  pap.employee_number = lv_emp
      AND    pap.current_emp_or_apl_flag = gv_const_y             -- 履歴フラグ
      AND    pap.person_id = paa.person_id                        -- 従業員ID
      AND    paa.period_of_service_id = ppos.period_of_service_id -- サービスID
      AND    pap.effective_start_date = ppos.date_start           -- 登録年月日(入社日)
      ORDER BY pap.person_id,pap.effective_start_date desc ,pap.effective_end_date
    ;
    --
    -- *** ローカル・レコード ***
    gc_per_rec gc_per_cur%ROWTYPE;
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
    -- 新規社員登録処理
    lr_check_rec.employee_number := NULL;     -- 社員コード
    <<per_loop>>
    FOR gc_per_rec IN gc_per_cur(ir_masters_rec.employee_number) LOOP
      lr_check_rec := gc_per_rec;
      EXIT;
    END LOOP per_loop;
    --
    IF lr_check_rec.employee_number IS NULL THEN
      ir_masters_rec.emp_kbn         := gv_kbn_new;    -- 新規社員
      ir_masters_rec.proc_kbn        := gv_sts_yes;    -- 連携データ
      ir_masters_rec.ymd_kbn         := NULL;          -- 日付変更なし
      ir_masters_rec.resp_kbn        := gv_sts_yes;    -- 職責・管理者 変更
      ir_masters_rec.location_id_kbn := gv_sts_yes;    -- 事業所 変更
--
-- 2009/12/11 Ver1.13 E_本番_00148 modify start by Y.Kuboshima
-- レコード全てを初期化するように修正
--      lr_check_rec.license_code      := NULL;          -- 資格コード（新）
--      lr_check_rec.job_post          := NULL;          -- 職位コード（新）
--      lr_check_rec.job_duty          := NULL;          -- 職務コード（新）
--      lr_check_rec.job_type          := NULL;          -- 職種コード（新）
--      lr_check_rec.job_system        := NULL;          -- 適用労働時間制コード（新）
--      lr_check_rec.job_post_order    := NULL;          -- 職位並順コード（新）
--      lr_check_rec.consent_division  := NULL;          -- 承認区分（新）
--      lr_check_rec.agent_division    := NULL;          -- 代行区分（新）
      lr_check_rec := NULL;
-- 2009/12/11 Ver1.13 E_本番_00148 modify end by Y.Kuboshima
--
      IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
        ir_masters_rec.retire_kbn    := gv_sts_yes;    -- 退職データ
      END IF;
      --事業所マスタチェック(ロケーションIDの取得)
      get_location_id(
          ir_masters_rec
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_others_expt;
      END IF;
    END IF;
    --
    IF (ir_masters_rec.emp_kbn IS NULL) THEN
      -- 連携前の退職日がNULLの場合
      IF (lr_check_rec.actual_termination_date IS NULL) THEN
        ir_masters_rec.emp_kbn  := gv_kbn_employee;  -- 既存社員
        IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
          ir_masters_rec.retire_kbn  := gv_sts_yes;  -- 退職データ
        END IF;
      ELSE
        ir_masters_rec.emp_kbn  := gv_kbn_retiree;  -- 退職者
        ir_masters_rec.retire_kbn  := NULL;         -- 退職処理なし
      END IF;
      --
      -- 入社年月日・退職年月日以外のデータ差異判断
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
-- 資格名(新・旧)、職位名(新・旧)、職種名(新・旧)、職務名(新・旧)、適用労働名(新・旧)の項目を除く
--      IF (lr_check_rec.employee_number||lr_check_rec.last_name_kanji||lr_check_rec.first_name_kanji
--        ||lr_check_rec.last_name||lr_check_rec.first_name||lr_check_rec.sex||lr_check_rec.employee_division
--        ||lr_check_rec.location_code||lr_check_rec.change_code
--        ||lr_check_rec.announce_date||lr_check_rec.office_location_code||lr_check_rec.license_code||lr_check_rec.license_name
--        ||lr_check_rec.job_post||lr_check_rec.job_post_name||lr_check_rec.job_duty||lr_check_rec.job_duty_name
--        ||lr_check_rec.job_type||lr_check_rec.job_type_name||lr_check_rec.job_system||lr_check_rec.job_system_name
--        ||lr_check_rec.job_post_order||lr_check_rec.consent_division||lr_check_rec.agent_division
--        ||lr_check_rec.office_location_code_old||lr_check_rec.location_code_old||lr_check_rec.license_code_old||lr_check_rec.license_code_name_old
--        ||lr_check_rec.job_post_old||lr_check_rec.job_post_name_old||lr_check_rec.job_duty_old||lr_check_rec.job_duty_name_old
--        ||lr_check_rec.job_type_old||lr_check_rec.job_type_name_old||lr_check_rec.job_system_old||lr_check_rec.job_system_name_old
--        ||lr_check_rec.job_post_order_old||lr_check_rec.consent_division_old||lr_check_rec.agent_division_old)
--          =
--         (ir_masters_rec.employee_number||ir_masters_rec.last_name_kanji||ir_masters_rec.first_name_kanji
--        ||ir_masters_rec.last_name||ir_masters_rec.first_name||ir_masters_rec.sex||ir_masters_rec.employee_division
--        ||ir_masters_rec.location_code||ir_masters_rec.change_code
--        ||ir_masters_rec.announce_date||ir_masters_rec.office_location_code||ir_masters_rec.license_code||ir_masters_rec.license_name
--        ||ir_masters_rec.job_post||ir_masters_rec.job_post_name||ir_masters_rec.job_duty||ir_masters_rec.job_duty_name
--        ||ir_masters_rec.job_type||ir_masters_rec.job_type_name||ir_masters_rec.job_system||ir_masters_rec.job_system_name
--        ||ir_masters_rec.job_post_order||ir_masters_rec.consent_division||ir_masters_rec.agent_division
--        ||ir_masters_rec.office_location_code_old||ir_masters_rec.location_code_old||ir_masters_rec.license_code_old||ir_masters_rec.license_code_name_old
--        ||ir_masters_rec.job_post_old||ir_masters_rec.job_post_name_old||ir_masters_rec.job_duty_old||ir_masters_rec.job_duty_name_old
--        ||ir_masters_rec.job_type_old||ir_masters_rec.job_type_name_old||ir_masters_rec.job_system_old||ir_masters_rec.job_system_name_old
--        ||ir_masters_rec.job_post_order_old||ir_masters_rec.consent_division_old||ir_masters_rec.agent_division_old) THEN
      IF (lr_check_rec.employee_number||lr_check_rec.last_name_kanji||lr_check_rec.first_name_kanji
        ||lr_check_rec.last_name||lr_check_rec.first_name||lr_check_rec.sex||lr_check_rec.employee_division
        ||lr_check_rec.location_code||lr_check_rec.change_code
        ||lr_check_rec.announce_date||lr_check_rec.office_location_code||lr_check_rec.license_code
        ||lr_check_rec.job_post||lr_check_rec.job_duty
        ||lr_check_rec.job_type||lr_check_rec.job_system
        ||lr_check_rec.job_post_order||lr_check_rec.consent_division||lr_check_rec.agent_division
        ||lr_check_rec.office_location_code_old||lr_check_rec.location_code_old||lr_check_rec.license_code_old
        ||lr_check_rec.job_post_old||lr_check_rec.job_duty_old
        ||lr_check_rec.job_type_old||lr_check_rec.job_system_old
        ||lr_check_rec.job_post_order_old||lr_check_rec.consent_division_old||lr_check_rec.agent_division_old)
          =
         (ir_masters_rec.employee_number||ir_masters_rec.last_name_kanji||ir_masters_rec.first_name_kanji
        ||ir_masters_rec.last_name||ir_masters_rec.first_name||ir_masters_rec.sex||ir_masters_rec.employee_division
        ||ir_masters_rec.location_code||ir_masters_rec.change_code
        ||ir_masters_rec.announce_date||ir_masters_rec.office_location_code||ir_masters_rec.license_code
        ||ir_masters_rec.job_post||ir_masters_rec.job_duty
        ||ir_masters_rec.job_type||ir_masters_rec.job_system
        ||ir_masters_rec.job_post_order||ir_masters_rec.consent_division||ir_masters_rec.agent_division
        ||ir_masters_rec.office_location_code_old||ir_masters_rec.location_code_old||ir_masters_rec.license_code_old
        ||ir_masters_rec.job_post_old||ir_masters_rec.job_duty_old
        ||ir_masters_rec.job_type_old||ir_masters_rec.job_system_old
        ||ir_masters_rec.job_post_order_old||ir_masters_rec.consent_division_old||ir_masters_rec.agent_division_old) THEN
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify end by Y.Kuboshima
        --
        ir_masters_rec.proc_kbn := NULL;  -- 連携なし（差異なし）
        ir_masters_rec.resp_kbn := NULL;  -- 職責・管理者変更なし
        ir_masters_rec.location_id_kbn := NULL;  -- 事業所 変更なし
      ELSE
        ir_masters_rec.proc_kbn := gv_sts_yes;  -- 連携データ（差異あり）
        -- 所属コード（拠点コード）の変更判断
-- 2009/09/04 Ver1.11 modify start by Yutaka.Kuboshima
--        IF (lr_check_rec.location_code <> ir_masters_rec.location_code) THEN
        IF (NVL(lr_check_rec.location_code, ' ') <> NVL(ir_masters_rec.location_code, ' ')) THEN
-- 2009/09/04 Ver1.11 modify end by Yutaka.Kuboshima
          ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
-- 2009/12/11 Ver1.13 E_本稼動_00103 add start by Y.Kuboshima
          ir_masters_rec.supervisor_kbn := gv_sts_yes;  -- 管理者変更あり
-- 2009/12/11 Ver1.13 E_本稼動_00103 add end by Y.Kuboshima
        END IF;
        -- 勤務地拠点コード(新)の変更判断
-- 2009/09/04 Ver1.11 modify start by Yutaka.Kuboshima
--        IF (lr_check_rec.office_location_code <> ir_masters_rec.office_location_code) THEN
        IF (NVL(lr_check_rec.office_location_code, ' ') <> NVL(ir_masters_rec.office_location_code, ' ')) THEN
-- 2009/09/04 Ver1.11 modify end by Yutaka.Kuboshima
          ir_masters_rec.location_id_kbn := gv_sts_yes;  -- 事業所 変更
        END IF;
      END IF;
      --
      --事業所マスタチェック(ロケーションIDの取得) (再雇用処理で使用する為、事業所は取得しておく)
      get_location_id(
        ir_masters_rec
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_others_expt;
      END IF;
      --
      -- 入社年月日差異判断
      IF (lr_check_rec.effective_start_date = ir_masters_rec.hire_date) THEN
        ir_masters_rec.ymd_kbn  := NULL;  -- 入社日変更なし
      ELSE
        ir_masters_rec.ymd_kbn  := gv_sts_yes;  -- 入社日変更
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
-- 警告エラーメッセージを表示
-- 処理ステータスは警告にする(当該レコードは連携対象とする)
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_hire_ymd_change_err
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => cv_employee_nm
                    ,iv_token_name2  => cv_tkn_ng_user
                    ,iv_token_value2 => ir_masters_rec.employee_number
                   );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ir_masters_rec.row_err_message := lv_errmsg;
        gv_retcode := cv_status_warn;
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
      END IF;
      --
      -- データ登録に必要なデータ格納
      -- 従業員マスタ
      ir_masters_rec.person_id            := lr_check_rec.person_id;                 -- 従業員ID
      ir_masters_rec.pap_version          := lr_check_rec.pap_version;               -- バージョン番号
      ir_masters_rec.hire_date_old        := lr_check_rec.effective_start_date;      -- 既存_入社年月日
      -- アサインメントマスタ
      ir_masters_rec.assignment_id        := lr_check_rec.assignment_id;             -- アサインメントID
      ir_masters_rec.assignment_number    := lr_check_rec.assignment_number;         -- アサインメント番号
-- Ver1.6 Del  2009/06/23  T1_1389対応  管理者取得場所を更新の直前に変更のため削除
--      ir_masters_rec.supervisor_id        := lr_check_rec.supervisor_id;             -- 管理者
-- End1.6
-- 2009/12/11 Ver1.13 E_本稼動_00103 add start by Y.Kuboshima
-- 変更前の管理者情報を取得しておく
      ir_masters_rec.supervisor_id        := lr_check_rec.supervisor_id;             -- 管理者
-- 2009/12/11 Ver1.13 E_本稼動_00103 add end by Y.Kuboshima
      ir_masters_rec.effective_start_date := lr_check_rec.paa_effective_start_date;  -- 登録年月日
      ir_masters_rec.effective_end_date   := lr_check_rec.paa_effective_end_date;    -- 登録期限年月日
      ir_masters_rec.paa_version          := lr_check_rec.paa_version;               -- バージョン番号
-- Ver1.3 Add  2009/04/16  デフォルト費用勘定を追加
      ir_masters_rec.default_code_comb_id := lr_check_rec.default_code_comb_id;      -- デフォルト費用勘定
-- End Ver1.3
      -- サービス期間マスタ
      ir_masters_rec.period_of_service_id := lr_check_rec.period_of_service_id;      -- サービスID
      ir_masters_rec.ppos_version         := lr_check_rec.ppos_version;              -- バージョン番号
      --
    END IF;
    --
-- Ver1.3 Add 2009/04/16  デフォルト費用勘定取得処理を追加
    -- 新規社員、所属コード変更時取得する
    --   所属未変更時は、デフォルト費用勘定に変更がないため必要ないはず。
    IF ( ir_masters_rec.resp_kbn = gv_sts_yes ) THEN
      -- デフォルト費用勘定CCIDの取得
      get_ccid(
        iv_aff_segment2  =>  ir_masters_rec.location_code             --   AFF02部門(所属コード)
       ,on_ccid          =>  ir_masters_rec.default_code_comb_id      --   CCID
       ,ov_errbuf        =>  lv_errbuf                                --   エラー・メッセージ           --# 固定 #
       ,ov_retcode       =>  lv_retcode                               --   リターン・コード             --# 固定 #
       ,ov_errmsg        =>  lv_errmsg                                --   ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
-- End Ver1.3
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
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
  END in_if_check_emp;
--
  /**********************************************************************************
   * Procedure Name   : in_if_check
   * Description      : データ妥当性チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE in_if_check(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf      OUT VARCHAR2,        --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,        --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'in_if_check'; -- プログラム名
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
    cv_ymd_err_nm         CONSTANT VARCHAR2(20) := '入社年月日未設定';    -- 項目名
    cv_hire_date_nm       CONSTANT VARCHAR2(20) := '入社年月日';          -- 項目名
    cv_retire_date_nm     CONSTANT VARCHAR2(20) := '退職年月日';          -- 項目名
    cv_last_name_err_nm   CONSTANT VARCHAR2(20) := 'カナ姓未設定';        -- 項目名
    cv_last_name_nm       CONSTANT VARCHAR2(10) := 'カナ姓';              -- 項目名
    cv_first_name_nm      CONSTANT VARCHAR2(10) := 'カナ名';              -- 項目名
    cv_last_kanji_nm      CONSTANT VARCHAR2(10) := '漢字姓';              -- 項目名
    cv_first_kanji_nm     CONSTANT VARCHAR2(10) := '漢字名';              -- 項目名
    cv_announce_date_nm   CONSTANT VARCHAR2(20) := '発令日';              -- 項目名
    cv_announce_date_nm1  CONSTANT VARCHAR2(20) := '発令日未設定';        -- 項目名
    cv_announce_date_nm2  CONSTANT VARCHAR2(20) := '発令日未来日付';      -- 項目名
-- 2009/08/06 Ver1.10 障害0000793 add start by Yutaka.Kuboshima
    cv_announce_date_nm3  CONSTANT VARCHAR2(20) := '発令日日付エラー';    -- 項目名
-- 2009/08/06 Ver1.10 障害0000793 add end by Yutaka.Kuboshima
    cv_sex_nm             CONSTANT VARCHAR2(10) := '性別';                -- 項目名
    cv_division_nm        CONSTANT VARCHAR2(20) := '社員・外部委託区分';  -- 項目名
    cv_location_cd        CONSTANT VARCHAR2(20) := '所属コード';          -- 項目名
    cv_office_location    CONSTANT VARCHAR2(20) := '勤務地拠点コード';    -- 項目名
    cv_new                CONSTANT VARCHAR2(10) := '(新)';                -- 項目名
    cv_old                CONSTANT VARCHAR2(10) := '(旧)';                -- 項目名
    --
    cv_all                CONSTANT VARCHAR2(1)  := 'A';
    --
    -- *** ローカル変数 ***
    lv_token_value2       VARCHAR2(30);
-- 2009/08/06 Ver1.10 障害0000793 add start by Yutaka.Kuboshima
    ld_announce_date      DATE;
-- 2009/08/06 Ver1.10 障害0000793 add end by Yutaka.Kuboshima
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
    --入社年月日
    IF (ir_masters_rec.hire_date IS NULL) THEN
       lv_token_value2 := cv_ymd_err_nm; -- '入社年月日未設定'
       RAISE global_process_expt;
    ELSIF (ir_masters_rec.hire_date) > cd_sysdate THEN -- 入社年月日とシステム日付の比較
       lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_st_ymd_err3
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => cv_employee_nm -- '社員番号'
                    ,iv_token_name2  => cv_tkn_ng_user
                    ,iv_token_value2 => ir_masters_rec.employee_number
                    );
       RAISE global_process2_expt;
    ELSIF (LENGTHB(TO_CHAR(ir_masters_rec.hire_date,'YYYYMMDD')) <> 8) THEN -- 日付妥当性チェック
       lv_token_value2 := cv_hire_date_nm; -- '入社年月日'
       RAISE global_process_expt;
    END IF;
    --
    --退職年月日
    IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
      IF (LENGTHB(TO_CHAR(ir_masters_rec.actual_termination_date,'YYYYMMDD')) <> 8) THEN -- 日付妥当性チェック
        lv_token_value2 := cv_retire_date_nm; -- '退職年月日'
        RAISE global_process_expt;
      ELSIF (ir_masters_rec.hire_date > ir_masters_rec.actual_termination_date) THEN -- 入社年月日と退職年月日の比較
        lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                     ,iv_name         => cv_st_ymd_err2
                     ,iv_token_name1  => cv_tkn_ng_word
                     ,iv_token_value1 => cv_employee_nm -- '社員番号'
                     ,iv_token_name2  => cv_tkn_ng_user
                     ,iv_token_value2 => ir_masters_rec.employee_number
                     );
        RAISE global_process2_expt;
      END IF;
    END IF;
    --
    --カナ姓・カナ名
    IF (ir_masters_rec.last_name IS NULL) then
      lv_token_value2 := cv_last_name_err_nm;  -- 'カナ姓未設定';
      RAISE global_process_expt;
    ELSIF (NOT xxccp_common_pkg.chk_single_byte_kana(ir_masters_rec.last_name)) THEN -- 半角カタカナチェック
      lv_token_value2 := cv_last_name_nm;  -- 'カナ姓';
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_single_byte_kana(ir_masters_rec.first_name) = FALSE) THEN -- 半角カタカナチェック（NULL正常）
      lv_token_value2 := cv_first_name_nm; -- 'カナ名'
      RAISE global_process_expt;
    END IF;
    --
    --漢字姓・漢字名
    IF (xxccp_common_pkg.chk_double_byte(ir_masters_rec.last_name_kanji) = FALSE) THEN
      lv_token_value2 := cv_last_kanji_nm; -- '漢字姓'
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_double_byte(ir_masters_rec.first_name_kanji) = FALSE) THEN
      lv_token_value2 := cv_first_kanji_nm; -- '漢字名'
      RAISE global_process_expt;
    END IF;
    --
    --発令日
-- 2009/08/06 Ver1.10 障害0000793 add start by Yutaka.Kuboshima
    BEGIN
      IF (ir_masters_rec.announce_date IS NOT NULL) THEN
        -- 日付妥当性チェック
        ld_announce_date := TO_DATE(ir_masters_rec.announce_date,'YYYYMMDD');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_token_value2 := cv_announce_date_nm3;
        RAISE global_process_expt;
    END;
-- 2009/08/06 Ver1.10 障害0000793 add end by Yutaka.Kuboshima
    IF (ir_masters_rec.announce_date IS NULL) THEN
      lv_token_value2 := cv_announce_date_nm1; -- '発令日未設定'
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_number(ir_masters_rec.announce_date) = FALSE) THEN -- 半角数字チェック（NULL正常）
      lv_token_value2 := cv_announce_date_nm; -- '発令日'
      RAISE global_process_expt;
    ELSIF (LENGTHB(ir_masters_rec.announce_date) <> 8) THEN -- 日付妥当性チェック
      lv_token_value2 := cv_announce_date_nm; -- '発令日'
      RAISE global_process_expt;
-- 2009/08/06 Ver1.10 障害0000793 modify start by Yutaka.Kuboshima
--    ELSIF (ir_masters_rec.announce_date > cc_process_date) THEN
    ELSIF (ir_masters_rec.announce_date > TO_CHAR(cd_process_date + 1,'YYYYMMDD')) THEN
-- 2009/08/06 Ver1.10 障害0000793 modify end by Y.Kuboshima
      lv_token_value2 := cv_announce_date_nm2; -- '発令日未来日付'
      RAISE global_process_expt;
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
    -- 入社日 > 発令日の場合
    ELSIF (ir_masters_rec.hire_date > ld_announce_date) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_announce_ymd_err
                   ,iv_token_name1  => cv_tkn_ng_word
                   ,iv_token_value1 => cv_employee_nm -- '社員番号'
                   ,iv_token_name2  => cv_tkn_ng_user
                   ,iv_token_value2 => ir_masters_rec.employee_number
                   );
      RAISE global_process2_expt;
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
    END IF;
    --
    --性別
    IF (ir_masters_rec.sex NOT IN ('M','F')) THEN
      lv_token_value2 := cv_sex_nm; -- '性別'
      RAISE global_process_expt;
    END IF;
    --
    --社員・外部委託区分
    IF (ir_masters_rec.employee_division NOT IN ('1','2')) THEN
      lv_token_value2 := cv_division_nm; -- '社員・外部委託区分'
      RAISE global_process_expt;
    END IF;
    --
    --所属コード(新)
    IF (ir_masters_rec.location_code IS NULL) THEN
      lv_token_value2 := cv_location_cd||cv_new; -- '所属コード(新)'
      RAISE global_process_expt;
    ELSE
      check_aff_bumon(      --AFF部門コード存在チェック
        ir_masters_rec.location_code
        ,NULL                 -- 業務日付時点での使用部門
        ,cv_location_cd||cv_new  -- エラー用トークン:'所属コード(新)'
-- Ver1.5 Add  2009/06/02  社員番号
        ,ir_masters_rec.employee_number
-- End Ver1.5
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;
    --
    --勤務地拠点コード(新)
    IF (ir_masters_rec.office_location_code IS NULL) THEN
      lv_token_value2 := cv_office_location||cv_new; -- '勤務地拠点コード(新)'
      RAISE global_process_expt;
    ELSE
      check_aff_bumon(            --AFF部門コード存在チェック
        ir_masters_rec.office_location_code
        ,NULL                         -- 業務日付時点での使用部門
        ,cv_office_location||cv_new   -- エラー用トークン:'勤務地拠点コード(新)'
-- Ver1.5 Add  2009/06/02  社員番号
        ,ir_masters_rec.employee_number
-- End Ver1.5
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;
    --
    --所属コード(旧)
    IF (ir_masters_rec.location_code_old IS NOT NULL) THEN
      check_aff_bumon(    --AFF部門コード存在チェック
         ir_masters_rec.location_code_old
        ,cv_all               -- 全部門でのチェック
        ,cv_location_cd||cv_old  -- エラー用トークン:'所属コード(旧)'
-- Ver1.5 Add  2009/06/02  社員番号
        ,ir_masters_rec.employee_number
-- End Ver1.5
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;
    --
    --勤務地拠点コード(旧)
    IF (ir_masters_rec.office_location_code_old IS NOT NULL) THEN
      check_aff_bumon(            --AFF部門コード存在チェック
         ir_masters_rec.office_location_code_old
        ,cv_all                       -- 全部門でのチェック
        ,cv_office_location||cv_old   -- エラー用トークン:'勤務地拠点コード(旧)'
-- Ver1.5 Add  2009/06/02  社員番号
        ,ir_masters_rec.employee_number
-- End Ver1.5
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;
    --
    -- データ連携対象チェック
    in_if_check_emp(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_warn) THEN
      RAISE global_process2_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** 警告1(更新不可データ) ***--
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_data_check_err
                   ,iv_token_name1  => cv_tkn_ng_user
                   ,iv_token_value1 => ir_masters_rec.employee_number
                   ,iv_token_name2  => cv_tkn_ng_err
                   ,iv_token_value2 => lv_token_value2
                   );
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
    WHEN global_process2_expt THEN                          --*** 警告2(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
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
--#####################################  固定部 END   ##########################################
--
  END in_if_check;
--
  /***********************************************************************************
   * Procedure Name   : check_fnd_user
   * Description      : ユーザーIDを取得し存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE check_fnd_user(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_fnd_user'; -- プログラム名
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
    BEGIN
      -- ユーザーマスタ
      SELECT fu.user_id
      INTO   ir_masters_rec.user_id
      FROM   fnd_user fu,          -- ユーザーマスタ
             per_all_people_f pap  -- 従業員マスタ
      WHERE  pap.employee_number = ir_masters_rec.employee_number
      AND    pap.person_id       = fu.employee_id
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.user_id := NULL; -- 該当データなし
      --
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END check_fnd_user;
--
  /***********************************************************************************
   * Procedure Name   : check_fnd_lookup
   * Description      : 参照コードマスタ 情報取得処理
   ***********************************************************************************/
  PROCEDURE check_fnd_lookup(
    iv_type        IN  VARCHAR2,     -- 1.タイプ
    iv_code        IN  VARCHAR2,     -- 2.参照コード
    iv_token       IN  VARCHAR2,     -- 3.エラー時のトークン
    iv_employee_nm IN  VARCHAR2,     --   社員番号
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_fnd_lookup'; -- プログラム名
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
    lv_flg  VARCHAR2(1) := NULL;
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
    BEGIN
      -- 参照コードテーブル
      SELECT '1'
      INTO   lv_flg
      FROM   fnd_lookup_values_vl flv  -- 参照コードテーブル
      WHERE  flv.lookup_type = iv_type
      AND    flv.lookup_code = iv_code
      AND    flv.enabled_flag = gv_const_y
      AND    NVL(flv.start_date_active,cd_process_date) <= cd_process_date
      AND    NVL(flv.end_date_active,cd_process_date) >= cd_process_date
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN       -- 該当データなし
        NULL;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    IF (lv_flg IS NULL) THEN
      -- マスタ存在チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_no_data_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => iv_token
                  ,iv_token_name2  => cv_tkn_ng_code
                  ,iv_token_value2 => iv_code
                  ,iv_token_name3  => cv_tkn_ng_user
                  ,iv_token_value3 => iv_employee_nm
                 );
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
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
  END check_fnd_lookup;
--
  /***********************************************************************************
   * Procedure Name   : check_code
   * Description      : コード存在チェック処理
   ***********************************************************************************/
  PROCEDURE check_code(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_code'; -- プログラム名
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
    lv_license_nm         CONSTANT VARCHAR2(30) := '資格コード(新)';  -- 資格名
    lv_job_post_nm        CONSTANT VARCHAR2(30) := '職位コード(新)';  -- 職位コード
    lv_job_duty_nm        CONSTANT VARCHAR2(30) := '職務コード(新)';  -- 職務コード
    lv_job_type_nm        CONSTANT VARCHAR2(30) := '職種コード(新)';  -- 職種コード
    lv_job_system_nm      CONSTANT VARCHAR2(30) := '適用労働時間制コード(新)';  -- 適用労働時間制コード
    lv_post_order_nm      CONSTANT VARCHAR2(30) := '職位並順コード(新)';  -- 職位並順コード
    lv_consent_nm         CONSTANT VARCHAR2(30) := '承認区分(新)';  -- 承認区分
    lv_agent_nm           CONSTANT VARCHAR2(30) := '代行区分(新)';  -- 代行区分
--Ver1.5 2009/06/02 Add start
    lv_license_nm_old     CONSTANT VARCHAR2(30) := '資格コード(旧)';  -- 資格名
    lv_job_post_nm_old    CONSTANT VARCHAR2(30) := '職位コード(旧)';  -- 職位コード
    lv_job_duty_nm_old    CONSTANT VARCHAR2(30) := '職務コード(旧)';  -- 職務コード
    lv_job_type_nm_old    CONSTANT VARCHAR2(30) := '職種コード(旧)';  -- 職種コード
    lv_post_order_nm_old  CONSTANT VARCHAR2(30) := '職位並順コード(旧)';  -- 職位並順コード
--Ver1.5 End
    --
    -- *** ローカル変数 ***
--Ver1.5 2009/06/02 Add start
    lv_job_post_order     VARCHAR2(2);
--Ver1.5 End
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
    -- 資格コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.license_code IS NOT NULL))
      OR (NVL(ir_masters_rec.license_code,' ') <> NVL(lr_check_rec.license_code,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_license
        ,ir_masters_rec.license_code
        ,lv_license_nm
-- Ver1.5 Add  2009/06/02  社員番号
        ,ir_masters_rec.employee_number
-- End Ver1.5
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 職位コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_post IS NOT NULL))
      OR (NVL(ir_masters_rec.job_post,' ') <> NVL(lr_check_rec.job_post,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_post
        ,ir_masters_rec.job_post
        ,lv_job_post_nm
-- Ver1.5 Add  2009/06/02  社員番号
        ,ir_masters_rec.employee_number
-- End Ver1.5
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 職務コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_duty IS NOT NULL))
      OR (NVL(ir_masters_rec.job_duty,' ') <> NVL(lr_check_rec.job_duty,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_duty
        ,ir_masters_rec.job_duty
        ,lv_job_duty_nm
-- Ver1.5 Add  2009/06/02  社員番号
        ,ir_masters_rec.employee_number
-- End Ver1.5
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 職種コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_type IS NOT NULL))
      OR (NVL(ir_masters_rec.job_type,' ') <> NVL(lr_check_rec.job_type,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_type
        ,ir_masters_rec.job_type
        ,lv_job_type_nm
-- Ver1.5 Add  2009/06/02  社員番号
        ,ir_masters_rec.employee_number
-- End Ver1.5
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 職位並順コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_post_order IS NOT NULL))
      OR (NVL(ir_masters_rec.job_post_order,' ') <> NVL(lr_check_rec.job_post_order,' '))) THEN
      -- 数値(0～99)以外はエラー
--Ver1.5 2009/06/02
      --IF (ir_masters_rec.job_post_order >= ' 0')
      --  AND (ir_masters_rec.job_post_order <= '99') THEN
      lv_job_post_order := ir_masters_rec.job_post_order;
      IF ( xxccp_common_pkg.chk_number( lv_job_post_order ) <> TRUE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_data_check_err
                    ,iv_token_name1  => cv_tkn_ng_user
                    ,iv_token_value1 => ir_masters_rec.employee_number
                    ,iv_token_name2  => cv_tkn_ng_err
-- 2010/01/29 Ver1.15 E_本稼動_01216 modify start by Shigeto.Niki
--                    ,iv_token_value2 => lv_post_order_nm_old
                    ,iv_token_value2 => lv_post_order_nm
-- 2010/01/29 Ver1.15 E_本稼動_01216 modify end by Shigeto.Niki
                   );
        RAISE global_process_expt;
      END IF;
      IF ( TO_NUMBER( lv_job_post_order ) >= 0 )
        AND ( TO_NUMBER( lv_job_post_order ) <= 99 ) THEN
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
--        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
          NULL;
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify end by Y.Kuboshima
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_data_check_err
                    ,iv_token_name1  => cv_tkn_ng_user
                    ,iv_token_value1 => ir_masters_rec.employee_number
                    ,iv_token_name2  => cv_tkn_ng_err
-- 2010/01/29 Ver1.15 E_本稼動_01216 modify start by Shigeto.Niki
--                    ,iv_token_value2 => lv_post_order_nm_old
                    ,iv_token_value2 => lv_post_order_nm
-- 2010/01/29 Ver1.15 E_本稼動_01216 modify end by Shigeto.Niki
                   );
        RAISE global_process_expt;
      END IF;
--Ver1.5 End
    END IF;
    --
--↓Ver1.5 2009/06/02 Add start
    -- 資格コード(旧)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.license_code_old IS NOT NULL))
      OR (NVL(ir_masters_rec.license_code_old,' ') <> NVL(lr_check_rec.license_code_old,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_license
        ,ir_masters_rec.license_code_old
        ,lv_license_nm_old
        ,ir_masters_rec.employee_number
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
-- Ver1.6  2009/06/23  旧は関係ないため修正
--      IF (lv_retcode = cv_status_normal) THEN
--        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
--      ELSIF (lv_retcode = cv_status_warn) THEN
-- End1.6
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 職位コード(旧)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_post_old IS NOT NULL))
      OR (NVL(ir_masters_rec.job_post_old,' ') <> NVL(lr_check_rec.job_post_old,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_post
        ,ir_masters_rec.job_post_old
        ,lv_job_post_nm_old
        ,ir_masters_rec.employee_number
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
-- Ver1.6  2009/06/23  旧は関係ないため修正
--      IF (lv_retcode = cv_status_normal) THEN
--        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
--      ELSIF (lv_retcode = cv_status_warn) THEN
-- End1.6
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 職務コード(旧)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_duty_old IS NOT NULL))
      OR (NVL(ir_masters_rec.job_duty_old,' ') <> NVL(lr_check_rec.job_duty_old,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_duty
        ,ir_masters_rec.job_duty_old
        ,lv_job_duty_nm_old
        ,ir_masters_rec.employee_number
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
-- Ver1.6  2009/06/23  旧は関係ないため修正
--      IF (lv_retcode = cv_status_normal) THEN
--        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
--      ELSIF (lv_retcode = cv_status_warn) THEN
-- End1.6
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 職種コード(旧)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_type_old IS NOT NULL))
      OR (NVL(ir_masters_rec.job_type_old,' ') <> NVL(lr_check_rec.job_type_old,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_type
        ,ir_masters_rec.job_type_old
        ,lv_job_type_nm_old
        ,ir_masters_rec.employee_number
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
-- Ver1.6  2009/06/23  旧は関係ないため修正
--      IF (lv_retcode = cv_status_normal) THEN
--        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
--      ELSIF (lv_retcode = cv_status_warn) THEN
-- End1.6
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 職位並順コード(旧)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_post_order_old IS NOT NULL))
      OR (NVL(ir_masters_rec.job_post_order_old,' ') <> NVL(lr_check_rec.job_post_order_old,' '))) THEN
      -- 数値(0～99)以外はエラー
      lv_job_post_order := ir_masters_rec.job_post_order_old;
      IF ( xxccp_common_pkg.chk_number( lv_job_post_order ) <> TRUE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_data_check_err
                    ,iv_token_name1  => cv_tkn_ng_user
                    ,iv_token_value1 => ir_masters_rec.employee_number
                    ,iv_token_name2  => cv_tkn_ng_err
                    ,iv_token_value2 => lv_post_order_nm_old
                   );
        RAISE global_process_expt;
      END IF;
-- Ver1.6  2009/06/23  旧は関係ないため修正
--      IF ( TO_NUMBER( lv_job_post_order ) >= 0 )
--        AND ( TO_NUMBER( lv_job_post_order ) <= 99 ) THEN
--        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
--      ELSE
-- End1.6
      IF ( TO_NUMBER( lv_job_post_order ) < 0 ) THEN
-- 2009/12/11 Ver1.13 E_本稼動_00103 delete start by Y.Kuboshima
--        ir_masters_rec.resp_kbn := gv_sts_yes;  -- 職責・管理者変更あり
-- 2009/12/11 Ver1.13 E_本稼動_00103 delete end by Y.Kuboshima
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_data_check_err
                    ,iv_token_name1  => cv_tkn_ng_user
                    ,iv_token_value1 => ir_masters_rec.employee_number
                    ,iv_token_name2  => cv_tkn_ng_err
                    ,iv_token_value2 => lv_post_order_nm_old
                   );
        RAISE global_process_expt;
      END IF;
    END IF;
--↑ Ver1.5 End
    --
--
--★★★参照コードマスタに設定する項目になった場合、ここから↓↓↓↓↓↓↓↓★★★
/*
    -- 適用労働時間制コード(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_system IS NOT NULL))
      OR (NVL(ir_masters_rec.job_system,' ') <> NVL(lr_check_rec.job_system,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_system
        ,ir_masters_rec.job_system
        ,lv_job_system_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 承認区分(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.consent_division IS NOT NULL))
      OR (NVL(ir_masters_rec.consent_division,' ') <> NVL(lr_check_rec.consent_division,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_agent
        ,ir_masters_rec.consent_division
        ,lv_consent_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 代行区分(新)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.agent_division IS NOT NULL))
      OR (NVL(ir_masters_rec.agent_division,' ') <> NVL(lr_check_rec.agent_division,' '))) THEN
      -- 参照コードマスタ 情報取得処理
      check_fnd_lookup(
         cv_flv_job_type
        ,ir_masters_rec.agent_division
        ,lv_agent_nm
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--★★★↑↑↑↑↑↑↑↑↑↑↑↑↑ここまで削除↑↑↑↑↑↑↑★★★
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
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
  END check_code;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_responsibility(A-7)
   * Description      : 職責・管理者情報の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_fnd_responsibility(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_responsibility'; -- プログラム名
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
    cv_level1  CONSTANT VARCHAR2(2):= 'L1';  -- レベル１
    cv_level2  CONSTANT VARCHAR2(2):= 'L2';  -- レベル２
    cv_level3  CONSTANT VARCHAR2(2):= 'L3';  -- レベル３
    cv_level4  CONSTANT VARCHAR2(2):= 'L4';  -- レベル４
    cv_level5  CONSTANT VARCHAR2(2):= 'L5';  -- レベル５
    cv_level6  CONSTANT VARCHAR2(2):= 'L6';  -- レベル６
    cv_all     CONSTANT VARCHAR2(1):= '-';   -- 全コート対象
    --
    -- *** ローカル変数 ***
    lv_location_cd  VARCHAR2(60);  -- 最下層部門コード
    lv_location_cd1 VARCHAR2(60);  -- １階層目部門コード
    lv_location_cd2 VARCHAR2(60);  -- ２階層目部門コード
    lv_location_cd3 VARCHAR2(60);  -- ３階層目部門コード
    lv_location_cd4 VARCHAR2(60);  -- ４階層目部門コード
    lv_location_cd5 VARCHAR2(60);  -- ５階層目部門コード
    lv_location_cd6 VARCHAR2(60);  -- ６階層目部門コード
    ln_resp_cnt     NUMBER := 0;
    ln_person_cnt   NUMBER := 0;
    ln_post_order   NUMBER := NULL;
    ln_application_id           fnd_responsibility.application_id%TYPE;     -- アプリケーションID
    lv_responsibility_key       fnd_responsibility.responsibility_key%TYPE; -- 職責キー
    lv_application_short_name   fnd_application.application_short_name%TYPE;-- アプリケーション名
    ld_st_date      DATE;
    --
    -- *** ローカル・カーソル ***
    -- 職責自動割当カーソル
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- カーソル変数追加
--    CURSOR resp_cur
    CURSOR resp_cur(iv_location_code1 IN VARCHAR2
                   ,iv_location_code2 IN VARCHAR2
                   ,iv_location_code3 IN VARCHAR2
                   ,iv_location_code4 IN VARCHAR2
                   ,iv_location_code5 IN VARCHAR2
                   ,iv_location_code6 IN VARCHAR2)
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
    IS
-- Ver1.9 Mod  2009/07/10  LOOKUPの設定を職責ID⇒職責KEYに変更  障害No.0000492
--      SELECT flv.description        responsibility_id,  -- 職責ID
      SELECT flv.description        responsibility_key,  -- 職責NEY
-- End1.9
             flv.attribute1         location_level,     -- 階層レベル
             flv.attribute2         location            -- 拠点コード
      FROM   fnd_lookup_values_vl flv   -- 参照コードマスタ
      WHERE  flv.lookup_type = cv_flv_responsibility  -- 職責自動割当テーブル
      AND    flv.enabled_flag = gv_const_y
-- Ver1.7 Mod  2009/06/25  基準日を業務日付+1に変更  障害No.0000161
--      AND    NVL(flv.start_date_active,ld_st_date) <= ld_st_date
--      AND    NVL(flv.end_date_active,ld_st_date) >= ld_st_date
      AND    NVL( flv.start_date_active, cd_process_date + 1 ) <= cd_process_date + 1
      AND    NVL( flv.end_date_active,   cd_process_date + 1 ) >= cd_process_date + 1
-- End1.7
      AND   ((NVL(flv.attribute3,cv_all) = cv_all) OR
             (NVL(flv.attribute3,cv_all) = ir_masters_rec.license_code)) -- 資格コード
      AND   ((NVL(flv.attribute4,cv_all) = cv_all) OR
             (NVL(flv.attribute4,cv_all) = ir_masters_rec.job_post))     -- 職位コード
      AND   ((NVL(flv.attribute5,cv_all) = cv_all) OR
             (NVL(flv.attribute5,cv_all) = ir_masters_rec.job_duty))     -- 職務コード
      AND   ((NVL(flv.attribute6,cv_all) = cv_all)  OR
             (NVL(flv.attribute6,cv_all) = ir_masters_rec.job_type))     -- 職種コード
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
      AND   ((flv.attribute1 = cv_level1 AND flv.attribute2 = iv_location_code1)
        OR   (flv.attribute1 = cv_level2 AND flv.attribute2 = iv_location_code2)
        OR   (flv.attribute1 = cv_level3 AND flv.attribute2 = iv_location_code3)
        OR   (flv.attribute1 = cv_level4 AND flv.attribute2 = iv_location_code4)
        OR   (flv.attribute1 = cv_level5 AND flv.attribute2 = iv_location_code5)
        OR   (flv.attribute1 = cv_level6 AND flv.attribute2 = iv_location_code6))
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
      ORDER BY flv.attribute1,flv.attribute2;
    --
-- Ver1.9 Add  2009/07/10  職責取得カーソルを追加  障害No.0000492
    CURSOR effective_resp_cur(
      pv_responsibility_key  VARCHAR2 )
    IS
      SELECT fres.responsibility_id,
             fres.responsibility_key,
             fres.application_id,
             fapp.application_short_name
      FROM   fnd_application    fapp,
             fnd_responsibility fres       -- 職責マスタ
      WHERE  fres.responsibility_key = pv_responsibility_key
      AND    fres.start_date  <= cd_process_date + 1
      AND    NVL( fres.end_date, cd_process_date + 1 ) >= cd_process_date + 1
      AND    fapp.application_id = fres.application_id;
-- End1.9
      --
-- Ver1.6 Del  2009/06/23  T1_1389対応  管理者取得場所を更新の直前に変更のため削除
--    -- 管理者割当カーソル
--    CURSOR person_cur
--    IS
--      SELECT paa.person_id                  person_id,
--             TO_NUMBER(paa.ass_attribute11) post_order
--      FROM   per_periods_of_service ppos,               -- 従業員サービス期間マスタ
--             per_all_assignments_f paa                  -- アサインメントマスタ
--      WHERE  paa.ass_attribute3 = ir_masters_rec.office_location_code   -- 勤務地拠点コード(新)
--      AND    TO_NUMBER(NVL(paa.ass_attribute11,'99')) > 0               -- 職位並順コード（新)
--      AND    TO_NUMBER(NVL(paa.ass_attribute11,'99')) <= TO_NUMBER(ir_masters_rec.job_post_order)
--      AND    paa.period_of_service_id = ppos.period_of_service_id       -- サービスID
--      AND    ppos.date_start <= ir_masters_rec.hire_date -- 入社日
--      AND    NVL(ppos.actual_termination_date ,ir_masters_rec.hire_date) >= ir_masters_rec.hire_date -- 退職日
--      ORDER BY post_order;
-- End1.6
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
-- 職責の取得
-- 職責の取得時に使用する日付
    --新規社員・再雇用時は入社日にて職責検索／既存社員で
    IF (ir_masters_rec.ymd_kbn  = gv_sts_yes)       -- 入社日変更
    OR (ir_masters_rec.emp_kbn  = gv_kbn_new) THEN  -- 新規社員
      ld_st_date := ir_masters_rec.hire_date;
    ELSIF (ir_masters_rec.actual_termination_date IS NULL)
       OR (TO_DATE(ir_masters_rec.announce_date,'YYYYMMDD') < ir_masters_rec.actual_termination_date) THEN
      ld_st_date := TO_DATE(ir_masters_rec.announce_date,'YYYYMMDD');
    ELSE
      ld_st_date := ir_masters_rec.actual_termination_date;
    END IF;
    --
    BEGIN
    -- AFF部門（部門階層ビュー）
--Ver1.8 Mod  2009/07/06  0000412 START
--      SELECT xhd.cur_dpt_cd,        -- 最下層部門コード
--             xhd.dpt1_cd,           -- １階層目部門コード
--             xhd.dpt2_cd,           -- ２階層目部門コード
--             xhd.dpt3_cd,           -- ３階層目部門コード
--             xhd.dpt4_cd,           -- ４階層目部門コード
--             xhd.dpt5_cd,           -- ５階層目部門コード
--             xhd.dpt6_cd            -- ６階層目部門コード
--      INTO   lv_location_cd,
--             lv_location_cd1,
--             lv_location_cd2,
--             lv_location_cd3,
--             lv_location_cd4,
--             lv_location_cd5,
--             lv_location_cd6
--      FROM   xxcmm_hierarchy_dept_v xhd
--      WHERE  xhd.cur_dpt_cd = ir_masters_rec.location_code   -- 最下層部門コードが同じ
--      AND    ROWNUM = 1;
      SELECT xwhd.cur_dpt_cd,        -- 最下層部門コード
             xwhd.dpt1_cd,           -- １階層目部門コード
             xwhd.dpt2_cd,           -- ２階層目部門コード
             xwhd.dpt3_cd,           -- ３階層目部門コード
             xwhd.dpt4_cd,           -- ４階層目部門コード
             xwhd.dpt5_cd,           -- ５階層目部門コード
             xwhd.dpt6_cd            -- ６階層目部門コード
      INTO   lv_location_cd,
             lv_location_cd1,
             lv_location_cd2,
             lv_location_cd3,
             lv_location_cd4,
             lv_location_cd5,
             lv_location_cd6
      FROM   xxcmm_wk_hiera_dept xwhd
      WHERE  xwhd.cur_dpt_cd  = ir_masters_rec.location_code  -- 最下層部門コードが同じ
      AND    xwhd.process_kbn = '2'                           -- 処理区分(1：全部門、2：部門)
      AND    ROWNUM = 1;
--Ver1.8 Mod  2009/07/06  0000412 END
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 職責自動割当カーソルOPEN処理変更
-- IF文を削除(SQLにIF文条件を移植)
--    <<resp_loop>>
--    FOR resp_rec IN resp_cur LOOP
--      IF   (resp_rec.location_level = cv_level1 AND resp_rec.location = lv_location_cd1)
--        OR (resp_rec.location_level = cv_level2 AND resp_rec.location = lv_location_cd2)
--        OR (resp_rec.location_level = cv_level3 AND resp_rec.location = lv_location_cd3)
--        OR (resp_rec.location_level = cv_level4 AND resp_rec.location = lv_location_cd4)
--        OR (resp_rec.location_level = cv_level5 AND resp_rec.location = lv_location_cd5)
--        OR (resp_rec.location_level = cv_level6 AND resp_rec.location = lv_location_cd6) THEN
--        --
---- Ver1.9 Mod  2009/07/10  LOOKUPの設定を職責ID⇒職責KEYに変更  障害No.0000492
----        BEGIN
----          -- 職責マスタ存在チェック
----          SELECT fres.application_id,
----                 fres.responsibility_key,
----                 fapp.application_short_name
----          INTO   ln_application_id,
----                 lv_responsibility_key,
----                 lv_application_short_name
----          FROM   fnd_application    fapp,
----                 fnd_responsibility fres       -- 職責マスタ
----        WHERE  fres.responsibility_id  = TO_NUMBER(resp_rec.responsibility_id)
------ Ver1.7 Mod  2009/06/25  基準日を業務日付+1に変更  障害No.0000161
------          AND    NVL(fres.start_date,ld_st_date)  <= ld_st_date
------          AND    NVL(fres.end_date,ld_st_date)  >= ld_st_date
----          AND    fres.start_date  <= cd_process_date + 1
----          AND    NVL( fres.end_date, cd_process_date + 1 ) >= cd_process_date + 1
------ End1.7
----          AND    fapp.application_id = fres.application_id
----          AND    ROWNUM = 1;
----        --
----        EXCEPTION
----          WHEN NO_DATA_FOUND THEN
----            ln_application_id := NULL;
----            lv_responsibility_key := NULL;
----            lv_application_short_name := NULL;
----          WHEN OTHERS THEN
----            RAISE global_api_others_expt;
----        END;
----        --
----        IF ln_application_id IS NOT NULL THEN
----          BEGIN
----            -- 職責自動割当ワークへ待避
----            INSERT INTO xxcmm_wk_people_resp(
----                employee_number,
----                responsibility_id,
----                user_id,
----                employee_kbn,
----                responsibility_key,
----                application_id,
----                application_short_name,
----                start_date,
----                end_date
----            )VALUES(
----                ir_masters_rec.employee_number,
----                TO_NUMBER(resp_rec.responsibility_id),
----                ir_masters_rec.user_id,
----                ir_masters_rec.emp_kbn,
----                lv_responsibility_key,
----                ln_application_id,
----                lv_application_short_name,
----                ld_st_date,
----                ir_masters_rec.actual_termination_date
----            );
----        ln_resp_cnt := ln_resp_cnt + 1;
----          EXCEPTION
----            WHEN DUP_VAL_ON_INDEX THEN  -- 同じ社員番号に同じ職責が存在した場合は、skipする
----              ln_application_id := NULL;
----              lv_responsibility_key := NULL;
----              lv_application_short_name := NULL;
----            WHEN OTHERS THEN
----              RAISE global_api_others_expt;
----          END;
----        END IF;
--        --
--        <<effective_resp_loop>>
--        FOR l_effective_resp_rec IN effective_resp_cur( resp_rec.responsibility_key ) LOOP
--          BEGIN
--            -- 職責自動割当ワークへ待避
--            INSERT INTO xxcmm_wk_people_resp(
--                employee_number,
--                responsibility_id,
--                user_id,
--                employee_kbn,
--                responsibility_key,
--                application_id,
--                application_short_name,
--                start_date,
--                end_date
--            )VALUES(
--                ir_masters_rec.employee_number,
--                l_effective_resp_rec.responsibility_id,
--                ir_masters_rec.user_id,
--                ir_masters_rec.emp_kbn,
--                l_effective_resp_rec.responsibility_key,
--                l_effective_resp_rec.application_id,
--                l_effective_resp_rec.application_short_name,
--                ld_st_date,
--                ir_masters_rec.actual_termination_date
--            );
--            ln_resp_cnt := ln_resp_cnt + 1;
--          EXCEPTION
--            -- 同じ社員番号に同じ職責が存在した場合は、skipする
--            WHEN DUP_VAL_ON_INDEX THEN
--              NULL;
--            WHEN OTHERS THEN
--              RAISE global_api_others_expt;
--          END;
--        END LOOP effective_resp_loop;
--        --
----End1.9
--      END IF;
--    END LOOP resp_loop;
--
-- ↓ modify start
    <<resp_loop>>
    FOR resp_rec IN resp_cur(lv_location_cd1
                            ,lv_location_cd2
                            ,lv_location_cd3
                            ,lv_location_cd4
                            ,lv_location_cd5
                            ,lv_location_cd6)
    LOOP
      <<effective_resp_loop>>
      FOR l_effective_resp_rec IN effective_resp_cur( resp_rec.responsibility_key ) LOOP
        BEGIN
          -- 職責自動割当ワークへ待避
          INSERT INTO xxcmm_wk_people_resp(
              employee_number,
              responsibility_id,
              user_id,
              employee_kbn,
              responsibility_key,
              application_id,
              application_short_name,
              start_date,
              end_date
          )VALUES(
              ir_masters_rec.employee_number,
              l_effective_resp_rec.responsibility_id,
              ir_masters_rec.user_id,
              ir_masters_rec.emp_kbn,
              l_effective_resp_rec.responsibility_key,
              l_effective_resp_rec.application_id,
              l_effective_resp_rec.application_short_name,
              ld_st_date,
              ir_masters_rec.actual_termination_date
          );
          ln_resp_cnt := ln_resp_cnt + 1;
        EXCEPTION
          -- 同じ社員番号に同じ職責が存在した場合は、skipする
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END LOOP effective_resp_loop;
      --
    END LOOP resp_loop;
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
    --
    IF (ln_resp_cnt = 0) THEN
/*  --職責が割当られなかった時の警告エラーはなし（コメントにしておく）
        -- 自動職責割当て不可メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_out_resp_msg
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                 );
      ir_status_rec.row_err_message   := iv_message;
      ir_status_rec.row_level_status  := cv_status_normal;  --処理継続
*/
      ir_masters_rec.resp_kbn := gv_sts_no;  -- 職責自動連携不可
    END IF;
    --
-- Ver1.6 Del  2009/06/23  T1_1389対応  管理者取得場所を更新の直前に変更のため削除
--    -- 管理者情報の取得
--    IF (ir_masters_rec.hire_date >= gn_person_start) THEN
--      ir_masters_rec.supervisor_id := gn_person_id; --プロファイルの設定された社員のperson_idを初期設定
--    END IF;
--    <<person_loop>>
--    FOR person_rec IN person_cur  LOOP
--      ln_person_cnt := ln_person_cnt + 1;
--      -- 管理者に並順が1番の社員を設定
--      IF (ln_person_cnt = 1) THEN
--        -- 並順1番のperson_idが本人以外の場合、person_idを設定
--        IF (person_rec.person_id <> ir_masters_rec.person_id)
--          OR (ir_masters_rec.person_id IS NULL ) THEN         -- 新規社員
--          ir_masters_rec.supervisor_id := person_rec.person_id;
--          EXIT person_loop;
--        END IF;
--      ELSE  --2件目でEXITする
--        -- 並順1番が複数いる場合、本人以外を設定
--        IF (person_rec.post_order = ln_post_order)
--          AND (person_rec.person_id <> ir_masters_rec.person_id) THEN
--            ir_masters_rec.supervisor_id := person_rec.person_id;
--        END IF;
--        EXIT person_loop;
--      END IF;
--      ln_post_order := person_rec.post_order;
--      --
--    END LOOP person_loop;
--    --
--    -- 管理者が本人だった場合はNULLを設定
--    IF (ir_masters_rec.supervisor_id = ir_masters_rec.person_id) THEN
--      ir_masters_rec.supervisor_id := NULL;
--    END IF;
-- End1.6
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
  END get_fnd_responsibility;
--
  /***********************************************************************************
   * Procedure Name   : check_insert
   * Description      : 社員データ登録分チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE check_insert(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_insert'; -- プログラム名
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
    -- ユーザマスタ存在チェック
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- ユーザ取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    -- ユーザ登録済エラー
    ELSIF (ir_masters_rec.user_id IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_dup_val_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_data
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- コードチェック処理(資格・職位・職務・職種・適用労働時間制・承認区分・代行区分)
    check_code(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_normal) THEN     -- 正常
      NULL;
    ELSIF (lv_retcode = cv_status_warn) THEN    -- コード未登録エラー
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_error) THEN   -- その他のエラー
      RAISE global_api_expt;
    END IF;
    --
    -- =================================
    -- 職責・管理者情報の取得処理(A-7)
    -- =================================
    get_fnd_responsibility(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN  -- SQLエラーのみ
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** 警告(更新不可データ) ***--
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
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
  END check_insert;
--
  /***********************************************************************************
   * Procedure Name   : check_update
   * Description      : 更新用データのチェック処理を行います。(A-6)
   ***********************************************************************************/
  PROCEDURE check_update(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_update'; -- プログラム名
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
    -- ユーザマスタ存在チェック
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- ユーザ取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    -- ユーザ未登録エラー
    ELSIF (ir_masters_rec.user_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_not_found_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_data
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 社員インタフェース.入社日＜アサインメントマスタ.登録年月日
    IF (ir_masters_rec.hire_date < lr_check_rec.paa_effective_start_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_st_ymd_err1
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 社員インタフェース.退職年月日＜アサインメントマスタ.登録年月日の場合、エラー
    IF (ir_masters_rec.actual_termination_date < lr_check_rec.paa_effective_start_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_st_ymd_err2
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 退職者の場合
    IF (ir_masters_rec.emp_kbn = gv_kbn_retiree) THEN
      -- 連携区分が’Y’(入社年月日・退職年月日以外にデータ差異がある)の場合、
      IF (ir_masters_rec.proc_kbn = gv_sts_yes) THEN
        --社員インタフェース.入社日に差異がない場合エラー（退職者の情報変更はエラー）
        IF (ir_masters_rec.hire_date = lr_check_rec.paa_effective_start_date) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_retiree_err1
                      ,iv_token_name1  => cv_tkn_ng_word
                      ,iv_token_value1 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name2  => cv_tkn_ng_user
                      ,iv_token_value2 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        ELSE
          -- 社員インタフェース.入社日＞サービス期間マスタ.退職日の場合、再雇用データ
          -- 再雇用の場合は、職責・管理者変更処理を行う（新規社員に同様）
          IF (ir_masters_rec.hire_date > lr_check_rec.actual_termination_date) THEN
            ir_masters_rec.ymd_kbn := gv_sts_yes;   -- 入社日連携区分('Y':日付変更データ)
            ir_masters_rec.resp_kbn := gv_sts_yes;   -- 職責・管理者変更区分('Y':日付変更データ)
-- 2009/12/11 Ver1.13 E_本稼動_00103 add start by Y.Kuboshima
            ir_masters_rec.supervisor_kbn := gv_sts_yes;
-- 2009/12/11 Ver1.13 E_本稼動_00103 add end by Y.Kuboshima
          ELSE
          -- 社員インタフェース.入社日≦サービス期間マスタ.退職日の場合、エラーとします。
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_retiree_err2
                        ,iv_token_name1  => cv_tkn_ng_word
                        ,iv_token_value1 => cv_employee_nm  -- '社員番号'
                        ,iv_token_name2  => cv_tkn_ng_user
                        ,iv_token_value2 => ir_masters_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END IF;
    --
    -- 資格・職位・職務・職種・適用労働時間制・職位並順・承認区分・代行区分に差分がある場合、コードチェックを行う
    IF ((ir_masters_rec.license_code||ir_masters_rec.job_post||ir_masters_rec.job_duty||ir_masters_rec.job_type
      ||ir_masters_rec.job_system||ir_masters_rec.job_post_order
      ||ir_masters_rec.consent_division||ir_masters_rec.agent_division)
      <> (lr_check_rec.license_code||lr_check_rec.job_post||lr_check_rec.job_duty||lr_check_rec.job_type
      ||lr_check_rec.job_system||lr_check_rec.job_post_order
      ||lr_check_rec.consent_division||lr_check_rec.agent_division)) THEN
      -- コードチェック処理(資格・職位・職務・職種・適用労働時間制・職位並順・承認区分・代行区分)
      check_code(
         ir_masters_rec
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_normal) THEN     -- 正常
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN    -- コード未登録エラー
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN   -- その他のエラー
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- =================================
    -- 職責・管理者情報の取得処理(A-7)
    -- =================================
    IF (ir_masters_rec.resp_kbn = gv_sts_yes) THEN  -- 職責・管理者変更あり
      get_fnd_responsibility(
         ir_masters_rec
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN  -- SQLエラーのみ
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 任意で例外処理を記述する ****
    WHEN global_process_expt THEN                           --*** 警告(更新不可データ) ***--
      ir_masters_rec.proc_flg := gv_sts_error;  -- 更新不可能
      ir_masters_rec.row_err_message := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 # 警告
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
  END check_update;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : 社員データのログ出力情報を格納します。(A-11)
   ***********************************************************************************/
  PROCEDURE add_report(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lr_report_rec.employee_number          := ir_masters_rec.employee_number;    --社員番号
    lr_report_rec.hire_date                := ir_masters_rec.hire_date;          --入社年月日
    lr_report_rec.actual_termination_date  := ir_masters_rec.actual_termination_date;--退職年月日
    lr_report_rec.last_name_kanji          := ir_masters_rec.last_name_kanji;    --漢字姓
    lr_report_rec.first_name_kanji         := ir_masters_rec.first_name_kanji;   --漢字名
    lr_report_rec.last_name                := ir_masters_rec.last_name;          --カナ姓
    lr_report_rec.first_name               := ir_masters_rec.first_name;         --カナ名
    lr_report_rec.sex                      := ir_masters_rec.sex;               --性別
    lr_report_rec.employee_division        := ir_masters_rec.employee_division;  --社員・外部委託区分
    lr_report_rec.location_code            := ir_masters_rec.location_code;      --所属コード（新）
    lr_report_rec.change_code              := ir_masters_rec.change_code;        --異動事由コード
    lr_report_rec.announce_date            := ir_masters_rec.announce_date;      --発令日
    lr_report_rec.office_location_code     := ir_masters_rec.office_location_code; --勤務地拠点コード（新）
    lr_report_rec.license_code             := ir_masters_rec.license_code;       --資格コード（新）
    lr_report_rec.license_name             := ir_masters_rec.license_name;       --資格名（新）
    lr_report_rec.job_post                 := ir_masters_rec.job_post;           --職位コード（新）
    lr_report_rec.job_post_name            := ir_masters_rec.job_post_name;      --職位名（新）
    lr_report_rec.job_duty                 := ir_masters_rec.job_duty;           --職務コード（新）
    lr_report_rec.job_duty_name            := ir_masters_rec.job_duty_name;      --職務名（新）
    lr_report_rec.job_type                 := ir_masters_rec.job_type;           --職種コード（新）
    lr_report_rec.job_type_name            := ir_masters_rec.job_type_name;      --職種名（新）
    lr_report_rec.job_system               := ir_masters_rec.job_system;         --適用労働時間制コード（新）
    lr_report_rec.job_system_name          := ir_masters_rec.job_system_name;    --適用労働名（新）
    lr_report_rec.job_post_order           := ir_masters_rec.job_post_order;     --職位並順コード（新）
    lr_report_rec.consent_division         := ir_masters_rec.consent_division;   --承認区分（新）
    lr_report_rec.agent_division           := ir_masters_rec.agent_division;     --代行区分（新）
    lr_report_rec.office_location_code_old := ir_masters_rec.office_location_code_old; --勤務地拠点コード（旧）
    lr_report_rec.location_code_old        := ir_masters_rec.location_code_old;  --所属コード（旧）
    lr_report_rec.license_code_old         := ir_masters_rec.license_code_old;   --資格コード（旧）
    lr_report_rec.license_code_name_old    := ir_masters_rec.license_code_name_old;--資格名（旧）
    lr_report_rec.job_post_old             := ir_masters_rec.job_post_old;       --職位コード（旧）
    lr_report_rec.job_post_name_old        := ir_masters_rec.job_post_name_old;  --職位名（旧）
    lr_report_rec.job_duty_old             := ir_masters_rec.job_duty_old;       --職務コード（旧）
    lr_report_rec.job_duty_name_old        := ir_masters_rec.job_duty_name_old;  --職務名（旧）
    lr_report_rec.job_type_old             := ir_masters_rec.job_type_old;       --職種コード（旧）
    lr_report_rec.job_type_name_old        := ir_masters_rec.job_type_name_old;  --職種名（旧）
    lr_report_rec.job_system_old           := ir_masters_rec.job_system_old;     --適用労働時間制コード（旧）
    lr_report_rec.job_system_name_old      := ir_masters_rec.job_system_name_old;--適用労働名（旧）
    lr_report_rec.job_post_order_old       := ir_masters_rec.job_post_order_old; --職位並順コード（旧）
    lr_report_rec.consent_division_old     := ir_masters_rec.consent_division_old; --承認区分（旧）
    lr_report_rec.agent_division_old       := ir_masters_rec.agent_division_old; --代行区分（旧）
    --
    lr_report_rec.message                  := ir_masters_rec.row_err_message;
    --
    -- レポートテーブルに追加
    IF  ir_masters_rec.proc_flg = gv_sts_update THEN
      gt_report_normal_tbl(gn_normal_cnt) := lr_report_rec;
    ELSIF  ir_masters_rec.proc_flg = gv_sts_error THEN
      gt_report_warn_tbl(gn_warn_cnt) := lr_report_rec;
    END IF;
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
   * Description      : レポート用データを出力します。(C-11)
   ***********************************************************************************/
  PROCEDURE disp_report(
    iv_disp_kbn    IN VARCHAR2,     -- 1.表示対象区分(cv_status_normal:正常,cv_status_warn:警告)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_normal     CONSTANT VARCHAR2(20) := '<<正常データ>>';  -- 見出し
    cv_warning    CONSTANT VARCHAR2(20) := '<<警告データ>>';  -- 見出し
    cv_errmsg     CONSTANT VARCHAR2(20) := ' [エラーメッセージ]';  -- エラーメッセージ
    lv_sep_com    CONSTANT VARCHAR2(1)  := ',';     -- カンマ
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
    cv_warnmsg    CONSTANT VARCHAR2(20) := ' [警告メッセージ]';  -- 警告メッセージ
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
    --
    -- *** ローカル変数 ***
    lv_dspbuf     VARCHAR2(5000);  -- エラー・メッセージ
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
    -- ログ見出し
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name
                 ,iv_name         => cv_rep_msg
                );
    --
    IF (iv_disp_kbn = cv_status_warn) THEN
      -- ログ見出し
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff => cv_warning --見出し１
      );
     FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => gv_out_msg --見出し２
      );
      <<report_w_loop>>
      FOR ln_disp_cnt IN 1..gn_warn_cnt LOOP
        lv_dspbuf := gt_report_warn_tbl(ln_disp_cnt).employee_number||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).hire_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).actual_termination_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).last_name_kanji||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).first_name_kanji||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).last_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).first_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).sex||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).employee_division||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).location_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).change_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).announce_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).office_location_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_name ||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_order||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).consent_division||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).agent_division||lv_sep_com||
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
-- ログの出力内容の順番を入れ替え
--                    gt_report_warn_tbl(ln_disp_cnt).office_location_code_old||lv_sep_com||
--                    gt_report_warn_tbl(ln_disp_cnt).location_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).location_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).office_location_code_old||lv_sep_com||
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify end by Y.Kuboshima
                    gt_report_warn_tbl(ln_disp_cnt).license_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_code_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_name_old ||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_order_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).consent_division_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).agent_division_old||
                    cv_errmsg||gt_report_warn_tbl(ln_disp_cnt).message
                    ;
        -- ログ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff => lv_dspbuf --警告データログ
        );
        -- 出力メッセージ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gt_report_warn_tbl(ln_disp_cnt).message
        );
      END LOOP report_w_loop;
      -- 空白行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
    --
    IF (iv_disp_kbn = cv_status_normal) THEN
      -- ログ見出し
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff => cv_normal --見出し１
      );
     FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => gv_out_msg --見出し２
      );
      <<report_n_loop>>
      FOR ln_disp_cnt IN 1..gn_normal_cnt LOOP
        lv_dspbuf := gt_report_normal_tbl(ln_disp_cnt).employee_number||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).hire_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).actual_termination_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).last_name_kanji||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).first_name_kanji||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).last_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).first_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).sex||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).employee_division||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).location_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).change_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).announce_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).office_location_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_name ||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_order||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).consent_division||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).agent_division||lv_sep_com||
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
-- ログの出力内容の順番を入れ替え
--                    gt_report_normal_tbl(ln_disp_cnt).office_location_code_old||lv_sep_com||
--                    gt_report_normal_tbl(ln_disp_cnt).location_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).location_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).office_location_code_old||lv_sep_com||
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
                    gt_report_normal_tbl(ln_disp_cnt).license_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_code_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_name_old ||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_order_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).consent_division_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).agent_division_old
                    ;
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
        IF (gt_report_normal_tbl(ln_disp_cnt).message IS NOT NULL) THEN
          lv_dspbuf := lv_dspbuf || lv_sep_com || cv_warnmsg || gt_report_normal_tbl(ln_disp_cnt).message;
        END IF;
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff => lv_dspbuf --正常データログ
        );
      END LOOP report_n_loop;
    END IF;
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
  /***********************************************************************************
   * Procedure Name   : update_resp_all
   * Description      : ユーザ職責マスタの更新処理を行います。
   ***********************************************************************************/
  PROCEDURE update_resp_all(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_resp_all'; -- プログラム名
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
    ln_retcd                 NUMBER;
    lb_retst                 BOOLEAN;
    ln_responsibility_id     fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id     fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date            fnd_user_resp_groups_all.start_date%TYPE;
    ld_start_date_u          fnd_user_resp_groups_all.start_date%TYPE;
    --
    lv_api_name              VARCHAR2(200);
    lv_update_flg            VARCHAR2(1);
--Ver1.5 Add  2009/06/02
    lv_sqlerrm               VARCHAR2(5000);    -- SQLERRM退避
--End Ver1.5
    --
    -- *** ローカル・カーソル ***
    --
    -- 職責自動割当ワーク
    CURSOR wk_pr1_cur
    IS
      SELECT xwpr.employee_number       employee_number,
             xwpr.responsibility_id     responsibility_id,
             xwpr.user_id               user_id,
             xwpr.responsibility_key    responsibility_key,
             xwpr.application_short_name    application_short_name,
             xwpr.start_date            start_date,
             xwpr.end_date              end_date
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX add start by Yutaka.Kuboshima
            ,xwpr.application_id        application_id
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX add end by Yutaka.Kuboshima
      FROM   xxcmm_wk_people_resp xwpr
      WHERE  xwpr.employee_number = ir_masters_rec.employee_number
      AND    xwpr.responsibility_id > 0
      ORDER BY xwpr.employee_number,xwpr.responsibility_id;
    --
    -- ユーザー職責マスタ
    CURSOR furg_cur(in_responsibility_id in number)
    IS
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX modify start by Yutaka.Kuboshima
--========================================
-- PT対応内容
-- 抽出項目：
-- responsibility_application_id 
--  →職責自動割当ワークのapplication_idで代用
-- security_group_id
--  →fnd_global.security_group_id(security_group_idは一つしか登録されていないから問題ないはず…)
-- 抽出条件：fnd_user_resp_groups_allをばらして
--           パーティションIDを指定する。
--========================================
--      SELECT fug.responsibility_application_id  responsibility_application_id,
--             fug.security_group_id              security_group_id
--      FROM   fnd_user_resp_groups_all fug                  -- ユーザー職責マスタ
--      WHERE  fug.user_id           = ir_masters_rec.user_id
--      AND    fug.responsibility_id = in_responsibility_id
--      AND    ROWNUM = 1;
      SELECT 'X'
      FROM   wf_user_role_assignments wura
            ,wf_local_user_roles      wlur
      WHERE  wura.role_name           = wlur.role_name
        AND  wura.user_name           = wlur.user_name
        AND  wlur.role_orig_system    = cv_role_orig_system
        AND  wlur.partition_id        = cn_partition_id
        AND  wura.partition_id        = cn_partition_id
        AND  wura.user_name           = ir_masters_rec.employee_number
        AND  wlur.role_orig_system_id = in_responsibility_id
        AND  rownum                   = 1
      ;
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX modify end by Yutaka.Kuboshima
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
    <<wk_pr1_loop>>
    FOR wk_pr1_rec IN wk_pr1_cur LOOP
      lv_update_flg := NULL;
      <<furg_rec_loop>>
      FOR furg_rec IN furg_cur(wk_pr1_rec.responsibility_id) LOOP
        EXIT WHEN furg_cur%NOTFOUND;
        --
        BEGIN
          FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
             USER_ID                       => wk_pr1_rec.user_id
            ,RESPONSIBILITY_ID             => wk_pr1_rec.responsibility_id
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX modify start by Yutaka.Kuboshima
--            ,RESPONSIBILITY_APPLICATION_ID => furg_rec.responsibility_application_id
--            ,SECURITY_GROUP_ID             => furg_rec.security_group_id
            ,RESPONSIBILITY_APPLICATION_ID => wk_pr1_rec.application_id
            ,SECURITY_GROUP_ID             => gn_security_group_id
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX modify end by Yutaka.Kuboshima
            ,START_DATE                    => wk_pr1_rec.start_date
            ,END_DATE                      => wk_pr1_rec.end_date
            ,DESCRIPTION                   => gv_const_y
          );
          lv_update_flg := gv_flg_on;
        EXCEPTION
          WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
            lv_sqlerrm := SQLERRM;
--End Ver1.5
            lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_api_err
                        ,iv_token_name1  => cv_tkn_apiname
                        ,iv_token_value1 => lv_api_name
                        ,iv_token_name2  => cv_tkn_ng_word
                        ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                        ,iv_token_name3  => cv_tkn_ng_data
                        ,iv_token_value3 => ir_masters_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
            lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
            RAISE global_process_expt;
        END;
      END LOOP furg_rec_loop;
      --
      IF lv_update_flg IS NULL THEN
        -- 新規社員職責登録
        -- ユーザ職責マスタ
        BEGIN
          FND_USER_RESP_GROUPS_API.LOAD_ROW(
            X_USER_NAME         => wk_pr1_rec.employee_number
           ,X_RESP_KEY          => wk_pr1_rec.responsibility_key
           ,X_APP_SHORT_NAME    => wk_pr1_rec.application_short_name
           ,X_SECURITY_GROUP    => 'STANDARD'
           ,X_OWNER             => gn_created_by
           ,X_START_DATE        => TO_CHAR(wk_pr1_rec.start_date,'YYYY/MM/DD')
           ,X_END_DATE          => TO_CHAR(wk_pr1_rec.end_date,'YYYY/MM/DD')
           ,X_DESCRIPTION       => NULL
           ,X_LAST_UPDATE_DATE  => SYSDATE
          );
        EXCEPTION
          WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
            lv_sqlerrm := SQLERRM;
--End Ver1.5
            lv_api_name := 'FND_USER_RESP_GROUPS_API.LOAD_ROW';
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_api_err
                        ,iv_token_name1  => cv_tkn_apiname
                        ,iv_token_value1 => lv_api_name
                        ,iv_token_name2  => cv_tkn_ng_word
                        ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                        ,iv_token_name3  => cv_tkn_ng_data
                        ,iv_token_value3 => wk_pr1_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
            lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
            RAISE global_process_expt;
        END;
      END IF;
    END LOOP wk_pr1_loop;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--Ver1.5 Add  2009/06/02
      --ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
--End Ver1.5
      ov_retcode := cv_status_error;
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
  END update_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : delete_resp_all
   * Description      : ユーザー職責マスタのデータの無効化を行います。
   ***********************************************************************************/
  PROCEDURE delete_resp_all(
    ir_masters_rec IN OUT masters_rec,  -- 1.チェック対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_resp_all'; -- プログラム名
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
    ln_user_id                  fnd_user_resp_groups_all.user_id%TYPE;
    ln_responsibility_id        fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id    fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id        fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date               fnd_user_resp_groups_all.start_date%TYPE;
    --
    lv_api_name                 VARCHAR2(200);  -- エラートークン用
--Ver1.5 Add  2009/06/02
    lv_sqlerrm                  VARCHAR2(5000); -- SQLERRM退避
--End Ver1.5
    --
    -- *** ローカル・カーソル ***
    CURSOR fug_cur
    IS
      SELECT fug.user_id            user_id,
             fug.responsibility_id  responsibility_id,
             fug.responsibility_application_id  responsibility_application_id,
             fug.security_group_id  security_group_id,
             fug.start_date         start_date
      FROM   fnd_user_resp_groups_all fug                      -- ユーザー職責マスタ
      WHERE  fug.user_id = ir_masters_rec.user_id;
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
    <<fug_cur_loop>>
    FOR fug_rec IN fug_cur LOOP
      --
      BEGIN
        -- API起動
        FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
            USER_ID                       => fug_rec.user_id
           ,RESPONSIBILITY_ID             => fug_rec.responsibility_id
           ,RESPONSIBILITY_APPLICATION_ID => fug_rec.responsibility_application_id
           ,SECURITY_GROUP_ID             => fug_rec.security_group_id
           ,START_DATE                    => fug_rec.start_date
           ,END_DATE                      => cd_process_date
           ,DESCRIPTION                   => gv_const_y
        );
        --
      EXCEPTION
        WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
          lv_sqlerrm := SQLERRM;
--End Ver1.5
          lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
          lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
          RAISE global_process_expt;
      END;
    END LOOP fug_cur_loop;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--Ver1.5 Add  2009/06/02
      --ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
--End Ver1.5
      ov_retcode := cv_status_error;
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
--#####################################  固定部 END   #############################################
--
  END delete_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : insert_resp_all
   * Description      : ユーザ職責マスタへの登録を行います。
   ***********************************************************************************/
  PROCEDURE insert_resp_all(
    iv_emp_number  IN VARCHAR2, -- 1.社員番号
    iv_resp_key    IN VARCHAR2, -- 2.職責キー
    iv_app_name    IN VARCHAR2, -- 3.アプリケーション名
    iv_st_date     IN DATE,     -- 4.有効日(自)
    iv_en_date     IN DATE,     -- 5.有効日(至)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_resp_all'; -- プログラム名
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
    lv_api_name                 VARCHAR2(200); -- エラートークン用
--Ver1.5 Add  2009/06/02
    lv_sqlerrm                  VARCHAR2(5000); -- SQLERRM退避
--End Ver1.5
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
    BEGIN
      --
      -- ユーザ職責マスタ
      FND_USER_RESP_GROUPS_API.LOAD_ROW(
        X_USER_NAME         => iv_emp_number
       ,X_RESP_KEY          => iv_resp_key
       ,X_APP_SHORT_NAME    => iv_app_name
       ,X_SECURITY_GROUP    => 'STANDARD'
       ,X_OWNER             => gn_created_by
       ,X_START_DATE        => TO_CHAR(iv_st_date,'YYYY/MM/DD')
       ,X_END_DATE          => TO_CHAR(iv_en_date,'YYYY/MM/DD')
       ,X_DESCRIPTION       => NULL
       ,X_LAST_UPDATE_DATE  => SYSDATE
      );
    EXCEPTION
      WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
        lv_sqlerrm := SQLERRM;
--End Ver1.5
        lv_api_name := 'FND_USER_RESP_GROUPS_API.LOAD_ROW';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => iv_emp_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--Ver1.5 Add  2009/06/02
      --ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
--End Ver1.5
      ov_retcode := cv_status_error;
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
  END insert_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : get_service_id
   * Description      : サービス期間IDの取得を行います。(退職処理前情報の取得)
   ***********************************************************************************/
  PROCEDURE get_service_id(
    ir_masters_rec IN OUT masters_rec,  -- 1.退職対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_service_id'; -- プログラム名
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
    -- 退職処理に使用（退職前の対象従業員のｻｰﾋﾞｽIDを求める）
    SELECT ppos.period_of_service_id,           -- サービスID
           ppos.object_version_number           -- ｻｰﾋﾞｽ期間ﾏｽﾀのﾊﾞｰｼﾞｮﾝ
    INTO   ir_masters_rec.period_of_service_id,
           ir_masters_rec.ppos_version
    FROM   per_periods_of_service ppos,         -- サービス期間マスタ
           per_all_people_f pap                 -- 従業員マスタ
    WHERE  ppos.person_id = ir_masters_rec.person_id
    AND    ppos.actual_termination_date IS NULL
    AND    ROWNUM = 1;
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
  END get_service_id;
--
  /***********************************************************************************
   * Procedure Name   : get_person_type
   * Description      : パーソンタイプの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_person_type(
    iv_user_person_type   IN VARCHAR2, -- 1.パーソンタイプ
    ov_person_type_id    OUT VARCHAR2, -- 2.パーソンタイプID
    ov_business_group_id OUT VARCHAR2, -- 3.ビジネスグループID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_person_type'; -- プログラム名
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
    -- ===============================
    -- パーソンタイプの取得
    -- ===============================
    BEGIN
      SELECT ppt.person_type_id,
             ppt.business_group_id
      INTO   ov_person_type_id,
             ov_business_group_id
      FROM   per_person_types ppt     -- パーソンタイプマスタ
      WHERE  ppt.user_person_type = iv_user_person_type
      AND    ROWNUM = 1;
    EXCEPTION
      -- データなしの場合も継続
      WHEN NO_DATA_FOUND THEN
        ov_person_type_id    := NULL;
        ov_business_group_id := NULL;
      --
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
  END get_person_type;
--
  /***********************************************************************************
   * Procedure Name   : changes_proc
   * Description      : 異動処理を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE changes_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.異動対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'changes_proc'; -- プログラム名
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
    -- HR_PERSON_API.UPDATE_PERSON
    lv_full_name                per_all_people_f.full_name%TYPE;
    ln_comment_id               per_all_people_f.comment_id%TYPE;
    lb_name_combination_warning BOOLEAN;
    lb_assign_payroll_warning   BOOLEAN;
    lb_orig_hire_warning        BOOLEAN;
    --
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments    VARCHAR2(200);
    ln_soft_coding_keyflex_id   per_all_assignments_f.soft_coding_keyflex_id%TYPE;
    lb_no_managers_warning      BOOLEAN;
    lb_other_manager_warning    BOOLEAN;
    --
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id%TYPE;
    ln_people_group_id              per_all_assignments_f.people_group_id%TYPE;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(1);
    lb_tax_district_changed_warn    BOOLEAN;
-- 2009/08/06 Ver1.10 障害0000510 add start by Yutaka.Kuboshima
    ln_job_id                       per_all_assignments_f.job_id%TYPE; -- 役職ID
    lv_reference_range              per_all_people_f.attribute29%TYPE; -- 照会範囲
    --
    lv_purchasing_flag              VARCHAR2(1);                       -- 購買担当フラグ
    lv_shipping_flag                VARCHAR2(1);                       -- 出荷担当フラグ
-- 2009/08/06 Ver1.10 障害0000510 add end by Yutaka.Kuboshima
    --
    lv_api_name                   VARCHAR2(200); -- エラートークン用
--Ver1.5 Add  2009/06/02
    lv_sqlerrm                    VARCHAR2(5000); -- SQLERRM退避
--End Ver1.5
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
-- 2009/08/06 Ver1.10 障害0000924 add start by Yutaka.Kuboshima
    -- 照会範囲の設定
    -- 所属コード(新)が財務経理部の場合
    IF (ir_masters_rec.location_code = gv_zaimu_bumon_cd) THEN
      -- 照会範囲に'T'を設定します
      lv_reference_range := gv_aff_dept_cd;
    ELSE
      -- 照会範囲に所属コード(新)を設定します
      lv_reference_range := ir_masters_rec.location_code;
    END IF;
-- 2009/08/06 Ver1.10 障害0000924 add end by Yutaka.Kuboshima
    -- 従業員マスタ(API)
    BEGIN
      --
      HR_PERSON_API.UPDATE_PERSON(
         P_VALIDATE                     =>  FALSE
        ,P_EFFECTIVE_DATE               =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE        =>  gv_upd_mode                           -- 'CORRECTION'
        ,P_PERSON_ID                    =>  ir_masters_rec.person_id              -- 従業員ID
        ,P_OBJECT_VERSION_NUMBER        =>  ir_masters_rec.pap_version            -- 従業員ﾏｽﾀﾊﾞｰｼﾞｮﾝ(IN/OUT)
        ,P_PERSON_TYPE_ID               =>  gv_person_type                        -- パーソンタイプ
        ,P_LAST_NAME                    =>  ir_masters_rec.last_name              -- カナ姓
        ,P_EMPLOYEE_NUMBER              =>  ir_masters_rec.employee_number        -- 社員番号(IN/OUT)
-- Ver1.3 Add  2009/04/16  「O:会社」を設定
        ,P_EXPENSE_CHECK_SEND_TO_ADDRES =>  cv_send_to_addres                     -- 郵便送付先(コード)
-- Ver1.3 End
        ,P_FIRST_NAME                   =>  ir_masters_rec.first_name             -- カナ名
        ,P_SEX                          =>  ir_masters_rec.sex                    -- 性別
-- Ver1.2  2009/04/03 Add コンテキストに SALES-OU を設定 
        ,P_ATTRIBUTE_CATEGORY           =>  gn_org_id                             -- ORG_ID
-- End
        ,P_ATTRIBUTE3                   =>  ir_masters_rec.employee_division      -- 従業員区分
        ,P_ATTRIBUTE7                   =>  ir_masters_rec.license_code           -- 資格コード（新）
        ,P_ATTRIBUTE8                   =>  ir_masters_rec.license_name           -- 資格名（新）
        ,P_ATTRIBUTE9                   =>  ir_masters_rec.license_code_old       -- 資格コード（旧）
        ,P_ATTRIBUTE10                  =>  ir_masters_rec.license_code_name_old  -- 資格名（旧）
        ,P_ATTRIBUTE11                  =>  ir_masters_rec.job_post               -- 職位コード（新）
        ,P_ATTRIBUTE12                  =>  ir_masters_rec.job_post_name          -- 職位名（新）
        ,P_ATTRIBUTE13                  =>  ir_masters_rec.job_post_old           -- 職位コード（旧）
        ,P_ATTRIBUTE14                  =>  ir_masters_rec.job_post_name_old      -- 職位名（旧）
        ,P_ATTRIBUTE15                  =>  ir_masters_rec.job_duty               -- 職務コード（新）
        ,P_ATTRIBUTE16                  =>  ir_masters_rec.job_duty_name          -- 職務名（新）
        ,P_ATTRIBUTE17                  =>  ir_masters_rec.job_duty_old           -- 職務コード（旧）
        ,P_ATTRIBUTE18                  =>  ir_masters_rec.job_duty_name_old      -- 職務名（旧）
        ,P_ATTRIBUTE19                  =>  ir_masters_rec.job_type               -- 職種コード（新）
        ,P_ATTRIBUTE20                  =>  ir_masters_rec.job_type_name          -- 職種名（新）
        ,P_ATTRIBUTE21                  =>  ir_masters_rec.job_type_old           -- 職種コード（旧）
        ,P_ATTRIBUTE22                  =>  ir_masters_rec.job_type_name_old      -- 職種名（旧）
        ,P_ATTRIBUTE28                  =>  ir_masters_rec.location_code          -- 起票部門(所属コード（新）)
-- 2009/08/06 Ver1.10 障害0000924 modify start by Yutaka.Kuboshima
--        ,P_ATTRIBUTE29                  =>  ir_masters_rec.location_code          -- 照会範囲(所属コード（新）)
        ,P_ATTRIBUTE29                  =>  lv_reference_range                    -- 照会範囲
-- 2009/08/06 Ver1.10 障害0000924 modify end by Yutaka.Kuboshima
        ,P_ATTRIBUTE30                  =>  ir_masters_rec.location_code          -- 承認者範囲(所属コード（新）)
        ,P_PER_INFORMATION_CATEGORY     => gv_info_category                       -- 'JP'
        ,P_PER_INFORMATION18            =>  ir_masters_rec.last_name_kanji        -- 漢字姓
        ,P_PER_INFORMATION19            =>  ir_masters_rec.first_name_kanji       -- 漢字名
        ,P_EFFECTIVE_START_DATE         =>  ir_masters_rec.effective_start_date   -- OUT(登録年月日)
        ,P_EFFECTIVE_END_DATE           =>  ir_masters_rec.effective_end_date     -- OUT(登録期限年月日)
        ,P_FULL_NAME                    =>  lv_full_name                          -- OUT
        ,P_COMMENT_ID                   =>  ln_comment_id                         -- OUT
        ,P_NAME_COMBINATION_WARNING     => lb_name_combination_warning            -- OUT
        ,P_ASSIGN_PAYROLL_WARNING       =>  lb_assign_payroll_warning             -- OUT
        ,P_ORIG_HIRE_WARNING            =>  lb_orig_hire_warning                  -- OUT
        );
    --
    EXCEPTION
      WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
        lv_sqlerrm := SQLERRM;
--End Ver1.5
        lv_api_name := 'HR_PERSON_API.UPDATE_PERSON';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
-- 2009/08/06 Ver1.10 障害0000510,0000910 add start by Yutaka.Kuboshima
    -- 事業所取得
    get_location(
      ir_masters_rec.location_code           -- IN : 所属コード(新)
     ,lv_purchasing_flag                     -- OUT: 購買担当フラグ
     ,lv_shipping_flag                       -- OUT: 出荷担当フラグ
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 役職取得
    get_job(
      ir_masters_rec.person_id               -- IN ：従業員ID
     ,ir_masters_rec.location_code           -- IN ：所属コード(新)
     ,ir_masters_rec.job_post_order          -- IN ：職位並順コード(新)
     ,ir_masters_rec.hire_date               -- IN ：入社日
     ,lv_purchasing_flag                     -- IN : 購買担当フラグ
     ,ln_job_id                              -- OUT：役職ID
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
-- 2009/08/06 Ver1.10 障害0000510,0000910 add end by Yutaka.Kuboshima
--
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
-- 所属コード(新)、職位並び順コード(新)が変更された場合のみ管理者を取得する
---- Ver1.6  Add  2009/06/22  管理者取得処理を追加  T1_1389
--    -- 管理者取得
--    get_supervisor(
--      ir_masters_rec.person_id               -- IN ：従業員ID
--     ,ir_masters_rec.office_location_code    -- IN ：勤務地拠点コード(新)
--     ,ir_masters_rec.job_post_order          -- IN ：職位並順コード(新)
--     ,ir_masters_rec.hire_date               -- IN ：入社日
--     ,ir_masters_rec.supervisor_id           -- OUT：管理者ID
--     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
--     ,lv_retcode                             -- リターン・コード             --# 固定 #
--     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
--    );
---- End1.6
---- 2009/08/06 Ver1.10 障害0000794 add start by Yutaka.Kuboshima
--    -- 最上位の管理者の場合、管理者はNULLに設定します
--    IF (ir_masters_rec.employee_number = gv_supervisor) THEN
--      ir_masters_rec.supervisor_id := NULL;
--    END IF;
---- 2009/08/06 Ver1.10 障害0000794 add end by Yutaka.Kuboshima
--
    IF (ir_masters_rec.supervisor_kbn = gv_sts_yes) THEN
      -- 管理者取得
      get_supervisor(
        ir_masters_rec.person_id               -- IN ：従業員ID
-- 2009/12/11 Ver1.13 E_本稼動_00103 add start by Y.Kuboshima
--       ,ir_masters_rec.office_location_code    -- IN ：勤務地拠点コード(新)
       ,ir_masters_rec.location_code           -- IN ：所属コード(新)
-- 2009/12/11 Ver1.13 E_本稼動_00103 add end by Y.Kuboshima
       ,ir_masters_rec.job_post_order          -- IN ：職位並順コード(新)
       ,ir_masters_rec.hire_date               -- IN ：入社日
       ,ir_masters_rec.supervisor_id           -- OUT：管理者ID
       ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
       ,lv_retcode                             -- リターン・コード             --# 固定 #
       ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 最上位の管理者の場合、管理者はNULLに設定します
      IF (ir_masters_rec.employee_number = gv_supervisor) THEN
        ir_masters_rec.supervisor_id := NULL;
      END IF;
    END IF;
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify end by Y.Kuboshima
    --
    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE               =>  FALSE
        ,P_EFFECTIVE_DATE         =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE  =>  gv_upd_mode                              -- 'CORRECTION'
        ,P_ASSIGNMENT_ID          =>  ir_masters_rec.assignment_id             -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
        ,P_OBJECT_VERSION_NUMBER  =>  ir_masters_rec.paa_version               -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 管理者の割当をAPI -> 直UPDATEに変更
--        ,P_SUPERVISOR_ID          =>  ir_masters_rec.supervisor_id             -- 管理者
        ,P_SUPERVISOR_ID          =>  NULL                                     -- 管理者
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
        ,P_ASSIGNMENT_NUMBER      =>  ir_masters_rec.assignment_number         -- ｱｻｲﾝﾒﾝﾄ番号(ﾁｪｯｸ時取得)
-- Ver1.3
--        ,P_DEFAULT_CODE_COMB_ID   =>  gv_default                               -- ﾌﾟﾛﾌｧｲﾙｵﾌﾟｼｮﾝ.ﾃﾞﾌｫﾙﾄ費用勘定
        ,P_SET_OF_BOOKS_ID        =>  gn_set_of_book_id                        -- 会計帳簿ID
        ,P_DEFAULT_CODE_COMB_ID   =>  ir_masters_rec.default_code_comb_id      -- デフォルト費用勘定
-- End Ver1.3
        ,P_ASS_ATTRIBUTE1         =>  ir_masters_rec.change_code               -- 異動事由コード
        ,P_ASS_ATTRIBUTE2         =>  ir_masters_rec.announce_date             -- 発令日
        ,P_ASS_ATTRIBUTE3         =>  ir_masters_rec.office_location_code      -- 勤務地拠点コード（新）
        ,P_ASS_ATTRIBUTE4         =>  ir_masters_rec.office_location_code_old  -- 勤務地拠点コード（旧）
        ,P_ASS_ATTRIBUTE5         =>  ir_masters_rec.location_code             -- 拠点コード（新）
        ,P_ASS_ATTRIBUTE6         =>  ir_masters_rec.location_code_old         -- 拠点コード（旧）
        ,P_ASS_ATTRIBUTE7         =>  ir_masters_rec.job_system                -- 適用労働時間制コード（新）
        ,P_ASS_ATTRIBUTE8         =>  ir_masters_rec.job_system_name           -- 適用労働名（新）
        ,P_ASS_ATTRIBUTE9         =>  ir_masters_rec.job_system_old            -- 適用労働時間制コード（旧）
        ,P_ASS_ATTRIBUTE10        =>  ir_masters_rec.job_system_name_old       -- 適用労働名（旧）
        ,P_ASS_ATTRIBUTE11        =>  ir_masters_rec.job_post_order            -- 職位並順コード（新）
        ,P_ASS_ATTRIBUTE12        =>  ir_masters_rec.job_post_order_old        -- 職位並順コード（旧）
        ,P_ASS_ATTRIBUTE13        =>  ir_masters_rec.consent_division          -- 承認区分（新）
        ,P_ASS_ATTRIBUTE14        =>  ir_masters_rec.consent_division_old      -- 承認区分（旧）
        ,P_ASS_ATTRIBUTE15        =>  ir_masters_rec.agent_division            -- 代行区分（新）
        ,P_ASS_ATTRIBUTE16        =>  ir_masters_rec.agent_division_old        -- 代行区分（旧）
        ,P_ASS_ATTRIBUTE17        =>  NULL                                     -- 差分連携用日付（自販機）
        ,P_ASS_ATTRIBUTE18        =>  NULL                                     -- 差分連携用日付（帳票）
        ,P_CONCATENATED_SEGMENTS  =>  lv_concatenated_segments                 -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID =>  ln_soft_coding_keyflex_id                -- IN/OUT
        ,P_COMMENT_ID             =>  ln_comment_id                            -- OUT
        ,P_EFFECTIVE_START_DATE   =>  ir_masters_rec.effective_start_date      -- OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE     =>  ir_masters_rec.effective_end_date        -- OUT（登録期限年月日）
        ,P_NO_MANAGERS_WARNING    =>  lb_no_managers_warning                   -- OUT
        ,P_OTHER_MANAGER_WARNING  =>  lb_other_manager_warning                 -- OUT
      );
    --
    EXCEPTION
      WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
        lv_sqlerrm := SQLERRM;
--End Ver1.5
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                   );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
    IF (ir_masters_rec.location_id_kbn = gv_sts_yes) THEN  -- 事業所 変更あり
      -- アサインメントマスタ(API)
      BEGIN
        HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
           P_VALIDATE                      =>  FALSE
          ,P_EFFECTIVE_DATE                =>  SYSDATE
          ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                          -- 'CORRECTION'
          ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id         -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
-- 2009/08/06 Ver1.10 障害0000510 add start by Yutaka.Kuboshima
          ,P_JOB_ID                        =>  ln_job_id                            -- 役職ID
-- 2009/08/06 Ver1.10 障害0000510 add end by Yutaka.Kuboshima
          ,P_LOCATION_ID                   =>  ir_masters_rec.location_id           -- 事業所(勤務地拠点コード変更時）
          ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version           -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
          ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id           -- OUT
          ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id                   -- OUT
          ,P_GROUP_NAME                    =>  lv_group_name                        -- OUT
          ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date  -- OUT（登録年月日）
          ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date    -- OUT（登録期限年月日）
          ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning        -- OUT
          ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning             -- OUT
          ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning                -- OUT
          ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn              -- OUT
          ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn         -- OUT
        );
      EXCEPTION
        WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
          lv_sqlerrm := SQLERRM;
--End Ver1.5
          lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
          lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
          RAISE global_process_expt;
      END;
    END IF;
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
-- 管理者の割当をAPI -> 直UPDATEに変更
    -- 管理者更新
    UPDATE per_all_assignments_f
    SET    supervisor_id        = ir_masters_rec.supervisor_id
    WHERE  assignment_id        = ir_masters_rec.assignment_id
    AND    effective_start_date = ir_masters_rec.effective_start_date
    AND    effective_end_date   = ir_masters_rec.effective_end_date;
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--Ver1.5 Add  2009/06/02
      --ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
--End Ver1.5
      ov_retcode := cv_status_error;
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
  END changes_proc;
--
  /***********************************************************************************
   * Procedure Name   : retire_proc
   * Description      : 退職処理を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE retire_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.退職対象データ
    ir_retire_date IN OUT DATE,         -- 2.退職日を設定
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'retire_proc'; -- プログラム名
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
    -- HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP
    ld_last_std_process_date    DATE;
    lb_supervisor_warn          BOOLEAN;
    lb_event_warn               BOOLEAN;
    lb_interview_warn           BOOLEAN;
    lb_review_warn              BOOLEAN;
    lb_recruiter_warn           BOOLEAN;
    lb_asg_future_changes_warn  BOOLEAN;
    lv_entries_changed_warn     VARCHAR2(200);
    lb_pay_proposal_warn        BOOLEAN;
    lb_dod_warn                 BOOLEAN;
    --
    -- HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP(
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_asg_future_changes_warning   BOOLEAN;
    lv_entries_changed_warning      VARCHAR2(1);
    --
    lv_api_name                 VARCHAR2(200); -- エラートークン用
--Ver1.5 Add  2009/06/02
    lv_sqlerrm                  VARCHAR2(5000); -- SQLERRM退避
--End Ver1.5
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
    -- サービス期間ID取得
    get_service_id(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- サービス期間ID取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
    BEGIN
      -- 従業員マスタ(API)
      HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP(
        P_VALIDATE                   => FALSE
       ,P_EFFECTIVE_DATE             => (ir_retire_date - 1)                    -- 登録期限年月日
       ,P_PERIOD_OF_SERVICE_ID       => ir_masters_rec.period_of_service_id     -- サービスID
       ,P_OBJECT_VERSION_NUMBER      => ir_masters_rec.ppos_version             -- ｻｰﾋﾞｽ期間ﾏｽﾀﾊﾞｰｼﾞｮﾝ番号
       ,P_ACTUAL_TERMINATION_DATE    => ir_retire_date                          -- 退職日
       ,P_LAST_STANDARD_PROCESS_DATE => ir_retire_date                          -- 最終給与処理日
       ,P_PERSON_TYPE_ID             => gv_person_type_ex                       -- パーソンタイプ(退職者)
       ,P_LAST_STD_PROCESS_DATE_OUT  => ld_last_std_process_date    -- OUT
       ,P_SUPERVISOR_WARNING         => lb_supervisor_warn          -- OUT
       ,P_EVENT_WARNING              => lb_event_warn               -- OUT
       ,P_INTERVIEW_WARNING          => lb_interview_warn           -- OUT
       ,P_REVIEW_WARNING             => lb_review_warn              -- OUT
       ,P_RECRUITER_WARNING          => lb_recruiter_warn           -- OUT
       ,P_ASG_FUTURE_CHANGES_WARNING => lb_asg_future_changes_warn  -- OUT
       ,P_ENTRIES_CHANGED_WARNING    => lv_entries_changed_warn     -- OUT
       ,P_PAY_PROPOSAL_WARNING       => lb_pay_proposal_warn        -- OUT
       ,P_DOD_WARNING                => lb_dod_warn                 -- OUT
      );
    --
    EXCEPTION
      WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
        lv_sqlerrm := SQLERRM;
--End Ver1.5
        lv_api_name := 'HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
    BEGIN
      HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP(
        P_VALIDATE                      => FALSE
       ,P_PERIOD_OF_SERVICE_ID          => ir_masters_rec.period_of_service_id  -- ｻｰﾋﾞｽID
       ,P_OBJECT_VERSION_NUMBER         => ir_masters_rec.ppos_version          -- ｻｰﾋﾞｽ期間ﾏｽﾀﾊﾞｰｼﾞｮﾝ番号
       ,P_FINAL_PROCESS_DATE            => ir_retire_date    -- 退職日(IN/OUT)（P_ACTUAL_TERMINATION_DATEと同じ日を設定）
       ,P_ORG_NOW_NO_MANAGER_WARNING    => lb_org_now_no_manager_warning    -- OUT
       ,P_ASG_FUTURE_CHANGES_WARNING    => lb_asg_future_changes_warning    -- OUT
       ,P_ENTRIES_CHANGED_WARNING       => lv_entries_changed_warning   -- OUT
      );
    --
    EXCEPTION
      WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
        lv_sqlerrm := SQLERRM;
--End Ver1.5
        lv_api_name := 'HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
    IF ir_masters_rec.emp_kbn = gv_kbn_new THEN  -- 新規社員はinsert_procにて更新
      NULL;
    ELSE
      -- ユーザマスタ(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
           X_USER_NAME            => ir_masters_rec.employee_number -- 社員番号
          ,X_OWNER                => gv_owner                       -- 'CUST'
          ,X_END_DATE             => ir_retire_date                 -- 有効日（至）
        );
      --
      EXCEPTION
        WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
          lv_sqlerrm := SQLERRM;
--End Ver1.5
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
          lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
          RAISE global_process_expt;
      END;
    END IF;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--Ver1.5 Add  2009/06/02
      --ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
--End Ver1.5
      ov_retcode := cv_status_error;
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
  END retire_proc;
--
  /***********************************************************************************
   * Procedure Name   : re_hire_proc
   * Description      : 退職者を再雇用登録を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE re_hire_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.再雇用対象データ
    ir_retire_date IN DATE,             -- 2.退職日
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 're_hire_proc'; -- プログラム名
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
    -- HR_EX_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE
    ln_assignment_sequence      per_all_assignments_f.assignment_sequence%TYPE;
    lb_assign_payroll_warning   BOOLEAN;
    --
    -- 退職データの待避(PERSON_TYPE_ID:'EMP')
    ln_assignment_id_old        per_all_assignments_f.assignment_id%TYPE;
    ld_effective_start_date_old per_all_assignments_f.effective_start_date%TYPE;
    --
    lv_api_name                 VARCHAR2(200); -- エラートークン用
    --
    lv_sqlerrm                  VARCHAR2(5000);  -- SQLERRM退避
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
    -- ユーザ存在チェック
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- ユーザ取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- 従業員マスタの退職後レコードの取得（PERSON_TYPE_ID:EX_EMP のレコードを再雇用レコードに更新）
    BEGIN
      SELECT object_version_number
      INTO   ir_masters_rec.pap_version
      FROM   per_all_people_f pap           -- 従業員マスタ
      WHERE  pap.person_id = ir_masters_rec.person_id           -- パーソンID
      AND    pap.effective_start_date = (ir_retire_date + 1)    -- 登録年月日(入社日)
      AND    pap.effective_end_date >= (ir_retire_date + 1)     -- 登録期限年月日
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    -- 従業員マスタの履歴レコードの待避
    ln_assignment_id_old        := ir_masters_rec.assignment_id;
    ld_effective_start_date_old := ir_masters_rec.effective_start_date;
    --
    BEGIN
      -- 従業員マスタ(API) -- 再雇用 --
      HR_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE(
        P_VALIDATE                  =>  FALSE
       ,P_HIRE_DATE                 =>  ir_masters_rec.hire_date            -- 社員ｲﾝﾀﾌｪｰｽ.入社年月日
       ,P_PERSON_ID                 =>  ir_masters_rec.person_id            -- 従業員ID
       ,P_PER_OBJECT_VERSION_NUMBER =>  ir_masters_rec.pap_version          -- 従業員ﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
       ,P_PERSON_TYPE_ID            =>  gv_person_type                      -- パーソンタイプ
       ,P_REHIRE_REASON             =>  NULL
       ,P_ASSIGNMENT_ID             =>  ir_masters_rec.assignment_id        -- OUT（新ｱｻｲﾝﾒﾝﾄID）
       ,P_ASG_OBJECT_VERSION_NUMBER =>  ir_masters_rec.paa_version          -- OUT（新ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号）
       ,P_PER_EFFECTIVE_START_DATE  =>  ir_masters_rec.effective_start_date -- OUT（新登録年月日）
       ,P_PER_EFFECTIVE_END_DATE    =>  ir_masters_rec.effective_end_date   -- OUT（新登録期限年月日）
       ,P_ASSIGNMENT_SEQUENCE       =>  ln_assignment_sequence              -- OUT
       ,P_ASSIGNMENT_NUMBER         =>  ir_masters_rec.assignment_number    -- OUT（新ｱｻｲﾝﾒﾝﾄ番号）
       ,P_ASSIGN_PAYROLL_WARNING    =>  lb_assign_payroll_warning           -- OUT
        );
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        lv_api_name := 'HR_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
    -- アサインメントマスタに新レコードが作成された場合(UPDATEではなく履歴が作成 assignment_sequenceもｶｳﾝﾄｱｯﾌﾟ)
    IF ir_masters_rec.assignment_id <> ln_assignment_id_old THEN
      -- 自販機・営業帳票側に、更新レコードとして２レコードが送られる為、旧データの
      -- 差分連携用日付（自販機）差分連携用日付（帳票）に更新日付をセットし回避する
      BEGIN
        UPDATE per_all_assignments_f
        SET    ASS_ATTRIBUTE17 = TO_CHAR(gd_last_update_date,'YYYYMMDD HH24:MI:SS')
              ,ASS_ATTRIBUTE18 = TO_CHAR(gd_last_update_date,'YYYYMMDD HH24:MI:SS')
        WHERE  assignment_id        = ln_assignment_id_old
        AND    effective_start_date = ld_effective_start_date_old
        AND    effective_end_date   >= ld_effective_start_date_old
        ;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
    --
    -- アサインメントマスタ・サービス期間マスタの新情報取得
    --(再雇用処理ではupdatemodeがない為、ｱｻｲﾝﾒﾝﾄﾏｽﾀ・ｻｰﾋﾞｽ期間ﾏｽﾀが履歴として作成される。情報を再取得する）
    BEGIN
      SELECT paa.period_of_service_id,
             ppos.object_version_number
      INTO   ir_masters_rec.period_of_service_id,
             ir_masters_rec.ppos_version
      FROM   per_all_assignments_f paa,     -- アサインメントマスタ
             per_periods_of_service ppos    -- 従業員サービス期間マスタ
      WHERE  paa.assignment_id    = ir_masters_rec.assignment_id        -- 新アサインメントID
      AND    effective_start_date = ir_masters_rec.effective_start_date -- 登録年月日
      AND    effective_end_date   = ir_masters_rec.effective_end_date   -- 登録期限年月日
      AND    ppos.period_of_service_id = paa.period_of_service_id;  -- サービスID
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    -- 再雇用処理後時は事業所の更新を行う
    ir_masters_rec.location_id_kbn := gv_sts_yes;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
      ov_retcode := cv_status_error;
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
  END re_hire_proc;
--
  /***********************************************************************************
   * Procedure Name   : re_hire_ass_proc
   * Description      : 再雇用登録を行った社員のアサインメントを登録するプロシージャ
   ***********************************************************************************/
  PROCEDURE re_hire_ass_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.再雇用対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 're_hire_ass_proc'; -- プログラム名
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
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments    VARCHAR2(200);
    ln_soft_coding_keyflex_id   per_all_assignments_f.soft_coding_keyflex_id%TYPE;
    ln_comment_id               per_all_people_f.comment_id%TYPE;
    lb_no_managers_warning      BOOLEAN;
    lb_other_manager_warning    BOOLEAN;
    --
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id%TYPE;
    ln_people_group_id              per_all_assignments_f.people_group_id%TYPE;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(1);
    lb_tax_district_changed_warn    BOOLEAN;
-- 2009/08/06 Ver1.10 障害0000510 add start by Yutaka.Kuboshima
    ln_job_id                       per_all_assignments_f.job_id%TYPE;
    --
    lv_purchasing_flag              VARCHAR2(1);   -- 購買担当フラグ
    lv_shipping_flag                VARCHAR2(1);   -- 出荷担当フラグ
-- 2009/08/06 Ver1.10 障害0000510 add end by Yutaka.Kuboshima
    --
    lv_api_name                   VARCHAR2(200); -- エラートークン用
--Ver1.5 Add  2009/06/02
    lv_sqlerrm                    VARCHAR2(5000);  -- SQLERRM退避
--End Ver1.5
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
-- 2009/08/06 Ver1.10 障害0000510 add start by Yutaka.Kuboshima
    -- 事業所取得
    get_location(
      ir_masters_rec.location_code           -- IN : 所属コード(新)
     ,lv_purchasing_flag                     -- OUT: 購買担当フラグ
     ,lv_shipping_flag                       -- OUT: 出荷担当フラグ
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 役職取得
    get_job(
      ir_masters_rec.person_id               -- IN ：従業員ID
     ,ir_masters_rec.location_code           -- IN ：所属コード(新)
     ,ir_masters_rec.job_post_order          -- IN ：職位並順コード(新)
     ,ir_masters_rec.hire_date               -- IN ：入社日
     ,lv_purchasing_flag                     -- IN : 購買担当フラグ
     ,ln_job_id                              -- OUT：役職ID
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
-- 2009/08/06 Ver1.10 障害0000510 add end by Yutaka.Kuboshima
--
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
-- 所属コード(新)、職位並び順コード(新)が変更された場合のみ管理者を取得する
-- Ver1.6  Add  2009/06/22  管理者取得処理を追加  T1_1389
--    -- 管理者取得
--    get_supervisor(
--      ir_masters_rec.person_id               -- IN ：従業員ID
--     ,ir_masters_rec.office_location_code    -- IN ：勤務地拠点コード(新)
--     ,ir_masters_rec.job_post_order          -- IN ：職位並順コード(新)
--     ,ir_masters_rec.hire_date               -- IN ：入社日
--     ,ir_masters_rec.supervisor_id           -- OUT：管理者ID
--     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
--     ,lv_retcode                             -- リターン・コード             --# 固定 #
--     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
--    );
---- End1.6
---- 2009/08/06 Ver1.10 障害0000794 add start by Yutaka.Kuboshima
--    -- 最上位の管理者の場合、管理者はNULLに設定します
--    IF (ir_masters_rec.employee_number = gv_supervisor) THEN
--      ir_masters_rec.supervisor_id := NULL;
--    END IF;
---- 2009/08/06 Ver1.10 障害0000794 add end by Yutaka.Kuboshima
--
    IF (ir_masters_rec.supervisor_kbn = gv_sts_yes) THEN
      -- 管理者取得
      get_supervisor(
        ir_masters_rec.person_id               -- IN ：従業員ID
-- 2009/12/11 Ver1.13 E_本稼動_00103 add start by Y.Kuboshima
--       ,ir_masters_rec.office_location_code    -- IN ：勤務地拠点コード(新)
       ,ir_masters_rec.location_code           -- IN ：所属コード(新)
-- 2009/12/11 Ver1.13 E_本稼動_00103 add end by Y.Kuboshima
       ,ir_masters_rec.job_post_order          -- IN ：職位並順コード(新)
       ,ir_masters_rec.hire_date               -- IN ：入社日
       ,ir_masters_rec.supervisor_id           -- OUT：管理者ID
       ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
       ,lv_retcode                             -- リターン・コード             --# 固定 #
       ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 最上位の管理者の場合、管理者はNULLに設定します
      IF (ir_masters_rec.employee_number = gv_supervisor) THEN
        ir_masters_rec.supervisor_id := NULL;
      END IF;
    END IF;
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify end by Y.Kuboshima
    --
    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE               =>  FALSE
        ,P_EFFECTIVE_DATE         =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE  =>  gv_upd_mode                              -- 'CORRECTION'
        ,P_ASSIGNMENT_ID          =>  ir_masters_rec.assignment_id             -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
        ,P_OBJECT_VERSION_NUMBER  =>  ir_masters_rec.paa_version               -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 管理者の割当をAPI -> 直UPDATEに変更
--        ,P_SUPERVISOR_ID          =>  ir_masters_rec.supervisor_id             -- 管理者
        ,P_SUPERVISOR_ID          =>  NULL                                     -- 管理者
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
        ,P_ASSIGNMENT_NUMBER      =>  ir_masters_rec.assignment_number         -- ｱｻｲﾝﾒﾝﾄ番号(ﾁｪｯｸ時取得)
-- Ver1.3
--        ,P_DEFAULT_CODE_COMB_ID   =>  gv_default                               -- ﾌﾟﾛﾌｧｲﾙｵﾌﾟｼｮﾝ.ﾃﾞﾌｫﾙﾄ費用勘定
        ,P_SET_OF_BOOKS_ID        =>  gn_set_of_book_id                        -- 会計帳簿ID
        ,P_DEFAULT_CODE_COMB_ID   =>  ir_masters_rec.default_code_comb_id      -- デフォルト費用勘定
-- End Ver1.3
        ,P_ASS_ATTRIBUTE1         =>  ir_masters_rec.change_code               -- 異動事由コード
        ,P_ASS_ATTRIBUTE2         =>  ir_masters_rec.announce_date             -- 発令日
        ,P_ASS_ATTRIBUTE3         =>  ir_masters_rec.office_location_code      -- 勤務地拠点コード（新）
        ,P_ASS_ATTRIBUTE4         =>  ir_masters_rec.office_location_code_old  -- 勤務地拠点コード（旧）
        ,P_ASS_ATTRIBUTE5         =>  ir_masters_rec.location_code             -- 拠点コード（新）
        ,P_ASS_ATTRIBUTE6         =>  ir_masters_rec.location_code_old         -- 拠点コード（旧）
        ,P_ASS_ATTRIBUTE7         =>  ir_masters_rec.job_system                -- 適用労働時間制コード（新）
        ,P_ASS_ATTRIBUTE8         =>  ir_masters_rec.job_system_name           -- 適用労働名（新）
        ,P_ASS_ATTRIBUTE9         =>  ir_masters_rec.job_system_old            -- 適用労働時間制コード（旧）
        ,P_ASS_ATTRIBUTE10        =>  ir_masters_rec.job_system_name_old       -- 適用労働名（旧）
        ,P_ASS_ATTRIBUTE11        =>  ir_masters_rec.job_post_order            -- 職位並順コード（新）
        ,P_ASS_ATTRIBUTE12        =>  ir_masters_rec.job_post_order_old        -- 職位並順コード（旧）
        ,P_ASS_ATTRIBUTE13        =>  ir_masters_rec.consent_division          -- 承認区分（新）
        ,P_ASS_ATTRIBUTE14        =>  ir_masters_rec.consent_division_old      -- 承認区分（旧）
        ,P_ASS_ATTRIBUTE15        =>  ir_masters_rec.agent_division            -- 代行区分（新）
        ,P_ASS_ATTRIBUTE16        =>  ir_masters_rec.agent_division_old        -- 代行区分（旧）
        ,P_CONCATENATED_SEGMENTS  =>  lv_concatenated_segments                 -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID =>  ln_soft_coding_keyflex_id                -- IN/OUT
        ,P_COMMENT_ID             =>  ln_comment_id                            -- OUT
        ,P_EFFECTIVE_START_DATE   =>  ir_masters_rec.effective_start_date      -- OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE     =>  ir_masters_rec.effective_end_date        -- OUT（登録期限年月日）
        ,P_NO_MANAGERS_WARNING    =>  lb_no_managers_warning                   -- OUT
        ,P_OTHER_MANAGER_WARNING  =>  lb_other_manager_warning                 -- OUT
      );
    --
    EXCEPTION
      WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
        lv_sqlerrm := SQLERRM;
--End Ver1.5
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                   );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
          P_VALIDATE                      =>  FALSE
        ,P_EFFECTIVE_DATE                =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                      -- 'CORRECTION'
        ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id     -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
-- 2009/08/06 Ver1.10 障害0000510 add start by Yutaka.Kuboshima
        ,P_JOB_ID                        =>  ln_job_id                        -- 役職ID
-- 2009/08/06 Ver1.10 障害0000510 add end by Yutaka.Kuboshima
        ,P_LOCATION_ID                   =>  ir_masters_rec.location_id       -- 事業所(勤務地拠点コード変更時）
        ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version       -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
        ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id       -- OUT
        ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id               -- OUT
        ,P_GROUP_NAME                    =>  lv_group_name                    -- OUT
        ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date --OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date -- OUT（登録期限年月日）
        ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning    -- OUT
        ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning         -- OUT
        ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning            -- OUT
        ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn          -- OUT
        ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn     -- OUT
      );
    EXCEPTION
      WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
        lv_sqlerrm := SQLERRM;
--End Ver1.5
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
-- 管理者の割当をAPI -> 直UPDATEに変更
    -- 管理者更新
    UPDATE per_all_assignments_f
    SET    supervisor_id        = ir_masters_rec.supervisor_id
    WHERE  assignment_id        = ir_masters_rec.assignment_id
    AND    effective_start_date = ir_masters_rec.effective_start_date
    AND    effective_end_date   = ir_masters_rec.effective_end_date;
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--Ver1.5 Add  2009/06/02
      --ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
--End Ver1.5
      ov_retcode := cv_status_error;
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
  END re_hire_ass_proc;
--
  /***********************************************************************************
   * Procedure Name   : insert_proc
   * Description      : 新規社員の登録を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE insert_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.登録対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    --
    lv_sqlerrm VARCHAR2(5000);  -- SQLERRM退避
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    --
    -- HR_EMPLOYEE_API.CREATE_EMPLOYEE
    lv_full_name                    per_all_people_f.full_name%TYPE;  -- フルネーム
    ln_per_comment_id               per_all_people_f.comment_id%TYPE;
    ln_assignment_sequence          per_all_assignments_f.assignment_sequence%TYPE;
    lb_name_combination_warning     BOOLEAN;
    lb_assign_payroll_warning       BOOLEAN;
    lb_orig_hire_warning            BOOLEAN;
    --
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments        VARCHAR2(200);
    ln_soft_coding_keyflex_id       per_all_assignments_f.soft_coding_keyflex_id%TYPE;
    ln_comment_id                   per_all_people_f.comment_id%TYPE;
    lb_no_managers_warning          BOOLEAN;
    --
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_people_group_id              per_all_assignments_f.people_group_id%TYPE;
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id%TYPE;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_other_manager_warning        BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(200);
    lb_tax_district_changed_warn    BOOLEAN;
-- 2009/08/06 Ver1.10 障害0000510,0000910 add start by Yutaka.Kuboshima
    ln_job_id                       per_all_assignments_f.job_id%TYPE; -- 役職ID
    lv_reference_range              per_all_people_f.attribute29%TYPE; -- 照会範囲
    --
    lv_purchasing_flag              VARCHAR2(1);                       -- 購買担当フラグ
    lv_shipping_flag                VARCHAR2(1);                       -- 出荷担当フラグ
-- 2009/08/06 Ver1.10 障害0000510,0000910 add end by Yutaka.Kuboshima
    --
    lv_api_name                     VARCHAR2(200); -- エラートークン用
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
    -- 新規登録社員
    --
-- 2009/08/06 Ver1.10 障害0000924 add start by Yutaka.Kuboshima
    -- 照会範囲の設定
    -- 所属コード(新)が財務経理部の場合
    IF (ir_masters_rec.location_code = gv_zaimu_bumon_cd) THEN
      -- 照会範囲に'T'を設定します
      lv_reference_range := gv_aff_dept_cd;
    ELSE
      -- 照会範囲に所属コード(新)を設定します
      lv_reference_range := ir_masters_rec.location_code;
    END IF;
-- 2009/08/06 Ver1.10 障害0000924 add end by Yutaka.Kuboshima
    -- 従業員マスタ(API)
    BEGIN
      --
      HR_EMPLOYEE_API.CREATE_EMPLOYEE(
         P_VALIDATE                     => FALSE
        ,P_HIRE_DATE                    => ir_masters_rec.hire_date              -- 入社年月日
        ,P_BUSINESS_GROUP_ID            => gv_bisiness_grp_id                    -- ビジネスグループID
        ,P_LAST_NAME                    => ir_masters_rec.last_name              -- カナ姓
        ,P_SEX                          => ir_masters_rec.sex                    -- 性別
        ,P_PERSON_TYPE_ID               => gv_person_type                        -- パーソンタイプ
        ,P_EMPLOYEE_NUMBER              => ir_masters_rec.employee_number        -- 社員番号
-- Ver1.3 Add  2009/04/16  「O:会社」を設定
        ,P_EXPENSE_CHECK_SEND_TO_ADDRES => cv_send_to_addres                     -- 郵便送付先(コード)
-- Ver1.3 End
        ,P_FIRST_NAME                   => ir_masters_rec.first_name             -- カナ名
-- Ver1.2  2009/04/03 Add コンテキストに SALES-OU を設定 
        ,P_ATTRIBUTE_CATEGORY           => gn_org_id                             -- ORG_ID
-- End
        ,P_ATTRIBUTE3                   => ir_masters_rec.employee_division      -- 従業員区分
        ,P_ATTRIBUTE7                   => ir_masters_rec.license_code           -- 資格コード（新）
        ,P_ATTRIBUTE8                   => ir_masters_rec.license_name           -- 資格名（新）
        ,P_ATTRIBUTE9                   => ir_masters_rec.license_code_old       -- 資格コード（旧）
        ,P_ATTRIBUTE10                  => ir_masters_rec.license_code_name_old  -- 資格名（旧）
        ,P_ATTRIBUTE11                  => ir_masters_rec.job_post               -- 職位コード（新）
        ,P_ATTRIBUTE12                  => ir_masters_rec.job_post_name          -- 職位名（新）
        ,P_ATTRIBUTE13                  => ir_masters_rec.job_post_old           -- 職位コード（旧）
        ,P_ATTRIBUTE14                  => ir_masters_rec.job_post_name_old      -- 職位名（旧）
        ,P_ATTRIBUTE15                  => ir_masters_rec.job_duty               -- 職務コード（新）
        ,P_ATTRIBUTE16                  => ir_masters_rec.job_duty_name          -- 職務名（新）
        ,P_ATTRIBUTE17                  => ir_masters_rec.job_duty_old           -- 職務コード（旧）
        ,P_ATTRIBUTE18                  => ir_masters_rec.job_duty_name_old      -- 職務名（旧）
        ,P_ATTRIBUTE19                  => ir_masters_rec.job_type               -- 職種コード（新）
        ,P_ATTRIBUTE20                  => ir_masters_rec.job_type_name          -- 職種名（新）
        ,P_ATTRIBUTE21                  => ir_masters_rec.job_type_old           -- 職種コード（旧）
        ,P_ATTRIBUTE22                  => ir_masters_rec.job_type_name_old      -- 職種名（旧）
        ,P_ATTRIBUTE28                  => ir_masters_rec.location_code          -- 起票部門(所属コード（新）)
-- 2009/08/06 Ver1.10 障害0000924 modify start by Yutaka.Kuboshima
--        ,P_ATTRIBUTE29                  => ir_masters_rec.location_code          -- 照会範囲(所属コード（新）)
        ,P_ATTRIBUTE29                  => lv_reference_range                    -- 照会範囲
-- 2009/08/06 Ver1.10 障害0000924 modify end by Yutaka.Kuboshima
        ,P_ATTRIBUTE30                  => ir_masters_rec.location_code          -- 承認者範囲(所属コード（新）)
        ,P_PER_INFORMATION_CATEGORY     => gv_info_category                      -- 'JP'
        ,P_PER_INFORMATION18            => ir_masters_rec.last_name_kanji        -- 漢字姓
        ,P_PER_INFORMATION19            => ir_masters_rec.first_name_kanji       -- 漢字名
        ,P_PERSON_ID                    => ir_masters_rec.person_id              -- OUT（従業員ID）
        ,P_ASSIGNMENT_ID                => ir_masters_rec.assignment_id          -- OUT（ｱｻｲﾝﾒﾝﾄID）
        ,P_PER_OBJECT_VERSION_NUMBER    => ir_masters_rec.pap_version            -- OUT（従業員ﾏｽﾀﾊﾞｰｼﾞｮﾝ番号）
        ,P_ASG_OBJECT_VERSION_NUMBER    => ir_masters_rec.paa_version            -- OUT（ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号）
        ,P_PER_EFFECTIVE_START_DATE     => ir_masters_rec.effective_start_date   -- OUT（登録年月日）
        ,P_PER_EFFECTIVE_END_DATE       => ir_masters_rec.effective_end_date     -- OUT（登録期限年月日）
        ,P_FULL_NAME                    => lv_full_name                          -- OUT（フルネーム）
        ,P_PER_COMMENT_ID               => ln_per_comment_id                     -- OUT
        ,P_ASSIGNMENT_SEQUENCE          => ln_assignment_sequence                -- OUT
        ,P_ASSIGNMENT_NUMBER            => ir_masters_rec.assignment_number      -- OUT（ｱｻｲﾝﾒﾝﾄ番号）
        ,P_NAME_COMBINATION_WARNING     => lb_name_combination_warning           -- OUT
        ,P_ASSIGN_PAYROLL_WARNING       => lb_assign_payroll_warning             -- OUT
        ,P_ORIG_HIRE_WARNING            => lb_orig_hire_warning                  -- OUT
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        lv_api_name := 'HR_EMPLOYEE_API.CREATE_EMPLOYEE';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
-- 2009/08/06 Ver1.10 障害0000510,0000910 add start by Yutaka.Kuboshima
    -- 事業所取得
    get_location(
      ir_masters_rec.location_code           -- IN : 所属コード(新)
     ,lv_purchasing_flag                     -- OUT: 購買担当フラグ
     ,lv_shipping_flag                       -- OUT: 出荷担当フラグ
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 役職取得
    get_job(
      ir_masters_rec.person_id               -- IN ：従業員ID
     ,ir_masters_rec.location_code           -- IN ：所属コード(新)
     ,ir_masters_rec.job_post_order          -- IN ：職位並順コード(新)
     ,ir_masters_rec.hire_date               -- IN ：入社日
     ,lv_purchasing_flag                     -- IN : 購買担当フラグ
     ,ln_job_id                              -- OUT：役職ID
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
-- 2009/08/06 Ver1.10 障害0000510,0000910 add end by Yutaka.Kuboshima
--
-- Ver1.6  Add  2009/06/22  管理者取得処理を追加  T1_1389
    -- 管理者取得
    get_supervisor(
      ir_masters_rec.person_id               -- IN ：従業員ID
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
--     ,ir_masters_rec.office_location_code    -- IN ：勤務地拠点コード(新)
     ,ir_masters_rec.location_code           -- IN ：所属コード(新)
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify end by Y.Kuboshima
     ,ir_masters_rec.job_post_order          -- IN ：職位並順コード(新)
     ,ir_masters_rec.hire_date               -- IN ：入社日
     ,ir_masters_rec.supervisor_id           -- OUT：管理者ID
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
-- End1.6
-- 2009/08/06 Ver1.10 障害0000794 add start by Yutaka.Kuboshima
    -- 最上位の管理者の場合、管理者はNULLに設定します
    IF (ir_masters_rec.employee_number = gv_supervisor) THEN
      ir_masters_rec.supervisor_id := NULL;
    END IF;
-- 2009/08/06 Ver1.10 障害0000794 add end by Yutaka.Kuboshima
    --
    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE               => FALSE
        ,P_EFFECTIVE_DATE         => SYSDATE
        ,P_DATETRACK_UPDATE_MODE  => gv_upd_mode                             -- 'CORRECTION'
        ,P_ASSIGNMENT_ID          => ir_masters_rec.assignment_id            -- HR_EMPLOYEE_API.CREATE_EMPLOYEEの出力項目のP_ASSIGNMENT_ID
        ,P_OBJECT_VERSION_NUMBER  => ir_masters_rec.paa_version              -- IN/OUT(ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号)
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 管理者の割当をAPI -> 直UPDATEに変更
--        ,P_SUPERVISOR_ID          => ir_masters_rec.supervisor_id            -- 管理者
        ,P_SUPERVISOR_ID          => NULL                                    -- 管理者
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
        ,P_ASSIGNMENT_NUMBER      => ir_masters_rec.assignment_number        -- HR_EMPLOYEE_API.CREATE_EMPLOYEEの出力項目のP_ASSIGNMENT_NUMBER
-- Ver1.3
--        ,P_DEFAULT_CODE_COMB_ID   => gv_default                              -- ﾌﾟﾛﾌｧｲﾙｵﾌﾟｼｮﾝ.ﾃﾞﾌｫﾙﾄ費用勘定
        ,P_SET_OF_BOOKS_ID        => gn_set_of_book_id                       -- 会計帳簿ID
        ,P_DEFAULT_CODE_COMB_ID   => ir_masters_rec.default_code_comb_id     -- デフォルト費用勘定
-- End Ver1.3
        ,P_ASS_ATTRIBUTE1         => ir_masters_rec.change_code              -- 異動事由コード
        ,P_ASS_ATTRIBUTE2         => ir_masters_rec.announce_date            -- 発令日
        ,P_ASS_ATTRIBUTE3         => ir_masters_rec.office_location_code     -- 勤務地拠点コード（新）
        ,P_ASS_ATTRIBUTE4         => ir_masters_rec.office_location_code_old -- 勤務地拠点コード（旧）
        ,P_ASS_ATTRIBUTE5         => ir_masters_rec.location_code            -- 拠点コード（新）
        ,P_ASS_ATTRIBUTE6         => ir_masters_rec.location_code_old        -- 拠点コード（旧）
        ,P_ASS_ATTRIBUTE7         => ir_masters_rec.job_system               -- 適用労働時間制コード（新）
        ,P_ASS_ATTRIBUTE8         => ir_masters_rec.job_system_name          -- 適用労働名（新）
        ,P_ASS_ATTRIBUTE9         => ir_masters_rec.job_system_old           -- 適用労働時間制コード（旧）
        ,P_ASS_ATTRIBUTE10        => ir_masters_rec.job_system_name_old      -- 適用労働名（旧）
        ,P_ASS_ATTRIBUTE11        => ir_masters_rec.job_post_order           -- 職位並順コード（新）
        ,P_ASS_ATTRIBUTE12        => ir_masters_rec.job_post_order_old       -- 職位並順コード（旧）
        ,P_ASS_ATTRIBUTE13        => ir_masters_rec.consent_division         -- 承認区分（新）
        ,P_ASS_ATTRIBUTE14        => ir_masters_rec.consent_division_old     -- 承認区分（旧）
        ,P_ASS_ATTRIBUTE15        => ir_masters_rec.agent_division           -- 代行区分（新）
        ,P_ASS_ATTRIBUTE16        => ir_masters_rec.agent_division_old       -- 代行区分（旧）
        ,P_ASS_ATTRIBUTE17        => NULL                                    -- 差分連携用日付（自販機）
        ,P_ASS_ATTRIBUTE18        => NULL                                    -- 差分連携用日付（帳票）
        ,P_CONCATENATED_SEGMENTS  => lv_concatenated_segments                -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID => ln_soft_coding_keyflex_id               -- IN/OUT
        ,P_COMMENT_ID             => ln_comment_id                           -- OUT
        ,P_EFFECTIVE_START_DATE   => ir_masters_rec.effective_start_date     -- OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE     => ir_masters_rec.effective_end_date       -- OUT（登録期限年月日）
        ,P_NO_MANAGERS_WARNING    => lb_no_managers_warning                  -- OUT
        ,P_OTHER_MANAGER_WARNING  => lb_other_manager_warning                -- OUT
        );
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
    -- アサインメントマスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
         P_VALIDATE                      =>  FALSE
        ,P_EFFECTIVE_DATE                =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                        -- 'CORRECTION'
        ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id       -- ｱｻｲﾝﾒﾝﾄID(ﾁｪｯｸ時取得)
-- 2009/08/06 Ver1.10 障害0000510 add start by Yutaka.Kuboshima
        ,P_JOB_ID                        =>  ln_job_id                          -- 役職ID
-- 2009/08/06 Ver1.10 障害0000510 add start by Yutaka.Kuboshima
        ,P_LOCATION_ID                   =>  ir_masters_rec.location_id         -- 事業所(勤務地拠点コードから求めたID）
        ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version         -- ｱｻｲﾝﾒﾝﾄﾏｽﾀﾊﾞｰｼﾞｮﾝ番号(IN/OUT)
        ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id         -- OUT
        ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id                 -- OUT
        ,P_GROUP_NAME                    =>  lv_group_name                      -- OUT
        ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date --OUT（登録年月日）
        ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date  -- OUT（登録期限年月日）
        ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning      -- OUT
        ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning           -- OUT
        ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning              -- OUT
        ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn            -- OUT
        ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn       -- OUT
      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
          lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
          RAISE global_process_expt;
    END;
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
-- 管理者の割当をAPI -> 直UPDATEに変更
    -- 管理者更新
    UPDATE per_all_assignments_f
    SET    supervisor_id        = ir_masters_rec.supervisor_id
    WHERE  assignment_id        = ir_masters_rec.assignment_id
    AND    effective_start_date = ir_masters_rec.effective_start_date
    AND    effective_end_date   = ir_masters_rec.effective_end_date;
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
    --
    -- 退職処理 (退職区分=’Y’）** 新規登録社員データに退職年月日が設定されている場合 **
    IF ir_masters_rec.retire_kbn = gv_sts_yes THEN
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- 退職日
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- ユーザマスタ(API)
    -- 新規登録データで退職年月日が設定されている場合にも対応
    BEGIN
      ir_masters_rec.user_id := FND_USER_PKG.CREATEUSERID(
                                X_USER_NAME             => ir_masters_rec.employee_number -- 社員番号
                               ,X_OWNER                 => gv_owner --'CUST'
                               ,X_UNENCRYPTED_PASSWORD  => gv_password -- ﾌﾟﾛﾌｧｲﾙ
                               ,X_START_DATE            => ir_masters_rec.hire_date -- 入社年月日
                               ,X_END_DATE              => ir_masters_rec.actual_termination_date -- 退職年月日
                               ,X_DESCRIPTION           => ir_masters_rec.last_name -- カナ姓
                               ,X_EMPLOYEE_ID           => ir_masters_rec.person_id --HR_EMPLOYEE_API.CREATE_EMPLOYEEの出力項目のP_PERSON_ID
                               );
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        lv_api_name := 'FND_USER_PKG.CREATEUSERID';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
        lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
        RAISE global_process_expt;
    END;
    --
-- 2009/08/06 Ver1.10 障害0000910 add start by Yutaka.Kuboshima
    -- 購買担当マスタ登録
    po_agents_proc(
      ir_masters_rec       -- 対象従業員情報
     ,lv_purchasing_flag   -- 購買担当フラグ
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- 出荷ロールマスタ登録
    wsh_grants_proc(
      ir_masters_rec       -- 対象従業員情報
     ,lv_shipping_flag     -- 出荷担当フラグ
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- 2009/08/06 Ver1.10 障害0000910 add end by Yutaka.Kuboshima
-- Ver1.4 Add  2009/05/21  セキュリティ属性登録処理をコール  T1_0966
    ins_user_sec(
      ir_masters_rec       -- 対象従業員情報
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- End Ver1.4
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : update_proc
   * Description      : 既存社員の更新を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE update_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.異動対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    --
    lv_sqlerrm VARCHAR2(5000);  -- SQLERRM退避
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    --
    lv_api_name                 VARCHAR2(200); -- エラートークン用
-- 2009/08/06 Ver1.10 障害0000510,0000910 add start by Yutaka.Kuboshima
    lv_purchasing_flag          VARCHAR2(1);   -- 購買担当フラグ
    lv_shipping_flag            VARCHAR2(1);   -- 出荷担当フラグ
-- 2009/08/06 Ver1.10 障害0000510,0000910 add end by Yutaka.Kuboshima
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
    ld_actual_termination_date  DATE;          -- 退職日
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
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
    -- 既存社員の入社年月日の変更(入社日連携区分 = 'Y'）
      -- 1.入社年月日を退職年月日として設定し、退職処理を行う。
      -- 2.新入社年月日で再雇用処理を行う。
    IF ir_masters_rec.ymd_kbn = gv_sts_yes THEN
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
      -- 入社年月日 - 1を退職日として設定
      ld_actual_termination_date := ir_masters_rec.hire_date - 1;
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
      -- 退職処理
      retire_proc(
        ir_masters_rec
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
--       ,ir_masters_rec.hire_date_old   -- 退職日に既存入社日セット
       ,ld_actual_termination_date       -- 退職日に既存入社日をセット
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      --
      -- 再雇用処理
      re_hire_proc(
        ir_masters_rec
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
--       ,ir_masters_rec.hire_date_old        -- 退職日に既存入社日をセット
       ,ld_actual_termination_date       -- 退職日に既存入社日をセット
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 既存社員の情報変更(連携区分 = 'Y'）
    IF ir_masters_rec.proc_kbn = gv_sts_yes THEN
      -- 異動処理
      changes_proc(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    -- 既存社員の情報変更なしの場合、再雇用情報引継ぎ処理を行う (連携区分 = NULL,入社日変更区分 = 'Y')
       -- 退職処理だけのデータは更新は行わない
    ELSIF ir_masters_rec.ymd_kbn = gv_sts_yes THEN
      -- 再雇用(アサインメントマスタ)処理
      re_hire_ass_proc(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 退職年月日が設定されている場合(退職区分=’Y’）
    IF ir_masters_rec.retire_kbn = gv_sts_yes THEN
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- 退職日をセット
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify start by Y.Kuboshima
-- 職責・管理者変更区分が'N'の場合も対象とする
--    IF  (ir_masters_rec.resp_kbn = gv_sts_yes)
    IF  (ir_masters_rec.resp_kbn IN (gv_sts_yes, gv_sts_no))
-- 2009/12/11 Ver1.13 E_本稼動_00103 modify end by Y.Kuboshima
     OR (ir_masters_rec.retire_kbn = gv_sts_yes) THEN  --退職者
      --ユーザ職責マスタの無効化
      delete_resp_all(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      --
      -- ユーザ職責マスタ更新
      IF (ir_masters_rec.resp_kbn = gv_sts_yes) THEN
      --ユーザ職責マスタの設定
        update_resp_all(
          ir_masters_rec
         ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,lv_retcode  -- リターン・コード             --# 固定 #
         ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
    --
    -- 退職年月日が設定されていない場合(退職区分=NULL）END_DATEをNULLに設定
    -- (退職されている場合は、retire_procで更新済み)
    IF (ir_masters_rec.retire_kbn IS NULL) THEN
      -- ユーザマスタ(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
          X_USER_NAME             =>  ir_masters_rec.employee_number  -- 社員番号
         ,X_OWNER                 =>  gv_owner                        --'CUST'
         ,X_START_DATE            =>  ir_masters_rec.hire_date        -- 入社年月日
         ,X_END_DATE              =>  FND_USER_PKG.NULL_DATE          -- 有効日（NULL）
        );
      --
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
          lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
          RAISE global_process_expt;
      END;
    END IF;
    --
-- 2009/08/06 Ver1.10 障害0000910 add start by Yutaka.Kuboshima
    -- 事業所取得
    get_location(
      ir_masters_rec.location_code           -- IN : 所属コード(新)
     ,lv_purchasing_flag                     -- OUT: 購買担当フラグ
     ,lv_shipping_flag                       -- OUT: 出荷担当フラグ
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 購買担当マスタ登録
    po_agents_proc(
      ir_masters_rec       -- 対象従業員情報
     ,lv_purchasing_flag   -- 購買担当フラグ
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- 出荷ロールマスタ登録
    wsh_grants_proc(
      ir_masters_rec       -- 対象従業員情報
     ,lv_shipping_flag     -- 出荷担当フラグ
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- 2009/08/06 Ver1.10 障害0000910 add end by Yutaka.Kuboshima
-- Ver1.4 Add  2009/05/21  セキュリティ属性登録処理をコール  T1_0966
    ins_user_sec(
      ir_masters_rec       -- 対象従業員情報
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- End Ver1.4
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
      ov_retcode := cv_status_error;
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
  END update_proc;
--
  /***********************************************************************************
   * Procedure Name   : delete_proc
   * Description      : 退職者の処理を行うプロシージャ
   ***********************************************************************************/
  PROCEDURE delete_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.退職対象データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_proc'; -- プログラム名
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
    -- *** ローカル・カーソル ***
    --
    -- *** ローカル・レコード ***
    lv_api_name        VARCHAR2(200);   -- エラートークン用
--Ver1.5 Add  2009/06/02
    lv_sqlerrm         VARCHAR2(5000);  -- SQLERRM退避
--End Ver1.5
-- 2009/08/06 Ver1.10 障害0000510,0000910 add start by Yutaka.Kuboshima
    lv_purchasing_flag VARCHAR2(1);   -- 購買担当フラグ
    lv_shipping_flag   VARCHAR2(1);   -- 出荷担当フラグ
-- 2009/08/06 Ver1.10 障害0000510,0000910 add end by Yutaka.Kuboshima

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
    -- 再雇用処理
    re_hire_proc(
      ir_masters_rec
     ,ir_masters_rec.effective_end_date   -- 退職日に既存退職日セット
     ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,lv_retcode  -- リターン・コード             --# 固定 #
     ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- 既存社員の情報変更(連携区分 = 'Y'）
    IF (ir_masters_rec.proc_kbn = gv_sts_yes) THEN
      -- 異動処理
      changes_proc(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    -- 既存社員の情報変更なしの場合、再雇用情報引継ぎ処理を行う(連携区分 = NULL）
    ELSE
      -- 再雇用(アサインメントマスタ)処理
      re_hire_ass_proc(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    IF (ir_masters_rec.retire_kbn = gv_sts_yes) THEN
      -- 退職処理
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- 退職日セット
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    --
    END IF;
    --
    -- ユーザ職責マスタ(API)
    IF  (ir_masters_rec.resp_kbn = gv_sts_yes) THEN -- 退職者は職責未設定(delete_resp_allは不要)
      -- ユーザ職責マスタ更新
      update_resp_all(
        ir_masters_rec
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 退職年月日が設定されていない場合(退職区分=NULL）END_DATEをNULLに設定
    -- (退職されている場合は、retire_procで更新済み)
    IF (ir_masters_rec.retire_kbn IS NULL) THEN
      -- ユーザマスタ(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
          X_USER_NAME             =>  ir_masters_rec.employee_number  -- 社員番号
         ,X_OWNER                 =>  gv_owner                        --'CUST'
         ,X_START_DATE            =>  ir_masters_rec.hire_date        -- 入社年月日
         ,X_END_DATE              =>  FND_USER_PKG.NULL_DATE          -- 有効日（NULL）
        );
      --
      EXCEPTION
        WHEN OTHERS THEN
--Ver1.5 Add  2009/06/02
          lv_sqlerrm := SQLERRM;
--End Ver1.5
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '社員番号'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
--Ver1.5 Add 2009/06/02
          lv_errmsg := lv_errmsg||lv_sqlerrm;
--End Ver1.5
          RAISE global_process_expt;
      END;
    END IF;
    --
-- 2009/08/06 Ver1.10 障害0000910 add start by Yutaka.Kuboshima
    -- 事業所取得
    get_location(
      ir_masters_rec.location_code           -- IN : 所属コード(新)
     ,lv_purchasing_flag                     -- OUT: 購買担当フラグ
     ,lv_shipping_flag                       -- OUT: 出荷担当フラグ
     ,lv_errbuf                              -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                             -- リターン・コード             --# 固定 #
     ,lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 購買担当マスタ登録
    po_agents_proc(
      ir_masters_rec       -- 対象従業員情報
     ,lv_purchasing_flag   -- 購買担当フラグ
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- 出荷ロールマスタ登録
    wsh_grants_proc(
      ir_masters_rec       -- 対象従業員情報
     ,lv_shipping_flag     -- 出荷担当フラグ
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- 2009/08/06 Ver1.10 障害0000910 add end by Yutaka.Kuboshima
-- Ver1.4 Add  2009/05/29  セキュリティ属性登録処理をコール  T1_0966
    ins_user_sec(
      ir_masters_rec       -- 対象従業員情報
     ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- End Ver1.4
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** API関数エラー時(関数使用直後) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
--Ver1.5 Add  2009/06/02
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||lv_sqlerrm,1,5000);
--End Ver1.5
      ov_retcode := cv_status_error;
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
  END delete_proc;
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    lv_file_chk   BOOLEAN;   --存在チェック結果
    lv_file_size  NUMBER;    --ファイルサイズ
    lv_block_size NUMBER;    --ブロックサイズ
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
    -- ===============================
    -- コンカレントメッセージ出力
    -- ===============================
    --入力パラメータなしメッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_input_no_msg
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- ===============================
    -- プロファイル取得
    -- ===============================
    init_get_profile(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- Ver1.3 Add  2009/04/16  会計帳簿ＩＤ取得、ＣＣＩＤ取得用（fnd_flex_ext.get_combination_id）
    -- ===============================
    -- 会計帳簿ＩＤ その他取得
    -- ===============================
    SELECT  gsob.chart_of_accounts_id    -- 勘定科目体系ＩＤ
           ,fifsv.id_flex_code           -- キーフレックスコード
           ,gsob.set_of_books_id         -- 会計帳簿ＩＤ
    INTO    gn_chart_of_acct_id
           ,gv_id_flex_code
           ,gn_set_of_book_id
    FROM    fnd_id_flex_structures_vl    fifsv
           ,gl_sets_of_books             gsob
    WHERE   gsob.name            = fnd_profile.value( cv_prf_bks_name )
    AND     fifsv.id_flex_num    = gsob.chart_of_accounts_id;
    --
-- End Ver1.3
    --
    -- ===============================
    -- CSVファイル存在チェック
    -- ===============================
    UTL_FILE.FGETATTR(gv_directory,
                      gv_file_name,
                      lv_file_chk,
                      lv_file_size,
                      lv_block_size
    );
    -- ファイルが存在しない場合エラー
    IF (NOT lv_file_chk) THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_csv_file_err
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    -- 職責自動割当ワーク削除処理
    -- ===============================
    DELETE xxcmm_wk_people_resp;
    --
    -- ===============================
    -- 業務日付の取得
    -- ===============================
    cd_process_date := xxccp_common_pkg2.get_process_date;   -- 業務日付 --# 固定 #
    --
    IF (cd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_process_date_err
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    cc_process_date := TO_CHAR(cd_process_date,'YYYYMMDD');
    --
    -- ===============================
    -- パーソンタイプの取得
    -- ===============================
    -- 従業員
    get_person_type(
       gv_user_person_type
      ,gv_person_type
      ,gv_bisiness_grp_id
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- パーソンタイプID取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- 退職者
    get_person_type(
       gv_user_person_type_ex
      ,gv_person_type_ex
      ,gv_bisiness_grp_id_ex
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- パーソンタイプID取得エラー
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- Ver1.4 Add  2009/05/21  初期処理を追加  T1_0966
    -- セキュリティ属性名を設定
    g_sec_att_code_tab( 1 ) := cv_att_code_ihp;    -- ICX_HR_PERSON_ID
    g_sec_att_code_tab( 2 ) := cv_att_code_tp;     -- TO_PERSON_ID
    --
    -- 標準データなのでNO_DATA_FOUNDは想定しない
    -- アプリケーションIDの取得【ICX：Self-Service Web Applications】
    SELECT    application_id
    INTO      gn_appl_id_icx
    FROM      fnd_application_vl
    WHERE     application_short_name = cv_appl_short_nm_icx;
-- End Ver1.4
--
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX add start by Yutaka.Kuboshima
    -- ===============================
    -- セキュリティグループIDの取得
    -- ※職責マスタの更新で使用
    -- ===============================
    gn_security_group_id := FND_GLOBAL.SECURITY_GROUP_ID;
-- 2010/03/02 Ver1.17 E_本稼動_XXXXX add end by Yutaka.Kuboshima
    --
    -- ===============================
    -- 社員インタフェース０件チェック
    -- ===============================
    BEGIN
      SELECT 1
      INTO   gn_target_cnt
      FROM   xxcmm_in_people_if xip     -- 社員インタフェース
      WHERE  ROWNUM = 1;
    EXCEPTION
      -- データなしの場合エラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_data_no_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      --
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    -- ===============================
    -- ファイルロック処理
    -- ===============================
    init_file_lock(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    -- 初期設定処理
    -- ===============================
    --
    -- WHOカラムの取得
    gn_created_by             := FND_GLOBAL.USER_ID;           -- 作成者
    gd_creation_date          := SYSDATE;                      -- 作成日
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- 最終更新者
    gd_last_update_date       := SYSDATE;                      -- 最終更新日
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- プログラムアプリケーションID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    gd_program_update_date    := SYSDATE;                      -- プログラム更新日
    --
--Ver1.8 Mod  2009/07/06  0000412 START
    -- INSERT処理(社員データ取込用_部門階層一時ワーク)
-- 2009/08/06 Ver1.10 障害0000869 delete start by Yutaka.Kuboshima
--    INSERT INTO xxcmm_wk_hiera_dept
--      SELECT  xhd.cur_dpt_cd,        -- 最下層部門コード
--              xhd.dpt1_cd,           -- １階層目部門コード
--              xhd.dpt2_cd,           -- ２階層目部門コード
--              xhd.dpt3_cd,           -- ３階層目部門コード
--              xhd.dpt4_cd,           -- ４階層目部門コード
--              xhd.dpt5_cd,           -- ５階層目部門コード
--              xhd.dpt6_cd,           -- ６階層目部門コード
--              '1'                    -- 処理区分(1：全部門、2：部門)
--      FROM    xxcmm_hierarchy_dept_all_v xhd
--    ;
-- 2009/08/06 Ver1.10 障害0000869 delete end by Yutaka.Kuboshima
    INSERT INTO xxcmm_wk_hiera_dept
      SELECT  xhd.cur_dpt_cd,        -- 最下層部門コード
              xhd.dpt1_cd,           -- １階層目部門コード
              xhd.dpt2_cd,           -- ２階層目部門コード
              xhd.dpt3_cd,           -- ３階層目部門コード
              xhd.dpt4_cd,           -- ４階層目部門コード
              xhd.dpt5_cd,           -- ５階層目部門コード
              xhd.dpt6_cd,           -- ６階層目部門コード
              '2'                    -- 処理区分(1：全部門、2：部門)
      FROM    xxcmm_hierarchy_dept_v xhd
    ;
--Ver1.8 Mod  2009/07/06  0000412 END
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
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
  END init;
--
  /***********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル変数宣言部 START   ########################
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
-- Ver1.3 Del 2009/04/16  使用していないため削除
--    lr_masters_rec       masters_rec;       -- 処理対象データ格納レコード
-- Ver1.3 End
--
-- Ver1.3 Add 2009/04/16  重複チェックのため追加
    l_people_if_rec      masters_rec;       -- 処理対象データ格納レコード
    l_if_clear_rec       masters_rec;       -- 処理対象データクリア用レコード
-- Ver1.3 End
    --
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 各従業員データを登録、更新、削除に分けると、
-- 正しい割当順序にならないので管理者または役職が正しく割当たらないため修正
--    lt_insert_masters    masters_tbl;       -- 各マスタへ登録するデータ
--    lt_update_masters    masters_tbl;       -- 各マスタへ更新するデータ
--    lt_delete_masters    masters_tbl;       -- 各マスタへ削除するデータ
    lt_proc_masters      masters_tbl;       -- 各マスタへ連携するデータ
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
    --
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 各従業員データを登録、更新、削除に分けると、
-- 正しい割当順序にならないので管理者または役職が正しく割当たらないため修正
--    ln_insert_cnt        NUMBER;            -- 登録件数
--    ln_update_cnt        NUMBER;            -- 更新件数
--    ln_delete_cnt        NUMBER;            -- 削除件数
    ln_proc_cnt          NUMBER;            -- 連携件数
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
    ln_exec_cnt          NUMBER;
    ln_log_cnt           NUMBER;
    lc_flg               CHAR(1) := ' ';    -- 重複データ用フラグ
    lb_retcd             BOOLEAN;           -- 検索結果
-- Ver1.3 Add 2009/04/16  重複チェックのため追加
    ln_exist_cnt         NUMBER;
    ln_wk_emp_num        xxcmm_in_people_if.employee_number%TYPE;
-- End Ver1.3
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --
    -- 社員取込インターフェース
    CURSOR in_if_cur
    IS
-- Ver1.3 Mod 2009/04/16  重複チェックのため抽出項目にROWIDを追加
--      SELECT xip.employee_number             employee_number,
      SELECT xip.ROWID                       xip_rowid,
             xip.employee_number             employee_number,
-- End Ver1.3
             xip.hire_date                   hire_date,
             xip.actual_termination_date     actual_termination_date,
             xip.last_name_kanji             last_name_kanji,
             xip.first_name_kanji            first_name_kanji,
             xip.last_name                   last_name,
             xip.first_name                  first_name,
             UPPER( xip.sex )                sex,
             NVL(xip.employee_division,'1')  employee_division,
             xip.location_code               location_code,
             xip.change_code                 change_code,
             xip.announce_date               announce_date,
             xip.office_location_code        office_location_code,
             xip.license_code                license_code,
             xip.license_name                license_name,
             xip.job_post                    job_post,
             xip.job_post_name               job_post_name,
             xip.job_duty                    job_duty,
             xip.job_duty_name               job_duty_name,
             xip.job_type                    job_type,
             xip.job_type_name               job_type_name,
             xip.job_system                  job_system,
             xip.job_system_name             job_system_name,
             xip.job_post_order              job_post_order,
             xip.consent_division            consent_division,
             xip.agent_division              agent_division,
             xip.office_location_code_old    office_location_code_old,
             xip.location_code_old           location_code_old,
             xip.license_code_old            license_code_old,
             xip.license_code_name_old       license_code_name_old,
             xip.job_post_old                job_post_old,
             xip.job_post_name_old           job_post_name_old,
             xip.job_duty_old                job_duty_old,
             xip.job_duty_name_old           job_duty_name_old,
             xip.job_type_old                job_type_old,
             xip.job_type_name_old           job_type_name_old,
             xip.job_system_old              job_system_old,
             xip.job_system_name_old         job_system_name_old,
             xip.job_post_order_old          job_post_order_old,
             xip.consent_division_old        consent_division_old,
             xip.agent_division_old          agent_division_old
      FROM   xxcmm_in_people_if xip
-- 2009/09/04 Ver1.11 modify start by Yutaka.Kuboshima
--      ORDER BY xip.employee_number;
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 退職者を始めに割当てるように修正
--      ORDER BY xip.job_post_order
      ORDER BY xip.actual_termination_date
              ,xip.job_post_order
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
              ,xip.hire_date;
-- 2009/09/04 Ver1.11 modify end by Yutaka.Kuboshima
    --
    -- 職責自動割当ワーク
    CURSOR wk_pr2_cur(lv_emp_kbn IN VARCHAR2)
    IS
      SELECT xwpr.employee_number,
             xwpr.responsibility_id,
             xwpr.user_id,
             xwpr.employee_kbn,
             xwpr.responsibility_key,
             xwpr.application_short_name,
             xwpr.start_date,
             xwpr.end_date
      FROM   xxcmm_wk_people_resp xwpr
      WHERE  xwpr.employee_kbn = lv_emp_kbn
      ORDER BY xwpr.employee_number,xwpr.responsibility_id;
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
    gn_target_cnt := 0; -- 処理件数
    gn_normal_cnt := 0; -- 成功件数
    gn_warn_cnt   := 0; -- 警告件数
    gn_error_cnt  := 0; -- エラー件数
    gn_skip_cnt   := 0; -- スキップ件数
    gn_rep_n_cnt  := 0; -- レポート件
    gn_rep_w_cnt  := 0; -- レポート件
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 各従業員データを登録、更新、削除に分けると、
-- 正しい割当順序にならないので管理者または役職が正しく割当たらないため修正
--    ln_insert_cnt := 0;
--    ln_update_cnt := 0;
--    ln_delete_cnt := 0;
    ln_proc_cnt   := 0; -- 連携件数
    gv_retcode    := cv_status_normal; -- 処理結果
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
--
-- Ver1.3 Del 2009/04/16  不要ないため削除
--    gn_if         := 0; -- 社員インターフェース件数
-- End Ver1.3
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- ===============================
    -- 初期処理(A-2)
    -- ===============================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
    --
-- Ver1.3 Del 2009/04/16  意味不明なため削除
--                        おそらく、重複チェックをするために１件目を飛ばしていると思われるが、
--                        対象データがあやふやで正常に制御されていないと思われる。
--    -- ===============================
--    -- 社員インタフェース情報取得(A-3)
--    -- ===============================
----
--    -- IF件数の初期化
--    gn_target_cnt := 0;
--
--    <<in_if_loop>>
--    FOR in_if_rec IN in_if_cur LOOP
--      -- ステータスの初期化
--      gt_mst_tbl(gn_if).proc_flg := NULL;   -- 更新区分
--      gt_mst_tbl(gn_if).proc_kbn := NULL;   -- 連携区分
--      gt_mst_tbl(gn_if).emp_kbn := NULL;    -- 社員状態
--      gt_mst_tbl(gn_if).ymd_kbn := NULL;    -- 入社日連携区分
--      gt_mst_tbl(gn_if).retire_kbn := NULL; -- 退職区分
--      gt_mst_tbl(gn_if).resp_kbn := NULL;   -- 職責・管理者変更区分
--
--      -- 退避したレコードと次レコードとの比較後に、退避レコードを登録更新エリアに格納(社員番号重複データは更新しない為)
--      IF (gn_target_cnt = 0) THEN
--        NULL;
--      ELSE
--        IF (gt_mst_tbl(gn_if).employee_number <> in_if_rec.employee_number) THEN
--          IF (lc_flg <> gv_flg_on) THEN
--            NULL;  --処理続ける
--          ELSE
--            lc_flg := ' ';
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_short_name
--                        ,iv_name         => cv_data_check_err
--                        ,iv_token_name1  => cv_tkn_ng_user
--                        ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
--                        ,iv_token_name2  => cv_tkn_ng_err
--                        ,iv_token_value2 => cv_employee_err_nm  -- '社員番号重複'
--                       );
--            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--          END IF;
--        ELSE
--          lc_flg := gv_flg_on;
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name
--                      ,iv_name         => cv_data_check_err
--                      ,iv_token_name1  => cv_tkn_ng_user
--                      ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
--                      ,iv_token_name2  => cv_tkn_ng_err
--                      ,iv_token_value2 => cv_employee_err_nm  -- '社員番号重複'
--                     );
--          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--        END IF;
--      END IF;
--
--      IF (gt_mst_tbl(gn_if).proc_flg IS NULL) AND (gn_target_cnt > 0) THEN
--        -- ===============================
--        -- データ妥当性チェック処理(A-4)
--        -- ===============================
--        in_if_check(
--           gt_mst_tbl(gn_if)  -- 待避エリア
--          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--          ,lv_retcode  -- リターン・コード             --# 固定 #
--          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--        );
----
--        --エラー処理（処理中止）
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_api_expt;
--        --警告処理（警告データ更新不可・次データ処理継続）
--        ELSIF (lv_retcode = cv_status_warn) THEN
--          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--        --正常処理：異動なし社員データ（SKIP）
--        ELSIF ((gt_mst_tbl(gn_if).proc_kbn IS NULL)         -- 連携なし
--          AND (gt_mst_tbl(gn_if).ymd_kbn IS NULL)           -- 入社日変更なし
--          AND (gt_mst_tbl(gn_if).retire_kbn IS NULL)) THEN  -- 退職処理なし
--          gt_mst_tbl(gn_if).proc_flg := gv_sts_thru; -- 変更なし
----
--        --正常処理：新規社員データ（登録）
--        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_new) THEN  -- 新規社員
--          -- =================================
--          -- 社員データ登録分チェック処理(A-5)
--          -- =================================
--          check_insert(
--             gt_mst_tbl(gn_if)  -- 待避エリア
--            ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--            ,lv_retcode  -- リターン・コード             --# 固定 #
--            ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--          );
--          --エラー処理（処理中止）
--          IF (lv_retcode = cv_status_error) THEN
--            RAISE global_api_expt;
--          --警告処理（警告データ更新不可・次データ処理継続）
--          ELSIF (lv_retcode = cv_status_warn) THEN
--            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--          --正常処理：新規社員データ（登録）
--          ELSE
--            -- =================================
--            -- 社員データ登録情報格納処理(A-8)
--            -- =================================
--            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
--            ln_insert_cnt := ln_insert_cnt + 1;
--            lt_insert_masters(ln_insert_cnt) := gt_mst_tbl(gn_if);
--          END IF;
----
--        --正常処理：既存社員異動データ・退職社員再雇用データ（更新）
--        ELSE --(emp_kbn 'U'：既存社員、'D'：退職者)
--          -- =================================
--          -- 社員データ更新分チェック処理(A-6)
--          -- =================================
--          check_update(
--             gt_mst_tbl(gn_if)  -- 待避エリア
--            ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--            ,lv_retcode  -- リターン・コード             --# 固定 #
--            ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--          );
--          --エラー処理（処理中止）
--          IF (lv_retcode = cv_status_error) THEN
--            RAISE global_api_expt;
--          --警告処理（警告データ更新不可・次データ処理継続）
--          ELSIF (lv_retcode = cv_status_warn) THEN
--            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--          --正常処理：異動なし（SKIP）
--          ELSIF (gt_mst_tbl(gn_if).proc_flg  = gv_sts_thru) THEN
--            NULL;
--          --正常処理：既存社員データ（更新）
--          ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_employee) THEN
--            -- =================================
--            -- 社員データ更新情報格納処理(A-9)
--            -- =================================
--            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
--            ln_update_cnt := ln_update_cnt + 1;
--            lt_update_masters(ln_update_cnt) := gt_mst_tbl(gn_if);
--          --正常処理：退職社員データ（更新）
--          ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_retiree) THEN
--            -- =================================
--            -- 社員データ削除情報格納処理(A-10)
--            -- =================================
--            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
--            ln_delete_cnt := ln_delete_cnt + 1;
--            lt_delete_masters(ln_delete_cnt) := gt_mst_tbl(gn_if);
--          END IF;
--        END IF;
--      END IF;
--
--      -- 件数のカウントアップ（異常時以外、処理件数=gn_skip_cnt + gn_normal_cnt + gn_warn_cnt ）
--      -- 異動なし件数（スキップ）をカウントアップ
--      IF (gt_mst_tbl(gn_if).proc_flg = gv_sts_thru) THEN  -- 異動なしデータ
--        gn_skip_cnt := gn_skip_cnt + 1;
--      -- 更新対象件数（正常）をカウントアップ
--      ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_update) THEN  -- 更新対象
--        gn_normal_cnt := gn_normal_cnt + 1;
--      -- 更新対象件数（異常）をカウントアップ
--      ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_error) THEN  -- 更新不可能
--        gn_warn_cnt := gn_warn_cnt + 1;
--      -- 異常件数をカウントアップ
--      ELSE
--        gn_error_cnt := gn_error_cnt +1;
--      END IF;
----
--      -- ==================================
--      -- 社員データエラー情報格納処理(A-11)
--      -- ==================================
--      add_report(
--        gt_mst_tbl(gn_if)  -- 待避エリア
----          ,lt_report_tbl
--        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--        ,lv_retcode  -- リターン・コード             --# 固定 #
--        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF (lv_retcode = cv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
----
--
--      -- 社員取込インタフェースの内容をチェックテーブルに待避(処理はここから始まる)
--      gn_target_cnt := gn_target_cnt + 1; -- 処理件数カウントアップ
--      BEGIN
--        gn_if := gn_if + 1;
--        gt_mst_tbl(gn_if).employee_number          := in_if_rec.employee_number;    --社員番号
--        gt_mst_tbl(gn_if).hire_date                := in_if_rec.hire_date;          --入社年月日
--        gt_mst_tbl(gn_if).actual_termination_date  := in_if_rec.actual_termination_date;--退職年月日
--        gt_mst_tbl(gn_if).last_name_kanji          := in_if_rec.last_name_kanji;    --漢字姓
--        gt_mst_tbl(gn_if).first_name_kanji         := in_if_rec.first_name_kanji;   --漢字名
--        gt_mst_tbl(gn_if).last_name                := in_if_rec.last_name;          --カナ姓
--        gt_mst_tbl(gn_if).first_name               := in_if_rec.first_name;         --カナ名
--        gt_mst_tbl(gn_if).sex                      := UPPER(in_if_rec.sex);         --性別
--        gt_mst_tbl(gn_if).employee_division        := NVL(in_if_rec.employee_division,'1');  --社員・外部委託区分
--        gt_mst_tbl(gn_if).location_code            := in_if_rec.location_code;      --所属コード（新）
--        gt_mst_tbl(gn_if).change_code              := in_if_rec.change_code;        --異動事由コード
--        gt_mst_tbl(gn_if).announce_date            := in_if_rec.announce_date;      --発令日
--        gt_mst_tbl(gn_if).office_location_code     := in_if_rec.office_location_code; --勤務地拠点コード（新）
--        gt_mst_tbl(gn_if).license_code             := in_if_rec.license_code;       --資格コード（新）
--        gt_mst_tbl(gn_if).license_name             := in_if_rec.license_name;       --資格名（新）
--        gt_mst_tbl(gn_if).job_post                 := in_if_rec.job_post;           --職位コード（新）
--        gt_mst_tbl(gn_if).job_post_name            := in_if_rec.job_post_name;      --職位名（新）
--        gt_mst_tbl(gn_if).job_duty                 := in_if_rec.job_duty;           --職務コード（新）
--        gt_mst_tbl(gn_if).job_duty_name            := in_if_rec.job_duty_name;      --職務名（新）
--        gt_mst_tbl(gn_if).job_type                 := in_if_rec.job_type;           --職種コード（新）
--        gt_mst_tbl(gn_if).job_type_name            := in_if_rec.job_type_name;      --職種名（新）
--        gt_mst_tbl(gn_if).job_system               := in_if_rec.job_system;         --適用労働時間制コード（新）
--        gt_mst_tbl(gn_if).job_system_name          := in_if_rec.job_system_name;    --適用労働名（新）
--        gt_mst_tbl(gn_if).job_post_order           := in_if_rec.job_post_order;     --職位並順コード（新）
--        gt_mst_tbl(gn_if).consent_division         := in_if_rec.consent_division;   --承認区分（新）
--        gt_mst_tbl(gn_if).agent_division           := in_if_rec.agent_division;     --代行区分（新）
--        gt_mst_tbl(gn_if).office_location_code_old := in_if_rec.office_location_code_old; --勤務地拠点コード（旧）
--        gt_mst_tbl(gn_if).location_code_old        := in_if_rec.location_code_old;  --所属コード（旧）
--        gt_mst_tbl(gn_if).license_code_old         := in_if_rec.license_code_old;   --資格コード（旧）
--        gt_mst_tbl(gn_if).license_code_name_old    := in_if_rec.license_code_name_old;--資格名（旧）
--        gt_mst_tbl(gn_if).job_post_old             := in_if_rec.job_post_old;       --職位コード（旧）
--        gt_mst_tbl(gn_if).job_post_name_old        := in_if_rec.job_post_name_old;  --職位名（旧）
--        gt_mst_tbl(gn_if).job_duty_old             := in_if_rec.job_duty_old;       --職務コード（旧）
--        gt_mst_tbl(gn_if).job_duty_name_old        := in_if_rec.job_duty_name_old;  --職務名（旧）
--        gt_mst_tbl(gn_if).job_type_old             := in_if_rec.job_type_old;       --職種コード（旧）
--        gt_mst_tbl(gn_if).job_type_name_old        := in_if_rec.job_type_name_old;  --職種名（旧）
--        gt_mst_tbl(gn_if).job_system_old           := in_if_rec.job_system_old;     --適用労働時間制コード（旧）
--        gt_mst_tbl(gn_if).job_system_name_old      := in_if_rec.job_system_name_old;--適用労働名（旧）
--        gt_mst_tbl(gn_if).job_post_order_old       := in_if_rec.job_post_order_old; --職位並順コード（旧）
--        gt_mst_tbl(gn_if).consent_division_old     := in_if_rec.consent_division_old; --承認区分（旧）
--        gt_mst_tbl(gn_if).agent_division_old       := in_if_rec.agent_division_old; --代行区分（旧）
--        gt_mst_tbl(gn_if).proc_flg := NULL;   -- 更新区分
--      EXCEPTION
--        WHEN VALUE_ERROR THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name
--                      ,iv_name         => cv_data_check_err
--                      ,iv_token_name1  => cv_tkn_ng_user
--                      ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
--                      ,iv_token_name2  => cv_tkn_ng_err
--                      ,iv_token_value2 => cv_data_err  -- 'データ異常'
--                     );
--          RAISE global_api_expt;
--        WHEN OTHERS THEN
--          RAISE global_api_others_expt;
--      END;
--    END LOOP in_if_loop;
----
--    -- 最終データチェック処理(in_if_loopの内容と同様)
--    -- ステータスの初期化
--    gt_mst_tbl(gn_if).proc_kbn := NULL;   -- 連携区分
--    gt_mst_tbl(gn_if).emp_kbn := NULL;    -- 社員状態
--    gt_mst_tbl(gn_if).ymd_kbn := NULL;    -- 入社日連携区分
--    gt_mst_tbl(gn_if).retire_kbn := NULL; -- 退職区分
--    gt_mst_tbl(gn_if).proc_flg := NULL;   -- 更新区分
--    -- 社員データ重複チェック（前のデータと同じ場合）
--    IF (lc_flg = gv_flg_on) THEN
--      lc_flg := ' ';
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_appl_short_name
--                  ,iv_name         => cv_data_check_err
--                  ,iv_token_name1  => cv_tkn_ng_user
--                  ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
--                  ,iv_token_name2  => cv_tkn_ng_err
--                  ,iv_token_value2 => cv_employee_err_nm  -- '社員番号重複'
--                  );
--      gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--      gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--    ELSE
--      -- ===============================
--      -- データ妥当性チェック処理(A-4)
--      -- ===============================
--      in_if_check(
--         gt_mst_tbl(gn_if)  -- 待避エリア
--        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--        ,lv_retcode  -- リターン・コード             --# 固定 #
--        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--      );
----
--      --エラー処理（処理中止）
--      IF (lv_retcode = cv_status_error) THEN
--        RAISE global_api_expt;
----
--      --警告処理（警告データ更新不可・次データ処理継続）
--      ELSIF (lv_retcode = cv_status_warn) THEN
--        gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--        gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
----
--      --正常処理：異動なし社員データ（SKIP）
--      ELSIF ((gt_mst_tbl(gn_if).proc_kbn IS NULL)         -- 連携なし
--        AND (gt_mst_tbl(gn_if).ymd_kbn IS NULL)           -- 入社日変更なし
--        AND (gt_mst_tbl(gn_if).retire_kbn IS NULL)) THEN  -- 退職処理なし
--        gt_mst_tbl(gn_if).proc_flg := gv_sts_thru; -- 変更なし
----
--      --正常処理：新規社員データ（登録）
--      ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_new) THEN  -- 新規社員
--        -- =================================
--        -- 社員データ登録分チェック処理(A-5)
--        -- =================================
--        check_insert(
--           gt_mst_tbl(gn_if)  -- 待避エリア
--          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--          ,lv_retcode  -- リターン・コード             --# 固定 #
--          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        --エラー処理（処理中止）
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_api_expt;
--        --警告処理（警告データ更新不可・次データ処理継続）
--        ELSIF (lv_retcode = cv_status_warn) THEN
--          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--        --正常処理：新規社員データ（登録）
--        ELSE
--          -- =================================
--          -- 社員データ登録情報格納処理(A-8)
--          -- =================================
--          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
--          ln_insert_cnt := ln_insert_cnt + 1;
--          lt_insert_masters(ln_insert_cnt) := gt_mst_tbl(gn_if);
--        END IF;
--
--      --正常処理：既存社員異動データ・退職社員再雇用データ（更新）
--      ELSE --(emp_kbn 'U'：既存社員、'D'：退職者)
--        -- =================================
--        -- 社員データ更新分チェック処理(A-6)
--        -- =================================
--        check_update(
--           gt_mst_tbl(gn_if)  -- 待避エリア
--          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--          ,lv_retcode  -- リターン・コード             --# 固定 #
--          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        --エラー処理（処理中止）
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_api_expt;
--        --警告処理（警告データ更新不可・次データ処理継続）
--        ELSIF (lv_retcode = cv_status_warn) THEN
--          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- 更新不可能
--          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--        --正常処理：既存社員データ（更新）
--        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_employee) THEN
--          -- =================================
--          -- 社員データ更新情報格納処理(A-9)
--          -- =================================
--          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
--          ln_update_cnt := ln_update_cnt + 1;
--          lt_update_masters(ln_update_cnt) := gt_mst_tbl(gn_if);
--        --正常処理：異動なし（SKIP）
--        ELSIF (gt_mst_tbl(gn_if).proc_flg  = gv_sts_thru) THEN
--          NULL;
--        --正常処理：退職社員データ（更新）
--        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_retiree) THEN
--          -- =================================
--          -- 社員データ削除情報格納処理(A-10)
--          -- =================================
--          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- 処理対象
--          ln_delete_cnt := ln_delete_cnt + 1;
--          lt_delete_masters(ln_delete_cnt) := gt_mst_tbl(gn_if);
--        END IF;
--      END IF;
--    END IF;
--
--    -- 件数のカウントアップ（異常時以外、処理件数=gn_skip_cnt + gn_normal_cnt + gn_warn_cnt ）
--    -- 異動なし件数（スキップ）をカウントアップ
--    IF (gt_mst_tbl(gn_if).proc_flg = gv_sts_thru) THEN  -- 異動なしデータ
--      gn_skip_cnt := gn_skip_cnt + 1;
--    -- 更新対象件数（正常）をカウントアップ
--    ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_update) THEN  -- 更新対象
--      gn_normal_cnt := gn_normal_cnt + 1;
--    -- 更新対象件数（異常）をカウントアップ
--    ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_error) THEN  -- 更新不可能
--      gn_warn_cnt := gn_warn_cnt + 1;
--    -- 異常件数をカウントアップ
--    ELSE
--      gn_error_cnt := gn_error_cnt +1;
--    END IF;
----
--    -- ==================================
--    -- 社員データエラー情報格納処理(A-11)
--    -- ==================================
--    add_report(
--      gt_mst_tbl(gn_if)  -- 待避エリア
--      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--      ,lv_retcode  -- リターン・コード             --# 固定 #
--      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--    );
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_api_expt;
--    END IF;
--
-- Ver1.3 Add 2009/04/16  データ取得・チェック周りを作成し直し追加
--                        対象データは都度、処理用レコードに格納するよう修正
--                        重複チェックは、I/F上に同じ従業員コードが存在するか取得するよう修正
    -- ===============================
    -- 社員インタフェース情報取得(A-3)
    -- ===============================
    -- IF件数の初期化
    gn_target_cnt := 0;
    --
    <<in_if_loop>>
    FOR in_if_rec IN in_if_cur LOOP
      -- 社員取込インタフェースの内容をチェックテーブルに待避
      gn_target_cnt := gn_target_cnt + 1;        -- 処理件数カウントアップ
      l_people_if_rec := l_if_clear_rec;         -- クリア
      --
      BEGIN
        -- ステータスの初期化
        l_people_if_rec.proc_flg                 := NULL;                                     -- 更新区分
        l_people_if_rec.proc_kbn                 := NULL;                                     -- 連携区分
        l_people_if_rec.emp_kbn                  := NULL;                                     -- 社員状態
        l_people_if_rec.ymd_kbn                  := NULL;                                     -- 入社日連携区分
        l_people_if_rec.retire_kbn               := NULL;                                     -- 退職区分
        l_people_if_rec.resp_kbn                 := NULL;                                     -- 職責・管理者変更区分
-- 2009/12/11 Ver1.13 E_本稼動_00103 add start by Y.Kuboshima
        l_people_if_rec.supervisor_kbn           := NULL;                                     -- 管理者変更区分
-- 2009/12/11 Ver1.13 E_本稼動_00103 add end by Y.Kuboshima
        --
        -- 取得I/Fデータ格納
        l_people_if_rec.employee_number          := in_if_rec.employee_number;                -- 社員番号
        l_people_if_rec.hire_date                := in_if_rec.hire_date;                      -- 入社年月日
        l_people_if_rec.actual_termination_date  := in_if_rec.actual_termination_date;        -- 退職年月日
        l_people_if_rec.last_name_kanji          := in_if_rec.last_name_kanji;                -- 漢字姓
        l_people_if_rec.first_name_kanji         := in_if_rec.first_name_kanji;               -- 漢字名
        l_people_if_rec.last_name                := in_if_rec.last_name;                      -- カナ姓
        l_people_if_rec.first_name               := in_if_rec.first_name;                     -- カナ名
        l_people_if_rec.sex                      := UPPER( in_if_rec.sex );                   -- 性別
        l_people_if_rec.employee_division        := NVL( in_if_rec.employee_division, '1' );  -- 社員・外部委託区分
        l_people_if_rec.location_code            := in_if_rec.location_code;                  -- 所属コード（新）
        l_people_if_rec.change_code              := in_if_rec.change_code;                    -- 異動事由コード
        l_people_if_rec.announce_date            := in_if_rec.announce_date;                  -- 発令日
        l_people_if_rec.office_location_code     := in_if_rec.office_location_code;           -- 勤務地拠点コード（新）
        l_people_if_rec.license_code             := in_if_rec.license_code;                   -- 資格コード（新）
        l_people_if_rec.license_name             := in_if_rec.license_name;                   -- 資格名（新）
        l_people_if_rec.job_post                 := in_if_rec.job_post;                       -- 職位コード（新）
        l_people_if_rec.job_post_name            := in_if_rec.job_post_name;                  -- 職位名（新）
        l_people_if_rec.job_duty                 := in_if_rec.job_duty;                       -- 職務コード（新）
        l_people_if_rec.job_duty_name            := in_if_rec.job_duty_name;                  -- 職務名（新）
        l_people_if_rec.job_type                 := in_if_rec.job_type;                       -- 職種コード（新）
        l_people_if_rec.job_type_name            := in_if_rec.job_type_name;                  -- 職種名（新）
        l_people_if_rec.job_system               := in_if_rec.job_system;                     -- 適用労働時間制コード（新）
        l_people_if_rec.job_system_name          := in_if_rec.job_system_name;                -- 適用労働名（新）
        l_people_if_rec.job_post_order           := in_if_rec.job_post_order;                 -- 職位並順コード（新）
        l_people_if_rec.consent_division         := in_if_rec.consent_division;               -- 承認区分（新）
        l_people_if_rec.agent_division           := in_if_rec.agent_division;                 -- 代行区分（新）
        l_people_if_rec.office_location_code_old := in_if_rec.office_location_code_old;       -- 勤務地拠点コード（旧）
        l_people_if_rec.location_code_old        := in_if_rec.location_code_old;              -- 所属コード（旧）
        l_people_if_rec.license_code_old         := in_if_rec.license_code_old;               -- 資格コード（旧）
        l_people_if_rec.license_code_name_old    := in_if_rec.license_code_name_old;          -- 資格名（旧）
        l_people_if_rec.job_post_old             := in_if_rec.job_post_old;                   -- 職位コード（旧）
        l_people_if_rec.job_post_name_old        := in_if_rec.job_post_name_old;              -- 職位名（旧）
        l_people_if_rec.job_duty_old             := in_if_rec.job_duty_old;                   -- 職務コード（旧）
        l_people_if_rec.job_duty_name_old        := in_if_rec.job_duty_name_old;              -- 職務名（旧）
        l_people_if_rec.job_type_old             := in_if_rec.job_type_old;                   -- 職種コード（旧）
        l_people_if_rec.job_type_name_old        := in_if_rec.job_type_name_old;              -- 職種名（旧）
        l_people_if_rec.job_system_old           := in_if_rec.job_system_old;                 -- 適用労働時間制コード（旧）
        l_people_if_rec.job_system_name_old      := in_if_rec.job_system_name_old;            -- 適用労働名（旧）
        l_people_if_rec.job_post_order_old       := in_if_rec.job_post_order_old;             -- 職位並順コード（旧）
        l_people_if_rec.consent_division_old     := in_if_rec.consent_division_old;           -- 承認区分（旧）
        l_people_if_rec.agent_division_old       := in_if_rec.agent_division_old;             -- 代行区分（旧）
      --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_data_check_err
                      ,iv_token_name1  => cv_tkn_ng_user
                      ,iv_token_value1 => l_people_if_rec.employee_number
                      ,iv_token_name2  => cv_tkn_ng_err
                      ,iv_token_value2 => cv_data_err  -- 'データ異常'
                     );
          RAISE global_api_expt;
      END;
      -- 退避用従業員コードが未設定の場合
      -- または、退避用従業員コードとレコードの従業員コードが異なる場合
      -- 重複チェックを実施する
      IF ( ln_wk_emp_num IS NULL )
      OR ( ln_wk_emp_num != in_if_rec.employee_number )
      THEN
        -- SQLで従業員コードが重複していないか確認する
        SELECT      COUNT( xip.ROWID )
        INTO        ln_exist_cnt
        FROM        xxcmm_in_people_if   xip
        WHERE       xip.employee_number = in_if_rec.employee_number
        AND         xip.ROWID != in_if_rec.xip_rowid
        AND         ROWNUM = 1;
        --
        IF ( ln_exist_cnt = 0 ) THEN
          ln_wk_emp_num := NULL;
        ELSE
          ln_wk_emp_num := in_if_rec.employee_number;
        END IF;
      END IF;
      --
      -- 退避用従業員コードがNULLの場合、チェック処理を実施
      IF ( ln_wk_emp_num IS NULL ) THEN
        -- ===============================
        -- データ妥当性チェック処理(A-4)
        -- ===============================
        in_if_check(
           l_people_if_rec  -- 待避エリア
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        --エラー処理（処理中止）
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        --警告処理（警告データ更新不可・次データ処理継続）
        ELSIF (lv_retcode = cv_status_warn) THEN
          l_people_if_rec.proc_flg := gv_sts_error;       -- 更新不可能
          l_people_if_rec.row_err_message := lv_errmsg;
        --正常処理：異動なし社員データ（SKIP）
        ELSIF ((l_people_if_rec.proc_kbn IS NULL)         -- 連携なし
          AND (l_people_if_rec.ymd_kbn IS NULL)           -- 入社日変更なし
          AND (l_people_if_rec.retire_kbn IS NULL)) THEN  -- 退職処理なし
          l_people_if_rec.proc_flg := gv_sts_thru;        -- 変更なし
          --
        --正常処理：新規社員データ（登録）
        ELSIF (l_people_if_rec.emp_kbn  = gv_kbn_new) THEN  -- 新規社員
          -- =================================
          -- 社員データ登録分チェック処理(A-5)
          -- =================================
          check_insert(
             l_people_if_rec  -- 待避エリア
            ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,lv_retcode  -- リターン・コード             --# 固定 #
            ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --エラー処理（処理中止）
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          --警告処理（警告データ更新不可・次データ処理継続）
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            l_people_if_rec.proc_flg := gv_sts_error;  -- 更新不可能
            l_people_if_rec.row_err_message := lv_errmsg;
          --正常処理：新規社員データ（登録）
          ELSE
            -- =================================
            -- 社員データ登録情報格納処理(A-8)
            -- =================================
            l_people_if_rec.proc_flg := gv_sts_update;  -- 処理対象
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 各従業員データを登録、更新、削除に分けると、
-- 正しい割当順序にならないので管理者または役職が正しく割当たらないため修正
--            ln_insert_cnt := ln_insert_cnt + 1;
--            lt_insert_masters( ln_insert_cnt ) := l_people_if_rec;
            ln_proc_cnt := ln_proc_cnt + 1;
            lt_proc_masters( ln_proc_cnt ) := l_people_if_rec;
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
          END IF;
          --
        --正常処理：既存社員異動データ・退職社員再雇用データ（更新）
        ELSE --(emp_kbn 'U'：既存社員、'D'：退職者)
          -- =================================
          -- 社員データ更新分チェック処理(A-6)
          -- =================================
          check_update(
             l_people_if_rec  -- 待避エリア
            ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,lv_retcode  -- リターン・コード             --# 固定 #
            ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --エラー処理（処理中止）
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          --警告処理（警告データ更新不可・次データ処理継続）
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            l_people_if_rec.proc_flg := gv_sts_error;  -- 更新不可能
            l_people_if_rec.row_err_message := lv_errmsg;
          --正常処理：異動なし（SKIP）
          ELSIF ( l_people_if_rec.proc_flg  = gv_sts_thru ) THEN
            NULL;
          --正常処理：既存社員データ（更新）
          ELSIF ( l_people_if_rec.emp_kbn  = gv_kbn_employee ) THEN
            -- =================================
            -- 社員データ更新情報格納処理(A-9)
            -- =================================
            l_people_if_rec.proc_flg := gv_sts_update;  -- 処理対象
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 各従業員データを登録、更新、削除に分けると、
-- 正しい割当順序にならないので管理者または役職が正しく割当たらないため修正
--            ln_update_cnt := ln_update_cnt + 1;
--            lt_update_masters( ln_update_cnt ) := l_people_if_rec;
            ln_proc_cnt := ln_proc_cnt + 1;
            lt_proc_masters( ln_proc_cnt ) := l_people_if_rec;
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
          --正常処理：退職社員データ（更新）
          ELSIF ( l_people_if_rec.emp_kbn  = gv_kbn_retiree ) THEN
            -- =================================
            -- 社員データ削除情報格納処理(A-10)
            -- =================================
            l_people_if_rec.proc_flg := gv_sts_update;  -- 処理対象
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 各従業員データを登録、更新、削除に分けると、
-- 正しい割当順序にならないので管理者または役職が正しく割当たらないため修正
--            ln_delete_cnt := ln_delete_cnt + 1;
--            lt_delete_masters( ln_delete_cnt ) := l_people_if_rec;
            ln_proc_cnt := ln_proc_cnt + 1;
            lt_proc_masters( ln_proc_cnt ) := l_people_if_rec;
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
          END IF;
        END IF;
      ELSE
        -- 従業員コードが重複している場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_data_check_err
                      ,iv_token_name1  => cv_tkn_ng_user
                      ,iv_token_value1 => l_people_if_rec.employee_number
                      ,iv_token_name2  => cv_tkn_ng_err
                      ,iv_token_value2 => cv_employee_err_nm     -- '社員番号重複'
                     );
        l_people_if_rec.proc_flg := gv_sts_error;                -- 更新不可能
        l_people_if_rec.row_err_message := lv_errmsg;
        --
      END IF;
      --
      -- 件数のカウントアップ（異常時以外、処理件数=gn_skip_cnt + gn_normal_cnt + gn_warn_cnt ）
      IF ( l_people_if_rec.proc_flg = gv_sts_thru ) THEN  -- 異動なしデータ
      -- 異動なし件数（スキップ）をカウントアップ
        gn_skip_cnt := gn_skip_cnt + 1;
      ELSIF ( l_people_if_rec.proc_flg = gv_sts_update ) THEN  -- 更新対象
      -- 更新対象件数（正常）をカウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSIF ( l_people_if_rec.proc_flg = gv_sts_error ) THEN  -- 更新不可能
      -- 更新対象件数（異常）をカウントアップ
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSE
      -- 異常件数をカウントアップ
        gn_error_cnt := gn_error_cnt +1;
      END IF;
      --
      -- ==================================
      -- 社員データエラー情報格納処理(A-11)
      -- ==================================
      -- 正常データと異常データがそれぞれの配列に格納される
      add_report(
        l_people_if_rec    -- 待避エリア
       ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,lv_retcode         -- リターン・コード             --# 固定 #
       ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      --
    END LOOP in_if_loop;
-- End Ver1.3
    --
    -- ================================
    -- 社員データ反映処理(A-12)
    -- ================================
-- 2009/10/29 Ver1.12 modify start by Yutaka.Kuboshima
-- 各従業員データを登録、更新、削除に分けると、
-- 正しい割当順序にならないので管理者または役職が正しく割当たらないため修正
--    IF ( ln_insert_cnt > 0 ) THEN
--      -- 新規社員登録処理
--      <<lt_insert_masters_loop>>
--      FOR ln_cnt IN 1 .. ln_insert_cnt LOOP
--        -- 新規社員登録処理
--        insert_proc(
--           lt_insert_masters(ln_cnt)
--          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--          ,lv_retcode  -- リターン・コード             --# 固定 #
--          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        --
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_api_expt;
--        END IF;
--      END LOOP lt_insert_masters_loop;
--      --
--      -- 新規社員の職責は社員職責自動割当ワークより一括登録
--      <<wk_pr2_loop>>
--      FOR wk_pr2_rec IN wk_pr2_cur(gv_kbn_new) LOOP
--      -- 新規社員登録処理
--        insert_resp_all(
--           wk_pr2_rec.employee_number
--          ,wk_pr2_rec.responsibility_key
--          ,wk_pr2_rec.application_short_name
--          ,wk_pr2_rec.start_date
--          ,wk_pr2_rec.end_date
--          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--          ,lv_retcode  -- リターン・コード             --# 固定 #
--          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_api_expt;
--        END IF;
--      END LOOP wk_pr2_loop;
--    END IF;
--    --
--    IF (ln_update_cnt > 0) THEN
--      -- 既存社員更新処理
--      <<lt_update_masters_loop>>
--      FOR ln_cnt IN 1 .. ln_update_cnt LOOP
--        -- 既存社員異動処理
--        update_proc(
--           lt_update_masters(ln_cnt)
--          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--          ,lv_retcode  -- リターン・コード             --# 固定 #
--          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        --
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_api_expt;
--        END IF;
--      END LOOP lt_update_masters_loop;
--    END IF;
--    --
--    IF (ln_delete_cnt > 0) THEN
--      -- 退職者再雇用処理
--      <<lt_delete_masters_loop>>
--      FOR ln_cnt IN 1..ln_delete_cnt LOOP
--        -- 退職者処理
--        delete_proc(
--           lt_delete_masters(ln_cnt)
--          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--          ,lv_retcode  -- リターン・コード             --# 固定 #
--          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        --
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_api_expt;
--        END IF;
--      END LOOP lt_update_masters_loop;
--    END IF;
--
-- ↓ modify start
    -- 連携対象データを抽出
    <<lt_proc_masters_loop>>
    FOR ln_cnt IN 1 .. ln_proc_cnt
    LOOP
      -- 登録処理の場合
      IF (lt_proc_masters(ln_cnt).emp_kbn = gv_kbn_new) THEN
        -- 新規社員登録処理
        insert_proc(
           lt_proc_masters(ln_cnt)
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      -- 更新処理の場合
      ELSIF (lt_proc_masters(ln_cnt).emp_kbn = gv_kbn_employee) THEN
        -- 既存社員異動処理
        update_proc(
           lt_proc_masters(ln_cnt)
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      -- 退職処理の場合
      ELSIF (lt_proc_masters(ln_cnt).emp_kbn = gv_kbn_retiree) THEN
        -- 退職者処理
        delete_proc(
           lt_proc_masters(ln_cnt)
          ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END LOOP lt_proc_masters_loop;
    -- 新規社員の職責は社員職責自動割当ワークより一括登録
    <<wk_pr2_loop>>
    FOR wk_pr2_rec IN wk_pr2_cur(gv_kbn_new) 
    LOOP
    -- 新規社員登録処理
      insert_resp_all(
         wk_pr2_rec.employee_number
        ,wk_pr2_rec.responsibility_key
        ,wk_pr2_rec.application_short_name
        ,wk_pr2_rec.start_date
        ,wk_pr2_rec.end_date
        ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END LOOP wk_pr2_loop;
-- 2009/10/29 Ver1.12 modify end by Yutaka.Kuboshima
    --
    -- 初期化
    ov_retcode := cv_status_normal;
    --
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
      -- カーソルが開いていれば
--
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
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
  IS
--
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    cv_normal     CONSTANT VARCHAR2(20) := '正常データの';  -- メッセージ
    cv_warning    CONSTANT VARCHAR2(20) := '警告データの';  -- メッセージ
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
    lv_msgbuf  VARCHAR2(5000);  -- エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
    END IF;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --異常エラー時は、成功件数０件、スキップ件数０件、エラー件数１件と固定表示
      gn_normal_cnt := 0;
      gn_warn_cnt := 0;
      gn_error_cnt := 1;
      gn_skip_cnt := 0;
    ELSE
      IF (gn_normal_cnt > 0) THEN
      -- ログ出力処理(成功データ出力)
        disp_report(
          cv_status_normal
         ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,lv_retcode  -- リターン・コード             --# 固定 #
         ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_log_err_msg
                       ,iv_token_name1  => cv_tkn_ng_word
                       ,iv_token_value1 => cv_normal    -- '正常データの'
                      );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          lv_retcode := cv_status_normal;
        END IF;
      END IF;
    --
    -- ログ出力・処理結果出力 処理(警告データ出力：未更新)
      IF (gn_warn_cnt > 0) THEN
        disp_report(
          cv_status_warn
         ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,lv_retcode  -- リターン・コード             --# 固定 #
         ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_log_err_msg
                       ,iv_token_name1  => cv_tkn_ng_word
                       ,iv_token_value1 => cv_warning    -- '警告データの'
                      );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
        -- ワーニングデータがある場合は、正常データ有ってもワーニング終了する。
        lv_retcode := cv_status_warn;
      END IF;
      --警告件数をエラー件数として設定
      gn_error_cnt := gn_warn_cnt;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_target_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_success_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_error_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_skip_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
-- 2009/10/29 Ver1.12 add start by Yutaka.Kuboshima
    -- 終了ステータスが正常かつ
    -- 入社日の変更が行われている場合
    IF (lv_retcode = cv_status_normal)
      AND (gv_retcode = cv_status_warn)
    THEN
      -- 終了ステータスを警告にする
      -- ※入社日の変更が行われた従業員は正常件数にカウントしています
      lv_retcode := cv_status_warn;
    END IF;
-- 2009/10/29 Ver1.12 add end by Yutaka.Kuboshima
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
                  iv_application  => cv_common_short_name
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合・正常件数０件の場合はROLLBACKする
    IF (retcode = cv_status_error)
    OR (gn_normal_cnt = 0) THEN
      ROLLBACK;
    END IF;
    --
    -- ===============================
    -- CSVファイル削除処理
    -- ===============================
-- Ver1.1 Mod by SCS 竹下 昭範  エラー終了時にファイルは削除しないよう修正
--    UTL_FILE.FREMOVE(gv_directory,   -- 出力先
--                     gv_file_name    -- CSVファイル名
--    );
    -- 正常時のみファイル削除処理を実施
    IF (retcode = cv_status_normal) THEN
      UTL_FILE.FREMOVE(gv_directory,   -- 出力先
                       gv_file_name    -- CSVファイル名
      );
    END IF;
-- Ver1.1 End
    -- ===============================
    -- 職責自動割当ワーク削除処理
    -- ===============================
    DELETE xxcmm_wk_people_resp;
    --
    -- ===============================
    -- 社員インタフェース削除処理
    -- ===============================
    DELETE xxcmm_in_people_if;
    --
    COMMIT;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
-- Ver1.1 Del by SCS 竹下 昭範  エラー終了時にファイルは削除しないよう修正
--      UTL_FILE.FREMOVE(gv_directory,   -- 出力先
--                       gv_file_name    -- CSVファイル名
--      );
-- Ver1.1 End
      DELETE xxcmm_in_people_if;
      DELETE xxcmm_wk_people_resp;
      COMMIT;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
-- Ver1.1 Del by SCS 竹下 昭範  エラー終了時にファイルは削除しないよう修正
--      UTL_FILE.FREMOVE(gv_directory,   -- 出力先
--                       gv_file_name    -- CSVファイル名
--      );
-- Ver1.1 End
      DELETE xxcmm_in_people_if;
      DELETE xxcmm_wk_people_resp;
      COMMIT;
  END main;
--
--#####################################  固定部 END   #############################################
--
END XXCMM002A01C;
/
