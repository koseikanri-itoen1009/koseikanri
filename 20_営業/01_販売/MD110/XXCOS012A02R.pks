CREATE OR REPLACE PACKAGE XXCOS012A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS012A02R (spec)
 * Description      : ピックリスト（出荷先・販売先・製品別）
 * MD.050           : ピックリスト（出荷先・販売先・製品別） MD050_COS_012_A02
 * Version          : 1.5
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
 *  2008/12/22    1.0   K.Kakishita      新規作成
 *  2009/02/23    1.1   K.Kakishita      売上区分のクイックコードタイプおよびコードの変更
 *  2009/02/26    1.2   K.Kakishita      帳票コンカレント起動後のワークテーブル削除処理の
 *                                       コメント化を外す。
 *  2009/04/03    1.3   N.Maeda          【ST障害No.T1_0086対応】
 *                                       非在庫品目を抽出対象より除外するよう変更。
 *  2009/06/05    1.4   T.Kitajima       [T1_1334]受注明細、EDI明細結合条件変更
 *  2009/06/09    1.5   T.Kitajima       [T1_1374]拠点名(40byte)
 *                                                チェーン店名(40byte)
 *                                                倉庫名(50byte)
 *                                                店舗コード(10byte)
 *                                                品目コード(16byte)
 *                                                品名(40byte)
 *                                                に修正
 *  2009/06/09    1.5   T.Kitajima       [T1_1375]入数が0の場合、ケース数に0設定、
 *                                                バラ数に数量を設定する。
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_login_base_code        IN      VARCHAR2,         -- 1.拠点
    iv_login_chain_store_code IN      VARCHAR2,         -- 2.チェーン店
    iv_request_date_from      IN      VARCHAR2,         -- 3.着日（From）
    iv_request_date_to        IN      VARCHAR2,         -- 4.着日（To）
    iv_bargain_class          IN      VARCHAR2)         -- 5.定番特売区分
  ;
END XXCOS012A02R;
/
