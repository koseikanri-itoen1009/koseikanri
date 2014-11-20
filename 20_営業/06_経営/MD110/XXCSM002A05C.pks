--//+UPD START 2009/02/13 CT017 S.Son
--CREATE OR REPLACE PACKAGE XXCSM002A05
CREATE OR REPLACE PACKAGE XXCSM002A05C
--//+UPD END 2009/02/13 CT017 S.Son
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A05(spec)
 * Description      : 商品計画単品別按分処理
 * MD.050           : 商品計画単品別按分処理 MD050_CSM_002_A05
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
 *  2008/11/17    1.0   sonshubai        新規作成
 *  2009/02/13    1.1   S.Son            [障害CT_017] コンパイルエラー対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         -- エラーメッセージ
    retcode       OUT    VARCHAR2,         -- エラーコード
    iv_kyoten_cd  IN     VARCHAR2,         -- 1.拠点コード
    iv_deal_cd    IN     VARCHAR2          -- 2.政策群コード
  );
--//+UPD START 2009/02/13 CT017 S.Son
--END XXCSM002A05;
END XXCSM002A05C;
--//+UPD END 2009/02/13 CT017 S.Son
/
