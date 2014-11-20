CREATE OR REPLACE PACKAGE XXCOP004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A04R(spec)
 * Description      : 引取計画チェックリスト出力ワーク登録
 * MD.050           : 引取計画チェックリスト MD050_COP_004_A04
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
 *  2008/11/03    1.0  SCS.Kikuchi       main新規作成
 *  2009/03/03    1.1  SCS.Kikuchi       SVF結合対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_target_month     IN  VARCHAR2,         -- 1.対象年月
    iv_prod_class_code  IN  VARCHAR2,         -- 2.商品区分
    iv_base_code        IN  VARCHAR2,         -- 3.拠点
    iv_whse_code        IN  VARCHAR2          -- 4.出荷管理先
   );
END XXCOP004A04R;
/
