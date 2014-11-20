CREATE OR REPLACE PACKAGE xxwsh930004c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930004C(spec)
 * Description      : ���o�ɏ�񍷈ك��X�g�i�o�Ɋ�j
 * MD.050/070       : ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD050_BPO_930)
 *                    ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD070_BPO_93D)
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
 *  2008/02/19    1.0   Oracle���V����   �V�K�쐬
 *  2008/06/23    1.1   Oracle�勴�F�Y   �s����O�Ή�
 *  2008/06/25    1.2   Oracle�勴�F�Y   �s����O�Ή�
 *  2008/06/30    1.3   Oracle�勴�F�Y   �s����O�Ή�
 *  2008/07/08    1.4   Oracle�|��N�m   �֑������Ή�
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
