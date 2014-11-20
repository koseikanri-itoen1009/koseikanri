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
 * Version          : 1.5
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
 *  2008/06/19    1.1   Yasuhisa Yamamoto     �V�X�e���e�X�g��Q�Ή�
 *  2008/06/26    1.2   ToshikazuIshiwata     �V�X�e���e�X�g��Q�Ή�(#309)
 *  2008/07/02    1.3   Naoki Fukuda          ST�s��Ή�(#373)
 *  2008/07/02    1.4   Satoshi Yunba         �֑������Ή�
 *  2008/07/23    1.5   Naoki Fukuda          ST�s��Ή�(#475)
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