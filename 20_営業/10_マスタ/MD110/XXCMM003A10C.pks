CREATE OR REPLACE PACKAGE xxcmm003a10c
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : xxcmm003a10c(spec)
 * Description     : 未取引客チェックリスト
 * MD.050          : MD050_CMM_003_A10_未取引客チェックリスト
 * MD.070          : MD050_CMM_003_A10_未取引客チェックリスト
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 * main              P         コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- -------------- ------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------- ------------------------------------
 *  2009-02-04    1.0  SCS K.Shirasuna  初回作成
 *  2009-03-09    1.1  Yutaka.Kuboshima ファイル出力先のプロファイルの削除
 *                                      物件マスタコード取得の抽出条件を変更
 *
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                     OUT NOCOPY VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode                    OUT NOCOPY VARCHAR2,         --    エラーコード        --# 固定 #
    iv_cust_status             IN         VARCHAR2,         --    顧客ステータス
    iv_sale_base_code          IN         VARCHAR2          --    拠点コード
  );
END xxcmm003a10c;
/
