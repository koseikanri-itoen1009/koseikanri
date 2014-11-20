CREATE OR REPLACE PACKAGE xxwsh600004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH600004C(spec)
 * Description      : �g�g�s���o�ɔz�Ԋm���񒊏o����
 * MD.050           : T_MD050_BPO_601_�z�Ԕz���v��
 * MD.070           : T_MD070_BPO_60F_�g�g�s���o�ɔz�Ԋm���񒊏o����
 * Version          : 1.17
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
 *  2008/05/02    1.0   M.Ikeda          �V�K�쐬
 *  2008/06/04    1.1   N.Yoshida        �ړ����b�g�ڍוR�t���Ή�
 *  2008/06/11    1.2   M.Hokkanji       �z�Ԃ��g�܂�Ă��Ȃ��ꍇ�ł��o�͂����悤�ɏC��
 *  2008/06/12    1.3   M.Nomura         �����e�X�g �s��Ή�#7
 *  2008/06/17    1.4   M.Hokkanji       �V�X�e���e�X�g �s��Ή�#153
 *  2008/06/19    1.5   M.Nomura         �V�X�e���e�X�g �s��Ή�#193
 *  2008/06/27    1.6   M.Nomura         �V�X�e���e�X�g �s��Ή�#303
 *  2008/07/04    1.7   M.Nomura         �V�X�e���e�X�g �s��Ή�#193 2���
 *  2008/07/17    1.8   Oracle �R�� ��_ I_S_192,T_S_443,�w�E240�Ή�
 *  2008/07/22    1.9   N.Fukuda         I_S_001�Ή�(�\��1������/�����敪�Ŏg�p����)
 *  2008/08/08    1.10  Oracle �R�� ��_ TE080_400�w�E#83,�ۑ�#32
 *  2008/08/11    1.10  N.Fukuda         �w�������̒��o����SQL�̕s��Ή�
 *  2008/08/12    1.10  N.Fukuda         �ۑ�#48(�ύX�v��#164)�Ή�
 *  2008/08/29    1.11  N.Fukuda         TE080_600�w�E#27(1)�Ή�(�S�����׎���̃p�^�[��)
 *  2008/08/29    1.11  N.Fukuda         TE080_600�w�E#27(3)�Ή�(�ꕔ���׎���̃p�^�[��)
 *  2008/08/29    1.11  N.Fukuda         TE080_600�w�E#28�Ή�
 *  2008/08/29    1.11  N.Fukuda         TE080_600�w�E#29�Ή�(TE080_400�w�E#83�̍ďC��)
 *  2008/08/29    1.12  N.Fukuda         ����w�b�_�ɕi�ڐ��ʁE���b�g���ʂ�0���Z�b�g����Ă���
 *  2008/09/09    1.13  N.Fukuda         TE080_600�w�E#30�Ή�
 *  2008/09/10    1.13  N.Fukuda         �Q��View�̕ύX(�p�[�e�B����ڋq�ɕύX)
 *  2008/09/25    1.14  M.Nomura         ����#26�Ή�
 *  2008/10/07    1.15  M.Nomura         TE080_600�w�E#27�Ή�
 *  2008/11/07    1.16  N.Fukuda         �����w�E#143�Ή�
 *  2009/01/26    1.17  N.Yoshida        �{��1017�Ή��A�{��#1044�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf              OUT NOCOPY  VARCHAR2    -- �G���[���b�Z�[�W #�Œ�#
     ,retcode             OUT NOCOPY  VARCHAR2    -- �G���[�R�[�h     #�Œ�#
     ,iv_dept_code_01     IN  VARCHAR2            -- 01 : ����_01
     ,iv_dept_code_02     IN  VARCHAR2            -- 02 : ����_02(2008/07/17 Add)
     ,iv_dept_code_03     IN  VARCHAR2            -- 03 : ����_03(2008/07/17 Add)
     ,iv_dept_code_04     IN  VARCHAR2            -- 04 : ����_04(2008/07/17 Add)
     ,iv_dept_code_05     IN  VARCHAR2            -- 05 : ����_05(2008/07/17 Add)
     ,iv_dept_code_06     IN  VARCHAR2            -- 06 : ����_06(2008/07/17 Add)
     ,iv_dept_code_07     IN  VARCHAR2            -- 07 : ����_07(2008/07/17 Add)
     ,iv_dept_code_08     IN  VARCHAR2            -- 08 : ����_08(2008/07/17 Add)
     ,iv_dept_code_09     IN  VARCHAR2            -- 09 : ����_09(2008/07/17 Add)
     ,iv_dept_code_10     IN  VARCHAR2            -- 10 : ����_10(2008/07/17 Add)
     ,iv_date_fix         IN  VARCHAR2            -- 11 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2            -- 12 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2            -- 13 : �m��ʒm���{����To
    ) ;
--
END xxwsh600004c ;
/
