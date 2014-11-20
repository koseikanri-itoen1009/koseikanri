CREATE OR REPLACE PACKAGE APPS.XXCCP006A01C--��<package_name>�͑啶���ŋL�q���ĉ������B
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP006A01C(spec)
 * Description      : �e�q�R���J�����g�I���X�e�[�^�X�Ď�
 * MD.050           : MD050_CCP_006_A01_�e�q�R���J�����g�I���X�e�[�^�X�Ď�
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/15    1.0   Yohei Takayama   main�V�K�쐬
 *  2009/05/01    1.1   Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    iv_exe_appl_short_name  IN   VARCHAR2,            -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_exe_conc_short_name  IN   VARCHAR2,            -- 2.�N���ΏۃR���J�����g�Z�k��
    iv_child_conc_time      IN   VARCHAR2,            -- 3.�q�R���J�����g�X�e�[�^�X�Ď��Ԋu
    iv_param1               IN   VARCHAR2  DEFAULT NULL,            -- 4.����1
    iv_param2               IN   VARCHAR2  DEFAULT NULL,            -- 5.����2
    iv_param3               IN   VARCHAR2  DEFAULT NULL,            -- 6.����3
    iv_param4               IN   VARCHAR2  DEFAULT NULL,            -- 7.����4
    iv_param5               IN   VARCHAR2  DEFAULT NULL,            -- 8.����5
    iv_param6               IN   VARCHAR2  DEFAULT NULL,            -- 9.����6
    iv_param7               IN   VARCHAR2  DEFAULT NULL,            -- 10.����7
    iv_param8               IN   VARCHAR2  DEFAULT NULL,            -- 11.����8
    iv_param9               IN   VARCHAR2  DEFAULT NULL,            -- 12.����9
    iv_param10              IN   VARCHAR2  DEFAULT NULL,            -- 13.����10
    iv_param11              IN   VARCHAR2  DEFAULT NULL,            -- 14.����11
    iv_param12              IN   VARCHAR2  DEFAULT NULL,            -- 15.����12
    iv_param13              IN   VARCHAR2  DEFAULT NULL,            -- 16.����13
    iv_param14              IN   VARCHAR2  DEFAULT NULL,            -- 17.����14
    iv_param15              IN   VARCHAR2  DEFAULT NULL,            -- 18.����15
    iv_param16              IN   VARCHAR2  DEFAULT NULL,            -- 19.����16
    iv_param17              IN   VARCHAR2  DEFAULT NULL,            -- 20.����17
    iv_param18              IN   VARCHAR2  DEFAULT NULL,            -- 21.����18
    iv_param19              IN   VARCHAR2  DEFAULT NULL,            -- 22.����19
    iv_param20              IN   VARCHAR2  DEFAULT NULL,            -- 23.����20
    iv_param21              IN   VARCHAR2  DEFAULT NULL,            -- 24.����21
    iv_param22              IN   VARCHAR2  DEFAULT NULL,            -- 25.����22
    iv_param23              IN   VARCHAR2  DEFAULT NULL,            -- 26.����23
    iv_param24              IN   VARCHAR2  DEFAULT NULL,            -- 27.����24
    iv_param25              IN   VARCHAR2  DEFAULT NULL,            -- 28.����25
    iv_param26              IN   VARCHAR2  DEFAULT NULL,            -- 29.����26
    iv_param27              IN   VARCHAR2  DEFAULT NULL,            -- 30.����27
    iv_param28              IN   VARCHAR2  DEFAULT NULL,            -- 31.����28
    iv_param29              IN   VARCHAR2  DEFAULT NULL,            -- 32.����29
    iv_param30              IN   VARCHAR2  DEFAULT NULL,            -- 33.����30
    iv_param31              IN   VARCHAR2  DEFAULT NULL,            -- 34.����31
    iv_param32              IN   VARCHAR2  DEFAULT NULL,            -- 35.����32
    iv_param33              IN   VARCHAR2  DEFAULT NULL,            -- 36.����33
    iv_param34              IN   VARCHAR2  DEFAULT NULL,            -- 37.����34
    iv_param35              IN   VARCHAR2  DEFAULT NULL,            -- 38.����35
    iv_param36              IN   VARCHAR2  DEFAULT NULL,            -- 39.����36
    iv_param37              IN   VARCHAR2  DEFAULT NULL,            -- 40.����37
    iv_param38              IN   VARCHAR2  DEFAULT NULL,            -- 41.����38
    iv_param39              IN   VARCHAR2  DEFAULT NULL,            -- 42.����39
    iv_param40              IN   VARCHAR2  DEFAULT NULL,            -- 43.����40
    iv_param41              IN   VARCHAR2  DEFAULT NULL,            -- 44.����41
    iv_param42              IN   VARCHAR2  DEFAULT NULL,            -- 45.����42
    iv_param43              IN   VARCHAR2  DEFAULT NULL,            -- 46.����43
    iv_param44              IN   VARCHAR2  DEFAULT NULL,            -- 47.����44
    iv_param45              IN   VARCHAR2  DEFAULT NULL,            -- 48.����45
    iv_param46              IN   VARCHAR2  DEFAULT NULL,            -- 49.����46
    iv_param47              IN   VARCHAR2  DEFAULT NULL,            -- 50.����47
    iv_param48              IN   VARCHAR2  DEFAULT NULL,            -- 51.����48
    iv_param49              IN   VARCHAR2  DEFAULT NULL,            -- 52.����49
    iv_param50              IN   VARCHAR2  DEFAULT NULL,            -- 53.����50
    iv_param51              IN   VARCHAR2  DEFAULT NULL,            -- 54.����51
    iv_param52              IN   VARCHAR2  DEFAULT NULL,            -- 55.����52
    iv_param53              IN   VARCHAR2  DEFAULT NULL,            -- 56.����53
    iv_param54              IN   VARCHAR2  DEFAULT NULL,            -- 57.����54
    iv_param55              IN   VARCHAR2  DEFAULT NULL,            -- 58.����55
    iv_param56              IN   VARCHAR2  DEFAULT NULL,            -- 59.����56
    iv_param57              IN   VARCHAR2  DEFAULT NULL,            -- 60.����57
    iv_param58              IN   VARCHAR2  DEFAULT NULL,            -- 61.����58
    iv_param59              IN   VARCHAR2  DEFAULT NULL,            -- 62.����59
    iv_param60              IN   VARCHAR2  DEFAULT NULL,            -- 63.����60
    iv_param61              IN   VARCHAR2  DEFAULT NULL,            -- 64.����61
    iv_param62              IN   VARCHAR2  DEFAULT NULL,            -- 65.����62
    iv_param63              IN   VARCHAR2  DEFAULT NULL,            -- 66.����63
    iv_param64              IN   VARCHAR2  DEFAULT NULL,            -- 67.����64
    iv_param65              IN   VARCHAR2  DEFAULT NULL,            -- 68.����65
    iv_param66              IN   VARCHAR2  DEFAULT NULL,            -- 69.����66
    iv_param67              IN   VARCHAR2  DEFAULT NULL,            -- 70.����67
    iv_param68              IN   VARCHAR2  DEFAULT NULL,            -- 71.����68
    iv_param69              IN   VARCHAR2  DEFAULT NULL,            -- 72.����69
    iv_param70              IN   VARCHAR2  DEFAULT NULL,            -- 73.����70
    iv_param71              IN   VARCHAR2  DEFAULT NULL,            -- 74.����71
    iv_param72              IN   VARCHAR2  DEFAULT NULL,            -- 75.����72
    iv_param73              IN   VARCHAR2  DEFAULT NULL,            -- 76.����73
    iv_param74              IN   VARCHAR2  DEFAULT NULL,            -- 77.����74
    iv_param75              IN   VARCHAR2  DEFAULT NULL,            -- 78.����75
    iv_param76              IN   VARCHAR2  DEFAULT NULL,            -- 79.����76
    iv_param77              IN   VARCHAR2  DEFAULT NULL,            -- 80.����77
    iv_param78              IN   VARCHAR2  DEFAULT NULL,            -- 81.����78
    iv_param79              IN   VARCHAR2  DEFAULT NULL,            -- 82.����79
    iv_param80              IN   VARCHAR2  DEFAULT NULL,            -- 83.����80
    iv_param81              IN   VARCHAR2  DEFAULT NULL,            -- 84.����81
    iv_param82              IN   VARCHAR2  DEFAULT NULL,            -- 85.����82
    iv_param83              IN   VARCHAR2  DEFAULT NULL,            -- 86.����83
    iv_param84              IN   VARCHAR2  DEFAULT NULL,            -- 87.����84
    iv_param85              IN   VARCHAR2  DEFAULT NULL,            -- 88.����85
    iv_param86              IN   VARCHAR2  DEFAULT NULL,            -- 89.����86
    iv_param87              IN   VARCHAR2  DEFAULT NULL,            -- 90.����87
    iv_param88              IN   VARCHAR2  DEFAULT NULL,            -- 91.����88
    iv_param89              IN   VARCHAR2  DEFAULT NULL,            -- 92.����89
    iv_param90              IN   VARCHAR2  DEFAULT NULL,            -- 93.����90
    iv_param91              IN   VARCHAR2  DEFAULT NULL,            -- 94.����91
    iv_param92              IN   VARCHAR2  DEFAULT NULL,            -- 95.����92
    iv_param93              IN   VARCHAR2  DEFAULT NULL,            -- 96.����93
    iv_param94              IN   VARCHAR2  DEFAULT NULL,            -- 97.����94
    iv_param95              IN   VARCHAR2  DEFAULT NULL,            -- 98.����95
    iv_param96              IN   VARCHAR2  DEFAULT NULL,            -- 99.����96
    iv_param97              IN   VARCHAR2  DEFAULT NULL             -- 100.����97
  );
END XXCCP006A01C;
/
