CREATE OR REPLACE PACKAGE xxinv100002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100002C(spec)
 * Description      : �̔��v��\
 * MD.050/070       : �̔��v��E����v�� (T_MD050_BPO_100)
 *                    �̔��v��\         (T_MD070_BPO_10B)
 * Version          : 1.5
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
 *  2008/01/18    1.0   Tatsuya Kurata   �V�K�쐬
 *  2008/04/22    1.1   Masanobu Kimura  �����ύX�v��#27
 *  2008/04/28    1.2   Sumie Nakamura   �d����W���P���w�b�_(�A�h�I��)���o�����R��Ή�
 *  2008/04/30    1.3   Yuko Kawano      �����ύX�v��#62,76
 *  2008/04/30    1.4   Tatsuya Kurata   �����ύX�v��#76
 *  2008/07/02    1.5   Satoshi Yunba    �֑������Ή�
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
      errbuf           OUT    VARCHAR2      --   �G���[���b�Z�[�W
     ,retcode          OUT    VARCHAR2      --   �G���[�R�[�h
     ,iv_year          IN     VARCHAR2      --   01.�N�x
     ,iv_prod_div      IN     VARCHAR2      --   02.���i�敪
     ,iv_gen           IN     VARCHAR2      --   03.����
     ,iv_output_unit   IN     VARCHAR2      --   04.�o�͒P��
     ,iv_output_type   IN     VARCHAR2      --   05.�o�͎��
     ,iv_base_01       IN     VARCHAR2      --   06.���_�P
     ,iv_base_02       IN     VARCHAR2      --   07.���_�Q
     ,iv_base_03       IN     VARCHAR2      --   08.���_�R
     ,iv_base_04       IN     VARCHAR2      --   09.���_�S
     ,iv_base_05       IN     VARCHAR2      --   10.���_�T
     ,iv_base_06       IN     VARCHAR2      --   11.���_�U
     ,iv_base_07       IN     VARCHAR2      --   12.���_�V
     ,iv_base_08       IN     VARCHAR2      --   13.���_�W
     ,iv_base_09       IN     VARCHAR2      --   14.���_�X
     ,iv_base_10       IN     VARCHAR2      --   15.���_�P�O
     ,iv_crowd_code_01 IN     VARCHAR2      --   16.�Q�R�[�h�P
     ,iv_crowd_code_02 IN     VARCHAR2      --   17.�Q�R�[�h�Q
     ,iv_crowd_code_03 IN     VARCHAR2      --   18.�Q�R�[�h�R
     ,iv_crowd_code_04 IN     VARCHAR2      --   19.�Q�R�[�h�S
     ,iv_crowd_code_05 IN     VARCHAR2      --   20.�Q�R�[�h�T
     ,iv_crowd_code_06 IN     VARCHAR2      --   21.�Q�R�[�h�U
     ,iv_crowd_code_07 IN     VARCHAR2      --   22.�Q�R�[�h�V
     ,iv_crowd_code_08 IN     VARCHAR2      --   23.�Q�R�[�h�W
     ,iv_crowd_code_09 IN     VARCHAR2      --   24.�Q�R�[�h�X
     ,iv_crowd_code_10 IN     VARCHAR2      --   25.�Q�R�[�h�P�O
    );
END xxinv100002c;
/
