CREATE OR REPLACE PACKAGE xxwip720002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip720002c(spec)
 * Description      : 運賃アドオンマスタ取込処理
 * MD.050           : 運賃計算（マスタ） T_MD050_BPO_720
 * MD.070           : 運賃アドオンマスタ取込処理（72E）T_MD070_BPO_72E
 * Version          : 1.3
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
 *  2008/01/09    1.0   Y.Kanami         main新規作成
 *  2008/11/11    1.1   N.Fukuda         統合指摘#589対応
 *  2009/04/03    1.2   A.Shiina         本番#432対応
 *  2016/07/06    1.3   S.Niki           E_本稼動_13659対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
-- v1.3 ADD START
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_prod_div   IN     VARCHAR2          --   商品区分
-- v1.3 ADD END
  );
END xxwip720002c;
/
