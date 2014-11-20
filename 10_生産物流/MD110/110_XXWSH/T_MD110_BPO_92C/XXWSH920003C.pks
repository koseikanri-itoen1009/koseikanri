CREATE OR REPLACE PACKAGE APPS.XXWSH920003C AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920003C(spec)
 * Description      : ���Y����(�����A�z��)
 * MD.050           : �v��E�ړ��E�݌ɁE�̔��v��/����v�� T_MD050_BPO921
 * MD.070           : �v��E�ړ��E�݌ɁE�̔��v��/����v�� T_MD070_BPO92E
 * Version          : 1.0
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
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,   -- �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT NOCOPY VARCHAR2,   -- �G���[�R�[�h     #�Œ�#
    iv_action_type           IN         VARCHAR2,   -- �������
    iv_req_mov_no            IN         VARCHAR2,   -- �˗�/�ړ�No
    iv_deliver_from_id       IN         VARCHAR2,   -- �o�Ɍ�
    iv_deliver_type          IN         VARCHAR2,   -- �o�Ɍ`��
    iv_object_date_from      IN         VARCHAR2,   -- �Ώۊ���From
    iv_object_date_to        IN         VARCHAR2,   -- �Ώۊ���To
    iv_shipped_date          IN         VARCHAR2,   -- �o�ɓ��w��
    iv_arrival_date          IN         VARCHAR2,   -- �����w��
    iv_instruction_post_code IN         VARCHAR2    -- �w�������w��
  );
END XXWSH920003C;
/
