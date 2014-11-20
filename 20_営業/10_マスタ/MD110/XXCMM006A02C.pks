CREATE OR REPLACE PACKAGE XXCMM006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM006A02C(spec)
 * Description      : 管理マスタIF出力(HHT)
 * MD.050           : 管理マスタIF出力(HHT) MD050_CMM_006_A02
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/25    1.0   SCS 福間 貴子    初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_date_from  IN     VARCHAR2,         --   1.最終更新日(開始)
    iv_date_to    IN     VARCHAR2          --   2.最終更新日(終了)
  );
END XXCMM006A02C;
/
