CREATE OR REPLACE PACKAGE xxwsh600001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600001c(spec)
 * Description      : �����z�Ԕz���v��쐬����
 * MD.050           : �z�Ԕz���v�� T_MD050_BPO_600
 * MD.070           : �����z�Ԕz���v��쐬���� T_MD070_BPO_60B
 * Version          : 1.10
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
 *  2008/03/11    1.0   Y.Kanami         �V�K�쐬
 *  2008/06/26    1.1  Oracle D.Sugahara ST��Q #297�Ή� *
 *  2008/07/02    1.2  Oracle M.Hokkanji ST��Q #321,351�Ή� *
 *  2008/07/10    1.3  Oracle M.Hokkanji TE080�w�E03�Ή��A�w�b�_�ύڗ��Čv�Z�Ή�
 *  2008/07/14    1.4  Oracle �R����_   �d�l�ύXNo.95�Ή�
 *  2008/08/04    1.5  Oracle M.Hokkanji �����ăe�X�g�s��Ή�(400TE080_159����2),ST513�Ή�
 *  2008/08/06    1.6  Oracle M.Hokkanji ST�s�493�Ή�
 *  2008/08/08    1.7  Oracle M.Hokkanji ST�s�510�Ή��A�����ύX173�Ή�
 *  2008/09/05    1.8  Oracle A.Shiina   PT 6-1_27 �w�E41-2 �Ή�
 *  2008/10/01    1.9  Oracle H.Itou     PT 6-1_27 �w�E18 �Ή�
 *  2008/10/16    1.10 Oracle H.Itou     T_S_625,�����e�X�g�w�E369
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT NOCOPY VARCHAR2,  -- �G���[���b�Z�[�W #�Œ�#
    retcode                 OUT NOCOPY VARCHAR2,  -- �G���[�R�[�h     #�Œ�#
    iv_prod_class           IN  VARCHAR2,         --  1.���i�敪
    iv_shipping_biz_type    IN  VARCHAR2,         --  2.�������
    iv_block_1              IN  VARCHAR2,         --  3.�u���b�N1
    iv_block_2              IN  VARCHAR2,         --  4.�u���b�N2
    iv_block_3              IN  VARCHAR2,         --  5.�u���b�N3
    iv_storage_code         IN  VARCHAR2,         --  6.�o�Ɍ�
    iv_transaction_type_id  IN  VARCHAR2,         --  7.�o�Ɍ`��
    iv_date_from            IN  VARCHAR2,         --  8.�o�ɓ�From
    iv_date_to              IN  VARCHAR2,         --  9.�o�ɓ�To
    iv_forwarder_id         IN  VARCHAR2          -- 10.�^���Ǝ�
  );
END xxwsh600001c;
/
