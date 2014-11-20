CREATE OR REPLACE PACKAGE APPS.XXCCP006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP006A02C(spec)
 * Description      : 動的パラメータコンカレント対応
 * MD.050           : 動的パラメータコンカレント対応 MD050_CCP_006_A02
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 動的パラメータコンカレント対応プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2009/01/13     1.0  Masakazu Yamashita  main新規作成
 *  2009/05/01     1.1  Masayuki.Sano       障害番号T1_0910対応(スキーマ名付加)
 *
 *****************************************************************************************/
--
  --動的パラメータコンカレント対応プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,                        --  エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,                        --  エラーコード     #固定#
    iv_app_name   IN     VARCHAR2 DEFAULT NULL,           --  1.起動対象アプリケーション短縮名
    iv_prg_name   IN     VARCHAR2 DEFAULT NULL,           --  2.起動対象コンカレント短縮名
    iv_args1      IN     VARCHAR2 DEFAULT CHR(0),         --  3.引数1
    iv_args2      IN     VARCHAR2 DEFAULT CHR(0),         --  4.引数2
    iv_args3      IN     VARCHAR2 DEFAULT CHR(0),         --  5.引数3
    iv_args4      IN     VARCHAR2 DEFAULT CHR(0),         --  6.引数4
    iv_args5      IN     VARCHAR2 DEFAULT CHR(0),         --  7.引数5
    iv_args6      IN     VARCHAR2 DEFAULT CHR(0),         --  8.引数6
    iv_args7      IN     VARCHAR2 DEFAULT CHR(0),         --  9.引数7
    iv_args8      IN     VARCHAR2 DEFAULT CHR(0),         -- 10.引数8
    iv_args9      IN     VARCHAR2 DEFAULT CHR(0),         -- 11.引数9
    iv_args10     IN     VARCHAR2 DEFAULT CHR(0),         -- 12.引数10
    iv_args11     IN     VARCHAR2 DEFAULT CHR(0),         -- 13.引数11
    iv_args12     IN     VARCHAR2 DEFAULT CHR(0),         -- 14.引数12
    iv_args13     IN     VARCHAR2 DEFAULT CHR(0),         -- 15.引数13
    iv_args14     IN     VARCHAR2 DEFAULT CHR(0),         -- 16.引数14
    iv_args15     IN     VARCHAR2 DEFAULT CHR(0),         -- 17.引数15
    iv_args16     IN     VARCHAR2 DEFAULT CHR(0),         -- 18.引数16
    iv_args17     IN     VARCHAR2 DEFAULT CHR(0),         -- 19.引数17
    iv_args18     IN     VARCHAR2 DEFAULT CHR(0),         -- 20.引数18
    iv_args19     IN     VARCHAR2 DEFAULT CHR(0),         -- 21.引数19
    iv_args20     IN     VARCHAR2 DEFAULT CHR(0),         -- 22.引数20
    iv_args21     IN     VARCHAR2 DEFAULT CHR(0),         -- 23.引数21
    iv_args22     IN     VARCHAR2 DEFAULT CHR(0),         -- 24.引数22
    iv_args23     IN     VARCHAR2 DEFAULT CHR(0),         -- 25.引数23
    iv_args24     IN     VARCHAR2 DEFAULT CHR(0),         -- 26.引数24
    iv_args25     IN     VARCHAR2 DEFAULT CHR(0),         -- 27.引数25
    iv_args26     IN     VARCHAR2 DEFAULT CHR(0),         -- 28.引数26
    iv_args27     IN     VARCHAR2 DEFAULT CHR(0),         -- 29.引数27
    iv_args28     IN     VARCHAR2 DEFAULT CHR(0),         -- 30.引数28
    iv_args29     IN     VARCHAR2 DEFAULT CHR(0),         -- 31.引数29
    iv_args30     IN     VARCHAR2 DEFAULT CHR(0),         -- 32.引数30
    iv_args31     IN     VARCHAR2 DEFAULT CHR(0),         -- 33.引数31
    iv_args32     IN     VARCHAR2 DEFAULT CHR(0),         -- 34.引数32
    iv_args33     IN     VARCHAR2 DEFAULT CHR(0),         -- 35.引数33
    iv_args34     IN     VARCHAR2 DEFAULT CHR(0),         -- 36.引数34
    iv_args35     IN     VARCHAR2 DEFAULT CHR(0),         -- 37.引数35
    iv_args36     IN     VARCHAR2 DEFAULT CHR(0),         -- 38.引数36
    iv_args37     IN     VARCHAR2 DEFAULT CHR(0),         -- 39.引数37
    iv_args38     IN     VARCHAR2 DEFAULT CHR(0),         -- 40.引数38
    iv_args39     IN     VARCHAR2 DEFAULT CHR(0),         -- 41.引数39
    iv_args40     IN     VARCHAR2 DEFAULT CHR(0),         -- 42.引数40
    iv_args41     IN     VARCHAR2 DEFAULT CHR(0),         -- 43.引数41
    iv_args42     IN     VARCHAR2 DEFAULT CHR(0),         -- 44.引数42
    iv_args43     IN     VARCHAR2 DEFAULT CHR(0),         -- 45.引数43
    iv_args44     IN     VARCHAR2 DEFAULT CHR(0),         -- 46.引数44
    iv_args45     IN     VARCHAR2 DEFAULT CHR(0),         -- 47.引数45
    iv_args46     IN     VARCHAR2 DEFAULT CHR(0),         -- 48.引数46
    iv_args47     IN     VARCHAR2 DEFAULT CHR(0),         -- 49.引数47
    iv_args48     IN     VARCHAR2 DEFAULT CHR(0),         -- 50.引数48
    iv_args49     IN     VARCHAR2 DEFAULT CHR(0),         -- 51.引数49
    iv_args50     IN     VARCHAR2 DEFAULT CHR(0),         -- 52.引数50
    iv_args51     IN     VARCHAR2 DEFAULT CHR(0),         -- 53.引数51
    iv_args52     IN     VARCHAR2 DEFAULT CHR(0),         -- 54.引数52
    iv_args53     IN     VARCHAR2 DEFAULT CHR(0),         -- 55.引数53
    iv_args54     IN     VARCHAR2 DEFAULT CHR(0),         -- 56.引数54
    iv_args55     IN     VARCHAR2 DEFAULT CHR(0),         -- 57.引数55
    iv_args56     IN     VARCHAR2 DEFAULT CHR(0),         -- 58.引数56
    iv_args57     IN     VARCHAR2 DEFAULT CHR(0),         -- 59.引数57
    iv_args58     IN     VARCHAR2 DEFAULT CHR(0),         -- 60.引数58
    iv_args59     IN     VARCHAR2 DEFAULT CHR(0),         -- 61.引数59
    iv_args60     IN     VARCHAR2 DEFAULT CHR(0),         -- 62.引数60
    iv_args61     IN     VARCHAR2 DEFAULT CHR(0),         -- 63.引数61
    iv_args62     IN     VARCHAR2 DEFAULT CHR(0),         -- 64.引数62
    iv_args63     IN     VARCHAR2 DEFAULT CHR(0),         -- 65.引数63
    iv_args64     IN     VARCHAR2 DEFAULT CHR(0),         -- 66.引数64
    iv_args65     IN     VARCHAR2 DEFAULT CHR(0),         -- 67.引数65
    iv_args66     IN     VARCHAR2 DEFAULT CHR(0),         -- 68.引数66
    iv_args67     IN     VARCHAR2 DEFAULT CHR(0),         -- 69.引数67
    iv_args68     IN     VARCHAR2 DEFAULT CHR(0),         -- 70.引数68
    iv_args69     IN     VARCHAR2 DEFAULT CHR(0),         -- 71.引数69
    iv_args70     IN     VARCHAR2 DEFAULT CHR(0),         -- 72.引数70
    iv_args71     IN     VARCHAR2 DEFAULT CHR(0),         -- 73.引数71
    iv_args72     IN     VARCHAR2 DEFAULT CHR(0),         -- 74.引数72
    iv_args73     IN     VARCHAR2 DEFAULT CHR(0),         -- 75.引数73
    iv_args74     IN     VARCHAR2 DEFAULT CHR(0),         -- 76.引数74
    iv_args75     IN     VARCHAR2 DEFAULT CHR(0),         -- 77.引数75
    iv_args76     IN     VARCHAR2 DEFAULT CHR(0),         -- 78.引数76
    iv_args77     IN     VARCHAR2 DEFAULT CHR(0),         -- 79.引数77
    iv_args78     IN     VARCHAR2 DEFAULT CHR(0),         -- 80.引数78
    iv_args79     IN     VARCHAR2 DEFAULT CHR(0),         -- 81.引数79
    iv_args80     IN     VARCHAR2 DEFAULT CHR(0),         -- 82.引数80
    iv_args81     IN     VARCHAR2 DEFAULT CHR(0),         -- 83.引数81
    iv_args82     IN     VARCHAR2 DEFAULT CHR(0),         -- 84.引数82
    iv_args83     IN     VARCHAR2 DEFAULT CHR(0),         -- 85.引数83
    iv_args84     IN     VARCHAR2 DEFAULT CHR(0),         -- 86.引数84
    iv_args85     IN     VARCHAR2 DEFAULT CHR(0),         -- 87.引数85
    iv_args86     IN     VARCHAR2 DEFAULT CHR(0),         -- 88.引数86
    iv_args87     IN     VARCHAR2 DEFAULT CHR(0),         -- 89.引数87
    iv_args88     IN     VARCHAR2 DEFAULT CHR(0),         -- 90.引数88
    iv_args89     IN     VARCHAR2 DEFAULT CHR(0),         -- 91.引数89
    iv_args90     IN     VARCHAR2 DEFAULT CHR(0),         -- 92.引数90
    iv_args91     IN     VARCHAR2 DEFAULT CHR(0),         -- 93.引数91
    iv_args92     IN     VARCHAR2 DEFAULT CHR(0),         -- 94.引数92
    iv_args93     IN     VARCHAR2 DEFAULT CHR(0),         -- 95.引数93
    iv_args94     IN     VARCHAR2 DEFAULT CHR(0),         -- 96.引数94
    iv_args95     IN     VARCHAR2 DEFAULT CHR(0),         -- 97.引数95
    iv_args96     IN     VARCHAR2 DEFAULT CHR(0),         -- 98.引数96
    iv_args97     IN     VARCHAR2 DEFAULT CHR(0),         -- 99.引数97
    iv_args98     IN     VARCHAR2 DEFAULT CHR(0)          --100.引数98
  );
END XXCCP006A02C;
/
