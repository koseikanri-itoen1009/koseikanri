CREATE OR REPLACE PACKAGE xxwip730005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP730005C(spec)
 * Description      : �����^���`�F�b�N���X�g
 * MD.050/070       : �^���v�Z�i�g�����U�N�V�����j  (T_MD050_BPO_734)
 *                    �����^���`�F�b�N���X�g        (T_MD070_BPO_73G)
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
 *  2008/04/30    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/05/23    1.1   Masayuki Ikeda   �����e�X�g��Q�Ή�
 *  2008/07/02    1.2   Satoshi Yunba   �֑������Ή�
 *  2008/07/15    1.3   Masayuki Nomura  ST��Q�Ή�#444
 *  2008/07/15    1.4   Masayuki Nomura  ST��Q�Ή�#444�i�L���Ή��j
 *  2008/07/17    1.5   Satoshi Takemoto ST��Q�Ή�#456
 *  2008/07/24    1.6   Satoshi Takemoto ST��Q�Ή�#477
 *  2008/07/25    1.7   Masayuki Nomura  ST��Q�Ή�#456
 *  2008/07/28    1.8   Masayuki Nomura  �ύX�v�������e�X�g��Q�Ή�
 *  2008/08/19    1.9   Takao Ohashi     T_TE080_BPO_730 �w�E10�Ή�
 *  2008/10/15    1.10  Yasuhisa Yamamoto ������Q#300,331
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
     ,iv_carrier_code_from  IN     VARCHAR2         -- 02 : �^���Ǝ�From
     ,iv_carrier_code_to    IN     VARCHAR2         -- 03 : �^���Ǝ�To
     ,iv_whs_code_from      IN     VARCHAR2         -- 04 : �o�Ɍ��q��From
     ,iv_whs_code_to        IN     VARCHAR2         -- 05 : �o�Ɍ��q��To
     ,iv_ship_date_from     IN     VARCHAR2         -- 06 : �o�ɓ�From
     ,iv_ship_date_to       IN     VARCHAR2         -- 07 : �o�ɓ�To
     ,iv_arrival_date_from  IN     VARCHAR2         -- 08 : ����From
     ,iv_arrival_date_to    IN     VARCHAR2         -- 09 : ����To
     ,iv_judge_date_from    IN     VARCHAR2         -- 10 : ���ϓ�From
     ,iv_judge_date_to      IN     VARCHAR2         -- 11 : ���ϓ�To
     ,iv_report_date_from   IN     VARCHAR2         -- 12 : �񍐓�From
     ,iv_report_date_to     IN     VARCHAR2         -- 13 : �񍐓�To
     ,iv_delivery_no_from   IN     VARCHAR2         -- 14 : �z��NoFrom
     ,iv_delivery_no_to     IN     VARCHAR2         -- 15 : �z��NoTo
     ,iv_request_no_from    IN     VARCHAR2         -- 16 : �˗�NoFrom
     ,iv_request_no_to      IN     VARCHAR2         -- 17 : �˗�NoTo
     ,iv_invoice_no_from    IN     VARCHAR2         -- 18 : �����NoFrom
     ,iv_invoice_no_to      IN     VARCHAR2         -- 19 : �����NoTo
     ,iv_order_type         IN     VARCHAR2         -- 20 : �󒍃^�C�v
     ,iv_wc_class           IN     VARCHAR2         -- 21 : �d�ʗe�ϋ敪
     ,iv_outside_contract   IN     VARCHAR2         -- 22 : �_��O
     ,iv_return_flag        IN     VARCHAR2         -- 23 : �m���ύX
     ,iv_output_flag        IN     VARCHAR2         -- 24 : ����
    ) ;
--
END xxwip730005c ;
/
