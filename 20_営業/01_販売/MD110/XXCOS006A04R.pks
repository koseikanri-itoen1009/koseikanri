CREATE OR REPLACE PACKAGE XXCOS006A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS006A04R (spec)
 * Description      : 出荷依頼書
 * MD.050           : 出荷依頼書 MD050_COS_006_A04
 * Version          : 1.7
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
 *  2008/11/07    1.0   K.Kakishita      新規作成
 *  2009/02/26    1.1   K.Kakishita      帳票コンカレント起動後のワークテーブル削除処理の
 *                                       コメント化を外す。
 *  2009/03/03    1.2   N.Maeda          不要な定数の削除
 *                                       ( ct_qct_cus_class_mst , ct_qcc_cus_class_mst1 )
 *  2009/04/01    1.3   N.Maeda          【ST障害No.T1-0085対応】
 *                                       非在庫品目を非抽出データへ変更
 *                                       【ST障害No.T1-0049対応】
 *                                       備考データ取得カラム名の修正
 *                                       descriptionへのセット内容を修正
 *  2009/06/19    1.4   K.Kiriu          【ST障害No.T1-1437対応】
 *                                       データパージ不具合対応
 *  2009/07/09    1.5   M.Sano           【SCS障害No.0000063対応】
 *                                       情報区分によるデータ作成対象の制御
 *  2009/10/01    1.6   S.Miyakoshi      【SCS障害No.0001378対応】
 *                                       帳票ワークテーブルの桁あふれ対応
 *                                       クイックコード取得時のパフォーマンス対応
 *  2013/03/26    1.7   T.Ishiwata       【E_本稼動_10343対応】
 *                                        パラメータ「出力区分」追加、文言、タイトル変更
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_ship_from_subinv_code  IN      VARCHAR2,         -- 1.出荷元倉庫
    iv_ordered_date_from      IN      VARCHAR2,         -- 2.受注日（From）
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata Start
--    iv_ordered_date_to        IN      VARCHAR2          -- 3.受注日（To）
    iv_ordered_date_to        IN      VARCHAR2,         -- 3.受注日（To）
    iv_output_code            IN      VARCHAR2          -- 4.出力区分
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata End
  );
END XXCOS006A04R;
/
