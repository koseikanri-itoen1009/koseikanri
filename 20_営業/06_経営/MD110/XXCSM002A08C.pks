CREATE OR REPLACE PACKAGE XXCSM002A08C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A08C(spec)
 * Description      : 月別商品計画(営業原価)チェックリスト出力
 * MD.050           : 月別商品計画(営業原価)チェックリスト出力 MD050_CSM_002_A08
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  main                【コンカレント実行ファイル登録プロシージャ】
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   S.son        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT    NOCOPY VARCHAR2,         --   エラーメッセージ
    retcode                OUT    NOCOPY VARCHAR2,         --   エラーコード
    iv_subject_year        IN     VARCHAR2,                --   対象年度
    iv_location_cd         IN     VARCHAR2,                --   拠点コード
    iv_hierarchy_level     IN     VARCHAR2                 --   階層
  );
END XXCSM002A08C;
/
