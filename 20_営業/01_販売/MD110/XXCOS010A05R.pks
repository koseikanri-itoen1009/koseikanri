CREATE OR REPLACE PACKAGE APPS.XXCOS010A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A05R(spec)
 * Description      : �󒍃G���[���X�g
 * MD.050           : �󒍃G���[���X�g MD050_COS_010_A05
 * Version          : 1.7
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
 *  2008/12/17    1.0   K.Kumamoto       �V�K�쐬
 *  2009/02/13    1.1   M.Yamaki         [COS_072]�G���[���X�g��ʃR�[�h�̑Ή�
 *  2009/02/24    1.2   T.Nakamura       [COS_133]���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/06/19    1.3   N.Nishimura      [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/07/23    1.4   N.Maeda          [0000300]���b�N�����C��
 *  2009/08/03    1.5   M.Sano           [0000902]�󒍃G���[���X�g�̏I���X�e�[�^�X�ύX
 *  2009/09/29    1.6   N.Maeda          [0001338]�v���V�[�W��execute_svf�̓Ɨ��g�����U�N�V������
 *  2010/01/19    1.7   M.Sano           [E_�{�ғ�_01159]�Ή�
 *                                       �E���̓p�����[�^�̒ǉ�
 *                                         (���s�敪����_��`�F�[���X�EDI��M��(FROM)�EDI��M��(TO))
 *                                       �E�Ĕ��s�̉\��
 *                                       �E�o�͑Ώۂ̃G���[����l���X�g�Ő���
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_err_list_type IN     VARCHAR2      --   �G���[���X�g���
-- 2010/01/13 M.Sano Ver.1.7 add start
   ,iv_request_type             IN VARCHAR2 DEFAULT NULL --   ���s�敪
   ,iv_base_code                IN VARCHAR2 DEFAULT NULL --   ���_�R�[�h
   ,iv_edi_chain_code           IN VARCHAR2 DEFAULT NULL --   �`�F�[���X�R�[�h
   ,iv_edi_received_date_from   IN VARCHAR2 DEFAULT NULL --   EDI��M���iFROM�j
   ,iv_edi_received_date_to     IN VARCHAR2 DEFAULT NULL --   EDI��M���iTO)
-- 2010/01/13 M.Sano Ver.1.7 add end
  );
END XXCOS010A05R;
/
