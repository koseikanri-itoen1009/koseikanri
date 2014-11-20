CREATE OR REPLACE PACKAGE XXCSM002A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A09C(spec)
 * Description      : 年間商品計画（営業原価）チェックリスト出力
 * MD.050           : 年間商品計画（営業原価）チェックリスト出力 MD050_CSM_002_A09
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
 *  2008-12-11    1.0   K.Yamada         main新規作成
 *  2012-12-13    1.1   SCSK K.Taniguchi [E_本稼動_09949] 新旧原価選択可能対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT VARCHAR2,          --   エラーメッセージ #固定#
    retcode         OUT VARCHAR2,          --   エラーコード     #固定#
    iv_p_yyyy       IN  VARCHAR2,          -- 1.対象年度
    iv_p_kyoten_cd  IN  VARCHAR2,          -- 2.拠点コード
--//+UPD START E_本稼動_09949 K.Taniguchi
--    iv_p_level      IN  VARCHAR2           -- 3.階層
    iv_p_level      IN  VARCHAR2,          -- 3.階層
    iv_p_new_old_cost_class
                    IN  VARCHAR2           -- 4.新旧原価区分
--//+UPD END E_本稼動_09949 K.Taniguchi
  );
END XXCSM002A09C;
/
