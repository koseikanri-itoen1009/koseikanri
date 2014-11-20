create or replace
PACKAGE BODY XXCFF004A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A10C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : 再リース要否アップロード CFF_004_A10
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_if_data            p ファイルアップロードIFデータ取得処理    (A-2)
 *  devide_item            p デリミタ文字項目分割                    (A-3)
 *  insert_work            p 再リース要否ワークデータ作成            (A-5)
 *  combination_check      p 組み合わせチェック                      (A-6)
 *  item_validate_check    p 項目妥当性チェック                      (A-8)
 *  re_lease_update        p 物件レコードロックと更新                (A-9)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   SCS大井 信幸     新規作成
 *  2009/02/09    1.1   SCS大井 信幸     ログ出力項目追加
 *  2009/02/25    1.2   SCS大井 信幸     文字列中の"を切り取り
 *  2009/02/25    1.3   SCS大井 信幸     ユーザーメッセージ出力先変更
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
  gr_file_data_tbl xxccp_common_pkg2.g_file_data_tbl; --ファイルアップロードデータ格納配列
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
---- ===============================
  -- ユーザー定義例外
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF004A10C'; -- パッケージ名
  cv_log             CONSTANT VARCHAR2(100) := 'LOG';          -- コンカレントログ出力先--
  cv_out             CONSTANT VARCHAR2(100) := 'OUTPUT';            -- コンカレント出力先--
--
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCFF';            -- アドオン：会計・リース・FA領域
  cv_appl_name_cmn   CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
  cv_not_null_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00005'; -- 必須エラーメッセージ
  cv_num_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00117'; -- 数値エラーメッセージ
  cv_combi_msg       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00036'; -- 組み合わせエラーメッセージ
  cv_exp_date_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00033'; -- 満了日エラーメッセージ
  cv_obj_stat_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00063'; -- 物件ステータスエラーメッセージ
  cv_re_lease_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00051'; -- 再リース要否値エラーメッセージ
  cv_rec_lock_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00007'; -- レコードロックエラーメッセージ
  cv_dup_index_msg   CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00011'; -- 重複エラーメッセージ
  cv_format_msg      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00166'; -- 項目フォーマットエラーメッセージ
  cv_upload_init_msg CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00167'; -- アップロード初期出力メッセージ
--
  cv_not_null_tkn    CONSTANT VARCHAR2(100)  := 'COLUMN_NAME';     -- 必須エラートークン
  cv_col_nam_tkn     CONSTANT VARCHAR2(100)  := 'COLUMN_VALUE';    -- 項目値トークン
  cv_info_tkn        CONSTANT VARCHAR2(100)  := 'INFO';            -- 情報トークン
  cv_from_info_tkn   CONSTANT VARCHAR2(100)  := 'FROM_INFO';       -- 情報トークン
  cv_num_err_tkn     CONSTANT VARCHAR2(100)  := 'INPUT';           -- 数値エラートークン
  cv_combi_tkn1      CONSTANT VARCHAR2(100)  := 'OBJECT_CODE';     -- 組み合わせエラートークン
  cv_combi_tkn2      CONSTANT VARCHAR2(100)  := 'CONTACT_NUMBER';  -- 組み合わせエラートークン
  cv_combi_tkn3      CONSTANT VARCHAR2(100)  := 'CONTACT_NUM';     -- 組み合わせエラートークン
  cv_combi_tkn4      CONSTANT VARCHAR2(100)  := 'LEASE_COMPANY';   -- 組み合わせエラートークン
  cv_combi_tkn5      CONSTANT VARCHAR2(100)  := 'LEASE_TIMES';     -- 組み合わせエラートークン
  cv_exp_tkn1        CONSTANT VARCHAR2(100)  := 'EXPIRATION_DATE'; -- 満了日エラートークン
  cv_exp_tkn2        CONSTANT VARCHAR2(100)  := 'BATCH_DATE';      -- 満了日エラートークン
  cv_status_tkn      CONSTANT VARCHAR2(100)  := 'OBJECT_STATUS';   -- 物件ステータスエラートークン
  cv_re_lease_tkn    CONSTANT VARCHAR2(100)  := 'RE_LEASED_FLAG';  -- 再リース値エラートークン
  cv_rec_lock_tkn    CONSTANT VARCHAR2(100)  := 'TABLE_NAME';      -- レコードロックトークン
  cv_file_name_tkn   CONSTANT VARCHAR2(100)  := 'FILE_NAME';       -- ファイル名トークン
  cv_csv_name_tkn    CONSTANT VARCHAR2(100)  := 'CSV_NAME';        -- CSVファイル名トークン
  cv_csv_name        CONSTANT VARCHAR2(3)    := 'CSV';             -- CSV
  cv_csv_delim       CONSTANT VARCHAR2(3)    := ',';               -- CSV区切り文字
  cv_look_type       CONSTANT VARCHAR2(100)  := 'XXCFF1_RE_LEASE_UPLOAD'; -- LOOKUP TYPE
--
  cv_tkn_val1        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50010'; -- 物件コード
  cv_tkn_val2        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50020'; -- 再リース要フラグ
  cv_tkn_val3        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50044'; -- 再リース回数
  cv_tkn_val4        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50040'; -- 契約番号
  cv_tkn_val5        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50058'; -- 契約枝番
  cv_tkn_val6        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50013'; -- 物件ステータス
  cv_tkn_val7        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50014'; -- リース物件テーブル
  cv_tkn_val8        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50136'; -- アップロードファイル再リース要否
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,              -- 1.ファイルID
    or_init_rec   OUT NOCOPY xxcff_common1_pkg.init_rtype,  -- 2.初期情報格納
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_file_name  xxccp_mrp_file_ul_interface.file_name%TYPE;  -- エラー・メッセージ
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
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      ,iv_which         => cv_out              -- 出力区分
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;

--    アップロードCSVファイル名取得
      SELECT
             file_name
      INTO
             lv_file_name
      FROM
             xxccp_mrp_file_ul_interface
      WHERE
            file_id = in_file_id;

--    アップロードCSVファイル名ログ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_upload_init_msg
                                          ,cv_file_name_tkn,   cv_tkn_val8
                                          ,cv_csv_name_tkn,    lv_file_name)
      );

    -- 共通初期処理の呼び出し
    xxcff_common1_pkg.init(
       ov_retcode  => lv_retcode
      ,ov_errbuf   => lv_errbuf
      ,ov_errmsg   => lv_errmsg
      ,or_init_rec => or_init_rec   --   1.初期情報格納
    );

    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
   * Description      : ファイルアップロードIFデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id    IN  NUMBER,              --   1.ファイルID
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    --共通アップロードデータ変換処理
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id =>  in_file_id       -- ファイルＩＤ
      ,ov_file_data=> gr_file_data_tbl -- 変換後VARCHAR2データ
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
    );
--lv_retcode := cv_status_error;
--lv_errmsg := '異常終了確認のためユーザーエラーとして設定';
--lv_errbuf := 'アップロードデータ変換処理でエラー（テスト用に変更）';
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END get_if_data;
  /**********************************************************************************
   * Procedure Name   : devide_item
   * Description      : デリミタ文字項目分割(A-3)
   ***********************************************************************************/
  PROCEDURE devide_item(
    in_file_data  IN  VARCHAR2,                           --  1.ファイルデータ
    ov_flag       OUT NOCOPY VARCHAR2,                    --  2.データ区分
    or_work_rtype OUT NOCOPY xxcff_re_lease_work%ROWTYPE, --  3.再リース要否ワークレコード
    ov_errbuf     OUT NOCOPY VARCHAR2,                    --  エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,                    --  リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)                    --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'devide_item'; -- プログラム名
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
    lv_item        VARCHAR2(5000);   -- 項目一時格納用
    lv_errmsg_sv   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ格納用
--
    -- *** ローカル・カーソル ***
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    lv_errmsg_sv := NULL;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    OPEN item_check_cur(cv_look_type);
    LOOP
      FETCH item_check_cur INTO item_check_cur_rec;
      EXIT WHEN item_check_cur%NOTFOUND;
      -- INDEX番目のデータ取得
      lv_item :=
        xxccp_common_pkg.char_delim_partition(in_file_data
                                             ,cv_csv_delim
                                             ,item_check_cur_rec.index_num
        );
      -- 囲み文字の”をTRIMする
      lv_item := ltrim(lv_item,'"');
      lv_item := rtrim(lv_item,'"');
      -- =====================================================
      --  項目長、必須、データ型エラーチェック
      -- =====================================================
      xxccp_common_pkg2.upload_item_check(
        iv_item_name     => item_check_cur_rec.item_name, -- 項目名称（項目の日本語名）  -- 必須
        iv_item_value    => lv_item,       -- 項目の値                    -- 任意
        in_item_len      => item_check_cur_rec.item_len,  -- 項目の長さ                  -- 必須
        in_item_decimal  => item_check_cur_rec.item_dec,  -- 項目の長さ（小数点以下）    -- 条件付必須
        iv_item_nullflg  => item_check_cur_rec.item_null, -- 必須フラグ（上記定数を設定）-- 必須
        iv_item_attr     => item_check_cur_rec.item_type, -- 項目属性（上記定数を設定）  -- 必須
        ov_errbuf        => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode       => lv_retcode,        -- リターン・コード             --# 固定 #
        ov_errmsg        => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #

      IF (lv_errmsg IS NOT NULL)
        AND (lv_errmsg_sv IS NULL) THEN
        lv_errmsg_sv := lv_errmsg;
      ELSE
        CASE item_check_cur_rec.lookup_code
          WHEN 1 THEN
            ov_flag := TRIM(lv_item);
          WHEN 2 THEN
            or_work_rtype.object_code := lv_item;
          WHEN 3 THEN
            or_work_rtype.re_lease_flag := lv_item;
          WHEN 4 THEN
            or_work_rtype.contract_number := lv_item;
          WHEN 5 THEN
            or_work_rtype.contract_line_num := TO_NUMBER(lv_item);
          WHEN 6 THEN
            or_work_rtype.lease_company := lv_item;
          WHEN 7 THEN
            or_work_rtype.re_lease_times := TO_NUMBER(lv_item);
        END CASE ;
      END IF;
      IF (ov_flag IS NULL) THEN
        CLOSE item_check_cur;
        EXIT;
      END IF;

    END LOOP;
    IF (lv_errmsg_sv IS NOT NULL) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_format_msg
                                          ,cv_info_tkn,        lv_errmsg_sv
                                          ,cv_combi_tkn1,      or_work_rtype.object_code
                                          ,cv_combi_tkn2,      or_work_rtype.contract_number
                                          ,cv_combi_tkn3,      or_work_rtype.contract_line_num
                                          ,cv_combi_tkn4,      or_work_rtype.lease_company
                                          ,cv_combi_tkn5,      or_work_rtype.re_lease_times)
      );
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (item_check_cur%ISOPEN) THEN
        CLOSE item_check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END devide_item;
  /**********************************************************************************
   * Procedure Name   : insert_work
   * Description      : 再リース要否ワーク登録(A-5)
   ***********************************************************************************/
  PROCEDURE insert_work(
    in_file_id    IN  NUMBER,                       -- 1.ファイルデータ
    ir_work_rtype IN  xxcff_re_lease_work%ROWTYPE,  -- 2.再リース要否ワークレコード
    ov_errbuf     OUT NOCOPY VARCHAR2,              --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,              --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)              --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work'; -- プログラム名
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
    --再リース要否ワークデータ挿入処理
    INSERT INTO xxcff_re_lease_work(
       object_code
      ,file_id
      ,contract_number
      ,contract_line_num
      ,re_lease_flag
      ,lease_company
      ,lease_type
      ,re_lease_times
      --WHOカラム
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       ir_work_rtype.object_code
      ,in_file_id
      ,ir_work_rtype.contract_number
      ,ir_work_rtype.contract_line_num
      ,ir_work_rtype.re_lease_flag
      ,ir_work_rtype.lease_company
      ,ir_work_rtype.lease_type
      ,ir_work_rtype.re_lease_times
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
     );
--
  EXCEPTION
--
    WHEN DUP_VAL_ON_INDEX THEN   --物件コードが重複の場合
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_dup_index_msg
                                          ,cv_not_null_tkn,     cv_tkn_val1
                                          ,cv_col_nam_tkn,      ir_work_rtype.object_code
                                          ,cv_from_info_tkn,    cv_csv_name
                  );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_work;
--
  /**********************************************************************************
   * Procedure Name   : combination_check
   * Description      : 組み合わせ存在チェック(A-6)
   ***********************************************************************************/
  PROCEDURE combination_check(
    in_file_id    IN  NUMBER,              --   1.ファイルID
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'combination_check'; -- プログラム名
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR combi_check_cur(in_file_id NUMBER)
    IS
    SELECT
       xrlw.lease_company     lease_company
      ,xrlw.object_code       object_code
      ,xrlw.contract_number   contract_number
      ,xrlw.contract_line_num contract_line_num
      ,xrlw.re_lease_times    re_lease_times
    FROM
      xxcff_re_lease_work     xrlw
    WHERE
        xrlw.file_id          = in_file_id
    AND NOT EXISTS
      (SELECT 1
       FROM
            xxcff_contract_headers xch
           ,xxcff_contract_lines   xcl
            ,xxcff_object_headers  xoh
       WHERE
            xcl.object_header_id    = xoh.object_header_id
       AND  xch.contract_header_id  = xcl.contract_header_id
       AND  xch.re_lease_times      = xoh.re_lease_times
       AND  xch.lease_company       = xrlw.lease_company
       AND  xrlw.object_code        = xoh.object_code
       AND  xch.contract_number     = xrlw.contract_number
       AND  xcl.contract_line_num   = xrlw.contract_line_num
       AND  xch.re_lease_times      = xrlw.re_lease_times);
    -- <カーソル名>レコード型
    combi_check_cur_rec combi_check_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    OPEN combi_check_cur(in_file_id);
    LOOP
      FETCH combi_check_cur INTO combi_check_cur_rec;
      EXIT WHEN combi_check_cur%NOTFOUND;
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_combi_msg
                                            ,cv_combi_tkn1,      combi_check_cur_rec.object_code
                                            ,cv_combi_tkn2,      combi_check_cur_rec.contract_number
                                            ,cv_combi_tkn3,      combi_check_cur_rec.contract_line_num
                                            ,cv_combi_tkn4,      combi_check_cur_rec.lease_company
                                            ,cv_combi_tkn5,      combi_check_cur_rec.re_lease_times)
        );
      gn_error_cnt := gn_error_cnt + 1;
    END LOOP;
    CLOSE combi_check_cur;

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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (combi_check_cur%ISOPEN) THEN
        CLOSE combi_check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END combination_check;
--
  /**********************************************************************************
   * Procedure Name   : item_validate_check
   * Description      : 項目妥当性チェック(A-8)
   ***********************************************************************************/
  PROCEDURE item_validate_check(
    in_code       IN  VARCHAR2,            --   1.物件コード
    in_ope_date   IN  DATE,                --   2.業務日付
    in_exp_date   IN  DATE,                --   3.リース満了日
    in_flag_org   IN  VARCHAR2,            --   4.再リース要否元
    in_flag       IN  VARCHAR2,            --   4.再リース要否
    in_status_cd  IN  VARCHAR2,            --   5.物件ステータスコード
    in_status_nm  IN  VARCHAR2,            --   6.物件ステータス名
    on_warn_cnt   OUT NOCOPY NUMBER,       --   7.発生警告メッセージ数
    on_update_flg OUT NOCOPY NUMBER,       --   8.更新対象フラグ 0:更新 1:更新対象外
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_validate_check'; -- プログラム名
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
    cv_re_lease_on    CONSTANT xxcff_object_headers.re_lease_flag%TYPE       := '1';   --再リース否
    cv_re_lease_off   CONSTANT xxcff_object_headers.re_lease_flag%TYPE       := '0';   --再リース要
    cv_status_cont    CONSTANT xxcff_object_status_v.object_status_code%TYPE := '102'; --契約
    cv_status_re_cont CONSTANT xxcff_object_status_v.object_status_code%TYPE := '104'; --再契約
--
    -- *** ローカル変数 ***
    ld_exp_month  DATE;  --業務月
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>

    -- <カーソル名>レコード型
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    on_warn_cnt   := 0;
    on_update_flg := 0;
    ld_exp_month := TRUNC(in_ope_date,'MM');

    --満了日チェック
    IF (NVL(in_exp_date,ld_exp_month)  < ld_exp_month) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_exp_date_msg
                                          ,cv_combi_tkn1,      in_code
                                          ,cv_exp_tkn1,        in_exp_date
                                          ,cv_exp_tkn2,        in_ope_date
                  )
      );
      on_warn_cnt := on_warn_cnt + 1;
    END IF;
    --再リース要否コードチェック
    IF ( in_flag NOT IN(cv_re_lease_on, cv_re_lease_off) ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_re_lease_msg
                                          ,cv_combi_tkn1,      in_code
                                          ,cv_re_lease_tkn,    in_flag
                  )
      );
      on_warn_cnt := on_warn_cnt + 1;
    END IF;
    --物件ステータス
    IF ( in_status_cd NOT IN(cv_status_cont, cv_status_re_cont) ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_obj_stat_msg
                                          ,cv_combi_tkn1,      in_code
                                          ,cv_status_tkn,      in_status_nm
                  )
      );
      on_warn_cnt := on_warn_cnt + 1;
    END IF;
    --要否フラグ値チェック
    IF ( in_flag = in_flag_org) THEN
      on_update_flg := 1;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END item_validate_check;
--
  /**********************************************************************************
   * Procedure Name   : re_lease_update
   * Description      : 物件レコードロックと更新(A-9)
   ***********************************************************************************/
  PROCEDURE re_lease_update(
    in_object_id  IN  xxcff_object_headers.object_header_id%TYPE, -- 物件内部ＩＤ
    in_flag       IN  xxcff_object_headers.re_lease_flag%TYPE,    -- 再リース値
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 're_lease_update'; -- プログラム名
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
    ln_busy_code  NUMBER := -54;
--
    -- *** ローカル変数 ***
    ln_object_id  xxcff_object_headers.object_header_id%TYPE;
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
    --リース物件レコードロック処理
    SELECT
           object_header_id AS object_header_id
    INTO
           ln_object_id
    FROM   
           xxcff_object_headers
    WHERE
           object_header_id = in_object_id
    FOR UPDATE NOWAIT;
    
    UPDATE
           xxcff_object_headers
    SET
           re_lease_flag          = in_flag
          ,last_updated_by        = cn_last_updated_by
          ,last_update_date       = cd_last_update_date
          ,last_update_login      = cn_last_update_login
          ,request_id             = cn_request_id
          ,program_application_id = cn_program_application_id
          ,program_id             = cn_program_id
          ,program_update_date    = cd_program_update_date
    WHERE  object_header_id       = in_object_id;
    
    gn_normal_cnt := gn_normal_cnt + 1;
    
--
  EXCEPTION
--
   WHEN TIMEOUT_ON_RESOURCE THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_rec_lock_msg
                                          ,cv_rec_lock_tkn,     cv_tkn_val7
                  );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
      IF (SQLCODE = ln_busy_code) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_rec_lock_msg
                                            ,cv_rec_lock_tkn,     cv_tkn_val7
                    );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ELSE
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      END IF;
      ov_retcode := cv_status_error;
     --
--#####################################  固定部 END   ##########################################
--
  END re_lease_update;
--
  /**********************************************************************************
   * Procedure Name   : submain_main
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain_main(
    in_file_id    IN  NUMBER,              -- 1.ファイルID
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_init_rtype   xxcff_common1_pkg.init_rtype;  --初期処理取得結果格納用
    lr_work_rtype   xxcff_re_lease_work%ROWTYPE;   --再リース要否ワークレコード格納用
    ln_reccnt       NUMBER(10);                    --ループ処理カウンタ
    ln_warn_cnt     NUMBER(10);                    --妥当性チェック発生判定用
    ln_update_flag  NUMBER(10);                    --更新対象判定用
    lv_comment_flag VARCHAR2(10);                  --出力区分格納用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR get_work_cur(in_file_id NUMBER)
    IS
    SELECT
       xoh.object_code         AS object_code
      ,xoh.expiration_date     AS expiration_date
      ,xoh.object_header_id    AS object_header_id
      ,xoh.re_lease_flag       AS re_lease_flag_org
      ,xrlw.re_lease_flag      AS re_lease_flag
      ,xoh.object_status       AS object_status
      ,xosv.object_status_name AS object_status_name
    FROM
       xxcff_object_headers    xoh
      ,xxcff_re_lease_work     xrlw
      ,xxcff_object_status_v   xosv
    WHERE
        xrlw.file_id            = in_file_id
    AND xrlw.object_code        = xoh.object_code
    AND xosv.object_status_code = xoh.object_status
    ORDER BY xoh.object_code;
    -- <カーソル名>レコード型
    get_work_cur_rec           get_work_cur%ROWTYPE;

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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
--
    -- 共通初期処理の呼び出し
    init(
       in_file_id  => in_file_id      --   1.ファイルID
      ,or_init_rec => lr_init_rtype   --   2.初期情報格納
      ,ov_retcode  => lv_retcode
      ,ov_errbuf   => lv_errbuf
      ,ov_errmsg   => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    -- =====================================================
    --  ファイルアップロードIFデータ取得(A-2)
    -- =====================================================
    get_if_data(
       in_file_id => in_file_id       -- 1.ファイルID
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
--
    --配列に格納されているCSV行を1行づつ取得する
    FOR ln_reccnt IN gr_file_data_tbl.first..gr_file_data_tbl.last LOOP
      gn_target_cnt := gn_target_cnt + 1;   --処理件数カウント
      -- =====================================================
      --  デリミタ文字項目分割(A-3)
      -- =====================================================
      devide_item(
         in_file_data  => gr_file_data_tbl(ln_reccnt)  -- 1.ファイルデータ
        ,ov_flag       => lv_comment_flag              -- 2.データ区分(コメント行判定用)
        ,or_work_rtype => lr_work_rtype                -- 3.再リース要否ワークレコード
        ,ov_retcode    => lv_retcode
        ,ov_errbuf     => lv_errbuf
        ,ov_errmsg     => lv_errmsg
      );
      --コメント行はスキップ
      -- =====================================================
      --  コメント行チェック(A-4)
      -- =====================================================
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
      ELSIF (TRIM(lv_comment_flag) IS NULL) THEN
        gn_target_cnt := gn_target_cnt - 1;   --処理件数カウント調整
      ELSE
        -- =====================================================
        --  再リース要否ワーク登録(A-5)
        -- =====================================================
        IF (gn_error_cnt = 0) THEN
          insert_work(
             in_file_id    => in_file_id       -- 1.ファイルデータ
            ,ir_work_rtype => lr_work_rtype    -- 2.再リース要否ワークレコード
            ,ov_retcode    => lv_retcode
            ,ov_errbuf     => lv_errbuf
            ,ov_errmsg     => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END LOOP;
--
      --全行警告の場合正常終了
    IF (gn_target_cnt = 0)  THEN
      return;
    END IF;
    IF (gn_error_cnt <> 0)  THEN
      --(エラー処理)
      return;
    END IF;
--
      -- =====================================================
      --  組み合わせ存在チェック(A-6)
      -- =====================================================
    -- 必須チェック、再リース要否ワーク登録でエラーがなければ処理を行う
    combination_check(
       in_file_id    => in_file_id       -- 1.ファイルＩＤ
      ,ov_retcode    => lv_retcode
      ,ov_errbuf     => lv_errbuf
      ,ov_errmsg     => lv_errmsg
    );
    IF (gn_error_cnt<> 0) THEN
      --(エラー処理)
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    -- 組み合わせチェックでエラーがあれば終了処理を行う
    -- =====================================================
    --  再リース要否情報抽出(A-7)
    -- =====================================================
    OPEN get_work_cur(in_file_id);
    LOOP
      FETCH get_work_cur INTO get_work_cur_rec;
      EXIT WHEN get_work_cur%NOTFOUND;
      -- =====================================================
      --  項目妥当性チェック(A-8)
      -- =====================================================
      item_validate_check(
         in_code       => get_work_cur_rec.object_code         -- 1.物件コード
        ,in_ope_date   => lr_init_rtype.process_date           -- 2.業務日付
        ,in_exp_date   => get_work_cur_rec.expiration_date     -- 3.リース満了日
        ,in_flag_org   => get_work_cur_rec.re_lease_flag_org   -- 4.再リース要否元
        ,in_flag       => get_work_cur_rec.re_lease_flag       -- 4.再リース要否
        ,in_status_cd  => get_work_cur_rec.object_status       -- 5.物件コステータスコード
        ,in_status_nm  => get_work_cur_rec.object_status_name  -- 6.物件ステータス名
        ,on_warn_cnt   => ln_warn_cnt                          -- 7.発生警告メッセージ数
        ,on_update_flg => ln_update_flag                       -- 7.更新対象判定
        ,ov_retcode    => lv_retcode
        ,ov_errbuf     => lv_errbuf
        ,ov_errmsg     => lv_errmsg
      );

      IF (ln_warn_cnt <> 0) THEN
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSIF (ln_update_flag <> 0) THEN  --更新不要の場合DB更新は行わず、カウントアップする
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        -- =====================================================
        --  物件レコードロックと更新(A-9)
        -- =====================================================
        re_lease_update(
           in_object_id => get_work_cur_rec.object_header_id -- 1.物件内部ID
          ,in_flag      => get_work_cur_rec.re_lease_flag    -- 2.再リース要否
          ,ov_retcode   => lv_retcode
          ,ov_errbuf    => lv_errbuf
          ,ov_errmsg    => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          CLOSE get_work_cur;
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP;
    CLOSE get_work_cur;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (get_work_cur%ISOPEN) THEN
        CLOSE get_work_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_work_cur%ISOPEN) THEN
        CLOSE get_work_cur;
      END IF;
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
    in_file_id    IN  NUMBER,              -- 1.ファイルID
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- ===============================================
    -- submain_mainの呼び出し（実際の処理はsubmain_mainで行う）
    -- ===============================================
    submain_main(
       in_file_id  -- 1.ファイルID
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- =====================================================
    --  終了処理(A-10)
    -- =====================================================
    IF (gn_error_cnt <> 0)
      OR (lv_retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      -- 再リース要否ワーク削除
      DELETE
      FROM  xxcff_re_lease_work
      WHERE file_id = in_file_id;
    END IF;
    -- ファイルアップロードIFテーブル削除
    DELETE
    FROM  xxccp_mrp_file_ul_interface
    WHERE file_id = in_file_id;
    --異常終了の場合ファイルアップロードIFテーブル削除のためにCOMMIT実行
    IF (gn_error_cnt <> 0)
      OR (lv_retcode = cv_status_error) THEN
      COMMIT;
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
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf         OUT NOCOPY   VARCHAR2,   --   エラーメッセージ #固定#
    retcode        OUT NOCOPY   VARCHAR2,   --   エラーコード     #固定#
    in_file_id     IN  NUMBER,              --   1.ファイルID
    iv_file_format IN  VARCHAR2             --   2.ファイルフォーマット
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
      ,iv_which   => cv_out
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
       in_file_id  -- 1.ファイルID
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
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
                     iv_application  => cv_appl_name_cmn
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
                     iv_application  => cv_appl_name_cmn
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
                     iv_application  => cv_appl_name_cmn
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
                     iv_application  => cv_appl_name_cmn
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
                     iv_application  => cv_appl_name_cmn
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
END XXCFF004A10C;
/
