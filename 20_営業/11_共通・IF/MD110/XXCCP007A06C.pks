CREATE OR REPLACE PACKAGE XXCCP007A06C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP007A06C(spec)
 * Description      : �s���o��Z�f�[�^�폜
 * Version          : 1.00
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/03    1.00  SCSK ����ˍ��D [E_�{�ғ�_09865]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_invoice_num   IN    VARCHAR2,         --   �o��Z���ԍ�
    iv_exe_mode      IN    VARCHAR2          --   ���s���[�h(0:�Ώۊm�F�A1:�f�[�^�X�V)
  );
END XXCCP007A06C;
/
