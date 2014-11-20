CREATE OR REPLACE PACKAGE APPS.XXCCP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP005A01C(spec)
 * Description      : 他システムからのIFファイルにおける、ヘッダ・フッタ削除します。
 * MD.050           : MD050_CCP_005_A01_IFファイルヘッダ・フッタ削除処理
 * Version          : 1.1
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
 *  2008-xx-xx    1.0   Yutaka.Kuboshima main新規作成
 *  2009-05-01    1.1   Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_file_name    IN     VARCHAR2,         --   ファイル名
    iv_other_system IN     VARCHAR2,         --   相手システム名
    iv_file_dir     IN     VARCHAR2          --   ファイルディレクトリ
  );
END XXCCP005A01C;
/
