CREATE OR REPLACE PACKAGE APPS.XXCSO011A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A03C (spec)
 * Description      : 未発注リスト作成
 * MD.050           : 未発注リスト作成 (MD050_CSO_011A03)
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
 *  2014/05/12    1.0   S.Niki           main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2      --   エラーメッセージ #固定#
   ,retcode         OUT    VARCHAR2      --   エラーコード     #固定#
   ,iv_base_code    IN     VARCHAR2      -- 1.発注作成部署
   ,iv_created_by   IN     VARCHAR2      -- 2.発注作成者
   ,iv_vendor_code  IN     VARCHAR2      -- 3.仕入先
   ,iv_po_num       IN     VARCHAR2      -- 4.発注番号
   ,iv_date_from    IN     VARCHAR2      -- 5.発注作成日FROM
   ,iv_date_to      IN     VARCHAR2      -- 6.発注作成日TO
   ,iv_lease_kbn    IN     VARCHAR2      -- 7.リース区分
  );
END XXCSO011A03C;
/
