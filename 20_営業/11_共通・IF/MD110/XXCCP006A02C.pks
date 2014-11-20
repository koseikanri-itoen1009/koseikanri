CREATE OR REPLACE PACKAGE APPS.XXCCP006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP006A02C(spec)
 * Description      : ���I�p�����[�^�R���J�����g�Ή�
 * MD.050           : ���I�p�����[�^�R���J�����g�Ή� MD050_CCP_006_A02
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���I�p�����[�^�R���J�����g�Ή��v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2009/01/13     1.0  Masakazu Yamashita  main�V�K�쐬
 *  2009/05/01     1.1  Masayuki.Sano       ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *
 *****************************************************************************************/
--
  --���I�p�����[�^�R���J�����g�Ή��v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,                        --  �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,                        --  �G���[�R�[�h     #�Œ�#
    iv_app_name   IN     VARCHAR2 DEFAULT NULL,           --  1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_prg_name   IN     VARCHAR2 DEFAULT NULL,           --  2.�N���ΏۃR���J�����g�Z�k��
    iv_args1      IN     VARCHAR2 DEFAULT CHR(0),         --  3.����1
    iv_args2      IN     VARCHAR2 DEFAULT CHR(0),         --  4.����2
    iv_args3      IN     VARCHAR2 DEFAULT CHR(0),         --  5.����3
    iv_args4      IN     VARCHAR2 DEFAULT CHR(0),         --  6.����4
    iv_args5      IN     VARCHAR2 DEFAULT CHR(0),         --  7.����5
    iv_args6      IN     VARCHAR2 DEFAULT CHR(0),         --  8.����6
    iv_args7      IN     VARCHAR2 DEFAULT CHR(0),         --  9.����7
    iv_args8      IN     VARCHAR2 DEFAULT CHR(0),         -- 10.����8
    iv_args9      IN     VARCHAR2 DEFAULT CHR(0),         -- 11.����9
    iv_args10     IN     VARCHAR2 DEFAULT CHR(0),         -- 12.����10
    iv_args11     IN     VARCHAR2 DEFAULT CHR(0),         -- 13.����11
    iv_args12     IN     VARCHAR2 DEFAULT CHR(0),         -- 14.����12
    iv_args13     IN     VARCHAR2 DEFAULT CHR(0),         -- 15.����13
    iv_args14     IN     VARCHAR2 DEFAULT CHR(0),         -- 16.����14
    iv_args15     IN     VARCHAR2 DEFAULT CHR(0),         -- 17.����15
    iv_args16     IN     VARCHAR2 DEFAULT CHR(0),         -- 18.����16
    iv_args17     IN     VARCHAR2 DEFAULT CHR(0),         -- 19.����17
    iv_args18     IN     VARCHAR2 DEFAULT CHR(0),         -- 20.����18
    iv_args19     IN     VARCHAR2 DEFAULT CHR(0),         -- 21.����19
    iv_args20     IN     VARCHAR2 DEFAULT CHR(0),         -- 22.����20
    iv_args21     IN     VARCHAR2 DEFAULT CHR(0),         -- 23.����21
    iv_args22     IN     VARCHAR2 DEFAULT CHR(0),         -- 24.����22
    iv_args23     IN     VARCHAR2 DEFAULT CHR(0),         -- 25.����23
    iv_args24     IN     VARCHAR2 DEFAULT CHR(0),         -- 26.����24
    iv_args25     IN     VARCHAR2 DEFAULT CHR(0),         -- 27.����25
    iv_args26     IN     VARCHAR2 DEFAULT CHR(0),         -- 28.����26
    iv_args27     IN     VARCHAR2 DEFAULT CHR(0),         -- 29.����27
    iv_args28     IN     VARCHAR2 DEFAULT CHR(0),         -- 30.����28
    iv_args29     IN     VARCHAR2 DEFAULT CHR(0),         -- 31.����29
    iv_args30     IN     VARCHAR2 DEFAULT CHR(0),         -- 32.����30
    iv_args31     IN     VARCHAR2 DEFAULT CHR(0),         -- 33.����31
    iv_args32     IN     VARCHAR2 DEFAULT CHR(0),         -- 34.����32
    iv_args33     IN     VARCHAR2 DEFAULT CHR(0),         -- 35.����33
    iv_args34     IN     VARCHAR2 DEFAULT CHR(0),         -- 36.����34
    iv_args35     IN     VARCHAR2 DEFAULT CHR(0),         -- 37.����35
    iv_args36     IN     VARCHAR2 DEFAULT CHR(0),         -- 38.����36
    iv_args37     IN     VARCHAR2 DEFAULT CHR(0),         -- 39.����37
    iv_args38     IN     VARCHAR2 DEFAULT CHR(0),         -- 40.����38
    iv_args39     IN     VARCHAR2 DEFAULT CHR(0),         -- 41.����39
    iv_args40     IN     VARCHAR2 DEFAULT CHR(0),         -- 42.����40
    iv_args41     IN     VARCHAR2 DEFAULT CHR(0),         -- 43.����41
    iv_args42     IN     VARCHAR2 DEFAULT CHR(0),         -- 44.����42
    iv_args43     IN     VARCHAR2 DEFAULT CHR(0),         -- 45.����43
    iv_args44     IN     VARCHAR2 DEFAULT CHR(0),         -- 46.����44
    iv_args45     IN     VARCHAR2 DEFAULT CHR(0),         -- 47.����45
    iv_args46     IN     VARCHAR2 DEFAULT CHR(0),         -- 48.����46
    iv_args47     IN     VARCHAR2 DEFAULT CHR(0),         -- 49.����47
    iv_args48     IN     VARCHAR2 DEFAULT CHR(0),         -- 50.����48
    iv_args49     IN     VARCHAR2 DEFAULT CHR(0),         -- 51.����49
    iv_args50     IN     VARCHAR2 DEFAULT CHR(0),         -- 52.����50
    iv_args51     IN     VARCHAR2 DEFAULT CHR(0),         -- 53.����51
    iv_args52     IN     VARCHAR2 DEFAULT CHR(0),         -- 54.����52
    iv_args53     IN     VARCHAR2 DEFAULT CHR(0),         -- 55.����53
    iv_args54     IN     VARCHAR2 DEFAULT CHR(0),         -- 56.����54
    iv_args55     IN     VARCHAR2 DEFAULT CHR(0),         -- 57.����55
    iv_args56     IN     VARCHAR2 DEFAULT CHR(0),         -- 58.����56
    iv_args57     IN     VARCHAR2 DEFAULT CHR(0),         -- 59.����57
    iv_args58     IN     VARCHAR2 DEFAULT CHR(0),         -- 60.����58
    iv_args59     IN     VARCHAR2 DEFAULT CHR(0),         -- 61.����59
    iv_args60     IN     VARCHAR2 DEFAULT CHR(0),         -- 62.����60
    iv_args61     IN     VARCHAR2 DEFAULT CHR(0),         -- 63.����61
    iv_args62     IN     VARCHAR2 DEFAULT CHR(0),         -- 64.����62
    iv_args63     IN     VARCHAR2 DEFAULT CHR(0),         -- 65.����63
    iv_args64     IN     VARCHAR2 DEFAULT CHR(0),         -- 66.����64
    iv_args65     IN     VARCHAR2 DEFAULT CHR(0),         -- 67.����65
    iv_args66     IN     VARCHAR2 DEFAULT CHR(0),         -- 68.����66
    iv_args67     IN     VARCHAR2 DEFAULT CHR(0),         -- 69.����67
    iv_args68     IN     VARCHAR2 DEFAULT CHR(0),         -- 70.����68
    iv_args69     IN     VARCHAR2 DEFAULT CHR(0),         -- 71.����69
    iv_args70     IN     VARCHAR2 DEFAULT CHR(0),         -- 72.����70
    iv_args71     IN     VARCHAR2 DEFAULT CHR(0),         -- 73.����71
    iv_args72     IN     VARCHAR2 DEFAULT CHR(0),         -- 74.����72
    iv_args73     IN     VARCHAR2 DEFAULT CHR(0),         -- 75.����73
    iv_args74     IN     VARCHAR2 DEFAULT CHR(0),         -- 76.����74
    iv_args75     IN     VARCHAR2 DEFAULT CHR(0),         -- 77.����75
    iv_args76     IN     VARCHAR2 DEFAULT CHR(0),         -- 78.����76
    iv_args77     IN     VARCHAR2 DEFAULT CHR(0),         -- 79.����77
    iv_args78     IN     VARCHAR2 DEFAULT CHR(0),         -- 80.����78
    iv_args79     IN     VARCHAR2 DEFAULT CHR(0),         -- 81.����79
    iv_args80     IN     VARCHAR2 DEFAULT CHR(0),         -- 82.����80
    iv_args81     IN     VARCHAR2 DEFAULT CHR(0),         -- 83.����81
    iv_args82     IN     VARCHAR2 DEFAULT CHR(0),         -- 84.����82
    iv_args83     IN     VARCHAR2 DEFAULT CHR(0),         -- 85.����83
    iv_args84     IN     VARCHAR2 DEFAULT CHR(0),         -- 86.����84
    iv_args85     IN     VARCHAR2 DEFAULT CHR(0),         -- 87.����85
    iv_args86     IN     VARCHAR2 DEFAULT CHR(0),         -- 88.����86
    iv_args87     IN     VARCHAR2 DEFAULT CHR(0),         -- 89.����87
    iv_args88     IN     VARCHAR2 DEFAULT CHR(0),         -- 90.����88
    iv_args89     IN     VARCHAR2 DEFAULT CHR(0),         -- 91.����89
    iv_args90     IN     VARCHAR2 DEFAULT CHR(0),         -- 92.����90
    iv_args91     IN     VARCHAR2 DEFAULT CHR(0),         -- 93.����91
    iv_args92     IN     VARCHAR2 DEFAULT CHR(0),         -- 94.����92
    iv_args93     IN     VARCHAR2 DEFAULT CHR(0),         -- 95.����93
    iv_args94     IN     VARCHAR2 DEFAULT CHR(0),         -- 96.����94
    iv_args95     IN     VARCHAR2 DEFAULT CHR(0),         -- 97.����95
    iv_args96     IN     VARCHAR2 DEFAULT CHR(0),         -- 98.����96
    iv_args97     IN     VARCHAR2 DEFAULT CHR(0),         -- 99.����97
    iv_args98     IN     VARCHAR2 DEFAULT CHR(0)          --100.����98
  );
END XXCCP006A02C;
/
