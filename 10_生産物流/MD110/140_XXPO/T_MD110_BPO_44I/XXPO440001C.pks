CREATE OR REPLACE PACKAGE xxpo440001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440001c(spec)
 * Description      : �L���o�Ɏw����
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_444)
 *                    �L���x�����[Issue1.0(T_MD070_BPO_44I)
 * Version          : 1.4
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
 *  2008/03/19    1.0   Oracle���V����   �V�K�쐬
 *  2008/05/16    1.1   Oracle����Ǖ�   �����e�X�g�s��i�@�\ID�F440�A�s�ID�F5�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F6�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F7�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F8�j
 *  2008/05/19    1.2   Oracle����Ǖ�   �����e�X�g�s��i�@�\ID�F440�A�s�ID�F9�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F10�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F11�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F12�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F13�j
 *  2008/05/21    1.3   Oracle�c���S��   �����e�X�g�s��i�@�\ID�F440�A�s�ID�F19�j
 *  2008/06/19    1.4   Oracle�F�{�a�Y   �����e�X�g�s�
 *                                         1.���r���[�w�E����No.11�F�K�p���Ǘ����s���B
 *                                         2.���r���[�w�E����No.13�F����於�A�z���於��
 *                                           �܂�Ԃ����R���J�����g���ōs���B
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  �Œ蕔 END   ###############################
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_use_purpose        IN     VARCHAR2         -- 01 : �g�p�ړI
     ,iv_request_no         IN     VARCHAR2         -- 02 : �˗�No
     ,iv_exec_user_dept     IN     VARCHAR2         -- 03 : �S������
     ,iv_update_exec_user   IN     VARCHAR2         -- 04 : �X�V�S��
     ,iv_update_date_from   IN     VARCHAR2         -- 05 : �X�V���tFrom
     ,iv_update_date_to     IN     VARCHAR2         -- 06 : �X�V���tTo
     ,iv_vendor             IN     VARCHAR2         -- 07 : �����
     ,iv_deliver_to         IN     VARCHAR2         -- 08 : �z����
     ,iv_shipped_locat_code IN     VARCHAR2         -- 09 : �o�ɑq��
     ,iv_shipped_date_from  IN     VARCHAR2         -- 10 : �o�ɓ�From
     ,iv_shipped_date_to    IN     VARCHAR2         -- 11 : �o�ɓ�To
     ,iv_prod_class         IN     VARCHAR2         -- 12 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         -- 13 : �i�ڋ敪
     ,iv_security_class     IN     VARCHAR2         -- 14 : �L���Z�L�����e�B�敪
    ) ;
--
END xxpo440001c ;
/
