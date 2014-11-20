CREATE OR REPLACE PACKAGE xxccp_ifcommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_ifcommon_pkg(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.0
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
 *  2008-10-21    1.0  Naoki.Watanabe   追加作成
 *****************************************************************************************/
--
  --EDIヘッダ・フッタ付与
  PROCEDURE add_edi_header_footer(iv_add_area       IN VARCHAR2  --付与区分
                                 ,iv_from_series    IN VARCHAR2  --ＩＦ元業務系列コード
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
                                 );
  --
  --帳票ヘッダ・フッタ付与
  PROCEDURE add_chohyo_header_footer(iv_add_area       IN VARCHAR2  --付与区分
                                    ,iv_from_series    IN VARCHAR2  --ＩＦ元業務系列コード
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
                                    );
  --
END xxccp_ifcommon_pkg;
/
