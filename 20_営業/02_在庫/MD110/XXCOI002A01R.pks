CREATE OR REPLACE PACKAGE XXCOI002A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI002A01R(spec)
 * Description      : 倉替伝票
 * MD.050           : 倉替伝票 MD050_COI_002_A01
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
 *  2008/11/12    1.0   K.Nakamura       main新規作成
 *  2012/08/10    1.1   K.Nakamura       [E_本稼動_09899]A4への印刷方式追記
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,      --   エラーメッセージ #固定#
    retcode         OUT    VARCHAR2,      --   エラーコード     #固定#
    iv_org_code     IN     VARCHAR2,      --   1.在庫組織
    iv_inout_div    IN     VARCHAR2,      --   2.入出庫区分
    iv_date_from    IN     VARCHAR2,      --   3.日付（From）
    iv_date_to      IN     VARCHAR2,      --   4.日付（To）
    iv_kyoten_from  IN     VARCHAR2,      --   5.出庫元拠点
    iv_dummy        IN     VARCHAR2,      --   入力制御用ダミー値
-- == 2012/08/10 V1.1 Modified START ===============================================================
--    iv_kyoten_to    IN     VARCHAR2       --   6.入庫先拠点
    iv_kyoten_to    IN     VARCHAR2,      --   6.入庫先拠点
    iv_print_form   IN     VARCHAR2       --   7.印刷方式制御区分
-- == 2012/08/10 V1.1 Modified END   ===============================================================
  );
END XXCOI002A01R;
/
