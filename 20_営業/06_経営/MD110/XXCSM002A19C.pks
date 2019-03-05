CREATE OR REPLACE PACKAGE XXCSM002A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSM002A19C(spec)
 * Description      : 年間商品計画ダウンロード
 * MD.050           : 年間商品計画ダウンロード MD050_CSM_002_A19
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
 *  2019/02/08    1.0   Y.Sasaki         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_output_kbn   IN   VARCHAR2,         -- 1.出力区分
    iv_location_cd  IN   VARCHAR2,         -- 2.拠点
    iv_plan_year    IN   VARCHAR2,         -- 3.年度
    iv_item_group_3 IN   VARCHAR2,         -- 4.商品群3
    iv_output_data  IN   VARCHAR2          -- 5.出力値
  );
END XXCSM002A19C;
/
