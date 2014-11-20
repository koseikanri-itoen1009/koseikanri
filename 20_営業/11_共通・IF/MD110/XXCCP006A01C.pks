CREATE OR REPLACE PACKAGE APPS.XXCCP006A01C--←<package_name>は大文字で記述して下さい。
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP006A01C(spec)
 * Description      : 親子コンカレント終了ステータス監視
 * MD.050           : MD050_CCP_006_A01_親子コンカレント終了ステータス監視
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
 *  2009/01/15    1.0   Yohei Takayama   main新規作成
 *  2009/05/01    1.1   Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    iv_exe_appl_short_name  IN   VARCHAR2,            -- 1.起動対象アプリケーション短縮名
    iv_exe_conc_short_name  IN   VARCHAR2,            -- 2.起動対象コンカレント短縮名
    iv_child_conc_time      IN   VARCHAR2,            -- 3.子コンカレントステータス監視間隔
    iv_param1               IN   VARCHAR2  DEFAULT NULL,            -- 4.引数1
    iv_param2               IN   VARCHAR2  DEFAULT NULL,            -- 5.引数2
    iv_param3               IN   VARCHAR2  DEFAULT NULL,            -- 6.引数3
    iv_param4               IN   VARCHAR2  DEFAULT NULL,            -- 7.引数4
    iv_param5               IN   VARCHAR2  DEFAULT NULL,            -- 8.引数5
    iv_param6               IN   VARCHAR2  DEFAULT NULL,            -- 9.引数6
    iv_param7               IN   VARCHAR2  DEFAULT NULL,            -- 10.引数7
    iv_param8               IN   VARCHAR2  DEFAULT NULL,            -- 11.引数8
    iv_param9               IN   VARCHAR2  DEFAULT NULL,            -- 12.引数9
    iv_param10              IN   VARCHAR2  DEFAULT NULL,            -- 13.引数10
    iv_param11              IN   VARCHAR2  DEFAULT NULL,            -- 14.引数11
    iv_param12              IN   VARCHAR2  DEFAULT NULL,            -- 15.引数12
    iv_param13              IN   VARCHAR2  DEFAULT NULL,            -- 16.引数13
    iv_param14              IN   VARCHAR2  DEFAULT NULL,            -- 17.引数14
    iv_param15              IN   VARCHAR2  DEFAULT NULL,            -- 18.引数15
    iv_param16              IN   VARCHAR2  DEFAULT NULL,            -- 19.引数16
    iv_param17              IN   VARCHAR2  DEFAULT NULL,            -- 20.引数17
    iv_param18              IN   VARCHAR2  DEFAULT NULL,            -- 21.引数18
    iv_param19              IN   VARCHAR2  DEFAULT NULL,            -- 22.引数19
    iv_param20              IN   VARCHAR2  DEFAULT NULL,            -- 23.引数20
    iv_param21              IN   VARCHAR2  DEFAULT NULL,            -- 24.引数21
    iv_param22              IN   VARCHAR2  DEFAULT NULL,            -- 25.引数22
    iv_param23              IN   VARCHAR2  DEFAULT NULL,            -- 26.引数23
    iv_param24              IN   VARCHAR2  DEFAULT NULL,            -- 27.引数24
    iv_param25              IN   VARCHAR2  DEFAULT NULL,            -- 28.引数25
    iv_param26              IN   VARCHAR2  DEFAULT NULL,            -- 29.引数26
    iv_param27              IN   VARCHAR2  DEFAULT NULL,            -- 30.引数27
    iv_param28              IN   VARCHAR2  DEFAULT NULL,            -- 31.引数28
    iv_param29              IN   VARCHAR2  DEFAULT NULL,            -- 32.引数29
    iv_param30              IN   VARCHAR2  DEFAULT NULL,            -- 33.引数30
    iv_param31              IN   VARCHAR2  DEFAULT NULL,            -- 34.引数31
    iv_param32              IN   VARCHAR2  DEFAULT NULL,            -- 35.引数32
    iv_param33              IN   VARCHAR2  DEFAULT NULL,            -- 36.引数33
    iv_param34              IN   VARCHAR2  DEFAULT NULL,            -- 37.引数34
    iv_param35              IN   VARCHAR2  DEFAULT NULL,            -- 38.引数35
    iv_param36              IN   VARCHAR2  DEFAULT NULL,            -- 39.引数36
    iv_param37              IN   VARCHAR2  DEFAULT NULL,            -- 40.引数37
    iv_param38              IN   VARCHAR2  DEFAULT NULL,            -- 41.引数38
    iv_param39              IN   VARCHAR2  DEFAULT NULL,            -- 42.引数39
    iv_param40              IN   VARCHAR2  DEFAULT NULL,            -- 43.引数40
    iv_param41              IN   VARCHAR2  DEFAULT NULL,            -- 44.引数41
    iv_param42              IN   VARCHAR2  DEFAULT NULL,            -- 45.引数42
    iv_param43              IN   VARCHAR2  DEFAULT NULL,            -- 46.引数43
    iv_param44              IN   VARCHAR2  DEFAULT NULL,            -- 47.引数44
    iv_param45              IN   VARCHAR2  DEFAULT NULL,            -- 48.引数45
    iv_param46              IN   VARCHAR2  DEFAULT NULL,            -- 49.引数46
    iv_param47              IN   VARCHAR2  DEFAULT NULL,            -- 50.引数47
    iv_param48              IN   VARCHAR2  DEFAULT NULL,            -- 51.引数48
    iv_param49              IN   VARCHAR2  DEFAULT NULL,            -- 52.引数49
    iv_param50              IN   VARCHAR2  DEFAULT NULL,            -- 53.引数50
    iv_param51              IN   VARCHAR2  DEFAULT NULL,            -- 54.引数51
    iv_param52              IN   VARCHAR2  DEFAULT NULL,            -- 55.引数52
    iv_param53              IN   VARCHAR2  DEFAULT NULL,            -- 56.引数53
    iv_param54              IN   VARCHAR2  DEFAULT NULL,            -- 57.引数54
    iv_param55              IN   VARCHAR2  DEFAULT NULL,            -- 58.引数55
    iv_param56              IN   VARCHAR2  DEFAULT NULL,            -- 59.引数56
    iv_param57              IN   VARCHAR2  DEFAULT NULL,            -- 60.引数57
    iv_param58              IN   VARCHAR2  DEFAULT NULL,            -- 61.引数58
    iv_param59              IN   VARCHAR2  DEFAULT NULL,            -- 62.引数59
    iv_param60              IN   VARCHAR2  DEFAULT NULL,            -- 63.引数60
    iv_param61              IN   VARCHAR2  DEFAULT NULL,            -- 64.引数61
    iv_param62              IN   VARCHAR2  DEFAULT NULL,            -- 65.引数62
    iv_param63              IN   VARCHAR2  DEFAULT NULL,            -- 66.引数63
    iv_param64              IN   VARCHAR2  DEFAULT NULL,            -- 67.引数64
    iv_param65              IN   VARCHAR2  DEFAULT NULL,            -- 68.引数65
    iv_param66              IN   VARCHAR2  DEFAULT NULL,            -- 69.引数66
    iv_param67              IN   VARCHAR2  DEFAULT NULL,            -- 70.引数67
    iv_param68              IN   VARCHAR2  DEFAULT NULL,            -- 71.引数68
    iv_param69              IN   VARCHAR2  DEFAULT NULL,            -- 72.引数69
    iv_param70              IN   VARCHAR2  DEFAULT NULL,            -- 73.引数70
    iv_param71              IN   VARCHAR2  DEFAULT NULL,            -- 74.引数71
    iv_param72              IN   VARCHAR2  DEFAULT NULL,            -- 75.引数72
    iv_param73              IN   VARCHAR2  DEFAULT NULL,            -- 76.引数73
    iv_param74              IN   VARCHAR2  DEFAULT NULL,            -- 77.引数74
    iv_param75              IN   VARCHAR2  DEFAULT NULL,            -- 78.引数75
    iv_param76              IN   VARCHAR2  DEFAULT NULL,            -- 79.引数76
    iv_param77              IN   VARCHAR2  DEFAULT NULL,            -- 80.引数77
    iv_param78              IN   VARCHAR2  DEFAULT NULL,            -- 81.引数78
    iv_param79              IN   VARCHAR2  DEFAULT NULL,            -- 82.引数79
    iv_param80              IN   VARCHAR2  DEFAULT NULL,            -- 83.引数80
    iv_param81              IN   VARCHAR2  DEFAULT NULL,            -- 84.引数81
    iv_param82              IN   VARCHAR2  DEFAULT NULL,            -- 85.引数82
    iv_param83              IN   VARCHAR2  DEFAULT NULL,            -- 86.引数83
    iv_param84              IN   VARCHAR2  DEFAULT NULL,            -- 87.引数84
    iv_param85              IN   VARCHAR2  DEFAULT NULL,            -- 88.引数85
    iv_param86              IN   VARCHAR2  DEFAULT NULL,            -- 89.引数86
    iv_param87              IN   VARCHAR2  DEFAULT NULL,            -- 90.引数87
    iv_param88              IN   VARCHAR2  DEFAULT NULL,            -- 91.引数88
    iv_param89              IN   VARCHAR2  DEFAULT NULL,            -- 92.引数89
    iv_param90              IN   VARCHAR2  DEFAULT NULL,            -- 93.引数90
    iv_param91              IN   VARCHAR2  DEFAULT NULL,            -- 94.引数91
    iv_param92              IN   VARCHAR2  DEFAULT NULL,            -- 95.引数92
    iv_param93              IN   VARCHAR2  DEFAULT NULL,            -- 96.引数93
    iv_param94              IN   VARCHAR2  DEFAULT NULL,            -- 97.引数94
    iv_param95              IN   VARCHAR2  DEFAULT NULL,            -- 98.引数95
    iv_param96              IN   VARCHAR2  DEFAULT NULL,            -- 99.引数96
    iv_param97              IN   VARCHAR2  DEFAULT NULL             -- 100.引数97
  );
END XXCCP006A01C;
/
