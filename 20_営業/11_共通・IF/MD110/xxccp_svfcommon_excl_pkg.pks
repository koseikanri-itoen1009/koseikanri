create or replace PACKAGE apps.xxccp_svfcommon_excl_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name           : xxccp_svfcommon_excl_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  submit_svf_request        P           SVF帳票共通関数(専用マネージャ実行のSVFコンカレントの起動)
 *  no_data_msg               F    CHAR   SVF帳票共通関数(0件出力メッセージ)
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2018-07-11    1.0  Kazuhiro.Nara    新規作成 [障害E_本稼動_15005]対応
 *
 *****************************************************************************************/
--
  -- ===============================
  -- PUBLIC PROCEDURE
  -- ===============================
  --
  --SVF帳票共通関数(SVFコンカレントの起動)
  PROCEDURE submit_svf_request(ov_retcode      OUT VARCHAR2               --リターンコード
                              ,ov_errbuf       OUT VARCHAR2               --エラーメッセージ
                              ,ov_errmsg       OUT VARCHAR2               --ユーザー・エラーメッセージ
                              ,iv_conc_name    IN  VARCHAR2               --コンカレント名
                              ,iv_file_name    IN  VARCHAR2               --出力ファイル名
                              ,iv_file_id      IN  VARCHAR2               --帳票ID
                              ,iv_output_mode  IN  VARCHAR2  DEFAULT 1    --出力区分
                              ,iv_frm_file     IN  VARCHAR2               --フォーム様式ファイル名
                              ,iv_vrq_file     IN  VARCHAR2               --クエリー様式ファイル名
                              ,iv_org_id       IN  VARCHAR2               --ORG_ID
                              ,iv_user_name    IN  VARCHAR2               --ログイン・ユーザ名
                              ,iv_resp_name    IN  VARCHAR2               --ログイン・ユーザの職責名
                              ,iv_doc_name     IN  VARCHAR2  DEFAULT NULL --文書名
                              ,iv_printer_name IN  VARCHAR2  DEFAULT NULL --プリンタ名
                              ,iv_request_id   IN  VARCHAR2               --要求ID
                              ,iv_nodata_msg   IN  VARCHAR2               --データなしメッセージ
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD START
                              ,iv_excl_code    IN  VARCHAR2               --SVF専用マネージャコード
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD END
                              ,iv_svf_param1   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ1
                              ,iv_svf_param2   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ2
                              ,iv_svf_param3   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ3
                              ,iv_svf_param4   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ4
                              ,iv_svf_param5   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ5
                              ,iv_svf_param6   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ6
                              ,iv_svf_param7   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ7
                              ,iv_svf_param8   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ8
                              ,iv_svf_param9   IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ9
                              ,iv_svf_param10  IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ10
                              ,iv_svf_param11  IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ11
                              ,iv_svf_param12  IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ12
                              ,iv_svf_param13  IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ13
                              ,iv_svf_param14  IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ14
                              ,iv_svf_param15  IN  VARCHAR2  DEFAULT NULL --svf可変パラメータ15
                              );
--
  -- ===============================
  -- PUBLIC FUNCTION
  -- ===============================
  --
  --SVF帳票共通関数(0件出力メッセージ)
  FUNCTION no_data_msg
    RETURN VARCHAR2;
  --
END xxccp_svfcommon_excl_pkg;
/
