CREATE OR REPLACE PACKAGE BODY XXCOP001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP001A01C(body)
 * Description      : アップロードファイルからの登録（基準計画）
 * MD.050           : アップロードファイルからの登録（基準計画） MD050_COP_001_A01
 * Version          : ver1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  output_disp            メッセージ出力
 *  check_validate_item    項目属性チェック
 *  init                   初期処理                            (A-1)
 *  get_file_info          関連データ取得                       (A-2)
 *  get_upload_data        ファイルアップロードI/Fテーブルデータ抽出(A-3)
 *  chk_upload_data        妥当性チェック                       (A-4)
 *  insert_data            データ登録                           (A-6)
 *  delete_data            ファイルアップロードI/Fテーブルデータ削除(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/21    1.0  SCS.Uchida       新規作成
 *  2009/04/03    1.1  SCS.Goto         T1_0237、T1_0270対応
 *  2009/08/21    1.2  SCS.Moriyama     0001134対応
 *
 *****************************************************************************************/
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  -- ユーザー定義グローバル定数
  -- ===============================
  --システム設定
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCOP001A01C'; -- パッケージ名
  gv_debug_mode                VARCHAR2(10)  := NULL;           -- デバッグモード：ON/OFF
  --起動ユーザー
  gn_user_id          CONSTANT NUMBER        := fnd_global.user_id;
  --メッセージ設定
  gv_xxcop            CONSTANT VARCHAR2(100) := 'XXCOP';              -- アプリケーション短縮名
  gv_m_e_get_who      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00001';   -- WHOカラム取得失敗
  gv_m_e_get_pro      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';   -- プロファイル値取得失敗
  gv_m_e_no_data      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';   -- 対象データなし
  gv_m_e_Param        CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00005';   -- パラメータエラーメッセージ
  gv_m_e_lock         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';   -- テーブルロックエラーメッセージ
  gv_m_e_not_exist    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00017';   -- マスタ未登録エラーメッセージ
  gv_m_e_chk_err      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00018';   -- 不正チェックエラーメッセージ
  gv_m_e_set_err      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00019';   -- 禁止項目設定エラー
  gv_m_e_nchk         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00020';   -- NUMBER型チェックエラー
  gv_m_e_dchk         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00021';   -- DATE型チェックエラー
  gv_m_e_schk         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00022';   -- サイズチェックエラー
  gv_m_e_input        CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00023';   -- 必須入力エラーメッセージ
  gv_m_e_fchk         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00024';   -- フォーマットチェックエラーメッセージ
  gv_m_e_insert_err   CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';   -- 登録処理エラーメッセージ
  gv_m_e_get_f_info   CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00032';   -- アップロードIF情報取得エラーメッセージ
  gv_m_n_fname        CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00033';   -- ファイル名出力メッセージ
  gv_m_e_fopen        CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00034';   -- ファイルオープン処理失敗
  gv_m_e_public       CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00035';   -- 標準API/Oracleエラーメッセージ
  gv_m_n_up_f_info    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00036';   -- アップロードファイル出力メッセージ
  gv_m_e_1rec_chk     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00040';   -- 一意性チェックエラーメッセージ
  gv_m_e_user_chk     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10006';   -- 起動ユーザーチェックエラーメッセージ
  gv_m_e_conc_call    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10012';   -- コンカレント発行エラー
  gv_m_e_set_err_t    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10030';   -- 基準計画分類不正エラーメッセージ
  gv_m_n_skip_rec     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10033';   -- 基準計画確定日以前データスキップメッセージ
  gv_m_e_unmatch      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10034';   -- 基準計画名未登録エラー
  gv_m_e_calendar_err CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10037';   -- 稼働日チェックエラー
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
  gv_m_e_prod_err     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10044';   -- 製造/購入品フラグ不正チェックエラー
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
  --トークン設定
  gv_t_prof_name      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  gv_t_parameter      CONSTANT VARCHAR2(100) := 'PARAMETER';
  gv_t_value          CONSTANT VARCHAR2(100) := 'VALUE';
  gv_t_value1         CONSTANT VARCHAR2(100) := 'VALUE1';
  gv_t_table          CONSTANT VARCHAR2(100) := 'TABLE';
  gv_t_column         CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_t_row_num        CONSTANT VARCHAR2(100) := 'ROW';
  gv_t_file           CONSTANT VARCHAR2(100) := 'FILE';
  gv_t_item           CONSTANT VARCHAR2(100) := 'ITEM';
  gv_t_fileid         CONSTANT VARCHAR2(100) := 'FILEID';
  gv_t_format         CONSTANT VARCHAR2(100) := 'FORMAT';
  gv_t_file_name      CONSTANT VARCHAR2(100) := 'FILE_NAME';
  gv_t_file_id        CONSTANT VARCHAR2(100) := 'FILE_ID';
  gv_t_format_ptn     CONSTANT VARCHAR2(100) := 'FORMAT_PTN';
  gv_t_upload_obj     CONSTANT VARCHAR2(100) := 'UPLOAD_OBJECT';
  gv_t_data           CONSTANT VARCHAR2(100) := 'DATA';
  gv_t_schedule_name  CONSTANT VARCHAR2(100) := 'SCHEDULE_NAME';
  gv_t_org_code       CONSTANT VARCHAR2(100) := 'ORG_CODE';
  gv_t_date           CONSTANT VARCHAR2(100) := 'DATE';
  gv_t_date1          CONSTANT VARCHAR2(100) := 'DATE1';
  gv_t_date2          CONSTANT VARCHAR2(100) := 'DATE2';
  gv_t_syori          CONSTANT VARCHAR2(100) := 'SYORI';
  gv_msg_comma        CONSTANT VARCHAR2(100) := ',';                  -- 項目区切り
  --テーブル名
  gv_table_name_item  CONSTANT VARCHAR2(100) := 'Disc品目マスタ';
  gv_table_name_org   CONSTANT VARCHAR2(100) := '組織パラメータ';
  gv_table_name_ift   CONSTANT VARCHAR2(100) := '基準計画IF表';
--20090403_Ver1.1_T1_0270_SCS.Goto_ADD_START
  gv_table_name_opm   CONSTANT VARCHAR2(100) := 'OPM品目マスタ';
--20090403_Ver1.1_T1_0270_SCS.Goto_ADD_END
  --プロファイル名
  gv_p_base_date      CONSTANT VARCHAR2(100) := 'XXCOP1_SCHEDULE_BASELINE' ;  -- 確定日基準日数
  --フォーマットパターン
  gv_format_mds_o     CONSTANT VARCHAR2(100) := '201';                -- 基準計画（出荷予測MDS）
  gv_format_mps_o     CONSTANT VARCHAR2(100) := '202';                -- 基準計画（工場出荷計画MPS）
  gv_format_mps_i     CONSTANT VARCHAR2(100) := '203';                -- 基準計画（購入計画MPS）
  --メッセージ出力
  gv_blank            CONSTANT VARCHAR2(5)   := 'BLANK';              -- 空白行
  --ファイルアップロードI/Fテーブル
  gv_delim            CONSTANT VARCHAR2(1)   := ',';                  -- デリミタ文字
--20090821_Ver1.2_0001134_SCS.Moriyama_MOD_START
--  gn_column_num       CONSTANT NUMBER        := 10;                   -- 項目数
  gn_column_num       CONSTANT NUMBER        := 13;                   -- 項目数
--20090821_Ver1.2_0001134_SCS.Moriyama_MOD_END
  gn_header_row_num   CONSTANT NUMBER        := 1;                    -- ヘッダー行数
  --項目の日本語名称
  gv_column_name_01   CONSTANT VARCHAR2(100) := 'MDS/MPS名';
  gv_column_name_02   CONSTANT VARCHAR2(100) := 'MDS/MPS摘要';
  gv_column_name_03   CONSTANT VARCHAR2(100) := '組織コード';
  gv_column_name_04   CONSTANT VARCHAR2(100) := '基準計画分類';
  gv_column_name_05   CONSTANT VARCHAR2(100) := '品目コード';
  gv_column_name_06   CONSTANT VARCHAR2(100) := '計画日付';
  gv_column_name_07   CONSTANT VARCHAR2(100) := '計画数量';
  gv_column_name_08   CONSTANT VARCHAR2(100) := '出荷元倉庫コード';
  gv_column_name_09   CONSTANT VARCHAR2(100) := '出荷日';
  gv_column_name_10   CONSTANT VARCHAR2(100) := '計画商品フラグ';
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
  gv_column_name_11   CONSTANT VARCHAR2(100) := '生産予定日';
  gv_column_name_12   CONSTANT VARCHAR2(100) := '製造/購入品フラグ';
  gv_column_name_13   CONSTANT VARCHAR2(100) := 'アップロード日付';
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
  --項目のサイズ
  gv_column_len_01    CONSTANT NUMBER := 10;                          -- MDS/MPS名
  gv_column_len_02    CONSTANT NUMBER := 50;                          -- MDS/MPS摘要
  gv_column_len_03    CONSTANT NUMBER := 3;                           -- 組織コード
  gv_column_len_04    CONSTANT NUMBER := 1;                           -- 基準計画分類
  gv_column_len_05    CONSTANT NUMBER := 7;                           -- 品目コード
  gv_column_len_07    CONSTANT NUMBER := 8;                           -- 計画数量
  gv_column_len_08    CONSTANT NUMBER := 3;                           -- 出荷元倉庫コード
  gv_column_len_10    CONSTANT NUMBER := 1;                           -- 計画商品フラグ
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
  gv_column_len_12    CONSTANT NUMBER := 1;                           -- 製造/購入品フラグ
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
  --必須判定
  gv_must_item        CONSTANT VARCHAR2(4) := 'MUST';                 -- 必須項目
  gv_null_item        CONSTANT VARCHAR2(4) := 'NULL';                 -- NULL項目
  gv_any_item         CONSTANT VARCHAR2(4) := 'ANY';                  -- 任意項目
  --日付型フォーマット
  gv_ymd_format       CONSTANT VARCHAR2(8)   := 'YYYYMMDD';           -- 年月日
  gv_ymd_out_format   CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';         -- 年月日（出力用）
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
  gn_product_flg      CONSTANT NUMBER := 1;                           -- 製造/購入品フラグ:製造品
  gn_purchase_flg     CONSTANT NUMBER := 2;                           -- 製造/購入品フラグ:購入品
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
  --基準計画レコード型
  TYPE xm_schedule_if_rtype IS RECORD (
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_START
--    schedule_designator     xxcop.xxcop_mrp_schedule_interface.schedule_designator%TYPE
--  , schedule_description    xxcop.xxcop_mrp_schedule_interface.schedule_description%TYPE
--  , organization_code       xxcop.xxcop_mrp_schedule_interface.organization_code%TYPE
--  , schedule_type           xxcop.xxcop_mrp_schedule_interface.schedule_type%TYPE
--  , item_code               xxcop.xxcop_mrp_schedule_interface.item_code%TYPE
--  , schedule_date           xxcop.xxcop_mrp_schedule_interface.schedule_date%TYPE
--  , schedule_quantity       xxcop.xxcop_mrp_schedule_interface.schedule_quantity%TYPE
--  , deliver_from            xxcop.xxcop_mrp_schedule_interface.deliver_from%TYPE
--  , shipment_date           xxcop.xxcop_mrp_schedule_interface.shipment_date%TYPE
--  , schedule_prod_flg       xxcop.xxcop_mrp_schedule_interface.schedule_prod_flg%TYPE
    schedule_designator     xxcop_mrp_schedule_interface.schedule_designator%TYPE
  , schedule_description    xxcop_mrp_schedule_interface.schedule_description%TYPE
  , organization_code       xxcop_mrp_schedule_interface.organization_code%TYPE
  , schedule_type           xxcop_mrp_schedule_interface.schedule_type%TYPE
  , item_code               xxcop_mrp_schedule_interface.item_code%TYPE
  , schedule_date           xxcop_mrp_schedule_interface.schedule_date%TYPE
  , schedule_quantity       xxcop_mrp_schedule_interface.schedule_quantity%TYPE
  , deliver_from            xxcop_mrp_schedule_interface.deliver_from%TYPE
  , shipment_date           xxcop_mrp_schedule_interface.shipment_date%TYPE
  , schedule_prod_flg       xxcop_mrp_schedule_interface.schedule_prod_flg%TYPE
  , num_of_cases            NUMBER
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
  , schedule_prod_date      xxcop_mrp_schedule_interface.schedule_prod_date%TYPE
  , prod_purchase_flg       xxcop_mrp_schedule_interface.prod_purchase_flg%TYPE
  , upload_date             DATE
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_END
  );
  --基準計画コレクション型
  TYPE xm_schedule_if_ttype IS TABLE OF xm_schedule_if_rtype
    INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : output_disp
   * Description      : メッセージ出力
   ***********************************************************************************/
  PROCEDURE output_disp(
    iv_errmsg     IN OUT VARCHAR2,     -- 1.レポート出力メッセージ
    iv_errbuf     IN OUT VARCHAR2      -- 2.ログ出力メッセージ
  )
  IS
  BEGIN
      --レポート出力
      IF ( iv_errmsg IS NOT NULL ) THEN
        IF ( iv_errmsg = gv_blank ) THEN
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff => NULL
          );
        ELSE
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff => iv_errmsg
          );
        END IF;
      END IF;
      --ログ出力
      IF ( iv_errbuf IS NOT NULL ) THEN
        IF ( iv_errbuf = gv_blank ) THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff => NULL
          );
        ELSE
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff => iv_errbuf
          );
        END IF;
      END IF;
      --出力メッセージのクリア
      iv_errmsg := NULL;
      iv_errbuf := NULL;
  END output_disp;
--
--
  /**********************************************************************************
   * Procedure Name   : check_validate_item
   * Description      : 項目属性チェック
   ***********************************************************************************/
  PROCEDURE check_validate_item(
    iv_item_name  IN  VARCHAR2,     -- 1.項目名（日本語）
    iv_item_value IN  VARCHAR2,     -- 2.項目値
    iv_null       IN  VARCHAR2,     -- 3.必須チェック
    iv_number     IN  VARCHAR2,     -- 4.NUMBER型チェック
    iv_date       IN  VARCHAR2,     -- 5.DATE型チェック
    in_item_size  IN  NUMBER,       -- 6.項目サイズ（BYTE）
    in_row_num    IN  NUMBER,       -- 7.行
    iv_file_data  IN  VARCHAR2,     -- 8.取得レコード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_validate_item'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --必須チェック
    IF ( iv_null = gv_must_item ) THEN
      IF( iv_item_value IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_input
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    ELSIF ( iv_null = gv_null_item ) THEN
      IF ( iv_item_value IS NOT NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_set_err
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    ELSE
      NULL;
    END IF;
    --NUMBER型チェック
    IF ( ( iv_number IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( xxcop_common_pkg.chk_number_format( iv_item_value ) = FALSE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_nchk
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --DATE型チェック
    IF ( ( iv_date IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( xxcop_common_pkg.chk_date_format( iv_item_value,iv_date ) = FALSE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_dchk
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --サイズチェック
    IF ( ( in_item_size IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( LENGTHB(iv_item_value) > in_item_size ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_schk
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --基準計画分類存在チェック
    
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_validate_item;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    iv_format       IN  VARCHAR2,   --   フォーマットパターン
    od_base_date    OUT DATE,       --   確定日
    ov_errbuf       OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_quick_type     CONSTANT VARCHAR2(100) := 'XXCOP1_SCHEDULE_TYPE';   -- タイプ
    cv_quick_lang     CONSTANT VARCHAR2(100) := USERENV('LANG');          -- 言語
    cv_quick_enable   CONSTANT VARCHAR2(1)   := 'Y';                      -- 有効フラグ
    cd_sysdate        CONSTANT DATE          := TRUNC(SYSDATE);           -- システム日付（年月日）
    -- *** ローカル変数 ***
    lv_quick_code     fnd_lookup_values.lookup_code%TYPE;                 -- クイックコード
    lv_add_base_date  VARCHAR2(100);                                      -- 確定日基準日数
    lv_err_flg        VARCHAR2(1);                                        -- エラー判定
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    lv_err_flg := gv_status_normal;
    --
    --1.フォーマットチェック
    BEGIN
      SELECT flv.lookup_code
      INTO   lv_quick_code
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type   = cv_quick_type
      AND    flv.language      = cv_quick_lang
      AND    flv.description   = iv_format
      AND    flv.enabled_flag  = cv_quick_enable
      AND    cd_sysdate BETWEEN NVL(flv.start_date_active,cd_sysdate)
                            AND NVL(flv.end_date_active  ,cd_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_Param
                       ,iv_token_name1  => gv_t_parameter
                       ,iv_token_value1 => '入力パラメータ'
                       ,iv_token_name2  => gv_t_value
                       ,iv_token_value2 => iv_format
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    --2.確定日基準日数の取得・チェック
    --lv_add_base_date := FND_PROFILE.VALUE(gv_p_base_date);
    FND_PROFILE.GET(gv_p_base_date,lv_add_base_date);
    --★デバッグログ（開発用）
    xxcop_common_pkg.put_debug_message('★確定日基準日数 ： ' || lv_add_base_date,gv_debug_mode);
    --
    --エラー判定
    IF ( lv_add_base_date IS NULL ) THEN
      lv_err_flg := gv_status_error;
    ELSE
      IF ( xxcop_common_pkg.chk_number_format( lv_add_base_date ) = FALSE ) THEN
        lv_err_flg := gv_status_error;
      ELSE
        od_base_date := cd_sysdate + lv_add_base_date;
        --★デバッグログ（開発用）
        xxcop_common_pkg.put_debug_message('★確定日 ： ' || od_base_date,gv_debug_mode);
        --
      END IF;
    END IF;
    --
    IF ( lv_err_flg = gv_status_error ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_pro
                     ,iv_token_name1  => gv_t_prof_name
                     ,iv_token_value1 => '確定日基準日数'
                   );
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END init;
--
--  
  /**********************************************************************************
   * Procedure Name   : get_file_info
   * Description      : 関連データ取得(A-2)
   ***********************************************************************************/
--
  PROCEDURE get_file_info(
    in_file_id          IN  NUMBER,                                     -- FILE_ID
    iv_format           IN  VARCHAR2,                                   -- フォーマットパターン
    ov_file_name        OUT xxccp_mrp_file_ul_interface.file_name%TYPE, -- ファイル名
    ov_errbuf           OUT VARCHAR2,                                   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,                                   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)                                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_upload_name       fnd_lookup_values.meaning%TYPE;                  -- ファイルアップロード名称
    lv_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;      -- ファイル名
    ld_upload_date       xxccp_mrp_file_ul_interface.creation_date%TYPE;  -- アップロード日時
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --ファイルアップロードI/Fテーブルの情報取得
    xxcop_common_pkg.get_upload_table_info(
       in_file_id      => in_file_id      -- ファイルID
      ,iv_format       => iv_format       -- フォーマットパターン
      ,ov_upload_name  => lv_upload_name  -- ファイルアップロード名称
      ,ov_file_name    => lv_file_name    -- ファイル名
      ,od_upload_date  => ld_upload_date  -- アップロード日時
      ,ov_retcode      => lv_retcode      -- リターンコード
      ,ov_errbuf       => lv_errbuf       -- エラーバッファ
      ,ov_errmsg       => lv_errmsg       -- ユーザー・エラー・メッセージ
    );
    --
    --アップロード情報出力
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_xxcop
                   ,iv_name         => gv_m_n_up_f_info
                   ,iv_token_name1  => gv_t_file_id
                   ,iv_token_value1 => TO_CHAR(in_file_id)
                   ,iv_token_name2  => gv_t_format_ptn
                   ,iv_token_value2 => iv_format
                   ,iv_token_name3  => gv_t_upload_obj
                   ,iv_token_value3 => lv_upload_name
                   ,iv_token_name4  => gv_t_file_name
                   ,iv_token_value4 => lv_file_name
                 );
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errmsg
    );
    --
    --空白行を挿入
    lv_errmsg := gv_blank;
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errmsg
    );
    --
    --ファイルアップロードI/Fテーブルの情報取得に失敗した場合
    IF ( lv_retcode <> gv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_f_info
                     ,iv_token_name1  => gv_t_fileid
                     ,iv_token_value1 => TO_CHAR(in_file_id)
                     ,iv_token_name2  => gv_t_format
                     ,iv_token_value2 => iv_format
                   );
      RAISE global_api_expt;
    END IF;
    --
    --ファイル名セット
    ov_file_name := lv_file_name;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END get_file_info;
--
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードI/Fテーブルデータ抽出(A-3)
   ***********************************************************************************/
--
  PROCEDURE get_upload_data(
    in_file_id    IN  NUMBER,                              -- FILE_ID
    o_fuid_tab    OUT xxccp_common_pkg2.g_file_data_tbl,   -- ファイルアップロードI/Fデータ(VARCHAR2型)
    ov_errbuf     OUT VARCHAR2,                            -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                            -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)                            -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --1.ファイルデータ取得(BLOBデータ変換)
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id         -- ファイルID
      ,ov_file_data => o_fuid_tab         -- ファイルアップロードI/Fデータ(VARCHAR2型)
      ,ov_errbuf    => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --データ件数の確認
    IF ( o_fuid_tab.COUNT <= gn_header_row_num ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_no_data
                   );
      RAISE global_process_expt;
    END IF;
    --対象件数＝CSVレコード数－ヘッダー行数でセット
    gn_target_cnt := o_fuid_tab.COUNT - gn_header_row_num;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END get_upload_data;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_upload_data
   * Description      : 妥当性チェック(A-4)
   ***********************************************************************************/
--
  PROCEDURE chk_upload_data(
    iv_format     IN  VARCHAR2,                           -- フォーマットパターン
    i_fuid_tab    IN  xxccp_common_pkg2.g_file_data_tbl,  -- ファイルアップロードI/Fデータ(VARCHAR2型)
    --★↓2009/01/23 追加
    id_base_date  IN  DATE,                               -- 確定日
    --★↑2009/01/23 追加
    o_scdl_tab    OUT xm_schedule_if_ttype,               -- 基準計画データ
    ov_errbuf     OUT VARCHAR2,                           -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                           -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_upload_data'; -- プログラム名
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
    cv_quick_type     CONSTANT VARCHAR2(100) := 'XXCOP1_SCHEDULE_TYPE';          -- タイプ
    cv_prod_type      CONSTANT VARCHAR2(100) := 'XXCOP1_PROD_PURCHASE_FLG';      -- タイプ
    cv_quick_lang     CONSTANT VARCHAR2(100) := USERENV('LANG');                 -- 言語
    cv_quick_enable   CONSTANT VARCHAR2(1)   := 'Y';                             -- 有効フラグ
    cd_quick_sysdate  CONSTANT DATE          := TRUNC(SYSDATE);                  -- システム日付（年月日）
    cd_sysdate        CONSTANT DATE          := TRUNC(SYSDATE);                  -- システム日付（年月日）    
    -- *** ローカル変数 ***
    l_csv_tab         xxcop_common_pkg.g_char_ttype;                             -- UPLOADファイルの項目分割後データを格納
    lv_invalid_flag   VARCHAR2(1);                                               -- エラーレコードフラグ
    ln_srd_idx        NUMBER;                                                    -- 実レコードNO
    ln_quick_rec_cnt  NUMBER;                                                    -- クイックコード件数
    ln_user_rec_cnt   NUMBER;                                                    -- ユーザー件数
    l_item_id         mtl_system_items_b.inventory_item_id%TYPE;                 -- 品目ID
    l_org_id          mtl_parameters.organization_id%TYPE;                       -- 組織ID
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_START
--    l_org_code        xxcop.xxcop_mrp_schedule_interface.organization_code%TYPE; -- 組織コード
    l_org_code        xxcop_mrp_schedule_interface.organization_code%TYPE;       -- 組織コード
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_END
    lv_case_flg       VARCHAR2(4);                                               -- 条件付必須項目判別用
    l_date_flg        bom_calendar_dates.seq_num%TYPE;                           -- 稼働日フラグ（非稼働日はNULL）
    lv_one_chk_flg    VARCHAR2(1);                                               -- 一意性キーチェックフラグ
    lv_token_col_name VARCHAR2(100);                                             -- 一意性キーチェックフラグ
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --ファイルアップロードI/Fテーブルの情報取得
    <<row_loop>>
    FOR ln_row_idx IN ( i_fuid_tab.FIRST + gn_header_row_num ) .. i_fuid_tab.COUNT LOOP
      --
      --ループ内で使用する変数の初期化
      lv_invalid_flag                             := gv_status_normal;
      ln_srd_idx                                  := ln_row_idx - gn_header_row_num;
      o_scdl_tab(ln_srd_idx).schedule_designator  := '';
      o_scdl_tab(ln_srd_idx).schedule_description := '';
      o_scdl_tab(ln_srd_idx).organization_code    := '';
      o_scdl_tab(ln_srd_idx).schedule_type        := '';
      o_scdl_tab(ln_srd_idx).item_code            := '';
      o_scdl_tab(ln_srd_idx).schedule_date        := '';
      o_scdl_tab(ln_srd_idx).schedule_quantity    := '';
      o_scdl_tab(ln_srd_idx).deliver_from         := '';
      o_scdl_tab(ln_srd_idx).shipment_date        := '';
      o_scdl_tab(ln_srd_idx).schedule_prod_flg    := '';
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
      o_scdl_tab(ln_srd_idx).schedule_prod_date   := '';
      o_scdl_tab(ln_srd_idx).prod_purchase_flg    := '';
      o_scdl_tab(ln_srd_idx).upload_date          := '';
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
      --
      --CSV文字分割
      xxcop_common_pkg.char_delim_partition(
         iv_char      => i_fuid_tab(ln_row_idx)  -- 対象文字列
        ,iv_delim     => gv_delim                -- デリミタ
        ,o_char_tab   => l_csv_tab               -- 分割結果
        ,ov_retcode   => lv_retcode              -- リターンコード
        ,ov_errbuf    => lv_errbuf               -- エラー・メッセージ
        ,ov_errmsg    => lv_errmsg               -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
      -- ===============================
      -- 1.項目数チェック
      -- ===============================
      IF ( l_csv_tab.COUNT = gn_column_num ) THEN
        -- ===============================
        -- ■項目属性チェック
        --   2.必須チェック
        --   3.NUMBER型チェック
        --   4.DATE型チェック
        --   5.サイズチェック
        -- ===============================
        -- 
        -- -------------------------------
        -- ● FLD1 : MDS/MPS名
        --     必須　  ： ○
        --     タイプ  : 文字
        --     サイズ  : 10byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_01
          ,iv_item_value  => l_csv_tab(1)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_01
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_designator := SUBSTRB(l_csv_tab(1),1,gv_column_len_01);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD2 : MDS/MPS摘要
        --     必須　  ： ○
        --     タイプ  : 文字
        --     サイズ  : 50byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_02
          ,iv_item_value  => l_csv_tab(2)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_02
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_description := SUBSTRB(l_csv_tab(2),1,gv_column_len_02);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ★2008/12/25 追加
        -- ● FLD3 : 組織コード
        --     必須　  ： ○
        --     タイプ  : 文字
        --     サイズ  : 3byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_03
          ,iv_item_value  => l_csv_tab(3)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_03
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).organization_code := SUBSTRB(l_csv_tab(3),1,gv_column_len_03);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD4 : 基準計画分類
        --     必須　  ： ○
        --     タイプ  : 数字
        --     サイズ  : 1byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_04
          ,iv_item_value  => l_csv_tab(4)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_04
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_type := TO_NUMBER(l_csv_tab(4));
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD5 : 品目コード
        --     必須　  ： ○
        --     タイプ  : 文字
        --     サイズ  : 7byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_05
          ,iv_item_value  => l_csv_tab(5)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_05
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).item_code := SUBSTRB(l_csv_tab(5),1,gv_column_len_05);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD6 : 計画日付
        --     必須　  ： ○
        --     タイプ  : 日付
        --     サイズ  :  -
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_06
          ,iv_item_value  => l_csv_tab(6)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_date := TO_DATE(l_csv_tab(6),gv_ymd_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD7 : 計画数量
        --     必須　  ： ○
        --     タイプ  : 数量
        --     サイズ  :  -
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_07
          ,iv_item_value  => l_csv_tab(7)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_07
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_quantity := TO_NUMBER(l_csv_tab(7));
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD8 : 出荷元倉庫コード
        --     必須　  ： 
        --     タイプ  : 文字
        --     サイズ  : 3byte
        -- -------------------------------
        --条件付必須判別
        IF ( iv_format = gv_format_mps_o ) THEN
          lv_case_flg := gv_must_item;
        ELSE
          lv_case_flg := gv_any_item;
        END IF;
        --
        check_validate_item(
           iv_item_name   => gv_column_name_08
          ,iv_item_value  => l_csv_tab(8)
          ,iv_null        => lv_case_flg          --条件付必須フラグをセット
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_08
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).deliver_from := SUBSTRB(l_csv_tab(8),1,gv_column_len_08);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD9 : 出荷日
        --     必須　  ： 
        --     タイプ  : 日付
        --     サイズ  :  -
        -- -------------------------------
        --条件付必須判別
        IF ( iv_format = gv_format_mps_o ) THEN
          lv_case_flg := gv_must_item;
        ELSE
          lv_case_flg := gv_any_item;
        END IF;
        --
        check_validate_item(
           iv_item_name   => gv_column_name_09
          ,iv_item_value  => l_csv_tab(9)
          ,iv_null        => lv_case_flg
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).shipment_date := TO_DATE(l_csv_tab(9),gv_ymd_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD10: 計画商品フラグ
        --     必須　  ： 
        --     タイプ  : 数字
        --     サイズ  : 1byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_10
          ,iv_item_value  => l_csv_tab(10)
          ,iv_null        => gv_any_item
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_10
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_prod_flg := TO_NUMBER(l_csv_tab(10));
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
        --
        -- -------------------------------
        -- ● FLD11 : 生産予定日
        --     必須　  ： 
        --     タイプ  : 日付
        --     サイズ  :  -
        -- -------------------------------
        --条件付必須判別
        IF ( iv_format = gv_format_mds_o ) THEN
          lv_case_flg := gv_null_item;
        ELSE
          lv_case_flg := gv_any_item;
        END IF;
        --
        check_validate_item(
           iv_item_name   => gv_column_name_11
          ,iv_item_value  => l_csv_tab(11)
          ,iv_null        => lv_case_flg
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_prod_date := TO_DATE(l_csv_tab(11),gv_ymd_out_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ● FLD12: 製造/購入品フラグ
        --     必須　  ： 
        --     タイプ  : 数字
        --     サイズ  : 1byte
        -- -------------------------------
        --条件付必須判別
        IF ( iv_format = gv_format_mps_i ) THEN
          lv_case_flg := gv_must_item;
        ELSE
          lv_case_flg := gv_null_item;
        END IF;
        --
        check_validate_item(
           iv_item_name   => gv_column_name_12
          ,iv_item_value  => l_csv_tab(12)
          ,iv_null        => lv_case_flg
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_12
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).prod_purchase_flg := TO_NUMBER(l_csv_tab(12));
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
--
        -- ===============================
        -- 5.製造品/購入品存在チェック
        -- ===============================
        IF (iv_format = gv_format_mps_i
           AND o_scdl_tab(ln_srd_idx).prod_purchase_flg IS NOT NULL)
        THEN
          SELECT count(flv.enabled_flag)
          INTO   ln_quick_rec_cnt
          FROM   fnd_lookup_values flv
          WHERE  flv.lookup_type   = cv_prod_type
          AND    flv.language      = cv_quick_lang
          AND    flv.lookup_code   = o_scdl_tab(ln_srd_idx).prod_purchase_flg
          AND    flv.enabled_flag  = cv_quick_enable
          AND    cd_quick_sysdate BETWEEN NVL(flv.start_date_active,cd_quick_sysdate)
                                      AND NVL(flv.end_date_active  ,cd_quick_sysdate)
          ;
          IF ( ln_quick_rec_cnt = 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_prod_err
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_item
                           ,iv_token_value2 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          END IF;
        END IF;
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '行目' || ':1-fld10:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 6.組織コード存在チェック
        -- ===============================
        BEGIN
          SELECT mp.organization_code
          INTO   l_org_code
          FROM   mtl_parameters                 mp                                -- 組織パラメータ
          WHERE  mp.organization_code = o_scdl_tab(ln_srd_idx).organization_code  -- CSVファイルの「組織コード」
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_not_exist
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_column
                           ,iv_token_value2 => gv_column_name_03
                           ,iv_token_name3  => gv_t_value1
                           ,iv_token_value3 => l_csv_tab(3)
                           ,iv_token_name4  => gv_t_table
                           ,iv_token_value4 => gv_table_name_org
                           ,iv_token_name5  => gv_t_item
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          WHEN TOO_MANY_ROWS THEN
            null;
        END;
        --
        --l_org_code := '';
        --
        -- =================================
        -- 7.組織コード・基準計画名整合性チェック
        -- =================================
        BEGIN
          SELECT mp.organization_code                               -- 組織コード
          INTO   l_org_code
          FROM   mtl_parameters                 mp                  -- 組織パラメータ
                ,mrp_schedule_designators       msd                 -- 基準計画名テーブル
          WHERE  mp.organization_code    = o_scdl_tab(ln_srd_idx).organization_code   --CSVファイルの「組織コード」
          AND    mp.organization_id      = msd.organization_id
          AND    msd.schedule_designator = o_scdl_tab(ln_srd_idx).schedule_designator --CSVファイルの「MDS/MPS名」
          --★↓2009/01/19 追加
          AND    msd.attribute1          = o_scdl_tab(ln_srd_idx).schedule_type       --CSVファイルの「基準計画分類」
          --★↑2009/01/19 追加
          AND    NVL(msd.disable_date , cd_sysdate + 1) > cd_sysdate                  --基準計画名テーブルの有効日チェック
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_unmatch
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_schedule_name
                           ,iv_token_value2 => l_csv_tab(1)
                           ,iv_token_name3  => gv_t_org_code
                           ,iv_token_value3 => l_csv_tab(3)
                           ,iv_token_name4  => gv_t_item
                           ,iv_token_value4 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          WHEN TOO_MANY_ROWS THEN
            null;
        END;
        --
--20090403_Ver1.1_T1_0237_SCS.Goto_DEL_START
--        -- ===============================
--        -- 8.起動ユーザーチェック
--        -- ===============================
--        SELECT count(fu.user_id)
--        INTO   ln_user_rec_cnt
--        FROM   fnd_user                  fu                     -- ユーザーマスタ
--              ,per_all_people_f          papf                   -- 従業員マスタ
--              ,mtl_item_locations        mil                    -- OPM保管場所マスタ
--              ,mrp_schedule_designators  msd                    -- 基準計画名テーブル
--              ,po_vendors                pv                     -- 仕入先マスタ
--              ,mtl_parameters            mp                     -- 組織パラメータ
--        WHERE  fu.employee_id       = papf.person_id
--        AND    papf.attribute4      = pv.segment1                                    --従業員.仕入先コード = 仕入先.仕入先コード
--        AND    pv.segment1          = mil.attribute13                                --仕入先.仕入先コード = OPM保管場所.仕入先コード
--        AND    mil.organization_id  = msd.organization_id                            --OPM保管場所.在庫組織ID = 基準計画名.在庫組織ID
--        AND    msd.organization_id  = mp.organization_id                             --基準計画名.在庫組織ID = 組織パラメータ.組織ID
--        AND    mp.organization_code = o_scdl_tab(ln_srd_idx).organization_code       --組織パラメータ.組織コード = CSVファイル.組織コード
--        AND    fu.user_id           = gn_user_id                                     --コンカレント起動ユーザー
--        AND    cd_sysdate BETWEEN NVL(papf.effective_start_date,cd_sysdate)          --従業員マスタの有効日チェック
--                              AND NVL(papf.effective_end_date  ,cd_sysdate)
--        AND    msd.schedule_designator = o_scdl_tab(ln_srd_idx).schedule_designator  --CSVファイル.MDS/MPS名
--        AND    pv.enabled_flag         = 'Y'                                         --仕入先マスタの有効フラグチェック
--        AND    NVL(mil.disable_date , cd_sysdate) >= cd_sysdate                      --OPM保管場所マスタの有効日チェック
--        AND    NVL(msd.disable_date , cd_sysdate + 1) > cd_sysdate                   --基準計画名テーブルの有効日チェック
--        ;
--        --
--        IF ( ln_user_rec_cnt = 0 ) THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => gv_xxcop
--                         ,iv_name         => gv_m_e_user_chk
--                         ,iv_token_name1  => gv_t_row_num
--                         ,iv_token_value1 => ln_srd_idx
--                         ,iv_token_name2  => gv_t_schedule_name
--                         ,iv_token_value2 => l_csv_tab(1)
--                       );
--          output_disp(
--             iv_errmsg  => lv_errmsg
--            ,iv_errbuf  => lv_errbuf
--          );
--          lv_invalid_flag := gv_status_error;
--        END IF;
--        --
--20090403_Ver1.1_T1_0237_SCS.Goto_DEL_END
        -- ===============================
        -- 9.基準計画分類存在チェック
        -- ===============================
        SELECT count(flv.enabled_flag)
        INTO   ln_quick_rec_cnt
        FROM   fnd_lookup_values flv
        WHERE  flv.lookup_type   = cv_quick_type
        AND    flv.language      = cv_quick_lang
        AND    flv.description   = iv_format
        AND    flv.lookup_code   = o_scdl_tab(ln_srd_idx).schedule_type
        AND    flv.enabled_flag  = cv_quick_enable
        AND    cd_quick_sysdate BETWEEN NVL(flv.start_date_active,cd_quick_sysdate)
                                    AND NVL(flv.end_date_active  ,cd_quick_sysdate)
        ;
        IF ( ln_quick_rec_cnt = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcop
                         ,iv_name         => gv_m_e_set_err_t
                         ,iv_token_name1  => gv_t_row_num
                         ,iv_token_value1 => ln_srd_idx
                         ,iv_token_name2  => gv_t_item
                         ,iv_token_value2 => i_fuid_tab(ln_row_idx)
                       );
          output_disp(
             iv_errmsg  => lv_errmsg
            ,iv_errbuf  => lv_errbuf
          );
          lv_invalid_flag := gv_status_error;
        END IF;
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '行目' || ':6:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 10.禁止項目入力チェック
        -- ===============================
        CASE iv_format
          -- 201:基準計画（出荷予測MDS）
          WHEN gv_format_mds_o THEN
            --FLD8:出荷元倉庫コード
            IF ( o_scdl_tab(ln_srd_idx).deliver_from IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_08
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            --FLD9:出荷日
            IF ( o_scdl_tab(ln_srd_idx).shipment_date IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_09
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            --
          -- 202:基準計画（工場出荷計画MPS）
          WHEN gv_format_mps_o THEN
            -- FLD10:計画商品フラグ
            IF ( o_scdl_tab(ln_srd_idx).schedule_prod_flg IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_10
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            --
          -- 203:基準計画（購入計画MPS）
          WHEN gv_format_mps_i THEN
            --FLD8:出荷元倉庫コード
            IF ( o_scdl_tab(ln_srd_idx).deliver_from IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_08
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            --FLD9:出荷日
            IF ( o_scdl_tab(ln_srd_idx).shipment_date IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_09
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            -- FLD10:計画商品フラグ
            IF ( o_scdl_tab(ln_srd_idx).schedule_prod_flg IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_10
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
        END CASE;
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '行目' || ':7:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 11.品目コードチェック
        -- ===============================
        BEGIN
          SELECT msib.inventory_item_id
          INTO   l_item_id
          FROM   mtl_system_items_b        msib               -- Disc品目マスタ
                ,mrp_schedule_designators  msde               -- 基準計画名
                --★↓2009/01/16 追加
                ,mtl_parameters            mp                 -- 組織パラメータ
                --★↑2009/01/16 追加
          WHERE  msib.segment1            = o_scdl_tab(ln_srd_idx).item_code
          --★↓2009/01/16 追加
          AND    mp.organization_code     = o_scdl_tab(ln_srd_idx).organization_code
          AND    msib.organization_id     = mp.organization_id
          --★↑2009/01/16 追加
          AND    msib.inventory_item_status_code <> 'Inactive'
          AND    msib.organization_id     = msde.organization_id
          AND    msde.schedule_designator = o_scdl_tab(ln_srd_idx).schedule_designator
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_not_exist
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_column
                           ,iv_token_value2 => gv_column_name_05
                           ,iv_token_name3  => gv_t_value1
                           ,iv_token_value3 => l_csv_tab(5)
                           ,iv_token_name4  => gv_t_table
                           ,iv_token_value4 => gv_table_name_item
                           ,iv_token_name5  => gv_t_item
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          WHEN TOO_MANY_ROWS THEN
            null;
        END;
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '行目' || ':8:' || 'b',gv_debug_mode);
      --
--20090403_Ver1.1_T1_0270_SCS.Goto_ADD_START
        -- ===============================
        -- 11.OPM品目マスタチェック
        -- ===============================
        BEGIN
          SELECT NVL(TO_NUMBER(iimb.attribute11), 1)
          INTO   o_scdl_tab(ln_srd_idx).num_of_cases
          FROM   ic_item_mst_b             iimb               -- OPM品目マスタ
          WHERE  iimb.item_no          = o_scdl_tab(ln_srd_idx).item_code
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_not_exist
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_column
                           ,iv_token_value2 => gv_column_name_05
                           ,iv_token_name3  => gv_t_value1
                           ,iv_token_value3 => l_csv_tab(5)
                           ,iv_token_name4  => gv_t_table
                           ,iv_token_value4 => gv_table_name_opm
                           ,iv_token_name5  => gv_t_item
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
        END;
--20090403_Ver1.1_T1_0270_SCS.Goto_ADD_END
        --
        -- ===============================
        -- 12.計画日付・稼働日チェック
        -- ===============================
        --★↓2009/01/23 追加
        --スキップ判定 [計画日付 > 確定日]
        IF o_scdl_tab(ln_srd_idx).schedule_date > id_base_date THEN
        --★↑2009/01/23 追加
          BEGIN
            SELECT bcd.seq_num
            INTO   l_date_flg
            FROM   bom_calendar_dates  bcd          --稼働日カレンダ
                  ,mtl_parameters      mp           --組織パラメータ
            WHERE  mp.organization_code = o_scdl_tab(ln_srd_idx).organization_code
            AND    bcd.calendar_code    = mp.calendar_code
            AND    bcd.calendar_date    = o_scdl_tab(ln_srd_idx).schedule_date
            ;
            IF l_date_flg IS NULL THEN              --非稼働日（土・日）
              RAISE NO_DATA_FOUND;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_calendar_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_date
                             ,iv_token_value2 => TO_CHAR(o_scdl_tab(ln_srd_idx).schedule_date,'YYYY/MM/DD')
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            WHEN TOO_MANY_ROWS THEN
              null;
          END;
        --★↓2009/01/23 追加
        END IF;
        --★↑2009/01/23 追加
        --
        -- ===============================
        -- 13.出庫元倉庫コード存在チェック
        -- ===============================
        IF ( iv_format = gv_format_mps_o ) THEN
          BEGIN
            SELECT mp.organization_id
            INTO   l_org_id
            FROM   mtl_parameters  mp                     --組織パラメータ
            WHERE  mp.organization_code = o_scdl_tab(ln_srd_idx).deliver_from
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_not_exist
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_08
                             ,iv_token_name3  => gv_t_value1
                             ,iv_token_value3 => l_csv_tab(8)
                             ,iv_token_name4  => gv_t_table
                             ,iv_token_value4 => gv_table_name_org
                             ,iv_token_name5  => gv_t_item
                             ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            WHEN TOO_MANY_ROWS THEN
              null;
          END;
        END IF;
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '行目' || ':9:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 14.計画商品フラグ不正チェック
        -- ===============================
        IF ( iv_format = gv_format_mds_o
          AND o_scdl_tab(ln_srd_idx).schedule_prod_flg <> 1
          AND o_scdl_tab(ln_srd_idx).schedule_prod_flg IS NOT NULL )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcop
                         ,iv_name         => gv_m_e_chk_err
                         ,iv_token_name1  => gv_t_row_num
                         ,iv_token_value1 => ln_srd_idx
                         ,iv_token_name2  => gv_t_column
                         ,iv_token_value2 => gv_column_name_10
                         ,iv_token_name3  => gv_t_item
                         ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                       );
          output_disp(
             iv_errmsg  => lv_errmsg
            ,iv_errbuf  => lv_errbuf
          );
          lv_invalid_flag := gv_status_error;
        END IF;
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '行目' || ':10:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 15.一意キーチェック
        -- ===============================
        <<key_loop>>
        FOR ln_key_idx IN o_scdl_tab.first .. ( ln_srd_idx - 1 ) LOOP
        --
          -- エラーフラグ初期化
          lv_one_chk_flg := '0';
          -- 一意性エラー検出
          CASE iv_format
            --★↓2009/01/20 追加
            -- 202:基準計画（工場出荷計画MPS）
            WHEN gv_format_mps_o THEN
              IF (  o_scdl_tab(ln_srd_idx).schedule_designator   = o_scdl_tab(ln_key_idx).schedule_designator
                AND o_scdl_tab(ln_srd_idx).schedule_description  = o_scdl_tab(ln_key_idx).schedule_description
                AND o_scdl_tab(ln_srd_idx).organization_code     = o_scdl_tab(ln_key_idx).organization_code
                AND o_scdl_tab(ln_srd_idx).item_code             = o_scdl_tab(ln_key_idx).item_code
                AND o_scdl_tab(ln_srd_idx).schedule_date         = o_scdl_tab(ln_key_idx).schedule_date
                AND o_scdl_tab(ln_srd_idx).deliver_from          = o_scdl_tab(ln_key_idx).deliver_from )
              THEN
                lv_one_chk_flg := '1';
                lv_token_col_name := gv_column_name_01 || gv_msg_comma
                                  || gv_column_name_02 || gv_msg_comma
                                  || gv_column_name_03 || gv_msg_comma
                                  || gv_column_name_05 || gv_msg_comma
                                  || gv_column_name_06 || gv_msg_comma
                                  || gv_column_name_08 || gv_msg_comma ;
              END IF;
            --★↑2009/01/20 追加
            --
            -- 201:出荷予測,203:購入計画
            ELSE
              IF (  o_scdl_tab(ln_srd_idx).schedule_designator   = o_scdl_tab(ln_key_idx).schedule_designator
                AND o_scdl_tab(ln_srd_idx).schedule_description  = o_scdl_tab(ln_key_idx).schedule_description
                AND o_scdl_tab(ln_srd_idx).organization_code     = o_scdl_tab(ln_key_idx).organization_code
                AND o_scdl_tab(ln_srd_idx).item_code             = o_scdl_tab(ln_key_idx).item_code
                AND o_scdl_tab(ln_srd_idx).schedule_date         = o_scdl_tab(ln_key_idx).schedule_date )
              THEN
                lv_one_chk_flg := '1';
                lv_token_col_name := gv_column_name_01 || gv_msg_comma
                                  || gv_column_name_02 || gv_msg_comma
                                  || gv_column_name_03 || gv_msg_comma
                                  || gv_column_name_05 || gv_msg_comma
                                  || gv_column_name_06 || gv_msg_comma ;
              END IF;
          END CASE;
          --
          -- エラー時メッセージ出力
          IF ( lv_one_chk_flg = '1' ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_1rec_chk
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_column
                           ,iv_token_value2 => lv_token_col_name
                           ,iv_token_name3  => gv_t_item
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          END IF;
        END LOOP key_loop;
        --
      --★デバッグログ（開発用）
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '行目' || ':11:' || 'b',gv_debug_mode);
      --
      ELSE
        --1のエラー処理
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fchk
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => ln_srd_idx
                       ,iv_token_name2  => gv_t_file
                       ,iv_token_value2 => 'CSVファイル'
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        lv_invalid_flag := gv_status_error;
      END IF;
      --
      IF ( lv_invalid_flag = gv_status_error ) THEN
        --妥当性チェックでエラーとなった場合、エラー件数をカウント（レコード単位で1件カウントする）
        gn_error_cnt := gn_error_cnt + 1;
        --ov_retcode := gv_status_error;
      END IF;
    END LOOP row_loop;
    --
    --
    IF ( gn_error_cnt > 0 OR lv_invalid_flag = gv_status_error ) THEN
      ov_retcode := gv_status_error;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END chk_upload_data;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : データ登録(A-6)
   ***********************************************************************************/
--
  PROCEDURE insert_data(
    in_file_id    IN  NUMBER,                                     -- FILE_ID
    iv_file_name  IN  xxccp_mrp_file_ul_interface.file_name%TYPE, -- ファイル名
    i_scdl_tab    IN  xm_schedule_if_ttype,                       -- 基準計画データ
    id_base_date  IN  DATE,                                       -- 確定日
    on_normal_cnt OUT NUMBER,                                     -- 正常件数
    on_warn_cnt   OUT NUMBER,                                     -- スキップ件数
    ov_errbuf     OUT VARCHAR2,                                   -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                                   -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)                                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_normal_cnt     NUMBER                                    ; -- 正常件数
    ln_warn_cnt       NUMBER                                    ; -- スキップ件数
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
  --1.処理件数の初期化
  ln_normal_cnt := 0;
  ln_warn_cnt   := 0;
  --
  --2.基準計画登録
  <<row_loop>>
  FOR ln_row_idx IN i_scdl_tab.FIRST .. i_scdl_tab.LAST LOOP
    --スキップ判定 [計画日付 ≦ 確定日]
    IF i_scdl_tab(ln_row_idx).schedule_date <= id_base_date THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_n_skip_rec
                     ,iv_token_name1  => gv_t_row_num
                     ,iv_token_value1 => ln_row_idx
                     ,iv_token_name2  => gv_t_date1
                     ,iv_token_value2 => TO_CHAR(i_scdl_tab(ln_row_idx).schedule_date,gv_ymd_out_format)
                     ,iv_token_name3  => gv_t_date2
                     ,iv_token_value3 => TO_CHAR(id_base_date,gv_ymd_out_format)
                   );
      output_disp(
         iv_errmsg  => lv_errmsg
        ,iv_errbuf  => lv_errbuf
      );
      --
      --スキップ件数カウント
      ln_warn_cnt := ln_warn_cnt + 1;
    ELSE
      --レコード登録
      INSERT
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_START
--      INTO   xxcop.xxcop_mrp_schedule_interface(      -- 基準計画IF表
      INTO   xxcop_mrp_schedule_interface(            -- 基準計画IF表
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_END
               --IF制御情報
               transaction_id
              ,file_id
              ,file_name
              ,row_no
              --ヘッダ情報
              ,schedule_designator
              ,schedule_description
              ,organization_code
              ,schedule_type
              --品目明細情報
              ,item_code
              --日付詳細情報
              ,schedule_date
              ,schedule_quantity
              ,deliver_from
              ,shipment_date
              ,schedule_prod_flg
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
              ,schedule_prod_date
              ,prod_purchase_flg
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
              --以下WHOカラム
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
             )
      VALUES ( --IF制御情報
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_START
--               XXCOP.XXCOP_MRP_SCHEDULE_IF_S1.NEXTVAL       -- 取引ID（ｼｰｹﾝｽ）
               XXCOP_MRP_SCHEDULE_IF_S1.NEXTVAL             -- 取引ID（ｼｰｹﾝｽ）
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_END
              ,in_file_id                                   -- ファイルID
              ,iv_file_name                                 -- ファイル名
              ,ln_row_idx                                   -- 行No
               --ヘッダ情報
              ,i_scdl_tab(ln_row_idx).schedule_designator   -- MDS/MPS名
              ,i_scdl_tab(ln_row_idx).schedule_description  -- MDS/MPS摘要
              ,i_scdl_tab(ln_row_idx).organization_code     -- 組織コード
              ,i_scdl_tab(ln_row_idx).schedule_type         -- 基準計画分類
               --品目明細情報
              ,i_scdl_tab(ln_row_idx).item_code             -- 品目コード
               --日付詳細情報
              ,i_scdl_tab(ln_row_idx).schedule_date         -- 計画日付
--20090403_Ver1.1_T1_0270_SCS.Goto_MOD_START
--              ,i_scdl_tab(ln_row_idx).schedule_quantity     -- 計画数量
              ,i_scdl_tab(ln_row_idx).schedule_quantity
                * i_scdl_tab(ln_row_idx).num_of_cases       -- 計画数量
--20090403_Ver1.1_T1_0270_SCS.Goto_MOD_END
              ,i_scdl_tab(ln_row_idx).deliver_from          -- 出荷元倉庫コード
              ,i_scdl_tab(ln_row_idx).shipment_date         -- 出荷日
              ,i_scdl_tab(ln_row_idx).schedule_prod_flg     -- 計画商品フラグ
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_START
              ,i_scdl_tab(ln_row_idx).schedule_prod_date    -- 生産予定日
              ,i_scdl_tab(ln_row_idx).prod_purchase_flg     -- 製造/購入品フラグ
--20090821_Ver1.2_0001134_SCS.Moriyama_ADD_END
               --以下WHOカラム
              ,gn_created_by                                -- CREATED_BY
              ,gd_creation_date                             -- CREATION_DATE
              ,gn_last_updated_by                           -- LAST_UPDATED_BY
              ,gd_last_update_date                          -- LAST_UPDATE_DATE
              ,gn_last_update_login                         -- LAST_UPDATE_LOGIN
              ,gn_request_id                                -- REQUEST_ID
              ,gn_program_application_id                    -- PROGRAM_APPLICATION_ID
              ,gn_program_id                                -- PROGRAM_ID
              ,gd_program_update_date                       -- PROGRAM_UPDATE_DATE
      );
      --
      --登録エラー
      IF ( SQL%ROWCOUNT != 1 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_insert_err
                       ,iv_token_name1  => gv_t_table
                       ,iv_token_value1 => gv_table_name_ift
                     );
        RAISE global_process_expt;
      END IF;
      --
      --正常処理件数カウント
      ln_normal_cnt := ln_normal_cnt + 1;
      --
    END IF;
    --
  END LOOP row_loop;
--
  on_normal_cnt := ln_normal_cnt;
  on_warn_cnt   := ln_warn_cnt;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END insert_data;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : ファイルアップロードI/Fテーブルデータ削除(A-7)
   ***********************************************************************************/
--
  PROCEDURE delete_data(
    in_file_id    IN  NUMBER,                              -- ファイルID
    ov_errbuf     OUT VARCHAR2,                            -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                            -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)                            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型 ***
    -- *** ローカルPL/SQL表 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --1.ファイルアップロードテーブルデータ削除処理
    xxcop_common_pkg.delete_upload_table(
       in_file_id   => in_file_id         -- ファイルID
      ,ov_retcode   => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errbuf    => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END delete_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
--
  PROCEDURE submain(
    in_file_id      IN  NUMBER,       --   FILE_ID
    iv_format       IN  VARCHAR2,     --   フォーマットパターン
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_next_conc_application  CONSTANT VARCHAR2(100)  := 'XXCOP'       ; -- 後続処理のアプリケーション名
    cv_next_conc_program      CONSTANT VARCHAR2(100)  := 'XXCOP001A02C'; -- 後続処理のプログラム名
    cv_next_conc_name         CONSTANT VARCHAR2(100)  := '基準計画の取込'; -- 後続処理の日本語名
--
    -- *** ローカル変数 ***
    ld_base_date      DATE                                      ; -- 確定日
    lv_file_name      xxccp_mrp_file_ul_interface.file_name%TYPE; -- ファイル名
    l_fuid_tab        xxccp_common_pkg2.g_file_data_tbl         ; -- ファイルアップロードデータ(VARCHAR2)
    l_scdl_tab        xm_schedule_if_ttype                      ; -- 基準計画表データ
    ln_normal_cnt     NUMBER                                    ; -- 正常件数
    ln_warn_cnt       NUMBER                                    ; -- スキップ件数
    ln_request_id              NUMBER                           ; -- 要求ID（A02起動時）
    -- *** ローカルRECORD型 ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    BEGIN
--
      --処理件数の初期化
      ln_normal_cnt := 0;
      --
      --*********************************************
      --*** 処理名：初期処理                        ***
      --*** 処理NO：A-1                            ***
      --*********************************************
      init(
         iv_format          --   フォーマットパターン
        ,ld_base_date       --   確定日
        ,lv_errbuf          --   エラー・メッセージ          --# 固定 #
        ,lv_retcode         --   リターン・コード            --# 固定 #
        ,lv_errmsg          --   ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --デバッグログ
        fnd_file.put_line(FND_FILE.LOG,'A-1:Process Error');
        RAISE global_process_expt;
      END IF;
      --デバッグログ
      fnd_file.put_line(FND_FILE.LOG,'A-1:Process Success');
--
      --*********************************************
      --*** 処理名：関連データ取得                   ***
      --*** 処理NO：A-2                            ***
      --*********************************************
      get_file_info(
         in_file_id                   --   FILE_ID
        ,iv_format                    --   フォーマットパターン
        ,lv_file_name                 --   ファイル名
        ,lv_errbuf                    --   エラー・メッセージ           --# 固定 #
        ,lv_retcode                   --   リターン・コード             --# 固定 #
        ,lv_errmsg                    --   ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --デバッグログ
        fnd_file.put_line(FND_FILE.LOG,'A-2:Process Error');
        RAISE global_process_expt;
      END IF;
      --デバッグログ
      fnd_file.put_line(FND_FILE.LOG,'A-2:Process Success');
--
      --**************************************************
      --*** 処理名：ファイルアップロードI/Fテーブルデータ抽出 ***
      --*** 処理NO：A-3                                  ***
      --**************************************************
      get_upload_data(
        in_file_id            --   FILE_ID
       ,l_fuid_tab            --   ファイルデータ
       ,lv_errbuf             --   エラー・メッセージ           --# 固定 #
       ,lv_retcode            --   リターン・コード             --# 固定 #
       ,lv_errmsg             --   ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --デバッグログ
        fnd_file.put_line(FND_FILE.LOG,'A-3:Process Error');
        RAISE global_process_expt;
      END IF;
      --デバッグログ
      fnd_file.put_line(FND_FILE.LOG,'A-3:Process Success');
--
      --*********************************************
      --*** 処理名：妥当性チェック                   ***
      --*** 処理NO：A-4                            ***
      --*********************************************
      chk_upload_data(
        iv_format             -- フォーマットパターン
       ,l_fuid_tab            -- ファイルデータ
       --★↓2009/01/23 追加
       ,ld_base_date          -- 確定日
       --★↑2009/01/23 追加
       ,l_scdl_tab            -- 基準計画データ
       ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,lv_retcode            -- リターン・コード             --# 固定 #
       ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --デバッグログ
        fnd_file.put_line(FND_FILE.LOG,'A-4:Process Error');
        RAISE global_process_expt;
      END IF;
      --デバッグログ
      fnd_file.put_line(FND_FILE.LOG,'A-4:Process Success');
--
      --*********************************************
      --*** 処理名：データ登録                      ***
      --*** 処理NO：A-6                            ***
      --*********************************************
      insert_data(
        in_file_id            -- ファイルID
       ,lv_file_name          -- ファイル名
       ,l_scdl_tab            -- 基準計画データ
       ,ld_base_date          -- 確定日
       ,ln_normal_cnt         -- 正常件数
       ,ln_warn_cnt           -- スキップ件数
       ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,lv_retcode            -- リターン・コード             --# 固定 #
       ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --デバッグログ
        fnd_file.put_line(FND_FILE.LOG,'A-6:Process Error');
        RAISE global_process_expt;
      END IF;
      --
      --デバッグログ
      fnd_file.put_line(FND_FILE.LOG,'A-6:Process Success');
--
    -- =======================================================================
    -- ■[A-1]?[A-6]で発生したエラーを集約しロールバックを実行。後続のデータ削除処理へ。
    -- =======================================================================
    EXCEPTION
      WHEN global_process_expt THEN
        lv_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      WHEN OTHERS THEN
        --エラーメッセージを出力
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END;
    --
    --終了ステータスがエラーの場合、ロールバックする。
    IF ( ov_retcode <> gv_status_normal ) THEN
      ROLLBACK;
      --エラーメッセージを出力
      output_disp(
         iv_errmsg  => lv_errmsg
        ,iv_errbuf  => lv_errbuf
      );
    END IF;
--
    --***************************************************
    --*** 処理名：ファイルアップロードI/Fテーブルデータ削除  ***
    --*** 処理NO：A-7                                   ***
    --***************************************************
    delete_data(
      in_file_id            -- ファイルID
     ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,Lv_retcode            -- リターン・コード             --# 固定 #
     ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = gv_status_normal ) THEN
      --デバッグログ
      fnd_file.put_line(FND_FILE.LOG,'A-7:Process Success');
      --
      IF ( ov_retcode <> gv_status_normal ) THEN
        --エラーの場合でも、ファイルアップロードI/Fテーブルの削除が成功した場合はコミットする。
        COMMIT;
      END IF;
    ELSE
      --デバッグログ
      fnd_file.put_line(FND_FILE.LOG,'A-7:Process Error');
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    END IF;
    --
    IF ( ov_retcode = gv_status_normal ) THEN
      --終了ステータスが正常の場合、成功件数をセットする。
      gn_normal_cnt := ln_normal_cnt;
      --★以下確認中★スキップ発生時にステータスを正常とするか警告とするかで処理の場所が変わる
      gn_warn_cnt   := ln_warn_cnt;
    ELSE
      --終了ステータスがエラーの場合、エラー件数をセットする。
      IF ( gn_error_cnt = 0 ) THEN
        gn_error_cnt := 1;
      END IF;
    END IF;
--
    -- ===============================
    -- ★2009/01/15 追加
    -- コンカレント[XXCOP001A02C]起動処理
    -- ===============================
    IF ( ov_retcode <> gv_status_error ) THEN
      --コンカレント[XXCOP001A02C]起動
      ln_request_id := fnd_request.submit_request(
                          application  => cv_next_conc_application
                         ,program      => cv_next_conc_program
                         ,argument1    => in_file_id
                         ,argument2    => iv_format
                       );
--
      --エラーメッセージ出力
      IF ( ln_request_id = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_conc_call
                       ,iv_token_name1  => gv_t_syori
                       ,iv_token_value1 => cv_next_conc_name
                     );
        --デバッグログ
        fnd_file.put_line(FND_FILE.LOG,SQLERRM);
        --
        RAISE global_api_expt;
      END IF;
--
      --コンカレント[XXCOP001A02C]起動のためコミット
      COMMIT;
--
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    in_file_id    IN     NUMBER,           --   FILE_ID
    iv_format     IN     VARCHAR2          --   フォーマットパターン
  )
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --ｴﾗｰ終了メッセージ（全件処理前戻し）
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code      VARCHAR2(100);
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_h_plan_file_name  VARCHAR2(1000);  -- 引取計画ファイル名
--
  BEGIN
--
  --[retcode]初期化（記述ルールより）
  retcode := gv_status_normal;
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
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    --行間
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       in_file_id           -- FILE_ID
      ,iv_format            -- フォーマットパターン
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --ステータスセット
    retcode := lv_retcode;
--
    -- ===============================
    -- エラーメッセージ出力処理
    -- ===============================
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --ユーザー・エラーメッセージ
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --エラーメッセージ
    );
    --
    --行間
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- 対象件数出力処理
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- 成功件数出力処理
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- エラー件数出力処理
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ===============================
    -- スキップ件数出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --行間
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- 終了メッセージ出力
    -- ===============================
    IF ( retcode = gv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = gv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( retcode = gv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- エラー処理（ROLLBACK）
    -- ===============================
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
  END main;
--
END XXCOP001A01C;
/
