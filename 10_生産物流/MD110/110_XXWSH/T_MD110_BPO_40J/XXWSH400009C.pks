CREATE OR REPLACE PACKAGE xxwsh400009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400009C(spec)
 * Description      : �o�׈˗��m�F�\
 * MD.050           : �o�׈˗�       T_MD050_BPO_401
 * MD.070           : �o�׈˗��m�F�\ T_MD070_BPO_40J
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
 *  2008/04/11    1.0   Masanobu Kimura  main�V�K�쐬
 *  2008/06/10    1.1   �Γn  ���a       �w�b�_�u�o�͓��t�v�̏�����ύX
 *  2008/06/13    1.2   �Γn  ���a       ST�s��Ή�
 *  2008/06/23    1.3   �Γn  ���a       ST�s��Ή�#106
 *  2008/07/01    1.4   ���c  ����       ST�s��Ή�#331 ���i�敪�͓��̓p�����[�^����擾
 *  2008/07/02    1.5   Satoshi Yunba    �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/03    1.6   �Ŗ�  ���\       ST�s��Ή�#344�357�406�Ή�
 *  2008/07/10    1.7   �㌴  ���D       �ύX�v��#91�Ή� �z���敪���VIEW���O�������ɕύX
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
  PROCEDURE main(
    errbuf                     OUT VARCHAR2,      --   �G���[���b�Z�[�W
    retcode                    OUT VARCHAR2,      --   �G���[�R�[�h
    iv_head_sales_branch       IN  VARCHAR2,      --   1.�Ǌ����_
    iv_input_sales_branch      IN  VARCHAR2,      --   2.���͋��_
    iv_deliver_to              IN  VARCHAR2,      --   3.�z����
    iv_deliver_from            IN  VARCHAR2,      --   4.�o�׌�
    iv_ship_date_from          IN  VARCHAR2,      --   5.�o�ɓ�From
    iv_ship_date_to            IN  VARCHAR2,      --   6.�o�ɓ�To
    iv_arrival_date_from       IN  VARCHAR2,      --   7.����From
    iv_arrival_date_to         IN  VARCHAR2,      --   8.����To
    iv_order_type_id           IN  VARCHAR2,      --   9.�o�Ɍ`��
    iv_request_no              IN  VARCHAR2,      --   10.�˗�No.
    iv_req_status              IN  VARCHAR2,      --   11.�o�׈˗��X�e�[�^�X
    iv_confirm_request_class   IN  VARCHAR2,      --   12.�����S���m�F�˗��敪
    iv_prod_class              IN  VARCHAR2       --   13.���i�敪
    );
--
END xxwsh400009c;
/
