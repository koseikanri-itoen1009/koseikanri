CREATE OR REPLACE PACKAGE xxwsh600002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600002c(spec)
 * Description      : 入出庫配送計画情報抽出処理
 * MD.050           : T_MD050_BPO_601_配車配送計画
 * MD.070           : T_MD070_BPO_60E_入出庫配送計画情報抽出処理
 * Version          : 1.16
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
 *  2008/04/01    1.0   M.Ikeda          新規作成
 *  2008/06/04    1.1   N.Yoshida        移動ロット詳細紐付け対応
 *  2008/06/05    1.2   M.Hokkanji       結合テスト用暫定対応:CSV出力処理の出力場所を変更
 *                                       中間テーブル登録データ抽出する際、配車配送計画ア
 *                                       ドオンにデータが存在しない場合でもデータを出力さ
 *                                       れるように修正
 *  2008/06/06    1.3   M.HOKKANJI       ＣＳＶ出力処理でエラー発生時にF_CLOSE_ALLしているのを
 *                                       個別にクローズするように変更
 *  2008/06/06    1.4   M.HOKKANJI       結合テスト440不具合対応#66
 *  2008/06/06    1.5   M.HOKKANJI       結合テスト440不具合対応#65
 *  2008/06/11    1.6   M.NOMURA         結合テスト WF対応
 *  2008/06/12    1.7   M.NOMURA         結合テスト 不具合対応#9
 *  2008/06/16    1.8   M.NOMURA         結合テスト 440 不具合対応#64
 *  2008/06/18    1.9   M.HOKKANJI       システムテスト不具合対応#147,#187
 *  2008/06/23    1.10  M.NOMURA         システムテスト不具合対応#217
 *  2008/06/27    1.11  M.NOMURA         システムテスト不具合対応#303
 *  2008/07/04    1.12  M.NOMURA         システムテスト不具合対応#390
 *  2008/07/16    1.13  Oracle 山根 一浩 I_S_192,T_S_443,指摘240対応
 *  2008/08/04    1.14  M.NOMURA         追加結合不具合対応
 *  2008/08/12    1.15  N.Fukuda         課題#32対応
 *  2008/08/12    1.15  N.Fukuda         課題#48(変更要求#164)対応
 *  2008/09/01    1.16  Y.Yamamoto       PT 2-2_17 指摘17対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main
    (
      errbuf              OUT NOCOPY  VARCHAR2    -- エラーメッセージ #固定#
     ,retcode             OUT NOCOPY  VARCHAR2    -- エラーコード     #固定#
     ,iv_dept_code_01     IN  VARCHAR2            -- 01 : 部署_01
     ,iv_dept_code_02     IN  VARCHAR2            -- 02 : 部署_02
     ,iv_dept_code_03     IN  VARCHAR2            -- 03 : 部署_03
     ,iv_dept_code_04     IN  VARCHAR2            -- 04 : 部署_04
     ,iv_dept_code_05     IN  VARCHAR2            -- 05 : 部署_05
     ,iv_dept_code_06     IN  VARCHAR2            -- 06 : 部署_06
     ,iv_dept_code_07     IN  VARCHAR2            -- 07 : 部署_07
     ,iv_dept_code_08     IN  VARCHAR2            -- 08 : 部署_08
     ,iv_dept_code_09     IN  VARCHAR2            -- 09 : 部署_09
     ,iv_dept_code_10     IN  VARCHAR2            -- 10 : 部署_10
     ,iv_fix_class        IN  VARCHAR2            -- 11 : 予定確定区分
     ,iv_date_cutoff      IN  VARCHAR2            -- 12 : 締め実施日
     ,iv_cutoff_from      IN  VARCHAR2            -- 13 : 締め実施時間From
     ,iv_cutoff_to        IN  VARCHAR2            -- 14 : 締め実施時間To
     ,iv_date_fix         IN  VARCHAR2            -- 15 : 確定通知実施日
     ,iv_fix_from         IN  VARCHAR2            -- 16 : 確定通知実施時間From
     ,iv_fix_to           IN  VARCHAR2            -- 17 : 確定通知実施時間To
    ) ;
--
END xxwsh600002c ;
/
