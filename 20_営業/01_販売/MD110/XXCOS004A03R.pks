CREATE OR REPLACE PACKAGE APPS.XXCOS004A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A03R (spec)
 * Description      : 消化計算チェックリスト
 * MD.050           : 消化計算チェックリスト MD050_COS_004_A03
 * Version          : 1.6
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
 *  2008/11/04    1.0   K.Kin            新規作成
 *  2009/02/04    1.1   K.Kin            [COS_011]文字列バッファが小さすぎます不具合対応
 *  2009/02/26    1.2   K.Kin            削除処理のコメント削除
 *  2009/06/19    1.3   K.Kiriu          [T1_1437]データパージ不具合対応
 *  2009/09/30    1.4   S.Miyakoshi      [0001378]帳票ワークテーブルの桁あふれ対応
 *  2010/02/23    1.5   K.Atsushiba      [E_本稼動_01670]異常掛率対応
 *  2012/08/03    1.6   K.Onotsuka       [E_本稼動_09900]入力パラメータ及び明細ソート条件追加対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_sales_base_code        IN      VARCHAR2,         -- 1.拠点コード
    iv_customer_number        IN      VARCHAR2,         -- 2.顧客コード
/* 2012/08/03 Ver1.6 Add Start */
    iv_yyyymm_from            IN      VARCHAR2,         -- 3.年月（From）
    iv_yyyymm_to              IN      VARCHAR2          -- 4.年月（To）
/* 2012/08/03 Ver1.6 Add End */
  );
END XXCOS004A03R;
/
