CREATE OR REPLACE PACKAGE XXCOS004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A02C (spec)
 * Description      : 商品別売上計算
 * MD.050           : 商品別売上計算 MD050_COS_004_A02
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
 *  2008/12/10    1.0   T.kitajima       新規作成
 *  2009/02/05    1.1   T.miyashita      [COS_022]単位換算の不具合
 *  2009/02/05    1.2   T.kitajima       [COS_023]赤黒フラグ設定不具合(仕様漏れ)
 *  2009/02/10    1.3   T.kitajima       [COS_041]納品伝票区分(1:納品)設定(仕様漏れ)
 *  2009/02/10    1.4   T.kitajima       [COS_047]差分明細の納品/基準単位(仕様漏れ)
 *  2009/02/19    1.5   T.kitajima       納品形態区分 メイン倉庫対応
 *  2009/02/24    1.6   T.kitajima       パラメータのログファイル出力対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2,         -- エラーメッセージ #固定#
    retcode            OUT NOCOPY VARCHAR2,         -- エラーコード     #固定#
    iv_exec_div        IN         VARCHAR2,         -- 1.定期随時区分
    iv_base_code       IN         VARCHAR2,         -- 2.拠点コード
    iv_customer_number IN         VARCHAR2          -- 3.顧客コード
  );
END XXCOS004A02C;
/
