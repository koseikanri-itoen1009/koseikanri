CREATE OR REPLACE PACKAGE XXCOS009A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A03R (spec)
 * Description      : 原価割れチェックリスト
 * MD.050           : 原価割れチェックリスト MD050_COS_009_A03
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
 *  2008/12/10    1.0   H.Ri             新規作成
 *  2009/02/17    1.1   H.Ri             get_msgのパッケージ名修正
 *  2009/04/21    1.2   K.Kiriu          [T1_0444]成績計上者コードの結合不正対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode           OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_sale_base_code IN     VARCHAR2,         --   売上拠点コード
    iv_dlv_date_from  IN     VARCHAR2,         --   納品日(FROM)
    iv_dlv_date_to    IN     VARCHAR2,         --   納品日(TO)
    iv_sale_emp_code  IN     VARCHAR2,         --   営業担当者コード
    iv_ship_to_code   IN     VARCHAR2          --   出荷先コード
  );
END XXCOS009A03R;
/
