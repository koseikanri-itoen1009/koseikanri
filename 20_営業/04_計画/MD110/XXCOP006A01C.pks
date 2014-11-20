CREATE OR REPLACE PACKAGE APPS.XXCOP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A01C(spec)
 * Description      : 横持計画
 * MD.050           : 横持計画 MD050_COP_006_A01
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
 *  2009/01/19    1.0   Y.Goto           新規作成
 *  2009/04/07    1.1   Y.Goto           T1_0273,T1_0274,T1_0289,T1_0366,T1_0367対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT    VARCHAR2,   --   エラーメッセージ #固定#
    retcode          OUT    VARCHAR2,   --   エラーコード     #固定#
    iv_plan_type     IN     VARCHAR2,   -- 1.計画区分
    iv_shipment_from IN     VARCHAR2,   -- 2.出荷ペース計画期間(FROM)
    iv_shipment_to   IN     VARCHAR2,   -- 3.出荷ペース計画期間(TO)
    iv_forcast_type  IN     VARCHAR2    -- 4.出荷予測区分
  );
END XXCOP006A01C;
/
