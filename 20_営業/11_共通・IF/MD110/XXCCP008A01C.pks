create or replace
PACKAGE XXCCP008A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A01C(spec)
 * Description      : リース契約データCSV出力
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
 *  2012/10/30    1.0   SCSK 古山        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT   VARCHAR2,       --   エラーメッセージ #固定#
    retcode             OUT   VARCHAR2,       --   エラーコード     #固定#
    iv_contract_number  IN    VARCHAR2,       --   01.契約番号
    iv_lease_company    IN    VARCHAR2,       --   02.リース会社
    iv_object_code_01   IN    VARCHAR2,       --   03.物件コード1
    iv_object_code_02   IN    VARCHAR2,       --   04.物件コード2
    iv_object_code_03   IN    VARCHAR2,       --   05.物件コード3
    iv_object_code_04   IN    VARCHAR2,       --   06.物件コード4
    iv_object_code_05   IN    VARCHAR2,       --   07.物件コード5
    iv_object_code_06   IN    VARCHAR2,       --   08.物件コード6
    iv_object_code_07   IN    VARCHAR2,       --   09.物件コード7
    iv_object_code_08   IN    VARCHAR2,       --   10.物件コード8
    iv_object_code_09   IN    VARCHAR2,       --   11.物件コード9
    iv_object_code_10   IN    VARCHAR2        --   12.物件コード10
  );
END XXCCP008A01C;
/