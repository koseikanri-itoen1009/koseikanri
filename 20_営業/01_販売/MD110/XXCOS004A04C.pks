CREATE OR REPLACE PACKAGE XXCOS004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A04C (spec)
 * Description      : 消化VD納品データ作成
 * MD.050           : 消化VD納品データ作成 MD050_COS_004_A04
 * Version          : 1.8
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
 *  2009/1/14    1.0   T.Miyashita      新規作成
 *  2009/02/04   1.1   T.miyashita       [COS_013]INV会計期間取得不具合
 *  2009/02/04   1.2   T.miyashita       [COS_017]基準単価と税抜基準単価の不具合
 *  2009/02/04   1.3   T.miyashita       [COS_024]販売金額の不具合
 *  2009/02/04   1.4   T.miyashita       [COS_028]作成元区分の不具合
 *  2009/02/19   1.5   T.miyashita       [COS_091]訪問・有効の軒数の取込漏れ対応
 *  2009/02/20   1.6   T.Miyashita       パラメータのログファイル出力対応
 *  2009/02/23   1.7   T.Miyashita       [COS_116]納品日セット不具合
 *  2009/02/23   1.8   T.Miyashita       [COS_122]営業担当員コードセット不具合
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2, -- エラーメッセージ #固定#
    retcode            OUT NOCOPY VARCHAR2, -- エラーコード     #固定#
    iv_exec_div        IN  VARCHAR2,        -- 1.定期随時区分
    iv_base_code       IN  VARCHAR2,        -- 2.拠点コード
    iv_customer_number IN  VARCHAR2         -- 3.顧客コード
  );
--
END XXCOS004A04C;
/
