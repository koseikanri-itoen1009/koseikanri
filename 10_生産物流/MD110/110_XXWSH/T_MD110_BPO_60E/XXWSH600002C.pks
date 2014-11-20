CREATE OR REPLACE PACKAGE xxwsh600002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600002c(spec)
 * Description      : ���o�ɔz���v���񒊏o����
 * MD.050           : T_MD050_BPO_601_�z�Ԕz���v��
 * MD.070           : T_MD070_BPO_60E_���o�ɔz���v���񒊏o����
 * Version          : 1.10
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
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf              OUT NOCOPY  VARCHAR2    -- �G���[���b�Z�[�W #�Œ�#
     ,retcode             OUT NOCOPY  VARCHAR2    -- �G���[�R�[�h     #�Œ�#
     ,iv_dept_code        IN  VARCHAR2            -- 01 : ����
     ,iv_fix_class        IN  VARCHAR2            -- 02 : �\��m��敪
     ,iv_date_cutoff      IN  VARCHAR2            -- 03 : ���ߎ��{��
     ,iv_cutoff_from      IN  VARCHAR2            -- 04 : ���ߎ��{����From
     ,iv_cutoff_to        IN  VARCHAR2            -- 05 : ���ߎ��{����To
     ,iv_date_fix         IN  VARCHAR2            -- 06 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2            -- 07 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2            -- 08 : �m��ʒm���{����To
    ) ;
--
END xxwsh600002c ;
/
