CREATE OR REPLACE PACKAGE xxcmn560001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn560001c(spec)
 * Description      : トレーサビリティ
 * MD.050           : トレーサビリティ T_MD050_BPO_560
 * MD.070           : トレーサビリティ T_MD070_BPO_56A
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
 *  2008/01/08    1.0   ORACLE 岩佐智治  main新規作成
 *
 *****************************************************************************************/
--
  -- コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_item_code    IN     VARCHAR2,         -- 1.品目コード
    iv_lot_no       IN     VARCHAR2,         -- 2.ロットNo
    iv_out_control  IN     VARCHAR2          -- 3.出力制御
  );
END xxcmn560001c;
/
