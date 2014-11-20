CREATE OR REPLACE PACKAGE BODY apps.xxccp_ifcommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_ifcommon_pkg(body)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.5
 *
 * Program List
 *  --------------------      ---- -----   --------------------------------------------------
 *   Name                     Type  Ret     Description
 *  --------------------      ---- -----   --------------------------------------------------
 *  add_edi_header_footer     P     VAR    EDIヘッダ・フッタ付与
 *  add_chohyo_header_footer  P     VAR    帳票ヘッダ・フッタ付与
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-16    1.0  Naoki.Watanabe   新規作成
 *  2009-02-10    1.1  Shinya.Kayahara  日付フォーマット修正
 *  2009-04-24    1.2  Masayuki.Sano    障害番号T1_0524,T1_0755対応
 *                                      ・可変長⇒固定長へ変更。
 *  2009-05-01    1.3  Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
 *  2009-05-22    1.4  Masayuki.Sano    障害番号T1_1145対応
 *                                      ・データ種コード:81のレコード長変更(775⇒776)
 *  2011-10-06    1.5  Kazuyuki.Kiriu   E_本稼動_07906対応
 *                                      ・流通ＢＭＳ対応
 *****************************************************************************************/
--  
  /**********************************************************************************
   * Procedure Name   : add_edi_header_footer
   * Description      : EDIヘッダ・フッタ付与
   ***********************************************************************************/
  PROCEDURE add_edi_header_footer(iv_add_area       IN VARCHAR2  --付与区分
                                 ,iv_from_series    IN VARCHAR2  --IF元業務系列コード
                                 ,iv_base_code      IN VARCHAR2  --拠点コード
                                 ,iv_base_name      IN VARCHAR2  --拠点名称
                                 ,iv_chain_code     IN VARCHAR2  --チェーン店コード
                                 ,iv_chain_name     IN VARCHAR2  --チェーン店名称
                                 ,iv_data_kind      IN VARCHAR2  --データ種コード
                                 ,iv_row_number     IN VARCHAR2  --並列処理番号
                                 ,in_num_of_records IN NUMBER    --レコード件数
                                 ,ov_retcode        OUT VARCHAR2 --リターンコード
                                 ,ov_output         OUT VARCHAR2 --出力値
                                 ,ov_errbuf         OUT VARCHAR2 --エラーメッセージ
                                 ,ov_errmsg         OUT VARCHAR2 --ユーザー・エラーメッセージ
                                 )
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxccp_ifcommon_pkg.add_edi_header_footer';
-- 2009-04-24 Ver.1.2 Add By Masayuki.Sano Start
    -- プロファイル：EDIヘッダ・フッダのレコード長(データ種コード)
    cv_data_kind_21       CONSTANT VARCHAR2(2) := '21';   -- データ種コード:21
    cv_data_kind_22       CONSTANT VARCHAR2(2) := '22';   -- データ種コード:22
    cv_data_kind_51       CONSTANT VARCHAR2(2) := '51';   -- データ種コード:51
    cv_data_kind_81       CONSTANT VARCHAR2(2) := '81';   -- データ種コード:81
-- 2011-10-06 Ver.1.5 Update By Kazuyuki.Kiriu Start
--    cv_len_of_record_21   CONSTANT NUMBER      := '4500'; -- 21のレコード長
--    cv_len_of_record_22   CONSTANT NUMBER      := '4500'; -- 22のレコード長
--    cv_len_of_record_51   CONSTANT NUMBER      := '1000'; -- 51のレコード長
    cv_len_of_record_21   CONSTANT NUMBER      := 8000; -- 21のレコード長
    cv_len_of_record_22   CONSTANT NUMBER      := 8000; -- 22のレコード長
    cv_len_of_record_51   CONSTANT NUMBER      := 3000; -- 51のレコード長
-- 2011-10-06 Ver.1.5 Update By Kazuyuki.Kiriu End
-- 2009-05-22 Ver.1.4 Update By Masayuki.Sano Start
--    cv_len_of_record_81   CONSTANT NUMBER      := '775';  -- 81のレコード長
    cv_len_of_record_81   CONSTANT NUMBER      := '776';  -- 81のレコード長
-- 2009-05-22 Ver.1.4 Update By Masayuki.Sano End
    cv_len_of_record_def  CONSTANT NUMBER      := '4500'; -- C1,その他のレコード長
-- 2009-04-24 Ver.1.2 Add By Masayuki.Sano End
    -- ================                                                           -- プログラム名
    -- ローカル変数定義
    -- ================
-- 2009-04-24 Ver.1.2 Update By Masayuki.Sano Start
--    lv_out_put         VARCHAR2(1000);                          --出力値格納用変数
    lv_out_put         VARCHAR2(5000);                          --出力値格納用変数
    ln_length_rec      NUMBER;                                  --1レコードの長さ(byte)_文字列
-- 2009-04-24 Ver.1.2 Update By Masayuki.Sano End
    ln_length_val      NUMBER := LENGTH(in_num_of_records) - 7; --下8桁を出力する際に使用する変数
    lv_error_parameter VARCHAR2(1000);                          --トークン用変数
    -- ================
    -- ユーザー定義例外
    -- ================
    in_parameter_expt   EXCEPTION; --必須項目がNULLの場合
    parameter_over_expt EXCEPTION; --INパラメータが指定桁数を超える場合
    add_area_expt       EXCEPTION; --付与区分が'H'でも'F'でもNULLでもない場合
  --
  BEGIN
    --
    --付与区分のNULLチェック
    IF (iv_add_area IS NULL) THEN
      lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_ADD_AREA');
      RAISE in_parameter_expt;
    END IF;
    --付与区分が'H'の場合
    IF (iv_add_area = 'H') THEN
      --必須項目のNULLチェック
      IF (iv_from_series  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_FROM_SERIES');
        RAISE in_parameter_expt;
      ELSIF (iv_base_code  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_base_name  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_NAME');
        RAISE in_parameter_expt;
      ELSIF (iv_chain_code IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_chain_name IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_NAME');
        RAISE in_parameter_expt;
      ELSIF (iv_data_kind  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_DATA_KIND');
        RAISE in_parameter_expt;
      ELSIF (iv_row_number IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_ROW_NUMBER');
        RAISE in_parameter_expt;
      ELSIF (LENGTHB(iv_from_series) > 2) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_FROM_SERIES');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_base_code) > 4) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_CODE');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_base_name) > 40) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_NAME');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_chain_code) > 4) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_CODE');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_chain_name) > 40) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_NAME');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_data_kind) > 2) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_DATA_KIND');
        RAISE parameter_over_expt;
      ELSIF (LENGTHB(iv_row_number) > 2) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_ROW_NUMBER');
        RAISE parameter_over_expt;
      END IF;
      --
      --出力値を変数に格納
      lv_out_put := FND_PROFILE.VALUE('XXCCP1_IF_HEADER')                    --レコード区分:H
                 || RPAD(iv_from_series,2,' ')                               --IF元業務系列コード
                 || FND_PROFILE.VALUE('XXCCP1_IF_TO_EDI_SERIES') --IF先業務系列コード
                 || RPAD(iv_base_code,4,' ')                     --拠点(部門)コード
                 || RPAD(iv_base_name,40,' ')                    --拠点名
                 || RPAD(iv_chain_code,4,' ')                    --チェーン店コード
                 || RPAD(iv_chain_name,40,' ')                   --チェーン店名
                 || RPAD(iv_data_kind,2,' ')                     --データ種コード
                 || iv_row_number                                --並列処理番号
                 || TO_CHAR(SYSDATE,'YYYYMMDD')                  --データ作成日
--20090210 修正_萱原 start--
--                 || TO_CHAR(SYSDATE,'HHMMSS')                    --データ作成時刻
                 || TO_CHAR(SYSDATE,'HH24MISS')                  --データ作成時刻
--20090210 修正_萱原 end--
                 ;
      --
    --付与区分が'F'の場合
    ELSIF (iv_add_area = 'F') THEN
      --
      --データ件数のNULLチェック
      IF (in_num_of_records IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_NUM_OF_RECORDS');
        RAISE in_parameter_expt;
      END IF;
      --
      --出力値を変数に格納
      --データ件数が8桁以下の場合
      IF (LENGTH(in_num_of_records) <= 8) THEN
        --8桁に揃えて格納
        lv_out_put := FND_PROFILE.VALUE('XXCCP1_IF_FOOTER')     --レコード区分:F
                   || LPAD(in_num_of_records,8,'0')            --データ件数
                   ;
      --データ件数が8桁より大きい場合
      ELSIF (LENGTH(in_num_of_records) > 8) THEN
        --下8桁を格納
        lv_out_put := FND_PROFILE.VALUE('XXCCP1_IF_FOOTER')     --レコード区分:F
                   || SUBSTR(in_num_of_records,ln_length_val)  --データ件数
                   ;
      END IF;
      --
    ELSE
      RAISE add_area_expt;
    END IF;
    --
-- 2009-04-24 Ver.1.2 Add By Masayuki.Sano Start
    CASE iv_data_kind
      WHEN cv_data_kind_21 THEN
        ln_length_rec := cv_len_of_record_21;   -- データ種コード"21"の場合のレコード長
      WHEN cv_data_kind_22 THEN
        ln_length_rec := cv_len_of_record_22;   -- データ種コード"22"の場合のレコード長
      WHEN cv_data_kind_51 THEN
        ln_length_rec := cv_len_of_record_51;   -- データ種コード"51"の場合のレコード長
      WHEN cv_data_kind_81 THEN
        ln_length_rec := cv_len_of_record_81;   -- データ種コード"81"の場合のレコード長
      ELSE
        ln_length_rec := cv_len_of_record_def;  -- 上記以外の場合はデータ種コード"C1"と同一
    END CASE;
--
-- 2009-04-24 Ver.1.2 Add By Masayuki.Sano End
    --正常終了時
    ov_retcode := xxccp_common_pkg.set_status_normal;
-- 2009-04-24 Ver.1.2 Add By Masayuki.Sano Start
--    ov_output  := lv_out_put; --アウトパラメータに出力値を格納
    ov_output  := RPAD(lv_out_put, TO_NUMBER(ln_length_rec), ' '); --アウトパラメータに出力値を格納
-- 2009-04-24 Ver.1.2 Add By Masayuki.Sano End
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    --
  EXCEPTION
    --必須項目がNULLの場合
    WHEN in_parameter_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10004'
                      ,iv_token_name1  => 'ITEM'
                      ,iv_token_value1 => lv_error_parameter
                    );
    --INパラメータが指定桁数を超えている場合
    WHEN parameter_over_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => 'XXCCP'
                      ,iv_name         => 'APP-XXCCP1-10006'
                      ,iv_token_name1  => 'ITEM'
                      ,iv_token_value1 => lv_error_parameter
                    );
    --付与区分が'H'、'F'、NULLのいずれでもない場合
    WHEN add_area_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL; --アウトパラメータに出力値を格納
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10005'
                    );
    --異常終了時
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := SUBSTRB(cv_prg_name||SQLERRM,1,5000);
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10003'
                    );
    --
  END add_edi_header_footer;
  --
--
  /**********************************************************************************
   * Procedure Name   : add_chohyo_header_footer
   * Description      : 帳票ヘッダ・フッタ付与
   ***********************************************************************************/
  PROCEDURE add_chohyo_header_footer(iv_add_area       IN VARCHAR2  --付与区分
                                    ,iv_from_series    IN VARCHAR2  --IF元業務系列コード
                                    ,iv_base_code      IN VARCHAR2  --拠点コード
                                    ,iv_base_name      IN VARCHAR2  --拠点名称
                                    ,iv_chain_code     IN VARCHAR2  --チェーン店コード
                                    ,iv_chain_name     IN VARCHAR2  --チェーン店名称
                                    ,iv_data_kind      IN VARCHAR2  --データ種コード
                                    ,iv_chohyo_code    IN VARCHAR2  --帳票コード
                                    ,iv_chohyo_name    IN VARCHAR2  --帳票表示名
                                    ,in_num_of_item    IN NUMBER    --項目数
                                    ,in_num_of_records IN NUMBER    --データ件数
                                    ,ov_retcode        OUT VARCHAR2 --リターンコード
                                    ,ov_output         OUT VARCHAR2 --出力値
                                    ,ov_errbuf         OUT VARCHAR2 --エラーメッセージ
                                    ,ov_errmsg         OUT VARCHAR2 --ユーザー・エラーメッセージ
                                    )
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxccp_ifcommon_pkg.add_chohyo_header_footer';
    cv_knot_str   CONSTANT VARCHAR2(1)   := '"';                                     -- プログラム名
    cv_dlim_str   CONSTANT VARCHAR2(1)   := ',';
    -- ================
    -- ローカル変数定義
    -- ================
    lv_out_put         VARCHAR2(1000);                          --出力値格納用変数
    lv_error_parameter VARCHAR2(1000);                          --トークン用変数
    -- ================
    -- ユーザー定義例外
    -- ================
    in_parameter_expt EXCEPTION; --必須項目がNULLの場合
    add_area_expt     EXCEPTION; --付与区分が'H'、'F'、NULLのいずれでもない場合
  --
  BEGIN
    --
    --付与区分のNULLチェック
    IF (iv_add_area IS NULL) THEN
      lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_ADD_AREA');
      RAISE in_parameter_expt;
    END IF;
    --付与区分が'H'の場合
    IF (iv_add_area = 'H') THEN
      --必須項目のNULLチェック
      IF (iv_from_series  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_FROM_SERIES');
        RAISE in_parameter_expt;
      ELSIF (iv_base_code  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_base_name  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_BASE_NAME');
        RAISE in_parameter_expt;
      ELSIF (iv_chain_code IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_chain_name IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHAIN_NAME');
        RAISE in_parameter_expt;
      ELSIF (iv_data_kind  IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_DATA_KIND');
        RAISE in_parameter_expt;
      ELSIF (iv_chohyo_code IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHOHYO_CODE');
        RAISE in_parameter_expt;
      ELSIF (iv_chohyo_name IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_CHOHYO_NAME');
        RAISE in_parameter_expt;
      ELSIF (in_num_of_item IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_NUM_OF_ITEM');
        RAISE in_parameter_expt;
      END IF;
      --出力値を変数に格納
      lv_out_put := cv_knot_str || FND_PROFILE.VALUE('XXCCP1_IF_HEADER') || cv_knot_str
                 || cv_dlim_str                                               --レコード区分:"H"
                 || cv_knot_str || FND_PROFILE.VALUE('XXCCP1_IF_TO_CHOHYO_SERIES') || cv_knot_str
                 || cv_dlim_str                                               --IF先業務系列コード
                 || cv_knot_str || iv_from_series || cv_knot_str
                 || cv_dlim_str                                               --IF元業務系列コード
                 || cv_knot_str || iv_base_code || cv_knot_str
                 || cv_dlim_str                                               --拠点(部門)コード
                 || cv_knot_str || iv_base_name || cv_knot_str
                 || cv_dlim_str                                               --拠点名
                 || cv_knot_str || iv_chain_code || cv_knot_str
                 || cv_dlim_str                                               --チェーン店コード
                 || cv_knot_str || iv_chain_name || cv_knot_str
                 || cv_dlim_str                                               --チェーン店名
                 || cv_knot_str || iv_data_kind || cv_knot_str
                 || cv_dlim_str                                               --データ種コード
                 || cv_knot_str || iv_chohyo_code || cv_knot_str
                 || cv_dlim_str                                               --帳票コード
                 || cv_knot_str || iv_chohyo_name || cv_knot_str
                 || cv_dlim_str                                               --帳票表示名
                 || TO_CHAR(SYSDATE,'YYYYMMDD')
                 || cv_dlim_str                                               --データ作成日
--20090210 修正_萱原 start--
--                 || TO_CHAR(SYSDATE,'HHMMSS')
                 || TO_CHAR(SYSDATE,'HH24MISS')
--20090210 修正_萱原 end--
                 || cv_dlim_str                                               --データ作成時刻
                 || in_num_of_item                                            --項目数
                 ;
    --
    --付与区分が'F'の場合
    ELSIF (iv_add_area = 'F') THEN
      --データ件数がNULLの場合
      IF (in_num_of_records IS NULL) THEN
        lv_error_parameter := FND_PROFILE.VALUE('XXCCP1_NUM_OF_RECORDS');
        RAISE in_parameter_expt;
      END IF;
      --出力値を変数に格納
      lv_out_put := cv_knot_str || FND_PROFILE.VALUE('XXCCP1_IF_FOOTER') || cv_knot_str
                 || cv_dlim_str                                                  --レコード区分:"F"
                 || in_num_of_records                                                  --データ件数
                 ;
    ELSE
      RAISE add_area_expt;
    END IF;
    --正常終了時
    ov_retcode := xxccp_common_pkg.set_status_normal;
    ov_output  := lv_out_put;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    --
  EXCEPTION
    --必須項目がNULLの場合
    WHEN in_parameter_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10004'
                      ,iv_token_name1  => 'ITEM'
                      ,iv_token_value1 => lv_error_parameter
                    );
    --付与区分が'H'、'F'、NULLのいずれでもない場合
    WHEN add_area_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL; --アウトパラメータに出力値を格納
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10005'
                    );
    --異常終了時
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_output  := NULL;
      ov_errbuf  := SUBSTRB(cv_prg_name||SQLERRM,1,5000);
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application => 'XXCCP'
                      ,iv_name        => 'APP-XXCCP1-10003'
                    );
    --
  END add_chohyo_header_footer;
  --
END xxccp_ifcommon_pkg;
/
