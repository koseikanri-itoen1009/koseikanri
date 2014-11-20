CREATE OR REPLACE PACKAGE XXCOS008A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A01C(spec)
 * Description      : 工場直送出荷依頼IF作成を行う
 * MD.050           : 工場直送出荷依頼IF作成 MD050_COS_008_A01
 * Version          : 1.2
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
 *  2008/12/25    1.0   K.Atsushiba      新規作成
 *  2009/02/05    1.1   K.Atsushiba      COS_035対応  出荷依頼I/Fヘッダーの依頼区分に「4」を設定。
 *  2009/02/18    1.2   K.Atsushiba      get_msgのパッケージ名修正
 *  2009/02/23    1.3   K.Atsushiba      パラメータのログファイル出力対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_base_code     IN     VARCHAR2,         -- 1.拠点コード
    iv_order_number  IN     VARCHAR2          -- 2.受注番号
  );
END XXCOS008A01C;
/
