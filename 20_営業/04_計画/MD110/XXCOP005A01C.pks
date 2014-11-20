create or replace PACKAGE XXCOP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP005A01C(spec)
 * Description      : 工場出荷計画
 * MD.050           : 工場出荷計画 MD050_COP_005_A01
 * Version          : 2.0
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
 *  2008/12/02    1.0   SCS Uda          新規作成
 *  2009/02/25    1.1   SCS Uda          結合テスト仕様変更（結合障害No.014）
 *  2009/04/07    1.2   SCS Uda          システムテスト障害対応（T1_0277、T1_0278、T1_0280、T1_0281、T1_0368）
 *  2009/04/14    1.3   SCS Uda          システムテスト障害対応（T1_0542）
 *  2009/04/21    1.4   SCS Uda          システムテスト障害対応（T1_0722）
 *  2009/04/28    1.5   SCS Uda          システムテスト障害対応（T1_0845、T1_0847）
 *  2009/05/20    1.6   SCS Uda          システムテスト障害対応（T1_1096）
 *  2009/06/04    1.7   SCS Fukada       システムテスト障害対応（T1_1328）プログラムの最後に「/」を追加
 *  2009/06/16    1.8   SCS Kikuchi      システムテスト障害対応（T1_1463、T1_1464）
 *  2009/09/01    2.0  SCS T.Tsukino     新規作成
 *
 *****************************************************************************************/
--コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf           OUT VARCHAR2         --   エラーメッセージ #固定#
    ,retcode          OUT VARCHAR2         --   エラーコード     #固定#
    ,iv_plan_from     IN  VARCHAR2         --   1.計画立案期間（FROM）
    ,iv_plan_to       IN  VARCHAR2         --   2.計画立案期間（TO）
    ,iv_pace_type     IN  VARCHAR2         --   3.対象出荷区分
    ,iv_pace_from     IN  VARCHAR2         --   4.出荷ペース計画期間（FROM）
    ,iv_pace_to       IN  VARCHAR2         --   5.出荷ペース計画期間（TO）
    ,iv_forcast_from  IN  VARCHAR2         --   6.出荷予測期間（FROM)
    ,iv_forcast_to    IN  VARCHAR2         --   7.出荷予測期間（TO）
    ,iv_schedule_date IN  VARCHAR2         --   8.出荷引当済日
   );
END XXCOP005A01C;
/

