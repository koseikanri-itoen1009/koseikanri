create or replace PACKAGE BODY xxcmn_common4_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2012. All rights reserved.
 *
 * Package Name           : xxcmn_common4_pkg(body)
 * Description            : 共通関数4
 * MD.070(CMD.050)        : T_MD050_BPO_000_共通関数4.xls
 * Version                : 1.0
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_syori_date         F  DATE  処理日付取得
 *  get_purge_period       F  NUM   バックアップ期間/パージ期間取得関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/18   1.00  SCSK 宮本直樹    新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name    CONSTANT VARCHAR2(100) := 'xxcmn_common4_pkg';       -- パッケージ名
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- 正常
  gn_ret_error     CONSTANT NUMBER := 1; -- エラー
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
--
/*****************************************************************************************
 * Function Name     : get_syori_date
 * Description       : 処理日付取得
 * Version           : 1.00
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/18    1.00 SCSK 宮本直樹    新規作成
 *
 *****************************************************************************************/
  FUNCTION get_syori_date 
    RETURN DATE                         --処理日付を日付型で戻す。エラーの場合はNULLを戻す。
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_syori_date' ;  --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_work       VARCHAR2(100);        --一時格納用
    ld_result     DATE;                 --処理結果を格納
--
  BEGIN

    --lv_作業用 := TO_CHAR(SYSDATE,'YYYY/MM/DD');
    --ld_result := TO_DATE(lv_作業用,'YYYY/MM/DD');
    lv_work       := TO_CHAR(SYSDATE,'YYYY/MM/DD');
    ld_result     := TO_DATE(lv_work,'YYYY/MM/DD');

    RETURN ld_result;

  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_syori_date ;

/*****************************************************************************************
 * Function Name     : get_purge_period
 * Description      : バックアップ期間/パージ期間取得関数
 * Version          : 1.00
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/18    1.00 SCSK 宮本直樹    新規作成
 *
 *****************************************************************************************/
  FUNCTION get_purge_period (
    iv_purge_type IN VARCHAR2,              --パージタイプ(0:パージ期間 1:バックアップ期間)
    iv_purge_code IN VARCHAR2)              --パージコード
    RETURN NUMBER                           --パージ期間を数値で戻す。エラーの場合はNULLを戻す。
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_purge_period' ;  --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    /*
    lc_lookup_type CONSTANT VARCHAR2(20) :=  'XXCMN_PURGE_PERIOD';
    lc_enable_y    CONSTANT VARCHAR2(1)  :=  'Y';

     ln_result          NUMBER;
     ln_purge_period  NUMBER;
     ln_backup_period NUMBER;

     lt_attribute1      fnd_lookup_values.attribute1%TYPE;
     lt_attribute2      fnd_lookup_values.attribute2%TYPE;
     ld_処理日        DATE;
    */
    lc_lookup_type    CONSTANT VARCHAR2(20) :=  'XXCMN_PURGE_PERIOD';   --汎用マスタより取得するキー(LOOK_UP_TYPE)
    lc_enable_y       CONSTANT VARCHAR2(1)  :=  'Y';                    --汎用マスタのenabledカラム判定用
--
    -- *** ローカル変数 ***
    lv_errmsg         VARCHAR2(5000); -- エラーメッセージ

    ln_result         NUMBER;                 --処理結果を格納
    ln_purge_period   NUMBER;                 --パージ期間を格納
    ln_backup_period  NUMBER;                 --バックアップ期間を格納

    lt_attribute1     fnd_lookup_values.attribute1%TYPE;    --DFF1の値
    lt_attribute2     fnd_lookup_values.attribute2%TYPE;    --DFF2の値
    ld_syori_date     DATE;                                 --処理日
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
    --パージタイプがNULLの場合はエラー
    /*
    IF iv_purge_type IS NULL THEN
        RAISE パラメータ不正例外
    END IF;
    */
    IF iv_purge_type IS NULL THEN
      RETURN NULL; --パラメータ不正でNULLを戻す
    END IF;
--
    --パージタイプが'0','1'以外の場合はエラー
    /*
    IF iv_purge_type NOT IN ('0','1') THEN
        RAISE パラメータ不正例外
    END IF;
    */
    IF iv_purge_type NOT IN ('0','1') THEN
      RETURN NULL; --パラメータ不正でNULLを戻す
    END IF;
--
    --パージコードがNULLの場合はエラー
    /*
    IF iv_purge_code IS NULL THEN
        RAISE パラメータ不正例外
    END IF;
    */
    IF iv_purge_code IS NULL THEN
      RETURN NULL; --パラメータ不正でNULLを戻す
    END IF;


    --ルックアップの有効日付を検証するために、処理日付を取得
    --ld_処理日 := 処理日付取得関数
    ld_syori_date := get_syori_date;

    BEGIN
      /*
      SELECT
          flv.attribute1,
          flv.attribute2
      INTO
          lt_attribute1,
          lt_attribute2
      FROM
          fnd_lookup_values flv
      WHERE
              flv.lookup_type  = lc_lookup_type
          AND lookup_code      = iv_purge_code
          AND flv.language     = userenv('LANG')
          AND flv.enabled_flag = lc_enable_y
          AND ld_処理日        BETWEEN NVL( flv.start_date_active, ld_処理日 )
                                   AND NVL( flv.end_date_active  , ld_処理日 );
      */
      --ルックアップからパージ期間を取得する
      SELECT
          flv.attribute1  AS attribute1,         --パージ期間
          flv.attribute2  AS attribute2          --バックアップ期間
      INTO
          lt_attribute1,
          lt_attribute2
      FROM
          fnd_lookup_values flv   --汎用マスタ
      WHERE
              flv.lookup_type  = lc_lookup_type
          AND flv.lookup_code  = iv_purge_code
          AND flv.language     = userenv('LANG')
          AND flv.enabled_flag = lc_enable_y
          AND ld_syori_date    BETWEEN NVL( flv.start_date_active, ld_syori_date)
                                   AND NVL( flv.end_date_active  , ld_syori_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       --ルックアップから値を取得できなかった場合は、NULLを戻す
        RETURN NULL;
    END;

    --DFFより取得した値はVARCHAR型なので、数値に変換
    BEGIN
      /*
      ln_パージ期間 := TO_NUMBER(lv_attribute1);
      ln_バックアップ期間 := TO_NUMBER(lv_attribute2);
      */
      ln_purge_period   := TO_NUMBER(lt_attribute1);  --パージ期間
      ln_backup_period  := TO_NUMBER(lt_attribute2);  --バックアップ期間
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END;

    --引数のパージタイプにより、戻り値を設定
    /*
    iv_パージタイプが"0"の場合
          ln_結果 := ln_パージ期間
    iv_パージタイプが"1"の場合
          ln_結果 := ln_バックアップ期間
    */
    CASE iv_purge_type
      WHEN '0' THEN
        ln_result := ln_purge_period;
      WHEN '1' THEN
        ln_result := ln_backup_period;
    END CASE;
--
    /*
    RETURN ln_結果;
    */
    RETURN ln_result;

  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  固定部 END   #########################################
--
  END get_purge_period ;

END xxcmn_common4_pkg;
/
