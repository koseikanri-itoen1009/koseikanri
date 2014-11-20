CREATE OR REPLACE PACKAGE xxwsh620005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620005c(spec)
 * Description      : ���Y�����i�o�ׁj
 * MD.050/070       : ���Y�����i�o�ׁjIssue1.0  (T_MD050_BPO_401)
 *                    �o�Ɏw���m�F�\            (T_MD070_BPO_40I)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- --------------------- -------------------------------------------------
 *  Date          Ver.  Editor                Description
 * ------------- ----- --------------------- -------------------------------------------------
 *  2008/05/12    1.0   Masakazu Yamashita    �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY PLS_INTEGER;
--
--################################  �Œ蕔 END   ###############################
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                OUT    VARCHAR2
     ,retcode               OUT    VARCHAR2
     ,iv_gyoumu_kbn         IN     VARCHAR2         -- 01:�Ɩ����
     ,iv_block1             IN     VARCHAR2         -- 02:�u���b�N1
     ,iv_block2             IN     VARCHAR2         -- 03:�u���b�N2 
     ,iv_block3             IN     VARCHAR2         -- 04:�u���b�N3
     ,iv_deliver_from_code  IN     VARCHAR2         -- 05:�o�Ɍ�
     ,iv_tanto_code         IN     VARCHAR2         -- 06:�S���҃R�[�h
     ,iv_input_date         IN     VARCHAR2         -- 07:���͓��t
     ,iv_input_time_from    IN     VARCHAR2         -- 08:���͎���FROM
     ,iv_input_time_to      IN     VARCHAR2         -- 09:���͎���TO
  );
END xxwsh620005c;
/