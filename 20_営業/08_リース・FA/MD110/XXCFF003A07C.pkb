create or replace
PACKAGE BODY XXCFF003A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A07C(body)
 * Description      : リース契約・物件アップロード
 * MD.050           : MD050_CFF_003_A07_リース契約・物件アップロード.doc
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                       (A-1)
 *  get_if_data            ファイルアップロードI/F取得    (A-2)
 *  devide_item            デリミタ文字項目分割           (A-3)
 *  chk_err_disposion      配列項目チェック処理           (A-4)
 *  ins_cont_work          アップロード振分処理           (A-5)
 *                         エラー判定処理                 (A-6)
 *  chk_rept_adjust        ﾜｰｸﾌｧｲﾙ重複・整合性ﾁｪｯｸ処理    (A-7)
 *  chk_cont_header        契約ワークチェック処理         (A-8)
 *  chk_cont_line          契約明細ワークチェック処理     (A-9)
 *  chk_obj_header         物件ワークチェック処理         (A-10)
 *                         エラー判定処理                 (A-11)
 *  get_contract_info      リース契約ワーク抽出           (A-12)
 *  set_upload_item        アップロード項目編集           (A-13)
 *  jdg_lease_kind         リース種類判定                 (A-14)
 *  insert_ob_hed          リース物件新規登録             (A-15)
 *  insert_co_hed          リース契約新規登録             (A-16)
 *  insert_co_lin          リース契約明細新規登録         (A-17)
 *  ins_object_histories   リース物件履歴登録             (A-18)
 *  xxcff003a05c           リース支払計画作成             (A-19)
 *  submain                終了処理                       (A-20)
 *  submain_main           メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/1/22     1.0   SCS礒崎祐次     新規作成
 *  2009/2/24     1.1   SCS礒崎祐次     [障害CFF_056] コンカレントパラメータと
 *                                      ＣＳＶファイル名の表示変更*
 *  2009/03/02    1.2   SCS礒崎祐次     [障害CFF_068] 業務エラーメッセージは
 *                                      出力ファイルに出力する。
 *  2009/05/14    1.3   SCS礒崎祐次     [障害T1_0783]数量がNULLの場合は、1を設定する。
 *  2009/05/18    1.4   SCS松中俊樹     [障害T1_0721]デリミタ文字分割後データ格納配列の
 *                                      桁数を変更
 *                                      初回設置場所と初回設置先の格納変数を修正
 *  2009/05/27    1.5   SCS礒崎祐次     [障害T1_1225] 税金コードマスタに
 *                                      よるマスタチェックの際、有効日の条件を追加する。
 *  2009/11/27    1.6X  SCS渡辺学       【暫定対応版】
 *                                      移行漏れ登録のため、チェックをはずす。
 *                                      ・契約番号の半角チェック
 *                                      ・終了日と最終支払日の大小チェック
 *  2010/01/07    1.7   SCS渡辺学       Ver.1.6X【暫定対応版】の対応は恒久対応とする。
 *                                      [E_本番_00229]
 *                                        入力項目「月額リース控除額（税抜）」を「維持管理費用相当額（総額）」変更。
 *                                        「維持管理費用相当額（総額）」から月額金額を換算し（円未満切捨て）、
 *                                        端数差額を初回の月額控除額で調整する。
 *  2013/07/05    1.8   SCSK中野徹也    【E_本稼動_10871】(消費税増税対応)
 *  2016/08/15    1.9   SCSK仁木 重人   【E_本稼動_13658】自販機耐用年数変更対応
 *  2018/03/27    1.10  SCSK大塚 亨     【E_本稼動_14830】IFRSリース資産対応
 *  2018/05/25    1.11  SCSK森 晴加     【E_本稼動_15112】IFRS障害対応
 *  2018/09/10    1.12  SCSK佐々木宏之  【E_本稼動_14830】追加対応
 *  2018/10/24    1.13  SCSK佐々木 大和 【E_本稼動_14830】追加対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
  --
  --ステータス・コード
  cv_status_normal  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn    CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;          --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                     --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;          --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                     --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;         --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;  --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;     --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;  --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                     --PROGRAM_UPDATE_DATE
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg        VARCHAR2(2000);
  gv_sep_msg        VARCHAR2(2000);
  gv_exec_user      VARCHAR2(100);
  gv_conc_name      VARCHAR2(30);
  gv_conc_status    VARCHAR2(30);
  gn_target_cnt     NUMBER;                          -- 対象件数
  gn_normal_cnt     NUMBER;                          -- 正常件数
  gn_error_cnt      NUMBER;                          -- エラー件数
  gn_warn_cnt       NUMBER;                          -- スキップ件数
--
--################################  固定部 END   ##################################
  cv_msg_part       CONSTANT VARCHAR2(1)    := ':';  -- コロン
  cv_msg_cont       CONSTANT VARCHAR2(1)    := '.';  -- ピリオド
  --
  cv_const_n        CONSTANT VARCHAR2(1)    := 'N';  -- 'N'
  cv_const_y        CONSTANT VARCHAR2(1)    := 'Y';  -- 'Y'
  --
  cv_null_byte      CONSTANT VARCHAR2(1)    := '';   -- ''
  --
  cv_csv_name       CONSTANT VARCHAR2(3)    := 'CSV'; -- CSV
  cv_csv_delim      CONSTANT VARCHAR2(1)    := ',';   -- CSV区切り文字
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
  
  lock_expt              EXCEPTION;     -- ロック取得エラー
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  --
--################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF003A07C'; -- パッケージ名
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
--
  cv_look_type       CONSTANT VARCHAR2(100) := 'XXCFF1_CONT_OBJ_UPLOAD'; -- LOOKUP TYPE
--
  cv_file_type_out   CONSTANT VARCHAR2(10)  := 'OUTPUT';      --出力(ユーザメッセージ用出力先)
  cv_file_type_log   CONSTANT VARCHAR2(10)  := 'LOG';         --ログ(システム管理者用出力先)
--
  -- メッセージ番号
-- Ver.1.9 DEL Start
--  -- 入力必須エラー
--  cv_msg_cff_00005   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00005';
-- Ver.1.9 DEL End
  -- 契約番号存在エラー
  cv_msg_cff_00044   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00044';
  -- 契約番号重複エラー
  cv_msg_cff_00119   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00119';
  -- 契約不整合エラー
  cv_msg_cff_00127   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00127';
  -- 契約日妥当性エラー
  cv_msg_cff_00083   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00083';
  -- 境界値エラー
  cv_msg_cff_00013   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00013';
  -- リース開始日妥当性エラー
  cv_msg_cff_00043   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00043';
  -- 支払回数境界値エラー
  cv_msg_cff_00016   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00016';
  -- 支払回数入力値エラー
  cv_msg_cff_00014   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00014';
-- Ver.1.9 DEL Start
--  -- 頻度エラー
--  cv_msg_cff_00023   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00023';
-- Ver.1.9 DEL End
  -- 初回支払日妥当性エラー（リース開始日前）
  cv_msg_cff_00022   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00022';
  -- 2回目支払日妥当性エラー（初回支払日前）
  cv_msg_cff_00056   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00056';
  -- 2回目支払日妥当性エラー（初回支払日翌々月以降）
  cv_msg_cff_00055   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00055';
-- Ver.1.9 DEL Start
--  -- 支払日妥当性エラー（最終支払日）
--  cv_msg_cff_00031   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00031';
-- Ver.1.9 DEL End
  -- 契約枝番重複エラー
  cv_msg_cff_00067   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00067';
  -- 契約枝番不整合エラー
  cv_msg_cff_00068   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00068';
-- Ver.1.9 DEL Start
--  -- 物件コード未登録エラー
--  cv_msg_cff_00075   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00075';
-- Ver.1.9 DEL End
  -- 物件コード存在エラー
  cv_msg_cff_00160   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00160';
  -- ワークテーブル物件コード重複エラー
  cv_msg_cff_00145   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00145';
  -- 資産種類マスタエラー
  cv_msg_cff_00069   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00069';
-- Ver.1.9 DEL Start
--  -- ロックエラー
--  cv_msg_cff_00007   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00007';
-- Ver.1.9 DEL End
  -- エラー対象
  cv_msg_cff_00009   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00009';
  -- リース契約エラー対象
  cv_msg_cff_00146   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00146';
  -- リース契約明細エラー対象
  cv_msg_cff_00147   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00147';
  -- リース種別エラー
  cv_msg_cff_00122   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00122';
  -- 耐用年数エラー
  cv_msg_cff_00149   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00149';
-- 2018/05/25 Ver1.11 Mori DEL Start
--  -- 控除額エラー
--  cv_msg_cff_00034   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00034';
-- 2018/05/25 Ver1.11 Mori DEL End
-- Ver.1.9 DEL Start
--  -- 再リース回数不一致エラー
--  cv_msg_cff_00148   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00148';
-- Ver.1.9 DEL End
  -- 契約明細件数エラー
  cv_msg_cff_00150   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00150';
  -- 数値論理エラー(0未満)
  cv_msg_cff_00117   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00117';
-- Ver.1.9 DEL Start
--  -- 日付論理エラー
--  cv_msg_cff_00118   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00118';
-- Ver.1.9 DEL End
  -- 禁則文字エラー
  cv_msg_cff_00138   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00138';
  -- データ変換エラー
  cv_msg_cff_00110   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00110';
-- Ver.1.9 DEL Start
--  -- 2回目支払日妥当性エラー（初回支払日翌々年以降）
--  cv_msg_cff_00177   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00177';
-- Ver.1.9 DEL End
  -- アップロード初期出力メッセージ  
  cv_msg_cff_00167   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00167'; 
  -- 半角英数字エラー
  cv_msg_cff_00179   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00179';
  -- 共通関数エラー
  cv_msg_cff_00094   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';
  -- 共通関数メッセージ
  cv_msg_cff_00095   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';
   -- 項目値妥当性チェックエラー
  cv_msg_cff_00124   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00124';
-- Ver.1.9 DEL Start
--  -- 対象件数メッセージ
--  cv_msg_cff_90000   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90000';
--  -- 成功件数メッセージ
--  cv_msg_cff_90001   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90001';
--  -- エラー件数メッセージ
--  cv_msg_cff_90002   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90002';
--  -- 正常終了メッセージ
--  cv_msg_cff_90004   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90004';
--  -- エラー終了全ロールバックメッセージ
--  cv_msg_cff_90006   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90006';
--  -- コンカレント入力パラメータメッセージ
--  cv_msg_cff_90009   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90009';
-- Ver.1.9 DEL End
-- 2018/03/27 Ver1.10 Otsuka ADD Start
  cv_msg_cff_00282   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00282';   -- 見積現金購入価額エラー
  cv_msg_cff_00283   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00283';   -- 法定耐用年数エラー
-- 2018/03/27 Ver1.10 Otsuka ADD End
--
  -- メッセージトークン
  cv_tk_cff_00005_01 CONSTANT VARCHAR2(15)  := 'INPUT';       -- カラム論理名
-- Ver.1.9 DEL Start
--  cv_tk_cff_00007_01 CONSTANT VARCHAR2(15)  := 'TABLE_NAME';  -- テーブル名
-- Ver.1.9 DEL End
  cv_tk_cff_00009_01 CONSTANT VARCHAR2(15)  := 'CONTRACT_NO'; -- 契約番号
  cv_tk_cff_00009_02 CONSTANT VARCHAR2(15)  := 'L_COMPANY';   -- リース会社
  cv_tk_cff_00009_03 CONSTANT VARCHAR2(15)  := 'SPEC_NO';     -- 契約枝番
  cv_tk_cff_00009_04 CONSTANT VARCHAR2(15)  := 'OBJECT_NO';   -- 物件コード
  cv_tk_cff_00013_01 CONSTANT VARCHAR2(15)  := 'INPUT';       -- カラム論理名
  cv_tk_cff_00013_02 CONSTANT VARCHAR2(15)  := 'MINVALUE';    -- 境界値エラーの範囲(MIN)
  cv_tk_cff_00016_01 CONSTANT VARCHAR2(15)  := 'MINVALUE';    -- 境界値エラーの範囲(MIN)
  cv_tk_cff_00016_02 CONSTANT VARCHAR2(15)  := 'MAXVALUE';    -- 境界値エラーの範囲(MAX)
  cv_tk_cff_00094_01 CONSTANT VARCHAR2(15)  := 'FUNC_NAME';   -- 共通関数
  cv_tk_cff_00095_01 CONSTANT VARCHAR2(15)  := 'ERR_MSG';     -- エラーメッセージ
  cv_tk_cff_00101_01 CONSTANT VARCHAR2(15)  := 'APPL_NAME';   -- アプリケーション名
  cv_tk_cff_00101_02 CONSTANT VARCHAR2(15)  := 'INFO';        -- エラーメッセージ
  cv_tk_cff_90000_01 CONSTANT VARCHAR2(15)  := 'COUNT';       -- 処理対象
-- Ver.1.9 DEL Start
--  cv_tk_cff_90009_01 CONSTANT VARCHAR2(15)  := 'PARAM_NAME';  -- コンカレント入力パラメータ名
--  cv_tk_cff_90009_02 CONSTANT VARCHAR2(15)  := 'PARAM_VAL';   -- コンカレント入力パラメータ値
-- Ver.1.9 DEL End
  cv_tk_cff_00124_01 CONSTANT VARCHAR2(15)  := 'COLUMN_NAME'; -- カラム論理名
  cv_tk_cff_00124_02 CONSTANT VARCHAR2(15)  := 'COLUMN_INFO'; -- カラム名
  cv_tk_cff_00167_01 CONSTANT VARCHAR2(15)  := 'FILE_NAME';   -- ファイル名トークン
  cv_tk_cff_00167_02 CONSTANT VARCHAR2(15)  := 'CSV_NAME';    -- CSVファイル名トークン
--
  -- トークン
-- Ver.1.9 DEL Start
  cv_msg_cff_50014   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50014';  -- リース物件テーブル
-- Ver.1.9 DEL End
  cv_msg_cff_50040   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50040';  -- 契約番号
-- Ver.1.9 DEL Start
--  cv_msg_cff_50134   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50134';  -- リース契約日
-- Ver.1.9 DEL End
  cv_msg_cff_50041   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50041';  -- リース種別
  cv_msg_cff_50042   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50042';  -- リース区分
  cv_msg_cff_50043   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50043';  -- リース会社
-- Ver.1.9 DEL Start
--  cv_msg_cff_50044   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50044';  -- 再リース回数
-- Ver.1.9 DEL End
  cv_msg_cff_50045   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50045';  -- 件名
-- Ver.1.9 DEL Start
--  cv_msg_cff_50046   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50046';  -- リース開始日
-- Ver.1.9 DEL End
  cv_msg_cff_50047   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50047';  -- 支払回数
  cv_msg_cff_50048   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50048';  -- 頻度
-- Ver.1.9 DEL Start
--  cv_msg_cff_50049   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50049';  -- 年数
--  cv_msg_cff_50051   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50051';  -- リース終了日
--  cv_msg_cff_50052   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50052';  -- 初回支払日
--  cv_msg_cff_50053   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50053';  -- 2回目支払日
--  cv_msg_cff_50054   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50054';  -- 3回目以降支払日
--  cv_msg_cff_50055   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50055';  -- 費用計上開始会計期間
--  cv_msg_cff_50056   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50056';  -- リース契約テーブル
--  cv_msg_cff_50058   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50058';  -- 契約枝番
-- Ver.1.9 DEL End
  cv_msg_cff_50148   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50148';  -- 税金コード
  cv_msg_cff_50149   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50149';  -- 初回設置先
  cv_msg_cff_50150   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50150';  -- 初回設置場所
  cv_msg_cff_50108   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50108';  -- 初回月額リース料
  cv_msg_cff_50109   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50109';  -- ２回目以降月額リース料
  cv_msg_cff_50156   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50156';  -- 初回月額消費税額
  cv_msg_cff_50157   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50157';  -- ２回目以降消費税額
  cv_msg_cff_50158   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50158';  -- 月額リース控除額
-- Ver.1.9 DEL Start
--  cv_msg_cff_50159   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50159';  -- 月額リース控除消費税額
-- Ver.1.9 DEL End
  cv_msg_cff_50064   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50064';  -- 見積現金購入購入価額
  cv_msg_cff_50032   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50032';  -- 法定耐用年数
  cv_msg_cff_50010   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50010';  -- 物件コード
-- Ver.1.9 DEL Start
--  cv_msg_cff_50072   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50072';  -- 資産種類
-- Ver.1.9 DEL End
  cv_msg_cff_50011   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50011';  -- 管理部門コード
  cv_msg_cff_50012   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50012';  -- 本社/工場
  cv_msg_cff_50184   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50184';  -- 発注番号
  cv_msg_cff_50177   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50177';  -- メーカー名
  cv_msg_cff_50178   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50178';  -- 機種
  cv_msg_cff_50179   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50179';  -- 機番
  cv_msg_cff_50180   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50180';  -- 年式
  cv_msg_cff_50181   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50181';  -- 数量
  cv_msg_cff_50182   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50182';  -- 車台番号
  cv_msg_cff_50183   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50183';  -- 登録番号
  cv_msg_cff_50187   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50187';  -- リース契約・物件
--
-- Ver.1.9 DEL Start
--  cv_msg_cff_50121   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50121';  -- コンカレント入力パラメータ名
--  cv_msg_cff_50122   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50122';  -- ファイルID
-- Ver.1.9 DEL End
  cv_msg_cff_50130   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50130';  -- 初期処理
  cv_msg_cff_50131   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50131';  -- BLOBデータ変換用関数
--
-- 2018/03/27 Ver1.10 Otsuka ADD Start
  -- リース判定
  cv_lease_cls_chk1  CONSTANT VARCHAR2(1)  := '1';        -- リース判定結果：1
  cv_msg_cff_50323   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50323';  -- リース判定処理
-- 2018/03/27 Ver1.10 Otsuka ADD End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 配列変数
  --[障害T1_0721]MOD START
  --TYPE load_data_rtype  IS TABLE OF VARCHAR2(200)
  TYPE load_data_rtype  IS TABLE OF VARCHAR2(600)
  --[障害T1_0721]MOD END
    INDEX BY binary_integer;       
  TYPE load_name_rtype  IS TABLE OF VARCHAR2(50)
    INDEX BY binary_integer;       
  TYPE load_len_rtype   IS TABLE OF NUMBER(4)
    INDEX BY binary_integer;       
  TYPE load_dec_rtype   IS TABLE OF NUMBER(2)
    INDEX BY binary_integer;       
  TYPE load_null_rtype  IS TABLE OF VARCHAR2(10)
    INDEX BY binary_integer;       
  TYPE load_attr_rtype  IS TABLE OF NUMBER(1)
    INDEX BY binary_integer;       
--
  -- リース契約ワーク対象データレコード型
  TYPE contract_info_rtype IS RECORD(
    contract_number            xxcff_cont_headers_work.contract_number%TYPE
   ,lease_class                xxcff_cont_headers_work.lease_class%TYPE
   ,lease_type                 xxcff_cont_headers_work.lease_type%TYPE
   ,lease_company              xxcff_cont_headers_work.lease_company%TYPE
   ,re_lease_times             xxcff_cont_headers_work.re_lease_times%TYPE
   ,comments                   xxcff_cont_headers_work.comments%TYPE
   ,contract_date              xxcff_cont_headers_work.contract_date%TYPE
   ,payment_frequency          xxcff_cont_headers_work.payment_frequency%TYPE
   ,payment_type               xxcff_cont_headers_work.payment_type%TYPE
   ,lease_start_date           xxcff_cont_headers_work.lease_start_date%TYPE
   ,first_payment_date         xxcff_cont_headers_work.first_payment_date%TYPE
   ,second_payment_date        xxcff_cont_headers_work.second_payment_date%TYPE
   ,contract_line_num          xxcff_cont_lines_work.contract_line_num%TYPE
   ,lease_company_line         xxcff_cont_lines_work.lease_company%TYPE
   ,first_charge               xxcff_cont_lines_work.first_charge%TYPE
   ,first_tax_charge           xxcff_cont_lines_work.first_tax_charge%TYPE
   ,second_charge              xxcff_cont_lines_work.second_charge%TYPE
   ,second_tax_charge          xxcff_cont_lines_work.second_tax_charge%TYPE
   ,first_deduction            xxcff_cont_lines_work.first_deduction%TYPE
   ,first_tax_deduction        xxcff_cont_lines_work.first_tax_deduction%TYPE
   --ADD 2010/01/07 START
   ,second_deduction           xxcff_cont_lines_work.first_deduction%TYPE
   --ADD 2010/01/07 END
   ,estimated_cash_price       xxcff_cont_lines_work.estimated_cash_price%TYPE
   ,life_in_months             xxcff_cont_lines_work.life_in_months%TYPE
   ,lease_kind                 xxcff_cont_lines_work.lease_kind%TYPE
   ,asset_category             xxcff_cont_lines_work.asset_category%TYPE
   ,first_installation_address xxcff_cont_lines_work.first_installation_address%TYPE
   ,first_installation_place   xxcff_cont_lines_work.first_installation_place%TYPE 
   ,object_header_id           xxcff_cont_lines_work.object_header_id%TYPE
   ,tax_code                   xxcff_cont_headers_work.tax_code%TYPE
   ,object_code                xxcff_cont_obj_work.object_code%TYPE
   ,po_number                  xxcff_cont_obj_work.po_number%TYPE
   ,registration_number        xxcff_cont_obj_work.registration_number%TYPE
   ,age_type                   xxcff_cont_obj_work.age_type%TYPE
   ,model                      xxcff_cont_obj_work.model%TYPE
   ,serial_number              xxcff_cont_obj_work.serial_number%TYPE
   ,quantity                   xxcff_cont_obj_work.quantity%TYPE
   ,manufacturer_name         xxcff_cont_obj_work.manufacturer_name%TYPE
   ,department_code            xxcff_cont_obj_work.department_code%TYPE
   ,owner_company              xxcff_cont_obj_work.owner_company%TYPE
   ,chassis_number             xxcff_cont_obj_work.chassis_number%TYPE
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期処理情報
  gr_init_rec              xxcff_common1_pkg.init_rtype;
  -- リース契約ワーク情報
  gr_contract_info_rec     contract_info_rtype;
  -- リース契約情報
  gr_cont_hed_rec          xxcff_common4_pkg.cont_hed_data_rtype;
  -- リース契約明細情報
  gr_cont_line_rec         xxcff_common4_pkg.cont_lin_data_rtype;
  -- リース物件、物件情報
  gr_object_data_rec       xxcff_common3_pkg.object_data_rtype;
--
  -- リース契約項目
  gn_seqno                 xxcff_cont_headers_work.seqno%TYPE;
  gv_contract_number       xxcff_cont_headers_work.contract_number%TYPE;
  gv_lease_class           xxcff_cont_headers_work.lease_class%TYPE;
  gv_lease_type            xxcff_cont_headers_work.lease_type%TYPE;
  gv_lease_company         xxcff_cont_headers_work.lease_company%TYPE;
  gn_re_lease_times        xxcff_cont_headers_work.re_lease_times%TYPE;
  gv_comments              xxcff_cont_headers_work.comments%TYPE;
  gd_contract_date         xxcff_cont_headers_work.contract_date%TYPE;
  gn_payment_frequency     xxcff_cont_headers_work.payment_frequency%TYPE;
  gv_payment_type          xxcff_cont_headers_work.payment_type%TYPE;
  gd_lease_start_date      xxcff_cont_headers_work.lease_start_date%TYPE;
  gd_first_payment_date    xxcff_cont_headers_work.first_payment_date%TYPE;
  gd_second_payment_date   xxcff_cont_headers_work.second_payment_date%TYPE;
  gv_tax_code              xxcff_cont_headers_work.tax_code%TYPE;
--
  -- リース契約明細項目
  gn_seqno_line            xxcff_cont_lines_work.seqno%TYPE; 
  gv_contract_number_line  xxcff_cont_lines_work.contract_number%TYPE; 
  gv_contract_line_num     xxcff_cont_lines_work.contract_line_num%TYPE;
  gv_lease_company_line    xxcff_cont_lines_work.lease_company%TYPE;
  gn_first_charge          xxcff_cont_lines_work.first_charge%TYPE;
  gn_first_tax_charge      xxcff_cont_lines_work.first_tax_charge%TYPE; 
  gn_second_charge         xxcff_cont_lines_work.second_charge%TYPE; 
  gn_second_tax_charge     xxcff_cont_lines_work.second_tax_charge%TYPE; 
  gn_first_deduction       xxcff_cont_lines_work.first_deduction%TYPE; 
  gn_first_tax_deduction   xxcff_cont_lines_work.first_tax_deduction%TYPE; 
  gn_estimated_cash_price  xxcff_cont_lines_work.estimated_cash_price%TYPE; 
  gn_life_in_months        xxcff_cont_lines_work.life_in_months%TYPE; 
  gv_object_code           xxcff_cont_lines_work.object_code%TYPE; 
  gv_lease_kind            xxcff_cont_lines_work.lease_kind%TYPE; 
  gv_asset_category        xxcff_cont_lines_work.asset_category%TYPE; 
  gv_first_inst_address    xxcff_cont_lines_work.first_installation_address%TYPE; 
  gv_first_inst_place      xxcff_cont_lines_work.first_installation_place%TYPE; 
--  
  -- リース物件項目
  gn_seqno_obj             xxcff_cont_obj_work.seqno%TYPE; 
  gv_po_number             xxcff_cont_obj_work.po_number%TYPE;
  gv_registration_number   xxcff_cont_obj_work.registration_number%TYPE;
  gv_age_type              xxcff_cont_obj_work.age_type%TYPE;
  gv_model                 xxcff_cont_obj_work.model%TYPE;
  gv_serial_number         xxcff_cont_obj_work.serial_number%TYPE;
  gn_quantity              xxcff_cont_obj_work.quantity%TYPE;
  gv_manufacturer_name     xxcff_cont_obj_work.manufacturer_name%TYPE;
  gv_department_code       xxcff_cont_obj_work.department_code%TYPE;
  gv_owner_company         xxcff_cont_obj_work.owner_company%TYPE;
  gv_chassis_number        xxcff_cont_obj_work.chassis_number%TYPE;
--
  gr_file_data_tbl         xxccp_common_pkg2.g_file_data_tbl;        -- ファイルアップロードデータ格納配列
  gr_lord_data_tab         load_data_rtype;                          -- 文字項目分割後データ格納配列
  gr_lord_name_tab         load_name_rtype;                          -- 文字項目分割項目名格納配列
  gr_lord_len_tab          load_len_rtype;                           -- 文字項目分割項目長格納配列
  gr_lord_dec_tab          load_dec_rtype;                           -- 文字項目分割項目小数点以下格納配列
  gr_lord_null_tab         load_null_rtype;                          -- 文字項目分割項目必須フラグ格納配列
  gr_lord_attr_tab         load_attr_rtype;                          -- 文字項目分割項目項目属性格納配列
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id             IN  NUMBER                                -- 1.ファイルID
   ,in_file_upload_code    IN  NUMBER                                -- 2.ファイルアップロードコード
   ,ov_errbuf              OUT NOCOPY VARCHAR2                       -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2                       -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2                       -- ユーザー・エラー・メッセージ
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
-- 
    --*** ローカル定数 ***
--
    --*** ローカル変数 ***
    lv_usermsg    VARCHAR2(5000);  -- ユーザー・メッセージ
    lv_file_name  xxccp_mrp_file_ul_interface.file_name%TYPE;  -- エラー・メッセージ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.コンカレント入力パラメータの表示
    -- ***************************************************
--    アップロードCSVファイル名取得
    SELECT  file_name
    INTO    lv_file_name
    FROM    xxccp_mrp_file_ul_interface
    WHERE   file_id = in_file_id;
--    アップロードCSVファイル名ログ出力
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                   cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                   cv_msg_cff_00167,    -- メッセージ：アップロードCSVファイル名ログ出力
                   cv_tk_cff_00167_01,  -- ファイルアップロード名称 
                   cv_msg_cff_50187,    -- リース契約・物件 
                   cv_tk_cff_00167_02,  -- CSVファイル名
                   lv_file_name         -- ファイルID
                 ),1,5000);
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG      --ログ(システム管理者用メッセージ)出力         
     ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT   --メッセージ(ユーザ用メッセージ)出力
     ,buff   => lv_errmsg
    );
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
    -- ***************************************************
    -- 2.共通関数｢初期処理｣を実行する
    -- ***************************************************
--
    -- 共通初期処理の呼び出し
    xxcff_common1_pkg.init(
       or_init_rec => gr_init_rec         -- 1.初期情報格納
      ,ov_retcode  => lv_retcode
      ,ov_errbuf   => lv_errbuf
      ,ov_errmsg   => lv_errmsg
    );
--
    --異常終了の時
    IF (lv_retcode <> cv_status_normal) THEN                   
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                     cv_msg_cff_00094,    -- メッセージ：共通関数エラー
                     cv_tk_cff_00094_01,  -- 共通関数名
                     cv_msg_cff_50130     -- ファイルID
                    ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
 /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードI/F取得  (A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id             IN  NUMBER           -- 1.ファイルID
   ,ov_errbuf              OUT NOCOPY VARCHAR2  -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2  -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
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
--
    --*** ローカル定数 ***
--
    --*** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.BLOBデータ変換
    -- ***************************************************
    --共通アップロードデータ変換処理
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id       -- ファイルＩＤ
     ,ov_file_data => gr_file_data_tbl -- 変換後VARCHAR2データ
     ,ov_retcode   => lv_retcode
     ,ov_errbuf    => lv_errbuf
     ,ov_errmsg    => lv_errmsg
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN                   
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                     cv_msg_cff_00110,    -- メッセージ：データ変換エラー
                     cv_tk_cff_00101_01,  -- アプリケーション名
                     cv_msg_cff_50131,    -- BLOBデータ変換用関数
                     cv_tk_cff_00101_02,  -- INFO
                     lv_errmsg
                    ),1,5000);
      lv_errbuf := lv_errmsg;
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
  END get_if_data;
--
 /**********************************************************************************
   * Procedure Name   : devide_item
   * Description      : デリミタ文字項目分割         (A-3)
   ***********************************************************************************/
  PROCEDURE devide_item(
    in_file_data     IN  VARCHAR2          --  1.ファイルデータ
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'devide_item'; -- プログラム名
    cv_data_type_1   CONSTANT VARCHAR2(1)   := '1';           -- ｢1:ヘッダー｣
    cv_data_type_2   CONSTANT VARCHAR2(1)   := '2';           -- ｢2:明細｣
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
--
    --*** ローカル定数 ***
    cn_item_max     CONSTANT NUMBER(2) := 34;  --項目数 
--
    --*** ローカル変数 ***
    ln_item_cnt     NUMBER;  -- カウンタ
--
    --*** ローカル・カーソル ***
    CURSOR item_check_cur(in_type VARCHAR2)
    IS
    SELECT
           flv.lookup_code           AS lookup_code
          ,TO_NUMBER(flv.meaning)    AS index_num
          ,flv.description           AS item_name
          ,TO_NUMBER(flv.attribute1) AS item_len
          ,TO_NUMBER(flv.attribute2) AS item_dec
          ,flv.attribute3            AS item_null
          ,flv.attribute4            AS item_type
    FROM   fnd_lookup_values_vl flv
    WHERE  lookup_type = in_type
    ORDER BY flv.lookup_code;
--
    -- *** ローカル・レコード ***
    item_check_cur_rec item_check_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.デリミタ文字項目分割
    -- ***************************************************
    --初期化
    ln_item_cnt          := 1;
    -- 該当件数分ループする
    OPEN item_check_cur(cv_look_type);
    LOOP
      FETCH item_check_cur INTO item_check_cur_rec;
      EXIT WHEN item_check_cur%NOTFOUND;
      --
        gr_lord_data_tab(item_check_cur_rec.index_num) :=
          xxccp_common_pkg.char_delim_partition(in_file_data
                                               ,cv_csv_delim
                                               ,item_check_cur_rec.index_num
        );
      --コメント行はスキップするので以降の処理は不要
        IF (item_check_cur_rec.index_num = 1) THEN
          IF (gr_lord_data_tab(ln_item_cnt) <> cv_data_type_1) AND
             (gr_lord_data_tab(ln_item_cnt) <> cv_data_type_2) THEN
            RETURN;
          END IF;
        END IF;
      --
        gr_lord_name_tab(item_check_cur_rec.index_num) := item_check_cur_rec.item_name;
        gr_lord_len_tab(item_check_cur_rec.index_num)  := item_check_cur_rec.item_len;
        gr_lord_dec_tab(item_check_cur_rec.index_num)  := item_check_cur_rec.item_dec;
        gr_lord_null_tab(item_check_cur_rec.index_num) := item_check_cur_rec.item_null;
        gr_lord_attr_tab(item_check_cur_rec.index_num) := item_check_cur_rec.item_type;
    END LOOP;
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
--#####################################  固定部 END   ##########################################
--
  END devide_item;
--
 /**********************************************************************************
   * Procedure Name   : chk_err_disposion
   * Description      : 配列項目チェック処理         (A-4)
   ***********************************************************************************/
  PROCEDURE chk_err_disposion(
    ov_errbuf        OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_err_disposion'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    --*** ローカル定数 ***
    cv_data_type_1     CONSTANT VARCHAR2(1)  := '1';        -- ｢1:ヘッダー｣
    cv_data_type_2     CONSTANT VARCHAR2(1)  := '2';        -- ｢2:明細｣
    cv_check_scope     CONSTANT VARCHAR2(10) := 'GARBLED';  -- 文字化けチェック   
    cv_check_must_y    CONSTANT VARCHAR2(10) := 'NULL_NG';  -- 必須フラグ=Y
    cv_check_must_n    CONSTANT VARCHAR2(10) := 'NULL_OK';  -- 必須フラグ=N
    cv_check_format_0  CONSTANT VARCHAR2(1)  := '0';        -- VARCHAR2
    cv_check_format_1  CONSTANT VARCHAR2(1)  := '1';        -- NUMBER
    cv_check_format_2  CONSTANT VARCHAR2(1)  := '2';        -- DATE
--
    --*** ローカル変数 ***
    lv_return     BOOLEAN;          -- リターン値
    lv_err_flag   VARCHAR2(1);      -- エラー存在フラグ
    lv_err_info   VARCHAR2(5000);   -- エラー対象情報
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.各項目のフォーマット、必須チェック
    -- ***************************************************
    -- エラー対象情報の編集
    lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                    cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                    cv_msg_cff_00009,    -- メッセージ：エラー対象
                    cv_tk_cff_00009_01,  -- 契約番号
                    gr_lord_data_tab(2),
                    cv_tk_cff_00009_02,  -- リース会社
                    gr_lord_data_tab(3),
                    cv_tk_cff_00009_03,  -- 契約枝番
                    gr_lord_data_tab(12), 
                    cv_tk_cff_00009_04,  -- 物件コード
                    gr_lord_data_tab(13) 
                  ),1,5000);
--
    -- エラーチェックフラグをクリアする。
    lv_err_flag := cv_const_n;
--
    -- データ区分が｢1:ヘッダー｣の時
    IF (gr_lord_data_tab(1) = cv_data_type_1) THEN
      -- 1.契約番号
--DEL 2009/11/27 START
/*
      --(半角チェック)
      lv_return := xxccp_common_pkg.chk_alphabet_number(
                     iv_check_char   => gr_lord_data_tab(2)); 
      IF (lv_return <> TRUE) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00179 ,   -- メッセージ：半角英数字エラー
                      cv_tk_cff_00005_01,  -- カラム名
                      cv_msg_cff_50040     -- 契約番号
                    ),1,5000)
        );
      END IF;              
*/
--DEL 2009/11/27 END
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(2)   -- 項目名称
       ,gr_lord_data_tab(2)   -- 項目値
       ,gr_lord_len_tab(2)    -- 項目の長さ
       ,gr_lord_dec_tab(2)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(2)   -- 必須フラグ
       ,gr_lord_attr_tab(2)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(2),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50040     -- 契約番号
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_contract_number := gr_lord_data_tab(2);
        END IF;
      END IF;
--       
      -- 2.リース会社
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(3)   -- 項目名称
       ,gr_lord_data_tab(3)   -- 項目値
       ,gr_lord_len_tab(3)    -- 項目の長さ
       ,gr_lord_dec_tab(3)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(3)   -- 必須フラグ
       ,gr_lord_attr_tab(3)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg       
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --変数に格納する。
        gv_lease_company := gr_lord_data_tab(3);
      END IF;
--      
      -- 3.件名
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(4)   -- 項目名称
       ,gr_lord_data_tab(4)   -- 項目値
       ,gr_lord_len_tab(4)    -- 項目の長さ
       ,gr_lord_dec_tab(4)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(4)   -- 必須フラグ
       ,gr_lord_attr_tab(4)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg       
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(4),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50045     -- 件名
                      ),1,5000)
          );
        ELSE
          --変数に格納する。
          gv_comments := gr_lord_data_tab(4);
        END IF;
      END IF;
--       
      -- 4.契約日
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(5)   -- 項目名称
       ,gr_lord_data_tab(5)   -- 項目値
       ,gr_lord_len_tab(5)    -- 項目の長さ
       ,gr_lord_dec_tab(5)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(5)   -- 必須フラグ
       ,gr_lord_attr_tab(5)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );            
      ELSE
        --変数に格納する。
        gd_contract_date := TO_DATE(gr_lord_data_tab(5),'YYYY/MM/DD');
      END IF;
--     
      -- 5.リース種別
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(6)   -- 項目名称
       ,gr_lord_data_tab(6)   -- 項目値
       ,gr_lord_len_tab(6)    -- 項目の長さ
       ,gr_lord_dec_tab(6)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(6)   -- 必須フラグ
       ,gr_lord_attr_tab(6)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg       
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );        
      ELSE
        --変数に格納する。
        gv_lease_class := gr_lord_data_tab(6);
      END IF;
--       
      -- 7.リース開始日
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(7)   -- 項目名称
       ,gr_lord_data_tab(7)   -- 項目値
       ,gr_lord_len_tab(7)    -- 項目の長さ
       ,gr_lord_dec_tab(7)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(7)   -- 必須フラグ
       ,gr_lord_attr_tab(7)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          ); 
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );            
      ELSE
        --変数に格納する。
        gd_lease_start_date := TO_DATE(gr_lord_data_tab(7),'YYYY/MM/DD');
      END IF;
--
      -- 8.支払回数
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(8)   -- 項目名称
       ,gr_lord_data_tab(8)   -- 項目値
       ,gr_lord_len_tab(8)    -- 項目の長さ
       ,gr_lord_dec_tab(8)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(8)   -- 必須フラグ
       ,gr_lord_attr_tab(8)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(8)) < 0) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            ); 
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50047     -- 支払回数
                      ),1,5000)
          );
        END IF;
        --変数に格納する。
        gn_payment_frequency := TO_NUMBER(gr_lord_data_tab(8));
      END IF;
--       
      -- 9.初回支払日
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(9)   -- 項目名称
       ,gr_lord_data_tab(9)   -- 項目値
       ,gr_lord_len_tab(9)    -- 項目の長さ
       ,gr_lord_dec_tab(9)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(9)   -- 必須フラグ
       ,gr_lord_attr_tab(9)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );            
      ELSE
        --変数に格納する。
        gd_first_payment_date := TO_DATE(gr_lord_data_tab(9),'YYYY/MM/DD');
      END IF;
--
      -- 10.２回目支払日
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(10)   -- 項目名称
       ,gr_lord_data_tab(10)   -- 項目値
       ,gr_lord_len_tab(10)    -- 項目の長さ
       ,gr_lord_dec_tab(10)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(10)   -- 必須フラグ
       ,gr_lord_attr_tab(10)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );            
      ELSE
        --変数に格納する。
        gd_second_payment_date := TO_DATE(gr_lord_data_tab(10),'YYYY/MM/DD');
      END IF;
--  
      -- 11.税金コード
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(11)   -- 項目名称
       ,gr_lord_data_tab(11)   -- 項目値
       ,gr_lord_len_tab(11)    -- 項目の長さ
       ,gr_lord_dec_tab(11)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(11)   -- 必須フラグ
       ,gr_lord_attr_tab(11)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --変数に格納する。
        gv_tax_code  := gr_lord_data_tab(11);
      END IF;
--
    ELSIF (gr_lord_data_tab(1) = cv_data_type_2) THEN
      -- 1.契約番号
--DEL 2009/11/27 START
/*
      --(半角チェック)
      lv_return := xxccp_common_pkg.chk_alphabet_number(
                     iv_check_char   => gr_lord_data_tab(2)); 
      IF (lv_return <> TRUE) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00179 ,   -- メッセージ：半角英数字エラー
                      cv_tk_cff_00005_01,  -- カラム名
                      cv_msg_cff_50040     -- 契約番号
                    ),1,5000)
        );
      END IF;              
*/
--DEL 2009/11/27 END
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(2)   -- 項目名称
       ,gr_lord_data_tab(2)   -- 項目値
       ,gr_lord_len_tab(2)    -- 項目の長さ
       ,gr_lord_dec_tab(2)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(2)   -- 必須フラグ
       ,gr_lord_attr_tab(2)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(2),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50040     -- 契約番号
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_contract_number_line := gr_lord_data_tab(2);
        END IF;
      END IF;
--       
      -- 2.契約枝番
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(12)   -- 項目名称
       ,gr_lord_data_tab(12)   -- 項目値
       ,gr_lord_len_tab(12)    -- 項目の長さ
       ,gr_lord_dec_tab(12)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(12)   -- 必須フラグ
       ,gr_lord_attr_tab(12)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --変数に格納する。
        gv_contract_line_num := TO_NUMBER(gr_lord_data_tab(12));
      END IF;
--      
      -- 3.リース会社
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(3)   -- 項目名称
       ,gr_lord_data_tab(3)   -- 項目値
       ,gr_lord_len_tab(3)    -- 項目の長さ
       ,gr_lord_dec_tab(3)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(3)   -- 必須フラグ
       ,gr_lord_attr_tab(3)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --変数に格納する。
        gv_lease_company_line := gr_lord_data_tab(3);
      END IF;
--      
      -- 4.物件コード
      --(半角チェック)
      lv_return := xxccp_common_pkg.chk_alphabet_number(
                     iv_check_char   => gr_lord_data_tab(13)); 
      IF (lv_return <> TRUE) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00179 ,   -- メッセージ：半角英数字エラー
                      cv_tk_cff_00005_01,  -- カラム名
                      cv_msg_cff_50010     -- 物件コード
                    ),1,5000)
        );
      END IF;                    
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(13)   -- 項目名称
       ,gr_lord_data_tab(13)   -- 項目値
       ,gr_lord_len_tab(13)    -- 項目の長さ
       ,gr_lord_dec_tab(13)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(13)   -- 必須フラグ
       ,gr_lord_attr_tab(13)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --変数に格納する。
        gv_object_code := gr_lord_data_tab(13);
      END IF;
--      
      -- 5.資産種類
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(14)   -- 項目名称
       ,gr_lord_data_tab(14)   -- 項目値
       ,gr_lord_len_tab(14)    -- 項目の長さ
       ,gr_lord_dec_tab(14)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(14)   -- 必須フラグ
       ,gr_lord_attr_tab(14)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --変数に格納する。
        gv_asset_category := gr_lord_data_tab(14);
      END IF;
--
      -- 6.初回設置先
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(15)   -- 項目名称
       ,gr_lord_data_tab(15)   -- 項目値
       ,gr_lord_len_tab(15)    -- 項目の長さ
       ,gr_lord_dec_tab(15)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(15)   -- 必須フラグ
       ,gr_lord_attr_tab(15)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(15),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50149     -- 初回設置先
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          --[障害T1_0721]MOD START
          --gv_first_inst_address := gr_lord_data_tab(15);
          gv_first_inst_place := gr_lord_data_tab(15);
          --[障害T1_0721]MOD END
        END IF;
      END IF;  
--
      -- 7.初回設置場所
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(16)   -- 項目名称
       ,gr_lord_data_tab(16)   -- 項目値
       ,gr_lord_len_tab(16)    -- 項目の長さ
       ,gr_lord_dec_tab(16)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(16)   -- 必須フラグ
       ,gr_lord_attr_tab(16)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(16),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50150     -- 初回設置場所
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          --[障害T1_0721]MOD START
          --gv_first_inst_place  := gr_lord_data_tab(16);
          gv_first_inst_address  := gr_lord_data_tab(16);
          --[障害T1_0721]MOD END
        END IF;
      END IF;  
--      
      -- 8.初回月額リース料
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(17)   -- 項目名称
       ,gr_lord_data_tab(17)   -- 項目値
       ,gr_lord_len_tab(17)    -- 項目の長さ
       ,gr_lord_dec_tab(17)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(17)   -- 必須フラグ
       ,gr_lord_attr_tab(17)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(17)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50108     -- 初回月額リース料
                      ),1,5000)
          );
        END IF;        --変数に格納する。
        gn_first_charge := TO_NUMBER(gr_lord_data_tab(17));
      END IF;   
--      
      -- 9.初回月額消費税額
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(18)   -- 項目名称
       ,gr_lord_data_tab(18)   -- 項目値
       ,gr_lord_len_tab(18)    -- 項目の長さ
       ,gr_lord_dec_tab(18)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(18)   -- 必須フラグ
       ,gr_lord_attr_tab(18)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(18)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50156     -- 初回月額消費税額
                      ),1,5000)
          );
        END IF;
        --変数に格納する。
        gn_first_tax_charge := TO_NUMBER(gr_lord_data_tab(18));
      END IF;   
--
      -- 11.２回目月額リース料
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(19)   -- 項目名称
       ,gr_lord_data_tab(19)   -- 項目値
       ,gr_lord_len_tab(19)    -- 項目の長さ
       ,gr_lord_dec_tab(19)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(19)   -- 必須フラグ
       ,gr_lord_attr_tab(19)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(19)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50109     -- ２回目月額リース料
                      ),1,5000)
          );
        END IF;
        --変数に格納する。
        gn_second_charge := TO_NUMBER(gr_lord_data_tab(19));
      END IF;   
--
      -- 11.２回目以降消費税額
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(20)   -- 項目名称
       ,gr_lord_data_tab(20)   -- 項目値
       ,gr_lord_len_tab(20)    -- 項目の長さ
       ,gr_lord_dec_tab(20)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(20)   -- 必須フラグ
       ,gr_lord_attr_tab(20)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(20)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50157     -- ２回目以降消費税額
                      ),1,5000)
          );
        END IF;
        --変数に格納する。
        gn_second_tax_charge := TO_NUMBER(gr_lord_data_tab(20));
      END IF;      
--
      -- 12.維持管理費用相当額（総額）
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(21)   -- 項目名称
       ,gr_lord_data_tab(21)   -- 項目値
       ,gr_lord_len_tab(21)    -- 項目の長さ
       ,gr_lord_dec_tab(21)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(21)   -- 必須フラグ
       ,gr_lord_attr_tab(21)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(21)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50158     -- 月額リース控除額
                      ),1,5000)
          );
        END IF;
        --変数に格納する。
        gn_first_deduction := TO_NUMBER(gr_lord_data_tab(21));
      END IF;      
--
--DEL 2010/01/07 START
--      -- 12.月額リース控除消費税額
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(22)   -- 項目名称
--       ,gr_lord_data_tab(22)   -- 項目値
--       ,gr_lord_len_tab(22)    -- 項目の長さ
--       ,gr_lord_dec_tab(22)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(22)   -- 必須フラグ
--       ,gr_lord_attr_tab(22)    -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        IF (TO_NUMBER(gr_lord_data_tab(22)) < 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50159     -- 月額リース控除消費税額
--                      ),1,5000)
--          );
--        END IF;
--        --変数に格納する。
--        gn_first_tax_deduction := TO_NUMBER(gr_lord_data_tab(22));
--      END IF;      
----
--      -- 13.見積現金購入金額
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(23)   -- 項目名称
--       ,gr_lord_data_tab(23)   -- 項目値
--       ,gr_lord_len_tab(23)    -- 項目の長さ
--       ,gr_lord_dec_tab(23)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(23)   -- 必須フラグ
--       ,gr_lord_attr_tab(23)    -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        IF (TO_NUMBER(gr_lord_data_tab(23)) < 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50064     -- 見積現金購入金額
--                      ),1,5000)
--          );
--        END IF;
--        --変数に格納する。
--        gn_estimated_cash_price := TO_NUMBER(gr_lord_data_tab(23));
--      END IF;      
----
--      -- 14.法定耐用年数
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(24)   -- 項目名称
--       ,gr_lord_data_tab(24)   -- 項目値
--       ,gr_lord_len_tab(24)    -- 項目の長さ
--       ,gr_lord_dec_tab(24)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(24)   -- 必須フラグ
--       ,gr_lord_attr_tab(24)    -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        IF (TO_NUMBER(gr_lord_data_tab(24)) < 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          --
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50032     -- 法定耐用年数
--                      ),1,5000)
--          );
--        END IF;
--        --変数に格納する。
--        gn_life_in_months := TO_NUMBER(gr_lord_data_tab(24));
--      END IF;         
----
--      -- 15.本社/工場
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(25)   -- 項目名称
--       ,gr_lord_data_tab(25)   -- 項目値
--       ,gr_lord_len_tab(25)    -- 項目の長さ
--       ,gr_lord_dec_tab(25)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(25)   -- 必須フラグ
--       ,gr_lord_attr_tab(25)    -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(25),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50012     -- 工場/本社
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--          gv_owner_company := gr_lord_data_tab(25);
--        END IF;         
--      END IF;         
----
--      -- 16.管理部門コード
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(26)   -- 項目名称
--       ,gr_lord_data_tab(26)   -- 項目値
--       ,gr_lord_len_tab(26)    -- 項目の長さ
--       ,gr_lord_dec_tab(26)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(26)   -- 必須フラグ
--       ,gr_lord_attr_tab(26)    -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(26),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50011     -- 管理部門コード
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--          gv_department_code := gr_lord_data_tab(26);
--        END IF;         
--      END IF;         
----
--      -- 17.発注番号
--      --(必須、文字数チェック) gv_po_number
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(27)   -- 項目名称
--       ,gr_lord_data_tab(27)   -- 項目値
--       ,gr_lord_len_tab(27)    -- 項目の長さ
--       ,gr_lord_dec_tab(27)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(27)   -- 必須フラグ
--       ,gr_lord_attr_tab(27)   -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(27),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50184     -- 発注番号
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--           gv_po_number := gr_lord_data_tab(27);
--        END IF;         
--      END IF;               
----
--      -- 18.メーカー名
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(28)   -- 項目名称
--       ,gr_lord_data_tab(28)   -- 項目値
--       ,gr_lord_len_tab(28)    -- 項目の長さ
--       ,gr_lord_dec_tab(28)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(28)   -- 必須フラグ
--       ,gr_lord_attr_tab(28)   -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(28),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50177     -- メーカー名
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--          gv_manufacturer_name := gr_lord_data_tab(28);
--        END IF;         
--      END IF;               
----
--      -- 19.機種
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(29)   -- 項目名称
--       ,gr_lord_data_tab(29)   -- 項目値
--       ,gr_lord_len_tab(29)    -- 項目の長さ
--       ,gr_lord_dec_tab(29)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(29)   -- 必須フラグ
--       ,gr_lord_attr_tab(29)   -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(29),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50178     -- 機種
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--          gv_model   := gr_lord_data_tab(29);
--        END IF;         
--      END IF;               
----
--      -- 20.機番
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(30)   -- 項目名称
--       ,gr_lord_data_tab(30)   -- 項目値
--       ,gr_lord_len_tab(30)    -- 項目の長さ
--       ,gr_lord_dec_tab(30)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(30)   -- 必須フラグ
--       ,gr_lord_attr_tab(30)   -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(30),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50179     -- 機番
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--          gv_serial_number   := gr_lord_data_tab(30);
--        END IF;         
--      END IF;      
----
--      -- 21.年式
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(31)   -- 項目名称
--       ,gr_lord_data_tab(31)   -- 項目値
--       ,gr_lord_len_tab(31)    -- 項目の長さ
--       ,gr_lord_dec_tab(31)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(31)   -- 必須フラグ
--       ,gr_lord_attr_tab(31)   -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(31),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50180     -- 年式
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--          gv_age_type   := gr_lord_data_tab(31);
--        END IF;         
--      END IF;      
----
--      -- 22.数量
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(32)   -- 項目名称
--       ,gr_lord_data_tab(32)   -- 項目値
--       ,gr_lord_len_tab(32)    -- 項目の長さ
--       ,gr_lord_dec_tab(32)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(32)   -- 必須フラグ
--       ,gr_lord_attr_tab(32)   -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        IF (TO_NUMBER(gr_lord_data_tab(32)) < 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50181     -- 数量
--                      ),1,5000)
--          );
--        ELSE
--          --変数に格納する。
--          gn_quantity   := TO_NUMBER(gr_lord_data_tab(32));
--        END IF;
--      END IF;      
----
--      -- 23.車台番号
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(33)   -- 項目名称
--       ,gr_lord_data_tab(33)   -- 項目値
--       ,gr_lord_len_tab(33)    -- 項目の長さ
--       ,gr_lord_dec_tab(33)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(33)   -- 必須フラグ
--       ,gr_lord_attr_tab(33)   -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(33),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50182     -- 車台番号
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--          gv_chassis_number  := gr_lord_data_tab(33);
--        END IF;         
--      END IF;      
----
--      -- 24.登録番号
--      --(必須、文字数チェック)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(34)   -- 項目名称
--       ,gr_lord_data_tab(34)   -- 項目値
--       ,gr_lord_len_tab(34)    -- 項目の長さ
--       ,gr_lord_dec_tab(34)    -- 項目の長さ(小数点以下)
--       ,gr_lord_null_tab(34)   -- 必須フラグ
--       ,gr_lord_attr_tab(34)   -- 項目型
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- エラー対象情報の出力
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(禁則文字チェック)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(34),   -- 対象文字列
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- エラー対象情報の出力
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
--                        cv_tk_cff_00005_01,  -- カラム名
--                        cv_msg_cff_50183     -- 登録番号
--                      ),1,5000)
--          );            
--        ELSE
--          --変数に格納する。
--          gv_registration_number  := gr_lord_data_tab(34);
--        END IF;         
--      END IF;      
--DEL 2010/01/07 END
--
--ADD 2010/01/07 START
--
      -- 13.見積現金購入金額
      --(文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(22)   -- 項目名称
       ,gr_lord_data_tab(22)   -- 項目値
       ,gr_lord_len_tab(22)    -- 項目の長さ
       ,gr_lord_dec_tab(22)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(22)   -- 必須フラグ
       ,gr_lord_attr_tab(22)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
-- 2018/03/27 Ver1.10 Otsuka MOD Start
--      ここではリース判別結果を利用しないため、一旦NVLで回避
--      マイナス値のみを対象とする
--        IF (TO_NUMBER(gr_lord_data_tab(22)) < 0) THEN
        IF (NVL(TO_NUMBER(gr_lord_data_tab(22)),0) < 0) THEN
-- 2018/03/27 Ver1.10 Otsuka MOD End
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0未満）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50064     -- 見積現金購入金額
                      ),1,5000)
          );
        END IF;
        --変数に格納する。
        gn_estimated_cash_price := TO_NUMBER(gr_lord_data_tab(22));
      END IF;      
--
      -- 14.法定耐用年数
      --(文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(23)   -- 項目名称
       ,gr_lord_data_tab(23)   -- 項目値
       ,gr_lord_len_tab(23)    -- 項目の長さ
       ,gr_lord_dec_tab(23)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(23)   -- 必須フラグ
       ,gr_lord_attr_tab(23)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
-- 2018/03/27 Ver1.10 Otsuka MOD Start
--      ここではリース判別結果を利用しないため、一旦NVLで回避
--      マイナス値のみを対象とする
--        IF (TO_NUMBER(gr_lord_data_tab(23)) < 0) THEN
        IF (NVL(TO_NUMBER(gr_lord_data_tab(23)),0) < 0) THEN
-- 2018/03/27 Ver1.10 Otsuka MOD End
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0未満）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50032     -- 法定耐用年数
                      ),1,5000)
          );
        END IF;
        --変数に格納する。
        gn_life_in_months := TO_NUMBER(gr_lord_data_tab(23));
      END IF;         
--
      -- 15.本社/工場
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(24)   -- 項目名称
       ,gr_lord_data_tab(24)   -- 項目値
       ,gr_lord_len_tab(24)    -- 項目の長さ
       ,gr_lord_dec_tab(24)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(24)   -- 必須フラグ
       ,gr_lord_attr_tab(24)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(24),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50012     -- 工場/本社
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_owner_company := gr_lord_data_tab(24);
        END IF;         
      END IF;         
--
      -- 16.管理部門コード
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(25)   -- 項目名称
       ,gr_lord_data_tab(25)   -- 項目値
       ,gr_lord_len_tab(25)    -- 項目の長さ
       ,gr_lord_dec_tab(25)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(25)   -- 必須フラグ
       ,gr_lord_attr_tab(25)    -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(25),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50011     -- 管理部門コード
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_department_code := gr_lord_data_tab(25);
        END IF;         
      END IF;         
--
      -- 17.発注番号
      --(必須、文字数チェック) gv_po_number
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(26)   -- 項目名称
       ,gr_lord_data_tab(26)   -- 項目値
       ,gr_lord_len_tab(26)    -- 項目の長さ
       ,gr_lord_dec_tab(26)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(26)   -- 必須フラグ
       ,gr_lord_attr_tab(26)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(26),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50184     -- 発注番号
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
           gv_po_number := gr_lord_data_tab(26);
        END IF;         
      END IF;               
--
      -- 18.メーカー名
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(27)   -- 項目名称
       ,gr_lord_data_tab(27)   -- 項目値
       ,gr_lord_len_tab(27)    -- 項目の長さ
       ,gr_lord_dec_tab(27)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(27)   -- 必須フラグ
       ,gr_lord_attr_tab(27)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(27),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50177     -- メーカー名
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_manufacturer_name := gr_lord_data_tab(27);
        END IF;         
      END IF;               
--
      -- 19.機種
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(28)   -- 項目名称
       ,gr_lord_data_tab(28)   -- 項目値
       ,gr_lord_len_tab(28)    -- 項目の長さ
       ,gr_lord_dec_tab(28)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(28)   -- 必須フラグ
       ,gr_lord_attr_tab(28)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(28),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50178     -- 機種
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_model   := gr_lord_data_tab(28);
        END IF;         
      END IF;               
--
      -- 20.機番
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(29)   -- 項目名称
       ,gr_lord_data_tab(29)   -- 項目値
       ,gr_lord_len_tab(29)    -- 項目の長さ
       ,gr_lord_dec_tab(29)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(29)   -- 必須フラグ
       ,gr_lord_attr_tab(29)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(29),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50179     -- 機番
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_serial_number   := gr_lord_data_tab(29);
        END IF;         
      END IF;      
--
      -- 21.年式
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(30)   -- 項目名称
       ,gr_lord_data_tab(30)   -- 項目値
       ,gr_lord_len_tab(30)    -- 項目の長さ
       ,gr_lord_dec_tab(30)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(30)   -- 必須フラグ
       ,gr_lord_attr_tab(30)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(30),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50180     -- 年式
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_age_type   := gr_lord_data_tab(30);
        END IF;         
      END IF;      
--
      -- 22.数量
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(31)   -- 項目名称
       ,gr_lord_data_tab(31)   -- 項目値
       ,gr_lord_len_tab(31)    -- 項目の長さ
       ,gr_lord_dec_tab(31)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(31)   -- 必須フラグ
       ,gr_lord_attr_tab(31)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(31)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00117,    -- メッセージ：数値論理エラー(0以下）
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50181     -- 数量
                      ),1,5000)
          );
        ELSE
          --変数に格納する。
          gn_quantity   := TO_NUMBER(gr_lord_data_tab(31));
        END IF;
      END IF;      
--
      -- 23.車台番号
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(32)   -- 項目名称
       ,gr_lord_data_tab(32)   -- 項目値
       ,gr_lord_len_tab(32)    -- 項目の長さ
       ,gr_lord_dec_tab(32)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(32)   -- 必須フラグ
       ,gr_lord_attr_tab(32)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(32),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50182     -- 車台番号
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_chassis_number  := gr_lord_data_tab(32);
        END IF;         
      END IF;      
--
      -- 24.登録番号
      --(必須、文字数チェック)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(33)   -- 項目名称
       ,gr_lord_data_tab(33)   -- 項目値
       ,gr_lord_len_tab(33)    -- 項目の長さ
       ,gr_lord_dec_tab(33)    -- 項目の長さ(小数点以下)
       ,gr_lord_null_tab(33)   -- 必須フラグ
       ,gr_lord_attr_tab(33)   -- 項目型
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- エラー対象情報の出力
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(禁則文字チェック)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(33),   -- 対象文字列
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- エラー対象情報の出力
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00138,    -- メッセージ：禁則文字エラー
                        cv_tk_cff_00005_01,  -- カラム名
                        cv_msg_cff_50183     -- 登録番号
                      ),1,5000)
          );            
        ELSE
          --変数に格納する。
          gv_registration_number  := gr_lord_data_tab(33);
        END IF;         
      END IF;      
--ADD 2010/01/07 END
--
    END IF;
--   
   --エラー存在時
   IF (lv_err_flag = cv_const_y) THEN
       ov_retcode := cv_status_error;
   END IF;
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
--#####################################  固定部 END   ##########################################
--
  END chk_err_disposion;
--
 /**********************************************************************************
   * Procedure Name   : ins_cont_work
   * Description      : アップロード振分処理          (A-5)
   ***********************************************************************************/
  PROCEDURE ins_cont_work(
    in_file_id       IN  NUMBER            -- 1.ファイルID
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cont_work'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cv_data_type_1     CONSTANT VARCHAR2(1)  := '1';        -- ｢1:ヘッダー｣
    cv_data_type_2     CONSTANT VARCHAR2(1)  := '2';        -- ｢2:明細｣
    cv_lease_type_1    CONSTANT VARCHAR2(1)  := '1';        -- ｢1:原契約｣
    cv_payment_type_0  CONSTANT VARCHAR2(1)  := '0';        -- ｢0:頻度（月）｣
--
    --*** ローカル変数 ***
    lv_return  BOOLEAN;  -- リターン値
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.ワークテーブルへの振分処理
    -- ***************************************************
    -- データ区分が｢1:ヘッダー｣の時
    IF (gr_lord_data_tab(1) = cv_data_type_1) THEN
      --リース契約ワークへの追加
      gn_seqno := gn_seqno + 1;
      INSERT INTO xxcff_cont_headers_work(
        seqno                                     -- 通番
      , contract_number                           -- 契約番号
      , lease_class                               -- リース種別
      , lease_type                                -- リース区分
      , lease_company                             -- リース会社
      , re_lease_times                            -- 再リース回数
      , comments                                  -- 件名
      , contract_date                             -- リース契約日
      , payment_frequency                         -- 支払回数
      , payment_type                              -- 頻度
      , lease_start_date                          -- リース開始日
      , first_payment_date                        -- 初回支払日
      , second_payment_date                       -- 2回目支払日
      , tax_code                                  -- 税金コード
      , file_id                                   -- ファイルID
      , created_by                                -- 作成者
      , creation_date                             -- 作成日
      , last_updated_by                           -- 最終更新者
      , last_update_date                          -- 最終更新日
      , last_update_login                         -- 最終更新ﾛｸﾞｲﾝ
      , request_id                                -- 要求ID
      , program_application_id                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      , program_id                                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      , program_update_date                       -- ﾌﾟﾛｸﾞﾗﾑ更新日
      )
      VALUES(
        gn_seqno                                  -- 通番
      , gv_contract_number                        -- 契約番号
      , gv_lease_class                            -- リース種別
      , cv_lease_type_1                           -- リース区分
      , gv_lease_company                          -- リース会社
      , 0                                         -- 再リース回数
      , gv_comments                               -- 件名
      , gd_contract_date                          -- リース契約日
      , gn_payment_frequency                      -- 支払回数
      , cv_payment_type_0                         -- 頻度
      , gd_lease_start_date                       -- リース開始日
      , gd_first_payment_date                     -- 初回支払日
      , gd_second_payment_date                    -- 2回目支払日
      , gv_tax_code                               -- 税金コード
      , in_file_id                                -- ファイルID
      , cn_created_by                             -- 作成者
      , cd_creation_date                          -- 作成日
      , cn_last_updated_by                        -- 最終更新者
      , cd_last_update_date                       -- 最終更新日
      , cn_last_update_login                      -- 最終更新ﾛｸﾞｲﾝ
      , cn_request_id                             -- 要求ID
      , cn_program_application_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      , cn_program_id                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      , cd_program_update_date                    -- ﾌﾟﾛｸﾞﾗﾑ更新日
      );
    ELSIF (gr_lord_data_tab(1) = cv_data_type_2) THEN
      gn_seqno_line := gn_seqno_line + 1;
      --リース契約明細ワークへの追加
      INSERT INTO xxcff_cont_lines_work(
        seqno                                     -- 通番
      , contract_number                           -- 契約番号
      , contract_line_num                         -- 契約枝番
      , lease_company                             -- リース会社 
      , first_charge                              -- 初回リース料
      , first_tax_charge                          -- 初回リース料_消費税額
      , second_charge                             -- ２回目リース料
      , second_tax_charge                         -- ２回目リース料_消費税額
      , first_deduction                           -- 初回リース料_控除額
      , first_tax_deduction                       -- 初回消費税額_控除額
      , estimated_cash_price                      -- 見積現金購入価額
      , life_in_months                            -- 法定耐用年数
      , object_code                               -- 物件コード
      , lease_kind                                -- リース種類
      , asset_category                            -- 資産種類
      , first_installation_address                -- 初回設置場所
      , first_installation_place                  -- 初回設置先
      , file_id                                   -- ファイルID
      , created_by                                -- 作成者
      , creation_date                             -- 作成日
      , last_updated_by                           -- 最終更新者
      , last_update_date                          -- 最終更新日
      , last_update_login                         -- 最終更新ﾛｸﾞｲﾝ
      , request_id                                -- 要求ID
      , program_application_id                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      , program_id                                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      , program_update_date                       -- ﾌﾟﾛｸﾞﾗﾑ更新日
      )
      VALUES(
        gn_seqno_line                             -- 通番
      , gv_contract_number_line                   -- 契約番号
      , gv_contract_line_num                      -- 契約枝番
      , gv_lease_company_line                     -- リース会社 
      , gn_first_charge                           -- 初回リース料
      , gn_first_tax_charge                       -- 初回リース料_消費税額
      , gn_second_charge                          -- ２回目リース料
      , gn_second_tax_charge                      -- ２回目リース料_消費税額
      , gn_first_deduction                        -- 初回リース料_控除額
--UPD 2010/01/07 START
      --, gn_first_tax_deduction                    -- 初回消費税額_控除額
      , 0                                         -- 初回消費税額_控除額
--UPD 2010/01/07 END
      , gn_estimated_cash_price                   -- 見積現金購入価額
      , gn_life_in_months                         -- 法定耐用年数
      , gv_object_code                            -- 物件コード
      , '0'                                       -- リース種類
      , gv_asset_category                         -- 資産種類
      , gv_first_inst_address                     -- 初回設置場所
      , gv_first_inst_place                       -- 初回設置先
      , in_file_id                                -- ファイルID
      , cn_created_by                             -- 作成者
      , cd_creation_date                          -- 作成日
      , cn_last_updated_by                        -- 最終更新者
      , cd_last_update_date                       -- 最終更新日
      , cn_last_update_login                      -- 最終更新ﾛｸﾞｲﾝ
      , cn_request_id                             -- 要求ID
      , cn_program_application_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      , cn_program_id                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      , cd_program_update_date                    -- ﾌﾟﾛｸﾞﾗﾑ更新日
      );
      --リース物件ワークへの追加
      INSERT INTO xxcff_cont_obj_work(
        seqno                                     -- 通番
      , contract_number                           -- 契約番号
      , contract_line_num                         -- 契約枝番
      , lease_company                             -- リース会社 
      , object_code                               -- 物件コード
      , po_number                                 -- 発注番号
      , registration_number                       -- 登録番号
      , age_type                                  -- 年式
      , model                                     -- 機種
      , serial_number                             -- 機番
      , quantity                                  -- 数量
      , manufacturer_name                         -- メーカー名
      , department_code                           -- 管理部門コード
      , owner_company                             -- 本社／工場
      , chassis_number                            -- 車台番号
      , file_id                                   -- ファイルID
      , created_by                                -- 作成者
      , creation_date                             -- 作成日
      , last_updated_by                           -- 最終更新者
      , last_update_date                          -- 最終更新日
      , last_update_login                         -- 最終更新ﾛｸﾞｲﾝ
      , request_id                                -- 要求ID
      , program_application_id                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      , program_id                                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      , program_update_date                       -- ﾌﾟﾛｸﾞﾗﾑ更新日
      )
      VALUES(
        gn_seqno_line                             -- 通番
      , gv_contract_number_line                   -- 契約番号
      , gv_contract_line_num                      -- 契約枝番
      , gv_lease_company_line                     -- リース会社 
      , gv_object_code                            -- 物件コード
      , gv_po_number                              -- 発注番号
      , gv_registration_number                    -- 登録番号
      , gv_age_type                               -- 年式
      , gv_model                                  -- 機種
      , gv_serial_number                          -- 機番
      , gn_quantity                               -- 数量
      , gv_manufacturer_name                      -- メーカー名
      , gv_department_code                        -- 管理部門コード
      , gv_owner_company                          -- 本社／工場
      , gv_chassis_number                         -- 車台番号
      , in_file_id                                -- ファイルID
      , cn_created_by                             -- 作成者
      , cd_creation_date                          -- 作成日
      , cn_last_updated_by                        -- 最終更新者
      , cd_last_update_date                       -- 最終更新日
      , cn_last_update_login                      -- 最終更新ﾛｸﾞｲﾝ
      , cn_request_id                             -- 要求ID
      , cn_program_application_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      , cn_program_id                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      , cd_program_update_date                    -- ﾌﾟﾛｸﾞﾗﾑ更新日
      );
    END IF; 
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
--#####################################  固定部 END   ##########################################
--
  END ins_cont_work;
--
  /**********************************************************************************
   * Procedure Name   : chk_rept_adjust
   * Description      : ﾜｰｸﾌｧｲﾙ重複・整合性ﾁｪｯｸ処理      (A-7)
   ***********************************************************************************/
  PROCEDURE chk_rept_adjust(
    in_file_id       IN  NUMBER            -- 1.ファイルID
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_rept_adjust'; -- プログラム名
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
--
    --*** ローカル定数 ***
--
    --*** ローカル変数 ***
    lv_err_flag          VARCHAR2(1);      -- エラー存在フラグ
    lv_err_flag_1        VARCHAR2(1);      -- カーソル別エラーフラグ１
    lv_err_flag_2        VARCHAR2(1);      -- カーソル別エラーフラグ２
    lv_err_flag_3        VARCHAR2(1);      -- カーソル別エラーフラグ３
    lv_err_flag_4        VARCHAR2(1);      -- カーソル別エラーフラグ４
    lv_err_flag_5        VARCHAR2(1);      -- カーソル別エラーフラグ５
    lv_err_flag_6        VARCHAR2(1);      -- カーソル別エラーフラグ６
    lv_err_info          VARCHAR2(5000);   -- エラー対象情報
    lv_contract_number   xxcff_cont_headers_work.contract_number%TYPE;   -- 契約番号ブレーク用
    lv_lease_company     xxcff_cont_headers_work.lease_company%TYPE;     -- リース会社ブレーク用
    ln_check_cnt         NUMBER(2);        -- 再リース回数チェック用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース契約ワーク上の契約番号重複チェック用
    CURSOR xchw_double_data_cur
    IS
      SELECT xchw.contract_number    AS contract_number
            ,xchw.lease_company      AS lease_company 
            ,COUNT(*)                AS seqno
      FROM   xxcff_cont_headers_work xchw
      WHERE  xchw.file_id          = in_file_id
      GROUP  BY xchw.contract_number
            ,xchw.lease_company
      HAVING COUNT(*) > 1;
    -- *** ローカル・レコード ***
    xchw_double_data_rec xchw_double_data_cur%ROWTYPE;
--
    -- リース契約ワーク上の契約番号存在チェック用
    CURSOR xchw_exist_data_cur
    IS
      SELECT xchw.contract_number    AS contract_number
            ,xchw.lease_company      AS lease_company 
      FROM   xxcff_cont_headers_work xchw
      WHERE  NOT EXISTS
       (SELECT null
        FROM   xxcff_cont_lines_work xclw
        WHERE  xclw.file_id          =  in_file_id
        AND    xclw.contract_number  =  xchw.contract_number
        AND    xclw.lease_company    =  xchw.lease_company)
      AND    xchw.file_id          = in_file_id;
    -- *** ローカル・レコード ***
    xchw_exist_data_rec xchw_exist_data_cur%ROWTYPE;
--
    -- リース契約明細ワーク上の契約番号重複チェック用
    CURSOR xclw_double_data_cur
    IS
      SELECT xclw.contract_number    AS contract_number
            ,xclw.contract_line_num  AS contract_line_num
            ,xclw.lease_company      AS lease_company
            ,COUNT(*)                AS seqno
      FROM   xxcff_cont_lines_work   xclw
      WHERE xclw.file_id             = in_file_id
      GROUP BY xclw.contract_number
              ,xclw.contract_line_num
              ,xclw.lease_company
      HAVING   COUNT(*) > 1;
    -- *** ローカル・レコード ***
    xclw_double_data_rec xclw_double_data_cur%ROWTYPE;
--
    -- リース契約明細ワーク上の契約番号存在チェック用
    CURSOR xclw_exist_data_cur
    IS
      SELECT xclw.contract_number    AS contract_number
            ,xclw.contract_line_num  AS contract_line_num
            ,xclw.lease_company      AS lease_company 
      FROM   xxcff_cont_lines_work   xclw
      WHERE  NOT EXISTS
       (SELECT null
        FROM   xxcff_cont_headers_work xchw
        WHERE  xchw.file_id          =  in_file_id
        AND    xchw.contract_number  =  xclw.contract_number
        AND    xchw.lease_company    =  xclw.lease_company)
      AND    xclw.file_id = in_file_id;
    -- *** ローカル・レコード ***
    xclw_exist_data_rec xclw_exist_data_cur%ROWTYPE;
--
    -- １契約明細数チェック用
    CURSOR xclw_line_num_data_cur
    IS
      SELECT xclw.contract_number   AS contract_number
            ,xclw.lease_company     AS lease_company
            ,COUNT(*)               AS seqno
      FROM   xxcff_cont_lines_work  xclw
      WHERE  xclw.file_id       = in_file_id
      GROUP  BY xclw.contract_number
               ,xclw.lease_company
      HAVING COUNT(*) > 999;
    -- *** ローカル・レコード ***
    xclw_line_num_data_rec xclw_line_num_data_cur%ROWTYPE;
--
    -- 物件コードチェック用
    CURSOR xclw_object_data_cur
    IS
      SELECT xclw.object_code       AS object_code
            ,COUNT(*)               AS seqno
      FROM   xxcff_cont_lines_work  xclw
      WHERE  xclw.file_id  = in_file_id
      GROUP  BY xclw.object_code 
      HAVING COUNT(*) > 1;
    -- *** ローカル・レコード ***
    xclw_object_data_rec xclw_object_data_cur%ROWTYPE;
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
    lv_err_flag   := cv_const_n;
    lv_err_flag_1 := cv_const_n;
    lv_err_flag_2 := cv_const_n;
    lv_err_flag_3 := cv_const_n;
    lv_err_flag_4 := cv_const_n;
    lv_err_flag_5 := cv_const_n;
    lv_err_flag_6 := cv_const_n;
    --
    -- ***************************************************
    -- 1.リース契約ワーク上の契約番号重複チェック
    -- **************************************************
    OPEN xchw_double_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xchw_double_data_cur INTO xchw_double_data_rec;
      EXIT WHEN xchw_double_data_cur%NOTFOUND;
--
        --エラー対象レコードの出力
        lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                       cv_msg_cff_00146,    -- メッセージ：リース契約エラー対象
                       cv_tk_cff_00009_01,  -- 契約番号
                       xchw_double_data_rec.contract_number, 
                       cv_tk_cff_00009_02,  -- リース会社
                       xchw_double_data_rec.lease_company
                      ),1,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_info
        );
        --エラーメッセージの出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00119     -- メッセージ：契約番号重複エラー
                    ),1,5000)
        );
        lv_err_flag := cv_const_y;
        --エラー件数のカウント
        IF (lv_err_flag_1 = cv_const_n) THEN
          lv_err_flag_1 := cv_const_y;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
    END LOOP;
    CLOSE xchw_double_data_cur;
--
    -- ***************************************************
    -- 2.リース契約ワーク上の契約番号存在チェック
    -- ***************************************************
    OPEN xchw_exist_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xchw_exist_data_cur INTO xchw_exist_data_rec;
      EXIT WHEN xchw_exist_data_cur%NOTFOUND;
--
        --エラー対象レコードの出力
        lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                       cv_msg_cff_00146,    -- メッセージ：リース契約エラー対象
                       cv_tk_cff_00009_01,  -- 契約番号
                       xchw_exist_data_rec.contract_number, 
                       cv_tk_cff_00009_02,  -- リース会社
                       xchw_exist_data_rec.lease_company
                      ),1,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_info
        );
        --エラーメッセージの出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00127     -- メッセージ：契約番号不整合エラー
                    ),1,5000)
        );
        lv_err_flag := cv_const_y;
        --エラー件数のカウント
        IF (lv_err_flag_2 = cv_const_n) THEN
          lv_err_flag_2 := cv_const_y;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
    END LOOP;
    CLOSE xchw_exist_data_cur;
--
    -- ***************************************************
    -- 3.リース契約ワーク上の契約番号存在チェック
    -- ***************************************************
    OPEN xclw_double_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xclw_double_data_cur INTO xclw_double_data_rec;
      EXIT WHEN xclw_double_data_cur%NOTFOUND;
--
        --エラー対象レコードの出力
        lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                       cv_msg_cff_00147,    -- メッセージ：リース契約明細エラー対象
                       cv_tk_cff_00009_01,  -- 契約番号
                       xclw_double_data_rec.contract_number, 
                       cv_tk_cff_00009_03,  -- 契約明細
                       xclw_double_data_rec.contract_line_num, 
                       cv_tk_cff_00009_02,  -- リース会社
                       xclw_double_data_rec.lease_company
                      ),1,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_info
        );
        --エラーメッセージの出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00067     -- メッセージ：契約枝番重複エラー
                    ),1,5000)
        );
        lv_err_flag := cv_const_y;
        --エラー件数のカウント
        IF (lv_err_flag_3 = cv_const_n) THEN
          lv_err_flag_3 := cv_const_y;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
    END LOOP;
    CLOSE xclw_double_data_cur;
--
    -- ***************************************************
    -- 4.リース契約明細ワーク上の契約番号存在チェック
    -- ***************************************************
    OPEN xclw_exist_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xclw_exist_data_cur INTO xclw_exist_data_rec;
      EXIT WHEN xclw_exist_data_cur%NOTFOUND;
--
        --エラー対象レコードの出力
        lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                       cv_msg_cff_00147,    -- メッセージ：リース契約明細エラー対象
                       cv_tk_cff_00009_01,  -- 契約番号
                       xclw_exist_data_rec.contract_number, 
                       cv_tk_cff_00009_03,  -- 契約明細
                       xclw_exist_data_rec.contract_line_num, 
                       cv_tk_cff_00009_02,  -- リース会社
                       xclw_exist_data_rec.lease_company
                      ),1,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_info
        );
        --エラーメッセージの出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00068     -- メッセージ：契約枝番不整合エラー
                    ),1,5000)
        );
        lv_err_flag := cv_const_y;
        --エラー件数のカウント
        IF (lv_err_flag_4 = cv_const_n) THEN
          lv_err_flag_4 := cv_const_y;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
    END LOOP;
    CLOSE xclw_exist_data_cur;
--
    -- ***************************************************
    -- 5.１契約明細数チェック用
    -- ***************************************************
    OPEN xclw_line_num_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xclw_line_num_data_cur INTO xclw_line_num_data_rec;
      EXIT WHEN xclw_line_num_data_cur%NOTFOUND;
--
      --エラー対象レコードの出力
      lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00146,    -- メッセージ：リース契約エラー対象
                      cv_tk_cff_00009_01,  -- 契約番号
                      xclw_line_num_data_rec.contract_number, 
                      cv_tk_cff_00009_02,  -- リース会社
                      xclw_line_num_data_rec.lease_company
                     ),1,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_info
      );
      --エラーメッセージの出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                    cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                    cv_msg_cff_00150     -- メッセージ：契約明細件数エラー
                  ),1,5000)
      );
      lv_err_flag := cv_const_y;
      --エラー件数のカウント
      IF (lv_err_flag_5 = cv_const_n) THEN
        lv_err_flag_5 := cv_const_y;
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
    END LOOP;
    CLOSE xclw_line_num_data_cur;
--
    -- ***************************************************
    -- 6. 物件コードチェック用
    -- ***************************************************
    OPEN xclw_object_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xclw_object_data_cur INTO xclw_object_data_rec;
      EXIT WHEN xclw_object_data_cur%NOTFOUND;
--
      --エラーメッセージの出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                    cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                    cv_msg_cff_00145,    -- メッセージ：物件コード重複エラー
                    cv_tk_cff_00009_04,  -- 物件コード
                    xclw_object_data_rec.object_code
                  ),1,5000)
      );
      lv_err_flag := cv_const_y;
      --エラー件数のカウント
      IF (lv_err_flag_6 = cv_const_n) THEN
        lv_err_flag_6 := cv_const_y;
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
    END LOOP;
    -- 物件コードチェック用
    CLOSE xclw_object_data_cur;
--   
   --エラー存在時
   IF (lv_err_flag = cv_const_y) THEN
       ov_retcode := cv_status_error;
   END IF;
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
      IF (xchw_double_data_cur%ISOPEN) THEN
        CLOSE xchw_double_data_cur;
      END IF;
      IF (xchw_exist_data_cur%ISOPEN) THEN
        CLOSE xchw_exist_data_cur;
      END IF;
      IF (xclw_double_data_cur%ISOPEN) THEN
        CLOSE xclw_double_data_cur;
      END IF;
      IF (xclw_exist_data_cur%ISOPEN) THEN
        CLOSE xclw_exist_data_cur;
      END IF;
      IF (xclw_line_num_data_cur%ISOPEN) THEN
        CLOSE xclw_line_num_data_cur;
      END IF;
      IF (xclw_object_data_cur%ISOPEN) THEN
        CLOSE xclw_object_data_cur;
      END IF;
    --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_rept_adjust;
--  
 /**********************************************************************************
   * Procedure Name   : chk_cont_header 
   * Description      : 契約ワークチェック処理        (A-8)
   ***********************************************************************************/
  PROCEDURE chk_cont_header(
    in_file_id       IN  NUMBER            -- 1.ファイルID
   ,ov_err_flag      OUT NOCOPY VARCHAR2   -- 2.エラーフラグ  
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cont_header'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cv_lease_type_1        CONSTANT VARCHAR2(1) := '1'; -- ｢原契約｣
    cv_payment_type_0      CONSTANT VARCHAR2(1) := '0'; -- ｢月｣
    cv_payment_type_1      CONSTANT VARCHAR2(1) := '1'; -- ｢年｣
--
    cv_frequency_min_0     CONSTANT NUMBER(3)   := 1;
    cv_frequency_max_0     CONSTANT NUMBER(3)   := 600;
    cv_frequency_min_1     CONSTANT NUMBER(3)   := 1;
    cv_frequency_max_1     CONSTANT NUMBER(3)   := 50;
--
    cn_month               CONSTANT NUMBER(2)   := 12;
    cv_payment_frequency_3 CONSTANT NUMBER(3)   := 3;
    cv_re_lease_time       CONSTANT NUMBER(3)   := 0;
--
    --*** ローカル変数 ***
    lv_err_flag          VARCHAR2(1);      -- エラー存在フラグ
    lv_err_info          VARCHAR2(5000);   -- エラー対象情報
--
    lv_lease_type        xxcff_contract_headers.lease_type%TYPE;
    lv_lease_class       xxcff_contract_headers.lease_class%TYPE;
    lv_lease_company     xxcff_contract_headers.lease_company%TYPE;
    lv_payment_type      xxcff_contract_headers.payment_type%TYPE;
    ld_lease_end_date    xxcff_contract_headers.lease_end_date%TYPE;
    ld_last_end_date     xxcff_contract_headers.lease_end_date%TYPE;
    lv_tax_code          xxcff_contract_headers.tax_code%TYPE;
    lv_vdsh_flag         VARCHAR2(1);      -- 自販機shフラグ    
-- V1.12 2018/09/10 Added START
    lv_ret_dff4    fnd_lookup_values.attribute4%TYPE;   --  リース判定DFF4
    lv_ret_dff5    fnd_lookup_values.attribute5%TYPE;   --  リース判定DFF5
    lv_ret_dff6    fnd_lookup_values.attribute6%TYPE;   --  リース判定DFF6
    lv_ret_dff7    fnd_lookup_values.attribute7%TYPE;   --  リース判定DFF7
-- V1.12 2018/09/10 Added END
    lv_first_date        DATE;
    lv_second_date       DATE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース契約ワークカーソル定義
    CURSOR xchw_data_cur
    IS
      SELECT xchw.contract_number      AS contract_number
            ,xchw.lease_class          AS lease_class
            ,xchw.lease_type           AS lease_type
            ,xchw.lease_company        AS lease_company
            ,xchw.contract_date        AS contract_date
            ,xchw.payment_frequency    AS payment_frequency
            ,xchw.payment_type         AS payment_type 
            ,xchw.lease_start_date     AS lease_start_date
            ,xchw.first_payment_date   AS first_payment_date
            ,xchw.second_payment_date  AS second_payment_date
            ,xchw.tax_code             AS tax_code
      FROM  xxcff_cont_headers_work  xchw
      WHERE xchw.file_id             = in_file_id;
    -- *** ローカル・レコード ***
    xchw_data_rec xchw_data_cur%ROWTYPE;
--
    -- 契約番号チェック用
    CURSOR xch_cont_double_data_cur
    IS
      SELECT xch.contract_number
      FROM   xxcff_contract_headers  xch
      WHERE  xch.contract_number   = xchw_data_rec.contract_number
      AND    xch.lease_company     = xchw_data_rec.lease_company
      AND    xch.re_lease_times       = cv_re_lease_time;
    -- *** ローカル・レコード ***
    xch_cont_double_data_rec xch_cont_double_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    OPEN xchw_data_cur;
    LOOP
      FETCH xchw_data_cur INTO xchw_data_rec;
      EXIT WHEN xchw_data_cur%NOTFOUND;
      -- 処理件数のカウント
      gn_target_cnt := gn_target_cnt + 1;
      -- 初期化
      lv_err_flag := cv_const_n;
      
      -- エラー対象情報の編集
      lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,                  -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00146,                -- メッセージ：リース契約エラー対象
                      cv_tk_cff_00009_01,              -- 契約番号
                      xchw_data_rec.contract_number,   
                      cv_tk_cff_00009_02,              -- リース会社
                      xchw_data_rec.lease_company
                    ),1,5000);
--
      -- ***************************************************
      -- 1. 契約番号
      -- ***************************************************
      -- リース契約との存在チェック
      OPEN xch_cont_double_data_cur;
      FETCH xch_cont_double_data_cur INTO xch_cont_double_data_rec;
      IF (xch_cont_double_data_cur%FOUND) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00044     -- メッセージ：契約番号存在エラー
                    ),1,5000)
        );
      END IF;
      CLOSE xch_cont_double_data_cur;
--
      -- ***************************************************
      -- 2. リース区分
      -- ***************************************************
      BEGIN
        SELECT xltv.lease_type_code
        INTO   lv_lease_type 
        FROM   xxcff_lease_type_v   xltv
        WHERE  xltv.lease_type_code = xchw_data_rec.lease_type
        AND    xltv.enabled_flag    = cv_const_y
        AND  NVL( xltv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xltv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00013,    -- メッセージ：境界値エラー
                        cv_tk_cff_00013_01,  -- カラム論理名
                        cv_msg_cff_50042,    -- リース区分
                        cv_tk_cff_00013_02,  -- 境界値エラーの範囲(MIN)
                        xchw_data_rec.lease_type
                      ),1,5000)
          );
      END;
--
      -- ***************************************************
      -- 3. リース種別
      -- ***************************************************
      -- 1.存在チェック
      BEGIN
        SELECT xlcv.lease_class_code
              ,xlcv.vdsh_flag
        INTO   lv_lease_class
              ,lv_vdsh_flag
        FROM   xxcff_lease_class_v   xlcv
        WHERE  xlcv.lease_class_code = xchw_data_rec.lease_class
        AND    xlcv.enabled_flag     = cv_const_y
        AND  NVL( xlcv.start_date_active, TO_DATE(gr_init_rec.process_date,'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xlcv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00013,    -- メッセージ：境界値エラー
                        cv_tk_cff_00013_01,  -- カラム論理名
                        cv_msg_cff_50041,    -- リース種別
                        cv_tk_cff_00013_02,  -- 境界値エラーの範囲(MIN)
                        xchw_data_rec.lease_class
                      ),1,5000)
         );
      END;
      -- 2.自販機_SHは対象外
      IF (lv_vdsh_flag = cv_const_y) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00122     -- メッセージ：リース種別エラー
                   ),1,5000)
        );
      END IF;
 --
      -- ***************************************************
      -- 4. リース会社
      -- ***************************************************
      BEGIN
        SELECT xlcv.lease_company_code
        INTO   lv_lease_company
        FROM   xxcff_lease_company_v   xlcv
        WHERE  xlcv.lease_company_code = xchw_data_rec.lease_company
        AND    xlcv.enabled_flag       = cv_const_y
        AND  NVL( xlcv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xlcv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00013,    -- メッセージ：境界値エラー
                        cv_tk_cff_00013_01,  -- カラム論理名
                        cv_msg_cff_50043,    -- リース会社
                        cv_tk_cff_00013_02,  -- 境界値エラーの範囲(MIN)
                        xchw_data_rec.lease_company
                      ),1,5000)
          );
      END;
 --
      -- ***************************************************
      -- 5. 頻度
      -- ***************************************************
      -- 1.存在チェック
      BEGIN
        SELECT xptv.payment_type_code
        INTO   lv_payment_type
        FROM   xxcff_payment_type_v xptv
        WHERE  xptv.payment_type_code = xchw_data_rec.payment_type
        AND    xptv.enabled_flag      = cv_const_y
        AND  NVL( xptv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xptv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00013,    -- メッセージ：境界値エラー
                        cv_tk_cff_00013_01,  -- カラム論理名
                        cv_msg_cff_50048,    -- 頻度
                        cv_tk_cff_00013_02,  -- 境界値エラーの範囲(MIN)
                        xchw_data_rec.payment_type
                      ),1,5000)
          );
      END;
--
      -- ***************************************************
      -- 6. 支払回数
      -- ***************************************************
      -- 1.境界値チェック
      IF (xchw_data_rec.payment_type = cv_payment_type_0) THEN
        IF ((xchw_data_rec.payment_frequency < cv_frequency_min_0) OR
            (xchw_data_rec.payment_frequency > cv_frequency_max_0)) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,             -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00016,           -- メッセージ：支払回数境界値エラー
                        cv_tk_cff_00013_01,         -- カラム論理名
                        cv_msg_cff_50047,           -- 支払回数
                        cv_tk_cff_00016_01,         -- 境界値エラーの範囲(MIN)
                        cv_frequency_min_0,
                        cv_tk_cff_00016_02,         -- 境界値エラーの範囲(MAX)
                        cv_frequency_max_0  
                      ),1,5000)
          );
        END IF;
      ELSIF (xchw_data_rec.payment_type = cv_payment_type_1 ) THEN
        IF ((xchw_data_rec.payment_frequency < cv_frequency_min_1  ) OR
            (xchw_data_rec.payment_frequency > cv_frequency_max_1  )) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00016,    -- メッセージ：支払回数境界値エラー
                        cv_tk_cff_00016_01,  -- 境界値エラーの範囲(MIN)
                        cv_frequency_min_1  ,
                        cv_tk_cff_00016_02,  -- 境界値エラーの範囲(MAX)
                        cv_frequency_max_1  
                      ),1,5000)
          );
        END IF;
      END IF;
      -- 2.入力値チェック
-- V1.12 2018/09/10 Modified START
--      IF (xchw_data_rec.lease_type = cv_lease_type_1) THEN
--        IF (MOD(xchw_data_rec.payment_frequency,cn_month) <> 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--          END IF;
--          lv_err_flag := cv_const_y;
--          -- エラー内容の出力
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                        cv_msg_cff_00014,    -- メッセージ：支払回数入力値エラー
--                        cv_tk_cff_00013_01,  -- カラム論理名
--                        cv_msg_cff_50047,    -- 支払回数
--                        cv_tk_cff_00013_02,  -- 境界値エラーの範囲(MIN)
--                        cn_month
--                     ),1,5000)
--          );
--        END IF;
--      END IF;
      --  リース判定処理
      xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>    lv_lease_class
        ,ov_ret_dff4    =>    lv_ret_dff4           -- DFF4(日本基準連携)
        ,ov_ret_dff5    =>    lv_ret_dff5           -- DFF5(IFRS連携)
        ,ov_ret_dff6    =>    lv_ret_dff6           -- DFF6(仕訳作成)
        ,ov_ret_dff7    =>    lv_ret_dff7           -- DFF7(リース判定処理)
        ,ov_errbuf      =>    lv_errbuf
        ,ov_retcode     =>    lv_retcode
        ,ov_errmsg      =>    lv_errmsg
      );
      -- 共通関数エラーの場合
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                                                       cv_msg_cff_00094,    -- メッセージ：共通関数エラー
                                                       cv_tk_cff_00094_01,  -- 共通関数名
                                                       cv_msg_cff_50323  )  -- ファイルID
                                                      || cv_msg_part
                                                      || lv_errmsg          --共通関数内ｴﾗｰﾒｯｾｰｼﾞ
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --  原契約で、リース判定処理1の場合、支払回数は12の倍数でなければならない
      IF (xchw_data_rec.lease_type = cv_lease_type_1) THEN
        IF ( lv_ret_dff7 = cv_lease_cls_chk1 ) THEN
          IF (MOD(xchw_data_rec.payment_frequency,cn_month) <> 0) THEN
            IF (lv_err_flag = cv_const_n) THEN
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_err_info
              );
            END IF;
            lv_err_flag := cv_const_y;
            -- エラー内容の出力
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                          cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                          cv_msg_cff_00014,    -- メッセージ：支払回数入力値エラー
                          cv_tk_cff_00013_01,  -- カラム論理名
                          cv_msg_cff_50047,    -- 支払回数
                          cv_tk_cff_00013_02,  -- 境界値エラーの範囲(MIN)
                          cn_month
                       ),1,5000)
            );
          END IF;
        END IF;
      END IF;
-- V1.12 2018/09/10 Modified END
--
      -- ***************************************************
      -- 7. リース契約日
      -- ***************************************************
      IF (TO_CHAR(gr_init_rec.process_date,'YYYYMM') < TO_CHAR(xchw_data_rec.contract_date,'YYYYMM')) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00083     -- メッセージ：契約日妥当性エラー
                    ),1,5000)
        );
      END IF;
--
      -- ***************************************************
      -- 8. リース開始日
      -- ***************************************************
      IF (TO_CHAR(xchw_data_rec.lease_start_date,'YYYYMMDD') < TO_CHAR(xchw_data_rec.contract_date,'YYYYMMDD')) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00043     -- メッセージ：リース開始日妥当性エラー
                    ),1,5000)
        );
      END IF;
      -- ***************************************************
      -- 9. 初回支払日
      -- ***************************************************
      IF (TO_CHAR(xchw_data_rec.first_payment_date,'YYYYMMDD') < TO_CHAR(xchw_data_rec.lease_start_date,'YYYYMMDD')) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00022     -- メッセージ：初回支払日妥当性エラー
                    ),1,5000)
        );
      END IF;
      -- ***************************************************
      -- 10. ２回目支払日
      -- ***************************************************
      -- 1. ２回目支払日＜初回支払日
      IF (TO_CHAR(xchw_data_rec.second_payment_date,'YYYYMMDD') < TO_CHAR(xchw_data_rec.first_payment_date,'YYYYMMDD')) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00056     -- メッセージ：2回目支払日妥当性エラー（初回支払日前）
                    ),1,5000)
        );
      END IF;
      -- 2. ２回目支払日(年月)＜初回支払日
      IF (TO_CHAR(xchw_data_rec.second_payment_date,'YYYYMM') > 
        TO_CHAR(ADD_MONTHS(xchw_data_rec.first_payment_date,1),'YYYYMM')) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00055     -- メッセージ：2回目支払日妥当性エラー（初回支払日翌々月以降）
                    ),1,5000)
        );
      END IF;  
      -- (リース終了日)
      IF (xchw_data_rec.payment_type = cv_payment_type_0) THEN
        ld_lease_end_date := ADD_MONTHS(xchw_data_rec.lease_start_date,xchw_data_rec.payment_frequency) - 1;
      ELSIF (xchw_data_rec.payment_type = cv_payment_type_1 ) THEN
        ld_lease_end_date := ADD_MONTHS(xchw_data_rec.lease_start_date,xchw_data_rec.payment_frequency*12) -1;
      END IF;
--
      -- (最終支払日)
      --  支払回数が３回未満の場合は２回目支払日を設定する。
      IF (xchw_data_rec.payment_frequency < cv_payment_frequency_3) THEN
        ld_last_end_date  := xchw_data_rec.second_payment_date;
      ELSE
        -- 月末日以外の時
        IF (xchw_data_rec.second_payment_date) <> LAST_DAY(xchw_data_rec.second_payment_date) THEN
          IF (xchw_data_rec.payment_type = cv_payment_type_0) THEN
            ld_last_end_date  := ADD_MONTHS(xchw_data_rec.second_payment_date,xchw_data_rec.payment_frequency -2);
          ELSE
            ld_last_end_date  := ADD_MONTHS(xchw_data_rec.second_payment_date,(xchw_data_rec.payment_frequency-2)*12);
          END IF;
        -- 月末日の時
        ELSE
          IF (xchw_data_rec.payment_type = cv_payment_type_0) THEN
            ld_last_end_date  := LAST_DAY(ADD_MONTHS(xchw_data_rec.second_payment_date,xchw_data_rec.payment_frequency -2));
          ELSE 
            ld_last_end_date  := LAST_DAY(ADD_MONTHS(xchw_data_rec.second_payment_date,(xchw_data_rec.payment_frequency-2)*12));
          END IF;
        END IF;
      END IF;
--
--DEL 2009/11/27 START
/*
      IF (TO_CHAR(ld_lease_end_date,'YYYYMMDD') < TO_CHAR(ld_last_end_date,'YYYYMMDD')) THEN
        IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00031     -- メッセージ：支払日妥当性エラー
                    ),1,5000)
        );
      END IF; 
*/
--DEL 2009/11/27 END
--
      --***************************************************
      -- 12. 税金コード
      -- ***************************************************
      -- 1.存在チェック
      BEGIN
        SELECT atc.name
        INTO   lv_tax_code
        FROM   ap_tax_codes atc
        WHERE  atc.name = xchw_data_rec.tax_code
--[障害T1_1225] MOD START
--      AND    atc.enabled_flag  = cv_const_y;
        AND    atc.enabled_flag  = cv_const_y
        AND  NVL( atc.start_date, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date
        AND  NVL( atc.inactive_date, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date;
--[障害T1_1225] MOD END 
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00013,    -- メッセージ：境界値エラー
                        cv_tk_cff_00013_01,  -- カラム論理名
                        cv_msg_cff_50148,    -- 税金コード
                        cv_tk_cff_00013_02,  -- 境界値エラーの範囲(MIN)
                        xchw_data_rec.tax_code
                      ),1,5000)
         );
      END;
      --エラー存在時
      IF (lv_err_flag = cv_const_y) THEN
        ov_err_flag   := cv_const_y;
        -- 処理件数のカウント
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
    END LOOP;
--
    CLOSE xchw_data_cur;
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
      IF (xchw_data_cur%ISOPEN) THEN
        CLOSE xchw_data_cur;
      END IF;
      IF (xch_cont_double_data_cur%ISOPEN) THEN
        CLOSE xch_cont_double_data_cur;
      END IF;
    --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_cont_header;
--
 /**********************************************************************************
   * Procedure Name   : chk_cont_line
   * Description      : 契約明細ワークチェック処理        (A-9)
   ***********************************************************************************/
  PROCEDURE chk_cont_line(
    in_file_id       IN  NUMBER            -- 1.ファイルID
   ,ov_err_flag      OUT NOCOPY VARCHAR2   -- 2.エラーフラグ  
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cont_line'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cn_month             CONSTANT NUMBER(2)   := 12;
    cv_lease_type_1      CONSTANT VARCHAR2(1) := '1'; -- ｢原契約｣
--
    --*** ローカル変数 ***
    lv_err_flag          VARCHAR2(1);      -- エラー存在フラグ
    lv_err_info          VARCHAR2(5000);   -- エラー対象情報
--
    lv_objectcode        xxcff_object_headers.object_code%TYPE;
    ln_object_id         xxcff_contract_lines.object_header_id%TYPE;
    ln_contact_id        xxcff_contract_lines.contract_header_id%TYPE;
    ln_line_id           xxcff_contract_lines.contract_line_id%TYPE;
    ln_re_lease_times    xxcff_contract_headers.re_lease_times%TYPE;
    lv_lease_class       xxcff_contract_headers.lease_class%TYPE;
    lv_lease_type        xxcff_contract_headers.lease_type%TYPE;
    ln_payment_frequency xxcff_contract_headers.payment_frequency%TYPE;
    lv_category_code     xxcff_contract_lines.asset_category%TYPE;
    lv_live_month        VARCHAR2(2);
    ln_category_id       NUMBER(15);
-- 2018/03/27 Ver1.10 Otsuka ADD Start
    lv_ret_dff4    VARCHAR2(1);    -- リース判定DFF4
    lv_ret_dff5    VARCHAR2(1);    -- リース判定DFF5
    lv_ret_dff6    VARCHAR2(1);    -- リース判定DFF6
    lv_ret_dff7    VARCHAR2(1);    -- リース判定DFF7
-- 2018/03/27 Ver1.10 Otsuka ADD End
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース契約明細ワークカーソル定義
    CURSOR xclw_data_cur
    IS
      SELECT xclw.contract_number      AS contract_number
            ,xclw.contract_line_num    AS contract_line_num
            ,xclw.lease_company        AS lease_company
            ,xclw.object_code          AS object_code
            ,xclw.asset_category       AS asset_category
            ,xclw.first_charge         AS first_charge
            ,xclw.first_tax_charge     AS first_tax_charge
            ,xclw.second_charge        AS second_charge
            ,xclw.second_tax_charge    AS second_tax_charge
            ,xclw.first_deduction      AS first_deduction
            ,xclw.first_tax_deduction  AS first_tax_deduction
-- 2018/03/27 Ver1.10 Otsuka ADD Start
            ,xclw.estimated_cash_price AS estimated_cash_price
            ,xclw.life_in_months       AS life_in_months
-- 2018/03/27 Ver1.10 Otsuka ADD End
      FROM  xxcff_cont_lines_work  xclw
      WHERE xclw.file_id             = in_file_id;
    -- *** ローカル・レコード ***
    xclw_data_rec xclw_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    OPEN xclw_data_cur;
    LOOP
      FETCH xclw_data_cur INTO xclw_data_rec;
      EXIT WHEN xclw_data_cur%NOTFOUND;
      -- 処理件数のカウント
      gn_target_cnt := gn_target_cnt + 1;
      -- 初期化
      lv_err_flag := cv_const_n;
      -- エラー対象情報の編集
      lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,                  -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00009,                -- メッセージ：エラー対象
                      cv_tk_cff_00009_01,              -- 契約番号
                      xclw_data_rec.contract_number,
                      cv_tk_cff_00009_02,              -- リース会社
                      xclw_data_rec.lease_company,
                      cv_tk_cff_00009_03,              -- 契約枝番
                      xclw_data_rec.contract_line_num,
                      cv_tk_cff_00009_04,              -- 物件コード
                      xclw_data_rec.object_code
                    ),1,5000);
--
      -- ***************************************************
      -- 1. リース契約ワークの検索
      -- ***************************************************
      SELECT xchw.re_lease_times
            ,xchw.lease_class
            ,xchw.lease_type
            ,xchw.payment_frequency
      INTO   ln_re_lease_times
            ,lv_lease_class
            ,lv_lease_type
            ,ln_payment_frequency
      FROM   xxcff_cont_headers_work  xchw
      WHERE  xchw.contract_number     = xclw_data_rec.contract_number
      AND    xchw.lease_company       = xclw_data_rec.lease_company;
      -- ***************************************************
      -- 2. 物件コード
      -- ***************************************************
      -- 1.物件コードの存在チェック
      xxcff_common2_pkg.get_lease_key(
        iv_objectcode => xclw_data_rec.object_code  --   1.物件コード(必須)
       ,on_object_id  => ln_object_id               --   2.物件内部ＩＤ
       ,on_contact_id => ln_contact_id              --   3.契約内部ＩＤ
       ,on_line_id    => ln_line_id                 --   4.契約明細内部ＩＤ
       ,ov_retcode    => lv_retcode
       ,ov_errbuf     => lv_errbuf
       ,ov_errmsg     => lv_errmsg
      );
      --物件コードが登録済の時
      IF (ln_object_id  IS NOT NULL) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00160,    -- メッセージ：物件コード存在エラー
                      cv_tk_cff_00009_04,  -- トークン：物件コード
                      xclw_data_rec.object_code
                    ),1,5000)
        );
      END IF;
      -- ***************************************************
      -- 3. 資産種類
      -- ***************************************************
      -- 1.存在チェック
      BEGIN
        SELECT xcv.category_code
        INTO   lv_category_code
        FROM   xxcff_category_v xcv
        WHERE  xcv.category_code = xclw_data_rec.asset_category
        AND    xcv.enabled_flag  = cv_const_y
        AND  NVL( xcv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xcv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00069     -- メッセージ：資産種類マスタエラー
                      ),1,5000)
          );
      END;
      -- ***************************************************
      -- 4. 耐用年数
      -- ***************************************************
      IF (lv_lease_type = cv_lease_type_1) THEN
        -- 耐用年数を算出する。
-- V1.12 2018/09/10 Modified START
--        lv_live_month :=  round(ln_payment_frequency / cn_month);
        --  12で割り切れない場合は切上げ
        IF ( ( ln_payment_frequency / cn_month ) <> TRUNC( ln_payment_frequency / cn_month ) ) THEN
          lv_live_month :=  TO_CHAR( TRUNC( ln_payment_frequency / cn_month ) + 1 );
        ELSE
          lv_live_month :=  TO_CHAR( ln_payment_frequency / cn_month );
        END IF;
-- V1.12 2018/09/10 Modified END
        -- 耐用年数チェック
        xxcff_common1_pkg.chk_life(
          iv_category           => xclw_data_rec.asset_category --   1.資産種類
         ,iv_life               => lv_live_month                --   2.耐用年数
         ,ov_errbuf             => lv_errbuf
         ,ov_retcode            => lv_retcode
         ,ov_errmsg             => lv_errmsg
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00149     -- メッセージ：耐用年数エラー
                      ),1,5000)
          );
        END IF;
      END IF;
      -- ***************************************************
      -- 5. 資産カテゴリ
      -- ***************************************************
      IF (lv_lease_type = cv_lease_type_1) THEN
        -- 耐用年数を算出する。
-- V1.12 2018/09/10 Modified START
--        lv_live_month :=  round(ln_payment_frequency / cn_month);
        --  12で割り切れない場合は切上げ
        IF ( ( ln_payment_frequency / cn_month ) <> TRUNC( ln_payment_frequency / cn_month ) ) THEN
          lv_live_month :=  TO_CHAR( TRUNC( ln_payment_frequency / cn_month ) + 1 );
        ELSE
          lv_live_month :=  TO_CHAR( ln_payment_frequency / cn_month );
        END IF;
-- V1.12 2018/09/10 Modified END
        -- 資産カテゴリチェック
        xxcff_common1_pkg.chk_fa_category(
          iv_segment1    => xclw_data_rec.asset_category    -- 種類
         ,iv_segment2    => NULL                            -- 申告償却
         ,iv_segment3    => NULL                            -- 資産勘定
         ,iv_segment4    => NULL                            -- 償却科目
         ,iv_segment5    => lv_live_month                   -- 耐用年数
         ,iv_segment6    => NULL                            -- 償却方法
         ,iv_segment7    => lv_lease_class                  -- リース種別
         ,on_category_id => ln_category_id
         ,ov_errbuf      => lv_errbuf 
         ,ov_retcode     => lv_retcode
         ,ov_errmsg      => lv_errmsg
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
        END IF;
      END IF;
      -- ***************************************************
      -- 6. 月額リース料控除額
      -- ***************************************************
--
      --DEL 2010/01/07 START
      --IF ((xclw_data_rec.first_charge  <= xclw_data_rec.first_deduction) OR
      --    (xclw_data_rec.second_charge <= xclw_data_rec.first_deduction)) THEN
      --  IF (lv_err_flag = cv_const_n) THEN
      --    FND_FILE.PUT_LINE(
      --      which  => FND_FILE.OUTPUT
      --     ,buff   => lv_err_info
      --    );
      --    lv_err_flag := cv_const_y;
      --  END IF;
      --  -- エラー内容の出力
      --  FND_FILE.PUT_LINE(
      --    which  => FND_FILE.OUTPUT
      --   ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
      --                cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
      --                cv_msg_cff_00034     -- メッセージ：控除額エラー
      --              ),1,5000)
      --  );
      --END IF;
      --DEL 2010/01/07 START
--
-- 2018/05/25 Ver1.11 Mori DEL Start
--      -- ***************************************************
--      -- 7. 月額消費税額控除額
--      -- ***************************************************
--      IF ((xclw_data_rec.first_tax_charge  <= xclw_data_rec.first_tax_deduction) OR
--          (xclw_data_rec.second_tax_charge <= xclw_data_rec.first_tax_deduction)) THEN
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- エラー内容の出力
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
--                      cv_msg_cff_00034     -- メッセージ：控除額エラー
--                    ),1,5000)
--       );
--      END IF;
--      --エラー存在時
--      IF (lv_err_flag = cv_const_y) THEN
--        ov_err_flag   := cv_const_y;
--        -- 処理件数のカウント
--        gn_error_cnt := gn_error_cnt + 1;
--      END IF;
-- 
-- 2018/05/25 Ver1.11 Mori DEL End
-- 2018/03/27 Ver1.10 Otsuka ADD Start
      -- ***************************************************
      -- 8. 見積現金購入価額
      -- ***************************************************
      -- ***************************************
      -- ***        実処理の記述             ***
      -- ***       共通関数の呼び出し        ***
      -- ***************************************
      --  リース判定処理
      xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>    lv_lease_class
        ,ov_ret_dff4    =>    lv_ret_dff4           -- DFF4(日本基準連携)
        ,ov_ret_dff5    =>    lv_ret_dff5           -- DFF5(IFRS連携)
        ,ov_ret_dff6    =>    lv_ret_dff6           -- DFF6(仕訳作成)
        ,ov_ret_dff7    =>    lv_ret_dff7           -- DFF7(リース判定処理)
        ,ov_errbuf      =>    lv_errbuf
        ,ov_retcode     =>    lv_retcode
        ,ov_errmsg      =>    lv_errmsg
      );
      -- 共通関数エラーの場合
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                                                       cv_msg_cff_00094,    -- メッセージ：共通関数エラー
                                                       cv_tk_cff_00094_01,  -- 共通関数名
                                                       cv_msg_cff_50323  )  -- ファイルID
                                                      || cv_msg_part
                                                      || lv_errmsg          --共通関数内ｴﾗｰﾒｯｾｰｼﾞ
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      -- リース判別結果が「1」の場合
      IF (lv_ret_dff7 = cv_lease_cls_chk1) THEN
        -- 未入力および0の場合エラー
        IF ((xclw_data_rec.estimated_cash_price IS NULL) OR 
            (xclw_data_rec.estimated_cash_price = 0)) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00282     -- メッセージ：見積現金購入価額エラー
                      ),1,5000)
          );
        END IF;
      -- リース判別結果が「2」の場合、未入力データを0に置き換える
      ELSE
        IF (xclw_data_rec.estimated_cash_price IS NULL) THEN
          xclw_data_rec.estimated_cash_price := NVL(TO_NUMBER(xclw_data_rec.estimated_cash_price),0);
        END IF;
      END IF;
      -- ***************************************************
      -- 9. 法定耐用年数
      -- ***************************************************
      -- リース判別結果が「1」の場合
      IF (lv_ret_dff7 = cv_lease_cls_chk1) THEN
        -- 未入力および0の場合エラー
        IF ((xclw_data_rec.life_in_months IS NULL) OR
            (xclw_data_rec.life_in_months = 0)) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00283     -- メッセージ：法定耐用年数エラー
                      ),1,5000)
          );
        END IF;
      -- リース判別結果が「2」の場合、未入力データを0に置き換える
      ELSE
        IF (xclw_data_rec.life_in_months IS NULL) THEN
          xclw_data_rec.life_in_months := NVL(xclw_data_rec.life_in_months,0);
        END IF;
      END IF;
-- 2018/03/27 Ver1.10 Otsuka ADD End
--  V1.12 2018/09/10 Added START
      --  エラー存在時
      IF ( lv_err_flag = cv_const_y ) THEN
        -- エラーフラグ設定、エラー件数カウント
        ov_err_flag   :=  cv_const_y;
        gn_error_cnt  :=  gn_error_cnt + 1;
      END IF;
--  V1.12 2018/09/10 Added END
--
    END LOOP;
--
    CLOSE xclw_data_cur;
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
      IF (xclw_data_cur%ISOPEN) THEN
        CLOSE xclw_data_cur;
      END IF;
    --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_cont_line;
--
 /**********************************************************************************
   * Procedure Name   : chk_obj_header
   * Description      : 物件ワークチェック処理          (A-10)
   ***********************************************************************************/
  PROCEDURE chk_obj_header(
    in_file_id       IN  NUMBER            -- 1.ファイルID
   ,ov_err_flag      OUT NOCOPY VARCHAR2   -- 2.エラーフラグ  
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_obj_header'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cn_month             CONSTANT NUMBER(2)   := 12;
    cv_lease_type_1      CONSTANT VARCHAR2(1) := '1'; -- ｢原契約｣
--
    --*** ローカル変数 ***
    lv_err_flag          VARCHAR2(1);      -- エラー存在フラグ
    lv_err_info          VARCHAR2(5000);   -- エラー対象情報
--
    lv_live_month        VARCHAR2(2);
    lv_owner_company     xxcff_object_headers.owner_company%TYPE;
    lv_department_code   xxcff_object_headers.department_code%TYPE;
    lv_location_id       NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース物件ワークカーソル定義
    CURSOR xcow_data_cur
    IS
      SELECT xcow.contract_number      AS contract_number
            ,xcow.contract_line_num    AS contract_line_num
            ,xcow.lease_company        AS lease_company
            ,xcow.object_code          AS object_code
            ,xcow.po_number            AS po_number
            ,xcow.registration_number  AS registration_number
            ,xcow.age_type             AS age_type
            ,xcow.model                AS model
            ,xcow.serial_number        AS serial_number
            ,xcow.quantity             AS quantity
            ,xcow.manufacturer_name    AS manufacturer_name 
            ,xcow.department_code      AS department_code
            ,xcow.owner_company        AS owner_company
            ,xcow.chassis_number       AS chassis_number
      FROM  xxcff_cont_obj_work  xcow
      WHERE xcow.file_id             = in_file_id;
    -- *** ローカル・レコード ***
    xcow_data_rec xcow_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    OPEN xcow_data_cur;
    LOOP
      FETCH xcow_data_cur INTO xcow_data_rec;
      EXIT WHEN xcow_data_cur%NOTFOUND;
      -- 処理件数のカウント
      gn_target_cnt := gn_target_cnt + 1;
      -- 初期化
      lv_err_flag := cv_const_n;
      -- エラー対象情報の編集
      lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,                  -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00009,                -- メッセージ：エラー対象
                      cv_tk_cff_00009_01,              -- 契約番号
                      xcow_data_rec.contract_number,
                      cv_tk_cff_00009_02,              -- リース会社
                      xcow_data_rec.lease_company,
                      cv_tk_cff_00009_03,              -- 契約枝番
                      xcow_data_rec.contract_line_num,
                      cv_tk_cff_00009_04,              -- 物件コード
                      xcow_data_rec.object_code
                    ),1,5000);
--
      -- ***************************************************
      -- 1. 本社/工場
      -- ***************************************************
      -- 1.存在チェック
      BEGIN
        SELECT xocv.owner_company_code
        INTO   lv_owner_company
        FROM   xxcff_owner_company_v xocv
        WHERE  xocv.owner_company_code = xcow_data_rec.owner_company
        AND    xocv.enabled_flag  = cv_const_y
        AND  NVL( xocv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xocv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00124,    -- メッセージ：項目値妥当性チェックエラー
                        cv_tk_cff_00124_01,  -- カラム論理名
                        cv_msg_cff_50012,    -- 本社/工場
                        cv_tk_cff_00124_02,  -- カラム名
                        xcow_data_rec.owner_company
                      ),1,5000)
          );
      END;
      -- ***************************************************
      -- 2. 管理部門
      -- ***************************************************
      -- 1.存在チェック
      BEGIN
        SELECT xdv.department_code
        INTO   lv_department_code
        FROM   xxcff_department_v xdv
        WHERE  xdv.department_code = xcow_data_rec.department_code
        AND    xdv.enabled_flag  = cv_const_y
        AND  NVL( xdv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xdv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- エラー内容の出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                        cv_msg_cff_00124,    -- メッセージ：項目値妥当性チェックエラー
                        cv_tk_cff_00124_01,  -- カラム論理名
                        cv_msg_cff_50011,    -- 管理部門
                        cv_tk_cff_00124_02,  -- カラム名
                        xcow_data_rec.department_code
                      ),1,5000)
          );
      END;
      -- ***************************************************
      -- 3. 事業所マスタの組合わせチェック
      -- ***************************************************
      -- 事業所マスタチェック
      xxcff_common1_pkg.chk_fa_location(
        iv_segment1           => NULL                           -- 1.申告地
       ,iv_segment2           => xcow_data_rec.department_code  -- 2.資産種類
       ,iv_segment3           => NULL                           -- 3.事業所
       ,iv_segment4           => NULL                           -- 4.場所
       ,iv_segment5           => xcow_data_rec.owner_company    -- 5.工場/本社
       ,on_location_id        => lv_location_id                 -- 事業所ID
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- エラー内容の出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                      cv_msg_cff_00095,    -- メッセージ：共通関数エラー
                      cv_tk_cff_00095_01,  -- 共通関数名
                      lv_errmsg            -- lv_errmsg
                    ),1,5000)
        );
      END IF;
      --エラー存在時
      IF (lv_err_flag = cv_const_y) THEN
        ov_err_flag   := cv_const_y;
        -- 処理件数のカウント
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
-- 
    END LOOP;
--
    CLOSE xcow_data_cur;
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
      IF (xcow_data_cur%ISOPEN) THEN
        CLOSE xcow_data_cur;
      END IF;
    --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_obj_header;
 /**********************************************************************************
   * Procedure Name   : set_upload_item
   * Description      : アップロード項目編集     (A-13)
   ***********************************************************************************/
  PROCEDURE set_upload_item(
    ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ
   ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード
   ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_upload_item'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cv_payment_type_0       CONSTANT VARCHAR2(1) := '0';   --頻度：｢月｣
    cv_payment_type_1       CONSTANT VARCHAR2(1) := '1';   --頻度：｢年｣
--
    cn_last_payment_date    CONSTANT NUMBER(2)   :=  31; 
--
    cv_lease_type_1         CONSTANT VARCHAR2(1) := '1';   --リース区分：｢原契約｣
    cv_lease_type_2         CONSTANT VARCHAR2(1) := '2';   --リース区分：｢再リース｣
--
    cv_cont_status_201      CONSTANT VARCHAR2(3) := '201'; --契約ステータス：｢登録済｣
--
    cv_lease_payment_flag_1 CONSTANT VARCHAR2(1) := '1';   --支払完了フラグ：｢完了｣
--
    cv_re_lease_flag_0      CONSTANT VARCHAR2(1) := '0';   --再リース要
    cv_bond_accept_flag_0   CONSTANT VARCHAR2(1) := '0';   --証書受領フラグ「未受領」
--
    cv_object_status_101    CONSTANT VARCHAR2(3) := '101'; -- 101:未契約
    cv_object_status_102    CONSTANT VARCHAR2(3) := '102'; -- 102:契約済
    
    --*** ローカル変数 ***
    lv_err_flag             VARCHAR2(1);                   -- エラー存在フラグ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- ***************************************************
  -- 1. リース契約項目編集
  -- ***************************************************
    gr_cont_hed_rec.contract_header_id      := NULL;                                   -- 契約内部ID
    gr_cont_hed_rec.contract_number         := gr_contract_info_rec.contract_number;   -- 契約番号
    gr_cont_hed_rec.lease_class             := gr_contract_info_rec.lease_class;       -- リース種別
    gr_cont_hed_rec.lease_type              := gr_contract_info_rec.lease_type;        -- リース区分
    gr_cont_hed_rec.lease_company           := gr_contract_info_rec.lease_company;     -- リース会社
    gr_cont_hed_rec.re_lease_times          := gr_contract_info_rec.re_lease_times;    -- 再リース回数
    gr_cont_hed_rec.comments                := gr_contract_info_rec.comments;          -- 件名
    gr_cont_hed_rec.contract_date           := gr_contract_info_rec.contract_date;     -- リース契約日
    gr_cont_hed_rec.payment_frequency       := gr_contract_info_rec.payment_frequency; -- 支払回数
    gr_cont_hed_rec.payment_type            := gr_contract_info_rec.payment_type;      -- 頻度
  -- 年数
    IF (gr_contract_info_rec.payment_type = cv_payment_type_0) THEN
-- 2018/10/24 v1.13 Modified START
--      gr_cont_hed_rec.payment_years := ROUND(gr_contract_info_rec.payment_frequency/12);
      gr_cont_hed_rec.payment_years := CEIL(gr_contract_info_rec.payment_frequency/12);
-- 2018/10/24 v1.13 Modified END
    END IF;
  -- リース開始日
    gr_cont_hed_rec.lease_start_date        := gr_contract_info_rec.lease_start_date;
  -- リース終了日
    IF (gr_contract_info_rec.payment_type = cv_payment_type_0) THEN
        gr_cont_hed_rec.lease_end_date      :=
          ADD_MONTHS(gr_contract_info_rec.lease_start_date,gr_contract_info_rec.payment_frequency) - 1;
    ELSE
        gr_cont_hed_rec.lease_end_date      :=
          ADD_MONTHS(gr_contract_info_rec.lease_start_date,gr_contract_info_rec.payment_frequency * 12) - 1;
    END IF;
  -- 初回支払日
    gr_cont_hed_rec.first_payment_date      := gr_contract_info_rec.first_payment_date;
  -- ２回目支払日  
    gr_cont_hed_rec.second_payment_date     := gr_contract_info_rec.second_payment_date;
  -- 3回目支払日
    IF (gr_contract_info_rec.second_payment_date = LAST_DAY(gr_cont_hed_rec.second_payment_date)) THEN
      gr_cont_hed_rec.third_payment_date    := cn_last_payment_date;
    ELSE
      gr_cont_hed_rec.third_payment_date    := TO_CHAR(gr_contract_info_rec.second_payment_date,'DD');
    END IF;
  -- 費用計上会計会計期間
    gr_cont_hed_rec.start_period_name       := TO_CHAR(gr_contract_info_rec.first_payment_date,'YYYY-MM');
    gr_cont_hed_rec.lease_payment_flag      := cv_lease_payment_flag_1;                   -- 支払計画完了フラグ
-- 2013/07/05 Ver.1.8 T.Nakano MOD Start
--    gr_cont_hed_rec.tax_code                := gr_contract_info_rec.tax_code;             -- 税コード
    gr_cont_hed_rec.tax_code                := NULL;                                      -- 税金コード
-- 2013/07/05 Ver.1.8 T.Nakano MOD End
  -- WHOカラム
    gr_cont_hed_rec.created_by              := cn_created_by;                             -- 作成者
    gr_cont_hed_rec.creation_date           := cd_creation_date;                          -- 作成日
    gr_cont_hed_rec.last_updated_by         := cn_last_updated_by;                        -- 最終更新者
    gr_cont_hed_rec.last_update_date        := cd_last_update_date;                       -- 最終更新日
    gr_cont_hed_rec.last_update_login       := cn_last_update_login;                      -- 最終更新ﾛｸﾞｲﾝ
    gr_cont_hed_rec.request_id              := cn_request_id;                             -- 要求ID
    gr_cont_hed_rec.program_application_id  := cn_program_application_id;                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    gr_cont_hed_rec.program_id              := cn_program_id;                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    gr_cont_hed_rec.program_update_date     := cd_program_update_date;                    -- ﾌﾟﾛｸﾞﾗﾑ更新日
--
  -- ***************************************************
  -- 2. リース契約明細項目編集
  -- ***************************************************
    gr_cont_line_rec.contract_line_id       := NULL;                                      -- 契約内部ID
    gr_cont_line_rec.contract_header_id     := NULL;                                      -- 契約内部明細ID
    gr_cont_line_rec.contract_line_num      := gr_contract_info_rec.contract_line_num;    -- 契約枝番
-- 2013/07/05 Ver.1.8 T.Nakano ADD Start
    gr_cont_line_rec.tax_code               := gr_contract_info_rec.tax_code;             -- 税金コード
-- 2013/07/05 Ver.1.8 T.Nakano ADD End
  -- 契約ステータス
    gr_cont_line_rec.contract_status        := cv_cont_status_201;
  --
    gr_cont_line_rec.first_charge           := gr_contract_info_rec.first_charge;         -- 初回月額リース料_リース料
    gr_cont_line_rec.first_tax_charge       := gr_contract_info_rec.first_tax_charge;     -- 初回消費税額_リース料
    gr_cont_line_rec.first_total_charge     := 
      gr_cont_line_rec.first_charge  + gr_cont_line_rec.first_tax_charge;                 -- 初回計リース料
  --
    gr_cont_line_rec.second_charge          := gr_contract_info_rec.second_charge;        -- ２回目月額リース料_リース料
    gr_cont_line_rec.second_tax_charge      := gr_contract_info_rec.second_tax_charge;    -- ２回目消費税額_リース料
    gr_cont_line_rec.second_total_charge    := 
      gr_cont_line_rec.second_charge  + gr_cont_line_rec.second_tax_charge;               -- ２回目計リース料
  --
    gr_cont_line_rec.first_deduction        := gr_contract_info_rec.first_deduction;      -- 初回月額リース料_控除額
    gr_cont_line_rec.first_tax_deduction    := gr_contract_info_rec.first_tax_deduction;  -- 初回消費税額_控除額
    gr_cont_line_rec.first_total_deduction  := 
      gr_cont_line_rec.first_deduction  + gr_cont_line_rec.first_tax_deduction ;          -- 初回計控除額
  --
--
    --UPD 2010/01/07 START
    --gr_cont_line_rec.second_deduction       := gr_contract_info_rec.first_deduction;      -- ２回目以降月額リース料_控除額
    gr_cont_line_rec.second_deduction       := gr_contract_info_rec.second_deduction;       -- ２回目以降月額リース料_控除額
    --UPD 2010/01/07 END
--
    gr_cont_line_rec.second_tax_deduction   := gr_contract_info_rec.first_tax_deduction;  -- ２回目以降消費税額_控除額
    gr_cont_line_rec.second_total_deduction := 
      gr_cont_line_rec.second_deduction + gr_cont_line_rec.second_tax_deduction ;         -- ２回目以降計控除額
  -- 総額リース料_リース料
    gr_cont_line_rec.gross_charge           := gr_contract_info_rec.first_charge +
      (gr_contract_info_rec.second_charge * (gr_contract_info_rec.payment_frequency - 1));
  -- 総額消費税額_リース料
    gr_cont_line_rec.gross_tax_charge       := gr_contract_info_rec.first_tax_charge +
      (gr_contract_info_rec.second_tax_charge * (gr_contract_info_rec.payment_frequency - 1));
  -- 総額計_リース料
    gr_cont_line_rec.gross_total_charge     :=
      gr_cont_line_rec.gross_charge         + gr_cont_line_rec.gross_tax_charge;
  -- 総額リース料_控除額
    --UPD 2010/01/07 START
    --gr_cont_line_rec.gross_deduction        :=
    --  (gr_contract_info_rec.first_deduction * gr_contract_info_rec.payment_frequency);
    gr_cont_line_rec.gross_deduction        := gr_contract_info_rec.first_deduction +
      (gr_contract_info_rec.second_deduction * (gr_contract_info_rec.payment_frequency - 1));
    --UPD 2010/01/07 END
  -- 総額消費税_控除額
    gr_cont_line_rec.gross_tax_deduction    :=
      (gr_contract_info_rec.first_tax_deduction * gr_contract_info_rec.payment_frequency);
  -- 総額計_控除額
    gr_cont_line_rec.gross_total_deduction  :=
      gr_cont_line_rec.gross_deduction      + gr_cont_line_rec.gross_tax_deduction;
  -- 
    gr_cont_line_rec.estimated_cash_price   := gr_contract_info_rec.estimated_cash_price; -- 見積現金購入金額
    gr_cont_line_rec.life_in_months         := gr_contract_info_rec.life_in_months;       -- 法定耐用年数
  --  gr_cont_line_rec.object_header_id     := gr_contract_info_rec.object_header_id;     -- 物件内部id
    gr_cont_line_rec.asset_category         := gr_contract_info_rec.asset_category;       -- 資産種類
    gr_cont_line_rec.first_installation_address := gr_contract_info_rec.first_installation_address;   -- 初回設置場所
    gr_cont_line_rec.first_installation_place   := gr_contract_info_rec.first_installation_place;     -- 初回設置先
  -- WHOカラム
    gr_cont_line_rec.created_by             := cn_created_by;                             -- 作成者
    gr_cont_line_rec.creation_date          := cd_creation_date;                          -- 作成日
    gr_cont_line_rec.last_updated_by        := cn_last_updated_by;                        -- 最終更新者
    gr_cont_line_rec.last_update_date       := cd_last_update_date;                       -- 最終更新日
    gr_cont_line_rec.last_update_login      := cn_last_update_login;                      -- 最終更新ﾛｸﾞｲﾝ
    gr_cont_line_rec.request_id             := cn_request_id;                             -- 要求ID
    gr_cont_line_rec.program_application_id := cn_program_application_id;                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    gr_cont_line_rec.program_id             := cn_program_id;                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    gr_cont_line_rec.program_update_date    := cd_program_update_date;                    -- ﾌﾟﾛｸﾞﾗﾑ更新日
-- 
  -- ***************************************************
  -- 3. リース物件項目編集
  -- ***************************************************
    gr_object_data_rec.object_header_id     := NULL;                                      -- 物件内部ID
    gr_object_data_rec.object_code          := gr_contract_info_rec.object_code;          -- 物件コード
    gr_object_data_rec.lease_class          := gr_contract_info_rec.lease_class;          -- リース種別
    gr_object_data_rec.lease_type           := gr_contract_info_rec.lease_type;           -- リース区分
    gr_object_data_rec.re_lease_times       := gr_contract_info_rec.re_lease_times;       -- 再リース回数
    gr_object_data_rec.po_number            := gr_contract_info_rec.po_number;            -- 発注番号
    gr_object_data_rec.registration_number  := gr_contract_info_rec.registration_number;  -- 登録番号
    gr_object_data_rec.age_type             := gr_contract_info_rec.age_type;             -- 年式
    gr_object_data_rec.model                := gr_contract_info_rec.model;                -- 機種
    gr_object_data_rec.serial_number        := gr_contract_info_rec.serial_number;        -- 機番
-- T1_0783 2009/05/14 MOD START --
--  gr_object_data_rec.quantity             := gr_contract_info_rec.quantity;             -- 数量
    IF (gr_contract_info_rec.quantity IS NULL) THEN                                       -- 数量
      gr_object_data_rec.quantity           := 1;
    ELSE
      gr_object_data_rec.quantity           := gr_contract_info_rec.quantity;
    END IF;
-- T1_0783 2009/05/14 MOD END   --
    gr_object_data_rec.manufacturer_name    := gr_contract_info_rec.manufacturer_name;    -- メーカー名
    gr_object_data_rec.department_code      := gr_contract_info_rec.department_code;      -- 管理部門コード
    gr_object_data_rec.owner_company        := gr_contract_info_rec.owner_company;        -- 本社／工場
    gr_object_data_rec.chassis_number       := gr_contract_info_rec.chassis_number;       -- 車台番号
    gr_object_data_rec.re_lease_flag        := cv_re_lease_flag_0;                        -- 再リース要フラグ
    gr_object_data_rec.cancellation_type    := NULL;                                      -- 解約区分
    gr_object_data_rec.cancellation_date    := NULL;                                      -- 中途解約日
    gr_object_data_rec.dissolution_date     := NULL;                                      -- 中途解約キャンセル日
    gr_object_data_rec.bond_acceptance_flag := cv_bond_accept_flag_0;                     -- 証書受領フラグ
    gr_object_data_rec.bond_acceptance_Date := NULL;                                      -- 物件内部ID
    gr_object_data_rec.expiration_date      := NULL;                                      -- 物件内部ID
    gr_object_data_rec.object_status        := cv_object_status_102;                      -- 物件ステータス
    gr_object_data_rec.active_flag          := cv_const_y;                                -- 物件有効フラグ
    gr_object_data_rec.info_sys_if_date     := NULL;                                      -- リース管理情報連携日
    gr_object_data_rec.generation_date      := NULL;                                      -- 発生日
  -- WHOカラム
    gr_object_data_rec.created_by           := cn_created_by;                             -- 作成者
    gr_object_data_rec.creation_date        := cd_creation_date;                          -- 作成日
    gr_object_data_rec.last_updated_by      := cn_last_updated_by;                        -- 最終更新者
    gr_object_data_rec.last_update_date     := cd_last_update_date;                       -- 最終更新日
    gr_object_data_rec.last_update_login    := cn_last_update_login;                      -- 最終更新ﾛｸﾞｲﾝ
    gr_object_data_rec.request_id           := cn_request_id;                             -- 要求ID
    gr_object_data_rec.program_application_id := cn_program_application_id;               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    gr_object_data_rec.program_id           := cn_program_id;                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    gr_object_data_rec.program_update_date  := cd_program_update_date;                    -- ﾌﾟﾛｸﾞﾗﾑ更新日
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
--#####################################  固定部 END   ##########################################
--
  END set_upload_item;
--
 /**********************************************************************************
   * Procedure Name   : jdg_lease_kind
   * Description      : リース種類判定         (A-14)
   ***********************************************************************************/
  PROCEDURE jdg_lease_kind(
    ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ
   ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード
   ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'jdg_lease_kind'; -- プログラム名
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
--
    --*** ローカル定数 ***
--
    --*** ローカル変数 ***
    lv_contract_ym      DATE;
    lv_first_after_charge      xxcff_cont_lines_work.first_charge%TYPE;
    lv_second_after_charge     xxcff_cont_lines_work.second_charge%TYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- ***************************************************
  -- 1. リース種類判定
  -- ***************************************************
    lv_contract_ym   := TRUNC(gr_cont_hed_rec.contract_date,'mm');
    lv_first_after_charge  := 
      gr_cont_line_rec.first_charge  - gr_cont_line_rec.first_deduction;               -- 初回月額リース料(控除後)
    lv_second_after_charge := 
      gr_cont_line_rec.second_charge - gr_cont_line_rec.second_deduction;              -- ２回目月額リース料(控除後)
    -- 関数の呼び出し
    XXCFF003A03C.main(
      iv_lease_type                  => gr_cont_hed_rec.lease_type                     -- 1.リース区分
     ,in_payment_frequency           => gr_cont_hed_rec.payment_frequency              -- 2.支払回数
     ,in_first_charge                => lv_first_after_charge                          -- 3.初回月額リース料(控除後)
     ,in_second_charge               => lv_second_after_charge                         -- 4.２回目以降月額リース料（控除後）
     ,in_estimated_cash_price        => gr_cont_line_rec.estimated_cash_price          -- 5.見積現金購入価額
     ,in_life_in_months              => gr_cont_line_rec.life_in_months                -- 6.法定耐用年数
     ,id_contract_ym                 => lv_contract_ym                                 -- 7.契約年月
-- Ver.1.9 ADD Start
     ,iv_lease_class                 => gr_cont_hed_rec.lease_class                    -- 8.リース種別
-- Ver.1.9 ADD End
     ,ov_lease_kind                  => gr_cont_line_rec.lease_kind                    -- 9.リース種類
     ,on_present_value_discount_rate => gr_cont_line_rec.present_value_discount_rate   -- 10.現在価値割引率
     ,on_present_value               => gr_cont_line_rec.present_value                 -- 11.現在価値
     ,on_original_cost               => gr_cont_line_rec.original_cost                 -- 12.取得価額
     ,on_calc_interested_rate        => gr_cont_line_rec.calc_interested_rate          -- 13.計算利子率
-- Ver.1.9 ADD Start
     ,on_original_cost_type1         => gr_cont_line_rec.original_cost_type1           -- 14.リース負債額_原契約
     ,on_original_cost_type2         => gr_cont_line_rec.original_cost_type2           -- 15.リース負債額_再リース
-- Ver.1.9 ADD End
     ,ov_errbuf                      => lv_errbuf
     ,ov_retcode                     => lv_retcode
     ,ov_errmsg                      => lv_errmsg
    );
    -- エラー判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
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
--#####################################  固定部 END   ##########################################
--
  END jdg_lease_kind;
--
 /**********************************************************************************
   * Procedure Name   : ins_object_histories
   * Description      : リース物件履歴登録        (A-18)
   ***********************************************************************************/
  PROCEDURE ins_object_histories(
    in_object_header_id  IN  NUMBER            -- 物件内部ID
   ,ov_errbuf            OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode           OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg            OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_object_histories'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cv_object_status_101     CONSTANT VARCHAR2(3) := '101'; -- 101:未契約
    cv_object_status_102     CONSTANT VARCHAR2(3) := '102'; -- 102:契約済
--
    --*** ローカル変数 ***
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.リース物件履歴の登録をする(101：未契約)
    -- ***************************************************
    gr_object_data_rec.object_status         := cv_object_status_101;       -- 未契約
    gr_object_data_rec.active_flag           := cv_const_y;                 -- 物件有効フラグ
    -- 関数の呼び出し
    xxcff_common3_pkg.insert_ob_his(
      io_object_data_rec    => gr_object_data_rec  --リース物件情報
     ,ov_errbuf             => lv_errbuf
     ,ov_retcode            => lv_retcode
     ,ov_errmsg             => lv_errmsg
    );
    --エラーが存在する場合は強制終了
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ***************************************************
    -- 2.リース物件履歴の登録をする(102:契約済）
    -- ***************************************************
    gr_object_data_rec.object_status         := cv_object_status_102;       -- 契約済
    -- 関数の呼び出し
    xxcff_common3_pkg.insert_ob_his(
      io_object_data_rec    => gr_object_data_rec  --リース物件履歴情報
     ,ov_errbuf             => lv_errbuf
     ,ov_retcode            => lv_retcode
     ,ov_errmsg             => lv_errmsg
    );
    --エラーが存在する場合は強制終了
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
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
--#####################################  固定部 END   ##########################################
--
  END ins_object_histories;
-- 
 /**********************************************************************************
   * Procedure Name   : get_contract_info
   * Description      : リース契約ワーク抽出       (A-12)
   ***********************************************************************************/
  PROCEDURE get_contract_info(
    in_file_id       IN  NUMBER            -- 1.ファイルID
   ,ov_err_flag      OUT NOCOPY VARCHAR2   -- 2.エラーフラグ  
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_info'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cn_month             CONSTANT NUMBER(2)   := 12;
    cv_lease_type_1      CONSTANT VARCHAR2(1) := '1'; -- ｢原契約｣
    cv_shori_type_1      CONSTANT VARCHAR2(1) := '1'; -- ｢登録｣
--
    --*** ローカル変数 ***
    lv_err_flag          VARCHAR2(1);      -- エラー存在フラグ
    lv_err_info          VARCHAR2(5000);   -- エラー対象情報
--
    lv_contract_number   xxcff_cont_lines_work.contract_number%TYPE;
    lv_lease_company     xxcff_cont_lines_work.lease_company%TYPE;
    ln_cont_header_id    xxcff_contract_lines.contract_header_id%TYPE;
    ln_object_header_id  xxcff_object_headers.object_header_id%TYPE;
--
  --ADD 2010/01/07 START
    ln_second_deduction               NUMBER;
    ln_truncated_deduction            NUMBER;
    ln_total_fraction                 NUMBER;
    ln_first_deduction                NUMBER;
  --ADD 2010/01/07 END
--
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース契約ワークカーソル定義
    CURSOR contract_work_data_cur
    IS
      SELECT xchw.contract_number            AS contract_number
            ,xchw.lease_class                AS lease_class
            ,xchw.lease_type                 AS lease_type
            ,xchw.lease_company              AS lease_company
            ,xchw.re_lease_times             AS re_lease_times
            ,xchw.comments                   AS comments
            ,xchw.contract_date              AS contract_date
            ,xchw.payment_frequency          AS payment_frequency
            ,xchw.payment_type               AS payment_type 
            ,xchw.lease_start_date           AS lease_start_date
            ,xchw.first_payment_date         AS first_payment_date
            ,xchw.second_payment_date        AS second_payment_date
            ,xclw.contract_line_num          AS contract_line_num
            ,xclw.lease_company              AS lease_company_line
            ,xclw.first_charge               AS first_charge
            ,xclw.first_tax_charge           AS first_tax_charge
            ,xclw.second_charge              AS second_charge
            ,xclw.second_tax_charge          AS second_tax_charge
            ,xclw.first_deduction            AS first_deduction
            ,xclw.first_tax_deduction        AS first_tax_deduction
            --ADD 2010/01/07 STAR
            ,NULL                            AS second_deduction
            --ADD 2010/01/07 END
-- 2018/03/27 Ver1.10 Otsuka MOD Start
--            ,xclw.estimated_cash_price       AS estimated_cash_price
--            ,xclw.life_in_months             AS life_in_months
            ,NVL(TO_NUMBER(xclw.estimated_cash_price),0)
                                             AS estimated_cash_price
            ,NVL(TO_NUMBER(xclw.life_in_months),0)
                                             AS life_in_months
-- 2018/03/27 Ver1.10 Otsuka MOD End
            ,xclw.lease_kind                 AS lease_kind
            ,xclw.asset_category             AS asset_category
            ,xclw.first_installation_address AS first_installation_address
            ,xclw.first_installation_place   AS first_installation_place
            ,xclw.object_header_id           AS object_header_id
            ,xchw.tax_code                   AS tax_code
            ,xcow.object_code                AS object_code 
            ,xcow.po_number                  AS po_number
            ,xcow.registration_number        AS registration_number
            ,xcow.age_type                   AS age_type
            ,xcow.model                      AS model
            ,xcow.serial_number              AS serial_number
            ,xcow.quantity                   AS quantity
            ,xcow.manufacturer_name          AS manufacturer_name 
            ,xcow.department_code            AS department_code
            ,xcow.owner_company              AS owner_company
            ,xcow.chassis_number             AS chassis_number
      FROM   xxcff_cont_lines_work   xclw
            ,xxcff_cont_headers_work xchw
            ,xxcff_cont_obj_work     xcow
      WHERE  xchw.contract_number    = xclw.contract_number
      AND    xchw.lease_company      = xclw.lease_company
      AND    xclw.object_code        = xcow.object_code
      AND    xchw.file_id            = in_file_id
      AND    xclw.file_id            = in_file_id
      AND    xcow.file_id            = in_file_id
      ORDER BY
             xclw.contract_number
            ,xclw.lease_company
            ,xclw.contract_line_num;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    OPEN contract_work_data_cur;
    LOOP
      FETCH contract_work_data_cur INTO gr_contract_info_rec;
      EXIT WHEN contract_work_data_cur%NOTFOUND;
--
      gn_target_cnt := gn_target_cnt + 1;
--
  --ADD 2010/01/07 START
  -- ***************************************************
  --  維持管理費相当額の月額金額を計算
  --  初回月額リース料控除額、2回目以降月額リース料控除額に金額設定
  --  端数調整は 初回月額リース料控除額 で実施
  -- ***************************************************
--
      -- 金額算出ロジック
--
      -- 維持管理費用相当額の月額の金額を算出(円未満の端数切捨て)
      -- 2回目以降月額リース料控除額
      ln_second_deduction := trunc(gr_contract_info_rec.first_deduction / gr_contract_info_rec.payment_frequency);
      -- 2回目以降月額リース料控除額と支払回数より維持管理費用相当額（端数切捨て）を算出
      ln_truncated_deduction := ln_second_deduction * gr_contract_info_rec.payment_frequency;
      -- 維持管理費用相当額と維持管理費用相当額（端数切捨て）より端数の総額を算出
      ln_total_fraction := gr_contract_info_rec.first_deduction - ln_truncated_deduction;
      -- 端数の総額を初回月額リース料控除額で調整する
      ln_first_deduction := ln_second_deduction + ln_total_fraction;
--
      -- 金額設定
--
      -- 初回月額リース料控除額
      gr_contract_info_rec.first_deduction := ln_first_deduction;
      -- 2回目以降月額リース料控除額
      gr_contract_info_rec.second_deduction := ln_second_deduction;
--
  --ADD 2010/01/07 END
--
  -- ***************************************************
  -- 1. アップロード項目編集                      (A-13)
  -- ***************************************************
      --関数の呼び出し
      set_upload_item(
        ov_retcode       => lv_retcode
       ,ov_errbuf        => lv_errbuf
       ,ov_errmsg        => lv_errmsg
      );
      --エラーが存在する場合は強制終了
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
  -- ***************************************************
  -- 2. リース種類判定                            (A-14)
  -- ***************************************************
      --関数の呼び出し
      jdg_lease_kind(
        ov_retcode    => lv_retcode
       ,ov_errbuf     => lv_errbuf
       ,ov_errmsg     => lv_errmsg
      );
      --エラーが存在する場合は強制終了
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
--
  -- ***************************************************
  -- 3. リース物件新規登録                        (A-15)
  -- ***************************************************
      xxcff_common3_pkg.insert_ob_hed(
        io_object_data_rec    => gr_object_data_rec --リース物件
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
      --物件内部IDを退避する。
      ln_object_header_id  := gr_object_data_rec.object_header_id;
      --エラーが存在する場合は強制終了
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
--
  -- ***************************************************
  -- 4. リース契約新規登録                        (A-16)
  -- ***************************************************
      --契約番号、リース会社が異なる場合
      IF ((lv_contract_number IS NULL) OR
          (lv_lease_company   IS NULL) OR
          (lv_contract_number <> gr_contract_info_rec.contract_number) OR
          (lv_lease_company   <> gr_contract_info_rec.lease_company)) THEN
      --ブレークキーを退避する。
        lv_contract_number := gr_contract_info_rec.contract_number;
        lv_lease_company   := gr_contract_info_rec.lease_company;
      --関数の呼び出し
        xxcff_common4_pkg.insert_co_hed(
          io_contract_data_rec  => gr_cont_hed_rec  --リース契約情報
         ,ov_errbuf             => lv_errbuf
         ,ov_retcode            => lv_retcode
         ,ov_errmsg             => lv_errmsg
        );
        --契約IDを退避する。
        ln_cont_header_id  := gr_cont_hed_rec.contract_header_id;
      END IF;
      --エラーが存在する場合は強制終了
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
  -- ***************************************************
  -- 5. リース契約明細新規登録                    (A-17)
  -- ***************************************************
      -- 契約内部IDをリース契約明細に設定する。
      gr_cont_line_rec.contract_header_id := ln_cont_header_id;
      -- 物件内部IDをリース契約明細に設定する。
      gr_cont_line_rec.object_header_id   := ln_object_header_id;
      -- リース契約明細新規登録(A-15)
      xxcff_common4_pkg.insert_co_lin(
        io_contract_data_rec  => gr_cont_line_rec  --リース契約明細情報
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
      --エラーが存在する場合は強制終了
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
--
  -- ***************************************************
  -- 6. リース物件履歴登録                        (A-18)
  -- ***************************************************
      ins_object_histories(
        in_object_header_id   => gr_contract_info_rec.object_header_id
       ,ov_retcode            => lv_retcode
       ,ov_errbuf             => lv_errbuf
       ,ov_errmsg             => lv_errmsg
      );
      --エラーが存在する場合は強制終了
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
--
  -- ***************************************************
  -- 7. リース支払計画作成                        (A-19)
  -- ***************************************************
      xxcff003a05c.main(
        iv_shori_type         => cv_shori_type_1                    -- 1.処理区分
       ,in_contract_line_id   => gr_cont_line_rec.contract_line_id  -- 2.契約明細内部ID
       ,ov_retcode            => lv_retcode
       ,ov_errbuf             => lv_errbuf
       ,ov_errmsg             => lv_errmsg
      );
      --エラーが存在する場合は強制終了
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
      --正常件数のカウント
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP;
--
    CLOSE contract_work_data_cur;
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
      IF (contract_work_data_cur%ISOPEN) THEN
        CLOSE contract_work_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_contract_info;
--
  /**********************************************************************************
   * Procedure Name   : submain_main
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain_main(
    in_file_id           IN  NUMBER,              --   ファイルID
    in_file_upload_code  IN  NUMBER,              --   アップロードコード
    ov_errbuf            OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain_main'; -- プログラム名
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
    cv_data_type_1  CONSTANT VARCHAR2(1) := '1'; -- ｢契約｣
    cv_data_type_2  CONSTANT VARCHAR2(1) := '2'; -- ｢契約明細｣
--
    -- *** ローカル変数 ***
    lr_init_rtype   xxcff_common1_pkg.init_rtype;  -- 初期処理取得結果格納用
    lv_all_err_flag VARCHAR2(1);                   -- エラー存在フラグ
    ln_reccnt       NUMBER(10);                    -- ループ処理カウンタ
    lv_err_flag     VARCHAR2(1);                   -- エラー存在フラグ
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
--
    gn_seqno      := 0;
    gn_seqno_line := 0;
    gn_seqno_obj  := 0;
--
    -- ローカル変数の初期化
    lv_all_err_flag := cv_const_n;

    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ==================================
    -- 初期処理                     (A-1)
    -- ==================================
    init(
      in_file_id,          -- 1.ファイルID
      in_file_upload_code, -- 2.ファイルアップロードコード
      lv_errbuf,           -- エラー・メッセージ           --# 固定 #
      lv_retcode,          -- リターン・コード             --# 固定 #
      lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
      --エラーが存在する場合は強制終了
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================
    -- ファイルアップロードI/F取得  (A-2)
    -- ==================================
    get_if_data(
       in_file_id => in_file_id       -- 1.ファイルID
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
      --エラーが存在する場合は強制終了
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --配列に格納されているCSV行を1行づつ取得する
    FOR ln_reccnt IN gr_file_data_tbl.first..gr_file_data_tbl.last LOOP
      --gn_target_cnt := gn_target_cnt + 1;   --処理件数カウント
      -- ==================================
      -- デリミタ文字項目分割         (A-3)
      -- ==================================
      devide_item(
         in_file_data  => gr_file_data_tbl(ln_reccnt)  -- 1.ファイルデータ
        ,ov_retcode    => lv_retcode
        ,ov_errbuf     => lv_errbuf
        ,ov_errmsg     => lv_errmsg
      );
      -- ==================================
      -- 配列項目チェック処理         (A-4)
      -- ==================================
      IF  ((gr_lord_data_tab(1) = cv_data_type_1)
       OR  (gr_lord_data_tab(1) = cv_data_type_2)) THEN
        -- 処理件数のカウント
        gn_target_cnt := gn_target_cnt + 1;
        -- 
        chk_err_disposion(
           ov_retcode    => lv_retcode
          ,ov_errbuf     => lv_errbuf
          ,ov_errmsg     => lv_errmsg
        );
      -- ==================================
      -- アップロード振分処理         (A-5)
      -- ==================================
        --エラーが存在しない場合のみワークテーブルに登録
        IF (lv_retcode <> cv_status_error) THEN
          ins_cont_work (
            in_file_id    => in_file_id       -- 1.ファイルID
           ,ov_retcode    => lv_retcode
           ,ov_errbuf     => lv_errbuf
           ,ov_errmsg     => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        ELSE
          lv_all_err_flag := cv_const_y;
          -- 処理件数のカウント
          gn_error_cnt := gn_error_cnt + 1;
        END IF;  
      END IF;
    END LOOP;
--
    -- ==================================
    -- エラー判定処理               (A-6)
    -- ==================================
    --１件でもエラーが存在する場合は強制終了
    IF (lv_all_err_flag = cv_const_y) THEN
      -- スキップ件数
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
      RAISE global_process_expt;
    END IF;
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- ==================================
    -- ﾜｰｸﾌｧｲﾙ重複・整合性ﾁｪｯｸ処理  (A-7)
    -- ==================================
    chk_rept_adjust(
      in_file_id    => in_file_id       -- 1.ファイルID
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --１件でもエラーが存在する場合は強制終了
    IF (lv_retcode = cv_status_error) THEN
      -- スキップ件数
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
      RAISE global_process_expt;
    END IF;
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- ==================================
    -- 契約ワークチェック処理       (A-8)
    -- ==================================
    chk_cont_header(
      in_file_id    => in_file_id       -- 1.ファイルID
     ,ov_err_flag   => lv_err_flag      -- 2.エラーフラグ
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --
    IF (lv_err_flag =  cv_const_y) THEN
      lv_all_err_flag := cv_const_y;
    END IF;
--
    -- ==================================
    -- 契約明細ワークチェック処理   (A-9)
    -- ==================================
    chk_cont_line(
      in_file_id    => in_file_id       -- 1.ファイルID
     ,ov_err_flag   => lv_err_flag      -- 2.エラーフラグ
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --
    IF (lv_err_flag =  cv_const_y) THEN
      lv_all_err_flag := cv_const_y;
    END IF;
--
    -- ==================================
    -- 物件ワークチェック処理   (A-10)
    -- ==================================
    chk_obj_header(
      in_file_id    => in_file_id       -- 1.ファイルID
     ,ov_err_flag   => lv_err_flag      -- 2.エラーフラグ
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --
    IF (lv_err_flag =  cv_const_y) THEN
      lv_all_err_flag := cv_const_y;
    END IF;
--
    -- ==================================
    -- エラー判定処理               (A-11)
    -- ==================================
    --１件でもエラーが存在する場合は強制終了
    IF (lv_all_err_flag = cv_const_y) THEN
      -- スキップ件数
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
      RAISE global_process_expt;
    END IF;
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- ==================================
    -- リース契約ワーク抽出        (A-12)
    -- ==================================
    get_contract_info(
      in_file_id    => in_file_id       -- 1.ファイルID
     ,ov_err_flag   => lv_err_flag      -- 2.エラーフラグ
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --１件でもエラーが存在する場合は強制終了
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_process_expt;
    END IF;
 --
  EXCEPTION
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
  END submain_main;
--  
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id           IN  NUMBER,              --   ファイルID
    in_file_upload_code  IN  NUMBER,              --   アップロードコード
    ov_errbuf            OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- ===============================================
    -- submain_mainの呼び出し（実際の処理はsubmain_mainで行う）
    -- ===============================================
    submain_main(
       in_file_id             -- 1.ファイルID
      ,in_file_upload_code    -- 2.アップロードコード
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ==================================
    -- 終了処理                    (A-19)
    -- ==================================
    IF (lv_retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      -- リース契約ワーク削除
      DELETE
      FROM  xxcff_cont_headers_work
      WHERE file_id = in_file_id;
      -- リース契約明細ワーク削除
      DELETE
      FROM  xxcff_cont_lines_work
      WHERE file_id = in_file_id;
      -- リース物件ワーク削除
      DELETE
      FROM  xxcff_cont_obj_work
      WHERE file_id = in_file_id;
    END IF;
    -- ファイルアップロードIFテーブル削除
    DELETE
    FROM  xxccp_mrp_file_ul_interface
    WHERE file_id = in_file_id;
    --異常終了の場合ファイルアップロードIFテーブル削除のためにCOMMIT実行
    IF (lv_retcode = cv_status_error) THEN
      COMMIT;
      RAISE global_process_expt;
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
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
     errbuf                 OUT NOCOPY VARCHAR2  -- エラー・メッセージ  --# 固定 #
   , retcode                OUT NOCOPY VARCHAR2  -- リターン・コード    --# 固定 #
   , in_file_id             IN  NUMBER             -- 1.ファイルID
   , in_file_upload_code    IN  NUMBER             -- 2.ファイルアップロードコード
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
       in_file_id             -- 1.ファイルID
      ,in_file_upload_code    -- 2.ファイルアップロードコード
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
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
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
    FND_FILE.PUT_LINE(
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
END XXCFF003A07C;
/