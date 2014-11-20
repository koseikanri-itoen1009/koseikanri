CREATE OR REPLACE PACKAGE xxcmn820004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820004c(spec)
 * Description      : �V�����z�v�Z�\�쐬
 * MD.050/070       : �W�������}�X�^Draft1C (T_MD050_BPO_820)
 *                    �V�����z�v�Z�\�쐬    (T_MD070_BPO_82D)
 * Version          : 1.3
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
 *  2008/01/18    1.0   Kazuo Kumamoto   �V�K�쐬
 *  2008/05/21    1.1   Masayuki Ikeda   �����e�X�g��Q�Ή�
 *  2008/06/09    1.2   Marushita        ���r���[�w�ENo6�Ή�
 *  2008/06/26    1.3   Marushita        ST�s�No.288,289�Ή�
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
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_fiscal_year        IN     VARCHAR2         --   01 : �Ώ۔N�x
     ,iv_generation         IN     VARCHAR2         --   03 : ����
     ,iv_prod_div           IN     VARCHAR2         --   04 : ���i�敪
     ,iv_output_unit        IN     VARCHAR2         --   05 : �o�͒P��
     ,iv_crowd_code_01      IN     VARCHAR2         --   06 : �Q�R�[�h1
     ,iv_crowd_code_02      IN     VARCHAR2         --   07 : �Q�R�[�h2
     ,iv_crowd_code_03      IN     VARCHAR2         --   08 : �Q�R�[�h3
     ,iv_crowd_code_04      IN     VARCHAR2         --   09 : �Q�R�[�h4
     ,iv_crowd_code_05      IN     VARCHAR2         --   10 : �Q�R�[�h5
    ) ;
END xxcmn820004c;
/
