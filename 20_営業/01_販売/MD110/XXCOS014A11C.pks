CREATE OR REPLACE PACKAGE XXCOS014A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A11C (spec)
 * Description      : 入庫予定データの作成を行う
 * MD.050           : 入庫予定情報データ作成 (MD050_COS_014_A11)
 * Version          : 1.2
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
 *  2009/03/16    1.0   K.Kiriu          新規作成
 *  2009/07/01    1.1   K.Kiriu          [T1_1359]数量換算対応
 *  2009/08/18    1.2   K.Kiriu          [0000445]PT対応
 *  2009/09/28    1.3   K.Satomura       [0001156]
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,  --    エラーメッセージ #固定#
    retcode               OUT    VARCHAR2,  --    エラーコード     #固定#
    iv_file_name          IN     VARCHAR2,  --  1.ファイル名
    iv_chain_code         IN     VARCHAR2,  --  2.チェーン店コード
    iv_report_code        IN     VARCHAR2,  --  3.帳票コード
    iv_user_id            IN     VARCHAR2,  --  4.ユーザID
    iv_chain_name         IN     VARCHAR2,  --  5.チェーン店名
    iv_store_code         IN     VARCHAR2,  --  6.店舗コード
    iv_base_code          IN     VARCHAR2,  --  7.拠点コード
    iv_base_name          IN     VARCHAR2,  --  8.拠点名
    iv_data_type_code     IN     VARCHAR2,  --  9.帳票種別コード
    iv_oprtn_series_code  IN     VARCHAR2,  -- 10.業務系列コード
    iv_report_name        IN     VARCHAR2,  -- 11.帳票様式
    iv_to_subinv_code     IN     VARCHAR2,  -- 12.搬送先保管場所コード
    iv_center_code        IN     VARCHAR2,  -- 13.センターコード
    iv_invoice_number     IN     VARCHAR2,  -- 14.伝票番号
    iv_sch_ship_date_from IN     VARCHAR2,  -- 15.出荷予定日FROM
    iv_sch_ship_date_to   IN     VARCHAR2,  -- 16.出荷予定日TO
    iv_sch_arrv_date_from IN     VARCHAR2,  -- 17.入庫予定日FROM
    iv_sch_arrv_date_to   IN     VARCHAR2,  -- 18.入庫予定日TO
    iv_move_order_number  IN     VARCHAR2,  -- 19.移動オーダー番号
    iv_edi_send_flag      IN     VARCHAR2   -- 20.EDI送信状況
  );
END XXCOS014A11C;
/
