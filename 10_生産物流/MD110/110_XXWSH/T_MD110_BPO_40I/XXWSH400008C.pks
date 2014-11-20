CREATE OR REPLACE
PACKAGE xxwsh400008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400008c(spec)
 * Description      : ���Y�����i�o�ׁj
 * MD.050/070       : ���Y�����i�o�ׁjIssue1.0  (T_MD050_BPO_401)
 *                    �o�ג����\                (T_MD070_BPO_40I)
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
 *  2008/03/26    1.0   Masakazu Yamashita    �V�K�쐬
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_syori_kbn          IN     VARCHAR2         -- 01 : �������
     ,iv_kyoten_cd          IN     VARCHAR2         -- 02 : ���_
     ,iv_shipped_locat      IN     VARCHAR2         -- 03 : �o�Ɍ�
     ,iv_arrival_date       IN     VARCHAR2         -- 04 : ����
  );
END xxwsh400008c;
/