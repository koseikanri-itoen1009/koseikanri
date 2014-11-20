create or replace PACKAGE BODY      XXCFF004A30C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A30C(body)
 * Description      : リース物件一部修正・移動・解約アップロード
 * MD.050           : MD050_CFF_004_A30_リース物件一部修正・移動・解約アップロード
 * Version          : 1.8
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理                                  (A-1)
 *  get_for_validation           妥当性チェック用の値取得                  (A-2)
 *  get_upload_data              ファイルアップロードIFデータ取得          (A-3)
 *  divide_item                  デリミタ文字項目分割                      (A-4)
 *  check_item_value             項目値チェック                            (A-5)
 *  ins_maintenance_wk           リース物件メンテナンステーブル作成        (A-6)
 *  get_maintenance_wk           リース物件メンテナンステーブル取得        (A-7)
 *  check_object_exist           リース物件存在チェック                    (A-8)
 *  check_mst_owner_company      マスタチェック(本社工場)                  (A-9)
 *  check_mst_department         マスタチェック(管理部門)                  (A-10)
 *  check_mst_cancellation_class マスタチェック(解約種別)                  (A-11)
 *  check_mst_lease_class        マスタチェック(リース種別)                (A-12)
 *  check_mst_bond_accep_flag    マスタチェック(証書受領)                  (A-13)
 *  validate_bond_accep_flag     妥当性チェック(証書受領)                  (A-14)
 *  call_facmn_chk_object_term   FA共通関数(物件コード解約チェック)        (A-15)
 *  check_cancellation_cancel    解約キャンセルチェック                    (A-16)
 *  call_facmn_chk_paychked      FA共通関数(支払照合済チェック)            (A-17)
 *  lock_object_tbl              リース物件テーブルロック取得(通常)        (A-18)
 *  lock_object_tbl_other        リース物件テーブルロック取得(その他)      (A-19)
 *  lock_object_hist_tbl         リース物件履歴テーブルロック取得          (A-20)
 *  lock_ctrct_relation_tbl      リース契約関連テーブルロック取得          (A-21)
 *  call_fa_common               FA共通関数起動処理(通常)                  (A-22)
 *  call_fa_common_other         FA共通関数起動処理(その他)                (A-23)
 *  call_facmn_chk_location      FA共通関数(事業所マスタチェック)          (A-24)
 *  check_cancellation_date      解約日チェック                            (A-25)
 *
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0  SCS 嶋田         新規作成
 *  2009/02/10    1.1  SCS 嶋田         ログの出力先が誤っていた箇所を修正
 *  2009/02/18    1.2  SCS 嶋田         証書受領の処理時、すでに証書受領済のレコードに
 *                                       関しては処理を行わない様にチェックを追加する
 *  2009/02/19    1.3  SCS 嶋田         顧客コードを追加
 *  2009/02/23    1.4  SCS 嶋田         契約ステータスが204:満了の際の対応を追加
 *  2009/05/18    1.5  SCS 松中         [障害T1_0721]デリミタ文字分割データ格納配列の桁数を変更
 *  2009/07/31    1.6  SCS 萱原         [統合テスト障害0000654]物件コードNULL時の処理分岐追加
 *  2009/08/03    1.7  SCS 渡辺         [統合テスト障害0000654(追加)]
 *                                        支払照合済チェックの呼出をコメントアウト
 *  2011/12/26    1.8  SCSK白川         [E_本稼動_08123] アップロードシートに解約日を追加
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
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- ロック(ビジー)エラー
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF004A30C'; -- パッケージ名
--
  cv_csv_delimiter   CONSTANT VARCHAR2(1) := ','; --カンマ
  cv_const_y         CONSTANT VARCHAR2(1) := 'Y'; --'Y'
--
  --証書受領フラグ
  cv_bond_acceptance_flag_0  CONSTANT VARCHAR2(1) := '0';  --未受領
  cv_bond_acceptance_flag_1  CONSTANT VARCHAR2(1) := '1';  --受領済
--
  --解約種別
  cv_cancel_class_1  CONSTANT VARCHAR2(1) := '1';  --解約確定(自己都合)
  cv_cancel_class_2  CONSTANT VARCHAR2(1) := '2';  --解約確定(保険対応)
  cv_cancel_class_3  CONSTANT VARCHAR2(1) := '3';  --解約申請
  cv_cancel_class_4  CONSTANT VARCHAR2(1) := '4';  --解約申請(自己都合)
  cv_cancel_class_5  CONSTANT VARCHAR2(1) := '5';  --解約申請(保険対応)
  cv_cancel_class_9  CONSTANT VARCHAR2(1) := '9';  --解約キャンセル
--
  --解約区分
  cv_cancel_type_1   CONSTANT VARCHAR2(1) := '1';  --自己都合
  cv_cancel_type_2   CONSTANT VARCHAR2(1) := '2';  --保険対応
--
  --物件ステータス
  cv_ob_status_101   CONSTANT VARCHAR2(3) := '101';  --未契約
  cv_ob_status_108   CONSTANT VARCHAR2(3) := '108';  --中途解約申請
--
  --契約ステータス
  cv_ct_status_204   CONSTANT VARCHAR2(3) := '204';  --満了
--
  --大分類
  cv_major_division_30  CONSTANT VARCHAR2(2) := '30';
  cv_major_division_40  CONSTANT VARCHAR2(2) := '40';
  cv_major_division_50  CONSTANT VARCHAR2(2) := '50';
  cv_major_division_60  CONSTANT VARCHAR2(2) := '60';
--
  --小分類
  cv_small_class_7      CONSTANT VARCHAR2(2) := '7';
  cv_small_class_8      CONSTANT VARCHAR2(2) := '8';
  cv_small_class_9      CONSTANT VARCHAR2(2) := '9';
  cv_small_class_10     CONSTANT VARCHAR2(2) := '10';
--
  --処理モード
  cv_exce_mode_adj   CONSTANT VARCHAR2(20) := 'ADJUSTMENT';    -- 修正
  cv_exce_mode_chg   CONSTANT VARCHAR2(20) := 'CHANGE';        -- 変更
--  cv_exce_mode_mov   CONSTANT VARCHAR2(20) := 'MOVE';          -- 移動
  cv_exce_mode_dis   CONSTANT VARCHAR2(20) := 'DISSOLUTION';   -- 解約キャンセル
  cv_exce_mode_can   CONSTANT VARCHAR2(20) := 'CANCELLATION';  -- 解約確定
--
    --解約種別/証書受領フラグの処理判別フラグ
  cv_proc_flag_tbl   CONSTANT VARCHAR2(3) := 'TBL'; --解約種別に値が存在する場合の処理
  cv_proc_flag_csv   CONSTANT VARCHAR2(3) := 'CSV'; --証書受領に値が存在する場合の処理
--
  -- ***出力タイプ
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      --出力(ユーザメッセージ用出力先)
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         --ログ(システム管理者用出力先)
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF'; --アドオン：会計・リース・FA領域
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP'; --共通のメッセージ

  -- ***メッセージ名(本文)
  cv_msg_name1     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094'; --共通関数エラー
  cv_msg_name2     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00095'; --共通関数メッセージ
  cv_msg_name3     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00124'; --項目値チェックエラー
  cv_msg_name4     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00176'; --物件コード重複エラー
  cv_msg_name5     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00123'; --存在チェックエラー
  cv_msg_name6     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00129'; --証書受領済チェックエラー
  cv_msg_name7     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00136'; --ステータスエラー
  cv_msg_name8     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007'; --ロックエラー
  cv_msg_name9     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00128'; --解約キャンセルチェックエラー
  cv_msg_name10    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00120'; --支払照合済みエラー
  cv_msg_name11    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104'; --削除エラー
  cv_msg_name12    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00159'; --物件エラー対象
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
  cv_msg_name13    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00191'; --解約日未設定チェックエラー
  cv_msg_name14    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00192'; --解約日設定チェックエラー
  cv_msg_name15    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00193'; --現会計期間開始日取得エラー
  cv_msg_name16    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00188'; --解約日エラー
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
--
  cv_msg_name29    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00167'; --アップロード初期出力メッセージ
  cv_msg_name30    CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000'; --対象件数メッセージ
  cv_msg_name31    CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001'; --成功件数メッセージ
  cv_msg_name32    CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002'; --エラー件数メッセージ
  cv_msg_name33    CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003'; --スキップ件数メッセージ
--
  -- ***メッセージ名(トークン)
  cv_tkn_val1      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130'; --初期処理
  cv_tkn_val2      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131'; --BLOBデータ変換用関数
  cv_tkn_val3      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50165'; --デリミタ文字分割関数
  cv_tkn_val4      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50166'; --項目チェック
  cv_tkn_val5      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50012'; --本社工場
  cv_tkn_val6      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50011'; --管理部門コード
  cv_tkn_val7      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50141'; --事業所マスタチェック
  cv_tkn_val8      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50017'; --リース種別
  cv_tkn_val9      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50014'; --リース物件テーブル
  cv_tkn_val10     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50023'; --リース物件履歴テーブル
  cv_tkn_val11     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50169'; --リース物件情報作成（バッチ）
  cv_tkn_val12     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50170'; --解約種別
  cv_tkn_val13     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50173'; --リース契約関連
  cv_tkn_val14     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50015'; --リース物件情報作成
  cv_tkn_val15     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50021'; --証書受領フラグ
  cv_tkn_val16     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50174'; --リース物件メンテナンステーブル
  cv_tkn_val17     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175'; --ファイルアップロードI/Fテーブル
  cv_tkn_val18     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50176'; --リース物件一部修正・移動・解約
  cv_tkn_val19     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50185'; --物件コード解約チェック
--
  -- ***トークン名
  -- プロファイル名
  cv_tkn_name1     CONSTANT VARCHAR2(100) := 'FUNC_NAME';   --共通関数名
  cv_tkn_name2     CONSTANT VARCHAR2(100) := 'COLUMN_NAME'; --項目名
  cv_tkn_name3     CONSTANT VARCHAR2(100) := 'COLUMN_INFO'; --項目情報
  cv_tkn_name4     CONSTANT VARCHAR2(100) := 'OBJECT_CODE'; --物件コード
  cv_tkn_name5     CONSTANT VARCHAR2(100) := 'COLUMN_DATA'; --項目データ
  cv_tkn_name6     CONSTANT VARCHAR2(100) := 'ERR_MSG';     --エラーメッセージ
  cv_tkn_name7     CONSTANT VARCHAR2(100) := 'TABLE_NAME';  --テーブル
  cv_tkn_name8     CONSTANT VARCHAR2(100) := 'INFO';        --メッセージ
  cv_tkn_name9     CONSTANT VARCHAR2(100) := 'FILE_NAME';   -- ファイル名トークン
  cv_tkn_name10    CONSTANT VARCHAR2(100) := 'CSV_NAME';    -- CSVファイル名トークン
--
  -- ***プロファイル名称
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  --文字項目分割後データ格納配列
  --[障害T1_0721]MOD START
  --TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(200) INDEX BY PLS_INTEGER;
  TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(600) INDEX BY PLS_INTEGER;
  --[障害T1_0721]MOD END
--
  -- ***バルクフェッチ用定義
--
  --妥当性チェック用の値取得用定義
  TYPE g_column_desc_ttype         IS TABLE OF xxcff_object_adj_upload_v.column_desc%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_ttype          IS TABLE OF xxcff_object_adj_upload_v.byte_count%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_decimal_ttype  IS TABLE OF xxcff_object_adj_upload_v.byte_count_decimal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_pay_match_flag_name_ttype IS TABLE OF xxcff_object_adj_upload_v.payment_match_flag_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_item_attribute_ttype      IS TABLE OF xxcff_object_adj_upload_v.item_attribute%TYPE INDEX BY PLS_INTEGER;
--
  --リース物件メンテナンステーブル取得用定義
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_object_headers.object_header_id%TYPE INDEX BY PLS_INTEGER;         --物件内部ID
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_contract_headers.contract_header_id%TYPE INDEX BY PLS_INTEGER;     --契約内部ID
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_contract_lines.contract_line_id%TYPE INDEX BY PLS_INTEGER;         --契約明細内部ID
  TYPE g_contract_status_ttype       IS TABLE OF xxcff_contract_lines.contract_status%TYPE INDEX BY PLS_INTEGER;          --契約ステータス
  TYPE g_cancellation_class_ttype    IS TABLE OF xxcff_maintenance_work.cancellation_class%TYPE INDEX BY PLS_INTEGER;     --解約種別
  TYPE g_object_code_ttype           IS TABLE OF xxcff_maintenance_work.object_code%TYPE INDEX BY PLS_INTEGER;            --物件コード
  TYPE g_bond_acceptance_flag_ttype  IS TABLE OF xxcff_maintenance_work.bond_acceptance_flag%TYPE INDEX BY PLS_INTEGER;   --証書受領フラグ
  TYPE g_lease_class_ttype           IS TABLE OF xxcff_object_headers.lease_class%TYPE INDEX BY PLS_INTEGER;              --リース種別
  TYPE g_lease_type_ttype            IS TABLE OF xxcff_object_headers.lease_type%TYPE INDEX BY PLS_INTEGER;               --リース区分
  TYPE g_re_lease_times_ttype        IS TABLE OF xxcff_object_headers.re_lease_times%TYPE INDEX BY PLS_INTEGER;           --再リース回数
  TYPE g_po_number_ttype             IS TABLE OF xxcff_object_headers.po_number%TYPE INDEX BY PLS_INTEGER;                --発注番号
  TYPE g_registration_number_ttype   IS TABLE OF xxcff_object_headers.registration_number%TYPE INDEX BY PLS_INTEGER;      --登録番号
  TYPE g_age_type_ttype              IS TABLE OF xxcff_object_headers.age_type%TYPE INDEX BY PLS_INTEGER;                 --年式
  TYPE g_model_ttype                 IS TABLE OF xxcff_object_headers.model%TYPE INDEX BY PLS_INTEGER;                    --機種
  TYPE g_serial_number_ttype         IS TABLE OF xxcff_object_headers.serial_number%TYPE INDEX BY PLS_INTEGER;            --機番
  TYPE g_quantity_ttype              IS TABLE OF xxcff_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;                 --数量
  TYPE g_manufacturer_name_ttype     IS TABLE OF xxcff_object_headers.manufacturer_name%TYPE INDEX BY PLS_INTEGER;        --メーカー名
  TYPE g_department_code_ttype       IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;          --管理部門コード
  TYPE g_owner_company_ttype         IS TABLE OF xxcff_object_headers.owner_company%TYPE INDEX BY PLS_INTEGER;            --本社工場(本社／工場)
  TYPE g_installation_address_ttype  IS TABLE OF xxcff_object_headers.installation_address%TYPE INDEX BY PLS_INTEGER;     --現設置場所
  TYPE g_installation_place_ttype    IS TABLE OF xxcff_object_headers.installation_place%TYPE INDEX BY PLS_INTEGER;       --現設置先
  TYPE g_chassis_number_ttype        IS TABLE OF xxcff_object_headers.chassis_number%TYPE INDEX BY PLS_INTEGER;           --車台番号
  TYPE g_re_lease_flag_ttype         IS TABLE OF xxcff_object_headers.re_lease_flag%TYPE INDEX BY PLS_INTEGER;            --再リース要フラグ
  TYPE g_cancellation_type_ttype     IS TABLE OF xxcff_object_headers.cancellation_type%TYPE INDEX BY PLS_INTEGER;        --解約区分
  TYPE g_cancellation_date_ttype     IS TABLE OF xxcff_object_headers.cancellation_date%TYPE INDEX BY PLS_INTEGER;        --中途解約日
  TYPE g_dissolution_date_ttype      IS TABLE OF xxcff_object_headers.dissolution_date%TYPE INDEX BY PLS_INTEGER;         --中途解約キャンセル日
  TYPE g_bond_acceptance_date_ttype  IS TABLE OF xxcff_object_headers.bond_acceptance_date%TYPE INDEX BY PLS_INTEGER;     --証書受領日
  TYPE g_expiration_date_ttype       IS TABLE OF xxcff_object_headers.expiration_date%TYPE INDEX BY PLS_INTEGER;          --満了日
  TYPE g_object_status_ttype         IS TABLE OF xxcff_object_headers.object_status%TYPE INDEX BY PLS_INTEGER;            --物件ステータス
  TYPE g_active_flag_ttype           IS TABLE OF xxcff_object_headers.active_flag%TYPE INDEX BY PLS_INTEGER;              --物件有効フラグ
  TYPE g_info_sys_if_date_ttype      IS TABLE OF xxcff_object_headers.info_sys_if_date%TYPE INDEX BY PLS_INTEGER;         --リース管理情報連携日
  TYPE g_generation_date_ttype       IS TABLE OF xxcff_object_headers.generation_date%TYPE INDEX BY PLS_INTEGER;          --発生日
  TYPE g_customer_code_ttype         IS TABLE OF xxcff_object_headers.customer_code%TYPE INDEX BY PLS_INTEGER;            --顧客コード
--
  --マスタチェック用定義
  TYPE g_mst_check_ttype             IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
--
  --ロック取得用定義
  TYPE g_small_class_ttype           IS TABLE OF xxcff_obj_ins_status_v.small_class%TYPE INDEX BY PLS_INTEGER;            --小分類
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- 初期値情報
  g_init_rec                     xxcff_common1_pkg.init_rtype;
--
  --ファイルアップロードIFデータ
  g_file_upload_if_data_tab      xxccp_common_pkg2.g_file_data_tbl;
--
  --文字項目分割後データ格納配列
  g_load_data_tab                g_load_data_ttype;
--
  --CSVの物件コードを保持
  g_csv_object_code              VARCHAR2(100);
--
  -- ***バルクフェッチ用定義
--
  --妥当性チェック用の値取得用定義
  g_column_desc_tab              g_column_desc_ttype;
  g_byte_count_tab               g_byte_count_ttype;
  g_byte_count_decimal_tab       g_byte_count_decimal_ttype;
  g_pay_match_flag_name_tab      g_pay_match_flag_name_ttype;
  g_item_attribute_tab           g_item_attribute_ttype;
--
  --リース物件メンテナンステーブル取得用定義
  g_object_header_id_tab         g_object_header_id_ttype;     --物件内部ID
  g_contract_header_id_tab       g_contract_header_id_ttype;   --契約内部ID
  g_contract_line_id_tab         g_contract_line_id_ttype;     --契約明細内部ID
  g_contract_status_tab          g_contract_status_ttype;      --契約ステータス
  g_cancellation_class_tab       g_cancellation_class_ttype;   --解約種別
  g_object_code_tab              g_object_code_ttype;          --物件コード
  g_bond_acceptance_flag_xmw_tab g_bond_acceptance_flag_ttype; --証書受領フラグ(メンテナンステーブル)
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
  g_cancellation_date_xmw_tab    g_cancellation_date_ttype;    --解約日(メンテナンステーブル)
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
  g_lease_class_tab              g_lease_class_ttype;          --リース種別
  g_lease_type_tab               g_lease_type_ttype;           --リース区分
  g_re_lease_times_tab           g_re_lease_times_ttype;       --再リース回数
  g_po_number_tab                g_po_number_ttype;            --発注番号
  g_registration_number_tab      g_registration_number_ttype;  --登録番号
  g_age_type_tab                 g_age_type_ttype;             --年式
  g_model_tab                    g_model_ttype;                --機種
  g_serial_number_tab            g_serial_number_ttype;        --機番
  g_quantity_tab                 g_quantity_ttype;             --数量
  g_manufacturer_name_tab        g_manufacturer_name_ttype;    --メーカー名
  g_department_code_tab          g_department_code_ttype;      --管理部門コード
  g_owner_company_tab            g_owner_company_ttype;        --本社工場(本社／工場)
  g_installation_address_tab     g_installation_address_ttype; --現設置場所
  g_installation_place_tab       g_installation_place_ttype;   --現設置先
  g_chassis_number_tab           g_chassis_number_ttype;       --車台番号
  g_re_lease_flag_tab            g_re_lease_flag_ttype;        --再リース要フラグ
  g_cancellation_type_tab        g_cancellation_type_ttype;    --解約区分
  g_cancellation_date_tab        g_cancellation_date_ttype;    --中途解約日(物件テーブル)
  g_dissolution_date_tab         g_dissolution_date_ttype;     --中途解約キャンセル日
  g_bond_acceptance_flag_tab     g_bond_acceptance_flag_ttype; --証書受領フラグ(物件テーブル)
  g_bond_acceptance_date_tab     g_bond_acceptance_date_ttype; --証書受領日
  g_expiration_date_tab          g_expiration_date_ttype;      --満了日
  g_object_status_tab            g_object_status_ttype;        --物件ステータス
  g_active_flag_tab              g_active_flag_ttype;          --物件有効フラグ
  g_info_sys_if_date_tab         g_info_sys_if_date_ttype;     --リース管理情報連携日
  g_generation_date_tab          g_generation_date_ttype;      --発生日
  g_customer_code_tab            g_customer_code_ttype;        --顧客コード
--
  --リース物件情報作成用定義
  g_re_lease_times_ob_tab        g_re_lease_times_ttype;       --再リース回数
  g_small_class_ob_tab           g_small_class_ttype;          --小分類
--
  --マスタチェック用定義
  g_mst_check_tab                g_mst_check_ttype;
--
  --ロック取得用定義
  g_object_header_id_lock_tab    g_object_header_id_ttype;     --物件内部ID
  g_contract_line_id_lock_tab    g_contract_line_id_ttype;     --契約明細内部ID
--
  --ロックフラグ
  gb_lock_ob_flag                BOOLEAN;
  gb_lock_ob_hist_flag           BOOLEAN;
  --エラーフラグ
  gb_err_flag                    BOOLEAN;
--
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
  gd_period_date_from            DATE;                         --現会計期間開始日
--
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
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
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_file_name    xxccp_mrp_file_ul_interface.file_name%TYPE; -- 取得ファイル名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
      --アップロードCSVファイル名取得
      SELECT
              xfu.file_name
      INTO
              lv_file_name
      FROM
              xxccp_mrp_file_ul_interface  xfu
      WHERE
              xfu.file_id = in_file_id;

      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG      --ログ(システム管理者用メッセージ)出力
       ,buff   => xxccp_common_pkg.get_msg(cv_msg_kbn_cff, cv_msg_name29
                                          ,cv_tkn_name9,   cv_tkn_val18
                                          ,cv_tkn_name10,    lv_file_name)
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => xxccp_common_pkg.get_msg(cv_msg_kbn_cff, cv_msg_name29
                                           ,cv_tkn_name9,   cv_tkn_val18
                                           ,cv_tkn_name10,    lv_file_name)
      );
--
    --①コンカレントパラメータを表示
--
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --②初期値情報の取得
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- 初期値情報
      ,ov_errbuf   => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --③初期値情報の取得処理で、リターンコードが正常以外の場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- 共通関数エラー
                                                    ,cv_tkn_name1                         -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val1 )                        -- 初期処理
                                                    || cv_msg_part
                                                    || lv_errmsg                          -- ユーザー・エラー・メッセージ
                                                    ,1
                                                    ,5000);
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
    --④現会計期間開始日の取得
    BEGIN

      SELECT ADD_MONTHS(TO_DATE((period_name || '-01'),'YYYY-MM-DD'), 1) AS period_date_from  -- リース月次締め期間の翌月初日
      INTO   gd_period_date_from                                                              -- 現会計期間開始日
      FROM   xxcff_lease_closed_periods xlcp                                                  -- リース月次締め期間
      WHERE  xlcp.set_of_books_id = g_init_rec.set_of_books_id                                -- 会計帳簿ID
      ;

    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name15 )                      -- 現会計期間開始日取得エラー
                                                      ,1
                                                      ,5000);
        RAISE global_process_expt;
    END;
--
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : get_for_validation
   * Description      : 妥当性チェック用の値取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_for_validation(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_for_validation'; -- プログラム名
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
    CURSOR get_validate_cur
    IS
      SELECT
              xoa.column_desc              AS column_desc
             ,xoa.byte_count               AS byte_count
             ,xoa.byte_count_decimal       AS byte_count_decimal
             ,xoa.payment_match_flag_name  AS payment_match_flag_name
             ,xoa.item_attribute           AS item_attribute
        FROM
              xxcff_object_adj_upload_v  xoa --リース物件一部修正ビュー
       ORDER BY
              xoa.code ASC
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --カーソルのオープン
    OPEN get_validate_cur;
    FETCH get_validate_cur
    BULK COLLECT INTO g_column_desc_tab          --項目名称
                     ,g_byte_count_tab           --バイト数
                     ,g_byte_count_decimal_tab   --バイト数_小数点以下
                     ,g_pay_match_flag_name_tab  --必須フラグ
                     ,g_item_attribute_tab       --項目属性
    ;
--
    --カーソルのクローズ
    CLOSE get_validate_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( get_validate_cur%ISOPEN ) THEN
        CLOSE get_validate_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_for_validation;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIFデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --ファイルアップロードIFデータを取得
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id                 -- ファイルID
     ,ov_file_data => g_file_upload_if_data_tab  -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- 共通関数エラー
                                                    ,cv_tkn_name1                         -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val2 )                        -- BLOBデータ変換用関数
                                                    || cv_msg_part
                                                    || lv_errmsg                          --共通関数内ｴﾗｰﾒｯｾｰｼﾞ
                                                    ,1
                                                    ,5000)
      ;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : デリミタ文字項目分割処理(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_loop_cnt_1 IN  NUMBER,       --  ループカウンタ1
    in_loop_cnt_2 IN  NUMBER,       --  ループカウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デリミタ文字分割の共通関数の呼出
    g_load_data_tab(in_loop_cnt_2) := xxccp_common_pkg.char_delim_partition(
                                        g_file_upload_if_data_tab(in_loop_cnt_1) --分割元文字列(取得データ)
                                       ,cv_csv_delimiter                         --デリミタ文字
                                       ,in_loop_cnt_2                            --返却対象INDEX
    );
    --処理中の物件コードを保持
    IF ( in_loop_cnt_2 = 1 ) THEN
      g_csv_object_code := g_load_data_tab(in_loop_cnt_2);
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
      --エラーメッセージを出力する
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- 共通関数エラー
                                                    ,cv_tkn_name1                         -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val3 )                        -- デリミタ文字分割関数
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_errmsg
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : check_item_value
   * Description      : 項目値チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_loop_cnt_2 IN  NUMBER,       -- ループカウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_value'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 項目値チェックを行う
--
    --項目チェックの共通関数の呼出
    xxccp_common_pkg2.upload_item_check(
       iv_item_name    => g_column_desc_tab(in_loop_cnt_2)          -- 項目名称
      ,iv_item_value   => g_load_data_tab(in_loop_cnt_2)            -- 項目の値
      ,in_item_len     => g_byte_count_tab(in_loop_cnt_2)           -- バイト数/項目の長さ
      ,in_item_decimal => g_byte_count_decimal_tab(in_loop_cnt_2)   -- バイト数_小数点以下/項目の長さ（小数点以下）
      ,iv_item_nullflg => g_pay_match_flag_name_tab(in_loop_cnt_2)  -- 必須フラグ
      ,iv_item_attr    => g_item_attribute_tab(in_loop_cnt_2)       -- 項目属性
      ,ov_errbuf       => lv_errbuf                               -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode                              -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --リターンコードが警告の場合
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name1                         -- 共通関数エラー
                                                      ,cv_tkn_name1                         -- トークン'FUNC_NAME'
                                                      ,cv_tkn_val4  )                       -- 共通関数名
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name2                         -- 共通関数メッセージ
                                                    ,cv_tkn_name6                         -- トークン'ERR_MSG'
                                                    ,lv_errmsg                            -- ユーザー・エラー・メッセージ
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff                   --XXCFF
                                                       ,cv_msg_name12                    --物件エラー対象
                                                       ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                       ,g_csv_object_code                -- CSVの物件コード
                                                      )
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_errmsg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
      --処理継続の為、リターンコードを初期化
      lv_retcode := cv_status_normal;
    --リターンコードがエラーの場合
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : ins_maintenance_wk
   * Description      : リース物件メンテナンステーブル作成処理(A-6)
   ***********************************************************************************/
  PROCEDURE ins_maintenance_wk(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_maintenance_wk'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- リース物件メンテナンステーブル(物件メンテナンスワーク)作成
    INSERT INTO xxcff_maintenance_work (
      file_id                 --ファイルID
     ,object_code             --物件コード
     ,owner_company           --本社工場
     ,department_code         --管理部門コード
     ,registration_number     --登録番号
     ,po_number               --発注番号
     ,manufacturer_name       --メーカー名
     ,model                   --機種
     ,serial_number           --機番
     ,age_type                --年式
     ,quantity                --数量
     ,chassis_number          --車台番号
     ,installation_address    --現設置場所
     ,installation_place      --現設置先
     ,cancellation_class      --解約種別
     ,bond_acceptance_flag    --証書受領フラグ
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
     ,cancellation_date       --解約日
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
     ,created_by              --作成者
     ,creation_date           --作成日
     ,last_updated_by         --最終更新者
     ,last_update_date        --最終更新日
     ,last_update_login       --最終更新ﾛｸﾞｲﾝ
     ,request_id              --要求ID
     ,program_application_id  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     ,program_id              --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     ,program_update_date     --ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    VALUES (
      in_file_id                 --ファイルID
     ,g_load_data_tab(1)         --物件コード
     ,g_load_data_tab(2)         --本社工場
     ,g_load_data_tab(3)         --管理部門
     ,g_load_data_tab(4)         --登録番号
     ,g_load_data_tab(5)         --発注番号
     ,g_load_data_tab(6)         --メーカー名
     ,g_load_data_tab(7)         --機種
     ,g_load_data_tab(8)         --機番
     ,g_load_data_tab(9)         --年式
     ,g_load_data_tab(10)        --数量
     ,g_load_data_tab(11)        --車台番号
     ,g_load_data_tab(12)        --現設置場所
     ,g_load_data_tab(13)        --現設置先
     ,g_load_data_tab(14)        --解約種別
     ,g_load_data_tab(15)        --証書受領
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
     ,TO_DATE(g_load_data_tab(16),'YYYY/MM/DD')  --解約日
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
     ,cn_created_by              --作成者
     ,cd_creation_date           --作成日
     ,cn_last_updated_by         --最終更新者
     ,cd_last_update_date        --最終更新日
     ,cn_last_update_login       --最終更新ログイン
     ,cn_request_id              --要求ID
     ,cn_program_application_id  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     ,cn_program_id              --コンカレント･プログラムID
     ,cd_program_update_date     --プログラム更新日
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      --登録時エラー(物件コード重複)の場合
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name4                         -- 物件コード重複エラー(ワークテーブル)
                                                    ,cv_tkn_name4                         -- トークン'OBJECT_CODE'
                                                    ,g_load_data_tab(1) )                 -- 物件コード
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END ins_maintenance_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_maintenance_wk
   * Description      : リース物件メンテナンステーブル取得処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_maintenance_wk(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_maintenance_wk'; -- プログラム名
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
    CURSOR get_maintenance_wk_cur
    IS
      SELECT
              xoh.object_header_id         AS object_header_id          --物件内部ID
             ,xca.contract_header_id       AS contract_header_id        --契約内部ID
             ,xca.contract_line_id         AS contract_line_id          --契約明細内部ID
             ,DECODE (xoh.object_status, '101', xca.contract_status
                                              , NVL(xca.contract_status, cv_ct_status_204))
                                           AS contract_status
             ,xmw.cancellation_class       AS cancellation_class        --解約種別
             ,xmw.object_code              AS object_code               --物件コード
             ,xmw.bond_acceptance_flag     AS bond_acceptance_flag_xmw  --証書受領フラグ
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
             ,xmw.cancellation_date        AS cancellation_date_xmw     --解約日
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
             ,xoh.lease_class              AS lease_class               --リース種別
             ,xoh.lease_type               AS lease_type                --リース区分
             ,xoh.re_lease_times           AS re_lease_times            --再リース回数
             ,NVL(xmw.po_number, xoh.po_number)                        AS po_number             --発注番号
             ,NVL(xmw.registration_number, xoh.registration_number)    AS registration_number   --登録番号
             ,NVL(xmw.age_type, xoh.age_type)                          AS age_type              --年式
             ,NVL(xmw.model, xoh.model)                                AS model                 --機種
             ,NVL(xmw.serial_number, xoh.serial_number)                AS serial_number         --機番
             ,NVL(xmw.quantity, xoh.quantity)                          AS quantity              --数量
             ,NVL(xmw.manufacturer_name, xoh.manufacturer_name)        AS manufacturer_name     --メーカー名
             ,NVL(xmw.department_code, xoh.department_code)            AS department_code       --管理部門コード
             ,NVL(xmw.owner_company, xoh.owner_company)                AS owner_company         --本社工場(本社／工場)
             ,NVL(xmw.installation_address, xoh.installation_address)  AS installation_address  --現設置場所
             ,NVL(xmw.installation_place, xoh.installation_place)      AS installation_place    --現設置先
             ,NVL(xmw.chassis_number, xoh.chassis_number)              AS chassis_number        --車台番号
             ,xoh.re_lease_flag            AS re_lease_flag             --再リース要フラグ
             ,xoh.cancellation_type        AS cancellation_type         --解約区分
             ,xoh.cancellation_date        AS cancellation_date         --中途解約日
             ,xoh.dissolution_date         AS dissolution_date          --中途解約キャンセル日
             ,xoh.bond_acceptance_flag     AS bond_acceptance_flag      --証書受領フラグ
             ,xoh.bond_acceptance_date     AS bond_acceptance_date      --証書受領日
             ,xoh.expiration_date          AS expiration_date           --満了日
             ,xoh.object_status            AS object_status             --物件ステータス
             ,xoh.active_flag              AS active_flag               --物件有効フラグ
             ,xoh.info_sys_if_date         AS info_sys_if_date          --リース管理情報連携日
             ,xoh.generation_date          AS generation_date           --発生日
             ,xoh.customer_code            AS customer_code             --顧客コード
        FROM
              xxcff_maintenance_work  xmw  --物件メンテナンスワーク(リース物件メンテナンステーブル)
             ,xxcff_object_headers    xoh  --リース物件
             ,(SELECT
                       xch.contract_header_id
                      ,xcl.contract_line_id
                      ,xcl.contract_status
                      ,xcl.object_header_id
                      ,xch.re_lease_times
                 FROM
                       xxcff_contract_headers  xch  --リース契約
                      ,xxcff_contract_lines    xcl  --リース契約明細
                WHERE
                       xch.contract_header_id  = xcl.contract_header_id  --契約内部ID
              )                       xca
       WHERE
              xmw.object_code         = xoh.object_code(+)      --物件コード
         AND  xoh.object_header_id    = xca.object_header_id(+) --物件内部ID
         AND  xoh.re_lease_times      = xca.re_lease_times(+)   --再リース回数
         AND  xmw.file_id             = in_file_id              --ファイルID
       ORDER BY
              xmw.object_code ASC
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- リース物件メンテナンスワーク取得
    OPEN get_maintenance_wk_cur;  --カーソルのオープン
    FETCH get_maintenance_wk_cur
    BULK COLLECT INTO g_object_header_id_tab         --物件内部ID
                     ,g_contract_header_id_tab       --契約内部ID
                     ,g_contract_line_id_tab         --契約明細内部ID
                     ,g_contract_status_tab          --契約ステータス
                     ,g_cancellation_class_tab       --解約種別
                     ,g_object_code_tab              --物件コード
                     ,g_bond_acceptance_flag_xmw_tab --証書受領フラグ(メンテナンステーブル)
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
                     ,g_cancellation_date_xmw_tab    --解約日(メンテナンステーブル)
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
                     ,g_lease_class_tab              --リース種別
                     ,g_lease_type_tab               --リース区分
                     ,g_re_lease_times_tab           --再リース回数
                     ,g_po_number_tab                --発注番号
                     ,g_registration_number_tab      --登録番号
                     ,g_age_type_tab                 --年式
                     ,g_model_tab                    --機種
                     ,g_serial_number_tab            --機番
                     ,g_quantity_tab                 --数量
                     ,g_manufacturer_name_tab        --メーカー名
                     ,g_department_code_tab          --管理部門コード
                     ,g_owner_company_tab            --本社工場(本社／工場)
                     ,g_installation_address_tab     --現設置場所
                     ,g_installation_place_tab       --現設置先
                     ,g_chassis_number_tab           --車台番号
                     ,g_re_lease_flag_tab            --再リース要フラグ
                     ,g_cancellation_type_tab        --解約区分
                     ,g_cancellation_date_tab        --中途解約日(物件テーブル)
                     ,g_dissolution_date_tab         --中途解約キャンセル日
                     ,g_bond_acceptance_flag_tab     --証書受領フラグ(物件テーブル)
                     ,g_bond_acceptance_date_tab     --証書受領日
                     ,g_expiration_date_tab          --満了日
                     ,g_object_status_tab            --物件ステータス
                     ,g_active_flag_tab		              --物件有効フラグ
                     ,g_info_sys_if_date_tab         --リース管理情報連携日
                     ,g_generation_date_tab          --発生日
                     ,g_customer_code_tab            --顧客コード
    ;
    CLOSE get_maintenance_wk_cur;  --カーソルのクローズ
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( get_maintenance_wk_cur%ISOPEN ) THEN
        CLOSE get_maintenance_wk_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_maintenance_wk;
--
  /**********************************************************************************
   * Procedure Name   : check_object_exist
   * Description      : リース物件存在チェック処理(A-8)
   ***********************************************************************************/
  PROCEDURE check_object_exist(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_object_exist'; -- プログラム名
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
    lv_warn_msg    VARCHAR2(5000);      --警告メッセージ
    ln_normal_cnt  PLS_INTEGER := 0;    --正常カウンター
    ln_error_cnt   PLS_INTEGER := 0;    --エラーカウンター
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 物件内部IDがNULLではないかチェック
    <<chk_exist_loop>>
    FOR ln_loop_cnt IN g_object_code_tab.FIRST .. g_object_code_tab.LAST LOOP
      IF ( g_object_header_id_tab(ln_loop_cnt) IS NULL ) THEN
        lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                        ,cv_msg_name5                         -- 存在チェックエラー
                                                        ,cv_tkn_name5                         -- トークン'COLUMN_DATA'
                                                        ,g_object_code_tab(ln_loop_cnt) )     -- 物件コード
                                                        ,1
                                                        ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
          ,buff   => lv_warn_msg
        );
        --エラーカウンタインクリメント
        ln_error_cnt  := ( ln_error_cnt + 1 );
      END IF;
    END LOOP chk_exist_loop;
--
    --物件内部IDがNULLのデータが存在した場合
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END check_object_exist;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_owner_company
   * Description      : マスタチェック(本社工場)処理(A-9)
   ***********************************************************************************/
  PROCEDURE check_mst_owner_company(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_owner_company'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
--
    -- *** ローカル・カーソル ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_owner_company_v  xocv  --本社工場ビュー
       WHERE
              xocv.owner_company_code = g_owner_company_tab(in_loop_cnt_3)
         AND  xocv.enabled_flag       = cv_const_y
         AND  (   ( xocv.start_date_active IS NULL )
               OR ( xocv.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xocv.end_date_active IS NULL )
               OR ( xocv.end_date_active >= g_init_rec.process_date )   )
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- マスタチェック(本社/工場)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --対象データがない場合
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name3                         -- 項目値チェックエラー
                                                      ,cv_tkn_name2                         -- トークン'COLUMN_NAME'
                                                      ,cv_tkn_val5                          -- 本社工場
                                                      ,cv_tkn_name3                         -- トークン'COLUMN_INFO'
                                                      ,g_owner_company_tab(in_loop_cnt_3)   -- 本社工場(値)
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --物件エラー対象
                                                         ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- 物件コード
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_mst_owner_company;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_department
   * Description      : マスタチェック(管理部門)処理(A-10)
   ***********************************************************************************/
  PROCEDURE check_mst_department(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_department'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
--
    -- *** ローカル・カーソル ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_department_v  xdv  --管理部門ビュー
       WHERE
              xdv.department_code  = g_department_code_tab(in_loop_cnt_3) --管理部門コード
         AND  xdv.enabled_flag     = cv_const_y                           --有効フラグ
         AND  (   ( xdv.start_date_active IS NULL )
               OR ( xdv.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xdv.end_date_active IS NULL )
               OR ( xdv.end_date_active >= g_init_rec.process_date )   )
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- マスタチェック(管理部門)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --対象データがない場合
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name3                         -- 項目値チェックエラー
                                                      ,cv_tkn_name2                         -- トークン'COLUMN_NAME'
                                                      ,cv_tkn_val6                          -- 管理部門コード
                                                      ,cv_tkn_name4                         -- トークン'OBJECT_CODE'
                                                      ,g_object_code_tab(in_loop_cnt_3)     -- 物件コード
                                                      ,cv_tkn_name3                         -- トークン'COLUMN_INFO'
                                                      ,g_department_code_tab(in_loop_cnt_3) -- 管理部門コード(値)
                                                     )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_mst_department;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_cancellation_class
   * Description      : マスタチェック(解約種別)処理(A-11)
   ***********************************************************************************/
  PROCEDURE check_mst_cancellation_class(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_cancellation_class'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
--
    -- *** ローカル・カーソル ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_cancellation_class_v  xccv  --解約種別ビュー
       WHERE
              xccv.cancellation_class_code  = g_cancellation_class_tab(in_loop_cnt_3)  --解約種別コード
         AND  xccv.enabled_flag             = cv_const_y                               --有効フラグ
         AND  (   ( xccv.start_date_active IS NULL )
               OR ( xccv.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xccv.end_date_active IS NULL )
               OR ( xccv.end_date_active >= g_init_rec.process_date )   )
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- マスタチェック(解約種別)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --対象データがない場合
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                          -- XXCFF
                                                      ,cv_msg_name3                            -- 項目値チェックエラー
                                                      ,cv_tkn_name2                            -- トークン'COLUMN_NAME'
                                                      ,cv_tkn_val12                            -- 解約種別
                                                      ,cv_tkn_name4                            -- トークン'OBJECT_CODE'
                                                      ,g_object_code_tab(in_loop_cnt_3)        -- 物件コード
                                                      ,cv_tkn_name3                            -- トークン'COLUMN_INFO'
                                                      ,g_cancellation_class_tab(in_loop_cnt_3) -- 解約種別コード(値)
                                                     )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_mst_cancellation_class;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_lease_class
   * Description      : マスタチェック(リース種別)処理(A-12)
   ***********************************************************************************/
  PROCEDURE check_mst_lease_class(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_lease_class'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
--
    -- *** ローカル・カーソル ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_lease_class_v  xlcv  --リース種別ビュー
       WHERE
              xlcv.lease_class_code = g_lease_class_tab(in_loop_cnt_3)     --リース種別コード
         AND  xlcv.vdsh_flag        IS NULL                                --自販機_SHフラグ
         AND  xlcv.enabled_flag     = cv_const_y                           --有効フラグ
         AND  (   ( xlcv.start_date_active IS NULL )
               OR ( xlcv.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xlcv.end_date_active IS NULL )
               OR ( xlcv.end_date_active >= g_init_rec.process_date )   )
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- マスタチェック(リース種別)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --対象データがない場合
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name3                         -- 項目値チェックエラー
                                                      ,cv_tkn_name2                         -- トークン'COLUMN_NAME'
                                                      ,cv_tkn_val8                          -- リース種別
                                                      ,cv_tkn_name4                         -- トークン'OBJECT_CODE'
                                                      ,g_object_code_tab(in_loop_cnt_3)     -- 物件コード
                                                      ,cv_tkn_name3                         -- トークン'COLUMN_INFO'
                                                      ,g_lease_class_tab(in_loop_cnt_3)     -- リース種別(値)
                                                     )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_mst_lease_class;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_bond_accep_flag
   * Description      : マスタチェック(証書受領)処理(A-13)
   ***********************************************************************************/
  PROCEDURE check_mst_bond_accep_flag(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_bond_accep_flag'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
--
    -- *** ローカル・カーソル ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_bond_acceptance_flag_v  xbav  --証書受領フラグビュー
       WHERE
              xbav.bond_acceptance_flag_code
                = NVL(g_bond_acceptance_flag_xmw_tab(in_loop_cnt_3), 0 )    --証書受領フラグコード
         AND  xbav.enabled_flag  =  cv_const_y                              --有効フラグ
         AND  (   ( xbav.start_date_active IS NULL )
               OR ( xbav.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xbav.end_date_active IS NULL )
               OR ( xbav.end_date_active >= g_init_rec.process_date )   )
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- マスタチェック(証書受領)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --対象データがない場合
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name3                         -- 項目値チェックエラー
                                                      ,cv_tkn_name2                         -- トークン'COLUMN_NAME'
                                                      ,cv_tkn_val15                         -- 証書受領フラグ
                                                      ,cv_tkn_name4                         -- トークン'OBJECT_CODE'
                                                      ,g_object_code_tab(in_loop_cnt_3)     -- 物件コード
                                                      ,cv_tkn_name3                         -- トークン'COLUMN_INFO'
                                                      ,g_bond_acceptance_flag_xmw_tab(in_loop_cnt_3) -- 証書受領フラグ
                                                     )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_mst_bond_accep_flag;
--
  /**********************************************************************************
   * Procedure Name   : validate_bond_accep_flag
   * Description      : 妥当性チェック(証書受領)処理(A-14)
   ***********************************************************************************/
  PROCEDURE validate_bond_accep_flag(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_bond_accep_flag'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 妥当性チェック(証書受領) - 証書受領フラグ(物件テーブル)が '1' でないこと
    IF ( g_bond_acceptance_flag_tab(in_loop_cnt_3) = cv_bond_acceptance_flag_1 ) THEN
--
      --妥当性チェックエラー
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name6                         -- 証書受領済チェックエラー
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --物件エラー対象
                                                         ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- 物件コード
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END validate_bond_accep_flag;
--
  /**********************************************************************************
   * Procedure Name   : call_facmn_chk_object_term
   * Description      : FA共通関数(物件コード解約チェック)処理(A-15)
   ***********************************************************************************/
  PROCEDURE call_facmn_chk_object_term(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_facmn_chk_object_term'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- FA共通関数(物件コード解約チェック)
    xxcff_common2_pkg.chk_object_term(
      iv_term_appl_chk_flg  => cv_const_y                            --解約申請チェックフラグ
     ,in_object_header_id   => g_object_header_id_tab(in_loop_cnt_3) --物件内部ID
     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --解約済み、もしくは満了の状態のレコードの為、証書受領がNOT NULLと整合
    IF ( lv_retcode = cv_status_warn ) THEN
      --処理継続の為、共通関数の戻り値が警告の場合はステータスを正常に戻す
      lv_retcode := cv_status_normal;
    --共通関数で戻り値が正常の場合、解約状態のレコードではない為、チェックエラー
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name1                         -- 共通関数エラー
                                                      ,cv_tkn_name1                         -- トークン'FUNC_NAME'
                                                      ,cv_tkn_val19 )                       -- 物件コード解約チェック
                                                      ,1
                                                      ,5000)
      ;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    ELSE
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END call_facmn_chk_object_term;
--
  /**********************************************************************************
   * Procedure Name   : check_cancellation_cancel
   * Description      : 解約キャンセルチェック処理(A-16)
   ***********************************************************************************/
  PROCEDURE check_cancellation_cancel(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cancellation_cancel'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 解約種別が解約キャンセル、且つCSVファイルの証書受領が受領済の場合(不正)
    IF ( ( g_cancellation_class_tab(in_loop_cnt_3) = cv_cancel_class_9 )
     AND ( g_bond_acceptance_flag_xmw_tab(in_loop_cnt_3) = cv_bond_acceptance_flag_1 ) )
    THEN
      --解約キャンセルチェックエラー
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name9                         -- 解約キャンセルチェックエラー
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --物件エラー対象
                                                         ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- 物件コード
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END check_cancellation_cancel;
--
  /**********************************************************************************
   * Procedure Name   : call_facmn_chk_paychked
   * Description      : FA共通関数(支払照合済チェック)処理(A-17)
   ***********************************************************************************/
  PROCEDURE call_facmn_chk_paychked(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_facmn_chk_paychked'; -- プログラム名
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
    lv_warn_msg  VARCHAR2(5000); --警告メッセージ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- FA共通関数(支払照合済チェック)
-- 0000654 2009/08/03 DEL START
--    xxcff_common2_pkg.payment_match_chk(
--      in_line_id   => g_contract_line_id_tab(in_loop_cnt_3)  --契約明細内部ID
--     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
--     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
--     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
--    );
-- 0000654 2009/08/03 DEL END
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff  -- XXCFF
                                                      ,cv_msg_name10 ) -- 支払照合済みエラー
                                                      ,1
                                                      ,5000)
      ;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
      --処理継続の為、共通関数の戻り値が警告の場合はステータスを正常に戻す
      lv_retcode := cv_status_normal;
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END call_facmn_chk_paychked;
--
  /**********************************************************************************
   * Procedure Name   : lock_object_tbl
   * Description      : リース物件テーブルロック取得(通常)処理(A-18)
   ***********************************************************************************/
  PROCEDURE lock_object_tbl(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_object_tbl'; -- プログラム名
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
    lv_warn_msg VARCHAR2(5000); --警告メッセージ出力用変数
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT
              xoh.object_header_id  AS object_header_id  --物件内部ID
             ,xoh.re_lease_times    AS re_lease_times    --再リース回数
        FROM
              xxcff_object_headers    xoh --リース物件
       WHERE NOT EXISTS
              (SELECT
                       NULL
                 FROM
                       xxcff_object_status_v  xosv  --リース物件ステータスビュー
                WHERE
                       xosv.object_status_code = xoh.object_status          --物件ステータス
                  AND  xosv.no_adjusts_flag    = cv_const_y                 --修正不可フラグ
              )
         AND  xoh.object_header_id = g_object_header_id_tab(in_loop_cnt_3)  --物件内部ID
         FOR UPDATE NOWAIT
      ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- リース物件テーブルロック取得(通常)
    OPEN lock_cur;
    FETCH lock_cur
    BULK COLLECT INTO  g_object_header_id_lock_tab  --物件内部ID
                      ,g_re_lease_times_ob_tab      --再リース回数
    ;
    --対象データなしの場合
    IF ( lock_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name7 )                       -- ステータスエラー
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --物件エラー対象
                                                         ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- 物件コード
                                                        )
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      RAISE global_api_expt;
    ELSE
      --物件テーブルのロックが正常に取得できている場合
      gb_lock_ob_flag := TRUE;
    END IF;
--
    --カーソルのクローズ
    CLOSE lock_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name8         -- テーブルロックエラー
                                                     ,cv_tkn_name7         -- トークン'TABLE_NAME'
                                                     ,cv_tkn_val9 )        -- リース物件テーブル
                                                     ,1
                                                     ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END lock_object_tbl;
--
  /**********************************************************************************
   * Procedure Name   : lock_object_tbl_other
   * Description      : リース物件テーブルロック取得(その他)処理(A-19)
   ***********************************************************************************/
  PROCEDURE lock_object_tbl_other(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    iv_proc_flag  IN  VARCHAR2,     --  証書受領フラグの取得元判別フラグ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_object_tbl_other'; -- プログラム名
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
    lv_major_division  VARCHAR2(2); --大分類
    lv_warn_msg VARCHAR2(5000);     --警告メッセージ出力用変数
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT
              xoh.object_header_id  --物件内部ID
             ,xoh.re_lease_times    --再リース回数
             ,xoiv.small_class      --小分類
        FROM
              xxcff_object_headers    xoh  --リース物件
             ,xxcff_obj_ins_status_v  xoiv --リース物件登録ステータスビュー
       WHERE
              xoh.object_header_id = g_object_header_id_tab(in_loop_cnt_3)      --物件内部ID
         AND  xoh.object_status    = xoiv.object_status                         --物件ステータス
         AND  xoiv.large_class     = lv_major_division                          --大分類
         AND  NVL(xoiv.constract_status, g_contract_status_tab(in_loop_cnt_3))
                = g_contract_status_tab(in_loop_cnt_3)                          --契約ステータス
         FOR UPDATE OF xoh.object_header_id NOWAIT
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 大分類の設定
    IF ( iv_proc_flag = cv_proc_flag_tbl ) THEN
      --解約種別の処理の場合、解約種別の値により設定
      lv_major_division := CASE g_cancellation_class_tab(in_loop_cnt_3)
                             WHEN cv_cancel_class_1 THEN cv_major_division_50 --解約確定(自己都合)
                             WHEN cv_cancel_class_2 THEN cv_major_division_50 --解約確定(保険対応)
                             WHEN cv_cancel_class_3 THEN cv_major_division_30 --解約申請
                             WHEN cv_cancel_class_4 THEN cv_major_division_30 --解約申請(自己都合)
                             WHEN cv_cancel_class_5 THEN cv_major_division_30 --解約申請(保険対応)
                             WHEN cv_cancel_class_9 THEN cv_major_division_40 --解約キャンセル
                           END;
    ELSIF ( iv_proc_flag = cv_proc_flag_csv ) THEN
      --証書受領処理の場合
      lv_major_division := cv_major_division_60;
    END IF;
--
    -- リース物件テーブルロック取得(その他)
    OPEN lock_cur;
    FETCH lock_cur
    BULK COLLECT INTO  g_object_header_id_lock_tab  --物件内部ID
                      ,g_re_lease_times_ob_tab      --再リース回数
                      ,g_small_class_ob_tab         --小分類
    ;
    IF ( lock_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name7 )                       -- ステータスエラー
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --物件エラー対象
                                                         ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- 物件コード
                                                        )
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      RAISE global_api_expt;
    ELSE
      --物件テーブルのロックが正常に取得できている場合
      gb_lock_ob_flag := TRUE;
    END IF;
--
    --カーソルのクローズ
    CLOSE lock_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --当機能内で、行ロック取得済みの場合はスキップ
      IF ( gb_lock_ob_flag ) THEN
        NULL;
      ELSE
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_name8         -- テーブルロックエラー
                                                       ,cv_tkn_name7         -- トークン'TABLE_NAME'
                                                       ,cv_tkn_val9 )        -- リース物件テーブル
                                                       ,1
                                                       ,5000);
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      END IF;
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END lock_object_tbl_other;
--
  /**********************************************************************************
   * Procedure Name   : lock_object_hist_tbl
   * Description      : リース物件履歴テーブルロック取得処理(A-20)
   ***********************************************************************************/
  PROCEDURE lock_object_hist_tbl(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_object_hist_tbl'; -- プログラム名
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
    CURSOR lock_cur
    IS
      SELECT
              xoht.object_header_id
        FROM
              xxcff_object_histories  xoht  --リース物件履歴
       WHERE
              xoht.object_header_id = g_object_header_id_tab(in_loop_cnt_3)
         FOR UPDATE NOWAIT
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- リース物件履歴テーブルロック
    OPEN lock_cur;
    FETCH lock_cur
    BULK COLLECT INTO  g_object_header_id_lock_tab  --物件内部ID
    ;
    IF ( lock_cur%ROWCOUNT = 0 ) THEN
      NULL;
    ELSE
      --物件履歴テーブルのロックが正常に取得できている場合
      gb_lock_ob_hist_flag := TRUE;
    END IF;
--
    --カーソルのクローズ
    CLOSE lock_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --当機能内で、行ロック取得済みの場合はスキップ
      IF ( gb_lock_ob_hist_flag ) THEN
        NULL;
      ELSE
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_name8         -- テーブルロックエラー
                                                       ,cv_tkn_name7         -- トークン'TABLE_NAME'
                                                       ,cv_tkn_val10 )       -- リース物件履歴テーブル
                                                       ,1
                                                       ,5000);
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      END IF;
--
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END lock_object_hist_tbl;
--
  /**********************************************************************************
   * Procedure Name   : lock_ctrct_relation_tbl
   * Description      : リース契約関連テーブルロック取得処理(A-21)
   ***********************************************************************************/
  PROCEDURE lock_ctrct_relation_tbl(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_ctrct_relation_tbl'; -- プログラム名
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
    CURSOR lock_cur
    IS
      SELECT
              xcl.contract_line_id  --契約明細内部ID
        FROM
              xxcff_contract_headers  xch --リース契約
             ,xxcff_contract_lines    xcl --リース契約明細
             ,xxcff_pay_planning      xpp --リース支払計画
       WHERE
              xch.contract_header_id = xcl.contract_header_id                --契約内部ID
         AND  xcl.contract_line_id   = xpp.contract_line_id                  --契約明細内部ID
         AND  xch.re_lease_times     = g_re_lease_times_ob_tab(1)            --再リース回数(A-18,A-19で取得)
         AND  xcl.object_header_id   = g_object_header_id_tab(in_loop_cnt_3) --物件内部ID
         FOR UPDATE OF xcl.contract_line_id, xpp.contract_line_id NOWAIT
    ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- リース契約関連テーブル(リース契約明細テーブル、リース支払計画テーブル)のロック
    OPEN lock_cur;
    FETCH lock_cur
    BULK COLLECT INTO  g_contract_line_id_lock_tab  --契約明細内部ID
    ;
    --カーソルのクローズ
    CLOSE lock_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name8         -- テーブルロックエラー
                                                     ,cv_tkn_name7         -- トークン'TABLE_NAME'
                                                     ,cv_tkn_val13 )       -- リース契約関連
                                                     ,1
                                                     ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END lock_ctrct_relation_tbl;
--
  /**********************************************************************************
   * Procedure Name   : call_fa_common
   * Description      : FA共通関数起動処理(通常)処理(A-22)
   ***********************************************************************************/
  PROCEDURE call_fa_common(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_fa_common'; -- プログラム名
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
    --リース物件情報
    l_ob_rec                       xxcff_common3_pkg.object_data_rtype;
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
    -- リース物件情報設定
    l_ob_rec.object_header_id     := g_object_header_id_tab(in_loop_cnt_3);     -- 物件内部ID
    l_ob_rec.object_code          := g_object_code_tab(in_loop_cnt_3);          -- 物件コード
    l_ob_rec.lease_class          := g_lease_class_tab(in_loop_cnt_3);          -- リース種別
    l_ob_rec.lease_type           := g_lease_type_tab(in_loop_cnt_3);           -- リース区分
    l_ob_rec.re_lease_times       := g_re_lease_times_tab(in_loop_cnt_3);       -- 再リース回数
    l_ob_rec.po_number            := g_po_number_tab(in_loop_cnt_3);            -- 発注番号
    l_ob_rec.registration_number  := g_registration_number_tab(in_loop_cnt_3);  -- 登録番号
    l_ob_rec.age_type             := g_age_type_tab(in_loop_cnt_3);             -- 年式
    l_ob_rec.model                := g_model_tab(in_loop_cnt_3);                -- 機種
    l_ob_rec.serial_number        := g_serial_number_tab(in_loop_cnt_3);        -- 機番
    l_ob_rec.quantity             := g_quantity_tab(in_loop_cnt_3);             -- 数量
    l_ob_rec.manufacturer_name    := g_manufacturer_name_tab(in_loop_cnt_3);    -- メーカー名
    l_ob_rec.department_code      := g_department_code_tab(in_loop_cnt_3);      -- 管理部門コード
    l_ob_rec.owner_company        := g_owner_company_tab(in_loop_cnt_3);        -- 本社／工場
    l_ob_rec.installation_address := g_installation_address_tab(in_loop_cnt_3); -- 現設置場所
    l_ob_rec.installation_place   := g_installation_place_tab(in_loop_cnt_3);   -- 現設置先
    l_ob_rec.chassis_number       := g_chassis_number_tab(in_loop_cnt_3);       -- 車台番号
    l_ob_rec.re_lease_flag        := g_re_lease_flag_tab(in_loop_cnt_3);        -- 再リース要フラグ
    l_ob_rec.cancellation_type    := g_cancellation_type_tab(in_loop_cnt_3);    -- 解約区分
    l_ob_rec.cancellation_date    := g_cancellation_date_tab(in_loop_cnt_3);    -- 中途解約日
    l_ob_rec.dissolution_date     := g_dissolution_date_tab(in_loop_cnt_3);     -- 中途解約キャンセル日
    l_ob_rec.bond_acceptance_flag := g_bond_acceptance_flag_tab(in_loop_cnt_3); -- 証書受領フラグ(物件テーブル)
    l_ob_rec.bond_acceptance_date := g_bond_acceptance_date_tab(in_loop_cnt_3); -- 証書受領日
    l_ob_rec.expiration_date      := g_expiration_date_tab(in_loop_cnt_3);      -- 満了日
--    l_ob_rec.object_status        := g_object_status_tab(in_loop_cnt_3);        -- 物件ステータス
    l_ob_rec.active_flag          := g_active_flag_tab(in_loop_cnt_3);          -- 物件有効フラグ
    l_ob_rec.info_sys_if_date     := g_info_sys_if_date_tab(in_loop_cnt_3);     -- リース管理情報連携日
    l_ob_rec.generation_date      := g_generation_date_tab(in_loop_cnt_3);      -- 発生日
    l_ob_rec.customer_code        := g_customer_code_tab(in_loop_cnt_3);        -- 顧客コード
    -- 以下、WHOカラム情報
    l_ob_rec.created_by             := cn_created_by;              --作成者
    l_ob_rec.creation_date          := cd_creation_date;           --作成日
    l_ob_rec.last_updated_by        := cn_last_updated_by;         --最終更新者
    l_ob_rec.last_update_date       := cd_last_update_date;        --最終更新日
    l_ob_rec.last_update_login      := cn_last_update_login;       --最終更新ログイン
    l_ob_rec.request_id             := cn_request_id;              --要求ID
    l_ob_rec.program_application_id := cn_program_application_id;  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    l_ob_rec.program_id             := cn_program_id;              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    l_ob_rec.program_update_date    := cd_program_update_date;     -- ﾌﾟﾛｸﾞﾗﾑ更新日
--
    --共通関数 リース物件情報作成（バッチ） の呼出
    xxcff_common3_pkg.create_ob_bat(
      io_object_data_rec        => l_ob_rec          --リース物件情報
     ,ov_errbuf                 => lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode                => lv_retcode        -- リターン・コード             --# 固定 #
     ,ov_errmsg                 => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- 共通関数エラー
                                                    ,cv_tkn_name1                         -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val11 )                       -- リース物件情報作成（バッチ）
                                                    || cv_msg_part
                                                    || lv_errmsg                          -- ユーザー・エラー・メッセージ
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    ELSE
      --成功件数のインクリメント
      gn_normal_cnt := ( gn_normal_cnt + 1 );
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END call_fa_common;
--
  /**********************************************************************************
   * Procedure Name   : call_fa_common_other
   * Description      : FA共通関数起動処理(その他)処理(A-23)
   ***********************************************************************************/
  PROCEDURE call_fa_common_other(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    iv_proc_flag  IN  VARCHAR2,     --  証書受領フラグの取得元判別フラグ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_fa_common_other'; -- プログラム名
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
    --リース物件情報
    l_ob_rec                       xxcff_common3_pkg.object_data_rtype;
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
    -- リース物件情報設定
    l_ob_rec.object_header_id     := g_object_header_id_tab(in_loop_cnt_3);     -- 物件内部ID
    l_ob_rec.object_code          := g_object_code_tab(in_loop_cnt_3);          -- 物件コード
    l_ob_rec.lease_class          := g_lease_class_tab(in_loop_cnt_3);          -- リース種別
    l_ob_rec.lease_type           := g_lease_type_tab(in_loop_cnt_3);           -- リース区分
    l_ob_rec.re_lease_times       := g_re_lease_times_tab(in_loop_cnt_3);       -- 再リース回数
    l_ob_rec.po_number            := g_po_number_tab(in_loop_cnt_3);            -- 発注番号
    l_ob_rec.registration_number  := g_registration_number_tab(in_loop_cnt_3);  -- 登録番号
    l_ob_rec.age_type             := g_age_type_tab(in_loop_cnt_3);             -- 年式
    l_ob_rec.model                := g_model_tab(in_loop_cnt_3);                -- 機種
    l_ob_rec.serial_number        := g_serial_number_tab(in_loop_cnt_3);        -- 機番
    l_ob_rec.quantity             := g_quantity_tab(in_loop_cnt_3);             -- 数量
    l_ob_rec.manufacturer_name    := g_manufacturer_name_tab(in_loop_cnt_3);    -- メーカー名
    l_ob_rec.department_code      := g_department_code_tab(in_loop_cnt_3);      -- 管理部門コード
    l_ob_rec.owner_company        := g_owner_company_tab(in_loop_cnt_3);        -- 本社／工場
    l_ob_rec.installation_address := g_installation_address_tab(in_loop_cnt_3); -- 現設置場所
    l_ob_rec.installation_place   := g_installation_place_tab(in_loop_cnt_3);   -- 現設置先
    l_ob_rec.chassis_number       := g_chassis_number_tab(in_loop_cnt_3);       -- 車台番号
    l_ob_rec.re_lease_flag        := g_re_lease_flag_tab(in_loop_cnt_3);        -- 再リース要フラグ
    l_ob_rec.cancellation_type    := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_cancellation_type_tab(in_loop_cnt_3)
                                       WHEN  cv_proc_flag_tbl
                                         THEN
                                           CASE g_cancellation_class_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_1 THEN cv_cancel_type_1
                                             WHEN  cv_cancel_class_2 THEN cv_cancel_type_2
                                             WHEN  cv_cancel_class_3 THEN g_cancellation_type_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_4 THEN cv_cancel_type_1
                                             WHEN  cv_cancel_class_5 THEN cv_cancel_type_2
                                             WHEN  cv_cancel_class_9 THEN NULL
                                           END
                                     END;                                       -- 解約区分
    l_ob_rec.cancellation_date    := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_cancellation_date_tab(in_loop_cnt_3)
                                       WHEN  cv_proc_flag_tbl
                                         THEN
                                           CASE g_cancellation_class_tab(in_loop_cnt_3)
-- 2011/12/26 Ver.1.8 A.Shirakawa MOD Start
--                                             WHEN  cv_cancel_class_1 THEN g_init_rec.process_date
--                                             WHEN  cv_cancel_class_2 THEN g_init_rec.process_date
                                             WHEN  cv_cancel_class_1 THEN g_cancellation_date_xmw_tab(in_loop_cnt_3)  --ﾒﾝﾃﾅﾝｽﾃｰﾌﾞﾙより取得
                                             WHEN  cv_cancel_class_2 THEN g_cancellation_date_xmw_tab(in_loop_cnt_3)  --ﾒﾝﾃﾅﾝｽﾃｰﾌﾞﾙより取得
-- 2011/12/26 Ver.1.8 A.Shirakawa MOD End
                                             WHEN  cv_cancel_class_3 THEN g_cancellation_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_4 THEN g_cancellation_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_5 THEN g_cancellation_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_9 THEN g_cancellation_date_tab(in_loop_cnt_3)
                                           END
                                     END;                                       -- 中途解約日
    l_ob_rec.dissolution_date     :=  CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_dissolution_date_tab(in_loop_cnt_3)
                                       WHEN  cv_proc_flag_tbl
                                         THEN
                                           CASE g_cancellation_class_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_1 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_2 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_3 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_4 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_5 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_9 THEN g_init_rec.process_date
                                           END
                                     END;                                       -- 中途解約キャンセル日
    l_ob_rec.bond_acceptance_flag := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_bond_acceptance_flag_xmw_tab(in_loop_cnt_3)  --ﾒﾝﾃﾅﾝｽﾃｰﾌﾞﾙより取得
                                       WHEN  cv_proc_flag_tbl
                                         THEN g_bond_acceptance_flag_tab(in_loop_cnt_3)      --物件テーブルより取得
                                     END;                                       --証書受領フラグ
    l_ob_rec.bond_acceptance_date := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_init_rec.process_date
                                       WHEN  cv_proc_flag_tbl
                                         THEN g_bond_acceptance_date_tab(in_loop_cnt_3)
                                     END;                                       -- 証書受領日
    l_ob_rec.expiration_date      := g_expiration_date_tab(in_loop_cnt_3);      -- 満了日
    l_ob_rec.object_status        := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_tbl
                                         THEN
                                           CASE g_cancellation_class_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_3 THEN cv_ob_status_108
                                             WHEN  cv_cancel_class_4 THEN cv_ob_status_108
                                             WHEN  cv_cancel_class_5 THEN cv_ob_status_108
                                           END
                                     END;                                       -- 物件ステータス
    l_ob_rec.active_flag          := g_active_flag_tab(in_loop_cnt_3);          -- 物件有効フラグ
    l_ob_rec.info_sys_if_date     := g_info_sys_if_date_tab(in_loop_cnt_3);     -- リース管理情報連携日
    l_ob_rec.generation_date      := g_generation_date_tab(in_loop_cnt_3);      -- 発生日
    l_ob_rec.customer_code        := g_customer_code_tab(in_loop_cnt_3);        -- 顧客コード
    -- 以下、WHOカラム情報
    l_ob_rec.created_by             := cn_created_by;              --作成者
    l_ob_rec.creation_date          := cd_creation_date;           --作成日
    l_ob_rec.last_updated_by        := cn_last_updated_by;         --最終更新者
    l_ob_rec.last_update_date       := cd_last_update_date;        --最終更新日
    l_ob_rec.last_update_login      := cn_last_update_login;       --最終更新ログイン
    l_ob_rec.request_id             := cn_request_id;              --要求ID
    l_ob_rec.program_application_id := cn_program_application_id;  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    l_ob_rec.program_id             := cn_program_id;              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    l_ob_rec.program_update_date    := cd_program_update_date;     -- ﾌﾟﾛｸﾞﾗﾑ更新日
--
    --共通関数 リース物件情報作成 の呼出
    xxcff_common3_pkg.create_ob_det(
      io_object_data_rec        => l_ob_rec                --リース物件情報
     ,iv_exce_mode              => CASE g_small_class_ob_tab(1) --【A-19】にて取得した小分類
                                     WHEN cv_small_class_7  THEN cv_exce_mode_adj
                                     WHEN cv_small_class_8  THEN cv_exce_mode_dis
                                     WHEN cv_small_class_9  THEN cv_exce_mode_can
                                     WHEN cv_small_class_10 THEN cv_exce_mode_chg
                                   END
     ,ov_errbuf                 => lv_errbuf               -- エラー・メッセージ           --# 固定 #
     ,ov_retcode                => lv_retcode              -- リターン・コード             --# 固定 #
     ,ov_errmsg                 => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- 共通関数エラー
                                                    ,cv_tkn_name1                         -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val14 )                       -- リース物件情報作成
                                                    || cv_msg_part
                                                    || lv_errmsg                          -- ユーザー・エラー・メッセージ
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    ELSE
      --成功件数のインクリメント
      gn_normal_cnt := ( gn_normal_cnt + 1 );
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END call_fa_common_other;
--
  /**********************************************************************************
   * Procedure Name   : call_facmn_chk_location
   * Description      : FA共通関数(事業所マスタチェック)処理(A-24)
   ***********************************************************************************/
  PROCEDURE call_facmn_chk_location(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_facmn_chk_location'; -- プログラム名
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
    ln_location_id  NUMBER(15);
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 事業所マスタの組み合わせチェック
    xxcff_common1_pkg.chk_fa_location(
      iv_segment2     => g_department_code_tab(in_loop_cnt_3)  -- 管理部門コード
     ,iv_segment5     => g_owner_company_tab(in_loop_cnt_3)    -- 本社工場
     ,on_location_id  => ln_location_id                        -- 事業所ID
     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff  -- XXCFF
                                                    ,cv_msg_name1    -- 共通関数エラー
                                                    ,cv_tkn_name1    -- トークン'FUNC_NAME'
                                                    ,cv_tkn_val7  )  -- 事業所マスタチェック
                                                    || cv_msg_part
                                                    || lv_errmsg     -- 共通関数内ｴﾗｰﾒｯｾｰｼﾞ
                                                    ,1
                                                    ,5000)
      ;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END call_facmn_chk_location;
--
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : check_cancellation_date
   * Description      : 解約日チェック処理(A-25)
   ***********************************************************************************/
  PROCEDURE check_cancellation_date(
    in_loop_cnt_3 IN  NUMBER,       --  ループカウンタ3
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cancellation_date'; -- プログラム名
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
    lv_warn_msg                VARCHAR2(5000); --警告メッセージ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 解約種別が解約確定、且つCSVファイルの解約日が未設定の場合(不正)
    IF ( ( g_cancellation_class_tab(in_loop_cnt_3) IN ( cv_cancel_class_1, cv_cancel_class_2 ) )
     AND ( g_cancellation_date_xmw_tab(in_loop_cnt_3) IS NULL ) )
    THEN
      --解約日未設定チェックエラー
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                      -- XXCFF
                                                      ,cv_msg_name13                       -- 解約日未設定チェックエラー
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --物件エラー対象
                                                         ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- 物件コード
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    -- 解約種別が解約確定以外、且つCSVファイルの解約日を設定の場合(不正)
    IF ( ( ( g_cancellation_class_tab(in_loop_cnt_3) IS NULL )
     OR    ( g_cancellation_class_tab(in_loop_cnt_3) NOT IN ( cv_cancel_class_1, cv_cancel_class_2 ) ) )
     AND   ( g_cancellation_date_xmw_tab(in_loop_cnt_3) IS NOT NULL ) )
    THEN
      --解約日設定チェックエラー
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                      -- XXCFF
                                                      ,cv_msg_name14                       -- 解約日設定チェックエラー
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --物件エラー対象
                                                         ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- 物件コード
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    IF ( ( g_cancellation_date_xmw_tab(in_loop_cnt_3) < gd_period_date_from )
     OR  ( g_cancellation_date_xmw_tab(in_loop_cnt_3) > g_init_rec.process_date ) )
    THEN
      --解約日エラー
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                      -- XXCFF
                                                      ,cv_msg_name16                       -- 解約日エラー
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --物件エラー対象
                                                         ,cv_tkn_name4                     --トークン'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- 物件コード
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warn_msg
      );
      --エラーフラグをTRUEにする
      gb_err_flag := TRUE;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END check_cancellation_date;
--
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER,       -- 1.ファイルID
    iv_file_format  IN   VARCHAR2,     -- 2.ファイルフォーマット
    ov_errbuf       OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT  VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- ループ時のカウント
    ln_loop_cnt_1  NUMBER;
    ln_loop_cnt_2  NUMBER;
--
    --データ取得処理内(A-1?A-6)でエラーが発生した件数をカウント
    ln_error_cnt   PLS_INTEGER;
--
    --移動・修正項目の存在チェック用
    l_all_null_tbl         g_mst_check_ttype; --移動・修正項目 有:1 / 無:0
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
    gn_target_cnt               := 0;
    gn_normal_cnt               := 0;
    gn_error_cnt                := 0;
    gn_warn_cnt                 := 0;
--
    ln_loop_cnt_1               := 0;
    ln_loop_cnt_2               := 0;
--
    ln_error_cnt                := 0;
--
    gb_lock_ob_flag             := FALSE; --ロックフラグ(物件):FALSE
    gb_lock_ob_hist_flag        := FALSE; --ロックフラグ(物件履歴):FALSE
    gb_err_flag                 := FALSE; --エラーフラグ:FALSE
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- ============================================
    -- A-1．初期処理
    -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-1の呼出(submain)');--私用■
--
    -- 共通初期処理(初期値情報の取得)の呼び出し
    init(
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．妥当性チェック用の値取得
    -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-2の呼出(submain)');--私用■
--
    get_for_validation(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．ファイルアップロードIFデータ取得
    -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-3の呼出(submain)');--私用■
--
    get_upload_data(
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --メインループ①
    <<MAIN_LOOP_1>>
      FOR ln_loop_cnt_1 IN g_file_upload_if_data_tab.FIRST .. g_file_upload_if_data_tab.LAST LOOP --ループスタート
--fnd_file.put_line(fnd_file.log,'■debug:'||'メインループ①開始');--私用■
--
        --１行目の場合カラム行の処理となる為、スキップして２行目の処理に遷移する
        IF ( ln_loop_cnt_1 <> 1 ) THEN
          --メインループ②カウンタのリセット
          ln_loop_cnt_2 := 0;
--
          --メインループ②
          <<MAIN_LOOP_2>>
          FOR ln_loop_cnt_2 IN g_column_desc_tab.FIRST .. g_column_desc_tab.LAST LOOP
--fnd_file.put_line(fnd_file.log,'■debug:'||'メインループ②開始');--私用■
--
            -- ============================================
            -- A-4．デリミタ文字項目分割
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-4の呼出(submain)');--私用■
            divide_item(
               ln_loop_cnt_1     -- ループカウンタ1
              ,ln_loop_cnt_2     -- ループカウンタ2
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
            IF ( gb_err_flag ) THEN
              EXIT MAIN_LOOP_2;
            END IF;
--
            --項目がNULLではない場合のみ、A-5のチェックを行う
            IF ( g_load_data_tab(ln_loop_cnt_2) IS NOT NULL ) THEN
              -- ============================================
              -- A-5．項目値チェック
              -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-5の呼出(submain)');--私用■
              check_item_value(
                 ln_loop_cnt_2     -- ループカウンタ2
                ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
                ,lv_retcode        -- リターン・コード             --# 固定 #
                ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
--fnd_file.put_line(fnd_file.log,'■debug:'||'メインループ②の終端');--私用■
          END LOOP MAIN_LOOP_2;
--
          --エラーフラグがTRUEならA-6の処理をスキップ
          IF ( gb_err_flag = FALSE ) THEN
-- 0000654 2009/07/31 ADD START
            --物件コードがNULLの場合、A-6の処理をスキップ
            IF ( g_csv_object_code IS NOT NULL ) THEN
-- 0000654 2009/07/31 ADD END
            -- ============================================
            -- A-6．リース物件メンテナンステーブル作成
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-6の呼出(submain)');--私用■
              ins_maintenance_wk(
                 in_file_id        -- 1.ファイルID
                ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
                ,lv_retcode        -- リターン・コード             --# 固定 #
                ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
              );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
-- 0000654 2009/07/31 ADD START
            END IF;
-- 0000654 2009/07/31 ADD END
          END IF;
--
          --エラーフラグがTRUE
          IF ( gb_err_flag ) THEN
            --エラー件数をプラス１
            ln_error_cnt := ( ln_error_cnt + 1 );
            --次処理継続の為、エラーフラグを戻す
            gb_err_flag := FALSE;
          ELSE
            --エラーでない場合、移動・修正項目のNULLチェック
            IF ( ( g_load_data_tab(2)  IS NOT NULL )    --本社工場
              OR ( g_load_data_tab(3)  IS NOT NULL )    --管理部門
              OR ( g_load_data_tab(4)  IS NOT NULL )    --登録番号
              OR ( g_load_data_tab(5)  IS NOT NULL )    --発注番号
              OR ( g_load_data_tab(6)  IS NOT NULL )    --メーカー名
              OR ( g_load_data_tab(7)  IS NOT NULL )    --機種
              OR ( g_load_data_tab(8)  IS NOT NULL )    --機番
              OR ( g_load_data_tab(9)  IS NOT NULL )    --年式
              OR ( g_load_data_tab(10) IS NOT NULL )    --数量
              OR ( g_load_data_tab(11) IS NOT NULL )    --車台番号
              OR ( g_load_data_tab(12) IS NOT NULL )    --現設置場所
              OR ( g_load_data_tab(13) IS NOT NULL ) )  --現設置先
             THEN
              --移動・修正項目が1つでも存在する場合
              l_all_null_tbl( ln_loop_cnt_1 - 1 ) := 1;
            ELSE
              --移動・修正項目が全てNULLの場合
              l_all_null_tbl( ln_loop_cnt_1 - 1 ) := 0;
            END IF;
          END IF;
--
        END IF; --１行目(カラム行)の場合、処理をスキップ_終了
--
--fnd_file.put_line(fnd_file.log,'■debug:'||'メインループ①の終端');--私用■
    END LOOP MAIN_LOOP_1;
--
    --1件でもエラーが存在する場合は強制終了
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7．リース物件メンテナンステーブル取得
    -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-7の呼出(submain)');--私用■
--
    get_maintenance_wk(
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --A-7で取得件数が0件の場合、以後の処理をスキップ
    IF ( g_object_header_id_tab.COUNT <> 0 ) THEN
--
      -- ============================================
      -- A-8．リース物件存在チェック
      -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-8の呼出(submain)');--私用■
--
      check_object_exist(
         lv_errbuf         -- エラー・メッセージ           --# 固定 #
        ,lv_retcode        -- リターン・コード             --# 固定 #
        ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      --メインループ③
      <<MAIN_LOOP_3>>
      FOR ln_loop_cnt_3 IN g_object_code_tab.FIRST .. g_object_code_tab.LAST LOOP
--fnd_file.put_line(fnd_file.log,'■debug:'||'メインループ③開始');--私用■
        --移動、修正用の項目がNOT NULLの場合
        IF ( l_all_null_tbl(ln_loop_cnt_3) = 1 ) THEN
--
          --対象件数のインクリメント
          gn_target_cnt := ( gn_target_cnt + 1 );
--
          -- ============================================
          -- A-9．マスタチェック(本社工場)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-9の呼出(submain)');--私用■
--
          check_mst_owner_company(
             ln_loop_cnt_3     -- ループカウンタ3
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-10．マスタチェック(管理部門)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-10の呼出(submain)');--私用■
--
          check_mst_department(
             ln_loop_cnt_3     -- ループカウンタ3
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-24．FA共通関数(事業所マスタチェック)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-24の呼出(submain)');--私用■
--
          call_facmn_chk_location(
             ln_loop_cnt_3     -- ループカウンタ3
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-12．マスタチェック(リース種別)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-12の呼出(submain)');--私用■
--
          check_mst_lease_class(
             ln_loop_cnt_3     -- ループカウンタ3
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-14．妥当性チェック(証書受領)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-14の呼出(submain)');--私用■
--
          validate_bond_accep_flag(
             ln_loop_cnt_3     -- ループカウンタ3
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          --エラーフラグがTRUEなら解約種別のチェックまでスキップ
          IF ( gb_err_flag = FALSE ) THEN
--
            -- ============================================
            -- A-18．リース物件テーブルロック取得(通常)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-18の呼出(submain)');--私用■
--
            lock_object_tbl(
               ln_loop_cnt_3     -- ループカウンタ3
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            --物件ステータスが「未契約」の時のみ、A-20の処理を行う
            IF ( g_object_status_tab(ln_loop_cnt_3) = cv_ob_status_101 ) THEN
              -- ============================================
              -- A-20．リース物件履歴テーブルロック取得
              -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-20の呼出(submain)');--私用■
--
              lock_object_hist_tbl(
                 ln_loop_cnt_3     -- ループカウンタ3
                ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
                ,lv_retcode        -- リターン・コード             --# 固定 #
                ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
            -- ============================================
            -- A-22．FA共通関数起動処理(通常)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-22の呼出(submain)');--私用■
--
            call_fa_common(
               ln_loop_cnt_3     -- ループカウンタ3
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;  --エラーフラグがTRUE
        END IF;  --移動、修正用の項目がNOT NULLの場合
--
        --エラーフラグがTRUEの場合、エラーカウンタをインクリメント
        IF ( gb_err_flag ) THEN
          gn_error_cnt := ( gn_error_cnt + 1 );
          gb_err_flag  := FALSE; --解約種別処理の為、初期化
        END IF;
--
        --解約種別のチェック
-- 2011/12/26 Ver.1.8 A.Shirakawa MOD Start
--        IF ( g_cancellation_class_tab(ln_loop_cnt_3) IS NOT NULL ) THEN
        IF (( g_cancellation_class_tab(ln_loop_cnt_3) IS NOT NULL )            --CSVファイルの解約種別が設定されている
         OR ( g_cancellation_date_xmw_tab(ln_loop_cnt_3) IS NOT NULL ) ) THEN  --CSVファイルの解約日が設定されている
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
--
          --対象件数のインクリメント
          gn_target_cnt := ( gn_target_cnt + 1 );
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
--
          -- ============================================
          -- A-25．解約日チェック
          -- ============================================
--
          check_cancellation_date(
             ln_loop_cnt_3     -- ループカウンタ3
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          --解約種別≠NULLの場合、以降の解約関連処理を続行する
          --解約種別＝NULL（かつ解約日≠NULL）の場合、A-25でエラーと判定されており、該当データの解約関連処理をSKIPする
          IF ( g_cancellation_class_tab(ln_loop_cnt_3) IS NOT NULL ) THEN
--
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
          -- ============================================
          -- A-11．マスタチェック(解約種別)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-11の呼出(submain)');--私用■
--
          check_mst_cancellation_class(
             ln_loop_cnt_3     -- ループカウンタ3
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          --解約種別が「解約キャンセル」の時、A-14の処理を実行
          IF ( g_cancellation_class_tab(ln_loop_cnt_3) = cv_cancel_class_9 ) THEN
            -- ============================================
            -- A-14．妥当性チェック(証書受領)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-14の呼出(submain)');--私用■
--
            validate_bond_accep_flag(
               ln_loop_cnt_3     -- ループカウンタ3
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ============================================
          -- A-16．解約キャンセルチェック
          -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-16の呼出(submain)');--私用■
--
          check_cancellation_cancel(
             ln_loop_cnt_3     -- ループカウンタ3
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          --解約種別が解約確定・契約明細内部IDがNULLではない場合、A-17の処理を行う
          IF ( ( g_cancellation_class_tab(ln_loop_cnt_3) IN ( cv_cancel_class_1, cv_cancel_class_2 ) )
           AND ( g_contract_line_id_tab(ln_loop_cnt_3) IS NOT NULL ) ) THEN
            -- ============================================
            -- A-17．FA共通関数(支払照合済チェック)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-17の呼出(submain)');--私用■
--
            call_facmn_chk_paychked(
               ln_loop_cnt_3     -- ループカウンタ3
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          --エラーフラグがTRUEなら証書受領のチェックまでスキップ
          IF ( gb_err_flag = FALSE ) THEN
            -- ============================================
            -- A-19．リース物件テーブルロック取得(その他)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-19の呼出(submain)');--私用■
--
            lock_object_tbl_other(
               ln_loop_cnt_3     -- ループカウンタ3
              ,cv_proc_flag_tbl  -- 解約種別/証書受領フラグの処理判別フラグ
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ============================================
            -- A-20．リース物件履歴テーブルロック取得
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-20の呼出(submain)');--私用■
--
            lock_object_hist_tbl(
               ln_loop_cnt_3     -- ループカウンタ3
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            --解約種別が解約確定の場合、A-21の処理を行う
            IF ( g_cancellation_class_tab(ln_loop_cnt_3) IN ( cv_cancel_class_1, cv_cancel_class_2 ) ) THEN
              -- ============================================
              -- A-21．リース契約関連テーブルロック取得
              -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-21の呼出(submain)');--私用■
--
              lock_ctrct_relation_tbl(
                 ln_loop_cnt_3     -- ループカウンタ3
                ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
                ,lv_retcode        -- リターン・コード             --# 固定 #
                ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
            END IF; --解約種別が解約確定の場合
--
            -- ============================================
            -- A-23．FA共通関数起動処理(その他)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-23の呼出(submain)');--私用■
--
            call_fa_common_other(
               ln_loop_cnt_3     -- ループカウンタ3
              ,cv_proc_flag_tbl  -- 解約種別/証書受領フラグの処理判別フラグ
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;  --エラーフラグがTRUE
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD Start
          END IF;  --解約種別≠NULL
-- 2011/12/26 Ver.1.8 A.Shirakawa ADD End
        END IF;  --解約種別のチェック
--
        --エラーフラグがTRUEの場合、エラーカウンタをインクリメント
        IF ( gb_err_flag ) THEN
          gn_error_cnt := ( gn_error_cnt + 1 );
          gb_err_flag  := FALSE; --証書受領処理の為、初期化
        END IF;
--
        --証書受領のチェック
        IF ( g_bond_acceptance_flag_xmw_tab(ln_loop_cnt_3) IS NOT NULL ) THEN
          IF ( g_bond_acceptance_flag_xmw_tab(ln_loop_cnt_3) <> cv_bond_acceptance_flag_0 ) THEN
--
            --対象件数のインクリメント
            gn_target_cnt := ( gn_target_cnt + 1 );
--
            -- ============================================
            -- A-13．マスタチェック(証書受領)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-13の呼出(submain)');--私用■
--
            check_mst_bond_accep_flag(
               ln_loop_cnt_3     -- ループカウンタ3
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ============================================
            -- A-14．妥当性チェック(証書受領)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-14の呼出(submain)');--私用■
--
            validate_bond_accep_flag(
               ln_loop_cnt_3     -- ループカウンタ3
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ============================================
            -- A-15．FA共通関数(物件コード解約チェック)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-15の呼出(submain)');--私用■
--
            call_facmn_chk_object_term(
               ln_loop_cnt_3     -- ループカウンタ3
              ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
              ,lv_retcode        -- リターン・コード             --# 固定 #
              ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            --エラーフラグがTRUEなら処理をスキップ
            IF ( gb_err_flag = FALSE ) THEN
              -- ============================================
              -- A-19．リース物件テーブルロック取得(その他)
              -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-19(5/5)の呼出(submain)');--私用■
--
              lock_object_tbl_other(
                 ln_loop_cnt_3     -- ループカウンタ3
                ,cv_proc_flag_csv  --解約種別/証書受領フラグの処理判別フラグ
                ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
                ,lv_retcode        -- リターン・コード             --# 固定 #
                ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ============================================
              -- A-20．リース物件履歴テーブルロック取得
              -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-20(5/5)の呼出(submain)');--私用■
--
              lock_object_hist_tbl(
                 ln_loop_cnt_3     -- ループカウンタ3
                ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
                ,lv_retcode        -- リターン・コード             --# 固定 #
                ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ============================================
              -- A-23．FA共通関数起動処理(その他)
              -- ============================================
--fnd_file.put_line(fnd_file.log,'■debug:'||'A-23(5/5)の呼出(submain)');--私用■
--
              call_fa_common_other(
                 ln_loop_cnt_3     -- ループカウンタ3
                ,cv_proc_flag_csv  -- 解約種別/証書受領フラグの処理判別フラグ
                ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
                ,lv_retcode        -- リターン・コード             --# 固定 #
                ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
--
            END IF; --エラーフラグがTRUE
          END IF; --証書チェック
        END IF; --証書受領のNULLチェック
--
        --エラーフラグがTRUEの場合、エラーカウンタをインクリメント
        IF ( gb_err_flag ) THEN
          gn_error_cnt := ( gn_error_cnt + 1 );
          gb_err_flag  := FALSE; --移動・修正処理の為、初期化
        END IF;
--fnd_file.put_line(fnd_file.log,'■debug:'||'メインループ③の終端');--私用■
      END LOOP MAIN_LOOP_3;
--
    ELSE
      --A-7まで処理が遷移し取得件数が0件の場合、テーブルの紐付けがおかしい為エラー
      gn_error_cnt := gn_target_cnt;
    END IF;  --A-7で取得件数が0件の場合
--
    --1件でもエラーが存在する場合は強制終了
    IF ( gn_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ***
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
    in_file_id       IN    NUMBER,          -- 1.ファイルID(必須)
    iv_file_format   IN    VARCHAR2         -- 2.ファイルフォーマット(必須)
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
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
      ,iv_which   => cv_file_type_out
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
       in_file_id      -- 1.ファイルID
      ,iv_file_format  -- 2.ファイルフォーマット
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ============================================
    -- A-50．終了処理
    -- ============================================
--
    IF (  lv_retcode <> cv_status_normal ) THEN
      --①正常以外の場合、ロールバックを発行
      ROLLBACK;
    ELSE
      --正常の場合
      BEGIN
        --②リース物件メンテナンスワーク(物件メンテナンスワーク)を削除
        DELETE FROM
          xxcff_maintenance_work  --リース物件メンテナンスワーク(物件メンテナンスワーク)
        WHERE
          file_id = in_file_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --③メッセージの設定
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- 'XXCFF'
                                                         ,cv_msg_name11             -- 削除エラー
                                                         ,cv_tkn_name7              -- トークン'TABLE_NAME'
                                                         ,cv_tkn_val16              -- 物件メンテナンスワーク
                                                         ,cv_tkn_name8              -- トークン'INFO'
                                                         ,SUBSTRB(SQLERRM,1,2000) ) -- メッセージ
                                                         ,1
                                                         ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          RAISE global_api_others_expt;
      END;
    END IF;
--
      BEGIN
        --④ファイルアップロードI/Fテーブルを削除
        DELETE FROM
          xxccp_mrp_file_ul_interface  --ファイルアップロードI/Fテーブル
        WHERE
          file_id = in_file_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --⑤メッセージの設定
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- 'XXCFF'
                                                         ,cv_msg_name11             -- 削除エラー
                                                         ,cv_tkn_name7              -- トークン'TABLE_NAME'
                                                         ,cv_tkn_val17              -- ファイルアップロードI/Fテーブル
                                                         ,cv_tkn_name8              -- トークン'INFO'
                                                         ,SUBSTRB(SQLERRM,1,2000) ) -- メッセージ
                                                         ,1
                                                         ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          RAISE global_api_others_expt;
      END;
      --⑥コミットを発行
      IF ( lv_retcode <> cv_status_normal ) THEN
        COMMIT;
      END IF;
--
    --⑦共通のログメッセージの出力
    -- ===============================================
    -- エラー時の出力件数設定
    -- ===============================================
    IF (( lv_retcode <> cv_status_normal ) OR ( gn_error_cnt <> 0 )) THEN
      -- 成功件数にゼロ件をセットする
      gn_normal_cnt := 0;
--
      --強制終了した場合(エラーになった処理がエラーカウントにインクリメントされていない)
      IF ( gn_error_cnt = 0 ) THEN
        IF ( gn_target_cnt = 0 ) THEN  --対象件数が未取得の場合
          NULL;
        ELSE
          gn_error_cnt := 1;
          gn_warn_cnt  := ( gn_target_cnt - gn_error_cnt );
        END IF;
      ELSE
        --スキップ件数をセットする
        gn_warn_cnt   := ( gn_target_cnt - gn_error_cnt );
      END IF;
    END IF;
--
    -- ===============================================================
    -- 共通のログメッセージの出力
    -- ===============================================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_name30
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_name31
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_name32
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_name33
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --共通のログメッセージの出力終了
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --終了メッセージの設定、出力(⑧,⑨)
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --
    --ステータスセット
    retcode := lv_retcode;
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
END XXCFF004A30C;
/