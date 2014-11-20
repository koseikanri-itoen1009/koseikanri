CREATE OR REPLACE PACKAGE xxwsh930004c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930004C(spec)
 * Description      : ���o�ɏ�񍷈ك��X�g�i�o�Ɋ�j
 * MD.050/070       : ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD050_BPO_930)
 *                    ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD070_BPO_93D)
 * Version          : 1.14
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
 *  2008/02/19    1.0   Oracle���V����   �V�K�쐬
 *  2008/06/23    1.1   Oracle�勴�F�Y   �s����O�Ή�
 *  2008/06/25    1.2   Oracle�勴�F�Y   �s����O�Ή�
 *  2008/06/30    1.3   Oracle�勴�F�Y   �s����O�Ή�
 *  2008/07/08    1.4   Oracle�|��N�m   �֑������Ή�
 *  2008/07/09    1.5   Oracle�Ŗ����\   �ύX�v���Ή�#92
 *  2008/07/28    1.6   Oracle�Ŗ����\   ST�s�#197�A�����ۑ�#32�A�����ύX�v��#180�Ή�
 *  2008/10/09    1.7   Oracle���c����   �����e�X�g��Q#338�Ή�
 *  2008/10/17    1.8   Oracle���c����   �ۑ�T_S_458�Ή�(������C�ӓ��̓p�����[�^�ɕύX�BPACKAGE�̏C���͂Ȃ�)
 *  2008/10/17    1.8   Oracle���c����   �ύX�v��#210�Ή�
 *  2008/10/20    1.9   Oracle���c����   �ۑ�T_S_486�Ή�
 *  2008/10/20    1.9   Oracle���c����   �����e�X�g��Q#394(1)�Ή�
 *  2008/10/20    1.9   Oracle���c����   �����e�X�g��Q#394(2)�Ή�
 *  2008/10/31    1.10  Oracle���c����   �����w�E#462�Ή�
 *  2008/11/17    1.11  Oracle���c����   �����w�E#651�Ή�(�ۑ�T_S_486�đΉ�)
 *  2008/12/17    1.12  Oracle���c����   �{�ԏ�Q#764�Ή�
 *  2008/12/25    1.13  Oracle���c����   �{�ԏ�Q#831�Ή�
 *  2009/01/06    1.14  Oracle�g�c�Ď�   �{�ԏ�Q#929�Ή�
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
     ,iv_prod_div           IN     VARCHAR2         -- 01 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 02 : �i�ڋ敪
     ,iv_date_from          IN     VARCHAR2         -- 03 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 04 : �o�ɓ�To
     ,iv_dept_code          IN     VARCHAR2         -- 05 : ����
     ,iv_output_type        IN     VARCHAR2         -- 06 : �o�͋敪
     ,iv_block_01           IN     VARCHAR2         -- 07 : �u���b�N�P
     ,iv_block_02           IN     VARCHAR2         -- 08 : �u���b�N�Q
     ,iv_block_03           IN     VARCHAR2         -- 09 : �u���b�N�R
     ,iv_ship_to_locat_code IN     VARCHAR2         -- 10 : �o�Ɍ�
     ,iv_online_type        IN     VARCHAR2         -- 11 : �I�����C���Ώۋ敪
     ,iv_request_no         IN     VARCHAR2         -- 12 : �˗�No�^�ړ�No
    ) ;
--
END xxwsh930004c ;
/
