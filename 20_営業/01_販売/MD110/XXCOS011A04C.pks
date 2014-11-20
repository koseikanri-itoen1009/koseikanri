CREATE OR REPLACE PACKAGE XXCOS011A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A04C (spec)
 * Description      : ���ɗ\��f�[�^�̍쐬���s��
 * MD.050           : ���ɗ\��f�[�^�쐬 (MD050_COS_011_A04)
 * Version          : 1.3
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
 *  2008/12/18    1.0   K.Kiriu         �V�K�쐬
 *  2008/02/27    1.1   K.Kiriu         [COS_147]�ŗ��̎擾�����ǉ�
 *  2009/03/10    1.2   T.Kitajima      [T1_0030]�ڋq�i�ڂ̖����G���[�Ή�
 *  2009/04/01    1.3   T.Kitajima      [T1_0043]�ڋq�i�ڂ̍i�荞�ݏ����ɒP�ʂ�ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_name    IN     VARCHAR2,         --   1.�t�@�C����
    iv_to_s_code    IN     VARCHAR2,         --   2.������ۊǏꏊ
    iv_edi_c_code   IN     VARCHAR2,         --   3.EDI�`�F�[���X�R�[�h
    iv_edi_f_number IN     VARCHAR2          --   4.EDI�`���ǔ�
  );
END XXCOS011A04C;
/
