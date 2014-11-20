CREATE OR REPLACE PACKAGE XXCOS002A031R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A031R(spec)
 * Description      : 営業成績表
 * MD.050           : 営業成績表 MD050_COS_002_A03
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
 *  2009/02/06    1.0   T.Nakabayashi    main新規作成
 *  2009/02/23    1.1   T.Nakabayashi    [COS_123]A-2 グループコード未設定でも個別の成績表は出力可能とする
 *  2009/02/26    1.2   T.Nakabayashi    MD050課題No153対応 従業員、アサインメント適用日判断追加
 *  2009/02/27    1.3   T.Nakabayashi    帳票ワークテーブル削除処理 コメントアウト解除
 *  2009/06/09    1.4   T.Tominaga       帳票ワークテーブル削除処理"delete_rpt_wrk_data" コメントアウト解除
 *  2009/06/18    1.5   K.Kiriu          [T1_1446]PT対応
 *  2009/06/22    1.6   K.Kiriu          [T1_1437]データパージ不具合対応
 *  2009/07/07    1.7   K.Kiriu          [0000418]削除件数取得不具合対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT     VARCHAR2,         --  エラーメッセージ #固定#
    retcode                   OUT     VARCHAR2,         --  エラーコード     #固定#
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_date          IN      VARCHAR2,         --  2.納品日
    iv_delivery_base_code     IN      VARCHAR2,         --  3.拠点
    iv_section_code           IN      VARCHAR2,         --  4.課
    iv_results_employee_code  IN      VARCHAR2          --  5.営業員
  );
END XXCOS002A031R;
/
