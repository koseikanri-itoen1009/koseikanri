CREATE OR REPLACE PACKAGE APPS.XXCCP008A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A03C(spec)
 * Description      : リース支払計画データCSV出力
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
 *  2012/10/05    1.00  SCSK 高崎美和    新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT   VARCHAR2,       --   エラーメッセージ #固定#
    retcode             OUT   VARCHAR2,       --   エラーコード     #固定#
    iv_contract_number  IN    VARCHAR2,       --    1.契約番号
    iv_lease_company    IN    VARCHAR2,       --    2.リース会社
    iv_object_code_01   IN    VARCHAR2,       --    3.物件コード1
    iv_object_code_02   IN    VARCHAR2,       --    4.物件コード2
    iv_object_code_03   IN    VARCHAR2,       --    5.物件コード3
    iv_object_code_04   IN    VARCHAR2,       --    6.物件コード4
    iv_object_code_05   IN    VARCHAR2,       --    7.物件コード5
    iv_object_code_06   IN    VARCHAR2,       --    8.物件コード6
    iv_object_code_07   IN    VARCHAR2,       --    9.物件コード7
    iv_object_code_08   IN    VARCHAR2,       --   10.物件コード8
    iv_object_code_09   IN    VARCHAR2,       --   11.物件コード9
    iv_object_code_10   IN    VARCHAR2        --   12.物件コード10
  );
END XXCCP008A03C;
/
