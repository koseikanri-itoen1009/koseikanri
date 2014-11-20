CREATE OR REPLACE PACKAGE BODY XXCOP_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(body)
 * Description      : 共通関数パッケージ(計画)
 * MD.050           : 共通関数    MD070_IPO_COP
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  get_charge_base_code     01.担当拠点取得関数
 *  get_case_quantity        02.ケース数換算関数
 *  delete_upload_table      03.ファイルアップロードテーブルデータ削除処理
 *  chk_date_format          04.日付型チェック関数
 *  chk_number_format        05.数値型チェック関数
 *  put_debug_message        06.デバッグメッセージ出力関数
 *  char_delim_partition     07.デリミタ文字分割関数
 *  get_upload_table_info    08.ファイルアップロードテーブル情報取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/04    1.0                   新規作成
 *  2009/03/25    1.1   S.Kayahara      最終行にスラッシュ追加
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################

  cv_pkg_name               CONSTANT VARCHAR2(100) := 'xxcop_common_pkg';       -- パッケージ名
--
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  resource_busy_expt        EXCEPTION;     -- デッドロックエラー
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
/************************************************************************
 * Function Name   : get_charge_base_code
 * Description     : ユーザに紐づく拠点コードを取得する
 ************************************************************************/
  FUNCTION get_charge_base_code
  ( in_user_id      IN NUMBER             -- ユーザーID
  , id_target_date  IN DATE               -- 対象日
  )
  RETURN VARCHAR2                         -- 拠点コード
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_charge_base_code'; -- プログラム名

    -- *** ローカル変数 ***
    lv_start_date      per_all_assignments_f.ass_attribute2%type;    -- 発令日
    lv_basecode_new    per_all_assignments_f.ass_attribute5%type;    -- 拠点コード(新)
    lv_basecode_old    per_all_assignments_f.ass_attribute6%type;    -- 拠点コード(旧)
  BEGIN
    ---------------------------------------------------------
    -- ユーザマスタ・従業員割当マスタより拠点情報を取得
    ---------------------------------------------------------
    --変更後処理
    SELECT paaf.ass_attribute2           -- 発令日
           -- 所属拠点から勤務地拠点に取得元変更
          ,paaf.ass_attribute5           -- 拠点(新)
          ,paaf.ass_attribute6           -- 拠点(旧)
    INTO   lv_start_date
        ,  lv_basecode_new
        ,  lv_basecode_old
    FROM   fnd_user                fu    -- ユーザ
          ,per_all_people_f        papf  -- 従業員
          ,per_all_assignments_f   paaf  -- 従業員割当
          ,per_person_types        ppt   -- 従業員タイプ
    WHERE
    -- 入力情報紐付け
           fu.user_id = in_user_id
    -- 従業員紐付け
    AND    fu.employee_id = papf.person_id
    AND    id_target_date BETWEEN papf.effective_start_date
                              AND NVL(papf.effective_end_date,id_target_date)
    -- 従業員割当紐付け
    AND    papf.person_id    = paaf.person_id
    AND    paaf.primary_flag = 'Y'
    AND    id_target_date BETWEEN paaf.effective_start_date
                          AND NVL(paaf.effective_end_Date,id_target_date)
    -- 従業員区分紐付け
    AND    papf.person_type_id = ppt.person_type_id
-- 2008/12/24 modified by scs_fukada start
--    AND    ppt.business_group_id  = fnd_global.per_business_group_id
    AND    ppt.business_group_id  = papf.business_group_id
-- 2008/12/24 modified by scs_fukada end
    AND    ppt.system_person_type = 'EMP'
    AND    ppt.active_flag        = 'Y'
    ;
/*
    --変更前バックアップ
    SELECT paa.ass_attribute2          -- 発令日
        ,  paa.ass_attribute5          -- 拠点コード(新)
        ,  paa.ass_attribute6          -- 拠点コード(旧)
    INTO   lv_start_date
        ,  lv_basecode_new
        ,  lv_basecode_old
    FROM   fnd_user               fu
        ,  per_all_assignments_f  paa
    WHERE  fu.user_id       = in_user_id
    AND    paa.person_id    = fu.employee_id
    AND    paa.primary_flag = 'Y'
    AND    id_target_date BETWEEN paa.effective_start_date
                              AND paa.effective_end_date
    ;
*/
    ---------------------------------------------------------
    -- 対象日が発令日以上の場合、拠点コード(新)を戻す
    -- 対象日が発令日より前の場合、拠点コード(旧)を戻す
    ---------------------------------------------------------
    IF (id_target_date >= to_date(replace(lv_start_date,'/',null),'yyyymmdd')) THEN
      return lv_basecode_new;       -- 拠点コード(新)
    ELSE
      return lv_basecode_old;       -- 拠点コード(旧)
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

/************************************************************************
 * Function Name   : get_case_quantity
 * Description     : 品目コード、数量(品目の基準単位とする）より、
 *                   OPM品目マスタを参照し、ケース入数からケース数を算出する
 ************************************************************************/
  PROCEDURE get_case_quantity
  ( iv_item_no                IN  VARCHAR2       -- 品目コード
  , in_individual_quantity    IN  NUMBER         -- バラ数量
  , in_trunc_digits           IN  NUMBER         -- 切捨て桁数
  , on_case_quantity          OUT NUMBER         -- ケース数量
  , ov_retcode                OUT VARCHAR2       -- リターンコード
  , ov_errbuf                 OUT VARCHAR2       -- エラー・メッセージ
  , ov_errmsg                 OUT VARCHAR2       -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_case_quantity'; -- プログラム名

    -- *** ローカル変数 ***
    cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP' ;               -- 正常終了メッセージ
    cv_item_chk_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00013';     -- マスタチェックエラーメッセージ
    cv_item_chk_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'item';                 --   トークン名１
    cv_item_chk_msg_tkn_val1  CONSTANT VARCHAR2(100) := '品目コード';           --   トークンセット値１
    cv_item_chk_msg_tkn_lbl2  CONSTANT VARCHAR2(100) := 'value';                --   トークン名２
    lv_num_of_cases           ic_item_mst_b.attribute11%type;  -- ケース入数
    ln_case_quantity          number;
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;

    ---------------------------------------------------------
    -- OPM品目マスタよりケース入数を取得
    ---------------------------------------------------------
    BEGIN
      SELECT iimb.attribute11
      INTO   lv_num_of_cases
      FROM   ic_item_mst_b iimb
      WHERE  iimb.item_no = iv_item_no
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_case_quantity   := null;
        ov_retcode         := cv_status_error;
        ov_errmsg          := xxccp_common_pkg.get_msg(
                                        iv_application  => cv_msg_application
                                       ,iv_name         => cv_item_chk_msg
                                       ,iv_token_name1  => cv_item_chk_msg_tkn_lbl1
                                       ,iv_token_value1 => cv_item_chk_msg_tkn_val1
                                       ,iv_token_name2  => cv_item_chk_msg_tkn_lbl2
                                       ,iv_token_value2 => iv_item_no
                                       );
        RETURN;
    END;

    ---------------------------------------------------------
    -- ケース数量算出
    ---------------------------------------------------------
    ln_case_quantity  :=  TRUNC(in_individual_quantity / NVL(TO_NUMBER(lv_num_of_cases),1),in_trunc_digits);

    ---------------------------------------------------------
    -- 正常終了：戻り値設定
    ---------------------------------------------------------
    on_case_quantity   := ln_case_quantity;

  EXCEPTION
    WHEN OTHERS THEN
      on_case_quantity := NULL;
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END;

/************************************************************************
 * Procedure Name  : delete_upload_table
 * Description     : ファイルアップロードインターフェーステーブルの
 *                   データを削除する
 ************************************************************************/
  PROCEDURE delete_upload_table
  ( in_file_id    IN  NUMBER          -- ファイルＩＤ
  , ov_retcode    OUT VARCHAR2        -- リターンコード
  , ov_errbuf     OUT VARCHAR2        -- エラー・メッセージ
  , ov_errmsg     OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'delete_upload_table';      -- プログラム名

    -- *** ローカル変数 ***
    cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP' ;                   -- 正常終了メッセージ
    cv_lock_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';         -- マスタチェックエラーメッセージ
    cv_lock_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'table';                    --   トークン名１
    cv_lock_err_msg_tkn_val1  CONSTANT VARCHAR2(100) := 'ファイルアップロードI/F';  --   トークンセット値１
    ln_file_id                xxccp_mrp_file_ul_interface.file_id%type;
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;

    ----------------------------------------
    -- アップロードＩＦテーブルロック
    ----------------------------------------
    BEGIN
      SELECT file_id
      INTO   ln_file_id
      FROM   xxccp_mrp_file_ul_interface
      WHERE  file_id = in_file_id
      FOR UPDATE OF file_id NOWAIT
      ;
    EXCEPTION
      WHEN resource_busy_expt     -- リソースビジー（ロック中）
      OR   NO_DATA_FOUND          -- 対象データ無し
      THEN
        ov_retcode   := cv_status_error;
        ov_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_application
                             ,iv_name         => cv_lock_err_msg
                             ,iv_token_name1  => cv_lock_err_msg_tkn_lbl1
                             ,iv_token_value1 => cv_lock_err_msg_tkn_val1
                             );
        RETURN;
    END;

    ----------------------------------------
    -- アップロードＩＦテーブル削除
    ----------------------------------------
    DELETE
    FROM   xxccp_mrp_file_ul_interface
    WHERE  file_id = in_file_id
    ;
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode   := cv_status_error;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END;

/************************************************************************
 * Procedure Name  : chk_date_format
 * Description     : 日付型チェック関数
 ************************************************************************/
  FUNCTION chk_date_format
  ( iv_value      IN  VARCHAR2        -- 文字列
  , iv_format     IN  VARCHAR2        -- 書式
  )
  RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_date_format';      -- プログラム名

    -- *** ローカル変数 ***
    lv_chk_value   VARCHAR2(200);
    ld_chk_value   DATE;
  BEGIN
    -- 書式がnullの場合、FALSEを戻す
    IF (iv_format IS NULL) THEN
      RETURN FALSE;
    END IF;

    -- 書式が正しいかチェック
    lv_chk_value := TO_CHAR(SYSDATE ,iv_format);

    -- 文字列が書式通りのDATE型に変換できるかチェック
    ld_chk_value := TO_DATE(iv_value, iv_format);

    lv_chk_value := TO_CHAR(ld_chk_value ,iv_format);

    IF (lv_chk_value <> iv_value) THEN
           RETURN FALSE;
    END IF;

    RETURN TRUE;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END;
--
/************************************************************************
 * Procedure Name  : chk_number_format
 * Description     : 数値型チェック関数
 ************************************************************************/
  FUNCTION chk_number_format
  ( iv_value      IN  VARCHAR2        -- 文字列
  )
  RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_number_format';      -- プログラム名

    -- *** ローカル変数 ***
    ln_chk_value   NUMBER;
  BEGIN

    ln_chk_value := TO_NUMBER(iv_value);

    RETURN TRUE;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END;
/************************************************************************
 * Procedure Name  : put_debug_message
 * Description     : デバッグメッセージ出力関数
 ************************************************************************/
  PROCEDURE put_debug_message(
    iv_value       IN      VARCHAR2     -- 文字列
  , iov_debug_mode IN OUT  VARCHAR2     -- デバッグモード
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'put_debug_message';      -- プログラム名

    -- *** ローカル変数 ***

  BEGIN

    -- デバッグモードプロファイル値取得
    IF (iov_debug_mode IS NULL) THEN
      iov_debug_mode := FND_PROFILE.VALUE('XXCOP1_DEBUG_MODE');
    END IF;

    -- デバッグモードに設定されていたらログ出力
    IF (iov_debug_mode = 'ON') THEN
      FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => iv_value
      );
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
/************************************************************************
 * Procedure Name  : char_delim_partition
 * Description     : デリミタ文字分割関数
 ************************************************************************/
  PROCEDURE char_delim_partition(
    iv_char       IN  VARCHAR2        -- 対象文字列
  , iv_delim      IN  VARCHAR2        -- デリミタ
  , o_char_tab    OUT g_char_ttype    -- 分割結果
  , ov_retcode    OUT VARCHAR2        -- リターンコード
  , ov_errbuf     OUT VARCHAR2        -- エラー・メッセージ
  , ov_errmsg     OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'char_delim_partition';      -- プログラム名

    -- *** ローカル変数 ***
    ln_index       NUMBER := 0;          -- CSVインデックス
    ln_start       NUMBER := 1;          -- 読み取り開始位置
    ln_sep         NUMBER;               -- 区切り文字の位置
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --データのカンマ区切り
    --==============================================================
    <<divide_loop>>
    LOOP
      -- CSVインデックスをカウントアップ
      ln_index := ln_index + 1;
--
      -- 区切り文字の位置を取得
      ln_sep := NVL( INSTR( iv_char, iv_delim, ln_start ), 0 );
--
      -- 読み取り終了位置の決定
      IF ( ln_sep = 0 ) THEN
        -- 区切り文字が見つからない場合は文字列の最後までを「PL/SQL表：CSV要素」に格納して終了する
        o_char_tab( ln_index ) := SUBSTR( iv_char, ln_start );
        EXIT divide_loop;
      ELSE
        -- 区切り文字が見つかった場合はその手前までを「PL/SQL表：CSV要素」に格納する
        o_char_tab( ln_index ) := SUBSTR( iv_char, ln_start, ( ln_sep - ln_start ) );
        -- 区切り文字の直後を次回の読み取り開始位置とする
        ln_start := ln_sep + 1;
      END IF;
    END LOOP divide_loop;
--
  EXCEPTION
      WHEN OTHERS THEN
        ov_retcode   := cv_status_error;
        ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END;
/************************************************************************
 * Procedure Name  : get_upload_table_info
 * Description     : ファイルアップロードテーブル情報取得
 ************************************************************************/
  PROCEDURE get_upload_table_info(
    in_file_id     IN  NUMBER          -- ファイルID
  , iv_format      IN  VARCHAR2        -- フォーマットパターン
  , ov_upload_name OUT VARCHAR2        -- ファイルアップロード名称
  , ov_file_name   OUT VARCHAR2        -- ファイル名
  , od_upload_date OUT DATE            -- アップロード日時
  , ov_retcode     OUT VARCHAR2        -- リターンコード
  , ov_errbuf      OUT VARCHAR2        -- エラー・メッセージ
  , ov_errmsg      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'get_upload_table_info';      -- プログラム名
    cv_lookup_type     CONSTANT VARCHAR2(22)  := 'XXCCP1_FILE_UPLOAD_OBJ';     -- タイプ
    cv_enable          CONSTANT VARCHAR2(1)   := 'Y';                          -- 有効フラグ
    cd_sysdate         CONSTANT DATE          := TRUNC(SYSDATE);               -- システム日付（年月日）

    -- *** ローカル変数 ***
    lv_language        fnd_lookup_values.language%TYPE := USERENV('LANG');  -- LANGUAGE
    lv_upload_name     fnd_lookup_values.meaning%TYPE;
    lv_file_name       xxccp_mrp_file_ul_interface.file_name%TYPE;
    lv_upload_date     xxccp_mrp_file_ul_interface.creation_date%TYPE;
  BEGIN
--
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    --==============================================================
    --ファイルアップロードインタフェーステーブルの取得
    --==============================================================
    SELECT xmfui.file_name
          ,xmfui.creation_date
    INTO   lv_file_name
          ,lv_upload_date
    FROM   xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = in_file_id;
    --
    --==============================================================
    --クイックコードの取得
    --==============================================================
    SELECT flv.meaning
    INTO   lv_upload_name
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type        = cv_lookup_type
    AND    flv.lookup_code        = iv_format
    AND    flv.language           = lv_language
    AND    flv.enabled_flag       = cv_enable
    AND    cd_sysdate BETWEEN NVL(flv.start_date_active,cd_sysdate)
                          AND NVL(flv.end_date_active,cd_sysdate);
    --
    --==============================================================
    --正常終了
    --==============================================================
    ov_upload_name     := lv_upload_name;
    ov_file_name       := lv_file_name;
    od_upload_date     := lv_upload_date;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END;
--
--###########################   END   ##############################
--
END XXCOP_COMMON_PKG;
/
