CREATE OR REPLACE PACKAGE xxpo870003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo870003c(spec)
 * Description      : �����P�����֏���
 * MD.050           : �d���P���^�W�������}�X�^�o�^ Issue1.0 T_MD050_BPO_870
 * MD.070           : �d���P���^�W�������}�X�^�o�^ Issue1.0  T_MD070_BPO_870
 * Version          : 1.11
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
 *  2008/03/10    1.0   Y.Ishikawa       �V�K�쐬
 *  2008/05/01    1.1   Y.Ishikawa       �������ׁA�����[�����ׁA���b�g�}�X�^�̒P���ݒ��
 *                                       �����z�������P���ɏC��
 *  2008/05/07    1.2   Y.Ishikawa       �g���[�X�̎w�E�ɂāA�i�ڃ`�F�b�N����
 *                                       MTL_SYSTEM_ITEMS_B�̎Q�Ƃ��폜
 *  2008/05/09    1.3   Y.Ishikawa       main�̋N�����ԏo�͂ɂāA���t�̃t�H�[�}�b�g��
 *                                       'YYYY/MM/DD HH:MM:SS'��'YYYY/MM/DD HH24:MI:SS'�ɕύX
 *  2008/06/03    1.4   Y.Ishikawa       �d���P���}�X�^���������X�V���ɂP���݂̂����X�V����Ȃ�
 *                                       �s��Ή�
 *  2008/06/03    1.5   Y.Ishikawa       �d���P���}�X�^�̎x����R�[�h���o�^����Ă��Ȃ��ꍇ��
 *                                       �����Ɋ܂߂Ȃ��B
 *                                       ������P����NULL�̏ꍇ�́A0�Ƃ��Čv�Z����B
 *  2008/07/01    1.6   Y.Ishikawa       �����w�b�_�̔z����R�[�h���d����R�[�h�𓱏o��
 *                                       �����P���}�X�^�̎x����ɑ΂��āA���d����R�[�h��
 *                                       �����ɂ��Ē��o����B
 *  2008/07/02    1.7   Y.Ishikawa       ���K�敪�y�єz�����敪�����ȊO�̎�
 *                                       �����[�����ׂ̕�����P�����X�V����Ȃ��B
 *  2008/09/19    1.8   Oracle�R����_   �ύX#193�Ή�
 *  2008/12/04    1.9   Oracle��r���   �{�ԏ�Q#381�Ή�(TRUNC�폜)
 *  2008/12/19    1.10  H.Marushita      �{�ԏ�Q#794�Ή�
 *  2008/12/25    1.11  T.Yoshimoto      ����EBS�W���X�e�[�^�X:�����F�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode            OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_date_type       IN     VARCHAR2,         --   ���t�^�C�v(1:������ 2:�[����)
    iv_start_date      IN     VARCHAR2,         --   ���ԊJ�n��(YYYY/MM/DD)
    iv_end_date        IN     VARCHAR2,         --   ���ԏI����(YYYY/MM/DD)
    iv_commodity_type  IN     VARCHAR2,         --   ���i�敪
    iv_item_type       IN     VARCHAR2,         --   �i�ڋ敪
    iv_item_code1      IN     VARCHAR2,         --   �i�ڃR�[�h1
    iv_item_code2      IN     VARCHAR2,         --   �i�ڃR�[�h2
    iv_item_code3      IN     VARCHAR2,         --   �i�ڃR�[�h3
    iv_customer_code1  IN     VARCHAR2,         --   �����R�[�h1
    iv_customer_code2  IN     VARCHAR2,         --   �����R�[�h2
    iv_customer_code3  IN     VARCHAR2          --   �����R�[�h3
  );
END xxpo870003c;
/
