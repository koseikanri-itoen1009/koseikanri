CREATE OR REPLACE PACKAGE XXCOS002A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A02R(spec)
 * Description      : 営業報告日報
 * MD.050           : 営業報告日報 MD050_COS_002_A02
 * Version          : 1.3
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
 *  2008/12/11    1.0   T.Nakabayashi    main新規作成
 *  2009/02/20    1.1   T.Nakabayashi    get_msgのパッケージ名修正
 *  2009/02/26    1.2   T.Nakabayashi    MD050課題No153対応 従業員、アサインメント適用日判断追加
 *  2009/02/27    1.3   T.Nakabayashi    帳票ワークテーブル削除処理 コメントアウト解除
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT     VARCHAR2,         --  エラーメッセージ #固定#
    retcode               OUT     VARCHAR2,         --  エラーコード     #固定#
    iv_delivery_date      IN      VARCHAR2,         --  1.納品日
    iv_delivery_base_code IN      VARCHAR2,         --  2.納品拠点
    iv_dlv_by_code        IN      VARCHAR2          --  3.営業員（納品者）
  );
END XXCOS002A02R;
/
