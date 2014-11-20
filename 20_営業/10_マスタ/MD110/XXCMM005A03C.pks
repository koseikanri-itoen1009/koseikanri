create or replace PACKAGE XXCMM005A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A03C(spec)
 * Description      : 拠点マスタIF出力（HHT）
 * MD.050           : 拠点マスタIF出力（HHT） MD050_CMM_005_A03
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
 *  2009/02/03    1.0   Masayuki.Sano    main新規作成
 *  2009/03/09    1.1   Yutaka.Kuboshima ファイル出力先のプロファイルの変更
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   エラーメッセージ #固定#
    retcode               OUT    VARCHAR2,        --   エラーコード     #固定#
    iv_update_from        IN     VARCHAR2,        --   1.最終更新日(FROM)
    iv_update_to          IN     VARCHAR2         --   2.最終更新日(TO)
  );
END XXCMM005A03C;
/
