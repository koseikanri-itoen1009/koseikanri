CREATE OR REPLACE PACKAGE XXCOI001A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A02R(spec)
 * Description      : 指定された条件に紐づく入庫確認情報のリストを出力します。
 * MD.050           : 入庫未確認リスト MD050_COI_001_A02 
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.0   S.Moriyama       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
       errbuf        OUT VARCHAR2                                     --   エラーメッセージ #固定#
     , retcode       OUT VARCHAR2                                     --   エラーコード     #固定#
     , iv_base_code   IN VARCHAR2                                     --   1.拠点コード
     , iv_output_type IN VARCHAR2                                     --   2.出力区分
     , iv_date_from   IN VARCHAR2                                     --   3.出力日付（自）
     , iv_date_to     IN VARCHAR2                                     --   4.出力日付（至）
  );
END XXCOI001A02R;
/
