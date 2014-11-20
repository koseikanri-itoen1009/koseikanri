CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A01C (body)
 * Description      : 納品データの取込を行う
 * MD.050           : HHT納品データ取込 (MD050_COS_001_A01)
 * Version          : 1.25
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  dlv_data_receive       納品データ抽出(A-1)
 *  data_check             データ妥当性チェック(A-2)
 *  error_data_register    エラーデータ登録(A-3)
 *  header_data_register   納品ヘッダテーブルへデータ登録(A-4)
 *  lines_data_register    納品明細テーブルへデータ登録(A-5)
 *  work_data_delete       ワークテーブルレコード削除(A-6)
 *  table_lock             テーブルロック(A-7)
 *  dlv_data_delete        納品ヘッダ・明細テーブルレコード削除(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/18    1.0   S.Miyakoshi      新規作成
 *  2009/02/03    1.1   S.Miyakoshi      [COS_003]百貨店HHT区分変更に対応
 *                                       [COS_004]エラーリストへの連携データの不具合発生に対応
 *  2009/02/05    1.2   S.Miyakoshi      [COS_034]品目IDの抽出項目を変更
 *  2009/02/20    1.3   S.Miyakoshi      パラメータのログファイル出力対応
 *  2009/02/26    1.4   S.Miyakoshi      従業員の履歴管理対応(xxcos_rs_info_v)
 *  2009/04/03    1.5   T.Kitajima       [T1_0247]HHTエラーリスト登録データ不正対応
 *                                       [T1_0256]保管場所取得方法修正対応
 *  2009/04/06    1.6   T.Kitajima       [T1_0329]TASK登録エラー対応
 *  2009/04/09    1.7   N.Maeda          [T1_0465]顧客名称、拠点名称の桁数制御追加
 *  2009/04/10    1.8   T.Kitajima       [T1_0248]百貨店条件変更
 *  2009/04/10    1.9   N.Maeda          [T1_0257]リソースid取得テーブル変更
 *  2009/04/14    1.10  T.Kitajima       [T1_0344]成績者コード、納品者コードチェック仕様変更
 *  2009/04/20    1.11  T.Kitajima       [T1_0592]百貨店画面種別チェック削除
 *  2009/05/01    1.12  T.Kitajima       [T1_0268]CHAR項目のTRIM対応
 *  2009/05/15    1.13  N.Maeda          [T1_1007]エラーデータ登録値(受注No.(HHT))の変更
 *  2009/05/15    1.14  N.Maeda          [T1_0752]訪問有効情報登録共通関数の引数(訪問日時)を修正
 *                                       [T1_1011]エラーリスト出力用拠点名称の取得条件変更
 *                                       [T1_0977]従業員マスタと顧客マスタの取得分割
 *  2009/09/01    1.15  N.Maeda          [0000929]リソースID取得条件変更[成績者⇒納品者]
 *                                                H/C妥当性チェックの実行条件修正
 *  2009/10/01    1.16  N.Maeda          [0001378]エラーリスト登録時登録桁数指定
 *  2009/10/30    1.17  M.Sano           [0001373]参照View変更[xxcos_rs_info_v ⇒ xxcos_rs_info2_v]
 *  2009/11/25    1.18  N.Maeda          [E_本稼動_00053] H/Cの整合性チェック削除
 *  2009/12/01    1.19  M.Sano           [E_本稼動_00234] 成績者、納品者の妥当性チェック修正
 *  2009/12/10    1.20  M.Sano           [E_本稼動_00108] 共通関数＜会計期間情報取得＞異常終了時の処理修正
 *  2010/01/18    1.21  M.Uehara         [E_本稼動_01128] カード売区分設定時のカード会社存在チェック追加
 *  2010/01/27    1.22  N.Maeda          [E_本稼動_01321] カード会社取得済配列設定
 *  2010/01/27    1.23  N.Maeda          [E_本稼動_01191] 処理起動モード3(納品ワークパージ)を追加
 *  2010/02/04    1.24  Y.Kuboshima      [E_T4_00195] 会計カレンダをAR ⇒ INVに修正
 *  2011/02/03    1.25  Y.Kanami         [E_本稼動_02624] データ妥当性チェックの顧客情報取得時の条件追加
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- クイックコード取得エラー
  lookup_types_expt EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS001A01C';         -- パッケージ名
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';                -- アプリケーション名
--
  -- プロファイル
  -- XXCOS:納品データ取込パージ処理日算出基準日数
  cv_prf_purge_date  CONSTANT VARCHAR2(50)  := 'XXCOS1_DLV_PURGE_DATE';
  -- XXCOI:在庫組織コード
  cv_prf_orga_code   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';
  -- XXCOS:MAX日付
  cv_prf_max_date    CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';
--
  -- エラーコード
  cv_msg_lock        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';     -- ロックエラー
  cv_msg_nodata      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';     -- 対象データ無しエラー
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';     -- プロファイル取得エラー
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';     -- XXCOS:MAX日付
  cv_msg_lookup      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';     -- 参照コードマスタ
  cv_msg_get         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10001';     -- データ抽出エラーメッセージ
  cv_msg_mst         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';     -- マスタチェックエラー
  cv_msg_disagree    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10003';     -- 成績者の所属拠点エラー
  cv_msg_belong      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10004';     -- 納品者の所属拠点エラー
  cv_msg_use         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10005';     -- 項目使用不可エラー
  cv_msg_status      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10006';     -- 顧客ステータスエラー
  cv_msg_base        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10008';     -- 顧客の売上拠点コードエラー
  cv_msg_class       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10009';     -- 入力区分・業態小分類整合性エラー
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--  cv_msg_period      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10010';     -- 納品日AR会計期間エラー
  cv_msg_period      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10010';     -- 納品日取込対象期間外エラー
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
  cv_msg_adjust      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10011';     -- 納品・検収日付整合性エラー
  cv_msg_future      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10012';     -- 納品日未来日エラー
  cv_msg_scope       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10013';     -- 検収日範囲エラー
  cv_msg_time        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10014';     -- 時間形式エラー
  cv_msg_object      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10015';     -- 品目売上対象区分エラー
  cv_msg_item        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10017';     -- 品目ステータスエラー
  cv_msg_convert     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10018';     -- 基準数量換算エラー
  cv_msg_vd          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10019';     -- VD情報必須エラー
  cv_msg_colm        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10020';     -- コラムNo不一致エラー
  cv_msg_hc          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10021';     -- H/C不一致エラー
  cv_msg_add         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10022';     -- データ追加エラーメッセージ
  cv_msg_del         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10023';     -- データ削除エラーメッセージ
  cv_msg_orga        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10024';     -- 在庫組織ID取得エラー
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10025';     -- 業務処理日取得エラー
  cv_msg_del_h       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10026';     -- ヘッダ削除件数
  cv_msg_del_l       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10027';     -- 明細削除件数
  cv_msg_para        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10028';     -- パラメータ出力メッセージ
  cv_msg_mode1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10029';     -- 納品ジャーナル取込モード
  cv_msg_mode2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10030';     -- 納品データパージ処理モード
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  cv_msg_mode3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13513';     -- 納品ワークテーブル削除処理モード
  cv_msg_mode3_comp  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13514';     -- 納品ワークテーブル削除確認メッセージ
  cv_msg_wh_del_count CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13515';     -- ヘッダワークテーブル削除件数メッセージ
  cv_msg_wl_del_count CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13516';     -- 明細ワークテーブル削除件数メッセージ
  cv_msg_no_del_target CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13517';    -- ワークテーブル削除対象データなしメッセージ
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
  cv_msg_head_tab    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10031';     -- 納品ヘッダテーブル
  cv_msg_line_tab    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10032';     -- 納品明細テーブル
  cv_msg_headwk_tab  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10033';     -- 納品ヘッダワークテーブル
  cv_msg_linewk_tab  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10034';     -- 納品明細ワークテーブル
  cv_msg_err_tab     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10035';     -- HHTエラーリスト帳票ワークテーブル
  cv_msg_lock_table  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10036';     -- 納品ヘッダテーブル及び納品明細テーブル
  cv_msg_lock_work   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10037';     -- ヘッダワークテーブル及び明細ワークテーブル
  cv_msg_cus_mst     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10038';     -- 顧客マスタ
  cv_msg_cus_code    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10039';     -- 顧客コード
  cv_msg_item_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10040';     -- 品目マスタ
  cv_msg_item_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10041';     -- 品目コード
  cv_msg_card        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10042';     -- カード売区分
  cv_msg_input       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10043';     -- 入力区分
  cv_msg_tax         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10044';     -- 消費税区分
  cv_msg_depart      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10045';     -- 百貨店画面種別
  cv_msg_sale        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10046';     -- 売上区分
  cv_msg_h_c         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10047';     -- H/C
  cv_msg_orga_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10048';     -- 在庫組織コード
  cv_msg_purge_date  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10049';     -- 納品データ取込パージ処理日算出基準日数
  cv_msg_delivery    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10050';     -- 納品データ
  cv_msg_return      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13501';     -- 返品データ
  cv_msg_tar_cnt_h   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13502';     -- ヘッダ対象件数
  cv_msg_tar_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13503';     -- 明細対象件数
  cv_msg_nor_cnt_h   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13504';     -- ヘッダ成功件数
  cv_msg_nor_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13505';     -- 明細成功件数
  cv_msg_keep_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13506';     -- 預け先コード
  cv_msg_qck_error   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13507';     -- クイックコード取得エラーメッセージ
  cv_msg_cust_st     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13508';     -- 顧客ステータス
  cv_msg_busi_low    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13509';     -- 業態（小分類）
  cv_msg_item_st     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13510';     -- 品目ステータス
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
  cv_msg_emp_mst     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00051';     -- 従業員マスタ
  cv_msg_paf_emp     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00173';     -- 成績者コード
  cv_msg_dlv_emp     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00174';     -- 納品者コード
  cv_err_msg_get_resource_id  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13511'; --リソースID取得エラー
--****************************** 2009/05/15 1.14 N.Maeda ADD END ********************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
  cv_msg_card_company CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13512';     -- カード会社未設定エラーメッセージ
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
  -- トークン
  cv_tkn_table       CONSTANT VARCHAR2(20)  := 'TABLE';                -- テーブル名
  cv_tkn_colmun      CONSTANT VARCHAR2(20)  := 'COLMUN';               -- テーブル列名
  cv_tkn_type        CONSTANT VARCHAR2(20)  := 'TYPE';                 -- クイックコードタイプ
  cv_tkn_profile     CONSTANT VARCHAR2(20)  := 'PROFILE';              -- プロファイル名
  cv_tkn_count       CONSTANT VARCHAR2(20)  := 'COUNT';                -- 件数
  cv_tkn_para1       CONSTANT VARCHAR2(20)  := 'PARAME1';              -- パラメータ
  cv_tkn_para2       CONSTANT VARCHAR2(20)  := 'PARAME2';              -- 処理内容
  cv_tkn_yes         CONSTANT VARCHAR2(1)   := 'Y';                    -- 判定＝Y
  cv_tkn_no          CONSTANT VARCHAR2(1)   := 'N';                    -- 判定＝N
  cv_default         CONSTANT VARCHAR2(1)   := '0';                    -- デフォルト値＝0
  cv_hit             CONSTANT VARCHAR2(1)   := '1';                    -- フラグ判定
  cv_daytime         CONSTANT VARCHAR2(1)   := '1';                    -- 昼間起動モード＝1
  cv_night           CONSTANT VARCHAR2(1)   := '2';                    -- 夜間起動モード＝2
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  cv_truncate        CONSTANT VARCHAR2(1)   := '3';                    -- 起動モード＝3(納品ワークパージ)
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
  cv_depart          CONSTANT VARCHAR2(1)   := '1';                    -- 百貨店用HHT区分＝1：百貨店
  cv_general         CONSTANT VARCHAR2(1)   := NULL;                   -- 百貨店用HHT区分＝NULL：一般拠点
--****************************** 2009/05/15 1.13 N.Maeda ADD START  *****************************--
  ct_order_no_ebs_0  CONSTANT xxcos_dlv_headers.order_no_ebs%TYPE := 0; -- 受注No.(EBS) = 0
--****************************** 2009/05/15 1.13 N.Maeda ADD  END   *****************************--
--****************************** 2009/05/15 1.14 N.Maeda ADD START  *****************************--
  cv_shot_date_type  CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_date_type       CONSTANT VARCHAR2(25)  := 'YYYY/MM/DD HH24:MI:SS';
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  lv_time_type       CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  cv_spe_cha         CONSTANT VARCHAR2(1)   := ' ';
  cv_time_cha        CONSTANT VARCHAR2(1)   := ':';
--****************************** 2009/05/15 1.14 N.Maeda ADD  END   *****************************--
-- ******* 2009/10/01 N.Maeda ADD START ********* --
  cv_user_lang       CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- ******* 2009/10/01 N.Maeda ADD  END  ********* --
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
  cv_card            CONSTANT VARCHAR2(1)   := '1';                    -- カード売区分＝1:カード
  cv_cash            CONSTANT VARCHAR2(1)   := '0';                    -- カード売区分＝0:現金
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
--
  -- クイックコードタイプ
  cv_qck_typ_status  CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_STATUS_MST_001_A01';   -- 顧客ステータス
  cv_qck_typ_a01     CONSTANT VARCHAR2(30)  := 'XXCOS_001_A01_%';                 -- クイックコード：コード
  cv_qck_typ_card    CONSTANT VARCHAR2(30)  := 'XXCOS1_CARD_SALE_CLASS';          -- カード売区分
  cv_qck_typ_input   CONSTANT VARCHAR2(30)  := 'XXCOS1_INPUT_CLASS';              -- 入力区分
  cv_qck_typ_gyotai  CONSTANT VARCHAR2(30)  := 'XXCOS1_GYOTAI_SHO_MST_001_A01';   -- 業態（小分類）
  cv_qck_typ_tax     CONSTANT VARCHAR2(30)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';    -- 消費税区分
  cv_qck_typ_depart  CONSTANT VARCHAR2(30)  := 'XXCOS1_DEPARTMENT_SCREEN_CLASS';  -- 百貨店画面種別
  cv_qck_typ_item    CONSTANT VARCHAR2(30)  := 'XXCOS1_ITEM_STATUS_MST_001_A01';  -- 品目ステータス
  cv_qck_typ_sale    CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS';               -- 売上区分
  cv_qck_typ_hc      CONSTANT VARCHAR2(30)  := 'XXCOS1_HC_CLASS';                 -- H/C
  cv_qck_typ_cus     CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_CLASS_MST_001_A01';    -- 顧客区分
--
  --フォーマット
  cv_fmt_date        CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                      -- DATE形式
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 納品ヘッダワークテーブルデータ格納用変数
  TYPE g_rec_headwk_data IS RECORD
    (
      order_no_hht      xxcos_dlv_headers.order_no_hht%TYPE,            -- 受注No.（HHT)
      order_no_ebs      xxcos_dlv_headers.order_no_ebs%TYPE,            -- 受注No.（EBS）
      base_code         xxcos_dlv_headers.base_code%TYPE,               -- 拠点コード
      perform_code      xxcos_dlv_headers.performance_by_code%TYPE,     -- 成績者コード
      dlv_by_code       xxcos_dlv_headers.dlv_by_code%TYPE,             -- 納品者コード
      hht_invoice_no    xxcos_dlv_headers.hht_invoice_no%TYPE,          -- HHT伝票No.
      dlv_date          xxcos_dlv_headers.dlv_date%TYPE,                -- 納品日
      inspect_date      xxcos_dlv_headers.inspect_date%TYPE,            -- 検収日
      sales_class       xxcos_dlv_headers.sales_classification%TYPE,    -- 売上分類区分
      sales_invoice     xxcos_dlv_headers.sales_invoice%TYPE,           -- 売上伝票区分
      card_class        xxcos_dlv_headers.card_sale_class%TYPE,         -- カード売区分
      dlv_time          xxcos_dlv_headers.dlv_time%TYPE,                -- 時間
      change_time_100   xxcos_dlv_headers.change_out_time_100%TYPE,     -- つり銭切れ時間100円
      change_time_10    xxcos_dlv_headers.change_out_time_10%TYPE,      -- つり銭切れ時間10円
      cus_number        xxcos_dlv_headers.customer_number%TYPE,         -- 顧客コード
      input_class       xxcos_dlv_headers.input_class%TYPE,             -- 入力区分
      tax_class         xxcos_dlv_headers.consumption_tax_class%TYPE,   -- 消費税区分
      total_amount      xxcos_dlv_headers.total_amount%TYPE,            -- 合計金額
      sale_discount     xxcos_dlv_headers.sale_discount_amount%TYPE,    -- 売上値引額
      sales_tax         xxcos_dlv_headers.sales_consumption_tax%TYPE,   -- 売上消費税額
      tax_include       xxcos_dlv_headers.tax_include%TYPE,             -- 税込金額
      keep_in_code      xxcos_dlv_headers.keep_in_code%TYPE,            -- 預け先コード
      depart_screen     xxcos_dlv_headers.department_screen_class%TYPE  -- 百貨店画面種別
    );
  TYPE g_tab_headwk_data IS TABLE OF g_rec_headwk_data INDEX BY PLS_INTEGER;
--
  -- 納品明細ワークテーブルデータ格納用変数
  TYPE g_rec_linewk_data IS RECORD
    (
      order_no_hht      xxcos_dlv_lines.order_no_hht%TYPE,              -- 受注No.（HHT）
      line_no_hht       xxcos_dlv_lines.line_no_hht%TYPE,               -- 行No.（HHT）
      order_no_ebs      xxcos_dlv_lines.order_no_ebs%TYPE,              -- 受注No.（EBS）
      line_num_ebs      xxcos_dlv_lines.line_number_ebs%TYPE,           -- 明細番号(EBS)
      item_code_self    xxcos_dlv_lines.item_code_self%TYPE,            -- 品名コード（自社）
      case_number       xxcos_dlv_lines.case_number%TYPE,               -- ケース数
      quantity          xxcos_dlv_lines.quantity%TYPE,                  -- 数量
      sale_class        xxcos_dlv_lines.sale_class%TYPE,                -- 売上区分
      wholesale_unit    xxcos_dlv_lines.wholesale_unit_ploce%TYPE,      -- 卸単価
      selling_price     xxcos_dlv_lines.selling_price%TYPE,             -- 売単価
      column_no         xxcos_dlv_lines.column_no%TYPE,                 -- コラムNo.
      h_and_c           xxcos_dlv_lines.h_and_c%TYPE,                   -- H/C
      sold_out_class    xxcos_dlv_lines.sold_out_class%TYPE,            -- 売切区分
      sold_out_time     xxcos_dlv_lines.sold_out_time%TYPE,             -- 売切時間
      cash_and_card     xxcos_dlv_lines.cash_and_card%TYPE              -- 現金・カード併用額
    );
  TYPE g_tab_linewk_data IS TABLE OF g_rec_linewk_data INDEX BY PLS_INTEGER;
--
  -- 拠点コード、顧客コードの妥当性チェック：抽出項目格納用変数
  TYPE g_rec_select_cus IS RECORD
    (
      customer_name   hz_cust_accounts.account_name%TYPE,              -- 顧客名称
      customer_id     hz_cust_accounts.cust_account_id%TYPE,           -- 顧客ID
      party_id        hz_cust_accounts.party_id%TYPE,                  -- パーティID
      sale_base       xxcmm_cust_accounts.sale_base_code%TYPE,         -- 売上拠点コード
      past_sale_base  xxcmm_cust_accounts.past_sale_base_code%TYPE,    -- 前月売上拠点コード
      cus_status      hz_parties.duns_number_c%TYPE,                   -- 顧客ステータス
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--      charge_person   jtf_rs_resource_extns.source_number%TYPE,        -- 担当営業員
--****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--      resource_id     jtf_rs_resource_extns.resource_id%TYPE,          -- リソースID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
      bus_low_type    xxcmm_cust_accounts.business_low_type%TYPE,      -- 業態（小分類）
      base_name       hz_cust_accounts.account_name%TYPE,              -- 拠点名称
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--      dept_hht_div    xxcmm_cust_accounts.dept_hht_div%TYPE            -- 百貨店用HHT区分
      dept_hht_div    xxcmm_cust_accounts.dept_hht_div%TYPE,            -- 百貨店用HHT区分
--****************************** 2010/01/18 1.21 M.Uehara MOD END *******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--      base_perf       per_all_assignments_f.ass_attribute5%TYPE,       -- 拠点コード（成績者）
--      base_dlv        per_all_assignments_f.ass_attribute5%TYPE        -- 拠点コード（納品者）
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      card_company    xxcmm_cust_accounts.card_company%TYPE            -- カード会社
--****************************** 2010/01/18 1.21 M.Uehara ADD END *******************************--
    );
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--  
--  TYPE g_tab_select_cus IS TABLE OF g_rec_select_cus INDEX BY VARCHAR2(9);
  TYPE g_tab_select_cus IS TABLE OF g_rec_select_cus INDEX BY VARCHAR2(15);
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  -- 成績者コードの妥当性チェック：抽出項目格納用変数
  TYPE g_rec_select_perf IS RECORD
    (
      base_perf       per_all_assignments_f.ass_attribute5%TYPE        -- 拠点コード（成績者）
    );
  TYPE g_tab_select_perf IS TABLE OF g_rec_select_perf INDEX BY VARCHAR2(30);
--
  -- 納品者コードの妥当性チェック：抽出項目格納用変数
  TYPE g_rec_select_dlv  IS RECORD
    (
      resource_id     jtf_rs_resource_extns.resource_id%TYPE,          -- リソースID
      base_dlv        per_all_assignments_f.ass_attribute5%TYPE        -- 拠点コード（納品者）
    );
  TYPE g_tab_select_dlv IS TABLE OF g_rec_select_dlv INDEX BY VARCHAR2(30);
--
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  -- 品目コードの妥当性チェック：抽出項目格納用変数
  TYPE g_rec_select_item IS RECORD
    (
      item_id          mtl_system_items_b.inventory_item_id%TYPE,              -- 品目ID
      primary_measure  mtl_system_items_b.primary_unit_of_measure%TYPE,        -- 基準単位
      in_case          ic_item_mst_b.attribute11%TYPE,                         -- ケース入数
      sale_object      ic_item_mst_b.attribute26%TYPE,                         -- 売上対象区分
      item_status      xxcmm_system_items_b.item_status%TYPE                   -- 品目ステータス
    );
  TYPE g_tab_select_item IS TABLE OF g_rec_select_item INDEX BY VARCHAR2(7);
--
  -- VDコラムマスタとの整合性チェック：抽出項目格納用変数
  TYPE g_rec_select_vd IS RECORD
    (
      column_no      xxcoi_mst_vd_column.column_no%TYPE,              -- コラムNo.
      hot_cold       xxcoi_mst_vd_column.hot_cold%TYPE                -- H/C
    );
  TYPE g_tab_select_vd IS TABLE OF g_rec_select_vd INDEX BY VARCHAR2(18);
--
  -- 納品ヘッダデータ登録用変数
  TYPE g_tab_head_order_no_hht      IS TABLE OF xxcos_dlv_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.（HHT)
  TYPE g_tab_head_order_no_ebs      IS TABLE OF xxcos_dlv_headers.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.（EBS）
  TYPE g_tab_head_base_code         IS TABLE OF xxcos_dlv_headers.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 拠点コード
  TYPE g_tab_head_perform_code      IS TABLE OF xxcos_dlv_headers.performance_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- 成績者コード
  TYPE g_tab_head_dlv_by_code       IS TABLE OF xxcos_dlv_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- 納品者コード
  TYPE g_tab_head_hht_invoice_no    IS TABLE OF xxcos_dlv_headers.hht_invoice_no%TYPE
    INDEX BY PLS_INTEGER;   -- HHT伝票No.
  TYPE g_tab_head_dlv_date          IS TABLE OF xxcos_dlv_headers.dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- 納品日
  TYPE g_tab_head_inspect_date      IS TABLE OF xxcos_dlv_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   -- 検収日
  TYPE g_tab_head_sales_class       IS TABLE OF xxcos_dlv_headers.sales_classification%TYPE
    INDEX BY PLS_INTEGER;   -- 売上分類区分
  TYPE g_tab_head_sales_invoice     IS TABLE OF xxcos_dlv_headers.sales_invoice%TYPE
    INDEX BY PLS_INTEGER;   -- 売上伝票区分
  TYPE g_tab_head_card_class        IS TABLE OF xxcos_dlv_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;   -- カード売区分
  TYPE g_tab_head_dlv_time          IS TABLE OF xxcos_dlv_headers.dlv_time%TYPE
    INDEX BY PLS_INTEGER;   -- 時間
  TYPE g_tab_head_change_time_100   IS TABLE OF xxcos_dlv_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;   -- つり銭切れ時間100円
  TYPE g_tab_head_change_time_10    IS TABLE OF xxcos_dlv_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;   -- つり銭切れ時間10円
  TYPE g_tab_head_cus_number        IS TABLE OF xxcos_dlv_headers.customer_number%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客コード
  TYPE g_tab_head_system_class      IS TABLE OF xxcos_dlv_headers.system_class%TYPE
    INDEX BY PLS_INTEGER;   -- 業態区分
  TYPE g_tab_head_input_class       IS TABLE OF xxcos_dlv_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   -- 入力区分
  TYPE g_tab_head_tax_class         IS TABLE OF xxcos_dlv_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- 消費税区分
  TYPE g_tab_head_total_amount      IS TABLE OF xxcos_dlv_headers.total_amount%TYPE
    INDEX BY PLS_INTEGER;   -- 合計金額
  TYPE g_tab_head_sale_discount     IS TABLE OF xxcos_dlv_headers.sale_discount_amount%TYPE
    INDEX BY PLS_INTEGER;   -- 売上値引額
  TYPE g_tab_head_sales_tax         IS TABLE OF xxcos_dlv_headers.sales_consumption_tax%TYPE
    INDEX BY PLS_INTEGER;   -- 売上消費税額
  TYPE g_tab_head_tax_include       IS TABLE OF xxcos_dlv_headers.tax_include%TYPE
    INDEX BY PLS_INTEGER;   -- 税込金額
  TYPE g_tab_head_keep_in_code      IS TABLE OF xxcos_dlv_headers.keep_in_code%TYPE
    INDEX BY PLS_INTEGER;   -- 預け先コード
  TYPE g_tab_head_depart_screen     IS TABLE OF xxcos_dlv_headers.department_screen_class%TYPE
    INDEX BY PLS_INTEGER;   -- 百貨店画面種別
--
  -- 納品明細データ登録用変数
  TYPE g_tab_line_order_no_hht     IS TABLE OF xxcos_dlv_lines.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.（HHT）
  TYPE g_tab_line_line_no_hht      IS TABLE OF xxcos_dlv_lines.line_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 行No.（HHT）
  TYPE g_tab_line_order_no_ebs     IS TABLE OF xxcos_dlv_lines.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.（EBS）
  TYPE g_tab_line_line_num_ebs     IS TABLE OF xxcos_dlv_lines.line_number_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- 明細番号(EBS)
  TYPE g_tab_line_item_code_self   IS TABLE OF xxcos_dlv_lines.item_code_self%TYPE
    INDEX BY PLS_INTEGER;   -- 品名コード（自社）
  TYPE g_tab_line_content          IS TABLE OF xxcos_dlv_lines.content%TYPE
    INDEX BY PLS_INTEGER;   -- 入数
  TYPE g_tab_line_item_id          IS TABLE OF xxcos_dlv_lines.inventory_item_id%TYPE
    INDEX BY PLS_INTEGER;   -- 品目ID
  TYPE g_tab_line_standard_unit    IS TABLE OF xxcos_dlv_lines.standard_unit%TYPE
    INDEX BY PLS_INTEGER;   -- 基準単位
  TYPE g_tab_line_case_number      IS TABLE OF xxcos_dlv_lines.case_number%TYPE
    INDEX BY PLS_INTEGER;   -- ケース数
  TYPE g_tab_line_quantity         IS TABLE OF xxcos_dlv_lines.quantity%TYPE
    INDEX BY PLS_INTEGER;   -- 数量
  TYPE g_tab_line_sale_class       IS TABLE OF xxcos_dlv_lines.sale_class%TYPE
    INDEX BY PLS_INTEGER;   -- 売上区分
  TYPE g_tab_line_wholesale_unit   IS TABLE OF xxcos_dlv_lines.wholesale_unit_ploce%TYPE
    INDEX BY PLS_INTEGER;   -- 卸単価
  TYPE g_tab_line_selling_price    IS TABLE OF xxcos_dlv_lines.selling_price%TYPE
    INDEX BY PLS_INTEGER;   -- 売単価
  TYPE g_tab_line_column_no        IS TABLE OF xxcos_dlv_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   -- コラムNo.
  TYPE g_tab_line_h_and_c          IS TABLE OF xxcos_dlv_lines.h_and_c%TYPE
    INDEX BY PLS_INTEGER;   -- H/C
  TYPE g_tab_line_sold_out_class   IS TABLE OF xxcos_dlv_lines.sold_out_class%TYPE
    INDEX BY PLS_INTEGER;   -- 売切区分
  TYPE g_tab_line_sold_out_time    IS TABLE OF xxcos_dlv_lines.sold_out_time%TYPE
    INDEX BY PLS_INTEGER;   -- 売切時間
  TYPE g_tab_line_replenish_num    IS TABLE OF xxcos_dlv_lines.replenish_number%TYPE
    INDEX BY PLS_INTEGER;   -- 補充数
  TYPE g_tab_line_cash_and_card    IS TABLE OF xxcos_dlv_lines.cash_and_card%TYPE
    INDEX BY PLS_INTEGER;   -- 現金・カード併用額
--
  -- エラーデータ格納用変数
  TYPE g_tab_err_base_code           IS TABLE OF xxcos_rep_hht_err_list.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 拠点コード
  TYPE g_tab_err_base_name           IS TABLE OF xxcos_rep_hht_err_list.base_name%TYPE
    INDEX BY PLS_INTEGER;   -- 拠点名称
  TYPE g_tab_err_data_name           IS TABLE OF xxcos_rep_hht_err_list.data_name%TYPE
    INDEX BY PLS_INTEGER;   -- データ名称
  TYPE g_tab_err_order_no_hht        IS TABLE OF xxcos_rep_hht_err_list.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 受注NO(HHT)
  TYPE g_tab_err_entry_number        IS TABLE OF xxcos_rep_hht_err_list.entry_number%TYPE
    INDEX BY PLS_INTEGER;   -- 伝票NO
  TYPE g_tab_err_line_no             IS TABLE OF xxcos_rep_hht_err_list.line_no%TYPE
    INDEX BY PLS_INTEGER;   -- 行NO
  TYPE g_tab_err_order_no_ebs        IS TABLE OF xxcos_rep_hht_err_list.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- 受注NO(EBS)
  TYPE g_tab_err_party_num           IS TABLE OF xxcos_rep_hht_err_list.party_num%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客コード
  TYPE g_tab_err_customer_name       IS TABLE OF xxcos_rep_hht_err_list.customer_name%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客名
  TYPE g_tab_err_payment_dlv_date    IS TABLE OF xxcos_rep_hht_err_list.payment_dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- 入金/納品日
  TYPE g_tab_err_perform_by_code     IS TABLE OF xxcos_rep_hht_err_list.performance_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- 成績者コード
  TYPE g_tab_err_item_code           IS TABLE OF xxcos_rep_hht_err_list.item_code%TYPE
    INDEX BY PLS_INTEGER;   -- 品目コード
  TYPE g_tab_err_error_message       IS TABLE OF xxcos_rep_hht_err_list.error_message%TYPE
    INDEX BY PLS_INTEGER;   -- エラー内容
--
  -- 訪問・有効実績登録用変数
  TYPE g_tab_resource_id             IS TABLE OF jtf_rs_resource_extns.resource_id%TYPE
    INDEX BY PLS_INTEGER;   -- リソースID
  TYPE g_tab_party_id                IS TABLE OF hz_parties.party_id%TYPE
    INDEX BY PLS_INTEGER;   -- パーティID
  TYPE g_tab_party_name              IS TABLE OF hz_parties.party_name%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客名称
  TYPE g_tab_cus_status              IS TABLE OF hz_parties.duns_number_c%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客ステータス
--
  -- クイックコード格納用
  -- 顧客ステータス格納用変数
  TYPE g_tab_qck_status   IS TABLE OF  hz_parties.duns_number_c%TYPE                  INDEX BY PLS_INTEGER;
  -- カード売区分格納用変数
  TYPE g_tab_qck_card     IS TABLE OF  xxcos_dlv_headers.card_sale_class%TYPE         INDEX BY PLS_INTEGER;
  -- 入力区分（使用可能項目）格納用変数
  TYPE g_tab_qck_inp_able IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- 入力区分（納品データ）格納用変数
  TYPE g_tab_qck_inp_dlv  IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- 入力区分（返品データ）格納用変数
  TYPE g_tab_qck_inp_ret  IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- 入力区分（フルVD納品・自動吸上）格納用変数
  TYPE g_tab_qck_inp_auto IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- 業態（小分類）格納用変数
  TYPE g_tab_qck_busi     IS TABLE OF  xxcmm_cust_accounts.business_low_type%TYPE     INDEX BY PLS_INTEGER;
  -- 消費税区分格納用変数
  TYPE g_tax_class IS RECORD
    (
      tax_cl   xxcos_dlv_headers.consumption_tax_class%TYPE              -- 変換前の消費税区分
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
--      dff3     xxcos_dlv_headers.consumption_tax_class%TYPE               -- 変換後の消費税区分
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
    );
  TYPE g_tab_qck_tax      IS TABLE OF  g_tax_class   INDEX BY PLS_INTEGER;
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  -- 百貨店画面種別格納用変数
--  TYPE g_tab_qck_depart   IS TABLE OF  xxcos_dlv_headers.department_screen_class%TYPE INDEX BY PLS_INTEGER;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
  -- 品目ステータス格納用変数
  TYPE g_tab_qck_item     IS TABLE OF  xxcmm_system_items_b.item_status%TYPE          INDEX BY PLS_INTEGER;
  -- 売上区分格納用変数
  TYPE g_tab_qck_sale     IS TABLE OF  xxcos_dlv_lines.sale_class%TYPE                INDEX BY PLS_INTEGER;
  -- H/C格納用変数
  TYPE g_tab_qck_hc       IS TABLE OF  xxcos_dlv_lines.h_and_c%TYPE                   INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 納品ヘッダテーブル登録データ
  gt_head_order_no_hht      g_tab_head_order_no_hht;        -- 受注No.（HHT）
  gt_head_order_no_ebs      g_tab_head_order_no_ebs;        -- 受注No.（EBS）
  gt_head_base_code         g_tab_head_base_code;           -- 拠点コード
  gt_head_perform_code      g_tab_head_perform_code;        -- 成績者コード
  gt_head_dlv_by_code       g_tab_head_dlv_by_code;         -- 納品者コード
  gt_head_hht_invoice_no    g_tab_head_hht_invoice_no;      -- HHT伝票No.
  gt_head_dlv_date          g_tab_head_dlv_date;            -- 納品日
  gt_head_inspect_date      g_tab_head_inspect_date;        -- 検収日
  gt_head_sales_class       g_tab_head_sales_class;         -- 売上分類区分
  gt_head_sales_invoice     g_tab_head_sales_invoice;       -- 売上伝票区分
  gt_head_card_class        g_tab_head_card_class;          -- カード売区分
  gt_head_dlv_time          g_tab_head_dlv_time;            -- 時間
  gt_head_change_time_100   g_tab_head_change_time_100;     -- つり銭切れ時間100円
  gt_head_change_time_10    g_tab_head_change_time_10;      -- つり銭切れ時間10円
  gt_head_cus_number        g_tab_head_cus_number;          -- 顧客コード
  gt_head_system_class      g_tab_head_system_class;        -- 業態区分
  gt_head_input_class       g_tab_head_input_class;         -- 入力区分
  gt_head_tax_class         g_tab_head_tax_class;           -- 消費税区分
  gt_head_total_amount      g_tab_head_total_amount;        -- 合計金額
  gt_head_sale_discount     g_tab_head_sale_discount;       -- 売上値引額
  gt_head_sales_tax         g_tab_head_sales_tax;           -- 売上消費税額
  gt_head_tax_include       g_tab_head_tax_include;         -- 税込金額
  gt_head_keep_in_code      g_tab_head_keep_in_code;        -- 預け先コード
  gt_head_depart_screen     g_tab_head_depart_screen;       -- 百貨店画面種別
--
  -- 納品明細テーブル登録データ
  gt_line_order_no_hht      g_tab_line_order_no_hht;        -- 受注No.（HHT）
  gt_line_line_no_hht       g_tab_line_line_no_hht;         -- 行No.（HHT）
  gt_line_order_no_ebs      g_tab_line_order_no_ebs;        -- 受注No.（EBS）
  gt_line_line_num_ebs      g_tab_line_line_num_ebs;        -- 明細番号(EBS)
  gt_line_item_code_self    g_tab_line_item_code_self;      -- 品名コード（自社）
  gt_line_content           g_tab_line_content;             -- 入数
  gt_line_item_id           g_tab_line_item_id;             -- 品目ID
  gt_line_standard_unit     g_tab_line_standard_unit;       -- 基準単位
  gt_line_case_number       g_tab_line_case_number;         -- ケース数
  gt_line_quantity          g_tab_line_quantity;            -- 数量
  gt_line_sale_class        g_tab_line_sale_class;          -- 売上区分
  gt_line_wholesale_unit    g_tab_line_wholesale_unit;      -- 卸単価
  gt_line_selling_price     g_tab_line_selling_price;       -- 売単価
  gt_line_column_no         g_tab_line_column_no;           -- コラムNo.
  gt_line_h_and_c           g_tab_line_h_and_c;             -- H/C
  gt_line_sold_out_class    g_tab_line_sold_out_class;      -- 売切区分
  gt_line_sold_out_time     g_tab_line_sold_out_time;       -- 売切時間
  gt_line_replenish_num     g_tab_line_replenish_num;       -- 補充数
  gt_line_cash_and_card     g_tab_line_cash_and_card;       -- 現金・カード併用額
--
  -- HHTエラーリスト帳票ワークテーブル登録データ
  gt_err_base_code          g_tab_err_base_code;            -- 拠点コード
  gt_err_base_name          g_tab_err_base_name;            -- 拠点名称
  gt_err_data_name          g_tab_err_data_name;            -- データ名称
  gt_err_order_no_hht       g_tab_err_order_no_hht;         -- 受注NO(HHT)
  gt_err_entry_number       g_tab_err_entry_number;         -- 伝票NO
  gt_err_line_no            g_tab_err_line_no;              -- 行NO
  gt_err_order_no_ebs       g_tab_err_order_no_ebs;         -- 受注NO(EBS)
  gt_err_party_num          g_tab_err_party_num;            -- 顧客コード
  gt_err_customer_name      g_tab_err_customer_name;        -- 顧客名
  gt_err_payment_dlv_date   g_tab_err_payment_dlv_date;     -- 入金/納品日
  gt_err_perform_by_code    g_tab_err_perform_by_code;      -- 成績者コード
  gt_err_item_code          g_tab_err_item_code;            -- 品目コード
  gt_err_error_message      g_tab_err_error_message;        -- エラー内容
--
  -- 訪問・有効実績登録用変数
  gt_resource_id            g_tab_resource_id;              -- リソースID
  gt_party_id               g_tab_party_id;                 -- パーティID
  gt_party_name             g_tab_party_name;               -- 顧客名称
  gt_cus_status             g_tab_cus_status;               -- 顧客ステータス
--
  gt_headers_work_data      g_tab_headwk_data;              -- 納品ヘッダワークテーブル抽出データ
  gt_lines_work_data        g_tab_linewk_data;              -- 納品明細ワークテーブル抽出データ
  gt_select_cus             g_tab_select_cus;               -- 拠点コード、顧客コードの妥当性チェック：抽出項目
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  gt_select_perf            g_tab_select_perf;              -- 成績者コードの妥当性チェック：抽出項目
  gt_select_dlv             g_tab_select_dlv;               -- 納品者コードの妥当性チェック：抽出項目
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  gt_select_item            g_tab_select_item;              -- 品目コードの妥当性チェック：抽出項目
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--  gt_select_vd              g_tab_select_vd;                -- VDコラムマスタとの整合性チェック：抽出項目
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
  gt_qck_status             g_tab_qck_status;               -- 顧客ステータス
  gt_qck_card               g_tab_qck_card;                 -- カード売区分
  gt_qck_inp_able           g_tab_qck_inp_able;             -- 入力区分（使用可能項目）
  gt_qck_inp_dlv            g_tab_qck_inp_dlv;              -- 入力区分（納品データ）
  gt_qck_inp_ret            g_tab_qck_inp_ret;              -- 入力区分（返品データ）
  gt_qck_inp_auto           g_tab_qck_inp_auto;             -- 入力区分（フルVD納品・自動吸上）
  gt_qck_busi               g_tab_qck_busi;                 -- 業態（小分類）
  gt_qck_tax                g_tab_qck_tax;                  -- 消費税区分
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  gt_qck_depart             g_tab_qck_depart;               -- 百貨店画面種別
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
  gt_qck_item               g_tab_qck_item;                 -- 品目ステータス
  gt_qck_sale               g_tab_qck_sale;                 -- 売上区分
  gt_qck_hc                 g_tab_qck_hc;                   -- H/C
  gn_purge_date             NUMBER;                         -- パージ処理基準日
  gn_orga_id                NUMBER;                         -- 在庫組織ID
  gd_max_date               DATE;                           -- MAX日付
  gd_process_date           DATE;                           -- 業務処理日
  gv_mode                   VARCHAR2(1);                    -- 起動モード
  gn_tar_cnt_h              NUMBER;                         -- ヘッダ対象件数
  gn_tar_cnt_l              NUMBER;                         -- 明細対象件数
  gn_nor_cnt_h              NUMBER;                         -- ヘッダ成功件数
  gn_nor_cnt_l              NUMBER;                         -- 明細成功件数
  gn_del_cnt_h              NUMBER;                         -- ヘッダ削除件数
  gn_del_cnt_l              NUMBER;                         -- 明細削除件数
  gv_tkn1                   VARCHAR2(50);                   -- エラーメッセージ用トークン１
  gv_tkn2                   VARCHAR2(50);                   -- エラーメッセージ用トークン２
  gv_tkn3                   VARCHAR2(50);                   -- エラーメッセージ用トークン３
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  gn_wh_del_count           NUMBER;                         -- ヘッダワーク削除件数
  gn_wl_del_count           NUMBER;                         -- 明細ワーク削除件数
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
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
    --==============================================================
    -- 「パラメータ出力メッセージ」を出力
    --==============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    IF ( gv_mode = cv_daytime ) THEN      -- 昼間モード
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode1 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- メッセージログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
    ELSIF ( gv_mode = cv_night ) THEN   -- 夜間モード
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode2 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- メッセージログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
    ELSIF ( gv_mode = cv_truncate ) THEN    -- 起動時の処理
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode3 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- メッセージログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
--
--****************************** 2010/01/27 1.23 N.Maeda  MOD END   *******************************--
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : dlv_data_receive
   * Description      : 納品データ抽出(A-1)
   ***********************************************************************************/
  PROCEDURE dlv_data_receive(
    on_target_cnt     OUT NUMBER,           --   抽出件数（ヘッダ）
    on_line_cnt       OUT NUMBER,           --   抽出件数（明細）
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlv_data_receive'; -- プログラム名
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
    lv_max_date      VARCHAR2(50);      -- MAX日付
    lv_orga_code     VARCHAR2(10);      -- 在庫組織コード
    ld_process_date  DATE;              -- 業務処理日
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    -- 納品ヘッダワークテーブルデータ抽出
    CURSOR get_headers_data_cur
    IS
--****************************** 2009/05/01 1.12 MOD START ******************************--
--      SELECT headers.order_no_hht             order_no_hht,             -- 受注No.（HHT)
--             headers.order_no_ebs             order_no_ebs,             -- 受注No.（EBS）
--             headers.base_code                base_code,                -- 拠点コード
--             headers.performance_by_code      performance_by_code,      -- 成績者コード
--             headers.dlv_by_code              dlv_by_code,              -- 納品者コード
--             headers.hht_invoice_no           hht_invoice_no,           -- HHT伝票No.
--             headers.dlv_date                 dlv_date,                 -- 納品日
--             headers.inspect_date             inspect_date,             -- 検収日
--             headers.sales_classification     sales_classification,     -- 売上分類区分
--             headers.sales_invoice            sales_invoice,            -- 売上伝票区分
--             headers.card_sale_class          card_sale_class,          -- カード売区分
--             headers.dlv_time                 dlv_time,                 -- 時間
--             headers.change_out_time_100      change_out_time_100,      -- つり銭切れ時間100円
--             headers.change_out_time_10       change_out_time_10,       -- つり銭切れ時間10円
--             headers.customer_number          customer_number,          -- 顧客コード
--             headers.input_class              input_class,              -- 入力区分
--             headers.consumption_tax_class    consumption_tax_class,    -- 消費税区分
--             headers.total_amount             total_amount,             -- 合計金額
--             headers.sale_discount_amount     sale_discount_amount,     -- 売上値引額
--             headers.sales_consumption_tax    sales_consumption_tax,    -- 売上消費税額
--             headers.tax_include              tax_include,              -- 税込金額
--             headers.keep_in_code             keep_in_code,             -- 預け先コード
--             headers.department_screen_class  department_screen_class   -- 百貨店画面種別
--      FROM   xxcos_dlv_headers_work           headers                   -- 納品ヘッダワークテーブル
--      ORDER BY order_no_hht
--      FOR UPDATE NOWAIT;
      SELECT headers.order_no_hht                    order_no_hht,             -- 受注No.（HHT)
             headers.order_no_ebs                    order_no_ebs,             -- 受注No.（EBS）
             TRIM( headers.base_code )               base_code,                -- 拠点コード
             TRIM( headers.performance_by_code )     performance_by_code,      -- 成績者コード
             TRIM( headers.dlv_by_code )             dlv_by_code,              -- 納品者コード
             TRIM( headers.hht_invoice_no )          hht_invoice_no,           -- HHT伝票No.
             headers.dlv_date                        dlv_date,                 -- 納品日
             headers.inspect_date                    inspect_date,             -- 検収日
             TRIM( headers.sales_classification )    sales_classification,     -- 売上分類区分
             TRIM( headers.sales_invoice )           sales_invoice,            -- 売上伝票区分
             TRIM( headers.card_sale_class )         card_sale_class,          -- カード売区分
             TRIM( headers.dlv_time )                dlv_time,                 -- 時間
             TRIM( headers.change_out_time_100 )     change_out_time_100,      -- つり銭切れ時間100円
             TRIM( headers.change_out_time_10 )      change_out_time_10,       -- つり銭切れ時間10円
             TRIM( headers.customer_number )         customer_number,          -- 顧客コード
             TRIM( headers.input_class )             input_class,              -- 入力区分
             TRIM( headers.consumption_tax_class )   consumption_tax_class,    -- 消費税区分
             headers.total_amount                    total_amount,             -- 合計金額
             headers.sale_discount_amount            sale_discount_amount,     -- 売上値引額
             headers.sales_consumption_tax           sales_consumption_tax,    -- 売上消費税額
             headers.tax_include                     tax_include,              -- 税込金額
             TRIM( headers.keep_in_code )            keep_in_code,             -- 預け先コード
             TRIM( headers.department_screen_class ) department_screen_class   -- 百貨店画面種別
      FROM   xxcos_dlv_headers_work           headers                   -- 納品ヘッダワークテーブル
      ORDER BY order_no_hht
      FOR UPDATE NOWAIT;
--****************************** 2009/05/01 1.12 MOD  END ******************************--
--
    -- 納品明細ワークテーブルデータ抽出
    CURSOR get_lines_data_cur
    IS
--****************************** 2009/05/01 1.12 MOD START ******************************--
--      SELECT lines.order_no_hht           order_no_hht,           -- 受注No.（HHT）
--             lines.line_no_hht            line_no_hht,            -- 行No.（HHT）
--             lines.order_no_ebs           order_no_ebs,           -- 受注No.（EBS）
--             lines.line_number_ebs        line_number_ebs,        -- 明細番号(EBS)
--             lines.item_code_self         item_code_self,         -- 品名コード（自社）
--             lines.case_number            case_number,            -- ケース数
--             lines.quantity               quantity,               -- 数量
--             lines.sale_class             sale_class,             -- 売上区分
--             lines.wholesale_unit_ploce   wholesale_unit_ploce,   -- 卸単価
--             lines.selling_price          selling_price,          -- 売単価
--             lines.column_no              column_no,              -- コラムNo.
--             lines.h_and_c                h_and_c,                -- H/C
--             lines.sold_out_class         sold_out_class,         -- 売切区分
--             lines.sold_out_time          sold_out_time,          -- 売切時間
--             lines.cash_and_card          cash_and_card           -- 現金・カード併用額
--      FROM   xxcos_dlv_lines_work         lines                   -- 納品明細ワークテーブル
--      ORDER BY order_no_hht, line_no_hht
--      FOR UPDATE NOWAIT;
      SELECT lines.order_no_hht           order_no_hht,           -- 受注No.（HHT）
             lines.line_no_hht            line_no_hht,            -- 行No.（HHT）
             lines.order_no_ebs           order_no_ebs,           -- 受注No.（EBS）
             lines.line_number_ebs        line_number_ebs,        -- 明細番号(EBS)
             TRIM( lines.item_code_self ) item_code_self,         -- 品名コード（自社）
             lines.case_number            case_number,            -- ケース数
             lines.quantity               quantity,               -- 数量
             TRIM( lines.sale_class )     sale_class,             -- 売上区分
             lines.wholesale_unit_ploce   wholesale_unit_ploce,   -- 卸単価
             lines.selling_price          selling_price,          -- 売単価
             TRIM( lines.column_no )      column_no,              -- コラムNo.
             TRIM( lines.h_and_c )        h_and_c,                -- H/C
             TRIM( lines.sold_out_class ) sold_out_class,         -- 売切区分
             TRIM( lines.sold_out_time )  sold_out_time,          -- 売切時間
             lines.cash_and_card          cash_and_card           -- 現金・カード併用額
      FROM   xxcos_dlv_lines_work         lines                   -- 納品明細ワークテーブル
      ORDER BY order_no_hht, line_no_hht
      FOR UPDATE NOWAIT;
--****************************** 2009/05/01 1.12 MOD  END ******************************--
--
    -- クイックコード取得：顧客ステータス
    CURSOR get_cus_status_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type = cv_qck_typ_status
      AND     look_val.lookup_code LIKE cv_qck_typ_a01
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type = cv_qck_typ_status
--      AND     look_val.lookup_code LIKE cv_qck_typ_a01
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：カード売区分
    CURSOR get_card_sales_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_card
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_card
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：入力区分（使用可能項目）
    CURSOR get_input_enabled_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：入力区分（納品データ）
    CURSOR get_input_dlv_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute3   = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute3   = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：入力区分（返品データ）
    CURSOR get_input_return_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute3   = cv_tkn_no;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute3   = cv_tkn_no;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：入力区分（フルVD納品・自動吸上）
    CURSOR get_input_auto_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute2   = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute2   = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：業態（小分類）
    CURSOR get_gyotai_sho_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_gyotai
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_gyotai
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：消費税区分
    CURSOR get_tax_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
--              look_val.attribute3   attribute3
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_tax
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_tax
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--    -- クイックコード取得：百貨店画面種別
--    CURSOR get_depart_screen_cur
--    IS
--      SELECT  look_val.lookup_code  lookup_code
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_depart
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
--
    -- クイックコード取得：品目ステータス
    CURSOR get_item_status_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_item
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_item
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：売上区分
    CURSOR get_sale_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_sale
      AND     look_val.attribute1   = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_sale
--      AND     look_val.attribute1   = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- クイックコード取得：H/C
    CURSOR get_hc_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_hc
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_hc
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出件数初期化
    on_target_cnt :=0;
    on_line_cnt   :=0;
--
    --==============================================================
    -- プロファイルの取得(XXCOI:在庫組織コード)
    --==============================================================
    lv_orga_code := FND_PROFILE.VALUE( cv_prf_orga_code );
--
    -- プロファイル取得エラーの場合
    IF ( lv_orga_code IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga_code );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- プロファイルの取得(XXCOS:MAX日付)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- プロファイル取得エラーの場合
    IF ( lv_max_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
    END IF;
--
    --==============================================================
    -- 共通関数＜在庫組織ID取得＞の呼び出し
    --==============================================================
    gn_orga_id := xxcoi_common_pkg.get_organization_id( lv_orga_code );
--
    -- 在庫組織ID取得エラーの場合
    IF ( gn_orga_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 共通関数＜業務処理日取得＞の呼び出し
    --==============================================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日取得エラーの場合
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==============================================================
    -- クイックコードの取得
    --==============================================================
    -- クイックコード取得：顧客ステータス
    BEGIN
      -- カーソルOPEN
      OPEN  get_cus_status_cur;
      -- バルクフェッチ
      FETCH get_cus_status_cur BULK COLLECT INTO gt_qck_status;
      -- カーソルCLOSE
      CLOSE get_cus_status_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：顧客ステータス
        IF ( get_cus_status_cur%ISOPEN ) THEN
          CLOSE get_cus_status_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_status );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cust_st );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：カード売区分
    BEGIN
      -- カーソルOPEN
      OPEN  get_card_sales_cur;
      -- バルクフェッチ
      FETCH get_card_sales_cur BULK COLLECT INTO gt_qck_card;
      -- カーソルCLOSE
      CLOSE get_card_sales_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：カード売区分
        IF ( get_card_sales_cur%ISOPEN ) THEN
          CLOSE get_card_sales_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_card );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_card );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：入力区分（使用可能項目）
    BEGIN
      -- カーソルOPEN
      OPEN  get_input_enabled_cur;
      -- バルクフェッチ
      FETCH get_input_enabled_cur BULK COLLECT INTO gt_qck_inp_able;
      -- カーソルCLOSE
      CLOSE get_input_enabled_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：入力区分（使用可能項目）
        IF ( get_input_enabled_cur%ISOPEN ) THEN
          CLOSE get_input_enabled_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：入力区分（納品データ）
    BEGIN
      -- カーソルOPEN
      OPEN  get_input_dlv_cur;
      -- バルクフェッチ
      FETCH get_input_dlv_cur BULK COLLECT INTO gt_qck_inp_dlv;
      -- カーソルCLOSE
      CLOSE get_input_dlv_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：入力区分（納品データ）
        IF ( get_input_dlv_cur%ISOPEN ) THEN
          CLOSE get_input_dlv_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：入力区分（返品データ）
    BEGIN
      -- カーソルOPEN
      OPEN  get_input_return_cur;
      -- バルクフェッチ
      FETCH get_input_return_cur BULK COLLECT INTO gt_qck_inp_ret;
      -- カーソルCLOSE
      CLOSE get_input_return_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：入力区分（返品データ）
        IF ( get_input_return_cur%ISOPEN ) THEN
          CLOSE get_input_return_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：入力区分（フルVD納品・自動吸上）
    BEGIN
      -- カーソルOPEN
      OPEN  get_input_auto_cur;
      -- バルクフェッチ
      FETCH get_input_auto_cur BULK COLLECT INTO gt_qck_inp_auto;
      -- カーソルCLOSE
      CLOSE get_input_auto_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：入力区分（フルVD納品・自動吸上）
        IF ( get_input_auto_cur%ISOPEN ) THEN
          CLOSE get_input_auto_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：業態（小分類）
    BEGIN
      -- カーソルOPEN
      OPEN  get_gyotai_sho_cur;
      -- バルクフェッチ
      FETCH get_gyotai_sho_cur BULK COLLECT INTO gt_qck_busi;
      -- カーソルCLOSE
      CLOSE get_gyotai_sho_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：業態（小分類）
        IF ( get_gyotai_sho_cur%ISOPEN ) THEN
          CLOSE get_gyotai_sho_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_gyotai );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_busi_low );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：消費税区分
    BEGIN
      -- カーソルOPEN
      OPEN  get_tax_class_cur;
      -- バルクフェッチ
      FETCH get_tax_class_cur BULK COLLECT INTO gt_qck_tax;
      -- カーソルCLOSE
      CLOSE get_tax_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：消費税区分
        IF ( get_tax_class_cur%ISOPEN ) THEN
          CLOSE get_tax_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_tax );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tax );
--
        RAISE lookup_types_expt;
    END;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--    -- クイックコード取得：百貨店画面種別
--    BEGIN
--      -- カーソルOPEN
--      OPEN  get_depart_screen_cur;
--      -- バルクフェッチ
--      FETCH get_depart_screen_cur BULK COLLECT INTO gt_qck_depart;
--      -- カーソルCLOSE
--      CLOSE get_depart_screen_cur;
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        -- カーソルCLOSE：クイックコード取得：百貨店画面種別
--        IF ( get_depart_screen_cur%ISOPEN ) THEN
--          CLOSE get_depart_screen_cur;
--        END IF;
----
--        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_depart );
--        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_depart );
----
--        RAISE lookup_types_expt;
--    END;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
--
    -- クイックコード取得：品目ステータス
    BEGIN
      -- カーソルOPEN
      OPEN  get_item_status_cur;
      -- バルクフェッチ
      FETCH get_item_status_cur BULK COLLECT INTO gt_qck_item;
      -- カーソルCLOSE
      CLOSE get_item_status_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：品目ステータス
        IF ( get_item_status_cur%ISOPEN ) THEN
          CLOSE get_item_status_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_item );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_st );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：売上区分
    BEGIN
      -- カーソルOPEN
      OPEN  get_sale_class_cur;
      -- バルクフェッチ
      FETCH get_sale_class_cur BULK COLLECT INTO gt_qck_sale;
      -- カーソルCLOSE
      CLOSE get_sale_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：売上区分
        IF ( get_sale_class_cur%ISOPEN ) THEN
          CLOSE get_sale_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_sale );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_sale );
--
        RAISE lookup_types_expt;
    END;
--
    -- クイックコード取得：H/C
    BEGIN
      -- カーソルOPEN
      OPEN  get_hc_class_cur;
      -- バルクフェッチ
      FETCH get_hc_class_cur BULK COLLECT INTO gt_qck_hc;
      -- カーソルCLOSE
      CLOSE get_hc_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：クイックコード取得：H/C
        IF ( get_hc_class_cur%ISOPEN ) THEN
          CLOSE get_hc_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_hc );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_h_c );
--
        RAISE lookup_types_expt;
    END;
--
    --==============================================================
    -- 納品ヘッダワークテーブルデータ取得
    --==============================================================
    BEGIN
--
      -- カーソルOPEN
      OPEN  get_headers_data_cur;
      -- バルクフェッチ
      FETCH get_headers_data_cur BULK COLLECT INTO gt_headers_work_data;
      -- 抽出件数セット
      on_target_cnt := get_headers_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_headers_data_cur;
--
    EXCEPTION
--
      -- ロックエラー
      WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
--
        -- カーソルCLOSE：納品ヘッダワークテーブルデータ取得
        IF ( get_headers_data_cur%ISOPEN ) THEN
          CLOSE get_headers_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
      -- エラー処理（データ抽出エラー）
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_get, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- 納品明細ワークテーブルデータ取得
    --==============================================================
    BEGIN
--
      -- カーソルOPEN
      OPEN  get_lines_data_cur;
      -- バルクフェッチ
      FETCH get_lines_data_cur BULK COLLECT INTO gt_lines_work_data;
      -- 抽出件数セット
      on_line_cnt := get_lines_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_lines_data_cur;
--
    EXCEPTION
--
      -- ロックエラー
      WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
--
        -- カーソルCLOSE：納品明細ワークテーブルデータ取得
        IF ( get_lines_data_cur%ISOPEN ) THEN
          CLOSE get_lines_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
      -- エラー処理（データ抽出エラー）
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_get, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
    WHEN lookup_types_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_qck_error, cv_tkn_table,  gv_tkn1,
                                                                                cv_tkn_type,   gv_tkn2,
                                                                                cv_tkn_colmun, gv_tkn3 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END dlv_data_receive;
--
  /***********************************************************************************
   * Procedure Name   : data_check
   * Description      : データ妥当性チェック(A-2)
   ***********************************************************************************/
  PROCEDURE data_check(
    in_line_cnt       IN  NUMBER,           --   処理件数（明細部）
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- プログラム名
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
    cv_month     CONSTANT VARCHAR2(5) := 'MONTH';
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--    cv_ar_class  CONSTANT VARCHAR2(2) := '02';
    cv_inv_class CONSTANT VARCHAR2(2) := '01';
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
    cv_open      CONSTANT VARCHAR2(4) := 'OPEN';
--***************************** 2009/04/10 1.8 T.Kitajima ADD START  *****************************--
    ct_hht_2     CONSTANT xxcmm_cust_accounts.dept_hht_div%TYPE          := '2';    -- 百貨店用HHT区分
    ct_disp_0    CONSTANT xxcos_dlv_headers.department_screen_class%TYPE := '0';    -- 百貨店画面種別
--***************************** 2009/04/10 1.8 T.Kitajima ADD START  *****************************--
--
    -- *** ローカル型   ***
    -- 納品明細データ一時格納用変数
    TYPE l_rec_line_temp IS RECORD
      (
        order_nol_hht        xxcos_dlv_lines.order_no_hht%TYPE,                 -- 受注No.(HHT)
        line_no_hht          xxcos_dlv_lines.line_no_hht%TYPE,                  -- 行No.(HHT)
        order_nol_ebs        xxcos_dlv_lines.order_no_ebs%TYPE,                 -- 受注No.(EBS)
        line_number          xxcos_dlv_lines.line_number_ebs%TYPE,              -- 明細番号(EBS)
        item_code            xxcos_dlv_lines.item_code_self%TYPE,               -- 品名コード(自社)
        content              xxcos_dlv_lines.content%TYPE,                      -- 入数
        item_id              xxcos_dlv_lines.inventory_item_id%TYPE,            -- 品目ID
        standard_unit        xxcos_dlv_lines.standard_unit%TYPE,                -- 基準単位
        case_number          xxcos_dlv_lines.case_number%TYPE,                  -- ケース数
        quantity             xxcos_dlv_lines.quantity%TYPE,                     -- 数量
        sale_class           xxcos_dlv_lines.sale_class%TYPE,                   -- 売上区分
        wholesale_price      xxcos_dlv_lines.wholesale_unit_ploce%TYPE,         -- 卸単価
        selling_price        xxcos_dlv_lines.selling_price%TYPE,                -- 売単価
        column_no            xxcos_dlv_lines.column_no%TYPE,                    -- コラムNo.
        h_and_c              xxcos_dlv_lines.h_and_c%TYPE,                      -- H/C
        sold_out_class       xxcos_dlv_lines.sold_out_class%TYPE,               -- 売切区分
        sold_out_time        xxcos_dlv_lines.sold_out_time%TYPE,                -- 売切時間
        replenish_num        xxcos_dlv_lines.replenish_number%TYPE,             -- 補充数
        cash_and_card        xxcos_dlv_lines.cash_and_card%TYPE                 -- 現金・カード併用額
      );
    TYPE l_tab_line_temp IS TABLE OF l_rec_line_temp INDEX BY PLS_INTEGER;
--
    -- *** ローカル変数 ***
    lt_line_temp   l_tab_line_temp;       -- 納品明細データ一時格納用
--
    -- 納品ヘッダデータ変数
    lt_order_noh_hht        xxcos_dlv_headers.order_no_hht%TYPE;               -- 受注No.(HHT)
    lt_order_noh_ebs        xxcos_dlv_headers.order_no_ebs%TYPE;               -- 受注No.(EBS)
    lt_base_code            xxcos_dlv_headers.base_code%TYPE;                  -- 拠点コード
    lt_performance_code     xxcos_dlv_headers.performance_by_code%TYPE;        -- 成績者コード
    lt_dlv_code             xxcos_dlv_headers.dlv_by_code%TYPE;                -- 納品者コード
    lt_hht_invoice_no       xxcos_dlv_headers.hht_invoice_no%TYPE;             -- HHT伝票No.
    lt_dlv_date             xxcos_dlv_headers.dlv_date%TYPE;                   -- 納品日
    lt_inspect_date         xxcos_dlv_headers.inspect_date%TYPE;               -- 検収日
    lt_sales_class          xxcos_dlv_headers.sales_classification%TYPE;       -- 売上分類区分
    lt_sales_invoice        xxcos_dlv_headers.sales_invoice%TYPE;              -- 売上伝票区分
    lt_card_sale_class      xxcos_dlv_headers.card_sale_class%TYPE;            -- カード売区分
    lt_dlv_time             xxcos_dlv_headers.dlv_time%TYPE;                   -- 時間
    lt_change_out_100       xxcos_dlv_headers.change_out_time_100%TYPE;        -- つり銭切れ時間100円
    lt_change_out_10        xxcos_dlv_headers.change_out_time_10%TYPE;         -- つり銭切れ時間10円
    lt_customer_number      xxcos_dlv_headers.customer_number%TYPE;            -- 顧客コード
    lt_system_class         xxcos_dlv_headers.system_class%TYPE;               -- 業態区分
    lt_input_class          xxcos_dlv_headers.input_class%TYPE;                -- 入力区分
    lt_tax_class            xxcos_dlv_headers.consumption_tax_class%TYPE;      -- 消費税区分
    lt_total_amount         xxcos_dlv_headers.total_amount%TYPE;               -- 合計金額
    lt_sale_discount        xxcos_dlv_headers.sale_discount_amount%TYPE;       -- 売上値引額
    lt_sales_tax            xxcos_dlv_headers.sales_consumption_tax%TYPE;      -- 売上消費税額
    lt_tax_include          xxcos_dlv_headers.tax_include%TYPE;                -- 税込金額
    lt_keep_in_code         xxcos_dlv_headers.keep_in_code%TYPE;               -- 預け先コード
    lt_department_class     xxcos_dlv_headers.department_screen_class%TYPE;    -- 百貨店画面種別
--
    -- 納品明細データ変数
    lt_order_nol_hht        xxcos_dlv_lines.order_no_hht%TYPE;                 -- 受注No.(HHT)
    lt_line_no_hht          xxcos_dlv_lines.line_no_hht%TYPE;                  -- 行No.(HHT)
    lt_order_nol_ebs        xxcos_dlv_lines.order_no_ebs%TYPE;                 -- 受注No.(EBS)
    lt_line_number          xxcos_dlv_lines.line_number_ebs%TYPE;              -- 明細番号(EBS)
    lt_item_code            xxcos_dlv_lines.item_code_self%TYPE;               -- 品名コード(自社)
    lt_content              xxcos_dlv_lines.content%TYPE;                      -- 入数
    lt_item_id              xxcos_dlv_lines.inventory_item_id%TYPE;            -- 品目ID
    lt_standard_unit        xxcos_dlv_lines.standard_unit%TYPE;                -- 基準単位
    lt_case_number          xxcos_dlv_lines.case_number%TYPE;                  -- ケース数
    lt_quantity             xxcos_dlv_lines.quantity%TYPE;                     -- 数量
    lt_sale_class           xxcos_dlv_lines.sale_class%TYPE;                   -- 売上区分
    lt_wholesale_price      xxcos_dlv_lines.wholesale_unit_ploce%TYPE;         -- 卸単価
    lt_selling_price        xxcos_dlv_lines.selling_price%TYPE;                -- 売単価
    lt_column_no            xxcos_dlv_lines.column_no%TYPE;                    -- コラムNo.
    lt_h_and_c              xxcos_dlv_lines.h_and_c%TYPE;                      -- H/C
    lt_sold_out_class       xxcos_dlv_lines.sold_out_class%TYPE;               -- 売切区分
    lt_sold_out_time        xxcos_dlv_lines.sold_out_time%TYPE;                -- 売切時間
    lt_replenish_num        xxcos_dlv_lines.replenish_number%TYPE;             -- 補充数
    lt_cash_and_card        xxcos_dlv_lines.cash_and_card%TYPE;                -- 現金・カード併用額
--
    -- エラーデータ変数
    lt_base_name            xxcos_rep_hht_err_list.base_name%TYPE;             -- 拠点名称
    lt_data_name            xxcos_rep_hht_err_list.data_name%TYPE;             -- データ名称
    lt_customer_name        xxcos_rep_hht_err_list.customer_name%TYPE;         -- 顧客名
--
    lt_customer_id          hz_cust_accounts.cust_account_id%TYPE;             -- 顧客ID
    lt_party_id             hz_parties.party_id%TYPE;                          -- パーティID
    lt_sale_base            xxcmm_cust_accounts.sale_base_code%TYPE;           -- 売上拠点コード
    lt_past_sale_base       xxcmm_cust_accounts.past_sale_base_code%TYPE;      -- 前月売上拠点コード
    lt_cus_status           hz_parties.duns_number_c%TYPE;                     -- 顧客ステータス
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--    lt_charge_person        jtf_rs_resource_extns.source_number%TYPE;          -- 担当営業員
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
    lt_bus_low_type         xxcmm_cust_accounts.business_low_type%TYPE;        -- 業態（小分類）
    lt_hht_class            xxcmm_cust_accounts.dept_hht_div%TYPE;             -- 百貨店用HHT区分
    lt_base_perf            per_all_assignments_f.ass_attribute5%TYPE;         -- 拠点コード（成績者）
    lt_base_dlv             per_all_assignments_f.ass_attribute5%TYPE;         -- 拠点コード（納品者）
    lt_in_case              ic_item_mst_b.attribute11%TYPE;                    -- 品目マスタ：ケース入数
    lt_sale_object          ic_item_mst_b.attribute26%TYPE;                    -- 品目マスタ：売上対象区分
    lt_item_status          xxcmm_system_items_b.item_status%TYPE;             -- 品目マスタ：品目ステータス
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
    lt_card_company         xxcmm_cust_accounts.card_company%TYPE;              -- カード会社
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--    lt_vd_column            xxcoi_mst_vd_column.column_no%TYPE;                -- VDコラムマスタ：コラムNo.
--    lt_vd_hc                xxcoi_mst_vd_column.hot_cold%TYPE;                 -- VDコラムマスタ：H/C
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
    lv_err_flag             VARCHAR2(1)  DEFAULT  '0';                         -- エラーフラグ
    lv_err_flag_time        VARCHAR2(1)  DEFAULT  '0';                         -- エラーフラグ（時間形式判定）
    lv_bad_sale             VARCHAR2(1)  DEFAULT  '0';                         -- 売上対象区分：売上不可
    ln_err_no               NUMBER  DEFAULT  '1';                              -- エラー配列ナンバー
    ln_line_cnt             NUMBER  DEFAULT  '1';                              -- 明細チェック済番号
    ln_temp_no              NUMBER  DEFAULT  '1';                              -- 明細一時格納用配列ナンバー
    ln_header_ok_no         NUMBER  DEFAULT  '1';                              -- 正常値配列ナンバー（ヘッダ）
    ln_line_ok_no           NUMBER  DEFAULT  '1';                              -- 正常値配列ナンバー（明細）
    ld_process_date         DATE;                                              -- カレント月の翌月
-- ******* 2009/10/01 N.Maeda MOD START ********* --
    lv_return_data          xxcos_rep_hht_err_list.data_name%TYPE;             -- 返品データ
--    lv_return_data          VARCHAR2(10);                                      -- 返品データ
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
-- ******************** 2009/11/25 1.18 N.Maeda DEL  START  ****************** --
--    lv_column_check         VARCHAR2(18);                                      -- 顧客ID、コラムNo.の結合した値
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
    ln_time_char            NUMBER;                                            -- 時間の文字列チェック
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--    lv_status               VARCHAR2(5);                                       -- AR会計期間チェック：ステータスの種類
--    ln_from_date            DATE;                                              -- AR会計期間チェック：会計（FROM）
--    ln_to_date              DATE;                                              -- AR会計期間チェック：会計（TO）
    lv_status               VARCHAR2(5);                                       -- INV会計期間チェック：ステータスの種類
    ln_from_date            DATE;                                              -- INV会計期間チェック：会計（FROM）
    ln_to_date              DATE;                                              -- INV会計期間チェック：会計（TO）
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
    lt_resource_id          jtf_rs_resource_extns.resource_id%TYPE;            -- リソースID
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
    lv_tbl_key              VARCHAR2(20);                                      -- 参照テーブルのキー値
    lv_time_fmt             CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami ADD START *****************************-- 
    lv_index_key            VARCHAR2(15);                                       -- 顧客情報検索時のKEY
--****************************** 2011/02/03 1.25 Y.Kanami ADD END *******************************--
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
    -- ループ開始：ヘッダ部
    FOR ck_no IN 1..gn_tar_cnt_h LOOP
--
      -- エラーフラグ初期化
      lv_err_flag := cv_default;
--
      -- データ取得：ヘッダ
      lt_order_noh_hht    := gt_headers_work_data(ck_no).order_no_hht;        -- 受注No.（HHT)
      lt_order_noh_ebs    := gt_headers_work_data(ck_no).order_no_ebs;        -- 受注No.（EBS）
      lt_base_code        := gt_headers_work_data(ck_no).base_code;           -- 拠点コード
      lt_performance_code := gt_headers_work_data(ck_no).perform_code;        -- 成績者コード
      lt_dlv_code         := gt_headers_work_data(ck_no).dlv_by_code;         -- 納品者コード
      lt_hht_invoice_no   := gt_headers_work_data(ck_no).hht_invoice_no;      -- HHT伝票No.
      lt_dlv_date         := gt_headers_work_data(ck_no).dlv_date;            -- 納品日
      lt_inspect_date     := gt_headers_work_data(ck_no).inspect_date;        -- 検収日
      lt_sales_class      := gt_headers_work_data(ck_no).sales_class;         -- 売上分類区分
      lt_sales_invoice    := gt_headers_work_data(ck_no).sales_invoice;       -- 売上伝票区分
      lt_card_sale_class  := gt_headers_work_data(ck_no).card_class;          -- カード売区分
      lt_dlv_time         := gt_headers_work_data(ck_no).dlv_time;            -- 時間
      lt_change_out_100   := gt_headers_work_data(ck_no).change_time_100;     -- つり銭切れ時間100円
      lt_change_out_10    := gt_headers_work_data(ck_no).change_time_10;      -- つり銭切れ時間10円
      lt_customer_number  := gt_headers_work_data(ck_no).cus_number;          -- 顧客コード
      lt_input_class      := gt_headers_work_data(ck_no).input_class;         -- 入力区分
      lt_tax_class        := gt_headers_work_data(ck_no).tax_class;           -- 消費税区分
      lt_total_amount     := gt_headers_work_data(ck_no).total_amount;        -- 合計金額
      lt_sale_discount    := gt_headers_work_data(ck_no).sale_discount;       -- 売上値引額
      lt_sales_tax        := gt_headers_work_data(ck_no).sales_tax;           -- 売上消費税額
      lt_tax_include      := gt_headers_work_data(ck_no).tax_include;         -- 税込金額
      lt_keep_in_code     := gt_headers_work_data(ck_no).keep_in_code;        -- 預け先コード
      lt_department_class := gt_headers_work_data(ck_no).depart_screen;       -- 百貨店画面種別
--
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
      -- 初期化 --
      lt_base_name     := NULL;     -- 拠点名称
      lt_data_name     := NULL;     -- データ名称
      lt_customer_name := NULL;     -- 顧客名
      lt_bus_low_type  := NULL;     -- 業態小分類
  /*-----2009/02/03-----END-------------------------------------------------------------------------------*/
      --== データ名称判定 ==--
      -- データ名称取得
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_delivery );
--      lv_return_data := xxccp_common_pkg.get_msg( cv_application, cv_msg_return );
      gv_tkn1        := SUBSTRB(xxccp_common_pkg.get_msg( cv_application, cv_msg_delivery ),1,20);
      lv_return_data := SUBSTRB(xxccp_common_pkg.get_msg( cv_application, cv_msg_return ),1,20);
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
      FOR i IN 1..gt_qck_inp_dlv.COUNT LOOP
        IF ( gt_qck_inp_dlv(i) = lt_input_class ) THEN
          lt_data_name := gv_tkn1;                -- データ名称セット：納品データ
          EXIT;
        END IF;
      END LOOP;
--
      FOR i IN 1..gt_qck_inp_ret.COUNT LOOP
        IF ( gt_qck_inp_ret(i) = lt_input_class ) THEN
          lt_data_name := lv_return_data;       -- データ名称セット：返品データ
          EXIT;
        END IF;
      END LOOP;
--
      --==============================================================
      --拠点コード、顧客コードの妥当性チェック（ヘッダ部）
      --==============================================================
--
--****************************** 2009/05/15 1.14 N.Maeda DEL START ******************************--
--      BEGIN
--****************************** 2009/05/15 1.14 N.Maeda DEL  END  ******************************--
--
        --変数の初期化
        lt_customer_name   := NULL;
        lt_customer_id     := NULL;
        lt_party_id        := NULL;
        lt_sale_base       := NULL;
        lt_past_sale_base  := NULL;
        lt_cus_status      := NULL;
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--        lt_charge_person   := NULL;
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
        lt_resource_id     := NULL;
        lt_bus_low_type    := NULL;
        lt_base_name       := NULL;
        lt_hht_class       := NULL;
        lt_base_perf       := NULL;
        lt_base_dlv        := NULL;
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
        lt_card_company    := NULL;
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
--
--****************************** 2011/02/03 1.25 Y.Kanami ADD START *****************************-- 
        -- 顧客マスタデータチェック用INDEX
        lv_index_key  :=  lt_customer_number||TO_CHAR(lt_dlv_date,'YYYYMM');
--****************************** 2011/02/03 1.25 Y.Kanami ADD END *******************************--
        --== 顧客マスタデータ抽出 ==--
        -- 既に取得済みの値であるかを確認する。
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--      IF ( gt_select_cus.EXISTS(lt_customer_number) ) THEN
--        lt_customer_name  := SUBSTRB( gt_select_cus(lt_customer_number).customer_name, 1, 40 );   -- 顧客名称
--        lt_customer_id    := gt_select_cus(lt_customer_number).customer_id;     -- 顧客ID
--        lt_party_id       := gt_select_cus(lt_customer_number).party_id;        -- パーティID
--        lt_sale_base      := gt_select_cus(lt_customer_number).sale_base;       -- 売上拠点コード
--        lt_past_sale_base := gt_select_cus(lt_customer_number).past_sale_base;  -- 前月売上拠点コード
--        lt_cus_status     := gt_select_cus(lt_customer_number).cus_status;      -- 顧客ステータス
      IF ( gt_select_cus.EXISTS(lv_index_key) ) THEN
        lt_customer_name  := SUBSTRB( gt_select_cus(lv_index_key).customer_name, 1, 40 );   -- 顧客名称
        lt_customer_id    := gt_select_cus(lv_index_key).customer_id;     -- 顧客ID
        lt_party_id       := gt_select_cus(lv_index_key).party_id;        -- パーティID
        lt_sale_base      := gt_select_cus(lv_index_key).sale_base;       -- 売上拠点コード
        lt_past_sale_base := gt_select_cus(lv_index_key).past_sale_base;  -- 前月売上拠点コード
        lt_cus_status     := gt_select_cus(lv_index_key).cus_status;      -- 顧客ステータス
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--

--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--          lt_charge_person  := gt_select_cus(lt_customer_number).charge_person;   -- 担当営業員
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--        lt_resource_id    := gt_select_cus(lt_customer_number).resource_id;     -- リソースID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--        lt_bus_low_type   := gt_select_cus(lt_customer_number).bus_low_type;    -- 業態（小分類）
--        lt_base_name      := SUBSTRB( gt_select_cus(lt_customer_number).base_name, 1, 30 );       -- 拠点名称
--        lt_hht_class      := gt_select_cus(lt_customer_number).dept_hht_div;    -- 百貨店用HHT区分
        lt_bus_low_type   := gt_select_cus(lv_index_key).bus_low_type;                  -- 業態（小分類）
        lt_base_name      := SUBSTRB( gt_select_cus(lv_index_key).base_name, 1, 30 );   -- 拠点名称
        lt_hht_class      := gt_select_cus(lv_index_key).dept_hht_div;                  -- 百貨店用HHT区分
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--        lt_base_perf      := gt_select_cus(lt_customer_number).base_perf;       -- 拠点コード（成績者）
--        lt_base_dlv       := gt_select_cus(lt_customer_number).base_dlv;        -- 拠点コード（納品者）
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--        lt_card_company   := gt_select_cus(lt_customer_number).card_company;    -- カード会社
        lt_card_company   := gt_select_cus(lv_index_key).card_company;              -- カード会社
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      ELSE
--****************************** 2009/05/15 1.14 N.Maeda MOD START ******************************--
--          SELECT SUBSTRB(parties.party_name,1,40)  party_name,                    -- 顧客名称
--                 cust.cust_account_id         cust_account_id,                    -- 顧客ID
--                 cust.party_id                party_id,                           -- パーティID
--                 custadd.sale_base_code       sale_base_code,                     -- 売上拠点コード
--                 custadd.past_sale_base_code  past_sale_base_code,                -- 前月売上拠点コード
--                 parties.duns_number_c        customer_status,                    -- 顧客ステータス
----****************************** 2009/04/10 1.9 N.Maeda MOD START ******************************--
----                 salesreps.employee_number    employee_number,                    -- 担当営業員
----                 salesreps.resource_id        resource_id,                        -- リソースID
--                 rivp.resource_id             resource_id,                        -- リソースID
----****************************** 2009/04/10 1.9 N.Maeda MOD END ******************************--
--                 custadd.business_low_type    business_low_type,                  -- 業態（小分類）
--                 SUBSTRB(base.account_name,1,30)  account_name,                   -- 拠点名称
--                 baseadd.dept_hht_div         dept_hht_div,                       -- 百貨店用HHT区分
--                 rivp.base_code               base_code,                          -- 拠点コード（成績者）
--                 rivd.base_code               base_code                           -- 拠点コード（納品者）
--          INTO   lt_customer_name,
--                 lt_customer_id,
--                 lt_party_id,
--                 lt_sale_base,
--                 lt_past_sale_base,
--                 lt_cus_status,
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----                 lt_charge_person,
----****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--                 lt_resource_id,
--                 lt_bus_low_type,
--                 lt_base_name,
--                 lt_hht_class,
--                 lt_base_perf,
--                 lt_base_dlv
--          FROM   hz_cust_accounts     cust,                    -- 顧客マスタ
--                 hz_cust_accounts     base,                    -- 拠点マスタ
--                 hz_parties           parties,                 -- パーティ
--                 xxcmm_cust_accounts  custadd,                 -- 顧客追加情報_顧客
--                 xxcmm_cust_accounts  baseadd,                 -- 顧客追加情報_拠点
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----                 xxcos_salesreps_v    salesreps,               -- 担当営業員view
----****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
--                 xxcos_rs_info_v      rivp,                    -- 営業員情報view（成績者）
--                 xxcos_rs_info_v      rivd,                    -- 営業員情報view（納品者）
--                 (
--                   SELECT  look_val.meaning      cus
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_typ_cus
--                   AND     look_val.attribute1   = cv_tkn_yes
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                 ) cust_class,   -- 顧客区分（'10'(顧客) , '12'(上様)）
--                 (
--                   SELECT  look_val.meaning      base
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_typ_cus
--                   AND     look_val.attribute2   = cv_tkn_yes
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                 ) base_class    -- 顧客区分（'1'(拠点)）
--          WHERE  cust.customer_class_code = cust_class.cus       -- 顧客マスタ.顧客区分 = '10'(顧客) or '12'(上様)
--            AND  base.customer_class_code = base_class.base      -- 拠点マスタ.顧客区分 = '1'(拠点)
--            AND  cust.account_number      = lt_customer_number   -- 顧客マスタ.顧客コード=抽出した顧客コード
--            AND  cust.party_id            = parties.party_id     -- 顧客マスタ.パーティID=パーティ.パーティID
--            AND  cust.cust_account_id     = custadd.customer_id  -- 顧客マスタ.顧客ID=顧客追加情報.顧客ID
----****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
--            AND  lt_base_code             = base.account_number  -- 抽出した拠点コード=拠点マスタ.顧客コード
----            AND  custadd.sale_base_code   = base.account_number  -- 顧客追加情報_顧客.売上拠点=拠点マスタ.顧客コード
----****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
--            AND  base.cust_account_id     = baseadd.customer_id  -- 拠点マスタ.顧客ID=顧客追加情報_拠点.顧客ID
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----            AND  (
----                    salesreps.account_number = lt_customer_number  -- 担当営業員view.顧客番号 = 抽出した顧客コード
----                  AND                                              -- 納品日の適用範囲
----                    lt_dlv_date >= NVL(salesreps.effective_start_date, gd_process_date)
----                  AND
----                    lt_dlv_date <= NVL(salesreps.effective_end_date, gd_max_date)
----                 )
----****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--            AND  (
--                    rivp.employee_number = lt_performance_code  -- 営業員情報view(成績者).顧客番号 = 抽出した成績者
--                  AND                                           -- 納品日の適用範囲
--                    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)
--                  AND
--                    lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
--                  AND
--                    lt_dlv_date >= rivp.per_effective_start_date
--                  AND
--                    lt_dlv_date <= rivp.per_effective_end_date
--                  AND
--                    lt_dlv_date >= rivp.paa_effective_start_date
--                  AND
--                    lt_dlv_date <= rivp.paa_effective_end_date
--                 )
--            AND  (
--                    rivd.employee_number = lt_dlv_code          -- 営業員情報view(納品者).顧客番号 = 抽出した納品者
--                  AND                                           -- 納品日の適用範囲
--                    lt_dlv_date >= NVL(rivd.effective_start_date, gd_process_date)
--                  AND
--                    lt_dlv_date <= NVL(rivd.effective_end_date, gd_max_date)
--                  AND
--                    lt_dlv_date >= rivd.per_effective_start_date
--                  AND
--                    lt_dlv_date <= rivd.per_effective_end_date
--                  AND
--                    lt_dlv_date >= rivd.paa_effective_start_date
--                  AND
--                    lt_dlv_date <= rivd.paa_effective_end_date
--                 );
----
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- 顧客名称
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- 顧客ID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- パーティID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- 売上拠点コード
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- 前月売上拠点コード
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- 顧客ステータス
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----          gt_select_cus(lt_customer_number).charge_person  := lt_charge_person;   -- 担当営業員
----****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--          gt_select_cus(lt_customer_number).resource_id    := lt_resource_id;     -- リソースID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- 業態（小分類）
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- 拠点名称
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- 百貨店用HHT区分
--          gt_select_cus(lt_customer_number).base_perf      := lt_base_perf;       -- 拠点コード（成績者）
--          gt_select_cus(lt_customer_number).base_dlv       := lt_base_dlv;        -- 拠点コード（納品者）
        BEGIN
          SELECT SUBSTRB(parties.party_name,1,40)  party_name,                    -- 顧客名称
                 cust.cust_account_id         cust_account_id,                    -- 顧客ID
                 cust.party_id                party_id,                           -- パーティID
                 custadd.sale_base_code       sale_base_code,                     -- 売上拠点コード
                 custadd.past_sale_base_code  past_sale_base_code,                -- 前月売上拠点コード
                 parties.duns_number_c        customer_status,                    -- 顧客ステータス
                 custadd.business_low_type    business_low_type,                  -- 業態（小分類）
                 SUBSTRB(base.account_name,1,30)  account_name,                   -- 拠点名称
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--                 baseadd.dept_hht_div         dept_hht_div                        -- 百貨店用HHT区分
                 baseadd.dept_hht_div         dept_hht_div,                       -- 百貨店用HHT区分
                 custadd.card_company         card_company                        -- カード会社
--****************************** 2010/01/18 1.21 M.Uehara MOD END   *******************************--
          INTO   lt_customer_name,
                 lt_customer_id,
                 lt_party_id,
                 lt_sale_base,
                 lt_past_sale_base,
                 lt_cus_status,
                 lt_bus_low_type,
                 lt_base_name,
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--                 lt_hht_class
                 lt_hht_class,
                 lt_card_company
--****************************** 2010/01/18 1.21 M.Uehara MOD END   *******************************--
          FROM   hz_cust_accounts     cust,                    -- 顧客マスタ
                 hz_cust_accounts     base,                    -- 拠点マスタ
                 hz_parties           parties,                 -- パーティ
                 xxcmm_cust_accounts  custadd,                 -- 顧客追加情報_顧客
                 xxcmm_cust_accounts  baseadd,                 -- 顧客追加情報_拠点
                 (
                   SELECT  look_val.meaning      cus
-- ******* 2009/10/01 N.Maeda MOD START ********* --
                   FROM    fnd_lookup_values     look_val
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
                   WHERE     look_val.language = cv_user_lang
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                   AND     look_val.lookup_type  = cv_qck_typ_cus
                   AND     look_val.attribute1   = cv_tkn_yes
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                 ) cust_class,   -- 顧客区分（'10'(顧客) , '12'(上様)）
                 (
                   SELECT  look_val.meaning      base
-- ******* 2009/10/01 N.Maeda MOD START ********* --
                   FROM    fnd_lookup_values     look_val
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
                   WHERE     look_val.language = cv_user_lang
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                   AND     look_val.lookup_type  = cv_qck_typ_cus
                   AND     look_val.attribute2   = cv_tkn_yes
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                 ) base_class    -- 顧客区分（'1'(拠点)）
          WHERE  cust.customer_class_code = cust_class.cus       -- 顧客マスタ.顧客区分 = '10'(顧客) or '12'(上様)
            AND  base.customer_class_code = base_class.base      -- 拠点マスタ.顧客区分 = '1'(拠点)
            AND  cust.account_number      = lt_customer_number   -- 顧客マスタ.顧客コード=抽出した顧客コード
            AND  cust.party_id            = parties.party_id     -- 顧客マスタ.パーティID=パーティ.パーティID
            AND  cust.cust_account_id     = custadd.customer_id  -- 顧客マスタ.顧客ID=顧客追加情報.顧客ID
            AND  lt_base_code             = base.account_number  -- 抽出した拠点コード=拠点マスタ.顧客コード
            AND  base.cust_account_id     = baseadd.customer_id;  -- 拠点マスタ.顧客ID=顧客追加情報_拠点.顧客ID;
--
--        END IF;
--****************************** 2009/05/15 1.14 N.Maeda MOD  END  ******************************--
--
--
          --== 顧客ステータスチェック ==--
          FOR i IN 1..gt_qck_status.COUNT LOOP
            EXIT WHEN gt_qck_status(i) = lt_cus_status;
            IF ( i = gt_qck_status.COUNT ) THEN
              -- ログ出力
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_status );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
              ln_err_no := ln_err_no + 1;
              -- エラーフラグ更新
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
--
          --== 売上拠点コードチェック ==--
          -- 売上拠点コードと前月売上拠点コードの使用判定
          IF ( TRUNC( lt_dlv_date, cv_month ) < TRUNC( gd_process_date, cv_month ) ) THEN
            lt_sale_base := NVL( lt_past_sale_base, lt_sale_base );
          END IF;
--
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
        -- 一般拠点の場合
--      IF ( lt_hht_class = cv_general ) THEN
--***************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
--        IF ( lt_hht_class IS NULL ) THEN
          IF ( lt_hht_class IS NULL ) 
            OR ( ( lt_hht_class = ct_hht_2 )
                 AND
                 (lt_department_class = ct_disp_0 )
               )
            THEN
--***************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
            -- 売上拠点コード妥当性チェック
            IF ( ( lt_sale_base != lt_base_code ) OR ( lt_base_code IS NULL ) ) THEN
              -- ログ出力
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_base );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                 -- 拠点コード
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);           -- 顧客コード
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);          -- 成績者コード
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
              ln_err_no := ln_err_no + 1;
              -- エラーフラグ更新
              lv_err_flag := cv_hit;
            END IF;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ログ出力
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
            gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                   cv_tkn_table,   gv_tkn1,
                                                   cv_tkn_colmun,  gv_tkn2 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
        END;
--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************-- 
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
--        IF ( lv_err_flag <> cv_hit ) THEN
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- 顧客名称
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- 顧客ID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- パーティID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- 売上拠点コード
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- 前月売上拠点コード
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- 顧客ステータス
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- 業態（小分類）
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- 拠点名称
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- 百貨店用HHT区分
----****************************** 2010/01/27 1.22 N.Maeda ADD START *******************************--
--          gt_select_cus(lt_customer_number).card_company   := lt_card_company;    -- カード会社
----****************************** 2010/01/27 1.22 N.Maeda ADD START *******************************--
        IF ( lv_err_flag <> cv_hit ) THEN
          gt_select_cus(lv_index_key).customer_name  := lt_customer_name;   -- 顧客名称
          gt_select_cus(lv_index_key).customer_id    := lt_customer_id;     -- 顧客ID
          gt_select_cus(lv_index_key).party_id       := lt_party_id;        -- パーティID
          gt_select_cus(lv_index_key).sale_base      := lt_sale_base;       -- 売上拠点コード
          gt_select_cus(lv_index_key).past_sale_base := lt_past_sale_base;  -- 前月売上拠点コード
          gt_select_cus(lv_index_key).cus_status     := lt_cus_status;      -- 顧客ステータス
          gt_select_cus(lv_index_key).bus_low_type   := lt_bus_low_type;    -- 業態（小分類）
          gt_select_cus(lv_index_key).base_name      := lt_base_name;       -- 拠点名称
          gt_select_cus(lv_index_key).dept_hht_div   := lt_hht_class;       -- 百貨店用HHT区分
          gt_select_cus(lv_index_key).card_company   := lt_card_company;    -- カード会社
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
        END IF;
--
      END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--****************************** 2009/04/14 1.10 T.Kitajima MOD START ******************************--
--      --==============================================================
--      --成績者コードの妥当性チェック（ヘッダ部）
--      --==============================================================
--      IF ( lt_base_perf != lt_sale_base ) THEN
--        -- ログ出力
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_disagree );
--        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--        ov_retcode := cv_status_warn;
--        -- エラー変数へ格納
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
--        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
--        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
--        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
--        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
--        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
--        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
--        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
--        ln_err_no := ln_err_no + 1;
--        -- エラーフラグ更新
--        lv_err_flag := cv_hit;
--      END IF;
--      --==============================================================
--      --納品者コードの妥当性チェック（ヘッダ部）
--      --==============================================================
--      IF ( lt_base_dlv != lt_sale_base ) THEN
--        -- ログ出力
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_belong );
--        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--        ov_retcode := cv_status_warn;
--        -- エラー変数へ格納
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
--        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
--        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
--        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
--        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
--        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
--        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
--        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
--        ln_err_no := ln_err_no + 1;
--        -- エラーフラグ更新
--        lv_err_flag := cv_hit;
--      END IF;
--
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
      BEGIN
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
        -- 成績者コード抽出項目テーブルのキー値を取得(成績者コード,納品日)
        lv_tbl_key   := lt_performance_code || TO_CHAR(lt_dlv_date, lv_time_type);
        -- 拠点コード（成績者）を取得
        lt_base_perf := NULL;
        IF ( gt_select_perf.EXISTS(lv_tbl_key) ) THEN
          lt_base_perf := gt_select_perf(lv_tbl_key).base_perf;  -- 納品コード（成績者）
        ELSE
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
          SELECT rivp.base_code       base_code              -- 拠点コード（成績者）
          INTO   lt_base_perf
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivp                   -- 営業員情報view（成績者）
          FROM   xxcos_rs_info2_v     rivp                   -- 営業員情報view（成績者）
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
          WHERE  rivp.employee_number = lt_performance_code  -- 営業員情報view(成績者).顧客番号 = 抽出した成績者
          AND    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)-- 納品日の適用範囲
          AND   lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
          AND   lt_dlv_date >= rivp.per_effective_start_date
          AND   lt_dlv_date <= rivp.per_effective_end_date
          AND   lt_dlv_date >= rivp.paa_effective_start_date
          AND   lt_dlv_date <= rivp.paa_effective_end_date;
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- 配列に格納
          gt_select_perf(lv_tbl_key).base_perf := lt_base_perf;  -- 納品コード（成績者）
        END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--
        --一般拠点の場合はチェックする。
        IF ( lt_hht_class IS NULL ) 
          OR ( ( lt_hht_class = ct_hht_2 )
            AND (lt_department_class = ct_disp_0 )
        )
        THEN
          --==============================================================
          --成績者コードの妥当性チェック（ヘッダ部）
          --==============================================================
          IF ( lt_base_perf != lt_sale_base ) THEN
            -- ログ出力
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_disagree );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- ログ出力
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_emp_mst );
        gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_paf_emp );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                             cv_tkn_table,   gv_tkn1,
                                             cv_tkn_colmun,  gv_tkn2 );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      END;
--
      BEGIN
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
        -- 成績者コード抽出項目テーブルのキー値を取得(成績者コード,納品日)
        lv_tbl_key   := lt_dlv_code || TO_CHAR(lt_dlv_date, lv_time_type);
        -- 拠点コード（納品者）、リソースIDを取得
        lt_resource_id := NULL;
        lt_base_dlv    := NULL;
        IF ( gt_select_dlv.EXISTS(lv_tbl_key) ) THEN
          lt_resource_id := gt_select_dlv(lv_tbl_key).resource_id;  -- リソースID
          lt_base_dlv    := gt_select_dlv(lv_tbl_key).base_dlv;     -- 拠点コード（納品者）
        ELSE
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
          SELECT rivd.base_code       base_code                           -- 拠点コード（納品者）
          INTO   lt_base_dlv
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivd                    -- 営業員情報view（納品者）
          FROM   xxcos_rs_info2_v     rivd                   -- 営業員情報view（納品者）
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
          WHERE  rivd.employee_number = lt_dlv_code          -- 営業員情報view(納品者).顧客番号 = 抽出した納品者
          AND    lt_dlv_date >= NVL(rivd.effective_start_date, gd_process_date)-- 納品日の適用範囲
          AND    lt_dlv_date <= NVL(rivd.effective_end_date, gd_max_date)
          AND    lt_dlv_date >= rivd.per_effective_start_date
          AND    lt_dlv_date <= rivd.per_effective_end_date
          AND    lt_dlv_date >= rivd.paa_effective_start_date
          AND    lt_dlv_date <= rivd.paa_effective_end_date;
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- SQLにて取得した場合、結果を配列に格納
          gt_select_dlv(lv_tbl_key).resource_id := lt_resource_id; -- リソースID
          gt_select_dlv(lv_tbl_key).base_dlv    := lt_base_dlv;    -- 拠点コード（納品者）
        END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--
        --一般拠点の場合はチェックする。
        IF ( lt_hht_class IS NULL ) 
        OR ( ( lt_hht_class = ct_hht_2 )
          AND (lt_department_class = ct_disp_0 ) ) THEN
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--
          --==============================================================
          --納品者コードの妥当性チェック（ヘッダ部）
          --==============================================================
          IF ( lt_base_dlv != lt_sale_base ) THEN
            -- ログ出力
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_belong );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
        END IF;
--****************************** 2009/04/14 1.10 T.Kitajima MOD  END  ******************************--
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- ログ出力
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_emp_mst );
          gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_emp );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                 cv_tkn_table,   gv_tkn1,
                                                 cv_tkn_colmun,  gv_tkn2 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
      END;
--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
      -- 納品者コード妥当性チェック用配列を検索
      IF (lt_resource_id IS NULL ) THEN
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
        BEGIN
          SELECT rivp.resource_id     resource_id            -- リソースID
          INTO   lt_resource_id
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivp                   -- 営業員情報view（納品者）
          FROM   xxcos_rs_info2_v      rivp                  -- 営業員情報view（納品者）
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
-- ************* 2009/09/01 N.Maeda 1.15 MOD START ************** --
          WHERE  rivp.employee_number = lt_dlv_code
--          WHERE  rivp.employee_number = lt_performance_code  -- 営業員情報view(成績者).顧客番号 = 抽出した成績者
-- ************* 2009/09/01 N.Maeda 1.15 MOD START ************** --
          AND    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)-- 納品日の適用範囲
          AND   lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
          AND   lt_dlv_date >= rivp.per_effective_start_date
          AND   lt_dlv_date <= rivp.per_effective_end_date
          AND   lt_dlv_date >= rivp.paa_effective_start_date
          AND   lt_dlv_date <= rivp.paa_effective_end_date;
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- 取得結果を配列に格納
          gt_select_dlv(lt_dlv_code).resource_id := lt_resource_id; -- リソースID
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ログ出力
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_err_msg_get_resource_id );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
              ln_err_no := ln_err_no + 1;
              -- エラーフラグ更新
              lv_err_flag := cv_hit;
        END;
--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--        IF ( lv_err_flag <> cv_hit ) THEN
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- 顧客名称
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- 顧客ID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- パーティID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- 売上拠点コード
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- 前月売上拠点コード
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- 顧客ステータス
--          gt_select_cus(lt_customer_number).resource_id    := lt_resource_id;     -- リソースID
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- 業態（小分類）
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- 拠点名称
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- 百貨店用HHT区分
--          gt_select_cus(lt_customer_number).base_perf      := lt_base_perf;       -- 拠点コード（成績者）
--          gt_select_cus(lt_customer_number).base_dlv       := lt_base_dlv;        -- 拠点コード（納品者）
--        END IF;
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--
      END IF;
--
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--
      --==============================================================
      --カード売区分の妥当性チェック（ヘッダ部）
      --==============================================================
      FOR i IN 1..gt_qck_card.COUNT LOOP
        EXIT WHEN gt_qck_card(i) = lt_card_sale_class;
        IF ( i = gt_qck_card.COUNT ) THEN
          -- ログ出力
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_card );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
        END IF;
      END LOOP;
--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      --==============================================================
      --カード会社チェック（ヘッダ部）
      --==============================================================
      IF ( lt_card_sale_class = cv_card AND lt_card_company IS NULL ) THEN
        -- ログ出力
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_card_company );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      END IF;
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
      --==============================================================
      --入力区分の妥当性チェック（ヘッダ部）
      --==============================================================
      IF ( lt_data_name IS NULL ) THEN
        -- ログ出力
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      END IF;
--
      --== 入力区分・業態小分類整合性チェック ==--
      FOR i IN 1..gt_qck_inp_auto.COUNT LOOP
        IF ( gt_qck_inp_auto(i) = lt_input_class ) THEN
          FOR j IN 1..gt_qck_busi.COUNT LOOP
            EXIT WHEN gt_qck_busi(j) = lt_bus_low_type;
            IF ( j = gt_qck_busi.COUNT ) THEN
              -- ログ出力
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_class );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
              ln_err_no := ln_err_no + 1;
              -- エラーフラグ更新
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
        END IF;
      END LOOP;
--
      --==============================================================
      --消費税区分の妥当性チェック（ヘッダ部）
      --==============================================================
--
      FOR i IN 1..gt_qck_tax.COUNT LOOP
        IF ( gt_qck_tax(i).tax_cl = lt_tax_class ) THEN
          EXIT;
        END IF;
        IF ( i = gt_qck_tax.COUNT ) THEN
          -- ログ出力
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_tax );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
        END IF;
      END LOOP;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
--      --== 百貨店の場合、預け先コードのセット・百貨店画面種別の妥当性チェックを行います。 ==--
----    IF ( lt_hht_class = cv_depart ) THEN
----****************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
----      IF ( lt_hht_class IS NOT NULL ) THEN
--      IF ( lt_hht_class IS NULL ) 
--        OR ( ( lt_hht_class = ct_hht_2 )
--             AND
--             (lt_department_class = ct_disp_0 )
--           )
--        THEN
----****************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
--  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
----
----****************************** 2009/04/03 1.5 T.Kitajima DEL START ******************************--
----        --==============================================================
----        -- 預け先コードに顧客コードをセット（ヘッダ部）
----        --==============================================================
----        lt_keep_in_code := lt_customer_number;
----****************************** 2009/04/03 1.5 T.Kitajima DEL START ******************************--
--
--       --==============================================================
--        -- 百貨店画面種別の妥当性チェック（ヘッダ部）
--        --==============================================================
--        FOR i IN 1..gt_qck_depart.COUNT LOOP
--          EXIT WHEN gt_qck_depart(i) = lt_department_class;
--          IF ( i = gt_qck_depart.COUNT ) THEN
--            -- ログ出力
--            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_depart );
--            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
--            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--            ov_retcode := cv_status_warn;
--            -- エラー変数へ格納
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
--            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
--            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
--            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--            gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
--            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
--            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
--            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--            gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
--            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
--            ln_err_no := ln_err_no + 1;
--            -- エラーフラグ更新
--            lv_err_flag := cv_hit;
--          END IF;
--        END LOOP;
--
--      END IF;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
      --==============================================================
      --納品日の妥当性チェック（ヘッダ部）
      --==============================================================
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--      --== AR会計期間チェック ==--
      --== INV会計期間チェック ==--
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
      -- 共通関数＜会計期間情報取得＞
      xxcos_common_pkg.get_account_period(
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--        cv_ar_class         -- 02:AR
        cv_inv_class        -- 01:INV
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
       ,lt_dlv_date         -- 納品日
       ,lv_status           -- ステータス(OPEN or CLOSE)
       ,ln_from_date        -- 会計（FROM）
       ,ln_to_date          -- 会計（TO）
       ,lv_errbuf           -- エラー・メッセージ
       ,lv_retcode          -- リターン・コード
       ,lv_errmsg           -- ユーザー・エラー・メッセージ
        );
--****************************** 2009/12/10 1.20 M.Sano MOD START *******************************--
----
--      --エラーチェック
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      END IF;
--
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--      -- AR会計期間範囲外の場合
      -- INV会計期間範囲外の場合
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
--      IF ( lv_status != cv_open ) THEN
      IF ( lv_status != cv_open OR lv_retcode = cv_status_error ) THEN
--****************************** 2009/12/10 1.20 M.Sano MOD  END  *******************************--
        -- ログ出力
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_period );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      END IF;
--
      --== 納品・検収日付整合性チェック ==--
      IF ( lt_dlv_date > lt_inspect_date ) THEN
        -- ログ出力
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_adjust );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      END IF;
--
      --== 未来日チェック ==--
      IF ( lt_dlv_date > gd_process_date ) THEN
        -- ログ出力
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_future );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      END IF;
--
      --==============================================================
      --検収日の妥当性チェック（ヘッダ部）
      --==============================================================
      ld_process_date := LAST_DAY( ADD_MONTHS( gd_process_date, 1 ) );
      IF ( lt_inspect_date > ld_process_date ) THEN
        -- ログ出力
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_scope );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      END IF;
--
      --==============================================================
      --時間の妥当性チェック（ヘッダ部）
      --==============================================================
      BEGIN
        -- エラーフラグ（時間形式判定）初期化
        lv_err_flag_time := cv_default;
--
        -- 文字列が含まれているか
        ln_time_char := TO_NUMBER( lt_dlv_time );
--
        IF ( LENGTHB( lt_dlv_time ) = 4 ) THEN
          IF ( ( substr( lt_dlv_time, 1, 2 ) < 0 ) or ( 24 < substr( lt_dlv_time, 1, 2 ) ) ) THEN
            -- エラーフラグ（時間形式判定）更新
            lv_err_flag_time := cv_hit;
          END IF;
--
          IF ( ( substr( lt_dlv_time, 3 ) < 0 ) or ( 59 < substr( lt_dlv_time, 3 ) ) ) THEN
            -- エラーフラグ（時間形式判定）更新
            lv_err_flag_time := cv_hit;
          END IF;
--
          IF ( lv_err_flag_time = cv_hit ) THEN
            -- ログ出力
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
--
        ELSE
          -- ログ出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- ログ出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- 行NO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- 品目コード
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
      END;
--
      -- ループ開始：明細部
      FOR line_no IN ln_line_cnt..in_line_cnt LOOP
--
        -- データ取得：明細
        lt_order_nol_hht   := gt_lines_work_data(line_no).order_no_hht;          -- 受注No.（HHT）
        lt_line_no_hht     := gt_lines_work_data(line_no).line_no_hht;           -- 行No.（HHT）
        lt_order_nol_ebs   := gt_lines_work_data(line_no).order_no_ebs;          -- 受注No.（EBS）
        lt_line_number     := gt_lines_work_data(line_no).line_num_ebs;          -- 明細番号(EBS)
        lt_item_code       := gt_lines_work_data(line_no).item_code_self;        -- 品名コード（自社）
        lt_case_number     := gt_lines_work_data(line_no).case_number;           -- ケース数
        lt_quantity        := gt_lines_work_data(line_no).quantity;              -- 数量
        lt_sale_class      := gt_lines_work_data(line_no).sale_class;            -- 売上区分
        lt_wholesale_price := gt_lines_work_data(line_no).wholesale_unit;        -- 卸単価
        lt_selling_price   := gt_lines_work_data(line_no).selling_price;         -- 売単価
        lt_column_no       := gt_lines_work_data(line_no).column_no;             -- コラムNo.
        lt_h_and_c         := gt_lines_work_data(line_no).h_and_c;               -- H/C
        lt_sold_out_class  := gt_lines_work_data(line_no).sold_out_class;        -- 売切区分
        lt_sold_out_time   := gt_lines_work_data(line_no).sold_out_time;         -- 売切時間
        lt_cash_and_card   := gt_lines_work_data(line_no).cash_and_card;         -- 現金・カード併用額
--
        -- 明細部ループを抜ける条件
        EXIT WHEN lt_order_noh_hht != lt_order_nol_hht;
--
        --==============================================================
        --品目コードの妥当性チェック（明細部）
        --==============================================================
        BEGIN
          --== 品目マスタデータ抽出 ==--
          -- 既に取得済みの品目コードであるかを確認する。
          IF ( gt_select_item.EXISTS(lt_item_code) ) THEN
            lt_item_id       := gt_select_item(lt_item_code).item_id;          -- 品目ID
            lt_standard_unit := gt_select_item(lt_item_code).primary_measure;  -- 基準単位
            lt_in_case       := gt_select_item(lt_item_code).in_case;          -- ケース入数
            lt_sale_object   := gt_select_item(lt_item_code).sale_object;      -- 売上対象区分
            lt_item_status   := gt_select_item(lt_item_code).item_status;      -- 品目ステータス
          ELSE
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
--          SELECT ic_item.item_id                   inventory_item_id,        -- 品目ID
            SELECT mtl_item.inventory_item_id        inventory_item_id,        -- 品目ID
  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
                   mtl_item.primary_unit_of_measure  primary_measure,          -- 基準単位
                   ic_item.attribute11               attribute11,              -- ケース入数
                   ic_item.attribute26               attribute26,              -- 売上対象区分
                   cmm_item.item_status              item_status               -- 品目ステータス
            INTO   lt_item_id,
                   lt_standard_unit,
                   lt_in_case,
                   lt_sale_object,
                   lt_item_status
            FROM   mtl_system_items_b    mtl_item,
                   ic_item_mst_b         ic_item,
                   xxcmm_system_items_b  cmm_item
            WHERE  mtl_item.segment1        = lt_item_code
              AND  mtl_item.organization_id = gn_orga_id
              AND  mtl_item.segment1        = ic_item.item_no
              AND  mtl_item.segment1        = cmm_item.item_code
              AND  ic_item.item_id          = cmm_item.item_id;
--
            gt_select_item(lt_item_code).item_id         := lt_item_id;         -- 品目ID
            gt_select_item(lt_item_code).primary_measure := lt_standard_unit;   -- 基準単位
            gt_select_item(lt_item_code).in_case         := lt_in_case;         -- ケース入数
            gt_select_item(lt_item_code).sale_object     := lt_sale_object;     -- 売上対象区分
            gt_select_item(lt_item_code).item_status     := lt_item_status;     -- 品目ステータス
--
          END IF;
--
          --== 売上対象区分チェック ==--
          IF ( lt_sale_object = lv_bad_sale ) THEN
            -- ログ出力
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_object );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
--
          --== 品目ステータスチェック ==--
          FOR i IN 1..gt_qck_item.COUNT LOOP
            EXIT WHEN gt_qck_item(i) = lt_item_status;
            IF ( i = gt_qck_item.COUNT ) THEN
              -- ログ出力
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_item );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--              gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--              gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
              gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
              gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
              ln_err_no := ln_err_no + 1;
              -- エラーフラグ更新
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
--
          --== 補充数算出 ==--
          lt_content       := lt_in_case;
          lt_case_number   := NVL( lt_case_number, 0 );
          lt_replenish_num := lt_in_case * lt_case_number + lt_quantity;
          IF ( lt_replenish_num = 0 ) THEN
            -- ログ出力
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_convert );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ログ出力
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_mst );
            gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                   cv_tkn_table,   gv_tkn1,
                                                   cv_tkn_colmun,  gv_tkn2 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
        END;
--
        --==============================================================
        --売上区分の妥当性チェック（明細部）
        --==============================================================
        FOR i IN 1..gt_qck_sale.COUNT LOOP
          EXIT WHEN gt_qck_sale(i) = lt_sale_class;
          IF ( i = gt_qck_sale.COUNT ) THEN
            -- ログ出力
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_sale );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
        END LOOP;
--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
        --==============================================================
        --カード会社チェック（明細部）
        --==============================================================
          IF ( lt_card_sale_class <> cv_card AND (NVL(lt_cash_and_card ,0) <> 0)
                                             AND lt_card_company IS NULL ) THEN
            -- ログ出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_card_company );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
        --==============================================================
        --コラムNo.とH/Cの妥当性チェック（明細部）
        --==============================================================
        FOR j IN 1..gt_qck_busi.COUNT LOOP
          IF ( gt_qck_busi(j) = lt_bus_low_type ) THEN
            --== コラムNo.とH/Cの設定値チェック ==--
            IF ( ( lt_column_no IS NULL ) OR ( lt_h_and_c IS NULL ) ) THEN
              -- ログ出力
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_vd );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--              gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--              gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
              gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
              gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
              ln_err_no := ln_err_no + 1;
              -- エラーフラグ更新
              lv_err_flag := cv_hit;
            END IF;
--
            --== H/Cの項目チェック ==--
            FOR i IN 1..gt_qck_hc.COUNT LOOP
              EXIT WHEN gt_qck_hc(i) = lt_h_and_c;
              IF ( i = gt_qck_hc.COUNT ) THEN
                -- ログ出力
                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_h_c );
                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
                ov_retcode := cv_status_warn;
                -- エラー変数へ格納
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
--                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
--                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
--                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
--                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
--                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
                ln_err_no := ln_err_no + 1;
                -- エラーフラグ更新
                lv_err_flag := cv_hit;
              END IF;
            END LOOP;
--
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--            --== VDコラムマスタとの整合性チェック ==--
--            BEGIN
--              lv_column_check := TO_CHAR( lt_customer_id ) || '_' || lt_column_no;
--              -- 既に取得済みの値であるかを確認する。
--              IF ( gt_select_vd.EXISTS(lv_column_check) ) THEN
--                lt_vd_column := gt_select_vd(lv_column_check).column_no;  -- コラムNo.
--                lt_vd_hc     := gt_select_vd(lv_column_check).hot_cold;   -- H/C
--              ELSE
--                SELECT vd.column_no  column_no,      -- コラムNo.
--                       vd.hot_cold   hot_cold        -- H/C
--                INTO   lt_vd_column,
--                       lt_vd_hc
--                FROM   xxcoi_mst_vd_column vd
--                WHERE  vd.customer_id = lt_customer_id
--                  AND  vd.column_no   = lt_column_no;
----
--                gt_select_vd(lv_column_check).column_no := lt_vd_column;  -- コラムNo.
--                gt_select_vd(lv_column_check).hot_cold  := lt_vd_hc;      -- H/C
----
---- *********** 2009/09/01 N.Maeda 1.15 ADD START ************* --
--              END IF;
---- *********** 2009/09/01 N.Maeda 1.15 ADD  END  ************* --
----
--              -- H/Cの整合性チェック
--              IF ( lt_h_and_c != lt_vd_hc ) THEN
--                -- ログ出力
--                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_hc );
--                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--                ov_retcode := cv_status_warn;
--                -- エラー変数へ格納
---- ******* 2009/10/01 N.Maeda MOD START ********* --
----                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
--                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
--                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
--                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
----                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
----                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
--                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
----                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
--                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
--                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
----                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
----                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
--                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
--                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
--                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
--                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
--                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
---- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
--                ln_err_no := ln_err_no + 1;
--                -- エラーフラグ更新
--                lv_err_flag := cv_hit;
--              END IF;
----
---- *********** 2009/09/01 N.Maeda 1.15 DEL START ************* --
----              END IF;
---- *********** 2009/09/01 N.Maeda 1.15 DEL  END  ************* --
----
--            EXCEPTION
--              WHEN NO_DATA_FOUND THEN
--                -- ログ出力
--                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm );
--                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--                ov_retcode := cv_status_warn;
--                -- エラー変数へ格納
---- ******* 2009/10/01 N.Maeda MOD START ********* --
----                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- 拠点コード
--                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- 拠点名称
--                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- データ名称
--                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- 受注NO(HHT)
----                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- 伝票NO
----                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- 行NO
--                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- 受注NO(EBS)
----                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- 顧客コード
--                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- 顧客名
--                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- 入金/納品日
----                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- 成績者コード
----                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- 品目コード
--                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- 拠点コード
--                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- 伝票NO
--                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- 行NO
--                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- 顧客コード
--                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- 成績者コード
--                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- 品目コード
---- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
--                ln_err_no := ln_err_no + 1;
--                -- エラーフラグ更新
--                lv_err_flag := cv_hit;
--            END;
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
--
          END IF;
        END LOOP;
--
        --==============================================================
        --納品データ（明細）を一時格納用変数へ
        --==============================================================
        lt_line_temp(ln_temp_no).order_nol_hht   := lt_order_nol_hht;        -- 受注No.（HHT）
        lt_line_temp(ln_temp_no).line_no_hht     := lt_line_no_hht;          -- 行No.（HHT）
        lt_line_temp(ln_temp_no).order_nol_ebs   := lt_order_nol_ebs;        -- 受注No.（EBS）
        lt_line_temp(ln_temp_no).line_number     := lt_line_number;          -- 明細番号(EBS)
        lt_line_temp(ln_temp_no).item_code       := lt_item_code;            -- 品名コード（自社）
        lt_line_temp(ln_temp_no).content         := lt_content;              -- 入数
        lt_line_temp(ln_temp_no).item_id         := lt_item_id;              -- 品目ID
        lt_line_temp(ln_temp_no).standard_unit   := lt_standard_unit;        -- 基準単位
        lt_line_temp(ln_temp_no).case_number     := lt_case_number;          -- ケース数
        lt_line_temp(ln_temp_no).quantity        := lt_quantity;             -- 数量
        lt_line_temp(ln_temp_no).sale_class      := lt_sale_class;           -- 売上区分
        lt_line_temp(ln_temp_no).wholesale_price := lt_wholesale_price;      -- 卸単価
        lt_line_temp(ln_temp_no).selling_price   := lt_selling_price;        -- 売単価
        lt_line_temp(ln_temp_no).column_no       := lt_column_no;            -- コラムNo.
        lt_line_temp(ln_temp_no).h_and_c         := lt_h_and_c;              -- H/C
        lt_line_temp(ln_temp_no).sold_out_class  := lt_sold_out_class;       -- 売切区分
        lt_line_temp(ln_temp_no).sold_out_time   := lt_sold_out_time;        -- 売切時間
        lt_line_temp(ln_temp_no).replenish_num   := lt_replenish_num;        -- 補充数
        lt_line_temp(ln_temp_no).cash_and_card   := lt_cash_and_card;        -- 現金・カード併用額
        ln_temp_no := ln_temp_no +1;
--
        -- 明細チェック済番号更新
        ln_line_cnt := ln_line_cnt + 1;
--
      END LOOP;
--
      -- 正常値変数へデータを格納
      IF ( lv_err_flag = cv_default ) THEN
        --==============================================================
        --納品データ（ヘッダ）を変数へ格納
        --==============================================================
        gt_head_order_no_hht(ln_header_ok_no)    := lt_order_noh_hht;        -- 受注No.（HHT）
        gt_head_order_no_ebs(ln_header_ok_no)    := lt_order_noh_ebs;        -- 受注No.（EBS）
        gt_head_base_code(ln_header_ok_no)       := lt_sale_base;            -- 拠点コード
        gt_head_perform_code(ln_header_ok_no)    := lt_performance_code;     -- 成績者コード
        gt_head_dlv_by_code(ln_header_ok_no)     := lt_dlv_code;             -- 納品者コード
        gt_head_hht_invoice_no(ln_header_ok_no)  := lt_hht_invoice_no;       -- HHT伝票No.
        gt_head_dlv_date(ln_header_ok_no)        := lt_dlv_date;             -- 納品日
        gt_head_inspect_date(ln_header_ok_no)    := lt_inspect_date;         -- 検収日
        gt_head_sales_class(ln_header_ok_no)     := lt_sales_class;          -- 売上分類区分
        gt_head_sales_invoice(ln_header_ok_no)   := lt_sales_invoice;        -- 売上伝票区分
        gt_head_card_class(ln_header_ok_no)      := lt_card_sale_class;      -- カード売区分
        gt_head_dlv_time(ln_header_ok_no)        := lt_dlv_time;             -- 時間
        gt_head_change_time_100(ln_header_ok_no) := lt_change_out_100;       -- つり銭切れ時間100円
        gt_head_change_time_10(ln_header_ok_no)  := lt_change_out_10;        -- つり銭切れ時間10円
        gt_head_cus_number(ln_header_ok_no)      := lt_customer_number;      -- 顧客コード
        gt_head_system_class(ln_header_ok_no)    := lt_bus_low_type;         -- 業態区分
        gt_head_input_class(ln_header_ok_no)     := lt_input_class;          -- 入力区分
        gt_head_tax_class(ln_header_ok_no)       := lt_tax_class;            -- 消費税区分
        gt_head_total_amount(ln_header_ok_no)    := lt_total_amount;         -- 合計金額
        gt_head_sale_discount(ln_header_ok_no)   := lt_sale_discount;        -- 売上値引額
        gt_head_sales_tax(ln_header_ok_no)       := lt_sales_tax;            -- 売上消費税額
        gt_head_tax_include(ln_header_ok_no)     := lt_tax_include;          -- 税込金額
        gt_head_keep_in_code(ln_header_ok_no)    := lt_keep_in_code;         -- 預け先コード
        gt_head_depart_screen(ln_header_ok_no)   := lt_department_class;     -- 百貨店画面種別
        gt_resource_id(ln_header_ok_no)          := lt_resource_id;          -- リソースID
        gt_party_id(ln_header_ok_no)             := lt_party_id;             -- パーティID
        gt_party_name(ln_header_ok_no)           := lt_customer_name;        -- 顧客名称
        gt_cus_status(ln_header_ok_no)           := lt_cus_status;           -- 顧客ステータス
        ln_header_ok_no := ln_header_ok_no + 1;
--
        --==============================================================
        --納品データ（明細）を変数へ格納
        --==============================================================
        FOR i IN 1..lt_line_temp.COUNT LOOP
          gt_line_order_no_hht(ln_line_ok_no)   := lt_line_temp(i).order_nol_hht;     -- 受注No.（HHT）
          gt_line_line_no_hht(ln_line_ok_no)    := lt_line_temp(i).line_no_hht;       -- 行No.（HHT）
          gt_line_order_no_ebs(ln_line_ok_no)   := lt_line_temp(i).order_nol_ebs;     -- 受注No.（EBS）
          gt_line_line_num_ebs(ln_line_ok_no)   := lt_line_temp(i).line_number;       -- 明細番号(EBS)
          gt_line_item_code_self(ln_line_ok_no) := lt_line_temp(i).item_code;         -- 品名コード（自社）
          gt_line_content(ln_line_ok_no)        := lt_line_temp(i).content;           -- 入数
          gt_line_item_id(ln_line_ok_no)        := lt_line_temp(i).item_id;           -- 品目ID
          gt_line_standard_unit(ln_line_ok_no)  := lt_line_temp(i).standard_unit;     -- 基準単位
          gt_line_case_number(ln_line_ok_no)    := lt_line_temp(i).case_number;       -- ケース数
          gt_line_quantity(ln_line_ok_no)       := lt_line_temp(i).quantity;          -- 数量
          gt_line_sale_class(ln_line_ok_no)     := lt_line_temp(i).sale_class;        -- 売上区分
          gt_line_wholesale_unit(ln_line_ok_no) := lt_line_temp(i).wholesale_price;   -- 卸単価
          gt_line_selling_price(ln_line_ok_no)  := lt_line_temp(i).selling_price;     -- 売単価
          gt_line_column_no(ln_line_ok_no)      := lt_line_temp(i).column_no;         -- コラムNo.
          gt_line_h_and_c(ln_line_ok_no)        := lt_line_temp(i).h_and_c;           -- H/C
          gt_line_sold_out_class(ln_line_ok_no) := lt_line_temp(i).sold_out_class;    -- 売切区分
          gt_line_sold_out_time(ln_line_ok_no)  := lt_line_temp(i).sold_out_time;     -- 売切時間
          gt_line_replenish_num(ln_line_ok_no)  := lt_line_temp(i).replenish_num;     -- 補充数
          gt_line_cash_and_card(ln_line_ok_no)  := lt_line_temp(i).cash_and_card;     -- 現金・カード併用額
          ln_line_ok_no := ln_line_ok_no + 1;
        END LOOP;
      END IF;
--
      -- 納品明細データ一時格納用変数を初期化
      lt_line_temp.DELETE;
      ln_temp_no := 1;
--
    END LOOP;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END data_check;
--
  /***********************************************************************************
   * Procedure Name   : error_data_register
   * Description      : エラーデータ登録(A-3)
   ***********************************************************************************/
  PROCEDURE error_data_register(
    on_warn_cnt       OUT NUMBER,           --   警告件数
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_data_register'; -- プログラム名
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
    -- 警告件数初期化
    on_warn_cnt := 0;
--
    --==============================================================
    -- HHTエラーリスト帳票ワークテーブルへエラーデータ登録
    --==============================================================
    -- 警告件数セット
    on_warn_cnt := gt_err_base_code.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_warn_cnt
        INSERT INTO xxcos_rep_hht_err_list
          (
            record_id,
            base_code,
            base_name,
            origin_shipment,
            data_name,
            order_no_hht,
            invoice_invent_date,
            entry_number,
            line_no,
            order_no_ebs,
            party_num,
            customer_name,
            payment_dlv_date,
            payment_class_name,
            performance_by_code,
            item_code,
            error_message,
            report_group_id,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            xxcos_rep_hht_err_list_s01.NEXTVAL,          -- レコードID
            gt_err_base_code(i),                         -- 拠点コード
            gt_err_base_name(i),                         -- 拠点名称
            NULL,                                        -- 出庫側コード
            gt_err_data_name(i),                         -- データ名称
            gt_err_order_no_hht(i),                      -- 受注NO（HHT）
            NULL,                                        -- 伝票/棚卸日
            gt_err_entry_number(i),                      -- 伝票NO
            gt_err_line_no(i),                           -- 行NO
--****************************** 2009/05/15 1.13 N.Maeda MOD START  *****************************--
            DECODE ( gt_err_order_no_ebs(i) ,            -- 受注NO（EBS）
                     ct_order_no_ebs_0 , NULL ,
                     gt_err_order_no_ebs(i) ) ,
--            gt_err_order_no_ebs(i),                      -- 受注NO（EBS）
--****************************** 2009/05/15 1.13 N.Maeda MOD  END   *****************************--
            gt_err_party_num(i),                         -- 顧客コード
            gt_err_customer_name(i),                     -- 顧客名
            gt_err_payment_dlv_date(i),                  -- 入金/納品日
            NULL,                                        -- 入金区分名称
            gt_err_perform_by_code(i),                   -- 成績者コード
            gt_err_item_code(i),                         -- 品目コード
            gt_err_error_message(i),                     -- エラー内容
            NULL,                                        -- 帳票用グループID
            cn_created_by,                               -- 作成者
            cd_creation_date,                            -- 作成日
            cn_last_updated_by,                          -- 最終更新者
            cd_last_update_date,                         -- 最終更新日
            cn_last_update_login,                        -- 最終更新ログイン
            cn_request_id,                               -- 要求ID
            cn_program_application_id,                   -- コンカレント・プログラム・アプリケーションID
            cn_program_id,                               -- コンカレント・プログラムID
            cd_program_update_date                       -- プログラム更新日
          );
--
    EXCEPTION
--
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END error_data_register;
--
  /***********************************************************************************
   * Procedure Name   : header_data_register
   * Description      : 納品ヘッダテーブルへデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE header_data_register(
    on_normal_cnt     OUT NUMBER,           --   納品ヘッダデータ作成件数
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'header_data_register'; -- プログラム名
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
    cv_entry_class  VARCHAR2(1) DEFAULT '3';  -- 訪問有効情報登録：DFF12（登録区分）
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
    -- 納品ヘッダデータ作成件数初期化
    on_normal_cnt := 0;
--
    --==============================================================
    -- 納品ヘッダテーブルへデータ登録
    --==============================================================
    -- 共通関数＜訪問有効情報登録＞
    FOR i IN 1..gt_party_id.COUNT LOOP
--
      xxcos_task_pkg.task_entry(
        lv_errbuf                 -- エラー・メッセージ
       ,lv_retcode                -- リターン・コード
       ,lv_errmsg                 -- ユーザー・エラー・メッセージ
       ,gt_resource_id(i)         -- リソースID
       ,gt_party_id(i)            -- パーティID
       ,gt_party_name(i)          -- パーティ名称（顧客名称）
--****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
       ,TO_DATE(TO_CHAR( gt_head_dlv_date(i) , cv_shot_date_type)
                ||cv_spe_cha||SUBSTR(gt_head_dlv_time(i),1,2)
                ||cv_time_cha||SUBSTR(gt_head_dlv_time(i),3,2) , cv_date_type)
--       ,gt_head_dlv_date(i)       -- 訪問日時 ＝ 納品日
--****************************** 2009/05/15 1.14 N.Maeda MOD  END   *****************************--
       ,NULL                      -- 詳細内容
       ,gt_head_total_amount(i)   -- 合計金額
       ,gt_head_input_class(i)    -- 入力区分
       ,cv_entry_class            -- DFF12（登録区分）＝ 3
       ,gt_head_order_no_hht(i)   -- DFF13（登録元ソース番号）＝ 受注No.（HHT）
       ,gt_cus_status(i)          -- DFF14（顧客ステータス）
      );
--
      --エラーチェック
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP;
--
--
    --== データ登録 ==--
    -- 納品ヘッダデータ作成件数セット
    on_normal_cnt := gt_head_order_no_hht.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_normal_cnt
        INSERT INTO xxcos_dlv_headers
          (
            order_no_hht,
            digestion_ln_number,
            order_no_ebs,
            base_code,
            performance_by_code,
            dlv_by_code,
            hht_invoice_no,
            dlv_date,
            inspect_date,
            sales_classification,
            sales_invoice,
            card_sale_class,
            dlv_time,
            change_out_time_100,
            change_out_time_10,
            customer_number,
            system_class,
            input_class,
            consumption_tax_class,
            total_amount,
            sale_discount_amount,
            sales_consumption_tax,
            tax_include,
            keep_in_code,
            department_screen_class,
            red_black_flag,
            stock_forward_flag,
            stock_forward_date,
            results_forward_flag,
            results_forward_date,
            cancel_correct_class,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            gt_head_order_no_hht(i),                     -- 受注No.（HHT)
            cv_default,                                  -- 枝番
            gt_head_order_no_ebs(i),                     -- 受注No.（EBS）
            gt_head_base_code(i),                        -- 拠点コード
            gt_head_perform_code(i),                     -- 成績者コード
            gt_head_dlv_by_code(i),                      -- 納品者コード
            gt_head_hht_invoice_no(i),                   -- HHT伝票No.
            gt_head_dlv_date(i),                         -- 納品日
            gt_head_inspect_date(i),                     -- 検収日
            gt_head_sales_class(i),                      -- 売上分類区分
            gt_head_sales_invoice(i),                    -- 売上伝票区分
            gt_head_card_class(i),                       -- カード売区分
            gt_head_dlv_time(i),                         -- 時間
            gt_head_change_time_100(i),                  -- つり銭切れ時間100円
            gt_head_change_time_10(i),                   -- つり銭切れ時間10円
            gt_head_cus_number(i),                       -- 顧客コード
            gt_head_system_class(i),                     -- 業態区分
            gt_head_input_class(i),                      -- 入力区分
            gt_head_tax_class(i),                        -- 消費税区分
            gt_head_total_amount(i),                     -- 合計金額
            gt_head_sale_discount(i),                    -- 売上値引額
            gt_head_sales_tax(i),                        -- 売上消費税額
            gt_head_tax_include(i),                      -- 税込金額
            gt_head_keep_in_code(i),                     -- 預け先コード
            gt_head_depart_screen(i),                    -- 百貨店画面種別
            cv_hit,                                      -- 赤黒フラグ
            cv_default,                                  -- 入出庫転送済フラグ
            NULL,                                        -- 入出庫転送済日付
            cv_default,                                  -- 販売実績連携済みフラグ
            NULL,                                        -- 販売実績連携済み日付
            NULL,                                        -- 取消・訂正区分
            cn_created_by,                               -- 作成者
            cd_creation_date,                            -- 作成日
            cn_last_updated_by,                          -- 最終更新者
            cd_last_update_date,                         -- 最終更新日
            cn_last_update_login,                        -- 最終更新ログイン
            cn_request_id,                               -- 要求ID
            cn_program_application_id,                   -- コンカレント・プログラム・アプリケーションID
            cn_program_id,                               -- コンカレント・プログラムID
            cd_program_update_date                       -- プログラム更新日
          );
--
    EXCEPTION
--
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END header_data_register;
--
  /***********************************************************************************
   * Procedure Name   : lines_data_register
   * Description      : 納品明細テーブルへデータ登録(A-5)
   ***********************************************************************************/
  PROCEDURE lines_data_register(
    on_normal_cnt     OUT NUMBER,           --   納品明細データ作成件数
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lines_data_register'; -- プログラム名
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
    -- 納品明細データ作成件数初期化
    on_normal_cnt := 0;
--
    --==============================================================
    -- 納品明細テーブルへデータ登録
    --==============================================================
    -- 納品明細データ作成件数セット
    on_normal_cnt := gt_line_order_no_hht.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_normal_cnt
        INSERT INTO xxcos_dlv_lines
          (
            order_no_hht,
            line_no_hht,
            digestion_ln_number,
            order_no_ebs,
            line_number_ebs,
            item_code_self,
            content,
            inventory_item_id,
            standard_unit,
            case_number,
            quantity,
            sale_class,
            wholesale_unit_ploce,
            selling_price,
            column_no,
            h_and_c,
            sold_out_class,
            sold_out_time,
            replenish_number,
            cash_and_card,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            gt_line_order_no_hht(i),                     -- 受注No.（HHT）
            gt_line_line_no_hht(i),                      -- 行No.（HHT）
            cv_default,                                  -- 枝番
            gt_line_order_no_ebs(i),                     -- 受注No.（EBS）
            gt_line_line_num_ebs(i),                     -- 明細番号（EBS）
            gt_line_item_code_self(i),                   -- 品名コード（自社）
            gt_line_content(i),                          -- 入数
            gt_line_item_id(i),                          -- 品目ID
            gt_line_standard_unit(i),                    -- 基準単位
            gt_line_case_number(i),                      -- ケース数
            gt_line_quantity(i),                         -- 数量
            gt_line_sale_class(i),                       -- 売上区分
            gt_line_wholesale_unit(i),                   -- 卸単価
            gt_line_selling_price(i),                    -- 売単価
            gt_line_column_no(i),                        -- コラムNo.
            gt_line_h_and_c(i),                          -- H/C
            gt_line_sold_out_class(i),                   -- 売切区分
            gt_line_sold_out_time(i),                    -- 売切時間
            gt_line_replenish_num(i),                    -- 補充数
            gt_line_cash_and_card(i),                    -- 現金・カード併用額
            cn_created_by,                               -- 作成者
            cd_creation_date,                            -- 作成日
            cn_last_updated_by,                          -- 最終更新者
            cd_last_update_date,                         -- 最終更新日
            cn_last_update_login,                        -- 最終更新ログイン
            cn_request_id,                               -- 要求ID
            cn_program_application_id,                   -- コンカレント・プログラム・アプリケーションID
            cn_program_id,                               -- コンカレント・プログラムID
            cd_program_update_date                       -- プログラム更新日
          );
--
    EXCEPTION
--
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END lines_data_register;
--
  /***********************************************************************************
   * Procedure Name   : work_data_delete
   * Description      : ワークテーブルレコード削除(A-6)
   ***********************************************************************************/
  PROCEDURE work_data_delete(
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'work_data_delete'; -- プログラム名
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
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
--
    -- 納品ヘッダワーク全データロック
    CURSOR loc_headers_cur
    IS
      SELECT 'Y'
      FROM   xxcos_dlv_headers_work
    FOR UPDATE NOWAIT;
    -- 納品明細ワーク全データロック
    CURSOR loc_lines_cur
    IS
      SELECT 'Y'
      FROM   xxcos_dlv_lines_work
    FOR UPDATE NOWAIT;
--
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
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
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    --  起動処理区分3の場合排他制御処理を実施
    IF ( gv_mode = cv_truncate ) THEN
--
      -- ヘッダワークに排他制御を実施
      BEGIN
--
        OPEN  loc_headers_cur;
        CLOSE loc_headers_cur;
--
      EXCEPTION
        WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
        -- カーソルCLOSE
        IF ( loc_headers_cur%ISOPEN ) THEN
          CLOSE loc_headers_cur;
        END IF;
--
        RAISE global_api_expt;
      END;
--
      -- 明細ワークに排他制御を実施
      BEGIN
--
        OPEN  loc_lines_cur;
        CLOSE loc_lines_cur;
--
      EXCEPTION
        WHEN lock_expt THEN
          gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
          lv_errbuf  := lv_errmsg;
--
          -- カーソルCLOSE
          IF ( loc_lines_cur%ISOPEN ) THEN
            CLOSE loc_lines_cur;
          END IF;
--
          RAISE global_api_expt;
      END;
--
    END IF;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
    --==============================================================
    -- 納品ヘッダワークテーブルのレコード削除
    --==============================================================
    BEGIN
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
--      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_dlv_headers_work';
      DELETE FROM xxcos_dlv_headers_work;
      gn_wh_del_count := SQL%ROWCOUNT;
--****************************** 2010/01/27 1.23 N.Maeda  MOD  END  *******************************--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- 納品明細ワークテーブルのレコード削除
    --==============================================================
    BEGIN
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
--      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_dlv_lines_work';
      DELETE FROM xxcos_dlv_lines_work;
      gn_wl_del_count := SQL%ROWCOUNT;
--****************************** 2010/01/27 1.23 N.Maeda  MOD  END  *******************************--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END work_data_delete;
--
  /***********************************************************************************
   * Procedure Name   : table_lock
   * Description      : テーブルロック(A-7)
   ***********************************************************************************/
  PROCEDURE table_lock(
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'table_lock'; -- プログラム名
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
    lv_purge_date    VARCHAR2(5);  -- パージ処理算出基準日
    ld_process_date  DATE;         -- 業務処理日
--
    -- *** ローカル・カーソル ***
    CURSOR headers_lock_cur
    IS
      SELECT head.creation_date  creation_date
      FROM   xxcos_dlv_headers   head
      WHERE  TRUNC( head.creation_date ) < ( gd_process_date - gn_purge_date )
      FOR UPDATE NOWAIT;
--
    CURSOR lines_lock_cur
    IS
      SELECT line.creation_date  creation_date
      FROM   xxcos_dlv_lines     line
      WHERE  TRUNC( line.creation_date ) < ( gd_process_date - gn_purge_date )
      FOR UPDATE NOWAIT;
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
    --==============================================================
    -- プロファイルの取得(XXCOS:納品データ取込パージ処理日算出基準日数)
    --==============================================================
    lv_purge_date := FND_PROFILE.VALUE( cv_prf_purge_date );
--
    -- プロファイル取得エラーの場合
    IF ( lv_purge_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_purge_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gn_purge_date := TO_NUMBER( lv_purge_date );
    END IF;
--
    --==============================================================
    -- 共通関数＜業務処理日取得＞の呼び出し
    --==============================================================
     ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日取得エラーの場合
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==============================================================
    -- テーブルロック
    --==============================================================
    OPEN  headers_lock_cur;
    CLOSE headers_lock_cur;
--
    OPEN  lines_lock_cur;
    CLOSE lines_lock_cur;
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock_table );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( headers_lock_cur%ISOPEN ) THEN
        CLOSE headers_lock_cur;
      END IF;
--
      IF ( lines_lock_cur%ISOPEN ) THEN
        CLOSE lines_lock_cur;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END table_lock;
--
  /***********************************************************************************
   * Procedure Name   : dlv_data_delete
   * Description      : 納品ヘッダ・明細テーブルレコード削除(A-8)
   ***********************************************************************************/
  PROCEDURE dlv_data_delete(
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlv_data_delete'; -- プログラム名
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
    --==============================================================
    -- 納品ヘッダテーブルの不要データ削除
    --==============================================================
    BEGIN
--
      DELETE FROM xxcos_dlv_headers
      WHERE TRUNC( xxcos_dlv_headers.creation_date ) < ( gd_process_date - gn_purge_date );
--
      gn_del_cnt_h := SQL%ROWCOUNT;    -- ヘッダ削除件数
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- 納品明細テーブルの不要データ削除
    --==============================================================
    BEGIN
--
      DELETE FROM xxcos_dlv_lines
      WHERE TRUNC( xxcos_dlv_lines.creation_date ) < ( gd_process_date - gn_purge_date );
--
      gn_del_cnt_l := SQL%ROWCOUNT;      -- 明細削除件数
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- 削除件数出力
    --==============================================================
    -- ヘッダ件数
    gv_out_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del_h, cv_tkn_count, TO_CHAR( gn_del_cnt_h ) );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 明細件数
    gv_out_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del_l, cv_tkn_count, TO_CHAR( gn_del_cnt_l ) );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END dlv_data_delete;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_mode       IN  VARCHAR2,     --   起動モード（1:昼間 or 2:夜間）
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_line_cnt   NUMBER;     -- 抽出件数（納品明細ワークテーブル）
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_tar_cnt_h  := 0;
    gn_tar_cnt_l  := 0;
    gn_nor_cnt_h  := 0;
    gn_nor_cnt_l  := 0;
    gn_del_cnt_h  := 0;
    gn_del_cnt_l  := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    gn_wh_del_count := 0;
    gn_wl_del_count := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-0)
    -- ===============================
    gv_mode := iv_mode;
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_errbuf   :=  lv_errbuf;
      ov_retcode  :=  lv_retcode;
      ov_errmsg   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    IF ( gv_mode = cv_daytime ) THEN    -- 昼間起動時の処理
--
      -- ============================================
      -- 納品データ抽出(A-1)
      -- ============================================
      dlv_data_receive(
        gn_tar_cnt_h,           -- 対象件数（納品ヘッダワークテーブル）
        gn_tar_cnt_l,           -- 対象件数（納品明細ワークテーブル）
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラー処理
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
--
      -- 警告処理（対象データ無しエラー）
      ELSIF ( gn_tar_cnt_h = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
--
      END IF;
--
      --== 対象データが1件以上ある場合、A-2からA-6の処理を行います。 ==--
      IF ( gn_tar_cnt_h >= 1 ) THEN
        -- ============================================
        -- データ妥当性チェック(A-2)
        -- ============================================
        data_check(
          gn_tar_cnt_l,           -- 処理件数（明細部）
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_errbuf   :=  lv_errbuf;
          ov_retcode  :=  lv_retcode;
          ov_errmsg   :=  lv_errmsg;
        END IF;
--
        -- エラー処理
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ============================================
        -- エラーデータ登録(A-3)
        -- ============================================
        -- 妥当性チェックでエラーとなったデータに対して以下の処理を行います。
        IF ( gt_err_base_code IS NOT NULL ) THEN
          error_data_register(
            gn_error_cnt,           -- 警告件数
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
          --エラー処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- 納品ヘッダテーブルへデータ登録(A-4)
        -- ============================================
        -- 妥当性チェックでエラーとならなかったデータに対して以下の処理を行う。
        IF ( gt_head_order_no_hht IS NOT NULL ) THEN
          header_data_register(
            gn_nor_cnt_h,           -- 納品ヘッダデータ作成件数
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
          --エラー処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- 納品明細テーブルへデータ登録(A-5)
        -- ============================================
        -- 妥当性のチェックでエラーとならなかったデータに対して以下の処理を行う。
        IF ( gt_line_order_no_hht IS NOT NULL ) THEN
          lines_data_register(
            gn_nor_cnt_l,           -- 納品明細データ作成件数
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
          --エラー処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- ワークテーブルレコード削除(A-6)
        -- ============================================
        work_data_delete(
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
        --エラー処理
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
--
    ELSIF ( gv_mode = cv_night ) THEN    -- 夜間起動時の処理
--
      -- ============================================
      -- テーブルロック(A-7)
      -- ============================================
      table_lock(
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラー処理
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      -- ============================================
      -- 納品ヘッダ・明細テーブルレコード削除(A-8)
      -- ============================================
      dlv_data_delete(
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラー処理
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
    ELSIF ( gv_mode = cv_truncate ) THEN    -- 起動時の処理
      -- ============================================
      -- ワークテーブルレコード削除(A-6)
      -- ============================================
      work_data_delete(
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
      --エラー処理
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
--****************************** 2010/01/27 1.23 N.Maeda  MOD END   *******************************--
--
    END IF;
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_mode       IN  VARCHAR2       --   起動モード（1:昼間 or 2:夜間）
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
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
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_mode     -- 起動モード
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- 成功件数初期化
      gn_nor_cnt_h := 0;
      gn_nor_cnt_l := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
      gn_wh_del_count := 0;
      gn_wl_del_count := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
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
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- 昼間起動時の件数出力
    IF ( iv_mode = cv_daytime ) THEN
--
      --ヘッダ対象件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tar_cnt_h
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_tar_cnt_h )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --明細対象件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tar_cnt_l
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_tar_cnt_l )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --ヘッダ成功件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_nor_cnt_h
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_nor_cnt_h )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --明細成功件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_nor_cnt_l
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_nor_cnt_l )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
      --ヘッダワーク削除件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wh_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wh_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --明細ワーク削除件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wl_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wl_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
      --エラー件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    --
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    ELSIF ( iv_mode = cv_truncate ) THEN
      --
      IF ( lv_retcode = cv_status_normal ) THEN
--
        --削除対象が存在しない場合
        IF ( gn_wh_del_count = 0 ) AND ( gn_wl_del_count = 0 ) THEN
          --ワークテーブル削除対象データなしメッセージ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_no_del_target
                         )
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          
        ELSE
--
          --全削除メッセージ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_mode3_comp
                         )
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        END IF;
      END IF;
      --
      --ヘッダワーク削除件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wh_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wh_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --明細ワーク削除件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wl_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wl_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
    END IF;
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS001A01C;
/
