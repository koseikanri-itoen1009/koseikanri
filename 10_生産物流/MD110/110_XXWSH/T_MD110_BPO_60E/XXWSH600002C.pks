CREATE OR REPLACE PACKAGE xxwsh600002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600002c(spec)
 * Description      : ���o�ɔz���v���񒊏o����
 * MD.050           : T_MD050_BPO_601_�z�Ԕz���v��
 * MD.070           : T_MD070_BPO_60E_���o�ɔz���v���񒊏o����
 * Version          : 1.28
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
 *  2008/04/01    1.0   M.Ikeda          �V�K�쐬
 *  2008/06/04    1.1   N.Yoshida        �ړ����b�g�ڍוR�t���Ή�
 *  2008/06/05    1.2   M.Hokkanji       �����e�X�g�p�b��Ή�:CSV�o�͏����̏o�͏ꏊ��ύX
 *                                       ���ԃe�[�u���o�^�f�[�^���o����ہA�z�Ԕz���v��A
 *                                       �h�I���Ƀf�[�^�����݂��Ȃ��ꍇ�ł��f�[�^���o�͂�
 *                                       ���悤�ɏC��
 *  2008/06/06    1.3   M.HOKKANJI       �b�r�u�o�͏����ŃG���[��������F_CLOSE_ALL���Ă���̂�
 *                                       �ʂɃN���[�Y����悤�ɕύX
 *  2008/06/06    1.4   M.HOKKANJI       �����e�X�g440�s��Ή�#66
 *  2008/06/06    1.5   M.HOKKANJI       �����e�X�g440�s��Ή�#65
 *  2008/06/11    1.6   M.NOMURA         �����e�X�g WF�Ή�
 *  2008/06/12    1.7   M.NOMURA         �����e�X�g �s��Ή�#9
 *  2008/06/16    1.8   M.NOMURA         �����e�X�g 440 �s��Ή�#64
 *  2008/06/18    1.9   M.HOKKANJI       �V�X�e���e�X�g�s��Ή�#147,#187
 *  2008/06/23    1.10  M.NOMURA         �V�X�e���e�X�g�s��Ή�#217
 *  2008/06/27    1.11  M.NOMURA         �V�X�e���e�X�g�s��Ή�#303
 *  2008/07/04    1.12  M.NOMURA         �V�X�e���e�X�g�s��Ή�#390
 *  2008/07/16    1.13  Oracle �R�� ��_ I_S_192,T_S_443,�w�E240�Ή�
 *  2008/08/04    1.14  M.NOMURA         �ǉ������s��Ή�
 *  2008/08/12    1.15  N.Fukuda         �ۑ�#32�Ή�
 *  2008/08/12    1.15  N.Fukuda         �ۑ�#48(�ύX�v��#164)�Ή�
 *  2008/09/01    1.16  Y.Yamamoto       PT 2-2_17 �w�E17�Ή�
 *  2008/09/09    1.17  N.Fukuda         TE080_600�w�E#30�Ή�
 *  2008/09/10    1.17  N.Fukuda         �Q��View�̕ύX(�p�[�e�B����ڋq�ɕύX)
 *  2008/09/19    1.18  M.Nomura         T_S_453 460 468�Ή�
 *  2008/09/25    1.19  M.Nomura         TE080_600�w�E#31�Ή�
 *  2008/09/25    1.20  M.Nomura         ����#26�Ή�
 *  2008/10/06    1.21  M.Nomura         ����#306�Ή�
 *  2008/10/07    1.22  M.Nomura         TE080_600�w�E#27�Ή�
 *  2008/10/14    1.23  M.Nomura         PT2-2_17�w�E71�Ή�
 *  2008/10/20    1.24  M.Nomura         ����#417�Ή�
 *  2008/10/23    1.25  M.Nomura         T_S_440�Ή�
 *  2008/10/28    1.26  M.Nomura         ����#143�Ή�
 *  2008/11/12    1.27  M.Nomura         ����#626�Ή�
 *  2008/11/27    1.28  M.Nomura         �{��177�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf              OUT NOCOPY  VARCHAR2    -- �G���[���b�Z�[�W #�Œ�#
     ,retcode             OUT NOCOPY  VARCHAR2    -- �G���[�R�[�h     #�Œ�#
     ,iv_dept_code_01     IN  VARCHAR2            -- 01 : ����_01
     ,iv_dept_code_02     IN  VARCHAR2            -- 02 : ����_02
     ,iv_dept_code_03     IN  VARCHAR2            -- 03 : ����_03
     ,iv_dept_code_04     IN  VARCHAR2            -- 04 : ����_04
     ,iv_dept_code_05     IN  VARCHAR2            -- 05 : ����_05
     ,iv_dept_code_06     IN  VARCHAR2            -- 06 : ����_06
     ,iv_dept_code_07     IN  VARCHAR2            -- 07 : ����_07
     ,iv_dept_code_08     IN  VARCHAR2            -- 08 : ����_08
     ,iv_dept_code_09     IN  VARCHAR2            -- 09 : ����_09
     ,iv_dept_code_10     IN  VARCHAR2            -- 10 : ����_10
     ,iv_fix_class        IN  VARCHAR2            -- 11 : �\��m��敪
     ,iv_date_cutoff      IN  VARCHAR2            -- 12 : ���ߎ��{��
     ,iv_cutoff_from      IN  VARCHAR2            -- 13 : ���ߎ��{����From
     ,iv_cutoff_to        IN  VARCHAR2            -- 14 : ���ߎ��{����To
     ,iv_date_fix         IN  VARCHAR2            -- 15 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2            -- 16 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2            -- 17 : �m��ʒm���{����To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
     ,iv_ship_date_from   IN  VARCHAR2            -- 18 : �o�ɓ�From
     ,iv_ship_date_to     IN  VARCHAR2            -- 19 : �o�ɓ�To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
    ) ;
--
END xxwsh600002c ;
/
