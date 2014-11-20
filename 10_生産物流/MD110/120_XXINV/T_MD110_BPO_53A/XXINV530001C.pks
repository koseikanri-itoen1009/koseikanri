CREATE OR REPLACE PACKAGE xxinv530001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv5300001(spec)
 * Description      : �I�����ʃC���^�[�t�F�[�X
 * MD.050           : �I��(T_MD050_BPO_530)
 * MD.070           : �I�����ʃC���^�[�t�F�[�X(T_MD070_BPO_53A)
 * Version          : 1.9
 *
 * Program List
 *  -------------------------------------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------------------------------------------------------------------
 *  main                  P          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * -----------------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * -----------------------------------------------------------------------------------
 *  2008/03/14    1.0   M.Inamine        �V�K�쐬
 *  2008/05/02    1.1   M.Inamine        �C��(�yBPO_530_�I���z�C���˗����� No2�̑Ή�)
 *                                           (�yBPO_530_�I���z�C���˗����� No4�̑Ή�)
 *  2008/05/07    1.2   M.Inamine        �C��(20080507_03 No5�̑Ή��A���b�g���͋󔒂��o��)
 *  2008/05/08    1.3   M.Inamine        �C��(�d�l�ύX�Ή��A���b�g�Ǘ��O�̏ꍇ���b�gID��NULL��)
 *  2008/05/09    1.4   M.Inamine        �C��(2008/05/08 03 �s��Ή��F���t�����̌��)
 *  2008/05/20    1.4   T.Ikehara        �C��(�s�ID6�Ή��F�o�̓��b�Z�[�W�̌��)
 *  2008/09/04    1.5   H.Itou           �C��(PT 6-3_39�w�E#12 ���ISQL�̕ϐ����o�C���h�ϐ���)
 *  2008/09/11    1.6   T.Ohashi         �C��(PT 6-3_39�w�E74 �Ή�)
 *  2008/09/16    1.7   T.Ikehara        �C��(�s�ID7�Ή��F�d���폜�̓G���[�Ƃ��Ȃ�)
 *  2008/10/15    1.8   T.Ikehara        �C��(�s�ID8�Ή��F�d���폜�Ώۃf�[�^��
 *                                                           �Ó����`�F�b�N�ΏۊO�ɏC�� )
 *  2008/12/06    1.9   H.Itou           �C��(�{�ԏ�Q#510�Ή��F���t�͕ϊ����Ĕ�r)
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT    VARCHAR2    -- �G���[���b�Z�[�W
   ,retcode               OUT    VARCHAR2    -- ���^�[���E�R�[�h  
   ,iv_report_post_code   IN     VARCHAR2    -- �񍐕���
   ,iv_whse_code          IN     VARCHAR2    -- �q�ɃR�[�h
   ,iv_item_type          IN     VARCHAR2);  -- �i�ڋ敪
--
END xxinv530001c;
/
