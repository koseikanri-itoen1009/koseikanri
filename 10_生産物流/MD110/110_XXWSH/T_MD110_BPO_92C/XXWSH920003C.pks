CREATE OR REPLACE PACKAGE XXWSH920003C AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920003C(spec)
 * Description      : �ړ��w�������˗������쐬
 * MD.050           : ���Y�������ʁi�o�ׁE�ړ��������j T_MD050_BPO921
 * MD.070           : �ړ��w�������˗������쐬 T_MD070_BPO92C
 * Version          : 1.6
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
 *  2008/04/23   1.0   Oracle �y�c ��   ����쐬
 *  2008/06/11   1.1   Oracle ���c ��   �f�o�b�O�o�͐���Ή��B�G���[�n���h�����O�s���̏C���B
 *                                      �d�ʗe�ώZ�o/�ύڌ����Z�o�������v���V�[�W����(C-15)�B
 *  2008/07/02   1.2   Oracle ���c ��   ST�s�No368�Ή�
 *                                      �݌ɕ�[���[���������ŁA��[��̒����q�ɋ敪�������̏ꍇ�̂�
 *                                      �z�����ݒ肷��悤�ɏC���B
 *                                      ���̑��̏ꍇ�ɂ�NULL��ݒ�B(�z���斈�̏W����s��Ȃ����߁B)
 *  2008/07/31   1.3   Oracle ���c ��   ST�s�No522�Ή�
 *                                      SUBMAIN�̃��^�[���R�[�h�ϐ��̒�`���ɂ��
 *                                      �G���[�n���h�����O�s���̏C���B
 *  2008/10/03   1.4   Oracle ���c ��   �����ۑ�#32�A�����ۑ�#58/�����ύX#166�A
 *                                      �����ۑ�#66/�����ύX#173�A�����ύX#183
 *                                      �����ύX#233
 *  2008/10/20   1.5   Oracle ���c      �����e�X�g�w�E#240
 *  2008/12/15   1.6   Oracle ���c      �{�ԏ�Q#631
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,   -- �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT NOCOPY VARCHAR2,   -- �G���[�R�[�h     #�Œ�#
    iv_action_type           IN         VARCHAR2,   -- �������
    iv_req_mov_no            IN         VARCHAR2,   -- �˗�/�ړ�No
    iv_deliver_from          IN         VARCHAR2,   -- �o�Ɍ�
    iv_deliver_type          IN         VARCHAR2,   -- �o�Ɍ`��
    iv_object_date_from      IN         VARCHAR2,   -- �Ώۊ���From
    iv_object_date_to        IN         VARCHAR2,   -- �Ώۊ���To
    iv_shipped_date          IN         VARCHAR2,   -- �o�ɓ��w��
    iv_arrival_date          IN         VARCHAR2,   -- �����w��
    iv_instruction_post_code IN         VARCHAR2    -- �w�������w��
  );
END XXWSH920003C;
/
