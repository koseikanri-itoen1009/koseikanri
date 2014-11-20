CREATE OR REPLACE PACKAGE XXCOS011A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A06C (spec)
 * Description      : 販売実績ヘッダデータ、販売実績明細データを取得して、販売実績データファイルを
 *                    作成する。
 * MD.050           : 販売実績データ作成（MD050_COS_011_A06）
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
 *  2009/01/09    1.0   K.Watanabe      新規作成
 *  2009/03/10    1.1   K.Kiriu         [COS_157]請求開始日NULL考慮の修正、届け先住所不正修正
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT  VARCHAR2,     --   エラーメッセージ #固定#
    retcode           OUT  VARCHAR2,     --   エラーコード     #固定#
    iv_run_class      IN   VARCHAR2,     --   実行区分：「0:新規」「2:解除」
    iv_inv_cust_code  IN   VARCHAR2,     --   請求先顧客コード
    iv_send_date      IN   VARCHAR2      --   送信日(YYYYMMDD)
  );
END XXCOS011A06C;
/
