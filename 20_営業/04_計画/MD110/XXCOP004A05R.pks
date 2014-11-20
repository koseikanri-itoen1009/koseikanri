CREATE OR REPLACE PACKAGE XXCOP004A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A05R(spec)
 * Description      : 引取計画立案表出力ワーク登録
 * MD.050           : 引取計画立案表 MD050_COP_004_A05
 * Version          : 1.4
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
 *  2008/12/29    1.0  SCS.Kikuchi       main新規作成
 *  2009/03/04    1.1  SCS.Kikuchi       SVF結合対応
 *  2009/04/28    1.2  SCS.Kikuchi       T1_0645,T1_0838対応
 *  2009/06/10    1.3  SCS.Kikuchi       T1_1411対応
 *  2009/06/23    1.4  SCS.Kikuchi       障害:0000025対応
 *  2009/10/13    1.5  SCS.Fukada        障害:E_T3_00556対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT VARCHAR2,      --   エラーメッセージ #固定#
    retcode             OUT VARCHAR2,      --   エラーコード     #固定#
    iv_prod_class_code  IN  VARCHAR2,      -- 2.商品区分
    iv_base_code        IN  VARCHAR2       -- 3.拠点
   );
END XXCOP004A05R;
/
